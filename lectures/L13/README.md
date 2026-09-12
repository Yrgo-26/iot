# L13 - Bring-up mot hårdvarugruppens CAN-nod

> **Obligatorisk labb, första passet.** Ger inga poäng, men är ett krav för godkänt på kursen -
> och **er länk ska fungera innan [L14](../L14/README.md)**, då representanter från Vector är på
> plats. Se [labb-PM:et](../../lab/README.md).

## Dagordning
* Kopplingen: AVR32DB28 mot DE0-CV över fyra ledningar, och FPGA-nodens CAN-sida ut på en
  riktig differentiell buss genom en transceiver.
* Bring-up-stegen, fem stycken, var och en med ett eget kvitto.
* Felsökning: vad varje symptom betyder, och vad det **inte** betyder.
* Överlämning mellan klasserna: att felsöka något två grupper har skrivit varsin halva av.

---

## Mål med lektionen
* Kunna koppla ihop en AVR32DB28-nod och en FPGA-nod enligt kontraktets pinnkonfiguration.
* Kunna koppla FPGA-nodens enledarbuss till en CAN-transceiver, och terminera bussen rätt.
* Kunna klättra bring-up-stegen i ordning, och säga vad varje steg bevisar som det föregående
  inte gjorde.
* Kunna gå från ett symptom till en hypotes till ett mätvärde, i stället för att byta sladdar
  tills det fungerar.
* Ha en fungerande länk: er drivrutin ska skicka och ta emot riktiga CAN-frames.

---

## Förutsättningar
* [L12](../L12/README.md) klar, och **hela checklistan i
  [L12 bilaga B avsnitt 6](../L12/appendix/b_factory_and_app.md#6-checklista-inför-l13)
  avbockad.** Det här passet är till för att koppla och felsöka, inte för att bli klar med
  milstolpe 7.
* En hårdvarugrupp med en syntetiserad `can_spi_node`. Har er partnergrupp inte en färdig nod:
  **låna ett fungerande kort.** Pinnkonfigurationen är gemensam just därför, och en trasig
  tidsplan hos någon annan är inte ett giltigt skäl att sakna en länk.

---

## Instruktioner

### Förberedelse
* Läs [labb-PM:et](../../lab/README.md) i sin helhet, särskilt kopplingsschemat och
  bring-up-stegen.
* Ta med: AVR32DB28-kort, USB-kabel, CAN-transceiver, två 120 Ω motstånd, tvinnad kabel,
  kopplingsdäck och kopplingstråd. Logikanalysator om ni har tillgång till en.

### Under passet
* Genomför steg 1-5 i [labb-PM:et](../../lab/README.md#bring-up-stegen).
* Dokumentera varje steg: vad ni observerade, och vad ni fick ändra.

### Efter passet
* Fyll i bring-up-loggen. Den hör hemma i `p03_report.md` och besvarar fråga 8 i
  [**P03** avsnitt 15](../../projects/P03/README.md#15-utvärdering).
* **Fungerar inte länken:** boka handledningstid före [L14](../L14/README.md). Vänta inte till
  labbpasset.

---

## Utvärdering
* Vad bevisar steg 2 (registereko) som steg 1 (SPI-loopback) inte gjorde?
* Vilket steg var svårast, och vilket testfall från [L11](../L11/README.md) hade kunnat fånga
  felet tidigare - om något?
* Ni läser `STATUS` och får `0x00000000` varje gång. Räkna upp minst fyra möjliga orsaker, i den
  ordning ni skulle undersöka dem.
* Er nod skickar en frame, men den syns inte på bussen. Är felet i er drivrutin, i FPGA:n eller i
  kopplingen? Hur avgör ni det utan att gissa?

---

## Nästa lektion
* **CAN-labben med Vector CANalyzer.** Trafiken ni fick igång idag ska analyseras: frame för frame,
  bit för bit, med representanter från Vector på plats.

---
