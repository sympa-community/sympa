# This file is part of Sympa, see top-level README.md file for details

if SYSV_INIT
init_SCRIPTS = sympa
endif

if SYSTEMD_UNITS
units_DATA = \
	sympa-archive.service \
	sympa-bounce.service \
	sympa-outgoing.service \
	sympa-task.service \
	sympa.service
noinst_DATA = \
	nginx-sympasoap.service \
	nginx-wwsympa.service \
	sympa-tmpfiles.conf
endif

EXTRA_DIST = \
	sympa.in \
	sympa-archive.servicein \
	sympa-bounce.servicein \
	sympa-outgoing.servicein \
	sympa-task.servicein \
	sympa.servicein \
	nginx-sympasoap.servicein \
	nginx-wwsympa.servicein \
	sympa-tmpfiles.confin

CLEANFILES = $(init_SCRIPTS) $(units_DATA) $(noinst_DATA)

sympa: sympa.in Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--initdir--|$(initdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--lockdir--|$(lockdir)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

.servicein.service: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		< $(srcdir)/$@in > $@

.confin.conf: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--piddir--|$(piddir)|' \
		< $(srcdir)/$@in > $@

