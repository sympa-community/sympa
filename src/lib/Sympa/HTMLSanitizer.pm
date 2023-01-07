# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

package Sympa::HTMLSanitizer;

use strict;
use warnings;
use base qw(HTML::StripScripts::Parser);

use Scalar::Util qw();
use URI;

use Sympa;
use Conf;
use Sympa::Tools::Text;

BEGIN {
    # Patch HTML::StripScripts to avoid ReDoS.
    $HTML::StripScripts::_AttVal{style} = sub {
        my ($filter, undef, undef, $attrval) = @_;
        my @clean;

        pos $attrval = 0;
        while (
            $attrval =~ m{
              \G
              [;\s]*
              (
                (?:
                  [^;'"()]+
                | ' [^']* '
                | " [^"]* "
                #FIXME:Handle nested parentheses
                | [(]
                  (?:
                    [^'"()]+
                  | ' [^']* '
                  | " [^"]* "
                  )*
                  [)]
                )+
              )
            }cgx
        ) {
            my ($key, $val) = split /\s*:\s*/, $1, 2;
            next unless defined $val;
            $key =~ s{\A ([-\w]+) \s* \z}{lc $1}ex
                or next;
            $val =~ s{\s+\z}{};

            my $sub = $filter->{_hssAttVal}{$filter->{_hssStyle}{$key} // ''}
                or next;
            if (defined $sub->($filter, 'style-psuedo-tag', $key, $val)) {
                push @clean, "$key:$val";
            }
        }

        return join '; ', @clean;
    };
}

# Returns a specialized HTML::StripScripts::Parser object built with the
# parameters provided as arguments.
sub new {
    my $class = shift;
    my $robot_id = shift || '*';

    my $self = $class->SUPER::new(
        {   Context        => 'Document',
            AllowSrc       => 1,
            AllowHref      => 1,
            AllowRelURL    => 1,
            EscapeFiltered => 0,
        }
    );

    my @allowed_origins = (
        Sympa::get_url($robot_id),
        split /\s*,\s*/,
        (Conf::get_robot_conf($robot_id, 'allowed_external_origin') || '')
    );
    $self->{_shsAllowedOriginRe} = '\A(?:' . join(
        '|',
        map {
            my $uri;
            unless (defined $_ and length $_) {
                ;
            } elsif (m{\A[-+\w]+:}) {
                $uri = URI->new($_)->canonical;
            } elsif ($_ =~ m{\A//}) {
                $uri = URI->new('http:' . $_)->canonical;
            } else {
                $uri = URI->new('http://' . $_)->canonical;
            }

            if ($uri
                and ($uri->scheme eq 'http' or $uri->scheme eq 'https')) {
                my $regexp = $uri->authority;
                # Escape metacharacters except wildcard '*'.
                $regexp =~
                    s/([^\s\w\x80-\xFF])/($1 eq '*') ? '.*' : "\\$1"/eg;

                ($regexp);
            } else {
                ();
            }
        } @allowed_origins
    ) . ')\z';

    return $self;
}

# Overridden method.
sub validate_src_attribute {
    my $self = shift;
    my $text = shift;

    my $uri = URI->new($text)->canonical;
    # Allow only cid URLs, local URLs and links with the same origin, i.e.
    # URLs with the same host etc.
    return $text if $uri->scheme and $uri->scheme eq 'cid';
    return $text unless $uri->can('authority') and $uri->authority;
    return $text if $uri->authority =~ $self->{_shsAllowedOriginRe};

    return undef;
}

# Overridden method.
sub validate_href_attribute {
    goto &validate_src_attribute;    # "&" required.
}

# This method is specific to this subclass.
sub sanitize_html {
    my $self   = shift;
    my $string = shift;

    return $self->filter_html($string);
}

# This method is specific to this subclass.
sub sanitize_html_file {
    my $self = shift;
    my $file = shift;

    $self->parse_file($file);
    return $self->filtered_document;
}

## Sanitize all values in the hashref or arrayref $var, starting from $level
sub sanitize_var {
    my $self       = shift;
    my $var        = shift;
    my %parameters = @_;

    unless (defined $var) {
        return undef;
    }
    unless (defined $parameters{'htmlAllowedParam'}
        && $parameters{'htmlToFilter'}) {
        die sprintf 'Missing var *** %s *** %s *** to ignore',
            $parameters{'htmlAllowedParam'},
            $parameters{'htmlToFilter'};
    }
    my $level = $parameters{'level'};
    $level |= 0;

    if (ref $var) {
        if (ref $var eq 'ARRAY') {
            foreach my $index (0 .. $#{$var}) {
                if (   (ref($var->[$index]) eq 'ARRAY')
                    || (ref($var->[$index]) eq 'HASH')) {
                    $self->sanitize_var(
                        $var->[$index],
                        'level'            => $level + 1,
                        'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
                        'htmlToFilter'     => $parameters{'htmlToFilter'},
                    );
                } elsif (defined $var->[$index]) {
                    # preserve numeric flags.
                    $var->[$index] =
                        Sympa::Tools::Text::encode_html($var->[$index])
                        unless Scalar::Util::looks_like_number(
                        $var->[$index]);
                }
            }
        } elsif (ref $var eq 'HASH') {
            foreach my $key (keys %{$var}) {
                if (   (ref($var->{$key}) eq 'ARRAY')
                    || (ref($var->{$key}) eq 'HASH')) {
                    $self->sanitize_var(
                        $var->{$key},
                        'level'            => $level + 1,
                        'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
                        'htmlToFilter'     => $parameters{'htmlToFilter'},
                    );
                } elsif (defined $var->{$key}) {
                    unless ($parameters{'htmlAllowedParam'}{$key}
                        or $parameters{'htmlToFilter'}{$key}) {
                        # preserve numeric flags.
                        $var->{$key} =
                            Sympa::Tools::Text::encode_html($var->{$key})
                            unless Scalar::Util::looks_like_number(
                            $var->{$key});
                    }
                    if ($parameters{'htmlToFilter'}{$key}) {
                        $var->{$key} = $self->sanitize_html($var->{$key});
                    }
                }

            }
        }
    } else {
        die 'Variable is neither a hash nor an array';
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::HTMLSanitizer - Sanitize HTML contents

=head1 SYNOPSIS

  $hss = Sympa::HTMLSanitizer->new;

  $sanitized = $hss->sanitize_html($html);
  $sanitized = $hss->sanitize_html_file($file);
  $hss->sanitize_var($variable);

=head1 DESCRIPTION

TBD.

=head2 Methods

=over

=item new ( $robot )

I<Constructor>.
Creates a new L<Sympa::HTMLSanitizer> instance.

Parameter:

=over

=item $robot

Robot context to determine allowed URL prefix.

=back

Returns:

New L<Sympa::HTMLSanitizer> instance.

=item sanitize_html ( $html )

I<Instance method>.
Returns sanitized version of HTML source.

Parameter:

=over

=item $html

HTML source.

=back

Returns:

Sanitized source.

=item sanitize_html_file ( $file )

I<Instance method>.
Returns sanitized version of HTML source in the file.

Parameter:

=over

=item $file

HTML file.

=back

Returns:

Sanitized source.

=item sanitize_var ( $var, [ options... ] )

I<Instance method>.
Sanitize all items in hashref or arrayref recursively.

TBD.

=back

=head1 HISTORY

TBD.

=cut
