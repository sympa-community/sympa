# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

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

package Sympa::DatabaseDriver::SQLite;

use strict;
use warnings;
use DBI qw();
use English qw(-no_match_vars);
use POSIX qw();

use Sympa::Log;

use base qw(Sympa::DatabaseDriver);

my $log = Sympa::Log->instance;

use constant required_modules    => [qw(DBD::SQLite)];
use constant required_parameters => [qw(db_name)];
use constant optional_parameters => [qw(db_timeout)];

sub build_connect_string {
    my $self = shift;

    return 'DBI:SQLite(sqlite_use_immediate_transaction=>1):dbname='
        . $self->{'db_name'};
}

sub connect {
    my $self = shift;

    $self->SUPER::connect() or return undef;

    # Configure to use sympa database
    $self->__dbh->func('func_index', -1, sub { return index($_[0], $_[1]) },
        'create_function');
    if (defined $self->{'db_timeout'}) {
        $self->__dbh->func($self->{'db_timeout'}, 'busy_timeout');
    } else {
        $self->__dbh->func(5000, 'busy_timeout');
    }
    # Create a temoprarhy view "dual" for portable SQL statements.
    $self->__dbh->do(q{CREATE TEMPORARY VIEW dual AS SELECT 'X' AS dummy;});

    return 1;
}

sub get_substring_clause {
    my $self  = shift;
    my $param = shift;
    return
          "substr("
        . $param->{'source_field'}
        . ",func_index("
        . $param->{'source_field'} . ",'"
        . $param->{'separator'} . "')+1,"
        . $param->{'substring_length'} . ")";
}

# DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

# DEPRECATED.
#sub get_formatted_date;

sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    $log->syslog('debug', 'Checking whether field %s.%s is autoincremental',
        $table, $field);

    my $type = $self->_get_field_type($table, $field);
    return undef unless $type;
    return ($type =~ /\binteger PRIMARY KEY\b/i) ? 1 : 0;
}

sub set_autoinc {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    $log->syslog('debug', 'Setting field %s.%s as autoincremental',
        $table, $field);

    my $type = $self->_get_field_type($table, $field);
    return undef unless $type;

    my $r;
    my $pk;
    if ($type =~ /\binteger\s+PRIMARY\s+KEY\b/i) {
        ## INTEGER PRIMARY KEY is auto-increment.
        return 1;
    } elsif ($type =~ /\bPRIMARY\s+KEY\b/i) {
        $r = $self->_update_table($table, qr(\b$field\s[^,]+),
            "$field\tinteger PRIMARY KEY");
    } elsif ($pk =
            $self->get_primary_key({'table' => $table})
        and $pk->{$field}
        and scalar keys %$pk == 1) {
        $self->unset_primary_key({'table' => $table});
        $r = $self->_update_table($table, qr(\b$field\s[^,]+),
            "$field\tinteger PRIMARY KEY");
    } else {
        $r = $self->_update_table($table, qr(\b$field\s[^,]+),
            "$field\t$type AUTOINCREMENT");
    }

    unless ($r) {
        $log->syslog('err',
            'Unable to set field %s in table %s as autoincrement',
            $field, $table);
        return undef;
    }
    return 1;
}

sub get_tables {
    my $self = shift;
    my @raw_tables;
    my @result;
    unless (@raw_tables = $self->__dbh->tables()) {
        $log->syslog('err',
            'Unable to retrieve the list of tables from database %s',
            $self->{'db_name'});
        return undef;
    }

    foreach my $t (@raw_tables) {
        $t =~ s/^"main"\.//;    # needed for SQLite 3
        $t =~ s/^.*\"([^\"]+)\"$/$1/;
        push @result, $t;
    }
    return \@result;
}

