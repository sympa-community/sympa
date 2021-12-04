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

package Sympa::CLI::close;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(mode=s);
use constant _args    => qw(list|family);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $that    = shift;

    my $lists;
    my $mode;
    if (ref $that eq 'Sympa::List') {
        $lists = [$that];
        unless (grep { ($options->{mode} // 'close') eq $_ }
            qw(close install purge)) {
            printf STDERR "Unknown mode %s\n", $options->{mode};
            exit 1;
        }
        $mode = $options->{mode};
    } else {
        $lists = Sympa::List::get_lists($that);
        unless ($lists and @{$lists // []}) {
            printf STDERR "No lists in family %s\n", $that->get_id;
            exit 1;
        }
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $that->{'domain'},
        action           => 'close_list',
        current_list     => $lists,
        mode             => $mode,
        sender           => Sympa::get_address($that, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Could not close list of %s\n", $that->get_id;
        exit 1;
    }
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-close - Close list(s)

=head1 SYNOPSIS

C<sympa.pl close> [ C<--mode=purge> ] I<list>[C<@>I<domain>]

C<sympa.pl close> I<family>C<@@>I<domain>

=head1 DESCRIPTION

Close list(s).

If a list is specified, close it.
And if C<--mode=purge> is specified, remove the list entirely.

If a family is specified, tries to close all the lists belonging to it.

=cut
