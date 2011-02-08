# SympaDatabaseManger.pm - This module contains all functions relative to
# the maintainance of the Sympa database.
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
# along with this program; if not, write to the Free Softwarec
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package SympaDatabaseManager;

use strict;

use Carp;
use Exporter;

use Conf;
use Log;
use List;
use tt2;
use Sympa::Constants;

our @ISA = qw(Exporter SQLSource);
our @EXPORT_OK = qw(probe_db data_structure_uptodate check_db_field_type is_auto_inc set_auto_inc);

use Sympa::DatabaseDescription;



# db structure description has moved in Sympa/Constant.pm 
my %db_struct = &Sympa::DatabaseDescription::db_struct();

my %not_null = %Sympa::DatabaseDescription::not_null;

my %primary =  %Sympa::DatabaseDescription::primary ;
	       
my %autoincrement = %Sympa::DatabaseDescription::autoincrement ;

## List the required INDEXES
##   1st key is the concerned table
##   2nd key is the index name
##   the table lists the field on which the index applies
my %indexes = %Sympa::DatabaseDescription::indexes ;

# table indexes that can be removed during upgrade process
my @former_indexes =  %Sympa::DatabaseDescription::primary ;

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


    my @tables ;
    ## Get tables
    if ($Conf::Conf{'db_type'} eq 'mysql') {
	@tables = $dbh->tables();
	
	foreach my $t (@tables) {
	    $t =~ s/^\`[^\`]+\`\.//;## Clean table names that would look like `databaseName`.`tableName` (mysql)
	    $t =~ s/^\`(.+)\`$/$1/;## Clean table names that could be surrounded by `` (recent DBD::mysql release)
	}
    }elsif($Conf::Conf{'db_type'} eq 'Pg') {
	@tables = $dbh->tables(undef,'public',undef,'TABLE',{pg_noprefix => 1} );
    }
    unless (defined $#tables) {
	&do_log('info', 'Can\'t load tables list from database %s : %s', $Conf::Conf{'db_name'}, $dbh->errstr);
	return undef;
    }
    
    my ( $fields, %real_struct);
    if (($Conf::Conf{'db_type'} eq 'mysql') || ($Conf::Conf{'db_type'} eq 'Pg')){			
	## Check required tables
	foreach my $t1 (keys %{$db_struct{'mysql'}}) {
	    my $found;
	    foreach my $t2 (@tables) {
		$found = 1 if ($t1 eq $t2) ;
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
	    my $sql_query;

	    if ( $Conf::Conf{'db_type'} eq 'Pg'){
		$sql_query = 'SELECT a.attname AS field, t.typname AS type, a.atttypmod AS lengh FROM pg_class c, pg_attribute a, pg_type t WHERE a.attnum > 0 and a.attrelid = c.oid and c.relname = \''.$t.'\' and a.atttypid = t.oid order by a.attnum';
	    }elsif ($Conf::Conf{'db_type'} eq 'mysql') {
		$sql_query = "SHOW FIELDS FROM $t";
	    }
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
		if ( $Conf::Conf{'db_type'} eq 'Pg'){
		    my $lengh = $ref->{'lengh'} - 4; # What a dirty method ! We give a Sympa tee shirt to anyone that suggest a clean solution ;-)
		    $real_struct{$t}{$ref->{'field'}} = $ref->{'type'}.'('.$lengh.')' if ( $ref->{'type'} eq 'varchar');
		}
	    }	    
	    $sth->finish();
	}
    }elsif ($Conf::Conf{'db_type'} eq 'SQLite') {
 	
 	unless (@tables = $dbh->tables) {
 	    &do_log('err', 'Can\'t load tables list from database %s', $Conf::Conf{'db_name'});
 	    return undef;
 	}
	
 	foreach my $t (@tables) {
	    $t =~ s/^"main"\.//; # needed for SQLite 3
	    $t =~ s/^.*\"([^\"]+)\"$/$1/;
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
	
	# Une simple requÂÃªte sqlite : PRAGMA table_info('nomtable') , retourne la liste des champs de la table en question.
	# La liste retournÂÃ©e est composÂÃ©e d'un NÂÂ°Ordre, Nom du champ, Type (longueur), Null ou not null (99 ou 0),Valeur par dÂÃ©faut,ClÂÃ© primaire (1 ou 0)
	
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
		    my $sqlquery = "ALTER TABLE $t ADD $f $db_struct{$Conf::Conf{'db_type'}}{$t}{$f} $options";
		    
		    unless ($dbh->do($sqlquery)) {
			    &do_log('err', 'Could not add field \'%s\' to table\'%s\'. (%s)', $f, $t, $sqlquery);
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
		if ($Conf::Conf{'update_db_field_types'} eq 'auto' && $Conf::Conf{'db_type'} ne 'SQLite') {
		    unless (&check_db_field_type(effective_format => $real_struct{$t}{$f},
						 required_format => $db_struct{$Conf::Conf{'db_type'}}{$t}{$f})) {
			push @report, sprintf('Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s). Attempting to change it...', 
					      $f, $t, $Conf::Conf{'db_name'}, $db_struct{$Conf::Conf{'db_type'}}{$t}{$f});
			&do_log('notice', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s) where type in database seems to be (%s). Attempting to change it...', 
				$f, $t, $Conf::Conf{'db_name'}, $db_struct{$Conf::Conf{'db_type'}}{$t}{$f},$real_struct{$t}{$f});
			
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
	    if (($Conf::Conf{'db_type'} eq 'mysql')||($Conf::Conf{'db_type'} eq 'Pg')) {
		## Check that primary key has the right structure.
		my $should_update;
		my %primaryKeyFound;	      

		my $sql_query ;
		my $test_request_result ;

		if ($Conf::Conf{'db_type'} eq 'mysql') { # get_primary_keys('mysql');

		    $sql_query = "SHOW COLUMNS FROM $t";
		    $test_request_result = $dbh->selectall_hashref($sql_query,'key');

		    foreach my $scannedResult ( keys %$test_request_result ) {
			if ( $scannedResult eq "PRI" ) {
			    $primaryKeyFound{$scannedResult} = 1;
			}
		    }
		}elsif ( $Conf::Conf{'db_type'} eq 'Pg'){# get_primary_keys('Pg');

#		    $sql_query = "SELECT column_name FROM information_schema.columns WHERE table_name = $t";
#		    my $sql_query = 'SELECT pg_attribute.attname AS field FROM pg_index, pg_class, pg_attribute WHERE pg_class.oid =\''.$t.'\'::regclass AND indrelid = pg_class.oid AND pg_attribute.attrelid = pg_class.oid AND pg_attribute.attnum = any(pg_index.indkey) AND indisprimary';
#		    $test_request_result = $dbh->selectall_hashref($sql_query,'key');

		    my $sql_query = 'SELECT pg_attribute.attname AS field FROM pg_index, pg_class, pg_attribute WHERE pg_class.oid =\''.$t.'\'::regclass AND indrelid = pg_class.oid AND pg_attribute.attrelid = pg_class.oid AND pg_attribute.attnum = any(pg_index.indkey) AND indisprimary';

		    my $sth;
		    unless ($sth = $dbh->prepare($sql_query)) {
			do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
			return undef;
		    }	    
		    unless ($sth->execute) {
			do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
			return undef;
		    }
		    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
			$primaryKeyFound{$ref->{'field'}} = 1;
		    }	    
		    $sth->finish();
		   

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
		#xxxxx $test_request_result = $dbh->selectall_hashref('SHOW INDEX FROM '.$t,'key_name');
		my %index_columns;
		if ( $Conf::Conf{'db_type'} eq 'mysql' ){# get_index('Pg');
		    $test_request_result = $dbh->selectall_hashref('SHOW INDEX FROM '.$t,'key_name');		
		    foreach my $indexName ( keys %$test_request_result ) {
			unless ( $indexName eq "PRIMARY" ) {
			    $index_columns{$indexName} = 1;
			}
		    }
		}elsif ( $Conf::Conf{'db_type'} eq 'Pg'){# get_index('Pg');
		    my $sql_query = 'SELECT pg_attribute.attname AS field FROM pg_index, pg_class, pg_attribute WHERE pg_class.oid =\''.$t.'\'::regclass AND indrelid = pg_class.oid AND pg_attribute.attrelid = pg_class.oid AND pg_attribute.attnum = any(pg_index.indkey)';

		    my $sth;
		    unless ($sth = $dbh->prepare($sql_query)) {
			do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
			return undef;
		    }	    
		    unless ($sth->execute) {
			do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
			return undef;
		    }
		    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
			$index_columns{$ref->{'field'}} = 1;
		    }	    
		    $sth->finish();
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
	# add autoincrement if needed
	foreach my $table (keys %autoincrement) {
	    unless (&is_autoinc ($table,$autoincrement{$table})){
		if (&set_autoinc ($table,$autoincrement{$table})){
		    &do_log('notice',"Setting table $table field $autoincrement{$table} as autoincrement");
		}else{
		    &do_log('err',"Could not set table $table field $autoincrement{$table} as autoincrement");
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

# return 1 if table.field is autoincrement
sub is_autoinc {
    my $table = shift; my $field = shift;
    &do_log('debug', 'is_autoinc(%s,%s)',$table,$field);    

    return undef unless $table;
    return undef unless $field;

    my $seqname = $table.'_'.$field.'_seq';
    my $sth;
    my $dbh = &List::db_get_handler();

    if ($Conf::Conf{'db_type'} eq 'Pg') {
	my $sql_query = "SELECT relname FROM pg_class WHERE relname = '$seqname' AND relkind = 'S'  AND relnamespace IN ( SELECT oid  FROM pg_namespace WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema' )";
	unless ($sth = $dbh->prepare($sql_query)) {
	    do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}	    
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}
	my $field = $sth->fetchrow();	    
	$sth->finish();
	return ($field eq $seqname);
    }elsif($Conf::Conf{'db_type'} eq 'mysql') {
	my $sql_query = "SHOW FIELDS FROM `$table` WHERE Extra ='auto_increment' and Field = '$field'";
	unless ($sth = $dbh->prepare($sql_query)) {
	    do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}	    
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}
	my $ref = $sth->fetchrow_hashref('NAME_lc') ;
	$sth->finish();
	return ($ref->{'field'} eq $field);
    }else{
	do_log('debug',"automatic upgrade : autoincrement for table $table, field $field : test of existing autoinc not yet supported for db_type = $Conf::Conf{'db_type'} ");
	return undef;
    }
}

# modify table.field as autoincrement
sub set_autoinc {
    my $table = shift; my $field = shift;
    &do_log('debug', 'set_autoinc(%s,%s)',$table,$field);    

    return undef unless $table;
    return undef unless $field;

    my $seqname = $table.'_'.$field.'_seq';
    my $sth;
    my $dbh = &List::db_get_handler();
    my $sql_query;

    if ($Conf::Conf{'db_type'} eq 'Pg') {
	$sql_query = "CREATE SEQUENCE $seqname";
	$sql_query = "ALTER TABLE `$table` CHANGE `$field` `$field` BIGINT( 20 ) NOT NULL AUTO_INCREMENT";
	unless ($sth = $dbh->prepare($sql_query)) {
	    do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}	    
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}
	$sth->finish();
	$sql_query = "ALTER TABLE $table ALTER COLUMN $field SET DEFAULT NEXTVAL('$seqname');";
	unless ($sth = $dbh->prepare($sql_query)) {
	    do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}	    
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}
	
	return ;
    }elsif($Conf::Conf{'db_type'} eq 'mysql'){
	$sql_query = "ALTER TABLE `$table` CHANGE `$field` `$field` BIGINT( 20 ) NOT NULL AUTO_INCREMENT";
	unless ($sth = $dbh->prepare($sql_query)) {
	    do_log('err','Unable to prepare SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}	    
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL query %s : %s', $sql_query, $dbh->errstr);
	    return undef;
	}
	$sth->finish();
    }else{
	do_log('debug',"automatic upgrade : autoincrement for table $table, field $field : test of existing autoinc not yet supported for db_type = $Conf::Conf{'db_type'} ");
	return undef;
    }
}

return 1;
