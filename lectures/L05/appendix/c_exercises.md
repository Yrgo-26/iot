# Bilaga C

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 1** i [**P03**](../../../projects/P03/README.md#5-milstolpe-1---frame-driverconframeh).
Arbeta i gruppens repo, i branchen `feature/frame`.

---

### **1.** Skapa `driver::can::Frame`
Skapa filen `include/driver/can/frame.hpp` och implementera `Frame` enligt
[bilaga A](./a_frame.md):

* `static constexpr std::uint8_t MaxDataLen{8U};`
* `std::uint16_t id{};`
* `std::uint8_t dlc{};`
* `std::uint8_t data[MaxDataLen]{};`

Krav:
* Doxygen-kommentar på filen, på structen och på varje medlem.
* Ingen `.cpp`-fil.
* Filen ska kompilera fristående: ett testprogram som bara inkluderar `frame.hpp` ska bygga.

---

### **2.** Implementera `isValid()`
Lägg till den fria funktionen i samma header:

```cpp
[[nodiscard]] constexpr bool isValid(const Frame& frame) noexcept;
```

Den ska returnera `true` om `frame.id <= 0x7FFU` och `frame.dlc <= Frame::MaxDataLen`.

**Kontrollera att den verkligen är `constexpr`** genom att skriva:

```cpp
static_assert(driver::can::isValid(driver::can::Frame{0x7FFU, 8U, {}}));
static_assert(!driver::can::isValid(driver::can::Frame{0x800U, 0U, {}}));
```

Om de raderna kompilerar är funktionen utvärderad vid kompileringstillfället, och ni har fått ett
gratis test som aldrig ens behöver köras.

---

### **3.** Kör den utdelade testsviten
Lägg in den utdelade testsviten `test/test_frame.cpp` oförändrad och kör den:

```bash
git submodule update --init
make test
```

**Ni skriver inga tester i den här kursen.** Sviterna är utdelade; ert jobb är att få dem att
passera, och att kunna läsa vad de säger. Att skriva dem lär ni er i *Mjuk- och
hårdvarutestning* längre fram.

---

### **4.** Läs testsviten som en kravspecifikation
Öppna `test/test_frame.cpp` och besvara, utan att köra den:

1. Vilka **gränsvärden** testar sviten för `id` respektive `dlc`? Varför just de, och inte
   värden mitt i intervallet?
2. Vilket testfall skulle fallera om ni skrev `frame.dlc < Frame::MaxDataLen` i stället för
   `<=` i `isValid()`? Vilka skulle fortfarande vara gröna?
3. Peka ut Arrange, Act och Assert i ett av testfallen. Vilken av de tre delarna *är* kravet?
4. Finns det något krav i [bilaga A](./a_frame.md) som sviten **inte** kontrollerar? Skriv ned
   vilket.

Fråga 4 har ett svar, och det är värt att hitta: en grön testsvit betyder inte att koden är rätt,
bara att den är rätt på de punkter sviten frågar om.

---

### **5.** Bryt koden med flit, och läs felet
Ändra tillfälligt `isValid()` så att `id`-gränsen blir `<` i stället för `<=`. Kör sviten.

* Vilket testfall fallerar, och vad står det i utskriften?
* Följ arbetsgången i
  [bilaga B avsnitt 5](./b_unit_testing.md#5-att-läsa-en-fallerande-testsvit): läs testnamnet,
  sedan Arrange, sedan den fallerande Assert-raden. Hur lång tid tog det att hitta felet i koden
  när ni gjorde så?
* Återställ koden.

---

### **6.** Förutsäg innan ni kör
Skriv ned era svar **innan** ni kompilerar, och kontrollera dem sedan:

1. Vad är `sizeof(driver::can::Frame)` på er maskin? Varför är det inte 11?
2. Kompilerar `driver::can::Frame f{0x123U, 2U, {0xAAU, 0xBBU}};`? Vad blir `f.data[7]`?
3. Kompilerar `driver::can::Frame f{0x123U, 2U, {0xAAU, 0xBBU}}; f.data[8] = 0U;`?
   Vad *händer* om den gör det?
4. Vad händer om ni lägger till en egen konstruktor till `Frame` och sedan försöker kompilera
   raden i fråga 2?

Fråga 3 och 4 är de intressanta. Diskutera dem i gruppen.

---

### **7.** Formattering och varningar
Kör, i projektkatalogen:

```bash
make format-check
```

och kompilera testsviten med `-Wall -Wextra -Werror`. Båda ska vara rena innan ni öppnar en
Pull Request. Det är samma kontroller CI kör, och samma kontroller en granskare kommer att titta
efter.

---

### **8.** Öppna en Pull Request
* Pusha `feature/frame` och öppna en PR mot `main`.
* Låt en annan gruppmedlem granska den.
* Granskaren ska ställa **minst en riktig fråga** - inte "ser bra ut". Ett förslag: varför
  `constexpr` på `isValid()`, och vad det köper.
* Uppdatera `CONTRIBUTORS.md`.

---

## Reflektion inför L06
* `Frame` gick att testa helt utan hårdvara. Vilken egenskap hos klassen gjorde det möjligt?
* Nästa klass är `driver::can::Interface`, som inte kan göra någonting alls. Hur testar man
  något som inte har en implementation?

---
