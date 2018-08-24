# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

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

package Sympa::Spindle::ResendArchive;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::Text;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Archive';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        die 'bug in logic. Ask developer'
            unless $self->{resent_by}
            and $self->{context}
            and $self->{arc}
            and $self->{message_id};
        $self->{distaff}->select_archive($self->{arc})
            or return 0;
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
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    # Keep succeeded message and exit.
    $handle->close;
    $self->{finish} = 'success';
}

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $message_id = Sympa::Tools::Text::canonic_message_id(
        $message->get_header('Message-Id'))
        || '';
    return 0 unless $message_id eq $self->{message_id};

    # Decrpyt message.
    # If encrypted, it will be re-encrypted by succeeding processes.
    $message->smime_decrypt;

    # Assign privileges of resending user to the message.
    $message->{envelope_sender} = $self->{resent_by};

    return ['Sympa::Spindle::TransformOutgoing', 'Sympa::Spindle::ToList'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ResendArchive - Workflow of resending messages in archive

=head1 SYNOPSIS

  use Sympa::Spindle::ResendArchive;

  my $spindle = Sympa::Spindle::ResendArchive->new(
      resent_by => $email, context => $list, arc => $arc,
      message_id => $message_id);
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ResendArchive> defines workflow for resending of messages
in archive.

When spin() method is invoked, it reads a message in archive,
decorate and distribute it.
Either resending failed or not, spin() will terminate
processing.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( resent_by =E<gt> $email,
context =E<gt> $list, arc =E<gt> $arc, message_id =E<gt> $message_id,
[ quiet =E<gt> 1 ] )

=item spin ( )

new() must take following options:

=over

=item resent_by =E<gt> $email

E-mail address of the user who requested resending message.
It is given by do_send_me() function of wwsympa.fcgi and
used by L<Sympa::Spindle::ToList> to whom distribute message.

=item context =E<gt> $list

=item arc =E<gt> $arc

=item message_id =E<gt> $message_id

Context (List), archive and message ID to specify the message in archive.

Note:
C<arc> parameter will be used by a latter part of processing,
L<Sympa::Spindle::TransformOutgoing> to construct C<Archived-At> field.

=item quiet =E<gt> 1

NOT YET IMPLEMENTED.

If this option is set, automatic replies reporting result of processing
to the user (see L</"resent_by">) will not be sent.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Archive> class.

=item {finish}

C<'success'> is set if processing succeeded.
C<'failure'> is set if processing failed.

=back

=head1 SEE ALSO

L<Sympa::Archive>,
L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::ToList>,
L<Sympa::Spindle::TransformOutgoing>.

=head1 HISTORY

L<Sympa::Spindle::ResendArchive> appeared on Sympa 6.2.13.

=cut
