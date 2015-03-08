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

use Sympa::DatabaseManager;

# OBSOLETED. Use $sdm->do_query directly.
sub do_query {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->do_query(@_);
    } else {
        return undef;
    }
}

# OBSOLETED. Use $sdm->do_prepared_query directly.
sub do_prepared_query {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->do_prepared_query(@_);
    } else {
        return undef;
    }
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
# OBSOLETED. Use Sympa::DatabaseManager->instance().
sub check_db_connect {
    return Sympa::DatabaseManager->instance ? 1 : undef;
}

## Disconnect from Database.
## Destroy db handle so that any pending statement handles will be finalized.
# OBSOLETED. Use Sympa::DatabaseManager->disconnect().
sub db_disconnect {
    Sympa::DatabaseManager->disconnect;
    return 1;
}

# Moved to Sympa::DatabaseManager::probe_db().
#sub probe_db();

# Moved to Conf::data_structure_uptodate().
#sub data_structure_uptodate();

# OBSOLETED. Use $sdm->quote directly.
sub quote {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->quote(@_);
    } else {
        return undef;
    }
}

# OBSOLETED. Use $sdm->get_substring_clause directly.
sub get_substring_clause {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->get_substring_clause(@_);
    } else {
        return undef;
    }
}

# DEPRECATED.
#sub get_limit_clause ( { rows_count => $rows, offset => $offset } );

## Returns a character string corresponding to the expression to use in
## a read query (e.g. SELECT) for the field given as argument.
## This sub takes a single argument: the name of the field to be used in
## the query.
##
# OBSOLETED. Use $sdm->get_canonical_write_date directly.
sub get_canonical_write_date {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->get_canonical_write_date(@_);
    } else {
        return undef;
    }
}

## Returns a character string corresponding to the expression to use in
## a write query (e.g. UPDATE or INSERT) for the value given as argument.
## This sub takes a single argument: the value of the date to be used in
## the query.
##
# OBSOLETED. Use $sdm->get_canonical_read_date directly.
sub get_canonical_read_date {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->get_canonical_read_date(@_);
    } else {
        return undef;
    }
}

## bound parameters for do_prepared_query().
## returns an array ( { sql_type => SQL_type }, value ),
## single scalar or empty array.
##
# OBSOLETED. Use $sdm->AS_DOUBLE directly.
sub AS_DOUBLE {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->AS_DOUBLE(@_);
    } else {
        return undef;
    }
}

# OBSOLETED. Use $sdm->AS_BLOB directly.
sub AS_BLOB {
    if (my $sdm = Sympa::DatabaseManager->instance) {
        return $sdm->AS_BLOB(@_);
    } else {
        return undef;
    }
}

1;

=encoding utf-8

=head1 NAME

SDM

=head1 NOTICE

This module was OBSOLETED.
Use L<Sympa::DatabaseManager> instead.

=cut

