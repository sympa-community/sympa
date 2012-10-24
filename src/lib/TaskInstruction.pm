# TaskInstruction.pm - This module includes the TaskInstruction object.
# This object is used to handle a single line contained by a task.
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

package TaskInstruction;

use strict;

use Carp;
use Data::Dumper;
use Digest::MD5;
use Exporter;
use Time::Local;

use tools;
use Task;
use List;

###### DEFINITION OF AVAILABLE COMMANDS FOR TASKS ######

our $date_arg_regexp1 = '\d+|execution_date';
our $date_arg_regexp2 = '(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?'; 
our $date_arg_regexp3 = '(\d+|execution_date)(\+|\-)(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
our $delay_regexp = '(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
our $var_regexp ='@\w+'; 
our $subarg_regexp = '(\w+)(|\((.*)\))'; # for argument with sub argument (ie arg(sub_arg))
                 
# regular commands
our %commands = ('next'          		=>	{
											'args' =>['date', '\w*'],
													# date   label
											'sub' => \&next_cmd,
											},
                'stop'                  =>	{
											'args' => [],
											'sub' => \&stop,
											},
				'create'                =>	{
											'args' => ['subarg', '\w+', '\w+'],
														#object    model  model choice
											'sub' => \&create_cmd,
											},
				'exec'                  =>	{
											'args' => ['.+'],
													#script
											'sub' => \&exec_cmd,
											},
				'update_crl'            =>	{
											'args' => ['\w+', 'date'], 
														#file    #delay
											'sub' => \&update_crl,
											},
				'expire_bounce'         =>	{
											'args' => ['\d+'],
													#Number of days (delay)
											'sub' => \&expire_bounce,
											},
				'chk_cert_expiration'   =>	{
											'args' => ['\w+', 'date'],
														#template  date
											'sub' => \&chk_cert_expiration,
											},
				'sync_include'          =>	{
											'args' => [],
											'sub' => \&sync_include,
											},
				'purge_user_table'      =>	{
											'args' => [],
											'sub' => \&purge_user_table,
											},
				'purge_logs_table'      =>	{
											'args' => [],
											'sub' => \&purge_logs_table,
											},
				'purge_session_table'   =>	{
											'args' => [],
											'sub' => \&purge_session_table,
											},
				'purge_tables'   		=>	{
											'args' => [],
											'sub' => \&purge_tables,
											},
				'purge_one_time_ticket_table'   =>	{
											'args' => [],
											'sub' => \&purge_one_time_ticket_table,
											},
				'purge_orphan_bounces'  =>	{
											'args' => [],
											'sub' => \&purge_orphan_bounces,
											},
				'eval_bouncers'         =>	{
											'args' => [],
											'sub' => \&eval_bouncers,
											},
				'process_bouncers'      =>	{
											'args' => [],
											'sub' => \&process_bouncers,
											},
		);

# commands which use a variable. If you add such a command, the first parameter must be the variable
our %var_commands = ('delete_subs'      =>	{
											'args' => ['var'],
													# variable 
											'sub' => \&delete_subs_cmd,
											},
					'send_msg'         =>	{
											'args' => ['var',  '\w+' ],
													#variable template
											'sub' => \&send_msg,
											},
					'rm_file'          =>	{
											'args' => ['var'],
													# variable
											'sub' => \&rm_file,
											},
		    );

foreach (keys %var_commands) {
    $commands{$_} = $var_commands{$_};
}

# commands which are used for assignments
our %asgn_commands = ('select_subs'      =>	{
											'args' => ['subarg'],
													# condition
											'sub' => \&select_subs,
											},
					'delete_subs'      =>	{
											'args' => ['var'],
													# variable
											'sub' => \&delete_subs_cmd,
											},
		     );

foreach (keys %asgn_commands) {
    $commands{$_} = $asgn_commands{$_};
}                                    

sub new {
	my $pkg = shift;
	my $data = shift; #Instructions are built by parsing a single line of a task string.
	my $self = &tools::dup_var($data);

	bless $self, $pkg;
	$self->parse;
	return $self;
}

