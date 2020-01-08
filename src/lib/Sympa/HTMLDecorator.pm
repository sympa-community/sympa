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

package Sympa::HTMLDecorator;

use strict;
use warnings;

use Sympa::Language;
use Sympa::Regexps;
use Sympa::Tools::Text;

use base qw(HTML::Parser Class::Singleton);

# Class::Singleton constructor.
sub _new_instance {
    return shift->SUPER::new(
        api_version        => 3,
        default_h          => [\&_default, 'self,text'],
        end_h              => [\&_end, 'self,event,tagname,text'],
        end_document_h     => [\&_end_document, 'self'],
        start_h            => [\&_start, 'self,event,tagname,attr,text'],
        start_document_h   => [\&_start_document, 'self'],
        text_h             => [\&_text, 'self,event,text'],
        empty_element_tags => 1,
        unbroken_text      => 1,
    );
}

sub _default {
    my $self = shift;
    my $text = shift;

    $self->_queue_flush;
    $self->{_shdOutput} .= $text;
}

sub _end {
    my $self = shift;
    my %options;
    @options{qw(event tagname text)} = @_;

    if ($self->_queue_tagname eq 'a') {
        $self->_queue_push(%options);
        if (lc $options{tagname} eq 'a') {
            $self->_queue_flush;
        }
        return;
    }

    $self->_queue_flush;
    $self->{_shdOutput} .= $options{text};
}

sub _end_document {
    my $self = shift;

    $self->_queue_flush;
}

sub _start {
    my $self = shift;
    my %options;
    @options{qw(event tagname attr text)} = @_;

    if ($self->_queue_tagname eq 'a') {
        unless (grep { lc $options{tagname} eq $_ } qw(a script)) {
            $self->_queue_push(%options);
            return;
        }
    }

    if (    lc $options{tagname} eq 'a'
        and $options{attr}
        and $options{attr}->{href}
        and $options{attr}->{href} =~ /\Amailto:/i) {
        $self->_queue_flush;
        $self->_queue_push(%options);
        return;
    }

    $self->_queue_flush;
    $self->{_shdOutput} .= $options{text};
}

sub _start_document {
    my $self = shift;

    $self->{_shdOutput} = '';
    $self->_queue_clear;
}

sub _text {
    my $self = shift;
    my %options;
    @options{qw(event text)} = @_;

    my $dtext    = Sympa::Tools::Text::decode_html($options{text});
    my $email_re = Sympa::Regexps::addrspec();

    if ($self->_queue_tagname eq 'a' or $dtext =~ /\b$email_re\b/) {
        $self->_queue_push(%options);
        return;
    }

    $self->_queue_flush;
    $self->{_shdOutput} .= $options{text};
    return;
}

sub _queue_clear {
    my $self = shift;

    $self->{_shdEmailQueued} = [];
}

sub _queue_flush {
    my $self = shift;

    return unless @{$self->{_shdEmailQueued}};

    if (my $func = $self->{_shdEmailFunc}) {
        $self->{_shdOutput} .= $self->$func();
    } else {
        while (my $item = $self->_queue_shift) {
            $self->{_shdOutput} .= $item->{text};
        }
    }
    $self->_queue_clear;
}

sub _queue_push {
    my $self    = shift;
    my %options = @_;

    push @{$self->{_shdEmailQueued}}, {%options};
}

sub _queue_shift {
    my $self = shift;

    return shift @{$self->{_shdEmailQueued}};
}

sub _queue_tagname {
    my $self = shift;

    if (    @{$self->{_shdEmailQueued}}
        and $self->{_shdEmailQueued}->[0]->{event} eq 'start'
        and lc $self->{_shdEmailQueued}->[0]->{tagname} eq 'a') {
        return 'a';
    } else {
        return '';
    }
}

sub decorate {
    my $self    = shift;
    my $html    = shift;
    my %options = @_;

    return $html unless defined $html and length $html;

    if ($options{email}) {
        $self->{_shdEmailFunc} =
              $options{email} eq 'at'         ? \&decorate_email_at
            : $options{email} eq 'gecos'      ? \&decorate_email_gecos
            : $options{email} eq 'javascript' ? \&decorate_email_js
            :                                   undef;
    }
    # No decoration needed.
    return $html unless $self->{_shdEmailFunc};

    if ($html =~ /[<>]/) {
        $self->parse($html);
        $self->eof;
    } else {
        $self->_start_document;
        $self->_text('text', $html);
        $self->_end_document;
    }
    return $self->{_shdOutput};
}

