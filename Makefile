## User Id and Group for Sympa (your httpd should have the same uid.gid)
USER	=	sympa
GROUP	=	sympa

## configuration file
CONFDIR	=	/etc

##  Perl path
PERL	=	/usr/bin/perl

## For preparing samples
HOST		=	`$(PERL) -MSys::Hostname -e "printf '%s', Sys::Hostname::hostname();"`
COOKIE		=	`$(PERL) -e " print int(rand ( time ))  "`
PERL_VERSION	=	`$(PERL) -e ' print $$]'`

SYMPA_VERSION	=	'3.1.1'

#SYMPA_VERSION	=	`pwd | $(PERL) -e 'my @version = split /-/, <STDIN>; printf "%s", $$version[1];'`

## Root directory for Sympa ; use absolute path.
## Binaries are located under $DIR/bin ; this directory needs to be
## readable for everyone ; `queue' needs to be executable 
## You can also set DESTDIR to the place where everything should be
## installed (usefull for packagers of Sympa)
DIR	=	/home/sympa

## PID location
PIDDIR	=	/home/sympa

## Both queue and bouncequeue are lunched by sendmail. If sendmail
## is configured to used smrsh (check the mailer prog definition), thoses
## files needs to be installed in /etc/smrsh.  
MAILERPROGDIR	=	$(DIR)/bin

#RPMTOPDIR	=	`rpm --eval %_topdir`
RPMTOPDIR	=	/usr/src/redhat

MANDIR		=	/usr/local/man

## SYSV init scripts directory
INITDIR		=	$(DIR)/bin

BINDIR		=	$(DIR)/bin

## Spools directory
SPOOLDIR	=	$(DIR)/spool

## Directory for installing WWSympa
WWSBINDIR	=	$(BINDIR)

# Chose your prefered color.
#
DARK_COLOR	=	'\#330099'
LIGHT_COLOR	=	'\#ccccff'
TEXT_COLOR	=	'\#000000' 
BG_COLOR	=	'\#ffffff'
ERROR_COLOR	=	'\#ff6666'
SELECTED_COLOR	=	'\#3366cc'
SHADED_COLOR	=	'\#eeeeee'

## Target directory for installing Icons
ICONSDIR	=	/home/httpd/icons

## Path to newaliases command (or what else may be called to rebuild
## Mail aliases database)
NEWALIASES    =       /usr/bin/newaliases

## The sendmail aliases file we use. Better use a seperate one for sympa.
## Of cause a extra alias file must be generated with proper permissions
## (owner sympa, write access for sympa, no write access for anyone else)
## and declared in sendmail.cf!
SENDMAIL_ALIASES=     /etc/mail/sympa_aliases

## Path to gencat program (creates the .cat catalog file using the .msg)
GENCAT	= 	/usr/bin/gencat

## Path to OpenSSL
OPENSSL	=	/usr/local/ssl/bin/openssl
SSLCERTDIR =	--DIR--/expl/X509-user-certs

SH	=	/bin/sh
CC	=	gcc
CFLAGS	=	-g

# Aix4.2 (and some others unix), use gnu make !
MAKE	=	make

##---------- STOP ---------- STOP ---------- STOP ---------- STOP ----------

CONFIG		=	$(CONFDIR)/sympa.conf
WWSCONFIG	=	$(CONFDIR)/wwsympa.conf
ETCBINDIR	=	$(BINDIR)/etc
NLSDIR		=	$(DIR)/nls

#ifeq ($(shell uname), Linux)
#	LOG_SOCKET_TYPE="inet"
#else
LOG_SOCKET_TYPE	=	"unix"
#endif

all:	checkcpan sources languages checkperl man

rpm: build_rh_rpm build_mdk_rpm

