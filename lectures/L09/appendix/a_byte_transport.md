# Bilaga A

## `ByteTransport` och registeråtkomsten

### 1. Varför ännu en söm

`driver::can::Interface` gjorde `Stub` och `Spi` utbytbara, och därmed `EchoNode` testbar. Men
`Spi` själv ligger *under* den sömmen. Utan något mer går den bara att köra på riktig hårdvara.

Räkna på vad det skulle betyda i praktiken. `Spi` blir klar i [L10](../../L10/README.md).
Hårdvaran finns i [L13](../../L13/README.md). Däremellan skulle ni ha en oprövad klass som ingen
kunnat köra en enda gång - och första gången den körs görs det på ett kort som samtidigt felsöks
av en annan grupp, över fyra ledningar som kanske sitter rätt.

Det är inte ett bra sätt att hitta ett bitskiftningsfel.

**`ByteTransport` är sömmen som löser det.** Den skär mellan "vad en registeråtkomst betyder" och
"hur en byte faktiskt tar sig till FPGA:n". Ovanför sömmen: `Spi`, som ska flashas till målet.
Nedanför: antingen AVR:ns SPI-periferi, eller en testdubblare på er laptop.

**Exakt samma `Spi`-kod körs i båda fallen.** Det är hela poängen.

---

### 2. Interfacet

```cpp
/**
 * @brief Byte-level transport used by the CAN driver.
 */
#pragma once

#include <cstdint>

namespace driver::can
{
/**
 * @brief Moves single bytes to and from the CAN controller, and frames transactions.
 *
 *        Knows nothing about registers, command bytes or CAN: it only carries bytes.
 */
class ByteTransport
{
public:
    /**
     * @brief Destructor.
     */
    virtual ~ByteTransport() noexcept = default;

    /**
     * @brief Begin a transaction by asserting the slave select line.
     */
    virtual void select() noexcept = 0;

    /**
     * @brief End a transaction by releasing the slave select line.
     */
    virtual void deselect() noexcept = 0;

    /**
     * @brief Exchange one byte.
     *
     * @param[in] byte Byte to shift out.
     *
     * @return The byte shifted in at the same time.
     */
    [[nodiscard]] virtual std::uint8_t transfer(std::uint8_t byte) noexcept = 0;
};
} // namespace driver::can
```

Tre metoder. Det är hela lagret.

**Varför `transfer()` returnerar en byte.** SPI är full duplex: varje klockpuls skiftar samtidigt
en bit ut och en bit in. Det finns ingen "skicka"-operation som inte också tar emot. En signatur
som vore `void transfer(std::uint8_t)` skulle ljuga om vad hårdvaran gör, och tvinga fram en
separat `receive()`-metod som inte motsvarar något.

**Varför `select()`/`deselect()` är egna metoder.** Ett alternativ vore att låta transporten göra
hela femBytestransaktionen i ett anrop. Det vore fel lager: `SS`-framingen är en del av
*protokollet*, inte av hur en byte överförs. Transporten ska inte behöva veta att en transaktion
är fem bytes lång. Håll den dum, så gör den bara en sak - och är lätt att implementera rätt både
på AVR:n och i ett test.

**Varför `noexcept` överallt.** Det här lagret kommer att köras på en friställd AVR utan undantag.
Att skriva det i signaturen redan nu gör det omöjligt att av misstag lägga in något som kastar.

**Varför `[[nodiscard]]` på `transfer()`.** Under en skrivning kastas returvärdet med avsikt, och
då skriver man `static_cast<void>(myTransport.transfer(byte));`. Den raden är avsiktligt lite
klumpig: den säger "jag vet att det här värdet är skräp", vilket är precis vad läsaren behöver
veta.

---

### 3. Konstanterna i `Spi`

