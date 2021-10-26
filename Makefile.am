# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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
	t/02_Sympa_DatabaseManager.t \
	t/Language.t \
	t/LockedFile.t \
	t/Regexps.t \
	t/compile_modules.t \
	t/compile_executables.t \
	t/Database_LDAP.t \
	t/parse_templates.t \
	t/pod-syntax.t \
	t/tools_data.t \
	t/tools_file.t \
	t/Tools_Password.t \
	t/Tools_SMIME.t \
	t/Tools_Text.t \
	t/tools_time.t
check_DATA = \
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
	t/stub/Sympa/Constants.pm \
	t/data/sympa.conf \
	t/data/sympa.sqlite \
	t/data/etc/auth.conf \
	xt/perlcriticrc
noinst_SCRIPTS = \
	xt/critic.t \
	xt/fixme.t \
	xt/fixme-todo.t \
	xt/pod-coverage.t \
	xt/pod-spelling.t \
	xt/perltidy.t

EXTRA_DIST = \
	AUTHORS.md \
	CONTRIBUTING.md \
	cpanfile \
	INSTALL.md \
	NEWS.md \
	OChangeLog \
	ONEWS \
	README.md \
	etc_README \
	$(check_SCRIPTS) $(check_DATA) \
	$(noinst_SCRIPTS)

CLEANFILES = sympa_wizard.pl.inst

MSGFMT=@MSGFMT@
.po.mo:
	$(MSGFMT) -o $@ $<

check-local: $(check_DATA)
	[ -z "$(TEST_FILES)" ] && TEST_FILES="$(check_SCRIPTS)"; \
	PERL5LIB=src/lib; export PERL5LIB; \
	$(PERL) -MTest::Harness -e 'runtests @ARGV' $$TEST_FILES

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
		$(sysconfdir); do \
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

sympa_wizard.pl.inst: $(top_srcdir)/src/sbin/sympa_wizard.pl.in Makefile
	$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(top_srcdir)/src/lib|' \
		< $(top_srcdir)/src/sbin/sympa_wizard.pl.in > $@

installconfig: installdir sympa_wizard.pl.inst
	@echo "Installing basic configuration ..."
	-@export PERL5LIB=$(DESTDIR)$(modulesdir); \
	if [ ! -f  $(DESTDIR)$(confdir)/sympa.conf ]; then \
		echo "This looks like your first Sympa installation. The following wizard will assist you to create your first Sympa configuration.";\
		if [ ! -d $(DESTDIR)$(confdir) ]; then \
			$(INSTALL) -d -m 755 $(DESTDIR)$(confdir); \
		fi; \
		chown $(USER) $(DESTDIR)$(confdir); \
		chgrp $(GROUP) $(DESTDIR)$(confdir); \
		$(PERL) sympa_wizard.pl.inst \
			--create sympa.conf \
			--target $(DESTDIR)$(confdir)/sympa.conf; \
		chown $(USER) $(DESTDIR)$(confdir)/sympa.conf; \
		chgrp $(GROUP) $(DESTDIR)$(confdir)/sympa.conf; \
	fi
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
			etc_README > $(DESTDIR)$(sysconfdir)/README; \
		chmod 644 $(DESTDIR)$(sysconfdir)/README; \
	fi
	@$(INSTALL_DATA) cpanfile $(DESTDIR)$(modulesdir)/;

nextstep: 
	@echo ""
	@echo "** You can find documentation at:"
	@echo "** https://sympa-community.github.io/manual/"
	@echo ""
	@echo "#########################################################"
	@echo "# CHECK YOU HAVE ALL THE NEEDED MODULES:"
	@echo "#    * Check the required perl modules are installed:"
	@echo "#        $(sbindir)/sympa_wizard.pl --check"
	@echo "#"
	@echo "# FIRST INSTALLATION:"
	@echo "#    * Check the INSTALL.md file."
	@echo "#    * Run the wizard to define some required parameters that can't be guessed."
	@echo "#        $(sbindir)/sympa_wizard.pl"
	@echo "#"
	@echo "# UPGRADING"
	@echo "#    * Run this script to upgrade your data structures:"
	@echo "#        $(sbindir)/sympa.pl --upgrade"
	@echo "#######################################################"

uninstall-hook:
	rm -f $(DESTDIR)$(confdir)/sympa.conf
	rm -f $(DESTDIR)$(confdir)/wwsympa.conf

dist-hook:
	$(MAKE) check

# tidyall --conf-file doc/dot.tidyallrc --root-dir . --recursive src t xt
tidyall:
	@ ( echo 'exit 1 if grep { $$_->error }'; \
	    echo 'Code::TidyAll->new_from_conf_file('; \
	    echo '  "doc/dot.tidyallrc", root_dir => ".", recursive => 1'; \
	    echo ')->process_paths(qw(src xt t))' \
	) | $(PERL) -MCode::TidyAll
