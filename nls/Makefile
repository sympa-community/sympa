# Makefile - This Makefile does the messages translations installation
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

## Available catalogues (languages)
CAT	=	fr.cat us.cat es.cat de.cat it.cat cn.cat tw.cat fi.cat pl.cat cz.cat hu.cat ro.cat et.cat

.SUFFIXES:	.cat .msg

.cat:	.msg

.msg.cat:
	rm -f $@
	$(GENCAT) $@ $<

all:	$(CAT)

clean:
	rm -f *.cat

install: 
	echo "Please use the main Makefile for installing NLS."

newinstall: makedir 
	@for c in $(CAT); do \
		echo "Installing catalog...$(DESTDIR)$(NLSDIR)/$$c"; \
		cp $$c $(DESTDIR)$(NLSDIR); \
	done
makedir:
	@if [ ! -d $(DESTDIR)$(NLSDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(NLSDIR)"; \
		mkdir -p $(DESTDIR)$(NLSDIR); \
	fi












