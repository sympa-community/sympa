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

package Sympa::Spindle::ProcessAuth;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Auth';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        die 'bug in logic. Ask developer'
            unless $self->{confirmed_by}
                and $self->{context}
                and $self->{keyauth};
    }

    1;
}

sub _on_garbage {
    my $self   = shift;
    my $handle = shift;

    # Keep broken request and skip it.
    $handle->close;
}

sub _on_failure {
    my $self    = shift;
    my $request = shift;
    my $handle  = shift;

    # Keep failed request and exit.
    $handle->close;
    $self->{finish} = 'failure';
}

sub _on_success {
    my $self = shift;

    # Remove succeeded request and exit.
    $self->SUPER::_on_success(@_);
    $self->{finish} = 'success';
}

sub _twist {
    my $self    = shift;
    my $request = shift;

    # Assign privileges of confirming user to the request.
    $request->{sender}    = $self->{confirmed_by};
    $request->{md5_check} = 1;

    return ['Sympa::Spindle::AuthorizeRequest'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessAuth - Workflow of request confirmation

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessAuth;

  my $spindle = Sympa::Spindle::ProcessAuth->new(
      confirmed_by => $email, context => $robot, keyauth => $key,
      scenario_context => {sender => $sender});
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessAuth> defines workflow for confirmation of held
requests.

When spin() method is invoked, it reads a request in held request spool,
authorizes it and dispatch it if possible.
Either authorization and dispatching failed or not, spin() will terminate
processing.
Failed request will be kept in spool and wait for confirmation again.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( confirmed_by =E<gt> $email,
context =E<gt> $context, keyauth =E<gt> $key,
[ quiet =E<gt> 1 ], scenario_context =E<gt> {context...} )

=item spin ( )

new() must take following options:

=over

=item confirmed_by =E<gt> $email

E-mail address of the user who confirmed the request.
It is given by AUTH command and
used by L<Sympa::Spindle::AuthorizeRequest> to execute scenario.

=item context =E<gt> $context

=item keyauth =E<gt> $key

Context (List or Robot) and authorization key to specify the request in
spool.

=item quiet =E<gt> 1

If this option is set, automatic replys reporting result of processing
to the user (see L</"confirmed_by">) will not be sent.

=item scenario_context =E<gt> {context...}

Authorization context given to scenario.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Auth> class.

=item {finish}

C<'success'> is set if processing succeeded.
C<'failure'> is set if processing failed.

=back

=head1 SEE ALSO

L<Sympa::Request>,
L<Sympa::Spindle>, L<Sympa::Spindle::AuthorizeRequest>,
L<Sympa::Spool::Auth>.

=head1 HISTORY

L<Sympa::Spindle::ProcessAuth> appeared on Sympa 6.2.15.

=cut
