SUBSTSRC	=	bounced.pl archived.pl wws-lib.pl cookie-lib.pl bounce-lib.pl Marc.pm

SRC		=	mime.types 

default: none

clean: 
	rm -rf $(DESTDIR)$(WWSBINDIR)

install: 
	echo "Please use the main Makefile for installing WWSympa."

newinstall: makedir $(SUBSTSRC) substcgi subst installtemplates installicons installsrc installmod

installmod:
	@for i in $(SRC) wwsympa.fcgi; do \
	chown $(USER) $(DESTDIR)$(WWSBINDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(WWSBINDIR)/$$i; \
	done
	@echo "Setting SetUID bit on wwsympa.fcgi..."
	chmod u+s $(DESTDIR)$(WWSBINDIR)/wwsympa.fcgi
	chmod g+s $(DESTDIR)$(WWSBINDIR)/wwsympa.fcgi
	chmod 755 $(DESTDIR)$(ETCBINDIR)/wws_templates
	chmod 755 $(DESTDIR)$(ICONSDIR)
	chmod 755 $(DESTDIR)$(BINDIR)/Marc
	@for i in $(SUBSTSRC) Marc; do \
	chown $(USER) $(DESTDIR)$(BINDIR)/$$i; \
	chgrp $(GROUP) $(DESTDIR)$(BINDIR)/$$i; \
	done

makedir:
	@if [ ! -d $(DESTDIR)$(BINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(BINDIR)"; \
		mkdir -p $(DESTDIR)$(BINDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(WWSBINDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(WWSBINDIR)"; \
		mkdir -p $(DESTDIR)$(WWSBINDIR); \
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
	@if [ ! -d $(DESTDIR)$(BINDIR)/Marc ]; then \
		echo "Creating required directory $(DESTDIR)$(BINDIR)/Marc"; \
		mkdir $(DESTDIR)$(BINDIR)/Marc; \
	fi

installsrc:
	@echo "Installing sources..."
	cp $(SRC) $(DESTDIR)$(WWSBINDIR)
	cp Marc/Search.pm $(DESTDIR)$(BINDIR)/Marc

installtemplates:
	@echo "Installing templates..."
	PERL=$(PERL); export PERL; \
	INSTALLDIR=$(ETCBINDIR); export INSTALLDIR; \
	BINDIR=$(BINDIR); export BINDIR; \
	DESTDIR=$(DESTDIR); export DESTDIR; \
	ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
	DARK_COLOR=$(DARK_COLOR); export DARK_COLOR; \
	LIGHT_COLOR=$(LIGHT_COLOR); export LIGHT_COLOR; \
	SELECTED_COLOR=$(SELECTED_COLOR); export SELECTED_COLOR; \
	TEXT_COLOR=$(TEXT_COLOR); export TEXT_COLOR; \
	BG_COLOR=$(BG_COLOR); export BG_COLOR; \
	ERROR_COLOR=$(ERROR_COLOR); export ERROR_COLOR; \
	COL1=5; export COL1; \
	COL2=40; export COL2; \
	COL3=30; export COL3; \
	COL4=40; export COL4; \
	COL12=45; export COL12; \
	COL23=70; export COL23; \
	COL34=70; export COL34; \
	COL234=110; export COL234; \
	$(PERL) ../subst.pl wws_templates/* 
	chmod -R 644 $(DESTDIR)$(ETCBINDIR)/wws_templates

installicons:
	@echo "Installing icons..."
	cp icons/*.gif $(DESTDIR)$(ICONSDIR)

subst:
	@echo "Doing multiple substitutions while installing ..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0755; export UMASK; \
		INSTALLDIR=$(BINDIR); export INSTALLDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
		ICONSDIR=$(ICONSDIR); export ICONSDIR; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		CONFIG=$(CONFIG); export CONFIG; \
		$(PERL) ../subst.pl $(SUBSTSRC) \
	)

substcgi:
	@echo "Doing multiple substitutions while installing CGI..."
	@( \
		PERL=$(PERL); export PERL; \
		UMASK=0755; export UMASK; \
		INSTALLDIR=$(WWSBINDIR); export INSTALLDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		DESTDIR=$(DESTDIR); export DESDIR; \
		ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
		BINDIR=$(BINDIR); export BINDIR; \
		MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
		ICONSDIR=$(ICONSDIR); export ICONSDIR; \
		WWSCONFIG=$(WWSCONFIG); export WWSCONFIG; \
		CONFIG=$(CONFIG); export CONFIG; \
		$(PERL) ../subst.pl wwsympa.fcgi \
	)




















