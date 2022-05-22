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

package Sympa::CLI::upgrade;

use strict;
use warnings;
use English qw(-no_match_vars);
use Getopt::Long qw(:config no_ignore_case);

use Sympa::Constants;
use Sympa::Log;
use Sympa::Upgrade;

use parent qw(Sympa::CLI);

my $log = Sympa::Log->instance;

use constant _options       => qw(from=s to=s);
use constant _args          => qw();
use constant _need_priv     => 1;
use constant _log_to_stderr => 1;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    _upgrade($options);
    exit 0;
}

sub _upgrade {
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

C<sympa upgrade> [ C<--from=>I<version_X> ] [ C<--to=>I<version_Y> ]

C<sympa upgrade> I<sub-command> ...

=head1 DESCRIPTION

If any sub-command are not specified,
runs Sympa maintenance script to upgrade from version I<X> to version I<Y>.

About available sub-commands see below.

=head1 SUB-COMMANDS

Currently following sub-commands are available.
To see detail of each sub-command,
run 'C<sympal.pl help upgrade> I<sub-command>'.

=over

=item L<"sympa upgrade incoming ..."|sympa-upgrade-incoming(1)>

Upgrade messages in incoming spool

=item L<"sympa upgrade outgoing ..."|sympa-upgrade-outgoing(1)>

Migrating messages in bulk tables

=item L<"sympa upgrade password ...|sympa-upgrade-password(1)>

Upgrading password in database

=item L<"sympa upgrade shared ..."|sympa-upgrade-shared(1)>

Encode file names in shared repositories.

=back

=cut
