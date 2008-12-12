# Makefile - This Makefile does the Sympa documentation processing and installation
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

# Available targets:
#   - all: generates .ps and .html files
#
# Needs:
#
# History
#   1999/04/13 : pda@prism.uvsq.fr : design of this makefile
#   1999/04/18 : pda@prism.uvsq.fr : added index generation
#   1999/06/24 : os@cru.fr         : icons are duplicated with html (-local_icons)
#   2007/05/31 : os@cru.fr         : the source is now the sympa.org wiki
#

all:	
	@echo "Since Sympa 5.3 the documentation is only provided in PDF format. The source being http://www.sympa.org/wiki/manual"

makedir:
	@if [ ! -d $(DESTDIR)$(DOCDIR) ]; then \
		echo "Creating required directory $(DESTDIR)$(DOCDIR)"; \
		mkdir -p $(DESTDIR)$(DOCDIR); \
	fi

install: makedir 
	@if [  -d $(DESTDIR)$(DOCDIR)/sympa ]; then \
		rm -rf $(DESTDIR)$(DOCDIR)/sympa; \
	fi



