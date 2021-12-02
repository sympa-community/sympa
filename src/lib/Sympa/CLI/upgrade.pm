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

package Sympa::CLI::upgrade;

use strict;
use warnings;

use Sympa::Constants;
use Sympa::Log;
use Sympa::Upgrade;

use parent qw(Sympa::CLI);

my $log = Sympa::Log->instance;

use constant _options       => qw(from=s to=s);
use constant _args          => qw();
use constant _log_to_stderr => 1;

sub _run {
    my $class   = shift;
    my $options = shift;

    $log->syslog('notice', "Upgrade process...");

    $options->{from} ||= Sympa::Upgrade::get_previous_version();
    $options->{to}   ||= Sympa::Constants::VERSION;

    if ($options->{from} eq $options->{to}) {
        $log->syslog('notice', 'Current version: %s; no upgrade is required',
            $options->{to});
        exit 0;
    } else {
        $log->syslog('notice', "Upgrading from %s to %s...",
            $options->{from}, $options->{to});
    }

    unless (Sympa::Upgrade::upgrade($options->{from}, $options->{to})) {
        $log->syslog('err', "Migration from %s to %s failed",
            $options->{from}, $options->{to});
        exit 1;
    }

    $log->syslog('notice', 'Upgrade process finished');
    Sympa::Upgrade::update_version();

    exit 0;

}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-upgrade - Upgrade Sympa

=head1 SYNOPSIS

C<sympa.pl upgrade> [ C<--from=>I<version_X> ] [ C<--to=>I<version_Y> ]

=head1 DESCRIPTION

Runs Sympa maintenance script to upgrade from version I<X> to version I<Y>.

=cut
