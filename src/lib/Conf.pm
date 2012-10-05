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

use Exporter;
use Carp;
use Storable;

use List;
use SDM;
use Log;
use Language;
use wwslib;
use confdef;
use tools;
use Sympa::Constants;
use Data::Dumper;

our @ISA = qw(Exporter);
our @EXPORT = qw(%params %Conf DAEMON_MESSAGE DAEMON_COMMAND DAEMON_CREATION DAEMON_ALL);

sub DAEMON_MESSAGE {1};
sub DAEMON_COMMAND {2};
sub DAEMON_CREATION {4};
sub DAEMON_ALL {7};

## Database and SQL statement handlers
my $sth;
# parameters hash, keyed by parameter name
our %params =
    map  { $_->{name} => $_ }
    grep { $_->{name} }
    @confdef::params;

# valid virtual host parameters, keyed by parameter name
my %valid_robot_key_words;
my %db_storable_parameters;
my %optional_key_words;
foreach my $hash(@confdef::params){
    $valid_robot_key_words{$hash->{'name'}} = 1 if ($hash->{'vhost'});    
    $db_storable_parameters{$hash->{'name'}} = 1 if (defined($hash->{'db'}) and $hash->{'db'} ne 'none');
    $optional_key_words{$hash->{'name'}} = 1 if ($hash->{'optional'}); 
}

our $params_by_categories = &_get_parameters_names_by_category();

my %old_params = (
    trusted_ca_options     => 'capath,cafile',
    msgcat                 => 'localedir',
    queueexpire            => '',
    clean_delay_queueother => '',
    pidfile_distribute     => '',
    pidfile_creation       => '',
    dkim_header_list => '',
    web_recode_to          => 'filesystem_encoding',
);

## These parameters now have a hard-coded value
## Customized value can be accessed though as %Ignored_Conf
my %Ignored_Conf;
my %hardcoded_params = (
    filesystem_encoding => 'utf8'
);

my %trusted_applications = ('trusted_application' => {
                                'occurrence' => '0-n',
                                'format' => {
                                    'name' => {
                                        'format' => '\S*',
                                        'occurrence' => '1',
                                        'case' => 'insensitive',
                                        },
                                    'ip'   => {
                                        'format' => '\d+\.\d+\.\d+\.\d+',
                                        'occurrence' => '0-1'
                                        },
                                    'md5password' => {
                                        'format' => '.*',
                                        'occurrence' => '0-1'
                                        },
                                    'proxy_for_variables'=> {
                                        'format' => '.*',        
                                        'occurrence' => '0-n',
                                        'split_char' => ','
                                        }
                                    }
                                }
                            );
my $binary_file_extension = ".bin";


my $wwsconf = &wwslib::load_config(Sympa::Constants::WWSCONFIG);
our %Conf = ();

## Loads and parses the configuration file. Reports errors if any.
# do not try to load database values if $no_db is set ;
# do not change gloval hash %Conf if $return_result  is set ;
# we known that's dirty, this proc should be rewritten without this global var %Conf
sub load {
    my $config_file = shift;
    my $no_db = shift;
    my $return_result = shift;
    my $force_reload;

    my $config_err = 0;
    my %line_numbered_config;

    if(_source_has_not_changed({'config_file' => $config_file}) && !$return_result) {
        ##printf "Conf::load(): File %s has not changed since the last cache. Using cache.\n",$config_file;
        if (my $tmp_conf = _load_binary_cache({'config_file' => $config_file.$binary_file_extension})){
            %Conf = %{$tmp_conf};
            $force_reload = 1; # Will force the robot.conf reloading, as sympa.conf is the default.
        }else{
            printf STDERR "Binary config file loading failed while loading source file '%s'\n",$config_file;
        }
    }else{
        printf "Conf::load(): File %s has changed since the last cache. Loading file.\n",$config_file;
        $force_reload = 1; # Will force the robot.conf reloading, as sympa.conf is the default.
        ## Loading the Sympa main config file.
        if(my $config_loading_result = &_load_config_file_to_hash({'path_to_config_file' => $config_file})) {
            %line_numbered_config = %{$config_loading_result->{'numbered_config'}};
            %Conf = %{$config_loading_result->{'config'}};
            $config_err = $config_loading_result->{'errors'};
        }else{
            printf STDERR  "Conf::load(): Unable to load %s. Aborting\n", $config_file;
            return undef;
        }
        # Returning the config file content if this is what has been asked.
        return (\%line_numbered_config) if ($return_result);

        # Users may define parameters with a typo or other errors. Check that the parameters
        # we found in the config file are all well defined Sympa parameters.
        $config_err += &_detect_unknown_parameters_in_config(
                                {
                                    'config_hash' => \%Conf,
                                    'config_file_line_numbering_reference' => \%line_numbered_config,
                                });
    
        # Some parameter values are hardcoded. In that case, ignore what was
        #  set in the config file and simply use the hardcoded value.
        %Ignored_Conf = %{&_set_hardcoded_parameter_values({'config_hash' => \%Conf,})};

        &_set_listmasters_entry({'config_hash' => \%Conf, 'main_config' => 1});
    
        ## Some parameters must have a value specifically defined in the config. If not, it is an error.
        $config_err += &_detect_missing_mandatory_parameters({'config_hash' => \%Conf,'file_to_check' => $config_file});

        # Some parameters need special treatments to get their final values.
        &_infer_server_specific_parameter_values({'config_hash' => \%Conf,});
        
        &_infer_robot_parameter_values({'config_hash' => \%Conf});

        if ($config_err) {
            printf STDERR "Errors while parsing main config file %s\n",$config_file;
            return undef;
        }

        &_store_source_file_name({'config_hash' => \%Conf,'config_file' => $config_file});
        &_save_config_hash_to_binary({'config_hash' => \%Conf,});
    }

    if (my $missing_modules_count = &_check_cpan_modules_required_by_config({'config_hash' => \%Conf,})){
        printf STDERR "Conf::load(): Warning: %n required modules are missing.\n",$missing_modules_count;
    }

    &_replace_file_value_by_db_value({'config_hash' => \%Conf}) unless($no_db);
    &_load_server_specific_secondary_config_files({'config_hash' => \%Conf,});
    &_load_robot_secondary_config_files({'config_hash' => \%Conf});

    ## Load robot.conf files
    unless (&load_robots({'config_hash' => \%Conf, 'no_db' => $no_db, 'force_reload' => $force_reload})){
        printf STDERR "Unable to load robots\n";
        return undef;
    }
    ##&_create_robot_like_config_for_main_robot();
    return 1;
}

## load each virtual robots configuration files
sub load_robots {
    my $param = shift;
    my @robots;

    my $robots_list_ref = &get_robots_list();
    unless (defined $robots_list_ref) {
        printf STDERR "robots config loading failed.\n";
        return undef;
    }else {
        @robots = @{$robots_list_ref};
    }
    unless ($#robots > -1) {
        return 1;
    }
    my $exiting = 0;
    foreach my $robot (@robots) {
        my $robot_config_file = "$Conf{'etc'}/$robot/robot.conf";
        my $robot_conf = undef;
        unless ($robot_conf = &_load_single_robot_config({'robot' => $robot, 'no_db' => $param->{'no_db'}, 'force_reload' => $param->{'force_reload'}})) {
            printf STDERR "The config for robot %s contain errors: it could not be correctly loaded.\n";
            $exiting = 1;
        }else{
            $param->{'config_hash'}{'robots'}{$robot} = $robot_conf;
        }
        &_check_double_url_usage({'config_hash' => $param->{'config_hash'}{'robots'}{$robot}});
    }
    return undef if ($exiting);
    return 1;
}

