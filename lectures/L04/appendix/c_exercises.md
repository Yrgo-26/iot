# Bilaga C

## Övningsuppgifter

Uppgifterna görs med papper och penna. Det skrivs ingen kod idag - poängen är att ni ska kunna
*läsa* ett hårdvarukontrakt innan ni börjar koda mot det, eftersom nästan varje bugg i det här
projektet uppstår i översättningen mellan
[bilaga B](./b_register_map_and_architecture.md) och C++.

Ta fram [bilaga B](./b_register_map_and_architecture.md) och ha den framme.

---

## Del 1 - Vad CAN gör åt oss

### **1.** Mekanism för mekanism
Fyll i tabellen. För varje mekanism ni byggde i L01-L03: vem gör den i ett CAN-system, och var?

| Mekanism (L01-L03) | Vem gör den i CAN? | Var? |
|---|---|---|
| Framesynkronisering (SOF) | | |
| Längdfält (LEN) | | |
| Adressering (DST/SRC) | | |
| Sekvensnummer (SEQ) | | |
| Checksumma (CHK) | | |
| Kvittens (ACK/NACK) | | |
| Kollisionshantering | | |
| Timeout och retry | | |
| Dubblettdetektion | | |

Två rader har inget självklart svar. Vilka, och varför?

### **2.** Adressering utan adresser
CAN-framen har ingen destinationsadress. Ändå fungerar CAN utmärkt i system med dussintals noder.
Förklara i två-tre meningar hur en mottagare vet att en frame angår den, och vad det får för
konsekvens för hur ett CAN-system designas jämfört med ert eget protokoll.

### **3.** Prioritet
Två noder börjar sända samtidigt. Nod A har identifieraren `0x100`, nod B har `0x0FF`.
* Vilken vinner arbitreringen?
* Vad gör förloraren?
* Vad hade hänt om båda hade haft `0x100`?

---

## Del 2 - Registerkartan

### **4.** Läs kartan
Svara utan att slå upp, och kontrollera sedan:
* Vilka register är **skrivbara men inte läsbara**?
* Vilket register nollställs av en skrivning av `0x0`, och inte av `0x1`?
* Vad returnerar en läsning av index 14?
* Vad händer om ni skriver `0x00000009` till `TX_DLC` och läser tillbaka registret?
* Vad händer om ni skriver till `RX_DLC`?

### **5.** Packa en frame
Ni ska skicka en frame med `id = 0x2A7`, `dlc = 5` och data `01 02 03 04 05`.

Skriv upp de fem registervärdena som ska skrivas, på hexadecimal form:

```text
TX_ID      = 0x________
TX_DLC     = 0x________
TX_DATA_LO = 0x________
TX_DATA_HI = 0x________
TX_SEND    = 0x________
```

### **6.** Packa upp en frame
Ni läser följande:

```text
RX_ID      = 0x00000481
RX_DLC     = 0x00000003
RX_DATA_LO = 0xDEADBE00
RX_DATA_HI = 0x00000000
```

* Vilken identifierare kom framen ifrån?
* Vilka databytes innehåller den, i ordning?
* Hur många bytes ska hamna i `frame.data`, och vad ska de övriga vara?
* Vilket register måste ni skriva till innan nästa frame kan tas emot, och med vilket värde?

### **7.** En felaktig drivrutin
Nedan är fyra påståenden om en drivrutin. Tre av dem beskriver en bugg. Vilka, och vad går fel?

1. "Efter `send()` pollar vi `STATUS` bit 0 och returnerar `true` när den kommer tillbaka -
   då vet vi att framen kom fram."
2. "`clearError()` skriver `0x1` till `ERROR_FLAGS` för att nollställa felbiten."
3. "`receive()` kopierar alltid alla åtta bytes från `RX_DATA_LO`/`HI` till `frame.data`."
4. "`send()` kontrollerar `STATUS` bit 0 innan den skriver `TX_SEND`."

### **8.** Den pulsande kontrollern
`can_controller` signalerar en avslutad sändning med en puls som är **en klockcykel** lång, 20 ns
vid 50 MHz. Er drivrutin pollar över SPI, och en transaktion tar omkring 40 µs.

* Hur många kontrollercykler hinner passera mellan två pollningar?
* Vad hade hänt om `STATUS` bit 0 hade speglat pulsen direkt i stället för att låsas?
* Varför måste biten nollställas av en *skrivning* och inte automatiskt vid läsning?

---

## Del 3 - Arkitekturen

### **9.** Rita arkitekturen
Rita **P03**:s lagerarkitektur ur minnet, från `app::EchoNode` ned till CAN-bussen. Markera med
en linje var gränsen går mellan det ni skriver och det hårdvaruklassen skriver, och med en till
var gränsen går mellan det som vet om SPI och det som inte gör det.

### **10.** Vem får veta vad?
För var och en av följande: sant eller falskt, och varför?

1. `app::EchoNode` får inkludera `driver/can/spi.hpp`.
2. `driver::can::Spi` får inkludera `driver/can/interface.hpp`.
3. `driver::can::Stub` behöver en `ByteTransport`.
4. `driver::can::ByteTransport` behöver känna till registerkartan.
5. Ett test av `EchoNode` behöver en `ByteTransport`.

### **11.** Sömmen som inte är uppenbar
`driver::can::Interface` gör `Stub` och `Spi` utbytbara. Varför räcker inte det - varför lägger
vi in ytterligare en söm (`ByteTransport`) *under* `Spi`?

Svara genom att beskriva en konkret bugg som `ByteTransport` gör det möjligt att hitta på er
laptop, men som annars hade väntat till [L13](../../L13/README.md).

### **12.** Förbered kontakten med hårdvarugruppen
Läs igenom [bilaga B](./b_register_map_and_architecture.md) en gång till och skriv ned **minst två
frågor** som kartan inte svarar på entydigt. Ta med dem till er hårdvarugrupp.

Det här är inte en konstruerad uppgift: kartan *är* ofullständig på ett par punkter, precis som
alla verkliga kravspecifikationer, och att upptäcka det nu i stället för under bring-upen är hela
poängen.

---
