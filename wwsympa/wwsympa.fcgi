#!--PERL-- -U

# wwsympa.fcgi - This script provides the web interface to Sympa 
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997-2003 Comite Reseau des Universites
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

## Copyright 1999 Comité Réseaux des Universités
## web interface to Sympa mailing lists manager
## Sympa: http://www.sympa.org/

## Authors :
##           Serge Aumont <sa AT cru.fr>
##           Olivier Salaün <os AT cru.fr>

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';
use Getopt::Long;

use strict vars;

## Template parser
require "--LIBDIR--/parser.pl";

## Sympa API
use List;
use mail;
use smtp;
use Conf;
use Commands;
use Language;
use Log;
use Ldap;

use Mail::Header;
use Mail::Address;

require "--LIBDIR--/msg.pl";
require "--LIBDIR--/tools.pl";

## WWSympa librairies
use wwslib;
use cookielib;

my %options;

## Configuration
my $wwsconf = {};

## Change to your wwsympa.conf location
my $conf_file = '--WWSCONFIG--';
my $sympa_conf_file = '--CONFIG--';



my $loop = 0;
my $list;
my $param = {};
my $robot ;
my $ip ; 


## Load config 
unless ($wwsconf = &wwslib::load_config($conf_file)) {
    &fatal_err('Unable to load config file %s', $conf_file);
}

## Load sympa config
unless (&Conf::load( $sympa_conf_file )) {
    &fatal_err('Unable to load sympa config file %s', $sympa_conf_file);
}

$log_level = $Conf{'log_level'} if ($Conf{'log_level'}); 

&mail::set_send_spool($Conf{'queue'});

if ($wwsconf->{'use_fast_cgi'}) {
    require CGI::Fast;
}else {
    require CGI;
}
my $mime_types = &wwslib::load_mime_types();


# hash of all the description files already loaded
# format :
#     $desc_files{pathfile}{'date'} : date of the last load
#     $desc_files{pathfile}{'desc_hash'} : hash which describes
#                         the description file

#%desc_files_map; NOT USED ANYMORE

# hash of the icons linked with a type of file
my %icon_table;

  # application file
$icon_table{'unknown'} = $wwsconf->{'icons_url'}.'/unknown.png';
$icon_table{'folder'} = $wwsconf->{'icons_url'}.'/folder.png';
$icon_table{'current_folder'} = $wwsconf->{'icons_url'}.'/folder.open.png';
$icon_table{'application'} = $wwsconf->{'icons_url'}.'/unknown.png';
$icon_table{'octet-stream'} = $wwsconf->{'icons_url'}.'/binary.png';
$icon_table{'audio'} = $wwsconf->{'icons_url'}.'/sound1.png';
$icon_table{'image'} = $wwsconf->{'icons_url'}.'/image2.png';
$icon_table{'text'} = $wwsconf->{'icons_url'}.'/text.png';
$icon_table{'video'} = $wwsconf->{'icons_url'}.'/movie.png';
$icon_table{'father'} = $wwsconf->{'icons_url'}.'/back.png';
$icon_table{'sort'} = $wwsconf->{'icons_url'}.'/down.png';
$icon_table{'url'} = $wwsconf->{'icons_url'}.'/link.png';
$icon_table{'left'} = $wwsconf->{'icons_url'}.'/left.png';
$icon_table{'right'} = $wwsconf->{'icons_url'}.'/right.png';
## Shared directory and description file

#$shared = 'shared';
#$desc = '.desc';


## subroutines
my %comm = ('home' => 'do_home',
	 'logout' => 'do_logout',
	 'loginrequest' => 'do_loginrequest',
	 'login' => 'do_login',
	 'subscribe' => 'do_subscribe',
	 'subrequest' => 'do_subrequest',
	 'subindex' => 'do_subindex',
	 'suboptions' => 'do_suboptions',
	 'signoff' => 'do_signoff',
	 'sigrequest' => 'do_sigrequest',
	 'ignoresub' => 'do_ignoresub',
	 'which' => 'do_which',
	 'lists' => 'do_lists',
	 'info' => 'do_info',
	 'review' => 'do_review',
	 'search' => 'do_search',
	 'pref', => 'do_pref',
	 'setpref' => 'do_setpref',
	 'setpasswd' => 'do_setpasswd',
	 'remindpasswd' => 'do_remindpasswd',
	 'sendpasswd' => 'do_sendpasswd',
	 'choosepasswd' => 'do_choosepasswd',	
	 'viewfile' => 'do_viewfile',
	 'set' => 'do_set',
	 'admin' => 'do_admin',
	 'add_request' => 'do_add_request',
	 'add' => 'do_add',
	 'del' => 'do_del',
	 'modindex' => 'do_modindex',
	 'reject' => 'do_reject',
	 'reject_notify' => 'do_reject_notify',
	 'distribute' => 'do_distribute',
	 'viewmod' => 'do_viewmod',
	 'editfile' => 'do_editfile',
	 'savefile' => 'do_savefile',
	 'arc' => 'do_arc',
	 'arc_manage' => 'do_arc_manage',                             
	 'remove_arc' => 'do_remove_arc',
	 'send_me' => 'do_send_me',
	 'arcsearch_form' => 'do_arcsearch_form',
	 'arcsearch_id' => 'do_arcsearch_id',
	 'arcsearch' => 'do_arcsearch',
	 'rebuildarc' => 'do_rebuildarc',
	 'rebuildallarc' => 'do_rebuildallarc',
	 'arc_download' => 'do_arc_download',
	 'arc_delete' => 'do_arc_delete',
	 'serveradmin' => 'do_serveradmin',
	 'help' => 'do_help',
	 'edit_list_request' => 'do_edit_list_request',
	 'edit_list' => 'do_edit_list',
	 'create_list_request' => 'do_create_list_request',
	 'create_list' => 'do_create_list',
	 'get_pending_lists' => 'do_get_pending_lists', 
	 'get_closed_lists' => 'do_get_closed_lists', 
	 'get_latest_lists' => 'do_get_latest_lists', 
	 'set_pending_list_request' => 'do_set_pending_list_request', 
	 'install_pending_list' => 'do_install_pending_list', 
	 'submit_list' => 'do_submit_list',
	 'editsubscriber' => 'do_editsubscriber',
	 'viewbounce' => 'do_viewbounce',
	 'rename_list_request' => 'do_rename_list_request',
	 'rename_list' => 'do_rename_list',
	 'reviewbouncing' => 'do_reviewbouncing',
	 'resetbounce' => 'do_resetbounce',
	 'scenario_test' => 'do_scenario_test',
	 'search_list' => 'do_search_list',
	 'show_cert' => 'show_cert',
	 'close_list_request' => 'do_close_list_request',
	 'close_list' => 'do_close_list',
	 'purge_list' => 'do_purge_list',	    
	 'restore_list' => 'do_restore_list',
	 'd_read' => 'do_d_read',
	 'd_create_dir' => 'do_d_create_dir',
	 'd_upload' => 'do_d_upload',   
	 'd_editfile' => 'do_d_editfile',
	 'd_overwrite' => 'do_d_overwrite',
	 'd_savefile' => 'do_d_savefile',
	 'd_describe' => 'do_d_describe',
	 'd_delete' => 'do_d_delete',
	 'd_rename' => 'do_d_rename',   
	 'd_control' => 'do_d_control',
	 'd_change_access' => 'do_d_change_access',
	 'd_set_owner' => 'do_d_set_owner',
	 'd_admin' => 'do_d_admin',
	 'dump' => 'do_dump',
	 'arc_protect' => 'do_arc_protect',
	 'view_translations' => 'do_view_translations',
	 'translate' => 'do_translate',
	 'view_template' => 'do_view_template',
	 'update_translation' => 'do_update_translation',
	 'remind' => 'do_remind',
	 'change_email' => 'do_change_email',
	 'load_cert' => 'do_load_cert',
	 'compose_mail' => 'do_compose_mail',
	 'send_mail' => 'do_send_mail',
	 'search_user' => 'do_search_user',
	 'unify_email' => 'do_unify_email',
	 'record_email' => 'do_record_email',	    
	 'set_lang' => 'do_set_lang',
	 'attach' => 'do_attach',
	 'change_identity' => 'do_change_identity',
	 'stats' => 'do_stats',
	 'viewlogs'=> 'do_viewlogs'
	 );

## Arguments awaited in the PATH_INFO, depending on the action 
my %action_args = ('default' => ['list'],
		'editfile' => ['list','file'],
		'viewfile' => ['list','file'],
		'sendpasswd' => ['email'],
		'choosepasswd' => ['email','passwd'],
		'lists' => ['topic','subtopic'],
		'login' => ['email','passwd','previous_action','previous_list'],
		'loginrequest' => ['previous_action','previous_list'],
		'logout' => ['previous_action','previous_list'],
		'remindpasswd' => ['previous_action','previous_list'],
		'pref' => ['previous_action','previous_list'],
		'reject' => ['list','id'],
		'distribute' => ['list','id'],
		'modindex' => ['list'],
		'viewmod' => ['list','id','file'],
		'viewfile' => ['list','file'],
		'add' => ['list','email'],
		'add_request' => ['list'],
		'del' => ['list','email'],
		'editsubscriber' => ['list','email','previous_action'],
		'viewbounce' => ['list','email'],
		'resetbounce' => ['list','email'],
		'review' => ['list','page','size','sortby'],
		'reviewbouncing' => ['list','page','size'],
		'arc' => ['list','month','arc_file'],
		'arc_manage' => ['list'],                                          
		'arcsearch_form' => ['list','archive_name'],
		'arcsearch_id' => ['list','archive_name','key_word'],
		'rebuildarc' => ['list','month'],
		'rebuildallarc' => [],
		'arc_download' => ['list'],
		'arc_delete' => ['list','zip'],
		'home' => [],
		'help' => ['help_topic'],
		'show_cert' => [],
		'subscribe' => ['list','email','passwd'],
		'subrequest' => ['list','email'],
		'subrequest' => ['list'],
		'subindex' => ['list'],
                'ignoresub' => ['list','@email','@gecos'],
		'signoff' => ['list','email','passwd'],
		'sigrequest' => ['list','email'],
		'set' => ['list','email','reception','gecos'],
		'serveradmin' => [],
		'get_pending_lists' => [],
		'get_closed_lists' => [],
		'get_latest_lists' => [],
		'search_list' => ['filter'],
		'shared' => ['list','@path'],
		'd_read' => ['list','@path'],
		'd_admin' => ['list','d_admin'],
		'd_delete' => ['list','@path'],
		'd_rename' => ['list','@path'],
		'd_create_dir' => ['list','@path'],
		'd_overwrite' => ['list','@path'],
		'd_savefile' => ['list','@path'],
		'd_describe' => ['list','@path'],
		'd_editfile' => ['list','@path'],
		'd_control' => ['list','@path'],
		'd_change_access' =>  ['list','@path'],
		'd_set_owner' =>  ['list','@path'],
		'dump' => ['list'],
		'view_translations' => [],
		'translate' => ['template','lang'],
		'view_template' => ['template','lang'],
		'update_translation' => ['template','lang'],
		'search' => ['list','filter'],
		'search_user' => ['email'],
		'set_lang' => ['lang'],
		'attach' => ['list','dir','file'],
		'change_identity' => ['email','previous_action','previous_list'],
		'edit_list_request' => ['list','group'],
		'rename_list' => ['list','new_list','new_robot'],
#		'viewlogs' => ['list']
		);

my %action_type = ('editfile' => 'admin',
		'review' => 'admin',
		'search' => 'admin',
		'viewfile' => 'admin',
		'admin' => 'admin',
		'add_request' =>'admin',
		'add' =>'admin',
		'del' =>'admin',
		'modindex' =>'admin',
		'reject' =>'admin',
		'reject_notify' =>'admin',
		'add_request' =>'admin',
		'distribute' =>'admin',
		'viewmod' =>'admin',
		'savefile' =>'admin',
		'rebuildarc' =>'admin',
		'rebuildallarc' =>'admin',
		'reviewbouncing' =>'admin',
		'edit_list_request' =>'admin',
		'edit_list' =>'admin',
		'editsubscriber' =>'admin',
		'viewbounce' =>'admin',
		'resetbounce'  =>'admin',
		'scenario_test' =>'admin',
		'close_list_request' =>'admin',
		'close_list' =>'admin',
		'restore_list' => 'admin',
		'd_admin' => 'admin',
		'dump' => 'admin',
		'remind' => 'admin',
		'subindex' => 'admin',
		'stats' => 'admin',
		'ignoresub' => 'admin',
		'rename_list' => 'admin',
		'rename_list_request' => 'admin',
		'arc_manage' => 'admin',
#		'viewlogs' => 'admin'
);

## Open log
$wwsconf->{'log_facility'}||= $Conf{'syslog'};

&Log::do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'wwsympa');
&do_log('info', 'WWSympa started');

## Set locale configuration
$Language::default_lang = $Conf{'lang'};
&Language::LoadLang($Conf{'msgcat'});

unless ($List::use_db = &List::probe_db()) {
    &error_message('no_database');
    &do_log('info','WWSympa requires a RDBMS to run');
}

my $pinfo = &List::_apply_defaults();

&tools::ciphersaber_installed();

my $zip_is_installed ;
if (require Archive::Zip) {
    $zip_is_installed = 1;
}

%::changed_params;

my (%in, $query);

my $birthday = time ;

