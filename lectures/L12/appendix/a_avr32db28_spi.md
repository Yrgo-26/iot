# Bilaga A

## `volatile` och AVR32DB28:s SPI

### 1. `volatile`: vad det är till för

Hittills har er kod bara rört vanligt minne. Den här filen rör **hårdvara**, och då slutar en av
kompilatorns grundläggande antaganden att gälla.

Kompilatorn antar att ingen annan än programmet ändrar en variabel. Med den utgångspunkten är
följande loop en oändlig loop, och optimeraren får ta bort den:

```cpp
while ((SPI0.INTFLAGS & SPI_IF_bm) == 0U)
{
}
```

`SPI0.INTFLAGS` läses en gång, resultatet läggs i ett register, och eftersom ingenting i loopen
ändrar det är villkoret konstant. Med `-O2` blir resultatet antingen en loop som aldrig avslutas
eller en loop som optimeras bort helt.

Men `INTFLAGS` **ändras** - av SPI-periferin, utan att programmet gör något. `volatile` är hur man
säger det:

> Läs om den här variabeln varje gång. Slå inte ihop läsningar, flytta dem inte, och ta inte bort
> dem.

I `<avr/io.h>` är periferiregistren redan deklarerade `volatile`, så `SPI0.INTFLAGS` bär
kvalificeraren med sig. Ni behöver inte skriva den - men ni behöver veta att den är där, och
varför.

#### Vad `volatile` *inte* är

`volatile` är **inte** en synkroniseringsmekanism. Den garanterar inte atomicitet, och den
garanterar ingen ordning mot annat än andra `volatile`-åtkomster. I trådad kod på en värddator
är `volatile` nästan alltid fel verktyg; `std::atomic` är rätt.

Här handlar det om något annat: ett register som en periferi ändrar under näsan på programmet.
Det är precis det fall `volatile` finns för.

#### Var det får stå i det här projektet

**Bara i `firmware/avr_spi_transport.cpp`.**

Det är hela poängen med `ByteTransport`-sömmen. Allt ovanför den - `Spi`, `Stub`, `Interface`,
`EchoNode` - är vanlig, portabel C++ som kompilerar och körs på er laptop. En granskare som ser
`volatile` i någon annan fil ska fråga varför.

---

### 2. AVR32DB28:s `SPI0`

Fyra register räcker för en polld master.

| Register | Innehåll |
|---|---|
| `SPI0.CTRLA` | Enable, master/slave, bitordning, prescaler. |
| `SPI0.CTRLB` | SPI-läge, slave-select-disable, buffertläge. |
| `SPI0.INTFLAGS` | Statusflaggor; `SPI_IF_bm` sätts när en överföring är klar. |
| `SPI0.DATA` | Skriv för att starta en överföring; läs för att hämta den mottagna byten. |

