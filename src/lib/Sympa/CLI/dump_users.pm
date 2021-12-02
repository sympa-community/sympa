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
__END__

=encoding utf-8

=head1 NAME

sympa-dump_users - Dump users of the lists

=head1 SYNOPSIS

C<sympa.pl dump_users> C<--roles=>I<role>[C<,>I<role>...] I<list>C<@>I<domain>|C<"*">

=head1 DESCRIPTION

Dumps users of a list or all lists.

C<--roles> may specify C<member> (subscribers), C<owner> (owners),
C<editor> (moderators) or any of them separated by comma (C<,>).
Only C<member> is chosen by default.

Users are dumped in files I<role>C<.dump> in each list directory.

Note: On Sympa prior to 6.2.31b.1, subscribers were dumped in
F<subscribers.db.dump> file, and owners and moderators could not be dumped.

See also L<"sympa.pl restore_users"|sympa-restore_users>.

=cut
