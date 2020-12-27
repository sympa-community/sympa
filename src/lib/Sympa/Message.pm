# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::Message;

use strict;
use warnings;
use DateTime;
use Encode qw();
use English;    # FIXME: drop $PREMATCH usage
use HTML::TreeBuilder;
use Mail::Address;
use MIME::Charset;
use MIME::EncWords;
use MIME::Entity;
use MIME::Field::ParamVal;
use MIME::Parser;
use MIME::Tools;
use Scalar::Util qw();
use Text::LineFold;
use URI::Escape qw();

BEGIN { eval 'use Crypt::SMIME'; }
BEGIN { eval 'use Net::DNS'; }

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::HTML::FormatText;
use Sympa::HTMLSanitizer;
use Sympa::Language;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Spool;
use Sympa::Template;
use Sympa::Tools::Data;
use Sympa::Tools::File;
use Sympa::Tools::Password;
use Sympa::Tools::SMIME;
use Sympa::Tools::Text;
use Sympa::User;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

sub new {
    $log->syslog('debug2', '(%s, ...)', @_);
    my $class      = shift;
    my $serialized = shift;

    my $self = bless {@_} => $class;

    unless (defined $serialized and length $serialized) {
        $log->syslog('err', 'Empty message');
        return undef;
    }

    # Get attributes from pseudo-header fields at the top of serialized
    # message.  Note that field names are case-sensitive.

    pos($serialized) = 0;
    while ($serialized =~ /\G(X-Sympa-[-\w]+): (.*?)\n(?![ \t])/cgs) {
        my ($k, $v) = ($1, $2);
        next unless length $v;

        if ($k eq 'X-Sympa-To') {
            $self->{'rcpt'} = join ',', split(/\s*,\s*/, $v);
        } elsif ($k eq 'X-Sympa-Checksum') {    # To migrate format <= 6.2a.40
            $self->{'checksum'} = $v;
        } elsif ($k eq 'X-Sympa-Family') {
            $self->{'family'} = $v;
        } elsif ($k eq 'X-Sympa-From') {    # Compatibility. Use Return-Path:
            $self->{'envelope_sender'} = $v;
        } elsif ($k eq 'X-Sympa-Auth-Level') {    # New in 6.2a.41
            if ($v eq 'md5') {
                $self->{'md5_check'} = 1;
            } else {
                $log->syslog('err',
                    'Unknown authentication level "%s", ignored', $v);
            }
        } elsif ($k eq 'X-Sympa-Message-ID') {    # New in 6.2a.41
            $self->{'message_id'} = $v;
        } elsif ($k eq 'X-Sympa-Sender') {        # New in 6.2a.41
            $self->{'sender'} = $v;
        } elsif ($k eq 'X-Sympa-Display-Name') {    # New in 6.2a.41
            $self->{'gecos'} = $v;
        } elsif ($k eq 'X-Sympa-Shelved') {         # New in 6.2a.41
            $self->{'shelved'} = {
                map {
                    my ($ak, $av) = split /=/, $_, 2;
                    ($ak => ($av || 1))
                } split(/\s*;\s*/, $v)
            };
        } elsif ($k eq 'X-Sympa-Spam-Status') {     # New in 6.2a.41
            $self->{'spam_status'} = $v;
        } else {
            $log->syslog('err', 'Unknown attribute information: "%s: %s"',
                $k, $v);
        }
    }
    # Ignore Unix From_
    $serialized =~ /\GFrom (.*?)\n(?![ \t])/cgs;
    # Get envelope sender from Return-Path:.
    # If old style X-Sympa-From: has been found, omit Return-Path:.
    #
    # We trust in "Return-Path:" header field only at the top of message
    # to prevent forgery.  See CAVEAT.
    if ($serialized =~ /\GReturn-Path: (.*?)\n(?![ \t])/cgs
        and not exists $self->{'envelope_sender'}) {
        my $addr = $1;
        if ($addr =~ /<>/) {    # special: null envelope sender
            $self->{'envelope_sender'} = '<>';
        } elsif ($addr =~ /<MAILER-DAEMON>/) {
            # Same as above, but a workaround for pipe(8) of Postfix 2.3+.
            $self->{'envelope_sender'} = '<>';
        } else {
            my @addrs = Mail::Address->parse($addr);
            if (@addrs
                and Sympa::Tools::Text::valid_email($addrs[0]->address)) {
                $self->{'envelope_sender'} = $addrs[0]->address;
            }
        }
    }
    # Strip attributes.
    substr($serialized, 0, pos $serialized) = '';

    # Check if message is parsable.

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    my $entity = $parser->parse_data(\$serialized);
    unless ($entity) {
        $log->syslog('err', 'Unable to parse message');
        return undef;
    }
    my $hdr = $entity->head;
    my ($dummy, $body_string) = split /(?:\A|\n)\r?\n/, $serialized, 2;

    $self->{_head}         = $hdr;
    $self->{_body}         = $body_string;
    $self->{_entity_cache} = $entity;
    $self->{'size'}        = length $serialized;

    unless (exists $self->{'sender'} and defined $self->{'sender'}) {
        ($self->{'sender'}, $self->{'gecos'}) = $self->_get_sender_email;
    }

    ## Store decoded subject and its original charset
    my $subject = $hdr->get('Subject');
    if (defined $subject and $subject =~ /\S/) {
        my @decoded_subject = MIME::EncWords::decode_mimewords($subject);
        $self->{'subject_charset'} = 'US-ASCII';
        foreach my $token (@decoded_subject) {
            unless ($token->[1]) {
                # don't decode header including raw 8-bit bytes.
                if ($token->[0] =~ /[^\x00-\x7F]/) {
                    $self->{'subject_charset'} = undef;
                    last;
                }
                next;
            }
            my $cset = MIME::Charset->new($token->[1]);
            # don't decode header encoded with unknown charset.
            unless ($cset->decoder) {
                $self->{'subject_charset'} = undef;
                last;
            }
            unless ($cset->output_charset eq 'US-ASCII') {
                $self->{'subject_charset'} = $token->[1];
            }
        }
    } else {
        $self->{'subject_charset'} = undef;
    }
    if ($self->{'subject_charset'}) {
        chomp $subject;
        $self->{'decoded_subject'} =
            MIME::EncWords::decode_mimewords($subject, Charset => 'UTF-8');
    } else {
        if (defined $subject) {
            chomp $subject;
            $subject =~ s/(\r\n|\r|\n)(?=[ \t])//g;
            $subject =~ s/\r\n|\r|\n/ /g;
        }
        $self->{'decoded_subject'} = $subject;
    }

    ## TOPICS
    my $topics;
    if ($topics = $hdr->get('X-Sympa-Topic')) {
        $self->{'topic'} = $topics;
    }

    # Message ID
    unless (exists $self->{'message_id'}) {
        $self->{'message_id'} = _get_message_id($self);
    }

    return $self;
}

# Tentative: removed when refactoring finished.
sub new_from_file {
    my $class = shift;
    my $file  = shift;

    open my $fh, '<', $file or return undef;
    my $serialized = do { local $RS; <$fh> };
    close $fh;

    my $self = $class->new($serialized, @_)
        or return undef;

    $self->{'filename'} = $file;
    # Get file date
    unless (exists $self->{'date'}) {
        $self->{'date'} = Sympa::Tools::File::get_mtime($file);
    }

    return $self;
}

## Get sender of the message according to header fields specified by
## 'sender_headers' parameter.
## FIXME: S/MIME signer may not be same as the sender given by this function.
sub _get_sender_email {
    my $self = shift;

    my $hdr = $self->{_head};

    my $sender = undef;
    my $gecos  = undef;
    foreach my $field (split /[\s,]+/, $Conf::Conf{'sender_headers'}) {
        if (lc $field eq 'return-path') {
            ## Try to get envelope sender
            if (    $self->{'envelope_sender'}
                and $self->{'envelope_sender'} ne '<>') {
                $sender = lc($self->{'envelope_sender'});
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
                    # Eliminate hostile characters.
                    $gecos =~ s/(\r\n|\r|\n)(?=[ \t])//g;
                    $gecos =~ s/[\0\r\n]+//g;
                }
                last;
            }
        }

        last if defined $sender;
    }
    unless (defined $sender) {
        #$log->syslog('debug3', 'No valid sender address');
        return;
    }
    unless (Sympa::Tools::Text::valid_email($sender)) {
        $log->syslog('err', 'Invalid sender address "%s"', $sender);
        return;
    }

    return ($sender, $gecos);
}

# Note that this must be called after decrypting message
# FIXME: Also check Resent-Message-ID:.
sub _get_message_id {
    my $self = shift;

    return Sympa::Tools::Text::canonic_message_id(
        $self->{_head}->get('Message-Id', 0));
}

# Old names: (part of) mail::mail_file(), mail::parse_tt2_messageasstring(),
# List::send_file(), List::send_global_file().
# Moved to: Sympa::Message::Template::new().
#sub new_from_template;

sub dup {
    my $self = shift;

    my $clone = {};
    foreach my $key (sort keys %$self) {
        my $val = $self->{$key};
        next unless defined $val;

        unless (Scalar::Util::blessed($val)) {
            $clone->{$key} = Sympa::Tools::Data::dup_var($val);
        } elsif ($val->can('dup') and !$val->isa('Sympa::List')) {
            $clone->{$key} = $val->dup;
        } else {
            $clone->{$key} = $val;
        }
    }

    return bless $clone => ref($self);
}

sub to_string {
    my $self    = shift;
    my %options = @_;

    my $serialized = '';
    if (ref $self->{'rcpt'} eq 'ARRAY' and @{$self->{'rcpt'}}) {
        $serialized .= sprintf "X-Sympa-To: %s\n",
            join(',', @{$self->{'rcpt'}});
    } elsif (defined $self->{'rcpt'} and length $self->{'rcpt'}) {
        $serialized .= sprintf "X-Sympa-To: %s\n",
            join(',', split(/\s*,\s*/, $self->{'rcpt'}));
    }
    if (defined $self->{'checksum'}) {
        $serialized .= sprintf "X-Sympa-Checksum: %s\n", $self->{'checksum'};
    }
    if (defined $self->{'family'}) {
        $serialized .= sprintf "X-Sympa-Family: %s\n", $self->{'family'};
    }
    if (defined $self->{'md5_check'}
        and length $self->{'md5_check'}) {    # New in 6.2a.41
        $serialized .= sprintf "X-Sympa-Auth-Level: %s\n", 'md5';
    }
    if (defined $self->{'message_id'}) {      # New in 6.2a.41
        $serialized .= sprintf "X-Sympa-Message-ID: %s\n",
            $self->{'message_id'};
    }
    if (defined $self->{'sender'}) {          # New in 6.2a.41
        $serialized .= sprintf "X-Sympa-Sender: %s\n", $self->{'sender'};
    }
    if (defined $self->{'gecos'}
        and length $self->{'gecos'}) {        # New in 6.2a.41
        $serialized .= sprintf "X-Sympa-Display-Name: %s\n", $self->{'gecos'};
    }
    if (%{$self->{'shelved'} || {}}) {        # New in 6.2a.41
        $serialized .= sprintf "X-Sympa-Shelved: %s\n", join(
            '; ',
            map {
                my $v = $self->{shelved}{$_};
                ("$v" eq '1') ? $_ : sprintf('%s=%s', $_, $v);
                }
                grep {
                $self->{shelved}{$_}
                } sort keys %{$self->{shelved}}
        );
    }
    if (defined $self->{'spam_status'}) {     # New in 6.2a.41.
        $serialized .= sprintf "X-Sympa-Spam-Status: %s\n",
            $self->{'spam_status'};
    }
    # This terminates pseudo-header part for attributes.
    unless (defined $self->{'envelope_sender'}) {
        $serialized .= "Return-Path: \n";
    }

    $serialized .= $self->as_string(%options);

    return $serialized;
}

sub add_header {
    my $self = shift;
    $self->{_head}->add(@_);
    delete $self->{_entity_cache};    # Clear entity cache.
}

sub delete_header {
    my $self = shift;
    $self->{_head}->delete(@_);
    delete $self->{_entity_cache};    # Clear entity cache.
}

sub replace_header {
    my $self = shift;
    $self->{_head}->replace(@_);
    delete $self->{_entity_cache};    # Clear entity cache.
}

sub head {
    shift->{_head};
}

# NOTE: As this processes is needed for incoming messages only, it would be
# moved to incoming pipeline class..
sub check_spam_status {
    my $self = shift;

    my $robot_id =
        (ref $self->{context} eq 'Sympa::List')
        ? $self->{context}->{'domain'}
        : $self->{context};

    my $spam_status =
        Sympa::Scenario->new($robot_id, 'spam_status')
        ->authz('smtp', {'message' => $self});
    if (defined $spam_status) {
        if (ref($spam_status) eq 'HASH') {
            $self->{'spam_status'} = $spam_status->{'action'};
        } else {
            $self->{'spam_status'} = $spam_status;
        }
    } else {
        $self->{'spam_status'} = 'unknown';
    }
}

my $has_mail_dkim_textwrap;

BEGIN {
    eval 'use Mail::DKIM::Signer';
    # This doesn't export $VERSION.
    eval 'use Mail::DKIM::TextWrap';
    $has_mail_dkim_textwrap = !$EVAL_ERROR;
    # Mail::DKIM::Signer prior to 0.38 doesn't import this.
    eval 'use Mail::DKIM::PrivateKey';
    eval 'use Mail::DKIM::ARC::Signer';
}

# Old name: tools::dkim_sign() which took string and returned string.
sub dkim_sign {
    $log->syslog('debug', '(%s)', @_);
    my $self    = shift;
    my %options = @_;

    my $dkim_d          = $options{'dkim_d'};
    my $dkim_i          = $options{'dkim_i'};
    my $dkim_selector   = $options{'dkim_selector'};
    my $dkim_privatekey = $options{'dkim_privatekey'};

    unless ($dkim_selector) {
        $log->syslog('err',
            "DKIM selector is undefined, could not sign message");
        return undef;
    }
    unless ($dkim_privatekey) {
        $log->syslog('err',
            "DKIM key file is undefined, could not sign message");
        return undef;
    }
    unless ($dkim_d) {
        $log->syslog('err',
            "DKIM d= tag is undefined, could not sign message");
        return undef;
    }

    unless ($Mail::DKIM::Signer::VERSION) {
        $log->syslog('err',
            "Failed to load Mail::DKIM::Signer Perl module, ignoring DKIM signature"
        );
        return undef;
    }
    unless ($has_mail_dkim_textwrap) {
        $log->syslog('err',
            "Failed to load Mail::DKIM::TextWrap Perl module, signature will not be pretty"
        );
    }

    # DKIM::PrivateKey does never allow armour texts nor newlines.  Strip them.
    my $privatekey_string = join '',
        grep { !/^---/ and $_ } split /\r\n|\r|\n/, $dkim_privatekey;
    my $privatekey = Mail::DKIM::PrivateKey->load(Data => $privatekey_string);
    unless ($privatekey) {
        $log->syslog('err', 'Can\'t create Mail::DKIM::PrivateKey');
        return undef;
    }
    # create a signer object
    my $dkim = Mail::DKIM::Signer->new(
        Algorithm => "rsa-sha256",
        Method    => "relaxed",
        Domain    => $dkim_d,
        Selector  => $dkim_selector,
        Key       => $privatekey,
        ($dkim_i ? (Identity => $dkim_i) : ()),
    );
    unless ($dkim) {
        $log->syslog('err', 'Can\'t create Mail::DKIM::Signer');
        return undef;
    }
    # $new_body will store the body as fed to Mail::DKIM to reuse it
    # when returning the message as string.  Line terminators must be
    # normalized with CRLF.
    my $msg_as_string = $self->as_string;
    $msg_as_string =~ s/\r?\n/\r\n/g;
    $msg_as_string =~ s/\r?\z/\r\n/ unless $msg_as_string =~ /\n\z/;
    $dkim->PRINT($msg_as_string);
    unless ($dkim->CLOSE) {
        $log->syslog('err', 'Cannot sign (DKIM) message');
        return undef;
    }

    my ($dummy, $new_body) = split /\r\n\r\n/, $msg_as_string, 2;
    $new_body =~ s/\r\n/\n/g;

    # Mail::DKIM::Signer wraps DKIM-Signature with with \r\n\t; this
    # is the hardcoded Separator passed to Mail::DKIM::TextWrap via
    # Mail::DKIM::KeyValueList. MIME::Tools on the other hand
    # (MIME::Head::stringify() in particular) encode EOL as plain \n;
    # so it is necessary to normalize CRLF->LF for DKIM-Signature to
    # avoid confusing the mail agent.

    my $dkim_signature = $dkim->signature->as_string;
    $dkim_signature =~ s/\r\n/\n/g;

    # Signing is done. Rebuilding message as string with original body
    # and new headers.
    # Note that DKIM-Signature: field should be prepended to the header.
    $self->add_header('DKIM-Signature', $dkim_signature, 0);
    $self->{_body} = $new_body;
    delete $self->{_entity_cache};    # Clear entity cache.

    return $self;
}

