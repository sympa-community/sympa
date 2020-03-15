# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

SUBDIRS = src default doc po www

check_SCRIPTS = \
	t/01_Conf.t \
	t/Config_XML.t \
	t/DataSource_LDAP2.t \
	t/DatabaseManager.t \
	t/Database_LDAP.t \
	t/Language.t \
	t/LockedFile.t \
	t/Message_smime.t \
	t/Message_urlize.t \
	t/Regexps.t \
	t/Scenario.t \
	t/Tools_Data.t \
	t/Tools_File.t \
	t/Tools_Password.t \
	t/Tools_SMIME.t \
	t/Tools_Text.t \
	t/Tools_Time.t \
	t/WWW_Tools.t \
	t/compile_executables.t \
	t/compile_modules.t \
	t/compile_scenarios.t \
	t/parse_templates.t \
	t/pod-syntax.t
check_DATA = \
	src/lib/Sympa/Test/MockLDAP.pm \
	t/data/list_data/test/config \
	t/data/sympa.conf \
	t/data/sympa.sqlite \
	t/data/etc/auth.conf \
	t/locale/cs/LC_MESSAGES/sympa.mo \
	t/locale/cs/LC_MESSAGES/web_help.mo \
	t/locale/zh_TW/LC_MESSAGES/sympa.mo \
	t/pki/cnf/ca.cnf \
	t/pki/cnf/rousse.cnf \
	t/pki/crt/ca.pem \
	t/pki/crt/rousse.pem \
	t/pki/key/ca.pem \
	t/pki/key/rousse_nopassword.pem \
	t/pki/key/rousse_password.pem \
	t/samples/urlize-deep-nested-mixed.eml \
	t/samples/urlize-encoding.eml \
	t/samples/urlize-nested-alternative-and-related.eml \
	t/samples/urlize-nested-alternative.eml \
	t/samples/urlize-nested-mixed.eml \
	t/samples/urlize-nested-mutiple-attachments.eml \
	t/samples/urlize-simple-mutiple-attachments.eml \
	t/samples/urlize-simple.eml \
	t/samples/signed.eml \
	t/samples/unsigned.eml \
	t/stub/Sympa/Constants.pm \
	xt/perlcriticrc
noinst_SCRIPTS = \
	xt/critic.t \
	xt/fixme.t \
	xt/fixme-todo.t \
	xt/pod-coverage.t \
	xt/pod-spelling.t \
	xt/perltidy.t
nobase_modules_DATA = \
	cpanfile

EXTRA_DIST = \
	AUTHORS.md \
	CONTRIBUTING.md \
	INSTALL.md \
	NEWS.md \
	OChangeLog \
	ONEWS \
	README.md \
	etc_README \
	$(check_SCRIPTS) $(check_DATA) \
	$(noinst_SCRIPTS) \
	$(nobase_modules_DATA)

CLEANFILES = \
	sympa.conf-dist

MSGFMT=@MSGFMT@
.po.mo:
	$(MSGFMT) -o $@ $<

# Skip this with "make distcheck"
check-local: $(check_DATA)
	if test -d t; then \
		[ -z "$(TEST_FILES)" ] && TEST_FILES="$(check_SCRIPTS)"; \
		PERL5LIB=src/lib; export PERL5LIB; \
		$(PERL) -MTest::Harness -e 'runtests @ARGV' $$TEST_FILES; \
	fi

authorcheck:
	[ -z "$(TEST_FILES)" ] && TEST_FILES="$(noinst_SCRIPTS)"; \
	PERL5LIB=src/lib; export PERL5LIB; \
	$(PERL) -MTest::Harness -e 'runtests @ARGV' $$TEST_FILES

install-data-hook: installdir installconfig nextstep

installdir:
	@echo "Creating plugin directory"
	@for dir in $(modulesdir)/Sympa/Template/Plugin; do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$$dir; \
		fi; \
	done
	@echo "Creating writable directories"
	-@for dir in $(expldir) $(spooldir) $(bouncedir) $(arcdir) $(piddir) \
		$(confdir) $(sysconfdir); do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$$dir; \
		chgrp $(GROUP) $(DESTDIR)$$dir; \
	done
	-@for subdir in automatic bounce msg task tmp; do \
		if [ ! -d $(DESTDIR)$(spooldir)/$$subdir ] ; then \
			echo "Creating $(DESTDIR)$(spooldir)/$$subdir"; \
			$(INSTALL) -d -m 750 $(DESTDIR)$(spooldir)/$$subdir; \
		fi; \
		chown $(USER) $(DESTDIR)$(spooldir)/$$subdir; \
		chgrp $(GROUP) $(DESTDIR)$(spooldir)/$$subdir; \
	done

