# Kommunikationsprotokoll och drivrutiner

Kursboken, satt med LuaLaTeX, i **två språkupplagor**: svenska och engelska. **Ett kapitel per
föreläsning**, femton stycken, i tre delar:

| Kapitel | Del | Innehåll |
|---|---|---|
| 1–3 | Ett eget protokoll | Frames, byte-parsning, bussar, routing och tillförlitlighet |
| 4–12 | CAN-drivrutinen | Registerkartan, arkitekturen, interfacet, stubben, SPI, transportsömmen, drivrutinen, testningen, hårdvaran |
| 13–15 | Hårdvaran | Bring-up, bussanalys, repetition |
| App. A | | Lösningar till alla övningar som inte ber om kod |
| App. B–D | | Om duggan, övningsduggan, och fullständiga svar |

Varje kapitel öppnar med vad det innehåller, avslutas med en sammanfattning, och har därefter
sina övningar. **Lösningarna till varje övning som inte ber om kod står i appendix A**, liksom
svaren på övningsduggan. Koden som kodövningarna ber om besvaras av den utdelade testsviten, och
publiceras i kursrepot efter respektive föreläsning.

Boken nämner varken klass eller årtal, så den kan användas som den är över flera år.

---

## Upplagorna

| Upplaga | Källor | PDF |
|---|---|---|
| Svenska | [`sv/`](./sv/) | [`sv/kommunikationsprotokoll-och-drivrutiner.pdf`](./sv/kommunikationsprotokoll-och-drivrutiner.pdf) |
| Engelska | [`en/`](./en/) | [`en/communication-protocols-and-drivers.pdf`](./en/communication-protocols-and-drivers.pdf) |

De två är samma bok: samma kapitel, samma figurer, samma övningar och samma svar, med samma
`\label` så att en hänvisning betyder samma sak i båda. **Ändras något i den ena ska motsvarande
ändring göras i den andra**, annars glider upplagorna isär.

I den svenska upplagan är brödtexten på svenska; i den engelska är den på engelska. All kod och
alla register- och signalnamn är på engelska i båda.

---

## Bygga

```bash
make                 # bygger båda upplagorna
make sv              # bara den svenska
make en              # bara den engelska
make VERSION=v2      # samma, med versionen på titelsidan
make clean           # tar bort allt bygget skriver
```

Kräver **LuaLaTeX** med TeX Gyre-typsnitten, DejaVu Sans Mono och paketen `babel` (svenska och
engelska), `tcolorbox`, `listings`, `titlesec`, `booktabs` och `tikz`. På Ubuntu/WSL:

```bash
sudo apt -y install texlive-luatex texlive-latex-extra texlive-fonts-extra texlive-lang-european
```

Två pass körs alltid per upplaga, det andra för innehållsförteckningen och referenserna. Bygget
fallerar om någon referens är odefinierad.

---

## Struktur

```text
coursebook.sty    All design - typsnitt, färger, rubriker, kodblock, övningar, svar.
                  Delas av båda upplagorna; språket väljs med paketets option
                  ([swedish] eller [english]), och allt språkberoende ligger samlat
                  i dess avsnitt "Språk"
coursebook.lua    Hjälpfunktionen \code{} behöver för att sätta kod ordagrant
sv/               Den svenska upplagan, och dess PDF
en/               Den engelska upplagan, och dess PDF
build/            Byggkatalog, en underkatalog per språk; skapas av make och
                  versionshanteras inte
```

Varje språkkatalog ser likadan ut inuti:

```text
book.tex          Dokumentets rot: vilka kapitel som ingår, i vilken ordning
front/            Titelsida och förord
chapters/NN/      Ett kapitel per föreläsning: chapter.tex, avsnittsfiler,
                  summary.tex och exercises.tex
back/exam/        Om duggan, övningsduggan, och svaren
figures/          Figurerna, ritade i TikZ
```

Boken läser ingenting utanför `book/`. En ändring i kursmaterialet når alltså boken först
när motsvarande `.tex`-fil ändras.

---

## Att lägga till ett kapitel

1. Skapa `sv/chapters/NN/chapter.tex` med `\chapter{...}`, ett `\label{ch:...}` och `\lecture{}`.
2. Lägg till `\input{chapters/NN/chapter}` i `sv/book.tex`.
3. Avsluta kapitlet med `\input{...summary}` och `\input{...exercises}`.
4. Numrera övningarna `\label{ex:NN:M}`.
5. Gör om steg 1–4 i `en/`, med **samma** `\label` och samma filnamn.

Referenser mellan kapitel skrivs `\kapref{ch:...}`, aldrig med ett hårdkodat kapitelnummer.
Etiketterna är desamma i båda upplagorna och översätts inte.

---

## Relaterade böcker

* CAN-boken, som kapitel 4 är den korta versionen av, i två språkupplagor precis som den här:
  [CAN - bussen, framen och kontrollern](https://github.com/Yrgo-26/can-book/blob/main/sv/can-sv.pdf) och
  [CAN - the bus, the frame and the controller](https://github.com/Yrgo-26/can-book/blob/main/en/can-en.pdf).
  Den ligger i ett eget repo, [Yrgo-26/can-book](https://github.com/Yrgo-26/can-book), eftersom den
  delas med hårdvarukursen, och nämner därför ingen kurs. Den svenska upplagan hänvisar till den
  svenska CAN-boken och den engelska till den engelska; kapitelnumren är desamma i båda.

---

## Ge ut en ny upplaga

PDF:erna är incheckade i repot, så de går att läsa direkt på GitHub. En skarp upplaga publiceras
dessutom som en release: pusha en versionstagg.

```bash
git tag v1.1.0
git push origin v1.1.0
```

[Book-arbetsflödet](../.github/workflows/book.yml) bygger då båda upplagorna med taggen på
titelsidan och lägger upp dem i en release med samma namn.

Boken ska kunna användas i många år, så ingen sida i den nämner en klass, ett år eller ett datum;
titelsidan visar versionen, och byggdatumet bara när ingen version anges.

---

## Licens
Bokens text och figurer, och PDF:erna som byggs från dem, är licensierade under
[CC BY 4.0](../LICENSE), liksom kursmaterialet de är satta från. Koden som förekommer i bokens
listningar får även användas under [MIT-licensen](../LICENSE-CODE).

---
