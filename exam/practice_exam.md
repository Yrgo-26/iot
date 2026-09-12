# Övningsdugga - Kommunikationsprotokoll & IoT

## Information

### Hjälpmedel
* En fusklapp på ett A4-blad (båda sidor får användas).
* Hexadecimal miniräknare.
* Registerkartan i [bilaga 1](#bilaga-1--registerkartan) nedan. Den delas ut med duggan.

### Poänggränser och betygsnivåer
Totalt: 25 poäng, fördelade på två delar.

| Del | Innehåll | Poäng |
|---|---|---:|
| A | Det egna protokollet (L01-L03) | 12 |
| B | CAN och drivrutinen (L04-L12) | 13 |

Betygsgränser:
* **G:** minst 12 poäng, med minst 4 poäng i vardera delen.
* **VG:** minst 19 poäng.

Bidrag till kursens slutpoäng:
* Betyget **G** ger 2 poäng till kurssammanställningen.
* Betyget **VG** ger 4 poäng till kurssammanställningen.

### Instruktioner
* Svara kort och tydligt.
* Visa uträkningarna där ni räknar.

---

# Del A - Det egna protokollet (12p)

Anta att vår checksumma är en 16-bitars summering av **alla bytes fram till CHK-fältet**.
Fält större än 1 byte (SOF, SEQ, CHK) skickas big-endian.

Framestruktur:

```text
SOF (2) | LEN (1) | TYPE (1) | DST (1) | SRC (1) | SEQ (2) | DATA (N) | CHK (2)
```

Frametyper:

| Typ | Värde |
|---|---|
| Ping | `0x00` |
| Pong | `0x01` |
| StatusRequest | `0x02` |
| StatusResponse | `0x03` |
| Ack | `0x04` |
| Nack | `0x05` |

`SOF = 0xA5F7` (2 bytes, big-endian).

---

### **1.** Bygg två frames för hand (4p)

**a)** Nod A har adress `0x17` och skickar en `StatusRequest` till en temperatursensor med adress
`0x25`. Sekvensnumret är `0x7F05`. Skriv upp hela framen byte för byte på hexadecimal form. (2p)

**b)** Sensorn svarar med ett `StatusResponse` innehållande temperaturen `0x16` (1 byte). Skriv
upp hela den framen byte för byte. (2p)

---

### **2.** Frame-parser (2p)
En frame-parser använder följande tillstånd:

```text
WaitForSof1 → WaitForSof2 → WaitForLen → WaitForType → WaitForDst → WaitForSrc
            → WaitForSeq1 → WaitForSeq2 → WaitForPayload → WaitForChk1 → WaitForChk2 → Ready
```

**a)** Beskriv kort vad parsern gör i `WaitForSof1` respektive `WaitForSof2`. (1p)

**b)** Parsern står i `WaitForSof2` och tar emot en byte som **inte** är `0xF7`. Vad ska den göra?
Det finns ett svar som är nästan rätt och ett som är rätt - motivera vilket som är vilket. (1p)

---

### **3.** Buss och routing (2p)
Vi har en broadcast-buss där alla noder tar emot alla bytes.

**a)** Sker routingen i bussen eller i noden? Motivera. (1p)

**b)** En nod tar emot en frame med korrekt checksumma, men `DST` är inte nodens adress. Vad ska
noden göra, och varför ska den **inte** skicka NACK? (1p)

---

### **4.** Tillförlitlighet (2p)
**a)** Nod A skickar en `StatusRequest` och får ingen `Ack`. Beskriv flödet med timeout och retry.
Ska `SEQ` vara samma eller nytt vid omsändningen, och varför? (1p)

**b)** `Ack`-framen tappas på vägen tillbaka, så nod A skickar om. Nod B tar emot samma frame en
andra gång. Vad ska B göra med den, och vad ska den **inte** göra? (1p)

---

### **5.** Byte-ström och felmodell (2p)
En nod tar emot följande byte-ström:

```text
32 74 00 FF A5 F7 03 03 25 17 7F 05 10 20 30 02 C2
```

**a)** Vid vilket index börjar framen, och vad ska parsern göra med datan före den? (1p)

**b)** Antag i stället att byten `0x20` tappas under överföringen:

```text
32 74 00 FF A5 F7 03 03 25 17 7F 05 10 30 02 C2
```

Vad händer med tolkningen av framen, och i vilket tillstånd hamnar parsern till slut? (1p)

---

# Del B - CAN och drivrutinen (13p)

Använd registerkartan i [bilaga 1](#bilaga-1--registerkartan).

---

### **6.** CAN-bussen (3p)
**a)** Vad är ett CAN-ID, och vilka **två** roller har det? (1p)

**b)** Två noder börjar sända samtidigt. Nod A har identifieraren `0x100`, nod B har `0x0FF`.
Vilken vinner arbitreringen, vad gör förloraren, och varför krävs ingen bussmästare? (1p)

**c)** Räkna upp **tre** mekanismer från del A som ni **inte** behövde implementera i mjukvara i
**P03**, och säg för var och en var i systemet den utförs i stället. (1p)

---

### **7.** Registerkartan (4p)
**a)** Ni ska skicka en frame med `id = 0x2A7`, `dlc = 5` och databytesen `01 02 03 04 05`. Skriv
upp de fem registervärdena som ska skrivas, i den ordning de ska skrivas: (2p)

```text
______________ = 0x________
______________ = 0x________
______________ = 0x________
______________ = 0x________
______________ = 0x________
```

