# Makefile - This Makefile does the web interface of Sympa installation
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

sbin_SUBST	=	bounced.pl archived.pl

cgi_SUBST	=	wwsympa.fcgi

lib_SUBST	=	wwslib.pm cookielib.pm bounce-lib.pl Marc.pm

SRC		=	mime.types 

default: none

clean: 
	rm -rf $(DESTDIR)$(SBINDIR)

install: 
	echo "Please use the main Makefile for installing WWSympa."

newinstall: makedir $(sbin_SUBST) $(cgi_SUBST) $(lib_SUBST) substcgi substsbin substlib installtemplates installicons installsrc installmod

installmod:
	@for i in $(SRC) ; do \
	chown $(USER) $(DESTDIR)$(ETCBINDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(ETCBINDIR)/$$i; \
	done
	@for i in $(sbin_SUBST) ; do \
	chown $(USER) $(DESTDIR)$(SBINDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(SBINDIR)/$$i; \
	done
	@for i in $(cgi_SUBST) ; do \
	chown $(USER) $(DESTDIR)$(CGIDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(CGIDIR)/$$i; \
	done
	@echo "Setting SetUID bit on wwsympa.fcgi..."
	chmod u+s $(DESTDIR)$(CGIDIR)/wwsympa.fcgi
	chmod g+s $(DESTDIR)$(CGIDIR)/wwsympa.fcgi
	chmod 755 $(DESTDIR)$(ETCBINDIR)/wws_templates
	chmod 755 $(DESTDIR)$(ICONSDIR)
	chmod 755 $(DESTDIR)$(LIBDIR)/Marc
	@for i in $(lib_SUBST) Marc/Search.pm; do \
	chown $(USER) $(DESTDIR)$(LIBDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(LIBDIR)/$$i; \
	chmod 644 $(DESTDIR)$(LIBDIR)/$$i; \
	done

makedir:
	@if [ ! -d $(DESTDIR)$(SBINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(SBINDIR)"; \
		mkdir -p $(DESTDIR)$(SBINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(CGIDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(CGIDIR)"; \
		mkdir -p $(DESTDIR)$(CGIDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(LIBDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(LIBDIR)"; \
		mkdir -p $(DESTDIR)$(LIBDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)"; \
		mkdir -p $(DESTDIR)$(ETCBINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/wws_templates ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/wws_templates"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/wws_templates; \
	fi
	@if [ ! -d $(DESTDIR)$(ICONSDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(ICONSDIR)"; \
		mkdir -p $(DESTDIR)$(ICONSDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(LIBDIR)/Marc ]; then \
		echo "Creating required directory $(DESTDIR)$(LIBDIR)/Marc"; \
		mkdir $(DESTDIR)$(LIBDIR)/Marc; \
	fi

installsrc:
	@echo
	@echo "Installing sources..."
	cp $(SRC) $(DESTDIR)$(ETCBINDIR)
	cp Marc/Search.pm $(DESTDIR)$(LIBDIR)/Marc

installtemplates:
	@echo
	@echo "Installing templates..."
	@for lang in wws_templates/* ; do \
		echo $$lang; \
		( \
		cd $$lang; \
		PERL=$(PERL); export PERL; \
		INSTALLDIR=$(ETCBINDIR)/wws_templates; export INSTALLDIR; \
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
		$(PERL) ../../../subst.pl *.tpl; \
		); \
	done
	$(PERL) ../set_symlinks.pl wws_templates $(DESTDIR)$(ETCBINDIR)/wws_templates
	chmod -R 644 $(DESTDIR)$(ETCBINDIR)/wws_templates

installicons:
	@echo "Installing icons..."
	cp icons/*.png $(DESTDIR)$(ICONSDIR)

substlib:
	@echo "Doing multiple substitutions while installing librairies..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0644; export UMASK; \
		INSTALLDIR=$(LIBDIR); export INSTALLDIR; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		CGIDIR=$(CGIDIR); export CGIDIR; \
		PIDDIR=$(PIDDIR); export PIDDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
		ICONSDIR=$(ICONSDIR); export ICONSDIR; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		CONFIG=$(CONFIG); export CONFIG; \
		$(PERL) ../subst.pl $(lib_SUBST) \
	)

substsbin:
	@echo "Doing multiple substitutions while installing binaries..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0755; export UMASK; \
		INSTALLDIR=$(SBINDIR); export INSTALLDIR; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		CGIDIR=$(CGIDIR); export CGIDIR; \
		PIDDIR=$(PIDDIR); export PIDDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
		ICONSDIR=$(ICONSDIR); export ICONSDIR; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		CONFIG=$(CONFIG); export CONFIG; \
		$(PERL) ../subst.pl $(sbin_SUBST) \
	)

substcgi:
	@echo "Doing multiple substitutions while installing CGIs..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0755; export UMASK; \
		INSTALLDIR=$(CGIDIR); export INSTALLDIR; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		CGIDIR=$(CGIDIR); export CGIDIR; \
		PIDDIR=$(PIDDIR); export PIDDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
		ICONSDIR=$(ICONSDIR); export ICONSDIR; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		CONFIG=$(CONFIG); export CONFIG; \
		$(PERL) ../subst.pl $(cgi_SUBST) \
	)

