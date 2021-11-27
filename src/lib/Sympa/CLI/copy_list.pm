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

package Sympa::CLI::copy_list;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(new_listname=s new_listrobot=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    $options->{copy_list} = shift @argv;

#} elsif ($options->{copy_list}) {
    my $current_list = Sympa::List->new(split(/\@/, $options->{copy_list}, 2),
        {just_try => 1});
    unless ($current_list) {
        printf STDERR "Incorrect list name %s\n", $options->{copy_list};
        exit 1;
    }

    my $listname = $options->{new_listname};
    unless (defined $listname and length $listname) {
        print STDERR "Missing parameter new_listname\n";
        exit 1;
    }

    my $robot_id = $options->{new_listrobot};
    unless (defined $robot_id) {
        $robot_id = $current_list->{'domain'};
    } else {
        unless (length $robot_id and Conf::valid_robot($robot_id)) {
            printf STDERR "Unknown robot \"%s\"\n", $robot_id;
            exit 1;
        }
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $robot_id,
        action           => 'move_list',
        current_list     => $current_list,
        listname         => $listname,
        mode             => 'copy',
        sender           => Sympa::get_address($robot_id, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Could not copy list %s to %s\@%s\n",
            $current_list->get_id, $listname, $robot_id;
        exit 1;
    }
    exit 0;

}
1;
