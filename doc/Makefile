#
# Sympa documentation Makefile
#
# Available targets:
#   - all: generates .ps and .html files
#   - ps: generates sympa.ps
#   - html: generates directory sympa/ with *.html files
#   - clean: removes all files
#   - distrib: cleans all auxiliary files
#
# Needs:
#   - latex2e
#   - packages:
#	epsfig
#	xspace
#	makeidx
#	a4		(optional, edit sympa.tex to remove it)
#	palatino	(optional, edit sympa.tex to remove it) 
#	changebar
#	html		(comes with latex2html)
#   - dvips
#   - fig2dev (a fairly recent version comes with transfig 3.2 and later)
#   - makeindex
#   - latex2html
#
# History
#   1999/04/13 : pda@prism.uvsq.fr : design of this makefile
#   1999/04/18 : pda@prism.uvsq.fr : added index generation
#   1999/06/24 : os@cru.fr         : icons are duplicated with html (-local_icons)
#

LATEX	= latex
DVIPS	= dvips
FIG2DEV	= fig2dev
LATEX2HTML = latex2html
MAKEINDEX = makeindex

# encapsulated postcript part of the source
# EPS	= ls-lR.eps
# GIF	= ls-lR.gif

.SUFFIXES: .fig .eps

.fig.eps:
	fig2dev -Lps $*.fig > $*.eps


all:	ps html

#
# PS generation
#

ps:	sympa.ps

sympa.ps: sympa.dvi
	$(DVIPS) -f sympa.dvi > sympa.ps

sympa.tex: sympa.tex.tpl
	$(PERL) ./parse_tex.pl sympa.tex.tpl sympa.tex

sympa.dvi: sympa.tex $(EPS)
	cp /dev/null sympa.ind
	$(LATEX) sympa
	$(MAKEINDEX) sympa
	$(LATEX) sympa
	$(MAKEINDEX) sympa
	$(LATEX) sympa
	$(MAKEINDEX) sympa
	$(LATEX) sympa

#
# HTML generation
#

html:	sympa/sympa.html

# -tmp is required since cwd contains a dot in it
sympa/sympa.html: sympa.tex $(GIF)
	$(LATEX2HTML) -tmp /tmp -verbosity 0 -local_icons sympa
	cd sympa ; rm -f WARNINGS images.* internals.pl labels.pl
#	cp ls-lR.gif sympa
	cp sympa.ps sympa

#
# Clean-up
#

clean: rmaux
	rm -f *.ps
	rm -rf sympa

rmaux:
	rm -f *.aux *.log *.toc *.dvi *.bak *.cb *.ind *.idx *.ilg
	rm -f $(EPS)

distrib: all rmaux




