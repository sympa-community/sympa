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

package Sympa::Request::Collection;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Spool);

my $log = Sympa::Log->instance;

use constant _no_glob_pattern => 1;    # Not a filesystem spool.

sub next {
    my $self = shift;

    unless ($self->{_metadatas}) {
        $self->{_metadatas} = $self->_load;
    }
    unless ($self->{_metadatas} and @{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        return;
    }

    while (@{$self->{_metadatas}}) {
        my $options = shift @{$self->{_metadatas}};
        next unless $options and %$options;
        return ($self->_generator->new(%$options), 1);
    }
    return;
}

use constant _create        => 1;
use constant _directories   => {};
use constant _generator     => 'Sympa::Request';
use constant _is_collection => 1;

sub _load {
    my $self = shift;

    my %options = map {
        my $val = $self->{$_};
        ($_ => (ref $val eq 'ARRAY' ? [@$val] : $val))
    } grep {
        !/\A_/ and !/\A(?:finish|scenario_context|stash|success)\z/
    } keys %$self;

    unless (grep { ref $_ eq 'ARRAY' } values %options) {
        return [\%options];
    }

    my @metadatas;
    while (1) {
        my %opts;
        while (my ($key, $val) = each %options) {
            if (ref $val eq 'ARRAY') {
                unless (@$val) {
                    return [@metadatas];
                } else {
                    $opts{$key} = shift @$val;
                }
            } else {
                $opts{$key} = $val;
            }
        }
        push @metadatas, \%opts;
    }
    return [@metadatas];
}

use constant quarantine => 1;
use constant remove     => 1;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Collection - Collection of requests

=head1 SYNOPSIS

  use Sympa::Request::Collection;
  $spool = Sympa::Request::Collection->new(
      context => $list, action => $action, sender => $sender,
      key1 => $val1, key2 => [$val2]);
  ($request, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Request::Collection> provides pseudo-spool to generate a set of
L<Sympa::Request> instances.

=head2 Methods

=over

=item new ( context =E<gt> $that, action =E<gt> $action,
sender =E<gt> $sender, [ key =E<gt> val, ... ] )

=item next ( )

next() returns L<Sympa::Request> instances.

Options given to new() are used to generate instances.
If one of their value is arrayref, next() repeatedly generates instances
over each array item.

=item quarantine ( )

=item remove ( )

=item store ( )

Do nothing.

=back

=head1 SEE ALSO

L<Sympa::Request>, L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Request::Collection> appeared on Sympa 6.2.15.

=cut