## returns a robot conf parameter
sub get_robot_conf {
    my ($robot, $param) = @_;

    if (defined $robot && $robot ne '*') {
        if (defined $Conf{'robots'}{$robot} && defined $Conf{'robots'}{$robot}{$param}) {
            return $Conf{'robots'}{$robot}{$param};
        }
    }
    ## default
    return $Conf{$param} || $wwsconf->{$param};
}

# deletes all the *.conf.bin files.
sub delete_binaries {
    &Log::do_log('notice',"Removing binary cache for sympa.conf, wwsympa.conf and all the robot.conf files");
    my @files = (Sympa::Constants::CONFIG,Sympa::Constants::WWSCONFIG);
    foreach my $robot (@{&get_robots_list()}) {
        push @files, "$Conf{'etc'}/$robot/robot.conf";
    }
    foreach my $c_file (@files) {
        my $binary_file = $c_file.".bin";
        if( -f $binary_file) {
            if (-w $binary_file) {
                unlink $binary_file;
            }else {
                &Log::do_log('err',"Could not remove file %s. You should remove it manually to ensure the configuration used is valid.",$binary_file);
            }
        }
    }
}

# Return a reference to an array containing the names of the robots on the server.
sub get_robots_list {
    &Log::do_log('debug2',"Retrieving the list of robots on the server");
    my @robots_list;
    unless (opendir DIR,$Conf{'etc'} ) {
        printf STDERR "Conf::load_robots(): Unable to open directory $Conf{'etc'} for virtual robots config\n" ;
        return undef;
    }
    foreach my $robot (readdir DIR) {
        my $robot_config_file = "$Conf{'etc'}/$robot/robot.conf";
        next unless (-d "$Conf{'etc'}/$robot");
        next unless (-f $robot_config_file);
        push @robots_list, $robot;
    }
    closedir(DIR);
    return \@robots_list;
}

## Returns a hash containing the values of all the parameters of the group
## (as defined in confdef.pm) whose name is given as argument, in the context
## of the robot given as argument.
sub get_parameters_group {
    my ($robot, $group) = @_;
    &Log::do_log('debug3','Getting parameters for group "%s"',$group);
    my $param_hash;
    foreach my $param_name (keys %{$params_by_categories->{$group}}) {
        $param_hash->{$param_name} = &get_robot_conf($robot,$param_name);
    }
    return $param_hash;
}

