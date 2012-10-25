# TaskSpool.pm - This module includes high level subs to manipulate the tasks spool.
#<!-- RCS Identication ; $Revision: 7792 $ ; $Date: 2012-10-23 15:36:05 +0200 (mar 23 oct 2012) $ --> 

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

package TaskSpool;

use strict;

use Data::Dumper;
use Exporter;
use Time::Local;

our @ISA = qw(Exporter);
our @EXPORT = qw(%global_models %months);

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

#### Spool level subs ####
##########################

# Initialize Sympaspool global object.
sub set_spool {
    $taskspool = new Sympaspool('task');
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

## Returns a hash containing the model used. The models returned are all the global models or, if a list name is given as argument, the models used for this list.
sub get_used_models {
    ## Optional list parameter
    my $list_id = shift;
    &Log::do_log('debug3',"Getting used models for list '%s'",$list_id);

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

## Returns a ref to @task_list, previously defined in the "list_task" sub.
sub get_task_list {
    &Log::do_log('debug',"Getting tasks list");
    return @task_list;
}

## Checks that all the required tasks at the server level are defined. Create them if needed.
sub create_required_tasks {
    my $current_date = shift;
    &Log::do_log('debug','Creating required tasks from models');
    my %default_data = ('creation_date' => $current_date, # hash of datas necessary to the creation of tasks
			'execution_date' => 'execution_date');
    create_required_global_tasks({'data' => \%default_data,'current_date' => $current_date});
    create_required_lists_tasks({'data' => \%default_data,'current_date' => $current_date});
}

## Checks that all the required GLOBAL tasks at the serever level are defined. Create them if needed.
sub create_required_global_tasks {
    my $param = shift;
    my $data = $param->{'data'};
    &Log::do_log('debug','Creating required tasks from global models');

    my $task;
    my %used_models; # models for which a task exists
    foreach my $model (get_used_models) {
	$used_models{$model} = 1;
    }
    foreach my $key (keys %global_models) {	
	&Log::do_log('debug2',"global_model : $key");
	unless ($used_models{$global_models{$key}}) {
	    if ($Conf::Conf{$key}) {
		unless($task = Task::create ({'creation_date' => $param->{'current_date'},'model' => $global_models{$key}, 'flavour' => $Conf::Conf{$key}, 'data' =>$data})) {
		    creation_error(sprintf 'Unable to create task with parameters creation_date = "%s", model = "%s", flavour = "%s", data = "%s"',$param->{'current_date'},$global_models{$key},$Conf::Conf{$key},$data);
		}
		$used_models{$1} = 1;
	    }
	}
    }
}

## Checks that all the required LIST tasks are defined. Create them if needed.
sub create_required_lists_tasks {
    my $param = shift;
    &Log::do_log('debug','Creating required tasks from list models');

    my $task;
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
	    foreach my $model (get_used_models($list->get_list_id())) {		
		$used_list_models{$model} = 1; 
	    }
	    &Log::do_log('debug3',"creating list task using models");my $tt= 0;

	    foreach my $model (@list_models) {
		unless ($used_list_models{$model}) {
		    my $model_task_parameter = "$model".'_task';
		    
		    if ( $model eq 'sync_include') {
			next unless ($list->has_include_data_sources() &&
				     ($list->{'admin'}{'status'} eq 'open'));
			unless ($task = Task::create ({'creation_date' => $param->{'current_date'}, 'label' => 'INIT', 'model' => $model, 'flavour' => 'ttl', 'data' => \%data})) {
			    creation_error(sprintf 'Unable to create task with parameters list = "%s", creation_date = "%s", label = "%s", model = "%s", flavour = "%s", data = "%s"',$list->get_list_id,$param->{'current_date'},'INIT',$model,'ttl',\%data);
			}
			&Log::do_log('debug3',"sync_include task creation done");$tt++;
			
		    }elsif (defined $list->{'admin'}{$model_task_parameter} && 
			    defined $list->{'admin'}{$model_task_parameter}{'name'} &&
			    ($list->{'admin'}{'status'} eq 'open')) {
			unless ($task = Task::create ({'creation_date' => $param->{'current_date'}, 'model' => $model, 'flavour' => $list->{'admin'}{$model_task_parameter}{'name'}, 'data' => \%data})) {
			    creation_error(sprintf 'Unable to create task with parameters list = "%s", creation_date = "%s", model = "%s", flavour = "%s", data = "%s"',$list->get_list_id,$param->{'current_date'},$model,$list->{'admin'}{$model_task_parameter}{'name'},\%data);
			}
			$tt++;
		    }
		}
	    }
	}
    }
}

sub creation_error {
    my $message = shift;
    &Log::do_log('err',$message);
    unless (&List::send_notify_to_listmaster ('error in task', $Conf::Conf{'domain'}, [$message])) {
	&Log::do_log('notice','error while notifying listmaster about "error_in_task"');
    }
}

## Packages must return true.
return 1;
