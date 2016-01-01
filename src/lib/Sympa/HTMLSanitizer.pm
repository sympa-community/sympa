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

package Sympa::HTMLSanitizer;

use strict;
use warnings;
use base qw(HTML::StripScripts::Parser);

use HTML::Entities qw();
use Scalar::Util qw();

use Conf;

our %url_prefix_of;

# Returns a specialized HTML::StripScripts::Parser object built with the
# parameters provided as arguments.
sub new {
    my $class = shift;
    my $robot_id = shift || '*';

    my $self = $class->SUPER::new(
        {   Context  => 'Document',
            AllowSrc => 1,
        }
    );

    my $url_prefix =
        lc(    Conf::get_robot_conf($robot_id, 'http_host')
            || Conf::get_robot_conf($robot_id, 'wwsympa_url'));
    $url_prefix = 'http://' . $url_prefix
        unless $url_prefix =~ m{\A[-\w]+://};
    $url_prefix =~ s{/\z}{};    # Strip trailing path separator.
    $url_prefix_of{$self + 0} = $url_prefix;

    return $self;
}

# Overridden method.
sub validate_src_attribute {
    my $self = shift;
    my $text = shift;

    # Allow only cid URLs and local links in src attribute.
    my $url_prefix = $url_prefix_of{$self + 0};
    if (   index(lc $text, 'cid:') == 0
        or ($url_prefix and lc $text eq $url_prefix)
        or ($url_prefix and index(lc $text, $url_prefix . '/') == 0)) {
        return $text;
    } else {
        return undef;
    }
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
                        HTML::Entities::encode_entities($var->[$index],
                        '<>&"')
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
                            HTML::Entities::encode_entities($var->{$key},
                            '<>&"')
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

sub DESTROY {
    my $self = shift;

    delete $url_prefix_of{$self + 0};
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
