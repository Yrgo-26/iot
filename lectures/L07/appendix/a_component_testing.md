# Bilaga A

## Komponenttestning

Den här bilagan går igenom komponenttestning: skillnaden mot enhetstest, interface som sömmar,
stubbar som testdubblare och dependency injection, och pekar ut de två ställen i `app::EchoNode`
där det spelar roll.

Kraven på `EchoNode` står i
[**P03** avsnitt 7](../../../projects/P03/README.md#7-milstolpe-3---appechonode-appecho_nodeh).

---

### 1. Vad ett komponenttest är

Kortversionen, som räcker för att läsa resten av den här bilagan:

* Ett **enhetstest** testar en enhet isolerad. `Frame` i [L05](../../L05/README.md) är exemplet:
  det finns inget att isolera den från.
* Ett **komponenttest** testar **flera delar som samverkar**, fortfarande utan hårdvara. Här:
  `app::EchoNode` plus `driver::can::Stub`, kopplade genom `driver::can::Interface`.

Skillnaden syns tydligast i vilken sorts bugg de fångar. Anta att `EchoNode::run()` anropar
`receive()` **två gånger** per varv:

```cpp
Frame frame{};
if (!myDriver.receive(frame)) { return; }

Frame response{};
response.id  = myResponseId;
response.dlc = myDriver.receive(frame) ? frame.dlc : 0U;   // fel: anropar receive() igen
```

Varje enhetstest är fortfarande grönt. `Stub` gör exakt det den lovar, och `Frame` likaså. Buggen
ligger i *interaktionen*: det andra anropet konsumerar tillståndet det första lämnade.

**Det är hela poängen.** Interaktionsbuggar — ett anrop för mycket, ett anrop i fel ordning, ett
returvärde som ignoreras — är den vanligaste sortens fel i drivrutinskod, och de bor mellan
enheterna, inte i dem.

---

### 2. Lagergränsen, i kod

`app/echo_node.hpp` ska **framåtdeklarera** `driver::can::Interface` och inte inkludera någon
konkret drivrutin:

```cpp
namespace driver::can { class Interface; }
```

Den raden är arkitekturens gräns uttryckt i kod. En granskare som ser
`#include "driver/can/spi.hpp"` i den filen ska stoppa PR:en direkt.

Regeln, som gäller hela projektet: **ingen fil ovanför `driver/can/interface.hpp` får innehålla
ordet SPI.**

---

### 3. Två detaljer i `run()` som är lätta att missa

Implementationen skrivs på lektionen. Två rader är värda att stanna vid extra, eftersom de
återkommer en söm längre ned:

**Loopen går till `frame.dlc`, inte till `MaxDataLen`.** Att kopiera åtta bytes hade "fungerat"
eftersom resten ändå är nollor — men `response.dlc` säger hur många som gäller, och kod som
kopierar mer än den säger sig kopiera slutar stämma när någon annan förutsättning ändras. Exakt
samma resonemang som maskeringen i `Spi::receive()` i
[L10](../../L10/appendix/a_spi_driver.md#3-receive).

**`myEchoCount` räknas upp bara när `send()` lyckades.** Räknaren betyder "ekade frames", inte
"försök". En `send()` som returnerar `false` är hårdvaran som säger att den är upptagen, och då
ekades ingenting.

---

### 4. Vad den utdelade sviten täcker

Ni skriver inte testerna; de är utdelade. Läs tabellen som en checklista när något fallerar —
raden säger vilket krav som är brutet:

| Fall | Vad det bevisar |
|---|---|
| Ingen injicerad frame, `run()` anropad | `echoCount()` oförändrad; komponenten gör inget när det inte finns något att göra. |
| En injicerad frame | Rätt `id`, `dlc` och data ekas; räknaren går upp med ett. |
| Två injicerade frames, två `run()` | Räknaren blir 2. |
| En injicerad frame, `run()` anropad **två** gånger | Räknaren blir 1 — inte 2. Det här fallet fångar buggen i avsnitt 1. |
| `dlc = 0` | En frame utan data ekas korrekt, och inget läses ur `data`. |
| `dlc = 8` | Alla åtta bytes följer med. |
| `send()` misslyckas | `echoCount()` går **inte** upp. |

De två näst sista är ett gränsvärdespar, av samma skäl som i
[L05 bilaga B](../../L05/appendix/b_unit_testing.md#6-gränsvärden-varför-sviterna-ser-ut-som-de-gör).
Det fjärde är det som är lätt att inte tänka på, och det som betalar sig.

---

### 5. Samma mönster, ett lager ned

Det här är skälet till att bilagan finns, och det enda ni behöver bära med er härifrån.

Testet håller i den **konkreta** typen och skriptar förloppet; komponenten ser bara
**interfacet**:

```cpp
driver::can::Stub stub{};
app::EchoNode node{stub, 0x200U};

stub.inject(incoming);   // testet matar in trafik
node.run();              // komponenten gör sitt, ovetande om att den kördes i ett test
stub.receive(echoed);    // testet läser tillbaka vad komponenten skickade
```

I [L11](../../L11/README.md) gör den utdelade sviten **exakt samma sak**, en söm längre ned:
`BankTransport` ersätter `Stub`, `Spi` ersätter `EchoNode` som det som testas, och testet skriptar
vad hårdvaran svarar i stället för vilka frames som kommer in.

Att det *är* samma mönster är ingen tillfällighet — det är vad man får av att lägga sömmarna på
rätt ställen.

---

### 6. Vad komponenttestet ändå inte bevisar

Det bevisar att `EchoNode` samverkar rätt med **någon** implementation av `Interface`. Det bevisar
ingenting om `Spi`, som ännu inte finns, och ingenting om huruvida registerkartan lästs rätt.

Den sortens fel ligger en söm längre ned, och fångas i [L11](../../L11/README.md).

---
