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

package Sympa::CLI::sync_include;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(role=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    $options->{sync_include} = shift @argv;

#} elsif ($options->{sync_include}) {
    my $list = Sympa::List->new($options->{sync_include});
    my $role = $options->{role} || 'member';    # Compat. <= 6.2.54

    unless (defined $list) {
        printf STDERR "Incorrect list name %s\n", $options->{sync_include};
        exit 1;
    }
    unless (grep { $role eq $_ } qw(member owner editor)) {
        printf STDERR "Unknown role %s\n", $role;
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'include',
        role             => $role,
        sender           => Sympa::get_address($list, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Could not sync role %s of list %s with data sources\n",
            $role, $list->get_id;
        exit 1;
    }
    exit 0;
## Migration from one version to another
}
1;
