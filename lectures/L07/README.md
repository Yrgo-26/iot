# L07 - Komponenttest genom stubben: `app::EchoNode`

## Dagordning
* Testpyramidens andra nivå: flera delar tillsammans, fortfarande utan hårdvara.
* Dependency injection: varför `EchoNode` tar en `Interface&` i stället för att skapa sin egen
  drivrutin.
* Live-kodning av `app::EchoNode`.
* Komponenttestning: att skripta inkommande frames med `inject()` och kontrollera vad som skickas.
* Vilken sorts bugg ett komponenttest fångar som ett enhetstest inte kan se.
* Arbete med **P03** (milstolpe 3).

---

## Mål med lektionen
* Kunna förklara skillnaden mellan enhetstest och komponenttest, med ett konkret exempel på en
  bugg bara det senare fångar.
* Kunna implementera en applikationskomponent som bara beror på ett interface.
* Kunna motivera varför komponenten håller en referens och inte äger drivrutinen.
* Kunna skriva ett komponenttest som injicerar en testdubblare och skriptar ett förlopp.
* Kunna avgöra om en given rad kod bryter mot lagergränsen i arkitekturen.

---

## Förutsättningar
* [L06](../L06/README.md): `Interface` och `Stub`, med grön testsvit.
* Från C++-kursen: referenser som medlemmar, `explicit` konstruktorer.

---

## Instruktioner

### Förberedelse
* Läs [bilaga A](./appendix/a_component_testing.md) om komponenttestning: vad det är, var
  lagergränsen går, och vad den utdelade sviten bevisar respektive inte bevisar.
* Läs [**P03** avsnitt 7](../../projects/P03/README.md#7-milstolpe-3---appechonode-appecho_nodeh).

### Under lektionen
* Delta i live-kodningen: `app/echo_node.hpp` och `source/app/echo_node.cpp`.
* Ta upp era svar från [L06 bilaga B uppgift 6](../L06/appendix/b_exercises.md) i helklass.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga B](./appendix/b_exercises.md).
* **Milstolpe 3** ska vara klar: `EchoNode` finns, med komponenttester genom stubben.

---

## Demonstration
* `EchoNode` som ekar en injicerad frame, körd helt utan hårdvara.
* Samma `EchoNode`-kod med en drivrutin som returnerar `false` på `send()` - och vad komponenten
  gör då.
* En bugg som bara ett komponenttest hittar: `receive()` anropas två gånger per `run()`, och
  varje enhetstest är ändå grönt.

---

## Utvärdering
* Vad är skillnaden mellan ett enhetstest och ett komponenttest, konkret?
* Varför tar `EchoNode` sin drivrutin genom konstruktorn i stället för att skapa den själv?
* Varför är konstruktorn `explicit`?
* Varför håller `EchoNode` en referens och inte en `std::unique_ptr`?
* Hur skulle ni testa att `EchoNode` beter sig rätt när `send()` misslyckas?
* Vilken rad i `EchoNode` skulle en granskare stoppa direkt om den innehöll ordet `Spi`?

---

## Nästa lektion
* Ned under interfacet. Vi lämnar applikationen och tittar på hur registren faktiskt nås: SPI
  från vågformen och uppåt, och transaktionsprotokollet som är kontraktets andra halva.

---
