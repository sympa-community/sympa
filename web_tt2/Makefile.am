# Makefile - This Makefile does the web templates installation
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

webtemplate_DATA = active_lists.tt2 \
		   add_request.tt2 \
		   admin_menu.tt2 \
		   admin.tt2 \
		   arc_manage.tt2 \
		   arc_protect.tt2 \
		   arcsearch_form.tt2 \
		   arcsearch.tt2 \
		   arc.tt2 \
		   auto_signoff.tt2 \
		   blacklist.tt2 \
		   button_footer.tt2 \
		   button_header.tt2 \
		   change_email.tt2 \
		   change_email_request.tt2 \
	     	   choosepasswd.tt2 \
		   close_list.tt2 \
		   compose_mail.tt2 \
		   copy_template.tt2 \
		   create_list_request.tt2 \
		   create_list.tt2 \
		   css.tt2 \
		   css_ie.tt2 \
		   d_control.tt2 \
		   d_editfile.tt2 \
		   d_install_shared.tt2 \
		   d_properties.tt2 \
		   d_read.tt2 \
		   dump_scenario.tt2 \
		   dumpvars.tt2 \
		   d_upload.tt2 \
		   edit_attributes.tt2 \
		   editfile.tt2 \
		   edit_list_request.tt2 \
		   editsubscriber.tt2 \
		   edit_template.tt2 \
		   error.tt2 \
		   footer.tt2 \
		   get_closed_lists.tt2 \
		   get_inactive_lists.tt2 \
		   get_latest_lists.tt2 \
		   get_pending_lists.tt2 \
		   help_admin.tt2 \
		   help_arc.tt2 \
		   help_editfile.tt2 \
		   help_editlist.tt2 \
		   help_faqadmin.tt2 \
		   help_faquser.tt2 \
		   help_introduction.tt2 \
		   help_listconfig.tt2 \
		   help_mail_commands.tt2 \
		   help_sendmsg.tt2 \
		   help_shared.tt2 \
		   help.tt2 \
		   help_user_options.tt2 \
		   help_user.tt2 \
		   home.tt2 \
		   info.tt2 \
		   install_pending_list.tt2 \
		   javascript.tt2 \
		   latest_arc.tt2 \
		   latest_d_read.tt2 \
		   latest_lists.tt2 \
		   list_button_footer.tt2 \
		   list_button_header.tt2 \
		   list_menu.tt2 \
		   list_panel.tt2 \
		   lists.tt2 \
		   loginbanner.tt2 \
		   login_menu.tt2 \
		   loginrequest.tt2 \
		   login.tt2 \
		   ls_templates.tt2 \
		   maintenance.tt2 \
		   main.tt2 \
		   manage_template.tt2 \
		   menu.tt2 \
		   menu_search.tt2 \
		   modindex.tt2 \
		   nav.tt2 \
		   notice.tt2 \
		   picture_upload.tt2 \
		   pref.tt2 \
		   remove_arc.tt2 \
		   rename_list_request.tt2 \
		   renewpasswd.tt2 \
		   requestpasswd.tt2 \
		   request_topic.tt2 \
		   reviewbouncing.tt2 \
		   review_family.tt2 \
		   review.tt2 \
		   rss_request.tt2 \
		   rss.tt2 \
		   scenario_test.tt2 \
		   search_user.tt2 \
		   serveradmin.tt2 \
		   setlang.tt2 \
		   set_pending_list_request.tt2 \
		   show_cert.tt2 \
		   show_exclude.tt2 \
		   show_sessions.tt2 \
		   sigrequest.tt2 \
		   skinsedit.tt2 \
		   sso_login.tt2 \
		   stats.tt2 \
		   subindex.tt2 \
		   suboptions.tt2 \
		   subrequest.tt2 \
		   subscriber_table.tt2 \
		   suspend_request.tt2 \
		   ticket.tt2 \
		   title.tt2 \
		   tt2_error.tt2 \
		   viewbounce.tt2 \
		   viewlogs.tt2 \
		   viewmod.tt2 \
		   view_template.tt2 \
		   your_lists.tt2

EXTRA_DIST = $(webtemplate_DATA)

install-data-hook:
	cd $(DESTDIR)$(webtemplatedir); \
	$(LN_S) -f review.tt2 search.tt2; \
	$(LN_S) -f lists.tt2 which.tt2; \
	$(LN_S) -f lists.tt2 search_list.tt2
