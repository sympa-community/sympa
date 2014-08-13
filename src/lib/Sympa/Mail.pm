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

package Sympa::Mail;

use strict;
use warnings;
use DateTime;
use Encode qw();
use MIME::EncWords;
use POSIX qw();

use Sympa::Bulk;
use Conf;
use Log;
use Sympa::Message;
use Sympa::Robot;
use tools;
use tt2;

my $opensmtp = 0;
my $fh       = 'fh0000000000';    ## File handle for the stream.

my $max_arg = eval { POSIX::_SC_ARG_MAX(); };
if ($@) {
    $max_arg = 4096;
    printf STDERR <<'EOF', $max_arg;
Your system does not conform to the POSIX P1003.1 standard, or
your Perl system does not define the _SC_ARG_MAX constant in its POSIX
library. You must modify the smtp.pm module in order to set a value
for variable %s.

EOF
} else {
    $max_arg = POSIX::sysconf($max_arg);
}

my %pid = ();

my $send_spool;    ## for calling context

our $log_smtp;     # SMTP logging is enabled or not

### PUBLIC FUNCTIONS ###

####################################################
# public set_send_spool
####################################################
# set in global $send_spool, the concerned spool for
# sending message when it is not done by smtpto
#
# IN : $spool (+): spool concerned by sending
# OUT :
#
####################################################
sub set_send_spool {
    my $spool = pop;

    $send_spool = $spool;
}

#sub mail_file($robot, $filename, $rcpt, $data, $return_message_as_string);
##DEPRECATED: Use Sympa::Message->new_from_template() & sending().

####################################################
# public mail_message
####################################################
# distribute a message to a list, Crypting if needed
#
# IN : -$message(+) : ref(Sympa::Message)
#      -$from(+) : message from
#      -$robot(+) : robot
#      -@rcpt(+) : recepients
# OUT : -$numsmtp : number of sendmail process | undef
#
####################################################
sub mail_message {

    my %params      = @_;
    my $message     = $params{'message'};
    my $list        = $params{'list'};
    my @rcpt        = @{$params{'rcpt'}};
    my $tag_as_last = $params{'tag_as_last'};

    my $robot = $list->{'domain'};

    unless (ref $message and $message->isa('Sympa::Message')) {
        Log::do_log('err', 'Invalid message parameter');
        return undef;
    }

    # normal return_path (ie used if VERP is not enabled)
    my $from = $list->get_list_address('return_path');

    Log::do_log(
        'debug',
        '(%s, from=%s, filename=%s, smime_crypted=%s, rcpt=%d, last=%s)',
        $message,
        $from,
        $message->{'filename'},
        $message->{'smime_crypted'},
        scalar(@rcpt),
        $tag_as_last
    );
    return 0 unless @rcpt;

    my ($i, $j, $nrcpt);
    my $size    = 0;
    my $numsmtp = 0;

    my %rcpt_by_dom;

    my @sendto;
    my @sendtobypacket;

    my $cmd_size =
        length(Conf::get_robot_conf($robot, 'sendmail')) + 1 +
        length(Conf::get_robot_conf($robot, 'sendmail_args')) +
        length(' -N success,delay,failure -V ') + 32 +
        length(" -f $from ");
    my $db_type = $Conf::Conf{'db_type'};

    while (defined($i = shift(@rcpt))) {
        my @k = reverse split /[\.@]/, $i;
        my @l = reverse split /[\.@]/, (defined $j ? $j : '@');

        my $dom;
        if ($i =~ /\@(.*)$/) {
            $dom = $1;
            chomp $dom;
        }
        $rcpt_by_dom{$dom} += 1;
        Log::do_log(
            'debug2',
            'Domain: %s; rcpt by dom: %s; limit for this domain: %s',
            $dom,
            $rcpt_by_dom{$dom},
            $Conf::Conf{'nrcpt_by_domain'}{$dom}
        );

        if (
            # number of recipients by each domain
            (   defined $Conf::Conf{'nrcpt_by_domain'}{$dom}
                and $rcpt_by_dom{$dom} >= $Conf::Conf{'nrcpt_by_domain'}{$dom}
            )
            or
            # number of different domains
            (       $j
                and $#sendto >= Conf::get_robot_conf($robot, 'avg')
                and lc "$k[0] $k[1]" ne lc "$l[0] $l[1]"
            )
            or
            # number of recipients in general, and ARG_MAX limitation
            (   $#sendto >= 0
                and (  $cmd_size + $size + length($i) + 5 > $max_arg
                    or $nrcpt >= Conf::get_robot_conf($robot, 'nrcpt'))
            )
            or
            # length of recipients field stored into bulkmailer table
            # (these limits might be relaxed by future release of Sympa)
            ($db_type eq 'mysql' and $size + length($i) + 5 > 65535)
            or
            ($db_type !~ /^(mysql|SQLite)$/ and $size + length($i) + 5 > 500)
            ) {
            undef %rcpt_by_dom;
            # do not replace this line by "push @sendtobypacket, \@sendto" !!!
            my @tab = @sendto;
            push @sendtobypacket, \@tab;
            $numsmtp++;
            $nrcpt = $size = 0;
            @sendto = ();
        }

        $nrcpt++;
        $size += length($i) + 5;
        push(@sendto, $i);
        $j = $i;
    }

    if ($#sendto >= 0) {
        $numsmtp++;
        my @tab = @sendto;
        # do not replace this line by push @sendtobypacket, \@sendto !!!
        push @sendtobypacket, \@tab;
    }

    # Shelve personalization.
    $message->{shelved}{merge} = 1
        if tools::smart_eq($list->{'admin'}{'merge_feature'}, 'on');

    # Since message for each recipient should be encrypted by bulk mailer,
    # check if encryption will be successful.
    if ($message->{'smime_crypted'}) {
        foreach my $bulk_of_rcpt (@sendtobypacket) {
            foreach my $email (@{$bulk_of_rcpt}) {
                if ($email !~ /@/) {
                    Log::do_log('err',
                        'incorrect call for encrypt with incorrect number of recipient'
                    );
                    return undef;
                }

                my $new_message = $message->dup;
                unless ($new_message->smime_encrypt($email)) {
                    Log::do_log(
                        'err',
                        'Unable to encrypt message to list %s for recipient %s',
                        $list,
                        $email
                    );
                    return undef;
                }
            }
        }

        $message->{shelved}{smime_encrypt} = 1;
    }

    # if not specified, delivery time is right now (used for sympa messages
    # etc.)
    my $delivery_date =
           $list->get_next_delivery_date
        || $message->{'date'}
        || time;

    return $numsmtp
        if sending(
        $message, \@sendtobypacket, $from,
        'priority'      => $list->{'admin'}{'priority'},
        'delivery_date' => $delivery_date,
        'use_bulk'      => 1,
        'tag_as_last'   => $tag_as_last
        );

    return undef;
}

