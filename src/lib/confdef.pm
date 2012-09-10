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
sub gettext { shift } # to mark i18n'ed messages.

## This defines the parameters to be edited :
##   title  : Title for the group of parameters following
##   name   : Name of the parameter
##   default: Default value
##   file   : Conf file where the param. is defined. If omitted, the parameter won't be added automatically to the config file, even if a default is set.
##   default: Default value : DON'T SET AN EMPTY DEFAULT VALUE ! It's useless and can lead to errors on fresh install.
##   query  : Description of the parameter
##   file   : Conf file where the param. is defined
##   vhost   : 1|0 : if 1, the parameter can have a specific value in a virtual host
##   db   : 'db_first','file_first','no'
##   multiple   : 1|0: If 1, the parameter can have mutiple values. Default i 0.

our @params = (

    { 'title' => gettext('Site customization') },

    {
        'name'     => 'domain',
        'query'    => gettext('Main robot hostname'),
        'sample'   => 'domain.tld',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'vhost'    => '1',
    },
    {
        'name'     => 'email',
        'default'  => 'sympa',
        'query'    => gettext('Local part of sympa email address'),
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'advice'   => gettext('Effective address will be [EMAIL]@[HOST]'),
    },
    {
        'name'     => 'email_',
        'default'  => 'SYMPA',
        'query'    => gettext('Gecos for service mail sent by Sympa itself'),
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'advice'   => gettext('This parameter is used in mail_tt2 files'),
        'optional' => '1',
    },
    {
        'name'     => 'listmaster',
        'default'  => 'your_email_address@domain.tld',
        'query'    => gettext('Listmasters email list comma separated'),
        'file'     => 'sympa.conf',
        'vhost'    => '1',
        'edit'     => '1',
        'advice'   => gettext('Sympa will associate listmaster privileges to these email addresses (mail and web interfaces). Some error reports may also be sent to these addresses.'),
    },
    {
        'name'     => 'listmaster_email',
        'default'  => 'listmaster',
        'query'    => gettext('Local part of listmaster email address'),
        'vhost'    => '1',
    },
    {
        'name'     => 'wwsympa_url',
        'sample'   => 'http://host.domain.tld/sympa',
        'query'    => gettext('URL of main Web page'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'soap_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'voot_feature',
        'default'  => 'off',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'max_wrong_password',
        'default'  => '19',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'spam_protection',
        'default'  => 'javascript',
        'vhost'    => '1',
    },
    {
        'name'     => 'web_archive_spam_protection',
        'default'  => 'cookie',
        'vhost'    => '1',
    },
    {
        'name'     => 'color_0',
        'default'  => '#ffcd9d', # very light grey use in tables,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_1',
        'default'  => '#999', # main menu button color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_2',
        'default'  => '#333',  # font color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_3',
        'default'  => '#ffffce', # top boxe and footer box bacground color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_4',
        'default'  => '#f77d18', #  page backgound color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_5',
        'default'  => '#fff',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_6',
        'default'  => '#99ccff', # list menu current button,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_7',
        'default'  => '#ff99cc', # errorbackground color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_8',
        'default'  => '#3366CC',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_9',
        'default'  => '#DEE7F7',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_10',
        'default'  => '#777777', # inactive button,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_11',
        'default'  => '#ccc',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_12',
        'default'  => '#000',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_13',
        'default'  => '#ffffce',  # input backgound  | transparent,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_14',
        'default'  => '#f4f4f4',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_15',
        'default'  => '#000',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'dark_color',
        'default'  => 'silver',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'light_color',
        'default'  => '#aaddff',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'text_color',
        'default'  => '#000000',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'bg_color',
        'default'  => '#ffffcc',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'error_color',
        'default'  => '#ff6666',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'selected_color',
        'default'  => 'silver',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'shaded_color',
        'default'  => '#66cccc',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'logo_html_definition',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'favicon_url',
        'optional' => '1',
        'vhost'    => '1',
        'optional' => '1',
    },
    {
        'name'     => 'main_menu_custom_button_1_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_1_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_1_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_2_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_2_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_2_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_3_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_3_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_3_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'css_path',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'css_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'static_content_path',
        'default'  => Sympa::Constants::STATICDIR,
        'query'    => gettext('Directory for storing static contents (CSS, members pictures, documentation) directly delivered by Apache'),
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'static_content_url',
        'default'  => '/static-sympa',
        'query'    => gettext('URL mapped with the static_content_path directory defined above'),
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'pictures_feature',
        'default'  => 'on',
    },
    {
        'name'     => 'pictures_max_size',
        'default'  => 102400, ## 100Kb,
        'vhost'    => '1',
    },
    {
        'name'     => 'cookie',
        'sample'   => '123456789',
        'query'    => gettext('Secret used by Sympa to make MD5 fingerprint in web cookies secure'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('Should not be changed ! May invalid all user password'),
        'optional' => '1',
    },
    {
        'name'     => 'create_list',
        'default'  => 'public_listmaster',
        'query'    => gettext('Who is able to create lists'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('This parameter is a scenario, check sympa documentation about scenarios if you want to define one'),
    },
    {
        'name'     => 'global_remind',
        'default'  => 'listmaster',
    },
    {
        'name'     => 'allow_subscribe_if_pending',
        'default'  => 'on',
        'vhost'    => '1',
    },
    {
        'name'     => 'custom_robot_parameter',
        'query'    => gettext('Used to define a custom parameter for your server. Do not forget the semicolon between the param name and the param value.'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'multiple' => '1',
        'optional' => '1',
    },

    { 'title' => gettext('Directories') },

    {
        'name'     => 'home',
        'default'  => Sympa::Constants::EXPLDIR,
        'query'    => gettext('Directory containing mailing lists subdirectories'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'etc',
        'default'  => Sympa::Constants::SYSCONFDIR,
        'query'    => gettext('Directory for configuration files; it also contains scenari/ and templates/ directories'),
        'file'     => 'sympa.conf',
    },

    { 'title' => gettext('System related') },

    {
        'name'     => 'syslog',
        'default'  => 'LOCAL1',
        'query'    => gettext('Syslog facility for sympa'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Do not forget to edit syslog.conf'),
    },
    {
        'name'     => 'log_level',
        'default'  => '0',
        'query'    => gettext('Log verbosity'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'advice'   => gettext('0: normal, 2,3,4: for debug'),
    },
    {
        'name'     => 'log_socket_type',
        'default'  => 'unix',
        'query'    => gettext('Communication mode with syslogd (unix | inet)'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'pidfile',
        'default'  => Sympa::Constants::PIDDIR . '/sympa.pid',
        'query'    => gettext('File containing Sympa PID while running'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('Sympa also locks this file to ensure that it is not running more than once. Caution: user sympa need to write access without special privilege.'),
    },
    {
        'name'     => 'pidfile_creation',
        'default'  => Sympa::Constants::PIDDIR . '/sympa-creation.pid',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'umask',
        'default'  => '027',
        'query'    => gettext('Umask used for file creation by Sympa'),
        'file'     => 'sympa.conf',
    },
    { title => 'Internationalization' },
    {
        name    => 'lang',
        default => 'en',
        query   => 'Default lang (ca | cs | de | el | es | et_EE | en | fr | fi | hu | it | ja_JP | ko | nl | nb_NO | oc | pl | pt_BR | ru | sv | tr | vi | zh_CN | zh_TW)',
        vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => gettext('This is the default language used by Sympa'),
    },
    {
        name    => 'supported_lang',
        default => 'ca,cs,de,el,es,et_EE,en,fr,fi,hu,it,ja_JP,ko,nl,nb_NO,oc,pl,pt_BR,ru,sv,tr,vi,zh_CN,zh_TW',
        query   => 'Supported languages',
        vhost   => '1',
        file    => 'sympa.conf',
        edit    => '1',
        advice  => gettext('This is the set of language that will be proposed to your users for the Sympa GUI. Don\'t select a language if you don\'t have the proper locale packages installed.'),
    },
    { 'title' => gettext('Sending related') },
    {
        'name'     => 'sendmail',
        'default'  => '/usr/sbin/sendmail',
        'query'    => gettext('Path to the MTA (sendmail, postfix, exim or qmail)'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('should point to a sendmail-compatible binary (eg: a binary named "sendmail" is distributed with Postfix)'),
    },
    {
        'name'     => 'sendmail_args',
        'default'  => '-oi -odi -oem',
    },
    {
        'name'     => 'distribution_mode',
        'default'  => 'single',
    },
    {
        'name'     => 'maxsmtp',
        'default'  => '40',
        'query'    => gettext('Max. number of Sendmail processes (launched by Sympa) running simultaneously'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.'),
    },
    {
        'name'    => 'automatic_list_removal',
        'default' => 'none',
        'vhost'   => '1',
    },
    {
        'name'    => 'automatic_list_feature',
        'default' => 'off',
        'vhost'   => '1',
    },
    {
        'name'    => 'automatic_list_creation',
        'default' => 'public',
        'vhost'   => '1',
    },
    {
        'name'    => 'automatic_list_families',
        'query'   => 'Defines the name of the family the automatic lists are based on.', 
        'file'    => 'sympa.conf',
        'optional' => '1',
        vhost   => '1',
    },
    {
        'name'    => 'automatic_list_prefix',
        'query'   => 'Defines the prefix allowing to recognize that a list is an automatic list.', 
        'file'    => 'sympa.conf',
        'optional' => '1',
    },
    {
        'name'     => 'log_smtp',
        'default'  => 'off',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'    => 'global_remind',
        'default' => 'listmaster',
    },
    {
        'name'     => 'use_blacklist',
        'query'    => gettext('comma separated list of operations for which blacklist filter is applied'),
        'default'  => 'send,create_list',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Setting this parameter to "none" will hide the blacklist feature'),
    },
    {
        'name'     => 'reporting_spam_script_path',
        'optional'  => '1',
        'query'    => gettext('If set, when a list editor report a spam, this external script is run by wwsympa or sympa, the spam is sent into script stdin'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'max_size',
        'query'    => gettext('Default maximum size (in bytes) for messages (can be re-defined for each list)'),
        'default'  => '5242880',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'misaddressed_commands',
        'default'  => 'reject',
    },
    {
        'name'     => 'misaddressed_commands_regexp',
        'default'  => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))',
    },
    {
        'name'     => 'nrcpt',
        'default'  => '25',
        'query'    => gettext('Maximum number of recipients per call to Sendmail. The nrcpt_by_domain.conf file allows a different tuning per destination domain.'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'avg',
        'default'  => '10',
        'query'    => gettext('Max. number of different domains per call to Sendmail'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'alias_manager',
        'default'  => Sympa::Constants::SBINDIR . '/alias_manager.pl',
    },
    {
        name    => 'db_list_cache',
        default => 'off',
        advice  => gettext('Whether or not to cache lists in the database'),
    },
    {
        'name'     => 'sendmail_aliases',
        'default'  => Sympa::Constants::SENDMAIL_ALIASES,
    },
    {
        'name'     => 'rfc2369_header_fields',
        'query'    => gettext('Specify which rfc2369 mailing list headers to add'),
        'default'  => 'help,subscribe,unsubscribe,post,owner,archive',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'remove_headers',
        'query'    => gettext('Specify header fields to be removed before message distribution'),
        'default'  => 'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To,Sender',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'remove_outgoing_headers',
        'default'  => 'none',
    },
    {
        'name'     => 'reject_mail_from_automates_feature',
        'query'    => gettext('Reject mail from automates (crontab, etc) sent to a list?'),
        'default'  => 'on',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'ignore_x_no_archive_header_feature',
        'default'  => 'off',
    },
    {
        'name'     => 'anonymous_header_fields',
        'default'  => 'Sender,X-Sender,Received,Message-id,From,DKIM-Signature,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender',
    },
    {
        'name'     => 'list_check_smtp',
        'optional' => '1',
        'query'    => gettext('SMTP server to which Sympa verify if alias with the same name as the list to be created'),
        'vhost'    => '1',
        'advice'   => gettext('Default value is real FQDN of host. Set [HOST]:[PORT] to specify non-standard port.'),
    },
    {
        'name'     => 'list_check_suffixes',
        'default'  => 'request,owner,editor,unsubscribe,subscribe',
        'vhost'    => '1',
    },
    {
        'name'     => 'list_check_helo',
        'optional' => '1',
        'query'    => gettext('SMTP HELO (EHLO) parameter used for alias verification'),
        'vhost'    => '1',
        'advice'   => gettext('Default value is the host part of list_check_smtp parameter.'),
    },
    {
        'name'     => 'urlize_min_size',
        'default'  => 10240, ## 10Kb,
    },

    { 'title' => gettext('Bulk mailer') },

    {
        'name'     => 'pidfile_bulk',
        'default'  => Sympa::Constants::PIDDIR . '/bulk.pid',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'sympa_packet_priority',
        'query'    => gettext('Default priority for a packet to be sent by bulk.'),
        'file'     => 'sympa.conf',
        'default'  => '5',
    },
    {
        'name'     => 'bulk_fork_threshold',
        'default'  => '1',
        'query'    => gettext('Minimum number of packets in database before the bulk forks to increase sending rate'),
        'file'     => 'sympa.conf',
        'advice'   => gettext(''),
    },
    {
        'name'     => 'bulk_max_count',
        'default'  => '3',
        'query'    => gettext('Max number of bulks that will run on the same server'),
        'file'     => 'sympa.conf',
        'advice'   => gettext(''),
    },
    {
        'name'     => 'bulk_lazytime',
        'default'  => '600',
        'query'    => gettext('The number of seconds a slave bulk will remain running without processing a message before it spontaneously dies.'),
        'file'     => 'sympa.conf',
        'advice'   => gettext(''),
    },
    {
        'name'     => 'bulk_sleep',
        'default'  => '1',
        'query'    => gettext("The number of seconds a bulk sleeps between starting a new loop if it didn't find a message to send."),
        'file'     => 'sympa.conf',
        'advice'   => gettext('Keep it small if you want your server to be reactive.'),
    },
    {
        'name'     => 'bulk_wait_to_fork',
        'default'  => '10',
        'query'    => gettext('Number of seconds a master bulk waits between two packets number checks.'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('Keep it small if you expect brutal increases in the message sending load.'),
    },

    { 'title' => gettext('Quotas') },

    {
        'name'     => 'default_shared_quota',
        'optional' => '1',
        'query'    => gettext('Default disk quota for shared repository'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'default_archive_quota',
        'optional' => '1',
    },

    { 'title' => gettext('Spool related') },

    {
        'name'     => 'spool',
        'default'  => Sympa::Constants::SPOOLDIR,
        'query'    => gettext('Directory containing various specialized spools'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('All spool are created at runtime by sympa.pl'),
    },
    {
        'name'     => 'queue',
        'default'  => Sympa::Constants::SPOOLDIR . '/msg',
        'query'    => gettext('Directory for incoming spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuedistribute',
        'default'  => Sympa::Constants::SPOOLDIR . '/distribute',
        'file'     => 'sympa.conf',
    },
    ##{
	##name => 'dkim_header_list',
        ##vhost => '1',
	##file   => 'sympa.conf',
        ##query   => 'list of headers to be included ito the message for signature', 
        ##default => 'from:sender:reply-to:subject:date:message-id:to:cc:list-id:list-help:list-unsubscribe:list-subscribe:list-post:list-owner:list-archive:in-reply-to:references:resent-date:resent-from:resent-sender:resent-to:resent-cc:resent-message-id:mime-version:content-type:content-transfer-encoding:content-id:content-description', 
    ##}, 
    { 'title' => 'S/MIME pluggin' },
    {
        'name'     => 'queuemod',
        'default'  => Sympa::Constants::SPOOLDIR . '/moderation',
        'query'    => gettext('Directory for moderation spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuedigest',
        'default'  => Sympa::Constants::SPOOLDIR . '/digest',
        'query'    => gettext('Directory for digest spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queueauth',
        'default'  => Sympa::Constants::SPOOLDIR . '/auth',
        'query'    => gettext('Directory for authentication spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queueoutgoing',
        'default'  => Sympa::Constants::SPOOLDIR . '/outgoing',
        'query'    => gettext('Directory for outgoing spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuetopic',
        'default'  => Sympa::Constants::SPOOLDIR . '/topic',
        'query'    => gettext('Directory for topic spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuebounce',
        'default'  => Sympa::Constants::SPOOLDIR . '/bounce',
        'query'    => gettext('Directory for bounce incoming spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuetask',
        'default'  => Sympa::Constants::SPOOLDIR . '/task',
        'query'    => gettext('Directory for task spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queueautomatic',
        'default'  => Sympa::Constants::SPOOLDIR . '/automatic',
        'query'    => gettext('Directory for automatic list creation spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'tmpdir',
        'default'  => Sympa::Constants::SPOOLDIR . '/tmp',
        'query'    => gettext('Temporary directory used by OpenSSL and antivirus plugins'),
    },
    {
        'name'     => 'sleep',
        'default'  => '5',
        'advice'   => gettext('Must not be 0.'),
    },
    {
        'name'     => 'clean_delay_queue',
        'default'  => '7',
    },
    {
        'name'     => 'clean_delay_queueoutgoing',
        'default'  => '7',
    },
    {
        'name'     => 'clean_delay_queuebounce',
        'default'  => '7',
    },
    {
        'name'     => 'clean_delay_queuemod',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queueauth',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queuesubscribe',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queuetopic',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queueautomatic',
        'default'  => '10',
    },
    {
        'name'     => 'clean_delay_tmpdir',
        'default'  => '7,',
    },

    { 'title' => gettext('Internationalization related') },

    {
        'name'     => 'localedir',
        'default'  => Sympa::Constants::LOCALEDIR,
        'query'    => gettext('Directory containing available NLS catalogues (Message internationalization)'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'supported_lang',
        'default'  => 'ca,cs,de,el,es,et_EE,en_US,fr,fi,hu,it,ja_JP,ko,nl,nb_NO,oc,pl,pt_BR,ru,sv,tr,vi,zh_CN,zh_TW',
        'query'    => gettext('Supported languages'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext("This is the set of language that will be proposed to your users for the Sympa GUI. Don't select a language if you don't have the proper locale packages installed."),
    },
    {
        'name'     => 'lang',
        'default'  => 'en_US',
        'query'    => gettext('Default language (one of supported languages)'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('This is the default language used by Sympa'),
    },
    {
        'name'     => 'filesystem_encoding',
        'default'  => 'utf-8',
    },

    { 'title' => gettext('Bounce related') },

    {
        'name'     => 'verp_rate',
        'default'  => '0%',
        'vhost'    => '1',
    },
    {
        'name'     => 'welcome_return_path',
        'default'  => 'owner',
        'query'    => gettext('Welcome message return-path ( unique | owner )'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('If set to unique, new subcriber is removed if welcome message bounce'),
    },
    {
        'name'     => 'remind_return_path',
        'default'  => 'owner',
        'query'    => gettext('Remind message return-path ( unique | owner )'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('If set to unique, subcriber is removed if remind message bounce, use with care'),
    },
    {
        'name'     => 'return_path_suffix',
        'default'  => '-owner',
    },
    {
        'name'     => 'expire_bounce_task',
        'default'  => 'daily',
        'query'    => gettext('Task name for expiration of old bounces'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'purge_orphan_bounces_task',
        'default'  => 'monthly',
    },
    {
        'name'     => 'eval_bouncers_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'process_bouncers_task',
        'default'  => 'weekly',
    },
    {
        'name'     => 'minimum_bouncing_count',
        'default'  => '10',
    },
    {
        'name'     => 'minimum_bouncing_period',
        'default'  => '10',
    },
    {
        'name'     => 'bounce_delay',
        'default'  => '0',
    },
    {
        'name'     => 'default_bounce_level1_rate',
        'default'  => '45',
        'vhost'    => '1',
    },
    {
        'name'     => 'default_bounce_level2_rate',
        'default'  => '75',
        'vhost'    => '1',
    },
    {
        'name'     => 'bounce_email_prefix',
        'default'  => 'bounce',
    },
    {
        'name'     => 'bounce_warn_rate',
        'default'  => '30',
        'query'    => gettext('Bouncing email rate for warn list owner'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'bounce_halt_rate',
        'default'  => '50',
        'query'    => gettext('Bouncing email rate for halt the list (not implemented)'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('Not yet used in current version, Default is 50'),
    },
    {
        'name'     => 'tracking_delivery_status_notification',
        'default'  => 'off',
    },
    {
        'name'     => 'tracking_message_delivery_notification',
        'default'  => 'off',
    },
    {
        'name'     => 'default_remind_task',
        'optional' => '1',
    },

    { 'title' => gettext('Tuning') },

    {
        'name'     => 'cache_list_config',
        'default'  => 'none',
        'query'    => gettext('Use of binary version of the list config structure on disk (none | binary_file)'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Set this parameter to "binary_file" if you manage a big amount of lists (1000+); it should make the web interface startup faster'),
    },
    {
        'name'     => 'lock_method',
        'default'  => 'flock',
        'advice'   => gettext('flock | nfs'),
    },
    {
        'name'     => 'sympa_priority',
        'query'    => gettext('Sympa commands priority'),
        'file'     => 'sympa.conf',
        'default'  => '1',
    },
    {
        'name'     => 'request_priority',
        'default'  => '0',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'owner_priority',
        'default'  => '9',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'default_list_priority',
        'query'    => gettext('Default priority for list messages'),
        'file'     => 'sympa.conf',
        'default'  => '5',
    },

    { 'title' => gettext('Database related') },

    {
        'name'     => 'update_db_field_types',
        'default'  => 'auto',
    },
    {
        'name'     => 'db_type',
        'default'  => 'mysql',
        'query'    => gettext('Type of the database (mysql|Pg|Oracle|Sybase|SQLite)'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Be careful to the case'),
    },
    {
        'name'     => 'db_name',
        'default'  => 'sympa',
        'query'    => gettext('Name of the database'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('With SQLite, the name of the DB corresponds to the DB file'),
    },
    {
        'name'     => 'db_host',
        'default'  => 'localhost',
        'sample'   => 'localhost',
        'query'    => gettext('Hostname of the database server'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'db_port',
        'default'  => undef,
        'query'    => gettext('Port of the database server'),
        'file'     => 'sympa.conf',
        'optional' => '1',
    },
    {
        'name'     => 'db_user',
        'default'  => 'user_name',
        'sample'   => 'sympa',
        'query'    => gettext('User for the database connection'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'db_passwd',
        'default'  => 'user_password',
        'sample'   => 'your_passwd',
        'query'    => gettext('Password for the database connection'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('What ever you use a password or not, you must protect the SQL server (is it not a public internet service ?)'),
    },
    {
        'name'     => 'db_timeout',
        'optional' => '1',
    },
    {
        'name'     => 'db_options',
        'optional' => '1',
    },
    {
        'name'     => 'db_env',
        'query'    => gettext('Environment variables setting for database'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('This is useful for defining ORACLE_HOME '),
        'optional' => '1',
    },
    {
        'name'     => 'db_additional_subscriber_fields',
        'sample'   => 'billing_delay,subscription_expiration',
        'query'    => gettext('Database private extention to subscriber table'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('You need to extend the database format with these fields'),
        'optional' => '1',
    },
    {
        'name'     => 'db_additional_user_fields',
        'sample'   => 'age,address',
        'query'    => gettext('Database private extention to user table'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('You need to extend the database format with these fields'),
        'optional' => '1',
    },
    {
        'name'     => 'purge_user_table_task',
        'default'  => 'monthly',
    },
    {
        'name'     => 'purge_tables_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'purge_logs_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'logs_expiration_period',
        'query'    => gettext('Number of months that elapse before a log is expired'),
        'default'  => '3',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'purge_session_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'session_table_ttl',
        'default'  => '2d',
    },
    {
        'name'     => 'purge_challenge_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'challenge_table_ttl',
        'default'  => '5d',
    },
    {
        'name'     => 'default_ttl',
        'query'    => gettext('Default timeout between two scheduled synchronizations of list members with data sources.'),
        'file'     => 'sympa.conf',
        'default'  => '3600',
    },
    {
        'name'     => 'default_distribution_ttl',
        'query'    => gettext('Default timeout between two action-triggered synchronizations of list members with data sources.'),
        'file'     => 'sympa.conf',
        'default'  => '300',
    },
    {
        'name'     => 'default_sql_fetch_timeout',
        'query'    => gettext('Default timeout while performing a fetch for an include_sql_query sync'),
        'file'     => 'sympa.conf',
        'default'  => '300',
    },

    { 'title' => gettext('Loop prevention') },

    {
        'name'     => 'loop_command_max',
        'default'  => '200',
    },
    {
        'name'     => 'loop_command_sampling_delay',
        'default'  => '3600',
    },
    {
        'name'     => 'loop_command_decrease_factor',
        'default'  => '0.5',
    },
    {
        'name'     => 'loop_prevention_regex',
        'default'  => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
        'vhost'    => '1',
    },
    {
        'name'     => 'msgid_table_cleanup_ttl',
        'default'  => '86400',
    },
    {
        'name'     => 'msgid_table_cleanup_frequency',
        'default'  => '3600',
    },

    { 'title' => gettext('S/MIME configuration') },

    {
        'name'     => 'openssl',
        'sample'   => '/usr/bin/ssl',
        'query'    => gettext('Path to OpenSSL'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Sympa recognizes S/MIME if OpenSSL is installed'),
        'optional' => '1',
    },
    {
        'name'     => 'capath',
        'optional' => '1',
        'sample'   => Sympa::Constants::SYSCONFDIR . '/ssl.crt',
        'query'    => gettext('Directory containing trusted CA certificates'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },
    {
        'name'     => 'cafile',
        'sample'   => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
        'query'    => gettext('File containing bundled trusted CA certificates'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },
    {
        'name'     => 'key_passwd',
        'sample'   => 'your_password',
        'query'    => gettext('Password used to crypt lists private keys'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },

    { 'title' => gettext('DKIM') },

    {
        'name'     => 'dkim_feature',
        'default'  => 'off',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_add_signature_to',
        'default'  => 'robot,list',
        'advice'   => gettext('Insert a DKIM signature to message from the robot, from the list or both'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_signature_apply_on',
        'default'  => 'md5_authenticated_messages,smime_authenticated_messages,dkim_authenticated_messages,editor_validated_messages',
        'advice'   => gettext('Type of message that is added a DKIM signature before distribution to subscribers. Possible values are "none", "any" or a list of the following keywords: "md5_authenticated_messages", "smime_authenticated_messages", "dkim_authenticated_messages", "editor_validated_messages".'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_private_key_path',
        'vhost'    => '1',
        'query'    => gettext('Location of the file where DKIM private key is stored'),
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_signer_domain',
        'vhost'    => '1',
        'query'    => gettext('The "d=" tag as defined in rfc 4871, default is virtual host domain name'),
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_selector',
        'vhost'    => '1',
        'query'    => gettext('The selector'),
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_signer_identity',
        'vhost'    => '1',
        'query'    => gettext('The "i=" tag as defined in rfc 4871, default is null'),
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    { 'title' => gettext('Antivirus plug-in') },

    {
        'name'     => 'antivirus_path',
        'optional' => '1',
        'sample'   => '/usr/local/uvscan/uvscan',
        'query'    => gettext('Path to the antivirus scanner engine'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'advice'   => gettext('supported antivirus: McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall'),
    },
    {
        'name'     => 'antivirus_args',
        'optional' => '1',
        'sample'   => '--secure --summary --dat /usr/local/uvscan',
        'query'    => gettext('Antivirus plugin command argument'),
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'antivirus_notify',
        'default'  => 'sender',
    },

    { 'title' => gettext('Tag based spam filtering') },

    {
        'name'     => 'antispam_feature',
        'default'  => 'off',
        'vhost'    => '1',
    },
    {
        'name'     => 'antispam_tag_header_name',
        'default'  => 'X-Spam-Status',
        'query'    => gettext('If a spam filter (like spamassassin or j-chkmail) add a smtp headers to tag spams, name of this header (example X-Spam-Status)'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'antispam_tag_header_spam_regexp',
        'default'  => '^\s*Yes',
        'query'    => gettext('Regexp applied on this header to verify message is a spam (example Yes)'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'antispam_tag_header_ham_regexp',
        'default'  => '^\s*No',
        'query'    => gettext('Regexp applied on this header to verify message is NOT a spam (example No)'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },

    { 'title' => gettext('wwsympa.conf parameters') },

    {
        'name'     => 'arc_path',
        'default'  => Sympa::Constants::ARCDIR,
        'query'    => gettext('Directory for storing HTML archives'),
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Better if not in a critical partition'),
        'vhost'     => '1',
    },
    {
        'name'     => 'archive_default_index',
        'default'  => 'thrd',
        'query'    => gettext('Default index organization when entering the web archive: either threaded or in chronological order'),
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'archived_pidfile',
        'default'  => Sympa::Constants::PIDDIR . '/archived.pid',
        'query'    => gettext('File containing archived PID while running'),
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'bounce_path',
        'default'  => Sympa::Constants::BOUNCEDIR ,
        'query'    => gettext('Directory for storing bounces'),
        'file'     => 'wwsympa.conf',
        'advice'   => gettext('Better if not in a critical partition'),
    },
    {
        'name'     => 'bounced_pidfile',
        'default'  => Sympa::Constants::PIDDIR . '/bounced.pid',
        'query'    => gettext('File containing bounced PID while running'),
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'cookie_expire',
        'default'  => '0',
        'query'    => gettext('HTTP cookies lifetime'),
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'cookie_domain',
        'default'  => 'localhost',
        'query'    => gettext('HTTP cookies validity domain'),
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'custom_archiver',
        'optional' => '1',
        'query'    => gettext('Activates a custom archiver to use instead of MHonArc. The value of this parameter is the absolute path on the file system to the script of the custom archiver.'),
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'default_home',
        'default'  => 'home',
        'query'    => gettext('Type of main Web page ( lists | home )'),
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'log_facility',
        'default'  => 'LOCAL1',
        'query'    => gettext('Syslog facility for wwsympa, archived and bounced'),
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'advice'   => gettext('Default is to use previously defined sympa log facility.'),
    },
    {
        'name'     => 'mhonarc',
        'default'  => '/usr/bin/mhonarc',
        'query'    => gettext('Path to MHonArc mail2html plugin'),
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'advice'   => gettext('This is required for HTML mail archiving'),
    },
    {
        'name'     => 'password_case',
        'default'  => 'insensitive',
        'query'    => gettext('Password case (insensitive | sensitive)'),
        'file'     => 'wwsympa.conf',
        'advice'   => gettext('Should not be changed ! May invalid all user password'),
    },
    {
        'name'     => 'title',
        'default'  => 'Mailing lists service',
        'query'    => gettext('Title of main Web page'),
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'use_fast_cgi',
        'default'  => '1',
        'query'    => gettext('Is fast_cgi module for Apache (or Roxen) installed (0 | 1)'),
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'advice'   => gettext('This module provide much faster web interface'),
    },

    { 'title' => gettext('Virtual host specific parameters') },

    {
        'name'     => 'http_host',
        'query'    => gettext('URL of a virtual host'),
        'sample'   => 'http://host.domain.tld',
        'default'  => 'http://host.domain.tld',
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
    },

    { 'title' => 'NOT CATEGORIZED' },

    {
        'name'     => 'anonymous_session_table_ttl',
        'default'  => '1h',
    },
    {
        'name'     => 'chk_cert_expiration_task',
        'optional' => '1',
    },
    {
        'name'     => 'crl_dir',
        'default'  => Sympa::Constants::EXPLDIR . '/crl',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'crl_update_task',
        'optional' => '1',
    },
    {
        'name'     => 'default_max_list_members',
        'default'  => '0',
        'optional' => '1',
        'query'    => gettext('Default limit for the number of subscribers per list (0 means no limit)'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'edit_list',
        'default'  => 'owner',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'host',
        'optional' => 1,
        'vhost'    => '1',
    },
    {
        'name'     => 'tracking_default_retention_period',
        'default'  => '90',
    },
    {
        'name'     => 'use_html_editor',
        'query'    => gettext('If set to "on", users will be able to post messages in HTML using a javascript WYSIWYG editor.'),
        'vhost'    => '1',
        'default'  => '0',
        'edit'     => '1',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'html_editor_file',
        'query'    => gettext('Path to the javascript file making the WYSIWYG HTML editor available'),
        'vhost'    => '1',
        'default'  => 'tinymce/jscripts/tiny_mce/tiny_mce.js',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'html_editor_init',
        'query'    => gettext('Javascript excerpt that enables and configures the WYSIWYG HTML editor.'),
        'vhost'    => '1',
        'default'  => 'tinyMCE.init({mode : "exact",elements : "body"});',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'ldap_export_connection_timeout',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_dnmanager',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_host',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_name',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_password',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_suffix',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_force_canonical_email',
        'default'  => '1',
        'query'    => gettext('When using LDAP authentication, if the identifier provided by the user was a valid email, if this parameter is set to false, then the provided email will be used to authenticate the user. Otherwise, use of the first email returned by the LDAP server will be used.'),
        'file'     => 'wwsympa.conf',
        'vhost'    => '1',
    },
    {
        'name'     => 'legacy_character_support_feature',
        'default'  => 'off',
        'query'    => gettext('If set to "on", enables support of legacy character set'),
        'file'     => 'sympa.conf',
        'advice'   => gettext('In some language environments, legacy encoding (character set) is preferred for e-mail messages: for example iso-2022-jp in Japanese language.'),
    },
    {
        'name'     => 'log_condition',
        'optional' => '1',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'log_module',
        'optional' => '1',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'merge_feature',
        'default'  => 'off',
    },
    {
        'name'     => 'one_time_ticket_table_ttl',
        'default'  => '10d',
    },
    {
        'name'     => 'pidfile_distribute',
        'default'  => Sympa::Constants::PIDDIR . '/sympa-distribute.pid',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'purge_one_time_ticket_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'queuesubscribe',
        'default'  => Sympa::Constants::SPOOLDIR . '/subscribe',
        'query'    => gettext('Directory for subscription spool'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'review_page_size',
        'query'    => gettext('Default number of lines of the array displaying users in the review page'),
        'vhost'    => '1',
        'default'  => 25,
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'sort',
        'default'  => 'fr,ca,be,ch,uk,edu,*,com',
    },
    {
        'name'     => 'spam_status',
        'default'  => 'x-spam-status',
        'query'    => gettext('Messages are supposed to be filtered by an antispam that add one more headers to messages. This parameter is used to select a special scenario in order to decide the message spam status: ham, spam or unsure. This parameter replace antispam_tag_header_name, antispam_tag_header_spam_regexp and antispam_tag_header_ham_regexp.'),
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'ssl_cert_dir',
        'default'  => Sympa::Constants::EXPLDIR . '/X509-user-certs',
        'query'    => gettext('Directory containing user certificates'),
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'task_manager_pidfile',
        'default'  => Sympa::Constants::PIDDIR . '/task_manager.pid',
        'query'    => gettext('File containing task_manager PID while running'),
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'viewlogs_page_size',
        'query'    => gettext('Default number of lines of the array displaying the log entries in the logs page'),
        'vhost'    => '1',
        'default'  => 25,
        'file'     => 'wwsympa.conf',
    },
);

