# Kursinfo

## Lärare
Erik Pihl ([erik.axel.pihl@gmail.com](mailto:erik.axel.pihl@gmail.com))

---

## Förkunskaper
Kursens ämne är **kommunikationsprotokoll och drivrutinskonstruktion**, inte C++ som språk.
Deltagarna förutsätts komma med följande på plats från *Programmeringsmetodik* och C++-kursen:

* Klasser, konstruktorer och destruktorer, `explicit`, `final`, `= default`, `= delete`.
* Arv, virtuella funktioner, abstrakta basklasser och polymorfism.
* Interface-baserad drivrutinsdesign och factory-mönstret.
* `constexpr`, `noexcept`, `[[nodiscard]]`, namespaces och `std::uint8_t`-familjen.
* Git och GitHub: klona, branch, commit, push, Pull Request och kodgranskning.
* Repoorganisation: en förutsägbar katalogstruktur, byggingångar och dokumentation.
* Kodformattering med `clang-format`: en gemensam stil som kontrolleras automatiskt.
* Grundläggande vana vid AVR32DB28-kortet och en terminalmiljö (WSL/Linux, `make`).

Inget av det lärs ut från grunden. Det repeteras kort där det behövs, i appendixen snarare än
i föreläsningarna.

C++-delen finns samlad i
[Modern Embedded C++](https://github.com/qrtech-academy/modern-embedded-cpp/blob/main/book/modern-embedded-cpp.pdf)
(på engelska), som är referensen att slå upp i om något sitter löst:

| Förkunskap | Kapitel |
|---|---|
| `constexpr`, `noexcept`, `[[nodiscard]]`, namespaces och `std::uint8_t`-familjen | 1 (avsnitt 1.2) |
| Klasser, konstruktorer och destruktorer, `explicit`, `final`, `= default`, `= delete` | 2 |
| Arv, virtuella funktioner, abstrakta basklasser och polymorfism | 3 |
| Interface-baserad drivrutinsdesign och factory-mönstret | 3 och 4 |

Kapitel 5 (templates) och 6 (trådar och synkronisering) förutsätts inte.

Git, repoorganisation och kodformattering finns i
[DevOps for Embedded Engineers](https://github.com/qrtech-academy/devops/blob/main/book/devops.pdf)
(på engelska):

| Förkunskap | Kapitel |
|---|---|
| Git och GitHub: branchar, Pull Requests och kodgranskning | 1 |
| Repoorganisation: katalogstruktur, byggingångar och dokumentation | 2 |
| Kodformattering med `clang-format` | 3 |

Kapitel 4-6 (CI med GitHub Actions och testautomatisering i Python) förutsätts inte.

Det kursen lär ut från noll är protokollkonstruktion, hårdvarukontrakt och testning av
drivrutiner utan hårdvara.

---

# Kursplan - Kommunikationsprotokoll & IoT

Femton pass. Kursen har tre delar:

* **Del 1 (L01-L03)** bygger ett eget protokoll från grunden: frames, parsning, bussar och
  tillförlitlighet. Allt skrivs i mjukvara, och varje mekanism syns.
* **Del 2 (L04-L12)** byter ut det egna protokollet mot **CAN**, och det mesta av mjukvaran mot
  hårdvara. Ni skriver drivrutinen till en CAN-kontroller som parallellklassen på hårdvaruspåret
  konstruerar i VHDL. Ingen av klasserna kan kompilera mot den andras kod; det enda som binder
  ihop halvorna är en registerkarta och ett SPI-protokoll.
* **Del 3 (L13-L15)** kopplar ihop de två halvorna på riktig hårdvara, analyserar trafiken i
  Vector CANalyzer, och avslutas med duggan.

| Föreläsning | Innehåll | Form |
|---|---|---|
| L01 | Frames: struktur, fält och serialisering | Föreläsning |
| L02 | Byte-parsing och tillståndsmaskiner | Föreläsning |
| L03 | Bussar, routing och tillförlitlig kommunikation | Föreläsning |
| L04 | CAN-bussen, registerkartan och drivrutinsarkitekturen. Start av **P03** | Föreläsning + grupptid |
| L05 | `driver::can::Frame` och den första testsviten | Föreläsning + grupptid |
| L06 | `driver::can::Interface` och `driver::can::Stub` | Föreläsning + grupptid |
| L07 | Komponenttest genom stubben: `app::EchoNode` | Föreläsning + grupptid |
| L08 | SPI från vågformen och transaktionsprotokollet | Föreläsning + grupptid |
| L09 | `ByteTransport`-sömmen och registeråtkomsten | Föreläsning + grupptid |
| L10 | `driver::can::Spi`: `send`, `receive`, `hasError`, `clearError` | Föreläsning + grupptid |
| L11 | Testning av drivrutinen utan hårdvara | Föreläsning + grupptid |
| L12 | AVR32DB28: `volatile`, MVIO och `AvrSpiTransport`; factory och exempelapplikation | Föreläsning + grupptid |
| **L13** | **Bring-up mot hårdvarugruppens CAN-nod** | **Obligatorisk labb** |
| **L14** | **CAN-labb med Vector CANalyzer** | **Obligatorisk labb** |
| **L15** | Genomgång av övningsduggan, kursutvärdering och **D01 - Dugga** | **Examination** |

**OBS!** L04-L12 följer samma upplägg: ungefär en timmes genomgång från katedern, oftast med
live-kodning, och därefter handledd grupptid med **P03**.

---

## Examination och betygsnivåer

### Upplägg
* Ett projekt (**P03**) - en CAN-drivrutin i C++, i grupper om 4-5.
* En skriftlig dugga (**D01**).
* En obligatorisk labb i två pass (**L13-L14**), där gruppens drivrutin ska fungera mot riktig
  hårdvara.

### Poängfördelning
* **P03**: upp till 4p (**G** = 2p, **VG** = 4p), satt individuellt enligt kriterierna i
  [projektbeskrivningen](../projects/P03/README.md#13-bedömning).
* **D01**: upp till 4p (**G** = 2p, **VG** = 4p).

Totalt 8 poäng.

**OBS!** Labben ger inga poäng, men den är obligatorisk och **simulering räcker inte**: gruppen
ska kunna visa riktig CAN-trafik från sin egen drivrutin i CANalyzer. Se
[labb-PM:et](../lab/README.md).

### Betygsnivåer
* 4 ≤ **G** ≤ 6 poäng
* 6 < **VG** ≤ 8 poäng

För godkänt krävs:
* Godkänt resultat på **P03**.
* Godkänt resultat på **D01**.
* Godkänd labb (**L13-L14**).

---

## Kursmaterial

### Litteratur
Kursmaterialet består av:
* Föreläsningsanteckningar, med ett eller flera appendix per föreläsning.
* Kodexempel, live-kodade under lektionerna och utdelade efteråt.
* Övningsuppgifter som görs efter föreläsningarna.
* Utdelade testsviter till delar av **P03**. Ni skriver dem inte; ni får dem att passera, och
  läser vad de rapporterar när de fallerar.
* Kursboken [Kommunikationsprotokoll och drivrutiner](../book/README.md): ett kapitel
  per föreläsning, med sammanfattningar, övningar och övningsduggan med fullständiga svar. Den
  finns [på svenska](../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf) och [på
  engelska](../book/en/communication-protocols-and-drivers.pdf); upplagorna har samma innehåll.
* Boken *CAN - bussen, framen och kontrollern*, som samlar CAN som protokoll med övningar och svar.
  Den finns [på svenska](https://github.com/Yrgo-26/can-book/blob/main/sv/can-sv.pdf) och
  [på engelska](https://github.com/Yrgo-26/can-book/blob/main/en/can-en.pdf); upplagorna har samma
  innehåll. Den täcker [L04](../lectures/L04/README.md) och [L08](../lectures/L08/README.md) på
  djupet, och är den enda delen av materialet som är värd att läsa i sin helhet i ett svep.
* Kontraktet mot hårdvaruklassen, i sin helhet i
  [`projects/P03/contract/`](../projects/P03/contract/) och sammanfattat i
  [L04 bilaga B](../lectures/L04/appendix/b_register_map_and_architecture.md) och
  [L08 bilaga A](../lectures/L08/appendix/a_spi.md). Hårdvaruklassens original är sanningskällan
  och vinner vid konflikt.

Kursens text är på **svenska**, appendixen inräknade. All kod och alla kommentarer i koden är på
**engelska**.

---

### Hårdvara
Följande finns tillgängligt på skolan:

**Per grupp:**
* **AVR32DB28** - kortet från *Programmeringsmetodik*. Kursens MCU, och SPI-master mot FPGA:n.
  SPI0 används på **ALT1**-muxen, alltså `PORTC`, eftersom den domänen matas från `VDDIO2` och
  därmed kan köras på 3,3 V mot FPGA:n medan kärnan går på 5 V.
* **Terasic DE0-CV** med hårdvaruklassens CAN-nod. Kortet kommer från hårdvarugruppen; er grupp
  paras ihop med en av deras.
* **CAN-transceiver ([SN65HVD230](https://www.electrokit.com/))** - 3,3 V, och därmed direkt
  kopplingsbar mot DE0-CV:s GPIO. Gör FPGA-nodens enledarbuss till en riktig differentiell
  CAN-buss som CANalyzer kan läsa.
* 120 Ω termineringsmotstånd i vardera änden, och tvinnad kabel.
* Kopplingsdäck och kopplingstråd.

**Gemensamt, till labben:**
* **Vector CANalyzer** med CAN-interface. Används i [L14](../lectures/L14/README.md), med
  representanter från Vector på plats.
* En logikanalysator med åtta kanaler är till stor hjälp vid felsökning av SPI, men är inte
  nödvändig.

**Under L01-L12 behövs ingen hårdvara alls.** Hela drivrutinen utvecklas och verifieras på
värddatorn.

---

### Mjukvara
**Det varje deltagare behöver**, på en vanlig laptop:
* **[Visual Studio Code](https://code.visualstudio.com/download)** - primär editor, samma som i
  tidigare kurser.
* **Linux / WSL** med **`g++`** (C++17), **GNU Make** och **git** med submodulstöd. Testramverket
  ligger som submodul i `libs/test`, så repot klonas med `--recurse-submodules` eller kompletteras
  med `git submodule update --init`.
  * `sudo apt -y install git make g++`
* **clang-format** - används av `make format-check`, samma kontroll som CI kör.
  * `sudo apt -y install clang-format`

**Till [L12](../lectures/L12/README.md) och framåt:**
* **avr-gcc, avr-libc, avrdude** samt AVR-Dx device family pack, precis som i
  *Programmeringsmetodik*.
  * `sudo apt -y install gcc-avr binutils-avr avr-libc avrdude`

**Till [L14](../lectures/L14/README.md):**
* **Vector CANalyzer**, installerad på labbdatorerna.

---
