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

cgi_SUBST	=	wwsympa.fcgi wwsympa_sudo_wrapper.pl

cgi_SRC		=	wwsympa-wrapper.fcgi

lib_SUBST	=	wwslib.pm cookielib.pm bounce-lib.pl Marc.pm Auth.pm SharedDocument.pm SympaSession.pm

SRC		=	mime.types 

all:	wwsympa-wrapper.fcgi

clean: 
	rm -rf $(DESTDIR)$(SBINDIR)
	@if [ -f ./wwsympa-wrapper.fcgi ]; then \
		rm -f wwsympa-wrapper.fcgi ; \
	fi


install: 
	echo "Please use the main Makefile for installing WWSympa."

newinstall: makedir $(sbin_SUBST) $(cgi_SUBST) $(cgi_SRC) $(lib_SUBST) substcgi substsbin substlib installicons installsrc installwrapper installmod

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
	@for i in $(cgi_SRC) ; do \
	chown $(USER) $(DESTDIR)$(CGIDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(CGIDIR)/$$i; \
	done
	echo "Setting SetUID bit on wwsympa-wrapper.fcgi..."; \
	chmod u+s $(DESTDIR)$(CGIDIR)/wwsympa-wrapper.fcgi; \
	chmod g+s $(DESTDIR)$(CGIDIR)/wwsympa-wrapper.fcgi; \
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
	@if [ ! -d $(DESTDIR)$(LIBDIR)/Marc ]; then \
		echo "Creating required directory $(DESTDIR)$(LIBDIR)/Marc"; \
		mkdir $(DESTDIR)$(LIBDIR)/Marc; \
	fi

installsrc:
	@echo
	@echo "Installing sources..."
	cp $(SRC) $(DESTDIR)$(ETCBINDIR)
	cp Marc/Search.pm $(DESTDIR)$(LIBDIR)/Marc

installicons:
	@echo "Installing icons..."
	@echo $(DESTDIR)/static_content/icons
	cp icons/*.png $(DESTDIR)/static_content/icons

installwrapper:
	@echo "Installing wwsympa-wrapper binary..."
	cp wwsympa-wrapper.fcgi $(DESTDIR)$(CGIDIR)/

substlib:
	@echo "Doing multiple substitutions while installing librairies..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0644; export UMASK; \
		INSTALLDIR=$(LIBDIR); export INSTALLDIR; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		CGIDIR=$(CGIDIR); export CGIDIR; \
		USER=$(USER); export USER; \
		GROUP=$(GROUP); export GROUP; \
		PIDDIR=$(PIDDIR); export PIDDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
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
		USER=$(USER); export USER; \
		GROUP=$(GROUP); export GROUP; \
		PIDDIR=$(PIDDIR); export PIDDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
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
		USER=$(USER); export USER; \
		SUDO=$(SUDO); export SUDO; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		CGIDIR=$(CGIDIR); export CGIDIR; \
		PIDDIR=$(PIDDIR); export PIDDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		CONFIG=$(CONFIG); export CONFIG; \
		PERLOPT="-U"; export PERLOPT; \
		$(PERL) ../subst.pl $(cgi_SUBST) \
	)

wwsympa-wrapper.fcgi: wwsympa-wrapper.fcgi.c Makefile ../Makefile
	$(CC) $(CFLAGS) -DWWSYMPA=\"$(WWSYMPA)\" -o wwsympa-wrapper.fcgi wwsympa-wrapper.fcgi.c
