# Bilaga B

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 2** i
[**P03**](../../../projects/P03/README.md#6-milstolpe-2---interface-och-stub). Arbeta i branchen
`feature/interface` respektive `feature/stub`.

---

### **1.** Skapa `driver::can::Interface`
Skapa `include/driver/can/interface.hpp` enligt [bilaga A](./a_interface_and_stub.md).

Krav:
* Virtuell destruktor, `noexcept`, `= default`.
* Fyra ren virtuella metoder: `send()`, `receive()`, `hasError()`, `clearError()`.
* `[[nodiscard]]` på de tre som returnerar något.
* `const` och `noexcept` där [bilaga A](./a_interface_and_stub.md) säger det.
* Framåtdeklarera `Frame` i stället för att inkludera `frame.hpp`.
* Doxygen på filen, klassen och varje metod.

**Kontrollera att den är abstrakt.** Lägg till raden

```cpp
static_assert(!std::is_constructible_v<driver::can::Interface>);
```

i en testfil (med `#include <type_traits>`). Kompilerar den, är klassen ren abstrakt.

---

### **2.** Skapa `driver::can::Stub`
Skapa `include/driver/can/stub.hpp` och implementera stubben enligt tabellen i
[bilaga A](./a_interface_and_stub.md).

Krav:
* `final`, ärver `Interface` publikt.
* Medlemsvariabler: `myLastFrame`, `myInitialized`, `myHasData` - i den ordningen.
* All initiering i konstruktorns initialiseringslista.
* `override` på varje överskuggad metod.
* Kopierings- och flyttoperationerna borttagna med `= delete`, publikt.
* `inject()` finns i `Stub` men **inte** i `Interface`.

Implementationen får ligga i headern (stubben är liten och bara till för test).

---

### **3.** Kör den utdelade testsviten för stubben
Lägg in `test/test_stub.cpp` oförändrad och kör `make test`. Sviten innehåller bland annat:

* `receiveReturnsFalseWhenNoData`
* `sendThenReceiveReturnsSameFrame`
* `injectMakesFrameReadable`
* `secondReceiveReturnsFalse`
* `hasErrorIsAlwaysFalse`
* `clearErrorDoesNothing`

Få dem gröna. Fallerar något: läs testnamnet först, koden sedan.

---

### **4.** Läs testsviten, och hitta hjälpfunktionen
I `test/test_stub.cpp` finns en hjälpfunktion som tar en `driver::can::Interface&` i stället för
en `Stub&`:

```cpp
namespace
{
void sendAndExpectEcho(driver::can::Interface& driver);
} // namespace
```

* Leta upp den och läs den. Innehåller den ordet `Stub` någonstans?
* Varför är den skriven mot interfacet och inte mot den konkreta typen?
* I [L11](../../L11/README.md) anropas exakt samma funktion med en `Spi`. Vad i er kod måste
  stämma för att det ska gå?

---

### **5.** Förutsäg innan ni kör
Skriv ned svaren först, kompilera sedan:

1. Vad händer om ni tar bort `virtual` från destruktorn i `Interface`, skapar en `Stub` på heapen
   via `new`, och raderar den genom en `Interface*`? Kompilerar det? Vad blir *fel*?
2. Vad händer om ni tar bort `[[nodiscard]]` från `send()` och sedan skriver `driver.send(frame);`
   utan att ta emot returvärdet? Och med `[[nodiscard]]` kvar?
3. Vad säger kompilatorn om ni glömmer att överskugga `clearError()` i `Stub`?
4. Vad säger kompilatorn om ni stavar fel på en metod men skriver `override`? Och om ni utelämnar
   `override`?

Fråga 4 är skälet till att `override` är obligatoriskt i det här projektet.

---

### **6.** En designfråga att diskutera i gruppen
Någon i gruppen föreslår att lägga till en metod i `Interface`:

```cpp
[[nodiscard]] virtual std::uint32_t readStatusRegister() const noexcept = 0;
```

"Den är praktisk vid felsökning."

Skriv ett kort svar (fem-tio rader) på:
* Vad `Stub` skulle behöva returnera från den.
* Vad som händer med `EchoNode` om någon börjar använda den.
* Vad som händer den dag hårdvarugruppen byter registerkarta.
* Var metoden i stället hör hemma.

Ta med svaret till [L07](../../L07/README.md).

---

### **7.** Pull Request
Öppna en PR per branch, låt en annan gruppmedlem granska, och uppdatera `CONTRIBUTORS.md`.
Granskaren ska kontrollera att varje `noexcept`, `const` och `[[nodiscard]]` i interfacet går att
motivera - och fråga om något av dem.

---

## Reflektion inför L07
* Ni har nu två klasser som ingen använder. Vad saknas för att designen ska bevisa något?
* `EchoNode` kommer att ta en `Interface&` i konstruktorn i stället för att skapa sin egen
  drivrutin. Vad heter det mönstret, och vad köper det er i testerna?

---
