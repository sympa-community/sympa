# Makefile - This Makefile does the Sympa documentation processing and installation
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

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
PDFLATEX	=	pdflatex	
MAKEINDEX = makeindex

# encapsulated postcript part of the source
# EPS	= ls-lR.eps
# GIF	= ls-lR.gif

.SUFFIXES: .fig .eps

.fig.eps:
	fig2dev -Lps $*.fig > $*.eps


all:	ps pdf html parse_tex.pl

#
# PS generation
#

ps:	sympa.ps

pdf:	sympa.pdf

sympa.ps: sympa.dvi
	$(DVIPS) -f sympa.dvi > sympa.ps

sympa.pdf: sympa.tex
	$(PDFLATEX) sympa.tex

sympa.tex: sympa.tex.tpl
	@(DIR='${DIR}'; export DIR; \
	BINDIR='${BINDIR}'; export BINDIR; \
	EXPL_DIR='${EXPL_DIR}'; export EXPL_DIR; \
	SBINDIR='${SBINDIR}'; export SBINDIR; \
	LIBDIR='${LIBDIR}'; export LIBDIR; \
	NLSDIR='${NLSDIR}'; export NLSDIR; \
	SPOOLDIR='${SPOOLDIR}'; export SPOOLDIR; \
	SCRIPTDIR='${SCRIPTDIR}'; export SCRIPTDIR; \
	WWSBINDIR='${WWSBINDIR}'; export WWSBINDIR; \
	MAILERPROGDIR='${MAILERPROGDIR}'; export MAILERPROGDIR; \
	ETCBINDIR='${ETCBINDIR}'; export ETCBINDIR; \
	ETCDIR='${ETCDIR}'; export ETCDIR; \
	PIDDIR='${ETCDIR}'; export PIDDIR; \
	CONFIG='${CONFIG}'; export CONFIG; \
	WWSCONFIG='${WWSCONFIG}'; export WWSCONFIG; \
	$(PERL) ./parse_tex.pl sympa.tex.tpl sympa.tex;)

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

html:	html/sympa.html

# -tmp is required since cwd contains a dot in it
html/sympa.html: sympa.tex $(GIF)
	$(LATEX2HTML) -dir html -mkdir -tmp /tmp -verbosity 0 -local_icons sympa
	cd html ; rm -f WARNINGS images.* internals.pl labels.pl
	cp sympa.ps html

#
# Clean-up
#

clean: rmaux
	rm -f *.ps
	rm -rf html

rmaux:
	rm -f *.aux *.log *.toc *.dvi *.bak *.cb *.ind *.idx *.ilg
	rm -f $(EPS)

distrib: all rmaux

makedir:
	@if [ ! -d $(DESTDIR)$(DOCDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(DOCDIR)"; \
		mkdir -p $(DESTDIR)$(DOCDIR); \
	fi

install: makedir 
	@for f in sympa.tex sympa.ps sympa.pdf; do \
		echo "Installing documentation...$(DESTDIR)$(DOCDIR)/$$f"; \
		cp $$f $(DESTDIR)$(DOCDIR); \
	done
	@if [  -d $(DESTDIR)$(DOCDIR)/sympa ]; then \
		rm -rf $(DESTDIR)$(DOCDIR)/sympa; \
	fi
	@if [  -d $(DESTDIR)$(DOCDIR)/html ]; then \
		rm -rf $(DESTDIR)$(DOCDIR)/html; \
	fi
	cp -R html/ $(DESTDIR)$(DOCDIR)



