# P03 - CAN-drivrutin i C++

## Översikt
Ni ska skriva C++-drivrutinen till en CAN-kontroller som **inte finns i mjukvara**. Den är
konstruerad i VHDL av parallellklassen på hårdvaruspåret, syntetiserad till ett FPGA, och nåbar
utifrån över SPI.

Det betyder att projektet har en egenskap era tidigare projekt inte haft: **den andra sidan av
gränssnittet skrivs av någon annan, samtidigt som ni skriver er sida.** Ingen av grupperna kan
kompilera mot den andras kod. Det enda som binder ihop de två halvorna är två dokument, och de
är projektets egentliga kravspecifikation:

* [Registerkartan](../../lectures/L04/appendix/b_register_map_and_architecture.md#registerkartan)
  - vad registren betyder.
* [SPI-protokollet](../../lectures/L08/appendix/a_spi.md#transaktionen) - hur de nås.

Båda är sammanfattningar, skrivna för att räcka till det här projektet. Hårdvaruklassens original
är sanningskällan och vinner vid konflikt, och de ligger i sin helhet i
[`contract/`](./contract/):

* [`register_map.md`](./contract/register_map.md)
* [`spi_register_protocol.md`](./contract/spi_register_protocol.md)

De två filerna är kopior ur hårdvaruklassens repo, [Yrgo-26/programmable-logic](https://github.com/Yrgo-26/programmable-logic),
inlagda här så att ni har kontraktet även när
ni inte har deras repo framför er. **Ändra dem inte.** Hittar ni en avvikelse mellan en kopia och
originalet är det originalet som gäller - rapportera avvikelsen till båda handledarna.

När projektet är klart har ni implementerat:

| Klass | Vad den är |
|---|---|
| `driver::can::Frame` | Ren data: ID, DLC och upp till åtta databytes. |
| `driver::can::Interface` | Rent abstrakt interface som all applikationskod skriver mot. |
| `driver::can::Stub` | Testdubblare som simulerar CAN-beteende i minnet, utan hårdvara. |
| `driver::can::ByteTransport` | Sömmen under drivrutinen: en byte i taget över SPI. |
| `driver::can::Spi` | Den riktiga drivrutinen: registerläsningar och -skrivningar som 5-bytetransaktioner. |
| `driver::can::AvrSpiTransport` | `ByteTransport` implementerad mot AVR32DB28:s SPI0-periferi. |
| `app::EchoNode` | En liten applikationskomponent som bara känner till `Interface`. |

---

## 1. Arbetsform

Projektet genomförs i grupper om **4-5 studenter**, och varje grupp paras ihop med en grupp i
hårdvaruklassen. Arbetssättet följer industriell praxis.

### 1.1 Git och GitHub
* Skapa ett privat GitHub-repository och bjud in alla gruppmedlemmar samt läraren som
  collaborator.
* Arbeta i feature-branchar. En branch per milstolpe är en rimlig utgångspunkt:
  `feature/frame`, `feature/interface`, `feature/stub` och så vidare.
* Committa ofta, med meddelanden som säger vad ändringen gör och inte bara att den finns.
* **Pusha aldrig direkt till `main`.** All kod når `main` genom en Pull Request. Skydda branchen i
  GitHubs inställningar så att regeln inte beror på att alla kommer ihåg den.

### 1.2 Kodgranskning
* Varje PR granskas av **minst en annan gruppmedlem** innan den mergas.
* Granskaren kontrollerar: att klassens publika API matchar specifikationen nedan, att alla
  tester passerar, att inga kompilatorvarningar tillkommit (`-Wall -Wextra -Werror`), och att
  Doxygen-kommentarer finns på alla publika metoder.
* Lägg granskningskommentarer i GitHub, inte i chatt eller muntligt. En granskning som inte
  finns skriftligt har inte hänt.
* En granskning som bara säger "ser bra ut" är ingen granskning. Ställ minst en riktig fråga,
  även när koden är bra.

### 1.3 Arbetsfördelning
* Alla ska skriva C++ och alla ska granska C++. Fördelningen får vara ojämn i mängd, inte i art.
* Dokumentera fördelningen löpande i `CONTRIBUTORS.md` i repots rot.

### 1.4 Kontakten med hårdvarugruppen
* Prata med er hårdvarugrupp tidigt, och gör det **om registerkartan snarare än om er kod**.
* Upptäcker någon av er en tvetydighet i kontraktet: ändra dokumentet först, koden sedan, och
  se till att båda handledarna vet om det. Ett kontrakt som uppdateras efter koden är inget
  kontrakt.

---

## 2. Så här drivs projektet

Projektet löper från [L04](../../lectures/L04/README.md) till
[L14](../../lectures/L14/README.md) och har **åtta milstolpar**. De är inte delinlämningar och
betygsätts inte var för sig; de finns för att varje föreläsning ska landa i något konkret, och
för att en grupp som halkar efter ska kunna se exakt var.

| Milstolpe | Klar efter | Innehåll |
|---|---|---|
| M1 | [L05](../../lectures/L05/README.md) | `Frame` + enhetstester |
| M2 | [L06](../../lectures/L06/README.md) | `Interface` + `Stub` |
| M3 | [L07](../../lectures/L07/README.md) | `EchoNode` + komponenttester genom stubben |
| M4 | [L09](../../lectures/L09/README.md) | `ByteTransport` + transaktionslagret (`readReg`/`writeReg`) |
| M5 | [L10](../../lectures/L10/README.md) | `Spi`: `send`, `receive`, `hasError`, `clearError` |
| M6 | [L11](../../lectures/L11/README.md) | Hela den utdelade testsviten grön, `ScriptedTransport` och `BankTransport` inräknade |
| M7 | [L12](../../lectures/L12/README.md) | `AvrSpiTransport`, factory, exempelapplikation |
| M8 | [L13](../../lectures/L13/README.md)-[L14](../../lectures/L14/README.md) | Bring-up mot hårdvarugruppens nod, och verifierad trafik i CANalyzer |

**Klassinterfacen i avsnitt 5-9 får inte ändras.** Lärarens testsvit binder mot dem och körs
utan modifikationer.

**M8 är obligatorisk och simulering räcker inte.** Er drivrutin ska sända och ta emot riktiga
CAN-frames över en riktig buss, och trafiken ska gå att läsa i CANalyzer. Labben ger inga poäng,
men den är ett krav för godkänt på kursen: se [L13](../../lectures/L13/README.md) och
[L14](../../lectures/L14/README.md).

Kravet gäller **er** halva. Är er hårdvarugrupps nod inte klar i tid lånar ni ett fungerande
kort - pinnkonfigurationen är gemensam för båda klasserna just därför, så vilken MCU-nod som
helst passar i vilket kort som helst. Att inte ha en fungerande länk på grund av någon annans
tidsplan är alltså inte ett giltigt utfall, och det är värt att planera efter från L04: en
grupp som har `Spi` grön mot `BankTransport` redan i L11 har marginal kvar till L13.

---

## 3. Projektstruktur

Lägg upp gruppens repo så här:

```text
can_driver/
  include/
    app/
      echo_node.hpp
    driver/
      can/
        byte_transport.hpp
        frame.hpp
        interface.hpp
        spi.hpp
        stub.hpp
  source/
    app/
      echo_node.cpp
    driver/
      can/
        spi.cpp
  firmware/
    avr_spi_transport.hpp        AVR32DB28-transporten; byggs bara för målet
    avr_spi_transport.cpp
    main.cpp
  test/                        Allt i den här katalogen är utdelat och läggs in oförändrat
    bank_transport.hpp           Simulerad registerbank, delad av flera testfiler
    scripted_transport.hpp       Skriptad transport, delad av flera testfiler
    test_echo_node.cpp
    test_frame.cpp
    test_spi.cpp
    test_stub.cpp
    main.cpp                   Kör qacademy::test::runAllTests()
  libs/test/                   qacademy::test, som git-submodul
  Makefile
  CONTRIBUTORS.md
  .gitignore
```

Gränsen som bär hela designen går vid `driver/can/interface.hpp`: **ingenting ovanför den raden
vet att SPI finns.** `app::EchoNode` kompilerar och testas utan att en enda SPI-byte existerar i
bygget, och det är själva poängen med att ha interfacet.

`firmware/` är den enda katalogen som inte byggs på värddatorn. Allt annat kompileras med `g++`
och körs i terminalen.

---

## 4. Namnkonventioner och kodstil

All kod och alla kommentarer i koden skrivs på **engelska**. Instruktionerna är på svenska.

* Namespaces: små bokstäver (`driver::can`, `app`).
* Klassnamn: PascalCase (`Interface`, `Stub`, `Spi`).
* Metoder: camelCase (`send`, `isInitialized`).
* Lokala variabler och parametrar: camelCase (`frame`, `value`).
* Privata medlemsvariabler: camelCase med `my` som prefix (`mySendCount`, `myHasData`).
* Konstanter: PascalCase på klassnivå (`MaxDataLen`, `RegStatus`).
* Heltalstyper: `std::uint32_t`, `std::uint8_t` och så vidare - aldrig bara `int` när ett
  negativt värde inte förekommer.
* Initiering: alltid via konstruktorns initialiseringslista, aldrig i funktionskroppen.
* `{}`-initiering för nollvärden: `count{}`, `running{}`.
* Använd `final`, `explicit`, `noexcept` och `[[nodiscard]]` konsekvent.
* Doxygen-kommentar på varje publik metod samt filheaders.
* Koden ska vara `clang-format`-ren mot kursens `.clang-format`, och kompilera varningsfritt med
  `-Wall -Wextra -Werror`.

---

## 5. Milstolpe 1 - `Frame` (`driver/can/frame.hpp`)

Definiera `driver::can::Frame` som en enkel aggregate:

* `static constexpr std::uint8_t MaxDataLen{8U};`
* `std::uint16_t id{};` - CAN-identifierare, 11 bitar (0x000-0x7FF).
* `std::uint8_t dlc{};` - Data Length Code, 0-8.
* `std::uint8_t data[MaxDataLen]{};` - nyttolast.

Lägg dessutom till en fri funktion i samma namespace:

```cpp
[[nodiscard]] constexpr bool isValid(const Frame& frame) noexcept;
```

som returnerar `true` om `frame.id <= 0x7FFU` och `frame.dlc <= Frame::MaxDataLen`.

**Varför en fri funktion och inte en metod?** För att `Frame` ska förbli en aggregate: ingen
konstruktor, ingen destruktor, inga virtuella funktioner. Den är data som skickas över en buss,
inte ett objekt med beteende, och `Frame f{0x123U, 2U, {0xAAU, 0xBBU}}` ska fortsätta fungera.

**Var validering hör hemma.** Registerbanken i hårdvaran validerar ingenting: skriver ni
`dlc = 0xF` lagras det och skickas vidare till kontrollern precis som det är. Att avvisa
ogiltiga frames är alltså **drivrutinens** ansvar, och `isValid()` är det ansvaret uttryckt en
gång, på ett ställe.

---

## 6. Milstolpe 2 - `Interface` och `Stub`

### 6.1 `driver::can::Interface` (`driver/can/interface.hpp`)

Rent abstrakt basklass. Krav:

* Virtuell destruktor, märkt `noexcept`, implementerad med `= default`.
* Ren virtuella metoder:
  * `send()`:
    * Skickar en CAN-frame.
    * Tar en parameter av typen `const Frame&`.
    * Returnerar `true` om sändningen accepterades, annars `false`.
    * Returvärdet måste tas emot.
  * `receive()`:
    * Försöker läsa en CAN-frame.
    * Tar en referens till en `Frame` som ska fyllas.
    * Returnerar `true` om en frame mottogs, annars `false`.
    * Returvärdet måste tas emot.
  * `hasError()`:
    * Indikerar om drivrutinen har ett fel via `true`/`false`.
    * Modifierar inte objektet (`const`).
    * Kan inte kasta undantag.
    * Returvärdet måste tas emot.
  * `clearError()`:
    * Rensar eventuella felstatusar.
    * Kan inte kasta undantag.

Interfacet innehåller **ingen** metod som avslöjar att hårdvaran nås över SPI. Det är kravet som
gör att `Stub` och `Spi` kan bytas mot varandra utan att någon rad ovanför interfacet ändras.

### 6.2 `driver::can::Stub` (`driver/can/stub.hpp`)

`final`, ärver `driver::can::Interface`. En testdubblare som simulerar CAN-beteende i minnet.

Privata medlemsvariabler:
* `Frame myLastFrame` - den senast sända eller injicerade framen.
* `bool myInitialized` - om stubben är initialiserad.
* `bool myHasData` - om en frame finns att läsa.

Standardkonstruktor:
* Initierar `myLastFrame` till tom.
* Sätter `myInitialized` till `true`.
* Sätter `myHasData` till `false`.

Överskuggningar:
* `send(const Frame& frame)`:
  * Returnerar `false` om `myInitialized` är `false`.
  * Lagrar framen i `myLastFrame` och sätter `myHasData` till `true`.
  * Returnerar `true`.
* `receive(Frame& frame)`:
  * Returnerar `false` om `myInitialized` är `false` eller `myHasData` är `false`.
  * Kopierar `myLastFrame` till utargumentet.
  * Sätter `myHasData` till `false`.
  * Returnerar `true`.
* `hasError()`: returnerar alltid `false`; stubben simulerar ingen felstatus.
* `clearError()`: gör ingenting.

Extra metod:
* `void inject(const Frame& frame) noexcept` - simulerar inkommande data genom att lagra framen
  för senare läsning via `receive()`.

Ta bort kopierings- och flyttoperationerna i den publika delen.

---

## 7. Milstolpe 3 - `app::EchoNode` (`app/echo_node.hpp`)

En applikationskomponent som **bara** känner till `driver::can::Interface`.

* Konstruktorn är `explicit` och tar `driver::can::Interface&` samt en `std::uint16_t`
  svars-ID. Referensen sparas som medlem; komponenten äger inte drivrutinen.
* `void run() noexcept`:
  * Läser en frame via `receive()`. Returnerar direkt om ingen finns.
  * Bygger ett svar: samma `dlc`, samma databytes, men med det konfigurerade svars-ID:t.
  * Skickar svaret via `send()`.
  * Räknar upp en intern räknare över antalet ekade frames.
* `[[nodiscard]] std::uint32_t echoCount() const noexcept` - antalet ekade frames.

Att `EchoNode` går att testa i sin helhet utan en enda rad hårdvarukod är hela poängen med
milstolpe 2. Den testas genom att en `Stub` injiceras i konstruktorn och frames skriptas in med
`inject()`.

---

## 8. Milstolpe 4 - `ByteTransport` och transaktionslagret

### 8.1 `driver::can::ByteTransport` (`driver/can/byte_transport.hpp`)

Sömmen under drivrutinen. Rent abstrakt, och medvetet **så dum som möjligt**: den kan ta `SS`
låg, växla en byte, och ta `SS` hög. Den vet ingenting om register, kommandobytes eller CAN.

* Virtuell destruktor, `noexcept`, `= default`.
* `virtual void select() noexcept = 0;` - drar `SS` låg, inleder en transaktion.
* `virtual void deselect() noexcept = 0;` - släpper `SS` hög, avslutar transaktionen.
* `[[nodiscard]] virtual std::uint8_t transfer(std::uint8_t byte) noexcept = 0;` - skiftar ut en
  byte och returnerar den som skiftades in samtidigt.

**Varför en söm till?** `Interface` gör `Stub` och `Spi` utbytbara; `ByteTransport` gör
*`Spi` själv* testbar. Samma drivrutinskod som kommer att köra på AVR32DB28:n kan köras på er
laptop mot en transport som ni skriptar. Utan den sömmen går `Spi` bara att testa på hårdvara,
och då testas den i praktiken aldrig.

### 8.2 Transaktionslagret i `driver::can::Spi` (`driver/can/spi.hpp`)

`final`, ärver `driver::can::Interface`. Den här milstolpen är deklarationen plus de två privata
hjälpfunktionerna.

* `explicit Spi(ByteTransport& transport) noexcept;` - sparar referensen.
* Ta bort kopierings- och flyttoperationerna i den publika delen.

Privata registerindex (`static constexpr std::uint8_t`):

| Konstant | Värde | Register |
|---|---:|---|
| `RegStatus` | 0 | `STATUS` |
| `RegTxId` | 1 | `TX_ID` |
| `RegTxDlc` | 2 | `TX_DLC` |
| `RegTxDataLo` | 3 | `TX_DATA_LO` |
| `RegTxDataHi` | 4 | `TX_DATA_HI` |
| `RegTxSend` | 5 | `TX_SEND` |
| `RegRxId` | 6 | `RX_ID` |
| `RegRxDlc` | 7 | `RX_DLC` |
| `RegRxDataLo` | 8 | `RX_DATA_LO` |
| `RegRxDataHi` | 9 | `RX_DATA_HI` |
| `RegRxAck` | 10 | `RX_ACK` |
| `RegErrorFlags` | 11 | `ERROR_FLAGS` |
| `RegTxAbort` | 12 | `TX_ABORT` |

Det är **indexet** som går ut på ledningen, inte offseten. Registerkartans offsetkolumn är
`index * 4` och är ett arv från en äldre, minnesmappad variant av samma konstruktion; skriv
konstanterna som index så slipper ni dividera med fyra vid varje anrop.

Privata statusmasker (`static constexpr std::uint32_t`):
* `StatusTxReady = (1U << 0U);`
* `StatusRxValid = (1U << 1U);`
* `StatusError = (1U << 2U);`

Privat kommandobit och triggervärde:
* `CmdWrite = 0x80U;` - bit 7 satt betyder skrivning.
* `Trigger = 0x1U;` - värdet som skrivs till `TX_SEND` respektive `RX_ACK`.

Privata hjälpfunktioner:
* `[[nodiscard]] std::uint32_t readReg(std::uint8_t index) const noexcept;`
* `void writeReg(std::uint8_t index, std::uint32_t value) const noexcept;`

Implementera dem i `source/driver/can/spi.cpp` enligt transaktionsformatet:

**Varje transaktion är exakt fem bytes**: en kommandobyte följd av fyra databytes, MSB först,
med `SS` låg hela vägen.

```text
readReg(index):                       writeReg(index, value):
  select()                              select()
  transfer(index)                       transfer(CmdWrite | index)
  b31_24 = transfer(0x00)               transfer(value >> 24)
  b23_16 = transfer(0x00)               transfer(value >> 16)
  b15_8  = transfer(0x00)               transfer(value >> 8)
  b7_0   = transfer(0x00)               transfer(value)
  deselect()                            deselect()
  return b31_24..b7_0 hopsatt
```

Tre saker i protokollet är lätta att missa och alla tre har en testkonsekvens:
* Byten som kommer tillbaka **under kommandobyten** är skräp. Kasta den.
* Vid en skrivning är alla fyra MISO-byten meningslösa. Kasta dem.
* `SS` **måste** gå hög mellan transaktioner. Två transaktioner under en och samma låga
  `SS`-period är inte två transaktioner; den andra kommandobyten tolkas aldrig som en
  kommandobyte.

---

## 9. Milstolpe 5 - `Spi`: metodkontrakten

Implementera de fyra interfacemetoderna i `source/driver/can/spi.cpp`.

### `send(const Frame& frame)`
1. Returnera `false` om `isValid(frame)` är `false`. Hårdvaran validerar inte åt er.
2. Läs `RegStatus`. Är `StatusTxReady` inte satt, returnera `false` - en sändning pågår.
3. Skriv `frame.id` till `RegTxId`.
4. Skriv `frame.dlc` till `RegTxDlc`.
5. Packa `frame.data[0..3]` till `RegTxDataLo` och `frame.data[4..7]` till `RegTxDataHi`,
   med **databyte 0 i de mest signifikanta bitarna**.
6. Skriv `Trigger` till `RegTxSend`.
7. Returnera `true`.

### `receive(Frame& frame)`
1. Läs `RegStatus`. Är `StatusRxValid` inte satt, returnera `false`.
2. Läs `RegRxId` till `frame.id` och `RegRxDlc` till `frame.dlc`.
3. Läs `RegRxDataLo` och `RegRxDataHi` och packa upp till `frame.data`.
4. **Maskera mot `frame.dlc`**: bytes ovanför den mottagna längden ska vara `0` i `frame.data`.
5. Skriv `Trigger` till `RegRxAck`.
6. Returnera `true`.

Hårdvaran nollställer visserligen sin dataackumulator vid varje framestart, så bytes ovanför
`RX_DLC` läses redan som `0x00`. Maskera ändå: nollorna är kontrollerns garanti, inte framens
innehåll, och en drivrutin som kopierar åtta bytes rakt av rapporterar upp till sex bytes som
aldrig sändes.

### `hasError() const noexcept`
Returnerar `true` om `StatusError` är satt i statusregistret.

### `clearError() noexcept`
Skriver `0x0` till `RegErrorFlags`. **Bara** ett helt nollställt ord nollställer låsningen; ett
värde med bara bit 0 satt gör ingenting. Det är motsatt regel mot `TX_SEND` och `RX_ACK`, som
kräver att bit 0 **är** satt, och skillnaden är en av de vanligaste buggarna i projektet.

### Vad drivrutinen inte kan veta
Tre begränsningar följer av hårdvarudesignen och ska hanteras, inte döljas:

* **En förlorad arbitrering ser ut som en lyckad sändning** på `STATUS` bit 0. Biten betyder
  "sändarporten är fri igen", inte "framen kom fram". Vill ni veta utfallet: vänta på bit 0 och
  **läs sedan `ERROR_FLAGS`**.
* **`ERROR_FLAGS` är en bit för fyra olika orsaker** (förlorad arbitrering, stoppfel,
  misslyckad CRC, mottagen fjärrframe). Retry-logik som skiljer på dem går inte att skriva mot
  det här gränssnittet.
* **Ingen buffring på mottagarsidan.** Kommer en ny frame innan den förra kvitterats med `RX_ACK`
  skrivs den över, och den nyaste vinner. Polla `receive()` tillräckligt ofta.

---

## 10. Milstolpe 6 - Testning

Testsviten byggs mot [`qacademy::test`](../../libs/test/README.md), som läggs in som git-submodul i
`libs/test`.

**Ni skriver inga tester och inga testdubblare i det här projektet.** Sviterna och de två
testdubblarna nedan är utdelade, och läggs in oförändrade. Ert jobb är att få dem att passera,
och att kunna läsa vad de säger när de inte gör det. Att skriva tester lär ni er i *Mjuk- och
hårdvarutestning*, som kommer efter den här kursen; poängen med ordningen är att ni ska ha sett
vad tester är till för innan ni skriver era första.

De två utdelade testdubblarna för `ByteTransport` svarar på olika frågor:

### 10.1 `ScriptedTransport` - "skickade drivrutinen rätt bytes?"
Returnerar MISO-bytes ur ett förprogrammerat skript och spelar in varje MOSI-byte samt varje
`select()`/`deselect()`. Med den kontrolleras transaktionerna **exakt**, byte för byte. Den
filen är i praktiken [SPI-protokollet](../../lectures/L08/appendix/a_spi.md) skrivet som kod.

### 10.2 `BankTransport` - "beter sig drivrutinen rätt?"
En simulerad registerbank: tretton `std::uint32_t` plus den klibbiga STATUS-logiken. Den
tolkar kommandobyten, läser och skriver rätt register, och härmar hårdvarans semantik:
maskeringen av `TX_ID`/`TX_DLC`, att en skrivning till `TX_SEND` nollställer TX-klar, att
`RX_ACK` nollställer RX-giltig, och att bara ett nollställt ord nollställer `ERROR_FLAGS`.
Med den körs hela `send()`/`receive()`-flödet på laptopen.

### 10.3 Vad de utdelade testerna täcker

Listan nedan är inte en uppgift utan en karta: den säger vilket krav varje testfall uttrycker, så
att ni vet var ni ska leta när ett av dem fallerar.

**`Frame` (enhetstest):**
* Default-initiering ger `id = 0`, `dlc = 0` och nollställd data.
* `isValid()` accepterar `0x7FF`/`8` och avvisar `0x800` respektive `9`.

**`Stub` (enhetstest):**
* `receive()` returnerar `false` när ingen data finns.
* `send()` accepterar en frame, som sedan går att läsa tillbaka med `receive()`.
* `inject()` gör en frame läsbar med `receive()`.
* En andra `receive()` utan nytt `send()`/`inject()` returnerar `false`.
* `hasError()` är `false` och `clearError()` ändrar ingenting.

**`EchoNode` (komponenttest, genom `Stub`):**
* `run()` utan injicerad frame ändrar inte `echoCount()`.
* En injicerad frame ekas med rätt svars-ID, samma `dlc` och samma data.
* `echoCount()` räknar upp exakt en gång per ekad frame.

**`Spi` mot `ScriptedTransport` (komponenttest):**
* `writeReg` skickar `CmdWrite | index` följt av de fyra databyten, MSB först.
* `readReg` skickar index följt av fyra dummybytes, och sätter ihop svaret rätt.
* Varje transaktion inleds med `select()` och avslutas med `deselect()` - exakt en gång.
* `send()` av `id = 0x123`, `dlc = 2`, data `AA BB` producerar
  `83 AA BB 00 00` som `TX_DATA_LO`-transaktion.

**`Spi` mot `BankTransport` (komponenttest):**
* `send()` returnerar `false` när `StatusTxReady` inte är satt.
* `send()` returnerar `false` för `dlc = 9` och för `id = 0x800`, **utan** att någon
  transaktion når bussen.
* `receive()` returnerar `false` när `StatusRxValid` inte är satt.
* `receive()` packar upp data korrekt och skriver `RX_ACK`.
* `receive()` av en frame med `dlc = 2` som följer på en med `dlc = 8` ger sex nollställda bytes.
* `hasError()` speglar `StatusError`.
* `clearError()` nollställer låsningen, och en skrivning av ett nollskilt värde gör det inte.

---

## 11. Milstolpe 7 - Hårdvara, factory och exempelapplikation

### 11.1 `driver::can::AvrSpiTransport`
`ByteTransport` implementerad mot AVR32DB28:s `SPI0`-periferi, på **ALT1**-muxen (`PORTC`).
Detaljerna står i [L12 bilaga A](../../lectures/L12/appendix/a_avr32db28_spi.md). Kort:

* `PORTMUX.SPIROUTEA` ska välja `ALT1`, annars hamnar SPI0 på `PORTA` och ingenting händer på
  de ledningar ni kopplat.
* `VDDIO2` måste vara matad innan `PORTC` gör någonting alls. `MVIO.STATUS` säger om den är det.
* `SS` drivs i mjukvara som en vanlig utgång, inte av periferin.
* Detta är den enda filen i projektet som rör `volatile` hårdvaruregister.

### 11.2 Factory och exempelapplikation
Bygg ihop systemet med factory-mönstret från C++-kursen: en factory som lämnar ut ett
`driver::can::Interface&`, och ett `main` som bara skapar factoryn, hämtar drivrutinen, skapar
en `EchoNode` och kör den. `main` ska inte innehålla någon applikationslogik och inte veta
vilken drivrutin den fick.

Byt ut `Spi` mot `Stub` i factoryn och programmet ska fortfarande kompilera och köra - på
värddatorn, utan hårdvara. Går inte det har någon rad ovanför interfacet lärt sig något den
inte borde veta.

---

## 12. Milstolpe 8 - Bring-up och verifierad CAN-trafik

Projektets slutpunkt, och den enda som inte går att nå från en laptop. Er nod ska kopplas till
hårdvarugruppens FPGA-nod över SPI, FPGA-nodens CAN-sida ska via en transceiver ut på en riktig
differentiell CAN-buss, och trafiken ska läsas i **Vector CANalyzer**.

* [L13](../../lectures/L13/README.md) är bring-upen: stegen från "SPI-loopback fungerar" till
  "en frame lämnar bussen", och felsökningen däremellan.
* [L14](../../lectures/L14/README.md) är labben, med representanter från Vector på plats.
  **Länken ska fungera innan L14**, så att labbtiden går åt till att analysera trafik och inte
  till att hitta en felkopplad ledning.

Godkänd labb kräver att gruppen kan visa, i CANalyzer:
* En frame som er drivrutin skickat, med rätt identifierare, rätt DLC och rätt databytes.
* En frame som er drivrutin tagit emot och kvitterat, så att `receive()` returnerade `true`.

Se [L13](../../lectures/L13/README.md) för kopplingsschemat och bring-up-stegen, och
[labb-PM:et](../../lab/README.md) för labbens genomförande.

---

## 13. Bedömning

Betyget sätts **individuellt**. Gruppens gemensamma kodbas är underlaget som gör bedömningen
möjlig, men det som avgör ditt betyg är vad *du* har bidragit med och kan redogöra för - bedömt
utifrån Git-historiken, `CONTRIBUTORS.md` och din förmåga att förklara din egen kod, dina egna
tester och dina egna designbeslut vid redovisningen.

**OBS!** En student som inte kan visa tillräckligt eget bidrag riskerar att inte bli godkänd,
även om gruppens kodbas uppfyller kraven.

### G (individuellt)
* Git-historiken visar att du personligen har skrivit fungerande kod för minst en av
  milstolparna.
* Du kan förklara din egen kod: vilket problem den löser, hur den är uppbyggd och varför.
* Du kan redogöra för de utdelade testerna som rör din kod: vad de verifierar, och vad ett
  fallerande testfall berättade för dig.
* Gruppens kodbas uppfyller milstolpe 1-7: `Stub` och `Spi` fungerar enligt specifikationen,
  registeråtkomsten är korrekt, testsviten passerar och kodstilen följs.
* Gruppen har en fungerande länk mot en FPGA-nod, verifierad i CANalyzer (milstolpe 8). Labben
  ger inga poäng, men utan godkänd labb blir kursen inte godkänd.

### VG (individuellt)
Utöver G-kraven:
* **Verifierat korrekt registeråtkomst:** du kan visa, mot de utdelade testfallen, att
  transaktionerna dina metoder producerar stämmer byte för byte mot protokollet - och förklara
  vilket testfall som skulle fånga vilken bugg, inte bara att det "verkar fungera" i en demo.
* **Motiverade designval:** du kan självständigt motivera varför sömmarna ligger där de ligger,
  vad `ByteTransport` köper som `Interface` inte redan gav, och vilka av hårdvarans
  begränsningar din kod hanterar respektive medvetet låter bli att dölja.
* Koden är genomgående dokumenterad och stilistiskt konsekvent, och granskningskulturen syns i
  repots historik.

### Bidrag till kursens slutpoäng
* Betyget **G** ger 2 poäng till kurssammanställningen.
* Betyget **VG** ger 4 poäng till kurssammanställningen.

---

## 14. Redovisning
Projektet redovisas för läraren under lektionstid:
* Gemensam demo av testsviten, körd från ett rent utcheckat repo.
* Gemensam demo av exempelapplikationen, både på värddator med `Stub` och på AVR32DB28 mot en
  FPGA-nod.
* Var och en av er ska individuellt kunna förklara sin egen del av implementationen och sina
  egna designbeslut, samt gå igenom vilka utdelade testfall som täcker den delen och vad de
  kontrollerar.

---

## 15. Utvärdering
Besvara följande frågor gemensamt i `p03_report.md`, tillsammans med bidragsrapporten:
1. Varför beror `app::EchoNode` på `driver::can::Interface` i stället för på `driver::can::Spi`?
2. Vad hade ni behövt ändra i `EchoNode` om hårdvarugruppen bytt från SPI till ett parallellt
   bussgränssnitt? Varför?
3. `ScriptedTransport` och `BankTransport` testar samma klass. Vilken sorts bugg fångar den ena
   som den andra missar?
   Vilket krav i [L08 bilaga A](../../lectures/L08/appendix/a_spi.md) svarar varje testfil mot?
4. Varför läser drivrutinen `ERROR_FLAGS` efter att ha väntat på `STATUS` bit 0, i stället för
   att lita på biten själv?
5. Varför ska `receive()` maskera databytes mot `RX_DLC`, trots att hårdvaran redan nollställer
   dem?
6. Vilka mekanismer från det egna protokollet i L01-L03 (checksumma, ACK/NACK, timeout, retry,
   dubblettdetektion) behövde ni **inte** skriva i mjukvara här, och var tog CAN hand om dem?
7. Hur användes AI-verktyg i projektet, och vad gjorde ni medvetet utan?
8. Vilket steg i bring-upen tog längst tid, och vilket test hade kunnat fånga felet tidigare?
9. Vad lärde ni er av att ha kontraktet - och inte den andra gruppens kod - som enda
   sanningskälla?

---

## 16. Användning av AI-verktyg
Ni får använda Claude (eller motsvarande) till att sätta upp repot (build-konfiguration,
mappstruktur, CI) och till att förklara vad ett utdelat testfall kontrollerar.

Ni får **inte** använda AI för att skriva drivrutinen: `Frame`, `Interface`, `Stub`,
`ByteTransport`, `Spi`, `AvrSpiTransport` och `EchoNode` ska vara skrivna av gruppen för hand.
Ange tydligt i `p03_report.md` var och hur AI-verktyg har använts.

Skälet är inte principiellt utan praktiskt: den här drivrutinen finns redan skriven, i flera
varianter, i material som är öppet på nätet. Poängen med projektet är att ni ska kunna läsa ett
hårdvarukontrakt och översätta det till kod, och den färdigheten övas bara av den som gör
översättningen själv.

---
