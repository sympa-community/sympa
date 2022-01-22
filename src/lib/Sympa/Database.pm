# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2021 The Sympa Community. See the
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

package Sympa::Database;

use strict;
use warnings;
use DBI;
use English qw(-no_match_vars);

use Sympa;
use Sympa::Log;

my $log = Sympa::Log->instance;

# Structure to keep track of active connections/connection status
# Keys: unique ID of connection (includes type, server, port, dbname and user).
# Values: database handler.
our %connection_of;
our %persistent_connection_of;

# Map to driver names from older format of db_type parameter.
my %driver_aliases = (
    mysql => 'Sympa::DatabaseDriver::MySQL',
    Pg    => 'Sympa::DatabaseDriver::PostgreSQL',
);

# Sympa::Database is the proxy class of Sympa::DatabaseDriver subclasses.
# The constructor may be overridden by _new() method.
sub new {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $class   = shift;
    my $db_type = shift;
    my %params  = @_;

    my $driver = $driver_aliases{$db_type} || $db_type;
    $driver = 'Sympa::DatabaseDriver::' . $driver
        unless $driver =~ /::/;
    unless (eval "require $driver"
        and $driver->isa('Sympa::DatabaseDriver')) {
        $log->syslog('err', 'Unable to use %s module: %s',
            $driver, $EVAL_ERROR || 'Not a Sympa::DatabaseDriver class');
        return undef;
    }

    return $driver->_new(
        $db_type,
        map {
                  (exists $params{$_} and defined $params{$_})
                ? ($_ => $params{$_})
                : ()
        } ( @{$driver->required_parameters}, @{$driver->optional_parameters}
        )
    );
}

sub _new {
    my $class   = shift;
    my $db_type = shift;
    my %params  = @_;

    return bless {%params} => $class;
}

############################################################
#  connect
############################################################
#  Connect to an SQL database.
#
# IN : $options : ref to a hash. Options for the connection process.
#         currently accepts 'keep_trying' : wait and retry until
#         db connection is ok (boolean) ; 'warn' : warn
#         listmaster if connection fails (boolean)
# OUT : 1 | undef
#
##############################################################
sub connect {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    # First check if we have an active connection with this server
    if ($self->ping) {
        $log->syslog('debug3', 'Connection to database %s already available',
            $self);
        return 1;
    }
    # Disconnected: Transaction (if any) was aborted.
    if (delete $self->{_sdbTransactionLevel}) {
        $log->syslog('err', 'Transaction on database %s was aborted: %s',
            $self, $DBI::errstr);
        $self->set_persistent($self->{_sdbPrevPersistency});
        return undef;
    }

    # Do we have required parameters?
    foreach my $param (@{$self->required_parameters}) {
        unless (defined $self->{$param}) {
            $log->syslog('info', 'Missing parameter %s for DBI connection',
                $param);
            return undef;
        }
    }

    # Check if required module such as DBD is installed.
    foreach my $module (@{$self->required_modules}) {
        unless (eval "require $module") {
            $log->syslog(
                'err',
                'A module for %s is not installed. You should download and install %s',
                ref($self),
                $module
            );
            Sympa::send_notify_to_listmaster('*', 'missing_dbd',
                {'db_type' => ref($self), 'db_module' => $module});
            return undef;
        }
    }
    foreach my $module (@{$self->optional_modules}) {
        eval "require $module";
    }

    # Set unique ID to determine connection.
    $self->{_id} = $self->get_id;

    # Establish new connection.

    # Set environment variables
    # Used by Oracle (ORACLE_HOME) etc.
    if ($self->{'db_env'}) {
        foreach my $env (split /;/, $self->{'db_env'}) {
            my ($key, $value) = split /=/, $env, 2;
            $ENV{$key} = $value if ($key);
        }
    }

    $connection_of{$self->{_id}} = eval { $self->_connect };

    unless ($self->ping) {
        unless ($persistent_connection_of{$self->{_id}}) {
            $log->syslog('err', 'Can\'t connect to Database %s: %s',
                $self, $DBI::errstr);
            $self->{_status} = 'failed';
            return undef;
        }

        # Notify listmaster unless the 'failed' status was set earlier.
        $log->syslog('err', 'Can\'t connect to Database %s, still trying...',
            $self);
        unless ($self->{_status} and $self->{_status} eq 'failed') {
            Sympa::send_notify_to_listmaster('*', 'no_db', {});
        }

        # Loop until connect works
        my $sleep_delay = 60;
        while (1) {
            sleep $sleep_delay;
            $connection_of{$self->{_id}} = eval { $self->_connect };
            last if $self->ping;
            $sleep_delay += 10;
        }

        delete $self->{_status};

        $log->syslog('notice', 'Connection to Database %s restored', $self);
        Sympa::send_notify_to_listmaster('*', 'db_restored', {});
    }

    $log->syslog('debug2', 'Connected to Database %s', $self);

    return 1;
}

