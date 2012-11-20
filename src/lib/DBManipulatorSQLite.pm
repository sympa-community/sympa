# DBManipulatorSQLite.pm - This module contains the code specific to using a SQLite server.
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

package DBManipulatorSQLite;

use strict;
use Data::Dumper;

use version;
use Carp;
use Log;

use DBManipulatorDefault;

our @ISA = qw(DBManipulatorDefault);

#######################################################
####### Beginning the RDBMS-specific code. ############
#######################################################

our %date_format = (
		   'read' => {
		       'SQLite' => 'strftime(\'%%s\',%s,\'utc\')'
		       },
		   'write' => {
		       'SQLite' => 'datetime(%d,\'unixepoch\',\'localtime\')'
		       }
	       );

# Builds the string to be used by the DBI to connect to the database.
#
# IN: Nothing
#
# OUT: Nothing
sub build_connect_string{
    my $self = shift;
    $self->{'connect_string'} = "DBI:SQLite(sqlite_use_immediate_transaction=>1):dbname=$self->{'db_name'}";
}

## Returns an SQL clause to be inserted in a query.
## This clause will compute a substring of max length
## $param->{'substring_length'} starting from the first character equal
## to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self = shift;
    my $param = shift;
    return "substr(".$param->{'source_field'}.",func_index(".$param->{'source_field'}.",'".$param->{'separator'}."')+1,".$param->{'substring_length'}.")";
}


## Returns an SQL clause to be inserted in a query.
## This clause will limit the number of records returned by the query to
## $param->{'rows_count'}. If $param->{'offset'} is provided, an offset of
## $param->{'offset'} rows is done from the first record before selecting
## the rows to return.
sub get_limit_clause {
    my $self = shift;
    my $param = shift;
    if ($param->{'offset'}) {
	return "LIMIT ".$param->{'rows_count'}." OFFSET ".$param->{'offset'};
    }else{
	return "LIMIT ".$param->{'rows_count'};
    }
}

# Returns a character string corresponding to the expression to use in a query
# involving a date.
# IN: A ref to hash containing the following keys:
#	* 'mode'
# 	   authorized values:
#		- 'write': the sub returns the expression to use in 'INSERT' or 'UPDATE' queries
#		- 'read': the sub returns the expression to use in 'SELECT' queries
#	* 'target': the name of the field or the value to be used in the query
#
# OUT: the formatted date or undef if the date format mode is unknonw.
sub get_formatted_date {
    my $self = shift;
    my $param = shift;
    &Log::do_log('debug3','Building SQL date formatting');
    if (lc($param->{'mode'}) eq 'read' or lc($param->{'mode'}) eq 'write') {
	return $param->{'target'};
    }else {
	&Log::do_log('err',"Unknown date format mode %s", $param->{'mode'});
	return undef;
    }
}

# Checks whether a field is an autoincrement field or not.
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to test
# * 'table' : the name of the table to add
#
# OUT: Returns true if the field is an autoincrement field, false otherwise
sub is_autoinc {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    &Log::do_log('debug3','Checking whether field %s.%s is autoincremental',
		 $table, $field);

    my $type = $self->_get_field_type($table, $field);
    return undef unless $type;
    return $type =~ /\bAUTOINCREMENT\b/i or
	   $type =~ /^integer\s+PRIMARY\s+KEY\b/i;
}

