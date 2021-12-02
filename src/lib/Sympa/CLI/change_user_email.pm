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

use constant _options => qw();
use constant _args    => qw(email email);

sub _run {
    my $class         = shift;
    my $options       = shift;
    my $current_email = shift;
    my $new_email     = shift;

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => [Sympa::List::get_robots()],
        action           => 'move_user',
        current_email    => $current_email,
        email            => $new_email,
        sender           => Sympa::get_address('*', 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Failed to change user email address %s to %s\n",
            $current_email, $new_email;
        exit 1;
    }
    exit 0;

}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-change_user_email - Change a user email address

=head1 SYNOPSIS

C<sympa.pl change_user_email> I<current_email> I<new_email>

=head1 DESCRIPTION

Changes a user email address in all Sympa  databases (subscriber_table,
list config, etc) for all virtual robots.

=cut
