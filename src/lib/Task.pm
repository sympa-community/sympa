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
use TaskSpool;
use TaskInstruction;
use tools;
use tracking;
use tt2;

#### Task level subs ####
##########################

## Creates a new Task object
sub new {
    my($pkg,$task_in_spool) = @_;
    my $task;
    &Log::do_log('debug2', 'Task::new  messagekey = %s',$task_in_spool->{'messagekey'});

    if ($task_in_spool) {
	$task->{'messagekey'} = $task_in_spool->{'messagekey'};    
	$task->{'taskasstring'} = $task_in_spool->{'messageasstring'};    
	$task->{'date'} = $task_in_spool->{'task_date'};    
	$task->{'label'} = $task_in_spool->{'task_label'};    
	$task->{'model'} = $task_in_spool->{'task_model'};    
	$task->{'flavour'} = $task_in_spool->{'task_flavour'};    
	$task->{'object'} = $task_in_spool->{'task_object'};    
	$task->{'domain'} = $task_in_spool->{'robot'};
	    
	if ($task_in_spool->{'list'}) { # list task
	    $task->{'list_object'} = new List ($task_in_spool->{'list'},$task_in_spool->{'robot'});
	    $task->{'domain'} = $task->{'list_object'}{'domain'};
	    unless (defined $task->{'list_object'}) {
		&Log::do_log('err','Unable to create new task object for list %s@%s. This list does not exist',$task_in_spool->{'list'},$task_in_spool->{'robot'});
		return undef;
	    }
	    $task->{'id'} = $task->{'list_object'}{'name'};
	    $task->{'id'} .= '@'.$task->{'domain'} if (defined $task->{'domain'});
	}
	$task->{'description'} = get_description($task);
    }else {
	$task->{'date'} = time;
    }

    ## Bless Task object
    bless $task, $pkg;

    return $task;
}

## task creation in spool
sub create {
    my $param = shift;
    
    &Log::do_log ('debug', "create task date: %s label: %s model: %s flavour: %s Rdata :%s",$param->{'creation_date'},$param->{'label'},$param->{'model'},$param->{'flavour'},$param->{'data'});
    
    # Creating task object. Simulating data retrieved from the database.
    my $task_in_spool;
    $task_in_spool->{'task_date'}          = $param->{'creation_date'};
    $task_in_spool->{'task_label'}         = $param->{'label'};
    $task_in_spool->{'task_model'}         = $param->{'model'};
    $task_in_spool->{'task_flavour'}  = $param->{'flavour'};
    if (defined $param->{'data'}{'list'}) { 
	$task_in_spool->{'list'} = $param->{'data'}{'list'}{'name'};
	$task_in_spool->{'domain'} = $param->{'data'}{'list'}{'robot'};
	$task_in_spool->{'task_object'} = 'list';
    }
    else {
	$task_in_spool->{'task_object'} = '_global';
    }
    my $self = new Task($task_in_spool);
    unless ($self) {
	&Log::do_log('err','Unable to create task object');
	return undef;
    }
    $self->{'Rdata'} = $param->{'data'};
    
    ## model recovery
    return undef unless ($self->get_template);
    
    ## Task as string generation
    return undef unless ($self->generate_from_template);

    ## In case a label is specified, ensure we won't use anything in the task prior to this label.
    if ($self->{'label'}) {
	return undef unless ($self->crop_after_label($self->{'label'}));
    }
    
    # task is accetable, store it in spool
    return undef unless ($self->store);
    
    return 1;
}

## Sets and returns the path to the file that must be used to generate the task as string.
sub get_template {
    my $self = shift;
    &Log::do_log ('debug2','Computing model file path for task %s',$self->get_description);

    unless ($self->{'model'}) {
	&Log::do_log('err','Missing a model name. Impossible to get a template. Aborting.');
	return undef;
    }
    unless ($self->{'flavour'}) {
	&Log::do_log('err','Missing a flavour name for model %s name. Impossible to get a template. Aborting.',$self->{'model'});
	return undef;
    }
    $self->{'model_name'} = $self->{'model'}.'.'.$self->{'flavour'}.'.'.'task';
 
     # for global model
    if ($self->{'object'} eq '_global') {
	unless ($self->{'template'} = &tools::get_filename('etc',{},"global_task_models/$self->{'model_name'}", $Conf::Conf{'host'})) {
	    &Log::do_log ('err', 'Unable to find task model %s. Creation aborted',$self->{'model_name'});
	    return undef;
	}
    }

    # for a list
    if ($self->{'object'}  eq 'list') {
	my $list = $self->{'list_object'};
	unless ($self->{'template'} = &tools::get_filename('etc', {},"list_task_models/$self->{'model_name'}", $list->{'domain'}, $list)) {
	    &Log::do_log ('err', 'Unable to find task model %s for list %s. Creation aborted',$self->{'model_name'},$self->get_full_listname);
	    return undef;
	}
    }
    &Log::do_log ('debug2','Model for task %s is %s',$self->get_description,$self->{'template'});
    return $self->{'template'};
}

