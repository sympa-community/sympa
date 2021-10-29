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

package Sympa::ListDef;

use strict;
use warnings;

use Sympa::Config::Schema;

our %pinfo     = _filter({%Sympa::Config::Schema::pinfo});
our %user_info = %Sympa::Config::Schema::user_info;

sub _filter {
    my $pinfo = shift;
    my $pnames = shift || [];

    return map {
        my $item = $pinfo->{$_};
        unless (not $item->{context}
            or grep { 'list' eq $_ } @{$item->{context}}) {
            ();
        } else {
            my $default = $item->{default};
            if ($item->{context}
                and grep { 'domain' eq $_ or 'site' eq $_ }
                @{$item->{context}}
                and ref $item->{format} ne 'HASH') {
                $default = {conf => join('.', @$pnames, $_)};
            }

            if (ref $item->{format} eq 'HASH') {
                (   $_ => {
                        %$item,
                        format => {_filter($item->{format}, [@$pnames, $_])},
                        (   (ref $item->{file_format} eq 'HASH')
                            ? ( file_format => {
                                    _filter(
                                        $item->{file_format}, [@$pnames, $_]
                                    )
                                }
                                )
                            : ()
                        ),
                        ((defined $default) ? (default => $default) : ()),
                    }
                );
            } elsif (defined $default) {
                ($_ => {%$item, default => $default});
            } else {
                ($_ => {%$item});
            }
        }
    } keys %$pinfo;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ListDef - Definition of list configuration parameters

=head1 DESCRIPTION

This module keeps definition of configuration parameters for each list.

=head2 Global variable

=over

=item %alias

Deprecated by Sympa 6.2.16.

=item %pinfo

This hash COMPLETELY defines ALL list parameters.
It is then used to load, save, view, edit list config files.
See L<Sympa::Config::Schema> for details about the content.

=item %user_info

TBD.

=back

=head1 SEE ALSO

L<list_config(5)>,
L<Sympa::List::Config>,
L<Sympa::ListOpt>.

=head1 HISTORY

L<Sympa::ListDef> was separated from L<List> module on Sympa 6.2.
On Sympa 6.2.57b, its content was moved to L<Sympa::Config::Schema>.

=cut
