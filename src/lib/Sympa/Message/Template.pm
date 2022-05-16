# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2020, 2021, 2022 The Sympa Community. See the
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

package Sympa::Message::Template;

use strict;
use warnings;
use DateTime;
use Encode qw();
use MIME::EncWords;

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::Log;
use Sympa::Spool;
use Sympa::Template;
use Sympa::Tools::Data;
use Sympa::Tools::Password;
use Sympa::Tools::SMIME;
use Sympa::Tools::Text;
use Sympa::User;

use base qw(Sympa::Message);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Old names: (part of) mail::mail_file(), mail::parse_tt2_messageasstring(),
# List::send_file(), List::send_global_file().
sub new {
    my $class   = shift;
    my %options = @_;

    my $that    = $options{context};
    my $tpl     = $options{template};
    my $who     = $options{rcpt};
    my $context = $options{data} || {};

    die 'Parameter $tpl is not defined'
        unless defined $tpl and length $tpl;

    my ($list, $family, $robot_id, $domain);
    if (ref $that eq 'Sympa::List') {
        $robot_id = $that->{'domain'};
        $list     = $that;
        $domain   = $that->{'domain'};
    } elsif (ref $that eq 'Sympa::Family') {
        $robot_id = $that->{'domain'};
        $family   = $that;
        $domain   = $that->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
        $domain = Conf::get_robot_conf($that, 'domain');
    } else {
        $robot_id = '*';
        $domain   = $Conf::Conf{'domain'};
    }

    my $data = Sympa::Tools::Data::dup_var($context);

    ## Any recipients
    if (not $who or (ref $who and !@$who)) {
        $log->syslog('err', 'No recipient for sending %s', $tpl);
        return undef;
    }

    ## Unless multiple recipients
    unless (ref $who) {
        unless ($data->{'user'}) {
            $data->{'user'} = Sympa::User->new($who);
        }

        if ($list) {
            # FIXME: Don't overwrite date & update_date.  Format datetime on
            # the template.
            my $subscriber =
                Sympa::Tools::Data::dup_var($list->get_list_member($who));
            if ($subscriber) {
                $data->{'subscriber'}{'date'} =
                    $language->gettext_strftime("%d %b %Y",
                    localtime($subscriber->{'date'}));
                $data->{'subscriber'}{'update_date'} =
                    $language->gettext_strftime("%d %b %Y",
                    localtime($subscriber->{'update_date'}));
                if ($subscriber->{'bounce'}) {
                    $subscriber->{'bounce'} =~
                        /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;

                    $data->{'subscriber'}{'first_bounce'} =
                        $language->gettext_strftime("%d %b %Y", localtime $1);
                }
            }
        }
    }

    # Lang
    $language->push_lang(
        $data->{'lang'},
        $data->{'user'}{'lang'},
        ($list ? $list->{'admin'}{'lang'} : undef),
        Conf::get_robot_conf($robot_id, 'lang'), 'en'
    );
    $data->{'lang'} = $language->get_lang;
    $language->pop_lang;

    if ($list) {
        # Trying to use custom_vars
        if (defined $list->{'admin'}{'custom_vars'}) {
            $data->{'custom_vars'} = {};
            foreach my $var (@{$list->{'admin'}{'custom_vars'}}) {
                $data->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
            }
        }
    }

    foreach my $p (
        'email', 'gecos', 'listmaster', 'wwsympa_url',
        'title', 'listmaster_email'
    ) {
        $data->{'conf'}{$p} = Conf::get_robot_conf($robot_id, $p);
    }
    $data->{'domain'} = $domain;
    $data->{'conf'}{'version'} = Sympa::Constants::VERSION();
    $data->{'sender'} ||= $who;

    # Compat.: Deprecated attributes of Robot.
    $data->{'conf'}{'sympa'} = Sympa::get_address($robot_id);
    $data->{'conf'}{'request'} = Sympa::get_address($robot_id, 'owner');
    # No longer used.
    $data->{'robot_domain'} = $domain;
    # Compat. < 6.2.32
    $data->{'conf'}{'host'} = $domain;

    if ($list) {
        $data->{'list'}{'lang'}    = $list->{'admin'}{'lang'};
        $data->{'list'}{'name'}    = $list->{'name'};
        $data->{'list'}{'subject'} = $list->{'admin'}{'subject'};
        $data->{'list'}{'owner'}   = [$list->get_admins('owner')];
        $data->{'list'}{'dir'} = $list->{'dir'};    #FIXME: Required?
        $data->{'list'}{'family'} = {name => $list->get_family->{'name'}}
            if $list->get_family;
        # Compat. < 6.2.32
        $data->{'list'}{'domain'} = $list->{'domain'};
        $data->{'list'}{'host'}   = $list->{'domain'};
    } elsif ($family) {
        $data->{family} = {name => $family->{'name'},};
    }

    # Sign mode
    my $smime_sign = Sympa::Tools::SMIME::find_keys($that, 'sign');

    if ($list) {
        # if the list have it's private_key and cert sign the message
        # . used only for the welcome message, could be useful in other case?
        # . a list should have several certificates and use if possible a
        #   certificate issued by the same CA as the recipient CA if it exists
        if ($smime_sign) {
            $data->{'fromlist'} = Sympa::get_address($list);
            $data->{'replyto'} = Sympa::get_address($list, 'owner');
        } else {
            $data->{'fromlist'} = Sympa::get_address($list, 'owner');
        }
    }
    my $unique_id = Sympa::unique_message_id($robot_id);
    $data->{'boundary'} = sprintf '----------=_%s', $unique_id
        unless $data->{'boundary'};
    $data->{'boundary1'} = sprintf '---------=1_%s', $unique_id
        unless $data->{'boundary1'};
    $data->{'boundary2'} = sprintf '---------=2_%s', $unique_id
        unless $data->{'boundary2'};

    my $self = $class->_new_from_template($that, $tpl . '.tt2',
        $who, $data, %options);
    return undef unless $self;

    # Shelve S/MIME signing.
    $self->{shelved}{smime_sign} = 1
        if $smime_sign;
    # Shelve DKIM signing.
    if (Conf::get_robot_conf($robot_id, 'dkim_feature') eq 'on') {
        my $dkim_add_signature_to =
            Conf::get_robot_conf($robot_id, 'dkim_add_signature_to');
        if ($list and $dkim_add_signature_to =~ /list/
            or not $list and $dkim_add_signature_to =~ /robot/) {
            $self->{shelved}{dkim_sign} = 1;
        }
    }

    # Set default envelope sender.
    if (exists $options{envelope_sender}) {
        $self->{envelope_sender} = $options{envelope_sender};
    } elsif ($list) {
        $self->{envelope_sender} = Sympa::get_address($list, 'return_path');
    } else {
        $self->{envelope_sender} = Sympa::get_address($robot_id, 'owner');
    }

    # Set default delivery date.
    $self->{date} = (exists $options{date}) ? $options{date} : time;

    # Set priority if specified.
    $self->{priority} = $options{priority}
        if exists $options{priority};

    # Shelve tracking if speficied.
    $self->{shelved}{tracking} = $options{tracking}
        if exists $options{tracking};

    # Assign unique ID and log it.
    my $marshalled =
        Sympa::Spool::marshal_metadata($self, '%s@%s.%ld.%ld,%d',
        [qw(localpart domainpart date PID RAND)]);
    $self->{messagekey} = $marshalled;

    return $self;
}

