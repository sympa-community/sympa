# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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
use Encode qw();

use Sympa::Regexps;
use Sympa::Tools::Text;

use base qw(HTML::Parser Class::Singleton);

# Class::Singleton constructor.
sub _new_instance {
    my $class = shift;

    $class->SUPER::new(
        api_version        => 3,
        default_h          => [\&_output, 'self,text'],
        end_h              => [\&_end, 'self,tagname,text'],
        start_h            => [\&_start, 'self,tagname,attr,text'],
        start_document_h   => [\&_start_document, 'self'],
        text_h             => [\&_text, 'self,text'],
        empty_element_tags => 1,
        unbroken_text      => 1,
    );
}

sub _end {
    my $self    = shift;
    my $tagname = shift;
    my $text    = shift;

    my $func = $self->{_shdEmailFunc};
    unless ($func
        and $self->{_shdStart}
        and lc $tagname eq $self->{_shdStart}) {
        $self->{_shdOutput} .= $text;
    } else {
        $self->{_shdOutput} .= $func->($text, '', '');
    }
    delete $self->{_shdStart};
}

sub _start {
    my $self    = shift;
    my $tagname = shift;
    my $attr    = shift;
    my $text    = shift;

    my $func = $self->{_shdEmailFunc};
    unless ($func
        and lc $tagname eq 'a'
        and $attr
        and $attr->{href}
        and $attr->{href} =~ /\Amailto:/i) {
        $self->{_shdOutput} .= $text;
        return;
    }

    if ($text =~ /\A(.+\bhref\s*=\s*([\"\']?)mailto:)([^\"]*)(\2.+)\z/is) {
        my ($before, $dtext, $after) =
            ($1, Sympa::Tools::Text::decode_html($3), $4);
        $self->{_shdOutput} .= $func->($before, $dtext, $after);
        $self->{_shdStart} = lc $tagname;
    } else {
        $self->{_shdOutput} .= $text;
    }
}

sub _start_document {
    my $self = shift;

    $self->{_shdOutput} = '';
    delete $self->{_shdStart};
}

sub _text {
    my $self = shift;
    my $text = shift;

    if (my $func = $self->{_shdEmailFunc}) {
        my $dtext    = Sympa::Tools::Text::decode_html($text);
        my $email_re = Sympa::Regexps::addrspec();

        my $decorated = '';
        pos $dtext = 0;
        while ($dtext =~ /\G((?:\s|.)*?)\b($email_re)\b/cg) {
            my ($t, $email) = ($1, $2);
            $decorated .= Sympa::Tools::Text::encode_html($t);
            $decorated .= $func->('', $email, '');
        }
        if (pos $dtext) {
            $self->{_shdOutput} .= $decorated;
            $self->{_shdOutput} .=
                Sympa::Tools::Text::encode_html(substr $dtext, pos $dtext);
            return;
        }
    }
    $self->{_shdOutput} .= $text;
    return;
}

sub _decorate_email_at {
    my $before = shift;
    my $dtext  = shift;
    my $after  = shift;

    $dtext =~ s/\@/ AT /g;
    return $before . Sympa::Tools::Text::encode_html($dtext) . $after;
}

sub _decorate_email_js {
    my $before = shift;
    my $dtext  = shift;
    my $after  = shift;

    my ($local, $domain) = split /\@/, $dtext, 2;
    ($local, $domain) = map {
        my $str = (defined $_) ? $_ : '';
        $str = Sympa::Tools::Text::encode_html($str);
        $str;
    } ($local, $domain);
    ($before, $local, $domain, $after) = map {
        my $str = (defined $_) ? $_ : '';
        $str =~ s/([\\\"])/\\$1/g;
        $str =~ s/\r\n|\r|\n/\\n/g;
        $str =~ s/\t/\\t/g;
        $str;
    } ($before, $local, $domain, $after);

    if (length $domain) {
        return
              sprintf '<script type="text/javascript">' . "\n" . '<!--' . "\n"
            . 'document.write("%s%s" + "@" + "%s%s")' . "\n"
            . '// -->' . "\n"
            . '</script>', $before, $local, $domain, $after;
    } else {
        return
              sprintf '<script type="text/javascript">' . "\n" . '<!--' . "\n"
            . 'document.write("%s%s%s")' . "\n"
            . '// -->' . "\n"
            . '</script>', $before, $local, $after;
    }
}

sub _output {
    my $self = shift;
    my $text = shift;

    $self->{_shdOutput} .= $text;
}

sub decorate {
    my $self    = shift;
    my $html    = shift;
    my %options = @_;

    return $html unless defined $html and length $html;

    if ($options{email}) {
        $self->{_shdEmailFunc} =
              $options{email} eq 'at'         ? \&_decorate_email_at
            : $options{email} eq 'javascript' ? \&_decorate_email_js
            :                                   undef;
    }
    # No decoration needed.
    return $html unless $self->{_shdEmailFunc};

    if ($html =~ /[<>]/) {
        $self->parse($html);
        $self->eof;
        return $self->{_shdOutput};
    } else {
        $self->_text($html);
        return $self->{_shdOutput};
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::HTMLDecorator - Decorating HTML texts

=head1 SYNOPSYS

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
Modifys HTML text.

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
