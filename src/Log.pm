#! --PERL--

# Log.pm - This module includes all Logging-related functions
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

package Log;

require Exporter;
use Sys::Syslog;
use Carp;
use POSIX qw/mktime/;


@ISA = qw(Exporter);
@EXPORT = qw(fatal_err do_log do_openlog $log_level);

my ($log_facility, $log_socket_type, $log_service,$sth,@sth_stack,$rows_nb);


local $log_level |= 0;

sub fatal_err {
    my $m  = shift;
    my $errno  = $!;
    
    syslog('err', $m, @_);
    syslog('err', "Exiting.");
    $m =~ s/%m/$errno/g;

    my $full_msg = sprintf $m,@_;

    ## Notify listmaster
    unless (&List::send_notify_to_listmaster('sympa_died', $Conf::Conf{'host'}, [$full_msg])) {
	&do_log('err',"Unable to send notify 'sympa died' to listmaster");
    }


    printf STDERR "$m\n", @_;
    exit(1);   
}

sub do_log {
    my $fac = shift;
    my $m = shift;

    my $errno = $!;
    my $debug = 0;

    my $level = 0;

    ## Encode parameters to FS encoding to prevent "Wide character in syswrite" errors
    foreach my $i (0..$#_) {
	$_[$i] = Encode::encode($Conf::Conf{'filesystem_encoding'}, $_[$i]) if (&Encode::is_utf8($_[$i]));
    }

    $level = 1 if ($fac =~ /^debug$/) ;

    if ($fac =~ /debug(\d)/ ) {
	$level = $1;
	$fac = 'debug';
    }
 
    # do not log if log level if too high regarding the log requested by user 
    return if ($level > $log_level);

    unless (syslog($fac, $m, @_)) {
	&do_connect();
	    syslog($fac, $m, @_);
    }
    if ($main::options{'foreground'}) {
	if ($main::options{'log_to_stderr'} || 
	    ($main::options{'batch'} && $fac eq 'err')) {
	    $m =~ s/%m/$errno/g;
	    printf STDERR "$m\n", @_;
	}
    }    
}


sub do_openlog {
   my ($fac, $socket_type, $service) = @_;
   $service ||= 'sympa';

   ($log_facility, $log_socket_type, $log_service) = ($fac, $socket_type, $service);

#   foreach my $k (keys %options) {
#       printf "%s = %s\n", $k, $options{$k};
#   }

   &do_connect();
}

sub do_connect {
    if ($log_socket_type =~ /^(unix|inet)$/i) {
      Sys::Syslog::setlogsock(lc($log_socket_type));
    }
    # close log may be usefull : if parent processus did open log child process inherit the openlog with parameters from parent process 
    closelog ; 
    openlog("$log_service\[$$\]", 'ndelay', $log_facility);
}

# return the name of the used daemon
sub set_daemon {
    my $daemon_tmp = shift;
    my @path = split(/\//, $daemon_tmp);
    my $daemon = $path[$#path];
    $daemon =~ s/(\.[^\.]+)$//; 
    return $daemon;
}

sub get_log_date {
    my $date_from,
    my $date_to;
 
    my $dbh = &List::db_get_handler();

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
	$dbh = &List::db_get_handler();
    }

    my $statement;
    my @dates;
    foreach my $query('MIN','MAX') {
	$statement = "SELECT $query(date_logs) FROM logs_table";
	push @sth_stack, $sth;
	unless($sth = $dbh->prepare($statement)) { 
	    do_log('err','Get_log_date: Unable to prepare SQL statement : %s %s',$statement, $dbh->errstr);
	    return undef;
	}
	unless($sth->execute) {
	    do_log('err','Get_log_date: Unable to execute SQL statement %s %s',$statement, $dbh->errstr);
	    return undef;
	}
	while (my $d = ($sth->fetchrow_array) [0]) {
	    push @dates, $d;
	}
    }
    $sth->finish();
    $sth = pop @sth_stack;
    
    return @dates;
}
    
       
# add log in RDBMS 
sub db_log {
    my $arg = shift;
    
    my $list = $arg->{'list'};
    my $robot = $arg->{'robot'};
    my $action = $arg->{'action'};
    my $parameters = &tools::clean_msg_id($arg->{'parameters'});
    my $target_email = $arg->{'target_email'};
    my $msg_id = &tools::clean_msg_id($arg->{'msg_id'});
    my $status = $arg->{'status'};
    my $error_type = $arg->{'error_type'};
    my $user_email = &tools::clean_msg_id($arg->{'user_email'});
    my $client = $arg->{'client'};
    my $daemon = $arg->{'daemon'};
    my $date=time;
    my $random = int(rand(1000));
    my $id = $date*1000+$random;

    unless($user_email) {
	$user_email = 'anonymous';
    }
    unless($list) {
	$list = '';
    }
    #remove the robot name of the list name
    if($list =~ /(.+)\@(.+)/) {
	$list = $1;
	unless($robot) {
	    $robot = $2;
	}
    }

    my $dbh = &List::db_get_handler();

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
	$dbh = &List::db_get_handler();
    }

    unless ($daemon =~ /^((task)|(archived)|(sympa)|(wwsympa)|(bounced)|(sympa_soap))$/) {
	do_log ('err',"Internal_error : incorrect process value $daemon");
	return undef;
    }
    
    ## Insert in log_table

    my $statement = sprintf 'INSERT INTO logs_table (id_logs,date_logs,robot_logs,list_logs,action_logs,parameters_logs,target_email_logs,msg_id_logs,status_logs,error_type_logs,user_email_logs,client_logs,daemon_logs) VALUES (%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',
    $id, 
    $date, 
    $dbh->quote($robot), 
    $dbh->quote($list), 
    $dbh->quote($action), 
    $dbh->quote($parameters),
    $dbh->quote($target_email),
    $dbh->quote($msg_id),
    $dbh->quote($status),
    $dbh->quote($error_type),
    $dbh->quote($user_email),
    $dbh->quote($client),
    $dbh->quote($daemon);		    
    
    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s", %s', $statement, $dbh->errstr);
	return undef;
    }
      
}

