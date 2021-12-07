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

package Sympa::CLI::sync_list_db;

use strict;
use warnings;

use Sympa::List;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw(list?);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list    = shift;

    if (ref $list eq 'Sympa::List') {
        $list->_update_list_db;
    } else {
        Sympa::List::_flush_list_db();
        my $all_lists = Sympa::List::get_lists('*', 'reload_config' => 1);
        foreach my $list (@$all_lists) {
            $list->_update_list_db;
        }
    }
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-sync_list_db - Synchronize database cache of the lists

=head1 SYNOPSIS

C<sympa sync_list_db> [ I<list>C<@>I<domain> ]

=head1 DESCRIPTION

Syncs filesystem list configs to the database cache of list configs,
optionally syncs an individual list if specified.

=cut