####################################################
# public mail_forward
####################################################
# forward a message.
#
# IN : -$mmessage(+) : ref(Sympa::Message)
#      -$from(+) : message from
#      -$rcpt(+) : ref(SCALAR) | ref(ARRAY)  - recepients
#      -$robot(+) : robot
# OUT : 1 | undef
#
####################################################
sub mail_forward {
    my ($message, $from, $rcpt, $robot) = @_;
    Log::do_log('debug2', '(%s, %s)', $from, $rcpt);

    unless (ref $message eq 'Sympa::Message') {
        Log::do_log('err', 'Unexpected parameter type: %s', ref $message);
        return undef;
    }
    ## Add an Auto-Submitted header field according to
    ## http://www.tools.ietf.org/html/draft-palme-autosub-01
    $message->add_header('Auto-Submitted', 'auto-forwarded');

    unless (
        defined sending(
            $message, $rcpt, $from,
            'priority' => Conf::get_robot_conf($robot, 'request_priority'),
        )
        ) {
        Log::do_log('err', 'From %s impossible to send', $from);
        return undef;
    }
    return 1;
}

#####################################################################
# public reaper
#####################################################################
# Non blocking function called by : Sympa::Mail::smtpto(), sympa::main_loop
#  task_manager::INFINITE_LOOP scanning the queue,
#  bounced::infinite_loop scanning the queue,
# just to clean the defuncts list by waiting to any processes and
#  decrementing the counter.
#
# IN : $block
# OUT : $i
#####################################################################
sub reaper {
    my $block = shift;
    my $i;

    $block = 1 unless (defined($block));
    while (($i = waitpid(-1, $block ? POSIX::WNOHANG() : 0)) > 0) {
        $block = 1;
        if (!defined($pid{$i})) {
            Log::do_log('debug2', 'Reaper waited %s, unknown process to me',
                $i);
            next;
        }
        $opensmtp--;
        delete($pid{$i});
    }
    Log::do_log(
        'debug2',
        'Reaper unwaited pids: %s Open = %s',
        join(' ', sort keys %pid), $opensmtp
    );
    return $i;
}

#DEPRECATED.  Use mail_message().
#sub sendto;

