# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Tools::Data;

use strict;
use warnings;
use Encode qw();
use English qw(-no_match_vars);
use POSIX qw();
use XML::LibXML qw();
BEGIN { eval 'use Clone qw()'; }

use Sympa::Tools::Text;

## This applies recursively to a data structure
## The transformation subroutine is passed as a ref
sub recursive_transformation {
    my ($var, $subref) = @_;

    return unless (ref($var));

    if (ref($var) eq 'ARRAY') {
        foreach my $index (0 .. $#{$var}) {
            if (ref($var->[$index])) {
                recursive_transformation($var->[$index], $subref);
            } else {
                $var->[$index] = &{$subref}($var->[$index]);
            }
        }
    } elsif (ref($var) eq 'HASH') {
        foreach my $key (keys %{$var}) {
            if (ref($var->{$key})) {
                recursive_transformation($var->{$key}, $subref);
            } else {
                $var->{$key} = &{$subref}($var->{$key});
            }
        }
    }

    return;
}

## Dump a variable's content
sub dump_var {
    my ($var, $level, $fd) = @_;

    return undef unless ($fd);

    if (ref($var)) {
        if (ref($var) eq 'ARRAY') {
            foreach my $index (0 .. $#{$var}) {
                print $fd "\t" x $level . $index . "\n";
                dump_var($var->[$index], $level + 1, $fd);
            }
        } elsif (ref($var) eq 'HASH'
            || ref($var) eq 'Sympa::Scenario'
            || ref($var) eq 'Sympa::List'
            || ref($var) eq 'CGI::Fast') {
            foreach my $key (sort keys %{$var}) {
                print $fd "\t" x $level . '_' . $key . '_' . "\n";
                dump_var($var->{$key}, $level + 1, $fd);
            }
        } else {
            printf $fd "\t" x $level . "'%s'" . "\n", ref($var);
        }
    } else {
        if (defined $var) {
            print $fd "\t" x $level . "'$var'" . "\n";
        } else {
            print $fd "\t" x $level . "UNDEF\n";
        }
    }
}

## Dump a variable's content
sub dump_html_var {
    my ($var) = shift;
    my $html = '';

    if (ref($var)) {

        if (ref($var) eq 'ARRAY') {
            $html .= '<ul>';
            foreach my $index (0 .. $#{$var}) {
                $html .= '<li> ' . $index . ':';
                $html .= dump_html_var($var->[$index]);
                $html .= '</li>';
            }
            $html .= '</ul>';
        } elsif (ref($var) eq 'HASH'
            || ref($var) eq 'Sympa::Scenario'
            || ref($var) eq 'Sympa::List') {
            $html .= '<ul>';
            foreach my $key (sort keys %{$var}) {
                $html .= '<li>' . $key . '=';
                $html .= dump_html_var($var->{$key});
                $html .= '</li>';
            }
            $html .= '</ul>';
        } else {
            $html .= 'EEEEEEEEEEEEEEEEEEEEE' . ref($var);
        }
    } else {
        if (defined $var) {
            $html .= Sympa::Tools::Text::encode_html($var);
        } else {
            $html .= 'UNDEF';
        }
    }
    return $html;
}

# Duplicates a complex variable (faster).
# CAUTION: This duplicates blessed elements even if they are
# singleton/multiton; this breaks subroutine references.
sub clone_var {
    return Clone::clone($_[0]) if $Clone::VERSION;
    goto &dup_var;    # '&' needed
}

## Duplictate a complex variable
sub dup_var {
    my ($var) = @_;

    if (ref($var)) {
        if (ref($var) eq 'ARRAY') {
            my $new_var = [];
            foreach my $index (0 .. $#{$var}) {
                $new_var->[$index] = dup_var($var->[$index]);
            }
            return $new_var;
        } elsif (ref($var) eq 'HASH') {
            my $new_var = {};
            foreach my $key (sort keys %{$var}) {
                $new_var->{$key} = dup_var($var->{$key});
            }
            return $new_var;
        }
    }

    return $var;
}

