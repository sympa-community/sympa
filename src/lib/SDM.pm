# SDM.pm - Sympa Database Manager : This module contains all functions relative to
# the access and maintenance of the Sympa database.
#<!-- RCS Identication ; $Revision: 7016 $ --> 
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

package SDM;

use strict;

use Carp;
use Exporter;

use Conf;
use Log;
use List;
use Sympa::Constants;
use SQLSource;
use Data::Dumper;

our @ISA;
our $AUTOLOAD;

use Sympa::DatabaseDescription;

# db structure description has moved in Sympa/Constant.pm 
my %db_struct = &Sympa::DatabaseDescription::db_struct();

my %not_null = &Sympa::DatabaseDescription::not_null();

my %primary =  &Sympa::DatabaseDescription::primary() ;
	       
my %autoincrement = &Sympa::DatabaseDescription::autoincrement() ;

## List the required INDEXES
##   1st key is the concerned table
##   2nd key is the index name
##   the table lists the field on which the index applies
my %indexes = %Sympa::DatabaseDescription::indexes ;

# table indexes that can be removed during upgrade process
my @former_indexes =  @Sympa::DatabaseDescription::former_indexes ;

our $db_source;
our $use_db;

sub do_query {
    my $query = shift;
    my @params = @_;
    my $sth;

    unless ($sth = $db_source->do_query($query,@params)) {
	&Log::do_log('err','SQL query failed to execute in the Sympa database');
	return undef;
    }

    return $sth;
}

sub do_prepared_query {
    my $query = shift;
    my @params = @_;
    my $sth;

    unless ($sth = $db_source->do_prepared_query($query,@params)) {
	&Log::do_log('err','SQL query failed to execute in the Sympa database');
	return undef;
    }

    return $sth;
}

## Get database handler
sub db_get_handler {
    &Log::do_log('debug3', 'Returning handle to sympa database');

    if(&check_db_connect()) {
	return $db_source->{'dbh'};
    }else {
	&Log::do_log('err', 'Unable to get a handle to Sympa database');
	return undef;
    }
}

## Just check if DB connection is ok
sub check_db_connect {
    
    #&Log::do_log('debug2', 'Checking connection to the Sympa database');
    ## Is the Database defined
    unless (&Conf::get_robot_conf('*','db_name')) {
	&Log::do_log('err', 'No db_name defined in configuration file');
	return undef;
    }
    
    unless ($db_source->{'dbh'} && $db_source->{'dbh'}->ping()) {
	unless (&connect_sympa_database('just_try')) {
	    &Log::do_log('err', 'Failed to connect to database');	   
	    return undef;
	}
    }

    return 1;
}

## Connect to Database
sub connect_sympa_database {
    my $option = shift;

    &Log::do_log('debug', 'Connecting to Sympa database');

    ## We keep trying to connect if this is the first attempt
    ## Unless in a web context, because we can't afford long response time on the web interface
    my $db_conf = &Conf::get_parameters_group('*','Database related');
    $db_conf->{'reconnect_options'} = {'keep_trying'=>($option ne 'just_try' && ( !$db_source->{'connected'} && !$ENV{'HTTP_HOST'})),
						 'warn'=>1 };
    unless ($db_source = new SQLSource($db_conf)) {
	&Log::do_log('err', 'Unable to create SQLSource object');
    	return undef;
    }
    ## Used to check that connecting to the Sympa database works and the
    ## SQLSource object is created.
    $use_db = 1;

    # Just in case, we connect to the database here. Probably not necessary.
    unless ( $db_source->{'dbh'} = $db_source->connect()) {
	&Log::do_log('err', 'Unable to connect to the Sympa database');
	return undef;
    }
    &Log::do_log('debug2','Connected to Database %s',&Conf::get_robot_conf('*','db_name'));

    return 1;
}

## Disconnect from Database
sub db_disconnect {
    &Log::do_log('debug', 'Disconnecting from Sympa database');

    unless ($db_source->{'dbh'}->disconnect()) {
	&Log::do_log('err','Can\'t disconnect from Database %s : %s',&Conf::get_robot_conf('*','db_name'), $db_source->{'dbh'}->errstr);
	return undef;
    }

    return 1;
}

