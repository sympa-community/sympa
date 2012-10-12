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

use List;
use Conf;
use Log;
use tools;
use Sympaspool;
use Data::Dumper;

my @task_list;
my %task_by_list;
my %task_by_model;

my $taskspool ;

sub set_spool {
    $taskspool = new Sympaspool('task');
}

## Creates a new Task object
sub new {
    my($pkg,$task_in_spool) = @_;
    my $task;
    &Log::do_log('debug2', 'Task::new  messagekey = %s',$task_in_spool->{'messagekey'});
    
    my $listname_regexp = &tools::get_regexp('listname');
    my $host_regexp = &tools::get_regexp('host');
    
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


## Packages must return true.
1;