sub add_table {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Adding table %s to database %s',
        $param->{'table'}, $self->{'db_name'});
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
    my $table = $param->{'table'};
    my $sth;
    my %result;
    unless ($sth = $self->do_query(q{PRAGMA table_info('%s')}, $table)) {
        $log->syslog('err',
            'Could not get the list of fields from table %s in database %s',
            $table, $self->{'db_name'});
        return undef;
    }
    while (my $field = $sth->fetchrow_hashref('NAME_lc')) {
        # http://www.sqlite.org/datatype3.html
        my $type = $field->{'type'};
        if ($type =~ /int/) {
            $type = 'integer';
        } elsif ($type =~ /char|clob|text/) {
            $type = 'text';
        } elsif ($type =~ /blob|none/) {
            $type = 'none';
        } elsif ($type =~ /real|floa|doub/) {
            $type = 'real';
        } elsif ($type =~ /timestamp/) {    # for compatibility to SQLite 2.
            $type = 'timestamp';
        } else {
            $type = 'numeric';
        }
        $result{$field->{'name'}} = $type;
    }
    return \%result;
}

sub update_field {
    my $self    = shift;
    my $param   = shift;
    my $table   = $param->{'table'};
    my $field   = $param->{'field'};
    my $type    = $param->{'type'};
    my $options = '';
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL ';
    }
    my $report;

    $log->syslog('debug', 'Updating field %s in table %s (%s%s)',
        $field, $table, $type, $options);

    my $r = $self->_update_table($table, qr(\b$field\s[^,]+),
        "$field\t$type$options");
    unless (defined $r) {
        $log->syslog('err', 'Could not update field %s in table %s (%s%s)',
            $field, $table, $type, $options);
        return undef;
    }
    $report = $r;
    $log->syslog('info', '%s', $r);

    # Conversion between timestamp and number is not obvious.
    # So convert explicitly.
    my $fields = $self->get_fields({'table' => $table});
    if ($fields->{$field} eq 'timestamp' and $type =~ /^number/i) {
        $self->do_query('UPDATE %s SET %s = strftime(\'%%s\', %s, \'utc\')',
            $table, $field, $field);
    }

    $report .= "\nTable $table, field $field updated";
    $log->syslog('info', 'Table %s, field %s updated', $table, $field);

    return $report;
}

sub add_field {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    $log->syslog(
        'debug',             'Adding field %s in table %s (%s, %s, %s, %s)',
        $field,              $table,
        $param->{'type'},    $param->{'notnull'},
        $param->{'autoinc'}, $param->{'primary'}
    );
    my $options = '';
    # To prevent "Cannot add a NOT NULL column with default value NULL" errors
    if ($param->{'primary'}) {
        $options .= ' PRIMARY KEY';
    }
    if ($param->{'autoinc'}) {
        $options .= ' AUTOINCREMENT';
    }
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL';
    }

    my $report = '';

    if ($param->{'primary'}) {
        $report = $self->_update_table($table, qr{[(]\s*},
            "(\n\t $field\t$param->{'type'}$options,\n\t ");
        unless (defined $report) {
            $log->syslog('err',
                'Could not add field %s to table %s in database %s',
                $field, $table, $self->{'db_name'});
            return undef;
        }
    } else {
        unless (
            $self->do_query(
                q{ALTER TABLE %s ADD %s %s%s},
                $table, $field, $param->{'type'}, $options
            )
        ) {
            $log->syslog('err',
                'Could not add field %s to table %s in database %s',
                $field, $table, $self->{'db_name'});
            return undef;
        }
    }

    $report .= "\n" if $report;
    $report .= sprintf 'Field %s added to table %s (%s%s)',
        $field, $table, $param->{'type'}, $options;
    $log->syslog('info', 'Field %s added to table %s (%s%s)',
        $field, $table, $param->{'type'}, $options);

    return $report;
}

sub delete_field {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    return '' if $field eq 'temporary';

    $log->syslog('debug', 'Deleting field %s from table %s', $field, $table);

    ## SQLite does not support removal of columns
    my $report =
        "Could not remove field $field from table $table since SQLite does not support removal of columns";
    $log->syslog('info', '%s', $report);

    return $report;
}

