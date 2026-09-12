# L01 - Frames

## Dagordning
* Kursöversikt: tre delar, ett projekt, en dugga och en obligatorisk labb.
* Vad är ett kommunikationsprotokoll?
* Problem med ostrukturerad datakommunikation (råa byte-strömmar utan struktur, synkronisering
  eller validering).
* Framestruktur: synkronisering (SOF), längd, typ, adresser, sekvensnummer, payload, checksumma.
* Ett första protokoll: design och implementation.

---

## Mål med lektionen
* Förstå vad ett kommunikationsprotokoll är och varför det behövs.
* Förstå skillnaden mellan frame och byte-ström.
* Kunna beskriva hur en frame är uppbyggd, fält för fält.
* Kunna implementera en enkel frame i C++, med `serialize()` och `deserialize()`.

---

## Förutsättningar
* Grundläggande C/C++ (pekare, arrayer, funktioner och struktar).

---

## Instruktioner

### Förberedelse
* Läs igenom kursinformationen [här](../../info/README.md).
* Läs igenom [bilaga A](./appendix/a_frames.md) för information om frames.

### Under lektionen
* Genomför övningsuppgifter i [bilaga B](./appendix/b_exercises.md).

### Demonstration
* En korrekt frame och hur denna packas upp (via deserialisering).
* En frame med trasig checksumma och hur det upptäcks.
* Vanlig bug: endianness (hur `0x0005` kan tolkas som `0x0500`).

---

## Lektionsanteckningar
Lösningsförslag för övningsuppgifterna finns [här](./notes/README.md).

---

## Utvärdering
* Förstår ni vad ett kommunikationsprotokoll är?
* Förstår ni varför följande fält behövs:
    * SOF
    * Payload-längden
    * Frame-typen
    * Destinationsadressen
    * Avsändaradressen
    * Sekvensnumret
    * Payloaden
    * Checksumman
* Vilka av fälten ovan tror ni att CAN har, och vilka tror ni att det saknar? Spara svaret till
  [L04](../L04/README.md).

---

## Nästa lektion
* Implementation av en byte-stream parser:
    * I denna lektion antar vi att vi alltid får en komplett frame i en buffer.
    * Nästa lektion behandlar verkligheten, där data överförs byte för byte.

---
