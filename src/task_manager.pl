#! --PERL--

# task_manager.pl - This script runs as a daemon and processes periodical Sympa tasks
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

## Options :  F         -> do not detach TTY
##         :  d		-> debug -d is equiv to -dF

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';
use strict vars;

use List;
use Conf;
use Log;
use Getopt::Long;
use Time::Local;
use MD5;
use smtp;
use wwslib;
 
require 'parser.pl';
require 'tools.pl';

my $opt_d;
my $opt_F;
my %options;
&GetOptions(\%main::options, 'dump=s', 'debug|d', 'log_level=s', 'foreground', 'config|f=s', 
	    'lang|l=s', 'mail|m', 'keepcopy|k=s', 'help', 'version', 'import=s', 'lowercase');

# $main::options{'debug2'} = 1 if ($main::options{'debug'});
$log_level = $main::options{'log_level'} if ($main::options{'log_level'}); 

my $Version = '0.1';

my $wwsympa_conf = "--WWSCONFIG--";
my $sympa_conf_file = '--CONFIG--';

my $wwsconf = {};
my $adrlist = {};

# some regexp that all modules should use and share
my %regexp = ('email' => '(\S+|\".*\")(@\S+)',
            'host' => '[\w\.\-]+',
            'listname' => '[a-z0-9][a-z0-9\-\._]+',
            'sql_query' => 'SELECT.*',
            'scenario' => '[\w,\.\-]+',
            'task' => '\w+'
            );


# Load WWSympa configuration
unless ($wwsconf = &wwslib::load_config($wwsympa_conf)) {
    &do_log ('err', 'error : unable to load config file');
    exit;
}

# Load sympa.conf
unless (Conf::load($sympa_conf_file)) {
    &do_log  ('err', "error : unable to load sympa configuration, file $sympa_conf_file has errors.");
    exit(1);
}

## Check databse connectivity
$List::use_db = &List::probe_db();

## Check for several files.
unless (&Conf::checkfiles()) {
    fatal_err("Missing files. Aborting.");
    ## No return.                                         
}

## Put ourselves in background if not in debug mode. 
                                             
unless ($main::options{'debug'} || $main::options{'foreground'}) {
     open(STDERR, ">> /dev/null");
     open(STDOUT, ">> /dev/null");
     if (open(TTY, "/dev/tty")) {
         ioctl(TTY, 0x20007471, 0);         # XXX s/b &TIOCNOTTY
#       ioctl(TTY, &TIOCNOTTY, 0);                                             
         close(TTY);
     }
                                       
     setpgrp(0, 0);
     if ((my $child_pid = fork) != 0) {                                        
         &do_log('debug', "Starting task_manager daemon, pid $_");	 
         exit(0);
     }     
 }

&tools::write_pid($wwsconf->{'task_manager_pidfile'}, $$);

$wwsconf->{'log_facility'}||= $Conf{'syslog'};
do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'task_manager');

# setting log_level using conf unless it is set by calling option
if ($main::options{'log_level'}) {
    do_log('info', "Configuration file read, log level set using options : $log_level"); 
}else{
    $log_level = $Conf{'log_level'};
    do_log('info', "Configuration file read, default log level  $log_level"); 
}

## Set the UserID & GroupID for the process
$( = $) = (getpwnam('--USER--'))[2];
$< = $> = (getpwnam('--GROUP--'))[2];


## Sets the UMASK
umask($Conf{'umask'});