## Uses the template of this task to generate the task as string.
sub generate_from_template {
    my $self = shift;
    &Log::do_log ('debug', "Generate task content with tt2 template %s",$self->{'template'});

    unless($self->{'template'}) {
	unless($self->get_template) {
	    &Log::do_log('err','Unable to find a suitable template file for task %s',$self->get_description);
	    return undef;
	}
    }
    ## creation
    my $tt2 = Template->new({'START_TAG' => quotemeta('['),'END_TAG' => quotemeta(']'), 'ABSOLUTE' => 1});
    my $taskasstring = '';
    if ($self->{'model'} eq 'sync_include') {
	$self->{'Rdata'}{'list'}{'ttl'} = $self->{'list_object'}{'admin'}{'ttl'};
    }
    unless (defined $tt2 && $tt2->process($self->{'template'}, $self->{'Rdata'}, \$taskasstring)) {
	&Log::do_log('err', "Failed to parse task template '%s' : %s", $self->{'template'}, $tt2->error());
	return undef;
    }
    $self->{'taskasstring'} = $taskasstring;
    
    if  (!$self->check) {
	&Log::do_log ('err', 'error : syntax error in task %s, you should check %s',$self->get_description,$self->{'template'});
	&Log::do_log ('notice', "Ignoring creation task request") ;
	return undef;
    }
    &Log::do_log('debug2', 'Resulting task_as_string: %s', $self->as_string);
    return 1;
}

