# L05 - `driver::can::Frame` och den första testsviten

## Dagordning
* Repetition: registerkartan, och vilken data en CAN-frame faktiskt bär.
* Live-kodning av `driver::can::Frame`: en aggregate, inte ett objekt.
* Var validering hör hemma när hårdvaran inte validerar någonting.
* Testpyramiden: enhetstest, komponenttest, integrationstest.
* Kursens utdelade testsviter: `qacademy::test`, `TEST()`, `EXPECT_*` och Arrange-Act-Assert -
  **att läsa och köra dem**, inte att skriva dem.
* Arbete med **P03** (milstolpe 1).

---

## Mål med lektionen
* Kunna implementera en aggregate enligt kursens namnkonventioner.
* Kunna förklara varför `Frame` medvetet saknar konstruktor, destruktor och metoder.
* Kunna motivera `static constexpr` framför `#define` för en klasskonstant.
* Kunna beskriva testpyramidens tre nivåer och placera `Frame` på rätt nivå.
* Kunna köra en utdelad testsvit, och läsa ett testfall som ett krav: vad Arrange, Act och
  Assert säger var för sig.
* Kunna använda ett fallerande testfall för att hitta buggen i sin egen kod, utan att gissa.

---

## Förutsättningar
* [L04](../L04/README.md): registerkartan och arkitekturen.
* Från C++-kursen: aggregates, default member initialization, `std::uint8_t`-familjen och
  `static constexpr`.
* Gruppens repo uppsatt enligt
  [projektstrukturen](../../projects/P03/README.md#3-projektstruktur), med `qacademy::test` som
  submodul.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_frame.md) om `Frame` och var validering hör hemma och
  [bilaga B](./appendix/b_unit_testing.md) om testpyramiden, testramverkets API, Arrange-Act-Assert
  och hur en fallerande svit läses, **eller** kapitel 5 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).
  **Ni skriver inga tester i den här kursen** - det gör ni i *Mjuk- och hårdvarutestning*
  längre fram. Här ska ni kunna läsa dem och få dem att passera.

### Under lektionen
* Delta i live-kodningen: `driver/can/frame.hpp` skrivs från tom fil.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga C](./appendix/c_exercises.md).
* **Milstolpe 1** ska vara klar: `Frame` och `isValid()` finns och den utdelade testsviten
  passerar.

---

## Demonstration
* `Frame f{};` och vad varje medlem innehåller efteråt.
* Ett testfall som fallerar, och vad `qacademy::test` skriver ut: filen, raden och uttrycket.
* `sizeof(Frame)` - och varför den inte är 11 bytes.

---

## Utvärdering
* Varför behöver `Frame` varken konstruktor, destruktor eller medlemsfunktioner i den här
  designen?
* Vad hade ni förlorat om `isValid()` hade varit en medlemsfunktion i stället för en fri
  funktion?
* Varför ligger valideringen i drivrutinen och inte i hårdvaran?
* Vilka är testpyramidens tre nivåer, och varför är `Frame` ett naturligt *enhetstest*-objekt?
* Vad gör Arrange-, Act- respektive Assert-steget i ett testfall - och vilket av de tre *är*
  kravet?
* Varför använder den utdelade sviten `0x7FF` och `0x800` i stället för `0x400`?
* Varför går `Frame` att testa helt utan hårdvara och utan resten av drivrutinen?

---

## Nästa lektion
* `driver::can::Interface` och `driver::can::Stub`: sömmen som gör att applikationskoden aldrig
  behöver veta om den pratar med ett FPGA eller med en array i minnet.

---
