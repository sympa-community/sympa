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

package Sympa::Spindle::ProcessTemplate;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Message::Template';

sub _on_failure {
    shift->{finish} = 'failure';
}

use constant _on_garbage => 1;
use constant _on_skip    => 1;

sub _on_success {
    shift->{finish} = 'success';
}

sub _twist {
    my $self    = shift;
    my $message = shift;

    $log->syslog(
        'notice',
        'Processing %s; envelope_sender=%s; message_id=%s; recipients=%s; sender=%s; template=%s; %s',
        $message,
        $message->{envelope_sender},
        $message->{message_id},
        $self->{rcpt},
        $message->{sender},
        $self->{template},
        join('; ',
            map { $self->{data}->{$_} ? ("$_=$self->{data}->{$_}") : () }
                qw(type action reason status))
    );

    $message->{rcpt} = $self->{rcpt};

    return $self->{splicing_to} || ['Sympa::Spindle::ToOutgoing'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessTemplate - Workflow of template sending

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessTemplate;

  my $spindle = Sympa::Spindle::ProcessTemplate->new( options... );
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessTemplate> defines workflow to send messages
generated from template.

When spin() method is invoked, it takes an message generated from template,
sends the message using another outgoing spindle and returns.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( I<template options>, [ splicing_to =E<gt> [spindles] ],
[ add_list_statistics =E<gt> 1 ] )

=item spin ( )

new() may take following options.

=over

=item I<template options>

See L<Sympa::Message::Template/"new">.

=item splicing_to =E<gt> [spindles]

A reference to array containing L<Sympa::Spindle> subclass(es) by which
the message will be sent.
By default C<['Sympa::Spindle::ToOutgoing']> is used.

=item add_list_statistics =E<gt> 1

TBD.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Message::Template> class.

=item {finish}

C<'success'> is set if processing succeeded.
C<'failure'> is set if processing failed.

=back

=head1 SEE ALSO

L<Sympa::Message::Template>,
L<Sympa::Spindle>,
L<Sympa::Spindle::ToListmaster>, L<Sympa::Spindle::ToMailer>,
L<Sympa::Spindle::ToOutgoing>.

=head1 HISTORY

L<Sympa::Spindle::ProcessTemplate> appeared on Sympa 6.2.13.

=cut
