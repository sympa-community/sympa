CDEFS	=	-DCONFIG=\"$(CONFIG)\"

SRC	=	sympa.pl Archive.pm Commands.pm Conf.pm \
		Language.pm List.pm Log.pm mail.pm msg.pl \
		smtp.pm tools.pl Version.pm parser.pl alias_manager.pl

all:	queue bouncequeue

clean:
	@if [ -f ./queue ]; then \
		rm queue ; \
	fi	
	@if [ -f ./bouncequeue ]; then \
		rm bouncequeue ; \
	fi

install: 
	echo "Please use the main Makefile for installing sources."

newinstall: makedir subst $(SRC) installqueue installscenari installtemplates installetc installlisttemplates installmod info


installtemplates:
	@echo "Installing default templates..."
	cp etc/templates/*.tpl  $(DESTDIR)$(ETCBINDIR)/templates

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
		$(PERL) ../../subst.pl mhonarc-ressources \
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

makedir:
	@if [ ! -d $(DESTDIR)$(MAILERPROGDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(MAILERPROGDIR)"; \
		mkdir -p $(DESTDIR)$(MAILERPROGDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(BINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(BINDIR)"; \
		mkdir -p $(DESTDIR)$(BINDIR); \
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

installmod:
	@echo "Setting group and owner for $(DESTDIR)$(BINDIR)..."
	chown -R $(USER) $(DESTDIR)$(BINDIR)
	chgrp -R $(GROUP) $(DESTDIR)$(BINDIR)
	@echo "Setting privileges..."
	chmod 755 $(DESTDIR)$(BINDIR) $(DESTDIR)$(ETCBINDIR) 
	chmod 755 $(DESTDIR)$(ETCBINDIR)/scenari $(DESTDIR)$(ETCBINDIR)/templates
	chmod 755 $(DESTDIR)$(ETCBINDIR)/create_list_templates
	chmod 644 $(DESTDIR)$(ETCBINDIR)/*.conf $(DESTDIR)$(ETCBINDIR)/*.crt 
	chmod 400 $(DESTDIR)$(ETCBINDIR)/ca-bundle.crt
	chmod 4755 $(DESTDIR)$(MAILERPROGDIR)/queue $(DESTDIR)$(MAILERPROGDIR)/bouncequeue

queue: queue.c Makefile ../Makefile
	$(CC) $(CFLAGS) $(CDEFS) -o queue queue.c

bouncequeue: bouncequeue.c Makefile ../Makefile
	$(CC) $(CFLAGS) $(CDEFS) -o bouncequeue bouncequeue.c

subst:
	@echo "Doing multiple substitutions while installing ..."
	@( \
		PERL=$(PERL); export PERL;\
		UMASK=0755; export UMASK;\
		DIR=$(DIR); export DIR;\
		DESTDIR=$(DESTDIR); export DESTDIR;\
		INSTALLDIR=$(BINDIR); export INSTALLDIR;\
		BINDIR=$(BINDIR); export BINDIR;\
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR;\
		CONFIG=$(CONFIG); export CONFIG;\
		SYMPA_VERSION=$(SYMPA_VERSION); export SYMPA_VERSION;\
		SENDMAIL_ALIASES=$(SENDMAIL_ALIASES); export SENDMAIL_ALIASES;\
		$(PERL) ../subst.pl $(SRC) \
	)

## Dépendances
queue:		queue.c Makefile

bouncequeue:	bouncequeue.c Makefile

info:
	@echo ""
	@echo "If you wish, you can contact the authors sympa-users-request@cru.fr"
	@echo "Thanks to provide release number, operating system and langage used."
	@echo ""








