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

package Sympa::CLI::dump_users;

use strict;
use warnings;

use Sympa::List;
use Sympa::Log;

use parent qw(Sympa::CLI);

my $log = Sympa::Log->instance;

use constant _options => qw(role=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    my $list_id = shift @argv;

#if ($options->{dump} or $options->{dump_users}) {
    my $all_lists;

    if (defined $list_id and $list_id eq 'ALL') {
        $all_lists =
            Sympa::List::get_lists('*', filter => [status => 'open']);
    } elsif (defined $list_id and length $list_id) {
        # The parameter is list ID and list have to be open.
        unless (0 < index $list_id, '@') {
            $log->syslog('err', 'Incorrect list address %s', $list_id);
            exit 1;
        }
        my $list = Sympa::List->new($list_id);
        unless (defined $list) {
            $log->syslog('err', 'Unknown list %s', $list_id);
            exit 1;
        }
        unless ($list->{'admin'}{'status'} eq 'open') {
            $log->syslog('err', 'List is not open: %s', $list);
            exit 1;
        }

        $all_lists = [$list];
    } else {
        $log->syslog('err', 'No lists specified');
        exit 1;
    }

    my @roles = qw(member);
    if ($options->{role}) {
        my %roles = map { ($_ => 1) }
            ($options->{role} =~ /\b(member|owner|editor)\b/g);
        @roles = sort keys %roles;
        unless (@roles) {
            $log->syslog('err', 'Unknown role %s', $options->{role});
            exit 1;
        }
    }

    foreach my $list (@$all_lists) {
        foreach my $role (@roles) {
            unless ($list->dump_users($role)) {
                printf STDERR "%s: Could not dump list users (%s)\n",
                    $list->get_id, $role;
            } else {
                printf STDERR "%s: Dumped list users (%s)\n",
                    $list->get_id, $role;
            }
        }
    }

    exit 0;
}
1;
