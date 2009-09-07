# Makefile - This Makefile does the Sympa scripts installation
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

dbscripts = create_db.Pg create_db.mysql create_db.Oracle \
	    create_db.Sybase create_db.SQLite

perlscripts = arc2webarc.pl testldap.pl p12topem.pl init_comment.pl \
	      crypt_passwd.pl testlogs.pl mod2html.pl tpl2tt2.pl \
	      ldap_alias_manager.pl mysql_alias_manager.pl

script_SCRIPTS = $(dbscripts) $(perlscripts)
init_SCRIPTS = sympa

EXTRA_DIST = $(dbscripts) \
	     arc2webarc.pl.in crypt_passwd.pl.in init_comment.pl.in \
	     ldap_alias_manager.pl.in mod2html.pl.in mysql_alias_manager.pl.in \
	     p12topem.pl.in testldap.pl.in testlogs.pl.in tpl2tt2.pl.in \
	     sympa.in

CLEANFILES = $(perlscripts) $(init_SCRIPTS)

arc2webarc.pl crypt_passwd.pl init_comment.pl ldap_alias_manager.pl mod2html.pl mysql_alias_manager.pl p12topem.pl testldap.pl testlogs.pl tpl2tt2.pl: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

sympa: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--initdir--|$(initdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--lockdir--|$(lockdir)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

arc2webarc.pl: arc2webarc.pl.in
crypt_passwd.pl: crypt_passwd.pl.in
init_comment.pl: init_comment.pl.in
ldap_alias_manager.pl: ldap_alias_manager.pl.in
mod2html.pl: mod2html.pl.in
mysql_alias_manager.pl: mysql_alias_manager.pl.in
p12topem.pl: p12topem.pl.in
testldap.pl: testldap.pl.in
testlogs.pl: testlogs.pl.in
tpl2tt2.pl: tpl2tt2.pl.in

sympa: sympa.in
