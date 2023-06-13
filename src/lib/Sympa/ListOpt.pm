# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2021, 2022 The Sympa Community. See the
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

package Sympa::ListOpt;

use strict;
use warnings;

# List parameter values except for parameters below.
our %list_option = (

    # reply_to_header.apply
    'forced'  => {'gettext_id' => 'overwrite Reply-To: header field'},
    'respect' => {'gettext_id' => 'preserve existing header field'},

    # reply_to_header.value, antivirus_notify
    'sender' => {'gettext_id' => 'sender'},

    # reply_to_header.value, include_remote_sympa_list.cert
    'list' => {'gettext_id' => 'list'},

    # include_ldap_2level_query.select2, include_ldap_2level_query.select1,
    # include_ldap_query.select, reply_to_header.value, dmarc_protection.mode,
    # personalization.web_apply_on, personalization.mail_apply_on
    'all' => {'gettext_id' => 'all'},

    # reply_to_header.value
    'other_email' => {'gettext_id' => 'other email address'},

    # msg_topic_keywords_apply_on
    'subject'          => {'gettext_id' => 'subject field'},
    'body'             => {'gettext_id' => 'message body'},
    'subject_and_body' => {'gettext_id' => 'subject and body'},

    # personalization.web_apply_on, personalization.mail_apply_on
    'footer' => {'gettext_id' => 'header and footer'},

    # bouncers_level2.notification, bouncers_level2.action,
    # bouncers_level1.notification, bouncers_level1.action,
    # spam_protection, dkim_signature_apply_on, web_archive_spam_protection,
    # dmarc_protection.mode, automatic_list_removal,
    # personalization.web_apply_on, personalization.mail_apply_on
    'none' => {'gettext_id' => 'do nothing'},

    # automatic_list_removal
    'if_epmty' => {'gettext_id' => 'if no list members contained'},

    # bouncers_level2.notification, bouncers_level1.notification,
    # rfc2369_header_fields, archive.mail_access
    'owner' => {'gettext_id' => 'owner'},

    # bouncers_level2.notification, bouncers_level1.notification
    'listmaster' => {'gettext_id' => 'listmaster'},

    # bouncers_level2.action, bouncers_level1.action
    'remove_bouncers' => {'gettext_id' => 'remove bouncing users'},
    'notify_bouncers' => {'gettext_id' => 'send notify to bouncing users'},

    # pictures_feature, dkim_feature, personalization_feature,
    # inclusion_notification_feature, tracking.delivery_status_notification,
    # tracking.message_disposition_notification
    'on' => {'gettext_id' => 'enabled'},
    # pictures_feature, dkim_feature, personalization_feature,
    # inclusion_notification_feature, tracking.delivery_status_notification,
    # tracking.message_disposition_notification, update_db_field_types
    'off' => {'gettext_id' => 'disabled'},
    # update_db_field_types
    'auto' => {'gettext_id' => 'automatic'},

    # include_remote_sympa_list.cert
    'robot' => {'gettext_id' => 'robot'},

    # include_ldap_2level_query.select2, include_ldap_2level_query.select1,
    # include_ldap_query.select
    'first' => {'gettext_id' => 'first entry'},

    # include_ldap_2level_query.select2, include_ldap_2level_query.select1
    'regex' => {'gettext_id' => 'entries matching regular expression'},

    # include_ldap_2level_query.scope2, include_ldap_2level_query.scope1,
    # include_ldap_query.scope
    'base' => {'gettext_id' => 'base'},
    'one'  => {'gettext_id' => 'one level'},
    'sub'  => {'gettext_id' => 'subtree'},

    # include_ldap_query.use_tls, include_ldap_2level_query.use_tls,
    # include_ldap_ca.use_tls, include_ldap_2level_ca.use_tls
    'starttls' => {'gettext_id' => 'use STARTTLS'},
    'ldaps'    => {'gettext_id' => 'use LDAPS (LDAP over TLS)'},

    ## include_ldap_2level_query.use_ssl, include_ldap_query.use_ssl
    #'yes' => {'gettext_id' => 'yes'},
    #'no'  => {'gettext_id' => 'no'},

    # include_ldap_2level_query.ssl_version, include_ldap_query.ssl_version
    'ssl_any' => {'gettext_id' => 'any versions'},
    'sslv2'   => {'gettext_id' => 'SSL version 2'},
    'sslv3'   => {'gettext_id' => 'SSL version 3'},
    'tlsv1'   => {'gettext_id' => 'TLS version 1'},
    'tlsv1_1' => {'gettext_id' => 'TLS version 1.1'},
    'tlsv1_2' => {'gettext_id' => 'TLS version 1.2'},
    'tlsv1_3' => {'gettext_id' => 'TLS version 1.3'},

    # editor.reception, owner_include.reception, owner.reception,
    # editor_include.reception
    'mail'   => {'gettext_id' => 'receive notification email'},
    'nomail' => {'gettext_id' => 'no notifications'},

    # editor.visibility, owner_include.visibility, owner.visibility,
    # editor_include.visibility
    'conceal'   => {'gettext_id' => 'concealed from list menu'},
    'noconceal' => {'gettext_id' => 'listed on the list menu'},

    # antivirus_notify
    'delivery_status' => {'gettext_id' => 'send back DSN'},

    # owner_include.profile, owner.profile
    'privileged' => {'gettext_id' => 'privileged owner'},
    'normal'     => {'gettext_id' => 'normal owner'},

    # priority
    '0' => {'gettext_id' => '0 - highest priority'},
    '9' => {'gettext_id' => '9 - lowest priority'},
    'z' => {'gettext_id' => 'queue messages only'},

    # spam_protection, web_archive_spam_protection
    'at'         => {'gettext_id' => 'replace @ characters'},
    'javascript' => {'gettext_id' => 'use JavaScript'},

    # msg_topic_tagging
    'required_sender' => {'gettext_id' => 'required to post message'},
    'required_moderator' =>
        {'gettext_id' => 'required to distribute message'},

    # msg_topic_tagging, custom_attribute.optional
    'optional' => {'gettext_id' => 'optional'},

    # custom_attribute.optional
    'required' => {'gettext_id' => 'required'},

    # custom_attribute.type
    'string'  => {'gettext_id' => 'string'},
    'text'    => {'gettext_id' => 'multi-line text'},
    'integer' => {'gettext_id' => 'number'},
    'enum'    => {'gettext_id' => 'set of keywords'},

    # footer_type
    'mime'   => {'gettext_id' => 'add a new MIME part'},
    'append' => {'gettext_id' => 'append to message body'},

    # archive.mail_access
    'open'    => {'gettext_id' => 'open'},
    'closed'  => {'gettext_id' => 'closed'},
    'private' => {'gettext_id' => 'subscribers only'},
    'public'  => {'gettext_id' => 'public'},

##    ## user_data_source
##    'database' => {'gettext_id' => 'RDBMS'},
##    'file'     => {'gettext_id' => 'include from local file'},
##    'include'  => {'gettext_id' => 'include from external source'},
##    'include2' => {'gettext_id' => 'general datasource'},

    # rfc2369_header_fields
    'help'        => {'gettext_id' => 'help'},
    'subscribe'   => {'gettext_id' => 'subscription'},
    'unsubscribe' => {'gettext_id' => 'unsubscription'},
    'post'        => {'gettext_id' => 'posting address'},
    'archive'     => {'gettext_id' => 'list archive'},

    # dkim_signature_apply_on
    'md5_authenticated_messages' =>
        {'gettext_id' => 'authenticated by password'},
    'smime_authenticated_messages' =>
        {'gettext_id' => 'authenticated by S/MIME signature'},
    'dkim_authenticated_messages' =>
        {'gettext_id' => 'with successfully verified DKIM signature'},
    'editor_validated_messages' => {'gettext_id' => 'approved by moderator'},
    'any'                       => {'gettext_id' => 'any messages'},

    # archive.period
    'day'     => {'gettext_id' => 'daily'},
    'week'    => {'gettext_id' => 'weekly'},
    'month'   => {'gettext_id' => 'monthly'},
    'quarter' => {'gettext_id' => 'quarterly'},
    'year'    => {'gettext_id' => 'yearly'},

    # web_archive_spam_protection
    'cookie'    => {'gettext_id' => 'use HTTP cookie'},
    'concealed' => {'gettext_id' => 'never show address'},

    # verp_rate
    '100%' => {'gettext_id' => '100% - always'},
    '0%'   => {'gettext_id' => '0% - never'},

    # archive_crypted_msg
    'original'  => {'gettext_id' => 'original messages'},
    'decrypted' => {'gettext_id' => 'decrypted messages'},

    # tracking.message_disposition_notification
    'on_demand' => {'gettext_id' => 'on demand'},

    # dmarc_protection.mode
    'dkim_signature' => {'gettext_id' => 'DKIM signature exists'},
    'dmarc_any'      => {'gettext_id' => 'DMARC policy exists'},
    'dmarc_reject'   => {'gettext_id' => 'DMARC policy suggests rejection'},
    'dmarc_quarantine' =>
        {'gettext_id' => 'DMARC policy suggests quarantine'},
    'domain_regex' => {'gettext_id' => 'domain matching regular expression'},

    # dmarc_protection.phrase
    'display_name'        => {'gettext_id' => '"Name"'},
    'name_and_email'      => {'gettext_id' => '"Name" (e-mail)'},
    'name_via_list'       => {'gettext_id' => '"Name" (via List)'},
    'name_email_via_list' => {'gettext_id' => '"Name" (e-mail via List)'},
    'list_for_email'      => {'gettext_id' => '"List" (on behalf of e-mail)'},
    'list_for_name'       => {'gettext_id' => '"List" (on behalf of Name)'},

    # cache_list_config
    'binary_file' => {'gettext_id' => 'use binary file'},
);

