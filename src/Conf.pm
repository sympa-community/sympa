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

my @valid_options = qw(
		       allow_subscribe_if_pending avg alias_manager bounce_warn_rate bounce_halt_rate bounce_email_prefix chk_cert_expiration_task expire_bounce_task
		       cache_list_config
		       clean_delay_queue clean_delay_queueauth clean_delay_queuemod clean_delay_queuesubscribe clean_delay_queueautomatic clean_delay_queuetopic clean_delay_queuebounce clean_delay_queueoutgoing clean_delay_tmpdir default_remind_task
		       cookie cookie_cas_expire create_list automatic_list_feature automatic_list_creation automatic_list_removal crl_dir crl_update_task db_host db_env db_name db_timeout
		       db_options db_passwd db_type db_user db_port db_additional_subscriber_fields db_additional_user_fields
		       default_shared_quota default_archive_quota default_list_priority distribution_mode edit_list email etc
		       global_remind home host ignore_x_no_archive_header_feature domain lang listmaster listmaster_email localedir log_socket_type log_level
		       logo_html_definition 
                       main_menu_custom_button_1_title main_menu_custom_button_1_url main_menu_custom_button_1_target 
                       main_menu_custom_button_2_title main_menu_custom_button_2_url main_menu_custom_button_2_target 
                       main_menu_custom_button_3_title main_menu_custom_button_3_url main_menu_custom_button_3_target  
                       misaddressed_commands misaddressed_commands_regexp max_size maxsmtp nrcpt 
		       owner_priority pidfile pidfile_distribute pidfile_creation
		       spool queue queuedistribute queueauth queuetask queuebounce queuedigest queueautomatic
		       queuemod queuetopic queuesubscribe queueoutgoing tmpdir logs_expiration_period lock_method
		       loop_command_max loop_command_sampling_delay loop_command_decrease_factor loop_prevention_regex
		       purge_user_table_task purge_logs_table_task 
		       purge_session_table_task session_table_ttl anonymous_session_table_ttl 
                       purge_one_time_ticket_table_task one_time_ticket_table_ttl
                       purge_orphan_bounces_task eval_bouncers_task process_bouncers_task
		       minimum_bouncing_count minimum_bouncing_period bounce_delay 
		       default_bounce_level1_rate default_bounce_level2_rate 
		       remind_return_path request_priority return_path_suffix rfc2369_header_fields sendmail sendmail_args sleep 
		       sort sympa_priority supported_lang syslog log_smtp log_module log_condition umask verp_rate welcome_return_path wwsympa_url
                       openssl capath cafile  key_passwd ssl_cert_dir remove_headers remove_outgoing_headers
		       antivirus_path antivirus_args antivirus_notify anonymous_header_fields sendmail_aliases
		       dark_color light_color text_color bg_color error_color selected_color shaded_color
		       color_0 color_1 color_2 color_3 color_4 color_5 color_6 color_7 color_8 color_9 color_10 color_11 color_12 color_13 color_14 color_15
 		       css_url css_path static_content_path static_content_url pictures_max_size pictures_feature
		       ldap_export_name ldap_export_host ldap_export_suffix ldap_export_password
		       ldap_export_dnmanager ldap_export_connection_timeout update_db_field_types urlize_min_size
		       list_check_smtp list_check_suffixes filesystem_encoding spam_protection web_archive_spam_protection soap_url
		       use_blacklist 
		       antispam_feature antispam_tag_header_name antispam_tag_header_spam_regexp antispam_tag_header_ham_regexp
);

my %old_options = ('trusted_ca_options' => 'capath,cafile',
		   'msgcat' => 'localedir',
		   'queueexpire' => '',
		   'clean_delay_queueother' => '',
		   'web_recode_to' => 'filesystem_encoding',
		   );
## These parameters now have a hard-coded value
## Customized value can be accessed though as %Ignored_Conf
my %Ignored_Conf;
my %hardcoded_options = ('filesystem_encoding' => 'utf8');

