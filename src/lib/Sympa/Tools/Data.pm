# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2022 The Sympa Community. See the
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

package Sympa::Tools::Data;

use strict;
use warnings;
use Encode qw();
use English qw(-no_match_vars);
use POSIX qw();
use XML::LibXML qw();
BEGIN { eval 'use Clone qw()'; }

use Sympa::Language;
use Sympa::Tools::Text;

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

# Moved to: dumpa_var() in sympa_soap_client.pl.
#sub dump_var;

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

sub clone_var {
    return Clone::clone($_[0]) if $Clone::VERSION;
    goto &dup_var;    # '&' needed
}

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
        $ca{$id} = $value;
    }

    return \%ca;
}

# Old name: Sympa::List::createXMLCustomAttribute().
sub encode_custom_attribute {
    my $ca = shift;

    return
        '<?xml version="1.0" encoding="UTF-8" ?><custom_attributes></custom_attributes>'
        unless $ca;
    my $ret =
        '<?xml version="1.0" encoding="UTF-8" ?><custom_attributes>' . join(
        '',
        map {
            sprintf
                '<custom_attribute id="%s"><value>%s</value></custom_attribute>',
                $_,
                Sympa::Tools::Text::encode_html($ca->{$_} // '', '\000-\037');
            }
            sort keys %$ca
        ) . '</custom_attributes>';
    $ret =~ s/\s*\n\s*/ /g;

    return $ret;
}

my $language = Sympa::Language->instance;

# Old name: edit_configuragion() in sympa_wizard.pl.
sub format_config {
    my $params  = shift;
    my $curConf = shift if ref $_[0];
    my $newConf = shift if ref $_[0];
    my %options = @_;

    my $out     = '';
    my $changed = 0;

    my $title;
    foreach my $param (@$params) {
        next if $param->{obsolete};

        unless ($param->{name}) {
            $title = $language->gettext($param->{gettext_id})
                if $param->{gettext_id};
            next;
        }

        $out .=
            _format_config_ent($param, $curConf, $newConf, \$title, \$changed,
            %options);
    }

    return ($options{only_changed} and $newConf and not $changed)
        ? undef
        : $out;
}

sub _format_config_ent {
    my $param       = shift;
    my $curConf     = shift;
    my $newConf     = shift;
    my $title_ref   = shift;
    my $changed_ref = shift;
    my %options     = @_;

    my $name = $param->{name};

    my $value;
    if ($curConf and exists $curConf->{$name}) {
        my $cur = $curConf->{$name};
        $cur = join ',', @$cur if ref $cur eq 'ARRAY';

        if ($newConf and exists $newConf->{$name}) {
            $value = $newConf->{$name};
            $$changed_ref++ unless $cur eq $value;
        } else {
            $value = $cur;
        }
    } elsif ($newConf and exists $newConf->{$name}) {
        $value = $newConf->{$name};
        $$changed_ref++;
    }

    my @filter = @{$options{filter} // []};
    @filter = qw(explicit mandatory) unless @filter;
    my %specs = (
        explicit  => length($value // ''),
        omittable => (defined $param->{default}),
        optional  => $param->{optional},
        mandatory => not(defined $param->{default} or $param->{optional}),
        minimal   => (100 <= ($param->{importance} // 0)),
    );
    return '' unless grep { $_ eq 'full' or $specs{$_} } @filter;

    my $out = '';

    $out .= sprintf "###\\\\\\\\ %s ////###\n\n", $$title_ref
        if $$title_ref;

    $out .= sprintf "## %s\n", $name;

    $out .= Sympa::Tools::Text::wrap_text(
        $language->gettext($param->{gettext_id}),
        '## ', '## ')
        if $param->{gettext_id};

    $out .= Sympa::Tools::Text::wrap_text(
        $language->gettext($param->{gettext_comment}),
        '## ', '## ')
        if $param->{gettext_comment};

    $out .= sprintf '## ' . $language->gettext('Example: ') . "%s\t%s\n",
        $name, $param->{sample}
        if defined $param->{sample};

    if ($specs{explicit}) {
        $out .= sprintf "%s\t%s\n", $name, $value;
    } elsif ($specs{omittable}) {
        $out .= sprintf "#%s\t%s\n", $name, $param->{default};
    } elsif ($specs{optional}) {
        ;
    } else {
        $out .= sprintf "#%s\t%s\n", $name,
            $language->gettext("(You must define this parameter)");
    }
    $out .= "\n";

    undef $$title_ref;
    return $out;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Tools::Data - Functions related to data structures

=head1 DESCRIPTION

This package provides some functions related to data strucures.

=head2 Functions

=over

=item clone_var (...)

Duplicates a complex variable (faster than dup_var()).
TBD.

CAUTION:
This duplicates blessed elements even if they are
singleton/multiton; this breaks subroutine references.

=item decode_custom_attribute ($string)

Creates a custom attribute from an XML description.

Options:

=over

=item $string

XML formed data as stored in database

=back

Returns:

A hashref storing custom attributes.

=item diff_on_arrays ( $setA, $setB )

Makes set operation on arrays (seen as set, with no double) :

- deleted : A \ B

- added : B \ A

- intersection : A /\ B

- union : A \/ B

Options:

=over

=item $setA, $setB

Arrayrefs.

=back

Returns:

A hashref with keys :
deleted, added, intersection, union.

=item dump_html_var (...)

Dump a variable's content.
TBD.

=item dump_var (...)

Dump a variable's content.
TBD.

=item dup_var (...)

Duplictate a complex variable.
TBD.

See also clone_var().

=item encode_custom_attribute ($hashref)

Create an XML Custom attribute to be stored into data base.

Options:

=over

=item $hasref

Hashref storing custom attributes.

=back

Returns:

String, XML formed data to be stored in database.

=item format_config (\@params, [ \%curConf, [ \%newConf ] ],
[ I<key> C<=E<gt>> I<val> ... ] ))

Outputs formetted configuration.

Options:

=over

=item \@params

Configuration scheme.
See L<Sympa::ConfDef>.

=item \%curConf

Hashref including current configuration.

=item \%newConf

Hashref including update of configuration, if any.

=item I<key> C<=E<gt>> I<val> ...

Following options are possible:

=over

=item C<output> C<=E<gt>> C<[>I<classes>, ...C<]>

Classes of parameters to output: Any of
C<mandatory>, C<omittable>, C<optional>,
C<full> (synonym for the former tree), C<minimal> (included in minimal set,
i.e. described in installation instruction) and
C<explicit> (the parameter given an empty value with \%curConf and \%newConf).

=item C<only_changed> C<=E<gt>> C<1>

When both \%curConf and \%newConf are given and no changes were given,
returns C<undef>.

=back

=back

Returns:

Formatted string.

This was introduced on Sympa 6.2.70.

=item get_array_from_splitted_string ($string)

Returns an array made on a string splited by ','.
It removes spaces.

Options:

=over

=item $string

string to split

=back

Returns:

An arrayref.

=item hash_2_string (...)

Converts a hash into a string formatted as var1="value1";var2="value2"; into
a hash.
TBD.

=item is_in_array ( $setA, $value )

Test if a value is on an array.

Options:

=over

=item $setA

An arrayref.

=item $value

a serached value

=back

Returns true or false.

=item recursive_transformation (...)

This applies recursively to a data structure.
The transformation subroutine is passed as a ref.
TBD.

=item smart_eq ( $x, $y )

I<Function>.
Check if two strings are identical.

Parameters:

=over

=item $x, $y

Operands.

If both of them are undefined, they are equal.
If only one of them is undefined, the are not equal.
If C<$y> is a L<Regexp> object and it matches to C<$x>, they are equal.
Otherwise, they are compared as strings.

=back

Returns:

If arguments matched, true value.  Otherwise false value.

=item smart_lessthan (...)

Compares two scalars, string/numeric independent.
TBD.

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

=item string_2_hash (...)

Converts a string formatted as var1="value1";var2="value2"; into a hash.
Used when extracting from session table some session properties or when
extracting users preference from user table.
Current encoding is NOT compatible with encoding of values with '"'.
TBD.

=back

=head1 SEE ALSO

TBD.

=head1 HISTORY

TBD.

=cut

