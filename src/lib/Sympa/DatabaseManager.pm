# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2021 The Sympa Community. See the
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

package Sympa::DatabaseManager;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Database;
use Sympa::DatabaseDescription;
use Sympa::Log;

my $log = Sympa::Log->instance;

our $instance;

# NOTE: This method actually returns an instance of Sympa::DatabaseDriver
# subclass not inheriting this class.  That's why probe_db() isn't the method
# but a static function.
sub instance {
    my $class = shift;

    return $instance if $instance;

    my $self;
    my $db_conf = Conf::get_parameters_group('*', 'Database related');

    return undef
        unless $self = Sympa::Database->new($db_conf->{'db_type'}, %$db_conf)
        and $self->connect;

    # At once connection succeeded, we keep trying to connect.
    # Unless in a web context, because we can't afford long response time on
    # the web interface.
    $self->set_persistent(1) unless $ENV{'GATEWAY_INTERFACE'};

    $instance = $self;
    return $self;
}

sub disconnect {
    my $class = shift;

    return 0 unless $instance;

    $instance->set_persistent(0);
    $instance->disconnect;
    undef $instance;
    return 1;
}

# db structure description has moved in Sympa::DatabaseDescription.
my %not_null      = Sympa::DatabaseDescription::not_null();
my %primary       = Sympa::DatabaseDescription::primary();
my %autoincrement = Sympa::DatabaseDescription::autoincrement();

# List the required INDEXES
#   1st key is the concerned table
#   2nd key is the index name
#   the table lists the field on which the index applies
my %indexes = %Sympa::DatabaseDescription::indexes;

# table indexes that can be removed during upgrade process
my @former_indexes = @Sympa::DatabaseDescription::former_indexes;

