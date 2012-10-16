# Task.pm - This module includes Task processing functions, used by task_manager.pl
#<!-- RCS Identication ; $Revision$ ; $Date$ --> 

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

package Task;

use strict;

use Carp;
use Data::Dumper;
use Digest::MD5;
use Exporter;
use Time::Local;

use Bulk;
use Conf;
use List;
use Log;
use mail;
use Scenario;
use Sympaspool;
use tools;
use tracking;
use tt2;

my @task_list;
my %task_by_list;
my %task_by_model;

my $taskspool ;

my @tasks; # list of tasks in the spool

## list of list task models
#my @list_models = ('expire', 'remind', 'sync_include');
our @list_models = ('sync_include','remind');

## hash of the global task models
our %global_models = (#'crl_update_task' => 'crl_update', 
		     #'chk_cert_expiration_task' => 'chk_cert_expiration',
		     'expire_bounce_task' => 'expire_bounce',
		     'purge_user_table_task' => 'purge_user_table',
		     'purge_logs_table_task' => 'purge_logs_table',
		     'purge_session_table_task' => 'purge_session_table',
		     'purge_tables_task' => 'purge_tables',
		     'purge_one_time_ticket_table_task' => 'purge_one_time_ticket_table',
		     'purge_orphan_bounces_task' => 'purge_orphan_bounces',
		     'eval_bouncers_task' => 'eval_bouncers',
		     'process_bouncers_task' =>'process_bouncers',
		     #,'global_remind_task' => 'global_remind'
		     );

## month hash used by epoch conversion routines
our %months = ('Jan', 0, 'Feb', 1, 'Mar', 2, 'Apr', 3, 'May', 4,  'Jun', 5, 
	      'Jul', 6, 'Aug', 7, 'Sep', 8, 'Oct', 9, 'Nov', 10, 'Dec', 11);

###### DEFINITION OF AVAILABLE COMMANDS FOR TASKS ######

our $date_arg_regexp1 = '\d+|execution_date';
our $date_arg_regexp2 = '(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?'; 
our $date_arg_regexp3 = '(\d+|execution_date)(\+|\-)(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
our $delay_regexp = '(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
our $var_regexp ='@\w+'; 
our $subarg_regexp = '(\w+)(|\((.*)\))'; # for argument with sub argument (ie arg(sub_arg))
                 
# regular commands
our %commands = ('next'                  => ['date', '\w*'],
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
		'sync_include'          => [],
		'purge_user_table'      => [],
		'purge_logs_table'      => [],
		'purge_session_table'   => [],
		'purge_tables'   => [],
		'purge_one_time_ticket_table'   => [],
		'purge_orphan_bounces'  => [],
		'eval_bouncers'         => [],
		'process_bouncers'      => []
		);

# commands which use a variable. If you add such a command, the first parameter must be the variable
our %var_commands = ('delete_subs'      => ['var'],
		                          # variable 
		    'send_msg'         => ['var',  '\w+' ],
		                          #variable template
		    'rm_file'          => ['var'],
		                          # variable
		    );

foreach (keys %var_commands) {
    $commands{$_} = $var_commands{$_};
}                                     
 
# commands which are used for assignments
our %asgn_commands = ('select_subs'      => ['subarg'],
		                            # condition
		     'delete_subs'      => ['var'],
		                            # variable
		     );

foreach (keys %asgn_commands) {
    $commands{$_} = $asgn_commands{$_};
}                                    
     
sub set_spool {
    $taskspool = new Sympaspool('task');
}

## Creates a new Task object
sub new {
    my($pkg,$task_in_spool) = @_;
    my $task;
    &Log::do_log('debug2', 'Task::new  messagekey = %s',$task_in_spool->{'messagekey'});
    
    $task->{'messagekey'} = $task_in_spool->{'messagekey'};    
    $task->{'taskasstring'} = $task_in_spool->{'messageasstring'};    
    $task->{'date'} = $task_in_spool->{'task_date'};    
    $task->{'label'} = $task_in_spool->{'task_label'};    
    $task->{'model'} = $task_in_spool->{'task_model'};    
    $task->{'object'} = $task_in_spool->{'task_object'};    
    $task->{'domain'} = $task_in_spool->{'robot'};    
	
    if ($task_in_spool->{'list'}) { # list task
	$task->{'list_object'} = new List ($task_in_spool->{'list'},$task_in_spool->{'robot'});
	$task->{'domain'} = $task->{'list_object'}{'domain'};
	unless (defined $task->{'list_object'}) {
	    &Log::do_log('err','Unable to create new task object for list %s@%s. This list does not exist',$task_in_spool->{'list'},$task_in_spool->{'robot'});
	}
    }
    $task->{'id'} = $task->{'list_object'}{'name'};
    $task->{'id'} .= '@'.$task->{'domain'} if (defined $task->{'domain'});

    ## Bless Task object
    bless $task, $pkg;

    return $task;
}


##remove a task using message key
sub remove {
    my $self = shift;
    &Log::do_log('debug',"Removing task '%s'",$self->{'messagekey'});
    unless ($taskspool->remove_message({'messagekey'=>$self->{'messagekey'}})){
	&Log::do_log('err', 'Unable to remove task (messagekey = %s)', $self->{'messagekey'});
	return undef;
    }
}


## Build all Task objects
sub list_tasks {

    &Log::do_log('debug',"Listing all tasks");
    my $spool_task = &Conf::get_robot_conf('*','queuetask');
    ## Reset the list of tasks
    undef @task_list;
    undef %task_by_list;
    undef %task_by_model;

    # fetch all task
    my $taskspool = new Sympaspool ('task');
    my @tasks = $taskspool->get_content({'selector'=>{}});

    ## Create Task objects
    foreach my $t (@tasks) {
	my $task = new Task ($t);	
	## Maintain list of tasks
	push @task_list, $task;
	
	my $list_id = $task->{'id'};
	my $model = $task->{'model'};

	$task_by_model{$model}{$list_id} = $task;
	$task_by_list{$list_id}{$model} = $task;
    }    
    return 1;
}

## Return a list tasks for the given list
sub get_tasks_by_list {
    my $list_id = shift;
    &Log::do_log('debug',"Getting tasks for list '%s'",$list_id);
    return () unless (defined $task_by_list{$list_id});
    return values %{$task_by_list{$list_id}};
}

sub get_used_models {
    ## Optional list parameter
    my $list_id = shift;
    &Log::do_log('debug',"Getting used models for list '%s'",$list_id);

    if (defined $list_id) {
	if (defined $task_by_list{$list_id}) {
	    &Log::do_log('debug2',"Found used models for list '%s'",$list_id);
	    return keys %{$task_by_list{$list_id}}
	}else {
	    &Log::do_log('debug2',"Did not find any used models for list '%s'",$list_id);
	    return ();
	}
	
    }else {
	return keys %task_by_model;
    }
}

sub get_task_list {
    &Log::do_log('debug',"Getting tasks list");
    return @task_list;
}

