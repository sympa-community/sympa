# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Spindle::DistributeMessage;

use strict;
use warnings;
use Encode qw();
use English;    # FIXME: drop $POSTMATCH usage
use MIME::EncWords;
use Time::HiRes qw();

use Sympa;
use Sympa::Bulk;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Message::Plugin;
use Sympa::Regexps;
use Sympa::Spool::Archive;
use Sympa::Spool::Digest;
use Sympa::Template;
use tools;
use Sympa::Tools::Data;
use Sympa::Topic;
use Sympa::Tracking;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# prepares and distributes a message to a list, do
# some of these :
# stats, hidding sender, adding custom subject,
# archive, changing the replyto, removing headers,
# adding headers, storing message in digest
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list      = $message->{context};
    my $messageid = $message->{message_id};
    my $sender =
           $self->{confirmed_by}
        || $self->{distributed_by}
        || $message->{sender};

    my $numsmtp = _distribute_msg($message);
    unless (defined $numsmtp) {
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
            Sympa::Report::notice_report_msg('message_confirmed', $sender,
                {'key' => $self->{authkey}, 'message' => $message},
                $list->{'domain'}, $list);
        } elsif ($self->{distributed_by}) {
            Sympa::Report::notice_report_msg('message_distributed', $sender,
                {'key' => $self->{authkey}, 'message' => $message},
                $list->{'domain'}, $list);
        }
    }

    $log->syslog(
        'info',
        'Message %s for %s from %s accepted (%.2f seconds, %d sessions, %d subscribers), message ID=%s, size=%d',
        $message,
        $list,
        $sender,
        Time::HiRes::time() - $self->{start_time},
        $numsmtp,
        $list->get_total,
        $messageid,
        $message->{'size'}
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

# Old name: Sympa::List::distribute_msg().
# Note: List::send_msg() has been merged to this method.
sub _distribute_msg {
    my $message = shift;

    Sympa::Message::Plugin::execute('pre_distribute', $message);

    my $list = $message->{context};

    my $robot = $list->{'domain'};

    # Update msg_count, and returns the new X-Sequence, if any.
    $message->{xsequence} = $list->get_next_sequence;

    ## Loading info msg_topic file if exists, add X-Sympa-Topic
    my $topic;
    if ($list->is_there_msg_topic) {
        $topic = Sympa::Topic->load($message);
    }
    if ($topic) {
        # Add X-Sympa-Topic: header.
        $message->add_header('X-Sympa-Topic', $topic->{topic});
    }

    # Hide the sender if the list is anonymized
    if ($list->{'admin'}{'anonymous_sender'}) {
        foreach my $field (@{$Conf::Conf{'anonymous_header_fields'}}) {
            $message->delete_header($field);
        }

        # override From: and Message-ID: fields.
        # Note that corresponding Resent-*: fields will be removed.
        $message->replace_header('From',
            $list->{'admin'}{'anonymous_sender'});
        $message->delete_header('Resent-From');
        my $new_id =
            $list->{'name'} . '.' . $message->{xsequence} . '@anonymous';
        $message->replace_header('Message-Id', "<$new_id>");
        $message->delete_header('Resent-Message-Id');

        # Duplicate topic file by new message ID.
        if ($topic) {
            $topic->store({context => $list, message_id => $new_id});
        }

        ## Virer eventuelle signature S/MIME
    }

    # Add Custom Subject

    my $parsed_tag;
    if ($list->{'admin'}{'custom_subject'}) {
        my $custom_subject = $list->{'admin'}{'custom_subject'};

        # Check if custom_subject parameter is parsable.
        my $data = {
            list => {
                name     => $list->{'name'},
                sequence => $message->{xsequence},
            },
        };
        my $template = Sympa::Template->new(undef);
        unless ($template->parse($data, [$custom_subject], \$parsed_tag)) {
            $log->syslog('err', 'Can\'t parse custom_subject of list %s: %s',
                $list, $template->{last_error});

            undef $parsed_tag;
        }
    }
    if ($list->{'admin'}{'custom_subject'} and defined $parsed_tag) {
        my $subject_field = $message->{'decoded_subject'};
        $subject_field = '' unless defined $subject_field;
        ## Remove leading and trailing blanks
        $subject_field =~ s/^\s*(.*)\s*$/$1/;

        ## Search previous subject tagging in Subject
        my $custom_subject = $list->{'admin'}{'custom_subject'};

        ## tag_regexp will be used to remove the custom subject if it is
        ## already present in the message subject.
        ## Remember that the value of custom_subject can be
        ## "dude number [%list.sequence"%]" whereas the actual subject will
        ## contain "dude number 42".
        my $list_name_escaped = $list->{'name'};
        $list_name_escaped =~ s/(\W)/\\$1/g;
        my $tag_regexp = $custom_subject;
        ## cleanup, just in case dangerous chars were left
        $tag_regexp =~ s/([^\w\s\x80-\xFF])/\\$1/g;
        ## Replaces "[%list.sequence%]" by "\d+"
        $tag_regexp =~ s/\\\[\\\%\s*list\\\.sequence\s*\\\%\\\]/\\d+/g;
        ## Replace "[%list.name%]" by escaped list name
        $tag_regexp =~
            s/\\\[\\\%\s*list\\\.name\s*\\\%\\\]/$list_name_escaped/g;
        ## Replaces variables declarations by "[^\]]+"
        $tag_regexp =~ s/\\\[\\\%\s*[^]]+\s*\\\%\\\]/[^]]+/g;
        ## Takes spaces into account
        $tag_regexp =~ s/\s+/\\s+/g;

        # Add subject tag

        ## If subject is tagged, replace it with new tag
        ## Splitting the subject in two parts :
        ##   - what will be before the custom subject (probably some "Re:")
        ##   - what will be after it : the original subject sent to the list.
        ## The custom subject is not kept.
        my $before_tag;
        my $after_tag;
        if ($custom_subject =~ /\S/) {
            $subject_field =~ s/\s*\[$tag_regexp\]\s*/ /;
        }
        $subject_field =~ s/\s+$//;

        # truncate multiple "Re:" and equivalents.
        my $re_regexp = Sympa::Regexps::re();
        if ($subject_field =~ /^\s*($re_regexp\s*)($re_regexp\s*)*/) {
            ($before_tag, $after_tag) = ($1, $POSTMATCH);
        } else {
            ($before_tag, $after_tag) = ('', $subject_field);
        }

        ## Encode subject using initial charset

        ## Don't try to encode the subject if it was not originally encoded.
        if ($message->{'subject_charset'}) {
            $subject_field = MIME::EncWords::encode_mimewords(
                Encode::decode_utf8(
                    $before_tag . '[' . $parsed_tag . '] ' . $after_tag
                ),
                Charset     => $message->{'subject_charset'},
                Encoding    => 'A',
                Field       => 'Subject',
                Replacement => 'FALLBACK'
            );
        } else {
            $subject_field =
                $before_tag . ' '
                . MIME::EncWords::encode_mimewords(
                Encode::decode_utf8('[' . $parsed_tag . ']'),
                Charset  => tools::lang2charset($language->get_lang),
                Encoding => 'A',
                Field    => 'Subject'
                )
                . ' '
                . $after_tag;
        }

        $message->delete_header('Subject');
        $message->add_header('Subject', $subject_field);
    }

    ## Prepare tracking if list config allow it
    my @apply_tracking = ();

    push @apply_tracking, 'dsn'
        if Sympa::Tools::Data::smart_eq(
        $list->{'admin'}{'tracking'}->{'delivery_status_notification'}, 'on');
    push @apply_tracking, 'mdn'
        if Sympa::Tools::Data::smart_eq(
        $list->{'admin'}{'tracking'}->{'message_disposition_notification'},
        'on')
        or (
        Sympa::Tools::Data::smart_eq(
            $list->{'admin'}{'tracking'}
                ->{'message_disposition_notification'}, 'on_demand'
        )
        and $message->get_header('Disposition-Notification-To')
        );

    if (@apply_tracking) {
        $message->{shelved}{tracking} = join '+', @apply_tracking;

        # remove notification request becuse a new one will be inserted if
        # needed
        $message->delete_header('Disposition-Notification-To');
    }

    ## Remove unwanted headers if present.
    if ($list->{'admin'}{'remove_headers'}) {
        foreach my $field (@{$list->{'admin'}{'remove_headers'}}) {
            $message->delete_header($field);
        }
    }

    # Archives
    unless ($list->is_archiving_enabled) {
        # Archiving is disabled.
    } elsif (
        !Sympa::Tools::Data::smart_eq(
            $Conf::Conf{'ignore_x_no_archive_header_feature'}, 'on')
        and (
            grep {
                /yes/i
            } $message->get_header('X-no-archive')
            or grep {
                /no\-external\-archive/i
            } $message->get_header('Restrict')
        )
        ) {
        # Ignoring message with a no-archive flag.
        $log->syslog('info',
            "Do not archive message with no-archive flag for list %s", $list);
    } else {
        my $spool = Sympa::Spool::Archive->new;
        $spool->store(
            $message,
            original => Sympa::Tools::Data::smart_eq(
                $list->{admin}{archive_crypted_msg}, 'original'
            )
        );
    }

    # Transformation of message after archiving.
    Sympa::Spindle::DistributeMessage::post_archive($message);

    ## store msg in digest if list accept digest mode (encrypted message can't
    ## be included in digest)
    if ($list->is_digest()
        and not Sympa::Tools::Data::smart_eq(
            $message->{'smime_crypted'},
            'smime_crypted'
        )
        ) {
        my $spool_digest = Sympa::Spool::Digest->new(context => $list);
        $spool_digest->store($message) if $spool_digest;
    }

    ## Synchronize list members, required if list uses include sources
    ## unless sync_include has been performed recently.
    if ($list->has_include_data_sources()) {
        unless (defined $list->on_the_fly_sync_include(use_ttl => 1)) {
            $log->syslog('notice', 'Unable to synchronize list %s', $list);
            #FIXME: Might be better to abort if synchronization failed.
        }
    }

    ##
    ## Below is the code of former send_msg().
    ##

    ## Blindly send the message to all users.

    my $total = $list->get_total('nocache');

    unless ($total > 0) {
        $log->syslog('info', 'No subscriber in list %s', $list);
        $list->savestats;
        return 0;
    }

    ## Bounce rate
    my $rate = $list->get_total_bouncing() * 100 / $total;
    if ($rate > $list->{'admin'}{'bounce'}{'warn_rate'}) {
        $list->send_notify_to_owner('bounce_rate', {'rate' => $rate});
        if (100 <= $rate) {
            Sympa::send_notify_to_user($list, 'hundred_percent_error',
                $message->{sender});
            Sympa::send_notify_to_listmaster($list, 'hundred_percent_error',
                {sender => $message->{sender}});
        }
    }

    #save the message before modifying it
    my $nbr_smtp = 0;

    # prepare verp parameter
    my $verp_rate = $list->{'admin'}{'verp_rate'};
    # force VERP if tracking is requested.
    $verp_rate = '100%'
        if Sympa::Tools::Data::smart_eq($message->{shelved}{tracking},
        qr/dsn|mdn/);

    my $tags_to_use;

    # Define messages which can be tagged as first or last according to the
    # VERP rate.
    # If the VERP is 100%, then all the messages are VERP. Don't try to tag
    # not VERP
    # messages as they won't even exist.
    if ($verp_rate eq '0%') {
        $tags_to_use->{'tag_verp'}   = '0';
        $tags_to_use->{'tag_noverp'} = 'z';
    } else {
        $tags_to_use->{'tag_verp'}   = 'z';
        $tags_to_use->{'tag_noverp'} = '0';
    }

    # Separate subscribers depending on user reception option and also if VERP
    # a dicovered some bounce for them.
    # Storing the not empty subscribers' arrays into a hash.
    my $available_recipients = $list->get_recipients_per_mode($message);
    unless ($available_recipients) {
        $log->syslog('info', 'No subscriber for sending msg in list %s',
            $list);
        $list->savestats;
        return 0;
    }

    foreach my $mode (sort keys %$available_recipients) {
        my $new_message = $message->dup;
        unless ($new_message->prepare_message_according_to_mode($mode, $list))
        {
            $log->syslog('err', "Failed to create Message object");
            return undef;
        }

        ## TOPICS
        my @selected_tabrcpt;
        my @possible_verptabrcpt;
        if ($list->is_there_msg_topic) {
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
            $nbr_smtp++;

            # Add number and size of messages sent to total in stats file.
            my $numsent = scalar @selected_tabrcpt;
            my $bytes   = length $new_message->as_string;
            $list->{'stats'}->[1] += $numsent;
            $list->{'stats'}->[2] += $bytes;
            $list->{'stats'}->[3] += $bytes * $numsent;
        } else {
            $log->syslog(
                'notice',
                'No non VERP subscribers left to distribute message to list %s',
                $list
            );
        }

        $new_message->{shelved}{tracking} ||= 'verp';

        if ($new_message->{shelved}{tracking} =~ /dsn|mdn/) {
            my $tracking = Sympa::Tracking->new($list);

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
            $nbr_smtp++;

            # Add number and size of messages sent to total in stats file.
            my $numsent = scalar @verp_selected_tabrcpt;
            my $bytes   = length $new_message->as_string;
            $list->{'stats'}->[1] += $numsent;
            $list->{'stats'}->[2] += $bytes;
            $list->{'stats'}->[3] += $bytes * $numsent;
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
    $list->savestats;
    return $nbr_smtp;
}

# Old name: Sympa::List::post_archive().
sub post_archive {
    my $message = shift;

    Sympa::Message::Plugin::execute('post_archive', $message);

    my $list = $message->{context};

    # Change the Reply-To: header field if necessary.
    if ($list->{'admin'}{'reply_to_header'}) {
        unless ($message->get_header('Reply-To')
            and $list->{'admin'}{'reply_to_header'}->{'apply'} ne 'forced') {
            my $reply;

            $message->delete_header('Reply-To');
            $message->delete_header('Resent-Reply-To');

            if ($list->{'admin'}{'reply_to_header'}->{'value'} eq 'list') {
                $reply = $list->get_list_address();
            } elsif (
                $list->{'admin'}{'reply_to_header'}->{'value'} eq 'sender') {
                #FIXME: Missing From: field?
                $reply = $message->get_header('From');
            } elsif ($list->{'admin'}{'reply_to_header'}->{'value'} eq 'all')
            {
                #FIXME: Missing From: field?
                $reply =
                      $list->get_list_address() . ','
                    . $message->get_header('From');
            } elsif ($list->{'admin'}{'reply_to_header'}->{'value'} eq
                'other_email') {
                $reply = $list->{'admin'}{'reply_to_header'}->{'other_email'};
            }

            $message->add_header('Reply-To', $reply) if $reply;
        }
    }

    ## Add/replace useful header fields

    ## These fields should be added preserving existing ones.
    $message->add_header('X-Loop',     $list->get_list_address);
    $message->add_header('X-Sequence', $message->{xsequence})
        if defined $message->{xsequence};
    ## These fields should be overwritten if any of them already exist
    $message->delete_header('Errors-To');
    $message->add_header('Errors-To', $list->get_list_address('return_path'));
    ## Two Precedence: fields are added (overwritten), as some MTAs recognize
    ## only one of them.
    $message->delete_header('Precedence');
    $message->add_header('Precedence', 'list');
    $message->add_header('Precedence', 'bulk');
    # The Sender: field should be added (overwritten) at least for DKIM or
    # Sender ID (a.k.a. SPF 2.0) compatibility.  Note that Resent-Sender:
    # field will be removed.
    $message->replace_header('Sender', $list->get_list_address('owner'));
    $message->delete_header('Resent-Sender');
    $message->replace_header('X-no-archive', 'yes');

    # Add custom header fields
    foreach my $i (@{$list->{'admin'}{'custom_header'}}) {
        $message->add_header($1, $2) if $i =~ /^([\S\-\:]*)\s(.*)$/;
    }

    ## Add RFC 2919 header field
    if ($message->get_header('List-Id')) {
        $log->syslog(
            'notice',
            'Found List-Id: %s',
            $message->get_header('List-Id')
        );
        $message->delete_header('List-ID');
    }
    $list->add_list_header($message, 'id');

    ## Add RFC 2369 header fields
    foreach my $field (
        @{  tools::get_list_params($list->{'domain'})
                ->{'rfc2369_header_fields'}->{'format'}
        }
        ) {
        if (scalar grep { $_ eq $field }
            @{$list->{'admin'}{'rfc2369_header_fields'}}) {
            $list->add_list_header($message, $field);
        }
    }

    # Add RFC5064 Archived-At: header field
    $list->add_list_header($message, 'archived_at');

    ## Remove outgoing header fields
    ## Useful to remove some header fields that Sympa has set
    if ($list->{'admin'}{'remove_outgoing_headers'}) {
        foreach my $field (@{$list->{'admin'}{'remove_outgoing_headers'}}) {
            $message->delete_header($field);
        }
    }
}

# Distribute a message to a list, shelving encryption if needed.
#
# IN : -$message(+) : ref(Sympa::Message)
#      -\@rcpt(+) : recipients
# OUT : -$numsmtp : number of sendmail process | undef
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

    # Shelve personalization.
    $message->{shelved}{merge} = 1
        if Sympa::Tools::Data::smart_eq($list->{'admin'}{'merge_feature'},
        'on');
    # Shelve re-encryption with S/MIME.
    $message->{shelved}{smime_encrypt} = 1
        if $message->{'smime_crypted'};

    # if not specified, delivery time is right now (used for sympa messages
    # etc.)
    my $delivery_date = $list->get_next_delivery_date;
    $message->{'date'} = $delivery_date if defined $delivery_date;

    # Overwrite original envelope sender.  It is REQUIRED for delivery.
    $message->{envelope_sender} = $list->get_list_address('return_path');

    return Sympa::Bulk->new->store($message, $rcpt, tag => $tag)
        || undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DistributeMessage -
Workflow to distribute messages to list members

=head1 DESCRIPTION

L<Sympa::Spindle::DistributeMessage> distribute messages to list members.

TBD

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

In most cases, L<Sympa::Spindle::DoMessage>
splices meessages to this class.  This method is not used in ordinal case.

=item spin ( )

Not implemented.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Spindle::DoMessage>,
L<Sympa::Topic>.

=head1 HISTORY

L<Sympa::Spindle::DistributeMessage> appeared on Sympa 6.2.13.

=cut