Slå upp dem i [databladet](https://www.microchip.com/en-us/product/AVR32DB28) och i
DFP-headern. Bitnamnen nedan är de som AVR-Dx-paketet definierar, men kontrollera dem mot er
egen installation innan ni skriver av dem - det är precis den vanan den här kursen försöker
bygga.

#### Konfigurationen

```cpp
void AvrSpiTransport::init() noexcept
{
    // Route SPI0 to PORTC (ALT1): PC0 = MOSI, PC1 = MISO, PC2 = SCK, PC3 = SS.
    PORTMUX.SPIROUTEA = PORTMUX_SPI0_ALT1_gc;

    // MOSI, SCK and SS are outputs; MISO is an input. SS idles high.
    PORTC.DIRSET = PIN0_bm | PIN2_bm | PIN3_bm;
    PORTC.DIRCLR = PIN1_bm;
    PORTC.OUTSET = PIN3_bm;

    // Master, MSB first, 4 MHz / 4 = 1 MHz, enabled.
    SPI0.CTRLA = SPI_MASTER_bm | SPI_PRESC_DIV4_gc | SPI_ENABLE_bm;

    // SPI mode 0, and software-controlled slave select.
    SPI0.CTRLB = SPI_MODE_0_gc | SPI_SSD_bm;
}
```

Fem rader, och tre av dem är fällor.

**`PORTMUX.SPIROUTEA`.** Utan den raden ligger `SPI0` på sin standardmux, `PA4`-`PA7`, och de fyra
ledningar ni kopplat till `PORTC` är helt tysta. Symptomet är det mest förvirrande som finns:
programmet kör, inga fel rapporteras, och logikanalysatorn visar ingenting alls. **Sätt den
först**, innan något annat rörs.

**`SPI_SSD_bm`** - *Slave Select Disable*. Utan den övervakar periferin `SS`-pinnen, och en låg
nivå där får mastern att tro att en annan master tagit över bussen: den lämnar masterläget. Men
här är det **er egen kod** som drar `SS` låg, vid varje `select()`. Utan `SSD` skjuter alltså
drivrutinen sig själv i foten vid första transaktionen.

**Prescalern.** Huvudklockan på en AVR-DB är 4 MHz som standard. `SPI_PRESC_DIV4_gc` ger 1 MHz,
vilket är exakt protokollets tak. Kör inte snabbare: FPGA-slaven garanterar ingenting över 1 MHz,
se [L08 bilaga A](../../L08/appendix/a_spi.md#2-parametrarna).

---

### 3. Varför `PORTC`, och vad MVIO gör

Det här är den elegantaste detaljen i hela konstruktionen, och den är värd att förstå.

**Problemet:** AVR32DB28-kortet körs på 5 V. DE0-CV:s GPIO är 3,3 V och tål inte 5 V. Den vanliga
lösningen är en nivåomvandlare på varje ledning - en komponent till, fyra kopplingar till, och
fyra saker till som kan sitta fel.

**Lösningen:** AVR-DB-familjen har **MVIO** (*Multi-Voltage I/O*). `PORTC` matas inte från `VDD`
som resten av chippet, utan från en egen pinne: **`VDDIO2`**.

Koppla `VDDIO2` till DE0-CV:s 3,3 V-rail, och hela `PORTC` blir en 3,3-voltsdomän:

* Det AVR:n **driver** på `PC0`, `PC2` och `PC3` är 3,3 V - en nivå FPGA:n är specificerad för.
* Det AVR:n **läser** på `PC1` jämförs mot en 3,3-voltströskel, inte mot en 5-voltströskel.
* Kärnan och resten av portarna kör oförändrat på 5 V.

**Ingen nivåomvandlare.** Det är därför pinnkonfigurationen i kontraktet inte är varje grupps
eget val: byter ni till standardmuxen på `PA4`-`PA7` hamnar ledningarna i `VDD`-domänen, och då
behövs nivåomvandlaren igen - eller så går FPGA-ingången sönder.

#### `MVIO.STATUS`

`VDDIO2` måste vara matad **innan** `PORTC` gör någonting alls. Är den inte det är portens
beteende odefinierat: pinnarna driver inte, och läsningar ger skräp.

`MVIO.STATUS` har en flagga som säger om `VDDIO2` ligger inom sitt tillåtna intervall. Kontrollera
den vid uppstart:

```cpp
bool AvrSpiTransport::isPowered() noexcept
{
    return (MVIO.STATUS & MVIO_VDDIO2S_bm) != 0U;
}
```

Vid bring-upen i [L13](../../L13/README.md) är den flaggan det **första** ni ska titta på. En
bortglömd `VDDIO2`-koppling ser ut precis som en trasig SPI-implementation, och den kontrollen
skiljer de två fallen åt på en sekund.

---

### 4. `AvrSpiTransport`

```cpp
/**
 * @brief ByteTransport implemented on the AVR32DB28's SPI0 peripheral.
 */
class AvrSpiTransport final : public driver::can::ByteTransport
{
public:
    AvrSpiTransport() noexcept;
    ~AvrSpiTransport() noexcept override = default;

    AvrSpiTransport(const AvrSpiTransport&)            = delete;
    AvrSpiTransport(AvrSpiTransport&&)                 = delete;
    AvrSpiTransport& operator=(const AvrSpiTransport&) = delete;
    AvrSpiTransport& operator=(AvrSpiTransport&&)      = delete;

    void select() noexcept override;
    void deselect() noexcept override;
    [[nodiscard]] std::uint8_t transfer(std::uint8_t byte) noexcept override;
};
```

Implementationen är kort:

```cpp
void AvrSpiTransport::select() noexcept
{
    PORTC.OUTCLR = PIN3_bm;
}

void AvrSpiTransport::deselect() noexcept
{
    PORTC.OUTSET = PIN3_bm;
}

std::uint8_t AvrSpiTransport::transfer(const std::uint8_t byte) noexcept
{
    SPI0.DATA = byte;

    while ((SPI0.INTFLAGS & SPI_IF_bm) == 0U)
    {
    }

    return SPI0.DATA;
}
```

**Läsningen av `SPI0.DATA` nollställer flaggan.** Hoppa över den - till exempel i en `select()`
som "bara" skulle skicka en dummybyte - och nästa `transfer()` ser en flagga som redan står kvar,
returnerar omedelbart, och läser en byte som inte hunnit komma in. Symptomet är data som ligger
**en byte efter** genom hela transaktionen, vilket är svårt att se och lätt att missta för ett
bitordningsfel.

**Ingen fördröjning behövs kring `SS`.** Protokollet kräver 60 ns setup och hold, och en AVR på
4 MHz använder 250 ns per instruktion. En enda `OUTCLR` är alltså redan fyra gånger så långsam
som kravet. Se [L08 bilaga A](../../L08/appendix/a_spi.md#4-ss-reglerna).

**Inga avbrott.** Allt är pollat, precis som i drivrutinerna från *Programmeringsmetodik*:
programmets flöde är satsernas ordning.

---

### 5. Friställd C++ på AVR

Firmware byggs för ett **friställt** (*freestanding*) mål. Det innebär att en del av C++ ni är
vana vid inte följer med:

| Finns inte | Vad ni gör i stället |
|---|---|
| Heap (`new`, `std::vector`) | Statiskt allokerade objekt; allt i projektet har känd storlek. |
| Undantag | Returkoder - vilket hela interfacet redan bygger på. |
| RTTI (`dynamic_cast`, `typeid`) | Virtuella funktioner räcker; ni castar aldrig nedåt. |
| `<iostream>` | UART-utskrift, eller en lysdiod. |

**Lägg märke till att ingenting av det påverkar er design.** `Interface` returnerar `bool` i
stället för att kasta. `Frame` är en aggregate med statisk storlek. Ingen klass använder heapen.
Det var inte tur - det är projektets kodkonventioner som är skrivna för ett friställt mål från
början, och det här är passet där det lönar sig.

Bygg med `-fno-exceptions -fno-rtti`, och kontrollera att allt fortfarande kompilerar. Gör det
inte det har någon rad smugit sig in som inte hör hemma på ett inbyggt mål.

---

### 6. Att bygga och flasha

Samma verktygskedja som i *Programmeringsmetodik*:

```bash
make -C firmware build
avrdude -c serialupdi -p avr32db28 -P /dev/ttyUSB0 -U flash:w:firmware/build/main.hex:i
```

`firmware/` byggs **inte** av repots `make build`; den katalogen kräver `avr-gcc` och DFP-paketet,
och CI har inte dem. Allt annat i projektet byggs och testas på värddatorn precis som förut.

Det är värt att notera vad det betyder: `AvrSpiTransport` är den **enda** klassen i projektet som
inte täcks av något automatiskt test. Det är avsiktligt och oundvikligt - den pratar med ett
fysiskt register - och det är precis därför bring-up-stegen i [L13](../../L13/README.md) är
utformade som de är. Den stegen *är* testet för den här klassen.

---
