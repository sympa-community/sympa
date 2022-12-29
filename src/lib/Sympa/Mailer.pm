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

package Sympa::Mailer;

use strict;
use warnings;
use base qw(Class::Singleton);

use English qw(-no_match_vars);
use POSIX qw();

use Conf;
use Sympa::Log;
use Sympa::Process;

my $log     = Sympa::Log->instance;
my $process = Sympa::Process->instance;

my $max_arg;
eval { $max_arg = POSIX::sysconf(POSIX::_SC_ARG_MAX()); };
if ($EVAL_ERROR) {
    $max_arg = 4096;
}

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {
        _pids      => {},
        redundancy => 1,        # Process redundancy (used by bulk.pl).
        log_smtp   => undef,    # SMTP logging is enabled or not.
    } => $class;
}

#sub set_send_spool($spool_dir);
#DEPRECATED: No longer used.

#sub mail_file($robot, $filename, $rcpt, $data, $return_message_as_string);
##DEPRECATED: Use Sympa::Message::Template::new() & send_message().

#sub mail_message($message, $rcpt, [tag_as_last => 1]);
# DEPRECATED: this is now a subroutine of Sympa::List::distribute_msg().

#sub mail_forward($message, $from, $rcpt, $robot);
#DEPRECATED: This is no longer used.

# DEPRECATED.  Use Sympa::Process::reap_child().
#sub reaper;

#DEPRECATED.
#sub sendto;

# DEPRECATED.  Use Sympa::Mailer::store() or Sympa::Spool::Outgoing::store().
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
    my $tag         = $params{tag};
    my $logging = (not defined $tag or $tag eq 's' or $tag eq 'z') ? 1 : 0;

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

    my $sendmail = $Conf::Conf{'sendmail'};
    my @sendmail_args = split /\s+/, $Conf::Conf{'sendmail_args'};
    if (defined $envid and length $envid) {
        # Postfix clone of sendmail command doesn't allow spaces between
        # "-V" and envid.
        # And as it denys "-V" with 2 characters, "0" are padded.
        push @sendmail_args, '-N', 'success,delay,failure',
            sprintf('-V%08s', $envid);
    }
    my $min_cmd_size =
        length($sendmail) + 1 +
        length(join ' ', @sendmail_args) + 1 +
        length("-f $return_path --");
    my $maxsmtp =
        int($Conf::Conf{'maxsmtp'} / ($self->{redundancy} || 1)) || 1;

    # Ignore SIGPIPE which may occur at the time of close().
    local $SIG{PIPE} = 'IGNORE';

    my $numsmtp = 0;
    while (@all_rcpt) {
        # Split rcpt by max length of command line (_SC_ARG_MAX).
        my $cmd_size = $min_cmd_size + 1 + length($all_rcpt[0]);
        my @rcpt     = (shift @all_rcpt);
        while (@all_rcpt
            and ($cmd_size += 1 + length($all_rcpt[0])) <= $max_arg) {
            push @rcpt, (shift @all_rcpt);
        }

        # Get sendmail handle.

        unless ($return_path) {
            $log->syslog('err', 'Missing Return-Path');
        }

        # Check how many open smtp's we have, if too many wait for a few
        # to terminate and then do our job.
        $process->sync_child(hash => $self->{_pids});
        $log->syslog('debug3', 'Open = %s', scalar keys %{$self->{_pids}});
        while ($maxsmtp < scalar keys %{$self->{_pids}}) {
            $log->syslog(
                'info',
                'Too many open SMTP (%s), calling reaper',
                scalar keys %{$self->{_pids}}
            );
            # Blockng call to the reaper.
            last if $process->wait_child < 0;
            $process->sync_child(hash => $self->{_pids});
        }

        my ($pipein, $pipeout, $pid);
        unless (pipe $pipein, $pipeout) {
            die sprintf 'Unable to create a SMTP channel: %s', $ERRNO;
            # No return
        }
        $pid = _safefork($message->get_id);
        $self->{_pids}->{$pid} = 1;

        unless ($pid) {    # _safefork() would die if fork() had failed.
            # Child
            close $pipeout;
            open STDIN, '<&', $pipein;

            # The '<>' means null sender.
            # Terminate options by "--" to prevent addresses beginning with "-"
            # being treated as options.
            exec $sendmail, @sendmail_args, '-f',
                ($return_path eq '<>' ? '' : $return_path), '--', @rcpt;

            exit 1;    # Should never get there.
        } else {
            # Parent
            if ($self->{log_smtp}) {
                $log->syslog(
                    'notice',
                    'Forked process %d: %s %s -f \'%s\' -- %s',
                    $pid,
                    $sendmail,
                    join(' ', @sendmail_args),
                    $return_path,
                    join(' ', @rcpt)
                );
            }
            unless (close $pipein) {
                $log->syslog('err', 'Could not close forked process %d',
                    $pid);
                return undef;
            }
            select undef, undef, undef, 0.3
                if scalar keys %{$self->{_pids}} < $maxsmtp;
        }

        # Output to handle.

        print $pipeout $msg_string;
        unless (close $pipeout) {
            $log->syslog('err', 'Failed to close pipe to process %d: %m',
                $pid);
            return undef;
        }
        $numsmtp++;
    }

    if ($logging) {
        $log->syslog(
            'notice',
            'Done sending message %s for %s (priority %s) in %s seconds since scheduled expedition date',
            $message,
            $message->{context},
            $message->{'priority'},
            time() - $message->{'date'}
        );
    }

    return $numsmtp;
}

