# Bilaga B

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 6** i
[**P03**](../../../projects/P03/README.md#10-milstolpe-6---testning). Arbeta i branchen
`feature/tests`.

Kom ihåg: **ni skriver inga tester.** Allt i `test/` är utdelat och läggs in oförändrat.

---

### **1.** Lägg in sviten och kör den
Kopiera in `test/scripted_transport.hpp`, `test/bank_transport.hpp`, `test/test_spi.cpp` och
`test/main.cpp` oförändrade, och kör:

```bash
make test
```

Notera hur många testfall som fallerar första gången. Skriv ned siffran - ni kommer att vilja
jämföra med den senare.

---

### **2.** Få sviten grön
Arbeta igenom de fallerande testfallen ett i taget, enligt arbetsgången i
[bilaga A avsnitt 5](./a_testing_the_driver.md#5-att-gå-från-ett-fallerande-testfall-till-buggen).

För varje bugg ni hittar, skriv en rad i en enkel logg:

| Testfall som fallerade | Vad testnamnet sa | Var buggen låg | Minuter |
|---|---|---|---|

Loggen ska med i `p03_report.md`. Den är intressantare än den låter: kolumnen "minuter" brukar
falla dramatiskt under uppgiftens gång, och skälet är att man slutar gissa.

---

### **3.** Läs sviten som kravspecifikation
Öppna `test/test_spi.cpp` och besvara:

1. Vilket testfall motsvarar exemplet `83 AA BB 00 00` i
   [L08 bilaga A](../../L08/appendix/a_spi.md#6-ett-komplett-exempel)?
2. Vilket testfall kontrollerar att en ogiltig frame inte kostar en enda transaktion? Hur
   kontrollerar det den saken?
3. Vilket testfall skulle fortfarande vara grönt om `clearError()` skrev `0x2` i stället för
   `0x0`? Finns det ett som skulle fallera?
4. Hur många testfall använder `ScriptedTransport` och hur många använder `BankTransport`?
   Stämmer fördelningen med resonemanget i
   [bilaga A avsnitt 1](./a_testing_the_driver.md#1-varför-två)?

---

### **4.** Vilken dubblare fångar vad?
För var och en av buggarna nedan: fångas den av `ScriptedTransport`, av `BankTransport`, av båda,
eller av ingen? Motivera i en mening, och **kontrollera sedan genom att införa buggen**.

| # | Bugg | Scripted? | Bank? |
|---|---|---|---|
| a | `TX_DATA_LO` och `TX_DATA_HI` förväxlade | | |
| b | `clearError()` skriver `0x1` | | |
| c | `receive()` maskerar inte mot `dlc` | | |
| d | `receive()` glömmer `RX_ACK` | | |
| e | `readReg()` räknar med kommandobytens MISO-svar | | |
| f | `send()` skriver `TX_SEND` först | | |
| g | `send()` validerar inte `dlc` | | |
| h | `MOSI` och `MISO` omkastade i kopplingen | | |

Rad (h) är med av ett skäl. Vilket?

---

### **5.** Kör hela stacken
Kör testfallet som kopplar `EchoNode` → `Spi` → `BankTransport`, se
[bilaga A avsnitt 4](./a_testing_the_driver.md#4-hela-stacken-på-laptopen).

* Öppna `app/echo_node.hpp` och `echo_node.cpp`. Hur många rader har ändrats sedan
  [L07](../../L07/README.md)?
* Vilken egenskap hos arkitekturen gjorde bytet från `Stub` till `Spi` gratis?
* Vad hade behövt ändras om `EchoNode` hade tagit en `driver::can::Spi&` i konstruktorn?

---

### **6.** Vad återstår?
Skriv en lista på **allt** som fortfarande kan vara fel trots att hela sviten är grön. Sikta på
minst fem punkter. [Bilaga A avsnitt 6](./a_testing_the_driver.md#6-vad-en-grön-testsvit-inte-bevisar)
ger några; försök hitta minst en till på egen hand.

Listan är er checklista inför [L13](../../L13/README.md), och den ska med i `p03_report.md`.

---

### **7.** Pull Request och avstämning
* Öppna en PR med hela sviten grön, och låt en annan gruppmedlem granska.
* Kör `make build`, `make format-check` och `make docs-check` från repots rot. Allt ska vara
  grönt från ett rent utcheckat repo.
* **Stäm av med er hårdvarugrupp.** Var är de? Har de en syntetiserad `can_spi_node`? Behöver ni
  låna ett kort inför [L13](../../L13/README.md)?

Den sista punkten är inte artighet utan planering: bring-upen är obligatorisk, och er länk ska
fungera före [L14](../../L14/README.md).

---

### **8.** Övningsduggan
Läs igenom [övningsduggan](../../../exam/practice_exam.md) och försök besvara åtminstone
G-uppgifterna. Den gås igenom i [L15](../../L15/README.md), men den som börjar då börjar för
sent - och L13 och L14 är labbpass utan tid för repetition.

---

## Reflektion inför L12
* Er drivrutin har aldrig sett ett riktigt hårdvaruregister. Nästa lektion gör den det, en söm
  längre ned. Vilken klass är det som ska skrivas, och vilket interface ska den implementera?
* Vad tror ni att `volatile` är till för, och varför har ni inte behövt det hittills?

---
