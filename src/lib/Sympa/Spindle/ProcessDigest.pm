# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Spindle::ProcessDigest;

use strict;
use warnings;
use POSIX qw();
use Time::HiRes qw();
use Time::Local qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Spindle::ProcessTemplate;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _distaff    => 'Sympa::Spool::Digest::Collection';
use constant _on_failure => 1;
use constant _on_garbage => 1;
use constant _on_skip    => 1;
use constant _on_success => 1;

sub _twist {
    my $self         = shift;
    my $spool_digest = shift;

    return 0
        unless $self->{send_now}
        or _may_distribute_digest($spool_digest);

    my $list = $spool_digest->{context};

    $language->set_lang(
        $list->{'admin'}{'lang'},
        Conf::get_robot_conf($list->{'domain'}, 'lang'),
        $Conf::Conf{'lang'}, 'en'
    );

    # Blindly send the message to all users.
    $log->syslog('info', 'Sending digest to list %s', $list);
    $self->_distribute_digest($spool_digest);

    $log->syslog(
        'info', 'Digest of the list %s sent (%.2f seconds)',
        $list,  Time::HiRes::time() - $self->{start_time}
    );
    $log->db_log(
        'robot'        => $list->{'domain'},
        'list'         => $list->{'name'},
        'action'       => 'SendDigest',
        'parameters'   => "",
        'target_email' => '',
        'msg_id'       => '',
        'status'       => 'success',
        'error_type'   => '',
        'user_email'   => ''
    );

    # Always succeeds.
    return 1;
}

## Private subroutines.

# Prepare and distribute digest message(s) to the subscribers with
# reception digest, digestplain or summary.
# Old name: List::send_msg_digest(), Sympa::List::distribute_digest().
sub _distribute_digest {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $self         = shift;
    my $spool_digest = shift;

    my $list = $spool_digest->{context};

    my $available_recipients = $list->get_digest_recipients_per_mode;
    unless ($available_recipients) {
        $log->syslog('info', 'No subscriber for sending digest in list %s',
            $list);

        unless ($self->{keep_digest}) {
            while (1) {
                my ($message, $handle) = $spool_digest->next;
                if ($message and $handle) {
                    $spool_digest->remove($handle);
                } elsif ($handle) {
                    $log->syslog('err', 'Cannot parse message <%s>',
                        $handle->basename);
                    $spool_digest->quarantine($handle);
                } else {
                    last;
                }
            }
        }

        return 0;
    }

    my $time = time;

    # Digest index.
    my @all_msg;
    my $i = 0;
    while (1) {
        my ($message, $handle) = $spool_digest->next;
        last unless $handle;    # No more messages.
        unless ($message) {
            $log->syslog('err', 'Cannot parse message <%s>',
                $handle->basename);
            $spool_digest->quarantine($handle);
            next;
        }

        $i++;

        # Commented because one Spam made Sympa die (MIME::tools 5.413)
        #$entity->remove_sig;
        my $msg = {
            'id'         => $i,
            'subject'    => $message->{'decoded_subject'},
            'from'       => $message->get_decoded_header('From'),
            'date'       => $message->get_decoded_header('Date'),
            'full_msg'   => $message->as_string,
            'body'       => $message->body_as_string,
            'plain_body' => $message->get_plaindigest_body,
            #FIXME: Might be extracted from Date:.
            'month'      => POSIX::strftime("%Y-%m", localtime $time),
            'message_id' => $message->{'message_id'},
        };
        push @all_msg, $msg;

        $spool_digest->remove($handle) unless $self->{keep_digest};
    }

    my $param = {
        'replyto'   => Sympa::get_address($list, 'owner'),
        'to'        => Sympa::get_address($list),
    };
    # Compat. to 6.2a or earlier
    $param->{'table_of_content'} = $language->gettext("Table of contents:");

    if ($list->get_reply_to() =~ /^list$/io) {
        $param->{'replyto'} = "$param->{'to'}";
    }

    $param->{'datetime'} =
        $language->gettext_strftime("%a, %d %b %Y %H:%M:%S", localtime $time);
    $param->{'date'} =
        $language->gettext_strftime("%a, %d %b %Y", localtime $time);

    ## Split messages into groups of digest_max_size size
    my @group_of_msg;
    while (@all_msg) {
        my @group = splice @all_msg, 0, $list->{'admin'}{'digest_max_size'};
        push @group_of_msg, \@group;
    }

    $param->{'current_group'} = 0;
    $param->{'total_group'}   = scalar @group_of_msg;
    ## Foreach set of digest_max_size messages...
    foreach my $group (@group_of_msg) {
        $param->{'current_group'}++;
        $param->{'msg_list'}       = $group;
        $param->{'auto_submitted'} = 'auto-generated';

        # Prepare and send MIME digest, plain digest and summary.
        foreach my $mode (qw{digest digestplain summary}) {
            next unless exists $available_recipients->{$mode};

            my $spindle = Sympa::Spindle::ProcessTemplate->new(
                context  => $list,
                template => $mode,
                rcpt     => $available_recipients->{$mode},
                data     => $param,

                splicing_to => [
                    'Sympa::Spindle::TransformDigestFinal',
                    'Sympa::Spindle::ToOutgoing'
                ],
                add_list_statistics => 1
            );
            unless ($spindle
                and $spindle->spin
                and $spindle->{finish} eq 'success') {
                $log->syslog('notice',
                    'Unable to send template "%s" to %s list subscribers',
                    $mode, $list);
                next;
            }
        }
    }

    return 1;
}

