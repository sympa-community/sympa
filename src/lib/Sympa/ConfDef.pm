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

package Sympa::ConfDef;

use strict;
use warnings;

use Sympa::Config::Schema;

our @params;

my $group = '';
my @pinfo = _filter({%Sympa::Config::Schema::pinfo});
foreach my $item (@pinfo) {
    if ($item->{group} and $group ne $item->{group}) {
        $group = $item->{group};
        my $title = {
            %{  $Sympa::Config::Schema::pgroup{$group}
                    // {gettext_id => $group}
            }
        };
        delete $title->{order};
        delete $title->{gettext_comment} unless $title->{gettext_comment};
        push @params, $title;
    }
    #delete @{$item}{qw(group order)};
    push @params, $item;
}

sub _filter {
    my $pinfo = shift;
    my $pnames = shift || [];

    return map {
        my $item = $pinfo->{$_};
        my $name = join '.', @$pnames, $_;

        my @ret;
        if (ref $item->{format} eq 'HASH') {
            (_filter($item->{format}, [@$pnames, $_]));
        } elsif (
            $item->{context}
            and grep {
                'domain' eq $_
            } @{$item->{context}}
        ) {
            my $i = {
                %$item,
                name  => $name,
                vhost => '1',
                (   (   ($item->{occurrence} // '') =~ /^0/
                            and not defined $item->{default}
                    ) ? (optional => '1') : ()
                ),
                (     (($item->{field_type} // '') eq 'password')
                    ? (obfuscated => '1')
                    : ()
                ),
                #edit => undef
            };
            delete @{$i}{qw(file_format)};
            ($i);
        } elsif (
            not $item->{context}
            or grep {
                'site' eq $_
            } @{$item->{context}}
        ) {
            my $i = {
                %$item,
                name => $name,
                (   (   ($item->{occurrence} // '') =~ /^0/
                            and not defined $item->{default}
                    ) ? (optional => '1') : ()
                ),
                (     (($item->{field_type} // '') eq 'password')
                    ? (obfuscated => '1')
                    : ()
                ),
                #edit => undef
            };
            delete @{$i}{qw(file_format)};
            ($i);
        } else {
            ();
        }
    } sort {
        by_order($pinfo, $a, $b)
    } keys %$pinfo;
}

sub by_order {
    my $pinfo = shift;
    my $a     = shift;
    my $b     = shift;

    return (
        ($pinfo->{$a}->{order} // 9999) <=> ($pinfo->{$b}->{order} // 9999))
        || (($a // '') cmp($b // ''));
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ConfDef - Definition of site and robot configuration parameters

=head1 DESCRIPTION

This module keeps definition of configuration parameters for site default
and each robot.

=head2 Global variable

=over

=item @params

Includes items in order parameters are shown.
It is then used to load, save, view, edit config files.
See L<Sympa::Config::Schema> for details about the content.

=back

=head1 SEE ALSO

L<sympa_config(5)>.

=head1 HISTORY

L<confdef> was separated from L<Conf> on Sympa 6.0a,
and renamed to L<Sympa::ConfDef> on 6.2a.39.
On Sympa 6.2.57b, its content was moved to L<Sympa::Config::Schema>.

=cut