####################################################
# get_array_from_splitted_string
####################################################
# return an array made on a string splited by ','.
# It removes spaces.
#
#
# IN : -$string (+): string to split
#
# OUT : -ref(ARRAY)
#
######################################################
# Note: This is used only by Sympa::List.
sub get_array_from_splitted_string {
    my ($string) = @_;
    my @array;

    foreach my $word (split /,/, $string) {
        $word =~ s/^\s+//;
        $word =~ s/\s+$//;
        push @array, $word;
    }

    return \@array;
}

####################################################
# diff_on_arrays
####################################################
# Makes set operation on arrays (seen as set, with no double) :
#  - deleted : A \ B
#  - added : B \ A
#  - intersection : A /\ B
#  - union : A \/ B
#
# IN : -$setA : ref(ARRAY) - set
#      -$setB : ref(ARRAY) - set
#
# OUT : -ref(HASH) with keys :
#          deleted, added, intersection, union
#
#######################################################
sub diff_on_arrays {
    my ($setA, $setB) = @_;
    my $result = {
        'intersection' => [],
        'union'        => [],
        'added'        => [],
        'deleted'      => []
    };
    my %deleted;
    my %added;
    my %intersection;
    my %union;

    my %hashA;
    my %hashB;

    foreach my $eltA (@$setA) {
        $hashA{$eltA}   = 1;
        $deleted{$eltA} = 1;
        $union{$eltA}   = 1;
    }

    foreach my $eltB (@$setB) {
        $hashB{$eltB} = 1;
        $added{$eltB} = 1;

        if ($hashA{$eltB}) {
            $intersection{$eltB} = 1;
            $deleted{$eltB}      = 0;
        } else {
            $union{$eltB} = 1;
        }
    }

    foreach my $eltA (@$setA) {
        if ($hashB{$eltA}) {
            $added{$eltA} = 0;
        }
    }

    foreach my $elt (keys %deleted) {
        next unless $elt;
        push @{$result->{'deleted'}}, $elt if ($deleted{$elt});
    }
    foreach my $elt (keys %added) {
        next unless $elt;
        push @{$result->{'added'}}, $elt if ($added{$elt});
    }
    foreach my $elt (keys %intersection) {
        next unless $elt;
        push @{$result->{'intersection'}}, $elt if ($intersection{$elt});
    }
    foreach my $elt (keys %union) {
        next unless $elt;
        push @{$result->{'union'}}, $elt if ($union{$elt});
    }

    return $result;

}

####################################################
# is_in_array
####################################################
# Test if a value is on an array
#
# IN : -$setA : ref(ARRAY) - set
#      -$value : a serached value
#
# OUT : boolean
#######################################################
sub is_in_array {
    my $set = shift;
    die 'missing parameter "$value"' unless @_;
    my $value = shift;

    if (defined $value) {
        foreach my $elt (@{$set || []}) {
            next unless defined $elt;
            return 1 if $elt eq $value;
        }
    } else {
        foreach my $elt (@{$set || []}) {
            return 1 unless defined $elt;
        }
    }

    return undef;
}

=over

=item smart_eq ( $a, $b )

I<Function>.
Check if two strings are identical.

Parameters:

=over

=item $a, $b

Operands.

If both of them are undefined, they are equal.
If only one of them is undefined, the are not equal.
If C<$b> is a L<Regexp> object and it matches to C<$a>, they are equal.
Otherwise, they are compared as strings.

=back

Returns:

If arguments matched, true value.  Otherwise false value.

=back

=cut

sub smart_eq {
    die 'missing argument' if scalar @_ < 2;
    my ($a, $b) = @_;

    if (defined $a and defined $b) {
        if (ref $b eq 'Regexp') {
            return 1 if $a =~ $b;
        } else {
            return 1 if $a eq $b;
        }
    } elsif (!defined $a and !defined $b) {
        return 1;
    }

    return undef;
}

