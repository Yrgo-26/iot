# Bilaga A

## SPI och transaktionsprotokollet

Det här är kontraktets andra halva. [L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md)
säger vad registren **betyder**; det här dokumentet säger hur de **nås**.

Det är en sammanfattning av hårdvaruklassens
[`spi_register_protocol.md`](https://github.com/Yrgo-26/programmable-logic/blob/main/project/spi_register_protocol.md), som ligger i
sin helhet
i [`projects/P03/contract/`](../../../projects/P03/contract/spi_register_protocol.md).
Originalet är sanningskällan och vinner vid konflikt.

---

## 1. SPI på fyra ledningar

SPI är en synkron seriebuss med en master och en eller flera slavar. Här är MCU:n master och
FPGA:n slav.

| Ledning | Riktning | Betydelse |
|---|---|---|
| `SCK` | master → slav | Klocka. Ingenting händer utan flanker på den. |
| `MOSI` | master → slav | *Master Out, Slave In*: masterns data. |
| `MISO` | slav → master | *Master In, Slave Out*: slavens data. |
| `SS` | master → slav | *Slave Select*, aktiv låg. Frames transaktionen. |

Den viktigaste egenskapen: **SPI är full duplex.** Varje klockpuls skiftar samtidigt en bit ut på
`MOSI` och en bit in på `MISO`. Det finns inget sätt att "bara läsa" - för att få en byte in
måste man skicka en byte ut. Därför skickar en läsning fyra dummybytes `0x00`, och därför är de
fyra `MISO`-byten under en skrivning meningslösa skräp.

---

## 2. Parametrarna

| Parameter | Värde |
|---|---|
| Roller | MCU är master, FPGA är slav. |
| Läge | SPI mode 0 (CPOL = 0, CPHA = 0). |
| Bitordning | MSB först, i varje byte. |
| `SCK`-frekvens | <= 1 MHz. AVR32DB28:n går på 4 MHz och dividerar med 4. |
| `SS` | Aktiv låg. Framingsignal: en transaktion per låg period. |
| Spänning | Kärnan går på 5 V, `PORTC` på 3,3 V via `VDDIO2`. **Ingen nivåomvandlare behövs.** |

### Mode 0, ritad

```text
SS     ‾‾‾‾\____________________________________________/‾‾‾‾

SCK    ________/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\____
                 ^     ^     ^     ^     ^     ^     ^     ^
                 |     |     |     |     |     |     |     |
MOSI   ‾‾‾‾X  b7 X  b6 X  b5 X  b4 X  b3 X  b2 X  b1 X  b0 X‾‾‾‾
```

* `SCK` vilar **låg** (CPOL = 0).
* Data samplas på **stigande** flank (CPHA = 0), markerad med `^`.
* Data byts på fallande flank.
* MSB först: `b7` är den första biten ut.

`MISO` följer samma mönster åt andra hållet: slaven byter sin utgång på fallande flank, och
mastern samplar den på stigande.

### Varför slaven inte klockar på `SCK`

FPGA:n kör på 50 MHz. `SCK` kommer utifrån, är asynkron mot den klockan, och skulle - använd som
klocka - skapa en andra klockdomän i designen med allt vad det innebär.

I stället **översamplas** `SCK`: den synkroniseras in med två vippor och flankerna *detekteras* i
50 MHz-domänen. Vid `SCK <= 1 MHz` går det minst 50 systemcykler per SPI-bit, alltså gott om
marginal.

Konsekvensen för er: protokollet garanterar korrekt funktion **upp till 1 MHz**. Snabbare kan
fungera, och är medvetet inte lovat. Kör inte snabbare vid bring-upen bara för att det går.

---

## 3. Transaktionen

**Varje transaktion är exakt fem bytes**: en kommandobyte följd av fyra databytes. `SS` faller
före kommandobyten och stiger efter den femte byten, och måste ligga låg hela vägen.

### Kommandobyten

```text
Bit:      7    6    5    4    3    2    1    0
        +----+----+----+----+----+----+----+----+
        | W  | 0  | 0  | 0  |   register index  |
        +----+----+----+----+----+----+----+----+
```

* **Bit 7 (`W`)**: `1` = skrivning, `0` = läsning.
* **Bitarna 6-4**: reserverade, ska vara `0`.
* **Bitarna 3-0**: registerindex, `0-12`, ur
  [registerkartan](../../L04/appendix/b_register_map_and_architecture.md#2-registerkartan).

I C++ blir det, med konstanterna från [**P03** avsnitt 8](../../../projects/P03/README.md#8-milstolpe-4---bytetransport-och-transaktionslagret):

```cpp
const std::uint8_t command{static_cast<std::uint8_t>(CmdWrite | index)};  // skrivning
const std::uint8_t command{index};                                        // läsning
```

### Skrivning (`W = 1`)
Mastern skickar registervärdet i de fyra databyten, **MSB först**: bitarna 31-24 i första
databyten. Slaven verkställer det hopsatta värdet **först när den femte byten är hel**. Det
slaven driver på `MISO` under en skrivning är meningslöst; kasta det.

### Läsning (`W = 0`)
I slutet av kommandobyten **låser slaven registrets aktuella värde en gång**, in i sin
svarsskiftare. De fyra databyten klockar sedan ut det värdet på `MISO`, MSB först, medan mastern
skickar dummybytes `0x00`.

**Låsningsregeln är en del av kontraktet, inte en implementationsdetalj.** De fyra byten hör
alltid till *ett* sammanhängande prov av registret, taget i ett ögonblick. Utan den regeln hade
en `STATUS`-läsning kunnat bli ihopsydd av två olika tidpunkter: TX-klar-biten från före en
sändning och RX-giltig-biten från efter. Det hade varit en bugg som uppträder ungefär en gång på
tusen och aldrig går att återskapa.

### Avbrott
Går `SS` hög innan den femte byten är hel överges transaktionen **utan sidoeffekter**: ingenting
verkställs, ingen trigger går, och slaven återgår till vila redo för nästa fallande `SS`-flank.
Det är vad som gör slaven självläkande efter en glitch eller en omstartad master.

### Ogiltiga kommandon
* En läsning av ett reserverat index (13-15) ger `0x00000000`; en skrivning ignoreras.
* En kommandobyte med någon av de reserverade bitarna 6-4 satt är ogiltig på samma sätt: ingen
  läsning låses och ingen skrivning verkställs. Slaven konsumerar ändå hela fembytesframen innan
  den återgår till vila.

Inget av det rapporteras som fel. **Det finns ingen felkanal på det här lagret.** En drivrutin som
skickar skräp får tyst nonsens tillbaka, och det är den sortens bugg som `ScriptedTransport` i
[L11](../../L11/README.md) finns till för att fånga.

---

## 4. `SS`-reglerna

Tre regler som alla har kostat någon en kväll:

**En transaktion per låg `SS`-period.** Mastern måste släppa `SS` hög mellan transaktioner.

**Back-to-back fungerar inte, och misslyckas tyst.** En sjätte byte som kommer medan `SS`
fortfarande är låg **kastas** - den tolkas inte som en ny kommandobyte. En transaktion börjar
bara på den första byten efter att `SS` fallit. Att slaven är ledig räcker alltså inte för att
starta en.

**Setup och hold kring `SS`.** Eftersom `SS` synkroniseras och flankdetekteras behöver den några
systemcykler för att slå igenom:

| Parameter | Minimum |
|---|---|
| `SS` låg före första stigande `SCK`-flank | 60 ns (3 cykler) |
| `SS` hög mellan transaktioner | 60 ns (3 cykler) |
| `SS` låg efter sista `SCK`-flank | 60 ns (3 cykler) |

Räkna med 100 ns för var och en i drivrutinen och ingenting av det här är i närheten av att bli
ett problem. En AVR som växlar en GPIO mellan två `transfer()`-anrop är redan långsammare än så.
Siffrorna spelar roll först om `SS` drivs av hårdvara.

Det är därför `ByteTransport` har **`select()` och `deselect()` som egna metoder** i stället för
att transporten skulle gissa var en transaktion börjar och slutar: framingen är drivrutinens
beslut, inte transportens.

---

## 5. `MISO` utanför en läsning

* `MISO` drivs **låg** medan slaven är avvald - den släpps inte till högimpedans. Designen
  förutsätter en enda slav på bussen.
* Byten mastern klockar ut **under kommandobyten** är meningslös. Slaven laddar sin svarsskiftare
  i *slutet* av kommandobyten, så det som lämnar under den är rester från förra gången. **Kasta
  den.**
* Under en skrivning är alla fyra `MISO`-databytes meningslösa.

---

## 6. Ett komplett exempel

Att skicka en frame (`id 0x123`, `dlc 2`, data `AA BB`) är fem transaktioner, sedan en pollning:

```text
Skriv TX_ID      : 81 00 00 01 23
Skriv TX_DLC     : 82 00 00 00 02
Skriv TX_DATA_LO : 83 AA BB 00 00
Skriv TX_DATA_HI : 84 00 00 00 00
Skriv TX_SEND    : 85 00 00 00 01
Läs   STATUS     : 00 xx xx xx xx   -> MISO ger 00 00 00 00 under sändning,
                                       sedan 00 00 00 01 när porten är fri igen.
```

Läs av kommandobyten i varje rad: `0x81` är `CmdWrite | 1`, alltså en skrivning till index 1,
`TX_ID`. `0x00` på sista raden är en läsning av index 0, `STATUS`.

Notera `83 AA BB 00 00`: **databyte 0 i den mest signifikanta positionen.** Det är samma packning
på båda sidor av ledningen - er drivrutin sätter ihop den, och `register_bank` presenterar
`TX_DATA_LO` som de *första* fyra bytesen. Byteordningsdiagrammet i
[L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md#5-databyteordning) är bilden
av det.

---

## 7. Vad det kostar i tid

En transaktion är 5 bytes = 40 bitar. Vid 1 MHz `SCK` tar själva klockningen 40 µs, plus
`SS`-hantering och den tid mastern behöver mellan byten.

Räkna med **ungefär 40-50 µs per transaktion**, och därmed:

| Operation | Transaktioner | Ungefärlig tid |
|---|---:|---|
| `hasError()` | 1 | ~45 µs |
| `clearError()` | 1 | ~45 µs |
| `receive()`, ingen frame | 1 | ~45 µs |
| `receive()`, en frame | 6 | ~270 µs |
| `send()` | 6 | ~270 µs |

Sätt det mot CAN-sidan: en maximal CAN-frame är omkring 130 bitar, alltså **130 µs** vid 1 Mbit/s.

Två slutsatser följer, och båda är värda att ha med sig till [L13](../../L13/README.md):

* **En `send()` tar längre tid än framen den skickar.** SPI-länken, inte CAN-bussen, är
  flaskhalsen i den här konstruktionen.
* **Pollningen kan missa frames.** Kontrollern buffrar inte: kommer två frames tätt inpå varandra
  och er `receive()` tar 270 µs, hinner den andra skriva över den första. Det är hårdvarans
  dokumenterade begränsning, inte er bugg - men det är er kod som märker den.

---

## 8. Pinnkonfigurationen

Fastlagd i kontraktet, så att vilken MCU-nod som helst passar i vilket FPGA-kort som helst:

| Signal | AVR32DB28 | DE0-CV port | DE0-CV pin |
|---|---|---|---|
| `SCK` | `PC2` | `sclk` | `GPIO_0(4)` |
| `MOSI` | `PC0` | `mosi` | `GPIO_0(5)` |
| `MISO` | `PC1` | `miso` | `GPIO_0(6)` |
| `SS` | `PC3` | `ss` | `GPIO_0(7)` |
| I/O-matning | `VDDIO2` | - | `3.3 V` |
| Jord | `GND` | - | `GND` |

`GPIO_0(0)` till `GPIO_0(2)` är reserverade för CAN-sidan, och `GPIO_0(3)` är medvetet oanvänd
som lucka mellan de två grupperna, så att ett bandkabelstift fel inte kortsluter något mellan
domänerna.

**Varför just `PORTC`** - och därmed `SPI0`:s ALT1-mux i stället för standardmuxen på
`PA4`-`PA7` - står i [L12 bilaga A](../../L12/appendix/a_avr32db28_spi.md). Kort: `PORTC` är
AVR-DB:ns MVIO-domän, matad från `VDDIO2`, vilket låter alla fyra SPI-ledningar ligga på 3,3 V
medan kärnan går på 5 V. Ingen nivåomvandlare.

**Avvikelser** är tillåtna men måste skrivas ned där den andra klassen ser dem. Ett odokumenterat
pinnbyte visar sig som en nod som svarar på registerläsningar men aldrig sänder en frame, vilket är
ett dyrt sätt att upptäcka en kopplingskonvention.

---
