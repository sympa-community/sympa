# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

perlscripts = \
	mod2html.pl \
	upgrade_bulk_spool.pl \
	upgrade_send_spool.pl \
	upgrade_shared_repository.pl \
	upgrade_sympa_password.pl

script_SCRIPTS = $(perlscripts)

man1_MANS = \
	mod2html.1 \
	upgrade_bulk_spool.1 \
	upgrade_send_spool.1 \
	upgrade_shared_repository.1 \
	upgrade_sympa_password.1

EXTRA_DIST = \
	mod2html.pl.in \
	upgrade_bulk_spool.pl.in \
	upgrade_send_spool.pl.in \
	upgrade_shared_repository.pl.in \
	upgrade_sympa_password.pl.in

CLEANFILES = $(perlscripts) $(bin_SCRIPTS) $(man1_MANS)

mod2html.pl upgrade_bulk_spool.pl upgrade_send_spool.pl upgrade_shared_repository.pl upgrade_sympa_password.pl: Makefile
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
		< $(srcdir)/$@.in > $@
	@chmod +x $@

mod2html.pl: $(srcdir)/mod2html.pl.in
upgrade_bulk_spool.pl: $(srcdir)/upgrade_bulk_spool.pl.in
upgrade_send_spool.pl: $(srcdir)/upgrade_send_spool.pl.in
upgrade_shared_repository.pl: $(srcdir)/upgrade_shared_repository.pl.in
upgrade_sympa_password.pl: $(srcdir)/upgrade_sympa_password.pl.in

.pl.1: Makefile
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@
