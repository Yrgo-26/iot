# L14 - CAN-labb med Vector CANalyzer

> **Obligatorisk labb, andra passet.** Representanter från **Vector** är på plats.
> **Er länk ska fungera när passet börjar** - labbtiden går åt till att analysera trafik, inte
> till att hitta en felkopplad ledning. Se [labb-PM:et](../../lab/README.md).

## Dagordning
* Introduktion till CANalyzer, med Vector.
* Er egen nod på bussen: frames från er drivrutin, lästa i CANalyzer.
* Trace-fönstret: identifierare, DLC, data, tidsstämplar och bussbelastning.
* Att skicka frames **från** CANalyzer till er nod, och se `receive()` ta emot dem.
* Statistik och felräknare: vad CANalyzer säger om en buss med två noder av olika mognad.
* Analys: hårdvaruklassens dokumenterade förenklingar mot riktig CAN, sedda utifrån.
* Avslutning: en frame spårad hela vägen, med namn på varje lager och vem som byggde det.

---

## Mål med lektionen
* Kunna identifiera en CAN-frame i CANalyzers trace, och läsa ut identifierare, DLC och data.
* Kunna verifiera att en frame som er drivrutin skickade kom fram med rätt innehåll.
* Kunna skicka en frame från CANalyzer och visa att er `receive()` tog emot och kvitterade den.
* Kunna tolka CANalyzers felräknare, och koppla en rapporterad avvikelse till en **dokumenterad**
  förenkling i hårdvaruklassens konstruktion.
* Kunna spåra en frame genom hela stacken, från `EchoNode` till bussen, och namnge varje lager.

---

## Förutsättningar
* [L13](../L13/README.md) genomförd, med en **fungerande** länk. Det är inte ett riktvärde: utan
  trafik på bussen finns ingenting att analysera, och labben blir inte godkänd.
* Grundläggande förståelse för CAN-framens fält, från [L04 bilaga A](../L04/appendix/a_can.md).

---

## Instruktioner

### Förberedelse
* Läs [labb-PM:et](../../lab/README.md), särskilt avsnittet om CANalyzer och
  redovisningskraven.
* Läs kapitel 14 i kursboken ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)): att läsa en trace, och att
  leta efter konstruktionens förenklingar.
* Ta med en fungerande nod och den bring-up-logg ni fyllde i under [L13](../L13/README.md).

### Under passet
* Delta i Vectors genomgång.
* Genomför uppgifterna i [labb-PM:et](../../lab/README.md#del-2---canalyzer).
* **Redovisa för läraren:** visa i CANalyzer en frame er drivrutin skickat, och en frame er
  drivrutin tagit emot och kvitterat. Det är kravet för godkänd labb.

### Efter passet
* Komplettera `p03_report.md` med era observationer, särskilt de förenklingar ni kunde se
  utifrån.

---

## Utvärdering
* Vilka fält i en CAN-frame kan ni se i CANalyzer som er registerkarta **inte** exponerar?
* Kvitterar CANalyzer era frames? Hur vet ni det, och vad hade hänt om ingen nod gjorde det?
* Hårdvarukonstruktionen läser aldrig tillbaka ACK-luckan. Hur påverkar det vad er drivrutin kan
  veta - och märks det i CANalyzer?
* Vad rapporterar CANalyzer för felräknare, och vilka av avvikelserna är förväntade givet
  konstruktionens dokumenterade förenklingar?
* Spåra en frame från `EchoNode::run()` till CAN_H/CAN_L. Hur många lager passerade den, och vilka
  av dem skrev ni själva?

---

## Nästa lektion
* Genomgång av övningsduggan, kursutvärdering, och **D01 - Duggan**.

---
