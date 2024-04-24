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

package Sympa::Request::Handler::info;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Scenario;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'info';
use constant _action_regexp   => qr'reject|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::info().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    my $data;
    foreach my $key (keys %{$list->{'admin'}}) {
        $data->{$key} = $list->{'admin'}{$key};
    }

    ## Set title in the current language
    foreach my $p ('subscribe', 'unsubscribe', 'send', 'review') {
        my $scenario = Sympa::Scenario->new($list, $p);
        $data->{$p} = $scenario->get_current_title;
    }

    ## Digest
    my @days;
    if (defined $list->{'admin'}{'digest'}) {

        foreach my $d (@{$list->{'admin'}{'digest'}{'days'}}) {
            push @days,
                $language->gettext_strftime("%A",
                localtime(0 + ($d + 3) * (3600 * 24)));
        }
        $data->{'digest'} =
              join(',', @days) . ' '
            . $list->{'admin'}{'digest'}{'hour'} . ':'
            . $list->{'admin'}{'digest'}{'minute'};
    }

    ## Reception mode
    $data->{'available_reception_mode'} = $list->available_reception_mode();
    $data->{'available_reception_modeA'} =
        [$list->available_reception_mode()];

    $data->{'url'} = Sympa::get_url($list, 'info');

    # Owners and moderators no longer are saved in the config file.
    $data->{owner} = [$list->get_admins('owner')];
    $data->{editor} = [$list->get_admins('editor')];

    unless (Sympa::send_file($list, 'info_report', $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "info_report" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'INFO %s from %s accepted (%.2f seconds)',
        $listname, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::info - info request handler

=head1 DESCRIPTION

Sends the information of a list to the requester using 'info_report' template.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