sub probe_db {
    $log->syslog('debug3', 'Checking database structure');

    my $sdm = __PACKAGE__->instance;
    unless ($sdm) {
        $log->syslog('err',
            'Could not check the database structure.  Make sure that database connection is available'
        );
        return undef;
    }

    my $db_struct = _db_struct($sdm);
    my $update_db_field_types =
        Conf::get_robot_conf('*', 'update_db_field_types') || 'off';

    # Does the driver support probing database structure?
    foreach my $method (
        qw(is_autoinc get_tables get_fields get_primary_key get_indexes)) {
        unless ($sdm->can($method)) {
            $log->syslog('notice',
                'Could not check the database structure: required methods have not been implemented'
            );
            return 1;
        }
    }

    # Does the driver support updating database structure?
    my $may_update;
    unless ($update_db_field_types eq 'auto') {
        $may_update = 0;
    } else {
        $may_update = 1;
        foreach my $method (
            qw(set_autoinc add_table update_field add_field delete_field
            unset_primary_key set_primary_key unset_index set_index)
        ) {
            unless ($sdm->can($method)) {
                $may_update = 0;
                last;
            }
        }
    }

    ## Database structure
    ## Report changes to listmaster
    my @report;

    ## Get tables
    my @tables;
    my $list_of_tables;
    if ($list_of_tables = $sdm->get_tables()) {
        @tables = @{$list_of_tables};
    } else {
        @tables = ();
    }

    my %real_struct;
    # Check required tables
    foreach my $t1 (keys %$db_struct) {
        my $found;
        foreach my $t2 (@tables) {
            $found = 1 if ($t1 eq $t2);
        }
        unless ($found) {
            my $rep;
            if (    $may_update
                and $rep = $sdm->add_table({'table' => $t1})) {
                push @report, $rep;
                $log->syslog(
                    'notice', 'Table %s created in database %s',
                    $t1, Conf::get_robot_conf('*', 'db_name')
                );
                push @tables, $t1;
                $real_struct{$t1} = {};
            }
        }
    }
    ## Get fields
    foreach my $t (keys %$db_struct) {
        $real_struct{$t} = $sdm->get_fields({'table' => $t});
    }
    ## Check tables structure if we could get it
    ## Only performed with mysql , Pg and SQLite
    if (%real_struct) {
        foreach my $t (keys %$db_struct) {
            unless ($real_struct{$t}) {
                $log->syslog(
                    'err',
                    'Table "%s" not found in database "%s"; you should create it with create_db.%s script',
                    $t,
                    Conf::get_robot_conf('*', 'db_name'),
                    Conf::get_robot_conf('*', 'db_type')
                );
                return undef;
            }
            unless (
                _check_fields(
                    $sdm,
                    {   'table'       => $t,
                        'report'      => \@report,
                        'real_struct' => \%real_struct,
                        'may_update'  => $may_update,
                    }
                )
            ) {
                $log->syslog(
                    'err',
                    'Unable to check the validity of fields definition for table %s. Aborting',
                    $t
                );
                return undef;
            }
            ## Remove temporary DB field
            if ($may_update and $real_struct{$t}{'temporary'}) {
                $sdm->delete_field(
                    {   'table' => $t,
                        'field' => 'temporary',
                    }
                );
                delete $real_struct{$t}{'temporary'};
            }

            ## Check that primary key has the right structure.
            unless (
                _check_primary_key(
                    $sdm,
                    {   'table'      => $t,
                        'report'     => \@report,
                        'may_update' => $may_update
                    }
                )
            ) {
                $log->syslog(
                    'err',
                    'Unable to check the validity of primary key for table %s. Aborting',
                    $t
                );
                return undef;
            }

            unless (
                _check_indexes(
                    $sdm,
                    {   'table'      => $t,
                        'report'     => \@report,
                        'may_update' => $may_update
                    }
                )
            ) {
                $log->syslog(
                    'err',
                    'Unable to check the valifity of indexes for table %s. Aborting',
                    $t
                );
                return undef;
            }
        }
        # add autoincrement if needed
        foreach my $table (keys %autoincrement) {
            unless (
                $sdm->is_autoinc(
                    {'table' => $table, 'field' => $autoincrement{$table}}
                )
            ) {
                if ($may_update
                    and $sdm->set_autoinc(
                        {   'table'      => $table,
                            'field'      => $autoincrement{$table},
                            'field_type' => $db_struct->{$table}
                                ->{$autoincrement{$table}},
                        }
                    )
                ) {
                    $log->syslog('notice',
                        "Setting table $table field $autoincrement{$table} as autoincrement"
                    );
                } else {
                    $log->syslog('err',
                        "Could not set table $table field $autoincrement{$table} as autoincrement"
                    );
                    return undef;
                }
            }
        }
    } else {
        $log->syslog('err',
            "Could not check the database structure. consider verify it manually before launching Sympa."
        );
        return undef;
    }

    ## Notify listmaster
    Sympa::send_notify_to_listmaster('*', 'db_struct_updated',
        {'report' => \@report})
        if @report;

    return 1;
}

# Returns a hashref definition by all types of RDBMS Sympa supports.
# Keys are table names and values are hashrefs with keys as field names and
# values are their field types converted according to database driver.
sub _db_struct {
    my $sdm = shift;

    my $db_struct;
    my %full_db_struct = Sympa::DatabaseDescription::full_db_struct();

    foreach my $table (keys %full_db_struct) {
        foreach my $field (keys %{$full_db_struct{$table}{'fields'}}) {
            my $trans =
                $sdm->translate_type(
                $full_db_struct{$table}{'fields'}{$field}{'struct'});

            $db_struct->{$table} ||= {};
            $db_struct->{$table}->{$field} = $trans;
        }
    }
    return $db_struct;
}

