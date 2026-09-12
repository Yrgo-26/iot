# Bilaga B

## Övningsuppgifter

Uppgifterna görs med papper och penna. Det skrivs ingen kod idag - i [L09](../../L09/README.md)
blir protokollet C++, och då ska det sitta.

Ha [bilaga A](./a_spi.md) och
[L04 bilaga B](../../L04/appendix/b_register_map_and_architecture.md) framme.

---

## Del 1 - Vågformen

### **1.** Rita mode 0
Rita `SS`, `SCK`, `MOSI` och `MISO` för en enda byte, `0xB4`, skickad från mastern.

* Markera varje flank där data **byts**.
* Markera varje flank där data **samplas**.
* Skriv ut bitarna i den ordning de går ut.

### **2.** Full duplex
Mastern skickar `0x00` och får tillbaka `0x2A`.

* Hur många klockpulser krävdes?
* Varför måste mastern skicka något alls när den bara vill läsa?
* Vad hade hänt om den hade skickat `0xFF` i stället för `0x00`?

### **3.** Översampling
FPGA:n kör på 50 MHz och `SCK` är 1 MHz.

* Hur många systemcykler går det per SPI-bit?
* Varför synkroniseras `SCK` med två vippor innan den används?
* Protokollet garanterar funktion upp till 1 MHz men inte över. Varför är det formulerat som ett
  löfte om en gräns i stället för ett förbud?

---

## Del 2 - Transaktionen

### **4.** Avkoda
För var och en av följande transaktioner: är det en läsning eller en skrivning, vilket register,
och vilket värde?

```text
a)  81 00 00 07 FF
b)  00 00 00 00 05
c)  8B 00 00 00 00
d)  04 00 00 00 00
e)  8A 00 00 00 01
f)  C2 00 00 00 03
```

Två av dem är ovanliga på var sitt sätt. Vilka, och varför?

### **5.** Koda
Skriv upp den kompletta femBytestransaktionen, på hexadecimal form, för var och en av:

a) Skriv `TX_DLC = 4`.
b) Läs `RX_ID`.
c) Skriv `TX_DATA_LO` för databytesen `11 22 33 44`.
d) Trigga en sändning.
e) Kvittera en mottagen frame.
f) Nollställ felregistret.

Notera särskilt skillnaden mellan (e) och (f).

### **6.** En hel sändning
Skriv upp **alla** transaktioner som krävs för att skicka en frame med `id = 0x555`, `dlc = 3` och
data `DE AD BE`, från den första statuskontrollen till att sändningen är utlöst.

Hur många transaktioner blev det? Ungefär hur lång tid tar det vid 1 MHz?

### **7.** Vad kommer tillbaka?
Under transaktionen `81 00 00 07 FF` (en skrivning) klockar mastern in fem bytes på `MISO`.

* Hur många av dem betyder något?
* Under transaktionen `00 00 00 00 00` (en läsning av `STATUS`), hur många av de fem `MISO`-byten
  betyder något, och vilka?
* En grupp skriver en drivrutin som sätter ihop returvärdet av **alla fem** `MISO`-byten i stället
  för de fyra sista. Vad händer? Hur skulle det se ut i felsökningen?

---

## Del 3 - `SS` och felfallen

### **8.** Avbrutna transaktioner
För var och en: vad händer?

a) `SS` går hög efter tre av fem bytes i en **skrivning** till `TX_ID`.
b) `SS` går hög efter tre av fem bytes i en **läsning** av `STATUS`.
c) `SS` går hög efter fem bytes, men mastern klockar ut en sjätte byte innan den gör det.
d) Mastern håller `SS` låg och skickar tio bytes i sträck: `81 00 00 01 23 82 00 00 00 02`.

Fall (d) är det farliga. Varför, och hur skulle symptomet se ut vid bring-upen?

### **9.** Reserverade bitar
Mastern skickar kommandobyten `0x91`.

* Vilket index pekar den på?
* Vad gör slaven?
* Rapporteras något som fel? Varför / varför inte?
* Var i **er** kod ska det förhindras att en sådan kommandobyte ens byggs?

### **10.** Låsningen vid läsning
Slaven låser det lästa registervärdet **en gång**, i slutet av kommandobyten.

* Beskriv, steg för steg, vad som hade kunnat gå fel vid en `STATUS`-läsning om den regeln inte
  fanns och de fyra byten lästes ur registret var för sig.
* Varför skulle just den buggen vara svår att hitta?
* Vilken av de tre statusbitarna skulle drabbas oftast, och varför?

---

## Del 4 - Tidsbudget

### **11.** Räkna
Vid 1 MHz `SCK`:

a) Hur lång tid tar en transaktion, ungefär?
b) Hur lång tid tar en `receive()` som inte hittar någon frame?
c) Hur lång tid tar en `receive()` som hittar en frame?
d) Hur lång tid tar en maximal CAN-frame på bussen, vid 1 Mbit/s?

### **12.** Konsekvensen
Två noder på bussen. Den andra noden skickar frames så fort den kan.

* Hur ofta kan er nod som bäst anropa `receive()`?
* Kontrollern buffrar inte: den håller exakt en mottagen frame. Vad händer med frames som kommer
  medan er `receive()` fortfarande pågår?
* Är det er bugg? Vad kan ni göra åt det, och vad kan ni inte?

Ta med svaret till [L13](../../L13/README.md) - det är exakt den situationen ni kommer att stå i
vid bring-upen.

---
