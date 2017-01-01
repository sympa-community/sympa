# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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
	samples/families/sample-auto/param_constraint.conf

man1_MANS = \
	sympa_toc.1
man5_MANS = \
	charset.conf.5 \
	sympa.conf.5 \
	sympa_database.5

EXTRA_DIST = $(nobase_doc_DATA) \
	charset.conf.podin \
	sympa.conf.podpl \
	sympa_database.podpl \
	sympa_toc.pod

CLEANFILES = $(man1_MANS) $(man5_MANS)

.pod.1:
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pod $@

.podin.5:
	$(AM_V_GEN)rm -f $*.pod
	@$(SED) \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$< > $*.pod
	@rm -f $@
	@$(POD2MAN) --section=5 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pod $@
	@rm -f $*.pod
.podpl.5:
	$(AM_V_GEN)rm -f $*.pod
	@PERL5LIB=$(top_srcdir)/src/lib; export PERL5LIB; \
	$(PERL) $(srcdir)/$< > $*.pod
	@rm -f $@
	@$(POD2MAN) --section=5 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pod $@
	@rm -f $*.pod
