# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2019, 2021 The Sympa Community. See the
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

package Sympa::Spindle::ProcessBounce;

use strict;
use warnings;
use Encode qw();
use English qw(-no_match_vars);
use IO::Scalar;
use Mail::Address;
use MIME::Head;
use MIME::Parser;

use Sympa;
use Conf;
use Sympa::List;
use Sympa::Log;
use Sympa::Process;
use Sympa::Regexps;
use Sympa::Scenario;
use Sympa::Spool::Listmaster;
use Sympa::Tools::Data;
use Sympa::Tools::Text;
use Sympa::Tracking;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Bounce';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 1) {
        # Process grouped notifications.
        Sympa::Spool::Listmaster->instance->flush;
    }

    1;
}

# Old name: process_message() in bounced.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    unless ($message) {
        $log->syslog('notice', 'Ignoring malformed message %s', $message);
        return undef;
    }

    unless (defined $message->{'message_id'}
        and length $message->{'message_id'}) {
        $log->syslog('err', 'Message %s has no message ID', $message);
        return undef;
    }

    $log->syslog(
        'notice',
        'Processing %s; envelope_sender=%s; message_id=%s; sender=%s',
        $message,
        $message->{envelope_sender},
        $message->{message_id},
        $message->{sender}
    );

    my $numreported = 0;

    # Get metadata.
    my ($list, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = $Conf::Conf{'domain'};
    }

    # Parse VERP address.
    # Since RFC 3464 states that DSN must be addressed in message header to
    # the envelope return address of original message, we seek To header
    # field.
    my $who;
    my $distribution_id;
    my $unique;

    my $to = $message->get_header('To');
    if ($to) {
        # Some MTAs decorate To: field of DSN as "mailbox <address>".
        # Pick address only.
        my @to = Mail::Address->parse($to);
        if (@to and $to[0] and $to[0]->address) {
            $to = Sympa::Tools::Text::canonic_email($to[0]->address);
        } else {
            undef $to;
        }
        $log->syslog('debug', 'Bounce to: <%s>', $to);
    }
    if ($to and 0 == index($to, $Conf::Conf{'bounce_email_prefix'} . '+')) {
        # VERP in use.
        my ($local_part, $robot) = split /\@/,
            substr($to, length($Conf::Conf{'bounce_email_prefix'} . '+')),
            2;
        $local_part =~ s/==a==/\@/;

        if ($local_part =~ s/(==[^\@]+)==([wr])\z/$1/) {
            # VERP for welcome/remind probe in use.
            $unique = $2;
        } elsif ($local_part =~ s/(==[^\@]+)==(\w+)\z/$1/) {
            # Tracking in use.
            $distribution_id = $2;
        }

        my $listname;
        ($who, $listname) = ($local_part =~ /\A(.*)==(.*)\z/);

        if ($who and $listname) {
            unless ($list =
                Sympa::List->new($listname, $robot, {just_try => 1})) {
                $log->syslog('notice',
                    'Skipping bounce %s for unknown list %s@%s',
                    $message, $listname, $robot);
                return undef;
            }
            # Overwrite context.
            $message->{context} = $list;

            $log->syslog('notice',
                'VERP in use: bounce %s related to <%s> for list %s',
                $message, $who, $list);
        }
    }

    my ($tracking_by_mdn_in_use, $tracking_by_dsn_in_use);
    if ($list) {
        $tracking_by_mdn_in_use = 1
            if Sympa::Tools::Data::smart_eq(
            $list->{'admin'}{'tracking'}{'message_disposition_notification'},
            qr/\A(on|on_demand)\z/
            );
        $tracking_by_dsn_in_use = 1
            if Sympa::Tools::Data::smart_eq(
            $list->{'admin'}{'tracking'}{'delivery_status_notification'},
            'on')
            or $tracking_by_mdn_in_use;
    }

    my $eff_type = $message->as_entity->effective_type || '';
    my $report_type =
        lc($message->as_entity->head->mime_attr('Content-Type.Report-Type')
            || '');

    # ---
    # If the DSN (RFC 3464) is correct and the tracking mode is enable,
    # it will be inserted in the database.
    if (    $eff_type eq 'multipart/report'
        and $report_type eq 'delivery-status'
        and $tracking_by_dsn_in_use
        and $who
        and $distribution_id) {
        my $dsn_status;
        my $arrival_date;

        my @reports = _parse_multipart_report($message,
            qw(message/delivery-status message/global-delivery-status));

        $arrival_date = $reports[0]->{arrival_date}->[0]
            if @reports and $reports[0]->{arrival_date};

        # Action Field MUST be present in a DSN report.
        # Possible values: failed, delayed, delivered, relayed, expanded.
        #FIXME: Only the first occurrence is recognized.
        foreach my $report (@reports) {
            next unless $report->{action};
            $dsn_status = lc($report->{action}->[0] || '');
            last if $dsn_status and $dsn_status =~ /\S/;
        }
        if ($arrival_date and $dsn_status) {
            $log->syslog('debug3',
                '%s: DSN detected: dsn_status=%s; rcpt=%s; arrival_date=%s',
                $message, $dsn_status, $who, $arrival_date);

            my $tracking = Sympa::Tracking->new(context => $list);
            if ($tracking->store(
                    $message, $who,
                    envid        => $distribution_id,
                    type         => 'DSN',
                    status       => $dsn_status,
                    arrival_date => $arrival_date
                )
            ) {
                $log->syslog('notice', 'DSN %s correctly treated', $message);
                $numreported++;
            } else {
                $log->syslog(
                    'err',
                    'Not able to fill database with notification data of %s',
                    $message
                );
            }
        }
    }    # if (... $report_type eq 'delivery-status' ...)

    # ---
    # If the MDN (RFC 3798) is correct and the tracking mode is enabled,
    # it will be inserted in the database.
    if (    $eff_type eq 'multipart/report'
        and $report_type eq 'disposition-notification'
        and $tracking_by_mdn_in_use
        and $who
        and $distribution_id) {
        my $date;
        my $mdn_status;

        my @reports = _parse_multipart_report(
            $message,
            qw(message/disposition-notification
                message/global-disposition-notification)
        );

        # Disposition Field MUST be present in a MDN report.
        # Possible values: displayed, deleted.
        foreach my $report (@reports) {
            next unless $report->{disposition};
            $mdn_status = lc($report->{disposition}->[0] || '');
            ($mdn_status) = split /\s*[\/]\s*/, $mdn_status
                if $mdn_status;
            last if $mdn_status and $mdn_status =~ /\S/;
        }
        if ($mdn_status) {
            $date = $message->get_header('Date');

            $log->syslog(
                'debug2',
                '%s: MDN detected: mdn_status=%s; original_rcpt=%s; date=%s',
                $message,
                $mdn_status,
                $who,
                $date
            );

            my $tracking = Sympa::Tracking->new(context => $list);
            if ($tracking->store(
                    $message, $who,
                    envid        => $distribution_id,
                    type         => 'MDN',
                    status       => $mdn_status,
                    arrival_date => $date
                )
            ) {
                $log->syslog('notice', 'MDN %s correctly treated', $message);
                $numreported++;
            } else {
                $log->syslog(
                    'err',
                    'Not able to fill database with notification data of %s',
                    $message
                );
            }
        }
    }    # if (... $report_type eq 'disposition-notification' ...)

    # ---
    # This case a report Email Feedback Reports (RFC 5965) mainly used by
    # AOL.
    if (    $eff_type eq 'multipart/report'
        and $report_type eq 'feedback-report') {
        # Prepare entity to analyse.
        # Not extract message/* parts.
        my $parser = MIME::Parser->new;
        $parser->extract_nested_messages(0);
        $parser->output_to_core(1);
        $parser->tmp_dir($Conf::Conf{'tmpdir'});
        my $entity = $parser->parse_data($message->as_string);

        # Get list context from List-Id: field in the third part of report.
        my $list;
        foreach my $part ($entity->parts) {
            my $etype = $part->effective_type || '';
            next
                unless $etype eq 'message/rfc822'
                or $etype eq 'text/rfc822-headers'
                or $etype eq 'message/global'
                or $etype eq 'message/global-headers';
            next unless $part->bodyhandle;

            my $str  = $part->bodyhandle->as_string . "\n\n";
            my $head = MIME::Head->read(IO::Scalar->new(\$str));

            foreach my $list_id ($head->get('List-Id')) {
                $list_id = Sympa::Tools::Text::canonic_message_id($list_id);

                if (0 == index(
                        scalar reverse($list_id),
                        scalar reverse('.', $robot)
                    )
                ) {
                    my $listname = substr $list_id, 0, -length($robot) - 1;
                    $list =
                        Sympa::List->new($listname, $robot, {just_try => 1});
                    last if $list;
                }
            }
            last if $list;
        }
        unless ($list) {
            $log->syslog('notice',
                'Skipping email feedback report %s on unknown list',
                $message);
            return undef;
        }
        # Overwrite context.
        $message->{context} = $list;

        my @reports =
            _parse_multipart_report($message, 'message/feedback-report');
        foreach my $report (@reports) {
            # Skip malformed report.
            next unless $report->{feedback_type};
            next unless $report->{user_agent};
            next unless $report->{version};
            next if $report->{arrival_date} and $report->{received_date};

            my $feedback_type = lc($report->{feedback_type}->[0] || '');
            my @original_rcpts =
                grep { Sympa::Tools::Text::valid_email($_) }
                map { Sympa::Tools::Text::canonic_email($_ || '') }
                @{$report->{original_rcpt_to} || []};

            # Malformed reports are forwarded to listmaster.
            unless (@original_rcpts) {
                $log->syslog(
                    'err',
                    'Ignoring Feedback Report %s for list %s: Unknown Original-Rcpt-To field. Can\'t do anything; feedback_type=%s',
                    $message,
                    $list,
                    $feedback_type
                );
                Sympa::send_notify_to_listmaster(
                    $list,
                    'arf_processing_failed',
                    {   error         => 'Unknown Original-Rcpt-To field',
                        feedback_type => $feedback_type,
                        msg           => $message,
                    }
                );
                return undef;
            }
            unless ($feedback_type
                and $feedback_type =~
                /b(?:abuse|fraud|not-spam|virus|other)\b/) {
                $log->syslog(
                    'err',
                    'Ignoring Feedback Report %s for list %s: Unknown format; feedback_type=%s',
                    $message,
                    $list,
                    $feedback_type
                );
                Sympa::send_notify_to_listmaster(
                    $list,
                    'arf_processing_failed',
                    {   error         => 'Unknown feedback type',
                        feedback_type => $feedback_type,
                        msg           => $message,
                    }
                );
                return undef;
            }

            # Process report.
            foreach my $original_rcpt (@original_rcpts) {
                $log->syslog('debug3',
                    'Email Feedback Report: %s feedback-type: %s; user: %s',
                    $list, $feedback_type, $original_rcpt);

                # RFC compliance remark: We do something if there is an
                # abuse.  We don't throw an error if we find another kind of
                # feedback (fraud, not-spam, virus or other) but we don't
                # take action if we meet them yet.  This is to be done, if
                # relevant.
                # n.b. The feedback types miscategorized, opt-out and
                # opt-out-list are abandoned.
                if ($feedback_type =~ /\babuse\b/) {
                    my $result =
                        Sympa::Scenario->new($list, 'unsubscribe')
                        ->authz('smtp', {'sender' => $original_rcpt});
                    my $action = $result->{'action'}
                        if ref $result eq 'HASH';
                    if ($action and $action =~ /do_it/i) {
                        if ($list->is_list_member($original_rcpt)) {
                            $list->delete_list_member(
                                [$original_rcpt],
                                exclude   => 1,
                                operation => 'auto_del'
                            );

                            $log->syslog(
                                'notice',
                                '%s has been removed from %s because abuse feedback report %s',
                                $original_rcpt,
                                $list,
                                $message
                            );
                            $list->send_notify_to_owner(
                                'automatic_del',
                                {   'who'    => $original_rcpt,
                                    'reason' => 'arf',
                                    'msg'    => $message,
                                }
                            );

                            $numreported++;
                        } else {
                            $log->syslog(
                                'err',
                                'Ignore Feedback Report %s for list %s: user %s not subscribed',
                                $message,
                                $list,
                                $original_rcpt
                            );
                            $list->send_notify_to_owner('warn-signoff',
                                {'who' => $original_rcpt});
                        }
                    } else {
                        $log->syslog(
                            'err',
                            'Ignore Feedback Report %s for list %s: user %s is not allowed to unsubscribe',
                            $message,
                            $list,
                            $original_rcpt
                        );
                    }
                } else {
                    $log->syslog(
                        'notice',
                        'Ignoring Feedback Report %s for list %s: Nothing to do for this feedback type; feedback_type=%s; original_rcpt=%s',
                        $message,
                        $list,
                        $feedback_type,
                        $original_rcpt
                    );
                }
            }

            last;    # feedback report may have only one block.
        }    # foreach my $report
    }    # if (... $report_type eq 'feedback-report')

    $log->syslog('debug', 'Processing bounce %s for list %s', $message,
        $list);

    # Bouncing addresses

    # RFC 3464 compliance check.
    my %stata;
    if ($list) {
        foreach my $report (
            _parse_multipart_report(
                $message,
                qw(message/delivery-status message/global-delivery-status)
            )
        ) {
            next unless $report->{status};
            my $status = $report->{status}->[0];
            if ($status and $status =~ /\b(\d+[.]\d+[.]\d+)\b/) {
                $status = $1;
            } else {
                next;
            }

            my $rcpt =
                (      $report->{original_recipient}
                    || $report->{final_recipient}
                    || [])->[0];
            next unless $rcpt;
            $rcpt = $1 if $rcpt =~ /\@.+:\s*(.+)\z/;
            $rcpt = $1 if $rcpt =~ /<(.+)>/;
            $rcpt = Sympa::Tools::Text::canonic_email($rcpt);
            next unless defined $rcpt;

            $stata{$rcpt} = $status;
        }
    }

    if ($unique and $who and grep {/\A[45][.]\d+[.]\d+/} values %stata) {
        # In this case the bounce result from a remind or a welcome
        # message; so try to remove the subscriber.
        $log->syslog('debug',
            "VERP for a service message, try to remove the subscriber");

        my $result = Sympa::Scenario->new($list, 'del')->authz(
            'smtp',
            {   'sender' => $Conf::Conf{'listmaster'},    #FIXME
                'email'  => $who
            }
        );
        my $action = $result->{'action'} if ref $result eq 'HASH';

        if ($action and $action =~ /do_it/i) {
            if ($list->is_list_member($who)) {
                $list->delete_list_member(
                    [$who],
                    exclude   => 1,
                    operation => 'auto_del'
                );
                $log->syslog(
                    'notice',
                    '%s has been removed from %s because welcome message bounced',
                    $who,
                    $list
                );
                $log->db_log(
                    'robot'        => $list->{'domain'},
                    'list'         => $list->{'name'},
                    'action'       => 'del',
                    'target_email' => $who,
                    'status'       => 'error',
                    'error_type'   => 'welcome_bounced'
                );

                $log->add_stat(
                    'robot'     => $list->{'domain'},
                    'list'      => $list->{'name'},
                    'operation' => 'auto_del',
                    'parameter' => "",
                    'mail'      => $who
                );

                if ($action =~ /notify/) {
                    $list->send_notify_to_owner(
                        'automatic_del',
                        {   'who'    => $who,
                            'reason' => 'welcome',
                            'msg'    => $message,
                        }
                    );
                }
            }
            $numreported++;
        } else {
            $log->syslog(
                'notice',
                'Unable to remove <%s> from %s (welcome or remind message bounced but del is closed)',
                $who,
                $list
            );
        }
    } elsif (%stata and $who) {
        # VERP in use.
        my $tracking = Sympa::Tracking->new(context => $list);
        my ($status) = values %stata;

        if ($tracking->store($message, $who, status => $status)) {
            $log->syslog('notice',
                'Received bounce for email address %s, list %s',
                $who, $list);
            $log->db_log(
                'robot'        => $list->{'domain'},
                'list'         => $list->{'name'},
                'action'       => 'get_bounce',
                'target_email' => $who,
                'msg_id'       => '',
                'status'       => 'error',
                'error_type'   => $status
            );

            $numreported++;
        }
    } elsif (%stata) {
        my $tracking = Sympa::Tracking->new(context => $list);

        while (my ($rcpt, $status) = each %stata) {
            if ($tracking->store($message, $rcpt, status => $status)) {
                $log->syslog('notice',
                    'Received bounce for email address <%s>, list %s',
                    $rcpt, $list);
                $log->db_log(
                    'robot'        => $list->{'domain'},
                    'list'         => $list->{'name'},
                    'action'       => 'get_bounce',
                    'target_email' => $rcpt,
                    'msg_id'       => '',
                    'status'       => 'error',
                    'error_type'   => $status
                );

                $numreported++;
            }
        }
    }

    unless ($numreported) {
        # No address found in the bounce itself.
        # No VERP and no rcpt recognized.
        $log->syslog('info', 'No address found in message %s', $message);
        return undef;
    }
    return 1;
}

