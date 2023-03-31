# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020, 2021 The Sympa Community. See the
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

package Sympa::Spindle::ToList;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Log;
use Sympa::Spool::Outgoing;
use Sympa::Spool::Topic;
use Sympa::Tools::Data;
use Sympa::Tracking;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list      = $message->{context};
    my $messageid = $message->{message_id};
    my $sender =
           $self->{confirmed_by}
        || $self->{distributed_by}
        || $self->{resent_by}
        || $message->{sender};

    my $numstored = _send_msg($message, $self->{resent_by});
    unless (defined $numstored) {
        $log->syslog('err', 'Unable to send message %s to list %s',
            $message, $list);
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error  => '',
                who    => $sender,
                msg_id => $messageid,
            }
        );
        Sympa::send_dsn($list, $message, {}, '5.3.0');
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    } elsif (not $self->{quiet}) {
        if ($self->{confirmed_by}) {
            # Ensure 1 second elapsed since last message.
            Sympa::send_file(
                $list,
                'message_report',
                $self->{confirmed_by},
                {   type           => 'success',             # Compat<=6.2.12.
                    entry          => 'message_confirmed',
                    auto_submitted => 'auto-replied',
                    key            => $self->{authkey}
                },
                date => time + 1
            );
        } elsif ($self->{distributed_by}) {
            # Ensure 1 second elapsed since last message.
            Sympa::send_file(
                $list,
                'message_report',
                $self->{distributed_by},
                {   type           => 'success',             # Compat<=6.2.12.
                    entry          => 'message_distributed',
                    auto_submitted => 'auto-replied',
                    key            => $self->{authkey}
                },
                date => time + 1
            );
        }
        # No notification sent to {resent_by} user.
    }

    $log->syslog(
        'info',
        'Message %s for %s from %s accepted (%.2f seconds, %d sessions, %d subscribers), message ID=%s, size=%d',
        $message,
        $list,
        $sender,
        Time::HiRes::time() - $self->{start_time},
        $numstored,
        $list->get_total,
        $messageid,
        $message->{'size'}
    );
    $log->db_log(
        'robot'        => $list->{'domain'},
        'list'         => $list->{'name'},
        'action'       => 'DoMessage',
        'parameters'   => $message->get_id,
        'target_email' => '',
        'msg_id'       => $messageid,
        'status'       => 'success',
        'error_type'   => '',
        'user_email'   => $sender
    );

    return 1;
}

# Private subroutines.

# Extract a set of rcpt for which VERP must be use from a rcpt_tab.
# Input  :  percent : the rate of subscribers that must be threaded using VERP
#           xseq    : the message sequence number
#           @rcpt   : a tab of emails
# return :  a tab of recipients for which recipients must be used depending on
#           the message sequence number, this way every subscriber is "VERPed"
#           from time to time input table @rcpt is spliced: recipients for
#           which VERP must be used are extracted from this table
# Old name: List::extract_verp_rcpt(), Sympa::List::_extract_verp_rcpt().
sub _extract_verp_rcpt {
    $log->syslog('debug3', '(%s, %s, %s, %s)', @_);
    my $percent     = shift;
    my $xsequence   = shift;
    my $refrcpt     = shift;
    my $refrcptverp = shift;

    my @result;

    if ($percent ne '0%') {
        my $nbpart;
        if ($percent =~ /^(\d+)\%/) {
            $nbpart = 100 / $1;
        } else {
            $log->syslog('err',
                'Wrong format for parameter: %s. Can\'t process VERP',
                $percent);
            return undef;
        }

        my $modulo = $xsequence % $nbpart;
        my $length = int(scalar(@$refrcpt) / $nbpart) + 1;

        @result = splice @$refrcpt, $length * $modulo, $length;
    }
    foreach my $verprcpt (@$refrcptverp) {
        push @result, $verprcpt;
    }
    return (@result);
}

