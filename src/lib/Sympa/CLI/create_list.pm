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

package Sympa::CLI::create_list;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(input_file=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    my $robot = shift @argv || $Conf::Conf{'domain'};

#} elsif ($options->{create_list}) {

    unless ($options->{input_file}) {
        print STDERR "Error : missing 'input_file' parameter\n";
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $robot,
        action           => 'create_list',
        parameters       => {file => $options->{input_file}},
        sender           => Sympa::get_address($robot, 'listmaster'),
        scenario_context => {skip => 1}
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        print STDERR "Could not create list\n";
        exit 1;
    }
    exit 0;

}
1;
