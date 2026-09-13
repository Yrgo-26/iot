# L06 - `driver::can::Interface` och `driver::can::Stub`

## Dagordning
* Repetition: interface och polymorfism från C++-kursen.
* Sömmen: vad `driver::can::Interface` ska - och framför allt inte ska - innehålla.
* Live-kodning av `driver/can/interface.hpp`.
* Live-kodning av `driver/can/stub.hpp`: en testdubblare som simulerar CAN i minnet.
* Varför stubben har `inject()`, och varför den metoden inte finns i interfacet.
* Arbete med **P03** (milstolpe 2).

---

## Mål med lektionen
* Kunna skriva en ren abstrakt basklass med virtuell destruktor, och förklara varför
  destruktorn måste vara virtuell.
* Kunna motivera varje `noexcept`, `[[nodiscard]]` och `const` i interfacets signaturer.
* Kunna förklara varför interfacet inte innehåller en enda metod som avslöjar hur hårdvaran nås.
* Kunna implementera en stubb som uppfyller interfacet och simulerar rimligt beteende i minnet.
* Kunna förklara varför `inject()` ligger i stubben och inte i interfacet.
* Kunna motivera att kopierings- och flyttoperationerna tas bort.

---

## Förutsättningar
* [L05](../L05/README.md): `Frame` och `isValid()`, med grön testsvit.
* Från C++-kursen: arv, virtuella funktioner, abstrakta basklasser, `override`, `final`,
  `= default` och `= delete`.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_interface_and_stub.md), som går igenom `Interface` och
  `Stub`: vad en söm är och varför kursen har två, vad som inte hör hemma i interfacet, och vad
  stubben inte simulerar, **eller** kapitel 6 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).
* Läs [**P03** avsnitt 6](../../projects/P03/README.md#6-milstolpe-2---interface-och-stub).

### Under lektionen
* Delta i live-kodningen: `interface.hpp` och `stub.hpp` skrivs från tomma filer.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga B](./appendix/b_exercises.md).
* **Milstolpe 2** ska vara klar: `Interface` och `Stub` finns, med enhetstester för stubben.

---

## Demonstration
* Ett `driver::can::Interface&` som pekar på en `Stub`, och samma referens som senare pekar på
  något helt annat - utan att anroparens kod ändras.
* Vad som händer om destruktorn *inte* är virtuell och objektet raderas genom en basklasspekare.
* Ett försök att kopiera en `Stub`, och kompilatorfelet det ger.

---

## Utvärdering
* Varför måste `Interface`-destruktorn vara virtuell, och varför `= default`?
* Varför är `hasError()` både `const`, `noexcept` och `[[nodiscard]]`?
* Varför returnerar `send()` en `bool` i stället för att kasta ett undantag?
* Varför tar `receive()` en `Frame&` som utargument i stället för att returnera en `Frame`?
* Vad hade gått sönder i designen om `inject()` hade legat i `Interface`?
* Varför tas kopierings- och flyttoperationerna bort?

---

## Nästa lektion
* Den första klassen som *använder* interfacet: `app::EchoNode`, testad genom stubben. Andra
  nivån i testpyramiden.

---
