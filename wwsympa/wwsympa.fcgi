#!--PERL-- -U

## Copyright 1999 Comité Réseaux des Universités
## web interface to Sympa mailing lists manager
## Sympa: http://listes.cru.fr/sympa/

## Authors :
##           Serge Aumont <sa@cru.fr>
##           Olivier Salaün <os@cru.fr>

## Change this to point to your Sympa bin directory
use lib '--BINDIR--';

use strict vars;

## Template parser
require "--BINDIR--/parser.pl";

## Sympa API
use List;
use mail;
use smtp;
use Conf;
use Commands;
use Language;
use Log;
use Getopt::Std;

use Mail::Header;
use Mail::Address;

#require "--BINDIR--/mail.pl";
require "--BINDIR--/msg.pl";
require "--BINDIR--/tools.pl";

## WWSympa librairies
use wwslib;
use cookielib;

## Configuration
my $wwsconf = {};

## Change to your wwsympa.conf location
my $conf_file = '--WWSCONFIG--';
my $sympa_conf_file = '--CONFIG--';

## Load config 
unless ($wwsconf = &wwslib::load_config($conf_file)) {
    &message('unable to load config file');
    return undef;
}

## Load sympa config
unless (&Conf::load( $sympa_conf_file )) {
    &message('config_error');
    &do_log('info','unable to load sympa config file');
    exit (-1);
}

&mail::set_send_spool($Conf{'queue'});

my $mime_types = &wwslib::load_mime_types();

if ($wwsconf->{'use_fast_cgi'}) {
    require CGI::Fast;
}else {
    require CGI;
}


my $loop = 0;
my $list;
my $param = {};


# hash of all the description files already loaded
# format :
#     $desc_files{pathfile}{'date'} : date of the last load
#     $desc_files{pathfile}{'desc_hash'} : hash which describes
#                         the description file

#%desc_files_map; NOT USED ANYMORE

# hash of the icons linked with a type of file
my %icon_table;

  # application file
$icon_table{'unknown'} = '/icons/unknown.gif';
$icon_table{'folder'} = '/icons/folder.gif';
$icon_table{'application'} = '/icons/unknown.gif';
$icon_table{'octet-stream'} = '/icons/binary.gif';
$icon_table{'audio'} = '/icons/sound1.gif';
$icon_table{'image'} = '/icons/image2.gif';
$icon_table{'text'} = '/icons/text.gif';
$icon_table{'video'} = '/icons/movie.gif';
$icon_table{'father'} = '/icons/small/back.gif';
$icon_table{'sort'} = '/icons/down.gif';
## Shared directory and description file

#$shared = 'shared';
#$desc = '.desc';

####{lefloch/modif/end}


## subroutines
my %comm = ('home' => 'do_home',
	 'logout' => 'do_logout',
	 'loginrequest' => 'do_loginrequest',
	 'login' => 'do_login',
	 'subscribe' => 'do_subscribe',
	 'subrequest' => 'do_subrequest',
	 'suboptions' => 'do_suboptions',
	 'signoff' => 'do_signoff',
	 'sigrequest' => 'do_sigrequest',
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
	 'remove_arc' => 'do_remove_arc',
	 'arcsearch_form' => 'do_arcsearch_form',
	 'arcsearch_id' => 'do_arcsearch_id',
	 'arcsearch' => 'do_arcsearch',
	 'rebuildarc' => 'do_rebuildarc',
	 'rebuildallarc' => 'do_rebuildallarc',
	 'serveradmin' => 'do_serveradmin',
	 'help' => 'do_help',
	 'edit_list_request' => 'do_edit_list_request',
	 'edit_list' => 'do_edit_list',
	 'create_list_request' => 'do_create_list_request',
	 'create_list' => 'do_create_list',
	 'get_pending_lists' => 'do_get_pending_lists', 
	 'set_pending_list_request' => 'do_set_pending_list_request', 
	 'install_pending_list' => 'do_install_pending_list', 
	 'submit_list' => 'do_submit_list',
	 'editsubscriber' => 'do_editsubscriber',
	 'viewbounce' => 'do_viewbounce',
	 'viewconfig' => 'do_viewconfig',
	 'reviewbouncing' => 'do_reviewbouncing',
	 'resetbounce' => 'do_resetbounce',
	 'scenario_test' => 'do_scenario_test',
	 'search_list' => 'do_search_list',
	 'show_cert' => 'show_cert',
	 'close_list_request' => 'do_close_list_request',
	 'close_list' => 'do_close_list',
	 'restore_list' => 'do_restore_list',
	 'd_read' => 'do_d_read',
	 'd_create_dir' => 'do_d_create_dir',
	 'd_upload' => 'do_d_upload',   
	 'd_editfile' => 'do_d_editfile',
	 'd_overwrite' => 'do_d_overwrite',
	 'd_savefile' => 'do_d_savefile',
	 'd_describe' => 'do_d_describe',
	 'd_delete' => 'do_d_delete',
	 'd_control' => 'do_d_control',
	 'd_change_access' => 'do_d_change_access',
	 'd_set_owner' => 'do_d_set_owner',
	 'd_admin' => 'do_d_admin',
	 'arc_protect' => 'do_arc_protect',
	 'view_translations' => 'do_view_translations',
	 'remind' => 'do_remind',
	 'change_email' => 'do_change_email',
	 'load_cert' => 'do_load_cert',
	 'compose_mail' => 'do_compose_mail',
	 'send_mail' => 'do_send_mail'
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
		'viewconfig' => ['list','email'],
		'resetbounce' => ['list','email'],
		'review' => ['list','page','size','sortby'],
		'reviewbouncing' => ['list','page','size'],
		'arc' => ['list','month','arc_file'],
		'arcsearch_form' => ['list','archive_name'],
		 'arcsearch_id' => ['list','archive_name','key_word'],
		'rebuildarc' => ['list','month'],
		'rebuildallarc' => [],
		'home' => [],
		'help' => ['help_topic'],
		'show_cert' => [],
		'subscribe' => ['list','email','passwd'],
		'subrequest' => ['list','email'],
		'subrequest' => ['list'],
		'signoff' => ['list','email','passwd'],
		'sigrequest' => ['list','email'],
		'set' => ['list','email','reception','gecos'],
		'serveradmin' => [],
		'get_pending_lists' => [],
		'search_list' => ['filter'],
		'shared' => ['list','@path'],
		'd_read' => ['list','@path'],
		'd_admin' => ['list','d_admin'],
		'd_delete' => ['list','@path'],
		'd_create_dir' => ['list','@path'],
		'd_overwrite' => ['list','@path'],
		'd_savefile' => ['list','@path'],
		'd_describe' => ['list','@path'],
		'd_editfile' => ['list','@path'],
		'd_control' => ['list','@path'],
		'd_change_access' =>  ['list','@path'],
		'd_set_owner' =>  ['list','@path'],
		'view_translations' => [],
		'search' => ['list','filter']
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
		'viewconfig' =>'admin',
		'resetbounce'  =>'admin',
		'scenario_test' =>'admin',
		'close_list_request' =>'admin',
		'close_list' =>'admin',
		'restore_list' => 'do_restore_list',
		'd_admin' => 'admin',
		'remind' => 'admin');

## Open log
$wwsconf->{'log_facility'}||= $Conf{'syslog'};

&Log::do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'wwsympa');
&do_log('info', 'WWSympa started');

## Set locale configuration
$Language::default_lang = $Conf{'lang'};
&Language::LoadLang($Conf{'msgcat'});

unless ($List::use_db = &List::probe_db()) {
    &message('no_database');
    &do_log('info','WWSympa requires a RDBMS to run');
}

my $pinfo = &List::_apply_defaults();

%::changed_params;

my (%in, $query);

## Main loop
while ($query = &new_loop()) {

    undef $param;
    undef $list;

    &Language::SetLang($Language::default_lang);

    ## Get params in a hash
    %in = $query->Vars;

    foreach my $k (keys %::changed_params) {
	&do_log('debug', 'Changed Param: %s', $k);
    }

    ## Free terminated sendmail processes
#    &smtp::reaper;

    ## Parse CGI parameters
#    &CGI::ReadParse();

    ## Get PATH_INFO parameters
    &get_parameters();

    ## Sympa parameters in $param->{'conf'}
    $param->{'conf'} = \%Conf;
    $param->{'wwsconf'} = $wwsconf;

    $param->{'path_cgi'} = $ENV{'SCRIPT_NAME'};
    $param->{'version'} = $Version::Version;
    $param->{'date'} = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));

    ## Change to list root
    unless (chdir($Conf{'home'})) {
	&message('chdir_error');
	&wwslog('info','unable to change directory');
	exit (-1);
    }

    ## Authentication 
    ## use https client certificat information if define.  
    if (($ENV{'SSL_CLIENT_S_DN_Email'}) && ($ENV{'SSL_CLIENT_VERIFY'} eq 'SUCCESS')) {
	$param->{'user'}{'email'} = lc($ENV{'SSL_CLIENT_S_DN_Email'});
	$param->{'auth_method'} = 'smime';
        $param->{'ssl_client_s_dn'} = $ENV{'SSL_CLIENT_S_DN'};
        $param->{'ssl_client_v_end'} = $ENV{'SSL_CLIENT_V_END'};
        $param->{'ssl_client_i_dn'} =  $ENV{'SSL_CLIENT_I_DN'};
        $param->{'ssl_cipher_usekeysize'} =  $ENV{'SSL_CIPHER_USEKEYSIZE'};



    }elsif ($ENV{'HTTP_COOKIE'} =~ /user\=/) {
	$param->{'user'}{'email'} = &wwslib::get_email_from_cookie($Conf{'cookie'});
	$param->{'auth_method'} = 'md5';
    }else{
	## request action need a auth_method even if the user is not authenticated ...
	$param->{'auth_method'} = 'md5';
    }

    if ($param->{'user'}{'email'}) {
	if (&List::is_user_db($param->{'user'}{'email'})) {
	    $param->{'user'} = &List::get_user_db($param->{'user'}{'email'});
	}
	
	## For the parser to display an empty field instead of [xxx]
	$param->{'user'}{'gecos'} ||= '';
	unless (defined $param->{'user'}{'cookie_delay'}) {
	    $param->{'user'}{'cookie_delay'} = $wwsconf->{'cookie_expire'};
	}
#	$param->{'user'}{'cookie_delay'} ||= $wwsconf->{'cookie_expire'};
#	$param->{'user'}{'init_passwd'} = 1 if ($param->{'user'}{'password'} =~ /^INIT/);
    }
    
    ## Action
    my $action = $in{'action'} ||  $wwsconf->{'default_home'};
#    $param->{'lang'} = $param->{'user'}{'lang'} || $Conf{'lang'};
    $param->{'remote_addr'} = $ENV{'REMOTE_ADDR'} ;
    $param->{'remote_host'} = $ENV{'REMOTE_HOST'};

    &List::init_list_cache();

    ## Session loop
    while ($action) {

	unless (&check_param_in()) {
	    &message('wrong_param');
	    &wwslog('info','Wrong parameters');
	    last;
	}

	$param->{'host'} = $list->{'admin'}{'host'} || $Conf{'host'};
	
	## language ( $ENV{'HTTP_ACCEPT_LANGUAGE'} not used !)
	    
	$param->{'lang'} = $param->{'user'}{'lang'} || $list->{'admin'}{'lang'} 
	|| $Conf{'lang'};
	&Language::SetLang($param->{'lang'});
	&POSIX::setlocale(&POSIX::LC_ALL, Msg(14, 1, 'en_US'));

	unless ($comm{$action}) {
	    &message('unknown_action');
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
	    undef $action;
	}
	
	undef $action if ($action == 1);
    }

    ## Prepare outgoing params
    &check_param_out();

    ## Params 
    $param->{'action_type'} = $action_type{$param->{'action'}};
    $param->{'action_type'} = 'none' unless ($param->{'is_priv'});

    if ($param->{'list'}) {
	$param->{'title'} = "$param->{'list'}\@$param->{'host'}";
    }else {
	$param->{'title'} = $wwsconf->{'title'};
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

	    &cookielib::set_cookie($param->{'user'}{'email'}, $Conf{'cookie'}, $wwsconf->{'cookie_domain'},$delay ) || exit;
	}elsif ($ENV{'HTTP_COOKIE'} =~ /user\=/){
	    &cookielib::set_cookie('unknown',$Conf{'cookie'}, $wwsconf->{'cookie_domain'}, 'now');
	}
    }

    # if bypass defined use file extention, if bypass = 'extrem' leave the action send the content-type
    if ($param->{'bypass'}) {
#	if ($param->{'bypass'} eq 'extreme') {
#	    do_log ('info',"extermmmmmmme xxxx");
#	    printf "Content-type: text/plain\n\n%s\n','bli bli';
#	}	
	unless ($param->{'bypass'} eq 'extreme') {
	    $mime_types->{$param->{'file_extension'}} ||= 'application/octet-stream';
	    
	    printf "Content-Type: %s\n\n", $mime_types->{$param->{'file_extension'}};
	    open (FILE, $param->{'file'});
	    print <FILE>;
	    close FILE;
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
	    foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates",
				"$Conf{'etc'}/wws_templates",
				"--ETCBINDIR--/wws_templates") {
		if (-f "$tpldir/$param->{'action'}.$param->{'lang'}.tpl") {
		    $param->{'action_template'} = "$tpldir/$param->{'action'}.$param->{'lang'}.tpl";
		    last;
		}
		if (-f "$tpldir/$param->{'action'}.tpl") {
		    $param->{'action_template'} = "$tpldir/$param->{'action'}.tpl";
		    last;
		}
	    }
	    unless ($param->{'action_template'})  {
		&message('template_error');
		&do_log('info',"unable to find template for $param->{'action'}");
	    }
	}

	## Menu template
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/menu.$param->{'lang'}.tpl"){
		$param->{'menu_template'} = "$tpldir/menu.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/menu.tpl"){
		$param->{'menu_template'} = "$tpldir/menu.tpl";
		last;
	    }
	}
	unless ($param->{'menu_template'})  {
	    &message('template_error');
	    &do_log('info','unable to find menu template');
	}

	## List_menu template
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/list_menu.$param->{'lang'}.tpl"){
		$param->{'list_menu_template'} = "$tpldir/list_menu.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/list_menu.tpl"){
		$param->{'list_menu_template'} = "$tpldir/list_menu.tpl";
		last;
	    }
	}
	unless ($param->{'list_menu_template'})  {
	    &message('template_error');
	    &do_log('info','unable to find list_menu template');
	}

	## admin_menu template
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/admin_menu.$param->{'lang'}.tpl"){
		$param->{'admin_menu_template'} = "$tpldir/admin_menu.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/admin_menu.tpl"){
		$param->{'admin_menu_template'} = "$tpldir/admin_menu.tpl";
		last;
	    }
	}
	unless ($param->{'admin_menu_template'})  {
	    &message('template_error');
	    &do_log('info','unable to find admin_menu template');
	}

	## Title template
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/title.$param->{'lang'}.tpl"){
		$param->{'title_template'} = "$tpldir/title.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/title.tpl"){
		$param->{'title_template'} = "$tpldir/title.tpl";
		last;
	    }
	}
	unless ($param->{'title_template'})  {
	    &message('template_error');
	    &do_log('info','unable to find title template');
	}

	## Error template
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/error.$param->{'lang'}.tpl"){
		$param->{'error_template'} = "$tpldir/error.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/error.tpl"){
		$param->{'error_template'} = "$tpldir/error.tpl";
		last;
	    }
	}
	unless ($param->{'error_template'})  {
	    &message('template_error');
	    &do_log('info','unable to find error template');
	}

	## Help template
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/help_$param->{'help_topic'}.$param->{'lang'}.tpl"){
		$param->{'help_template'} = "$tpldir/help_$param->{'help_topic'}.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/help_$param->{'help_topic'}.tpl"){
		$param->{'help_template'} = "$tpldir/help_$param->{'help_topic'}.tpl";
		last;
	    }
	}

	## main template
	my $main ;
        foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/main.$param->{'lang'}.tpl"){
		$main = "$tpldir/main.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/main.tpl"){
		$main = "$tpldir/main.tpl";
		last;
	    }
	}
	unless ($main)  {
	    &message('template_error');
	    &do_log('info','unable to find main template');
	}

	if (defined $list) {
	    $param->{'list_conf'} = $list->{'admin'};
	}

	&parse_tpl($param,$main , STDOUT);
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

    $msg = "[user $param->{'user'}{'email'}] " . $msg
	if $param->{'user'}{'email'};

    $msg = "[client $remote] ".$msg
	if $remote;
    
    return &Log::do_log($facility, $msg, @_);
}

## Return a message to the client
sub message {
    my ($msg, $data) = @_;
    
    $data ||= {};

    $data->{'action'} = $param->{'action'};
    $data->{'msg'} = $msg;

    push @{$param->{'errors'}}, $data;
    
    ## For compatibility
    $param->{'error_msg'} ||= $msg;

}

sub new_loop {
    $loop++;
    my $query;

    if ($wwsconf->{'use_fast_cgi'}) {
	$query = new CGI::Fast;
    }else {	
	return undef if ($loop > 1);

	$query = new CGI;
    }
    
    return $query;
}

