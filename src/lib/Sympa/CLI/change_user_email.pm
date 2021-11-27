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

package Sympa::CLI::change_user_email;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(current_email=s new_email=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

#} elsif ($options->{change_user_email}) {
    unless ($options->{current_email} and $options->{new_email}) {
        print STDERR "Missing current_email or new_email parameter\n";
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => [Sympa::List::get_robots()],
        action           => 'move_user',
        current_email    => $options->{current_email},
        email            => $options->{new_email},
        sender           => Sympa::get_address('*', 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Failed to change user email address %s to %s\n",
            $options->{current_email}, $options->{new_email};
        exit 1;
    }
    exit 0;

}
1;
