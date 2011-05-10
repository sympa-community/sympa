# DBManipulatorOracle.pm - This module contains the code specific to using a Oracle server.
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

package DBManipulatorOracle;

use strict;
use Data::Dumper;

use Carp;
use Log;

use DBManipulatorDefault;

our @ISA = qw(DBManipulatorDefault);

#######################################################
####### Beginning the RDBMS-specific code. ############
#######################################################

our %date_format = (
		   'read' => {
		       'Oracle' => '((to_number(to_char(%s,\'J\')) - to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) * 86400) +to_number(to_char(%s,\'SSSSS\'))',
		       },
		   'write' => {
		       'Oracle' => 'to_date(to_char(round(%s/86400) + to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) || \':\' ||to_char(mod(%s,86400)), \'J:SSSSS\')',
		       }
	       );

sub build_connect_string{
    my $self = shift;
	$self->{'connect_string'} = "DBI:Oracle:";
	if ($self->{'db_host'} && $self->{'db_name'}) {
	    $self->{'connect_string'} .= "host=$self->{'db_host'};sid=$self->{'db_name'}";
	}
}

## Returns an SQL clause to be inserted in a query.
## This clause will compute a substring of max length
## $param->{'substring_length'} starting from the first character equal
## to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self = shift;
    my $param = shift;
    return "substr(".$param->{'source_field'}.",instr(".$param->{'source_field'}.",'".$param->{'separator'}."')+1)";
}

## Returns an SQL clause to be inserted in a query.
## This clause will limit the number of records returned by the query to
## $param->{'rows_count'}. If $param->{'offset'} is provided, an offset of
## $param->{'offset'} rows is done from the first record before selecting
## the rows to return.
sub get_limit_clause {
    my $self = shift;
    my $param = shift;
    return "";
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
    return 0;
}

## Defines the field as an autoincrement field
## Takes a hash as argument which must contain the following key:
## * 'field' : the name of the field to set
## * 'table' : the name of the table to add
##
sub set_autoinc {
    my $self = shift;
    my $param = shift;
}

## Returns a ref to an array containing the list of tables in the database.
## Returns undef if something goes wrong.
##
sub get_tables {
    my $self = shift;
    my @raw_tables;
    my $sth;
    unless ($sth = $self->do_query("SELECT table_name FROM user_tables")) {
	&Log::do_log('err','Unable to retrieve the list of tables from database %s',$self->{'db_name'});
	return undef;
    }
    while (my $table= $sth->fetchrow()) {
	push @raw_tables, lc ($table);   	
    }
    return \@raw_tables;
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