sub arc_seal {
    $log->syslog('debug2', '(%s)', @_);
    my $self    = shift;
    my %options = @_;

    my $arc_d          = $options{'arc_d'};
    my $arc_selector   = $options{'arc_selector'};
    my $arc_privatekey = $options{'arc_privatekey'};
    my $arc_srvid      = $options{'arc_srvid'};
    my $arc_cv         = $options{'arc_cv'};

    unless ($arc_selector) {
        $log->syslog('err',
            "ARC selector is undefined, could not seal message");
        return undef;
    }
    unless ($arc_privatekey) {
        $log->syslog('err',
            "ARC key file is undefined, could not seal message");
        return undef;
    }
    unless ($arc_d) {
        $log->syslog('err',
            "ARC d= tag is undefined, could not seal message");
        return undef;
    }

    unless ($arc_cv =~ m{^(none|pass|fail)$}) {
        $log->syslog('err',
            "ARC chain value %s is invalid, could not seal message", $arc_cv);
        return undef;
    }

    unless ($Mail::DKIM::ARC::Signer::VERSION) {
        $log->syslog('err',
            "Failed to load Mail::DKIM::ARC::Signer Perl module, no seal added"
        );
        return undef;
    }

    # DKIM::PrivateKey does never allow armour texts nor newlines.  Strip them.
    my $privatekey_string = join '',
        grep { !/^---/ and $_ } split /\r\n|\r|\n/, $arc_privatekey;
    my $privatekey = Mail::DKIM::PrivateKey->load(Data => $privatekey_string);
    unless ($privatekey) {
        $log->syslog('err', 'Can\'t create Mail::DKIM::PrivateKey');
        return undef;

    }

    # create a signer object
    my $arc = Mail::DKIM::ARC::Signer->new(
        Algorithm => "rsa-sha256",
        Chain     => $arc_cv,
        SrvId     => $arc_srvid,
        Domain    => $arc_d,
        Selector  => $arc_selector,
        Key       => $privatekey,
    );
    unless ($arc) {
        $log->syslog('err', 'Can\'t create Mail::DKIM::ARC::Signer');
        return undef;
    }
    # $new_body will store the body as fed to Mail::DKIM to reuse it
    # when returning the message as string.  Line terminators must be
    # normalized with CRLF.
    my $msg_as_string = $self->as_string;
    $msg_as_string =~ s/\r?\n/\r\n/g;
    $msg_as_string =~ s/\r?\z/\r\n/ unless $msg_as_string =~ /\n\z/;
    unless (eval { $arc->PRINT($msg_as_string) and $arc->CLOSE }) {
        $log->syslog('err', 'Cannot ARC seal message: %s', $EVAL_ERROR);
        return undef;
    }
    $log->syslog('debug2', 'ARC %s: %s', $arc->{result},
        $arc->{result_reason});

    # don't need this since DKIM just did it
    #    my ($dummy, $new_body) = split /\r\n\r\n/, $msg_as_string, 2;
    #$new_body =~ s/\r\n/\n/g;

    # Seal is done. Add new headers for the seal
    my @seal = $arc->as_strings();
    if (grep { $_ and /\AARC-Seal:/i } @seal) {
        foreach my $ahdr (reverse @seal) {
            my ($ah, $av) = split /:\s*/, $ahdr, 2;
            $self->add_header($ah, $av, 0);
        }
    }
    #$self->{_body} = $new_body;
    delete $self->{_entity_cache};    # Clear entity cache.

    return $self;
}

BEGIN {
    eval 'use Mail::DKIM::Verifier';
    eval 'use Mail::DKIM::ARC::Verifier';
}

sub check_dkim_signature {
    my $self = shift;

    return unless $Mail::DKIM::Verifier::VERSION;

    my $robot_id =
        (ref $self->{context} eq 'Sympa::List') ? $self->{context}->{'domain'}
        : (ref $self->{context} eq 'Sympa::Family')
        ? $self->{context}->{'domain'}
        : $self->{context};

    return
        unless Sympa::Tools::Data::smart_eq(
        Conf::get_robot_conf($robot_id || '*', 'dkim_feature'), 'on');

    my $dkim;
    unless ($dkim = Mail::DKIM::Verifier->new()) {
        $log->syslog('err', 'Could not create Mail::DKIM::Verifier');
        return;
    }

    # Line terminators must be normalized with CRLF.
    my $msg_as_string = $self->as_string;
    $msg_as_string =~ s/\r?\n/\r\n/g;
    $msg_as_string =~ s/\r?\z/\r\n/ unless $msg_as_string =~ /\n\z/;
    $dkim->PRINT($msg_as_string);
    unless ($dkim->CLOSE) {
        $log->syslog('err', 'Cannot verify signature of (DKIM) message');
        return;
    }

    #FIXME: Identity of signatures would be checked.
    foreach my $signature ($dkim->signatures) {
        if ($signature->result_detail eq 'pass') {
            $self->{'dkim_pass'} = 1;
            return;
        }
    }
    delete $self->{'dkim_pass'};
}

sub check_arc_chain {
    my $self = shift;

    return unless $Mail::DKIM::ARC::Verifier::VERSION;

    my $robot_id =
        (ref $self->{context} eq 'Sympa::List')
        ? $self->{context}->{'domain'}
        : $self->{context};
    my $srvid;
    unless ($srvid = Conf::get_robot_conf($robot_id || '*', 'arc_srvid')) {
        $log->syslog('debug2', 'ARC library installed, but no arc_srvid set');
        return;
    }

    # if there is no authentication-results, not much point in checking ARC
    # since we can't add a new seal

    my @ars =
        grep { my $d = $_->param('_'); $d and lc $d eq lc $srvid }
        map { MIME::Field::ParamVal->parse($_) }
        $self->get_header('Authentication-Results');

    unless (@ars) {
        $log->syslog('debug2',
            'ARC enabled but no Authentication-Results: %s;', $srvid);
        return;
    }
    # already checked?
    foreach my $ar (@ars) {
        my $param_arc = $ar->param('arc');
        if ($param_arc and $param_arc =~ m{\A(pass|fail|none)\b}i) {
            $self->{shelved}->{arc_cv} = $1;
            $log->syslog('debug2', 'ARC already checked: %s', $param_arc);
            return;
        }
    }

    my $arc;
    unless ($arc = Mail::DKIM::ARC::Verifier->new(Strict => 1)) {
        $log->syslog('err', 'Could not create Mail::DKIM::ARC::Verifier');
        return;
    }

    # Line terminators must be normalized with CRLF.
    my $msg_as_string = $self->as_string;
    $msg_as_string =~ s/\r?\n/\r\n/g;
    $msg_as_string =~ s/\r?\z/\r\n/ unless $msg_as_string =~ /\n\z/;
    unless (eval { $arc->PRINT($msg_as_string) and $arc->CLOSE }) {
        $log->syslog('err', 'Cannot verify chain of (ARC) message: %s',
            $EVAL_ERROR);
        return;
    }

    $log->syslog('debug2', 'result %s', $arc->result);
    $self->{shelved}->{arc_cv} = $arc->result;
}

# Old name: tools::remove_invalid_dkim_signature() which takes a message as
# string and outputs idem without signature if invalid.
sub remove_invalid_dkim_signature {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    return unless $self->get_header('DKIM-Signature');

    $self->check_dkim_signature;
    unless ($self->{'dkim_pass'}) {
        $log->syslog('info',
            'DKIM signature of message %s is invalid, removing', $self);
        $self->delete_header('DKIM-Signature');
    }
}

sub as_entity {
    my $self = shift;

    unless (defined $self->{_entity_cache}) {
        die 'Bug in logic.  Ask developer' unless $self->{_head};
        my $string =
            $self->{_head}->as_string . "\n"
            . (defined $self->{_body} ? $self->{_body} : '');

        my $parser = MIME::Parser->new();
        $parser->output_to_core(1);
        $parser->tmp_dir($Conf::Conf{'tmpdir'});
        $self->{_entity_cache} = $parser->parse_data(\$string);
    }
    return $self->{_entity_cache};
}

sub set_entity {
    my $self   = shift;
    my $entity = shift;
    return undef unless $entity;

    my $orig = $self->as_entity->as_string;
    my $new  = $entity->as_string;

    if ($orig ne $new) {
        $self->{_head} = $entity->head;
        $self->{_body} = $entity->body_as_string;
        $self->{_entity_cache} = $entity;    # Also update entity cache.
    }

    return $entity;
}

sub as_string {
    my $self    = shift;
    my %options = @_;

    die 'Bug in logic.  Ask developer' unless $self->{_head};

    return $self->{'orig_msg_as_string'}
        if $options{'original'} and $self->{'smime_crypted'};

    my $return_path = '';
    if (defined $self->{'envelope_sender'}) {
        my $val = $self->{'envelope_sender'};
        $val = "<$val>" unless $val eq '<>';
        $return_path = sprintf "Return-Path: %s\n", $val;
    }
    return
          $return_path
        . $self->{_head}->as_string . "\n"
        . (defined $self->{_body} ? $self->{_body} : '');
}

sub body_as_string {
    my $self = shift;
    return $self->{_body};
}

sub header_as_string {
    my $self = shift;
    return $self->{_head}->as_string;
}

sub get_header {
    my $self  = shift;
    my $field = shift;
    my $sep   = shift;
    die sprintf 'Second argument is not index but separator: "%s"', $sep
        if defined $sep and Scalar::Util::looks_like_number($sep);

    my $hdr = $self->{_head};

    if (defined $sep or wantarray) {
        my @values = grep {s/\A$field\s*:\s*//i}
            split /\n(?![ \t])/, $hdr->as_string();
        if (defined $sep) {
            return undef unless @values;
            return join $sep, @values;
        }
        return @values;
    } else {
        my $value = $hdr->get($field, 0);
        chomp $value if defined $value;
        return $value;
    }
}

# Old name: tools::decode_header() which can take Message, MIME::Entity,
# MIME::Head or Mail::Header object as argument.
sub get_decoded_header {
    my $self = shift;
    my $tag  = shift;
    my $sep  = shift;

    my $head = $self->head;

    if (defined $sep) {
        my @values = $head->get($tag);
        return undef unless scalar @values;
        foreach my $val (@values) {
            $val = MIME::EncWords::decode_mimewords($val, Charset => 'UTF-8');
            chomp $val;
        }
        return join $sep, @values;
    } else {
        my $val = $head->get($tag);
        return undef unless defined $val;
        $val = MIME::EncWords::decode_mimewords($val, Charset => 'UTF-8');
        chomp $val;
        return $val;
    }
}

# Dump the Message object
# Currently not used.
sub dump {
    my ($self, $output) = @_;
    # my $output ||= \*STDERR;

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

## Add topic and put header X-Sympa-Topic
# OBSOLETED.  No longer used.
sub add_topic {
    my ($self, $topic) = @_;

    $self->{'topic'} = $topic;
    $self->add_header('X-Sympa-Topic', $topic);
}

## Get topic
# OBSOLETED.  No longer used.
sub get_topic {
    my ($self) = @_;

    if (defined $self->{'topic'}) {
        return $self->{'topic'};

    } else {
        return '';
    }
}

sub clean_html {
    my $self = shift;

    my $robot =
        (ref $self->{context} eq 'Sympa::List')
        ? $self->{context}->{'domain'}
        : $self->{context};

    my $entity = $self->as_entity->dup;
    if ($entity = _fix_html_part($entity, $robot)) {
        $self->set_entity($entity);
        return 1;
    }
    return 0;
}

sub _fix_html_part {
    my $entity = shift;
    my $robot  = shift;
    return $entity unless $entity;

    my $eff_type = $entity->head->mime_type || '';    # Use real content-type.
    if ($entity->parts) {
        my @newparts = ();
        foreach my $part ($entity->parts) {
            push @newparts, _fix_html_part($part, $robot);
        }
        $entity->parts(\@newparts);
    } elsif ($eff_type eq 'text/html') {
        my $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        return $entity if !$bodyh or $bodyh->is_encoded;

        my $body = $bodyh->as_string;
        # Re-encode parts to UTF-8, since StripScripts cannot handle texts
        # with some charsets (ISO-2022-*, UTF-16*, ...) correctly.
        my $cset = MIME::Charset->new(
            $entity->head->mime_attr('Content-Type.Charset') || '');
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
            $entity->head->mime_attr('Content-Type.Charset', 'UTF-8');
        }

        my $filtered_body =
            Sympa::HTMLSanitizer->new($robot)->sanitize_html($body);

        my $io = $bodyh->open("w");
        unless (defined $io) {
            $log->syslog('err', 'Failed to save message: %m');
            return undef;
        }
        $io->print($filtered_body);
        $io->close;
        $entity->sync_headers(Length => 'COMPUTE')
            if $entity->head->get('Content-Length');
    }
    return $entity;
}

# Old name: tools::smime_decrypt() which took MIME::Entity object and list,
# and won't modify Message object.
sub smime_decrypt {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    return 0 unless $Crypt::SMIME::VERSION;

    my $key_passwd = $Conf::Conf{'key_passwd'};
    $key_passwd = '' unless defined $key_passwd;

    my $content_type = lc($self->{_head}->mime_attr('Content-Type') || '');
    unless (
        (      $content_type eq 'application/pkcs7-mime'
            or $content_type eq 'application/x-pkcs7-mime'
        )
        and !Sympa::Tools::Data::smart_eq(
            $self->{_head}->mime_attr('Content-Type.smime-type'),
            qr/signed-data/i
        )
    ) {
        return 0;
    }

    #FIXME: an empty "context" parameter means mail to sympa@, listmaster@...
    my ($certs, $keys) =
        Sympa::Tools::SMIME::find_keys($self->{context} || '*', 'decrypt');
    unless (defined $certs and @$certs) {
        $log->syslog('err',
            'Unable to decrypt message: missing certificate file');
        return undef;
    }

    my ($msg_string, $entity);

    # Try all keys/certs until one decrypts.
    while (my $certfile = shift @$certs) {
        my $keyfile = shift @$keys;
        $log->syslog('debug', 'Trying decrypt with certificate %s, key %s',
            $certfile, $keyfile);

        my ($cert, $key);
        if (open my $fh, '<', $certfile) {
            $cert = do { local $RS; <$fh> };
            close $fh;
        }
        if (open my $fh, '<', $keyfile) {
            $key = do { local $RS; <$fh> };
            close $fh;
        }

        my $smime = Crypt::SMIME->new();
        if (length $key_passwd) {
            eval { $smime->setPrivateKey($key, $cert, $key_passwd) }
                or next;
        } else {
            eval { $smime->setPrivateKey($key, $cert) }
                or next;
        }
        $msg_string = eval { $smime->decrypt($self->as_string); };
        last if defined $msg_string;
    }

    unless (defined $msg_string) {
        $log->syslog('err', 'Message could not be decrypted');
        return undef;
    }
    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    $entity = $parser->parse_data($msg_string);
    unless (defined $entity) {
        $log->syslog('err', 'Message could not be decrypted');
        return undef;
    }

    my ($dummy, $body_string) = split /(?:\A|\n)\r?\n/, $msg_string, 2;
    my $head = $entity->head;
    # Now remove headers from $msg_string.
    # Keep for each header defined in the incoming message but undefined in
    # the decrypted message, add this header in the decrypted form.
    my $predefined_headers;
    foreach my $header ($head->tags) {
        $predefined_headers->{lc $header} = 1 if $head->get($header);
    }
    foreach my $header (split /\n(?![ \t])/, $self->header_as_string) {
        next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
        my ($tag, $val) = ($1, $2);
        $head->add($tag, $val) unless $predefined_headers->{lc $tag};
    }
    # Some headers from the initial message should not be restored
    # Content-Disposition and Content-Transfer-Encoding if the result is
    # multipart
    $head->delete('Content-Disposition')
        if $self->get_header('Content-Disposition');
    if (Sympa::Tools::Data::smart_eq(
            $head->mime_attr('Content-Type'),
            qr/multipart/i
        )
    ) {
        $head->delete('Content-Transfer-Encoding')
            if $self->get_header('Content-Transfer-Encoding');
    }

    # We should be the sender and/or the listmaster

    $self->{'smime_crypted'}      = 'smime_crypted';
    $self->{'orig_msg_as_string'} = $self->as_string;
    $self->{_head}                = $head;
    $self->{_body}                = $body_string;
    delete $self->{_entity_cache};    # Clear entity cache.
    $log->syslog('debug', 'Message has been decrypted');

    return $self;
}

# Old name: tools::smime_encrypt() which returns stringified message.
sub smime_encrypt {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self  = shift;
    my $email = shift;

    my $msg_header = $self->{_head};

    my $certfile;
    my $entity;

    my $base =
        $Conf::Conf{'ssl_cert_dir'} . '/'
        . Sympa::Tools::Text::escape_chars($email);
    if (-f $base . '@enc') {
        $certfile = $base . '@enc';
    } else {
        $certfile = $base;
    }
    unless (-r $certfile) {
        $log->syslog('notice',
            'Unable to encrypt message to %s (missing certificate %s)',
            $email, $certfile);
        return undef;
    }

    my $cert;
    if (open my $fh, '<', $certfile) {
        $cert = do { local $RS; <$fh> };
        close $fh;
    }

    # encrypt the incoming message parse it.
    my $smime = Crypt::SMIME->new();
    #FIXME: Add intermediate CA certificates if any.
    eval { $smime->setPublicKey($cert); };
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Unable to encrypt message to %s: %s',
            $email, $EVAL_ERROR);
        return undef;
    }

    # don't; cf RFC2633 3.1. netscape 4.7 at least can't parse encrypted
    # stuff that contains a whole header again... since MIME::Tools has
    # got no function for this, we need to manually extract only the MIME
    # headers...
    #XXX$msg_header->print(\*MSGDUMP);
    #XXXprintf MSGDUMP "\n%s", $msg_body;
    my $dup_head = $msg_header->dup();
    foreach my $t ($dup_head->tags()) {
        $dup_head->delete($t) unless $t =~ /^(mime|content)-/i;
    }

    #FIXME: is $self->body_as_string respect base64 number of char per line ??
    my $msg_string = eval {
        $smime->encrypt($dup_head->as_string . "\n" . $self->body_as_string);
    };
    unless (defined $msg_string) {
        $log->syslog('err', 'Unable to S/MIME encrypt message: %s',
            $EVAL_ERROR);
        return undef;
    }

    ## Get as MIME object
    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    unless ($entity = $parser->parse_data($msg_string)) {
        $log->syslog('notice', 'Unable to parse message');
        return undef;
    }

    my ($dummy, $body_string) = split /\n\r?\n/, $msg_string, 2;

    # foreach header defined in  the incomming message but undefined in
    # the crypted message, add this header in the crypted form.
    my $predefined_headers;
    foreach my $header ($entity->head->tags) {
        $predefined_headers->{lc $header} = 1
            if $entity->head->get($header);
    }
    foreach my $header (split /\n(?![ \t])/, $msg_header->as_string) {
        next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
        my ($tag, $val) = ($1, $2);
        $entity->head->add($tag, $val)
            unless $predefined_headers->{lc $tag};
    }

    $self->{_head} = $entity->head;
    $self->{_body} = $body_string;
    delete $self->{_entity_cache};    # Clear entity cache.

    return $self;
}

