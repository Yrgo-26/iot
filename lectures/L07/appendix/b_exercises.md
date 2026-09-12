# Bilaga B

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 3** i
[**P03**](../../../projects/P03/README.md#7-milstolpe-3---appechonode-appecho_nodeh). Arbeta i
branchen `feature/echo-node`.

---

### **1.** Skapa `app::EchoNode`
Skapa `include/app/echo_node.hpp` och `source/app/echo_node.cpp` enligt
[bilaga A](./a_component_testing.md).

Krav:
* Konstruktorn är `explicit`, tar `driver::can::Interface&` och `std::uint16_t`, och är
  `noexcept`.
* Medlemmarna är `myDriver` (referens), `myResponseId` och `myEchoCount`.
* All initiering i initialiseringslistan.
* Headern **framåtdeklarerar** `driver::can::Interface` och inkluderar ingen drivrutinsheader.
* `echoCount()` är `[[nodiscard]]`, `const` och `noexcept`.

---

### **2.** Kör det utdelade komponenttestet
Lägg in `test/test_echo_node.cpp` oförändrad och kör `make test`. Sviten täcker de sex fallen i
[bilaga A avsnitt 4](./a_component_testing.md#4-vad-den-utdelade-sviten-täcker).

Läs den sedan, och svara:
1. Vilket av de sex fallen skulle fortfarande vara grönt om `run()` glömde att räkna upp
   `myEchoCount`?
2. Hur får testet in en frame i systemet, och hur läser det tillbaka den ekade framen? Vilken
   metod används i vartdera fallet, och varför finns den inte i `Interface`?
3. Fallet som anropar `run()` **två** gånger på en injicerad frame - vilket krav uttrycker det?

---

### **3.** Skriv buggen, se testet fånga den
Ändra tillfälligt `run()` så att den anropar `receive()` två gånger, precis som i
[bilaga A avsnitt 1](./a_component_testing.md#1-vad-ett-komponenttest-är).

* Kör `make test`. Vilka testfall fallerar, och vilka är fortfarande gröna?
* Kör bara enhetstesterna för `Stub` och `Frame`. Fallerar något av dem?
* Återställ koden.

Skriv ned i två meningar vad övningen visade. Den ska med i `p03_report.md`.

---

### **4.** En drivrutin som misslyckas
Den utdelade sviten innehåller ett fall där `send()` returnerar `false`, och kontrollerar att
`echoCount()` då **inte** går upp. För att det ska fungera behöver stubben kunna misslyckas på
begäran:

```cpp
/**
 * @brief Make the next call to send() fail, simulating busy hardware.
 */
void failNextSend() noexcept;
```

* Lägg till metoden i `Stub` så att testfallet passerar.
* Frågan att svara på i gruppen: hör den här metoden hemma i `Stub`, eller är det början på den
  "stubb som växer tills den är en andra implementation av hårdvaran" som
  [L06 bilaga A](../../L06/appendix/a_interface_and_stub.md#4-vad-stubben-inte-simulerar) varnar
  för? Motivera.

---

### **5.** Lagergränsen, i praktiken
För var och en av raderna nedan: bryter den mot arkitekturens lagergräns? Motivera i en mening.

1. `#include "driver/can/interface.hpp"` i `echo_node.hpp`.
2. `#include "driver/can/stub.hpp"` i `test_echo_node.cpp`.
3. `#include "driver/can/stub.hpp"` i `echo_node.cpp`.
4. `driver::can::Frame frame{};` i `echo_node.cpp`.
5. `if (myDriver.hasError()) { myDriver.clearError(); }` i `run()`.
6. `static_cast<driver::can::Spi&>(myDriver).readReg(0U);` i `run()`.

Rad 5 är den intressanta: den bryter inte mot någon gräns, men är den en bra idé? Vem borde
hantera fel, och varför?

---

### **6.** Förutsäg innan ni kör
1. Vad händer om ni glömmer `explicit` och sedan skriver `app::EchoNode node = stub;`?
   (Tips: konstruktorn tar två parametrar. Vad blir felmeddelandet?)
2. Vad händer om ni byter `driver::can::Interface& myDriver` mot
   `driver::can::Interface myDriver`? Vad säger kompilatorn, och varför?
3. Vad händer om ni skapar `EchoNode` med en `Stub` som går ur scope innan `run()` anropas?
   Kompilerar det? Vad blir fel?

---

### **7.** Pull Request
Öppna en PR, låt en annan gruppmedlem granska. Granskaren ska särskilt kontrollera att
`echo_node.hpp` inte inkluderar någon konkret drivrutin, och ställa minst en fråga om varför
räknaren räknas upp där den räknas upp.

---

## Reflektion inför L08
Ni har nu ett komplett, testat system som inte kan prata med någonting.

* Vad återstår, konkret, för att `EchoNode` ska kunna eka en riktig CAN-frame?
* `Stub` lagrar en frame i minnet. Vad ska `Spi` göra i stället - och hur många gånger måste den
  prata med hårdvaran för att göra det?

---
