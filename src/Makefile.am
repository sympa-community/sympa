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

SUBDIRS = etc

AM_CPPFLAGS = -DCONFIG=\"$(CONFIG)\"

sbin_SCRIPTS = sympa.pl bulk.pl alias_manager.pl task_manager.pl sympa_wizard.pl
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
bouncequeue_SOURCES = bouncequeue.c
familyqueue_SOURCES = familyqueue.c


modules_DATA = admin.pm Archive.pm Bulk.pm Commands.pm confdef.pm Conf.pm CAS.pm Config_XML.pm \
	       Family.pm Language.pm List.pm Log.pm mail.pm Ldap.pm Upgrade.pm \
	       Lock.pm Version.pm Fetch.pm Message.pm Task.pm Datasource.pm \
	       SQLSource.pm LDAPSource.pm Scenario.pm PlainDigest.pm \
	       tools.pl tt2.pl report.pm time_utils.pl

EXTRA_DIST = $(modules_DATA) $(sbin_SCRIPTS)

install-exec-hook:
	chmod 4755 $(DESTDIR)$(libexecdir)/queue
	-chown $(USER) $(DESTDIR)$(libexecdir)/queue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/queue

	chmod 4755 $(DESTDIR)$(libexecdir)/bouncequeue
	-chown $(USER) $(DESTDIR)$(libexecdir)/bouncequeue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/bouncequeue

	chmod 4755 $(DESTDIR)$(libexecdir)/familyqueue
	-chown $(USER) $(DESTDIR)$(libexecdir)/familyqueue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/familyqueue

	chmod 4750 aliaswrapper $(DESTDIR)$(sbindir)/aliaswrapper
	-chown root $(DESTDIR)$(sbindir)/aliaswrapper
	-chgrp $(GROUP) $(DESTDIR)$(sbindir)/aliaswrapper

	chmod 4750 $(DESTDIR)$(sbindir)/virtualwrapper
	-chown root $(DESTDIR)$(sbindir)/virtualwrapper
	-chgrp $(GROUP) $(DESTDIR)$(sbindir)/virtualwrapper

install-data-hook:
	sed -i \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--VERSION--|$(VERSION)|' \
		-e 's|--SENDMAIL_ALIASES--|$(SENDMAIL_ALIASES)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--prefix--|$(prefix)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--pkgdatadir--|$(pkgdatadir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--expldir--|$(expldir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		$(addprefix $(DESTDIR)$(modulesdir)/, $(modules_DATA)) \
		$(addprefix $(DESTDIR)$(sbindir)/, $(sbin_SCRIPTS))
