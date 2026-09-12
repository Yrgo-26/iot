# Bilaga A

## `driver::can::Frame`

### 1. Vad en CAN-frame bär

Registerkartan i [L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md) säger
exakt vad hårdvaran kan skicka och ta emot, och det är inte mycket:

| Fält | Storlek | Register |
|---|---|---|
| Identifierare | 11 bitar | `TX_ID` / `RX_ID` |
| DLC | 4 bitar, värde 0-8 | `TX_DLC` / `RX_DLC` |
| Data | 0-8 bytes | `TX_DATA_LO`/`HI`, `RX_DATA_LO`/`HI` |

Det är hela nyttolasten. Jämför med framen ni byggde i [L01](../../L01/README.md), som hade SOF,
LEN, TYPE, DST, SRC, SEQ, DATA och CHK - åtta fält mot tre. Skillnaden är inte att CAN är
fattigare, utan att fem av era åtta fält motsvaras av något hårdvaran redan gör: SOF och CHK
finns på bussen men aldrig i ett register, och DST/SRC/SEQ är designval som ett CAN-system gör
*ovanpå* identifieraren.

---

### 2. Klassen

```cpp
/**
 * @brief CAN frame definition.
 */
#pragma once

#include <cstdint>

namespace driver::can
{
/**
 * @brief A single CAN frame: identifier, data length code and payload.
 */
struct Frame
{
    /** Maximum number of payload bytes in a CAN frame. */
    static constexpr std::uint8_t MaxDataLen{8U};

    std::uint16_t id{};                /**< CAN identifier, 11 bits (0x000 - 0x7FF). */
    std::uint8_t  dlc{};               /**< Data length code, 0 - 8. */
    std::uint8_t  data[MaxDataLen]{};  /**< Payload. */
};

/**
 * @brief Check whether a frame is valid, i.e. whether the hardware can send it.
 *
 * @param[in] frame Frame to check.
 *
 * @return True if the identifier and the data length code are both in range.
 */
[[nodiscard]] constexpr bool isValid(const Frame& frame) noexcept
{
    return (frame.id <= 0x7FFU) && (frame.dlc <= Frame::MaxDataLen);
}

} // namespace driver::can
```

Det är hela filen. Ingen `.cpp`.

---

### 3. Varför en aggregate?

`Frame` har medvetet **ingen** konstruktor, destruktor, kopieringsoperator eller medlemsfunktion.
Den är en `struct`, inte en `class`. Skälen, i tur och ordning:

**Den är data, inte beteende.** En frame är något som flyttas: från applikationen till drivrutinen,
från drivrutinen till fyra register, från registren ut på bussen. Ett objekt med invarianter att
upprätthålla hade behövt en konstruktor som kan misslyckas, och det är inte vad en frame är.

**Aggregate-initiering är läsbar.** Med aggregaten fungerar det här:

```cpp
const Frame frame{0x123U, 2U, {0xAAU, 0xBBU}};
```

Lägg till en enda användardeklarerad konstruktor och den raden slutar kompilera, eller börjar
betyda något annat. Testsviterna ni får från och med nästa pass är fulla av sådana rader.

**Default member initialization gör `Frame f{};` säker.** `{}` efter varje medlem betyder att en
default-konstruerad frame har `id = 0`, `dlc = 0` och åtta nollställda databytes. Utan dem hade
`Frame f;` gett odefinierat innehåll, och `receive()` hade kunnat lämna ifrån sig skräp i de
bytes den inte fyllde.

**Kopiering är gratis och rätt.** Kompilatorn genererar en kopieringskonstruktor som kopierar
elva bytes. Det är precis vad vi vill när `EchoNode` bygger ett svar från en mottagen frame.

---

### 4. `MaxDataLen`: `static constexpr`, inte `#define`

```cpp
static constexpr std::uint8_t MaxDataLen{8U};   // ja
#define MAX_DATA_LEN 8                          // nej
```

Skillnaden är inte stilistisk:

* `MaxDataLen` har en **typ**. `std::uint8_t` säger att värdet är en längd i bytes och inget
  annat, och `frame.dlc <= Frame::MaxDataLen` jämför två `std::uint8_t` utan
  heltalskonverteringar att fundera på.
* `MaxDataLen` har en **räckvidd**. Den heter `Frame::MaxDataLen` utanför klassen och krockar inte
  med någon annans konstant. En `#define` gäller från raden den står på till filens slut, tvärs
  igenom varje header som inkluderas efteråt.
* `MaxDataLen` går att **felsöka**. Den finns i debuggern; en `#define` är borta innan
  kompilatorn ens ser koden.
* `MaxDataLen` går att **använda som arraystorlek**, vilket `data[MaxDataLen]` gör - och därmed
  är arrayens storlek och gränskontrollen i `isValid()` garanterat samma tal.

---

### 5. Varför `isValid()` är en fri funktion

Den kunde ha varit `frame.isValid()`. Två skäl till att den inte är det:

1. **Aggregaten ska förbli en aggregate.** En medlemsfunktion hade inte brutit aggregate-status i
   C++17, men en `[[nodiscard]] constexpr bool isValid() const noexcept`-metod är första steget
   mot en klass med invarianter, och nästa steg är en konstruktor.
2. **Den hör till drivrutinen, inte till datan.** Regeln "`id <= 0x7FF` och `dlc <= 8`" kommer
   inte från CAN-framen som begrepp utan från den här hårdvarans registerbredder. Att uttrycka den
   som en fri funktion i `driver::can` gör det tydligt att den är drivrutinens regel.

---

### 6. Var validering hör hemma

Det här är den punkt som är lätt att gå förbi, och den återkommer i [L10](../../L10/README.md).

Registerkartan säger uttryckligen att hårdvaran **inte validerar någonting**: en `TX_DLC` på
`0xF` lagras och skickas vidare till kontrollern precis som den är. Två slutsatser följer:

* **Drivrutinen måste validera.** `send()` ska returnera `false` för en ogiltig frame, inte skicka
  den vidare och hoppas.
* **Bara drivrutinen ska validera.** Frestelsen är att lägga en kontroll i `EchoNode` också, "för
  säkerhets skull". Låt bli. Två kopior av samma regel är två saker som ska hållas i synk, och den
  dag `MaxDataLen` ändras kommer bara den ena att ändras med.

Regeln uttrycks en gång, i `isValid()`, och används på ett ställe: i `Spi::send()`.

---

### 7. Namnkonventionerna, tillämpade

`Frame` visar hela kursens kodstil på tolv rader:

| Regel | I `Frame` |
|---|---|
| Namespaces i små bokstäver | `driver::can` |
| Typnamn i PascalCase | `Frame` |
| Klasskonstanter i PascalCase | `MaxDataLen` |
| Medlemmar i camelCase | `id`, `dlc`, `data` |
| Explicita heltalstyper | `std::uint16_t`, `std::uint8_t` |
| `{}`-initiering för nollvärden | `id{}`, `dlc{}`, `data[MaxDataLen]{}` |
| `[[nodiscard]]` på returvärden som betyder något | `isValid()` |
| Doxygen på allt publikt | filheader, klass, varje medlem, `isValid()` |

Notera att `my`-prefixet **inte** används här. Det gäller privata medlemsvariabler, och `Frame`
har inga privata medlemmar. Från och med `Stub` i [L06](../../L06/README.md) dyker det upp.

---
