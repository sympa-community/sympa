# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2019, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::Request;

use strict;
use warnings;
use English qw(-no_match_vars);
use Scalar::Util qw();

use Sympa;
use Sympa::CommandDef;
use Sympa::Log;
use Sympa::Tools::Data;
use Sympa::Tools::Text;
use Sympa::User;

my $log = Sympa::Log->instance;

my %attrmap = (
    action => 'X-Sympa-Action',
    gecos  => 'X-Sympa-Display-Name',
    sender => 'X-Sympa-Sender',
);
my @optattrs = qw(arc current_email reception visibility);

sub new {
    my $class = shift;
    # Optional $serialized.
    my $serialized;
    unless (@_ and ($_[0] eq '' or $_[0] =~ /\n/)) {
        $serialized = '';
    } else {
        $serialized = shift;
    }
    my %options = @_;

    my $handler = $options{action};
    $handler = 'Sympa::Request::Handler::' . $handler
        unless 0 < index $handler, '::';
    unless (eval sprintf 'require %s',
        $handler and $handler->isa('Sympa::Request::Handler')) {
        $log->syslog('err', 'Unable to use %s module: %s',
            $handler, $EVAL_ERROR || 'Not a Sympa::Request::Handler class');
        return undef;
    }

    my $self = bless {%options, _handler => $handler} => $class;
    $self->{email} = Sympa::Tools::Text::canonic_email($self->{email})
        if defined $self->{email};

    # Get attributes from pseudo-header fields at the top of serialized
    # message.  Note that field names are case-sensitive.

    my %revmap = reverse %attrmap;
    pos($serialized) = 0;
    while ($serialized =~ /\G(X-Sympa-[-\w]+): (.*?)\n(?![ \t])/cgs) {
        my ($k, $v) = ($1, $2);
        next unless length $v;

        if ($k eq 'X-Sympa-Options') {
            my %vals =
                map { my ($k, $v) = split /=/, $_, 2; ($k, $v) }
                split /\s*;\s*/, $v;
            @{$self}{@optattrs} = @vals{@optattrs};
        } elsif (my $attr = $revmap{$k}) {
            $self->{$attr} = $v;
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

    #FIXME:Meddlesomeness to be removed.
    if (    $self->{action} ne 'set'
        and $self->{email}
        and not length($self->{gecos} // '')) {
        my $user = Sympa::User->new($self->{email});
        $self->{gecos} = $user->gecos if $user and $user->gecos;
    }

    $self;
}

# OBSOLETED.  Use new().
sub new_from_tuples {
    my $class   = shift;
    my %options = @_;

    return $class->new('', %options);
}

sub cmd_line {
    my $self    = shift;
    my %options = @_;

    return $self->{cmd_line}
        if $self->{cmd_line} and not $options{canonic};
    return undef
        if not $self->{action}
        or $self->{action} eq 'unknown';

    my $cmd_format = $Sympa::CommandDef::comms{$self->{action}}->{cmd_format};
    my $arg_keys   = $Sympa::CommandDef::comms{$self->{action}}->{arg_keys};
    return undef
        unless $cmd_format;

    $cmd_format = $cmd_format->($self) if ref $cmd_format;

    my %attrs   = %{$self};
    my $context = $self->{context};
    if (ref $context eq 'Sympa::List') {
        @attrs{qw(localpart domainpart)} =
            split /\@/, Sympa::get_address($context);
    } elsif (ref $context eq 'Sympa::Family') {
        #FIXME:family name
        $attrs{domainpart} = $context->{'domain'};
    } else {
        $attrs{domainpart} = $context;
    }
    return sprintf $cmd_format,
        map { defined $_ ? $_ : '' } @attrs{@{$arg_keys || []}};
}

sub dup {
    my $self = shift;

    my $clone = {};
    foreach my $key (sort keys %$self) {
        my $val = $self->{$key};
        next unless defined $val;

        unless (Scalar::Util::blessed($val)) {
            $clone->{$key} = Sympa::Tools::Data::dup_var($val);
        } elsif ($val->can('dup')
            and !$val->isa('Sympa::List')
            and !$val->isa('Sympa::Family')) {
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
    foreach my $attr (sort keys %attrmap) {
        my $val = _canonic_value($self->{$attr});
        if (defined $val and length $val) {
            $msg_string .= sprintf "%s: %s\n", $attrmap{$attr}, $val;
        }
    }

    my $optattrs = join '; ', map {
        my $val = _canonic_value($self->{$_});
        (defined $val and length $val)
            ? (sprintf '%s=%s', $_, $val)
            : ();
    } @optattrs;
    if ($optattrs) {
        $msg_string .= sprintf "X-Sympa-Options: %s\n", $optattrs;
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

sub _canonic_value {
    my $val = shift;

    return undef unless defined $val;
    $val =~ s/\A\s+//;
    $val =~ s/\s+\z//;
    $val =~ s/(?:\r\n|\r|\n)(?=[ \t])//g;
    $val =~ s/\r\n|\r|\n/ /g;
    $val;
}

sub handler {
    shift->{_handler};
}

sub get_id {
    my $self = shift;

    join ';', map {
        my $val = $self->{$_};
        if (Scalar::Util::blessed($val) and $val->can('get_id')) {
            sprintf '%s=%s', $_, $val->get_id;
        } elsif (ref $val eq 'HASH' and $_ eq 'request') {    # FIXME
            sprintf '%s=<%s>', $_, get_id($val);
        } elsif (ref $val) {
            sprintf '%s=%s', $_, ref $val;
        } else {
            sprintf '%s=%s', $_, $val;
        }
    } grep {
        defined $self->{$_}
        } qw(action context current_list listname arc mode role email
        reception visibility request error);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request - Requests for operation

=head1 SYNOPSIS

  use Sympa::Request;
  my $request = Sympa::Request->new($serialized, context => $list);
  my $request = Sympa::Request->new(context => $list, action => 'last');

=head1 DESCRIPTION

L<Sympa::Request> implements serializable object representing requests by
users.

=head2 Methods

=over

=item new ( [ $serialized, ] context =E<gt> $that, action =E<gt> $action,
key =E<gt> value, ... ] )

I<Constructor>.
Creates a new L<Sympa::Request> object.

Parameters:

=over

=item $serialized

Serialized request.

=item context =E<gt> object

Context.  L<Sympa::List> object, Robot or C<'*'>.

=item action =E<gt> $action

Name of requested action.

=item key =E<gt> value, ...

Metadata and attributes.

=back

Returns:

A new instance of L<Sympa::Request>, or I<undef>, if something went wrong.

=item new_from_tuples ( key =E<gt> value, ... )

I<Constructor>.
OBSOLETED.
Creates L<Sympa::Request> object from paired options.

=item dup ( )

I<Copy constructor>.
Gets deep copy of instance.

=item to_string ( )

I<Serializer>.
Returns serialized data of object.

=item cmd_line ( [ canonic =E<gt> 1 ] )

I<Instance method>.
TBD.

=item handler ( )

I<Instance method>.
Name of a subclass of L<Sympa::Request::Handler> to process request.

=item get_id ( )

I<Instance method>.
Gets unique identifier of instance.

=back

=head2 Context and metadata

Context and metadata given to constructor are accessible as hash elements
of object.
They are given by request spool.
See L<Sympa::Spool::Auth/"Context and metadata"> for details.

=head2 Attributes

These are accessible as hash elements of objects.
There are attributes including:

=over

=item {custom_attribute}

Custom attribute connected to requested action.

=item {gecos}

Display name of user sending request.

=item {sender}

E-mail of user who sent the request.

=back

=head2 Serialization

L<Sympa::Request> object includes number of slots as hash items:
B<metadata>, B<context> and B<attributes>.
Metadata including context are given by spool:
See L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

Logically, objects are stored into physical spool as B<serialized form>
and deserialized when they are fetched from spool.
Attributes are encoded in C<X-Sympa-*:> pseudo-header fields.

See also L<Sympa::Message/"Serialization"> for example.

=head1 SEE ALSO

L<Sympa::Request::Collection>,
L<Sympa::Request::Handler>,
L<Sympa::Request::Message>,
L<Sympa::Spool::Auth>.

=head1 HISTORY

L<Sympa::Request> appeared on Sympa 6.2.10.

=cut
