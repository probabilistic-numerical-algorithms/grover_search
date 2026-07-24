.DELETE_ON_ERROR:
.PHONY: clean default all

PANDOC := pandoc
LUALATEX := lualatex

.DEFAULT_TARGET := default

default:: all
all:: Classical-Resonance-Engine.tex
all:: Classical-Resonance-Engine.pdf

clean::
	-rm -f *.{aux,log}

%.tex: %.md
	$(PANDOC) -s -f markdown -t latex $(<) -o $(@)

%.pdf: %.tex
	$(LUALATEX) $(<)
