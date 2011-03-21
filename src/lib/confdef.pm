# Conf.pm - This module does the sympa.conf and robot.conf parsing
# RCS Identication ; $Revision: 5688 $ ; $Date: 2009-04-30 14:49:42 +0200 (jeu, 30 avr 2009) $ 
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

package confdef;

use strict "vars";

use Sympa::Constants;

## This defines the parameters to be edited :
##   title  : Title for the group of parameters following
##   name   : Name of the parameter
##   default: Default value
##   query  : Description of the parameter
##   file   : Conf file where the param. is defined
##   vhost   : 1|0 : if 1, the parameter can have a specific value in a virtual host
##   db   : 'db_first','file_first','no'
##   multiple   : 1|0: If 1, the parameter can have mutiple values. Default i 0.
##   optional   : 1|0: If 1, the parameter is optional. It can have no value at all.
##   edit   : 1|0
##   advice : Additionnal advice concerning the parameter

our @params = (
    { title => 'Directories and file location' },
    {
        name    => 'home',
        default => Sympa::Constants::EXPLDIR,
        query   => 'Directory containing mailing lists subdirectories',
        file    => 'sympa.conf',
        edit    => '1',
    },
    {
        name    => 'etc',
        default => Sympa::Constants::SYSCONFDIR,
        query   => 'Directory for configuration files ; it also contains scenari/ and templates/ directories',
        file    => 'sympa.conf',
    },
    {
        name    => 'pidfile',
        default => Sympa::Constants::PIDDIR . '/sympa.pid',
        query   => 'File containing Sympa PID while running.',
        file    => 'sympa.conf',
        advice  => 'Sympa also locks this file to ensure that it is not running more than once. Caution : user sympa need to write access without special privilegee.',
    },
    { 
        name    => 'pidfile_distribute',
        default => Sympa::Constants::PIDDIR . '/sympa-distribute.pid',
        file    => 'sympa.conf',
    },
    { 
        name    => 'pidfile_creation',
        default => Sympa::Constants::PIDDIR . '/sympa-creation.pid',
	file    => 'sympa.conf',
    },
    { 
        name    => 'pidfile_bulk',
        default => Sympa::Constants::PIDDIR . '/bulk.pid',
	file    => 'sympa.conf',
    },
    {
        name   => 'archived_pidfile',
        default => Sympa::Constants::PIDDIR . '/archived.pid',
        query  => 'File containing archived PID while running.',
        file   => 'wwsympa.conf',
    },
    {
        name   => 'bounced_pidfile',
        default => Sympa::Constants::PIDDIR . '/bounced.pid',
        query  => 'File containing bounced PID while running.',
        file   => 'wwsympa.conf',
    },
    {
        name  => 'task_manager_pidfile',
        default => Sympa::Constants::PIDDIR . '/task_manager.pid',
        query => 'File containing task_manager PID while running.',
        file  => 'wwsympa.conf',
    },
    {
        name    => 'umask',
        default => '027',
        query   => 'Umask used for file creation by Sympa',
        file    => 'sympa.conf',
    },
    {
        name    => 'arc_path',
        default => Sympa::Constants::ARCDIR,
        query   => 'Directory for storing HTML archives',
        file    => 'wwsympa.conf',
	edit => '1',
        advice  =>'Better if not in a critical partition',
    },
     {
        name    => 'archive_default_index',
        default => 'thrd',
        query   => 'Default index organization when entering the web archive: either threaded or in chronological order',
        file    => 'wwsympa.conf',
	edit => '1',
    },
     {
        name    => 'custom_archiver',
        default => '',
        query   => 'Activates a custom archiver to use instead of MHOnArc. The value of this parameter is the absolute path on the file system to the script of the custom archiver.',
        file    => 'wwsympa.conf',
	edit => '1',
    },
   {
        name    => 'bounce_path',
        default => Sympa::Constants::BOUNCEDIR ,
        query   => 'Directory for storing bounces',
        file    => 'wwsympa.conf',
        advice  => 'Better if not in a critical partition',
    },
    {
        name    => 'localedir',
        default => Sympa::Constants::LOCALEDIR,
        query   => 'Directory containing available NLS catalogues (Message internationalization)',
        file    => 'sympa.conf',
    },
    {
        name    => 'spool',
        default => Sympa::Constants::SPOOLDIR,
        query   => 'Directory containing various specialized spools',
        file    => 'sympa.conf',
        advice => 'All spool are created at runtime by sympa.pl',
    },
    {
        name    => 'queue',
        default => Sympa::Constants::SPOOLDIR . '/msg',
        query   => 'Directory for incoming spool',
        file    => 'sympa.conf',
    },
    {
        name    => 'queuebounce',
        default => Sympa::Constants::SPOOLDIR . '/bounce',
        query   => 'Directory for bounce incoming spool',
        file    => 'sympa.conf',
    },
    {
        name    => 'queuedistribute',
		file    => 'sympa.conf'
    },
    {
        name    => 'queueautomatic',
        default => Sympa::Constants::SPOOLDIR . '/automatic',
        query   => 'Directory for automatic list creation spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queuedigest',
        default => Sympa::Constants::SPOOLDIR . '/digest',
        query   => 'Directory for digest spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queuemod',
        default => Sympa::Constants::SPOOLDIR . '/moderation',
        query   => 'Directory for moderation spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queuetopic',
        default => Sympa::Constants::SPOOLDIR . '/topic',
        query   => 'Directory for topic spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queueauth',
        default => Sympa::Constants::SPOOLDIR . '/auth',
        query   => 'Directory for authentication spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queueoutgoing',
        default => Sympa::Constants::SPOOLDIR . '/outgoing',
        query   => 'Directory for outgoing spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queuetask',
        default => Sympa::Constants::SPOOLDIR . '/task',
        query   => 'Directory for task spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'queuesubscribe',
        default => Sympa::Constants::SPOOLDIR . '/subscribe',
        query   => 'Directory for subscription spool',
	file    => 'sympa.conf'
    },
    {
        name    => 'http_host',
        query   => 'URL to a virtual host.',
        default => 'http://domain.tld',
        default => 'http://domain.tld',
	vhost   => '1',
        edit    => '1',
        file    => 'sympa.conf',
    },	      
    {
        name    => 'static_content_path',
        default => Sympa::Constants::STATICDIR,
        query   => 'Directory for storing static contents (CSS, members pictures, documentation) directly delivered by Apache',
	vhost   => '1',
        edit    => '1',
        file    => 'sympa.conf',
    },	      
    {
        name    => 'static_content_url',
        default => '/static-sympa',
        query   => 'URL mapped with the static_content_path directory defined above',
	vhost   => '1',
        edit    => '1',
        file    => 'sympa.conf',
    },	      
    { title => 'Syslog' },
    {
        name    => 'syslog',
        default => 'LOCAL1',
        query   => 'Syslog facility for sympa',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Do not forget to edit syslog.conf',
    },
    {
        name    => 'log_socket_type',
        default => 'unix',
        query   => 'Communication mode with syslogd (unix | inet)',
        file    => 'sympa.conf',
    },
    {
        name   => 'log_facility',
        default => 'LOCAL1',
        query  => 'Syslog facility for wwsympa, archived and bounced',
        file   => 'wwsympa.conf',
        edit   => '1',
        advice => 'default is to use previously defined sympa log facility',
    },
    {
        name    => 'log_level',
        default => '0',
        query   => 'Log intensity',
	vhost   => '1',
        file    => 'sympa.conf',
        advice  => '0 : normal, 2,3,4 for debug',
    },
    { 
        name    => 'log_smtp',
        default => 'off',
	vhost   => '1',
        file    => 'sympa.conf',
    },
    { 
        name    => 'log_module',
        default => '',
	vhost   => '1', 
	file    => 'wwsympa.conf',
    },
    { 
        name    => 'log_condition',
        default => '',
	vhost   => '1',
	file    => 'wwsympa.conf',
    },
    { 
        name    => 'logs_expiration_period',
        query   => 'Number of months that elapse before a log is expired.',
        default => '3',
        file    => 'sympa.conf',
    },
    { title => 'General definition' },
    {
        name    => 'domain',
        query   => 'Main robot hostname',
        edit    => '1',
        file    => 'sympa.conf',
        vhost   => '1',
    },
    {
        name    => 'listmaster',
        default => 'your_email_address@domain.tld',
        query   => 'Listmasters email list comma separated',
        file    => 'sympa.conf',
        vhost   => '1',
        edit    => '1',
        advice  => 'Sympa will associate listmaster privileges to these email addresses (mail and web interfaces). Some error reports may also be sent to these addresses.',
    },
    {
        name    => 'email',
        default => 'sympa',
        query   => 'Local part of sympa email adresse',
	vhost   => '1',
        edit    => '1',
        file    => 'sympa.conf',
        advice  => 'Effective address will be \[EMAIL\]@\[HOST\]',
    },
    {
        name    => 'create_list',
        default => 'public_listmaster',
        query   => 'Who is able to create lists',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'This parameter is a scenario, check sympa documentation about scenarios if you want to define one',
    },
    {
        name    => 'edit_list',
        default => 'owner',
	file    => 'sympa.conf',
    },
    { title => 'Tuning' },
    {
        name    => 'cache_list_config',
        default => 'none',
        query   => 'Use of binary version of the list config structure on disk: none | binary_file',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'Set this parameter to "binary_file" if you manage a big amount of lists (1000+) ; it should make the web interface startup faster',
    },
    {
        name  => 'sympa_priority',
        query => 'Sympa commands priority',
        file  => 'sympa.conf',
        default => '1',
    },
    {
        name  => 'default_list_priority',
        query => 'Default priority for list messages',
        file  => 'sympa.conf',
        default => '5',
    },
    {
        name  => 'default_ttl',
        query => 'Default timeout between two scheduled synchronizations of list members with data sources.',
        file  => 'sympa.conf',
        default => '3600',
    },
    {
        name  => 'default_distribution_ttl',
        query => 'Default timeout between two action-triggered synchronizations of list members with data sources.',
        file  => 'sympa.conf',
        default => '300',
    },
   {
        name  => 'default_sql_fetch_timeout',
        query => 'Default timeout while performing a fetch for an include_sql_query sync',
        file  => 'sympa.conf',
        default => '300',
    },
    {
        name  => 'sympa_packet_priority',
        query => 'Default priority for a packet to be sent by bulk.',
        file  => 'sympa.conf',
        default => '5',
    },
    {
        name    => 'request_priority',
        default => '0',
	file  => 'sympa.conf',
    },
    {
        name    => 'owner_priority',
        default => '9',
	file  => 'sympa.conf',
    },
    {
        name    => 'bulk_fork_threshold',
        default => '1',
        query   => 'Minimum number of packets in database before the bulk forks to increase sending rate',
        file    => 'sympa.conf',
        advice  => '',
    },
    {
        name    => 'bulk_max_count',
        default => '3',
        query   => 'Max number of bulks that will run on the same server',
        file    => 'sympa.conf',
        advice  => '',
    },
    {
        name    => 'bulk_lazytime',
        default => '600',
        query   => 'the number of seconds a slave bulk will remain running without processing a message before it spontaneously dies.',
        file    => 'sympa.conf',
        advice  => '',
    },
    {
        name    => 'bulk_wait_to_fork',
        default => '10',
        query   => 'Number of seconds a master bulk waits between two packets number checks.',
        file    => 'sympa.conf',
        advice  => 'Keep it small if you expect brutal increases in the message sending load.',
    },
    {
        name    => 'bulk_sleep',
        default => '1',
        query   => 'the number of seconds a bulk sleeps between starting a new loop if it didn\'t find a message to send.',
        file    => 'sympa.conf',
        advice  => 'Keep it small if you want your server to be reactive.',
    },
    {
        name    => 'cookie',
        sample  => '123456789',
        query   => 'Secret used by Sympa to make MD5 fingerprint in web cookies secure',
        file   => 'sympa.conf',
        advice => 'Should not be changed ! May invalid all user password',
        optional => '1',
    },
    {
        name   => 'legacy_character_support_feature',
        default => 'off',
        query  => 'If set to "on", enables support of legacy characters',
        file   => 'sympa.conf',
        advice => '',
    },
    {
        name   => 'password_case',
        default => 'insensitive',
        query  => 'Password case (insensitive | sensitive)',
        file   => 'wwsympa.conf',
        advice => 'Should not be changed ! May invalid all user password',
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
        name     => 'custom_robot_parameter',
        query    => 'Used to define a custom parameter for your server. Do not forget the semicolon between the param name and the param value.', 
	vhost    => '1',
        file     => 'sympa.conf',
        multiple => '1',
        optional => '1',
    },
    {
        name  => 'max_size',
        query => 'Default maximum size (in bytes) for messages (can be re-defined for each list)',
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
        advice  => 'Setting this parameter to "none" will hide the blacklist feature',
    },
    {
        name    => 'rfc2369_header_fields',
        query   => 'Specify which rfc2369 mailing list headers to add',
        default => 'help,subscribe,unsubscribe,post,owner,archive',
        file    => 'sympa.conf',
    },
    {
        name   => 'remove_headers',
        query  => 'Specify header fields to be removed before message distribution',
        default => 'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To,Sender',
        file    => 'sympa.conf',
    },
    {
        name   => 'reject_mail_from_automates_feature',
        query  => 'Reject mail from automates (crontab, etc) sent to a list?',
        default => 'on',
        file    => 'sympa.conf',
    },
    {
        name    => 'automatic_list_feature',
        default => 'off',
	vhost   => '1',
    },
    {
        name    => 'automatic_list_creation',
        default => 'public',
	vhost   => '1',
    },
    {
        name    => 'automatic_list_removal',
        default => '', ## Can be 'if_empty'
	vhost   => '1',
    },
    {
        name    => 'global_remind',
        default => 'listmaster',
    },
    {
        name    => 'bounce_warn_rate',
        default => '30',
        file    => 'sympa.conf',
    },
    {
        name    => 'bounce_halt_rate',
        default => '50',
        file    => 'sympa.conf',
    },
    {
        name    => 'bounce_email_prefix',
        default => 'bounce',
    },
    {
        name    => 'loop_command_max',
        default => '200',
    },
    {
        name    => 'loop_command_sampling_delay',
        default => '3600',
    },
    {
        name    => 'loop_command_decrease_factor',
        default => '0.5',
    },
    {
        name    => 'loop_prevention_regex',
        default => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
	vhost   => '1',
    },
     {
        name    => 'msgid_table_cleanup_frequency',
        default => '3600',
    },
    {
        name    => 'msgid_table_cleanup_ttl',
        default => '86400',
    },
    { title => 'Internationalization' },
    {
        name    => 'lang',
        default => 'en_US',
        query   => 'Default lang (ca | cs | de | el | es | et_EE | en_US | fr | fi | hu | it | ja_JP | ko | nl | nb_NO | oc | pl | pt_BR | ru | sv | tr | vi | zh_CN | zh_TW)',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  =>'This is the default language used by Sympa',
    },
    {
        name    => 'supported_lang',
        default => 'ca,cs,de,el,es,et_EE,en_US,fr,fi,hu,it,ja_JP,ko,nl,nb_NO,oc,pl,pt_BR,ru,sv,tr,vi,zh_CN,zh_TW',
        query   => 'Supported languages',
	vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'This is the set of language that will be proposed to your users for the Sympa GUI. Don\'t select a language if you don\'t have the proper locale packages installed.',
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
        advice => 'Not yet used in current version, Default is 50',
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
        advice => 'If set to unique, new subcriber is removed if welcome message bounce',
    },
    {
        name   => 'remind_return_path',
        query  => 'Remind message return-path',
        file   => 'sympa.conf',
        advice => 'If set to unique, subcriber is removed if remind message bounce, use with care',
    },
    { title => 'MTA related' },
    {
        name    => 'sendmail',
        default => '/usr/sbin/sendmail',
        query   => 'Path to the MTA (sendmail, postfix, exim or qmail)',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'should point to a sendmail-compatible binary (eg: a binary named "sendmail" is distributed with Postfix)',
    },
    {
        name => 'sendmail_args',
        default => '-oi -odi -oem',
    },
    {
        name => 'sendmail_aliases',
        default => Sympa::Constants::SENDMAIL_ALIASES,
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
        advice  => 'Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.',
    },
    { title => 'Plugin' },
    {
        name   => 'antivirus_path',
        optional => '1',
        sample => '/usr/local/uvscan/uvscan',
        query  => 'Path to the antivirus scanner engine',
        file   => 'sympa.conf',
        edit   => '1',
        advice => 'supported antivirus : McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall',
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
        default => 'sender',
    },
    {
        name    => 'mhonarc',
        default => '/usr/bin/mhonarc',
        query   => 'Path to MhOnarc mail2html pluggin',
        file    => 'wwsympa.conf',
        edit    => '1',
        advice  =>'This is required for HTML mail archiving',
    },
    { title => 'DKIM' },
    {
        name    => 'dkim_feature',
        default => 'off',
        vhost => '1',
	file   => 'sympa.conf',
    },
    {
        name    => 'dkim_add_signature_to',
        default => 'robot,list', 
	advice  => 'Insert a DKIM signature to message from the robot, from the list or both',
        vhost => '1',
	file   => 'sympa.conf',
    },
    {
        name    => 'dkim_signature_apply_on',
        default => 'md5_authenticated_messages,smime_authenticated_messages,dkim_authenticated_messages,editor_validated_messages', 
	advice  => 'Type of message that receive a DKIM signature before distribution to subscribers. Possible values are "none", "any" or a list of the following keywords : "md5_authenticated_messages,smime_authenticated_messages,dkim_authenticated_message,editor_validated_message".',
        vhost => '1',
	file   => 'sympa.conf',
    },    
    {
        name => 'dkim_private_key_path',
	vhost => '1',
        query   => 'location of the file where DKIM private key is stored',
	optional => '1',
	file   => 'sympa.conf',
    },
    {
        name => 'dkim_selector',
	vhost => '1',
        query   => 'the selector', 
	optional => '1',
	file   => 'sympa.conf',
    },
    {
        name => 'dkim_signer_domain',
	vhost => '1',
        query   => 'the "d=" tag as defined in rfc 4871, default is virtual host domaine',
	optional => '1',
	file   => 'sympa.conf',
    },
    {
        name => 'dkim_signer_identity',
	vhost => '1',
        query   => 'the "i=" tag as defined in rfc 4871, default null',
	optional => '1',
	file   => 'sympa.conf',
    },
    {
	name => 'dkim_header_list',
        vhost => '1',
	file   => 'sympa.conf',
        query   => 'list of headers to be included ito the message for signature', 
        default => 'from:sender:reply-to:subject:date:message-id:to:cc:list-id:list-help:list-unsubscribe:list-subscribe:list-post:list-owner:list-archive:in-reply-to:references:resent-date:resent-from:resent-sender:resent-to:resent-cc:resent-message-id:mime-version:content-type:content-transfer-encoding:content-id:content-description', 
    }, 
    { 'title' => 'S/MIME pluggin' },
    {
        name   => 'openssl',
        sample => '/usr/bin/ssl',
        query  => 'Path to OpenSSL',
        file   => 'sympa.conf',
        edit   => '1',
        advice => 'Sympa knowns S/MIME if openssl is installed',
	optional => '1',
    },
    {
        name   => 'capath',
        optional => '1',
        sample => Sympa::Constants::SYSCONFDIR . '/ssl.crt',
        query  => 'Directory containing trusted CA certificates',
        file   => 'sympa.conf',
        edit   => '1',
        optional => '1',
    },
    {
        name   => 'cafile',
        sample => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
        query  => 'File containing bundled trusted CA certificates',
        file   => 'sympa.conf',
        edit   => '1',
        optional => '1',
    },
    {
        name    => 'ssl_cert_dir',
        default => Sympa::Constants::EXPLDIR . '/X509-user-certs',
        query   => 'Directory containing user certificates',
        file    => 'sympa.conf',
    },
    {
        name    => 'crl_dir',
        default => Sympa::Constants::EXPLDIR . '/crl',
        file    => 'sympa.conf',
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
        default => '',
    },
    {
        name    => 'crl_update_task',
        default => '',
    },
    {
        name    => 'ldap_force_canonical_email',
        default => '1',
        query  => 'When using LDAP authentication, if the identifier provided by the user was a valid email, if this parameter is set to false, then the provided email will be used to authenticate the user. Otherwise, use of the first email returned by the LDAP server will be used.',
        file   => 'wwsympa.conf',
	vhost => '1',
    },
    {
        name    => 'ldap_export_name',
        default => '',
    },
    {
        name    => 'ldap_export_host',
        default => '',
    },
    {
        name    => 'ldap_export_suffix',
        default => '',
    },
    {
        name    => 'ldap_export_password',
        default => '',
    },
    {
        name    => 'ldap_export_dnmanager',
        default => '',
    },
    {
        name    => 'ldap_export_connection_timeout',
        default => '',
    },
    { title => 'Database' },
    {
        name    => 'db_type',
        default => 'mysql',
        query   => 'Type of the database (mysql|Pg|Oracle|Sybase|SQLite)',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'be careful to the case',
    },
    {
        name    => 'db_name',
        default => 'sympa',
        query   => 'Name of the database',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => 'with SQLite, the name of the DB corresponds to the DB file',
    },
    {
        name   => 'db_host',
        default => 'localhost',
        sample => 'localhost',
        query  => 'Host of the database',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name   => 'db_port',
        default => undef,
        query  => 'Port of the database',
        file   => 'sympa.conf',
	optional => '1',
    },
    {
        name   => 'db_user',
        default => 'user_name',
        sample => 'sympa',
        query  => 'User for the database connection',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name   => 'db_passwd',
        default => 'user_password',
        sample => 'your_passwd',
        query  => 'Password for the database connection',
        file   => 'sympa.conf',
        edit   => '1',
        advice => 'What ever you use a password or not, you must protect the SQL server (is it a not a public internet service ?)',
    },
    {
        name   => 'db_env',
        query  => 'Environment variables setting for database',
        file   => 'sympa.conf',
        advice => 'This is useful for defining ORACLE_HOME ',
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
        advice  => 'This module provide much faster web interface',
    },
    {
        name    => 'wwsympa_url',
        sample => 'http://host.domain.tld/sympa',
        query   => 'URL of main web page',
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
        query  => 'Type of main web page (lists|home)',
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
        name    => 'review_page_size',
        query => 'Default number of lines of the array displaying users in the review page',
	vhost   => '1',
        default => 25,
	file => 'wwsympa.conf',
    },
    {
        name    => 'viewlogs_page_size',
        query => 'Default number of lines of the array displaying the log entries in the logs page',
	vhost   => '1',
        default => 25,
	file => 'wwsympa.conf',
    },
    {
        name    => 'use_html_editor',
        query => 'If set to "on", users will be able to post messages in HTML using a javascript WYSIWYG editor.',
	vhost   => '1',
        default => '0',
        edit  => '1',
	file => 'wwsympa.conf',
    },
    {
        name    => 'html_editor_file',
        query => 'Path to the javascript file making the WYSIWYG HTML editor available',
	vhost   => '1',
        default => 'tinymce/jscripts/tiny_mce/tiny_mce.js',
	file => 'wwsympa.conf',
    },
    {
        name    => 'html_editor_init',
        query => 'Javascript excerpt that enables and configures the WYSIWYG HTML editor.',
	vhost   => '1',
        default => 'tinyMCE.init({mode : "exact",elements : "body"});',
	file => 'wwsympa.conf',
    },
    {
        name  => 'spam_status',
        default => 'x-spam-status',
        query => 'Messages are supposed to be filtered by an antispam that add one more headers to messages. This parameter is used to select a special scenario in order to decide the message spam status : ham, spam or unsure. This parameter replace antispam_tag_header_name, antispam_tag_header_spam_regexp and antispam_tag_header_ham_regexp.',
	vhost   => '1',
        file  => 'sympa.conf',
        edit  => '1',
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
        query  => 'Regexp applied on this header to verify message is a spam (example \s*Yes)',
	vhost   => '1',
        file   => 'sympa.conf',
        edit   => '1',
    },
    {
        name  => 'antispam_tag_header_ham_regexp',
        default => '^\s*No',
        query => 'Regexp applied on this header to verify message is NOT a spam (example \s*No)',
	vhost   => '1',
        file  => 'sympa.conf',
        edit  => '1',
    },
    {
        name  => 'reporting_spam_script_path',
        default => '',
        query => 'If set, when a list editor report a spam, this external script is run by wwsympa or sympa, the spam is sent into script stdin',
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
        optional => 1,
	vhost   => '1',
    },
    {
        name    => 'sort',
        default => 'fr,ca,be,ch,uk,edu,*,com',
    },
    {
        name    => 'tmpdir',
        default => Sympa::Constants::SPOOLDIR . '/tmp',
     },
    {
        name    => 'sleep',
        default => '5',
    },
    {
        name    => 'clean_delay_queue',
        default => '7',
    },
    {
        name    => 'clean_delay_queuemod',
        default => '30',
    },
    {
        name    => 'clean_delay_queuetopic',
        default => '30',
    },
    {
        name    => 'clean_delay_queuesubscribe',
        default => '30',
    },
    {
        name    => 'clean_delay_queueautomatic',
        default => '10',
    },
    {
        name    => 'clean_delay_queueauth',
        default => '30',
    },
    {
        name    => 'clean_delay_queuebounce',
        default => '7',
    },
    {
        name    => 'clean_delay_queueoutgoing',
        default => '7',
    },
    {
        name    => 'clean_delay_tmpdir',
        default => '7,'
    },
    {
        name    => 'remind_return_path',
        default => 'owner',
    },
    {
        name    => 'welcome_return_path',
        default => 'owner',
    },
    {
        name    => 'distribution_mode',
        default => 'single',
    },
    {
        name    => 'listmaster_email',
        default => 'listmaster',
	vhost   => '1',
    },
    {
        name    => 'misaddressed_commands',
        default => 'reject',
    },
    {
        name    => 'misaddressed_commands_regexp',
        default => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))',
    },
    {
        name    => 'remove_outgoing_headers',
        default => 'none',
    },
    {
        name    => 'anonymous_header_fields',
        default => 'Sender,X-Sender,Received,Message-id,From,DKIM-Signature,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender',
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
        default => '#ffcd9d', # very light grey use in tables
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
        default => '#ffffce', # top boxe and footer box bacground color
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_4',
        default => '#f77d18', #  page backgound color
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
        default => '#ccc',
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
        default => '#ffffce',  # input backgound  | transparent
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_14',
        default => '#f4f4f4',
	vhost   => '1',
	db      => 'db_first',
    },
    {
        name    => 'color_15',
        default => '#000',
	vhost   => '1',
	db      => 'db_first',
    },
    {	name	=> 'list_check_helo',
	default	=> '',
	vhost	=> '1',
    },
    {
        name    => 'list_check_smtp',
        default => '',
	vhost   => '1',
    },
    {
        name    => 'list_check_suffixes',
        default => 'request,owner,editor,unsubscribe,subscribe',
	vhost   => '1',
    },
    {
        name    => 'expire_bounce_task',
        default => 'daily',
    },
    {
        name    => 'purge_user_table_task',
        default => 'monthly',
    },
    {
        name => 'purge_logs_table_task',
        default => 'daily',
    },
    {
        name => 'purge_tables_task',
        default => 'daily',
    },
    {
        name => 'logs_expiration_period',
        default => 3,
    },
    {
        name    => 'purge_session_table_task',
        default => 'daily',
    },
    {
        name    => 'session_table_ttl',
        default => '2d',
    },
    {
        name    => 'purge_one_time_ticket_table_task',
        default => 'daily',
    },
    {
        name    => 'one_time_ticket_table_ttl',
        default => '10d',
    },
    {
        name    => 'anonymous_session_table_ttl',
        default => '1h',
    },
    {
        name    => 'purge_challenge_table_task',
        default => 'daily',
    },
    {
        name => 'challenge_table_ttl',
        default => '5d',
    },
    {
        name    => 'purge_orphan_bounces_task',
        default => 'monthly',
    },
    {
        name    => 'eval_bouncers_task',
        default => 'daily',
    },
    {
        name    => 'process_bouncers_task',
        default => 'weekly',
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
        default => 'javascript',
	vhost   => '1',
    },
    {
        name    => 'web_archive_spam_protection',
        default => 'cookie',
	vhost   => '1',
    },
    {
        name    => 'minimum_bouncing_count',
        default => '10',
    },
    {
        name    => 'minimum_bouncing_period',
        default => '10',
    },
    {
        name    => 'bounce_delay',
        default => '0',
    },
    {
        name    => 'default_bounce_level1_rate',
        default => '45',
	vhost   => '1',
    },
    {
        name    => 'default_bounce_level2_rate',
        default => '75',
	vhost   => '1',
    },
    {
        name    => 'soap_url',
        default => '',
	vhost   => '1',
    },
    {
        name    => 'css_url',
        default => '',
	vhost   => '1',
    },
    {
        name    => 'css_path',
        default => '',
	vhost   => '1',
    },
    {
        name    => 'urlize_min_size',
        default => 10240, ## 10Kb
    },
    {
        name    => 'default_remind_task',
        default => '',
    },
    {
        name    => 'update_db_field_types',
        default => 'auto',
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
        default => '-owner',
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
        default => 'on',
    },
    {
        name    => 'merge_feature',
	default => 'off',
    },
    {
        name    => 'use_blacklist',
        default => 'send,subscribe',
    },
    {
        name    => 'static_content_url',
        default => '/static-sympa',
    },
    {
        name    => 'static_content_path',
        default => Sympa::Constants::EXPLDIR . '/static_content',
    },
    {
        name    => 'filesystem_encoding',
        default => 'utf-8',
    },
    {
        name    => 'cache_list_config',
        default => 'none',
        advice  => 'none | binary_file',
    },
    {
        name    => 'lock_method',
        default => 'flock',
        advice  => 'flock | nfs',
    },
    {
        name    => 'ignore_x_no_archive_header_feature',
        default => 'off',
    },
    {
        name    => 'alias_manager',
        default => Sympa::Constants::SBINDIR . '/alias_manager.pl',
    },
    {
        name    => 'max_wrong_password',
        default => '19',
        vhost => '1',
	file   => 'sympa.conf',
    },
    {
        name    => 'tracking_delivery_status_notification',
        default => 'off',
    },
    {
        name    => 'tracking_message_delivery_notification',
        default => 'off',
    },
    {
        name    => 'tracking_default_retention_period',
        default => '90',
    },

);