# Old name: tools::smime_sign().
sub smime_sign {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    my $list       = $self->{context};
    my $key_passwd = $Conf::Conf{'key_passwd'};
    $key_passwd = '' unless defined $key_passwd;

    #FIXME
    return 1 unless $list;

    my ($certfile, $keyfile) = Sympa::Tools::SMIME::find_keys($list, 'sign');

    my $signed_msg;

    ## Keep a set of header fields ONLY
    ## OpenSSL only needs content type & encoding to generate a
    ## multipart/signed msg
    my $dup_head = $self->head->dup;
    foreach my $field ($dup_head->tags) {
        next if $field =~ /^(content-type|content-transfer-encoding)$/i;
        $dup_head->delete($field);
    }

    my ($cert, $key);
    if (open my $fh, '<', $certfile) {
        $cert = do { local $RS; <$fh> };
        close $fh;
    }
    if (open my $fh, '<', $keyfile) {
        $key = do { local $RS; <$fh> };
        close $fh;
    }

    my $smime = Crypt::SMIME->new();
    #FIXME: Add intermediate CA certificates if any.
    if (length $key_passwd) {
        $smime->setPrivateKey($key, $cert, $key_passwd);
    } else {
        $smime->setPrivateKey($key, $cert);
    }
    my $msg_string = eval {
        $smime->sign($dup_head->as_string . "\n" . $self->body_as_string);
    };
    unless (defined $msg_string) {
        $log->syslog('err', 'Unable to S/MIME sign message: %s', $EVAL_ERROR);
        return undef;
    }

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    unless ($signed_msg = $parser->parse_data($msg_string)) {
        $log->syslog('notice', 'Unable to parse message');
        return undef;
    }

    ## foreach header defined in  the incoming message but undefined in the
    ## crypted message, add this header in the crypted form.
    my $head = $signed_msg->head;
    my $predefined_headers;
    foreach my $header ($head->tags) {
        $predefined_headers->{lc $header} = 1
            if $head->get($header);
    }
    foreach my $header (split /\n(?![ \t])/, $self->header_as_string) {
        next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
        my ($tag, $val) = ($1, $2);
        $head->add($tag, $val)
            unless $predefined_headers->{lc $tag};
    }

    ## Keeping original message string in addition to updated headers.
    my ($dummy, $body_string) = split /(?:\A|\n)\r?\n/, $msg_string, 2;

    $self->{_head} = $head;
    $self->{_body} = $body_string;
    delete $self->{_entity_cache};    # Clear entity cache.
    $self->check_smime_signature;

    return $self;
}

# Old name: tools::smime_sign_check() or Message::smime_sign_check()
# which won't alter Message object.
sub check_smime_signature {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    return 0 unless $Crypt::SMIME::VERSION;
    return 0 unless $self->is_signed;

    ## Messages that should not be altered (no footer)
    $self->{'protected'} = 1;

    my $sender = $self->{'sender'};

    # First step is to check if message signing is OK.
    my $smime = Crypt::SMIME->new;
    eval {    # Crypt::SMIME >= 0.15 is required.
        $smime->setPublicKeyStore(grep { defined $_ and length $_ }
                ($Conf::Conf{'cafile'}, $Conf::Conf{'capath'}));
    };
    unless (eval { $smime->check($self->as_string) }) {
        $log->syslog('info', '%s: Unable to verify S/MIME signature: %s',
            $self, $EVAL_ERROR);
        return undef;
    }

    # Second step is to check the signer of message matches the sender.
    # We need to check which certificate is for our user (CA and intermediate
    # certs are also included), and look at the purpose:
    # S/MIME signing and/or S/MIME encryption.
    #FIXME: A better analyse should be performed to extract the signer email.
    my %certs;
    my $signers = Crypt::SMIME::getSigners($self->as_string);
    foreach my $cert (@{$signers || []}) {
        my $parsed = Sympa::Tools::SMIME::parse_cert(text => $cert);
        next unless $parsed;
        next unless $parsed->{'email'}{lc $sender};

        if ($parsed->{'purpose'}{'sign'} and $parsed->{'purpose'}{'enc'}) {
            $certs{'both'} = $cert;
            $log->syslog('debug', 'Found a signing + encryption cert');
        } elsif ($parsed->{'purpose'}{'sign'}) {
            $certs{'sign'} = $cert;
            $log->syslog('debug', 'Found a signing cert');
        } elsif ($parsed->{'purpose'}{'enc'}) {
            $certs{'enc'} = $cert;
            $log->syslog('debug', 'Found an encryption cert');
        }
        last if $certs{'both'} or ($certs{'sign'} and $certs{'enc'});
    }
    unless ($certs{both} or $certs{sign} or $certs{enc}) {
        $log->syslog('info', '%s: Could not extract certificate for %s',
            $self, $sender);
        return undef;
    }

    # OK, now we have the certs, either a combined sign+encryption one
    # or a pair of single-purpose. save them, as email@addr if combined,
    # or as email@addr@sign / email@addr@enc for split certs.
    foreach my $c (keys %certs) {
        my $filename = "$Conf::Conf{ssl_cert_dir}/"
            . Sympa::Tools::Text::escape_chars(lc($sender));
        if ($c ne 'both') {
            unlink $filename;    # just in case there's an old cert left...
            $filename .= "\@$c";
        } else {
            unlink("$filename\@enc");
            unlink("$filename\@sign");
        }
        $log->syslog('debug', 'Saving %s cert in %s', $c, $filename);
        my $fh;
        unless (open $fh, '>', $filename) {
            $log->syslog('err', 'Unable to create certificate file %s: %m',
                $filename);
            return undef;
        }
        print $fh $certs{$c};
        close $fh;
    }

    # TODO: Future version should check if the subject of certificate was part
    # of the SMIME signature.
    $self->{'smime_signed'} = 1;
    $log->syslog('debug3', '%s is signed, signature is checked', $self);
    ## Il faudrait traiter les cas d'erreur (0 différent de undef)
    return 1;
}

