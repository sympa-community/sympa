# DBManipulatorDefault.pm - This module contains default manipulation functions.
# they are used if not defined in the DBManipulator<*> subclasses.
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

package DBManipulatorDefault;

use strict;

use Carp;
use Log;

use Datasource;

our @ISA = qw(Datasource);

sub build_connect_string {
    my $self = shift;
    $self->{'connect_string'} = "DBI:$self->{'db_type'}:$self->{'db_name'}:$self->{'db_host'}";
}

## Returns an SQL clause to be inserted in a query.
## This clause will compute a substring of max length
## $param->{'substring_length'} starting from the first character equal
## to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self = shift;
    my $param = shift;
    return "REVERSE(SUBSTRING(".$param->{'source_field'}." FROM position('".$param->{'separator'}."' IN ".$param->{'source_field'}.") FOR ".$param->{'substring_length'}."))";
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
	return "LIMIT ".$param->{'offset'}.",".$param->{'rows_count'};
    }else{
	return "LIMIT ".$param->{'rows_count'};
    }
}

## Returns a character string corresponding to the expression to use in a query
## involving a date.
## Takes a hash as argument which can contain the following keys:
## * 'mode'
##   authorized values:
##	- 'write': the sub returns the expression to use in 'INSERT' or 'UPDATE' queries
##	- 'read': the sub returns the expression to use in 'SELECT' queries
## * 'target': the name of the field or the value to be used in the query
##
sub get_formatted_date {
    my $self = shift;
    my $param = shift;
    if (lc($param->{'mode'}) eq 'read') {
	return sprintf 'UNIX_TIMESTAMP(%s)',$param->{'target'};
    }elsif(lc($param->{'mode'}) eq 'write') {
	return sprintf 'FROM_UNIXTIME(%d)',$param->{'target'};
    }else {
	&Log::do_log('err',"Unknown date format mode %s", $param->{'mode'});
	return undef;
    }
}

## Returns 1 if the field is an autoincrement field.
## Takes a hash as argument which can contain the following keys:
## * 'field' : the name of the field to test
## * 'table' : the name of the table to add
##
sub is_autoinc {
    my $self = shift;
    my $param = shift;
    my $sth;
    unless ($sth = $self->do_query("SHOW FIELDS FROM `%s` WHERE Extra ='auto_increment' and Field = '%s'",$param->{'table'},$param->{'field'})) {
	do_log('err','Unable to gather autoincrement field named %s for table %s',$param->{'field'},$param->{'table'});
	return undef;
    }	    
    my $ref = $sth->fetchrow_hashref('NAME_lc') ;
    return ($ref->{'field'} eq $param->{'field'});
}

## Defines the field as an autoincrement field
## Takes a hash as argument which must contain the following key:
## * 'field' : the name of the field to set
## * 'table' : the name of the table to add
##
sub set_autoinc {
    my $self = shift;
    my $param = shift;
    unless ($self->do_query("ALTER TABLE `%s` CHANGE `%s` `%s` BIGINT( 20 ) NOT NULL AUTO_INCREMENT",$param->{'table'},$param->{'field'},$param->{'field'})) {
	do_log('err','Unable to set field %s in table %s as autoincrement',$param->{'field'},$param->{'table'});
	return undef;
    }
    return 1;
}

## Returns a ref to an array containing the list of tables in the database.
## Returns undef if something goes wrong.
##
sub get_tables {
    my $self = shift;
    my @raw_tables;
    my @result;
    unless (@raw_tables = $self->{'dbh'}->tables()) {
	&Log::do_log('err','Unable to retrieve the list of tables from database %s',$self->{'db_name'});
	return undef;
    }
    
    foreach my $t (@raw_tables) {
	$t =~ s/^\`[^\`]+\`\.//;## Clean table names that would look like `databaseName`.`tableName` (mysql)
	$t =~ s/^\`(.+)\`$/$1/;## Clean table names that could be surrounded by `` (recent DBD::mysql release)
	push @result, $t;
    }
    return \@result;
}

## Adds a table to the database
## Takes a hash as argument which must contain the following key:
## * 'table' : the name of the table to add
##
## Returns a report if the table adding worked, undef otherwise
sub add_table {
    my $self = shift;
    my $param = shift;
    unless ($self->do_query("CREATE TABLE %s (temporary INT)",$param->{'table'})) {
	&do_log('err', 'Could not create table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;;
    }
    return sprintf "Table %s created in database %s", $param->{'table'}, $self->{'db_name'};
}

## Returns a ref to an hash containing the description of the fields in a table from the database.
## Takes a hash as argument which must contain the following key:
## * 'table' : the name of the table whose fields are requested.
##
sub get_fields {
    my $self = shift;
    my $param = shift;
    my $sth;
    my %result;
    unless ($sth = $self->do_query("SHOW FIELDS FROM %s",$param->{'table'})) {
	&do_log('err', 'Could not get the list of fields from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {		
	$result{$ref->{'field'}} = $ref->{'type'};
    }
    return \%result;
}

## Changes the type of a field in a table from the database.
## Takes a hash as argument which must contain the following keys:
## * 'field' : the name of the field to update
## * 'table' : the name of the table whose fields will be updated.
## * 'type' : the type of the field to add
## * 'notnull' : specifies that the field must not be null
##
sub update_field {
    my $self = shift;
    my $param = shift;
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

## Adds a field in a table from the database.
## Takes a hash as argument which must contain the following keys:
## * 'field' : the name of the field to add
## * 'table' : the name of the table where the field will be added.
## * 'type' : the type of the field to add
## * 'notnull' : specifies that the field must not be null
## * 'autoinc' : specifies that the field must be autoincremental
## * 'primary' : specifies that the field is a key
##
sub add_field {
    my $self = shift;
    my $param = shift;
    my $options;
    ## To prevent "Cannot add a NOT NULL column with default value NULL" errors
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
	&do_log('err', 'Could not field %s to table %s in database %s', $param->{'field'}, $param->{'table'}, $self->{'db_name'});
	return undef;
    }

    my $report = sprintf('Field %s added to table %s (options : %s)', $param->{'field'}, $param->{'table'}, $options);
    &Log::do_log('info', 'Field %s added to table %s  (options : %s)', $param->{'field'}, $param->{'table'}, $options);
    
    return $report;
}

return 1;
