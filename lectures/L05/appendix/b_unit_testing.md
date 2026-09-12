# Bilaga B

## Testpyramiden och de utdelade testsviterna

Den här bilagan är kursens genomgång av testningen: testpyramiden, ramverket,
Arrange-Act-Assert och hur en fallerande svit läses. Den förutsätter ingen tidigare erfarenhet av
enhetstestning.

Allt här gäller de **utdelade** testsviterna. Börja med avsnitt 0, som säger varför de är
utdelade.

---

### 0. Ni skriver inga tester i den här kursen

Det är den stora skillnaden mot hur enhetstestning brukar läras ut, där man skriver sina egna
testfall från början.

**Varje testsvit i den här kursen är utdelad.** Ert jobb är att

1. **köra** dem,
2. **läsa** dem när de fallerar, och
3. **få dem att passera**.

Det är ett medvetet upplägg. Att skriva bra tester är ett eget hantverk, och det lär ni er i
*Mjuk- och hårdvarutestning* efter den här kursen. Här får ni i stället se vad tester är **till
för**, på ett projekt där de gör verklig nytta: hårdvaran finns inte än, och testsviterna är det
enda som säger er om drivrutinen fungerar.

Ordningen är avsiktlig. Den som har sett en testsvit hitta en bugg i sin egen kod, och har läst
ett testfall som en kravspecifikation, har en betydligt konkretare bild av vad ett bra test är
än den som ombeds skriva ett först.

Läs därför resten av den här bilagan som *lässtöd*: den säger vad ett test är och hur det läses,
inte hur man skriver ett.

---

### 1. Varför testning är en del av *den här* kursen

I era tidigare projekt gick det att köra programmet och titta. Här går det inte:

* **Hårdvaran finns inte än.** Hårdvaruklassen bygger sin CAN-nod parallellt med att ni bygger
  drivrutinen. Det första passet ni kan köra mot riktig hårdvara är [L13](../../L13/README.md) —
  tredje passet från slutet.
* **Hårdvaran är inte er.** När den väl finns felsöks den samtidigt av någon annan. En bugg som
  uppstår under bring-upen kan ligga i er kod, i deras VHDL, eller i en kopplingstråd, och att ta
  reda på vilket är dyrt.
* **Det mesta av drivrutinen går att köra utan hårdvara.** Det är inte en tröstpremie utan en
  designkonsekvens: sömmarna i arkitekturen finns just för att göra det möjligt.

Regeln som följer: **allt som kan köras på laptopen ska vara grönt innan det körs på hårdvara.**
Bring-upen ska leta efter kopplingsfel, inte efter bitpackningsfel.

---

### 2. Pyramiden, hos oss

Testpyramiden delar upp tester efter hur mycket de omfattar: ett **enhetstest** provar en klass i
taget, ett **komponenttest** flera delar ihop men utan hårdvara, och ett **integrationstest** det
riktiga systemet med riktiga ledningar. Bredden är en rekommendation om *antal* — många snabba
tester längst ned, få dyra längst upp. Ett projekt med tre snabba tester och en person som kopplar
om sladdar är pyramiden upp och ned.

Så här faller kursens moment på nivåerna:

| Nivå | Var | Vad |
|---|---|---|
| Enhetstest | [L05](../../L05/README.md), [L06](../../L06/README.md) | `Frame`, `Stub` — en klass i taget |
| Komponenttest | [L07](../../L07/README.md), [L11](../../L11/README.md) | `EchoNode` genom stubben; `Spi` mot en simulerad registerbank |
| Integrationstest | [L13](../../L13/README.md), [L14](../../L14/README.md) | Riktig hårdvara, riktiga ledningar |

Integrationsnivån är den enda som inte går att automatisera här, och det är precis vad de två
labbpassen är till för.

---

### 3. Ramverket

`qacademy::test` ligger i [`libs/test`](../../../libs/test/README.md) som git-submodul, och dess
README är API-referensen. Hela API:t ni behöver kunna läsa är `TEST(svit, namn)`, som deklarerar
ett testfall, och kontrollerna `EXPECT_TRUE`, `EXPECT_FALSE`, `EXPECT_EQ` och `EXPECT_NE`.

Det enda värt att tillägga: ett `EXPECT_*` som fallerar **avbryter inte** testfallet. Ett testfall
kan alltså rapportera flera fel på en körning, vilket är precis vad man vill när ett
bitpackningsfel slagit igenom på fyra bytes samtidigt.

---

### 4. Arrange-Act-Assert, som lässtöd

Varje testfall har tre delar, i den ordningen: **Arrange** ställer upp utgångsläget, **Act** utför
det som ska provas, och **Assert** kontrollerar resultatet. Hos oss används mönstret åt andra
hållet: ni skriver inte testfall efter det, ni **läser** dem efter det.

När ni öppnar en utdelad testfil, läs i den ordningen. Arrange säger vilket utgångsläge kravet
gäller i, Act säger vad som ska hända, och **Assert är kravet**.

---

### 5. Att läsa en fallerande testsvit

```text
FAILED: EXPECT_EQ(frame.data[0], 0xAAU) at test_frame.cpp:42
```

Tre saker står där: **vilket** uttryck som inte höll, **var** det stod, och därmed **vad** testet
förväntade sig. Arbetsgången när något fallerar, och **utan att öppna er egen kod i steg 1–3**:

1. Läs **testnamnet**. Det säger vilket krav som är brutet.
2. Läs **Arrange-delen**. Den säger under vilka förutsättningar.
3. Läs **Assert-raden** som fallerade. Den säger vad som förväntades.
4. Först därefter: öppna er egen kod.

Steg 1–3 tar en minut och gör steg 4 kort. Att hoppa direkt till steg 4 är den vanligaste
anledningen till att en enkel bugg tar en timme.

---

### 6. Gränsvärden: varför sviterna ser ut som de gör

Titta på vilka värden den utdelade sviten för `Frame` använder: `0x7FF` och `0x800`, `8` och `9`.
Inte `0x400` och `4`.

Buggar bor på gränserna. En jämförelse som ska vara `<=` men skrevs `<` fungerar för varenda
värde utom ett, och det värdet är exakt det testet använder.

**Mönstret att känna igen:** för varje gräns finns ett par — det största värdet som ska accepteras
och det minsta som ska avvisas. Ser ni ett sådant par i en utdelad svit vet ni vilken rad i er
kod det handlar om.

---

### 7. Testerna som kravspecifikation

Det här är det viktigaste ni tar med er.

Prosan i [**P03**](../../../projects/P03/README.md) är skriven av en människa och kan vara
tvetydig. Den utdelade testsviten kan det inte: den kompilerar och den kör. När ni undrar exakt
vad `receive()` ska returnera i ett gränsfall, **öppna testfilen innan ni gissar**.

Det gäller särskilt i [L11](../../L11/README.md), där den utdelade sviten kontrollerar era
SPI-transaktioner byte för byte. Den filen är i praktiken protokollet i
[L08 bilaga A](../../L08/appendix/a_spi.md) skrivet som kod.

---

### 8. Bygga och köra

```bash
git submodule update --init
make test
```

`make build` i repots rot bygger och kör allt som har en Makefile, och det är samma kontroll som
CI kör.

En grön CI betyder inte att koden är rätt — bara att den kompilerar och att de utdelade testerna
passerar. Den skillnaden är värd att hålla i minnet under hela projektet, och den är precis vad
*Mjuk- och hårdvarutestning* ägnar sig åt: vem bestämmer att testsviten testar rätt saker?

---