installconfig: installdir
	@echo "Installing basic configuration ..."
	-@if [ ! -f  $(DESTDIR)$(confdir)/sympa.conf ]; then \
		echo "installing sympa.conf"; \
		$(INSTALL) -m 640 sympa.conf $(DESTDIR)$(confdir); \
		chown $(USER) $(DESTDIR)$(confdir)/sympa.conf; \
		chgrp $(GROUP) $(DESTDIR)$(confdir)/sympa.conf; \
	fi
	@echo "Installing configuration template ..."
	-@echo "installing sympa.conf-dist"; \
	$(INSTALL) -m 644 -T sympa.conf-dist $(DESTDIR)$(confdir)/sympa.conf-dist; \
	chown $(USER) $(DESTDIR)$(confdir)/sympa.conf-dist; \
	chgrp $(GROUP) $(DESTDIR)$(confdir)/sympa.conf-dist
	-@if [ ! -f $(DESTDIR)$(sysconfdir)/data_structure.version ]; then \
		cd $(DESTDIR)$(sysconfdir); \
		echo "# automatically created file" >> data_structure.version; \
		echo "# you should not modify it" >> data_structure.version; \
		echo $(VERSION) >> data_structure.version; \
		chown $(USER) data_structure.version; \
		chgrp $(GROUP) data_structure.version; \
	fi
	-@for dir in create_list_templates custom_actions custom_conditions \
		data_sources families tasks \
		mail_tt2 scenari search_filters web_tt2; do \
		if [ ! -d $(DESTDIR)$(sysconfdir)/$$dir ] ; then \
			echo "Creating $(DESTDIR)$(sysconfdir)/$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$(sysconfdir)/$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$(sysconfdir)/$$dir; \
		chgrp $(GROUP) $(DESTDIR)$(sysconfdir)/$$dir; \
	done
	@if [ ! -e $(DESTDIR)$(sysconfdir)/README ]; then \
		echo "Creating $(DESTDIR)$(sysconfdir)/README"; \
		$(SED) \
			-e 's|--sysconfdir--|$(sysconfdir)|' \
			-e 's|--defaultdir--|$(defaultdir)|' \
			$(srcdir)/etc_README > $(DESTDIR)$(sysconfdir)/README; \
		chmod 644 $(DESTDIR)$(sysconfdir)/README; \
	fi

nextstep: 
	@echo ""
	@echo "** You can find documentation at:"
	@echo "** https://sympa-community.github.io/manual/"
	@echo ""
	@echo "#########################################################"
	@echo "# CHECK YOU HAVE ALL THE NEEDED MODULES:"
	@echo "#    * Install or upgrade required perl modules. If you have cpanminus:"
	@echo "#        cpanm --installdeps --with-recommends ."
	@echo "#"
	@echo "# FIRST INSTALLATION:"
	@echo "#    * Edit this file to define initial configuration:"
	@echo "#        $(confdir)/sympa.conf"
	@echo "#"
	@echo "# ADDITIONAL SETTINGS:"
	@echo "#    * You will find all available configuration settings in:"
	@echo "#        $(confdir)/sympa.conf-dist"
	@echo "#"
	@echo "#    * Copy the configuration settings you want in:"
	@echo "#        $(confdir)/sympa.conf"
	@echo "#"
	@echo "# UPGRADING"
	@echo "#    * Run this script to upgrade your data structures:"
	@echo "#        $(sbindir)/sympa.pl --upgrade"
	@echo "#######################################################"

uninstall-hook:
	cd $(DESTDIR)$(confdir) && rm -f sympa.conf
	cd $(DESTDIR)$(confdir) && rm -f sympa.conf-dist
	cd $(DESTDIR)$(confdir) && rm -f wwsympa.conf
	cd $(DESTDIR)$(sysconfdir) && rm -f data_structure.version
	cd $(DESTDIR)$(sysconfdir) && rm -f README

DISTCHECK_CONFIGURE_FLAGS = --enable-fhs --with-perl=$(PERL)

dist-hook:
	$(MAKE) check

distcheck-hook:
	-md5sum $(DIST_ARCHIVES) > $(DIST_ARCHIVES).md5
	-sha256sum $(DIST_ARCHIVES) > $(DIST_ARCHIVES).sha256
	-openssl sha512 $(DIST_ARCHIVES) > $(DIST_ARCHIVES).sha512

tidyall:
	tidyall --conf-file doc/dot.tidyallrc --root-dir . -r src t xt

all-local: sympa.conf-dist

sympa.conf-dist:
	@PERL5LIB=$(srcdir)/src/lib; export PERL5LIB; \
	$(PERL) mk-sympa-dist.pl

