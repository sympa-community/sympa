# DBManipulatorPostgres.pm - This module contains the code specific to using a Postgres server.
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

package DBManipulatorPostgres;

use strict;

use Carp;
use Log;

use DefaultDBManipulator;

our @ISA = qw(DefaultDBManipulator);

our %date_format = (
		   'read' => {
		       'Pg' => 'date_part(\'epoch\',%s)',
		       },
		   'write' => {
		       'Pg' => '\'epoch\'::timestamp with time zone + \'%d sec\'',
		       }
	       );

sub build_connect_string{
    my $self = shift;
    $self->{'connect_string'} = "DBI:Pg:dbname=$self->{'db_name'};host=$self->{'db_host'}";
}

## Returns an SQL clause to be inserted in a query.
## This clause will compute a substring of max length
## $param->{'substring_length'} starting from the first character equal
## to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self = shift;
    my $param = shift;
    return "SUBSTRING(".$param->{'source_field'}." FROM position('".$param->{'separator'}."' IN ".$param->{'source_field'}.") FOR ".$param->{'substring_length'}.")";
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

## Returns 1 if the field is an autoincrement field.
## Takes a hash as argument which can contain the following keys:
## * 'field' : the name of the field to test
## * 'table' : the name of the table to add
##
sub is_autoinc {
    my $self = shift;
    my $param = shift;
    my $seqname = $param->{'table'}.'_'.$param->{'field'}.'_seq';
    my $sth;
    unless ($sth = $self->do_query("SELECT relname FROM pg_class WHERE relname = '%s' AND relkind = 'S'  AND relnamespace IN ( SELECT oid  FROM pg_namespace WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema' )",$seqname)) {
	do_log('err','Unable to gather autoincrement field named %s for table %s',$param->{'field'},$param->{'table'});
	return undef;
    }	    
    my $field = $sth->fetchrow();	    
    return ($ref->{'field'} eq $seqname);
}

## Defines the field as an autoincrement field
## Takes a hash as argument which must contain the following key:
## * 'field' : the name of the field to set
## * 'table' : the name of the table to add
##
sub set_autoinc {
    my $self = shift;
    my $param = shift;
    my $seqname = $param->{'table'}.'_'.$param->{'field'}.'_seq';
    unless ($self->do_query("CREATE SEQUENCE %s",$seqname)) {
	do_log('err','Unable to create sequence %s',$seqname);
	return undef;
    }
    unless ($self->do_query("ALTER TABLE `%s` CHANGE `$field` `%s` BIGINT( 20 ) NOT NULL AUTO_INCREMENT",$param->{'table'},$param->{'field'})) {
	do_log('err','Unable to set field %s in table %s as autoincrement',$param->{'field'},$param->{'table'});
	return undef;
    }
    unless ($self->do_query("ALTER TABLE %s ALTER COLUMN %s SET DEFAULT NEXTVAL('%s')",$param->{'table'},$param->{'field'},$seqname)) {
	do_log('err','Unable to set sequence %s as value for field %s, table %s',$seqname,$param->{'field'},$param->{'table'});
	return undef;
    }
    return 1;
 }

## Returns a ref to an array containing the list of tables in the database.
## Returns undef if something goes wrong.
##
sub get_tables {
    my $self = shift;
}

## Adds a table to the database
## Takes a hash as argument which must contain the following key:
## * 'table' : the name of the table to add
##
## Returns 1 if the table add worked, undef otherwise
sub add_table {
    my $self = shift;
    my $param = shift;
}

## Returns a ref to an array containing the names of the fields in a table from the database.
## Takes a hash as argument which must contain the following key:
## * 'table' : the name of the table whose fields are requested.
##
sub get_fields {
    my $self = shift;
    my $param = shift;
}

## Changes the type of a field in a table from the database.
## Takes a hash as argument which must contain the following keys:
## * 'field' : the name of the field to update
## * 'table' : the name of the table whose fields will be updated.
##
sub update_field {
    my $self = shift;
    my $param = shift;
}

## Adds a field in a table from the database.
## Takes a hash as argument which must contain the following keys:
## * 'field' : the name of the field to add
## * 'table' : the name of the table where the field will be added.
##
sub add_field {
    my $self = shift;
    my $param = shift;
}

return 1;