```cpp
class Spi final : public Interface
{
    // ...
private:
    /** Register indices, as sent in the command byte. */
    static constexpr std::uint8_t RegStatus{0U};
    static constexpr std::uint8_t RegTxId{1U};
    static constexpr std::uint8_t RegTxDlc{2U};
    static constexpr std::uint8_t RegTxDataLo{3U};
    static constexpr std::uint8_t RegTxDataHi{4U};
    static constexpr std::uint8_t RegTxSend{5U};
    static constexpr std::uint8_t RegRxId{6U};
    static constexpr std::uint8_t RegRxDlc{7U};
    static constexpr std::uint8_t RegRxDataLo{8U};
    static constexpr std::uint8_t RegRxDataHi{9U};
    static constexpr std::uint8_t RegRxAck{10U};
    static constexpr std::uint8_t RegErrorFlags{11U};
    static constexpr std::uint8_t RegTxAbort{12U};

    /** STATUS register bit masks. */
    static constexpr std::uint32_t StatusTxReady{1U << 0U};
    static constexpr std::uint32_t StatusRxValid{1U << 1U};
    static constexpr std::uint32_t StatusError{1U << 2U};

    /** Command byte: bit 7 set means write. */
    static constexpr std::uint8_t CmdWrite{0x80U};

    /** Value written to the write-triggered registers. */
    static constexpr std::uint32_t Trigger{0x1U};

    ByteTransport& myTransport; /**< Transport used for every register access. Not owned. */
};
```

**Index, inte offset.** Registerkartan har en offsetkolumn (`0x00`, `0x04`, `0x08`, ...) som är
ett arv från en tidigare, minnesmappad variant av samma konstruktion. Det som går ut på
ledningen är **indexet**, alltså `offset / 4`. Skriv konstanterna som index direkt, så slipper ni
en division vid varje anrop och en klass av fel där någon dividerar två gånger eller ingen gång.

**Namngivna konstanter, inte siffror.** `writeReg(5U, 1U)` säger ingenting. `writeReg(RegTxSend,
Trigger)` säger allt. Den dag hårdvarugruppen skjuter in ett register i mitten av kartan är
skillnaden mellan en femminutersändring och en eftermiddags felsökning.

