# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::Mail;

use strict;
use warnings;
use English qw(-no_match_vars);
use POSIX qw();

use Sympa::Bulk;
use Conf;
use Log;
use Sympa::Robot;
use tools;

my $opensmtp = 0;
my $fh       = 'fh0000000000';    ## File handle for the stream.

my $max_arg = eval { POSIX::_SC_ARG_MAX(); };
if ($EVAL_ERROR) {
    $max_arg = 4096;
    printf STDERR <<'EOF', $max_arg;
Your system does not conform to the POSIX P1003.1 standard, or
your Perl system does not define the _SC_ARG_MAX constant in its POSIX
library. You must modify the smtp.pm module in order to set a value
for variable %s.

EOF
} else {
    $max_arg = POSIX::sysconf($max_arg);
}

my %pid = ();

our $always_use_bulk;    ## for calling context

our $log_smtp;     # SMTP logging is enabled or not

### PUBLIC FUNCTIONS ###

#sub set_send_spool($spool_dir);
#DEPRECATED: No longer used.

#sub mail_file($robot, $filename, $rcpt, $data, $return_message_as_string);
##DEPRECATED: Use Sympa::Message->new_from_template() & sending().

#sub mail_message($message, $rcpt, [tag_as_last => 1]);
# DEPRECATED: this is now a subroutine of Sympa::List::send_msg().

#sub mail_forward($message, $from, $rcpt, $robot);
#DEPRECATED: This is no longer used.

#####################################################################
# public reaper
#####################################################################
# Non blocking function called by : Sympa::Mail::smtpto(), sympa::main_loop
#  task_manager::INFINITE_LOOP scanning the queue,
#  bounced::infinite_loop scanning the queue,
# just to clean the defuncts list by waiting to any processes and
#  decrementing the counter.
#
# IN : $block
# OUT : $i
#####################################################################
sub reaper {
    my $block = shift;
    my $i;

    $block = 1 unless (defined($block));
    while (($i = waitpid(-1, $block ? POSIX::WNOHANG() : 0)) > 0) {
        $block = 1;
        if (!defined($pid{$i})) {
            Log::do_log('debug2', 'Reaper waited %s, unknown process to me',
                $i);
            next;
        }
        $opensmtp--;
        delete($pid{$i});
    }
    Log::do_log(
        'debug2',
        'Reaper unwaited pids: %s Open = %s',
        join(' ', sort keys %pid), $opensmtp
    );
    return $i;
}

#DEPRECATED.  Use mail_message().
#sub sendto;

