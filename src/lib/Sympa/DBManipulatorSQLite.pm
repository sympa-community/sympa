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

package Sympa::DBManipulatorSQLite;

use strict;
use warnings;
use DBI qw();
use English qw(-no_match_vars);
use POSIX qw();

use Log;

use base qw(Sympa::DBManipulatorDefault);

sub build_connect_string {
    my $self = shift;
    $self->{'connect_string'} =
        "DBI:SQLite(sqlite_use_immediate_transaction=>1):dbname=$self->{'db_name'}";
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

sub get_formatted_date {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Building SQL date formatting');
    if (lc($param->{'mode'}) eq 'read' or lc($param->{'mode'}) eq 'write') {
        return $param->{'target'};
    } else {
        Log::do_log('err', "Unknown date format mode %s", $param->{'mode'});
        return undef;
    }
}

sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    Log::do_log('debug', 'Checking whether field %s.%s is autoincremental',
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

    Log::do_log('debug', 'Setting field %s.%s as autoincremental',
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
        Log::do_log('err',
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
    unless (@raw_tables = $self->{'dbh'}->tables()) {
        Log::do_log('err',
            'Unable to retrieve the list of tables from database %s',
            $self->{'db_name'});
        return undef;
    }

    foreach my $t (@raw_tables) {
        $t =~ s/^"main"\.//;            # needed for SQLite 3
        $t =~ s/^.*\"([^\"]+)\"$/$1/;
        push @result, $t;
    }
    return \@result;
}

sub add_table {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Adding table %s to database %s',
        $param->{'table'}, $self->{'db_name'});
    unless (
        $self->do_query("CREATE TABLE %s (temporary INT)", $param->{'table'}))
    {
        Log::do_log('err', 'Could not create table %s in database %s',
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
        Log::do_log('err',
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

    Log::do_log('debug', 'Updating field %s in table %s (%s%s)',
        $field, $table, $type, $options);

    my $r = $self->_update_table($table, qr(\b$field\s[^,]+),
        "$field\t$type$options");
    unless (defined $r) {
        Log::do_log('err', 'Could not update field %s in table %s (%s%s)',
            $field, $table, $type, $options);
        return undef;
    }
    $report = $r;
    Log::do_log('info', '%s', $r);

    # Conversion between timestamp and number is not obvious.
    # So convert explicitly.
    my $fields = $self->get_fields({'table' => $table});
    if ($fields->{$field} eq 'timestamp' and $type =~ /^number/i) {
        $self->do_query('UPDATE %s SET %s = strftime(\'%%s\', %s, \'utc\')',
            $table, $field, $field);
    }

    $report .= "\nTable $table, field $field updated";
    Log::do_log('info', 'Table %s, field %s updated', $table, $field);

    return $report;
}

sub add_field {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    Log::do_log(
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
            Log::do_log('err',
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
            Log::do_log('err',
                'Could not add field %s to table %s in database %s',
                $field, $table, $self->{'db_name'});
            return undef;
        }
    }

    $report .= "\n" if $report;
    $report .= sprintf 'Field %s added to table %s (%s%s)',
        $field, $table, $param->{'type'}, $options;
    Log::do_log('info', 'Field %s added to table %s (%s%s)',
        $field, $table, $param->{'type'}, $options);

    return $report;
}

sub delete_field {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    my $field = $param->{'field'};

    return '' if $field eq 'temporary';

    Log::do_log('debug', 'Deleting field %s from table %s', $field, $table);

    ## SQLite does not support removal of columns
    my $report =
        "Could not remove field $field from table $table since SQLite does not support removal of columns";
    Log::do_log('info', '%s', $report);

    return $report;
}

sub get_primary_key {
    my $self  = shift;
    my $param = shift;
    my $table = $param->{'table'};
    Log::do_log('debug', 'Getting primary key for table %s', $table);

    my %found_keys = ();

    my $sth;
    unless ($sth = $self->do_query(q{PRAGMA table_info('%s')}, $table)) {
        Log::do_log('err',
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

    Log::do_log('debug', 'Removing primary key from table %s', $table);
    my $r =
        $self->_update_table($table, qr{,\s*PRIMARY\s+KEY\s+[(][^)]+[)]}, '');
    unless (defined $r) {
        Log::do_log('err', 'Could not remove primary key from table %s',
            $table);
        return undef;
    }
    $report = $r;
    Log::do_log('info', '%s', $r);
    $report .= "\nTable $table, PRIMARY KEY dropped";
    Log::do_log('info', 'Table %s, PRIMARY KEY dropped', $table);

    return $report;
}

sub set_primary_key {
    my $self   = shift;
    my $param  = shift;
    my $table  = $param->{'table'};
    my $fields = join ',', @{$param->{'fields'}};
    my $report;

    Log::do_log('debug', 'Setting primary key for table %s (%s)',
        $table, $fields);
    my $r = $self->_update_table($table, qr{\s*[)]\s*$},
        ",\n\t PRIMARY KEY ($fields)\n )");
    unless (defined $r) {
        Log::do_log('debug', 'Could not set primary key for table %s (%s)',
            $table, $fields);
        return undef;
    }
    $report = $r;
    Log::do_log('info', '%s', $r);
    $report .= "\nTable $table, PRIMARY KEY set on $fields";
    Log::do_log('info', 'Table %s, PRIMARY KEY set on %s', $table, $fields);

    return $report;
}

sub get_indexes {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Looking for indexes in %s', $param->{'table'});

    my %found_indexes;
    my $sth;
    my $l;
    unless ($sth =
        $self->do_query(q{PRAGMA index_list('%s')}, $param->{'table'})) {
        Log::do_log(
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
            Log::do_log(
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
    Log::do_log('debug', 'Removing index %s from table %s',
        $param->{'index'}, $param->{'table'});

    my $sth;
    unless ($sth = $self->do_query(q{DROP INDEX "%s"}, $param->{'index'})) {
        Log::do_log('err',
            'Could not drop index %s from table %s in database %s',
            $param->{'index'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $report = "Table $param->{'table'}, index $param->{'index'} dropped";
    Log::do_log('info', 'Table %s, index %s dropped',
        $param->{'table'}, $param->{'index'});

    return $report;
}

sub set_index {
    my $self  = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',', @{$param->{'fields'}};
    Log::do_log(
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
        Log::do_log(
            'err',
            'Could not add index %s using field %s for table %s in database %s',
            $fields,
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    my $report = "Table $param->{'table'}, index %s set using $fields";
    Log::do_log('info', 'Table %s, index %s set using fields %s',
        $param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
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
    unless (!$need_lock or $self->{'dbh'}->begin_work) {
        Log::do_log('err', 'Could not lock database: (%s) %s',
            $self->{'dbh'}->err, $self->{'dbh'}->errstr);
        return undef;
    }

    ## do query
    $sth = $self->SUPER::do_query(@_);

    ## release lock
    return $sth unless $need_lock;
    eval {
        if ($sth) {
            $rc = $self->{'dbh'}->commit;
        } else {
            $rc = $self->{'dbh'}->rollback;
        }
    };
    if ($EVAL_ERROR or !$rc) {
        Log::do_log(
            'err',
            'Could not unlock database: %s',
            $EVAL_ERROR || sprintf('(%s) %s',
                $self->{'dbh'}->err, $self->{'dbh'}->errstr)
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
    unless (!$need_lock or $self->{'dbh'}->begin_work) {
        Log::do_log('err', 'Could not lock database: (%s) %s',
            $self->{'dbh'}->err, $self->{'dbh'}->errstr);
        return undef;
    }

    ## do query
    $sth = $self->SUPER::do_prepared_query(@_);

    ## release lock
    return $sth unless $need_lock;
    eval {
        if ($sth) {
            $rc = $self->{'dbh'}->commit;
        } else {
            $rc = $self->{'dbh'}->rollback;
        }
    };
    if ($EVAL_ERROR or !$rc) {
        Log::do_log(
            'err',
            'Could not unlock database: %s',
            $EVAL_ERROR || sprintf('(%s) %s',
                $self->{'dbh'}->err, $self->{'dbh'}->errstr)
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
        Log::do_log('err',
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

    Log::do_log(
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
        Log::do_log('err', 'Table "%s" does not exist', $table);
        return undef;
    }

    $statement =~
        s/^\s*CREATE\s+TABLE\s+([\"\w]+)/CREATE TABLE ${table_saved}_new/;

    my $statement_orig = $statement;
    $statement =~ s/$regex/$replacement/;
    if ($statement eq $statement_orig) {
        Log::do_log('err', 'Table "%s" was not changed', $table);
        return undef;
    }
    $statement =~ s/\btemporary\s+INT,\s*//;    # Omit "temporary" field.

    my $s = $statement;
    $s =~ s/\n\s*/ /g;
    $s =~ s/\t/ /g;
    Log::do_log('info', '%s', $s);

    unless ($self->do_query('%s', $statement)) {
        Log::do_log('err', 'Could not create temporary table "%s_new"',
            $table_saved);
        return undef;
    }

    Log::do_log('info', 'Copy "%s" to "%s_new"', $table, $table_saved);
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
        Log::do_log('Could not get table \'%s\' on database \'%s\'',
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
        Log::do_log('err',
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
        Log::do_log('err', 'Could not rename table "%s" to "%s"',
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
        unless ($self->do_query(q{DROP TABLE "%s"}, $table)) {
            Log::do_log('err', 'Could not drop table "%s"', $table);
            return undef;
        }
        return 0;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DBManipulatorSQLite - Database driver for SQLite

=head1 SEE ALSO

L<Sympa::DBManipulatorDefault>, L<SDM>.

=cut
