# Bilaga A

## De två testdubblarna och vad de bevisar

**Ni skriver varken testdubblarna eller testsviten.** Båda är utdelade. Det här appendixet
förklarar hur de fungerar och hur de läses, eftersom de från och med nu är den enda instans som
kan säga om er drivrutin är rätt.

---

### 1. Varför två

`ByteTransport` är ett litet interface - tre metoder - och just därför går det att implementera
på två helt olika sätt, som svarar på två olika frågor.

| Testdubblare | Frågan den svarar på | Vad den är |
|---|---|---|
| `ScriptedTransport` | *Skickade drivrutinen rätt bytes?* | Bandspelare: spelar upp förprogrammerade svar, spelar in allt som skickades. |
| `BankTransport` | *Beter sig drivrutinen rätt?* | Simulator: en registerbank i minnet, med hårdvarans semantik. |

De överlappar inte, och båda behövs. Ett exempel var:

* `clearError()` som skriver `0x1` i stället för `0x0`. **`ScriptedTransport` fångar det**: den
  inspelade byten är `01` där testet väntar sig `00`. `BankTransport` fångar det också, men först
  indirekt - felbiten går inte ned.
* `receive()` som inte maskerar mot `dlc`. **`BankTransport` fångar det**: banken ger tillbaka en
  frame med `dlc = 2` efter en med `dlc = 8`, och testet ser sex bytes som inte ska vara där.
  `ScriptedTransport` fångar det inte - ur dess synvinkel skickades exakt rätt bytes.
* `TX_SEND` skriven före dataregistren. **`ScriptedTransport` fångar det**: ordningen på de
  inspelade transaktionerna är fel. `BankTransport` gör det bara om den modellerar att
  kontrollern läser data vid triggern - vilket den inte gör.

---

### 2. `ScriptedTransport`

```cpp
/**
 * @brief ByteTransport test double replaying scripted MISO bytes and recording MOSI bytes.
 */
class ScriptedTransport final : public driver::can::ByteTransport
{
public:
    // ... constructor taking the script ...

    void select() noexcept override;
    void deselect() noexcept override;
    [[nodiscard]] std::uint8_t transfer(std::uint8_t byte) noexcept override;

    /** Bytes the driver sent, in order. */
    [[nodiscard]] const std::vector<std::uint8_t>& sent() const noexcept;

    /** Number of completed select/deselect pairs. */
    [[nodiscard]] std::size_t transactionCount() const noexcept;
};
```

Den gör tre saker:
* **Spelar upp.** `transfer()` returnerar nästa byte ur skriptet, oavsett vad som skickades in.
* **Spelar in.** Varje byte som skickades sparas i ordning.
* **Räknar framing.** Varje `select()`/`deselect()`-par räknas, så att testet kan kontrollera att
  transaktionerna är korrekt avgränsade.

Ett testfall ur sviten, i sin helhet:

```cpp
TEST(Spi, writeRegSendsCommandByteThenValueMsbFirst)
{
    // Arrange.
    ScriptedTransport transport{};
    driver::can::Spi driver{transport};

    driver::can::Frame frame{};
    frame.id      = 0x123U;
    frame.dlc     = 2U;
    frame.data[0] = 0xAAU;
    frame.data[1] = 0xBBU;

    // Act.
    static_cast<void>(driver.send(frame));

    // Assert: the TX_DATA_LO transaction, bytes 11-15 of the recording.
    const auto& sent{transport.sent()};
    EXPECT_EQ(sent[10], 0x83U);   // CmdWrite | RegTxDataLo
    EXPECT_EQ(sent[11], 0xAAU);
    EXPECT_EQ(sent[12], 0xBBU);
    EXPECT_EQ(sent[13], 0x00U);
    EXPECT_EQ(sent[14], 0x00U);
}
```

