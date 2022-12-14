# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2022 The Sympa Community. See the
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

package Sympa::Spindle::TransformOutgoing;

use strict;
use warnings;

use Sympa;
use Sympa::Log;
use Sympa::Message::Plugin;
use Sympa::Robot;

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
                $reply = Sympa::get_address($list);
            } elsif (
                $list->{'admin'}{'reply_to_header'}->{'value'} eq 'sender') {
                #FIXME: Missing From: field?
                $reply = $message->get_header('From');
            } elsif ($list->{'admin'}{'reply_to_header'}->{'value'} eq 'all')
            {
                #FIXME: Missing From: field?
                $reply =
                    Sympa::get_address($list) . ','
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
    $message->add_header('X-Loop',     Sympa::get_address($list));
    $message->add_header('X-Sequence', $message->{xsequence})
        if defined $message->{xsequence};
    ## These fields should be overwritten if any of them already exist
    $message->delete_header('Errors-To');
    $message->add_header('Errors-To',
        Sympa::get_address($list, 'return_path'));
    ## Two Precedence: fields are added (overwritten), as some MTAs recognize
    ## only one of them.
    $message->delete_header('Precedence');
    $message->add_header('Precedence', 'list');
    $message->add_header('Precedence', 'bulk');
    # The Sender: field should be added (overwritten) at least for DKIM or
    # Sender ID (a.k.a. SPF 2.0) compatibility.  Note that Resent-Sender:
    # field will be removed.
    $message->replace_header('Sender', Sympa::get_address($list, 'owner'));
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
    # At first, delete fields of parent list.  See RFC 2369, section 4.
    foreach my $h (
        qw(List-Help List-Subscribe List-Unsubscribe List-Owner
        List-Unsubscribe-Post)
    ) {
        $message->delete_header($h);
    }
    foreach my $field (
        @{  Sympa::Robot::list_params($list->{'domain'})
                ->{'rfc2369_header_fields'}->{'format'}
        }
    ) {
        if (scalar grep { $_ eq $field }
            @{$list->{'admin'}{'rfc2369_header_fields'}}) {
            $list->add_list_header($message, $field);
        }
    }

    # Add RFC5064 Archived-At: header field
    # Sympa::Spindle::ResendArchive will give "arc" parameter.
    $list->add_list_header($message, 'archived_at', arc => $self->{arc});

    ## Remove outgoing header fields
    ## Useful to remove some header fields that Sympa has set
    if ($list->{'admin'}{'remove_outgoing_headers'}) {
        foreach my $field (@{$list->{'admin'}{'remove_outgoing_headers'}}) {
            my ($f, $v) = split /\s*:\s*/, $field;
            if (defined $v) {
                my @values = $message->get_header($f);
                my $i;
                for ($i = $#values; 0 <= $i; $i--) {
                    $message->delete_header($f, $i) if $values[$i] eq $v;
                }
            } else {
                $message->delete_header($field);
            }
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

This class executes the second stage of message transformation to be sent
through the list. This stage is put after storing messages into archive
spool (See also L<Sympa::Spindle::DistributeMessage>).
Transformation processes by this class are done in the following order:

=over

=item *

Executes C<post_archive> hook of L<message hooks|Sympa::Message::Plugin>
if available.

=item *

Adds / modifies C<Reply-To> header field,
if L<C<reply_to_header>|list_config(5)/reply_to_header> list option is
enabled.

=item *

Adds / overwrites following header fields:

=over

=item C<X-Loop>

=item C<X-Sequence>

=item C<Errors-To>

=item C<Precedence>

=item C<Sender>

=item C<X-no-archive>

=back

=item *

Adds header fields specified by
L<C<custom_header>|list_config(5)/custom_header> list configuration parameter,
if any.

=item *

Adds RFC 2919 C<List-Id> field,
RFC 2369 fields (according to
L<C<rfc2369_header_fields>|list_config(5)/rfc2369_header_fields> list
configuration option) and RFC 5064 C<Archived-At> field (if archiving is
enabled).
 
=item *

Removes header fields specified by
L<C<remove_outgoing_headers>|list_config(5)/remove_outgoing_headers>
list configuration parameter, if any.

=back

Then this class passes the message to the last stage of transformation,
L<Sympa::Spindle::ToList>.

=head1 CAVEAT

=over

=item *

Transformation by this class can break integrity of DKIM signature,
because some header fields may be removed according to
C<remove_outgoing_headers> list configuration parameter.

=back

=head1 SEE ALSO

L<Sympa::Internals::Workflow>.

L<Sympa::Message>,
L<Sympa::Message::Plugin>,
L<Sympa::Spindle>,
L<Sympa::Spindle::DistributeMessage>.

=head1 HISTORY

L<Sympa::Spindle::TransformOutgoing> appeared on Sympa 6.2.13.

=cut