sub get_primary_key {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    $log->syslog('debug', 'Getting primary key for table %s', $table);

    my %found_keys = ();

    my $sth;
    unless ($sth = $self->do_query(q{PRAGMA table_info('%s')}, $table)) {
        $log->syslog('err',
            'Could not get field list from table %s in database %s',
            $table, $self->{'db_name'});
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

sub unset_primary_key {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $report;

    $log->syslog('debug', 'Removing primary key from table %s', $table);
    my $r =
        $self->_update_table($table, qr{,\s*PRIMARY\s+KEY\s+[(][^)]+[)]}, '');
    unless (defined $r) {
        $r = $self->_update_table($table, qr{(?<=integer)\s+PRIMARY\s+KEY},
            '');
        unless (defined $r) {
            $log->syslog('err', 'Could not remove primary key from table %s',
                $table);
            return undef;
        }
    }
    $report = $r;
    $log->syslog('info', '%s', $r);
    $report .= "\nTable $table, PRIMARY KEY dropped";
    $log->syslog('info', 'Table %s, PRIMARY KEY dropped', $table);

    return $report;
}

sub set_primary_key {
    my $self   = shift;
    my $param  = shift;
    my $table  = $param->{'table'};
    my $fields = join ',', @{$param->{'fields'}};
    my $report;

    $log->syslog('debug', 'Setting primary key for table %s (%s)',
        $table, $fields);
    my $r = $self->_update_table($table, qr{\s*[)]\s*$},
        ",\n\t PRIMARY KEY ($fields)\n )");
    unless (defined $r) {
        $log->syslog('debug', 'Could not set primary key for table %s (%s)',
            $table, $fields);
        return undef;
    }
    $report = $r;
    $log->syslog('info', '%s', $r);
    $report .= "\nTable $table, PRIMARY KEY set on $fields";
    $log->syslog('info', 'Table %s, PRIMARY KEY set on %s', $table, $fields);

    return $report;
}

