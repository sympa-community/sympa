# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

package Sympa::Aliases::CheckSMTP;

use strict;
use warnings;
BEGIN { eval 'use Net::SMTP'; }

use Conf;
use Sympa::Log;

use base qw(Sympa::Aliases);

my $log = Sympa::Log->instance;

# Old name: Sympa::Admin::list_check_smtp().
sub check {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self     = shift;
    my $name     = shift;
    my $robot_id = shift;

    my $smtp_relay = Conf::get_robot_conf($robot_id, 'list_check_smtp');
    return 0 unless defined $smtp_relay and length $smtp_relay;

    my $smtp_helo = Conf::get_robot_conf($robot_id, 'list_check_helo')
        || $smtp_relay;
    $smtp_helo =~ s/:[-\w]+$// if $smtp_helo;

    my @suffixes = split /\s*,\s*/,
        (Conf::get_robot_conf($robot_id, 'list_check_suffixes') || '');
    my @addresses = (
        sprintf('%s@%s', $name, $robot_id),
        map { sprintf('%s-%s@%s', $name, $_, $robot_id) } @suffixes
    );
    my $return_address = sprintf '%s%s@%s', $name,
        (Conf::get_robot_conf($robot_id, 'return_path_suffix') || ''),
        $robot_id;
    push @addresses, $return_address
        unless grep { $return_address eq $_ } @addresses;

    unless ($Net::SMTP::VERSION) {
        $log->syslog('err',
            'Unable to use Net library, Net::SMTP required, install it first'
        );
        return undef;
    }
    if (my $smtp = Net::SMTP->new(
            $smtp_relay,
            Hello   => $smtp_helo,
            Timeout => 30
        )
    ) {
        $smtp->mail('');
        my $conf = 0;
        foreach my $address (@addresses) {
            $conf = $smtp->to($address);
            last if $conf;
        }
        $smtp->quit();
        return $conf;
    }
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Aliases::CheckSMTP - Alias management: Check addresses using SMTP

=head1 SYNOPSIS

  use Sympa::Aliases;
  my $aliases = Sympa::Aliases->new('CheckSMTP');
  $aliases->check('listname', 'domain');

=head1 DESCRIPTION 

TBD.

=head2 Methods

=over

=item check ($listname, $robot_id)

I<Instance method>.
Checks if the requested list exists already using SMTP 'RCPT TO'.

Parameters:

=over

=item $listname

Name of the list.

=item $robot_id

List's robot.

=back

Returns:

Instance of L<Net::SMTP> class or false value.

=back

=head2 Configuration parameters

Following parameters in F<sympa.conf> or F<robot.conf> are referred by
this module.

=over

=item list_check_helo

SMTP HELO (EHLO) parameter used for address verification.
Default value is the host part of C<list_check_smtp> parameter.

=item list_check_smtp

SMTP server to verify existence of the same addresses as the list.

=item list_check_suffixes

List of suffixes used for list addresses.

=back

=head1 SEE ALSO

L<Sympa::Aliases>.

=head1 HISTORY

The feature which allows Sympa to check listname on SMTP server
before list creation, contributed by Sergiy Zhuk, appeared on Sympa 3.3.

C<list_check_helo> parameter was added by S. Ikeda on Sympa 6.1.5.

L<Sympa::Aliases::CheckSMTP> as a separate module appeared on Sympa 6.2.23b.

=cut 
