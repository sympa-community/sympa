# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021, 2022 The Sympa Community. See the
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

package Sympa::CLI::restore;

use strict;
use warnings;

use Sympa::List;
use Sympa::Log;

use parent qw(Sympa::CLI);

my $log = Sympa::Log->instance;

use constant _options => qw(roles=s);
use constant _args    => qw(list|domain|site);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $that    = shift;

    my $all_lists;
    if (ref $that eq 'Sympa::List') {
        $all_lists = [$that];
    } else {
        $all_lists = Sympa::List::get_lists($that);
    }

    my @roles = qw(member);
    if ($options->{roles}) {
        my %roles = map { ($_ => 1) }
            ($options->{roles} =~ /\b(member|owner|editor)\b/g);
        @roles = sort keys %roles;
        unless (@roles) {
            $log->syslog('err', 'Unknown role %s', $options->{roles});
            exit 1;
        }
    }

    foreach my $list (@$all_lists) {
        unless ($list->{'admin'}{'status'} eq 'open') {
            $log->syslog('err', 'List is not open: %s', $list);
            next;
        }
        foreach my $role (@roles) {
            unless ($list->restore_users($role)) {
                warn sprintf "%s: Could not restore list users (%s)\n",
                    $list->get_id, $role;
            } else {
                warn sprintf "%s: Restored list users (%s)\n",
                    $list->get_id, $role;
            }
        }
    }

    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-restore - Restore users of the lists

=head1 SYNOPSIS

C<sympa restore> C<--roles=>I<role>[C<,>I<role>...] I<list>C<@>I<domain>|C<"*">

=head1 DESCRIPTION

Restore users from files dumped by C<--dump_users>.

=head1 HISTORY

This option was added on Sympa 6.2.34.

=cut
