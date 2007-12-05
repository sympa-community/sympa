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

cgi_SUBST	=	sympa_soap_server.fcgi 

cgi_SRC		= 	sympa_soap_server-wrapper.fcgi

script_SUBST	=	sympa_soap_client.pl

lib_SUBST	=	sympasoap.pm SympaTransport.pm

SRC		=	sympa.wsdl

all:	sympa_soap_server-wrapper.fcgi

clean: 
	rm -rf $(DESTDIR)$(SBINDIR)
	@if [ -f ./sympa_soap_server-wrapper.fcgi ]; then \
		rm -f sympa_soap_server-wrapper.fcgi ; \
	fi

install: 
	echo "Please use the main Makefile for installing soapSympa."

newinstall: makedir $(cgi_SUBST) $(lib_SUBST) substcgi substlib substscript installsrc installwrapper installmod

installmod:
	@for i in $(SRC) ; do \
	chown $(USER) $(DESTDIR)$(ETCBINDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(ETCBINDIR)/$$i; \
	done
	@for i in $(script_SUBST) ; do \
	chown $(USER) $(DESTDIR)$(SCRIPTDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(SCRIPTDIR)/$$i; \
	chmod a+x $(DESTDIR)$(SCRIPTDIR)/$$i; \
	done
	@for i in $(cgi_SUBST) ; do \
	chown $(USER) $(DESTDIR)$(CGIDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(CGIDIR)/$$i; \
	done
	@for i in $(cgi_SRC) ; do \
	chown $(USER) $(DESTDIR)$(CGIDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(CGIDIR)/$$i; \
	done
	@echo "Setting SetUID bit on sympa_soap_server-wrapper.fcgi..."
	chmod u+s $(DESTDIR)$(CGIDIR)/sympa_soap_server-wrapper.fcgi
	chmod g+s $(DESTDIR)$(CGIDIR)/sympa_soap_server-wrapper.fcgi
	@for i in $(lib_SUBST) ; do \
	chown $(USER) $(DESTDIR)$(LIBDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(LIBDIR)/$$i; \
	chmod 644 $(DESTDIR)$(LIBDIR)/$$i; \
	done

makedir:
	@if [ ! -d $(DESTDIR)$(CGIDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(CGIDIR)"; \
		mkdir -p $(DESTDIR)$(CGIDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(SCRIPTDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(SCRIPTDIR)"; \
		mkdir -p $(DESTDIR)$(SCRIPTDIR); \
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

installwrapper:
	@echo "Installing sympa_soap_server-wrapper binary..."
	cp sympa_soap_server-wrapper.fcgi $(DESTDIR)$(CGIDIR)/

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

substscript:
	@echo "Doing multiple substitutions while installing scripts..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0644; export UMASK; \
		INSTALLDIR=$(SCRIPTDIR); export INSTALLDIR; \
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
		$(PERL) ../subst.pl $(script_SUBST) \
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

sympa_soap_server-wrapper.fcgi: sympa_soap_server-wrapper.fcgi.c Makefile ../Makefile
	$(CC) $(CFLAGS) -DSYMPASOAP=\"$(SYMPASOAP)\" -o sympa_soap_server-wrapper.fcgi sympa_soap_server-wrapper.fcgi.c
