# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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
if SMTPC
SUBDIRS += src/smtpc
endif

check_SCRIPTS = \
	t/Language.t \
	t/LockedFile.t \
	t/Regexps.t \
	t/compile_modules.t \
	t/compile_executables.t \
	t/Database_SQLite.t \
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
	xt/perlcriticrc
noinst_SCRIPTS = \
	xt/critic.t \
	xt/fixme.t \
	xt/fixme-todo.t \
	xt/pod-coverage.t \
	xt/pod-spelling.t

EXTRA_DIST = \
	important_changes.pl \
	META.json.pl \
	META.json \
	sympa.spec.pl \
	sympa.spec \
	etc_README \
	$(check_SCRIPTS) $(check_DATA) \
	$(noinst_SCRIPTS)

CLEANFILES = META.json previous_sympa_version sympa.spec sympa_wizard.pl.inst

MSGFMT=@MSGFMT@
.po.mo:
	$(MSGFMT) -o $@ $<

check-local:
	[ -z "$(TEST_FILES)" ] && TEST_FILES="$(check_SCRIPTS)"; \
	PERL5LIB=src/lib; export PERL5LIB; \
	$(PERL) -MTest::Harness -e 'runtests @ARGV' $$TEST_FILES

authorcheck:
	[ -z "$(TEST_FILES)" ] && TEST_FILES="$(noinst_SCRIPTS)"; \
	PERL5LIB=src/lib; export PERL5LIB; \
	$(PERL) -MTest::Harness -e 'runtests @ARGV' $$TEST_FILES

install-data-hook: installdir installconfig nextstep importantchanges
if SMTPC
	-chown $(USER) $(DESTDIR)$(libexecdir)/sympa_smtpc
	-chgrp $(GROUP) $(DESTDIR)$(libexecdir)/sympa_smtpc
	-chmod 750 $(DESTDIR)$(libexecdir)/sympa_smtpc
endif

installdir:
	@echo "Creating plugin directory"
	@for dir in $(modulesdir)/Sympa/Template/Plugin; do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$$dir; \
		fi; \
	done
	@echo "Creating writable directories"
	@for dir in $(expldir) $(spooldir) $(spooldir)/msg $(spooldir)/digest \
		$(spooldir)/moderation $(spooldir)/auth \
		$(spooldir)/outgoing $(spooldir)/tmp $(spooldir)/task \
		$(spooldir)/bulk \
		$(bouncedir) $(arcdir) $(piddir) $(staticdir) $(staticdir)/js $(sysconfdir); do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$$dir || /bin/true; \
		chgrp $(GROUP) $(DESTDIR)$$dir || /bin/true; \
	done

sympa_wizard.pl.inst: $(top_srcdir)/src/sbin/sympa_wizard.pl.in Makefile
	$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(top_srcdir)/src/lib|' \
		< $(top_srcdir)/src/sbin/sympa_wizard.pl.in > $@

installconfig: installdir sympa_wizard.pl.inst
	@echo "Installing basic configuration ..."
	export PERL5LIB=$(DESTDIR)$(modulesdir); \
	if [ ! -f  $(DESTDIR)$(confdir)/sympa.conf ]; then \
		echo "This looks like your first Sympa installation. The following wizard will assist you to create your first Sympa configuration.";\
		if [ ! -d $(DESTDIR)$(confdir) ]; then \
			$(INSTALL) -d -m 755 $(DESTDIR)$(confdir); \
		fi; \
		chown $(USER) $(DESTDIR)$(confdir) || /bin/true; \
		chgrp $(GROUP) $(DESTDIR)$(confdir) || /bin/true; \
		$(PERL) sympa_wizard.pl.inst \
			--create sympa.conf \
			--target $(DESTDIR)$(confdir)/sympa.conf \
			|| /bin/true; \
		chown $(USER) $(DESTDIR)$(confdir)/sympa.conf || /bin/true; \
		chgrp $(GROUP) $(DESTDIR)$(confdir)/sympa.conf || /bin/true; \
	fi; \
	if [ ! -f $(DESTDIR)$(sysconfdir)/data_structure.version ]; then \
		cd $(DESTDIR)$(sysconfdir); \
		echo "# automatically created file" >> data_structure.version; \
		echo "# you should not modify it" >> data_structure.version; \
		echo $(VERSION) >> data_structure.version; \
		chown $(USER) data_structure.version || /bin/true; \
		chgrp $(GROUP) data_structure.version || /bin/true; \
	fi
	@for dir in create_list_templates custom_actions custom_conditions \
		data_sources families global_task_models list_task_models \
		mail_tt2 scenari search_filters web_tt2; do \
		if [ ! -d $(DESTDIR)$(sysconfdir)/$$dir ] ; then \
			echo "Creating $(DESTDIR)$(sysconfdir)/$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$(sysconfdir)/$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$(sysconfdir)/$$dir || /bin/true; \
		chgrp $(GROUP) $(DESTDIR)$(sysconfdir)/$$dir || /bin/true; \
	done
	@if [ ! -e $(DESTDIR)$(sysconfdir)/README ]; then \
		echo "Creating $(DESTDIR)$(sysconfdir)/README"; \
		$(SED) \
			-e 's|--sysconfdir--|$(sysconfdir)|' \
			-e 's|--defaultdir--|$(defaultdir)|' \
			etc_README > $(DESTDIR)$(sysconfdir)/README; \
		chmod 444 $(DESTDIR)$(sysconfdir)/README; \
	fi

nextstep: 
	@echo ""
	@echo "** You can find documentation at:"
	@echo "** http://www.sympa.org/documentation/manual/sympa-$(VERSION).pdf"
	@echo ""
	@echo "#########################################################"
	@echo "# CHECK YOU HAVE ALL THE NEEDED MODULES:"
	@echo "#    * Check the required perl modules are installed:"
	@echo "#        $(sbindir)/sympa_wizard.pl --check"
	@echo "#"
	@echo "# FIRST INSTALLATION:"
	@echo "#    * Check the INSTALL file."
	@echo "#    * Run the wizard to define some required parameters that can't be guessed."
	@echo "#        $(sbindir)/sympa_wizard.pl"
	@echo "#"
	@echo "# UPGRADING"
	@echo "#    * Run this script to upgrade your data structures:"
	@echo "#        $(sbindir)/sympa.pl --upgrade"
	@echo "#######################################################"

importantchanges:
	if test -f $(top_srcdir)/previous_sympa_version; then \
		export PREVIOUS=`$(CAT) $(top_srcdir)/previous_sympa_version`; \
	fi; \
	$(PERL) $(top_srcdir)/important_changes.pl \
		--current=$(VERSION) \
		--previous=$${PREVIOUS};

uninstall-hook:
	rm -f $(DESTDIR)$(confdir)/sympa.conf
	rm -f $(DESTDIR)$(confdir)/wwsympa.conf

dist-hook:
	$(MAKE) check

META.json: META.json.pl Makefile src/lib/Sympa/ModDef.pm
	cd src/lib; $(MAKE) Sympa/Constants.pm
	$(PERL) META.json.pl > META.json

sympa.spec: sympa.spec.pl Makefile src/lib/Sympa/ModDef.pm
	cd src/lib; $(MAKE) Sympa/Constants.pm
	$(PERL) sympa.spec.pl > sympa.spec

