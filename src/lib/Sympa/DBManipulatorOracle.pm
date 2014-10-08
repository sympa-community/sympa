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

package Sympa::DBManipulatorOracle;

use strict;
use warnings;
##use Data::Dumper;

use Sympa::DBManipulatorOracle::St;
use Log;

use base qw(Sympa::DBManipulatorDefault);

sub build_connect_string {
    my $self = shift;
    $self->{'connect_string'} = "DBI:Oracle:";
    if ($self->{'db_host'} && $self->{'db_name'}) {
        $self->{'connect_string'} .=
            "host=$self->{'db_host'};sid=$self->{'db_name'}";
    }
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

sub get_formatted_date {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Building SQL date formatting');
    if (lc($param->{'mode'}) eq 'read') {
        return
            sprintf
            q{((to_number(to_char(%s,'J')) - to_number(to_char(to_date('01/01/1970','dd/mm/yyyy'), 'J'))) * 86400) +to_number(to_char(%s,'SSSSS'))},
            $param->{'target'}, $param->{'target'};
    } elsif (lc($param->{'mode'}) eq 'write') {
        return
            sprintf
            q{to_date(to_char(floor(%s/86400) + to_number(to_char(to_date('01/01/1970','dd/mm/yyyy'), 'J'))) || ':' ||to_char(mod(%s,86400)), 'J:SSSSS')},
            $param->{'target'}, $param->{'target'};
    } else {
        Log::do_log('err', "Unknown date format mode %s", $param->{'mode'});
        return undef;
    }
}

sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Checking whether field %s.%s is autoincremental',
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
        Log::do_log('err',
            'Unable to gather autoincrement field named %s for table %s',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    return $sth->fetchrow_array;
}

#FIXME: Currently not works.
sub set_autoinc {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Setting field %s.%s as autoincremental',
        $param->{'field'}, $param->{'table'});
    unless (
        $self->do_query(
            "ALTER TABLE `%s` CHANGE `%s` `%s` BIGINT( 20 ) NOT NULL AUTO_INCREMENT",
            $param->{'table'}, $param->{'field'}, $param->{'field'}
        )
        ) {
        Log::do_log('err',
            'Unable to set field %s in table %s as autoincrement',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    return 1;
}

sub get_tables {
    my $self = shift;
    Log::do_log('debug', 'Retrieving all tables in database %s',
        $self->{'db_name'});
    my @raw_tables;
    my $sth;
    unless ($sth = $self->do_query("SELECT table_name FROM user_tables")) {
        Log::do_log('err',
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
    Log::do_log('debug', 'Getting fields list from table %s in database %s',
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
        Log::do_log('err',
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

#FIXME: Currently not works.
sub update_field {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Updating field %s in table %s (%s, %s)',
        $param->{'field'}, $param->{'table'}, $param->{'type'},
        $param->{'notnull'});
    my $options;
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL ';
    }
    my $report = sprintf(
        "ALTER TABLE %s CHANGE %s %s %s %s",
        $param->{'table'}, $param->{'field'}, $param->{'field'},
        $param->{'type'},  $options
    );
    Log::do_log('notice', "ALTER TABLE %s CHANGE %s %s %s %s",
        $param->{'table'}, $param->{'field'}, $param->{'field'},
        $param->{'type'}, $options);
    unless (
        $self->do_query(
            "ALTER TABLE %s CHANGE %s %s %s %s",
            $param->{'table'}, $param->{'field'}, $param->{'field'},
            $param->{'type'},  $options
        )
        ) {
        Log::do_log('err', 'Could not change field "%s" in table "%s"',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    $report .= sprintf("\nField %s in table %s, structure updated",
        $param->{'field'}, $param->{'table'});
    Log::do_log('info', 'Field %s in table %s, structure updated',
        $param->{'field'}, $param->{'table'});
    return $report;
}

#FIXME: Currently not works.
sub add_field {
    my $self  = shift;
    my $param = shift;
    Log::do_log(
        'debug',             'Adding field %s in table %s (%s, %s, %s, %s)',
        $param->{'field'},   $param->{'table'},
        $param->{'type'},    $param->{'notnull'},
        $param->{'autoinc'}, $param->{'primary'}
    );
    my $options;
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
        Log::do_log('err',
            'Could not add field %s to table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf('Field %s added to table %s (options : %s)',
        $param->{'field'}, $param->{'table'}, $options);
    Log::do_log('info', 'Field %s added to table %s (options: %s)',
        $param->{'field'}, $param->{'table'}, $options);

    return $report;
}

#FIXME: Currently not works.
sub delete_field {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Deleting field %s from table %s',
        $param->{'field'}, $param->{'table'});

    unless (
        $self->do_query(
            "ALTER TABLE %s DROP COLUMN `%s`", $param->{'table'},
            $param->{'field'}
        )
        ) {
        Log::do_log('err',
            'Could not delete field %s from table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf('Field %s removed from table %s',
        $param->{'field'}, $param->{'table'});
    Log::do_log('info', 'Field %s removed from table %s',
        $param->{'field'}, $param->{'table'});

    return $report;
}

sub get_primary_key {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Getting primary key for table %s',
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
        Log::do_log('err',
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

# Currently not work
sub unset_primary_key {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Removing primary key from table %s',
        $param->{'table'});

    return undef;    # Currently disabled.

    my $sth;
    unless (
        $sth = $self->do_query(
            q{ALTER TABLE %s
              DROP PRIMARY KEY CASCADE}, $param->{'table'}
        )
        ) {
        Log::do_log('err',
            'Could not drop primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $report = "Table $param->{'table'}, PRIMARY KEY dropped";
    Log::do_log('info', 'Table %s, PRIMARY KEY dropped', $param->{'table'});

    return $report;
}

# Currently not work
sub set_primary_key {
    my $self  = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',', @{$param->{'fields'}};
    Log::do_log('debug', 'Setting primary key for table %s (%s)',
        $param->{'table'}, $fields);
    my $pkname = $param->{'table'};
    $pkname =~ s/_table\z//;
    $pkname = "ind_$pkname";

    return undef;    # Currently disabled.

    unless (
        $sth = $self->do_query(
            q{ALTER TABLE %s
              ADD CONSTRAINT %s PRIMARY KEY (%s)}, $param->{'table'},
            $pkname,                               $fields
        )
        ) {
        Log::do_log(
            'err',
            'Could not set fields %s as primary key for table %s in database %s',
            $fields,
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    my $report = "Table $param->{'table'}, PRIMARY KEY set on $fields";
    Log::do_log('info', 'Table %s, PRIMARY KEY set on %s',
        $param->{'table'}, $fields);
    return $report;
}

#FIXME: Currently not works.
sub get_indexes {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Looking for indexes in %s', $param->{'table'});

    my %found_indexes;
    my $sth;
    unless ($sth = $self->do_query("SHOW INDEX FROM %s", $param->{'table'})) {
        Log::do_log(
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
    ##open TMP, ">>/tmp/toto"; print TMP Dumper(\%found_indexes); close TMP;
    return \%found_indexes;
}

#FIXME: Currently not works.
sub unset_index {
    my $self  = shift;
    my $param = shift;
    Log::do_log('debug', 'Removing index %s from table %s',
        $param->{'index'}, $param->{'table'});

    my $sth;
    unless (
        $sth = $self->do_query(
            "ALTER TABLE %s DROP INDEX %s", $param->{'table'},
            $param->{'index'}
        )
        ) {
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

#FIXME: Currently not works.
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
            "ALTER TABLE %s ADD INDEX %s (%s)", $param->{'table'},
            $param->{'index_name'},             $fields
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

sub do_query {
    my $self = shift;
    my $ret  = $self->SUPER::do_query(@_);
    if ($ret) {
        bless $ret => 'Sympa::DBManipulatorOracle::St';
    }
    return $ret;
}

sub do_prepared_query {
    my $self = shift;
    my $ret  = $self->SUPER::do_prepared_query(@_);
    if ($ret) {
        bless $ret => 'Sympa::DBManipulatorOracle::St';
    }
    return $ret;
}

sub AS_BLOB {
    return ({'ora_type' => DBD::Oracle::ORA_BLOB()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DBManipulatorOracle - Database driver for Oracle Database

=head1 SEE ALSO

L<Sympa::DBManipulatorDefault>, L<SDM>.

=cut
