# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2022, 2023 The Sympa Community. See the
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

package Sympa::DatabaseDriver::Oracle;

use strict;
use warnings;

use Sympa::DatabaseDriver::Oracle::St;
use Sympa::Log;

use base qw(Sympa::DatabaseDriver);

my $log = Sympa::Log->instance;

use constant required_modules => [qw(DBD::Oracle)];

sub build_connect_string {
    my $self = shift;

    my $connect_string = "DBI:Oracle:";
    if (    $self->{'db_host'}
        and $self->{'db_host'} ne 'none'
        and $self->{'db_name'}) {
        $connect_string .= "host=$self->{'db_host'};sid=$self->{'db_name'}";
        $connect_string .= ';port=' . $self->{'db_port'}
            if defined $self->{'db_port'};
    } elsif ($self->{'db_name'}) {
        $connect_string .= $self->{'db_name'};
    }
    $connect_string .= ';' . $self->{'db_options'}
        if defined $self->{'db_options'};
    return $connect_string;
}

sub connect {
    my $self = shift;

    # Client encoding derived from the environment variable.
    # Set this before parsing db_env to allow override if one knows what
    # she is doing.
    # NLS_LANG needs to be set before connecting, otherwise it's useless.
    # Underscore (_) and dot (.) are a vital part as NLS_LANG has the
    # syntax "language_territory.charset".
    #
    # NOTE: "UTF8" should be overridden by "AL32UTF8" on Oracle 9i
    # or later (use db_env).  Former can't correctly handle characters
    # beyond BMP.
    $ENV{'NLS_LANG'} = '_.UTF8';

    $self->SUPER::connect() or return undef;

    # We set long preload length instead of defaulting to 80.
    $self->__dbh->{LongReadLen} = 204800;
    $self->__dbh->{LongTruncOk} = 0;

    return 1;
}

sub get_substring_clause {
    my $self  = shift;
    my $param = shift;
    return
          "substr("
        . $param->{'source_field'}
        . ",instr("
        . $param->{'source_field'} . ",'"
        . $param->{'separator'} . "')+1)";
}

#DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

#DEPRECATED.
#sub get_formatted_date;

sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Checking whether field %s.%s is autoincremental',
        $param->{'field'}, $param->{'table'});
    my $sth;
    unless (
        $sth = $self->do_prepared_query(
            q{SELECT COUNT(trigger_name)
              FROM user_triggers
              WHERE table_name = ? AND trigger_name = ?},
            uc($param->{'table'}),
            uc('trg_' . $param->{'field'})
        )
    ) {
        $log->syslog('err',
            'Unable to gather autoincrement field named %s for table %s',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    return $sth->fetchrow_array;
}

sub set_autoinc {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Setting field %s.%s as autoincremental',
        $param->{'field'}, $param->{'table'});

    my $field = $param->{'field'};
    my $table = $param->{'table'};

    # Check if sequence already exists.
    my $seq_exists;
    my $sth = $self->do_query(
        q{SELECT COUNT(*)
          FROM all_objects
          WHERE object_type = 'SEQUENCE' AND object_name = '%s'},
        uc sprintf('seq_%s', $field)
    );
    if ($sth) {
        ($seq_exists) = $sth->fetchrow_array;
        $sth->finish;
    }

    # (Re-)create trigger.
    unless (
        ($seq_exists or $self->do_query(q{CREATE SEQUENCE seq_%s}, $field))
        and $self->do_query(
            q{CREATE OR REPLACE TRIGGER trg_%s
              BEFORE INSERT ON %s
              FOR EACH ROW BEGIN
                SELECT seq_%s.nextval
                INTO :new.%s
                FROM dual;
              END;}, $field, $table, $field, $field
        )
    ) {
        $log->syslog('err',
            'Unable to set field %s in table %s as autoincrement',
            $field, $table);
        return undef;
    }
    return 1;
}