**`1U << 0U` och inte `0x01U`.** Masken skrivs som en skiftning därför att registerkartan är
skriven i bitpositioner. `StatusRxValid{1U << 1U}` går att jämföra rad för rad mot tabellen i
[L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md#3-status---de-tre-bitarna-hela-drivrutinen-kretsar-kring);
`0x02U` gör det inte.

---

### 4. `writeReg()`

```cpp
void Spi::writeReg(const std::uint8_t index, const std::uint32_t value) const noexcept
{
    myTransport.select();

    static_cast<void>(myTransport.transfer(static_cast<std::uint8_t>(CmdWrite | index)));
    static_cast<void>(myTransport.transfer(static_cast<std::uint8_t>(value >> 24U)));
    static_cast<void>(myTransport.transfer(static_cast<std::uint8_t>(value >> 16U)));
    static_cast<void>(myTransport.transfer(static_cast<std::uint8_t>(value >> 8U)));
    static_cast<void>(myTransport.transfer(static_cast<std::uint8_t>(value)));

    myTransport.deselect();
}
```

Fem `transfer()`, mellan ett `select()` och ett `deselect()`. Läs den mot
`81 00 00 01 23` i [L08 bilaga A](../../L08/appendix/a_spi.md#6-ett-komplett-exempel): `0x81` är
`CmdWrite | RegTxId`, och de fyra följande är `0x00000123` MSB först.

**Varje `static_cast<void>` är avsiktlig.** `transfer()` är `[[nodiscard]]`, och under en
skrivning är returvärdet meningslöst. Casten säger till både kompilatorn och läsaren att det är
känt.

**Varför `static_cast<std::uint8_t>` på varje argument?** `value >> 24U` är en `std::uint32_t`.
Utan casten sker en implicit avsmalnande konvertering, som `-Wconversion` klagar på och som är
lätt att göra fel på när någon senare byter typ. Casten är dessutom dokumentation: "här kastas
de övre bitarna med flit".

**Varför `const` på metoden?** Den ändrar inte `Spi`-objektets tillstånd - `myTransport` är en
referens, och referensen i sig ändras inte. Att hårdvaran ändras är en annan sak, och `const`
i C++ talar om objektet, inte om världen. Det gör att `hasError() const` kan anropa `readReg()`.

---

### 5. `readReg()`

```cpp
std::uint32_t Spi::readReg(const std::uint8_t index) const noexcept
{
    myTransport.select();

    static_cast<void>(myTransport.transfer(index));

    std::uint32_t value{};
    value |= static_cast<std::uint32_t>(myTransport.transfer(0U)) << 24U;
    value |= static_cast<std::uint32_t>(myTransport.transfer(0U)) << 16U;
    value |= static_cast<std::uint32_t>(myTransport.transfer(0U)) << 8U;
    value |= static_cast<std::uint32_t>(myTransport.transfer(0U));

    myTransport.deselect();
    return value;
}
```

**Den första byten kastas.** Slaven laddar sin svarsskiftare i *slutet* av kommandobyten, så det
som klockas in under kommandobyten är rester från förra gången. Fyra `transfer()` bidrar till
värdet, inte fem.

**Kommandobyten är bara `index`.** Bit 7 låg betyder läsning; ingen `CmdWrite`.

**Dummybyten är `0x00`.** Slaven bryr sig inte om vad mastern skickar under en läsning, men
`0x00` är konventionen och gör en logikanalysatorutskrift läsbar.

**`static_cast<std::uint32_t>` före skiftningen, inte efter.** Det här är den vanligaste buggen
i hela funktionen:

```cpp
value |= myTransport.transfer(0U) << 24U;                            // fel
value |= static_cast<std::uint32_t>(myTransport.transfer(0U)) << 24U; // rätt
```

`transfer()` returnerar en `std::uint8_t`. I den första raden befordras den till `int` (typiskt
32 bitar med tecken) och skiftas 24 steg - vilket för ett värde med bit 7 satt skriver in i
teckenbiten. Resultatet blir odefinierat beteende i C++17 och i praktiken ett negativt tal som
sedan konverteras till `std::uint32_t` med `0xFF`-bytes där det inte ska finnas några.

Symptomet: **`id` och `dlc` ser rätt ut för små värden och blir fel så fort en byte har bit 7
satt.** Alltså fungerar det för `0x123` och går sönder för `0xAABB`. Den utdelade testsviten i
[L11](../../L11/README.md) har ett fall just för det.

---

### 6. Varför hjälpfunktionerna är privata

`readReg()` och `writeReg()` är implementationsdetaljer i `Spi`. Ingen utanför klassen ska kunna
peta i registren, av samma skäl som `Interface` inte har en `readStatusRegister()`: den dag någon
gör det i applikationskoden är arkitekturen bruten, och den dag hårdvarugruppen ändrar kartan har
ni två ställen att ändra på i stället för ett.

Den utdelade testsviten testar dem ändå - genom `send()` och `receive()`, och genom att
inspektera vilka bytes som kom ut på `ScriptedTransport`. Att testa en privat metod direkt är
nästan alltid ett tecken på att den borde vara publik, eller på att testet testar fel sak.

---

### 7. Vad det här lagret *inte* gör

`readReg()` och `writeReg()` är rena översättningar av protokollet, och innehåller ingen logik
alls: ingen validering, ingen statuskontroll, inget begrepp om vad ett register betyder. De vet
att en transaktion är fem bytes och att bit 7 betyder skrivning, och inget mer.

All betydelse ligger i lagret ovanför, och det är [L10](../../L10/README.md).

Att hålla den gränsen ren är det som gör `Spi` läsbar. Så fort `writeReg()` börjar innehålla
"om index är `RegTxSend`, kontrollera först att ..." har två lager smält ihop, och båda blev
svårare att testa.

---
