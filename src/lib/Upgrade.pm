# Upgrade.pm - This module gathers all subroutines used to upgrade Sympa data structures
#<!-- RCS Identication ; $Revision$ --> 

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

package Upgrade;

use strict;

use Carp;
use POSIX qw(strftime);

use Conf;
use Log;
use Sympa::Constants;

my %db_struct = ('mysql' => {'user_table' => {'email_user' => 'varchar(100)',
					      'gecos_user' => 'varchar(150)',
					      'password_user' => 'varchar(40)',
					      'last_login_date_user' => 'int(11)',
					      'last_login_host_user' => 'varchar(60)',
					      'wrong_login_count_user' => 'int(11)',
					      'cookie_delay_user' => 'int(11)',
					      'lang_user' => 'varchar(10)',
					      'attributes_user' => 'text',
					      'data_user' => 'text'},
			     'subscriber_table' => {'list_subscriber' => 'varchar(50)',
						    'user_subscriber' => 'varchar(100)',
						    'robot_subscriber' => 'varchar(80)',
						    'date_subscriber' => 'datetime',
						    'number_messages_subscriber' => 'int(5)',
						    'update_subscriber' => 'datetime',
						    'visibility_subscriber' => 'varchar(20)',
						    'reception_subscriber' => 'varchar(20)',
						    'topics_subscriber' => 'varchar(200)',
						    'bounce_subscriber' => 'varchar(35)',
						    'comment_subscriber' => 'varchar(150)',
						    'subscribed_subscriber' => "int(1)",
						    'included_subscriber' => "int(1)",
						    'include_sources_subscriber' => 'varchar(50)',
						    'bounce_score_subscriber' => 'smallint(6)',
						    'bounce_address_subscriber' => 'varchar(100)',
						    'custom_attribute_subscriber' => 'text',
						    'suspend_subscriber' => "int(1)",
						    'suspend_start_date_subscriber' => 'int(11)',
						    'suspend_end_date_subscriber' => 'int(11)'},
			     'admin_table' => {'list_admin' => 'varchar(50)',
					       'user_admin' => 'varchar(100)',
					       'robot_admin' => 'varchar(80)',
					       'role_admin' => "enum('listmaster','owner','editor')",
					       'date_admin' => 'datetime',
					       'update_admin' => 'datetime',
					       'reception_admin' => 'varchar(20)',
					       'visibility_admin' => 'varchar(20)',
					       'comment_admin' => 'varchar(150)',
					       'subscribed_admin' => "int(1)",
					       'included_admin' => "int(1)",
					       'include_sources_admin' => 'varchar(50)',
					       'info_admin' =>  'varchar(150)',
					       'profile_admin' => "enum('privileged','normal')"},
			     'exclusion_table' => {'list_exclusion' => 'varchar(50)',
						   'user_exclusion' => 'varchar(100)',
						   'date_exclusion' => 'int(11)'},
			     'netidmap_table' => {'netid_netidmap' => 'varchar(100)',
						  'serviceid_netidmap' => 'varchar(100)',
						  'email_netidmap' => 'varchar(100)',
						  'robot_netidmap' => 'varchar(80)'},
			     'session_table' => {'id_session' => 'varchar(30)',
						 'start_date_session' => 'int(11)',
						 'date_session' => 'int(11)',
						 'remote_addr_session' => 'varchar(60)',
						 'robot_session'  => 'varchar(80)',
						 'email_session'  => 'varchar(100)',
						 'hit_session' => 'int(11)',
						 'data_session'  => 'text'},
			     'logs_table' => {'id_logs' => 'bigint(20)',
					      'date_logs' => 'int(11)',
					      'robot_logs' => 'varchar(80)',
					      'list_logs' => 'varchar(50)',
					      'action_logs' => 'varchar(50)',
					      'parameters_logs' => 'varchar(100)',
					      'target_email_logs' => 'varchar(100)',
					      'user_email_logs' => 'varchar(100)',
					      'msg_id_logs' => 'varchar(255)',
					      'status_logs' => 'varchar(10)',
					      'error_type_logs' => 'varchar(150)',
					      'client_logs' => 'varchar(100)',
					      'daemon_logs' => 'varchar(10)'},
			     'one_time_ticket_table' => {'ticket_one_time_ticket' => 'varchar(30)',
							 'email_one_time_ticket' => 'varchar(100)',
							 'robot_one_time_ticket' => 'varchar(80)',
							 'date_one_time_ticket' => 'int(11)',
							 'data_one_time_ticket' => 'varchar(200)',
							 'remote_addr_one_time_ticket' => 'varchar(60)',
							 'status_one_time_ticket' => 'varchar(60)'},
			     'bulkmailer_table' => {'messagekey_bulkmailer' => 'varchar(80)',
						    'messageid_bulkmailer' => 'varchar(100)',
						    'packetid_bulkmailer' => 'varchar(33)',
						    'receipients_bulkmailer' => 'text',
						    'returnpath_bulkmailer' => 'varchar(100)',
						    'robot_bulkmailer' => 'varchar(80)',
						    'listname_bulkmailer' => 'varchar(50)',
						    'verp_bulkmailer' => 'int(1)',
						    'tracking_bulkmailer' => "enum('mdn','dsn')",
						    'merge_bulkmailer' => 'int(1)',
						    'priority_message_bulkmailer' => 'smallint(10)',
						    'priority_packet_bulkmailer' => 'smallint(10)',
						    'reception_date_bulkmailer' => 'int(11)',
						    'delivery_date_bulkmailer' => 'int(11)',
						    'lock_bulkmailer' => 'varchar(30)'},
			     'bulkspool_table' => {'messagekey_bulkspool' => 'varchar(33)',
						   'messageid_bulkspool' => 'varchar(100)',
						   'message_bulkspool' => 'longtext',
						   'lock_bulkspool' => 'int(1)',
						   'dkim_privatekey_bulkspool' => 'varchar(1000)',
						   'dkim_selector_bulkspool' => 'varchar(50)',
						   'dkim_d_bulkspool' => 'varchar(50)',
						   'dkim_i_bulkspool' => 'varchar(100)',
						   'dkim_header_list_bulkspool' => 'varchar(500)',
					       },
			     'notification_table' => {'pk_notification' => 'int(11)',
						      'message_id_notification' => 'varchar(100)',
						      'recipient_notification' => 'varchar(100)',
						      'reception_option_notification' => 'varchar(20)',
						      'status_notification' => 'varchar(100)',
						      'arrival_date_notification' => 'varchar(80)',
						      'type_notification' => "enum('DSN', 'MDN')",
						      'message_notification' => 'longtext',
						      'list_notification' => 'varchar(50)',
						      'robot_notification' => 'varchar(80)',
						      'date_notification' => 'int(11)',

			     },
			     'stat_table' => {'id_stat' => 'bigint(20)',
					      'date_stat' => 'int(11)',
					      'email_stat' => 'varchar(100)',
					      'operation_stat' => 'varchar(50)',
					      'list_stat' => 'varchar(150)',
					      'daemon_stat' => 'varchar(10)',
					      'user_ip_stat' => 'varchar(100)',
					      'robot_stat' => 'varchar(80)',
					      'parameter_stat' => 'varchar(50)',
					      'read_stat' => 'tinyint(1)',
					  },
			     'conf_table' => {'robot_conf' => 'varchar(80)',
					      'label_conf' => 'varchar(80)',
					      'value_conf' => 'varchar(300)'}
			 },
		 );

&multi_db;

