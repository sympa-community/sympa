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

execcgi_SCRIPTS = wwsympa.fcgi sympa_soap_server.fcgi
if SETUID_FCGI
execcgi_PROGRAMS = wwsympa-wrapper.fcgi sympa_soap_server-wrapper.fcgi
wwsympa_wrapper_fcgi_SOURCES = wwsympa-wrapper.fcgi.c
wwsympa_wrapper_fcgi_CPPFLAGS = -DWWSYMPA=\"$(execcgidir)/wwsympa.fcgi\"
sympa_soap_server_wrapper_fcgi_SOURCES = sympa_soap_server-wrapper.fcgi.c
sympa_soap_server_wrapper_fcgi_CPPFLAGS = \
			-DSYMPASOAP=\"$(execcgidir)/sympa_soap_server.fcgi\"
endif

man8_MANS = \
	wwsympa.8 \
	sympa_soap_server.8

EXTRA_DIST = wwsympa.fcgi.in sympa_soap_server.fcgi.in

CLEANFILES = $(execcgi_SCRIPTS) $(man8_MANS)

install-exec-hook:
if SETUID_FCGI
	-chown $(USER) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-chown $(USER) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
else
	-rm -f $(DESTDIR)$(execcgidir)/wwsympa-wrapper.fcgi
	-rm -f $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
endif

wwsympa.fcgi sympa_soap_server.fcgi: Makefile
	@rm -f $@
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
	@chmod +x $@

wwsympa.fcgi: $(srcdir)/wwsympa.fcgi.in
sympa_soap_server.fcgi: $(srcdir)/sympa_soap_server.fcgi.in

.fcgi.8:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@

