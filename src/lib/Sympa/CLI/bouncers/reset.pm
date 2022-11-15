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

package Sympa::CLI::bouncers::reset;

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

    my ($errors, $users) = (0, 0);
    for (
        my $i = $list->get_first_bouncing_list_member();
        $i;
        $i = $list->get_next_bouncing_list_member()
    ) {
        if ($list->update_list_member(
                $i->{email},
                bounce       => undef,
                update_date  => time,
                bounce_score => 0
            )
        ) {
            $users++;
        } else {
            printf STDERR "Unable to cancel bounce error for %s.\n", $i->{email};
        }
        $errors++;
    }

    if ($errors) {
        my $text =
            ($users > 1)
            ? "Canceled %i bounce errors on %i.\n"
            : "Canceled %i bounce error on %i.\n";
        printf $text, $users, $errors;
    } else {
        print "No bounce errors to cancel.\n";
    }

    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-bouncers-reset - Reset the bounce status of all bounced users of a list

=head1 SYNOPSIS

C<sympa bouncers reset> I<list>[ C<@>I<domain> ]

=head1 DESCRIPTION

Reset the bounce status of all bounced users of a list

=head1 HISTORY

This option was added on Sympa 6.2.69b.

=cut
