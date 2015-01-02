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

package Sympa::DatabaseDriver::ODBC;

use strict;
use warnings;

use Log;

use base qw(Sympa::DatabaseDriver);

sub build_connect_string {
    my $self = shift;
    Log::do_log('debug', 'Building connection string to database %s',
        $self->{'db_name'});
    $self->{'connect_string'} = "DBI:$self->{'db_type'}:$self->{'db_name'}";
}

sub get_substring_clause {
    my $self  = shift;
    my $param = shift;

    die 'not yet implemented: This is required by Sympa';
}

sub get_formatted_date {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented: This is required by Sympa';
}

sub is_autoinc {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub set_autoinc {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub get_tables {
    my $self = shift;

    die 'Not yet implemented';
}

sub add_table {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemeneted';
}

sub get_fields {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub update_field {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub add_field {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub delete_field {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub get_primary_key {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub unset_primary_key {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub set_primary_key {
    my $self  = shift;
    my $param = shift;

    die 'Not yet impelemented';
}

sub get_indexes {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub unset_index {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub set_index {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented';
}

sub AS_DOUBLE {
    return ({'TYPE' => DBI::SQL_DOUBLE()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::ODBC - Database driver for ODBC

=head1 DESCRIPTION

I<This module is under development>.

=head1 SEE ALSO

L<Sympa::DatabaseDriver>, L<SDM>.

=cut