sub _check_fields {
    my $sdm         = shift;
    my $param       = shift;
    my $t           = $param->{'table'};
    my %real_struct = %{$param->{'real_struct'}};
    my $report_ref  = $param->{'report'};
    my $may_update  = $param->{'may_update'};

    my $db_struct = _db_struct($sdm);

    foreach my $f (sort keys %{$db_struct->{$t}}) {
        unless ($real_struct{$t}{$f}) {
            push @{$report_ref},
                sprintf(
                "Field '%s' (table '%s' ; database '%s') was NOT found. Attempting to add it...",
                $f, $t, Conf::get_robot_conf('*', 'db_name'));
            $log->syslog(
                'notice',
                'Field "%s" (table "%s"; database "%s") was NOT found. Attempting to add it...',
                $f,
                $t,
                Conf::get_robot_conf('*', 'db_name')
            );

            my $rep;
            if ($may_update
                and $rep = $sdm->add_field(
                    {   'table'   => $t,
                        'field'   => $f,
                        'type'    => $db_struct->{$t}->{$f},
                        'notnull' => $not_null{$f},
                        'autoinc' =>
                            ($autoincrement{$t} and $autoincrement{$t} eq $f),
                        'primary' => (
                            scalar @{$primary{$t} || []} == 1
                                and $primary{$t}->[0] eq $f
                        ),
                    }
                )
            ) {
                push @{$report_ref}, $rep;
            } else {
                $log->syslog('err',
                    'Addition of fields in database failed. Aborting');
                return undef;
            }
            next;
        }

        ## Change DB types if different and if update_db_types enabled
        if ($may_update) {
            unless (
                $sdm->is_sufficient_field_type(
                    $db_struct->{$t}->{$f},
                    $real_struct{$t}{$f}
                )
            ) {
                push @{$report_ref},
                    sprintf(
                    "Field '%s'  (table '%s' ; database '%s') does NOT have awaited type (%s). Attempting to change it...",
                    $f, $t,
                    Conf::get_robot_conf('*', 'db_name'),
                    $db_struct->{$t}->{$f}
                    );

                $log->syslog(
                    'notice',
                    'Field "%s" (table "%s"; database "%s") does NOT have awaited type (%s) where type in database seems to be (%s). Attempting to change it...',
                    $f,
                    $t,
                    Conf::get_robot_conf('*', 'db_name'),
                    $db_struct->{$t}->{$f},
                    $real_struct{$t}{$f}
                );

                my $rep;
                if ($may_update
                    and $rep = $sdm->update_field(
                        {   'table'   => $t,
                            'field'   => $f,
                            'type'    => $db_struct->{$t}->{$f},
                            'notnull' => $not_null{$f},
                        }
                    )
                ) {
                    push @{$report_ref}, $rep;
                } else {
                    $log->syslog('err',
                        'Fields update in database failed. Aborting');
                    return undef;
                }
            }
        } else {
            unless ($real_struct{$t}{$f} eq $db_struct->{$t}->{$f}) {
                $log->syslog(
                    'err',
                    'Field "%s" (table "%s"; database "%s") does NOT have awaited type (%s)',
                    $f,
                    $t,
                    Conf::get_robot_conf('*', 'db_name'),
                    $db_struct->{$t}->{$f}
                );
                $log->syslog('err',
                    'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES'
                );
                return undef;
            }
        }
    }
    return 1;
}

sub _check_primary_key {
    my $sdm        = shift;
    my $param      = shift;
    my $t          = $param->{'table'};
    my $report_ref = $param->{'report'};
    my $may_update = $param->{'may_update'};

    my $list_of_keys = join ',', @{$primary{$t}};
    my $key_as_string = "$t [$list_of_keys]";
    $log->syslog('debug',
        'Checking primary keys for table %s expected_keys %s',
        $t, $key_as_string);

    my $should_update = _check_key(
        $sdm,
        {   'table'         => $t,
            'key_name'      => 'primary',
            'expected_keys' => $primary{$t}
        }
    );
    if ($should_update) {
        my $list_of_keys = join ',', @{$primary{$t}};
        my $key_as_string = "$t [$list_of_keys]";

        # Fixup: At 6.2a.29 r7637, family_exclusion field became a part of
        # primary key.  But it could contain NULL and may break not_null
        # constraint.
        if (grep { $_ eq 'family_exclusion' } @{$primary{$t}}) {
            $sdm->do_query(
                q{UPDATE exclusion_table
                  SET family_exclusion = ''
                  WHERE family_exclusion IS NULL}
            );
        }

        if ($should_update->{'empty'}) {
            if (@{$primary{$t}}) {
                $log->syslog('notice', 'Primary key %s is missing. Adding it',
                    $key_as_string);
                ## Add primary key
                my $rep = undef;
                if ($may_update
                    and $rep = $sdm->set_primary_key(
                        {'table' => $t, 'fields' => $primary{$t}}
                    )
                ) {
                    push @{$report_ref}, $rep;
                } else {
                    return undef;
                }
            }
        } elsif ($should_update->{'existing_key_correct'}) {
            $log->syslog('debug',
                "Existing key correct (%s) nothing to change",
                $key_as_string);
        } else {
            ## drop previous primary key
            my $rep = undef;
            if (    $may_update
                and $rep = $sdm->unset_primary_key({'table' => $t})) {
                push @{$report_ref}, $rep;
            } else {
                return undef;
            }
            ## Add primary key
            if (@{$primary{$t}}) {
                $rep = undef;
                if ($may_update
                    and $rep = $sdm->set_primary_key(
                        {'table' => $t, 'fields' => $primary{$t}}
                    )
                ) {
                    push @{$report_ref}, $rep;
                } else {
                    return undef;
                }
            }
        }
    } else {
        $log->syslog('err', 'Unable to evaluate table %s primary key', $t);
        return undef;
    }
    return 1;
}