# Chop whetever content the task as string could contain (except titles) before the label of the task.
sub crop_after_label {
    my $self = shift;
    my $label = shift;

    &Log::do_log('debug', 'Cropping task content to keep only the content located starting label %s',$label);

    my $label_found_in_task=0; # If this variable still contains 0 at the end of the sub, that means that the label after which we want to crop does not exist in the task. We will therefore not crop anything and return the task with the same content.
    my @new_parsed_instructions;
    $self->parse unless (defined $self->{'parsed_instructions'} && $#{$self->{'parsed_instructions'}} > -1);
    foreach my $line (@{$self->{'parsed_instructions'}}) {
	if ($line->{'nature'} eq 'label' && $line->{'label'} eq $label) {
	    $label_found_in_task=1;
	    push @new_parsed_instructions, {'nature' => 'empty line','line_as_string' => ''};
	}
	if($label_found_in_task || $line->{'nature'} eq 'title') {
	    push @new_parsed_instructions, $line;
	}
    }
    unless ($label_found_in_task) {
	&Log::do_log('err','The label %s does not exist in task %s. We can not crop after it.');
	return undef;
    }else {
	$self->{'parsed_instructions'} = \@new_parsed_instructions;
	$self->stringify_parsed_instructions;
    }
	
    return 1;
}

## Stores the task to database
sub store {
    my $self = shift;

    &Log::do_log('debug','Spooling task %s',$self->get_description);
    my $taskspool = new Sympaspool('task');
    my %meta;
    $meta{'task_date'}=$self->{'date'};
    $meta{'task_label'}=$self->{'label'};
    $meta{'task_model'}=$self->{'model'};
    $meta{'task_flavour'}=$self->{'flavour'};
    $meta{'robot'}= $self->{'domain'} if $self->{'domain'};
    if ($self->{'list_object'}) {
	$meta{'list'}=$self->{'list_object'}{'name'} ;
	$meta{'task_object'}=$self->{'id'};
    }else{
	$meta{'task_object'}= '_global' ;
    }

    &Log::do_log ('debug3', 'Task creation done. date: %s, label: %s, model: %s, flavour: %s',$self->{'date'},$self->{'label'},$self->{'model'},$self->{'flavour'});
    unless($taskspool->store($self->{'taskasstring'},\%meta)) {
	&Log::do_log('err','Unable to store task %s in database.',$self->get_description);
	return undef;
    }
    &Log::do_log ('debug3', 'task %s successfully stored.',$self->get_description);
    return 1;
}

## Removes a task using message key
sub remove {
    my $self = shift;
    &Log::do_log('debug',"Removing task '%s'",$self->{'messagekey'});
    my $taskspool = new Sympaspool('task');
    unless ($taskspool->remove_message({'messagekey'=>$self->{'messagekey'}})){
	&Log::do_log('err', 'Unable to remove task (messagekey = %s)', $self->{'messagekey'});
	return undef;
    }
}

## Builds a string giving the name of the model of the task, along with its flavour and, if the task is in list context, the name of the list.
sub get_description {
    my $self = shift;
    &Log::do_log ('debug3','Computing textual description for task %s.%s',$self->{'model'},$self->{'flavour'});
    unless (defined $self->{'description'} && $self->{'description'} ne '') {
	$self->{'description'} = sprintf '%s.%s',$self->{'model'},$self->{'flavour'};
	if (defined $self->{'list_object'}) { # list task
	    $self->{'description'} .= sprintf ' (list %s)',$self->{'id'};
	}
    }
    return $self->{'description'};
}

## Uses the parsed instructions to build a new task as string. If no parsed instructions are found, returns the original task as string.
sub stringify_parsed_instructions {
    my $self = shift;
    &Log::do_log('debug2','Resetting taskasstring key of task object from the parsed content of %s',$self->get_description);

    my $new_string = $self->as_string;
    unless (defined $new_string) {
	&Log::do_log('err','task %s has no parsed content. Leaving taskasstring key unchanged',$self->get_description);
	return undef;
    }else {
	$self->{'taskasstring'} = $new_string;
	if ($Log::get_log_level > 1) {
	    &Log::do_log('debug2','task %s content recreated. Content:',$self->get_description);
	    foreach (split "\n",$self->{'taskasstring'}) {
		&Log::do_log('debug2','%s',$_);
	    }
	}
    }
    return 1;
}

## Returns a string built from parsed isntructions or undef if no parsed instructions exist.
## This sub reprensents what we obtain when concatenating the lines found in the parsed
## instructions only. we don't try to save anything. If there are no parsed instructions,
## You end up with an undef value and that's it. If you want to obtain the task as a string
## and don't know whether the instructions were parsed before or not, use stringify_parsed_instructions().
sub as_string {
    my $self = shift;
    &Log::do_log('debug2','Generating task string from the parsed content of task %s',$self->get_description);

    my $task_as_string = '';
    if (defined $self->{'parsed_instructions'} && $#{$self->{'parsed_instructions'}} > -1) {
	foreach my $line (@{$self->{'parsed_instructions'}}) {
	    $task_as_string .= "$line->{'line_as_string'}\n";
	}
	$task_as_string =~ s/\n\n$/\n/;
    }else {
	&Log::do_log('err', 'Task %s appears to have no parsed instructions.');
	$task_as_string = undef;
    }
    return $task_as_string;
}

## Returns the local part of the list name of the task if the task is in list context, undef otherwise.
sub get_short_listname {
    my $self = shift;
    if (defined $self->{'list_object'}) {
	return $self->{'list_object'}{'name'};
    }
    return undef;
}

## Returns the full list name of the task if the task is in list context, undef otherwise.
sub get_full_listname {
    my $self = shift;
    if (defined $self->{'list_object'}) {
	return $self->{'list_object'}->get_list_id;
    }
    return undef;
}
    
## Check the syntax of a task
sub check {

    my $self = shift; # the task to check

    &Log::do_log ('debug2', 'check(%s)', $self->get_description);
    my %result; # stores the result of the chk_line subroutine
    my $lnb = 0; # line number
    my %used_labels; # list of labels used as parameter in commands
    my %labels; # list of declared labels
    my %used_vars; # list of vars used as parameter in commands
    my %vars; # list of declared vars

    $self->parse;
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

## Executes the task
sub execute {

    my $self = shift;
    &Log::do_log('debug', 'Running task id = %s, %s)', $self->{'messagekey'}, $self->get_description);
    unless($self->parse) {
	&Log::do_log('err','Unable to parse task %s',$self->get_description);
	return undef;
    }
    unless ($self->process_all) {
	&Log::do_log('err', 'Error while processing task %s (messagekey=%s), removing it',$self->get_description,$self->{'messagekey'});
	$self->remove;
	return undef;
    }else{
	&Log::do_log('notice', 'The task %s has been correctly executed. Removing it (messagekey=%s)', $self->get_description, $self->{'messagekey'});
	$self->remove;
    }
    return 1;
}

## Parses the task as string into parsed instructions.
sub parse {
    my $self = shift;
    &Log::do_log ('debug2', "* Parsing task id = %s : %s", $self->{'messagekey'},$self->get_description);
    
    my $taskasstring = $self->{'taskasstring'}; # task to execute
    unless ($taskasstring) {
	&Log::do_log('err','No string describing the task available in %s',$self->get_description);
	return undef;
    }
    my $lnb = 0; # line number
    foreach my $line (split('\n',$taskasstring)){
	$lnb++;
	my $result = new TaskInstruction ({'line_as_string' =>$line, 'line_number' => $lnb});
	if ( defined $result->{'error'}) {
	    &Log::do_log ('err', "error : $result->{'error'}");
	    return undef;
	}
	push @{$self->{'parsed_instructions'}},$result;
    }
    return 1;
}

## Processes all parsed instructions sequentially.
sub process_all {
    my $self = shift;
    my $variables;
    my $result;
    &Log::do_log('debug','Processing all instructions found in task %s',$self->get_description);
    foreach my $instruction (@{$self->{'parsed_instructions'}}) {
	if (defined $self->{'must_stop'}) {
	    &Log::do_log('debug2','Stopping here for task %s',$self->get_description);
	    last;
	}
	$instruction->{'variables'} = $variables;
	unless ($result = $self->process_line($instruction)) {
	    &Log::do_log('err','Error while executing %s at line %s, task %s',$instruction->{'line_as_string'},$instruction->{'line_number'},$self->get_description);
	    return undef;
	}
	if (ref $result && $result->{'type'} eq 'variables') {
	    $variables = $result->{'variables'};
	}
    }
    return 1;
}

## Changes the label of a task file
sub change_label {
    my $task_file = $_[0];
    my $new_label = $_[1];
    
    my $new_task_file = $task_file;
    $new_task_file =~ s/(.+\.)(\w*)(\.\w+\.\w+$)/$1$new_label$3/;

    if (rename ($task_file, $new_task_file)) {
	&Log::do_log ('notice', "$task_file renamed in $new_task_file");
	return 1;
    } else {
	&Log::do_log ('err', "error ; can't rename $task_file in $new_task_file");
	return undef;
    }
}

## send a error message to list-master, log it, and change the label task into 'ERROR' 
sub error {
    my $task_id = $_[0];
    my $message = $_[1];

    my @param;
    $param[0] = "An error has occured during the execution of the task $task_id :
                 $message";
    &Log::do_log ('err', "Error in task: $message");
    change_label ($task_id, 'ERROR') unless ($task_id eq '');
    unless (&List::send_notify_to_listmaster ('error in task', $Conf::Conf{'domain'}, \@param)) {
    	&Log::do_log('notice','error while notifying listmaster about "error_in_task"');
    }
}

## Check that a task in list context is still legitimate. for example, a list whose all datasource inclusions parameters would have been removed should not keep a sync_include task.
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

#### Task line level subs ####
##############################

## Executes a single parsed line of a task.
sub process_line {
    my $self = shift;
    my $instruction = shift;
    my $status;
    if ($instruction->{'nature'} eq 'assignment' || $instruction->{'nature'} eq 'command') {
	$status = $self->cmd_process ($instruction);
    }else{
	$status->{'output'} = 'Nothing to compute';
    }
    return $status;
}

## Calls the appropriate functions for a parsed line of a task.
sub cmd_process {

    my $self = shift;
    my $instruction = shift;# The parsed instruction to execute.
    my $command = $instruction->{'command'}; # command name
    my $Rarguments = $instruction->{'Rarguments'};; # command arguments
    my $Rvars = $instruction->{'variables'};; # variable list of the task
    my $lnb = $instruction->{'line_number'}; # line number

    my $taskasstring = $self->{'taskasstring'};

    &Log::do_log('debug', 'Processing %s (line %d of task %s)', $instruction->{'line_as_string'}, $lnb,$self->get_description);
    # building of %context
    my %context = ('line_number' => $lnb);

    &Log::do_log('debug2','Current task : %s', join(':',%$self));

     # regular commands
    return stop ($self, \%context) if ($command eq 'stop');
    return next_cmd ($self, $Rarguments, \%context) if ($command eq 'next');
    return create_cmd ($self, $Rarguments, \%context) if ($command eq 'create');
    return exec_cmd ($self, $Rarguments) if ($command eq 'exec');
    return update_crl ($self, $Rarguments, \%context) if ($command eq 'update_crl');
    return expire_bounce ($self, $Rarguments, \%context) if ($command eq 'expire_bounce');
    return purge_user_table ($self, \%context) if ($command eq 'purge_user_table');
    return purge_logs_table ($self, \%context) if ($command eq 'purge_logs_table');
    return purge_session_table ($self, \%context) if ($command eq 'purge_session_table');
    return purge_tables ($self, \%context) if ($command eq 'purge_tables');
    return purge_one_time_ticket_table ($self, \%context) if ($command eq 'purge_one_time_ticket_table');
    return sync_include($self, \%context) if ($command eq 'sync_include');
    return purge_orphan_bounces ($self, \%context) if ($command eq 'purge_orphan_bounces');
    return eval_bouncers ($self, \%context) if ($command eq 'eval_bouncers');
    return process_bouncers ($self, \%context) if ($command eq 'process_bouncers');

     # commands which use a variable
    return send_msg ($self, $Rarguments, $Rvars, \%context) if ($command eq 'send_msg');       
    return rm_file ($self, $Rarguments, $Rvars, \%context) if ($command eq 'rm_file');

     # commands which return a variable
    return select_subs ($self, $Rarguments, \%context) if ($command eq 'select_subs');
    return chk_cert_expiration ($self, $Rarguments, \%context) if ($command eq 'chk_cert_expiration');

     # commands which return and use a variable
    return delete_subs_cmd ($self, $Rarguments, $Rvars, \%context) if ($command eq 'delete_subs');  
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

    &Log::do_log ('notice', "$context->{'line_number'} : stop $task->{'messagekey'}");
    
    unless ($task->remove) {
	error ($task->{'messagekey'}, "error in stop command : unable to delete task $task->{'messagekey'}");
	return undef;
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

    $task->{'must_stop'} = 1;
    my $listname = $task->{'object'};
    my $model = $task->{'model'};

    ## Determine type
    my ($type, $flavour);
    my %data = ('creation_date'  => $task->{'date'},
		'execution_date' => 'execution_date');
    if ($listname eq '_global') {
	$type = '_global';
	foreach my $key (keys %TaskSpool::global_models) {
	    if ($TaskSpool::global_models{$key} eq $model) {
		$flavour = $Conf::Conf{$key};
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
	    $flavour = 'ttl';
	}else {
	    unless (defined $list->{'admin'}{"$model\_task"}) {
		error ($task->{'messagekey'}, "List $list->{'name'} no more require $model task");
		return undef;
	    }

	    $flavour = $list->{'admin'}{"$model\_task"}{'name'};
	}
    }
    &Log::do_log('debug2','Will create next task');
    unless (create ({'creation_date' => $date, 'label' => $tab[1], 'model' => $model, 'flavour' => $flavour, 'data' => \%data})) {
	error ($task->{'messagekey'}, "error in create command : creation subroutine failure");
	return undef;
    }

    my $human_date = &tools::adate ($date);
    &Log::do_log ('debug2', "--> new task $model ($human_date)");
    return 1;
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

##sub create_cmd {
##
    ##my ($task, $Rarguments, $context) = @_;
##
    ##my @tab = @{$Rarguments};
    ##my $arg = $tab[0];
    ##my $model = $tab[1];
    ##my $flavour = $tab[2];
##
    ##&Log::do_log ('notice', "line $context->{'line_number'} : create ($arg, $model, $flavour)");
##
    ### recovery of the object type and object
    ##my $type;
    ##my $object;
    ##if ($arg =~ /$subarg_regexp/) {
	##$type = $1;
	##$object = $3;
    ##} else {
	##error ($task->{'messagekey'}, "error in create command : don't know how to create $arg");
	##return undef;
    ##}
##
    ### building of the data hash necessary to the create subroutine
    ##my %data = ('creation_date'  => $task->{'date'},
		##'execution_date' => 'execution_date');
##
    ##if ($type eq 'list') {
	##my $list = new List ($object);
	##$data{'list'}{'name'} = $list->{'name'};
    ##}
    ##$type = '_global';
    ##unless (create ($task->{'date'}, '', $model, $flavour, \%data)) {
	##error ($task->{'messagekey'}, "error in create command : creation subroutine failure");
	##return undef;
    ##}
    ##
    ##return 1;
##}
##
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

    my $result;
    $result->{'purged_users'} = $#purged_users + 1;
    return $result;
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
	 my @date = (0, 0, 0, $2, $TaskSpool::months{$1}, $3 - 1900);
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
	 my @date = (0, $4, $3 - 1, $2, $TaskSpool::months{$1}, $5 - 1900);
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
    return 1;  
}

## Packages must return true.
1;
