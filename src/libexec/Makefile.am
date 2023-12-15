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

#FIXME:These lines might be enabled by Sympa-7.0.
#libexec_SCRIPTS = alias_manager.pl \
#		  ldap_alias_manager.pl \
#		  mysql_alias_manager.pl

sbin_SCRIPTS = alias_manager.pl
script_SCRIPTS = ldap_alias_manager.pl mysql_alias_manager.pl

man8_MANS = alias_manager.8

EXTRA_DIST = alias_manager.pl.in \
	     ldap_alias_manager.pl.in \
	     mysql_alias_manager.pl.in

#CLEANFILES = $(libexec_SCRIPTS) $(man8_MANS)
CLEANFILES = $(sbin_SCRIPTS) $(script_SCRIPTS) $(man8_MANS)

libexec_PROGRAMS = queue bouncequeue familyqueue

AM_CPPFLAGS = -DCONFIG=\"$(CONFIG)\"

queue_SOURCES = queue.c
queue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"

bouncequeue_SOURCES = bouncequeue.c
bouncequeue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"

familyqueue_SOURCES = familyqueue.c
familyqueue_CPPFLAGS = $(AM_CPPFLAGS) -DSPOOLDIR=\"${spooldir}\"

if SETUID_NEWALIASES
libexec_PROGRAMS += sympa_newaliases-wrapper
sympa_newaliases_wrapper_SOURCES = sympa_newaliases-wrapper.c
sympa_newaliases_wrapper_CPPFLAGS = $(AM_CPPFLAGS) \
	-DSYMPA_NEWALIASES=\"${sbindir}/sympa_newaliases.pl\"
endif

install-exec-hook:
	-chown $(USER) $(DESTDIR)$(libexecdir)/queue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/queue
if SETUID_QUEUE
	chmod 4755 $(DESTDIR)$(libexecdir)/queue
else
	chmod 0755 $(DESTDIR)$(libexecdir)/queue
endif

	-chown $(USER) $(DESTDIR)$(libexecdir)/bouncequeue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/bouncequeue
if SETUID_QUEUE
	chmod 4755 $(DESTDIR)$(libexecdir)/bouncequeue
else
	chmod 0755 $(DESTDIR)$(libexecdir)/bouncequeue
endif

	-chown $(USER) $(DESTDIR)$(libexecdir)/familyqueue
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/familyqueue
if SETUID_QUEUE
	chmod 4755 $(DESTDIR)$(libexecdir)/familyqueue
else
	chmod 0755 $(DESTDIR)$(libexecdir)/familyqueue
endif

if SMRSH
	@echo 'Installing symbolic links for Sendmail smrsh'
	$(INSTALL) -d -m 755 $(DESTDIR)$(smrshdir)
	-rm -f $(DESTDIR)$(smrshdir)/queue
	$(LN_S) $(libexecdir)/queue $(DESTDIR)$(smrshdir)/queue
	-rm -f $(DESTDIR)$(smrshdir)/bouncequeue
	$(LN_S) $(libexecdir)/bouncequeue $(DESTDIR)$(smrshdir)/bouncequeue
	-rm -f $(DESTDIR)$(smrshdir)/familyqueue
	$(LN_S) $(libexecdir)/familyqueue $(DESTDIR)$(smrshdir)/familyqueue
endif

if SETUID_NEWALIASES
	-chown root $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper
	chmod 4750 $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper
else
	-rm -f $(DESTDIR)$(libexecdir)/sympa_newaliases-wrapper
endif

alias_manager.pl ldap_alias_manager.pl mysql_alias_manager.pl: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--SENDMAIL_ALIASES--|$(SENDMAIL_ALIASES)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

alias_manager.pl: $(srcdir)/alias_manager.pl.in
ldap_alias_manager.pl: $(srcdir)/ldap_alias_manager.pl.in
mysql_alias_manager.pl: $(srcdir)/mysql_alias_manager.pl.in

.pl.8:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pl $@

