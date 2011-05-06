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

use Carp;
use Log;

use DBManipulatorDefault;

our @ISA = qw(DBManipulatorDefault);

our %date_format = (
		   'read' => {
		       'SQLite' => 'strftime(\'%%s\',%s,\'utc\')'
		       },
		   'write' => {
		       'SQLite' => 'datetime(%d,\'unixepoch\',\'localtime\')'
		       }
	       );

sub build_connect_string{
    my $self = shift;
    $self->{'connect_string'} = "DBI:SQLite:dbname=$self->{'db_name'}";
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

## Returns 1 if the field is an autoincrement field.
## Takes a hash as argument which can contain the following keys:
## * 'field' : the name of the field to test
## * 'table' : the name of the table to add
##
sub is_autoinc {
    my $self = shift;
    my $param = shift;
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
    my $sth;
    my %result;
    unless ($sth = $self->do_query("PRAGMA table_info(%s)",$param->{'table'})) {
	&do_log('err', 'Could not get the list of fields from table %s in database %s', $param->{'table'}, $self->{'db_name'});
	return undef;
    }
    while (my $field = $sth->fetchrow_arrayref('NAME_lc')) {		
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
	$result{$field->[1]} = $field->[2];
    }
    return \%result;
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