## fetch the value from parameter $label of robot $robot from conf_table
sub get_db_conf  {

    my $robot = shift;
    my $label = shift;

    # if the value is related to a robot that is not explicitly defined, apply it to the default robot.
    $robot = '*' unless (-f $Conf{'etc'}.'/'.$robot.'/robot.conf') ;
    unless ($robot) {$robot = '*'};

    unless ($sth = &SDM::do_query("SELECT value_conf AS value FROM conf_table WHERE (robot_conf =%s AND label_conf =%s)", &SDM::quote($robot),&SDM::quote($label))) {
        &Log::do_log('err','Unable retrieve value of parameter %s for robot %s from the database', $label, $robot);
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
    
    &Log::do_log('info','Set config for robot %s , %s="%s"',$robot,$label, $value);

    
    # set the current config before to update database.    
    if (-f "$Conf{'etc'}/$robot/robot.conf") {
    $Conf{'robots'}{$robot}{$label}=$value;
    }else{
    $Conf{$label}=$value;    
    $robot = '*' ;
    }

    unless ($sth = &SDM::do_query("SELECT count(*) FROM conf_table WHERE (robot_conf=%s AND label_conf =%s)", &SDM::quote($robot),&SDM::quote($label))) {
        &Log::do_log('err','Unable to check presence of parameter %s for robot %s in database', $label, $robot);
        return undef;
    }

    my $count = $sth->fetchrow;
    $sth->finish();
    
    if ($count == 0) {
        unless ($sth = &SDM::do_query("INSERT INTO conf_table (robot_conf, label_conf, value_conf) VALUES (%s,%s,%s)",&SDM::quote($robot),&SDM::quote($label), &SDM::quote($value))) {
            &Log::do_log('err','Unable add value %s for parameter %s in the robot %s DB conf', $value, $label, $robot);
            return undef;
        }
    }else{
        unless ($sth = &SDM::do_query("UPDATE conf_table SET robot_conf=%s, label_conf=%s, value_conf=%s WHERE ( robot_conf  =%s AND label_conf =%s)",&SDM::quote($robot),&SDM::quote($label),&SDM::quote($value),&SDM::quote($robot),&SDM::quote($label))) {
            &Log::do_log('err','Unable set parameter %s value to %s in the robot %s DB conf', $label, $value, $robot);
            return undef;
        } 
    }
}


# Store configs to database
sub conf_2_db {
    my $config_file = shift;
    &Log::do_log('info',"conf_2_db");

    my @conf_parameters = @confdef::params ;

    # store in database robots parameters.
    my $robots_conf = &load_robots ; #load only parameters that are in a robot.conf file (do not apply defaults). 

    unless (opendir DIR,$Conf{'etc'} ) {
        printf STDERR "Conf::conf2db(): Unable to open directory $Conf{'etc'} for virtual robots config\n" ;
        return undef;
    }

    foreach my $robot (readdir(DIR)) {
        next unless (-d "$Conf{'etc'}/$robot");
        next unless (-f "$Conf{'etc'}/$robot/robot.conf");
        
        my $config;
        if(my $result_of_config_loading = _load_config_file_to_hash({'path_to_config_file' => $Conf{'etc'}.'/'.$robot.'/robot.conf'})){
            $config = $result_of_config_loading->{'config'};
        }
        &_remove_unvalid_robot_entry($config);
        
        for my $i ( 0 .. $#conf_parameters ) {
            if ($conf_parameters[$i]->{'name'}) { #skip separators in conf_parameters structure
            if (($conf_parameters[$i]->{'vhost'} eq '1') && #skip parameters that can't be define by robot so not to be loaded in db at that stage 
                ($config->{$conf_parameters[$i]->{'name'}})){
                &Conf::set_robot_conf($robot, $conf_parameters[$i]->{'name'}, $config->{$conf_parameters[$i]->{'name'}});
            }
            }
        }
    }
    closedir (DIR);

    # store in database sympa;conf and wwsympa.conf
    
    ## Load configuration file. Ignoring database config and get result
    my $global_conf;
    unless ($global_conf= Conf::load($config_file,1,'return_result')) {
    &Log::fatal_err("Configuration file $config_file has errors.");  
    }
    
    for my $i ( 0 .. $#conf_parameters ) {
    if (($conf_parameters[$i]->{'edit'} eq '1') && $global_conf->{$conf_parameters[$i]->{'name'}}) {
        &Conf::set_robot_conf("*",$conf_parameters[$i]->{'name'},$global_conf->{$conf_parameters[$i]->{'name'}}[0]);
    }       
    }
}

## Check required files and create them if required
sub checkfiles_as_root {

  my $config_err = 0;

    ## Check aliases file
    unless (-f $Conf{'sendmail_aliases'} || ($Conf{'sendmail_aliases'} =~ /^none$/i)) {
    unless (open ALIASES, ">$Conf{'sendmail_aliases'}") {
        &Log::do_log('err',"Failed to create aliases file %s", $Conf{'sendmail_aliases'});
        # printf STDERR "Failed to create aliases file %s", $Conf{'sendmail_aliases'};
        return undef;
    }

    print ALIASES "## This aliases file is dedicated to Sympa Mailing List Manager\n";
    print ALIASES "## You should edit your sendmail.mc or sendmail.cf file to declare it\n";
    close ALIASES;
    &Log::do_log('notice', "Created missing file %s", $Conf{'sendmail_aliases'});
    unless (&tools::set_file_rights(file => $Conf{'sendmail_aliases'},
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
                    mode  => 0644,
                    ))
    {
        &Log::do_log('err','Unable to set rights on %s',$Conf{'db_name'});
        return undef;
    }
    }

    foreach my $robot (keys %{$Conf{'robots'}}) {

    # create static content directory
    my $dir = &get_robot_conf($robot, 'static_content_path');
    if ($dir ne '' && ! -d $dir){
        unless ( mkdir ($dir, 0775)) {
        &Log::do_log('err', 'Unable to create directory %s: %s', $dir, $!);
        printf STDERR 'Unable to create directory %s: %s',$dir, $!;
        $config_err++;
        }

        unless (&tools::set_file_rights(file => $dir,
                        user  => Sympa::Constants::USER,
                        group => Sympa::Constants::GROUP,
                        ))
        {
        &Log::do_log('err','Unable to set rights on %s',$Conf{'db_name'});
        return undef;
        }
    }
    }

    return 1 ;
}

## Check a few files
sub checkfiles {
    my $config_err = 0;
    
    foreach my $p ('sendmail','openssl','antivirus_path') {
    next unless $Conf{$p};
    
    unless (-x $Conf{$p}) {
        &Log::do_log('err', "File %s does not exist or is not executable", $Conf{$p});
        $config_err++;
    }
    }
    
    foreach my $qdir ('spool','queue','queueautomatic','queuedigest','queuemod','queuetopic','queueauth','queueoutgoing','queuebounce','queuesubscribe','queuetask','queuedistribute','tmpdir')
    {
    unless (-d $Conf{$qdir}) {
        &Log::do_log('info', "creating spool $Conf{$qdir}");
        unless ( mkdir ($Conf{$qdir}, 0775)) {
        &Log::do_log('err', 'Unable to create spool %s', $Conf{$qdir});
        $config_err++;
        }
            unless (&tools::set_file_rights(
                    file  => $Conf{$qdir},
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
            )) {
                &Log::do_log('err','Unable to set rights on %s',$Conf{$qdir});
        $config_err++;
            }
    }
    }

    ## Also create associated bad/ spools
    foreach my $qdir ('queue','queuedistribute','queueautomatic') {
        my $subdir = $Conf{$qdir}.'/bad';
    unless (-d $subdir) {
        &Log::do_log('info', "creating spool $subdir");
        unless ( mkdir ($subdir, 0775)) {
        &Log::do_log('err', 'Unable to create spool %s', $subdir);
        $config_err++;
        }
            unless (&tools::set_file_rights(
                    file  => $subdir,
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
            )) {
                &Log::do_log('err','Unable to set rights on %s',$subdir);
        $config_err++;
            }
    }
    }

    ## Check cafile and capath access
    if (defined $Conf{'cafile'} && $Conf{'cafile'}) {
    unless (-f $Conf{'cafile'} && -r $Conf{'cafile'}) {
        &Log::do_log('err', 'Cannot access cafile %s', $Conf{'cafile'});
        unless (&List::send_notify_to_listmaster('cannot_access_cafile', $Conf{'domain'}, [$Conf{'cafile'}])) {
        &Log::do_log('err', 'Unable to send notify "cannot access cafile" to listmaster');    
        }
        $config_err++;
    }
    }

    if (defined $Conf{'capath'} && $Conf{'capath'}) {
    unless (-d $Conf{'capath'} && -x $Conf{'capath'}) {
        &Log::do_log('err', 'Cannot access capath %s', $Conf{'capath'});
        unless (&List::send_notify_to_listmaster('cannot_access_capath', $Conf{'domain'}, [$Conf{'capath'}])) {
        &Log::do_log('err', 'Unable to send notify "cannot access capath" to listmaster');    
        }
        $config_err++;
    }
    }

    ## queuebounce and bounce_path pointing to the same directory
    if ($Conf{'queuebounce'} eq $wwsconf->{'bounce_path'}) {
    &Log::do_log('err', 'Error in config: queuebounce and bounce_path parameters pointing to the same directory (%s)', $Conf{'queuebounce'});
    unless (&List::send_notify_to_listmaster('queuebounce_and_bounce_path_are_the_same', $Conf{'domain'}, [$Conf{'queuebounce'}])) {
        &Log::do_log('err', 'Unable to send notify "queuebounce_and_bounce_path_are_the_same" to listmaster');    
    }
    $config_err++;
    }

    #  create pictures dir if usefull for each robot
    foreach my $robot (keys %{$Conf{'robots'}}) {
    my $dir = &get_robot_conf($robot, 'static_content_path');
    if ($dir ne '' && -d $dir) {
        unless (-f $dir.'/index.html'){
        unless(open (FF, ">$dir".'/index.html')) {
            &Log::do_log('err', 'Unable to create %s/index.html as an empty file to protect directory: %s', $dir, $!);
        }
        close FF;        
        }
        
        # create picture dir
        if ( &get_robot_conf($robot, 'pictures_feature') eq 'on') {
        my $pictures_dir = &get_robot_conf($robot, 'pictures_path');
        unless (-d $pictures_dir){
            unless (mkdir ($pictures_dir, 0775)) {
            &Log::do_log('err', 'Unable to create directory %s',$pictures_dir);
            $config_err++;
            }
            chmod 0775, $pictures_dir;

            my $index_path = $pictures_dir.'/index.html';
            unless (-f $index_path){
            unless (open (FF, ">$index_path")) {
                &Log::do_log('err', 'Unable to create %s as an empty file to protect directory', $index_path);
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
        &List::send_notify_to_listmaster('cannot_mkdir',  $robot, ["Could not create directory $dir: $!"]);
        &Log::do_log('err','Failed to create directory %s',$dir);
        return undef;
        }
    }

    foreach my $css ('style.css','print.css','fullPage.css','print-preview.css') {

        $param->{'css'} = $css;
        my $css_tt2_path = &tools::get_filename('etc',{}, 'web_tt2/css.tt2', $robot, undef);
        
        ## Update the CSS if it is missing or if a new css.tt2 was installed
        if (! -f $dir.'/'.$css ||
        (stat($css_tt2_path))[9] > (stat($dir.'/'.$css))[9]) {
        &Log::do_log('notice',"TT2 file $css_tt2_path has changed; updating static CSS file $dir/$css ; previous file renamed");
        
        ## Keep copy of previous file
        rename $dir.'/'.$css, $dir.'/'.$css.'.'.time;

        unless (open (CSS,">$dir/$css")) {
            &List::send_notify_to_listmaster('cannot_open_file',  $robot, ["Could not open file $dir/$css: $!"]);
            &Log::do_log('err','Failed to open (write) file %s',$dir.'/'.$css);
            return undef;
        }
        
        unless (&tt2::parse_tt2($param,'css.tt2' ,\*CSS, $tt2_include_path)) {
            my $error = &tt2::get_error();
            $param->{'tt2_error'} = $error;
            &List::send_notify_to_listmaster('web_tt2_error', $robot, [$error]);
            &Log::do_log('err', "Error while installing $dir/$css");
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
    &List::send_notify_to_listmaster('css_updated',  $Conf{'domain'}, ["Static CSS files have been updated ; check log file for details"]);
    }


    return undef if ($config_err);
    return 1;
}

## return 1 if the parameter is a known robot
## Valid options : 
##    'just_try' : prevent error logs if robot is not valid
sub valid_robot {
    my $robot = shift;
    my $options = shift;

    ## Main host
    return 1 if ($robot eq $Conf{'domain'});

    ## Missing etc directory
    unless (-d $Conf{'etc'}.'/'.$robot) {
    &Log::do_log('err', 'Robot %s undefined ; no %s directory', $robot, $Conf{'etc'}.'/'.$robot) unless ($options->{'just_try'});
    return undef;
    }

    ## Missing expl directory
    unless (-d $Conf{'home'}.'/'.$robot) {
    &Log::do_log('err', 'Robot %s undefined ; no %s directory', $robot, $Conf{'home'}.'/'.$robot) unless ($options->{'just_try'});
    return undef;
    }
    
    ## Robot not loaded
    unless (defined $Conf{'robots'}{$robot}) {
    &Log::do_log('err', 'Robot %s was not loaded by this Sympa process', $robot) unless ($options->{'just_try'});
    return undef;
    }

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
    &Log::do_log('notice', "SSO: $sso->{'service_id'}");
    next unless ($sso->{'service_id'} eq $param{'service_id'});

    return $sso;
    }
    
    return undef;
}

##########################################
## Low level subs. Not supposed to be called from other modules.
##########################################

sub _load_auth {
    
    my $robot = shift;
    my $is_main_robot = shift;
    # find appropriate auth.conf file
    my $config_file = &_get_config_file_name({'robot' => $robot, 'file' => "auth.conf"});
    &Log::do_log('debug', 'Conf::_load_auth(%s)', $config_file);

    $robot ||= $Conf{'domain'};
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
                    'auth_service_name' => '[\w\-\.]+',
                    'auth_service_friendly_name' => '.*',
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
                        'http_header_list' => '[\w\.\-\,]+',
                        'email_http_header' => '\w+',
                        'http_header_value_separator' => '.+',
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
                        'netid_http_header' => '[\w\-\.]+',
                    },
              'authentication_info_url' => 'http(s)?:/.*'
              );
    


    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config_file)) {
    &Log::do_log('notice',"_load_auth: Unable to open %s: %s", $config_file, $!);
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
        &Log::do_log('err',"_load_auth: unknown keyword '%s' in %s line %d", $keyword, $config_file, $line_num);
        next;
        }
        unless ($value =~ /^$valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}$/) {
        &Log::do_log('err',"_load_auth: unknown format '%s' for keyword '%s' in %s line %d", $value, $keyword, $config_file,$line_num);
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
            &Log::do_log('err','Incorrect CAS paragraph in auth.conf');
            next;
            }

            eval "require AuthCAS";
            if ($@) {
                &Log::do_log('err', 'Failed to load AuthCAS perl module');
                return undef;
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
            
            $current_paragraph->{'cas_server'} = new AuthCAS(%{$cas_param});
            unless (defined $current_paragraph->{'cas_server'}) {
            &Log::do_log('err', 'Failed to create CAS object for %s: %s', 
                $current_paragraph->{'base_url'}, &AuthCAS::get_errors());
            next;
            }

            $Conf{'cas_number'}{$robot}  ++ ;
            $Conf{'cas_id'}{$robot}{$current_paragraph->{'auth_service_name'}} =  $#paragraphs+1 ; 

	    ## Default value for auth_service_friendly_name IS auth_service_name
	    $Conf{'cas_id'}{$robot}{$current_paragraph->{'auth_service_name'}}{'auth_service_friendly_name'} = $current_paragraph->{'auth_service_friendly_name'} || $current_paragraph->{'auth_service_name'};

            $current_paragraph->{'ldap_scope'} ||= 'sub'; ## Force the default scope because '' is interpreted as 'base'
        }elsif($current_paragraph->{'auth_type'} eq 'generic_sso') {         
          $Conf{'generic_sso_number'}{$robot}  ++ ;
          $Conf{'generic_sso_id'}{$robot}{$current_paragraph->{'service_id'}} =  $#paragraphs+1 ; 
          $current_paragraph->{'ldap_scope'} ||= 'sub'; ## Force the default scope because '' is interpreted as 'base'
          $current_paragraph->{'http_header_value_separator'} ||= ';'; ## default value for http_header_value_separator is ';'
          
          ## CGI.pm changes environment variable names ('-' => '_')
          ## declared environment variable names needs to be transformed accordingly
          foreach my $parameter ('http_header_list','email_http_header','netid_http_header') {
                        $current_paragraph->{$parameter} =~ s/\-/\_/g if (defined $current_paragraph->{$parameter});
          }
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

## load charset.conf file (charset mapping for service messages)
sub load_charset {
    my $charset = {};

    my $config_file = &_get_config_file_name({'robot' => '', 'file' => "charset.conf"});
    if (-f $config_file) {
    unless (open CONFIG, $config_file) {
        printf STDERR 'Conf::load_charset(): Unable to read configuration file %s: %s\n',$config_file, $!;
        return {};
    }
    while (<CONFIG>) {
        chomp $_;
        s/\s*#.*//;
        s/^\s+//;
        next unless /\S/;
        my ($locale, $cset) = split(/\s+/, $_);
        unless ($cset) {
        printf STDERR 'Conf::load_charset(): Charset name is missing in configuration file %s line %d\n',$config_file, $.;
        next;
        }
        unless ($locale =~ s/^([a-z]+)_([a-z]+)/lc($1).'_'.uc($2).$'/ei) { #'
        printf STDERR 'Conf::load_charset():  Illegal locale name in configuration file %s line %d\n',$config_file, $.;
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
  my $config_file = &_get_config_file_name({'robot' => '', 'file' => "nrcpt_by_domain.conf"});
  return undef unless  (-r $config_file);
  my $line_num = 0;
  my $config_err = 0;
  my $nrcpt_by_domain ; 
  my $valid_dom = 0;

  return undef unless (-f $config_file) ;
  ## Open the configuration file or return and read the lines.
  unless (open(IN, $config_file)) {
      printf STDERR  "Conf::load_nrcpt_by_domain(): : Unable to open %s: %s\n", $config_file, $!;
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
      printf STDERR gettext("Conf::load_nrcpt_by_domain(): Error at line %d: %s"), $line_num, $config_file, $_;
      $config_err++;
      }
  } 
  close(IN);
  return ($nrcpt_by_domain);
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

## load automatic_list_description.conf configuration file
sub load_automatic_lists_description {
    my $robot = shift;
    my $family = shift;
    &Log::do_log('debug2','Starting: robot %s family %s',$robot,$family);
    
    my %automatic_lists_params = (
	'class' => {
	    'occurrence' => '1-n',
	    'format' => { 
		'name' => {'format' => '.*', 'occurrence' => '1', },
		'stamp' => {'format' => '.*', 'occurrence' => '1', },
		'description' => {'format' => '.*', 'occurrence' => '1', },
		'order' => {'format' => '\d+', 'occurrence' => '1',  },
		'instances' => {'occurrence' => '1','format' => '.*',},
		    #'format' => {
			#'instance' => {
			    #'occurrence' => '1-n',
			    #'format' => {
				#'value' => {'format' => '.*', 'occurrence' => '1', },
				#'tag' => {'format' => '.*', 'occurrence' => '1', },
				#'order' => {'format' => '\d+', 'occurrence' => '1',  },
				#},
			    #},
			#},
		},
	    },
	);
    # find appropriate automatic_lists_description.tt2 file
    my $config ;
    if (defined $robot) {
	$config = $Conf{'etc'}.'/'.$robot.'/families/'.$family.'/automatic_lists_description.conf';
    }else{
	$config = $Conf{'etc'}.'/families/'.$family.'/automatic_lists_description.conf';
    }
    return undef unless  (-r $config);
    my $description = &load_generic_conf_file($config,\%automatic_lists_params);

    ## Now doing some structuration work because Conf::load_automatic_lists_description() can't handle
    ## data structured beyond one level of hash. This needs to be changed.
    my @structured_data;
    foreach my $class (@{$description->{'class'}}){
	my @structured_instances;
	my @instances = split '%%%',$class->{'instances'};
	my $default_found = 0;
	foreach my $instance (@instances) {
	    my $structured_instance;
	    my @instance_params = split '---',$instance;
	    foreach my $instance_param (@instance_params) {
		$instance_param =~ /^\s*(\S+)\s+(.*)\s*$/;
		my $key = $1;
		my $value = $2;
		$key =~ s/^\s*//;
		$key =~ s/\s*$//;
		$value =~ s/^\s*//;
		$value =~ s/\s*$//;
		$structured_instance->{$key} = $value;
	    }
	    $structured_instances[$structured_instance->{'order'}] = $structured_instance;
	    if (defined $structured_instance->{'default'}) {
		$default_found = 1;
	    }
	}
	unless($default_found) {$structured_instances[0]->{'default'} = 1;}
	$class->{'instances'} = \@structured_instances;
	$structured_data[$class->{'order'}] = $class;
    }
    $description->{'class'} = \@structured_data;
    return $description;
}


## load trusted_application.conf configuration file
sub load_trusted_application {
    my $robot = shift;
    
    # find appropriate trusted-application.conf file
    my $config_file = &_get_config_file_name({'robot' => $robot, 'file' => "trusted_applications.conf"});
    return undef unless  (-r $config_file);
    # print STDERR "load_trusted_applications $config_file ($robot)\n";

    return undef unless  (-r $config_file);
    # open TMP, ">/tmp/dump1";&tools::dump_var(&load_generic_conf_file($config_file,\%trusted_applications);, 0,\*TMP);close TMP;
    return (&load_generic_conf_file($config_file,\%trusted_applications));

}


## load trusted_application.conf configuration file
sub load_crawlers_detection {
    my $robot = shift;

    my %crawlers_detection_conf = ('user_agent_string' => {'occurrence' => '0-n',
                          'format' => '.+'
                          } );
        
    my $config_file = &_get_config_file_name({'robot' => $robot, 'file' => "crawlers_detection.conf"});
    return undef unless  (-r $config_file);
    my $hashtab = &load_generic_conf_file($config_file,\%crawlers_detection_conf);
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
#      -$structure_ref (+): ref(HASH) describing expected syntax
#      -$on_error: optional. sub returns undef if set to 'abort'
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

    ## Parse each paragraph
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
    $value = lc($value) if (defined $p->{'case'} && $p->{'case'} eq 'insensitive'); 
    
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

## Simply load a config file and returns a hash.
## the returned hash contains two keys:
## 1- the key 'config' points to a hash containing the data found in the config file.
## 2- the key 'numbered_config' points to a hash containing the data found in the config file. Each entry contains both the value of a parameter and the line where it was found in the config file.
## 3- the key 'errors' contains the number of config entries that could not be loaded, due to an error.
## Returns undef if something went wrong while attempting to read the file.
sub _load_config_file_to_hash {
    my $param = shift;
    my $result;
    $result->{'errors'} = 0;
    my $line_num = 0;
    ## Open the configuration file or return and read the lines.
    unless (open(IN, $param->{'path_to_config_file'})) {
        printf STDERR  "Conf::_load_config_file_to_hash(): Unable to open %s: %s\n", $param->{'path_to_config_file'}, $!;
        return undef;
    }
    while (<IN>) {
        $line_num++;
        # skip empty or commented lines
        next if (/^\s*$/ || /^[\#;]/);
        # match "keyword value" pattern
        if (/^(\S+)\s+(.+)$/) {
            my ($keyword, $value) = ($1, $2);
            $value =~ s/\s*$//;
            ##  'tri' is a synonym for 'sort'
            ## (for compatibility with older versions)
            $keyword = 'sort' if ($keyword eq 'tri');
            ##  'key_password' is a synonym for 'key_passwd'
            ## (for compatibilyty with older versions)
            $keyword = 'key_passwd' if ($keyword eq 'key_password');
            ## Special case: `command`
            if ($value =~ /^\`(.*)\`$/) {
                $value = qx/$1/;
                chomp($value);
            }
            if(exists $params{$keyword} && defined $params{$keyword}{'multiple'} && $params{$keyword}{'multiple'} == 1){
                if(defined $result->{'config'}{$keyword}) {
                    push @{$result->{'config'}{$keyword}}, $value;
                    push @{$result->{'numbered_config'}{$keyword}}, [$value, $line_num];
                }else{
                    $result->{'config'}{$keyword} = [$value];
                    $result->{'numbered_config'}{$keyword} = [[$value, $line_num]];
                }
            }else{
                $result->{'config'}{$keyword} = $value;
                $result->{'numbered_config'}{$keyword} = [ $value, $line_num ];
            }
        } else {
            printf STDERR  "Conf::_load_config_file_to_hash(): ".gettext("Error at line %d: %s\n"), $line_num, $param->{'path_to_config_file'}, $_;
            $result->{'errors'}++;
        }
    }
    close(IN);
    return $result;
}

## Checks a hash containing a sympa config and removes any entry that
## is not supposed to be defined at the robot level.
sub _remove_unvalid_robot_entry {
    my $param = shift;
    my $config_hash = $param->{'config_hash'};
    foreach my $keyword(keys %$config_hash) {
        unless($valid_robot_key_words{$keyword}) {
            printf STDERR "Conf::_remove_unvalid_robot_entry(): removing unknown robot keyword $keyword\n" unless ($param->{'quiet'});
            delete $config_hash->{$keyword};
        }
    }
    return 1;
}

sub _detect_unknown_parameters_in_config {
    my $param = shift;
    my $number_of_unknown_parameters_found = 0;
    foreach my $parameter (sort keys %{$param->{'config_hash'}}) {
        next if (exists $params{$parameter});
        if (defined $old_params{$parameter}) {
            if ($old_params{$parameter}) {
                printf STDERR  "Conf::_detect_unknown_parameters_in_config(): Line %d of sympa.conf, parameter %s is no more available, read documentation for new parameter(s) %s\n", $param->{'config_file_line_numbering_reference'}{$parameter}[1], $parameter, $old_params{$parameter};
            }else {
                printf STDERR  "Conf::_detect_unknown_parameters_in_config(): Line %d of sympa.conf, parameter %s is now obsolete\n", $param->{'config_file_line_numbering_reference'}{$parameter}[1], $parameter;
                next;
            }
        }else {
            printf STDERR  "Conf::_detect_unknown_parameters_in_config(): Line %d, unknown field: %s in sympa.conf\n", $param->{'config_file_line_numbering_reference'}{$parameter}[1], $parameter;
        }
        $number_of_unknown_parameters_found++;
    }
    return $number_of_unknown_parameters_found;
}

sub _infer_server_specific_parameter_values {
    my $param = shift;
    
    $param->{'config_hash'}{'robot_name'} = '';

    $param->{'config_hash'}{'pictures_url'} ||= $param->{'config_hash'}{'static_content_url'}.'/pictures/';
    $param->{'config_hash'}{'pictures_path'} ||= $param->{'config_hash'}{'static_content_path'}.'/pictures/';

    unless ( (defined $param->{'config_hash'}{'cafile'}) || (defined $param->{'config_hash'}{'capath'} )) {
        $param->{'config_hash'}{'cafile'} = Sympa::Constants::DEFAULTDIR . '/ca-bundle.crt';
    } 
    
    unless ($param->{'config_hash'}{'DKIM_feature'} eq 'on'){
        # dkim_signature_apply_ on nothing if DKIM_feature is off
        $param->{'config_hash'}{'dkim_signature_apply_on'} = ['']; # empty array
    }

    ## Set Regexp for accepted list suffixes
    if (defined ($param->{'config_hash'}{'list_check_suffixes'})) {
        $param->{'config_hash'}{'list_check_regexp'} = $param->{'config_hash'}{'list_check_suffixes'};
        $param->{'config_hash'}{'list_check_regexp'} =~ s/[,\s]+/\|/g;
    }
    
    my $p = 1;
    foreach (split(/,/, $param->{'config_hash'}{'sort'})) {
        $param->{'config_hash'}{'poids'}{$_} = $p++;
    }
    $param->{'config_hash'}{'poids'}{'*'} = $p if ! $param->{'config_hash'}{'poids'}{'*'};
    
    ## Parameters made of comma-separated list
    foreach my $parameter ('rfc2369_header_fields','anonymous_header_fields','remove_headers','remove_outgoing_headers') {
        if ($param->{'config_hash'}{$parameter} eq 'none') {
            delete $param->{'config_hash'}{$parameter};
        }else {
            $param->{'config_hash'}{$parameter} = [split(/,/, $param->{'config_hash'}{$parameter})];
        }
    }

    foreach my $action (split(/,/, $param->{'config_hash'}{'use_blacklist'})) {
        $param->{'config_hash'}{'blacklist'}{$action} = 1;
    }

    foreach my $log_module (split(/,/, $param->{'config_hash'}{'log_module'})) {
        $param->{'config_hash'}{'loging_for_module'}{$log_module} = 1;
    }
    
    foreach my $log_condition (split(/,/, $param->{'config_hash'}{'log_condition'})) {
        chomp $log_condition;
        if ($log_condition =~ /^\s*(ip|email)\s*\=\s*(.*)\s*$/i) {         
            $param->{'config_hash'}{'loging_condition'}{$1} = $2;
        }else{
            &Log::do_log('err',"unrecognized log_condition token %s ; ignored",$log_condition);
        }
    }    

    if ($param->{'config_hash'}{'ldap_export_name'}) {    
        $param->{'config_hash'}{'ldap_export'} =     {$param->{'config_hash'}{'ldap_export_name'} => { 'host' => $param->{'config_hash'}{'ldap_export_host'},
                                   'suffix' => $param->{'config_hash'}{'ldap_export_suffix'},
                                   'password' => $param->{'config_hash'}{'ldap_export_password'},
                                   'DnManager' => $param->{'config_hash'}{'ldap_export_dnmanager'},
                                   'connection_timeout' => $param->{'config_hash'}{'ldap_export_connection_timeout'}
                                }
                                };
    }
        
    ## Default SOAP URL corresponds to default robot
    if ($param->{'config_hash'}{'soap_url'}) {
        my $url = $param->{'config_hash'}{'soap_url'};
        $url =~ s/^http(s)?:\/\/(.+)$/$2/;
        $param->{'config_hash'}{'robot_by_soap_url'}{$url} = $param->{'config_hash'}{'domain'};
    }
        
    return 1;
}

sub _load_server_specific_secondary_config_files {
    my $param = shift;
    ## Load charset.conf file if necessary.
    if($param->{'config_hash'}{'legacy_character_support_feature'} eq 'on'){
        $param->{'config_hash'}{'locale2charset'} = &load_charset ();
    }else{
        $param->{'config_hash'}{'locale2charset'} = {};
    }
    
    ## Load nrcpt_by_domain.conf
    $param->{'config_hash'}{'nrcpt_by_domain'} = &load_nrcpt_by_domain () ;
    $param->{'config_hash'}{'crawlers_detection'} = &load_crawlers_detection($param->{'config_hash'}{'robot_name'});
        
}

sub _infer_robot_parameter_values {
    my $param = shift;

    # 'host' and 'domain' are mandatory and synonym.$Conf{'host'} is
    # still widely used even if the doc requires domain.
    $param->{'config_hash'}{'host'} = $param->{'config_hash'}{'domain'} if (defined $param->{'config_hash'}{'domain'}) ;
    $param->{'config_hash'}{'domain'} = $param->{'config_hash'}{'host'} if (defined $param->{'config_hash'}{'host'}) ;

    $param->{'config_hash'}{'wwsympa_url'} ||= "http://$param->{'config_hash'}{'host'}/sympa";

    $param->{'config_hash'}{'static_content_url'} ||= $Conf{'static_content_url'};
    $param->{'config_hash'}{'static_content_path'} ||= $Conf{'static_content_path'};

    ## CSS
    my $final_separator = '';
    $final_separator = '/' if ($param->{'config_hash'}{'robot_name'});
    $param->{'config_hash'}{'css_url'} ||= $param->{'config_hash'}{'static_content_url'}.'/css'.$final_separator.$param->{'config_hash'}{'robot_name'};
    $param->{'config_hash'}{'css_path'} ||= $param->{'config_hash'}{'static_content_path'}.'/css'.$final_separator.$param->{'config_hash'}{'robot_name'};

    if (defined $param->{'config_hash'}{'email'}) {
        $param->{'config_hash'}{'sympa'} = $param->{'config_hash'}{'email'}.'@'.$param->{'config_hash'}{'host'};
        $param->{'config_hash'}{'request'} = $param->{'config_hash'}{'email'}.'-request@'.$param->{'config_hash'}{'host'};
    }

    # split action list for blacklist usage
    foreach my $action (split(/,/, $Conf{'use_blacklist'})) {
        $param->{'config_hash'}{'blacklist'}{$action} = 1;
    }

    ## Create a hash to deduce robot from SOAP url
    if ($param->{'config_hash'}{'soap_url'}) {
        my $url = $param->{'config_hash'}{'soap_url'};
        $url =~ s/^http(s)?:\/\/(.+)$/$2/;
        $Conf{'robot_by_soap_url'}{$url} = $param->{'config_hash'}{'robot_name'};
    }
    # Hack because multi valued parameters are not available for Sympa 6.1.
    if (defined $param->{'config_hash'}{'automatic_list_families'}) {
        my @families = split ';',$param->{'config_hash'}{'automatic_list_families'};
        my %families_description;
        foreach my $family_description (@families) {
            my %family;
            my @family_parameters = split ':',$family_description;
            foreach my $family_parameter (@family_parameters) {
            my @parameter = split '=', $family_parameter;
            $family{$parameter[0]} = $parameter[1];
            }
            $family{'escaped_prefix_separator'} = $family{'prefix_separator'};
            $family{'escaped_prefix_separator'} =~ s/([+*?.])/\\$1/g;
            $family{'escaped_classes_separator'} = $family{'classes_separator'};
            $family{'escaped_classes_separator'} =~ s/([+*?.])/\\$1/g;
            $families_description{$family{'name'}} = \%family;
        }
        $param->{'config_hash'}{'automatic_list_families'} = \%families_description;
    }

    &_parse_custom_robot_parameters({'config_hash' => $param->{'config_hash'}});
}

sub _load_robot_secondary_config_files {
    my $param = shift;
    my $trusted_applications = &load_trusted_application($param->{'config_hash'}{'robot_name'});
    $param->{'config_hash'}{'trusted_applications'} = undef;
    if (defined $trusted_applications) {
        $param->{'config_hash'}{'trusted_applications'} = $trusted_applications->{'trusted_application'};
    }
    my $robot_name_for_auth_storing  = $param->{'config_hash'}{'robot_name'} || $Conf{'domain'};
    my $is_main_robot = 0;
    $is_main_robot = 1 unless ($param->{'config_hash'}{'robot_name'});
    $Conf{'auth_services'}{$robot_name_for_auth_storing} = &_load_auth($param->{'config_hash'}{'robot_name'}, $is_main_robot);
    if (defined $param->{'config_hash'}{'automatic_list_families'}) {
        foreach my $family (keys %{$param->{'config_hash'}{'automatic_list_families'}}) {
            $param->{'config_hash'}{'automatic_list_families'}{$family}{'description'} = &load_automatic_lists_description($param->{'config_hash'}{'robot_name'},$param->{'config_hash'}{'automatic_list_families'}{$family}{'name'});
        }
    }
    return 1;
}
## For parameters whose value is hard_coded, as per %hardcoded_params, set the
## parameter value to the hardcoded value, whatever is defined in the config.
## Returns a ref to a hash containing the ignored values.
sub _set_hardcoded_parameter_values{
    my $param = shift;
    my %ignored_values;
    ## Some parameter values are hardcoded. In that case, ignore what was set in the config file and simply use the hardcoded value.
    foreach my $p (keys %hardcoded_params) {
        $ignored_values{$p} = $param->{'config_hash'}{$p} if (defined $param->{'config_hash'}{$p});
        $param->{'config_hash'}{$p} = $hardcoded_params{$p};
    }
    return \%ignored_values;
}

sub _detect_missing_mandatory_parameters {
    my $param = shift;
    my $number_of_errors = 0;
    $param->{'file_to_check'} =~ /^(\/.*\/)?([^\/]+)$/;
    my $config_file_name = $2;
    foreach my $parameter (keys %params) {
        next if (defined $params{$parameter}->{'file'} && $params{$parameter}->{'file'} ne $config_file_name);
        unless (defined $param->{'config_hash'}{$parameter} or defined $params{$parameter}->{'default'} or defined $params{$parameter}->{'optional'}) {
            printf STDERR "Conf::_detect_missing_mandatory_parameters(): Required field not found in sympa.conf: %s\n", $parameter;
            $number_of_errors++;
            next;
        }
        $param->{'config_hash'}{$parameter} ||= $params{$parameter}->{'default'};
    }
    return $number_of_errors;
}

## Some functionalities activated by some parameter values require that
## some optional CPAN modules are installed. This function checks whether
## these modules are installed and if they are missing, changes the config
## to fall back to a functioning that doesn't require a module and issues
## a warning.
## Returns the number of missing modules.
sub _check_cpan_modules_required_by_config {
    my $param = shift;
    my $number_of_missing_modules = 0;
    if ($param->{'config_hash'}{'lock_method'} eq 'nfs') {
        eval "require File::NFSLock";
        if ($@) {
            printf STDERR "Conf::_check_cpan_modules_required_by_config(): Failed to load File::NFSLock perl module ; setting 'lock_method' to 'flock'\n";
            $param->{'config_hash'}{'lock_method'} = 'flock';
            $number_of_missing_modules++;
        }
    }
         
    ## Some parameters require CPAN modules
    if ($param->{'config_hash'}{'dkim_feature'} eq 'on') {
        eval "require Mail::DKIM";
        if ($@) {
            printf STDERR "Conf::_check_cpan_modules_required_by_config(): Failed to load Mail::DKIM perl module ; setting 'DKIM_feature' to 'off'\n";
            $param->{'config_hash'}{'dkim_feature'} = 'off';
            $number_of_missing_modules++;
        }
    }
    return $number_of_missing_modules;
}

sub _dump_non_robot_parameters {
    my $param = shift;
    foreach my $key (keys %{$param->{'config_hash'}}){
        unless($valid_robot_key_words{$key}){
            delete $param->{'config_hash'}{$key};
            printf STDERR "Conf::_dump_non_robot_parameters(): Robot %s config: unknown robot parameter: %s\n",$param->{'robot'},$key;
        }
    }
}

sub _load_single_robot_config{
    my $param = shift;
    my $robot = $param->{'robot'};
    my $robot_conf;
    
   my $config_err;
    my $config_file = "$Conf{'etc'}/$robot/robot.conf";
    my $force_reload = $param->{'force_reload'};
    if(!$force_reload && &_source_has_not_changed({'config_file' => $config_file})) {
        $force_reload = 0;
    }
    if(!$force_reload) {
        printf "Conf::_load_single_robot_config(): File %s has not changed since the last cache. Using cache.\n",$config_file;
        unless (-r $config_file) {
            printf STDERR "Conf::_load_single_robot_config(): No read access on %s\n", $config_file;
            &List::send_notify_to_listmaster('cannot_access_robot_conf',$Conf{'domain'}, ["No read access on $config_file. you should change privileges on this file to activate this virtual host. "]);
            return undef;
        }
         unless ($robot_conf = _load_binary_cache({'config_file' => $config_file.$binary_file_extension})){
            printf STDERR "Binary config file loading failed. Loading source file '%s'\n",$config_file;
            $force_reload = 1;
        }
    }
    if($force_reload){
        if(my $config_loading_result = &_load_config_file_to_hash({'path_to_config_file' => $config_file})) {
            $robot_conf = $config_loading_result->{'config'};
            $config_err = $config_loading_result->{'errors'};
        }else{
            printf STDERR  "Conf::_load_single_robot_config(): Unable to load %s. Aborting\n", $config_file;
            return undef;
        }
        
        # Remove entries which are not supposed to be defined at the robot level.
        &_dump_non_robot_parameters({'config_hash' => $robot_conf, 'robot' => $robot});
        
        ## Default for 'host' is the domain
        $robot_conf->{'host'} ||= $robot;
        $robot_conf->{'robot_name'} ||= $robot;

        &_set_listmasters_entry({'config_hash' => $robot_conf});
    
        &_infer_robot_parameter_values({'config_hash' => $robot_conf});
        
        &_store_source_file_name({'config_hash' => $robot_conf,'config_file' => $config_file});
        &_save_config_hash_to_binary({'config_hash' => $robot_conf,'source_file' => $config_file});
        return undef if ($config_err);
    }
    &_replace_file_value_by_db_value({'config_hash' => $robot_conf}) unless $param->{'no_db'};
    &_load_robot_secondary_config_files({'config_hash' => $robot_conf});
    return $robot_conf;
}

sub _set_listmasters_entry{
    my $param = shift;
    my $number_of_valid_email = 0;
    my $number_of_email_provided = 0;
    # listmaster is a list of email separated by commas
    if (defined $param->{'config_hash'}{'listmaster'} && $param->{'config_hash'}{'listmaster'} !~ /^\s*$/) {
        $param->{'config_hash'}{'listmaster'} =~ s/\s//g;
        my @emails_provided = split(/,/, $param->{'config_hash'}{'listmaster'});
        $number_of_email_provided = $#emails_provided+1;
        foreach my $lismaster_address (@emails_provided){
            if (&tools::valid_email($lismaster_address)) {
                push @{$param->{'config_hash'}{'listmasters'}}, $lismaster_address;
                $number_of_valid_email++;
            }else{
                printf STDERR "Conf::_set_listmasters_entry(): Robot %s config: Listmaster address '%s' is not a valid email\n",$param->{'config_hash'}{'host'},$lismaster_address;
            }
        }
    }else{
        if ($param->{'main_config'}) {
			printf STDERR "Conf::_set_listmasters_entry(): Robot %s config: No listmaster defined. This is the main config. It MUST define at least one listmaster. Stopping here.\n.";
			return undef;
		}else{
			$param->{'config_hash'}{'listmasters'} = $Conf{'listmasters'};
			$param->{'config_hash'}{'listmaster'} = $Conf{'listmaster'};
			$number_of_valid_email = $#{$param->{'config_hash'}{'listmasters'}};
		}
    }
    if ($number_of_email_provided > $number_of_valid_email){
        printf STDERR "Conf::_set_listmasters_entry(): Robot %s config: All the listmasters addresses found were not valid. Out of %s addresses provided, %s only are valid email addresses.\n",$param->{'config_hash'}{'host'},$number_of_email_provided,$number_of_valid_email;
        return undef;
    }
    return $number_of_valid_email;
}

sub _check_double_url_usage{
    my $param = shift;
    my ($host, $path);
    if ($param->{'config_hash'}{'http_host'} =~ /^([^\/]+)(\/.*)$/) {
        ($host, $path) = ($1,$2);
    }else {
        ($host, $path) = ($param->{'config_hash'}{'http_host'}, '/');
    }

    ## Warn listmaster if another virtual host is defined with the same host+path
    if (defined $Conf{'robot_by_http_host'}{$host}{$path}) {
      printf STDERR "Conf::_infer_robot_parameter_values(): Error: two virtual hosts (%s and %s) are mapped via a single URL '%s%s'\n", $Conf{'robot_by_http_host'}{$host}{$path}, $param->{'config_hash'}{'robot_name'}, $host, $path;
    }

    $Conf{'robot_by_http_host'}{$host}{$path} = $param->{'config_hash'}{'robot_name'} ;    
}

sub _parse_custom_robot_parameters {
    my $param = shift;
    my $csp_tmp_storage = undef;
    if (defined $param->{'config_hash'}{'custom_robot_parameter'} && ref() ne 'HASH'){
        foreach my $custom_p (@{$param->{'config_hash'}{'custom_robot_parameter'}}){
            if($custom_p =~ /(\S+)\s*\;\s*(.+)/) {
                $csp_tmp_storage->{$1} = $2;
            }
        }
        $param->{'config_hash'}{'custom_robot_parameter'} = $csp_tmp_storage;
    }
}

sub _replace_file_value_by_db_value {
    my $param = shift;
    my $robot = $param->{'config_hash'}{'robot_name'};
    # The name of the default robot is "*" in the database.
    $robot = '*' if ($param->{'config_hash'}{'robot_name'} eq '');
    foreach my $label (keys %db_storable_parameters) {
        next unless ($robot ne '*' && $valid_robot_key_words{$label} == 1);
        my $value = &get_db_conf($robot, $label);
        if (defined $value) {
            $param->{'config_hash'}{$label} = $value ;
        }
    }
}

# Stores the config hash binary representation to a file.
# Returns 1 or undef if something went wrong.
sub _save_binary_cache {
    my $param = shift;
    my $lock = new Lock ($param->{'target_file'});
    unless (defined $lock) {
        &Log::do_log('err','Could not create new lock');
        return undef;
    }
    $lock->set_timeout(2); 
    unless ($lock->lock('write')) {
        return undef;
    }   

    eval {&Storable::store($param->{'conf_to_save'},$param->{'target_file'});};
    if ($@) {
        printf STDERR  'Conf::_save_binary_cache(): Failed to save the binary config %s. error: %s\n', $param->{'target_file'},$@;
        unless ($lock->unlock()) {
            return undef;
        }
        return undef;
    }
    eval {chown ((getpwnam(Sympa::Constants::USER))[2], (getgrnam(Sympa::Constants::GROUP))[2], $param->{'target_file'});};
    if ($@){
        printf STDERR  'Conf::_save_binary_cache(): Failed to change owner of the binary file %s. error: %s\n', $param->{'target_file'},$@;
        unless ($lock->unlock()) {
            return undef;
        }
        return undef;
     }
    unless ($lock->unlock()) {
        return undef;
    }
    return 1;
}

# Loads the config hash binary representation from a file an returns it
# Returns the hash or undef if something went wrong.
sub _load_binary_cache {
    my $param = shift;
    my $result = undef;

    my $lock = new Lock ($param->{'config_file'});
    unless (defined $lock) {
        &Log::do_log('err','Could not create new lock');
        return undef;
    }
    $lock->set_timeout(2); 
    unless ($lock->lock('read')) {
        return undef;
    }   
    
    eval {
        $result = &Storable::retrieve($param->{'config_file'});
    };
    if ($@) {
        printf STDERR  "Conf::_load_binary_cache(): Failed to load the binary config %s. error: %s\n", $param->{'config_file'},$@;
        unless ($lock->unlock()) {
            return undef;
        }
        return undef;
    }
    ## Release the lock
    unless ($lock->unlock()) {
        return undef;
    }
    return $result;
}

sub _save_config_hash_to_binary {
    my $param = shift;
    unless(_save_binary_cache({'conf_to_save' => $param->{'config_hash'},'target_file' => $param->{'config_hash'}{'source_file'}.$binary_file_extension})){
        printf STDERR "Conf::_save_config_hash_to_binary(): Could not save main config %s\n",$param->{'config_hash'}{'source_file'};
    }
}

sub _source_has_not_changed {
    my $param = shift;
    my $is_older = &tools::a_is_older_than_b({'a_file' => $param->{'config_file'},'b_file' => $param->{'config_file'}.$binary_file_extension,});
    return 1 if(defined $is_older && $is_older == 1);
    return 0;
}

sub _store_source_file_name {
    my $param = shift;
    $param->{'config_hash'}{'source_file'} = $param->{'config_file'};
}

sub _get_config_file_name {
    my $param = shift;
    my $config_file;
    if ($param->{'robot'}) {
        $config_file = $Conf{'etc'}.'/'.$param->{'robot'}.'/'.$param->{'file'};
    }else{
        $config_file = $Conf{'etc'}.'/'.$param->{'file'} ;
    }
    $config_file = Sympa::Constants::DEFAULTDIR .'/'.$param->{'file'} unless (-f $config_file);
    return $config_file;
}

sub _create_robot_like_config_for_main_robot {
    return if (defined $Conf::Conf{'robots'}{$Conf::Conf{'domain'}});
    my $main_conf_no_robots = &tools::dup_var(\%Conf);
    delete $main_conf_no_robots->{'robots'};
    &_remove_unvalid_robot_entry({'config_hash' => $main_conf_no_robots, 'quiet' => 1 });
    $Conf{'robots'}{$Conf{'domain'}} = $main_conf_no_robots;
}

sub _get_parameters_names_by_category {
    my $param_by_categories;
    my $current_category;
    foreach my $entry (@confdef::params) {
        if ($entry->{'title'}) {
            $current_category = $entry->{'title'};
        }else{
            $param_by_categories->{$current_category}{$entry->{'name'}} = 1;
        }
    }
    return $param_by_categories;
}

## Packages must return true.
1;
