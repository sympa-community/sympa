# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::DatabaseDriver;

use strict;
use warnings;

use Log;

use base qw(Sympa::Datasource::SQL);

############################
#### Section containing generic functions          #
#### without anything related to a specific RDBMS. #
############################

# Returns the primary keys for all the tables in the database.
#
# IN: Nothing. Uses all the tables found in the databse of the SQLSource.
#
# OUT: - Returns a ref to a two level-hash:
#	* The keys of the first level are the database's tables name.
#	* The keys of the second level are the name of the primary keys for
#	the table whose name is
# 	  given by the first level key.
#      - Returns undef if something went wrong.
sub get_all_primary_keys {
    my $self = shift;
    Log::do_log('debug', 'Retrieving all primary keys in database %s',
        $self->{'db_name'});
    my %found_keys = undef;
    foreach my $table (@{$self->get_tables()}) {
        unless ($found_keys{$table} =
            $self->get_primary_key({'table' => $table})) {
            Log::do_log('err',
                'Primary key retrieval for table %s failed. Aborting',
                $table);
            return undef;
        }
    }
    return \%found_keys;
}

# Returns the indexes for all the tables in the database.
#
# IN: Nothing. Uses all the tables found in the databse of the SQLSource.
#
# OUT: - Returns a ref to a two level-hash:
#	* The keys of the first level are the database's tables name.
#	* The keys of the second level are the name of the indexes for the
#	table whose name is
# 	  given by the first level key.
#      - Returns undef if something went wrong.
sub get_all_indexes {
    my $self = shift;
    Log::do_log('debug', 'Retrieving all indexes in database %s',
        $self->{'db_name'});
    my %found_indexes;
    foreach my $table (@{$self->get_tables()}) {
        unless ($found_indexes{$table} =
            $self->get_indexes({'table' => $table})) {
            Log::do_log('err',
                'Index retrieval for table %s failed. Aborting', $table);
            return undef;
        }
    }
    return \%found_indexes;
}

# Checks the compliance of a key of a table compared to what it is supposed to
# reference.
#
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which we want to check the primary key
#	* 'key_name' : the kind of key tested:
#		- if the value is 'primary', the key tested will be the table primary key
#		- for any other value, the index whose name is this value will be tested.
#	* 'expected_keys' : A ref to an array containing the list of fields that we
#	   expect to be part of the key.
#
# OUT: - Returns a ref likely to contain the following values:
#	* 'empty': if this key is defined, then no key was found for the table
#	* 'existing_key_correct': if this key's value is 1, then a key
#	   exists and is fair to the structure defined in the 'expected_keys'
#	   parameter hash.
#	   Otherwise, the key is not correct.
#	* 'missing_key': if this key is defined, then a part of the key was missing.
#	   The value associated to this key is a hash whose keys are the names
#	   of the fields
#	   missing in the key.
#	* 'unexpected_key': if this key is defined, then we found fields in
#	the actual
#	   key that don't belong to the list provided in the 'expected_keys'
#	   parameter hash.
#	   The value associated to this key is a hash whose keys are the names
#	   of the fields
#	   unexpectedely found.
sub check_key {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Checking %s key structure for table %s',
        $param->{'key_name'}, $param->{'table'});
    my $keysFound;
    my $result;
    if (lc($param->{'key_name'}) eq 'primary') {
        return undef
            unless ($keysFound =
            $self->get_primary_key({'table' => $param->{'table'}}));
    } else {
        return undef
            unless ($keysFound =
            $self->get_indexes({'table' => $param->{'table'}}));
        $keysFound = $keysFound->{$param->{'key_name'}};
    }

    my @keys_list = keys %{$keysFound};
    if ($#keys_list < 0) {
        $result->{'empty'} = 1;
    } else {
        $result->{'existing_key_correct'} = 1;
        my %expected_keys;
        foreach my $expected_field (@{$param->{'expected_keys'}}) {
            $expected_keys{$expected_field} = 1;
        }
        foreach my $field (@{$param->{'expected_keys'}}) {
            unless ($keysFound->{$field}) {
                Log::do_log('info',
                    'Table %s: Missing expected key part %s in %s key',
                    $param->{'table'}, $field, $param->{'key_name'});
                $result->{'missing_key'}{$field} = 1;
                $result->{'existing_key_correct'} = 0;
            }
        }
        foreach my $field (keys %{$keysFound}) {
            unless ($expected_keys{$field}) {
                Log::do_log('info',
                    'Table %s: Found unexpected key part %s in %s key',
                    $param->{'table'}, $field, $param->{'key_name'});
                $result->{'unexpected_key'}{$field} = 1;
                $result->{'existing_key_correct'} = 0;
            }
        }
    }
    return $result;
}