sub probe_db {
    &Log::do_log('debug3', 'Checking database structure');    
    my (%checked, $table);
    
    my $dbh = &db_get_handler();

    ## Database structure
    ## Report changes to listmaster
    my @report;

    ## Get tables
    my @tables;
    my $list_of_tables;
    if ($list_of_tables = $db_source->get_tables()) {
	@tables = @{$list_of_tables};
    }else{
	@tables = ();
    }

    my ( $fields, %real_struct);
	## Check required tables
    foreach my $t1 (keys %{$db_struct{'mysql'}}) {
	my $found;
	foreach my $t2 (@tables) {
	    $found = 1 if ($t1 eq $t2) ;
	}
	unless ($found) {
	    if (my $rep = $db_source->add_table({'table'=>$t1})) {
		push @report, $rep;
		&Log::do_log('notice', 'Table %s created in database %s', $t1, &Conf::get_robot_conf('*','db_name'));
		push @tables, $t1;
		$real_struct{$t1} = {};
	    }
	}
    }
    ## Get fields
    foreach my $t (@tables) {
	$real_struct{$t} = $db_source->get_fields({'table'=>$t});
    }
    ## Check tables structure if we could get it
    ## Only performed with mysql , Pg and SQLite
    if (%real_struct) {

	foreach my $t (keys %{$db_struct{'mysql'}}) {
	    unless ($real_struct{$t}) {
		&Log::do_log('err', "Table '%s' not found in database '%s' ; you should create it with create_db.%s script", $t, &Conf::get_robot_conf('*','db_name'), &Conf::get_robot_conf('*','db_type'));
		return undef;
	    }
	    unless (&check_fields({'table' => $t,'report' => \@report,'real_struct' => \%real_struct})) {
		&Log::do_log('err', "Unable to check the validity of fields definition for table %s. Aborting.", $t);
		return undef;
	    }
	    ## Remove temporary DB field
	    if ($real_struct{$t}{'temporary'}) {
		$db_source->delete_field({
		    'table' => $t,
		    'field' => 'temporary',
		    });
		delete $real_struct{$t}{'temporary'};
	    }

	    if ((&Conf::get_robot_conf('*','db_type') eq 'mysql')||(&Conf::get_robot_conf('*','db_type') eq 'Pg')||(&Conf::get_robot_conf('*','db_type') eq 'SQLite')) {
		## Check that primary key has the right structure.
		unless (&check_primary_key({'table' => $t,'report' => \@report})) {
		    &Log::do_log('err', "Unable to check the valifity of primary key for table %s. Aborting.", $t);
		    return undef;
		}
		
		unless (&check_indexes({'table' => $t,'report' => \@report})) {
		    &Log::do_log('err', "Unable to check the valifity of indexes for table %s. Aborting.", $t);
		    return undef;
		}
		
	    }   
	}
	# add autoincrement if needed
	foreach my $table (keys %autoincrement) {
	    &Log::do_log('notice',"Checking autoincrement for table $table, field $autoincrement{$table}");
	    unless ($db_source->is_autoinc({'table'=>$table,'field'=>$autoincrement{$table}})){
		if ($db_source->set_autoinc({'table'=>$table,'field'=>$autoincrement{$table},
		'field_type'=>$db_struct{'mysql'}{$table}{'fields'}{$autoincrement{$table}}{'struct'}})){
		    &Log::do_log('notice',"Setting table $table field $autoincrement{$table} as autoincrement");
		}else{
		    &Log::do_log('err',"Could not set table $table field $autoincrement{$table} as autoincrement");
		    return undef;
		}
	    }
	}
    }else{
	&Log::do_log('err',"Could not check the database structure. consider verify it manually before launching Sympa.");
	return undef;
    }
    
    ## Used by List subroutines to check that the DB is available
    $List::use_db = 1;

    ## Notify listmaster
    &List::send_notify_to_listmaster('db_struct_updated',  &Conf::get_robot_conf('*','domain'), {'report' => \@report}) if ($#report >= 0);

    return 1;
}

sub check_fields {
    my $param = shift;
    my $t = $param->{'table'};
    my %real_struct = %{$param->{'real_struct'}};
    my $report_ref = $param->{'report'};

    foreach my $f (sort keys %{$db_struct{&Conf::get_robot_conf('*','db_type')}{$t}}) {
	unless ($real_struct{$t}{$f}) {
	    push @{$report_ref}, sprintf("Field '%s' (table '%s' ; database '%s') was NOT found. Attempting to add it...", $f, $t, &Conf::get_robot_conf('*','db_name'));
	    &Log::do_log('info', "Field '%s' (table '%s' ; database '%s') was NOT found. Attempting to add it...", $f, $t, &Conf::get_robot_conf('*','db_name'));

	    my $rep;
	    if ($rep = $db_source->add_field({
		'table' => $t,
		'field' => $f,
		'type' => $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f},
		'notnull' => $not_null{$f},
		'autoinc' => ( $autoincrement{$t} eq $f),
		'primary' => ( $autoincrement{$t} eq $f),
		})){
		push @{$report_ref}, $rep;
		
	    }else {
		&Log::do_log('err', 'Addition of fields in database failed. Aborting.');
		return undef;
	    }
	    next;
	}
	
	## Change DB types if different and if update_db_types enabled
	if (&Conf::get_robot_conf('*','update_db_field_types') eq 'auto' && &Conf::get_robot_conf('*','db_type') ne 'SQLite') {
	    unless (&check_db_field_type(effective_format => $real_struct{$t}{$f},
					 required_format => $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f})) {
		push @{$report_ref}, sprintf("Field '%s'  (table '%s' ; database '%s') does NOT have awaited type (%s). Attempting to change it...",$f, $t, &Conf::get_robot_conf('*','db_name'), $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f});
		
		&Log::do_log('notice', "Field '%s'  (table '%s' ; database '%s') does NOT have awaited type (%s) where type in database seems to be (%s). Attempting to change it...",$f, $t, &Conf::get_robot_conf('*','db_name'), $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f},$real_struct{$t}{$f});
		
		my $rep;
		if ($rep = $db_source->update_field({
		    'table' => $t,
		    'field' => $f,
		    'type' => $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f},
		    'notnull' => $not_null{$f},
		    })){
			push @{$report_ref}, $rep;
		}else {
		    &Log::do_log('err', 'Fields update in database failed. Aborting.');
		    return undef;
		}
	    }
	}else {
	    unless ($real_struct{$t}{$f} eq $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f}) {
		&Log::do_log('err', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s).', $f, $t, &Conf::get_robot_conf('*','db_name'), $db_struct{&Conf::get_robot_conf('*','db_type')}{$t}{$f});
		&Log::do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
		return undef;
	    }
	}
    }
    return 1;
}