# Defines the field as an autoincrement field
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to set
# * 'table' : the name of the table to add
#
# OUT: 1 if the autoincrement could be set, undef otherwise.
sub set_autoinc {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    &Log::do_log('debug3','Setting field %s.%s as autoincremental',
		 $table, $field);

    my $type = $self->_get_field_type($table, $field);
    return undef unless $type;

    my $r;
    my $pk;
    if ($type =~ /^integer\s+PRIMARY\s+KEY\b/i) {
	## INTEGER PRIMARY KEY is auto-increment.
	return 1;
    } elsif ($type =~ /\bPRIMARY\s+KEY\b/i) {
	$r = $self->_update_table($table,
				  qr(\b$field\s[^,]+),
				  "$field\tinteger PRIMARY KEY");
    } elsif ($pk = $self->get_primary_key({ 'table' => $table }) and
	     $pk->{$field} and scalar keys %$pk == 1) {
	$self->unset_primary_key({ 'table' => $table });
	$r = $self->_update_table($table,
				  qr(\b$field\s[^,]+),
				  "$field\tinteger PRIMARY KEY");
    } else {
	$r = $self->_update_table($table,
				  qr(\b$field\s[^,]+),
				  "$field\t$type AUTOINCREMENT");
    }

    unless ($r) {
	&Log::do_log('err','Unable to set field %s in table %s as autoincremental', $field, $table);
	return undef;
    }
    return 1;
}

# Returns the list of the tables in the database.
# Returns undef if something goes wrong.
#
# OUT: a ref to an array containing the list of the tables names in the database, undef if something went wrong
sub get_tables {
    my $self = shift;
    my @raw_tables;
    my @result;
    unless (@raw_tables = $self->{'dbh'}->tables()) {
	&Log::do_log('err','Unable to retrieve the list of tables from database %s',$self->{'db_name'});
	return undef;
    }
    
    foreach my $t (@raw_tables) {
	$t =~ s/^"main"\.//; # needed for SQLite 3
	$t =~ s/^.*\"([^\"]+)\"$/$1/;
	push @result, $t;
    }
    return \@result;
}

