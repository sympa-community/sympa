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

SUBDIRS = script

nobase_default_DATA = list_task_models/expire.yearly.task \
		      list_task_models/remind.2month.task \
		      list_task_models/remind.monthly.task \
		      list_task_models/remind.yearly.task \
		      list_task_models/sync_include.ttl.task \
		      global_task_models/chk_cert_expiration.daily.task \
		      global_task_models/crl_update.daily.task \
		      global_task_models/eval_bouncers.daily.task \
		      global_task_models/expire_bounce.daily.task \
		      global_task_models/process_bouncers.weekly.task \
		      global_task_models/purge_logs_table.daily.task \
		      global_task_models/purge_one_time_ticket_table.daily.task \
		      global_task_models/purge_orphan_bounces.monthly.task \
		      global_task_models/purge_session_table.daily.task \
		      global_task_models/purge_tables.daily.task \
		      global_task_models/purge_user_table.monthly.task \
		      topics.conf nrcpt_by_domain.conf \
		      ldap_alias_manager.conf edit_list.conf \
		      create_list.conf crawlers_detection.conf auth.conf \
		      ca-bundle.crt mhonarc-ressources.tt2 list_aliases.tt2 \
		      create_list_templates/discussion_list/comment.tt2 \
		      create_list_templates/discussion_list/config.tt2 \
		      create_list_templates/hotline/comment.tt2 \
		      create_list_templates/hotline/config.tt2 \
		      create_list_templates/html-news-letter/comment.tt2 \
		      create_list_templates/html-news-letter/config.tt2 \
		      create_list_templates/intranet_list/comment.tt2 \
		      create_list_templates/intranet_list/config.tt2 \
		      create_list_templates/news-letter/comment.tt2 \
		      create_list_templates/news-letter/config.tt2 \
		      create_list_templates/private_working_group/comment.tt2 \
		      create_list_templates/private_working_group/config.tt2 \
		      create_list_templates/public_web_forum/comment.tt2 \
		      create_list_templates/public_web_forum/config.tt2 \
		      families/sample-auto/config.tt2 \
		      families/sample-auto/param_constraint.conf \
		      scenari/access_web_archive.closed \
		      scenari/access_web_archive.intranet \
		      scenari/access_web_archive.listmaster \
		      scenari/access_web_archive.owner \
		      scenari/access_web_archive.private \
		      scenari/access_web_archive.public \
		      scenari/add.auth \
		      scenari/add.closed \
		      scenari/add.owner \
		      scenari/add.owner_notify \
		      scenari/automatic_list_creation.listmaster \
		      scenari/automatic_list_creation.public \
		      scenari/create_list.intranet \
		      scenari/create_list.listmaster \
		      scenari/create_list.public_listmaster \
		      scenari/d_edit.editor \
		      scenari/d_edit.owner \
		      scenari/d_edit.private \
		      scenari/d_edit.private-https \
		      scenari/d_edit.public \
		      scenari/del.auth \
		      scenari/del.closed \
		      scenari/del.owner \
		      scenari/del.owner_notify \
		      scenari/d_read.owner \
		      scenari/d_read.private \
		      scenari/d_read.private-https \
		      scenari/d_read.public \
		      scenari/global_remind.listmaster \
		      scenari/info.open \
		      scenari/info.private \
		      scenari/invite.closed \
		      scenari/invite.owner \
		      scenari/invite.private \
		      scenari/invite.public \
		      scenari/remind.listmaster \
		      scenari/remind.owner \
		      scenari/review.closed \
		      scenari/review.intranet \
		      scenari/review.listmaster \
		      scenari/review.owner \
		      scenari/review.private \
		      scenari/review.public \
		      scenari/send.closed \
		      scenari/send.editorkey \
		      scenari/send.editorkeyonly \
		      scenari/send.editorkeyonlyauth \
		      scenari/send.intranet \
		      scenari/send.intranetorprivate \
		      scenari/send.newsletter \
		      scenari/send.newsletterkeyonly \
		      scenari/send.private \
		      scenari/send.privateandeditorkey \
		      scenari/send.privateandnomultipartoreditorkey \
		      scenari/send.privatekey \
		      scenari/send.privatekeyandeditorkeyonly \
		      scenari/send.privateoreditorkey \
		      scenari/send.privateorpublickey \
		      scenari/send.private_smime \
		      scenari/send.public \
		      scenari/send.publickey \
		      scenari/send.publicnoattachment \
		      scenari/send.public_nobcc \
		      scenari/send.publicnomultipart \
		      scenari/subscribe.auth \
		      scenari/subscribe.auth_notify \
		      scenari/subscribe.auth_owner \
		      scenari/subscribe.closed \
		      scenari/subscribe.intranet \
		      scenari/subscribe.intranetorowner \
		      scenari/subscribe.open \
		      scenari/subscribe.open_notify \
		      scenari/subscribe.open_quiet \
		      scenari/subscribe.owner \
		      scenari/subscribe.smime \
		      scenari/subscribe.smimeorowner \
		      scenari/topics_visibility.conceal \
		      scenari/topics_visibility.identified \
		      scenari/topics_visibility.noconceal \
		      scenari/unsubscribe.auth \
		      scenari/unsubscribe.auth_notify \
		      scenari/unsubscribe.closed \
		      scenari/unsubscribe.open \
		      scenari/unsubscribe.open_notify \
		      scenari/unsubscribe.owner \
		      scenari/visibility.conceal \
		      scenari/visibility.intranet \
		      scenari/visibility.noconceal \
		      scenari/visibility.secret

EXTRA_DIST = $(nobase_default_DATA)

DEFAULT_SCENARIOS = add.owner \
		    d_edit.owner \
		    d_read.private \
		    del.owner \
		    info.open \
		    invite.private \
		    remind.owner \
		    review.owner \
		    send.private \
		    subscribe.open \
		    topics_visibility.noconceal \
		    unsubscribe.open \
		    visibility.conceal

install-data-hook:
	sed -i -e 's|--libexecdir--|$(libexecdir)|' \
		$(DESTDIR)$(defaultdir)/list_aliases.tt2
	cd  $(DESTDIR)$(defaultdir)/scenari; \
	for file in $(DEFAULT_SCENARIOS); do \
		ln -sf $$file `echo $$file | sed -e 's/\.[^.]\+$$/.default/'`; \
	done
