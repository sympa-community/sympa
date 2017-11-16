# This file is part of Sympa, see top-level README.md file for details

execcgi_SCRIPTS = wwsympa.fcgi sympa_soap_server.fcgi
execcgi_PROGRAMS = wwsympa-wrapper.fcgi sympa_soap_server-wrapper.fcgi
wwsympa_wrapper_fcgi_SOURCES = wwsympa-wrapper.fcgi.c
wwsympa_wrapper_fcgi_CPPFLAGS = -DWWSYMPA=\"$(execcgidir)/wwsympa.fcgi\"
sympa_soap_server_wrapper_fcgi_SOURCES = sympa_soap_server-wrapper.fcgi.c
sympa_soap_server_wrapper_fcgi_CPPFLAGS = \
			-DSYMPASOAP=\"$(execcgidir)/sympa_soap_server.fcgi\"

man8_MANS = \
	wwsympa.8 \
	sympa_soap_server.8

EXTRA_DIST = wwsympa.fcgi.in sympa_soap_server.fcgi.in

CLEANFILES = $(execcgi_SCRIPTS) $(man8_MANS)

install-exec-hook:
	-chown $(USER) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chown $(USER) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi

wwsympa.fcgi sympa_soap_server.fcgi: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

wwsympa.fcgi: $(srcdir)/wwsympa.fcgi.in
sympa_soap_server.fcgi: $(srcdir)/sympa_soap_server.fcgi.in

.fcgi.8:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@

