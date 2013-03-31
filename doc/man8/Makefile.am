man8_MANS = archived.8 bounced.8 alias_manager.8 bulk.8 spooler.8 sympa.8 

CLEANFILES = $(man8_MANS)

.pl.8:

archived.8 bounced.8: Makefile
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $(srcdir)/../../wwsympa/$*.pl $@

alias_manager.8 bulk.8 spooler.8 sympa.8: Makefile
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $(srcdir)/../../src/$*.pl $@

archived.8: $(srcdir)/../../wwsympa/archived.pl
bounced.8: $(srcdir)/../../wwsympa/bounced.pl
alias_manager.8: $(srcdir)/../../src/alias_manager.pl
bulk.8: $(srcdir)/../../src/bulk.pl
spooler.8: $(srcdir)/../../src/spooler.pl
sympa.8: $(srcdir)/../../src/sympa.pl
