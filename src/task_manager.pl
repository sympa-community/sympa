#! --PERL--

## Worl Wide Sympa is a front-end to Sympa Mailing Lists Manager
## Copyright Comite Reseau des Universites


## Options :  F         -> do not detach TTY
##         :  d		-> debug -d is equiv to -dF

## Change this to point to your Sympa bin directory
use lib '--DIR--/bin';
use strict vars;

use List;
use Conf;
use Log;
use Getopt::Long;
use Time::Local;
use MD5;
use smtp;
use wwslib;

#AF : change_label ERROR pour toutes les cdmes qd elles merdent ?
require 'parser.pl';
require 'tools.pl';


my $sender;

my $opt_d;
my $opt_F;
my %options;
&GetOptions(\%main::options, 'dump=s', 'debug|d', 'foreground', 'config|f=s', 
	    'lang|l=s', 'mail|m', 'keepcopy|k=s', 'help', 'version', 'import=s', 'lowercase');

$main::options{'debug2'} = 1 if ($main::options{'debug'});

my $Version = '0.1';

my $wwsympa_conf = "--WWSCONFIG--";
my $sympa_conf_file = '--CONFIG--';

my $wwsconf = {};
my $adrlist = {};

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


## Set the UserID & GroupID for the process
$< = $> = (getpwnam('sympa'))[2];
$( = $) = (getpwnam('sympa'))[2];

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
    if (($_ = fork) != 0) {
	&do_log('debug', "Starting task_manager daemon, pid $_");
	exit(0);
    }
    $wwsconf->{'log_facility'}||= $Conf{'syslog'};
    do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'task_manager');
}


## Sets the UMASK
umask($Conf{'umask'});