sub _check_indexes {
    my $sdm        = shift;
    my $param      = shift;
    my $t          = $param->{'table'};
    my $report_ref = $param->{'report'};
    my $may_update = $param->{'may_update'};
    $log->syslog('debug', 'Checking indexes for table %s', $t);

    ## drop previous index if this index is not a primary key and was defined
    ## by a previous Sympa version
    my %index_columns = %{$sdm->get_indexes({'table' => $t})};
    foreach my $idx (keys %index_columns) {
        $log->syslog('debug', 'Found index %s', $idx);
        ## Remove the index if obsolete.
        foreach my $known_index (@former_indexes) {
            if ($idx eq $known_index) {
                my $rep;
                $log->syslog('notice', 'Removing obsolete index %s', $idx);
                if (    $may_update
                    and $rep =
                    $sdm->unset_index({'table' => $t, 'index' => $idx})) {
                    push @{$report_ref}, $rep;
                }
                last;
            }
        }
    }

    ## Create required indexes
    foreach my $idx (keys %{$indexes{$t}}) {
        ## Add indexes
        unless ($index_columns{$idx}) {
            my $rep;
            $log->syslog('notice',
                'Index %s on table %s does not exist. Adding it',
                $idx, $t);
            if ($may_update
                and $rep = $sdm->set_index(
                    {   'table'      => $t,
                        'index_name' => $idx,
                        'fields'     => $indexes{$t}{$idx}
                    }
                )
            ) {
                push @{$report_ref}, $rep;
            }
        }
        my $index_check = _check_key(
            $sdm,
            {   'table'         => $t,
                'key_name'      => $idx,
                'expected_keys' => $indexes{$t}{$idx}
            }
        );
        if ($index_check) {
            my $list_of_fields = join ',', @{$indexes{$t}{$idx}};
            my $index_as_string = "$idx: $t [$list_of_fields]";
            if ($index_check->{'empty'}) {
                ## Add index
                my $rep = undef;
                $log->syslog('notice', 'Index %s is missing. Adding it',
                    $index_as_string);
                if ($may_update
                    and $rep = $sdm->set_index(
                        {   'table'      => $t,
                            'index_name' => $idx,
                            'fields'     => $indexes{$t}{$idx}
                        }
                    )
                ) {
                    push @{$report_ref}, $rep;
                } else {
                    return undef;
                }
            } elsif ($index_check->{'existing_key_correct'}) {
                $log->syslog('debug',
                    "Existing index correct (%s) nothing to change",
                    $index_as_string);
            } else {
                ## drop previous index
                $log->syslog('notice',
                    'Index %s has not the right structure. Changing it',
                    $index_as_string);
                my $rep = undef;
                if (    $may_update
                    and $rep =
                    $sdm->unset_index({'table' => $t, 'index' => $idx})) {
                    push @{$report_ref}, $rep;
                }
                ## Add index
                $rep = undef;
                if ($may_update
                    and $rep = $sdm->set_index(
                        {   'table'      => $t,
                            'index_name' => $idx,
                            'fields'     => $indexes{$t}{$idx}
                        }
                    )
                ) {
                    push @{$report_ref}, $rep;
                } else {
                    return undef;
                }
            }
        } else {
            $log->syslog('err', 'Unable to evaluate index %s in table %s',
                $idx, $t);
            return undef;
        }
    }
    return 1;
}

