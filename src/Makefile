# Makefile - This Makefile builds and installs Sympa sources
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

CDEFS	=	-DCONFIG=\"$(CONFIG)\"

sbin_SRC	=	sympa.pl alias_manager.pl task_manager.pl sympa_wizard.pl

bin_SRC		=	queue bouncequeue

lib_SRC		=	Archive.pm Commands.pm Conf.pm \
			Language.pm List.pm Log.pm mail.pm msg.pl Ldap.pm \
			smtp.pm tools.pl Version.pm parser.pl X509.pm Message.pm

libexec_SRC	=	aliaswrapper virtualwrapper

all:	queue bouncequeue aliaswrapper virtualwrapper

clean:
	@if [ -f ./queue ]; then \
		rm queue ; \
	fi	
	@if [ -f ./bouncequeue ]; then \
		rm bouncequeue ; \
	fi
	@if [ -f ./aliaswrapper ]; then \
		rm aliaswrapper ; \
	fi
	@if [ -f ./virtualwrapper ]; then \
		rm virtualwrapper ; \
	fi

install: 
	echo "Please use the main Makefile for installing sources."

newinstall: makedir subst $(sbin_SRC) $(lib_SRC) installqueue installwrapper installscenari installtask_models installtemplates installetc installlisttemplates installmod installgeneral_task_models info


