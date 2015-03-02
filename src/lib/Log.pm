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

package Log;

use strict;
use warnings;

use Sympa::Log;

# Deprecated: No longer used.
#sub fatal_err;

# OBSOLETED.  Use Sympa::Log::syslog().
sub do_log {
    unshift @_, Sympa::Log->instance;
    goto &Sympa::Log::syslog;
}

# OBSOLETED.  Use Sympa::Log::instance() or Sympa::Log::openlog().
sub do_openlog {
    return Sympa::Log->instance->openlog(@_);
}

# OBSOLETED.  Use Sympa::Log::get_log_date().
sub get_log_date {
    return Sympa::Log->instance->get_log_date;
}

# OBSOLETED.  Use Sympa::Log::db_log().
sub db_log {
    my $arg = shift || {};
    @_ = (Sympa::Log->instance, %$arg);
    goto &Sympa::Log::db_log;
}

#OBSOLETED.  Use Sympa::Log::add_stat().
sub db_stat_log {
    my $arg = shift || {};
    return Sympa::Log->instance->add_stat(%$arg);
}

# delete logs in RDBMS
# MOVED to _db_log_del() in task_manager.pl.
#sub db_log_del;

# OBSOLETED.  Use Sympa::Log::get_first_db_log().
sub get_first_db_log {
    return Sympa::Log->instance->get_first_db_log(@_);
}

# No longer used.
#sub return_rows_nb;

#OBSOLETED.  Use Sympa::Log::get_next_db_log().
sub get_next_db_log {
    return Sympa::Log->instance->get_next_db_log(@_);
}

# OBSOLETED.  Use {level} property of Sympa::Log instance.
sub set_log_level {
    Sympa::Log->instance->{level} = shift;
}

#OBSOLETED: No longer used.
#sub get_log_level;

# OBSOLETED.  Use Sympa::Log::aggregate_data().
sub aggregate_data {
    return Sympa::Log->instance->aggregate_data(@_);
}

# Never used.
#sub get_last_date_aggregation;

# OBSOLETED.  Use Sympa::Log::aggregate_daily_data().
sub aggregate_daily_data {
    return Sympa::Log->instance->aggregate_daily_data(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Log

=head1 NOTICE

This module was OBSOLETED.
Use L<Sympa::Log> instead.

=cut