# Old names: mail::smtpto(), Sympa::Mail::smtpto(),
# Sympa::Mailer::get_sendmail_handle().
# DEPRECATED: Merged into store().
#sub _get_sendmail_handle;

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
    my $tag = shift;

    my $err;
    for (my $i = 1; $i < 4; $i++) {
        my $pid = $process->fork($tag);
        return $pid if defined $pid;

        $err = $ERRNO;
        $log->syslog('err', 'Cannot create new process: %s', $err);
        #FIXME:should send a mail to the listmaster
        sleep(10 * $i);
    }
    die sprintf 'Exiting because cannot create new process for <%s>: %s',
        $tag, $err;
    # No return.
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Mailer - Store messages to sendmail

=head1 SYNOPSIS

  use Sympa::Mailer;
  use Sympa::Process;
  my $mailer = Sympa::Mailer->instance;
  my $process = Sympa::Process->instance;

  $mailer->store($message, ['user1@dom.ain', user2@other.dom.ain']);

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

=item reaper ( [ blocking =E<gt> 1 ] )

DEPRECATED.
Use L<Sympa::Process/"reap_child">.

I<Instance method>.
Non blocking function called by: main loop of sympa, task_manager, bounced
etc., just to clean the defuncts list by waiting to any processes and
decrementing the counter.

Parameter:

=over

=item blocking =E<gt> 1

Operation would block.

=back

Returns:

PID.

=item store ( $message, $rcpt,
[ envid =E<gt> $envid ], [ tag =E<gt> $tag ] )

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

=item envid =E<gt> $envid

An envelope ID of this message submission in notification table.
See also L<Sympa::Tracking>.

=item tag =E<gt> $tag

TBD

=back

Returns:

Filehandle on opened pipe to output SMTP "DATA" field.
Otherwise C<undef>.

=back

=head2 Attributes

L<Sympa::Mailer> instance may have following attributes:

=over

=item {log_smtp}

If true value is set, each invocation of sendmail process will be logged.

=item {redundancy}

Positive integer.
If set, maximum number of invocation of sendmail is divided by this value.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Process>,
L<Sympa::Spool::Listmaster>, L<Sympa::Spool::Outgoing>.

=head1 HISTORY

L<Sympa::Mailer>, the rewrite of mail.pm, appeared on Sympa 6.2.

=cut
