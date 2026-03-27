# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2026 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and
# at <https://github.com/sympa-community/sympa.git>.
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

package Sympa::HTML::URIFind;

use strict;
use warnings;
use Sympa::Regexps;
use Sympa::Tools::Text;

use base qw(URI::Find::Schemeless);

sub new {
    my $class    = shift;
    my $callback = shift;

    $callback ||= sub {
        my ($uri, $orig_uri) = @_;
        return sprintf '<a href="%s">%s</a>',
            Sympa::Tools::Text::encode_html($uri),
            Sympa::Tools::Text::encode_html($orig_uri);
    };
    $class->SUPER::new($callback);
}

sub find {
    my $self        = shift;
    my $textref     = shift;
    my $escape_func = shift;

    $escape_func ||= \&Sympa::Tools::Text::encode_html;
    $self->SUPER::find($textref, $escape_func);
}

my $email_re = Sympa::Regexps::email();

sub schemeless_uri_re {
    my $self = shift;

    return $self->SUPER::schemeless_uri_re() . '|'
        . qr{(?: ^ | (?<=[\s"<>()\[\]]) ) $email_re}x;
}

sub _uri_filter {
    my $self       = shift;
    my $orig_match = shift;

    $orig_match = $self->decruft($orig_match);

    my $replacement = '';
    if ($orig_match =~ qr{^$email_re$}) {
        # An e-mail address.
        $self->{_uris_found}++;
        $replacement = $self->{callback}
            ->(URI->new($orig_match, 'mailto')->as_string, $orig_match);
        $replacement = $self->recruft($replacement);
    } elsif ($orig_match =~ qr{^ (?: (?i) mailto: ) (?! $email_re )}x) {
        # It's not a legitimate mailto: URI.
        $orig_match  = $self->recruft($orig_match);
        $replacement = $self->{escape_func}->($orig_match);
    } else {
        # The others are handed over to the superclass.
        $orig_match  = $self->recruft($orig_match);
        $replacement = $self->SUPER::_uri_filter($orig_match);
    }
    return $replacement;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::HTML::URIFind - Find URIs / email addresses in plain text

=head1 SYNOPSIS

    require Sympa::HTML::URIFind;

    my $finder = Sympa::HTML::URIFind->new;

    $how_many_found = $finder->find(\$text);

=head1 DESCRIPTION

This module modifies a plain text to wrap all URIs and email addresses in HTML
tags.  Special characters are escaped appropriately.

=head1 HISTORY

L<Sympa::HTML::URIFind> appeared on Sympa 6.2.78.

=head1 SEE ALSO

L<URI::Find>.

=cut
