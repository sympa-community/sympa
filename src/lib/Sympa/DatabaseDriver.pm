# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2021, 2022 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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

use base qw(Sympa::Database);

use constant required_modules    => [];
use constant required_parameters => [qw(db_name)];
use constant optional_modules    => [];
use constant optional_parameters =>
    [qw(db_host db_port db_user db_passwd db_options db_env)];

sub translate_type {
    return $_[1];
}

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

sub delete_field {
    my $self    = shift;
    my $options = shift;

    unless ($self->can('drop_field')) {
        return 'Removal of column from table does not supported.';
    }

    my $table  = $options->{table};
    my $field  = $options->{field};
    my $fields = $self->get_fields({table => $table});
    unless (defined $fields->{$field}) {
        return sprintf 'The field %s does not exist in the table %s',
            $table, $field;
    }

    return $self->drop_field($table, $field);
}

sub md5_func {
    shift;

    return sprintf q{MD5(CONCAT(%s))}, join ', ',
        map { sprintf q{COALESCE(%s, '')}, $_ } @_;
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

=head2 Instance methods subclasses should implement

=over

=item required_modules ( )

I<Overridable>.
Returns an arrayref including package name(s) this driver requires.
By default, no packages are required.

=item required_parameters ( )

I<Overridable>.
Returns an arrayref including names of required (not optional) parameters.
By default, returns C<['db_name']>.

I<Note>:
On Sympa prior to 6.2.71b, it by default returned
C<['db_name', 'db_user']>.
On Sympa prior to 6.2.37b.2, it by default returned
C<['db_host', 'db_name', 'db_user']>.

=item optional_modules ( )

I<Overridable>.
Returns an arrayref including all name(s) of optional packages.
By default, there are no optional packages.

This method was introduced by Sympa 6.2.4.

=item optional_parameters ( )

I<Overridable>.
Returns an arrayref including all names of optional parameters.
By default, returns C<'db_passwd'>, C<'db_port'>, C<'db_options'> and so on.

=item build_connect_string ( )

I<Mandatory for SQL driver>.
Builds the string to be used by the DBI to connect to the database.

Parameter:

None.

Returns:

String representing data source name (DSN).

=item connect ( )

I<Overridable>.
Connects to database calling L</_connect>() and sets database handle.

Parameter:

None.

Returns:

True value or, if connection failed, false value.

=item _connect ( )

I<Overridable>.
Connects to database and returns native database handle.

The default implementation is for L<DBI> database handle.

=item get_substring_clause ( { source_field => $source_field,
separator => $separator, substring_length => $substring_length } )

This method was deprecated by Sympa 6.2.4.

=item get_limit_clause ( )

This method was deprecated.

=item get_formatted_date ( { mode => $mode, target => $target } )

B<Deprecated> as of Sympa 6.2.25b.3.

I<Mandatory for SQL driver>.
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

=item is_sufficient_field_type ( $required, $actual )

I<Overridable>, I<only for SQL driver>.
Checks if database field type is sufficient.

Parameters:

=over

=item $required

Required field type.

=item $actual

Actual field type.

=back

Returns:

The true value if actual field type is appropriate AND size is equal to or
greater than required size.

This method was added on Sympa 6.2.67b.1.

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

A ref to an array containing the list of the table names in the
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

=item delete_field ( { table => $table, field => $column } );

I<Overridable>.
If the column exists in the table, remove it using drop_field().
Otherwise do nothing.

=item drop_field ( $table, $field )

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

Note:
On Sympa 6.2.71b.1 or earlier, delete_field() was defined instead of this.

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

=item translate_type ( $generic_type )

I<Required to probe and update database structure>.
Get native field type corresponds to generic type.
The generic type is based on MySQL:
See L<Sympa::DatabaseDescription/full_db_struct>.

=back

Subclasses of L<Sympa::DatabaseDriver> class also can override methods
provided by L<Sympa::Database> class:

=over

=item do_operation ( $operation, $parameters, ...)

I<Overridable>, I<only for LDAP driver>.

=item do_query ( $query, $parameters, ... )

I<Overridable>, I<only for SQL driver>.

=item do_prepared_query ( $query, $parameters, ... )

I<Overridable>, I<only for SQL driver>.

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

=item md5_func ( $expression, ... )

I<Required>.
Given expressions, returns a SQL expression calculating MD5 digest of
concatenated those expressions.  Among them, NULL values should be ignored
and numeric values should be converted to textual type before concatenation.
Value of the SQL expression should be lowercase 32 hexadigits.

=back

=head2 Utility method

=over

=item __dbh ( )

I<Instance method>, I<protected>.
Returns native database handle which L<_connect>() returned.
This may be used at inside of each driver class.

=back

=head1 SEE ALSO

L<Sympa::Database>, L<Sympa::DatabaseManager>.

=head1 HISTORY

Sympa Database Manager (SDM) appeared on Sympa 6.2.

=cut
