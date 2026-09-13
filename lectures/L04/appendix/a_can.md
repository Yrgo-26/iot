# Bilaga A

## CAN — läsanvisning

CAN som protokoll står i sin helhet i CAN-boken,
[**CAN - bussen, framen och kontrollern**](https://github.com/Yrgo-26/can-book/blob/main/sv/can-sv.pdf),
som också finns på engelska:
[**CAN - the bus, the frame and the controller**](https://github.com/Yrgo-26/can-book/blob/main/en/can-en.pdf).
Den här bilagan duplicerar den inte; den säger vad ni ska läsa, i vilken ordning, och vad ni ska ha
med er därifrån.

Boken är ungefär 55 sidor, och varje kapitel slutar med fyra övningar som alla besvaras i bokens
appendix A. Upplagorna har samma innehåll och samma kapitelnummer, så läsanvisningen nedan gäller
båda. Läs den med papper och penna framme.

---

## Inför den här lektionen

Läs **kapitel 1, 2 och 7**. De är de tre som L04 bygger direkt på.

| Kapitel | Ämne | Varför det behövs i L04 |
|---|---|---|
| 1 | Bussen | Dominant och recessiv, wired-AND. Utan den asymmetrin går varken arbitrering eller registerkartans felhantering att förstå. |
| 2 | Framen | Identifieraren, DLC och databytesen — exakt de tre fält registerkartan exponerar. |
| 7 | Den förenklade kontrollern | Vad hårdvaruklassens konstruktion gör, och vad den inte gör. |

Kapitel 7 är det viktigaste av de tre. Det är också det enda som inte handlar om CAN i allmänhet
utan om just den kontroller ni skriver drivrutin mot.

---

## Läs senare under kursen

De övriga kapitlen behövs inte för att komma igång, men de förklarar varför hårdvaran beter sig
som den gör, och de ingår i duggan.

| Kapitel | Ämne | När |
|---|---|---|
| 3 | Bitstoppning och CRC-15 | När ni undrar varför en frames längd inte går att räkna ut exakt ur DLC. |
| 4 | Arbitrering | När ni skriver felhanteringen i [L10](../../L10/README.md) och behöver veta varför en förlorad arbitrering ser ut som den gör. |
| 5 | Bittajming | Inför [L13](../../L13/README.md), där bithastighet och sampelpunkt ska ställas in på riktig hårdvara. |
| 6 | Felhantering | När ni vill veta vad en fullständig CAN-kontroller gör som den här inte gör. |

---

## Det ni ska ha med er

Efter kapitel 1, 2 och 7 ska ni kunna svara på följande utan att slå upp. Frågorna återkommer i
lektionens [övningar](./c_exercises.md) och i duggan.

* Vad betyder **dominant** och **recessiv**, och vilken av dem vinner?
* Varför har en CAN-frame ingen destinationsadress, och hur vet en mottagare att en frame angår
  den?
* Vilka två roller har identifieraren samtidigt?
* Hur många databytes rymmer en frame som mest, och hur många bitar är DLC-fältet?
* Vad gör sändaren respektive mottagaren i ACK-luckan?
* Varför räcker det inte att kontrollern signalerar med pulser — varför behövs ett registerlager
  emellan?
* Vilka tre av kontrollerns begränsningar når ända upp i drivrutinen?

Den sista frågan är den som kostar mest om den inte sitter. Svaret står i bokens kapitel 7 och,
i den form drivrutinen möter det, i
[bilaga B](./b_register_map_and_architecture.md#7-de-tre-begränsningarna-drivrutinen-måste-hantera).

---

## Vad boken inte täcker

Boken beskriver **klassisk CAN med 11-bitars identifierare**. Den går inte igenom CAN FD, CAN XL
eller högre lager som CANopen och J1939, och den beskriver inte elektriken i detalj.

Den beskriver inte heller **registerkartan**. Den är det här kursmaterialets sak, och står i
[bilaga B](./b_register_map_and_architecture.md), med hårdvaruklassens original i
[`projects/P03/contract/`](../../../projects/P03/contract/register_map.md).

---
