# L04 - CAN-bussen, registerkartan och drivrutinsarkitekturen

## Dagordning
* CAN: bussen, framen, prioritet och arbitrering.
* Vad hårdvaran gör åt oss - och därmed vad ni *inte* behöver skriva i **P03**.
* Registerkartan till hårdvaruklassens CAN-kontroller: vad varje register betyder.
* Klibbiga bitar: varför registerbanken finns mellan kontrollern och er drivrutin.
* Lagerarkitekturen **P03** ska byggas i, och vem som får veta vad.
* Start av **P03**: genomgång av projektbeskrivningen och milstolparna.

---

## Mål med lektionen
* Kunna förklara CAN-ID, prioritet, DLC och hårdvaruarbitrering.
* Kunna peka ut, mekanism för mekanism, vilka delar av L01-L03 som CAN gör i hårdvara.
* Kunna läsa en registerkarta och säga vilka register som är läsbara, skrivbara respektive
  triggande, och vad varje statusbit betyder.
* Kunna förklara varför kontrollerns encykelspulser behöver göras om till klibbiga, pollbara
  bitar, och vad det kostar drivrutinen.
* Kunna rita **P03**:s lagerarkitektur ur minnet och säga vad varje lager inte vet om lagret
  under.
* Känna till de tre begränsningar i hårdvaran som drivrutinen måste hantera och inte dölja.

---

## Förutsättningar
* L01-L03: eget protokoll, parser, buss och tillförlitlighetsmekanismer. Vi kommer att jämföra
  mot dem hela lektionen.
* Från C++-kursen: abstrakta basklasser, polymorfism och interface-baserad drivrutinsdesign.

---

## Instruktioner

### Förberedelse
* Läs **kapitel 1, 2 och 7** i CAN-boken
  ([svenska](https://github.com/Yrgo-26/can-book/blob/main/sv/can-sv.pdf),
  [engelska](https://github.com/Yrgo-26/can-book/blob/main/en/can-en.pdf)).
  [Bilaga A](./appendix/a_can.md) är läsanvisningen: vad ni ska läsa och vad ni ska ha med er
  därifrån.
* Läs **antingen** [bilaga B](./appendix/b_register_map_and_architecture.md): registerkartan och
  arkitekturen, **eller** kapitel 4 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)). Det är kursens viktigaste
  stoff - hela **P03** skrivs mot det.
* Läs projektbeskrivningen för [**P03**](../../projects/P03/README.md) i sin helhet.

### Under lektionen
* Delta i genomgången.
* Genomför övningsuppgifterna i [bilaga C](./appendix/c_exercises.md). De görs med papper och
  penna: det skrivs ingen kod idag.
* Sätt upp gruppens repo enligt [projektstrukturen](../../projects/P03/README.md#3-projektstruktur),
  och lägg till `qacademy::test` som submodul.

### Efter lektionen
* Ta kontakt med er hårdvarugrupp. Stäm av att ni läser samma version av registerkartan, och
  kom överens om hur ni meddelar varandra om något i den behöver ändras.

---

## Demonstration
* En CAN-frame på oscilloskop/logikanalysator: SOF, identifierare, DLC, data, CRC, ACK, EOF.
* Två noder som sänder samtidigt, och vem som vinner - arbitrering utan bussmästare.
* Registerkartan läst uppifrån och ned, med den kompletta sändningssekvensen som exempel:
  fem skrivningar, en trigger och en pollning.

---

## Utvärdering
* Vilka mekanismer från L01-L03 slipper ni implementera nu, och var tog CAN hand om dem?
* Vad betyder `STATUS` bit 0, och vilken skrivning nollställer den?
* Vad betyder det att `ERROR_FLAGS` nollställs av `0x0` och inte av `0x1`, och varför skiljer
  sig den regeln från `TX_SEND`:s?
* Varför delas `TX_DATA` upp i `_LO` och `_HI` i stället för att vara ett brett register?
* Varför kan drivrutinen inte skilja en förlorad arbitrering från en lyckad sändning genom att
  bara titta på `STATUS` bit 0?
* I lagerarkitekturen: vilket lager är det *enda* som får känna till att kommunikationen går
  över SPI?

---

## Nästa lektion
* Vi börjar koda. `driver::can::Frame` live-kodas, och enhetstestas med `qacademy::test` - utan en
  enda rad hårdvarukod.

---
