# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::DatabaseDriver::Sybase;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::DatabaseDriver);

my $log = Sympa::Log->instance;

use constant required_modules => [qw(DBD::Sybase)];

sub build_connect_string {
    my $self = shift;

    my $connect_string =
        "DBI:Sybase:database=$self->{'db_name'};server=$self->{'db_host'}";
    $connect_string .= ';port=' . $self->{'db_port'}
        if defined $self->{'db_port'};
    $connect_string .= ';' . $self->{'db_options'}
        if defined $self->{'db_options'};
    return $connect_string;
}

sub connect {
    my $self = shift;

    # Client encoding derived from the environment variable.
    # Set this before parsing db_env to allow override if one knows what
    # she is doing.
    $ENV{'SYBASE_CHARSET'} = 'utf8';

    $self->SUPER::connect() or return undef;

    $self->__dbh->do("use $self->{'db_name'}");

    # We set long preload length instead of defaulting to 32768.
    $self->__dbh->{LongReadLen} = 204800;
    $self->__dbh->{LongTruncOk} = 0;

    return 1;
}

sub get_substring_clause {
    my $self  = shift;
    my $param = shift;
    return
          "substring("
        . $param->{'source_field'}
        . ",charindex('"
        . $param->{'separator'} . "',"
        . $param->{'source_field'} . ")+1,"
        . $param->{'substring_length'} . ")";
}

# DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

sub get_formatted_date {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug', 'Building SQL date formatting');
    if (lc($param->{'mode'}) eq 'read') {
        return sprintf 'datediff(second, \'01/01/1970\',%s)',
            $param->{'target'};
    } elsif (lc($param->{'mode'}) eq 'write') {
        return sprintf 'dateadd(second,%s,\'01/01/1970\')',
            $param->{'target'};
    } else {
        $log->syslog('err', "Unknown date format mode %s", $param->{'mode'});
        return undef;
    }
}

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
    $log->syslog('debug', 'Setting field %s.%s as autoincremental',
        $param->{'field'}, $param->{'table'});
    unless (
        $self->do_query(
            "ALTER TABLE `%s` CHANGE `%s` `%s` BIGINT( 20 ) NOT NULL AUTO_INCREMENT",
            $param->{'table'}, $param->{'field'}, $param->{'field'}
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
    my @raw_tables;
    my $sth;
    unless (
        $sth = $self->do_query(
            "SELECT name FROM %s..sysobjects WHERE type='U'",
            $self->{'db_name'}
        )
        ) {
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
    my $report = "Table $param->{'table'}, index %s set using $fields";
    $log->syslog('info', 'Table %s, index %s set using fields %s',
        $param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
}

sub translate_type {
    my $self = shift;
    my $type = shift;

    return undef unless $type;

    # Sybase
    $type =~ s/^int.*/numeric/g;
    $type =~ s/^text.*/varchar(500)/g;
    $type =~ s/^smallint.*/numeric/g;
    $type =~ s/^bigint.*/numeric/g;
    $type =~ s/^double/double precision/g;
    $type =~ s/^longtext.*/text/g;
    $type =~ s/^enum.*/varchar(15)/g;
    $type =~ s/^mediumblob/long binary/g;
    return $type;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::Sybase - Database driver for Adaptive Server Enterprise

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
