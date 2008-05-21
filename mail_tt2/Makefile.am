# Makefile - This Makefile does the mail templates installation
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

default: none

install:
	echo "Please use the main Makefile for installing WWSympa."

newinstall: makedir installtemplates installmod

installmod:
	chown $(USER) $(DESTDIR)$(ETCBINDIR)/mail_tt2/*
	chgrp $(GROUP) $(DESTDIR)$(ETCBINDIR)/mail_tt2/*
	chmod 755 $(DESTDIR)$(ETCBINDIR)/mail_tt2

makedir:
	@if [ ! -d $(DESTDIR)$(ETCBINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)"; \
		mkdir -p $(DESTDIR)$(ETCBINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/mail_tt2 ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/mail_tt2"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/mail_tt2; \
	fi

installtemplates:
	@echo
	@echo "Installing mail templates..."
		@( \
		PERL=$(PERL); export PERL; \
		UMASK=0644; export UMASK; \
		INSTALLDIR=$(ETCBINDIR)/mail_tt2; export INSTALLDIR; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		CGIDIR=$(CGIDIR); export CGIDIR; \
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		COL1=5; export COL1; \
		COL2=40; export COL2; \
		COL3=30; export COL3; \
		COL4=40; export COL4; \
		COL12=45; export COL12; \
		COL23=70; export COL23; \
		COL34=70; export COL34; \
		COL234=110; export COL234; \
		$(PERL) ../subst.pl *.tt2; \
		); \
	$(PERL) ../set_symlinks.pl mail_tt2 $(DESTDIR)$(ETCBINDIR)/mail_tt2
	find $(DESTDIR)$(ETCBINDIR) -type d -exec chmod 755 {} \;
	find $(DESTDIR)$(ETCBINDIR) -type f -exec chmod 444 {} \;
	rm -f $(DESTDIR)$(ETCBINDIR)/web_tt2/authorization_reject.tt2 ; \
	(cd $(DESTDIR)$(ETCBINDIR)/web_tt2 ; ln -s ../mail_tt2/authorization_reject.tt2 authorization_reject.tt2)
