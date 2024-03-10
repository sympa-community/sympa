# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
	sympasoap-spawn-fcgi.service \
	wwsympa-spawn-fcgi.service \
	sympasoap-multiwatch.service \
	sympasoap-multiwatch.socket \
	wwsympa-multiwatch.service \
	wwsympa-multiwatch.socket \
	sympa-tmpfiles.conf
endif

EXTRA_DIST = \
	README.md \
	sympa.in \
	sympa-archive.servicein \
	sympa-bounce.servicein \
	sympa-outgoing.servicein \
	sympa-task.servicein \
	sympa.servicein \
	sympasoap-spawn-fcgi.servicein \
	sympasoap-multiwatch.servicein \
	sympasoap-multiwatch.socketin \
	wwsympa-spawn-fcgi.servicein \
	wwsympa-multiwatch.servicein \
	wwsympa-multiwatch.socketin \
	sympa-tmpfiles.confin

CLEANFILES = $(init_SCRIPTS) $(units_DATA) $(noinst_DATA)

sympa: sympa.in Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--CONFIG--|$(CONFIG)|' \
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
		-e 's|--execcgidir--|$(execcgidir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		< $(srcdir)/$@in > $@

.socketin.socket: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--piddir--|$(piddir)|' \
		< $(srcdir)/$@in > $@

.confin.conf: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--piddir--|$(piddir)|' \
		< $(srcdir)/$@in > $@