## sort task name by their epoch date
sub epoch_sort {

    $a =~ /(\d+)\..+/;
    my $date1 = $1;
    $b =~ /(\d+)\..+/;
    my $date2 = $1;
    
    $date1 <=> $date2;
}

####### SUBROUTINES #######

sub create_required_tasks {
    my $current_date = shift;
    &Log::do_log('debug','Creating required tasks from models');
    my %default_data = ('creation_date' => $current_date, # hash of datas necessary to the creation of tasks
			'execution_date' => 'execution_date');
    create_required_global_tasks({'data' => \%default_data,'current_date' => $current_date});
    create_required_lists_tasks({'data' => \%default_data,'current_date' => $current_date});
}

sub create_required_global_tasks {
    my $param = shift;
    my $data = $param->{'data'};
    &Log::do_log('debug','Creating required tasks from global models');
    my %used_models; # models for which a task exists
    foreach my $model (&Task::get_used_models) {
	$used_models{$model} = 1;
    }
    foreach my $key (keys %global_models) {	
	&Log::do_log('debug2',"global_model : $key");
	unless ($used_models{$global_models{$key}}) {
	    if ($Conf::Conf{$key}) { 
		create ($param->{'current_date'}, '', $global_models{$key}, $Conf::Conf{$key}, $data);
		$used_models{$1} = 1;
	    }
	}
    }
}

sub create_required_lists_tasks {
    my $param = shift;
    &Log::do_log('debug','Creating required tasks from list models');
    foreach my $robot (keys %{$Conf::Conf{'robots'}}) {
	&Log::do_log('debug3',"creating list task : current bot  is $robot");
	my $all_lists = &List::get_lists($robot);
	foreach my $list ( @$all_lists ) {
	    &Log::do_log('debug3',"creating list task : current list  is $list->{'name'}");
	    my %data = %{$param->{'data'}};
	    $data{'list'} = {'name' => $list->{'name'},
			     'robot' => $list->{'domain'}};
	    
	    my %used_list_models; # stores which models already have a task 
	    foreach (@list_models) { 
		$used_list_models{$_} = undef;
	    }	    
	    foreach my $model (&Task::get_used_models($list->get_list_id())) {		
		$used_list_models{$model} = 1; 
	    }
	    &Log::do_log('debug3',"creating list task using models");my $tt= 0;

	    foreach my $model (@list_models) {
		unless ($used_list_models{$model}) {
		    my $model_task_parameter = "$model".'_task';
		    
		    if ( $model eq 'sync_include') {
			next unless ($list->has_include_data_sources() &&
				     ($list->{'admin'}{'status'} eq 'open'));

			create ($param->{'current_date'}, 'INIT', $model, 'ttl', \%data);
			&Log::do_log('debug3',"sync_include task ceration done");$tt++;
			
		    }elsif (defined $list->{'admin'}{$model_task_parameter} && 
			    defined $list->{'admin'}{$model_task_parameter}{'name'} &&
			    ($list->{'admin'}{'status'} eq 'open')) {
			
			create ($param->{'current_date'}, '', $model, $list->{'admin'}{$model_task_parameter}{'name'}, \%data);
			$tt++;
		    }
		}
	    }
	}
    }
}

## task creations
sub create {
        
    my $date          = shift;
    my $label         = shift;
    my $model         = shift;
    my $model_choice  = shift;
    my $Rdata         = shift;

    &Log::do_log ('debug', "create task date: $date label: $label model: $model model_choice: $model_choice Rdata :$Rdata");

    my $list_name;
    my $robot;
    my $object;
    if (defined $Rdata->{'list'}) { 
	$list_name = $Rdata->{'list'}{'name'};
	$robot = $Rdata->{'list'}{'robot'};
	# $task_file  = "$spool_task/$date.$label.$model.$list_name\@$robot";
	$object = 'list';
    }
    else {
	$object = '_global';
	# $task_file  = $spool_task.'/'.$date.'.'.$label.'.'.$model.'.'.$object;
    }

    ## model recovery
    my $model_file;
    my $model_name = $model.'.'.$model_choice.'.'.'task';
 
     # for global model
    if ($object eq '_global') {
	unless ($model_file = &tools::get_filename('etc',{},"global_task_models/$model_name", $Conf::Conf{'host'})) {
	    &Log::do_log ('err', "error : unable to find $model_name, creation aborted");
	    return undef;
	}
    }

    # for a list
    if ($object  eq 'list') {
	my $list = new List($list_name, $robot);

	$Rdata->{'list'}{'ttl'} = $list->{'admin'}{'ttl'};

	unless ($model_file = &tools::get_filename('etc', {},"list_task_models/$model_name", $list->{'domain'}, $list)) {
	    &Log::do_log ('err', "error : unable to find $model_name, for list $list_name creation aborted");
	    return undef;
	}
    }
   
    &Log::do_log ('notice', "create task with with tt2 template $model_file");
    
    ## creation
    my $task_as_string = '';
    my $tt2 = Template->new({'START_TAG' => quotemeta('['),'END_TAG' => quotemeta(']'), 'ABSOLUTE' => 1});

    unless (defined $tt2 && $tt2->process($model_file, $Rdata, \$task_as_string)) {
	&Log::do_log('err', "Failed to parse task template '%s' : %s", $model_file, $tt2->error());
    }
    foreach my $line (split '\n',$task_as_string) {
	&Log::do_log('trace', 'Resulting task_as_string: %s', $line);
    }
    if  (!check ($task_as_string)) {
	&Log::do_log ('err', "error : syntax error in $task_as_string, you should check $model_file");
	&Log::do_log ('notice', "Ignoring creation task request") ;
	return undef;
    }
    # task is accetable, store it in spool
    my $taskspool = new Sympaspool('task');
    my %meta;
    $meta{'task_date'}=$date;
    $meta{'task_label'}=$label;
    $meta{'task_model'}=$model;
    $meta{'robot'}= $robot if $robot;
    if ($list_name) {
	$meta{'list'}=$list_name ;
	$meta{'task_object'}=$list_name.'@'.$robot ;
    }else{
	$meta{'task_object'}= '_global' ;
    }

    &Log::do_log ('debug3', "task creation done  date: $date label: $label model: $model  model_choice: $model_choice, Rdata :$Rdata");
    $taskspool->store($task_as_string,\%meta);
    return 1;
}

### SYNTAX CHECKING SUBROUTINES ###