sub is_signed {
    my $self = shift;

    my $content_type = lc($self->head->mime_attr('Content-Type') // '');
    my $protocol = lc($self->head->mime_attr('Content-Type.protocol') // '');
    my $smime_type =
        lc($self->head->mime_attr('Content-Type.smime-type') // '');
    return 1
        if $content_type eq 'multipart/signed'
        and ($protocol eq 'application/pkcs7-signature'
        or $protocol eq 'application/x-pkcs7-signature');
    return 1
        if ($content_type eq 'application/pkcs7-mime'
        or $content_type eq 'application/x-pkcs7-mime')
        and $smime_type eq 'signed-data';
    return 0;
}

# Old name: Bulk::merge_msg()
sub personalize {
    my $self = shift;
    my $list = shift;
    my $rcpt = shift || undef;
    my $data = shift || {};

    my $content_type = lc($self->{_head}->mime_attr('Content-Type') || '');
    if (   $content_type eq 'multipart/encrypted'
        or $content_type eq 'multipart/signed'
        or $content_type eq 'application/pkcs7-mime'
        or $content_type eq 'application/x-pkcs7-mime') {
        return 1;
    }

    my $entity = $self->as_entity->dup;

    # Initialize parameters at first only once.
    $data->{'headers'} ||= {};
    my $headers = $entity->head;
    foreach my $key (
        qw/subject x-originating-ip message-id date x-original-to from to thread-topic content-type/
    ) {
        next unless $headers->count($key);
        my $value = $headers->get($key, 0);
        chomp $value;
        $value =~ s/(?:\r\n|\r|\n)(?=[ \t])//g;    # unfold
        $data->{'headers'}{$key} = $value;
    }
    $data->{'subject'} = $self->{'decoded_subject'};

    unless (defined _merge_msg($entity, $list, $rcpt, $data)) {
        return undef;
    }

    $self->set_entity($entity);
    return $self;
}

sub _merge_msg {
    my $entity = shift;
    my $list   = shift;
    my $rcpt   = shift;
    my $data   = shift;

    my $enc = $entity->head->mime_encoding;
    # Parts with nonstandard encodings aren't modified.
    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
        return $entity;
    }
    my $eff_type = $entity->effective_type || 'text/plain';
    # Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}) {
        return $entity;
    }

    # Check for attchment-part, which should not be changed
    if ('attachment' eq
        lc($entity->head->mime_attr('Content-Disposition') // '')) {
        return $entity;
    }

    if ($entity->parts) {
        foreach my $part ($entity->parts) {
            unless (_merge_msg($part, $list, $rcpt, $data)) {
                $log->syslog('err', 'Failed to personalize message part');
                return undef;
            }
        }
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {
        # multipart or message types without subparts.
        return $entity;
    } elsif (MIME::Tools::textual_type($eff_type)) {
        my ($charset, $in_cset, $bodyh, $body, $utf8_body);

        my ($descr) = ($entity->head->get('Content-Description', 0));
        chomp $descr if $descr;
        $descr = MIME::EncWords::decode_mimewords($descr, Charset => 'UTF-8');

        $data->{'part'} = {
            description => $descr,
            disposition =>
                lc($entity->head->mime_attr('Content-Disposition') || ''),
            encoding => $enc,
            type     => $eff_type,
        };

        $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        if (!$bodyh or $bodyh->is_encoded) {
            return $entity;
        }

        $body = $bodyh->as_string;
        unless (defined $body and length $body) {
            return $entity;
        }

        ## Detect charset.  If charset is unknown, detect 7-bit charset.
        $charset = $entity->head->mime_attr('Content-Type.Charset');
        $in_cset = MIME::Charset->new($charset || 'NONE');
        unless ($in_cset->decoder) {
            $in_cset =
                MIME::Charset->new(MIME::Charset::detect_7bit_charset($body)
                    || 'NONE');
        }
        unless ($in_cset->decoder) {
            $log->syslog('err', 'Unknown charset "%s"', $charset);
            return undef;
        }
        $in_cset->encoder($in_cset);    # no charset conversion

        ## Only decodable bodies are allowed.
        eval { $utf8_body = Encode::encode_utf8($in_cset->decode($body, 1)); };
        if ($EVAL_ERROR) {
            $log->syslog('err', 'Cannot decode by charset "%s"', $charset);
            return undef;
        }

        ## PARSAGE ##

        my $message_output;
        unless (
            defined(
                $message_output =
                    personalize_text($utf8_body, $list, $rcpt, $data)
            )
        ) {
            $log->syslog('err', 'Error merging message');
            return undef;
        }
        $utf8_body = $message_output;

        ## Data not encodable by original charset will fallback to UTF-8.
        my ($newcharset, $newenc);
        ($body, $newcharset, $newenc) =
            $in_cset->body_encode(Encode::decode_utf8($utf8_body),
            Replacement => 'FALLBACK');
        unless ($newcharset) {    # bug in MIME::Charset?
            $log->syslog('err', 'Can\'t determine output charset');
            return undef;
        } elsif ($newcharset ne $in_cset->as_string) {
            $entity->head->mime_attr('Content-Transfer-Encoding' => $newenc);
            $entity->head->mime_attr('Content-Type.Charset' => $newcharset);

            ## normalize newline to CRLF if transfer-encoding is BASE64.
            $body =~ s/\r\n|\r|\n/\r\n/g
                if $newenc and $newenc eq 'BASE64';
        } else {
            ## normalize newline to CRLF if transfer-encoding is BASE64.
            $body =~ s/\r\n|\r|\n/\r\n/g
                if $enc and uc $enc eq 'BASE64';
        }

        ## Save new body.
        my $io = $bodyh->open('w');
        unless ($io
            and $io->print($body)
            and $io->close) {
            $log->syslog('err', 'Can\'t write in Entity: %m');
            return undef;
        }
        $entity->sync_headers(Length => 'COMPUTE')
            if $entity->head->get('Content-Length');

        return $entity;
    }

    return $entity;
}

# Moved to Sympa::Spindle::AuthorizeMessage::_test_personalize().
#sub test_personalize;

# Old name: Bulk::merge_data()
sub personalize_text {
    my $body = shift;
    my $list = shift;
    my $rcpt = shift;
    my $data = shift || {};

    die 'Unexpected type of $list' unless ref $list eq 'Sympa::List';

    my $listname = $list->{'name'};
    my $robot_id = $list->{'domain'};

    $data->{'listname'} = $listname;
    $data->{'domain'}   = $robot_id;
    $data->{'robot'}    = $data->{'domain'};    # Compat.<=6.2.52.
    $data->{'wwsympa_url'} = Conf::get_robot_conf($robot_id, 'wwsympa_url');

    my $message_output;

    my $user = $list->get_list_member($rcpt);

    if ($user) {
        $user->{'escaped_email'} = URI::Escape::uri_escape($rcpt);
        $user->{'friendly_date'} =
            $language->gettext_strftime("%d %b %Y  %H:%M",
            localtime($user->{'date'}));

        # this method has been removed because some users may forward
        # authentication link
        # $user->{'fingerprint'} = tools::get_fingerprint($rcpt);
    }

    $data->{'user'} = $user if $user;

    # Parse the template in the message : replace the tags and the parameters
    # by the corresponding values
    my $template = Sympa::Template->new(undef);
    return undef
        unless $template->parse($data, \$body, \$message_output,
        is_not_template => 1);

    return $message_output;
}

sub prepare_message_according_to_mode {
    my $self = shift;
    my $mode = shift;
    my $list = shift;

    my $robot_id = $list->{'domain'};

    if (   $mode eq 'nomail'
        or $mode eq 'summary'
        or $mode eq 'digest'
        or $mode eq 'digestplain') {
        ;
    } elsif ($mode eq 'notice') {
        ##Prepare message for notice reception mode
        my $entity = $self->as_entity->dup;

        $entity->bodyhandle(undef);
        $entity->parts([]);
        $self->set_entity($entity);
    } elsif ($mode eq 'txt') {
        ##Prepare message for txt reception mode
        my $entity = $self->as_entity->dup;

        if (_as_singlepart($entity, 'text/plain')) {
            $log->syslog('notice', 'Multipart message changed to singlepart');
        }
        ## Add a footer
        _decorate_parts($entity, $list);
        $self->set_entity($entity);
    } elsif ($mode eq 'urlize') {
        # Prepare message for urlize reception mode.
        # Not extract message/rfc822 parts.
        my $parser = MIME::Parser->new;
        $parser->extract_nested_messages(0);
        $parser->extract_uuencode(1);
        $parser->output_to_core(1);
        $parser->tmp_dir($Conf::Conf{'tmpdir'});

        my $msg_string = $self->as_string;
        $msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;
        my $entity = $parser->parse_data($msg_string);

        _urlize_parts($entity, $list, $self->{'message_id'});
        ## Add a footer
        _decorate_parts($entity, $list);
        $self->set_entity($entity);
    } else {    # 'mail'
        # Prepare message for normal reception mode,
        # and add a footer.
        unless ($self->{'protected'}) {
            my $entity = $self->as_entity->dup;

            _decorate_parts($entity, $list);
            $self->set_entity($entity);
        }
    }

    return $self;
}

# OBSOLETED.  Use prepare_message_according_to_mode('mail').
sub decorate {
    my $self = shift;

    return $self->prepare_message_according_to_mode('mail', $self->{context});
}

# Old name:
# Sympa::List::add_parts() or Message::add_parts(), n.b. not add_part().
sub _decorate_parts {
    $log->syslog('debug3', '(%s, %s)');
    my $entity = shift;
    my $list   = shift;

    my $type = $list->{'admin'}{'footer_type'};
    my $eff_type = $entity->effective_type || 'text/plain';

    ## Signed or encrypted messages won't be modified.
    if ($eff_type =~ /^multipart\/(signed|encrypted)$/i) {
        return $entity;
    }

    my $header =
        ($type eq 'mime')
        && Sympa::search_fullpath($list, 'message_header.mime')
        || Sympa::search_fullpath($list, 'message_header');
    my $footer =
        ($type eq 'mime')
        && Sympa::search_fullpath($list, 'message_footer.mime')
        || Sympa::search_fullpath($list, 'message_footer');
    my $global_footer =
        ($type eq 'mime')
        && Sympa::search_fullpath($list->{'domain'},
        'message_global_footer.mime')
        || Sympa::search_fullpath($list->{'domain'}, 'message_global_footer');
    # No footer/header.
    return
           unless $header and -s $header
        or $footer        and -s $footer
        or $global_footer and -s $global_footer;

    if ($type eq 'append') {
        ## append footer/header
        my ($global_footer_text, $footer_text, $header_text) = ('', '', '');
        if ($header and -s $header) {
            if (open my $fh, '<', $header) {
                $header_text = do { local $RS; <$fh> };
                close $fh;
            }
            $header_text = '' unless $header_text =~ /\S/;
        }
        if ($footer and -s $footer) {
            if (open my $fh, '<', $footer) {
                $footer_text = do { local $RS; <$fh> };
                close $fh;
            }
            $footer_text = '' unless $footer_text =~ /\S/;
        }
        if ($global_footer and -s $global_footer) {
            if (open my $fh, '<', $global_footer) {
                $global_footer_text = do { local $RS; <$fh> };
                close $fh;
            }
            $global_footer_text = '' unless $global_footer_text =~ /\S/;
        }
        if (   length $header_text
            or length $footer_text
            or length $global_footer_text) {
            if (_append_parts(
                    $entity,      $header_text,
                    $footer_text, $global_footer_text
                )
            ) {
                $entity->sync_headers(Length => 'COMPUTE')
                    if $entity->head->get('Content-Length');
            }
        }
    } else {
        ## MIME footer/header
        my $parser = MIME::Parser->new;
        $parser->output_to_core(1);
        $parser->tmp_dir($Conf::Conf{'tmpdir'});

        if (   $eff_type =~ /^multipart\/alternative/i
            || $eff_type =~ /^multipart\/related/i) {
            $log->syslog('debug3', 'Making message %s into multipart/mixed',
                $entity);
            $entity->make_multipart("mixed", Force => 1);
        }

        if ($header and -s $header) {
            my $fh;
            unless (open $fh, '<', $header) {
                ;
            } elsif ($header =~ /\.mime$/) {
                my $header_part;
                eval { $header_part = $parser->parse($fh); };
                close $fh;
                if ($EVAL_ERROR) {
                    $log->syslog('err', 'Failed to parse MIME data %s: %s',
                        $header, $parser->last_error);
                } else {
                    $entity->make_multipart unless $entity->is_multipart;
                    ## Add AS FIRST PART (0)
                    $entity->add_part($header_part, 0);
                }
            } else {
                ## text/plain header
                $entity->make_multipart unless $entity->is_multipart;
                my $header_text = do { local $RS; <$fh> };
                close $fh;
                my $header_part = MIME::Entity->build(
                    Data       => $header_text,
                    Type       => "text/plain",
                    Filename   => undef,
                    'X-Mailer' => undef,
                    Encoding   => "8bit",
                    Charset    => "UTF-8"
                );
                $entity->add_part($header_part, 0);
            }
        }
        if ($footer and -s $footer) {
            my $fh;
            unless (open $fh, '<', $footer) {
                ;
            } elsif ($footer =~ /\.mime$/) {
                my $footer_part;
                eval { $footer_part = $parser->parse($fh); };
                close $fh;
                if ($EVAL_ERROR) {
                    $log->syslog('err', 'Failed to parse MIME data %s: %s',
                        $footer, $parser->last_error);
                } else {
                    $entity->make_multipart unless $entity->is_multipart;
                    $entity->add_part($footer_part);
                }
            } else {
                ## text/plain footer
                $entity->make_multipart unless $entity->is_multipart;
                my $footer_text = do { local $RS; <$fh> };
                close $fh;
                $entity->attach(
                    Data       => $footer_text,
                    Type       => "text/plain",
                    Filename   => undef,
                    'X-Mailer' => undef,
                    Encoding   => "8bit",
                    Charset    => "UTF-8"
                );
            }
        }
        if ($global_footer and -s $global_footer) {
            my $fh;
            unless (open $fh, '<', $global_footer) {
                ;
            } elsif ($global_footer =~ /\.mime$/) {
                my $global_footer_part;
                eval { $global_footer_part = $parser->parse($fh); };
                close $fh;
                if ($EVAL_ERROR) {
                    $log->syslog('err', 'Failed to parse MIME data %s: %s',
                        $global_footer, $parser->last_error);
                } else {
                    $entity->make_multipart unless $entity->is_multipart;
                    $entity->add_part($global_footer_part);
                }
            } else {
                ## text/plain global_footer
                $entity->make_multipart unless $entity->is_multipart;
                my $global_footer_text = do { local $RS; <$fh> };
                close $fh;
                $entity->attach(
                    Data       => $global_footer_text,
                    Type       => "text/plain",
                    Filename   => undef,
                    'X-Mailer' => undef,
                    Encoding   => "8bit",
                    Charset    => "UTF-8"
                );
            }
        }
    }

    return $entity;
}

## Append header/footer/global_footer to text/plain body.
## Note: As some charsets (e.g. UTF-16) are not compatible to US-ASCII,
##   we must concatenate decoded header/body/footer/global_footer and at last
##   encode it.
## Note: With BASE64 transfer-encoding, newline must be normalized to CRLF,
##   however, original body would be intact.
sub _append_parts {
    my $entity            = shift;
    my $header_msg        = shift || '';
    my $footer_msg        = shift || '';
    my $global_footer_msg = shift || '';

    my $enc = $entity->head->mime_encoding;
    # Parts with nonstandard encodings aren't modified.
    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
        return undef;
    }
    my $eff_type = $entity->effective_type || 'text/plain';
    my $body;
    my $io;

    ## Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}i) {
        return undef;
    }

    ## Skip attached parts.
    my $disposition = $entity->head->mime_attr('Content-Disposition');
    return undef
        if $disposition and uc $disposition ne 'INLINE';

    ## Preparing header, footer and global_footer for inclusion.
    if ($eff_type eq 'text/plain' or $eff_type eq 'text/html') {
        if (   length $header_msg
            or length $footer_msg
            or length $global_footer_msg) {
            # Only decodable bodies are allowed.
            my $bodyh = $entity->bodyhandle;
            if ($bodyh) {
                return undef if $bodyh->is_encoded;
                $body = $bodyh->as_string();
            } else {
                $body = '';
            }

            # Alter body.
            $body = _append_footer_header_to_part(
                {   'part'          => $entity,
                    'header'        => $header_msg,
                    'footer'        => $footer_msg,
                    'global_footer' => $global_footer_msg,
                    'eff_type'      => $eff_type,
                    'body'          => $body
                }
            );
            return undef unless defined $body;

            # Save new body.
            $io = $bodyh->open('w');
            unless (defined $io) {
                $log->syslog('err', 'Failed to save message: %m');
                return undef;
            }
            $io->print($body);
            $io->close;
            $entity->sync_headers(Length => 'COMPUTE')
                if $entity->head->get('Content-Length');

            return 1;
        }
    } elsif ($eff_type eq 'multipart/mixed') {
        ## Append to the first part, since other parts will be "attachments".
        if ($entity->parts
            and _append_parts(
                $entity->parts(0), $header_msg,
                $footer_msg,       $global_footer_msg
            )
        ) {
            return 1;
        }
    } elsif ($eff_type eq 'multipart/alternative') {
        ## We try all the alternatives
        my $r = undef;
        foreach my $p ($entity->parts) {
            $r = 1
                if _append_parts($p, $header_msg, $footer_msg,
                $global_footer_msg);
        }
        return $r if $r;
    } elsif ($eff_type eq 'multipart/related') {
        ## Append to the first part, since other parts will be "attachments".
        if ($entity->parts
            and _append_parts(
                $entity->parts(0), $header_msg,
                $footer_msg,       $global_footer_msg
            )
        ) {
            return 1;
        }
    }

    ## We couldn't find any parts to modify.
    return undef;
}

# Styles to cancel local CSS.
my $div_style =
    'background: transparent; border: none; clear: both; display: block; float: none; position: static';

sub _append_footer_header_to_part {
    my $data = shift;

    my $entity            = $data->{'part'};
    my $header_msg        = $data->{'header'};
    my $footer_msg        = $data->{'footer'};
    my $global_footer_msg = $data->{'global_footer'};
    my $eff_type          = $data->{'eff_type'};
    my $body              = $data->{'body'};

    my $in_cset;

    ## Detect charset.  If charset is unknown, detect 7-bit charset.
    my $charset = $entity->head->mime_attr('Content-Type.Charset');
    $in_cset = MIME::Charset->new($charset || 'NONE');
    unless ($in_cset->decoder) {
        # MIME::Charset 1.009.2 or later required.
        $in_cset =
            MIME::Charset->new(MIME::Charset::detect_7bit_charset($body)
                || 'NONE');
    }
    unless ($in_cset->decoder) {
        return undef;
    }
    $in_cset->encoder($in_cset);    # no charset conversion

    # Decode body to Unicode, since Sympa::Tools::Text::encode_html() and
    # newline normalization will break texts with several character sets
    # (UTF-16/32, ISO-2022-JP, ...).
    # Only decodable bodies are allowed.
    eval {
        $body = $in_cset->decode($body, 1);
        $header_msg        = Encode::decode_utf8($header_msg,        1);
        $footer_msg        = Encode::decode_utf8($footer_msg,        1);
        $global_footer_msg = Encode::decode_utf8($global_footer_msg, 1);
    };
    return undef if $EVAL_ERROR;

    my $new_body;
    if ($eff_type eq 'text/plain') {
        $log->syslog('debug3', "Treating text/plain part");

        ## Add newlines.  For BASE64 encoding they also must be normalized.
        if (length $header_msg) {
            $header_msg .= "\n" unless $header_msg =~ /\n\z/;
        }
        if (length $footer_msg and length $body) {
            $body .= "\n" unless $body =~ /\n\z/;
        }
        if (length $global_footer_msg and length $body) {
            $body .= "\n" unless $body =~ /\n\z/;
        }
        if (length $footer_msg) {
            $footer_msg .= "\n" unless $footer_msg =~ /\n\z/;
        }
        if (length $global_footer_msg) {
            $global_footer_msg .= "\n" unless $global_footer_msg =~ /\n\z/;
        }
        if (uc($entity->head->mime_attr('Content-Transfer-Encoding') || '')
            eq 'BASE64') {
            $header_msg =~ s/\r\n|\r|\n/\r\n/g;
            $body =~ s/(\r\n|\r|\n)\z/\r\n/;    # only at end
            $footer_msg =~ s/\r\n|\r|\n/\r\n/g;
            $global_footer_msg =~ s/\r\n|\r|\n/\r\n/g;
        }

        $new_body = $header_msg . $body . $footer_msg . $global_footer_msg;

        ## Data not encodable by original charset will fallback to UTF-8.
        my ($newcharset, $newenc);
        ($body, $newcharset, $newenc) =
            $in_cset->body_encode($new_body, Replacement => 'FALLBACK');
        unless ($newcharset) {                  # bug in MIME::Charset?
            $log->syslog('err', 'Can\'t determine output charset');
            return undef;
        } elsif ($newcharset ne $in_cset->as_string) {
            $entity->head->mime_attr('Content-Transfer-Encoding' => $newenc);
            $entity->head->mime_attr('Content-Type.Charset' => $newcharset);
        }
    } elsif ($eff_type eq 'text/html') {
        $log->syslog('debug3', "Treating text/html part");

        # Escape special characters.
        $header_msg = Sympa::Tools::Text::encode_html($header_msg);
        $header_msg =~ s/(\r\n|\r|\n)$//;       # strip the last newline.
        $header_msg =~ s,(\r\n|\r|\n),<br/>,g;
        $footer_msg = Sympa::Tools::Text::encode_html($footer_msg);
        $footer_msg =~ s/(\r\n|\r|\n)$//;       # strip the last newline.
        $footer_msg =~ s,(\r\n|\r|\n),<br/>,g;
        $global_footer_msg =
            Sympa::Tools::Text::encode_html($global_footer_msg);
        $global_footer_msg =~ s/(\r\n|\r|\n)$//;    # strip the last newline.
        $global_footer_msg =~ s,(\r\n|\r|\n),<br/>,g;

        $new_body = $body;
        if (length $header_msg) {
            my $div = sprintf '<div style="%s">%s</div>',
                $div_style, $header_msg;
            $new_body =~ s,(<body\b[^>]*>),$1$div,i
                or $new_body = $div . $new_body;
        }
        if (length $footer_msg) {
            my $div = sprintf '<div style="%s">%s</div>',
                $div_style, $footer_msg;
            $new_body =~ s,(</\s*body\b[^>]*>),$div$1,i
                or $new_body = $new_body . $div;
        }
        if (length $global_footer_msg) {
            my $div = sprintf '<div style="%s">%s</div>',
                $div_style, $global_footer_msg;
            $new_body =~ s,(</\s*body\b[^>]*>),$div$1,i
                or $new_body = $new_body . $div;
        }
        # Append newline if it is not there: A few MUAs need it.
        $new_body .= "\n" unless $new_body =~ /\n\z/;

        # Unencodable characters are encoded to entity, because charset
        # metadata in HTML won't be altered.
        # Problem: FB_HTMLCREF of several codecs are broken.
        eval { $body = $in_cset->encode($new_body, Encode::FB_HTMLCREF); };
        return undef if $EVAL_ERROR;
    }

    return $body;
}

sub _urlize_parts {
    my $entity     = shift;
    my $list       = shift;
    my $message_id = shift;

    ## Only multipart/mixed messages are modified.
    my $eff_type = $entity->effective_type || 'text/plain';
    unless ($eff_type eq 'multipart/mixed'
        or $eff_type eq 'multipart/alternative'
        or $eff_type eq 'multipart/related') {
        return undef;
    }

    my $expl = $list->{'dir'} . '/urlized';
    unless (-d $expl or mkdir $expl, 0775) {
        $log->syslog('err', 'Unable to create urlized directory %s', $expl);
        return undef;
    }

    ## Clean up Message-ID and preventing double percent encoding.
    my $dir1 = Sympa::Tools::Text::encode_filesystem_safe($message_id);
    unless (-d "$expl/$dir1" or mkdir "$expl/$dir1", 0775) {
        $log->syslog('err', 'Unable to create urlized directory %s/%s: %m',
            $expl, $dir1);
        return 0;
    }
    return _urlize_sub_parts($entity, $list, $message_id, $dir1, 0);
}

sub _urlize_sub_parts {
    my $entity     = shift;
    my $list       = shift;
    my $message_id = shift;
    my $directory  = shift;
    my $i          = shift;
    my @parts      = ();
    use Data::Dumper;
    my $parent_eff_type = $entity->effective_type();

    foreach my $part ($entity->parts) {
        my $eff_type = $part->effective_type || 'text/plain';
        if ($eff_type eq 'multipart/mixed') {
            $i++;
            my $p =
                _urlize_sub_parts($part->dup, $list, $message_id, $directory,
                $i);
            push @parts, $p;
        } elsif (
            (      $eff_type eq 'multipart/alternative'
                or $eff_type eq 'multipart/related'
            )
            and $i < 2
        ) {
            $i++;
            my $p =
                _urlize_sub_parts($part->dup, $list, $message_id, $directory,
                $i);
            push @parts, $p;
        } else {
            my $p = _urlize_one_part($part->dup, $list, $directory, $i,
                $parent_eff_type);
            if (defined $p) {
                push @parts, $p;
                $i++;
            } else {
                push @parts, $part;
            }
        }
    }

    $entity->parts(\@parts);
    return $entity;
}

sub _urlize_one_part {
    my $entity          = shift;
    my $list            = shift;
    my $dir             = shift;
    my $i               = shift;
    my $parent_eff_type = shift;

    return undef unless ($parent_eff_type eq 'multipart/mixed');

    my $expl     = $list->{'dir'} . '/urlized';
    my $listname = $list->{'name'};
    my $head     = $entity->head;
    my $encoding = $head->mime_encoding;

    # name of the linked file
    my $filename;
    if ($head->recommended_filename) {
        $filename = $head->recommended_filename;
        if (Encode::is_utf8($filename)) {
            # MIME-tools >= 5.501 returns Unicode value ("utf8 flag" on).
            $filename = Encode::encode_utf8($filename);
        } elsif ($filename !~ /[^\s\x20-\x7E]/
            and $filename =~ /=[?][-.+\w]+[?][BQ][?].*[?]=/i) {
            # Earlier versions of MIME-tools won't decode (nonstandard)
            # RFC-2047-encoded parameters.
            $filename = MIME::EncWords::decode_mimewords($filename,
                Charset => 'UTF-8') // $filename;
        }
    } else {
        my $content_disposition =
            lc($entity->head->mime_attr('Content-Disposition') // '');
        if ($entity->effective_type =~ m{\Atext}
            && (  !$content_disposition
                || $content_disposition eq 'attachment')
            && $entity->head->mime_attr('content-type.charset')
        ) {
            return undef;
        }
        my $fileExt = Conf::get_mime_type($entity->effective_type || '')
            || 'bin';
        $filename = sprintf 'msg.%d.%s', $i, $fileExt;
    }
    my $safe_filename = Sympa::Tools::Text::encode_filesystem_safe($filename);
    my $file = sprintf '%s/%s/%s', $expl, $dir, $safe_filename;

    # Create the linked file
    # Store body in file
    my $fh;
    unless (open $fh, '>', $file) {
        $log->syslog('err', 'Unable to open %s: %m', $file);
        return undef;
    }
    if ($entity->bodyhandle) {
        my $ct = $entity->effective_type || 'text/plain';
        printf $fh "Content-Type: %s", $ct;
        printf $fh "; Charset=%s",
            $head->mime_attr('Content-Type.Charset')
            if Sympa::Tools::Data::smart_eq(
            $head->mime_attr('Content-Type.Charset'), qr/\S/);
        print $fh "\n\n";
        print $fh $entity->bodyhandle->as_string;
    } else {
        my $ct = $entity->effective_type || 'application/octet-stream';
        printf $fh "Content-Type: %s", $ct;
        print $fh "\n\n";
        print $fh $entity->body_as_string;
    }
    close $fh;

    my $size = -s $file;

    ## Only URLize files with a moderate size
    if ($size < $Conf::Conf{'urlize_min_size'}) {
        unlink $file;
        return undef;
    }

    # Do NOT escape '/' chars separating path components.
    my $file_url =
        Sympa::get_url($list, 'attach', paths => [$dir, $safe_filename]);

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    my $new_part;

    my $charset = Conf::lang2charset($language->get_lang);
    my $data    = {
        file_name => $filename,
        file_url  => $file_url,
        file_size => $size,
        charset   => $charset,    # compat. <= 6.1.
    };

    my $template = Sympa::Template->new(
        $list,
        subdir => 'mail_tt2',
        lang   => $language->get_lang
    );
    unless ($template->parse($data, 'urlized_part.tt2', \$new_part)) {
        $log->syslog(
            'err',
            'Can\'t parse template urlized_part.tt2: %s',
            $template->{last_error}
        );
        return undef;
    }
    $entity = $parser->parse_data(\$new_part);
    _fix_utf8_parts($entity, $parser, [], $charset);

    return $entity;
}

# Some paths of message processing in Sympa can't recognize Unicode strings.
# At least MIME::Parser::parse_data() and Template::proccess(): these
# methods occationalily break strings containing Unicode characters.
#
# My mail_utf8 patch expects the behavior as following ---
#
# Sub-messages to be attached (into digests, moderation notices etc.) will
# passed to Sympa::Mail::reformat_message() separately then attached to reformatted
# parent message again.  As a result, sub-messages won't be broken.  Since
# they won't cause mixture of Unicode string (parent message generated by
# Sympa::Template::parse()) and byte string (sub-messages).
#
# Note: For compatibility with old style, data passed to
# Sympa::Mail::reformat_message() already includes sub-message(s).  Then:
# - When a part has an `X-Sympa-Attach:' header field for internal use, new
#   style, Sympa::Mail::reformat_message() attaches raw sub-message to reformatted
#   parent message again;
# - When a part doesn't have any `X-Sympa-Attach:' header fields, sub-
#   messages generated by [% INSERT %] directive(s) in the template will be
#   used.
#
# More Note: Latter behavior above will give expected result only if
# contents of sub-messages are US-ASCII or ISO-8859-1. In other cases
# customized templates (if any) should be modified so that they have
# appropriate `X-Sympa-Attach:' header fields.
#
# Sub-messages are gathered from template context paramenters.

sub reformat_utf8_message {
    my $self        = shift;
    my $attachments = shift || [];
    my $defcharset  = shift;

    my $entity = $self->as_entity->dup;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});

    $entity->head->delete('X-Mailer');
    _fix_utf8_parts($entity, $parser, $attachments, $defcharset);
    $entity->head->add('X-Mailer', sprintf 'Sympa %s',
        Sympa::Constants::VERSION);

    $self->set_entity($entity);
    return $self;
}