# Values for subscriber reception mode.
our %reception_mode = (
    'mail'        => {'gettext_id' => 'standard (direct reception)'},
    'digest'      => {'gettext_id' => 'digest MIME format'},
    'digestplain' => {'gettext_id' => 'digest plain text format'},
    'summary'     => {'gettext_id' => 'summary mode'},
    'notice'      => {'gettext_id' => 'notice mode'},
    'txt'         => {'gettext_id' => 'text-only mode'},
    'urlize'      => {'gettext_id' => 'urlize mode'},
    'nomail'      => {'gettext_id' => 'no mail'},
    'not_me'      => {'gettext_id' => 'not receiving your own posts'}
);

# Values for subscriber visibility mode.
our %visibility_mode = (
    'noconceal' => {'gettext_id' => 'listed in the list review page'},
    'conceal'   => {'gettext_id' => 'concealed'}
);

# Values for list status.
our %list_status = (
    'open'          => {'gettext_id' => 'in operation'},
    'pending'       => {'gettext_id' => 'list not yet activated'},
    'error_config'  => {'gettext_id' => 'erroneous configuration'},
    'family_closed' => {'gettext_id' => 'closed family instance'},
    'closed'        => {'gettext_id' => 'closed list'},
);

our %list_status_capital = (
    'open'          => {'gettext_id' => 'In operation'},
    'pending'       => {'gettext_id' => 'List not activated yet'},
    'error_config'  => {'gettext_id' => 'Erroneous configuration'},
    'family_closed' => {'gettext_id' => 'Closed family instance'},
    'closed'        => {'gettext_id' => 'Closed list'},
);

# Deprecated: Moved to Sympa::Template::_get_option_description().
#sub get_option_description;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ListOpt - Definition of list configuration parameter values

=head1 DESCRIPTION

L<Sympa::ListOpt> gives information about options used for values of list
configuration.

=head2 Function

=over

=item get_option_description ( $that, $value, [ $type, [ $withval ] ] )

B<Deprecated>.

I<Function>.
Gets i18n-ed title of option.
Language context must be set in advance (See L<Sympa::Language>).

Parameters:

=over

=item $that

Context, instance of L<Sympa::List>, Robot or Site.

=item $value

Value of option.

=item $type

Type of option:
field_type (see L<Sympa::ListDef>)
or other (list config option, default).

=item $withval

Adds value of option to returned title.

=back

Returns:

I18n-ed title of option value.

=back

=head1 SEE ALSO

L<Sympa::ListDef>.

=head1 HISTORY

L<Sympa::ListOpt> appeared on Sympa 6.2.13.

=cut
