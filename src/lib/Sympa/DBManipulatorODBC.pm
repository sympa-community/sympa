# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Sympa::DBManipulatorODBC;

use strict;
use warnings;

use Log;

use base qw(Sympa::DBManipulatorDefault);

# Builds the string to be used by the DBI to connect to the database.
#
# IN: Nothing
#
# OUT: Nothing
sub build_connect_string {
    my $self = shift;
    Log::do_log('debug', 'Building connection string to database %s',
        $self->{'db_name'});
    $self->{'connect_string'} =
        "DBI:$self->{'db_type'}:$self->{'db_name'}";
}

# Returns an SQL clause to be inserted in a query.
# This clause will compute a substring of max length
# $param->{'substring_length'} starting from the first character equal
# to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self  = shift;
    my $param = shift;

    die 'not yet implemented: This is required by Sympa';
}

# Returns a character string corresponding to the expression to use in a query
# involving a date.
# IN: A ref to hash containing the following keys:
#	* 'mode'
# 	   authorized values:
#		- 'write': the sub returns the expression to use in 'INSERT'
#		or 'UPDATE' queries
#		- 'read': the sub returns the expression to use in 'SELECT' queries
#	* 'target': the name of the field or the value to be used in the query
#
# OUT: the formatted date or undef if the date format mode is unknonw.
sub get_formatted_date {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented: This is required by Sympa';
}

# Checks whether a field is an autoincrement field or not.
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to test
# * 'table' : the name of the table to add
#
# OUT: Returns true if the field is an autoincrement field, false otherwise
sub is_autoinc {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Defines the field as an autoincrement field
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to set
# * 'table' : the name of the table to add
#
# OUT: 1 if the autoincrement could be set, undef otherwise.
sub set_autoinc {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Returns the list of the tables in the database.
# Returns undef if something goes wrong.
#
# OUT: a ref to an array containing the list of the tables names in the
# database, undef if something went wrong
sub get_tables {
    my $self = shift;

    die 'Not yet implemented';
}

# Adds a table to the database
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table to add
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
sub add_table {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemeneted';
}

# Returns a ref to an hash containing the description of the fields in a table
# from the database.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table whose fields are requested.
#
# OUT: A hash in which:
#	* the keys are the field names
#	* the values are the field type
#	Returns undef if something went wrong.
#
sub get_fields {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Changes the type of a field in a table from the database.
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to update
# * 'table' : the name of the table whose fields will be updated.
# * 'type' : the type of the field to add
# * 'notnull' : specifies that the field must not be null
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub update_field {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
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
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub add_field {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Deletes a field from a table in the database.
# IN: A ref to hash containing the following keys:
#	* 'field' : the name of the field to delete
#	* 'table' : the name of the table where the field will be deleted.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub delete_field {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Returns the list fields being part of a table's primary key.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys are requested.
#
# OUT: A ref to a hash in which each key is the name of a primary key or undef
# if something went wrong.
#
sub get_primary_key {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Drops the primary key of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys must be
#	dropped.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub unset_primary_key {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Sets the primary key of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys must be
#	defined.
#	* 'fields' : a ref to an array containing the names of the fields used
#	in the key.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub set_primary_key {
    my $self  = shift;
    my $param = shift;

    die 'Not yet impelemented';
}

# Returns a ref to a hash in which each key is the name of an index.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the indexes are requested.
#
# OUT: A ref to a hash in which each key is the name of an index. These key
# point to
#	a second level hash in which each key is the name of the field indexed.
#      Returns undef if something went wrong.
#
sub get_indexes {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Drops an index of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the index must be dropped.
#	* 'index' : the name of the index to be dropped.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub unset_index {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# Sets an index in a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the index must be defined.
#	* 'fields' : a ref to an array containing the names of the fields used
#	in the index.
#	* 'index_name' : the name of the index to be defined..
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub set_index {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

# For DOUBLE type.
sub AS_DOUBLE {
    return ({'TYPE' => DBI::SQL_DOUBLE()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
