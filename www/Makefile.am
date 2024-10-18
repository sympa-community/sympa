# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2023 The Sympa Community. See the
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

nobase_static_DATA = \
	fonts/font-awesome/LICENSE.txt \
	fonts/font-awesome/css/brands.css \
	fonts/font-awesome/css/brands.min.css \
	fonts/font-awesome/css/fontawesome.css \
	fonts/font-awesome/css/fontawesome.min.css \
	fonts/font-awesome/css/regular.css \
	fonts/font-awesome/css/regular.min.css \
	fonts/font-awesome/css/solid.css \
	fonts/font-awesome/css/solid.min.css \
	fonts/font-awesome/webfonts/fa-brands-400.ttf \
	fonts/font-awesome/webfonts/fa-brands-400.woff2 \
	fonts/font-awesome/webfonts/fa-regular-400.ttf \
	fonts/font-awesome/webfonts/fa-regular-400.woff2 \
	fonts/font-awesome/webfonts/fa-solid-900.ttf \
	fonts/font-awesome/webfonts/fa-solid-900.woff2 \
	fonts/Raleway/OFL.txt \
	fonts/Raleway/Raleway-Regular.otf \
	icons/favicon_sympa.png \
	icons/logo_sympa.png \
	js/foundation/css/foundation-float.css \
	js/foundation/css/foundation-float.min.css \
	js/foundation/js/foundation.js \
	js/foundation/js/foundation.min.js \
	js/foundation/js/vendor/what-input.js \
	js/html5shiv/html5shiv.js \
	js/jqplot/jqplot.barRenderer.min.js \
	js/jqplot/jqplot.canvasAxisTickRenderer.min.js \
	js/jqplot/jqplot.canvasTextRenderer.min.js \
	js/jqplot/jqplot.categoryAxisRenderer.min.js \
	js/jqplot/jquery.jqplot.css \
	js/jqplot/jquery.jqplot.min.js \
	js/jquery.js \
	js/jquery-migrate.js \
	js/jquery-minicolors/jquery.minicolors.css \
	js/jquery-minicolors/jquery.minicolors.js \
	js/jquery-minicolors/jquery.minicolors.min.js \
	js/jquery-minicolors/jquery.minicolors.png \
	js/jquery-ui/LICENSE.txt \
	js/jquery-ui/images/ui-bg_flat_0_aaaaaa_40x100.png \
	js/jquery-ui/images/ui-bg_flat_75_ffffff_40x100.png \
	js/jquery-ui/images/ui-bg_glass_55_fbf9ee_1x400.png \
	js/jquery-ui/images/ui-bg_glass_65_ffffff_1x400.png \
	js/jquery-ui/images/ui-bg_glass_75_dadada_1x400.png \
	js/jquery-ui/images/ui-bg_glass_75_e6e6e6_1x400.png \
	js/jquery-ui/images/ui-bg_glass_95_fef1ec_1x400.png \
	js/jquery-ui/images/ui-bg_highlight-soft_75_cccccc_1x100.png \
	js/jquery-ui/images/ui-icons_222222_256x240.png \
	js/jquery-ui/images/ui-icons_2e83ff_256x240.png \
	js/jquery-ui/images/ui-icons_444444_256x240.png \
	js/jquery-ui/images/ui-icons_454545_256x240.png \
	js/jquery-ui/images/ui-icons_555555_256x240.png \
	js/jquery-ui/images/ui-icons_777620_256x240.png \
	js/jquery-ui/images/ui-icons_777777_256x240.png \
	js/jquery-ui/images/ui-icons_888888_256x240.png \
	js/jquery-ui/images/ui-icons_cc0000_256x240.png \
	js/jquery-ui/images/ui-icons_cd0a0a_256x240.png \
	js/jquery-ui/images/ui-icons_ffffff_256x240.png \
	js/jquery-ui/jquery-ui.css \
	js/jquery-ui/jquery-ui.js \
	js/respondjs/respond.min.js \
	js/sympa.js

EXTRA_DIST = $(nobase_static_DATA)

install-data-hook:
	@echo "Creating static_content directory"
	-@for dir in $(staticdir); do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			$(INSTALL) -d -m 644 $(DESTDIR)$$dir; \
		fi; \
	done
	@echo "Creating writable directories"
	-@for dir in $(cssdir) $(picturesdir); do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			$(INSTALL) -d -m 755 $(DESTDIR)$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$$dir; \
		chgrp $(GROUP) $(DESTDIR)$$dir; \
	done