# delete logs in RDBMS
sub db_log_del {
    my $exp = &Conf::get_robot_conf($Conf{'host'},'logs_expiration_period');
    my $date = time - ($exp * 24 * 60 * 60);

    my $dbh = &List::db_get_handler();

    my $statement =  sprintf "DELETE FROM logs_table WHERE (logs_table.date_logs <= %s)", $dbh->quote($date);

    unless ($dbh->do($statement)) {
	&do_log('err','Unable to execute SQL statement "%s" : %s',$statement, $dbh->errstr);
	return undef;
    }

}

# Scan log_table with appropriate select 
sub get_first_db_log {
    my $dbh = &List::db_get_handler();
    my $select = shift;

    ## Dump vars
    #open TMP, ">/tmp/logs.dump";
    #&tools::dump_var($select, 0, \*TMP);
    #close TMP;

    my %action_type = ('message' => ['reject','distribute','arc_delete','arc_download',
				     'sendMessage','remove','record_email','send_me',
				     'd_remove_arc','rebuildarc','remind','send_mail',
				     'DoFile','sendMessage','DoForward','DoMessage',
				     'DoCommand','SendDigest'],
		       'authentication' => ['login','logout','loginrequest','sendpasswd',
					    'ssologin','ssologin_succeses','remindpasswd',
					    'change_identity','choosepasswd'],
		       'subscription' => ['subscribe','signoff','add','del','ignoresub',
					  'subindex'],
		       'list_management' => ['create_list','rename_list','close_list',
					     'edit_list','admin','blacklist','install_pending_list',
					     'purge_list','edit_template','copy_template',
					     'remove_template'],
		       'bounced' => ['resetbounce','get_bounce'],
		       'preferences' => ['set','setpref','pref','change_email','setpasswd','record_email','editsubscriber'],
		       'shared' => ['d_unzip','d_upload','d_read','d_delete','d_savefile',
				    'd_overwrite','d_create_dir','d_set_owner','d_change_access',
				    'd_describe','d_rename','d_editfile','d_admin',
				    'd_install_shared','d_reject_shared','d_properties',
				    'creation_shared_file','d_unzip_shared_file',
				    'install_file_hierarchy','d_copy_rec_dir','d_copy_file',
				    'change_email','set_lang','new_d_read','d_control'],
		       );
		       
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
	$dbh = &List::db_get_handler();
    }

    my $statement = sprintf "SELECT date_logs AS date, robot_logs AS robot, list_logs AS list, action_logs AS action, parameters_logs AS parameters, target_email_logs AS target_email,msg_id_logs AS msg_id, status_logs AS status, error_type_logs AS error_type, user_email_logs AS user_email, client_logs AS client, daemon_logs AS daemon FROM logs_table WHERE robot_logs=%s ", $dbh->quote($select->{'robot'});	

    #If the checkbox is checked, the other parameters of research are not taken into account.
    unless ($select->{'all'} eq 'on') {
	my $list_selected = 'false'; #like $robot_selected, for a list.
	
        
	#if a type of target and a target are specified
	if (($select->{'type_target'}) && ($select->{'type_target'} ne 'none')) {
	    if($select->{'target'}) {
		$select->{'type_target'} = lc ($select->{'type_target'});
		$select->{'target'} = lc ($select->{'target'});
		$statement .= 'AND ' . $select->{'type_target'} . '_logs = ' . $dbh->quote($select->{'target'}).' ';
	    }
	}

	#if the search is between two date
	if ($select->{'date_from'}) {
	    my @tab_date_from = split(/\//,$select->{'date_from'});
	    my $date_from = &POSIX::mktime(0,0,-1,$tab_date_from[0],$tab_date_from[1]-1,$tab_date_from[2]-1900);
	    unless($select->{'date_to'}) {
		my $date_from2 = &POSIX::mktime(0,0,25,$tab_date_from[0],$tab_date_from[1]-1,$tab_date_from[2]-1900);
		$statement .= sprintf "AND date_logs BETWEEN '%s' AND '%s' ",$date_from, $date_from2;
	    }
	    if($select->{'date_to'}) {
		my @tab_date_to = split(/\//,$select->{'date_to'});
		my $date_to = &POSIX::mktime(0,0,25,$tab_date_to[0],$tab_date_to[1]-1,$tab_date_to[2]-1900);
		
		$statement .= sprintf "AND date_logs BETWEEN '%s' AND '%s' ",$date_from, $date_to;
	    }
	}

	#if the search is on a precise type
	if ($select->{'type'}) {
	    if(($select->{'type'} ne 'none') && ($select->{'type'} ne 'all_actions')) {
		my $first = 'false';
		foreach my $type(@{$action_type{$select->{'type'}}}) {
		    if($first eq 'false') {
			#if it is the first action, put AND on the statement
			$statement .= sprintf "AND (logs_table.action_logs = '%s' ",$type;
			$first = 'true';
		    }
		    #else, put OR
		    else {
			$statement .= sprintf "OR logs_table.action_logs = '%s' ",$type;
		    }
		}
		$statement .= ')';
	    }
	    
	}

	#if the listmaster want to make a search by an IP adress.
	if($select->{'ip'}) {
	    $statement .= sprintf "AND client_logs = '%s'",$select->{'ip'};
	}
	
	## Currently not used
	#if the search is on the actor of the action
	if ($select->{'user_email'}) {
	    $select->{'user_email'} = lc ($select->{'user_email'});
	    $statement .= sprintf "AND user_email_logs = '%s' ",$select->{'user_email'}; 
	}

	#if a list is specified -just for owner or above-
	if($select->{'list'}) {
	    if($select->{'list'} eq 'all_list') {
		my $first = 'false';
		my $which_list;
		if($select->{'privilege'} eq 'owner') {
		    $which_list = 'alllists_owner';
		}
		if($select->{'privilege'} eq 'listmaster') {
		    $statement .= sprintf "AND (list_logs = '' ";
		    $which_list = 'alllists';
		    $first = 'true';
		}
		foreach my $alllists(@{$select->{$which_list}}) {
		    #if it is the first list, put AND on the statement
		    if($first eq 'false') {
			$statement .= sprintf "AND (list_logs = '%s' ",$alllists;
			$first = 'true';
		    }
		    #else, put OR
		    else {
			$statement .= sprintf "OR list_logs = '%s' ",$alllists;
		    }
		}
		$statement .= sprintf ")";
		$list_selected = 'true';
	    }
	    else {
		if($select->{'list'} ne 'none') {
		    $select->{'list'} = lc ($select->{'list'});
		    $statement .= sprintf "AND list_logs = '%s' ",$select->{'list'};
		    $list_selected = 'true';
		}
	    }
	}
	
    }
    #If the checkbox is checked
    else {
	#an editor has just an access on the current list and robot
	if($select->{'privilege'} eq 'editor') {
	    $statement .= sprintf "AND list_logs = '%s' ",$select->{'current_list'}; 
	}
	if($select->{'privilege'} eq 'owner') {
	    my $first = 'false';
	    foreach my $alllists(@{$select->{'alllists_owner'}}) {
		#if it is the first list, put AND on the statement
		if($first eq 'false') {
		    $statement .= sprintf "AND (list_logs = '%s' ",$alllists;
		    $first = 'true';
		}
		#else, put OR
		else {
		    $statement .= sprintf "OR list_logs = '%s' ",$alllists;
		}
	    }
	    $statement .= sprintf ")";

	}
	#on the current robot to the listmaster
	if($select->{'privilege'} eq 'listmaster') {
	    $statement .= sprintf "AND robot_logs = '%s' ",$select->{'robot'};
	}
    }
    $statement .= sprintf "GROUP BY date_logs "; 

    push @sth_stack, $sth;
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    $rows_nb = $sth->rows;

    ## If no rows returned, return an empty hash
    ## Required to differenciate errors and empty results
    if ($rows_nb == 0) {
	return {};
    }
    return ($sth->fetchrow_hashref);
    
}
sub return_rows_nb {
    return $rows_nb;
}
sub get_next_db_log {

    my $log = $sth->fetchrow_hashref;
    
    unless (defined $log) {
	$sth->finish;
	$sth = pop @sth_stack;
    }
    return $log;
}

1;








