# Makefile - This Makefile does the Sympa documentation processing and installation
# RCS Identication ; $Revision$ ; $Date$ 
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

nobase_doc_DATA = \
	README.perltidy \
	dot.perltidyrc \
	samples/README \
	samples/trusted_applications.conf \
	samples/robot.conf \
	samples/employees.ldap \
	samples/test/config \
	samples/test/info \
	samples/test/message.footer \
	samples/test/web_tt2/welcome.tt2 \
	samples/sampleClient.php \
	samples/families/sample-auto/config.tt2 \
	samples/families/sample-auto/param_constraint.conf \
	sympa.pdf

man5dir = $(mandir)/man5
man5ext = 5Sympa
MAN5POD = \
	charset.conf.pod

EXTRA_DIST = $(nobase_doc_DATA) charset.conf.podin
CLEANFILES = $(MAN5POD) *.$(man5ext)

.podin.pod: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$< > $@

man5pod: $(MAN5POD) Makefile
	@test -n "$(man5ext)" || exit 0; \
	for pod in $(MAN5POD); do \
		echo "$$pod" | $(SED) -e 's/\.pod$$//' \
		| while read tmp; do \
		rm -f $$tmp.$(man5ext); \
		echo "GEN $$tmp.$(man5ext)"; \
		$(POD2MAN) --section=$(man5ext) --center="sympa $(VERSION)" \
			--lax --release="$(VERSION)" $$pod $$tmp.$(man5ext); \
		done; \
	done

install-data-hook: man5pod
	@test -n "$(man5ext)" || exit 0; \
	test -n "$(man5dir)" || exit 0; \
	$(mkdir_p) "$(DESTDIR)$(man5dir)" || exit 1; \
	for pod in $(MAN5POD); do \
		echo "$$pod" | $(SED) -e 's/\.pod$$//' \
		| while read tmp; do \
		echo "installing $$tmp.$(man5ext)"; \
		$(INSTALL_DATA) "$$tmp.$(man5ext)" "$(DESTDIR)$(man5dir)" \
		|| exit $$?; \
		done; \
	done