sub _fix_utf8_parts {
    my $entity      = shift;
    my $parser      = shift;
    my $attachments = shift || [];
    my $defcharset  = shift;
    return $entity unless $entity;

    my $enc = $entity->head->mime_encoding;
    # Parts with nonstandard encodings aren't modified.
    return $entity
        if $enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i;
    my $eff_type = $entity->effective_type;
    # Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}) {
        return $entity;
    }

    if ($entity->head->get('X-Sympa-Attach')) {    # Need re-attaching data.
        my $data = shift @{$attachments};
        if (ref $data eq 'MIME::Entity') {
            $entity->parts([$data]);
        } elsif (ref $data eq 'SCALAR' or ref $data eq 'ARRAY') {
            eval { $data = $parser->parse_data($data); };
            if ($EVAL_ERROR) {
                $log->syslog('notice', 'Failed to parse MIME data');
                $data = $parser->parse_data('');
            }
            $entity->parts([$data]);
        } else {
            if (Scalar::Util::blessed($data)
                and $data->isa('Sympa::Message')) {
                $data = $data->as_string;
            } elsif (ref $data) {
                die sprintf 'Unsupported type for attachment: %s', ref $data;
            } else {    # already stringified.
                eval { $parser->parse_data($data); };    # check only.
                if ($EVAL_ERROR) {
                    $log->syslog('notice', 'Failed to parse MIME data');
                    $data = '';
                }
            }
            $parser->extract_nested_messages(0);    # Keep attachments intact.
            $data =
                $parser->parse_data($entity->head->as_string . "\n" . $data);
            $parser->extract_nested_messages(1);
            %$entity = %$data;
        }
        $entity->head->delete('X-Sympa-Attach');
    } elsif ($entity->parts) {
        my @newparts = ();
        foreach my $part ($entity->parts) {
            push @newparts,
                _fix_utf8_parts($part, $parser, $attachments, $defcharset);
        }
        $entity->parts(\@newparts);
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {
        # multipart or message types without subparts.
        return $entity;
    } elsif (MIME::Tools::textual_type($eff_type)) {
        my $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        return $entity if !$bodyh or $bodyh->is_encoded;

        my $head = $entity->head;
        my $body = $bodyh->as_string;
        my $wrap = $body;
        if ($head->get('X-Sympa-NoWrap')) {    # Need not wrapping
            $head->delete('X-Sympa-NoWrap');
        } elsif ($eff_type eq 'text/plain'
            and lc($head->mime_attr('Content-type.Format') || '') ne 'flowed')
        {
            $wrap = Sympa::Tools::Text::wrap_text($body);
        }

        my $charset = $head->mime_attr("Content-Type.Charset") || $defcharset;
        my ($newbody, $newcharset, $newenc) =
            MIME::Charset::body_encode(Encode::decode_utf8($wrap),
            $charset, Replacement => 'FALLBACK');
        # Append newline if it is not there.  A few MUAs need it.
        $newbody .= "\n" unless $newbody =~ /\n\z/;

        if (    $newenc eq $enc
            and $newcharset eq $charset
            and $newbody eq $body) {
            # Normalize field, especially because charset may be absent.
            $head->mime_attr('Content-Type',              uc $eff_type);
            $head->mime_attr('Content-Type.Charset',      $newcharset);
            $head->mime_attr('Content-Transfer-Encoding', $newenc);

            $head->add("MIME-Version", "1.0")
                unless $head->get("MIME-Version");
            return $entity;
        }

        ## normalize newline to CRLF if transfer-encoding is BASE64.
        $newbody =~ s/\r\n|\r|\n/\r\n/g
            if $newenc and $newenc eq 'BASE64';

        # Fix headers and body.
        $head->mime_attr("Content-Type", "TEXT/PLAIN")
            unless $head->mime_attr("Content-Type");
        $head->mime_attr("Content-Type.Charset",      $newcharset);
        $head->mime_attr("Content-Transfer-Encoding", $newenc);
        $head->add("MIME-Version", "1.0") unless $head->get("MIME-Version");
        my $io = $bodyh->open("w");

        unless (defined $io) {
            $log->syslog('err', 'Failed to save message: %m');
            return undef;
        }

        $io->print($newbody);
        $io->close;
        $entity->sync_headers(Length => 'COMPUTE');
    } else {
        # Binary or text with long lines will be suggested to be BASE64.
        $entity->head->mime_attr("Content-Transfer-Encoding",
            $entity->suggest_encoding);
        $entity->sync_headers(Length => 'COMPUTE');
    }
    return $entity;
}

sub get_plain_body {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    my $entity = $self->as_entity->dup;
    return undef unless _as_singlepart($entity, 'text/plain');
    return undef unless $entity->bodyhandle;
    my $body = $entity->bodyhandle->as_string;

    # Get charset
    my $cset =
        MIME::Charset->new($entity->head->mime_attr('Content-Type.Charset')
            || 'NONE');
    unless ($cset->decoder) {
        # Charset is unknown.  Detect 7-bit charset.
        $cset = MIME::Charset->new(MIME::Charset::detect_7bit_charset($body));
    }
    unless ($cset->decoder) {
        $cset = MIME::Charset->new('US-ASCII');
    }

    # Unfold flowed text if required.
    my $format = lc($entity->head->mime_attr('Content-Type.Format') || '');
    my $delsp  = lc($entity->head->mime_attr('Content-Type.DelSp')  || '');
    if ($format eq 'flowed') {
        my $linefold =
            Text::LineFold->new(Charset => $cset, OutputCharset => 'UTF-8');
        if ($delsp eq 'yes') {
            return $linefold->unfold($body, 'FLOWED');
        } else {
            return $linefold->unfold($body, 'FLOWEDSP');
        }
    } else {
        $cset->encoder('UTF-8');
        return $cset->encode($body);
    }
}

# Make multipart/alternative message to singlepart.
# Old name: tools::as_singlepart(), Sympa::Tools::Message::as_singlepart().
sub _as_singlepart {
    my $entity         = shift;
    my $preferred_type = shift;
    my $loops          = shift || 0;

    my $done = 0;

    $loops++;
    return undef unless $entity;
    return undef if 4 < $loops;

    my $eff_type = lc($entity->effective_type || 'text/plain');
    if ($eff_type eq lc $preferred_type) {
        $done = 1;
    } elsif ($eff_type eq 'multipart/alternative') {
        foreach my $part ($entity->parts) {
            my $eff_type = lc($part->effective_type || 'text/plain');
            if ($eff_type eq lc $preferred_type
                or (    $eff_type eq 'multipart/related'
                    and $part->parts
                    and lc($part->parts(0)->effective_type || 'text/plain')
                    eq $preferred_type)
            ) {
                ## Only keep the first matching part
                $entity->parts([$part]);
                $entity->make_singlepart();
                $done = 1;
                last;
            }
        }
    } elsif ($eff_type eq 'multipart/signed') {
        my @parts = $entity->parts();
        ## Only keep the first part
        $entity->parts([$parts[0]]);
        $entity->make_singlepart();

        $done ||= _as_singlepart($entity, $preferred_type, $loops);

    } elsif ($eff_type =~ /^multipart/) {
        foreach my $part ($entity->parts) {
            next unless $part;    ## Skip empty parts

            my $eff_type = lc($part->effective_type || 'text/plain');
            if ($eff_type eq 'multipart/alternative') {
                if (_as_singlepart($part, $preferred_type, $loops)) {
                    $entity->parts([$part]);
                    $entity->make_singlepart();
                    $done = 1;
                }
            }
        }
    }

    return $done;
}

