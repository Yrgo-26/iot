# Bilaga B

## Registerkartan och drivrutinsarkitekturen

Det här är kursens viktigaste appendix. Hela **P03** skrivs mot det, och när er kod och det här
dokumentet är oense är det koden som har fel.

Dokumentet är en sammanfattning av hårdvaruklassens
[`register_map.md`](https://github.com/Yrgo-26/programmable-logic/blob/main/project/register_map.md), som ligger i sin helhet i
[`projects/P03/contract/`](../../../projects/P03/contract/register_map.md). Originalet är
sanningskällan: det uppdateras före koden, det ändras bara när båda klasserna vet om det, och det
vinner över den här sammanfattningen om de någonsin skulle säga emot varandra.

---

## 1. Vad ni faktiskt pratar med

Parallellklassen konstruerar en förenklad CAN-kontroller i VHDL. Den kan allt det ni skrev i
mjukvara i L01-L03, fast i kisel: framing, bitstoppning, CRC-15, arbitrering och bittajming.

Men den är konstruerad för en anropare i samma klockdomän - något som kan reagera på en puls som
är **en klockcykel lång**. Vid 50 MHz betyder det 20 nanosekunder. En drivrutin som pollar över
SPI ser systemet några mikrosekunder i taget i bästa fall, alltså tusentals cykler för sent.

Därför ligger det två lager mellan kontrollern och er:

```text
                 er C++-kod
                      |
                     SPI                     5-bytetransaktioner, <= 1 MHz
                      |
   spi_slave  ->  spi_reg_bridge             bytes blir transaktioner
                      |
              register_bank                  pulser blir klibbiga, pollbara bitar
                      |
              can_controller                 CAN i VHDL
                      |
                  CAN-bussen
```

`register_bank` är det lager som gör hela konstruktionen användbar från mjukvara: den fångar
kontrollerns encykelspulser och håller kvar dem som **nivåer som ni måste nollställa själva**.
Varje "skriv `0x1` här för att kvittera" i kartan nedan är den mekanismen.

---

## 2. Registerkartan

> **Den här tabellen är en kopia.** Originalet är `project/register_map.md` i **hårdvarukursens
> repo**, och det är originalet som gäller om de två någonsin säger emot varandra. Kartan står
> ändå här i sin helhet, därför att ni kodar mot den varje dag och inte ska behöva byta repo för
> att slå upp ett index. Men hittar ni en skillnad mellan de två: rapportera den, koda inte efter
> den.

Tretton register, vart och ett 32 bitar brett. **Indexet** är det som går ut på ledningen;
offsetkolumnen är ett arv från en äldre, minnesmappad variant av samma konstruktion och är alltid
`index * 4`.

| Index | Register | Offset | Åtkomst | Beskrivning |
|---:|---|---|---|---|
| 0 | `STATUS` | 0x00 | R | Bit 0: TX klar. Bit 1: RX giltig. Bit 2: Fel. |
| 1 | `TX_ID` | 0x04 | R/W | 11-bitars sändar-ID (bitarna 10-0). |
| 2 | `TX_DLC` | 0x08 | R/W | Data Length Code (bitarna 3-0, värde 0-8). |
| 3 | `TX_DATA_LO` | 0x0C | R/W | Sändardata byte 0-3 (byte 0 = MSB). |
| 4 | `TX_DATA_HI` | 0x10 | R/W | Sändardata byte 4-7 (byte 4 = MSB). |
| 5 | `TX_SEND` | 0x14 | W | Skriv `0x1` för att utlösa sändning. |
| 6 | `RX_ID` | 0x18 | R | Mottagen identifierare (bitarna 10-0). |
| 7 | `RX_DLC` | 0x1C | R | Mottagen DLC (bitarna 3-0). |
| 8 | `RX_DATA_LO` | 0x20 | R | Mottagen data byte 0-3. |
| 9 | `RX_DATA_HI` | 0x24 | R | Mottagen data byte 4-7. |
| 10 | `RX_ACK` | 0x28 | W | Skriv `0x1` för att kvittera och tömma RX-bufferten. |
| 11 | `ERROR_FLAGS` | 0x2C | R/W | Felregistret; skriv `0x0` för att nollställa. |
| 12 | `TX_ABORT` | 0x30 | W | Skriv `0x1` för att tvinga tillbaka TX klar efter en avbruten sändning. |

Index 13-15 är reserverade: en läsning ger `0x00000000`, en skrivning ignoreras.

---

## 3. STATUS - de tre bitarna hela drivrutinen kretsar kring

Samma tre bitar som i originalet, men beskrivna i drivrutinens termer: där originalet namnger
kontrollerns interna signaler (`tx_done`, `rx_valid`) står här vad de betyder sett utifrån. Det är
avsiktligt och ingen avvikelse. Är det **regeln** som skiljer sig åt, och inte bara orden, är det
originalet som gäller.

| Bit | Betydelse | Sätts av | Nollställs av |
|---:|---|---|---|
| 0 | TX klar | reset; en avslutad sändning; en stigande flank på `error` medan biten är låg; en **accepterad** skrivning till `TX_ABORT` | en accepterad skrivning till `TX_SEND` |
| 1 | RX giltig | en mottagen frame, som samtidigt låser `RX_*` | en skrivning av `0x1` till `RX_ACK` |
| 2 | Fel | en **stigande flank** på kontrollerns felnivå | en skrivning av `0x0` till `ERROR_FLAGS` |

Bitarna 31-3 läses alltid som `0`.

**Läs tabellen en gång till.** Varenda bit har en uttrycklig nollställning, och den nollställningen
är drivrutinens ansvar. Glömmer ni `RX_ACK` står `STATUS` bit 1 kvar för alltid och ni läser samma
frame i en oändlig loop. Glömmer ni att `TX_SEND` nollställer bit 0 undrar ni varför den andra
sändningen aldrig accepteras.

---

## 4. Semantik, register för register

* **`TX_SEND`** utlöser en sändning när ett värde med **bit 0 satt** skrivs *och* `STATUS` bit 0
  är satt. Övriga bitar i ordet ignoreras. Är `STATUS` bit 0 låg ignoreras skrivningen tyst: en
  sändning pågår. Läsning ger `0x00000000` - registret lagrar inget, det *gör* något.
* **`RX_ACK`** nollställer `STATUS` bit 1. Kräver bit 0 satt. Läsning ger `0x00000000`.
* **`ERROR_FLAGS`** är **en** bit (bit 0), som speglar `STATUS` bit 2. Det är en
  lås-och-nollställ-på-noll-konstruktion: **bara en skrivning där hela ordet är noll** nollställer.
  `0x000000FF` nollställer alltså inte, trots att bit 0 är satt. `R/W` i tabellen betyder inte att
  det är ett vanligt register.
* **`TX_ABORT`** sätter `STATUS` bit 0 tillbaka till `1` och gör ingenting annat. Nödutgång: i en
  fungerande konstruktion ska den aldrig behövas, eftersom bit 0 redan har två automatiska vägar
  tillbaka. Behöver ni den har ni hittat en bugg värd att rapportera till hårdvarugruppen.
* **Maskning vid skrivning.** `TX_ID` lagrar bitarna 10-0 och `TX_DLC` bitarna 3-0; överflödiga
  bitar läses tillbaka som noll. En skrivning av `0xFFFFFFFF` läses alltså tillbaka som
  `0x000007FF` respektive `0x0000000F`. `TX_DATA_LO`/`HI` lagrar alla 32 bitarna.
* **Skrivningar till `STATUS`, `RX_ID`, `RX_DLC` och `RX_DATA_LO`/`HI` ignoreras tyst.**
  Transaktionen fullbordas normalt; inget fel rapporteras.

---

## 5. Databyteordning

`TX_DATA` och `RX_DATA` är 64 bitar breda, med **databyte 0 i de mest signifikanta bitarna**:

```text
bit 63                                                              bit 0
+--------+--------+--------+--------+--------+--------+--------+--------+
| byte 0 | byte 1 | byte 2 | byte 3 | byte 4 | byte 5 | byte 6 | byte 7 |
+--------+--------+--------+--------+--------+--------+--------+--------+
 \___________ TX_DATA_LO ___________/ \___________ TX_DATA_HI __________/
```

`LO` och `HI` syftar på registerparets ordning, inte på bitsignifikans: **`TX_DATA_LO` bär de
första fyra databytesen.** Det är projektets vanligaste läsfel, och det syns inte förrän en frame
kommer fram bakvänd.

En frame med `dlc = 2` och data `AA BB` packas alltså som:

```text
TX_DATA_LO = 0xAABB0000
TX_DATA_HI = 0x00000000
```

---

## 6. Vad hårdvaran inte gör åt er

Tre saker som det är lätt att anta men fel att anta:

* **Ingen validering.** En `TX_DLC` på `0xF` lagras och skickas vidare till kontrollern precis som
  den är. Att avvisa `dlc > 8` och `id > 0x7FF` är **drivrutinens** ansvar. Att göra det på båda
  sidor är precis så de två kopiorna av regeln glider isär.
* **Ingen buffring på mottagarsidan.** Kontrollern håller exakt en mottagen frame. Kommer nästa
  innan den förra kvitterats skrivs den över, och den nyaste vinner. Det är ett dokumenterat val,
  inte en bugg; en riktig kontroller har en mottagningskö.
* **Ingen tidsgräns.** Kartan säger inte hur lång en sändning är. En drivrutin som vill ge upp får
  välja sin timeout själv. Riktvärde: en maximal frame är omkring 130 bitar, alltså ungefär 130 µs
  vid 1 Mbit/s, plus väntan på en ledig buss.

---

## 7. De tre begränsningarna drivrutinen måste hantera

Förenklingarna mot riktig CAN är många; tre av dem syns ända ut i er kod.

### 7.1 En förlorad arbitrering ser ut som en lyckad sändning
`STATUS` bit 0 kommer tillbaka i båda fallen. Biten betyder **"sändarporten är fri igen"**, inte
"framen kom fram". Det är avsiktligt, och det gör den ordinarie pollningsloopen till:

```text
polla STATUS bit 0     -> sändningsförsöket är över
läs ERROR_FLAGS        -> gick det bra eller inte?
```

Utan det andra steget kan drivrutinen inte veta om framen ska skickas om.

### 7.2 `ERROR_FLAGS` är en bit för fyra orsaker
Förlorad arbitrering, stoppfel, misslyckad CRC och mottagen fjärrframe ger alla samma enda bit.
Drivrutinen kan se *att* något gick fel, aldrig *vad*. Retry-logik som behandlar en förlorad
arbitrering annorlunda än en trasig CRC går inte att skriva mot det här gränssnittet, och det är
värt att notera i `p03_report.md` snarare än att försöka kringgå.

### 7.3 `RX_DATA` ovanför `RX_DLC` läses som `0x00` - maskera ändå
Kontrollern nollställer sin dataackumulator vid varje framestart, så bytes ovanför den mottagna
längden bär aldrig rester från en tidigare frame. **Maskera ändå mot `RX_DLC`.** Nollorna är
kontrollerns garanti, inte framens innehåll, och en drivrutin som kopierar åtta bytes rakt av
rapporterar upp till sex bytes som aldrig sändes.

---

## 8. Lagerarkitekturen

Så här ser **P03** ut när det är klart. Varje pil är ett beroende, och varje horisontell linje är
en gräns någon *inte* får titta igenom:

```text
   app::EchoNode                       Applikationen. Vet bara att den kan skicka och ta emot
        |                              CAN-frames. Vet inte att FPGA, SPI eller register finns.
        v
   driver::can::Interface              Sömmen. Rent abstrakt: send, receive, hasError, clearError.
        |
   +----+----------------+
   |                     |
   v                     v
driver::can::Stub   driver::can::Spi   Två utbytbara implementationer. Stubben simulerar CAN i
                         |             minnet; Spi översätter metodanrop till registeråtkomster.
                         v
              driver::can::ByteTransport   Andra sömmen. En byte i taget, plus SS-framing.
                         |                 Vet inte vad en byte betyder.
        +----------------+----------------+
        |                                 |
        v                                 v
  ScriptedTransport /              AvrSpiTransport      Testdubblare på värddatorn;
  BankTransport                          |              AVR32DB28:s SPI0 på målet.
  (test)                                 v
                              ====== SPI-ledningarna ======
                                         |
                          spi_slave -> spi_reg_bridge -> register_bank
                                         |
                                  can_controller                     hårdvaruklassens VHDL
                                         |
                                    CAN-bussen
```

### Varför två sömmar och inte en?

De löser olika problem, och det är värt att hålla isär dem.

* **`Interface`** gör *applikationen* testbar. `EchoNode` kan köras mot en `Stub` och behöver
  aldrig veta att hårdvara finns.
* **`ByteTransport`** gör *drivrutinen* testbar. Utan den går `Spi` bara att köra på riktig
  hårdvara, och då körs den i praktiken bara under bring-upen - på ett kort som samtidigt
  felsöks av någon annan. Med den kan exakt samma `Spi`-kod som sedan flashas till AVR32DB28:n
  köras på er laptop mot en transport ni själva skriptar.

Regeln som följer, och som en kodgranskare ska leta efter: **ingen fil ovanför
`driver/can/interface.hpp` får innehålla ordet SPI.** Byter hårdvarugruppen transportlager en dag
ska ingenting ovanför den raden behöva ändras.

---

## 9. Sändningssekvensen, som exempel

Att skicka en frame (`id 0x123`, `dlc 2`, data `AA BB`) är fem registerskrivningar och en pollning:

```text
1. läs  STATUS        -> bit 0 satt? annars: upptaget, returnera false
2. skriv TX_ID        = 0x00000123
3. skriv TX_DLC       = 0x00000002
4. skriv TX_DATA_LO   = 0xAABB0000
5. skriv TX_DATA_HI   = 0x00000000
6. skriv TX_SEND      = 0x00000001      -> STATUS bit 0 går låg
   ...
7. polla STATUS       -> bit 0 tillbaka: porten är fri
8. läs  ERROR_FLAGS   -> 0 = framen gick ut, 1 = något gick fel
```

Och att ta emot en:

```text
1. läs  STATUS        -> bit 1 satt? annars: ingen frame, returnera false
2. läs  RX_ID, RX_DLC
3. läs  RX_DATA_LO, RX_DATA_HI, packa upp, maskera mot RX_DLC
4. skriv RX_ACK       = 0x00000001      -> STATUS bit 1 går låg
```

Hur en enskild "läs" eller "skriv" ser ut på ledningen står i
[L08 bilaga A](../../L08/appendix/a_spi.md). Tills dess räcker det att veta att var och en av
raderna ovan är en avslutad transaktion, och att de kostar tid: vid 1 MHz SCK tar en transaktion
omkring 40 µs. En `send()` är alltså sex transaktioner, och det sätter en praktisk gräns för hur
ofta ni kan polla.

---

## 10. Att ändra i kontraktet

Registerkartan är ett kontrakt mellan två klasser som inte kan kompilera mot varandra. Ändras den
måste båda sidor veta om det **innan** ändringen mergas.

Originalet ligger i hårdvarukursens repo, [Yrgo-26/programmable-logic](https://github.com/Yrgo-26/programmable-logic), som
`project/register_map.md`, och tabellen i avsnitt 2
är en kopia av det. Ordningen är därför given: originalet ändras först, kopian här förs över i
samma veva, och koden sist. Aldrig koden först, och aldrig bara det ena av de två dokumenten -
två kopior som gått isär är värre än en enda som är svår att hitta.

I praktiken: ändringen diskuteras med båda handledarna först, och dokumenten uppdateras före
koden, aldrig efter.

Hittar ni en tvetydighet - och det kommer ni att göra - är rätt reaktion att fråga, inte att gissa
och fortsätta koda. En gissning som råkar stämma är omöjlig att skilja från en som inte gör det
förrän bring-upen i [L13](../../L13/README.md).

---
