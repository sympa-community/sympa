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

package Sympa::CLI::reload_list_config;

use strict;
use warnings;

use Sympa::List;
use Sympa::Log;

use parent qw(Sympa::CLI);

my $log = Sympa::Log->instance;

use constant _options       => qw();
use constant _args          => qw(list_id|domain?);
use constant _log_to_stderr => 1;

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list_id = shift;

    if ($list_id and 0 < index $list_id, '@') {
        $log->syslog('notice', 'Loading list %s...', $list_id);
        my $list = Sympa::List->new($list_id, '', {reload_config => 1});
        unless (defined $list) {
            printf STDERR "Error : incorrect list name '%s'\n", $list_id;
            exit 1;
        }
    } elsif ($list_id) {
        unless (Conf::valid_robot($list_id)) {
            printf STDERR "Error : incorrect domain '%s'\n", $list_id;
            exit 1;
        }
        $log->syslog('notice', "Loading ALL lists in %s...", $list_id);
        Sympa::List::get_lists($list_id, reload_config => 1);
    } else {
        $log->syslog('notice', "Loading ALL lists...");
        Sympa::List::get_lists('*', reload_config => 1);
    }
    $log->syslog('notice', '...Done.');

    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-reload_list_config - Recreate config cache of the lists

=head1 SYNOPSIS

C<sympa.pl reload_list_config> I<list>C<@>I<domain>|I<domain>

=head1 DESCRIPTION

=cut