## convert a string formated as var1="value1";var2="value2"; into a hash.
## Used when extracting from session table some session properties or when
## extracting users preference from user table
## Current encoding is NOT compatible with encoding of values with '"'
##
sub string_2_hash {
    my $data = shift;
    my %hash;

    pos($data) = 0;
    while ($data =~ /\G;?(\w+)\=\"((\\[\"\\]|[^\"])*)\"(?=(;|\z))/g) {
        my ($var, $val) = ($1, $2);
        $val =~ s/\\([\"\\])/$1/g;
        $hash{$var} = $val;
    }

    return (%hash);

}
## convert a hash into a string formated as var1="value1";var2="value2"; into
## a hash
sub hash_2_string {
    my $refhash = shift;

    return undef unless ref $refhash eq 'HASH';

    my $data_string;
    foreach my $var (keys %$refhash) {
        next unless length $var;
        my $val = $refhash->{$var};
        $val = '' unless defined $val;

        $val =~ s/([\"\\])/\\$1/g;
        $data_string .= ';' . $var . '="' . $val . '"';
    }
    return ($data_string);
}

## compare 2 scalars, string/numeric independant
sub smart_lessthan {
    my ($stra, $strb) = @_;
    $stra =~ s/^\s+//;
    $stra =~ s/\s+$//;
    $strb =~ s/^\s+//;
    $strb =~ s/\s+$//;
    $ERRNO = 0;
    my ($numa, $unparsed) = POSIX::strtod($stra);
    my $numb;
    $numb = POSIX::strtod($strb)
        unless ($ERRNO || $unparsed != 0);

    if (($stra eq '') || ($strb eq '') || ($unparsed != 0) || $ERRNO) {
        return $stra lt $strb;
    } else {
        return $stra < $strb;
    }
}

=over

=item sort_uniq ( [ \&comp ], @items )

Returns sorted array of unique elements in the list.

Parameters:

=over

=item \&comp

Optional subroutine reference to compare each pairs of elements.
It should take two arguments and return negative, zero or positive result.

=item @items

Items to be sorted.

=back

This function was added on Sympa 6.2.16.

=back

=cut

sub sort_uniq {
    my $comp;
    if (ref $_[0] eq 'CODE') {
        $comp = shift;
    }

    my %items;
    @items{@_} = ();

    if ($comp) {
        return sort { $comp->($a, $b) } keys %items;
    } else {
        return sort keys %items;
    }
}

# Create a custom attribute from an XML description
# IN : A string, XML formed data as stored in database
# OUT : HASH data storing custome attributes.
# Old name: Sympa::List::parseCustomAttribute().
sub decode_custom_attribute {
    my $xmldoc = shift;
    return undef unless defined $xmldoc and length $xmldoc;

    my $parser = XML::LibXML->new();
    my $tree;

    ## We should use eval to parse to prevent the program to crash if it fails
    if (ref($xmldoc) eq 'GLOB') {
        $tree = eval { $parser->parse_fh($xmldoc) };
    } else {
        $tree = eval { $parser->parse_string($xmldoc) };
    }

    return undef unless defined $tree;

    my $doc = $tree->getDocumentElement;

    my @custom_attr = $doc->getChildrenByTagName('custom_attribute');
    my %ca;
    foreach my $ca (@custom_attr) {
        my $id    = Encode::encode_utf8($ca->getAttribute('id'));
        my $value = Encode::encode_utf8($ca->getElementsByTagName('value'));
        $ca{$id} = {value => $value};
    }
    return \%ca;
}

# Create an XML Custom attribute to be stored into data base.
# IN : HASH data storing custome attributes
# OUT : string, XML formed data to be stored in database
# Old name: Sympa::List::createXMLCustomAttribute().
sub encode_custom_attribute {
    my $custom_attr = shift;
    return
        '<?xml version="1.0" encoding="UTF-8" ?><custom_attributes></custom_attributes>'
        if (not defined $custom_attr);
    my $XMLstr = '<?xml version="1.0" encoding="UTF-8" ?><custom_attributes>';
    foreach my $k (sort keys %{$custom_attr}) {
        my $value = $custom_attr->{$k}{value};
        $value = '' unless defined $value;

        $XMLstr .=
              "<custom_attribute id=\"$k\"><value>"
            . Sympa::Tools::Text::encode_html($value, '\000-\037')
            . "</value></custom_attribute>";
    }
    $XMLstr .= "</custom_attributes>";
    $XMLstr =~ s/\s*\n\s*/ /g;

    return $XMLstr;
}

1;