# Returns 1 if the  digest must be sent.
# Old name: Sympa::List::get_nextdigest(),
# Sympa::List::may_distribute_digest().
sub _may_distribute_digest {
    $log->syslog('debug3', '(%s)', @_);
    my $spool_digest = shift;

    my $list = $spool_digest->{context};

    return undef unless defined $spool_digest->{time};
    return undef unless $list->is_digest;

    my @days = @{$list->{'admin'}{'digest'}->{'days'} || []};
    my $hh = $list->{'admin'}{'digest'}->{'hour'}   || 0;
    my $mm = $list->{'admin'}{'digest'}->{'minute'} || 0;

    my @now        = localtime time;
    my $today      = $now[6];                           # current day
    my @timedigest = localtime $spool_digest->{time};

    ## Should we send a digest today
    my $send_digest = 0;
    foreach my $d (@days) {
        if ($d == $today) {
            $send_digest = 1;
            last;
        }
    }
    return undef unless $send_digest;

    if ($hh * 60 + $mm <= $now[2] * 60 + $now[1]
        and Time::Local::timelocal(0, @timedigest[1 .. 5]) <
        Time::Local::timelocal(0, $mm, $hh, @now[3 .. 5])) {
        return 1;
    }

    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessDigest - Workflow of digest sending

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessDigest;

  my $spindle = Sympa::Spindle::ProcessDigest->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessDigest> defines workflow to distribute digest
messages.

When spin() method is invoked, messages kept in digest spool of each list are
compiled into digest messages (MIME digest, plain text digest or summary) and
stored into outgoing spool.
Lists not reaching the time to distribute digest are omitted.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( [ send_now =E<gt> 1 ], [ keep_digest =E<gt> 1 ] )

=item spin ( )

If C<send_now> is set, spin() stores digests of all lists keeping unsent
digests into outgoing spool, including the lists not reaching time to
distribute.
If C<keep_digest> is set, won't remove compiled messages from digest spool.

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Digest::Collection> class.

=back

=head1 SEE ALSO

L<Sympa::Spindle>,
L<Sympa::Spool::Digest>, L<Sympa::Spool::Digest::Collection>.

=head1 HISTORY

L<Sympa::Spindle::SendDigest> appeared on Sympa 6.2.10.
It was renamed to L<Sympa::Spindle::ProcessDigest> on Sympa 6.2.13.

=cut
