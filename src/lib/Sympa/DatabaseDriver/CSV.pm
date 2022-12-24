# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2022 The Sympa Community. See the
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

package Sympa::DatabaseDriver::CSV;

use strict;
use warnings;

use base qw(Sympa::DatabaseDriver);

use constant required_modules    => [qw(DBD::CSV)];
use constant required_parameters => [qw(db_name)];
use constant optional_parameters => [qw(db_options)];

sub build_connect_string {
    my $self = shift;

    return undef unless 0 == index $self->{db_name}, '/';

    my $connect_string = sprintf 'DBI:CSV:f_dir=%s', $self->{db_name};
    $connect_string .= sprintf ';%s', $self->{db_options}
        if defined $self->{db_options};
    return $connect_string;
}

1;

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::CSV - Database driver for CSV

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
