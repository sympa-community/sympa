# Makefile - This Makefile does Sympa samples installation
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

SRC	=	README trusted_applications.conf

SUBSTSRC	=	robot.conf *.ldap

SAMPLEDIR	=	$(DIR)/sample

all:	

install: makedir installsrc installsubstsrc installsamplelist

clean:
	rm -rf $(DESTDIR)$(SAMPLEDIR)

makedir:
	@if [ ! -d $(DESTDIR)$(SAMPLEDIR) ]; then \
		mkdir -p $(DESTDIR)$(SAMPLEDIR); \
	fi

installsubstsrc:
	@echo "Doing multiple substitutions while installing ..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		DIR=$(DIR); export DIR; \
		PIDDIR=$(PIDDIR); export PIDDIR; \
		SPOOLDIR=$(SPOOLDIR); export SPOOLDIR; \
		INSTALLDIR=$(SAMPLEDIR); export INSTALLDIR; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		CONFIG=$(CONFIG); export CONFIG; \
		LOG_SOCKET_TYPE=$(LOG_SOCKET_TYPE); export LOG_SOCKET_TYPE; \
		COOKIE=$(COOKIE); export COOKIE; \
		OPENSSL=$(OPENSSL); export OPENSSL ; \
		SSLCERTDIR=$(SSLCERTDIR); export SSLCERTDIR ; \
		HOST=$(HOST); export HOST; \
		$(PERL) ../../../subst.pl $(SUBSTSRC) \
	)


installsrc:
	@for c in $(SRC); do \
	cp $$c $(DESTDIR)$(SAMPLEDIR); \
	done

installsamplelist:
	@if [ ! -d $(DESTDIR)$(SAMPLEDIR)/sample-list ]; then \
		echo "Installing sample list ..."; \
		mkdir -p $(DESTDIR)$(SAMPLEDIR)/sample-list; \
		cd test; \
		for f in * ; do \
			cp $$f $(DESTDIR)$(SAMPLEDIR)/sample-list/; \
			chown $(USER) $(DESTDIR)$(SAMPLEDIR)/sample-list/$$f; \
			chgrp $(GROUP) $(DESTDIR)$(SAMPLEDIR)/sample-list/$$f; \
		done; \
		cd ..; \
	fi