sub get_indexes {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Looking for indexes in %s', $param->{'table'});

    my %found_indexes;
    my $sth;
    my $l;
    unless ($sth =
        $self->do_query(q{PRAGMA index_list('%s')}, $param->{'table'})) {
        $log->syslog(
            'err',
            'Could not get the list of indexes from table %s in database %s',
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    while ($l = $sth->fetchrow_hashref('NAME_lc')) {
        next if $l->{'unique'};
        $found_indexes{$l->{'name'}} = {};
    }
    $sth->finish;

    foreach my $index_name (keys %found_indexes) {
        unless ($sth =
            $self->do_query(q{PRAGMA index_info('%s')}, $index_name)) {
            $log->syslog(
                'err',
                'Could not get the list of indexes from table %s in database %s',
                $param->{'table'},
                $self->{'db_name'}
            );
            return undef;
        }
        while ($l = $sth->fetchrow_hashref('NAME_lc')) {
            $found_indexes{$index_name}{$l->{'name'}} = {};
        }
        $sth->finish;
    }

    return \%found_indexes;
}

sub unset_index {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Removing index %s from table %s',
        $param->{'index'}, $param->{'table'});

    my $sth;
    unless ($sth =
        $self->do_query(q{DROP INDEX IF EXISTS "%s"}, $param->{'index'})) {
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
            q{CREATE INDEX %s ON %s (%s)}, $param->{'index_name'},
            $param->{'table'},             $fields
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
    my $report = sprintf 'Table %s, index %s set using fields %s',
        $param->{'table'}, $param->{'index_name'}, $fields;
    $log->syslog('info', 'Table %s, index %s set using fields %s',
        $param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
}

sub translate_type {
    my $self = shift;
    my $type = shift;

    return undef unless $type;

    # SQLite
    $type =~ s/^varchar.*/text/g;
    $type =~ s/^.*int\(1\).*/numeric/g;
    $type =~ s/^int.*/integer/g;
    $type =~ s/^tinyint.*/integer/g;
    $type =~ s/^bigint.*/integer/g;
    $type =~ s/^smallint.*/integer/g;
    $type =~ s/^double/real/g;
    $type =~ s/^longtext.*/text/g;
    $type =~ s/^datetime.*/numeric/g;
    $type =~ s/^enum.*/text/g;
    $type =~ s/^mediumblob/none/g;
    return $type;
}

# Note:
# To prevent "database is locked" error, acquire "immediate" lock
# by each query.  Most queries excluding "SELECT" need to lock in this
# manner.
sub do_query {
    my $self = shift;
    my $sth;
    my $rc;

    my $need_lock =
        ($_[0] =~
            /^\s*(ALTER|CREATE|DELETE|DROP|INSERT|REINDEX|REPLACE|UPDATE)\b/i
        );

    ## acquire "immediate" lock
    unless (!$need_lock or $self->__dbh->begin_work) {
        $log->syslog('err', 'Could not lock database: %s', $self->error);
        return undef;
    }

    ## do query
    $sth = $self->SUPER::do_query(@_);

    ## release lock
    return $sth unless $need_lock;
    eval {
        if ($sth) {
            $rc = $self->__dbh->commit;
        } else {
            $rc = $self->__dbh->rollback;
        }
    };
    if ($EVAL_ERROR or !$rc) {
        $log->syslog(
            'err',
            'Could not unlock database: %s',
            $EVAL_ERROR || $self->error
        );
        return undef;
    }

    return $sth;
}

sub do_prepared_query {
    my $self = shift;
    my $sth;
    my $rc;

    my $need_lock =
        ($_[0] =~
            /^\s*(ALTER|CREATE|DELETE|DROP|INSERT|REINDEX|REPLACE|UPDATE)\b/i
        );

    ## acquire "immediate" lock
    unless (!$need_lock or $self->__dbh->begin_work) {
        $log->syslog('err', 'Could not lock database: %s', $self->error);
        return undef;
    }

    ## do query
    $sth = $self->SUPER::do_prepared_query(@_);

    ## release lock
    return $sth unless $need_lock;
    eval {
        if ($sth) {
            $rc = $self->__dbh->commit;
        } else {
            $rc = $self->__dbh->rollback;
        }
    };
    if ($EVAL_ERROR or !$rc) {
        $log->syslog(
            'err',
            'Could not unlock database: %s',
            $EVAL_ERROR || $self->error
        );
        return undef;
    }

    return $sth;
}

sub AS_BLOB {
    return ({TYPE => DBI::SQL_BLOB()} => $_[1])
        if scalar @_ > 1;
    return ();
}

# Private methods

# Get raw type of column
sub _get_field_type {
    my $self  = shift;
    my $table = shift;
    my $field = shift;

    my $sth;
    unless ($sth = $self->do_query(q{PRAGMA table_info('%s')}, $table)) {
        $log->syslog('err',
            'Could not get the list of fields from table %s in database %s',
            $table, $self->{'db_name'});
        return undef;
    }
    my $l;
    while ($l = $sth->fetchrow_hashref('NAME_lc')) {
        if (lc $l->{'name'} eq lc $field) {
            $sth->finish;
            return
                  $l->{'type'}
                . ($l->{'pk'}         ? ' PRIMARY KEY'                : '')
                . ($l->{'notnull'}    ? ' NOT NULL'                   : '')
                . ($l->{'dflt_value'} ? " DEFAULT $l->{'dflt_value'}" : '');
        }
    }
    $sth->finish;

    $log->syslog(
        'err',
        'Could not gather information of field %s from table %s in database %s',
        $field,
        $table,
        $self->{'db_name'}
    );
    return undef;
}

# Update table structure
# Old table will be saved as "<table name>_<YYmmddHHMMSS>_<PID>".
sub _update_table {
    my $self        = shift;
    my $table       = shift;
    my $regex       = shift;
    my $replacement = shift;
    my $statement;
    my $table_saved = sprintf '%s_%s_%d', $table,
        POSIX::strftime("%Y%m%d%H%M%S", gmtime $^T),
        $PID;
    my $report;

    ## create temporary table with new structure
    $statement = $self->_get_create_table($table);
    unless (defined $statement) {
        $log->syslog('err', 'Table "%s" does not exist', $table);
        return undef;
    }

    $statement =~
        s/^\s*CREATE\s+TABLE\s+([\"\w]+)/CREATE TABLE ${table_saved}_new/;

    my $statement_orig = $statement;
    $statement =~ s/$regex/$replacement/;
    if ($statement eq $statement_orig) {
        $log->syslog('debug', 'Table "%s" was not changed', $table);
        return undef;
    }
    $statement =~ s/\btemporary\s+INT,\s*//;    # Omit "temporary" field.

    my $s = $statement;
    $s =~ s/\n\s*/ /g;
    $s =~ s/\t/ /g;
    $log->syslog('info', '%s', $s);

    unless ($self->do_query('%s', $statement)) {
        $log->syslog('err', 'Could not create temporary table "%s_new"',
            $table_saved);
        return undef;
    }

    $log->syslog('info', 'Copy "%s" to "%s_new"', $table, $table_saved);
    ## save old table
    my $indexes = $self->get_indexes({'table' => $table});
    unless (defined $self->_copy_table($table, "${table_saved}_new")
        and defined $self->_rename_or_drop_table($table, $table_saved)
        and defined $self->_rename_table("${table_saved}_new", $table)) {
        return undef;
    }
    ## recreate indexes
    foreach my $name (keys %{$indexes || {}}) {
        unless (
            defined $self->unset_index(
                {'table' => "${table_saved}_new", 'index' => $name}
            )
            and defined $self->set_index(
                {   'table'      => $table,
                    'index_name' => $name,
                    'fields'     => [sort keys %{$indexes->{$name}}]
                }
            )
        ) {
            return undef;
        }
    }

    $report = "Old table was saved as \'$table_saved\'";
    return $report;
}

# Get SQL statement by which table was created.
sub _get_create_table {
    my $self  = shift;
    my $table = shift;
    my $sth;

    unless (
        $sth = $self->do_query(
            q{SELECT sql
              FROM sqlite_master
              WHERE type = 'table' AND name = '%s'},
            $table
        )
    ) {
        $log->syslog('Could not get table \'%s\' on database \'%s\'',
            $table, $self->{'db_name'});
        return undef;
    }
    my $sql = $sth->fetchrow_array();
    $sth->finish;

    return $sql || undef;
}

# Copy table content to another table
# Target table must have all columns source table has.
sub _copy_table {
    my $self      = shift;
    my $table     = shift;
    my $table_new = shift;
    return undef unless defined $table and defined $table_new;

    my $fields = join ', ', grep { $_ ne 'temporary' }
        sort keys %{$self->get_fields({'table' => $table})};
    $fields ||= 'temporary';

    my $sth;
    unless (
        $sth = $self->do_query(
            q{INSERT INTO "%s" (%s) SELECT %s FROM "%s"},
            $table_new, $fields, $fields, $table
        )
    ) {
        $log->syslog('err',
            'Could not copy talbe "%s" to temporary table "%s_new"',
            $table, $table_new);
        return undef;
    }

    return 1;
}

# Rename table
# If target already exists, do nothing and return 0.
sub _rename_table {
    my $self      = shift;
    my $table     = shift;
    my $table_new = shift;
    return undef unless defined $table and defined $table_new;

    if ($self->_get_create_table($table_new)) {
        return 0;
    }
    unless (
        $self->do_query(q{ALTER TABLE %s RENAME TO %s}, $table, $table_new)) {
        $log->syslog('err', 'Could not rename table "%s" to "%s"',
            $table, $table_new);
        return undef;
    }
    return 1;
}

# Rename table
# If target already exists, drop source table.
sub _rename_or_drop_table {
    my $self      = shift;
    my $table     = shift;
    my $table_new = shift;

    my $r = $self->_rename_table($table, $table_new);
    unless (defined $r) {
        return undef;
    } elsif ($r) {
        return $r;
    } else {
        unless ($self->do_query(q{DROP TABLE IF EXISTS "%s"}, $table)) {
            $log->syslog('err', 'Could not drop table "%s"', $table);
            return undef;
        }
        return 0;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::SQLite - Database driver for SQLite

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
