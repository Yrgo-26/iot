# Bilaga A

## Interfacet och stubben

Den här bilagan går igenom lektionens två klasser, `driver::can::Interface` och
`driver::can::Stub`: vad en söm är och varför kursen har två, vad som inte hör hemma i interfacet,
vad stubben inte simulerar, och varför den är en stubb och inte en mock.

De exakta kraven på båda klasserna står i
[**P03** avsnitt 6](../../../projects/P03/README.md#6-milstolpe-2---interface-och-stub).

---

### 1. Vad en söm är, och varför vi har två

En **söm** (*seam*) är ett ställe där man kan byta ut beteende utan att ändra koden runt omkring.
`driver::can::Interface` är kursens första.

Men vi har **två**, och det är värt att hålla isär dem från början:

| Söm | Gör vad testbart |
|---|---|
| `driver::can::Interface` | **Applikationen.** `EchoNode` kan köras mot en `Stub` och behöver aldrig veta att hårdvara finns. |
| `driver::can::ByteTransport` | **Drivrutinen själv.** Samma `Spi`-kod som flashas till målet kan köras på er laptop mot en transport ni skriptar. |

Den andra sömmen kommer i [L09](../../L09/README.md). En drivrutin som når registren direkt över
en minnesmappad buss behöver den inte, eftersom den inte har något transportlager att byta ut. Vår
når dem över SPI, och det är därför sömmen behövs.

Håll dem isär. De löser olika problem, och en granskare som blandar ihop dem kommer att undra
varför det finns två.

---

### 2. Sömmen har redan lönat sig en gång

Argumentet för `Interface` brukar vara hypotetiskt: *tänk om hårdvaran byts ut.* Här är det inte
hypotetiskt.

En tidigare version av den här konstruktionen nådde registren via **minnesmappad I/O** på
basadressen `0xFF200000`, och hade därför en drivrutinsklass som hette `Fpga` och inte `Spi`. Den
varianten förutsätter en processor med en adressbuss ut mot FPGA-väven. AVR32DB28:n har ingen
sådan buss, så registren nås över SPI i stället.

**Allt ovanför `Interface` hade överlevt den ändringen oförändrat.** `Frame`, `Interface`, `Stub`
och `EchoNode` är bit för bit desamma i båda varianterna. Det är hela argumentet, demonstrerat.

Den gamla varianten hade `Fpga` och `volatile`-pekare där vi har `Spi` och `ByteTransport`. Ingen
av dem är fel; det är två implementationer under samma söm.

---

### 3. Vad som inte hör hemma i interfacet

Testet på om en metod hör hemma i `Interface` är enkelt: **kan både `Stub` och `Spi`
implementera den meningsfullt?**

`readStatusRegister()` kan de inte — stubben har inga register. En sådan metod hade tvingat
stubben att ljuga, och tvingat applikationen att veta att register finns.

Det är också skälet till att `inject()` ligger i `Stub` och inte i `Interface`: en `Spi` kan inte
trolla fram trafik som inte finns.

Konsekvensen för hur testerna skrivs, och mönstret återkommer genom hela projektet:

```cpp
driver::can::Stub stub{};            // konkret typ: har inject()
app::EchoNode node{stub, 0x200U};    // tar en Interface&: har den inte
stub.inject(frame);                  // testet talar med stubben direkt
node.run();                          // komponenten vet ingenting om det
```

Testet håller i den **konkreta** typen, komponenten ser bara **interfacet**.

---

### 4. Vad stubben inte simulerar

Den simulerar inte:

* Fel (`hasError()` är alltid `false`).
* Att hårdvaran är upptagen (`send()` lyckas alltid när stubben är initialiserad).
* Kö: en andra `send()` skriver över den första framen.
* Arbitrering, CRC, eller något annat CAN gör.

Det är avsiktligt. Stubbens jobb är att låta `EchoNode` köras, inte att vara en CAN-simulator.

**Att veta var gränsen för en testdubblares realism går är en färdighet i sig.** En stubb som
växer tills den är en andra implementation av hårdvaran är en stubb som själv behöver testas.

Den som vill testa hur drivrutinen beter sig när hårdvaran är upptagen behöver en annan
testdubblare — och den ligger en söm längre ned, i [L11](../../L11/README.md).

---

### 5. Stubb, inte mock

Två ord som ofta blandas ihop:

* En **stubb** svarar på anrop med förprogrammerade svar. Testet kontrollerar vad *den anropande
  koden* gjorde med svaren.
* En **mock** kontrollerar dessutom att den blev anropad på rätt sätt — rätt metod, rätt
  argument, rätt antal gånger.

`Stub` är en stubb. I [L11](../../L11/README.md) möter ni `ScriptedTransport`, som ligger närmare
en mock: den spelar in varje byte som passerar, så att testet kan kontrollera exakt vilka bytes
drivrutinen skickade.

---
