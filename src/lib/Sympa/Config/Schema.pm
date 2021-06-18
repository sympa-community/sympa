# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2020, 2021 The Sympa Community. See the
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

package Sympa::Config::Schema;

use strict;
use warnings;

use Sympa::Constants;
use Sympa::Regexps;

# Parameter defaults
my %default = (
    occurrence => '0-1',
    length     => 25
);

# DEPRECATED. No longer used.
#our @param_order;

# List parameter alias names
# DEPRECATED.  Use 'obsolete' elements.
#our %alias;

our %pgroup = (
    presentation => {
        order           => 1,
        gettext_id      => 'Service description',
        gettext_comment => '',
    },
    database => {
        order           => 2,
        gettext_id      => 'Database related',
        gettext_comment => '',
    },
    logging => {
        order           => 3,
        gettext_id      => 'System log',
        gettext_comment => '',
    },
    mta => {
        order => 4,
        #gettext_id      => 'Alias management',
        gettext_id      => 'Mail server',
        gettext_comment => '',
    },
    description => {
        order           => 10,
        gettext_id      => 'List definition',
        gettext_comment => '',
    },
    incoming => {
        order           => 19,
        gettext_id      => 'Receiving',
        gettext_comment => '',
    },
    sending => {
        order => 20,
        #gettext_id      => 'Sending related',
        gettext_id      => 'Sending/receiving setup',
        gettext_comment => '',
    },
    outgoing => {
        order           => 21,
        gettext_id      => 'Distribution',
        gettext_comment => '',
    },
    command => {
        order           => 30,
        gettext_id      => 'Privileges',
        gettext_comment => '',
    },
    archives => {
        order           => 40,
        gettext_id      => 'Archives',
        gettext_comment => '',
    },
    bounces => {
        order => 50,
        #gettext_id      => 'Bounce management and tracking',
        gettext_id      => 'Bounces',
        gettext_comment => '',
    },

    loop_prevention => {
        order           => 51,
        gettext_id      => 'Loop prevention',
        gettext_comment => '',
    },
    automatic_lists => {
        order           => 52,
        gettext_id      => 'Automatic lists',
        gettext_comment => '',
    },
    antispam => {
        order           => 53,
        gettext_id      => 'Tag based spam filtering',
        gettext_comment => '',
    },
    directories => {
        order           => 54,
        gettext_id      => 'Directories',
        gettext_comment => '',
    },
    other => {
        order           => 90,
        gettext_id      => 'Miscellaneous',
        gettext_comment => '',
    },

    www_basic => {
        order           => 110,
        gettext_id      => 'Web interface parameters',
        gettext_comment => '',
    },
    www_appearances => {
        order           => 120,
        gettext_id      => 'Web interface parameters: Appearances',
        gettext_comment => '',
    },
    www_other => {
        order           => 190,
        gettext_id      => 'Web interface parameters: Miscellaneous',
        gettext_comment => '',
    },

    crypto => {
        order      => 59,
        gettext_id => 'S/MIME and TLS',
        gettext_comment =>
            "S/MIME authentication, decryption and re-encryption. It requires these external modules: Crypt-OpenSSL-X509 and Crypt-SMIME.\nTLS client authentication. It requires an external module: IO-Socket-SSL.",
    },
    data_source => {
        order      => 60,
        gettext_id => 'Data sources setup',
        gettext_comment =>
            'Including subscribers, owners and moderators from data sources. Appropriate database driver (DBD) modules are required: DBD-CSV, DBD-mysql, DBD-ODBC, DBD-Oracle, DBD-Pg, DBD-SQLite and/or Net-LDAP. And also, if secure connection (LDAPS) to LDAP server is required: IO-Socket-SSL.',
    },
    dkim => {
        order => 70,
        #gettext_id => 'DKIM and ARC',
        gettext_id => 'DKIM/DMARC/ARC',
        gettext_comment =>
            "DKIM signature verification and re-signing. It requires an external module: Mail-DKIM.\nARC seals on forwarded messages. It requires an external module: Mail-DKIM.",
    },
    dmarc_protection => {    #FIXME: Not used?
        order      => 71,
        gettext_id => 'DMARC protection',
        gettext_comment =>
            'Processes originator addresses to avoid some domains\' excessive DMARC protection. This feature requires an external module: Net-DNS.',
    },

    list_check => {
        order      => 72,
        gettext_id => 'List address verification',
        gettext_comment =>
            'Checks if an alias with the same name as the list to be created already exists on the SMTP server. This feature requires an external module: Net-SMTP.',
    },
    antivirus => {
        order           => 73,
        gettext_id      => 'Antivirus plug-in',
        gettext_comment => '',
    },

    password_validation => {
        order      => 153,
        gettext_id => 'Password validation',
        gettext_comment =>
            'Checks if the password the user submitted has sufficient strength. This feature requires an external module: Data-Password.',
    },
    ldap_auth => {
        order      => 154,
        gettext_id => 'Authentication with LDAP',
        gettext_comment =>
            'Authenticates users based on the directory on LDAP server. This feature requires an external module: Net-LDAP. And also, if secure connection (LDAPS) is required: IO-Socket-SSL.',
    },
    sympasoap => {
        order      => 156,
        gettext_id => 'SOAP HTTP interface',
        gettext_comment =>
            'Provides some functions of Sympa through the SOAP HTTP interface. This feature requires an external module: SOAP-Lite.',
    },

    _obsoleted => {
        order           => 99999,
        gettext_id      => 'Obsoleted parameters',
        gettext_comment => '',
    },
);

my $site_obsolete =
    {context => [qw(site)], group => '_obsoleted', obsolete => 1};

