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

use Log;
use Language;
use wwslib;
use CAS;

require Exporter;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(%Conf);

my @valid_options = qw(
		       avg bounce_warn_rate bounce_halt_rate chk_cert_expiration_task expire_bounce_task
		       clean_delay_queue clean_delay_queueauth clean_delay_queuemod 
		       cookie cookie_cas_expire create_list crl_dir crl_update_task db_host db_env db_name 
		       db_options db_passwd db_type db_user db_port db_additional_subscriber_fields db_additional_user_fields
		       default_shared_quota default_archive_quota default_list_priority edit_list email etc
		       global_remind home host domain lang listmaster log_socket_type log_level 
		       misaddressed_commands misaddressed_commands_regexp max_size maxsmtp msgcat nrcpt 
		       owner_priority pidfile spool queue queueauth queuetask queuebounce queuedigest 
		       queueexpire queuemod queuesubscribe queueoutgoing tmpdir
		       loop_command_max loop_command_sampling_delay loop_command_decrease_factor
		       purge_user_table_task  purge_orphan_bounces_task eval_bouncers_task process_bouncers_task
		       minimum_bouncing_count minimum_bouncing_period bounce_delay 
		       default_bounce_level1_rate default_bounce_level2_rate 
		       remind_return_path request_priority rfc2369_header_fields sendmail sendmail_args sleep 
		       sort sympa_priority syslog log_smtp umask welcome_return_path wwsympa_url
                       openssl capath cafile  key_passwd ssl_cert_dir remove_headers
		       antivirus_path antivirus_args antivirus_notify anonymous_header_fields
		       dark_color light_color text_color bg_color error_color selected_color shaded_color
		       ldap_export_name ldap_export_host ldap_export_suffix ldap_export_password
		       ldap_export_dnmanager ldap_export_connection_timeout
		       list_check_smtp list_check_suffixes  spam_protection web_archive_spam_protection soap_url
);

my %old_options = ('trusted_ca_options' => 'capath,cafile');

my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %Default_Conf = 
    ('home'    => '--EXPL_DIR--',
     'etc'     => '--ETCDIR--',
     'key_passwd' => '',
     'ssl_cert_dir' => '--EXPL_DIR--/X509-user-certs',
     'crl_dir' => '--EXPL_DIR--/crl',
     'umask'   => '027',
     'syslog'  => 'LOCAL1',
     'log_level'  => 0,
     'nrcpt'   => 25,
     'avg'     => 10,
     'maxsmtp' => 20,
     'sendmail'=> '/usr/sbin/sendmail',
     'sendmail_args' => '-oi -odi -oem',
     'openssl' => '',
     'host'    => undef,
     'domain'  => undef,
     'email'   => 'sympa',
     'pidfile' => '--PIDDIR--/sympa.pid',
     'msgcat'  => '--NLSDIR--',
     'sort'    => 'fr,ca,be,ch,uk,edu,*,com',
     'spool'   => '--SPOOLDIR--',
     'queue'   => undef,
     'queuedigest'=> undef,
     'queuemod'   => undef,
     'queueexpire'=> undef,
     'queueauth'  => undef,
     'queueoutgoing'  => undef,
     'queuebounce'  => undef,    
     'queuetask' => undef,
     'queuesubscribe' => undef,
     'tmpdir'  => undef,     
     'sleep'      => 5,
     'clean_delay_queue'    => 1,
     'clean_delay_queuemod' => 10,
     'clean_delay_queueauth' => 3,
     'log_socket_type'      => 'unix',
     'log_smtp'      => '',
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
     'db_additional_subscriber_fields' => '',
     'db_additional_user_fields' => '',
     'listmaster' => undef,
     'default_list_priority' => 5,
     'sympa_priority' => 1,
     'request_priority' => 0,
     'owner_priority' => 9,
     'lang' => 'us',
     'misaddressed_commands' => 'reject',
     'misaddressed_commands_regexp' => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))',
     'max_size' => 5242880,
     'edit_list' => 'owner',
     'create_list' => 'public_listmaster',
     'global_remind' => 'listmaster',
     'wwsympa_url' => undef,
     'bounce_warn_rate' => '30',
     'bounce_halt_rate' => '50',
     'cookie' => undef,
     'cookie_cas_expire' => '6',
     'loop_command_max' => 200,
     'loop_command_sampling_delay' => 3600,
     'loop_command_decrease_factor' => 0.5,
     'rfc2369_header_fields' => 'help,subscribe,unsubscribe,post,owner,archive',
     'remove_headers' => 'Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To',
     'antivirus_path' => '',
     'antivirus_args' => '',
     'antivirus_notify' => 'sender',
     'anonymous_header_fields' => 'Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender',
     'dark_color' => '#330099',
     'light_color' => '#ccccff',
     'text_color' => '#000000',
     'bg_color' => '#ffffff',
     'error_color' => '#ff6666',
     'selected_color' => '#3366cc',
     'shaded_color' => '#eeeeee',
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
     'soap_url' => ''
     );
   
