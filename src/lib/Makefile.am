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

nobase_modules_DATA = admin.pm Archive.pm Bulk.pm Commands.pm confdef.pm \
		      Conf.pm Config_XML.pm Family.pm Language.pm \
		      List.pm Sympa/LockedFile.pm Log.pm mail.pm Ldap.pm \
		      Upgrade.pm Sympa/User.pm \
		      Fetch.pm Message.pm Task.pm Datasource.pm SQLSource.pm \
		      LDAPSource.pm Scenario.pm PlainDigest.pm report.pm \
		      tools.pm tt2.pm Sympa/Constants.pm \
		      Sympa/Template/Compat.pm Robot.pm WebAgent.pm \
		      HTML/myFormatText.pm tracking.pm \
		      Sympa/DatabaseDescription.pm SDM.pm \
		      DBManipulatorMySQL.pm DBManipulatorSQLite.pm\
		      DBManipulatorSybase.pm DBManipulatorOracle.pm \
		      DBManipulatorPostgres.pm DBManipulatorDefault.pm \
		      OAuthConsumer.pm VOOTConsumer.pm OAuthProvider.pm \
		      VOOTProvider.pm

EXTRA_DIST = Sympa/Constants.pm.in $(nobase_modules_DATA)
CLEANFILES = Sympa/Constants.pm

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
