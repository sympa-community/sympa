# Conf.pm - This module does the sympa.conf and robot.conf parsing
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

## This module handles the configuration file for Sympa.

package Conf;

use strict "vars";

use List;
use Log;
use Language;
use wwslib;
use CAS;

require Exporter;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT = qw(%Conf DAEMON_MESSAGE DAEMON_COMMAND DAEMON_CREATION DAEMON_ALL);

require 'tools.pl';

sub DAEMON_MESSAGE {1};
sub DAEMON_COMMAND {2};
sub DAEMON_CREATION {4};
sub DAEMON_ALL {7};

## Database and SQL statement handlers
my ($dbh, $sth, $db_connected, @sth_stack, $use_db);

## This defines the parameters to be edited :
##   title  : Title for the group of parameters following
##   name   : Name of the parameter
##   default: Default value
##   query  : Description of the parameter
##   file   : Conf file where the param. is defined
##   vhost   : 1|0 : if 1, the parameter can have a specific value in a virtual host
##   db   : 'db_first','file_first','no'
##   edit   : 1|0
##   advice : Additionnal advice concerning the parameter

our @params = (
    { title => 'Directories and file location' },
    {
        name    => 'home',
        default => '--expldir--',
        query   => 'Directory containing mailing lists subdirectories',
        file    => 'sympa.conf',
        edit    => '1',
    },
    {
        name    => 'etc',
        default => '--sysconfdir--',
        query   => 'Directory for configuration files ; it also contains scenari/ and templates/ directories',
        file    => 'sympa.conf'
    },
    {
        name    => 'pidfile',
        default => '--piddir--/sympa.pid',
        query   => 'File containing Sympa PID while running.',
        file    => 'sympa.conf',
        advice  => 'Sympa also locks this file to ensure that it is not running more than once. Caution : user sympa need to write access without special privilegee.'
    },
    { 
        name    => 'pidfile_distribute',
        default => '--piddir--/sympa-distribute.pid',
    },
    { 
        name    => 'pidfile_creation',
        default => '--piddir--/sympa-creation.pid',
    },
    { 
        name    => 'pidfile_bulk',
        default => '--piddir--/bulk.pid',
    },
    {
        name   => 'archived_pidfile',
        default => '--piddir--/archived.pid',
        query  => 'File containing archived PID while running.',
        file   => 'wwsympa.conf',
    },
    {
        name   => 'bounced_pidfile',
        default => '--piddir--/bounced.pid',
        query  => 'File containing bounced PID while running.',
        file   => 'wwsympa.conf',
    },
    {
        name  => 'task_manager_pidfile',
        default => '--piddir--/task_manager.pid',
        query => 'File containing task_manager PID while running.',
        file  => 'wwsympa.conf'
    },
    {
        name    => 'umask',
        default => '027',
        query   => 'Umask used for file creation by Sympa',
        file    => 'sympa.conf'
    },
    {
        name    => 'arc_path',
        default => '--prefix--/arc',
        query   => 'Where to store HTML archives',
        file    => 'wwsympa.conf',edit => '1',
        advice  =>'Better if not in a critical partition'
    },
    {
        name    => 'bounce_path',
        default => '--prefix--/bounce',
        query   => 'Where to store bounces',
        file    => 'wwsympa.conf',
        advice  => 'Better if not in a critical partition'
    },
    {
        name    => 'localedir',
        default => '--localedir--',
        query   => 'Directory containing available NLS catalogues (Message internationalization)',
        file    => 'sympa.conf',
    },
    {
        name    => 'spool',
        default => '--spooldir--',
        query   => 'The main spool containing various specialized spools',
        file    => 'sympa.conf',
        advice => 'All spool are created at runtime by sympa.pl'
    },
    {
        name    => 'queue',
        default => '--spooldir--/msg',
        query   => 'Incoming spool',
        file    => 'sympa.conf',
    },
    {
        name    => 'queuebounce',
        default => '--spooldir--/bounce',
        query   => 'Bounce incoming spool',
        file    => 'sympa.conf',
    },
    {
        name    => 'queuedistribute',
        default => 'undef,'
    },
    {
        name    => 'queueautomatic',
        default => 'undef,'
    },
    {
        name    => 'queuedigest',
        default => 'undef,'
    },
    {
        name    => 'queuemod',
        default => 'undef,'
    },
    {
        name    => 'queuetopic',
        default => 'undef,'
    },
    {
        name    => 'queueauth',
        default => 'undef,'
    },
    {
        name    => 'queueoutgoing',
        default => 'undef,'
    },
    {
        name    => 'queuetask',
        default => 'undef,'
    },
    {
        name    => 'queuesubscribe',
        default => 'undef,'
    },
    {
        name    => 'static_content_path',
        default => '--prefix--/static_content',
        query   => 'The directory where Sympa stores static contents (CSS, members pictures, documentation) directly delivered by Apache',
	vhost   => '1',
        file    => 'sympa.conf',
    },	      
    {
        name    => 'static_content_url',
        default => '--prefix--/static-sympa',
        query   => 'The URL mapped with the static_content_path directory defined above',
	vhost   => '1',
        file    => 'sympa.conf',
    },	      
    { title => 'Syslog' },
    {
        name    => 'syslog',
        default => 'LOCAL1',
        query   => 'The syslog facility for sympa',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Do not forget to edit syslog.conf'
    },
    {
        name    => 'log_socket_type',
        default => 'unix',
        query   => 'Communication mode with syslogd is either unix (via Unix sockets) or inet (use of UDP)',
        file    => 'sympa.conf'
    },
    {
        name   => 'log_facility',
        default => 'MAIL',
        query  => 'The syslog facility for wwsympa, archived and bounced',
        file   => 'wwsympa.conf',
        edit   => '1',
        advice => 'default is to use previously defined sympa log facility'
    },
    {
        name    => 'log_level',
        default => '0',
        query   => 'Log intensity',
	vhost   => '1',
        file    => 'sympa.conf',
        advice  => '0 : normal, 2,3,4 for debug'
    },
    { 
        name    => 'log_smtp',
        default => 'off',
	vhost   => '1',
    },
    { 
        name    => 'log_module',
        default => '',
	vhost   => '1',
    },
    { 
        name    => 'log_condition',
        default => '',
	vhost   => '1',
    },
    { 
        name    => 'logs_expiration_period',
        query   => 'Number of months that elapse before a log is expired.',
        default => '3',
    },
    { title => 'General definition' },
    {
        name    => 'domain',
        default => 'domain.tld',
        query   => 'Main robot hostname',
        file    => 'sympa.conf',
    },
    {
        name    => 'listmaster',
        default => 'your_email_address@domain.tld',
        query   => 'Listmasters email list comma separated',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Sympa will associate listmaster privileges to these email addresses (mail and web interfaces). Some error reports may also be sent to these addresses.'
    },
    {
        name    => 'email',
        default => 'sympa',
        query   => 'Local part of sympa email adresse',
	vhost   => '1',
        file    => 'sympa.conf',
        advice  => 'Effective address will be \[EMAIL\]@\[HOST\]'
    },
    {
        name    => 'create_list',
        default => 'public_listmaster',
        query   => 'Who is able to create lists',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'This parameter is a scenario, check sympa documentation about scenarios if you want to define one'
    },
    {
        name    => 'edit_list',
        default => 'owner'
    },
    { title => 'Tuning' },
    {
        name    => 'cache_list_config',
        default => 'none',
        query   => 'Use of binary version of the list config structure on disk: none | binary_file',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Set this parameter to "binary_file" if you manage a big amount of lists (1000+) ; it should make the web interface startup faster'
    },
    {
        name  => 'sympa_priority',
        query => 'Sympa commands priority',
        file  => 'sympa.conf',
        default => '1'
    },
    {
        name  => 'default_list_priority',
        query => 'Default priority for list messages',
        file  => 'sympa.conf',
        default => '5'
    },
    {
        name  => 'sympa_packet_priority',
        query => 'Default priority for a packet to be sent by bulk.',
        file  => 'sympa.conf',
        default => '5'
    },
    {
        name    => 'request_priority',
        default => '0'
    },
    {
        name    => 'owner_priority',
        default => '9'
    },
    {
        name    => 'bulk_fork_threshold',
        default => '1',
        query   => 'The minimum number of packets in database before the bulk forks to increase sending rate',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => ''
    },
    {
        name    => 'bulk_max_count',
        default => '3',
        query   => 'The max number of bulks that will run on the same server.',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => ''
    },
    {
        name    => 'bulk_lazytime',
        default => '600',
        query   => 'the number of seconds a slave bulk will remain running without processing a message before it spontaneously dies.',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => ''
    },
    {
        name    => 'bulk_wait_to_fork',
        default => '10',
        query   => 'The number of seconds a master bulk waits between two packets number checks.',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Keep it small if you expect brutal increases in the message sending load.'
    },
    {
        name    => 'bulk_sleep',
        default => '1',
        query   => 'the number of seconds a bulk sleeps between starting a new loop if it didn\'t find a message to send.',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Keep it small if you want your server to be reactive.'
    },
    {
        name    => 'cookie',
        sample  => '123456789',
        query   => 'Secret used by Sympa to make MD5 fingerprint in web cookies secure',
        file   => 'sympa.conf',
        advice => 'Should not be changed ! May invalid all user password',
        optional => '1'
    },
    {
        name    => 'cookie_cas_expire',
        default => '6'
    },
    {
        name   => 'legacy_character_support_feature',
        default => '',
        query  => 'If set to "on", enables support of legacy characters',
        file   => 'sympa.conf',
        advice => ''
    },
    {
        name   => 'password_case',
        default => 'insensitive',
        query  => 'Password case (insensitive | sensitive)',
        file   => 'wwsympa.conf',
        advice => 'Should not be changed ! May invalid all user password'
    },
    {
        name  => 'cookie_expire',
        default => '0',
        query => 'HTTP cookies lifetime',
        file  => 'wwsympa.conf',
    },
    {
        name  => 'cookie_domain',
        default => 'localhost',
        query => 'HTTP cookies validity domain',
	vhost   => '1',
        file  => 'wwsympa.conf',
    },
    {
        name  => 'max_size',
        query => 'The default maximum size (in bytes) for messages (can be re-defined for each list)',
        default => '5242880',
	vhost   => '1',
        file  => 'sympa.conf',
        edit  => '1',
    },
    {
        name    => 'use_blacklist',
        query   => 'comma separated list of operations for which blacklist filter is applied', 
        default => 'send,create_list',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Setting this parameter to "none" will hide the blacklist feature'
    },
    {
        name    => 'rfc2369_header_fields',
        query   => 'Specify which rfc2369 mailing list headers to add',
        default => 'help,subscribe,unsubscribe,post,owner,archive',
        file    => 'sympa.conf'
    },
    {
        name   => 'remove_headers',
        query  => 'Specify header fields to be removed before message distribution',
        default => 'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To',
        file    => 'sympa.conf',
    },
    {
        name    => 'automatic_list_feature',
        default => 'off'
	vhost   => '1',
    },
    {
        name    => 'automatic_list_creation',
        default => 'public'
	vhost   => '1',
    },
    {
        name    => 'automatic_list_removal',
        default => '' ## Can be 'if_empty'
	vhost   => '1',
    },
    {
        name    => 'global_remind',
        default => 'listmaster'
    },
    {
        name    => 'bounce_warn_rate',
        default => '30'
    },
    {
        name    => 'bounce_halt_rate',
        default => '50'
    },
    {
        name    => 'bounce_email_prefix',
        default => 'bounce'
    },
    {
        name    => 'loop_command_max',
        default => '200'
    },
    {
        name    => 'loop_command_sampling_delay',
        default => '3600'
    },
    {
        name    => 'loop_command_decrease_factor',
        default => '0.5'
    },
    {
        name    => 'loop_prevention_regex',
        default => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
	vhost   => '1',
    },
    { title => 'Internationalization' },
    {
        name    => 'lang',
        default => 'en_US',
        query   => 'Default lang (ca | cs | de | el | es | et_EE | en_US | fr | fi | hu | it | ja_JP | ko | nl | nb_NO | oc | pl | pt_BR | ru | sv | tr | vi | zh_CN | zh_TW)',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  =>'This is the default language used by Sympa'
    },
    {
        name    => 'supported_lang',
        default => 'ca,cs,de,el,es,et_EE,en_US,fr,fi,hu,it,ja_JP,ko,nl,nb_NO,oc,pl,pt_BR,ru,sv,tr,vi,zh_CN,zh_TW',
        query   => 'Supported languages',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'This is the set of language that will be proposed to your users for the Sympa GUI. Don\'t select a language if you don\'t have the proper locale packages installed.'
    },
    { title => 'Errors management' },
    {
        name   => 'bounce_warn_rate',
        sample => '20',
        query  => 'Bouncing email rate for warn list owner',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name   => 'bounce_halt_rate',
        sample => '50',
        query  => 'Bouncing email rate for halt the list (not implemented)',
        file   => 'sympa.conf',
        advice => 'Not yet used in current version, Default is 50' 
    },
    {
        name   => 'expire_bounce_task',
        sample => 'daily',
        query  => 'Task name for expiration of old bounces',
        file   => 'sympa.conf',
    },
    {
        name   => 'welcome_return_path',
        sample => 'unique',
        query  => 'Welcome message return-path',
        file   => 'sympa.conf',
        advice => 'If set to unique, new subcriber is removed if welcome message bounce'
    },
    {
        name   => 'remind_return_path',
        query  => 'Remind message return-path',
        file   => 'sympa.conf',
        advice => 'If set to unique, subcriber is removed if remind message bounce, use with care'
    },
    { title => 'MTA related' },
    {
        name    => 'sendmail',
        default => '/usr/sbin/sendmail',
        query   => 'Path to the MTA (sendmail, postfix, exim or qmail)',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'should point to a sendmail-compatible binary (eg: a binary named "sendmail" is distributed with Postfix)'
    },
    {
        name => 'sendmail_args',
        default => '-oi -odi -oem'
    },
    {
        name => 'sendmail_aliases',
        default => '--SENDMAIL_ALIASES--'
    },
    {
        name    => 'nrcpt',
        default => '25',
        query   => 'Maximum number of recipients per call to Sendmail. The nrcpt_by_domain.conf file allows a different tuning per destination domain.',
        file    => 'sympa.conf',
    },
    {
        name    => 'avg',
        default => '10',
        query   => 'Max. number of different domains per call to Sendmail',
        file    => 'sympa.conf',
    },
    {
        name    => 'maxsmtp',
        default => '40',
        query   => 'Max. number of Sendmail processes (launched by Sympa) running simultaneously',
        file    => 'sympa.conf',
        advice  => 'Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.'
    },
    { title => 'Plugin' },
    {
        name   => 'antivirus_path',
        optional => '1',
        sample => '/usr/local/uvscan/uvscan',
        query  => 'Path to the antivirus scanner engine',
        file   => 'sympa.conf',
        edit   => '1',
        advice => 'supported antivirus : McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall'
    },
    {
        name   => 'antivirus_args',
        optional => '1',
        sample => '--secure --summary --dat /usr/local/uvscan',
        query  => 'Antivirus pluggin command argument',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name    => 'antivirus_notify',
        default => 'sender'
    },
    {
        name    => 'mhonarc',
        default => '/usr/bin/mhonarc',
        query   => 'Path to MhOnarc mail2html pluggin',
        file    => 'wwsympa.conf',
        edit    => '1',
        advice  =>'This is required for HTML mail archiving'
    },
    { 'title' => 'S/MIME pluggin' },
    {
        name   => 'openssl',
        sample => '/usr/bin/ssl',
        query  => 'Path to OpenSSL',
        file   => 'sympa.conf',
        edit   => '1',
        advice => 'Sympa knowns S/MIME if openssl is installed',
	optional => '1'
    },
    {
        name   => 'capath',
        optional => '1',
        sample => '--sysconfdir--/ssl.crt',
        query  => 'The directory path use by OpenSSL for trusted CA certificates',
        file   => 'sympa.conf',
        edit   => '1'
    },
    {
        name   => 'cafile',
        sample => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
        query  => ' This parameter sets the all-in-one file where you can assemble the Certificates of Certification Authorities (CA)',
        file   => 'sympa.conf',
        edit   => '1'
    },
    {
        name    => 'ssl_cert_dir',
        default => '--expldir--/X509-user-certs',
        query   => 'User CERTs directory',
        file    => 'sympa.conf'
    },
    {
        name    => 'crl_dir',
        default => '--expldir--/crl',
        file    => 'sympa.conf'
    },
    {
        name   => 'key_passwd',
        sample => 'your_password',
        query  => 'Password used to crypt lists private keys',
        file   => 'sympa.conf',
        edit   => '1',
        optional   => '1',
    },
    {
        name    => 'chk_cert_expiration_task',
        default => ''
    },
    {
        name    => 'crl_update_task',
        default => ''
    },
    {
        name    => 'ldap_export_name',
        default => ''
    },
    {
        name    => 'ldap_export_host',
        default => ''
    },
    {
        name    => 'ldap_export_suffix',
        default => ''
    },
    {
        name    => 'ldap_export_password',
        default => ''
    },
    {
        name    => 'ldap_export_dnmanager',
        default => ''
    },
    {
        name    => 'ldap_export_connection_timeout',
        default => ''
    },
    { title => 'Database' },
    {
        name    => 'db_type',
        default => 'mysql',
        query   => 'Database type (mysql | Pg | Oracle | Sybase | SQLite)',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'be carefull to the case'
    },
    {
        name    => 'db_name',
        default => 'sympa',
        query   => 'Name of the database',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'with SQLite, the name of the DB corresponds to the DB file'
    },
    {
        name   => 'db_host',
        default => 'localhost',
        sample => 'localhost',
        query  => 'The host hosting your sympa database',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name   => 'db_port',
        default => '3306',
        query  => 'The database port',
        file   => 'sympa.conf',
    },
    {
        name   => 'db_user',
        default => 'user_name',
        sample => 'sympa',
        query  => 'Database user for connexion',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name   => 'db_passwd',
        default => 'user_password',
        sample => 'your_passwd',
        query  => 'Database password (associated to the db_user)',
        file   => 'sympa.conf',
        edit   => '1',
        advice => 'What ever you use a password or not, you must protect the SQL server (is it a not a public internet service ?)'
    },
    {
        name   => 'db_env',
        query  => 'Environment variables setting for database',
        file   => 'sympa.conf',
        advice => 'This is usefull for definign ORACLE_HOME ',
        optional => '1',
    },
    {
        name   => 'db_additional_user_fields',
        sample => 'age,address',
        query  => 'Database private extention to user table',
        file   => 'sympa.conf',
        advice => 'You need to extend the database format with these fields',
        optional => '1',
    },
    {
        name   => 'db_additional_subscriber_fields',
        sample => 'billing_delay,subscription_expiration',
        query  => 'Database private extention to subscriber table',
        file   => 'sympa.conf',
        advice => 'You need to extend the database format with these fields',
        optional => '1',
    },
    {
        name    => 'db_options',
        optional => '1',
    },
    {
        name    => 'db_timeout',
        optional => '1',
    },
    { title => 'Web interface' },
    {
        name    => 'use_fast_cgi',
        default => '1',
        query   => 'Is fast_cgi module for Apache (or Roxen) installed (0 | 1)',
        file    => 'wwsympa.conf',
        edit    => '1',
        advice  => 'This module provide much faster web interface'
    },
    {
        name    => 'wwsympa_url',
        default => 'http://host.domain.tld/sympa',
        query   => "Sympa\'s main page URL",
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
    },
    {
        name    => 'title',
        default => 'Mailing lists service',
        query   => 'Title of main web page',
	vhost   => '1',
        file    => 'wwsympa.conf',
        edit    => '1',
    },
    {
        name   => 'default_home',
        default => 'home',
        query  => 'Main page type (lists | home)',
	vhost   => '1',
        file   => 'wwsympa.conf',
        edit   => '1',
    },
    {
        name  => 'default_shared_quota',
        query => 'Default disk quota for shared repository',
	vhost   => '1',
        file  => 'sympa.conf',
        edit  => '1',
    },
    {
        name    => 'antispam_feature',
        default => 'off',
	vhost   => '1',
    },
    {
        name  => 'antispam_tag_header_name',
        default => 'X-Spam-Status',
        query => 'If a spam filter (like spamassassin or j-chkmail) add a smtp headers to tag spams, name of this header (example X-Spam-Status)',
	vhost   => '1',
        file  => 'sympa.conf',
        edit  => '1',
    },
    {
        name   => 'antispam_tag_header_spam_regexp',
        default => '^\s*Yes',
        query  => 'The regexp applied on this header to verify message is a spam (example \s*Yes)',
	vhost   => '1',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name  => 'antispam_tag_header_ham_regexp',
        default => '^\s*No',
        query => 'The regexp applied on this header to verify message is NOT a spam (example \s*No)',
	vhost   => '1',
        file  => 'sympa.conf',
        edit  => '1',
    },
    {
        name    => 'allow_subscribe_if_pending',
        default => 'on',
	vhost   => '1',
    },
    {
        name    => 'host',
        default => undef,
	vhost   => '1',
    },
    {
        name    => 'sort',
        default => 'fr,ca,be,ch,uk,edu,*,com'
    },
    {
        name    => 'tmpdir',
        default => 'undef,     '
    },
    {
        name    => 'sleep',
        default => '5,'
    },
    {
        name    => 'clean_delay_queue',
        default => '1,'
    },
    {
        name    => 'clean_delay_queuemod',
        default => '10,'
    },
    {
        name    => 'clean_delay_queuetopic',
        default => '7,'
    },
    {
        name    => 'clean_delay_queuesubscribe',
        default => '10,'
    },
    {
        name    => 'clean_delay_queueautomatic',
        default => '10,'
    },
    {
        name    => 'clean_delay_queueauth',
        default => '3,'
    },
    {
        name    => 'clean_delay_queuebounce',
        default => '10,'
    },
    {
        name    => 'clean_delay_queueoutgoing',
        default => '1,'
    },
    {
        name    => 'clean_delay_tmpdir',
        default => '7,'
    },
    {
        name    => 'remind_return_path',
        default => 'owner'
    },
    {
        name    => 'welcome_return_path',
        default => 'owner'
    },
    {
        name    => 'distribution_mode',
        default => 'single'
    },
    {
        name    => 'listmaster_email',
        default => 'listmaster'
	vhost   => '1',
    },
    {
        name    => 'misaddressed_commands',
        default => 'reject'
    },
    {
        name    => 'misaddressed_commands_regexp',
        default => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))'
    },
    {
        name    => 'remove_outgoing_headers',
        default => 'none'
    },
    {
        name    => 'anonymous_header_fields',
        default => 'Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender'
    },
    {
        name => 'dark_color',
        default => 'silver',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'light_color',
        default => '#aaddff',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'text_color',
        default => '#000000',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'bg_color',
        default => '#ffffcc',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'error_color',
        default => '#ff6666',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'selected_color',
        default => 'silver',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'shaded_color',
        default => '#66cccc',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_0',
        default => '#F0F0F0', # very light grey use in tables
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_1',
        default => '#999', # main menu button color
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_2',
        default => '#333',  # font color
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_3',
        default => '#929292', # top boxe and footer box bacground color
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_4',
        default => 'silver', #  page backgound color
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_5',
        default => '#fff',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name => 'color_6',
        default => '#99ccff', # list menu current button
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_7',
        default => '#ff99cc', # errorbackground color
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_8',
        default => '#3366CC',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name => 'color_9',
        default => '#DEE7F7',
	vhost   => '1',
	db      => 'db_first',
    },
     {
        name    => 'color_10',
        default => '#777777', # inactive button
	vhost   => '1',
	db      => 'db_first',
    },
     {
        name    => 'color_11',
        default => '#3366CC',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_12',
        default => '#000',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_13',
        default => '#ffffcc',  # input backgound  | transparent
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_14',
        default => '#000',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_15',
        default => '#000',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'list_check_smtp',
        default => ''
	vhost   => '1',
    },
    {
        name    => 'list_check_suffixes',
        default => 'request,owner,editor,unsubscribe,subscribe'
	vhost   => '1',
    },
    {
        name    => 'expire_bounce_task',
        default => 'daily'
    },
    {
        name    => 'purge_user_table_task',
        default => 'monthly'
    },
    {
        name => 'purge_logs_table_task',
        default => 'daily'
    },
    {
        name => 'purge_tables_task',
        default => 'daily'
    },
    {
        name => 'logs_expiration_period',
        default => 3
    },
    {
        name    => 'purge_session_table_task',
        default => 'daily'
    },
    {
        name    => 'session_table_ttl',
        default => '2d'
    },
    {
        name    => 'purge_one_time_ticket_table_task',
        default => 'daily'
    },
    {
        name    => 'one_time_ticket_table_ttl',
        default => '10d'
    },
    {
        name    => 'anonymous_session_table_ttl',
        default => '1h'
    },
    {
        name    => 'purge_challenge_table_task',
        default => 'daily'
    },
    {
        name => 'challenge_table_ttl',
        default => '5d'
    },
    {
        name    => 'purge_orphan_bounces_task',
        default => 'monthly'
    },
    {
        name    => 'eval_bouncers_task',
        default => 'daily'
    },
    {
        name    => 'process_bouncers_task',
        default => 'weekly'
    },
    {
        name    => 'default_archive_quota',
        default => '',
    },
    {
        name    => 'default_shared_quota',
        default => '',
    },
    {
        name    => 'spam_protection',
        default => 'javascript'
	vhost   => '1',
    },
    {
        name    => 'web_archive_spam_protection',
        default => 'cookie'
	vhost   => '1',
    },
    {
        name    => 'minimum_bouncing_count',
        default => '10'
    },
    {
        name    => 'minimum_bouncing_period',
        default => '10'
    },
    {
        name    => 'bounce_delay',
        default => '0'
    },
    {
        name    => 'default_bounce_level1_rate',
        default => '45'
	vhost   => '1',
    },
    {
        name    => 'default_bounce_level2_rate',
        default => '75'
	vhost   => '1',
    },
    {
        name    => 'soap_url',
        default => ''
	vhost   => '1',
    },
    {
        name    => 'css_url',
        default => ''
	vhost   => '1',
    },
    {
        name    => 'css_path',
        default => ''
	vhost   => '1',
    },
    {
        name    => 'urlize_min_size',
        default => 10240, ## 10Kb
    },
    {
        name    => 'default_remind_task',
        default => ''
    },
    {
        name    => 'update_db_field_types',
        default => 'auto'
    },
    {
        name => 'logo_html_definition',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_1_title',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_1_url',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_1_target',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_2_title',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_2_url',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_2_target',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_3_title',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_3_url',
        default => '',
	vhost   => '1',
    },
    {
        name => 'main_menu_custom_button_3_target',
        default => '',
	vhost   => '1',
    },
    {
        name    => 'return_path_suffix',
        default => '-owner'
    },
    {
        name    => 'verp_rate',
        default => '0%',
	vhost   => '1',
    }, 
    {
        name    => 'pictures_max_size',
        default => 102400, ## 100Kb
	vhost   => '1',
    },
    {
        name    => 'pictures_feature',
        default => 'on'
    },
    {
        name    => 'use_blacklist',
        default => 'send,subscribe'
    },
    {
        name    => 'static_content_url',
        default => '/static-sympa'
    },
    {
        name    => 'static_content_path',
        default => '--prefix--/static_content'
    },
    {
        name    => 'filesystem_encoding',
        default => 'utf-8'
    },
    {
        name    => 'cache_list_config',
        default => 'none',
        advice  => 'none | binary_file'
    },
    {
        name    => 'lock_method',
        default => 'flock',
        advice  => 'flock | nfs'
    },
    {
        name    => 'ignore_x_no_archive_header_feature',
        default => 'off'
    },
    {
        name    => 'alias_manager',
        default => '--sbindir--/alias_manager.pl'
    },
);

