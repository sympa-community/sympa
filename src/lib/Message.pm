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

=encoding utf-8

=head1 NAME 

I<Message.pm> - mail message embedding for internal use in Sympa

=head1 DESCRIPTION 

While processing a message in Sympa, we need to link informations to rhe message, mdify headers and such. This was quite a problem when a message was signed, as modifying anything in the message body would alter its MD5 footprint. And probably make the message to be rejected by clients verifying its identity (which is somehow a good thing as it is the reason why people use MD5 after all). With such messages, the process was complex. We then decided to embed any message treated in a "Message" object, thus making the process easier.

=cut 

package Message;

use strict;
use warnings;
use Mail::Address;
use MIME::Charset;
use MIME::EncWords;
use MIME::Parser;

use Conf;
use List;
use Log;
use tools;
use tt2;

=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by Message.pm

=cut 

=pod 

=head2 sub new

Creates a new Message object.

=head3 Arguments 

=over 

=item * I<$pkg>, a package name 

=item * I<$file>, the message file

=item * I<$noxsympato>, a boolean

=back 

=head3 Return 

=over 

=item * I<a Message object>, if created

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * Log::do_log()

=item * Conf::get_robot_conf

=item * List::new

=item * Mail::Address::parse

=item * MIME::EncWords::decode_mimewords

=item * MIME::Entity::as_string

=item * MIME::Head::get

=item * MIME::Parser::output_to_core

=item * MIME::Parser::read

=item * tools::valid_email

=item * tools::smime_decrypt

=item * tools::smime_sign_check

=back 

=cut 

