# Makefile - This Makefile builds and installs Sympa sources
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

SUBDIRS = etc lib

AM_CPPFLAGS = -DCONFIG=\"$(CONFIG)\"

sbin_SCRIPTS = sympa.pl bulk.pl alias_manager.pl task_manager.pl \
	       sympa_wizard.pl sympa_newaliases.pl

libexec_PROGRAMS = queue bouncequeue familyqueue sympa_newaliases-wrapper
queue_SOURCES = queue.c
queue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"
bouncequeue_SOURCES = bouncequeue.c
bouncequeue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"
familyqueue_SOURCES = familyqueue.c
familyqueue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"
sympa_newaliases_wrapper_SOURCES = sympa_newaliases-wrapper.c
sympa_newaliases_wrapper_CPPFLAGS = $(AM_CPPFLAGS) \
	-DSYMPA_NEWALIASES=\"${sbindir}/sympa_newaliases.pl\"

man1_MANS = sympa_newaliases.1

EXTRA_DIST = $(modules_DATA) \
	     bulk.pl.in \
	     alias_manager.pl.in \
	     sympa.pl.in \
	     sympa_wizard.pl.in \
	     task_manager.pl.in \
	     sympa_newaliases.pl.in

CLEANFILES = $(man1_MANS) $(sbin_SCRIPTS)

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

	-chown root $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper
	chmod 4750 $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper

alias_manager.pl bulk.pl task_manager.pl sympa.pl sympa_wizard.pl: Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

alias_manager.pl: $(srcdir)/alias_manager.pl.in
bulk.pl: $(srcdir)/bulk.pl.in
sympa.pl: $(srcdir)/sympa.pl.in
sympa_wizard.pl: $(srcdir)/sympa_wizard.pl.in
task_manager.pl: $(srcdir)/task_manager.pl.in

sympa_newaliases.pl: $(srcdir)/sympa_newaliases.pl.in Makefile
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--SENDMAIL_ALIASES--|$(SENDMAIL_ALIASES)|' \
		-e 's|--MAKEMAP--|$(MAKEMAP)|' \
		-e 's|--NEWALIASES--|$(NEWALIASES)|' \
		-e 's|--NEWALIASES_ARG--|$(NEWALIASES_ARG)|' \
		-e 's|--POSTALIAS--|$(POSTALIAS)|' \
		-e 's|--POSTMAP--|$(POSTMAP)|' \
		< $(srcdir)/$@.in > $@
	chmod +x $@

.pl.1:
	rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@