our %pinfo = (

    # Initial configuration

    domain => {
        context => [qw(domain site)],    #FIXME:not used in robot.conf.
        order   => 1.01,
        group   => 'presentation',
        gettext_id => 'Primary mail domain name',
        format     => '[-\w]+(?:[.][-\w]+)+',
        sample     => 'mail.example.org',
        occurrence => '1',
    },
    listmaster => {
        context    => [qw(domain site)],
        order      => 1.02,
        group      => 'presentation',
        sample     => 'your_email_address@domain.tld',
        gettext_id => 'Email addresses of listmasters',
        split_char => ',',                                #FIXME
        gettext_comment =>
            'Email addresses of the listmasters (users authorized to perform global server commands). Some error reports may also be sent to these addresses. Listmasters can be defined for each virtual host, however, the default listmasters will have privileges to manage all virtual hosts.',
        format_s   => '$addrspec',
        occurrence => '1-n',
    },

    ### Global definition page ###

    supported_lang => {
        context => [qw(domain site)],
        order   => 1.10,
        group   => 'presentation',
        default =>
            'ca,cs,de,el,en-US,es,et,eu,fi,fr,gl,hu,it,ja,ko,nb,nl,oc,pl,pt-BR,ru,sv,tr,vi,zh-CN,zh-TW',
        gettext_id => 'Supported languages',
        split_char => ',',
        gettext_comment =>
            'All supported languages for the user interface. Languages proper locale information not installed are ignored.',
        format => '\w+(\-\w+)*',
    },
    title => {
        context    => [qw(domain site)],
        order      => 1.11,
        group      => 'presentation',
        default    => 'Mailing lists service',
        gettext_id => 'Title of service',
        gettext_comment =>
            'The name of your mailing list service. It will appear in the header of web interface and subjects of several service messages.',
        format => '.+',
        file   => 'wwsympa.conf',
    },
    gecos => {
        context    => [qw(domain site)],
        order      => 1.12,
        group      => 'presentation',
        default    => 'SYMPA',
        gettext_id => 'Display name of Sympa',
        gettext_comment =>
            'This parameter is used for display name in the "From:" header field for the messages sent by Sympa itself.',
        format => '.+',
    },
    legacy_character_support_feature => {
        context    => [qw(site)],
        order      => 1.13,
        group      => 'presentation',
        default    => 'off',
        gettext_id => 'Support of legacy character set',
        gettext_comment =>
            "If set to \"on\", enables support of legacy character set according to charset.conf(5) configuration file.\nIn some language environments, legacy encoding (character set) can be preferred for e-mail messages: for example iso-2022-jp in Japanese language.",
        format => ['on', 'off'],    #XXX
    },

    # Database

    update_db_field_types => {
        context    => [qw(site)],
        order      => 2.01,
        group      => 'database',
        gettext_id => 'Update database structure',
        gettext_comment =>
            "auto: Updates database table structures automatically.\nHowever, since version 5.3b.5, Sympa will not shorten field size if it already have been longer than the size defined in database definition.",
        format  => ['auto', 'off'],
        default => 'auto',
    },
    db_type => {
        context    => [qw(site)],
        order      => 2.10,
        group      => 'database',
        default    => 'mysql',
        gettext_id => 'Type of the database',
        gettext_comment =>
            'Possible types are "MySQL", "PostgreSQL", "Oracle" and "SQLite".',
        format     => '\w+',
        occurrence => '1',
    },
    db_host => {
        context => [qw(site)],
        order   => 2.11,
        group   => 'database',
        #default => 'localhost',
        sample     => 'localhost',
        gettext_id => 'Hostname of the database server',
        gettext_comment =>
            'With PostgreSQL, you can also use the path to Unix Socket Directory, e.g. "/var/run/postgresql" for connection with Unix domain socket.',
        format_s => '$host',
    },
    db_port => {
        context    => [qw(site)],
        order      => 2.12,
        group      => 'database',
        gettext_id => 'Port of the database server',
        format     => '[-/\w]+',
    },
    db_name => {
        context    => [qw(site)],
        order      => 2.13,
        group      => 'database',
        default    => 'sympa',
        gettext_id => 'Name of the database',
        gettext_comment =>
            "With SQLite, this must be the full path to database file.\nWith Oracle Database, this must be SID, net service name or easy connection identifier (to use net service name, db_host should be set to \"none\" and HOST, PORT and SERVICE_NAME should be defined in tnsnames.ora file).",
        format => '.+',
    },
    db_user => {
        context => [qw(site)],
        order   => 2.14,
        group   => 'database',
        #default => 'user_name',
        sample     => 'sympa',
        gettext_id => 'User for the database connection',
        format     => '.+',
    },
    db_passwd => {
        context => [qw(site)],
        order   => 2.15,
        group   => 'database',
        #default => 'user_password',
        sample     => 'your_passwd',
        gettext_id => 'Password for the database connection',
        field_type => 'password',
        gettext_comment =>
            'What ever you use a password or not, you must protect the SQL server (is it not a public internet service ?)',
        format => '.+',
    },
    db_options => {
        context    => [qw(site)],
        order      => 2.16,
        group      => 'database',
        gettext_id => 'Database options',
        gettext_comment =>
            'If these options are defined, they will be appended to data source name (DSN) fed to database driver. Check the related DBD documentation to learn about the available options.',
        format => '.+',
        sample =>
            'mysql_read_default_file=/home/joe/my.cnf;mysql_socket=tmp/mysql.sock-test',
    },
    db_env => {
        context    => [qw(site)],
        order      => 2.17,
        group      => 'database',
        gettext_id => 'Environment variables setting for database',
        gettext_comment =>
            'With Oracle Database, this is useful for defining ORACLE_HOME and NLS_LANG.',
        format => '.+',
        sample =>
            'NLS_LANG=American_America.AL32UTF8;ORACLE_HOME=/u01/app/oracle/product/11.2.0/server',
    },
    db_timeout => {
        context    => [qw(site)],
        order      => 2.18,
        group      => 'database',
        gettext_id => 'Database processing timeout',
        gettext_comment =>
            'Currently, this parameter may be used for SQLite only.',
        format => '\d+',
    },
    db_additional_subscriber_fields => {
        context    => [qw(site)],
        order      => 2.20,
        group      => 'database',
        sample     => 'billing_delay,subscription_expiration',
        gettext_id => 'Database private extension to subscriber table',
        split_char => ',',                                              #FIXME
        gettext_comment =>
            "Adds more fields to \"subscriber_table\" table. Sympa recognizes fields defined with this parameter. You will then be able to use them from within templates and scenarios:\n* for scenarios: [subscriber->field]\n* for templates: [% subscriber.field %]\nThese fields will also appear in the list members review page and will be editable by the list owner. This parameter is a comma-separated list.\nYou need to extend the database format with these fields",
        format     => '.+',
        occurrence => '0-n',
    },
    db_additional_user_fields => {
        context    => [qw(site)],
        order      => 2.21,
        group      => 'database',
        sample     => 'age,address',
        gettext_id => 'Database private extension to user table',
        split_char => ',',                                              #FIXME
        gettext_comment =>
            "Adds more fields to \"user_table\" table. Sympa recognizes fields defined with this parameter. You will then be able to use them from within templates: [% subscriber.field %]\nThis parameter is a comma-separated list.\nYou need to extend the database format with these fields",
        format     => '.+',
        occurrence => '0-n',
    },

    ### System log

    syslog => {
        context         => [qw(site)],
        order           => 3.01,
        group           => 'logging',
        default         => 'LOCAL1',
        gettext_id      => 'System log facility for Sympa',
        gettext_comment => 'Do not forget to configure syslog server.',
        format          => '\S+',
    },
    log_socket_type => {
        context    => [qw(site)],
        order      => 3.02,
        group      => 'logging',
        default    => 'unix',
        gettext_id => 'Communication mode with syslog server',
        format     => '\w+',
    },
    log_level => {
        context    => [qw(domain site)],    #FIXME "domain" possible?
        order      => 3.03,
        group      => 'logging',
        default    => '0',
        sample     => '2',
        gettext_id => 'Log verbosity',
        gettext_comment =>
            "Sets the verbosity of logs.\n0: Only main operations are logged\n3: Almost everything is logged.",
        format => '\d+',
    },

    ### Maili server (alias management & passing to the next hop)

    sendmail => {
        context    => [qw(site)],
        order      => 4.01,
        group      => 'mta',
        default    => '/usr/sbin/sendmail',
        gettext_id => 'Path to sendmail',
        gettext_comment =>
            "Absolute path to sendmail command line utility (e.g.: a binary named \"sendmail\" is distributed with Postfix).\nSympa expects this binary to be sendmail compatible (exim, Postfix, qmail and so on provide it).",
        format => '.+',
    },
    sendmail_args => {
        context    => [qw(site)],
        order      => 4.02,
        group      => 'mta',
        default    => '-oi -odi -oem',
        gettext_id => 'Command line parameters passed to sendmail',
        gettext_comment =>
            "Note that \"-f\", \"-N\" and \"-V\" options and recipient addresses should not be included, because they will be included by Sympa.",
        format => '.+',
    },

    sendmail_aliases => {
        context   => [qw(domain site)],
        order     => 4.03,
        group     => 'mta',
        default_s => '$SENDMAIL_ALIASES',
        gettext_id =>
            'Path of the file that contains all list related aliases',
        gettext_comment =>
            "It is recommended to create a specific alias file so that Sympa never overwrites the standard alias file, but only a dedicated file.\nSet this parameter to \"none\" if you want to disable alias management in Sympa.",
        format => '.+',
    },
    aliases_program => {
        context    => [qw(domain site)],
        order      => 4.04,
        group      => 'mta',
        format     => 'makemap|newaliases|postalias|postmap|/.+|none',
        default    => 'newaliases',
        gettext_id => 'Program used to update alias database',
        gettext_comment =>
            'This may be "makemap", "newaliases", "postalias", "postmap" or full path to custom program.',
        # Option "none" was added on 6.2.61b
    },
    aliases_wrapper => {
        context    => [qw(domain site)],
        order      => 4.045,
        group      => 'mta',
        format     => ['off', 'on'],
        synonym    => {'0' => 'off', '1' => 'on'},
        default    => 'on',
        gettext_id => 'Whether to use the alias wrapper',
        gettext_comment =>
            'If the program to update alias database does not require root privileges, set this parameter to "off" and remove the wrapper file sympa_newaliases-wrapper.',
    },
    aliases_db_type => {
        context    => [qw(domain site)],
        order      => 4.05,
        group      => 'mta',
        format     => '\w[-\w]*',
        default    => 'hash',
        gettext_id => 'Type of alias database',
        gettext_comment =>
            '"btree", "dbm", "hash" and so on.  Available when aliases_program is "makemap", "postalias" or "postmap"',
    },
    alias_manager => {
        context    => [qw(site)],
        order      => 4.06,
        group      => 'mta',
        gettext_id => 'Path to alias manager',
        gettext_comment =>
            'The absolute path to the script that will add/remove mail aliases',
        format => '.+',

        default_s => '$SBINDIR/alias_manager.pl',
        sample    => '/usr/local/libexec/ldap_alias_manager.pl',
    },

    ### List definition page ###

    subject => {
        context    => [qw(list)],
        order      => 10.01,
        group      => 'description',
        gettext_id => "Subject of the list",
        gettext_comment =>
            'This parameter indicates the subject of the list, which is sent in response to the LISTS mail command. The subject is a free form text limited to one line.',
        format     => '.+',
        occurrence => '1',
        length     => 50
    },

    visibility => {
        context    => [qw(list domain site)],
        order      => 10.02,
        group      => 'description',
        gettext_id => "Visibility of the list",
        gettext_comment =>
            'This parameter indicates whether the list should feature in the output generated in response to a LISTS command or should be shown in the list overview of the web-interface.',
        scenario => 'visibility',
        synonym  => {
            'public'  => 'noconceal',
            'private' => 'conceal'
        },
        default => 'conceal',
    },

    owner => {
        context  => [qw(list)],
        obsolete => 1,
        format   => {
            email => {
                context  => [qw(list)],
                obsolete => 1,
                format_s => '$email',
            },
            gecos => {
                context  => [qw(list)],
                obsolete => 1,
                format   => '.+',
            },
            info => {
                context  => [qw(list)],
                obsolete => 1,
                format   => '.+',
            },
            profile => {
                context  => [qw(list)],
                obsolete => 1,
                format   => ['privileged', 'normal'],
            },
            reception => {
                context  => [qw(list)],
                obsolete => 1,
                format   => ['mail', 'nomail'],
            },
            visibility => {
                context  => [qw(list)],
                obsolete => 1,
                format   => ['conceal', 'noconceal'],
            }
        },
        occurrence => '1-n'
    },

    editor => {
        context  => [qw(list)],
        obsolete => 1,
        format   => {
            email => {
                context  => [qw(list)],
                obsolete => 1,
                format_s => '$email',
            },
            reception => {
                context  => [qw(list)],
                obsolete => 1,
                format   => ['mail', 'nomail'],
            },
            visibility => {
                context  => [qw(list)],
                obsolete => 1,
                format   => ['conceal', 'noconceal'],
            },
            gecos => {
                context  => [qw(list)],
                obsolete => 1,
                format   => '.+',
            },
            info => {
                context  => [qw(list)],
                obsolete => 1,
                format   => '.+',
            }
        },
        occurrence => '0-n'
    },

    topics => {
        context    => [qw(list)],
        order      => 10.07,
        group      => 'description',
        gettext_id => "Topics for the list",
        gettext_comment =>
            "This parameter allows the classification of lists. You may define multiple topics as well as hierarchical ones. WWSympa's list of public lists uses this parameter.",
        format     => [],            # Sympa::Robot::topic_keys() called later
        field_type => 'listtopic',
        split_char => ',',
        occurrence => '0-n',
        filters    => ['lc'],
    },

    host => {
        context    => [qw(list domain site)],
        order      => 10.08,
        group      => 'description',
        gettext_id => "Internet domain",
        gettext_comment =>
            'Domain name of the list, default is the robot domain name set in the related robot.conf file or in file sympa.conf.',
        format_s => '$host',
        filters  => ['canonic_domain'],
        length   => 20,
        obsolete => 1
    },

    lang => {
        context    => [qw(list domain site)],
        order      => 10.09,
        group      => 'description',
        gettext_id => "Language of the list",
        #gettext_id => 'Default language',
        gettext_comment =>
            "This parameter defines the language used for the list. It is used to initialize a user's language preference; Sympa command reports are extracted from the associated message catalog.",
        #gettext_comment =>
        #    'This is the default language used by Sympa. One of supported languages should be chosen.',
        format => [],    ## Sympa::get_supported_languages() called later
        file_format => '\w+(\-\w+)*',
        field_type  => 'lang',
        occurrence  => '1',
        filters     => ['canonic_lang'],
        default     => 'en-US',
    },

    family_name => {
        context    => [qw(list)],
        order      => 10.10,
        group      => 'description',
        gettext_id => 'Family name',
        format_s   => '$family_name',
        occurrence => '0-1',
        internal   => 1
    },

    max_list_members => {
        context    => [qw(list domain site)],
        order      => 10.11,
        group      => 'description',                     # incoming / sending?
        gettext_id => "Maximum number of list members",
        gettext_comment =>
            'limit for the number of subscribers. 0 means no limit.',
        gettext_unit => 'list members',
        format       => '\d+',
        length       => 8,
        default      => '0',
    },

    # Incoming
    # - Approximately corresponds to ProcessIncoming and DoMessage spindles.
    # - Does _not_ contain the parameters with List context.

    sender_headers => {
        context => [qw(site)],
        order   => 19.00_02,
        group   => 'incoming',
        default => 'From',
        sample  => 'Resent-From,From,Return-Path',
        gettext_id =>
            'Header field name(s) used to determine sender of the messages',
        gettext_comment =>
            '"Return-Path" means envelope sender (a.k.a. "UNIX From") which will be alternative to sender of messages without "From" field.  "Resent-From" may also be inserted before "From", because some mailers add it into redirected messages and keep original "From" field intact.  In particular cases, "Return-Path" can not give right sender: Several mail gateway products rewrite envelope sender and add original one as non-standard field such as "X-Envelope-From".  If that is the case, you might want to insert it in place of "Return-Path".',
        split_char => ',',
    },

    misaddressed_commands => {
        context    => [qw(site)],
        order      => 19.00_03,
        group      => 'incoming',
        gettext_id => 'Reject misaddressed commands',
        gettext_comment =>
            'When a mail command is sent to a list, by default Sympa rejects this message. This feature can be turned off by setting this parameter to "ignore".',
        default => 'reject',
    },
    misaddressed_commands_regexp => {
        context => [qw(site)],
        order   => 19.00_04,
        group   => 'incoming',
        gettext_id =>
            'Regular expression matching with misaddressed commands',
        gettext_comment =>
            'Perl regular expression applied on messages subject and body to detect misaddressed commands.',
        default =>
            '((subscribe\s+(\S+)|unsubscribe\s+(\S+)|signoff\s+(\S+)|set\s+(\S+)\s+(mail|nomail|digest))\s*)',
    },
    sympa_priority => {
        context    => [qw(domain site)],
        order      => 19.00_05,
        group      => 'incoming',
        gettext_id => 'Priority for command messages',
        gettext_comment =>
            'Priority applied to messages sent to Sympa command address.',
        format  => [0 .. 9, 'z'],
        default => '1',
    },
    request_priority => {
        context    => [qw(domain site)],
        order      => 19.00_06,
        group      => 'incoming',
        gettext_id => 'Priority for messages bound for list owners',
        gettext_comment =>
            'Priority for processing of messages bound for "LIST-request" address, i.e. owners of the list',
        format  => [0 .. 9, 'z'],
        default => '0',
    },
    owner_priority => {
        context    => [qw(domain site)],
        order      => 19.00_07,
        group      => 'incoming',
        gettext_id => 'Priority for non-VERP bounces',
        gettext_comment =>
            'Priority for processing of messages bound for "LIST-owner" address, i.e. non-delivery reports (bounces).',
        format  => [0 .. 9, 'z'],
        default => '9',
    },

    priority => {
        context    => [qw(list domain site)],
        order      => 10.12,
        group      => 'description',            # incoming / sending?
        gettext_id => "Priority",
        gettext_comment =>
            'The priority with which Sympa will process messages for this list. This level of priority is applied while the message is going through the spool. The z priority will freeze the message in the spool.',
        #gettext_comment =>
        #    'Priority for processing of messages posted to list addresses.',
        format     => [0 .. 9, 'z'],
        length     => 1,
        occurrence => '1',
        default    => '5',
    },

    incoming_max_count => {
        context    => [qw(site)],
        order      => 19.00_10,
        group      => 'incoming',
        default    => '1',
        gettext_id => 'Max number of sympa.pl workers',
        gettext_comment =>
            'Max number of workers of sympa.pl daemon processing incoming spool.',
        format => '\d+',
    },

    sleep => {
        context         => [qw(site)],
        order           => 19.00_11,
        group           => 'incoming',
        default         => '5',
        gettext_id      => 'Interval between scanning incoming message spool',
        gettext_comment => 'Must not be 0.',
        format          => '\d+',
        gettext_unit    => 'seconds',
    },

    ### Sending page ###
    # - Approximately corresponds to AuthorizeMessage, Transform*, ToArchive,
    #   ToDigest and ToList spindles.
    # - Contains the parameters with List context.

    send => {
        context    => [qw(list domain site)],
        order      => 20.01,
        group      => 'sending',
        gettext_id => "Who can send messages",
        gettext_comment =>
            'This parameter specifies who can send messages to the list.',
        scenario => 'send',
        default  => 'private',
    },

    delivery_time => {
        context    => [qw(list)],
        order      => 20.02,
        group      => 'sending',
        gettext_id => "Delivery time (hh:mm)",
        gettext_comment =>
            'If this parameter is present, non-digest messages will be delivered to subscribers at this time: When this time has been past, delivery is postponed to the same time in next day.',
        format     => '[0-2]?\d\:[0-6]\d',
        occurrence => '0-1',
        length     => 5
    },

    digest => {
        context    => [qw(list)],
        order      => 20.03,
        group      => 'sending',
        gettext_id => "Digest frequency",
        gettext_comment =>
            'Definition of digest mode. If this parameter is present, subscribers can select the option of receiving messages in multipart/digest MIME format, or as a plain text digest. Messages are then grouped together, and compiled messages are sent to subscribers according to the frequency selected with this parameter.',
        file_format => '\d+(\s*,\s*\d+)*\s+\d+:\d+',
        format      => {
            days => {
                context     => [qw(list)],
                order       => 1,
                gettext_id  => "days",
                format      => [0 .. 6],
                file_format => '1|2|3|4|5|6|7',
                field_type  => 'dayofweek',
                occurrence  => '1-n'
            },
            hour => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "hour",
                format     => '\d+',
                occurrence => '1',
                length     => 2
            },
            minute => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "minute",
                format     => '\d+',
                occurrence => '1',
                length     => 2
            }
        },
    },

    digest_max_size => {
        context      => [qw(list)],
        order        => 20.04,
        group        => 'sending',
        gettext_id   => "Digest maximum number of messages",
        gettext_unit => 'messages',
        format       => '\d+',
        default      => 25,
        length       => 2
    },

    available_user_options => {
        context    => [qw(list)],
        order      => 20.05,
        group      => 'sending',
        gettext_id => "Available subscription options",
        format     => {
            reception => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "reception mode",
                gettext_comment =>
                    'Only these modes will be allowed for the subscribers of this list. If a subscriber has a reception mode not in the list, Sympa uses the mode specified in the default_user_options paragraph.',
                format => [
                    'mail',    'notice', 'digest', 'digestplain',
                    'summary', 'nomail', 'txt',    'urlize',
                    'not_me'
                ],
                synonym    => {'html' => 'mail'},
                field_type => 'reception',
                occurrence => '1-n',
                split_char => ',',
                default =>
                    'mail,notice,digest,digestplain,summary,nomail,txt,urlize,not_me'
            }
        }
    },

    default_user_options => {
        context         => [qw(list)],
        order           => 20.06,
        group           => 'sending',
        gettext_id      => "Subscription profile",
        gettext_comment => 'Default profile for the subscribers of the list.',
        format          => {
            reception => {
                context         => [qw(list)],
                order           => 1,
                gettext_id      => "reception mode",
                gettext_comment => 'Mail reception mode.',
                format          => [
                    'mail',    'notice', 'digest', 'digestplain',
                    'summary', 'nomail', 'txt',    'urlize',
                    'not_me'
                ],
                synonym    => {'html' => 'mail'},
                field_type => 'reception',
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                context         => [qw(list)],
                order           => 2,
                gettext_id      => "visibility",
                gettext_comment => 'Visibility of the subscriber.',
                format          => ['conceal', 'noconceal'],
                field_type      => 'visibility',
                occurrence      => '1',
                default         => 'noconceal'
            }
        },
    },

    msg_topic => {
        context    => [qw(list)],
        order      => 20.07,
        group      => 'sending',
        gettext_id => "Topics for message categorization",
        gettext_comment =>
            "This paragraph defines a topic used to tag a message of a list, named by msg_topic.name (\"other\" is a reserved word), its title is msg_topic.title. The msg_topic.keywords entry is optional and allows automatic tagging. This should be a list of keywords, separated by ','.",
        format => {
            name => {
                context     => [qw(list)],
                order       => 1,
                gettext_id  => "Message topic name",
                format      => '[\-\w]+',
                occurrence  => '1',
                length      => 15,
                validations => ['reserved_msg_topic_name'],
            },
            keywords => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "Message topic keywords",
                format     => '[^,\n]+(,[^,\n]+)*',
                occurrence => '0-1'
            },
            title => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "Message topic title",
                format     => '.+',
                occurrence => '1',
                length     => 35
            }
        },
        occurrence => '0-n'
    },

    msg_topic_keywords_apply_on => {
        context => [qw(list)],
        order   => 20.08,
        group   => 'sending',
        gettext_id =>
            "Defines to which part of messages topic keywords are applied",
        gettext_comment =>
            'This parameter indicates which part of the message is used to perform automatic tagging.',
        format     => ['subject', 'body', 'subject_and_body'],
        occurrence => '0-1',
        default    => 'subject'
    },

    msg_topic_tagging => {
        context    => [qw(list)],
        order      => 20.09,
        group      => 'sending',
        gettext_id => "Message tagging",
        gettext_comment =>
            'This parameter indicates if the tagging is optional or required for a list.',
        format     => ['required_sender', 'required_moderator', 'optional'],
        occurrence => '1',
        default    => 'optional'
    },

    reply_to => {
        context    => [qw(list)],
        group      => 'sending',
        gettext_id => "Reply address",
        format     => '\S+',
        default    => 'sender',
        obsolete   => 1
    },
    'reply-to' => {obsolete => 'reply_to'},
    replyto    => {obsolete => 'reply_to'},

    forced_reply_to => {
        context    => [qw(list)],
        group      => 'sending',
        gettext_id => "Forced reply address",
        format     => '\S+',
        obsolete   => 1
    },
    forced_replyto    => {obsolete => 'forced_reply_to'},
    'forced_reply-to' => {obsolete => 'forced_reply_to'},

    reply_to_header => {
        context    => [qw(list)],
        order      => 20.10,
        group      => 'sending',
        gettext_id => "Reply address",
        gettext_comment =>
            'This defines what Sympa will place in the Reply-To: SMTP header field of the messages it distributes.',
        format => {
            value => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "value",
                gettext_comment =>
                    "This parameter indicates whether the Reply-To: field should indicate the sender of the message (sender), the list itself (list), both list and sender (all) or an arbitrary e-mail address (defined by the other_email parameter).\nNote: it is inadvisable to change this parameter, and particularly inadvisable to set it to list. Experience has shown it to be almost inevitable that users, mistakenly believing that they are replying only to the sender, will send private messages to a list. This can lead, at the very least, to embarrassment, and sometimes to more serious consequences.",
                format     => ['sender', 'list', 'all', 'other_email'],
                default    => 'sender',
                occurrence => '1'
            },
            other_email => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "other email address",
                gettext_comment =>
                    'If value was set to other_email, this parameter defines the e-mail address used.',
                format_s => '$email',
            },
            apply => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "respect of existing header field",
                gettext_comment =>
                    'The default is to respect (preserve) the existing Reply-To: SMTP header field in incoming messages. If set to forced, Reply-To: SMTP header field will be overwritten.',
                format  => ['forced', 'respect'],
                default => 'respect'
            }
        }
    },

    anonymous_sender => {
        context    => [qw(list)],
        order      => 20.11,
        group      => 'sending',
        gettext_id => "Anonymous sender",
        gettext_comment =>
            "To hide the sender's email address before distributing the message. It is replaced by the provided email address.",
        format => '.+'
    },

    anonymous_header_fields => {
        context => [qw(site)],
        order   => 20.11_1,
        group   => 'sending',
        gettext_id =>
            'Header fields removed when a mailing list is setup in anonymous mode',
        gettext_comment =>
            "See \"anonymous_sender\" list parameter.\nDefault value prior to Sympa 6.1.19 is:\n  Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender",
        default =>
            'Authentication-Results,Disposition-Notification-To,DKIM-Signature,Injection-Info,Organisation,Organization,Original-Recipient,Originator,Path,Received,Received-SPF,Reply-To,Resent-Reply-To,Return-Receipt-To,X-Envelope-From,X-Envelope-To,X-Sender,X-X-Sender',
        split_char => ',',
    },

    custom_header => {
        context    => [qw(list)],
        order      => 20.12,
        group      => 'sending',
        gettext_id => "Custom header field",
        gettext_comment =>
            'This parameter is optional. The headers specified will be added to the headers of messages distributed via the list. As of release 1.2.2 of Sympa, it is possible to put several custom header lines in the configuration file at the same time.',
        format     => '\S+:\s+.*',
        occurrence => '0-n',
        length     => 30
    },
    'custom-header' => {obsolete => 'custom_header'},

    custom_subject => {
        context    => [qw(list)],
        order      => 20.13,
        group      => 'sending',
        gettext_id => "Subject tagging",
        gettext_comment =>
            'This parameter is optional. It specifies a string which is added to the subject of distributed messages (intended to help users who do not use automatic tools to sort incoming messages). This string will be surrounded by [] characters.',
        format => '.+',
        length => 15
    },
    'custom-subject' => {obsolete => 'custom_subject'},

    footer_type => {
        context    => [qw(list)],
        order      => 20.14,
        group      => 'sending',
        gettext_id => "Attachment type",
        gettext_comment =>
            "List owners may decide to add message headers or footers to messages sent via the list. This parameter defines the way a footer/header is added to a message.\nmime: \nThe default value. Sympa will add the footer/header as a new MIME part.\nappend: \nSympa will not create new MIME parts, but will try to append the header/footer to the body of the message. Predefined message-footers will be ignored. Headers/footers may be appended to text/plain messages only.",
        format  => ['mime', 'append'],
        default => 'mime'
    },

    max_size => {
        context    => [qw(list domain host)],
        order      => 20.15,
        group      => 'sending',                # incoming / sending?
        gettext_id => "Maximum message size",
        gettext_comment => 'Maximum size of a message in 8-bit bytes.',
        #gettext_id => 'Maximum size of messages',
        #gettext_comment =>
        #    'Incoming messages smaller than this size is allowed distribution by Sympa.',
        gettext_unit => 'bytes',
        format       => '\d+',
        length       => 8,
        default      => '5242880',    ## 5 MiB
        sample       => '2097152',
    },
    'max-size' => {obsolete => 'max_size'},

    personalization_feature => {
        context    => [qw(list domain site)],
        order      => 20.16,
        group      => 'sending',                         # outgoing / sending?
        gettext_id => "Allow message personalization",
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'off',
    },
    merge_feature => {obsolete => 'personalization_feature'},

    personalization => {
        context    => [qw(list domain site)],
        order      => 20.161,
        group      => 'sending',
        gettext_id => "Message personalization",
        format     => {
            web_apply_on => {
                context    => [qw(list domain site)],
                order      => 1,
                group      => 'sending',
                gettext_id => 'Scope for messages from the web interface',
                format     => ['none', 'footer', 'all'],
                default    => 'footer',
                occurrence => '1'
            },
            mail_apply_on => {
                context    => [qw(list domain site)],
                order      => 2,
                group      => 'sending',
                gettext_id => 'Scope for messages from incoming email',
                format     => ['none', 'footer', 'all'],
                default    => 'none',
                occurrence => '1'
            },
        },
    },

    message_hook => {
        context    => [qw(list)],
        order      => 20.17,
        group      => 'sending',
        gettext_id => 'Hook modules for message processing',
        format     => {
            pre_distribute => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'A hook on the messages before distribution',
                format     => '(::|\w)+',
            },
            post_archive => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => 'A hook on the messages just after archiving',
                format     => '(::|\w)+',
            },
        },
    },

    reject_mail_from_automates_feature => {
        context => [qw(list site)],
        order   => 20.18,
        group   => 'sending',         # incoming / sending?
        gettext_id => "Reject mail from automatic processes (crontab, etc)?",
        #gettext_id => 'Reject mail sent from automated services to list',
        gettext_comment =>
            "Rejects messages that seem to be from automated services, based on a few header fields (\"Content-Identifier:\", \"Auto-Submitted:\").\nSympa also can be configured to reject messages based on the \"From:\" header field value (see \"loop_prevention_regex\").",
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'on',
    },

    remove_headers => {
        context => [qw(list site)],
        order   => 20.19,
        group   => 'sending',         # outgoing / sending?
        #gettext_id => 'Incoming SMTP header fields to be removed',
        gettext_id => 'Header fields to be removed from incoming messages',
        gettext_comment =>
            "Use it, for example, to ensure some privacy for your users in case that \"anonymous_sender\" mode is inappropriate.\nThe removal of these header fields is applied before Sympa adds its own header fields (\"rfc2369_header_fields\" and \"custom_header\").",
        format => '\S+',
        default =>
            'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To,Sender',
        sample =>
            'Resent-Date,Resent-From,Resent-To,Resent-Message-Id,Sender,Delivered-To',
        occurrence => '0-n',
        split_char => ','
    },

    remove_outgoing_headers => {
        context => [qw(list site)],
        order   => 20.20,
        group   => 'sending',         # outgoing /  sending?
        #gettext_id => 'Outgoing SMTP header fields to be removed',
        gettext_id =>
            'Header fields to be removed before message distribution',
        gettext_comment =>
            "The removal happens after Sympa's own header fields are added; therefore, it is a convenient way to remove Sympa's own header fields (like \"X-Loop:\" or \"X-no-archive:\") if you wish.",
        format     => '\S+',
        default    => 'none',
        sample     => 'X-no-archive',
        occurrence => '0-n',
        split_char => ','
    },

    rfc2369_header_fields => {
        context => [qw(list site)],
        order   => 20.21,
        group   => 'sending',         # outgoing / sending?
        #gettext_id => "RFC 2369 Header fields",
        gettext_id => 'RFC 2369 header fields',
        gettext_comment =>
            "Specify which RFC 2369 mailing list header fields to be added.\n\"List-Id:\" header field defined in RFC 2919 is always added. Sympa also adds \"Archived-At:\" header field defined in RFC 5064.",
        format =>
            ['help', 'subscribe', 'unsubscribe', 'post', 'owner', 'archive'],
        default    => 'help,subscribe,unsubscribe,post,owner,archive',
        occurrence => '0-n',
        split_char => ','
    },

    ### Outgoing
    # - Corresponds to ProcessOutgoing and ToMailer spindles.
    # - Does _not_ contain the parameters with List context.

    urlize_min_size => {
        context    => [qw(domain site)],
        order      => 21.00_11,
        group      => 'outgoing',                     # 'sending'?
        gettext_id => 'Minimum size to be urlized',
        gettext_comment =>
            'When a subscriber chose "urlize" reception mode, attachments not smaller than this size will be urlized.',
        format       => '\d+',
        gettext_unit => 'bytes',
        default      => 10240,                        # 10 kiB
    },
    allowed_external_origin => {
        context    => [qw(domain site)],
        order      => 21.00_12,
        group      => 'outgoing',                                # 'archives'?
        gettext_id => 'Allowed external links in sanitized HTML',
        gettext_comment =>
            'When the HTML content of a message must be sanitized, links ("href" or "src" attributes) with the hosts listed in this parameter will not be scrubbed. If "*" character is included, it matches any subdomains. Single "*" allows any hosts.',
        format     => '[-\w*]+(?:[.][-\w*]+)+',
        split_char => ',',
        sample     => '*.example.org,www.example.com',
    },

    sympa_packet_priority => {
        context    => [qw(domain site)],
        order      => 21.00_20,
        group      => 'outgoing',
        gettext_id => 'Default priority for a packet',
        default    => '5',
        gettext_comment =>
            'The default priority set to a packet to be sent by the bulk.',
        format => [0 .. 9, 'z'],
    },
    bulk_fork_threshold => {
        context    => [qw(site)],
        order      => 21.00_21,
        group      => 'outgoing',
        default    => '1',
        gettext_id => 'Fork threshold of bulk daemon',
        gettext_comment =>
            'The minimum number of packets before bulk daemon forks a new worker to increase sending rate.',
        format => '\d+',
    },
    bulk_max_count => {
        context    => [qw(site)],
        order      => 21.00_22,
        group      => 'outgoing',
        default    => '3',
        gettext_id => 'Maximum number of bulk workers',
        format     => '\d+',
    },
    bulk_lazytime => {
        context    => [qw(site)],
        order      => 21.00_23,
        group      => 'outgoing',
        default    => '600',
        gettext_id => 'Idle timeout of bulk workers',
        gettext_comment =>
            'The number of seconds a bulk worker will remain running without processing a message before it spontaneously exits.',
        format       => '\d+',
        gettext_unit => 'seconds',
    },
    bulk_sleep => {
        context    => [qw(site)],
        order      => 21.00_24,
        group      => 'outgoing',
        default    => '1',
        gettext_id => 'Sleep time of bulk workers',
        gettext_comment =>
            "The number of seconds a bulk worker sleeps between starting a new loop if it didn't find a message to send.\nKeep it small if you want your server to be reactive.",
        format       => '\d+',
        gettext_unit => 'seconds',
    },
    bulk_wait_to_fork => {
        context    => [qw(site)],
        order      => 21.00_25,
        group      => 'outgoing',
        default    => '10',
        gettext_id => 'Interval between checks of packet numbers',
        gettext_comment =>
            "Number of seconds a master bulk daemon waits between two packets number checks.\nKeep it small if you expect brutal increases in the message sending load.",
        format       => '\d+',
        gettext_unit => 'seconds',
    },

    log_smtp => {
        context    => [qw(domain site)],
        order      => 21.00_32,
        group      => 'outgoing',
        gettext_id => 'Log invocation of sendmail',
        gettext_comment =>
            'This can be overwritten by "-m" option for sympa.pl.',
        format  => ['on', 'off'],    #XXX
        default => 'off',
    },
    maxsmtp => {
        context    => [qw(site)],
        order      => 21.00_33,
        group      => 'outgoing',
        default    => '40',
        sample     => '500',
        gettext_id => 'Maximum number of sendmail processes',
        gettext_comment =>
            "Maximum number of simultaneous child processes spawned by Sympa. This is the main load control parameter. \nProposed value is quite low, but you can rise it up to 100, 200 or even 300 with powerful systems.",
        format => '\d+',
    },
    nrcpt => {
        context    => [qw(site)],
        order      => 21.00_34,
        group      => 'outgoing',
        default    => '25',
        gettext_id => 'Maximum number of recipients per call to sendmail',
        gettext_comment =>
            'This grouping factor makes it possible for the sendmail processes to optimize the number of SMTP sessions for message distribution. If needed, you can limit the number of recipients for a particular domain. Check the "nrcpt_by_domain.conf" configuration file.',
        format => '\d+',
    },
    avg => {
        context => [qw(site)],
        order   => 21.00_35,
        group   => 'outgoing',
        default => '10',
        gettext_id =>
            'Maximum number of different mail domains per call to sendmail',
        format => '\d+',
    },

    ### Privileges page ###

    create_list => {
        context    => [qw(domain site)],
        order      => 30.00_01,
        group      => 'command',
        default    => 'public_listmaster',
        sample     => 'intranet',
        gettext_id => 'Who is able to create lists',
        gettext_comment =>
            'Defines who can create lists (or request list creation) by creating new lists or by renaming or copying existing lists.',
        scenario => 'create_list',
    },
    allow_subscribe_if_pending => {
        context    => [qw(domain site)],
        order      => 30.00_02,
        group      => 'command',
        gettext_id => 'Allow adding subscribers to a list not open',
        gettext_comment =>
            'If set to "off", adding subscribers to, or removing subscribers from a list with status other than "open" is forbidden.',
        format  => ['on', 'off'],    #XXX
        default => 'on',
    },
    global_remind => {
        context    => [qw(site)],
        order      => 30.00_03,
        group      => 'command',
        gettext_id => 'Who is able to send remind messages over all lists',
        default    => 'listmaster',
        scenario   => 'global_remind',
    },
    move_user => {
        context    => [qw(domain site)],
        order      => 30.00_04,
        group      => 'command',
        default    => 'auth',
        gettext_id => 'Who is able to change user\'s email',
        scenario   => 'move_user',
    },
    use_blocklist => {
        context    => [qw(domain site)],
        order      => 30.00_05,
        group      => 'command',
        gettext_id => 'Use blocklist',
        default    => 'send,create_list',
        split_char => ',',
        gettext_comment =>
            'List of operations separated by comma for which blocklist filter is applied.  Setting this parameter to "none" will hide the blocklist feature.',
        format => '[-.\w]+',
    },
    use_blacklist => {obsolete => 'use_blocklist'},

    ### Priviledges on the lists

    info => {
        context    => [qw(list domain site)],
        order      => 30.01,
        group      => 'command',
        gettext_id => "Who can view list information",
        scenario   => 'info',
        default    => 'open',
    },

    subscribe => {
        context    => [qw(list domain site)],
        order      => 30.02,
        group      => 'command',
        gettext_id => "Who can subscribe to the list",
        gettext_comment =>
            'The subscribe parameter defines the rules for subscribing to the list.',
        scenario => 'subscribe',
        default  => 'open',
    },
    subscription => {obsolete => 'subscribe'},

    add => {
        context    => [qw(list domain site)],
        order      => 30.03,
        group      => 'command',
        gettext_id => "Who can add subscribers",
        gettext_comment =>
            'Privilege for adding (ADD command) a subscriber to the list',
        scenario => 'add',
        default  => 'owner',
    },

    unsubscribe => {
        context    => [qw(list domain site)],
        order      => 30.04,
        group      => 'command',
        gettext_id => "Who can unsubscribe",
        gettext_comment =>
            'This parameter specifies the unsubscription method for the list. Use open_notify or auth_notify to allow owner notification of each unsubscribe command.',
        scenario => 'unsubscribe',
        default  => 'open',
    },
    unsubscription => {obsolete => 'unsubscribe'},

    del => {
        context    => [qw(list domain site)],
        order      => 30.05,
        group      => 'command',
        gettext_id => "Who can delete subscribers",
        scenario   => 'del',
        default    => 'owner',
    },

    invite => {
        context    => [qw(list domain site)],
        order      => 30.06,
        group      => 'command',
        gettext_id => "Who can invite people",
        scenario   => 'invite',
        default    => 'private',
    },

    remind => {
        context    => [qw(list domain site)],
        order      => 30.07,
        group      => 'command',
        gettext_id => "Who can start a remind process",
        gettext_comment =>
            'This parameter specifies who is authorized to use the remind command.',
        scenario => 'remind',
        default  => 'owner',
    },

    review => {
        context    => [qw(list domain site)],
        order      => 30.08,
        group      => 'command',
        gettext_id => "Who can review subscribers",
        gettext_comment =>
            'This parameter specifies who can access the list of members. Since subscriber addresses can be abused by spammers, it is strongly recommended that you only authorize owners or subscribers to access the subscriber list. ',
        scenario => 'review',
        synonym  => {'open' => 'public',},
        default  => 'owner',
    },

    owner_domain => {
        context    => [qw(list domain site)],
        order      => 30.085,
        group      => 'command',
        gettext_id => "Required domains for list owners",
        #gettext_comment =>
        #    'Restrict list ownership to addresses in the specified domains.',
        gettext_comment =>
            'Restrict list ownership to addresses in the specified domains. This can be used to reserve list ownership to a group of trusted users from a set of domains associated with an organization, while allowing moderators and subscribers from the Internet at large.',
        format_s   => '$host( +$host)*',
        length     => 72,
        occurrence => '0-1',
        split_char => ' ',
    },

    owner_domain_min => {
        context    => [qw(list domain site)],
        order      => 30.086,
        group      => 'command',
        gettext_id => "Minimum owners in required domains",
        #gettext_comment =>
        #    'Require list ownership by a minimum number of addresses in the specified domains.',
        gettext_comment =>
            'Minimum number of owners for each list must satisfy the owner_domain restriction. The default of zero (0) means *all* list owners must match. Setting to 1 requires only one list owner to match owner_domain; all other owners can be from any domain. This setting can be used to ensure that there is always at least one known contact point for any mailing list.',
        format     => '\d+',
        length     => 2,
        occurrence => '0-1',
        default    => '0',
    },

    shared_doc => {
        context    => [qw(list domain site)],
        order      => 30.09,
        group      => 'command',                #FIXME www_other/shared_doc
        gettext_id => "Shared documents",
        gettext_comment =>
            'This paragraph defines read and edit access to the shared document repository.',
        format => {
            d_read => {
                context    => [qw(list domain site)],
                order      => 1,
                gettext_id => "Who can view",
                scenario   => 'd_read',
                default    => 'private',
            },
            d_edit => {
                context    => [qw(list domain site)],
                order      => 2,
                gettext_id => "Who can edit",
                scenario   => 'd_edit',
                default    => 'owner',
            },
            quota => {
                context => [qw(list domain site)],
                order   => 3,
                #FIXME: group www_other/shared_doc
                gettext_id   => "quota",
                gettext_unit => 'Kbytes',
                format       => '\d+',
                length       => 8
            }
        }
    },

    ### Archives page ###

    ignore_x_no_archive_header_feature => {
        context    => [qw(site)],
        order      => 40.00_01,
        group      => 'archives',
        gettext_id => 'Ignore "X-no-archive:" header field',
        gettext_comment =>
            'Sympa\'s default behavior is to skip archiving of incoming messages that have an "X-no-archive:" header field set. This parameter allows one to change this behavior.',
        format  => ['on', 'off'],
        default => 'off',
        sample  => 'on',
    },
    custom_archiver => {
        context    => [qw(site)],
        order      => 40.00_02,
        group      => 'archives',
        gettext_id => 'Custom archiver',
        gettext_comment =>
            "Activates a custom archiver to use instead of MHonArc. The value of this parameter is the absolute path to the executable file.\nSympa invokes this file with these two arguments:\n--list\nThe address of the list including domain part.\n--file\nAbsolute path to the message to be archived.",
        format => '.+',
        file   => 'wwsympa.conf',
    },

    process_archive => {
        context    => [qw(list domain site)],
        order      => 40.01,
        group      => 'archives',
        gettext_id => "Store distributed messages into archive",
        gettext_comment =>
            "If enabled, distributed messages via lists will be archived. Otherwise archiving is disabled.\nNote that even if setting this parameter disabled, past archives will not be removed and will be accessible according to access settings by each list.",
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'off',
    },

    web_archive => {
        context    => [qw(list domain site)],
        obsolete   => '1',                      # Merged into archive.
        group      => 'archives',
        gettext_id => "Web archives",
        format     => {
            access => {
                context    => [qw(list domain site)],
                order      => 1,
                gettext_id => "access right",
                scenario   => 'archive_web_access',
                default    => 'closed',
                obsolete   => 1,                      # Use archive.web_access
            },
            quota => {
                context      => [qw(list site)],
                order        => 2,
                gettext_id   => "quota",
                gettext_unit => 'Kbytes',
                format       => '\d+',
                length       => 8,
                obsolete     => 1,                    # Use archive.quota
            },
            max_month => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "Maximum number of month archived",
                format     => '\d+',
                length     => 3,
                obsolete => 1,                        # Use archive.max_month
            }
        }
    },
    archive => {
        context    => [qw(list domain site)],
        order      => 40.02,
        group      => 'archives',
        gettext_id => "Archives",
        gettext_comment =>
            "Privilege for reading mail archives and frequency of archiving.\nDefines who can access the list's web archive.",
        format => {
            period => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "frequency",
                format     => ['day', 'week', 'month', 'quarter', 'year'],
                synonym    => {'weekly' => 'week'},
                obsolete => 1,    # Not yet implemented.
            },
            access => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "access right",
                format  => ['open', 'private', 'public', 'owner', 'closed'],
                synonym => {'open' => 'public'},
                obsolete => 1,    # Use archive.mail_access
            },
            web_access => {
                context    => [qw(list domain site)],
                order      => 3,
                gettext_id => "access right",
                scenario   => 'archive_web_access',
                default    => 'closed',
            },
            mail_access => {
                context    => [qw(list domain site)],
                order      => 4,
                gettext_id => "access right by mail commands",
                scenario   => 'archive_mail_access',
                synonym    => {
                    'open' => 'public',    # Compat. with <=6.2b.3.
                },
                default => 'closed',
            },
            quota => {
                context      => [qw(list site)],
                order        => 5,
                gettext_id   => "quota",
                gettext_unit => 'Kbytes',
                format       => '\d+',
                length       => 8
            },
            max_month => {
                context      => [qw(list)],
                order        => 6,
                gettext_id   => "Maximum number of month archived",
                gettext_unit => 'months',
                format       => '\d+',
                length       => 3
            }
        }
    },

    archive_crypted_msg => {
        context    => [qw(list)],
        order      => 40.03,
        group      => 'archives',
        gettext_id => "Archive encrypted mails as cleartext",
        format     => ['original', 'decrypted'],
        occurrence => '1',
        default    => 'original'
    },

    web_archive_spam_protection => {
        context => [qw(list domain site)],
        order   => 40.04,
        group   => 'archives',
        #gettext_id => "email address protection method",
        gettext_id => 'Protect web archive against spam harvesters',
        #gettext_comment =>
        #    'Idem spam_protection is provided but it can be used only for web archives. Access requires a cookie, and users must submit a small form in order to receive a cookie before browsing the archives. This blocks all robot, even google and co.',
        gettext_comment =>
            "The same as \"spam_protection\", but restricted to the web archive.\nIn addition to it:\ncookie: users must submit a small form in order to receive a cookie before browsing the web archive.\nconcealed: e-mail addresses will never be displayed.",
        format     => ['cookie', 'javascript', 'at', 'concealed', 'none'],
        synonym    => {'gecos' => 'concealed'},
        occurrence => '1',
        default    => 'cookie',
    },

    ### Bounces page ###

    bounce => {
        context    => [qw(list site)],
        order      => 50.01,
        group      => 'bounces',
        gettext_id => "Bounces management",
        format     => {
            warn_rate => {
                context    => [qw(list site)],
                order      => 1,
                gettext_id => "warn rate",
                gettext_comment =>
                    'The list owner receives a warning whenever a message is distributed and the number (percentage) of bounces exceeds this value.',
                gettext_unit => '%',
                format       => '\d+',
                length       => 3,
                default      => '30',
            },
            halt_rate => {
                context    => [qw(list site)],
                order      => 2,
                gettext_id => "halt rate",
                gettext_comment =>
                    'NOT USED YET. If bounce rate reaches the halt_rate, messages for the list will be halted, i.e. they are retained for subsequent moderation.',
                gettext_unit => '%',
                format       => '\d+',
                length       => 3,
                default      => '50',
                obsolete     => 1,       # Not yet implemented.
            }
        }
    },

    bouncers_level1 => {
        context         => [qw(list domain site)],
        order           => 50.02,
        group           => 'bounces',
        gettext_id      => "Management of bouncers, 1st level",
        gettext_comment => 'Level 1 is the lower level of bouncing users',
        format          => {
            rate => {
                context    => [qw(list domain site)],
                order      => 1,
                gettext_id => "threshold",
                gettext_comment =>
                    "Each bouncing user have a score (from 0 to 100).\nThis parameter defines a lower limit for each category of bouncing users.For example, level 1 begins from 45 to level_2_treshold.",
                gettext_unit => 'points',
                format       => '\d+',
                length       => 2,
                default      => '45',
            },
            action => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "action for this population",
                gettext_comment =>
                    'This parameter defines which task is automatically applied on level 1 bouncers.',
                format     => ['remove_bouncers', 'notify_bouncers', 'none'],
                occurrence => '1',
                default    => 'notify_bouncers'
            },
            notification => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "notification",
                gettext_comment =>
                    'When automatic task is executed on level 1 bouncers, a notification email can be send to listowner or listmaster.',
                format     => ['none', 'owner', 'listmaster'],
                occurrence => '1',
                default    => 'owner'
            }
        }
    },

    bouncers_level2 => {
        context         => [qw(list domain site)],
        order           => 50.03,
        group           => 'bounces',
        gettext_id      => "Management of bouncers, 2nd level",
        gettext_comment => 'Level 2 is the highest level of bouncing users',
        format          => {
            rate => {
                context    => [qw(list domain site)],
                order      => 1,
                gettext_id => "threshold",
                gettext_comment =>
                    "Each bouncing user have a score (from 0 to 100).\nThis parameter defines the score range defining each category of bouncing users.For example, level 2 is for users with a score between 80 and 100.",
                gettext_unit => 'points',
                format       => '\d+',
                length       => 2,
                default      => '75',
            },
            action => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "action for this population",
                gettext_comment =>
                    'This parameter defines which task is automatically applied on level 2 bouncers.',
                format     => ['remove_bouncers', 'notify_bouncers', 'none'],
                occurrence => '1',
                default    => 'remove_bouncers'
            },
            notification => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "notification",
                gettext_comment =>
                    'When automatic task is executed on level 2 bouncers, a notification email can be send to listowner or listmaster.',
                format     => ['none', 'owner', 'listmaster'],
                occurrence => '1',
                default    => 'owner'
            }
        }
    },

    verp_rate => {
        context    => [qw(list domain site)],
        order      => 50.04,
        group      => 'bounces',
        gettext_id => "percentage of list members in VERP mode",
        gettext_comment =>
            "Uses variable envelope return path (VERP) to detect bouncing subscriber addresses.\n0%: VERP is never used.\n100%: VERP is always in use.\nVERP requires address with extension to be supported by MTA. If tracking is enabled for a list or a message, VERP is applied for 100% of subscribers.",
        format =>
            ['100%', '50%', '33%', '25%', '20%', '10%', '5%', '2%', '0%'],
        occurrence => '1',
        default    => '0%',
    },

    tracking => {
        context    => [qw(list site)],
        order      => 50.05,
        group      => 'bounces',
        gettext_id => "Message tracking feature",
        format     => {
            delivery_status_notification => {
                context => [qw(list site)],
                order   => 1,
                gettext_id =>
                    "tracking message by delivery status notification",
                #gettext_id =>
                #    'Tracking message by delivery status notification (DSN)',
                format     => ['on', 'off'],
                occurrence => '1',
                default    => 'off',
            },
            message_disposition_notification => {
                context => [qw(list site)],
                order   => 2,
                gettext_id =>
                    "tracking message by message disposition notification",
                #gettext_id =>
                #    'Tracking message by message disposition notification (MDN)',
                format     => ['on', 'on_demand', 'off'],
                occurrence => '1',
                default    => 'off',
            },
            tracking => {
                context    => [qw(list site)],
                order      => 3,
                gettext_id => "who can view message tracking",
                scenario   => 'tracking',
                default    => 'owner',
            },
            retention_period => {
                context => [qw(list site)],
                order   => 4,
                gettext_id =>
                    "Tracking datas are removed after this number of days",
                #gettext_id => 'Max age of tracking information',
                #gettext_comment =>
                #    'Tracking information is removed after this number of days',
                gettext_unit => 'days',
                format       => '\d+',
                default      => '90',
                length       => 5
            }
        }
    },

    welcome_return_path => {
        context    => [qw(list site)],
        order      => 50.06,
        group      => 'bounces',
        gettext_id => "Welcome return-path",
        #gettext_id => 'Remove bouncing new subscribers',
        gettext_comment =>
            'If set to unique, the welcome message is sent using a unique return path in order to remove the subscriber immediately in the case of a bounce.',
        format  => ['unique', 'owner'],
        default => 'owner',
    },

    remind_return_path => {
        context    => [qw(list site)],
        order      => 50.07,
        group      => 'bounces',
        gettext_id => "Return-path of the REMIND command",
        #gettext_id => 'Remove subscribers bouncing remind message',
        gettext_comment =>
            'Same as welcome_return_path, but applied to remind messages.',
        format  => ['unique', 'owner'],
        default => 'owner',
    },

    expire_bounce_task => {
        context    => [qw(site)],
        order      => 50.10_01,
        group      => 'bounces',
        default    => 'daily',
        gettext_id => 'Task for expiration of old bounces',
        gettext_comment =>
            'This task resets bouncing information for addresses not bouncing in the last 10 days after the latest message distribution.',
        task => 'expire_bounce',
    },
    purge_orphan_bounces_task => {
        context    => [qw(site)],
        order      => 50.10_02,
        group      => 'bounces',
        gettext_id => 'Task for cleaning invalidated bounces',
        gettext_comment =>
            'This task deletes bounce information for unsubscribed users.',
        default => 'monthly',
        task    => 'purge_orphan_bounces',
    },
    eval_bouncers_task => {
        context    => [qw(site)],
        order      => 50.10_03,
        group      => 'bounces',
        gettext_id => 'Task for updating bounce scores',
        gettext_comment =>
            'This task scans all bouncing users for all lists, and updates "bounce_score_subscriber" field in "subscriber_table" table. The scores may be used for management of bouncers.',
        default => 'daily',
        task    => 'eval_bouncers',
    },
    process_bouncers_task => {
        context    => [qw(site)],
        order      => 50.10_04,
        group      => 'bounces',
        gettext_id => 'Task for management of bouncers',
        gettext_comment =>
            'This task executes actions on bouncing users configured by each list, according to their scores.',
        default => 'weekly',
        task    => 'process_bouncers',
    },
    purge_tables_task => {
        context    => [qw(site)],
        order      => 50.10_05,
        group      => 'bounces',
        gettext_id => 'Task for cleaning tables',
        gettext_comment =>
            'This task cleans old tracking information from "notification_table" table.',
        default => 'daily',
        task    => 'purge_tables',
    },
    minimum_bouncing_count => {
        context    => [qw(site)],
        order      => 50.10_06,
        group      => 'bounces',
        gettext_id => 'Minimum number of bounces',
        gettext_comment =>
            'The minimum number of bounces received to update bounce score of a user.',
        format  => '\d+',
        default => '10',
    },
    minimum_bouncing_period => {
        context    => [qw(site)],
        order      => 50.10_07,
        group      => 'bounces',
        gettext_id => 'Minimum bouncing period',
        gettext_comment =>
            'The minimum period for which bouncing lasted to update bounce score of a user.',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '10',
    },
    bounce_delay => {
        context    => [qw(site)],
        order      => 50.10_08,
        group      => 'bounces',
        gettext_id => 'Delay of bounces',
        gettext_comment =>
            'Average time for a bounce sent back to mailing list server after a post was sent to a list. Usually bounces are sent back on the same day as the original message.',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '0',
    },
    bounce_email_prefix => {
        context    => [qw(site)],
        order      => 50.10_09,
        group      => 'bounces',
        gettext_id => 'Prefix of VERP return address',
        gettext_comment =>
            "The prefix to consist the return-path of probe messages used for bounce management, when variable envelope return path (VERP) is enabled. VERP requires address with extension to be supported by MTA.\nIf you change the default value, you must modify the mail aliases too.",
        format  => '\S+',
        default => 'bounce',
    },
    return_path_suffix => {
        context    => [qw(site)],
        order      => 50.10_10,
        group      => 'bounces',
        gettext_id => 'Suffix of list return address',
        gettext_comment =>
            'The suffix appended to the list name to form the return-path of messages distributed through the list. This address will receive all non-delivery reports (also called bounces).',
        format  => '\S+',
        default => '-owner',
    },

    ### Loop prevention

    loop_command_max => {
        context    => [qw(site)],
        order      => 51.00_01,
        group      => 'loop_prevention',
        gettext_id => 'Maximum number of responses to command message',
        gettext_comment =>
            'The maximum number of command reports sent to an email address. Messages are stored in "bad" subdirectory of incoming message spool, and reports are not longer sent.',
        format  => '\d+',
        default => '200',
    },
    loop_command_sampling_delay => {
        context    => [qw(site)],
        order      => 51.00_02,
        group      => 'loop_prevention',
        gettext_id => 'Delay before counting responses to command message',
        gettext_comment =>
            'This parameter defines the delay in seconds before decrementing the counter of reports sent to an email address.',
        format       => '\d+',
        gettext_unit => 'seconds',
        default      => '3600',
    },
    loop_command_decrease_factor => {
        context    => [qw(site)],
        order      => 51.00_03,
        group      => 'loop_prevention',
        gettext_id => 'Decrementing factor of responses to command message',
        gettext_comment =>
            'The decrementation factor (from 0 to 1), used to determine the new report counter after expiration of the delay.',
        format  => '[.\d]+',
        default => '0.5',
    },

    msgid_table_cleanup_ttl => {
        context    => [qw(site)],
        order      => 51.00_04,
        group      => 'loop_prevention',
        gettext_id => 'Expiration period of message ID table',
        gettext_comment =>
            'Expiration period of entries in the table maintained by sympa_msg.pl daemon to prevent delivery of duplicate messages caused by loop.',
        format       => '\d+',
        gettext_unit => 'seconds',
        default      => '86400',
    },
    msgid_table_cleanup_frequency => {
        context    => [qw(site)],
        order      => 51.00_05,
        group      => 'loop_prevention',
        gettext_id => 'Cleanup interval of message ID table',
        gettext_comment =>
            'Interval between cleanups of the table maintained by sympa_msg.pl daemon to prevent delivery of duplicate messages caused by loop.',
        format       => '\d+',
        gettext_unit => 'seconds',
        default      => '3600',
    },

    ### Automatic list creation

    automatic_list_feature => {
        context    => [qw(domain site)],
        order      => 52.00_01,
        group      => 'automatic_lists',
        gettext_id => 'Automatic list',
        format     => ['on', 'off'],       #XXX
        default    => 'off',
    },
    automatic_list_removal => {
        context    => [qw(domain site)],
        order      => 52.00_02,
        group      => 'automatic_lists',
        gettext_id => 'Remove empty automatic list',
        gettext_comment =>
            'If set to "if_empty", then Sympa will remove automatically created mailing lists just after their creation, if they contain no list member.',
        format  => ['none', 'if_empty'],
        default => 'none',
        sample  => 'if_empty',
    },
    automatic_list_creation => {
        context    => [qw(domain site)],
        order      => 52.00_03,
        group      => 'automatic_lists',
        gettext_id => 'Who is able to create automatic list',
        default    => 'public',
        scenario   => 'automatic_list_creation',
    },
    automatic_list_families => {
        context => [qw(domain site)],
        order   => 52.00_04,
        group   => 'automatic_lists',
        sample =>
            'name=family_one:prefix=f1:display=My automatic lists:prefix_separator=+:classes separator=-:family_owners_list=alist@domain.tld;name=family_two:prefix=f2:display=My other automatic lists:prefix_separator=+:classes separator=-:family_owners_list=anotherlist@domain.tld;',
        gettext_id => 'Definition of automatic list families',
        gettext_comment =>
            "Defines the families the automatic lists are based on. It is a character string structured as follows:\n* each family is separated from the other by a semicolon (;)\n* inside a family definition, each field is separated from the other by a colon (:)\n* each field has the structure: \"<field name>=<field value>\"\nBasically, each time Sympa uses the automatic lists families, the values defined in this parameter will be available in the family object.\n* for scenarios: [family->name]\n* for templates: [% family.name %]",
        format => '.+',    #FIXME: use paragraph
    },
    parsed_family_files => {
        context    => [qw(domain site)],
        order      => 52.00_05,
        group      => 'automatic_lists',
        gettext_id => 'Parsed files for families',
        gettext_comment =>
            'comma-separated list of files that will be parsed by Sympa when instantiating a family (no space allowed in file names)',
        format     => '[-.\w]+',
        split_char => ',',
        default =>
            'message_header,message_header.mime,message_footer,message_footer.mime,info',
    },
    family_signoff => {
        context    => [qw(domain site)],
        order      => 52.00_06,
        group      => 'automatic_lists',
        gettext_id => 'Global unsubscription',
        default    => 'auth',                    # Compat. to <=6.2.52
        scenario   => 'family_signoff',
    },

    ### Tag-based spam filtering

    antispam_feature => {
        context    => [qw(domain site)],
        order      => 53.00_01,
        group      => 'antispam',
        gettext_id => 'Tag based spam filtering',
        format     => ['on', 'off'],
        default    => 'off',
    },
    antispam_tag_header_name => {
        context    => [qw(domain site)],
        order      => 53.00_02,
        group      => 'antispam',
        default    => 'X-Spam-Status',
        gettext_id => 'Header field to tag spams',
        gettext_comment =>
            'If a spam filter (like spamassassin or j-chkmail) add a header field to tag spams, name of this header field (example X-Spam-Status)',
        format => '\S+',
    },
    antispam_tag_header_spam_regexp => {
        context    => [qw(domain site)],
        order      => 53.00_03,
        group      => 'antispam',
        default    => '^\s*Yes',
        gettext_id => 'Regular expression to check header field to tag spams',
        gettext_comment =>
            'Regular expression applied on this header to verify message is a spam (example Yes)',
        format => '.+',    #FIXME: Check regexp
    },
    antispam_tag_header_ham_regexp => {
        context    => [qw(domain site)],
        order      => 53.00_04,
        group      => 'antispam',
        default    => '^\s*No',
        gettext_id => 'Regular expression to determine spam or ham.',
        gettext_comment =>
            'Regular expression applied on this header field to verify message is NOT a spam (example No)',
        format => '.+',    #FIXME: Check regexp
    },
    spam_status => {
        context    => [qw(domain site)],
        order      => 53.00_05,
        group      => 'antispam',
        default    => 'x-spam-status',
        gettext_id => 'Name of header field to inform',
        gettext_comment =>
            'Messages are supposed to be filtered by an spam filter that adds them one or more headers. This parameter is used to select a special scenario in order to decide the message\'s spam status: ham, spam or unsure. This parameter replaces antispam_tag_header_name, antispam_tag_header_spam_regexp and antispam_tag_header_ham_regexp.',
        scenario => 'spam_status',
    },

    ### Directories

    home => {
        context         => [qw(site)],
        order           => 54.00_01,
        group           => 'directories',
        default_s       => '$EXPLDIR',
        gettext_id      => 'List home',
        gettext_comment => 'Base directory of list configurations.',
        format          => '.+',
    },
    etc => {
        context    => [qw(site)],
        order      => 54.00_02,
        group      => 'directories',
        default_s  => '$SYSCONFDIR',
        gettext_id => 'Directory for configuration files',
        gettext_comment =>
            'Base directory of global configuration (except "sympa.conf").',
        format => '.+',
    },

    spool => {
        context    => [qw(site)],
        order      => 54.00_03,
        group      => 'directories',
        default_s  => '$SPOOLDIR',
        gettext_id => 'Base directory of spools',
        gettext_comment =>
            'Base directory of all spools which are created at runtime. This directory must be writable by Sympa user.',
        format => '.+',
    },
    queue => {
        context    => [qw(site)],
        order      => 54.00_04,
        group      => 'directories',
        default_s  => '$SPOOLDIR/msg',
        gettext_id => 'Directory for message incoming spool',
        gettext_comment =>
            'This spool is used both by "queue" program and "sympa_msg.pl" daemon.',
        format => '.+',
    },
    queuemod => {
        context    => [qw(site)],
        order      => 54.00_05,
        group      => 'directories',
        default_s  => '$SPOOLDIR/moderation',
        gettext_id => 'Directory for moderation spool',
        format     => '.+',
    },
    queuedigest => {
        context    => [qw(site)],
        order      => 54.00_06,
        group      => 'directories',
        default_s  => '$SPOOLDIR/digest',
        gettext_id => 'Directory for digest spool',
        format     => '.+',
    },
    queueauth => {
        context    => [qw(site)],
        order      => 54.00_07,
        group      => 'directories',
        default_s  => '$SPOOLDIR/auth',
        gettext_id => 'Directory for held message spool',
        gettext_comment =>
            'This parameter is named such by historical reason.',
        format => '.+',
    },
    queueoutgoing => {
        context    => [qw(site)],
        order      => 54.00_08,
        group      => 'directories',
        default_s  => '$SPOOLDIR/outgoing',
        gettext_id => 'Directory for archive spool',
        gettext_comment =>
            'This parameter is named such by historical reason.',
        format => '.+',
    },
    queuesubscribe => {
        context    => [qw(site)],
        order      => 54.00_09,
        group      => 'directories',
        default_s  => '$SPOOLDIR/subscribe',
        gettext_id => 'Directory for held request spool',
        gettext_comment =>
            'This parameter is named such by historical reason.',
        format => '.+',
    },
    queuetopic => {
        context    => [qw(site)],
        order      => 54.00_10,
        group      => 'directories',
        default_s  => '$SPOOLDIR/topic',
        gettext_id => 'Directory for topic spool',
        format     => '.+',
    },
    queuebounce => {
        context    => [qw(site)],
        order      => 54.00_11,
        group      => 'directories',
        default_s  => '$SPOOLDIR/bounce',
        gettext_id => 'Directory for bounce incoming spool',
        gettext_comment =>
            'This spool is used both by "bouncequeue" program and "bounced.pl" daemon.',
        format => '.+',
    },
    queuetask => {
        context    => [qw(site)],
        order      => 54.00_12,
        group      => 'directories',
        default_s  => '$SPOOLDIR/task',
        gettext_id => 'Directory for task spool',
        format     => '.+',
    },
    queueautomatic => {
        context    => [qw(site)],
        order      => 54.00_13,
        group      => 'directories',
        default_s  => '$SPOOLDIR/automatic',
        gettext_id => 'Directory for automatic list creation spool',
        gettext_comment =>
            'This spool is used both by "familyqueue" program and "sympa_automatic.pl" daemon.',
        format => '.+',
    },
    queuebulk => {
        context    => [qw(site)],
        order      => 54.00_14,
        group      => 'directories',
        default_s  => '$SPOOLDIR/bulk',
        gettext_id => 'Directory for message outgoing spool',
        gettext_comment =>
            'This parameter is named such by historical reason.',
        format => '.+',
    },
    tmpdir => {
        context   => [qw(site)],
        order     => 54.00_15,
        group     => 'directories',
        default_s => '$SPOOLDIR/tmp',
        gettext_id =>
            'Temporary directory used by external programs such as virus scanner. Also, outputs to daemons\' standard error are redirected to the files under this directory.',
        format => '.+',
    },
    viewmail_dir => {
        context    => [qw(site)],
        order      => 54.00_16,
        group      => 'directories',
        default_s  => '$SPOOLDIR/viewmail',
        gettext_id => 'Directory to cache formatted messages',
        gettext_comment =>
            'Base directory path of directories where HTML view of messages are cached.',
        format => '.+',
    },
    bounce_path => {
        context    => [qw(site)],
        order      => 54.00_17,
        group      => 'directories',
        default_s  => '$BOUNCEDIR',
        gettext_id => 'Directory for storing bounces',
        file       => 'wwsympa.conf',
        gettext_comment =>
            "The directory where bounced.pl daemon will store the last bouncing message for each user. A message is stored in the file: <bounce_path>/<list name>\@<mail domain name>/<email address>, or, if tracking is enabled: <bounce_path>/<list name>\@<mail domain name>/<email address>_<envelope ID>.\nUsers can access to these messages using web interface in the bounce management page.\nDon't confuse with \"queuebounce\" parameter which defines the spool where incoming error reports are stored and picked by bounced.pl daemon.",
        format => '.+',
    },

    arc_path => {
        context    => [qw(domain site)],
        order      => 54.00_18,
        group      => 'directories',
        default_s  => '$ARCDIR',
        gettext_id => 'Directory for storing archives',
        file       => 'wwsympa.conf',
        gettext_comment =>
            'Where to store HTML archives. This parameter is used by the "archived.pl" daemon. It is a good idea to install the archive outside the web document hierarchy to prevent overcoming of WWSympa\'s access control.',
        format => '.+',
    },

    purge_spools_task => {
        context         => [qw(site)],
        order           => 54.00_20,
        group           => 'directories',
        gettext_id      => 'Task for cleaning spools',
        gettext_comment => 'This task cleans old content in spools.',
        default         => 'daily',
        task            => 'purge_spools',
    },
    clean_delay_queue => {
        context    => [qw(site)],
        order      => 54.00_21,
        group      => 'directories',
        gettext_id => 'Max age of incoming bad messages',
        gettext_comment =>
            'Number of days "bad" messages are kept in message incoming spool (as specified by "queue" parameter). Sympa keeps messages rejected for various reasons (badly formatted, looping etc.).',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '7',
    },
    clean_delay_queueoutgoing => {
        context    => [qw(site)],
        order      => 54.00_22,
        group      => 'directories',
        gettext_id => 'Max age of bad messages for archives',
        gettext_comment =>
            'Number of days "bad" messages are kept in message archive spool (as specified by "queueoutgoing" parameter). Sympa keeps messages rejected for various reasons (unable to create archive directory, to copy file etc.).',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '7',
    },
    clean_delay_queuebounce => {
        context    => [qw(site)],
        order      => 54.00_23,
        group      => 'directories',
        gettext_id => 'Max age of bad bounce messages',
        gettext_comment =>
            'Number of days "bad" messages are kept in bounce spool (as specified by "queuebounce" parameter). Sympa keeps messages rejected for various reasons (unknown original sender, unknown report type).',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '7',
    },
    #clean_delay_queuemod
    clean_delay_queueauth => {
        context    => [qw(site)],
        order      => 54.00_25,
        group      => 'directories',
        gettext_id => 'Max age of held messages',
        gettext_comment =>
            'Number of days messages are kept in held message spool (as specified by "queueauth" parameter). Beyond this deadline, messages that have not been confirmed are deleted.',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '30',
    },
    clean_delay_queuesubscribe => {
        context    => [qw(site)],
        order      => 54.00_26,
        group      => 'directories',
        gettext_id => 'Max age of held requests',
        gettext_comment =>
            'Number of days requests are kept in held request spool (as specified by "queuesubscribe" parameter). Beyond this deadline, requests that have not been validated nor declined are deleted.',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '30',
    },
    clean_delay_queuetopic => {
        context    => [qw(site)],
        order      => 54.00_27,
        group      => 'directories',
        gettext_id => 'Max age of tagged topics',
        gettext_comment =>
            'Number of days (automatically or manually) tagged topics are kept in topic spool (as specified by "queuetopic" parameter). Beyond this deadline, tagging is forgotten.',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '30',
    },
    clean_delay_queueautomatic => {
        context => [qw(site)],
        order   => 54.00_28,
        group   => 'directories',
        gettext_id =>
            'Max age of incoming bad messages in automatic list creation spool',
        gettext_comment =>
            'Number of days "bad" messages are kept in automatic list creation spool (as specified by "queueautomatic" parameter). Sympa keeps messages rejected for various reasons (badly formatted, looping etc.).',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '10',
    },
    clean_delay_queuebulk => {
        context    => [qw(site)],
        order      => 54.00_29,
        group      => 'directories',
        gettext_id => 'Max age of outgoing bad messages',
        gettext_comment =>
            'Number of days "bad" messages are kept in message outgoing spool (as specified by "queuebulk" parameter). Sympa keeps messages rejected for various reasons (failed personalization, bad configuration on MTA etc.).',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '7',
    },
    clean_delay_queuedigest => {
        context    => [qw(site)],
        order      => 54.00_30,
        group      => 'directories',
        gettext_id => 'Max age of bad messages in digest spool',
        gettext_comment =>
            'Number of days "bad" messages are kept in digest spool (as specified by "queuedigest" parameter). Sympa keeps messages rejected for various reasons (syntax errors in "digest.tt2" template etc.).',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '14',
    },
    clean_delay_tmpdir => {
        context    => [qw(site)],
        order      => 54.00_31,
        group      => 'directories',
        gettext_id => 'Max age of temporary files',
        gettext_comment =>
            'Number of days files in temporary directory (as specified by "tmpdir" parameter), including standard error logs, are kept.',
        format       => '\d+',
        gettext_unit => 'days',
        default      => '7',
    },

    ####### Sympa services: Optional features

    ### S/MIME and TLS

    cafile => {
        context    => [qw(site)],
        order      => 59.00_01,
        group      => 'crypto',
        gettext_id => 'File containing trusted CA certificates',
        gettext_comment =>
            'This can be used alternatively and/or additionally to "capath".',
        format => '.+',
    },
    capath => {
        context    => [qw(site)],
        order      => 59.00_02,
        group      => 'crypto',
        gettext_id => 'Directory containing trusted CA certificates',
        gettext_comment =>
            "CA certificates in this directory are used for client authentication.\nThe certificates need to have names including hash of subject, or symbolic links to them with such names. The links may be created by using \"c_rehash\" script bundled in OpenSSL.",
        format => '.+',
    },
    key_passwd => {
        context    => [qw(site)],
        order      => 59.00_03,
        group      => 'crypto',
        sample     => 'your_password',
        gettext_id => 'Password used to crypt lists private keys',
        gettext_comment =>
            'If not defined, Sympa assumes that list private keys are not encrypted.',
        format     => '.+',
        field_type => 'password',
    },
    key_password => {
        context  => [qw(site)],
        obsolete => 'key_passwd',
    },
    ssl_cert_dir => {
        context    => [qw(site)],
        order      => 59.00_04,
        group      => 'crypto',
        default_s  => '$EXPLDIR/X509-user-certs',
        gettext_id => 'Directory containing user certificates',
        format     => '.+',
    },
    # Not yet implemented
    #crl_dir => {
    #    context   => [qw(site)],
    #    order     => 59.00_05,
    #    group => 'crypto',
    #    default => Sympa::Constants::EXPLDIR . '/crl',
    #},
    #chk_cert_expiration_task => {
    #    context   => [qw(site)],
    #    order     => 59.00_06,
    #    group => 'crypto',
    #},
    #crl_update_task => {
    #    context   => [qw(site)],
    #    order     => 59.00_07,
    #    group => 'crypto',
    #},

    ### Data sources page ###

    inclusion_notification_feature => {
        context => [qw(list site)],
        order   => 60.01,
        group   => 'data_source',
        gettext_id =>
            "Notify subscribers when they are included from a data source?",
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'off',
    },

    member_include => {
        context    => [qw(list)],
        order      => 60.02,
        group      => 'data_source',
        gettext_id => 'Subscribers defined in an external data source',
        format     => {
            source => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'the data source',
                datasource => 1,
                occurrence => '1'
            },
            source_parameters => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => 'data source parameters',
                format     => '.*',
                occurrence => '0-1'
            },
        },
        occurrence => '0-n'
    },

    owner_include => {
        context    => [qw(list)],
        order      => 60.02_1,
        group      => 'data_source',
        gettext_id => 'Owners defined in an external data source',
        format     => {
            source => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'the data source',
                datasource => 1,
                occurrence => '1'
            },
            source_parameters => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => 'data source parameters',
                format     => '.*',
                occurrence => '0-1'
            },
            profile => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => 'profile',
                format     => ['privileged', 'normal'],
                occurrence => '1',
                default    => 'normal'
            },
            reception => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => 'reception mode',
                format     => ['mail', 'nomail'],
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "visibility",
                format     => ['conceal', 'noconceal'],
                occurrence => '1',
                default    => 'noconceal'
            },
        },
        occurrence => '0-n'
    },

    editor_include => {
        context    => [qw(list)],
        order      => 60.02_2,
        group      => 'data_source',
        gettext_id => 'Moderators defined in an external data source',
        format     => {
            source => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'the data source',
                datasource => 1,
                occurrence => '1'
            },
            source_parameters => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => 'data source parameters',
                format     => '.*',
                occurrence => '0-1'
            },
            reception => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => 'reception mode',
                format     => ['mail', 'nomail'],
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "visibility",
                format     => ['conceal', 'noconceal'],
                occurrence => '1',
                default    => 'noconceal'
            }
        },
        occurrence => '0-n'
    },

    sql_fetch_timeout => {
        context      => [qw(list site)],
        order        => 60.03,
        group        => 'data_source',
        gettext_id   => "Timeout for fetch of include_sql_query",
        gettext_unit => 'seconds',
        #gettext_id => 'Default of SQL fetch timeout',
        #gettext_comment =>
        #    'Default timeout while performing a fetch with include_sql_query.',
        format  => '\d+',
        length  => 6,
        default => '300',
    },

    user_data_source => {
        context    => [qw(list)],
        group      => 'data_source',
        gettext_id => "User data source",
        format     => '\S+',
        default    => 'include2',
        obsolete   => 1,
    },

    include_file => {
        context    => [qw(list)],
        order      => 60.04,
        group      => 'data_source',
        gettext_id => "File inclusion",
        gettext_comment =>
            'Include subscribers from this file.  The file should contain one e-mail address per line (lines beginning with a "#" are ignored).',
        format     => '\S+',
        occurrence => '0-n',
        length     => 20,
    },

    include_remote_file => {
        context    => [qw(list)],
        order      => 60.05,
        group      => 'data_source',
        gettext_id => "Remote file inclusion",
        format     => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            url => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "data location URL",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            user => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "remote user",
                format     => '.+',
                occurrence => '0-1'
            },
            passwd => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password',
                occurrence => '0-1',
                length     => 10
            },
            timeout => {
                context      => [qw(list)],
                order        => 5,
                gettext_id   => "idle timeout",
                gettext_unit => 'seconds',
                format       => '\d+',
                length       => 6,
                default      => 180,
            },
            ssl_version => {
                context    => [qw(list)],
                order      => 6,
                gettext_id => 'SSL version',
                format     => [
                    'ssl_any', 'sslv2',   'sslv3', 'tlsv1',
                    'tlsv1_1', 'tlsv1_2', 'tlsv1_3'
                ],
                synonym    => {'tls' => 'tlsv1'},
                occurrence => '0-1',
                default    => 'ssl_any',
            },
            ssl_ciphers => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => 'SSL ciphers used',
                format     => '.+',
                default    => 'ALL'
            },
            # ssl_cert # Use cert.pem in list directory
            # ssl_key  # Use private_key in list directory

            # NOTE: The default of ca_verify is "none" that is different from
            #   include_ldap_query (required) or include_remote_sympa_list
            #   (optional).
            ca_verify => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => 'Certificate verification',
                format     => ['none', 'optional', 'required'],
                synonym    => {'require' => 'required'},
                occurrence => '0-1',
                default    => 'none',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented

            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            },
        },
        occurrence => '0-n'
    },

    include_list => {
        context    => [qw(list)],
        group      => 'data_source',
        gettext_id => "List inclusion",
        format_s   => '$listname(\@$host)?(\s+filter\s+.+)?',
        occurrence => '0-n',
        obsolete   => 1,                                     # 2.2.6 - 6.2.15.
    },

    include_sympa_list => {
        context    => [qw(list)],
        order      => 60.06,
        group      => 'data_source',
        gettext_id => "List inclusion",
        gettext_comment =>
            'Include subscribers from other list. All subscribers of list listname become subscribers of the current list. You may include as many lists as required, using one include_sympa_list paragraph for each included list. Any list at all may be included; you may therefore include lists which are also defined by the inclusion of other lists. Be careful, however, not to include list A in list B and then list B in list A, since this will give rise to an infinite loop.',
        format => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            listname => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "list name to include",
                format_s   => '$listname(\@$host)?',
                occurrence => '1'
            },
            filter => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "filter definition",
                format     => '.*'
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            },
        },
        occurrence => '0-n'
    },

    include_remote_sympa_list => {
        context    => [qw(list)],
        order      => 60.07,
        group      => 'data_source',
        gettext_id => "remote list inclusion",
        gettext_comment =>
            "Sympa can contact another Sympa service using HTTPS to fetch a remote list in order to include each member of a remote list as subscriber. You may include as many lists as required, using one include_remote_sympa_list paragraph for each included list. Be careful, however, not to give rise to an infinite loop resulting from cross includes.\nFor this operation, one Sympa site acts as a server while the other one acs as client. On the server side, the only setting needed is to give permission to the remote Sympa to review the list. This is controlled by the review scenario.",
        format => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            url => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "data location URL",
                format     => '.+',
                occurrence => '0-1',              # Backward compat. <= 6.2.44
                length     => 50
            },
            user => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "remote user",
                format     => '.+',
                occurrence => '0-1'
            },
            passwd => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password',
                occurrence => '0-1',
                length     => 10,
            },
            host => {
                context         => [qw(list)],
                order           => 4.5,
                gettext_id      => "remote host",
                gettext_comment => 'obsoleted.  Use "data location URL".',
                format_s        => '$host',
                occurrence      => '1'
            },
            port => {
                context         => [qw(list)],
                order           => 4.6,
                gettext_id      => "remote port",
                gettext_comment => 'obsoleted.  Use "data location URL".',
                format          => '\d+',
                default         => 443,
                length          => 4
            },
            path => {
                context         => [qw(list)],
                order           => 4.7,
                gettext_id      => "remote path of sympa list dump",
                gettext_comment => 'obsoleted.  Use "data location URL".',
                format          => '\S+',
                occurrence      => '1',
                length          => 20
            },
            cert => {
                context => [qw(list)],
                order   => 4.8,
                gettext_id =>
                    "certificate for authentication by remote Sympa",
                format   => ['robot', 'list'],
                default  => 'list',
                obsolete => 1,
            },
            timeout => {
                context      => [qw(list)],
                order        => 5,
                gettext_id   => "idle timeout",
                gettext_unit => 'seconds',
                format       => '\d+',
                length       => 6,
                default      => 180,
            },
            ssl_version => {
                context    => [qw(list)],
                order      => 6,
                gettext_id => 'SSL version',
                format     => [
                    'ssl_any', 'sslv2',   'sslv3', 'tlsv1',
                    'tlsv1_1', 'tlsv1_2', 'tlsv1_3'
                ],
                synonym    => {'tls' => 'tlsv1'},
                occurrence => '0-1',
                default    => 'ssl_any',
            },
            ssl_ciphers => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => 'SSL ciphers used',
                format     => '.+',
                default    => 'ALL'
            },
            # ssl_cert # Use cert.pem in list directory
            # ssl_key  # Use private_key in list directory

            # NOTE: The default of ca_verify is "none" that is different from
            #   include_ldap_query (required) or include_remote_file (none).
            ca_verify => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => 'Certificate verification',
                format     => ['none', 'optional', 'required'],
                synonym    => {'require' => 'required'},
                occurrence => '0-1',
                default    => 'optional',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented

            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            },
        },
        occurrence => '0-n'
    },

    include_ldap_query => {
        context    => [qw(list)],
        order      => 60.08,
        group      => 'data_source',
        gettext_id => "LDAP query inclusion",
        gettext_comment =>
            'This paragraph defines parameters for a query returning a list of subscribers. This feature requires the Net::LDAP (perlldap) PERL module.',
        format => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            host => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "remote host",
                format_s   => '$multiple_host_or_url',
                occurrence => '1'
            },
            port => {
                context    => [qw(list)],
                order      => 2.1,
                gettext_id => "remote port",
                format     => '\d+',
                obsolete   => 1,
                length     => 4
            },
            use_tls => {
                context    => [qw(list)],
                order      => 2.4,
                gettext_id => 'use TLS (formerly SSL)',
                format     => ['starttls', 'ldaps', 'none'],
                synonym    => {'yes' => 'ldaps', 'no' => 'none'},
                occurrence => '1',
                default    => 'none',
            },
            use_ssl => {
                context => [qw(list)],
                #order => 2.5,
                #gettext_id => 'use SSL (LDAPS)',
                #format => ['yes', 'no'],
                #default => 'no'
                obsolete => 'use_tls',    # 5.3a.2 - 6.2.14
            },
            ssl_version => {
                context    => [qw(list)],
                order      => 2.6,
                gettext_id => 'SSL version',
                format     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                synonym    => {'tls' => 'tlsv1'},
                occurrence => '1',
                default    => 'tlsv1'
            },
            ssl_ciphers => {
                context    => [qw(list)],
                order      => 2.7,
                gettext_id => 'SSL ciphers used',
                format     => '.+',
                default    => 'ALL',
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            ca_verify => {
                context    => [qw(list)],
                order      => 2.8,
                gettext_id => 'Certificate verification',
                format     => ['none', 'optional', 'required'],
                synonym    => {'require' => 'required'},
                occurrence => '1',
                default    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            bind_dn => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "remote user",
                format     => '.+'
            },
            user => {
                context  => [qw(list)],
                obsolete => 'bind_dn'
            },
            bind_password => {
                context    => [qw(list)],
                order      => 3.5,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password',
                length     => 10
            },
            passwd => {
                context  => [qw(list)],
                obsolete => 'bind_password'
            },
            suffix => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "suffix",
                format     => '.+'
            },
            scope => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "search scope",
                format     => ['base', 'one', 'sub'],
                occurrence => '1',
                default    => 'sub'
            },
            timeout => {
                context      => [qw(list)],
                order        => 6,
                gettext_id   => "connection timeout",
                gettext_unit => 'seconds',
                format       => '\w+',
                length       => 6,
                default      => 30
            },
            filter => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => "filter",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            attrs => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => "extracted attribute",
                format_s   => '$ldap_attrdesc(\s*,\s*$ldap_attrdesc)?',
                default    => 'mail',
                length     => 50
            },
            select => {
                context    => [qw(list)],
                order      => 9,
                gettext_id => "selection (if multiple)",
                format     => ['all', 'first', 'regex'],
                occurrence => '1',
                default    => 'first'
            },
            regex => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "regular expression",
                format     => '.+',
                default    => '',
                length     => 50
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 11,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            }
        },
        occurrence => '0-n'
    },

    include_ldap_2level_query => {
        context    => [qw(list)],
        order      => 60.09,
        group      => 'data_source',
        gettext_id => "LDAP 2-level query inclusion",
        gettext_comment =>
            'This paragraph defines parameters for a two-level query returning a list of subscribers. Usually the first-level query returns a list of DNs and the second-level queries convert the DNs into e-mail addresses. This feature requires the Net::LDAP (perlldap) PERL module.',
        format => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            host => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "remote host",
                format_s   => '$multiple_host_or_url',
                occurrence => '1'
            },
            port => {
                context    => [qw(list)],
                order      => 2.1,
                gettext_id => "remote port",
                format     => '\d+',
                obsolete   => 1,
                length     => 4
            },
            use_tls => {
                context    => [qw(list)],
                order      => 2.4,
                gettext_id => 'use TLS (formerly SSL)',
                format     => ['starttls', 'ldaps', 'none'],
                synonym    => {'yes' => 'ldaps', 'no' => 'none'},
                occurrence => '1',
                default    => 'none',
            },
            use_ssl => {
                context => [qw(list)],
                #order => 2.5,
                #gettext_id => 'use SSL (LDAPS)',
                #format => ['yes', 'no'],
                #default => 'no'
                obsolete => 'use_tls',    # 5.3a.2 - 6.2.14
            },
            ssl_version => {
                context    => [qw(list)],
                order      => 2.6,
                gettext_id => 'SSL version',
                format     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                synonym    => {'tls' => 'tlsv1'},
                occurrence => '1',
                default    => 'tlsv1'
            },
            ssl_ciphers => {
                context    => [qw(list)],
                order      => 2.7,
                gettext_id => 'SSL ciphers used',
                format     => '.+',
                default    => 'ALL'
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            ca_verify => {
                context    => [qw(list)],
                order      => 2.8,
                gettext_id => 'Certificate verification',
                format     => ['none', 'optional', 'required'],
                synonym    => {'require' => 'required'},
                occurrence => '1',
                default    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            bind_dn => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "remote user",
                format     => '.+'
            },
            user => {
                context  => [qw(list)],
                obsolete => 'bind_dn'
            },
            bind_password => {
                context    => [qw(list)],
                order      => 3.5,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password',
                length     => 10
            },
            passwd => {
                context  => [qw(list)],
                obsolete => 'bind_password'
            },
            suffix1 => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "first-level suffix",
                format     => '.+'
            },
            scope1 => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "first-level search scope",
                format     => ['base', 'one', 'sub'],
                default    => 'sub'
            },
            timeout1 => {
                context      => [qw(list)],
                order        => 6,
                gettext_id   => "first-level connection timeout",
                gettext_unit => 'seconds',
                format       => '\w+',
                length       => 6,
                default      => 30
            },
            filter1 => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => "first-level filter",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            attrs1 => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => "first-level extracted attribute",
                format_s   => '$ldap_attrdesc',
                length     => 15
            },
            select1 => {
                context    => [qw(list)],
                order      => 9,
                gettext_id => "first-level selection",
                format     => ['all', 'first', 'regex'],
                occurrence => '1',
                default    => 'first'
            },
            regex1 => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "first-level regular expression",
                format     => '.+',
                default    => '',
                length     => 50
            },
            suffix2 => {
                context    => [qw(list)],
                order      => 11,
                gettext_id => "second-level suffix template",
                format     => '.+'
            },
            scope2 => {
                context    => [qw(list)],
                order      => 12,
                gettext_id => "second-level search scope",
                format     => ['base', 'one', 'sub'],
                occurrence => '1',
                default    => 'sub'
            },
            timeout2 => {
                context      => [qw(list)],
                order        => 13,
                gettext_id   => "second-level connection timeout",
                gettext_unit => 'seconds',
                format       => '\w+',
                length       => 6,
                default      => 30
            },
            filter2 => {
                context    => [qw(list)],
                order      => 14,
                gettext_id => "second-level filter template",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            attrs2 => {
                context    => [qw(list)],
                order      => 15,
                gettext_id => "second-level extracted attribute",
                format_s   => '$ldap_attrdesc(\s*,\s*$ldap_attrdesc)?',
                default    => 'mail',
                length     => 50
            },
            select2 => {
                context    => [qw(list)],
                order      => 16,
                gettext_id => "second-level selection",
                format     => ['all', 'first', 'regex'],
                occurrence => '1',
                default    => 'first'
            },
            regex2 => {
                context    => [qw(list)],
                order      => 17,
                gettext_id => "second-level regular expression",
                format     => '.+',
                default    => '',
                length     => 50
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 18,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            }
        },
        occurrence => '0-n'
    },

    include_sql_query => {
        context    => [qw(list)],
        order      => 60.10,
        group      => 'data_source',
        gettext_id => "SQL query inclusion",
        gettext_comment =>
            'This parameter is used to define the SQL query parameters. ',
        format => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            db_type => {
                context    => [qw(list)],
                order      => 1.5,
                gettext_id => "database type",
                format     => '\S+',
                occurrence => '1'
            },
            db_host => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "remote host",
                format_s   => '$host',
                # Not required for ODBC
                # occurrence => '1'
            },
            host => {
                context  => [qw(list)],
                obsolete => 'db_host'
            },
            db_port => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "database port",
                format     => '\d+'
            },
            db_name => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "database name",
                format     => '\S+',
                occurrence => '1'
            },
            db_options => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "connection options",
                format     => '.+'
            },
            connect_options => {
                context  => [qw(list)],
                obsolete => 'db_options'
            },
            db_env => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "environment variables for database connection",
                format     => '\w+\=\S+(;\w+\=\S+)*'
            },
            db_user => {
                context    => [qw(list)],
                order      => 6,
                gettext_id => "remote user",
                format     => '\S+',
                occurrence => '1'
            },
            user => {
                context  => [qw(list)],
                obsolete => 'db_user'
            },
            db_passwd => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password'
            },
            passwd => {
                context  => [qw(list)],
                obsolete => 'db_passwd'
            },
            sql_query => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => "SQL query",
                format_s   => '$sql_query',
                occurrence => '1',
                length     => 50
            },
            f_dir => {
                context => [qw(list)],
                order   => 9,
                gettext_id =>
                    "Directory where the database is stored (used for DBD::CSV only)",
                format => '.+'
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            }
        },
        occurrence => '0-n'
    },

    ttl => {
        context    => [qw(list site)],
        order      => 60.12,
        group      => 'data_source',
        gettext_id => "Inclusions timeout",
        gettext_comment =>
            'Sympa caches user data extracted using the include parameter. Their TTL (time-to-live) within Sympa can be controlled using this parameter. The default value is 3600',
        #gettext_comment =>
        #    'Default timeout between two scheduled synchronizations of list members with data sources.',
        gettext_unit => 'seconds',
        format       => '\d+',
        default      => '3600',
        length       => 6
    },

    distribution_ttl => {
        context => [qw(list site)],
        order   => 60.13,
        group   => 'data_source',
        gettext_id => "Inclusions timeout for message distribution",
        gettext_comment =>
            "This parameter defines the delay since the last synchronization after which the user's list will be updated before performing either of following actions:\n* Reviewing list members\n* Message distribution",
        gettext_unit => 'seconds',
        format       => '\d+',
        length       => 6
    },

    include_ldap_ca => {
        context    => [qw(list)],
        order      => 60.14,
        group      => 'data_source',
        gettext_id => "LDAP query custom attribute",
        format     => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            host => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "remote host",
                format_s   => '$multiple_host_or_url',
                occurrence => '1'
            },
            port => {
                context    => [qw(list)],
                order      => 2.1,
                gettext_id => "remote port",
                format     => '\d+',
                obsolete   => 1,
                length     => 4
            },
            use_tls => {
                context    => [qw(list)],
                order      => 2.4,
                gettext_id => 'use TLS (formerly SSL)',
                format     => ['starttls', 'ldaps', 'none'],
                synonym    => {'yes' => 'ldaps', 'no' => 'none'},
                occurrence => '1',
                default    => 'none',
            },
            use_ssl => {
                context => [qw(list)],
                #order => 2.5,
                #gettext_id => 'use SSL (LDAPS)',
                #format => ['yes', 'no'],
                #default => 'no'
                obsolete => 'use_tls',    # 6.2a? - 6.2.14
            },
            ssl_version => {
                context    => [qw(list)],
                order      => 2.6,
                gettext_id => 'SSL version',
                format     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                synonym    => {'tls' => 'tlsv1'},
                occurrence => '1',
                default    => 'tlsv1'
            },
            ssl_ciphers => {
                context    => [qw(list)],
                order      => 2.7,
                gettext_id => 'SSL ciphers used',
                format     => '.+',
                default    => 'ALL'
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            ca_verify => {
                context    => [qw(list)],
                order      => 2.8,
                gettext_id => 'Certificate verification',
                format     => ['none', 'optional', 'required'],
                synonym    => {'require' => 'required'},
                occurrence => '1',
                default    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            bind_dn => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "remote user",
                format     => '.+'
            },
            user => {
                context  => [qw(list)],
                obsolete => 'bind_dn'
            },
            bind_password => {
                context    => [qw(list)],
                order      => 3.5,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password',
                length     => 10
            },
            passwd => {
                context  => [qw(list)],
                obsolete => 'bind_password'
            },
            suffix => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "suffix",
                format     => '.+'
            },
            scope => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "search scope",
                format     => ['base', 'one', 'sub'],
                occurrence => '1',
                default    => 'sub'
            },
            timeout => {
                context      => [qw(list)],
                order        => 6,
                gettext_id   => "connection timeout",
                gettext_unit => 'seconds',
                format       => '\w+',
                length       => 6,
                default      => 30
            },
            filter => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => "filter",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            attrs => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => "extracted attribute",
                format_s   => '$ldap_attrdesc(\s*,\s*$ldap_attrdesc)?',
                default    => 'mail',
                length     => 15
            },
            email_entry => {
                context    => [qw(list)],
                order      => 9,
                gettext_id => "Name of email entry",
                format     => '\S+',
                occurrence => '1'
            },
            select => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "selection (if multiple)",
                format     => ['all', 'first', 'regex'],
                occurrence => '1',
                default    => 'first'
            },
            regex => {
                context    => [qw(list)],
                order      => 11,
                gettext_id => "regular expression",
                format     => '.+',
                default    => '',
                length     => 50
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 12,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            }
        },
        occurrence => '0-n'
    },

    include_ldap_2level_ca => {
        context    => [qw(list)],
        order      => 60.15,
        group      => 'data_source',
        gettext_id => "LDAP 2-level query custom attribute",
        format     => {
            name => {
                context    => [qw(list)],
                format     => '.+',
                gettext_id => "short name for this source",
                length     => 50,
                order      => 1,
            },
            host => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "remote host",
                format_s   => '$multiple_host_or_url',
                occurrence => '1'
            },
            port => {
                context    => [qw(list)],
                order      => 2.1,
                gettext_id => "remote port",
                format     => '\d+',
                obsolete   => 1,
                length     => 4
            },
            use_tls => {
                context    => [qw(list)],
                order      => 2.4,
                gettext_id => 'use TLS (formerly SSL)',
                format     => ['starttls', 'ldaps', 'none'],
                synonym    => {'yes' => 'ldaps', 'no' => 'none'},
                occurrence => '1',
                default    => 'none',
            },
            use_ssl => {
                context => [qw(list)],
                #order => 2.5,
                #gettext_id => 'use SSL (LDAPS)',
                #format => ['yes', 'no'],
                #default => 'no'
                obsolete => 'use_tls',    # 6.2a? - 6.2.14
            },
            ssl_version => {
                context    => [qw(list)],
                order      => 2.6,
                gettext_id => 'SSL version',
                format     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                synonym    => {'tls' => 'tlsv1'},
                occurrence => '1',
                default    => 'tlsv1'
            },
            ssl_ciphers => {
                context    => [qw(list)],
                order      => 2.7,
                gettext_id => 'SSL ciphers used',
                format     => '.+',
                default    => 'ALL'
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            ca_verify => {
                context    => [qw(list)],
                order      => 2.8,
                gettext_id => 'Certificate verification',
                format     => ['none', 'optional', 'required'],
                synonym    => {'require' => 'required'},
                occurrence => '1',
                default    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            bind_dn => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "remote user",
                format     => '.+',
            },
            user => {
                context  => [qw(list)],
                obsolete => 'bind_dn'
            },
            bind_password => {
                context    => [qw(list)],
                order      => 3.5,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password',
                length     => 10
            },
            passwd => {
                context  => [qw(list)],
                obsolete => 'bind_password'
            },
            suffix1 => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "first-level suffix",
                format     => '.+'
            },
            scope1 => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "first-level search scope",
                format     => ['base', 'one', 'sub'],
                occurrence => '1',
                default    => 'sub'
            },
            timeout1 => {
                context      => [qw(list)],
                order        => 6,
                gettext_id   => "first-level connection timeout",
                gettext_unit => 'seconds',
                format       => '\w+',
                length       => 6,
                default      => 30
            },
            filter1 => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => "first-level filter",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            attrs1 => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => "first-level extracted attribute",
                format_s   => '$ldap_attrdesc',
                length     => 15
            },
            select1 => {
                context    => [qw(list)],
                order      => 9,
                gettext_id => "first-level selection",
                format     => ['all', 'first', 'regex'],
                occurrence => '1',
                default    => 'first'
            },
            regex1 => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "first-level regular expression",
                format     => '.+',
                default    => '',
                length     => 50
            },
            suffix2 => {
                context    => [qw(list)],
                order      => 11,
                gettext_id => "second-level suffix template",
                format     => '.+'
            },
            scope2 => {
                context    => [qw(list)],
                order      => 12,
                gettext_id => "second-level search scope",
                format     => ['base', 'one', 'sub'],
                occurrence => '1',
                default    => 'sub'
            },
            timeout2 => {
                context      => [qw(list)],
                order        => 13,
                gettext_id   => "second-level connection timeout",
                gettext_unit => 'seconds',
                format       => '\w+',
                length       => 6,
                default      => 30
            },
            filter2 => {
                context    => [qw(list)],
                order      => 14,
                gettext_id => "second-level filter template",
                format     => '.+',
                occurrence => '1',
                length     => 50
            },
            attrs2 => {
                context    => [qw(list)],
                order      => 15,
                gettext_id => "second-level extracted attribute",
                format_s   => '$ldap_attrdesc',
                default    => 'mail',
                length     => 15
            },
            select2 => {
                context    => [qw(list)],
                order      => 16,
                gettext_id => "second-level selection",
                format     => ['all', 'first', 'regex'],
                occurrence => '1',
                default    => 'first'
            },
            regex2 => {
                context    => [qw(list)],
                order      => 17,
                gettext_id => "second-level regular expression",
                format     => '.+',
                default    => '',
                length     => 50
            },
            email_entry => {
                context    => [qw(list)],
                order      => 18,
                gettext_id => "Name of email entry",
                format     => '\S+',
                occurrence => '1'
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 19,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            }
        },
        occurrence => '0-n'
    },

    include_sql_ca => {
        context    => [qw(list)],
        order      => 60.16,
        group      => 'data_source',
        gettext_id => "SQL query custom attribute",
        format     => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "short name for this source",
                format     => '.+',
                length     => 50,
            },
            db_type => {
                context    => [qw(list)],
                order      => 1.5,
                gettext_id => "database type",
                format     => '\S+',
                occurrence => '1'
            },
            db_host => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "remote host",
                format_s   => '$host',
                # Not required for ODBC and SQLite. Optional for Oracle.
                #occurrence => '1'
            },
            host => {
                context  => [qw(list)],
                obsolete => 'db_host'
            },
            db_port => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "database port",
                format     => '\d+'
            },
            db_name => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "database name",
                format     => '\S+',
                occurrence => '1'
            },
            db_options => {
                context    => [qw(list)],
                order      => 4.5,
                gettext_id => "connection options",
                format     => '.+'
            },
            connect_options => {
                context  => [qw(list)],
                obsolete => 'db_options'
            },
            db_env => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "environment variables for database connection",
                format     => '\w+\=\S+(;\w+\=\S+)*'
            },
            db_user => {
                context    => [qw(list)],
                order      => 6,
                gettext_id => "remote user",
                format     => '\S+',
                occurrence => '1'
            },
            user => {
                context  => [qw(list)],
                obsolete => 'db_user'
            },
            db_passwd => {
                context    => [qw(list)],
                order      => 7,
                gettext_id => "remote password",
                format     => '.+',
                field_type => 'password'
            },
            passwd => {
                context  => [qw(list)],
                obsolete => 'db_passwd'
            },
            sql_query => {
                context    => [qw(list)],
                order      => 8,
                gettext_id => "SQL query",
                format_s   => '$sql_query',
                occurrence => '1',
                length     => 50
            },
            f_dir => {
                context => [qw(list)],
                order   => 9,
                gettext_id =>
                    "Directory where the database is stored (used for DBD::CSV only)",
                format => '.+'
            },
            email_entry => {
                context    => [qw(list)],
                order      => 10,
                gettext_id => "Name of email entry",
                format     => '\S+',
                occurrence => '1'
            },
            nosync_time_ranges => {
                context    => [qw(list)],
                order      => 11,
                gettext_id => "Time ranges when inclusion is not allowed",
                format_s   => '$time_ranges',
                occurrence => '0-1'
            }
        },
        occurrence => '0-n'
    },

    ### DKIM page ###

    dkim_add_signature_to => {
        context    => [qw(domain site)],
        order      => 70.00_01,
        group      => 'dkim',
        default    => 'robot,list',
        gettext_id => 'Which service messages to be signed',
        gettext_comment =>
            'Inserts a DKIM signature to service messages in context of robot, list or both',
        format     => '(?:list|robot)(?:,(?:list|robot))*',    #FIXME
        split_char => ',',
    },

    dkim_signer_identity => {    # Not derived by list config
        context         => [qw(domain site)],
        order           => 70.00_03,
        group           => 'dkim',
        gettext_id      => 'The "i=" tag as defined in rfc 4871',
        gettext_comment => 'Default is null.',
        format_s        => '\S+',
    },

    dkim_feature => {
        context => [qw(domain site)],
        order   => 70.01,
        group   => 'dkim',
        #gettext_id => 'Enable DKIM',
        #gettext_comment =>
        #    "Enable/Disable DKIM. This feature requires Mail::DKIM to be installed, and maybe some custom scenario to be updated",
        gettext_id => "Insert DKIM signature to messages sent to the list",
        gettext_comment =>
            'If set to "on", Sympa may verify DKIM signatures of incoming messages and/or insert DKIM signature to outgoing messages.',
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'off',
    },

    dkim_parameters => {
        context    => [qw(list domain site)],
        order      => 70.02,
        group      => 'dkim',
        gettext_id => "DKIM configuration",
        gettext_comment =>
            'A set of parameters in order to define outgoing DKIM signature',
        format => {
            private_key_path => {
                context => [qw(list domain site)],
                order   => 1,
                #gettext_id => "File path for list DKIM private key",
                #gettext_comment =>
                #    "The file must contain a RSA pem encoded private key",
                gettext_id => 'File path for DKIM private key',
                gettext_comment =>
                    'The file must contain a PEM encoded private key',
                format     => '\S+',
                occurrence => '0-1',
            },
            selector => {
                context    => [qw(list domain site)],
                order      => 2,
                gettext_id => "Selector for DNS lookup of DKIM public key",
                #gettext_comment =>
                #    "The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for <selector>._domainkey.your_domain",
                gettext_comment =>
                    'The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for "<selector>._domainkey.your_domain"',
                format     => '\S+',
                occurrence => '0-1',
            },
            header_list => {
                obsolete => 1,                        # Not yet implemented
                context  => [qw(list domain site)],
                order    => 4,
                gettext_id =>
                    'List of headers to be included into the message for signature',
                gettext_comment =>
                    'You should probably use the default value which is the value recommended by RFC4871',
                format     => '\S+',
                occurrence => '1-n',
                split_char => ':',                    #FIXME
                default =>
                    'from:sender:reply-to:subject:date:message-id:to:cc:list-id:list-help:list-unsubscribe:list-subscribe:list-post:list-owner:list-archive:in-reply-to:references:resent-date:resent-from:resent-sender:resent-to:resent-cc:resent-message-id:mime-version:content-type:content-transfer-encoding:content-id:content-description',
            },
            signer_domain => {
                context => [qw(list domain site)],
                order   => 5,
                gettext_id =>
                    'DKIM "d=" tag, you should probably use the default value',
                gettext_comment =>
                    'The DKIM "d=" tag, is the domain of the signing entity. The list domain MUST be included in the "d=" domain',
                #gettext_id => 'The "d=" tag as defined in rfc 4871',
                #gettext_comment =>
                #    'The DKIM "d=" tag is the domain of the signing entity. The virtual host domain name is used as its default value',
                format     => '\S+',
                occurrence => '0-1',
            },
            signer_identity => {
                context => [qw(list)],    # Not deriving domain conf
                order   => 6,
                gettext_id =>
                    'DKIM "i=" tag, you should probably leave this parameter empty',
                gettext_comment =>
                    'DKIM "i=" tag, you should probably not use this parameter, as recommended by RFC 4871, default for list brodcasted messages is i=<listname>-request@<domain>',
                format     => '\S+',
                occurrence => '0-1'
            },
        },
        occurrence => '0-1'
    },

    dkim_signature_apply_on => {
        context => [qw(list domain site)],
        order   => 70.03,
        group   => 'dkim',
        gettext_id =>
            "The categories of messages sent to the list that will be signed using DKIM.",
        gettext_comment =>
            "This parameter controls in which case messages must be signed using DKIM, you may sign every message choosing 'any' or a subset. The parameter value is a comma separated list of keywords",
        #gettext_id => 'Which messages delivered via lists to be signed',
        #gettext_comment =>
        #    'Type of message that is added a DKIM signature before distribution to subscribers. Possible values are "none", "any" or a list of the following keywords: "md5_authenticated_messages", "smime_authenticated_messages", "dkim_authenticated_messages", "editor_validated_messages".',
        format => [
            'md5_authenticated_messages',  'smime_authenticated_messages',
            'dkim_authenticated_messages', 'editor_validated_messages',
            'none',                        'any'
        ],
        occurrence => '0-n',
        split_char => ',',
        default =>
            'md5_authenticated_messages,smime_authenticated_messages,dkim_authenticated_messages,editor_validated_messages',
    },

    arc_feature => {
        context    => [qw(list domain site)],
        order      => 70.04,
        group      => 'dkim',
        gettext_id => "Add ARC seals to messages sent to the list",
        gettext_comment =>
            "Enable/Disable ARC. This feature requires Mail::DKIM::ARC to be installed, and maybe some custom scenario to be updated",
        #gettext_id => 'Enable ARC',
        #gettext_comment =>
        #    'If set to "on", Sympa may add ARC seals to outgoing messages.',
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'off',
    },

    arc_srvid => {
        context    => [qw(domain site)],
        order      => 70.05,
        group      => 'dkim',
        gettext_id => 'SRV ID for Authentication-Results used in ARC seal',
        gettext_comment => 'Typically the domain of the mail server',
        format => '\S+',    # "value" defined in RFC 2045, 5.1
    },

    arc_parameters => {
        context    => [qw(list domain site)],
        order      => 70.06,
        group      => 'dkim',
        gettext_id => "ARC configuration",
        gettext_comment =>
            'A set of parameters in order to define outgoing ARC seal',
        format => {
            arc_private_key_path => {
                context => [qw(list domain site)],
                order   => 1,
                #gettext_id => "File path for list ARC private key",
                #gettext_comment =>
                #    "The file must contain a RSA pem encoded private key. Default is DKIM private key.",
                gettext_id => 'File path for ARC private key',
                gettext_comment =>
                    'The file must contain a PEM encoded private key. Defaults to same file as DKIM private key',
                format     => '\S+',
                occurrence => '0-1',
            },
            arc_selector => {
                context    => [qw(list domain site)],
                order      => 2,
                gettext_id => "Selector for DNS lookup of ARC public key",
                #gettext_comment =>
                #    "The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for <selector>._domainkey.your_domain.  Default is selector for DKIM signature",
                gettext_comment =>
                    'The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for "<selector>._domainkey.your_domain". Default is the same selector as for DKIM signatures',
                format     => '\S+',
                occurrence => '0-1',
            },
            arc_signer_domain => {
                context => [qw(list domain site)],
                order   => 3,
                gettext_id =>
                    'ARC "d=" tag, you should probably use the default value',
                gettext_comment =>
                    'The ARC "d=" tag is the domain of the signing entity. The DKIM d= domain name is used as its default value',
                #gettext_id => 'The "d=" tag as defined in ARC',
                #gettext_comment =>
                #    'The ARC "d=" tag, is the domain of the sealing entity. The list domain MUST be included in the "d=" domain',
                format     => '\S+',
                occurrence => '0-1',
            },
        },
        occurrence => '0-1'
    },

    dmarc_protection => {
        context => [qw(list domain site)],
        order   => 70.07,
        format  => {
            mode => {
                context => [qw(list domain site)],
                format  => [
                    'none',           'all',
                    'dkim_signature', 'dmarc_reject',
                    'dmarc_any',      'dmarc_quarantine',
                    'domain_regex'
                ],
                synonym => {
                    'dkim'         => 'dkim_signature',
                    'dkim_exists'  => 'dkim_signature',
                    'dmarc_exists' => 'dmarc_any',
                    'domain'       => 'domain_regex',
                    'domain_match' => 'domain_regex',
                },
                sample     => 'dmarc_reject,dkim_signature',
                gettext_id => "Protection modes",
                split_char => ',',
                occurrence => '0-n',
                gettext_comment =>
                    'Select one or more operation modes.  "Domain matching regular expression" (domain_regex) matches the specified Domain regular expression; "DKIM signature exists" (dkim_signature) matches any message with a DKIM signature header; "DMARC policy ..." (dmarc_*) matches messages from sender domains with a DMARC policy as given; "all" (all) matches all messages.',
                #gettext_id => 'Test mode(s) for DMARC Protection',
                #gettext_comment =>
                #    "Do not set unless you want to use DMARC protection.\nThis is a comma separated list of test modes; if multiple are selected then protection is activated if ANY match.  Do not use dmarc_* modes unless you have a local DNS cache as they do a DNS lookup for each received message.",
                order => 1
            },
            domain_regex => {
                context    => [qw(list domain site)],
                order      => 2,
                gettext_id => 'Regular expression for domain name match',
                gettext_comment =>
                    'Regular expression match pattern for From domain',
                #gettext_id => "Match domain regular expression",
                #gettext_comment =>
                #    'This is used for the "domain_regex" protection mode.',
                occurrence => '0-1',
                format     => '.+',
            },
            other_email => {
                context    => [qw(list domain site)],
                format     => '.+',
                gettext_id => "New From address",
                occurrence => '0-1',
                gettext_comment =>
                    'This is the email address to use when modifying the From header.  It defaults to the list address.  This is similar to Anonymisation but preserves the original sender details in the From address phrase.',
                order => 3,
            },
            phrase => {
                context => [qw(list domain site)],
                format  => [
                    'display_name',   'name_and_email',
                    'name_via_list',  'name_email_via_list',
                    'list_for_email', 'list_for_name',
                ],
                synonym =>
                    {'name' => 'display_name', 'prefixed' => 'list_for_name'},
                default    => 'name_via_list',
                gettext_id => "New From name format",
                occurrence => '0-1',
                #gettext_comment =>
                #    'This is the format to be used for the sender name part of the new From header.',
                gettext_comment =>
                    'This is the format to be used for the sender name part of the new From header field.',
                order => 4,
            },
        },
        gettext_id => "DMARC Protection",
        group      => 'dkim',
        gettext_comment =>
            "Parameters to define how to manage From address processing to avoid some domains' excessive DMARC protection",
        occurrence => '0-1',
    },

    ### Optional features

    ### List address verification

    list_check_helo => {
        context => [qw(domain site)],
        order   => 72.00_01,
        group   => 'list_check',
        gettext_id =>
            'SMTP HELO (EHLO) parameter used for address verification',
        gettext_comment =>
            'Default value is the host part of "list_check_smtp" parameter.',
        format => '\S+',
    },
    list_check_smtp => {
        context => [qw(domain site)],
        order   => 72.00_02,
        group   => 'list_check',
        gettext_id =>
            'SMTP server to verify existence of the same addresses as the list to be created',
        gettext_comment =>
            "This is needed if you are running Sympa on a host but you handle all your mail on a separate mail relay.\nDefault value is real FQDN of the host. Port number may be specified as \"mail.example.org:25\" or \"203.0.113.1:25\".  If port is not specified, standard port (25) will be used.",
        format_s => '$hostport',
    },
    list_check_suffixes => {
        context    => [qw(domain site)],
        order      => 72.00_03,
        group      => 'list_check',
        gettext_id => 'Address suffixes to verify',
        gettext_comment =>
            "List of suffixes you are using for list addresses, i.e. \"mylist-request\", \"mylist-owner\" and so on.\nThis parameter is used with the \"list_check_smtp\" parameter. It is also used to check list names at list creation time.",
        format     => '\S+',                                          #FIXME
        default    => 'request,owner,editor,unsubscribe,subscribe',
        split_char => ',',
    },

    ### Antivirus plug-in

    antivirus_path => {
        context    => [qw(domain site)],
        order      => 73.00_01,
        group      => 'antivirus',
        sample     => '/usr/local/bin/clamscan',
        gettext_id => 'Path to the antivirus scanner engine',
        gettext_comment =>
            'Supported antivirus: Clam AntiVirus/clamscan & clamdscan, McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall',
        format => '.+',
    },
    antivirus_args => {
        context    => [qw(domain site)],
        order      => 73.00_02,
        group      => 'antivirus',
        sample     => '--no-summary --database /usr/local/share/clamav',
        gettext_id => 'Antivirus plugin command line arguments',
        format     => '.+',
    },
    antivirus_notify => {
        context => [qw(domain site)],
        order   => 73.00_03,
        group   => 'antivirus',
        gettext_id =>
            'Notify sender if virus checker detects malicious content',
        default => 'sender',
        gettext_comment =>
            '"sender" to notify originator of the message, "delivery_status" to send delivery status, or "none"',
        format => ['sender', 'delivery_status', 'none'],
    },

    ### Miscelaneous page ###

    email => {
        context    => [qw(domain site)],
        order      => 90.00_01,
        group      => 'other',
        default    => 'sympa',
        gettext_id => 'Local part of Sympa email address',
        gettext_comment =>
            "Local part (the part preceding the \"\@\" sign) of the address by which mail interface of Sympa accepts mail commands.\nIf you change the default value, you must modify the mail aliases too.",
        format => '\S+',
    },
    listmaster_email => {
        context    => [qw(domain site)],
        order      => 90.00_02,
        group      => 'other',
        default    => 'listmaster',
        gettext_id => 'Local part of listmaster email address',
        gettext_comment =>
            "Local part (the part preceding the \"\@\" sign) of the address by which listmasters receive messages.\nIf you change the default value, you must modify the mail aliases too.",
        format => '\S+',
    },
    custom_robot_parameter => {
        order      => 90.00_03,
        context    => [qw(domain site)],
        group      => 'other',
        gettext_id => 'Custom robot parameter',
        gettext_comment =>
            "Used to define a custom parameter for your server. Do not forget the semicolon between the parameter name and the parameter value.\nYou will be able to access the custom parameter value in web templates by variable \"conf.custom_robot_parameter.<param_name>\"",
        format     => '.+',
        sample     => 'param_name ; param_value',
        occurrence => '0-n',
    },

    prohibited_listnames => {
        context => [qw(site)],
        order   => 90.00_035,
        group   => 'other',
        gettext_id =>
            'Prevent people to use some names for their lists names',
        gettext_comment =>
            'This parameter is a comma-separated list of names. You can use * as a wildcard character. To use a regex for this, please use prohibited_listnames_regex setting.',
        sample => 'www,root,*master',
        #XXXsplit_char => ',',
    },
    prohibited_listnames_regex => {
        context => [qw(site)],
        order   => 90.00_036,
        group   => 'other',
        gettext_id =>
            'Prevent people to use some names for their lists names, based on a regex',
        gettext_comment =>
            'This parameter is a regex. Please note that prohibited_listnames and prohibited_listnames_regex will both be applied if set, they are not exclusive.',
        sample => 'www|root|.*master',
    },

    cache_list_config => {
        order      => 90.00_04,
        context    => [qw(site)],
        group      => 'other',
        default    => 'none',
        gettext_id => 'Use of binary cache of list configuration',
        gettext_comment =>
            "binary_file: Sympa processes will maintain a binary version of the list configuration, \"config.bin\" file on local disk. If you manage a big amount of lists (1000+), it should make the web interface startup faster.\nYou can recreate cache by running \"sympa.pl --reload_list_config\".",
        format => ['binary_file', 'none'],    #FIXME: "on"/"off" is better
    },
    db_list_cache => {
        order      => 90.00_05,
        context    => [qw(site)],
        group      => 'other',
        default    => 'off',
        gettext_id => 'Use database cache to search lists',
        gettext_comment =>
            "Note that \"list_table\" database table should be filled at the first time by running:\n  # sympa.pl --sync_list_db",
        format => ['on', 'off'],              #XXX
    },
    purge_user_table_task => {
        context    => [qw(site)],
        order      => 90.00_06,
        group      => 'other',
        gettext_id => 'Task for expiring inactive users',
        gettext_comment =>
            'This task removes rows in the "user_table" table which have not corresponding entries in the "subscriber_table" table.',
        default => 'monthly',
        task    => 'purge_user_table',
    },
    purge_logs_table_task => {
        context    => [qw(site)],
        order      => 90.00_07,
        group      => 'other',
        gettext_id => 'Task for cleaning tables',
        gettext_comment =>
            'This task cleans old logs from "logs_table" table.',
        default => 'daily',
        task    => 'purge_logs_table',
    },
    logs_expiration_period => {
        context    => [qw(site)],
        order      => 90.00_08,
        group      => 'other',
        gettext_id => 'Max age of logs in database',
        gettext_comment =>
            'Number of months that elapse before a log is expired',
        format       => '\d+',
        gettext_unit => 'months',
        default      => '3',
    },
    stats_expiration_period => {
        context    => [qw(site)],
        order      => 90.00_09,
        group      => 'other',
        gettext_id => 'Max age of statistics information in database',
        gettext_comment =>
            'Number of months that elapse before statistics information are expired',
        format       => '\d+',
        gettext_unit => 'months',
        default      => '3',
    },

    umask => {
        context    => [qw(site)],
        order      => 90.00_10,
        group      => 'other',
        default    => '027',
        gettext_id => 'Umask',
        gettext_comment =>
            'Default mask for file creation (see umask(2)). Note that it will be interpreted as an octal value.',
        format     => '[0-7]+',
        occurrence => '1',
    },

    ### Miscelaneous (list)

    account => {
        context    => [qw(list)],
        group      => 'other',
        gettext_id => "Account",
        format     => '\S+',
        length     => 10,
        obsolete   => 1,
    },

    clean_delay_queuemod => {
        context => [qw(list site)],
        order   => 90.01,
        group   => 'other',           # directories
        #gettext_id => "Expiration of unmoderated messages",
        gettext_id => 'Max age of moderated messages',
        gettext_comment =>
            'Number of days messages are kept in moderation spool (as specified by "queuemod" parameter). Beyond this deadline, messages that have not been processed are deleted.',
        gettext_unit => 'days',
        format       => '\d+',
        length       => 3,
        default      => '30',
    },

    cookie => {
        context    => [qw(list site)],
        order      => 90.02,
        group      => 'other',
        sample     => '123456789',
        gettext_id => 'Secret string for generating unique keys',
        #gettext_comment =>
        #    'This parameter is a confidential item for generating authentication keys for administrative commands (ADD, DELETE, etc.). This parameter should remain concealed, even for owners. The cookie is applied to all list owners, and is only taken into account when the owner has the auth parameter.',
        gettext_comment =>
            "This allows generated authentication keys to differ from a site to another. It is also used for encryption of user passwords stored in the database. The presence of this string is one reason why access to \"sympa.conf\" needs to be restricted to the \"sympa\" user.\nNote that changing this parameter will break all HTTP cookies stored in users' browsers, as well as all user passwords and lists X509 private keys. To prevent a catastrophe, Sympa refuses to start if this \"cookie\" parameter was changed.",
        format     => '\S+',
        field_type => 'password',
        length     => 15,
        obsolete   => 1,
    },

    custom_attribute => {
        context    => [qw(list)],
        order      => 90.03,
        group      => 'other',
        gettext_id => "Custom user attributes",
        format     => {
            id => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "internal identifier",
                format     => '\w+',
                occurrence => '1',
                length     => 20
            },
            name => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => "label",
                format     => '.+',
                occurrence => '1',
                length     => 30
            },
            comment => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "additional comment",
                format     => '.+',
                length     => 100
            },
            type => {
                context    => [qw(list)],
                order      => 4,
                gettext_id => "type",
                format     => ['string', 'text', 'integer', 'enum'],
                default    => 'string',
                occurrence => 1
            },
            enum_values => {
                context    => [qw(list)],
                order      => 5,
                gettext_id => "possible attribute values (if enum is used)",
                format     => '.+',
                length     => 100
            },
            optional => {
                context    => [qw(list)],
                order      => 6,
                gettext_id => "is the attribute optional?",
                format     => ['required', 'optional'],
                default    => 'optional',
                occurrence => 1
            }
        },
        occurrence => '0-n'
    },

    custom_vars => {
        context    => [qw(list)],
        order      => 90.04,
        group      => 'other',
        gettext_id => "custom parameters",
        format     => {
            name => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'var name',
                format     => '\S+',
                occurrence => '1'
            },
            value => {
                context    => [qw(list)],
                order      => 2,
                gettext_id => 'var value',
                format     => '.+',
                occurrence => '1',
            }
        },
        occurrence => '0-n'
    },

    expire_task => {
        context    => [qw(list)],
        order      => 90.05,
        group      => 'other',
        gettext_id => "Periodical subscription expiration task",
        gettext_comment =>
            "This parameter states which model is used to create an expire task. An expire task regularly checks the subscription or resubscription  date of subscribers and asks them to renew their subscription. If they don't they are deleted.",
        task     => 'expire',
        obsolete => 1,
    },

    loop_prevention_regex => {
        context => [qw(list domain site)],
        order   => 90.06,
        group   => 'other',                  #loop_prevention
        gettext_id =>
            "Regular expression applied to prevent loops with robots",
        #gettext_id => 'Regular expression to prevent loop',
        gettext_comment =>
            'If the sender address matches the regular expression, then the message is rejected.',
        format  => '\S*',
        length  => 70,
        default => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
    },

    pictures_feature => {
        context => [qw(list domain site)],
        order   => 90.07,
        group   => 'other',                  #FIXME: www_other/pictures
        #gettext_id =>
        #    "Allow picture display? (must be enabled for the current robot)",
        gettext_id => 'Pictures',
        gettext_comment =>
            "Enables or disables the pictures feature by default.  If enabled, subscribers can upload their picture (from the \"Subscriber option\" page) to use as an avatar.\nPictures are stored in a directory specified by the \"static_content_path\" parameter.",
        format     => ['on', 'off'],
        occurrence => '1',
        default    => 'on',
    },

    remind_task => {
        context    => [qw(list site)],
        order      => 90.08,
        group      => 'other',
        gettext_id => 'Periodical subscription reminder task',
        gettext_comment =>
            'This parameter states which model is used to create a remind task. A remind task regularly sends  subscribers a message which reminds them of their list subscriptions.',
        #gettext_comment =>
        #    'This task regularly sends subscribers a message which reminds them of their list subscriptions.',
        task => 'remind',
    },

    ### Other (internal attributes of the list)

    latest_instantiation => {
        context    => [qw(list)],
        order      => 99.01,
        group      => 'other',
        gettext_id => 'Latest family instantiation',
        format     => {
            email => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'who ran the instantiation',
                format_s   => 'listmaster|$email',
                occurrence => '0-1'
            },
            date => {
                context => [qw(list)],
                #order => 2,
                obsolete   => 1,
                gettext_id => 'date',
                format     => '.+'
            },
            date_epoch => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => 'date',
                format     => '\d+',
                field_type => 'unixtime',
                occurrence => '1',
                length     => 10,
            }
        },
        internal => 1
    },

    creation => {
        context    => [qw(list)],
        order      => 99.02,
        group      => 'other',
        gettext_id => "Creation of the list",
        format     => {
            email => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => "who created the list",
                format_s   => 'listmaster|$email',
                occurrence => '1'
            },
            date => {
                context => [qw(list)],
                #order => 2,
                obsolete   => 1,
                gettext_id => "human readable",
                format     => '.+'
            },
            date_epoch => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => "date",
                format     => '\d+',
                field_type => 'unixtime',
                occurrence => '1',
                length     => 10,
            },
        },
        occurrence => '0-1',
        internal   => 1
    },

    update => {
        context    => [qw(list)],
        order      => 99.03,
        group      => 'other',
        gettext_id => "Last update of config",
        format     => {
            email => {
                context    => [qw(list)],
                order      => 1,
                gettext_id => 'who updated the config',
                format_s   => '(listmaster|automatic|$email)',
                occurrence => '0-1',
                length     => 30
            },
            date => {
                context => [qw(list)],
                #order => 2,
                obsolete   => 1,
                gettext_id => 'date',
                format     => '.+',
                length     => 30
            },
            date_epoch => {
                context    => [qw(list)],
                order      => 3,
                gettext_id => 'date',
                format     => '\d+',
                field_type => 'unixtime',
                occurrence => '1',
                length     => 10,
            }
        },
        internal => 1,
    },

    status => {
        context    => [qw(list)],
        order      => 99.04,
        group      => 'other',
        gettext_id => "Status of the list",
        format =>
            ['open', 'closed', 'pending', 'error_config', 'family_closed'],
        field_type => 'status',
        default    => 'open',
        internal   => 1
    },

    serial => {
        context    => [qw(list)],
        order      => 99.05,
        group      => 'other',
        gettext_id => "Serial number of the config",
        format     => '\d+',
        default    => 0,
        internal   => 1,
        length     => 3
    },

    # WWSympa: Basic configuration

    wwsympa_url => {
        context    => [qw(domain site)],
        order      => 110.01,
        group      => 'www_basic',
        sample     => 'https://web.example.org/sympa',
        gettext_id => 'URL prefix of web interface',
        gettext_comment =>
            'This is used to construct URLs of web interface. The protocol (either https:// or http://) is required.',
    },
    wwsympa_url_local => {
        context    => [qw(domain site)],
        order      => 110.02,
        group      => 'www_basic',
        gettext_id => 'URL prefix of WWSympa behind proxy',
    },
    static_content_url => {
        context    => [qw(domain site)],
        order      => 110.03,
        group      => 'www_basic',
        default    => '/static-sympa',
        gettext_id => 'URL for static contents',
        gettext_comment =>
            'HTTP server have to map it with "static_content_path" directory.',
    },
    static_content_path => {
        context    => [qw(domain site)],
        order      => 110.04,
        group      => 'www_basic',
        default_s  => '$STATICDIR',
        gettext_id => 'Directory for static contents',
    },
    css_path => {
        context    => [qw(site)],
        order      => 110.05,
        group      => 'www_basic',
        default_s  => '$CSSDIR',
        gettext_id => 'Directory for static style sheets (CSS)',
        gettext_comment =>
            'After an upgrade, static CSS files are upgraded with the newly installed "css.tt2" template. Therefore, this is not a good place to store customized CSS files.',
    },
    css_url => {
        context    => [qw(site)],
        order      => 110.06,
        group      => 'www_basic',
        default    => '/static-sympa/css',
        gettext_id => 'URL for style sheets (CSS)',
        gettext_comment =>
            'To use auto-generated static CSS, HTTP server have to map it with "css_path".',
    },
    pictures_path => {
        context    => [qw(site)],
        order      => 110.07,
        group      => 'www_basic',
        default_s  => '$PICTURESDIR',
        gettext_id => 'Directory for subscribers pictures',
    },
    pictures_url => {
        context    => [qw(site)],
        order      => 110.08,
        group      => 'www_basic',
        default    => '/static-sympa/pictures',
        gettext_id => 'URL for subscribers pictures',
        gettext_comment =>
            'HTTP server have to map it with "pictures_path" directory.',
    },
    mhonarc => {
        context         => [qw(domain site)],
        order           => 110.10,
        group           => 'www_basic',
        default         => '/usr/bin/mhonarc',
        gettext_id      => 'Path to MHonArc mail-to-HTML converter',
        file            => 'wwsympa.conf',
        gettext_comment => 'This is required for HTML mail archiving.',
    },
    log_facility => {
        context    => [qw(site)],
        order      => 110.20,
        group      => 'www_basic',
        default    => 'LOCAL1',
        gettext_id => 'System log facility for web interface',
        gettext_comment =>
            'System log facility for WWSympa, archived.pl and bounced.pl. Default is to use value of "syslog" parameter.',
        file => 'wwsympa.conf',
    },

    use_fast_cgi => {
        context    => [qw(site)],
        default    => '1',
        gettext_id => 'Enable FastCGI',
        file       => 'wwsympa.conf',
        gettext_comment =>
            'Is FastCGI module for HTTP server installed? This module provides a much faster web interface.',
        obsolete => 1,
    },

    logo_html_definition => {
        context    => [qw(domain site)],
        order      => 120.01,
        group      => 'www_appearances',
        gettext_id => 'Custom logo',
        gettext_comment =>
            'HTML fragment to insert a logo in the page of web interface.',
        sample =>
            '<a href="http://www.example.com"><img style="float: left; margin-top: 7px; margin-left: 37px;" src="http://www.example.com/logos/mylogo.jpg" alt="My Company" /></a>',
    },
    favicon_url => {
        context         => [qw(domain site)],
        order           => 120.02,
        group           => 'www_appearances',
        gettext_id      => 'Custom favicon',
        gettext_comment => 'URL of favicon image',
    },

    color_0 => {
        context    => [qw(domain site)],
        order      => 120.10,
        group      => 'www_appearances',
        gettext_id => 'Colors for web interface',
        gettext_comment =>
            'Colors are used in style sheet (CSS). They may be changed using web interface by listmasters.',
        default => '#f7f7f7',    # very light grey use in tables,
        db      => 'db_first',
    },
    color_1 => {
        context => [qw(domain site)],
        order   => 120.11,
        group   => 'www_appearances',
        default => '#222222',           # main menu button color,
        db      => 'db_first',
    },
    color_2 => {
        context => [qw(domain site)],
        order   => 120.12,
        group   => 'www_appearances',
        default => '#004b94',           # font color,
        db      => 'db_first',
    },
    color_3 => {
        context => [qw(domain site)],
        order   => 120.13,
        group   => 'www_appearances',
        default => '#5e5e5e',    # top boxe and footer box bacground color,
        db      => 'db_first',
    },
    color_4 => {
        context => [qw(domain site)],
        order   => 120.14,
        group   => 'www_appearances',
        default => '#4c4c4c',           #  page backgound color,
        db      => 'db_first',
    },
    color_5 => {
        context => [qw(domain site)],
        order   => 120.15,
        group   => 'www_appearances',
        default => '#0090e9',
        db      => 'db_first',
    },
    color_6 => {
        context => [qw(domain site)],
        order   => 120.16,
        group   => 'www_appearances',
        default => '#005ab2',           # list menu current button,
        db      => 'db_first',
    },
    color_7 => {
        context => [qw(domain site)],
        order   => 120.17,
        group   => 'www_appearances',
        default => '#ffffff',           # errorbackground color,
        db      => 'db_first',
    },
    color_8 => {
        context => [qw(domain site)],
        order   => 120.18,
        group   => 'www_appearances',
        default => '#f2f6f9',
        db      => 'db_first',
    },
    color_9 => {
        context => [qw(domain site)],
        order   => 120.19,
        group   => 'www_appearances',
        default => '#bfd2e1',
        db      => 'db_first',
    },
    color_10 => {
        context => [qw(domain site)],
        order   => 120.20,
        group   => 'www_appearances',
        default => '#983222',           # inactive button,
        db      => 'db_first',
    },
    color_11 => {
        context => [qw(domain site)],
        order   => 120.21,
        group   => 'www_appearances',
        default => '#66aaff',
        db      => 'db_first',
    },
    color_12 => {
        context => [qw(domain site)],
        order   => 120.22,
        group   => 'www_appearances',
        default => '#ffe7e7',
        db      => 'db_first',
    },
    color_13 => {
        context => [qw(domain site)],
        order   => 120.23,
        group   => 'www_appearances',
        default => '#f48a7b',           # input backgound  | transparent,
        db      => 'db_first',
    },
    color_14 => {
        context => [qw(domain site)],
        order   => 120.24,
        group   => 'www_appearances',
        default => '#ffff99',
        db      => 'db_first',
    },
    color_15 => {
        context => [qw(domain site)],
        order   => 120.25,
        group   => 'www_appearances',
        default => '#fe57a1',
        db      => 'db_first',
    },
    dark_color => {
        context    => [qw(domain site)],
        order      => 120.30,
        group      => 'www_appearances',
        gettext_id => 'Colors for web interface, obsoleted',
        default    => '#c0c0c0',                               # 'silver'
        db         => 'db_first',
    },
    light_color => {
        context => [qw(domain site)],
        order   => 120.31,
        group   => 'www_appearances',
        default => '#aaddff',
        db      => 'db_first',
    },
    text_color => {
        context => [qw(domain site)],
        order   => 120.32,
        group   => 'www_appearances',
        default => '#000000',
        db      => 'db_first',
    },
    bg_color => {
        context => [qw(domain site)],
        order   => 120.33,
        group   => 'www_appearances',
        default => '#ffffcc',
        db      => 'db_first',
    },
    error_color => {
        context => [qw(domain site)],
        order   => 120.34,
        group   => 'www_appearances',
        default => '#ff6666',
        db      => 'db_first',
    },
    selected_color => {
        context => [qw(domain site)],
        order   => 120.35,
        group   => 'www_appearances',
        default => '#c0c0c0',           # 'silver'
        db      => 'db_first',
    },
    shaded_color => {
        context => [qw(domain site)],
        order   => 120.36,
        group   => 'www_appearances',
        default => '#66cccc',
        db      => 'db_first',
    },
    default_home => {
        context    => [qw(domain site)],
        order      => 120.40,
        group      => 'www_appearances',
        default    => 'home',
        gettext_id => 'Type of main web page',
        gettext_comment =>
            '"lists" for the page of list of lists. "home" for home page.',
        file => 'wwsympa.conf',
    },
    archive_default_index => {
        context    => [qw(site)],
        order      => 120.41,
        group      => 'www_appearances',
        default    => 'thrd',
        gettext_id => 'Default index organization of web archive',
        gettext_comment =>
            "thrd: Threaded index.\nmail: Chronological index.",
        file => 'wwsympa.conf',
    },
    # { your_lists_size: not yet implemented. }
    review_page_size => {
        context    => [qw(domain site)],
        order      => 120.42,
        group      => 'www_appearances',
        gettext_id => 'Size of review page',
        gettext_comment =>
            'Default number of lines of the array displaying users in the review page',
        default => 25,
        file    => 'wwsympa.conf',
    },
    viewlogs_page_size => {
        context    => [qw(domain site)],
        order      => 120.43,
        group      => 'www_appearances',
        gettext_id => 'Size of viewlogs page',
        gettext_comment =>
            'Default number of lines of the array displaying the log entries in the logs page.',
        default => 25,
        file    => 'wwsympa.conf',
    },
    main_menu_custom_button_1_title => {
        context    => [qw(domain site)],
        order      => 120.51,
        group      => 'www_appearances',
        gettext_id => 'Custom menus',
        gettext_comment =>
            'You may modify the main menu content by editing the menu.tt2 file, but you can also edit these parameters in order to add up to 3 buttons. Each button is defined by a title (the text in the button), an URL and, optionally, a target.',
        sample => 'FAQ',
    },
    main_menu_custom_button_2_title => {
        context => [qw(domain site)],
        order   => 120.52,
        group   => 'www_appearances',
    },
    main_menu_custom_button_3_title => {
        context => [qw(domain site)],
        order   => 120.53,
        group   => 'www_appearances',
    },
    main_menu_custom_button_1_url => {
        context => [qw(domain site)],
        order   => 120.54,
        group   => 'www_appearances',
        sample  => 'http://www.renater.fr/faq/universalistes/index',
    },
    main_menu_custom_button_2_url => {
        context => [qw(domain site)],
        order   => 120.55,
        group   => 'www_appearances',
    },
    main_menu_custom_button_3_url => {
        context => [qw(domain site)],
        order   => 120.56,
        group   => 'www_appearances',
    },
    main_menu_custom_button_1_target => {
        context => [qw(domain site)],
        order   => 120.57,
        group   => 'www_appearances',
        sample  => 'Help',
    },
    main_menu_custom_button_2_target => {
        context => [qw(domain site)],
        order   => 120.58,
        group   => 'www_appearances',
    },
    main_menu_custom_button_3_target => {
        context => [qw(domain site)],
        order   => 120.59,
        group   => 'www_appearances',
    },

    # Web interface: Session and cookie:

    cookie_domain => {
        context    => [qw(domain site)],
        order      => 190.01,
        group      => 'www_other',
        default    => 'localhost',
        sample     => '.renater.fr',
        gettext_id => 'HTTP cookies validity domain',
        gettext_comment =>
            'If beginning with a dot ("."), the cookie is available within the specified Internet domain. Otherwise, for the specified host. The only reason for replacing the default value would be where WWSympa\'s authentication process is shared with an application running on another host.',
        file => 'wwsympa.conf',
    },
    cookie_expire => {
        context    => [qw(site)],
        order      => 190.02,
        group      => 'www_other',
        default    => '0',
        gettext_id => 'HTTP cookies lifetime',
        gettext_comment =>
            'This is the default value when not set explicitly by users. "0" means the cookie may be retained during browser sessions.',
        file => 'wwsympa.conf',
    },
    cookie_refresh => {
        context    => [qw(site)],
        order      => 190.03,
        group      => 'www_other',
        default    => '60',
        gettext_id => 'Average interval to refresh HTTP session ID.',
        file       => 'wwsympa.conf',
    },
    purge_session_table_task => {
        context    => [qw(site)],
        order      => 190.04,
        group      => 'www_other',
        gettext_id => 'Task for cleaning old sessions',
        gettext_comment =>
            'This task removes old entries in the "session_table" table.',
        default => 'daily',
        task    => 'purge_session_table',
    },
    session_table_ttl => {
        context    => [qw(site)],
        order      => 190.05,
        group      => 'www_other',
        gettext_id => 'Max age of sessions',
        gettext_comment =>
            "Session duration is controlled by \"sympa_session\" cookie validity attribute. However, by security reason, this delay also need to be controlled by server side. This task removes old entries in the \"session_table\" table.\nFormat of values is a string without spaces including \"y\" for years, \"m\" for months, \"d\" for days, \"h\" for hours, \"min\" for minutes and \"sec\" for seconds.",
        default => '2d',
    },
    anonymous_session_table_ttl => {
        context    => [qw(site)],
        order      => 190.06,
        group      => 'www_other',
        gettext_id => 'Max age of sessions for anonymous users',
        default    => '1h',
    },

    # Shared document repository

    shared_feature => {
        context    => [qw(domain site)],
        order      => 190.10,
        group      => 'www_other',
        format     => ['on', 'off'],                #XXX
        gettext_id => 'Enable shared repository',
        gettext_comment =>
            'If set to "on", list owners can open shared repository.',
        default => 'off',
    },
    #shared_doc

    # HTML editor

    htmlarea_url => {    # Deprecated on 6.2.36
        context    => [qw(site)],
        gettext_id => '',
        file       => 'wwsympa.conf',
        obsolete   => 1,
    },
    use_html_editor => {
        context    => [qw(domain site)],
        order      => 190.20,
        group      => 'www_other',
        gettext_id => 'Use HTML editor',
        gettext_comment =>
            'If set to "on", users will be able to post messages in HTML using a javascript WYSIWYG editor.',
        format  => ['off', 'on'],
        synonym => {'0' => 'off', '1' => 'on'},
        default => 'off',
        sample  => 'on',
        file    => 'wwsympa.conf',
    },
    html_editor_url => {
        context    => [qw(domain site)],
        order      => 190.21,
        group      => 'www_other',
        gettext_id => 'URL of HTML editor',
        gettext_comment =>
            "URL path to the javascript file making the WYSIWYG HTML editor available.  Relative path under <static_content_url> or absolute path.\nExample is for TinyMCE 4 installed under <static_content_path>/js/tinymce/.",
        sample => 'js/tinymce/tinymce.min.js',
    },
    html_editor_init => {
        context    => [qw(domain site)],
        order      => 190.22,
        group      => 'www_other',
        gettext_id => 'HTML editor initialization',
        gettext_comment =>
            'Javascript excerpt that enables and configures the WYSIWYG HTML editor.',
        sample =>
            'tinymce.init({selector:"#body",language:lang.split(/[^a-zA-Z]+/).join("_")});',
        file => 'wwsympa.conf',
    },
    ##{ html_editor_hide: not yet implemented. },
    ##{ html_editor_show: not yet implemented. },

    # Password

    max_wrong_password => {
        context    => [qw(domain site)],
        order      => 190.31,
        group      => 'www_other',
        gettext_id => 'Count limit of wrong password submission',
        gettext_comment =>
            'If this limit is reached, the account is locked until the user renews their password. The default value is chosen in order to block bots trying to log in using brute force strategy. This value should never be reached by real users that will probably uses the renew password service before they performs so many tries.',
        default => '19',
    },
    password_case => {
        context    => [qw(site)],        # per-robot config is impossible.
        order      => 190.32,
        group      => 'www_other',
        default    => 'insensitive',
        gettext_id => 'Password case',
        file       => 'wwsympa.conf',
        gettext_comment =>
            "\"insensitive\" or \"sensitive\".\nIf set to \"insensitive\", WWSympa's password check will be insensitive. This only concerns passwords stored in the Sympa database, not the ones in LDAP.\nShould not be changed! May invalid all user password.",
    },
    password_hash => {
        context => [qw(site)],           # per-robot config is impossible.
        order   => 190.33,
        group   => 'www_other',
        default => 'md5',
        gettext_id => 'Password hashing algorithm',
        file       => 'wwsympa.conf',
        gettext_comment =>
            "\"md5\" or \"bcrypt\".\nIf set to \"md5\", Sympa will use MD5 password hashes. If set to \"bcrypt\", bcrypt hashes will be used instead. This only concerns passwords stored in the Sympa database, not the ones in LDAP.\nShould not be changed! May invalid all user passwords.",
    },
    password_hash_update => {
        context => [qw(site)],           # per-robot config is impossible.
        order   => 190.34,
        group   => 'www_other',
        default => '1',
        gettext_id => 'Update password hashing algorithm when users log in',
        file       => 'wwsympa.conf',
        gettext_comment =>
            "On successful login, update the encrypted user password to use the algorithm specified by \"password_hash\". This allows for a graceful transition to a new password hash algorithm. A value of 0 disables updating of existing password hashes.  New and reset passwords will use the \"password_hash\" setting in all cases.",
    },
    bcrypt_cost => {
        context    => [qw(site)],           # per-robot config is impossible.
        order      => 190.35,
        group      => 'www_other',
        default    => '12',
        gettext_id => 'Bcrypt hash cost',
        file       => 'wwsympa.conf',
        gettext_comment =>
            "When \"password_hash\" is set to \"bcrypt\", this sets the \"cost\" parameter of the bcrypt hash function. The default of 12 is expected to require approximately 250ms to calculate the password hash on a 3.2GHz CPU. This only concerns passwords stored in the Sympa database, not the ones in LDAP.\nCan be changed but any new cost setting will only apply to new passwords.",
    },

    # One time ticket

    one_time_ticket_lifetime => {
        context         => [qw(site)],
        order           => 190.41,
        group           => 'www_other',
        default         => '2d',
        gettext_id      => 'Age of one time ticket',
        gettext_comment => 'Duration before the one time tickets are expired',
    },
    one_time_ticket_lockout => {
        context    => [qw(domain site)],
        order      => 190.42,
        group      => 'www_other',
        default    => 'one_time',
        gettext_id => 'Restrict access to one time ticket',
        gettext_comment =>
            'Is access to the one time ticket restricted, if any users previously accessed? (one_time | remote_addr | open)',
    },
    purge_one_time_ticket_table_task => {
        context    => [qw(site)],
        order      => 190.43,
        group      => 'www_other',
        gettext_id => 'Task for expiring old one time tickets',
        default    => 'daily',
        task       => 'purge_one_time_ticket_table',
    },
    one_time_ticket_table_ttl => {
        context    => [qw(site)],
        order      => 190.44,
        group      => 'www_other',
        gettext_id => 'Expiration period of one time ticket',
        default    => '10d',
    },

    # Pictures

    ##pictures_feature

    pictures_max_size => {
        context      => [qw(domain site)],
        order        => 190.51,
        group        => 'www_other',
        gettext_id   => 'The maximum size of uploaded picture',
        gettext_unit => 'bytes',
        default      => 102400,                                   # 100 kiB
    },

    # Protection against spam harvesters

    spam_protection => {
        context => [qw(list domain site)],
        order   => 190.61,
        group   => 'www_other',
        #gettext_id => "email address protection method",
        gettext_id => 'Protect web interface against spam harvesters',
        gettext_comment =>
            "There is a need to protect Sympa web sites against spambots which collect email addresses from public web sites. Various methods are available in Sympa and you can choose to use them with the spam_protection and web_archive_spam_protection parameters. Possible value are:\njavascript: \nthe address is hidden using a javascript. A user who enables javascript can see a nice mailto address where others have nothing.\nat: \nthe \@ char is replaced by the string \" AT \".\nnone: \nno protection against spammer.",
        #gettext_comment =>
        #    "These values are supported:\njavascript: the address is hidden using a javascript. Users who enable Javascript can see nice mailto addresses where others have nothing.\nat: the \"\@\" character is replaced by the string \"AT\".\nnone: no protection against spam harvesters.",
        format     => ['at', 'javascript', 'none'],
        occurrence => '1',
        default    => 'javascript'
    },
    ##web_archive_spam_protection
    reporting_spam_script_path => {
        context    => [qw(domain site)],
        order      => 190.62,
        group      => 'www_other',
        gettext_id => 'Script to report spam',
        gettext_comment =>
            'If set, when a list moderator report undetected spams for list moderation, this external script is invoked and the message is injected into standard input of the script.',
    },

    # Various miscellaneous

    domains_blocklist => {
        context => [qw(site)],
        order   => 190.71,
        group   => 'www_other',
        gettext_id =>
            'Prevent people to subscribe to a list with adresses using these domains',
        gettext_comment => 'This parameter is a comma-separated list.',
        sample          => 'example.org,spammer.com',
        split_char      => ',',
    },
    domains_blacklist => {obsolete => 'domains_blocklist'},

    quiet_subscription => {
        context    => [qw(site)],
        order      => 190.72,
        group      => 'www_other',
        gettext_id => 'Quiet subscriptions policy',
        gettext_comment =>
            'Global policy for quiet subscriptions: "on" means that subscriptions will never send a notice to the subscriber, "off" will enforce a notice sending, and "optional" (default) allows the use of the list policy.',
        format  => ['on', 'optional', 'off'],    #XXX
        default => 'optional',
    },

    show_report_abuse => {
        context => [qw(site)],
        order   => 190.73,
        group   => 'www_other',
        gettext_id =>
            'Add a "Report abuse" link in the side menu of the lists',
        gettext_comment =>
            'The link is a mailto link, you can change that by overriding web_tt2/report_abuse.tt2',
        format  => ['on', 'off'],
        synonym => {'1' => 'on', '0' => 'off'},
        default => 'off',
    },
    allow_account_deletion => {
        context => [qw(site)],
        order   => 190.74,
        group   => 'www_other',
        gettext_id =>
            'EXPERIMENTAL! Allow users to delete their account. If enabled, shows a "delete my account" form in user\'s preferences page.',
        gettext_comment =>
            'Account deletion unsubscribes the users from his/her lists and removes him/her from lists ownership. It is only available to users using internal authentication (i.e. no LDAP, no SSO...). See https://github.com/sympa-community/sympa/issues/300 for details',
        format  => ['on', 'off'],
        synonym => {'1' => 'on', '0' => 'off'},
        default => 'off',
    },

    # Web interface: Optional features

    password_validation => {
        context    => [qw(site)],
        order      => 153.01,
        group      => 'password_validation',
        gettext_id => 'Password validation',
        gettext_comment =>
            'The password validation techniques to be used against user passwords that are added to mailing lists. Options come from Data::Password (http://search.cpan.org/~razinf/Data-Password-1.07/Password.pm#VARIABLES)',
        sample =>
            'MINLEN=8,GROUPS=3,DICTIONARY=4,DICTIONARIES=/pentest/dictionaries',
    },

    ldap_force_canonical_email => {
        context    => [qw(domain site)],
        order      => 154.01,
        group      => 'ldap_auth',
        default    => '1',
        gettext_id => 'Use canonical email address for LDAP authentication',
        gettext_comment =>
            'When using LDAP authentication, if the identifier provided by the user was a valid email, if this parameter is set to false, then the provided email will be used to authenticate the user. Otherwise, use of the first email returned by the LDAP server will be used.',
        file => 'wwsympa.conf',
    },

    soap_url => {
        context    => [qw(domain site)],
        order      => 156.01,
        group      => 'sympasoap',
        sample     => 'http://web.example.org/sympasoap',
        gettext_id => 'URL of SympaSOAP',
        gettext_comment =>
            'WSDL document of SympaSOAP refers to this URL in its service section.',
    },
    soap_url_local => {
        context    => [qw(domain site)],
        order      => 156.02,
        group      => 'sympasoap',
        gettext_id => 'URL of SympaSOAP behind proxy',
    },

    #### End of living parameters ####

    ## Parameters which have not been implemented yet.
    #purge_challenge_table_task => {
    #    default => 'daily',
    #},
    #challenge_table_ttl => {
    #    default => '5d',
    #},

    #FIXME: Probablly not available now.
    automatic_list_prefix => {
        context => [qw(site)],
        gettext_id =>
            'Defines the prefix allowing to recognize that a list is an automatic list.',
        obsolete => 1,    # Maybe not used
    },
    default_distribution_ttl => {
        context => [qw(site)],
        gettext_id =>
            'Default timeout between two action-triggered synchronizations of list members with data sources.',
        default  => '300',
        obsolete => 1,       # Maybe not used
    },
    edit_list => {
        context  => [qw(site)],
        default  => 'owner',
        obsolete => 1,            # Maybe not used
    },

    ## Obsoleted parameters

    trusted_ca_options             => $site_obsolete,    # cf. capath & cafile
    msgcat                         => $site_obsolete,
    queueexpire                    => $site_obsolete,
    clean_delay_queueother         => $site_obsolete,
    web_recode_to                  => $site_obsolete,    # ??? - 5.2
    localedir                      => $site_obsolete,
    ldap_export_connection_timeout => $site_obsolete,    # 3.3b3 - 4.1?
    ldap_export_dnmanager          => $site_obsolete,    # ,,
    ldap_export_host               => $site_obsolete,    # ,,
    ldap_export_name               => $site_obsolete,    # ,,
    ldap_export_password           => $site_obsolete,    # ,,
    ldap_export_suffix             => $site_obsolete,    # ,,
    tri                            => $site_obsolete,    # ??? - 1.3.4-1
    sort                           => $site_obsolete,    # 1.4.0 - ???
    pidfile                        => $site_obsolete,    # ??? - 6.1.17
    pidfile_distribute             => $site_obsolete,    # ,,
    pidfile_creation               => $site_obsolete,    # ,,
    pidfile_bulk                   => $site_obsolete,    # ,,
    archived_pidfile               => $site_obsolete,    # ,,
    bounced_pidfile                => $site_obsolete,    # ,,
    task_manager_pidfile           => $site_obsolete,    # ,,
    email_gecos                    => $site_obsolete,    # 6.2a.?? - 6.2a.33
    lock_method                    => $site_obsolete,    # 5.3b.3 - 6.2a.33
    html_editor_file               => $site_obsolete,    # 6.2a
    openssl                        => $site_obsolete,    # ?? - 6.2a.40
    distribution_mode              => $site_obsolete,    # 5.0a.1 - 6.2a.40
    queuedistribute                => $site_obsolete,    # ,,

    log_condition => {
        context  => [qw(domain site)],
        file     => 'wwsympa.conf',
        obsolete => 1,                                   # 6.2a.29 - 6.2.41b.1
    },
    log_module => {
        context  => [qw(domain site)],
        file     => 'wwsympa.conf',
        obsolete => 1,                                   # 6.2a.29 - 6.2.41b.1
    },
    filesystem_encoding => {
        context  => [qw(site)],
        default  => 'utf-8',
        obsolete => 1,                                   # 5.3a.7 - 6.2.52
    },
    http_host => {
        context  => [qw(domain site)],
        obsolete => 1,                                   # ?? - 6.2.54
    },

);

