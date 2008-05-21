## Available catalogues (languages)
MAN8	=	archived.8 bounced.8 alias_manager.8 sympa.8 

.SUFFIXES:	.8 .pod

.8:	.pod

.pod.8:
	rm -f $@
	pod2man --section=8 --center="sympa $(SYMPA_VERSION)" --lax --release="$(SYMPA_VERSION)" $< $@

all:	$(MAN8)

clean:
	rm -f *.8

install: 
	echo "Please use the main Makefile for installing MAN Page."

newinstall: makedir 
	@for manfile in $(MAN8); do \
		echo "Installing man pages...$(DESTDIR)$(MANDIR)/man8/$$manfile"; \
		( \
			PERL=$(PERL); export PERL; \
			UMASK=0644; export UMASK; \
			DIR=$(DIR); export DIR; \
			INSTALLDIR=$(MANDIR)/man8; export INSTALLDIR; \
			DESTDIR=$(DESTDIR); export DESTDIR; \
			SYMPA_VERSION=$(SYMPA_VERSION); export SYMPA_VERSION; \
			CONFDIR=$(CONFDIR); export CONFDIR; \
			SENDMAIL_ALIASES=$(SENDMAIL_ALIASES); export SENDMAIL_ALIASES; \
			VIRTUAL_ALIASES=$(VIRTUAL_ALIASES); export VIRTUAL_ALIASES; \
			MAILERPROGDIR=$(MAILERPROGDIR); export MAILERPROGDIR; \
			PIDDIR=$(PIDDIR); export PIDDIR; \
			SPOOLDIR=$(SPOOLDIR); export SPOOLDIR; \
			PIDDIR=$(PIDDIR); export PIDDIR; \
			ETCBINDIR=$(ETCBINDIR); export ETCBINDIR; \
			$(PERL) ../../subst.pl $$manfile \
		) ;\
	done
makedir:
	@if [ ! -d $(DESTDIR)$(MANDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(MANDIR)"; \
		mkdir -p $(DESTDIR)$(MANDIR); \
	fi
	@if [ ! -d $(DESTDIR)$(MANDIR)/man8 ]; then \
		echo "Creating required directory $(DESTDIR)$(MANDIR)/man8"; \
		mkdir -p $(DESTDIR)$(MANDIR)/man8; \
	fi












