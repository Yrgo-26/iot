# L10 - `driver::can::Spi`: `send`, `receive`, `hasError`, `clearError`

## Dagordning
* De fyra interfacemetoderna, byggda ovanpå `readReg()` och `writeReg()`.
* Live-kodning av `send()`: validering, statuskontroll, fem skrivningar, en trigger.
* Live-kodning av `receive()`: statuskontroll, fyra läsningar, uppackning, maskering, kvittens.
* Live-kodning av `hasError()` och `clearError()`.
* Packning och uppackning över registerpar: databyte 0 i de mest signifikanta bitarna.
* De tre begränsningarna hårdvaran har, och hur drivrutinen hanterar dem utan att dölja dem.
* Arbete med **P03** (milstolpe 5).

---

## Mål med lektionen
* Kunna implementera `send()` och `receive()` korrekt mot registerkartan.
* Kunna packa och packa upp åtta databytes över två 32-bitarsregister, i rätt ordning.
* Kunna motivera var valideringen ligger, och varför den ligger på exakt ett ställe.
* Kunna förklara varför `receive()` maskerar mot `dlc` trots att hårdvaran redan nollställer.
* Kunna förklara varför `clearError()` skriver `0x0` och inte `0x1`.
* Kunna beskriva varför en förlorad arbitrering inte går att skilja från en lyckad sändning, och
  vad drivrutinen gör åt det.

---

## Förutsättningar
* [L09](../L09/README.md): `ByteTransport`, `Spi`-deklarationen och de två hjälpfunktionerna.
* [L04](../L04/README.md): registerkartan, särskilt `STATUS`-tabellen och byteordningen.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_spi_driver.md) **eller** kapitel 10 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).
* Läs [**P03** avsnitt 9](../../projects/P03/README.md#9-milstolpe-5---spi-metodkontrakten).

### Under lektionen
* Delta i live-kodningen: de fyra metoderna i `spi.cpp`.

### Efter lektionen
* Genomför övningsuppgifterna i [bilaga B](./appendix/b_exercises.md).
* **Milstolpe 5** ska vara klar.

---

## Demonstration
* En komplett `send()` körd mot `PrintTransport` från [L09](../L09/README.md), och jämförd rad
  för rad mot exemplet i [L08 bilaga A](../L08/appendix/a_spi.md#6-ett-komplett-exempel).
* Samma `send()` med `TX_DATA_LO` och `TX_DATA_HI` förväxlade - en frame som kommer fram bakvänd.
* En `receive()` av en frame med `dlc = 2` som följer på en med `dlc = 8`, med och utan maskering.

---

## Utvärdering
* I vilken ordning skriver `send()` sina register, och varför måste `TX_SEND` komma sist?
* Vad returnerar `send()` om `dlc` är 9? Och om `STATUS` bit 0 är låg? Är det samma sorts `false`?
* Hur packas databytesen `AA BB` in i `TX_DATA_LO`?
* Vad händer om `receive()` glömmer att skriva `RX_ACK`?
* Varför räcker det inte att vänta på `STATUS` bit 0 för att veta att en frame kom fram?
* Vilka tre begränsningar i hårdvaran ska drivrutinen hantera, och vilken av dem kan den inte
  göra något åt?

---

## Nästa lektion
* Testsviten. `ScriptedTransport` och `BankTransport` delas ut, och hela drivrutinen körs på
  laptopen - `EchoNode` inräknad, utan en enda rad hårdvarukod.

---
