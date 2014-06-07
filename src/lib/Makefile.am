# $Id$

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

nobase_modules_DATA = \
	admin.pm \
	Archive.pm \
	Auth.pm \
	Bounce.pm \
	Bulk.pm \
	Commands.pm \
	Conf.pm \
	confdef.pm \
	Config_XML.pm \
	Sympa/Constants.pm \
	cookielib.pm \
	Sympa/Crash.pm \
	Sympa/DatabaseDescription.pm \
	Datasource.pm \
	DBManipulatorDefault.pm \
	DBManipulatorMySQL.pm \
	DBManipulatorOracle.pm \
	DBManipulatorPostgres.pm \
	DBManipulatorSQLite.pm \
	DBManipulatorSybase.pm \
	Family.pm \
	Fetch.pm \
	Sympa/Language.pm \
	Ldap.pm \
	LDAPSource.pm \
	List.pm \
	Sympa/ListDef.pm \
	Sympa/LockedFile.pm \
	Log.pm \
	Sympa/ModDef.pm \
	mail.pm \
	Marc.pm \
	Marc/Search.pm \
	Message.pm \
	PlainDigest.pm \
	Sympa/Regexps.pm \
	report.pm \
	Robot.pm \
	Scenario.pm \
	SDM.pm \
	SharedDocument.pm \
	SQLSource.pm \
	SympaSession.pm \
	sympasoap.pm \
	SympaTransport.pm \
	Task.pm \
	Sympa/Template/Compat.pm \
	tools.pm \
	tracking.pm \
	tt2.pm \
	Upgrade.pm \
	Sympa/User.pm \
	WebAgent.pm \
	wwslib.pm

man3dir = $(mandir)/man3
man3ext = 3Sympa
MAN3PM = \
	Sympa/Language.pm \
	Sympa/LockedFile.pm \
	Sympa/ModDef.pm \
	Sympa/Regexps.pm \
	Sympa/User.pm

EXTRA_DIST = Sympa/Constants.pm.in $(nobase_modules_DATA)
CLEANFILES = Sympa/Constants.pm *.$(man3ext)

Sympa/Constants.pm: Sympa/Constants.pm.in Makefile
	if [ -f $(DESTDIR)$(modulesdir)/Sympa/Constants.pm ]; then \
		PREVIOUS=`$(PERL) -Mlib=$(DESTDIR)$(modulesdir) -MSympa::Constants -e 'print Sympa::Constants::VERSION'`; \
	elif [ -f $(DESTDIR)$(bindir)/Version.pm ]; then \
		PREVIOUS=`$(PERL) -Mlib=$(DESTDIR)$(bindir) -MVersion -e 'print $$Version::Version'`; \
	else \
		PREVIOUS=$(VERSION); \
	fi; \
	echo $${PREVIOUS} > $(top_srcdir)/previous_sympa_version;
	[ -d Sympa ] || mkdir Sympa
	rm -f $@
	$(AM_V_GEN)$(SED) \
		-e 's|--VERSION--|$(VERSION)|' \
		-e 's|--USER--|$(USER)|' \
		-e 's|--GROUP--|$(GROUP)|' \
		-e 's|--CONFIG--|$(CONFIG)|' \
		-e 's|--WWSCONFIG--|$(WWSCONFIG)|' \
		-e 's|--SENDMAIL_ALIASES--|$(SENDMAIL_ALIASES)|' \
		-e 's|--piddir--|$(piddir)|' \
		-e 's|--expldir--|$(expldir)|' \
		-e 's|--spooldir--|$(spooldir)|' \
		-e 's|--sysconfdir--|$(sysconfdir)|' \
		-e 's|--localedir--|$(localedir)|' \
		-e 's|--libexecdir--|$(libexecdir)|' \
		-e 's|--sbindir--|$(sbindir)|' \
		-e 's|--scriptdir--|$(scriptdir)|' \
		-e 's|--modulesdir--|$(modulesdir)|' \
		-e 's|--defaultdir--|$(defaultdir)|' \
		-e 's|--staticdir--|$(staticdir)|' \
		-e 's|--arcdir--|$(arcdir)|' \
		-e 's|--bouncedir--|$(bouncedir)|' \
		< $(srcdir)/$@.in > $@

man3pm: $(MAN3PM) Makefile
	@test -n "$(man3ext)" || exit 0; \
	for pm in $(MAN3PM); do \
		echo "$$pm" | $(SED) -e 's/\.pm$$//' -e 's/\//::/g' \
		| while read pod; do \
		rm -f $$pod.$(man3ext); \
		echo "GEN $$pod.$(man3ext)"; \
		$(POD2MAN) --section=$(man3ext) --center="sympa $(VERSION)" \
			--lax --release="$(VERSION)" $$pm $$pod.$(man3ext); \
		done; \
	done

install-data-hook: man3pm
	@test -n "$(man3ext)" || exit 0; \
	test -n "$(man3dir)" || exit 0; \
	$(mkdir_p) "$(DESTDIR)$(man3dir)" || exit 1; \
	for pm in $(MAN3PM); do \
		echo "$$pm" | $(SED) -e 's/\.pm$$//' -e 's/\//::/g' \
		| while read pod; do \
		echo "installing $$pod.$(man3ext)"; \
		$(INSTALL_DATA) "$$pod.$(man3ext)" "$(DESTDIR)$(man3dir)" \
		|| exit $$?; \
		done; \
	done

