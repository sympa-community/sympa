# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019, 2022 The Sympa Community. See the
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

package Sympa::Spool::Topic;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Constants;
use Sympa::Log;
use Sympa::Tools::File;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

sub new {
    my $class   = shift;
    my %options = @_;

    bless {%options} => $class;
}

# Old name: Sympa::List::tag_topic().
sub store {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self    = shift;
    my $message = shift;

    $self->_create;

    my $topic_list = $self->{topic};
    my $method     = $self->{method};

    my $msg_id = ($message->{message_id} =~ s/\A<(.*)>\z/$1/r);
    my $list   = $message->{context};
    return undef unless $msg_id and ref $list eq 'Sympa::List';

    my $queuetopic = $Conf::Conf{'queuetopic'};

    # Message ID can contain hostile "/".  Escape it.
    my $file = sprintf '%s.%s', $list->get_id,
        Sympa::Tools::Text::encode_filesystem_safe($msg_id);

    my $fh;
    unless (open $fh, '>', $queuetopic . '/' . $file) {
        $log->syslog('info', 'Unable to create msg topic file %s/%s: %s',
            $queuetopic, $file, $!);
        return undef;
    }

    print $fh "TOPIC   $topic_list\n";
    print $fh "METHOD  $method\n";

    close $fh;

    return $queuetopic . '/' . $file;
}

sub _create {
    my $self = shift;

    my $spool_dir = $Conf::Conf{'queuetopic'};
    unless (-d $spool_dir) {
        my $umask = umask oct $Conf::Conf{'umask'};

        $log->syslog('info', 'Creating directory %s of %s', $spool_dir,
            $self);
        unless (mkdir $spool_dir, 0775 or -d $spool_dir) {
            die sprintf 'Cannot create %s: %s', $spool_dir, $ERRNO;
        }
        unless (
            Sympa::Tools::File::set_file_rights(
                file  => $spool_dir,
                user  => Sympa::Constants::USER(),
                group => Sympa::Constants::GROUP()
            )
        ) {
            die sprintf 'Cannot create %s: %s', $spool_dir, $ERRNO;
        }

        umask $umask;
    }
}

# Old name: Sympa::List::load_msg_topic_file().
sub load {
    $log->syslog('debug2', '(%s, %s, %s => %s)', @_);
    my $class   = shift;
    my $message = shift;
    my %options = @_;

    my $msg_id =
        $options{in_reply_to}
        ? Sympa::Tools::Text::canonic_message_id(
        $message->get_header('In-Reply-To'))
        : $message->{message_id};
    my $list = $message->{context};
    return undef unless $msg_id and ref $list eq 'Sympa::List';

    my $queuetopic = $Conf::Conf{'queuetopic'};

    # Message ID can contain hostile "/".  Escape it.
    my $file = sprintf '%s.%s', $list->get_id,
        Sympa::Tools::Text::encode_filesystem_safe($msg_id);

    my $fh;
    unless (open $fh, '<', $queuetopic . '/' . $file) {
        $log->syslog('debug', 'No topic defined; unable to open %s/%s: %m',
            $queuetopic, $file);
        return undef;
    }

    my %info = ();

    while (my $line = <$fh>) {
        next if $line =~ /\A\s*#/ or $line !~ /\S/;

        if ($line =~ /^(\S+)\s+(.+)$/io) {
            my ($keyword, $value) = ($1, $2);
            $value =~ s/\s*$//;

            if ($keyword eq 'TOPIC') {
                $info{'topic'} = $value;
            } elsif ($keyword eq 'METHOD') {
                if ($value =~ /^(editor|sender|auto)$/) {
                    $info{'method'} = $value;
                } else {
                    $log->syslog('err', 'Syntax error in file %s/%s: %s',
                        $queuetopic, $file, $line);
                    return undef;
                }
            }
        }
    }
    close $fh;

    if (exists $info{'topic'} and exists $info{'method'}) {
        $info{'msg_id'}   = $msg_id;
        $info{'filename'} = $file;

        return $class->new(%info);
    }
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Topic - Message topic

=head1 SYNOPSIS

  use Sympa::Spool::Topic;
  
  $topic = Sympa::Spool::Topic->new(topic => $topics, method => 'auto');
  $topic->store($message);
  
  $topic = Sympa::Spool::Topic->load($message);

=head1 DESCRIPTION

TBD.

=head2 Methods

=over

=item new ( options... )

I<Constructor>.
Creates new instance of L<Sympa::Spool::Topic>.

=item load ( $message, [ in_reply_to =E<gt> 1 ] )

I<Constructor>.
Looks for a msg topic file from the message_id of
the message, loads it and return contained information
as hash items.

Parameters:

=over

=item $message

L<Sympa::Message> instance to be looked for.

=item in_reply_to =E<gt> 1

Use value of C<In-Reply-To:> field instead of message ID.

=back

Returns:

Instance of L<Sympa::Spool::Topic> or, if topic was not found, C<undef>.

=item store ( $message )

I<Instance method>.
Tag the message by creating the msg topic file.

Parameter:

=over

=item $message

Message to be tagged.

=back

Returns:

Message topic filename or C<undef>.

=back

=head1 CONFIGURATION PARAMETERS

=over

=item queuetopic

Directory path where topic files are stored.

Note:
Though it is neither queue nor spool, named such by historical reason.

=item umask

The umask to make directory.

=back

=head1 CAVEAT

L<Sympa::Spool::Topic> is not a real subsclass of L<Sympa::Spool>.

=head1 HISTORY

Feature to handle message topics was introduced on Sympa 5.2b.

L<Sympa::Topic> module appeared on Sympa 6.2.10.
It was renamed to L<Sympa::Spool::Topic> on Sympa 6.2.45b.3.

=cut