sub decorate_email_at {
    my $self = shift;

    my $decorated = '';
    my $email_re  = Sympa::Regexps::addrspec();
    while (my $item = $self->_queue_shift) {
        if ($item->{event} eq 'text') {
            my $dtext = Sympa::Tools::Text::decode_html($item->{text});
            if ($dtext =~ s{\b($email_re)\b}{join ' AT ', split(/\@/, $1)}eg)
            {
                $decorated .= Sympa::Tools::Text::encode_html($dtext);
            } else {
                $decorated .= $item->{text};
            }
        } elsif ($item->{event} eq 'start') {
            my $text = $item->{text};
            if ($text =~ s{\b(href=\S+)}{join '%20AT%20', split(/\@/, $1)}egi)
            {
                $decorated .= $text;
            } else {
                $decorated .= $item->{text};
            }
        } else {
            $decorated .= $item->{text};
        }
    }
    return $decorated;
}

sub decorate_email_gecos {
    my $self = shift;

    my $decorated = '';
    my $email_re  = Sympa::Regexps::addrspec();
    my $language  = Sympa::Language->instance;
    while (my $item = $self->_queue_shift) {
        if ($item->{event} eq 'text') {
            my $dtext       = Sympa::Tools::Text::decode_html($item->{text});
            my $replacement = $language->gettext('address@concealed');
            if ($dtext =~ s{\b($email_re)\b}{$replacement}g) {
                $decorated .= Sympa::Tools::Text::encode_html($dtext);
            } else {
                $decorated .= $item->{text};
            }
        } else {
            $decorated .= $item->{text};
        }
    }

    $decorated .= $language->gettext('No gecos') if ($decorated eq ': ');

    return $decorated;
}

sub decorate_email_js {
    my $self = shift;

    my $text = '';
    while (my $item = $self->_queue_shift) {
        $text .= $item->{text};
    }

    if (index($text, '<') == 0) {
        return _decorate_email_js($text);
    }

    my $decorated = '';
    my $email_re  = Sympa::Regexps::addrspec();
    my $dtext     = Sympa::Tools::Text::decode_html($text);
    pos $dtext = 0;
    while ($dtext =~ /\G((?:\n|.)*?)\b($email_re)\b/cg) {
        $decorated .=
              Sympa::Tools::Text::encode_html($1)
            . _decorate_email_js(Sympa::Tools::Text::encode_html($2));
    }
    if (pos $dtext) {
        return $decorated
            . Sympa::Tools::Text::encode_html(substr $dtext, pos $dtext);
    }

    return $text;
}

sub _decorate_email_js {
    my $text = shift;

    my @texts = map {
        my $str = (defined $_) ? $_ : '';
        $str =~ s/([\\\"])/\\$1/g;
        $str =~ s/\r\n|\r|\n/\\n/g;
        $str =~ s/\t/\\t/g;
        $str;
    } split /\b|(?=\@)|(?<=\@)/, $text;
    return
          sprintf '<script type="text/javascript">' . "\n" . '<!--' . "\n"
        . 'document.write(%s)' . "\n"
        . '// -->' . "\n"
        . '</script>',
        join(" +\n", map { '"' . $_ . '"' } @texts);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::HTMLDecorator - Decorating HTML texts

=head1 SYNOPSIS

  use Sympa::HTMLDecorator;
  $decorator = Sympa::HTMLDecorator->instance;
  $ouput = $decorator->decorate($html, email => 'javascript');

=head1 DESCRIPTION

L<Sympa::HTMLDecorator> transforms HTML texts.

=head2 Methods

=over

=item instance ( )

I<Constructor>.
Returns singleton instance of this class.

=item decorate ( $html, email =E<gt> $mode )

I<Instance method>.
Modifies HTML text.

Parameters:

=over

=item $html

A text including HTML document or fragment.
It must be encoded by UTF-8.

=item email =E<gt> $mode

Transformation mode.
C<'at'> replaces C<@> in email addresses.
C<'javascript'> obfuscates emails using JavaScript code.

=back

Returns:

Modified text.

=back

=head1 SEE ALSO

L<Sympa::HTMLSanitizer>.

=head1 HISTORY

L<Sympa::HTMLDecorator> appeared on Sympa 6.2.14.

=cut
