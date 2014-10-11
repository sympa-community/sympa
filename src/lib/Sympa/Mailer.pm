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

package Sympa::Mailer;

use strict;
use warnings;
use base qw(Class::Singleton);

use English qw(-no_match_vars);
use POSIX qw();

use Sympa::Bulk;
use Conf;
use Log;
use tools;

my $max_arg;
eval {
    $max_arg = POSIX::sysconf( POSIX::_SC_ARG_MAX() );
};
if ($EVAL_ERROR) {
    $max_arg = 4096;
}

=head2 CLASS METHODS

=over

=item instance ( %parameters )

Creates a new L<Sympa::Mailer> object.

Returns:

A new L<Sympa::Mailer> object, or I<undef> for failure.

=back

=cut

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;
    my %params = @_;

    bless {
        pids => {},
        opensmtp => 0,
        always_use_bulk => undef, # for calling context
        log_smtp => undef, # SMTP logging is enabled or not
    } => $class;
}

=head2 Instance methods

=cut

#sub set_send_spool($spool_dir);
#DEPRECATED: No longer used.

#sub mail_file($robot, $filename, $rcpt, $data, $return_message_as_string);
##DEPRECATED: Use Sympa::Message->new_from_template() & send_message().

#sub mail_message($message, $rcpt, [tag_as_last => 1]);
# DEPRECATED: this is now a subroutine of Sympa::List::distribute_msg().

#sub mail_forward($message, $from, $rcpt, $robot);
#DEPRECATED: This is no longer used.

=over

=item reaper ( [ $block ] )

Non blocking function called by: Sympa::Mail::get_sendmail_handle() and
main loop of sympa, task_manager, bounced etc.,
just to clean the defuncts list by waiting to any processes and
decrementing the counter.

Parameter:

=over

=item $block

=back

Returns:

PID.

=back

=cut

sub reaper {
    my $self = shift;
    my $block = shift;
    my $i;

    $block = 1 unless defined $block;
    while (($i = waitpid(-1, $block ? POSIX::WNOHANG() : 0)) > 0) {
        $block = 1;
        unless (defined($self->{pids}->{$i})) {
            Log::do_log('debug2', 'Reaper waited %s, unknown process to me',
                $i);
            next;
        }
        $self->{opensmtp}--;
        delete $self->{pids}->{$i};
    }
    Log::do_log(
        'debug2',
        'Reaper unwaited pids: %s Open = %s',
        join(' ', sort keys %{$self->{pids}}), $self->{opensmtp}
    );
    return $i;
}

#DEPRECATED.
#sub sendto;

=over

=item send_message ( $message, $rcpt, [ tag_as_last => 1 )

Sends a message using sendmail or puting it
in bulk spool according to the context.

Shelves signing if needed.

Parameters:

=over

=item $message

L<Sympa::Message> instance, message to be sent.

=item $rcpt

Scalar or arrayref, recipients for SMTP "RCPT To:" field.

=item $message->{envelope_sender}

For SMTP, "MAIL From:" field; for spool, "Return-Path" field.

=back

Returns:

1 if sendmail was called.  0 if pushed in spool.  Otherwise C<undef>.

=back

=cut

# Old name: mail::sending(), Sympa::Mail::sending().
sub send_message {
    my $self = shift;
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

    if ($self->{always_use_bulk}) {
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
        my $pipeout = $self->get_sendmail_handle($message->{envelope_sender}, $rcpt, $robot_id);

        # Send message stripping Return-Path pseudo-header field.
        my $msg_string = $message->as_string;
        $msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;

        print $pipeout $msg_string;
        unless (close $pipeout) {
            Log::do_log('err', 'Could not close safefork to sendmail');
            return undef;
        }
    }
    return 1;
}

=over

=item get_sendmail_handle ( $return_path, $rcpt, $robot, [ $envid ] )

Makes a sendmail ready for the recipients given as argument, uses a file
descriptor in the smtp table which can be imported by other parties.
Before, waits for number of children process < number allowed by sympa.conf

Parameters:

 $return_path :(+) for SMTP "MAIL From:" field
 $rcpt :(+) ref(SCALAR)|ref(ARRAY)- for SMTP "RCPT To:" field
 $robot :(+) robot
 $envid : an ID of this message submission in notification table

Returns:

Filehandle on opened file for ouput, for SMTP "DATA" field.
Otherwise C<undef>.

=back

=cut

# TODO: Split rcpt by max length of command line (_SC_ARG_MAX).
# Old name: mail::smtpto(), Sympa::Mail::smtpto().
sub get_sendmail_handle {
    Log::do_log('debug2', '(%s, %s, %s, %s)', @_);
    my $self = shift;
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

    Log::do_log('debug3', 'Open = %s', $self->{opensmtp});
    while ($self->{opensmtp} > Conf::get_robot_conf($robot, 'maxsmtp')) {
        Log::do_log('debug3', 'Too many open SMTP (%s), calling reaper',
            $self->{opensmtp});
        last if $self->reaper(0) == -1;    # Blocking call to the reaper.
    }

    my ($in, $out);
    unless (pipe $in, $out) {
        die sprintf 'Unable to create a channel in get_sendmail_handle: %s', $ERRNO;
        # No return
    }
    $pid = _safefork();
    $self->{pids}->{$pid} = 0;

    my $sendmail = Conf::get_robot_conf($robot, 'sendmail');
    my @sendmail_args = split /\s+/,
        Conf::get_robot_conf($robot, 'sendmail_args');
    if (defined $envid and length $envid) {
        # Postfix clone of sendmail command doesn't allow spaces between
        # "-V" and envid.
        push @sendmail_args, '-N', 'success,delay,failure', "-V$envid";
    }
    if ($pid == 0) {
        # Child
        close $out;
        open STDIN, '<&', $in;

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

    # Parent
    if ($self->{log_smtp}) {
        my $r;
        if (!ref $rcpt) {
            $r = $rcpt;
        } elsif (ref $rcpt eq 'SCALAR') {
            $r = $$rcpt;
        } else {
            $r = join(' ', @$rcpt);
        }
        Log::do_log(
            'debug3', '%s %s -f \'%s\' -- %s',
            $sendmail, join(' ', @sendmail_args),
            $return_path, $r
        );
    }
    unless (close $in) {
        Log::do_log('err', 'Could not close safefork');
        return undef;
    }
    $self->{opensmtp}++;
    select(undef, undef, undef, 0.3)
        if $self->{opensmtp} < Conf::get_robot_conf($robot, 'maxsmtp');

    return $out;
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
sub _safefork {
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