installtemplates:
	@echo "Deleting current templates..."
	rm -f $(DESTDIR)$(ETCBINDIR)/templates/*.tpl
	@echo "Installing default templates..."
	@for lang in etc/templates/* ; do \
		echo $$lang; \
		cp $$lang/*.tpl  $(DESTDIR)$(ETCBINDIR)/templates/; \
	done
	$(PERL) ../set_symlinks.pl templates $(DESTDIR)$(ETCBINDIR)/templates

installtask_models:
	@echo "Installing default task models ..."
	cp -pR etc/list_task_models/* $(DESTDIR)$(ETCBINDIR)/list_task_models

installgeneral_task_models:
	@echo "Installing general task models ..."
	cp -pR etc/global_task_models/* $(DESTDIR)$(ETCBINDIR)/global_task_models

installetc:
	@echo "Installing default configuration ..."
	cp etc/*.conf etc/*.crt $(DESTDIR)$(ETCBINDIR)/
	@( \
		UMASK=0664; export UMASK;\
		INSTALLDIR=$(ETCBINDIR); export INSTALLDIR;\
		DESTDIR=$(DESTDIR); export DESTDIR;\
		DARK_COLOR=$(DARK_COLOR); export DARK_COLOR;\
		LIGHT_COLOR=$(LIGHT_COLOR); export LIGHT_COLOR;\
		BG_COLOR=$(BG_COLOR); export BG_COLOR;\
		TEXT_COLOR=$(TEXT_COLOR); export TEXT_COLOR;\
		ERROR_COLOR=$(ERROR_COLOR); export ERROR_COLOR;\
		SHADED_COLOR=$(SHADED_COLOR); export SHADED_COLOR;\
		cd etc;\
		$(PERL) ../../subst.pl mhonarc-ressources README \
	)
	@( \
		UMASK=0664; export UMASK;\
		INSTALLDIR=$(ETCBINDIR); export INSTALLDIR;\
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR;\
		cd etc;\
		$(PERL) ../../subst.pl list_aliases.tpl \
	)

installlisttemplates:
	@echo "Installing default list templates ..."
	cp -pR etc/create_list_templates/* $(DESTDIR)$(ETCBINDIR)/create_list_templates

installscenari:
	@echo "Installing default scenari..."
	cp etc/scenari/*.* $(DESTDIR)$(ETCBINDIR)/scenari
	$(PERL) ../set_symlinks.pl scenari $(DESTDIR)$(ETCBINDIR)/scenari

installqueue:
	@echo "Installing Queue binary..."
	cp queue $(DESTDIR)$(MAILERPROGDIR)/
	@echo "Installing BounceQueue binary..."
	cp bouncequeue $(DESTDIR)$(MAILERPROGDIR)/

installwrapper:
	@echo "Installing AliasWrapper binary..."
	cp aliaswrapper $(DESTDIR)$(LIBEXECDIR)/
	@echo "Installing VirtualWrapper binary..."
	cp virtualwrapper $(DESTDIR)$(LIBEXECDIR)/

makedir:
	@if [ ! -d $(DESTDIR)$(MAILERPROGDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(MAILERPROGDIR)"; \
		mkdir -p $(DESTDIR)$(MAILERPROGDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(LIBEXECDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(LIBEXECDIR)"; \
		mkdir -p $(DESTDIR)$(LIBEXECDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(BINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(BINDIR)"; \
		mkdir -p $(DESTDIR)$(BINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(SBINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(SBINDIR)"; \
		mkdir -p $(DESTDIR)$(SBINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(LIBDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(LIBDIR)"; \
		mkdir -p $(DESTDIR)$(LIBDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/etc"; \
		mkdir -p $(DESTDIR)$(ETCBINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/scenari ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/scenari"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/scenari; \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/create_list_templates ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/create_list_templates"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/create_list_templates; \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/templates ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/templates"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/templates; \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/list_task_models ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/list_task_models"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/list_task_models; \
	fi
	@if [ ! -d $(DESTDIR)$(ETCBINDIR)/global_task_models ]; then \
		echo "Creating required directory $(DESTDIR)$(ETCBINDIR)/global_task_models"; \
		mkdir $(DESTDIR)$(ETCBINDIR)/global_task_models; \
	fi

installmod:
	@echo "Setting group and owner for $(DESTDIR)$(SBINDIR)..."
	@for file in $(sbin_SRC) ; do \
		chown $(USER) $(DESTDIR)$(SBINDIR)/$$file; \
		chgrp $(GROUP) $(DESTDIR)$(SBINDIR)/$$file; \
	done
	@echo "Setting group and owner for $(DESTDIR)$(LIBDIR)..."
	@for file in $(lib_SRC) ; do \
		chown $(USER) $(DESTDIR)$(LIBDIR)/$$file; \
		chgrp $(GROUP) $(DESTDIR)$(LIBDIR)/$$file; \
	done
	chown -R $(USER) $(DESTDIR)$(ETCBINDIR)
	chgrp -R $(GROUP) $(DESTDIR)$(ETCBINDIR)
	chown root $(DESTDIR)$(LIBEXECDIR)/aliaswrapper
	chgrp $(GROUP) $(DESTDIR)$(LIBEXECDIR)/aliaswrapper
	chown root $(DESTDIR)$(LIBEXECDIR)/virtualwrapper
	chgrp $(GROUP) $(DESTDIR)$(LIBEXECDIR)/virtualwrapper
	@echo "Setting privileges..."
	chmod 755 $(DESTDIR)$(SBINDIR) $(DESTDIR)$(ETCBINDIR) 
	chmod 755 $(DESTDIR)$(ETCBINDIR)/scenari $(DESTDIR)$(ETCBINDIR)/templates $(DESTDIR)$(ETCBINDIR)/list_task_models $(DESTDIR)$(ETCBINDIR)/global_task_models
	chmod 755 $(DESTDIR)$(ETCBINDIR)/create_list_templates
	chmod 644 $(DESTDIR)$(ETCBINDIR)/*.conf $(DESTDIR)$(ETCBINDIR)/*.crt 
	chmod 600 $(DESTDIR)$(ETCBINDIR)/ca-bundle.crt
	@for file in $(bin_SRC) ; do \
		chown $(USER) $(DESTDIR)$(MAILERPROGDIR)/$$file; \
		chgrp $(GROUP) $(DESTDIR)$(MAILERPROGDIR)/$$file; \
		chmod 4755 $(DESTDIR)$(MAILERPROGDIR)/$$file; \
	done
	@for file in $(libexec_SRC) ; do \
		chown $(USER) $(DESTDIR)$(LIBEXECDIR)/$$file; \
		chgrp $(GROUP) $(DESTDIR)$(LIBEXECDIR)/$$file; \
		chmod 4750 $(DESTDIR)$(LIBEXECDIR)/$$file; \
	done

queue: queue.c Makefile ../Makefile
	$(CC) $(CFLAGS) $(CDEFS) -o queue queue.c

bouncequeue: bouncequeue.c Makefile ../Makefile
	$(CC) $(CFLAGS) $(CDEFS) -o bouncequeue bouncequeue.c

aliaswrapper: aliaswrapper.c Makefile ../Makefile
	$(CC) $(CFLAGS) $(CDEFS) -DNEWALIASES=\"${NEWALIASES}\" \
		-DNEWALIASES_ARG=\"${NEWALIASES_ARG}\" -o aliaswrapper aliaswrapper.c

virtualwrapper: virtualwrapper.c Makefile ../Makefile
	$(CC) $(CFLAGS) $(CDEFS) -DPOSTMAP=\"${POSTMAP}\" \
		-DPOSTMAP_ARG=\"${POSTMAP_ARG}\" -o virtualwrapper virtualwrapper.c

subst:
	@echo "Doing multiple substitutions while installing binaries..."
	@( \
		PERL=$(PERL); export PERL;\
		UMASK=0755; export UMASK;\
		HOST=$(HOST); export HOST;\
		DIR=$(DIR); export DIR;\
		DESTDIR=$(DESTDIR); export DESTDIR;\
		PIDDIR=$(PIDDIR); export PIDDIR;\
		INSTALLDIR=$(SBINDIR); export INSTALLDIR;\
		SBINDIR=$(SBINDIR); export SBINDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR;\
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR;\
		CONFIG=$(CONFIG); export CONFIG;\
		SYMPA_VERSION=$(SYMPA_VERSION); export SYMPA_VERSION;\
		SENDMAIL_ALIASES=$(SENDMAIL_ALIASES); export SENDMAIL_ALIASES;\
		VIRTUAL_ALIASES=$(VIRTUAL_ALIASES); export VIRTUAL_ALIASES;\
		SPOOLDIR=$(SPOOLDIR); export SPOOLDIR;\
		COOKIE=$(COOKIE); export COOKIE;\
		$(PERL) ../subst.pl $(sbin_SRC) \
	)
	@echo "Doing multiple substitutions while installing libraries ..."
	@( \
		PERL=$(PERL); export PERL;\
		UMASK=0644; export UMASK;\
		DIR=$(DIR); export DIR;\
		DESTDIR=$(DESTDIR); export DESTDIR;\
		PIDDIR=$(PIDDIR); export PIDDIR;\
		INSTALLDIR=$(LIBDIR); export INSTALLDIR;\
		SBINDIR=$(SBINDIR); export SBINDIR;\
		LIBDIR=$(LIBDIR); export LIBDIR;\
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR;\
		CONFIG=$(CONFIG); export CONFIG;\
		SYMPA_VERSION=$(SYMPA_VERSION); export SYMPA_VERSION;\
		SENDMAIL_ALIASES=$(SENDMAIL_ALIASES); export SENDMAIL_ALIASES;\
		VIRTUAL_ALIASES=$(VIRTUAL_ALIASES); export VIRTUAL_ALIASES;\
		$(PERL) ../subst.pl $(lib_SRC) \
	)

## Dépendances
queue:		queue.c Makefile

bouncequeue:	bouncequeue.c Makefile

info:
	@echo ""
	@echo "If you wish, you can contact the authors sympa-users-request@cru.fr"
	@echo "Thanks to provide release number, operating system and langage used."
	@echo ""








