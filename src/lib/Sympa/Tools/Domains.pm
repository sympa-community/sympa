# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Tools::Domains;

use strict;
use warnings;
use Conf;
use Sympa::Tools::Text;

sub is_blacklisted {
    my $email = shift;

    if (defined($Conf::Conf{'domains_blacklist'})) {
        my @parts = split '@', Sympa::Tools::Text::canonic_email($email);
        foreach my $f (split ',', lc($Conf::Conf{'domains_blacklist'})) {
            if ($parts[1] && $parts[1] eq $f) {
                return 1;
            }
        }
    }

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Tools::Domains - Domains-related functions

=head1 DESCRIPTION

This package provides some email's domains-related functions.

=head2 Functions

=over

=item is_blacklisted ( $email )

Says if the domain of the given email is blacklisted (C<domains_blacklist>
setting).

Returns 1 if it's blacklisted, 0 otherwise

=back

=cut
