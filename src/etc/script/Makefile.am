# Makefile - This Makefile does the Sympa scripts installation
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

SRC	=	create_db.Pg create_db.mysql create_db.Oracle create_db.Sybase create_db.SQLite 

SUBSTSRC	=	arc2webarc.pl testldap.pl p12topem.pl init_comment.pl crypt_passwd.pl testlogs.pl mod2html.pl tpl2tt2.pl ldap_alias_manager.pl mysql_alias_manager.pl

INITSRC		=	sympa

#SCRIPTDIR	=	../../../script
SCRIPTDIR	=	$(SBINDIR)

all:	

install: makedir installsrc installsubstsrc installinit

clean:
	rm -rf $(DESTDIR)$(SCRIPTDIR)

makedir:
	@if [ ! -d $(DESTDIR)$(SCRIPTDIR) ]; then \
		mkdir -p $(DESTDIR)$(SCRIPTDIR); \
	fi

installsubstsrc:
	@echo "Doing multiple substitutions while installing ..."
	@( \
		PERL=$(PERL); export PERL; \
		SH=$(SH); export SH; \
		USER=$(USER); export USER; \
		UMASK=0755; export UMASK; \
		DIR=$(DIR); export DIR; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		INITDIR=$(INITDIR); export INITDIR; \
		INSTALLDIR=$(SCRIPTDIR); export INSTALLDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		CONFIG=$(CONFIG); export CONFIG; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		COOKIE=$(COOKIE); export COOKIE; \
		HOST=$(HOST); export HOST; \
		OPENSSL=$(OPENSSL); export OPENSSL; \
		PIDPRE='$(PIDPRE)'; export PIDPRE; \
		PIDPOST='$(PIDPOST)'; export PIDPOST; \
		LOCKDIR=$(LOCKDIR); export LOCKDIR; \
		$(PERL) ../../../subst.pl $(SUBSTSRC) \
	)

installsrc:
	@for c in $(SRC); do \
	cp $$c $(DESTDIR)$(SCRIPTDIR); \
	done


installinit:
	mkdir -p $(DESTDIR)$(INITDIR)
	@echo "Installing SYSV init script in $(DESTDIR)$(INITDIR)..."
	@( \
		PERL=$(PERL); export PERL; \
		SH=$(SH); export SH; \
		USER=$(USER); export USER; \
		UMASK=0755; export UMASK; \
		DIR=$(DIR); export DIR; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		INITDIR=$(INITDIR); export INITDIR; \
		INSTALLDIR=$(INITDIR); export INSTALLDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		PIDDIR=$(PIDDIR); export PIDDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		CONFIG=$(CONFIG); export CONFIG; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		COOKIE=$(COOKIE); export COOKIE; \
		HOST=$(HOST); export HOST; \
		$(PERL) ../../../subst.pl $(INITSRC) \
	)