our %user_info = (
    owner => {
        order      => 10.03,
        group      => 'description',
        gettext_id => "Owners",
        gettext_comment =>
            'Owners are managing subscribers of the list. They may review subscribers and add or delete email addresses from the mailing list. If you are a privileged owner of the list, you can choose other owners for the mailing list. Privileged owners may edit a few more options than other owners. ',
        format => {
            profile => {
                order      => 1,
                gettext_id => "profile",
                format     => ['privileged', 'normal'],
                occurrence => '1',
                default    => 'normal'
            },
            email => {
                order       => 2,
                gettext_id  => "email address",
                format_s    => '$email',
                occurrence  => '1',
                length      => 30,
                filters     => ['canonic_email'],
                validations => [
                    qw(list_address list_special_addresses unique_paragraph_key)
                ],
            },
            gecos => {
                order      => 3,
                gettext_id => "name",
                format     => '.+',
                length     => 30
            },
            reception => {
                order      => 4,
                gettext_id => "reception mode",
                format     => ['mail', 'nomail'],
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                order      => 5,
                gettext_id => "visibility",
                format     => ['conceal', 'noconceal'],
                occurrence => '1',
                default    => 'noconceal'
            },
            info => {
                order      => 6,
                gettext_id => "private information",
                format     => '.+',
                length     => 30
            },
            subscribed => {
                order      => 11,
                gettext_id => 'subscribed',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '1',
                internal   => 1,
            },
            included => {
                #order      => 12,
                obsolete   => 1,
                gettext_id => 'included',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '0',
                internal   => 1,
            },
            id => {
                #order      => 13,
                obsolete   => 1,
                gettext_id => 'name of external datasource',
                internal   => 1,
            },
            date => {
                order      => 14,
                gettext_id => 'delegated since',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            update_date => {
                order      => 14.5,
                gettext_id => 'last update time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion => {
                order      => 14.6,
                gettext_id => 'last inclusion time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion_ext => {
                order      => 14.7,
                gettext_id => 'last inclusion time from external data source',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
        },
        occurrence => '1-n'
    },

    editor => {
        order      => 10.05,
        group      => 'description',
        gettext_id => "Moderators",
        gettext_comment =>
            "Moderators are responsible for moderating messages. If the mailing list is moderated, messages posted to the list will first be passed to the moderators, who will decide whether to distribute or reject it.\nFYI: Defining moderators will not make the list moderated; you will have to set the \"send\" parameter.\nFYI: If the list is moderated, any moderator can distribute or reject a message without the knowledge or consent of the other moderators. Messages that have not been distributed or rejected will remain in the moderation spool until they are acted on.",
        format => {
            email => {
                order       => 1,
                gettext_id  => "email address",
                format_s    => '$email',
                occurrence  => '1',
                length      => 30,
                filters     => ['canonic_email'],
                validations => [
                    qw(list_address list_editor_address unique_paragraph_key)
                ],
            },
            gecos => {
                order      => 2,
                gettext_id => "name",
                format     => '.+',
                length     => 30
            },
            reception => {
                order      => 3,
                gettext_id => "reception mode",
                format     => ['mail', 'nomail'],
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                order      => 4,
                gettext_id => "visibility",
                format     => ['conceal', 'noconceal'],
                occurrence => '1',
                default    => 'noconceal'
            },
            info => {
                order      => 5,
                gettext_id => "private information",
                format     => '.+',
                length     => 30
            },
            subscribed => {
                order      => 11,
                gettext_id => 'subscribed',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '1',
                internal   => 1,
            },
            included => {
                #order      => 12,
                obsolete   => 1,
                gettext_id => 'included',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '0',
                internal   => 1,
            },
            id => {
                #order      => 13,
                obsolete   => 1,
                gettext_id => 'name of external datasource',
                internal   => 1,
            },
            date => {
                order      => 14,
                gettext_id => 'delegated since',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            update_date => {
                order      => 14.5,
                gettext_id => 'last update time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion => {
                order      => 14.6,
                gettext_id => 'last inclusion time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion_ext => {
                order      => 14.7,
                gettext_id => 'last inclusion time from external data source',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
        },
        occurrence => '0-n'
    },
);

our %obsolete_robot_params = (
    arc_private_key_path          => 'arc_parameters.arc_private_key_path',
    arc_selector                  => 'arc_parameters.arc_selector',
    arc_signer_domain             => 'arc_parameters.arc_signer_domain',
    archive_mail_access           => 'archive.mail_access',
    archive_web_access            => 'archive.web_access',
    bounce_halt_rate              => 'bounce.halt_rate',
    bounce_warn_rate              => 'bounce.warn_rate',
    d_edit                        => 'shared_doc.d_edit',
    d_read                        => 'shared_doc.d_read',
    default_archive_quota         => 'archive.quota',
    default_bounce_level1_rate    => 'bouncers_level1.rate',
    default_bounce_level2_rate    => 'bouncers_level2.rate',
    default_list_priority         => 'priority',
    default_max_list_members      => 'max_list_members',
    default_remind_task           => 'remind_task',
    default_shared_quota          => 'shared_doc.quota',
    default_sql_fetch_timeout     => 'sql_fetch_timeout',
    default_ttl                   => 'ttl',
    dkim_header_list              => 'dkim_parameters.header_list',
    dkim_private_key_path         => 'dkim_parameters.private_key_path',
    dkim_selector                 => 'dkim_parameters.selector',
    dkim_signer_domain            => 'dkim_parameters.signer_domain',
    dmarc_protection_domain_regex => 'dmarc_protection.domain_regex',
    dmarc_protection_mode         => 'dmarc_protection.mode',
    dmarc_protection_other_email  => 'dmarc_protection.other_email',
    dmarc_protection_phrase       => 'dmarc_protection.phrase',
    tracking                      => 'tracking.tracking',
    tracking_default_retention_period => 'tracking.retention_period',
    tracking_delivery_status_notification =>
        'tracking.delivery_status_notification',
    tracking_message_disposition_notification =>
        'tracking.message_disposition_notification',
);

_apply_defaults();

## Apply defaults to parameters definition (%pinfo)
sub _apply_defaults {
    foreach my $p (keys %pinfo) {
        cleanup($p, $pinfo{$p});
    }
    foreach my $p (keys %user_info) {
        cleanup($p, $user_info{$p});
    }
}

sub cleanup {
    my $p = shift;
    my $v = shift;

    ## Apply defaults to %pinfo
    foreach my $d (keys %default) {
        unless (defined $v->{$d}) {
            $v->{$d} = $default{$d};
        }
    }

    if (exists $v->{default_s}) {
        my $default = $v->{default_s};
        $default =~ s{\$(\w\w+)}{
            Sympa::Constants->can($1)->();
        }eg;
        $v->{default} = $default;
    }

    if (exists $v->{format_s}) {
        my $format = $v->{format_s};
        if ($format =~ /\A\$(\w+)\z/) {
            $format = Sympa::Regexps->can($1)->();
        } else {
            $format =~ s/\$(\w+)/Sympa::Regexps->can($1)->()/eg;
        }
        $v->{format} = $format;
    } elsif ($v->{'scenario'}) {
        # Scenario format
        $v->{'format'} = Sympa::Regexps::scenario_config();
        #XXX$v->{'default'} = 'default';
    } elsif ($v->{'task'}) {
        # Task format
        $v->{'format'} = Sympa::Regexps::task();
    } elsif ($v->{'datasource'}) {
        # Data source format
        $v->{'format'} = Sympa::Regexps::datasource();
    }

    ## Enumeration
    if (ref($v->{'format'}) eq 'ARRAY') {
        $v->{'file_format'} ||= join '|', @{$v->{'format'}},
            keys %{$v->{synonym} || {}};
    }

    ## Set 'format' as default for 'file_format'
    $v->{'file_format'} ||= $v->{'format'};

    if (    $v->{'occurrence'} =~ /n$/
        and $v->{'split_char'}
        and $v->{'format'}) {
        my $format = $v->{'file_format'};
        my $char   = $v->{'split_char'};
        $v->{'file_format'} = "($format)*(\\s*$char\\s*($format))*";
    }

    ref $v->{'format'} eq 'HASH' && ref $v->{'file_format'} eq 'HASH'
        or return;

    ## Parameter is a Paragraph)
    foreach my $k (keys %{$v->{'format'}}) {
        ## Defaults
        foreach my $d (keys %default) {
            unless (defined $v->{'format'}{$k}{$d}) {
                $v->{'format'}{$k}{$d} = $default{$d};
            }
        }

        if (ref $v->{'format'}{$k}) {
            if (exists $v->{'format'}{$k}{default_s}) {
                my $default = $v->{'format'}{$k}{default_s};
                $default =~ s{\$(\w\w+)}{
                    Sympa::Constants->can($1)->();
                }eg;
                $v->{'format'}{$k}{default} = $default;
            }

            if (exists $v->{'format'}{$k}{format_s}) {
                my $format = $v->{'format'}{$k}{format_s};
                if ($format =~ /\A\$(\w+)\z/) {
                    $format = Sympa::Regexps->can($1)->();
                } else {
                    $format =~ s/\$(\w+)/Sympa::Regexps->can($1)->()/eg;
                }
                $v->{'format'}{$k}{format} = $format;
            } elsif ($v->{'format'}{$k}{'scenario'}) {
                # Scenario format
                $v->{'format'}{$k}{'format'} =
                    Sympa::Regexps::scenario_config();
                #XXX$v->{'format'}{$k}{'default'} = 'default'
                #XXX    unless ($p eq 'web_archive' and $k eq 'access')
                #XXX    or ($p eq 'archive' and $k eq 'web_access');
            } elsif ($v->{'format'}{$k}{'task'}) {
                # Task format
                $v->{'format'}{$k}{'format'} = Sympa::Regexps::task();
            } elsif ($v->{'format'}{$k}{'datasource'}) {
                # Data source format
                $v->{'format'}{$k}{'format'} = Sympa::Regexps::datasource();
            }
        }

        ## Enumeration
        if (ref($v->{'format'}{$k}{'format'}) eq 'ARRAY') {
            $v->{'file_format'}{$k}{'file_format'} ||= join '|',
                @{$v->{'format'}{$k}{'format'}},
                keys %{$v->{'format'}{$k}{synonym} || {}};
        }

        next if $v->{format}{$k}{'obsolete'};

        #FIXME
        if (($v->{'file_format'}{$k}{'occurrence'} =~ /n$/)
            && $v->{'file_format'}{$k}{'split_char'}) {
            my $format = $v->{'file_format'}{$k}{'file_format'};
            my $char   = $v->{'file_format'}{$k}{'split_char'};
            $v->{'file_format'}{$k}{'file_format'} =
                "($format)*(\\s*$char\\s*($format))*";
        }

    }

    ref $v->{'file_format'} eq 'HASH'
        or return;

    foreach my $k (keys %{$v->{'file_format'}}) {
        ## Set 'format' as default for 'file_format'
        $v->{'file_format'}{$k}{'file_format'} ||=
            $v->{'file_format'}{$k}{'format'};
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ListDef - Definition of list configuration parameters

=head1 DESCRIPTION

This module keeps definition of configuration parameters for each list.

=head2 Global variable

=over

=item %alias

Deprecated by Sympa 6.2.16.

=item %pgroup

TBD.

=item %pinfo

This hash COMPLETELY defines ALL list parameters.
It is then used to load, save, view, edit list config files.

List parameters format accepts the following keywords :

=over

=item context

TBD.

Introduced on Sympa 6.2.57b.

=item format

Regexp applied to the configuration file entry.
Or arrayref containing all possible values of parameter.

Or, if the parameter is paragraph, value of this item is a hashref containing
definitions of sub-parameters.

See also L<Sympa::List::Config/"Node types">.

=item format_s

Template of regexp applied to the configuration file entry;
see also L</format>.

Subpatterns C<$word> indicate the name of pattern defined in
L<Sympa::Regexps>.

This was introduced on Sympa 6.2.19b.2.

=item file_format

Config file format of the parameter might not be
the same in memory.

=item split_char

Character used to separate multiple parameters.
Used with the set or the array of scalars.

=item length

Length of a scalar variable ; used in web forms.

=item scenario

Tells that the parameter is a scenario, providing its name.

=item default

Default value for the param ; may be a robot configuration
parameter (conf).

If occurrence is C<0-1> or C<0-n>,
default value will be assigned
only when list is created or new node is added to configuration.

=item default_s

Template of constant used as default value in configuration file entry;
see also L</default>.

Subpatterns C<$WORD> indicate the name of constant defined in
L<Sympa::Constants>.

=item synonym

Defines synonyms for parameter values (for compatibility
reasons).

=item gettext_unit

Unit of the parameter ; this is used in web forms and refers
to translated
strings in NLS catalogs.

=item occurrence

Occurrence of the parameter in the config file
possible values: C<0-1>, C<1>, C<0-n> and C<1-n>.
Example: A list may have multiple owner.

See also L<Sympa::List::Config/"Node types">.

=item gettext_id

Title reference in NLS catalogs.

=item gettext_comment

Description text of a parameter.

=item group

Group of parameters.

=item obsolete

Obsolete parameter ; should not be displayed
nor saved.

As of 6.2.16, if the value is true value and is not C<1>,
defines parameter alias name mainly for backward compatibility.

=item obsolete_values

B<Deprecated>.

Defined obsolete values for a parameter.
These values should not get proposed on the web interface
edition form.

=item order

Order of parameters within paragraph.

=item internal

Indicates that the parameter is an internal parameter
that should always be saved in the config file.

=item field_type

Used to special treatment of parameter value to show it.

=over

=item C<'dayofweek'>

Day of week, C<0> - C<6>.

=item C<'lang'>

Language tag.

=item C<'password'>

The value to be concealed.

=item C<'reception'>

Reception mode of list member.

=item C<'status'>

Status of list.

=item C<'listtopic'>

List topic.

=item C<'unixtime'>

The time in second from Unix epoch.

=item C<'visibility'>

Visibility mode of list member.

=back

Most of field types were introduced on Sympa 6.2.17.

=item filters

See L<Sympa::List::Config/"Filters">.

Introduced on Sympa 6.2.17.

=item validations

See L<Sympa::List::Config/"Validations">.

Introduced on Sympa 6.2.17.

=item privilege

I<Dynamically assigned>.
Privilege for specified user:
C<'write'>, C<'read'> or C<'hidden'>.

Introduced on Sympa 6.2.17.

=item enum

I<Automatically assigned>.
TBD.

Introduced on Sympa 6.2.17.

=item file

Conf file where the parameter is defined.
"wwsympa.conf" is a synonym of "sympa.conf".
It remains there in order to migrating older versions of config.

=item db

'db_first', 'file_first' or 'no'.
TBD.

=back

=item %user_info

TBD.

=back

=head1 SEE ALSO

L<list_config(5)>,
L<Sympa::List::Config>,
L<Sympa::ListOpt>.

L<sympa.conf(5)>, L<robot.conf(5)>.

=head1 HISTORY

L<Sympa::ListDef> was separated from L<List> module on Sympa 6.2.
On Sympa 6.2.57b, its content was moved to L<Sympa::Config::Schema>.

L<confdef> was separated from L<Conf> on Sympa 6.0a,
and renamed to L<Sympa::ConfDef> on 6.2a.39.
On Sympa 6.2.57b, its content was moved to L<Sympa::Config::Schema>.

Descriptions of parameters in this source file were partially taken from
chapters "sympa.conf parameters" in
I<Sympa, Mailing List Management Software - Reference manual>, written by
Serge Aumont, Stefan Hornburg, Soji Ikeda, Olivier SalaE<252>n and
David Verdin.

=cut