# Merged into connect(().
#sub establish_connection();

sub _connect {
    my $self = shift;

    my $connection = DBI->connect(
        $self->build_connect_string, $self->{'db_user'},
        $self->{'db_passwd'}, {PrintError => 0}
    );
    # Force field names to be lowercased.
    # This has has been added after some problems of field names
    # upercased with Oracle.
    $connection->{FetchHashKeyName} = 'NAME_lc' if $connection;

    return $connection;
}

sub __dbh {
    my $self = shift;
    return $connection_of{$self->{_id} || ''};
}

sub do_operation {
    die 'Not implemented';
}

sub do_query {
    my $self   = shift;
    my $query  = shift;
    my @params = @_;

    my $sth;

    $query =~ s/^\s+//;
    $query =~ s/\s+$//;
    my $statement = sprintf $query, @params;

    my $s = $statement;
    $s =~ s/\n\s*/ /g;
    $log->syslog('debug3', 'Will perform query "%s"', $s);

    unless ($self->__dbh and $sth = $self->__dbh->prepare($statement)) {
        # Check connection to database in case it would be the cause of the
        # problem.
        unless ($self->connect()) {
            $log->syslog('err', 'Unable to get a handle to %s database',
                $self->{'db_name'});
            return undef;
        } else {
            unless ($self->__dbh and $sth = $self->__dbh->prepare($statement))
            {
                my $trace_statement = sprintf $query,
                    @{$self->prepare_query_log_values(@params)};
                $log->syslog('err', 'Unable to prepare SQL statement %s: %s',
                    $trace_statement, $self->error);
                return undef;
            }
        }
    }
    unless ($sth->execute) {
        # Check connection to database in case it would be the cause of the
        # problem.
        unless ($self->connect()) {
            $log->syslog('err', 'Unable to get a handle to %s database',
                $self->{'db_name'});
            return undef;
        } else {
            unless ($sth = $self->__dbh->prepare($statement)) {
                # Check connection to database in case it would be the cause
                # of the problem.
                unless ($self->connect()) {
                    $log->syslog('err',
                        'Unable to get a handle to %s database',
                        $self->{'db_name'});
                    return undef;
                } else {
                    unless ($sth = $self->__dbh->prepare($statement)) {
                        my $trace_statement = sprintf $query,
                            @{$self->prepare_query_log_values(@params)};
                        $log->syslog('err',
                            'Unable to prepare SQL statement %s: %s',
                            $trace_statement, $self->error);
                        return undef;
                    }
                }
            }
            unless ($sth->execute) {
                my $trace_statement = sprintf $query,
                    @{$self->prepare_query_log_values(@params)};
                $log->syslog('err',
                    'Unable to execute SQL statement "%s": %s',
                    $trace_statement, $self->error);
                return undef;
            }
        }
    }

    return $sth;
}