sub check_primary_key {
    my $param = shift;
    my $t = $param->{'table'};
    my $report_ref = $param->{'report'};
    &Log::do_log('debug','Checking primary key for table %s',$t);

    my $list_of_keys = join ',',@{$primary{$t}};
    my $key_as_string = "$t [$list_of_keys]";
    &Log::do_log('debug','Checking primary keys for table %s expected_keys %s',$t,$key_as_string );

    my $should_update = $db_source->check_key({'table'=>$t,'key_name'=>'primary','expected_keys'=>$primary{$t}});
    if ($should_update){
	my $list_of_keys = join ',',@{$primary{$t}};
	my $key_as_string = "$t [$list_of_keys]";
	if ($should_update->{'empty'}) {
	    &Log::do_log('notice',"Primary key %s is missing. Adding it.",$key_as_string);
	    ## Add primary key
	    my $rep = undef;
	    if ($rep = $db_source->set_primary_key({'table'=>$t,'fields'=>$primary{$t}})) {
		push @{$report_ref}, $rep;
	    }
	}elsif($should_update->{'existing_key_correct'}) {
	    &Log::do_log('debug',"Existing key correct (%s) nothing to change",$key_as_string);
	}else{
	    ## drop previous primary key
	    my $rep = undef;
	    if ($rep = $db_source->unset_primary_key({'table'=>$t})) {
		push @{$report_ref}, $rep;
	    }
	    ## Add primary key
	    $rep = undef;
	    if ($rep = $db_source->set_primary_key({'table'=>$t,'fields'=>$primary{$t}})) {
		push @{$report_ref}, $rep;
	    }
	}
    }else{
	&Log::do_log('err','Unable to evaluate table %s primary key. Trying to reset primary key anyway.',$t);
	## drop previous primary key
	my $rep = undef;
	if ($rep = $db_source->unset_primary_key({'table'=>$t})) {
	    push @{$report_ref}, $rep;
	}
	## Add primary key
	$rep = undef;
	if ($rep = $db_source->set_primary_key({'table'=>$t,'fields'=>$primary{$t}})) {
	    push @{$report_ref}, $rep;
	}
    }
    return 1;
}

