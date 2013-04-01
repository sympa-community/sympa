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

SUBDIRS = sample

## pdf_DATA requires autoconf 2.60; not available yet
#pdf_DATA = sympa.pdf

EXTRA_DIST = $(pdf_DATA)

man1_MANS = sympa_wizard.1
man8_MANS = archived.8 bounced.8 \
    alias_manager.8 bulk.8 spooler.8 sympa.8 task_manager.8

CLEANFILES = $(man1_MANS) $(man8_MANS)

.pl.1:
.pl.8:

sympa_wizard.1: Makefile
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $(srcdir)/../src/$*.pl $@

archived.8 bounced.8: Makefile
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $(srcdir)/../wwsympa/$*.pl $@

alias_manager.8 bulk.8 spooler.8 sympa.8 task_manager.8: Makefile
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $(srcdir)/../src/$*.pl $@

sympa_wizard.1: $(srcdir)/../src/sympa_wizard.pl
archived.8: $(srcdir)/../wwsympa/archived.pl
bounced.8: $(srcdir)/../wwsympa/bounced.pl
alias_manager.8: $(srcdir)/../src/alias_manager.pl
bulk.8: $(srcdir)/../src/bulk.pl
spooler.8: $(srcdir)/../src/spooler.pl
sympa.8: $(srcdir)/../src/sympa.pl
task_manager.8: $(srcdir)/../src/task_manager.pl