## check the syntax of a task
sub check {

    my $task_as_string = shift; # the task to check

    &Log::do_log ('debug2', "check($task_as_string)" );
    my %result; # stores the result of the chk_line subroutine
    my $lnb = 0; # line number
    my %used_labels; # list of labels used as parameter in commands
    my %labels; # list of declared labels
    my %used_vars; # list of vars used as parameter in commands
    my %vars; # list of declared vars

    my @task_by_lines = split('\n',$task_as_string);


    foreach my $line (@task_by_lines) {


	chomp $line;
	$lnb++;

	next if ( $line =~ /^\s*\#/ ); 
	unless (chk_line ($line, \%result)) {
	    &Log::do_log ('err', "error at line $lnb : $line");
	    &Log::do_log ('err', "$result{'error'}");
	    return undef;
	}
	
	if ( $result{'nature'} eq 'assignment' ) {
	    if (chk_cmd ($result{'command'}, $lnb, $result{'Rarguments'}, \%used_labels, \%used_vars)) {
		$vars{$result{'var'}} = 1;
	    } else {
		return undef;}
	}
	
	if ( $result{'nature'} eq 'command' ) {
	    return undef unless (chk_cmd ($result{'command'}, $lnb, $result{'Rarguments'}, \%used_labels, \%used_vars));
	} 
			 
	$labels{$result{'label'}} = 1 if ( $result{'nature'} eq 'label' );
	
    }

    # are all labels used ?
    foreach my $label (keys %labels) {
	&Log::do_log ('debug3', "warning : label $label exists but is not used") unless ($used_labels{$label});
    }

    # do all used labels exist ?
    foreach my $label (keys %used_labels) {
	unless ($labels{$label}) {
	    &Log::do_log ('err', "error : label $label is used but does not exist");
	    return undef;
	}
    }
    
    # are all variables used ?
    foreach my $var (keys %vars) {
	&Log::do_log ('notice', "warning : var $var exists but is not used") unless ($used_vars{$var});
    }

    # do all used variables exist ?
    foreach my $var (keys %used_vars) {
	unless ($vars{$var}) {
	    &Log::do_log ('err', "error : var $var is used but does not exist");
	    return undef;
	}
    }

    return 1;
}

## check a task line
sub chk_line {

    my $line = $_[0];
    my $Rhash = $_[1]; # will contain nature of line (label, command, error...)

    ## just in case...
    chomp $line;

    &Log::do_log('debug2', 'chk_line(%s, %s)', $line, $Rhash->{'nature'});
        
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

	unless ($commands{$command}) { 
	    $Rhash->{'nature'} = 'error';
	    $Rhash->{'error'} = "unknown command $command";
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
	unless ( $asgn_commands{$hash2{'command'}} ) { 
	    $Rhash->{'nature'} = 'error';
	    $Rhash->{'error'} = "non valid assignment $2";
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

    &Log::do_log('debug2', 'chk_cmd(%s, %d, %s)', $cmd, $lnb, join(',',@{$Rargs}));
    
    if (defined $commands{$cmd}) {
	
	my @expected_args = @{$commands{$cmd}};
	my @args = @{$Rargs};
	
	unless ($#expected_args == $#args) {
	    &Log::do_log ('err', "error at line $lnb : wrong number of arguments for $cmd");
	    &Log::do_log ('err', "args = @args ; expected_args = @expected_args");
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
		&Log::do_log ('err', "error at line $lnb : argument $_ is not valid");
		return undef;
	    }
	    
	    $Rused_labels->{$args[1]} = 1 if ($cmd eq 'next' && ($args[1]));   
	    $Rused_vars->{$args[0]} = 1 if ($var_commands{$cmd});
	}
    }
    return 1;
}

    
### TASK EXECUTION SUBROUTINES ###

sub execute {

    my $self = shift;
    my $taskasstring = $self->{'taskasstring'}; # task to execute

    my %result; # stores the result of the chk_line subroutine
    my %vars; # list of task vars
    my $lnb = 0; # line number

    &Log::do_log('debug', 'Running task id = %s, line %d with vars %s)', $self->{'messagekey'}, $lnb, join('/',  %vars));

    my $label = $self->{'label'};
    return undef if ($label eq 'ERROR');

    &Log::do_log ('debug2', "* execution of the task id = %s", $self->{'messagekey'});

    my @tasklines = split('\n',$taskasstring);

    my $labelfound = 0;
    my $status;
    $labelfound = 1 if ($label eq '') ;
    
    foreach my $line (@tasklines){
	chomp $line;
	$lnb++;
	## Ignore all lines until a label is found.
	unless ($labelfound ) {
	    chk_line ($line, \%result);
	    if ($result{'label'} eq $label) { 
		$labelfound = 1;
	    }else{
		next;
	    }
	}
	## Now that we have found a label, the line must contain something consistent.
	unless ( chk_line ($line, \%result) ) {
	    &Log::do_log ('err', "error : $result{'error'}");
	    return undef;
	}
	
	# processing of the assignments: Looking for values that will be used in subsequent command.
	if ($result{'nature'} eq 'assignment') {
	    $status = $vars{$result{'var'}} = &cmd_process ($result{'command'}, $result{'Rarguments'}, $self, \%vars, $lnb);
	    last unless defined($status);
	}
	
	# processing of the commands
	if ($result{'nature'} eq 'command') {
	    $status = &cmd_process ($result{'command'}, $result{'Rarguments'}, $self, \%vars, $lnb);
	    last unless (defined($status) && $status >= 0);
	}
    } 

    unless (defined $status) {
	&Log::do_log('err', 'Error while processing task %s - %s (%s)  (messagekey=%s), removing it', $self->{'model'}, $self->{'label'},$self->{'id'}, $self->{'messagekey'});
	$self->remove;
	return undef;
    }
    unless ($status >= 0) {
	&Log::do_log('notice', 'The task %s - %s (%s) is now useless. Removing it (messagekey=%s)', $self->{'model'}, $self->{'label'},$self->{'id'}, $self->{'messagekey'});
	$self->remove;
    }

    return 1;
}


sub cmd_process {

    my $command = $_[0]; # command name
    my $Rarguments = $_[1]; # command arguments
    my $task = $_[2]; # task
    my $Rvars = $_[3]; # variable list of the task
    my $lnb = $_[4]; # line number

    my $taskasstring = $task->{'taskasstring'};

    &Log::do_log('debug', 'cmd_process(%s, %d)', $command, $lnb);

     # building of %context
    my %context = ('line_number' => $lnb);

    &Log::do_log('debug2','Current task : %s', join(':',%$task));

     # regular commands
    return stop ($task, \%context) if ($command eq 'stop');
    return next_cmd ($task, $Rarguments, \%context) if ($command eq 'next');
    return create_cmd ($task, $Rarguments, \%context) if ($command eq 'create');
    return exec_cmd ($task, $Rarguments) if ($command eq 'exec');
    return update_crl ($task, $Rarguments, \%context) if ($command eq 'update_crl');
    return expire_bounce ($task, $Rarguments, \%context) if ($command eq 'expire_bounce');
    return purge_user_table ($task, \%context) if ($command eq 'purge_user_table');
    return purge_logs_table ($task, \%context) if ($command eq 'purge_logs_table');
    return purge_session_table ($task, \%context) if ($command eq 'purge_session_table');
    return purge_tables ($task, \%context) if ($command eq 'purge_tables');
    return purge_one_time_ticket_table ($task, \%context) if ($command eq 'purge_one_time_ticket_table');
    return sync_include($task, \%context) if ($command eq 'sync_include');
    return purge_orphan_bounces ($task, \%context) if ($command eq 'purge_orphan_bounces');
    return eval_bouncers ($task, \%context) if ($command eq 'eval_bouncers');
    return process_bouncers ($task, \%context) if ($command eq 'process_bouncers');

     # commands which use a variable
    return send_msg ($task, $Rarguments, $Rvars, \%context) if ($command eq 'send_msg');       
    return rm_file ($task, $Rarguments, $Rvars, \%context) if ($command eq 'rm_file');

     # commands which return a variable
    return select_subs ($task, $Rarguments, \%context) if ($command eq 'select_subs');
    return chk_cert_expiration ($task, $Rarguments, \%context) if ($command eq 'chk_cert_expiration');

     # commands which return and use a variable
    return delete_subs_cmd ($task, $Rarguments, $Rvars, \%context) if ($command eq 'delete_subs');  
}


### command subroutines ###
 
 # remove files whose name is given in the key 'file' of the hash
sub rm_file {
    
    my ($task, $Rarguments,$Rvars, $context) = @_;
    
    my @tab = @{$Rarguments};
    my $var = $tab[0];

    foreach my $key (keys %{$Rvars->{$var}}) {
	my $file = $Rvars->{$var}{$key}{'file'};
	next unless ($file);
	unless (unlink ($file)) {
	    error ($task->{'filepath'}, "error in rm_file command : unable to remove $file");
	    return undef;
	}
    }

    return 1;
}

sub stop {
    
    my ($task, $context) = @_;

    &Log::do_log ('notice', "$context->{'line_number'} : stop $task->{'mesageid'}");
    
    unless ($task->remove) { 
	error ($task->{'mesagekey'}, "error in stop command : unable to delete task $task->{'messagekey'}");
	return 0;
    }
}

sub send_msg {
        
    my ($task, $Rarguments, $Rvars, $context) = @_;
    
    my @tab = @{$Rarguments};
    my $template = $tab[1];
    my $var = $tab[0];
    
    &Log::do_log ('notice', "line $context->{'line_number'} : send_msg (@{$Rarguments})");


    if ($task->{'object'} eq '_global') {

	foreach my $email (keys %{$Rvars->{$var}}) {
	    unless (&List::send_global_file ($template, $email, ,'',$Rvars->{$var}{$email}) ) {
		&Log::do_log ('notice', "Unable to send template $template to $email");
	    }else{
		&Log::do_log ('notice', "--> message sent to $email");
	    }
	}
    } else {
	my $list = $task->{'list_object'};
	foreach my $email (keys %{$Rvars->{$var}}) {
	    unless ($list->send_file ($template, $email, $list->{'domain'}, $Rvars->{$var}{$email}))  {
		&Log::do_log ('notice', "Unable to send template $template to $email");
	    }else{
		&Log::do_log ('notice', "--> message sent to $email");
	    }
	}
    }
    return 1;
}

sub next_cmd {
        
    my ($task, $Rarguments, $context) = @_;
    
    my @tab = @{$Rarguments};
    my $date = &tools::epoch_conv ($tab[0], $task->{'date'}); # conversion of the date argument into epoch format
    my $label = $tab[1];

    &Log::do_log ('debug2', "line $context->{'line_number'} of $task->{'model'} : next ($date, $label)");

    my $listname = $task->{'object'};
    my $model = $task->{'model'};

    ## Determine type
    my ($type, $model_choice);
    my %data = ('creation_date'  => $task->{'date'},
		'execution_date' => 'execution_date');
    if ($listname eq '_global') {
	$type = '_global';
	foreach my $key (keys %global_models) {
	    if ($global_models{$key} eq $model) {
		$model_choice = $Conf::Conf{$key};
		last;
	    }
	}
    }else {
	$type = 'list';
	my $list = $task->{'list_object'};
	$data{'list'}{'name'} = $list->{'name'};
	$data{'list'}{'robot'} = $list->{'domain'};
	
	if ( $model eq 'sync_include') {
	    unless ($list->{'admin'}{'user_data_source'} eq 'include2') {
		error ($task->{'messagekey'}, "List $list->{'name'} no more require sync_include task");
		return undef;
	    }

	    $data{'list'}{'ttl'} = $list->{'admin'}{'ttl'};
	    $model_choice = 'ttl';
	}else {
	    unless (defined $list->{'admin'}{"$model\_task"}) {
		error ($task->{'messagekey'}, "List $list->{'name'} no more require $model task");
		return undef;
	    }

	    $model_choice = $list->{'admin'}{"$model\_task"}{'name'};
	}
    }

    unless (create ($date, $tab[1], $model, $model_choice, \%data)) {
	error ($task->{'messagekey'}, "error in create command : creation subroutine failure");
	return undef;
    }

    my $human_date = &tools::adate ($date);

    unless ($task->remove) {
	error ($task->{'messagekey'}, "error in next command : unable to remove task");
	return undef;
    }

    &Log::do_log ('debug2', "--> new task $model ($human_date)");
    
    return 0;
}

sub select_subs {

    my ($task, $Rarguments, $context) = @_;

    my @tab = @{$Rarguments};
    my $condition = $tab[0];
 
    &Log::do_log ('debug2', "line $context->{'line_number'} : select_subs ($condition)");
    $condition =~ /(\w+)\(([^\)]*)\)/;
    if ($2) { # conversion of the date argument into epoch format
	my $date = &tools::epoch_conv ($2, $task->{'date'});
        $condition = "$1($date)";
    }  
 
    my @users; # the subscribers of the list      
    my %selection; # hash of subscribers who match the condition
    my $list = $task->{'list_object'};
    
    for ( my $user = $list->get_first_list_member(); $user; $user = $list->get_next_list_member() ) { 
	push (@users, $user);
    }
    
    # parameter of subroutine Scenario::verify
    my $verify_context = {'sender' => 'nobody',
			  'email' => 'nobody',
			  'remote_host' => 'unknown_host',
			  'listname' => $task->{'object'}};
    
    my $new_condition = $condition; # necessary to the older & newer condition rewriting
    # loop on the subscribers of $list_name
    foreach my $user (@users) {

	# AF : voir 'update' &Log::do_log ('notice', "date $user->{'date'} & update $user->{'update'}");
	# condition rewriting for older and newer
	$new_condition = "$1($user->{'update_date'}, $2)" if ($condition =~ /(older|newer)\((\d+)\)/ );
	
	if (&Scenario::verify ($verify_context, $new_condition) == 1) {
	    $selection{$user->{'email'}} = undef;
	    &Log::do_log ('notice', "--> user $user->{'email'} has been selected");
	}
    }
    
    return \%selection;
}

sub delete_subs_cmd {

    my ($task, $Rarguments, $Rvars,  $context) = @_;

    my @tab = @{$Rarguments};
    my $var = $tab[0];

    &Log::do_log ('notice', "line $context->{'line_number'} : delete_subs ($var)");

    
    my $list = $task->{'list_object'};
    my %selection; # hash of subscriber emails who are successfully deleted

    foreach my $email (keys %{$Rvars->{$var}}) {

	&Log::do_log ('notice', "email : $email");
	my $result = $list->check_list_authz('del', 'smime',
					     {'sender'   => $Conf::Conf{'listmaster'},
					      'email'    => $email,
					  });
	my $action;
	$action = $result->{'action'} if (ref($result) eq 'HASH');
	if ($action =~ /reject/i) {
	    error ($task->{'filepath'}, "error in delete_subs command : deletion of $email not allowed");
	} else {
	    my $u = $list->delete_list_member ($email);
	    &Log::do_log ('notice', "--> $email deleted");
	    $selection{$email} = {};
	}
    }

    return \%selection;
}

sub create_cmd {

    my ($task, $Rarguments, $context) = @_;

    my @tab = @{$Rarguments};
    my $arg = $tab[0];
    my $model = $tab[1];
    my $model_choice = $tab[2];

    &Log::do_log ('notice', "line $context->{'line_number'} : create ($arg, $model, $model_choice)");

    # recovery of the object type and object
    my $type;
    my $object;
    if ($arg =~ /$subarg_regexp/) {
	$type = $1;
	$object = $3;
    } else {
	error ($task->{'messagekey'}, "error in create command : don't know how to create $arg");
	return undef;
    }

    # building of the data hash necessary to the create subroutine
    my %data = ('creation_date'  => $task->{'date'},
		'execution_date' => 'execution_date');

    if ($type eq 'list') {
	my $list = new List ($object);
	$data{'list'}{'name'} = $list->{'name'};
    }
    $type = '_global';
    unless (create ($task->{'date'}, '', $model, $model_choice, \%data)) {
	error ($task->{'messagekey'}, "error in create command : creation subroutine failure");
	return undef;
    }
    
    return 1;
}

sub exec_cmd {

    my ($task, $Rarguments, $context) = @_;

    my @tab = @{$Rarguments};
    my $file = $tab[0];

    &Log::do_log ('notice', "line $context->{'line_number'} : exec ($file)");
    system ($file);
    
    return 1;
}

sub purge_logs_table {
    # If a log is older then $list->get_latest_distribution_date()-$delai expire the log
    my ($task, $Rarguments, $context) = @_;
    my $date;
    my $execution_date = $task->{'date'};
    my @slots = ();
    
    &Log::do_log('debug2','purge_logs_table()');
    unless(&Log::db_log_del()) {
	&Log::do_log('err','purge_logs_table(): Failed to delete logs');
	return undef;
    }

    #-----------Data aggregation, to make statistics-----------------
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($execution_date);
    $min = 0;
    $sec = 0;
    my $date_end = timelocal($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

	my $sth;
	unless($sth = &SDM::do_query("SELECT date_stat FROM stat_table WHERE read_stat = 0 ORDER BY date_stat ASC LIMIT 1")) {
		&Log::do_log('err', 'Unable to retrieve oldest non processed stat');
		return undef;
	}
	my @res = $sth->fetchrow_array;
	return unless($#res >= 0);
	my $date_deb = $res[0] - ($res[0] % 3600);

    #hour to hour
    for  (my $i=$date_deb; $i <= $date_end; $i=$i+3600){
	push(@slots, $i);
	
    }

    for (my $j=1; $j <= scalar(@slots); $j++){
	 
	&Log::aggregate_data($slots[$j-1], $slots[$j]);
    }
    #-------------------------------------------------------------------

    &Log::do_log('notice','purge_logs_table(): logs purged');
    return 1;
}

## remove sessions from session_table if older than $Conf::Conf{'session_table_ttl'}
sub purge_session_table {    

    &Log::do_log('info','task_manager::purge_session_table()');
    require SympaSession;

    my $removed = &SympaSession::purge_old_sessions('*');
    unless(defined $removed) {
	&Log::do_log('err','&SympaSession::purge_old_sessions(): Failed to remove old sessions');
	return undef;
    }
    &Log::do_log('notice','purge_session_table(): %s row removed in session_table',$removed);
    return 1;
}

## remove messages from bulkspool table when no more packet have any pointer to this message
sub purge_tables {    

    &Log::do_log('info','task_manager::purge_tables()');
    require SympaSession;
    my $removed = &Bulk::purge_bulkspool();
    unless(defined $removed) {
	&Log::do_log('err','Failed to purge bulkspool');
    }
    &Log::do_log('notice','%s rows removed in bulkspool_table',$removed);    
    #
    my $removed = 0;
    foreach my $robot (keys %{$Conf::Conf{'robots'}}) {
	my $all_lists = &List::get_lists($robot);
	foreach my $list ( @$all_lists ) {
	    $removed += &tracking::remove_message_by_period($list->{'admin'}{'tracking'}{'retention_period'},$list->{'name'},$robot);   
	}
    }
    &Log::do_log('notice', "%s rows removed in tracking table",$removed);

    return 1;
}

## remove one time ticket table if older than $Conf::Conf{'one_time_ticket_table_ttl'}
sub purge_one_time_ticket_table {    

    &Log::do_log('info','task_manager::purge_one_time_ticket_table()');
    my $removed = &SympaSession::purge_old_tickets('*');
    unless(defined $removed) {
	&Log::do_log('err','&SympaSession::purge_old_tickets(): Failed to remove old tickets');
	return undef;
    }
    &Log::do_log('notice','purge_one_time_ticket_table(): %s row removed in one_time_ticket_table',$removed);
    return 1;
}

sub purge_user_table {
    my ($task, $Rarguments, $context) = @_;
    &Log::do_log('debug2','purge_user_table()');

    ## Load user_table entries
    my @users = &List::get_all_global_user();

    ## Load known subscribers/owners/editors
    my %known_people;

    ## Listmasters
    foreach my $l (@{$Conf::Conf{'listmasters'}}) {
	$known_people{$l} = 1;
    }

    foreach my $r (keys %{$Conf::Conf{'robots'}}) {

	my $all_lists = &List::get_lists($r);
	foreach my $list (@$all_lists){

	    ## Owners
	    my $owners = $list->get_owners();
	    if (defined $owners) {
		foreach my $o (@{$owners}) {
		    $known_people{$o->{'email'}} = 1;
		}
	    }

	    ## Editors
	    my $editors = $list->get_editors();
	    if (defined $editors) {		
		foreach my $e (@{$editors}) {
		    $known_people{$e->{'email'}} = 1;
		}
	    }
	    
	    ## Subscribers
	    for (my $user = $list->get_first_list_member(); $user; $user = $list->get_next_list_member()) {
		$known_people{$user->{'email'}} = 1;
	    }
	}
    }    

    ## Look for unused entries
    my @purged_users;
    foreach (@users) {
	unless ($known_people{$_}) {
	    &Log::do_log('debug2','User to purge: %s', $_);
	    push @purged_users, $_;
	}
    }
    
    unless ($#purged_users < 0) {
	unless (&List::delete_global_user(@purged_users)) {
	    &Log::do_log('err', 'purge_user_table error: Failed to delete users');
	    return undef;
	}
    }
    
    return $#purged_users + 1;
}

## Subroutine which remove bounced message of no-more known users
sub purge_orphan_bounces {
    my($task, $context) = @_;
    
    &Log::do_log('info','purge_orphan_bounces()');
    
    ## Hash {'listname' => 'bounced address' => 1}
    my %bounced_users;
    my $all_lists;
    
    unless ($all_lists = &List::get_lists('*')) {
	&Log::do_log('notice','No list available');
	return 1;
    }
    
    foreach my $list (@$all_lists) {
	
	my $listname = $list->{'name'};
	
	## first time: loading DB entries into %bounced_users
	for (my $user_ref = $list->get_first_bouncing_list_member(); $user_ref; $user_ref = $list->get_next_bouncing_list_member()){
	    my $user_id = $user_ref->{'email'};
	    $bounced_users{$listname}{$user_id} = 1;
	}
	
	my $bounce_dir = $list->get_bounce_dir();
	
	unless (-d $bounce_dir) {
	    &Log::do_log('notice', 'No bouncing subscribers in list %s', $listname);
	    next;
	}
	
	## then reading Bounce directory & compare with %bounced_users
	unless (opendir(BOUNCE,$bounce_dir)) {
	    &Log::do_log('err','Error while opening bounce directory %s',$bounce_dir);
	    return undef;
	}
	
	## Finally removing orphan files
	foreach my $bounce (readdir(BOUNCE)) {
	    if ($bounce =~ /\@/){
		unless (defined($bounced_users{$listname}{$bounce})) {
		    &Log::do_log('info','removing orphan Bounce for user %s in list %s',$bounce,$listname);
		    unless (unlink($bounce_dir.'/'.$bounce)) {
			&Log::do_log('err','Error while removing file %s/%s', $bounce_dir, $bounce);
		    }
		}
	    }	    
	}
	
	closedir BOUNCE;
    }
    return 1;
}


 sub expire_bounce {
     # If a bounce is older then $list->get_latest_distribution_date()-$delai expire the bounce
     # Is this variable my be set in to task modele ?
     my ($task, $Rarguments, $context) = @_;

     my $execution_date = $task->{'date'};
     my @tab = @{$Rarguments};
     my $delay = $tab[0];

     &Log::do_log('debug2','expire_bounce(%d)',$delay);
     my $all_lists = &List::get_lists('*');
     foreach my $list (@$all_lists ) {

	 my $listname = $list->{'name'};

	 # the reference date is the date until which we expire bounces in second
	 # the latest_distribution_date is the date of last distribution #days from 01 01 1970

	 unless ($list->get_latest_distribution_date()) {
	     &Log::do_log('debug2','bounce expiration : skipping list %s because could not get latest distribution date',$listname);
	     next;
	 }
	 my $refdate = (($list->get_latest_distribution_date() - $delay) * 3600 * 24);

	 for (my $u = $list->get_first_bouncing_list_member(); $u ; $u = $list->get_next_bouncing_list_member()) {
	     $u->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
	     $u->{'last_bounce'} = $2;
	     if ($u->{'last_bounce'} < $refdate) {
		 my $email = $u->{'email'};

		 unless ( $list->is_list_member($email) ) {
		     &Log::do_log('info','expire_bounce: %s not subscribed', $email);
		     next;
		 }

		 unless( $list->update_list_member($email, {'bounce' => 'NULL'},{'bounce_address' => 'NULL'})) {
		     &Log::do_log('info','expire_bounce: failed update database for %s', $email);
		     next;
		 }
		 my $escaped_email = &tools::escape_chars($email);

		 my $bounce_dir = $list->get_bounce_dir();

		 unless (unlink $bounce_dir.'/'.$escaped_email) {
		     &Log::do_log('info','expire_bounce: failed deleting %s', $bounce_dir.'/'.$escaped_email);
		     next;
		 }
		 &Log::do_log('info','expire bounces for subscriber %s of list %s (last distribution %s, last bounce %s )',
			$email,$listname,
			&POSIX::strftime("%d %b %Y", localtime($list->get_latest_distribution_date() * 3600 * 24)),
			&POSIX::strftime("%d %b %Y", localtime($u->{'last_bounce'})));

	     }
	 }
     }

     return 1;
 }

 sub chk_cert_expiration {

     my ($task, $Rarguments, $context) = @_;

    my $cert_dir = &Conf::get_robot_conf('*','ssl_cert_dir');
     my $execution_date = $task->{'date'};
     my @tab = @{$Rarguments};
     my $template = $tab[0];
     my $limit = &tools::duration_conv ($tab[1], $execution_date);

     &Log::do_log ('notice', "line $context->{'line_number'} : chk_cert_expiration (@{$Rarguments})");

     ## building of certificate list
     unless (opendir(DIR, $cert_dir)) {
	 error ($task->{'filepath'}, "error in chk_cert_expiration command : can't open dir $cert_dir");
	 return undef;
     }
     my @certificates = grep !/^(\.\.?)|(.+expired)$/, readdir DIR;
     closedir (DIR);

     foreach (@certificates) {

	 my $soon_expired_file = $_.'.soon_expired'; # an empty .soon_expired file is created when a user is warned that his certificate is soon expired

	 # recovery of the certificate expiration date 
	 open (ENDDATE, "openssl x509 -enddate -in $cert_dir/$_ -noout |");
	 my $date = <ENDDATE>; # expiration date
	 close (ENDDATE);
	 chomp ($date);

	 unless ($date) {
	     &Log::do_log ('err', "error in chk_cert_expiration command : can't get expiration date for $_ by using the x509 openssl command");
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
		 unlink ($soon_expired_file) || &Log::do_log ('err', "error : can't delete $soon_expired_file");
	     }
	     next;
	 }

	 # expired certificate processing
	 if ($expiration_date < $execution_date) {

	     &Log::do_log ('notice', "--> $_ certificate expired ($date), certificate file deleted");
	     unlink ("$cert_dir/$_") || &Log::do_log ('notice', "error : can't delete certificate file $_");
	     if (-e $soon_expired_file) {
		 unlink ("$cert_dir/$soon_expired_file") || &Log::do_log ('err', "error : can't delete $soon_expired_file");
	     }
	     next;
	 }

	 # soon expired certificate processing
	 if ( ($expiration_date > $execution_date) && 
	      ($expiration_date < $limit) &&
	      !(-e $soon_expired_file) ) {

	     unless (open (FILE, ">$cert_dir/$soon_expired_file")) {
		 &Log::do_log ('err', "error in chk_cert_expiration : can't create $soon_expired_file");
		 next;
	     } else {close (FILE);}

	     my %tpl_context; # datas necessary to the template

	     open (ID, "openssl x509 -subject -in $cert_dir/$_ -noout |");
	     my $id = <ID>; # expiration date
	     close (ID);
	     chomp ($id);

	     unless ($id) {
		 &Log::do_log ('err', "error in chk_cert_expiration command : can't get expiration date for $_ by using the x509 openssl command");
		 next;
	     }

	     $id =~ s/subject= //;
	     &Log::do_log ('notice', "id : $id");
	     $tpl_context{'expiration_date'} = &tools::adate ($expiration_date);
	     $tpl_context{'certificate_id'} = $id;
	     $tpl_context{'auto_submitted'} = 'auto-generated';
	     unless (&List::send_global_file ($template, $_,'', \%tpl_context)) {
		 &Log::do_log ('notice', "Unable to send template $template to $_");
	     }
	     &Log::do_log ('notice', "--> $_ certificate soon expired ($date), user warned");
	 }
     }
     return 1;
 }


 ## attention, j'ai n'ai pas pu comprendre les retours d'erreurs des commandes wget donc pas de verif sur le bon fonctionnement de cette commande
 sub update_crl {

     my ($task, $Rarguments, $context) = @_;

     my @tab = @{$Rarguments};
     my $limit = &tools::epoch_conv ($tab[1], $task->{'date'});
     my $CA_file = "$Conf::Conf{'home'}/$tab[0]"; # file where CA urls are stored ;
     &Log::do_log ('notice', "line $context->{'line_number'} : update_crl (@tab)");

     # building of CA list
     my @CA;
     unless (open (FILE, $CA_file)) {
	 error ($task->{'filepath'}, "error in update_crl command : can't open $CA_file file");
	 return undef;
     }
     while (<FILE>) {
	 chomp;
	 push (@CA, $_);
     }
     close (FILE);

     # updating of crl files
     my $crl_dir = "$Conf::Conf{'crl_dir'}";
     unless (-d $Conf::Conf{'crl_dir'}) {
	 if ( mkdir ($Conf::Conf{'crl_dir'}, 0775)) {
	     &Log::do_log('notice', "creating spool $Conf::Conf{'crl_dir'}");
	 }else{
	     &Log::do_log('err', "Unable to create CRLs directory $Conf::Conf{'crl_dir'}");
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
	     &Log::do_log ('err', "error in update_crl command : can't get expiration date for $file crl file by using the crl openssl command");
	     next;
	 }

	 $date =~ /nextUpdate=(\w+)\s*(\d+)\s(\d\d)\:(\d\d)\:\d\d\s(\d+).+/;
	 my @date = (0, $4, $3 - 1, $2, $months{$1}, $5 - 1900);
	 my $expiration_date = timegm (@date); # epoch expiration date
	 my $rep = &tools::adate ($expiration_date);

	 ## check if the crl is soon expired or expired
	 #my $file_date = $task->{'date'} - (-M $file) * 24 * 60 * 60; # last modification date
	 my $condition = "newer($limit, $expiration_date)";
	 my $verify_context;
	 $verify_context->{'sender'} = 'nobody';

	 if (&Scenario::verify ($verify_context, $condition) == 1) {
	     unlink ($file);
	     &Log::do_log ('notice', "--> updating of the $file crl file");
	     my $cmd = "wget -O \'$file\' \'$url\'";
	     open CMD, "| $cmd";
	     close CMD;
	     next;
	 }
     }
     return 1;
 }

 ## Subroutine for bouncers evaluation: 
 # give a score for each bouncing user
sub eval_bouncers {
    #################       
    my ($task, $context) = @_;
    
    my $all_lists = &List::get_lists('*');
    foreach my $list (@$all_lists) {
	
	my $listname = $list->{'name'};
	my $list_traffic = {};
	
	&Log::do_log('info','eval_bouncers(%s)',$listname);
	
	## Analizing file Msg-count and fill %$list_traffic
	unless (open(COUNT,$list->{'dir'}.'/msg_count')){
	    &Log::do_log('debug','** Could not open msg_count FILE for list %s',$listname);
	    next;
	}    
	while (<COUNT>) {
	    if ( /^(\w+)\s+(\d+)/) {
		my ($a, $b) = ($1, $2);
		$list_traffic->{$a} = $b;	
	    }
	}    	
	close(COUNT);
	
	#for each bouncing user
	for (my $user_ref = $list->get_first_bouncing_list_member(); $user_ref; $user_ref = $list->get_next_bouncing_list_member()){
	    my $score = &get_score($user_ref,$list_traffic) || 0;
	    
	    ## copying score into DataBase
	    unless ($list->update_list_member($user_ref->{'email'},{'score' => $score }) ) {
		&Log::do_log('err','Task eval_bouncers :Error while updating DB for user %s',$user_ref->{'email'});
		next;
	    }
	}
    }
    return 1;
}

sub none {

    1;
}

## Routine for automatic bouncing users management
##
sub process_bouncers {
###################
    my ($task,$context) = @_;
    &Log::do_log('info','Processing automatic actions on bouncing users'); 

###########################################################################
# This sub apply a treatment foreach category of bouncing-users
#
# The relation between possible actions and correponding subroutines 
# is indicated by the following hash (%actions).
# It's possible to add actions by completing this hash and the one in list 
# config (file List.pm, in sections "bouncers_levelX"). Then you must write 
# the code for your action:
# The action subroutines have two parameter : 
# - the name of the current list
# - a reference on users email list: 
# Look at the "remove_bouncers" sub in List.pm for an example
###########################################################################
   
    ## possible actions
    my %actions = ('remove_bouncers' => \&List::remove_bouncers,
		   'notify_bouncers' => \&List::notify_bouncers,
		   'none'            => \&none
		   );

    my $all_lists = &List::get_lists();
    foreach my $list (@$all_lists) {
	my $listname = $list->{'name'};
	
	my @bouncers;
	# @bouncers = ( ['email1', 'email2', 'email3',....,],    There is one line 
	#               ['email1', 'email2', 'email3',....,],    foreach bounce 
	#               ['email1', 'email2', 'email3',....,],)   level.
   
	next unless ($list);

	my $max_level;    
	for (my $level = 1;defined ($list->{'admin'}{'bouncers_level'.$level});$level++) {
	    $max_level = $level;
	}
	
	##  first, bouncing email are sorted in @bouncer 
	for (my $user_ref = $list->get_first_bouncing_list_member(); $user_ref; $user_ref = $list->get_next_bouncing_list_member()) {	   

	    ## Skip included users (cannot be removed)
	    next if ($user_ref->{'is_included'});
 
	    for ( my $level = $max_level;($level >= 1) ;$level--) {

		if ($user_ref->{'bounce_score'} >= $list->{'admin'}{'bouncers_level'.$level}{'rate'}){
		    push(@{$bouncers[$level]}, $user_ref->{'email'});
		    $level = ($level-$max_level);		   
		}
	    }
	}
	
	## then, calling action foreach level
	for ( my $level = $max_level;($level >= 1) ;$level--) {

	    my $action = $list->{'admin'}{'bouncers_level'.$level}{'action'};
	    my $notification = $list->{'admin'}{'bouncers_level'.$level}{'notification'};
	  
	    if (defined $bouncers[$level] && @{$bouncers[$level]}){
		## calling action subroutine with (list,email list) in parameter 
		unless ($actions{$action}->($list,$bouncers[$level])){
		    &Log::do_log('err','error while calling action sub for bouncing users in list %s',$listname);
		    return undef;
		}

		## calling notification subroutine with (list,action, email list) in parameter  
		
		my $param = {'listname' => $listname,
			     'action' => $action,
			     'user_list' => \@{$bouncers[$level]},
			     'total' => $#{$bouncers[$level]} + 1};

	        if ($notification eq 'listmaster'){

		    unless(&List::send_notify_to_listmaster('automatic_bounce_management',$list->{'domain'},$param)){
			&Log::do_log('err','error while notifying listmaster');
		    }
		}elsif ($notification eq 'owner'){
		    unless ($list->send_notify_to_owner('automatic_bounce_management',$param)){
			&Log::do_log('err','error while notifying owner');
		    }
		}
	    }
	}
    }     
    return 1;
}


sub get_score {

    my $user_ref = shift;
    my $list_traffic = shift;

    &Log::do_log('debug','Get_score(%s) ',$user_ref->{'email'});

    my $min_period = $Conf::Conf{'minimum_bouncing_period'};
    my $min_msg_count = $Conf::Conf{'minimum_bouncing_count'};
	
    # Analizing bounce_subscriber_field and keep usefull infos for notation
    $user_ref->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;

    my $BO_period = int($1 / 86400) - $Conf::Conf{'bounce_delay'};
    my $EO_period = int($2 / 86400) - $Conf::Conf{'bounce_delay'};
    my $bounce_count = $3;
    my $bounce_type = $4;

    my $msg_count = 0;
    my $min_day = $EO_period;

    unless ($bounce_count >= $min_msg_count){
	#not enough messages distributed to keep score
	&Log::do_log('debug','Not enough messages for evaluation of user %s',$user_ref->{'email'});
	return undef ;
    }

    unless (($EO_period - $BO_period) >= $min_period){
	#too short bounce period to keep score
	&Log::do_log('debug','Too short period for evaluate %s',$user_ref->{'email'});
	return undef;
    } 

    # calculate number of messages distributed in list while user was bouncing
    foreach my $date (sort {$b <=> $a} keys (%$list_traffic)) {
	if (($date >= $BO_period) && ($date <= $EO_period)) {
	    $min_day = $date;
	    $msg_count += $list_traffic->{$date};
	}
    }

    #Adjust bounce_count when msg_count file is too recent, compared to the bouncing period
    my $tmp_bounce_count = $bounce_count;
    unless ($EO_period == $BO_period) {
	my $ratio  = (($EO_period - $min_day) / ($EO_period - $BO_period));
	$tmp_bounce_count *= $ratio;
    }
    
    ## Regularity rate tells how much user has bounced compared to list traffic
    $msg_count ||= 1; ## Prevents "Illegal division by zero" error
    my $regularity_rate = $tmp_bounce_count / $msg_count;

    ## type rate depends on bounce type (5 = permanent ; 4 =tewmporary)
    my $type_rate = 1;
    $bounce_type =~ /(\d)\.(\d)\.(\d)/;    
    if ($1 == 4) { # if its a temporary Error: score = score/2
	$type_rate = .5;
    }

    my $note = $bounce_count * $regularity_rate * $type_rate;

    ## Note should be an integer
    $note = int($note + 0.5);
	
#    $note = 100 if ($note > 100); # shift between message ditrib & bounces => note > 100     
    
    return  $note;
}



### MISCELLANEOUS SUBROUTINES ### 

## sort task name by their epoch date
sub epoch_sort {

    $a =~ /(\d+)\..+/;
    my $date1 = $1;
    $b =~ /(\d+)\..+/;
    my $date2 = $1;
    
    $date1 <=> $date2;
}

## change the label of a task file
sub change_label {
    my $task_file = $_[0];
    my $new_label = $_[1];
    
    my $new_task_file = $task_file;
    $new_task_file =~ s/(.+\.)(\w*)(\.\w+\.\w+$)/$1$new_label$3/;

    if (rename ($task_file, $new_task_file)) {
	&Log::do_log ('notice', "$task_file renamed in $new_task_file");
    } else {
	&Log::do_log ('err', "error ; can't rename $task_file in $new_task_file");
    }
}

## send a error message to list-master, log it, and change the label task into 'ERROR' 
sub error {
    my $task_id = $_[0];
    my $message = $_[1];

    my @param;
    $param[0] = "An error has occured during the execution of the task $task_id :
                 $message";
    &Log::do_log ('err', "$message");
    change_label ($task_id, 'ERROR') unless ($task_id eq '');
    unless (&List::send_notify_to_listmaster ('error in task', $Conf::Conf{'domain'}, \@param)) {
    	&Log::do_log('notice','error while notifying listmaster about "error_in_task"');
    }
}

sub sync_include {
    my ($task, $context) = @_;

    &Log::do_log('debug2', 'sync_include(%s)', $task->{'id'});

    my $list = $task->{'list_object'};

    $list->sync_include();
    $list->sync_include_admin() if ((defined $list->{'admin'}{'editor_include'} && $#{$list->{'admin'}{'editor_include'}}>-1) || (defined $list->{'admin'}{'owner_include'} && $#{$list->{'admin'}{'owner_include'}}>-1));

    if (! $list->has_include_data_sources() &&
	(!$list->{'last_sync'} || ($list->{'last_sync'} > (stat("$list->{'dir'}/config"))[9]))) {
	&Log::do_log('debug', "List $list->{'name'} no more require sync_include task");
	return -1;	
    }    
}

sub check_list_task_is_valid {
    my $self = shift;
    my $list = $self->{'list_object'};
    &Log::do_log('debug','Checking %s task validity for list %s@%s',$self->{'model'},$list->{'name'},$list->{'domain'});
    ### Check list object validity; recreate it if needed.

    ## Skip closed lists
    unless (defined $list && ($list->{'admin'}{'status'} eq 'open')) {
	&Log::do_log('notice','Removing task %s, label %s (messageid = %s) because list %s is closed', $self->{'model'}, $self->{'label'}, $self->{'messagekey'},$self->{'id'});
	$self->remove;
	return 0;
    }

    ## Skip if parameter is not defined
    if ( $self->{'model'} eq 'sync_include') {
	if ($list->has_include_data_sources()) {
	    return 1;
	}else{
	    &Log::do_log('notice','Removing task %s, label %s (messageid = %s) because list does not use any inclusion', $self->{'model'}, $self->{'label'}, $self->{'messagekey'},$self->{'id'});
	    $self->remove;
	    return 0;
	}
    }else {
	unless (defined $list->{'admin'}{$self->{'model'}} && 
		defined $list->{'admin'}{$self->{'model'}}{'name'}) {
	    &Log::do_log('notice','Removing task %s, label %s (messageid = %s) because it is not defined in list %s configuration', $self->{'model'}, $self->{'label'}, $self->{'messagekey'},$self->{'id'});
	    $self->remove;
	    return 0;
	}		
    }
    return 1;
}
## Packages must return true.
1;