my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %Default_Conf = 
    ('home'    => '--EXPL_DIR--',
     'etc'     => '--ETCDIR--',
     'key_passwd' => '',
     'ssl_cert_dir' => '--EXPL_DIR--/X509-user-certs',
     'crl_dir' => '--EXPL_DIR--/crl',
     'umask'   => '022',
     'syslog'  => 'LOCAL1',
     'log_level'  => 0,
     'nrcpt'   => 25,
     'allow_subscribe_if_pending' => 'on',
     'avg'     => 10,
     'maxsmtp' => 20,
     'sendmail'=> '/usr/sbin/sendmail',
     'sendmail_args' => '-oi -odi -oem',
     'sendmail_aliases' => '--SENDMAIL_ALIASES--',
     'openssl' => '',
     'host'    => undef,
     'domain'  => undef,
     'email'   => 'sympa',
     'pidfile' => '--PIDDIR--/sympa.pid',
     'pidfile_distribute' => '--PIDDIR--/sympa-distribute.pid',
     'pidfile_creation' => '--PIDDIR--/sympa-creation.pid',
     'localedir'  => '--LOCALEDIR--',
     'sort'    => 'fr,ca,be,ch,uk,edu,*,com',
     'spool'   => '--SPOOLDIR--',
     'queue'   => undef,
     'queuedistribute' => undef,
     'queueautomatic' => undef,
     'queuedigest'=> undef,
     'queuemod'   => undef,
     'queuetopic' => undef,
     'queueauth'  => undef,
     'queueoutgoing'  => undef,
     'queuebounce'  => undef,    
     'queuetask' => undef,
     'queuesubscribe' => undef,
     'tmpdir'  => undef,     
     'sleep'      => 5,
     'clean_delay_queue'    => 1,
     'clean_delay_queuemod' => 10,
     'clean_delay_queuetopic' => 7,
     'clean_delay_queuesubscribe' => 10,
     'clean_delay_queueautomatic' => 10,
     'clean_delay_queueauth' => 3,
     'clean_delay_queuebounce'   => 10,
     'clean_delay_queueoutgoing'   => 1,
     'clean_delay_tmpdir'   => 7,
     'log_socket_type'      => 'unix',
     'log_smtp'      => '',
     'log_module'      => '',
     'log_condition'      => '',
     'remind_return_path' => 'owner',
     'welcome_return_path' => 'owner',
     'db_type' => '',
     'db_name' => '',
     'db_host' => '',
     'db_user' => '', 
     'db_passwd'  => '',
     'db_options' => '',
     'db_env' => '',
     'db_port' => '',
     'db_timeout' => '',
     'db_additional_subscriber_fields' => '',
     'db_additional_user_fields' => '',
     'distribution_mode' => 'single',
     'listmaster' => undef,
     'listmaster_email' => 'listmaster',
     'default_list_priority' => 5,
     'sympa_priority' => 1,
     'request_priority' => 0,
     'owner_priority' => 9,
     'lang' => 'en_US',
     'misaddressed_commands' => 'reject',
     'misaddressed_commands_regexp' => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))',
     'max_size' => 5242880,
     'edit_list' => 'owner',
     'create_list' => 'public_listmaster',
     'automatic_list_feature' => 'off',
     'automatic_list_creation' => 'public',
     'automatic_list_removal' => '', ## Can be 'if_empty'
     'global_remind' => 'listmaster',
     'wwsympa_url' => undef,
     'bounce_warn_rate' => '30',
     'bounce_halt_rate' => '50',
     'bounce_email_prefix' => 'bounce',
     'cookie' => undef,
     'cookie_cas_expire' => '6',
     'loop_command_max' => 200,
     'loop_command_sampling_delay' => 3600,
     'loop_command_decrease_factor' => 0.5,
     'loop_prevention_regex' => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
     'rfc2369_header_fields' => 'help,subscribe,unsubscribe,post,owner,archive',
     'remove_headers' => 'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To',
     'remove_outgoing_headers' => 'none',
     'antivirus_path' => '',
     'antivirus_args' => '',
     'antivirus_notify' => 'sender',
     'anonymous_header_fields' => 'Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender',
     'dark_color' => 'silver',
     'light_color' => '#aaddff',
     'text_color' => '#000000',
     'bg_color' => '#ffffcc',
     'error_color' => '#ff6666',
     'selected_color' => 'silver',
     'shaded_color' => '#66cccc',
     'color_0' => '#F0F0F0', # very light grey use in tables
     'color_1' => '#999', # main menu button color                       
     'color_2' => '#333', # font color                                   
     'color_3' => '#929292', # top boxe and footer box bacground color   
     'color_4' => 'silver', #  page backgound color                      
     'color_5' => '#fff', # ??                                           
     'color_6' => '#99ccff', # list menu current button                  
     'color_7' => '#ff99cc', # eroorbackground color,          
     'color_8' => '#3366CC', #                                           
     'color_9' => '#DEE7F7',
     'color_10' => '#777777', # inactive button
     'color_11' => '#3366CC', #                                          
     'color_12' => '#000',
     'color_13' => '#ffffcc',                                        # input backgound  | transparent
     'color_14' => '#000',
     'color_15' => '#000',
     'chk_cert_expiration_task' => '',
     'crl_update_task' => '',
     'ldap_export_name' => '',
     'ldap_export_host' => '',
     'ldap_export_suffix' => '',
     'ldap_export_password' => '',
     'ldap_export_dnmanager' => '',
     'ldap_export_connection_timeout' => '',
     'list_check_smtp' => '',
     'list_check_suffixes' => 'request,owner,editor,unsubscribe,subscribe',
     'expire_bounce_task' => 'daily',
     'purge_user_table_task' => 'monthly',
     'purge_logs_table_task' => 'daily',
     'logs_expiration_period' => 3, #3 months
     'purge_session_table_task' => 'daily',
     'session_table_ttl' => '2d', #
     'purge_one_time_ticket_table_task' => 'daily',
     'one_time_ticket_table_ttl' => '10d', #
     'anonymous_session_table_ttl' => '1h', #
     'purge_challenge_table_task' => 'daily',
     'challenge_table_ttl' => '5d', # 
     'purge_orphan_bounces_task' => 'monthly',
     'eval_bouncers_task' => 'daily',
     'process_bouncers_task' => 'weekly',
     'default_archive_quota' => '',
     'default_shared_quota' => '',
     'capath' => '',
     'cafile' => '',
     'spam_protection' => 'javascript',
     'web_archive_spam_protection' => 'cookie',
     'minimum_bouncing_count' => 10,
     'minimum_bouncing_period' => 10,
     'bounce_delay' => 0,
     'default_bounce_level1_rate' => 45,
     'default_bounce_level2_rate' => 75,
     'soap_url' => '',
     'css_url' => '', ## Defined below
     'css_path' => '',## Defined below
     'urlize_min_size' => 10240, ## 10Kb
     'supported_lang' => 'ca,cs,de,el,es,et_EE,en_US,fr,hu,it,ja_JP,ko,nl,oc,pt_BR,ru,sv,tr,zh_CN,zh_TW',
     'default_remind_task' => '',
     'update_db_field_types' => 'auto',
     'logo_html_definition' => '',
     'main_menu_custom_button_1_title' => '',
     'main_menu_custom_button_1_url' => '',
     'main_menu_custom_button_1_target' => '',
     'main_menu_custom_button_2_title' => '',
     'main_menu_custom_button_2_url' => '',
     'main_menu_custom_button_2_target' => '',
     'main_menu_custom_button_3_title' => '',
     'main_menu_custom_button_3_url' => '',
     'main_menu_custom_button_3_target' => '',
     'return_path_suffix' => '-owner',
     'verp_rate' => '0%', 
     'pictures_max_size' => 102400, ## 100Kb
     'pictures_feature' => 'on',
     'use_blacklist' => 'send,subscribe',
     'static_content_url' => '/static-sympa',
     'static_content_path' => '--DIR--/static_content',
     'filesystem_encoding' => 'utf-8',
     'cache_list_config' => 'none', ## none | binary_file
     'lock_method' => 'flock', ## flock | nfs
     'ignore_x_no_archive_header_feature' => 'off',
     'alias_manager' => '--SBINDIR--/alias_manager.pl',
     'antispam_feature' => 'off',
     'antispam_tag_header_name' => 'X-Spam-Status',
     'antispam_tag_header_spam_regexp' => '^\s*Yes',
     'antispam_tag_header_ham_regexp' => '^\s*No'
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
	next if (/^\s*$/o || /^[\#\;]/o);
#	if (/^(\S+)\s+(\S+|\`.*\`)\s*$/io) {
	if (/^(\S+)\s+(.+)$/io) {
	    my($keyword, $value) = ($1, $2);
	    $value =~ s/\s*$//;
	    ##  'tri' is a synonime for 'sort' (for compatibily with old versions)
	    $keyword = 'sort' if ($keyword eq 'tri');
	    ##  'key_password' is a synonime for 'key_passwd' (for compatibily with old versions)
	    $keyword = 'key_passwd' if ($keyword eq 'key_password');
	    ## Special case: `command`
	    if ($value =~ /^\`(.*)\`$/) {
		$value = qx/$1/;
		chomp($value);
	    }
	    $o{$keyword} = [ $value, $line_num ];
	}else {
	    printf STDERR gettext("Error at line %d : %s"), $line_num, $config, $_;
	    $config_err++;
	}
    }
    close(IN);

    ## Hardcoded values
    foreach my $p (keys %hardcoded_options) {
	$Ignored_Conf{$p} = $o{$p}[0] if (defined $o{$p});
	$o{$p}[0] = $hardcoded_options{$p};
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
	$o{'cafile'}[0] = '--ETCBINDIR--/ca-bundle.crt';
    }   

    my $spool = $o{'spool'}[0] || $Default_Conf{'spool'};

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
	next if ($valid_options{$i});
	if (defined $old_options{$i}) {
	    if ($old_options{$i}) {
		printf STDERR  "Line %d of sympa.conf, parameter %s is no more available, read documentation for new parameter(s) %s\n", $o{$i}[1], $i, $old_options{$i};
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
    foreach $i (keys %valid_options) {
	unless (defined $o{$i} or defined $Default_Conf{$i}) {
	    printf "Required field not found in sympa.conf: %s\n", $i;
	    $config_err++;
	    next;
	}
	$Conf{$i} = $o{$i}[0] || $Default_Conf{$i};
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

    ## Load robot.conf files
    my $robots_conf = &load_robots ;    
    $Conf{'robots'} = $robots_conf ;

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

    #  open (TMP, ">> /tmp/dump1"); printf TMP "dump de la conf dans conf.pm\n" ; &tools::dump_var($Conf{'crawlers_detection'}, 0,\*TMP);     close TMP;

    $Conf{'pictures_url'}  = $Conf{'static_content_url'}.'/pictures/';
    $Conf{'pictures_path'}  = $Conf{'static_content_path'}.'/pictures/';
    
    return 1;
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
    my %valid_robot_key_words = ( 'http_host'     => 1,
				  'allow_subscribe_if_pending'   => 1,
				  listmaster      => 1,
				  email           => 1,
				  host            => 1,
				  wwsympa_url     => 1,
				  'title'         => 1,
				  logo_html_definition        => 1,
				  antispam_feature => 1,
				  antispam_tag_header_name => 1,
				  antispam_tag_header_spam_regexp => 1,
				  antispam_tag_header_ham_regexp => 1,
				  main_menu_custom_button_1_title => 1,
				  main_menu_custom_button_1_url => 1,
				  main_menu_custom_button_1_target => 1,
				  main_menu_custom_button_2_title => 1,
				  main_menu_custom_button_2_url => 1,
				  main_menu_custom_button_2_target => 1,
				  main_menu_custom_button_3_title => 1,
				  main_menu_custom_button_3_url => 1,
				  main_menu_custom_button_3_target => 1,
				  lang            => 1,
				  default_home    => 1,
				  cookie_domain   => 1,
				  log_smtp        => 1,
				  log_module    => 1,
				  log_condition    => 1,
				  log_level       => 1,
				  create_list     => 1,
				  automatic_list_feature     => 1,
				  automatic_list_creation     => 1,
				  automatic_list_removal     => 1,
				  dark_color      => 1,
				  light_color     => 1,
				  text_color      => 1, 
				  bg_color        => 1,
				  error_color     => 1,
				  selected_color  => 1,
				  shaded_color    => 1,
				  list_check_smtp => 1,
				  list_check_suffixes => 1,
				  spam_protection => 1,
				  web_archive_spam_protection => 1,
				  bounce_level1_rate => 1,
				  bounce_level2_rate => 1,
				  use_blacklist => 1,
				  soap_url => 1,
				  css_url => 1,
 				  css_path => 1,
				  static_content_path => 1,
                                  static_content_url => 1,
				  pictures_max_size => 1,
 				  color_0 => 1, color_1 => 1, color_2 => 1, color_3 => 1, color_4 => 1, color_5 => 1,color_6 => 1, 
				  color_7 => 1, color_8 => 1, color_9 => 1,
				  color_10 => 1, color_11 => 1, color_12 => 1,color_13 => 1, color_14 => 1, color_15 => 1,
				  supported_lang => 1,
				  default_shared_quota => 1,
				  verp_rate => 1,
				  loop_prevention_regex => 1,
				  max_size => 1,
				  );

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
	foreach my $p (@valid_options) {
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
		(stat('--ETCBINDIR--/web_tt2/css.tt2'))[9] > (stat($dir.'/'.$css))[9]) {
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
	$config = '--ETCBINDIR--/crawlers_detection.conf' unless (-f $config);
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
