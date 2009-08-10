# Makefile.am - Top-level Makefile.am for Sympa
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

SUBDIRS = src wwsympa soap web_tt2 mail_tt2 doc po po-wwsympa

EXTRA_DIST = important_changes.pl \
	     sympa.spec.in \
	     sympa.spec \
	     README.charset

install-data-hook: installdir installconfig nextstep importantchanges

installdir:
	@echo "Creating writable directories"
	@for dir in $(expldir) $(spooldir) $(spooldir)/msg $(spooldir)/digest \
		$(spooldir)/moderation $(spooldir)/expire $(spooldir)/auth \
		$(spooldir)/outgoing $(spooldir)/tmp $(spooldir)/task \
		$(bouncedir) $(arcdir) $(piddir) $(staticdir) $(sysconfdir); do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			install -d -m 755 $(DESTDIR)$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$$dir || /bin/true; \
		chgrp $(GROUP) $(DESTDIR)$$dir || /bin/true; \
	done

installconfig: installdir
	@echo "Installing basic configuration ..."
	export PERL5LIB=$(DESTDIR)$(modulesdir); \
	if [ ! -f  $(DESTDIR)$(confdir)/sympa.conf ]; then \
		echo "This looks like your first Sympa installation. The following wizard will assist you to create your first Sympa configuration.";\
		$(DESTDIR)$(sbindir)/sympa_wizard.pl \
			--create sympa.conf \
			--target $(DESTDIR)$(confdir)/sympa.conf \
			|| /bin/true; \
		$(DESTDIR)$(sbindir)/sympa_wizard.pl \
			--create wwsympa.conf \
			--target $(DESTDIR)$(confdir)/wwsympa.conf \
			|| /bin/true; \
	fi; \
	if [ ! -f $(DESTDIR)$(sysconfdir)/sympa/data_structure.version ]; then \
		cd $(DESTDIR)$(sysconfdir)/sympa; \
		echo "# automatically created file" >> data_structure.version; \
		echo "# you should not modify it" >> data_structure.version; \
		echo $(VERSION) >> data_structure.version; \
		chown $(USER) data_structure.version || /bin/true; \
		chgrp $(GROUP) data_structure.version || /bin/true; \
	fi

nextstep: 
	@echo ""
	@echo "** You can find documentation at:"
	@echo "** http://www.sympa.org/documentation/manual/sympa-$(VERSION).pdf"
	@echo ""
	@echo "#########################################################"
	@echo "# If you are installing, you should check the INSTALL file"
	@echo "# and run the installation wizard:"
	@echo "# $(sbindir)/sympa_wizard.pl"
	@echo "#"
	@echo "# If you are upgrading, you just need to run"
	@echo "# $(sbindir)/sympa.pl --upgrade"
	@echo "#"
	@echo "# In both case, you should run the wizard to check you"
	@echo "# have all perl modules needed:"
	@echo "# $(sbindir)/sympa_wizard.pl --check"
	@echo "#######################################################"

importantchanges:
	if [ -f $(DESTDIR)$(modulesdir)/Constants.pm ]; then \
		previous=`perl -Mlib=$(DESTDIR)$(modulesdir) -MVersion -e 'print Sympa::Constants::VERSION'`; \
        elif [ -f $(DESTDIR)$(bindir)/Version.pm ]; then \
                previous=`perl -Mlib=$(DESTDIR)$(bindir) -MVersion -e 'print $$Version::Version'`; \
	fi; \
	$(PERL) $(top_srcdir)/important_changes.pl \
		--current=$(VERSION) \
		--previous=$${previous};

uninstall-hook:
	rm -f $(DESTDIR)$(confdir)/sympa.conf
	rm -f $(DESTDIR)$(confdir)/wwsympa.conf
