man8_MANS = archived.8 bounced.8 alias_manager.8 sympa.8 

EXTRA_DIST = archived.pod bounced.pod alias_manager.pod sympa.pod

CLEANFILES = $(man8_MANS)

.pod.8:
	rm -f $@
	pod2man --section=8 --center="sympa $(VERSION)" --lax --release="$(VERSION)" $< $@

install-data-hook:
	sed \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--expldir--|$(expldir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--docdir--|$(docdir)|' \
		$(addprefix $(DESTDIR)$(man8dir)/, $(man8_MANS))
