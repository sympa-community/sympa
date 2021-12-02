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

package Sympa::CLI::purge_list;

use strict;
use warnings;

use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw(list);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list    = shift;

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list->{'domain'},
        action           => 'close_list',
        current_list     => $list,
        mode             => 'purge',
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Could not purge list %s\n", $list->get_id;
        exit 1;
    }
    exit 0;

}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-purge_list - Remove the list

=head1 SYNOPSIS

C<sympa.pl purge_list>

=head1 DESCRIPTION

Remove the list:
Remove archive, configuration files, users and owners in admin table.
Restore is not possible after this operation.

=cut