sub multi_db {
    foreach my $table ( keys %{ $db_struct{'mysql'} } ) {		
	foreach my $field  ( keys %{ $db_struct{'mysql'}{$table}  }) {
	    my $trans = $db_struct{'mysql'}{$table}{$field};
	    my $trans_o = $trans;
	    my $trans_pg = $trans;
	    my $trans_syb = $trans;
	    my $trans_sq = $trans;
# Oracle	
	    $trans_o =~ s/^varchar/varchar2/g;	
	    $trans_o =~ s/^int.*/number/g;	
	    $trans_o =~ s/^bigint.*/number/g;	
	    $trans_o =~ s/^smallint.*/number/g;	
	    $trans_o =~ s/^enum.*/varchar2(20)/g;	
	    $trans_o =~ s/^text.*/varchar2(500)/g;	
	    $trans_o =~ s/^longtext.*/long/g;	
	    $trans_o =~ s/^datetime.*/date/g;	
#Postgresql
	    $trans_pg =~ s/^int(1)/smallint/g;
	    $trans_pg =~ s/^int\(.*/int4/g;
	    $trans_pg =~ s/^bigint.*/bigint/g;
	    $trans_pg =~ s/^smallint.*/int4/g;
	    $trans_pg =~ s/^enum.*/varchar(15)/g;
	    $trans_pg =~ s/^text.*/varchar(500)/g;
	    $trans_pg =~ s/^longtext.*/text/g;
	    $trans_pg =~ s/^datetime.*/timestamp with time zone/g;
#Sybase		
	    $trans_syb =~ s/^int.*/numeric/g;
	    $trans_syb =~ s/^text.*/varchar(500)/g;
	    $trans_syb =~ s/^smallint.*/numeric/g;
	    $trans_syb =~ s/^bigint.*/numeric/g;
	    $trans_syb =~ s/^longtext.*/text/g;
	    $trans_syb =~ s/^enum.*/varchar(15)/g;
#Sqlite		
	    $trans_sq =~ s/^varchar.*/text/g;
	    $trans_sq =~ s/^int\(1\).*/boolean/g;
	    $trans_sq =~ s/^int.*/integer/g;
	    $trans_sq =~ s/^bigint.*/integer/g;
	    $trans_sq =~ s/^smallint.*/integer/g;
	    $trans_sq =~ s/^datetime.*/timestamp/g;
	    $trans_sq =~ s/^enum.*/text/g;	 

	    $db_struct{'pg'}{$table}{$field} = $trans_pg;
	    $db_struct{'Oracle'}{$table}{$field} = $trans_o;
	    $db_struct{'Sybase'}{$table}{$field} = $trans_syb;
	    $db_struct{'SQLite'}{$table}{$field} = $trans_sq;
	}
    }	
}



my %not_null = ('email_user' => 1,
		'list_subscriber' => 1,
		'robot_subscriber' => 1,
		'user_subscriber' => 1,
		'date_subscriber' => 1,
		'number_messages_subscriber' => 1,
		'list_admin' => 1,
		'robot_admin' => 1,
		'user_admin' => 1,
		'role_admin' => 1,
		'date_admin' => 1,
		'list_exclusion' => 1,
		'user_exclusion' => 1,
		'netid_netidmap' => 1,
		'serviceid_netidmap' => 1,
		'robot_netidmap' => 1,
		'id_logs' => 1,
		'date_logs' => 1,
		'action_logs' => 1,
		'status_logs' => 1,
		'daemon_logs' => 1,
		'id_session' => 1,
		'start_date_session' => 1,
		'date_session' => 1,
		'messagekey_bulkmailer' => 1,
		'packetid_bulkmailer' => 1,
		'messagekey_bulkspool' => 1,
		'id_stat' => 1,
		'date_stat' => 1,
		'operation_stat' => 1,
		'robot_stat' => 1,
		'read_stat' => 1,
	);

my %primary = ('user_table' => ['email_user'],
	       'subscriber_table' => ['robot_subscriber','list_subscriber','user_subscriber'],
	       'admin_table' => ['robot_admin','list_admin','role_admin','user_admin'],
	       'exclusion_table' => ['list_exclusion','user_exclusion'],
	       'netidmap_table' => ['netid_netidmap','serviceid_netidmap','robot_netidmap'],
	       'logs_table' => ['id_logs'],
	       'session_table' => ['id_session'],
	       'one_time_ticket_table' => ['ticket_one_time_ticket'],
	       'bulkmailer_table' => ['messagekey_bulkmailer','packetid_bulkmailer'],
	       'bulkspool_table' => ['messagekey_bulkspool'],
	       'conf_table' => ['robot_conf','label_conf'],
	       'stat_table' => ['id_stat'],
	       'notification_table' => ['pk_notification']
	       );
	       
my %autoincrement = ('notification_table' => 'pk_notification');

## List the required INDEXES
##   1st key is the concerned table
##   2nd key is the index name
##   the table lists the field on which the index applies
my %indexes = ('admin_table' => {'user_index' => ['user_admin']},
	       'subscriber_table' => {'user_index' => ['user_subscriber']},
	       'stat_table' => {'user_index' => ['email_stat']}
	       );

# table indexes that can be removed during upgrade process
my @former_indexes = ('user_subscriber', 'list_subscriber', 'subscriber_idx', 'admin_idx', 'netidmap_idx', 'user_admin', 'list_admin', 'role_admin', 'admin_table_index', 'logs_table_index','netidmap_table_index','subscriber_table_index');


## Return the previous Sympa version, ie the one listed in data_structure.version
sub get_previous_version {
    my $version_file = "$Conf::Conf{'etc'}/data_structure.version";
    my $previous_version;
    
    if (-f $version_file) {
	unless (open VFILE, $version_file) {
	    do_log('err', "Unable to open %s : %s", $version_file, $!);
	    return undef;
	}
	while (<VFILE>) {
	    next if /^\s*$/;
	    next if /^\s*\#/;
	    chomp;
	    $previous_version = $_;
	    last;
	}
	close VFILE;
	
	return $previous_version;
    }
    
    return undef;
}

sub update_version {
    my $version_file = "$Conf::Conf{'etc'}/data_structure.version";

    ## Saving current version if required
    unless (open VFILE, ">$version_file") {
	do_log('err', "Unable to write %s ; sympa.pl needs write access on %s directory : %s", $version_file, $Conf::Conf{'etc'}, $!);
	return undef;
    }
    printf VFILE "# This file is automatically created by sympa.pl after installation\n# Unless you know what you are doing, you should not modify it\n";
    printf VFILE "%s\n", Sympa::Constants::VERSION;
    close VFILE;
    
    return 1;
}


## Upgrade data structure from one version to another
sub upgrade {
    my ($previous_version, $new_version) = @_;

    &do_log('notice', 'Upgrade::upgrade(%s, %s)', $previous_version, $new_version);
    
    unless (&List::check_db_connect()) {
	return undef;
    }

    my $dbh = &List::db_get_handler();

    if (&tools::lower_version($new_version, $previous_version)) {
	&do_log('notice', 'Installing  older version of Sympa ; no upgrade operation is required');
	return 1;
    }

    ## Always update config.bin files while upgrading
    ## This is especially useful for character encoding reasons
    &do_log('notice','Rebuilding config.bin files for ALL lists...it may take a while...');
    my $all_lists = &List::get_lists('*',{'reload_config' => 1});

    ## Empty the admin_table entries and recreate them
    &do_log('notice','Rebuilding the admin_table...');
    &List::delete_all_list_admin();
    foreach my $list (@$all_lists) {
	$list->sync_include_admin();
    }

    ## Migration to tt2
    if (&tools::lower_version($previous_version, '4.2b')) {

	&do_log('notice','Migrating templates to TT2 format...');	
	
    my $tpl_script = Sympa::Constants::SCRIPTDIR . '/tpl2tt2.pl';
	unless (open EXEC, "$tpl_script|") {
	    &do_log('err', "Unable to run $tpl_script");
	    return undef;
	}
	close EXEC;
	
	&do_log('notice','Rebuilding web archives...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    next unless (defined $list->{'admin'}{'web_archive'});
	    my $file = $Conf::Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();
	    
	    unless (open REBUILD, ">$file") {
		&do_log('err','Cannot create %s', $file);
		next;
	    }
	    print REBUILD ' ';
	    close REBUILD;
	}	
    }
    
    ## Initializing the new admin_table
    if (&tools::lower_version($previous_version, '4.2b.4')) {
	&do_log('notice','Initializing the new admin_table...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    $list->sync_include_admin();
	}
    }

    ## Move old-style web templates out of the include_path
    if (&tools::lower_version($previous_version, '5.0.1')) {
	&do_log('notice','Old web templates HTML structure is not compliant with latest ones.');
	&do_log('notice','Moving old-style web templates out of the include_path...');

	my @directories;

	if (-d "$Conf::Conf{'etc'}/web_tt2") {
	    push @directories, "$Conf::Conf{'etc'}/web_tt2";
	}

	## Go through Virtual Robots
	foreach my $vr (keys %{$Conf::Conf{'robots'}}) {

	    if (-d "$Conf::Conf{'etc'}/$vr/web_tt2") {
		push @directories, "$Conf::Conf{'etc'}/$vr/web_tt2";
	    }
	}

	## Search in V. Robot Lists
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    if (-d "$list->{'dir'}/web_tt2") {
		push @directories, "$list->{'dir'}/web_tt2";
	    }	    
	}

	my @templates;

	foreach my $d (@directories) {
	    unless (opendir DIR, $d) {
		printf STDERR "Error: Cannot read %s directory : %s", $d, $!;
		next;
	    }
	    
	    foreach my $tt2 (sort grep(/\.tt2$/,readdir DIR)) {
		push @templates, "$d/$tt2";
	    }
	    
	    closedir DIR;
	}

	foreach my $tpl (@templates) {
	    unless (rename $tpl, "$tpl.oldtemplate") {
		printf STDERR "Error : failed to rename $tpl to $tpl.oldtemplate : $!\n";
		next;
	    }

	    &do_log('notice','File %s renamed %s', $tpl, "$tpl.oldtemplate");
	}
    }


    ## Clean buggy list config files
    if (&tools::lower_version($previous_version, '5.1b')) {
	&do_log('notice','Cleaning buggy list config files...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    $list->save_config('listmaster@'.$list->{'domain'});
	}
    }

    ## Fix a bug in Sympa 5.1
    if (&tools::lower_version($previous_version, '5.1.2')) {
	&do_log('notice','Rename archives/log. files...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    my $l = $list->{'name'}; 
	    if (-f $list->{'dir'}.'/archives/log.') {
		rename $list->{'dir'}.'/archives/log.', $list->{'dir'}.'/archives/log.00';
	    }
	}
    }

    if (&tools::lower_version($previous_version, '5.2a.1')) {

	## Fill the robot_subscriber and robot_admin fields in DB
	&do_log('notice','Updating the new robot_subscriber and robot_admin  Db fields...');

	unless ($List::use_db) {
	    &do_log('info', 'Sympa not setup to use DBI');
	    return undef;
	}

	foreach my $r (keys %{$Conf::Conf{'robots'}}) {
	    my $all_lists = &List::get_lists($r, {'skip_sync_admin' => 1});
	    foreach my $list ( @$all_lists ) {
		
		foreach my $table ('subscriber','admin') {
		    my $statement = sprintf "UPDATE %s_table SET robot_%s=%s WHERE (list_%s=%s)",
		    $table,
		    $table,
		    $dbh->quote($r),
		    $table,
		    $dbh->quote($list->{'name'});

		    unless ($dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', 
			       $statement, $dbh->errstr);
			&List::send_notify_to_listmaster('upgrade_failed', $Conf::Conf{'domain'},{'error' => $dbh->errstr});
			return undef;
		    }
		}
		
		## Force Sync_admin
		$list = new List ($list->{'name'}, $list->{'domain'}, {'force_sync_admin' => 1});
	    }
	}

	## Rename web archive directories using 'domain' instead of 'host'
	&do_log('notice','Renaming web archive directories with the list domain...');
	
	my $root_dir = &Conf::get_robot_conf($Conf::Conf{'domain'},'arc_path');
	unless (opendir ARCDIR, $root_dir) {
	    do_log('err',"Unable to open $root_dir : $!");
	    return undef;
	}
	
	foreach my $dir (sort readdir(ARCDIR)) {
	    next if (($dir =~ /^\./o) || (! -d $root_dir.'/'.$dir)); ## Skip files and entries starting with '.'
		     
	    my ($listname, $listdomain) = split /\@/, $dir;

	    next unless ($listname && $listdomain);

	    my $list = new List $listname;
	    unless (defined $list) {
		do_log('notice',"Skipping unknown list $listname");
		next;
	    }
	    
	    if ($listdomain ne $list->{'domain'}) {
		my $old_path = $root_dir.'/'.$listname.'@'.$listdomain;		
		my $new_path = $root_dir.'/'.$listname.'@'.$list->{'domain'};

		if (-d $new_path) {
		    do_log('err',"Could not rename %s to %s ; directory already exists", $old_path, $new_path);
		    next;
		}else {
		    unless (rename $old_path, $new_path) {
			do_log('err',"Failed to rename %s to %s : %s", $old_path, $new_path, $!);
			next;
		    }
		    &do_log('notice', "Renamed %s to %s", $old_path, $new_path);
		}
	    }		     
	}
	close ARCDIR;
	
    }

    ## DB fields of enum type have been changed to int
    if (&tools::lower_version($previous_version, '5.2a.1')) {
	
	if ($List::use_db && $Conf::Conf{'db_type'} eq 'mysql') {
	    my %check = ('subscribed_subscriber' => 'subscriber_table',
			 'included_subscriber' => 'subscriber_table',
			 'subscribed_admin' => 'admin_table',
			 'included_admin' => 'admin_table');
	    
	    foreach my $field (keys %check) {

		my $statement;
				
		## Query the Database
		$statement = sprintf "SELECT max(%s) FROM %s", $field, $check{$field};
		
		my $sth;
		
		unless ($sth = $dbh->prepare($statement)) {
		    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
		    return undef;
		}
		
		unless ($sth->execute) {
		    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		    return undef;
		}
		
		my $max = $sth->fetchrow();
		$sth->finish();		

		## '0' has been mapped to 1 and '1' to 2
		## Restore correct field value
		if ($max > 1) {
		    ## 1 to 0
		    &do_log('notice', 'Fixing DB field %s ; turning 1 to 0...', $field);
		    
		    my $statement = sprintf "UPDATE %s SET %s=%d WHERE (%s=%d)", $check{$field}, $field, 0, $field, 1;
		    my $rows;
		    unless ($rows = $dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		    
		    &do_log('notice', 'Updated %d rows', $rows);

		    ## 2 to 1
		    &do_log('notice', 'Fixing DB field %s ; turning 2 to 1...', $field);
		    
		    $statement = sprintf "UPDATE %s SET %s=%d WHERE (%s=%d)", $check{$field}, $field, 1, $field, 2;

		    unless ($rows = $dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		    
		    &do_log('notice', 'Updated %d rows', $rows);		    

		}

		## Set 'subscribed' data field to '1' is none of 'subscribed' and 'included' is set		
		$statement = "UPDATE subscriber_table SET subscribed_subscriber=1 WHERE ((included_subscriber IS NULL OR included_subscriber!=1) AND (subscribed_subscriber IS NULL OR subscribed_subscriber!=1))";
		
		&do_log('notice','Updating subscribed field of the subscriber table...');
		my $rows = $dbh->do($statement);
		unless (defined $rows) {
		    &fatal_err("Unable to execute SQL statement %s : %s", $statement, $dbh->errstr);	    
		}
		&do_log('notice','%d rows have been updated', $rows);
				
	    }
	}
    }

    ## Rename bounce sub-directories
    if (&tools::lower_version($previous_version, '5.2a.1')) {

	&do_log('notice','Renaming bounce sub-directories adding list domain...');
	
	my $root_dir = &Conf::get_robot_conf($Conf::Conf{'domain'},'bounce_path');
	unless (opendir BOUNCEDIR, $root_dir) {
	    do_log('err',"Unable to open $root_dir : $!");
	    return undef;
	}
	
	foreach my $dir (sort readdir(BOUNCEDIR)) {
	    next if (($dir =~ /^\./o) || (! -d $root_dir.'/'.$dir)); ## Skip files and entries starting with '.'
		     
	    next if ($dir =~ /\@/); ## Directory already include the list domain

	    my $listname = $dir;
	    my $list = new List $listname;
	    unless (defined $list) {
		do_log('notice',"Skipping unknown list $listname");
		next;
	    }
	    
	    my $old_path = $root_dir.'/'.$listname;		
	    my $new_path = $root_dir.'/'.$listname.'@'.$list->{'domain'};
	    
	    if (-d $new_path) {
		do_log('err',"Could not rename %s to %s ; directory already exists", $old_path, $new_path);
		next;
	    }else {
		unless (rename $old_path, $new_path) {
		    do_log('err',"Failed to rename %s to %s : %s", $old_path, $new_path, $!);
		    next;
		}
		&do_log('notice', "Renamed %s to %s", $old_path, $new_path);
	    }
	}
	close BOUNCEDIR;
    }

    ## Update lists config using 'include_list'
    if (&tools::lower_version($previous_version, '5.2a.1')) {
	
	&do_log('notice','Update lists config using include_list parameter...');

	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    if (defined $list->{'admin'}{'include_list'}) {
	    
		foreach my $index (0..$#{$list->{'admin'}{'include_list'}}) {
		    my $incl = $list->{'admin'}{'include_list'}[$index];
		    my $incl_list = new List ($incl);
		    
		    if (defined $incl_list &&
			$incl_list->{'domain'} ne $list->{'domain'}) {
			&do_log('notice','Update config file of list %s, including list %s', $list->get_list_id(), $incl_list->get_list_id());
			
			$list->{'admin'}{'include_list'}[$index] = $incl_list->get_list_id();

			$list->save_config('listmaster@'.$list->{'domain'});
		    }
		}
	    }
	}	
    }

    ## New mhonarc ressource file with utf-8 recoding
    if (&tools::lower_version($previous_version, '5.3a.6')) {
	
	&do_log('notice','Looking for customized mhonarc-ressources.tt2 files...');
	foreach my $vr (keys %{$Conf::Conf{'robots'}}) {
	    my $etc_dir = $Conf::Conf{'etc'};

	    if ($vr ne $Conf::Conf{'domain'}) {
		$etc_dir .= '/'.$vr;
	    }

	    if (-f $etc_dir.'/mhonarc-ressources.tt2') {
		my $new_filename = $etc_dir.'/mhonarc-ressources.tt2'.'.'.time;
		rename $etc_dir.'/mhonarc-ressources.tt2', $new_filename;
		&do_log('notice', "Custom %s file has been backed up as %s", $etc_dir.'/mhonarc-ressources.tt2', $new_filename);
		&List::send_notify_to_listmaster('file_removed',$Conf::Conf{'domain'},
						 [$etc_dir.'/mhonarc-ressources.tt2', $new_filename]);
	    }
	}


	&do_log('notice','Rebuilding web archives...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    next unless (defined $list->{'admin'}{'web_archive'});
	    my $file = $Conf::Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();
	    
	    unless (open REBUILD, ">$file") {
		&do_log('err','Cannot create %s', $file);
		next;
	    }
	    print REBUILD ' ';
	    close REBUILD;
	}	

    }

    ## Changed shared documents name encoding
    ## They are Q-encoded therefore easier to store on any filesystem with any encoding
    if (&tools::lower_version($previous_version, '5.3a.8')) {
	&do_log('notice','Q-Encoding web documents filenames...');

	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    if (-d $list->{'dir'}.'/shared') {
		&do_log('notice','  Processing list %s...', $list->get_list_address());

		## Determine default lang for this list
		## It should tell us what character encoding was used for filenames
		&Language::SetLang($list->{'admin'}{'lang'});
		my $list_encoding = &Language::GetCharset();

		my $count = &tools::qencode_hierarchy($list->{'dir'}.'/shared', $list_encoding);

		if ($count) {
		    &do_log('notice', 'List %s : %d filenames has been changed', $list->{'name'}, $count);
		}
	    }
	}

    }    

    ## We now support UTF-8 only for custom templates, config files, headers and footers, info files
    ## + web_tt2, scenari, create_list_templatee, families
    if (&tools::lower_version($previous_version, '5.3b.3')) {
	&do_log('notice','Encoding all custom files to UTF-8...');

	my (@directories, @files);

	## Site level
	foreach my $type ('mail_tt2','web_tt2','scenari','create_list_templates','families') {
	    if (-d $Conf::Conf{'etc'}.'/'.$type) {
		push @directories, [$Conf::Conf{'etc'}.'/'.$type, $Conf::Conf{'lang'}];
	    }
	}

	foreach my $f (
        Sympa::Constants::CONFIG,
        Sympa::Constants::WWSCONFIG,
        $Conf::Conf{'etc'}.'/'.'topics.conf',
        $Conf::Conf{'etc'}.'/'.'auth.conf'
    ) {
	    if (-f $f) {
		push @files, [$f, $Conf::Conf{'lang'}];
	    }
	}

	## Go through Virtual Robots
	foreach my $vr (keys %{$Conf::Conf{'robots'}}) {
	    foreach my $type ('mail_tt2','web_tt2','scenari','create_list_templates','families') {
		if (-d $Conf::Conf{'etc'}.'/'.$vr.'/'.$type) {
		    push @directories, [$Conf::Conf{'etc'}.'/'.$vr.'/'.$type, &Conf::get_robot_conf($vr, 'lang')];
		}
	    }

	    foreach my $f ('robot.conf','topics.conf','auth.conf') {
		if (-f $Conf::Conf{'etc'}.'/'.$vr.'/'.$f) {
		    push @files, [$Conf::Conf{'etc'}.'/'.$vr.'/'.$f, $Conf::Conf{'lang'}];
		}
	    }
	}

	## Search in Lists
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    foreach my $f ('config','info','homepage','message.header','message.footer') {
		if (-f $list->{'dir'}.'/'.$f){
		    push @files, [$list->{'dir'}.'/'.$f, $list->{'admin'}{'lang'}];
		}
	    }

	    foreach my $type ('mail_tt2','web_tt2','scenari') {
		my $directory = $list->{'dir'}.'/'.$type;
		if (-d $directory) {
		    push @directories, [$directory, $list->{'admin'}{'lang'}];
		}	    
	    }
	}

	## Search language directories
	foreach my $pair (@directories) {
	    my ($d, $lang) = @$pair;
	    unless (opendir DIR, $d) {
		next;
	    }

	    if ($d =~ /(mail_tt2|web_tt2)$/) {
		foreach my $subdir (grep(/^[a-z]{2}(_[A-Z]{2})?$/, readdir DIR)) {
		    if (-d "$d/$subdir") {
			push @directories, ["$d/$subdir", $subdir];
		    }
		}
		closedir DIR;

	    }elsif ($d =~ /(create_list_templates|families)$/) {
		foreach my $subdir (grep(/^\w+$/, readdir DIR)) {
		    if (-d "$d/$subdir") {
			push @directories, ["$d/$subdir", $Conf::Conf{'lang'}];
		    }
		}
		closedir DIR;
	    }
	}

	foreach my $pair (@directories) {
	    my ($d, $lang) = @$pair;
	    unless (opendir DIR, $d) {
		next;
	    }
	    foreach my $file (readdir DIR) {
		next unless (($d =~ /mail_tt2|web_tt2|create_list_templates|families/ && $file =~ /\.tt2$/) ||
			     ($d =~ /scenari$/ && $file =~ /\w+\.\w+$/));
		push @files, [$d.'/'.$file, $lang];
	    }
	    closedir DIR;
	}

	## Do the encoding modifications
	## Previous versions of files are backed up with the date extension
	my $total = &to_utf8(\@files);
	&do_log('notice','%d files have been modified', $total);
    }

    ## giving up subscribers flat files ; moving subscribers to the DB
    ## Also giving up old 'database' mode
    if (&tools::lower_version($previous_version, '5.4a.1')) {
	
	&do_log('notice','Looking for lists with user_data_source parameter set to file or database...');

	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    if ($list->{'admin'}{'user_data_source'} eq 'file') {

		&do_log('notice','List %s ; changing user_data_source from file to include2...', $list->{'name'});
		
		my @users = &List::_load_list_members_file("$list->{'dir'}/subscribers");
		
		$list->{'admin'}{'user_data_source'} = 'include2';
		$list->{'total'} = 0;
		
		## Add users to the DB
		my $total = $list->add_list_member(@users);
		unless (defined $total) {
		    &do_log('err', 'Failed to add users');
		    next;
		}
		
		&do_log('notice','%d subscribers have been loaded into the database', $total);
		
		unless ($list->save_config('automatic')) {
		    &do_log('err', 'Failed to save config file for list %s', $list->{'name'});
		}
	    }elsif ($list->{'admin'}{'user_data_source'} eq 'database') {

		&do_log('notice','List %s ; changing user_data_source from database to include2...', $list->{'name'});

		unless ($list->update_list_member('*', {'subscribed' => 1})) {
		    &do_log('err', 'Failed to update subscribed DB field');
		}

		$list->{'admin'}{'user_data_source'} = 'include2';

		unless ($list->save_config('automatic')) {
		    &do_log('err', 'Failed to save config file for list %s', $list->{'name'});
		}
	    }
	}
    }
    
    if (&tools::lower_version($previous_version, '5.5a.1')) {

      ## Remove OTHER/ subdirectories in bounces
      &do_log('notice', "Removing obsolete OTHER/ bounce directories");
      if (opendir BOUNCEDIR, &Conf::get_robot_conf($Conf::Conf{'domain'}, 'bounce_path')) {
	
	foreach my $subdir (sort grep (!/^\.+$/,readdir(BOUNCEDIR))) {
	  my $other_dir = &Conf::get_robot_conf($Conf::Conf{'domain'}, 'bounce_path').'/'.$subdir.'/OTHER';
	  if (-d $other_dir) {
	    &tools::remove_dir($other_dir) && &do_log('notice', "Directory $other_dir removed");
	  }
	}
	
	close BOUNCEDIR;
 
      }else {
	&do_log('err', "Failed to open directory $Conf::Conf{'queuebounce'} : $!");	
      }

   }

   if (&tools::lower_version($previous_version, '6.1b.5')) {
		## Encoding of shared documents was not consistent with recent versions of MIME::Encode
		## MIME::EncWords::encode_mimewords() used to encode characters -!*+/ 
		## Now these characters are preserved, according to RFC 2047 section 5 
		## We change encoding of shared documents according to new algorithm
		&do_log('notice','Fixing Q-encoding of web document filenames...');
		my $all_lists = &List::get_lists('*');
		foreach my $list ( @$all_lists ) {
			if (-d $list->{'dir'}.'/shared') {
				&do_log('notice','  Processing list %s...', $list->get_list_address());

				my @all_files;
				&tools::list_dir($list->{'dir'}, \@all_files, 'utf-8');
				
				my $count;
				foreach my $f_struct (reverse @all_files) {
					my $new_filename = $f_struct->{'filename'};
					
					## Decode and re-encode filename
					$new_filename = &tools::qencode_filename(&tools::qdecode_filename($new_filename));
					
					if ($new_filename ne $f_struct->{'filename'}) {
						## Rename file
						my $orig_f = $f_struct->{'directory'}.'/'.$f_struct->{'filename'};
						my $new_f = $f_struct->{'directory'}.'/'.$new_filename;
						&do_log('notice', "Renaming %s to %s", $orig_f, $new_f);
						unless (rename $orig_f, $new_f) {
							&do_log('err', "Failed to rename %s to %s : %s", $orig_f, $new_f, $!);
							next;
						}
						$count++;
					}
				}
				if ($count) {
				&do_log('notice', 'List %s : %d filenames has been changed', $list->{'name'}, $count);
				}
			}
		}
		
   }	

    return 1;
}

