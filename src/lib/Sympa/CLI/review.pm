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

package Sympa::CLI::review;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::List;

use parent qw(Sympa::CLI);

use constant _options => qw(status);
use constant _args    => qw(list);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list    = shift;

    if ($list) {
        my @members = $list->get_members(
            'unconcealed_member',
            order => 'email'
        );
        my @bounced   = ();
        my @suspended = ();

        printf "%i member(s) in list %s.\n",
            scalar(@members), $list->get_id;
        for my $member (@members) {
            printf "%s\n", $member->{email};
            push @bounced,   $member->{'email'}
                if defined $member->{'bounce'};
            push @suspended, $member->{'email'}
                if defined $member->{'suspend'};
        }

        if ($options->{'status'}) {
            print "------------------\n";

            printf "%i bounced member(s) in list %s.\n",
                scalar(@bounced), $list->get_id;
            for my $member (@bounced) {
                printf "%s\n", $member;
            }

            printf "%i suspended member(s) in list %s.\n",
                scalar(@suspended), $list->get_id;
            for my $member (@suspended) {
                printf "%s\n", $member;
            }
        }

        exit 0;
    } else {
        printf STDERR "Error : please provide the name of a list\n";
        exit 1;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-review - Show subscribers of the list.

=head1 SYNOPSIS

C<sympa review> S<[ C<--status> ]> I<list>[ C<@>I<domain> ]

=head1 DESCRIPTION

Show subscribers of the list.

=head1 HISTORY

This option was added on Sympa 6.2.69b.

=cut
