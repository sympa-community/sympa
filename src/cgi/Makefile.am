# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
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

execcgi_SCRIPTS = wwsympa.fcgi sympa_soap_server.fcgi
execcgi_PROGRAMS = wwsympa-wrapper.fcgi sympa_soap_server-wrapper.fcgi
wwsympa_wrapper_fcgi_SOURCES = wwsympa-wrapper.fcgi.c
wwsympa_wrapper_fcgi_CPPFLAGS = -DWWSYMPA=\"$(execcgidir)/wwsympa.fcgi\"
sympa_soap_server_wrapper_fcgi_SOURCES = sympa_soap_server-wrapper.fcgi.c
sympa_soap_server_wrapper_fcgi_CPPFLAGS = \
			-DSYMPASOAP=\"$(execcgidir)/sympa_soap_server.fcgi\"

EXTRA_DIST = wwsympa.fcgi.in sympa_soap_server.fcgi.in

CLEANFILES = $(execcgi_SCRIPTS)

install-exec-hook:
	-chown $(USER) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chown $(USER) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi

wwsympa.fcgi sympa_soap_server.fcgi: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

wwsympa.fcgi: $(srcdir)/wwsympa.fcgi.in
sympa_soap_server.fcgi: $(srcdir)/sympa_soap_server.fcgi.in
