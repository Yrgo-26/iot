# L12 - AVR32DB28, `AvrSpiTransport`, factory och exempelapplikation

## Dagordning
* Ned till botten: den riktiga transporten.
* `volatile` på riktiga hårdvaruregister - varför det behövs och var det får användas.
* AVR32DB28:s `SPI0`: `CTRLA`, `CTRLB`, `INTFLAGS`, `DATA`.
* `PORTMUX.SPIROUTEA` och ALT1: varför SPI0 måste ligga på `PORTC`.
* MVIO och `VDDIO2`: hur kärnan går på 5 V medan SPI-ledningarna går på 3,3 V, utan
  nivåomvandlare.
* Live-kodning av `AvrSpiTransport`.
* Factory-mönstret på ett friställt mål, och en `main` som inte vet vilken drivrutin den fick.
* Arbete med **P03** (milstolpe 7).

---

## Mål med lektionen
* Kunna förklara varför `volatile` krävs för minnesmappad I/O, och vad kompilatorn annars gör.
* Kunna peka ut exakt vilka filer i projektet som får innehålla `volatile`, och varför just de.
* Kunna konfigurera `SPI0` som master i mode 0, MSB först, med rätt prescaler.
* Kunna förklara varför `PORTMUX.SPIROUTEA` måste sättas till ALT1, och vad som händer annars.
* Kunna förklara vad `VDDIO2` gör och varför konstruktionen inte behöver en nivåomvandlare.
* Kunna bygga ihop systemet med en factory, så att `main` inte känner till någon konkret
  drivrutin.

---

## Förutsättningar
* [L09](../L09/README.md): `ByteTransport`-interfacet.
* [L08 bilaga A](../L08/appendix/a_spi.md): pinnkonfigurationen och parametrarna.
* Från *Programmeringsmetodik*: AVR-verktygskedjan, `make`, flashning över UPDI.
* Från C++-kursen: factory-mönstret.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_avr32db28_spi.md) om `volatile` och AVR32DB28:s SPI och
  [bilaga B](./appendix/b_factory_and_app.md) om factoryn och exempelapplikationen, **eller**
  kapitel 12 i kursboken ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).
* Kontrollera att verktygskedjan fungerar: `avr-gcc`, `avr-libc`, `avrdude` och AVR-Dx-paketet.

### Under lektionen
* Delta i live-kodningen: `firmware/avr_spi_transport.hpp`, `.cpp` och `firmware/main.cpp`.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga C](./appendix/c_exercises.md).
* **Milstolpe 7** ska vara klar, och firmware ska gå att bygga och flasha.
* **Förbered [L13](../L13/README.md).** Ta med kort, kablar, transceiver och
  termineringsmotstånd. Stäm av med er hårdvarugrupp att de har en syntetiserad nod.

---

## Demonstration
* En loop utan `volatile`, kompilerad med `-O2`, och vad optimeraren gjorde av den.
* `SPI0` konfigurerad från tom fil, och en byte klockad ut, sedd på logikanalysator.
* Samma program utan `PORTMUX.SPIROUTEA` - fyra helt tysta ledningar.
* `main` där `Spi` byts mot `Stub` i factoryn, kompilerad för värddatorn och körd i terminalen.

---

## Utvärdering
* Vad gör kompilatorn med `while (!(SPI0.INTFLAGS & SPI_IF_bm)) {}` om `INTFLAGS` inte är
  `volatile`?
* Varför är `volatile` inte en synkroniseringsmekanism, och vad har det för betydelse här?
* Vilka två register måste vara rätt satta innan en enda SPI-byte kan lämna chippet?
* Varför drivs `SS` i mjukvara i stället för av periferin?
* Vad säger `MVIO.STATUS`, och vad händer med `PORTC` om `VDDIO2` inte är matad?
* Vilken rad i `main` skulle behöva ändras om ni bytte `Spi` mot `Stub`? Vilka rader skulle
  **inte** behöva ändras?

---

## Nästa lektion
* **Obligatorisk labb.** Kort mot kort, SPI-loopback, registerläsning, och den första framen ut
  på en riktig CAN-buss.

---
