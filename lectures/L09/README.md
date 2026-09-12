# L09 - `ByteTransport`-sömmen och registeråtkomsten

## Dagordning
* Protokollet blir kod.
* Den andra sömmen: `driver::can::ByteTransport`, och varför `Interface` inte räckte.
* Live-kodning av `driver/can/byte_transport.hpp`.
* Live-kodning av `driver/can/spi.hpp`: registerindex, statusmasker och de två hjälpfunktionerna.
* Live-kodning av `readReg()` och `writeReg()` i `spi.cpp`.
* Bitskiftning och maskning: att sätta ihop och plocka isär ett 32-bitars ord, MSB först.
* Arbete med **P03** (milstolpe 4).

---

## Mål med lektionen
* Kunna förklara vad `ByteTransport` gör möjligt som `Interface` inte redan gjorde.
* Kunna motivera varför `select()` och `deselect()` är egna metoder och inte inbakade i
  `transfer()`.
* Kunna skriva registerkartan som namngivna `static constexpr`-konstanter, och motivera index
  framför offset.
* Kunna implementera `readReg()` och `writeReg()` korrekt, inklusive kommandobyten och
  byteordningen.
* Kunna förklara varför byten som klockas in under kommandobyten kastas.
* Kunna peka ut de vanligaste bitskiftningsfelen och säga hur de skulle se ut i ett fallerande
  testfall.

---

## Förutsättningar
* [L08](../L08/README.md): transaktionsformatet. Idag skrivs det i C++.
* [L04](../L04/README.md): registerkartan.
* Från C++-kursen: bitoperatorer, `static_cast`, och skillnaden mellan `std::uint8_t` och
  `std::uint32_t` i uttryck.

---

## Instruktioner

### Förberedelse
* Läs [bilaga A](./appendix/a_byte_transport.md).
* Läs [**P03** avsnitt 8](../../projects/P03/README.md#8-milstolpe-4---bytetransport-och-transaktionslagret).

### Under lektionen
* Delta i live-kodningen: `byte_transport.hpp`, `spi.hpp` och de två hjälpfunktionerna i `spi.cpp`.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga B](./appendix/b_exercises.md).
* **Milstolpe 4** ska vara klar: `ByteTransport`, `Spi`-deklarationen och de två
  hjälpfunktionerna finns.

---

## Demonstration
* `writeReg(RegTxId, 0x123U)` körd mot en transport som skriver ut varje byte - och jämförd med
  `81 00 00 01 23` ur [L08 bilaga A](../L08/appendix/a_spi.md#6-ett-komplett-exempel).
* Samma anrop med skiftningarna i fel ordning, och hur utskriften avslöjar det.
* `std::uint8_t b = value >> 24;` utan `static_cast`, och vad kompilatorn säger med `-Wextra`.

---

## Utvärdering
* Vad hade ni **inte** kunnat testa på laptopen utan `ByteTransport`?
* Varför returnerar `transfer()` en byte i stället för att vara `void`?
* Varför är registerkonstanterna index och inte offset?
* Hur byggs kommandobyten för en skrivning till index 3?
* Varför kastas den första byten som klockas in i `readReg()`?
* Varför är `readReg()` och `writeReg()` privata?
* Varför är de `const` trots att de pratar med hårdvara?

---

## Nästa lektion
* De fyra interfacemetoderna: `send()`, `receive()`, `hasError()` och `clearError()`, byggda
  ovanpå dagens två hjälpfunktioner.

---
