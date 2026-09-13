# Föreläsningar

Varje föreläsning motsvarar ett kapitel i kursboken, med samma nummer: L05 är kapitel 5. Boken
finns [på svenska](../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf) och
[på engelska](../book/en/communication-protocols-and-drivers.pdf), med samma innehåll och samma
kapitel- och avsnittsnummer. Inför varje föreläsning läser ni **antingen** dess appendix **eller**
motsvarande kapitel - de täcker samma stoff. Boken har dessutom lösningar till sina övningar, i
appendix A.

## Del 1 - Ett eget protokoll
* [L01](./L01/README.md): Frames: struktur, fält och serialisering.
* [L02](./L02/README.md): Byte-parsing och tillståndsmaskiner.
* [L03](./L03/README.md): Bussar, routing och tillförlitlig kommunikation.

## Del 2 - CAN-drivrutinen
* [L04](./L04/README.md): CAN-bussen, registerkartan och drivrutinsarkitekturen. Start av **P03**.
* [L05](./L05/README.md): `driver::can::Frame` och den första testsviten.
* [L06](./L06/README.md): `driver::can::Interface` och `driver::can::Stub`.
* [L07](./L07/README.md): Komponenttest genom stubben: `app::EchoNode`.
* [L08](./L08/README.md): SPI från vågformen och transaktionsprotokollet.
* [L09](./L09/README.md): `ByteTransport`-sömmen och registeråtkomsten.
* [L10](./L10/README.md): `driver::can::Spi`: `send`, `receive`, `hasError`, `clearError`.
* [L11](./L11/README.md): Testning av drivrutinen utan hårdvara.
* [L12](./L12/README.md): AVR32DB28, `AvrSpiTransport`, factory och exempelapplikation.

## Del 3 - Hårdvaran
* [L13](./L13/README.md): **Bring-up mot hårdvarugruppens CAN-nod** (obligatorisk labb).
* [L14](./L14/README.md): **CAN-labb med Vector CANalyzer** (obligatorisk labb).
* [L15](./L15/README.md): **D01 - Dugga**.

---
