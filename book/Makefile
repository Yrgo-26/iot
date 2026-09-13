# Bygg kursboken i dess båda språkupplagor: två LuaLaTeX-pass per upplaga, det andra för
# innehållsförteckning och referenser.
#
#   make                 bygg båda upplagorna, daterade idag
#   make sv              bygg bara den svenska
#   make en              bygg bara den engelska
#   make VERSION=v2      detsamma, med versionen på titelsidan
#   make clean           ta bort allt bygget skriver
#
# Upplagorna delar design (coursebook.sty, coursebook.lua) och ingenting annat: texten, figurerna,
# titelsidan och den färdiga PDF:en ligger i en egen katalog per språk. Boken läser ingenting
# utanför book/, och koden i texten är en satt kopia av kursmaterialets, så en ändring i en
# föreläsning når boken först när motsvarande .tex-fil ändras.

ROOT    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD   := $(ROOT)/build
VERSION ?=

SV_PDF  := sv/kommunikationsprotokoll-och-drivrutiner.pdf
EN_PDF  := en/communication-protocols-and-drivers.pdf

# Designen, som båda upplagorna satts med, och därför bygger om båda när den ändras.
SHARED  := coursebook.sty coursebook.lua

# Texten i en upplaga: roten, förmaterialet, kapitlen, bakmaterialet och figurerna.
edition_sources = $(1)/book.tex \
                  $(wildcard $(1)/front/*.tex $(1)/chapters/*/*.tex \
                             $(1)/back/*.tex $(1)/back/*/*.tex $(1)/figures/*.tex)

# Ett LuaLaTeX-pass i språkkatalogen $(1). Designen ligger en nivå upp och hittas via TEXINPUTS,
# allt annat är relativt katalogen, så de två upplagornas källor ser likadana ut inifrån.
latex_pass = cd $(ROOT)/$(1) && TEXINPUTS="$(ROOT):$$TEXINPUTS" \
             lualatex -interaction=nonstopmode -halt-on-error -file-line-error \
                      -output-directory=$(BUILD)/$(1) -jobname=book \
                      '\def\bookversion{$(VERSION)}\input{book.tex}'

.PHONY: all sv en clean FORCE

all: sv en

sv: $(SV_PDF)
en: $(EN_PDF)

# Versionen bygget senast gjordes för. Filen skrivs om bara när VERSION ändras, så att en ny
# version - eller ingen efter en - bygger om titelsidan och ingenting annat gör det.
$(BUILD)/version: FORCE
	@mkdir -p $(BUILD)
	@echo '$(VERSION)' | cmp -s - $@ || echo '$(VERSION)' > $@

$(SV_PDF): $(SHARED) $(call edition_sources,sv) $(BUILD)/version
	@mkdir -p $(BUILD)/sv
	$(call latex_pass,sv) >/dev/null || (tail -40 $(BUILD)/sv/book.log; exit 1)
	$(call latex_pass,sv) >/dev/null || (tail -40 $(BUILD)/sv/book.log; exit 1)
	@! grep -q "There were undefined references" $(BUILD)/sv/book.log || \
	    (echo "error: odefinierade referenser; se $(BUILD)/sv/book.log"; exit 1)
	cp $(BUILD)/sv/book.pdf $@

$(EN_PDF): $(SHARED) $(call edition_sources,en) $(BUILD)/version
	@mkdir -p $(BUILD)/en
	$(call latex_pass,en) >/dev/null || (tail -40 $(BUILD)/en/book.log; exit 1)
	$(call latex_pass,en) >/dev/null || (tail -40 $(BUILD)/en/book.log; exit 1)
	@! grep -q "There were undefined references" $(BUILD)/en/book.log || \
	    (echo "error: odefinierade referenser; se $(BUILD)/en/book.log"; exit 1)
	cp $(BUILD)/en/book.pdf $@

clean:
	rm -rf $(BUILD) $(SV_PDF) $(EN_PDF)
