## Available catalogues (languages)
CAT	=	fr.cat us.cat es.cat de.cat it.cat cn-gb.cat cn-big5.cat fi.cat pl.cat

.SUFFIXES:	.cat .msg

.cat:	.msg

.msg.cat:
	rm -f $@
	$(GENCAT) $@ $<

all:	$(CAT)

clean:
	rm -f *.cat

install: 
	echo "Please use the main Makefile for installing NLS."

newinstall: makedir 
	@for c in $(CAT); do \
		echo "Installing catalog...$(DESTDIR)$(NLSDIR)/$$c"; \
		cp $$c $(DESTDIR)$(NLSDIR); \
	done
makedir:
	@if [ ! -d $(DESTDIR)$(NLSDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(NLSDIR)"; \
		mkdir -p $(DESTDIR)$(NLSDIR); \
	fi