my $wwsconf;
%Conf = ();

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
	    printf STDERR Msg(1, 3, "Malformed line %d in %s: %s"), $line_num, $config, $_;
	    $config_err++;
	}
    }
    close(IN);

    ## Defaults
    unless (defined $o{'wwsympa_url'}) {
	$o{'wwsympa_url'}[0] = "http://$o{'host'}[0]/wws";
    }

    # 'host' and 'domain' are mandatory and synonime.$Conf{'host'} is
    # still wydly use even if the doc require domain.
 
    $o{'host'} = $o{'domain'} if (defined $o{'domain'}) ;
    $o{'domain'} = $o{'host'} if (defined $o{'host'}) ;
    
    unless ( (defined $o{'cafile'}) || (defined $o{'capath'} )) {
	$o{'cafile'} = '--ETCBINDIR--/ca-bundle.crt';
    }   
    my $spool = $o{'spool'}[0] || $Default_Conf{'spool'};

    unless (defined $o{'queuedigest'}) {
	$o{'queuedigest'}[0] = "$spool/digest";
    }
    unless (defined $o{'queuemod'}) {
	$o{'queuemod'}[0] = "$spool/moderation";
    }
    unless (defined $o{'queueexpire'}) {
	$o{'queueexpire'}[0] = "$spool/expire";
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
	if ($old_options{$i}) {
	    printf STDERR  "Line %d of sympa.conf, parameter %s is no more available, read documentation for new parameter(s) %s\n", $o{$i}[1], $i, $old_options{$i};
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

    
    my @array = &_load_auth();
    $Conf{'auth_services'} = [@array];

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

    if ($Conf{'rfc2369_header_fields'} eq 'none') {
	delete $Conf{'rfc2369_header_fields'};
    }else {
	$Conf{'rfc2369_header_fields'} = [split(/,/, $Conf{'rfc2369_header_fields'})];
    }

    if ($Conf{'anonymous_header_fields'} eq 'none') {
	delete $Conf{'anonymous_header_fields'};
    }else {
	$Conf{'anonymous_header_fields'} = [split(/,/, $Conf{'anonymous_header_fields'})];
    }

    if ($Conf{'remove_headers'} eq 'none') {
	delete $Conf{'remove_headers'};
    }else {
	$Conf{'remove_headers'} = [split(/,/, $Conf{'remove_headers'})];
    }

    if ($Conf{'db_env'}) {
	my @raw = split /;/, $Conf{'db_env'};
	my %cooked;
	foreach my $env (@raw) {
	    next unless ($env =~ /^\s*(\w+)\s*\=\s*(\S+)\s*$/);
	    $cooked{$1} = $2;
	}
	$Conf{'db_env'} = \%cooked;
    }

    @{$Conf{'listmasters'}} = split(/,/, $Conf{'listmaster'});

    ## Set Regexp for accepted list suffixes
    if (defined ($Conf{'list_check_suffixes'})) {
	$Conf{'list_check_regexp'} = $Conf{'list_check_suffixes'};
	$Conf{'list_check_regexp'} =~ s/,/\|/g;
    }

    $Conf{'sympa'} = "$Conf{'email'}\@$Conf{'host'}";
    $Conf{'request'} = "$Conf{'email'}-request\@$Conf{'host'}";
    
    my $robots_conf = &load_robots ;
    
    $Conf{'robots'} = $robots_conf ;
    return 1;
}

## load each virtual robots configuration files
sub load_robots {
    
    my %robot_conf ;
    my %valid_robot_key_words = ( 'http_host'     => 1, 
				  listmaster      => 1,
				  email           => 1,
				  host            => 1,
				  wwsympa_url     => 1,
				  'title'         => 1,
				  lang            => 1,
				  default_home    => 1,
				  cookie_domain   => 1,
				  log_smtp        => 1,
				  log_level       => 1,
				  create_list     => 1,
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
				  soap_url => 1,
				  );

    ## Load wwsympa.conf
    unless ($wwsconf = &wwslib::load_config('--WWSCONFIG--')) {
	print STDERR "Unable to load config file --WWSCONFIG--\n";
    }

    unless (opendir DIR,$Conf{'etc'} ) {
	printf STDERR "Unable to open directory $Conf{'etc'} for virtual robots config\n" ;
	return undef;
    }

    foreach $robot (readdir(DIR)) {
	next unless (-d "$Conf{'etc'}/$robot");
	next unless (-r "$Conf{'etc'}/$robot/robot.conf");
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
		$value = lc($value) unless ($keyword eq 'title');
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
	@{$robot_conf->{$robot}{'listmasters'}} = split(/,/, $robot_conf->{$robot}{'listmaster'})
	    if $robot_conf->{$robot}{'listmaster'};

	## Default for 'host' is the domain
	$robot_conf->{$robot}{'host'} ||= $robot;

	$robot_conf->{$robot}{'title'} ||= $wwsconf->{'title'};
	$robot_conf->{$robot}{'default_home'} ||= $wwsconf->{'default_home'};

	$robot_conf->{$robot}{'lang'} ||= $Conf{'lang'};
	$robot_conf->{$robot}{'email'} ||= $Conf{'email'};
	$robot_conf->{$robot}{'log_smtp'} ||= $Conf{'log_smtp'};
	$robot_conf->{$robot}{'log_level'} ||= $Conf{'log_level'};
	$robot_conf->{$robot}{'wwsympa_url'} ||= 'http://'.$robot_conf->{$robot}{'http_host'}.'/wws';
	$robot_conf->{$robot}{'sympa'} = $robot_conf->{$robot}{'email'}.'@'.$robot_conf->{$robot}{'host'};
	$robot_conf->{$robot}{'request'} = $robot_conf->{$robot}{'email'}.'-request@'.$robot_conf->{$robot}{'host'};
	$robot_conf->{$robot}{'cookie_domain'} ||= 'localhost';
	#$robot_conf->{$robot}{'soap_url'} ||= $Conf{'soap_url'};

	my ($host, $path);
	if ($robot_conf->{$robot}{'http_host'} =~ /^([^\/]+)(\/.*)$/) {
	    ($host, $path) = ($1,$2);
	}else {
	    ($host, $path) = ($robot_conf->{$robot}{'http_host'}, '/');
	}
	$Conf{'robot_by_http_host'}{$host}{$path} = $robot ;
	
	## Create a hash to deduce robot from SOAP url
	if ($robot_conf->{$robot}{'soap_url'}) {
	    my $url = $robot_conf->{$robot}{'soap_url'};
	    $url =~ s/^http(s)?:\/\/(.+)$/$2/;
	    $Conf{'robot_by_soap_url'}{$url} = $robot;
	}

	close (ROBOT_CONF);
    }
    closedir(DIR);

    ## Add default robot conf
    ## Missing parameters from wwsympa.conf !!!
    foreach my $key (keys %valid_robot_key_words) {
	#if (! defined $Conf{$key}) {
	#    printf STDERR "OOps: %s\n", $key;
	#    next;
	#}
	$robot_conf->{$Conf{'domain'}}{$key} = $Conf{$key};
    }
    
    ## Default SOAP URL corresponds to default robot
    if ($Conf{'soap_url'}) {
	my $url = $Conf{'soap_url'};
	$url =~ s/^http(s)?:\/\/(.+)$/$2/;
	$Conf{'robot_by_soap_url'}{$url} = $Conf{'domain'};
    }

    return ($robot_conf);
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
    
    foreach my $qdir ('spool','queue','queuedigest','queuemod','queueexpire','queueauth','queueoutgoing','queuebounce','queuesubscribe','queuetask','tmpdir')
    {
	unless (-d $Conf{$qdir}) {
	    do_log('info', "creating spool $Conf{$qdir}");
	    unless ( mkdir ($Conf{$qdir}, 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{$qdir});
		$config_err++;
	    }
	}
    }

    ## Also create msg/bad/
    unless (-d $Conf{'queue'}.'/bad') {
	    do_log('info', "creating spool $Conf{'queue'}/bad");
	    unless ( mkdir ($Conf{'queue'}.'/bad', 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{'queue'}.'/bad');
		$config_err++;
	    }
	}

    return undef if ($config_err);
    return 1;
}

## Loads and parses the authentication configuration file.
##########################################

sub _load_auth {
    
    my $config;
    unless ($config = &tools::get_filename('etc', 'auth.conf', $Conf{'domain'})) {
	do_log('err',"_load_auth: Unable to find auth.conf");
	return undef;
    }

    my $line_num = 0;
    my $config_err = 0;
    my @paragraphs;
    my %result;
    my $current_paragraph ;

    my %valid_keywords = ('ldap' => {'regexp' => '.*',
				     'negative_regexp' => '.*',
				     'host' => '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*',
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
				    'ldap_host' => '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*',
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
					    'email_http_header' => '\w+'
					    }
			  );
    


    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	do_log('notice',"_load_auth: Unable to open %s: %s", $config, $!);
	return undef;
    }
    
    $Conf{'cas_number'} = 0;
    $Conf{'generic_sso_number'} = 0;
    $Conf{'ldap_number'} = 0;
    $Conf{'use_passwd'} = 0;
    
    ## Parsing  auth.conf
    while (<IN>) {

	$line_num++;
	next if (/^\s*[\#\;]/o);		

	if (/^\s*(ldap|cas|user_table|generic_sso)\s*$/io) {
	    $current_paragraph->{'auth_type'} = lc($1);
	}elsif (/^\s*(\S+)\s+(.*\S)\s*$/o){
	    my ($keyword,$value) = ($1,$2);
	    unless (defined $valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}) {
		do_log('notice',"_load_auth: unknown keyword '%s' in %s line %d", $keyword, $config, $line_num);
		next;
	    }
	    unless ($value =~ /^$valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}$/) {
		do_log('notice',"_load_auth: unknown format '%s' for keyword '%s' in %s line %d", $value, $keyword, $config,$line_num);
		next;
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

		    my %cas_param = (casUrl => $current_paragraph->{'base_url'});

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
		    
		    $current_paragraph->{'cas_server'} = new CAS(%cas_param);
		    unless (defined $current_paragraph->{'cas_server'}) {
			&do_log('err', 'Failed to create CAS object for %s : %s', 
				$current_paragraph->{'base_url'}, &CAS::get_errors());
			next;
		    }

		    $Conf{'cas_number'}  ++ ;
		    $Conf{'cas_id'}{$current_paragraph->{'auth_service_name'}} =  $#paragraphs+1 ; 
		}elsif($current_paragraph->{'auth_type'} eq 'generic_sso') {
		    $Conf{'generic_sso_number'}  ++ ;
		    $Conf{'generic_sso_id'}{$current_paragraph->{'service_id'}} =  $#paragraphs+1 ; 
		}elsif($current_paragraph->{'auth_type'} eq 'ldap') {
		    $Conf{'ldap'}  ++ ;
		    $Conf{'use_passwd'} = 1;
		}elsif($current_paragraph->{'auth_type'} eq 'user_table') {
		    $Conf{'use_passwd'} = 1;
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

    return @paragraphs;
    
}

## returns a robot conf parameter
sub get_robot_conf {
    my ($robot, $param) = @_;

    if (defined $Conf{'robots'}{$robot} && defined $Conf{'robots'}{$robot}{$param}) {
	return $Conf{'robots'}{$robot}{$param};
    }
    
    ## default
    return $Conf{$param} || $wwsconf->{$param};
}

## Packages must return true.
1;
