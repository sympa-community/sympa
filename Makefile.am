# Makefile.am - Top-level Makefile.am for Sympa
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

#SUBDIRS = src doc wwsympa nls

ChangeLog:
	@CVS2CL@

## User Id and Group for Sympa (your httpd should have the same uid.gid)
USER	=	@USER@
GROUP	=	@GROUP@

## configuration file
CONFDIR	=	@CONFDIR@

##  Perl path
PERL	=	@PERL@

## For preparing samples
HOST		=	`$(PERL) -MSys::Hostname -e "printf '%s', Sys::Hostname::hostname();"`
COOKIE		=	`$(PERL) -e " print int(rand ( time ))  "`
PERL_VERSION	=	`$(PERL) -e ' print $$]'`

SYMPA_VERSION	=	@VERSION@

## Root directory for Sympa ; use absolute path.
## Binaries are located under $DIR/bin ; this directory needs to be
## readable for everyone ; `queue' needs to be executable 
## You can also set DESTDIR to the place where everything should be
## installed (usefull for packagers of Sympa)
DIR	=	${prefix}

EXPL_DIR	=	@EXPLDIR@

## PID location
PIDDIR	=	@PIDDIR@

## Both queue and bouncequeue are lunched by sendmail. If sendmail
## is configured to used smrsh (check the mailer prog definition), thoses
## files needs to be installed in /etc/smrsh.  
MAILERPROGDIR	=	@BINDIR@

RPMTOPDIR	=	`rpm --eval %_topdir`
#RPMTOPDIR	=	/usr/src/redhat

MANDIR		=	@MANDIR@

## SYSV init scripts directory
INITDIR		=	@INITDIR@

BINDIR		=	@BINDIR@

SBINDIR		=	@SBINDIR@

CGIDIR		=	@CGIDIR@

LIBDIR		=	@LIBDIR@

LOCALEDIR	=	@LOCALEDIR@

DOCDIR		=	@DOCDIR@

ETCDIR		=	@ETCDIR@

SCRIPTDIR	=	@SCRIPTDIR@

SAMPLEDIR	=	@SAMPLEDIR@

## Spools directory
SPOOLDIR	=	@SPOOLDIR@

## Directory for installing WWSympa
WWSBINDIR	=	$(BINDIR)

## Web interface colors are now defined in sympa.conf

## Settings used in src/etc/scripts/sympa
PIDPRE		=	pidof -x
PIDPOST		=	
LOCKDIR		=	@LOCKDIR@

## Path to newaliases command (or what else may be called to rebuild
## Mail aliases database)
NEWALIASES	=	@NEWALIASES@

## Argument to newaliases command
# NEWALIASES_ARG	=	hash:/etc/mail/sympa_aliases
NEWALIASES_ARG	=	@NEWALIASES_ARG@

## Path to postmap command (or what else may be called to rebuild
## Mail virtual database)
POSTMAP		=	@POSTMAP@

## Argument to postmap command
# POSTMAP_ARG	=	hash:/etc/mail/sympa_virtual
POSTMAP_ARG	=	@POSTMAP_ARG@

## The sendmail aliases file we use. Better use a seperate one for sympa.
## Of course an extra alias file must be generated with proper permissions
## (owner sympa, write access for sympa, no write access for anyone else)
## and declared in sendmail.cf!
SENDMAIL_ALIASES=	@SENDMAIL_ALIASES@

## The postfix virtual file we use. Better use a seperate one for sympa.
## Of course an extra alias file must be generated with proper permissions
## (owner sympa, write access for sympa, no write access for anyone else)
## and declared in main.cf!
VIRTUAL_ALIASES=	@VIRTUAL_ALIASES@

## Path to OpenSSL
OPENSSL	=	@OPENSSL@
SSLCERTDIR =	$(EXPL_DIR)/X509-user-certs

CC	=	@CC@
CFLAGS	=	-g

# Aix4.2 (and some others unix), use gnu make !
#MAKE	=	@MAKE@

