# L11 - Testning av drivrutinen utan hårdvara

## Dagordning
* Genomgång av de två utdelade testdubblarna: `ScriptedTransport` och `BankTransport`.
* Skillnaden mellan dem: "skickade drivrutinen rätt bytes?" och "beter sig drivrutinen rätt?".
* Genomgång av den utdelade testsviten, fall för fall, mot registerkartan och protokollet.
* Att läsa ett fallerande testfall och gå raka vägen till buggen.
* `EchoNode` körd mot `Spi` mot `BankTransport`: hela stacken på laptopen.
* Utdelning av övningsduggan.
* Arbete med **P03** (milstolpe 6).

---

## Mål med lektionen
* Kunna förklara vilken sorts bugg `ScriptedTransport` fångar och `BankTransport` missar, och
  tvärtom.
* Kunna läsa ett testfall i den utdelade sviten och säga vilket krav i
  [L04 bilaga B](../L04/appendix/b_register_map_and_architecture.md) eller
  [L08 bilaga A](../L08/appendix/a_spi.md) det svarar mot.
* Kunna använda ett fallerande testfall för att lokalisera en bugg utan att gissa.
* Kunna förklara varför hela stacken går att köra utan hårdvara, och exakt vilken egenskap hos
  arkitekturen som gör det möjligt.
* Kunna redogöra för vad en grön testsvit **inte** bevisar.

---

## Förutsättningar
* [L10](../L10/README.md): `Spi` komplett, med alla fyra metoder implementerade.
* [L05 bilaga B](../L05/appendix/b_unit_testing.md): testpyramiden och hur en testfil läses.

---

## Om testerna
**Ni skriver inga tester.** Både testdubblarna och testsviten är utdelade och läggs in
oförändrade. Ert jobb är att få dem gröna, och att kunna läsa vad de säger.

Att skriva tester lär ni er i *Mjuk- och hårdvarutestning*, som kommer efter den här kursen.
Ordningen är avsiktlig: den som har sett en testsvit hitta en riktig bugg i sin egen drivrutin
har en helt annan bild av vad ett bra test är än den som ombeds skriva ett först.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_testing_the_driver.md) **eller** kapitel 11 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).

### Under lektionen
* Delta i genomgången av testdubblarna och sviten.
* Lägg in de utdelade filerna och kör `make test`.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga B](./appendix/b_exercises.md).
* **Milstolpe 6** ska vara klar: hela den utdelade testsviten är grön.
* Läs igenom [övningsduggan](../../exam/practice_exam.md). Den gås igenom i
  [L15](../L15/README.md), men den som börjar då börjar för sent.

---

## Demonstration
* Ett testfall i `ScriptedTransport`-sviten jämfört rad för rad mot `81 00 00 01 23` i
  [L08 bilaga A](../L08/appendix/a_spi.md#6-ett-komplett-exempel).
* `BankTransport` som vägrar en `send()` därför att TX-klar är låg, och samma bank efter en
  simulerad avslutad sändning.
* `EchoNode` + `Spi` + `BankTransport`: en injicerad frame som ekas genom hela stacken, utan
  hårdvara.
* Ett medvetet infört fel i `pack()`, och exakt vilken rad i utskriften som pekar ut det.

---

## Utvärdering
* Vilken av de två testdubblarna hade fångat att `TX_DATA_LO` och `TX_DATA_HI` förväxlats?
  Vilken hade inte gjort det?
* Vilken hade fångat att `clearError()` skriver `0x1`?
* Varför kan `EchoNode` köras mot `Spi` utan att en enda rad i `EchoNode` ändras?
* Vad bevisar en grön testsvit - och vad bevisar den inte?
* Vilka fel återstår som bara bring-upen kan hitta?

---

## Nästa lektion
* Den riktiga transporten. AVR32DB28:s SPI0, `volatile` på riktiga hårdvaruregister, MVIO och
  `VDDIO2` - och factoryn som binder ihop allt till en körbar applikation.

---