# Note: this would be moved to incoming pipeline package.
# Old names: tools::virus_infected(), Sympa::Tools::Message::virus_infected().
sub check_virus_infection {
    $log->syslog('debug2', '(%s, ...)', @_);
    my $self    = shift;
    my %options = @_;

    my $robot_id;
    if (ref $self->{context} eq 'Sympa::List') {
        $robot_id = $self->{context}->{'domain'};
    } elsif ($self->{context} and $self->{context} ne '*') {
        $robot_id = $self->{context};
    } else {
        $robot_id = '*';
    }

    my $antivirus_path = Conf::get_robot_conf($robot_id, 'antivirus_path');
    my @antivirus_args = split /\s+/,
        (Conf::get_robot_conf($robot_id, 'antivirus_args') || '');

    unless ($antivirus_path) {
        $log->syslog('debug',
            'Sympa not configured to scan virus in message');
        return 0;
    }

    my $subdir = [split /\//, $self->get_id]->[0];
    my $work_dir = join '/', $Conf::Conf{'tmpdir'}, 'antivirus', $subdir;
    unless (-d $work_dir or Sympa::Tools::File::mkdir_all($work_dir, 0755)) {
        $log->syslog('err', 'Unable to create tmp antivirus directory %s: %m',
            $work_dir);
        return undef;
    }

    ## Call the procedure of splitting mail
    unless ($self->_split_mail($work_dir)) {
        $log->syslog('err', 'Could not split mail %s', $self);
        return undef;
    }

    my $virusfound = 0;
    my $error_msg;
    my $result;

    if ($antivirus_path =~ /\/uvscan$/) {
        # McAfee

        # impossible to look for viruses with no option set
        unless (@antivirus_args) {
            $log->syslog('err', 'Missing "antivirus_args" in sympa.conf');
            return undef;
        }

        my $pipein;
        unless (open $pipein, '-|', $antivirus_path, @antivirus_args,
            $work_dir) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            $result .= $_;
            chomp $result;
            if (   (/^\s*Found the\s+(.*)\s*virus.*$/i)
                || (/^\s*Found application\s+(.*)\.\s*$/i)) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## uvscan status = 12 or 13 (*256) => virus
        if ($status == 13 or $status == 12) {
            $virusfound ||= "unknown";
        }

        ## Meaning of the codes
        ##  12 : The program tried to clean a file, and that clean failed for
        ##  some reason and the file is still infected.
        ##  13 : One or more viruses or hostile objects (such as a Trojan
        ##  horse, joke program,  or  a  test file) were found.
        ##  15 : The programs self-check failed; the program might be infected
        ##  or damaged.
        ##  19 : The program succeeded in cleaning all infected files.

        $error_msg = $result
            if $status != 0
            and $status != 12
            and $status != 13
            and $status != 19;
    } elsif ($antivirus_path =~ /\/vscan$/) {
        # Trend Micro

        my $pipein;
        unless (open $pipein, '-|', $antivirus_path, @antivirus_args,
            $work_dir) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            if (/Found virus (\S+) /i) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## uvscan status = 1 | 2 (*256) => virus
        if ($status == 1 or $status == 2) {
            $virusfound ||= "unknown";
        }
    } elsif ($antivirus_path =~ /\/fsav$/) {
        # F-Secure
        my $dbdir = $PREMATCH;

        # impossible to look for viruses with no option set
        unless (@antivirus_args) {
            $log->syslog('err', 'Missing "antivirus_args" in sympa.conf');
            return undef;
        }

        my $pipein;
        unless (
            open $pipein, '-|', $antivirus_path,
            '--databasedirectory' => $dbdir,
            @antivirus_args, $work_dir
        ) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            if (/infection:\s+(.*)/) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## fsecure status = 3 (*256) => virus
        if ($status == 3) {
            $virusfound ||= "unknown";
        }
    } elsif ($antivirus_path =~ /f-prot\.sh$/) {
        my $pipein;
        unless (open $pipein, '-|', $antivirus_path, @antivirus_args,
            $work_dir) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            if (/Infection:\s+(.*)/) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## f-prot status = 3 (*256) => virus
        if ($status == 3) {
            $virusfound ||= "unknown";
        }
    } elsif ($antivirus_path =~ /kavscanner/) {
        # Kaspersky

        # impossible to look for viruses with no option set
        unless (@antivirus_args) {
            $log->syslog('err', 'Missing "antivirus_args" in sympa.conf');
            return undef;
        }

        my $pipein;
        unless (open $pipein, '-|', $antivirus_path, @antivirus_args,
            $work_dir) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            if (/infected:\s+(.*)/) {
                $virusfound = $1;
            } elsif (/suspicion:\s+(.*)/i) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## uvscan status = 3 (*256) => virus
        if ($status >= 3) {
            $virusfound ||= "unknown";
        }

    } elsif ($antivirus_path =~ /\/sweep$/) {
        # Sophos Antivirus... by liuk@publinet.it

        # impossible to look for viruses with no option set
        unless (@antivirus_args) {
            $log->syslog('err', 'Missing "antivirus_args" in sympa.conf');
            return undef;
        }

        my $pipein;
        unless (open $pipein, '-|', $antivirus_path, @antivirus_args,
            $work_dir) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            if (/Virus\s+(.*)/) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## sweep status = 3 (*256) => virus
        if ($status == 3) {
            $virusfound ||= "unknown";
        }

        ## Clam antivirus
    } elsif ($antivirus_path =~ /\/clamd?scan$/) {
        # Clam antivirus
        my $result;

        my $pipein;
        unless (open $pipein, '-|', $antivirus_path, @antivirus_args,
            $work_dir) {
            $log->syslog('err', 'Cannot open pipe: %m');
            return undef;
        }
        while (<$pipein>) {
            $result .= $_;
            chomp $result;
            if (/^\S+:\s(.*)\sFOUND$/) {
                $virusfound = $1;
            }
        }
        close $pipein;
        my $status = $CHILD_ERROR >> 8;

        ## Clamscan status = 1 (*256) => virus
        if ($status == 1) {
            $virusfound ||= "unknown";
        }
        $error_msg = $result
            if $status != 0 and $status != 1;
    }

    ## Error while running antivir, notify listmaster
    if ($error_msg) {
        Sympa::send_notify_to_listmaster(
            '*',
            'virus_scan_failed',
            {   'filename'  => $work_dir,
                'error_msg' => $error_msg
            }
        );
    }

    # if debug mode is active, the working directory is kept
    unless ($options{debug}) {    #FIXME: Is this condition required?
        opendir DIR, $work_dir;
        my @list = readdir DIR;
        closedir DIR;
        foreach my $file (@list) {
            unlink "$work_dir/$file";
        }
        rmdir $work_dir;
    }

    return $virusfound;
}

# Old name: tools::split_mail(), Sympa::Tools::Message::split_mail().
# Currently this is used by check_virus_infection() only.
sub _split_mail {
    my $self = shift;
    my $dir  = shift;

    my $i = 0;
    foreach
        my $part (grep { $_ and $_->bodyhandle } $self->as_entity->parts_DFS)
    {
        my $head = $part->head;
        my $fileExt;

        if (    $head->mime_attr('Content-Type.Name')
            and $head->mime_attr('Content-Type.Name') =~
            /\.([.\w]*\w)\s*\"*$/) {
            $fileExt = $1;
        } elsif ($head->recommended_filename
            and $head->recommended_filename =~ /\.([.\w]*\w)\s*\"*$/) {
            $fileExt = $1;
            # MIME-tools >= 5.501 returns Unicode value ("utf8 flag" on).
            $fileExt = Encode::encode_utf8($fileExt)
                if Encode::is_utf8($fileExt);
        } else {
            $fileExt = Conf::get_mime_type($head->mime_type) || 'bin';
        }

        ## Store body in file
        my $fh;
        unless (open $fh, '>', sprintf('%s/msg%03d.%s', $dir, $i, $fileExt)) {
            $log->syslog('err', 'Unable to create %s/msg%03d.%s: %m',
                $dir, $i, $fileExt);
            return undef;
        }
        print $fh $part->bodyhandle->as_string;
        close $fh;

        $i++;
    }

    return 1;
}

# Old name: PlainDigest::plain_body_as_string(),
#   Sympa::Tools::Message::plain_body_as_string().
#
# Changes
# 20080910
# - don't bother trying to find path to lynx unless use_lynx is true
# - anchor content-type test strings to end of string to avoid
#    picking up malformed headers as per bug 3702
# - local Text::Wrap variables
# - moved repeated code to get charset into sub _getCharset
# - added use of MIME::Charset to check charset aliases
# 20100810 - S. Ikeda
# - Remove dependency on Text::Wrap: use common utility tools::wrap_text().
# - Use MIME::Charset OO to handle vendor-defined encodings.
# - Use MIME::EncWords instead of MIME::WordDecoder.
# - Now HTML::FormatText is mandatory.  Remove Lynx support.
#
sub get_plaindigest_body {
    my $self = shift;

    # Reparse message to extract UUEncode.
    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->tmp_dir($Conf::Conf{'tmpdir'});
    $parser->extract_uuencode(1);
    $parser->extract_nested_messages(1);
    my $topent = $parser->parse_data($self->as_string);

    my $string = _do_toplevel($topent);

    ## clean up after ourselves
    #$topent->purge;

    return Sympa::Tools::Text::wrap_text($string, '', '');
}

sub _do_toplevel {
    my $topent = shift;
    if (   $topent->effective_type =~ /^text\/plain$/i
        || $topent->effective_type =~ /^text\/enriched/i) {
        return _do_text_plain($topent);
    } elsif ($topent->effective_type =~ /^text\/html$/i) {
        return _do_text_html($topent);
    } elsif ($topent->effective_type =~ /^multipart\/.*/i) {
        return _do_multipart($topent);
    } elsif ($topent->effective_type =~ /^message\/rfc822$/i) {
        return _do_message($topent);
    } elsif ($topent->effective_type =~ /^message\/delivery\-status$/i) {
        return _do_dsn($topent);
    } else {
        return _do_other($topent);
    }
}

sub _do_multipart {
    my $topent = shift;

    my $string = '';

    # cycle through each part and process accordingly
    foreach my $subent ($topent->parts) {
        if (   $subent->effective_type =~ /^text\/plain$/i
            || $subent->effective_type =~ /^text\/enriched/i) {
            $string .= _do_text_plain($subent);
        } elsif ($subent->effective_type =~ /^multipart\/related$/i) {
            if ($topent->effective_type =~ /^multipart\/alternative$/i
                && _hasTextPlain($topent)) {
                # this is a rare case - /related nested inside /alternative.
                # If there's also a text/plain alternative just ignore it
                next;
            } else {
                # just treat like any other multipart
                $string .= _do_multipart($subent);
            }
        } elsif ($subent->effective_type =~ /^multipart\/.*/i) {
            $string .= _do_multipart($subent);
        } elsif ($subent->effective_type =~ /^text\/html$/i) {
            if ($topent->effective_type =~ /^multipart\/alternative$/i
                && _hasTextPlain($topent)) {
                # there's a text/plain alternive, so don't warn
                # that the text/html part has been scrubbed
                next;
            }
            $string .= _do_text_html($subent);
        } elsif ($subent->effective_type =~ /^message\/rfc822$/i) {
            $string .= _do_message($subent);
        } elsif ($subent->effective_type =~ /^message\/delivery\-status$/i) {
            $string .= _do_dsn($subent);
        } else {
            # something else - just scrub it and add a message to say what was
            # there
            $string .= _do_other($subent);
        }
    }

    return $string;
}

sub _do_message {
    my $topent = shift;
    my $msgent = $topent->parts(0);

    my $string = '';

    unless ($msgent) {
        return $language->gettext(
            "----- Malformed message ignored -----\n\n");
    }

    # Get decoded headers.
    # Note that MIME::Head::get() returns empty array if requested fields are
    # not found.
    my ($from) = map {
        chomp $_;
        MIME::EncWords::decode_mimewords($_, Charset => 'UTF-8')
    } ($msgent->head->get('From', 0));
    $from = $language->gettext("[Unknown]")
        unless defined $from and length $from;
    my ($subject) = map {
        chomp $_;
        MIME::EncWords::decode_mimewords($_, Charset => 'UTF-8')
    } ($msgent->head->get('Subject', 0));
    my ($date) = map {
        chomp $_;
        MIME::EncWords::decode_mimewords($_, Charset => 'UTF-8')
    } ($msgent->head->get('Date', 0));
    my $to = join ', ', map {
        chomp $_;
        MIME::EncWords::decode_mimewords($_, Charset => 'UTF-8')
    } ($msgent->head->get('To'));
    my $cc = join ', ', map {
        chomp $_;
        MIME::EncWords::decode_mimewords($_, Charset => 'UTF-8')
    } ($msgent->head->get('Cc'));

    my @fromline = Mail::Address->parse($msgent->head->get('From'));
    my $name;
    if ($fromline[0]) {
        $name = MIME::EncWords::decode_mimewords($fromline[0]->name(),
            Charset => 'utf8');
        $name = $fromline[0]->address()
            unless defined $name and $name =~ /\S/;
        chomp $name;
    }
    $name = $from unless defined $name and length $name;

    $string .= $language->gettext(
        "\n[Attached message follows]\n-----Original message-----\n");
    my $headers = '';
    $headers .= $language->gettext_sprintf("Date: %s\n", $date) if $date;
    $headers .= $language->gettext_sprintf("From: %s\n", $from) if $from;
    $headers .= $language->gettext_sprintf("To: %s\n",   $to)   if $to;
    $headers .= $language->gettext_sprintf("Cc: %s\n",   $cc)   if $cc;
    $headers .= $language->gettext_sprintf("Subject: %s\n", $subject)
        if $subject;
    $headers .= "\n";
    $string .= Sympa::Tools::Text::wrap_text($headers, '', '    ');

    $string .= _do_toplevel($msgent);

    $string .= $language->gettext_sprintf(
        "-----End of original message from %s-----\n\n", $name);
    return $string;
}

sub _do_text_plain {
    my $entity = shift;

    my $string = '';

    if (($entity->head->get('Content-Disposition') || '') =~ /attachment/) {
        return _do_other($entity);
    }

    my $thispart = $entity->bodyhandle->as_string;

    # deal with CR/LF left over - a problem from Outlook which
    # qp encodes them
    $thispart =~ s/\r\n/\n/g;

    ## normalise body to UTF-8
    # get charset
    my $charset = _getCharset($entity);
    eval {
        $charset->encoder('utf8');
        $thispart = $charset->encode($thispart);
    };
    if ($EVAL_ERROR) {
        # mmm, what to do if it fails?
        $string .= $language->gettext_sprintf(
            "** Warning: A message part is using unrecognised character set %s\n    Some characters may be lost or incorrect **\n\n",
            $charset->as_string
        );
        $thispart =~ s/[^\x00-\x7F]/?/g;
    }

    # deal with 30 hyphens (RFC 1153)
    $thispart =~ s/\n-{30}(\n|$)/\n -----------------------------\n/g;
    # leading and trailing lines (RFC 1153)
    $thispart =~ s/^\n*//;
    $thispart =~ s/\n+$/\n/;

    $string .= $thispart;
    return $string;
}

sub _do_other {
    # just add a note that attachment was stripped.
    my $entity = shift;

    return $language->gettext_sprintf(
        "\n[An attachment of type %s was included here]\n",
        $entity->mime_type);
}

sub _do_dsn {
    my $entity = shift;

    my $string = '';

    $string .= $language->gettext("\n-----Delivery Status Report-----\n");
    $string .= _do_text_plain($entity);
    $string .=
        $language->gettext("\n-----End of Delivery Status Report-----\n");

    return $string;
}

sub _do_text_html {
    # get a plain text representation of an HTML part
    my $entity = shift;

    my $string = '';
    my $text;

    unless (defined $entity->bodyhandle) {
        return $language->gettext(
            "\n[** Unable to process HTML message part **]\n");
    }

    my $body = $entity->bodyhandle->as_string;

    # deal with CR/LF left over - a problem from Outlook which
    # qp encodes them
    $body =~ s/\r\n/\n/g;

    my $charset = _getCharset($entity);

    eval {
        # normalise body to internal unicode
        if ($charset->decoder) {
            $body = $charset->decode($body);
        } else {
            # mmm, what to do if it fails?
            $string .= $language->gettext_sprintf(
                "** Warning: A message part is using unrecognised character set %s\n    Some characters may be lost or incorrect **\n\n",
                $charset->as_string
            );
            $body =~ s/[^\x00-\x7F]/?/g;
        }
        my $tree = HTML::TreeBuilder->new->parse($body);
        $tree->eof();
        my $formatter =
            Sympa::HTML::FormatText->new(leftmargin => 0, rightmargin => 72);
        $text = $formatter->format($tree);
        $tree->delete();
        $text = Encode::encode_utf8($text);
    };
    if ($EVAL_ERROR) {
        $string .= $language->gettext(
            "\n[** Unable to process HTML message part **]\n");
        return $string;
    }

    $string .= $language->gettext("[ Text converted from HTML ]\n");

    # deal with 30 hyphens (RFC 1153)
    $text =~ s/\n-{30}(\n|$)/\n -----------------------------\n/g;
    # leading and trailing lines (RFC 1153)
    $text =~ s/^\n*//;
    $text =~ s/\n+$/\n/;

    $string .= $text;

    return $string;
}

sub _hasTextPlain {
    # tell if an entity has text/plain children
    my $topent  = shift;
    my @subents = $topent->parts;
    foreach my $subent (@subents) {
        if ($subent->effective_type =~ /^text\/plain$/i) {
            return 1;
        }
    }
    return undef;
}

sub _getCharset {
    my $entity = shift;

    my $charset =
          $entity->head->mime_attr('content-type.charset')
        ? $entity->head->mime_attr('content-type.charset')
        : 'us-ascii';
    # malformed mail with single quotes around charset?
    if ($charset =~ /'([^']*)'/i) { $charset = $1; }

    # get charset object.
    return MIME::Charset->new($charset);
}

