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

use Conf;
use Log;

my $max_arg;
eval { $max_arg = POSIX::sysconf(POSIX::_SC_ARG_MAX()); };
if ($EVAL_ERROR) {
    $max_arg = 4096;
}

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {
        pids     => {},
        opensmtp => 0,
        log_smtp => undef,    # SMTP logging is enabled or not
    } => $class;
}

#sub set_send_spool($spool_dir);
#DEPRECATED: No longer used.

#sub mail_file($robot, $filename, $rcpt, $data, $return_message_as_string);
##DEPRECATED: Use Sympa::Message->new_from_template() & send_message().

#sub mail_message($message, $rcpt, [tag_as_last => 1]);
# DEPRECATED: this is now a subroutine of Sympa::List::distribute_msg().

#sub mail_forward($message, $from, $rcpt, $robot);
#DEPRECATED: This is no longer used.

sub reaper {
    my $self  = shift;
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
        join(' ', sort {$a <=> $b} keys %{$self->{pids}}),
        $self->{opensmtp}
    );
    return $i;
}

#DEPRECATED.
#sub sendto;

# DEPRECATED.  Use Sympa::Mailer::store() or Sympa::Bulk::store().
# Old name:
# mail::sending(), Sympa::Mail::sending(), Sympa::Mailer::send_message().
#sub send_message ($self, $message, $rcpt, %params);

sub store {
    my $self    = shift;
    my $message = shift;
    my $rcpt    = shift;
    my %params  = @_;

    my $return_path = $message->{envelope_sender};
    my $envid       = $params{envid};
    my $robot_id;
    if (ref $message->{context} eq 'Sympa::List') {
        $robot_id = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
    } else {
        $robot_id = '*';
    }

    my @all_rcpt;
    unless (ref $rcpt) {
        @all_rcpt = ($rcpt);
    } elsif (ref $rcpt eq 'SCALAR') {
        @all_rcpt = ($$rcpt);
    } elsif (ref $rcpt eq 'ARRAY') {
        @all_rcpt = @$rcpt;
    }

    # Stripping Return-Path: pseudo-header field.
    my $msg_string = $message->as_string;
    $msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;

    my $min_cmd_size =
        length(Conf::get_robot_conf($robot_id, 'sendmail')) + 1 +
        length(Conf::get_robot_conf($robot_id, 'sendmail_args')) +
        length(' -N success,delay,failure -V') + 32 +
        length(" -f $return_path");
    my $numsmtp = 0;
    while (@all_rcpt) {
        # Split rcpt by max length of command line (_SC_ARG_MAX).
        my $cmd_size = $min_cmd_size + 1 + length($all_rcpt[0]);
        my @rcpt = (shift @all_rcpt);
        while (@all_rcpt
            and ($cmd_size += 1 + length($all_rcpt[0])) <= $max_arg) {
            push @rcpt, (shift @all_rcpt);
        }

        my $pipeout = $self->_get_sendmail_handle(
            $return_path, [@rcpt], $robot_id, $envid);
        print $pipeout $msg_string;
        unless (close $pipeout) {
            return undef;
        }
        $numsmtp++;
    }

    return $numsmtp;
}

# Old names: mail::smtpto(), Sympa::Mail::smtpto(),
# Sympa::Mailer::get_sendmail_handle().
# Note: Use store().
sub _get_sendmail_handle {
    Log::do_log('debug2', '(%s, %s, %s, %s)', @_);
    my $self = shift;
    my ($return_path, $rcpt, $robot, $envid) = @_;

    unless ($return_path) {
        Log::do_log('err', 'Missing Return-Path');
    }

    Log::do_log('debug3', '(%s, %s)', $return_path, join(',', @$rcpt));

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
        die sprintf 'Unable to create a SMTP channel: %s', $ERRNO;
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
        exec $sendmail, @sendmail_args, '-f', $return_path, '--', @$rcpt;

        exit 1;    # Should never get there.
    }

    # Parent
    if ($self->{log_smtp}) {
        Log::do_log(
            'debug3', '%s %s -f \'%s\' -- %s',
            $sendmail, join(' ', @sendmail_args),
            $return_path, join(' ', @$rcpt)
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
# Note: Use store().
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
__END__

=encoding utf-8

=head1 NAME

Sympa::Mailer - Store messages to sendmail

=head1 DESCRIPTION

L<Sympa::Mailer> implements the class to invoke sendmail processes and
store messages to them.

=head2 Methods

=over

=item instance ( )

I<Constructor>.
Creates a singleton instance of L<Sympa::Mailer> object.

Returns:

A new L<Sympa::Mailer> instance, or I<undef> for failure.

=item reaper ( [ $block ] )

I<Instance method>.
Non blocking function called by: main loop of sympa, task_manager, bounced
etc., just to clean the defuncts list by waiting to any processes and
decrementing the counter.

Parameter:

=over

=item $block

TBD

=back

Returns:

PID.

=item store ( $message, $rcpt, [ envid =E<gt> $envid ] )

I<Instance method>.
Makes a sendmail ready for the recipients given as argument, uses a file
descriptor in the smtp table which can be imported by other parties.
Before, waits for number of children process < number allowed by sympa.conf

Parameters:

=over

=item $message

Message to be sent.

{envelope_sender} attribute of the message will be used as SMTP "MAIL FROM:"
field.

=item $rcpt

Scalar, scalarref or arrayref, for SMTP "RCPT TO:" field.

=item $envid

An envelope ID of this message submission in notification table.
See also L<Sympa::Tracking>.

=back

Returns:

Filehandle on opened pipe to ouput SMTP "DATA" field.
Otherwise C<undef>.

=back

=head1 SEE ALSO

L<Sympa::Alarm>, L<Sympa::Bulk>, L<Sympa::Message>.

=head1 HISTORY

L<Sympa::Mailer>, the rewrite of mail.pm, appeared on Sympa 6.2.

=cut