## Parses the line of a task and returns a hash that can be executed.
sub parse {
	my $self = shift;
	
    &Log::do_log('debug2', 'Parsing "%s"', $self->{'line_as_string'});

    $self->{'nature'} = undef;
    # empty line
    if (! $self->{'line_as_string'}) {
	$self->{'nature'} = 'empty line';
    # comment
    }elsif ($self->{'line_as_string'} =~ /^\s*\#.*/) {
	$self->{'nature'} = 'comment';
    # title
    }elsif ($self->{'line_as_string'} =~ /^\s*title\...\s*(.*)\s*/i) {
	$self->{'nature'} = 'title';
	$self->{'title'} = $1;
    # label
    }elsif ($self->{'line_as_string'} =~ /^\s*\/\s*(.*)/) {
	$self->{'nature'} = 'label';
	$self->{'label'} = $1;
    # command
     }elsif ($self->{'line_as_string'} =~ /^\s*(\w+)\s*\((.*)\)\s*/i ) { 
	my $command = lc ($1);
	my @args = split (/,/, $2);
	foreach (@args) { s/\s//g;}

	unless ($commands{$command}) { 
	    $self->{'nature'} = 'error';
	    $self->{'error'} = "unknown command $command";
	}else {
	    $self->{'nature'} = 'command';
	    $self->{'command'} = $command;

	    # arguments recovery. no checking of their syntax !!!
	    $self->{'Rarguments'} = \@args;
	    $self->chk_cmd;
	}
    # assignment
    }elsif ($self->{'line_as_string'} =~ /^\s*(@\w+)\s*=\s*(.+)/) {

		my $subinstruction = new TaskInstruction ({'line_as_string' => $2, 'line_number' => $self->{'line_number'}});
		
		unless ( $asgn_commands{$subinstruction->{'command'}} ) { 
			$self->{'nature'} = 'error';
			$self->{'error'} = "non valid assignment $2";
		}else {
			$self->{'nature'} = 'assignment';
			$self->{'var'} = $1;
			$self->{'command'} = $subinstruction->{'command'};
			$self->{'Rarguments'} = $subinstruction->{'Rarguments'};
		}
    }else {
		$self->{'nature'} = 'error'; 
		$self->{'error'} = 'syntax error';
    }
}

## Checks the arguments of a command 
sub chk_cmd {

    my $self = shift;

    &Log::do_log('debug2', 'chk_cmd(%s, %d, %s)', $self->{'command'}, $self->{'line_number'}, join(',',@{$self->{'Rarguments'}}));
    
    if (defined $commands{$self->{'command'}}) {
	
	my @expected_args = @{$commands{$self->{'command'}}{'args'}};
	my @args = @{$self->{'Rarguments'}};
	
	unless ($#expected_args == $#args) {
	    &Log::do_log ('err', "error at line $self->{'line_number'} : wrong number of arguments for $self->{'command'}");
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
		&Log::do_log ('err', "error at line $self->{'line_number'} : argument $_ is not valid");
		return undef;
	    }
	    
	    $self->{'used_labels'}{$args[1]} = 1 if ($self->{'command'} eq 'next' && ($args[1]));   
	    $self->{'used_vars'}{$args[0]} = 1 if ($var_commands{$self->{'command'}});
	}
    }
    return 1;
}

## Calls the appropriate functions for a parsed line of a task.
sub cmd_process {

    my $self = shift;
    my $task = shift;# The parsed instruction to execute.

    my $taskasstring = $task->{'taskasstring'};

    &Log::do_log('debug', 'Processing "%s" (line %d of task %s)', $self->{'line_as_string'}, $self->{'line_number'},$task->get_description);

	# regular commands
	return &{$commands{$self->{'command'}}{'sub'}}($self,$task);
}

### command subroutines ###
 
# remove files whose name is given in the key 'file' of the hash
sub rm_file {
    
    my ($self,$task) = @_;
    
    my @tab = @{$self->{'Rarguments'}};
    my $var = $tab[0];

    foreach my $key (keys %{$self->{'variables'}{$var}}) {
	my $file = $self->{'variables'}{$var}{$key}{'file'};
	next unless ($file);
	unless (unlink ($file)) {
	    error ($task->{'filepath'}, "error in rm_file command : unable to remove $file");
	    return undef;
	}
    }

    return 1;
}

sub stop {
    
    my ($self,$task) = @_;

    &Log::do_log ('notice', "$self->{'line_number'} : stop $task->{'messagekey'}");
    
    unless ($task->remove) {
	error ($task->{'messagekey'}, "error in stop command : unable to delete task $task->{'messagekey'}");
	return undef;
    }
}