sub dmarc_protect {
    my $self = shift;

    my $list = $self->{context};
    return unless ref $list eq 'Sympa::List';

    return unless $list->{'admin'}{'dmarc_protection'};
    my @modes = @{$list->{'admin'}{'dmarc_protection'}{'mode'} || []};
    return unless grep { $_ and $_ ne 'none' } @modes;
    $log->syslog('debug', 'DMARC protection on');

    my $dkim_signature = $self->get_header('DKIM-Signature');
    my $domain_regex   = $list->{'admin'}{'dmarc_protection'}{'domain_regex'};

    my $original_from = $self->get_header('From');
    my ($from)        = Mail::Address->parse($original_from);
    my $from_address  = $from->address if $from;
    $log->syslog('debug', 'From address: <%s>', $from_address);

    # Will this message be processed?
    if (grep { $_ eq 'all' } @modes) {
        $log->syslog('debug', 'Munging From for ALL messages');
    } elsif (
        $dkim_signature and grep {
            $_ eq 'dkim_signature'
        } @modes
    ) {
        $log->syslog('debug', 'Munging From for DKIM-signed messages');
    } elsif (
        $from_address
        and $domain_regex
        and grep {
            $_ eq 'domain_regex'
        } @modes
        and eval {
            $from_address =~ /$domain_regex$/;
        }
    ) {
        $log->syslog('debug',
            'Munging From for messages based on domain regexp');
    } elsif ($from_address and $self->_check_dmarc_rr($from_address)) {
        $log->syslog('debug', 'Munging From for messages with strict policy');
    } else {
        return;
    }

    my $listtype = $self->{listtype} || '';

    # Remove any DKIM signatures we find
    if ($dkim_signature) {
        $self->add_header('X-Original-DKIM-Signature', $dkim_signature);
        $self->delete_header('DKIM-Signature');
        $self->delete_header('DomainKey-Signature');
        $log->syslog('debug',
            'Removing previous DKIM and DomainKey signatures');
    }

    # Identify default new From address
    my $phraseMode = $list->{'admin'}{'dmarc_protection'}{'phrase'}
        || 'name_via_list';
    my $newName;
    my $newComment;
    my $anonaddr;
    my $anonphrase;
    if ($listtype eq 'owner' or $listtype eq 'editor') {
        # -request or -editor address
        $anonaddr = Sympa::get_address($list, $listtype);
    } else {
        $anonaddr = $list->{'admin'}{'dmarc_protection'}{'other_email'};
        $anonaddr = Sympa::get_address($list)
            unless $anonaddr and $anonaddr =~ /\@/;
        my @anonFrom = Mail::Address->parse($anonaddr);
        if (@anonFrom) {
            $anonaddr   = $anonFrom[0]->address;
            $anonphrase = $anonFrom[0]->phrase;
        }
    }
    $log->syslog('debug', 'Anonymous From: %s', $anonaddr);

    if ($from) {
        # We should always have a From address in reality, unless the
        # message is from a badly-behaved automate.
        my $origName =
            MIME::EncWords::decode_mimewords($from->phrase,
            Charset => 'UTF-8')
            if defined $from->phrase;
        unless (defined $origName and $origName =~ /\S/) {
            # If we dont have a Phrase, should we search the Sympa
            # database for the sender to obtain their name that way?
            # Might be difficult.
            ($origName) = split /\@/, $from_address;
        }

        if ($phraseMode eq 'name_and_email') {
            $newName    = $origName;
            $newComment = $from_address;
        } elsif ($phraseMode eq 'name_email_via_list') {
            $newName = $origName;

            if ($listtype eq 'owner') {
                $newComment = $language->gettext_sprintf(
                    '%s via Owner Address of %s Mailing List',
                    $from_address, $list->{'name'});
            } elsif ($listtype eq 'editor') {
                $newComment = $language->gettext_sprintf(
                    '%s via Moderator Address of %s Mailing List',
                    $from_address, $list->{'name'});
            } else {
                $newComment =
                    $language->gettext_sprintf('%s via %s Mailing List',
                    $from_address, $list->{'name'});
            }
        } elsif ($phraseMode eq 'name_via_list') {
            $newName = $origName;

            if ($listtype eq 'owner') {
                $newComment = $language->gettext_sprintf(
                    'via Owner Address of %s Mailing List',
                    $list->{'name'});
            } elsif ($listtype eq 'editor') {
                $newComment = $language->gettext_sprintf(
                    'via Moderator Address of %s Mailing List',
                    $list->{'name'});
            } else {
                $newComment =
                    $language->gettext_sprintf('via %s Mailing List',
                    $list->{'name'});
            }
        } elsif ($phraseMode eq 'list_for_email') {
            if ($listtype eq 'owner') {
                $newName = $language->gettext_sprintf(
                    'Owner Address of %s Mailing List',
                    $list->{'name'});
            } elsif ($listtype eq 'editor') {
                $newName = $language->gettext_sprintf(
                    'Moderator Address of %s Mailing List',
                    $list->{'name'});
            } else {
                $newName = $language->gettext_sprintf('%s Mailing List',
                    $list->{'name'});
            }

            $newComment =
                $language->gettext_sprintf('on behalf of %s', $origName);
        } elsif ($phraseMode eq 'list_for_name') {
            if ($listtype eq 'owner') {
                $newName = $language->gettext_sprintf(
                    'Owner Address of %s Mailing List',
                    $list->{'name'});
            } elsif ($listtype eq 'editor') {
                $newName = $language->gettext_sprintf(
                    'Moderator Address of %s Mailing List',
                    $list->{'name'});
            } else {
                $newName = $language->gettext_sprintf('%s Mailing List',
                    $list->{'name'});
            }

            $newComment =
                $language->gettext_sprintf('on behalf of %s', $from_address);
        } else {
            $newName = $origName;
        }

        $self->add_header('Reply-To', $from_address)
            unless $self->get_header('Reply-To');
    }
    # If the new From email address has a Phrase component, then
    # append it
    if (defined $anonphrase and length $anonphrase) {
        if (defined $newName and $newName =~ /\S/) {
            $newName .= ' ' . $anonphrase;
        } else {
            $newName = $anonphrase;
        }
    }
    $newName = $language->gettext('Anonymous')
        unless defined $newName and $newName =~ /\S/;

    $self->add_header('X-Original-From', $original_from);
    $self->replace_header(
        'From',
        Sympa::Tools::Text::addrencode(
            $anonaddr,                               $newName,
            Conf::lang2charset($language->get_lang), $newComment
        )
    );
}

# Strict auto policy - is the sender domain policy to reject
sub _check_dmarc_rr {
    my $self  = shift;
    my $email = shift;

    # Net::DNS is optional.
    unless ($Net::DNS::VERSION) {
        $log->syslog('err',
            'Unable to get DNS RR. Net::DNS required. Install it first');
        return 0;
    }

    my $domain = $email;
    $domain =~ s/\A.*\@//;    # strip local part.

    my $list = $self->{context};
    my $dns  = Net::DNS::Resolver->new;

    my $rrstr;
    my $sp = 0;
    while (0 <= index $domain, '.') {
        my $packet = $dns->query("_dmarc.$domain", 'TXT');
        next unless $packet;

        ($rrstr) = grep { $_ and $_ =~ /\Av=DMARC/i } map {
            # Note: txtdata() of Net::DNS::RR::TXT >=0.69 returns array of
            # text fragments in array context. Take care to get values in
            # scalar context.
            my $rrstr = $_->txtdata if $_->type eq 'TXT';
            $rrstr;
        } $packet->answer;
        last if $rrstr;
    } continue {
        $domain =~ s/\A[^.]*[.]//;
        $sp = 1;
    }
    return 0 unless $rrstr;    # no valid record found.

    my %rr = _parse_dmarc_rr($rrstr);
    my $policy = ($sp and $rr{sp}) || $rr{p};
    return 0 unless $policy;    # no policy found.

    $log->syslog('debug', 'DMARC DNS record found: %s', $rrstr);
    $self->add_header('X-Original-DMARC-Record', sprintf 'domain=%s; %s',
        $domain, $rrstr);

    my @modes = @{$list->{'admin'}{'dmarc_protection'}{'mode'} || []};
    unless (
        (lc $policy eq 'reject' and grep { $_ eq 'dmarc_reject' } @modes)
        or (lc $policy eq 'quarantine'
            and grep { $_ eq 'dmarc_quarantine' } @modes)
        or grep { $_ eq 'dmarc_any' } @modes
    ) {
        $log->syslog('debug', 'No DMARC policy matched');
        return 0;
    } else {
        $log->syslog('debug', 'DMARC policy "%s" matched', $policy);
        return 1;
    }
}

# Parse DMARC TXT RR.
# Partially borrowed from parse() in Mail::DMARC::Policy by MBRADSHAW@cpan.
sub _parse_dmarc_rr {
    my $str = shift;

    my $cleaned = $str;
    $cleaned =~ s/\s//g;      # remove whitespace
    $cleaned =~ s/\\;/;/g;    # replace \;  with ;
    $cleaned =~ s/;;/;/g;     # replace ;;  with ;
    $cleaned =~ s/;0;/;/g;    # replace ;0; with ;
    chop $cleaned if ';' eq substr $cleaned, -1, 1;    # remove a trailing ;
    my @tag_vals = split /;/, $cleaned;

    my %rr;
    foreach my $tv (@tag_vals) {
        my ($tag, $value) = split /=|:|-/, $tv, 2;
        next unless defined $tag and defined $value and length $value;
        $rr{lc $tag} = $value;
    }
    return %rr;
}

# Old name: Sympa::List::compute_topic()
sub compute_topic {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    my $list = $self->{context};
    return undef unless ref $list eq 'Sympa::List';

    my @topic_array;
    my %topic_hash;
    my %keywords;

    # Getting keywords.
    foreach my $topic (@{$list->{'admin'}{'msg_topic'} || []}) {
        my $list_keyw = Sympa::Tools::Data::get_array_from_splitted_string(
            $topic->{'keywords'});

        foreach my $keyw (@{$list_keyw}) {
            $keywords{$keyw} = $topic->{'name'};
        }
    }

    # getting string to parse
    # We convert it to UTF-8 for case-ignore match with non-ASCII keywords.
    my $mail_string = '';
    if (index($list->{'admin'}{'msg_topic_keywords_apply_on'}, 'subject') >=
        0) {
        $mail_string = $self->{'decoded_subject'} . "\n";
    }
    unless ($list->{'admin'}{'msg_topic_keywords_apply_on'} eq 'subject') {
        my $entity = $self->as_entity;
        my $eff_type = $entity->effective_type || '';
        if ($eff_type eq 'multipart/signed' and $entity->parts) {
            $entity = $entity->parts(0);
        }
        #FIXME: Should also handle application/pkcs7-mime format.

        # get bodies of any text/* parts, not digging nested subparts.
        my @parts;
        if ($entity->parts) {
            @parts = $entity->parts;
        } else {
            @parts = ($entity);
        }
        foreach my $part (@parts) {
            next unless $part->effective_type =~ /^text\//i;
            my $charset = $part->head->mime_attr("Content-Type.Charset");
            $charset = MIME::Charset->new($charset);
            $charset->encoder('UTF-8');

            if (defined $part->bodyhandle) {
                my $body = $part->bodyhandle->as_string();
                my $converted;
                eval { $converted = $charset->encode($body); };
                if ($EVAL_ERROR) {
                    $converted = $body;
                    $converted =~ s/[^\x01-\x7F]/?/g;
                }
                $mail_string .= $converted . "\n";
            }
        }
    }
    # foldcase string
    $mail_string = Sympa::Tools::Text::foldcase($mail_string);

    # parsing
    foreach my $keyw (keys %keywords) {
        if (index($mail_string, Sympa::Tools::Text::foldcase($keyw)) >= 0) {
            $topic_hash{$keywords{$keyw}} = 1;
        }
    }

    # for no double
    foreach my $k (sort keys %topic_hash) {
        push @topic_array, $k if $topic_hash{$k};
    }

    unless (@topic_array) {
        return '';
    } else {
        return join(',', @topic_array);
    }
}