sub do_prepared_query {
    my $self   = shift;
    my $query  = shift;
    my @params = ();
    my %types  = ();

    my $sth;

    ## get binding types and parameters
    my $i = 0;
    while (scalar @_) {
        my $p = shift;
        if (ref $p eq 'HASH') {
            # a hashref { sql_type => SQL_type } etc.
            $types{$i} = $p;
            push @params, shift;
        } elsif (ref $p) {
            $log->syslog('err', 'Unexpected %s object.  Ask developer',
                ref $p);
            return undef;
        } else {
            push @params, $p;
        }
        $i++;
    }

    $query =~ s/^\s+//;
    $query =~ s/\s+$//;
    $query =~ s/\n\s*/ /g;
    $log->syslog('debug3', 'Will perform query "%s"', $query);

    if ($self->{'cached_prepared_statements'}{$query}) {
        $sth = $self->{'cached_prepared_statements'}{$query};
    } else {
        $log->syslog('debug3',
            'Did not find prepared statement for %s. Doing it', $query);
        unless ($self->__dbh and $sth = $self->__dbh->prepare($query)) {
            unless ($self->connect()) {
                $log->syslog('err', 'Unable to get a handle to %s database',
                    $self->{'db_name'});
                return undef;
            } else {
                unless ($self->__dbh and $sth = $self->__dbh->prepare($query))
                {
                    $log->syslog('err', 'Unable to prepare SQL statement: %s',
                        $self->error);
                    return undef;
                }
            }
        }

        ## bind parameters with special types
        ## this may be done only once when handle is prepared.
        foreach my $i (sort keys %types) {
            $sth->bind_param($i + 1, $params[$i], $types{$i});
        }

        $self->{'cached_prepared_statements'}{$query} = $sth;
    }
    unless ($sth->execute(@params)) {
        # Check database connection in case it would be the cause of the
        # problem.
        unless ($self->connect()) {
            $log->syslog('err', 'Unable to get a handle to %s database',
                $self->{'db_name'});
            return undef;
        } else {
            unless ($sth = $self->__dbh->prepare($query)) {
                unless ($self->connect()) {
                    $log->syslog('err',
                        'Unable to get a handle to %s database',
                        $self->{'db_name'});
                    return undef;
                } else {
                    unless ($sth = $self->__dbh->prepare($query)) {
                        $log->syslog('err',
                            'Unable to prepare SQL statement: %s',
                            $self->error);
                        return undef;
                    }
                }
            }

            ## bind parameters with special types
            ## this may be done only once when handle is prepared.
            foreach my $i (sort keys %types) {
                $sth->bind_param($i + 1, $params[$i], $types{$i});
            }

            $self->{'cached_prepared_statements'}{$query} = $sth;
            unless ($sth->execute(@params)) {
                $log->syslog('err',
                    'Unable to execute SQL statement "%s": %s',
                    $query, $self->error);
                return undef;
            }
        }
    }

    return $sth;
}

sub prepare_query_log_values {
    my $self = shift;
    my @result;
    foreach my $value (@_) {
        my $cropped = substr($value, 0, 100);
        if ($cropped ne $value) {
            $cropped .= "...[shortened]";
        }
        push @result, $cropped;
    }
    return \@result;
}

# DEPRECATED: Use tools::eval_in_time() and fetchall_arrayref().
#sub fetch();

# As most of DBMS do not support nested transactions, these are not
# effective during when {_sdbTransactionLevel} attribute is
# positive, i.e. only the outermost transaction will be available.
sub begin {
    my $self = shift;

    $self->{_sdbTransactionLevel} //= 0;
    if ($self->{_sdbTransactionLevel}++) {
        return 1;
    }

    my $dbh = $self->__dbh;
    return undef unless $dbh;

    $dbh->begin_work or die $DBI::errstr;
    $self->{_sdbPrevPersistency} = $self->set_persistent(0);
    return 1;
}

sub commit {
    my $self = shift;

    unless ($self->{_sdbTransactionLevel}) {
        die 'bug in logic. Ask developer';
    }
    if (--$self->{_sdbTransactionLevel}) {
        return 1;
    }

    my $dbh = $self->__dbh;
    return undef unless $dbh;

    $self->set_persistent($self->{_sdbPrevPersistency});
    return $dbh->commit;
}

sub rollback {
    my $self = shift;

    unless ($self->{_sdbTransactionLevel}) {
        die 'bug in logic. Ask developer';
    }
    if (--$self->{_sdbTransactionLevel}) {
        return 1;
    }

    my $dbh = $self->__dbh;
    return undef unless $dbh;

    $self->set_persistent($self->{_sdbPrevPersistency});
    return $dbh->rollback;
}

sub disconnect {
    my $self = shift;

    my $id = $self->get_id;

    # Don't disconnect persistent connection.
    return 0 if $persistent_connection_of{$id};

    $connection_of{$id}->disconnect if $connection_of{$id};
    delete $connection_of{$id};
    return 1;
}

# NOT YET USED.
#sub create_db;

sub error {
    my $self = shift;

    my $dbh = $self->__dbh;
    return sprintf '(%s) %s', $dbh->state, ($dbh->errstr || '') if $dbh;
    return undef;
}