checkperl:
	@echo "#######################################"
	@echo "## Database structure has been extended"
	@echo "## You need to run the following command on your database :"
	@echo "## ALTER TABLE subscriber_table ADD comment_subscriber varchar (150);"
	@echo "## ";
	@echo "## Then run $(BINDIR)/init_comment.pl"
	@if [ $(PERL_VERSION) = '5.006' ]; then \
	echo "##################################"; \
	echo "## You are using Perl version $(PERL_VERSION) :"; \
	echo "## You need to patch your syslog.pm "; \
	echo "## See http://bugs.perl.org/perlbug.cgi?req=bidmids&bidmids=20000712.003"; \
	echo "##"; \
	echo "## If your Perl version is 5.6.0 AND if your system is Solaris :"; \
	echo "## See also http://bugs.perl.org/perlbug.cgi?req=bidmids&bidmids=20000522.003"; \
	echo "#############################################################################"; \
	fi

sources: src/Makefile src/queue.c src/bouncequeue.c
	@echo "Making src"
	(cd src && echo "making in src..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' WWSBINDIR='${WWSBINDIR}' \
	MAILERPROGDIR='${MAILERPROGDIR}' ETCBINDIR='${ETCBINDIR}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	USER='${USER}' GROUP='${GROUP}' \
	SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' NEWALIASES='${NEWALIASES}');

doc:	doc/sympa.tex 
	@echo "Making doc"
	(cd doc && echo "making in doc..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' WWSBINDIR='${WWSBINDIR}' \
	MAILERPROGDIR='${MAILERPROGDIR}' ETCBINDIR='${ETCBINDIR}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	USER='${USER}' GROUP='${GROUP}');

man: doc/man8/Makefile
	@echo "Making man"
	(cd doc/man8 && echo "making in doc/man8/..." && \
	$(MAKE) SYMPA_VERSION='$(SYMPA_VERSION)');

languages:
	@echo "Making nls"
	(cd nls && echo "making in nls..." && \
	$(MAKE) SH='${SH}' PERL='${PERL}' ETCBINDIR='${ETCBINDIR}' \
	DIR='${DIR}' NLSDIR='${NLSDIR}' BINDIR='${BINDIR}' \
	USER='${USER}' GROUP='${GROUP}' GENCAT='${GENCAT}');

checkcpan: 
	@echo "Checking needed CPAN modules ..."
	$(PERL) ./check_perl_modules.pl

clean:
	find . \( -name ".#*" -o -name "*~" -o -name ".*~" -o -name "#*#" \) -exec  rm -f {} \;
	@for i in src nls wwsympa src/etc/sample ;\
	do \
	(cd $$i && echo "making clean in $$i..." && \
	$(MAKE) PERL='${PERL}' clean) || exit 1; \
	done;

install: installsrc installnls installwws installman installscript installsample installdir installconfig

installsrc:
	(cd src && echo "making in src..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' SYMPA_VERSION='${SYMPA_VERSION}' \
	DIR='${DIR}' BINDIR='${BINDIR}' WWSBINDIR='${WWSBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	DESTDIR='${DESTDIR}' DARK_COLOR='${DARK_COLOR}' LIGHT_COLOR='${LIGHT_COLOR}' \
	TEXT_COLOR='${TEXT_COLOR}' BG_COLOR='${BG_COLOR}' ERROR_COLOR='${ERROR_COLOR}' \
	SHADED_COLOR='${SHADED_COLOR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	ETCBINDIR='${ETCBINDIR}' SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' \
	USER='${USER}' GROUP='${GROUP}' newinstall) || exit 1;

installnls:
	(cd nls && echo "making in nls..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' NLSDIR='${NLSDIR}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' \
	SENDMAIL_ALIASES='${SENDMAIL_ALIASES}' \
	USER='${USER}' GROUP='${GROUP}' GENCAT='${GENCAT}' newinstall) || exit 1;

installwws:
	(cd wwsympa && echo "making in wwsympa..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' BINDIR='${BINDIR}' WWSBINDIR='${WWSBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	DESTDIR='${DESTDIR}' DARK_COLOR='${DARK_COLOR}' LIGHT_COLOR='${LIGHT_COLOR}' \
	TEXT_COLOR='${TEXT_COLOR}' BG_COLOR='${BG_COLOR}' SHADED_COLOR='${SHADED_COLOR}' \
	ERROR_COLOR='${ERROR_COLOR}' SELECTED_COLOR='${SELECTED_COLOR}' \
	USER='${USER}' GROUP='${GROUP}' ICONSDIR='${ICONSDIR}' newinstall) || exit 1;

installsample:
	(cd src/etc/sample && echo "making in src/etc/sample..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' LOG_SOCKET_TYPE='${LOG_SOCKET_TYPE}' \
	DESTDIR='${DESTDIR}' DIR='${DIR}' BINDIR='${BINDIR}' WWSBINDIR='${WWSBINDIR}' HOST='${HOST}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' MAILERPROGDIR='${MAILERPROGDIR}' \
	DARK_COLOR='${DARK_COLOR}' LIGHT_COLOR='${LIGHT_COLOR}' COOKIE='${COOKIE}' \
	SHADED_COLOR='${SHADED_COLOR}' OPENSSL='${OPENSSL}' SSLCERTDIR='${SSLCERTDIR}' \
	SPOOLDIR='${SPOOLDIR}' TEXT_COLOR='${TEXT_COLOR}' BG_COLOR='${BG_COLOR}' ERROR_COLOR='${ERROR_COLOR}' \
	USER='${USER}' GROUP='${GROUP}' ICONSDIR='${ICONSDIR}' PIDDIR='${PIDDIR}' install) || exit 1;

installman:
	mkdir -p $(DESTDIR)$(MANDIR)
	mkdir -p $(DESTDIR)$(MANDIR)/man8
	@for manfile in sympa.8 archived.8 bounced.8 alias_manager.8; do \
	echo "Installing man file man8/$$manfile..."; \
	( \
		cd doc/man8 ; \
		PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		DIR=$(DIR); export DIR; \
		INSTALLDIR=$(MANDIR)/man8; export INSTALLDIR; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		SYMPA_VERSION=$(SYMPA_VERSION); export SYMPA_VERSION; \
		CONFDIR=$(CONFDIR); export CONFDIR; \
		PIDDIR=$(PIDDIR); export PIDDIR; \
		$(PERL) ../../subst.pl $$manfile \
	) ;\
	chown $(USER) $(DESTDIR)$(MANDIR)/man8/$$manfile; \
	chgrp $(GROUP) $(DESTDIR)$(MANDIR)/man8/$$manfile; \
	done


installscript:
	(cd src/etc/script && echo "making in src/etc/script..." && \
	$(MAKE) SH='${SH}' CC='${CC}' CFLAGS='${CFLAGS}' PERL='${PERL}' \
	DIR='${DIR}' DESTDIR='${DESTDIR}' BINDIR='${BINDIR}' WWSBINDIR='${WWSBINDIR}' HOST='${HOST}' \
	CONFIG='${CONFIG}' WWSCONFIG='${WWSCONFIG}' ETCBINDIR='${ETCBINDIR}' \
	MAILERPROGDIR='${MAILERPROGDIR}' \
	DARK_COLOR='${DARK_COLOR}' LIGHT_COLOR='${LIGHT_COLOR}' COOKIE='${COOKIE}' INITDIR='${INITDIR}' \
	TEXT_COLOR='${TEXT_COLOR}' BG_COLOR='${BG_COLOR}' ERROR_COLOR='${ERROR_COLOR}' OPENSSL='${OPENSSL}' \
	SHADED_COLOR='${SHADED_COLOR}' USER='${USER}' GROUP='${GROUP}' ICONSDIR='${ICONSDIR}' install) || exit 1;


installdir:
	echo "Setting $(USER) owner of $(DESTDIR)$(DIR)"
	chown $(USER) $(DESTDIR)$(DIR)
	chgrp $(GROUP) $(DESTDIR)$(DIR)
	@if [ ! -f $(DESTDIR)$(CONFDIR)/sympa.conf ] ; then \
	echo "First installation : installing directories..."; \
	for dir in expl etc sample ; do \
		if [ ! -d $(DESTDIR)$(DIR)/$$dir ] ; then \
			echo "Creating $(DESTDIR)$(DIR)/$$dir"; \
			mkdir -p $(DESTDIR)$(DIR)/$$dir; \
			chown $(USER) $(DESTDIR)$(DIR)/$$dir; \
			chgrp $(GROUP) $(DESTDIR)$(DIR)/$$dir; \
		fi \
	done \
	fi
	@if [ ! -f $(DESTDIR)$(CONFDIR)/sympa.conf ] ; then \
	echo "First installation : installing conf directories..."; \
	for dir in etc/create_list_templates etc/templates etc/wws_templates etc/scenari ; do \
		if [ ! -d $(DESTDIR)$(DIR)/$$dir ] ; then \
			echo "Creating $(DESTDIR)$(DIR)/$$dir"; \
			mkdir -p $(DESTDIR)$(DIR)/$$dir; \
			chown $(USER) $(DESTDIR)$(DIR)/$$dir; \
			chgrp $(GROUP) $(DESTDIR)$(DIR)/$$dir; \
		fi \
	done \
	fi
	@if [ ! -f $(DESTDIR)$(CONFDIR)/sympa.conf ] ; then \
	echo "First installation : installing spool directories..."; \
	for dir in $(SPOOLDIR) $(SPOOLDIR)/msg $(SPOOLDIR)/digest $(SPOOLDIR)/moderation \
	$(SPOOLDIR)/expire $(SPOOLDIR)/auth $(SPOOLDIR)/outgoing $(SPOOLDIR)/tmp ; do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			mkdir -p $(DESTDIR)$$dir; \
			chown $(USER) $(DESTDIR)$$dir; \
			chgrp $(GROUP) $(DESTDIR)$$dir; \
			chmod 770 $(DESTDIR)$$dir; \
		fi \
	done \
	fi

installconfig:
	mkdir -p $(DESTDIR)$(CONFDIR)
	@for cfile in sympa.conf wwsympa.conf ; do \
	if [ ! -f $(DESTDIR)$(CONFDIR)/$$cfile ] ; then \
	echo "Installing sample config file $$cfile..."; \
	( \
		cd src/etc/sample/ ; \
		PERL=$(PERL); export PERL; \
		UMASK=0600; export UMASK; \
		DIR=$(DIR); export DIR; \
		INSTALLDIR=$(CONFDIR); export INSTALLDIR; \
		DESTDIR=$(DESTDIR); export DESTDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		CONFIG=$(CONFIG); export CONFIG; \
		LOG_SOCKET_TYPE=$(LOG_SOCKET_TYPE); export LOG_SOCKET_TYPE; \
		COOKIE=$(COOKIE); export COOKIE; \
		HOST=$(HOST); export HOST; \
		OPENSSL=$(OPENSSL); export OPENSSL ; \
		SSLCERTDIR=$(SSLCERTDIR); export SSLCERTDIR ; \
		PIDDIR=$(PIDDIR); export PIDDIR; \
		SPOOLDIR=$(SPOOLDIR); export SPOOLDIR; \
		$(PERL) ../../../subst.pl $$cfile \
	) ;\
	chown $(USER) $(DESTDIR)$(CONFDIR)/$$cfile; \
	chgrp $(GROUP) $(DESTDIR)$(CONFDIR)/$$cfile; \
	fi \
	done

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
		HOMEDIR='/home/sympa'; export HOMEDIR; \
		VERSION=$(SYMPA_VERSION); export VERSION; \
		$(PERL) ../../../subst.pl sympa.spec \
	)
	@( \
		cd ..; \
		tar -cvf $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar sympa-$(SYMPA_VERSION); \
		gzip $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar; \
	)
	rpm -ba $(RPMTOPDIR)/SPECS/sympa.spec

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
		HOMEDIR='/var/lib/sympa'; export HOMEDIR; \
		VERSION=$(SYMPA_VERSION); export VERSION; \
		$(PERL) ../../../subst.pl sympa.spec \
	)
	@( \
		cd ..; \
		tar -cvf $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar sympa-$(SYMPA_VERSION); \
		bzip2 $(RPMTOPDIR)/SOURCES/sympa-$(SYMPA_VERSION).tar; \
	)
	rpm -ba $(RPMTOPDIR)/SPECS/sympa.spec

