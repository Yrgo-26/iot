# Kommunikationsprotokoll & IoT
Repo för kursen **Kommunikationsprotokoll & IoT** med klassen Ee26, vt27.

Kursen tar dig från ett självpåhittat protokoll på papper till en C++-drivrutin som får en CAN-
kontroller i ett FPGA att skicka riktiga frames på en riktig buss. Första delen bygger ett eget
protokoll från grunden, så att varje mekanism syns. Andra delen kastar det, och ersätter det med
CAN och med hårdvara som en parallellklass konstruerar samtidigt.

**Ämnet är kommunikationsprotokoll och drivrutinskonstruktion**, inte C++ som språk. Klasser,
interface, polymorfism och factory-mönstret repeteras snarare än lärs ut. Se
[förkunskaper](./info/README.md#förkunskaper).

Kursens text är på **svenska**, appendixen inräknade. All kod och alla kommentarer i koden är på
**engelska**.

---

## Om kursen

### Del 1: Ett eget protokoll (L01-L03)
Varför en byte-ström inte är kommunikation, och vad som måste läggas till för att den ska bli det:
framing och synkronisering, längdfält, adressering, sekvensnummer och checksumma; en parser som
tillståndsmaskin; en delad buss med flera noder; och de mekanismer som gör kommunikationen
tillförlitlig när bussen inte är det - ACK/NACK, timeout, omsändning och dubblettdetektion.

Allt skrivs i mjukvara, i en simulerad miljö med en deterministisk felmodell, så att varje fel
går att framkalla på begäran och varje mekanism går att se arbeta.

### Del 2: CAN-drivrutinen (L04-L12)
Samma problem, löst av hårdvara. CAN gör framing, arbitrering, CRC och kvittens i kisel, och det
som återstår för mjukvaran är att prata med kontrollern.

Kontrollern är konstruerad i VHDL av parallellklassen på hårdvaruspåret och nås över SPI. Ni
skriver drivrutinen: ett rent interface, en stubb som simulerar CAN i minnet, en transportsöm,
och den riktiga drivrutinen som packar upp registerkartan till 5-bytetransaktioner. Hela stacken
utvecklas och testas på värddatorn, utan hårdvara, ända till [L12](./lectures/L12/README.md).

**Ingen av klasserna kan kompilera mot den andras kod.** Det enda som binder ihop de två halvorna
är en registerkarta och ett SPI-protokoll, och att arbeta mot ett kontrakt i stället för mot en
implementation är en av kursens poänger.

### Del 3: Hårdvaran (L13-L15)
De två halvorna kopplas ihop: AVR32DB28 mot FPGA över SPI, FPGA:ns CAN-sida ut på en riktig
differentiell buss genom en transceiver, och trafiken läses i **Vector CANalyzer**. Labben är
obligatorisk, och simulering räcker inte - länken ska fungera.

### Examination
Ett projekt (**P03**, 4p), en skriftlig dugga (**D01**, 4p), och en obligatorisk labb som ger
noll poäng men är ett krav för godkänt. Se [info/README.md](./info/README.md#examination-och-betygsnivåer).

---

## Kurslitteratur

### Kursboken
Hela kursen finns också som en bok, i två språkupplagor:
* Svenska: [Kommunikationsprotokoll och drivrutiner](./book/sv/kommunikationsprotokoll-och-drivrutiner.pdf).
* Engelska: [Communication Protocols and Drivers](./book/en/communication-protocols-and-drivers.pdf).

Boken innehåller ett kapitel per föreläsning, där varje kapitel innefattar sammanfattningar,
övningar och övningsduggan med fullständiga svar. Den byggs från källorna i
[`book/`](./book/README.md), där det också står hur du bygger den själv (`make -C book`) och hur en
ny upplaga ges ut.

### Referenslitteratur
CAN som protokoll ligger i en egen bok, också den i två språkupplagor:
* Svenska: [CAN - bussen, framen och
  kontrollern](https://github.com/Yrgo-26/can-book/blob/main/sv/can-sv.pdf).
* Engelska: [CAN - the bus, the frame and the
  controller](https://github.com/Yrgo-26/can-book/blob/main/en/can-en.pdf).

C++-grunderna, som kursen förutsätter, finns i
[Modern Embedded C++](https://github.com/qrtech-academy/modern-embedded-cpp/blob/main/book/modern-embedded-cpp.pdf)
(på engelska). Git, repoorganisation och kodformattering, som kursen också förutsätter, finns i
kapitel 1-3 av
[DevOps for Embedded Engineers](https://github.com/qrtech-academy/devops/blob/main/book/devops.pdf)
(på engelska). Se [förkunskaper](./info/README.md#förkunskaper) för vilka kapitel som täcker vad.

---

## Struktur

```text
.github/     CI-workflows: bygge, formattering och kontroll av kursmaterialet
book/        Kursen satt som en bok med LuaLaTeX, på svenska i book/sv och på engelska
             i book/en; `make -C book` bygger båda PDF:erna
ci/          Skript för bygge, kodformattering och materialkontroll
exam/        Duggainformation och övningsdugga
info/        Kursinformation, schema och examination
lab/         Labb-PM för bring-up och CANalyzer-labben
lectures/    Föreläsningar, litteratur och övningsuppgifter
libs/        Delade C++-bibliotek (testramverket qacademy::test), som git-submodul
projects/    Projektbeskrivning, krav och inlämningsinstruktioner, samt kontraktet mot
             hårdvaruklassen i projects/P03/contract/
```

---

## Kloning och bygge
Testsviterna länkar mot `qacademy::test` i `libs/test`, som är en git-submodul. Klona med
submoduler:

```bash
git clone --recurse-submodules <repository-url>
# Eller, i ett redan klonat repo:
git submodule update --init
```

Från repots rot:

```bash
make build         # Bygg alla kodexempel som har en Makefile, och kör deras tester.
make format        # Formatera all C/C++-kod.
make format-check  # Kontrollera formattering utan att ändra filer.
make docs-check    # Kontrollera länkar, och att kontraktskopiorna matchar originalen.
make contract-check # Bara kontraktskopiorna.
make clean         # Städa bort byggartefakter.
```

Samma kontroller körs i CI vid varje push och Pull Request till `main`.

`clang-format` installeras via `apt` i WSL:

```bash
sudo apt -y update
sudo apt -y install clang-format
```

---

## Kontraktet mot hårdvaruklassen
Två dokument utgör den gemensamma kravspecifikationen mellan klasserna, och de vinner över allt
annat material i det här repot om de skulle säga emot varandra:
* [`register_map.md`](./projects/P03/contract/register_map.md) - vad registren betyder.
* [`spi_register_protocol.md`](./projects/P03/contract/spi_register_protocol.md) - hur de nås.

Båda är kopior ur hårdvaruklassens repo, inlagda i [`projects/P03/contract/`](./projects/P03/contract/)
så att kontraktet finns tillgängligt även utan deras repo. **Originalen är sanningskällan**, och
ordningen vid en ändring är: originalet först, kopian i samma veva, koden sist.

Originalen ligger i hårdvarukursens repo,
[Yrgo-26/programmable-logic](https://github.com/Yrgo-26/programmable-logic).

`make contract-check` kontrollerar att kopiorna fortfarande stämmer mot dem. Peka ut en klon med
`CONTRACT_SRC`; är variabeln inte satt hoppas kontrollen över:

```bash
CONTRACT_SRC=<PATH>/programmable-logic/project make contract-check
```

Sammanfattningarna, skrivna för att räcka till projektet, finns i
[L04 bilaga B](./lectures/L04/appendix/b_register_map_and_architecture.md) och
[L08 bilaga A](./lectures/L08/appendix/a_spi.md).

---

## Licens
Kursmaterialet är licensierat under [CC BY 4.0](./LICENSE) – Erik Pihl. Det gäller
föreläsningarna, appendixen, projektbeskrivningen, labb-PM:et och kursboken i
[`book/`](./book/README.md), inklusive PDF:erna som byggs från den.

Källkoden är licensierad separat under [MIT](./LICENSE-CODE), eftersom CC BY 4.0 inte är avsedd
för mjukvara: kodexemplen i `lectures/`, de utdelade testsviterna, och skripten i
[`ci/`](./ci). Testramverket i `libs/test` har en egen licens.

Kopiorna av kontraktet i [`projects/P03/contract/`](./projects/P03/contract/) hör till
hårdvarukursen; se [Yrgo-26/programmable-logic](https://github.com/Yrgo-26/programmable-logic).

---
