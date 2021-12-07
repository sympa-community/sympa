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

package Sympa::CLI::export_list;

use strict;
use warnings;

use Sympa::List;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw(domain|site);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $that    = shift;

    my $all_lists = Sympa::List::get_lists($that);
    exit 1 unless defined $all_lists;
    foreach my $list (@$all_lists) {
        printf "%s\n", $list->{'name'};
    }
    exit 0;
}

1;
__END__

=encoding utf-8

#=head1 NAME
#
#sympa-export_list - TBD

=head1 SYNOPSIS

C<sympa export_list> I<domain>|C<"*">

=head1 DESCRIPTION

B<Not fully implemented>.

=cut
