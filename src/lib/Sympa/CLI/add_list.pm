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

package Sympa::CLI::add_list;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Family;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(input_file=s robot=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    $options->{add_list} = shift;

#} elsif ($options->{add_list}) {
    my $robot = $options->{robot} || $Conf::Conf{'domain'};

    my $family_name;
    unless ($family_name = $options->{add_list}) {
        print STDERR "Error : missing family parameter\n";
        exit 1;
    }

    my $family;
    unless ($family = Sympa::Family->new($family_name, $robot)) {
        printf STDERR
            "The family %s does not exist, impossible to add a list\n",
            $family_name;
        exit 1;
    }

    unless ($options->{input_file}) {
        print STDERR "Error : missing 'input_file' parameter\n";
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $family,
        action           => 'create_automatic_list',
        parameters       => {file => $options->{input_file}},
        sender           => Sympa::get_address($family, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Impossible to add a list to the family %s\n",
            $family_name;
        exit 1;
    }

    exit 0;

}

1;

