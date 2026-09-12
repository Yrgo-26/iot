# Bilaga C

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 7** i
[**P03**](../../../projects/P03/README.md#11-milstolpe-7---hårdvara-factory-och-exempelapplikation).
Arbeta i branchen `feature/firmware`.

---

### **1.** Se optimeraren arbeta
Innan ni skriver någon AVR-kod, kör det här på värddatorn:

```cpp
int flag{};

void wait()
{
    while (flag == 0)
    {
    }
}
```

* Kompilera med `g++ -O2 -S` och titta på assemblern. Vad blev loopen?
* Lägg till `volatile` på `flag` och gör om. Vad ändrades?
* Förklara i två meningar varför skillnaden spelar roll för `SPI0.INTFLAGS`.

---

### **2.** Implementera `AvrSpiTransport`
Skapa `firmware/avr_spi_transport.hpp` och `.cpp` enligt [bilaga A](./a_avr32db28_spi.md).

Krav:
* `final`, ärver `driver::can::ByteTransport`.
* Kopierings- och flyttoperationerna borttagna.
* Konfigurationen sätter `PORTMUX.SPIROUTEA`, portriktningarna, `CTRLA` och `CTRLB`.
* `transfer()` läser `SPI0.DATA` efter varje överföring.
* **Kontrollera varje bitnamn mot DFP-headern eller databladet** innan ni skriver av det ur
  bilagan.

---

### **3.** Kontrollera `VDDIO2`
Lägg till en kontroll av `MVIO.STATUS` vid uppstart, och visa resultatet på en lysdiod eller
över UART.

Det är tio minuters arbete, och det är den enskilt mest värdefulla raden kod ni skriver inför
[L13](../../L13/README.md).

---

### **4.** Bygg och flasha
```bash
make -C firmware build
avrdude -c serialupdi -p avr32db28 -P /dev/ttyUSB0 -U flash:w:firmware/build/main.hex:i
```

Kontrollera med en logikanalysator eller ett oscilloskop, **innan** något kopplas till FPGA:n:
* Går det klockpulser på `PC2` när programmet kör?
* Ligger `SCK` låg i vila?
* Går `PC3` (`SS`) låg före varje byteknippe och hög efter?
* Är frekvensen ungefär 1 MHz?

Har ni ingen analysator: en lysdiod på `SS` och en långsam testloop visar åtminstone att pinnen
växlar.

---

### **5.** Förutsäg, ändra, observera
Gör en ändring i taget och notera symptomet. Återställ efter varje.

| # | Ändring | Förutsägelse | Vad hände? |
|---|---|---|---|
| a | Ta bort `PORTMUX.SPIROUTEA`-raden | | |
| b | Ta bort `SPI_SSD_bm` ur `CTRLB` | | |
| c | Sätt prescalern till `DIV2` | | |
| d | Ta bort läsningen av `SPI0.DATA` i `transfer()` | | |
| e | Glöm `PORTC.DIRSET` för `PC2` | | |

Rad (d) är den lömskaste: det *ser* ut att fungera. Vad blir egentligen fel, och när märks det?

---

### **6.** Bygg factoryn
Implementera factoryn enligt [bilaga B](./b_factory_and_app.md), och skriv `firmware/main.cpp`.

Krav:
* `main` är högst tio rader och innehåller ingen applikationslogik.
* Orden `Spi`, `AvrSpiTransport`, `SPI0` och `PORTC` förekommer inte i `main.cpp`.
* Medlemmarna i factoryn deklareras i konstruktionsordning.

---

### **7.** Arkitekturtestet
Byt `AvrSpiTransport` + `Spi` mot `Stub` i factoryn och kompilera för **värddatorn**.

* Gick det?
* Om inte: vilken fil klagade kompilatorn på, och vilken lagergräns hade brutits?
* Kör programmet. Vad gör `EchoNode` mot en `Stub`?

Återställ, och skriv ned resultatet - det hör hemma i `p03_report.md`.

---

### **8.** Friställda bygget
Bygg firmware med `-fno-exceptions -fno-rtti`.

* Kompilerar allt?
* Om inte: vilken rad, och vad använde den som inte finns på målet?
* Sök igenom hela `include/` och `source/` efter `new`, `std::vector`, `std::string` och
  `dynamic_cast`. Hittar ni något?

---

### **9.** Felsökningsapplikationen
Bygg applikationen i [bilaga B avsnitt 5](./b_factory_and_app.md#5-en-exempelapplikation-som-går-att-felsöka-med):
tre lysdioder och en knapp.

Den är inte ett krav i **P03**, men den kommer att spara er mer tid i
[L13](../../L13/README.md) än den tar att bygga.

---

### **10.** Checklistan inför L13
Gå igenom [checklistan i bilaga B avsnitt 6](./b_factory_and_app.md#6-checklista-inför-l13).
Alla åtta punkter ska vara avbockade **innan** nästa pass. L13 är ett labbpass, inte ett pass
för att bli klar med milstolpe 7.

---

## Reflektion inför L13
* Vilken klass i projektet har aldrig körts mot något, och hur kommer ni att veta att den
  fungerar?
* Om ingenting händer när ni kopplar ihop korten - vad kontrollerar ni först, och varför just
  det?

---
