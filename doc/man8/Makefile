## Available catalogues (languages)
MAN8	=	archived.8 bounced.8 alias_manager.8 sympa.8 

.SUFFIXES:	.8 .pod

.8:	.pod

.pod.8:
	rm -f $@
	pod2man -s 8 -r $(SYMPA_VERSION) $< $@

all:	$(MAN8)

clean:
	rm -f *.8

install: 
	echo "Please use the main Makefile for installing MAN Page."

newinstall: makedir 
	@for c in $(MAN8); do \
		echo "Installing man pages...$(DESTDIR)$(MANDIR)/$$c"; \
		cp $$c $(DESTDIR)$(MANDIR); \
	done
makedir:
	@if [ ! -d $(DESTDIR)$(MANDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(MANDIR)"; \
		mkdir -p $(DESTDIR)$(MANDIR); \
	fi












