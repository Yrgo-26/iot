# Bilaga B

## Övningsuppgifter

Uppgifterna motsvarar **milstolpe 5** i
[**P03**](../../../projects/P03/README.md#9-milstolpe-5---spi-metodkontrakten). Arbeta i
branchen `feature/spi`.

---

### **1.** Implementera packningen
Skriv hjälpfunktionerna som packar `frame.data` till `TX_DATA_LO` respektive `TX_DATA_HI`, enligt
[bilaga A avsnitt 2](./a_spi_driver.md#2-packningen).

Kontrollera mot `PrintTransport` från [L09](../../L09/appendix/b_exercises.md):
`id = 0x123`, `dlc = 2`, data `AA BB` ska ge transaktionen `83 AA BB 00 00`.

---

### **2.** Implementera `send()`
Enligt [bilaga A avsnitt 1](./a_spi_driver.md#1-send).

Kontrollera, mot `PrintTransport`, att en komplett `send()` ger exakt sex transaktioner i denna
ordning: en läsning av `STATUS`, fem skrivningar, och `TX_SEND` sist.

---

### **3.** Implementera `receive()`
Enligt [bilaga A avsnitt 3](./a_spi_driver.md#3-receive).

Glöm inte maskeringen mot `frame.dlc` och kvittensen sist.

---

### **4.** Implementera `hasError()` och `clearError()`
Enligt [bilaga A avsnitt 4](./a_spi_driver.md#4-haserror-och-clearerror).

Kontrollera att `clearError()` skriver `0x00000000` och inte `0x00000001`. Det är en enda siffra,
och den kostar en kväll om den är fel.

---

### **5.** Bryt koden med flit
Gör en ändring i taget, kör mot `PrintTransport`, och skriv ned **vad utskriften visar** och
**hur felet skulle yttra sig på en riktig buss**. Återställ efter varje.

| # | Ändring | Utskrift? | Symptom på bussen? |
|---|---|---|---|
| a | `TX_SEND` skrivs först i stället för sist | | |
| b | `TX_DATA_LO` och `TX_DATA_HI` byter plats | | |
| c | Skiftningarna inom `pack()` i omvänd ordning | | |
| d | `clearError()` skriver `0x1` | | |
| e | `receive()` glömmer `RX_ACK` | | |
| f | `receive()` maskerar inte mot `dlc` | | |
| g | `send()` hoppar över statuskontrollen | | |

Rad (f) är den svåraste: utskriften ser **rätt ut**. Varför, och vilket testfall i
[L11](../../L11/README.md) fångar den ändå?

---

### **6.** Räkna transaktioner
Skriv ned, utan att köra:

1. Hur många transaktioner kostar en `send()` som lyckas?
2. En `send()` som returnerar `false` på grund av upptagen hårdvara?
3. En `send()` som returnerar `false` på grund av `dlc = 9`?
4. En `receive()` som inte hittar någon frame?
5. En `receive()` som hittar en frame?
6. `hasError()`?

Kontrollera sedan mot `PrintTransport`. Stämde 3?

Fråga 3 är poängen: valideringen ligger först **just för att** en ogiltig frame inte ska kosta en
enda transaktion.

---

### **7.** Den oändliga loopen
Skriv den här loopen i ett litet testprogram mot `PrintTransport`:

```cpp
while (!driver.send(frame))
{
}
```

* Kör den med en giltig frame och en transport som säger att hårdvaran är upptagen. Vad händer?
* Kör den med `frame.dlc = 9`. Vad händer?
* Skriv om loopen så att båda fallen hanteras, enligt
  [bilaga A avsnitt 5.1](./a_spi_driver.md#51-en-förlorad-arbitrering-ser-ut-som-en-lyckad-sändning).

---

### **8.** Designfrågor att besvara i gruppen
Skriv korta svar; de hör hemma i `p03_report.md`.

1. `send()` returnerar `false` av två helt olika skäl. Vad skulle ni ha ändrat i `Interface` för
   att skilja dem åt, och vad hade det kostat `Stub`?
2. `receive()` maskerar mot `dlc` trots att hårdvaran redan nollställer. Ge ett scenario där det
   faktiskt gör skillnad.
3. Er nod sänder en frame och förlorar arbitreringen. Beskriv, steg för steg, vad drivrutinen
   observerar - och vad den *inte* kan observera.
4. Kontrollern buffrar inte mottagna frames. Vilken ändring i **er** kod minskar risken att tappa
   en frame mest, och vilken gräns kan ni ändå inte komma förbi?

---

### **9.** Checklistan
Gå igenom [checklistan i bilaga A avsnitt 6](./a_spi_driver.md#6-checklista-före-make-test) rad
för rad innan ni öppnar PR:en. Elva punkter, och var och en av dem har varit någons bugg.

---

### **10.** Pull Request
Öppna en PR, låt en annan gruppmedlem granska. Granskaren ska gå igenom checklistan oberoende av
er, och ställa minst en fråga om varför något är gjort som det är.

---

## Reflektion inför L11
* Ni har nu en komplett drivrutin som aldrig har körts mot något som beter sig som hårdvara.
  Vilka av felen i uppgift 5 hade `PrintTransport` **inte** kunnat avslöja?
* Vad skulle en testdubblare behöva kunna för att fånga dem?

---