####################################################
# sending
####################################################
# send a message using smpto function or puting it
# in spool according to the context
# Signing if needed
#
#
# IN : -$message: ref(Sympa::Message) - message to be sent
#      -$rcpt: SCALAR | ref(ARRAY) - recipients for SMTP "RCPT To:" field.
#      -$from: for SMTP, "MAIL From:" field; for spool sending, "X-Sympa-From"
#              field
#      -use_bulk => boolean
#
# OUT : 1 - call to smtpto (sendmail) | 0 - push in spool
#           | undef
#
####################################################
sub sending {
    my $message = shift;
    my $rcpt    = shift;
    my $from    = shift;
    my %params  = @_;

    my $that = $message->{context};
    my ($robot_id, $listname);
    if (ref $that eq 'Sympa::List') {
        $robot_id = $that->{'domain'};
        $listname = $that->{'name'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $priority_message = $params{'priority'};
    my $priority_packet =
        Conf::get_robot_conf($robot_id, 'sympa_packet_priority');
    my $delivery_date = $params{'delivery_date'};
    $delivery_date = time() unless ($delivery_date);
    my $use_bulk    = $params{'use_bulk'};
    my $tag_as_last = $params{'tag_as_last'};
    my $sympa_file;
    my $fh;

    if ($use_bulk) {
        # in that case use bulk tables to prepare message distribution
        my $bulk_code = Sympa::Bulk::store(
            'message'          => $message,
            'rcpts'            => $rcpt,
            'from'             => $from,
            'robot'            => $robot_id,
            'listname'         => $listname,
            'priority_message' => $priority_message,
            'priority_packet'  => $priority_packet,
            'delivery_date'    => $delivery_date,
            'tag_as_last'      => $tag_as_last,
        );

        unless (defined $bulk_code) {
            Log::do_log('err', 'Failed to store message for list %s',
                $listname);
            Sympa::Robot::send_notify_to_listmaster('bulk_error', $robot_id,
                {'listname' => $listname});
            return undef;
        }
    } elsif (defined $send_spool) {
        # in context wwsympa.fcgi do not send message to reciepients but copy
        # it to standard spool
        Log::do_log('debug', "NOT USING BULK");

        my $sympa_email = Conf::get_robot_conf($robot_id, 'sympa');
        $sympa_file =
            "$send_spool/T.$sympa_email." . time . '.' . int(rand(10000));
        unless (open TMP, ">$sympa_file") {
            Log::do_log('notice', 'Cannot create %s: %s', $sympa_file, $!);
            return undef;
        }

        my $all_rcpt;
        if (ref($rcpt) eq 'SCALAR') {
            $all_rcpt = $$rcpt;
        } elsif (ref($rcpt) eq 'ARRAY') {
            $all_rcpt = join(',', @{$rcpt});
        } else {
            $all_rcpt = $rcpt;
        }

        $message->{'rcpt'}            = $all_rcpt;
        $message->{'envelope_sender'} = $from;
        $message->{'checksum'}        = tools::sympa_checksum($all_rcpt);

        printf TMP $message->to_string;
        close TMP;
        my $new_file = $sympa_file;
        $new_file =~ s/T\.//g;

        unless (rename $sympa_file, $new_file) {
            Log::do_log('notice', 'Cannot rename %s to %s: %s',
                $sympa_file, $new_file, $!);
            return undef;
        }
    } else {    # send it now
        Log::do_log('debug', "NOT USING BULK");
        *SMTP = smtpto($from, $rcpt, $robot_id);

        # Send message stripping Return-Path pseudo-header field.
        my $msg_string = $message->as_string;
        $msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;

        print SMTP $msg_string;
        unless (close SMTP) {
            Log::do_log('err', 'Could not close safefork to sendmail');
            return undef;
        }
    }
    return 1;
}

##############################################################################
# smtpto
##############################################################################
# Makes a sendmail ready for the recipients given as argument, uses a file
# descriptor in the smtp table which can be imported by other parties.
# Before, waits for number of children process < number allowed by sympa.conf
#
# IN : $from :(+) for SMTP "MAIL From:" field
#      $rcpt :(+) ref(SCALAR)|ref(ARRAY)- for SMTP "RCPT To:" field
#      $robot :(+) robot
#      $msgkey : a id of this message submission in notification table
# OUT : Sympa::Mail::$fh - file handle on opened file for ouput, for SMTP "DATA"
# field
#       | undef
#
##############################################################################
sub smtpto {
    Log::do_log('debug2', '(%s, %s, %s, %s)', @_);
    my ($from, $rcpt, $robot, $msgkey) = @_;

    unless ($from) {
        Log::do_log('err', 'Missing Return-Path');
    }

    if (ref($rcpt) eq 'SCALAR') {
        Log::do_log('debug2', '(%s, %s)', $from, $$rcpt);
    } elsif (ref($rcpt) eq 'ARRAY') {
        Log::do_log('debug2', '(%s, %s)', $from, join(',', @{$rcpt}));
    }

    my ($pid, $str);

    ## Escape "-" at beginning of recepient addresses
    ## prevent sendmail from taking it as argument

    if (ref($rcpt) eq 'SCALAR') {
        $$rcpt =~ s/^-/\\-/;
    } elsif (ref($rcpt) eq 'ARRAY') {
        my @emails = @$rcpt;
        foreach my $i (0 .. $#emails) {
            $rcpt->[$i] =~ s/^-/\\-/;
        }
    }

    ## Check how many open smtp's we have, if too many wait for a few
    ## to terminate and then do our job.

    Log::do_log('debug3', 'Open = %s', $opensmtp);
    while ($opensmtp > Conf::get_robot_conf($robot, 'maxsmtp')) {
        Log::do_log('debug3', 'Too many open SMTP (%s), calling reaper',
            $opensmtp);
        last if (reaper(0) == -1);    ## Blocking call to the reaper.
    }

    *IN  = ++$fh;
    *OUT = ++$fh;

    if (!pipe(IN, OUT)) {
        die "Unable to create a channel in smtpto: $!";
        ## No return
    }
    $pid = tools::safefork();
    $pid{$pid} = 0;

    my $sendmail      = Conf::get_robot_conf($robot, 'sendmail');
    my $sendmail_args = Conf::get_robot_conf($robot, 'sendmail_args');
    if ($msgkey) {
        $sendmail_args .= ' -N success,delay,failure -V ' . $msgkey;
    }
    if ($pid == 0) {

        close(OUT);
        open(STDIN, "<&IN");

        $from = '' if $from eq '<>';    # null sender
        if (!ref($rcpt)) {
            exec $sendmail, split(/\s+/, $sendmail_args), '-f', $from, $rcpt;
        } elsif (ref($rcpt) eq 'SCALAR') {
            exec $sendmail, split(/\s+/, $sendmail_args), '-f', $from, $$rcpt;
        } elsif (ref($rcpt) eq 'ARRAY') {
            exec $sendmail, split(/\s+/, $sendmail_args), '-f', $from, @$rcpt;
        }

        exit 1;                         ## Should never get there.
    }
    if ($log_smtp) {
        $str = "safefork: $sendmail $sendmail_args -f '$from' ";
        if (!ref($rcpt)) {
            $str .= $rcpt;
        } elsif (ref($rcpt) eq 'SCALAR') {
            $str .= $$rcpt;
        } else {
            $str .= join(' ', @$rcpt);
        }
        Log::do_log('notice', '%s', $str);
    }
    unless (close(IN)) {
        Log::do_log('err', 'Could not close safefork');
        return undef;
    }
    $opensmtp++;
    select(undef, undef, undef, 0.3)
        if ($opensmtp < Conf::get_robot_conf($robot, 'maxsmtp'));
    return ("Sympa::Mail::$fh");    ## Symbol for the write descriptor.
}

#XXX NOT USED
####################################################
# send_in_spool      : not used but if needed ...
####################################################
# send a message by putting it in global $send_spool
#
# IN : $rcpt (+): ref(SCALAR)|ref(ARRAY) - recepients
#      $robot(+) : robot
#      $sympa_email : for the file name
#      $XSympaFrom : for "X-Sympa-From" field
# OUT : $return->
#        -filename : name of temporary file
#         needing to be renamed
#        -fh : file handle opened for writing
#         on
####################################################
sub send_in_spool {
    my ($rcpt, $robot, $sympa_email, $XSympaFrom) = @_;
    Log::do_log('debug3', '(%s, %s, %s)', $XSympaFrom, $rcpt);

    unless ($sympa_email) {
        $sympa_email = Conf::get_robot_conf($robot, 'sympa');
    }

    unless ($XSympaFrom) {
        $XSympaFrom = Conf::get_robot_conf($robot, 'sympa');
    }

    my $sympa_file =
        "$send_spool/T.$sympa_email." . time . '.' . int(rand(10000));

    my $all_rcpt;
    if (ref($rcpt) eq "ARRAY") {
        $all_rcpt = join(',', @$rcpt);
    } else {
        $all_rcpt = $$rcpt;
    }

    unless (open TMP, ">$sympa_file") {
        Log::do_log('notice', 'Cannot create %s: %s', $sympa_file, $!);
        return undef;
    }

    printf TMP "X-Sympa-To: %s\n",       $all_rcpt;
    printf TMP "X-Sympa-From: %s\n",     $XSympaFrom;
    printf TMP "X-Sympa-Checksum: %s\n", tools::sympa_checksum($all_rcpt);

    my $return;
    $return->{'filename'} = $sympa_file;
    $return->{'fh'}       = \*TMP;

    return $return;
}

#DEPRECATED: Use Sympa::Message::reformat_utf8_message().
#sub reformat_message($;$$);

#DEPRECATED. Moved to Sympa::Message::_fix_utf8_parts as internal functioin.
#sub fix_part;

1;