# Old name: Sympa::DatabaseManager::_check_db_field_type().
sub is_sufficient_field_type {
    my $self      = shift;
    my $required  = shift;
    my $effective = shift;

    my ($required_type, $required_size, $effective_type, $effective_size);

    if ($required =~ /^(\w+)(\((\d+)\))?$/) {
        ($required_type, $required_size) = ($1, $3);
    }

    if ($effective =~ /^(\w+)(\((\d+)\))?$/) {
        ($effective_type, $effective_size) = ($1, $3);
    }

    if (    ($effective_type // '') eq ($required_type // '')
        and (not defined $required_size or $effective_size >= $required_size))
    {
        return 1;
    }

    return 0;
}

sub set_persistent {
    my $self = shift;
    my $flag = shift;

    my $ret = $persistent_connection_of{$self->get_id};
    if ($flag) {
        $persistent_connection_of{$self->get_id} = 1;
    } elsif (defined $flag) {
        delete $persistent_connection_of{$self->get_id};
    }
    # Returns the previous value of the flag (6.2.65b.1 or later)
    return $ret;
}

sub ping {
    my $self = shift;

    my $dbh = $self->__dbh;

    # Disconnected explicitly.
    return undef unless $dbh;
    # Some drivers don't have ping().
    return 1 unless $dbh->can('ping');
    return $dbh->ping;
}

sub quote {
    my $self = shift;
    my ($string, $datatype) = @_;

    # quote() does not need actual connection but driver handle.
    unless ($self->__dbh or $self->connect) {
        return undef;
    }
    return $self->__dbh->quote($string, $datatype);
}

# No longer used.
#sub set_fetch_timeout($timeout);

## Returns a character string corresponding to the expression to use in
## a read query (e.g. SELECT) for the field given as argument.
## This sub takes a single argument: the name of the field to be used in
## the query.
##
# Moved to Sympa::Upgrade::_get_canonical_write_date().
#sub get_canonical_write_date;

## Returns a character string corresponding to the expression to use in
## a write query (e.g. UPDATE or INSERT) for the value given as argument.
## This sub takes a single argument: the value of the date to be used in
## the query.
##
# Moved to Sympa::Upgrade::_get_canonical_read_date().
#sub get_canonical_read_date;

# We require that user also matches (except SQLite).
sub get_id {
    my $self = shift;

    return join ';', map {"$_=$self->{$_}"}
        grep {
               !ref($self->{$_})
            and defined $self->{$_}
            and !/\A_/
            and !/passw(or)?d/
        }
        sort keys %$self;
}

sub DESTROY {
    shift->disconnect;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Database - Handling databases

=head1 SYNOPSIS

  use Sympa::Database;

  $database = Sympa::Database->new('SQLite', db_name => '...');
      or die 'Cannot connect to database';
  $sth = $database->do_prepared_query('SELECT FROM ...', ...)
      or die 'Cannot execute query';
  $database->disconnect;

=head1 DESCRIPTION

TBD.

=head2 Methods

=over

=item new ( $db_type, [ option => value, ... ] )

I<Constructor>.
Creates new database instance.

=item begin ( )

I<Instance method>, I<only for SQL>.
Begin transaction.

=item commit ( )

I<Instance method>, I<only for SQL>.
Commit transaction.

=item do_operation ( $operation, options... )

I<Instance method>, I<only for LDAP>.
Performs LDAP search operation.
About options see L<Net::LDAP/search>.

Returns:

Operation handle (L<LDAP::Search> object or such), or C<undef>.

=item do_prepared_query ( $statement, parameters... )

I<Instance method>, I<only for SQL>.
Prepares and executes SQL query.
$statement is an SQL statement that may contain placeholders C<?>.

Returns:

Statement handle (L<DBI::st> object or such), or C<undef>.

=item do_query ( $statement, parameters... )

I<Instance method>, I<only for SQL>.
Executes SQL query.
$statement and parameters will be fed to sprintf().

Returns:

Statement handle (L<DBI::st> object or such), or C<undef>.

=item rollback ( )

I<Instance method>, I<only for SQL>.
Rollback transaction.

=back

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=head1 HISTORY

Sympa Database Manager (SDM) appeared on Sympa 6.2.

=cut