# Adds a table to the database
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table to add
#
# OUT: A character string report of the operation done or undef if something went wrong.
sub add_table {
    my $self = shift;
    my $param = shift;
    &Log::do_log('debug3','Adding table %s to database %s',$param->{'table'},$self->{'db_name'});
    unless ($self->do_query("CREATE TABLE %s (temporary INT)",$param->{'table'})) {
	&Log::do_log('err', 'Could not create table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    return sprintf "Table %s created in database %s", $param->{'table'}, $self->{'db_name'};
}

# Returns a ref to an hash containing the description of the fields in a table from the database.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table whose fields are requested.
#
# OUT: A hash in which:
#	* the keys are the field names
#	* the values are the field type
#	Returns undef if something went wrong.
#
sub get_fields {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $sth;
    my %result;
    unless ($sth = $self->do_query(q{PRAGMA table_info('%s')}, $table)) {
	&Log::do_log('err', 'Could not get the list of fields from table %s in database %s', $table, $self->{'db_name'});
	return undef;
    }
    while (my $field = $sth->fetchrow_hashref('NAME_lc')) {		
	# http://www.sqlite.org/datatype3.html
	my $type = $field->{'type'};
	if($type =~ /int/) {
	    $type = 'integer';
	} elsif ($type =~ /char|clob|text/) {
	    $type = 'text';
	} elsif ($type =~ /blob|none/) {
	    $type = 'none';
	} elsif ($type =~ /real|floa|doub/) {
	    $type = 'real';
	} else {
	    $type = 'numeric';
	}
	$result{$field->{'name'}} = $type;
    }
    return \%result;
}
# Changes the type of a field in a table from the database.
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to update
# * 'table' : the name of the table whose fields will be updated.
# * 'type' : the type of the field to add
# * 'notnull' : specifies that the field must not be null
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub update_field {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};
    my $type = $param->{'type'};
    my $options = '';
    if ($param->{'notnull'}) {
	$options .= ' NOT NULL';
    }
    my $report;

    &Log::do_log('debug3', 'Updating field %s in table %s (%s%s)',
		 $field, $table, $type, $options);
    my $r = $self->_update_table($table,
				 qr(\b$field\s[^,]+),
				 "$field\t$type$options");
    unless (defined $r) {
	&Log::do_log('err', 'Could not update field %s in table %s (%s%s)',
		     $field, $table, $type, $options);
	return undef;
    }
    $report = $r;
    &Log::do_log('info', '%s', $r);
    $report .= "\nTable $table, field $field updated";
    &Log::do_log('info', 'Table %s, field %s updated', $table, $field);

    return $report;
}

# Adds a field in a table from the database.
# IN: A ref to hash containing the following keys:
#	* 'field' : the name of the field to add
#	* 'table' : the name of the table where the field will be added.
#	* 'type' : the type of the field to add
#	* 'notnull' : specifies that the field must not be null
#	* 'autoinc' : specifies that the field must be autoincremental
#	* 'primary' : specifies that the field is a key
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub add_field {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};
    my $type = $param->{'type'};

    my $options = '';
    # To prevent "Cannot add a NOT NULL column with default value NULL" errors
    if ($param->{'primary'}) {
	$options .= ' PRIMARY KEY';
    }
    if ( $param->{'autoinc'}) {
	$options .= ' AUTOINCREMENT';
    }
    if ( $param->{'notnull'}) {
	$options .= ' NOT NULL';
    }
    &Log::do_log('debug3','Adding field %s in table %s (%s%s)',
		 $field, $table, $type, $options);

    my $report = '';

    if ($param->{'primary'}) {
	$report = $self->_update_table($table,
				       qr{[(]\s*},
				       "(\n\t $field\t$type$options,\n\t ");
	unless (defined $report) {
	    &Log::do_log('err', 'Could not add field %s to table %s in database %s', $field, $table, $self->{'db_name'});
	return undef;
    }
    } else { 
	unless ($self->do_query(
	    q{ALTER TABLE %s ADD %s %s%s},
	    $table, $field, $type, $options
	)) {
	    &Log::do_log('err', 'Could not add field %s to table %s in database %s', $field, $table, $self->{'db_name'});
	    return undef;
	}
	if ($self->_vernum <= 3.001003) {
	    unless ($self->do_query(q{VACUUM})) {
		&Log::do_log('err', 'Could not vacuum database %s',
			     $self->{'db_name'});
		return undef;
	    }
	}
    }

    $report .= "\n" if $report;
    $report .= sprintf 'Field %s added to table %s (%s%s)',
		       $field, $table, $type, $options;
    &Log::do_log('info', 'Field %s added to table %s (%s%s)',
		 $field, $table, $type, $options);

    return $report;
}

# Deletes a field from a table in the database.
# IN: A ref to hash containing the following keys:
#	* 'field' : the name of the field to delete
#	* 'table' : the name of the table where the field will be deleted.
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub delete_field {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};
    &Log::do_log('debug3','Deleting field %s from table %s', $field, $table);

    ## SQLite does not support removal of columns

    my $report = "Could not remove field $field from table $table since SQLite does not support removal of columns";
    &Log::do_log('info', '%s', $report);

    return $report;
}

# Returns the list fields being part of a table's primary key.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys are requested.
#
# OUT: A ref to a hash in which each key is the name of a primary key or undef if something went wrong.
#
sub get_primary_key {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    &Log::do_log('debug3','Getting primary key for table %s', $table);

    my %found_keys = ();

    my $sth;
    unless ($sth = $self->do_query(
	q{PRAGMA table_info('%s')},
	$table
    )) {
	&Log::do_log('err', 'Could not get field list from table %s in database %s', $table, $self->{'db_name'});
	return undef;
    }
    my $l;
    while ($l = $sth->fetchrow_hashref('NAME_lc')) {
	next unless $l->{'pk'};
	$found_keys{$l->{'name'}} = 1;
    }
    $sth->finish;

    return \%found_keys;
}

# Drops the primary key of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys must be dropped.
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub unset_primary_key {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $report;
    &Log::do_log('debug3', 'Removing primary key from table %s', $table);

    my $r = $self->_update_table($table,
				 qr{,\s*PRIMARY\s+KEY\s+[(][^)]+[)]},
				 '');
    unless (defined $r) {
	&Log::do_log('err', 'Could not remove primary key from table %s',
		     $table);
	return undef;
    }
    $report = $r;
    &Log::do_log('info', '%s', $r);
    $report .= "\nTable $table, PRIMARY KEY dropped";
    &Log::do_log('info', 'Table %s, PRIMARY KEY dropped', $table);

    return $report;
}

