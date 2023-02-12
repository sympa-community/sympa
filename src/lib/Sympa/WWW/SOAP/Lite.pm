# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
#
# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2023 The Sympa Community. See the
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

use strict;
use warnings;
use Encode qw();
use SOAP::Lite;

package Sympa::WWW::SOAP::Transport;

# 'base' pragma doesn't work here
our @ISA = qw(SOAP::Transport);

sub AUTOLOAD {
    our $AUTOLOAD;

    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
    return if $method eq 'DESTROY';

    no strict 'refs';
    *$AUTOLOAD = sub {
        shift->proxy->$method(
            map { Encode::is_utf8($_) ? Encode::encode_utf8($_) : $_ } @_);
    };
    goto &$AUTOLOAD;
}

1;

package Sympa::WWW::SOAP::Data;

# 'base' pragma doesn't work here
our @ISA = qw(SOAP::Data);

sub type {
    my $self = shift;
    if (@_) {
        my ($type, @value) = @_;

        if ($type eq 'string') {
            return $self->SUPER::type($type,
                map { Encode::is_utf8($_) ? $_ : Encode::decode_utf8($_) }
                    @value);
        }
    }

    return $self->SUPER::type(@_);
}

sub value {
    my $self = shift;

    if (($self->type // '') eq 'string') {
        return $self->SUPER::value(
            map { Encode::is_utf8($_) ? $_ : Encode::decode_utf8($_) } @_);
    }

    return $self->SUPER::value(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::WWW::SOAP::Lite - Overrides on SOAP::Lite for Sympa

=head1 DESCRIPTION

This module provides following subclasses of those in L<SOAP::Lite>.

=over

=item C<Sympa::WWW::SOAP::Data>

The C<type()> and C<value()> methods will decode strings to utf8-flagged
ones.

=item C<Sympa::WWW::SOAP::Transport>

This will encode utf8-flagged parameters to byte-strings and pass them to
dispatched SOAP methods.

=back

=head1 HISTORY

L<Sympa::WWW::SOAP::Lite> was introdiced on Sympa 6.2.73b.
Note that, at this time, L<Sympa::WWW::SOAP::Transport>
in earlier release was renamed to L<Sympa::WWW:SOAP::FastCGI>.

=cut
