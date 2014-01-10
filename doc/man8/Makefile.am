# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

man8_MANS = archived.8 bounced.8 alias_manager.8 sympa.8 

EXTRA_DIST = archived.pod.in bounced.pod.in alias_manager.pod.in sympa.pod.in

CLEANFILES = $(man8_MANS) archived.pod bounced.pod alias_manager.pod sympa.pod

.pod.8:
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@

archived.pod bounced.pod alias_manager.pod sympa.pod: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--SENDMAIL_ALIASES--|$(SENDMAIL_ALIASES)|' \
		< $(srcdir)/$@.in > $@

archived.pod: $(srcdir)/archived.pod.in
bounced.pod: $(srcdir)/bounced.pod.in
alias_manager.pod: $(srcdir)/alias_manager.pod.in
sympa.pod: $(srcdir)/sympa.pod.in