sub check_indexes {
    my $param = shift;
    my $t = $param->{'table'};
    my $report_ref = $param->{'report'};
    &Log::do_log('debug','Checking indexes for table %s',$t);
    ## drop previous index if this index is not a primary key and was defined by a previous Sympa version
    my %index_columns = %{$db_source->get_indexes({'table' => $t})};
    foreach my $idx ( keys %index_columns ) {
	&Log::do_log('debug','Found index %s',$idx);
	## Remove the index if obsolete.
	foreach my $known_index ( @former_indexes ) {
	    if ( $idx eq $known_index ) {
		&Log::do_log('notice','Removing obsolete index %s',$idx);
		if (my $rep = $db_source->unset_index({'table'=>$t,'index'=>$idx})) {
		    push @{$report_ref}, $rep;
		}
		last;
	    }
	}
    }
    
    ## Create required indexes
    foreach my $idx (keys %{$indexes{$t}}){ 
	## Add indexes
	unless ($index_columns{$idx}) {
	    &Log::do_log('notice','Index %s on table %s does not exist. Adding it.',$idx,$t);
	    if (my $rep = $db_source->set_index({'table'=>$t, 'index_name'=> $idx, 'fields'=>$indexes{$t}{$idx}})) {
		push @{$report_ref}, $rep;
	    }
	}
	my $index_check = $db_source->check_key({'table'=>$t,'key_name'=>$idx,'expected_keys'=>$indexes{$t}{$idx}});
	if ($index_check){
	    my $list_of_fields = join ',',@{$indexes{$t}{$idx}};
	    my $index_as_string = "$idx: $t [$list_of_fields]";
	    if ($index_check->{'empty'}) {
		## Add index
		my $rep = undef;
		&Log::do_log('notice',"Index %s is missing. Adding it.",$index_as_string);
		if ($rep = $db_source->set_index({'table'=>$t, 'index_name'=> $idx, 'fields'=>$indexes{$t}{$idx}})) {
		    push @{$report_ref}, $rep;
		}
	    }elsif($index_check->{'existing_key_correct'}) {
		&Log::do_log('debug',"Existing index correct (%s) nothing to change",$index_as_string);
	    }else{
		## drop previous index
		&Log::do_log('notice',"Index %s has not the right structure. Changing it.",$index_as_string);
		my $rep = undef;
		if ($rep = $db_source->unset_index({'table'=>$t, 'index'=> $idx})) {
		    push @{$report_ref}, $rep;
		}
		## Add index
		$rep = undef;
		if ($rep = $db_source->set_index({'table'=>$t, 'index_name'=> $idx, 'fields'=>$indexes{$t}{$idx}})) {
		    push @{$report_ref}, $rep;
		}
	    }
	}else{
	    &Log::do_log('err','Unable to evaluate index %s in table %s. Trying to reset index anyway.',$t,$idx);
	    ## drop previous index
	    my $rep = undef;
	    if ($rep = $db_source->unset_index({'table'=>$t, 'index'=> $idx})) {
		push @{$report_ref}, $rep;
	    }
	    ## Add index
	    $rep = undef;
	    if ($rep = $db_source->set_index({'table'=>$t, 'index_name'=> $idx,'fields'=>$indexes{$t}{$idx}})) {
		push @{$report_ref}, $rep;
	    }
	}
    }	 
    return 1;
}

## Check if data structures are uptodate
## If not, no operation should be performed before the upgrade process is run
sub data_structure_uptodate {
     my $version_file = "&Conf::get_robot_conf('*','etc')/data_structure.version";
     my $data_structure_version;

     if (-f $version_file) {
	 unless (open VFILE, $version_file) {
	     &Log::do_log('err', "Unable to open %s : %s", $version_file, $!);
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
	 &Log::do_log('err', "Data structure (%s) is not uptodate for current release (%s)", $data_structure_version, Sympa::Constants::VERSION);
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

sub quote {
    my $param = shift;
    if (defined $db_source) {
	return $db_source->quote($param);
    }else{
	if(&check_db_connect()) {
	    return $db_source->quote($param);
	}else{
	    &Log::do_log('err', 'Unable to get a handle to Sympa database');
	    return undef;
	}
    }
}

sub get_substring_clause {
    my $param = shift;
    if (defined $db_source) {
	return $db_source->get_substring_clause($param);
     }else{
	if(&check_db_connect()) {
	    return $db_source->get_substring_clause($param);
	}else{
	    &Log::do_log('err', 'Unable to get a handle to Sympa database');
	    return undef;
	}
    }
}

sub get_limit_clause {
    my $param = shift;
    if (defined $db_source) {
	return ' '.$db_source->get_limit_clause($param).' ';
    }else{
	if(&check_db_connect()) {
	    return ' '.$db_source->get_limit_clause($param).' ';
	}else{
	    &Log::do_log('err', 'Unable to get a handle to Sympa database');
	    return undef;
	}
    }
}

## Returns a character string corresponding to the expression to use in
## a read query (e.g. SELECT) for the field given as argument.
## This sub takes a single argument: the name of the field to be used in
## the query.
##
sub get_canonical_write_date {
    my $param = shift;
    if (defined $db_source) {
	return $db_source->get_canonical_write_date($param);
    }else{
	if(&check_db_connect()) {
	    return $db_source->get_canonical_write_date($param);
	}else{
	    &Log::do_log('err', 'Unable to get a handle to Sympa database');
	    return undef;
	}
    }
}

## Returns a character string corresponding to the expression to use in 
## a write query (e.g. UPDATE or INSERT) for the value given as argument.
## This sub takes a single argument: the value of the date to be used in
## the query.
##
sub get_canonical_read_date {
    my $param = shift;
    if (defined $db_source) {
	return $db_source->get_canonical_read_date($param);
    }else{
	if(&check_db_connect()) {
	    return $db_source->get_canonical_read_date($param);
	}else{
	    &Log::do_log('err', 'Unable to get a handle to Sympa database');
	    return undef;
	}
    }
}

return 1;
