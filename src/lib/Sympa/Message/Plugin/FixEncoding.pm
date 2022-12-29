# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Message::Plugin::FixEncoding;

use strict;
use warnings;
use MIME::Charset '1.010';

use Sympa::Language;

use constant gettext_id => 'Fix character set and encoding';

sub post_archive {
    my $class   = shift;
    my $name    = shift;
    my $message = shift;

    my $list = $message->{context};
    my $lang = $list->{'admin'}{'lang'};
    return 1 unless Sympa::Language::canonic_lang($lang);
    my $charset = Conf::lang2charset($lang);

    my $entity = $message->as_entity->dup;
    if (_fix_encoding($entity, $charset)) {
        $message->set_entity($entity);
    }

    return 1;
}

sub _fix_encoding {
    my $entity     = shift;
    my $defcharset = shift;

    return undef unless $entity;

    my $encoding = uc($entity->head->mime_encoding);
    my $eff_type = $entity->effective_type || 'text/plain';
    my $disposition =
        uc($entity->head->mime_attr('Content-Disposition') || '');

    # Parts with nonstandard encodings aren't modified.
    return 0
        if $encoding
        and $encoding !~ /\A(?:BASE64|QUOTED-PRINTABLE|[78]BIT|BINARY)\z/;
    # Signed or encrypted parts aren't modified.
    return 0 if $eff_type =~ m{^multipart/(signed|encrypted)$};
    # Attachments aren't modified.
    return 0 if $disposition eq 'ATTACHMENT';

    # Process subparts recursively.
    if ($entity->parts) {
        my $ret = 0;
        foreach my $part ($entity->parts) {
            my $rc = _fix_encoding($part, $defcharset);
            return undef unless defined $rc;
            $ret ||= $rc;
        }
        return $ret;
    }

    # Modify text/plain parts.
    if ($eff_type eq 'text/plain') {
        my $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        return 0 if not $bodyh or $bodyh->is_encoded;

        my $head = $entity->head;
        my $body = $bodyh->as_string;

        # Part encoded by unknown charset aren't modified.
        my $cset =
            MIME::Charset->new($head->mime_attr('Content-Type.Charset'));
        $cset = MIME::Charset->new(MIME::Charset::detect_7bit_charset($body))
            unless $cset->decoder;
        return 0 unless $cset->decoder;
        my $charset = $cset->as_string;

        # Undecodable bodies aren't modified.
        my $ubody = eval { $cset->decode($body, 1); };
        return 0 unless defined $ubody;

        # Fix charset and encoding.
        my ($newbody, $newcharset, $newencoding) =
            MIME::Charset::body_encode($ubody, $defcharset,
            Replacement => 'FALLBACK');
        return 0 if $newencoding eq $encoding and $newcharset eq $charset;

        # Fix headers and body.
        $head->mime_attr('Content-Type', 'TEXT/PLAIN')
            unless $head->mime_attr('Content-Type');
        $head->mime_attr('Content-Type.Charset',      $newcharset);
        $head->mime_attr('Content-Transfer-Encoding', $newencoding);
        $head->add(
            'X-Fix-Encoding',
            sprintf(
                'Converted from %s, %s to %s, %s',
                $charset, $encoding, $newcharset, $newencoding
            ),
            0
        );

        my $io = $bodyh->open('w');
        return undef unless $io;
        $io->print($newbody);
        return undef unless $io->close;

        return 1;
    }

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Message::Plugin::FixEncoding -
Example module for message hook to correct charset and encoding of messages

=head1 DESCRIPTION

This hook module corrects charset (character set) and transfer-encoding
of messages distributed from list according to list's language configuration.
It won't affect to archived messages.

For more details about Sympa message hook see L<Sympa::Message::Plugin>.

This module implements following handler.

=over 4

=item post_archive

=back

=head1 SEE ALSO

L<Sympa::Message::Plugin>

=head1 AUTHOR

IKEDA Soji <ikeda@conversion.co.jp>.

=cut