sub send_msg {
        
    my ($self,$task) = @_;
    
    my @tab = @{$self->{'Rarguments'}};
    my $template = $tab[1];
    my $var = $tab[0];
    
    &Log::do_log ('notice', "line $self->{'line_number'} : send_msg (@{$self->{'Rarguments'}})");

    if ($task->{'object'} eq '_global') {

	foreach my $email (keys %{$self->{'variables'}{$var}}) {
	    unless (&List::send_global_file ($template, $email, ,'',$self->{'variables'}{$var}{$email}) ) {
		&Log::do_log ('notice', "Unable to send template $template to $email");
	    }else{
		&Log::do_log ('notice', "--> message sent to $email");
	    }
	}
    } else {
	my $list = $task->{'list_object'};
	foreach my $email (keys %{$self->{'variables'}{$var}}) {
	    unless ($list->send_file ($template, $email, $list->{'domain'}, $self->{'variables'}{$var}{$email}))  {
		&Log::do_log ('notice', "Unable to send template $template to $email");
	    }else{
		&Log::do_log ('notice', "--> message sent to $email");
	    }
	}
    }
    return 1;
}

sub next_cmd {
        
    my ($self,$task) = @_;
    
    my @tab = @{$self->{'Rarguments'}};
    my $date = &tools::epoch_conv ($tab[0], $task->{'date'}); # conversion of the date argument into epoch format
    my $label = $tab[1];

    &Log::do_log ('debug2', "line $self->{'line_number'} of $task->{'model'} : next ($date, $label)");

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
    unless (Task::create ({'creation_date' => $date, 'label' => $tab[1], 'model' => $model, 'flavour' => $flavour, 'data' => \%data})) {
	error ($task->{'messagekey'}, "error in create command : creation subroutine failure");
	return undef;
    }

    my $human_date = &tools::adate ($date);
    &Log::do_log ('debug2', "--> new task $model ($human_date)");
    return 1;
}

sub select_subs {

    my ($self,$task) = @_;

    my @tab = @{$self->{'Rarguments'}};
    my $condition = $tab[0];
 
    &Log::do_log ('debug2', "line $self->{'line_number'} : select_subs ($condition)");
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

    my ($self,$task) = @_;

    my @tab = @{$self->{'Rarguments'}};
    my $var = $tab[0];

    &Log::do_log ('notice', "line $self->{'line_number'} : delete_subs ($var)");

    
    my $list = $task->{'list_object'};
    my %selection; # hash of subscriber emails who are successfully deleted

    foreach my $email (keys %{$self->{'variables'}{$var}}) {

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

    my ($self,$task) = @_;

    my @tab = @{$self->{'Rarguments'}};
    my $arg = $tab[0];
    my $model = $tab[1];
    my $flavour = $tab[2];

    &Log::do_log ('notice', "line $self->{'line_number'} : create ($arg, $model, $flavour)");

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
    unless (create ($task->{'date'}, '', $model, $flavour, \%data)) {
	error ($task->{'messagekey'}, "error in create command : creation subroutine failure");
	return undef;
    }
    
    return 1;
}

sub exec_cmd {

    my ($self,$task) = @_;

    my @tab = @{$self->{'Rarguments'}};
    my $file = $tab[0];

    &Log::do_log ('notice', "line $self->{'line_number'} : exec ($file)");
    system ($file);
    
    return 1;
}

sub purge_logs_table {
    # If a log is older then $list->get_latest_distribution_date()-$delai expire the log
    my ($self,$task) = @_;
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

    my ($self,$task) = @_;
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

    my ($self,$task) = @_;
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

    my ($self,$task) = @_;
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
    my ($self,$task) = @_;
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
    my ($self,$task) = @_;
    
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
     my ($self,$task) = @_;

     my $execution_date = $task->{'date'};
     my @tab = @{$self->{'Rarguments'}};
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

     my ($self,$task) = @_;

    my $cert_dir = &Conf::get_robot_conf('*','ssl_cert_dir');
     my $execution_date = $task->{'date'};
     my @tab = @{$self->{'Rarguments'}};
     my $template = $tab[0];
     my $limit = &tools::duration_conv ($tab[1], $execution_date);

     &Log::do_log ('notice', "line $self->{'line_number'} : chk_cert_expiration (@{$self->{'Rarguments'}})");

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

     my ($self,$task) = @_;

     my @tab = @{$self->{'Rarguments'}};
     my $limit = &tools::epoch_conv ($tab[1], $task->{'date'});
     my $CA_file = "$Conf::Conf{'home'}/$tab[0]"; # file where CA urls are stored ;
     &Log::do_log ('notice', "line $self->{'line_number'} : update_crl (@tab)");

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
    my ($self,$task) = @_;
    
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
    my ($self,$task) = @_;
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
    my ($self,$task) = @_;

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

# Packages must return true;
return 1;