# Old names: Bounce::rfc1891(), _parse_dsn() in bounced.pl.
# Merged into _twist().
#sub _parse_dsn;

# Old name: _parse_multipart_report() in bounced.pl.
sub _parse_multipart_report {
    my $message       = shift;
    my @subpart_types = @_;

    # Prepare entity to analyse.
    # Not extract message/* parts.
    my $parser = MIME::Parser->new;
    $parser->extract_nested_messages(0);
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    my $entity = $parser->parse_data($message->as_string);

    return
        unless ($entity->effective_type || '') eq 'multipart/report'
        and $entity->parts;

    my @results;
    foreach my $p ($entity->parts) {
        # Get only possible types of subpart.
        my $eff_type = $p->effective_type || '';
        next unless grep { $_ eq $eff_type } @subpart_types;
        next unless $p->bodyhandle;

        my @fields = grep {$_} map {
            my $str = $_ . "\n\n";
            MIME::Head->read(IO::Scalar->new(\$str));
        } split /(?:\A|\r\n|\n)[\r\n]+/, $p->bodyhandle->as_string;
        next unless @fields;

        foreach my $fields (@fields) {
            my %item;
            foreach my $key ($fields->tags) {
                my $hashkey = lc $key;
                $hashkey =~ s/\W/_/g;

                foreach my $val ($fields->get($key)) {
                    chomp $val;
                    # Strip comment.
                    1 while $val =~ s/\s*[(][^)]*[)]\s*/ /gs;
                    # Strip type.
                    if ($val =~ s/\A\s*utf-8\s*;\s*//i) {
                        $val = _decode_utf_8_addr_xtext($val);
                    } else {
                        $val =~ s/\A[-\w\s]*;\s*//;
                    }
                    # Unfold and strip spaces.
                    $val =~ s/(?:\r\n|\r|\n)(?=[ \t])//g;
                    $val =~ s/\A\s+//;
                    $val =~ s/\s+\z//;

                    $item{$hashkey} ||= [];
                    push @{$item{$hashkey}}, $val;
                }
            }
            push @results, {%item} if %item;
        }

        # Get only the first report.
        last if @results;
    }

    return @results;
}