sub probe_db {
    &do_log('debug3', 'List::probe_db()');    
    my (%checked, $table);
    
    ## Database structure
    ## Report changes to listmaster
    my @report;

    ## Is the Database defined
    unless ($Conf::Conf{'db_name'}) {
	&do_log('err', 'No db_name defined in configuration file');
	return undef;
    }
    
    unless (&List::check_db_connect()) {
	unless (&SQLSource::create_db()) {
	    return undef;
	}
	
	if ($ENV{'HTTP_HOST'}) { ## Web context
	    return undef unless &List::db_connect('just_try');
	}else {
	    return undef unless &List::db_connect();
	}
    }
    
    my $dbh = &List::db_get_handler();
    
    my (@tables, $fields, %real_struct);
    if ($Conf::Conf{'db_type'} eq 'mysql') {
	
	## Get tables
	@tables = $dbh->tables();
	
	foreach my $t (@tables) {
	    $t =~ s/^\`[^\`]+\`\.//;## Clean table names that would look like `databaseName`.`tableName` (mysql)
	    $t =~ s/^\`(.+)\`$/$1/;## Clean table names that could be surrounded by `` (recent DBD::mysql release)
	}
	
	unless (defined $#tables) {
	    &do_log('info', 'Can\'t load tables list from database %s : %s', $Conf::Conf{'db_name'}, $dbh->errstr);
	    return undef;
	}
	
	## Check required tables
	foreach my $t1 (keys %{$db_struct{'mysql'}}) {
	    my $found;
	    foreach my $t2 (@tables) {
		$found = 1 if ($t1 eq $t2);
	    }
	    unless ($found) {
		unless ($dbh->do("CREATE TABLE $t1 (temporary INT)")) {
		    &do_log('err', 'Could not create table %s in database %s : %s', $t1, $Conf::Conf{'db_name'}, $dbh->errstr);
		    next;
		}
		
		push @report, sprintf('Table %s created in database %s', $t1, $Conf::Conf{'db_name'});
		&do_log('notice', 'Table %s created in database %s', $t1, $Conf::Conf{'db_name'});
		push @tables, $t1;
		$real_struct{$t1} = {};
	    }
	}
	
	## Get fields
	foreach my $t (@tables) {
	    my $sth;
	    
	    #	    unless ($sth = $dbh->table_info) {
	    #	    unless ($sth = $dbh->prepare("LISTFIELDS $t")) {
	    my $sql_query = "SHOW FIELDS FROM $t";
	    unless ($sth = $dbh->prepare($sql_query)) {
		do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
		return undef;
	    }
	    
	    unless ($sth->execute) {
		do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
		return undef;
	    }
	    
	    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
		$real_struct{$t}{$ref->{'field'}} = $ref->{'type'};
	    }
	    
	    $sth->finish();
	}
	
    }elsif ($Conf::Conf{'db_type'} eq 'Pg') {
	
	unless (@tables = $dbh->tables) {
	    &do_log('err', 'Can\'t load tables list from database %s', $Conf::Conf{'db_name'});
	    return undef;
	}
    }elsif ($Conf::Conf{'db_type'} eq 'SQLite') {
 	
 	unless (@tables = $dbh->tables) {
 	    &do_log('err', 'Can\'t load tables list from database %s', $Conf::Conf{'db_name'});
 	    return undef;
 	}
	
 	foreach my $t (@tables) {
	    $t =~ s/^"main"\.//; # needed for SQLite 3
	    $t =~ s/^.*\"([^"]+)\"$/$1/;
 	}
	
	foreach my $t (@tables) {
	    next unless (defined $db_struct{$Conf::Conf{'db_type'}}{$t});
	    
	    my $res = $dbh->selectall_arrayref("PRAGMA table_info($t)");
	    unless (defined $res) {
		&do_log('err','Failed to check DB tables structure : %s', $dbh->errstr);
		next;
	    }
	    foreach my $field (@$res) {
		# http://www.sqlite.org/datatype3.html
		if($field->[2] =~ /int/) {
		    $field->[2]="integer";
		} elsif ($field->[2] =~ /char|clob|text/) {
		    $field->[2]="text";
		} elsif ($field->[2] =~ /blob/) {
		    $field->[2]="none";
		} elsif ($field->[2] =~ /real|floa|doub/) {
		    $field->[2]="real";
		} else {
		    $field->[2]="numeric";
		}
		$real_struct{$t}{$field->[1]} = $field->[2];
	    }
	}
	
	# Une simple requête sqlite : PRAGMA table_info('nomtable') , retourne la liste des champs de la table en question.
	# La liste retournée est composée d'un N°Ordre, Nom du champ, Type (longueur), Null ou not null (99 ou 0),Valeur par défaut,Clé primaire (1 ou 0)
	
    }elsif ($Conf::Conf{'db_type'} eq 'Oracle') {
 	
 	my $statement = "SELECT table_name FROM user_tables";	 
	
	my $sth;
	
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	    return undef;
     	}
	
       	unless ($sth->execute) {
	    &do_log('err','Can\'t load tables list from database and Unable to perform SQL query %s : %s ',$statement, $dbh->errstr);
	    return undef;
     	}
	
	## Process the SQL results
     	while (my $table= $sth->fetchrow()) {
	    push @tables, lc ($table);   	
	}
	
     	$sth->finish();
	
    }elsif ($Conf::Conf{'db_type'} eq 'Sybase') {
	
	my $statement = sprintf "SELECT name FROM %s..sysobjects WHERE type='U'",$Conf::Conf{'db_name'};
#	my $statement = "SELECT name FROM sympa..sysobjects WHERE type='U'";     
	
	my $sth;
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	    return undef;
	}
	unless ($sth->execute) {
	    &do_log('err','Can\'t load tables list from database and Unable to perform SQL query %s : %s ',$statement, $dbh->errstr);
	    return undef;
	}
	
	## Process the SQL results
	while (my $table= $sth->fetchrow()) {
	    push @tables, lc ($table);   
	}
	
	$sth->finish();
    }
    
    foreach $table ( @tables ) {
	$checked{$table} = 1;
    }
    
    my $found_tables = 0;
    foreach $table('user_table', 'subscriber_table', 'admin_table') {
	if ($checked{$table} || $checked{'public.' . $table}) {
	    $found_tables++;
	}else {
	    &do_log('err', 'Table %s not found in database %s', $table, $Conf::Conf{'db_name'});
	}
    }
    
    ## Check tables structure if we could get it
    ## Only performed with mysql and SQLite
    if (%real_struct) {
	foreach my $t (keys %{$db_struct{$Conf::Conf{'db_type'}}}) {
	    unless ($real_struct{$t}) {
		&do_log('err', 'Table \'%s\' not found in database \'%s\' ; you should create it with create_db.%s script', $t, $Conf::Conf{'db_name'}, $Conf::Conf{'db_type'});
		return undef;
	    }
	    
	    my %added_fields;
	    
	    foreach my $f (sort keys %{$db_struct{$Conf::Conf{'db_type'}}{$t}}) {
		unless ($real_struct{$t}{$f}) {
		    push @report, sprintf('Field \'%s\' (table \'%s\' ; database \'%s\') was NOT found. Attempting to add it...', $f, $t, $Conf::Conf{'db_name'});
		    &do_log('info', 'Field \'%s\' (table \'%s\' ; database \'%s\') was NOT found. Attempting to add it...', $f, $t, $Conf::Conf{'db_name'});
		    
		    my $options;
		    ## To prevent "Cannot add a NOT NULL column with default value NULL" errors
		    if ($not_null{$f}) {
			$options .= 'NOT NULL';
		    }
		    if ( $autoincrement{$t} eq $f) {
					$options .= ' AUTO_INCREMENT PRIMARY KEY ';
			}
		    unless ($dbh->do("ALTER TABLE $t ADD $f $db_struct{$Conf::Conf{'db_type'}}{$t}{$f} $options")) {
			    &do_log('err', 'Could not add field \'%s\' to table\'%s\'.', $f, $t);
			    &do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			    return undef;
		    }
		    
		    push @report, sprintf('Field %s added to table %s (options : %s)', $f, $t, $options);
		    &do_log('info', 'Field %s added to table %s  (options : %s)', $f, $t, $options);
		    $added_fields{$f} = 1;
		    
		    ## Remove temporary DB field
		    if ($real_struct{$t}{'temporary'}) {
			unless ($dbh->do("ALTER TABLE $t DROP temporary")) {
			    &do_log('err', 'Could not drop temporary table field : %s', $dbh->errstr);
			}
			delete $real_struct{$t}{'temporary'};
		    }
		    
		    next;
		}
		
		## Change DB types if different and if update_db_types enabled
		if ($Conf::Conf{'update_db_field_types'} eq 'auto') {
		    unless (&check_db_field_type(effective_format => $real_struct{$t}{$f},
						 required_format => $db_struct{$Conf::Conf{'db_type'}}{$t}{$f})) {
			push @report, sprintf('Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s). Attempting to change it...', 
					      $f, $t, $Conf::Conf{'db_name'}, $db_struct{$Conf::Conf{'db_type'}}{$t}{$f});
			&do_log('notice', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s). Attempting to change it...', 
				$f, $t, $Conf::Conf{'db_name'}, $db_struct{$Conf::Conf{'db_type'}}{$t}{$f});
			
			my $options;
			if ($not_null{$f}) {
			    $options .= 'NOT NULL';
			}
			
			push @report, sprintf("ALTER TABLE $t CHANGE $f $f $db_struct{$Conf::Conf{'db_type'}}{$t}{$f} $options");
			&do_log('notice', "ALTER TABLE $t CHANGE $f $f $db_struct{$Conf::Conf{'db_type'}}{$t}{$f} $options");
			unless ($dbh->do("ALTER TABLE $t CHANGE $f $f $db_struct{$Conf::Conf{'db_type'}}{$t}{$f} $options")) {
			    &do_log('err', 'Could not change field \'%s\' in table\'%s\'.', $f, $t);
			    &do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			    return undef;
			}
			
			push @report, sprintf('Field %s in table %s, structure updated', $f, $t);
			&do_log('info', 'Field %s in table %s, structure updated', $f, $t);
		    }
		}else {
		    unless ($real_struct{$t}{$f} eq $db_struct{$Conf::Conf{'db_type'}}{$t}{$f}) {
			&do_log('err', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s).', $f, $t, $Conf::Conf{'db_name'}, $db_struct{$Conf::Conf{'db_type'}}{$t}{$f});
			&do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			return undef;
		    }
		}
	    }
	    if ($Conf::Conf{'db_type'} eq 'mysql') {
		## Check that primary key has the right structure.
		my $should_update;
		my $test_request_result = $dbh->selectall_hashref('SHOW COLUMNS FROM '.$t,'key');
		my %primaryKeyFound;
		foreach my $scannedResult ( keys %$test_request_result ) {
		    if ( $scannedResult eq "PRI" ) {
			$primaryKeyFound{$scannedResult} = 1;
		    }
		}
		foreach my $field (@{$primary{$t}}) {		
		    unless ($primaryKeyFound{$field}) {
			$should_update = 1;
			last;
		    }
		}
		
		## Create required PRIMARY KEY. Removes useless INDEX.
		foreach my $field (@{$primary{$t}}) {		
		    if ($added_fields{$field}) {
			$should_update = 1;
			last;
		    }
		}
		
		if ($should_update) {
		    my $fields = join ',',@{$primary{$t}};
		    my %definedPrimaryKey;
		    foreach my $definedKeyPart (@{$primary{$t}}) {
			$definedPrimaryKey{$definedKeyPart} = 1;
		    }
		    my $searchedKeys = ['field','key'];
		    my $test_request_result = $dbh->selectall_hashref('SHOW COLUMNS FROM '.$t,$searchedKeys);
		    my $expectedKeyMissing = 0;
		    my $unExpectedKey = 0;
		    my $primaryKeyFound = 0;
		    my $primaryKeyDropped = 0;
		    foreach my $scannedResult ( keys %$test_request_result ) {
			if ( $$test_request_result{$scannedResult}{"PRI"} ) {
			    $primaryKeyFound = 1;
			    if ( !$definedPrimaryKey{$scannedResult}) {
				&do_log('info','Unexpected primary key : %s',$scannedResult);
				$unExpectedKey = 1;
				next;
			    }
			}
			else {
			    if ( $definedPrimaryKey{$scannedResult}) {
				&do_log('info','Missing expected primary key : %s',$scannedResult);
				$expectedKeyMissing = 1;
				next;
			    }
			}
			
		    }
		    if( $primaryKeyFound && ( $unExpectedKey || $expectedKeyMissing ) ) {
			## drop previous primary key
			unless ($dbh->do("ALTER TABLE $t DROP PRIMARY KEY")) {
			    &do_log('err', 'Could not drop PRIMARY KEY, table\'%s\'.', $t);
			}
			push @report, sprintf('Table %s, PRIMARY KEY dropped', $t);
			&do_log('info', 'Table %s, PRIMARY KEY dropped', $t);
			$primaryKeyDropped = 1;
		    }
		    
		    ## Add primary key
		    if ( $primaryKeyDropped || !$primaryKeyFound ) {
			&do_log('debug', "ALTER TABLE $t ADD PRIMARY KEY ($fields)");
			unless ($dbh->do("ALTER TABLE $t ADD PRIMARY KEY ($fields)")) {
			    &do_log('err', 'Could not set field \'%s\' as PRIMARY KEY, table\'%s\'.', $fields, $t);
			    return undef;
			}
			push @report, sprintf('Table %s, PRIMARY KEY set on %s', $t, $fields);
			&do_log('info', 'Table %s, PRIMARY KEY set on %s', $t, $fields);
		    }
		}
		
		## drop previous index if this index is not a primary key and was defined by a previous Sympa version
		$test_request_result = $dbh->selectall_hashref('SHOW INDEX FROM '.$t,'key_name');
		my %index_columns;
		
		foreach my $indexName ( keys %$test_request_result ) {
		    unless ( $indexName eq "PRIMARY" ) {
			$index_columns{$indexName} = 1;
		    }
		}
		
		foreach my $idx ( keys %index_columns ) {
		    
		    ## Check whether the index found should be removed
		    my $index_name_is_known = 0;
		    foreach my $known_index ( @former_indexes ) {
			if ( $idx eq $known_index ) {
			    $index_name_is_known = 1;
			    last;
			}
		    }
		    ## Drop indexes
		    if( $index_name_is_known ) {
			if ($dbh->do("ALTER TABLE $t DROP INDEX $idx")) {
			    push @report, sprintf('Deprecated INDEX \'%s\' dropped in table \'%s\'', $idx, $t);
			    &do_log('info', 'Deprecated INDEX \'%s\' dropped in table \'%s\'', $idx, $t);
			}else {
			    &do_log('err', 'Could not drop deprecated INDEX \'%s\' in table \'%s\'.', $idx, $t);
			}
			
		    }
		    
		}
		
		## Create required indexes
		foreach my $idx (keys %{$indexes{$t}}){ 
		    
		    unless ($index_columns{$idx}) {
			my $columns = join ',', @{$indexes{$t}{$idx}};
			if ($dbh->do("ALTER TABLE $t ADD INDEX $idx ($columns)")) {
			    &do_log('info', 'Added INDEX \'%s\' in table \'%s\'', $idx, $t);
			}else {
			    &do_log('err', 'Could not add INDEX \'%s\' in table \'%s\'.', $idx, $t);
			}
		    }
		}	 
	    }   
	    elsif ($Conf::Conf{'db_type'} eq 'SQLite') {
		## Create required INDEX and PRIMARY KEY
		my $should_update;
		foreach my $field (@{$primary{$t}}) {
		    if ($added_fields{$field}) {
			$should_update = 1;
			last;
		    }
		}
		
		if ($should_update) {
		    my $fields = join ',',@{$primary{$t}};
		    ## drop previous index
		    my $success;
		    foreach my $field (@{$primary{$t}}) {
			unless ($dbh->do("DROP INDEX $field")) {
			    next;
			}
			$success = 1; last;
		    }
		    
		    if ($success) {
			push @report, sprintf('Table %s, INDEX dropped', $t);
			&do_log('info', 'Table %s, INDEX dropped', $t);
		    }else {
			&do_log('err', 'Could not drop INDEX, table \'%s\'.', $t);
		    }
		    
		    ## Add INDEX
		    unless ($dbh->do("CREATE INDEX IF NOT EXIST $t\_index ON $t ($fields)")) {
			&do_log('err', 'Could not set INDEX on field \'%s\', table\'%s\'.', $fields, $t);
			return undef;
		    }
		    push @report, sprintf('Table %s, INDEX set on %s', $t, $fields);
		    &do_log('info', 'Table %s, INDEX set on %s', $t, $fields);
		    
		}
	    }
	}
	## Try to run the create_db.XX script
    }elsif ($found_tables == 0) {
        my $db_script =
            Sympa::Constants::SCRIPTDIR . "/create_db.$Conf::Conf{'db_type'}";
	unless (open SCRIPT, $db_script) {
	    &do_log('err', "Failed to open '%s' file : %s", $db_script, $!);
	    return undef;
	}
	my $script;
	while (<SCRIPT>) {
	    $script .= $_;
	}
	close SCRIPT;
	my @scripts = split /;\n/,$script;

	$db_script =
        Sympa::Constants::SCRIPTDIR . "/create_db.$Conf::Conf{'db_type'}";
	push @report, sprintf("Running the '%s' script...", $db_script);
	&do_log('notice', "Running the '%s' script...", $db_script);
	foreach my $sc (@scripts) {
	    next if ($sc =~ /^\#/);
	    unless ($dbh->do($sc)) {
		&do_log('err', "Failed to run script '%s' : %s", $db_script, $dbh->errstr);
		return undef;
	    }
	}

	## SQLite :  the only access permissions that can be applied are 
	##           the normal file access permissions of the underlying operating system
	if (($Conf::Conf{'db_type'} eq 'SQLite') &&  (-f $Conf::Conf{'db_name'})) {
	    unless (&tools::set_file_rights(file => $Conf::Conf{'db_name'},
					    user  => Sympa::Constants::USER,
					    group => Sympa::Constants::GROUP,
					    mode  => 0664,
					    ))
	    {
		&do_log('err','Unable to set rights on %s',$Conf::Conf{'db_name'});
		return undef;
	    }
	}
	
    }elsif ($found_tables < 3) {
	&do_log('err', 'Missing required tables in the database ; you should create them with create_db.%s script', $Conf::Conf{'db_type'});
	return undef;
    }
    
    ## Used by List subroutines to check that the DB is available
    $List::use_db = 1;

    ## Notify listmaster
    &List::send_notify_to_listmaster('db_struct_updated',  $Conf::Conf{'domain'}, {'report' => \@report}) if ($#report >= 0);

    return 1;
}

## Check if data structures are uptodate
## If not, no operation should be performed before the upgrade process is run
sub data_structure_uptodate {
     my $version_file = "$Conf::Conf{'etc'}/data_structure.version";
     my $data_structure_version;

     if (-f $version_file) {
	 unless (open VFILE, $version_file) {
	     do_log('err', "Unable to open %s : %s", $version_file, $!);
	     return undef;
	 }
	 while (<VFILE>) {
	     next if /^\s*$/;
	     next if /^\s*\#/;
	     chomp;
	     $data_structure_version = $_;
	     last;
	 }
	 close VFILE;
     }

     if (defined $data_structure_version &&
	 $data_structure_version ne Sympa::Constants::VERSION) {
	 &do_log('err', "Data structure (%s) is not uptodate for current release (%s)", $data_structure_version, Sympa::Constants::VERSION);
	 return 0;
     }

     return 1;
 }

## Compare required DB field type
## Input : required_format, effective_format
## Output : return 1 if field type is appropriate AND size >= required size
sub check_db_field_type {
    my %param = @_;

    my ($required_type, $required_size, $effective_type, $effective_size);

    if ($param{'required_format'} =~ /^(\w+)(\((\d+)\))?$/) {
	($required_type, $required_size) = ($1, $3);
    }

    if ($param{'effective_format'} =~ /^(\w+)(\((\d+)\))?$/) {
	($effective_type, $effective_size) = ($1, $3);
    }

    if (($effective_type eq $required_type) && ($effective_size >= $required_size)) {
	return 1;
    }

    return 0;
}

## used to encode files to UTF-8
## also add X-Attach header field if template requires it
## IN : - arrayref with list of filepath/lang pairs
sub to_utf8 {
    my $files = shift;

    my $with_attachments = qr{ archive.tt2 | digest.tt2 | get_archive.tt2 | listmaster_notification.tt2 | 
				   message_report.tt2 | moderate.tt2 |  modindex.tt2 | send_auth.tt2 }x;
    my $total;
    
    foreach my $pair (@{$files}) {
	my ($file, $lang) = @$pair;
	unless (open(TEMPLATE, $file)) {
	    &do_log('err', "Cannot open template %s", $file);
	    next;
	}
	
	my $text = '';
	my $modified = 0;

	## If filesystem_encoding is set, files are supposed to be encoded according to it
	my $charset;
	if ((defined $Conf::Conf::Ignored_Conf{'filesystem_encoding'})&&($Conf::Conf::Ignored_Conf{'filesystem_encoding'} ne 'utf-8')) {
	    $charset = $Conf::Conf::Ignored_Conf{'filesystem_encoding'};
	}else {	    
	    &Language::PushLang($lang);
	    $charset = &Language::GetCharset;
	    &Language::PopLang;
	}
	
	# Add X-Sympa-Attach: headers if required.
	if (($file =~ /mail_tt2/) && ($file =~ /\/($with_attachments)$/)) {
	    while (<TEMPLATE>) {
		$text .= $_;
		if (m/^Content-Type:\s*message\/rfc822/i) {
		    while (<TEMPLATE>) {
			if (m{^X-Sympa-Attach:}i) {
			    $text .= $_;
			    last;
			}
			if (m/^[\r\n]+$/) {
			    $text .= "X-Sympa-Attach: yes\n";
			    $modified = 1;
			    $text .= $_;
			    last;
			}
			$text .= $_;
		    }
		}
	    }
	} else {
	    $text = join('', <TEMPLATE>);
	}
	close TEMPLATE;
	
	# Check if template is encoded by UTF-8.
	if ($text =~ /[^\x20-\x7E]/) {
	    my $t = $text;
	    eval {
		&Encode::decode('UTF-8', $t, Encode::FB_CROAK);
	      };
	    if ($@) {
		eval {
		    $t = $text;
		    &Encode::from_to($t, $charset, "UTF-8", Encode::FB_CROAK);
		};
		if ($@) {
		    &do_log('err',"Template %s cannot be converted from %s to UTF-8", $charset, $file);
		} else {
		    $text = $t;
		    $modified = 1;
		}
	    }
	}
	
	next unless $modified;
	
	my $date = strftime("%Y.%m.%d-%H.%M.%S", localtime(time));
	unless (rename $file, $file.'@'.$date) {
	    do_log('err', "Cannot rename old template %s", $file);
	    next;
	}
	unless (open(TEMPLATE, ">$file")) {
	    do_log('err', "Cannot open new template %s", $file);
	    next;
	}
	print TEMPLATE $text;
	close TEMPLATE;
	unless (&tools::set_file_rights(file => $file,
					user =>  Sympa::Constants::USER,
					group => Sympa::Constants::GROUP,
					mode =>  0644,
					))
	{
	    &do_log('err','Unable to set rights on %s',$Conf::Conf{'db_name'});
	    next;
	}
	&do_log('notice','Modified file %s ; original file kept as %s', $file, $file.'@'.$date);
	
	$total++;
    }

    return $total;
}


# md5_encode_password : Version later than 5.4 uses md5 fingerprint instead of symetric crypto to store password.
#  This require to rewrite paassword in database. This upgrade IS NOT REVERSIBLE
sub md5_encode_password {

    my $total = 0;

    &do_log('notice', 'Upgrade::md5_encode_password() recoding password using md5 fingerprint');
    
    unless (&List::check_db_connect()) {
	return undef;
    }

    my $dbh = &List::db_get_handler();

    my $sth;
    unless ($sth = $dbh->prepare("SELECT email_user,password_user from user_table")) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement : %s', $dbh->errstr);
	return undef;
    }

    $total = 0;
    my $total_md5 = 0 ;

    while (my $user = $sth->fetchrow_hashref('NAME_lc')) {

	my $clear_password ;
	if ($user->{'password_user'} =~ /^[0-9a-f]{32}/){
	    do_log('info','password from %s already encoded as md5 fingerprint',$user->{'email_user'});
	    $total_md5++ ;
	    next;
	}	
	
	## Ignore empty passwords
	next if ($user->{'password_user'} =~ /^$/);

	if ($user->{'password_user'} =~ /^crypt.(.*)$/) {
	    $clear_password = &tools::decrypt_password($user->{'password_user'});
	}else{ ## Old style cleartext passwords
	    $clear_password = $user->{'password_user'};
	}

	$total++;

	## Updating Db
	my $escaped_email =  $user->{'email_user'};
	$escaped_email =~ s/\'/''/g;
	my $statement = sprintf "UPDATE user_table SET password_user='%s' WHERE (email_user='%s')", &tools::md5_fingerprint($clear_password), $escaped_email ;
	
	unless ($dbh->do($statement)) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
    }
    $sth->finish();
    
    do_log('info',"Updating password storage in table user_table using md5 for %d users",$total) ;
    if ($total_md5) {
	do_log('info',"Found in table user %d password stored using md5, did you run Sympa before upgrading ?", $total_md5 );
    }    
    return $total;
}


sub create_db_script {
    
## DATABASE Creation script
    
    my $create_db_mysql;
    my $create_db_Pg;
    my $create_db_Oracle;
    my $create_db_SQLite;
    my $create_db_Sybase;

    
# MYSQL CREATION DATABASE SCRIPT
    
    $create_db_mysql = "## MySQL Database creation script

CREATE DATABASE sympa;

## Connect to DB 
\\r sympa \n";
    
    foreach my $table ( keys %{ $db_struct{'mysql'} } ) {
	$create_db_mysql .= "\n\n-- --------------------------------------------------------
--
-- Table structure for table \`$table\`
-- \n\n";
	
        $create_db_mysql .= "CREATE TABLE $table ( \n";
	foreach my $field  ( keys %{ $db_struct{'mysql'}{$table}  } ) {
	    $create_db_mysql .= "\t $field \t $db_struct{'mysql'}{$table}{$field}";
	    if (exists $not_null{$field}){
		$create_db_mysql .= " NOT NULL";
	    }
	    $create_db_mysql .= ", \n";
	}
	
	if (exists $primary{$table}){
	    $create_db_mysql .= "\t PRIMARY KEY (";
	    for my $i (0 .. @{$primary{$table}}-1){
		$create_db_mysql .= "$primary{$table}[$i]";
		if  (exists $primary{$table}[$i+1]){$create_db_mysql .= ", ";}
	    }
	    $create_db_mysql .= ")"
	    }
	if (exists $indexes{$table}){
	    $create_db_mysql .= ", \n \t INDEX user_index ( $indexes{$table}{'user_index'}[0] ) \n";
	}
	
	
	$create_db_mysql .= " \n );\n";
    }
    
    
# ORACLE DATABASE CREATION SCRIPT
    
    $create_db_Oracle = "## ORACLE Database creation script

/Bases/oracle/product/7.3.4.1/bin/sqlplus loginsystem/passwdoracle <<-!
create user SYMPA identified by SYMPA default tablespace TABLESP
temporary tablespace TEMP;
 grant create session to SYMPA;
 grant create table to SYMPA;
 grant create synonym to SYMPA;
 grant create view to SYMPA;
 grant execute any procedure to SYMPA;
 grant select any table to SYMPA;
 grant select any sequence to SYMPA;
 grant resource to SYMPA;
!

/Bases/oracle/product/7.3.4.1/bin/sqlplus SYMPA/SYMPA <<-!
";
    
    foreach my $table ( keys %{ $db_struct{'mysql'} } ) {
	$create_db_Oracle .= "\n\n## --------------------------------------------------------
##
## Table structure for table \`$table\`
## \n\n";
	    
	    $create_db_Oracle .= "CREATE TABLE $table ( \n";
	foreach my $field  ( keys %{ $db_struct{'Oracle'}{$table}  } ) {
	    my $trans = $db_struct{'Oracle'}{$table}{$field};
	    $create_db_Oracle .= "\t $field \t".$trans;
	    if (exists $not_null{$field}){
		$create_db_Oracle .= " NOT NULL";
	    }
	    $create_db_Oracle .= ", \n";
	}
	
	if (exists $primary{$table}){
	    my $tablet = $table;
	    $tablet =~ s/\_table$/\1/g;
	    $create_db_Oracle .= "\t CONSTRAINT ind_$tablet PRIMARY KEY (";
	    for my $i (0 .. @{$primary{$table}}-1){
		$create_db_Oracle .= "$primary{$table}[$i]";
		if  (exists $primary{$table}[$i+1]){$create_db_Oracle .= ", ";}
	    }
	    $create_db_Oracle .= ")"
	    }
	
	$create_db_Oracle .= " \n );\n";
    }
    
# Postgresql DATABASE CREATION SCRIPT
    
    $create_db_Pg = "-- POSTGRESQL Database creation script

CREATE DATABASE sympa;

-- Connect to DB 
\\connect sympa \n";
    
    foreach my $table ( keys %{ $db_struct{'mysql'} } ) {
	$create_db_Pg .= "\n\n-- --------------------------------------------------------
--
-- Table structure for table \`$table\`
-- \n\n";
	$create_db_Pg .= $table;
	$create_db_Pg .= "CREATE TABLE $table ( \n";
	foreach my $field  ( keys %{ $db_struct{'pg'}{$table}  } ) {
	    my $trans = $db_struct{'pg'}{$table}{$field};
	    $create_db_Pg .= "\t $field \t".$trans ;
	    if (exists $not_null{$field}){
		$create_db_Pg .= " NOT NULL";
	    }
	    $create_db_Pg .= ", \n";
	}
	my $tablet = $table;
	$tablet =~ s/\_table$/\1/g;
	if (exists $primary{$table}){
	    $create_db_Pg .= "\t CONSTRAINT ind_$tablet PRIMARY KEY (";
	    for my $i (0 .. @{$primary{$table}}-1){
		$create_db_Pg .= "$primary{$table}[$i]";
		if  (exists $primary{$table}[$i+1]){$create_db_Pg .= ", ";}
	    }
	    $create_db_Pg .= ")"
	    }
	$create_db_Pg .= " \n );\n";
	if (exists $indexes{$table}){
	    $create_db_Pg .= "\n CREATE INDEX $tablet\_idx ON $table($indexes{$table}{'user_index'}[0]) ) \n";
	}
	
	
	
    }
    
    
# Sybase DATABASE CREATION SCRIPT
    
    $create_db_Sybase = "/* Sybase Database creation script */

/* sympa database must have been created */

/* Connect to DB */
use sympa \n
go \n";
    
    foreach my $table ( keys %{ $db_struct{'mysql'} } ) {
	$create_db_Sybase .= "\n\n/* -------------------------------------------------------- */

/* Table structure for table \`$table\` */
 \n\n";
	
	$create_db_Sybase .= "create table $table \n( \n";
	foreach my $field  ( keys %{ $db_struct{'Sybase'}{$table}  } ) {
	    my $trans = $db_struct{'Sybase'}{$table}{$field};
	    $create_db_Sybase .= "\t $field \t".$trans;
	    if (exists $not_null{$field}){
		$create_db_Sybase .= " NOT NULL";
	    }
	$create_db_Sybase .= ", \n";
	}
	
	if (exists $primary{$table}){
	    my $tablet = $table;
	    $tablet =~ s/\_table$/\1/g;
	    $create_db_Sybase .= "\t constraint ind_".$tablet." PRIMARY KEY (";
	    for my $i (0 .. @{$primary{$table}}-1){
		$create_db_Sybase .= "$primary{$table}[$i]";
		if  (exists $primary{$table}[$i+1]){$create_db_Sybase .= ", ";}
	    }
	    $create_db_Sybase .=")"
	    }
	
	
	$create_db_Sybase .= "\n)\ngo \n";
	if (exists $indexes{$table}){
	    my $ckey = $indexes{$table}{'user_index'}[0];
	    $create_db_Sybase .= "\ncreate index ".$ckey."_fk on $table ($ckey) \ngo\n";
	}
	
	
	
    }
    
    
# SQLITE DATABASE CREATION SCRIPT
    
    $create_db_SQLite = "-- SQLITE Database creation script";
    
    foreach my $table ( keys %{ $db_struct{'mysql'} } ) {
	$create_db_SQLite .= "\n\n-- --------------------------------------------------------
--
-- Table structure for table \`$table\`
-- \n\n";
	
	$create_db_SQLite .= "CREATE TABLE $table ( \n";
	foreach my $field  ( keys %{ $db_struct{'SQLite'}{$table}  } ) {
	    my $trans = $db_struct{'SQLite'}{$table}{$field};
	    $create_db_SQLite .= "\t $field \t".$trans;
	    if (exists $not_null{$field}){
		$create_db_SQLite .= " NOT NULL";
	    }
	    $create_db_SQLite .= ", \n";
	}
	
	if (exists $primary{$table}){
	    $create_db_SQLite .= "\t PRIMARY KEY (";
	    for my $i (0 .. @{$primary{$table}}-1){
		$create_db_SQLite .= "$primary{$table}[$i]";
		if  (exists $primary{$table}[$i+1]){$create_db_SQLite .= ", ";}
	    }
	    $create_db_SQLite .= ")"
	    }
	$create_db_SQLite .= " \n );\n";
	if (exists $indexes{$table}){
	    my $tablet = $table;
	    $tablet =~ s/\_table$/\1/g;
	    $create_db_SQLite .= "\nCREATE INDEX ".$tablet."_idx ON $table ( $indexes{$table}{'user_index'}[0] ); \n";
	}
	
	
    }
    
    
    open(MYSQL_CREATE,">../etc/script/create_db.mysql") || die ("error") ;
    print MYSQL_CREATE $create_db_mysql;
    close(MYSQL_CREATE);
    
    open(ORACLE_CREATE,">../etc/script/create_db.Oracle") || die ("error") ;
    print ORACLE_CREATE $create_db_Oracle;
    close(ORACLE_CREATE);
    
    open(PG_CREATE,">../etc/script/create_db.Pg") || die ("error") ;
    print PG_CREATE $create_db_Pg;
    close(PG_CREATE);
    
    open(SYBASE_CREATE,">../etc/script/create_db.Sybase") || die ("error") ;
    print SYBASE_CREATE $create_db_Sybase;
    close(SYBASE_CREATE);
    
    open(SQLITE_CREATE,">../etc/script/create_db.SQLite") || die ("error") ;
    print SQLITE_CREATE $create_db_SQLite;
    close(SQLITE_CREATE);
} 
## Packages must return true.
1;
