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

package Sympa::CLI::test;

use strict;
use warnings;

use parent qw(Sympa::CLI);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    Sympa::CLI->run(qw(help test));
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-test - Test functions of Sympa

=head1 SYNOPSIS

C<sympa test> I<sub-command> ...

=head1 DESCRIPTION

TBD.

=head1 SUB-COMMANDS

Currently following sub-commands are available.
To see detail of each sub-command, run 'C<sympal.pl help test> I<sub-command>'.

=over

=item L<"sympa test ldap ..."|sympa-test-ldap(1)>

Testing LDAP connection for Sympa

=item L<"sympa test soap ..."|sympa-test-soap(1)>

Demo client for Sympa SOAP/HTTP API

=item L<"sympa test syslog ..."|sympa-test-syslog(1)>

Testing logging function of Sympa

=back

=cut
