# Bilaga A

## `driver::can::Spi`: de fyra metoderna

Allt i det här appendixet bygger på `readReg()` och `writeReg()` från
[L09](../../L09/appendix/a_byte_transport.md). De två funktionerna vet ingenting om vad ett
register betyder; det är här betydelsen kommer in.

---

### 1. `send()`

```cpp
bool Spi::send(const Frame& frame)
{
    if (!isValid(frame))
    {
        return false;
    }

    if ((readReg(RegStatus) & StatusTxReady) == 0U)
    {
        return false;
    }

    writeReg(RegTxId, frame.id);
    writeReg(RegTxDlc, frame.dlc);
    writeReg(RegTxDataLo, packDataLo(frame));
    writeReg(RegTxDataHi, packDataHi(frame));
    writeReg(RegTxSend, Trigger);

    return true;
}
```

#### Ordningen är inte godtycklig

`TX_SEND` **måste** skrivas sist. Den skrivningen är inte "spara ett värde" utan "börja sända
nu", och kontrollern läser då `TX_ID`, `TX_DLC` och de två dataregistren. Skriv triggern först
och ni skickar förra framens innehåll - vilket vid bring-upen ser ut som en nod som ligger exakt
en frame efter.

Statuskontrollen måste komma **före** skrivningarna. Skulle ni skriva `TX_ID` medan en sändning
pågår skriver ni över data kontrollern håller på att använda.

#### Två `false`, två olika betydelser

```cpp
if (!isValid(frame))                                     return false;  // fel på anroparen
if ((readReg(RegStatus) & StatusTxReady) == 0U)          return false;  // upptaget, försök igen
```

Interfacet har bara en `bool` att uttrycka båda med. Det är en medveten förenkling, men värd att
vara medveten om: en anropare som får `false` vet inte om den ska rätta sin frame eller vänta.

Två saker följer:
* **Ordningen spelar roll.** Valideringen först, så att en ogiltig frame avvisas *utan* att en enda
  transaktion går ut på bussen. Den utdelade testsviten kontrollerar just det.
* **Det hör hemma i `p03_report.md`.** Ett gränssnitt vars begränsningar ni kan namnge är ett
  gränssnitt ni har förstått.

#### Valideringen, en gång och på ett ställe

Registerkartan säger uttryckligen att hårdvaran inte validerar. `isValid()` från
[L05](../../L05/appendix/a_frame.md) är den regeln, uttryckt en gång, och `send()` är det enda
stället den används. Lägg inte en till kontroll i `EchoNode` "för säkerhets skull": två kopior av
samma regel är två saker som ska hållas i synk.

---

### 2. Packningen