Varför spelar ordningen roll?

**b)** Ni läser följande: (1p)

```text
RX_ID      = 0x00000481
RX_DLC     = 0x00000003
RX_DATA_LO = 0xDEADBE00
RX_DATA_HI = 0x00000000
```

Vilken identifierare kom framen från, vilka databytes innehåller den, och vad ska
`frame.data[3]` till `frame.data[7]` innehålla efter `receive()`?

**c)** Vilket register måste skrivas innan nästa frame kan tas emot, och med vilket värde? Vad
händer om drivrutinen glömmer det? (1p)

---

### **8.** SPI-transaktionen (3p)
Följande bytes går ut på **MOSI**. För var och en: är det en läsning eller en skrivning, vilket
register, och vilket värde? (2p)

```text
a)  81 00 00 07 FF
b)  85 00 00 00 01
c)  8B 00 00 00 00
d)  C2 00 00 00 03
```

**e)** Skriv upp den kompletta femBytestransaktionen för att **läsa** `RX_DLC`. (1p)

---

### **9.** Klibbiga bitar och begränsningar (3p)
**a)** `can_controller` signalerar en avslutad sändning med en puls som är en klockcykel lång,
20 ns vid 50 MHz. En SPI-transaktion tar omkring 40 µs. Förklara varför registerbanken behövs,
och varför `STATUS` bit 0 måste nollställas av en **skrivning** i stället för automatiskt vid
läsning. (1p)

**b)** Er nod sänder en frame och förlorar arbitreringen. `STATUS` bit 0 kommer tillbaka precis som
vid en lyckad sändning. Vad ska drivrutinen göra för att ta reda på hur det gick, och vad kan den
fortfarande **inte** ta reda på? (1p)

**c)** `clearError()` skriver `0x0` till `ERROR_FLAGS`, medan `receive()` skriver `0x1` till
`RX_ACK`. En student tycker att det är inkonsekvent och skriver `0x1` i båda. Vad blir symptomet,
och när upptäcks det? (1p)

---

### **10.** Arkitekturen (VG-uppgift, ingår i poängen ovan)
Ingår i uppgift 7-9 ovan som delfrågor på den skarpa duggan. Öva på följande:

* Rita drivrutinsarkitekturen från `app::EchoNode` ned till CAN-bussen, och markera var gränsen
  går mellan det som vet om SPI och det som inte gör det.
* En gruppmedlem lägger till `#include "driver/can/spi.hpp"` i `echo_node.hpp` "för att kunna logga
  statusregistret". Vilka tre saker går sönder?
* `driver::can::Interface` gör `Stub` och `Spi` utbytbara. Varför räcker inte det - vad köper
  `ByteTransport` som ligger *under* `Spi`?

---

## Bilaga 1 - Registerkartan

Varje register är 32 bitar. **Indexet** är det som går ut i kommandobyten.

| Index | Register | Åtkomst | Beskrivning |
|---:|---|---|---|
| 0 | `STATUS` | R | Bit 0: TX klar. Bit 1: RX giltig. Bit 2: Fel. |
| 1 | `TX_ID` | R/W | 11-bitars sändar-ID (bitarna 10-0). |
| 2 | `TX_DLC` | R/W | Data Length Code (bitarna 3-0, värde 0-8). |
| 3 | `TX_DATA_LO` | R/W | Sändardata byte 0-3 (byte 0 = MSB). |
| 4 | `TX_DATA_HI` | R/W | Sändardata byte 4-7 (byte 4 = MSB). |
| 5 | `TX_SEND` | W | Skriv `0x1` för att utlösa sändning. |
| 6 | `RX_ID` | R | Mottagen identifierare (bitarna 10-0). |
| 7 | `RX_DLC` | R | Mottagen DLC (bitarna 3-0). |
| 8 | `RX_DATA_LO` | R | Mottagen data byte 0-3. |
| 9 | `RX_DATA_HI` | R | Mottagen data byte 4-7. |
| 10 | `RX_ACK` | W | Skriv `0x1` för att kvittera och tömma RX-bufferten. |
| 11 | `ERROR_FLAGS` | R/W | Felregistret; skriv `0x0` för att nollställa. |
| 12 | `TX_ABORT` | W | Skriv `0x1` för att tvinga tillbaka TX klar. |

**STATUS:**

| Bit | Betydelse | Nollställs av |
|---:|---|---|
| 0 | TX klar | en accepterad skrivning till `TX_SEND` |
| 1 | RX giltig | en skrivning av `0x1` till `RX_ACK` |
| 2 | Fel | en skrivning av `0x0` till `ERROR_FLAGS` |

**SPI-transaktionen:** exakt fem bytes - en kommandobyte plus fyra databytes, MSB först, med `SS`
låg hela vägen.

```text
Bit:      7    6    5    4    3    2    1    0
        +----+----+----+----+----+----+----+----+
        | W  | 0  | 0  | 0  |   register index  |
        +----+----+----+----+----+----+----+----+
```

`W = 1` betyder skrivning, `W = 0` läsning. Bitarna 6-4 är reserverade och ska vara `0`.

**Databyteordning:**

```text
bit 63                                                              bit 0
+--------+--------+--------+--------+--------+--------+--------+--------+
| byte 0 | byte 1 | byte 2 | byte 3 | byte 4 | byte 5 | byte 6 | byte 7 |
+--------+--------+--------+--------+--------+--------+--------+--------+
 \___________ TX_DATA_LO ___________/ \___________ TX_DATA_HI __________/
```

---
