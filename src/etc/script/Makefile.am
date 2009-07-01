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


script_SCRIPTS = create_db.Pg create_db.mysql create_db.Oracle \
		 create_db.Sybase create_db.SQLite \
		 arc2webarc.pl testldap.pl p12topem.pl init_comment.pl \
		 crypt_passwd.pl testlogs.pl mod2html.pl tpl2tt2.pl \
		 ldap_alias_manager.pl mysql_alias_manager.pl
init_SCRIPTS = sympa

EXTRA_DIST = $(script_SCRIPTS) $(init_SCRIPTS)

install-data-hook:
	sed \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--prefix--|$(prefix)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--lockdir--|$(lockdir)|' \
		-e 's|--initdir--|$(initdir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--pkgdatadir--|$(pkgdatadir)|' \
		$(addprefix $(DESTDIR)$(scriptdir)/, $(script_SCRIPTS)) \
		$(addprefix $(DESTDIR)$(initdir)/, $(init_SCRIPTS))