Databyte 0 ligger i de **mest signifikanta** bitarna, och `TX_DATA_LO` bär de **första** fyra
bytesen. Namnen `LO`/`HI` syftar på registerparets ordning, inte på bitsignifikans - se
[L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md#5-databyteordning).

```cpp
namespace
{
/**
 * @brief Pack four payload bytes into one register word, byte 0 in the most significant bits.
 *
 * @param[in] data   Payload.
 * @param[in] offset Index of the first byte to pack.
 *
 * @return The packed 32-bit word.
 */
[[nodiscard]] std::uint32_t pack(const std::uint8_t* const data,
                                 const std::uint8_t offset) noexcept
{
    return (static_cast<std::uint32_t>(data[offset + 0U]) << 24U)
         | (static_cast<std::uint32_t>(data[offset + 1U]) << 16U)
         | (static_cast<std::uint32_t>(data[offset + 2U]) << 8U)
         | (static_cast<std::uint32_t>(data[offset + 3U]));
}
} // namespace
```

Samma `static_cast`-regel som i `readReg()`: **casta före skiftningen, inte efter.** En
`std::uint8_t` befordras annars till `int`, och en byte med bit 7 satt skiftad 24 steg skriver in
i teckenbiten.

Att packa alla åtta bytes oavsett `dlc` är rätt här: registerkartan säger att
`TX_DATA_LO`/`HI` ovanför `TX_DLC` aldrig skickas, så de behöver inte nollställas. `Frame` är
dessutom alltid nollinitierad. Mottagarsidan är den där det spelar roll - se avsnitt 3.

#### De två vanligaste packningsfelen

| Fel | Symptom |
|---|---|
| `TX_DATA_LO` och `TX_DATA_HI` förväxlade | Framen kommer fram med byte 4-7 först. Syns direkt i CANalyzer, och inte alls i simulering om testet också har fel. |
| Skiftningarna i omvänd ordning inom ett register | `AA BB CC DD` kommer fram som `DD CC BB AA`. |

Båda ger en frame som kommer fram - bara med fel innehåll. Det är den obehagligaste sortens fel,
för allt *ser* ut att fungera.

---

### 3. `receive()`

```cpp
bool Spi::receive(Frame& frame)
{
    if ((readReg(RegStatus) & StatusRxValid) == 0U)
    {
        return false;
    }

    frame.id  = static_cast<std::uint16_t>(readReg(RegRxId) & 0x7FFU);
    frame.dlc = static_cast<std::uint8_t>(readReg(RegRxDlc) & 0xFU);

    const std::uint32_t lo{readReg(RegRxDataLo)};
    const std::uint32_t hi{readReg(RegRxDataHi)};

    unpack(lo, frame.data, 0U);
    unpack(hi, frame.data, 4U);

    for (std::uint8_t i{frame.dlc}; i < Frame::MaxDataLen; ++i)
    {
        frame.data[i] = 0U;
    }

    writeReg(RegRxAck, Trigger);
    return true;
}
```

#### Maskeringen mot `dlc`

Loopen som nollställer bytes ovanför `frame.dlc` ser överflödig ut. Registerkartan säger ju att
kontrollern nollställer sin dataackumulator vid varje framestart, så de bytesen **är** redan noll.

Gör det ändå, av tre skäl:

1. **Nollorna är kontrollerns garanti, inte framens innehåll.** En drivrutin som kopierar åtta
   bytes rakt av rapporterar upp till sex bytes som aldrig sändes. Att de råkar vara noll gör
   dem inte till data.
2. **Garantin kan försvinna.** Den kommer från en implementationsdetalj i hårdvarugruppens VHDL.
   Ändrar de den, eller lånar ni ett kort från en annan grupp som gjort annorlunda, är er
   drivrutin fortfarande rätt.
3. **`dlc` är kontraktet.** `frame.dlc = 2` betyder "två bytes gäller". Kod som lämnar ifrån sig
   ett objekt vars fält säger emot varandra är kod som gör nästa läsare osäker.

Samma resonemang som loopen i `EchoNode::run()` i
[L07](../../L07/appendix/a_component_testing.md#3-två-detaljer-i-run-som-är-lätta-att-missa).

#### `RX_ACK` sist

Kvittensen frigör `RX_*`-registren och nollställer `STATUS` bit 1. Skriv den **efter** att ni
läst allt - annars kan nästa frame skriva över registren mitt i er läsning.

Glöm den helt, och `STATUS` bit 1 står kvar för alltid: varje `receive()` returnerar `true` med
samma frame, i en oändlig loop. Det är ett symptom värt att känna igen.

#### Maskningen vid läsning

`readReg(RegRxId) & 0x7FFU` och `readReg(RegRxDlc) & 0xFU` är egentligen onödiga - banken nollar
redan bitarna ovanför. De står där av samma skäl som loopen: drivrutinen litar på sitt eget
kontrakt, inte på den andra sidans implementation.

---

### 4. `hasError()` och `clearError()`

```cpp
bool Spi::hasError() const noexcept
{
    return (readReg(RegStatus) & StatusError) != 0U;
}

void Spi::clearError() noexcept
{
    writeReg(RegErrorFlags, 0U);
}
```

Två rader, och en av dem är en fälla.

**`clearError()` skriver `0x0`, inte `0x1`.** `ERROR_FLAGS` är en
lås-och-nollställ-på-noll-konstruktion: **bara** en skrivning där hela ordet är noll nollställer
låsningen. `0x1` gör ingenting. `0x000000FF` gör ingenting, trots att bit 0 är satt.

Det är motsatt regel mot `TX_SEND` och `RX_ACK`, som kräver att bit 0 **är** satt. Att de tre
registren har olika regler är inte elegant, men det står i kartan, och det är kartan som gäller.

Symptomet om ni skriver `0x1`: felbiten går aldrig ned, `hasError()` returnerar `true` för alltid
efter första felet, och all retry-logik ovanför slutar fungera.

**Att `hasError()` kan vara `const` och ändå anropa `readReg()`** beror på att `readReg()` är
`const`: den ändrar inte `Spi`-objektet. Att den ändrar hårdvarans tillstånd - en läsning av
`TX_SEND` gör faktiskt ingenting, men en läsning kunde i princip ha sidoeffekter - är något
`const` i C++ inte uttalar sig om.

---

### 5. De tre begränsningarna

Ur [L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md#7-de-tre-begränsningarna-drivrutinen-måste-hantera),
nu med koden framför oss.

#### 5.1 En förlorad arbitrering ser ut som en lyckad sändning

`STATUS` bit 0 kommer tillbaka i båda fallen. Drivrutinen kan alltså inte veta utfallet av
`send()` genom att vänta på biten.

Notera först att `send()` **inte väntar**. Den returnerar så fort triggern är skriven, och det är
rätt: en drivrutinsmetod som blockerar i upp till 130 µs på en 4 MHz-MCU äter hela systemets
tidsbudget. Väntan hör hemma hos anroparen.

**Hur väntar anroparen då?** Interfacet har varken `txReady()` eller `waitForSend()` - och det är
avsiktligt, eftersom `Stub` inte kunnat implementera dem meningsfullt. Det anroparen har är att
`send()` returnerar `false` medan sändaren är upptagen. Väntan *är* alltså ett nytt försök:

```cpp
driver.clearError();

// send() returns false while the transmitter is busy, so this both waits and queues.
while (!driver.send(frame))
{
}

// The port was free when the frame was accepted, which means the previous transmission
// had finished. Its outcome is in the error latch.
if (driver.hasError())
{
    driver.clearError();
    // Lost arbitration, stuff error, bad CRC or a remote frame - the latch does not say which.
}
```

**Läs loopen en gång till.** Den har en fälla som är värd att se nu i stället för vid bring-upen:
`send()` returnerar `false` av **två** skäl, och bara det ena går över av sig självt. En frame med
`dlc = 9` gör `while (!driver.send(frame)) {}` till en oändlig loop.

Rätt hantering är att validera innan man går in i loopen, eller att räkna försök och ge upp:

```cpp
constexpr std::uint16_t MaxAttempts{100U};

if (!isValid(frame))
{
    return false;   // never going to be accepted, however long we wait
}

std::uint16_t attempts{};
while (!driver.send(frame))
{
    if (++attempts >= MaxAttempts)
    {
        return false;
    }
}
```

Att ett returvärde med två betydelser blir ett problem exakt en söm längre upp är ett vanligt
mönster i drivrutinsdesign, och det hör hemma i `p03_report.md`.

#### 5.2 `ERROR_FLAGS` är en bit för fyra orsaker

Förlorad arbitrering, stoppfel, misslyckad CRC och mottagen fjärrframe ger samma bit. Ni kan inte
skriva retry-logik som behandlar dem olika. **Försök inte** gissa er till orsaken ur
sammanhanget; skriv i stället ned begränsningen i `p03_report.md` och hantera alla fyra likadant.

#### 5.3 Ingen buffring på mottagarsidan

Kontrollern håller exakt en frame. Er `receive()` tar omkring 270 µs (sex transaktioner). En frame som
kommer in under tiden skriver över den föregående.

Vad ni kan göra: polla ofta, och gör ingenting långsamt mellan `receive()`-anropen.
Vad ni inte kan göra: något alls åt att frames tappas när trafiken är tät nog. Det är hårdvarans
dokumenterade begränsning, och rätt hantering är att veta om den.

---

### 6. Checklista före `make test`

* [ ] `send()` validerar **först**, och skickar ingen transaktion för en ogiltig frame.
* [ ] `send()` kontrollerar `StatusTxReady` innan den skriver något.
* [ ] `TX_SEND` skrivs **sist**.
* [ ] `TX_DATA_LO` bär databyte 0-3, `TX_DATA_HI` byte 4-7.
* [ ] Databyte 0 ligger i bitarna 31-24.
* [ ] Varje `static_cast<std::uint32_t>` står **före** skiftningen.
* [ ] `receive()` kontrollerar `StatusRxValid` först.
* [ ] `receive()` skriver `RX_ACK` **efter** alla läsningar.
* [ ] `receive()` nollställer `frame.data` ovanför `frame.dlc`.
* [ ] `clearError()` skriver `0x0`.
* [ ] Ingen magisk siffra i hela filen: bara namngivna konstanter.

---
