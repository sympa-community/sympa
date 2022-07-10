# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
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

package Sympa::ConfDef;

use strict;
use warnings;

use Sympa::Constants;

our @params = (
    # Sympa services

    {'gettext_id' => 'Service description'},

    {   'name'       => 'domain',
        'gettext_id' => 'Primary mail domain name',
        'sample'     => 'mail.example.org',
        'edit'       => '1',
        'file'       => 'sympa.conf',
        'vhost' => '1',    #FIXME:not used in robot.conf.
    },
    {   'name'       => 'listmaster',
        'sample'     => 'your_email_address@domain.tld',
        'gettext_id' => 'Email addresses of listmasters',
        'file'       => 'sympa.conf',
        'split_char' => ',',
        'vhost'      => '1',
        'edit'       => '1',
        'gettext_comment' =>
            'Email addresses of the listmasters (users authorized to perform global server commands). Some error reports may also be sent to these addresses. Listmasters can be defined for each virtual host, however, the default listmasters will have privileges to manage all virtual hosts.',
    },
    {   'name'       => 'lang',
        'default'    => 'en-US',
        'gettext_id' => 'Default language',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            'This is the default language used by Sympa. One of supported languages should be chosen.',
    },
    {   'name' => 'supported_lang',
        'default' =>
            'ca,cs,de,el,en-US,es,et,eu,fi,fr,gl,hu,it,ja,ko,nb,nl,oc,pl,pt-BR,ru,sv,tr,vi,zh-CN,zh-TW',
        'gettext_id' => 'Supported languages',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'split_char' => ',',
        'edit'       => '1',
        'gettext_comment' =>
            'All supported languages for the user interface. Languages proper locale information not installed are ignored.',
    },
    {   'name'       => 'title',                   #FIXME:Not specific to web
        'default'    => 'Mailing lists service',
        'gettext_id' => 'Title of service',
        'gettext_comment' =>
            'The name of your mailing list service. It will appear in the header of web interface and subjects of several service messages.',
        'vhost' => '1',
        'file'  => 'wwsympa.conf',
        'edit'  => '1',
    },
    {   'name'       => 'gecos',
        'default'    => 'SYMPA',
        'gettext_id' => 'Display name of Sympa',
        'vhost'      => '1',
        'edit'       => '1',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'This parameter is used for display name in the "From:" header field for the messages sent by Sympa itself.',
    },
    {   'name'       => 'legacy_character_support_feature',
        'default'    => 'off',
        'gettext_id' => 'Support of legacy character set',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            "If set to \"on\", enables support of legacy character set according to charset.conf(5) configuration file.\nIn some language environments, legacy encoding (character set) can be preferred for e-mail messages: for example iso-2022-jp in Japanese language.",
    },

    {'gettext_id' => 'Database related'},

    {   'name'       => 'update_db_field_types',
        'gettext_id' => 'Update database structure',
        'gettext_comment' =>
            "auto: Updates database table structures automatically.\nHowever, since version 5.3b.5, Sympa will not shorten field size if it already have been longer than the size defined in database definition.",
        'default' => 'auto',
    },
    {   'name'       => 'db_type',
        'default'    => 'mysql',
        'gettext_id' => 'Type of the database',
        'gettext_comment' =>
            'Possible types are "MySQL", "PostgreSQL", "Oracle" and "SQLite".',
        'file' => 'sympa.conf',
        'edit' => '1',
    },
    {   'name' => 'db_host',
        #'default'    => 'localhost',
        'sample'     => 'localhost',
        'gettext_id' => 'Hostname of the database server',
        'gettext_comment' =>
            'With PostgreSQL, you can also use the path to Unix Socket Directory, e.g. "/var/run/postgresql" for connection with Unix domain socket.',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => 1,
    },
    {   'name'       => 'db_port',
        'default'    => undef,
        'gettext_id' => 'Port of the database server',
        'file'       => 'sympa.conf',
        'optional'   => '1',
    },
    {   'name'       => 'db_name',
        'default'    => 'sympa',
        'gettext_id' => 'Name of the database',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            "With SQLite, this must be the full path to database file.\nWith Oracle Database, this must be SID, net service name or easy connection identifier (to use net service name, db_host should be set to \"none\" and HOST, PORT and SERVICE_NAME should be defined in tnsnames.ora file).",
    },
    {   'name'       => 'db_user',
        'default'    => 'user_name',
        'sample'     => 'sympa',
        'gettext_id' => 'User for the database connection',
        'file'       => 'sympa.conf',
        'optional'   => '1',
        'edit'       => '1',
    },
    {   'name'       => 'db_passwd',
        'default'    => 'user_password',
        'sample'     => 'your_passwd',
        'gettext_id' => 'Password for the database connection',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'obfuscated' => '1',
        'gettext_comment' =>
            'What ever you use a password or not, you must protect the SQL server (is it not a public internet service ?)',
    },
    {   'name'       => 'db_options',
        'gettext_id' => 'Database options',
        'gettext_comment' =>
            'If these options are defined, they will be appended to data source name (DSN) fed to database driver. Check the related DBD documentation to learn about the available options.',
        'sample' =>
            'mysql_read_default_file=/home/joe/my.cnf;mysql_socket=tmp/mysql.sock-test',
        'optional' => '1',
    },
    {   'name'       => 'db_env',
        'gettext_id' => 'Environment variables setting for database',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'With Oracle Database, this is useful for defining ORACLE_HOME and NLS_LANG.',
        'sample' =>
            'NLS_LANG=American_America.AL32UTF8;ORACLE_HOME=/u01/app/oracle/product/11.2.0/server',
        'optional' => '1',
    },
    {   'name'       => 'db_timeout',
        'gettext_id' => 'Database processing timeout',
        'gettext_comment' =>
            'Currently, this parameter may be used for SQLite only.',
        'optional' => '1',
    },
    {   'name'       => 'db_additional_subscriber_fields',
        'sample'     => 'billing_delay,subscription_expiration',
        'gettext_id' => 'Database private extension to subscriber table',
        'file'       => 'sympa.conf',
        'split_char' => ',',
        'gettext_comment' =>
            "Adds more fields to \"subscriber_table\" table. Sympa recognizes fields defined with this parameter. You will then be able to use them from within templates and scenarios:\n* for scenarios: [subscriber->field]\n* for templates: [% subscriber.field %]\nThese fields will also appear in the list members review page and will be editable by the list owner. This parameter is a comma-separated list.\nYou need to extend the database format with these fields",
        'optional' => '1',
    },
    {   'name'       => 'db_additional_user_fields',
        'sample'     => 'age,address',
        'gettext_id' => 'Database private extension to user table',
        'file'       => 'sympa.conf',
        'split_char' => ',',
        'gettext_comment' =>
            "Adds more fields to \"user_table\" table. Sympa recognizes fields defined with this parameter. You will then be able to use them from within templates: [% subscriber.field %]\nThis parameter is a comma-separated list.\nYou need to extend the database format with these fields",
        'optional' => '1',
    },

    {'gettext_id' => 'System log'},

    {   'name'            => 'syslog',
        'default'         => 'LOCAL1',
        'gettext_id'      => 'System log facility for Sympa',
        'file'            => 'sympa.conf',
        'edit'            => '1',
        'gettext_comment' => 'Do not forget to configure syslog server.',
    },
    {   'name'       => 'log_socket_type',
        'default'    => 'unix',
        'gettext_id' => 'Communication mode with syslog server',
        'file'       => 'sympa.conf',
        'edit'       => '1',
    },
    {   'name'       => 'log_level',
        'default'    => '0',
        'sample'     => '2',
        'gettext_id' => 'Log verbosity',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            "Sets the verbosity of logs.\n0: Only main operations are logged\n3: Almost everything is logged.",
    },

    {'gettext_id' => 'Alias management'},

    {   'name'       => 'aliases_program',
        'default'    => 'newaliases',
        'gettext_id' => 'Program used to update alias database',
        'gettext_comment' =>
            'This may be "makemap", "newaliases", "postalias", "postmap" or full path to custom program.',
        'vhost' => '1',
    },
    {   'name'       => 'aliases_db_type',
        'default'    => 'hash',
        'gettext_id' => 'Type of alias database',
        'gettext_comment' =>
            '"btree", "dbm", "hash" and so on.  Available when aliases_program is "makemap", "postalias" or "postmap"',
        'vhost' => '1',
    },
    {   'name'      => 'sendmail_aliases',
        'default_s' => '$SENDMAIL_ALIASES',
        'gettext_id' =>
            'Path of the file that contains all list related aliases',
        'gettext_comment' =>
            "It is recommended to create a specific alias file so that Sympa never overwrites the standard alias file, but only a dedicated file.\nSet this parameter to \"none\" if you want to disable alias management in Sympa.",
        'vhost' => '1',
    },
    {   'name'       => 'alias_manager',
        'gettext_id' => 'Path to alias manager',
        'gettext_comment' =>
            'The absolute path to the script that will add/remove mail aliases',

        'default_s' => '$SBINDIR/alias_manager.pl',
        'sample'    => '/usr/local/libexec/ldap_alias_manager.pl',
    },

    {'gettext_id' => 'Receiving'},

    {   'name'       => 'default_max_list_members',
        'gettext_id' => 'Default maximum number of list members',
        'default'    => '0',
        'optional'   => '1',
        'gettext_comment' =>
            'Default limit for the number of subscribers per list (0 means no limit).',
        'vhost' => '1',
        'file'  => 'sympa.conf',
    },

    {   'name'       => 'max_size',
        'gettext_id' => 'Maximum size of messages',
        'gettext_comment' =>
            'Incoming messages smaller than this size is allowed distribution by Sympa.',
        'gettext_unit' => 'bytes',
        'default'      => '5242880',      ## 5 MiB
        'sample'       => '2097152',
        'vhost'        => '1',
        'file'         => 'sympa.conf',
        'edit'         => '1',
    },
    {   'name'       => 'reject_mail_from_automates_feature',
        'gettext_id' => 'Reject mail sent from automated services to list',
        'gettext_comment' =>
            "Rejects messages that seem to be from automated services, based on a few header fields (\"Content-Identifier:\", \"Auto-Submitted:\").\nSympa also can be configured to reject messages based on the \"From:\" header field value (see \"loop_prevention_regex\").",
        'default' => 'on',
        'sample'  => 'off',
        'file'    => 'sympa.conf',
    },
    {   'name'    => 'sender_headers',
        'default' => 'From',
        'sample'  => 'Resent-From,From,Return-Path',
        'gettext_id' =>
            'Header field name(s) used to determine sender of the messages',
        'gettext_comment' =>
            '"Return-Path" means envelope sender (a.k.a. "UNIX From") which will be alternative to sender of messages without "From" field.  "Resent-From" may also be inserted before "From", because some mailers add it into redirected messages and keep original "From" field intact.  In particular cases, "Return-Path" can not give right sender: several mail gateway products rewrite envelope sender and add original one as non-standard field such as "X-Envelope-From".  If that is the case, you might want to insert it in place of "Return-Path".',
        'split_char' => ',',
    },

    {   'name'       => 'misaddressed_commands',
        'gettext_id' => 'Reject misaddressed commands',
        'gettext_comment' =>
            'When a mail command is sent to a list, by default Sympa rejects this message. This feature can be turned off setting this parameter to "ignore".',
        'default' => 'reject',
    },
    {   'name' => 'misaddressed_commands_regexp',
        'gettext_id' =>
            'Regular expression matching with misaddressed commands',
        'gettext_comment' =>
            'Perl regular expression applied on messages subject and body to detect misaddressed commands.',
        'default' =>
            '((subscribe\s+(\S+)|unsubscribe\s+(\S+)|signoff\s+(\S+)|set\s+(\S+)\s+(mail|nomail|digest))\s*)',
    },
    {   'name'       => 'sympa_priority',
        'gettext_id' => 'Priority for command messages',
        'gettext_comment' =>
            'Priority applied to messages sent to Sympa command address.',
        'file'    => 'sympa.conf',
        'default' => '1',
        'vhost'   => '1',
    },
    {   'name'       => 'request_priority',
        'gettext_id' => 'Priority for messages bound for list owners',
        'gettext_comment' =>
            'Priority for processing of messages bound for "LIST-request" address, i.e. owners of the list',
        'default' => '0',
        'file'    => 'sympa.conf',
        'vhost'   => '1',
    },
    {   'name'       => 'owner_priority',
        'gettext_id' => 'Priority for non-VERP bounces',
        'gettext_comment' =>
            'Priority for processing of messages bound for "LIST-owner" address, i.e. non-delivery reports (bounces).',
        'default' => '9',
        'file'    => 'sympa.conf',
        'vhost'   => '1',
    },
    {   'name'       => 'default_list_priority',
        'gettext_id' => 'Default priority for list messages',
        'gettext_comment' =>
            'Priority for processing of messages posted to list addresses.',
        'file'    => 'sympa.conf',
        'default' => '5',
        'vhost'   => '1',
    },
    {   'name'       => 'incoming_max_count',
        'default'    => '1',
        'gettext_id' => 'Max number of sympa.pl workers',
        'gettext_comment' =>
            'Max number of workers of sympa.pl daemon processing incoming spool.',
    },

    {   'name'       => 'sleep',
        'default'    => '5',
        'gettext_id' => 'Interval between scanning incoming message spool',
        'gettext_comment' => 'Must not be 0.',
        'gettext_unit'    => 'seconds',
    },

    {'gettext_id' => 'Sending related'},

    {   'name' => 'anonymous_header_fields',
        'gettext_id' =>
            'Header fields removed when a mailing list is setup in anonymous mode',
        'gettext_comment' =>
            "See \"anonymous_sender\" list parameter.\nDefault value prior to Sympa 6.1.19 is:\n  Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender",
        'default' =>
            'Authentication-Results,Disposition-Notification-To,DKIM-Signature,Injection-Info,Organisation,Organization,Original-Recipient,Originator,Path,Received,Received-SPF,Reply-To,Resent-Reply-To,Return-Receipt-To,X-Envelope-From,X-Envelope-To,X-Sender,X-X-Sender',
        'split_char' => ',',
    },
    {   'name'       => 'merge_feature',
        'gettext_id' => 'Allow message personalization by default',
        'gettext_comment' =>
            'This parameter defines the default "merge_feature" list parameter.',
        'default' => 'off',
    },
    {   'name'       => 'remove_headers',
        'gettext_id' => 'Header fields to be removed from incoming messages',
        'gettext_comment' =>
            "Use it, for example, to ensure some privacy for your users in case that \"anonymous_sender\" mode is inappropriate.\nThe removal of these header fields is applied before Sympa adds its own header fields (\"rfc2369_header_fields\" and \"custom_header\").",
        'default' =>
            'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To,Sender',
        'sample' =>
            'Resent-Date,Resent-From,Resent-To,Resent-Message-Id,Sender,Delivered-To',
        'file'       => 'sympa.conf',
        'split_char' => ',',
    },
    {   'name' => 'remove_outgoing_headers',
        'gettext_id' =>
            'Header fields to be removed before message distribution',
        'gettext_comment' =>
            "The removal happens after Sympa's own header fields are added; therefore, it is a convenient way to remove Sympa's own header fields (like \"X-Loop:\" or \"X-no-archive:\") if you wish.",
        'default'    => 'none',
        'sample'     => 'X-no-archive',
        'split_char' => ',',
    },
    {   'name'       => 'rfc2369_header_fields',
        'gettext_id' => 'RFC 2369 header fields',
        'gettext_comment' =>
            "Specify which RFC 2369 mailing list header fields to be added.\n\"List-Id:\" header field defined in RFC 2919 is always added. Sympa also adds \"Archived-At:\" header field defined in RFC 5064.",
        'default'    => 'help,subscribe,unsubscribe,post,owner,archive',
        'file'       => 'sympa.conf',
        'split_char' => ',',
    },
    {   'name'       => 'urlize_min_size',
        'gettext_id' => 'Minimum size to be urlized',
        'gettext_comment' =>
            'When a subscriber chose "urlize" reception mode, attachments not smaller than this size will be urlized.',
        'gettext_unit' => 'bytes',
        'default'      => 10240,     ## 10 kiB,
        'vhost'        => '1',
    },
    {   'name'       => 'allowed_external_origin',
        'gettext_id' => 'Allowed external links in sanitized HTML',
        'gettext_comment' =>
            'When the HTML content of a message must be sanitized, links ("href" or "src" attributes) with the hosts listed in this parameter will not be scrubbed. If "*" character is included, it matches any subdomains. Single "*" allows any hosts.',
        'split_char' => ',',
        'optional'   => '1',
        'sample'     => '*.example.org,www.example.com',
        'vhost'      => '1',
    },

    {   'name'       => 'sympa_packet_priority',
        'gettext_id' => 'Default priority for a packet',
        'file'       => 'sympa.conf',
        'default'    => '5',
        'vhost'      => '1',
        'gettext_comment' =>
            'The default priority set to a packet to be sent by the bulk.',
    },
    {   'name'       => 'bulk_fork_threshold',
        'default'    => '1',
        'gettext_id' => 'Fork threshold of bulk daemon',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'The minimum number of packets before bulk daemon forks a new worker to increase sending rate.',
    },
    {   'name'       => 'bulk_max_count',
        'default'    => '3',
        'gettext_id' => 'Maximum number of bulk workers',
        'file'       => 'sympa.conf',
    },
    {   'name'       => 'bulk_lazytime',
        'default'    => '600',
        'gettext_id' => 'Idle timeout of bulk workers',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'The number of seconds a bulk worker will remain running without processing a message before it spontaneously exits.',
        'gettext_unit' => 'seconds',
    },
    {   'name'       => 'bulk_sleep',
        'default'    => '1',
        'gettext_id' => 'Sleep time of bulk workers',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            "The number of seconds a bulk worker sleeps between starting a new loop if it didn't find a message to send.\nKeep it small if you want your server to be reactive.",
        'gettext_unit' => 'seconds',
    },
    {   'name'       => 'bulk_wait_to_fork',
        'default'    => '10',
        'gettext_id' => 'Interval between checks of packet numbers',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            "Number of seconds a master bulk daemon waits between two packets number checks.\nKeep it small if you expect brutal increases in the message sending load.",
        'gettext_unit' => 'seconds',
    },
##    {
##        'name'     => 'pidfile_bulk',
##        'default'  => Sympa::Constants::PIDDIR . '/bulk.pid',
##        'file'     => 'sympa.conf',
##    },

    {   'name'       => 'sendmail',
        'default'    => '/usr/sbin/sendmail',
        'gettext_id' => 'Path to sendmail',
        'gettext_comment' =>
            "Absolute path to sendmail command line utility (e.g.: a binary named \"sendmail\" is distributed with Postfix).\nSympa expects this binary to be sendmail compatible (exim, Postfix, qmail and so on provide it).",
        'file' => 'sympa.conf',
        'edit' => '1',
    },
    {   'name'       => 'sendmail_args',
        'default'    => '-oi -odi -oem',
        'gettext_id' => 'Command line parameters passed to sendmail',
        'gettext_comment' =>
            "Note that \"-f\", \"-N\" and \"-V\" options and recipient addresses should not be included, because they will be included by Sympa.",
    },
    {   'name'       => 'log_smtp',
        'gettext_id' => 'Log invocation of sendmail',
        'gettext_comment' =>
            'This can be overwritten by "-m" option for sympa.pl.',
        'default' => 'off',
        'vhost'   => '1',
        'file'    => 'sympa.conf',
    },
#    {   'name'    => 'distribution_mode',
#        'default' => 'single',
#    },
    {   'name'       => 'maxsmtp',
        'default'    => '40',
        'sample'     => '500',
        'gettext_id' => 'Maximum number of sendmail processes',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            "Maximum number of simultaneous child processes spawned by Sympa. This is the main load control parameter. \nProposed value is quite low, but you can rise it up to 100, 200 or even 300 with powerful systems.",
    },
    {   'name'       => 'nrcpt',
        'default'    => '25',
        'gettext_id' => 'Maximum number of recipients per call to sendmail',
        'gettext_comment' =>
            'This grouping factor makes it possible for the sendmail processes to optimize the number of SMTP sessions for message distribution. If needed, you can limit the number of recipients for a particular domain. Check the "nrcpt_by_domain.conf" configuration file.',
        'file' => 'sympa.conf',
    },
    {   'name'    => 'avg',
        'default' => '10',
        'gettext_id' =>
            'Maximum number of different mail domains per call to sendmail',
        'file' => 'sympa.conf',
    },

    {'gettext_id' => 'Privileges'},

    {   'name'       => 'create_list',
        'default'    => 'public_listmaster',
        'sample'     => 'intranet',
        'gettext_id' => 'Who is able to create lists',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            'Defines who can create lists (or request list creation) by creating new lists or by renaming or copying existing lists.',
        'scenario' => '1',
    },
    {   'name'       => 'allow_subscribe_if_pending',
        'gettext_id' => 'Allow adding subscribers to a list not open',
        'gettext_comment' =>
            'If set to "off", adding subscribers to, or removing subscribers from a list with status other than "open" is forbidden.',
        'default' => 'on',
        'vhost'   => '1',
    },
    {   'name'       => 'global_remind',
        'gettext_id' => 'Who is able to send remind messages over all lists',
        'default'    => 'listmaster',
        'scenario'   => '1',
    },
    {   'name'       => 'move_user',
        'default'    => 'auth',
        'gettext_id' => 'Who is able to change user\'s email',
        'vhost'      => '1',
        'scenario'   => '1',
    },
    {   'name'       => 'use_blacklist',
        'gettext_id' => 'Use blacklist',
        'default'    => 'send,create_list',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'split_char' => ',',
        'edit'       => '1',
        'gettext_comment' =>
            'List of operations separated by comma for which blacklist filter is applied.  Setting this parameter to "none" will hide the blacklist feature.',
    },
    {   'name'       => 'owner_domain',
        'sample'     => 'domain1.tld domain2.tld',
        'gettext_id' => 'List of required domains for list owner addresses',
        'file'       => 'sympa.conf',
        'optional'   => '1',
        'split_char' => ' ',
        'vhost'      => '1',
        'edit'       => '1',
        'gettext_comment' =>
            'Restrict list ownership to addresses in the specified domains. This can be used to reserve list ownership to a group of trusted users from a set of domains associated with an organization, while allowing moderators and subscribers from the Internet at large.',
        'default' => undef,
    },
    {   'name'   => 'owner_domain_min',
        'sample' => '1',
        'gettext_id' =>
            'Minimum number of owners for each list that must match owner_domain restriction',
        'file'     => 'sympa.conf',
        'default'  => '0',
        'optional' => '1',
        'vhost'    => '1',
        'edit'     => '1',
        'gettext_comment' =>
            'Minimum number of owners for each list must satisfy the owner_domain restriction. The default of zero (0) means *all* list owners must match. Setting to 1 requires only one list owner to match owner_domain; all other owners can be from any domain. This setting can be used to ensure that there is always at least one known contact point for any mailing list.',
    },

    {'gettext_id' => 'Default privileges for the lists'},

    # List definition
    {   'name'       => 'visibility',
        'gettext_id' => "Visibility of the list",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'conceal',
    },

    # Sending
    {   'name'       => 'send',
        'gettext_id' => "Who can send messages",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'private',
    },

    # Privileges
    {   'name'       => 'info',
        'gettext_id' => "Who can view list information",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'open',
    },
    {   'name'       => 'subscribe',
        'gettext_id' => "Who can subscribe to the list",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'open',
    },
    {   'name'       => 'add',
        'gettext_id' => "Who can add subscribers",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'owner',
    },
    {   'name'       => 'unsubscribe',
        'gettext_id' => "Who can unsubscribe",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'open',
    },
    {   'name'       => 'del',
        'gettext_id' => "Who can delete subscribers",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'owner',
    },
    {   'name'       => 'invite',
        'gettext_id' => "Who can invite people",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'private',
    },
    {   'name'       => 'remind',
        'gettext_id' => "Who can start a remind process",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'owner',
    },
    {   'name'       => 'review',
        'gettext_id' => "Who can review subscribers",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'owner',
    },

    {   'name'       => 'd_read',
        'gettext_id' => "Who can view",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'private',
    },
    {   'name'       => 'd_edit',
        'gettext_id' => "Who can edit",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'owner',
    },

    # Archives
    {   'name'       => 'archive_web_access',
        'gettext_id' => "access right",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'closed',
    },
    {   'name'       => 'archive_mail_access',
        'gettext_id' => "access right by mail commands",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'closed',
    },

    # Bounces
    {   'name'       => 'tracking',
        'gettext_id' => "who can view message tracking",
        'scenario'   => 1,
        'vhost'      => 1,
        'default'    => 'owner',
    },

    {'gettext_id' => 'Archives'},

    {   'name'       => 'process_archive',
        'default'    => 'off',
        'gettext_id' => 'Store distributed messages into archive',
        'gettext_comment' =>
            "If enabled, distributed messages via lists will be archived. Otherwise archiving is disabled.\nNote that even if setting this parameter disabled, past archives will not be removed and will be accessible according to access settings by each list.",
        'vhost' => '1',
        'file'  => 'sympa.conf',
        'edit'  => '1',
    },
    {   'name'         => 'default_archive_quota',
        'gettext_id'   => 'Default disk quota for lists\' archives',
        'gettext_unit' => 'Kbytes',
        'optional'     => '1',
    },

    {   'name'       => 'ignore_x_no_archive_header_feature',
        'gettext_id' => 'Ignore "X-no-archive:" header field',
        'gettext_comment' =>
            'Sympa\'s default behavior is to skip archiving of incoming messages that have an "X-no-archive:" header field set. This parameter allows one to change this behavior.',
        'default' => 'off',
        'sample'  => 'on',
    },
    {   'name'       => 'custom_archiver',
        'optional'   => '1',
        'gettext_id' => 'Custom archiver',
        'gettext_comment' =>
            "Activates a custom archiver to use instead of MHonArc. The value of this parameter is the absolute path to the executable file.\nSympa invokes this file with these two arguments:\n--list\nThe address of the list including domain part.\n--file\nAbsolute path to the message to be archived.",
        'file' => 'wwsympa.conf',
        'edit' => '1',
    },
    {   'name'            => 'mhonarc',
        'default'         => '/usr/bin/mhonarc',
        'gettext_id'      => 'Path to MHonArc mail-to-HTML converter',
        'file'            => 'wwsympa.conf',
        'edit'            => '1',
        'gettext_comment' => 'This is required for HTML mail archiving.',
        'vhost'           => '1',
    },
##    {
##        'name'     => 'archived_pidfile',
##        'default'  => Sympa::Constants::PIDDIR . '/archived.pid',
##        'gettext_id' => 'File containing archived PID while running',
##        'file'     => 'wwsympa.conf',
##    },

    {'gettext_id' => 'Bounce management and tracking'},

    {   'name'       => 'bounce_warn_rate',
        'default'    => '30',
        'gettext_id' => 'Default bounce warn rate',
        'gettext_comment' =>
            'The list owner receives a warning whenever a message is distributed and the number (percentage) of bounces exceeds this value.',
        'file' => 'sympa.conf',
        'edit' => '1',
    },
    {   'name'       => 'bounce_halt_rate',
        'default'    => '50',
        'gettext_id' => 'Default bounce halt rate',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'NOT USED YET. If bounce rate reaches the halt_rate, messages for the list will be halted, i.e. they are retained for subsequent moderation.',
    },
    {   'name'       => 'default_bounce_level1_rate',
        'gettext_id' => 'Default bounce management threshold, 1st level',
        'default'    => '45',
        'vhost'      => '1',
    },
    {   'name'       => 'default_bounce_level2_rate',
        'gettext_id' => 'Default bounce management threshold, 2nd level',
        'default'    => '75',
        'vhost'      => '1',
    },

    {   'name'       => 'verp_rate',
        'gettext_id' => 'Percentage of list members in VERP mode',
        'gettext_comment' =>
            "Uses variable envelope return path (VERP) to detect bouncing subscriber addresses.\n0%: VERP is never used.\n100%: VERP is always in use.\nVERP requires address with extension to be supported by MTA. If tracking is enabled for a list or a message, VERP is applied for 100% of subscribers.",
        'default' => '0%',
        'vhost'   => '1',
    },
    {   'name' => 'tracking_delivery_status_notification',
        'gettext_id' =>
            'Tracking message by delivery status notification (DSN)',
        'default' => 'off',
    },
    {   'name' => 'tracking_message_disposition_notification',
        'gettext_id' =>
            'Tracking message by message disposition notification (MDN)',
        'default' => 'off',
    },
    {   'name'       => 'tracking_default_retention_period',
        'gettext_id' => 'Max age of tracking information',
        'gettext_comment' =>
            'Tracking information is removed after this number of days',
        'gettext_unit' => 'days',
        'default'      => '90',
    },
    {   'name'       => 'welcome_return_path',
        'default'    => 'owner',
        'gettext_id' => 'Remove bouncing new subscribers',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'If set to unique, the welcome message is sent using a unique return path in order to remove the subscriber immediately in the case of a bounce.',
    },
    {   'name'       => 'remind_return_path',
        'default'    => 'owner',
        'gettext_id' => 'Remove subscribers bouncing remind message',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'Same as welcome_return_path, but applied to remind messages.',
    },
    {   'name'       => 'default_remind_task',
        'gettext_id' => 'Periodical subscription reminder task',
        'gettext_comment' =>
            'This task regularly sends subscribers a message which reminds them of their list subscriptions.',
        'optional' => '1',
    },
##    {
##        'name'     => 'bounced_pidfile',
##        'default'  => Sympa::Constants::PIDDIR . '/bounced.pid',
##        'gettext_id' => 'File containing bounced PID while running',
##        'file'     => 'wwsympa.conf',
##    },

    {   'name'       => 'expire_bounce_task',
        'default'    => 'daily',
        'gettext_id' => 'Task for expiration of old bounces',
        'gettext_comment' =>
            'This task resets bouncing information for addresses not bouncing in the last 10 days after the latest message distribution.',
        'file' => 'sympa.conf',
        'task' => 'expire_bounce',
    },
    {   'name'       => 'purge_orphan_bounces_task',
        'gettext_id' => 'Task for cleaning invalidated bounces',
        'gettext_comment' =>
            'This task deletes bounce information for unsubscribed users.',
        'default' => 'monthly',
        'task'    => 'purge_orphan_bounces',
    },
    {   'name'       => 'eval_bouncers_task',
        'gettext_id' => 'Task for updating bounce scores',
        'gettext_comment' =>
            'This task scans all bouncing users for all lists, and updates "bounce_score_subscriber" field in "subscriber_table" table. The scores may be used for management of bouncers.',
        'default' => 'daily',
        'task'    => 'eval_bouncers',
    },
    {   'name'       => 'process_bouncers_task',
        'gettext_id' => 'Task for management of bouncers',
        'gettext_comment' =>
            'This task executes actions on bouncing users configured by each list, according to their scores.',
        'default' => 'weekly',
        'task'    => 'process_bouncers',
    },
    {   'name'       => 'purge_tables_task',
        'gettext_id' => 'Task for cleaning tables',
        'gettext_comment' =>
            'This task cleans old tracking information from "notification_table" table.',
        'default' => 'daily',
        'task'    => 'purge_tables',
    },
    {   'name'       => 'minimum_bouncing_count',
        'gettext_id' => 'Minimum number of bounces',
        'gettext_comment' =>
            'The minimum number of bounces received to update bounce score of a user.',
        'default' => '10',
    },
    {   'name'       => 'minimum_bouncing_period',
        'gettext_id' => 'Minimum bouncing period',
        'gettext_comment' =>
            'The minimum period for which bouncing lasted to update bounce score of a user.',
        'gettext_unit' => 'days',
        'default'      => '10',
    },
    {   'name'       => 'bounce_delay',
        'gettext_id' => 'Delay of bounces',
        'gettext_comment' =>
            'Average time for a bounce sent back to mailing list server after a post was sent to a list. Usually bounces are sent back on the same day as the original message.',
        'gettext_unit' => 'days',
        'default'      => '0',
    },
    {   'name' => 'bounce_email_prefix',
        'gettext_comment' =>
            "The prefix to consist the return-path of probe messages used for bounce management, when variable envelope return path (VERP) is enabled. VERP requires address with extension to be supported by MTA.\nIf you change the default value, you must modify the mail aliases too.",
        'default' => 'bounce',
    },
    {   'name'       => 'return_path_suffix',
        'gettext_id' => 'Suffix of list return address',
        'gettext_comment' =>
            'The suffix appended to the list name to form the return-path of messages distributed through the list. This address will receive all non-delivery reports (also called bounces).',
        'default' => '-owner',
    },

    # Sympa services: Advanced configuration

    {'gettext_id' => 'Loop prevention'},

    {   'name'       => 'loop_command_max',
        'gettext_id' => 'Maximum number of responses to command message',
        'gettext_comment' =>
            'The maximum number of command reports sent to an email address. Messages are stored in "bad" subdirectory of incoming message spool, and reports are not longer sent.',
        'default' => '200',
    },
    {   'name'       => 'loop_command_sampling_delay',
        'gettext_id' => 'Delay before counting responses to command message',
        'gettext_comment' =>
            'This parameter defines the delay in seconds before decrementing the counter of reports sent to an email address.',
        'gettext_unit' => 'seconds',
        'default'      => '3600',
    },
    {   'name'       => 'loop_command_decrease_factor',
        'gettext_id' => 'Decrementing factor of responses to command message',
        'gettext_comment' =>
            'The decrementation factor (from 0 to 1), used to determine the new report counter after expiration of the delay.',
        'default' => '0.5',
    },
    {   'name'       => 'loop_prevention_regex',
        'gettext_id' => 'Regular expression to prevent loop',
        'gettext_comment' =>
            'If the sender address matches the regular expression, then the message is rejected.',
        'default' =>
            'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
        'vhost' => '1',
    },
    {   'name'       => 'msgid_table_cleanup_ttl',
        'gettext_id' => 'Expiration period of message ID table',
        'gettext_comment' =>
            'Expiration period of entries in the table maintained by sympa_msg.pl daemon to prevent delivery of duplicate messages caused by loop.',
        'gettext_unit' => 'seconds',
        'default'      => '86400',
    },
    {   'name'       => 'msgid_table_cleanup_frequency',
        'gettext_id' => 'Cleanup interval of message ID table',
        'gettext_comment' =>
            'Interval between cleanups of the table maintained by sympa_msg.pl daemon to prevent delivery of duplicate messages caused by loop.',
        'gettext_unit' => 'seconds',
        'default'      => '3600',
    },

    {'gettext_id' => 'Automatic lists'},

    {   'name'       => 'automatic_list_removal',
        'gettext_id' => 'Remove empty automatic list',
        'gettext_comment' =>
            'If set to "if_empty", then Sympa will remove automatically created mailing lists just after their creation, if they contain no list member.',
        'default' => 'none',       ## Can be 'if_empty'
        'sample'  => 'if_empty',
        'vhost'   => '1',
    },
    {   'name'       => 'automatic_list_feature',
        'gettext_id' => 'Automatic list',
        'default'    => 'off',
        'vhost'      => '1',
    },
    {   'name'       => 'automatic_list_creation',
        'gettext_id' => 'Who is able to create automatic list',
        'default'    => 'public',
        'vhost'      => '1',
        'scenario'   => '1',
    },
    {   'name' => 'automatic_list_families',
        'sample' =>
            'name=family_one:prefix=f1:display=My automatic lists:prefix_separator=+:classes separator=-:family_owners_list=alist@domain.tld;name=family_two:prefix=f2:display=My other automatic lists:prefix_separator=+:classes separator=-:family_owners_list=anotherlist@domain.tld;',
        'gettext_id' => 'Definition of automatic list families',
        'gettext_comment' =>
            "Defines the families the automatic lists are based on. It is a character string structured as follows:\n* each family is separated from the other by a semicolon (;)\n* inside a family definition, each field is separated from the other by a colon (:)\n* each field has the structure: \"<field name>=<field value>\"\nBasically, each time Sympa uses the automatic lists families, the values defined in this parameter will be available in the family object.\n* for scenarios: [family->name]\n* for templates: [% family.name %]",
        'file'     => 'sympa.conf',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'       => 'parsed_family_files',
        'gettext_id' => 'Parsed files for families',
        'gettext_comment' =>
            'comma-separated list of files that will be parsed by Sympa when instantiating a family (no space allowed in file names)',
        'file'       => 'sympa.conf',
        'split_char' => ',',
        'default' =>
            'message_header,message_header.mime,message_footer,message_footer.mime,info',
        'vhost' => '1',
    },

    {'gettext_id' => 'Tag based spam filtering'},

    {   'name'       => 'antispam_feature',
        'gettext_id' => 'Tag based spam filtering',
        'default'    => 'off',
        'vhost'      => '1',
    },
    {   'name'       => 'antispam_tag_header_name',
        'default'    => 'X-Spam-Status',
        'gettext_id' => 'Header field to tag spams',
        'gettext_comment' =>
            'If a spam filter (like spamassassin or j-chkmail) add a header field to tag spams, name of this header field (example X-Spam-Status)',
        'vhost' => '1',
        'file'  => 'sympa.conf',
        'edit'  => '1',
    },
    {   'name'    => 'antispam_tag_header_spam_regexp',
        'default' => '^\s*Yes',
        'gettext_id' =>
            'Regular expression to check header field to tag spams',
        'gettext_comment' =>
            'Regular expression applied on this header to verify message is a spam (example Yes)',
        'vhost' => '1',
        'file'  => 'sympa.conf',
        'edit'  => '1',
    },
    {   'name'       => 'antispam_tag_header_ham_regexp',
        'default'    => '^\s*No',
        'gettext_id' => 'Regular expression to determine spam or ham.',
        'gettext_comment' =>
            'Regular expression applied on this header field to verify message is NOT a spam (example No)',
        'vhost' => '1',
        'file'  => 'sympa.conf',
        'edit'  => '1',
    },
    {   'name'       => 'spam_status',
        'default'    => 'x-spam-status',
        'gettext_id' => 'Name of header field to inform',
        'gettext_comment' =>
            'Messages are supposed to be filtered by an spam filter that adds them one or more headers. This parameter is used to select a special scenario in order to decide the message\'s spam status: ham, spam or unsure. This parameter replaces antispam_tag_header_name, antispam_tag_header_spam_regexp and antispam_tag_header_ham_regexp.',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'scenario' => '1',
    },

    {'gettext_id' => 'Directories'},

    {   'name'            => 'home',
        'default_s'       => '$EXPLDIR',
        'gettext_id'      => 'List home',
        'gettext_comment' => 'Base directory of list configurations.',
        'file'            => 'sympa.conf',
        'edit'            => '1',
    },
    {   'name'       => 'etc',
        'default_s'  => '$SYSCONFDIR',
        'gettext_id' => 'Directory for configuration files',
        'gettext_comment' =>
            'Base directory of global configuration (except "sympa.conf").',
        'file' => 'sympa.conf',
    },
##    {
##        name    => 'localedir',
##        default => Sympa::Constants::LOCALEDIR,
##        'gettext_id' =>
##        'Directory containing available NLS catalogues (Message internationalization)',
##        file    => 'sympa.conf',
##    },

    {   'name'       => 'spool',
        'default_s'  => '$SPOOLDIR',
        'gettext_id' => 'Base directory of spools',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            'Base directory of all spools which are created at runtime. This directory must be writable by Sympa user.',
    },
    {   'name'       => 'queue',
        'default_s'  => '$SPOOLDIR/msg',
        'gettext_id' => 'Directory for message incoming spool',
        'gettext_comment' =>
            'This spool is used both by "queue" program and "sympa_msg.pl" daemon.',
        'file' => 'sympa.conf',
    },
    {   'name'       => 'queuemod',
        'default_s'  => '$SPOOLDIR/moderation',
        'gettext_id' => 'Directory for moderation spool',
        'file'       => 'sympa.conf',
    },
    {   'name'       => 'queuedigest',
        'default_s'  => '$SPOOLDIR/digest',
        'gettext_id' => 'Directory for digest spool',
        'file'       => 'sympa.conf',
    },
    {   'name'       => 'queueauth',
        'default_s'  => '$SPOOLDIR/auth',
        'gettext_id' => 'Directory for held message spool',
        'gettext_comment' =>
            'This parameter is named such by historical reason.',
        'file' => 'sympa.conf',
    },
    {   'name'       => 'queueoutgoing',
        'default_s'  => '$SPOOLDIR/outgoing',
        'gettext_id' => 'Directory for archive spool',
        'gettext_comment' =>
            'This parameter is named such by historical reason.',
        'file' => 'sympa.conf',
    },
#    {   'name'    => 'queuedistribute',
#        'default' => Sympa::Constants::SPOOLDIR . '/distribute',
#        'file'    => 'sympa.conf',
#    },
    ##{ queuesignoff: not yet implemented. },
    {   'name'       => 'queuesubscribe',
        'default_s'  => '$SPOOLDIR/subscribe',
        'gettext_id' => 'Directory for held request spool',
        'gettext_comment' =>
            'This parameter is named such by historical reason.',
        'file' => 'sympa.conf',
    },
    {   'name'       => 'queuetopic',
        'default_s'  => '$SPOOLDIR/topic',
        'gettext_id' => 'Directory for topic spool',
        'file'       => 'sympa.conf',
    },
    {   'name'       => 'queuebounce',
        'default_s'  => '$SPOOLDIR/bounce',
        'gettext_id' => 'Directory for bounce incoming spool',
        'gettext_comment' =>
            'This spool is used both by "bouncequeue" program and "bounced.pl" daemon.',
        'file' => 'sympa.conf',
    },
    {   'name'       => 'queuetask',
        'default_s'  => '$SPOOLDIR/task',
        'gettext_id' => 'Directory for task spool',
        'file'       => 'sympa.conf',
    },
    {   'name'       => 'queueautomatic',
        'default_s'  => '$SPOOLDIR/automatic',
        'gettext_id' => 'Directory for automatic list creation spool',
        'gettext_comment' =>
            'This spool is used both by "familyqueue" program and "sympa_automatic.pl" daemon.',
        'file' => 'sympa.conf',
    },
    {   'name'       => 'queuebulk',
        'default_s'  => '$SPOOLDIR/bulk',
        'gettext_id' => 'Directory for message outgoing spool',
        'gettext_comment' =>
            'This parameter is named such by historical reason.',
        'file' => 'sympa.conf',
    },
    {   'name'      => 'tmpdir',
        'default_s' => '$SPOOLDIR/tmp',
        'gettext_id' =>
            'Temporary directory used by external programs such as virus scanner. Also, outputs to daemons\' standard error are redirected to the files under this directory.',
    },
    {   name         => 'viewmail_dir',
        'default_s'  => '$SPOOLDIR/viewmail',
        'gettext_id' => 'Directory to cache formatted messages',
        'gettext_comment' =>
            'Base directory path of directories where HTML view of messages are cached.',
        file => 'sympa.conf',
    },
    {   'name'       => 'bounce_path',
        'default_s'  => '$BOUNCEDIR',
        'gettext_id' => 'Directory for storing bounces',
        'file'       => 'wwsympa.conf',
        'gettext_comment' =>
            "The directory where bounced.pl daemon will store the last bouncing message for each user. A message is stored in the file: <bounce_path>/<list name>\@<mail domain name>/<email address>, or, if tracking is enabled: <bounce_path>/<list name>\@<mail domain name>/<email address>_<envelope ID>.\nUsers can access to these messages using web interface in the bounce management page.\nDon't confuse with \"queuebounce\" parameter which defines the spool where incoming error reports are stored and picked by bounced.pl daemon.",
    },

    {   'name'       => 'arc_path',
        'default_s'  => '$ARCDIR',
        'gettext_id' => 'Directory for storing archives',
        'file'       => 'wwsympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            'Where to store HTML archives. This parameter is used by the "archived.pl" daemon. It is a good idea to install the archive outside the web document hierarchy to prevent overcoming of WWSympa\'s access control.',
        'vhost' => 1,
    },

    {   'name'            => 'purge_spools_task',
        'gettext_id'      => 'Task for cleaning spools',
        'gettext_comment' => 'This task cleans old content in spools.',
        'default'         => 'daily',
        'task'            => 'purge_spools',
    },
    {   'name'       => 'clean_delay_queue',
        'gettext_id' => 'Max age of incoming bad messages',
        'gettext_comment' =>
            'Number of days "bad" messages are kept in message incoming spool (as specified by "queue" parameter). Sympa keeps messages rejected for various reasons (badly formatted, looping etc.).',
        'gettext_unit' => 'days',
        'default'      => '7',
    },
    {   'name'       => 'clean_delay_queueoutgoing',
        'gettext_id' => 'Max age of bad messages for archives',
        'gettext_comment' =>
            'Number of days "bad" messages are kept in message archive spool (as specified by "queueoutgoing" parameter). Sympa keeps messages rejected for various reasons (unable to create archive directory, to copy file etc.).',
        'gettext_unit' => 'days',
        'default'      => '7',
    },
    {   'name'       => 'clean_delay_queuebounce',
        'gettext_id' => 'Max age of bad bounce messages',
        'gettext_comment' =>
            'Number of days "bad" messages are kept in bounce spool (as specified by "queuebounce" parameter). Sympa keeps messages rejected for various reasons (unknown original sender, unknown report type).',
        'gettext_unit' => 'days',
        'default'      => '7',
    },
    {   'name'       => 'clean_delay_queuemod',
        'gettext_id' => 'Max age of moderated messages',
        'gettext_comment' =>
            'Number of days messages are kept in moderation spool (as specified by "queuemod" parameter). Beyond this deadline, messages that have not been processed are deleted.',
        'gettext_unit' => 'days',
        'default'      => '30',
    },
    {   'name'       => 'clean_delay_queueauth',
        'gettext_id' => 'Max age of held messages',
        'gettext_comment' =>
            'Number of days messages are kept in held message spool (as specified by "queueauth" parameter). Beyond this deadline, messages that have not been confirmed are deleted.',
        'gettext_unit' => 'days',
        'default'      => '30',
    },
    ##{ clean_delay_queuesignoff: not yet implemented. },
    {   'name'       => 'clean_delay_queuesubscribe',
        'gettext_id' => 'Max age of held requests',
        'gettext_comment' =>
            'Number of days requests are kept in held request spool (as specified by "queuesubscribe" parameter). Beyond this deadline, requests that have not been validated nor declined are deleted.',
        'gettext_unit' => 'days',
        'default'      => '30',
    },
    {   'name'       => 'clean_delay_queuetopic',
        'gettext_id' => 'Max age of tagged topics',
        'gettext_comment' =>
            'Number of days (automatically or manually) tagged topics are kept in topic spool (as specified by "queuetopic" parameter). Beyond this deadline, tagging is forgotten.',
        'gettext_unit' => 'days',
        'default'      => '30',
    },
    {   'name' => 'clean_delay_queueautomatic',
        'gettext_id' =>
            'Max age of incoming bad messages in automatic list creation spool',
        'gettext_comment' =>
            'Number of days "bad" messages are kept in automatic list creation spool (as specified by "queueautomatic" parameter). Sympa keeps messages rejected for various reasons (badly formatted, looping etc.).',
        'gettext_unit' => 'days',
        'default'      => '10',
    },
    {   'name'       => 'clean_delay_queuebulk',
        'gettext_id' => 'Max age of outgoing bad messages',
        'gettext_comment' =>
            'Number of days "bad" messages are kept in message outgoing spool (as specified by "queuebulk" parameter). Sympa keeps messages rejected for various reasons (failed personalization, bad configuration on MTA etc.).',
        'gettext_unit' => 'days',
        'default'      => '7',
    },
    {   'name'       => 'clean_delay_queuedigest',
        'gettext_id' => 'Max age of bad messages in digest spool',
        'gettext_comment' =>
            'Number of days "bad" messages are kept in digest spool (as specified by "queuedigest" parameter). Sympa keeps messages rejected for various reasons (syntax errors in "digest.tt2" template etc.).',
        'gettext_unit' => 'days',
        'default'      => '14',
    },
    {   'name'       => 'clean_delay_tmpdir',
        'gettext_id' => 'Max age of temporary files',
        'gettext_comment' =>
            'Number of days files in temporary directory (as specified by "tmpdir" parameter), including standard error logs, are kept.',
        'gettext_unit' => 'days',
        'default'      => '7',
    },

##    {
##        'name'     => 'pidfile',
##        'default'  => Sympa::Constants::PIDDIR . '/sympa.pid',
##        'gettext_id' => 'File containing Sympa PID while running',
##        'file'     => 'sympa.conf',
##        'gettext_comment' =>
##        'Sympa also locks this file to ensure that it is not running more than once. Caution: user sympa need to write access without special privilege.',
##    },
##    {
##        'name'     => 'pidfile_distribute',
##        'default'  => Sympa::Constants::PIDDIR . '/sympa-distribute.pid',
##        'file'     => 'sympa.conf',
##    },
##    {
##        'name'     => 'pidfile_creation',
##        'default'  => Sympa::Constants::PIDDIR . '/sympa-creation.pid',
##        'file'     => 'sympa.conf',
##    },
##    {
##        'name'     => 'task_manager_pidfile',
##        'default'  => Sympa::Constants::PIDDIR . '/task_manager.pid',
##        'gettext_id' => 'File containing task_manager PID while running',
##        'file'     => 'wwsympa.conf',
##    },

    {'gettext_id' => 'Miscellaneous'},

    {   'name'       => 'email',
        'default'    => 'sympa',
        'gettext_id' => 'Local part of Sympa email address',
        'vhost'      => '1',
        'edit'       => '1',
        'file'       => 'sympa.conf',
        'gettext_comment' =>
            "Local part (the part preceding the \"\@\" sign) of the address by which mail interface of Sympa accepts mail commands.\nIf you change the default value, you must modify the mail aliases too.",
    },
    {   'name'       => 'listmaster_email',
        'default'    => 'listmaster',
        'gettext_id' => 'Local part of listmaster email address',
        'vhost'      => '1',
        'gettext_comment' =>
            "Local part (the part preceding the \"\@\" sign) of the address by which listmasters receive messages.\nIf you change the default value, you must modify the mail aliases too.",
    },
    {   'name'       => 'custom_robot_parameter',
        'gettext_id' => 'Custom robot parameter',
        'gettext_comment' =>
            "Used to define a custom parameter for your server. Do not forget the semicolon between the parameter name and the parameter value.\nYou will be able to access the custom parameter value in web templates by variable \"conf.custom_robot_parameter.<param_name>\"",
        'sample'   => 'param_name ; param_value',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'multiple' => '1',
        'optional' => '1',
    },

##    {
##        'name'     => 'lock_method',
##        'default'  => 'flock',
##        'gettext_comment' => 'flock | nfs',
##    },
    {   'name'       => 'cache_list_config',
        'default'    => 'none',
        'gettext_id' => 'Use of binary cache of list configuration',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            "binary_file: Sympa processes will maintain a binary version of the list configuration, \"config.bin\" file on local disk. If you manage a big amount of lists (1000+), it should make the web interface startup faster.\nYou can recreate cache by running \"sympa.pl --reload_list_config\".",
    },
    {   'name'       => 'db_list_cache',
        'default'    => 'off',
        'gettext_id' => 'Use database cache to search lists',
        'gettext_comment' =>
            "Note that \"list_table\" database table should be filled at the first time by running:\n  # sympa.pl --sync_list_db",
    },
    {   'name'       => 'purge_user_table_task',
        'gettext_id' => 'Task for expiring inactive users',
        'gettext_comment' =>
            'This task removes rows in the "user_table" table which have not corresponding entries in the "subscriber_table" table.',
        'default' => 'monthly',
        'task'    => 'purge_user_table',
    },
    {   'name'       => 'purge_logs_table_task',
        'gettext_id' => 'Task for cleaning tables',
        'gettext_comment' =>
            'This task cleans old logs from "logs_table" table.',
        'default' => 'daily',
        'task'    => 'purge_logs_table',
    },
    {   'name'       => 'logs_expiration_period',
        'gettext_id' => 'Max age of logs in database',
        'gettext_comment' =>
            'Number of months that elapse before a log is expired',
        'gettext_unit' => 'months',
        'default'      => '3',
        'file'         => 'sympa.conf',
    },
    {   'name'       => 'stats_expiration_period',
        'gettext_id' => 'Max age of statistics information in database',
        'gettext_comment' =>
            'Number of months that elapse before statistics information are expired',
        'gettext_unit' => 'months',
        'default'      => '3',
    },

    {   'name'       => 'umask',
        'default'    => '027',
        'gettext_id' => 'Umask',
        'gettext_comment' =>
            'Default mask for file creation (see umask(2)). Note that it will be interpreted as an octal value.',
        'file' => 'sympa.conf',
    },
    {   'name'       => 'cookie',
        'sample'     => '123456789',
        'gettext_id' => 'Secret string for generating unique keys',
        'file'       => 'sympa.conf',
        'obfuscated' => '1',
        'gettext_comment' =>
            "This allows generated authentication keys to differ from a site to another. It is also used for encryption of user passwords stored in the database. The presence of this string is one reason why access to \"sympa.conf\" needs to be restricted to the \"sympa\" user.\nNote that changing this parameter will break all HTTP cookies stored in users' browsers, as well as all user passwords and lists X509 private keys. To prevent a catastrophe, Sympa refuses to start if this \"cookie\" parameter was changed.",
        'optional' => '1',
    },

    {'gettext_id' => 'Web interface parameters'},

    # Basic configuration

    {   'name'       => 'wwsympa_url',
        'sample'     => 'https://web.example.org/sympa',
        'gettext_id' => 'URL prefix of web interface',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'optional'   => '1',
        'edit'       => '1',
        'gettext_comment' =>
            'This is used to construct URLs of web interface.',
    },
    {   'name'       => 'http_host',
        'gettext_id' => 'URL prefix of WWSympa behind proxy',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'optional'   => '1',
    },
    {   'name'       => 'static_content_url',
        'default'    => '/static-sympa',
        'gettext_id' => 'URL for static contents',
        'gettext_comment' =>
            'HTTP server have to map it with "static_content_path" directory.',
        'vhost' => '1',
        'edit'  => '1',
        'file'  => 'sympa.conf',
    },
    {   'name'       => 'static_content_path',
        'default_s'  => '$STATICDIR',
        'gettext_id' => 'Directory for static contents',
        'vhost'      => '1',
        'edit'       => '1',
        'file'       => 'sympa.conf',
    },
    {   'name'       => 'log_facility',
        'default'    => 'LOCAL1',
        'gettext_id' => 'System log facility for web interface',
        'gettext_comment' =>
            'System log facility for WWSympa, archived.pl and bounced.pl. Default is to use value of "syslog" parameter.',
        'file' => 'wwsympa.conf',
        'edit' => '1',
    },

    {'gettext_id' => 'Web interface parameters: Appearances'},

    {   'name'       => 'logo_html_definition',
        'gettext_id' => 'Custom logo',
        'gettext_comment' =>
            'HTML fragment to insert a logo in the page of web interface.',
        'sample' =>
            '<a href="http://www.example.com"><img style="float: left; margin-top: 7px; margin-left: 37px;" src="http://www.example.com/logos/mylogo.jpg" alt="My Company" /></a>',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'            => 'favicon_url',
        'gettext_id'      => 'Custom favicon',
        'gettext_comment' => 'URL of favicon image',
        'optional'        => '1',
        'vhost'           => '1',
        'optional'        => '1',
    },
    {   'name'       => 'css_path',
        'default_s'  => '$CSSDIR',
        'gettext_id' => 'Directory for static style sheets (CSS)',
        'gettext_comment' =>
            'After an upgrade, static CSS files are upgraded with the newly installed "css.tt2" template. Therefore, this is not a good place to store customized CSS files.',
    },
    {   'name'       => 'css_url',
        'default'    => '/static-sympa/css',
        'gettext_id' => 'URL for style sheets (CSS)',
        'gettext_comment' =>
            'To use auto-generated static CSS, HTTP server have to map it with "css_path".',
    },
    {   'name'       => 'pictures_path',
        'default_s'  => '$PICTURESDIR',
        'gettext_id' => 'Directory for subscribers pictures',
    },
    {   'name'       => 'pictures_url',
        'default'    => '/static-sympa/pictures',
        'gettext_id' => 'URL for subscribers pictures',
        'gettext_comment' =>
            'HTTP server have to map it with "pictures_path" directory.',
    },
    {   'name'       => 'color_0',
        'gettext_id' => 'Colors for web interface',
        'gettext_comment' =>
            'Colors are used in style sheet (CSS). They may be changed using web interface by listmasters.',
        'default' => '#f7f7f7',    # very light grey use in tables,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_1',
        'default' => '#222222',    # main menu button color,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_2',
        'default' => '#004b94',    # font color,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_3',
        'default' => '#5e5e5e',    # top boxe and footer box bacground color,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_4',
        'default' => '#4c4c4c',    #  page backgound color,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_5',
        'default' => '#0090e9',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_6',
        'default' => '#005ab2',    # list menu current button,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_7',
        'default' => '#ffffff',    # errorbackground color,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_8',
        'default' => '#f2f6f9',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_9',
        'default' => '#bfd2e1',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_10',
        'default' => '#983222',    # inactive button,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_11',
        'default' => '#66aaff',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_12',
        'default' => '#ffe7e7',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_13',
        'default' => '#f48a7b',    # input backgound  | transparent,
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_14',
        'default' => '#ffff99',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'color_15',
        'default' => '#fe57a1',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'       => 'dark_color',
        'gettext_id' => 'Colors for web interface, obsoleted',
        'default'    => '#c0c0c0',                               # 'silver'
        'vhost'      => '1',
        'db'         => 'db_first',
    },
    {   'name'    => 'light_color',
        'default' => '#aaddff',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'text_color',
        'default' => '#000000',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'bg_color',
        'default' => '#ffffcc',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'error_color',
        'default' => '#ff6666',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'selected_color',
        'default' => '#c0c0c0',          # 'silver'
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'    => 'shaded_color',
        'default' => '#66cccc',
        'vhost'   => '1',
        'db'      => 'db_first',
    },
    {   'name'       => 'default_home',
        'default'    => 'home',
        'gettext_id' => 'Type of main web page',
        'gettext_comment' =>
            '"lists" for the page of list of lists. "home" for home page.',
        'vhost' => '1',
        'file'  => 'wwsympa.conf',
        'edit'  => '1',
    },
    {   'name'       => 'archive_default_index',
        'default'    => 'thrd',
        'gettext_id' => 'Default index organization of web archive',
        'gettext_comment' =>
            "thrd: Threaded index.\nmail: Chronological index.",
        'file' => 'wwsympa.conf',
        'edit' => '1',
    },
    # { your_lists_size: not yet implemented. }
    {   'name'       => 'review_page_size',
        'gettext_id' => 'Size of review page',
        'gettext_comment' =>
            'Default number of lines of the array displaying users in the review page',
        'vhost'   => '1',
        'default' => 25,
        'file'    => 'wwsympa.conf',
    },
    {   'name'       => 'viewlogs_page_size',
        'gettext_id' => 'Size of viewlogs page',
        'gettext_comment' =>
            'Default number of lines of the array displaying the log entries in the logs page.',
        'vhost'   => '1',
        'default' => 25,
        'file'    => 'wwsympa.conf',
    },
    {   'name'       => 'main_menu_custom_button_1_title',
        'gettext_id' => 'Custom menus',
        'gettext_comment' =>
            'You may modify the main menu content by editing the menu.tt2 file, but you can also edit these parameters in order to add up to 3 buttons. Each button is defined by a title (the text in the button), an URL and, optionally, a target.',
        'sample'   => 'FAQ',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_2_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_3_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_1_url',
        'sample'   => 'http://www.renater.fr/faq/universalistes/index',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_2_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_3_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_1_target',
        'sample'   => 'Help',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_2_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {   'name'     => 'main_menu_custom_button_3_target',
        'optional' => '1',
        'vhost'    => '1',
    },

    {'gettext_id' => 'Web interface parameters: Miscellaneous'},

    # Session and cookie:

    {   'name'       => 'cookie_domain',
        'default'    => 'localhost',
        'sample'     => '.renater.fr',
        'gettext_id' => 'HTTP cookies validity domain',
        'gettext_comment' =>
            'If beginning with a dot ("."), the cookie is available within the specified Internet domain. Otherwise, for the specified host. The only reason for replacing the default value would be where WWSympa\'s authentication process is shared with an application running on another host.',
        'vhost' => '1',
        'file'  => 'wwsympa.conf',
    },
    {   'name'       => 'cookie_expire',
        'default'    => '0',
        'gettext_id' => 'HTTP cookies lifetime',
        'gettext_comment' =>
            'This is the default value when not set explicitly by users. "0" means the cookie may be retained during browser sessions.',
        'file' => 'wwsympa.conf',
    },
    {   'name'       => 'cookie_refresh',
        'default'    => '60',
        'gettext_id' => 'Average interval to refresh HTTP session ID.',
        'file'       => 'wwsympa.conf',
    },
    {   'name'       => 'purge_session_table_task',
        'gettext_id' => 'Task for cleaning old sessions',
        'gettext_comment' =>
            'This task removes old entries in the "session_table" table.',
        'default' => 'daily',
        'task'    => 'purge_session_table',
    },
    {   'name'       => 'session_table_ttl',
        'gettext_id' => 'Max age of sessions',
        'gettext_comment' =>
            "Session duration is controlled by \"sympa_session\" cookie validity attribute. However, by security reason, this delay also need to be controlled by server side. This task removes old entries in the \"session_table\" table.\nFormat of values is a string without spaces including \"y\" for years, \"m\" for months, \"d\" for days, \"h\" for hours, \"min\" for minutes and \"sec\" for seconds.",
        'default' => '2d',
    },
    {   'name'    => 'anonymous_session_table_ttl',
        'default' => '1h',
    },

    # Shared document repository

    {   'name'       => 'shared_feature',
        'gettext_id' => 'Enable shared repository',
        'gettext_comment' =>
            'If set to "on", list owners can open shared repository.',
        'vhost'   => '1',
        'edit'    => '1',
        'default' => 'off',
    },

    {   'name'         => 'default_shared_quota',
        'optional'     => '1',
        'gettext_id'   => 'Default disk quota for shared repository',
        'gettext_unit' => 'Kbytes',
        'vhost'        => '1',
        'file'         => 'sympa.conf',
        'edit'         => '1',
    },

    # HTML editor

    {   'name'       => 'use_html_editor',
        'gettext_id' => 'Use HTML editor',
        'gettext_comment' =>
            'If set to "on", users will be able to post messages in HTML using a javascript WYSIWYG editor.',
        'vhost'   => '1',
        'default' => '0',
        'sample'  => 'on',
        'edit'    => '1',
        'file'    => 'wwsympa.conf',
    },
    {   'name'       => 'html_editor_url',
        'gettext_id' => 'URL of HTML editor',
        'gettext_comment' =>
            "URL path to the javascript file making the WYSIWYG HTML editor available.  Relative path under <static_content_url> or absolute path.\nExample is for TinyMCE 4 installed under <static_content_path>/js/tinymce/.",
        'vhost'  => '1',
        'sample' => 'js/tinymce/tinymce.min.js',
        'file'     => 'sympa.conf',    # added after migration of wwsympa.conf
        'optional' => '1',
    },
    {   'name'       => 'html_editor_init',
        'gettext_id' => 'HTML editor initialization',
        'gettext_comment' =>
            'Javascript excerpt that enables and configures the WYSIWYG HTML editor.',
        'vhost' => '1',
        'sample' =>
            'tinymce.init({selector:"#body",language:lang.split(/[^a-zA-Z]+/).join("_")});',
        'file'     => 'wwsympa.conf',
        'optional' => '1',
    },
    ##{ html_editor_hide: not yet implemented. },
    ##{ html_editor_show: not yet implemented. },

    # Password

    {   'name'       => 'max_wrong_password',
        'gettext_id' => 'Count limit of wrong password submission',
        'gettext_comment' =>
            'If this limit is reached, the account is locked until the user renews their password. The default value is chosen in order to block bots trying to log in using brute force strategy. This value should never be reached by real users that will probably uses the renew password service before they performs so many tries.',
        'default' => '19',
        'vhost'   => '1',
        'file'    => 'sympa.conf',
    },
    {   'name'       => 'password_case',
        'default'    => 'insensitive',
        'gettext_id' => 'Password case',
        'file'       => 'wwsympa.conf',
        #vhost      => '1', # per-robot config is impossible.
        'gettext_comment' =>
            "\"insensitive\" or \"sensitive\".\nIf set to \"insensitive\", WWSympa's password check will be insensitive. This only concerns passwords stored in the Sympa database, not the ones in LDAP.\nShould not be changed! May invalid all user password.",
    },
    {   'name'       => 'password_hash',
        'default'    => 'md5',
        'gettext_id' => 'Password hashing algorithm',
        'file'       => 'wwsympa.conf',
        #vhost      => '1', # per-robot config is impossible.
        'gettext_comment' =>
            "\"md5\" or \"bcrypt\".\nIf set to \"md5\", Sympa will use MD5 password hashes. If set to \"bcrypt\", bcrypt hashes will be used instead. This only concerns passwords stored in the Sympa database, not the ones in LDAP.\nShould not be changed! May invalid all user passwords.",
    },
    {   'name'       => 'password_hash_update',
        'default'    => '1',
        'gettext_id' => 'Update password hashing algorithm when users log in',
        'file'       => 'wwsympa.conf',
        #vhost      => '1', # per-robot config is impossible.
        'gettext_comment' =>
            "On successful login, update the encrypted user password to use the algorithm specified by \"password_hash\". This allows for a graceful transition to a new password hash algorithm. A value of 0 disables updating of existing password hashes.  New and reset passwords will use the \"password_hash\" setting in all cases.",
    },
    {   'name'       => 'bcrypt_cost',
        'default'    => '12',
        'gettext_id' => 'Bcrypt hash cost',
        'file'       => 'wwsympa.conf',
        #vhost      => '1', # per-robot config is impossible.
        'gettext_comment' =>
            "When \"password_hash\" is set to \"bcrypt\", this sets the \"cost\" parameter of the bcrypt hash function. The default of 12 is expected to require approximately 250ms to calculate the password hash on a 3.2GHz CPU. This only concerns passwords stored in the Sympa database, not the ones in LDAP.\nCan be changed but any new cost setting will only apply to new passwords.",
    },

    # One time ticket

    {   'name'       => 'one_time_ticket_lifetime',
        'default'    => '2d',
        'gettext_id' => 'Age of one time ticket',
        'gettext_comment' =>
            'Duration before the one time tickets are expired',
    },
    {   'name'       => 'one_time_ticket_lockout',
        'default'    => 'one_time',
        'gettext_id' => 'Restrict access to one time ticket',
        'gettext_comment' =>
            'Is access to the one time ticket restricted, if any users previously accessed? (one_time | remote_addr | open)',
        'edit'  => '1',
        'vhost' => '1',
    },
    {   'name'    => 'purge_one_time_ticket_table_task',
        'default' => 'daily',
        'task'    => 'purge_one_time_ticket_table',
    },
    {   'name'    => 'one_time_ticket_table_ttl',
        'default' => '10d',
    },

    # Pictures

    {   'name'       => 'pictures_feature',
        'gettext_id' => 'Pictures',
        'gettext_comment' =>
            "Enables or disables the pictures feature by default.  If enabled, subscribers can upload their picture (from the \"Subscriber option\" page) to use as an avatar.\nPictures are stored in a directory specified by the \"static_content_path\" parameter.",
        'default' => 'on',
        'vhost'   => '1',
    },
    {   'name'         => 'pictures_max_size',
        'gettext_id'   => 'The maximum size of uploaded picture',
        'gettext_unit' => 'bytes',
        'default'      => 102400,                                   ## 100Kb,
        'vhost'        => '1',
    },

    # Protection against spam harvesters

    {   'name'       => 'spam_protection',
        'gettext_id' => 'Protect web interface against spam harvesters',
        'gettext_comment' =>
            "These values are supported:\njavascript: the address is hidden using a javascript. Users who enable Javascript can see nice mailto addresses where others have nothing.\nat: the \"\@\" character is replaced by the string \"AT\".\nnone: no protection against spam harvesters.",
        'default' => 'javascript',
        'vhost'   => '1',
    },
    {   'name'       => 'web_archive_spam_protection',
        'gettext_id' => 'Protect web archive against spam harvesters',
        'gettext_comment' =>
            "The same as \"spam_protection\", but restricted to the web archive.\nIn addition to it:\ncookie: users must submit a small form in order to receive a cookie before browsing the web archive.\ngecos: \nonly gecos is displayed.",
        'default' => 'cookie',
        'vhost'   => '1',
    },
    {   'name'       => 'reporting_spam_script_path',
        'optional'   => '1',
        'gettext_id' => 'Script to report spam',
        'gettext_comment' =>
            'If set, when a list moderator report undetected spams for list moderation, this external script is invoked and the message is injected into standard input of the script.',
        'vhost' => '1',
        'file'  => 'sympa.conf',
    },

    {   'name' => 'domains_blacklist',
        'gettext_id' =>
            'Prevent people to subscribe to a list with adresses using these domains',
        'gettext_comment' => 'This parameter is a comma-separated list.',
        'default'         => undef,
        'sample'          => 'example.org,spammer.com',
        'split_char'      => ',',
        'file'            => 'sympa.conf',
        'optional'        => 1,
    },
    {   'name'       => 'quiet_subscription',
        'gettext_id' => 'Quiet subscriptions policy',
        'gettext_comment' =>
            'Global policy for quiet subscriptions: "on" means that subscriptions will never send a notice to the subscriber, "off" will enforce a notice sending, and "optional" (default) allows the use of the list policy.',
        'default'  => 'optional',
        'file'     => 'sympa.conf',
        'optional' => 1,
    },

    # Sympa services: Optional features

    {   'gettext_id' => 'S/MIME and TLS',
        'gettext_comment' =>
            "S/MIME authentication, decryption and re-encryption. It requires these external modules: Crypt-OpenSSL-X509 and Crypt-SMIME.\nTLS client authentication. It requires an external module: IO-Socket-SSL.",
    },

#    {   'name'       => 'openssl',
#        'sample'     => '/usr/bin/ssl',
#        'gettext_id' => 'Path to OpenSSL',
#        'file'       => 'sympa.conf',
#        'edit'       => '1',
#        'gettext_comment' =>
#            'Sympa recognizes S/MIME if OpenSSL is installed',
#        'optional' => '1',
#    },
    {   'name'       => 'cafile',
        'gettext_id' => 'File containing trusted CA certificates',
        'gettext_comment' =>
            'This can be used alternatively and/or additionally to "capath".',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },
    {   'name'       => 'capath',
        'optional'   => '1',
        'gettext_id' => 'Directory containing trusted CA certificates',
        'gettext_comment' =>
            "CA certificates in this directory are used for client authentication.\nThe certificates need to have names including hash of subject, or symbolic links to them with such names. The links may be created by using \"c_rehash\" script bundled in OpenSSL.",
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },
    {   'name'       => 'key_passwd',
        'sample'     => 'your_password',
        'gettext_id' => 'Password used to crypt lists private keys',
        'gettext_comment' =>
            'If not defined, Sympa assumes that list private keys are not encrypted.',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'obfuscated' => '1',
        'optional'   => '1',
    },
    # Not yet implemented
    #{   'name'    => 'crl_dir',
    #    'default' => Sympa::Constants::EXPLDIR . '/crl',
    #    'file'    => 'sympa.conf',
    #},
    {   'name'       => 'ssl_cert_dir',
        'default_s'  => '$EXPLDIR/X509-user-certs',
        'gettext_id' => 'Directory containing user certificates',
        'file'       => 'sympa.conf',
    },

    {   'gettext_id' => 'Data sources setup',
        'gettext_comment' =>
            'Including subscribers, owners and moderators from data sources. Appropriate database driver (DBD) modules are required: DBD-CSV, DBD-mysql, DBD-ODBC, DBD-Oracle, DBD-Pg, DBD-SQLite and/or Net-LDAP. And also, if secure connection (LDAPS) to LDAP server is required: IO-Socket-SSL.',
    },

    {   'name'       => 'default_sql_fetch_timeout',
        'gettext_id' => 'Default of SQL fetch timeout',
        'gettext_comment' =>
            'Default timeout while performing a fetch with include_sql_query.',
        'file'    => 'sympa.conf',
        'default' => '300',
    },
    {   'name'       => 'default_ttl',
        'gettext_id' => 'Default of inclusion timeout',
        'gettext_comment' =>
            'Default timeout between two scheduled synchronizations of list members with data sources.',
        'file'    => 'sympa.conf',
        'default' => '3600',
    },

    {   'gettext_id' => 'DKIM and ARC',
        'gettext_comment' =>
            "DKIM signature verification and re-signing. It requires an external module: Mail-DKIM.\nARC seals on forwarded messages. It requires an external module: Mail-DKIM.",
    },

    {   'name'       => 'dkim_feature',
        'gettext_id' => 'Enable DKIM',
        'gettext_comment' =>
            'If set to "on", Sympa may verify DKIM signatures of incoming messages and/or insert DKIM signature to outgoing messages.',
        'default' => 'off',
        'vhost'   => '1',
        'file'    => 'sympa.conf',
    },
    {   'name'       => 'dkim_add_signature_to',
        'default'    => 'robot,list',
        'gettext_id' => 'Which service messages to be signed',
        'gettext_comment' =>
            'Inserts a DKIM signature to service messages in context of robot, list or both',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'split_char' => ',',
    },
    {   'name'       => 'dkim_private_key_path',
        'vhost'      => '1',
        'gettext_id' => 'File path for DKIM private key',
        'gettext_comment' =>
            'The file must contain a PEM encoded private key',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {   'name' => 'dkim_signature_apply_on',
        'default' =>
            'md5_authenticated_messages,smime_authenticated_messages,dkim_authenticated_messages,editor_validated_messages',
        'gettext_id' => 'Which messages delivered via lists to be signed',
        'gettext_comment' =>
            'Type of message that is added a DKIM signature before distribution to subscribers. Possible values are "none", "any" or a list of the following keywords: "md5_authenticated_messages", "smime_authenticated_messages", "dkim_authenticated_messages", "editor_validated_messages".',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'split_char' => ',',
    },
    {   'name'       => 'dkim_signer_domain',
        'vhost'      => '1',
        'gettext_id' => 'The "d=" tag as defined in rfc 4871',
        'gettext_comment' =>
            'The DKIM "d=" tag is the domain of the signing entity. The virtual host domain name is used as its default value',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {   'name'            => 'dkim_signer_identity',
        'vhost'           => '1',
        'gettext_id'      => 'The "i=" tag as defined in rfc 4871',
        'gettext_comment' => 'Default is null.',
        'optional'        => '1',
        'file'            => 'sympa.conf',
    },
    {   'name'       => 'dkim_selector',
        'gettext_id' => 'Selector for DNS lookup of DKIM public key',
        'gettext_comment' =>
            'The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for "<selector>._domainkey.your_domain"',
        'vhost'    => '1',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {   'name'       => 'arc_feature',
        'gettext_id' => 'Enable ARC',
        'gettext_comment' =>
            'If set to "on", Sympa may add ARC seals to outgoing messages.',
        'default' => 'off',
        'vhost'   => '1',
        'file'    => 'sympa.conf',
    },
    {   'name'       => 'arc_srvid',
        'gettext_id' => 'SRV ID for Authentication-Results used in ARC seal',
        'gettext_comment' => 'Typically the domain of the mail server',
        'vhost'           => '1',
        'optional'        => '1',
        'file'            => 'sympa.conf',
    },
    {   'name'       => 'arc_signer_domain',
        'vhost'      => '1',
        'gettext_id' => 'The "d=" tag as defined in ARC',
        'gettext_comment' =>
            'The ARC "d=" tag is the domain of the signing entity. The DKIM d= domain name is used as its default value',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {   'name'       => 'arc_selector',
        'gettext_id' => 'Selector for DNS lookup of ARC public key',
        'gettext_comment' =>
            'The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for "<selector>._domainkey.your_domain". Default is the same selector as for DKIM signatures',
        'vhost'    => '1',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {   'name'       => 'arc_private_key_path',
        'vhost'      => '1',
        'gettext_id' => 'File path for ARC private key',
        'gettext_comment' =>
            'The file must contain a PEM encoded private key. Defaults to same file as DKIM private key',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    # Not yet implemented.
    #{
    #    name => 'dkim_header_list',
    #    vhost => '1',
    #    file   => 'sympa.conf',
    #    'gettext_id' =>
    #        'List of headers to be included ito the message for signature',
    #    default =>
    #        'from:sender:reply-to:subject:date:message-id:to:cc:list-id:list-help:list-unsubscribe:list-subscribe:list-post:list-owner:list-archive:in-reply-to:references:resent-date:resent-from:resent-sender:resent-to:resent-cc:resent-message-id:mime-version:content-type:content-transfer-encoding:content-id:content-description',
    #},

    {   'gettext_id' => 'DMARC protection',
        'gettext_comment' =>
            'Processes originator addresses to avoid some domains\' excessive DMARC protection. This feature requires an external module: Net-DNS.',
    },

    {   'name'       => 'dmarc_protection_mode',
        'gettext_id' => 'Test mode(s) for DMARC Protection',
        'sample'     => 'dmarc_reject,dkim_signature',
        'vhost'      => '1',
        'edit'       => '1',
        'optional'   => '1',
        'gettext_comment' =>
            "Do not set unless you want to use DMARC protection.\nThis is a comma separated list of test modes; if multiple are selected then protection is activated if ANY match.  Do not use dmarc_* modes unless you have a local DNS cache as they do a DNS lookup for each received message.",
    },
    {   'name'       => 'dmarc_protection_domain_regex',
        'gettext_id' => 'Regular expression for domain name match',
        'vhost'      => '1',
        'edit'       => '1',
        'optional'   => '1',
        'gettext_comment' =>
            'This is used for the "domain_regex" protection mode.',
    },
    {   'name'       => 'dmarc_protection_phrase',
        'gettext_id' => 'New From name format',
        'gettext_comment' =>
            'This is the format to be used for the sender name part of the new From header field.',
        'vhost'    => '1',
        'edit'     => '1',
        'optional' => '1',
        'default'  => 'name_via_list',
    },
    {   'name'       => 'dmarc_protection_other_email',
        'gettext_id' => 'New From address',
        'vhost'      => '1',
        'edit'       => '1',
        'optional'   => '1',
    },

    {   'gettext_id' => 'List address verification',
        'gettext_comment' =>
            'Checks if an alias with the same name as the list to be created already exists on the SMTP server. This feature requires an external module: Net-SMTP.',
    },

    {   'name'     => 'list_check_helo',
        'optional' => '1',
        'gettext_id' =>
            'SMTP HELO (EHLO) parameter used for address verification',
        'vhost' => '1',
        'gettext_comment' =>
            'Default value is the host part of "list_check_smtp" parameter.',
    },
    {   'name'     => 'list_check_smtp',
        'optional' => '1',
        'gettext_id' =>
            'SMTP server to verify existence of the same addresses as the list to be created',
        'vhost' => '1',
        'gettext_comment' =>
            "This is needed if you are running Sympa on a host but you handle all your mail on a separate mail relay.\nDefault value is real FQDN of the host. Port number may be specified as \"mail.example.org:25\" or \"203.0.113.1:25\".  If port is not specified, standard port (25) will be used.",
    },
    {   'name'       => 'list_check_suffixes',
        'gettext_id' => 'Address suffixes to verify',
        'gettext_comment' =>
            "List of suffixes you are using for list addresses, i.e. \"mylist-request\", \"mylist-owner\" and so on.\nThis parameter is used with the \"list_check_smtp\" parameter. It is also used to check list names at list creation time.",
        'default'    => 'request,owner,editor,unsubscribe,subscribe',
        'vhost'      => '1',
        'split_char' => ',',
    },

    {'gettext_id' => 'Antivirus plug-in'},

    {   'name'       => 'antivirus_path',
        'optional'   => '1',
        'sample'     => '/usr/local/bin/clamscan',
        'gettext_id' => 'Path to the antivirus scanner engine',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            'Supported antivirus: Clam AntiVirus/clamscan & clamdscan, McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall',
    },
    {   'name'       => 'antivirus_args',
        'optional'   => '1',
        'sample'     => '--no-summary --database /usr/local/share/clamav',
        'gettext_id' => 'Antivirus plugin command line arguments',
        'vhost'      => '1',
        'file'       => 'sympa.conf',
        'edit'       => '1',
    },
    {   'name' => 'antivirus_notify',
        'gettext_id' =>
            'Notify sender if virus checker detects malicious content',
        'default' => 'sender',
        'vhost'   => '1',
        'gettext_comment' =>
            '"sender" to notify originator of the message, "delivery_status" to send delivery status, or "none"',
    },

    # Web interface: Optional features

    {   'gettext_id' => 'Password validation',
        'gettext_comment' =>
            'Checks if the password the user submitted has sufficient strength. This feature requires an external module: Data-Password.',
    },

    {   'name'       => 'password_validation',
        'gettext_id' => 'Password validation',
        'gettext_comment' =>
            'The password validation techniques to be used against user passwords that are added to mailing lists. Options come from Data::Password (http://search.cpan.org/~razinf/Data-Password-1.07/Password.pm#VARIABLES)',
        'sample' =>
            'MINLEN=8,GROUPS=3,DICTIONARY=4,DICTIONARIES=/pentest/dictionaries',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'optional' => '1',
    },

    {   'gettext_id' => 'Authentication with LDAP',
        'gettext_comment' =>
            'Authenticates users based on the directory on LDAP server. This feature requires an external module: Net-LDAP. And also, if secure connection (LDAPS) is required: IO-Socket-SSL.',
    },

    {   'name'       => 'ldap_force_canonical_email',
        'default'    => '1',
        'gettext_id' => 'Use canonical email address for LDAP authentication',
        'gettext_comment' =>
            'When using LDAP authentication, if the identifier provided by the user was a valid email, if this parameter is set to false, then the provided email will be used to authenticate the user. Otherwise, use of the first email returned by the LDAP server will be used.',
        'file'  => 'wwsympa.conf',
        'vhost' => '1',
    },

    {   'gettext_id' => 'SOAP HTTP interface',
        'gettext_comment' =>
            'Provides some functions of Sympa through the SOAP HTTP interface. This feature requires an external module: SOAP-Lite.',
    },

    {   'name'       => 'soap_url',
        'sample'     => 'http://web.example.org/sympasoap',
        'gettext_id' => 'URL of SympaSOAP',
        'vhost'      => '1',
        'optional'   => '1',
        'gettext_comment' =>
            'WSDL document of SympaSOAP refers to this URL in its service section.',
    },
    {   'name'       => 'soap_url_local',
        'gettext_id' => 'URL of SympaSOAP behind proxy',
        'vhost'      => '1',
        'optional'   => '1',
    },

    # Obsoleted or unknwon parameters (NOTE: Some of them are still alive!).

    {'gettext_id' => 'Obsoleted parameters'},

    {   'name'     => 'host',
        'optional' => 1,
        'vhost'    => '1',
    },
    {   'name'     => 'log_condition',
        'optional' => '1',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
    },
    {   'name'     => 'log_module',
        'optional' => '1',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
    },
    {   'name'    => 'filesystem_encoding',
        'default' => 'utf-8',
    },

    #FIXME: Is it currently available?
    {   'name' => 'automatic_list_prefix',
        'gettext_id' =>
            'Defines the prefix allowing to recognize that a list is an automatic list.',
        'file'     => 'sympa.conf',
        'optional' => '1',
    },
    {   'name' => 'default_distribution_ttl',    #FIXME: maybe not used
        'gettext_id' =>
            'Default timeout between two action-triggered synchronizations of list members with data sources.',
        'file'    => 'sympa.conf',
        'default' => '300',
    },

    {   'name'    => 'edit_list',                #FIXME:maybe not used
        'default' => 'owner',
        'file'    => 'sympa.conf',
    },
    {   'name'       => 'use_fast_cgi',
        'default'    => '1',
        'gettext_id' => 'Enable FastCGI',
        'file'       => 'wwsympa.conf',
        'edit'       => '1',
        'gettext_comment' =>
            'Is FastCGI module for HTTP server installed? This module provides a much faster web interface.',
    },
    {   'name'       => 'htmlarea_url',          # Deprecated on 6.2.36
        'gettext_id' => '',
        'default'    => undef,
        'file'       => 'wwsympa.conf',
        'optional'   => 1,
    },
    {   'name' => 'show_report_abuse',
        'gettext_id' =>
            'Add a "Report abuse" link in the side menu of the lists (0|1)',
        'gettext_comment' =>
            'The link is a mailto link, you can change that by overriding web_tt2/report_abuse.tt2',
        'default'  => '0',
        'file'     => 'sympa.conf',
        'optional' => 1,
    },
    {   'name' => 'allow_account_deletion',
        'gettext_id' =>
            'EXPERIMENTAL! Allow users to delete their account. If enabled, shows a "delete my account" form in user\'s preferences page.',
        'gettext_comment' =>
            'Account deletion unsubscribes the users from his/her lists and removes him/her from lists ownership. It is only available to users using internal authentication (i.e. no LDAP, no SSO...). See https://github.com/sympa-community/sympa/issues/300 for details',
        'default'  => '0',
        'file'     => 'sympa.conf',
        'optional' => 1,
    },

## Not implemented yet.
##    {
##        'name'     => 'chk_cert_expiration_task',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'crl_update_task',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'ldap_export_connection_timeout',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'ldap_export_dnmanager',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'ldap_export_host',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'ldap_export_name',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'ldap_export_password',
##        'optional' => '1',
##    },
##    {
##        'name'     => 'ldap_export_suffix',
##        'optional' => '1',
##    },
##    {   'name'    => 'purge_challenge_table_task',
##        'default' => 'daily',
##    },
##    {   'name'    => 'challenge_table_ttl',
##        'default' => '5d',
##    },
## No longer used
##    {
##        'name'     => 'sort',
##        'default'  => 'fr,ca,be,ch,uk,edu,*,com',
##    },
);

_apply_defaults();

sub _apply_defaults {
    foreach my $param (@params) {
        next unless exists $param->{default_s};

        my $default = $param->{default_s};
        $default =~ s{\$(\w\w+)}{
            my $func = Sympa::Constants->can($1);
            die sprintf 'Can\'t locate object method "%s" via package "%s"',
                $1, 'Sympa::Constants'
                unless $func;
            $func->()
        }eg;
        $param->{default} = $default;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ConfDef - Definition of site and robot configuration parameters

=head1 DESCRIPTION

This module keeps definition of configuration parameters for site default
and each robot.

=head2 Global variable

=over

=item @params

Includes following items in order parameters are shown.

=over

=item C<{ gettext_id =E<gt> TITLE }>

Title for the group of parameters following.

=item C<{ name =E<gt> NAME, DEFINITIONS, ... }>

Definition of parameter.  DEFINITIONS may contain following pairs.

=over

=item name =E<gt> NAME

Name of the parameter.

=item file =E<gt> FILE

Conf file where the parameter is defined.  If omitted, the
parameter won't be added automatically to the config file, even
if a default is set.
C<"wwsympa.conf"> is a synonym of C<"sympa.conf">.  It remains there
in order to migrating older versions of config.

=item default =E<gt> VALUE

Default value.
DON'T SET AN EMPTY DEFAULT VALUE! It's useless
and can lead to errors on fresh install.

=item gettext_id =E<gt> STRING

Description of the parameter.

=item gettext_comment =E<gt> STRING

Additional advice concerning the parameter.

=item sample =E<gt> STRING

FIXME FIXME

=item edit =E<gt> 1|0

This defines the parameters to be edited.

=item optional =E<gt> 1|0

FIXME FIXME

=item vhost =E<gt> 1|0

If 1, the parameter can have a specific value in a
virtual host.

=item db =E<gt> OPTION

'db_first', 'file_first' or 'no'.

=item obfuscated =E<gt> 1|0

FIXME FIXME

=item multiple =E<gt> 1|0

If 1, the parameter can have multiple values. Default is 0.

=item scenario =E<gt> 1|0

If 1, the parameter is the name of scenario.

=back

=back

=back

=head1 SEE ALSO

L<sympa.conf(5)>, L<robot.conf(5)>.

=head1 HISTORY

L<confdef> was separated from L<Conf> on Sympa 6.0a,
and renamed to L<Sympa::ConfDef> on 6.2a.39.

Descriptions of parameters in this source file were partially taken from
chapters "sympa.conf parameters" in
I<Sympa, Mailing List Management Software - Reference manual>, written by
Serge Aumont, Stefan Hornburg, Soji Ikeda, Olivier SalaE<252>n and
David Verdin.

=cut