# Helper functions to return the binding type and value used by
# do_prepared_query().
# Overridden by inherited classes.
#
# IN: - parameter value
#
# OUT: - One of:
#	* An array ( { sql_type => SQL_type }, value ).
#	* Single value (i.e. an array with single item), if special
#	  treatment won't be needed.
#	* Empty array () if arguments were not given.

# For DOUBLE type.
sub AS_DOUBLE {
    return $_[1] if scalar @_ > 1;
    return ();
}

# For BLOB types.
sub AS_BLOB {
    return $_[1] if scalar @_ > 1;
    return ();
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver - Base class of database drivers for Sympa

=head1 SYNOPSIS

  package Sympa::DatabaseDriver::FOO;
  use base qw(Sympa::DatabaseDriver);

=head1 DESCRIPTION

L<Sympa::DatabaseDriver> is the base class of driver classes for
Sympa Database Manager (SDM).

=head2 Instance methods subclasses should implement.

=over

=item build_connect_string ( )

I<Mandatory>.
Builds the string to be used by the DBI to connect to the database.

Parameter:

None.

Returns:

String representing data source name (DSN).

=item get_substring_clause ( { source_field => $source_field,
separator => $separator, substring_length => $substring_length } )

I<Mandatory>.
Returns an SQL clause to be inserted in a query.
This clause will compute a substring of max length

Parameters:

=over

=item $separator

Substring starts from the first character equal to this parameter.

=item $source_field

Search separator in the value of this field.

=item $substring_length

Max length of result.

=back

Returns:

Resulting substring.

=item get_limit_clause ( )

This method was deprecated.

=item get_formatted_date ( { mode => $mode, target => $target } )

I<Mandatory>.
Returns a character string corresponding to the expression to use in a query
involving a date.

Parameters:

=over

=item $mode

authorized values:

=over

=item C<'write'>

The sub returns the expression to use in 'INSERT' or 'UPDATE' queries.

=item C<'read'>

The sub returns the expression to use in 'SELECT' queries.

=back

=item $target

The name of the field or the value to be used in the query.

=back

Returns:

The formatted date or C<undef> if the date format mode is unknown.

=item is_autoinc ( { table => $table, field => $field } )

I<Required to probe database structure>.
Checks whether a field is an auto-increment field or not.

Parameters:

=over

=item $field

The name of the field to test

=item $table

The name of the table to add

=back

Returns:

True if the field is an auto-increment field, false otherwise

=item set_autoinc ( { table => $table, field => $field } )

I<Required to update database structure>.
Defines the field as an auto-increment field.

Parameters:

=over

=item $field

The name of the field to set.

=item $table

The name of the table to add.

=back

Returns:

C<1> if the auto-increment could be set, C<undef> otherwise.

=item get_tables ( )

I<Required to probe database structure>.
Returns the list of the tables in the database.

Parameters:

None.

Returns:

A ref to an array containing the list of the tables names in the
database, C<undef> if something went wrong.

=item add_table ( { table => $table } )

I<Required to update database structure>.
Adds a table to the database.

Parameter:

=over

=item $table

The name of the table to add

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item get_fields ( { table => $table } )

I<Required to probe database structure>.
Returns a ref to an hash containing the description of the fields in a table
from the database.

Parameters:

=over

=item $table

The name of the table whose fields are requested.

=back

Returns:

A hash in which the keys are the field names and the values are the field type.

Returns C<undef> if something went wrong.

=item update_field ( { table => $table, field => $field, type => $type, ... } )

I<Required to update database structure>.
Changes the type of a field in a table from the database.

Parameters:

=over

=item $field

The name of the field to update.

=item $table

The name of the table whose fields will be updated.

=item $type

The type of the field to add.

=item $notnull

Specifies that the field must not be null

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item add_field ( { table => $table, field => $field, type => $type, ... } )

I<Required to update database structure>.
Adds a field in a table from the database.

Parameters:

=over

=item $field

The name of the field to add.

=item $table

The name of the table where the field will be added.

=item $type

The type of the field to add.

=item $notnull

Specifies that the field must not be null.

=item $autoinc

Specifies that the field must be auto-incremental.

=item $primary

Specifies that the field is a key.

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item delete_field ( { table => $table, field => $field } )

I<Required to update database structure>.
Deletes a field from a table in the database.

Parameters:

=over

=item $field

The name of the field to delete

=item $table

The name of the table where the field will be deleted.

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item get_primary_key ( { table => $table } )

I<Required to probe database structure>.
Returns the list fields being part of a table's primary key.

=over

=item $table

The name of the table for which the primary keys are requested.

=back

Returns:

A ref to a hash in which each key is the name of a primary key or C<undef>
if something went wrong.

=item unset_primary_key ( { table => $table } )

I<Required to update database structure>.
Drops the primary key of a table.

Parameter:

=over

=item $table

The name of the table for which the primary keys must be
dropped.

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item set_primary_key ( { table => $table, fields => $fields } )

I<Required to update database structure>.
Sets the primary key of a table.

Parameters:

=over

=item $table

The name of the table for which the primary keys must be
defined.

=item $fields

A ref to an array containing the names of the fields used
in the key.

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item get_indexes ( { table => $table } )

I<Required to probe database structure>.
Returns a ref to a hash in which each key is the name of an index.

Parameter:

=over

=item $table

The name of the table for which the indexes are requested.

=back

Returns:

A ref to a hash in which each key is the name of an index.  These key
point to a second level hash in which each key is the name of the field
indexed.  Returns C<undef> if something went wrong.

=item unset_index ( { table => $table, index => $index } )

I<Required to update database structure>.
Drops an index of a table.

Parameters:

=over

=item $table

The name of the table for which the index must be dropped.

=item $index

The name of the index to be dropped.

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item set_index ( { table => $table, index_name => $index_name,
fields => $fields } )

I<Required to update database structure>.
Sets an index in a table.

Parameters:

=over

=item $table

The name of the table for which the index must be defined.

=item $fields

A ref to an array containing the names of the fields used
in the index.

=item $index_name

The name of the index to be defined.

=back

Returns:

A character string report of the operation done or C<undef> if something
went wrong.

=item do_query ( $query, $parameters, ... )

I<Overridable>.
TBD.

Parameters:

TBD.

Returns:

TBD.

=item do_prepared_query ( $query, $parameters, ... )

I<Overridable>.
TBD.

Parameters:

TBD.

Returns:

TBD.

=item AS_DOUBLE ( $value )

I<Overridable>.
Helper functions to return the DOUBLE binding type and value used by
L</do_prepared_query>().
Overridden by inherited classes.

Parameter:

=over

=item $value

=back

Parameter value

Returns:

One of:

=over

=item *

An array C<( { sql_type =E<gt> SQL_type }, value )>.

=item *

Single value (i.e. an array with single item), if special
treatment won't be needed.

=item *

Empty array C<()> if arguments were not given.

=back

=item AS_BLOB ( $value )

I<Overridable>.
Helper functions to return the BLOB (binary large object) binding type and
value used by L</do_prepared_query>().
Overridden by inherited classes.

See L</AS_DOUBLE> for more details.

=back

=head1 SEE ALSO

L<SDM>, L<Sympa::DatabaseDescription>.

=head1 HISTORY

Sympa Database Manager appeared on Sympa 6.2.

=cut
