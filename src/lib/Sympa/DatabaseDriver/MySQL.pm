# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::DatabaseDriver::MySQL;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::DatabaseDriver);

my $log = Sympa::Log->instance;

use constant required_modules => [qw(DBD::mysql)];

sub build_connect_string {
    my $self = shift;

    my $connect_string =
          'DBI:mysql:'
        . $self->{'db_name'} . ':'
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

    # - At first, reset "mysql_auto_reconnect" driver attribute.
    #   DBI::connect() sets it to true not according to \%attr argument
    #   when the processes are running under mod_perl or CGI environment
    #   so that "SET NAMES utf8" will be skipped.
    # - Set client-side character set to "utf8" or "utf8mb4".
    # - Reset SQL mode that is given various default by versions of MySQL.
    $self->__dbh->{'mysql_auto_reconnect'} = 0;
    unless (defined $self->__dbh->do("SET NAMES 'utf8mb4'")
        or defined $self->__dbh->do("SET NAMES 'utf8'")) {
        $log->syslog('err', 'Cannot set client-side character set: %s',
            $self->error);
    }
    unless (defined $self->__dbh->do("SET SESSION sql_mode=''")) {
        $log->syslog('err', 'Cannot reset SQL mode: %s', $self->error);
        return undef;
    }

    return 1;
}

sub get_substring_clause {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Building substring caluse');
    return
          "REVERSE(SUBSTRING("
        . $param->{'source_field'}
        . " FROM position('"
        . $param->{'separator'} . "' IN "
        . $param->{'source_field'}
        . ") FOR "
        . $param->{'substring_length'} . "))";
}

# DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

# DEPRECATED.
#sub get_formatted_date;

sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Checking whether field %s.%s is autoincremental',
        $param->{'field'}, $param->{'table'});
    my $sth;
    unless (
        $sth = $self->do_query(
            "SHOW FIELDS FROM `%s` WHERE Extra ='auto_increment' and Field = '%s'",
            $param->{'table'},
            $param->{'field'}
        )
    ) {
        $log->syslog('err',
            'Unable to gather autoincrement field named %s for table %s',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    my $ref = $sth->fetchrow_hashref('NAME_lc');
    return ($ref->{'field'} eq $param->{'field'});
}

sub set_autoinc {
    my $self  = shift;
    my $param = shift;
    my $field_type =
        defined($param->{'field_type'})
        ? $param->{'field_type'}
        : 'BIGINT( 20 )';
    $log->syslog('debug', 'Setting field %s.%s as autoincremental',
        $param->{'field'}, $param->{'table'});
    unless (
        $self->do_query(
            "ALTER TABLE `%s` CHANGE `%s` `%s` %s NOT NULL AUTO_INCREMENT",
            $param->{'table'}, $param->{'field'},
            $param->{'field'}, $field_type
        )
    ) {
        $log->syslog('err',
            'Unable to set field %s in table %s as autoincrement',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    return 1;
}

sub get_tables {
    my $self = shift;
    $log->syslog('debug', 'Retrieving all tables in database %s',
        $self->{'db_name'});
    my @raw_tables;
    my @result;
    unless (@raw_tables = $self->__dbh->tables()) {
        $log->syslog('err',
            'Unable to retrieve the list of tables from database %s',
            $self->{'db_name'});
        return undef;
    }

    foreach my $t (@raw_tables) {
        # Clean table names that would look like `databaseName`.`tableName`
        # (mysql)
        $t =~ s/^\`[^\`]+\`\.//;
        # Clean table names that could be surrounded by `` (recent DBD::mysql
        # release)
        $t =~ s/^\`(.+)\`$/$1/;
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
        $self->do_query(
            "CREATE TABLE %s (temporary INT) DEFAULT CHARACTER SET utf8",
            $param->{'table'}
        )
    ) {
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
    unless ($sth = $self->do_query("SHOW FIELDS FROM %s", $param->{'table'}))
    {
        $log->syslog('err',
            'Could not get the list of fields from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        $result{$ref->{'field'}} = $ref->{'type'};
    }
    return \%result;
}

sub update_field {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Updating field %s in table %s (%s, %s)',
        $param->{'field'}, $param->{'table'}, $param->{'type'},
        $param->{'notnull'});
    my $options = '';
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL ';
    }
    my $report = sprintf(
        "ALTER TABLE %s CHANGE %s %s %s %s",
        $param->{'table'}, $param->{'field'}, $param->{'field'},
        $param->{'type'},  $options
    );
    $log->syslog('notice', "ALTER TABLE %s CHANGE %s %s %s %s",
        $param->{'table'}, $param->{'field'}, $param->{'field'},
        $param->{'type'}, $options);
    unless (
        $self->do_query(
            "ALTER TABLE %s CHANGE %s %s %s %s",
            $param->{'table'}, $param->{'field'}, $param->{'field'},
            $param->{'type'},  $options
        )
    ) {
        $log->syslog('err', 'Could not change field "%s" in table "%s"',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    $report .= sprintf("\nField %s in table %s, structure updated",
        $param->{'field'}, $param->{'table'});
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
    # To prevent "Cannot add a NOT NULL column with default value NULL" errors
    if ($param->{'notnull'}) {
        $options .= 'NOT NULL ';
    }
    if ($param->{'autoinc'}) {
        $options .= ' AUTO_INCREMENT ';
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
            "ALTER TABLE %s DROP COLUMN `%s`", $param->{'table'},
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
    unless ($sth = $self->do_query("SHOW COLUMNS FROM %s", $param->{'table'}))
    {
        $log->syslog('err',
            'Could not get field list from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $test_request_result = $sth->fetchall_hashref('field');
    foreach my $scannedResult (keys %$test_request_result) {
        if ($test_request_result->{$scannedResult}{'key'} eq "PRI") {
            $found_keys{$scannedResult} = 1;
        }
    }
    return \%found_keys;
}

sub unset_primary_key {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Removing primary key from table %s',
        $param->{'table'});

    my $sth;
    unless ($sth =
        $self->do_query("ALTER TABLE %s DROP PRIMARY KEY", $param->{'table'}))
    {
        $log->syslog('err',
            'Could not drop primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
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
    my $fields = join ',', @{$param->{'fields'}};
    $log->syslog('debug', 'Setting primary key for table %s (%s)',
        $param->{'table'}, $fields);
    unless (
        $sth = $self->do_query(
            "ALTER TABLE %s ADD PRIMARY KEY (%s)", $param->{'table'},
            $fields
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
    $log->syslog('debug', 'Looking for indexes in %s', $param->{'table'});

    my %found_indexes;
    my $sth;
    unless ($sth = $self->do_query("SHOW INDEX FROM %s", $param->{'table'})) {
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
        if ($index_part->{'key_name'} ne "PRIMARY") {
            my $index_name = $index_part->{'key_name'};
            my $field_name = $index_part->{'column_name'};
            $found_indexes{$index_name}{$field_name} = 1;
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
    unless (
        $sth = $self->do_query(
            "ALTER TABLE %s DROP INDEX %s", $param->{'table'},
            $param->{'index'}
        )
    ) {
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
            "ALTER TABLE %s ADD INDEX %s (%s)", $param->{'table'},
            $param->{'index_name'},             $fields
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

## For DOUBLE type.
sub AS_DOUBLE {
    return ({'mysql_type' => DBD::mysql::FIELD_TYPE_DOUBLE()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::MySQL - Database driver for MySQL / MariaDB

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