## Change to list root
unless (chdir($Conf{'home'})) {
    &message('chdir_error');
    &do_log('err','error : unable to change directory');
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

## Create and write the pidfile
unless (open(LOCK, "+>> $wwsconf->{'task_manager_pidfile'}")) {
    fatal_err("Could not open %s, exiting", $wwsconf->{'task_manager_pidfile'});
}
unless (flock(LOCK, 6)) {
    &do_log ('err', "Could not lock $wwsconf->{'task_manager_pidfile'} : task_manager is probably already running");
    fatal_err("Could not lock %s: task_manager is probably already running.", $wwsconf->{'task_manager_pidfile'});
}
unless (open(LCK, "> $wwsconf->{'task_manager_pidfile'}")) {
    fatal_err("Could not open %s, exiting", $wwsconf->{'task_manager_pidfile'});
}
unless (truncate(LCK, 0)) {
    fatal_err("Could not truncate %s, exiting.", $wwsconf->{'task_manager_pidfile'});
}

print LCK "$$\n";
close(LCK);

## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
my $end = 0;

###### VARIABLES DECLARATION ######

my $spool_task = $Conf{'queuetask'};
my $std_general_task_model_dir = "--ETCBINDIR--/global_task_models";
my $user_general_task_model_dir = "--DIR--/etc/global_task_models";
my $certif_dir = $Conf{'ssl_cert_dir'};
my @tasks; # list of tasks in the spool

undef my $log; # won't execute send_msg and delete commands if true, only log
#$log = 1;

## building of the list of models concerning individual lists
my @list_models = ('expire','remind');

## month hash used by epoch conversion routines
my %months = ('Jan', 0, 'Feb', 1, 'Mar', 2, 'Apr', 3, 'May', 4,  'Jun', 5, 
	      'Jul', 6, 'Aug', 7, 'Sep', 8, 'Oct', 9, 'Nov', 10, 'Dec', 11);

###### DEFINITION OF AVAILABLE COMMANDS FOR TASKS ######

my $date_arg_regexp1 = '\d+|execution_date';
my $date_arg_regexp2 = '(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?'; 
my $date_arg_regexp3 = '(\d+|execution_date)(\+|\-)(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?';
my $delay_regexp = '(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?';
my $var_regexp ='@\w+'; 
my $subarg_regexp = '(\w+)\((.*)\)'; # for argument with sub argument (ie arg(sub_arg))
                 
# regular commands
my %commands = ('next'                  => ['date', '\w*'],
		                           # date   label
                'stop'                  => [],
		'create'                => ['subarg', '\w+', '\w+'],
		                           #object    model  model choice
		'exec'                  => ['.+'],
		                           #script
		'chk_certif_expiration' => ['\w+',   'delay'],
		                           #template  delay
		'update_CRL'            => ['\w+', 'delay'], 
					   #file    #delay
		);

# commands which use a variable. If you add such a command, the first parameter must be the variable
my %var_commands = ('delete'      => ['var'],
		                     # variable 
		    'send_msg'    => ['var',  '\w+' ],
		                     #variable template
		    );
my @var_commands;
foreach (keys %var_commands) {
    $commands{$_} = $var_commands{$_};
    push (@var_commands, $_);
}

# commands which are used for assignments
my %asgn_commands = ('select_subs' => ['subarg'],
		                      # condition
		     'delete'      => ['var'],
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
    &do_log ('notice', "****** $rep ******");

    ## @tasks initialisation
    unless (opendir(DIR, $spool_task)) {
	&do_log ('err', "error : can't open dir %s: %m", $spool_task);
    }
    my @tasks = sort epoch_sort (grep !/^\.\.?$/, readdir DIR);

    ## processing of tasks anterior to the current date
    &do_log ('notice', 'processing of tasks anterior to the current date');
    foreach my $task (@tasks) {
	$task =~ /(\d+)\..+/;
	last unless ($1 < $current_date);
	execute ("$spool_task/$task");
    }
    &do_log ('notice', 'done');

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

    ## general tasks
    
     # user general task models
    if (opendir(DIR, $user_general_task_model_dir)) {
	my @files = grep !/^\.\.?$/, readdir DIR;
	foreach (@files) {
	    /(\w+)\.(\w+)\.task/;
	    my %data = %default_data; # hash of datas necessary to the creation of tasks
	    if (!in (\@used_models, $1)) {
		create ($current_date, '', $1, $2, 'global_task', \%data);
		push (@used_models, $1);
	    } 
	}
    }

     # standart general task models
    if  (opendir(DIR, $std_general_task_model_dir)) {
	my @files = grep !/^\.\.?$/, readdir DIR;
	foreach (@files) {
	    /(\w+)\.(\w+)\.task/;
	    my %data = %default_data;
	    if (!in (\@used_models, $1)) {
		create ($current_date, '', $1, $2, 'global_task', \%data);
		push (@used_models, $1);
	    }
	    create ($current_date, '', $1, $2, 'global_task', \%data) if (! in (\@used_models, $1));
	}
    } else {
	&do_log ('err', "error : can't open dir %s: %m", $std_general_task_model_dir);
    }
    
    
    ## tasks concerning individuals lists : loop on the lists
    
    foreach ( &List::get_lists() ) {
	
	my %data = %default_data;
	my $list = new List ($_);
	
	$data{'list'}{'name'} = $list->{'name'};
	
	my %list_models; # stores which models already have a task 
	foreach (@list_models) { $list_models{$_} = undef; }
	
	foreach $_ (@tasks) {
	   /(.*)\.(.*)\.(.*)\.(.*)/;
	   my $model = $3;
	   my $object = $4;
	   if ($object eq $list->{'name'}) { $list_models {$model} = 1; }
       }
        
	foreach my $model (keys %list_models) {
	    unless ($list_models{$model}) {
		if ( $list->{'admin'}{$model.'_task'} ) {
		    create ($current_date, '', $model, $list->{'admin'}{$model.'_task'}, 'list', \%data);
		}
#       elsif {} creation d'un modele par defaut si ce type de tache l'exige
	    }
	}
    }
   
    sleep 60;
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

     # for general model
    if ($object eq 'global_task') {
	if (open (MODEL, "$user_general_task_model_dir/$model_name")) {
	    $model_file = "$user_general_task_model_dir/$model_name";
	} elsif (open (MODEL, "$std_general_task_model_dir/$model_name")) {
	    $model_file = "$std_general_task_model_dir/$model_name";
	} else { 
	    &do_log ('err', "error : unable to find $model_name, creation aborted");
	    return undef;
	}
    }

     # for a list
    if ($object  eq 'list') {
	if (open (MODEL, "$Conf{'home'}/$list_name/list_task_models/$model_name")) {
	    $model_file = "$Conf{'home'}/$list_name/list_task_models/$model_name";
	} elsif (open (MODEL, "$Conf{'etc'}/list_task_models/$model_name")) {
	    $model_file = "$Conf{'etc'}/list_task_models/$model_name";
	} elsif (open (MODEL, "--DIR--/bin/etc/list_task_models/$model_name")) {
	    $model_file = "--DIR--/bin/etc/list_task_models/$model_name";
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
    
    # special checking for list whose user_data_source config parmater is include. The task won't be created if there is a delete command
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
		if (/.*delete.*/) {
		    close (TASK);
		    undef $ok;
		    &do_log ('err', "error : you are not allowed to use the delete command on a list whose subscribers are included, creation aborted");
		    last;
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
    if ($line =~ /^\s*title\...\s*(.*)\s*/) {
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
    
	my $command = $1;
	my @args = split (/,/, $2);
	foreach (@args) { s/\s//g;}
	my $is_cmd = undef;

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
	    &do_log ('notice', "$hash2{'command'}");
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
		&do_log ('err',"error at line $lnb : wrong number of arguments for $command");
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
    &do_log ('notice', "* execution of the task $task_file");

    # positioning at the right label
    $_[0] =~ /\w*\.(\w*)\..*/;
    my $label = $1;
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
	    &do_log ('err',"error : $result{'error'}");
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
    $task_file =~ /.+\/([\w\.]+)$/;
    $context{'task_name'} = $1; # task file name
    $context{'task_name'} =~ /(\d+)\..+/;
    $context{'execution_date'} = $1; # task execution date
    $context{'task_name'} =~ /^\w+\.\w*\.\w+\.(\w+)$/;
    $context{'object_name'} = $1; # object of the task
    $context{'line_number'} = $lnb;
    
    return stop (\%context) if ($command eq 'stop');
    return send_msg ($Rarguments, $Rvars, \%context) if ($command eq 'send_msg');       
    return next_cmd ($Rarguments, \%context) if ($command eq 'next');
    return select_subs ($Rarguments, \%context) if ($command eq 'select_subs');
    return delete_cmd ($Rarguments, $Rvars, \%context) if ($command eq 'delete');
    return create_cmd ($Rarguments, \%context) if ($command eq 'create');
    return exec_cmd ($Rarguments) if ($command eq 'exec');
    return chk_certif_expiration ($Rarguments, \%context) if ($command eq 'chk_certif_expiration');
    return update_CRL ($Rarguments, \%context) if ($command eq 'update_CRL');
}


### command subroutines ###

sub stop {

    my $context = $_[0];
    my $task_file = $context->{'task_file'};

    &do_log ('notice', "$context->{'line_number'} : stop $task_file");
    
    unlink ($task_file) ? 
	&do_log ('notice', "$task_file deleted") 
	    : &do_log ('err', "error : unable to delete $task_file");
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

    my $list = new List ($context->{'object_name'});
        
    foreach my $email (@{$Rvars->{$var}}) {
	&do_log ('notice', "--> message sent to $email");
	my %msg_context;
	&List::send_file ($list, $template, $email, \%msg_context) if (!$log);
    }
    
    return 1;
}

sub next_cmd {
    
    my $Rarguments = $_[0];
    my $context = $_[1];
    
    my @tab = @{$Rarguments};
    my $date = &tools::epoch_conv ($tab[0], $context->{'execution_date'}); # conversion of the date argument into epoch format
    my $label = $tab[1];
    
    &do_log ('notice', "line $context->{'line_number'} : next ($date, $label)");

    $context->{'task_name'} =~ /\w*\.\w*\.(\w*)\.(\w*)/;
    my $new_task = "$date.$label.$1.$2";
    my $human_date = &tools::adate ($date);
    my $new_task_file = "$spool_task/$new_task";
    unless (rename ($context->{'task_file'}, $new_task_file)) {
	&do_log ('err', "error : unable to rename $context->{'task_file'} en $new_task");
    }
    &do_log ('notice', "--> new task $new_task ($human_date)");
    
    return undef;
}

sub select_subs {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my @tab = @{$Rarguments};
    my $condition = $tab[0];
 
    &do_log ('debug', "line $context->{'line_number'} : select_subs ($condition)");
    $condition =~ /(\w+)\(([^\)]*)\)/;
    if ($2) { # conversion of the date argument into epoch format
	my $date = &tools::epoch_conv ($2, $context->{'execution_date'});
        $condition = "$1($date)";
    }  
 
    my @users; # the subscribers of the list      
    my @selection; # list of subscribers who match the condition
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
	    push (@selection, $user->{'email'});
	    &do_log ('notice', "--> user $user->{'email'} has been selected");
	}
    }
    
    return \@selection;
}

sub delete_cmd {

    my $Rarguments = $_[0];
    my $Rvars = $_[1];
    my $context = $_[2];

    my @tab = @{$Rarguments};
    my $var = $tab[0];

    &do_log ('notice', "line $context->{'line_number'} : delete ($var)");

    
    my $list = new List ($context->{'list_name'});
    my @selection; # list of subscriber emails who are successfully deleted

    foreach my $email (@{$Rvars->{$var}}) {

	&do_log ('notice', "email : $email");
	my $action = &List::request_action ('del', 'smime',
					    {'listname' => $context->{'list_name'},
					     'sender'   => $Conf{'listmaster'},
					     'email'    => $email,
					 });
	if ($action =~ /reject/i) {
	    &do_log('err', "error : deletion of $email not allowed");
	}
	### AF : voir le cas $action eq 'request_auth'
	
	if ($action =~ /do_it/i) {
	    my $u = $list->delete_user ($email) if (!$log);
	    $list->save() if (!$log);;
	    &do_log ('notice', "--> $email deleted");
	    push (@selection, $email);
	}
    }

    return \@selection;
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
	$object = $2;
    } else {
	&do_log ('notice', "error : don't know how to create $arg, task interrupted");
        change_label ($context->{'task_file'}, 'ERROR');
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
	$type = 'global_task';
        # AF prepare le %data
    }

    unless (create ($context->{'execution_date'}, '', $model, $model_choice, $type, \%data)) {
	&do_log ('err', "creation command failed, task interrupted");
        change_label ($context->{'task_file'}, 'ERROR');
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

sub chk_certif_expiration {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my $execution_date = $context->{'execution_date'};
    my @tab = @{$Rarguments};
    my $template = $tab[0];
    my $delay = &tools::duration_conv ($tab[1], $execution_date);

    &do_log ('notice', "line $context->{'line_number'} : chk_certif_expiration (@{$Rarguments})");
 
    ## building of certificate list
    unless (opendir(DIR, $certif_dir)) {
	&do_log ('err', "error : can't open dir %s: %m", $certif_dir);
    }
    my @certificates = grep !/^(\.\.?)|(.+expired)$/, readdir DIR;
    close (DIR);
 
    chdir($certif_dir);

    foreach (@certificates) {

	my $soon_expired_file = $_.'.soon_expired'; # an empty .soon_expired file is created when a user iw warned his certificate is soon expired

	# recovery of the certificate expiration date 
	open (ENDDATE, "openssl x509 -enddate -in $_ -noout |");
	my $date = <ENDDATE>; # expiration date
	close (ENDDATE);
	chomp ($date);
	next unless ($date);
	$date =~ /notAfter=(\w+)\s*(\d+)\s[\d\:]+\s(\d+).+/;
	my @date = (0, 0, 0, $2, $months{$1}, $3 - 1900);
	$date =~ s/notAfter=//;
	my $expiration_date = timegm (@date); # epoch expiration date

	# no near expiration nor expiration processing
	if ($expiration_date > $execution_date + $delay) { 
	    # deletion of unuseful soon_expired file if it is existing
	    if (-e $soon_expired_file) {
		unlink ($_) || &do_log ('err', "error : can't delete $soon_expired_file");
	    }
	    next;
	}
	
	# expired certificate processing
	if ($expiration_date < $execution_date) {
	    
	    &do_log ('notice', "--> $_ certificate expired ($date), certificate file deleted");
	    if (!$log) {
		unlink ($_) || &do_log ('notice', "error : can't delete certificate file $_");
	    }
	}

	# soon expired certificate processing
	if ( ($expiration_date > $execution_date) && 
	     ($expiration_date < $execution_date + $delay) &&
	     !(-e $soon_expired_file) ) {

	    open (FILE, ">$soon_expired_file") || &do_log ('error', "error : can't create $soon_expired_file");
	    close (FILE);
	    
	    my %tpl_context; # datas necessary to the template

	    open (ID, "openssl x509 -subject -in $_ -noout |");
	    my $id = <ID>; # expiration date
	    close (ID);
	    chomp ($id);
	    $id =~ s/subject= //;
	    do_log ('notice', "id : $id");
	    $tpl_context{'expiration_date'} = &tools::adate ($expiration_date);
	    $tpl_context{'certificate_id'} = $id;
	
	    &List::send_global_file ($template, $_, \%tpl_context) if (!$log);
	    &do_log ('notice', "--> $_ certificate soon expired ($date), user warned");
	}
    }
    chdir ($Conf{'home'});
    return 1;
}

sub update_CRL {

    my $Rarguments = $_[0];
    my $context = $_[1];

    my @tab = @{$Rarguments};
    my $delay = $tab[1];
    my $CA_file = "/usr/local/sympb/expl/$tab[0]"; # file where CA urls are stored ; AF completer avec un DIR std defini dans %conf
   
    &do_log ('notice', "line $context->{'line_number'} : update_CRL (@tab)");

    # building of CA list
    my @CA;
    unless (open (FILE, $CA_file)) {
	&do_log ('err', "error : can't open $CA_file file");
        change_label ($context->{'task_file'}, 'ERROR');
	return undef;
    }
    while (<FILE>) {
	chomp;
	push (@CA, $_);
    }
    close (FILE);

    # updating of CRL files
    my $CRL_dir = '/usr/local/sympb/expl/CRL'; # AF : sera defini dans la conf
    foreach my $url (@CA) {
	
	my $crl_file = &tools::escape_chars ($url); # convert an URL into a file name
	my $file = "$CRL_dir/$crl_file";
	
	## create $file if it doesn't exist
	unless (-e $file) {
	    my $cmd = "wget -F -O \'$file\' \'$url\'";
	    open CMD, "| $cmd";
	    close CMD;
	    next;
	}

	 # building of the CRL expiration date
	open (ID, "openssl crl -nextupdate -in \'$file\' -noout -inform der|");
	my $date = <ID>; # expiration date
	close (ID);
	chomp ($date);
	next unless ($date);
	$date =~ /nextUpdate=(\w+)\s*(\d+)\s(\d\d)\:(\d\d)\:\d\d\s(\d+).+/;
	my @date = (0, $4, $3 - 1, $2, $months{$1}, $5 - 1900);
	my $expiration_date = timegm (@date); # epoch expiration date

	## check if the CRL is soon expired or expired
	my $file_date = $context->{'execution_date'} - (-M $file) * 24 * 60 * 60; # last modification date
	my $limit = &tools::epoch_conv ("$expiration_date-$delay", $context->{'execution_date'});
	my $condition = "older($file_date, $limit)";
	my $verify_context;
	$verify_context->{'sender'} = 'nobody';

	my $rep1 = &tools::adate ($file_date);
	my $rep2 = &tools::adate ($limit);
	do_log ('notice', "date dernier acces fichier $rep1");
	do_log ('notice', "date limite $rep2");
	if (&List::verify ($verify_context, $condition) == 1) {
	    unlink ($file);
	    my $cmd = "wget -F -O \'$file\' \'$url\'";
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
