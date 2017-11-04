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

package Sympa::Aliases;

use strict;
use warnings;
use English qw(-no_match_vars);
BEGIN { eval 'use Net::SMTP'; }

use Conf;
use Sympa::Constants;
use Sympa::Log;

my $log = Sympa::Log->instance;

sub new {
    bless {} => shift;
}

# OLd name: Sympa::Admin::list_check_smtp().
sub check {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self     = shift;
    my $name     = shift;
    my $robot_id = shift;

    my $conf = '';
    my $smtp;

    my $smtp_relay = Conf::get_robot_conf($robot_id, 'list_check_smtp');
    my $smtp_helo  = Conf::get_robot_conf($robot_id, 'list_check_helo')
        || $smtp_relay;
    $smtp_helo =~ s/:[-\w]+$// if $smtp_helo;
    my $suffixes = Conf::get_robot_conf($robot_id, 'list_check_suffixes');
    return 0
        unless $smtp_relay and $suffixes;
    $log->syslog('debug2', '(%s, %s)', $name, $robot_id);
    my @suf = split /\s*,\s*/, $suffixes;
    return 0 unless @suf;    #FIXME

    my @addresses = (
        $name . '@' . $robot_id,
        map { $name . '-' . $_ . '@' . $robot_id } @suf
    );

    unless ($Net::SMTP::VERSION) {
        $log->syslog('err',
            'Unable to use Net library, Net::SMTP required, install it first'
        );
        return undef;
    }
    if ($smtp = Net::SMTP->new(
            $smtp_relay,
            Hello   => $smtp_helo,
            Timeout => 30
        )
        ) {
        $smtp->mail('');
        foreach my $address (@addresses) {
            $conf = $smtp->to($address);
            last if $conf;
        }
        $smtp->quit();
        return $conf;
    }
    return undef;
}

# Old name: Sympa::Admin::install_aliases().
sub add {
    $log->syslog('debug', '(%s, %s)', @_);
    my $self = shift;
    my $list = shift;

    return 1
        if lc Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') eq
            'none';

    my $alias_manager = $Conf::Conf{'alias_manager'};
    $log->syslog('debug2', '%s add %s %s', $alias_manager, $list->{'name'},
        $list->{'admin'}{'host'});

    unless (-x $alias_manager) {
        $log->syslog('err', 'Failed to install aliases: %m');
        return undef;
    }

    #FIXME: 'host' parameter is passed to alias_manager: no 'domain'
    # parameter to determine robot.
    my $status =
        system($alias_manager, 'add', $list->{'name'},
        $list->{'admin'}{'host'}) >> 8;

    if ($status == 0) {
        $log->syslog('info', 'Aliases installed successfully');
        return 1;
    }

    if ($status == 1) {
        $log->syslog('err', 'Configuration file %s has errors',
            Conf::get_sympa_conf());
    } elsif ($status == 2) {
        $log->syslog('err',
            'Internal error: Incorrect call to alias_manager');
    } elsif ($status == 3) {
        # Won't occur
        $log->syslog('err',
            'Could not read sympa config file, report to httpd error_log');
    } elsif ($status == 4) {
        # Won't occur
        $log->syslog('err',
            'Could not get default domain, report to httpd error_log');
    } elsif ($status == 5) {
        $log->syslog('err', 'Unable to append to alias file');
    } elsif ($status == 6) {
        $log->syslog('err', 'Unable to run newaliases');
    } elsif ($status == 7) {
        $log->syslog('err',
            'Unable to read alias file, report to httpd error_log');
    } elsif ($status == 8) {
        $log->syslog('err',
            'Could not create temporay file, report to httpd error_log');
    } elsif ($status == 13) {
        $log->syslog('info', 'Some of list aliases already exist');
    } elsif ($status == 14) {
        $log->syslog('err',
            'Can not open lock file, report to httpd error_log');
    } elsif ($status == 15) {
        $log->syslog('err', 'The parser returned empty aliases');
    } else {
        $log->syslog('err', 'Unknown error %s while running alias manager %s',
            $status, $alias_manager);
    }

    return undef;
}

# Old names: Sympa::Admin::remove_aliases() & Sympa::List::remove_aliases().
sub del {
    $log->syslog('info', '(%s, %s)', @_);
    my $self = shift;
    my $list = shift;

    return 1
        if lc Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') eq
            'none';

    my $alias_manager = $Conf::Conf{'alias_manager'};

    unless (-x $alias_manager) {
        $log->syslog('err', 'Cannot run alias_manager %s', $alias_manager);
        return undef;
    }

    my $status =
        system($alias_manager, 'del', $list->{'name'},
        $list->{'admin'}{'host'}) >> 8;

    if ($status == 0) {
        $log->syslog('info', 'Aliases for list %s removed successfully',
            $list);
        return 1;
    } else {
        $log->syslog('err', 'Failed to remove aliases; status %d: %m',
            $status);
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME 

Sympa::Aliases - Base class for alias management

=head1 DESCRIPTION 

TBD.

=head2 Methods

=over

=item new ( )

I<Constructor>.
Creates new instance of L<Sympa::Aliases>.

=item check ($listname, $robot_id)

I<Instance method>.
Checks if the requested list exists already using SMTP 'rcpt to'.

Parameters:

=over

=item $listname

Name of the list.

=item $robot_id

List's robot.

=back

Returns:

L<Net::SMTP> object or false value.

=item add ($list)

I<Instance method>.
Installs aliases for the list $list.

Parameters:

=over

=item $list

An instance of L<Sympa::List>.

=back

Returns:

C<undef> if not applicable or aliases not installed. or C<1> if OK.

=item del ($list)

I<Instance method>.
Removes aliases for the list $list.

Parameters:

=over

=item $list

An instance of L<Sympa::List>.

=back

Returns:

C<undef> if not applicable. C<1> (if ok) or concated string of alias not
removed.

=back

=head1 HISTORY

F<alias_manager.pl> as a program to automate alias management appeared on
Sympa 3.1b.13.

L<Sympa::Aliases> module as an OO-based class appeared on Sympa 6.2.23b,
and it obsoleted F<alias_manager.pl>.

=cut 
