# Makefile - This Makefile builds and installs Sympa sources
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

SUBDIRS = etc lib

AM_CPPFLAGS = -DCONFIG=\"$(CONFIG)\"

sbin_SCRIPTS = sympa.pl bulk.pl spooler.pl alias_manager.pl task_manager.pl sympa_wizard.pl
sbin_PROGRAMS = aliaswrapper virtualwrapper
aliaswrapper_SOURCES = aliaswrapper.c
aliaswrapper_CPPFLAGS = $(AM_CPPFLAGS) \
			-DNEWALIASES=\"${NEWALIASES}\" \
			-DNEWALIASES_ARG=\"${NEWALIASES_ARG}\"
virtualwrapper_SOURCES = virtualwrapper.c
virtualwrapper_CPPFLAGS = $(AM_CPPFLAGS) \
			  -DPOSTMAP=\"${POSTMAP}\" \
			  -DPOSTMAP_ARG=\"${POSTMAP_ARG}\"

libexec_PROGRAMS = queue bouncequeue familyqueue
queue_SOURCES = queue.c
queue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"
bouncequeue_SOURCES = bouncequeue.c
bouncequeue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"
familyqueue_SOURCES = familyqueue.c
familyqueue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"

EXTRA_DIST = $(modules_DATA) \
	     bulk.pl.in \
	     alias_manager.pl.in \
	     sympa.pl.in \
	     spooler.pl.in \
	     sympa_wizard.pl.in \
	     task_manager.pl.in

CLEANFILES = $(sbin_SCRIPTS)

install-exec-hook:
	-chown $(USER) $(DESTDIR)$(libexecdir)/queue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/queue
	chmod 4755 $(DESTDIR)$(libexecdir)/queue

	-chown $(USER) $(DESTDIR)$(libexecdir)/bouncequeue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/bouncequeue
	chmod 4755 $(DESTDIR)$(libexecdir)/bouncequeue

	-chown $(USER) $(DESTDIR)$(libexecdir)/familyqueue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/familyqueue
	chmod 4755 $(DESTDIR)$(libexecdir)/familyqueue

	-chown root $(DESTDIR)$(sbindir)/aliaswrapper
	-chgrp $(GROUP) $(DESTDIR)$(sbindir)/aliaswrapper
	chmod 4750 aliaswrapper $(DESTDIR)$(sbindir)/aliaswrapper

	-chown root $(DESTDIR)$(sbindir)/virtualwrapper
	-chgrp $(GROUP) $(DESTDIR)$(sbindir)/virtualwrapper
	chmod 4750 $(DESTDIR)$(sbindir)/virtualwrapper

alias_manager.pl bulk.pl task_manager.pl sympa.pl spooler.pl sympa_wizard.pl: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

alias_manager.pl: $(srcdir)/alias_manager.pl.in
bulk.pl: $(srcdir)/bulk.pl.in
sympa.pl: $(srcdir)/sympa.pl.in
spooler.pl: $(srcdir)/spooler.pl.in
sympa_wizard.pl: $(srcdir)/sympa_wizard.pl.in
task_manager.pl: $(srcdir)/task_manager.pl.in
