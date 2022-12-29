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

    # RFC 3464 compliance check, or analysis of bounced message.
    my (%hash, $from);
    if ($list) {
        _parse_dsn($message, \%hash) or _anabounce($message, \%hash, \$from);
    }

    if (%hash and $who and $unique) {
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
    } elsif (%hash and $who) {
        # VERP in use.
        my $tracking = Sympa::Tracking->new(context => $list);
        my ($status) = values %hash;

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
    } elsif (%hash) {
        my $tracking = Sympa::Tracking->new(context => $list);

        while (my ($rcpt, $status) = each %hash) {
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

# Private subroutines.

# RFC 3464 compliance check
# Old names: Bounce::rfc1891(), _parse_dsn() in bounced.pl.
sub _parse_dsn {
    my $message = shift;
    my $result  = shift;

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

        $result->{$rcpt} = $status;
    }

    return scalar keys %$result;
}

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

# Equivalents relative to RFC 1893
my %equiv = (
    "user unknown"                                                => '5.1.1',
    "receiver not found"                                          => '5.1.1',
    "the recipient name is not recognized"                        => '5.1.1',
    "sorry, no mailbox here by that name"                         => '5.1.1',
    "utilisateur non recens\xE9 dans le carnet d'adresses public" => '5.1.1',
    "unknown address"                                             => '5.1.1',
    "unknown user"                                                => '5.1.1',
    "550"                                                         => '5.1.1',
    "le nom du destinataire n'est pas reconnu"                    => '5.1.1',
    "user not listed in public name & address book"               => '5.1.1',
    "no such address"                                             => '5.1.1',
    "not known at this site."                                     => '5.1.1',
    "user not known"                                              => '5.1.1',

    "user is over the quota. you can try again later." => '4.2.2',
    "quota exceeded"                                   => '4.2.2',
    "write error to mailbox, disk quota exceeded"      => '4.2.2',
    "user mailbox exceeds allowed size"                => '4.2.2',
    "insufficient system storage"                      => '4.2.2',
    "User's Disk Quota Exceeded:"                      => '4.2.2'
);

## Corrige une adresse SMTP
# Old names: Bounce::corrige(), _corrige() in bounced.pl.
sub _corrige {

    my ($adr, $from) = @_;

    ## X400 address
    if ($adr =~ /^\//) {

        my (%x400, $newadr);

        my @detail = split /\//, $adr;
        foreach (@detail) {

            my ($var, $val) = split /=/;
            $x400{$var} = $val;
            #print "\t$var <=> $val\n";

        }

        $newadr = $x400{PN} || "$x400{s}";
        $newadr = "$x400{g}." . $newadr if $x400{g};
        my ($l, $d) = split /\@/, $from;

        $newadr .= "\@$d";

        return $newadr;

    } elsif ($adr =~ /\@/) {

        return $adr;

    } elsif ($adr =~ /\!/) {

        my ($dom, $loc) = split /\!/, $adr;
        return "$loc\@$dom";

    } else {

        my ($l, $d) = split /\@/, $from;
        my $newadr = "$adr\@$d";

        return $newadr;

    }
}

# Analyse d'un rapport de non-remise
# Param 1 : descripteur du fichier contenant le bounce
# //    2 : reference d'un hash pour retourner @ en erreur
# //    3 : reference d'un tableau pour retourner des stats
# //    4 : reference d'un tableau pour renvoyer le bounce
# Old names: Bounce::anabounce(), _anabounce() in bounced.pl.
sub _anabounce {
    my $message = shift;
    my $result  = shift;
    my $from    = shift;

    my $msg_string = $message->as_string;
    my $fic        = IO::Scalar->new(\$msg_string);

    my $entete = 1;
    my $type;
    my %info;
    my ($qmail,                $type_9,      $type_18,
        $exchange,             $ibm_vm,      $lotus,
        $sendmail_5,           $yahoo,       $type_21,
        $exim,                 $vines,       $mercury_143,
        $altavista,            $mercury_131, $type_31,
        $type_32,              $exim_173,    $type_38,
        $type_39,              $type_40,     $pmdf,
        $following_recipients, $postfix,     $groupwise7
    );

    ## Le champ separateur de paragraphe est un ensemble
    ## de lignes vides
    local $RS = '';

    ## Parcour du bounce, paragraphe par paragraphe
    foreach (<$fic>) {
        if ($entete) {
            undef $entete;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            my ($champ_courant, %champ);
            foreach (@paragraphe) {
                if (/^(\S+):\s*(.*)$/) {
                    $champ_courant = $1;
                    $champ_courant =~ y/[A-Z]/[a-z]/;
                    $champ{$champ_courant} = $2;
                } elsif (/^\s+(.*)$/) {
                    $champ{$champ_courant} .= " $1";
                }

                ## Le champ From:
                if (defined $champ{from}) {
                    my @addrs = Mail::Address->parse($champ{from});
                    $$from = $addrs[0]->address if @addrs;
                }
            }
            local $RS = '';

            $champ{from} =~ s/^.*<(.+)[\>]$/$1/;
            $champ{from} =~ y/[A-Z]/[a-z]/;

            if ($champ{subject} =~
                /^Returned mail: (Quota exceeded for user (\S+))$/) {

                $info{$2}{error} = $1;
                $type = 27;

            } elsif ($champ{subject} =~
                /^Returned mail: (message not deliverable): \<(\S+)\>$/) {

                $info{$2}{error} = $1;
                $type = 34;
            }

            unless (defined $champ{'x-failed-recipients'}) {
                ;
            } elsif ($champ{'x-failed-recipients'} =~ /^\s*(\S+)$/) {
                $info{$1}{error} = "";
            } elsif ($champ{'x-failed-recipients'} =~ /^\s*(\S+),/) {
                for my $xfr (split(/\s*,\s*/, $champ{'x-failed-recipients'}))
                {
                    $info{$xfr}{error} = "";
                }
            }
        } elsif (
            /^\s*-+ The following addresses (had permanent fatal errors|had transient non-fatal errors|have delivery notifications) -+/m
        ) {

            my $adr;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^(\S[^\(]*)/) {
                    $adr = $1;
                    my $error = $2;
                    $adr =~ s/^[\"\<](.+)[\"\>]\s*$/$1/;
                    #print "\tADR : #$adr#\n";
                    $info{$adr}{error} = $error;
                    $type = 1;

                } elsif (/^\s+\(expanded from: (.+)\)/) {
                    #print "\tEXPANDED $adr : $1\n";
                    $info{$adr}{expanded} = $1;
                    $info{$adr}{expanded} =~ s/^[\"\<](.+)[\"\>]$/$1/;
                }
            }
            local $RS = '';

        } elsif (/^\s+-+\sTranscript of session follows\s-+/m) {

            my $adr;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^(\d{3}\s)?(\S+|\".*\")\.{3}\s(.+)$/) {

                    $adr = $2;
                    my $cause = $3;
                    $cause =~ s/^(.*) [\(\:].*$/$1/;
                    foreach $a (split /,/, $adr) {

                        $a =~ s/^[\"\<]([^\"\>]+)[\"\>]$/$1/;
                        $info{$a}{error} = $cause;
                        $type = 2;

                    }
                } elsif (/^\d{3}\s(too many hops).*to\s(.*)$/i) {

                    $adr = $2;
                    my $cause = $1;
                    foreach $a (split /,/, $adr) {

                        $a =~ s/^[\"\<](.+)[\"\>]$/$1/;
                        $info{$a}{error} = $cause;
                        $type = 2;

                    }

                } elsif (/^\d{3}\s.*\s([^\s\)]+)\.{3}\s(.+)$/) {

                    $adr = $1;
                    my $cause = $2;
                    $cause =~ s/^(.*) [\(\:].*$/$1/;
                    foreach $a (split /,/, $adr) {

                        $a =~ s/^[\"\<](.+)[\"\>]$/$1/;
                        $info{$a}{error} = $cause;
                        $type = 2;

                    }
                }
            }
            local $RS = '';

            ## Rapport Compuserve
        } elsif (/^Receiver not found:/m) {

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                $info{$2}{error} = $1 if /^(.*): (\S+)/;
                $type = 3;

            }
            local $RS = '';

        } elsif (/^\s*-+ Special condition follows -+/m) {

            my ($cause, $adr);

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^(Unknown QuickMail recipient\(s\)):/) {
                    $cause = $1;
                    $type  = 4;

                } elsif (/^\s+(.*)$/ and $cause) {

                    $adr = $1;
                    $adr =~ s/^[\"\<](.+)[\"\>]$/$1/;
                    $info{$adr}{error} = $cause;
                    $type = 4;

                }
            }
            local $RS = '';

        } elsif (/^Your message add?ressed to .* couldn\'t be delivered/m) {

            my $adr;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^Your message add?ressed to (.*) couldn\'t be delivered, for the following reason :/
                ) {
                    $adr = $1;
                    $adr =~ s/^[\"\<](.+)[\"\>]$/$1/;
                    $type = 5;

                } else {

                    /^(.*)$/;
                    $info{$adr}{error} = $1;
                    $type = 5;

                }
            }
            local $RS = '';

            ## Rapport X400
        } elsif (
            /^Your message was not delivered to:\s+(\S+)\s+for the following reason:\s+(.+)$/m
        ) {

            my ($adr, $error) = ($1, $2);
            $error =~ s/Your message.*$//;
            $info{$adr}{error} = $error;
            $type = 6;

            ## Rapport X400
        } elsif (
            /^Your message was not delivered to\s+(\S+)\s+for the following reason:\s+(.+)$/m
        ) {

            my ($adr, $error) = ($1, $2);
            $error =~ s/\(.*$//;
            $info{$adr}{error} = $error;
            $type = 6;

            ## Rapport X400
        } elsif (/^Original-Recipient: rfc822; (\S+)\s+Action: (.*)$/m) {

            $info{$1}{error} = $2;
            $type = 16;

            ## Rapport NTMail
        } elsif (/^The requested destination was:\s+(.*)$/m) {

            $type = 7;

        } elsif ($type and $type == 7 and /^\s+(\S+)/) {

            undef $type;
            my $adr = $1;
            $adr =~ s/^[\"\<](.+)[\"\>]$/$1/;
            next unless $adr;
            $info{$adr}{'error'} = '';

            ## Rapport Qmail dans prochain paragraphe
        } elsif (/^Hi\. This is the qmail-send program/m) {

            $qmail = 1;

            ## Rapport Qmail
        } elsif ($qmail) {

            undef $qmail if /^[^<]/;

            if (/^<(\S+)>:\n(.*)/m) {

                $info{$1}{error} = $2;
                $type = 8;

            }
            local $RS = '';

            ## Sendmail
        } elsif (
            /^Your message was not delivered to the following recipients:/m) {

            $type_9 = 1;

        } elsif ($type_9) {

            undef $type_9;

            if (/^\s*(\S+):\s+(.*)$/m) {

                $info{$1}{error} = $2;
                $type = 9;

            }

            ## Rapport Exchange dans prochain paragraphe
        } elsif (/^The following recipient\(s\) could not be reached:/m
            or /^did not reach the following recipient\(s\):/m) {

            $exchange = 1;

            ## Rapport Exchange
        } elsif ($exchange) {

            undef $exchange;

            if (/^\s*(\S+).*\n\s+(.*)$/m) {

                $info{$1}{error} = $2;
                $type = 10;

            }

            ## IBM VM dans prochain paragraphe
        } elsif (
            /^Your mail item could not be delivered to the following users/m)
        {

            $ibm_vm = 1;

            ## Rapport IBM VM
        } elsif ($ibm_vm) {

            undef $ibm_vm;

            if (/^(.*)\s+\---->\s(\S+)$/m) {

                $info{$2}{error} = $1;
                $type = 12;

            }
            ## Rapport Lotus SMTP dans prochain paragraphe
        } elsif (/^-+\s+Failure Reasons\s+-+/m) {

            $lotus = 1;

            ## Rapport Lotus SMTP
        } elsif ($lotus) {

            undef $lotus;

            if (/^(.*)\n(\S+)$/m) {

                $info{$2}{error} = $1;
                $type = 13;

            }
            ## Rapport Sendmail 5 dans prochain paragraphe
        } elsif (/^\-+\sTranscript of session follows\s\-+/m) {

            $sendmail_5 = 1;

            ## Rapport  Sendmail 5
        } elsif ($sendmail_5) {

            undef $sendmail_5;

            if (/<(\S+)>\n\S+, (.*)$/m) {

                $info{$1}{error} = $2;
                $type = 14;

            }
            ## Rapport Smap
        } elsif (/^\s+-+ Transcript of Report follows -+/) {

            my $adr;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^Rejected-For: (\S+),/) {

                    $adr               = $1;
                    $info{$adr}{error} = "";
                    $type              = 17;

                } elsif (/^\s+explanation (.*)$/) {

                    $info{$adr}{error} = $1;

                }
            }
            local $RS = '';

        } elsif (/^\s*-+Message not delivered to the following:/) {

            $type_18 = 1;

        } elsif ($type_18) {

            undef $type_18;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^\s*(\S+)\s+(.*)$/) {

                    $info{$1}{error} = $2;
                    $type = 18;

                }
            }
            local $RS = '';

        } elsif (/unable to deliver following mail to recipient\(s\):/m) {

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^\d+ <(\S+)>\.{3} (.+)$/) {

                    $info{$1}{error} = $2;
                    $type = 19;

                }
            }
            local $RS = '';

            ## Rapport de Yahoo dans paragraphe suivant
        } elsif (/^Unable to deliver message to the following address\(es\)/m)
        {

            $yahoo = 1;

            ## Rapport Yahoo
        } elsif ($yahoo) {

            undef $yahoo;

            if (/^<(\S+)>:\s(.+)$/m) {

                $info{$1}{error} = $2;
                $type = 20;

            }

        } elsif (/^Content-Description: Session Transcript/m) {

            $type_21 = 1;

        } elsif ($type_21) {

            undef $type_21;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/<(\S+)>\.{3} (.*)$/) {

                    $info{$1}{error} = $2;
                    $type = 21;

                }
            }
            local $RS = '';

        } elsif (
            /^Your message has encountered delivery problems\s+to local user \S+\.\s+\(Originally addressed to (\S+)\)/m
            or
            /^Your message has encountered delivery problems\s+to (\S+)\.$/m
            or
            /^Your message has encountered delivery problems\s+to the following recipient\(s\):\s+(\S+)$/m
        ) {

            my $adr = $2 || $1;
            $info{$adr}{error} = "";
            $type = 22;

        } elsif (/^(The user return_address (\S+) does not exist)/) {

            $info{$2}{error} = $1;
            $type = 23;

            ## Rapport Exim paragraphe suivant
        } elsif (
            /^A message that you sent could not be delivered to (all|one or more) of its/m
            or /(^|permanent error. )The following address\(es\) failed:/m) {

            $exim = 1;

            ## Rapport Exim
        } elsif ($exim) {

            undef $exim;

            if (/^\s*(\S+):\s+(.*)$/m) {

                $info{$1}{error} = $2;
                $type = 24;

            } elsif (/^\s*(\S+)\n+\s*(.*)$/m) {
                my ($exim_user, $exim_msg) = ($1, $2);
                if ($exim_msg =~ /MTP error.*: \d\d\d (\d\.\d\.\d) \w/i) {
                    $info{$exim_user}{error} = $1;
                } elsif ($exim_msg =~ /MTP error.*: (\d)\d\d \w/i) {
                    $info{$exim_user}{error} =
                        ($1 eq "5") ? "5.1.1" : "4.2.2";
                }
                $type = 24;

            } elsif (/^\s*(\S+)$/m) {
                $info{$1}{error} = "";
            }

            ## Rapport VINES-ISMTP par. suivant
        } elsif (/^Message not delivered to recipients below/m) {

            $vines = 1;

            ## Rapport VINES-ISMTP
        } elsif ($vines) {

            undef $vines;

            if (/^\s+\S+:.*\s+(\S+)$/m) {

                $info{$1}{error} = "";
                $type = 25;

            }

            ## Rapport Mercury 1.43 par. suivant
        } elsif (
            /^The local mail transport system has reported the following problems/m
        ) {

            $mercury_143 = 1;

            ## Rapport Mercury 1.43
        } elsif ($mercury_143) {

            undef $mercury_143;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/<(\S+)>\s+(.*)$/) {

                    $info{$1}{error} = $2;
                    $type = 26;
                }
            }
            local $RS = '';

            ## Rapport de AltaVista Mail dans paragraphe suivant
        } elsif (/unable to deliver mail to the following recipient\(s\):/m) {

            $altavista = 1;

            ## Rapport AltaVista Mail
        } elsif ($altavista) {

            undef $altavista;

            if (/^(\S+):\n.*\n\s*(.*)$/m) {

                $info{$1}{error} = $2;
                $type = 27;

            }

            ## Rapport SMTP32
        } elsif (/^(User mailbox exceeds allowed size): (\S+)$/m) {

            $info{$2}{error} = $1;
            $type = 28;

        } elsif (/^The following recipients did not receive this message:$/m)
        {

            $following_recipients = 1;

        } elsif ($following_recipients) {

            undef $following_recipients;

            if (/^\s+<(\S+)>/) {

                $info{$1}{error} = "";
                $type = 29;

            }

            ## Rapport Mercury 1.31 par. suivant
        } elsif (
            /^One or more addresses in your message have failed with the following/m
        ) {

            $mercury_131 = 1;

            ## Rapport Mercury 1.31
        } elsif ($mercury_131) {

            undef $mercury_131;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/<(\S+)>\s+(.*)$/) {

                    $info{$1}{error} = $2;
                    $type = 30;
                }
            }
            local $RS = '';

        } elsif (/^The following recipients haven\'t received this message:/m)
        {

            $type_31 = 1;

        } elsif ($type_31) {

            undef $type_31;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/(\S+)$/) {

                    $info{$1}{error} = "";
                    $type = 31;
                }
            }
            local $RS = '';

        } elsif (/^The following destination addresses were unknown/m) {

            $type_32 = 1;

        } elsif ($type_32) {

            undef $type_32;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/<(\S+)>/) {

                    $info{$1}{error} = "";
                    $type = 32;
                }
            }
            local $RS = '';

        } elsif (/^-+Transcript of session follows\s-+$/m) {

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^(\S+)$/) {

                    $info{$1}{error} = "";
                    $type = 33;

                } elsif (/<(\S+)>\.{3} (.*)$/) {

                    $info{$1}{error} = $2;
                    $type = 33;

                }
            }
            local $RS = '';

            ## Rapport Bigfoot
        } elsif (/^The message you tried to send to <(\S+)>/m) {
            $info{$1}{error} = "destination mailbox unavailable";

        } elsif (/^The destination mailbox (\S+) is unavailable/m) {

            $info{$1}{error} = "destination mailbox unavailable";

        } elsif (
            /^The following message could not be delivered because the address (\S+) does not exist/m
        ) {

            $info{$1}{error} = "user unknown";

        } elsif (/^Error-For:\s+(\S+)\s/) {

            $info{$1}{error} = "";

            ## Rapport Exim 1.73 dans proc. paragraphe
        } elsif (
            /^The address to which the message has not yet been delivered is:/m
        ) {

            $exim_173 = 1;

            ## Rapport Exim 1.73
        } elsif ($exim_173) {

            undef $exim_173;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/(\S+)/) {

                    $info{$1}{error} = "";
                    $type = 37;
                }
            }
            local $RS = '';

        } elsif (
            /^This Message was undeliverable due to the following reason:/m) {

            $type_38 = 1;

        } elsif ($type_38) {

            undef $type_38 if /Recipient:/;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/\s+Recipient:\s+<(\S+)>/) {

                    $info{$1}{error} = "";
                    $type = 38;

                } elsif (/\s+Reason:\s+<(\S+)>\.{3} (.*)/) {

                    $info{$1}{error} = $2;
                    $type = 38;

                }
            }
            local $RS = '';

        } elsif (/Your message could not be delivered to:/m) {

            $type_39 = 1;

        } elsif ($type_39) {

            undef $type_39;

            if (/^(\S+)/) {

                $info{$1}{error} = "";
                $type = 39;

            }
        } elsif (/Session Transcription follow:/m) {

            if (/^<+\s+\d+\s+(.*) for \((.*)\)$/m) {

                $info{$2}{error} = $1;
                $type = 43;

            }

        } elsif (
            /^This message was returned to you for the following reasons:/m) {

            $type_40 = 1;

        } elsif ($type_40) {

            undef $type_40;

            if (/^\s+(.*): (\S+)/) {

                $info{$2}{error} = $1;
                $type = 40;

            }

            ## Rapport PMDF dans proc. paragraphe
        } elsif (
            /^Your message cannot be delivered to the following recipients:/m
            or
            /^Your message has been enqueued and undeliverable for \d day\s*to the following recipients/m
        ) {

            $pmdf = 1;

            ## Rapport PMDF
        } elsif ($pmdf) {

            my $adr;
            undef $pmdf;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/\s+Recipient address:\s+(\S+)/) {

                    $adr               = $1;
                    $info{$adr}{error} = "";
                    $type              = 41;

                } elsif (/\s+Reason:\s+(.*)$/) {

                    $info{$adr}{error} = $1;
                    $type = 41;

                }
            }
            local $RS = '';

            ## Rapport MDaemon
        } elsif (/^(\S+) - (no such user here)\.$/m) {

            $info{$1}{error} = $2;
            $type = 42;

            # Postfix dans le prochain paragraphe
        } elsif (/^This is the Postfix program/m
            || /^This is the mail system at host/m) {
            $postfix = 1;
            ## Rapport Postfix
        } elsif ($postfix) {

            undef $postfix
                if /THIS IS A WARNING/;    # Pas la peine de le traiter

            if (/^<(\S+)>:\s(.*)/m) {
                my ($addr, $error) = ($1, $2);

                if ($error =~ /^host\s[^:]*said:\s(\d+)/) {
                    $info{$addr}{error} = $1;
                } elsif ($error =~ /^([^:]+):/) {
                    $info{$addr}{error} = $1;
                } else {
                    $info{$addr}{error} = $error;
                }
            }
            local $RS = '';
        } elsif (
            /^The message that you sent was undeliverable to the following:/)
        {

            $groupwise7 = 1;

        } elsif ($groupwise7) {

            undef $groupwise7;

            ## Parcour du paragraphe
            my @paragraphe = split /\n/, $_;
            local $RS = "\n";
            foreach (@paragraphe) {

                if (/^\s+(\S*) \((.+)\)/) {

                    $info{$1}{error} = $2;

                }
            }

            local $RS = '';

            ## Wanadoo
        } elsif (/^(\S+); Action: Failed; Status: \d.\d.\d \((.*)\)/m) {
            $info{$1}{error} = $2;
        }
    }

    my $count = 0;
    ## On met les adresses au clair
    foreach my $a1 (keys %info) {

        next unless ($a1 and ref($info{$a1}));

        $count++;
        my ($a2, $a3);

        $a2 = $a1;

        unless (!$info{$a1}{expanded}
            or ($a1 =~ /\@/ and $info{$a1}{expanded} !~ /\@/)) {

            $a2 = $info{$a1}{expanded};

        }

        $a3 = _corrige($a2, $$from);
        $a3 =~ y/[A-Z]/[a-z]/;
        $a3 =~ s/^<(.*)>$/$1/;

        if ($info{$a1}{error}) {
            my $status = _canonicalize_status(lc($info{$a1}{error}));
            $result->{$a3} = $status if $status;
        }
    }

    return $count;
}

# Set error message to a status RFC 1893 compliant
# Old name: _canonicalize_status() in bounced.pl.
sub _canonicalize_status {

    my $status = shift;

    if ($status !~ /^\d+\.\d+\.\d+$/) {
        if ($equiv{$status}) {
            $status = $equiv{$status};
        } else {
            return undef;
        }
    }
    return $status;
}

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
