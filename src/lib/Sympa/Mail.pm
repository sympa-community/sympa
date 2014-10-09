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

our $log_smtp;           # SMTP logging is enabled or not

### PUBLIC FUNCTIONS ###

#sub set_send_spool($spool_dir);
#DEPRECATED: No longer used.

#sub mail_file($robot, $filename, $rcpt, $data, $return_message_as_string);
##DEPRECATED: Use Sympa::Message->new_from_template() & sending().

#sub mail_message($message, $rcpt, [tag_as_last => 1]);
# DEPRECATED: this is now a subroutine of Sympa::List::distribute_msg().

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
#      -$message->{envelope_sender}: for SMTP, "MAIL From:" field; for spool
#              sending, "Return-Path" field
#
# OUT : 1 - call to smtpto (sendmail) | 0 - push in spool
#           | undef
#
####################################################
sub sending {
    my $message = shift;
    my $rcpt    = shift;
    my %params  = @_;

    my $that = $message->{context};
    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $that->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $tag_as_last = $params{'tag_as_last'};
    my $sympa_file;
    my $fh;

    if ($always_use_bulk) {
        # in that case use bulk tables to prepare message distribution
        unless (defined Sympa::Bulk::store($message, $rcpt)) {
            Log::do_log('err', 'Failed to store message %s for %s',
                $message, $that);
            tools::send_notify_to_listmaster(
                $that,
                'bulk_error',
                {   ($list ? (listname => $list->{'name'}) : ()),    #compat.
                    'message_id' => $message->get_id,
                }
            );
            return undef;
        }
    } else {    # send it now
        Log::do_log('debug', "NOT USING BULK");
        *SMTP = smtpto($message->{envelope_sender}, $rcpt, $robot_id);

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
# IN : $return_path :(+) for SMTP "MAIL From:" field
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
    my ($return_path, $rcpt, $robot, $envid) = @_;

    unless ($return_path) {
        Log::do_log('err', 'Missing Return-Path');
    }

    if (ref($rcpt) eq 'SCALAR') {
        Log::do_log('debug3', '(%s, %s)', $return_path, $$rcpt);
    } elsif (ref($rcpt) eq 'ARRAY') {
        Log::do_log('debug3', '(%s, %s)', $return_path, join(',', @{$rcpt}));
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
    $pid = safefork();
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

        $return_path = '' if $return_path eq '<>';    # null sender
        # Terminate options by "--" to prevent addresses beginning with "-"
        # being treated as options.
        if (!ref($rcpt)) {
            exec $sendmail, @sendmail_args, '-f', $return_path, '--', $rcpt;
        } elsif (ref($rcpt) eq 'SCALAR') {
            exec $sendmail, @sendmail_args, '-f', $return_path, '--', $$rcpt;
        } elsif (ref($rcpt) eq 'ARRAY') {
            exec $sendmail, @sendmail_args, '-f', $return_path, '--', @$rcpt;
        }

        exit 1;    # Should never get there.
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
            $return_path, $r
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

## Safefork does several tries before it gives up.
## Do 3 trials and wait 10 seconds * $i between each.
## Exit with a fatal error is fork failed after all
## tests have been exhausted.
# Old name: tools::safefork().
sub safefork {
    my ($i, $pid);

    my $err;
    for ($i = 1; $i < 4; $i++) {
        my ($pid) = fork;
        return $pid if defined $pid;

        $err = $ERRNO;
        Log::do_log('err', 'Cannot create new process: %s', $err);
        #FIXME:should send a mail to the listmaster
        sleep(10 * $i);
    }
    die sprintf 'Exiting because cannot create new process: %s', $err;
    # No return.
}

1;
