# Bilaga B

## Factoryn och exempelapplikationen

### 1. Vad som återstår

Alla delar finns nu. Det som fattas är limmet:

```text
EchoNode  behöver ett  Interface&
Spi       ÄR ett       Interface,  och behöver en ByteTransport&
AvrSpiTransport  ÄR en ByteTransport
```

Någon måste skapa objekten, i rätt ordning, och hålla dem vid liv så länge programmet kör. Den
någon ska **inte** vara `main`, och definitivt inte `EchoNode`.

---

### 2. Factoryn

```cpp
/**
 * @brief Creates and owns the driver stack for this build target.
 */
class Factory
{
public:
    Factory() noexcept;

    Factory(const Factory&)            = delete;
    Factory(Factory&&)                 = delete;
    Factory& operator=(const Factory&) = delete;
    Factory& operator=(Factory&&)      = delete;

    /**
     * @brief Get the CAN driver.
     *
     * @return Reference to the driver, valid for the lifetime of the factory.
     */
    [[nodiscard]] driver::can::Interface& canDriver() noexcept;

private:
    AvrSpiTransport myTransport; /**< Byte transport. Declared before the driver that uses it. */
    driver::can::Spi myDriver;   /**< The CAN driver, bound to myTransport. */
};
```

**Deklarationsordningen är ett krav, inte stil.** Medlemmar konstrueras i den ordning de
deklareras, och `myDriver` tar en referens till `myTransport` i sin konstruktor. Byt plats på de
två raderna och ni binder en referens till ett objekt som inte konstruerats än. Kompilatorn säger
ingenting.

**Returtypen är `Interface&`, inte `Spi&`.** Det är hela poängen. Anroparen får något den kan
använda, inte något den kan känna igen.

**Ingen heap.** Objekten är medlemmar, factoryn ligger på stacken i `main`, och allt har statisk
storlek. På ett friställt mål finns ingen `std::unique_ptr` att ta till - och det behövs inte
heller. `std::unique_ptr` i C++-kursens factory-exempel löste ett ägandeproblem som inte finns
när antalet objekt är känt vid kompileringstillfället.

---

### 3. `main`

```cpp
int main()
{
    Factory factory{};
    app::EchoNode node{factory.canDriver(), ResponseId};

    while (true)
    {
        node.run();
    }
}
```

Fem rader. `main` gör tre saker och inget mer:

1. Skapar factoryn.
2. Skapar applikationskomponenten med det factoryn lämnar ut.
3. Kör.

Ordet `Spi` förekommer inte. Inte heller `AvrSpiTransport`, `SPI0` eller `PORTC`. Om ni kan läsa
er `main` utan att veta vilken hårdvara programmet kör på har ni fått arkitekturen rätt.

---

### 4. Testet på designen

Byt en rad i factoryn:

```cpp
private:
    driver::can::Stub myDriver;   // was: AvrSpiTransport + Spi
```

Kompilera för **värddatorn**. Det ska gå, och programmet ska köra - `EchoNode` ekar frames mot en
array i minnet i stället för mot en CAN-buss.

Om det inte går, läs kompilatorfelet noga: det pekar ut exakt var någon rad ovanför
`driver/can/interface.hpp` har lärt sig något om hårdvaran som den inte borde veta.

Det här är ett test ni kan köra på tio sekunder, och det säger mer om arkitekturens kvalitet än
någon kodgranskning. Gör det innan ni lämnar in.

---

### 5. En exempelapplikation som går att felsöka med

`EchoNode` är en bra applikation att bevisa arkitekturen med och en dålig att felsöka med: den
gör ingenting synligt. Inför [L13](../../L13/README.md) är det värt att bygga en till, som säger
något om vad den gör.

Förslag, med kortets egna lysdioder från *Programmeringsmetodik*:

| Lysdiod | Tänds när |
|---|---|
| Grön | En frame har tagits emot och kvitterats. |
| Gul | En frame har skickats (`send()` returnerade `true`). |
| Röd | `hasError()` returnerade `true`. |

Plus en knapp som skickar en frame med ett känt ID och en känd nyttolast.

Det är ett kvarts arbete och det betalar sig direkt vid bänken: en röd lysdiod som tänds när ni
kopplar in transceivern säger något helt annat än en nod som inte gör något alls.

**Håll den utanför `EchoNode`.** Lysdioderna hör till applikationen, inte till drivrutinen, och
drivrutinen ska fortsätta vara byggbar för värddatorn.

---

### 6. Checklista inför L13

* [ ] Hela den utdelade testsviten är grön på värddatorn.
* [ ] Factoryn med `Stub` kompilerar och kör på värddatorn.
* [ ] Factoryn med `AvrSpiTransport` + `Spi` kompilerar för AVR32DB28.
* [ ] Firmware går att flasha, och kortet startar.
* [ ] `MVIO.STATUS`-kontrollen finns, och programmet visar resultatet på något sätt.
* [ ] Ni har en applikation som visar sända frames, mottagna frames och fel.
* [ ] Ni vet vilken hårdvarugrupp ni paras ihop med, och har stämt av att de har en nod.
* [ ] Ni har transceiver, termineringsmotstånd, tvinnad kabel och kopplingstråd med er.

Den sista punkten är den som brukar glömmas.

---
