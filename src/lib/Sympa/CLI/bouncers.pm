# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
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

package Sympa::CLI::bouncers;

use strict;
use warnings;

use parent qw(Sympa::CLI);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    Sympa::CLI->run(qw(help bouncers));
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-bouncers - Manipulate list bounced users

=head1 SYNOPSIS

C<sympa bouncers> I<sub-command> ...

=head1 DESCRIPTION

TBD.

=head1 SUB-COMMANDS

Currently following sub-commands are available.
To see detail of each sub-command, run 'C<sympal.pl help bouncers> I<sub-command>'.

=over

=item L<"sympa bouncers del ..."|sympa-bouncers-del(1)>

Unsubscribe bounced users from a list

=item L<"sympa bouncers reset ..."|sympa-bouncers-reset(1)>

Reset the bounce status of all bounced users of a list

=back

=head1 HISTORY

This option was added on Sympa 6.2.69b.

=cut