**Läs det som protokollet, inte som kod.** De fem raderna i Assert-delen är `83 AA BB 00 00` ur
[L08 bilaga A](../../L08/appendix/a_spi.md#6-ett-komplett-exempel), skrivet som ett krav. Hela
den här testfilen är i praktiken SPI-protokollet uttryckt i C++.

Det betyder också att **testfilen är en bättre kravspecifikation än prosan**. Undrar ni exakt
vilken byte som ska ligga var: öppna den, i stället för att gissa.

---

### 3. `BankTransport`

Den här är den mer ambitiösa. Den tolkar kommandobyten, håller tretton register i minnet, och
härmar hårdvarans semantik:

* Maskeringen: `TX_ID` lagrar bitarna 10-0, `TX_DLC` bitarna 3-0.
* `TX_SEND` med bit 0 satt nollställer `STATUS` bit 0; en skrivning medan biten är låg ignoreras.
* `RX_ACK` med bit 0 satt nollställer `STATUS` bit 1.
* `ERROR_FLAGS` nollställs **bara** av ett helt nollställt ord.
* Skrivningar till `STATUS` och `RX_*` ignoreras tyst.
* Läsningar av `TX_SEND` och `RX_ACK` ger `0x00000000`.
* Reserverade index ger `0x00000000`.

Plus några metoder som bara testet använder, för att simulera vad kontrollern gör:

```cpp
/** Simulate a completed transmission: TX ready goes high again. */
void completeTransmission() noexcept;

/** Simulate a received frame: RX valid goes high and the RX_* registers are latched. */
void deliverFrame(const driver::can::Frame& frame) noexcept;

/** Simulate the controller latching an error. */
void raiseError() noexcept;
```

Med dem kan ett testfall skripta ett helt förlopp:

```cpp
TEST(Spi, receiveMasksDataAboveDlc)
{
    // Arrange: an eight-byte frame, then a two-byte frame.
    BankTransport bank{};
    driver::can::Spi driver{bank};

    driver::can::Frame eight{};
    eight.dlc = 8U;
    for (std::uint8_t i{}; i < 8U; ++i) { eight.data[i] = static_cast<std::uint8_t>(0xA0U + i); }
    bank.deliverFrame(eight);

    driver::can::Frame received{};
    EXPECT_TRUE(driver.receive(received));

    driver::can::Frame two{};
    two.dlc     = 2U;
    two.data[0] = 0x11U;
    two.data[1] = 0x22U;
    bank.deliverFrame(two);

    // Act.
    EXPECT_TRUE(driver.receive(received));

    // Assert: six bytes that were never sent must not be reported.
    EXPECT_EQ(received.dlc, 2U);
    EXPECT_EQ(received.data[0], 0x11U);
    EXPECT_EQ(received.data[1], 0x22U);
    for (std::uint8_t i{2U}; i < 8U; ++i)
    {
        EXPECT_EQ(received.data[i], 0x00U);
    }
}
```

Det testfallet är hela anledningen till att maskeringsloopen i `receive()` finns, och det är den
sortens krav som är nästan omöjligt att komma ihåg ur prosa men självklart när man ser det som
kod.

---

### 4. Hela stacken på laptopen

Med `BankTransport` går det att köra **allt** ni har byggt, utan hårdvara:

```cpp
TEST(EchoNode, echoesThroughTheRealDriver)
{
    // Arrange.
    BankTransport bank{};
    driver::can::Spi driver{bank};
    app::EchoNode node{driver, 0x200U};

    driver::can::Frame incoming{};
    incoming.id      = 0x123U;
    incoming.dlc     = 2U;
    incoming.data[0] = 0xAAU;
    incoming.data[1] = 0xBBU;
    bank.deliverFrame(incoming);

    // Act.
    node.run();

    // Assert.
    EXPECT_EQ(node.echoCount(), 1U);
    EXPECT_EQ(bank.readRegister(1U), 0x200U);   // TX_ID
    EXPECT_EQ(bank.readRegister(3U), 0xAABB0000U); // TX_DATA_LO
}
```

Jämför den med testfallet i
[L07 bilaga A](../../L07/appendix/a_component_testing.md#5-samma-mönster-ett-lager-ned). Det är
**samma testfall**, med `Stub` utbytt mot `Spi` + `BankTransport`. `EchoNode` är oförändrad. Det
är arkitekturen som betalar tillbaka: sömmen i `Interface` gjorde bytet möjligt, och sömmen i
`ByteTransport` gjorde det möjligt att göra det utan hårdvara.

---

### 5. Att gå från ett fallerande testfall till buggen

Arbetsgången, i ordning, och **utan att öppna er egen kod i steg 1-3**:

```text
FAILED: EXPECT_EQ(sent[11], 0xAAU) at test_spi.cpp:87
```

1. **Testnamnet.** `writeRegSendsCommandByteThenValueMsbFirst` - kravet gäller hur ett värde
   skrivs ut, MSB först.
2. **Indexet.** `sent[11]` är den andra byten i den tredje transaktionen. Räkna: 0-4 är
   `STATUS`-läsningen, 5-9 är `TX_ID`, 10-14 är `TX_DLC`... eller är det `TX_DATA_LO`? Att räkna
   fel här är vanligt; skriv ut `transport.sent()` i sin helhet och titta.
3. **Det förväntade värdet.** `0xAA` är `frame.data[0]`. Kravet är alltså att databyte 0 hamnar
   först.
4. **Nu**, och först nu: er `pack()`. Ligger `data[0]` i bitarna 31-24?

Steg 1-3 tar en minut och gör steg 4 kort. Att hoppa direkt till steg 4 är den vanligaste
anledningen till att en enkel bugg tar en timme.

---

### 6. Vad en grön testsvit inte bevisar

Det här är viktigare än det låter, och det är precis vad *Mjuk- och hårdvarutestning* handlar om.

En grön svit bevisar att **er kod stämmer med testförfattarens tolkning av kontraktet**. Den
bevisar inte:

* Att **tolkningen** är rätt. Testsviten är skriven av en människa som läste samma dokument som
  ni. Är dokumentet fel, är testet fel.
* Att **hårdvarugruppen** implementerat samma tolkning. Deras testbänkar är skrivna mot samma
  dokument, av en annan människa.
* Att **kopplingen** är rätt. En omkastad `MOSI`/`MISO` är osynlig för varje test på laptopen.
* Att **tidsbudgeten** håller. `BankTransport` svarar omedelbart; en riktig SPI-länk gör det inte.
* Att ni **pollar tillräckligt ofta** för att inte tappa frames.

Allt det där fångas bara av [L13](../../L13/README.md) och [L14](../../L14/README.md) - och det
är exakt vad de två passen är till för. Det är därför integrationstester ligger högst upp i
pyramiden och inte går att ersätta med fler enhetstester.

Men: allt **under** de punkterna ska vara grönt innan ni kopplar in något. En grön svit gör inte
bring-upen enkel; den gör den *möjlig*, genom att ta bort ett par hundra möjliga felkällor innan
ni står vid bänken.

---