## If using fast_cgi, it is usefull to initialize all list context
if ($wwsconf->{'use_fast_cgi'}) {

    foreach my $l ( &List::get_lists('*') ) {
	my $list = new List ($l);
    }
}

 ## Main loop
 my $loop_count;
 my $start_time = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));
 while ($query = &new_loop()) {

     undef $param;
     undef $list;
     undef $robot;
     undef $ip;

     undef $log_level;
     $log_level = $Conf{'log_level'} if ($Conf{'log_level'}); 
     $log_level |= 0;

     &Language::SetLang($Language::default_lang);

     ## Get params in a hash
 #    foreach ($query->param) {
 #	$in{$_} = $query->param($_);
 #    }
     %in = $query->Vars;

     foreach my $k (keys %::changed_params) {
	 &do_log('debug3', 'Changed Param: %s', $k);
     }

     ## Free terminated sendmail processes
 #    &smtp::reaper;

     ## Parse CGI parameters
 #    &CGI::ReadParse();

     ## Get PATH_INFO parameters
     &get_parameters();

     if (defined $Conf{'robot_by_http_host'}{$ENV{'SERVER_NAME'}}) {
	 my ($selected_robot, $selected_path);
	 my ($k,$v);
	 while (($k, $v) = each %{$Conf{'robot_by_http_host'}{$ENV{'SERVER_NAME'}}}) {
	     if ($ENV{'REQUEST_URI'} =~ /^$k/) {
		 ## Longer path wins
		 if (length($k) > length($selected_path)) {
		     ($selected_robot, $selected_path) = ($v, $k);
		 }
	     }
	 }
	 $robot = $selected_robot;
     }
     
     $robot = $Conf{'host'} unless $robot;
 
     $param->{'cookie_domain'} = $Conf{'robots'}{$robot}{'cookie_domain'} if $Conf{'robots'}{$robot};
     $param->{'cookie_domain'} ||= $wwsconf->{'cookie_domain'};
     $ip = $ENV{'REMOTE_HOST'};
     $ip = $ENV{'REMOTE_ADDR'} unless ($ip);
     $ip = 'undef' unless ($ip);
      ## In case HTTP_HOST does not match cookie_domain
     my $http_host = $ENV{'HTTP_HOST'};
     $http_host =~ s/:\d+$//; ## suppress port
     unless (($http_host =~ /$param->{'cookie_domain'}$/) || 
	     ($param->{'cookie_domain'} eq 'localhost')) {
	 &wwslog('notice', 'Cookie_domain(%s) does NOT match HTTP_HOST; setting cookie_domain to %s', $param->{'cookie_domain'}, $http_host);
	 $param->{'cookie_domain'} = $http_host;
     }

     $log_level = $Conf{'robots'}{$robot}{'log_level'};

     ## Sympa parameters in $param->{'conf'}
     if (defined $Conf{'robots'}{$robot}) {
	 $param->{'conf'} = {'email' => $Conf{'robots'}{$robot}{'email'},
			     'host' =>  $Conf{'robots'}{$robot}{'host'},
			     'sympa' => $Conf{'robots'}{$robot}{'sympa'},
			     'request' => $Conf{'robots'}{$robot}{'request'}
			 };
     }else {
	 $param->{'conf'} = {'email' => $Conf{'email'},
			     'host' =>  $Conf{'host'},
			     'sympa' => $Conf{'sympa'},
			     'request' => $Conf{'request'}
			 };
     }
     $param->{'wwsconf'} = $wwsconf;

     foreach my $p ('dark_color','light_color','text_color','bg_color','error_color',
		    'selected_color','shaded_color') { 
	 $param->{$p} = &Conf::get_robot_conf($robot, $p);
     }

     $param->{'path_cgi'} = $ENV{'SCRIPT_NAME'};
     $param->{'version'} = $Version::Version;
     $param->{'date'} = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));

     ## Change to list root
     unless (chdir($Conf{'home'})) {
	 &error_message('chdir_error');
	 &wwslog('info','unable to change directory');
	 exit (-1);
     }

     ## Sets the UMASK
     umask(oct($Conf{'umask'}));

     ## Authentication 
     ## use https client certificat information if define.  

     ## Compatibility issue with old a-sign.at certs
     if (!$ENV{'SSL_CLIENT_S_DN_Email'} && 
	 $ENV{'SSL_CLIENT_S_DN'} =~ /\+MAIL=([^\+\/]+)$/) {
	 $ENV{'SSL_CLIENT_S_DN_Email'} = $1;
      }

     if (($ENV{'SSL_CLIENT_S_DN_Email'}) && ($ENV{'SSL_CLIENT_VERIFY'} eq 'SUCCESS')) {
	 $param->{'user'}{'email'} = lc($ENV{'SSL_CLIENT_S_DN_Email'});
	 $param->{'auth_method'} = 'smime';
	 $param->{'ssl_client_s_dn'} = $ENV{'SSL_CLIENT_S_DN'};
	 $param->{'ssl_client_v_end'} = $ENV{'SSL_CLIENT_V_END'};
	 $param->{'ssl_client_i_dn'} =  $ENV{'SSL_CLIENT_I_DN'};
	 $param->{'ssl_cipher_usekeysize'} =  $ENV{'SSL_CIPHER_USEKEYSIZE'};

     }elsif ($ENV{'HTTP_COOKIE'} =~ /(user|sympauser)\=/) {
	 $param->{'user'}{'email'} = &wwslib::get_email_from_cookie($Conf{'cookie'});
	 $param->{'auth_method'} = 'md5';
     }else{
	 ## request action need a auth_method even if the user is not authenticated ...
	 $param->{'auth_method'} = 'md5';
     }


     ##Cookie extern : sympa_altemails
     ## !!
     $param->{'alt_emails'} = &cookielib::check_cookie_extern($ENV{'HTTP_COOKIE'},$Conf{'cookie'},$param->{'user'}{'email'});

     if ($param->{'user'}{'email'}) {
	 $param->{'auth'} = $param->{'alt_emails'}{$param->{'user'}{'email'}} || 'classic';

	 if (&List::is_user_db($param->{'user'}{'email'})) {
	     $param->{'user'} = &List::get_user_db($param->{'user'}{'email'});
	 }

	 ## For the parser to display an empty field instead of [xxx]
	 $param->{'user'}{'gecos'} ||= '';
	 unless (defined $param->{'user'}{'cookie_delay'}) {
	     $param->{'user'}{'cookie_delay'} = $wwsconf->{'cookie_expire'};
	 }
	 ## get subscrition using cookie and set param for use in templates
	 @{$param->{'get_which'}}  =  &cookielib::get_which_cookie($ENV{'HTTP_COOKIE'});

	 # if no cookie was received, look for subscriptions
	 unless (defined $param->{'get_which'}) {
	     @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') ; 
	 }

     }else{

	 ## Get lang from cookie
	 $param->{'cookie_lang'} = &cookielib::check_lang_cookie($ENV{'HTTP_COOKIE'});
     }

     ## Action
     my $action = $in{'action'};
     $action ||= $Conf{'robots'}{$robot}{'default_home'}
     if ($Conf{'robots'}{$robot});
     $action ||= $wwsconf->{'default_home'} ;
 #    $param->{'lang'} = $param->{'user'}{'lang'} || $Conf{'lang'};
     $param->{'remote_addr'} = $ENV{'REMOTE_ADDR'} ;
     $param->{'remote_host'} = $ENV{'REMOTE_HOST'};

     &export_topics ($robot);
     # if ($wwsconf->{'export_topics'} =~ /all/i);

     &List::init_list_cache();

     ## Session loop
     while ($action) {
	 unless (&check_param_in()) {
	     &error_message('wrong_param');
	     &wwslog('info','Wrong parameters');
	     last;
	 }

	 $param->{'host'} = $list->{'admin'}{'host'} || $robot;
	 $param->{'domain'} = $param->{'host'};

	 ## language ( $ENV{'HTTP_ACCEPT_LANGUAGE'} not used !)

	 $param->{'lang'} = $param->{'cookie_lang'} || $param->{'user'}{'lang'} || $list->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');
	 &Language::SetLang($param->{'lang'});
	 &POSIX::setlocale(&POSIX::LC_ALL, Msg(14, 1, 'en_US'));

	 ## use default_home parameter
	 if ($action eq 'home') {
	     $action = $Conf{'robots'}{$robot}{'default_home'} || $wwsconf->{'default_home'};

	     if (! &tools::get_filename('etc', 'topics.conf', $robot) &&
		 ($action eq 'home')) {
		 $action = 'lists';
	     }
	 }

	 unless ($comm{$action}) {
	     &error_message('unknown_action');
	     &wwslog('info','unknown action %s', $action);
	     last;
	 }

	 $param->{'action'} = $action;

	 my $old_action = $action;

	 ## Execute the action ## 
	 $action = &{$comm{$action}}();

	 delete($param->{'action'}) if (! defined $action);

	 if ($action eq $old_action) {
	     &wwslog('info','Stopping loop with %s action', $action);
	     #undef $action;
	     $action = 'home';
	 }

	 undef $action if ($action == 1);
     }

     ## Prepare outgoing params
     &check_param_out();


     ## Params 
     $param->{'action_type'} = $action_type{$param->{'action'}};
     $param->{'action_type'} = 'none' unless ($param->{'is_priv'});

     if ($param->{'list'}) {
	 $param->{'title'} = "$param->{'list'}\@$list->{'admin'}{'host'}";
     }else {
	 $param->{'title'} = $Conf{'robots'}{$robot}{'title'};
	 $param->{'title'} = $wwsconf->{'title'} unless $param->{'title'};
     }

     ## Set cookies "your_subscribtions"
     if ($param->{'user'}{'email'}) {
	 # if at least one element defined in get_which tab
	 &cookielib::set_which_cookie ($wwsconf->{'cookie_domain'},@{$param->{'get_which'}});

	 ## Add lists information to 'which_info'
	 foreach my $l (@{$param->{'get_which'}}) {
	     my $list = new List ($l);
	     $param->{'which_info'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'which_info'}{$l}{'host'} = $list->{'admin'}{'host'};
	     $param->{'which_info'}{$l}{'info'} = 1;
	 }
     }
     ## Set cookies unless client use https authentication
     unless (($ENV{'SSL_CLIENT_S_DN_Email'}) && ($ENV{'SSL_CLIENT_VERIFY'} eq 'SUCCESS')) {
	 if ($param->{'user'}{'email'}) {
	     my $delay = $param->{'user'}{'cookie_delay'};
	     unless (defined $delay) {
		 $delay = $wwsconf->{'cookie_expire'};
	     }

	     if ($delay == 0) {
		 $delay = 'session';
	     }

	     unless (&cookielib::set_cookie($param->{'user'}{'email'}, $Conf{'cookie'}, $param->{'cookie_domain'},$delay )) {
		 &wwslog('notice', 'Could not set HTTP cookie');
		 exit -1;
	     }
	     $param->{'cookie_set'} = 1;

	     ##Cookie extern : sympa_altemails
	     my $number = 0;
	     foreach my $element (keys %{$param->{'alt_emails'}}){
		  $number ++ if ($element);
	     }  
	     $param->{'unique'} = 1 if($number <= 1);

	     unless(&cookielib::set_cookie_extern($Conf{'cookie'},$param->{'cookie_domain'},%{$param->{'alt_emails'}})){
		  &wwslog('notice', 'Could not set HTTP cookie for external_auth');
		  exit -1;
	     }

	 }elsif ($ENV{'HTTP_COOKIE'} =~ /sympauser\=/){
	     &cookielib::set_cookie('unknown', $Conf{'cookie'}, $param->{'cookie_domain'}, 'now');
	 }
     }

     ## Available languages
     my $saved_lang = &Language::GetLang();
     foreach my $l (@wwslib::languages) {
	 &Language::SetLang($l);
	 $param->{'languages'}{$l}{'complete'} = sprintf Msg(14, 2, $l);
	 if ($param->{'lang'} eq $l) {
	     $param->{'languages'}{$l}{'selected'} = 'SELECTED';
	 }else {
	     $param->{'languages'}{$l}{'selected'} = '';
	 }
     }
     &Language::SetLang($saved_lang);
     # if bypass is defined select the content-type from various vars
     if ($param->{'bypass'}) {

	## if bypass = 'extreme' leave the action send the content-type
	unless ($param->{'bypass'} eq 'extreme') {

	     ## if bypass = 'asis', file content-type is in the file itself as is define by the action in $param->{'content_type'};
	     unless ($param->{'bypass'} eq 'asis') {
		 $mime_types->{$param->{'file_extension'}} ||= $param->{'content_type'};
		 $mime_types->{$param->{'file_extension'}} ||= 'application/octet-stream';
		 printf "Content-Type: %s\n\n", $mime_types->{$param->{'file_extension'}};
	     }

	     #  $param->{'file'} or $param->{'error'} must be define in this case.

	     if (open (FILE, $param->{'file'})){
		 print <FILE>;
		 close FILE;
	     }elsif($param->{'error_msg'}){
		 printf "$param->{'error_msg'}\n";
	     }else{
		 printf "Internal error content-type nor file defined\n";
		 &do_log('err', 'Internal error content-type nor file defined');
	     }
	 }

     }elsif ($param->{'redirect_to'}) {
	 print "Location: $param->{'redirect_to'}\n\n";
     }else {
	 ## Send HTML
	 print "Cache-control: no-cache\n";
	 print "Content-Type: text/html\n\n";

	 ## Icons
	 $param->{'icons_url'} = $wwsconf->{'icons_url'};


	 ## Retro compatibility concerns
	 $param->{'active'} = 1;

	 ## Action template
	 if (defined $param->{'action'}) {
	     $param->{'action_template'} = &tools::get_filename('etc', "wws_templates/$param->{'action'}.$param->{'lang'}.tpl", $robot,$list);
	     unless ($param->{'action_template'})  {
		 &error_message('template_error');
		 &do_log('info',"unable to find template for $param->{'action'}");
	     }
	 }

	 ## Menu template
	 $param->{'menu_template'} = &tools::get_filename('etc', "wws_templates/menu.$param->{'lang'}.tpl", $robot,$list);
	 unless ($param->{'menu_template'})  {
	     &error_message('template_error');
	     &do_log('info','unable to find menu template');
	 }

	 ## List_menu template
	 $param->{'list_menu_template'} = &tools::get_filename('etc', "wws_templates/list_menu.$param->{'lang'}.tpl", $robot,$list);

	 unless ($param->{'list_menu_template'})  {
	     &error_message('template_error');
	     &do_log('info','unable to find list_menu template');
	 }

	 ## admin_menu template
	 $param->{'admin_menu_template'} = &tools::get_filename('etc', "wws_templates/admin_menu.$param->{'lang'}.tpl", $robot,$list);

	 unless ($param->{'admin_menu_template'})  {
	     &error_message('template_error');
	     &do_log('info','unable to find admin_menu template');
	 }

	 ## Title template
	 $param->{'title_template'} = &tools::get_filename('etc', "wws_templates/title.$param->{'lang'}.tpl", $robot,$list);

	 unless ($param->{'title_template'})  {
	     &error_message('template_error');
	     &do_log('info','unable to find title template');
	 }

	 ## Error template
	 $param->{'error_template'} = &tools::get_filename('etc', "wws_templates/error.$param->{'lang'}.tpl", $robot,$list);

	 unless ($param->{'error_template'})  {
	     &error_message('template_error');
	     &do_log('info','unable to find error template');
	 }

	 ## Notice template
	 $param->{'notice_template'} = &tools::get_filename('etc', "wws_templates/notice.$param->{'lang'}.tpl", $robot,$list);

	 unless ($param->{'notice_template'})  {
	     &error_message('template_error');
	     &do_log('info','unable to find notice template');
	 }

	 ## Help template
	 $param->{'help_template'} = &tools::get_filename('etc', "wws_templates/help_$param->{'help_topic'}.$param->{'lang'}.tpl", $robot,$list);

	 ## main template
	 my $main = &tools::get_filename('etc', "wws_templates/main.$param->{'lang'}.tpl", $robot,$list);;

	 unless ($main)  {
	     &error_message('template_error');
	     &do_log('info','unable to find main template');
	 }

	 if (defined $list) {
	     $param->{'list_conf'} = $list->{'admin'};
	 }

	 &parser::parse_tpl($param,$main , \*STDOUT);
     }    

     # exit if wwsympa.fcgi itself has changed
     if ((stat($ENV{'SCRIPT_FILENAME'}))[9] > $birthday ) {
	  do_log('notice',"Exiting because $ENV{'SCRIPT_FILENAME'} has changed since fastcgi server started");
	  exit(0);
     }

     # At the end of this loop reset variables is important to use this cgi as a CGI::fast 
     undef $param ; 
     undef %::changed_params;

 }

 ##############################################################
 #-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/
 ##############################################################


 ## Write to log
 sub wwslog {
     my $facility = shift;
     my $msg = shift;

     my $remote = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

     $msg = "[list $param->{'list'}] " . $msg
	 if $param->{'list'};

     if ($param->{'alt_emails'}) {
	 my @alts;
	 foreach my $alt (keys %{$param->{'alt_emails'}}) {
	     push @alts, $alt
		 unless ($alt eq $param->{'user'}{'email'});
	 }

	 if ($#alts >= 0) {
	     my $alt_list = join ',', @alts;
	     $msg = "[alt $alt_list] " . $msg;
	 }
     }

     $msg = "[user $param->{'user'}{'email'}] " . $msg
	 if $param->{'user'}{'email'};

     $msg = "[client $remote] ".$msg
	 if $remote;

     return &Log::do_log($facility, $msg, @_);
 }

 ## Return an error message to the client
 sub error_message {
     my ($msg, $data) = @_;

     $data ||= {};

     $data->{'action'} = $param->{'action'};
     $data->{'msg'} = $msg;

     push @{$param->{'errors'}}, $data;

     ## For compatibility
     $param->{'error_msg'} ||= $msg;

 }

 ## Return a message to the client
 sub message {
     my ($msg, $data) = @_;

     $data ||= {};

     $data->{'action'} = $param->{'action'};
     $data->{'msg'} = $msg;

     push @{$param->{'notices'}}, $data;

 }

 sub new_loop {
     $loop++;
     my $query;

     if ($wwsconf->{'use_fast_cgi'}) {
	 $query = new CGI::Fast;
	 $loop_count++;
     }else {	
	 return undef if ($loop > 1);

	 $query = new CGI;
     }

     return $query;
 }

 sub get_parameters {
 #    &wwslog('debug4', 'get_parameters');

     ## CGI URL
     if ($ENV{'HTTPS'} eq 'on') {
	 $param->{'base_url'} = sprintf 'https://%s', $ENV{'HTTP_HOST'};
	 $param->{'use_ssl'} = 1;
     }else {
	 $param->{'base_url'} = sprintf 'http://%s', $ENV{'HTTP_HOST'};
	 $param->{'use_ssl'} = 0;
     }

     $param->{'path_info'} = $ENV{'PATH_INFO'};
     $param->{'robot_domain'} = $wwsconf->{'robot_domain'}{$ENV{'SERVER_NAME'}};


     if ($ENV{'REQUEST_METHOD'} eq 'GET') {
	 my $path_info = $ENV{'PATH_INFO'};
	 &do_log('debug2', "PATH_INFO: %s",$ENV{'PATH_INFO'});

	 $path_info =~ s+^/++;

	 my $ending_slash = 0;
	 if ($path_info =~ /\/$/) {
	     $ending_slash = 1;
	 }

	 my @params = split /\//, $path_info;

 #	foreach my $i(0..$#params) {
 #	    $params[$i] = &tools::unescape_chars($params[$i]);
 #	}

	 if ($params[0] eq 'nomenu') {
	     $param->{'nomenu'} = 1;
	     shift @params;
	 }

	 ## debug mode
	 if ($params[0] =~ /debug(\d)?/) {
	     shift @params;
	     if ($1) { 
		 $main::options{'debug_level'} = $1 if ($1);
	     }else{
		 $main::options{'debug_level'} = 1 ;
	     }
	 }else{
	     $main::options{'debug_level'} = 0 ;
	 } 
	 do_log ('debug2', "debug level $main::options{'debug_level'}");

	 if ($#params >= 0) {
	     $in{'action'} = $params[0];

	     my $args;
	     if ($action_args{$in{'action'}}) {
		 $args = $action_args{$in{'action'}};
	     }else {
		 $args = $action_args{'default'};
	     }

	     my $i = 1;
	     foreach my $p (@$args) {
		 my $pname;
		 ## More than 1 param
		 if ($p =~ /^\@(\w+)$/) {
		     $pname = $1;

		     $in{$pname} = join '/', @params[$i..$#params];
		     $in{$pname} .= '/' if $ending_slash;
		     last;
		 }else {
		     $pname = $p;
		     $in{$pname} = $params[$i];
		 }
		 $i++;
	     }
	 }
     }elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
	 ## POST
	 foreach my $p (keys %in) {
	     if ($p =~ /^action_(\w+)((\.\w+)*)$/) {
		 
		 $in{'action'} = $1;
		 if ($2) {
		     foreach my $v (split /\./, $2) {
			 $v =~ s/^\.?(\w+)\.?/$1/;
			 $in{$v} = 1;
		     }
		 }

		 undef $in{$p};
	     }
	 }

	 $param->{'nomenu'} = $in{'nomenu'};
     }	

     ## Lowercase email addresses
     $in{'email'} = lc ($in{'email'});

     ## Don't get multiple listnames
     if ($in{'list'}) {
	 my @lists = split /\0/, $in{'list'};
	 $in{'list'} = $lists[0];
     }

     return 1;
 }

 ## Analysis of incoming parameters
 sub check_param_in {
     &wwslog('debug2', 'check_param');

     ## Lowercase list name
     $in{'list'} =~ tr/A-Z/a-z/;

     ## In case the variable was multiple
     if ($in{'list'} =~ /^(\S+)\0/) {
	 $in{'list'} = $1;

	 unless ($list = new List ($in{'list'}, $robot)) {
	     &error_message('unknown_list', {'list' => $in{'list'}} );
	     &wwslog('info','check_param: unknown list %s', $in{'list'});
	     return undef;
	 }
     }

     ## listmaster has owner and editor privileges for the list
     if (&List::is_listmaster($param->{'user'}{'email'},$robot)) {
	 $param->{'is_listmaster'} = 1;
     }

    if ($in{'list'}) {
	unless ($list = new List ($in{'list'}, $robot)) {
	    &error_message('unknown_list', {'list' => $in{'list'}} );
	    &wwslog('info','check_param: unknown list %s', $in{'list'});
	    return undef;
	}

	$param->{'list'} = $in{'list'};
	$param->{'subtitle'} = $list->{'admin'}{'subject'};
	$param->{'subscribe'} = $list->{'admin'}{'subscribe'}{'name'};
	$param->{'send'} = $list->{'admin'}{'send'}{'title'}{$param->{'lang'}};
	$param->{'total'} = $list->get_total('nocache');
	$param->{'list_as_x509_cert'} = $list->{'as_x509_cert'};
	$param->{'listconf'} = $list->{'admin'};

	## privileges
	if ($param->{'user'}{'email'}) {
	    $param->{'is_subscriber'} = $list->is_user($param->{'user'}{'email'});
	    $param->{'subscriber'} = $list->get_subscriber($param->{'user'}{'email'})
		if $param->{'is_subscriber'};
	    $param->{'is_privileged_owner'} = $param->{'is_listmaster'} || $list->am_i('privileged_owner', $param->{'user'}{'email'});
	    $param->{'is_owner'} = $param->{'is_privileged_owner'} || $list->am_i('owner', $param->{'user'}{'email'});
	    $param->{'is_editor'} = $list->am_i('editor', $param->{'user'}{'email'});
	    $param->{'is_priv'} = $param->{'is_owner'} || $param->{'is_editor'};

	    ## If user is identified
	    $param->{'may_post'} = 1;
	}

	$param->{'is_moderated'} = $list->is_moderated();

	## Privileged info
	if ($param->{'is_priv'}) {
	    $param->{'mod_total'} = $list->get_mod_spool_size();
	    if ($param->{'total'} > 0) {
		$param->{'bounce_total'} = $list->get_total_bouncing();
		$param->{'bounce_rate'} = $param->{'bounce_total'} * 100 / $param->{'total'};
		$param->{'bounce_rate'} = int ($param->{'bounce_rate'} * 10) / 10;
	    }else {
		$param->{'bounce_rate'} = 0;
	    }
	}

	## (Un)Subscribing 
	if ($list->{'admin'}{'user_data_source'} eq 'include') {
	    $param->{'may_signoff'} = $param->{'may_suboptions'} = $param->{'may_subscribe'} = 0;
	}else {
	    unless ($param->{'user'}{'email'}) {
		$param->{'may_subscribe'} = $param->{'may_signoff'} = 1;

	    }else {
		if ($param->{'is_subscriber'} &&
		    ($param->{'subscriber'}{'subscribed'} == 1)) {
		    ## May signoff
		    $main::action = &List::request_action ('unsubscribe',$param->{'auth_method'},$robot,
						     {'listname' =>$param->{'list'}, 
						      'sender' =>$param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'}});

		    $param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner/);
		    $param->{'may_suboptions'} = 1;

		}else {

		    ## May Subscribe
		    $main::action = &List::request_action ('subscribe',$param->{'auth_method'},$robot,
						     {'listname' => $param->{'list'}, 
						      'sender' => $param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'}});

		    $param->{'may_subscribe'} = 1 if ($main::action =~ /do_it|owner/);
		}
	    }
	}

	## Shared documents
	my %mode;
	$mode{'read'} = 1;
	my %access = &d_access_control(\%mode,"");
	$param->{'may_d_read'} = $access{'may'}{'read'};

	if (-e $list->{'dir'}.'/shared') {
	    $param->{'shared'}='exist';
	}elsif (-e $list->{'dir'}.'/pending.shared') {
	    $param->{'shared'}='deleted';
	}else{
	    $param->{'shared'}='none';
	}
    }

     if ($param->{'user'}{'email'} && 
	 (($param->{'create_list'} = &List::request_action ('create_list',$param->{'auth_method'},$robot,
							    {'sender' => $param->{'user'}{'email'},
							     'remote_host' => $param->{'remote_host'},
							     'remote_addr' => $param->{'remote_addr'}})) =~ /do_it|listmaster/)) {
	 $param->{'may_create_list'} = 1;
     }else{
	 undef ($param->{'may_create_list'});
     }

     return 1;

 }

 ## Prepare outgoing params
 sub check_param_out {
     &wwslog('debug2', 'check_param');

     $param->{'loop_count'} = $loop_count;
     $param->{'start_time'} = $start_time;
     $param->{'process_id'} = $$;

     if ($list->{'name'}) {
	 ## Owners
	 foreach my $o (@{$list->{'admin'}{'owner'}}) {
	     next unless $o->{'email'};

	     $param->{'owner'}{$o->{'email'}}{'gecos'} = $o->{'gecos'};
	     $param->{'owner'}{$o->{'email'}}{mailto} = &mailto($list,$o->{'email'},$o->{'gecos'});
	     ($param->{'owner'}{$o->{'email'}}{'local'},$param->{'owner'}{$o->{'email'}}{'domain'}) = split ('@',$o->{'email'});
	     my $masked_email = $o->{'email'};
	     $masked_email =~ s/\@/ AT /;
	     $param->{'owner'}{$o->{'email'}}{'masked_email'} = $masked_email;
	 }

	 ## Editors
	 foreach my $e (@{$list->{'admin'}{'editor'}}) {
	     next unless $e->{'email'};
	     $param->{'editor'}{$e->{'email'}}{'gecos'} = $e->{'gecos'};
	     $param->{'editor'}{$e->{'email'}}{mailto} = &mailto($list,$e->{'email'},$e->{'gecos'});
	     ($param->{'editor'}{$e->{'email'}}{'local'},$param->{'editor'}{$e->{'email'}}{'domain'}) = split ('@',$e->{'email'});
	     my $masked_email = $e->{'email'};
	     $masked_email =~ s/\@/ AT /;
	     $param->{'editor'}{$e->{'email'}}{'masked_email'} = $masked_email;
	 }  

	## privileges
	if ($param->{'user'}{'email'}) {
	    $param->{'is_subscriber'} = $list->is_user($param->{'user'}{'email'});
	    $param->{'subscriber'} = $list->get_subscriber($param->{'user'}{'email'})
		if $param->{'is_subscriber'};
	    $param->{'is_privileged_owner'} = $param->{'is_listmaster'} || $list->am_i('privileged_owner', $param->{'user'}{'email'});
	    $param->{'is_owner'} = $param->{'is_privileged_owner'} || $list->am_i('owner', $param->{'user'}{'email'});
	    $param->{'is_editor'} = $list->am_i('editor', $param->{'user'}{'email'});
	    $param->{'is_priv'} = $param->{'is_owner'} || $param->{'is_editor'};

	    ## If user is identified
	    $param->{'may_post'} = 1;
	}

	 ## Should Not be used anymore ##
	 $param->{'may_subunsub'} = 1 
	     if ($param->{'may_signoff'} || $param->{'may_subscribe'});

	 ## May review
	 my $action = &List::request_action ('review',$param->{'auth_method'},$robot,
					     {'listname' => $param->{'list'},
					      'sender' => $param->{'user'}{'email'},
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}});

	 $param->{'may_suboptions'} = 1 unless ($list->{'admin'}{'user_data_source'} eq 'include');
	 $param->{'total'} = $list->get_total();
	 $param->{'may_review'} = 1 if ($action =~ /do_it/);

	## (Un)Subscribing 
	if ($list->{'admin'}{'user_data_source'} eq 'include') {
	    $param->{'may_signoff'} = $param->{'may_suboptions'} = $param->{'may_subscribe'} = 0;
	}else {
	    unless ($param->{'user'}{'email'}) {
		$param->{'may_subscribe'} = $param->{'may_signoff'} = 1;

	    }else {
		if ($param->{'is_subscriber'} &&
		    ($param->{'subscriber'}{'subscribed'} == 1)) {
		    ## May signoff
		    $main::action = &List::request_action ('unsubscribe',$param->{'auth_method'},$robot,
						     {'listname' =>$param->{'list'}, 
						      'sender' =>$param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'}});

		    $param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner/);
		    $param->{'may_suboptions'} = 1;

		}else {

		    ## May Subscribe
		    $main::action = &List::request_action ('subscribe',$param->{'auth_method'},$robot,
						     {'listname' => $param->{'list'}, 
						      'sender' => $param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'}});

		    $param->{'may_subscribe'} = 1 if ($main::action =~ /do_it|owner/);
		}
	    }
	}

	 ## Archives Access control
	 if (defined $list->{'admin'}{'web_archive'}) {
	     $param->{'is_archived'} = 1;

	     if (&List::request_action ('web_archive.access',$param->{'auth_method'},$robot,
					{'listname' => $param->{'list'},
					 'sender' => $param->{'user'}{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
		 $param->{'arc_access'} = 1; 
	     }else{
		 undef ($param->{'arc_access'});
	     }
	 }	
     }    
 }

 ## Login WWSympa
 sub do_login {
     &wwslog('info', 'do_login(%s)', $in{'email'});
     my $user;
     my $next_action;

     if ($param->{'user'}{'email'}) {
	 &error_message('already_login', {'email' => $param->{'user'}{'email'}});
	 &wwslog('info','do_login: user %s already logged in', $param->{'user'}{'email'});
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'login','',$robot,'','already logged');
	 return 'home';
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_login: no email');
	 # &List::db_log('wwsympa','nobody',$param->{'auth_method'},$ip,'login','',$robot,'','no email');
	 return 'home';
     }

     unless ($in{'passwd'}) {
	 my $url_redirect;
	 #Does the email belongs to an ldap directory?
	 if($url_redirect = &is_ldap_user($in{'email'})){
	     $param->{'redirect_to'} = $url_redirect
		 if ($url_redirect && ($url_redirect != 1));
	 }elsif ($in{'failure_referer'}) {
	     $param->{'redirect_to'} = $in{'failure_referer'};	    
	 }else{
	     $in{'init_email'} = $in{'email'};
	     $param->{'init_email'} = $in{'email'};
	     $param->{'escaped_init_email'} = &tools::escape_chars($in{'email'});
	     return $in{'failure_referer'}||'loginrequest';
	 }
     }

     ##authentication of the sender
     unless($param->{'user'} = &check_auth($in{'email'},$in{'passwd'})){
	 &error_message('failed');
	 # &List::db_log('wwsympa',$in{'email'},'null',$ip,'login','',$robot,'','failed');
	 do_log('notice', "Authentication failed\n");
	 if ($in{'previous_action'}) {
	     delete $in{'passwd'};
	     $in{'list'} = $in{'previous_list'};
	     return  $in{'previous_action'};
	 }elsif ($in{'failure_referer'}) {
	     $param->{'redirect_to'} = $in{'failure_referer'};	    
	 }else {
	     return  'loginrequest';
	 }
     } 
     # &List::db_log('wwsympa',$in{'email'},'null',$ip,'login','',$robot,'','done');

     my $email = lc($param->{'user'}{'email'});
     unless($param->{'alt_emails'}{$email}){
	 unless(&cookielib::set_cookie_extern($Conf{'cookie'},$param->{'cookie_domain'},%{$param->{'alt_emails'}})){
	     # &List::db_log('wwsympa',$email,'null',$ip,'login','',$robot,'','Could not set cookie');
	     &wwslog('notice', 'Could not set HTTP cookie for external_auth');
	     return undef;
	 }
     }

     ##

     ## Current authentication mode
     $param->{'auth'} = $param->{'alt_emails'}{$param->{'user'}{'email'}} || 'classic';

     $param->{'lang'} = $user->{'lang'} || $list->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');
     $param->{'cookie_lang'} = undef;    

     if (($param->{'auth'} eq 'classic') && ($param->{'user'}{'password'} =~ /^init/) ) {
	 &message('you_should_choose_a_password');
     }

     if ($in{'newpasswd1'} && $in{'newpasswd2'}) {
	 my $old_action = $param->{'action'};
	 $param->{'action'} = 'setpasswd';
	 &do_setpasswd();
	 $param->{'action'} = $old_action;
     }

     if ($in{'referer'}) {
	 $param->{'redirect_to'} = &tools::unescape_chars($in{'referer'});
     }elsif ($in{'previous_action'}) {
	 $next_action = $in{'previous_action'};
	 $in{'list'} = $in{'previous_list'};
     }else {
	 $next_action = 'home';
     }

     if ($param->{'nomenu'}) {
	 $param->{'back_to_mom'} = 1;
	 return 1;
     }

     return $next_action;

 }

 ## authentication : via email or uid
 sub check_auth{
     my ($canonic, $user);
     my $auth = shift; ## User email or UID
     my $pwd = shift; ## Password

     if( &tools::valid_email($auth)) {
	 return &authentication($auth,$pwd);

     }else{
	 ## This is an UID
	 if ($canonic = &ldap_authentication($auth,$pwd,'uid_filter')){
	     $param->{'auth'} = 'ldap';   
	     $param->{'alt_emails'}{$canonic} = 'ldap' if($canonic);

	     unless($user = &List::get_user_db($canonic)){
		 $user = {'email' => $canonic};
	     }
	     return $user;

	 }else{
	     &error_message('incorrect_passwd');
	     &wwslog('notice', "Incorrect Ldap password");
	     return undef;
	 }
     }
 }

 ## Email authentication:unless you are in User_table,you may belong to the ldap directory

 sub authentication{

     my ($email,$pwd) = @_;
     my ($user,$canonic);

     unless ($user = &List::get_user_db($email)) {
	 $user = {'email' => $email,
		  'password' => &tools::tmp_passwd($email)
		  };
     }    
     unless ($user->{'password'}) {
	 $user->{'password'} = &tools::tmp_passwd($email);
     }

     ## Password in DB is case-insensitive
     if((($wwsconf->{'password_case'} eq 'insensitive') && (lc($pwd) eq lc($user->{'password'})))
	|| ($pwd eq $user->{'password'})) {
	 $param->{'auth'} = 'classic';
	 $param->{'alt_emails'}{$email} = 'classic' if($email);
	 return $user;

     }elsif($canonic = &ldap_authentication($email,$pwd,'email_filter')){

	 $param->{'auth'} = 'ldap';
	 unless($user = &List::get_user_db($canonic)){
	     $user = {'email' => $canonic};
	 }
	 $param->{'alt_emails'}{$canonic} = 'ldap';
	 return $user;
     }else{

	 if ($user->{'password'} =~ /^init/i) {
	     &error_message('init_passwd');
	 }
	 &error_message('incorrect_passwd');
	 &wwslog('info','authentication: incorrect password for user %s', $email);

	 $param->{'init_email'} = $email;
	 $param->{'escaped_init_email'} = &tools::escape_chars($email);
	 return undef;
     }

 }

 sub ldap_authentication {

     my ($auth,$pwd,$whichfilter) = @_;
     my ($cnx, $mesg, $host,$ldap_passwd,$ldap_anonymous);

     unless (&tools::get_filename('etc', 'auth.conf', $robot)) {
	 return undef;
     }

     ## No LDAP entry is defined in auth.conf
     if ($#{$Conf{'ldap_array'}} < 0) {
	 &do_log('notice', 'Skipping empty auth.conf');
	 return undef;
     }

     unless (require Net::LDAP) {
	 do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	 return undef;
     }
     unless (require Net::LDAP::Entry) {
	 do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	 return undef;
     }

     unless (require Net::LDAP::Message) {
	 do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	 return undef;
     }

     foreach my $ldap (@{$Conf{'ldap_array'}}){
	 foreach $host (split(/,/,$ldap->{'host'})){

	     my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
	     my $attrs = $ldap->{'email_attribute'};
	     my $filter = $ldap->{'get_dn_by_uid_filter'} if($whichfilter eq 'uid_filter');
	     $filter = $ldap->{'get_dn_by_email_filter'} if($whichfilter eq 'email_filter');
	     $filter =~ s/\[sender\]/$auth/ig;

	     ##anonymous bind in order to have the user's DN
	     my $ldap_anonymous;
	     if ($ldap->{'use_ssl'}) {
		 unless (require Net::LDAPS) {
		     do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		     return undef;
		 } 

		 my %param;
		 $param{'timeout'} = $ldap->{'timeout'} if ($ldap->{'timeout'});
		 $param{'sslversion'} = $ldap->{'ssl_version'} if ($ldap->{'ssl_version'});
		 $param{'ciphers'} = $ldap->{'ssl_ciphers'} if ($ldap->{'ssl_ciphers'});

		 $ldap_anonymous = Net::LDAPS->new($host,%param);
	     }else {
		 $ldap_anonymous = Net::LDAP->new($host,timeout => $ldap->{'timeout'});
	     }

	     unless ($ldap_anonymous ){
		 do_log ('err','Unable to connect to the LDAP server %s',$host);
		 next;
	     }

	     my $cnx;
	     ## Not always anonymous...
	     if (defined ($ldap->{'bind_dn'}) && defined ($ldap->{'bind_password'})) {
		 $cnx = $ldap_anonymous->bind($ldap->{'bind_dn'}, password =>$ldap->{'bind_password'});
	     }else {
		 $cnx = $ldap_anonymous->bind;
	     }

	     unless(defined($cnx) && ($cnx->code() == 0)){
		 do_log('notice',"Can\'t bind to LDAP server $host");
		 last;
		 #do_log ('err','Ldap Error : %s, Ldap server error : %s',$cnx->error,$cnx->server_error);
		 #$ldap_anonymous->unbind;
	     }

	     $mesg = $ldap_anonymous->search(base => $ldap->{'suffix'},
					     filter => "$filter",
					     scope => $ldap->{'scope'} ,
					     timeout => $ldap->{'timeout'});

	     if ($mesg->count() == 0) {
		 do_log('notice','No entry in the Ldap Directory Tree of %s for %s',$host,$auth);
		 $ldap_anonymous->unbind;
		 last;
	     }

	     my $refhash=$mesg->as_struct();
	     my (@DN) = keys(%$refhash);
	     $ldap_anonymous->unbind;

	     ##  bind with the DN and the pwd
	     my $ldap_passwd;
	     if ($ldap->{'use_ssl'}) {
		 unless (require Net::LDAPS) {
		     do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		     return undef;
		 } 

		 my %param;
		 $param{'timeout'} = $ldap->{'timeout'} if ($ldap->{'timeout'});
		 $param{'sslversion'} = $ldap->{'ssl_version'} if ($ldap->{'ssl_version'});
		 $param{'ciphers'} = $ldap->{'ssl_ciphers'} if ($ldap->{'ssl_ciphers'});

		 $ldap_passwd = Net::LDAPS->new($host,%param);
	     }else {
		 $ldap_passwd = Net::LDAP->new($host,timeout => $ldap->{'timeout'});
	     }

	     unless ($ldap_passwd) {
		 do_log('err','Unable to (re) connect to the LDAP server %s', $host);
		 do_log ('err','Ldap Error : %s, Ldap server error : %s',$ldap_passwd->error,$ldap_passwd->server_error);
		 next;
	     }

	     $cnx = $ldap_passwd->bind($DN[0], password => $pwd);
	     unless(defined($cnx) && ($cnx->code() == 0)){
		 do_log('notice', 'Incorrect password for user %s ; host: %s',$auth, $host);
		 #do_log ('err','Ldap Error : %s, Ldap server error : %s',$cnx->error,$cnx->server_error);
		 $ldap_passwd->unbind;
		 last;
	     }
	     # this bind is anonymous and may return 
	     # $ldap_passwd->bind($DN[0]);
	     $mesg= $ldap_passwd->search ( base => $ldap->{'suffix'},
					   filter => "$filter",
					   scope => $ldap->{'scope'},
					   timeout => $ldap->{'timeout'}
					   );

	     if ($mesg->count() == 0) {
		 do_log('notice',"No entry in the Ldap Directory Tree of %s,$host");
		 $ldap_passwd->unbind;
		 last;
	     }

	     ## To get the value of the canonic email and the alternative email
	     my (@canonic_email, @alternative);

	     ## Keep previous alt emails not from LDAP source
	     my $previous = {};
	     foreach my $alt (keys %{$param->{'alt_emails'}}) {
		 $previous->{$alt} = $param->{'alt_emails'}{$alt} if ($param->{'alt_emails'}{$alt} ne 'ldap');
	     }
	     $param->{'alt_emails'} = {};

	     my $entry = $mesg->entry(0);
	     @canonic_email = $entry->get_value($attrs,alloptions);
	     foreach my $email (@canonic_email){
		 my $e = lc($email);
		 $param->{'alt_emails'}{$e} = 'ldap' if ($e);
	     }

	     foreach my $attribute_value (@alternative_conf){
		 @alternative = $entry->get_value($attribute_value,alloptions);
		 foreach my $alter (@alternative){
		     my $a = lc($alter); 
		     $param->{'alt_emails'}{$a} = 'ldap' if($a) ;
		 }
	     }

	     ## Restore previous emails
	     foreach my $alt (keys %{$previous}) {
		 $param->{'alt_emails'}{$alt} = $previous->{$alt};
	     }

	     $ldap_passwd->unbind or do_log('notice', "unable to unbind");
	     do_log('debug3',"canonic: $canonic_email[0]");
	     return lc($canonic_email[0]);
	 }

	 next unless ($ldap_anonymous);
	 next unless ($ldap_passwd);
	 next unless (defined($cnx) && ($cnx->code() == 0));
	 next if($mesg->count() == 0);
	 next if($mesg->code() != 0);
	 next unless ($host);
     }
 }

 sub do_unify_email {

     &wwslog('info', 'do_unify_email');

     unless($param->{'user'}{'email'}){
	 &error_message('failed');
	 &do_log('notice',"error email");
     }

     ##Do you want to be considered as one user in user_table and subscriber table?
     foreach my $old_email( keys %{$param->{'alt_emails'}}){
	 next unless (&List::is_user_db($old_email));
	 next if($old_email eq $param->{'user'}{'email'});

	 unless ( &List::delete_user_db($old_email) ) {
	     &error_message('failed');
	     &wwslog('info','do_unify_email: delete failed for the email %s',$old_email);
	 }
     }

     foreach my $role ('member','owner','editor'){
	 foreach my $email ( keys %{$param->{'alt_emails'}} ){
	     my @array = &List::get_which($email,$robot, $role); 
	     $param->{'alternative_subscribers_entries'}{$role}{$email} = \@array if($#array > -1);
	 }
     }

     foreach my $email(sort keys %{$param->{'alternative_subscribers_entries'}{'member'}}){
	 foreach my $list_name ( @{ $param->{'alternative_subscribers_entries'}{'member'}{$email} } ){ 
	     my $newlist = new List ($list_name);

	     unless ( $newlist->update_user($email,{'email' => $param->{'user'}{'email'} }) ) {
		 if ($newlist->{'admin'}{'user_data_source'} eq 'include') {
		 }else{
		     $newlist->delete_user($email);
		 }
	     }

	 }
     }

     $param->{'alt_emails'} = undef;

     return 'which';
 }


 ## Declare an alternative email
 sub do_record_email{

     &wwslog('info', 'do_record_email');
     my $user;
     my $new_email;

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_record_email: no user');
	 return 'pref';
     }

     ##To verify that the user is in User_table 
     ##To verify the associated password 
     ##If not in User table we add him 

     unless(&tools::valid_email($in{'new_alternative_email'})){
	 &error_message('incorrect_email', {'email' => $in{'new_alternative_email'}});
	 &do_log('notice', "do_record_email:incorrect email %s",$in{'new_alternative_email'});
	 return 'pref';
     }

     ## Alt email is the same as main email address
     if ($in{'new_alternative_email'} eq $param->{'user'}{'email'}) {
	 &error_message('incorrect_email', {'email' => $in{'new_alternative_email'}});
	 &do_log('notice', "do_record_email:incorrect email %s",$in{'new_alternative_email'});
	 return 'pref';
     }

     my $new_user;

     $user = &List::get_user_db($in{'new_alternative_email'});
     $user->{'password'} ||= &tools::tmp_passwd($in{'new_alternative_email'});	
     unless($in{'new_password'} eq $user->{'password'}){
	 &error_message('incorrect_passwd');
	 &wwslog('info','do_record_email: incorrect password for user %s', $in{'new_alternative_email'});
	 return 'pref';
     }  

     ##To add this alternate email in the cookie sympa_altemails   
     $param->{'alt_emails'}{$in{'new_alternative_email'}} = 'classic';
     return 'pref';

 }

 sub is_ldap_user {
     unless (&tools::get_filename('etc', 'auth.conf', $robot)) {
	 return undef;
     }
     unless (require Net::LDAP) {
	 do_log ('err',"Unable to use LDAP library, Net::LDAP required,install perl-ldap (CPAN) first");
	 return undef;
     }

     my $auth = shift; ## User email or UID
     my ($ldap_anonymous,$host,$filter);

     foreach my $ldap (@{$Conf{'ldap_array'}}){
	 foreach $host (split(/,/,$ldap->{'host'})){
	     unless($host){
		 last;
	     }

	     &do_log('debug4','Host: %s', $host);

	     my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
	     my $attrs = $ldap->{'email_attribute'};

	     if (&tools::valid_email($auth)){
		 $filter = $ldap->{'get_dn_by_email_filter'};
	     }else{
		 $filter = $ldap->{'get_dn_by_uid_filter'};
	     }
	     $filter =~ s/\[sender\]/$auth/ig;

	     ## !! une fonction get_dn_by_email/uid

	     my $ldap_anonymous;
	     if ($ldap->{'use_ssl'}) {
		 unless (require Net::LDAPS) {
		     do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		     return undef;
		 } 

		 my %param;
		 $param{'timeout'} = $ldap->{'timeout'} if ($ldap->{'timeout'});
		 $param{'sslversion'} = $ldap->{'ssl_version'} if ($ldap->{'ssl_version'});
		 $param{'ciphers'} = $ldap->{'ssl_ciphers'} if ($ldap->{'ssl_ciphers'});

		 $ldap_anonymous = Net::LDAPS->new($host,%param);
	     }else {
		 $ldap_anonymous = Net::LDAP->new($host,timeout => $ldap->{'timeout'});
	     }


	     unless ($ldap_anonymous ){
		 do_log ('err','Unable to connect to the LDAP server %s',$host);
		 next;
	     }

	     $ldap_anonymous->bind;
	     my $mesg = $ldap_anonymous->search(base => $ldap->{'suffix'} ,
						filter => "$filter",
						scope => $ldap->{'scope'}, 
						timeout => $ldap->{'timeout'} );

	     unless($mesg->count() != 0) {
		 do_log('notice','No entry in the Ldap Directory Tree of %s for %s',$host,$auth);
		 $ldap_anonymous->unbind;
		 last;
	     } 

	     $ldap_anonymous->unbind;
	     my $redirect = $ldap->{'authentication_info_url'};
	     return $redirect || 1;
	 }
	 next unless ($ldap_anonymous);
	 next unless ($host);
     }
 }

 ## send back login form
 sub do_loginrequest {
     &wwslog('info','do_loginrequest');

     if ($param->{'user'}{'email'}) {
	 &error_message('already_login', {'email' => $param->{'user'}{'email'}});
	 &wwslog('info','do_loginrequest: already logged in as %s', $param->{'user'}{'email'});
	 return undef;
     }

     if ($in{'init_email'}) {
	 $param->{'init_email'} = $in{'init_email'};
     }

     if ($in{'previous_action'} eq 'referer') {
	 $param->{'referer'} = &tools::escape_chars($ENV{'HTTP_REFERER'});
     }elsif (! $param->{'previous_action'}) {
	 $param->{'previous_action'} = $in{'previous_action'};
	 $param->{'previous_list'} = $in{'previous_list'};
     }

     $param->{'title'} = 'Login'
	 if ($param->{'nomenu'});


     return 1;
 }

 ## Help / about WWSympa
 sub do_help {
     &wwslog('info','do_help(%s)', $in{'help_topic'});

     ## Contextual help
     if ($in{'help_topic'}) {
	 if ($in{'help_topic'} eq 'editlist') {
	     foreach my $pname (sort List::by_order keys %{$pinfo}) {
		 next if ($pname =~ /^comment|defaults$/);

		 $param->{'param'}{$pname}{'title'} = $pinfo->{$pname}{'title'}{$param->{'lang'}};
		 $param->{'param'}{$pname}{'comment'} = $pinfo->{$pname}{'comment'}{$param->{'lang'}};
	     }
	 }

	 $param->{'nomenu'} = 1;
	 $param->{'help_topic'} = $in{'help_topic'};
     }

     return 1;
 }

 ## Logout from WWSympa
 sub do_logout {
     &wwslog('info','do_logout(%s)', $param->{'user'}{'email'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_logout: user not logged in');
	 return undef;
     }

     # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'logout','',$robot,'','done');

     delete $param->{'user'};
     $param->{'lang'} = $param->{'cookie_lang'} = &cookielib::check_lang_cookie($ENV{'HTTP_COOKIE'}) || $list->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

     &wwslog('info','do_logout: logout performed');

     if ($in{'previous_action'} eq 'referer') {
	 $param->{'referer'} = &tools::escape_chars($in{'previous_list'});
     }

     return 'home';
 }

 ## Remind the password
 sub do_remindpasswd {
     &wwslog('info', 'do_remindpasswd(%s)', $in{'email'}); 

     my $url_redirect;
     if($in{'email'}){
	 if($url_redirect = &is_ldap_user($in{'email'})){
	     $param->{'redirect_to'} = $url_redirect
		 if ($url_redirect && ($url_redirect != 1));
	 }elsif (! &tools::valid_email($in{'email'})) {
	     &error_message('incorrect_email', {'email' => $in{'email'}});
	     &wwslog('info','do_remindpasswd: incorrect email %s', $in{'email'});
	     return undef;
	 }
     }

     $param->{'email'} = $in{'email'};

     ('wwsympa',$in{'email'},'null',$ip,'remindpasswd','',$robot,'','done');

     if ($in{'previous_action'} eq 'referer') {
	 $param->{'referer'} = &tools::escape_chars($in{'previous_list'});
     }
     return 1;
 }

 sub do_sendpasswd {
     &wwslog('info', 'do_sendpasswd(%s)', $in{'email'}); 
     my ($passwd, $user);

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_sendpasswd: no email');
	 return 'remindpasswd';
     }

     unless (&tools::valid_email($in{'email'})) {
	 &error_message('incorrect_email', {'email' => $in{'email'}});
	 &wwslog('info','do_sendpasswd: incorrect email %s', $in{'email'});
	 return 'remindpasswd';
     }

     my $url_redirect;
     if($url_redirect = &is_ldap_user($in{'email'})){
	 ## There might be no authentication_info_url URL defined in auth.conf
	 if ($url_redirect == 1) {
	     &error_message('ldap_user');
	     &wwslog('info','do_sendpasswd: LDAP user %s, cannot remind password', $in{'email'});
	     return 'remindpasswd';
	 }else {
	     $param->{'redirect_to'} = $url_redirect
		 if ($url_redirect && ($url_redirect != 1));
	     return 1;
	 }
     }

     if ($param->{'newuser'} =  &List::get_user_db($in{'email'})) {

	 ## Create a password if none
	 unless ($param->{'newuser'}{'password'}) {
	     unless ( &List::update_user_db($in{'email'},
					    {'password' => &tools::tmp_passwd($in{'email'}) 
					     })) {
		 &error_message('update_failed');
		 &wwslog('info','send_passwd: update failed');
		 return undef;
	     }
	     $param->{'newuser'}{'password'} = &tools::tmp_passwd($in{'email'});
	 }

	 $param->{'newuser'}{'escaped_email'} =  &tools::escape_chars($param->{'newuser'}{'email'});

     }else {

	 $param->{'newuser'} = {'email' => $in{'email'},
				'escaped_email' => &tools::escape_chars($in{'email'}),
				'password' => &tools::tmp_passwd($in{'email'}) 
				};

     }

     $param->{'init_passwd'} = 1 
	 if ($param->{'user'}{'password'} =~ /^init/);

     &List::send_global_file('sendpasswd', $in{'email'}, $robot, $param);
     ('wwsympa',$in{'email'},'null',$ip,'sendpasswd','',$robot,'','done');


     $param->{'email'} = $in{'email'};
     $param->{'referer'} = $in{'referer'};

 #    if ($in{'previous_action'}) {
 #	$in{'list'} = $in{'previous_list'};
 #	return $in{'previous_action'};
 #
 #    }els

     if ($in{action} eq 'sendpasswd') {
	 #&message('password_sent');
	 $param->{'password_sent'} = 1;
	 $param->{'init_email'} = $in{'email'};
	 return 'loginrequest';
     }

     return 'loginrequest';
 }

 ## Which list the user is subscribed to 
 ## TODO (pour listmaster, toutes les listes)
 sub do_which {
     my $which = {};

     &wwslog('info', 'do_which');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_which: no user');
	 $param->{'previous_action'} = 'which';
	 return 'loginrequest';
     }
     $param->{'get_which'} = undef ;
     $param->{'which'} = undef ;

     foreach my $role ('member','owner','editor') {

	 foreach my $l( &List::get_which($param->{'user'}{'email'}, $robot, $role) ){ 	    
	     my $list = new List ($l);

	     next unless (&List::request_action ('visibility', $param->{'auth_method'}, $robot,
						 {'listname' =>  $l,
						  'sender' =>$param->{'user'}{'email'} ,
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/);

	     $param->{'which'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'which'}{$l}{'host'} = $list->{'admin'}{'host'};

	     if ($role eq 'member') {
		 push @{$param->{'get_which'}}, $l;
	     }else {
		 $param->{'which'}{$l}{'admin'} = 1;
	     }

	     ## For compatibility concerns (3.0)
	     ## To be deleted one of these day
	     $param->{$role}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{$role}{$l}{'host'} = $list->{'admin'}{'host'};

	 }

     }
     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'which','',$robot,'','done');
     return 1;
 }

 ## The list of list
 sub do_lists {
     my @lists;
     &wwslog('info', 'do_lists(%s,%s)', $in{'topic'}, $in{'subtopic'});

     my %topics = &List::load_topics($robot);

     if ($in{'topic'}) {
	 if ($in{'subtopic'}) {
	     $param->{'subtitle'} = sprintf "%s / %s", $topics{$in{'topic'}}{'title'}, $topics{$in{'topic'}}{'sub'}{$in{'subtopic'}}{'title'};
	     $param->{'subtitle'} ||= "$in{'topic'} / $in{'subtopic'}";
	 }else {
	     $param->{'subtitle'} = $topics{$in{'topic'}}{'title'} || $in{'topic'};
	 }
     }

     foreach my $l ( &List::get_lists($robot) ) {
	 my $list = new List ($l, $robot);

	 my $sender = $param->{'user'}{'email'} || 'nobody';
	 my $action = &List::request_action ('visibility',$param->{'auth_method'},$robot,
					     {'listname' =>  $l,
					      'sender' => $sender, 
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}});

	 next unless ($action eq 'do_it');

	 my $list_info = {};
	 $list_info->{'subject'} = $list->{'admin'}{'subject'};
	 $list_info->{'host'} = $list->{'admin'}{'host'};
	 if ($param->{'user'}{'email'} &&
	     ($list->am_i('owner',$param->{'user'}{'email'}) ||
	      $list->am_i('editor',$param->{'user'}{'email'})) ) {
	     $list_info->{'admin'} = 1;
	 }
	 if ($param->{'user'}{'email'} &&
	     $list->is_user($param->{'user'}{'email'})) {
	     $list_info->{'is_subscriber'} = 1;
	 }

	 ## no topic ; List all lists
	 if (! $in{'topic'}) {
	     $param->{'which'}{$list->{'name'}} = $list_info;
	 }elsif ($list->{'admin'}{'topics'}) {
	     foreach my $topic (@{$list->{'admin'}{'topics'}}) {
		 my @tree = split '/', $topic;

		 next if (($in{'topic'}) && ($tree[0] ne $in{'topic'}));
		 next if (($in{'subtopic'}) && ($tree[1] ne $in{'subtopic'}));

		 $param->{'which'}{$list->{'name'}} = $list_info;
	     }
	 }elsif ($in{'topic'} eq 'topicsless') {
	     $param->{'which'}{$list->{'name'}} = $list_info;
	 }
     }
     return 1;
 }

 ## List information page
 sub do_info {
     &wwslog('info', 'do_info');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_info: no list');
	 return undef;
     }

     ## May review
     my $action = &List::request_action ('info',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'},
					  'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});
     unless ($action =~ /do_it/) {
	 &error_message('may_not');
	 &wwslog('info','do_info: may not view info');
	 return undef;
     }

     ## Digest frequency
     if ($list->{'admin'}{'digest'} =~ /^([\d\,]+)\s+([\d\:]+)/m) {
	 my (@days, $d);
	 my $hour = $2;
	 foreach $d (split /\,/, $1) {
 #	    push @days, $week{$param->{'lang'}}[$d];
	     push @days, &POSIX::strftime("%A", localtime(0 + ($d +3) * (3600 * 24)));
	 }
	 $param->{'digest'} = sprintf '%s - %s', (join ', ', @days), $hour;
     }

     ## Is_user
     if ($param->{'is_subscriber'}) {
	 my ($s, $m);

	 unless($s = $list->get_subscriber($param->{'user'}{'email'})) {
	     &error_message('subscriber_not_found', {'email' => $param->{'user'}{'email'}});
	     &wwslog('info', 'do_info: subscriber %s not found', $param->{'user'}{'email'});
	     return undef;
	 }

	 $s->{'reception'} ||= 'mail';
	 $s->{'visibility'} ||= 'noconceal';
	 $s->{'date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'date'}));

	 foreach $m (keys %wwslib::reception_mode) {
	     $param->{'reception'}{$m}{'description'} = $wwslib::reception_mode{$m};
	     if ($s->{'reception'} eq $m) {
		 $param->{'reception'}{$m}{'selected'} = 'SELECTED';
	     }else {
		 $param->{'reception'}{$m}{'selected'} = '';
	     }
	 }

	 ## my $sortby = $in{'sortby'} || 'email';
	 $param->{'subscriber'} = $s;
     }

     ## Get List Description
     if (-r $list->{'dir'}.'/homepage') {
	 $param->{'homepage_file'} = $list->{'dir'}.'/homepage';
     }else {
	 $param->{'info_file'} = $list->{'dir'}.'/info';
     }



     return 1;
 }

 ## Subscribers' list
 sub do_review {
     &wwslog('info', 'do_review(%d)', $in{'page'});
     my $record;
     my @users;
     my $size = $in{'size'} || $wwsconf->{'review_page_size'};
     my $sortby = $in{'sortby'} || 'email';
     my %sources;

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_review: no list');
	 return undef;
     }

     ## May review
     my $action = &List::request_action ('review',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'},
					  'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});
     unless ($action =~ /do_it/) {
	 &error_message('may_not');
	 &wwslog('info','do_review: may not review');
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','may not');
	 return undef;
     }

     unless ($param->{'total'}) {
	 &error_message('no_subscriber');
	 &wwslog('info','do_review: no subscriber');
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','no subscriber');
	 return 1;
     }

     ## Owner
     $param->{'page'} = $in{'page'} || 1;
     $param->{'total_page'} = int ($param->{'total'} / $size);
     $param->{'total_page'} ++
	 if ($param->{'total'} % $size);

     if ($param->{'page'} > $param->{'total_page'}) {
	 &error_message('no_page', {'page' => $param->{'page'}});
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','out of pages');
	 &wwslog('info','do_review: no page %d', $param->{'page'});
	 return undef;
     }

     my $offset;
     if ($param->{'page'} > 1) {
	 $offset = (($param->{'page'} - 1) * $size);
     }else {
	 $offset = 0;
     }

     ## We might not use LIMIT clause
     my ($limit_not_used, $count);
     unless (($list->{'admin'}{'user_data_source'} =~ /^database|include2$/) && 
	     ($Conf{'db_type'} =~ /^Pg|mysql$/)) {
	 $limit_not_used = 1;
     }

     ## Additional DB fields
     my @additional_fields = split ',', $Conf{'db_additional_subscriber_fields'};

     ## Members list
     $count = -1;
     for (my $i = $list->get_first_user({'sortby' => $sortby, 
					 'offset' => $offset, 
					 'rows' => $size}); 
	  $i; $i = $list->get_next_user()) {

	 next if (($i->{'visibility'} eq 'conceal')
		  and (! $param->{'is_owner'}) );

	 if ($limit_not_used) {
	     $count++;
	     next unless (($count >= $offset) && ($count <= $offset+$size));
	 }

	 ## Add user
	 $i->{'date'} = &POSIX::strftime("%d %b %Y", localtime($i->{'date'}));
	 $i->{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($i->{'update_date'}));

	 $i->{'reception'} ||= 'mail';

	 $i->{'email'} =~ /\@(.+)$/;
	 $i->{'domain'} = $1;

	 ## Escape some weird chars
	 $i->{'escaped_email'} = &tools::escape_chars($i->{'email'});

	 ## Check data sources
	 if ($i->{'id'}) {
	     my @s;
	     my @ids = split /,/,$i->{'id'};
	     foreach my $id (@ids) {
		 unless (defined ($sources{$id})) {
		     $sources{$id} = $list->search_datasource($id);
		 }
		 push @s, $sources{$id};
	     }
	     $i->{'sources'} = join ', ', @s;
	 }

	 if (@additional_fields) {
	     my @fields;
	     foreach my $f (@additional_fields) {
		 push @fields, $i->{$f};
	     }
	     $i->{'additional'} = join ',', @fields;
	 }

	 push @{$param->{'members'}}, $i;
     }

     if ($param->{'page'} > 1) {
	 $param->{'prev_page'} = $param->{'page'} - 1;
     }

     unless (($offset + $size) >= $param->{'total'}) {
	 $param->{'next_page'} = $param->{'page'} + 1;
     }

     $param->{'size'} = $size;
     $param->{'sortby'} = $sortby;

     ## additional DB fields
     $param->{'additional_fields'} = $Conf{'db_additional_subscriber_fields'};
     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','done');
     return 1;
 }

 ## Search in subscribers
 sub do_search {
     &wwslog('info', 'do_search(%s)', $in{'filter'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_search: no list');
	 return undef;
     }

     unless ($in{'filter'}) {
	 &error_message('no_filter');
	 &wwslog('info','do_search: no filter');
	 return undef;
     }

     ## May review
     my $sender = $param->{'user'}{'email'} || 'nobody';
     my $action = &List::request_action ('review',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'},
					  'sender' => $sender,
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});

     unless ($action =~ /do_it/) {
	 &error_message('may_not');
	 &wwslog('info','do_search: may not review');
	 return undef;
     }

     ## Regexp
     $param->{'filter'} = $in{'filter'};
     my $regexp = $param->{'filter'};
     $regexp =~ s/\\/\\\\/g;
     $regexp =~ s/\./\\\./g;
     $regexp =~ s/\*/\.\*/g;
     $regexp =~ s/\+/\\\+/g;
     $regexp =~ s/\?/\\\?/g;

     my $sql_regexp;
     if ($list->{'admin'}{'user_data_source'} eq 'database') {
	 $sql_regexp = $param->{'filter'};
	 $sql_regexp =~ s/\%/\\\%/g;
	 $sql_regexp =~ s/\*/\%/g;
	 $sql_regexp = '%'.$sql_regexp.'%';
     }

     my $record = 0;
     ## Members list
     for (my $i = $list->get_first_user({'sql_regexp' => $sql_regexp, 'sortby' => 'email'})
	  ; $i; $i = $list->get_next_user()) {

	 ## Search filter
	 next if ($i->{'email'} !~ /$regexp/i
		  && $i->{'gecos'} !~ /$regexp/i);

	 next if (($i->{'visibility'} eq 'conceal')
		  and (! $param->{'is_owner'}) );

	 ## Add user
	 $i->{'date'} = &POSIX::strftime("%d %b %Y", localtime($i->{'date'}));
	 $i->{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($i->{'update_date'}));

	 $i->{'reception'} ||= 'mail';

	 ## Escape some weird chars
	 $i->{'escaped_email'} = &tools::escape_chars($i->{'email'});

	 $record++;
	 push @{$param->{'members'}}, $i;
     }

     ## Maximum size of selection
     my $max_select = 500;

     if ($record > $max_select) {
	 undef $param->{'members'};
	 $param->{'too_many_select'} = 1;
     }

     $param->{'occurrence'} = $record;
     return 1;
 }

 ## Access to user preferences
 sub do_pref {
     &wwslog('info', 'do_pref');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_pref: no user');
	 $param->{'previous_action'} = 'pref';
	 return 'loginrequest';
     }

     ## Find nearest expiration period
     my $selected = 0;
     foreach my $p (sort {$b <=> $a} keys %wwslib::cookie_period) {
	 my $entry = {'value' => $p};

	 ## Set description from NLS
	 $entry->{'desc'} = sprintf Msg(17, $wwslib::cookie_period{$p}, $p);

	 ## Choose nearest delay
	 if ((! $selected) && $param->{'user'}{'cookie_delay'} >= $p) {
	     $entry->{'selected'} = 'SELECTED';
	     $selected = 1;
	 }

	 unshift @{$param->{'cookie_periods'}}, $entry;
     }

     $param->{'previous_list'} = $in{'previous_list'};
     $param->{'previous_action'} = $in{'previous_action'};

     return 1;
 }

 ## Set the initial password
 sub do_choosepasswd {
     &wwslog('info', 'do_choosepasswd');

     if($param->{'auth'} eq 'ldap'){
	 &error_message('may_not');
	 &wwslog('notice', "do_choosepasswd : user not authorized\n");
      }

     unless ($param->{'user'}{'email'}) {
	 unless ($in{'email'} && $in{'passwd'}) {
	     &error_message('no_user');
	     &wwslog('info','do_pref: no user');
	     $param->{'previous_action'} = 'choosepasswd';
	     return 'loginrequest';
	 }

	 $in{'previous_action'} = 'choosepasswd';
	 return 'login';
     }

     $param->{'init_passwd'} = 1 if ($param->{'user'}{'password'} =~ /^INIT/i);

     return 1;
 }

 ## Change subscription parameter
 sub do_set {
     &wwslog('info', 'do_set(%s, %s)', $in{'reception'}, $in{'visibility'});

     my ($reception, $visibility) = ($in{'reception'}, $in{'visibility'});
     my $email;

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_set: no list');
	 return undef;
     }

     unless ($reception || $visibility) {
	 &error_message('no_reception');
	 &wwslog('info','do_set: no reception');
	 return undef;
     }

     if ($in{'email'}) {
	 unless ($param->{'is_owner'}) {
	     &error_message('may_not');
	     &wwslog('info','do_set: not owner');
	     return undef;
	 }

	 $email = &tools::unescape_chars($in{'email'});
     }else {
	 unless ($param->{'user'}{'email'}) {
	     &error_message('no_user');
	     &wwslog('info','do_set: no user');
	     return 'loginrequest';
	 }
	 $email = $param->{'user'}{'email'};
     } 

     unless ($list->is_user($email)) {
	 &error_message('not_subscriber');
	 &wwslog('info','do_set: %s not subscriber of list %s', $email, $param->{'list'});
	 return undef;
     }

     # Verify that the mode is allowed
     if (! $list->is_available_reception_mode($reception)) {
       &error_message('not_allowed');
       return undef;
     }

     $reception = '' if $reception eq 'mail';
     $visibility = '' if $visibility eq 'noconceal';

     my $update = {'reception' => $reception,
		   'visibility' => $visibility,
		   'update_date' => time};

     ## Lower-case new email address
     $in{'new_email'} = lc( $in{'new_email'});

     if ($in{'new_email'} && ($in{'email'} ne $in{'new_email'})) {

	 unless ($in{'new_email'} && &tools::valid_email($in{'new_email'})) {
	     &do_log('notice', "do_set:incorrect email %s",$in{'new_email'});
	     &error_message('incorrect_email', {'email' => $in{'new_email'}});
	     return undef;
	 }

	 ## Duplicate entry in user_table
	 unless (&List::is_user_db($in{'new_email'})) {

	     my $user_pref = &List::get_user_db($in{'email'});
	     $user_pref->{'email'} = $in{'new_email'};
	     &List::add_user_db($user_pref);
	 }

	 $update->{'email'} = $in{'new_email'};
     }

     ## Get additional DB fields
     foreach my $v (keys %in) {
	 if ($v =~ /^additional_field_(\w+)$/) {
	     $update->{$1} = $in{$v};
	 }
     }

     $update->{'gecos'} = $in{'gecos'} if $in{'gecos'};

     unless ( $list->update_user($email, $update) ) {
	 &error_message('failed');
	 &wwslog('info', 'do_set: set failed');
	 return undef;
     }

     $list->save();

     &message('performed');

     return 'info';
 }

 ## Update of user preferences
 sub do_setpref {
     &wwslog('info', 'do_setpref');
     my $changes = {};

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_pref: no user');
	 return 'loginrequest';
     }

     foreach my $p ('gecos','lang','cookie_delay') {
	 $changes->{$p} = $in{$p} if (defined($in{$p}));
     }

     if (&List::is_user_db($param->{'user'}{'email'})) {

	 unless (&List::update_user_db($param->{'user'}{'email'}, $changes)) {
	     &error_message('update_failed');
	     &wwslog('info','do_pref: update failed');
	     return undef;
	 }
     }else {
	 $changes->{'email'} = $param->{'user'}{'email'};
	 unless (&List::add_user_db($changes)) {
	     &error_message('update_failed');
	     &wwslog('info','do_pref: update failed');
	     return undef;
	 }
     }

     foreach my $p ('gecos','lang','cookie_delay') {
	 $param->{'user'}{$p} = $in{$p};
     }


     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }else {
	 return 'pref';
     }
 }

 ## Prendre en compte les défauts
 sub do_viewfile {
     &wwslog('info', 'do_viewfile');

     unless ($in{'file'}) {
	 &error_message('missing_arg', {'argument' => 'file'});
	 &wwslog('info','do_viewfile: no file');
	 return undef;
     }

     unless (defined $wwslib::filenames{$in{'file'}}) {
	 &error_message('file_not_editable', {'file' => $in{'file'}});
	 &wwslog('info','do_viewfile: file %s not editable', $in{'file'});
	 return undef;
     }

    unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_viewfile: no list');
	 return undef;
     }

     $param->{'file'} = $in{'file'};

     $param->{'filepath'} = $list->{'dir'}.'/'.$in{'file'};

     if ((-e $param->{'filepath'}) and (! -r $param->{'filepath'})) {
	 &error_message('read_error');
	 &wwslog('info','do_viewfile: cannot read %s', $param->{'filepath'});
	 return undef;
     }

     return 1;
 }

 ## Subscribe to the list
 ## TOTO: accepter nouveaux users
 sub do_subscribe {
     &wwslog('info', 'do_subscribe(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_subscribe: no list');
	 return undef;
     }

     ## Not authentified
     unless ($param->{'user'}{'email'}) {
	 ## no email 
	 unless ($in{'email'}) {
	     return 'subrequest';
	 }

	 ## Perform login
	 if ($in{'passwd'}) {
	     $in{'previous_action'} = 'subscribe';
	     $in{'previous_list'} = $param->{'list'};
	     return 'login';
	 }else {
	     return 'subrequest';
	 }

	 if ( &List::is_user_db($in{'email'})) {
	     &error_message('no_user');
	     &wwslog('info','do_subscribe: need auth for user %s', $in{'email'});
	     return undef;
	 }

     }

     if ($param->{'is_subscriber'} && 
	      ($param->{'subscriber'}{'subscribed'} == 1)) {
	 &error_message('already_subscriber', {'list' => $list->{'name'}});
	 &wwslog('info','do_subscribe: %s already subscriber', $param->{'user'}{'email'});
	 return undef;
     }

     my $sub_is = &List::request_action('subscribe',$param->{'auth_method'},$robot,
					{'listname' => $param->{'list'},
					 'sender' => $param->{'user'}{'email'}, 
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

     if ($sub_is =~ /reject/) {
	 &error_message('may_not');
	 &wwslog('info', 'do_subscribe: subscribe closed');
	 return undef;
     }

     $param->{'may_subscribe'} = 1;

     if ($sub_is =~ /owner/) {
	 $list->send_notify_to_owner({'who' => $param->{'user'}{'email'},
				      'keyauth' => $list->compute_auth($param->{'user'}{'email'}, 'add'),
				      'replyto' => &Conf::get_robot_conf($robot, 'sympa'),
				      'gecos' => $param->{'user'}{'gecos'},
				      'type' => 'subrequest'});
	 $list->store_subscription_request($param->{'user'}{'email'});
	 &message('sent_to_owner');
	 &wwslog('info', 'do_subscribe: subscribe sent to owner');

	 return 'info';
     }elsif ($sub_is =~ /do_it/) {
	 if ($param->{'is_subscriber'}) {
	     unless ($list->update_user($param->{'user'}{'email'}, 
					{'subscribed' => 1,
					 'update_date' => time})) {
		 &error_message('failed');
		 &wwslog('info', 'do_subscribe: update failed');
		 return undef;
	     }
	 }else {
	     my $defaults = $list->get_default_user_options();
	     my $u;
	     %{$u} = %{$defaults};
	     $u->{'email'} = $param->{'user'}{'email'};
	     $u->{'gecos'} = $param->{'user'}{'gecos'} || $in{'gecos'};
	     $u->{'date'} = $u->{'update_date'} = time;
	     $u->{'password'} = $param->{'user'}{'password'};
	     $u->{'lang'} = $param->{'user'}{'lang'} || $param->{'lang'};
	     $u->{'subscribed'} = 1 if ($list->{'admin'}{'user_data_source'} eq 'include2');

	     unless ($list->add_user($u)) {
		 &error_message('failed');
		 &wwslog('info', 'do_subscribe: subscribe failed');
		 return undef;
	     }
	     $list->save();
	 }

	 unless ($sub_is =~ /quiet/i ) {
	     my %context;
	     $context{'subject'} = sprintf(Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	     $context{'body'} = sprintf(Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	     $list->send_file('welcome', $param->{'user'}{'email'}, $robot, \%context);
	 }

	 if ($sub_is =~ /notify/) {
	     $list->send_notify_to_owner({'who' => $param->{'user'}{'email'}, 
					  'gecos' => $param->{'user'}{'gecos'}, 
					  'type' => 'subscribe'});
	 }
	 ## perform which to update your_subscribtions cookie ;
	 @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') ; 
	 &message('performed');
     }

     if ($in{'previous_action'}) {
	 return $in{'previous_action'};
     }

 #    return 'suboptions';
     return 'info';
 }

 ## Subscription request (user not authentified)
 sub do_suboptions {
     &wwslog('info', 'do_suboptions()');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_suboptions: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_suboptions: user not logged in');
	 return undef;
     }

     unless($param->{'is_subscriber'} ) {
	 &error_message('not_subscriber', {'list' => $list->{'name'}});
	 &wwslog('info','do_suboptions: %s not subscribed to %s',$param->{'user'}{'email'}, $param->{'list'} );
	 return undef;
     }

     my ($s, $m);

     unless($s = $list->get_subscriber($param->{'user'}{'email'})) {
	 &error_message('subscriber_not_found', {'email' => $param->{'user'}{'email'}});
	 &wwslog('info', 'do_info: subscriber %s not found', $param->{'user'}{'email'});
	 return undef;
     }

     $s->{'reception'} ||= 'mail';
     $s->{'visibility'} ||= 'noconceal';
     $s->{'date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'date'}));
     $s->{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'update_date'}));

     foreach $m (keys %wwslib::reception_mode) {
       if ($list->is_available_reception_mode($m)) {
	 $param->{'reception'}{$m}{'description'} = $wwslib::reception_mode{$m};
	 if ($s->{'reception'} eq $m) {
	     $param->{'reception'}{$m}{'selected'} = 'SELECTED';
	 }else {
	     $param->{'reception'}{$m}{'selected'} = '';
	 }
       }
     }

     foreach $m (keys %wwslib::visibility_mode) {
	 $param->{'visibility'}{$m}{'description'} = $wwslib::visibility_mode{$m};
	 if ($s->{'visibility'} eq $m) {
	     $param->{'visibility'}{$m}{'selected'} = 'SELECTED';
	 }else {
	     $param->{'visibility'}{$m}{'selected'} = '';
	 }
     }

     $param->{'subscriber'} = $s;

     return 1;
 }

 ## Subscription request (user not authentified)
 sub do_subrequest {
     &wwslog('info', 'do_subrequest(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_subrequest: no list');
	 return undef;
     }

     my $ldap_user;
     $ldap_user = 1
	 if (!&tools::valid_email($in{'email'}) || &is_ldap_user($in{'email'}));

     ## Auth ?
     if ($param->{'user'}{'email'}) {

	 ## Subscriber ?
	 if ($param->{'is_subscriber'}) {
	     &error_message('already_subscriber', {'list' => $list->{'name'}});
	     &wwslog('info','do_subscribe: %s already subscriber', $param->{'user'}{'email'});
	     return undef;
	 }

	 $param->{'status'} = 'auth';
     }else {
	 ## Provided email parameter ?
	 unless ($in{'email'}) {
	     $param->{'status'} = 'notauth_noemail';
	     return 1;
	 }

	 ## Subscriber ?
	 if (!$ldap_user && $list->is_user($in{'email'})) {
	     $param->{'status'} = 'notauth_subscriber';
	     return 1;
	 }

	 my $user;
	 $user = &List::get_user_db($in{'email'})
	     if &List::is_user_db($in{'email'});

	 ## Need to send a password by email
	 if ((!&List::is_user_db($in{'email'}) || 
	      !$user->{'password'} || 
	      ($user->{'password'} =~ /^INIT/i)) &&
	     !$ldap_user) {

	     &do_sendpasswd();
	     $param->{'status'} = 'notauth_passwordsent';
	     return 1;
	 }

	 $param->{'email'} = $in{'email'};
	 $param->{'status'} = 'notauth';
     }

     return 1;
 }

 ## Unsubscribe from list
 sub do_signoff {
     &wwslog('info', 'do_signoff');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_signoff: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 unless ($in{'email'}) {
	     return 'sigrequest';
	 }

	 ## Perform login first
	 if ($in{'passwd'}) {
	     $in{'previous_action'} = 'signoff';
	     $in{'previous_list'} = $param->{'list'};
	     return 'login';
	 }

	 if ( &List::is_user_db($in{'email'}) ) {
	     &error_message('no_user');
	     &wwslog('info','do_signoff: need auth for user %s', $in{'email'});
	     return undef;
	 }

	 ## No passwd
	 &init_passwd($in{'email'}, {'lang' => $param->{'lang'} });

	 $param->{'user'}{'email'} = $in{'email'};
     }

     unless ($list->is_user($param->{'user'}{'email'})) {
	 &error_message('not_subscriber', {'list' => $list->{'name'}});
	 &wwslog('info','do_signoff: %s not subscribed to %s',$param->{'user'}{'email'}, $param->{'list'} );
	 return undef;
     }

     my $sig_is = &List::request_action ('unsubscribe',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'}, 
					  'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});

     $param->{'may_signoff'} = 1 if ($sig_is =~ /do_it|owner/);

     if ($sig_is =~ /reject/) {
	 &error_message('may_not');
	 &wwslog('info', 'do_signoff: %s may not signoff from %s'
		 , $param->{'user'}{'email'}, $param->{'list'});
	 return undef;
     }elsif ($sig_is =~ /owner/) {
	 $list->send_notify_to_owner({'who' => $param->{'user'}{'email'},
				      'keyauth' => $list->compute_auth($param->{'user'}{'email'}, 'del'),
				      'type' => 'sigrequest'});
	 &message('sent_to_owner');
	 &wwslog('info', 'do_signoff: signoff sent to owner');
	 return undef;
     }else {
	 if ($param->{'subscriber'}{'included'}) {
	     unless ($list->update_user($param->{'user'}{'email'}, 
					{'subscribed' => 0,
					 'update_date' => time})) {
		 &error_message('failed');
		 &wwslog('info', 'do_signoff: update failed');
		 return undef;
	     }
	 }else {
	     unless ($list->delete_user($param->{'user'}{'email'})) {
		 &error_message('failed');
		 &wwslog('info', 'do_signoff: signoff failed');
		 return undef;
	     }

	     $list->save();
	 }

	 if ($sig_is =~ /notify/) {
	     $list->send_notify_to_owner({'who' => $param->{'user'}{'email'},
					  'gecos' => '', 
					  'type' => 'signoff'});
	 }

	 my %context;
	 $context{'subject'} = sprintf(Msg(6 , 71, 'Signoff from list %s'), $list->{'name'});
	 $context{'body'} = sprintf(Msg(6 , 31, "You have been removed from list %s.\n Thanks for being with us.\n"), $list->{'name'});
	 ## perform which to update your_subscribtions cookie ;
	 @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') ; 

	 $list->send_file('bye', $param->{'user'}{'email'}, $robot, \%context);
     }
     &message('performed');
     $param->{'is_subscriber'} = 0;
     $param->{'may_signoff'} = 0;

     return 'info';
 }

 ## Unsubscription request (user not authentified)
 sub do_sigrequest {
     &wwslog('info', 'do_sigrequest(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_sigrequest: no list');
	 return undef;
     }

     my $ldap_user;
     $ldap_user = 1
	 if (!&tools::valid_email($in{'email'}) || &is_ldap_user($in{'email'}));

     ## Do it
     if ($param->{'user'}{'email'}) {
	 $param->{'status'} = 'auth';
	 return 1;
 #	return 'signoff';
     }

     ## Not auth & no email
     unless ($in{'email'}) {
	 return 1;
     }

     if ($list->is_user($in{'email'}) || $ldap_user) {
	 my $user;
	 $user = &List::get_user_db($in{'email'})
	     if &List::is_user_db($in{'email'});

	 ## Need to send a password by email
	 if ((!&List::is_user_db($in{'email'}) || 
	     !$user->{'password'} || 
	     ($user->{'password'} =~ /^INIT/i)) &&
	     !$ldap_user) {

	     &do_sendpasswd();
	     $param->{'email'} =$in{'email'};
	     $param->{'init_passwd'} = 1;
	     return 1;
	 }
     }else {
	 $param->{'not_subscriber'} = 1;
     }

     $param->{'email'} = $in{'email'};

     return 1;
 }


 ## Update of password
 sub do_setpasswd {
     &wwslog('info', 'do_setpasswd');
     my $user;

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_setpasswd: no user');
	 return 'loginrequest';
     }

     unless ($in{'newpasswd1'}) {
	 &error_message('no_passwd');
	 &wwslog('info','do_setpasswd: no newpasswd1');
	 return undef;
     }

     unless ($in{'newpasswd2'}) {
	 &error_message('no_passwd');
	 &wwslog('info','do_setpasswd: no newpasswd2');
	 return undef;
     }

     unless ($in{'newpasswd1'} eq $in{'newpasswd2'}) {
	 &error_message('diff_passwd');
	 &wwslog('info','do_setpasswd: different newpasswds');
	 return undef;
     }

     if (&List::is_user_db($param->{'user'}{'email'})) {
	 unless ( &List::update_user_db($param->{'user'}{'email'}, {'password' => $in{'newpasswd1'}} )) {
	     &error_message('failed');
	     &wwslog('info','do_setpasswd: update failed');
	     return undef;
	 }
     }else {
	 unless ( &List::add_user_db({'email' => $param->{'user'}{'email'}, 
				      'password' => $in{'newpasswd1'}} )) {
	     &error_message('failed');
	     &wwslog('info','do_setpasswd: update failed');
	     return undef;
	 }
     }

     $param->{'user'}{'password'} =  $in{'newpasswd1'};

     &message('performed');

     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }else {
	 return 'pref';
     }
 }

 ## List admin page
 sub do_admin {
     &wwslog('info', 'do_admin');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_admin: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_admin: no user');
	 $param->{'previous_action'} = 'admin';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($param->{'is_owner'} or $param->{'is_editor'}) {
	 &error_message('may_not');
	 &wwslog('info','do_admin: %s not private user', $param->{'user'}{'email'});
	 return undef;
     }

     ## Messages edition
     foreach my $f ('info','homepage','welcome.tpl','bye.tpl','removed.tpl','message.footer','message.header','remind.tpl','invite.tpl','reject.tpl') {
	 next unless ($list->may_edit($f, $param->{'user'}{'email'}) eq 'write');
	 $param->{'files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	 $param->{'files'}{$f}{'selected'} = '';
     }
     $param->{'files'}{'info'}{'selected'} = 'SELECTED';

 #    my %mode;
 #    $mode{'edit'} = 1;
 #    my %access = &d_access_control(\%mode,$path);

     return 1;
 }

 ## Server admin page
 sub do_serveradmin {
     &wwslog('info', 'do_serveradmin');
     my $f;

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_serveradmin: no user');
	 $param->{'previous_action'} = 'serveradmin';
	 return 'loginrequest';
     }

     unless ($param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_admin: %s not listmaster', $param->{'user'}{'email'});
	 return undef;
     }

 #    $param->{'conf'} = \%Conf;

     ## Lists Default files
     foreach my $f ('welcome.tpl','bye.tpl','removed.tpl','message.footer','message.header','remind.tpl','invite.tpl','reject.tpl','your_infected_msg.tpl') {
	 $param->{'lists_default_files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	 $param->{'lists_default_files'}{$f}{'selected'} = '';
     }

     ## All Robots are shown to super listmaster
     if (&List::is_listmaster($param->{'user'}{'email'})) {
	 $param->{'main_robot'} = 1;
	 $param->{'robots'} = $Conf{'robots'};
     }

     ## Server files
     foreach my $f ('helpfile.tpl','lists.tpl','global_remind.tpl','summary.tpl','create_list_request.tpl','list_created.tpl','list_aliases.tpl') {
	 $param->{'server_files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	 $param->{'server_files'}{$f}{'selected'} = '';
     }
     $param->{'server_files'}{'helpfile.tpl'}{'selected'} = 'SELECTED';

     return 1;
 }

 ## Multiple add
 sub do_add_request {
     &wwslog('info', 'do_add_request(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_add_request: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_add_request: no user');
	 $param->{'previous_action'} = 'add_request';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     my $add_is = &List::request_action ('add',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'},
					  'sender' => $param->{'user'}{'email'}, 
					  'email' => 'nobody',
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});

     unless ($add_is =~ /do_it/) {
	 &error_message('may_not');
	 &wwslog('info','do_add_request: %s may not add', $param->{'user'}{'email'});
	 return undef;
     }

     return 1;
 }
 ## Add a user to a list
 ## TODO: vérifier validité email
 sub do_add {
     &wwslog('info', 'do_add(%s)', $in{'email'});

     my %user;

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_add: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_add: no user');
	 return 'loginrequest';
     }

     my $add_is = &List::request_action ('add',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'},
					  'sender' => $param->{'user'}{'email'}, 
					  'email' => $in{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});

     unless ($add_is =~ /do_it/) {
	 &error_message('may_not');
	 &wwslog('info','do_add: %s may not add', $param->{'user'}{'email'});
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$in{'email'},'may not');
	 return undef;
     }

     if ($in{'dump'}) {
	 foreach (split /\n/, $in{'dump'}) {
	     if (/^(\S+|\".*\"@\S+)(\s+(.*))?\s*$/) {
		 $user{&tools::get_canonical_email($1)} = $3;
	     }
	 }
     }elsif ($in{'email'} =~ /,/) {
	 foreach my $pair (split /\0/, $in{'email'}) {
	     if ($pair =~ /^(.+),(.+)$/) {
		 $user{&tools::get_canonical_email($1)} = $2;
	     }
	 }
     }elsif ($in{'email'}) {
	 $user{&tools::get_canonical_email($in{'email'})} = $in{'gecos'};
     }else {
	 &error_message('no_email');
	 &wwslog('info','do_add: no email');
	 return undef;
     }

     my ($total, @new_users );
     my $comma_emails ;
     foreach my $email (keys %user) {

	 unless (&tools::valid_email($email)) {
	     &error_message('incorrect_email', {'email' => $email});
	     &wwslog('info','do_add: incorrect email %s', $email);
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"incorrect_email");
	     next;
	 }

	 my $user_entry = $list->get_subscriber($email);

	 if ( defined($user_entry) && ($user_entry->{'subscribed'} == 1)) {
	     &error_message('user_already_subscriber', {'email' => $email,
							'list' => $list->{'name'}});
	     &wwslog('info','do_add: %s already subscriber', $email);
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"already subscriber");
	     next;
	 }

	 ## If already included
	 if (defined($user_entry)) {
	     unless ($list->update_user($email, 
					{'subscribed' => 1,
					 'update_date' => time})) {
		 &error_message('failed');
		 &wwslog('info', 'do_add: update failed');
		 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"update failed");
		 return undef;
	     }
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"updated");

	 }else {
	     my $u2 = &List::get_user_db($email);
	     my $defaults = $list->get_default_user_options();
	     my $u;
	     %{$u} = %{$defaults};
	     $u->{'email'} = $email;
	     $u->{'gecos'} = $user{$email} || $u2->{'gecos'};
	     $u->{'date'} = $u->{'update_date'} = time;
	     $u->{'password'} = $u2->{'password'} || &tools::tmp_passwd($email) ;
	     $u->{'lang'} = $u2->{'lang'} || $list->{'admin'}{'lang'};
	     $u->{'subscribed'} = 1 if ($list->{'admin'}{'user_data_source'} eq 'include2');
	     if ($comma_emails) {
		 $comma_emails = $comma_emails .','. $email;
	     }else{
		 $comma_emails = $email;
	     }

	     ##
	     push @new_users, $u;
	 }

	 ## Delete subscription request if any
	 $list->delete_subscription_request($email);

	 unless ($in{'quiet'} || ($add_is =~ /quiet/i )) {
	     my %context;
	     $context{'subject'} = sprintf(Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	     $context{'body'} = sprintf(Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	     $list->send_file('welcome', $email, $robot, \%context);
	 }
     }

     $total = $list->add_user(@new_users);
     unless( defined $total) {
	 &error_message('failed_add');
	 &wwslog('info','do_add: failed adding');
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$comma_emails,'failed',$total);
	 return undef;
     }

     $list->save();
     &message('add_performed', {'total' => $total});
     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$comma_emails,'done',$total) if (@new_users);
     return 'review';
 }

 ## Del a user to a list
 ## TODO: vérifier validité email
 sub do_del {
     &wwslog('info', 'do_del()');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_del: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_del: no email');
	 return undef;
     }

     $in{'email'} = &tools::unescape_chars($in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_del: no user');
	 return 'loginrequest';
     }

     my $del_is = &List::request_action ('del',$param->{'auth_method'},$robot,
					 {'listname' =>$param->{'list'},
					  'sender' => $param->{'user'}{'email'},
					  'email' => $in{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});

     unless ( $del_is =~ /do_it/) {
	 &error_message('may_not');
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,$in{'email'},'may not');
	 &wwslog('info','do_del: %s may not del', $param->{'user'}{'email'});
	 return undef;
     }

     my @emails = split /\0/, $in{'email'};

     my ($total, @removed_users);

     foreach my $email (@emails) {

	 my $escaped_email = &tools::escape_chars($email);

	 my $user_entry = $list->get_subscriber($email);

	 unless ( defined($user_entry) && ($user_entry->{'subscribed'} == 1) ) {
	     &error_message('not_subscriber', {'email' => $email});
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,$email,'not subscriber');
	     &wwslog('info','do_del: %s not subscribed', $email);
	     next;
	 }

	 if ($user_entry->{'included'}) {
	     unless ($list->update_user($email, 
					{'subscribed' => 0,
					 'update_date' => time})) {
		 &error_message('failed');
		 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,$email,'failed subscriber included');
		 &wwslog('info', 'do_del: update failed');
		 return undef;
	     }


	 }else {
	     push @removed_users, $email;
	 }

	 if (-f "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email") {
	     unless (unlink "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email") {
		 &wwslog('info','do_resetbounce: failed deleting %s', "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email");
		 next;
	     }
	 }


	 &wwslog('info','do_del: subscriber %s deleted from list %s', $email, $param->{'list'});

	 unless ($in{'quiet'}) {
	     my %context;
	     $context{'subject'} = sprintf(Msg(6, 18, "You have been removed from list %s\n"), $list->{'name'});
	     $context{'body'} = sprintf(Msg(6, 31, "You have been removed from list %s.\nThanks for being with us.\n"), $list->{'name'});

	     $list->send_file('removed', $email, $robot, \%context);
	 }
     }

     $total = $list->delete_user(@removed_users);

     unless( defined $total) {
	 &error_message('failed');
	 &wwslog('info','do_del: failed');
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,join('.',@removed_users),'failed');
	 return undef;
     }
     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,join(',',@removed_users),'done',$total) if (@removed_users) ;
     $list->save();

     &message('performed');
     $param->{'is_subscriber'} = 1;
     $param->{'may_signoff'} = 1;

     return $in{'previous_action'} || 'review';
 }

 sub do_modindex {
     &wwslog('info', 'do_modindex');
     my $msg;

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_modindex: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_modindex: no user');
	 $param->{'previous_action'} = 'modindex';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_modindex: %s not editor', $param->{'user'}{'email'});
	 return 'admin';
     }

     ## Loads message list
     unless (opendir SPOOL, $Conf{'queuemod'}) {
	 &error_message('spool_error');
	 &wwslog('info','do_modindex: unable to read spool');
	 return 'admin';
     }

     foreach $msg ( sort grep(!/^\./, readdir SPOOL )) {
	 next
	     unless ($msg =~ /^$list->{'name'}\_(\w+)$/);

	 my $id = $1;

	 ## Load msg
	 unless (open MSG, "$Conf{'queuemod'}/$msg") {
	     &error_message('msg_error');
	     &wwslog('info','do_modindex: unable to read msg %s', $msg);
	     closedir SPOOL;
	     return 'admin';
	 }

	 my $mail = new Mail::Internet [<MSG>];
	 close MSG;

	 $param->{'spool'}{$id}{'size'} = int( (-s "$Conf{'queuemod'}/$msg") / 1024 + 0.5);
	 $param->{'spool'}{$id}{'subject'} =  &MIME::Words::decode_mimewords($mail->head->get('Subject'));
	 $param->{'spool'}{$id}{'subject'} ||= 'no_subject';
	 $param->{'spool'}{$id}{'date'} = $mail->head->get('Date');
	 $param->{'spool'}{$id}{'from'} = &MIME::Words::decode_mimewords($mail->head->get('From'));
	 foreach my $field ('subject','date','from') {
	     $param->{'spool'}{$id}{$field} =~ s/</&lt;/;
	     $param->{'spool'}{$id}{$field} =~ s/>/&gt;/;
	 }
     }
     closedir SPOOL;

     unless ($param->{'spool'}) {
	 &message('no_msg', {'list' => $in{'list'}});
	 &wwslog('info','do_modindex: no message');
	 return 'admin';
     }


     return 1;
 }

 sub do_reject {
     &wwslog('info', 'do_reject()');
     my ($msg, $file);

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_reject: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_reject: no user');
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_reject: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     unless ($in{'id'}) {
	 &error_message('missing_arg', {'argument' => 'msgid'});
	 &wwslog('info','do_reject: no msgid');
	 return undef;
     }

     foreach my $id (split /\0/, $in{'id'}) {

	 $file = "$Conf{'queuemod'}/$list->{'name'}_$id";

	 ## Open the file
	 if (!open(IN, $file)) {
	     &error_message('failed_someone_else_did_it');
	     &wwslog('info','do_reject: Unable to open %s', $file);
	     return undef;
	 }
	 unless ($in{'quiet'}) {
	     my $message = new Mail::Internet [<IN>];
	     my @sender_hdr = Mail::Address->parse($message->head->get('From'));
	     unless  ($#sender_hdr == -1) {
		 my $rejected_sender = $sender_hdr[0]->address;
		 my %context;
		 $context{'subject'} = $message->head->get('subject');
		 $context{'rejected_by'} = $param->{'user'}{'email'};
		 $list->send_file('reject', $rejected_sender, $robot, \%context);
	     }
	 }
	 close(IN);  

	 unless (unlink($file)) {
	     &error_message('failed');
	     &wwslog('info','do_reject: failed to erase %s', $file);
	     return undef;
	 }

     }

     &message('performed');

     return 'modindex';
 }

 ## TODO: supprimer le msg
 sub do_distribute {
     &wwslog('info', 'do_distribute()');
     my ($msg, $file);

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_distribute: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_distribute: no user');
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_distribute: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     unless ($in{'id'}) {
	 &error_message('missing_arg', {'argument' => 'msgid'});
	 &wwslog('info','do_distribute: no msgid');
	 return undef;
     }
     my $extention = time.".".int(rand 9999) ;
     my $sympa_email = &Conf::get_robot_conf($robot, 'sympa');
     unless (open DISTRIBUTE, ">$Conf{'queue'}/T.$sympa_email.$extention") {
	 &error_message('failed');
	 &wwslog('info','do_distribute: could not create %s: %s', "$Conf{'queue'}/T.$sympa_email.$extention",$!);
	 return undef;
     }

     printf DISTRIBUTE ("X-Sympa-To: %s\n",$sympa_email);
     printf DISTRIBUTE ("Message-Id: <%s\@wwsympa>\n", time);
     printf DISTRIBUTE ("From: %s\n\n", $param->{'user'}{'email'});

     foreach my $id (split /\0/, $in{'id'}) {

	 $file = "$Conf{'queuemod'}/$list->{'name'}_$id";

	 printf DISTRIBUTE ("QUIET DISTRIBUTE %s %s\n",$list->{'name'},$id);
	 unless (rename($file,"$file.distribute")) {
	     &error_message('failed');
	     &wwslog('info','do_distribute: failed to rename %s', $file);
	 }


     }
     close DISTRIBUTE;
     rename("$Conf{'queue'}/T.$sympa_email.$extention","$Conf{'queue'}/$sympa_email.$extention");

     &message('performed_soon');

     return 'modindex';
 }

 sub do_viewmod {
     &wwslog('info', 'do_viewmod(%s)', $in{'id'});
     my $msg;

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_viewmod: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_viewmod: no user');
	 return 'loginrequest';
     }

     unless ($in{'id'}) {
	 &error_message('missing_arg', {'argument' => 'msgid'});
	 &wwslog('info','do_viewmod: no msgid');
	 return undef;
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_viewmod: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     my $tmp_dir = $Conf{'queuemod'}.'/.'.$list->{'name'}.'_'.$in{'id'};

     unless (-d $tmp_dir) {
	 &error_message('no_html_message_available');
	 &wwslog('info','do_viewmod: no HTML version of the message available in %s', $tmp_dir);
	 return undef;
     }

     if ($in{'file'}) {
	 $in{'file'} =~ /\.(\w+)$/;
	 $param->{'file_extension'} = $1;
	 $param->{'file'} = "$Conf{'queuemod'}/.$list->{'name'}_$in{'id'}/$in{'file'}";
	 $param->{'bypass'} = 1;
     }else {
	 $param->{'file'} = "$Conf{'queuemod'}/.$list->{'name'}_$in{'id'}/msg00000.html" ;
     }

     $param->{'base'} = sprintf "%s%s/viewmod/%s/%s/", $param->{'base_url'}, $param->{'path_cgi'}, $param->{'list'}, $in{'id'};
     $param->{'id'} = $in{'id'};

     return 1;
 }


 ## Edition of list/sympa files
 ## No list -> sympa files (helpfile,...)
 ## TODO : upload
 sub do_editfile {
     &wwslog('info', 'do_editfile(%s)', $in{'file'});

     $param->{'subtitle'} = sprintf $param->{'subtitle'}, $in{'file'};

     unless ($in{'file'}) {
	 ## Messages edition
	 foreach my $f ('info','homepage','welcome.tpl','bye.tpl','removed.tpl','message.footer','message.header','remind.tpl','invite.tpl','reject.tpl','your_infected_msg.tpl') {
	     next unless ($list->may_edit($f, $param->{'user'}{'email'}) eq 'write');
	     $param->{'files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	     $param->{'files'}{$f}{'selected'} = '';
	 }
	 return 1;
     }

     unless (defined $wwslib::filenames{$in{'file'}}) {
	 &error_message('file_not_editable', {'file' => $in{'file'}});
	 &wwslog('info','do_editfile: file %s not editable', $in{'file'});
	 return undef;
     }

     $param->{'file'} = $in{'file'};

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_editfile: no user');
	 return 'loginrequest';
     }

     if ($param->{'list'}) {
	 unless ($list->may_edit($in{'file'}, $param->{'user'}{'email'}) eq 'write') {
	     &error_message('may_not');
	     &wwslog('info','do_editfile: not allowed');
	     return undef;
	 }

	 ## Add list lang to tpl filename
	 my $file = $in{'file'};
	 $file =~ s/\.tpl$/\.$list->{'admin'}{'lang'}\.tpl/;

	 ## Look for the template
	 $param->{'filepath'} = &tools::get_filename('etc','templates/'.$file,$robot, $list);

	 ## Default for 'homepage' is 'info'
	 if (($in{'file'} eq 'homepage') &&
	     ! $param->{'filepath'}) {
	     $param->{'filepath'} = &tools::get_filename('etc','templates/'.'info',$robot, $list);
	 }
     }else {
	 unless (&List::is_listmaster($param->{'user'}{'email'},$robot)) {
	     &error_message('missing_arg', {'argument' => 'list'});
	     &wwslog('info','do_editfile: no list');
	     return undef;
	 }

	 my $file = $in{'file'};

	 ## Look for the template
	 if ($file eq 'list_aliases.tpl') {
	     $param->{'filepath'} = &tools::get_filename('etc',$file,$robot);
	 }else {
	     my $lang = &Conf::get_robot_conf($robot, 'lang');
	     $file =~ s/\.tpl$/\.$lang\.tpl/;

	     $param->{'filepath'} = &tools::get_filename('etc','templates/'.$file,$robot);
	 }
     }

     if ($param->{'filepath'} && (! -r $param->{'filepath'})) {
	 &error_message('failed');
	 &wwslog('info','do_editfile: cannot read %s', $param->{'filepath'});
	 return undef;
     }

     return 1;
 }

 ## Saving of list files
 sub do_savefile {
     &wwslog('info', 'do_savefile(%s)', $in{'file'});

     $param->{'subtitle'} = sprintf $param->{'subtitle'}, $in{'file'};

     unless ($in{'file'}) {
	 &error_message('missing_arg'. {'argument' => 'file'});
	 &wwslog('info','do_savefile: no file');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_savefile: no user');
	 return 'loginrequest';
     }

     if ($param->{'list'}) {
	 unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	     &error_message('may_not');
	     &wwslog('info','do_savefile: not allowed');
	     return undef;
	 }

	 $param->{'filepath'} = $list->{'dir'}.'/'.$in{'file'};
     }else {
	 unless (&List::is_listmaster($param->{'user'}{'email'}),$robot) {
	     &error_message('missing_arg', {'argument' => 'list'});
	     &wwslog('info','do_savefile: no list');
	     return undef;
	 }

	 if ($robot ne $Conf{'domain'}) {
	     if ($in{'file'} eq 'list_aliases.tpl') {
		 $param->{'filepath'} = "$Conf{'etc'}/$robot/$in{'file'}";
	     }else {
		 $param->{'filepath'} = "$Conf{'etc'}/$robot/templates/$in{'file'}";
	     }
	 }else {
	      if ($in{'file'} eq 'list_aliases.tpl') {
		  $param->{'filepath'} = "$Conf{'etc'}/$in{'file'}";
	      }else {
		  $param->{'filepath'} = "$Conf{'etc'}/templates/$in{'file'}";
	      }
	 }
     }

     unless ((! -e $param->{'filepath'}) or (-w $param->{'filepath'})) {
	 &error_message('failed');
	 &wwslog('info','do_savefile: cannot write %s', $param->{'filepath'});
	 return undef;
     }

     ## Keep the old file
     if (-e $param->{'filepath'}) {
	 rename($param->{'filepath'}, "$param->{'filepath'}.orig");
     }

     ## Not empty
     if ($in{'content'} && ($in{'content'} !~ /^\s*$/)) {			

	 ## Remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
	 $in{'content'} =~ s/\015//g;

	 ## Save new file
	 unless (open FILE, ">$param->{'filepath'}") {
	     &error_message('failed');
	     &wwslog('info','do_savefile: failed to save file %s: %s', $param->{'filepath'},$!);
	     return undef;
	 }
	 print FILE $in{'content'};
	 close FILE;
     }elsif (-f $param->{'filepath'}) {
	 &wwslog('info', 'do_savefile: deleting %s', $param->{'filepath'});
	 unlink $param->{'filepath'};
     }

     &message('performed');

 #    undef $in{'file'};
 #    undef $param->{'file'};
     return 'editfile';
 }

 ## Access to web archives
 sub do_arc {
     &wwslog('info', 'do_arc(%s, %s)', $in{'month'}, $in{'arc_file'});
     my $latest;
     my $index = $wwsconf->{'archive_default_index'};

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_arc: no list');
	 return undef;
     }

     ## Access control
     unless (&List::request_action ('web_archive.access',$param->{'auth_method'},$robot,
				    {'listname' => $param->{'list'},
				     'sender' => $param->{'user'}{'email'},
				     'remote_host' => $param->{'remote_host'},
				     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	 &error_message('may_not');
	 &wwslog('info','do_arc: access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'cookie'){
	 ## Reject Email Sniffers
	 unless (&cookielib::check_arc_cookie($ENV{'HTTP_COOKIE'})) {
	     if ($param->{'user'}{'email'} or $in{'not_a_sniffer'}) {
		 &cookielib::set_arc_cookie($param->{'cookie_domain'});
	     }else {
		 return 'arc_protect';
	     }
	 }
     }
     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'at') {
	 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = ' AT ';	$param->{'hidden_end'} = '';
     }elsif($list->{'admin'}{'web_archive_spam_protection'} eq 'javascript') {
	 $param->{'hidden_head'} = '
 <SCRIPT language="JavaScript">
 <!-- 
 document.write("';
	 $param->{'hidden_at'} ='" + "@" + "';
	 $param->{'hidden_end'} ='")
 // -->
 </SCRIPT>';
     }

     ## Calendar
     unless (opendir ARC, "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}") {
	 &error_message('empty_archives');
	 &wwslog('info','do_arc: no directory %s', "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}");
	 return undef;
     }
     foreach my $dir (sort grep(!/^\./,readdir ARC)) {
	 if ($dir =~ /^(\d{4})-(\d{2})$/) {
	     $param->{'calendar'}{$1}{$2} = 1;
	     $latest = $dir;
	 }
     }
     closedir ARC;

     ## Read html file
     $in{'month'} ||= $latest;

     unless ($in{'arc_file'}) {
	 undef $latest;
	 unless (opendir ARC, "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}") {
	     &wwslog('info',"unable to readdir $wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}");
	     &error_message('month_not_found');
	 }
	 foreach my $file (grep(/^$index/,readdir ARC)) {
	     if ($file =~ /^$index(\d+)\.html$/) {
		 $latest = $1 if ($latest < $1);
	     }
	 }
	 closedir ARC;

	 $in{'arc_file'} = $index.$latest.".html";
     }

     ## File exist ?
     unless (-r "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}/$in{'arc_file'}") {
	 &wwslog('info',"unable to read $wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}/$in{'arc_file'}");
	 &error_message('arc_not_found');
	 return undef;
     }

     ## File type
     unless ($in{'arc_file'} =~ /^(mail\d+|msg\d+|thrd\d+)\.html$/) {
	 $in{'arc_file'} =~ /\.(\w+)$/;
	 $param->{'file_extension'} = $1;

	 if ($param->{'file_extension'} !~ /^html$/i) {
	     $param->{'bypass'} = 1;
	 }
     }

     $param->{'file'} = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}/$in{'arc_file'}";

     $param->{'base'} = sprintf "%s%s/arc/%s/%s/", $param->{'base_url'}, $param->{'path_cgi'}, $param->{'list'}, $in{'month'};

     $param->{'archive_name'} = $in{'month'};

     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'cookie'){
	 &cookielib::set_arc_cookie($param->{'cookie_domain'});
     }

     return 1;
 }

 ## Access to web archives
 sub do_remove_arc {
     &wwslog('info', 'do_remove_arc : list %s, yyyy %s, mm %s, msgid %s', $in{'list'}, $in{'yyyy'}, $in{'month'}, $in{'msgid'});

     ## Access control should allow also email->sender to remove its messages
     #unless ( $param->{'is_owner'}) {
 #	$param->{'error'}{'action'} = 'remove_arc';
 #	&message('may_not_remove_arc');
 #	&wwslog('info','remove_arc: access denied for %s', $param->{'user'}{'email'});
 #	return undef;
 #    }

     if ($in{'msgid'} =~ /NO-ID-FOUND\.mhonarc\.org/) {
	 &error_message('may_not_remove_arc');
	 &wwslog('info','remove_arc: no message id found');
	 $param->{'status'} = 'no_msgid';
	 return undef;
     } 
     ## 
     my $arcpath = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'yyyy'}-$in{'month'}";
     &wwslog('info','remove_arc: looking for %s in %s',$in{'msgid'},"$arcpath/arctxt");

     ## remove url directory if exists
     my $url_dir = $list->{'dir'}.'/urlized/'.$in{'msgid'};
     if (-d $url_dir) {
	 opendir DIR, "$url_dir";
	 my @list = readdir(DIR);
	 closedir DIR;
	 close (DIR);
	 foreach (@list) {
	     unlink ("$url_dir/$_")  ;
	 }
	 unless (rmdir $url_dir) {
		 &wwslog('info',"remove_arc: unable to remove $url_dir");
	 }
     } 

     opendir ARC, "$arcpath/arctxt";
     my $message;
     foreach my $file (grep (!/\./,readdir ARC)) {
	 ## &wwslog('info','remove_arc: scanning %s', $file);
	 next unless (open MAIL,"$arcpath/arctxt/$file") ;
	 while (<MAIL>) {
	     last if /^$/ ;
	     if (/^Message-id:\s?<?([^>\s]+)>?\s?/i ) {
		 my $id = $1;
		 if ($id eq $in{'msgid'}) {
		     $message = $file ;
		 }
		 last ;
	     }
	 }
	 close MAIL ;
	 if ($message) {
	     unless (-d "$arcpath/deleted"){
		 unless (mkdir ("$arcpath/deleted",0777)) {
		     &error_message('may_not_create_deleted_dir');
		     &wwslog('info',"remove_arc: unable to create $arcpath/deleted : $!");
		     $param->{'status'} = 'error';
		     last;
		 }
	     }
	     unless (rename ("$arcpath/arctxt/$message","$arcpath/deleted/$message")) {
		 &error_message('may_not_rename_deleted_message');
		 &wwslog('info',"remove_arc: unable to rename message $arcpath/arctxt/$message");
		 $param->{'status'} = 'error';
		 last;
	     }
	     ## system "cd $arcpath ; $conf->{'mhonarc'} -rmm $in{'msgid'}";


	     my $file = "$Conf{'queueoutgoing'}/.remove.$list->{'name'}\@$list->{'admin'}{'host'}.$in{'yyyy'}-$in{'month'}.".time;

	     unless (open REBUILD, ">$file") {
		 &error_message('failed');
		 &wwslog('info','do_remove: cannot create %s', $file);
		 closedir ARC;
		 return undef;
	     }

	     &do_log('info', 'create File: %s', $file);

	     printf REBUILD ("%s\n",$in{'msgid'});
	     close REBUILD;


	     &wwslog('info', 'do_remove_arc message marked for remove by archived %s', $message);
	     $param->{'status'} = 'done';

	     last;
	 }
     }
     closedir ARC;

     unless ($message) {
	 &wwslog('info', 'do_remove_arc : no file match msgid');
	 $param->{'status'} = 'not_found';
     }

     closedir ARC;
     return 1;
 }

 ## Access to web archives
 sub do_send_me {
     &wwslog('info', 'do_send_me : list %s, yyyy %s, mm %s, msgid %s', $in{'list'}, $in{'yyyy'}, $in{'month'}, $in{'msgid'});

     if ($in{'msgid'} =~ /NO-ID-FOUND\.mhonarc\.org/) {
	 &error_message('may_not_send_me');
	 &wwslog('info','send_me: no message id found');
	 $param->{'status'} = 'no_msgid';
	 return undef;
     } 
     ## 
     my $arcpath = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'yyyy'}-$in{'month'}";
     &wwslog('info','send_me: looking for %s in %s',$in{'msgid'},"$arcpath/arctxt");

     opendir ARC, "$arcpath/arctxt";
     my $msgfile;
     foreach my $file (grep (!/\./,readdir ARC)) {
	 &wwslog('debug','send_me: scanning %s', $file);
	 next unless (open MAIL,"$arcpath/arctxt/$file") ;
	 while (<MAIL>) {
	     last if /^$/ ;
	     if (/^Message-id:\s?<?([^>\s]+)>?\s?/i ) {
		 my $id = $1;
		 if ($id eq $in{'msgid'}) {
		     $msgfile = $file ;
		 }
		 last ;
	     }
	 }
	 close MAIL ;
     }
     if ($msgfile) {
	 my $message;
	 unless ($message = new Message("$arcpath/arctxt/$msgfile")) {
	     &wwslog('info', 'do_send_me : could not create object message for file %s',"$arcpath/arctxt/$msgfile");
	     $param->{'status'} = 'message_err';
	 }

	 my $tempfile =  $Conf{'queue'}."/T.".&Conf::get_robot_conf($robot, 'sympa').".".time.'.'.int(rand(10000)) ;
	 unless (open TMP, ">$tempfile") {
	     &do_log('notice', 'Cannot create %s : %s', $tempfile, $!);
	     return undef;
	 }

	 printf TMP "X-Sympa-To: %s\n", $param->{'user'}{'email'};
	 printf TMP "X-Sympa-From: %s\n", &Conf::get_robot_conf($robot, 'sympa');
	 printf TMP "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($param->{'user'}{'email'});
	 unless (open MSG, "$arcpath/arctxt/$msgfile") {
	     $param->{'status'} = 'message_err';
	     &wwslog('info', 'do_send_me : could not read file %s',"$arcpath/arctxt/$msgfile");
	 }
	 while (<MSG>){print TMP;}
	 close MSG;
	 close TMP;

	 my $new_file = $tempfile;
	 $new_file =~ s/T\.//g;

	 unless (rename $tempfile, $new_file) {
	     &do_log('notice', 'Cannot rename %s to %s : %s', $tempfile, $new_file, $!);
	     return undef;
	 }
	 &wwslog('info', 'do_send_me message %s spooled for %s', "$arcpath/arctxt/$msgfile", $param->{'user'}{'email'} );
	 &message('performed');	
	 $in{'month'} = $in{'yyyy'}."-".$in{'month'};
	 return 'arc';

     }else{
	 &wwslog('info', 'do_send_me : no file match msgid');
	 $param->{'status'} = 'not_found';
	 return undef;
     }

     return 1;
 }

 ## Output an initial form to search in web archives
 sub do_arcsearch_form {
     &wwslog('info', 'do_arcsearch_form(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_arcsearch_form: no list');
	 return undef;
     }

     ## Access control
     unless (&List::request_action ('web_archive.access',$param->{'auth_method'},$robot,
				    {'listname' => $param->{'list'},
				     'sender' => $param->{'user'}{'email'},
				     'remote_host' => $param->{'remote_host'},
				     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	 &error_message('may_not');
	 &wwslog('info','do_arcsearch_form: access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $search_base = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}";
     opendir ARC, "$search_base";
     foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) {
	 if ($dir =~ /^(\d{4})-(\d{2})$/) {
	     push @{$param->{'yyyymm'}}, $dir;
	 }
     }
     closedir ARC;

     $param->{'key_word'} = $in{'key_word'};
     $param->{'archive_name'} = $in{'archive_name'};

     return 1;
 }

 ## Search in web archives
 sub do_arcsearch {
     &wwslog('info', 'do_arcsearch(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &error_message('missing_argument', {'argument' => 'list'});
	 &wwslog('info','do_arcsearch: no list');
	 return undef;
     }

     ## Access control
     unless (&List::request_action ('web_archive.access',$param->{'auth_method'},$robot,
				    {'listname' => $param->{'list'},
				     'sender' => $param->{'user'}{'email'},
				     'remote_host' => $param->{'remote_host'},
				     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	 &error_message('may_not');
	 &wwslog('info','do_arcsearch: access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     use Marc::Search;

     my $search = new Marc::Search;
     $search->search_base ($wwsconf->{'arc_path'} . '/' . $param->{'list'} . '@' . $param->{'host'});
     $search->base_href ($param->{'base_url'}.$param->{'path_cgi'} . '/arc/' . $param->{'list'});
     $search->archive_name ($in{'archive_name'});

     unless (defined($in{'directories'})) {
	 # by default search in current mounth and in the previous none empty one
	 my $search_base = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}";
	 my $previous_active_dir ;
	 opendir ARC, "$search_base";
	 foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) {
	     if (($dir =~ /^(\d{4})-(\d{2})$/) && ($dir lt $search->archive_name)) {
		 $previous_active_dir = $dir;
		 last;
	     }
	 }
	 closedir ARC;
	 $in{'directories'} = $search->archive_name."\0".$previous_active_dir ;
     }

     if (defined($in{'directories'})) {
	 $search->directories ($in{'directories'});
	 foreach my $dir (split/\0/, $in{'directories'})	{
	     push @{$param->{'directories'}}, $dir;
	 }
     }

     if (defined $in{'previous'}) {
	 $search->body_count ($in{'body_count'});
	 $search->date_count ($in{'date_count'});
	 $search->from_count ($in{'from_count'});
	 $search->subj_count ($in{'subj_count'});
	 $search->previous ($in{'previous'});
     }

     ## User didn't enter any search terms
     if ($in{'key_word'} =~ /^\s*$/) {
	 &error_message('missing_argument', {'argument' => 'key_word'});
	 &wwslog('info','do_arcsearch: no search term');
	 return undef;
     }

     $param->{'key_word'} = $in{'key_word'};
     $in{'key_word'} =~ s/\@/\\\@/g;
     $in{'key_word'} =~ s/\[/\\\[/g;
     $in{'key_word'} =~ s/\]/\\\]/g;
     $in{'key_word'} =~ s/\(/\\\(/g;
     $in{'key_word'} =~ s/\)/\\\)/g;
     $in{'key_word'} =~ s/\$/\\\$/g;

     $search->limit ($in{'limit'});

     $search->age (1) 
	 if (($in{'age'} eq 'new') or ($in{'age'} eq '1'));

     $search->match (1) 
	 if (($in{'match'} eq 'partial') or ($in{'match'} eq '1'));

     my @words = split(/\s+/,$in{'key_word'});
     $search->words (\@words);
     $search->clean_words ($in{'key_word'});
     my @clean_words = @words;

     for my $i (0 .. $#words) {
	 $words[$i] =~ s,/,\\/,g;
	 $words[$i] = '\b' . $words[$i] . '\b' if ($in{'match'} eq 'exact');
     }
     $search->key_word (join('|',@words));

     if ($in{'case'} eq 'off') {
	 $search->case(1);
	 $search->key_word ('(?i)' . $search->key_word);
     }
     if ($in{'how'} eq 'any') {
	 $search->function2 ($search->match_any(@words));
	 $search->how ('any');
     }elsif ($in{'how'} eq 'all') {
	 $search->function1 ($search->body_match_all(@clean_words,@words));
	 $search->function2 ($search->match_all(@words));
	 $search->how       ('all');
     }else {
	 $search->function2 ($search->match_this(@words));
	 $search->how       ('phrase');
     }

     $search->subj (defined($in{'subj'}));
     $search->from (defined($in{'from'}));
     $search->date (defined($in{'date'}));
     $search->body (defined($in{'body'}));

     $search->body (1) 
	 if ( not ($search->subj)
	      and not ($search->from)
	      and not ($search->body)
	      and not ($search->date));

     my $searched = $search->search;

     if (defined($search->error)) {
	 &wwslog('info','do_arcsearch_search_error : %s', $search->error);
     }

     $search->searched($searched);

     if ($searched < $search->file_count) {
	 $param->{'continue'} = 1;
     }

     foreach my $field ('list','archive_name','age','body','case','date','from','how','limit','match','subj') {
	 $param->{$field} = $in{$field};
     }

     $param->{'body_count'} = $search->body_count;
     $param->{'clean_words'} = $search->clean_words;
     $param->{'date_count'} = $search->date_count;
     $param->{'from_count'} = $search->from_count;
     $param->{'subj_count'} = $search->subj_count;

     $param->{'num'} = $search->file_count + 1;
     $param->{'searched'} = $search->searched;

     $param->{'res'} = $search->res;

     ## Decode subject header fields
     foreach my $m (@{$param->{'res'}}) {
	 $m->{'subj'} = &MIME::Words::decode_mimewords($m->{'subj'});
     }

     return 1;
 }

 ## Search message-id in web archives
 sub do_arcsearch_id {
     &wwslog('info', 'do_arcsearch_id(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &error_message('missing_argument', {'argument' => 'list'});
	 &wwslog('info','do_arcsearch_id: no list');
	 return undef;
     }

     ## Access control
     unless (&List::request_action ('web_archive.access',$param->{'auth_method'},$robot,
		    {'listname' => $param->{'list'},
		     'sender' => $param->{'user'}{'email'},
		     'remote_host' => $param->{'remote_host'},
		     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	 &error_message('may_not');
	 &wwslog('info','do_arcsearch_id: access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     use Marc::Search;

     my $search = new Marc::Search;
     $search->search_base ($wwsconf->{'arc_path'} . '/' . $param->{'list'} . '@' . $param->{'host'});
     $search->base_href ($param->{'base_url'}.$param->{'path_cgi'} . '/arc/' . $param->{'list'});

     $search->archive_name ($in{'archive_name'});

     # search in current mounth and in the previous none empty one 
     my $search_base = $search->search_base; 
     my $previous_active_dir ; 
     opendir ARC, "$search_base"; 
     foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) { 
	 if (($dir =~ /^(\d{4})-(\d{2})$/) && ($dir lt $search->archive_name)) { 
	     $previous_active_dir = $dir; 
	     last; 
	 } 
     } 
     closedir ARC; 
     $in{'archive_name'} = $search->archive_name."\0".$previous_active_dir ; 

     $search->directories ($in{'archive_name'});
 #    $search->directories ($search->archive_name);

     ## User didn't enter any search terms
     if ($in{'key_word'} =~ /^\s*$/) {
	 &error_message('missing_argument', {'argument' => 'key_word'});
	 &wwslog('info','do_arcsearch_id: no search term');
     return undef;
     }

     $param->{'key_word'} = &tools::unescape_chars($in{'key_word'});
     $in{'key_word'} =~ s/\@/\\\@/g;
     $in{'key_word'} =~ s/\[/\\\[/g;
     $in{'key_word'} =~ s/\]/\\\]/g;
     $in{'key_word'} =~ s/\(/\\\(/g;
     $in{'key_word'} =~ s/\)/\\\)/g;
     $in{'key_word'} =~ s/\$/\\\$/g;

     ## Mhonarc escapes '-' characters (&#45;)
     $in{'key_word'} =~ s/\-/\&\#45\;/g;

     $search->limit (1);

     my @words = split(/\s+/,$in{'key_word'});
     $search->words (\@words);
     $search->clean_words ($in{'key_word'});
     my @clean_words = @words;

     $search->key_word (join('|',@words));

     $search->function2 ($search->match_this(@words));

     $search->id (1);

     my $searched = $search->search;

     if (defined($search->error)) {
	 &wwslog('info','do_arcsearch_id_search_error : %s', $search->error);
     }

     $search->searched($searched);

     $param->{'res'} = $search->res;

     unless ($#{$param->{'res'}} >= 0) {
	 &error_message('msg_not_found');
	 &wwslog('info','No message found in archives matching Message-ID %s', $in{'key_word'});
	 return 'arc';
     }

     $param->{'redirect_to'} = $param->{'res'}[0]{'file'};

     return 1;
 }

 # get pendings lists
 sub do_get_pending_lists {

     &wwslog('info', 'get_pending_lists');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','get_pending_lists :  no user');
	 $param->{'previous_action'} = 'get_pending_lists';
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &do_log('info', 'Incorrect_privilege to get pending');
	 return undef;
     } 

     foreach my $l ( &List::get_lists($robot) ) {
	 my $list = new List ($l,$robot);
	 if ($list->{'admin'}{'status'} eq 'pending') {
	     $param->{'pending'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'pending'}{$l}{'by'} = $list->{'admin'}{'creation'}{'email'};
	 }
     }

     return 1;
 }

 # get closed lists
 sub do_get_closed_lists {

     &wwslog('info', 'get_closed_lists');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','get_closed_lists :  no user');
	 $param->{'previous_action'} = 'get_closed_lists';
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &do_log('info', 'Incorrect_privilege');
	 return undef;
     } 

     foreach my $l ( &List::get_lists($robot) ) {
	 my $list = new List ($l,$robot);
	 if ($list->{'admin'}{'status'} eq 'closed') {
	     $param->{'closed'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'closed'}{$l}{'by'} = $list->{'admin'}{'creation'}{'email'};
	 }
     }

     return 1;
 }

 # get latest lists
 sub do_get_latest_lists {

     &wwslog('info', 'get_latest_lists');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','get_latest_lists :  no user');
	 $param->{'previous_action'} = 'get_latest_lists';
	 return 'loginrequest';
     }

     unless ( $param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &do_log('info', 'Incorrect_privilege');
	 return undef;
     } 

     my @unordered_lists;
     foreach my $l ( &List::get_lists($robot) ) {
	 my $list = new List ($l,$robot);
	 unless ($list) {
	     next;
	 }

	 push @unordered_lists, {'name' => $list->{'name'},
				 'subject' => $list->{'admin'}{'subject'},
				 'creation_date' => $list->{'admin'}{'creation'}{'date_epoch'}};
     }

     foreach my $l (sort {$b->{'creation_date'} <=> $a->{'creation_date'}} @unordered_lists) {
	 push @{$param->{'latest_lists'}}, $l;
	 $l->{'creation_date'} = &POSIX::strftime("%d %b %Y", localtime($l->{'creation_date'}));
     }

     return 1;
 }


 ## show a list parameters
 sub do_set_pending_list_request {
     &wwslog('info', 'set_pending_list(%s)',$in{'list'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','set_pending_list:  no user');
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &do_log('info', 'Incorrect_privilege to open pending list %s from %s', $in{'list'},$param->{'user'}{'email'});
	 return undef;
     } 

     my $list_dir = $list->{'dir'};

     $param->{'list_config'} = $list_dir.'/config';
     $param->{'list_info'} = $list_dir.'/info';
     $param->{'list_subject'} = $list->{'admin'}{'subject'};
     $param->{'list_request_by'} = $list->{'admin'}{'creation'}{'email'};
     $param->{'list_request_date'} = $list->{'admin'}{'creation'}{'date'};
     $param->{'list_serial'} = $list->{'admin'}{'serial'};
     $param->{'list_status'} = $list->{'admin'}{'status'};

     return 1;
 }

 ## show a list parameters
 sub do_install_pending_list {
     &wwslog('info', 'do_install_pending_list(%s,%s,%s)',$in{'list'},$in{'status'},$in{'notify'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_install_pending_list:  no user');
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &error_message('Incorrect_privilege');
	 &do_log('info', 'Incorrect_privilege to open pending list %s from %s', $in{'list'},$param->{'user'}{'email'});
	 return undef;
     } 

     if ($list->{'admin'}{'status'} eq $in{'status'}) {
	 &error_message('huummm_didnt_change_anything');
	 &wwslog('info','view_pending_list: didn t change really the status, nothing to do');
	 return undef ;
     }    

     $list->{'admin'}{'status'} = $in{'status'};

 #    open TMP, ">/tmp/dump1";
 #    dump_var ($list->{'admin'}, 0, \*TMP);
 #    close TMP;

     unless ($list->save_config($param->{'user'}{'email'})) {
	 &error_message('cannot_save_config');
	 &wwslog('info','_create_list: Cannot save config file');
	 return undef;
     }

 #    open TMP, ">/tmp/dump2";
 #    dump_var ($list->{'admin'}, 0, \*TMP);
 #    close TMP;

     ## create the aliases
     if ($in{'status'} eq 'open') {
	 &_install_aliases();
     }

     if ($in{'notify'}) {
	 foreach my $i (@{$list->{'admin'}{'owner'}}) {
	     next if ($i->{'reception'} eq 'nomail');
	     next unless ($i->{'email'});
	     if ($in{'status'} eq 'open') {
		 $list->send_file('list_created', $i->{'email'}, $robot,{});
	     }elsif ($in{'status'} eq 'closed') {
		 $list->send_file('list_rejected', $i->{'email'}, $robot,{});
	     }
	 }
     }

     $param->{'status'} = $in{'status'};

     if ($in{'status'} ne 'open') {
	 $list = $param->{'list'} = $in{'list'} = undef;
	 return 'get_pending_lists';
     }

     return 1;
 }

 ## Install sendmail aliases
 sub _install_aliases {
     &wwslog('info', "_install_aliases($list->{'name'},$list->{'admin'}{'host'})");

     my $alias_manager = '--SBINDIR--/alias_manager.pl';
     &do_log('debug2',"$alias_manager add $list->{'name'} $list->{'admin'}{'host'}");
     if (-x $alias_manager) {
	 system ("$alias_manager add $list->{'name'} $list->{'admin'}{'host'}") ;
	 my $status = $? / 256;
	 if ($status == '0') {
	     &wwslog('info','Aliases installed successfully') ;
	     $param->{'auto_aliases'} = 1;
	 }elsif ($status == '1') {
	     &wwslog('info','Configuration file --CONFIG-- has errors');
	 }elsif ($status == '2')  {
	     &wwslog('info','Internal error : Incorrect call to alias_manager');
	 }elsif ($status == '3')  {
	     &wwslog('info','Could not read sympa config file, report to httpd error_log') ;
	 }elsif ($status == '4')  {
	     &wwslog('info','Could not get default domain, report to httpd error_log') ;
	 }elsif ($status == '5')  {
	     &wwslog('info','Unable to append to alias file') ;
	 }elsif ($status == '6')  {
	     &wwslog('info','Unable run newaliases') ;
	 }elsif ($status == '7')  {
	     &wwslog('info','Unable to read alias file, report to httpd error_log') ;
	 }elsif ($status == '8')  {
	     &wwslog('info','Could not create temporay file, report to httpd error_log') ;
	 }elsif ($status == '13') {
	     &wwslog('info','Some of list aliases already exist') ;
	 }elsif ($status == '14') {
	     &wwslog('info','Can not open lock file, report to httpd error_log') ;
	 }else {
	     &error_message('failed_to_install_aliases');
	     &wwslog('info',"Unknown error $status while running alias manager $alias_manager");
	 } 
     }else {
	 &wwslog('info','Failed to install aliases: %s', $!);
	 &error_message('failed_to_install_aliases');
     }

     unless ($param->{'auto_aliases'}) {
	 my $template_file = &tools::get_filename('etc', 'list_aliases.tpl', $robot);
	 my @aliases ;
	 my %data;
	 $data{'list'}{'domain'} = $data{'robot'} = $robot;
	 $data{'list'}{'name'} = $list->{'name'};
	 $data{'default_domain'} = $Conf{'domain'};
	 $data{'is_default_domain'} = 1 if ($robot == $Conf{'domain'});
	 &parser::parse_tpl (\%data,$template_file,\@aliases);
	 $param->{'aliases'}  = '';
	 foreach (@aliases) {$param->{'aliases'} .= $_; }
     }

     return 1;
 }

 ## Remove sendmail aliases
 sub _remove_aliases {
     &wwslog('info', "_remove_aliases($list->{'name'},$list->{'admin'}{'host'})");

     my $alias_manager = '--SBINDIR--/alias_manager.pl';

     unless (-x $alias_manager) {
	 &wwslog('info','Cannot run alias_manager %s', $alias_manager);
	 &error_message('failed_to_remove_aliases');
     }

     system ("$alias_manager del $list->{'name'} $list->{'admin'}{'host'}");
     my $status = $? / 256;
     if ($status == 0) {
	 &wwslog('info','Aliases removed successfully');
	 $param->{'auto_aliases'} = 1;
     }else {
	 &wwslog('info','Failed to remove aliases ; status %d : %s', $status, $!);
	 &error_message('failed_to_remove_aliases');
     }

     unless ($param->{'auto_aliases'}) {
	 $param->{'aliases'}  = "#----------------- $in{'list'}\n";
	 $param->{'aliases'} .= "$in{'list'}: \"| --MAILERPROGDIR--/queue $in{'list'}\"\n";
	 $param->{'aliases'} .= "$in{'list'}-request: \"| --MAILERPROGDIR--/queue $in{'list'}-request\"\n";
	 $param->{'aliases'} .= "$in{'list'}-owner: \"| --MAILERPROGDIR--/bouncequeue $in{'list'}\"\n";
	 $param->{'aliases'} .= "$in{'list'}-unsubscribe: \"| --MAILERPROGDIR--/queue $in{'list'}-unsubscribe\"\n";
	 $param->{'aliases'} .= "# $in{'list'}-subscribe: \"| --MAILERPROGDIR--/queue $in{'list'}-subscribe\"\n";
     }

     return 1;
 }

 ## check if the requested list exists already using smtp 'rcpt to'
 sub list_check_smtp {
     my $list = shift;
     my $conf = '';
     my $smtp;
     my (@suf, @addresses);

     my $smtp_relay = $Conf{'robots'}{$robot}{'list_check_smtp'} || $Conf{'list_check_smtp'};
     my $suffixes = $Conf{'robots'}{$robot}{'list_check_suffixes'} || $Conf{'list_check_suffixes'};
     return 0 
	 unless ($smtp_relay && $suffixes);
     my $domain = &Conf::get_robot_conf($robot, 'host');
     &wwslog('debug2', 'list_check_smtp(%s)',$in{'listname'});
     @suf = split(/,/,$suffixes);
     return 0 if ! @suf;
     for(@suf) {
	 push @addresses, $list."-$_\@".$domain;
     }
     push @addresses,"$list\@" . $domain;

     unless (require Net::SMTP) {
	 do_log ('err',"Unable to use Net library, Net::SMTP required, install it (CPAN) first");
	 return undef;
     }
     if( $smtp = Net::SMTP->new($smtp_relay,
				Hello => $smtp_relay,
				Timeout => 30) ) {
	 $smtp->mail('');
	 for(@addresses) {
		 $conf = $smtp->to($_);
		 last if $conf;
	 }
	 $smtp->quit();
	 return $conf;
    }
    return undef;
 }

 ## create a liste using a list template. 
 sub do_create_list {

     &wwslog('info', 'do_create_list(%s,%s,%s)',$in{'listname'},$in{'subject'},$in{'template'});

     foreach my $arg ('listname','subject','template','info','topics') {
	 unless ($in{$arg}) {
	     &error_message('missing_arg', {'argument' => $arg});
	     &wwslog('info','do_create_list: missing param %s', $arg);
	     return undef;
	 }
     }

     $in{'listname'} = lc ($in{'listname'});

     unless ($in{'listname'} =~ /^[a-z0-9][a-z0-9\-\+\._]*$/i) {
	 &error_message('incorrect_listname', {'listname' => $in{'listname'}});
	 &wwslog('info','do_create_list: incorrect listname %s', $in{'listname'});
	 return 'create_list_request';
     }

     my $regx = Conf::get_robot_conf($robot,'list_check_regexp');
     if( $regx ) {
	 if ($in{'listname'} =~ /^(\S+)-($regx)$/) {
	     &error_message("Incorrect listname \"$in{'listname'}\" matches one of service aliases",{'listname' => $in{'listname'}});
	     &wwslog('info','do_create_list: incorrect listname %s matches one of service aliases', $in{'listname'});
	     return 'create_list_request';
	 }
     }
     ## 'other' topic means no topic
     $in{'topics'} = undef if ($in{'topics'} eq 'other');

     ## Check listname on SMTP server
     my $res = list_check_smtp($in{'listname'});
     unless ( defined($res) ) {
	 &error_message('unable_to_check_list_using_smtp');
	 &do_log('err', "can't check list %.128s on %.128s",
		 $in{'listname'},
		 $wwsconf->{'list_check_smtp'});
	 return undef;
     }
     if( $res || new List ($in{'listname'})) {
	 &error_message('list_already_exists');
	 &do_log('info', 'could not create already existing list %s for %s', 
		 $in{'listname'},
		 $param->{'user'}{'email'});
	 return undef;
     }


     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_create_list_request:  no user');
	 return 'loginrequest';
     }
     my $lang = $param->{'lang'};

     $param->{'create_action'} = $param->{'create_list'};

     &wwslog('info',"do_create_list, get action : $param->{'create_action'} ");

     if ($param->{'create_action'} =~ /reject/) {
	 &error_message('may_not');
	 &wwslog('info','do_create_list: not allowed');
	 return undef;
     }elsif ($param->{'create_action'} =~ /listmaster/i) {
	 $param->{'status'} = 'pending' ;
     }elsif  ($param->{'create_action'} =~ /do_it/i) {
	 $param->{'status'} = 'open' ;
     }else{
	 &error_message('internal_scenario_error');
	 &wwslog('info','do_create_list: internal error in scenario create_list');
	 return undef;
     }

     my $template_file = &tools::get_filename('etc', 'create_list_templates/'.$in{'template'}.'/config.tpl', $robot);
     unless ($template_file) {
	 &error_message('unable_to_open_template');
	 &do_log('info', 'no template %s in %s NOR %s',$in{'template'},"$Conf{'etc'}/$robot/create_list_templates/$in{'template'}","$Conf{'etc'}/create_list_templates/$in{'template'}","--ETCBINDIR--/create_list_templates/$in{'template'}");

	 return undef;
     }

     my $list_dir;

     ## A virtual robot
     if ($robot ne $Conf{'domain'}) {
	 unless (-d $Conf{'home'}.'/'.$robot) {
	     unless (mkdir ($Conf{'home'}.'/'.$robot,0777)) {
		 &error_message('unable_to_create_dir');
		 &do_log('info', 'unable to create %s/%s : %s',$Conf{'home'},$robot,$?);
		 return undef;
	     }    
	 }

	 $list_dir = $Conf{'home'}.'/'.$robot.'/'.$in{'listname'};
     }else {
	 $list_dir = $Conf{'home'}.'/'.$in{'listname'};
     }

     unless (mkdir ($list_dir,0777)) {
	 &error_message('unable_to_create_dir');
	 &do_log('info', 'unable to create %s : %s',$list_dir,$?);
	 return undef;
     }    

     my $parameters;
     $parameters->{'owner'}{'email'} = $param->{'user'}{'email'};
     $parameters->{'owner'}{'gecos'} = $param->{'user'}{'gcos'};
     $parameters->{'listname'} = $in{'listname'};
     $parameters->{'subject'} = $in{'subject'};
     $parameters->{'creation'}{'date'} = $param->{'date'};
     $parameters->{'creation'}{'date_epoch'} = time;
     $parameters->{'creation'}{'email'} = $param->{'user'}{'email'};
     $parameters->{'lang'} = $lang;
     $parameters->{'status'} = $param->{'status'};
     $parameters->{'topics'} = $in{'topics'};

     open CONFIG, ">$list_dir/config";
     &parser::parse_tpl($parameters, $template_file, \*CONFIG);
     close CONFIG;

     ## Remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
     $in{'info'} =~ s/\015//g;

     open INFO, ">$list_dir/info" ;
     print INFO $in{'info'};
     close INFO;

     ## Create list object
     $in{'list'} = $in{'listname'};
     &check_param_in();

     if  ($param->{'create_action'} =~ /do_it/i) {
	 &_install_aliases();
     }

     ## notify listmaster
     if ($param->{'create_action'} =~ /notify/) {
	 &do_log('info','notify listmaster');
	 &List::send_notify_to_listmaster('request_list_creation',$robot, $in{'listname'},$parameters->{'owner'}{'email'});
     }
     return 1;
 }

 ## Return the creation form
 sub do_create_list_request {
     &wwslog('info', 'do_create_list_request()');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_create_list_request:  no user');
	 $param->{'previous_action'} = 'create_list_request';
	 return 'loginrequest';
     }

     $param->{'create_action'} = &List::request_action('create_list',$param->{'auth_method'},$robot,
						       {'sender' => $param->{'user'}{'email'},
							'remote_host' => $param->{'remote_host'},
							'remote_addr' => $param->{'remote_addr'}});

     ## Initialize the form
     ## When returning to the form
     foreach my $p ('listname','template','subject','topics','info') {
	 $param->{'saved'}{$p} = $in{$p};
     }

     if ($param->{'create_action'} =~ /reject/) {
	 &error_message('may_not');
	 &wwslog('info','do_create_list: not allowed');
	 return undef;
     }

     my %topics;
     unless (%topics = &List::load_topics($robot)) {
	 &error_message('unable_to_load_list_of_topics');
     }
     $param->{'list_of_topics'} = \%topics;

     $param->{'list_of_topics'}{$in{'topics'}}{'selected'} = 1
	 if ($in{'topics'});

     unless ($param->{'list_list_tpl'} = &tools::get_list_list_tpl($robot)) {
	 &error_message('unable_to_load_create_list_templates');
     }	

     foreach my $template (keys %{$param->{'list_list_tpl'}}){
	 $param->{'tpl_count'} ++ ;
     }

     $param->{'list_list_tpl'}{$in{'template'}}{'selected'} = 1
	 if ($in{'template'});


     return 1 ;

 }

 ## WWSympa Home-Page
 sub do_home {
     &wwslog('info', 'do_home');
     # all variables are set in export_topics

     return 1;
 }

 sub do_editsubscriber {
     &wwslog('info', 'do_editsubscriber(%s)', $in{'email'});

     my $user;

     unless ($param->{'is_owner'}) {
	 &error_message('may_not');
	 &wwslog('info','do_editsubscriber: may not edit');
	 return undef;
     }

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_editsubscriber: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_editsubscriber: no email');
	 return undef;
     }

     $in{'email'} = &tools::unescape_chars($in{'email'});

     unless($user = $list->get_subscriber($in{'email'})) {
	 &error_message('subscriber_not_found', {'email' => $in{'email'}});
	 &wwslog('info','do_editsubscriber: subscriber %s not found', $in{'email'});
	 return undef;
     }

     $param->{'current_subscriber'} = $user;
     $param->{'current_subscriber'}{'escaped_email'} = &tools::escape_html($param->{'current_subscriber'}{'email'});

     $param->{'current_subscriber'}{'date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'date'}));
     $param->{'current_subscriber'}{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'update_date'}));

     ## Prefs
     $param->{'current_subscriber'}{'reception'} ||= 'mail';
     $param->{'current_subscriber'}{'visibility'} ||= 'noconceal';
     foreach my $m (keys %wwslib::reception_mode) {		
       if ($list->is_available_reception_mode($m)) {
	 $param->{'reception'}{$m}{'description'} = $wwslib::reception_mode{$m};
	 if ($param->{'current_subscriber'}{'reception'} eq $m) {
	     $param->{'reception'}{$m}{'selected'} = 'SELECTED';
	 }else {
	     $param->{'reception'}{$m}{'selected'} = '';
	 }
       }
     }

     ## Bounces
     if ($user->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/) {
	 my @bounce = ($1, $2, $3, $5);
	 $param->{'current_subscriber'}{'first_bounce'} = &POSIX::strftime("%d %b %Y", localtime($bounce[0]));
	 $param->{'current_subscriber'}{'last_bounce'} = &POSIX::strftime("%d %b %Y", localtime($bounce[1]));
	 $param->{'current_subscriber'}{'bounce_count'} = $bounce[2];
	 if ($bounce[3] =~ /^(\d+\.(\d+\.\d+))$/) {
	    $user->{'bounce_code'} = $1;
	    $user->{'bounce_status'} = $wwslib::bounce_status{$2};
	 }	

	 $param->{'previous_action'} = $in{'previous_action'};
     }

     ## Additional DB fields
     if ($Conf{'db_additional_subscriber_fields'}) {
	 my @additional_fields = split ',', $Conf{'db_additional_subscriber_fields'};

	 my %data;

	 foreach my $field (@additional_fields) {

	     ## Is the Database defined
	     unless ($Conf{'db_name'}) {
		 &do_log('info', 'No db_name defined in configuration file');
		 return undef;
	     }

	     ## Check field type (enum or not) with MySQL
	     $data{$field}{'type'} = &List::get_db_field_type('subscriber_table', $field);
	     if ($data{$field}{'type'} =~ /^enum\((\S+)\)$/) {
		 my @enum = split /,/,$1;
		 foreach my $e (@enum) {
		     $e =~ s/^\'([^\']+)\'$/$1/;
		     $data{$field}{'enum'}{$e} = '';
		 }
		 $data{$field}{'type'} = 'enum';

		 $data{$field}{'enum'}{$user->{$field}} = 'SELECTED'
		     if (defined $user->{$field});
	     }else {
		 $data{$field}{'type'} = 'string';
		 $data{$field}{'value'} = $user->{$field};
	     } 
	 }
	 $param->{'additional_fields'} = \%data;
     }

     return 1;
 }

 sub do_viewbounce {
     &wwslog('info', 'do_viewbounce(%s)', $in{'email'});

     unless ($param->{'is_owner'}) {
	 &error_message('may_not');
	 &wwslog('info','do_viewbounce: may not view');
	 return undef;
     }

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_viewbounce: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_viewbounce: no email');
	 return undef;
     }

     my $escaped_email = &tools::escape_chars($in{'email'});

     $param->{'lastbounce_path'} = "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email";

     unless (-r $param->{'lastbounce_path'}) {
	 &error_message('no_bounce', {'email' => $in{'email'}});
	 &wwslog('info','do_viewbounce: no bounce %s', $param->{'lastbounce_path'});
	 return undef;
     }

     return 1;
 }

 ## some help for listmaster and developpers
 sub do_scenario_test {
     &wwslog('info', 'do_scenario_test');

     ## List available scenarii
     unless (opendir SCENARI, "--ETCBINDIR--/scenari/"){
	 &wwslog('info',"do_scenario_test : unable to open --ETCBINDIR--/scenari");
	 &error_message('scenari_wrong_access');
	 return undef;
     }

     foreach my $scfile (readdir SCENARI) {
	 if ($scfile =~ /^(\w+)\.(\w+)/ ) {
	     $param->{'scenario'}{$1}{'defined'}=1 ;
	 }
     }
     closedir SCENARI;
     foreach my $l ( &List::get_lists('*') ) {
	 $param->{'listname'}{$l}{'defined'}=1 ;
     }
     foreach my $a ('smtp','md5','smime') {
	 #$param->{'auth_method'}{$a}{'define'}=1 ;
	 $param->{'authmethod'}{$a}{'defined'}=1 ;
     }

     $param->{'scenario'}{$in{'scenario'}}{'selected'} = 'SELECTED' if $in{'scenario'};

     $param->{'listname'}{$in{'listname'}}{'selected'} = 'SELECTED' if $in{'listname'};

     $param->{'authmethod'}{$in{'auth_method'}}{'selected'} = 'SELECTED' if $in{'auth_method'};

     $param->{'email'} = $in{'email'};

     if ($in{'scenario'}) {
	 my $operation = $in{'scenario'};
	 &wwslog('debug4', 'do_scenario_test: perform scenario_test');
	 ($param->{'scenario_condition'},$param->{'scenario_auth_method'},$param->{'scenario_action'}) = 
	     &List::request_action ($operation,$in{'auth_method'},$robot,
				    {'listname' => $in{'listname'},
				     'sender' => $in{'sender'},
				     'email' => $in{'email'},
				     'remote_host' => $in{'remote_host'},
				     'remote_addr' => $in{'remote_addr'}}, 'debug');	
     }
     return 1;
 }

 ## Bouncing addresses review
 sub do_reviewbouncing {
     &wwslog('info', 'do_reviewbouncing(%d)', $in{'page'});
     my $size = $in{'size'} || $wwsconf->{'review_page_size'};

     unless ($in{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_reviewbouncing: no list');
	 return undef;
     }

     unless ($param->{'is_owner'}) {
	 &error_message('may_not');
	 &wwslog('info','do_reviewbouncing: may not review');
	 return 'admin';
     }

     unless ($param->{'bounce_total'}) {
	 &error_message('no_bouncing_subscriber');
	 &wwslog('info','do_reviewbouncing: no bouncing subscriber');
	 return 'admin';
     }

     ## Owner
     $param->{'page'} = $in{'page'} || 1;
     $param->{'total_page'} = int ( $param->{'bounce_total'} / $size);
     $param->{'total_page'} ++
	 if ($param->{'bounce_total'} % $size);

     if ($param->{'page'} > $param->{'total_page'}) {
	 &error_message('no_page', {'page' => $param->{'page'}});
	 &wwslog('info','do_reviewbouncing: no page %d', $param->{'page'});
	 return 'admin';
     }

     my @users;
     ## Members list
     for (my $i = $list->get_first_bouncing_user(); $i; $i = $list->get_next_bouncing_user()) {
	 $i->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
	 $i->{'first_bounce'} = $1;
	 $i->{'last_bounce'} = $2;
	 $i->{'bounce_count'} = $3;
	 if ($5 =~ /^(\d+)\.\d+\.\d+$/) {
	     $i->{'bounce_class'} = $1;
	 }	

	 push @users, $i;
     }

     my $record;
     foreach my $i (sort 
		    {($b->{'bounce_count'} <=> $a->{'bounce_count'}) ||
			 ($b->{'last_bounce'} <=> $a->{'last_bounce'}) ||
			     ($b->{'bounce_class'} <=> $a->{'bounce_class'}) }
		    @users) {
	 $record++;

	 if ($record > ( $size * ($param->{'page'} ) ) ) {
	     $param->{'next_page'} = $param->{'page'} + 1;
	     last;
	 }

	 next if ($record <= ( ($param->{'page'} - 1) *  $size));

	 $i->{'first_bounce'} = &POSIX::strftime("%d %b %Y", localtime($i->{'first_bounce'}));
	 $i->{'last_bounce'} = &POSIX::strftime("%d %b %Y", localtime($i->{'last_bounce'}));

	 ## Escape some weird chars
	 $i->{'escaped_email'} = &tools::escape_chars($i->{'email'});

	 push @{$param->{'members'}}, $i;
     }

     if ($param->{'page'} > 1) {
	 $param->{'prev_page'} = $param->{'page'} - 1;
     }

     $param->{'size'} = $in{'size'};

     return 1;
 }

 sub do_resetbounce {
     &wwslog('info', 'do_resetbounce()');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_resetbounce: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_resetbounce: no email');
	 return undef;
     }

     $in{'email'} = &tools::unescape_chars($in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_resetbounce: no user');
	 return 'loginrequest';
     }

     ## Require DEL privilege
     my $del_is = &List::request_action ('del',$param->{'auth_method'},$robot,
	 {'listname' => $param->{'list'}, 
	  'sender' => $param->{'user'}{'email'},
	  'email' => $in{'email'},
	  'remote_host' => $param->{'remote_host'},
	  'remote_addr' => $param->{'remote_addr'}});

     unless ( $del_is =~ /do_it/) {
	 &error_message('may_not');
	 &wwslog('info','do_resetbounce: %s may not reset', $param->{'user'}{'email'});
	 return undef;
     }

     my @emails = split /\0/, $in{'email'};

     foreach my $email (@emails) {

	 my $escaped_email = &tools::escape_chars($email);

	 unless ( $list->is_user($email) ) {
	     &error_message('not_subscriber', {'email' => $email});
	     &wwslog('info','do_del: %s not subscribed', $email);
	     return undef;
	 }

	 unless( $list->update_user($email, {'bounce' => 'NULL', 'update_date' => time})) {
	     &error_message('failed');
	     &wwslog('info','do_resetbounce: failed update database for %s', $email);
	     return undef;
	 }

	 unless (unlink "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email") {
	     &wwslog('info','do_resetbounce: failed deleting %s', "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email");
	 }

	 &wwslog('info','do_resetbounce: bounces for %s reset ', $email);

     }

     return $in{'previous_action'} || 'review';
 }

 ## Rebuild an archive using arctxt/
 sub do_rebuildarc {
     &wwslog('info', 'do_rebuildarc(%s, %s)', $param->{'list'}, $in{'month'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_rebuildarc: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_rebuildarc: no user');
	 return 'loginrequest';
     }

     unless ($param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_rebuildarc: not listmaster');
	 return undef;
     }

     my $file = "$Conf{'queueoutgoing'}/.rebuild.$list->{'name'}\@$list->{'admin'}{'host'}";

     unless (open REBUILD, ">$file") {
	 &error_message('failed');
	 &wwslog('info','do_rebuildarc: cannot create %s', $file);
	 return undef;
     }

     &do_log('info', 'File: %s', $file);

     print REBUILD ' ';
     close REBUILD;

     &message('performed');

     return 'admin';
 }

 ## Rebuild all archives using arctxt/
 sub do_rebuildallarc {
     &wwslog('info', 'do_rebuildallarc');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_rebuildallarc: no user');
	 return 'loginrequest';
     }

     unless ($param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_rebuildallarc: not listmaster');
	 return undef;
     }
     foreach my $l ( &List::get_lists($robot) ) {
	 my $list = new List ($l,$robot); 
	 next unless (defined $list->{'admin'}{'web_archive'});
	 my $file = "$Conf{'queueoutgoing'}/.rebuild.$list->{'name'}\@$list->{'admin'}{'host'}";

	 unless (open REBUILD, ">$file") {
	     &error_message('failed');
	     &wwslog('info','do_rebuildarc: cannot create %s', $file);
	     return undef;
	 }

	 &do_log('info', 'File: %s', $file);

	 print REBUILD ' ';
	 close REBUILD;

     }
     &message('performed');

     return 'serveradmin';
 }

 ## Search among lists
 sub do_search_list {
     &wwslog('info', 'do_search_list(%s)', $in{'filter'});

     unless ($in{'filter'}) {
	 &error_message('no_filter');
	 &wwslog('info','do_search_list: no filter');
	 return undef;
     }

     ## Regexp
     $param->{'filter'} = $in{'filter'};
     $param->{'regexp'} = $param->{'filter'};
     $param->{'regexp'} =~ s/\\/\\\\/g;
     $param->{'regexp'} =~ s/\./\\\./g;
     $param->{'regexp'} =~ s/\*/\.\*/g;
     $param->{'regexp'} =~ s/\+/\\\+/g;
     $param->{'regexp'} =~ s/\?/\\\?/g;

     ## Members list
     my $record = 0;
     foreach my $l ( &List::get_lists($robot) ) {
	 my $is_admin;
	 my $list = new List ($l, $robot);

	 ## Search filter
	 next if (($list->{'name'} !~ /$param->{'regexp'}/i) 
		  && ($list->{'admin'}{'subject'} !~ /$param->{'regexp'}/i));

	 my $action = &List::request_action ('visibility',$param->{'auth_method'},$robot,
					     {'listname' =>  $list->{'name'},
					      'sender' => $param->{'user'}{'email'}, 
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}});

	 next unless ($action eq 'do_it');

	 if ($param->{'user'}{'email'} &&
	     ($list->am_i('owner',$param->{'user'}{'email'}) ||
	      $list->am_i('editor',$param->{'user'}{'email'})) ) {
	     $is_admin = 1;
	 }

	 $record++;
	 $param->{'which'}{$list->{'name'}} = {'host' => $list->{'admin'}{'host'},
					       'subject' => $list->{'admin'}{'subject'},
					       'admin' => $is_admin,
					       'export' => 'no'};
     }
     $param->{'occurrence'} = $record;

     ##Lists stored in ldap directories
     my %lists;
     if($in{'extended'}){
	 foreach my $directory (keys %{$Conf{'ldap_export'}}){
	     next unless(%lists = &Ldap::get_exported_lists($param->{'regexp'},$directory));

	     foreach my $list_name (keys %lists) {
		 $param->{'occurrence'}++ unless($param->{'which'}{$list_name});
		 next if($param->{'which'}{$list_name});
		 $param->{'which'}{$list_name} = {'host' => "$lists{$list_name}{'host'}",
						  'subject' => "$lists{$list_name}{'subject'}",
						  'urlinfo' => "$lists{$list_name}{'urlinfo'}",
						  'list_address' => "$lists{$list_name}{'list_address'}",
						  'export' => 'yes',
					      };
	     } 
	 }
     }

     return 1;
 }

 sub do_edit_list {
     &wwslog('info', 'do_edit_list()');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_edit_list:  no user');
	 return 'loginrequest';
     }

     unless ($param->{'is_owner'}) {
	 &error_message('may_not');
	 &wwslog('info','do_edit_list: not allowed');
	 return undef;
     }

     my $new_admin = {};

     ## List the parameters editable sent in the form
     my $edited_param = {};

     foreach my $key (sort keys %in) {
	 next unless ($key =~ /^(single_param|multiple_param)\.(\S+)$/);

	 $key =~ /^(single_param|multiple_param)\.(\S+)$/;
	 my ($type, $name) = ($1, $2);

	 ## Tag parameter as present in the form
	 $name =~ /^([^\.]+)(\.|$)/;
	 $edited_param->{$1} = 1;

	 ## Parameter value
	 my $value = $in{$key};
	 next if ($value eq '');

	 if ($type eq 'multiple_param') {
	     my @values = split /\0/, $value;
	     $value = \@values;
	 }

	 my @token = split /\./, $name;

	 ## make it an entry in $new_admin
	 my $var = &_shift_var(0, $new_admin, @token);
	 $$var = $value;
     } 

 #    print "Content-type: text/plain\n\n";
 #    &dump_var($new_admin,0);

     ## Did the config changed ?
     unless ($list->{'admin'}{'serial'} == $in{'serial'}) {
	 &error_message('config_changed', {'email' => $list->{'admin'}{'update'}{'email'}});
	 &wwslog('info','do_edit_list: Config file has been modified(%d => %d) by %s. Cannot apply changes', $in{'single_param.serial'}, $list->{'admin'}{'serial'}, $list->{'admin'}{'update'}{'email'});
	 return undef;
     }

     ## Check changes & check syntax
     my (%changed, %delete);
     my @syntax_error;
     foreach my $pname (sort List::by_order keys %{$edited_param}) {

	 my ($p, $new_p);
	 ## Check privileges first
	 next unless ($list->may_edit($pname,$param->{'user'}{'email'}) eq 'write');
	 #next unless (defined $new_admin->{$pname});
	 next if $pinfo->{$pname}{'obsolete'};

	 my $to_index;

	 ## Single vs multiple parameter
	 if ($pinfo->{$pname}{'occurrence'} =~ /n$/) {

	     my $last_index = $#{$new_admin->{$pname}};

	     if ($#{$list->{'admin'}{$pname}} < $last_index) {
		 $to_index = $last_index;
	     }else {
		 $to_index = $#{$list->{'admin'}{$pname}};
	     }

	     if ($#{$list->{'admin'}{$pname}} != $last_index) {
		 $changed{$pname} = 1; 
		 #next;
	     }
	     $p = $list->{'admin'}{$pname};
	     $new_p = $new_admin->{$pname};
	 }else {
	     $p = [$list->{'admin'}{$pname}];
	     $new_p = [$new_admin->{$pname}];
	 }

	 ## Check changed parameters
	 ## Also check syntax
	 foreach my $i (0..$to_index) {

	     ## Scenario
	     ## Eg: 'subscribe'
	     if ($pinfo->{$pname}{'scenario'} || $pinfo->{$pname}{'task'}) {
		 if ($p->[$i]{'name'} ne $new_p->[$i]{'name'}) {
		     $changed{$pname} = 1; next;
		 }
		 ## Hash
		 ## Ex: 'owner'
	     }elsif (ref ($pinfo->{$pname}{'format'}) eq 'HASH') {

		 ## Foreach Keys
		 ## Ex: 'owner->email'
		 foreach my $key (keys %{$pinfo->{$pname}{'format'}}) {

		     next unless ($list->may_edit("$pname.$key",$param->{'user'}{'email'}) eq 'write');

		     ## Ex: 'shared_doc->d_read'
		     if ($pinfo->{$pname}{'format'}{$key}{'scenario'} || $pinfo->{$pname}{'format'}{$key}{'task'}) {
			 if ($p->[$i]{$key}{'name'} ne $new_p->[$i]{$key}{'name'}) {
			     $changed{$pname} = 1; next;
			 }
		     }else{
			 ## Multiple param
			 if ($pinfo->{$pname}{'format'}{$key}{'occurrence'} =~ /n$/) {

			     if ($#{$p->[$i]{$key}} != $#{$new_p->[$i]{$key}}) {
				 $changed{$pname} = 1; next;
			     }

			     ## Multiple param, foreach entry
			     ## Ex: 'digest->days'
			     foreach my $index (0..$#{$p->[$i]{$key}}) {

				 my $format = $pinfo->{$pname}{'format'}{$key}{'format'};
				 if (ref ($format)) {
				     $format = $pinfo->{$pname}{'format'}{$key}{'file_format'};
				 }

				 if ($p->[$i]{$key}[$index] ne $new_p->[$i]{$key}[$index]) {

				     if ($new_p->[$i]{$key}[$index] !~ /^$format$/i) {
					 push @syntax_error, $pname;
				     }
				     $changed{$pname} = 1; next;
				 }
			     }

			 ## Single Param
			 ## Ex: 'owner->email'
			 }else {
			     if (! $new_p->[$i]{$key}) {
				 ## If empty and is primary key => delete entry
				 if ($pinfo->{$pname}{'format'}{$key}{'occurrence'} =~ /^1/) {
				     $new_p->[$i] = undef;

				     ## Skip the rest of the paragraph
				     $changed{$pname} = 1; last;

				     ## If optionnal parameter
				 }else {
				     $changed{$pname} = 1; next;
				 }
			     }
			     if ($p->[$i]{$key} ne $new_p->[$i]{$key}) {

				 my $format = $pinfo->{$pname}{'format'}{$key}{'format'};
				 if (ref ($format)) {
				     $format = $pinfo->{$pname}{'format'}{$key}{'file_format'};
				 }

				 if ($new_p->[$i]{$key} !~ /^$format$/i) {
				     push @syntax_error, $pname;
				 }

				 $changed{$pname} = 1; next;
			     }
			 }
		     }
		 }
	     ## Scalar
	     ## Ex: 'max_size'
	     }else {
		 if (! defined($new_p->[$i])) {
		     push @{$delete{$pname}}, $i;
		     $changed{$pname} = 1;
		 }elsif ($p->[$i] ne $new_p->[$i]) {
		     unless ($new_p->[$i] =~ /^$pinfo->{$pname}{'file_format'}$/) {
			 push @syntax_error, $pname;
		     }
		     $changed{$pname} = 1; 
		 }
	     }	    
	 }
     }

     ## Syntax errors
     if ($#syntax_error > -1) {
	 &error_message('syntax_errors', {'params' => join(',',@syntax_error)});
	 foreach my $pname (@syntax_error) {
	     &wwslog('info','do_edit_list: Syntax errors, param %s=\'%s\'', $pname, $new_admin->{$pname});
	 }
	 return undef;
     }

     ## Delete selected params
     foreach my $p (keys %delete) {

	 ## Delete ALL entries
	 unless (ref ($delete{$p})) {
	     undef $new_admin->{$p};
	     next;
	 }

	 ## Delete selected entries
	 foreach my $k (reverse @{$delete{$p}}) {
	     splice @{$new_admin->{$p}}, $k, 1;
	 }
     }
     ## Update config in memory
	 my $data_source_updated;
     foreach my $pname (keys %changed) {

	 my @users;

	 ## If datasource config changed
	 if ($pname =~ /^(include_.*|user_data_source|ttl)$/) {
	     $data_source_updated = 1;
	 }

	 ## User Data Source
	 if ($pname eq 'user_data_source') {
	     ## Migrating to database
	     if (($list->{'admin'}{'user_data_source'} eq 'file') &&
		 ($new_admin->{'user_data_source'} eq 'database')) {
		 unless (-f "$list->{'dir'}/subscribers") {
		     &wwslog('notice', 'No subscribers to load in database');
		 }
		 @users = &List::_load_users_file("$list->{'dir'}/subscribers");
	     }elsif (($list->{'admin'}{'user_data_source'} eq 'database') &&
		     ($new_admin->{'user_data_source'} eq 'include2')) {
		 $list->update_user('*', {'subscribed' => 1});
		 &message('subscribers_update_soon');
	     }elsif (($list->{'admin'}{'user_data_source'} eq 'include2') &&
		     ($new_admin->{'user_data_source'} eq 'database')) {
		 $list->sync_include('purge');
	     }

	     ## Update total of subscribers
	     $list->{'total'} = &List::_load_total_db($list->{'name'});
	     $list->savestats();
	 }

	 #If no directory, delete the entry
	 if($pname eq 'export'){
	     foreach my $old_directory (@{$list->{'admin'}{'export'}}){
		 my $var = 0;
		 foreach my $new_directory (@{$new_admin->{'export'}}){
		     next unless($new_directory eq $old_directory);
		     $var = 1;
		 }

		 if(!$var || $new_admin->{'status'} ne 'open'){
		     &Ldap::delete_list($old_directory,$list);
		 }
	     }
	 }

	 $list->{'admin'}{$pname} = $new_admin->{$pname};
	 if (defined $new_admin->{$pname}) {
	     delete $list->{'admin'}{'defaults'}{$pname};
	 }else {
	     $list->{'admin'}{'defaults'}{$pname} = 1;
	 }

	 if (($pname eq 'user_data_source') &&
	     ($#users >= 0)) {

	     $list->{'total'} = 0;

	     ## Insert users in database
	     foreach my $user (@users) {
		 $list->add_user($user);
	     }

	     $list->get_total();
	     $list->{'mtime'}[1] = 0;
	 }
     }

     ## Save config file
     unless ($list->save_config($param->{'user'}{'email'})) {
	 &error_message('cannot_save_config');
	 &wwslog('info','do_edit_list: Cannot save config file');
	 return undef;
     }


     ## Reload config
     $list = new List $list->{'name'};

     ## remove existing sync_include task
     ## to start a new one
     if ($data_source_updated && ($list->{'admin'}{'user_data_source'} eq 'include2')) {
	 $list->remove_task('sync_include');
     }

     ##Exportation to an Ldap directory
     if(($list->{'admin'}{'status'} eq 'open')){
	 if($list->{'admin'}{'export'}){
	     foreach my $directory (@{$list->{'admin'}{'export'}}){
		 if($directory){
		     unless(&Ldap::export_list($directory,$list)){
			 &error_message('exportation_failed');
			 &wwslog('info','do_edit_list: The exportation failed');
		     }
		 }
	     }
	 }
     }

     ## Tag changed parameters
     foreach my $pname (keys %changed) {
	 $::changed_params{$pname} = 1;
     }

     ## Save stats
     $list->savestats();

 #    print "Content-type: text/plain\n\n";
 #    &dump_var(\%pinfo,0);
 #    &dump_var($list->{'admin'},0);
 #    &dump_var($param->{'param'},0);

     &message('list_config_updated');

     return 'edit_list_request';
 }

 ## Shift tokens to get a reference to the desired 
 ## entry in $var (recursive)
 sub _shift_var {
     my ($i, $var, @tokens) = @_;
 #    &do_log('debug2','shift_var(%s,%s,%s)',$i, $var, join('.',@tokens));
     my $newvar;

     my $token = shift @tokens;

     if ($token =~ /^\d+$/) {
	 return \$var->[$token]
	     if ($#tokens == -1);

	 if ($tokens[0] =~ /^\d+$/) {
	     unless (ref $var->[$token]) {
		 $var->[$token] = [];
	     }
	     $newvar = $var->[$token];
	 }else {
	     unless (ref $var->[$token]) {
		 $var->[$token] = {};
	     }
	     $newvar = $var->[$token];
	 }
     }else {
	 return \$var->{$token}
	     if ($#tokens == -1);

	 if ($tokens[0] =~ /^\d+$/) {
	     unless (ref $var->{$token}) {
		 $var->{$token} = [];
	     }
	     $newvar = $var->{$token};
	 }else {
	     unless (ref $var->{$token}) {
		 $var->{$token} = {};
	     }
	     $newvar = $var->{$token};
	 }

     }

     if ($#tokens > -1) {
	 $i++;
	 return &_shift_var($i, $newvar, @tokens);
     }
     return $newvar;
 }

 ## Send back the list config edition form
 sub do_edit_list_request {
     &wwslog('info', 'do_edit_list_request(%s)', $in{'group'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_edit_list_request:  no user');
	 $param->{'previous_action'} = 'edit_list_request';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($param->{'is_owner'}) {
	 &error_message('may_not');
	 &wwslog('info','do_edit_list: not allowed');
	 return undef;
     }

     if ($in{'group'}) {
	 $param->{'group'} = $in{'group'};
	 &_prepare_edit_form ($list->{'admin'});
     }

 #    print "Content-type: text/plain\n\n";
 #    &dump_var(\%pinfo,0);
 #    &dump_var($list->{'admin'},0);
 #    &dump_var($param->{'param'},0);

     $param->{'serial'} = $list->{'admin'}{'serial'};

     return 1;
 }

 ## Prepare config data to be send in the
 ## edition form
 sub _prepare_edit_form {
     my $list_config = shift;

     foreach my $pname (sort List::by_order keys %{$pinfo}) {
	 next if ($pname =~ /^comment|defaults$/);
	 next if ($in{'group'} && ($pinfo->{$pname}{'group'} ne $in{'group'}));

	 ## Skip obsolete parameters
	 next if $pinfo->{$pname}{'obsolete'};

	 my $p = &_prepare_data($pname, $pinfo->{$pname}, $list_config->{$pname});

	 $p->{'default'} = $list_config->{'defaults'}{$pname};
	 $p->{'may_edit'} = $list->may_edit($pname,$param->{'user'}{'email'});
	 $p->{'changed'} = $::changed_params{$pname};

	 ## Exceptions...too many
	 if ($pname eq 'topics') {
	     $p->{'type'} = 'enum';

	     my @topics;
	     foreach my $topic(@{$p->{'value'}}) {
		 push @topics, $topic->{'value'};
	     }
	     undef $p->{'value'};
	     my %list_of_topics = &List::load_topics($robot);
	     foreach my $selected_topic (@topics) {
		 my $menu = {};
		 foreach my $topic (keys %list_of_topics) {
		     $menu->{'value'}{$topic}{'selected'} = 0;
		     $menu->{'value'}{$topic}{'title'} = $list_of_topics{$topic}{'title'};

		     if ($list_of_topics{$topic}{'sub'}) {
			 foreach my $subtopic (keys %{$list_of_topics{$topic}{'sub'}}) {
			     $menu->{'value'}{"$topic/$subtopic"}{'selected'} = 0;
			     $menu->{'value'}{"$topic/$subtopic"}{'title'} = "$list_of_topics{$topic}{'title'}/$list_of_topics{$topic}{'sub'}{$subtopic}{'title'}";
			 }
		     }
		 }
		 $menu->{'value'}{$selected_topic}{'selected'} = 1;
		 $menu->{'value'}{$selected_topic}{'title'} = "Unknown ($selected_topic)"
		     unless (defined $menu->{'value'}{$selected_topic}{'title'});
		 push @{$p->{'value'}}, $menu;
	     }
	 }elsif ($pname eq 'digest') {
	     foreach my $v (@{$p->{'value'}}) {
		 next unless ($v->{'name'} eq 'days');

		 foreach my $day (keys %{$v->{'value'}}) {
		     $v->{'value'}{$day}{'title'} = &POSIX::strftime("%A", localtime(0 + ($day +3) * (3600 * 24)));
		 }
	     }
	 }elsif ($pname eq 'lang') {
	     my $saved_lang = &Language::GetLang();
	     foreach my $lang (keys %{$p->{'value'}}) {
		 &Language::SetLang($lang);
		 $p->{'value'}{$lang}{'title'} = Msg(14, 2, $lang);
	     }
	     &Language::SetLang($saved_lang);
	 }

	 push @{$param->{'param'}}, $p;	
     }
     return 1; 
 }

 sub _prepare_data {
     my ($name, $struct, $data) = @_;
 #    &do_log('debug2', '_prepare_data(%s, %s)', $name, $data);

     ## Prepare data structure for the parser
     my $p_glob = {'name' => $name,
		   'title' => Msg(16, $struct->{'title_id'}, $name),
		   'comment' => $struct->{'comment'}{$param->{'lang'}}
	       };

     ## Occurrences
     my $data2;
     if ($struct->{'occurrence'} =~ /n$/) {
	 $p_glob->{'occurrence'} = 'multiple';
	 if (defined($data)) {
	     $data2 = $data;

	     ## Add an empty entry
	     unless (($name eq 'days') || ($name eq 'reception')) {
		 push @{$data2}, undef;
		 ## &do_log('debug2', 'Add 1 %s', $name);
	     }
	 }else {
	     $data2 = [undef];
	 }
     }else {
	 $data2 = [$data];
     }

     my @all_p;

     ## Foreach occurrence of param
     foreach my $d (@{$data2}) {
	 my $p = {};

	 ## Type of data
	 if ($struct->{'scenario'}) {
	     $p_glob->{'type'} = 'scenario';
	     my $list_of_scenario = $list->load_scenario_list($struct->{'scenario'},$robot);

	     $list_of_scenario->{$d->{'name'}}{'selected'} = 1;

	     foreach my $key (keys %{$list_of_scenario}) {
		 $list_of_scenario->{$key}{'title'} = $list_of_scenario->{$key}{'title'}{$param->{'lang'}} || $key;
	     }

	     $p->{'value'} = $list_of_scenario;

	 }elsif ($struct->{'task'}) {
	     $p_glob->{'type'} = 'task';
	     my $list_of_task = $list->load_task_list($struct->{'task'}, $robot);

	     $list_of_task->{$d->{'name'}}{'selected'} = 1;

	     foreach my $key (keys %{$list_of_task}) {
		 $list_of_task->{$key}{'title'} = $list_of_task->{$key}{'title'}{$param->{'lang'}} || $key;
	     }

	     $p->{'value'} = $list_of_task;

	 }elsif (ref ($struct->{'format'}) eq 'HASH') {
	     $p_glob->{'type'} = 'paragraph';
	     unless (ref($d) eq 'HASH') {
		 $d = {};
	     }

	     foreach my $k (sort {$struct->{'format'}{$a}{'order'} <=> $struct->{'format'}{$b}{'order'}} 
			    keys %{$struct->{'format'}}) {
		 ## Prepare data recursively
		 my $v = &_prepare_data($k, $struct->{'format'}{$k}, $d->{$k});
		 $v->{'may_edit'} = $list->may_edit("$name.$k",$param->{'user'}{'email'});

		 push @{$p->{'value'}}, $v;
	     }

	 }elsif (ref ($struct->{'format'}) eq 'ARRAY') {
	     $p_glob->{'type'} = 'enum';

	     unless (defined $p_glob->{'value'}) {
		 ## Initialize
		 foreach my $elt (@{$struct->{'format'}}) {
		     $p_glob->{'value'}{$elt}{'selected'} = 0;
		 }
	     }
	     $p_glob->{'value'}{$d}{'selected'} = 1;

	 }else {
	     $p_glob->{'type'} = 'scalar';
	     $p->{'value'} = &tools::escape_html($d);
	     $p->{'length'} = $struct->{'length'};
	     $p->{'unit'} = $struct->{'unit'};
	 }

	 push @all_p, $p;
     }

     if (($p_glob->{'occurrence'} eq 'multiple')
	 && ($p_glob->{'type'} ne 'enum')) {
	 $p_glob->{'value'} = \@all_p;
     }else {
	 foreach my $k (keys %{$all_p[0]}) {
	     $p_glob->{$k} = $all_p[0]->{$k};
	 }
     }

     return $p_glob;
 }

 ## Dump a variable's content
 sub dump_var {
     my ($var, $level, $fd) = @_;

     if (ref($var)) {
	 if (ref($var) eq 'ARRAY') {
	     foreach my $index (0..$#{$var}) {
		 print $fd "\t"x$level.$index."\n";
		 &dump_var($var->[$index], $level+1, $fd);
	     }
	 }elsif (ref($var) eq 'HASH') {
	     foreach my $key (sort keys %{$var}) {
		 print $fd "\t"x$level.'_'.$key.'_'."\n";
		 &dump_var($var->{$key}, $level+1, $fd);
	     }    
	 }
     }else {
	 if (defined $var) {
	     print $fd "\t"x$level."'$var'"."\n";
	 }else {
	     print $fd "\t"x$level."UNDEF\n";
	 }
     }
 }

 ## NOT USED anymore (expect chinese)
 sub do_close_list_request {
     &wwslog('info', 'do_close_list_request()');

     unless($param->{'is_owner'} || $param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_close_list_request: not listmaster or list owner');
	 return undef;
     }

     if ($list->{'admin'}{'status'} eq 'closed') {
	 &error_message('already_closed');
	 &wwslog('info','do_close_list_request: already closed');
	 return undef;
     }      

     return 1;
 }


 # in order to rename a list you must be list owner and you must be allowed to create new list
 sub do_rename_list_request {
     &wwslog('info', 'do_rename_list_request()');

     unless (($param->{'is_privileged_owner'}) || ($param->{'is_listmaster'})) {
	 &error_message('may_not');
	 &wwslog('info','do_rename_list_request: not owner');
	 return undef;
     }  


     unless ($param->{'user'}{'email'} &&  (&List::request_action ('create_list',$param->{'auth_method'},$robot,
							    {'sender' => $param->{'user'}{'email'},
							     'remote_host' => $param->{'remote_host'},
							     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it|listmaster/)) {
	 &error_message('may_not');
	 &wwslog('info','do_rename_list_request: not owner');
	 return undef;
     }

     return '1';
 }

 # in order to rename a list you must be list owner and you must be allowed to create new list
 sub do_rename_list {
     &wwslog('info', 'do_rename_list()');

     unless (($param->{'is_privileged_owner'}) || ($param->{'is_listmaster'})) {
	 &error_message('may_not');
	 &wwslog('info','do_rename_list: not owner');
	 return undef;
     }  

     unless ($param->{'list'}) {
	 &error_message('list_required');
	 &wwslog('info','do_rename_list: parameter list missing');
	 return undef;
     }  

     unless ($param->{'user'}{'email'} &&  (&List::request_action ('create_list',$param->{'auth_method'},$robot,
							    {'sender' => $param->{'user'}{'email'},
							     'remote_host' => $param->{'remote_host'},
							     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it|listmaster/)) {
	 &error_message('may_not');
	 &wwslog('info','do_rename_list: not owner');
	 return undef;
     }

     # check new listname syntax
     $in{'new_listname'} = lc ($in{'new_listname'});
     unless ($in{'new_listname'} =~ /^[a-z0-9][a-z0-9\-\+\._]*$/i) {
	 &error_message('incorrect_listname', {'listname' => $in{'new_listname'}});
	 &wwslog('info','do_rename_list: incorrect listname %s', $in{'new_listname'});
	 return 'rename_list_request';
     }

     ## Check listname on SMTP server
     my $res = list_check_smtp($in{'new_listname'});
     unless ( defined($res) ) {
	 &error_message('unable_to_check_list_using_smtp');
	 &do_log('err', "can't check list %.128s on %.128s",
		 $in{'new_listname'},
		 $wwsconf->{'list_check_smtp'});
	 return undef;
     }
     if( $res || new List ($in{'new_listname'})) {
	 &error_message('list_already_exists');
	 &do_log('info', 'could not rename list %s for %s: new list %s already existing list', 
		 $in{'listname'},$param->{'user'}{'email'},$in{'new_listname'});

	 return undef;
     }

     my $regx = Conf::get_robot_conf($robot,'list_check_regexp');
     if( $regx ) {
	 if ($in{'new_listname'} =~ /^(\S+)-($regx)$/) {
	     &error_message("Incorrect listname \"$in{'new_listname'}\" matches one of service aliases",{'listname' => $in{'new_listname'}});
	     &wwslog('info','do_create_list: incorrect listname %s matches one of service aliases', $in{'new_listname'});
	     return 'rename_list_request';
	 }
     }

     $list->savestats();

     ## Dump subscribers
     $list->_save_users_file("$list->{'dir'}/subscribers.closed.dump");

     &_remove_aliases();

     ## Rename this list it self
     unless (rename ("$list->{'dir'}", "$list->{'dir'}/../$in{'new_listname'}" )){
	 &wwslog('info',"do_rename_list : unable to rename $list->{'dir'} to $list->{'dir'}/../$in{'new_listname'}");
	 &error_message('failed');
	 return undef;
     }
     ## Rename archive
     if (-d "$wwsconf->{'arc_path'}/$in{'listname'}/\@$robot") {
	 unless (rename ("$wwsconf->{'arc_path'}/$in{'listname'}/\@$robot","$wwsconf->{'arc_path'}/$in{'new_listname'}/\@$robot")) {
	     &wwslog('info',"do_rename_list : unable to rename archive $wwsconf->{'arc_path'}/$in{'listname'}/\@$robot $wwsconf->{'arc_path'}/$in{'new_listname'}/\@$robot");
	     &error_message('renamming_archive_failed');
	     # continue even if there is some troubles with archives
	     # return undef;
	 }
     }
     ## Rename bounces
     if (-d "$wwsconf->{'bounce_path'}/$param->{'list'}") {
	 unless (rename ("wwsconf->{'bounce_path'}/$param->{'list'}","wwsconf->{'bounce_path'}/$in{'new_listname'}")) {
	      &error_message('unable_to_rename_bounces');
	      &wwslog('info',"do_rename_list unable to rename bounces from wwsconf->{'bounce_path'}/$param->{'list'} to sconf->{'bounce_path'}/$in{'new_listname'}");
	 }
     }


     # if subscribtion are stored in database rewrite the database
     if ($list->{'admin'}{'user_data_source'} =~ /^database|include2$/) {
	 &List::update_subscribers_db ($in{'list'},$in{'new_listname'});
	 &wwslog('debug',"do_rename_list :List::update_subscribers_db ($in{'list'},$in{'new_listname'} ");
     }

     ## Install new aliases
     $in{'listname'} = $in{'new_listname'};
     $param->{'list'} = $in{'new_listname'};
     unless ($list = new List ($in{'new_listname'})) {
	 &wwslog('info',"do_rename_list : unable to load $in{'new_listname'} while renamming");
	 &error_message('failed');
	 return undef;
     }
     &_install_aliases() if ($list->{'admin'}{'status'} eq 'open');

     $param->{'redirect_to'} = "$param->{'base_url'}$param->{'path_cgi'}/admin/$in{'new_listname'}";
     return 1;

 }


 sub do_purge_list {
     &wwslog('info', 'do_purge_list()');

     unless (($param->{'is_listmaster'}) || ($param->{'is_privileged_owner'})) {
	 &error_message('may_not');
	 &wwslog('info','do_purge_list: not privileged_owner');
	 return undef;
     }  

     unless ($in{'selected_lists'}) {
	 &error_message('missing_arg', {'argument' => 'selected_lists'});
	 &wwslog('info','do_purge_list: no list');
	 return undef;
     }

     my @lists = split /\0/, $in{'selected_lists'};

     foreach my $l (@lists) {
	 my $list = new List ($l);

	 `/bin/rm -rf $list->{'dir'}`;
     }    

     &message('performed');

     return 'serveradmin';
 }

 sub do_close_list {
     &wwslog('info', 'do_close_list()');

     unless ($param->{'is_privileged_owner'}) {
	 &error_message('may_not');
	 &wwslog('info','do_close_list: not privileged owner');
	 return undef;
     }  

     if ($list->{'admin'}{'status'} eq 'closed') {
	 &error_message('already_closed');
	 &wwslog('info','do_close_list: already closed');
	 return undef;
     }      

     ## Dump subscribers
     $list->_save_users_file("$list->{'dir'}/subscribers.closed.dump");

     ## Delete users
     my @users;
     for ( my $user = $list->get_first_user(); $user; $user = $list->get_next_user() ){
	 push @users, $user->{'email'};
     }
     $list->delete_user(@users);

     ## Change status & save config
     $list->{'admin'}{'status'} = 'closed';
     $list->{'admin'}{'defaults'}{'status'} = 0;

     $list->save_config($param->{'user'}{'email'});
     $list->savestats();

     &_remove_aliases();

     &message('list_closed');

     return 'admin';
 }

 sub do_restore_list {
     &wwslog('info', 'do_restore_list()');

     unless ($param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_restore_list: not listmaster');
	 return undef;
     }

     unless ($list->{'admin'}{'status'} eq 'closed') {
	 &error_message('list_not_closed');
	 &wwslog('info','do_restore_list: list not closed');
	 return undef;
     }      

     ## Change status & save config
     $list->{'admin'}{'status'} = 'open';
     $list->{'admin'}{'defaults'}{'status'} = 0;
     $list->save_config($param->{'user'}{'email'});

     if ($list->{'admin'}{'user_data_source'} eq 'file') {
	 $list->{'users'} = &List::_load_users_file("$list->{'dir'}/subscribers.closed.dump");
	 $list->save();
     }elsif ($list->{'admin'}{'user_data_source'} eq 'database') {
	 unless (-f "$list->{'dir'}/subscribers.closed.dump") {
	     &wwslog('notice', 'No subscribers to restore');
	 }
	 my @users = &List::_load_users_file("$list->{'dir'}/subscribers.closed.dump");

	 ## Insert users in database
	 foreach my $user (@users) {
	     $list->add_user($user);
	 }
     }

     $list->savestats(); 

     &_install_aliases();

     &message('list_restored');

     return 'admin';
 }


 sub get_desc_file {
     my $file = shift;
     my $ligne;
     my %hash;

     open DESC_FILE,"$file";

     while ($ligne = <DESC_FILE>) {
	 if ($ligne =~ /^title\s*$/) {
	     #case title of the document
	     while (($ligne = <DESC_FILE>) and ($ligne!~/^\s*$/)) {
		 $ligne =~ /^\s*(\S.*\S)\s*/;
		 $hash{'title'} = $hash{'title'}.$1." ";
	     }
	 }



	 if ($ligne =~ /^creation\s*$/) {
	     #case creation of the document
	     while (($ligne = <DESC_FILE>) and ($ligne!~/^\s*$/)) {
		 if ($ligne =~ /^\s*email\s*(\S*)\s*/) {
		     $hash{'email'} = $1;
		 } 
		 if ($ligne =~ /^\s*date_epoch\s*(\d*)\s*/) {
		     $hash{'date'} = $1;
		 }

	     }
	 }   

	 if ($ligne =~ /^access\s*$/) {
	     #case access scenari for the document
	     while (($ligne = <DESC_FILE>) and ($ligne!~/^\s*$/)) {
		 if ($ligne =~ /^\s*read\s*(\S*)\s*/) {
		     $hash{'read'} = $1;
		 }
		 if ($ligne =~ /^\s*edit\s*(\S*)\s*/) {
		     $hash{'edit'} = $1;
		 }

	     }
	 }

     }


     close DESC_FILE;

     return %hash;

 }


 sub show_cert {
     return 1;
 }

 ## Function synchronize
 ## Return true if the file in parameter can be overwrited
 ## false if it has changes since the parameter date_epoch
 sub synchronize {
     # args : 'path' , 'date_epoch'
     my $path = shift;
     my $date_epoch = shift;

     my @info = stat $path;

     return ($date_epoch == $info[10]);
 }


 #*******************************************
 # Function : d_access_control
 # Description : return a hash with privileges
 #               in read, edit, control
 #               if first parameter require
 #               it 
 #******************************************

 ## Regulars
 #  read(/) = default (config list)
 #  edit(/) = default (config list)
 #  control(/) = not defined
 #  read(A/B)= (read(A) && read(B)) ||
 #             (author(A) || author(B))
 #  edit = idem read
 #  control (A/B) : author(A) || author(B)
 #  + (set owner A/B) if (empty directory &&   
 #                        control A)


 sub d_access_control {
     # Arguments:
     # (\%mode,$path)
     # if mode->{'read'} control access only for read
     # if mode->{'edit'} control access only for edit
     # if mode->{'control'} control access only for control

     # return the hash
     # $result{'may'}{'read'} = 0 or 1 (right or not)
     # $result{'may'}{'edit'} = 0 or 1 (right or not)
     # $result{'may'}{'control'} = 0 or 1 (right or not)
     # $result{'scenario'}{'read'} = scenario name for the document
     # $result{'scenario'}{'edit'} = scenario name for the document

     &wwslog('info', "d_access_control");

     # Result
      my %result;

     # Control 

     # Arguments
     my $mode = shift;
     my $path = shift;

     my $mode_read = $mode->{'read'};
     my $mode_edit = $mode->{'edit'};
     my $mode_control = $mode->{'control'};

     # Useful parameters
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';


     # document to read
     my $doc;
     if ($path) {
	 # the path must have no slash a its end
	 $path =~ /^(.*[^\/])?(\/*)$/;
	 $path = $1;
	 $doc = $shareddir.'/'.$path;
     } else {
	 $doc = $shareddir;
     }

     # Control for editing
     my $may_read = 1;
     my $may_edit = 1;
     my $is_author = 0; # <=> $may_control



     if (!$path) {    
	 # Default control : if $path="", the rights are those of the shared space
	 #                   in the config of the list

	 $result{'scenario'}{'read'} = $list->{'admin'}{'shared_doc'}{'d_read'}{'name'};
	 $result{'scenario'}{'edit'} = $list->{'admin'}{'shared_doc'}{'d_edit'}{'name'};

	 # Test of privileged owner

	 if ($param->{'is_privileged_owner'}) {
	     $result{'may'}{'read'} = 1;
	     $result{'may'}{'edit'} = 1;
	     $result{'may'}{'control'} = 1; 
	     return %result;
	 }

	 # if not privileged owner
	 if ($mode_read) {
	     $result{'may'}{'read'} = (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},$robot,
							    {'listname' => $param->{'list'},
							     'sender' => $param->{'user'}{'email'},
							     'remote_host' => $param->{'remote_host'},
							     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i);
	 }
	 if ($mode_edit) {
	     $result{'may'}{'edit'} = (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},$robot,
							       {'listname' => $param->{'list'},
								'sender' => $param->{'user'}{'email'},
								'remote_host' => $param->{'remote_host'},
								'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i);
	 }

	 ## Only authenticated users can edit files
	 $result{'may'}{'edit'} = 0 unless ($param->{'user'}{'email'});

	 if ($mode_control) {
	     $result{'may'}{'control'} = 0;
	 }

	 # result
	 return %result;

     } else {
	 # path remaining to test
	 my $current_path = $path;

	 # current document to test
	 my $current_document;

	 # description file loaded in a hash
	 my %desc_hash;

	 # test of privileged owner once
	 my $test_privilege = 1;

	 # user : to compare string. In order not to test ('' eq '')!
	 my $user = $param->{'user'}{'email'} || 'nobody';

	 while ($current_path ne "") {
	     # no description file found yet
	     my $def_desc_file = 0;
	     my $desc_file;

	     $current_path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	     $current_document = $3;

	     # opening of the description file appropriated
	     if (-d $shareddir.'/'.$current_path) {
		 # case directory

 #		unless ($slash) {
		 $current_path = $current_path.'/';
 #		}

		 if (-e "$shareddir/$current_path.desc"){
		     $desc_file = $shareddir.'/'.$current_path.".desc";
		     $def_desc_file = 1;
		 }

	     }else {
		 # case file
		 if (-e "$shareddir/$1.desc.$3"){
		     $desc_file = $shareddir.'/'.$1.".desc.".$3;
		     $def_desc_file = 1;
		 } 

	     }

	     if ($def_desc_file) {
		 # a description file was found
		 # loading of acces information

		 %desc_hash = &get_desc_file($desc_file);

		 # Test of privileged owner
		 if ($test_privilege) {
		     if ($param->{'is_privileged_owner'}) {
			 $result{'may'}{'read'} = 1;
			 $result{'may'}{'edit'} = 1;
			 $result{'may'}{'control'} = 1;
			 $result{'scenario'}{'read'} = $desc_hash{'read'};
			 $result{'scenario'}{'edit'} = $desc_hash{'edit'};

			 return %result;
		     }
		 }
		 $test_privilege = 0; # test privileges only once


		 if ($mode_read) {
		     $may_read = $may_read && (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},$robot,
								      {'listname' => $param->{'list'},
								       'sender' => $param->{'user'}{'email'},
								       'remote_host' => $param->{'remote_host'},
								       'remote_addr' => $param->{'remote_addr'},
								       'scenario'=> $desc_hash{'read'}}) =~ /do_it/i);
		 }


		 if ($mode_edit) {
		     $may_edit = $may_edit && (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},$robot,
								      {'listname' => $param->{'list'},
								       'sender' => $param->{'user'}{'email'},
								       'remote_host' => $param->{'remote_host'},
								       'remote_addr' => $param->{'remote_addr'},
								       'scenario'=> $desc_hash{'edit'}}) =~ /do_it/i);

		 }

		 ## Only authenticated users can edit files
		 $may_edit = 0 unless ($param->{'user'}{'email'});

		 $is_author = $is_author || ($user eq $desc_hash{'email'});

		 unless (defined $result{'scenario'}{'read'}) {
		     $result{'scenario'}{'read'} = $desc_hash{'read'};
		     $result{'scenario'}{'edit'} = $desc_hash{'edit'};
		 }

		 if ($is_author) {
		     $result{'may'}{'read'} = 1;
		     $result{'may'}{'edit'} = 1;
		     $result{'may'}{'control'} = 1;
		     return %result;
		 }

	     }

	     # truncate the path for the while   
	     $current_path = $1; 
	 }

	 # default access 
	 unless (defined $result{'scenario'}{'read'}) {
	     $result{'scenario'}{'read'} =  $list->{'admin'}{'shared_doc'}{'d_read'}{'name'};
	     $result{'scenario'}{'edit'} =  $list->{'admin'}{'shared_doc'}{'d_edit'}{'name'};
	 }

	 # Test of privileged owner if not already done in the while => no desc file found
	 if ($test_privilege) {
	     if ($param->{'is_privileged_owner'}) {
		 $result{'may'}{'read'} = 1;
		 $result{'may'}{'edit'} = 1;
		 $result{'may'}{'control'} = 1;
		 return %result;
	     } else {
		 # case no description file and no privileges
		 $result{'may'}{'read'} = (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},$robot,
								  {'listname' => $param->{'list'},
								   'sender' => $param->{'user'}{'email'},
								   'remote_host' => $param->{'remote_host'},
								   'remote_addr' => $param->{'remote_addr'},
								   'scenario'=>$result{'scenario'}{'read'}}) =~ /do_it/i);
		 $result{'may'}{'edit'} =  (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},$robot,
								   {'listname' => $param->{'list'},
								    'sender' => $param->{'user'}{'email'},
								    'remote_host' => $param->{'remote_host'},
								    'remote_addr' => $param->{'remote_addr'},
								    'scenario'=>$result{'scenario'}{'edit'}}) =~ /do_it/i);
		 ## Only authenticated users can edit files
		 $result{'may'}{'edit'} = 0 unless ($param->{'user'}{'email'});

		 $result{'may'}{'control'} = 0;
		 return %result;
	     }
	 }

	 if ($mode_read) {
	     $result{'may'}{'read'} = $may_read;
	 }

	 if ($mode_edit) {
	      $result{'may'}{'edit'} = $may_edit;
	 }

	 if ($mode_control) {
	     $result{'may'}{'control'} = 0;
	 }


	 return %result;
     }


 }


 # create the root shared document
 sub do_d_admin {
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$in{'path'});

     unless ($access{'may'}{'edit'}) {
	 &wwslog('info',"do_d_admin : permission denied for $param->{'user'}{'email'} ");
	 &error_message('failed');
	 return undef;
     }

     my $dir = $list->{'dir'};

     if ($in{'d_admin'} eq 'create') {

	 if (-e "$dir/shared") {
	     &wwslog('info',"do_d_admin :  create; $dir/shared allready exist");
	     &error_message('failed');
	     return undef;
	 }
	 unless (mkdir ("$dir/shared",0777)) {
	     &wwslog('info',"do_d_admin : create; unable to create $dir/shared : $! ");
	     &error_message('failed');
	     return undef;
	 }

	 return 'd_read';
     }elsif($in{'d_admin'} eq 'restore') {
	 unless (-e "$dir/pending.shared") {
	     &wwslog('info',"do_d_admin : restore; $dir/pending.shared not found");
	     &error_message('failed');
	     return undef;
	 }
	 if (-e "$dir/shared") {
	     &wwslog('info',"do_d_admin : restore; $dir/shared allready exist");
	     &error_message('failed');
	     return undef;
	 }
	 unless (rename ("$dir/pending.shared", "$dir/shared")){
	     &wwslog('info',"do_d_admin : restore; unable to rename $dir/pending.shared");
	     &error_message('failed');
	     return undef;
	 }

	 return 'd_read';
     }elsif($in{'d_admin'} eq 'delete') {
	 unless (-e "$dir/shared") {
	     &wwslog('info',"do_d_admin : restore; $dir/shared not found");
	     &error_message('failed');
	     return undef;
	 }
	 if (-e "$dir/pending.shared") {
	     &wwslog('info',"do_d_admin : delete ; $dir/pending.shared allready exist");
	     &error_message('failed');
	     return undef;
	 }
	 unless (rename ("$dir/shared", "$dir/pending.shared")){
	     &wwslog('info',"do_d_admin : restore; unable to rename $dir/shared");
	     &error_message('failed');
	     return undef;
	     }
     }

     return 'admin';
 }

 #*******************************************
 # Function : do_d_read# Description : reads a file or a directory
 #******************************************

 # Function which sorts a hash of documents
 # Sort by various parameters
 sub by_order {
     my $order = shift;
     my $hash = shift;
     # $order = 'order_by_size'/'order_by_doc'/'order_by_author'/'order_by_date'

     if ($order eq 'order_by_doc')  {
	 $hash->{$a}{'doc'} cmp $hash->{$b}{'doc'}
	 or $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'};
     } 
     elsif ($order eq 'order_by_author') {
	 $hash->{$a}{'author'} cmp $hash->{$b}{'author'}
	 or $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'};
     } 
     elsif ($order eq 'order_by_size') {
	 $hash->{$a}{'size'} <=> $hash->{$b}{'size'} 
	 or $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'};
     }
     elsif ($order eq 'order_by_date') {
	 $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'} or $a cmp $b;
     }

     else {
	 $a cmp $b;
     }
 }

 ##
 ## Function do_d_read
 sub do_d_read {
     &wwslog('info', 'do_d_read(%s)', $in{'path'});

     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_read: no list');
	 return undef;
     }

     ### Useful variables

     # current list / current shared directory
     my $list_name = $list->{'name'};
     my $list_host = $list->{'name'}.'@'.$list->{'admin'}{'host'}; 

     # relative path / directory shared of the document 
     my $path = $in{'path'};
     my $path_orig = $path;

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     # document to read
     my $doc;
     if ($path) {
	 # the path must have no slash a its end
	 $path =~ /^(.*[^\/])?(\/*)$/;
	 $path = $1;
	 $doc = $shareddir.'/'.$path;
     } else {
	 $doc = $shareddir;
     }

     ### Document exist ? 
     unless (-r "$doc") {
	 &wwslog('info',"do_d_read : unable to read $shareddir/$path : no such file or directory");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     ### Document has non-size zero?
     unless (-s "$doc") {
	 &wwslog('info',"do_d_read : unable to read $shareddir/$path : empty document");
	 &error_message('empty_document', {'path' => $path});
	 return undef;
     }

     ### Document isn't a description file
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_read : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     ### Access control    
     my %mode;
     $mode{'read'} = 1;
     $mode{'edit'} = 1;
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);
     my $may_read = $access{'may'}{'read'};
     unless ($may_read) {
	 &error_message('may_not');
	 &wwslog('info','d_read : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $may_edit = $access{'may'}{'edit'};
     my $may_control = $access{'may'}{'control'};


     ### File or directory ?

     if (!(-d $doc)) {
	 ## Jump to the URL
	 if ($doc =~ /\.url$/) {
	     open DOC, $doc;
	     my $url = <DOC>;
	     close DOC;
	     chomp $url;
	     $param->{'redirect_to'} = $url;
	     return 1;
	 }else {
	     # parameters for the template file
	     # view a file 
	     $param->{'file'} = $doc;

	     ## File type
	     $path =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/; 

	     $param->{'file_extension'} = $3;
	     $param->{'bypass'} = 1;
	 }
     }else {
	 # verification of the URL (the path must have a slash at its end)
 #	if ($ENV{'PATH_INFO'} !~ /\/$/) { 
 #	    $param->{'redirect_to'} = "$param->{'base_url'}$param->{'path_cgi'}/d_read/$list_name/";
 #	    return 1;
 #	}

	 ## parameters of the current directory
	 if ($path && (-e "$doc/.desc")) {
	     my %desc_hash = &get_desc_file("$doc/.desc");
	     $param->{'doc_owner'} = $desc_hash{'email'};
	     $param->{'doc_title'} = $desc_hash{'title'};
	 }
	 my @info = stat $doc;
	 $param->{'doc_date'} =  &POSIX::strftime("%d %b %Y", localtime($info[9]));


	 # listing of all the shared documents of the directory
	 unless (opendir DIR, "$doc") {
	     &error_message('failed');
	     &wwslog('info',"d_read : cannot open $doc : $!");
	     return undef;
	 }

	 my @dir = grep !/^\./, readdir DIR;
	 closedir DIR;

	 # empty directory?
	 $param->{'empty'} = ($#dir == -1);

	 # building of two hash : for the subdirectories
	 # and for the files
	 my %subdirs, my %files;

	 ## for the exception of index.html
	 # name of the file "index.html" if exists in the directory read
	 my $indexhtml;
	 # boolean : one of the subdirectories or files inside
	 # can be edited -> normal mode of read -> d_read.tpl;
	 my $normal_mode;


	 my $path_doc;
	 my %desc_hash;
	 my $may, my $def_desc;
	 my $user = $param->{'user'}{'email'} || 'nobody';

	 foreach my $d (@dir) {

	     # current document
	     my $path_doc = "$doc/$d";

	     #case subdirectory
	     if (-d $path_doc) {

		 # last update
		 my @info = stat $path_doc;
		 $subdirs{$d}{'date_epoch'} = $info[9];
		 $subdirs{$d}{'date'} = &POSIX::strftime("%d %b %Y", localtime($info[9]));

		 # Case read authorized : fill the hash 
		 $subdirs{$d}{'icon'} = $icon_table{'folder'};

		 # name of the doc
		 $subdirs{$d}{'doc'} = $d;

		 $subdirs{$d}{'escaped_doc'} =  &tools::escape_chars($d);

		 # size of the doc
		 $subdirs{$d}{'size'} = (-s $path_doc)/1000;

		 if (-e "$path_doc/.desc") {
		     # check access permission for reading
		     %desc_hash = &get_desc_file("$path_doc/.desc");

		     if  (($user eq $desc_hash{'email'}) || ($may_control) ||
			  (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},$robot,
						  {'listname' => $param->{'list'},
						   'sender' => $param->{'user'}{'email'},
						   'remote_host' => $param->{'remote_host'},
						   'remote_addr' => $param->{'remote_addr'},
						   'scenario' => $desc_hash{'read'}}) =~ /do_it/i)) {

			 # description
			 $subdirs{$d}{'title'} = $desc_hash{'title'};
			 $subdirs{$d}{'escaped_title'}=&tools::escape_html($desc_hash{'title'});

			 # Author
			 if ($desc_hash{'email'}) {
			     $subdirs{$d}{'author'} = $desc_hash{'email'};
			     $subdirs{$d}{'author_mailto'} = &mailto($list,$desc_hash{'email'});
			     $subdirs{$d}{'author_known'} = 1;
			 }

			 # if the file can be read, check for edit access & edit description files access
			 ## only authentified users can edit a file
			 if ($param->{'user'}{'email'} &&
			     ($may_control || ($user eq $desc_hash{'email'}) ||
			     ($may_edit && (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},$robot,
								   {'listname' => $param->{'list'},
								    'sender' => $param->{'user'}{'email'},
								    'remote_host' => $param->{'remote_host'},
								    'remote_addr' => $param->{'remote_addr'},
								    'scenario' => $desc_hash{'edit'}}) =~ /do_it/i)))) {
			     $subdirs{$d}{'edit'} = 1;
			     # if index.html, must know if something can be edit in the dir
			     $normal_mode = 1;
			 }
			 if  ($may_control || ($user eq $desc_hash{'email'})) {
			     $subdirs{$d}{'control'} = 1;
			 }

		     }
		 } else {
		     # no description file = no need to check access for read

		     # access for edit and control
		     if ($may_edit || $may_control) {
			 $subdirs{$d}{'edit'} = 1;
			 $normal_mode = 1;
		     }
		     if ($may_control) {$subdirs{$d}{'control'} = 1;}
		 }

	     }else {
		 # case file
		 $may = 1;
		 $def_desc = 0;

		 if (-e "$doc/.desc.$d") {
		     # a desc file was found
		     $def_desc = 1;

		     # check access permission		
		     %desc_hash = &get_desc_file("$doc/.desc.$d");

		     unless (($user eq $desc_hash{'email'}) || ($may_control) ||
			     (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},$robot,
						     {'listname' => $param->{'list'},
						      'sender' => $param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'},
						      'scenario' => $desc_hash{'read'}}) =~ /do_it/i)) {
			 $may = 0;
		     } 
		 } 

		 # if permission or no description file
		 if ($may) {
		     $path_doc =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/; 

		     ## Bookmark
		     if ($path_doc =~ /\.url$/) {
			 open DOC, $path_doc;
			 my $url = <DOC>;
			 close DOC;
			 chomp $url;
			 $files{$d}{'url'} = $url;
			 $files{$d}{'anchor'} = $d;
			 $files{$d}{'anchor'} =~ s/\.url$//;
			 $files{$d}{'icon'} = $icon_table{'url'};			

		     ## MIME - TYPES : icons for template
		     }elsif (my $type = $mime_types->{$3}) {
			 # type of the file and apache icon
			 $type =~ /^([\w\-]+)\/([\w\-]+)$/;
			 my $mimet = $1;
			 my $subt = $2;
			 if ($subt) {
			     if ($subt =~  /^octet-stream$/) {
				 $mimet = 'octet-stream';
				 $subt = 'binary';
			     }
			     $files{$d}{'type'} = "$subt file";
			 }
			 $files{$d}{'icon'} = $icon_table{$mimet} || $icon_table{'unknown'};
		     } else {
			 # unknown file type
			 $files{$d}{'icon'} = $icon_table{'unknown'};
		     }

		     ## case html
		     if ($3 =~ /^html?$/i) { 
			 $files{$d}{'html'} = 1;
			 $files{$d}{'type'} = 'html file';
			 $files{$d}{'icon'} = $icon_table{'text'};
		     }
		     ## exception of index.html
		     if ($d =~ /^(index\.html?)$/i) {
			 $indexhtml = $1;
		     }

		     ## Access control for edit and control
		     if ($def_desc) {
			 # check access for edit and control the file
			 ## Only authenticated users can edit files
			 if ($param->{'user'}{'email'} &&
			     (($user eq $desc_hash{'email'}) || $may_control ||
			     ($may_edit && (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},$robot,
								   {'listname' => $param->{'list'},
								    'sender' => $param->{'user'}{'email'},
								    'remote_host' => $param->{'remote_host'},
								    'remote_addr' => $param->{'remote_addr'},
								    'scenario' => $desc_hash{'edit'}}) =~ /do_it/i)))) {

			     $normal_mode = 1;
			     $files{$d}{'edit'} = 1;    
			 }

			 if (($user eq $desc_hash{'email'}) || $may_control) { 
			     $files{$d}{'control'} = 1;    
			 }

			 # fill the file hash
			   # description of the file
			 $files{$d}{'title'} = $desc_hash{'title'};
			 $files{$d}{'escaped_title'}=&tools::escape_html($desc_hash{'title'});
			   # author
			 if ($desc_hash{'email'}) {
			     $files{$d}{'author'} = $desc_hash{'email'};
			     $files{$d}{'author_known'} = 1;
			 }
		     } else {
			 if ($may_edit) {
			     $files{$d}{'edit'} = 1;
			     $normal_mode = 1;
			 }    
			 if ($may_control) {$files{$d}{'control'} = 1;} 
		     }

		       # name of the file
		     $files{$d}{'doc'} = $d;
		     $files{$d}{'escaped_doc'} =  &tools::escape_chars($d);

		       # last update
		     my @info = stat $path_doc;
		     $files{$d}{'date_epoch'} = $info[9];
		     $files{$d}{'date'} = POSIX::strftime("%d %b %Y", localtime($info[9]));
		       # size
		     $files{$d}{'size'} = (-s $path_doc)/1000; 
		 }
	     }
	 }

	 closedir DIR;


	 ### Exception : index.html
	 if ($indexhtml) {
	     unless ($normal_mode) {
		 $param->{'file_extension'} = 'html';
		 $param->{'bypass'} = 1;
		 $param->{'file'} = "$doc/$indexhtml";
		 return 1;
	     }
	 }

	 ## to sort subdirs
	 my @sort_subdirs;
	 my $order = $in{'order'} || 'order_by_doc';
	 $param->{'order_by'} = $order;
	 foreach my $k (sort {by_order($order,\%subdirs)} keys %subdirs) {
	     push @sort_subdirs, $subdirs{$k};
	 }

	 ## to sort files
	 my @sort_files;
	 foreach my $k (sort {by_order($order,\%files)} keys %files) {
	     push @sort_files, $files{$k};
	 }

	 # parameters for the template file
	 $param->{'list'} = $list_name;

	 $param->{'may_edit'} = $may_edit;	
	 $param->{'may_control'} = $may_control;

	 if ($path) {
	     # building of the parent directory path
	     if ($path =~ /^(([^\/]*\/)*)([^\/]+)$/) {
		 $param->{'father'} = $1;
	     }else {
		 $param->{'father'} = '';
	     }
	     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');


	     # Parameters for the description
	     if (-e "$doc/.desc") {
		 my @info = stat "$doc/.desc";
		 $param->{'serial_desc'} = $info[10];
		 my %desc_hash = &get_desc_file("$doc/.desc");
		 $param->{'description'} = $desc_hash{'title'};
	     }

	     $param->{'path'} = $path.'/';
	     $param->{'escaped_path'} = &tools::escape_chars($param->{'path'}, '/');
	 }
	 if (scalar keys %subdirs) {
	     $param->{'sort_subdirs'} = \@sort_subdirs;
	 }
	 if (scalar keys %files) {
	     $param->{'sort_files'} = \@sort_files;
	 }

     }

     $param->{'father_icon'} = $icon_table{'father'};
     $param->{'sort_icon'} = $icon_table{'sort'};
     return 1;

 }


 ## Useful function to have the path with or without slash
 ## at its end
 sub format_path {
     my $mode = shift; #'with_slash' / 'without_slash'
     my $path = shift;

     ## supress ending '/'
     $path =~ s/\/+$//;

     if ($mode eq 'with_slash') {
	 return $path . '/';
     }

     return $path;
 } 

 #*******************************************
 # Function : do_d_editfile
 # Description : prepares the parameters to
 #               edit a file
 #*******************************************

 sub do_d_editfile {
     &wwslog('info', 'do_d_editfile(%s)', $in{'path'});

     # Variables
     my $path = $in{'path'};

     # $path must have no slash at its end
     $path = &format_path('without_slash',$path);

     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     $param->{'directory'} = -d "$shareddir/$path";

     # Control

     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_editfile: no list');
	 return undef;
     }

     unless ($path) {
	 &error_message('missing_arg', {'argument' => 'file name'});
	 &wwslog('info','do_d_editfile: no file name');
	 return undef;
     }   

     # Existing document? File?
     unless (-w "$shareddir/$path") {
	 &error_message('no_such_file', {'path' => $path});
	 &wwslog('info',"d_editfile : Cannot edit $shareddir/$path : not an existing file");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_editdile : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     if ($path =~ /\.url$/) {
	 ## Get URL of bookmark
	 open URL, "$shareddir/$path";
	 my $url = <URL>;
	 close URL;
	 chomp $url;

	 $param->{'url'} = $url;
     }

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);
     my $may_edit = $access{'may'}{'edit'};

     unless ($may_edit) {
	 &error_message('may_not');
	 &wwslog('info','d_editfile : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## End of controls

     $param->{'list'} = $list_name;
     $param->{'path'} = $path;

     # test if it's a text file
     if (-T "$shareddir/$path") {
	 $param->{'textfile'} = 1;
	 $param->{'filepath'} = "$shareddir/$path";
     } else {
	 $param->{'textfile'} = 0;
     }

     #Current directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = $1;
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     # Description of the file
     my $descfile;
     if (-d "$shareddir/$path") {
	 $descfile = "$shareddir/$1$3/.desc";
     }else {
	 $descfile = "$shareddir/$1.desc.$3";
     }

     if (-e $descfile) {
	 my %desc_hash = &get_desc_file($descfile);
	 $param->{'desc'} = $desc_hash{'title'};
	 $param->{'doc_owner'} = $desc_hash{'email'};   
	 ## Synchronization
	 my @info = stat $descfile;
	 $param->{'serial_desc'} = $info[10];
     }

     ## Synchronization
     my @info = stat "$shareddir/$path";
     $param->{'serial_file'} = $info[10];
     ## parameters of the current directory
     $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[9]));

     $param->{'father_icon'} = $icon_table{'father'};
     return 1;
 }

 #*******************************************
 # Function : do_d_describe
 # Description : Saves the description of 
 #               the file
 #******************************************

 sub do_d_describe {
     &wwslog('info', 'do_d_describe(%s)', $in{'path'});

     # Variables
     my $path = $in{'path'};
     ## $path must have no slash at its end
     $path = &format_path('without_slash',$path);

     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     my $action_return;

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_describe: no list');
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_describe : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     ## the path must not be empty (the description file of the shared directory
     #  doesn't exist)
     unless ($path) {
	 &error_message('failed');
	 &wwslog('info',"d_describe : Cannot describe $shareddir : root directory");
	 return undef;
     }

     ## must be existing a content to replace the description
     unless ($in{'content'}) {
	 &error_message('no_description');
	 &wwslog('info',"do_d_describe : cannot describe $shareddir/$path : no content");
	 return undef;
     }

     # the file to describe must already exist
     unless (-e "$shareddir/$path") {
	 &error_message('failed');
	 &wwslog('info',"d_describe : Unable to describe $shareddir/$path : not an existing document");
	 return undef;
     }

     # Access control
	 # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','d_describe : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }


     ## End of controls

     if ($in{'content'} !~ /^\s*$/) {

	 # Description file
	 $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 my $dir = $1;
	 my $file = $3;

	 my $desc_file;
	 if (-d "$shareddir/$path") {
	     $action_return = 'd_read';
	     $desc_file = "$shareddir/$dir$file/.desc";
	 } else {
	     $action_return = 'd_editfile';
	     $desc_file = "$shareddir/$dir.desc.$file";
	 }

	 if (-r "$desc_file"){
	     # if description file already exists : open it and modify it
	     my %desc_hash = &get_desc_file ("$desc_file");

	     # Synchronization
	     unless (&synchronize($desc_file,$in{'serial'})){
		 &error_message('synchro_failed');
		 &wwslog('info',"d_describe : Synchronization failed for $desc_file");
		 return undef;
	     }

	     # fill the description file
	     unless (open DESC,">$desc_file") {
		 &wwslog('info',"do_d_describe : cannot open $desc_file : $!");
		 &error_message('failed');
		 return undef;
	     }

	     # information modified
	     print DESC "title\n  $in{'content'}\n\n"; 
	     # information not modified
	     print DESC "access\n  read $desc_hash{'read'}\n  edit $desc_hash{'edit'}\n\n";
	     print DESC "creation\n";
	     # time
	     print DESC "  date_epoch $desc_hash{'date'}\n";
	     # author
	     print DESC "  email $desc_hash{'email'}\n\n";

	     close DESC;

	 } else {
	     # Creation of a description file 
	     unless (open (DESC,">$desc_file")) {
		 &error_message('failed');
		 &wwslog('info',"d_describe : Cannot create description file $desc_file : $!");
		 return undef;
	     }
	     # fill
	     # description
	     print DESC "title\n  $in{'content'}\n\n";
	     # date and author
	     my @info = stat "$shareddir/$path";
	     print DESC "creation\n  date_epoch ".$info[10]."\n  email\n\n"; 
	     # access rights
	     print DESC "access\n";
	     print DESC "  read $access{'scenario'}{'read'}\n";
	     print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	     close DESC;

	 }
     }

     return $action_return;

 }

 #*******************************************
 # Function : do_d_savefile
 # Description : Saves a file edited in a 
 #               text area
 #******************************************

 sub do_d_savefile {
     &wwslog('info', 'do_d_savefile(%s)', $in{'path'});

     # Variables
     my $path = $in{'path'};

     if ($in{'url'}) {
	 $path .= $in{'name_doc'} . '.url';
     }

     if ($in{'name_doc'} =~ /[\[\]\/]/) {
	 &error_message('incorrect_name', {'name' => $in{'name_doc'} });
	 &wwslog('info',"do_d_savefile : Unable to create file $path : incorrect name");
	 return undef;
     }

     ## $path must have no slash at its end
     $path = &format_path('without_slash',$path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_savefile : no list');
	 return undef;
     }

     ## must be existing a content to replace the file
     unless ($in{'content'} || $in{'url'}) {
	 &error_message('no_content');
	 &wwslog('info',"do_d_savefile : Cannot save file $shareddir/$path : no content");
	 return undef;
     }

     my $creation;
     $creation = 1 unless (-f "$shareddir/$path");

     ### Document isn't a description file
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_savefile : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','d_savefile : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

 #### End of controls

     if (($in{'content'} =~ /^\s*$/) && ($in{'url'} =~ /^\s*$/)) {
	 &error_message('no_content');
	 &wwslog('info',"do_d_savefile : Cannot save file $shareddir/$path : no content");
	 return undef;
     }

     # Synchronization
     unless (&synchronize("$shareddir/$path",$in{'serial'})){
	 &error_message('synchro_failed');
	 &wwslog('info',"do_d_savefile : Synchronization failed for $shareddir/$path");
	 return undef;
     }

     # Renaming of the old file 
     rename ("$shareddir/$path","$shareddir/$path.old")
	 unless ($creation);

     if ($in{'url'}) {
	 open URL, ">$shareddir/$path";
	 print URL "$in{'url'}\n";
	 close URL;
     }else {
	 # Creation of the shared file
	 unless (open FILE, ">$shareddir/$path") {
	     rename("$shareddir/$path.old","$shareddir/$path");
	     &error_message('cannot_overwrite', {'reason' => $1,
						 'path' => $path});
	     &wwslog('info',"do_d_savefile : Cannot open for replace $shareddir/$path : $!");
	     return undef;
	 }
	 print FILE $in{'content'};
	 close FILE;
     }

     unlink "$shareddir/$path.old";

     # Description file
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $dir = $1;
     my $file = $3;
     if (-e "$shareddir/$dir.desc.$file"){

	 # if description file already exists : open it and modify it
	 my %desc_hash = &get_desc_file ("$shareddir/$dir.desc.$file");

	 open DESC,">$shareddir/$dir.desc.$file"; 

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 
	 print DESC "access\n  read $desc_hash{'read'}\n  edit $desc_hash{'edit'}\n\n";
	 print DESC "creation\n";
	 # date
	 print DESC '  date_epoch '.$desc_hash{'date'}."\n";

	 # information modified
	 # author
	 print DESC "  email $param->{'user'}{'email'}\n\n";

	 close DESC;

     } else {
	 # Creation of a description file if author is known

	 unless (open (DESC,">$shareddir/$dir.desc.$file")) {
	     &wwslog('info',"do_d_savefile: cannot create description file $shareddir/$dir.desc.$file");
	 }
	 # description
	 print DESC "title\n \n\n";
	 # date of creation and author
	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email $param->{'user'}{'email'}\n\n"; 
	 # Access
	 print DESC "access\n";
	 print DESC "  read $access{'scenario'}{'read'}\n";
	 print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	 close DESC;
     }

     &message('save_success', {'path' => $path});
     return $in{'previous_action'} || 'd_editfile';
 }

 #*******************************************
 # Function : do_d_overwrite
 # Description : Overwrites a file with a
 #               uploaded file
 #******************************************

 sub do_d_overwrite {
     &wwslog('info', 'do_d_overwrite(%s)', $in{'path'});

     # Variables
     my $path = $in{'path'};
     ##### $path must have no slash at its end!
     $path = &format_path('without_slash',$path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     # Parameters of the uploaded file
     my $fh = $query->upload('uploaded_file');
     my $fn = $query->param('uploaded_file');

     $fn =~ /([^\/\\]+)$/;
     my $fname = $1;


 ####### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_overwrite : no list');
	 return undef;
     }

     # uploaded file must have a name 
     unless ($fname) {
	 &error_message('missing_arg');
	 &wwslog('info',"do_d_overwrite : No file specified to overwrite");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_overwrite : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     # the path to replace must already exist
     unless (-e "$shareddir/$path") {
	 &error_message('failed');
	 &wwslog('info',"do_d_overwrite : Unable to overwrite $shareddir/$path : not an existing file");
	 return undef;
     }

     # the path must represent a file
     if (-d "$shareddir/$path") {
	 &error_message('failed');
	 &wwslog('info',"do_d_overwrite : Unable to create $shareddir/$path : a directory named $path already exists");
	 return undef;
     }


       # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','do_d_overwrite :  access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

 #### End of controls


     # Synchronization
     unless (&synchronize("$shareddir/$path",$in{'serial'})){
	 &error_message('synchro_failed');
	 &wwslog('info',"do_d_overwrite : Synchronization failed for $shareddir/$path");
	 return undef;
     }

     # Renaming of the old file 
     rename ("$shareddir/$path","$shareddir/$path.old");

     # Creation of the shared file
     unless (open FILE, ">$shareddir/$path") {
	 &error_message('cannot_overwrite', {'path' => $path,
				       'reason' => $!});
	 &wwslog('info',"d_overwrite : Cannot open for replace $shareddir/$path : $!");
	 return undef;
     }
     while (<$fh>) {
	 print FILE;
     }
     close FILE;

     # Description file
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $dir = $1;
     my $file = $3;
     if (-e "$shareddir/$dir.desc.$file"){
	 # if description file already exists : open it and modify it
	 my %desc_hash = &get_desc_file ("$shareddir/$dir.desc.$file");

	 open DESC,">$shareddir/$dir.desc.$file"; 

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 
	 print DESC "access\n  read $desc_hash{'read'}\n  edit $desc_hash{'edit'}\n\n";
	 print DESC "creation\n";
	 # time
	 print DESC "  date_epoch $desc_hash{'date'}\n";
	 # information modified
	 # author
	 print DESC "  email $param->{'user'}{'email'}\n\n";

	 close DESC;
     } else {
	 # Creation of a description file
	 unless (open (DESC,">$shareddir/$dir.desc.$file")) {
	     &wwslog('info',"do_d_overwrite : Cannot create description file $shareddir/$dir.desc.$file");
	     return undef;
	 }
	 # description
	 print DESC "title\n  \n\n";
	 # date of creation and author
	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email $param->{'user'}{'email'}\n\n"; 
	 # access rights
	 print DESC "access\n";
	 print DESC "  read $access{'scenario'}{'read'}\n";
	 print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	 close DESC;

     }

     # Removing of the old file
     unlink "$shareddir/$path.old";

     $in{'list'} = $list_name;
     #$in{'path'} = $dir;

     # message of success
     &message('upload_success', {'path' => $path});
     return 'd_editfile';
 }

 #*******************************************
 # Function : do_d_upload
 # Description : Creates a new file with a 
 #               uploaded file
 #******************************************

 sub do_d_upload {
     # Parameters of the uploaded file
     my $fn = $query->param('uploaded_file');

     $fn =~ /([^\/\\]+)$/;
     my $fname = $1;

     &wwslog('info', 'do_d_upload(%s%s)', $in{'path'},$fname);

     # Variables 
     my $path = $in{'path'};
     ## $path must have a slash at its end
     $path = &format_path('with_slash',$path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';


 # Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_upload : no list');
	 return undef;
     }


     # uploaded file must have a name 
     unless ($fname) {
	 &error_message('no_name');
	 &wwslog('info',"do_d_upload : No file specified to upload");
	 return undef;
     }

     ## Check quota
     if ($list->{'admin'}{'shared_doc'}{'quota'}) {
	 if ($list->get_shared_size() >= $list->{'admin'}{'shared_doc'}{'quota'} * 1024){
	     &error_message('shared_full');
	     &wwslog('info',"do_d_upload : Shared Quota exceeded for list $list->{'name'}");
	     return undef;
	 }
     }

     # The name of the file must be correct and musn't not be a description file
     if ($fname =~ /^\./
	 || $fname =~ /\.desc/ 
	 || $fname =~ /[~\#\[\]]$/) {

 #    unless ($fname =~ /^\w/ and 
 #	    $fname =~ /\w$/ and 
 #	    $fname =~ /^[\w\-\.]+$/ and
 #	    $fname !~ /\.desc/) {
	 &error_message('incorrect_name', {'name' => $fname});
	 &wwslog('info',"do_d_upload : Unable to create file $fname : incorrect name");
	 return undef;
     }

     # the file must be uploaded in a directory existing
     unless (-d "$shareddir/$path") {
	 &error_message('failed');
	 &wwslog('info',"do_d_upload : $shareddir/$path : not a directory");
	 return undef;
     }

     # Lowercase for file name
     $fname = $fname;

     # the file mustn't already exist
     if (-e "$shareddir/$path$fname") {
	 &error_message('cannot_upload', {'path' => "$path$fname",
				    'reason' => "file already exists"});
	 &wwslog('info',"do_d_upload : Unable to create $shareddir/$path$fname : file already exists");
	 return undef;
     }

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     $mode{'control'} = 1; # for the exception index.html
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','do_d_upload : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## Exception index.html
     unless ($fname !~ /^index.html?$/i) {
	 unless ($access{'may'}{'control'}) {
	     &error_message('index_html', {'dir' => $path});
	     &wwslog('info',"do_d_upload : $param->{'user'}{'email'} not authorized to upload a INDEX.HTML file in $path");
	     return undef;
	 }
     }

 ## End of controls

 # Creation of the shared file
     my $fh = $query->upload('uploaded_file');
     unless (open FILE, ">$shareddir/$path$fname") {
	 &error_message('cannot_upload', {'path' => "$path$fname",
				    'reason' => $!});
	 &wwslog('info',"do_d_upload : Cannot open file $shareddir/$path$fname : $!");
	 return undef;
     }
     while (<$fh>) {
	 print FILE;
     }
     close FILE;

 # Creation of the description file
     unless (open (DESC,">$shareddir/$path.desc.$fname")) {
	 &wwslog('info',"do_d_upload: cannot create description file $shareddir/.desc.$path$fname");
     }

     print DESC "title\n \n\n"; 
     print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 

     print DESC "access\n";
     print DESC "  read $access{'scenario'}{'read'}\n";
     print DESC "  edit $access{'scenario'}{'edit'}\n";  

     close DESC;

     ## ???
     $in{'list'} = $list_name;
     return 'd_read';
 }

 #*******************************************
 # Function : do_d_delete
 # Description : Delete an existing document
 #               (file or directory)
 #******************************************

 sub do_d_delete {
     &wwslog('info', 'do_d_delete(%s)', $in{'path'});

     #useful variables
     my $path = $in{'path'};
     ## $path must have no slash at its end!
     $path = &format_path('without_slash',$path);

     #Current directory and document to delete
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $current_directory = &format_path('without_slash',$1);
     my $document = $3;

      # path of the shared directory
     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';

 #### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_delete : no list');
	 return undef;
     }

     ## must be something to delete
     unless ($document) {
	 &error_message('missing_arg', {'argument' => 'document'});
	 &wwslog('info',"do_d_delete : no document to delete has been specified");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($document !~ /^\.desc/) {
	 &wwslog('info',"do_d_delete : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }


     ### Document exists?
     unless (-e "$shareddir/$path") {
	 &wwslog('info',"do_d_delete : $shareddir/$path : no such file or directory");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     # removing of the document
     my $doc = "$shareddir/$path";

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','do_d_rename : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## Directory
     if (-d "$shareddir/$path") {

	 # test of emptiness
	 opendir DIR, "$doc";
	 my @readdir = readdir DIR;
	 close DIR;

	 # test for "ordinary" files
	 my @test_normal = grep !/^\./, @readdir;
	 my @test_hidden = grep !(/^\.desc$/ | /^\.(\.)?$/ | /^[^\.]/), @readdir;
	 if (($#test_normal != -1) || ($#test_hidden != -1)) {
	     &error_message('full_directory', {'directory' => $path});
	     &wwslog('info',"do_d_delete : Failed to erase $doc : directory not empty");
	     return undef;
	 }

	 # removing of the description file if exists
	 if (-e "$doc/\.desc") {
	     unless (unlink("$doc/.desc")) {
		 &error_message('failed');
		 &wwslog('info',"do_d_delete : Failed to erase $doc/.desc : $!");
		 return undef;
	     }
	 }   
	 # removing of the directory
	 rmdir $doc;

	 ## File
     }else {

	 # removing of the document
	 unless (unlink($doc)) {
	     &error_message('failed');
	     &wwslog('info','do_d_delete: failed to erase %s', $doc);
	     return undef;
	 }
	 # removing of the description file if exists
	 if (-e "$shareddir/$current_directory/.desc.$document") {
	     unless (unlink("$shareddir/$current_directory/.desc.$document")) {
		 &wwslog('info',"do_d_delete: failed to erase $shareddir/$current_directory/.desc.$document");
	     }
	 }   
     }

     $in{'list'} = $list_name;
     $in{'path'} = $current_directory.'/';
     return 'd_read';
 }

 #*******************************************
 # Function : do_d_rename
 # Description : Rename a document
 #               (file or directory)
 #******************************************

 sub do_d_rename {
     &wwslog('info', 'do_d_rename(%s)', $in{'path'});

     #useful variables
     my $path = $in{'path'};

     ## $path must have no slash at its end!
     $path = &format_path('without_slash',$path);

     #Current directory and document to delete
     my $current_directory;
     if ($path =~ /^(.*)\/([^\/]+)$/) {
	 $current_directory = &format_path('without_slash',$1);
     }else {
	 $current_directory = '.';
     }
     $path =~ /(^|\/)([^\/]+)$/; 
     my $document = $2;

     # path of the shared directory
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';

 #### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_rename : no list');
	 return undef;
     }

     ## must be something to delete
     unless ($document) {
	 &error_message('missing_arg', {'argument' => 'document'});
	 &wwslog('info',"do_d_rename : no document to rename has been specified");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($document !~ /^\.desc/) {
	 &wwslog('info',"do_d_rename : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     ### Document exists?
     unless (-e "$shareddir/$path") {
	 &wwslog('info',"do_d_rename : $shareddir/$path : no such file or directory");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     ## New document name
     unless ($in{'new_name'}) {
	 &error_message('missing_arg', {'argument' => 'new name'});
	 &wwslog('info',"do_d_rename : new name missing");
	 return undef;
     }

     if ($in{'new_name'} =~ /^\./
	 || $in{'new_name'} =~ /\.desc/ 
	 || $in{'new_name'} =~ /[~\#\[\]\/]$/) {
	 &error_message('incorrect_name', {'name' => $in{'new_name'}});
	 &wwslog('info',"do_d_rename : Unable to create file $in{'new_name'} : incorrect name");
	 return undef;
     }

     if (($document =~ /\.url$/) && ($in{'new_name'} !~ /\.url$/)) {
	 &error_message('incorrect_name', {'name' => $in{'new_name'}});
	 &wwslog('info',"do_d_rename : New file name $in{'new_name'} does not match URL filenames");
	 return undef;
     }

     my $doc = "$shareddir/$path";

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','do_d_rename : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     unless (rename $doc, "$shareddir/$current_directory/$in{'new_name'}") {
	 &error_message('failed');
	 &wwslog('info',"do_d_rename : Failed to rename %s to %s : %s", $doc, "$shareddir/$current_directory/$in{'new_name'}", $!);
	 return undef;
     }

     ## Rename description file
     my $desc_file = "$shareddir/$current_directory/.desc.$document";
     if (-f $desc_file) {
	 my $new_desc_file = $desc_file;
	 $new_desc_file =~ s/$document/$in{'new_name'}/;

	 unless (rename $desc_file, $new_desc_file) {
	     &error_message('failed');
	     &wwslog('info',"do_d_rename : Failed to rename $desc_file : $!");
	     return undef;
	 }
     }

     $in{'list'} = $list_name;
     $in{'path'} = $current_directory.'/';
     return 'd_read';
 }

 #*******************************************
 # Function : do_d_create
 # Description : Creates a new file / directory
 #******************************************
 sub do_d_create_dir {
     &wwslog('info', 'do_d_create_dir(%s)', $in{'name_doc'});

     #useful variables
     my $path = $in{'path'};
     ## $path must have a slash at its end
     $path = &format_path('with_slash',$path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};
     my $name_doc = $in{'name_doc'};

     $param->{'list'} = $list_name;
     $param->{'path'} = $path;

     my $type = $in{'type'} || 'directory';
     my $desc_file;

 ### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_create_dir : no list');
	 return undef;
     }

      # Must be a directory to create (directory name not empty)
     unless ($name_doc) {
	 &error_message('no_name');
	 &wwslog('info',"do_d_create_dir : Unable to create directory : no name specified!");
	 return undef;
     }

     # The name of the directory must be correct
     if ($name_doc =~ /^\./
	 || $name_doc =~ /\.desc/ 
	 || $name_doc =~ /[~\#\[\]\/]$/) {
	 &error_message('incorrect_name', {'name' => $name_doc});
	 &wwslog('info',"do_d_create_dir : Unable to create directory $name_doc : incorrect name");
	 return undef;
     }


     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode, $path);

     unless ($access{'may'}{'edit'}) {
	 &error_message('may_not');
	 &wwslog('info','do_d_create_dir :  access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }    
     ### End of controls

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     my $document = "$shareddir/$path$name_doc";

     $param->{'document'} = $document;

     if ($type eq 'directory') {
	 # Creation of the new directory
	 unless (mkdir ("$document",0777)) {
	     &error_message('cannot_create_dir', {'path' => $document,
						  'reason' => $!});
	     &wwslog('info',"do_d_create_dir : Unable to create $document : $!");
	     return undef;
	 }

	 $desc_file = "$document/.desc";

     }else {
	 # Creation of the new file
	 unless (open FILE, ">$document") {
	     &error_message('cannot_create_file', {'path' => $document,
						   'reason' => $!});
	     &wwslog('info',"do_d_create_dir : Unable to create $document : $!");
	     return undef;
	 }
	 close FILE;

	 $desc_file = "$shareddir/$path.desc.$name_doc";
     }

     # Creation of a default description file 
     unless (open (DESC,">$desc_file")) {
	 &error_message('failed');
	 &wwslog('info','do_d_create_dir : Cannot create description file %s', $document.'/.desc');
     }

     print DESC "title\n \n\n"; 
     print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 

     print DESC "access\n";
     print DESC "  read $access{'scenario'}{'read'}\n";
     print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

     close DESC;

     if ($type eq 'directory') {
	 return 'd_read';
     }

     $in{'path'} = "$path$name_doc";
     return 'd_editfile';
 }

 ############## Control


 #*******************************************
 # Function : do_d_control
 # Description : prepares the parameters
 #               to edit access for a doc
 #*******************************************

 sub do_d_control {
     &wwslog('info', "do_d_control $in{'path'}");

     # Variables
     my $path = $in{'path'};
     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';
     ## $path must have no slash at its end
     $path = &format_path('without_slash',$path);


     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_control: no list');
	 return undef;
     }

     unless ($path) {
	 &error_message('missing_arg', {'argument' => 'document_name'});
	 &wwslog('info','do_d_control: no document name');
	 return undef;
     }   

     # Existing document? 
     unless (-e "$shareddir/$path") {
	 &error_message('no_such_document', {'path' => $path});
	 &wwslog('info',"do_d_control : Cannot control $shareddir/$path : not an existing document");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_control : $shareddir/$path : description file");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     # Access control
     my %mode;
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);
     unless ($access{'may'}{'control'}) {
	 &error_message('may_not');
	 &wwslog('info','d_control : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }


  ## End of controls


     #Current directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = $1;    
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     my $desc_file;
     # path of the description file
     if (-d "$shareddir/$path") {
	 $desc_file = "$shareddir/$1$3/.desc";
     } else {
	 $desc_file = "$shareddir/$1.desc.$3";
     }

     # Description of the file
     my $read;
     my $edit;

     if (-e $desc_file) {

	 ## Synchronization
	 my @info = stat "$desc_file";
	 $param->{'serial_desc'} = $info[10];
	 my %desc_hash = &get_desc_file("$desc_file");
	 # rights for read and edit
	 $read = $desc_hash{'read'};
	 $edit = $desc_hash{'edit'};
	 # owner of the document
	 $param->{'owner'} = $desc_hash{'email'};
	 $param->{'doc_title'} = $desc_hash{'title'};
     }else {
	 $read = $access{'scenario'}{'read'};
	 $edit = $access{'scenario'}{'edit'};
     }

     ## other info
     my @info = stat "$shareddir/$path";
     $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[9]));

     # template parameters
     $param->{'list'} = $list_name;
     $param->{'path'} = $path;

     my $lang = $param->{'lang'};

     ## Scenario list for READ
     my $read_scenario_list = $list->load_scenario_list('d_read', $robot);
     $param->{'read'}{'scenario_name'} = $read;
     $param->{'read'}{'label'} = $read_scenario_list->{$read}{'title'}{$lang};

     foreach my $key (keys %{$read_scenario_list}) {
	 $param->{'scenari_read'}{$key}{'scenario_name'} = $read_scenario_list->{$key}{'name'};
	 $param->{'scenari_read'}{$key}{'scenario_label'} = $read_scenario_list->{$key}{'title'}{$lang};
	 if ($key eq $read) {
	     $param->{'scenari_read'}{$key}{'selected'} = 'SELECTED';
	 }
     }

     ## Scenario list for EDIT
     my $edit_scenario_list = $list->load_scenario_list('d_edit', $robot);
     $param->{'edit'}{'scenario_name'} = $edit;
     $param->{'edit'}{'label'} = $edit_scenario_list->{$edit}{'title'}{$lang};

     foreach my $key (keys %{$edit_scenario_list}) {
	 $param->{'scenari_edit'}{$key}{'scenario_name'} = $edit_scenario_list->{$key}{'name'};
	 $param->{'scenari_edit'}{$key}{'scenario_label'} = $edit_scenario_list->{$key}{'title'}{$lang};
	 if ($key eq $edit) {
	     $param->{'scenari_edit'}{$key}{'selected'} = 'SELECTED';
	 }
     }

     ## father directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = $1;    
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     $param->{'set_owner'} = 1;

     $param->{'father_icon'} = $icon_table{'father'};
     return 1;
 }


 #*******************************************
 # Function : do_d_change_access
 # Description : Saves the description of 
 #               the file
 #******************************************

 sub do_d_change_access {
     &wwslog('info', 'do_d_change_access(%s)', $in{'path'});

     # Variables
     my $path = $in{'path'};
     ## $path must have no slash at its end
     $path = &format_path('without_slash',$path);

     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_change_access: no list');
	 return undef;
     }

     ## the path must not be empty (the description file of the shared directory
     #  doesn't exist)
     unless ($path) {
	 &error_message('failed');
	 &wwslog('info',"do_d_change_access : Cannot change access $shareddir : root directory");
	 return undef;
     }

     # the document to describe must already exist 
     unless (-e "$shareddir/$path") {
	 &error_message('failed');
	 &wwslog('info',"d_change_access : Unable to change access $shareddir/$path : no such document");
	 return undef;
     }


     # Access control
     my %mode;
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'control'}) {
	 &error_message('may_not');
	 &wwslog('info','d_change_access : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## End of controls

     # Description file
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $dir = $1;
     my $file = $3;

     my $desc_file;
     if (-d "$shareddir/$path") {
	 $desc_file = "$shareddir/$1$3/.desc";
     } else {
	 $desc_file = "$shareddir/$1.desc.$3";
     }

     if (-e "$desc_file"){
	 # if description file already exists : open it and modify it
	 my %desc_hash = &get_desc_file ("$desc_file");

	 # Synchronization
	 unless (&synchronize($desc_file,$in{'serial'})){
	     &error_message('synchro_failed');
	     &wwslog('info',"d_change_access : Synchronization failed for $desc_file");
	     return undef;
	 }

	 unless (open DESC,">$desc_file") {
	     &wwslog('info',"d_change_access : cannot open $desc_file : $!");
	     &error_message('failed');
	     return undef;
	 }

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 

	 # access rights
	 print DESC "access\n  read $in{'read_access'}\n";
	 print DESC "  edit $in{'edit_access'}\n\n";

	 print DESC "creation\n";
	 # time
	 print DESC "  date_epoch $desc_hash{'date'}\n";
	 # author
	 print DESC "  email $desc_hash{'email'}\n\n";

	 close DESC;

     } else {
	 # Creation of a description file 
	 unless (open (DESC,">$desc_file")) {
	     &error_message('failed');
	     &wwslog('info',"d_change_access : Cannot create description file $desc_file : $!");
	     return undef;
	 }
	 print DESC "title\n \n\n";

	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email\n\n"; 
	 print DESC "access\n  read $in{'read_access'}\n";
	 print DESC "  edit $in{'edit_access'}\n\n";

	 close DESC;

     }

     return 'd_control';


 }	

 sub do_d_set_owner {
     &wwslog('info', 'do_d_set_owner(%s)', $in{'path'});

     # Variables
     my $desc_file;

     my $path = $in{'path'};
     ## $path must have no slash at its end
     $path = &format_path('without_slash',$path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_d_set_owner: no list');
	 return undef;
     }


     ## the path must not be empty (the description file of the shared directory
     #  doesn't exist)
     unless ($path) {
	 &error_message('failed');
	 &wwslog('info',"do_d_set_owner : Cannot change access $shareddir : root directory");
	 return undef;
     }

     # the email must look like an email "somebody@somewhere"
     unless (&tools::valid_email($in{'content'})) {
	 &error_message('incorrect_email', {'email' => $in{'content'}});
	 &wwslog('info',"d_set_owner : $in{'content'} : incorrect email");
	 return undef;
     }

     # Access control
     ## father directory
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $dir = $1; 
     my $file = $3;
     if (-d "$shareddir/$path") {
	 $desc_file = "$shareddir/$dir$file/.desc"; 
     }else {
	 $desc_file = "$shareddir/$dir.desc.$file";
     }       

     my %mode;
     $mode{'control'} = 1;
       ## must be authorized to control father directory
     #my %access = &d_access_control(\%mode,$1);
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'control'}) {
	 &error_message('may_not');
	 &wwslog('info','d_set_owner : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $may_set = 1;

     unless ($may_set) {
	 &error_message('full_directory', {'directory' => $path});
	 &wwslog('info',"d_set_owner : cannot set owner of a full directory");
	 return undef;
     }

 ## End of controls

     my %desc_hash;

     if (-e "$desc_file"){
	 # if description file already exists : open it and modify it
	 %desc_hash = &get_desc_file ("$desc_file");

	 # Synchronization
	 unless (&synchronize($desc_file,$in{'serial'})){
	     &error_message('synchro_failed');
	     &wwslog('info',"d_set_owner : Synchronization failed for $desc_file");
	     return undef;
	 }

	 unless (open DESC,">$desc_file") {
	     &wwslog('info',"d_set_owner : cannot open $desc_file : $!");
	     &error_message('failed');
	     return undef;
	 }

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 

	 print DESC "access\n  read $desc_hash{'read'}\n";
	 print DESC "  edit $desc_hash{'edit'}\n\n";
	 print DESC "creation\n";
	 # time
	 print DESC "  date_epoch $desc_hash{'date'}\n";

	 #information modified
	 # author
	 print DESC "  email $in{'content'}\n\n";

	 close DESC;

     } else {
	 # Creation of a description file 
	 unless (open (DESC,">$desc_file")) {
	     &error_message('failed');
	     &wwslog('info',"d_set_owner : Cannot create description file $desc_file : $!");
	     return undef;
	 }
	 print DESC "title\n  $desc_hash{'title'}\n\n";
	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email $in{'content'}\n\n"; 

	 print DESC "access\n  read $access{'scenario'}{'read'}\n";
	 print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	 close DESC;

     }

     ## ONLY IF SET_OWNER can be performed even if not control of the father directory
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);
     unless ($access{'may'}{'control'}) {
	 ## father directory
	 $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 $in{'path'} = $1;
	 return 'd_read';
     }

     ## ELSE
     return 'd_control';
 }

 ## Protecting archives from Email Sniffers
 sub do_arc_protect {
     &wwslog('info', 'do_arc_protect()');

     return 1;
 } 

 ## Show a state of template translations
 sub do_view_translations {
      &wwslog('info', 'do_view_translations()');
      my %lang = ('default' => 1);

      unless (opendir TPL, "--ETCBINDIR--/wws_templates/") {
	  &error_message('error');
	  &wwslog('info','do_view_translations: unable to read --ETCBINDIR--/wws_templates/');
	  return undef;
      }

      foreach my $tpl (sort grep(/\.tpl$/, readdir TPL)) {
	  my @token = split /\./, $tpl;
	  if ($#token == 2) {
	      $param->{'tpl'}{$token[0]}{$token[1]} = 'bin';
	      $lang{$token[1]} = 1;
	  }else {
	      $param->{'tpl'}{$token[0]}{'default'} = 'bin';
	  }
      }

      closedir TPL;

      foreach my $l (keys %lang) {
	  foreach my $t (keys %{$param->{'tpl'}}) {
	      $param->{'tpl'}{$t}{$l} ||= 'none';
	  }
      }

      $param->{'tpl_lang'} = \%lang;

      return 1;
 }

 ## REMIND
 sub do_remind {
     &wwslog('info', 'do_remind()');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_remind: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_remind: no user');
	 return 'loginrequest';
     }

     ## Access control
     unless (&List::request_action ('remind',$param->{'auth_method'},$robot,
				    {'listname' => $param->{'list'},
				     'sender' => $param->{'user'}{'email'},
				     'remote_host' => $param->{'remote_host'},
				     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	 &error_message('may_not');
	 &wwslog('info','do_remind: access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $extention = time.".".int(rand 9999) ;
     my $mail_command;

     ## Sympa will require a confirmation
     if (&List::request_action ('remind','smtp',$robot,
				    {'listname' => $param->{'list'},
				     'sender' => $param->{'user'}{'email'},
				     'remote_host' => $param->{'remote_host'},
				     'remote_addr' => $param->{'remote_addr'}}) =~ /reject/i) {

	 &error_message('may_not');
	 &wwslog('info','remind : access denied for %s', $param->{'user'}{'email'});
	 return undef;

     }else {
	 $mail_command = sprintf "REMIND %s", $param->{'list'};
     }

     open REMIND, ">$Conf{'queue'}/T.".&Conf::get_robot_conf($robot, 'sympa').".$extention" ;

     printf REMIND ("X-Sympa-To: %s\n",&Conf::get_robot_conf($robot, 'sympa'));
     printf REMIND ("Message-Id: <%s\@wwsympa>\n", time);
     printf REMIND ("From: %s\n\n", $param->{'user'}{'email'});

     printf REMIND "$mail_command\n";

     close REMIND;

     rename("$Conf{'queue'}/T.".&Conf::get_robot_conf($robot, 'sympa').".$extention","$Conf{'queue'}/".&Conf::get_robot_conf($robot, 'sympa').".$extention");

     &message('performed_soon');

     return 'admin';
 }

 ## Load list certificat
 sub do_load_cert {
     &wwslog('info','do_load_cert(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_load_cert: no list');
	 return undef;
     }
     my @cert = $list->get_cert();
     unless (@cert) {
	 &error_message('missing_cert');
	 &wwslog('info','do_load_cert: no cert for this list');
	 return undef;
     }

     $param->{'bypass'} = 'extreme';
     printf "Content-type: application/x-x509-email-cert\n\n";
     foreach my $l (@cert) {
	 printf "$l";
     }
     return 1;
 }


 ## Change a user's email address in Sympa environment
 sub do_change_email {
     &wwslog('info','do_change_email(%s)', $in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_change_password: user not logged in');
	 return undef;
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_change_email: no email');
	 return undef;
     }

     my ($password, $newuser);

     if ($newuser =  &List::get_user_db($in{'email'})) {

	 $password = $newuser->{'password'};
     }

     $password ||= &tools::tmp_passwd($in{'email'});

     ## Step 2 : checking password
     if ($in{'password'}) {
	 unless ($in{'password'} eq $password) {
	     &error_message('incorrect_passwd');
	     &wwslog('info','do_change_email: incorrect password for user %s', $in{'email'});
	     return undef;
	 }

	 ## Change email
	 foreach my $l ( &List::get_which($param->{'user'}{'email'},$robot, 'member') ) {
	     my $list = new List ($l);

	     my $sub_is = &List::request_action('subscribe',$param->{'auth_method'},$robot,
						{'listname' => $l,
						 'sender' => $in{'email'}, 
						 'previous_email' => $param->{'user'}{'email'},
						 'remote_host' => $param->{'remote_host'},
						 'remote_addr' => $param->{'remote_addr'}});

	     my $unsub_is = &List::request_action('unsubscribe',$param->{'auth_method'},$robot,
						  {'listname' => $l,
						   'sender' => $param->{'user'}{'email'}, 
						   'remote_host' => $param->{'remote_host'},
						   'remote_addr' => $param->{'remote_addr'}});


	     if ($sub_is !~ /do_it/) {	
		 &error_message('change_email_failed_because_subscribe_not_allowed',{'list' => $l}) ;
		 &wwslog('info', "do_change_email: could not change email for list %s because subscribe not allowed");
		 next;
	     }elsif($unsub_is !~ /do_it/) {	
		 &error_message('change_email_failed_because_unsubscribe_not_allowed',{'list' => $l});
		 &wwslog('info', "do_change_email : could not change email for list %s because unsubscribe not allowed");
		 next;
	     }
	     #elsif(($sub_is =~ /owner/) || ($unsub_is =~ /owner/)) {
	     #    next;
	     #}
	     unless ($list->update_user($param->{'user'}{'email'}, {'email' => $in{'email'}, 'update_date' => time}) ) {
		 &error_message('change_email_failed', {'list' => $l});
		 &wwslog('info', 'do_change_email: could not change email for list %s', $l);
	     }
	 }

	 &message('done');

	 ## Update User_table
	 &List::delete_user_db($in{'email'});

	 unless ( &List::update_user_db($param->{'user'}{'email'},
					{'email' => $in{'email'},
					 'lang' => $param->{'user'}{'lang'},
					 'cookie_delay' => $param->{'user'}{'cookie_delay'},
					 'gecos' => $param->{'user'}{'gecos'}
					    })) {
	     &error_message('update_failed');
	     &wwslog('info','change_email: update failed');
	     return undef;
	 }

	 ## Change login
	 $param->{'user'} = &List::get_user_db($in{'email'});

	 return 'pref';

	 ## Step 1 : sending password
     }else {
	 $param->{'newuser'} = {'email' => $in{'email'},
				'password' => $password };

	 &List::send_global_file('sendpasswd', $in{'email'}, $robot, $param);

	 $param->{'email'} = $in{'email'};

	 return '1';
     }

     $param->{'email'} = $in{'email'};

     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }else {
	 return 'pref';
     }

 }

 sub do_compose_mail {
     &wwslog('info', 'do_compose_mail');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_compose_mail: no user');
	 $param->{'previous_action'} = 'compose_mail';
	 return 'loginrequest';
     }

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_compose_mail: no list');
	 return undef;
     }

     unless ($param->{'may_post'}) {
	 &error_message('may_not');
	 &wwslog('info','do_compose_mail: may not send message');
	 return undef;
     }
     if ($in{'to'}) {
	 # In archive we hidde email replacing @ by ' '. Here we must do ther reverse transformation
	 $in{'to'} =~ s/ /\@/;
	 $param->{'to'} = $in{'to'};
     }else{
	 $param->{'to'} = $list->{'name'} . '@' . $list->{'admin'}{'host'};
     }
     ($param->{'local_to'},$param->{'domain_to'}) = split ('@',$param->{'to'});

     $param->{'mailto'}= &mailto($list,$param->{'to'});
     $param->{'subject'}= &MIME::Words::encode_mimewords($in{'subject'});
     $param->{'in_reply_to'}= $in{'in_reply_to'};
     $param->{'message_id'} = &tools::get_message_id($robot);
     return 1;
 }

 sub do_send_mail {
     &wwslog('info', 'do_send_mail');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_send_mail: no user');
	 $param->{'previous_action'} = 'send_mail';
	 return 'loginrequest';
     }

     # In archive we hidde email replacing @ by ' '. Here we must do ther reverse transformation
     $in{'to'} =~ s/ /\@/;
     my $to = $in{'to'};
     unless ($in{'to'}) {
	 unless ($param->{'list'}) {
	     &error_message('missing_arg', {'argument' => 'list'});
	     &wwslog('info','do_send_mail: no list');
	     return undef;		
	 }
	 unless ($param->{'may_post'}) {
	     &error_message('may_not');
	     &wwslog('info','do_send_mail: may not send message');
	     return undef;
	 }
	 $to = $list->{'name'}.'@'.$list->{'admin'}{'host'};
     }

     ## Remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
     $in{'body'} =~ s/\015//g;

     my @body = split /\0/, $in{'body'};

     &mail::mailback(\@body, 
		     {'Subject' => $in{'subject'}, 
		      'In-Reply-To' => $in{'in_reply_to'},
		      'Message-ID' => $in{'message_id'}}, 
		     $param->{'user'}{'email'}, $to, $robot, $to);

     &message('performed');
     return 'info';
 }

 sub do_search_user {
     &wwslog('info', 'do_search_user');

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_search_user: no user');
	 return 'serveradmin';
     }

     unless ($param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_search_user: requires listmaster privilege');
	 return undef;
     }

     unless ($in{'email'}) {
	 &error_message('missing_arg', {'argument' => 'email'});
	 &wwslog('info','do_search_user: no email');
	 return undef;
     }

     foreach my $role ('member','owner','editor') {
	 foreach my $l ( &List::get_which($in{'email'},$robot, $role) ) {
	     my $list = new List ($l);

	     $param->{'which'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'which'}{$l}{'host'} = $list->{'admin'}{'host'};
	     if ($role eq 'member') {
		 $param->{'which'}{$l}{'info'} = 1;
	     }else {
		 $param->{'which'}{$l}{'admin'} = 1;
	     }
	 }
     }

     $param->{'email'} = $in{'email'};

     unless (defined $param->{'which'}) {
	 &error_message('no_entry');
	 &wwslog('info','do_search_user: no entry for %s', $in{'email'});
	 return 'serveradmin';
     }

     return 1;
 }

 ## Set language
 sub do_set_lang {
     &wwslog('info', 'do_set_lang(%s)', $in{'lang'});

     $param->{'lang'} = $param->{'cookie_lang'} = $in{'lang'};
     &cookielib::set_lang_cookie($in{'lang'},$param->{'cookie_domain'});

     if ($param->{'user'}{'email'}) {
	 if (&List::is_user_db($param->{'user'}{'email'})) {
	     unless (&List::update_user_db($param->{'user'}{'email'}, {'lang' => $in{'lang'}})) {
		 &error_message('update_failed');
		 &wwslog('info','do_set_lang: update failed');
		 return undef;
	     }
	 }else {
	     unless (&List::add_user_db({'email' => $param->{'user'}{'email'}, 'lang' => $in{'lang'}})) {
		 &error_message('update_failed');
		 &wwslog('info','do_set_lang: update failed');
		 return undef;
	     }
	 }
     }

     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }

     return 'home';
 }
 ## Function do_attach
 sub do_attach {
     &wwslog('info', 'do_attach(%s)', $in{'path'});


     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','attach: no list');
	 return undef;
     }

     ### Useful variables

     # current list / current shared directory
     my $list_name = $list->{'name'};

     # relative path / directory shared of the document 
     my $path = &tools::escape_chars($in{'dir'}).'/'.$in{'file'};
     my $path_orig = $path;

     # path of the urlized directory
     my $urlizeddir =  $list->{'dir'}.'/urlized';

     # document to read
     my $doc;
     if ($path) {
	 # the path must have no slash a its end
	 $path =~ /^(.*[^\/])?(\/*)$/;
	 $path = $1;
	 $doc = $urlizeddir.'/'.$path;
     } else {
	 $doc = $urlizeddir;
     }

     ### Document exist ? 
     unless (-e "$doc") {
	 &wwslog('info',"do_attach : unable to read $urlizeddir/$path : no such file or directory");
	 &error_message('no_such_document', {'path' => $path});
	 return undef;
     }

     ### Document has non-size zero?
     unless (-s "$doc") {
	 &wwslog('info',"do_attach : unable to read $urlizeddir/$path : empty document");
	 &error_message('empty_document', {'path' => $path});
	 return undef;
     }

     ### Access control    
     unless (&List::request_action ('web_archive.access',$param->{'auth_method'},$robot,
				    {'listname' => $param->{'list'},
				     'sender' => $param->{'user'}{'email'},
				     'remote_host' => $param->{'remote_host'},
				     'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	 &error_message('may_not');
	 &wwslog('info','do_attach: access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     # parameters for the template file
     # view a file 
     $param->{'file'} = $doc;

     ## File type
     $path =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/; 

     $param->{'file_extension'} = $3;
     $param->{'bypass'} = 'asis';
 }

 sub do_subindex {
     &wwslog('info', 'do_subindex');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_subindex: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_subindex: no user');
	 $param->{'previous_action'} = 'modindex';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_subindex: %s not owner', $param->{'user'}{'email'});
	 return 'admin';
     }


     my $subscriptions = $list->get_subscription_requests();
     foreach my $sub (keys %{$subscriptions}) {
	 $subscriptions->{$sub}{'date'} = &POSIX::strftime("%d %b %Y", localtime($subscriptions->{$sub}{'date'}));
     }

     $param->{'subscriptions'} = $subscriptions;

     return 1;
 }

 sub do_ignoresub {
     &wwslog('info', 'do_ignoresub');

     my @users;

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_ignoresub: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_ignoresub: no user');
	 $param->{'previous_action'} = 'modindex';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_ignoresub: %s not owner', $param->{'user'}{'email'});
	 return 'admin';
     }

     foreach my $pair (split /\0/, $in{'email'}) {
	 if ($pair =~ /,/) {
	     push @users, $`;
	 }
     }

     foreach my $u (@users) {
	 $list->delete_subscription_request($u);
     }

     return 'subindex';
 }

 sub do_change_identity {
     &wwslog('info', 'do_change_identity(%s)', $in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &error_message('no_user');
	 &wwslog('info','do_change_identity: no user');
	 return $in{'previous_action'};
     }

     unless ($in{'email'}) {
	 &error_message('no_email');
	 &wwslog('info','do_change_identity: no email');
	 return $in{'previous_action'};
     }

     unless (&tools::valid_email($in{'email'})) {
	 &error_message('incorrect_email', {'email' => $in{'email'}});
	 &wwslog('info','do_change_identity: incorrect email %s', $in{'email'});
	 return $in{'previous_action'};
     }

     unless ($param->{'alt_emails'}{$in{'email'}}) {
	 &error_message('may_not');
	 &wwslog('info','do_change_identity: may not change email address');
	 return $in{'previous_action'};
     }

     $param->{'user'}{'email'} = $in{'email'};
     $param->{'auth'} = $param->{'alt_emails'}{$in{'email'}};

     return $in{'previous_action'};
 }

 sub do_stats {
     &wwslog('info', 'do_stats');

     unless ($param->{'list'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_stats: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &error_message('missing_arg', {'argument' => 'list'});
	 &wwslog('info','do_stats: no user');
	 $param->{'previous_action'} = 'stats';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	 &error_message('may_not');
	 &wwslog('info','do_stats: %s not owner', $param->{'user'}{'email'});
	 return 'admin';
     }

     $param->{'shared_size'} = int (($list->get_shared_size + 512)/1024);
     $param->{'arc_size'} = int (($list->get_arc_size($wwsconf->{'arc_path'}) + 512)/1024);

     return 1;
 }


 ## setting the topics list for templates
 sub export_topics {

     my $robot = shift; 
     do_log ('debug2',"export_topics($robot)");
     my %topics = &List::load_topics($robot);

     unless (defined %topics) {
	 &wwslog('err','No topics defined');
	 return undef;
     }

     my $total = 0;
     foreach my $t (sort {$topics{$a}{'order'} <=> $topics{$b}{'order'}} keys %topics) {
	 next unless (&List::request_action ('topics_visibility', $param->{'auth_method'},$robot,
					     {'topicname' => $t, 
					      'sender' => $param->{'user'}{'email'},
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/);

	 my $current = $topics{$t};
	 $current->{'id'} = $t;

	 ## For compatibility reasons
	 $current->{'mod'} = $total % 3;
	 $current->{'mod2'} = $total % 2;

	 push @{$param->{'topics'}}, $current;

	 $total++;
     }

     push @{$param->{'topics'}}, {'id' => 'topicsless',
				  'mod' => $total,
				  'sub' => {}
			      };

     $param->{'topics'}[int($total / 2)]{'next'} = 1;
 }


 ## Subscribers' list
 sub do_dump {
     &do_log('info', "do_dump($param->{'list'})");

     ## Whatever the action return, it must never send a complex html page
     $param->{'bypass'} = 1;
     $param->{'content_type'} = "text/plain";
     $param->{'file'} = undef ; 

     unless ($param->{'list'}) {
	 # any error message must start with 'err_' in order to allow remote Sympa to catch it
	 &error_message('err_missing_arg_list');
	 &do_log('info','do_dump: no list');
	 return undef;
     }

     ## May dump is may review
     my $action = &List::request_action ('review',$param->{'auth_method'},$robot,
					 {'listname' => $param->{'list'},
					  'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});


     &do_log('info',"do_dump: request_action : $action");
     unless ($action =~ /do_it/) {
	 # any error message must start with 'err_' in order to allow remote Sympa to catch it
	 &error_message ('err_not_allowed');
	 &do_log('info','do_dump: may not review');
	 return undef;
     }
     my @listnames = $param->{'list'} ;
     &List::dump(@listnames);
     $param->{'file'} = "$list->{'dir'}/subscribers.db.dump";
     return 1;
 }


 ## retrurn a mailto according to spam protection parameter
 sub mailto {

     my $list = shift;
     my $email = shift;
     my $gecos = shift;

     my $local; 
     my $domain;

     ($local,$domain) = split ('@',$email);

     $gecos = $email unless ($gecos);

     if ($list->{'admin'}{'spam_protection'} eq 'none') {
	 return("<A HREF=\"mailto:$email\">$gecos</A>");
     }elsif($list->{'admin'}{'spam_protection'} eq 'javascript') {

	 my $return = "<SCRIPT language=JavaScript>
 <!--
 document.write(\"<A HREF=\" + \"mail\" + \"to:\" + \"$local\" + \"@\" + \"$domain\" + \">$gecos</A>\")
 // --></SCRIPT>";
	 return ($return);
     }elsif($list->{'admin'}{'spam_protection'} eq 'at') {
	 return ("$local AT $domain");
     }
 }

 ## View translation for a template
 sub do_translate {
     &do_log('info', "do_translate($in{'template'}, $in{'lang'})");

     my ($template, $lang) = ($in{'template'}, $in{'lang'});

     unless ($in{'template'}) {
	 &error_message('missing_arg', {'argument' => 'template'});
	 &wwslog('info','do_translate: no template');
	 return undef;
     }

     unless ($in{'lang'}) {
	 &error_message('missing_arg', {'argument' => 'lang'});
	 &wwslog('info','do_translate: no lang');
	 return undef;
     }

     $param->{'trans'} = &tools::load_translation($template, $lang, $robot);
     $param->{'lang'} = $lang;
     $param->{'template'} = $template;

     return 1; 
 }

 ## View a template for translation
 sub do_view_template {
     &do_log('info', "do_view_template($in{'template'}, $in{'lang'})");

     unless ($in{'template'}) {
	 &error_message('missing_arg', {'argument' => 'template'});
	 &wwslog('info','do_view_template: no template');
	 return undef;
     }

     unless ($in{'lang'}) {
	 &error_message('missing_arg', {'argument' => 'lang'});
	 &wwslog('info','do_view_template: no lang');
	 return undef;
     }

     my $src_file =  &tools::get_filename('etc', 'wws_templates/'.$in{template}.'.src', $robot);
     unless (open TPL, $src_file) {
	 do_log('err', 'Unable to open file %s: %s', $src_file, $!);
	 return undef;
     }

     my @tpl;
     while (<TPL>) {
	 push @tpl, &tools::escape_html($_);
     }
     close TPL;

     $param->{'tpl'} = \@tpl;

     return 1;
 }

 ## view logs stored in RDBMS
 ## this function as been writen in order to allow list owner and listmater to views logs
 ## of there robot or there is real problems with privacy policy and law in such services.
 ## 
 sub do_viewlogs {
     &do_log('info', 'do_viewlogs()');

     my $list = new List ($param->{'list'});

     unless ($param->{'is_listmaster'}) {
	 &error_message('may_not');
	 &wwslog('info','do_viewlogs may_not from %s in list %s', $param->{'user'}{'email'}, $param->{'list'});
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'viewlogs',$param->{'list'},$robot,'','may not');
	 return undef;
     }
     my @lines;
     my $select = ('list'=> $param->{'list'},'robot'=> $param->{'robot'});

     for (my $line = &List::get_first_db_log($select); $line; $line = &List::get_next_db_log()) {
	 # $line->{'date'} = &POSIX::strftime("%d %b %Y %H:%M:%S", $line->{'date'} );

	 push @lines, sprintf ('%s %8s %15s@%20s %20s %25s %5s %s %s %s',$line->{'date'},$line->{'process'},$line->{'list'},$line->{'robot'},$line->{'ip'},$line->{'email'},$line->{'auth'},$line->{'operation'}, $line->{'operation_arg'}, $line->{'status'}); 
     }
     $param->{'log_entries'} = \@lines;

     return 1;
 }

 ## Update translation for a template
 sub do_update_translation {
     &do_log('info', "do_update_translation($in{'template'}, $in{'lang'})");

     unless ($in{'template'}) {
	 &error_message('missing_arg', {'argument' => 'template'});
	 &wwslog('info','do_update_translation: no template');
	 return undef;
     }

     unless ($in{'lang'}) {
	 &error_message('missing_arg', {'argument' => 'lang'});
	 &wwslog('info','do_update_translation: no lang');
	 return undef;
     }

     ## Load full index
     my $index_file =  &tools::get_filename('etc', "wws_templates/index.$in{'lang'}", $robot);
     my $index;
     unless ($index = &tools::load_index($in{'lang'}, $index_file)) {
	 &error_message('failed');
	 &wwslog('info','do_update_translation: failed to load full index');
	 return undef;		
     }

     ## Update index with incoming values
     foreach my $var (keys %in) {
	 if ($var =~ /^trans(\d+)$/) {
	     $index->{$in{'template'}}{$1} = $in{$var};
	 }
     }

     ## Save updated index
     my $index_file;
     if ($robot ne $Conf{'domain'}) {
	 $index_file = "$Conf{'etc'}/$robot/wws_templates/index.$in{'lang'}";
     }else {
	 $index_file = "$Conf{'etc'}/wws_templates/index.$in{'lang'}";
     }

     unless (&tools::save_index($in{'lang'}, $index_file, $index)) {
	 &error_message('failed');
	 &wwslog('info','do_update_translation: failed to save index');
	 return undef;	
     }

     return 1;
 }

sub do_arc_manage {
    &wwslog('info', "do_arc_manage ($in{'list'})");

    my $search_base = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}";
    opendir ARC, "$search_base";
    foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) {
	if ($dir =~ /^(\d{4})-(\d{2})$/) {
	    push @{$param->{'yyyymm'}}, $dir;
	}
    }
    closedir ARC;
    
    return 1;
}

## create a zip file with archives from (list,month)
sub do_arc_download {
    
    &wwslog('info', "do_arc_download ($in{'list'})");
    
    ##check if zip module has been installed
    unless($zip_is_installed) {
	&error_message('service_unavailable');
	&wwslog('info','service unavailable because zip CPAN module is not installed');
	return undef;
    }

    ##check access rights
    unless($param->{'is_owner'} || $param->{'is_listmaster'}) {
	&error_message('may_not');
	&wwslog('info','do_arc_download : not listmaster or list owner');
	return undef;
    }
    
    ##zip file name:listname_archives.zip  
    my $zip_file_name = $in{'list'}.'_archives.zip';
    my $zip_abs_file = $Conf{'tmpdir'}.'/'.$zip_file_name;
    my $zip = Archive::Zip->new();
    
    #Search for months to put in zip
    unless (defined($in{'directories'})) {
	&error_message('select_month');
	&wwslog('info','do_arc_download : no archives specified');
	return 'arc_manage';
    }
    
    #for each selected month
    foreach my $dir (split/\0/, $in{'directories'}) {
	my $abs_dir = ($wwsconf->{'arc_path'}.'/'.$in{'list'}.'@'.$param->{'host'}.'/'.$dir.'/arctxt');
	##check arc directory
	unless (-d $abs_dir) {
	    &error_message('month_not_found');
	    &wwslog('info','archive %s not found',$dir);
	    next;
	}
	## create and fill a new folder in zip
	$zip->addTree ($abs_dir, $in{'list'}.'_'.$dir);                           
    }
    
    ## check if zip isn't empty
    if ($zip->numberOfMembers()== 0) {                      
	&error_message('month_not_found');                   
	&wwslog('info','Error : empty directories');
	return undef;
    }   
    ##writing zip file
    unless ($zip->writeToFileNamed($zip_abs_file) == AZ_OK){
	&error_message('internal_error');
	&wwslog ('info', 'Error while writing Zip File %s\n',$zip_file_name);
	return undef;
    }

    ##Sending Zip to browser
    $param->{'bypass'} ='extreme';
    printf("Content-Type: application/zip;\nContent-disposition: filename=\"%s\";\n\n",$zip_file_name);
    ##MIME Header
    unless (open (ZIP,$zip_abs_file)) {
	&error_message('internal_error');
	&wwslog ('info', 'Error while reading Zip File %s\n',$zip_file_name);
	return undef;
    }
    while (<ZIP>) {
	printf $_;
    }
    close ZIP ;
    
    ## remove zip file from server disk
    unless (unlink ($zip_abs_file)){     
	&error_message('internal_error');
	&wwslog ('info', 'Error while unlinking File %s\n',$zip_abs_file);
    }
    
    return 1;
}

sub do_arc_delete {
  
    my @abs_dirs;
    
    &wwslog('info', "do_arc_delete ($in{'list'})");
    
    unless (defined  $in{'directories'}){
      	&error_message('month_not_found');
	&wwslog('info','No Archives months selected');
	return 'arc_manage';
    }
    
    ## if user want to download archives before delete
    &wwslog('notice', "ZIP: $in{'zip'}");
    if ($in{'zip'} == 1) {
	&do_arc_download();
    }
  
    
    foreach my $dir (split/\0/, $in{'directories'}) {
	push(@abs_dirs ,$wwsconf->{'arc_path'}.'/'.$in{'list'}.'@'.$param->{'host'}.'/'.$dir);
    }

    unless (tools::remove_dir(@abs_dirs)) {
	&wwslog('info','Error while Calling tools::remove_dir');
    }
    
    &message('performed');
    return 'arc_manage';
}
		