# parameters hash, keyed by parameter name
my %params =
    map  { $_->{name} => $_ }
    grep { $_->{name} }
    @params;

# valid virtual host parameters, keyed by parameter name
my %valid_robot_key_words;
foreach my $hash(@params){
    $valid_robot_key_words{$hash->{'name'}} = 1 if ($hash->{'vhost'});
    $valid_robot_key_words{$hash->{'name'}} = 'db' if (defined($hash->{'db'}) and $hash->{'db'} ne 'none');
}

my %old_params = (
    trusted_ca_options     => 'capath,cafile',
    msgcat                 => 'localedir',
    queueexpire            => '',
    clean_delay_queueother => '',
    web_recode_to          => 'filesystem_encoding',
);

## These parameters now have a hard-coded value
## Customized value can be accessed though as %Ignored_Conf
my %Ignored_Conf;
my %hardcoded_params = (
    filesystem_encoding => 'utf8'
);

my %trusted_applications = ('trusted_application' => {'occurrence' => '0-n',
						'format' => { 'name' => {'format' => '\S*',
									 'occurrence' => '1',
									 'case' => 'insensitive',
								        },
							      'ip'   => {'format' => '\d+\.\d+\.\d+\.\d+',
									 'occurrence' => '0-1'},
							      'md5password' => {'format' => '.*',
										'occurrence' => '0-1'},
							      'proxy_for_variables'=> {'format' => '.*',	    
										      'occurrence' => '0-n',
										      'split_char' => ','
										  }
							  }
					    }
			    );


