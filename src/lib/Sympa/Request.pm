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

package Sympa::Request;

use strict;
use warnings;
use Scalar::Util qw();

use Sympa::Log;
use Sympa::Tools::Data;
use Sympa::Tools::Text;
use Sympa::User;

my $log = Sympa::Log->instance;

sub new {
    my $class      = shift;
    my $serialized = shift;

    my $self = bless {@_} => $class;
    $self->{email} = Sympa::Tools::Text::canonic_email($self->{email})
        if defined $self->{email};

    # Get attributes from pseudo-header fields at the top of serialized
    # message.  Note that field names are case-sensitive.

    pos($serialized) = 0;
    while ($serialized =~ /\G(X-Sympa-[-\w]+): (.*?)\n(?![ \t])/cgs) {
        my ($k, $v) = ($1, $2);
        next unless length $v;

        if ($k eq 'X-Sympa-Action') {
            $self->{action} = $v;
        } elsif ($k eq 'X-Sympa-Display-Name') {
            $self->{gecos} = $v;
        } else {
            $log->syslog('err', 'Unknown attribute information: "%s: %s"',
                $k, $v);
        }
    }

    # Strip attributes.
    substr($serialized, 0, pos $serialized) = '';

    # Check if custom_attribute is parsable.
    if ($serialized =~ /\S/ and not $self->{custom_attribute}) {
        $serialized =~ s/\A\s+//;
        $self->{custom_attribute} =
            Sympa::Tools::Data::decode_custom_attribute($serialized);
    }

    if ($self->{email}
        and not(defined $self->{gecos} and length $self->{gecos})) {
        my $user = Sympa::User->new($self->{email});
        $self->{gecos} = $user->gecos if $user and $user->gecos;
    }

    $self;
}

sub new_from_tuples {
    my $class   = shift;
    my %options = @_;

    return $class->new('', %options);
}

sub dup {
    my $self = shift;

    my $clone = {};
    foreach my $key (sort keys %$self) {
        my $val = $self->{$key};
        next unless defined $val;

        unless (Scalar::Util::blessed($val)) {
            $clone->{$key} = Sympa::Tools::Data::dup_var($val);
        } elsif ($val->can('dup') and !$val->isa('Sympa::List')) {
            $clone->{$key} = $val->dup;
        } else {
            $clone->{$key} = $val;
        }
    }

    return bless $clone => ref($self);
}

sub to_string {
    my $self = shift;

    my $msg_string = '';
    if (defined $self->{action} and length $self->{action}) {
        $msg_string .= sprintf "X-Sympa-Action: %s\n", $self->{action};
    }
    if (defined $self->{gecos} and length $self->{gecos}) {
        $msg_string .= sprintf "X-Sympa-Display-Name: %s\n", $self->{gecos};
    }
    if (ref $self->{custom_attribute} eq 'HASH') {
        my $xml_string = Sympa::Tools::Data::encode_custom_attribute(
            $self->{custom_attribute});
        $msg_string .= sprintf "\n%s\n", $xml_string;
    } else {
        $msg_string .= "\n";
    }
    return $msg_string;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request - Requests for operation

=head1 SYNOPSYS

TBD.

=head1 DESCRIPTION

L<Sympa::Request> inmplements serializable object representing requests by
users.

=head2 Methods

=over

=item new ( $serialized, context => $list, [ key =E<gt> value, ... ] )

I<Constructor>.
Creates a new L<Sympa::Request> object.

=item new_from_tuples ( key =E<gt> value, ... )

I<Constructor>.
Creates L<Sympa::Request> object from paired options.

=item dup ( )

I<Copy constructor>.
Gets deep copy of instance.

=item to_string ( )

I<Serializer>.
Returns serialized data of object.

=back

=head2 Context and metadata

Context and metadata given to constructor are accessible as hash elements
of object.
They are given by request spool.
See L<Sympa::Spool::Request/"Context and metadata"> for details.

=head2 Attributes

These are accessible as hash elements of objects.

=over

=item {custom_attribute}

Custom attribute connected to requested action.

=item {gecos}

Display name of user sending request.

=back

=head1 SEE ALSO

L<Sympa::Spool::Request>.

=head1 HISTORY

L<Sympa::Request> appeared on Sympa 6.2.10.

=cut
