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

package Sympa::Request::Handler;

use strict;
use warnings;

use base qw(Sympa::Spindle);

sub action_regexp {
    my $self = shift;
    $self->_action_scenario ? $self->_action_regexp : undef;
}

sub action_scenario {
    shift->_action_scenario;
}

sub context_class {
    shift->_context_class;
}

sub _context_class {''}

sub owner_action {
    shift->_owner_action;
}

sub _owner_action {undef}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler - Base class of request handler classes

=head1 SYNOPSIS

  package Sympa::Request::Handler::foo;
  use base qw(Sympa::Request::Handler);
  
  use constant _action_regexp   => qr{reject|request_auth|do_it}i;
  use constant _action_scenario => 'review';
  use constant _context_class   => 'Sympa::List';
  
  sub _twist {
      ...
  }
  
  1;

=head1 DESCRIPTION

L<Sympa::Request::Handler> is the base class of subclasses to process
instance of L<Sympa::Request>.

=head2 Methods

TBD.

=head2 Methods subclass should implement

=over

=item _action_regexp ( )

I<Instance method>,
I<mandatory> if _action_scenario() returns true value.
Returns a regexp matching available scenario results.
Note that C<i> modifier is necessary.

=item _action_scenario ( )

I<Instance method>,
I<mandatory>.
Returns the name of scenario to authorize the request under given context.
If authorization is not required, returns C<undef>.

=item _context_class ( )

I<Instance method>.
Returns the class name of context under which the request will be executed,
L<Sympa::List> etc.
By default, returns robot context.

=item _owner_action ( )

I<Instance method>.
Returns name of action to be stored in spool when scenario returns C<owner>.
By default, returns C<undef>.

=item _twist ( $request )

I<Instance method>,
I<mandatory>.
See L<Sympa::Spindle/"_twist">.

=back

=head1 SEE ALSO

L<Sympa::Request>, L<Sympa::Spindle>.

=head1 HISTORY

L<Sympa::Request::Handler> appeared on Sympa 6.2.15.

=cut
