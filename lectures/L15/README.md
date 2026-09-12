# L15 - D01: Dugga

## Dagordning
* Kursutvärdering.
* Genomgång av [övningsduggan](../../exam/practice_exam.md).
* Genomförande av **D01**.

---

## Mål med lektionen
Visa förståelse för kursens båda halvor:

**Det egna protokollet (L01-L03):**
* Frame och parser, och skillnaden mellan byte-ström och strukturerad frame.
* Serialisering och deserialisering.
* Validering: SOF, längd, typ, checksumma.
* Adressering (DST/SRC), sekvensnummer (SEQ) och routing.
* Tillförlitlighet: ACK/NACK, timeout, retry och dubbletter.

**CAN och drivrutinen (L04-L12):**
* Vad CAN-hårdvaran gör som ni annars hade fått skriva själva.
* Registerkartan: vad varje register betyder, och hur en klibbig statusbit nollställs.
* SPI-transaktionen: kommandobyte, fyra databytes, och byteordningen.
* Lagerarkitekturen: vem får veta vad, och varför.
* De tre begränsningarna i konstruktionen, och hur en drivrutin hanterar dem.

---

## Förutsättningar
* Genomförande av L01-L14.
* [Övningsduggan](../../exam/practice_exam.md) genomarbetad **före** passet. Genomgången här är
  en genomgång, inte en första läsning.

---

## Instruktioner

### Förberedelse
* Gå igenom [övningsduggan](../../exam/practice_exam.md) och era svar.
* Repetera [L03](../L03/README.md)s fyra appendix - det är den delen av kursen som ligger längst
  bort i tiden och som väger tyngst i duggans första hälft.
* Förbered er fusklapp: ett A4-blad, båda sidor. Se [duggainformationen](../../exam/README.md).

### Under passet
* Kursutvärdering.
* Genomgång av övningsduggan.
* **D01**, skriftlig.

---

## Efter kursen
Två saker fortsätter direkt härifrån:

* **Mjuk- och hårdvarutestning.** Där skriver ni testerna ni har kört och läst genom hela det
  här projektet. Ni har sett vad de är till för; nu får ni bestämma vad de ska kontrollera.
* **Ert eget repo.** Drivrutinen ni byggt är en komplett, testad, lagerdelad drivrutinsstack mot
  riktig hårdvara. Det är ett rimligt första objekt i en portfölj.

---