## Change to list root
unless (chdir($Conf{'home'})) {
    &message('chdir_error');
    &do_log('err',"error : unable to change to directory $Conf{'home'}");
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
my $end = 0;

###### VARIABLES DECLARATION ######

my $spool_task = $Conf{'queuetask'};
my $std_global_task_model_dir = "--ETCBINDIR--/global_task_models";
my $user_global_task_model_dir = "$Conf{'etc'}/global_task_models";
my $cert_dir = $Conf{'ssl_cert_dir'};
my @tasks; # list of tasks in the spool

undef my $log; # won't execute send_msg and delete_subs commands if true, only log
#$log = 1;

## list of list task models
my @list_models = ('expire', 'remind');

## hash of the global task models
my %global_models = (#'crl_update_task' => 'crl_update', 
		     #'chk_cert_expiration_task' => 'chk_cert_expiration',
		     'expire_bounce' => 'expire_bounce'
		     #,'global_remind' => 'global_remind'
		     );

## month hash used by epoch conversion routines
my %months = ('Jan', 0, 'Feb', 1, 'Mar', 2, 'Apr', 3, 'May', 4,  'Jun', 5, 
	      'Jul', 6, 'Aug', 7, 'Sep', 8, 'Oct', 9, 'Nov', 10, 'Dec', 11);

###### DEFINITION OF AVAILABLE COMMANDS FOR TASKS ######

my $date_arg_regexp1 = '\d+|execution_date';
my $date_arg_regexp2 = '(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?'; 
my $date_arg_regexp3 = '(\d+|execution_date)(\+|\-)(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?';
my $delay_regexp = '(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?';
my $var_regexp ='@\w+'; 
my $subarg_regexp = '(\w+)(|\((.*)\))'; # for argument with sub argument (ie arg(sub_arg))
                 
# regular commands
my %commands = ('next'                  => ['date', '\w*'],
		                           # date   label
                'stop'                  => [],
		'create'                => ['subarg', '\w+', '\w+'],
		                           #object    model  model choice
		'exec'                  => ['.+'],
		                           #script
		'update_crl'            => ['\w+', 'date'], 
		                           #file    #delay
		'expire_bounce'         => ['\d+'],
		                           #Number of days (delay)
		'chk_cert_expiration'   => ['\w+', 'date'],
		                           #template  date
		);

# commands which use a variable. If you add such a command, the first parameter must be the variable
my %var_commands = ('delete_subs'      => ['var'],
		                          # variable 
		    'send_msg'         => ['var',  '\w+' ],
		                          #variable template
		    'rm_file'          => ['var'],
		                          # variable
		    );
my @var_commands;
foreach (keys %var_commands) {
    $commands{$_} = $var_commands{$_};
    push (@var_commands, $_);
}

# commands which are used for assignments
my %asgn_commands = ('select_subs'      => ['subarg'],
		                            # condition
		     'delete_subs'      => ['var'],
		                            # variable
		     );
my @asgn_commands;
foreach (keys %asgn_commands) {
    $commands{$_} = $asgn_commands{$_};
    push (@asgn_commands, $_);
}

# list of all commands
my @commands = keys %commands;

###### INFINITE LOOP SCANING THE QUEUE (unless a sig TERM is received) ######
while (!$end) {
    
    my $current_date = time; # current epoch date
    my $rep = &tools::adate ($current_date);
    # &do_log ('notice', "****** $rep ******");

    ## @tasks initialisation
    unless (opendir(DIR, $spool_task)) {
	&do_log ('err', "error : can't open dir %s: %m", $spool_task);
    }
    my @tasks = sort epoch_sort (grep !/^\.\.?$/, readdir DIR);

    ## processing of tasks anterior to the current date
    &do_log ('debuug3', 'processing of tasks anterior to the current date');
    foreach my $task (@tasks) {
	$task =~ /^(\d+)\.\w*\.\w+\.($regexp{'listname'}|_global)$/;
	# &do_log ('debuug3', "procesing %s/%s", $spool_task,$task);
	last unless ($1 < $current_date);
	if ($2 ne '_global') { # list task
	    my $list = new List ($2);
	    next unless ($list->{'admin'}{'status'} eq 'open');
	}
	execute ("$spool_task/$task");
    }
    # &do_log ('notice', 'done');

    unless (opendir(DIR, $spool_task)) {
	&do_log ('err', "error : can't open dir %s: %m", $spool_task);
    }
    undef @tasks;
    @tasks = sort epoch_sort (grep !/^\.\.?$/, readdir DIR); # @tasks updating
    closedir DIR;

    my @used_models; # models for which a task exists
    foreach (@tasks) {
	/.*\..*\.(.*)\..*/;
	push (@used_models, $1) unless (in (\@used_models, $1));
    }

    ### creation of required tasks 
    my %default_data = ('creation_date' => $current_date, # hash of datas necessary to the creation of tasks
			'execution_date' => 'execution_date');

    ## global tasks

    foreach my $key (keys %global_models) {
	if (!in (\@used_models, $global_models{$key})) {
	    if ($Conf{$key}) { 
		my %data = %default_data; # hash of datas necessary to the creation of tasks
		create ($current_date, '', $global_models{$key}, $Conf{$key}, '_global', \%data);
		push (@used_models, $1);
	    }
	}
    }    
    
    ## list tasks

    foreach ( &List::get_lists() ) {
	
	my %data = %default_data;
	my $list = new List ($_);
	
	$data{'list'}{'name'} = $list->{'name'};
	
	my %used_list_models; # stores which models already have a task 
	foreach (@list_models) { $used_list_models{$_} = undef; }
	
	foreach $_ (@tasks) {
	   /(.*)\.(.*)\.(.*)\.(.*)/;
	   my $model = $3;
	   my $object = $4;
	   if ($object eq $list->{'name'}) { $used_list_models {$model} = 1; }
       }
        
	foreach my $model (keys %used_list_models) {
	    unless ($used_list_models{$model}) {
		if ( $list->{'admin'}{$model.'_task'} ) {
		    create ($current_date, '', $model, $list->{'admin'}{$model.'_task'}, 'list', \%data);
		}
	    }
	}
    }
    sleep 60;
    #$end = 1;
}

&do_log ('notice', 'task_manager exited normally due to signal');
exit(0);

####### SUBROUTINES #######

## task creations
sub create {
        
    my $date          = $_[0];
    my $label         = $_[1];
    my $model         = $_[2];
    my $model_choice  = $_[3];
    my $object        = $_[4];
    my $Rdata         = $_[5];

    my $task_file;
    my $list_name;
    if ($object eq 'list') { 
	$list_name = $Rdata->{'list'}{'name'};
	$task_file  = "$spool_task/$date.$label.$model.$list_name";
    }
    else {$task_file  = $spool_task.'/'.$date.'.'.$label.'.'.$model.'.'.$object;}

    ## model recovery
    my $model_file;
    my $model_name = $model.'.'.$model_choice.'.'.'task';
 
    &do_log ('notice', "creation of $task_file");

     # for global model
    if ($object eq '_global') {
	if (open (MODEL, "$user_global_task_model_dir/$model_name")) {
	    $model_file = "$user_global_task_model_dir/$model_name";
	} elsif (open (MODEL, "$std_global_task_model_dir/$model_name")) {
	    $model_file = "$std_global_task_model_dir/$model_name";
	} else { 
	    &do_log ('err', "error : unable to find $model_name, creation aborted");
	    return undef;
	}
    }

    # for a list
    if ($object  eq 'list') {
	my $list = new List($list_name);

	if (open (MODEL, "$list->{'dir'}/list_task_models/$model_name")) {
	    $model_file = "$Conf{'home'}/$list_name/list_task_models/$model_name";
	} elsif (open (MODEL, "$Conf{'etc'}/list_task_models/$model_name")) {
	    $model_file = "$Conf{'etc'}/list_task_models/$model_name";
	} elsif (open (MODEL, "--ETCBINDIR--/list_task_models/$model_name")) {
	    $model_file = "--ETCBINDIR--/list_task_models/$model_name";
	} else { 
	    &do_log ('err', "error : unable to find $model_name, creation aborted");
	    return undef;
	}
    }
   
    &do_log ('notice', "with model $model_file");
    close (MODEL);

    ## creation
    open (TASK, ">$task_file");
    parse_tpl ($Rdata, $model_file, TASK);
    close (TASK);
    
    # special checking for list whose user_data_source config parmater is include. The task won't be created if there is a delete_subs command
    my $ok = 1;
    if ($object eq 'list') {
	my $list = new List("$list_name");
	if ($list->{'admin'}{'user_data_source'} eq 'include') {
	    unless ( open (TASK, $task_file) ) {
		&do_log ('err', "error : unable to read $task_file, checking is impossible");
		return undef;
	    }
	    while (<TASK>) {
		chomp;
		if (/.*delete_subs.*/) {
		    close (TASK);
		    undef $ok;
		    &do_log ('err', "error : you are not allowed to use the delete_subs command on a list whose subscribers are included, creation aborted");
		    return undef;
		}
	    }
	    close (TASK);
	} 
    } # end of special checking

    if  (!$ok or !check ($task_file)) {
	&do_log ('err', "error : syntax error in $task_file, you should check $model_file");
	unlink ($task_file) ? 
	    &do_log ('notice', "$task_file deleted") 
		: &do_log ('err', "error : unable to delete $task_file");	
	return undef;
    }
    return 1;
}

### SYNTAX CHECKING SUBROUTINES ###

## check the syntax of a task
sub check {

    my $task_file = $_[0]; # the task to check
    my %result; # stores the result of the chk_line subroutine
    my $lnb = 0; # line number
    my @used_labels; # list of labels used as parameter in commands
    my @labels; # list of declared labels
    my @used_vars; # list of vars used as parameter in commands
    my @vars; # list of declared vars

    unless ( open (TASK, $task_file) ) {
	&do_log ('err', "error : unable to read $task_file, checking is impossible");
	return undef;
    }

    
    while (<TASK>) {

	chomp;

	$lnb++;
	unless (chk_line ($_, \%result)) {
	    &do_log ('err', "error at line $lnb : $_");
	    &do_log ('err', "$result{'error'}");
	    return undef;
	}
	
	if ( $result{'nature'} eq 'assignment' ) {
	    if (chk_cmd ($result{'command'}, $lnb, \@{$result{'Rarguments'}}, \@used_labels, \@used_vars)) {
		push (@vars, $result{'var'});
	    } else {return undef;}
	}

	if ( $result{'nature'} eq 'command' ) {
	    return undef unless (chk_cmd ($result{'command'}, $lnb, \@{$result{'Rarguments'}}, \@used_labels, \@used_vars));
	} 
			 
	push (@labels, $result{'label'}) if ( $result{'nature'} eq 'label' );
	
    }

    # are all labels used ?
    foreach my $label (@labels) {
	&do_log ('notice', "warning : label $label exists but is not used") unless (in (\@used_labels, $label));
    }

    # do all used labels exist ?
    foreach my $label (@used_labels) {
	unless (in (\@labels, $label)) {
	    &do_log ('err', "error : label $label is used but does not exist");
	    return undef;
	}
    }
    
    # are all variables used ?
    foreach my $var (@vars) {
	&do_log ('notice', "warning : var $var exists but is not used") unless (in (\@used_vars, $var));
    }

    # do all used variables exist ?
    foreach my $var (@used_vars) {
	unless (in (\@vars, $var)) {
	    &do_log ('err', "error : var $var is used but does not exist");
	    return undef;
	}
    }

    return 1;
}

## check a task line
sub chk_line {

    my $line = $_[0];
    my $Rhash = $_[1]; # will contain nature of line (label, command, error...)
        
    $Rhash->{'nature'} = undef;
  
    # empty line
    if (! $line) {
	$Rhash->{'nature'} = 'empty line';
	return 1;
    }
  
    # comment
    if ($line =~ /^\s*\#.*/) {
	$Rhash->{'nature'} = 'comment';
	return 1;
    } 

    # title
    if ($line =~ /^\s*title\...\s*(.*)\s*/i) {
	$Rhash->{'nature'} = 'title';
	$Rhash->{'title'} = $1;
	return 1;
    }

    # label
    if ($line =~ /^\s*\/\s*(.*)/) {
	$Rhash->{'nature'} = 'label';
	$Rhash->{'label'} = $1;
	return 1;
    }

    # command
    if ($line =~ /^\s*(\w+)\s*\((.*)\)\s*/i ) { 
    
	my $command = lc ($1);
	my @args = split (/,/, $2);
	foreach (@args) { s/\s//g;}

	unless (in (\@commands, $command)) { 
	    $Rhash->{'nature'} = 'error';
	    $Rhash->{'error'} = 'unknown command';
	    return 0;
	}
    
	$Rhash->{'nature'} = 'command';
	$Rhash->{'command'} = $command;

	# arguments recovery. no checking of their syntax !!!
	$Rhash->{'Rarguments'} = \@args;
	return 1;
    }
  
    # assignment
    if ($line =~ /^\s*(@\w+)\s*=\s*(.+)/) {

	my %hash2;
	chk_line ($2, \%hash2);
	unless ( in (\@asgn_commands, $hash2{'command'}) ) { 
	    $Rhash->{'nature'} = 'error';
	    $Rhash->{'error'} = 'non valid assignment';
	    return 0;
	}
	$Rhash->{'nature'} = 'assignment';
	$Rhash->{'var'} = $1;
	$Rhash->{'command'} = $hash2{'command'};
	$Rhash->{'Rarguments'} = $hash2{'Rarguments'};
	return 1;
    }

    $Rhash->{'nature'} = 'error'; 
    $Rhash->{'error'} = 'syntax error';
    return 0;
}

## check the arguments of a command 
sub chk_cmd {
    
    my $cmd = $_[0]; # command name
    my $lnb = $_[1]; # line number
    my $Rargs = $_[2]; # argument list
    my $Rused_labels = $_[3];
    my $Rused_vars = $_[4];
    
    foreach my $command (@commands) { 
	
	if ($cmd eq $command) {

	    my @expected_args = @{$commands{$command}};
	    my @args = @{$Rargs};

	    unless ($#expected_args == $#args) {
		&do_log ('err', "error at line $lnb : wrong number of arguments for $command");
		&do_log ('err', "args = @args ; expected_args = @expected_args");
		return undef;
	    }

	    foreach (@args) {

		undef my $error;
		my $regexp = $expected_args[0];
		shift (@expected_args);

		if ($regexp eq 'date') {
		    $error = 1 unless ( (/^$date_arg_regexp1$/i) or (/^$date_arg_regexp2$/i) or (/^$date_arg_regexp3$/i) );
		}
		elsif ($regexp eq 'delay') {
		    $error = 1 unless (/^$delay_regexp$/i);
		}
		elsif ($regexp eq 'var') {
		    $error = 1 unless (/^$var_regexp$/i);
		}
		elsif ($regexp eq 'subarg') {
		    $error = 1 unless (/^$subarg_regexp$/i);
		}
		else {
		    $error = 1 unless (/^$regexp$/i);
		}

		if ($error) {
		    &do_log ('err', "error at line $lnb : argument $_ is not valid");
		    return undef;
		}

		push (@{$Rused_labels}, $args[1]) if ($command eq 'next' && ($args[1]));   
		push (@{$Rused_vars}, $args[0]) if (in (\@var_commands, $command));
      	    }
	}
    }
    return 1;
}

    
### TASK EXECUTION SUBROUTINES ###

sub execute {

    my $task_file = $_[0]; # task to execute
    my %result; # stores the result of the chk_line subroutine
    my %vars; # list of task vars
    my $lnb = 0; # line number

    unless ( open (TASK, $task_file) ) {
	&do_log ('err', "error : can't read the task $task_file");
	return undef;
    }

    # positioning at the right label
    $_[0] =~ /\w*\.(\w*)\..*/;
    my $label = $1;
    return undef if ($label eq 'ERROR');

    &do_log ('debug2', "* execution of the task $task_file");
    unless ($label eq '') {
	while ( <TASK> ) {
	    $lnb++;
	    chk_line ($_, \%result);
	    last if ($result{'label'} eq $label);
	}
    }

    # execution
    while ( <TASK> ) {
  
	chomp;
	$lnb++;

	unless ( chk_line ($_, \%result) ) {
	    &do_log ('err', "error : $result{'error'}");
	    return undef;
	}
		
	# processing of the assignments
	if ($result{'nature'} eq 'assignment') {
	    $vars{$result{'var'}} = cmd_process ($result{'command'}, $result{'Rarguments'}, $task_file, \%vars, $lnb);
	}
					      
	# processing of the commands
	if ($result{'nature'} eq 'command') {
	    last unless cmd_process ($result{'command'}, $result{'Rarguments'}, $task_file, \%vars, $lnb);
	}
    } 

    close (TASK);

    return 1;
}


sub cmd_process {

    my $command = $_[0]; # command name
    my $Rarguments = $_[1]; # command arguments
    my $task_file = $_[2]; # task
    my $Rvars = $_[3]; # variable list of the task
    my $lnb = $_[4]; # line number

     # building of %context
    my %context; # datas necessary to command processing
    $context{'task_file'} = $task_file; # long task file name
    $task_file =~ /\/($regexp{'listname'})$/i;
    $context{'task_name'} = $1; # task file name
    $context{'task_name'} =~ /^(\d+)\..+/;
    $context{'execution_date'} = $1; # task execution date
    $context{'task_name'} =~ /^\w+\.\w*\.\w+\.($regexp{'listname'})$/;
    $context{'object_name'} = $1; # object of the task
    $context{'line_number'} = $lnb;

     # regular commands
    return stop (\%context) if ($command eq 'stop');
    return next_cmd ($Rarguments, \%context) if ($command eq 'next');
    return create_cmd ($Rarguments, \%context) if ($command eq 'create');
    return exec_cmd ($Rarguments) if ($command eq 'exec');
    return update_crl ($Rarguments, \%context) if ($command eq 'update_crl');
    return expire_bounce ($Rarguments, \%context) if ($command eq 'expire_bounce');

     # commands which use a variable
    return send_msg ($Rarguments, $Rvars, \%context) if ($command eq 'send_msg');       
    return rm_file ($Rarguments, $Rvars, \%context) if ($command eq 'rm_file');

     # commands which return a variable
    return select_subs ($Rarguments, \%context) if ($command eq 'select_subs');
    return chk_cert_expiration ($Rarguments, \%context) if ($command eq 'chk_cert_expiration');

     # commands which return and use a variable
    return delete_subs_cmd ($Rarguments, $Rvars, \%context) if ($command eq 'delete_subs');  
}


### command subroutines ###
 
 # remove files whose name is given in the key 'file' of the hash
sub rm_file {
        
    my $Rarguments = $_[0];
    my $Rvars = $_[1];
    my $context = $_[2];
    
    my @tab = @{$Rarguments};
    my $var = $tab[0];

    foreach my $key (keys %{$Rvars->{$var}}) {
	my $file = $Rvars->{$var}{$key}{'file'};
	next unless ($file);
	unless (unlink ($file)) {
	    error ("$context->{'task_file'}", "error in rm_file command : unable to remove $file");
	    return undef;
	}
    }
}

sub stop {

    my $context = $_[0];
    my $task_file = $context->{'task_file'};

    &do_log ('notice', "$context->{'line_number'} : stop $task_file");
    
    unlink ($task_file) ?  
	&do_log ('notice', "--> $task_file deleted")
	    : error ($task_file, "error in stop command : unable to delete task file");

    return undef;
}

sub send_msg {
        
    my $Rarguments = $_[0];
    my $Rvars = $_[1];
    my $context = $_[2];
    
    my @tab = @{$Rarguments};
    my $template = $tab[1];
    my $var = $tab[0];
    
    &do_log ('notice', "line $context->{'line_number'} : send_msg (@{$Rarguments})");


    if ($context->{'object_name'} eq '_global') {

	foreach my $email (keys %{$Rvars->{$var}}) {
	    &do_log ('notice', "--> message sent to $email");
	    &List::send_global_file ($template, $email, $Rvars->{$var}{$email}) if (!$log);
	}
    } else {
	my $list = new List ($context->{'object_name'});
        
	foreach my $email (keys %{$Rvars->{$var}}) {
	    &do_log ('notice', "--> message sent to $email");
	    $list->send_file ($template, $email, $Rvars->{$var}{$email}) if (!$log);
	}
    }
    return 1;
}

sub next_cmd {
    
    my $Rarguments = $_[0];
    my $context = $_[1];
    
    my @tab = @{$Rarguments};
    my $date = &tools::epoch_conv ($tab[0], $context->{'execution_date'}); # conversion of the date argument into epoch format
    my $label = $tab[1];
    
    &do_log ('notice', "line $context->{'line_number'} of $context->{'task_name'} : next ($date, $label)");

    $context->{'task_name'} =~ /\w*\.\w*\.(\w*)\.(($regexp{'listname'})|_global)/;

    my $new_task = "$date.$label.$1.$2";
    my $human_date = &tools::adate ($date);
    my $new_task_file = "$spool_task/$new_task";
    unless (rename ($context->{'task_file'}, $new_task_file)) {
	error ("$context->{'task_file'}", "error in next command : unable to rename task file into $new_task");
	return undef;
    }
    &do_log ('notice', "--> new task $new_task ($human_date)");
    
    return undef;
}

sub select_subs {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my @tab = @{$Rarguments};
    my $condition = $tab[0];
 
    &do_log ('debug2', "line $context->{'line_number'} : select_subs ($condition)");
    $condition =~ /(\w+)\(([^\)]*)\)/;
    if ($2) { # conversion of the date argument into epoch format
	my $date = &tools::epoch_conv ($2, $context->{'execution_date'});
        $condition = "$1($date)";
    }  
 
    my @users; # the subscribers of the list      
    my %selection; # hash of subscribers who match the condition
    my $list = new List ($context->{'object_name'});
    
    if ( $list->{'admin'}{'user_data_source'} =~ /database|file/) {
        for ( my $user = $list->get_first_user(); $user; $user = $list->get_next_user() ) { 
            push (@users, $user);
	}
    }
    
    my $verify_context; # parameter of subroutine List::verify
    $verify_context->{'sender'} = 'nobody' ;
    $verify_context->{'email'} = $verify_context->{'sender'};
    $verify_context->{'remote_host'} = 'unknown_host';
    $verify_context->{'listname'} = $context->{'object_name'};
    
    my $new_condition = $condition; # necessary to the older & newer condition rewriting
    # loop on the subscribers of $list_name
    foreach my $user (@users) {

	# AF : voir 'update' do_log ('notice', "date $user->{'date'} & update $user->{'update'}");
	# condition rewriting for older and newer
	$new_condition = "$1($user->{'update_date'}, $2)" if ($condition =~ /(older|newer)\((\d+)\)/ );
	
	if (&List::verify ($verify_context, $new_condition) == 1) {
	    $selection{$user->{'email'}} = undef;
	    &do_log ('notice', "--> user $user->{'email'} has been selected");
	}
    }
    
    return \%selection;
}

sub delete_subs_cmd {

    my $Rarguments = $_[0];
    my $Rvars = $_[1];
    my $context = $_[2];

    my @tab = @{$Rarguments};
    my $var = $tab[0];

    &do_log ('notice', "line $context->{'line_number'} : delete_subs ($var)");

    
    my $list = new List ($context->{'list_name'});
    my %selection; # hash of subscriber emails who are successfully deleted

    foreach my $email (keys %{$Rvars->{$var}}) {

	&do_log ('notice', "email : $email");
	my $action = &List::request_action ('del', 'smime',
					    {'listname' => $context->{'list_name'},
					     'sender'   => $Conf{'listmaster'},
					     'email'    => $email,
					 });
	if ($action =~ /reject/i) {
	    error ("$context->{'task_file'}", "error in delete_subs command : deletion of $email not allowed");
	} else {
	    my $u = $list->delete_user ($email) if (!$log);
	    $list->save() if (!$log);;
	    &do_log ('notice', "--> $email deleted");
	    $selection{$email} = {};
	}
    }

    return \%selection;
}

sub create_cmd {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my @tab = @{$Rarguments};
    my $arg = $tab[0];
    my $model = $tab[1];
    my $model_choice = $tab[2];

    &do_log ('notice', "line $context->{'line_number'} : create ($arg, $model, $model_choice)");

    # recovery of the object type and object
    my $type;
    my $object;
    if ($arg =~ /$subarg_regexp/) {
	$type = $1;
	$object = $3;
    } else {
	error ($context->{'task_file'}, "error in create command : don't know how to create $arg");
	return undef;
    }

    # building of the data hash necessary to the create subroutine
    my %data = ('creation_date'  => $context->{'execution_date'},
		'execution_date' => 'execution_date');

    if ($type eq 'list') {
	my $list = new List ($object);
	$data{'list'}{'name'} = $list->{'name'};
    }
    if ($type eq 'global') {
	$type = '_global';
    }

    unless (create ($context->{'execution_date'}, '', $model, $model_choice, $type, \%data)) {
	error ($context->{'task_file'}, "error in create command : creation subroutine failure");
	return undef;
    }
    
    return 1;
}

sub exec_cmd {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my @tab = @{$Rarguments};
    my $file = $tab[0];

    do_log ('notice', "line $context->{'line_number'} : exec ($file)");
    system ($file);
    
    return 1;
}

sub expire_bounce {
    # If a bounce is older then $list->get_latest_distribution_date()-$delai expire the bounce
    # Is this variable my be set in to task modele ?
    my $Rarguments = $_[0];
    my $context = $_[1];
    
    my $execution_date = $context->{'execution_date'};
    my @tab = @{$Rarguments};
    my $delay = $tab[0];

    do_log('debug2',"bounce expiration task  using $delay days as delay");
    foreach my $listname (&List::get_lists('*') ) {
	my $list = new List ($listname);
	# the reference date is the date until which we expire bounces in second
        # the latest_distribution_date is the date of last distribution #days from 01 01 1970
	unless ( $list->{'admin'}{'user_data_source'} eq 'database' ) {
	    # do_log('notice','bounce expiration : skipping list %s because not using database',$listname);
	    next;
	}
	
	unless ($list->get_latest_distribution_date()) {
	    do_log('debug2','bounce expiration : skipping list %s because could not get latest distribution date',$listname);
	    next;
	}
	my $refdate = (($list->get_latest_distribution_date() - $delay) * 3600 * 24);
	
	for (my $u = $list->get_first_bouncing_user(); $u ; $u = $list->get_next_bouncing_user()) {
	    $u->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
            $u->{'last_bounce'} = $2;
	    if ($u->{'last_bounce'} < $refdate) {
		my $email = $u->{'email'};
		
		unless ( $list->is_user($email) ) {
		    do_log('info','expire_bounce: %s not subscribed', $email);
		    next;
		}
		
		unless( $list->update_user($email, {'bounce' => 'NULL', 'update_date' => time})) {
		    do_log('info','expire_bounce: failed update database for %s', $email);
		    next;
		}
		my $escaped_email = &tools::escape_chars($email);
		unless (unlink "$wwsconf->{'bounce_path'}/$listname/$escaped_email") {
		    do_log('info','expire_bounce: failed deleting %s', "$wwsconf->{'bounce_path'}/$listname/$escaped_email");
	           next;
		}
		do_log('info','expire bounces for subscriber %s of list %s (last distribution %s, last bounce %s )',
                       $email,$listname,
                       &POSIX::strftime("%d %b %Y", localtime($list->get_latest_distribution_date() * 3600 * 24)),
		       &POSIX::strftime("%d %b %Y", localtime($u->{'last_bounce'})));
		
	    }
	}
    }

    return 1;
}

sub chk_cert_expiration {

    my $Rarguments = $_[0];
    my $context = $_[1];
        
    my $execution_date = $context->{'execution_date'};
    my @tab = @{$Rarguments};
    my $template = $tab[0];
    my $limit = &tools::duration_conv ($tab[1], $execution_date);

    &do_log ('notice', "line $context->{'line_number'} : chk_cert_expiration (@{$Rarguments})");
 
    ## building of certificate list
    unless (opendir(DIR, $cert_dir)) {
	error ($context->{'task_file'}, "error in chk_cert_expiration command : can't open dir $cert_dir");
	return undef;
    }
    my @certificates = grep !/^(\.\.?)|(.+expired)$/, readdir DIR;
    close (DIR);

    foreach (@certificates) {

	my $soon_expired_file = $_.'.soon_expired'; # an empty .soon_expired file is created when a user is warned that his certificate is soon expired

	# recovery of the certificate expiration date 
	open (ENDDATE, "openssl x509 -enddate -in $cert_dir/$_ -noout |");
	my $date = <ENDDATE>; # expiration date
	close (ENDDATE);
	chomp ($date);
	
	unless ($date) {
	    &do_log ('err', "error in chk_cert_expiration command : can't get expiration date for $_ by using the x509 openssl command");
	    next;
	}
	
	$date =~ /notAfter=(\w+)\s*(\d+)\s[\d\:]+\s(\d+).+/;
	my @date = (0, 0, 0, $2, $months{$1}, $3 - 1900);
	$date =~ s/notAfter=//;
	my $expiration_date = timegm (@date); # epoch expiration date
	my $rep = &tools::adate ($expiration_date);

	# no near expiration nor expiration processing
	if ($expiration_date > $limit) { 
	    # deletion of unuseful soon_expired file if it is existing
	    if (-e $soon_expired_file) {
		unlink ($soon_expired_file) || &do_log ('err', "error : can't delete $soon_expired_file");
	    }
	    next;
	}
	
	# expired certificate processing
	if ($expiration_date < $execution_date) {
	    
	    &do_log ('notice', "--> $_ certificate expired ($date), certificate file deleted");
	    if (!$log) {
		unlink ("$cert_dir/$_") || &do_log ('notice', "error : can't delete certificate file $_");
	    }
	    if (-e $soon_expired_file) {
		unlink ("$cert_dir/$soon_expired_file") || &do_log ('err', "error : can't delete $soon_expired_file");
	    }
	    next;
	}

	# soon expired certificate processing
	if ( ($expiration_date > $execution_date) && 
	     ($expiration_date < $limit) &&
	     !(-e $soon_expired_file) ) {

	    unless (open (FILE, ">$cert_dir/$soon_expired_file")) {
		&do_log ('err', "error in chk_cert_expiration : can't create $soon_expired_file");
		next;
	    } else {close (FILE);}
	    
	    my %tpl_context; # datas necessary to the template

	    open (ID, "openssl x509 -subject -in $cert_dir/$_ -noout |");
	    my $id = <ID>; # expiration date
	    close (ID);
	    chomp ($id);
	    
	    unless ($id) {
		&do_log ('err', "error in chk_cert_expiration command : can't get expiration date for $_ by using the x509 openssl command");
		next;
	    }

	    $id =~ s/subject= //;
	    do_log ('notice', "id : $id");
	    $tpl_context{'expiration_date'} = &tools::adate ($expiration_date);
	    $tpl_context{'certificate_id'} = $id;
	
	    &List::send_global_file ($template, $_, \%tpl_context) if (!$log);
	    &do_log ('notice', "--> $_ certificate soon expired ($date), user warned");
	}
    }
    return 1;
}


## attention, j'ai n'ai pas pu comprendre les retours d'erreurs des commandes wget donc pas de verif sur le bon fonctionnement de cette commande
sub update_crl {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my @tab = @{$Rarguments};
    my $limit = &tools::epoch_conv ($tab[1], $context->{'execution_date'});
    my $CA_file = "$Conf{'home'}/$tab[0]"; # file where CA urls are stored ;
    &do_log ('notice', "line $context->{'line_number'} : update_crl (@tab)");

    # building of CA list
    my @CA;
    unless (open (FILE, $CA_file)) {
	error ($context->{'task_file'}, "error in update_crl command : can't open $CA_file file");
	return undef;
    }
    while (<FILE>) {
	chomp;
	push (@CA, $_);
    }
    close (FILE);

    # updating of crl files
    my $crl_dir = "$Conf{'crl_dir'}";
    unless (-d $Conf{'crl_dir'}) {
	if ( mkdir ($Conf{'crl_dir'}, 0775)) {
	    do_log('notice', "creating spool $Conf{'crl_dir'}");
	}else{
	    do_log('err', "Unable to create CRLs directory $Conf{'crl_dir'}");
	    return undef;
	}
    }

    foreach my $url (@CA) {
	
	my $crl_file = &tools::escape_chars ($url); # convert an URL into a file name
	my $file = "$crl_dir/$crl_file";
	
	## create $file if it doesn't exist
	unless (-e $file) {
	    my $cmd = "wget -O \'$file\' \'$url\'";
	    open CMD, "| $cmd";
	    close CMD;
	}

	 # recovery of the crl expiration date
	open (ID, "openssl crl -nextupdate -in \'$file\' -noout -inform der|");
	my $date = <ID>; # expiration date
	close (ID);
	chomp ($date);

	unless ($date) {
	    &do_log ('err', "error in update_crl command : can't get expiration date for $file crl file by using the crl openssl command");
	    next;
	}

	$date =~ /nextUpdate=(\w+)\s*(\d+)\s(\d\d)\:(\d\d)\:\d\d\s(\d+).+/;
	my @date = (0, $4, $3 - 1, $2, $months{$1}, $5 - 1900);
	my $expiration_date = timegm (@date); # epoch expiration date
	my $rep = &tools::adate ($expiration_date);

	## check if the crl is soon expired or expired
	#my $file_date = $context->{'execution_date'} - (-M $file) * 24 * 60 * 60; # last modification date
	my $condition = "newer($limit, $expiration_date)";
	my $verify_context;
	$verify_context->{'sender'} = 'nobody';

	if (&List::verify ($verify_context, $condition) == 1) {
	    unlink ($file);
	    &do_log ('notice', "--> updating of the $file crl file");
	    my $cmd = "wget -O \'$file\' \'$url\'";
	    open CMD, "| $cmd";
	    close CMD;
	    next;
	}
    }
    return 1;
}

### MISCELLANEOUS SUBROUTINES ### 

## when we catch SIGTERM, just change the value of the loop variable.
sub sigterm {
    $end = 1;
}

## sort task name by their epoch date
sub epoch_sort {

    $a =~ /(\d+)\..+/;
    my $date1 = $1;
    $b =~ /(\d+)\..+/;
    my $date2 = $1;
    
    $date1 <=> $date2;
}

## return true if $element is in @tab
sub in {
    my $Rtab = $_[0];
    my $element = $_[1];

    foreach (@$Rtab) {
	return 1 if ($element eq $_);
    }
    return undef;
}

## change the label of a task file
sub change_label {
    my $task_file = $_[0];
    my $new_label = $_[1];
    
    my $new_task_file = $task_file;
    $new_task_file =~ s/(.+\.)(\w*)(\.\w+\.\w+$)/$1$new_label$3/;

    if (rename ($task_file, $new_task_file)) {
	&do_log ('notice', "$task_file renamed in $new_task_file");
    } else {
	&do_log ('err', "error ; can't rename $task_file in $new_task_file");
    }
}

## send a error message to list-master, log it, and change the label task into 'ERROR' 
sub error {
    my $task_file = $_[0];
    my $message = $_[1];

    my @param;
    $param[0] = "An error has occured during the execution of the task $task_file :
                 $message";
    do_log ('err', "$message");
    change_label ($task_file, 'ERROR') unless ($task_file eq '');
    &List::send_notify_to_listmaster ('error in task', $Conf{'domain'}, @param);
}