####################################################
# sending
####################################################
# send a message using smpto function or puting it
# in spool according to the context
# Signing if needed
#
#
# IN : -$message: ref(Sympa::Message) - message to be sent
#      -$rcpt: SCALAR | ref(ARRAY) - recipients for SMTP "RCPT To:" field.
#      -$from: for SMTP, "MAIL From:" field; for spool sending, "X-Sympa-From"
#              field
#      -use_bulk => boolean
#
# OUT : 1 - call to smtpto (sendmail) | 0 - push in spool
#           | undef
#
####################################################
sub sending {
    my $message = shift;
    my $rcpt    = shift;
    my $from    = shift;
    my %params  = @_;

    my $that = $message->{context};
    my ($robot_id, $listname);
    if (ref $that eq 'Sympa::List') {
        $robot_id = $that->{'domain'};
        $listname = $that->{'name'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $priority_message = $params{'priority'};
    my $priority_packet =
        Conf::get_robot_conf($robot_id, 'sympa_packet_priority');
    my $delivery_date = $params{'delivery_date'};
    $delivery_date = time() unless ($delivery_date);
    my $use_bulk    = $always_use_bulk || $params{'use_bulk'};
    my $tag_as_last = $params{'tag_as_last'};
    my $sympa_file;
    my $fh;

    if ($use_bulk) {
        # in that case use bulk tables to prepare message distribution

        $message->{envelope_sender} = $from;

        my $bulk_code = Sympa::Bulk::store(
            $message,
            'rcpts'            => $rcpt,
            'priority_message' => $priority_message,
            'priority_packet'  => $priority_packet,
            'delivery_date'    => $delivery_date,
            'tag_as_last'      => $tag_as_last,
        );

        unless (defined $bulk_code) {
            Log::do_log('err', 'Failed to store message for %s', $that);
            Sympa::Robot::send_notify_to_listmaster('bulk_error', $robot_id,
                {'listname' => $listname});
            return undef;
        }
    } else {    # send it now
        Log::do_log('debug', "NOT USING BULK");
        *SMTP = smtpto($from, $rcpt, $robot_id);

        # Send message stripping Return-Path pseudo-header field.
        my $msg_string = $message->as_string;
        $msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;

        print SMTP $msg_string;
        unless (close SMTP) {
            Log::do_log('err', 'Could not close safefork to sendmail');
            return undef;
        }
    }
    return 1;
}

##############################################################################
# smtpto
##############################################################################
# Makes a sendmail ready for the recipients given as argument, uses a file
# descriptor in the smtp table which can be imported by other parties.
# Before, waits for number of children process < number allowed by sympa.conf
#
# IN : $from :(+) for SMTP "MAIL From:" field
#      $rcpt :(+) ref(SCALAR)|ref(ARRAY)- for SMTP "RCPT To:" field
#      $robot :(+) robot
#      $envid : an ID of this message submission in notification table
# OUT : Sympa::Mail::$fh - file handle on opened file for ouput, for SMTP
#       "DATA" field.  Otherwise undef
#
##############################################################################
# TODO: Split rcpt by max length of command line (_SC_ARG_MAX).
sub smtpto {
    Log::do_log('debug2', '(%s, %s, %s, %s)', @_);
    my ($from, $rcpt, $robot, $envid) = @_;

    unless ($from) {
        Log::do_log('err', 'Missing Return-Path');
    }

    if (ref($rcpt) eq 'SCALAR') {
        Log::do_log('debug3', '(%s, %s)', $from, $$rcpt);
    } elsif (ref($rcpt) eq 'ARRAY') {
        Log::do_log('debug3', '(%s, %s)', $from, join(',', @{$rcpt}));
    }

    my ($pid, $str);

    # Check how many open smtp's we have, if too many wait for a few
    # to terminate and then do our job.

    Log::do_log('debug3', 'Open = %s', $opensmtp);
    while ($opensmtp > Conf::get_robot_conf($robot, 'maxsmtp')) {
        Log::do_log('debug3', 'Too many open SMTP (%s), calling reaper',
            $opensmtp);
        last if reaper(0) == -1;    # Blocking call to the reaper.
    }

    *IN  = ++$fh;
    *OUT = ++$fh;

    if (!pipe(IN, OUT)) {
        die sprintf 'Unable to create a channel in smtpto: %s', $ERRNO;
        # No return
    }
    $pid = tools::safefork();
    $pid{$pid} = 0;

    my $sendmail = Conf::get_robot_conf($robot, 'sendmail');
    my @sendmail_args = split /\s+/,
        Conf::get_robot_conf($robot, 'sendmail_args');
    if (defined $envid and length $envid) {
        # Postfix clone of sendmail command doesn't allow spaces between
        # "-V" and envid.
        push @sendmail_args, '-N', 'success,delay,failure', "-V$envid";
    }
    if ($pid == 0) {
        close(OUT);
        open(STDIN, "<&IN");

        $from = '' if $from eq '<>';    # null sender
        # Terminate options by "--" to prevent addresses beginning with "-"
        # being treated as options.
        if (!ref($rcpt)) {
            exec $sendmail, @sendmail_args, '-f', $from, '--', $rcpt;
        } elsif (ref($rcpt) eq 'SCALAR') {
            exec $sendmail, @sendmail_args, '-f', $from, '--', $$rcpt;
        } elsif (ref($rcpt) eq 'ARRAY') {
            exec $sendmail, @sendmail_args, '-f', $from, '--', @$rcpt;
        }

        exit 1;                         # Should never get there.
    }
    if ($log_smtp) {
        my $r;
        if (!ref $rcpt) {
            $r = $rcpt;
        } elsif (ref $rcpt eq 'SCALAR') {
            $r = $$rcpt;
        } else {
            $r = join(' ', @$rcpt);
        }
        Log::do_log(
            'debug3', 'safefork: %s %s -f \'%s\' -- %s',
            $sendmail, join(' ', @sendmail_args),
            $from, $r
        );
    }
    unless (close(IN)) {
        Log::do_log('err', 'Could not close safefork');
        return undef;
    }
    $opensmtp++;
    select(undef, undef, undef, 0.3)
        if $opensmtp < Conf::get_robot_conf($robot, 'maxsmtp');
    return ("Sympa::Mail::$fh");    # Symbol for the write descriptor.
}

#This has never been used.
#sub send_in_spool($rcpt, $robot, $sympa_email, $XSympaFrom);

#DEPRECATED: Use Sympa::Message::reformat_utf8_message().
#sub reformat_message($;$$);

#DEPRECATED. Moved to Sympa::Message::_fix_utf8_parts as internal functioin.
#sub fix_part;

1;
