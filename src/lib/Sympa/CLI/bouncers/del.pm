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

package Sympa::CLI::bouncers::del;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI::bouncers);

use constant _options   => qw();
use constant _args      => qw(list);
use constant _need_priv => 1;

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list    = shift;

    my @bounced;
    for (
        my $i = $list->get_first_bouncing_list_member();
        $i;
        $i = $list->get_next_bouncing_list_member()
    ) {
        push @bounced, $i->{email};
    }

    unless (scalar @bounced) {
        printf STDERR "No bounced users in list %s.\n", $list->get_id;
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'del',
        role             => 'member',
        email            => [@bounced],
        sender           => Sympa::get_address($list, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Failed to delete email addresses from %s.\n",
            $list->get_id;
        exit 1;
    }

    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-bouncers-del - Unsubscribe bounced users from a list

=head1 SYNOPSIS

C<sympa bouncers del> I<list>[ C<@>I<domain> ]

=head1 DESCRIPTION

Unsubscribe bounced users from a list.

=cut
