# L08 - SPI från vågformen och transaktionsprotokollet

## Dagordning
* Under interfacet: hur registren i [L04](../L04/README.md) faktiskt nås.
* SPI från vågformen och uppåt: master/slave, de fyra ledningarna, lägen, MSB först.
* `SS` som framing - och varför det inte bara är en chip select.
* Transaktionen: en kommandobyte plus fyra databytes, alltid exakt fem.
* Låsning vid läsning, verkställande vid skrivning, och avbrott på `SS`.
* Att avkoda en transaktion för hand, ur en logikanalysatorutskrift.
* Arbete med **P03**.

---

## Mål med lektionen
* Kunna rita SPI mode 0 för en byte: `SCK`, `MOSI`, `MISO` och `SS`, med rätt flanker.
* Kunna förklara varför slaven översamplar `SCK` i stället för att klocka på den.
* Kunna avkoda en fembytestransaktion för hand och säga vilket register som lästes eller skrevs,
  och med vilket värde.
* Kunna förklara varför läsningen låser registervärdet **en gång**, och vad som hade gått fel
  annars.
* Kunna redogöra för `SS`-reglerna: en transaktion per låg period, avbrott utan sidoeffekter,
  och varför en sjätte byte inte startar en ny transaktion.
* Kunna räkna ut ungefär hur lång tid en `send()` tar, och vad det betyder för pollning.

---

## Förutsättningar
* [L04](../L04/README.md): registerkartan. Idag handlar det om *hur* registren nås, inte om vad
  de betyder.
* Grundläggande digitalteknik: klocka, flank, skiftregister.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_spi.md) **eller** kapitel 8 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)). Det är kontraktets andra
  halva, och det läses lika noga som registerkartan i
  [L04 bilaga B](../L04/appendix/b_register_map_and_architecture.md).

### Under lektionen
* Delta i genomgången.
* Genomför övningsuppgifterna i [bilaga B](./appendix/b_exercises.md). De görs med papper och
  penna: det skrivs ingen kod idag heller.

### Efter lektionen
* Stäm av med er hårdvarugrupp att ni läser samma version av protokollet, och att ni är överens
  om pinnkonfigurationen.

---

## Demonstration
* En byte klockad ut på en logikanalysator, avkodad flank för flank.
* En komplett `TX_ID`-skrivning: `81 00 00 01 23`, och samma sekvens med `SS` uppsläppt för
  tidigt.
* Vad `MISO` bär under kommandobyten, och varför den byten ska kastas.

---

## Utvärdering
* Vilka fyra ledningar har SPI, och vem driver vilken?
* I mode 0: på vilken flank läggs data ut, och på vilken samplas den?
* Hur ser kommandobyten ut, bit för bit?
* Vad returnerar en läsning av index 14, och varför är det inte ett fel?
* Vad händer om `SS` går hög efter tre av fem bytes?
* Varför får två transaktioner inte ligga back-to-back under en och samma låga `SS`?
* Hur många transaktioner kostar en `send()`, och ungefär hur lång tid tar det vid 1 MHz?

---

## Nästa lektion
* Protokollet blir kod: `ByteTransport`-sömmen och `readReg`/`writeReg`.

---
