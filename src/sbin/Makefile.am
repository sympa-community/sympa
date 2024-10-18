# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2022 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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

sbin_SCRIPTS = \
	archived.pl \
	bounced.pl \
	bulk.pl \
	sympa \
	sympa_automatic.pl \
	sympa_msg.pl \
	sympa_newaliases.pl \
	task_manager.pl

man1_MANS = \
	sympa.1 \
	sympa_newaliases.1
man8_MANS = \
	archived.8 \
	bounced.8 \
	bulk.8 \
	sympa_automatic.8 \
	sympa_msg.8 \
	task_manager.8

EXTRA_DIST = \
	archived.pl.in \
	bounced.pl.in \
	bulk.pl.in \
	sympa.pl.in \
	sympa_automatic.pl.in \
	sympa_msg.pl.in \
	sympa_newaliases.pl.in \
	task_manager.pl.in

CLEANFILES = $(sbin_SCRIPTS) $(man1_MANS) $(man8_MANS)

sympa: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$@.pl.in > $@
	@chmod +x $@

sympa: $(srcdir)/sympa.pl.in

archived.pl bounced.pl bulk.pl sympa_automatic.pl sympa_msg.pl task_manager.pl: Makefile
	@rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--docdir--|$(docdir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

archived.pl: $(srcdir)/archived.pl.in
bounced.pl: $(srcdir)/bounced.pl.in
bulk.pl: $(srcdir)/bulk.pl.in
sympa_automatic.pl: $(srcdir)/sympa_automatic.pl.in
sympa_msg.pl: $(srcdir)/sympa_msg.pl.in
task_manager.pl: $(srcdir)/task_manager.pl.in

sympa_newaliases.pl: Makefile
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
		-e 's|--MAKEMAP--|$(MAKEMAP)|' \
		-e 's|--NEWALIASES--|$(NEWALIASES)|' \
		-e 's|--NEWALIASES_ARG--|$(NEWALIASES_ARG)|' \
		-e 's|--POSTALIAS--|$(POSTALIAS)|' \
		-e 's|--POSTMAP--|$(POSTMAP)|' \
		< $(srcdir)/$@.in > $@
	@chmod +x $@

sympa_newaliases.pl: $(srcdir)/sympa_newaliases.pl.in

.pl.1:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@
sympa.1: sympa
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=1 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $< $@
.pl.8:
	@rm -f $@
	$(AM_V_GEN)$(POD2MAN) --section=8 --center="sympa $(VERSION)" \
		--lax --release="$(VERSION)" $*.pl $@

# Create link to older script name for backward compatibility.
install-exec-hook:
	@rm -f $(DESTDIR)$(sbindir)/sympa.pl
	$(LN_S) sympa $(DESTDIR)$(sbindir)/sympa.pl

# Remove old sympa.8 manpage.
install-data-hook:
	@rm -f $(DESTDIR)$(man8dir)/sympa.8