# Old names: List::send_msg(), (part of) Sympa::List::distribute_msg().
sub _send_msg {
    my $message   = shift;
    my $resent_by = shift;

    my $list = $message->{context};

    my $verp_rate;
    my $tags_to_use;
    my $available_recipients;
    unless ($resent_by) {    # Not in ResendArchive spindle.
        # Synchronize list members, required if list uses include sources
        # unless sync_include has been performed recently.
        my $delay = $list->{'admin'}{'distribution_ttl'}
            // $list->{'admin'}{'ttl'};
        unless (defined $list->sync_include('member', delay => $delay)) {
            $log->syslog('notice', 'Unable to synchronize list %s', $list);
            #FIXME: Might be better to abort if synchronization failed.
        }

        # Blindly send the message to all users.

        my $total = $list->get_total('nocache');
        unless ($total and 0 < $total) {
            $log->syslog('info', 'No subscriber in list %s', $list);
            return 0;
        }

        # Postpone delivery if delivery time is specified.
        my $delivery_date = $list->get_next_delivery_date;
        $message->{date} = $delivery_date if defined $delivery_date;

        # Bounce rate.
        my $rate = $list->get_total_bouncing() * 100 / $total;
        if ($rate > $list->{'admin'}{'bounce'}{'warn_rate'}) {
            $list->send_notify_to_owner('bounce_rate', {'rate' => $rate});
            if (100 <= $rate) {
                Sympa::send_notify_to_user($list, 'hundred_percent_error',
                    $message->{sender});
                Sympa::send_notify_to_listmaster($list,
                    'hundred_percent_error', {sender => $message->{sender}});
            }
        }

        # Prepare verp parameter.
        $verp_rate = $list->{'admin'}{'verp_rate'};
        # Force VERP if tracking is requested.
        $verp_rate = '100%'
            if Sympa::Tools::Data::smart_eq($message->{shelved}{tracking},
            qr/dsn|mdn/);

        # Define messages which can be tagged as first or last according to the
        # VERP rate.
        # If the VERP is 100%, then all the messages are VERP. Don't try to tag
        # not VERP messages as they won't even exist.
        if ($verp_rate eq '0%') {
            $tags_to_use = {tag_verp => '0', tag_noverp => 'z'};
        } else {
            $tags_to_use = {tag_verp => 'z', tag_noverp => '0'};
        }

        # Separate subscribers depending on user reception option and also if
        # VERP a dicovered some bounce for them.
        # Storing the not empty subscribers' arrays into a hash.
        $available_recipients = $list->get_recipients_per_mode($message);
        unless ($available_recipients) {
            $log->syslog('info', 'No subscriber for sending msg in list %s',
                $list);
            return 0;
        }
    } else {
        $verp_rate            = '0%';
        $tags_to_use          = {tag_verp => '0', tag_noverp => 'z',};
        $available_recipients = {mail => {noverp => [$resent_by]}};
    }

    my $numstored = 0;

    foreach my $mode (sort keys %$available_recipients) {
        # Save the message before modifying it.
        my $new_message = $message->dup;
        unless ($new_message->prepare_message_according_to_mode($mode, $list))
        {
            $log->syslog('err', "Failed to create Message object");
            return undef;
        }

        # Topics.
        my @selected_tabrcpt;
        my @possible_verptabrcpt;
        if (not $resent_by    # Not in ResendArchive spindle.
            and $list->is_there_msg_topic
        ) {
            my $topic = Sympa::Spool::Topic->load($message);
            my $topic_list = $topic ? $topic->{topic} : '';

            @selected_tabrcpt =
                $list->select_list_members_for_topic($topic_list,
                $available_recipients->{$mode}{'noverp'} || []);
            @possible_verptabrcpt =
                $list->select_list_members_for_topic($topic_list,
                $available_recipients->{$mode}{'verp'} || []);
        } else {
            @selected_tabrcpt =
                @{$available_recipients->{$mode}{'noverp'} || []};
            @possible_verptabrcpt =
                @{$available_recipients->{$mode}{'verp'} || []};
        }

        ## Preparing VERP recipients.
        my @verp_selected_tabrcpt = _extract_verp_rcpt(
            $verp_rate,         $message->{xsequence},
            \@selected_tabrcpt, \@possible_verptabrcpt
        );

        # Prepare non-VERP sending.
        if (@selected_tabrcpt) {
            my $result =
                _mail_message($new_message, \@selected_tabrcpt,
                tag => $tags_to_use->{'tag_noverp'});
            unless (defined $result) {
                $log->syslog(
                    'err',
                    'Could not send message to distribute to list %s (VERP disabled)',
                    $list
                );
                return undef;
            }
            $tags_to_use->{'tag_noverp'} = '0' if $result;
            $numstored += $result->{total_packets};

            # Add number and size of messages sent to total in stats file.
            my $numsent = scalar @selected_tabrcpt;
            my $bytes   = length $new_message->as_string;
            $list->update_stats(0, $numsent, $bytes, $bytes * $numsent);
        } else {
            $log->syslog(
                'notice',
                'No non VERP subscribers left to distribute message to list %s',
                $list
            );
        }

        $new_message->{shelved}{tracking} ||= 'verp';

        if ($new_message->{shelved}{tracking} =~ /dsn|mdn/) {
            my $tracking = Sympa::Tracking->new(context => $list);

            $tracking->register($new_message, [@verp_selected_tabrcpt],
                'reception_option' => $mode);
        }

        # Ignore those reception option where mail must not ne sent.
        next
            if $mode eq 'digest'
            or $mode eq 'digestplain'
            or $mode eq 'summary'
            or $mode eq 'nomail';

        ## prepare VERP sending.
        if (@verp_selected_tabrcpt) {
            my $result =
                _mail_message($new_message, \@verp_selected_tabrcpt,
                tag => $tags_to_use->{'tag_verp'});
            unless (defined $result) {
                $log->syslog(
                    'err',
                    'Could not send message to distribute to list %s (VERP enabled)',
                    $list
                );
                return undef;
            }
            $tags_to_use->{'tag_verp'} = '0' if $result;
            $numstored += $result->{total_packets};

            # Add number and size of messages sent to total in stats file.
            my $numsent = scalar @verp_selected_tabrcpt;
            my $bytes   = length $new_message->as_string;
            $list->update_stats(0, $numsent, $bytes, $bytes * $numsent);
        } else {
            $log->syslog('notice',
                'No VERP subscribers left to distribute message to list %s',
                $list);
        }
    }

    #log in stat_table to make statistics...
    unless ($message->{sender} =~ /($Conf::Conf{'email'})\@/) {
        #ignore messages sent by robot
        unless ($message->{sender} =~ /($list->{name})-request/) {
            #ignore messages of requests
            $log->add_stat(
                'robot'     => $list->{'domain'},
                'list'      => $list->{'name'},
                'operation' => 'send_mail',
                'parameter' => $message->{size},
                'mail'      => $message->{sender},
            );
        }
    }
    return $numstored;
}