# Checks the compliance of a key of a table compared to what it is supposed to
# reference.
#
# IN: A ref to hash containing the following keys:
# * 'table' : the name of the table for which we want to check the primary key
# * 'key_name' : the kind of key tested:
#   - if the value is 'primary', the key tested will be the table primary key
#   - for any other value, the index whose name is this value will be tested.
# * 'expected_keys' : A ref to an array containing the list of fields that we
#   expect to be part of the key.
#
# OUT: - Returns a ref likely to contain the following values:
# * 'empty': if this key is defined, then no key was found for the table
# * 'existing_key_correct': if this key's value is 1, then a key
#   exists and is fair to the structure defined in the 'expected_keys'
#   parameter hash.
#   Otherwise, the key is not correct.
# * 'missing_key': if this key is defined, then a part of the key was missing.
#   The value associated to this key is a hash whose keys are the names
#   of the fields missing in the key.
# * 'unexpected_key': if this key is defined, then we found fields in the
#   actual key that don't belong to the list provided in the 'expected_keys'
#   parameter hash.
#   The value associated to this key is a hash whose keys are the names of the
#   fields unexpectedely found.
sub _check_key {
    my $sdm   = shift;
    my $param = shift;
    $log->syslog('debug', 'Checking %s key structure for table %s',
        $param->{'key_name'}, $param->{'table'});
    my $keysFound;
    my $result;
    if (lc($param->{'key_name'}) eq 'primary') {
        return undef
            unless ($keysFound =
            $sdm->get_primary_key({'table' => $param->{'table'}}));
    } else {
        return undef
            unless ($keysFound =
            $sdm->get_indexes({'table' => $param->{'table'}}));
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
                $log->syslog('info',
                    'Table %s: Missing expected key part %s in %s key',
                    $param->{'table'}, $field, $param->{'key_name'});
                $result->{'missing_key'}{$field} = 1;
                $result->{'existing_key_correct'} = 0;
            }
        }
        foreach my $field (keys %{$keysFound}) {
            unless ($expected_keys{$field}) {
                $log->syslog('info',
                    'Table %s: Found unexpected key part %s in %s key',
                    $param->{'table'}, $field, $param->{'key_name'});
                $result->{'unexpected_key'}{$field} = 1;
                $result->{'existing_key_correct'} = 0;
            }
        }
    }
    return $result;
}

# Moved: Use Sympa::Database::is_sufficient_field_type().
#sub _check_db_field_type;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseManager - Managing schema of Sympa core database

=head1 SYNOPSIS

  use Sympa::DatabaseManager;
  
  $sdm = Sympa::DatabaseManager->instance
      or die 'Cannot connect to database';
  $sth = $sdm->do_prepared_query('SELECT FROM ...', ...)
      or die 'Cannot execute query';
  Sympa::DatabaseManager->disconnect;

  Sympa::DatabaseManager::probe_db() or die 'Database is not up-to-date';

=head1 DESCRIPTION

L<Sympa::DatabaseManager> provides functions to manage schema of Sympa core
database.

=head2 Methods and functions

=over

=item instance ( )

I<Constructor>.
Gets singleton instance of Sympa::Database class managing Sympa core database.

=item disconnect ( )

I<Class method>.
Disconnects from core database.

=item probe_db ( )

I<Function>.
If possible, probes database structure and updates it.

=back

=head1 SEE ALSO

L<Sympa::Database>, L<Sympa::DatabaseDescription>, L<Sympa::DatabaseDriver>.

=head1 HISTORY

Sympa Database Manager (SDM) appeared on Sympa 6.2.

=cut
