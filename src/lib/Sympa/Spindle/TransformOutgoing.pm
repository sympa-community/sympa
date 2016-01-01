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

package Sympa::Spindle::TransformOutgoing;

use strict;
use warnings;

use Sympa::Log;
use Sympa::Message::Plugin;
use tools;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

# Transformation of message after archiving.
# Old name: Sympa::List::post_archive().
sub _twist {
    my $self    = shift;
    my $message = shift;

    Sympa::Message::Plugin::execute('post_archive', $message);

    my $list = $message->{context};

    # Change the Reply-To: header field if necessary.
    if ($list->{'admin'}{'reply_to_header'}) {
        unless ($message->get_header('Reply-To')
            and $list->{'admin'}{'reply_to_header'}->{'apply'} ne 'forced') {
            my $reply;

            $message->delete_header('Reply-To');
            $message->delete_header('Resent-Reply-To');

            if ($list->{'admin'}{'reply_to_header'}->{'value'} eq 'list') {
                $reply = $list->get_list_address();
            } elsif (
                $list->{'admin'}{'reply_to_header'}->{'value'} eq 'sender') {
                #FIXME: Missing From: field?
                $reply = $message->get_header('From');
            } elsif ($list->{'admin'}{'reply_to_header'}->{'value'} eq 'all')
            {
                #FIXME: Missing From: field?
                $reply =
                      $list->get_list_address() . ','
                    . $message->get_header('From');
            } elsif ($list->{'admin'}{'reply_to_header'}->{'value'} eq
                'other_email') {
                $reply = $list->{'admin'}{'reply_to_header'}->{'other_email'};
            }

            $message->add_header('Reply-To', $reply) if $reply;
        }
    }

    ## Add/replace useful header fields

    ## These fields should be added preserving existing ones.
    $message->add_header('X-Loop',     $list->get_list_address);
    $message->add_header('X-Sequence', $message->{xsequence})
        if defined $message->{xsequence};
    ## These fields should be overwritten if any of them already exist
    $message->delete_header('Errors-To');
    $message->add_header('Errors-To', $list->get_list_address('return_path'));
    ## Two Precedence: fields are added (overwritten), as some MTAs recognize
    ## only one of them.
    $message->delete_header('Precedence');
    $message->add_header('Precedence', 'list');
    $message->add_header('Precedence', 'bulk');
    # The Sender: field should be added (overwritten) at least for DKIM or
    # Sender ID (a.k.a. SPF 2.0) compatibility.  Note that Resent-Sender:
    # field will be removed.
    $message->replace_header('Sender', $list->get_list_address('owner'));
    $message->delete_header('Resent-Sender');
    $message->replace_header('X-no-archive', 'yes');

    # Add custom header fields
    foreach my $i (@{$list->{'admin'}{'custom_header'}}) {
        $message->add_header($1, $2) if $i =~ /^([\S\-\:]*)\s(.*)$/;
    }

    ## Add RFC 2919 header field
    if ($message->get_header('List-Id')) {
        $log->syslog(
            'notice',
            'Found List-Id: %s',
            $message->get_header('List-Id')
        );
        $message->delete_header('List-ID');
    }
    $list->add_list_header($message, 'id');

    ## Add RFC 2369 header fields
    foreach my $field (
        @{  tools::get_list_params($list->{'domain'})
                ->{'rfc2369_header_fields'}->{'format'}
        }
        ) {
        if (scalar grep { $_ eq $field }
            @{$list->{'admin'}{'rfc2369_header_fields'}}) {
            $list->add_list_header($message, $field);
        }
    }

    # Add RFC5064 Archived-At: header field
    $list->add_list_header($message, 'archived_at');

    ## Remove outgoing header fields
    ## Useful to remove some header fields that Sympa has set
    if ($list->{'admin'}{'remove_outgoing_headers'}) {
        foreach my $field (@{$list->{'admin'}{'remove_outgoing_headers'}}) {
            $message->delete_header($field);
        }
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::TransformOutgoing -
Process to transform messages - second stage

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Message::Plugin>,
L<Sympa::Spindle>,
L<Sympa::Spindle::DistributeMessage>.

=head1 HISTORY

L<Sympa::Spindle::TransformOutgoing> appeared on Sympa 6.2.13.

=cut
