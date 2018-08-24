# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Ticket;

use strict;
use warnings;
use POSIX qw();

use Conf;
use Sympa::DatabaseManager;
use Sympa::Log;
use Sympa::Tools::Password;
use Sympa::Tools::Time;

my $log = Sympa::Log->instance;

# Create new entry in one_time_ticket table using a rand as id so later
# access is authenticated.
# Old name: Sympa::Auth::create_one_time_ticket().
sub create {
    my $email       = shift;
    my $robot       = shift;
    my $data_string = shift;
    my $remote_addr = shift;
    ## Value may be 'mail' if the IP address is not known

    my $ticket = Sympa::Tools::Password::get_random();
    #$log->syslog('info', '(%s, %s, %s, %s) Value = %s',
    #    $email, $robot, $data_string, $remote_addr, $ticket);

    my $date = time;

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{INSERT INTO one_time_ticket_table
              (ticket_one_time_ticket, robot_one_time_ticket,
               email_one_time_ticket, date_one_time_ticket,
               data_one_time_ticket,
               remote_addr_one_time_ticket, status_one_time_ticket)
              VALUES (?, ?, ?, ?, ?, ?, ?)},
            $ticket, $robot,
            $email,  time,
            $data_string,
            $remote_addr, 'open'
        )
    ) {
        $log->syslog(
            'err',
            'Unable to insert new one time ticket for user %s, robot %s in the database',
            $email,
            $robot
        );
        return undef;
    }
    return $ticket;
}

# Read one_time_ticket from table and remove it.
# Old name: Sympa::Auth::create_one_time_ticket().
sub load {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $robot         = shift;
    my $ticket_number = shift;
    my $addr          = shift;

    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT ticket_one_time_ticket AS ticket,
                     robot_one_time_ticket AS robot,
                     email_one_time_ticket AS email,
                     date_one_time_ticket AS "date",
                     data_one_time_ticket AS data,
                     remote_addr_one_time_ticket AS remote_addr,
                     status_one_time_ticket as status
              FROM one_time_ticket_table
              WHERE ticket_one_time_ticket = ? AND robot_one_time_ticket = ?},
            $ticket_number, $robot
        )
    ) {
        $log->syslog('err',
            'Unable to retrieve one time ticket %s from database',
            $ticket_number);
        return {'result' => 'error'};
    }

    my $ticket = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;

    unless ($ticket) {
        $log->syslog('info', 'Unable to find one time ticket %s', $ticket);
        return {'result' => 'not_found'};
    }

    my $result;
    my $printable_date =
        POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime $ticket->{'date'});
    my $lockout = Conf::get_robot_conf($robot, 'one_time_ticket_lockout')
        || 'open';
    my $lifetime =
        Sympa::Tools::Time::duration_conv(
        Conf::get_robot_conf($robot, 'one_time_ticket_lifetime') || 0);

    if ($lockout eq 'one_time' and $ticket->{'status'} ne 'open') {
        $result = 'closed';
        $log->syslog('info', 'Ticket %s from %s has been used before (%s)',
            $ticket_number, $ticket->{'email'}, $printable_date);
    } elsif ($lockout eq 'remote_addr'
        and $ticket->{'status'} ne $addr
        and $ticket->{'status'} ne 'open') {
        $result = 'closed';
        $log->syslog('info',
            'Ticket %s from %s refused because accessed by the other (%s)',
            $ticket_number, $ticket->{'email'}, $printable_date);
    } elsif ($lifetime and $ticket->{'date'} + $lifetime < time) {
        $log->syslog('info', 'Ticket %s from %s refused because expired (%s)',
            $ticket_number, $ticket->{'email'}, $printable_date);
        $result = 'expired';
    } else {
        $result = 'success';
    }

    if ($result eq 'success') {
        unless (
            $sth = $sdm->do_prepared_query(
                q{UPDATE one_time_ticket_table
                  SET status_one_time_ticket = ?
                  WHERE ticket_one_time_ticket = ? AND
                        robot_one_time_ticket = ?},
                $addr, $ticket_number, $robot
            )
        ) {
            $log->syslog('err',
                'Unable to set one time ticket %s status to %s',
                $ticket_number, $addr);
        } elsif (!$sth->rows) {
            # ticket may be removed by task.
            $log->syslog('info', 'Unable to find one time ticket %s',
                $ticket_number);
            return {'result' => 'not_found'};
        }
    }

    $log->syslog('info', 'Ticket: %s; Result: %s', $ticket_number, $result);
    return {
        'result'      => $result,
        'date'        => $ticket->{'date'},
        'email'       => $ticket->{'email'},
        'remote_addr' => $ticket->{'remote_addr'},
        'robot'       => $robot,
        'data'        => $ticket->{'data'},
        'status'      => $ticket->{'status'}
    };
}

# Remove old one_time_ticket from a particular robot or from all robots.
# Delay is a parameter in seconds.
# Old name: Sympa::Session::purge_old_tickets().
sub purge_old_tickets {
    $log->syslog('debug2', '(%s)', @_);
    my $robot = shift;

    my $delay = Sympa::Tools::Time::duration_conv(
        $Conf::Conf{'one_time_ticket_table_ttl'});

    unless ($delay) {
        $log->syslog('info', '(%s) Exit with delay null', $robot);
        return;
    }

    my @tickets;
    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm) {
        $log->syslog('err', 'Unavailable database connection');
        return;
    }

    my @conditions;
    push @conditions,
        sprintf('robot_one_time_ticket = %s', $sdm->quote($robot))
        if $robot and $robot ne '*';
    push @conditions, sprintf('%d > date_one_time_ticket', time - $delay)
        if $delay;

    my $condition = join(' AND ', @conditions);
    my $where = "WHERE $condition" if $condition;

    my $count_statement =
        sprintf 'SELECT COUNT(*) FROM one_time_ticket_table %s', $where;
    my $statement = sprintf 'DELETE FROM one_time_ticket_table %s', $where;

    unless ($sth = $sdm->do_query($count_statement)) {
        $log->syslog('err',
            'Unable to count old one time tickets for robot %s', $robot);
        return undef;
    }

    my $total = $sth->fetchrow;
    if ($total == 0) {
        $log->syslog('debug', 'No tickets to expire');
    } else {
        unless ($sth = $sdm->do_query($statement)) {
            $log->syslog('err',
                'Unable to delete expired one time tickets for robot %s',
                $robot);
            return undef;
        }
    }
    return $total;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Ticket - One-time ticket for authorization

=head1 SYNOPSIS

TBD.

=head1 DESCRIPTION

TBD.

=head1 HISTORY

Feature to handle one-time ticket was introduced on Sympa 6.0b.2.

L<Sympa::Ticket> module appeared on Sympa 6.2.13.

=cut