# FreeBSD hier(7) structure and locations
# by Autrijus Tang 2001/10/11
#ifeq ($(shell uname), FreeBSD)
#	PIDPRE	= 	ps -ax | grep
#	PIDPOST	= 	| grep perl | head -n 1 | cut -f 2 -d " "
#	LOCKDIR	= 	/var/spool/lock
#	RPMTOPDIR	=	/usr/local/src/redhat
#	OPENSSL	=	/usr/bin/openssl
#endif

##---------- STOP ---------- STOP ---------- STOP ---------- STOP ----------

CONFIG		=	$(CONFDIR)/sympa.conf
WWSCONFIG	=	$(CONFDIR)/wwsympa.conf
ETCBINDIR	=	@DATADIR@

main_SRC	=	AUTHORS COPYING ChangeLog INSTALL KNOWNBUGS NEWS README

#ifeq ($(shell uname), Linux)
#	LOG_SOCKET_TYPE="inet"
#else
LOG_SOCKET_TYPE	=	unix
#endif

all:	warning checkperl checkcpan sources wrapper soap_wrapper man locale

rpm: build_rh_rpm build_mdk_rpm

warning:
	@echo "######################## W A R N I N G ######################"; \
	echo "## If it is the first time you install Sympa on this server :"; \
	echo "##        It may take a while...."; \
	echo "## The reason is that Sympa requires many Perl modules that"; \
	echo "## are not distributed with the standard Perl distribution."; \
	echo "## We'll try to install these modules automatically..."; \
	echo "## If some modules cannot be installed automatically, (probably" ; \
	echo "## because of the 'make test'), try downloading them from the"; \
	echo "## CPAN website (http://search.cpan.org) and install them manually."; \
	echo "#############################################################"; \
	echo -n "Please hit <Enter> to proceed"; \
	if [ "$(DESTDIR)" = "" ]; then read rep; fi

checkperl:
	@if [ $(PERL_VERSION) = '5.006' ]; then \
	echo "##################################"; \
	echo "## You are using Perl version $(PERL_VERSION) :"; \
	echo "## You need to patch your syslog.pm "; \
	echo "## See http://bugs.perl.org/perlbug.cgi?req=bidmids&bidmids=20000712.003"; \
	echo "##"; \
	echo "## If your Perl version is 5.6.0 AND if your system is Solaris :"; \
	echo "## See also http://bugs.perl.org/perlbug.cgi?req=bidmids&bidmids=20000522.003"; \
	echo "#############################################################################"; \
	if [ "$(DESTDIR)" = "" ]; then read rep; fi \
	fi
	@if [ ! -f $(SUIDPERL) ]; then \
		echo "#################################################################################"; \
		echo "## wwsympa.fcgi that provides Sympa's web interface needs to run as user $(USER)"; \
		echo "## There are many options to do so : "; \
		echo "##  1/ Use the C wrapper provided with Sympa. this is the default behaviour."\
		echo "##  2/ Use 'sudo' to run wwsympa.fcgi as user $(USER). Your Apache configuration should use wwsympa_sudo_wrapper.pl"; \
		echo "##     You should edit your /etc/sudoers file (with visudo command) as follows :"; \
		echo "##     apache ALL = ($(USER))  NOPASSWD: $(CGIDIR)/wwsympa.fcgi"; \
		echo "##  3/ Use Apache's suExec mode."; \
		echo "#######################################################################################"; \
		echo -n "Please hit <Enter> to continue"; \
		if [ "$(DESTDIR)" = "" ]; then read rep; fi \
	fi
	@if [ ! -f $(MSGFMT) ]; then \
		echo "##################################"; \
		echo "## You don't have msgfmt installed. It is required to build message catalogues"; \
		echo "## msgfmt is provided with a 'gettext' package on most systems..."; \
		echo "#####################################################"; \
		if [ "$(DESTDIR)" = "" ]; then read rep; fi \
	fi


