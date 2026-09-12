# Bilaga B

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 4** i
[**P03**](../../../projects/P03/README.md#8-milstolpe-4---bytetransport-och-transaktionslagret).
Arbeta i branchen `feature/transport`.

---

### **1.** Skapa `driver::can::ByteTransport`
Skapa `include/driver/can/byte_transport.hpp` enligt [bilaga A](./a_byte_transport.md).

Krav:
* Virtuell destruktor, `noexcept`, `= default`.
* Tre ren virtuella metoder: `select()`, `deselect()`, `transfer()`.
* `noexcept` på alla tre, `[[nodiscard]]` på `transfer()`.
* Doxygen på filen, klassen och varje metod.
* Headern inkluderar `<cstdint>` och ingenting annat.

---

### **2.** Deklarera `driver::can::Spi`
Skapa `include/driver/can/spi.hpp`:

* `final`, ärver `Interface` publikt.
* `explicit Spi(ByteTransport& transport) noexcept;`
* Kopierings- och flyttoperationerna borttagna, publikt.
* De fyra interfacemetoderna deklarerade med `override` - men **inte** implementerade än.
* De tretton registerindexen, de tre statusmaskerna, `CmdWrite` och `Trigger`, alla privata
  `static constexpr`.
* De två privata hjälpfunktionerna.
* `myTransport` som privat referensmedlem.

Låt de fyra interfacemetoderna ha tomma kroppar tills vidare (returnera `false` respektive gör
ingenting). De implementeras i [L10](../../L10/README.md).

---

### **3.** Implementera `writeReg()` och `readReg()`
Skapa `source/driver/can/spi.cpp` och implementera de två hjälpfunktionerna enligt
[bilaga A](./a_byte_transport.md).

Krav:
* Exakt fem `transfer()`-anrop per transaktion.
* `select()` först, `deselect()` sist, i båda.
* MSB först.
* `readReg()` kastar den byte som klockas in under kommandobyten.
* Varje avsmalnande konvertering är en explicit `static_cast`.
* Filen kompilerar med `-Wall -Wextra -Werror`.

---

### **4.** Förutsäg innan ni kör
Skriv ned svaren, kompilera sedan.

1. Vad blir kommandobyten för en skrivning till `RegTxDataHi`? Och för en läsning av samma
   register?
2. Vilken sekvens av fem bytes producerar `writeReg(RegTxDataLo, 0xAABB0000U)`?
3. Vad returnerar `readReg()` om transporten svarar `FF 12 34 56 78` på de fem `transfer()`-anropen?
4. Vad returnerar den om ni av misstag räknar med *alla fem* mottagna byten i stället för de
   fyra sista?

---

### **5.** Teckenutvidgningsbuggen
Skriv `readReg()` en gång **fel**, med skiftningen före casten:

```cpp
value |= myTransport.transfer(0U) << 24U;
```

Låt transporten svara så att den första databyten är `0x80`.

* Vad blir `value`?
* Varför?
* För vilka värden fungerar den felaktiga koden ändå?
* Hur skulle symptomet se ut om buggen låg kvar till bring-upen i
  [L13](../../L13/README.md)? Vilka `id`-värden hade fungerat och vilka inte?

Återställ sedan koden. Den här buggen är projektets vanligaste, och den enda anledningen till att
den inte kostar er en kväll är att ni har sett den nu.

---

### **6.** En transport att felsöka med
För att kunna köra uppgift 4 och 5 behöver ni något att köra mot. Skriv en liten
`PrintTransport` i `test/` som implementerar `ByteTransport` och skriver ut varje anrop:

```text
select
  -> 81   <- 00
  -> 00   <- 00
  -> 00   <- 00
  -> 01   <- 00
  -> 23   <- 00
deselect
```

Den är inte en testdubblare utan ett felsökningsverktyg, och den är värd att behålla hela
projektet. De riktiga testdubblarna (`ScriptedTransport` och `BankTransport`) är utdelade och
kommer i [L11](../../L11/README.md).

Jämför utskriften rad för rad mot exemplet i
[L08 bilaga A](../../L08/appendix/a_spi.md#6-ett-komplett-exempel).

---

### **7.** Lagergränsen igen
Sant eller falskt, med motivering:

1. `byte_transport.hpp` får inkludera `frame.hpp`.
2. `spi.hpp` får inkludera `byte_transport.hpp`.
3. `ByteTransport` borde ha en metod `writeRegister(index, value)`.
4. `ByteTransport` borde göra hela femBytestransaktionen i ett anrop.
5. `readReg()` borde vara publik så att testerna kan anropa den direkt.

Påstående 4 är det som låter mest rimligt och ändå är fel. Varför?

---

### **8.** Pull Request
Öppna en PR, låt en annan gruppmedlem granska. Granskaren ska kontrollera att varje
`static_cast` går att motivera, och räkna `transfer()`-anropen.

---

## Reflektion inför L10
* Ni har nu allt som krävs för att läsa och skriva vilket register som helst. Vad återstår för
  att `send()` ska fungera?
* Registerkartan säger att hårdvaran inte validerar någonting. Var i er kod ska den valideringen
  ligga, och vad ska hända med en ogiltig frame?

---
