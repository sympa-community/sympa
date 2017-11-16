# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::AuthorizeMessage;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Tools::Data;
use Sympa::Topic;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

# Old name: (part of) DoMessage() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list      = $message->{context};
    my $messageid = $message->{message_id};

    # Now check if the sender is an authorized address.
    my $sender = $self->{confirmed_by} || $message->{sender};

    my $context = {
        'sender'  => $sender,
        'message' => $message
    };

    # List msg topic.
    if (not $self->{confirmed_by}    # Not in ProcessHeld spindle.
        and $list->is_there_msg_topic
        ) {
        my $topic;
        if ($topic = Sympa::Topic->load($message)) {
            # Is message already tagged?
            ;
        } elsif ($topic = Sympa::Topic->load($message, in_reply_to => 1)) {
            # Is message in-reply-to already tagged?
            $topic =
                Sympa::Topic->new(topic => $topic->{topic}, method => 'auto');
            $topic->store($message);
        } elsif (my $topic_list = $message->compute_topic) {
            # Not already tagged.
            $topic =
                Sympa::Topic->new(topic => $topic_list, method => 'auto');
            $topic->store($message);
        }

        if ($topic) {
            $context->{'topic'} = $context->{'topic_' . $topic->{method}} =
                $topic->{topic};
        }
        $context->{'topic_needed'} =
            (!$context->{'topic'} && $list->is_msg_topic_tagging_required);
    }

    # Call scenario: auth_method MD5 do not have any sense in "send"
    # scenario because auth is performed by distribute or reject command.

    my $action;
    my $result;

    # The order of the following 3 lines is important! SMIME > DKIM > SMTP.
    my $auth_method =
          $message->{'smime_signed'} ? 'smime'
        : $message->{'md5_check'}    ? 'md5'
        : $message->{'dkim_pass'}    ? 'dkim'
        :                              'smtp';

    $result = Sympa::Scenario::request_action($list, 'send', $auth_method,
        $context);
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        $log->syslog(
            'err',
            'Message %s ignored because unable to evaluate scenario "send" for list %s',
            $message,
            $list
        );
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error =>
                    'Message ignored because scenario "send" cannot be evaluated',
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
    }

    # Message topic context.
    if ($action =~ /^do_it\b/ and $context->{'topic_needed'}) {
        if ($list->{'admin'}{'msg_topic_tagging'} eq 'required_sender') {
            $action = 'request_auth';
        } elsif (
            $list->{'admin'}{'msg_topic_tagging'} eq 'required_moderator') {
            $action = 'editorkey';
        }
    }

    if ($action =~ /^do_it\b/) {
        $self->{quiet} ||= ($action =~ /,\s*quiet\b/);    # Overwrite.

        unless ($self->{confirmed_by}) {    # Not in ProcessHeld spindle.
            $message->{shelved}{dkim_sign} = 1
                if Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'}, 'any')
                or (
                Sympa::Tools::Data::is_in_array(
                    $list->{'admin'}{'dkim_signature_apply_on'},
                    'smime_authenticated_messages')
                and $message->{'smime_signed'}
                )
                or (
                Sympa::Tools::Data::is_in_array(
                    $list->{'admin'}{'dkim_signature_apply_on'},
                    'dkim_authenticated_messages')
                and $message->{'dkim_pass'}
                );
        } else {
            $message->add_header('X-Validation-by', $self->{confirmed_by});

            $message->{shelved}{dkim_sign} = 1
                if Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'}, 'any')
                or Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'},
                'md5_authenticated_messages');
        }

        # Check TT2 syntax for merge_feature.
        unless (_test_personalize($message, $list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        # Keep track of known message IDs...if any.
        $self->{_msgid}{$list->get_id}{$messageid} = time
            unless $self->{confirmed_by};

        return ['Sympa::Spindle::DistributeMessage'];
    } elsif (
        not $self->{confirmed_by}    # Not in ProcessHeld spindle.
        and $action =~ /^request_auth\b/
        ) {
        ## Check syntax for merge_feature.
        unless (_test_personalize($message, $list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        return ['Sympa::Spindle::ToHeld'];
    } elsif ($action =~ /^editorkey\b/) {
        $self->{quiet} ||= ($action =~ /,\s*quiet\b/);    # Overwrite

        # Check syntax for merge_feature.
        unless (_test_personalize($message, $list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        return ['Sympa::Spindle::ToModeration'];
    } elsif ($action =~ /^editor\b/) {
        $self->{quiet} ||= ($action =~ /,\s*quiet\b/);    # Overwrite

        # Check syntax for merge_feature.
        unless (_test_personalize($message, $list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        return ['Sympa::Spindle::ToEditor'];
    } elsif ($action =~ /^reject\b/) {
        my $quiet = $self->{quiet} || ($action =~ /,\s*quiet\b/);

        $log->syslog(
            'notice',
            'Message %s for %s from %s rejected(%s) because sender not allowed',
            $message,
            $list,
            $sender,
            $result->{'tt2'}
        );

        # Do not report to the sender if the message was tagged as a spam.
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            if (defined $result->{'tt2'}) {
                unless (
                    Sympa::send_file(
                        $list, $result->{'tt2'},
                        $sender, {auto_submitted => 'auto-replied'}
                    )
                    ) {
                    $log->syslog('notice',
                        'Unable to send template "%s" to %s',
                        $result->{'tt2'}, $sender);
                    Sympa::send_dsn($list, $message,
                        {reason => $result->{'reason'}}, '5.7.1');
                }
            } else {
                Sympa::send_dsn($list, $message,
                    {reason => $result->{'reason'}}, '5.7.1');
            }
        }
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'rejected_authorization',
            'user_email'   => $sender
        );
        return undef;
    } else {
        $log->syslog('err',
            'Unknown action %s returned by the scenario "send"', $action);
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error  => 'Unknown action returned by the scenario "send"',
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
    }
}

# Private subroutine.

# Tests if personalization can be performed successfully over all subscribers
# of list.
# Returns: 1 if succeed, or undef.
# Old name: Sympa::Message::test_personalize().
sub _test_personalize {
    my $message = shift;
    my $list    = shift;

    return 1
        unless Sympa::Tools::Data::smart_eq($list->{'admin'}{'merge_feature'},
        'on');

    # Get available recipients to test.
    my $available_recipients = $list->get_recipients_per_mode($message) || {};
    # Always test all available reception modes using sender.
    foreach my $mode ('mail',
        grep { $_ and $_ ne 'nomail' and $_ ne 'not_me' }
        @{$list->{'admin'}{'available_user_options'}->{'reception'} || []}) {
        push @{$available_recipients->{$mode}{'verp'}}, $message->{'sender'};
    }

    foreach my $mode (sort keys %$available_recipients) {
        my $new_message = $message->dup;
        $new_message->prepare_message_according_to_mode($mode, $list);

        foreach my $rcpt (
            @{$available_recipients->{$mode}{'verp'}   || []},
            @{$available_recipients->{$mode}{'noverp'} || []}
            ) {
            unless ($new_message->personalize($list, $rcpt, {})) {
                return undef;
            }
        }
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::AuthorizeMessage -
Workflow to authorize messages bound for lists

=head1 DESCRIPTION

L<Sympa::Spindle::AuthorizeMessage> authorizes messages and stores them
into confirmation spool, moderation spool or the lists.

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

L<Sympa::Message>, L<Sympa::Scenario>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spindle::DoMessage>, L<Sympa::Spindle::ProcessHeld>,
L<Sympa::Spindle::ToEditor>, L<Sympa::Spindle::ToHeld>,
L<Sympa::Spindle::ToModeration>,
L<Sympa::Topic>.

=head1 HISTORY

L<Sympa::Spindle::AuthorizeMessage> appeared on Sympa 6.2.13.

=cut
