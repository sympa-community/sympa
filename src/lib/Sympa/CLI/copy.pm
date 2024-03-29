# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
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

package Sympa::CLI::copy;

use strict;
use warnings;

use parent qw(Sympa::CLI::move);    # 'copy' is an alias of 'move'.

sub _run {
    $_[1]->{mode} = 'copy';
    goto &Sympa::CLI::move::_run;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-copy - Copy the list

=head1 DESCRIPTION

See L<"sympa move"|sympa-move(1)>.

=cut