## Creates a new object
sub new {

    my $pkg   = shift;
    my $datas = shift;

    my $file             = $datas->{'file'};
    my $noxsympato       = $datas->{'noxsympato'};
    my $messageasstring  = $datas->{'messageasstring'};
    my $mimeentity       = $datas->{'mimeentity'};
    my $message_in_spool = $datas->{'message_in_spool'};

    my $message;
    Log::do_log('debug2', 'Message::new(%s,%s)', $file, $noxsympato);

    if ($mimeentity) {
        $message->{'msg'}     = $mimeentity;
        $message->{'altered'} = '_ALTERED';

        ## Bless Message object
        bless $message, $pkg;

        return $message;
    }

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);

    my $msg;

    if ($message_in_spool) {
        $messageasstring         = $message_in_spool->{'messageasstring'};
        $message->{'messagekey'} = $message_in_spool->{'messagekey'};
        $message->{'spoolname'}  = $message_in_spool->{'spoolname'};
    }
    if ($file) {
        ## Parse message as a MIME::Entity
        $message->{'filename'} = $file;
        unless (open FILE, $file) {
            Log::do_log('err', 'Cannot open message file %s : %s', $file, $!);
            return undef;
        }

        # unless ($msg = $parser->read(\*FILE)) {
        #    Log::do_log('err', 'Unable to parse message %s', $file);
        #    close(FILE);
        #    return undef;
        #}
        while (<FILE>) {
            $messageasstring = $messageasstring . $_;
        }
        close(FILE);
    }
    if ($messageasstring) {
        if (ref($messageasstring)) {
            $msg = $parser->parse_data($messageasstring);
        } else {
            $msg = $parser->parse_data(\$messageasstring);
        }
    }

    unless ($msg) {
        Log::do_log('err', 'Unable to parse message from file %s, skipping.',
            $file);
        return undef;
    }

    $message->{'msg'}           = $msg;
    $message->{'msg_as_string'} = $msg->as_string;
    $message->{'size'}          = length($msg->as_string);

    my $hdr = $message->{'msg'}->head;

    $message->{'envelope_sender'} = _get_envelope_sender($message);
    ($message->{'sender'}, $message->{'gecos'}) = _get_sender_email($message);
    return undef unless defined $message->{'sender'};

    ## Store decoded subject and its original charset
    my $subject = $hdr->get('Subject');
    if (defined $subject and $subject =~ /\S/) {
        my @decoded_subject = MIME::EncWords::decode_mimewords($subject);
        $message->{'subject_charset'} = 'US-ASCII';
        foreach my $token (@decoded_subject) {
            unless ($token->[1]) {
                # don't decode header including raw 8-bit bytes.
                if ($token->[0] =~ /[^\x00-\x7F]/) {
                    $message->{'subject_charset'} = undef;
                    last;
                }
                next;
            }
            my $cset = MIME::Charset->new($token->[1]);
            # don't decode header encoded with unknown charset.
            unless ($cset->decoder) {
                $message->{'subject_charset'} = undef;
                last;
            }
            unless ($cset->output_charset eq 'US-ASCII') {
                $message->{'subject_charset'} = $token->[1];
            }
        }
    } else {
        $message->{'subject_charset'} = undef;
    }
    if ($message->{'subject_charset'}) {
        $message->{'decoded_subject'} = tools::decode_header($hdr, 'Subject');
    } else {
        if ($subject) {
            chomp $subject;
            $subject =~ s/(\r\n|\r|\n)(?=[ \t])//g;
            $subject =~ s/\r\n|\r|\n/ /g;
        }
        $message->{'decoded_subject'} = $subject;
    }

    ## Extract recepient address (X-Sympa-To)
    $message->{'rcpt'} = $hdr->get('X-Sympa-To');
    chomp $message->{'rcpt'} if defined $message->{'rcpt'};
    unless (defined $noxsympato) {
        # message.pm can be used not only for message comming from queue
        unless ($message->{'rcpt'}) {
            Log::do_log('err',
                'no X-Sympa-To found, ignoring message file %s', $file);
            return undef;
        }

        ## get listname & robot
        my ($listname, $robot) = split(/\@/, $message->{'rcpt'});

        $robot    = lc($robot);
        $listname = lc($listname);
        $robot ||= $Conf::Conf{'domain'};
        my $spam_status =
            Scenario::request_action('spam_status', 'smtp', $robot,
            {'message' => $message});
        $message->{'spam_status'} = 'unkown';
        if (defined $spam_status) {
            if (ref($spam_status) eq 'HASH') {
                $message->{'spam_status'} = $spam_status->{'action'};
            } else {
                $message->{'spam_status'} = $spam_status;
            }
        }

        my $conf_email = Conf::get_robot_conf($robot, 'email');
        my $conf_host  = Conf::get_robot_conf($robot, 'host');
        unless ($listname =~
            /^(sympa|$Conf::Conf{'listmaster_email'}|$conf_email)(\@$conf_host)?$/i
            ) {
            my $list_check_regexp =
                Conf::get_robot_conf($robot, 'list_check_regexp');
            if ($listname =~ /^(\S+)-($list_check_regexp)$/) {
                $listname = $1;
            }

            my $list = List->new($listname, $robot, {'just_try' => 1});
            if ($list) {
                $message->{'list'} = $list;
            }
        }
        # verify DKIM signature
        if (Conf::get_robot_conf($robot, 'dkim_feature') eq 'on') {
            $message->{'dkim_pass'} =
                tools::dkim_verifier($message->{'msg_as_string'});
        }
    }

    ## valid X-Sympa-Checksum prove the message comes from web interface with
    ## authenticated sender
    if ($hdr->get('X-Sympa-Checksum')) {
        my $chksum = $hdr->get('X-Sympa-Checksum');
        chomp $chksum;
        my $rcpt = $hdr->get('X-Sympa-To');
        chomp $rcpt;

        if ($chksum eq tools::sympa_checksum($rcpt)) {
            $message->{'md5_check'} = 1;
        } else {
            Log::do_log('err', "incorrect X-Sympa-Checksum header");
        }
    }

    ## S/MIME
    if ($Conf::Conf{'openssl'}) {

        ## Decrypt messages
        if (   ($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i)
            && ($hdr->get('Content-Type') !~ /signed-data/)) {
            my ($dec, $dec_as_string) =
                tools::smime_decrypt($message->{'msg'}, $message->{'list'});

            unless (defined $dec) {
                Log::do_log('debug', "Message %s could not be decrypted",
                    $file);
                return undef;
                ## We should the sender and/or the listmaster
            }

            $message->{'smime_crypted'} = 'smime_crypted';
            $message->{'orig_msg'}      = $message->{'msg'};
            $message->{'msg'}           = $dec;
            $message->{'msg_as_string'} = $dec_as_string;
            $hdr                        = $dec->head;
            Log::do_log('debug', "message %s has been decrypted", $file);
        }

        ## Check S/MIME signatures
        if ($hdr->get('Content-Type') =~
            /multipart\/signed|application\/(x-)?pkcs7-mime/i) {
            $message->{'protected'} =
                1;    ## Messages that should not be altered (no footer)
            my $signed = tools::smime_sign_check($message);
            if ($signed->{'body'}) {
                $message->{'smime_signed'}  = 1;
                $message->{'smime_subject'} = $signed->{'subject'};
                Log::do_log('debug',
                    "message %s is signed, signature is checked", $file);
            }
            ## Il faudrait traiter les cas d'erreur (0 différent de undef)
        }
    }
    ## TOPICS
    my $topics;
    if ($topics = $hdr->get('X-Sympa-Topic')) {
        $message->{'topic'} = $topics;
    }

    bless $message, $pkg;
    return $message;
}

