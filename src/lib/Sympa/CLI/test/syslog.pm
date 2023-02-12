# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
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

package Sympa::CLI::test::syslog;

use strict;
use warnings;

use Conf;
use Sympa::Log;

use parent qw(Sympa::CLI::test);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 1;

sub _run {
    my $class   = shift;
    my $options = shift;

    my $log = Sympa::Log->instance;

    # Open the syslog and say we're read out stuff.
    $log->openlog(
        $Conf::Conf{'syslog'},
        $Conf::Conf{'log_socket_type'},
        service => 'sympa/testlogs'
    );

    # setting log_level using conf unless it is set by calling option
    if ($options->{log_level}) {
        $log->syslog('info', 'Logs seems OK, log level set using options: %s',
            $options->{log_level});
    } else {
        $log->{level} = $Conf::Conf{'log_level'};
        $log->syslog(
            'info',
            'Logs seems OK, default log level %s',
            $Conf::Conf{'log_level'}
        );
    }
    printf "Ok, now check logs \n";

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-test-syslog - Testing logging function of Sympa

=head1 SYNOPSIS

C<sympa> C<test> C<syslog> [ C<--debug> ]
[ C<--log_level=>I<level> ] [ C<--config=>I</path/to/sympa.conf> ]

=head1 DESCRIPTION

TBD.

=head1 HISTORY

F<testlogs.pl> appeared on Sympa 4.0a.2.

Its function was moved to C<sympa test syslog> on Sympa 6.2.71b.

=cut
