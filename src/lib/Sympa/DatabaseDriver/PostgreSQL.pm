# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::DatabaseDriver::PostgreSQL;

use strict;
use warnings;
use Encode qw();

use Sympa::Log;

use base qw(Sympa::DatabaseDriver);

my $log = Sympa::Log->instance;

use constant required_modules => [qw(DBD::Pg)];

sub build_connect_string {
    my $self = shift;

    my $connect_string =
          'DBI:Pg:dbname='
        . $self->{'db_name'}
        . ';host='
        . ($self->{'db_host'} || 'localhost');
    $connect_string .= ';port=' . $self->{'db_port'}
        if defined $self->{'db_port'};
    $connect_string .= ';' . $self->{'db_options'}
        if defined $self->{'db_options'};
    return $connect_string;
}

sub connect {
    my $self = shift;

    $self->SUPER::connect() or return undef;

    # - Configure Postgres to use ISO format dates.
    # - Set client encoding to UTF8.
    # Note: utf8 flagging must be disabled so that we will consistently use
    # UTF-8 bytestring as internal format.
    $self->__dbh->{pg_enable_utf8} = 0;    # For DBD::Pg 3.x
    $self->__dbh->do("SET DATESTYLE TO 'ISO';");
    $self->__dbh->do("SET NAMES 'utf8'");

    return 1;
}

sub quote {
    my $self      = shift;
    my $string    = shift;
    my $data_type = shift;

    # Set utf8 flag. Because DBD::Pg 3.3.0 to 3.5.x need utf8 flag for input
    # parameters, even if pg_enable_utf8 option is disabled.
    if ($DBD::Pg::VERSION =~ /\A3[.][3-5]\b/
        and not(ref $data_type eq 'HASH' and $data_type->{pg_type})) {
        $string = Encode::decode_utf8($string);
    }
    return $self->SUPER::quote($string, $data_type);
}

sub do_prepared_query {
    my $self  = shift;
    my $query = shift;

    # Set utf8 flag. Because DBD::Pg 3.3.0 to 3.5.x need utf8 flag for input
    # parameters, even if pg_enable_utf8 option is disabled.
    if ($DBD::Pg::VERSION =~ /\A3[.][3-5]\b/) {
        my @params;
        while (scalar @_) {
            my $p = shift;
            if (ref $p) {
                push @params, $p, shift;
            } else {
                push @params, Encode::decode_utf8($p);
            }
        }
        @_ = @params;
    }
    return $self->SUPER::do_prepared_query($query, @_);
}

sub get_substring_clause {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug2', 'Building a substring clause');
    return
          "SUBSTRING("
        . $param->{'source_field'}
        . " FROM position('"
        . $param->{'separator'} . "' IN "
        . $param->{'source_field'}
        . ") FOR "
        . $param->{'substring_length'} . ")";
}

# DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

# DEPRECATED.
#sub get_formatted_date;

sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Checking whether field %s.%s is an autoincrement',
        $param->{'table'}, $param->{'field'});
    my $seqname = $param->{'table'} . '_' . $param->{'field'} . '_seq';
    my $sth;
    unless (
        $sth = $self->do_prepared_query(
            q{SELECT relname
              FROM pg_class
              WHERE relname = ? AND relkind = 'S' AND
                    relnamespace IN (
                                     SELECT oid
                                     FROM pg_namespace
                                     WHERE nspname NOT LIKE 'pg_%' AND
                                           nspname != 'information_schema'
                                    )},
            $seqname
        )
    ) {
        $log->syslog('err',
            'Unable to gather autoincrement field named %s for table %s',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    my $field = $sth->fetchrow();
    return ($field eq $seqname);
}

sub set_autoinc {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Setting field %s.%s as an auto increment',
        $param->{'table'}, $param->{'field'});
    my $seqname = $param->{'table'} . '_' . $param->{'field'} . '_seq';
    unless ($self->do_query("CREATE SEQUENCE %s", $seqname)) {
        $log->syslog('err', 'Unable to create sequence %s', $seqname);
        return undef;
    }
    unless (
        $self->do_query(
            "ALTER TABLE %s ALTER COLUMN %s TYPE BIGINT", $param->{'table'},
            $param->{'field'}
        )
    ) {
        $log->syslog('err',
            'Unable to set type of field %s in table %s as bigint',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    unless (
        $self->do_query(
            "ALTER TABLE %s ALTER COLUMN %s SET DEFAULT NEXTVAL('%s')",
            $param->{'table'}, $param->{'field'}, $seqname
        )
    ) {
        $log->syslog(
            'err',
            'Unable to set default value of field %s in table %s as next value of sequence table %s',
            $param->{'field'},
            $param->{'table'},
            $seqname
        );
        return undef;
    }
    unless (
        $self->do_query(
            "UPDATE %s SET %s = NEXTVAL('%s')", $param->{'table'},
            $param->{'field'},                  $seqname
        )
    ) {
        $log->syslog('err',
            'Unable to set sequence %s as value for field %s, table %s',
            $seqname, $param->{'field'}, $param->{'table'});
        return undef;
    }
    return 1;
}

# Note: Pg searches tables in schemas listed in search_path, defaults to be
# '"$user",public'.
sub get_tables {
    my $self = shift;
    $log->syslog('debug3', 'Getting the list of tables in database %s',
        $self->{'db_name'});

    ## get search_path.
    ## The result is an arrayref; needs DBD::Pg >= 2.00 and PostgreSQL > 7.4.
    my $sth;
    unless ($sth = $self->do_query('SELECT current_schemas(false)')) {
        $log->syslog('err', 'Unable to get search_path of database %s',
            $self->{'db_name'});
        return undef;
    }
    my $search_path = $sth->fetchrow;
    $sth->finish;

    ## get table names.
    my @raw_tables;
    my %raw_tables;
    foreach my $schema (@{$search_path || []}) {
        my @tables =
            $self->__dbh->tables(undef, $schema, undef, 'TABLE',
            {pg_noprefix => 1});
        foreach my $t (@tables) {
            next if $raw_tables{$t};
            push @raw_tables, $t;
            $raw_tables{$t} = 1;
        }
    }
    unless (@raw_tables) {
        $log->syslog('err',
            'Unable to retrieve the list of tables from database %s',
            $self->{'db_name'});
        return undef;
    }
    return \@raw_tables;
}

sub add_table {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Adding table %s', $param->{'table'});
    unless (
        $self->do_query("CREATE TABLE %s (temporary INT)", $param->{'table'}))
    {
        $log->syslog('err', 'Could not create table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    return sprintf "Table %s created in database %s", $param->{'table'},
        $self->{'db_name'};
}

sub get_fields {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug',
        'Getting the list of fields in table %s, database %s',
        $param->{'table'}, $self->{'db_name'});
    my $sth;
    my %result;
    unless (
        $sth = $self->do_query(
            "SELECT a.attname AS field, t.typname AS type, a.atttypmod AS length FROM pg_class c, pg_attribute a, pg_type t WHERE a.attnum > 0 and a.attrelid = c.oid and c.relname = '%s' and a.atttypid = t.oid order by a.attnum",
            $param->{'table'}
        )
    ) {
        $log->syslog('err',
            'Could not get the list of fields from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        # What a dirty method ! We give a Sympa tee shirt to anyone that
        # suggest a clean solution ;-)
        my $length = $ref->{'length'} - 4;
        if ($ref->{'type'} eq 'varchar') {
            $result{$ref->{'field'}} = $ref->{'type'} . '(' . $length . ')';
        } else {
            $result{$ref->{'field'}} = $ref->{'type'};
        }
    }
    return \%result;
}

sub update_field {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};
    my $type  = $param->{'type'};
    $log->syslog('debug3', 'Updating field %s in table %s (%s, %s)',
        $field, $table, $type, $param->{'notnull'});
    my $options = '';
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL ';
    }
    my $report;
    my @sql;

    ## Conversion between timestamp and integer is not obvious.
    ## So create new column then copy contents.
    my $fields = $self->get_fields({'table' => $table});
    if ($fields->{$field} eq 'timestamptz' and $type =~ /^int/i) {
        @sql = (
            "ALTER TABLE $table RENAME $field TO ${field}_tmp",
            "ALTER TABLE $table ADD $field $type$options",
            "UPDATE $table SET $field = date_part('epoch', ${field}_tmp)",
            "ALTER TABLE $table DROP ${field}_tmp"
        );
    } else {
        @sql = sprintf("ALTER TABLE %s ALTER COLUMN %s TYPE %s %s",
            $table, $field, $type, $options);
    }
    foreach my $sql (@sql) {
        $log->syslog('notice', '%s', $sql);
        if ($report) {
            $report .= "\n$sql";
        } else {
            $report = $sql;
        }
        unless ($self->do_query('%s', $sql)) {
            $log->syslog('err', 'Could not change field "%s" in table "%s"',
                $param->{'field'}, $param->{'table'});
            return undef;
        }
    }
    $report .=
        sprintf("\nField %s in table %s, structure updated", $field, $table);
    $log->syslog('info', 'Field %s in table %s, structure updated',
        $field, $table);
    return $report;
}

sub add_field {
    my $self  = shift;
    my $param = shift;
    $log->syslog(
        'debug',             'Adding field %s in table %s (%s, %s, %s, %s)',
        $param->{'field'},   $param->{'table'},
        $param->{'type'},    $param->{'notnull'},
        $param->{'autoinc'}, $param->{'primary'}
    );
    my $options = '';
    # To prevent "Cannot add a NOT NULL column with default value NULL" errors
    if ($param->{'notnull'}) {
        $options .= 'NOT NULL ';
    }
    if ($param->{'primary'}) {
        $options .= ' PRIMARY KEY ';
    }
    unless (
        $self->do_query(
            "ALTER TABLE %s ADD %s %s %s", $param->{'table'},
            $param->{'field'},             $param->{'type'},
            $options
        )
    ) {
        $log->syslog('err',
            'Could not add field %s to table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf('Field %s added to table %s (options : %s)',
        $param->{'field'}, $param->{'table'}, $options);
    $log->syslog('info', 'Field %s added to table %s (options: %s)',
        $param->{'field'}, $param->{'table'}, $options);

    return $report;
}

sub delete_field {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Deleting field %s from table %s',
        $param->{'field'}, $param->{'table'});

    unless (
        $self->do_query(
            "ALTER TABLE %s DROP COLUMN %s", $param->{'table'},
            $param->{'field'}
        )
    ) {
        $log->syslog('err',
            'Could not delete field %s from table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf('Field %s removed from table %s',
        $param->{'field'}, $param->{'table'});
    $log->syslog('info', 'Field %s removed from table %s',
        $param->{'field'}, $param->{'table'});

    return $report;
}

sub get_primary_key {
    my $self  = shift;
    my $param = shift;

    $log->syslog('debug', 'Getting primary key for table %s',
        $param->{'table'});
    my %found_keys;
    my $sth;
    unless (
        $sth = $self->do_query(
            "SELECT pg_attribute.attname AS field FROM pg_index, pg_class, pg_attribute WHERE pg_class.oid ='%s'::regclass AND indrelid = pg_class.oid AND pg_attribute.attrelid = pg_class.oid AND pg_attribute.attnum = any(pg_index.indkey) AND indisprimary",
            $param->{'table'}
        )
    ) {
        $log->syslog('err',
            'Could not get the primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        $found_keys{$ref->{'field'}} = 1;
    }
    return \%found_keys;
}

sub unset_primary_key {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Removing primary key from table %s',
        $param->{'table'});

    my $sth;

    ## PostgreSQL does not have 'ALTER TABLE ... DROP PRIMARY KEY'.
    ## Instead, get a name of constraint then drop it.
    my $key_name;

    unless (
        $sth = $self->do_query(
            q{SELECT tc.constraint_name
              FROM information_schema.table_constraints AS tc
              WHERE tc.table_catalog = %s AND tc.table_name = %s AND
                    tc.constraint_type = 'PRIMARY KEY'},
            $self->quote($self->{'db_name'}), $self->quote($param->{'table'})
        )
    ) {
        $log->syslog('err',
            'Could not search primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    $key_name = $sth->fetchrow_array();
    $sth->finish;
    unless (defined $key_name) {
        $log->syslog('err',
            'Could not get primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    unless (
        $sth = $self->do_query(
            q{ALTER TABLE %s DROP CONSTRAINT "%s"}, $param->{'table'},
            $key_name
        )
    ) {
        $log->syslog('err',
            'Could not drop primary key "%s" from table %s in database %s',
            $key_name, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = "Table $param->{'table'}, PRIMARY KEY dropped";
    $log->syslog('info', 'Table %s, PRIMARY KEY dropped', $param->{'table'});

    return $report;
}

sub set_primary_key {
    my $self  = shift;
    my $param = shift;

    my $sth;

    ## Give fixed key name if possible.
    my $key;
    if ($param->{'table'} =~ /^(.+)_table$/) {
        $key = sprintf 'CONSTRAINT "ind_%s" PRIMARY KEY', $1;
    } else {
        $key = 'PRIMARY KEY';
    }

    my $fields = join ',', @{$param->{'fields'}};
    $log->syslog('debug', 'Setting primary key for table %s (%s)',
        $param->{'table'}, $fields);
    unless (
        $sth = $self->do_query(
            q{ALTER TABLE %s ADD %s (%s)}, $param->{'table'},
            $key,                          $fields
        )
    ) {
        $log->syslog(
            'err',
            'Could not set fields %s as primary key for table %s in database %s',
            $fields,
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }

    my $report = "Table $param->{'table'}, PRIMARY KEY set on $fields";
    $log->syslog('info', 'Table %s, PRIMARY KEY set on %s',
        $param->{'table'}, $fields);
    return $report;
}

sub get_indexes {
    my $self  = shift;
    my $param = shift;

    $log->syslog('debug', 'Getting the indexes defined on table %s',
        $param->{'table'});
    my %found_indexes;
    my $sth;
    unless (
        $sth = $self->do_query(
            q{SELECT c.oid
              FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n
              ON n.oid = c.relnamespace
              WHERE c.relname ~ '^(%s)$' AND
                    pg_catalog.pg_table_is_visible(c.oid)},
            $param->{'table'}
        )
    ) {
        $log->syslog('err',
            'Could not get the oid for table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $ref = $sth->fetchrow_hashref('NAME_lc');

    unless (
        $sth = $self->do_query(
            "SELECT c2.relname, pg_catalog.pg_get_indexdef(i.indexrelid, 0, true) AS description FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i WHERE c.oid = \'%s\' AND c.oid = i.indrelid AND i.indexrelid = c2.oid AND NOT i.indisprimary ORDER BY i.indisprimary DESC, i.indisunique DESC, c2.relname",
            $ref->{'oid'}
        )
    ) {
        $log->syslog(
            'err',
            'Could not get the list of indexes from table %s in database %s',
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }

    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        $ref->{'description'} =~
            s/CREATE INDEX .* ON .* USING .* \((.*)\)$/$1/i;
        $ref->{'description'} =~ s/\s//i;
        my @index_members = split ',', $ref->{'description'};
        foreach my $member (@index_members) {
            $found_indexes{$ref->{'relname'}}{$member} = 1;
        }
    }
    return \%found_indexes;
}

sub unset_index {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Removing index %s from table %s',
        $param->{'index'}, $param->{'table'});

    my $sth;
    unless ($sth = $self->do_query("DROP INDEX %s", $param->{'index'})) {
        $log->syslog('err',
            'Could not drop index %s from table %s in database %s',
            $param->{'index'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $report = "Table $param->{'table'}, index $param->{'index'} dropped";
    $log->syslog('info', 'Table %s, index %s dropped',
        $param->{'table'}, $param->{'index'});

    return $report;
}

sub set_index {
    my $self  = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',', @{$param->{'fields'}};
    $log->syslog(
        'debug',
        'Setting index %s for table %s using fields %s',
        $param->{'index_name'},
        $param->{'table'}, $fields
    );
    unless (
        $sth = $self->do_query(
            "CREATE INDEX %s ON %s (%s)", $param->{'index_name'},
            $param->{'table'},            $fields
        )
    ) {
        $log->syslog(
            'err',
            'Could not add index %s using field %s for table %s in database %s',
            $fields,
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    my $report = "Table $param->{'table'}, index %s set using $fields";
    $log->syslog('info', 'Table %s, index %s set using fields %s',
        $param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
}

sub translate_type {
    my $self = shift;
    my $type = shift;

    return undef unless $type;

    # PostgreSQL
    $type =~ s/^int(1)/smallint/g;
    $type =~ s/^int\(?.*\)?/int4/g;
    $type =~ s/^smallint.*/int4/g;
    $type =~ s/^tinyint\(.*\)/int2/g;
    $type =~ s/^bigint.*/int8/g;
    $type =~ s/^double/float8/g;
    $type =~ s/^text.*/text/g;    # varchar(500) on <= 6.2.36
    $type =~ s/^longtext.*/text/g;
    $type =~ s/^datetime.*/timestamptz/g;
    $type =~ s/^enum.*/varchar(15)/g;
    $type =~ s/^mediumblob/bytea/g;
    return $type;
}

sub AS_DOUBLE {
    return ({'pg_type' => DBD::Pg::PG_FLOAT8()} => $_[1])
        if scalar @_ > 1;
    return ();
}

sub AS_BLOB {
    return ({'pg_type' => DBD::Pg::PG_BYTEA()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::PostgreSQL - Database driver for PostgreSQL

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
