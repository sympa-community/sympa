SRC	=	create_db.Pg create_db.mysql create_db.Oracle create_db.Sybase

SUBSTSRC	=	load_subscribers.pl arc2webarc.pl testldap.pl p12topem.pl init_comment.pl crypt_passwd.pl

INITSRC		=	sympa

#SCRIPTDIR	=	../../../script
SCRIPTDIR	=	$(BINDIR)

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
		INSTALLDIR=$(SCRIPTDIR); export INSTALLDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		CONFIG=$(CONFIG); export CONFIG; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		COOKIE=$(COOKIE); export COOKIE; \
		HOST=$(HOST); export HOST; \
		OPENSSL=$(OPENSSL); export OPENSSL; \
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
		INSTALLDIR=$(INITDIR); export INSTALLDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		CONFIG=$(CONFIG); export CONFIG; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		COOKIE=$(COOKIE); export COOKIE; \
		HOST=$(HOST); export HOST; \
		$(PERL) ../../../subst.pl $(INITSRC) \
	)



