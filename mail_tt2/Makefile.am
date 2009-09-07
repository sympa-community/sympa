# Makefile - This Makefile does the mail templates installation
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

mailtemplate_DATA = authorization_reject.tt2 \
		    bye.tt2 certif_warning.tt2 \
		    command_report.tt2 \
		    digest_plain.tt2 \
		    digest.tt2 \
		    d_install_shared.tt2 \
		    d_reject_shared.tt2 \
		    expire_deletion.tt2 \
		    expire_warning1.tt2 \
		    expire_warning2.tt2 \
		    get_archive.tt2 \
		    global_remind.tt2 \
		    helpfile.tt2 \
		    index_archive.tt2 \
		    info_report.tt2 \
		    invite.tt2 \
		    list_created.tt2 \
		    listeditor_notification.tt2 \
		    listmaster_notification.tt2 \
		    listowner_notification.tt2 \
		    list_rejected.tt2 \
		    lists.tt2 \
		    list_unknown.tt2 \
		    message_report.tt2 \
		    moderate.tt2 \
		    modindex.tt2 \
		    reject.tt2 \
		    remind.tt2 \
		    removed.tt2 \
		    request_auth.tt2 \
		    review.tt2 \
		    send_auth.tt2 \
		    sendpasswd.tt2 \
		    sendssopasswd.tt2 \
		    stats_report.tt2 \
		    summary.tt2 \
		    urlized_part.tt2 \
		    user_notification.tt2 \
		    welcome.tt2 \
		    which.tt2 \
		    x509-user-cert-missing.tt2 \
		    your_infected_msg.tt2

EXTRA_DIST = $(mailtemplate_DATA)

install-data-hook:
	(cd $(DESTDIR)$(webtemplatedir); \
		rm -f authorization_reject.tt2; \
		$(LN_S) -f ../mail_tt2/authorization_reject.tt2)
