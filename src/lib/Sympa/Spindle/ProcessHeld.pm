# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: Commands.pm 12548 2015-11-28 08:33:32Z sikeda $

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

package Sympa::Spindle::ProcessHeld;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Held';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        die 'bug in logic. Ask developer'
            unless $self->{confirmed_by}
            and $self->{context}
            and $self->{authkey};
    }

    1;
}

sub _on_garbage {
    my $self   = shift;
    my $handle = shift;

    # Keep broken message and skip it.
    $handle->close;
}

sub _on_failure {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    # Keep failed message and exit.
    $handle->close;
    $self->{finish} = 'failure';
}

sub _on_success {
    my $self = shift;

    # Remove succeeded message and exit.
    $self->SUPER::_on_success(@_);
    $self->{finish} = 'success';
}

sub _twist {
    my $self    = shift;
    my $message = shift;

    # Decrpyt message.
    # If encrypted, it will be re-encrypted by succeeding processes.
    $message->smime_decrypt;

    # Assign privileges of confirming user to the message.
    $message->{envelope_sender} = $self->{confirmed_by};
    $message->{md5_check}       = 1;

    unless (ref $message->{context} eq 'Sympa::List') {
        $log->syslog('notice', 'Unknown list %s', $message->{localpart});
        Sympa::send_dsn($message->{context} || '*', $message, {}, '5.1.1');
        return undef;
    }
    my $list = $message->{context};

    Sympa::Language->instance->set_lang(
        $list->{'admin'}{'lang'},
        Conf::get_robot_conf($list->{'domain'}, 'lang'),
        $Conf::Conf{'lang'}, 'en'
    );

    return ['Sympa::Spindle::AuthorizeMessage'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessHeld - Workflow of message confirmation

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessHeld;

  my $spindle = Sympa::Spindle::ProcessHeld->new(
      confirmed_by => $email, context => $robot, authkey => $key);
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessHeld> defines workflow for confirmation of held
messages.

When spin() method is invoked, it reads a message in held message spool,
authorizes it and distribute it if possible.
Either authorization and distribution failed or not, spin() will terminate
processing.
Failed message will be kept in spool and wait for confirmation again.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( confirmed_by =E<gt> $email,
context =E<gt> $context, authkey =E<gt> $key,
[ quiet =E<gt> 1 ] )

=item spin ( )

new() must take following options:

=over

=item confirmed_by =E<gt> $email

E-mail address of the user who confirmed the message.
It is given by CONFIRM command and
used by L<Sympa::Spindle::AuthorizeMessage> to execute "send" scenario.

=item context =E<gt> $context

=item authkey =E<gt> $key

Context (List or Robot) and authorization key to specify the message in
spool.

=item quiet =E<gt> 1

If this option is set, automatic replies reporting result of processing
to the user (see L</"confirmed_by">) will not be sent.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Held> class.

=item {finish}

C<'success'> is set if processing succeeded.
C<'failure'> is set if processing failed.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::AuthorizeMessage>,
L<Sympa::Spool::Held>.

=head1 HISTORY

L<Sympa::Spindle::ProcessHeld> appeared on Sympa 6.2.13.

=cut
