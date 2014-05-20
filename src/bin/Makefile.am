# Makefile - This Makefile does the Sympa scripts installation
# RCS Identication ; $Revision$ ; $Date$ 
#
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

bin_SCRIPTS = sympa_soap_client.pl

dbscripts = \
	create_db.Pg \
	create_db.mysql \
	create_db.Oracle \
	create_db.Sybase \
	create_db.SQLite

perlscripts = \
	arc2webarc.pl \
	testldap.pl \
	p12topem.pl \
	init_comment.pl \
	crypt_passwd.pl \
	testlogs.pl \
	mod2html.pl \
	tpl2tt2.pl

script_SCRIPTS = $(dbscripts) $(perlscripts)

EXTRA_DIST = $(dbscripts) \
	arc2webarc.pl.in \
	crypt_passwd.pl.in \
	init_comment.pl.in \
	mod2html.pl.in \
	p12topem.pl.in \
	testldap.pl.in \
	testlogs.pl.in \
	tpl2tt2.pl.in \
	sympa_soap_client.pl.in

CLEANFILES = $(perlscripts) $(bin_SCRIPTS)

arc2webarc.pl crypt_passwd.pl init_comment.pl mod2html.pl p12topem.pl testldap.pl testlogs.pl tpl2tt2.pl sympa_soap_client.pl: Makefile
	rm -f $@
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
	chmod +x $@

arc2webarc.pl: $(srcdir)/arc2webarc.pl.in
crypt_passwd.pl: $(srcdir)/crypt_passwd.pl.in
init_comment.pl: $(srcdir)/init_comment.pl.in
mod2html.pl: $(srcdir)/mod2html.pl.in
p12topem.pl: $(srcdir)/p12topem.pl.in
testldap.pl: $(srcdir)/testldap.pl.in
testlogs.pl: $(srcdir)/testlogs.pl.in
tpl2tt2.pl: $(srcdir)/tpl2tt2.pl.in
sympa_soap_client.pl: $(srcdir)/sympa_soap_client.pl.in

.pl.1: Makefile
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $* $@
