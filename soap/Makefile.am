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

execcgi_SCRIPTS	 = sympa_soap_server.fcgi
execcgi_PROGRAMS = sympa_soap_server-wrapper.fcgi
sympa_soap_server_wrapper_fcgi_SOURCES = sympa_soap_server-wrapper.fcgi.c
sympa_soap_server_wrapper_fcgi_CPPFLAGS = \
			  -DSYMPASOAP=\"$(execcgidir)/sympa_soap_server.fcgi\"

script_SCRIPTS = sympa_soap_client.pl

modules_DATA = sympasoap.pm SympaTransport.pm

default_DATA = sympa.wsdl

EXTRA_DIST = $(default_DATA) $(modules_DATA) \
	     sympa_soap_client.pl.in \
	     sympa_soap_server.fcgi.in

CLEANFILES = $(script_SCRIPTS) $(execcgi_SCRIPTS)

install-exec-hook:
	-chown $(USER) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	-chgrp $(GROUP) $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi
	chmod 6755 $(DESTDIR)$(execcgidir)/sympa_soap_server-wrapper.fcgi

sympa_soap_client.pl sympa_soap_server.fcgi: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

sympa_soap_client.pl: $(srcdir)/sympa_soap_client.pl.in
sympa_soap_server.fcgi: $(srcdir)/sympa_soap_server.fcgi.in