my $wwsconf;
our %Conf = ();

## Loads and parses the configuration file. Reports errors if any.
sub load {
    my $config = shift;
    my $no_db = shift;
    my $line_num = 0;
    my $config_err = 0;
    my($i, %o);

    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
        printf STDERR  "load: Unable to open %s: %s\n", $config, $!;
        return undef;
    }
    while (<IN>) {
        $line_num++;
        # skip empty or commented lines
        next if (/^\s*$/ || /^[#;]/);
        # match "keyword value" pattern
        if (/^(\S+)\s+(.+)$/) {
            my ($keyword, $value) = ($1, $2);
            $value =~ s/\s*$//;
            ##  'tri' is a synonyme for 'sort'
            ## (for compatibily with old versions)
            $keyword = 'sort' if ($keyword eq 'tri');
            ##  'key_password' is a synonyme for 'key_passwd'
            ## (for compatibily with old versions)
            $keyword = 'key_passwd' if ($keyword eq 'key_password');
            ## Special case: `command`
            if ($value =~ /^\`(.*)\`$/) {
                $value = qx/$1/;
                chomp($value);
            }
            $o{$keyword} = [ $value, $line_num ];
        } else {
            printf STDERR
                gettext("Error at line %d : %s\n"), $line_num, $config, $_;
            $config_err++;
        }
    }
    close(IN);

    ## Hardcoded values
    foreach my $p (keys %hardcoded_params) {
	$Ignored_Conf{$p} = $o{$p}[0] if (defined $o{$p});
	$o{$p}[0] = $hardcoded_params{$p};
    }

    ## Defaults
    unless (defined $o{'wwsympa_url'}) {
	$o{'wwsympa_url'}[0] = "http://$o{'host'}[0]/sympa";
    }

    # 'host' and 'domain' are mandatory and synonime.$Conf{'host'} is
    # still wydly use even if the doc require domain.
 
    $o{'host'} = $o{'domain'} if (defined $o{'domain'}) ;
    $o{'domain'} = $o{'host'} if (defined $o{'host'}) ;
    
    unless ( (defined $o{'cafile'}) || (defined $o{'capath'} )) {
	$o{'cafile'}[0] = '--pkgdatadir--/etc/ca-bundle.crt';
    }   

    my $spool = $o{'spool'}[0] || $params{'spool'}->{'default'};

    unless (defined $o{'queueautomatic'}) {
      $o{'queueautomatic'}[0] = "$spool/automatic";
    }

    unless (defined $o{'queuedigest'}) {
	$o{'queuedigest'}[0] = "$spool/digest";
    }
    unless (defined $o{'queuedistribute'}) {
	$o{'queuedistribute'}[0] = "$spool/distribute";
    }
    unless (defined $o{'queuemod'}) {
	$o{'queuemod'}[0] = "$spool/moderation";
    }
    unless (defined $o{'queuetopic'}) {
	$o{'queuetopic'}[0] = "$spool/topic";
    }
    unless (defined $o{'queueauth'}) {
	$o{'queueauth'}[0] = "$spool/auth";
    }
    unless (defined $o{'queueoutgoing'}) {
	$o{'queueoutgoing'}[0] = "$spool/outgoing";
    }
    unless (defined $o{'queuesubscribe'}) {
	$o{'queuesubscribe'}[0] = "$spool/subscribe";
    }
    unless (defined $o{'queuetask'}) {
	$o{'queuetask'}[0] = "$spool/task";
    }
    unless (defined $o{'tmpdir'}) {
	$o{'tmpdir'}[0] = "$spool/tmp";
    }    

    ## Check if we have unknown values.
    foreach $i (sort keys %o) {
	next if (exists $params{$i});
	if (defined $old_params{$i}) {
	    if ($old_params{$i}) {
		printf STDERR  "Line %d of sympa.conf, parameter %s is no more available, read documentation for new parameter(s) %s\n", $o{$i}[1], $i, $old_params{$i};
	    }else {
		printf STDERR  "Line %d of sympa.conf, parameter %s is now obsolete\n", $o{$i}[1], $i;
		next;
	    }
	}else {
	    printf STDERR  "Line %d, unknown field: %s in sympa.conf\n", $o{$i}[1], $i;
	}
	$config_err++;
    }
    ## Do we have all required values ?
    foreach $i (keys %params) {
	unless (defined $o{$i} or defined $params{$i}->{'default'} or defined $params{$i}->{'optional'}) {
	    printf "Required field not found in sympa.conf: %s\n", $i;
	    $config_err++;
	    next;
	}
	$Conf{$i} = $o{$i}[0] || $params{$i}->{'default'};
    }

    ## Some parameters depend on others
    unless ($Conf{'css_url'}) {
	$Conf{'css_url'} = $Conf{'static_content_url'}.'/css';
    }
    
    unless ($Conf{'css_path'}) {
	$Conf{'css_path'} = $Conf{'static_content_path'}.'/css';
    }

    ## Some parameters require CPAN modules
    if ($Conf{'lock_method'} eq 'nfs') {
	if (eval "require File::NFSLock") {
	    require File::NFSLock;
	}else {
	    &do_log('err', "Failed to load File::NFSLock perl module ; setting 'lock_method' to 'flock'");
	    $Conf{'lock_method'} = 'flock';
	}
    }

    ## Load charset.conf file if necessary.
    if($Conf{'legacy_character_support_feature'} eq 'on'){
	my $charset_conf = &load_charset;
	$Conf{'locale2charset'} = $charset_conf;
    }else{
	$Conf{'locale2charset'} = {};
    }

    unless ($no_db){
	#load parameter from database if database value as prioprity over conf file
	foreach my $label (keys %valid_robot_key_words) {
	    next unless ($valid_robot_key_words{$label} eq 'db');
	    my $value = &get_db_conf('*', $label);
	    if ($value) {
		$Conf{$label} = $value ;
	    }
	}
	## Load robot.conf files
	my $robots_conf = &load_robots ;    
	$Conf{'robots'} = $robots_conf ;
	foreach my $robot (keys %{$Conf{'robots'}}) {
	    foreach my $label (keys %valid_robot_key_words) {
		next unless ($valid_robot_key_words{$label} eq 'db');
		my $value = &get_db_conf($robot, $label);
		if ($value) {
		    $Conf{'robots'}{$robot}{$label} = $value ;
		}
	    }
	}
    }



    my $nrcpt_by_domain =  &load_nrcpt_by_domain ;
    $Conf{'nrcpt_by_domain'} = $nrcpt_by_domain ;
    
    foreach my $robot (keys %{$Conf{'robots'}}) {
	my $config;   
	unless ($config = &tools::get_filename('etc',{},'auth.conf', $robot)) {
	    &do_log('err',"_load_auth: Unable to find auth.conf");
	    next;
	}
	
	$Conf{'auth_services'}{$robot} = &_load_auth($robot, $config);	
    }
    
    if ($Conf{'ldap_export_name'}) {    
	##Export
	$Conf{'ldap_export'} = {$Conf{'ldap_export_name'} => { 'host' => $Conf{'ldap_export_host'},
							       'suffix' => $Conf{'ldap_export_suffix'},
							       'password' => $Conf{'ldap_export_password'},
							       'DnManager' => $Conf{'ldap_export_dnmanager'},
							       'connection_timeout' => $Conf{'ldap_export_connection_timeout'}
							   }
			    };
    }
        
    my $p = 1;
    foreach (split(/,/, $Conf{'sort'})) {
	$Conf{'poids'}{$_} = $p++;
    }
    $Conf{'poids'}{'*'} = $p if ! $Conf{'poids'}{'*'};
    
    if ($config_err) {
	return undef;
    }

    ## Parameters made of comma-separated list
    foreach my $parameter ('rfc2369_header_fields','anonymous_header_fields','remove_headers','remove_outgoing_headers') {
	if ($Conf{$parameter} eq 'none') {
	    delete $Conf{$parameter};
	}else {
	    $Conf{$parameter} = [split(/,/, $Conf{$parameter})];
	}
    }

    foreach my $action (split(/,/, $Conf{'use_blacklist'})) {
	$Conf{'blacklist'}{$action} = 1;
    }

    foreach my $log_module (split(/,/, $Conf{'log_module'})) {
	$Conf{'loging_for_module'}{$log_module} = 1;
    }
    foreach my $log_condition (split(/,/, $Conf{'log_condition'})) {
	chomp $log_condition;
	if ($log_condition =~ /^\s*(ip|email)\s*\=\s*(.*)\s*$/i) { 	    
	    $Conf{'loging_condition'}{$1} = $2;
	}else{
	    &do_log('err',"unrecognized log_condition token %s ; ignored",$log_condition);
	}
    }    

    $Conf{'listmaster'} =~ s/\s//g ;
    @{$Conf{'listmasters'}} = split(/,/, $Conf{'listmaster'});

    
    ## Set Regexp for accepted list suffixes
    if (defined ($Conf{'list_check_suffixes'})) {
	$Conf{'list_check_regexp'} = $Conf{'list_check_suffixes'};
	$Conf{'list_check_regexp'} =~ s/,/\|/g;
    }
	
    $Conf{'sympa'} = "$Conf{'email'}\@$Conf{'host'}";
    $Conf{'request'} = "$Conf{'email'}-request\@$Conf{'host'}";
    $Conf{'trusted_applications'} = &load_trusted_application (); 
    $Conf{'crawlers_detection'} = &load_crawlers_detection (); 
    $Conf{'pictures_url'}  = $Conf{'static_content_url'}.'/pictures/';
    $Conf{'pictures_path'}  = $Conf{'static_content_path'}.'/pictures/';
	



    return 1;
}    

## load charset.conf file (charset mapping for service messages)
sub load_charset {
    my $charset = {};

    my $config = $Conf{'etc'}.'/charset.conf' ;
    $config = '--ETCBINDIR--/charset.conf' unless -f $config;
    if (-f $config) {
	unless (open CONFIG, $config) {
	    printf STDERR 'unable to read configuration file %s: %s\n',$config, $!;
	    return {};
	}
	while (<CONFIG>) {
	    chomp $_;
	    s/\s*#.*//;
	    s/^\s+//;
	    next unless /\S/;
	    my ($locale, $cset) = split(/\s+/, $_);
	    unless ($cset) {
		printf STDERR 'charset name is missing in configuration file %s line %d\n',$config, $.;
		next;
	    }
	    unless ($locale =~ s/^([a-z]+)_([a-z]+)/lc($1).'_'.uc($2).$'/ei) { #'
		printf STDERR 'illegal locale name in configuration file %s line %d\n',$config, $.;
		next;
	    }
	    $charset->{$locale} = $cset;
	
	}
	close CONFIG;
    }

    return $charset;
}


## load nrcpt file (limite receipient par domain
sub load_nrcpt_by_domain {
  my $config = $Conf{'etc'}.'/nrcpt_by_domain.conf';
  my $line_num = 0;
  my $config_err = 0;
  my $nrcpt_by_domain ; 
  my $valid_dom = 0;

  return undef unless (-f $config) ;
  &do_log('notice',"load_nrcpt: loading $config");

  ## Open the configuration file or return and read the lines.
  unless (open(IN, $config)) {
      printf STDERR  "load: Unable to open %s: %s\n", $config, $!;
      return undef;
  }
  while (<IN>) {
      $line_num++;
      next if (/^\s*$/o || /^[\#\;]/o);
      if (/^(\S+)\s+(\d+)$/io) {
	  my($domain, $value) = ($1, $2);
	  chomp $domain; chomp $value;
	  $nrcpt_by_domain->{$domain} = $value;
	  $valid_dom +=1;
      }else {
	  printf STDERR gettext("Error at line %d : %s"), $line_num, $config, $_;
	  $config_err++;
      }
  } 
  close(IN);
  &do_log('debug',"load_nrcpt: loaded $valid_dom config lines from $config");
  return ($nrcpt_by_domain);
}


## load each virtual robots configuration files
sub load_robots {
    
    my $robot_conf ;

    ## Load wwsympa.conf
    unless ($wwsconf = &wwslib::load_config('--WWSCONFIG--')) {
	print STDERR "Unable to load config file --WWSCONFIG--\n";
    }

    unless (opendir DIR,$Conf{'etc'} ) {
	printf STDERR "Unable to open directory $Conf{'etc'} for virtual robots config\n" ;
	return undef;
    }

    ## Set the defaults based on sympa.conf and wwsympa.conf first
    foreach my $key (keys %valid_robot_key_words) {
	$robot_conf->{$Conf{'domain'}}{$key} = $Conf{$key};
    }

    foreach my $robot (readdir(DIR)) {
	next unless (-d "$Conf{'etc'}/$robot");
	next unless (-f "$Conf{'etc'}/$robot/robot.conf");
	

	unless (-r "$Conf{'etc'}/$robot/robot.conf") {
	    printf STDERR "No read access on %s\n", "$Conf{'etc'}/$robot/robot.conf";
	    &List::send_notify_to_listmaster('cannot_access_robot_conf',$Conf{'domain'}, ["No read access on $Conf{'etc'}/$robot/robot.conf. you should change privileges on this file to activate this virtual host. "]);
	    next;
	}

	unless (open (ROBOT_CONF,"$Conf{'etc'}/$robot/robot.conf")) {
	    printf STDERR "load robots config: Unable to open $Conf{'etc'}/$robot/robot.conf\n"; 
	    next ;
	}
	
	while (<ROBOT_CONF>) {
	    next if (/^\s*$/o || /^[\#\;]/o);
	    if (/^\s*(\S+)\s+(.+)\s*$/io) {
		my($keyword, $value) = ($1, $2);
		$value =~ s/\s*$//;
		$keyword = lc($keyword);

		## Not all parameters should be lowercased
		## We should define which parameter needs to be lowercased
		#$value = lc($value) unless ($keyword eq 'title' || $keyword eq 'logo_html_definition' || $keyword eq 'lang');

		if ($valid_robot_key_words{$keyword}) {
		    $robot_conf->{$robot}{$keyword} = $value;
		    # printf STDERR "load robots config: $keyword = $value\n";
		}else{
		    printf STDERR "load robots config: unknown keyword $keyword\n";
		    # printf STDERR "load robots config: unknown keyword $keyword\n";
		}
	    }
	}
	# listmaster is a list of email separated by commas
	$robot_conf->{$robot}{'listmaster'} =~ s/\s//g;
	@{$robot_conf->{$robot}{'listmasters'}} = split(/,/, $robot_conf->{$robot}{'listmaster'})
	    if $robot_conf->{$robot}{'listmaster'};

	## Default for 'host' is the domain
	$robot_conf->{$robot}{'host'} ||= $robot;

	$robot_conf->{$robot}{'title'} ||= $wwsconf->{'title'};
	$robot_conf->{$robot}{'default_home'} ||= $wwsconf->{'default_home'};

	$robot_conf->{$robot}{'lang'} ||= $Conf{'lang'};
	$robot_conf->{$robot}{'email'} ||= $Conf{'email'};
	$robot_conf->{$robot}{'log_smtp'} ||= $Conf{'log_smtp'};
	$robot_conf->{$robot}{'log_module'} ||= $Conf{'log_module'};
	$robot_conf->{$robot}{'log_condition'} ||= $Conf{'log_module'};
	$robot_conf->{$robot}{'log_level'} ||= $Conf{'log_level'};
	$robot_conf->{$robot}{'antispam_feature'} ||= $Conf{'antispam_feature'};
	$robot_conf->{$robot}{'antispam_tag_header_name'} ||= $Conf{'antispam_tag_header_name'};
	$robot_conf->{$robot}{'antispam_tag_header_spam_regexp'} ||= $Conf{'antispam_tag_header_spam_regexp'};
	$robot_conf->{$robot}{'antispam_tag_header_ham_regexp'} ||= $Conf{'antispam_tag_header_ham_regexp'};
	$robot_conf->{$robot}{'wwsympa_url'} ||= 'http://'.$robot_conf->{$robot}{'http_host'}.'/sympa';

	$robot_conf->{$robot}{'static_content_url'} ||= $Conf{'static_content_url'};
	$robot_conf->{$robot}{'static_content_path'} ||= $Conf{'static_content_path'};

	## CSS
	$robot_conf->{$robot}{'css_url'} ||= $robot_conf->{$robot}{'static_content_url'}.'/css/'.$robot;
	$robot_conf->{$robot}{'css_path'} ||= $Conf{'static_content_path'}.'/css/'.$robot;

	$robot_conf->{$robot}{'sympa'} = $robot_conf->{$robot}{'email'}.'@'.$robot_conf->{$robot}{'host'};
	$robot_conf->{$robot}{'request'} = $robot_conf->{$robot}{'email'}.'-request@'.$robot_conf->{$robot}{'host'};
	$robot_conf->{$robot}{'cookie_domain'} ||= 'localhost';
	#$robot_conf->{$robot}{'soap_url'} ||= $Conf{'soap_url'};
	$robot_conf->{$robot}{'verp_rate'} ||= $Conf{'verp_rate'};
	$robot_conf->{$robot}{'use_blacklist'} ||= $Conf{'use_blacklist'};

	$robot_conf->{$robot}{'pictures_url'} ||= $robot_conf->{$robot}{'static_content_url'}.'/pictures/';
	$robot_conf->{$robot}{'pictures_path'} ||= $robot_conf->{$robot}{'static_content_path'}.'/pictures/';
	$robot_conf->{$robot}{'pictures_feature'} ||= $Conf{'pictures_feature'};

	# split action list for blacklist usage
	foreach my $action (split(/,/, $Conf{'use_blacklist'})) {
	    $robot_conf->{$robot}{'blacklist'}{$action} = 1;
	}

	my ($host, $path);
	if ($robot_conf->{$robot}{'http_host'} =~ /^([^\/]+)(\/.*)$/) {
	    ($host, $path) = ($1,$2);
	}else {
	    ($host, $path) = ($robot_conf->{$robot}{'http_host'}, '/');
	}

	## Warn listmaster if another virtual host is defined with the same host+path
	if (defined $Conf{'robot_by_http_host'}{$host}{$path}) {
	  printf STDERR "Error: two virtual hosts (%s and %s) are mapped via a single URL '%s%s'", $Conf{'robot_by_http_host'}{$host}{$path}, $robot, $host, $path;
	}

	$Conf{'robot_by_http_host'}{$host}{$path} = $robot ;
	
	## Create a hash to deduce robot from SOAP url
	if ($robot_conf->{$robot}{'soap_url'}) {
	    my $url = $robot_conf->{$robot}{'soap_url'};
	    $url =~ s/^http(s)?:\/\/(.+)$/$2/;
	    $Conf{'robot_by_soap_url'}{$url} = $robot;
	}
	# printf STDERR "load trusted de $robot";
	$robot_conf->{$robot}{'trusted_applications'} = &load_trusted_application($robot);
	$robot_conf->{$robot}{'crawlers_detection'} = &load_crawlers_detection($robot);

	close (ROBOT_CONF);


	#load parameter from database if database value as prioprity over conf file
	#foreach my $label (keys %valid_robot_key_words) {
	#    next unless ($valid_robot_key_words{$label} eq 'db');
	#    my $value = &get_db_conf($robot, $label);
	#    $robot_conf->{$robot}{$label} = $value if ($value);	    
	#}		
    }
    closedir(DIR);
    
    ## Default SOAP URL corresponds to default robot
    if ($Conf{'soap_url'}) {
	my $url = $Conf{'soap_url'};
	$url =~ s/^http(s)?:\/\/(.+)$/$2/;
	$Conf{'robot_by_soap_url'}{$url} = $Conf{'domain'};
    }
    return ($robot_conf);
}


## fetch the value from parameter $label of robot $robot from conf_table
sub get_db_conf  {

    my $robot = shift;
    my $label = shift;

    $dbh = &List::db_get_handler();
    my $sth;

    # if the value is related to a robot that is not explicitly defined, apply it to the default robot.
    $robot = '*' unless (-f $Conf{'etc'}.'/'.$robot.'/robot.conf') ;
    unless ($robot) {$robot = '*'};

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
	$dbh = &List::db_get_handler();
    }	   
    my $statement = sprintf "SELECT value_conf AS value FROM conf_table WHERE (robot_conf =%s AND label_conf =%s)", $dbh->quote($robot),$dbh->quote($label); 

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    my $value = $sth->fetchrow;
    
    $sth->finish();
    return $value
}


## store the value from parameter $label of robot $robot from conf_table
sub set_robot_conf  {
    my $robot = shift;
    my $label = shift;
    my $value = shift;
	
    do_log('info','Set config for robot %s , %s="%s"',$robot,$label, $value);

    
    # set the current config before to update database.    
    if (-f "$Conf{'etc'}/$robot/robot.conf") {
	$Conf{'robots'}{$robot}{$label}=$value;
    }else{
	$Conf{$label}=$value;	
	$robot = '*' ;
    }

    my $dbh = &List::db_get_handler();
    my $sth;
    
    my $statement = sprintf "SELECT count(*) FROM conf_table WHERE (robot_conf=%s AND label_conf =%s)", $dbh->quote($robot),$dbh->quote($label); 
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	next;
    }
    my $count = $sth->fetchrow;
    $sth->finish();
    
    if ($count == 0) {
	$statement = sprintf "INSERT INTO conf_table (robot_conf, label_conf, value_conf) VALUES (%s,%s,%s)",$dbh->quote($robot),$dbh->quote($label), $dbh->quote($value);
    }else{
	$statement = sprintf "UPDATE conf_table SET robot_conf=%s, label_conf=%s, value_conf=%s WHERE ( robot_conf  =%s AND label_conf =%s)",$dbh->quote($robot),$dbh->quote($label),$dbh->quote($value),$dbh->quote($robot),$dbh->quote($label); 
    }
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }    
}


## Check required files and create them if required
sub checkfiles_as_root {

  my $config_err = 0;

    ## Check aliases file
    unless (-f $Conf{'sendmail_aliases'}) {
	unless (open ALIASES, ">$Conf{'sendmail_aliases'}") {
	    &do_log('err',"Failed to create aliases file %s", $Conf{'sendmail_aliases'});
	    # printf STDERR "Failed to create aliases file %s", $Conf{'sendmail_aliases'};
	    return undef;
	}

	print ALIASES "## This aliases file is dedicated to Sympa Mailing List Manager\n";
	print ALIASES "## You should edit your sendmail.mc or sendmail.cf file to declare it\n";
	close ALIASES;
	&do_log('notice', "Created missing file %s", $Conf{'sendmail_aliases'});
	unless (&tools::set_file_rights(file => $Conf{'sendmail_aliases'},
					user => '--USER--',
					group => '--GROUP--',
					mode => 0644,
					))
	{
	    &do_log('err','Unable to set rights on %s',$Conf{'db_name'});
	    return undef;
	}
    }

    foreach my $robot (keys %{$Conf{'robots'}}) {

	# create static content directory
	my $dir = &get_robot_conf($robot, 'static_content_path');
	if ($dir ne '' && ! -d $dir){
	    unless ( mkdir ($dir, 0775)) {
		&do_log('err', 'Unable to create directory %s : %s', $dir, $!);
		printf STDERR 'Unable to create directory %s : %s',$dir, $!;
		$config_err++;
	    }

	    unless (&tools::set_file_rights(file => $dir,
					    user => '--USER--',
					    group => '--GROUP--',
					    ))
	    {
		&do_log('err','Unable to set rights on %s',$Conf{'db_name'});
		return undef;
	    }
	}
    }

    return 1 ;
}

## return 1 if the parameter is a known robot
sub valid_robot {
    my $robot = shift;

    ## Main host
    return 1 if ($robot eq $Conf{'domain'});

    ## Missing etc directory
    unless (-d $Conf{'etc'}.'/'.$robot) {
	&do_log('err', 'Robot %s undefined ; no %s directory', $robot, $Conf{'etc'}.'/'.$robot);
	return undef;
    }

    ## Missing expl directory
    unless (-d $Conf{'home'}.'/'.$robot) {
	&do_log('err', 'Robot %s undefined ; no %s directory', $robot, $Conf{'home'}.'/'.$robot);
	return undef;
    }
    
    ## Robot not loaded
    unless (defined $Conf{'robots'}{$robot}) {
	&do_log('err', 'Robot %s was not loaded by this Sympa process', $robot);
	return undef;
    }

    return 1;
}

## Check a few files
sub checkfiles {
    my $config_err = 0;
    
    foreach my $p ('sendmail','openssl','antivirus_path') {
	next unless $Conf{$p};
	
	unless (-x $Conf{$p}) {
	    do_log('err', "File %s does not exist or is not executable", $Conf{$p});
	    $config_err++;
	}
    }
    
    foreach my $qdir ('spool','queue','queueautomatic','queuedigest','queuemod','queuetopic','queueauth','queueoutgoing','queuebounce','queuesubscribe','queuetask','queuedistribute','tmpdir')
    {
	unless (-d $Conf{$qdir}) {
	    do_log('info', "creating spool $Conf{$qdir}");
	    unless ( mkdir ($Conf{$qdir}, 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{$qdir});
		$config_err++;
	    }
	}
    }

    ## Also create associated bad/ spools
    foreach my $qdir ('queue','queuedistribute','queueautomatic')
    {
	unless (-d $Conf{$qdir}.'/bad') {
	    do_log('info', "creating spool $Conf{$qdir}/bad");
	    unless ( mkdir ($Conf{$qdir}.'/bad', 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{$qdir}.'/bad');
		$config_err++;
	    }
	}
    }

    ## Check cafile and capath access
    if (defined $Conf{'cafile'} && $Conf{'cafile'}) {
	unless (-f $Conf{'cafile'} && -r $Conf{'cafile'}) {
	    &do_log('err', 'Cannot access cafile %s', $Conf{'cafile'});
	    unless (&List::send_notify_to_listmaster('cannot_access_cafile', $Conf{'domain'}, [$Conf{'cafile'}])) {
		&do_log('err', 'Unable to send notify "cannot access cafile" to listmaster');	
	    }
	    $config_err++;
	}
    }

    if (defined $Conf{'capath'} && $Conf{'capath'}) {
	unless (-d $Conf{'capath'} && -x $Conf{'capath'}) {
	    &do_log('err', 'Cannot access capath %s', $Conf{'capath'});
	    unless (&List::send_notify_to_listmaster('cannot_access_capath', $Conf{'domain'}, [$Conf{'capath'}])) {
		&do_log('err', 'Unable to send notify "cannot access capath" to listmaster');	
	    }
	    $config_err++;
	}
    }

    ## queuebounce and bounce_path pointing to the same directory
    if ($Conf{'queuebounce'} eq $wwsconf->{'bounce_path'}) {
	&do_log('err', 'Error in config : queuebounce and bounce_path parameters pointing to the same directory (%s)', $Conf{'queuebounce'});
	unless (&List::send_notify_to_listmaster('queuebounce_and_bounce_path_are_the_same', $Conf{'domain'}, [$Conf{'queuebounce'}])) {
	    &do_log('err', 'Unable to send notify "queuebounce_and_bounce_path_are_the_same" to listmaster');	
	}
	$config_err++;
    }

    ## automatic_list_creation enabled but queueautomatic pointing to queue
    if (($Conf{automatic_list_feature} eq 'on') && $Conf{'queue'} eq $Conf{'queueautomatic'}) {
        &do_log('err', 'Error in config : queue and queueautomatic parameters pointing to the same directory (%s)', $Conf{'queue'});
        unless (&List::send_notify_to_listmaster('queue_and_queueautomatic_are_the_same', $Conf{'domain'}, [$Conf{'queue'}])) {
            &do_log('err', 'Unable to send notify "queue_and_queueautomatic_are_the_same" to listmaster');
        }
        $config_err++;
    }

    #  create pictures dir if usefull for each robot
    foreach my $robot (keys %{$Conf{'robots'}}) {
	my $dir = &get_robot_conf($robot, 'static_content_path');
	if ($dir ne '' && -d $dir) {
	    unless (-f $dir.'/index.html'){
		unless(open (FF, ">$dir".'/index.html')) {
		    &do_log('err', 'Unable to create %s/index.html as an empty file to protect directory : %s', $dir, $!);
		}
		close FF;		
	    }
	    
	    # create picture dir
	    if ( &get_robot_conf($robot, 'pictures_feature') eq 'on') {
		my $pictures_dir = &get_robot_conf($robot, 'pictures_path');
		unless (-d $pictures_dir){
		    unless (mkdir ($pictures_dir, 0775)) {
			do_log('err', 'Unable to create directory %s',$pictures_dir);
			$config_err++;
		    }
		    chmod 0775, $pictures_dir;

		    my $index_path = $pictures_dir.'/index.html';
		    unless (-f $index_path){
			unless (open (FF, ">$index_path")) {
			    &do_log('err', 'Unable to create %s as an empty file to protect directory', $index_path);
			}
			close FF;
		    }
		}		
	    }
	}
    }    		

    # create or update static CSS files
    my $css_updated = undef;
    foreach my $robot (keys %{$Conf{'robots'}}) {
	my $dir = &get_robot_conf($robot, 'css_path');
	
	## Get colors for parsing
	my $param = {};
	foreach my $p (%params) {
	    $param->{$p} = &Conf::get_robot_conf($robot, $p) if (($p =~ /_color$/)|| ($p =~ /color_/));
	}

	## Set TT2 path
	my $tt2_include_path = &tools::make_tt2_include_path($robot,'web_tt2','','');

	## Create directory if required
	unless (-d $dir) {
	    unless ( &tools::mkdir_all($dir, 0755)) {
		&List::send_notify_to_listmaster('cannot_mkdir',  $robot, ["Could not create directory $dir : $!"]);
		&do_log('err','Failed to create directory %s',$dir);
		return undef;
	    }
	}

	foreach my $css ('style.css','print.css','fullPage.css','print-preview.css') {

	    $param->{'css'} = $css;

	    ## Update the CSS if it is missing or if a new css.tt2 was installed
	    if (! -f $dir.'/'.$css ||
		(stat('--pkgdatadir--/etc/web_tt2/css.tt2'))[9] > (stat($dir.'/'.$css))[9]) {
		&do_log('notice',"Updating static CSS file $dir/$css ; previous file renamed");
		
		## Keep copy of previous file
		rename $dir.'/'.$css, $dir.'/'.$css.'.'.time;

		unless (open (CSS,">$dir/$css")) {
		    &List::send_notify_to_listmaster('cannot_open_file',  $robot, ["Could not open file $dir/$css : $!"]);
		    &do_log('err','Failed to open (write) file %s',$dir.'/'.$css);
		    return undef;
		}
		
		unless (&tt2::parse_tt2($param,'css.tt2' ,\*CSS, $tt2_include_path)) {
		    my $error = &tt2::get_error();
		    $param->{'tt2_error'} = $error;
		    &List::send_notify_to_listmaster('web_tt2_error', $robot, [$error]);
		    &do_log('err', "Error while installing $dir/$css");
		}

		$css_updated ++;

		close (CSS) ;
		
		## Make the CSS world-readable
		chmod 0644, $dir.'/'.$css;
	    }	    
	}
    }
    if ($css_updated) {
	## Notify main listmaster
	&List::send_notify_to_listmaster('css_updated',  $Conf{'host'}, ["Static CSS files have been updated ; check log file for details"]);
    }


    return undef if ($config_err);
    return 1;
}

## Returns the SSO record correponding to the provided sso_id
## return undef if none was found
sub get_sso_by_id {
    my %param = @_;

    unless (defined $param{'service_id'} && defined $param{'robot'}) {
	return undef;
    }

    foreach my $sso (@{$Conf{'auth_services'}{$param{'robot'}}}) {
	&do_log('notice', "SSO: $sso->{'service_id'}");
	next unless ($sso->{'service_id'} eq $param{'service_id'});

	return $sso;
    }
    
    return undef;
}

## Loads and parses the authentication configuration file.
##########################################

sub _load_auth {
    
    my $robot = shift;
    my $config = shift;
    &do_log('debug', 'Conf::_load_auth(%s)', $config);

    my $line_num = 0;
    my $config_err = 0;
    my @paragraphs;
    my %result;
    my $current_paragraph ;

    my %valid_keywords = ('ldap' => {'regexp' => '.*',
				     'negative_regexp' => '.*',
				     'host' => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
				     'timeout' => '\d+',
				     'suffix' => '.+',
				     'bind_dn' => '.+',
				     'bind_password' => '.+',
				     'get_dn_by_uid_filter' => '.+',
				     'get_dn_by_email_filter' => '.+',
				     'email_attribute' => '\w+',
				     'alternative_email_attribute' => '(\w+)(,\w+)*',
				     'scope' => 'base|one|sub',
				     'authentication_info_url' => 'http(s)?:/.*',
				     'use_ssl' => '1',
				     'ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1',
				     'ssl_ciphers' => '[\w:]+' },
			  
			  'user_table' => {'regexp' => '.*',
					   'negative_regexp' => '.*'},
			  
			  'cas' => {'base_url' => 'http(s)?:/.*',
				    'non_blocking_redirection' => 'on|off',
				    'login_path' => '.*',
				    'logout_path' => '.*',
				    'service_validate_path' => '.*',
				    'proxy_path' => '.*',
				    'proxy_validate_path' => '.*',
				    'auth_service_name' => '.*',
				    'authentication_info_url' => 'http(s)?:/.*',
				    'ldap_host' => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
				    'ldap_bind_dn' => '.+',
				    'ldap_bind_password' => '.+',
				    'ldap_timeout'=> '\d+',
				    'ldap_suffix'=> '.+',
				    'ldap_scope' => 'base|one|sub',
				    'ldap_get_email_by_uid_filter' => '.+',
				    'ldap_email_attribute' => '\w+',
				    'ldap_use_ssl' => '1',
				    'ldap_ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1',
				    'ldap_ssl_ciphers' => '[\w:]+'
				    },
			  'generic_sso' => {'service_name' => '.+',
					    'service_id' => '\S+',
					    'http_header_prefix' => '\w+',
					    'email_http_header' => '\w+',
					    'logout_url' => '.+',
					    'ldap_host' => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
					    'ldap_bind_dn' => '.+',
					    'ldap_bind_password' => '.+',
					    'ldap_timeout'=> '\d+',
					    'ldap_suffix'=> '.+',
					    'ldap_scope' => 'base|one|sub',
					    'ldap_get_email_by_uid_filter' => '.+',
					    'ldap_email_attribute' => '\w+',
					    'ldap_use_ssl' => '1',
					    'ldap_ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1',
					    'ldap_ssl_ciphers' => '[\w:]+',
					    'force_email_verify' => '1',
					    'internal_email_by_netid' => '1',
					    'netid_http_header' => '\w+',
					},
			  'authentication_info_url' => 'http(s)?:/.*'
			  );
    


    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	do_log('notice',"_load_auth: Unable to open %s: %s", $config, $!);
	return undef;
    }
    
    $Conf{'cas_number'}{$robot} = 0;
    $Conf{'generic_sso_number'}{$robot} = 0;
    $Conf{'ldap_number'}{$robot} = 0;
    $Conf{'use_passwd'}{$robot} = 0;
    
    ## Parsing  auth.conf
    while (<IN>) {

	$line_num++;
	next if (/^\s*[\#\;]/o);		

	if (/^\s*authentication_info_url\s+(.*\S)\s*$/o){
	    $Conf{'authentication_info_url'}{$robot} = $1;
	    next;
	}elsif (/^\s*(ldap|cas|user_table|generic_sso)\s*$/io) {
	    $current_paragraph->{'auth_type'} = lc($1);
	}elsif (/^\s*(\S+)\s+(.*\S)\s*$/o){
	    my ($keyword,$value) = ($1,$2);
	    unless (defined $valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}) {
		do_log('err',"_load_auth: unknown keyword '%s' in %s line %d", $keyword, $config, $line_num);
		next;
	    }
	    unless ($value =~ /^$valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}$/) {
		do_log('err',"_load_auth: unknown format '%s' for keyword '%s' in %s line %d", $value, $keyword, $config,$line_num);
		next;
	    }

	    ## Allow white spaces between hosts
	    if ($keyword =~ /host$/) {
		$value =~ s/\s//g;
	    }
	    
	    $current_paragraph->{$keyword} = $value;
	}

	## process current paragraph
	if (/^\s+$/o || eof(IN)) {
	    if (defined($current_paragraph)) {
		
		if ($current_paragraph->{'auth_type'} eq 'cas') {
		    unless (defined $current_paragraph->{'base_url'}) {
			&do_log('err','Incorrect CAS paragraph in auth.conf');
			next;
		    }

		    my $cas_param = {casUrl => $current_paragraph->{'base_url'}};

		    ## Optional parameters
		    ## We should also cope with X509 CAs
		    $cas_param->{'loginPath'} = $current_paragraph->{'login_path'} 
		    if (defined $current_paragraph->{'login_path'});
		    $cas_param->{'logoutPath'} = $current_paragraph->{'logout_path'} 
		    if (defined $current_paragraph->{'logout_path'});
		    $cas_param->{'serviceValidatePath'} = $current_paragraph->{'service_validate_path'} 
		    if (defined $current_paragraph->{'service_validate_path'});
		    $cas_param->{'proxyPath'} = $current_paragraph->{'proxy_path'} 
		    if (defined $current_paragraph->{'proxy_path'});
		    $cas_param->{'proxyValidatePath'} = $current_paragraph->{'proxy_validate_path'} 
		    if (defined $current_paragraph->{'proxy_validate_path'});
		    
		    $current_paragraph->{'cas_server'} = new CAS(%{$cas_param});
		    unless (defined $current_paragraph->{'cas_server'}) {
			&do_log('err', 'Failed to create CAS object for %s : %s', 
				$current_paragraph->{'base_url'}, &CAS::get_errors());
			next;
		    }

		    $Conf{'cas_number'}{$robot}  ++ ;
		    $Conf{'cas_id'}{$robot}{$current_paragraph->{'auth_service_name'}} =  $#paragraphs+1 ; 
		    $current_paragraph->{'ldap_scope'} ||= 'sub'; ## Force the default scope because '' is interpreted as 'base'
		}elsif($current_paragraph->{'auth_type'} eq 'generic_sso') {
		    $Conf{'generic_sso_number'}{$robot}  ++ ;
		    $Conf{'generic_sso_id'}{$robot}{$current_paragraph->{'service_id'}} =  $#paragraphs+1 ; 
		    $current_paragraph->{'ldap_scope'} ||= 'sub'; ## Force the default scope because '' is interpreted as 'base'
		}elsif($current_paragraph->{'auth_type'} eq 'ldap') {
		    $Conf{'ldap'}{$robot}  ++ ;
		    $Conf{'use_passwd'}{$robot} = 1;
		    $current_paragraph->{'scope'} ||= 'sub'; ## Force the default scope because '' is interpreted as 'base'
		}elsif($current_paragraph->{'auth_type'} eq 'user_table') {
		    $Conf{'use_passwd'}{$robot} = 1;
		}
		# setting default
		$current_paragraph->{'regexp'} = '.*' unless (defined($current_paragraph->{'regexp'})) ;
		$current_paragraph->{'non_blocking_redirection'} = 'on' unless (defined($current_paragraph->{'non_blocking_redirection'})) ;
		push(@paragraphs,$current_paragraph);
		
		undef $current_paragraph;
	    } 
	    next ;
	}
    }
    close(IN); 

    return \@paragraphs;
    
}

## returns a robot conf parameter
sub get_robot_conf {
    my ($robot, $param) = @_;

    if ($robot ne '*') {
	if (defined $Conf{'robots'}{$robot} && defined $Conf{'robots'}{$robot}{$param}) {
	    return $Conf{'robots'}{$robot}{$param};
	}
    }
    
    ## default
    return $Conf{$param} || $wwsconf->{$param};
}



## load .sql named filter conf file
sub load_sql_filter {
	
    my $file = shift;
    my %sql_named_filter_params = (
	'sql_named_filter_query' => {'occurrence' => '1',
	'format' => { 
		'db_type' => {'format' => 'mysql|SQLite|Pg|Oracle|Sybase', },
		'db_name' => {'format' => '.*', 'occurrence' => '1', },
		'db_host' => {'format' => '.*', 'occurrence' => '1', },
		'statement' => {'format' => '.*', 'occurrence' => '1', },
		'db_user' => {'format' => '.*', 'occurrence' => '0-1',  },
		'db_passwd' => {'format' => '.*', 'occurrence' => '0-1',},
		'db_options' => {'format' => '.*', 'occurrence' => '0-1',},
		'db_env' => {'format' => '.*', 'occurrence' => '0-1',},
		'db_port' => {'format' => '\d+', 'occurrence' => '0-1',},
		'db_timeout' => {'format' => '\d+', 'occurrence' => '0-1',},
	}
	});

    return undef unless  (-r $file);

    return (&load_generic_conf_file($file,\%sql_named_filter_params, 'abort'));
}

## load trusted_application.conf configuration file
sub load_trusted_application {
    my $robot = shift;
    
    # find appropriate trusted-application.conf file
    my $config ;
    if (defined $robot) {
	$config = $Conf{'etc'}.'/'.$robot.'/trusted_applications.conf';
    }else{
	$config = $Conf{'etc'}.'/trusted_applications.conf' ;
    }
    # print STDERR "load_trusted_applications $config ($robot)\n";

    return undef unless  (-r $config);
    # open TMP, ">/tmp/dump1";&tools::dump_var(&load_generic_conf_file($config,\%trusted_applications);, 0,\*TMP);close TMP;
    return (&load_generic_conf_file($config,\%trusted_applications));

}


## load trusted_application.conf configuration file
sub load_crawlers_detection {
    my $robot = shift;

    my %crawlers_detection_conf = ('user_agent_string' => {'occurrence' => '0-n',
						  'format' => '.+'
						  } );
        
    my $config ;
    if (defined $robot) {
	$config = $Conf{'etc'}.'/'.$robot.'/crawlers_detection.conf';
    }else{
	$config = $Conf{'etc'}.'/crawlers_detection.conf' ;
	$config = '--pkgdatadir--/etc/crawlers_detection.conf' unless (-f $config);
    }

    return undef unless  (-r $config);
    my $hashtab = &load_generic_conf_file($config,\%crawlers_detection_conf);
    my $hashhash ;


    foreach my $kword (keys %{$hashtab}) {
	next unless ($crawlers_detection_conf{$kword});  # ignore comments and default
	foreach my $value (@{$hashtab->{$kword}}) {
	    $hashhash->{$kword}{$value} = 'true';
	}
    }
    
    return $hashhash;
}

############################################################
#  load_generic_conf_file
############################################################
#  load a generic config organized by paragraph syntax
#  
# IN : -$config_file (+): full path of config file
#      -$structure_ref (+) : ref(HASH) describing expected syntax
#      -$on_error : optional. sub returns undef if set to 'abort'
#          and an error is found in conf file
# OUT : ref(HASH) of parsed parameters
#     | undef
#
############################################################## 
sub load_generic_conf_file {
    my $config_file = shift;
    my $structure_ref = shift;
    my $on_error = shift;
    my %structure = %$structure_ref;

    # printf STDERR "load_generic_file  $config_file \n";

    unless (open (CONF,$config_file)) {
	 printf STDERR "load_generic_conf_file: Unable to open $config_file";
	 return undef;
    }

    my %admin;
    my (@paragraphs);
    
    ## Just in case...
    local $/ = "\n";
    
    ## Set defaults to 1
    foreach my $pname (keys %structure) {       
	$admin{'defaults'}{$pname} = 1 unless ($structure{$pname}{'internal'});
    }
        ## Split in paragraphs
    my $i = 0;
    unless (open (CONFIG, $config_file)) {
	printf STDERR 'unable to read configuration file %s\n',$config_file;
	return undef;
    }
    while (<CONFIG>) {
	if (/^\s*$/) {
	    $i++ if $paragraphs[$i];
	}else {
	    push @{$paragraphs[$i]}, $_;
	}
    }

    for my $index (0..$#paragraphs) {
	my @paragraph = @{$paragraphs[$index]};

	my $pname;

	## Clean paragraph, keep comments
	for my $i (0..$#paragraph) {
	    my $changed = undef;
	    for my $j (0..$#paragraph) {
		if ($paragraph[$j] =~ /^\s*\#/) {
		    chomp($paragraph[$j]);
		    push @{$admin{'comment'}}, $paragraph[$j];
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}elsif ($paragraph[$j] =~ /^\s*$/) {
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}

		last if $changed;
	    }

	    last unless $changed;
	}

	## Empty paragraph
	next unless ($#paragraph > -1);
	
	## Look for first valid line
	unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
	    printf STDERR 'Bad paragraph "%s" in %s, ignored', @paragraph, $config_file;
	    return undef if $on_error eq 'abort';
	    next;
	}
	    
	$pname = $1;	
	unless (defined $structure{$pname}) {
	    printf STDERR 'Unknown parameter "%s" in %s, ignored', $pname, $config_file;
	    return undef if $on_error eq 'abort';
	    next;
	}
	## Uniqueness
	if (defined $admin{$pname}) {
	    unless (($structure{$pname}{'occurrence'} eq '0-n') or
		    ($structure{$pname}{'occurrence'} eq '1-n')) {
		printf STDERR 'Multiple parameter "%s" in %s', $pname, $config_file;
		return undef if $on_error eq 'abort';
	    }
	}
	
	## Line or Paragraph
	if (ref $structure{$pname}{'format'} eq 'HASH') {
	    ## This should be a paragraph
	    unless ($#paragraph > 0) {
		printf STDERR 'Expecting a paragraph for "%s" parameter in %s, ignore it\n', $pname, $config_file;
		return undef if $on_error eq 'abort';
		next;
	    }
	    
	    ## Skipping first line
	    shift @paragraph;

	    my %hash;
	    for my $i (0..$#paragraph) {	    
		next if ($paragraph[$i] =~ /^\s*\#/);		
		unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
		    printf STDERR 'Bad line "%s" in %s\n',$paragraph[$i], $config_file;
		    return undef if $on_error eq 'abort';
		}		
		my $key = $1;
			
		unless (defined $structure{$pname}{'format'}{$key}) {
		    printf STDERR 'Unknown key "%s" in paragraph "%s" in %s\n', $key, $pname, $config_file;
		    return undef if $on_error eq 'abort';
		    next;
		}
		
		unless ($paragraph[$i] =~ /^\s*$key\s+($structure{$pname}{'format'}{$key}{'format'})\s*$/i) {
		    printf STDERR 'Bad entry "%s" in paragraph "%s" in %s\n', $paragraph[$i], $key, $pname, $config_file;
		    return undef if $on_error eq 'abort';
		    next;
		}

		$hash{$key} = &_load_a_param($key, $1, $structure{$pname}{'format'}{$key});
	    }


	    ## Apply defaults & Check required keys
	    my $missing_required_field;
	    foreach my $k (keys %{$structure{$pname}{'format'}}) {

		## Default value
		unless (defined $hash{$k}) {
		    if (defined $structure{$pname}{'format'}{$k}{'default'}) {
			$hash{$k} = &_load_a_param($k, 'default', $structure{$pname}{'format'}{$k});
		    }
		}

		## Required fields
		if ($structure{$pname}{'format'}{$k}{'occurrence'} eq '1') {
		    unless (defined $hash{$k}) {
			printf STDERR 'Missing key %s in param %s in %s\n', $k, $pname, $config_file;
			return undef if $on_error eq 'abort';
			$missing_required_field++;
		    }
		}
	    }

	    next if $missing_required_field;

	    delete $admin{'defaults'}{$pname};

	    ## Should we store it in an array
	    if (($structure{$pname}{'occurrence'} =~ /n$/)) {
		push @{$admin{$pname}}, \%hash;
	    }else {
		$admin{$pname} = \%hash;
	    }
	}else{
	    ## This should be a single line
	    my $xxxmachin =  $structure{$pname}{'format'};
	    unless ($#paragraph == 0) {
		printf STDERR 'Expecting a single line for %s parameter in %s %s\n', $pname, $config_file, $xxxmachin ;
		return undef if $on_error eq 'abort';
	    }

	    unless ($paragraph[0] =~ /^\s*$pname\s+($structure{$pname}{'format'})\s*$/i) {
		printf STDERR 'Bad entry "%s" in %s\n', $paragraph[0], $config_file ;
		return undef if $on_error eq 'abort';
		next;
	    }

	    my $value = &_load_a_param($pname, $1, $structure{$pname});

	    delete $admin{'defaults'}{$pname};

	    if (($structure{$pname}{'occurrence'} =~ /n$/)
		&& ! (ref ($value) =~ /^ARRAY/)) {
		push @{$admin{$pname}}, $value;
	    }else {
		$admin{$pname} = $value;
	    }
	}
    }
    
    close CONFIG;
    return \%admin;
}


### load_a_param
# 
sub _load_a_param {
    my ($key, $value, $p) = @_;
    
    ## Empty value
    if ($value =~ /^\s*$/) {
	return undef;
    }
    
    ## Default
    if ($value eq 'default') {
	$value = $p->{'default'};
    }
    ## lower case if usefull
    $value = lc($value) if ($p->{'case'} eq 'insensitive'); 
    
    ## Do we need to split param if it is not already an array
    if (($p->{'occurrence'} =~ /n$/)
	&& $p->{'split_char'}
	&& !(ref($value) eq 'ARRAY')) {
	my @array = split /$p->{'split_char'}/, $value;
	foreach my $v (@array) {
	    $v =~ s/^\s*(.+)\s*$/$1/g;
	}
	
	return \@array;
    }else {
	return $value;
    }
}

## Packages must return true.
1;
