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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package TaskSpool;

use strict;

use Exporter;
use SympaspoolClassic;
#use Time::Local; # no longer used
# tentative
use Data::Dumper;

#use Task; # this module is used by Task
#use List; # used by Task

our @ISA = qw(SympaspoolClassic Exporter);
our @EXPORT = qw(%global_models %months);

my @task_list;
my %task_by_list;
my %task_by_model;

my @tasks; # list of tasks in the spool

our $filename_regexp = '^(\d+)\.([^\.]+)?\.([^\.]+)\.(\S+)$';
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

sub new {
    Sympa::Log::Syslog::do_log('debug2', '(%s, %s)', @_);
    return shift->SUPER::new('task', shift);
}

sub get_storage_name {
    my $self = shift;
    my $filename;
    my $param = shift;
    my $object = "_global";
    my $date = $param->{'task_date'};
    $date ||= time;
    $filename = $date.'.'.$param->{'task_label'}.'.'.$param->{'task_model'}.'.'.$param->{'task_object'};
    return $filename;
}

sub analyze_file_name {
    Sympa::Log::Syslog::do_log('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    my $key  = shift;
    my $data = shift;

    unless($key =~ /$filename_regexp/){
	Sympa::Log::Syslog::do_log('err',
	'File %s name does not have the proper format', $key);
	return undef;
    }
    $data->{'task_date'} = $1;
    $data->{'task_label'} = $2;
    $data->{'task_model'} = $3;
    $data->{'task_object'} = $4;
    Sympa::Log::Syslog::do_log('debug3', 'date %s, label %s, model %s, object %s',
	$data->{'task_date'}, $data->{'task_label'}, $data->{'task_model'},
	$data->{'task_object'});
    unless ($data->{'task_object'} eq '_global') {
	($data->{'list'}, $data->{'robot'}) =
	    split /\@/, $data->{'task_object'};
    }
    
    $data->{'list'} = lc($data->{'list'});
    $data->{'robot'} = lc($data->{'robot'});
    return undef
	unless $data->{'robot_object'} = Robot->new($data->{'robot'});

    my $listname;
    #FIXME: is this needed?
    ($listname, $data->{'type'}) =
	$data->{'robot_object'}->split_listname($data->{'list'});
    if (defined $listname) {
	$data->{'list_object'} =
	    List->new($listname, $data->{'robot_object'}, {'just_try' => 1});
    }

    return $data;
}

# Initialize Sympaspool global object.
#NO LONGER USED.
#sub set_spool {
#    $taskspool = new TaskSpool;
#}

## Build all Task objects
# Internal use.
sub list_tasks {
    Sympa::Log::Syslog::do_log('debug2', '(%s)', @_);
    my $self = shift;

    ## Reset the list of tasks
    undef @task_list;
    undef %task_by_list;
    undef %task_by_model;

    # fetch all task
    my @tasks = $self->get_content();

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
# NO LONGER USED.
#sub get_tasks_by_list {
#    my $list_id = shift;
#    &Sympa::Log::Syslog::do_log('debug',"Getting tasks for list '%s'",$list_id);
#    return () unless (defined $task_by_list{$list_id});
#    return values %{$task_by_list{$list_id}};
#}

## Returns a hash containing the model used. The models returned are all the global models or, if a list name is given as argument, the models used for this list.
# Internal use.
sub get_used_models {
    ## Optional list parameter
    my $list_id = shift;
    &Sympa::Log::Syslog::do_log('debug3',"Getting used models for list '%s'",$list_id);

    if (defined $list_id) {
	if (defined $task_by_list{$list_id}) {
	    &Sympa::Log::Syslog::do_log('debug2',"Found used models for list '%s'",$list_id);
	    return keys %{$task_by_list{$list_id}}
	}else {
	    &Sympa::Log::Syslog::do_log('debug2',"Did not find any used models for list '%s'",$list_id);
	    return ();
	}
	
    }else {
	return keys %task_by_model;
    }
}

## Returns a ref to @task_list, previously defined in the "list_task" sub.
# NO LONGER USED.
#sub get_task_list {
#    &Sympa::Log::Syslog::do_log('debug',"Getting tasks list");
#    return @task_list;
#}

## Checks that all the required tasks at the server level are defined. Create them if needed.
sub create_required_tasks {
    Sympa::Log::Syslog::do_log('debug2', '(%s)', @_);
    my $current_date = shift;

    my $taskspool = TaskSpool->new();
    $taskspool->list_tasks();

    my %default_data = ('creation_date' => $current_date, # hash of datas necessary to the creation of tasks
			'execution_date' => 'execution_date');
    create_required_global_tasks({'data' => \%default_data,'current_date' => $current_date});
    create_required_lists_tasks({'data' => \%default_data,'current_date' => $current_date});
}

## Checks that all the required GLOBAL tasks at the serever level are defined. Create them if needed.
sub create_required_global_tasks {
    my $param = shift;
    my $data = $param->{'data'};
    &Sympa::Log::Syslog::do_log('debug','Creating required tasks from global models');

    my $task;
    my %used_models; # models for which a task exists
    foreach my $model (get_used_models) {
	$used_models{$model} = 1;
    }
    foreach my $key (keys %global_models) {	
	&Sympa::Log::Syslog::do_log('debug2',"global_model : $key");
	unless ($used_models{$global_models{$key}}) {
	    if (Site->$key) {
		unless($task = Task::create ({'creation_date' => $param->{'current_date'},'model' => $global_models{$key}, 'flavour' => Site->$key, 'data' =>$data})) {
		    creation_error(sprintf 'Unable to create task with parameters creation_date = "%s", model = "%s", flavour = "%s", data = "%s"',$param->{'current_date'},$global_models{$key}, Site->$key, $data);
		}
		$used_models{$1} = 1;
	    }
	}
    }
}

## Checks that all the required LIST tasks are defined. Create them if needed.
sub create_required_lists_tasks {
    my $param = shift;
    &Sympa::Log::Syslog::do_log('debug','Creating required tasks from list models');

    my $task;
    foreach my $robot (@{Robot::get_robots()}) {
	Sympa::Log::Syslog::do_log('debug3', 'creating list task : current bot is %s',
	    $robot);
	my $all_lists = List::get_lists($robot);
	foreach my $list ( @$all_lists ) {
	    Sympa::Log::Syslog::do_log('debug3', 'creating list task : current list is %s',
		$list);
	    my %data = %{$param->{'data'}};
	    $data{'list'} = {'name' => $list->name, 'robot' => $list->domain};
	    
	    my %used_list_models; # stores which models already have a task 
	    foreach my $model (@list_models) { 
		$used_list_models{$model} = undef;
	    }
	    foreach my $model (get_used_models($list->get_id())) {		
		$used_list_models{$model} = 1; 
	    }
	    Sympa::Log::Syslog::do_log('debug3', 'creating list task using models');
	    my $tt= 0;

	    foreach my $model (@list_models) {
		unless ($used_list_models{$model}) {
		    my $model_task_parameter = "$model".'_task';

		    if ( $model eq 'sync_include') {
			next unless $list->has_include_data_sources() and
			    $list->status eq 'open';
			unless ($task = Task::create ({'creation_date' => $param->{'current_date'}, 'label' => 'INIT', 'model' => $model, 'flavour' => 'ttl', 'data' => \%data})) {
			    creation_error(sprintf 'Unable to create task with parameters list = "%s", creation_date = "%s", label = "%s", model = "%s", flavour = "%s", data = "%s"',$list->get_list_id,$param->{'current_date'},'INIT',$model,'ttl',\%data);
			}
			Sympa::Log::Syslog::do_log('debug3', 'sync_include task creation done');
			$tt++;
			
		    } elsif (%{$list->$model_task_parameter} and
			defined $list->$model_task_parameter->{'name'} and
			$list->status eq 'open') {
			unless ($task = Task::create({'creation_date' => $param->{'current_date'}, 'model' => $model, 'flavour' => $list->$model_task_parameter->{'name'}, 'data' => \%data})) {
			    creation_error(sprintf 'Unable to create task with parameters list = "%s", creation_date = "%s", model = "%s", flavour = "%s", data = "%s"', $list->get_id, $param->{'current_date'}, $model, $list->$model_task_parameter->{'name'}, \%data);
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
    Sympa::Log::Syslog::do_log('err', $message);
    Site->send_notify_to_listmaster('task_creation_error', $message);
}

## Packages must return true.
1;
