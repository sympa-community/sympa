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

package Sympa::CLI::user::del;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI::user);

my $log = Sympa::Log->instance;

use constant _options   => qw();
use constant _args      => qw(email);
use constant _need_priv => 1;

sub _run {
    my $class         = shift;
    my $options       = shift;
    my $email         = shift;

    my @robots = Sympa::List::get_robots();

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => \@robots,
        action           => 'del_user',
        email            => $email,
        last_robot       => $robots[-1],
        sender           => Sympa::get_address('*', 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Failed to delete user email address %s\n",
            $email;

        exit 1;
    }
    exit 0;

}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-user-del - Delete user

=head1 SYNOPSIS

C<sympa user del> I<email>

=head1 DESCRIPTION

Deletes a user email address in all Sympa databases (subscriber_table,
list config, etc) for all virtual robots.

=cut