# Distribute a message to a list, shelving encryption if needed.
#
# IN : -$message(+) : ref(Sympa::Message)
#      -\@rcpt(+) : recipients
# Returns: Marshalled metadata (file name) or undef
#
# Old name: Sympa::Mail::mail_message(), Sympa::List::_mail_message().
sub _mail_message {
    $log->syslog('debug2', '(%s, %s, %s => %s)', @_);
    my $message = shift;
    my $rcpt    = shift;
    my %params  = @_;

    my $tag = $params{tag};

    my $list = $message->{context};

    # Shelve DMARC protection, unless anonymization feature is enabled.
    $message->{shelved}{dmarc_protect} = 1
        if $list->{'admin'}{'dmarc_protection'}
        and $list->{'admin'}{'dmarc_protection'}{'mode'}
        and not $list->{'admin'}{'anonymous_sender'};

    # Shelve personalization if not yet shelved.
    # Note that only 'footer' mode will be allowed unless otherwise requested.
    $message->shelve_personalization(type => 'mail')
        unless $message->{shelved}{merge};

    # Shelve re-encryption with S/MIME.
    $message->{shelved}{smime_encrypt} = 1
        if $message->{'smime_crypted'};

    # Overwrite original envelope sender.  It is REQUIRED for delivery.
    $message->{envelope_sender} = Sympa::get_address($list, 'return_path');

    return Sympa::Spool::Outgoing->new->store($message, $rcpt, tag => $tag)
        || undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToList - Process to distribute messages to list members

=head1 DESCRIPTION

This class executes the last stage of message transformation to be sent
through the list.
Transformation processes by this class are done in the following order:

=over

=item *

Classifies recipients for whom message is delivered by each reception mode,
filters recipients by topics (see also L<Sympa::Spool::Topic>), and choose
message tracking modes if necessary.

=item *

Transforms message by each reception mode.

=item *

Enables DMARC protection (according to
L<C<dmarc_protection>|sympa_config(5)/dmarc_protection>
list configuration parameter),
message personalization (according to
L<C<personalization_feature>|sympa_config(5)/personalization_feature>
list configuration parameter) and/or
re-encryption by S/MIME (if original message was encrypted).

=item *

Alters envelope sender of the message to I<list>C<-owner> address.

=back

Then stores message into outgoing spool (see L<Sympa::Spool::Outgoing>)
with classified packets of recipients.

This class updates statistics information of the list (with digest delivery,
L<Sympa::Spindle::ToOutgoing> will update it).


=head1 SEE ALSO

L<Sympa::Internals::Workflow>.

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spool::Outgoing>,
L<Sympa::Spool::Topic>, L<Sympa::Tracking>.

=head1 HISTORY

L<Sympa::Spindle::ToList> appeared on Sympa 6.2.13.

=cut