sub get_tables {
    my $self = shift;
    $log->syslog('debug', 'Retrieving all tables in database %s',
        $self->{'db_name'});
    my @raw_tables;
    my $sth;
    unless ($sth = $self->do_query("SELECT table_name FROM user_tables")) {
        $log->syslog('err',
            'Unable to retrieve the list of tables from database %s',
            $self->{'db_name'});
        return undef;
    }
    while (my $table = $sth->fetchrow()) {
        push @raw_tables, lc($table);
    }
    return \@raw_tables;
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
    $log->syslog('debug', 'Getting fields list from table %s in database %s',
        $param->{'table'}, $self->{'db_name'});
    my $sth;
    my %result;
    unless (
        $sth = $self->do_prepared_query(
            q{SELECT column_name, data_type, data_length
              FROM all_tab_columns
              WHERE table_name = ?}, uc($param->{'table'})
        )
    ) {
        $log->syslog('err',
            'Could not get the list of fields from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        my $data_type   = lc($ref->{'data_type'});
        my $data_length = $ref->{'data_length'};
        my $type;
        if (   not $data_length
            or $data_type eq 'number' and $data_length == 22
            or $data_type eq 'date') {
            $type = $data_type;
        } else {
            $type = sprintf '%s(%s)', $data_type, $data_length;
        }
        $result{lc($ref->{'column_name'})} = $type;
    }
    return \%result;
}

sub update_field {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Updating field %s in table %s (%s, %s)',
        $param->{'field'}, $param->{'table'}, $param->{'type'},
        $param->{'notnull'});

    # Check NOT NULL constraint on current field.
    # If new constraint in the query below is same as old one, query fails.
    my $sth = $self->do_prepared_query(
        q{SELECT nullable
          FROM all_tab_columns
          WHERE table_name = ? AND column_name = ?},
        uc($param->{'table'}), uc($param->{'field'})
    );
    unless ($sth) {
        return undef;
    }
    my ($nullable) = $sth->fetchrow_array;
    $sth->finish;

    my $options = '';
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL' unless $nullable and $nullable eq 'N';
    } else {
        $options .= ' NULL' if $nullable and $nullable eq 'N';
    }

    unless (
        $self->do_query(
            q{ALTER TABLE %s
              MODIFY (%s %s %s)},
            $param->{'table'}, $param->{'field'}, $param->{'type'}, $options
        )
    ) {
        $log->syslog('err', 'Could not change field "%s" in table "%s"',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    my $report = sprintf 'Field %s in table %s, structure updated',
        $param->{'field'}, $param->{'table'};
    $log->syslog('info', 'Field %s in table %s, structure updated',
        $param->{'field'}, $param->{'table'});
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
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL';
    }

    unless (
        $self->do_query(
            q{ALTER TABLE %s
              ADD (%s %s %s)},
            $param->{'table'}, $param->{'field'}, $param->{'type'}, $options
        )
    ) {
        $log->syslog('err',
            'Could not add field %s to table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf 'Field %s added to table %s (options : %s)',
        $param->{'field'}, $param->{'table'}, $options;
    $log->syslog('info', 'Field %s added to table %s (options: %s)',
        $param->{'field'}, $param->{'table'}, $options);

    return $report;
}

sub drop_field {
    $log->syslog('debug', '(%s, %s, %s)', @_);
    my $self  = shift;
    my $table = shift;
    my $field = shift;

    unless ($self->do_query(q{ALTER TABLE %s DROP (%s)}, $table, $field)) {
        $log->syslog('err',
            'Could not delete field %s from table %s in database %s',
            $field, $table, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf 'Field %s removed from table %s', $field, $table;
    $log->syslog('info', '%s', $report);

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
        $sth = $self->do_prepared_query(
            q{SELECT cols.column_name
              FROM all_cons_columns cols, all_constraints cons
              WHERE cons.constraint_type = 'P' AND
                    cols.constraint_name = cons.constraint_name AND
                    cols.owner = cons.owner AND
                    cols.table_name = cons.table_name AND
                    cons.table_name = ?},
            uc($param->{'table'})
        )
    ) {
        $log->syslog('err',
            'Could not get field list from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $field;
    while ($field = $sth->fetchrow_array) {
        $found_keys{lc $field} = 1;
    }
    return \%found_keys;
}

sub unset_primary_key {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Removing primary key from table %s',
        $param->{'table'});

    my $sth;
    unless (
        $sth = $self->do_query(
            q{ALTER TABLE %s
              DROP PRIMARY KEY}, $param->{'table'}
        )
    ) {
        $log->syslog('err',
            'Could not drop primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $report = sprintf 'Table %s, PRIMARY KEY dropped', $param->{'table'};
    $log->syslog('info', 'Table %s, PRIMARY KEY dropped', $param->{'table'});

    return $report;
}

sub set_primary_key {
    my $self  = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',', @{$param->{'fields'}};
    $log->syslog('debug', 'Setting primary key for table %s (%s)',
        $param->{'table'}, $fields);
    my $pkname = $param->{'table'};
    $pkname =~ s/_table\z//;
    $pkname = "ind_$pkname";

    unless (
        $sth = $self->do_query(
            q{ALTER TABLE %s
              ADD CONSTRAINT %s PRIMARY KEY (%s)},
            $param->{'table'}, $pkname, $fields
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
    my $report = sprintf 'Table %s, PRIMARY KEY set on %s', $param->{'table'},
        $fields;
    $log->syslog('info', 'Table %s, PRIMARY KEY set on %s',
        $param->{'table'}, $fields);
    return $report;
}

# Note: We assume that indexes other than primary key are _not_ unique keys.
sub get_indexes {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Looking for indexes in %s', $param->{'table'});

    my %found_indexes;
    my $sth;
    unless (
        $sth = $self->do_prepared_query(
            q{SELECT index_name, column_name
              FROM all_indexes NATURAL JOIN all_ind_columns
              WHERE generated = 'N' AND table_name = ?},
            uc $param->{'table'}
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
    my $index_part;
    while ($index_part = $sth->fetchrow_hashref('NAME_lc')) {
        my $index_name = lc $index_part->{'index_name'};
        my $field_name = lc $index_part->{'column_name'};
        $found_indexes{$index_name}{$field_name} = 1;
    }
    $sth->finish;

    return \%found_indexes;
}

sub unset_index {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Removing index %s from table %s',
        $param->{'index'}, $param->{'table'});

    my $sth;
    unless ($sth = $self->do_query(q{DROP INDEX %s}, $param->{'index'})) {
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
            q{CREATE INDEX %s
              ON %s (%s)},
            $param->{'index_name'}, $param->{'table'}, $fields
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

    # Oracle
    $type =~ s/^varchar/varchar2/g;
    $type =~ s/^int.*/number/g;
    $type =~ s/^bigint.*/number/g;
    $type =~ s/^smallint.*/number/g;
    $type =~ s/^tinyint.*/number/g;
    $type =~ s/^double/number/g;
    $type =~ s/^enum.*/varchar2(20)/g;
    # varchar2(500) on <= 6.2.36
    # FIXME: Oracle 8 and later support varchar2 up to 4000 o.
    $type =~ s/^text.*/varchar2(2000)/g;
    $type =~ s/^longtext.*/long/g;
    $type =~ s/^datetime.*/date/g;
    $type =~ s/^mediumblob/blob/g;
    return $type;
}

sub do_query {
    my $self = shift;
    my $ret  = $self->SUPER::do_query(@_);
    if ($ret) {
        bless $ret => 'Sympa::DatabaseDriver::Oracle::St';
    }
    return $ret;
}

sub do_prepared_query {
    my $self = shift;
    my $ret  = $self->SUPER::do_prepared_query(@_);
    if ($ret) {
        bless $ret => 'Sympa::DatabaseDriver::Oracle::St';
    }
    return $ret;
}

sub AS_BLOB {
    return ({'ora_type' => DBD::Oracle::ORA_BLOB()} => $_[1])
        if scalar @_ > 1;
    return ();
}

sub md5_func {
    shift;

    return sprintf q{LOWER(RAWTOHEX(STANDARD_HASH(%s, 'MD5')))},
        join ' || ', map { sprintf 'TO_CHAR(%s)', $_ } @_;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::Oracle - Database driver for Oracle Database

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
