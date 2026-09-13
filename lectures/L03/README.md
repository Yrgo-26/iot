# L03 - Bussar, routing och tillförlitlig kommunikation

## Dagordning
* Databussar och noder: varför broadcast är normen i inbyggda system.
* Adressering och routing (DST/SRC), och varför routingen ligger i noden och inte i bussen.
* Felmodell: tappade bytes, korrupt data och fördröjning - gjorda deterministiska.
* Kvittens: ACK och NACK, och skillnaden mellan *integritet* och *leveransgaranti*.
* När svar uteblir: timeout, retry och de dubbletter som följer.
* Gruppindelning inför **P03**, som startar på riktigt i [L04](../L04/README.md).

---

## Mål med lektionen
* Förstå vad en databuss är och varför broadcast är vanligt i inbyggda system.
* Kunna beskriva hur routing fungerar med DST/SRC.
* Förstå hur fel uppstår i en byte-ström, och varför en *deterministisk* felmodell är
  förutsättningen för att kunna testa felhantering.
* Kunna förklara varför en checksumma räcker för att upptäcka ett fel men inte för att laga det.
* Kunna beskriva ACK/NACK, timeout, retry och dubblettdetektion, och hur de hänger ihop.
* Kunna resonera om vilka av dessa mekanismer som *inte* behöver skrivas i mjukvara på en
  CAN-buss.

---

## Förutsättningar
* L01: `comm::frame::Frame` med `serialize()` och `deserialize()`.
* L02: `comm::frame::Parser` som kan extrahera frames från en byte-ström.

---

## Om det här passet
Det här är kursens sista pass med det egna protokollet, och det täcker mer än ett pass rimligen
hinner koda igenom. Så är det med avsikt.

Från [L04](../L04/README.md) tar CAN över, och då gör hårdvaran det mesta av det ni läser om
idag: framing, checksumma, kvittens och omsändning ligger i kisel. **Det gör inte materialet
mindre viktigt - det gör det till duggamaterial snarare än projektmaterial.** Ni ska kunna
resonera om mekanismerna på papper, och ni ska kunna känna igen dem när ni ser CAN göra dem åt
er.

Upplägget blir därför:
* **På lektionen:** bussen, routingen och del 1 av övningarna. Det är den delen som bygger den
  simulering resten vilar på.
* **Efter lektionen, som självstudier:** felmodellen, ACK/NACK samt timeout/retry/dubbletter, med
  del 2-4 av övningarna. Den som inte hinner koda dem ska ändå kunna gå igenom dem på papper -
  det är precis den formen duggan har.

Övningsduggan i [exam/](../../exam/practice_exam.md) visar nivån. Läs den tidigt, inte i slutet
av kursen.

---

## Instruktioner

### Förberedelse
* Läs **antingen** [bilaga A](./appendix/a_bus_and_routing.md) om databussar och routing, **eller**
  avsnitt 3.1 i kursboken ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).
* Läs igenom projektbeskrivningen för **P03** [här](../../projects/P03/README.md), åtminstone
  avsnitt 1-3.

### Under lektionen
* Delta i genomgången.
* Genomför **del 1** (uppgift 1-5) i [bilaga E](./appendix/e_exercises.md).
* Bilda projektgrupper om 4-5, och notera vilken hårdvarugrupp ni paras ihop med.

### Efter lektionen
* Läs **antingen** [bilaga B](./appendix/b_error_model.md) om felmodellen,
  [bilaga C](./appendix/c_ack_nack.md) om ACK/NACK och
  [bilaga D](./appendix/d_timeout_retry_duplicate.md) om timeout, retry och dubbletter, **eller**
  avsnitt 3.2-3.3 i kursboken
  ([svenska](../../book/sv/kommunikationsprotokoll-och-drivrutiner.pdf),
  [engelska](../../book/en/communication-protocols-and-drivers.pdf)).
* Genomför **del 2-4** (uppgift 6-21) i [bilaga E](./appendix/e_exercises.md).

---

## Demonstration
* Tre noder på en delad buss; en status request får ett status response.
* Samma körning med byte 5 droppad → parsern faller tillbaka till `WaitForSof1`.
* Samma körning med en bitflip → checksumman fallerar och framen avvisas.
* Förlorat ACK → timeout → retry → mottagaren ser en dubblett och kör *inte* applikationslogiken
  igen.

---

## Utvärdering
* Förstår ni varför vi behöver DST och SRC?
* Förstår ni varför en buss ofta är broadcast (alla får allt)?
* Varför räcker inte en checksumma som garanti för att en frame kom fram?
* Vad händer om timeout-värdet är för kort? Och för långt?
* Varför måste mottagaren skicka ACK igen när den upptäcker en dubblett, i stället för att
  bara ignorera den?

---

## Nästa lektion
* **CAN**, och slutet på det egna protokollet. Vi tittar på vad CAN-hårdvaran gör åt oss, läser
  registerkartan till den CAN-kontroller parallellklassen konstruerar, och ritar upp den
  lagerarkitektur **P03** ska byggas i.

---
