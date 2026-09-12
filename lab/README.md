# Laboration - Bring-up och CAN-analys med Vector CANalyzer

**Obligatorisk.** Två pass: [L13](../lectures/L13/README.md) och
[L14](../lectures/L14/README.md).

Labben ger **inga poäng**, men den är ett krav för godkänt på kursen, och **simulering räcker
inte**. Gruppens drivrutin ska skicka och ta emot riktiga CAN-frames över en riktig buss, och
trafiken ska gå att läsa i CANalyzer.

---

## Syfte
* Koppla ihop de två halvorna av ett hårdvaru-/mjukvarusystem som två klasser byggt var för sig
  mot ett gemensamt kontrakt.
* Få er egen drivrutin att fungera mot riktig hårdvara.
* Analysera CAN-trafik i ett industriellt verktyg, med representanter från Vector på plats.
* Se, utifrån, vilka förenklingar en förenklad CAN-kontroller faktiskt gör.

---

## Förkunskaper
Innan [L13](../lectures/L13/README.md):
* Hela den utdelade testsviten grön på värddatorn.
* Firmware som går att bygga och flasha.
* Hela checklistan i
  [L12 bilaga B avsnitt 6](../lectures/L12/appendix/b_factory_and_app.md#6-checklista-inför-l13)
  avbockad.

Innan [L14](../lectures/L14/README.md):
* **En fungerande länk.** Utan trafik på bussen finns ingenting att analysera.

---

## Material

**Per grupp:**
* AVR32DB28-kort med er firmware, och USB-kabel.
* DE0-CV med hårdvaruklassens `can_spi_node`, syntetiserad och programmerad.
* En CAN-transceiver för **3,3 V** (SN65HVD230 eller likvärdig).
* 2 × 120 Ω termineringsmotstånd.
* Tvinnad tvåledare till CAN_H/CAN_L.
* Kopplingsdäck och kopplingstråd.
* Logikanalysator, om tillgänglig. Inte nödvändig, men sparar timmar.

**Gemensamt:**
* Labbdator med **Vector CANalyzer** och ett CAN-interface.

---

## Kopplingen

### SPI: AVR32DB28 ↔ DE0-CV

Fyra ledningar plus matning och jord, enligt kontraktets pinnkonfiguration
([L08 bilaga A](../lectures/L08/appendix/a_spi.md#8-pinnkonfigurationen)):

| Signal | AVR32DB28 | DE0-CV |
|---|---|---|
| `SCK` | `PC2` | `GPIO_0(4)` |
| `MOSI` | `PC0` | `GPIO_0(5)` |
| `MISO` | `PC1` | `GPIO_0(6)` |
| `SS` | `PC3` | `GPIO_0(7)` |
| I/O-matning | `VDDIO2` | 3,3 V |
| Jord | `GND` | `GND` |

> **`VDDIO2` först.** `PORTC` är AVR-DB:ns MVIO-domän och matas från `VDDIO2`, inte från `VDD`.
> Utan den kopplingen gör `PORTC` ingenting alls, och symptomet ser ut precis som en trasig
> SPI-implementation. Koppla den, och kontrollera `MVIO.STATUS`, innan något annat felsöks.
>
> **Ingen nivåomvandlare behövs.** Det är hela poängen med MVIO: kärnan kör på 5 V medan de fyra
> SPI-ledningarna ligger i en 3,3-voltsdomän. Koppla **inte** in en nivåomvandlare "för säkerhets
> skull" - den lägger bara till en felkälla.

`GND` mellan korten är inte valfritt. Två kort utan gemensam jord kommunicerar inte, och
symptomet är obegripligt.

### CAN: DE0-CV ↔ transceiver ↔ buss

FPGA-nodens CAN-sida är en **enledarbuss med öppen dränering** på tre GPIO-pinnar:

| Signal | DE0-CV | Betydelse |
|---|---|---|
| `tx_bus` | `GPIO_0(0)` | Vad noden driver. |
| `bus_en` | `GPIO_0(1)` | Om noden driver alls. |
| `rx_bus` | `GPIO_0(2)` | Bussens nivå, in till noden. |

För att CANalyzer ska kunna se trafiken måste den enledarbussen bli en riktig **differentiell**
CAN-buss. Det är transceiverns jobb:

```text
   DE0-CV                  SN65HVD230                 Bussen
  tx_bus  ─┐
           ├── (öppen dränering) ──► D (TXD)      CAN_H ──┬──────────┬──
  bus_en  ─┘                                              │          │
                                     CAN_L ──┬──────────┬──         120 Ω
  rx_bus  ◄────────────────────────── R (RXD)          120 Ω         │
                                                         │      CANalyzer
   3,3 V ──────────────────────────► VCC                 │
   GND   ──────────────────────────► GND            hårdvarugruppens
                                                        andra nod
```

Transceiverns `TXD` ska vara **låg för en dominant bit**:

| `bus_en` | `tx_bus` | Noden | `TXD` |
|---|---|---|---|
| 0 | - | driver inte | 1 (recessiv) |
| 1 | 0 | dominant | 0 |
| 1 | 1 | recessiv | 1 |

Hur `tx_bus` och `bus_en` slås ihop till den enda `TXD`-ledningen är **hårdvarugruppens sida av
kopplingen**; stäm av det med dem innan ni kopplar. Kombinationen är trivial men den måste vara
gjord, och en nod vars `bus_en` ignorerats driver bussen hela tiden och blockerar alla andra.

**Terminering:** 120 Ω i **vardera änden** av bussen, inte i mitten och inte fler än två. En
felterminerad buss fungerar ofta ändå på en kort kabel, och slutar fungera exakt när ni börjar
tro att allt är klart.

**Bithastighet: 1 Mbit/s.** Ställ in samma i CANalyzer.

---

## Del 1 - Bring-up-stegen

Klättra dem i ordning. Varje steg har ett eget kvitto, och poängen är att **aldrig ha mer än en
okänd sak åt gången**. Hoppa över ett steg och ni felsöker fyra lager samtidigt.

### Steg 0 - Strömmen och `VDDIO2`
**Gör:** koppla matning och jord. Kör firmware.

**Kvitto:** `MVIO.STATUS` rapporterar att `VDDIO2` är inom intervallet. (Det är därför ni lade in
kontrollen i [L12](../lectures/L12/appendix/c_exercises.md).)

**Bevisar:** att `PORTC` över huvud taget kan driva något.

---

### Steg 1 - SPI-loopback
**Gör:** koppla `MOSI` direkt till `MISO` på AVR-kortet, utan FPGA:n inblandad. Skicka en byte
och läs vad som kommer tillbaka.

**Kvitto:** ni får tillbaka exakt den byte ni skickade. Prova minst `0x00`, `0xFF`, `0xAA` och
`0x55`.

**Bevisar:** att `AvrSpiTransport` fungerar - klocka, bitordning, timing och `SPI0`-konfigurationen.
Det är den enda klassen i projektet som inget automattest täcker, och det här steget är dess test.

**Om det inte fungerar:** felet är i er kod eller i AVR-konfigurationen. FPGA:n är inte inkopplad
och kan inte vara orsaken. Kontrollera `PORTMUX.SPIROUTEA` först.

---

### Steg 2 - Registereko
**Gör:** koppla in FPGA:n. Skriv ett värde till ett R/W-register och läs tillbaka det.
`TX_ID` är bäst: den maskerar till elva bitar, vilket ger ett extra kvitto.

**Kvitto:**
* Skriv `0x00000123` till `TX_ID`, läs tillbaka `0x00000123`.
* Skriv `0xFFFFFFFF` till `TX_ID`, läs tillbaka `0x000007FF`.
* Skriv `0xFFFFFFFF` till `TX_DLC`, läs tillbaka `0x0000000F`.

Maskeringen är det viktiga: den bevisar att ni pratar med **registerbanken** och inte med ett
eko av er egen ledning.

**Bevisar:** hela SPI-kedjan, kopplingen, och att båda sidor tolkar kommandobyten likadant.

**Om det inte fungerar:** se felsökningstabellen nedan.

---

### Steg 3 - STATUS
**Gör:** läs `STATUS` upprepade gånger utan att göra något annat.

**Kvitto:** `0x00000001` - TX-klar satt, RX-giltig låg, fel lågt. Det är resettillståndet.

**Bevisar:** att `can_controller` är i vila och att banken speglar den.

**Om ni får `0x00000005`:** felbiten är satt redan från start. Skriv `0x0` till `ERROR_FLAGS` och
läs om. Går den inte ned: antingen skriver ni fel värde (se
[L10 bilaga A](../lectures/L10/appendix/a_spi_driver.md#4-haserror-och-clearerror)), eller så
ligger kontrollern och rapporterar fel - vilket är hårdvarugruppens ände.

---

### Steg 4 - En frame ut
**Gör:** koppla in transceivern och terminera bussen. Kör en `send()` med ett känt ID och en känd
nyttolast, till exempel `id = 0x123`, `dlc = 2`, data `AA BB`.

**Kvitto:** aktivitet på CAN_H/CAN_L, och `STATUS` bit 0 som går låg och sedan kommer tillbaka.
Med logikanalysator: en framestruktur som ser ut som CAN.

**Bevisar:** hela sändvägen, från `Spi::send()` genom fem registerskrivningar och en trigger, ut
genom kontrollern och transceivern.

> **Notera:** en frame som ingen kvitterar fullbordas ändå i den här konstruktionen - sändaren läser
> aldrig tillbaka ACK-luckan. `STATUS` bit 0 kommer alltså tillbaka även om ni är ensamma på
> bussen. Läs `ERROR_FLAGS` för att veta hur det gick.

---

### Steg 5 - En frame in
**Gör:** låt en andra nod skicka - hårdvarugruppens andra nod, en annan grupps nod, eller
CANalyzer.

**Kvitto:** `STATUS` bit 1 går hög, `receive()` returnerar `true`, och `frame` innehåller rätt ID,
rätt DLC och rätt data.

**Bevisar:** hela mottagningsvägen, inklusive kvittensen. Skriver ni inte `RX_ACK` står bit 1
kvar och ni läser samma frame i all evighet - ett symptom värt att känna igen.

**Efter det här steget är länken klar**, och ni är redo för [L14](../lectures/L14/README.md).

---

## Felsökning

| Symptom | Trolig orsak | Kontrollera |
|---|---|---|
| Inget händer alls, inga klockpulser | `PORTMUX.SPIROUTEA` inte satt | SPI0 ligger på `PA4`-`PA7` i stället för `PORTC` |
| `PORTC` gör ingenting, klocka saknas | `VDDIO2` inte matad | `MVIO.STATUS` |
| Alla läsningar ger `0x00000000` | `MISO` inte kopplad, eller fel pinne | Steg 1 igen; byt `MOSI`/`MISO` och se om det ändras |
| Alla läsningar ger `0xFFFFFFFF` | `MISO` flytande eller uppdragen | Kopplingen; slaven driver `MISO` låg i vila |
| Läsningarna ligger en byte fel | `SPI0.DATA` läses inte i `transfer()` | [L12 bilaga A](../lectures/L12/appendix/a_avr32db28_spi.md#4-avrspitransport) |
| Värden stämmer för små tal men inte för stora | Teckenutvidgning i `readReg()` | [L09 bilaga A](../lectures/L09/appendix/a_byte_transport.md#5-readreg) |
| Skrivningar verkar inte ta | `SS` släpps inte mellan transaktioner | Logikanalysator på `PC3` |
| Andra transaktionen ignoreras | Två transaktioner under en låg `SS`-period | [L08 bilaga A](../lectures/L08/appendix/a_spi.md#4-ss-reglerna) |
| Framen kommer fram bakvänd | `TX_DATA_LO`/`HI` förväxlade | [L10 bilaga A](../lectures/L10/appendix/a_spi_driver.md#2-packningen) |
| `receive()` ger samma frame om och om igen | `RX_ACK` skrivs inte | Steg 5 |
| `hasError()` är alltid `true` | `clearError()` skriver `0x1` i stället för `0x0` | [L10 bilaga A](../lectures/L10/appendix/a_spi_driver.md#4-haserror-och-clearerror) |
| Bussen ligger konstant dominant | En nods `bus_en` ignorerad i kopplingen | Kopplingstabellen ovan |
| Fungerar på kort kabel, inte på lång | Terminering saknas eller sitter fel | 120 Ω i **vardera** änden |

**Arbetsgången när något inte fungerar:**
1. Vilket steg var det sista som gav rätt kvitto?
2. Vad är den **enda** saken som tillkommit sedan dess?
3. Formulera en hypotes om vad som är fel.
4. Bestäm vilken mätning som skulle avgöra saken.
5. Gör mätningen.

Att byta sladdar tills det fungerar är inte felsökning, och det tar längre tid.

---

## Del 2 - CANalyzer

Genomförs i [L14](../lectures/L14/README.md), med representanter från Vector på plats.

### 1. Koppla in
Koppla CANalyzers CAN-interface till bussen som en tredje nod, och ställ in **1 Mbit/s**.
Kontrollera att termineringen fortfarande är 120 Ω i vardera änden - inte tre motstånd för att
det nu är tre noder.

### 2. Läs era egna frames
Skicka en frame med känt ID och känd nyttolast från er nod.

* Hitta den i trace-fönstret.
* Läs av identifierare, DLC och databytes. Stämmer de med vad `send()` fick?
* Vad är tidsstämpeln, och hur ofta kommer framesen?

### 3. Skicka till er nod
Skicka en frame **från** CANalyzer till er nod.

* Returnerar er `receive()` `true`?
* Stämmer ID, DLC och data?
* Kvitterade ni den, och vad hände med `STATUS` bit 1?

### 4. Titta på kvittensen
* Kvitterar CANalyzer era frames? Hur ser det ut i tracen?
* Koppla bort CANalyzer och skicka en frame med bara er nod på bussen. Vad säger `ERROR_FLAGS`?
  Vad *skulle* en riktig CAN-nod ha gjort?

### 5. Leta efter förenklingarna
Hårdvaruklassens konstruktion har dokumenterade förenklingar mot riktig CAN. Några av dem går att
se utifrån. Undersök, och notera vad ni hittar:

* Sändaren läser aldrig tillbaka ACK-luckan. Vad betyder det för en frame som ingen kvitterar?
* Konstruktionen genererar inga error frames. Vad händer om CANalyzer skickar en?
* Efter EOF: finns det en intermission mellan framesen, och vad säger CANalyzer om det?
* Rapporterar CANalyzer några felräknare? Vilka, och kan ni förklara dem?

**Att hitta en avvikelse är inte att hitta ett fel.** Uppgiften är att kunna säga *vilken*
dokumenterad förenkling som förklarar vad ni ser - och vilka avvikelser som **inte** har någon
sådan förklaring, för det är de senare som är intressanta för båda klasserna.

### 6. Bussbelastning
* Vad är bussbelastningen med er nod som enda sändare?
* Jämför med er tidsbudget från
  [L08 bilaga A avsnitt 7](../lectures/L08/appendix/a_spi.md#7-vad-det-kostar-i-tid): vad
  begränsar er egentligen, CAN-bussen eller SPI-länken?

---

## Redovisning och godkännande

För **godkänd labb** ska gruppen visa läraren, i CANalyzer:

1. En frame som **er drivrutin skickat**, med rätt identifierare, rätt DLC och rätt databytes.
2. En frame som **er drivrutin tagit emot och kvitterat**, så att `receive()` returnerade `true`.

Dessutom ska gruppen kunna svara på:
* Vilket bring-up-steg tog längst tid, och varför?
* Vilken av era observationer i del 2 förklaras av en dokumenterad förenkling, och vilken gör
  det inte?

---

## Bring-up-logg

Fyll i under [L13](../lectures/L13/README.md); den hör hemma i `p03_report.md`.

| Steg | Fungerade direkt? | Vad var fel? | Hur hittade ni det? | Tid |
|---|---|---|---|---|
| 0 - `VDDIO2` | | | | |
| 1 - SPI-loopback | | | | |
| 2 - Registereko | | | | |
| 3 - STATUS | | | | |
| 4 - En frame ut | | | | |
| 5 - En frame in | | | | |

Sista kolumnen är den intressanta. Ett steg som tog tre timmar är värt en rad i
`p03_report.md` om **vilket test på laptopen som hade kunnat fånga felet tidigare** - eller om
varför inget test hade kunnat det.

---
