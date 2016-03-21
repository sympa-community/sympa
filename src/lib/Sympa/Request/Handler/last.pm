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

package Sympa::Request::Handler::last;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Archive;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Sends back the last archive file.
# Old name: Sympa::Commands::last().
sub _twist {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $self->add_stash($request, 'user', 'unknown_list');
        $log->syslog(
            'info',
            '%s from %s refused, unknown list for robot %s',
            uc $request->{action},
            $request->{sender}, $request->{context}
        );
        return 1;
    }
    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        $self->add_stash($request, 'user', 'empty_archives');
        $log->syslog('info', 'LAST %s from %s refused, list not archived',
            $which, $sender);
        return undef;
    }

    my ($arc_message, $arc_handle);
    my $archive = Sympa::Archive->new(context => $list);
    foreach my $arc (reverse $archive->get_archives) {
        next unless $archive->select_archive($arc);
        ($arc_message, $arc_handle) = $archive->next(reverse => 1);
        last if $arc_message;
    }
    unless ($arc_message) {
        $self->add_stash($request, 'user', 'no_required_file');
        $log->syslog('info', 'LAST %s from %s, no such archive',
            $which, $sender);
        return undef;
    }
    $arc_handle->close;    # Unlock.

    # Decrypt message if possible.
    $arc_message->smime_decrypt;

    my @msglist = (
        {   id       => 1,
            subject  => $arc_message->{'decoded_subject'},
            from     => $arc_message->get_decoded_header('From'),
            date     => $arc_message->get_decoded_header('Date'),
            full_msg => $arc_message->as_string
        }
    );
    my $param = {
        to      => $sender,
        subject => $language->gettext_sprintf(
            'Archive of %s, last message',
            $list->{'name'}
        ),
        msg_list       => [@msglist],
        boundary1      => Sympa::unique_message_id($list),
        boundary2      => Sympa::unique_message_id($list),
        auto_submitted => 'auto-replied'
    };
    unless (Sympa::send_file($list, 'get_archive', $sender, $param)) {
        $log->syslog('notice', 'Unable to send template "get_archive" to %s',
            $sender);
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

    $log->syslog('info', 'LAST %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

1;
__END__
