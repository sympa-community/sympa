# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2022 The Sympa Community. See the
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

package Sympa::Request::Handler::set;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

# Old name: (part of) Sympa::Commands::set().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $sender = $request->{sender};
    my $email  = $request->{email};
    my $role   = $request->{role} || 'member';

    die 'bug in logic. Ask developer'
        unless grep { $role eq $_ } qw(member owner editor);

    $language->set_lang($list->{'admin'}{'lang'});

    # Check if we know this email on the list. Otherwise just reject the
    # message.
    if ($role eq 'member') {
        unless ($list->is_list_member($email)) {
            unless ($email eq $sender) {    # Request from owner?
                $self->add_stash($request, 'user', 'user_not_subscriber');
            } else {
                $self->add_stash($request, 'user', 'not_subscriber');
            }
            $log->syslog('info',
                'SET %s from %s refused, %s (%s) not on list',
                $list, $sender, $email, $role);
            return undef;
        }
    } else {
        unless ($list->is_admin($role, $email)) {
            $self->add_stash($request, 'user', 'not_list_user',
                {listname => $list->{'name'}, role => $role, email => $email}
            );
            $log->syslog('info',
                'SET %s from %s refused, %s (%s) not on list',
                $list, $sender, $email, $role);
            return undef;
        }
    }

    my $gecos      = $request->{gecos};
    my $reception  = $request->{reception};
    my $visibility = $request->{visibility};
    # for editor and owner
    my $info = $request->{info};
    # for owner
    my $profile = $request->{profile};

    # Note that empty (or including spaces only) value makes the name unset.
    if (defined $gecos) {
        $gecos =~ s/\A\s+//;
        $gecos =~ s/\s+\z//;
    }
    if (defined $info) {
        $info =~ s/\A\s+//;
        $info =~ s/\s+\z//;
    }

    if ($role eq 'member') {
        #FIXME: this should be merged into is_available_reception_mode().
        # May set to DIGEST.
        if (    $reception
            and grep { $reception eq $_ } qw(digest digestplain summary)
            and not $list->is_digest) {
            $self->add_stash($request, 'user', 'no_digest');
            $log->syslog('info', 'SET %s %s from %s refused, no digest mode',
                $list, $reception, $sender);
            return undef;
        }

        # Verify that the mode is allowed.
        if ($reception and not $list->is_available_reception_mode($reception))
        {
            $self->add_stash(
                $request, 'user',
                'not_available_reception_mode',
                {   modes => join(' ', $list->available_reception_mode),
                    reception_modes => [$list->available_reception_mode],
                    reception_mode  => $reception,
                }
            );
            $log->syslog('info',
                'SET %s %s from %s refused, mode not available',
                $list, $reception, $sender);
            return undef;
        }
    } else {
        if ($reception
            and not grep { $reception eq $_ } qw(mail nomail)) {
            $self->add_stash(
                $request, 'user',
                'not_available_reception_mode',
                {reception_mode => $reception, role => $role}
            );
            $log->syslog('info',
                'SET %s %s from %s refused, mode not availeble',
                $list, $reception, $sender);
            return undef;
        }
    }

    if ($visibility
        and not grep { $visibility eq $_ } qw(conceal noconceal)) {
        $self->add_stash($request, 'user', 'not_available_visibility',
            {visibility => $visibility, role => $role});
        $log->syslog('info',
            'SET %s %s from %s refused, visibility not availeble',
            $list, $visibility, $sender);
        return undef;
    }

    if (    $role eq 'owner'
        and $profile
        and not grep { $profile eq $_ } qw(normal privileged)) {
        $self->add_stash($request, 'user', 'not_available_profile',
            {profile => $profile, role => $role});
        $log->syslog('info',
            'SET %s %s from %s refused, profile not availeble',
            $list, $profile, $sender);
        return undef;
    }

    if ($role eq 'member') {
        unless (defined $gecos
            or $reception
            or $visibility) {
            $log->syslog('info', 'No properties to be changed');
            $self->add_stash($request, 'user', 'no_changed_properties',
                {listname => $list->{'name'}, email => $email, role => $role}
            );
            return 1;
        }
        unless (
            $list->update_list_member(
                $email,
                (defined $gecos ? (gecos      => $gecos)      : ()),
                ($reception     ? (reception  => $reception)  : ()),
                ($visibility    ? (visibility => $visibility) : ()),
                update_date => time
            )
        ) {
            my $error =
                sprintf
                'Failed to change subscriber "%s" options for list %s',
                $email, $list->get_id;
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
            $log->syslog('info', 'SET %s %s%s from %s refused, update failed',
                $list, $reception, $visibility, $sender);
            return undef;
        }
    } elsif ($role eq 'editor') {
        unless (defined $gecos
            or $reception
            or $visibility
            or defined $info) {
            $log->syslog('info', 'No properties to be changed');
            $self->add_stash($request, 'user', 'no_changed_properties',
                {listname => $list->{'name'}, email => $email, role => $role}
            );
            return 1;
        }
        unless (
            $list->update_list_admin(
                $email,
                $role,
                (defined $gecos ? (gecos      => $gecos)      : ()),
                ($reception     ? (reception  => $reception)  : ()),
                ($visibility    ? (visibility => $visibility) : ()),
                (defined $info  ? (info       => $info)       : ()),
                update_date => time
            )
        ) {
            $self->add_stash($request, 'intern');
            $log->syslog('info', 'SET %s %s%s from %s refused, update failed',
                $list, $reception, $visibility, $sender);
            return undef;
        }
    } else {
        unless (defined $gecos
            or $reception
            or $visibility
            or defined $info
            or $profile) {
            $log->syslog('info', 'No properties to be changed');
            $self->add_stash($request, 'user', 'no_changed_properties',
                {listname => $list->{'name'}, email => $email, role => $role}
            );
            return 1;
        }
        unless (
            $list->update_list_admin(
                $email,
                $role,
                (defined $gecos ? (gecos      => $gecos)      : ()),
                ($reception     ? (reception  => $reception)  : ()),
                ($visibility    ? (visibility => $visibility) : ()),
                (defined $info  ? (info       => $info)       : ()),
                ($profile       ? (profile    => $profile)    : ()),
                update_date => time
            )
        ) {
            $self->add_stash($request, 'intern');
            $log->syslog('info', 'SET %s %s%s from %s refused, update failed',
                $list, $reception, $visibility, $sender);
            return undef;
        }
    }

    $self->add_stash($request, 'notice', 'config_updated');
    $log->syslog('info', 'SET %s from %s accepted (%.2f seconds)',
        $list, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::set - set request handler

=head1 DESCRIPTION

Change subscription options (reception or visibility).

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
