# Makefile - This Makefile does the web interface of Sympa installation
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

sbin_SCRIPTS = bounced.pl archived.pl
execcgi_SCRIPTS = wwsympa.fcgi wwsympa_sudo_wrapper.pl
execcgi_PROGRAMS = wwsympa-wrapper.fcgi
wwsympa_wrapper_fcgi_SOURCES = wwsympa-wrapper.fcgi.c
wwsympa_wrapper_fcgi_CPPFLAGS = -DWWSYMPA=\"$(execcgidir)/wwsympa.fcgi\"

nobase_modules_DATA = wwslib.pm cookielib.pm bounce-lib.pl Marc.pm Auth.pm \
		      Marc/Search.pm SharedDocument.pm SympaSession.pm

default_DATA = mime.types 

EXTRA_DIST = $(default_DATA) $(nobase_modules_DATA) \
	     $(sbin_SCRIPTS) $(execcgi_SCRIPTS)

install-exec-hook:
	-chown $(USER) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi

install-data-hook:
	sed -i \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--pkgdatadir--|$(pkgdatadir)|' \
		-e 's|--execcgidir--|$(execcgidir)|' \
		$(addprefix $(DESTDIR)$(modulesdir)/, $(nobase_modules_DATA)) \
		$(addprefix $(DESTDIR)$(sbindir)/, $(sbin_SCRIPTS)) \
		$(addprefix $(DESTDIR)$(execcgidir)/, $(execcgi_SCRIPTS))

installicons:
	install -d -m 755 $(DESTDIR)$(prefix)/static_content
	install -d -m 755 $(DESTDIR)$(prefix)/static_content/icons
	install -m 644 icons/*.png $(DESTDIR)$(prefix)/static_content/icons