#TODO: This would be merged in new() because used only by it.
sub _new_from_template {
    $log->syslog('debug2', '(%s, %s, %s, %s, %s)', @_);
    my $class    = shift;
    my $that     = shift || '*';
    my $filename = shift;
    my $rcpt     = shift;
    my $data     = shift;
    my %options  = @_;

    my ($list, $family, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $list->{'domain'};
    } elsif (ref $that eq 'Sympa::Family') {
        $family   = $that;
        $robot_id = $family->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $message_as_string;
    my %header_ok;    # hash containing no missing headers
    my $existing_headers = 0;    # the message already contains headers

    ## We may receive a list of recipients
    die sprintf 'Wrong type of reference for $rcpt: %s', ref $rcpt
        if ref $rcpt and ref $rcpt ne 'ARRAY';

    ## Charset for encoding
    $data->{'charset'} ||= Conf::lang2charset($data->{'lang'});

    # Template file parsing
    # If context is List, add list directory and list archives to get the
    # 'info' file and last message.
    my $template = Sympa::Template->new(
        $that,
        subdir => 'mail_tt2',
        lang   => $data->{'lang'},
        include_path =>
            ($list ? [$list->{'dir'}, $list->{'dir'} . '/archives'] : [])
    );
    unless ($template->parse($data, $filename, \$message_as_string)) {
        $log->syslog(
            'err',     'Can\'t parse template %s: %s',
            $filename, $template->{last_error}
        );
        return undef;
    }

    # Does the message include headers ?
    if ($data->{'headers'}) {
        foreach my $field (keys %{$data->{'headers'}}) {
            $field =~ tr/A-Z/a-z/;
            $header_ok{$field} = 1;
        }
    }

    foreach my $line (split /\n/, $message_as_string) {
        last if ($line =~ /^\s*$/);
        if ($line =~ /^[\w-]+:\s*/) {
            ## A header field
            $existing_headers = 1;
        } elsif ($existing_headers and $line =~ /^\s/) {
            ## Following of a header field
            next;
        } else {
            last;
        }

        foreach my $header (
            qw(message-id date to from subject reply-to
            mime-version content-type content-transfer-encoding)
        ) {
            if ($line =~ /^$header\s*:/i) {
                $header_ok{$header} = 1;
                last;
            }
        }
    }

    ## ADD MISSING HEADERS
    my $headers = "";

    unless ($header_ok{'message-id'}) {
        $headers .=
            sprintf("Message-Id: %s\n", Sympa::unique_message_id($robot_id));
    }

    unless ($header_ok{'date'}) {
        # Format current time.
        # If setting local timezone fails, fallback to UTC.
        my $date =
            (eval { DateTime->now(time_zone => 'local') } || DateTime->now)
            ->strftime('%a, %{day} %b %Y %H:%M:%S %z');
        $headers .= sprintf "Date: %s\n", $date;
    }

    unless ($header_ok{'to'}) {
        my $to;
        # Currently, bare e-mail address is assumed.  Complex ones such as
        # "phrase" <email> won't be allowed.
        if (ref($rcpt)) {
            if ($data->{'to'}) {
                $to = $data->{'to'};
            } else {
                $to = join(",\n   ", @{$rcpt});
            }
        } else {
            $to = $rcpt;
        }
        $headers .= "To: $to\n";
    }
    unless ($header_ok{'from'}) {
        unless (defined $data->{'from'}) {
            # DSN should not have command address <sympa> to prevent looping
            # by dumb auto-responder (including Sympa command robot itself).
            my $sympa =
                (       exists $options{envelope_sender}
                    and defined $options{envelope_sender}
                    and $options{envelope_sender} eq '<>')
                ? Sympa::get_address($robot_id, 'owner')    # sympa-request
                : Sympa::get_address($robot_id);
            $headers .= sprintf "From: %s\n",
                Sympa::Tools::Text::addrencode($sympa,
                Conf::get_robot_conf($robot_id, 'gecos'),
                $data->{'charset'});
        } elsif ($data->{'from'} eq 'sympa'
            or $data->{'from'} eq $data->{'conf'}{'sympa'}) {
            #XXX NOTREACHED: $data->{'from'} was obsoleted.
            $headers .= 'From: '
                . Sympa::Tools::Text::addrencode(
                $data->{'conf'}{'sympa'},
                $data->{'conf'}{'gecos'},
                $data->{'charset'}
                ) . "\n";
        } else {
            #XXX NOTREACHED: $data->{'from'} was obsoleted.
            $headers .= "From: "
                . MIME::EncWords::encode_mimewords(
                Encode::decode('utf8', $data->{'from'}),
                'Encoding' => 'A',
                'Charset'  => $data->{'charset'},
                'Field'    => 'From'
                ) . "\n";
        }
    }
    unless ($header_ok{'subject'}) {
        $headers .= "Subject: "
            . MIME::EncWords::encode_mimewords(
            Encode::decode('utf8', $data->{'subject'}),
            'Encoding' => 'A',
            'Charset'  => $data->{'charset'},
            'Field'    => 'Subject'
            ) . "\n";
    }
    unless ($header_ok{'reply-to'}) {
        $headers .= "Reply-to: "
            . MIME::EncWords::encode_mimewords(
            Encode::decode('utf8', $data->{'replyto'}),
            'Encoding' => 'A',
            'Charset'  => $data->{'charset'},
            'Field'    => 'Reply-to'
            )
            . "\n"
            if ($data->{'replyto'});
    }
    if ($data->{'headers'}) {
        foreach my $field (keys %{$data->{'headers'}}) {
            $headers .=
                $field . ': '
                . MIME::EncWords::encode_mimewords(
                Encode::decode('utf8', $data->{'headers'}{$field}),
                'Encoding' => 'A',
                'Charset'  => $data->{'charset'},
                'Field'    => $field
                ) . "\n";
        }
    }
    unless ($header_ok{'mime-version'}) {
        $headers .= "MIME-Version: 1.0\n";
    }
    unless ($header_ok{'content-type'}) {
        $headers .=
            "Content-Type: text/plain; charset=" . $data->{'charset'} . "\n";
    }
    unless ($header_ok{'content-transfer-encoding'}) {
        $headers .= "Content-Transfer-Encoding: 8bit\n";
    }

    # Determine what value the Auto-Submitted header field should take.
    # See RFC 3834.  The header field can have one of the following keywords:
    # "auto-generated", "auto-replied".
    # The header should not be set when WWSympa stores a command into
    # incoming spool.
    # n.b. The keyword "auto-forwarded" was abandoned.
    unless ($data->{'not_auto_submitted'} || $header_ok{'auto_submitted'}) {
        ## Default value is 'auto-generated'
        my $header_value = $data->{'auto_submitted'} || 'auto-generated';
        $headers .= "Auto-Submitted: $header_value\n";
    }

    unless ($existing_headers) {
        $headers .= "\n";
    }

    # All these data provide mail attachments in service messages.
    my @msgs = ();
    my $ifh;
    if (ref($data->{'msg_list'}) eq 'ARRAY') {
        @msgs =
            map { $_->{'msg'} || $_->{'full_msg'} } @{$data->{'msg_list'}};
    } elsif ($data->{'spool'}) {
        @msgs = @{$data->{'spool'}};
    } elsif ($data->{'msg'}) {
        push @msgs, $data->{'msg'};
    } elsif ($data->{'msg_path'} and open $ifh, '<', $data->{'msg_path'}) {
        #XXX NOTREACHED: No longer used.
        push @msgs, join('', <$ifh>);
        close $ifh;
    } elsif ($data->{'file'} and open $ifh, '<', $data->{'file'}) {
        #XXX NOTREACHED: No longer used.
        push @msgs, join('', <$ifh>);
        close $ifh;
    }

    my $self =
        $class->SUPER::new($headers . $message_as_string, context => $that);
    return undef unless $self;

    unless ($self->reformat_utf8_message(\@msgs, $data->{'charset'})) {
        $log->syslog('err', 'Failed to reformat message');
    }

    return $self;
}

# Methods compatible to Sympa::Spool.

sub next {
    my $self = shift;

    return if delete $self->{_done_next};
    $self->{_done_next} = 1;
    return ($self, 1);
}

use constant quarantine => 1;
use constant remove     => 1;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Message::Template - Mail message generated from template

=head1 SYNOPSIS

  use Sympa::Message::Template;
  my $message = Sympa::Message::Template->new(
      context => $list, template => "name", rcpt => [$email], data => {});

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( context =E<gt> $that, template =E<gt> $filename,
rcpt =E<gt> $rcpt, [ data =E<gt> $data ], [ options... ] )

I<Constructor>.
Creates L<Sympa::Message> object from template.

Parameters:

=over

=item context =E<gt> $that

Content: Sympa::List, robot or '*'.

=item template =E<gt> $filename

Template filename (without extension).

=item rcpt =E<gt> $rcpt

Scalar or arrayref: SMTP "RCPT TO:" field.

If it is a scalar, tries to retrieve information of the user
(See also L<Sympa::User>.

=item data =E<gt> $data

Hashref used to parse template, with keys:

=over

=item return_path

SMTP "MAIL FROM:" field if sent by SMTP (see L<Sympa::Mailer>),
"Return-Path:" field if sent by spool.

Note: This parameter was OBSOLETED.  Currently, {envelope_sender} attribute of
object is taken from the context.

=item to

"To:" header field

=item lang

Language tag used for parsing template.
See also L<Sympa::Language>.

=item from

"From:" field if not a full msg

Note:
This parameter was OBSOLETED.
The "From:" field will be filled in by "sympa" address if it is not found.

=item subject

"Subject:" field if not a full msg

=item replyto

"Reply-To:" field if not a full msg

=item body

Body message if $filename is C<''>.

Note: This feature has been deprecated.

=item headers

Additional headers, hashref with keys are field names.

=back

=back

Below are optional parameters.

=over

=item date =E<gt> $time

Delivery time of message.
By default current time will be used.

=item envelope_sender =E<gt> $email

Forces setting envelope sender.
C<'E<lt>E<gt>'> may be used for null envelope sender.

=item priority =E<gt> $priority

Forces setting priority if specified.

=item tracking =E<gt> $feature

Forces tracking if specified.

=back

Returns:

New L<Sympa::Message> instance, or C<undef> if something went wrong.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Template>.

=head1 HISTORY

L<Sympa::Message/"new_from_template"> appeared on Sympa 6.2.

It was renamed to L<Sympa::Message::Template/"new"> on Sympa 6.2.13.

=cut
