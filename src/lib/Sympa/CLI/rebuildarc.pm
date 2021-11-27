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

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    $options->{rebuildarc} = shift @argv;

#} elsif ($options->{rebuildarc}) {
    my ($listname, $robot_id) = split /\@/, $options->{rebuildarc}, 2;
    my $current_list = Sympa::List->new($listname, $robot_id);
    unless ($current_list) {
        printf STDERR "Incorrect list name %s.\n", $options->{rebuildarc};
        exit 1;
    }

    my $arc_message = Sympa::Message->new(
        sprintf("\nrebuildarc %s *\n\n", $listname),
        context => $robot_id,
        sender  => Sympa::get_address($robot_id, 'listmaster'),
        date    => time
    );
    my $marshalled = Sympa::Spool::Archive->new->store($arc_message);
    unless ($marshalled) {
        printf STDERR "Cannot store command to rebuild archive of list %s.\n",
            $options->{rebuildarc};
        exit 1;
    }
    printf "Archive rebuild scheduled for %s.\n", $options->{rebuildarc};
    exit 0;
}
1;