## Get envelope sender (a.k.a. "UNIX From") from Return-Path: header field.
##
## We trust in "Return-Path:" header field only at the top of message
## to prevent forgery.  To ensure it will be added to messages by MDA:
##
## - Sendmail:   Add 'P' in the 'F=' flags of local mailer line (such
##               as 'Mlocal').
## - Postfix:
##   - local(8): Available by default.
##   - pipe(8):  Add 'R' in the 'flags=' attributes in master.cf.
## - Exim:       Set 'return_path_add' to true with pipe_transport.
## - qmail:      Use preline(1).
##
sub _get_envelope_sender {
    my $message = shift;

    my $headers = $message->{'msg'}->head->header();
    my $i       = 0;
    $i++ while $headers->[$i] and $headers->[$i] =~ /^X-Sympa-/;
    if ($headers->[$i] and $headers->[$i] =~ /^Return-Path:\s*(.+)$/) {
        my $addr = $1;
        if ($addr =~ /<>/) {    # special: null envelope sender
            return '<>';
        } else {
            my @addrs = Mail::Address->parse($addr);
            if (@addrs and tools::valid_email($addrs[0]->address)) {
                return $addrs[0]->address;
            }
        }
    }

    return undef;
}

## Get sender of the message according to header fields specified by
## 'sender_headers' parameter.
## FIXME: S/MIME signer may not be same as the sender given by this function.
sub _get_sender_email {
    my $message = shift;

    my $hdr = $message->{'msg'}->head;

    my $sender = undef;
    my $gecos  = undef;
    foreach my $field (split /[\s,]+/, $Conf::Conf{'sender_headers'}) {
        if (lc $field eq 'return-path') {
            ## Try to get envelope sender
            if (    $message->{'envelope_sender'}
                and $message->{'envelope_sender'} ne '<>') {
                $sender = lc($message->{'envelope_sender'});
            }
        } elsif ($hdr->get($field)) {
            ## Try to get message header.
            ## On "Resent-*:" headers, the first occurrence must be used (see
            ## RFC 5322 3.6.6).
            ## FIXME: Though "From:" can occur multiple times, only the first
            ## one is detected.
            my $addr = $hdr->get($field, 0);               # get the first one
            my @sender_hdr = Mail::Address->parse($addr);
            if (@sender_hdr and $sender_hdr[0]->address) {
                $sender = lc($sender_hdr[0]->address);
                my $phrase = $sender_hdr[0]->phrase;
                if (defined $phrase and length $phrase) {
                    $gecos = MIME::EncWords::decode_mimewords($phrase,
                        Charset => 'UTF-8');
                }
                last;
            }
        }

        last if defined $sender;
    }
    unless (defined $sender) {
        Log::do_log('err', 'No valid sender address');
        return undef;
    }
    unless (tools::valid_email($sender)) {
        Log::do_log('err', 'Invalid sender address "%s"', $sender);
        return undef;
    }

    return ($sender, $gecos);
}

