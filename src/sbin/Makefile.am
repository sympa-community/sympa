# This file is part of Sympa, see top-level README.md file for details

sbin_SCRIPTS = archived.pl \
	       bounced.pl \
	       bulk.pl \
	       sympa.pl \
	       sympa_automatic.pl \
	       sympa_msg.pl \
	       sympa_newaliases.pl \
	       sympa_wizard.pl \
	       task_manager.pl

man1_MANS = \
	sympa.1 \
	sympa_newaliases.1 \
	sympa_wizard.1
man8_MANS = \
	archived.8 \
	bounced.8 \
	bulk.8 \
	sympa_automatic.8 \
	sympa_msg.8 \
	task_manager.8

EXTRA_DIST = \
	archived.pl.in \
	bounced.pl.in \
	bulk.pl.in \
	sympa.pl.in \
	sympa_automatic.pl.in \
	sympa_msg.pl.in \
	sympa_newaliases.pl.in \
	sympa_wizard.pl.in \
	task_manager.pl.in

CLEANFILES = $(sbin_SCRIPTS) $(man1_MANS) $(man8_MANS)

archived.pl bounced.pl bulk.pl sympa.pl sympa_automatic.pl sympa_msg.pl task_manager.pl: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

archived.pl: $(srcdir)/archived.pl.in
bounced.pl: $(srcdir)/bounced.pl.in
bulk.pl: $(srcdir)/bulk.pl.in
sympa.pl: $(srcdir)/sympa.pl.in
sympa_automatic.pl: $(srcdir)/sympa_automatic.pl.in
sympa_msg.pl: $(srcdir)/sympa_msg.pl.in
task_manager.pl: $(srcdir)/task_manager.pl.in

sympa_newaliases.pl sympa_wizard.pl: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--SENDMAIL_ALIASES--|$(SENDMAIL_ALIASES)|' \
		-e 's|--MAKEMAP--|$(MAKEMAP)|' \
		-e 's|--NEWALIASES--|$(NEWALIASES)|' \
		-e 's|--NEWALIASES_ARG--|$(NEWALIASES_ARG)|' \
		-e 's|--POSTALIAS--|$(POSTALIAS)|' \
		-e 's|--POSTMAP--|$(POSTMAP)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

sympa_newaliases.pl: $(srcdir)/sympa_newaliases.pl.in
sympa_wizard.pl: $(srcdir)/sympa_wizard.pl.in

.pl.1:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@
.pl.8:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pl $@

# Remove old sympa.8 manpage.
install-data-hook:
	@rm -f $(DESTDIR)$(man8dir)/sympa.8

