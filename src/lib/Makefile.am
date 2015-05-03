# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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
	Sympa.pm \
	Sympa/Admin.pm \
	Sympa/Alarm.pm \
	Sympa/Archive.pm \
	Sympa/Auth.pm \
	Sympa/Bulk.pm \
	Sympa/Commands.pm \
	Conf.pm \
	Sympa/ConfDef.pm \
	Sympa/Config_XML.pm \
	Sympa/Constants.pm \
	Sympa/Crash.pm \
	Sympa/Database.pm \
	Sympa/DatabaseDescription.pm \
	Sympa/DatabaseDriver.pm \
	Sympa/DatabaseDriver/CSV.pm \
	Sympa/DatabaseDriver/LDAP.pm \
	Sympa/DatabaseDriver/MySQL.pm \
	Sympa/DatabaseDriver/ODBC.pm \
	Sympa/DatabaseDriver/Oracle.pm \
	Sympa/DatabaseDriver/Oracle/St.pm \
	Sympa/DatabaseDriver/PostgreSQL.pm \
	Sympa/DatabaseDriver/SQLite.pm \
	Sympa/DatabaseDriver/Sybase.pm \
	Sympa/DatabaseManager.pm \
	Sympa/Datasource.pm \
	Sympa/Family.pm \
	Sympa/Fetch.pm \
	Sympa/HTML/FormatText.pm \
	Sympa/HTMLSanitizer.pm \
	Sympa/Language.pm \
	Sympa/List.pm \
	Sympa/ListDef.pm \
	Sympa/LockedFile.pm \
	Sympa/Log.pm \
	Sympa/Mailer.pm \
	Sympa/Marc.pm \
	Sympa/Marc/Search.pm \
	Sympa/Message.pm \
	Sympa/Message/Plugin.pm \
	Sympa/Message/Plugin/FixEncoding.pm \
	Sympa/ModDef.pm \
	Sympa/Regexps.pm \
	Sympa/Report.pm \
	Sympa/Robot.pm \
	Sympa/Scenario.pm \
	SDM.pm \
	Sympa/SharedDocument.pm \
	Sympa/Session.pm \
	Sympa/SOAP.pm \
	Sympa/SOAP/Transport.pm \
	Sympa/Spool.pm \
	Sympa/Spool/Archive.pm \
	Sympa/Task.pm \
	Sympa/Template.pm \
	tools.pm \
	Sympa/Tools/Daemon.pm \
	Sympa/Tools/Data.pm \
	Sympa/Tools/DKIM.pm \
	Sympa/Tools/File.pm \
	Sympa/Tools/Password.pm \
	Sympa/Tools/SMIME.pm \
	Sympa/Tools/Text.pm \
	Sympa/Tools/Time.pm \
	Sympa/Tools/WWW.pm \
	Sympa/Tracking.pm \
	Sympa/Upgrade.pm \
	Sympa/User.pm

man3dir = $(mandir)/man3
man3ext = 3Sympa
MAN3PM = $(nobase_modules_DATA)
MAN3POD = Sympa/Internals.pod

EXTRA_DIST = \
	Sympa/Constants.pm.in \
	Sympa/Internals.podpl \
	$(nobase_modules_DATA)
CLEANFILES = Sympa/Constants.pm Sympa/Internals.pod *.$(man3ext)

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

Sympa/Internals.pod: Sympa/Internals.podpl Makefile
	$(AM_V_GEN)$(PERL) $< $(MAN3PM) > $@

man3pm: $(MAN3PM) $(MAN3POD) Makefile
	@test -n "$(man3ext)" || exit 0; \
	for pm in $(MAN3PM) $(MAN3POD); do \
		echo "$$pm" | $(SED) -e 's/\.pm$$//' -e 's/\.pod$$//' -e 's/\//::/g' \
		| while read pod; do \
			rm -f $$pod.$(man3ext); \
			if grep '^=head1 NAME$$' $$pm > /dev/null; then \
				echo "GEN $$pod.$(man3ext)"; \
				$(POD2MAN) --section=$(man3ext) \
					--center="sympa $(VERSION)" \
					--lax --release="$(VERSION)" \
					$$pm $$pod.$(man3ext); \
			fi; \
		done; \
	done

install-data-hook: man3pm
	@test -n "$(man3ext)" || exit 0; \
	test -n "$(man3dir)" || exit 0; \
	$(mkdir_p) "$(DESTDIR)$(man3dir)" || exit 1; \
	for pm in $(MAN3PM) $(MAN3POD); do \
		echo "$$pm" | $(SED) -e 's/\.pm$$//' -e 's/\.pod$$//' -e 's/\//::/g' \
		| while read pod; do \
			if grep '^=head1 NAME$$' $$pm > /dev/null; then \
				echo "installing $$pod.$(man3ext)"; \
				$(INSTALL_DATA) "$$pod.$(man3ext)" "$(DESTDIR)$(man3dir)" \
				|| exit $$?; \
			fi; \
		done; \
	done

