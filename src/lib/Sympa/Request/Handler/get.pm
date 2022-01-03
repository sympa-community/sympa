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

package Sympa::Request::Handler::get;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Archive;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'archive_mail_access';
use constant _action_regexp   => qr'reject|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::getfile().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    my $arc = $request->{arc};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived) {
        $self->add_stash($request, 'user', 'empty_archives');
        $log->syslog('info',
            'GET %s %s from %s refused, no archive for list %s',
            $which, $arc, $sender, $which);
        return undef;
    }

    my $archive = Sympa::Archive->new(context => $list);
    my @msg_list;
    unless ($archive->select_archive($arc)) {
        $self->add_stash($request, 'user', 'no_required_file');
        $log->syslog('info', 'GET %s %s from %s, no such archive',
            $which, $arc, $sender);
        return undef;
    }

    while (1) {
        my ($arc_message, $arc_handle) = $archive->next;
        last unless $arc_handle;     # No more messages.
        next unless $arc_message;    # Malformed message.
        $arc_handle->close;          # Unlock.

        # Decrypt message if possible
        $arc_message->smime_decrypt;

        $log->syslog('debug', 'MAIL object: %s', $arc_message);

        push @msg_list,
            {
            id       => $arc_message->{serial},
            subject  => $arc_message->{decoded_subject},
            from     => $arc_message->get_decoded_header('From'),
            date     => $arc_message->get_decoded_header('Date'),
            full_msg => $arc_message->as_string
            };
    }

    my $param = {
        to      => $sender,
        subject => $language->gettext_sprintf(
            'Archive of %s, file %s',
            $list->{'name'}, $arc
        ),
        msg_list       => [@msg_list],
        auto_submitted => 'auto-replied'
    };
    unless (Sympa::send_file($list, 'get_archive', $sender, $param)) {
        my $error = sprintf 'Unable to send archive to %s', $sender;
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error  => $error,
                who    => $sender,
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'GET %s %s from %s accepted (%.2f seconds)',
        $which, $arc, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::get - get request handler

=head1 DESCRIPTION

Sends back the requested archive file using 'get_archive' template.

=head1 SEE ALSO

L<Sympa::Archive>, L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
