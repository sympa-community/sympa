SRC	=	README config.* topics.conf

SUBSTSRC	=	sympa.conf wwsympa.conf

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
	@if [ ! -d $(DESTDIR)$(DIR)/expl ]; then \
		echo "Installing sample list ..."; \
		mkdir -p $(DESTDIR)$(DIR)/expl; \
		mkdir -p $(DESTDIR)$(DIR)/expl/test; \
		cp test/* $(DESTDIR)$(DIR)/expl/test/; \
		chown -R $(USER) $(DESTDIR)$(DIR)/expl; \
		chgrp -R $(GROUP) $(DESTDIR)$(DIR)/expl; \
	fi




