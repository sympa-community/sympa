# DBManipulatorMySQL.pm - This module contains the code specific to using a MySQL server.
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

package DBManipulatorMySQL;

use strict;
use Data::Dumper;

use Carp;
use Log;

use DBManipulatorDefault;

our @ISA = qw(DBManipulatorDefault);

# Builds the string to be used by the DBI to connect to the database.
#
# IN: Nothing
#
# OUT: Nothing
sub build_connect_string {
    my $self = shift;
    &Log::do_log('debug','Building connection string to database %s',$self->{'db_name'});
    $self->{'connect_string'} = "DBI:$self->{'db_type'}:$self->{'db_name'}:$self->{'db_host'}";
}

# Returns an SQL clause to be inserted in a query.
# This clause will compute a substring of max length
# $param->{'substring_length'} starting from the first character equal
# to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self = shift;
    my $param = shift;
    &Log::do_log('debug','Building substring caluse');
    return "REVERSE(SUBSTRING(".$param->{'source_field'}." FROM position('".$param->{'separator'}."' IN ".$param->{'source_field'}.") FOR ".$param->{'substring_length'}."))";
}

# Returns an SQL clause to be inserted in a query.
# This clause will limit the number of records returned by the query to
# $param->{'rows_count'}. If $param->{'offset'} is provided, an offset of
# $param->{'offset'} rows is done from the first record before selecting
# the rows to return.
sub get_limit_clause {
    my $self = shift;
    my $param = shift;
    &Log::do_log('debug','Building limit 1 caluse');
    if ($param->{'offset'}) {
	return "LIMIT ".$param->{'offset'}.",".$param->{'rows_count'};
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
    &Log::do_log('debug','Building SQL date formatting');
    if (lc($param->{'mode'}) eq 'read') {
	return sprintf 'UNIX_TIMESTAMP(%s)',$param->{'target'};
    }elsif(lc($param->{'mode'}) eq 'write') {
	return sprintf 'FROM_UNIXTIME(%d)',$param->{'target'};
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
    &Log::do_log('debug','Checking whether field %s.%s is autoincremental',$param->{'field'},$param->{'table'});
    my $sth;
    unless ($sth = $self->do_query("SHOW FIELDS FROM `%s` WHERE Extra ='auto_increment' and Field = '%s'",$param->{'table'},$param->{'field'})) {
	do_log('err','Unable to gather autoincrement field named %s for table %s',$param->{'field'},$param->{'table'});
	return undef;
    }	    
    my $ref = $sth->fetchrow_hashref('NAME_lc') ;
    return ($ref->{'field'} eq $param->{'field'});
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
    &Log::do_log('debug','Setting field %s.%s as autoincremental',$param->{'field'},$param->{'table'});
    unless ($self->do_query("ALTER TABLE `%s` CHANGE `%s` `%s` BIGINT( 20 ) NOT NULL AUTO_INCREMENT",$param->{'table'},$param->{'field'},$param->{'field'})) {
	do_log('err','Unable to set field %s in table %s as autoincrement',$param->{'field'},$param->{'table'});
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
    &Log::do_log('debug','Retrieving all tables in database %s',$self->{'db_name'});
    my @raw_tables;
    my @result;
    unless (@raw_tables = $self->{'dbh'}->tables()) {
	&Log::do_log('err','Unable to retrieve the list of tables from database %s',$self->{'db_name'});
	return undef;
    }
    
    foreach my $t (@raw_tables) {
	$t =~ s/^\`[^\`]+\`\.//;# Clean table names that would look like `databaseName`.`tableName` (mysql)
	$t =~ s/^\`(.+)\`$/$1/;# Clean table names that could be surrounded by `` (recent DBD::mysql release)
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
    &Log::do_log('debug','Adding table %s to database %s',$param->{'table'},$self->{'db_name'});
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
    &Log::do_log('debug','Getting fields list from table %s in database %s',$param->{'table'},$self->{'db_name'});
    my $sth;
    my %result;
    unless ($sth = $self->do_query("SHOW FIELDS FROM %s",$param->{'table'})) {
	&Log::do_log('err', 'Could not get the list of fields from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {		
	$result{$ref->{'field'}} = $ref->{'type'};
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
    &Log::do_log('debug','Updating field %s in table %s (%s, %s)',$param->{'field'},$param->{'table'},$param->{'type'},$param->{'notnull'});
    my $options;
    if ($param->{'notnull'}) {
	$options .= ' NOT NULL ';
    }
    my $report = sprintf("ALTER TABLE %s CHANGE %s %s %s %s",$param->{'table'},$param->{'field'},$param->{'field'},$param->{'type'},$options);
    &Log::do_log('notice', "ALTER TABLE %s CHANGE %s %s %s %s",$param->{'table'},$param->{'field'},$param->{'field'},$param->{'type'},$options);
    unless ($self->do_query("ALTER TABLE %s CHANGE %s %s %s %s",$param->{'table'},$param->{'field'},$param->{'field'},$param->{'type'},$options)) {
	&Log::do_log('err', 'Could not change field \'%s\' in table\'%s\'.',$param->{'field'}, $param->{'table'});
	return undef;
    }
    $report .= sprintf('\nField %s in table %s, structure updated', $param->{'field'}, $param->{'table'});
    &Log::do_log('info', 'Field %s in table %s, structure updated', $param->{'field'}, $param->{'table'});
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
    &Log::do_log('debug','Adding field %s in table %s (%s, %s, %s, %s)',$param->{'field'},$param->{'table'},$param->{'type'},$param->{'notnull'},$param->{'autoinc'},$param->{'primary'});
    my $options;
    # To prevent "Cannot add a NOT NULL column with default value NULL" errors
    if ($param->{'notnull'}) {
	$options .= 'NOT NULL ';
    }
    if ( $param->{'autoinc'}) {
	$options .= ' AUTO_INCREMENT ';
    }
    if ( $param->{'primary'}) {
	$options .= ' PRIMARY KEY ';
    }
    unless ($self->do_query("ALTER TABLE %s ADD %s %s %s",$param->{'table'},$param->{'field'},$param->{'type'},$options)) {
	&Log::do_log('err', 'Could not add field %s to table %s in database %s', $param->{'field'}, $param->{'table'}, $self->{'db_name'});
	return undef;
    }

    my $report = sprintf('Field %s added to table %s (options : %s)', $param->{'field'}, $param->{'table'}, $options);
    &Log::do_log('info', 'Field %s added to table %s  (options : %s)', $param->{'field'}, $param->{'table'}, $options);
    
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
    &Log::do_log('debug','Deleting field %s from table %s',$param->{'field'},$param->{'table'});

    unless ($self->do_query("ALTER TABLE %s DROP COLUMN `%s`",$param->{'table'},$param->{'field'})) {
	&Log::do_log('err', 'Could not delete field %s from table %s in database %s', $param->{'field'}, $param->{'table'}, $self->{'db_name'});
	return undef;
    }

    my $report = sprintf('Field %s removed from table %s', $param->{'field'}, $param->{'table'});
    &Log::do_log('info', 'Field %s removed from table %s', $param->{'field'}, $param->{'table'});
    
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
    &Log::do_log('debug','Getting primary key for table %s',$param->{'table'});

    my %found_keys;
    my $sth;
    unless ($sth = $self->do_query("SHOW COLUMNS FROM %s",$param->{'table'})) {
	&Log::do_log('err', 'Could not get field list from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }

    my $test_request_result = $sth->fetchall_hashref('field');
    foreach my $scannedResult ( keys %$test_request_result ) {
	if ( $test_request_result->{$scannedResult}{'key'} eq "PRI" ) {
	    $found_keys{$scannedResult} = 1;
	}
    }
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
    &Log::do_log('debug','Removing primary key from table %s',$param->{'table'});

    my $sth;
    unless ($sth = $self->do_query("ALTER TABLE %s DROP PRIMARY KEY",$param->{'table'})) {
	&Log::do_log('err', 'Could not drop primary key from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    my $report = "Table $param->{'table'}, PRIMARY KEY dropped";
    &Log::do_log('info', 'Table %s, PRIMARY KEY dropped', $param->{'table'});

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

    my $sth;
    my $fields = join ',',@{$param->{'fields'}};
    &Log::do_log('debug','Setting primary key for table %s (%s)',$param->{'table'},$fields);
    unless ($sth = $self->do_query("ALTER TABLE %s ADD PRIMARY KEY (%s)",$param->{'table'}, $fields)) {
	&Log::do_log('err', 'Could not set fields %s as primary key for table %s in database %s', $fields, $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    my $report = "Table $param->{'table'}, PRIMARY KEY set on $fields";
    &Log::do_log('info', 'Table %s, PRIMARY KEY set on %s', $param->{'table'},$fields);
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
    &Log::do_log('debug','Looking for indexes in %s',$param->{'table'});

    my %found_indexes;
    my $sth;
    unless ($sth = $self->do_query("SHOW INDEX FROM %s",$param->{'table'})) {
	&Log::do_log('err', 'Could not get the list of indexes from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    my $index_part;
    while($index_part = $sth->fetchrow_hashref('NAME_lc')) {
	if ( $index_part->{'key_name'} ne "PRIMARY" ) {
	    my $index_name = $index_part->{'key_name'};
	    my $field_name = $index_part->{'column_name'};
	    $found_indexes{$index_name}{$field_name} = 1;
	}
    }
    open TMP, ">>/tmp/toto"; print TMP &Dumper(\%found_indexes); close TMP;
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
    &Log::do_log('debug','Removing index %s from table %s',$param->{'index'},$param->{'table'});

    my $sth;
    unless ($sth = $self->do_query("ALTER TABLE %s DROP INDEX %s",$param->{'table'},$param->{'index'})) {
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
    &Log::do_log('debug', 'Setting index %s for table %s using fields %s', $param->{'index_name'},$param->{'table'}, $fields);
    unless ($sth = $self->do_query("ALTER TABLE %s ADD INDEX %s (%s)",$param->{'table'}, $param->{'index_name'}, $fields)) {
	&Log::do_log('err', 'Could not add index %s using field %s for table %s in database %s', $fields, $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    my $report = "Table $param->{'table'}, index %s set using $fields";
    &Log::do_log('info', 'Table %s, index %s set using fields %s',$param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
}

return 1;
