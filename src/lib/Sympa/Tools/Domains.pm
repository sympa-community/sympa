# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019, 2021 The Sympa Community. See the
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

package Sympa::Tools::Domains;

use strict;
use warnings;
use Conf;
use Sympa::Tools::Text;

sub is_blocklisted {
    my $email = shift;

    if (defined($Conf::Conf{'domains_blocklist'})) {
        my @parts = split '@', Sympa::Tools::Text::canonic_email($email);
        foreach my $f (split ',', lc($Conf::Conf{'domains_blocklist'})) {
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

=item is_blocklisted ( $email )

Says if the domain of the given email is blocklisted (C<domains_blocklist>
setting).

Returns 1 if it's blocklisted, 0 otherwise

=back

=cut