sub get_id {
    my $self = shift;

    my $id;
    # Tentative.  Alternatives for more general ID in the future.
    if ($self->{'messagekey'}) {
        $id = $self->{'messagekey'};
    } elsif ($self->{'filename'}) {
        my @parts = split /\//, $self->{'filename'};
        $id = pop @parts;
    } elsif (exists $self->{'message_id'}) {
        $id = $self->{'message_id'};
    }

    my $shelved;
    if (%{$self->{shelved} || {}}) {
        $shelved = sprintf 'shelved:%s', join(
            ';',
            map {
                my $v = $self->{shelved}{$_};
                ("$v" eq '1') ? $_ : sprintf('%s=%s', $_, $v);
                }
                grep {
                $self->{shelved}{$_}
                } sort keys %{$self->{shelved}}
        );
    }

    return join '/', grep {$_} ($id, $shelved);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Message - Mail message embedding for internal use in Sympa

=head1 SYNOPSIS

  use Sympa::Message;
  my $message = Sympa::Message->new($serialized, context => $list);

=head1 DESCRIPTION

While processing a message in Sympa, we need to link information to the
message, modify headers and such.  This was quite a problem when a message was
signed, as modifying anything in the message body would alter its MD5
footprint. And probably make the message to be rejected by clients verifying
its identity (which is somehow a good thing as it is the reason why people use
MD5 after all). With such messages, the process was complex. We then decided
to embed any message treated in a "Message" object, thus making the process
easier.

=head2 Methods and functions

=over

=item new ( $serialized, context =E<gt> $that, KEY =E<gt> value, ... )

I<Constructor>.
Creates a new L<Sympa::Message> object.

Parameters:

=over

=item $serialized

Serialized message.

=item context =E<gt> object

Context.  L<Sympa::List> object, Robot or C<'*'>.

=item key =E<gt> value, ...

Metadata.

=back

Returns:

A new L<Sympa::Message> object, or I<undef>, if something went wrong.

=item dup ( )

I<Copy constructor>.
Gets deep copy of instance.

=item to_string ( [ original =E<gt> 0|1 ] )

I<Serializer>.
Returns serialized data of Message object.

Parameter:

=over

=item original =E<gt> 0|1

If set to 1 and content has been decrypted, returns original content.
Default is 0.

=back

Returns:

Serialized representation of Message object.

=item add_header ( $field, $value, [ $index ] )

I<Instance method>.
Adds a header field named $field with body $value.
If $index is given, the field will be inserted at the place it indicates:
If it is C<0>, the field will be prepended.

=item delete_header ( $field, [ $index ] )

I<Instance method>.
Deletes all occurrences of the header field named $field.

=item replace_header ( $field, $value, [ $index ] )

I<Instance method>.
Replaces header fields named $field with $value.

=item head

I<Instance method>.
Gets header of the message as L<MIME::Head> instance.

Note that returned value is real reference to internal data structure.
Even if it was changed, string representation of message may not be updated.
Alternatively, use L</add_header>(), L</delete_header>() or
L</replace_header>() to modify header.

=item check_spam_status ( )

I<Instance method>.
Gets spam status according to spam_status scenario
and sets it as {spam_status} attribute.

=item dkim_sign ( dkim_d =E<gt> $d, [ dkim_i =E<gt> $i ],
dkim_selector =E<gt> $selector, dkim_privatekey =E<gt> $privatekey )

I<Instance method>.
Adds DKIM signature to the message.

=item check_dkim_signature ( )

I<Instance method>.
Checks DKIM signature of the message
and sets or clears {dkim_pass} item of the message object.

=item remove_invalid_dkim_signature ( )

I<Instance method>.
Verifies DKIM signatures included in the message,
and if any of them are invalid, removes them.

=item check_arc_chain ( )

I<Instance method>.
Checks ARC chain of the message
and sets {shelved}{arc_cv} item of the message object.

=item arc_seal ( )
 
I<Instance method>.
Adds a new ARC seal if there's an arc_cv from check_arc_chain and
the cv is none or valid.
 
=item as_entity ( )

I<Instance method>.
Gets message content as MIME entity (L<MIME::Entity> instance).

Note that returned value is real reference to internal data structure.
Even if it was changed, string representation of message may not be updated.
Below is better way to modify message.

    my $entity = $message->as_entity->dup;
    # ... Modify $entity...
    $message->set_entity($entity);

=item set_entity ( $entity )

I<Instance method>.
Updates message with MIME entity (L<MIME::Entity> instance).
String representation will be automatically updated.

=item as_string ( )

I<Instance method>.
Gets a string representation of message.

Parameter:

=over

=item original =E<gt> 0|1

If set to 1 and content has been decrypted, returns original content.
Default is 0.

=back

Note that method like "set_string()" does not exist:
You would be better to create new instance rather than replacing entire
content.

=item body_as_string ( )

I<Instance method>.
Gets body of the message as string.

Note that the result won't be decoded.

=item header_as_string ( )

I<Instance method>.
Gets header part of the message as string.

Note that the result won't be decoded nor unfolded.

=item get_header ( $field, [ $sep ] )

I<Instance method>.
Gets value(s) of header field $field, stripping trailing newline.

B<In scalar context> without $sep, returns first occurrence or C<undef>.
If $sep is defined, returns all occurrences joined by it, or C<undef>.
Otherwise B<in array context>, returns an array of all occurrences or C<()>.

Note:
Folding newlines will not be removed.

=item get_decoded_header ( $tag, [ $sep ] )

I<Instance method>.
Returns header value decoded to UTF-8 or undef.
Trailing newline will be removed.
If $sep is given, returns all occurrences joined by it.

=item dump ( $output )

I<Instance method>.
Dumps a Message object to a stream.

Parameters:

=over

=item $output

the stream to which dump the object

=back

Returns:

=over

=item 1

if everything's alright

=back

=item add_topic ( $output )

Note:
No longer used.

I<Instance method>.
Adds topic and puts header X-Sympa-Topic.

Parameters:

=over

=item $output

the string containing the topic to add

=back

Returns:

=over

=item 1

if everything's alright

=back

=item get_topic ( )

Note:
No longer used.

I<Instance method>.
Gets topic of message.

Parameters:

None.

Returns:

=over

=item the topic

if it exists

=item empty string

otherwise

=back

=item clean_html ( )

I<Instance method>.
Encodes HTML parts of the message by UTF-8 and strips scripts included in
them.

=item smime_decrypt ( )

I<Instance method>.
Decrypts message using private key of user.

Note that this method modifies Message object.

Parameters:

None.

Returns:

True value if message was decrypted.  Otherwise false value.

If decrypting succeeded, {smime_crypted} item is set.

=item smime_encrypt ( $email )

I<Instance method>.
Encrypts message using certificate of user.

Note that this method modifies Message object.

Parameters:

=over

=item $email

E-mail address of user.

=back

Returns:

True value if encryption succeeded, or C<undef>.

=item smime_sign ( )

I<Instance method>.
Adds S/MIME signature to the message.

Signing key is taken from what stored in list directory.

Parameters:

None.

Returns:

True value if message was successfully signed.
Otherwise false value.

=item check_smime_signature ( )

I<Instance method>.
Verifies S/MIME signature of the message,
and if verification succeeded, sets {smime_signed} item true.

Parameters:

None

Returns:

1 if signature is successfully verified.
0 otherwise.
C<undef> if something went wrong.

=item is_signed ( )

I<Instance method>.
Checks if the message is signed.

B<Note>:
This checks if the message has appropriate content type and
header parameters.  Use check_smime_signature() to check if the message has
properly signed content.

Currently, S/MIME-signed messages with content type
"multipart/signed" or "application/pkcs7-mime" (with smime-type="signed-data"
parameter) are recognized.
Enveloped-only messages are not supported.
The other signature mechanisms such as PGP/MIME have not been supported yet.

Parameters:

None.

Returns:

C<1> if the message is considered signed.
C<0> otherwise.

=item personalize ( $list, [ $rcpt ], [ $data ] )

I<Instance method>.
Personalizes a message with custom attributes of a user.

Parameters:

=over

=item $list

L<List> object.

=item $rcpt

Recipient.

=item $data

Hashref.  Additional data to be interpolated into personalized message.

=back

Returns:

Modified message itself, or C<undef> if error occurred.

=item test_personalize ( $list )

DEPRECATED by Sympa 6.2.13.
No longer available.

I<Instance method>.
Tests if personalization can be performed successfully over all subscribers
of list.

Parameters:

Returns:

C<1> if succeed, or C<undef>.

=item personalize_text ( $body, $list, [ $rcpt ], [ $data ] )

I<Function>.
Retrieves the customized data of the
users then parses the text. It returns the
personalized text.

Parameters:

=over

=item $body

Message body with the TT2.

=item $list

L<List> object.

=item $rcpt

The recipient email.

=item $data

Hashref.  Additional data to be interpolated into personalized message.

=back

Returns:

Customized text, or C<undef> if error occurred.

=item prepare_message_according_to_mode ( $mode, $list )

I<Instance method>.
Transforms the message according to reception mode:
C<'mail'>, C<'notice'> or C<'txt'>.
Note: 'html' mode was deprecated as of 6.2.23b.2.

By C<'nomail'>, C<'digest'>, C<'digestplain'> or C<'summary'> mode,
the message is not modified.

Returns modified message object itself, or C<undef> if transformation failed.

=item decorate ( )

OBSOLETED.
Use prepare_message_according_to_mode('mail', $list).

I<Instance method>.
Adds footer/header to a message.

=item reformat_utf8_message ( )

I<Instance method>.
Reformats bodies of text parts contained in the message using
recommended encoding schema and/or charsets defined by MIME::Charset.

MIME-compliant headers are appended / modified.  And custom X-Mailer:
header is appended :).

Parameters:

=over

=item $attachments

ref(ARRAY) - messages to be attached as subparts.

=back

Returns:

string

=item get_plain_body ( )

I<Instance method>.
Gets decoded content of text/plain part.

The text will be converted to UTF-8.
Flowed text (see RFC 3676) will be conjuncted.

=item check_virus_infection ( [ debug =E<gt> 1 ] )

I<Instance method>.
Checks the message using anti-virus plugin, if configuration requests it.

Parameter:

TBD.

Returns:

The name of malware the message contains, if any;
C<"unknown"> for unidentified malware;
C<undef> if checking failed;
otherwise C<0>.

=item get_plaindigest_body ( )

I<Instance method>.
Returns a plain text version of message, suitable for use in plain text
digests.

=over

=item *

Most attachments are stripped out and replaced with a
note that they've been stripped. text/plain parts are
retained.

=item *

An attempt to convert text/html parts to plain text is made
if there is no text/plain alternative.

=item *

All messages are converted from their original character
set to UTF-8.

=item *

Parts of type message/rfc822 are recursed
through in the same way, with brief headers included.

=item *

Any line consisting only of 30 hyphens has the first
character changed to space (see RFC 1153). Lines are
wrapped at 76 columns.

=back

Parameters:

None.

Returns:

String.

=item dmarc_protect ( )

I<Instance method>.
Munges the C<From:> header field if we are using DMARC Protection mode.

Parameters:

None.

Returns:

None.
C<From:> field of the message may be modified.

=item compute_topic ( )

I<Instance method>.
Compute the topic of the message. The topic is got
from keywords defined in list parameter
msg_topic.keywords. The keyword is applied on the
subject and/or the body of the message according
to list parameter msg_topic_keywords_apply_on

Parameters:

None.

Returns:

String of tag(s), can be separated by ',', can be empty.

=item get_id ( )

I<Instance method>.
Gets unique identifier of instance.

=back

=head2 Context and Metadata

Context and metadata given to constructor are accessible as hash elements of
object.  These are typically used.

=over

=item {context}

Context of the message, L<Sympa::List> object, robot or C<'*'>.

=item {date}

The UNIX time messages was initially accepted, or the time message should be
delivered.

=item {domainpart}

=item {listname}

=item {listtype}

=item {localpart}

Domain, name, type and local part of context.

=item {priority}

Priority of the message.

=item {tag}

Tag of packet used by bulk spool to control logging.
C<'0'> is the first message of multiple packet.
C<'z'> is the last.
C<'s'> is the single message with single packet.

=item {time}

The Unix time in floating point number when the message was stored into the
spool.  This is used by bulk spool.

=back

=head2 Attributes

These are accessible as hash elements of objects.

=over

=item {checksum}

No longer used.  It is kept for compatibility with Sympa 6.1.x or earlier.
See also upgrade_send_spool(1).

=item {envelope_sender}

Envelope sender, a.k.a. "Unix From".
This is not always same as {sender} attribute
nor the content of C<From:> field.

C<'E<lt>E<gt>'> will be used for "null envelope sender".

=item {family}

Name of family (see L<Sympa::Family>) the message corresponds to.
This is given by familyqueue(8) program.

=item {gecos}

Display name of actual sender (see {sender} below), if any.

=item {md5_check}

True value indicates that the message has been authenticated by C<md5> level
(password authentication).
This is set by web mailer of WWSympa and used by incoming spool.

=item {message_id}

Original message ID of the message.

=item {rcpt}

Recipients for delivery.
This is kept for compatibility with earlier releases.

=item {sender}

Actual sender of the message.
This is determined according to C<sender_headers> configuration parameter.
See also {envelope_sender} above.

=item {shelved}

Shelved processing.
Hashref with multiple items.
Currently these items are available:

=over

=item dkim_sign =E<gt> 1

Adding DKIM signature.

=item dmarc_protect =E<gt> 1

DMARC protection.  See also L</dmarc_protect>().

=item merge =E<gt> 1

Personalizing.

=item smime_encrypt =E<gt> 1

Adding S/MIME encryption.

=item smime_sign =E<gt> 1

Adding S/MIME signature.

=item tracking =E<gt> C<dsn>|C<mdn>|C<r>|C<w>|C<verp>

Requesting tracking feature including VERP.

=back

This is used by bulk spool.

=item {spam_status}

Result of spam check.
This is set by L</check_spam_status>() method.

=back

=head2 Serialization

L<Sympa::Message> object includes number of slots as hash items:
B<metadata>, B<context>, B<attributes> and B<message content>.
Metadata including context are given by spool:
See L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

Logically, objects are stored into physical spool as B<serialized form>
and deserialized when they are fetched from spool.
B<Attributes> will be serialized and deserialized along with raw message
content.
Attributes are encoded in C<X-Sympa-*:> pseudo-header fields and
C<Return-Path:> header field.
Below is an example of serialized form.

  X-Sympa-Message-ID: 123456789.12345@domain.name : {message_id} attribute
  X-Sympa-Sender: user01@user.sympa.test          : {sender} attribute
  X-Sympa-Display-Name: Infant                    : {gecos} attribute
  X-Sympa-Shelved: dkim_sign; tracking=mdn        : {shelved} attribute
  X-Sympa-Spam-Status: ham                        : {spam_status} attribute
  Return-Path: sympa-request@domain.name          : {envelope_sender} attribute
  Message-Id: <123456789.12345@domain.name>       :   ---
  From: Infant <user@other.host.dom>              :    |
  To: User <user@some.host.name>                  :    |
  Subject: Howdy world                            :    | Raw message content
  X-Sympa-Topic: sometopic                        :    |
                                                  :    |
  Bonjour, le monde.                              :    |
                                                  :   ---

On msg, automatic and bounce spools,
C<Return-Path:> header fields are given by MDA
and C<X-Sympa-*:> header fields are given by queue programs.
On other spools, they are given by components of Sympa.

Pseudo-header fields I<should> appear at beginning of serialized content.
Fields appear at other places (e.g. C<X-Sympa-Topic:> field above) are not
attributes but are the part of raw message content.

Pseudo-header fields I<should not> be included in actually sent messages.

=head1 CAVEAT

=head2 Adding C<Return-Path:> field

We trust in C<Return-Path:> header field only at the top of message
to prevent forgery.  To ensure it will be added to messages by MDA,

=over

=item Sendmail

Add C<P> in the C<F=> flags of local mailer line (such as C<Mlocal>).

=item Postfix

=over

=item local(8)

Prepending C<Return-Path:> is available by default.

=item pipe(8)

Add C<R> to the C<flags=> attributes in master.cf.

Additionally with Postfix 2.3 or later, add an empty C<null_sender=>
attribute.
Or "null envelope sender" would be replaced with C<E<lt>MAILER-DAEMONE<gt>>.

=back

=item Exim

Set C<return_path_add> to be true with pipe_transport.

=item qmail

Use preline(1).

=item sympa-milter

As of version 0.7, prepending C<Return-Path:> is available.

=back

=head1 BUGS

L<get_plaindigest_body>()
seems to ignore any text after a UUencoded attachment.

=head1 HISTORY

L<Message> module appeared on Sympa 3.3.6.
It was initially written by:

=over

=item * Serge Aumont <sa AT cru.fr>

=item * Olivier SalaE<252>n <os AT cru.fr>

=back

L<get_plaindigest_body>, ex. L<PlainDigest/plain_body_as_string>,
was initially written by Chris Hastie.  It appeared on Sympa 4.2b.1.

  (c) Chris Hastie 2004 - 2008.

Renamed and merged L<Sympa::Message> appeared on Sympa 6.2.

=cut
