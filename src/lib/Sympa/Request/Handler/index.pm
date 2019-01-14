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

package Sympa::Request::Handler::index;

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

# Old name: Sympa::Commands::index().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        $self->add_stash($request, 'user', 'empty_archives');
        $log->syslog('info', 'INDEX %s from %s refused, list not archived',
            $which, $sender);
        return undef;
    }

    my @arcs;
    if ($list->is_archived) {
        my $archive = Sympa::Archive->new(context => $list);
        foreach my $arc ($archive->get_archives) {
            my $info = $archive->select_archive($arc, info => 1);
            next unless $info;

            push @arcs,
                $language->gettext_sprintf(
                '%-37s %5.1f kB   %s',
                $arc,
                $info->{size} / 1024.0,
                $language->gettext_strftime(
                    '%a, %d %b %Y %H:%M:%S',
                    localtime $info->{mtime}
                )
                ) . "\n";
        }
    }

    unless (
        Sympa::send_file(
            $list, 'index_archive', $sender,
            {'archives' => \@arcs, 'auto_submitted' => 'auto-replied'}
        )
    ) {
        $log->syslog('notice',
            'Unable to send template "index_archive" to %s', $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'INDEX %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::index - index request handler

=head1 DESCRIPTION

Sends the list of archived files of a list using 'index_archive' template.

=head1 SEE ALSO

L<Sympa::Archive>, L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
