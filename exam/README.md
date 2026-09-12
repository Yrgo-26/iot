# D01 - Dugga

## Information
Duggan genomförs under [L15](../lectures/L15/README.md) och ger upp till **4 poäng**
(**G** = 2p, **VG** = 4p) av kursens 8.

Den täcker kursens **båda** halvor.

---

### Del A - Det egna protokollet (L01-L03)
* Design av egna kommunikationsprotokoll: framestruktur och fältens syfte.
* Skillnaden mellan byte-ström och strukturerad frame.
* Serialisering och deserialisering, inklusive endianness.
* Validering: SOF, längd, typ, checksumma.
* Parsning som tillståndsmaskin.
* Adressering (DST/SRC) och routing mellan noder på en broadcast-buss.
* Sekvensnummer (SEQ) och dess syfte.
* Skillnaden mellan integritet (checksumma) och leveransgaranti.
* ACK/NACK, timeout och retry.
* Dubbletter: hur de uppstår och vad de får för konsekvenser.
* Fel i byte-ström: tappade bytes, korrupt data och fördröjning.

### Del B - CAN och drivrutinen (L04-L12)
* CAN-bussen: identifierare, prioritet, DLC och hårdvaruarbitrering.
* Vilka mekanismer från del A som CAN utför i hårdvara, och var.
* Registerkartan: vad varje register betyder, vilka som är läs-, skriv- respektive
  triggerregister.
* `STATUS`-bitarnas betydelse, och hur var och en nollställs.
* Databyteordningen över `TX_DATA_LO`/`HI`.
* SPI-transaktionen: kommandobyten, de fyra databyten, MSB först, och `SS`-reglerna.
* Att avkoda och konstruera en transaktion för hand.
* Lagerarkitekturen: vilka lager som finns, och vad varje lager inte vet om lagret under.
* Konstruktionens tre dokumenterade begränsningar, och hur en drivrutin hanterar dem.

---

## Uppdelning
Duggan är uppdelad i:

* **G-uppgifter** - grundläggande förståelse:
    * Frame-design och checksumberäkning.
    * Parserlogik och byte-ström.
    * Adressering (DST/SRC) och sekvensnummer (SEQ).
    * CAN-ID, arbitrering och vad hårdvaran gör.
    * Att läsa registerkartan och packa en frame i register.
    * Att avkoda en SPI-transaktion.
* **VG-uppgifter** - fördjupning:
    * Tillförlitlig kommunikation: ACK/NACK, timeout, retry.
    * Analys av fel i byte-ström och deras konsekvenser.
    * Dubbletter och varför de uppstår.
    * Klibbiga statusbitar: varför de behövs och vad som händer utan dem.
    * Lagerarkitekturens gränser, och konsekvenserna av att bryta dem.
    * Konstruktionens begränsningar och vad de gör omöjligt för drivrutinen.

---

## Genomförande
Duggan genomförs med papper och penna.

**Tillåtna hjälpmedel:**
* En fusklapp på ett A4-blad; båda sidor får användas.
* Hexadecimal miniräknare.

Byte-sekvenser, checksumberäkningar och registerpackning ska kunna göras manuellt. Ni ska kunna
tolka och analysera både byte-strömmar och SPI-transaktioner.

**Registerkartan delas ut med duggan.** Ni behöver inte memorera indexen - däremot ska ni kunna
läsa kartan och veta vad den betyder.

---

## Övningsdugga
[Övningsduggan](./practice_exam.md) visar vad som förväntas, i samma format och med samma
poängfördelning som den skarpa duggan.

Den delas ut efter [L11](../lectures/L11/README.md) och gås igenom i
[L15](../lectures/L15/README.md). **Börja inte på den i L15** - L13 och L14 är labbpass utan tid
för repetition.

---
