# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package SDM;

use strict;
use warnings;

use Conf;
use Sympa::Database;
use Log;

our $db_source;

sub do_query {
    my $query  = shift;
    my @params = @_;
    my $sth;

    if (check_db_connect()) {
        unless ($sth = $db_source->do_query($query, @params)) {
            Log::do_log('err',
                'SQL query failed to execute in the Sympa database');
            return undef;
        }
    } else {
        Log::do_log('err', 'Unable to get a handle to Sympa database');
        return undef;
    }

    return $sth;
}

sub do_prepared_query {
    my $query  = shift;
    my @params = @_;
    my $sth;

    if (check_db_connect()) {
        unless ($sth = $db_source->do_prepared_query($query, @params)) {
            Log::do_log('err',
                'SQL query failed to execute in the Sympa database');
            return undef;
        }
    } else {
        Log::do_log('err', 'Unable to get a handle to Sympa database');
        return undef;
    }

    return $sth;
}

## Get database handler
## Note: if database connection is not available, this function returns
## immediately.
##
## NO LONGER USED.  Should not access to database handler.
#sub db_get_handler();

## Just check if DB connection is ok
## Possible option is 'just_try', won't try to reconnect if database
## connection is not available.
sub check_db_connect {
    my @options = @_;

    ## Is the Database defined
    unless (Conf::get_robot_conf('*', 'db_name')) {
        Log::do_log('err', 'No db_name defined in configuration file');
        return undef;
    }

    unless ($db_source and $db_source->ping) {
        unless (connect_sympa_database(@options)) {
            Log::do_log('err', 'Failed to connect to database');
            return undef;
        }
    }

    return 1;
}

## Connect to Database
sub connect_sympa_database {
    Log::do_log('debug2', '(%s)', @_);
    my $option = shift || '';

    ## We keep trying to connect if 'just_try' option was not set.
    ## Unless in a web context, because we can't afford long response time on
    ## the web interface
    my $db_conf = Conf::get_parameters_group('*', 'Database related');
    $db_conf->{'reconnect_options'} = {
        'keep_trying' =>
            ($option ne 'just_try' && !$ENV{'GATEWAY_INTERFACE'}),
        'warn' => 1,
    };
    unless ($db_source =
        Sympa::Database->new($db_conf->{'db_type'}, %$db_conf)) {
        Log::do_log('err', 'Unable to create Sympa::Database object');
        return undef;
    }

    # Just in case, we connect to the database here. Probably not necessary.
    unless ($db_source->connect()) {
        Log::do_log('err', 'Unable to connect to the Sympa database');
        return undef;
    }
    Log::do_log(
        'debug2',
        'Connected to Database %s',
        Conf::get_robot_conf('*', 'db_name')
    );

    return 1;
}

## Disconnect from Database.
## Destroy db handle so that any pending statement handles will be finalized.
sub db_disconnect {
    Log::do_log('debug2', '');

    $db_source->disconnect if $db_source;
    return 1;
}

# Moved to Sympa::DatabaseManager::probe_db().
#sub probe_db();

# Moved to Conf::data_structure_uptodate().
#sub data_structure_uptodate();

sub quote {
    my $param = shift;
    if ($db_source and $db_source->__dbh) {
        return $db_source->quote($param);
    } else {
        if (check_db_connect()) {
            return $db_source->quote($param);
        } else {
            Log::do_log('err', 'Unable to get a handle to Sympa database');
            return undef;
        }
    }
}

sub get_substring_clause {
    my $param = shift;
    if ($db_source) {
        return $db_source->get_substring_clause($param);
    } else {
        if (check_db_connect()) {
            return $db_source->get_substring_clause($param);
        } else {
            Log::do_log('err', 'Unable to get a handle to Sympa database');
            return undef;
        }
    }
}

# DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

## Returns a character string corresponding to the expression to use in
## a read query (e.g. SELECT) for the field given as argument.
## This sub takes a single argument: the name of the field to be used in
## the query.
##
sub get_canonical_write_date {
    my $param = shift;
    if ($db_source) {
        return $db_source->get_canonical_write_date($param);
    } else {
        if (check_db_connect()) {
            return $db_source->get_canonical_write_date($param);
        } else {
            Log::do_log('err', 'Unable to get a handle to Sympa database');
            return undef;
        }
    }
}

## Returns a character string corresponding to the expression to use in
## a write query (e.g. UPDATE or INSERT) for the value given as argument.
## This sub takes a single argument: the value of the date to be used in
## the query.
##
sub get_canonical_read_date {
    my $param = shift;
    if ($db_source) {
        return $db_source->get_canonical_read_date($param);
    } else {
        if (check_db_connect()) {
            return $db_source->get_canonical_read_date($param);
        } else {
            Log::do_log('err', 'Unable to get a handle to Sympa database');
            return undef;
        }
    }
}

## bound parameters for do_prepared_query().
## returns an array ( { sql_type => SQL_type }, value ),
## single scalar or empty array.
##
sub AS_DOUBLE {
    return $db_source->AS_DOUBLE(@_);
}

sub AS_BLOB {
    return $db_source->AS_BLOB(@_);
}

1;
