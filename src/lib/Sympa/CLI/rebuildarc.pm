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

package Sympa::CLI::rebuildarc;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Message;
use Sympa::Spool::Archive;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw();

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list    = shift;

    my $arc_message = Sympa::Message->new(
        sprintf("\nrebuildarc %s *\n\n", $list->{'name'}),
        context => $list->{'domain'},
        sender  => Sympa::get_address($list, 'listmaster'),
        date    => time
    );
    my $marshalled = Sympa::Spool::Archive->new->store($arc_message);
    unless ($marshalled) {
        printf STDERR "Cannot store command to rebuild archive of list %s.\n",
            $list->get_id;
        exit 1;
    }
    printf "Archive rebuild scheduled for %s.\n", $list->get_id;
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-rebuildarc - Rebuild the archives of the list

=head1 SYNOPSIS

C<sympa.pl rebuildarc> I<list>[C<@>I<domain>]

=head1 DESCRIPTION

Rebuild the archives of the list.

=cut
