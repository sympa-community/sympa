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

package Sympa::CLI::show_pending_lists;

use strict;
use warnings;

use Sympa::List;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw(domain);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $domain  = shift;

    my $all_lists =
        Sympa::List::get_lists($domain, 'filter' => ['status' => 'pending']);

    if (@{$all_lists}) {
        print "Pending lists:\n";
        foreach my $list (@$all_lists) {
            printf "%s\n  subject: %s\n  creator: %s\n  date: %s\n",
                $list->get_id,
                $list->{'admin'}{'subject'},
                $list->{'admin'}{'creation'}{'email'},
                $list->{'admin'}{'creation'}{'date_epoch'};
        }
    } else {
        printf "No pending list for robot %s\n", $domain;
    }
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-show_pending_lists - Show pending lists

=head1 SYNOPSIS

C<sympa show_pending_lists> I<domain>

=head1 DESCRIPTION

Print all pending lists for the robot, with informations.

=cut