# Sets the primary key of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys must be defined.
#	* 'fields' : a ref to an array containing the names of the fields used in the key.
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub set_primary_key {
    my $self = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $fields = join ',',@{$param->{'fields'}};
    my $report;
    &Log::do_log('debug3', 'Setting primary key for table %s (%s)',
		 $table, $fields);

    my $r = $self->_update_table($table,
				 qr{\s*[)]\s*$},
				 ",\n\t PRIMARY KEY ($fields)\n )");
    unless (defined $r) {
	&Log::do_log('debug', 'Could not set primary key for table %s (%s)',
		     $table, $fields);
	return undef;
    }
    $report = $r;
    &Log::do_log('info', '%s', $r);
    $report .= "\nTable $table, PRIMARY KEY set on $fields";
    &Log::do_log('info', 'Table %s, PRIMARY KEY set on %s', $table, $fields);

    return $report;
}

# Returns a ref to a hash in which each key is the name of an index.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the indexes are requested.
#
# OUT: A ref to a hash in which each key is the name of an index. These key point to
#	a second level hash in which each key is the name of the field indexed.
#      Returns undef if something went wrong.
#
sub get_indexes {
    my $self = shift;
    my $param = shift;
    &Log::do_log('debug3','Looking for indexes in %s',$param->{'table'});

    my %found_indexes;
    my $sth;
    my $l;
    unless ($sth = $self->do_query(
	q{PRAGMA index_list('%s')},
	$param->{'table'}
    )) {
	&Log::do_log('err', 'Could not get the list of indexes from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    while($l = $sth->fetchrow_hashref('NAME_lc')) {
	next if $l->{'unique'};
	$found_indexes{$l->{'name'}} = {};
	}
    $sth->finish;

    foreach my $index_name (keys %found_indexes) {
	unless ($sth = $self->do_query(
	    q{PRAGMA index_info('%s')},
	    $index_name
	)) {
	    &Log::do_log('err', 'Could not get the list of indexes from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	    return undef;
    }
	while($l = $sth->fetchrow_hashref('NAME_lc')) {
	    $found_indexes{$index_name}{$l->{'name'}} = {};
	}
	$sth->finish;
    }

    return \%found_indexes;
}

# Drops an index of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the index must be dropped.
#	* 'index' : the name of the index to be dropped.
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub unset_index {
    my $self = shift;
    my $param = shift;
    &Log::do_log('debug3','Removing index %s from table %s',$param->{'index'},$param->{'table'});

    my $sth;
    unless ($sth = $self->do_query(
	q{DROP INDEX "%s"},
	$param->{'index'}
    )) {
	&Log::do_log('err', 'Could not drop index %s from table %s in database %s',$param->{'index'}, $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    my $report = "Table $param->{'table'}, index $param->{'index'} dropped";
    &Log::do_log('info', 'Table %s, index %s dropped', $param->{'table'},$param->{'index'});

    return $report;
}

# Sets an index in a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the index must be defined.
#	* 'fields' : a ref to an array containing the names of the fields used in the index.
#	* 'index_name' : the name of the index to be defined..
#
# OUT: A character string report of the operation done or undef if something went wrong.
#
sub set_index {
    my $self = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',',@{$param->{'fields'}};
    &Log::do_log('debug3', 'Setting index %s for table %s using fields %s', $param->{'index_name'},$param->{'table'}, $fields);
    unless ($sth = $self->do_query(
	q{CREATE INDEX %s ON %s (%s)},
	$param->{'index_name'}, $param->{'table'}, $fields
    )) {
	&Log::do_log('err', 'Could not add index %s using field %s for table %s in database %s', $fields, $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    my $report = "Table $param->{'table'}, index %s set using $fields";
    &Log::do_log('info', 'Table %s, index %s set using fields %s',$param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
}

############################################################################
## Overridden methods
############################################################################

## To prevent "database is locked" error, acquire "immediate" lock
## by each query.  All queries including "SELECT" need to lock in this
## manner.

sub do_query {
    my $self = shift;
    my $sth;
    my $rc;

    my $need_lock =
	($_[0] =~ /^\s*(ALTER|CREATE|DELETE|DROP|INSERT|REINDEX|REPLACE|UPDATE)\b/i);

    ## acquire "immediate" lock
    unless (! $need_lock or $self->{'dbh'}->begin_work) {
	&Log::do_log('err', 'Could not lock database: (%s) %s',
		     $self->{'dbh'}->err, $self->{'dbh'}->errstr);
	return undef;
    }

    ## do query
    $sth = $self->SUPER::do_query(@_);

    ## release lock
    return $sth unless $need_lock;
    eval {
	if ($sth) {
	    $rc = $self->{'dbh'}->commit;
	} else {
	    $rc = $self->{'dbh'}->rollback;
	}
    };
    if ($@ or ! $rc) {
	&Log::do_log('err', 'Could not unlock database: %s',
		     $@ || sprintf('(%s) %s', $self->{'dbh'}->err,
				   $self->{'dbh'}->errstr));
	return undef;
    }

    return $sth;
}

sub do_prepared_query {
    my $self = shift;
    my $sth;
    my $rc;

    my $need_lock =
	($_[0] =~ /^\s*(ALTER|CREATE|DELETE|DROP|INSERT|REINDEX|REPLACE|UPDATE)\b/i);

    ## acquire "immediate" lock
    unless (! $need_lock or $self->{'dbh'}->begin_work) {
	&Log::do_log('err', 'Could not lock database: (%s) %s',
		     $self->{'dbh'}->err, $self->{'dbh'}->errstr);
	return undef;
    }

    ## do query
    $sth = $self->SUPER::do_prepared_query(@_);

    ## release lock
    return $sth unless $need_lock;
    eval {
	if ($sth) {
	    $rc = $self->{'dbh'}->commit;
	} else {
	    $rc = $self->{'dbh'}->rollback;
	}
    };
    if ($@ or ! $rc) {
	&Log::do_log('err', 'Could not unlock database: %s',
		     $@ || sprintf('(%s) %s', $self->{'dbh'}->err,
				   $self->{'dbh'}->errstr));
	return undef;
    }

    return $sth;
}

## For BLOB types.
sub AS_BLOB {
    return ( { TYPE => DBI::SQL_BLOB() } => $_[1] )
	if scalar @_ > 1;
    return ();
}

############################################################################
## private methods
############################################################################

## get numified version of SQLite
sub _vernum {
    my $self = shift;
    return version->new('v' . $self->{'dbh'}->{'sqlite_version'})->numify;
}

## get raw type of column
sub _get_field_type {
    my $self = shift;
    my $table = shift;
    my $field = shift;

    my $sth;
    unless ($sth = $self->do_query(q{PRAGMA table_info('%s')}, $table)) {
	&Log::do_log('err', 'Could not get the list of fields from table %s in database %s', $table, $self->{'db_name'});
	return undef;
    }
    my $l;
    while ($l = $sth->fetchrow_hashref('NAME_lc')) {
	if (lc $l->{'name'} eq lc $field) {
	    $sth->finish;
	    return $l->{'type'};
	}
    }
    $sth->finish;

    &Log::do_log('err', 'Could not gather information of field %s from table %s in database %s', $field, $table, $self->{'db_name'});
    return undef;
}

## update table structure
## old table will be saved as "<table name>_<YYmmddHHMMSS>_<PID>".
sub _update_table {
    my $self = shift;
    my $table = shift;
    my $regex = shift;
    my $replacement = shift;
    my $statement;
    my $table_saved = sprintf '%s_%s_%d', $table,
			      POSIX::strftime("%Y%m%d%H%M%S", gmtime $^T),
			      $$;
    my $report;

    ## create temporary table with new structure
    $statement = $self->_get_create_table($table);
    unless (defined $statement) {
	&Log::do_log('err', 'Table \'%s\' does not exist', $table);
	return undef;
    }
    $statement=~ s/^\s*CREATE\s+TABLE\s+([\"\w]+)/CREATE TABLE ${table_saved}_new/;
    $statement =~ s/$regex/$replacement/;
    my $s = $statement; $s =~ s/\n\s*/ /g; $s =~ s/\t/ /g;
    &Log::do_log('info', '%s', $s);
    unless ($self->do_query('%s', $statement)) {
	&Log::do_log('err', 'Could not create temporary table \'%s_new\'',
		     $table_saved);
	return undef;
    }

    &Log::do_log('info', 'Copy \'%s\' to \'%s_new\'', $table, $table_saved);
    ## save old table
    my $indexes = $self->get_indexes({ 'table' => $table });
    unless (defined $self->_copy_table($table, "${table_saved}_new") and
	    defined $self->_rename_or_drop_table($table, $table_saved) and
	    defined $self->_rename_table("${table_saved}_new", $table)) {
	return undef;
    }
    ## recreate indexes
    foreach my $name (keys %{$indexes || {}}) {
	unless (defined $self->unset_index(
		    { 'table' => "${table_saved}_new", 'index' => $name }) and
		defined $self->set_index(
		    { 'table' => $table, 'index_name' => $name,
		      'fields' => [ sort keys %{$indexes->{$name}} ] })
	) {
	    return undef;
	}
    }

    $report = "Old table was saved as \'$table_saved\'";
    return $report;
}

## Get SQL statement by which table was created.
sub _get_create_table {
    my $self = shift;
    my $table = shift;
    my $sth;

    unless ($sth = $self->do_query(
	q{SELECT sql
	  FROM sqlite_master
	  WHERE type = 'table' AND name = '%s'},
	$table
    )) {
	&Log::do_log('Could not get table \'%s\' on database \'%s\'',
		     $table, $self->{'db_name'});
	return undef;
    }
    my $sql = $sth->fetchrow_array();
    $sth->finish;

    return $sql || undef;
}

## copy table content to another table
## target table must have all columns source table has.
sub _copy_table {
    my $self = shift;
    my $table = shift;
    my $table_new = shift;
    return undef unless defined $table and defined $table_new;

    my $fields = join ', ',
		      sort keys %{$self->get_fields({ 'table' => $table })};

    my $sth;
    unless ($sth = $self->do_query(
	q{INSERT INTO "%s" (%s) SELECT %s FROM "%s"},
	$table_new, $fields, $fields, $table
    )) {
	&Log::do_log('err', 'Could not copy talbe \'%s\' to temporary table \'%s_new\'', $table, $table_new);
	return undef;
    }

    return 1;
}

## rename table
## if target already exists, do nothing and return 0.
sub _rename_table {
    my $self = shift;
    my $table = shift;
    my $table_new = shift;
    return undef unless defined $table and defined $table_new;

    if ($self->_get_create_table($table_new)) {
	return 0;
    }
    unless ($self->do_query(
	q{ALTER TABLE %s RENAME TO %s},
	$table, $table_new
    )) {
	&Log::do_log('err', 'Could not rename table \'%s\' to \'%s\'',
		     $table, $table_new);
	return undef;
    }
    return 1;
}

## rename table
## if target already exists, drop source table.
sub _rename_or_drop_table {
    my $self = shift;
    my $table = shift;
    my $table_new = shift;

    my $r = $self->_rename_table($table, $table_new);
    unless (defined $r) {
	return undef;
    } elsif ($r) {
	return $r;
    } else {
	unless ($self->do_query(q{DROP TABLE "%s"}, $table)) {
	    &Log::do_log('err', 'Could not drop table \'%s\'', $table);
	    return undef;
	}
	return 0;
    }
}

1;