sources: src/Makefile src/queue.c src/bouncequeue.c src/aliaswrapper.c
	@echo "Making src"
	@(cd src && echo "making in src..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' WWSBINDIR='${WWSBINDIR}' \
	MAILERPROGDIR='${MAILERPROGDIR}' ETCBINDIR='${ETCBINDIR}' ETCDIR='${ETCDIR}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	USER='${USER}' GROUP='${GROUP}' \
	SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' \
	VIRTUAL_ALIASES='${VIRTUAL_ALIASES}' \
	NEWALIASES='${NEWALIASES}' NEWALIASES_ARG='${NEWALIASES_ARG}' \
	POSTMAP='${POSTMAP}' POSTMAP_ARG='${POSTMAP_ARG}' \
	PIDPRE='${PIDPRE}' PIDPOST='${PIDPOST}' LOCKDIR='${LOCKDIR}');

wrapper: src/Makefile src/queue.c src/bouncequeue.c src/aliaswrapper.c
	@echo "Making wwsympa"
	@(cd wwsympa && echo "making in wwsympa..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' WWSYMPA='${CGIDIR}/wwsympa.fcgi');

soap_wrapper: src/Makefile src/queue.c src/bouncequeue.c src/aliaswrapper.c
	@echo "Making sympa_soap"
	@(cd soap && echo "making in soap..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' SYMPASOAP='${CGIDIR}/sympa_soap_server.fcgi');

documentation: doc/sympa.tex.tpl doc/Makefile 
	@echo "Making documentation"
	@(cd doc && echo "making in doc/..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' CGIDIR='${CGIDIR}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' WWSBINDIR='${WWSBINDIR}' \
	MAILERPROGDIR='${MAILERPROGDIR}' ETCBINDIR='${ETCBINDIR}' ETCDIR='${ETCDIR}' PIDDIR='${PIDDIR}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' EXPL_DIR='${EXPL_DIR}' LOCALEDIR='${LOCALEDIR}' SPOOLDIR='${SPOOLDIR}' \
	SCRIPTDIR='${SCRIPTDIR}' \
	USER='${USER}' GROUP='${GROUP}');

man: doc/man8/Makefile
	@echo "Making man"
	@(cd doc/man8 && echo "making in doc/man8/..." && \
	$(MAKE) SYMPA_VERSION='$(SYMPA_VERSION)');

checkcpan: 
	@echo "Checking needed CPAN modules ..."
	$(PERL) ./check_perl_modules.pl

clean:
	find . \( -name ".#*" -o -name "*~" -o -name ".*~" -o -name "#*#" \) -exec  rm -f {} \;
	@for i in src wwsympa src/etc/sample;\
	do \
	(cd $$i && echo "making clean in $$i..." && \
	$(MAKE) PERL='${PERL}' clean) || exit 1; \
	done;

install: importantchanges installdir installsrc installwws installwebtt2 installmailtt2 installlocale installman installscript installsample installconfig installdoc installsoap nextstep

nextstep: 
	@echo ""
	@echo "** You can find documentation at:"
	@echo "** http://www.sympa.org/documentation/manual/sympa-$(SYMPA_VERSION).pdf"
	@echo ""
	@echo "#########################################################"
	@echo "# If you install Sympa for the first time on this server"
	@echo "# you should check the INSTALL file."
	@echo "#"
	@echo "# If you are upgrading, you now need to run"
	@echo "#    $(SBINDIR)/sympa.pl --upgrade"
	@echo "#######################################################"

importantchanges:
	@( 	PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		BINDIR=$(SBINDIR); export BINDIR; \
		SBINDIR=$(SBINDIR); export SBINDIR; \
		LIBDIR=$(LIBDIR); export LIBDIR; \
		ETCDIR=$(ETCDIR); export ETCDIR;\
		USER=$(USER); export USER;\
		GROUP=$(GROUP); export GROUP;\
		SYMPA_VERSION=$(SYMPA_VERSION); export SYMPA_VERSION; \
		$(PERL) ./important_changes.pl \
	) ;

locale:
	@(cd po && echo "making in po/...." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' LOCALEDIR='${LOCALEDIR}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	SCRIPTDIR='${SCRIPTDIR}' \
	USER='${USER}' GROUP='${GROUP}') || exit 1;

installlocale:
	@(cd po && echo "making install in po/...." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' LOCALEDIR='${LOCALEDIR}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	USER='${USER}' GROUP='${GROUP}' install) || exit 1;

updatelocale:
	@(cd po && echo "make update-po in po/...." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' LOCALEDIR='${LOCALEDIR}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	SCRIPTDIR='${SCRIPTDIR}' \
	USER='${USER}' GROUP='${GROUP}' update-po) || exit 1;

installsrc:
	@(cd src && echo "making in src..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' SYMPA_VERSION='${SYMPA_VERSION}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' WWSBINDIR='${WWSBINDIR}' \
	DESTDIR='${DESTDIR}' MAILERPROGDIR='${MAILERPROGDIR}' EXPL_DIR='${EXPL_DIR}' LIBEXECDIR='${LIBEXECDIR}' \
	PIDDIR='${PIDDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' LOCALEDIR='${LOCALEDIR}' SCRIPTDIR='${SCRIPTDIR}' \
	ETCBINDIR='${ETCBINDIR}' ETCDIR='${ETCDIR}' SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' \
	VIRTUAL_ALIASES='${VIRTUAL_ALIASES}'  HOST='${HOST}' COOKIE='${COOKIE}' \
	SPOOLDIR='${SPOOLDIR}' LOG_SOCKET_TYPE='${LOG_SOCKET_TYPE}' \
	SSLCERTDIR='${SSLCERTDIR}' OPENSSL='${OPENSSL}' \
	PODIR='${prefix}/po' \
	USER='${USER}' GROUP='${GROUP}' newinstall) || exit 1;

installdoc:
	@(cd doc && echo "make install in doc..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' DOCDIR='${DOCDIR}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' \
	VIRTUAL_ALIASES='${VIRTUAL_ALIASES}' \
	USER='${USER}' GROUP='${GROUP}' install) || exit 1;

installwws:
	@(cd wwsympa && echo "making in wwsympa..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' \
	USER='${USER}' GROUP='${GROUP}' SUDO='${SUDO}' \
	CGIDIR='${CGIDIR}' WWSBINDIR='${WWSBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	PIDDIR='${PIDDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' USER='${USER}' GROUP='${GROUP}' newinstall) || exit 1;

installwebtt2:
	@(cd web_tt2 && echo "making in web_tt2..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' \
	USER='${USER}' GROUP='${GROUP}' \
	CGIDIR='${CGIDIR}' WWSBINDIR='${WWSBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	PIDDIR='${PIDDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' USER='${USER}' GROUP='${GROUP}' newinstall) || exit 1;

installmailtt2:
	@(cd mail_tt2 && echo "making in mail_tt2..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' \
	USER='${USER}' GROUP='${GROUP}' \
	CGIDIR='${CGIDIR}' WWSBINDIR='${WWSBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	PIDDIR='${PIDDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' USER='${USER}' GROUP='${GROUP}' newinstall) || exit 1;

installsoap:
	@(cd soap && echo "making in soap/..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' \
	USER='${USER}' GROUP='${GROUP}' SCRIPTDIR='${SCRIPTDIR}' \
	CGIDIR='${CGIDIR}' WWSBINDIR='${WWSBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	PIDDIR='${PIDDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' USER='${USER}' GROUP='${GROUP}' newinstall) || exit 1;

installsample:
	@(cd src/etc/sample && echo "making in src/etc/sample..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' LOG_SOCKET_TYPE='${LOG_SOCKET_TYPE}' \
	DESTDIR='${DESTDIR}' DIR='${DIR}' SAMPLEDIR='${SAMPLEDIR}' \
	BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' \
	EXPL_DIR='${EXPL_DIR}' WWSBINDIR='${WWSBINDIR}' HOST='${HOST}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	COOKIE='${COOKIE}' OPENSSL='@OPENSSL@' SSLCERTDIR='${SSLCERTDIR}' \
	SPOOLDIR='${SPOOLDIR}' USER='${USER}' GROUP='${GROUP}' PIDDIR='${PIDDIR}' install) || exit 1;


installman:
	@(cd doc/man8 && \
	$(MAKE) PERL='${PERL}' DIR='${DIR}' DESTDIR='${DESTDIR}' SYMPA_VERSION='${SYMPA_VERSION}' MANDIR='${MANDIR}' \
	USER='${USER}' GROUP='${GROUP}' \
	CONFDIR='${CONFDIR}' SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' VIRTUAL_ALIASES='${VIRTUAL_ALIASES}' UMASK='${UMASK}'  \
	MAILERPROGDIR='${MAILERPROGDIR}' PIDDIR='${PIDDIR}' SPOOLDIR='${SPOOLDIR}' PIDDIR='${PIDDIR}' ETCBINDIR='${ETCBINDIR}' \
	newinstall) || exit 1;

installscript:
	@(cd src/etc/script && echo "making in src/etc/script..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' DESTDIR='${DESTDIR}' SCRIPTDIR='${SCRIPTDIR}' \
	BINDIR='${BINDIR}' SBINDIR='${SBINDIR}' LIBDIR='${LIBDIR}' \
	WWSBINDIR='${WWSBINDIR}' HOST='${HOST}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	MAILERPROGDIR='${MAILERPROGDIR}' PIDDIR='${PIDDIR}' \
	COOKIE='${COOKIE}' INITDIR='${INITDIR}' \
	PIDPRE='${PIDPRE}' PIDPOST='${PIDPOST}' LOCKDIR='${LOCKDIR}' \
	OPENSSL='@OPENSSL@' USER='${USER}' GROUP='${GROUP}' install) || exit 1;


installdir:
	@echo "Creating required directories"
	@for dir in $(DIR) $(EXPL_DIR) $(CONFDIR) $(SAMPLEDIR) $(ETCDIR) $(BINDIR) $(LOCALEDIR) $(DOCDIR) $(DIR)/static_content $(DIR)/static_content/icons ; do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			mkdir -p $(DESTDIR)$$dir; \
			chown $(USER) $(DESTDIR)$$dir; \
			chgrp $(GROUP) $(DESTDIR)$$dir; \
			chmod 755 $(DESTDIR)$$dir; \
		fi \
	done
	@if [ ! -f $(DESTDIR)$(CONFDIR)/sympa.conf ] ; then \
	echo "First installation : installing conf directories..."; \
	for dir in create_list_templates mail_tt2 web_tt2 scenari \
	task_models general_task_models; do \
		if [ ! -d $(DESTDIR)$(ETCDIR)/$$dir ] ; then \
			echo "Creating $(DESTDIR)$(ETCDIR)/$$dir"; \
			mkdir -p $(DESTDIR)$(ETCDIR)/$$dir; \
			chown $(USER) $(DESTDIR)$(ETCDIR)/$$dir; \
			chgrp $(GROUP) $(DESTDIR)$(ETCDIR)/$$dir; \
		fi \
	done; \
	( \
		PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		INSTALLDIR=$(ETCDIR); export INSTALLDIR; \
		USER=$(USER); export USER;\
		GROUP=$(GROUP); export GROUP;\
		INSTALLNAME='README'; export INSTALLNAME; \
                ETCDIR=$(ETCDIR); export ETCDIR; \
                ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		$(PERL) ./subst.pl src/etc/README_etc \
	) \
	fi
	@if [ ! -f $(DESTDIR)$(CONFDIR)/sympa.conf ] ; then \
	echo "First installation : installing spool directories..."; \
	for dir in $(SPOOLDIR) $(SPOOLDIR)/msg $(SPOOLDIR)/digest $(SPOOLDIR)/moderation \
	$(SPOOLDIR)/expire $(SPOOLDIR)/auth $(SPOOLDIR)/outgoing $(SPOOLDIR)/tmp \
	$(SPOOLDIR)/task ; do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			mkdir -p $(DESTDIR)$$dir; \
			chown $(USER) $(DESTDIR)$$dir; \
			chgrp $(GROUP) $(DESTDIR)$$dir; \
			chmod 770 $(DESTDIR)$$dir; \
		fi \
	done \
	fi
	@if [ ! -f $(DESTDIR)$(CONFDIR)/sympa.conf ] ; then \
	echo "First installation : creating archives and bounce directories..."; \
	for dir in bounce arc ; do \
		if [ ! -d $(DESTDIR)$(DIR)/$$dir ] ; then \
			echo "Creating $(DESTDIR)$(DIR)/$$dir"; \
			mkdir -p $(DESTDIR)$(DIR)/$$dir; \
			chown $(USER) $(DESTDIR)$(DIR)/$$dir; \
			chgrp $(GROUP) $(DESTDIR)$(DIR)/$$dir; \
		fi \
	done \
	fi


installconfig:
	mkdir -p $(DESTDIR)$(CONFDIR)
	@INITCONF='0'
	@for cfile in sympa.conf wwsympa.conf ; do \
	if [ ! -f $(DESTDIR)$(CONFDIR)/$$cfile ] ; then \
	echo "Installing sample config file $$cfile..."; \
	DESTDIR=$(DESTDIR); export DESTDIR; \
	$(PERL) -I $(DESTDIR)$(LIBDIR) $(DESTDIR)$(SBINDIR)/sympa_wizard.pl -c $$cfile; \
	chown $(USER) $(DESTDIR)$(CONFDIR)/$$cfile; \
	chgrp $(GROUP) $(DESTDIR)$(CONFDIR)/$$cfile; \
	if [ "$(DESTDIR)" = "" ]; then \
	INITCONF='1'; \
	fi \
	fi \
	done; \
	if [ "$$INITCONF" ] ; then \
	echo "###############################################"; \
	echo "It seems to be your first installation of Sympa"; \
	echo "The following wizard will help you create your $(CONFDIR)/sympa.conf and $(CONFDIR)/wwsympa.conf :"; \
	DESTDIR=$(DESTDIR); export DESTDIR; \
	$(PERL) -I $(DESTDIR)$(LIBDIR) $(DESTDIR)$(SBINDIR)/sympa_wizard.pl; \
	fi

build_rh_rpm: clean
	@echo "Building RedHat RPM in $(RPMTOPDIR) ..."
	@( \
		cd src/etc/script/ ; \
		PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		INSTALLDIR=$(RPMTOPDIR)/SPECS; export INSTALLDIR; \
		SUFFIX=''; export SUFFIX; \
		ZIPEXT='gz'; export ZIPEXT; \
		APPGROUP='System Environment/Daemons'; export APPGROUP; \
		MTA='smtpdaemon'; export MTA; \
		HOMEDIR='/var/sympa'; export HOMEDIR; \
		PIDDIR='/var/run/sympa'; export PIDDIR; \
		VERSION=$(SYMPA_VERSION); export VERSION; \
                CONFDIR='/etc'; export CONFDIR; \
                SENDMAIL_ALIASES='/etc/mail/sympa_aliases'; export SENDMAIL_ALIASES; \
                MAILERPROGDIR='/etc/smrsh'; export MAILERPROGDIR; \
		INITDIR='/etc/rc.d/init.d';  export INITDIR; \
                SPOOLDIR='/var/sympa/spool'; export SPOOLDIR; \
                BINDIR='/etc/smrsh'; export BINDIR; \
                SBINDIR='/var/sympa/sbin'; export SBINDIR; \
                DATADIR='/usr/share/sympa'; export DATADIR; \
                EXPLDIR='/var/sympa/expl'; export EXPLDIR; \
                LIBDIR='/usr/lib/sympa/bin'; export LIBDIR; \
                CGIDIR='/var/www/cgi-bin'; export CGIDIR; \
                LOCALEDIR='/usr/lib/sympa/locale'; export LOCALEDIR; \
		SCRIPTDIR='/var/sympa/bin'; export SCRIPTDIR; \
		LIBEXECDIR='/var/sympa/bin'; export LIBEXECDIR; \
		SAMPLEDIR='/usr/share/sympa/examples'; export SAMPLEDIR; \
                ETCDIR='/etc/sympa'; export ETCDIR; \
		$(PERL) ../../../subst.pl sympa.spec.rh80 \
	)
	mv $(RPMTOPDIR)/SPECS/sympa.spec.rh80 $(RPMTOPDIR)/SPECS/sympa.spec
	@( \
		cd ..; \
		tar -cvf $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar sympa-$(SYMPA_VERSION); \
		gzip $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar; \
	)
	rpmbuild  -ba $(RPMTOPDIR)/SPECS/sympa.spec

build_mdk_rpm: clean
	@echo "Building Mandrake RPM in $(RPMTOPDIR) ..."
	@( \
		cd src/etc/script/ ; \
		PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		INSTALLDIR=$(RPMTOPDIR)/SPECS; export INSTALLDIR; \
		SUFFIX='mdk'; export SUFFIX; \
		ZIPEXT='bz2'; export ZIPEXT; \
		APPGROUP='System/Servers'; export APPGROUP; \
		MTA='MailTransportAgent'; export MTA; \
		HOMEDIR='/var/lib/sympa'; export HOMEDIR; \
		VERSION=$(SYMPA_VERSION); export VERSION; \
                CONFDIR='/etc/sympa'; export CONFDIR; \
                SENDMAIL_ALIASES='/etc/mail/sympa_aliases'; export SENDMAIL_ALIASES; \
                MAILERPROGDIR='/usr/lib/sympa/bin'; export MAILERPROGDIR; \
                PIDDIR='/var/run/sympa'; export PIDDIR; \
		INITDIR='/etc/rc.d/init.d';  export INITDIR; \
                SPOOLDIR='/var/spool/sympa'; export SPOOLDIR; \
                BINDIR='/usr/lib/sympa/bin'; export BINDIR; \
                SBINDIR='/usr/lib/sympa/bin'; export SBINDIR; \
                DATADIR='/usr/share/sympa'; export DATADIR; \
                EXPLDIR='/var/lib/sympa/expl'; export EXPLDIR; \
                LIBDIR='/usr/lib/sympa/bin'; export LIBDIR; \
                CGIDIR='/var/www/cgi-bin'; export CGIDIR; \
                LOCALEDIR='/usr/lib/sympa/locale'; export LOCALEDIR; \
		SCRIPTDIR='/usr/lib/sympa/bin'; export SCRIPTDIR; \
		LIBEXECDIR='/usr/lib/sympa/bin'; export LIBEXECDIR; \
		SAMPLEDIR='/usr/share/sympa/examples'; export SAMPLEDIR; \
                ETCDIR='/etc/sympa'; export ETCDIR; \
		$(PERL) ../../../subst.pl sympa.spec \
	)
	@( \
		cd ..; \
		tar -cvf $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar sympa-$(SYMPA_VERSION); \
		bzip2 $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar; \
	)
	rpmbuild -ba $(RPMTOPDIR)/SPECS/sympa.spec

tag:	ChangeLog
	@if [ ! $(NEW_VERSION) ]; then \
	echo "Current version is $(VERSION)"; \
	echo "You need to define NEW_VERSION"; \
	else echo $(NEW_VERSION) > .version; cvs ci -m 'preparing $(NEW_VERSION)' .version ChangeLog; cvs tag -F `echo sympa-$(NEW_VERSION)|sed 's/\./_/g'`; \
	fi