=pod 

=head2 sub dump

Dump a Message object to a stream.

=head3 Arguments 

=over 

=item * I<$self>, the Message object to dump

=item * I<$output>, the stream to which dump the object

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Dump the Message object
sub dump {
    my ($self, $output) = @_;
#    my $output ||= \*STDERR;

    my $old_output = select;
    select $output;

    foreach my $key (keys %{$self}) {
        if (ref($self->{$key}) eq 'MIME::Entity') {
            printf "%s =>\n", $key;
            $self->{$key}->print;
        } else {
            printf "%s => %s\n", $key, $self->{$key};
        }
    }

    select $old_output;

    return 1;
}

=pod 

=head2 sub add_topic

Add topic and put header X-Sympa-Topic.

=head3 Arguments 

=over 

=item * I<$self>, the Message object to which add a topic

=item * I<$output>, the string containing the topic to add

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * MIME::Head::add

=back 

=cut 

## Add topic and put header X-Sympa-Topic
sub add_topic {
    my ($self, $topic) = @_;

    $self->{'topic'} = $topic;
    my $hdr = $self->{'msg'}->head;
    $hdr->add('X-Sympa-Topic', $topic);

    return 1;
}

=pod 

=head2 sub add_topic

Add topic and put header X-Sympa-Topic.

=head3 Arguments 

=over 

=item * I<$self>, the Message object whose topic is retrieved

=back 

=head3 Return 

=over 

=item * I<the topic>, if it exists

=item * I<empty string>, otherwise

=back 

=head3 Calls 

=over 

=item * MIME::Head::add

=back 

=cut 

## Get topic
sub get_topic {
    my ($self) = @_;

    if (defined $self->{'topic'}) {
        return $self->{'topic'};

    } else {
        return '';
    }
}

sub clean_html {
    my $self  = shift;
    my $robot = shift;
    my $new_msg;
    if ($new_msg = _fix_html_part($self->{'msg'}, $robot)) {
        $self->{'msg'} = $new_msg;
        return 1;
    }
    return 0;
}

sub _fix_html_part {
    my $part  = shift;
    my $robot = shift;
    return $part unless $part;

    my $eff_type = $part->head->mime_attr("Content-Type");
    if ($part->parts) {
        my @newparts = ();
        foreach ($part->parts) {
            push @newparts, _fix_html_part($_, $robot);
        }
        $part->parts(\@newparts);
    } elsif ($eff_type =~ /^text\/html/i) {
        my $bodyh = $part->bodyhandle;
        # Encoded body or null body won't be modified.
        return $part if !$bodyh or $bodyh->is_encoded;

        my $body = $bodyh->as_string;
        # Re-encode parts to UTF-8, since StripScripts cannot handle texts
        # with some charsets (ISO-2022-*, UTF-16*, ...) correctly.
        my $cset =
            MIME::Charset->new($part->head->mime_attr('Content-Type.Charset')
                || '');
        unless ($cset->decoder) {
            # Charset is unknown.  Detect 7-bit charset.
            my ($dummy, $charset) =
                MIME::Charset::body_encode($body, '', Detect7Bit => 'YES');
            $cset = MIME::Charset->new($charset)
                if $charset;
        }
        if (    $cset->decoder
            and $cset->as_string ne 'UTF-8'
            and $cset->as_string ne 'US-ASCII') {
            $cset->encoder('UTF-8');
            $body = $cset->encode($body);
            $part->head->mime_attr('Content-Type.Charset', 'UTF-8');
        }

        my $filtered_body =
            tools::sanitize_html('string' => $body, 'robot' => $robot);

        my $io = $bodyh->open("w");
        unless (defined $io) {
            Log::do_log('err', "Failed to save message : $!");
            return undef;
        }
        $io->print($filtered_body);
        $io->close;
        $part->sync_headers(Length => 'COMPUTE');
    }
    return $part;
}

1;

=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier SalaE<252>n <os AT cru.fr> 

=back 

=cut 