sub get_parameters {
#    &wwslog('debug', 'get_parameters');

    ## CGI URL
    if ($ENV{'HTTPS'} eq 'on') {
	$param->{'base_url'} = sprintf 'https://%s', $ENV{'HTTP_HOST'};
    }else {
	$param->{'base_url'} = sprintf 'http://%s', $ENV{'HTTP_HOST'};
    }

    if ($ENV{'REQUEST_METHOD'} eq 'GET') {
	my $path_info = $ENV{'PATH_INFO'};

	$path_info =~ s+^/++;

	my $ending_slash = 0;
	if ($path_info =~ /\/$/) {
	    $ending_slash = 1;
	}

	my @params = split /\//, $path_info;

	if ($params[0] eq 'nomenu') {
	    $param->{'nomenu'} = 1;
	    shift @params;
	}
	
	## debug mode
#	if ($params[0] eq 'debug') {
#	    shift @params;
#	    $Getopt::Std::opt_d = 1;
#	}elsif ($params[0] eq 'debug2') {
#	    shift @params;
#	    $Getopt::Std::opt_d = 1;
#	    $Getopt::Std::opt_D = 1;
#	}
	 
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
    }
    
    ## listmaster has owner and editor privileges for the list
    if (&List::is_listmaster($param->{'user'}{'email'})) {
	$param->{'is_listmaster'} = 1;
    }

   if ($in{'list'}) {
       unless ($list = new List ($in{'list'})) {
	   &message('unknown_list', {'list' => $in{'list'}} );
	   &wwslog('info','check_param: unknown list %s', $in{'list'});
	   return undef;
       }
       
       $param->{'list'} = $in{'list'};
       $param->{'subtitle'} = $list->{'admin'}{'subject'};
       $param->{'subscribe'} = $list->{'admin'}{'subscribe'}{'name'};
       $param->{'send'} = $list->{'admin'}{'send'}{'title'}{$param->{'lang'}};
       $param->{'total'} = $list->get_total();
       $param->{'list_as_x509_cert'} = $list->{'as_x509_cert'};

       ## privileges
       if ($param->{'user'}{'email'}) {
	   $param->{'is_subscriber'} = $list->is_user($param->{'user'}{'email'});
	   $param->{'is_privileged_owner'} = $param->{'is_listmaster'} || $list->am_i('privileged_owner', $param->{'user'}{'email'});
	   $param->{'is_owner'} = $param->{'is_privileged_owner'} || $list->am_i('owner', $param->{'user'}{'email'});
	   $param->{'is_editor'} = $list->am_i('editor', $param->{'user'}{'email'});
	   $param->{'is_priv'} = $param->{'is_owner'} || $param->{'is_editor'};

	   my $may_post = &List::request_action ('send',$param->{'auth_method'},
						 {'listname' => $param->{'list'}, 
						  'sender' => $param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});
	   $param->{'may_post'} = 1 
	       unless ($may_post =~ /reject/);
       }
	
       $param->{'is_moderated'} = $list->is_moderated();
 
       ## Privileged info
       if ($param->{'is_priv'}) {
	   $param->{'mod_total'} = $list->get_mod_spool_size();
	   if ($param->{'total'} > 0) {
	       $param->{'bounce_total'} = $list->get_total_bouncing();
	       $param->{'bounce_rate'} = $param->{'bounce_total'} * 100 / $param->{'total'};
	       $param->{'bounce_rate'} = int ($param->{'bounce_rate'} * 10) / 10;
	   }
       }
       
       ## (Un)Subscribing 
       if ($list->{'admin'}{'user_data_source'} eq 'include') {
	   $param->{'may_signoff'} = $param->{'may_suboptions'} = $param->{'may_subscribe'} = 0;
       }else {
	   unless ($param->{'user'}{'email'}) {
	       $param->{'may_subscribe'} = $param->{'may_signoff'} = 1;
	       
	   }else {
	       if ($param->{'is_subscriber'}) {
		   ## May signoff
		   $main::action = &List::request_action ('unsubscribe',$param->{'auth_method'},
						    {'listname' =>$param->{'list'}, 
						     'sender' =>$param->{'user'}{'email'},
						     'remote_host' => $param->{'remote_host'},
						     'remote_addr' => $param->{'remote_addr'}});
		   
		   $param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner/);
		   $param->{'may_suboptions'} = 1;
	       }else {
		   
		   ## May Subscribe
		   $main::action = &List::request_action ('subscribe',$param->{'auth_method'},
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
       
       if (-e "$Conf{'home'}/$param->{'list'}/shared") {
	   $param->{'shared'}='exist';
       }elsif (-e "$Conf{'home'}/$param->{'list'}/pending.shared") {
	   $param->{'shared'}='deleted';
       }else{
	   $param->{'shared'}='none';
       }
   }
    
    if ($param->{'user'}{'email'} && 
	(&List::request_action ('create_list',$param->{'auth_method'},
				{'sender' => $param->{'user'}{'email'},
				 'remote_host' => $param->{'remote_host'},
				 'remote_addr' => $param->{'remote_addr'}}) =~ /do_it|listmaster/)) {
	$param->{'may_create_list'} = 1;
    }else{
	undef ($param->{'may_create_list'});
    }

    return 1;

}

## Prepare outgoing params
sub check_param_out {
    &wwslog('debug2', 'check_param');

    if ($list->{'name'}) {
	## Owners
	foreach my $o (@{$list->{'admin'}{'owner'}}) {
	    next unless $o->{'email'};
	    $param->{'owner'}{$o->{'email'}}{'gecos'} = $o->{'gecos'} || $o->{'email'};
	}
	
	## Editors
	foreach my $e (@{$list->{'admin'}{'editor'}}) {
	    next unless $e->{'email'};
	    $param->{'editor'}{$e->{'email'}}{'gecos'} = $e->{'gecos'} || $e->{'email'};
	}  
 
	## Should Not be used anymore ##
	$param->{'may_subunsub'} = 1 
	    if ($param->{'may_signoff'} || $param->{'may_subscribe'});
	
	## May review
	my $action = &List::request_action ('review',$param->{'auth_method'},
					    {'listname' => $param->{'list'},
					     'sender' => $param->{'user'}{'email'},
					     'remote_host' => $param->{'remote_host'},
					     'remote_addr' => $param->{'remote_addr'}});
	
	$param->{'may_review'} = 1 if ($action =~ /do_it/);
	
	## Archives Access control
	if (defined $list->{'admin'}{'web_archive'}) {
	    $param->{'is_archived'} = 1;
	    
	    if (&List::request_action ('web_archive.access',$param->{'auth_method'},
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
    &wwslog('debug', 'do_login(%s)', $in{'email'});
    my $user;
    my $next_action;
    
    if ($param->{'user'}{'email'}) {
	&message('already_login', {'email' => $param->{'user'}{'email'}});
	&wwslog('info','do_login: user %s already logged in', $param->{'user'}{'email'});
	return undef;
    }
    
    unless ($in{'email'}) {
	&message('no_email');
	&wwslog('info','do_login: no email');
	return undef;
    }
    
    unless (&wwslib::valid_email($in{'email'})) {
	&message('incorrect_email', {'email' => $in{'email'}});
	&wwslog('info','do_login: incorrect email %s', $in{'email'});
	return undef;
    }    
    
    unless ($in{'passwd'}) {
	$in{'init_email'} = $in{'email'};
	$param->{'init_email'} = $in{'email'};
	return 'loginrequest';
    }

    ## Make password case-insensitive !!
    $in{'passwd'} =~ tr/A-Z/a-z/;
    
    unless ($user = &List::get_user_db($in{'email'})) {
	
	$user = {'email' => $in{'email'},
		 'password' => &tools::tmp_passwd($in{'email'}) 
		 };
    }
    
    unless ($user->{'password'}) {
	&message('passwd_not_found', {'email' => $in{'email'}});
	&wwslog('info','do_login: password for user %s not found', $in{'email'});
	$param->{'init_email'} = $in{'email'};
	return 'loginrequest';
    }
    
    unless ($in{'passwd'} eq $user->{'password'}) {

	## Uncomplete password
	if ($user->{'password'} =~ /$in{'passwd'}/) {
	    &message('uncomplete_passwd');
	    &wwslog('info','do_login: uncomplete password for user %s', $in{'email'});
	}else {
	    &message('incorrect_passwd');
	    &wwslog('info','do_login: incorrect password for user %s', $in{'email'});
	}

	$param->{'init_email'} = $in{'email'};
	return 'loginrequest';
    }
    
    $param->{'user'} = $user;
    
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

## send back login form
sub do_loginrequest {
    &wwslog('debug','do_loginrequest');
    
    if ($param->{'user'}{'email'}) {
	&message('already_login', {'email' => $param->{'user'}{'email'}});
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
    &wwslog('debug','do_help(%s)', $in{'help_topic'});
    
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
    &wwslog('debug','do_logout(%s)', $param->{'user'}{'email'});
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_logout: user not logged in');
	return undef;
    }
    
    delete $param->{'user'};
    
    &wwslog('info','do_logout: logout performed');
    
    if ($in{'previous_action'} eq 'referer') {
	$param->{'referer'} = &tools::escape_chars($in{'previous_list'});
    }

    return 'home';
}

## Remind the password
sub do_remindpasswd {
    &wwslog('debug', 'do_remindpasswd(%s)', $in{'email'}); 
    
    if ($in{'email'} and ! &wwslib::valid_email($in{'email'})) {
	&message('incorrect_email', {'email' => $in{'email'}});
	&wwslog('info','do_remindpasswd: incorrect email %s', $in{'email'});
	return undef;
    }
    
    $param->{'email'} = $in{'email'};
    
    if ($in{'previous_action'} eq 'referer') {
	$param->{'referer'} = &tools::escape_chars($in{'previous_list'});
    }
    
    return 1;
}

sub do_sendpasswd {
    &wwslog('debug', 'do_sendpasswd(%s)', $in{'email'}); 
    my ($passwd, $user);
    
    unless ($in{'email'}) {
	&message('no_email');
	&wwslog('info','do_sendpasswd: no email');
	return 'remindpasswd';
    }
    
    unless (&wwslib::valid_email($in{'email'})) {
	&message('incorrect_email', {'email' => $in{'email'}});
	&wwslog('info','do_sendpasswd: incorrect email %s', $in{'email'});
	return 'remindpasswd';
    }
    

    if ($param->{'newuser'} =  &List::get_user_db($in{'email'})) {

	## Create a password if none
	unless ($param->{'newuser'}{'password'}) {
	    unless ( &List::update_user_db($in{'email'},
					   {'password' => &tools::tmp_passwd($in{'email'}) 
					    })) {
		&message('update_failed');
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

	$param->{'init_passwd'} = 1;
    }

    unless (open MAIL, "|$Conf{'sendmail'} $in{'email'}") {
	&message('mail_error');
	&wwslog('info','do_sendpasswd: mail error');
	return undef;
    }    

    my $tpl_file;
        
    foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	if (-f "$tpldir/msg_sendpasswd.$param->{'lang'}.tpl") {
	    $tpl_file = "$tpldir/msg_sendpasswd.$param->{'lang'}.tpl";
	    last;
	}
	if (-f "$tpldir/msg_sendpasswd.tpl") {
	    $tpl_file = "$tpldir/msg_sendpasswd.tpl";
	    last;
	}
    }
    
    &parse_tpl ($param, $tpl_file, MAIL);
    close MAIL;

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
    
    return 1;
}

## Which list the user is subscribed to 
## TODO (pour listmaster, toutes les listes)
sub do_which {
    my $which = {};
    my @lists;
    &wwslog('debug', 'do_which');
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_which: no user');
	$param->{'previous_action'} = 'which';
	return 'loginrequest';
    }

    foreach my $role ('member','owner','editor') {
	foreach my $l ( &List::get_which($param->{'user'}{'email'}, $role) ) {
	    my $list = new List ($l);
	    
	    $param->{'which'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	    $param->{'which'}{$l}{'host'} = $list->{'admin'}{'host'};
	    if ($role eq 'member') {
		$param->{'which'}{$l}{'info'} = 1;
	    }else {
		$param->{'which'}{$l}{'admin'} = 1;
	    }

	    ## For compatibility concerns (3.0)
	    ## To be deleted one of these day
	    $param->{$role}{$l}{'subject'} = $list->{'admin'}{'subject'};
	    $param->{$role}{$l}{'host'} = $list->{'admin'}{'host'};
	}
    }

    return 1;
}

## The list of list
sub do_lists {
    my @lists;
    &wwslog('debug', 'do_lists(%s,%s)', $in{'topic'}, $in{'subtopic'});

    my %topics = &List::load_topics();

    if ($in{'topic'}) {
	if ($in{'subtopic'}) {
	    $param->{'subtitle'} = sprintf "%s / %s", $topics{$in{'topic'}}{'title'}, $topics{$in{'topic'}}{'sub'}{$in{'subtopic'}}{'title'};
	    $param->{'subtitle'} ||= "$in{'topic'} / $in{'subtopic'}";
	}else {
	    $param->{'subtitle'} = $topics{$in{'topic'}}{'title'} || $in{'topic'};
	}
    }

    foreach my $l ( &List::get_lists() ) {
	my $list = new List ($l);

	my $sender = $param->{'user'}{'email'} || 'nobody';
	my $action = &List::request_action ('visibility',$param->{'auth_method'},
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
	    
	if ($list->{'admin'}{'topics'}) {
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
    &wwslog('debug', 'do_info');

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_info: no list');
	return undef;
    }

    ## May review
    my $action = &List::request_action ('info',$param->{'auth_method'},
					{'listname' => $param->{'list'},
					 'sender' => $param->{'user'}{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});
    unless ($action =~ /do_it/) {
	&message('may_not');
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
	    &message('subscriber_not_found', {'email' => $param->{'user'}{'email'}});
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

	$param->{'subscriber'} = $s;
    }

    ## Get List Description
    if (-r "$Conf{'home'}/$param->{'list'}/homepage") {
	$param->{'homepage_file'} = "$Conf{'home'}/$param->{'list'}/homepage";
    }else {
	$param->{'info_file'} = "$Conf{'home'}/$param->{'list'}/info";
    }



    return 1;
}

## Subscribers' list
sub do_review {
    &wwslog('debug', 'do_review(%d)', $in{'page'});
    my $record;
    my @users;
    my $size = $in{'size'} || $wwsconf->{'review_page_size'};
    my $sortby = $in{'sortby'} || 'email';

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_review: no list');
	return undef;
    }

    ## May review
    my $action = &List::request_action ('review',$param->{'auth_method'},
					{'listname' => $param->{'list'},
					 'sender' => $param->{'user'}{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});
    unless ($action =~ /do_it/) {
	&message('may_not');
	&wwslog('info','do_review: may not review');
	return undef;
    }

    unless ($param->{'total'}) {
	&message('no_subscriber');
	&wwslog('info','do_review: no subscriber');
	return 1;
    }

    ## Owner
    $param->{'page'} = $in{'page'} || 1;
    $param->{'total_page'} = int ($param->{'total'} / $size);
    $param->{'total_page'} ++
	if ($param->{'total'} % $size);

    if ($param->{'page'} > $param->{'total_page'}) {
	&message('no_page', {'page' => $param->{'page'}});
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
    unless (($list->{'admin'}{'user_data_source'} eq 'database') && 
	    ($Conf{'db_type'} =~ /^Pg|mysql$/)) {
	$limit_not_used = 1;
    }

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

	$i->{'reception'} ||= 'mail';

	## Escape some weird chars
	$i->{'escaped_email'} = &tools::escape_chars($i->{'email'});

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

    return 1;
}

## Search in subscribers
sub do_search {
    &wwslog('debug', 'do_search(%s)', $in{'filter'});

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_search: no list');
	return undef;
    }

    unless ($in{'filter'}) {
	&message('no_filter');
	&wwslog('info','do_search: no filter');
	return undef;
    }
    
    ## May review
    my $sender = $param->{'user'}{'email'} || 'nobody';
    my $action = &List::request_action ('review',$param->{'auth_method'},
					{'listname' => $param->{'list'},
					 'sender' => $sender,
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

    unless ($action =~ /do_it/) {
	&message('may_not');
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
    &wwslog('debug', 'do_pref');

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_pref: no user');
	$param->{'previous_action'} = 'pref';
	return 'loginrequest';
    }

    ## Available languages
#    foreach $l (keys %languages) {
    my $saved_lang = &Language::GetLang();
    foreach my $l (@wwslib::languages) {
#	$param->{'languages'}{$l}{'complete'} = $languages{$l};
	&Language::SetLang($l);
	$param->{'languages'}{$l}{'complete'} = Msg(14, 2, $l);
	if ($param->{'lang'} eq $l) {
	    $param->{'languages'}{$l}{'selected'} = 'SELECTED';
	}else {
	    $param->{'languages'}{$l}{'selected'} = '';
	}
    }
    &Language::SetLang($saved_lang);
    
    $param->{'previous_list'} = $in{'previous_list'};
    $param->{'previous_action'} = $in{'previous_action'};

    return 1;
}

## Set the initial password
sub do_choosepasswd {
    &wwslog('debug', 'do_choosepasswd');

    unless ($param->{'user'}{'email'}) {
	unless ($in{'email'} && $in{'passwd'}) {
	    &message('no_user');
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
    &wwslog('debug', 'do_set(%s, %s)', $in{'reception'}, $in{'visibility'});

    my ($reception, $visibility) = ($in{'reception'}, $in{'visibility'});
    my $email;

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_set: no list');
	return undef;
    }
    
    unless ($reception || $visibility) {
	&message('no_reception');
	&wwslog('info','do_set: no reception');
	return undef;
    }
    
    if ($in{'email'}) {
    	unless ($param->{'is_owner'}) {
	    &message('may_not');
	    &wwslog('info','do_set: not owner');
	    return undef;
        }
	
	$email = &tools::unescape_chars($in{'email'});
    }else {
    	unless ($param->{'user'}{'email'}) {
	    &message('no_user');
	    &wwslog('info','do_set: no user');
	    return 'loginrequest';
        }
	$email = $param->{'user'}{'email'};
    } 
    
    unless ($list->is_user($email)) {
	&message('not_subscriber');
	&wwslog('info','do_set: %s not subscriber of list %s', $email, $param->{'list'});
	return undef;
    }
    
    # Verify that the mode is allowed
    if (! $list->is_available_reception_mode($reception)) {
      &message('not_allowed');
      return undef;
    }

    $reception = '' if $reception eq 'mail';
    $visibility = '' if $visibility eq 'noconceal';
   
    my $update = {'reception' => $reception,
		  'visibility' => $visibility};
    
    if ($in{'email'} ne $in{'new_email'}) {

	## Duplicate entry in user_table
	unless (&List::is_user_db($in{'new_email'})) {

	    my $user_pref = &List::get_user_db($in{'email'});
	    $user_pref->{'email'} = $in{'new_email'};
	    &List::add_user_db($user_pref);
	}
	
	$update->{'email'} = $in{'new_email'};
    }

    $update->{'gecos'} = $in{'gecos'} if $in{'gecos'};
    
    unless ( $list->update_user($email, $update) ) {
	&message('failed');
	&wwslog('info', 'do_set: set failed');
	return undef;
    }
    
    &message('performed');
    
    return 'info';
}

## Update of user preferences
sub do_setpref {
    &wwslog('debug', 'do_setpref');
    my $changes = {};

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_pref: no user');
	return 'loginrequest';
    }

    foreach my $p ('gecos','lang','cookie_delay') {
	$changes->{$p} = $in{$p};
    }

    if (&List::is_user_db($param->{'user'}{'email'})) {

	unless (&List::update_user_db($param->{'user'}{'email'}, $changes)) {
	    &message('update_failed');
	    &wwslog('info','do_pref: update failed');
	    return undef;
	}
    }else {
	$changes->{'email'} = $param->{'user'}{'email'};
	unless (&List::add_user_db($changes)) {
	    &message('update_failed');
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
    &wwslog('debug', 'do_viewfile');

    unless ($in{'file'}) {
	&message('missing_arg', {'argument' => 'file'});
	&wwslog('info','do_viewfile: no file');
	return undef;
    }

    unless (defined $wwslib::filenames{$in{'file'}}) {
	&message('file_not_editable', {'file' => $in{'file'}});
	&wwslog('info','do_viewfile: file %s not editable', $in{'file'});
	return undef;
    }

   unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_viewfile: no list');
	return undef;
    }

    $param->{'file'} = $in{'file'};

    $param->{'filepath'} = "$Conf{'home'}/$list->{'name'}/$in{'file'}";

    if ((-e $param->{'filepath'}) and (! -r $param->{'filepath'})) {
	&message('read_error');
	&wwslog('info','do_viewfile: cannot read %s', $param->{'filepath'});
	return undef;
    }

    return 1;
}

## Subscribe to the list
## TOTO: accepter nouveaux users
sub do_subscribe {
    &wwslog('debug', 'do_subscribe(%s)', $in{'email'});

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
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

	if ( &List::is_user_db($in{'email'}) ) {
	    &message('no_user');
	    &wwslog('info','do_subscribe: need auth for user %s', $in{'email'});
	    return undef;
	}
	
    }

    if ($param->{'is_subscriber'} ) {
	&message('already_subscriber', {'list' => $list->{'name'}});
	&wwslog('info','do_subscribe: %s already subscriber', $param->{'user'}{'email'});
	return undef;
    }
	
    my $sub_is = &List::request_action('subscribe',$param->{'auth_method'},
				       {'listname' => $param->{'list'},
					'sender' => $param->{'user'}{'email'}, 
					'remote_host' => $param->{'remote_host'},
					'remote_addr' => $param->{'remote_addr'}});

    if ($sub_is eq 'closed') {
       	&message('may_not');
	&wwslog('info', 'do_subscribe: subscribe closed');
	return undef;
    }

    $param->{'may_subscribe'} = 1;
    
    if ($sub_is eq 'owner') {
	my $keyauth = $list->compute_auth($param->{'user'}{'email'}, 'add');
	$list->send_sub_to_owner($param->{'user'}{'email'}, $keyauth, $Conf{'sympa'}, $param->{'user'}{'gecos'});
	&message('sent_to_owner');
	&wwslog('info', 'do_subscribe: subscribe sent to owner');

	return 'info';
    }elsif ($sub_is =~ /do_it/) {
	my $u = $list->get_default_user_options();
	$u->{'email'} = $param->{'user'}{'email'};
	$u->{'gecos'} = $param->{'user'}{'gecos'} || $in{'gecos'};
	$u->{'date'} = time;
	$u->{'password'} = $param->{'user'}{'password'};
	$u->{'lang'} = $param->{'user'}{'lang'} || $param->{'lang'};
	
	unless ($list->add_user($u)) {
	    &message('failed');
	    &wwslog('info', 'do_subscribe: subscribe failed');
	    return undef;
	}

	$list->save();

	my %context;
	$context{'subject'} = sprintf(Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	$context{'body'} = sprintf(Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	$list->send_file('welcome', $param->{'user'}{'email'}, \%context);

	if ($sub_is =~ /notify/) {
	    $list->send_notify_to_owner($param->{'user'}{'email'}, $param->{'user'}{'gecos'}, 'subscribe');
	}
    }
    
    &message('performed');

#    return 'suboptions';
    return 'info';
}

## Subscription request (user not authentified)
sub do_suboptions {
    &wwslog('debug', 'do_suboptions()');
    
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_suboptions: no list');
	return undef;
    }

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_suboptions: user not logged in');
	return undef;
    }

    unless($list->is_user($param->{'user'}{'email'})) {
	&message('not_subscriber', {'list' => $list->{'name'}});
	&wwslog('info','do_suboptions: %s not subscribed to %s',$param->{'user'}{'email'}, $param->{'list'} );
	return undef;
    }
    
    my ($s, $m);
    
    unless($s = $list->get_subscriber($param->{'user'}{'email'})) {
	&message('subscriber_not_found', {'email' => $param->{'user'}{'email'}});
	&wwslog('info', 'do_info: subscriber %s not found', $param->{'user'}{'email'});
	return undef;
    }
    
    $s->{'reception'} ||= 'mail';
    $s->{'visibility'} ||= 'noconceal';
    $s->{'date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'date'}));
    
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
    &wwslog('debug', 'do_subrequest(%s)', $in{'email'});
    
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_subrequest: no list');
	return undef;
    }
    
    ## Basic check of email if provided
    if ($in{'email'}) {
	unless (&wwslib::valid_email($in{'email'})) {
	    &message('incorrect_email');
	    &wwslog('info','do_subrequest: incorrect email %s'
		    , $in{'email'});
	    return undef;
	}
    }
    
    ## Auth ?
    if ($param->{'user'}{'email'}) {

	## Subscriber ?
	if ($param->{'is_subscriber'}) {
	    &message('already_subscriber', {'list' => $list->{'name'}});
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
	if ($list->is_user($in{'email'})) {
	    $param->{'status'} = 'notauth_subscriber';
	    return 1;
	}

	my $user;
	$user = &List::get_user_db($in{'email'})
	    if &List::is_user_db($in{'email'});

	## Need to send a password by email
	if (!&List::is_user_db($in{'email'}) || 
	    !$user->{'password'} || 
	    ($user->{'password'} =~ /^INIT/i)) {

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
    &wwslog('debug', 'do_signoff');

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_signoff: no list');
	return undef;
    }

    unless ($param->{'user'}{'email'}) {
	unless ($in{'email'}) {
	    &message('no_user');
	    &wwslog('info','do_signoff: no user');
	    return 'loginrequest';
	}

	## Perform login first
	if ($in{'passwd'}) {
	    $in{'previous_action'} = 'signoff';
	    $in{'previous_list'} = $param->{'list'};
	    return 'login';
	}
	
	if ( &List::is_user_db($in{'email'}) ) {
	    &message('no_user');
	    &wwslog('info','do_signoff: need auth for user %s', $in{'email'});
	    return undef;
	}
	
	## No passwd
	&init_passwd($in{'email'}, {'lang' => $param->{'lang'} });
	
	$param->{'user'}{'email'} = $in{'email'};
    }
    
    unless ($list->is_user($param->{'user'}{'email'})) {
	&message('not_subscriber', {'list' => $list->{'name'}});
	&wwslog('info','do_signoff: %s not subscribed to %s',$param->{'user'}{'email'}, $param->{'list'} );
	return undef;
    }

    my $sig_is = &List::request_action ('unsubscribe',$param->{'auth_method'},
					{'listname' => $param->{'list'}, 
					 'sender' => $param->{'user'}{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

    $param->{'may_signoff'} = 1 if ($sig_is =~ /do_it|owner/);
    
    if ($sig_is =~ /reject/) {
	&message('may_not');
	&wwslog('info', 'do_signoff: %s may not signoff from %s'
		, $param->{'user'}{'email'}, $param->{'list'});
	return undef;
    }elsif ($sig_is =~ /owner/) {
	my $keyauth = $list->compute_auth($param->{'user'}{'email'}, 'del');
	$list->send_sig_to_owner($param->{'user'}{'email'}, $keyauth);
	&message('sent_to_owner');
	&wwslog('info', 'do_signoff: signoff sent to owner');
	return undef;
    }else {
	unless ($list->delete_user($param->{'user'}{'email'})) {
	    &message('failed');
	    &wwslog('info', 'do_signoff: signoff failed');
	    return undef;
	}

	$list->save();

	if ($sig_is =~ /notify/) {
	    $list->send_notify_to_owner($param->{'user'}{'email'}, '', 'signoff');
	}
	
	my %context;
	$context{'subject'} = sprintf(Msg(6 , 71, 'Signoff from list %s'), $list->{'name'});
 	$context{'body'} = sprintf(Msg(6 , 31, "You have been removed from list %s.\n Thanks for being with us.\n"), $list->{'name'});
	$list->send_file('bye', $param->{'user'}{'email'}, \%context);
    }

    &message('performed');
    $param->{'is_subscriber'} = 0;
    $param->{'may_signoff'} = 0;

    return 'info';
}

## Unsubscription request (user not authentified)
sub do_sigrequest {
    &wwslog('debug', 'do_sigrequest(%s)', $in{'email'});
    
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_sigrequest: no list');
	return undef;
    }

    ## Do it
    if ($param->{'user'}{'email'}) {
	$param->{'status'} = 'auth';
	return 1;
#	return 'signoff';
    }
    
    ## Not auth & no email
    unless ($in{'email'}) {
	return 'sigrequest';
    }
    
    ## Basic check of email if provided
    if ($in{'email'}) {
	unless (&wwslib::valid_email($in{'email'})) {
	    &message('incorrect_email');
	    &wwslog('info','do_sigrequest: incorrect email %s'
		    , $in{'email'});
	    return undef;
	}
    }
    
    if ($list->is_user($in{'email'})) {
	my $user;
	$user = &List::get_user_db($in{'email'})
	    if &List::is_user_db($in{'email'});

	## Need to send a password by email
	if (!&List::is_user_db($in{'email'}) || 
	    !$user->{'password'} || 
	    ($user->{'password'} =~ /^INIT/i)) {
	    
	    &do_sendpasswd();
	    $param->{'email'} =$in{'email'};
	    $param->{'init_passwd'} = 1;
	    return 'sigrequest';
	}
    }else {
	$param->{'not_subscriber'} = 1;
    }
    
    $param->{'email'} = $in{'email'};
    
    return 1;
}


## Update of password
sub do_setpasswd {
    &wwslog('debug', 'do_setpasswd');
    my $user;

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_setpasswd: no user');
	return 'loginrequest';
    }

     unless ($in{'newpasswd1'}) {
	&message('no_passwd');
	&wwslog('info','do_setpasswd: no newpasswd1');
	return undef;
    }
  
    unless ($in{'newpasswd2'}) {
	&message('no_passwd');
	&wwslog('info','do_setpasswd: no newpasswd2');
	return undef;
    }

    unless ($in{'newpasswd1'} eq $in{'newpasswd2'}) {
	&message('diff_passwd');
	&wwslog('info','do_setpasswd: different newpasswds');
	return undef;
    }

    ## Make password case-insensitive
    $in{'newpasswd1'} =~ tr/A-Z/a-z/;
  
    if (&List::is_user_db($param->{'user'}{'email'})) {
	unless ( &List::update_user_db($param->{'user'}{'email'}, {'password' => $in{'newpasswd1'}} )) {
	    &message('failed');
	    &wwslog('info','do_setpasswd: update failed');
	    return undef;
	}
    }else {
	unless ( &List::add_user_db({'email' => $param->{'user'}{'email'}, 
				     'password' => $in{'newpasswd1'}} )) {
	    &message('failed');
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
    &wwslog('debug', 'do_admin');

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_admin: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_admin: no user');
	$param->{'previous_action'} = 'admin';
	$param->{'previous_list'} = $in{'list'};
	return 'loginrequest';
    }
 
    unless ($param->{'is_owner'} or $param->{'is_editor'}) {
	&message('may_not');
	&wwslog('info','do_admin: %s not priv user', $param->{'user'}{'email'});
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
    &wwslog('debug', 'do_serveradmin');
    my $f;

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_serveradmin: no user');
	$param->{'previous_action'} = 'serveradmin';
	return 'loginrequest';
    }
 
    unless ($param->{'is_listmaster'}) {
	&message('may_not');
	&wwslog('info','do_admin: %s not listmaster', $param->{'user'}{'email'});
	return undef;
    }
 
    $param->{'conf'} = \%Conf;

    ## Lists Default files
    foreach my $f ('welcome.tpl','bye.tpl','removed.tpl','message.footer','message.header','remind.tpl','invite.tpl','reject.tpl') {
	$param->{'lists_default_files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	$param->{'lists_default_files'}{$f}{'selected'} = '';
    }
    
    ## Server files
    foreach my $f ('helpfile.tpl','lists.tpl','global_remind.tpl','summary.tpl') {
	$param->{'server_files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	$param->{'server_files'}{$f}{'selected'} = '';
    }
    $param->{'server_files'}{'helpfile.tpl'}{'selected'} = 'SELECTED';

    return 1;
}

## Multiple add
sub do_add_request {
    &wwslog('debug', 'do_add_request(%s)', $in{'email'});

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_add_request: no list');
	return undef;
    }
 
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_add_request: no user');
	$param->{'previous_action'} = 'add_request';
	$param->{'previous_list'} = $in{'list'};
	return 'loginrequest';
    }

    my $add_is = &List::request_action ('add',$param->{'auth_method'},
					{'listname' => $param->{'list'},
					 'sender' => $param->{'user'}{'email'}, 
					 'email' => 'nobody',
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

    unless ($add_is =~ /do_it/) {
	&message('may_not');
	&wwslog('info','do_add_request: %s may not add', $param->{'user'}{'email'});
	return undef;
    }

    return 1;
}
## Add a user to a list
## TODO: vérifier validité email
sub do_add {
    &wwslog('debug', 'do_add(%s)', $in{'email'});

    my %user;

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_add: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_add: no user');
	return 'loginrequest';
    }
 
    my $add_is = &List::request_action ('add',$param->{'auth_method'},
					{'listname' => $param->{'list'},
					 'sender' => $param->{'user'}{'email'}, 
					 'email' => $in{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

    unless ($add_is =~ /do_it/) {
	&message('may_not');
	&wwslog('info','do_add: %s may not add', $param->{'user'}{'email'});
	return undef;
    }
    
    if ($in{'dump'}) {
	foreach (split /\n/, $in{'dump'}) {
	    if (/^(\S+|\".*\"@\S+)(\s+(.*))?\s*$/) {
		$user{$1} = $3;
	    }
	}
    }elsif ($in{'email'}) {
	$user{$in{'email'}} = $in{'gecos'};
    }else {
	&message('no_email');
	&wwslog('info','do_add: no email');
	return undef;
    }

    my $total = 0;
    foreach my $email (keys %user) {

	unless (&wwslib::valid_email($email)) {
	    &message('incorrect_email', {'email' => $email});
	    &wwslog('info','do_add: incorrect email %s', $email);
	    next;
	}

	if ( $list->is_user($email) ) {
	    &message('user_already_subscriber', {'email' => $email,
						 'list' => $list->{'name'}});
	    &wwslog('info','do_add: %s already subscriber', $email);
	    next;
	}
    
	my $u2 = &List::get_user_db($email);
	my $u = $list->get_default_user_options();
	$u->{'email'} = $email;
	$u->{'gecos'} = $user{$email} || $u2->{'gecos'};
	$u->{'date'} = time;
	$u->{'password'} = $u2->{'password'} || &tools::tmp_passwd($email) ;
	$u->{'lang'} = $u2->{'lang'} || $list->{'admin'}{'lang'};

	unless( $list->add_user($u)) {
	    &message('failed_add', {'user' => $email});
	    &wwslog('info','do_add: failed adding %s', $email);
	    next;
	}

	$total++;
	
	$list->save();
	unless ($in{'quiet'}) {
	    my %context;
	    $context{'subject'} = sprintf(Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	    $context{'body'} = sprintf(Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	    $list->send_file('welcome', $email, \%context);
	}
    }
    
    if ($total == 0) {
	return undef;
    }else {
	&message('add_performed', {'total' => $total});
    }

    return 'review';
}

## Del a user to a list
## TODO: vérifier validité email
sub do_del {
    &wwslog('debug', 'do_del()');

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_del: no list');
	return undef;
    }
    
    unless ($in{'email'}) {
	&message('no_email');
	&wwslog('info','do_del: no email');
	return undef;
    }

    $in{'email'} = &tools::unescape_chars($in{'email'});

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_del: no user');
	return 'loginrequest';
    }
 
    my $del_is = &List::request_action ('del',$param->{'auth_method'},
					{'listname' =>$param->{'list'},
					 'sender' => $param->{'user'}{'email'},
					 'email' => $in{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

    unless ( $del_is =~ /do_it/) {
	&message('may_not');
	&wwslog('info','do_del: %s may not del', $param->{'user'}{'email'});
	return undef;
    }

    my @emails = split /\0/, $in{'email'};

    foreach my $email (@emails) {

	my $escaped_email = &tools::escape_chars($email);
	
	unless ( $list->is_user($email) ) {
	    &message('not_subscriber');
	    &wwslog('info','do_del: %s not subscribed', $email);
	    return undef;
	}
	
	unless( $list->delete_user($email)) {
	    &message('failed');
	    &wwslog('info','do_del: failed for %s', $email);
	    return undef;
	}

	if (-f "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email") {
	    unless (unlink "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email") {
		&wwslog('info','do_resetbounce: failed deleting %s', "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email");
	    }
	}
	

	&wwslog('info','do_del: subscriber %s deleted from list %s', $email, $param->{'list'});
	
	$list->save();

	unless ($in{'quiet'}) {
	    my %context;
	    $context{'subject'} = sprintf(Msg(6, 18, "You have been removed from list %s\n"), $list->{'name'});
	    $context{'body'} = sprintf(Msg(6, 31, "You have been removed from list %s.\nThanks for being with us.\n"), $list->{'name'});
	    
	    $list->send_file('removed', $email, \%context);
	}
    }

    &message('performed');
    $param->{'is_subscriber'} = 1;
    $param->{'may_signoff'} = 1;
    
    return $in{'previous_action'} || 'review';
}

sub do_modindex {
    &wwslog('debug', 'do_modindex');
    my $msg;

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_modindex: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_modindex: no user');
	$param->{'previous_action'} = 'modindex';
	$param->{'previous_list'} = $in{'list'};
	return 'loginrequest';
    }
 
    unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	&message('may_not');
	&wwslog('info','do_modindex: %s not editor', $param->{'user'}{'email'});
	return 'admin';
    }

    ## Loads message list
    unless (opendir SPOOL, $Conf{'queuemod'}) {
	&message('spool_error');
	&wwslog('info','do_modindex: unable to read spool');
	return 'admin';
    }
    
    foreach $msg ( sort grep(!/^\./, readdir SPOOL )) {
	next
	    unless ($msg =~ /^$list->{'name'}\_(\w+)$/);
	
	my $id = $1;

	## Load msg
	unless (open MSG, "$Conf{'queuemod'}/$msg") {
	    &message('msg_error');
	    &wwslog('info','do_modindex: unable to read msg %s', $msg);
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

    unless ($param->{'spool'}) {
	&message('no_msg');
	&wwslog('info','do_modindex: no message');
	return 'admin';
    }


    return 1;
}

sub do_reject {
    &wwslog('debug', 'do_reject()');
    my ($msg, $file);

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_reject: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_reject: no user');
	return 'loginrequest';
    }
 
    unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	&message('may_not');
	&wwslog('info','do_reject: %s not editor', $param->{'user'}{'email'});
	return undef;
    }

    unless ($in{'id'}) {
	&message('missing_arg', {'argument' => 'msgid'});
	&wwslog('info','do_reject: no msgid');
	return undef;
    }
   
    foreach my $id (split /\0/, $in{'id'}) {

	$file = "$Conf{'queuemod'}/$list->{'name'}_$id";

	## Open the file
	if (!open(IN, $file)) {
	    &message('failed_someone_else_did_it');
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
		$list->send_file('reject', $rejected_sender, \%context);
	    }
	}
	close(IN);  
	
	unless (unlink($file)) {
	    &message('failed');
	    &wwslog('info','do_reject: failed to erase %s', $file);
	    return undef;
	}
	
    }

    &message('performed');
    
    return 'modindex';
}

## TODO: supprimer le msg
sub do_distribute {
    &wwslog('debug', 'do_distribute()');
    my ($msg, $file);

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_distribute: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_distribute: no user');
	return 'loginrequest';
    }
    
    unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	&message('may_not');
	&wwslog('info','do_distribute: %s not editor', $param->{'user'}{'email'});
	return undef;
    }

    unless ($in{'id'}) {
	&message('missing_arg', {'argument' => 'msgid'});
	&wwslog('info','do_distribute: no msgid');
	return undef;
    }
    my $extention = time.".".int(rand 9999) ;
    open DISTRIBUTE, ">$Conf{'queue'}/T.$Conf{'sympa'}.$extention" ;

    printf DISTRIBUTE ("X-Sympa-To: %s\n",$Conf{'sympa'});
    printf DISTRIBUTE ("Message-Id: <%s\@wwsympa>\n", time);
    printf DISTRIBUTE ("From: %s\n\n", $param->{'user'}{'email'});

    foreach my $id (split /\0/, $in{'id'}) {
	
	$file = "$Conf{'queuemod'}/$list->{'name'}_$id";

	printf DISTRIBUTE ("QUIET DISTRIBUTE %s %s\n",$list->{'name'},$id);
	unless (rename($file,"$file.distribute")) {
	    &message('failed');
	    &wwslog('info','do_distribute: failed to rename %s', $file);
	}


    }
    close DISTRIBUTE;
    rename("$Conf{'queue'}/T.$Conf{'sympa'}.$extention","$Conf{'queue'}/$Conf{'sympa'}.$extention");

    &message('performed_soon');
    
    return 'modindex';
}

sub do_viewmod {
    &wwslog('debug', 'do_viewmod(%s)', $in{'id'});
    my $msg;

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_viewmod: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_viewmod: no user');
	return 'loginrequest';
    }
 
    unless ($in{'id'}) {
	&message('missing_arg', {'argument' => 'msgid'});
	&wwslog('info','do_viewmod: no msgid');
	return undef;
    }
   
    unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	&message('may_not');
	&wwslog('info','do_viewmod: %s not editor', $param->{'user'}{'email'});
	return undef;
    }

    my $tmp_dir = $Conf{'queuemod'}.'/.'.$list->{'name'}.'_'.$in{'id'};

    unless (-d $tmp_dir) {
	unless (mkdir ($tmp_dir, 0777)) {
	    &message('may_not_create_dir');
	    &wwslog('info','do_viewmod: unable to create %s', $tmp_dir);
	    return undef;
	}
	my $mhonarc_ressources ;
	if (-r "$Conf{'home'}/$list->{'name'}/mhonarc-ressources") {
	    $mhonarc_ressources =  "$Conf{'home'}/$list->{'name'}/mhonarc-ressources" ;
	}elsif (-r "$Conf{'etc'}/mhonarc-ressources"){
	    $mhonarc_ressources =  "$Conf{'etc'}/mhonarc-ressources" ;
	}elsif (-r "--ETCBINDIR--/mhonarc-ressources"){
	    $mhonarc_ressources =  "--ETCBINDIR--/mhonarc-ressources" ;
	}else {
	    do_log('notice',"Cannot find any MhOnArc ressource file");
	}

	## generate HTML
	chdir $tmp_dir;
	open ARCMOD, "$wwsconf->{'mhonarc'}  -single -rcfile $mhonarc_ressources -definevars \"listname=$list->{'name'} hostname=$list->{'admin'}{'host'} \" $Conf{'queuemod'}/$list->{'name'}_$in{'id'}|";
	open MSG, ">msg00000.html";
	&do_log('debug', "$wwsconf->{'mhonarc'}  -single -rcfile $mhonarc_ressources -definevars \"listname=$list->{'name'} hostname=$list->{'admin'}{'host'} \" $Conf{'queuemod'}/$list->{'name'}_$in{'id'}|");
	print MSG <ARCMOD>;
	close MSG;
	close ARCMOD;
	chdir $Conf{'home'};

#	system "cd $Conf{'queuemod'}/.$list->{'name'}_$in{'id'} ; $wwsconf->{'mhonarc'}  -single -rcfile $mhonarc_ressources -definevars \"listname=$list->{'name'} hostname=$list->{'admin'}{'host'} \" $Conf{'queuemod'}/$list->{'name'}_$in{'id'} >msg00000.html";
    }

    if ($in{'file'}) {
	$in{'file'} =~ /\.(\w+)$/;
	$param->{'file_extension'} = $1;
	$param->{'file'} = "$Conf{'queuemod'}/.$list->{'name'}_$in{'id'}/$in{'file'}";
	$param->{'bypass'} = 1;
	##do_log('notice',"xxxxx attachement2 param file $param->{'file'} ");
    }else {
	$param->{'file'} = "$Conf{'queuemod'}/.$list->{'name'}_$in{'id'}/msg00000.html" ;
	##do_log('notice',"xxxxx param file $param->{'file'} ");
    }
    
    $param->{'base'} = sprintf "%s%s/viewmod/%s/%s/", $param->{'base_url'}, $param->{'path_cgi'}, $param->{'list'}, $in{'id'};
    $param->{'id'} = $in{'id'};

    return 1;
}


## Edition of list/sympa files
## No list -> sympa files (helpfile,...)
## TODO : upload
sub do_editfile {
    &wwslog('debug', 'do_editfile(%s)', $in{'file'});
    
    $param->{'subtitle'} = sprintf $param->{'subtitle'}, $in{'file'};

    unless ($in{'file'}) {
	## Messages edition
	foreach my $f ('info','homepage','welcome.tpl','bye.tpl','removed.tpl','message.footer','message.header','remind.tpl','invite.tpl','reject.tpl') {
	    next unless ($list->may_edit($f, $param->{'user'}{'email'}) eq 'write');
	    $param->{'files'}{$f}{'complete'} = Msg(15, $wwslib::filenames{$f}, $f);
	    $param->{'files'}{$f}{'selected'} = '';
	}
	return 1;
    }

    unless (defined $wwslib::filenames{$in{'file'}}) {
	&message('file_not_editable', {'file' => $in{'file'}});
	&wwslog('info','do_editfile: file %s not editable', $in{'file'});
	return undef;
    }

    $param->{'file'} = $in{'file'};

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_editfile: no user');
	return 'loginrequest';
    }

    if ($param->{'list'}) {
	unless ($list->may_edit($in{'file'}, $param->{'user'}{'email'}) eq 'write') {
	    &message('may_not');
	    &wwslog('info','do_editfile: not allowed');
	    return undef;
	}

	## Look for the template
	foreach my $dir ("$Conf{'home'}/$param->{'list'}","$Conf{'etc'}/templates","--ETCBINDIR--/templates") {
	    if (-f "$dir/$in{'file'}") {
		$param->{'filepath'} = "$dir/$in{'file'}";
		last;
	    }
	}
    }else {
	unless (&List::is_listmaster($param->{'user'}{'email'})) {
	    &message('missing_arg', {'argument' => 'list'});
	    &wwslog('info','do_editfile: no list');
	    return undef;
	}

	## Look for the template
	foreach my $dir ("$Conf{'etc'}/templates","--ETCBINDIR--/templates") {
	    if (-f "$dir/$in{'file'}") {
		$param->{'filepath'} = "$dir/$in{'file'}";
		last;
	    }
	}
    }

    if ($param->{'filepath'} && (! -r $param->{'filepath'})) {
	&message('failed');
	&wwslog('info','do_editfile: cannot read %s', $param->{'filepath'});
	return undef;
    }
    
    return 1;
}

## Saving of list files
sub do_savefile {
    &wwslog('debug', 'do_savefile(%s)', $in{'file'});
    
    $param->{'subtitle'} = sprintf $param->{'subtitle'}, $in{'file'};

    unless ($in{'file'}) {
	&message('missing_arg'. {'argument' => 'file'});
	&wwslog('info','do_savefile: no file');
	return undef;
    }

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_savefile: no user');
	return 'loginrequest';
    }

    if ($param->{'list'}) {
	unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	    &message('may_not');
	    &wwslog('info','do_savefile: not allowed');
	    return undef;
	}

	$param->{'filepath'} = "$Conf{'home'}/$list->{'name'}/$in{'file'}";
    }else {
	unless (&List::is_listmaster($param->{'user'}{'email'})) {
	    &message('missing_arg', {'argument' => 'list'});
	    &wwslog('info','do_savefile: no list');
	    return undef;
	}

	$param->{'filepath'} = "$Conf{'etc'}/templates/$in{'file'}";
    }

    unless ((! -e $param->{'filepath'}) or (-w $param->{'filepath'})) {
	&message('failed');
	&wwslog('info','do_savefile: cannot write %s', $param->{'filepath'});
	return undef;
    }

    ## Keep the old file
    if (-e $param->{'filepath'}) {
	rename($param->{'filepath'}, "$param->{'filepath'}.orig");
    }

    ## Not empty
    if ($in{'content'} && ($in{'content'} !~ /^\s*$/)) {			
	## Save new file
	open FILE, ">$param->{'filepath'}";
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
    &wwslog('debug', 'do_arc(%s, %s)', $in{'month'}, $in{'arc_file'});
    my $latest;
    my $index = $wwsconf->{'archive_default_index'};

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_arc: no list');
	return undef;
    }

    ## Access control
    unless (&List::request_action ('web_archive.access',$param->{'auth_method'},
				   {'listname' => $param->{'list'},
				    'sender' => $param->{'user'}{'email'},
				    'remote_host' => $param->{'remote_host'},
				    'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	&message('may_not');
	&wwslog('info','do_arc: access denied for %s', $param->{'user'}{'email'});
	return undef;
   }
    
    ## Reject Email Sniffers
    unless (&cookielib::check_arc_cookie($ENV{'HTTP_COOKIE'})) {
	if ($param->{'user'}{'email'} or $in{'not_a_sniffer'}) {
	    &cookielib::set_arc_cookie();
	}else {
	    return 'arc_protect';
	}
    }

    ## Calendar
    unless (opendir ARC, "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}") {
	&message('empty_archives');
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
	    &message('month_not_found');
	}
	foreach my $file (grep(/^$index/,readdir ARC)) {
	    if ($file =~ /^$index(\d+)\.html$/) {
		$latest = $1 if ($latest < $1);
	    }
	}

	$in{'arc_file'} = $index.$latest.".html";
    }

    ## File exist ?
    unless (-r "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}/$in{'arc_file'}") {
	&wwslog('info',"unable to read $wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'month'}/$in{'arc_file'}");
	&message('arc_not_found');
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

    &cookielib::set_arc_cookie();

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
	&message('may_not_remove_arc');
	&wwslog('info','remove_arc: no message id found');
	$param->{'status'} = 'no_msgid';
	return undef;
    } 
    ## 
    my $arcpath = "$wwsconf->{'arc_path'}/$param->{'list'}\@$param->{'host'}/$in{'yyyy'}-$in{'month'}";
    &wwslog('info','remove_arc: looking for %s in %s',$in{'msgid'},"$arcpath/arctxt");

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
		    &message('may_not_create_deleted_dir');
		    &wwslog('info',"remove_arc: unable to create $arcpath/deleted : $!");
		    $param->{'status'} = 'error';
		    last;
		}
	    }
	    unless (rename ("$arcpath/arctxt/$message","$arcpath/deleted/$message")) {
		&message('may_not_rename_deleted_message');
		&wwslog('info',"remove_arc: unable to rename message $arcpath/arctxt/$message");
		$param->{'status'} = 'error';
		last;
	    }
	    ## system "cd $arcpath ; $conf->{'mhonarc'} -rmm $in{'msgid'}";

  
	    my $file = "$Conf{'queueoutgoing'}/.remove.$list->{'name'}\@$list->{'admin'}{'host'}.$in{'yyyy'}-$in{'month'}.".time;

            unless (open REBUILD, ">$file") {
                &message('failed');
	        &wwslog('info','do_remove: cannot create %s', $file);
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
    unless ($message) {
	&wwslog('info', 'do_remove_arc : no file match msgid');
	$param->{'status'} = 'not_found';
    }

    closedir ARC;
    return 1;
}

## Output an initial form to search in web archives
sub do_arcsearch_form {
    &wwslog('debug', 'do_arcsearch_form(%s)', $param->{'list'});

    unless ($param->{'list'}) {
        &message('missing_arg', {'argument' => 'list'});
        &wwslog('info','do_arcsearch_form: no list');
        return undef;
    }

    ## Access control
    unless (&List::request_action ('web_archive.access',$param->{'auth_method'},
				   {'listname' => $param->{'list'},
				    'sender' => $param->{'user'}{'email'},
				    'remote_host' => $param->{'remote_host'},
				    'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
        &message('may_not');
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
    &wwslog('debug', 'do_arcsearch(%s)', $param->{'list'});

    unless ($param->{'list'}) {
	&message('missing_argument', {'argument' => 'list'});
        &wwslog('info','do_arcsearch: no list');
        return undef;
    }

    ## Access control
    unless (&List::request_action ('web_archive.access',$param->{'auth_method'},
				   {'listname' => $param->{'list'},
				    'sender' => $param->{'user'}{'email'},
				    'remote_host' => $param->{'remote_host'},
				    'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	&message('may_not');
        &wwslog('info','do_arcsearch: access denied for %s', $param->{'user'}{'email'});
        return undef;
    }

    use Marc::Search;

    my $search = new Marc::Search;
    $search->search_base ($wwsconf->{'arc_path'} . '/' . $param->{'list'} . '@' . $param->{'host'});
    $search->base_href ($param->{'base_url'}.$param->{'path_cgi'} . '/arc/' . $param->{'list'});
    
    $search->archive_name ($in{'archive_name'});
    
    if (defined($in{'directories'})) {
	$search->directories ($in{'directories'});
	foreach my $dir (split/\0/, $in{'directories'})	{
	    push @{$param->{'directories'}}, $dir;
	}
    }else {
	$search->directories ($search->archive_name);
	push @{$param->{'directories'}}, $search->archive_name;
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
	&message('missing_argument', {'argument' => 'key_word'});
        &wwslog('info','do_arcsearch: no search term');
	return undef;
    }
    
    $param->{'key_word'} = $in{'key_word'};
    $in{'key_word'} =~ s/\@/\\\@/g;
    
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
    
    return 1;
}

## Search message-id in web archives
sub do_arcsearch_id {
    &wwslog('debug', 'do_arcsearch_id(%s)', $param->{'list'});

    unless ($param->{'list'}) {
	&message('missing_argument', {'argument' => 'list'});
        &wwslog('info','do_arcsearch_id: no list');
        return undef;
    }

    ## Access control
    unless (&List::request_action ('web_archive.access',$param->{'auth_method'},
                   {'listname' => $param->{'list'},
                    'sender' => $param->{'user'}{'email'},
                    'remote_host' => $param->{'remote_host'},
                    'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	&message('may_not');
        &wwslog('info','do_arcsearch_id: access denied for %s', $param->{'user'}{'email'});
        return undef;
    }

    use Marc::Search;

    my $search = new Marc::Search;
    $search->search_base ($wwsconf->{'arc_path'} . '/' . $param->{'list'} . '@' . $param->{'host'});
    $search->base_href ($param->{'base_url'}.$param->{'path_cgi'} . '/arc/' . $param->{'list'});

    $search->archive_name ($in{'archive_name'});

    $search->directories ($search->archive_name);

    ## User didn't enter any search terms
    if ($in{'key_word'} =~ /^\s*$/) {
	&message('missing_argument', {'argument' => 'key_word'});
        &wwslog('info','do_arcsearch_id: no search term');
    return undef;
    }

    $param->{'key_word'} = &tools::unescape_chars($in{'key_word'});
    $in{'key_word'} =~ s/\@/\\\@/g;

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
	&message('msg_not_found');
	&wwslog('info','No message found in archives matching Message-ID %s', $in{'key_word'});
	return 'arc';
    }

    $param->{'redirect_to'} = $param->{'res'}[0]{'file'};

    return 1;
}

# get pendings lists
sub do_get_pending_lists {

    &wwslog('debug', 'get_pending_lists');

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','get_pending_lists :  no user');
	$param->{'previous_action'} = 'get_pending_lists';
	return 'loginrequest';
    }
    unless ( $param->{'is_listmaster'}) {
	&message('may_not');
	&do_log('info', 'Incorrect_privilege to get pending');
	return undef;
    } 

    foreach my $l ( &List::get_lists() ) {
	my $list = new List ($l);
	if ($list->{'admin'}{'status'} eq 'pending') {
	    $param->{'pending'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	    $param->{'pending'}{$l}{'by'} = $list->{'admin'}{'creation'}{'email'};
	}
    }

    return 1;
}

## show a list parameters
sub do_set_pending_list_request {
    &wwslog('debug', 'set_pending_list(%s)',$in{'list'});
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','set_pending_list:  no user');
	return 'loginrequest';
    }
    unless ( $param->{'is_listmaster'}) {
	&message('may_not');
	&do_log('info', 'Incorrect_privilege to open pending list %s from %s', $in{'list'},$param->{'user'}{'email'});
	return undef;
    } 

    $param->{'list_config'} = "$Conf{'home'}/$in{'list'}/config";
    $param->{'list_info'} = "$Conf{'home'}/$in{'list'}/info";
    $param->{'list_subject'} = $list->{'admin'}{'subject'};
    $param->{'list_request_by'} = $list->{'admin'}{'creation'}{'email'};
    $param->{'list_request_date'} = $list->{'admin'}{'creation'}{'date'};
    $param->{'list_serial'} = $list->{'admin'}{'serial'};
    $param->{'list_status'} = $list->{'admin'}{'status'};
 
    return 1;
}

## show a list parameters
sub do_install_pending_list {
    &wwslog('debug', 'do_install_pending_list(%s,%s,%s)',$in{'list'},$in{'status'},$in{'notify'});
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_install_pending_list:  no user');
	return 'loginrequest';
    }
    unless ( $param->{'is_listmaster'}) {
	&message('Incorrect_privilege');
	&do_log('info', 'Incorrect_privilege to open pending list %s from %s', $in{'list'},$param->{'user'}{'email'});
	return undef;
    } 
        
    if ($list->{'admin'}{'status'} eq $in{'status'}) {
	&message('huummm_didnt_change_anything');
	&wwslog('info','view_pending_list: didn t change really the status, nothing to do');
	return undef ;
    }
    
    $param->{'list_config'} = "$Conf{'home'}/$in{'list'}/config";
    if ($in{'serial'} ne $list->{'admin'}{'serial'}) {
	&message('unable_to_write_config_some_one_else_is_editing_it');
	&wwslog('info','serial number as changed Sympa:%s Browser: %s',$in{'serial'},$list->{'admin'}{'serial'});
        return undef;
    }
    unless (open CONFIG, "$Conf{'home'}/$in{'list'}/config") {
	&message('unable_to_read_config');
	&wwslog('info','unable to read configuration file for list %s',$in{'list'});
	return undef;
    }
    unless (open CONFIGOLD, ">$Conf{'home'}/$in{'list'}/config.$in{'serial'}"){
	&message('unable_to_save_config');
	&wwslog('info','unable to write config.%s file for list %s',$in{'serial'},$in{'list'});
	return undef;
    }
    my $serial = $in{'serial'} + 1 ;
    
    unless (open CONFIGNEW, ">$Conf{'home'}/$in{'list'}/config.$serial"){
	&message('unable_to_save_config');
	&wwslog('info','unable to write config.%s file for list %s',$in{'serial'},$in{'list'});
	return undef;
    }
    
    while (<CONFIG>) {
	print CONFIGOLD $_ ;
	if (/^\s*status\s*(open|closed|pending)\s*$/i) {
	    print CONFIGNEW "status $in{'status'}\n";
	    $in{'status'} = 'setting' ;
	}elsif (/^\s*serial\s*(\d*)\s*$/i) {
	    print CONFIGNEW "serial $serial\n";
	    $in{'serial'} = 'setting' ;
	}else{
	    print CONFIGNEW $_ ;
	}
    }
    unless ($in{'status'}) {
	print CONFIGNEW "\nstatus $in{'status'}\n";
    }
    unless ($in{'serial'}) {
	print CONFIGNEW "\nstatus $in{'serial'}\n";
    }
    
    close CONFIG;
    close CONFIGOLD;
    close CONFIGNEW;
    &wwslog('info','new serial %d for list %s',$serial,$in{'list'});
    unless (rename ("$Conf{'home'}/$in{'list'}/config.$serial","$Conf{'home'}/$in{'list'}/config")){
	&message('unable_to_rename_config');
	&wwslog('info','unable to rename %s in %s (status %d)',"$Conf{'home'}/$in{'list'}/config.$serial","$Conf{'home'}/$in{'list'}/config,$!");
	return undef;
    }
    

    $param->{'aliases'}  = "#----------------- $in{'list'}\n";
    $param->{'aliases'} .= "$in{'list'}: \"| --MAILERPROGDIR--/queue $in{'list'}\"\n";
    $param->{'aliases'} .= "$in{'list'}-request: \"| --MAILERPROGDIR--/queue $in{'list'}-request\"\n";
    $param->{'aliases'} .= "$in{'list'}-owner: \"| --MAILERPROGDIR--/bouncequeue $in{'list'}\"\n";
    $param->{'aliases'} .= "$in{'list'}-unsubscribe: \"| --MAILERPROGDIR--/queue $in{'list'}-unsubscribe\"\n";
    $param->{'aliases'} .= "# $in{'list'}-subscribe: \"| --MAILERPROGDIR--/queue $in{'list'}-subscribe\"\n";

    return 1;
}
    

## create a liste using a list template. 
sub do_create_list {
    &wwslog('debug', 'do_create_list(%s,%s,%s)',$in{'listname'},$in{'subject'},$in{'template'});
    unless ($in{'listname'}) {
	&message('list_name_is_required');
	return undef;
    }
    $in{'listname'} = lc ($in{'listname'});

    unless ($in{'listname'} =~ /^[a-z0-9][a-z0-9\-\+\._]*$/i) {
	&message('incorrect_listname', {'listname' => $in{'listname'}});
	return 'create_list_request';
    }
   
    unless ($in{'subject'}) {
	&message('subject_is_required');
	return undef;
    }
    unless ($in{'template'}) {
	&message('type_is_required');
	return undef;
    }
    unless ($in{'info'}) {
	&message('description_is_required');
	return undef;
    }

    unless ($in{'topics'}) {
	&message('topics_is_required');
	return undef;
    }

    if ( new List ($in{'listname'})) {
	&message('list_already_exists');
	&do_log('info', 'could not create already existing list %s for %s', $in{'listname'},$param->{'user'}{'email'});
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_create_list_request:  no user');
	return 'loginrequest';
    }
    my $lang = $param->{'lang'};
    
    $param->{'create_action'} = &List::request_action('create_list',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'}});

    &wwslog('info',"do_create_list, get action : $param->{'create_action'} ");
    
    if ($param->{'create_action'} =~ /reject/) {
	&message('may_not');
	&wwslog('info','do_create_list: not allowed');
	return undef;
    }elsif ($param->{'create_action'} =~ /listmaster/i) {
	$param->{'status'} = 'pending' ;
    }elsif  ($param->{'create_action'} =~ /do_it/i) {
	$param->{'status'} = 'open' ;
    }else{
	&message('internal_scenario_error');
	&wwslog('info','do_create_list: internal error in scenario create_list');
	return undef;
    }
	     
    my $template_file ;
    if (-r "$Conf{'etc'}/create_list_templates/$in{'template'}/config.tpl") {
	$template_file = "$Conf{'etc'}/create_list_templates/$in{'template'}/config.tpl" ;
    }elsif(-r "--ETCBINDIR--/create_list_templates/$in{'template'}/config.tpl") {
	$template_file = "--ETCBINDIR--/create_list_templates/$in{'template'}/config.tpl";
    }else{
	&message('unable_to_open_template');
	&do_log('info', 'no template %s in %s NOR %s',$in{'template'},"$Conf{'etc'}/create_list_templates/$in{'template'}","--ETCBINDIR--/create_list_templates/$in{'template'}");
	
	return undef;
    }
    
    unless (mkdir ("$Conf{'home'}/$in{'listname'}",0777)) {
	&message('unable_to_create_dir');
	&do_log('info', 'unable to create %s/%s : %s',$Conf{'home'},$in{'listname'},$?);
	return undef;
    }    
    
    my $parameters;
    $parameters->{'owner'}{'email'} = $param->{'user'}{'email'};
    $parameters->{'owner'}{'gecos'} = $param->{'user'}{'gcos'};
    $parameters->{'listname'} = $in{'listname'};
    $parameters->{'subject'} = $in{'subject'};
    $parameters->{'date'} = $param->{'date'};
    $parameters->{'date_epoch'} = time;
    $parameters->{'lang'} = $lang;
    $parameters->{'status'} = $param->{'status'};
    $parameters->{'topics'} = $in{'topics'};

    open CONFIG, ">$Conf{'home'}/$in{'listname'}/config";
    &parse_tpl($parameters, $template_file, CONFIG);
    close CONFIG;
    
    open INFO, ">$Conf{'home'}/$in{'listname'}/info" ;
    print INFO $in{'info'};
    close INFO;
    
    ## notify postmaster
    if ($param->{'create_action'} =~ /notify/) {
	&do_log('info','notify postmaster');
  	&List::send_notify_to_listmaster('request_list_creation',$in{'listname'},$parameters->{'owner'}{'email'});
    }
    return 1;
}

## Return the creation form
sub do_create_list_request {
    &wwslog('debug', 'do_create_list_request()');
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_create_list_request:  no user');
	$param->{'previous_action'} = 'create_list_request';
	return 'loginrequest';
    }

    $param->{'create_action'} = &List::request_action('create_list',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'},
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'}});
    
    ## Initialize the form
    ## When returning to the form
    foreach my $p ('listname','template','subject','topics','info') {
	$param->{'saved'}{$p} = $in{$p};
    }

    if ($param->{'create_action'} =~ /reject/) {
	&message('may_not');
	&wwslog('info','do_create_list: not allowed');
	return undef;
    }

    my %topics;
    unless (%topics = &List::load_topics()) {
	&message('unable_to_load_list_of_topics');
    }
    $param->{'list_of_topics'} = \%topics;

    $param->{'list_of_topics'}{$in{'topics'}}{'selected'} = 1
	if ($in{'topics'});

    unless ($param->{'list_list_tpl'} = &tools::get_list_list_tpl()) {
	&message('unable_to_load_create_list_templates');
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
    &wwslog('debug', 'do_home');

    my %topics = &List::load_topics();
    
    my $total = 0;
    foreach my $t (sort {$topics{$a}{'order'} <=> $topics{$b}{'order'}} keys %topics) {
	next unless (&List::request_action ('topics_visibility', $param->{'auth_method'},
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

    return 1;
}

sub do_editsubscriber {
    &wwslog('debug', 'do_editsubscriber(%s)', $in{'email'});

    my $user;

    unless ($param->{'is_owner'}) {
	&message('may_not');
	&wwslog('info','do_editsubscriber: may not edit');
	return undef;
    }

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_editsubscriber: no list');
	return undef;
    }

    unless ($in{'email'}) {
	&message('no_email');
	&wwslog('info','do_editsubscriber: no email');
	return undef;
    }

    $in{'email'} = &tools::unescape_chars($in{'email'});

    unless($user = $list->get_subscriber($in{'email'})) {
	&message('subscriber_not_found', {'email' => $in{'email'}});
	&wwslog('info','do_editsubscriber: subscriber %s not found', $in{'email'});
	return undef;
    }

    $param->{'subscriber'} = $user;
    $param->{'subscriber'}{'escaped_email'} = &tools::escape_chars($param->{'subscriber'}{'email'});
    $param->{'subscriber'}{'date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'date'}));

    ## Prefs
    $param->{'subscriber'}{'reception'} ||= 'mail';
    $param->{'subscriber'}{'visibility'} ||= 'noconceal';
    foreach my $m (keys %wwslib::reception_mode) {		
      if ($list->is_available_reception_mode($m)) {
	$param->{'reception'}{$m}{'description'} = $wwslib::reception_mode{$m};
	if ($param->{'subscriber'}{'reception'} eq $m) {
	    $param->{'reception'}{$m}{'selected'} = 'SELECTED';
	}else {
	    $param->{'reception'}{$m}{'selected'} = '';
	}
      }
    }

    ## Bounces
    if ($user->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/) {
	my @bounce = ($1, $2, $3, $5);
    	$param->{'subscriber'}{'first_bounce'} = &POSIX::strftime("%d %b %Y", localtime($bounce[0]));
    	$param->{'subscriber'}{'last_bounce'} = &POSIX::strftime("%d %b %Y", localtime($bounce[1]));
    	$param->{'subscriber'}{'bounce_count'} = $bounce[2];
	if ($bounce[3] =~ /^(\d+\.(\d+\.\d+))$/) {
	   $user->{'bounce_code'} = $1;
	   $user->{'bounce_status'} = $wwslib::bounce_status{$2};
 	}	

	$param->{'previous_action'} = $in{'previous_action'};
    }

    return 1;
}

sub do_viewconfig {
    &wwslog('debug', 'do_viewconfig(%s)');
    unless ($param->{'list'}) {

	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_viewbounce: no list');
	return undef;
    }

    unless ($param->{'is_owner'}) {
	&message('may_not');
	&wwslog('info','do_viewconfig: may not view');
	return undef;
    }
    $param->{'list_config'} = "$Conf{'home'}/$in{'list'}/config";
    return 1;
}

sub do_viewbounce {
    &wwslog('debug', 'do_viewbounce(%s)', $in{'email'});

    unless ($param->{'is_owner'}) {
	&message('may_not');
	&wwslog('info','do_viewbounce: may not view');
	return undef;
    }

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_viewbounce: no list');
	return undef;
    }

    unless ($in{'email'}) {
	&message('no_email');
	&wwslog('info','do_viewbounce: no email');
	return undef;
    }

    my $escaped_email = &tools::escape_chars($in{'email'});

    $param->{'lastbounce_path'} = "$wwsconf->{'bounce_path'}/$param->{'list'}/$escaped_email";

    unless (-r $param->{'lastbounce_path'}) {
	&message('no_bounce', {'email' => $in{'email'}});
	&wwslog('info','do_viewbounce: no bounce %s', $param->{'lastbounce_path'});
	return undef;
    }

    return 1;
}

## some help for listmaster and developpers
sub do_scenario_test {
    &wwslog('debug', 'do_scenario_test');

    ## List available scenarii
    unless (opendir SCENARI, "--ETCBINDIR--/scenari/"){
	&wwslog('info',"do_scenario_test : unable to open --ETCBINDIR--/scenari");
	&message('scenari_wrong_access');
	return undef;
    }

    foreach my $scfile (readdir SCENARI) {
	if ($scfile =~ /^(\w+)\.(\w+)/ ) {
	    $param->{'scenario'}{$1}{'defined'}=1 ;
	}
    }
    closedir SCENARI;
    foreach my $l ( &List::get_lists() ) {
	$param->{'listname'}{$l}{'defined'}=1 ;
    }
    foreach my $a ('smtp','md5','smime') {
	$param->{'auth_method'}{$a}{'define'}=1 ;
    }

    $param->{'scenario'}{$in{'scenario'}}{'selected'} = 'SELECTED' if $in{'scenario'};

    $param->{'listname'}{$in{'listname'}}{'selected'} = 'SELECTED' if $in{'listname'};
    
    $param->{'authmethod'}{$in{'auth_method'}}{'selected'} = 'SELECTED' if $in{'auth_method'};

    $param->{'email'} = $in{'email'};

    if ($in{'scenario'}) {
        my $operation = $in{'scenario'};
	&wwslog('debug', 'do_scenario_test: perform scenario_test');
	($param->{'scenario_condition'},$param->{'scenario_auth_method'},$param->{'scenario_action'}) = 
	    &List::request_action ($operation,$in{'auth_method'},
				   {'listname' => $in{'listname'},
				    'sender' => $in{'sender'},
				    'email' => $in{'email'},
				    'remote_host' => $in{'remote_host'},
				    'remote_addr' => $in{'remote_addr'}});	
    }
    return 1;
}

## Bouncing addresses review
sub do_reviewbouncing {
    &wwslog('debug', 'do_reviewbouncing(%d)', $in{'page'});
    my $size = $in{'size'} || $wwsconf->{'review_page_size'};

    unless ($in{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_reviewbouncing: no list');
	return undef;
    }

    unless ($param->{'is_owner'}) {
	&message('may_not');
	&wwslog('info','do_reviewbouncing: may not review');
	return 'admin';
    }

    ## Owner
    $param->{'page'} = $in{'page'} || 1;
    $param->{'total_page'} = int ( $param->{'bounce_total'} / $size);
    $param->{'total_page'} ++
	if ($param->{'bounce_total'} % $size);

    if ($param->{'page'} > $param->{'total_page'}) {
	&message('no_page', {'page' => $param->{'page'}});
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
    &wwslog('debug', 'do_resetbounce()');

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_resetbounce: no list');
	return undef;
    }
    
    unless ($in{'email'}) {
	&message('no_email');
	&wwslog('info','do_resetbounce: no email');
	return undef;
    }
    
    $in{'email'} = &tools::unescape_chars($in{'email'});

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_resetbounce: no user');
	return 'loginrequest';
    }
 
    ## Require DEL privilege
    my $del_is = &List::request_action ('del',$param->{'auth_method'},
	{'listname' => $param->{'list'}, 
	 'sender' => $param->{'user'}{'email'},
	 'email' => $in{'email'},
	 'remote_host' => $param->{'remote_host'},
	 'remote_addr' => $param->{'remote_addr'}});
    
    unless ( $del_is =~ /do_it/) {
	&message('may_not');
	&wwslog('info','do_resetbounce: %s may not reset', $param->{'user'}{'email'});
	return undef;
    }

    my @emails = split /\0/, $in{'email'};

    foreach my $email (@emails) {

	my $escaped_email = &tools::escape_chars($email);
    
	unless ( $list->is_user($email) ) {
	    &message('not_subscriber', {'email' => $email});
	    &wwslog('info','do_del: %s not subscribed', $email);
	    return undef;
	}
	
	unless( $list->update_user($email, {'bounce' => 'NULL'})) {
	    &message('failed');
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
    &wwslog('debug', 'do_rebuildarc(%s, %s)', $param->{'list'}, $in{'month'});

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_rebuildarc: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_rebuildarc: no user');
	return 'loginrequest';
    }

    unless ($param->{'is_listmaster'}) {
	&message('may_not');
	&wwslog('info','do_rebuildarc: not listmaster');
	return undef;
    }
  
    my $file = "$Conf{'queueoutgoing'}/.rebuild.$list->{'name'}\@$list->{'admin'}{'host'}";

    unless (open REBUILD, ">$file") {
	&message('failed');
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
    &wwslog('debug', 'do_rebuildallarc');
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_rebuildallarc: no user');
	return 'loginrequest';
    }

    unless ($param->{'is_listmaster'}) {
	&message('may_not');
	&wwslog('info','do_rebuildallarc: not listmaster');
	return undef;
    }
    foreach my $l ( &List::get_lists() ) {
	my $list = new List ($l); 
	next unless (defined $list->{'admin'}{'web_archive'});
        my $file = "$Conf{'queueoutgoing'}/.rebuild.$list->{'name'}\@$list->{'admin'}{'host'}";

	unless (open REBUILD, ">$file") {
	    &message('failed');
	    &wwslog('info','do_rebuildarc: cannot create %s', $file);
	    return undef;
	}
	
	&do_log('info', 'File: %s', $file);
    
	print REBUILD ' ';
	close REBUILD;
        
    }
    &message('performed');

    return 'admin';
}

## Search among lists
sub do_search_list {
    &wwslog('debug', 'do_search_list(%s)', $in{'filter'});

    unless ($in{'filter'}) {
	&message('no_filter');
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
    foreach my $l ( &List::get_lists() ) {
	my $is_admin;
	my $list = new List ($l);

	## Search filter
	next if (($list->{'name'} !~ /$param->{'regexp'}/i) 
		 && ($list->{'admin'}{'subject'} !~ /$param->{'regexp'}/i));
	
	my $action = &List::request_action ('visibility',$param->{'auth_method'},
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
					      'admin' => $is_admin};
    }

    $param->{'occurrence'} = $record;

    return 1;
}

sub do_edit_list {
    &wwslog('debug', 'do_edit_list()');

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_edit_list:  no user');
	return 'loginrequest';
    }

    unless ($param->{'is_owner'}) {
	&message('may_not');
	&wwslog('info','do_edit_list: not allowed');
	return undef;
    }

    my $new_admin = {};

    foreach my $key (sort keys %in) {
	next unless ($key =~ /^(single_param|multiple_param)\.(\S+)$/);
	
	$key =~ /^(single_param|multiple_param)\.(\S+)$/;
	my ($type, $name) = ($1, $2);

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
	&message('config_changed', {'email' => $list->{'admin'}{'update'}{'email'}});
	&wwslog('info','do_edit_list: Config file has been modified(%d => %d) by %s. Cannot apply changes', $in{'single_param.serial'}, $list->{'admin'}{'serial'}, $list->{'admin'}{'update'}{'email'});
	return undef;
    }

    ## Check changes & check syntax
    my %changed;
    my @syntax_error;
    foreach my $pname (sort List::by_order keys %{$pinfo}) {
	my ($p, $new_p);
	## Check privileges first
	next unless ($list->may_edit($pname,$param->{'user'}{'email'}) eq 'write');

	## Single vs multiple parameter
	if ($pinfo->{$pname}{'occurrence'} =~ /n$/) {

	    my $last_index = $#{$new_admin->{$pname}};

	    if ($#{$list->{'admin'}{$pname}} != $last_index) {
		$changed{$pname} = 1; next;
	    }
	    $p = $list->{'admin'}{$pname};
	    $new_p = $new_admin->{$pname};
	}else {
	    $p = [$list->{'admin'}{$pname}];
	    $new_p = [$new_admin->{$pname}];
	}

	## Check changed parameters
	## Also check syntax
	foreach my $i (0..$#{$p}) {

	    ## Scenario
	    if ($pinfo->{$pname}{'scenario'}) {
		if ($p->[$i]{'name'} ne $new_p->[$i]{'name'}) {
		    $changed{$pname} = 1; next;
		}
		## Hash
	    }elsif (ref ($pinfo->{$pname}{'format'}) eq 'HASH') {

		foreach my $key (keys %{$pinfo->{$pname}{'format'}}) {

		    next unless ($list->may_edit("$pname.$key",$param->{'user'}{'email'}) eq 'write');

		    if ($pinfo->{$pname}{'format'}{$key}{'scenario'}) {
			if ($p->[$i]{$key}{'name'} ne $new_p->[$i]{$key}{'name'}) {
			    $changed{$pname} = 1; next;
			}
		    }else{
			if ($pinfo->{$pname}{'format'}{$key}{'occurrence'} =~ /n$/) {

			    if ($#{$p->[$i]{$key}} != $#{$new_p->[$i]{$key}}) {
				$changed{$pname} = 1; next;
			    }
			    foreach my $index (0..$#{$p->[$i]{$key}}) {
				if ($p->[$i]{$key}[$index] ne $new_p->[$i]{$key}[$index]) {
				    unless ($new_p->[$i]{$key}[$index] =~ /^$pinfo->{$pname}{'format'}{$key}{'file_format'}$/) {
					push @syntax_error, $pname;
				    }
				    $changed{$pname} = 1; next;
				}
			    }
			}else {
			    if ($p->[$i]{$key} ne $new_p->[$i]{$key}) {
				unless ($new_p->[$i]{$key} =~ /^$pinfo->{$pname}{'format'}{$key}{'file_format'}$/) {
				    push @syntax_error, $pname;
				}
				
				## If empty and is primary key => delete entry
				if ((! $new_p->[$i]{$key}) && ($pinfo->{$pname}{'format'}{$key}{'occurrence'} eq '1')) {				
				    splice @{$new_p}, $i, 1;
				}
				$changed{$pname} = 1; next;
			    }
			}
		    }
		}
		## Scalar
	    }else {
		if ($p->[$i] ne $new_p->[$i]) {
		    unless ($new_p->[$i] =~ /^$pinfo->{$pname}{'file_format'}$/) {
			push @syntax_error, $pname;
		    }
		    $changed{$pname} = 1; next;
		}
	    }	    
	}
    }

    ## Syntax errors
    if ($#syntax_error > -1) {
	&message('syntax_errors', {'params' => join(',',@syntax_error)});
	foreach my $pname (@syntax_error) {
	    &wwslog('info','do_edit_list: Syntax errors, param %s=\'%s\'', $pname, $new_admin->{$pname});
	}
	return undef;
    }

    ## Update config in memory
    foreach my $pname (keys %changed) {

	my @users;
	
	## User Data Source
	if ($pname eq 'user_data_source') {
	    ## Migrating to database
	    if (($list->{'admin'}{'user_data_source'} eq 'file') &&
		($new_admin->{'user_data_source'} eq 'database')) {
		unless (-f "$list->{'name'}/subscribers") {
		    &wwslog('notice', 'No subscribers to load in database');
		}
		@users = &List::_load_users_file("$list->{'name'}/subscribers");
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
	&message('cannot_save_config');
	&wwslog('info','do_edit_list: Cannot save config file');
	return undef;
    }

    ## Reload config
    $list = new List $list->{'name'};

    ## Tag changed parameters
    foreach my $pname (keys %changed) {
	$::changed_params{$pname} = 1;
    }
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
#    &do_log('debug','shift_var(%s,%s,%s)',$i, $var, join('.',@tokens));
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
    &wwslog('debug', 'do_edit_list_request()');

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_edit_list_request:  no user');
	$param->{'previous_action'} = 'edit_list_request';
	$param->{'previous_list'} = $in{'list'};
	return 'loginrequest';
    }

    unless ($param->{'is_owner'}) {
	&message('may_not');
	&wwslog('info','do_edit_list: not allowed');
	return undef;
    }

    &_prepare_edit_form ($list->{'admin'});

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
	    my %list_of_topics = &List::load_topics();
	    foreach my $selected_topic (@topics) {
		my $menu = {};
		foreach my $topic (keys %list_of_topics) {
		    $menu->{'value'}{$topic}{'selected'} = 0;
		    $menu->{'value'}{$topic}{'title'} = $list_of_topics{$topic}{'title'};

		    foreach my $subtopic (keys %{$list_of_topics{$topic}{'sub'}}) {
			$menu->{'value'}{"$topic/$subtopic"}{'selected'} = 0;
			$menu->{'value'}{"$topic/$subtopic"}{'title'} = "$list_of_topics{$topic}{'title'}/$list_of_topics{$topic}{'sub'}{$subtopic}{'title'}";
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
#    &do_log('debug', '_prepare_data(%s, %s)', $name, $data);

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
		## &do_log('debug', 'xxx Add 1 %s', $name);
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
	    my $list_of_scenario = $list->load_scenario_list($struct->{'scenario'});
	    
	    $list_of_scenario->{$d->{'name'}}{'selected'} = 1;
	    
	    foreach my $key (keys %{$list_of_scenario}) {
		$list_of_scenario->{$key}{'title'} = $list_of_scenario->{$key}{'title'}{$param->{'lang'}} || $key;
	    }
	    
	    $p->{'value'} = $list_of_scenario;

	}elsif (ref ($struct->{'format'}) eq 'HASH') {
	    $p_glob->{'type'} = 'paragraph';
	    unless (ref($d) eq 'HASH') {
		$d = {};
	    }

	    foreach my $k (keys %{$struct->{'format'}}) {
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
	    $p->{'value'} = $d;
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
    my ($var, $level) = @_;

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
		print STDOUT "\t"x$level.$index."\n";
		&dump_var($var->[$index], $level+1);
	    }
	}elsif (ref($var) eq 'HASH') {
	    foreach my $key (sort keys %{$var}) {
		print STDOUT "\t"x$level.'_'.$key.'_'."\n";
		&dump_var($var->{$key}, $level+1);
	    }    
	}
    }else {
	if (defined $var) {
	    print STDOUT "\t"x$level."'$var'"."\n";
	}else {
	    print STDOUT "\t"x$level."UNDEF\n";
	}
    }
}

## NOT USED anymore (expect chinese)
sub do_close_list_request {
    &wwslog('debug', 'do_close_list_request()');

    unless ($param->{'is_listmaster'}) {
	&message('may_not');
	&wwslog('info','do_close_list_request: not listmaster');
	return undef;
    }

    if ($list->{'admin'}{'status'} eq 'closed') {
	&message('already_closed');
	&wwslog('info','do_close_list_request: already closed');
	return undef;
    }      

    return 1;
}

sub do_close_list {
    &wwslog('debug', 'do_close_list_request()');
    
    unless ($param->{'is_listmaster'}) {
	&message('may_not');
	&wwslog('info','do_close_list: not listmaster');
	return undef;
    }  

    if ($list->{'admin'}{'status'} eq 'closed') {
	&message('already_closed');
	&wwslog('info','do_close_list: already closed');
	return undef;
    }      
    
    ## Dump subscribers
    $list->_save_users_file("$list->{'name'}/subscribers.closed.dump");
    
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
    
    &message('list_closed');

    return 'admin';
}

sub do_restore_list {
    &wwslog('debug', 'do_restore_list()');
    
    unless ($param->{'is_listmaster'}) {
	&message('may_not');
	&wwslog('info','do_restore_list: not listmaster');
	return undef;
    }

    unless ($list->{'admin'}{'status'} eq 'closed') {
	&message('list_not_closed');
	&wwslog('info','do_restore_list: list not closed');
	return undef;
    }      
    
    ## Change status & save config
    $list->{'admin'}{'status'} = 'open';
    $list->{'admin'}{'defaults'}{'status'} = 0;
    $list->save_config($param->{'user'}{'email'});

    if ($list->{'admin'}{'user_data_source'} eq 'file') {
	$list->{'users'} = &List::_load_users_file("$list->{'name'}/subscribers.closed.dump");
	$list->save();
    }elsif ($list->{'admin'}{'user_data_source'} eq 'database') {
	unless (-f "$list->{'name'}/subscribers.closed.dump") {
	    &wwslog('notice', 'No subscribers to restore');
	}
	my @users = &List::_load_users_file("$list->{'name'}/subscribers.closed.dump");
	
	## Insert users in database
	foreach my $user (@users) {
	    $list->add_user($user);
	}
    }

    $list->savestats(); 
    &message('list_restored');

    return 'admin';
}


####{lefloch/modif/begin : for the sharing of documents}

## Function load_desc_file
## Rename with get_desc_file!
# returns the description file in a hash
# {'title'} -> string = the title of the file
# {'date'} -> int = the date of creation
# {'email'} -> the last author
# {'read'} -> string = scenario 
# {'edit'} -> string = scenario 


#sub load_desc_file {
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
  
    &wwslog('debug', "d_access_control");
    
    # Result
     my %result;
 
    # Control 

    # Arguments
    my $mode = shift;
    my $path = shift;
    $path = lc($path);

    my $mode_read = $mode->{'read'};
    my $mode_edit = $mode->{'edit'};
    my $mode_control = $mode->{'control'};

    # Useful parameters
    my $expl = $Conf{'home'};

    my $list_name = $list->{'name'};
    my $shareddir =  $expl.'/'.$list_name.'/shared';
    

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
	    $result{'may'}{'read'} = (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},
							   {'listname' => $param->{'list'},
							    'sender' => $param->{'user'}{'email'},
							    'remote_host' => $param->{'remote_host'},
							    'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i);
	}
	if ($mode_edit) {
	    $result{'may'}{'edit'} = (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},
							      {'listname' => $param->{'list'},
							       'sender' => $param->{'user'}{'email'},
							       'remote_host' => $param->{'remote_host'},
							       'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i);
	}
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
		    $may_read = $may_read && (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},
								     {'listname' => $param->{'list'},
								      'sender' => $param->{'user'}{'email'},
								      'remote_host' => $param->{'remote_host'},
								      'remote_addr' => $param->{'remote_addr'},
								      'scenario'=> $desc_hash{'read'}}) =~ /do_it/i);
		}
		
		
		if ($mode_edit) {
		    $may_edit = $may_edit && (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},
								     {'listname' => $param->{'list'},
								      'sender' => $param->{'user'}{'email'},
								      'remote_host' => $param->{'remote_host'},
								      'remote_addr' => $param->{'remote_addr'},
								      'scenario'=> $desc_hash{'edit'}}) =~ /do_it/i);
		    
		}
		

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
		$result{'may'}{'read'} = (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},
								 {'listname' => $param->{'list'},
								  'sender' => $param->{'user'}{'email'},
								  'remote_host' => $param->{'remote_host'},
								  'remote_addr' => $param->{'remote_addr'},
								  'scenario'=>$result{'scenario'}{'read'}}) =~ /do_it/i);
		$result{'may'}{'edit'} =  (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},
								  {'listname' => $param->{'list'},
								   'sender' => $param->{'user'}{'email'},
								   'remote_host' => $param->{'remote_host'},
								   'remote_addr' => $param->{'remote_addr'},
								   'scenario'=>$result{'scenario'}{'edit'}}) =~ /do_it/i);
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

    if ($access{'may'}{'edit'}) {
	my $dir = "$Conf{'home'}/$param->{'list'}";

	if ($in{'d_admin'} eq 'create') {

	    if (-e "$dir/shared") {
		&wwslog('info',"do_d_admin :  create; $dir/shared allready exist");
		&message('failed');
		return undef;
	    }
	    unless (mkdir ("$dir/shared",0777)) {
		&wwslog('info',"do_d_admin : create; unable to create $dir/shared : $! ");
		&message('failed');
		return undef;
	    }

	    return 'd_read';
	}elsif($in{'d_admin'} eq 'restore') {
	    unless (-e "$dir/pending.shared") {
		&wwslog('info',"do_d_admin : restore; $dir/pending.shared not found");
		&message('failed');
		return undef;
	    }
	    if (-e "$dir/shared") {
		&wwslog('info',"do_d_admin : restore; $dir/shared allready exist");
		&message('failed');
		return undef;
	    }
	    unless (rename ("$dir/pending.shared", "$dir/shared")){
		&wwslog('info',"do_d_admin : restore; unable to rename $dir/pending.shared");
		&message('failed');
		return undef;
	    }

	    return 'd_read';
        }elsif($in{'d_admin'} eq 'delete') {
	    unless (-e "$dir/shared") {
		&wwslog('info',"do_d_admin : restore; $dir/shared not found");
		&message('failed');
		return undef;
	    }
	    if (-e "$dir/pending.shared") {
		&wwslog('info',"do_d_admin : delete ; $dir/pending.shared allready exist");
		&message('failed');
		return undef;
	    }
	    unless (rename ("$dir/shared", "$dir/pending.shared")){
		&wwslog('info',"do_d_admin : restore; unable to rename $dir/shared");
		&message('failed');
		return undef;
	    }
	}
	
	return 'admin';
    }else{
	&wwslog('info',"do_d_admin : permission denied for $param->{'user'}{'email'} ");
	&message('failed');
	return undef;
    }
}

#*******************************************
# Function : do_d_read
# Description : reads a file or a directory
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
    #action_args == ['list','@path']
    
    &wwslog('debug', 'do_d_read(%s)', $in{'path'});
   

    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_read: no list');
	return undef;
    }

    ### Useful variables
        
    # current list / current shared directory
    my $list_name = $list->{'name'};
    my $list_host = $list->{'name'}.'@'.$list->{'admin'}{'host'}; 

    # relative path / directory shared of the document 
    my $path = lc($in{'path'});
    my $path_orig = $path;
  
    my $expl = $Conf{'home'};
    
    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

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
    unless (-e "$doc") {
	&wwslog('info',"do_d_read : unable to read $shareddir/$path : no such file or directory");
	&message('no_such_document', {'path' => $path});
	return undef;
    }

    ### Document has non-size zero?
    unless (-s "$doc") {
	&wwslog('info',"do_d_read : unable to read $shareddir/$path : empty document");
	&message('empty_document', {'path' => $path});
	return undef;
    }

    ### Document isn't a description file
    unless ($path !~ /\.desc/) {
	&wwslog('info',"do_d_read : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
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
	&message('may_not');
	&wwslog('info','d_read : access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

    my $may_edit = $access{'may'}{'edit'};
    my $may_control = $access{'may'}{'control'};

    
    ### File or directory ?
  
    if (!(-d $doc)) {
	# parameters for the template file
 	# view a file 
	$param->{'file'} = $doc;
	    
	## File type
	$path =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/; 

	$param->{'file_extension'} = $3;
	$param->{'bypass'} = 1;
	    
    }else {
	# verification of the URL (the path must have a slash at its end)
	if ($path) {
	    if ($path_orig !~ /\/$/) {
		$param->{'redirect_to'} = "$param->{'base_url'}$param->{'path_cgi'}/d_read/$list_name/$path_orig/";
		return 1;
	    }
	    
	}else {
	    if ($ENV{'PATH_INFO'} !~ /\/$/) { 
		$param->{'redirect_to'} = "$param->{'base_url'}$param->{'path_cgi'}/d_read/$list_name/";
		return 1;
	    }
	}

	## parameters of the current directory
	if ($path && (-e "$doc/.desc")) {
	    my %desc_hash = &get_desc_file("$doc/.desc");
	    $param->{'doc_owner'} = $desc_hash{'email'};
	    $param->{'doc_title'} = $desc_hash{'title'};
	}
	my @info = stat $doc;
	$param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[10]));


	# listing of all the shared documents of the directory
	unless (opendir DIR, "$doc") {
	    &message('failed');
	    &wwslog('info',"d_read : cannot open $doc : $!");
	    return undef;
	}

	my @dir = grep !/^\./, readdir DIR;

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
		
		if (-e "$path_doc/.desc") {
		    # check access permission for reading
		    %desc_hash = &get_desc_file("$path_doc/.desc");
		    
		    if  (($user eq $desc_hash{'email'}) || ($may_control) ||
			 (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},
						 {'listname' => $param->{'list'},
						  'sender' => $param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'},
						  'scenario' => $desc_hash{'read'}}) =~ /do_it/i)) {
			
			# Case read authorized : fill the hash 
			$subdirs{$d}{'icon'} = $icon_table{'folder'};

			# name of the doc
			$subdirs{$d}{'doc'} = $d;

			# size of the doc
			$subdirs{$d}{'size'} = (-s $path_doc)/1000;

			# last update
			my @info = stat $path_doc;
			$subdirs{$d}{'date_epoch'} = $info[10];
			$subdirs{$d}{'date'} = &POSIX::strftime("%d %b %y  %H:%M", localtime($info[10]));

			# description
			$subdirs{$d}{'title'} = $desc_hash{'title'};

			# Author
			if ($desc_hash{'email'}) {
			    $subdirs{$d}{'author'} = $desc_hash{'email'};
			    $subdirs{$d}{'author_known'} = 1;
			}
						
			# if the file can be read, check for edit access & edit description files access
			if ($may_control || ($user eq $desc_hash{'email'}) ||
			    ($may_edit && (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},
								  {'listname' => $param->{'list'},
								   'sender' => $param->{'user'}{'email'},
								   'remote_host' => $param->{'remote_host'},
								   'remote_addr' => $param->{'remote_addr'},
								   'scenario' => $desc_hash{'edit'}}) =~ /do_it/i))) {
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
		      # name of the doc
		    $subdirs{$d}{'doc'} = $d;
		      # size
		    $subdirs{$d}{'size'} = (-s $path_doc)/1000; 
		      # last update
		    my @info = stat $path_doc;
		    $subdirs{$d}{'date_epoch'} = $info[10];
		    $subdirs{$d}{'date'} = &POSIX::strftime("%d %b %y  %H:%M", localtime($info[10]));
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
			    (&List::request_action ('shared_doc.d_read',$param->{'auth_method'},
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
		    
		    ## MIME - TYPES : icons for template
		    if (my $type = $mime_types->{$3}) {
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
			if (($user eq $desc_hash{'email'}) || $may_control ||
			    ($may_edit && (&List::request_action ('shared_doc.d_edit',$param->{'auth_method'},
								  {'listname' => $param->{'list'},
								   'sender' => $param->{'user'}{'email'},
								   'remote_host' => $param->{'remote_host'},
								   'remote_addr' => $param->{'remote_addr'},
								   'scenario' => $desc_hash{'edit'}}) =~ /do_it/i))) {
			    
			    $normal_mode = 1;
			    $files{$d}{'edit'} = 1;    
			}
			
			if (($user eq $desc_hash{'email'}) || $may_control) { 
			    $files{$d}{'control'} = 1;    
			}
			
			# fill the file hash
			  # description of the file
			$files{$d}{'title'} = $desc_hash{'title'};
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
		      # last update
		    my @info = stat $path_doc;
		    $files{$d}{'date_epoch'} = $info[10];
		    $files{$d}{'date'} = POSIX::strftime("%d %b %y  %H:%M", localtime($info[10]));
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
	    $path =~ /^(([^\/]*\/)*)([^\/]+)$/; 
	    $param->{'father'} = $1;
	    
	    
	    # Parameters for the description
	    if (-e "$doc/.desc") {
		my @info = stat "$doc/.desc";
		$param->{'serial_desc'} = $info[10];
		my %desc_hash = &get_desc_file("$doc/.desc");
		$param->{'description'} = $desc_hash{'title'};
	    }
	    
	    $param->{'path'} = $path.'/';
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
    my $mode = shift;
    # mode = 'with_slash' / 'without_slash'
    my $path = shift;
    # path = path to format
    
    my $slash;
    if ($mode eq 'with_slash') {
	$slash = '/';
    }
    elsif ($mode eq 'without_slash') {
	$slash = '';
    } else {
	return $path;
    }
   
    $path =~ /^((.+[^\/])(\/*))?$/;
    
    unless ($1) { 
	return "";
    }

    return ($2.$slash);
} 

#*******************************************
# Function : do_d_editfile
# Description : prepares the parameters to
#               edit a file
#*******************************************

sub do_d_editfile {
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_editfile(%s)', $in{'path'});

    # Variables
    my $expl = $Conf{'home'};
    my $path = lc($in{'path'});
    # $path must have no slash at its end
    $path = &format_path('without_slash',$path);

    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};
   
    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

    # Control
        
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_editfile: no list');
	return undef;
    }

    unless ($path) {
	&message('missing_arg', {'argument' => 'file name'});
	&wwslog('info','do_d_editfile: no file name');
	return undef;
    }   

    # Existing document? File?
    unless (-f "$shareddir/$path") {
	&message('no_such_file', {'path' => $path});
	&wwslog('info',"d_editfile : Cannot edit $shareddir/$path : not an existing file");
	return undef;
    }

       
    ### Document isn't a description file?
    unless ($path !~ /\.desc/) {
	&wwslog('info',"do_editdile : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
	return undef;
    }
    
    # Access control
    my %mode;
    $mode{'edit'} = 1;
    my %access = &d_access_control(\%mode,$path);
    my $may_edit = $access{'may'}{'edit'};
   
    unless ($may_edit) {
	&message('may_not');
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
    $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
    $param->{'father'} = $1;    


    # Description of the file
    if (-e "$shareddir/$1.desc.$3") {
	my %desc_hash = &get_desc_file("$shareddir/$1.desc.$3");
	$param->{'desc'} = $desc_hash{'title'};
	$param->{'doc_owner'} = $desc_hash{'email'};   
	## Synchronization
	my @info = stat "$shareddir/$1.desc.$3";
	$param->{'serial_desc'} = $info[10];
    }

    ## Synchronization
    my @info = stat "$shareddir/$path";
    $param->{'serial_file'} = $info[10];
    ## parameters of the current directory
    $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[10]));

    $param->{'father_icon'} = $icon_table{'father'};
    return 1;
}


#*******************************************
# Function : do_d_describe
# Description : Saves the description of 
#               the file
#******************************************

sub do_d_describe {
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_describe(%s)', $in{'path'});

    # Variables
    my $expl = $Conf{'home'};

    my $path = lc($in{'path'});
    ## $path must have no slash at its end
    $path = &format_path('without_slash',$path);


    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};

    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

    my $action_return;

####  Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_describe: no list');
	return undef;
    }

    ### Document isn't a description file?
    unless ($path !~ /\.desc/) {
	&wwslog('info',"do_d_describe : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
	return undef;
    }
    
    ## the path must not be empty (the description file of the shared directory
    #  doesn't exist)
    unless ($path) {
	&message('failed');
	&wwslog('info',"d_describe : Cannot describe $shareddir : root directory");
	return undef;
    }

    ## must be existing a content to replace the description
    unless ($in{'content'}) {
	&message('no_description');
	&wwslog('info',"do_d_describe : cannot describe $shareddir/$path : no content");
	return undef;
    }

    # the file to describe must already exist
    unless (-e "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"d_describe : Unable to describe $shareddir/$path : not an existing document");
	return undef;
    }

    
    # Access control
        # Access control
    my %mode;
    $mode{'edit'} = 1;
    my %access = &d_access_control(\%mode,$path);
       
    unless ($access{'may'}{'edit'}) {
	&message('may_not');
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

	if (-e "$desc_file"){
	    # if description file already exists : open it and modify it
	    my %desc_hash = &get_desc_file ("$desc_file");

	    # Synchronization
	    unless (&synchronize($desc_file,$in{'serial'})){
		&message('synchro_failed');
		&wwslog('info',"d_describe : Synchronization failed for $desc_file");
		return undef;
	    }
	    
	    # fill the description file
	    unless (open DESC,">$desc_file") {
		&wwslog('info',"do_d_describe : cannot open $desc_file : $!");
		&message('failed');
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
		&message('failed');
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
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_savefile(%s)', $in{'path'});
    
    # Variables
    my $expl = $Conf{'home'};

    my $path = lc($in{'path'});
    ## $path must have no slash at its end
    $path = &format_path('without_slash',$path);
    
    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};

    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

####  Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_savefile : no list');
	return undef;
    }

  
    ## must be existing a content to replace the file
    unless ($in{'content'}) {
	&message('no_content');
	&wwslog('info',"do_d_savefile : Cannot save file $shareddir/$path : no content");
	return undef;
    }

    # the path to replace must already exist
    unless (-e "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"do_d_savefile : Unable to save $shareddir/$path : not an existing file");
	return undef;
    }

    # the path must represent a file
    if (-d "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"do_d_savefile : Unable to save $shareddir/$path : is a directory");
	return undef;
    }

    ### Document isn't a description file
    unless ($path !~ /\.desc/) {
	&wwslog('info',"do_d_savefile : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
	return undef;
    }

    # Access control
    my %mode;
    $mode{'edit'} = 1;
    my %access = &d_access_control(\%mode,$path);
      
    unless ($access{'may'}{'edit'}) {
	&message('may_not');
	&wwslog('info','d_savefile : access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

#### End of controls
    
    if ($in{'content'} !~ /^\s*$/) {			
	
	# Synchronization
	unless (&synchronize("$shareddir/$path",$in{'serial'})){
	    &message('synchro_failed');
	    &wwslog('info',"do_d_savefile : Synchronization failed for $shareddir/$path");
	    return undef;
	}

	# Renaming of the old file 
	rename ("$shareddir/$path","$shareddir/$path.old");
    
	# Creation of the shared file

	unless (open FILE, ">$shareddir/$path") {

	    rename("$shareddir/$path.old","$shareddir/$path");

	    &message('cannot_overwrite', {'reason' => $1,
					  'path' => $path});
	    &wwslog('info',"do_d_savefile : Cannot open for replace $shareddir/$path : $!");
	    return undef;
	}
	print FILE $in{'content'};
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
    
	# Removing of the old file
	unlink "$shareddir/$path.old";

    }

    &message('save_success', {'path' => $path});
    return 'd_editfile';
}

#*******************************************
# Function : do_d_overwrite
# Description : Overwrites a file with a
#               uploaded file
#******************************************

sub do_d_overwrite {
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_overwrite(%s)', $in{'path'});
 
    # Variables
    my $expl = $Conf{'home'};
    
    my $path = lc($in{'path'});
    ##### $path must have no slash at its end!
    $path = &format_path('without_slash',$path);

    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};

    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

    # Parameters of the uploaded file
    my $fh = $query->upload('uploaded_file');
    my $fn = $query->param('uploaded_file');

    $fn =~ /([^\/\\]+)$/;
    my $fname = $1;
    

####### Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_overwrite : no list');
	return undef;
    }

    # uploaded file must have a name 
    unless ($fname) {
	&message('missing_arg');
	&wwslog('info',"do_d_overwrite : No file specified to overwrite");
	return undef;
    }

    ### Document isn't a description file?
    unless ($path !~ /\.desc/) {
	&wwslog('info',"do_d_overwrite : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
	return undef;
    }

    # the path to replace must already exist
    unless (-e "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"do_d_overwrite : Unable to overwrite $shareddir/$path : not an existing file");
	return undef;
    }

    # the path must represent a file
    if (-d "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"do_d_overwrite : Unable to create $shareddir/$path : a directory named $path already exists");
	return undef;
    }
    

      # Access control
    my %mode;
    $mode{'edit'} = 1;
    my %access = &d_access_control(\%mode,$path);
   
    unless ($access{'may'}{'edit'}) {
	&message('may_not');
	&wwslog('info','do_d_overwrite :  access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

#### End of controls


    # Synchronization
    unless (&synchronize("$shareddir/$path",$in{'serial'})){
	&message('synchro_failed');
	&wwslog('info',"do_d_overwrite : Synchronization failed for $shareddir/$path");
	return undef;
    }

    # Renaming of the old file 
    rename ("$shareddir/$path","$shareddir/$path.old");
    
    # Creation of the shared file
    unless (open FILE, ">$shareddir/$path") {
	&message('cannot_overwrite', {'path' => $path,
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
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_upload(%s)', $in{'path'});
  
    # Variables 
    my $expl = $Conf{'home'};
    my $path = lc($in{'path'});
    ## $path must have a slash at its end
    $path = &format_path('with_slash',$path);

    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};
   
    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

    # Parameters of the uploaded file
    my $fn = $query->param('uploaded_file');

    $fn =~ /([^\/\\]+)$/;
    my $fname = $1;

# Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_upload : no list');
	return undef;
    }
 
  
    # uploaded file must have a name 
    unless ($fname) {
	&message('no_name');
	&wwslog('info',"do_d_upload : No file specified to upload");
	return undef;
    }

    # The name of the file must be correct and musn't not be a description file
    unless ($fname =~ /^\w/ and 
	    $fname =~ /\w$/ and 
	    $fname =~ /^[\w\-\.]+$/ and
	    $fname !~ /\.desc/) {
	&message('incorrect_name', {'name' => $fname});
	&wwslog('info',"do_d_upload : Unable to create file $fname : incorrect name");
	return undef;
    }

    # the file must be uploaded in a directory existing
    unless (-d "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"do_d_upload : $shareddir/$path : not a directory");
	return undef;
    }

    # Lowercase for file name
    $fname = lc($fname);
    
    # the file mustn't already exist
    if (-e "$shareddir/$path$fname") {
	&message('cannot_upload', {'path' => "$path$fname",
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
	&message('may_not');
	&wwslog('info','do_d_upload : access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

    ## Exception index.html
    unless ($fname !~ /^index.html?$/i) {
	unless ($access{'may'}{'control'}) {
	    &message('index_html', {'dir' => $path});
	    &wwslog('info',"do_d_upload : $param->{'user'}{'email'} not authorized to upload a INDEX.HTML file in $path");
	    return undef;
	}
    }
    
## End of controls

# Creation of the shared file
    my $fh = $query->upload('uploaded_file');
    unless (open FILE, ">$shareddir/$path$fname") {
	&message('cannot_upload', {'path' => "$path$fname",
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
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_delete(%s)', $in{'path'});

        #useful variables
    my $expl = $Conf{'home'};

    my $path = lc($in{'path'});
    ## $path must have no slash at its end!
    $path = &format_path('without_slash',$path);
    
    #Current directory and document to delete
    $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
    my $current_directory = &format_path('with_slash',$1);
    my $document = $3;
    
     # path of the shared directory
    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};
    my $shareddir =  $expl.'/'.$list_name.'/shared';

#### Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_delete : no list');
	return undef;
    }

    ## must be something to delete
    unless ($document) {
	&message('missing_arg', {'argument' => 'document'});
	&wwslog('info',"do_d_delete : no document to delete has been specified");
	return undef;
    }

    ### Document isn't a description file?
    unless ($document !~ /^\.desc/) {
	&wwslog('info',"do_d_delete : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
	return undef;
    }

        
    ### Document exists?
    unless (-e "$shareddir/$path") {
	&wwslog('info',"do_d_delete : $shareddir/$path : no such file or directory");
	&message('no_such_document', {'path' => $path});
	return undef;
    }

    # removing of the document
    my $doc = "$shareddir/$path";
   
    if (-d "$shareddir/$path") {
	# case directory
	
	# Access control
	my %mode;
	$mode{'edit'} = 1;
	my %access = &d_access_control(\%mode,$path);
   
	unless ($access{'may'}{'edit'}) {
	    &message('may_not');
	    &wwslog('info','do_d_delete : access denied for %s', $param->{'user'}{'email'});
	    return undef;
	}

	# test of emptiness
	opendir DIR, "$doc";
	my @readdir = readdir DIR;
	  
	  # test for "ordinary" files
	my @test = grep !/^\./, @readdir;
	if ($#test != -1) {
	    &message('full_directory', {'directory' => $path});
	    &wwslog('info',"do_d_delete : Failed to erase $doc : directory not empty");
	    return undef;
	}
	  # test for files of type ".*" except ".desc";
	@test = grep !(/^\.desc$/ | /^\.(\.)?$/ | /^[^\.]/), @readdir;
	if ($#test != -1) {
	    &message('failed');
	    &wwslog('info',"do_d_delete : Failed to erase $doc : directory contains files of type .*");
	    return undef;
	}
	close DIR;


	# removing of the description file if exists
	if (-e "$doc/\.desc") {
	    unless (unlink("$doc/.desc")) {
		&message('failed');
		&wwslog('info',"do_d_delete : Failed to erase $doc/.desc : $!");
		return undef;
	    }
	}   
	# removing of the directory
	rmdir $doc;

    } else {
	# case file

	# Access control
	my %mode;
	$mode{'edit'} = 1;
	my %access = &d_access_control(\%mode,$path);
   
	unless ($access{'may'}{'edit'}) {
	    &message('may_not');
	    &wwslog('info','do_d_delete : access denied for %s', $param->{'user'}{'email'});
	    return undef;
	}

	# removing of the document
	unless (unlink($doc)) {
	    &message('failed');
	    &wwslog('info','do_d_delete: failed to erase %s', $doc);
	    return undef;
	}
	# removing of the description file if exists
	if (-e "$shareddir/$current_directory.desc.$document") {
	    unless (unlink("$shareddir/$current_directory.desc.$document")) {
		&wwslog('info',"do_d_delete: failed to erase $shareddir/$current_directory.desc.$document");
	    }
	}   
    }

    
    $in{'list'} = $list_name;
    $in{'path'} = $current_directory;
    return 'd_read';
}

#*******************************************
# Function : do_d_create_dir
# Description : Creates a new directory
#******************************************
sub do_d_create_dir {
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_create_dir(%s)', $in{'name_doc'});
  
      #useful variables
    my $expl = $Conf{'home'};
    my $path = lc($in{'path'});
    ## $path must have a slash at its end
    $path = &format_path('with_slash',$path);

    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};
    my $name_doc = $in{'name_doc'};
    
    # Lowercase for directory name
    $name_doc = lc($name_doc);

    $param->{'list'} = $list_name;
    $param->{'path'} = $path;
    
### Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_create_dir : no list');
	return undef;
    }

     # Must be a directory to create (directory name not empty)
    unless ($name_doc) {
	&message('no_name');
	&wwslog('info',"do_d_create_dir : Unable to create directory : no name specified!");
	return undef;
    }

    # The name of the directory must be correct
    unless ($name_doc =~ /^\w/ and 
	    $name_doc =~ /\w$/ and 
	    $name_doc =~ /^[\w\-\.]+$/ and
	    $name_doc !~ /\.desc/) {
	&message('incorrect_name', {'name' => $name_doc});
	&wwslog('info',"do_d_create_dir : Unable to create directory $name_doc : incorrect name");
	return undef;
    }

     	
    # Access control
    my %mode;
    $mode{'edit'} = 1;
    my %access = &d_access_control(\%mode,$path);
    
    unless ($access{'may'}{'edit'}) {
	&message('may_not');
	&wwslog('info','do_d_create_dir :  access denied for %s', $param->{'user'}{'email'});
	return undef;
    }



### End of controls
    
    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';
    
    my $document = "$shareddir/$path$name_doc";
    
    $param->{'document'} = $document;
      	
    # Creation of the new directory
    unless (mkdir ("$document",0777)) {
	&message('cannot_create_dir', {'path' => $document,
				       'reason' => $!});
	&wwslog('info',"do_d_create_dir : Unable to create $document : $!");
	return undef;
    }

    # Creation of a default description file 
    unless (open (DESC,">$document/.desc")) {
	&message('failed');
	&wwslog('info','do_d_create_dir : annot create description file %s', $document.'/.desc');
    }

    print DESC "title\n \n\n"; 
    print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 
      
    print DESC "access\n";
    print DESC "  read $access{'scenario'}{'read'}\n";
    print DESC "  edit $access{'scenario'}{'edit'}\n\n";  
    
    close DESC;

    return 'd_read';
}



############## Control


#*******************************************
# Function : do_d_control
# Description : prepares the parameters
#               to edit access for a doc
#*******************************************

sub do_d_control {
    &wwslog('debug', "do_d_control $in{'path'}");

    # Variables
    my $expl = $Conf{'home'};
    my $path = lc($in{'path'});
    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};
       
    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';
    ## $path must have no slash at its end
    $path = &format_path('without_slash',$path);


    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_control: no list');
	return undef;
    }

    unless ($path) {
	&message('missing_arg', {'argument' => 'document_name'});
	&wwslog('info','do_d_control: no document name');
	return undef;
    }   

    # Existing document? 
    unless (-e "$shareddir/$path") {
	&message('no_such_document', {'path' => $path});
	&wwslog('info',"do_d_control : Cannot control $shareddir/$path : not an existing document");
	return undef;
    }

    ### Document isn't a description file?
    unless ($path !~ /\.desc/) {
	&wwslog('info',"do_d_control : $shareddir/$path : description file");
	&message('no_such_document', {'path' => $path});
	return undef;
    }
    
    # Access control
    my %mode;
    $mode{'control'} = 1;
    my %access = &d_access_control(\%mode,$path);
    unless ($access{'may'}{'control'}) {
	&message('may_not');
	&wwslog('info','d_control : access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

   
 ## End of controls

    
    #Current directory
    $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
    $param->{'father'} = $1;    
    
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
    $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[10]));;

    # template parameters
    $param->{'list'} = $list_name;
    $param->{'path'} = $path;
    
    my $lang = $param->{'lang'};

    ## Scenario list for READ
    #XXXXXX SHOULD use List::load_scenario_list()
    my $read_scenario_list = $list->load_scenario_list('d_read');
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
    #XXXXXX SHOULD use List::load_scenario_list()
    my $edit_scenario_list = $list->load_scenario_list('d_edit');
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
    $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
    $param->{'father'} = $1;    

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
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_change_access(%s)', $in{'path'});

    # Variables
    my $expl = $Conf{'home'};

    my $path = lc($in{'path'});
    ## $path must have no slash at its end
    $path = &format_path('without_slash',$path);

    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};

    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

####  Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_change_access: no list');
	return undef;
    }

       
    ## the path must not be empty (the description file of the shared directory
    #  doesn't exist)
    unless ($path) {
	&message('failed');
	&wwslog('info',"do_d_change_access : Cannot change access $shareddir : root directory");
	return undef;
    }

    # the document to describe must already exist 
    unless (-e "$shareddir/$path") {
	&message('failed');
	&wwslog('info',"d_change_access : Unable to change access $shareddir/$path : no such document");
	return undef;
    }

    
    # Access control
    my %mode;
    $mode{'control'} = 1;
    my %access = &d_access_control(\%mode,$path);
       
    unless ($access{'may'}{'control'}) {
	&message('may_not');
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
	    &message('synchro_failed');
	    &wwslog('info',"d_change_access : Synchronization failed for $desc_file");
	    return undef;
	}
	
	unless (open DESC,">$desc_file") {
	    &wwslog('info',"d_change_access : cannot open $desc_file : $!");
	    &message('failed');
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
	    &message('failed');
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
    #action_args == ['list','@path']
    &wwslog('debug', 'do_d_set_owner(%s)', $in{'path'});
    
    # Variables
    my $desc_file;
    my $expl = $Conf{'home'};

    my $path = lc($in{'path'});
    ## $path must have no slash at its end
    $path = &format_path('without_slash',$path);

    #my $list_name = $in{'list'};
    my $list_name = $list->{'name'};

    # path of the shared directory
    my $shareddir =  $expl.'/'.$list_name.'/shared';

####  Controls
    ### action relative to a list ?
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_d_set_owner: no list');
	return undef;
    }

       
    ## the path must not be empty (the description file of the shared directory
    #  doesn't exist)
    unless ($path) {
	&message('failed');
	&wwslog('info',"do_d_set_owner : Cannot change access $shareddir : root directory");
	return undef;
    }

    # the email must look like an email "somebody@somewhere"
    unless ($in{'content'} =~ /^[\w\.\-\~]+\@[\w\.\-\~]+$/) {
	&message('incorrect_email', {'email' => $in{'content'}});
	&wwslog('info',"d_set_owner : $in{'content'} : incrorrect email");
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
	&message('may_not');
	&wwslog('info','d_set_owner : access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

    my $may_set = 1;
   
    unless ($may_set) {
	&message('full_directory', {'directory' => $path});
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
	    &message('synchro_failed');
	    &wwslog('info',"d_set_owner : Synchronization failed for $desc_file");
	    return undef;
	}
	
	unless (open DESC,">$desc_file") {
	    &wwslog('info',"d_set_owner : cannot open $desc_file : $!");
	    &message('failed');
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
	    &message('failed');
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
    &wwslog('debug', 'do_arc_protect()');

    return 1;
} 

## Show a state of template translations
sub do_view_translations {
     &wwslog('debug', 'do_view_translations()');
     my %lang = ('default' => 1);

     foreach my $tpl (<--ETCBINDIR--/wws_templates/*.tpl>) {
	 $tpl =~ s/^.*\/([^\/]+)$/$1/;
	 my @token = split /\./, $tpl;
	 if ($#token == 2) {
	     $param->{'tpl'}{$token[0]}{$token[1]} = 'bin';
	     $lang{$token[1]} = 1;
	 }else {
	     $param->{'tpl'}{$token[0]}{'default'} = 'bin';
	 }
     }

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
    &wwslog('debug', 'do_remind()');

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_remind: no list');
	return undef;
    }
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_remind: no user');
	return 'loginrequest';
    }
    
    ## Access control
    unless (&List::request_action ('remind',$param->{'auth_method'},
				   {'listname' => $param->{'list'},
				    'sender' => $param->{'user'}{'email'},
				    'remote_host' => $param->{'remote_host'},
				    'remote_addr' => $param->{'remote_addr'}}) =~ /do_it/i) {
	&message('may_not');
	&wwslog('info','do_remind: access denied for %s', $param->{'user'}{'email'});
	return undef;
    }

    my $extention = time.".".int(rand 9999) ;
    my $mail_command;

    ## Sympa will require a confirmation
    if (&List::request_action ('remind','smtp',
				   {'listname' => $param->{'list'},
				    'sender' => $param->{'user'}{'email'},
				    'remote_host' => $param->{'remote_host'},
				    'remote_addr' => $param->{'remote_addr'}}) =~ /reject/i) {
	
	&message('may_not');
	&wwslog('info','remind : access denied for %s', $param->{'user'}{'email'});
	return undef;

    }else {
	$mail_command = sprintf "REMIND %s", $param->{'list'};
    }

    open REMIND, ">$Conf{'queue'}/T.$Conf{'sympa'}.$extention" ;
    
    printf REMIND ("X-Sympa-To: %s\n",$Conf{'sympa'});
    printf REMIND ("Message-Id: <%s\@wwsympa>\n", time);
    printf REMIND ("From: %s\n\n", $param->{'user'}{'email'});

    printf REMIND "$mail_command\n";

    close REMIND;

    rename("$Conf{'queue'}/T.$Conf{'sympa'}.$extention","$Conf{'queue'}/$Conf{'sympa'}.$extention");

    &message('performed_soon');

    return 'admin';
}

## Load list certificat
sub do_load_cert {
    &wwslog('debug','do_load_cert(%s)', $param->{'list'});

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_load_cert: no list');
	return undef;
    }
    my @cert = $list->get_cert();
    unless (@cert) {
	&message('missing_cert');
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
    &wwslog('debug','do_change_email(%s)', $in{'email'});
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_change_password: user not logged in');
	return undef;
    }
    
    unless ($in{'email'}) {
	&message('no_email');
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
	    &message('incorrect_passwd');
	    &wwslog('info','do_change_email: incorrect password for user %s', $in{'email'});
	    return undef;
	}

	## Change email
	foreach my $l ( &List::get_which($param->{'user'}{'email'}, 'member') ) {
	    my $list = new List ($l);
	    
	    unless ($list->update_user($param->{'user'}{'email'}, {'email' => $in{'email'}}) ) {
		&message('failed');
		&wwslog('info', 'do_change_email: update failed');
		return undef;
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
	    &message('update_failed');
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

	unless (open MAIL, "|$Conf{'sendmail'} $in{'email'}") {
	    &message('mail_error');
	    &wwslog('info','do_change_email: mail error');
	    return undef;
	}    
	
	my $tpl_file;
        
	foreach my $tpldir ("$Conf{'home'}/$param->{'list'}/wws_templates","$Conf{'etc'}/wws_templates","--ETCBINDIR--/wws_templates") {
	    if (-f "$tpldir/msg_sendpasswd.$param->{'lang'}.tpl") {
		$tpl_file = "$tpldir/msg_sendpasswd.$param->{'lang'}.tpl";
		last;
	    }
	    if (-f "$tpldir/msg_sendpasswd.tpl") {
		$tpl_file = "$tpldir/msg_sendpasswd.tpl";
		last;
	    }
	}
	
	&parse_tpl ($param, $tpl_file, MAIL);
	close MAIL;

	$param->{'email'} = $in{'email'};

	return 'change_email';
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
    &wwslog('debug', 'do_compose_mail');

    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_compose_mail: no user');
	$param->{'previous_action'} = 'compose_mail';
	return 'loginrequest';
    }

    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_compose_mail: no list');
	return undef;
    }

    unless ($param->{'may_post'}) {
	&message('may_not');
	&wwslog('info','do_compose_mail: may not send message');
	return undef;
    }

    $param->{'to'} = $list->{'name'} . '@' . $list->{'admin'}{'host'};
    
    return 1;
}

sub do_send_mail {
    &wwslog('debug', 'do_send_mail');
    
    unless ($param->{'user'}{'email'}) {
	&message('no_user');
	&wwslog('info','do_send_mail: no user');
	$param->{'previous_action'} = 'send_mail';
	return 'loginrequest';
    }
    
    unless ($param->{'list'}) {
	&message('missing_arg', {'argument' => 'list'});
	&wwslog('info','do_send_mail: no list');
	return undef;
    }
    
    unless ($param->{'may_post'}) {
	&message('may_not');
	&wwslog('info','do_send_mail: may not send message');
	return undef;
    }

    my @body = split /\0/, $in{'body'};
    my $to = $list->{'name'}.'@'.$list->{'admin'}{'host'};

    &mail::mailback(\@body, $in{'subject'}, $param->{'user'}{'email'}, $to, $to);

    &message('performed');
    return 'info';
}
