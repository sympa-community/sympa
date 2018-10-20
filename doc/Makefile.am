# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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
	auth.conf.5 \
	automatic_lists_description.conf.5 \
	charset.conf.5 \
	crawlers_detection.conf.5 \
	edit_list.conf.5 \
	ldap_alias_manager.conf.5 \
	list_config.5 \
	nrcpt_by_domain.conf.5 \
	sympa.conf.5 \
	sympa_database.5 \
	sympa.wsdl.5 \
	sympa_scenario.5 \
	topics.conf.5 \
	trusted_applications.conf.5

EXTRA_DIST = $(nobase_doc_DATA) \
	auth.conf.pod \
	automatic_lists_description.conf.pod \
	charset.conf.pod \
	crawlers_detection.conf.pod \
	edit_list.conf.pod \
	ldap_alias_manager.conf.pod \
	list_config.podpl \
	nrcpt_by_domain.conf.pod \
	sympa.conf.podpl \
	sympa_database.podpl \
	sympa_scenario.pod \
	sympa_toc.pod \
	sympa.wsdl.pod \
	topics.conf.pod \
	trusted_applications.conf.pod

CLEANFILES = $(man1_MANS) $(man5_MANS)

.pod.1:
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pod $@
.pod.5:
	$(AM_V_GEN)$(POD2MAN) --section=5 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pod $@

.podpl.pod:
	$(AM_V_GEN)PERL5LIB=$(top_srcdir)/src/lib; export PERL5LIB; \
	$(PERL) $(srcdir)/$< > $*.pod