# Decode utf-8-addr-xtext or utf-8-addr-unitext.  cf. RFC 6533 section 3.
# Old name: _decode_utf_8_addr_xtext() in bounced.pl.
sub _decode_utf_8_addr_xtext {
    my $str = shift;
    return $str unless defined $str and length $str;

    my $dec = Encode::decode_utf8($str);
    $dec =~ s<
        \\x[{]
        (
            [01][1-9] | 10 | 20 | 2B | 3D | 7F | 5C |
            [8-9A-F][0-9A-F] |
            [1-9A-F][0-9A-F]{2} |
            [1-9A-CE-F][0-9A-F]{3} |
            D[0-7][0-9A-F]{2} |
            [1-9A-F][0-9A-F]{4} |
            10[0-9A-F]{4}
        )
        [}]
    ><
        pack 'U', hex "0x$1"
    >egx;
    $str = Encode::encode_utf8($dec);

    return $str;
}

# Old names: Bounce::corrige(), _corrige() in bounced.pl.
# DEPRECATED.
#sub _corrige;

# Old names: Bounce::anabounce(), _anabounce() in bounced.pl.
# DEPRECATED.
#sub _anabounce;

# Old name: _canonicalize_status() in bounced.pl.
# DEPRECATED.
#sub _canonicalize_status;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessBounce - Workflow of bounce processing

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessBounce;

  my $spindle = Sympa::Spindle::ProcessBounce->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessBounce> defines workflow to process bounce messages
including notifications requested by tracking feature.

When spin() method is invoked, messages kept in bounce spool are
processed.
Bounce spool may contain several types of bounce messages by their
recipient addresses:

=over

=item *

Bounce address of particular list.
Messages bound for this address are analysed and increase bounce score
of original recipient if any.

=item *

VERP address.
Messages bound for this address are stored into tracking spool
without envelope ID, and increase bounce score.

=item *

VERP address with C<w> or C<r> suffix.
Messages bound for this address cause deletion of original recipient.

=item *

VERP address with envelope ID.
Messages are Delivery Status Notification (DSN) or
Message Disposition Notification (MDN).
They are stored into tracking spool
with envelope ID, and increase bounce score.

=item *

Others, and messages are E-mail Feedback Report.
Reports are analysed, and if opt-out report is found and list configuration
allows it, original recipient will be deleted.

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Bounce> class.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spool::Bounce>, L<Sympa::Tracking>.

=head1 HISTORY

L<Sympa::Spindle::ProcessBounce> appeared on Sympa 6.2.10.

=cut
