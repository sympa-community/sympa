# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2021 The Sympa Community. See the
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

package Sympa::Request::Handler::add;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::Domains;
use Sympa::Tools::Password;
use Sympa::Tools::Text;
use Sympa::User;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'add';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::add().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list    = $request->{context};
    my $sender  = $request->{sender};
    my $email   = $request->{email};
    my $comment = $request->{gecos};
    my $role    = $request->{role} || 'member';
    my $ca      = $request->{custom_attribute};

    die 'bug in logic. Ask developer'
        unless grep { $role eq $_ } qw(member owner editor);

    $language->set_lang($list->{'admin'}{'lang'});

    unless (Sympa::Tools::Text::valid_email($email)) {
        $self->add_stash($request, 'user', 'incorrect_email',
            {'email' => $email});
        $log->syslog('err',
            'request "add" rejected; incorrect email "%s"', $email);
        return undef;
    }

    my @stash;
    if ($role eq 'member') {
        unless ($request->{force} or $list->is_subscription_allowed) {
            $log->syslog('info', 'List %s not open', $list);
            $self->add_stash($request, 'user', 'list_not_open',
                {'status' => $list->{'admin'}{'status'}});
            $self->{finish} = 1;
            return undef;
        }
        if (Sympa::Tools::Domains::is_blocklisted($email)) {
            $self->add_stash($request, 'user', 'blocklisted_domain',
                {'email' => $email});
            $log->syslog('err',
                'request "add" rejected; blocklisted domain for "%s"',
                $email);
            return undef;
        }

        $list->add_list_member(
            {email => $email, gecos => $comment, custom_attribute => $ca},
            stash => \@stash);
    } else {
        $list->add_list_admin(
            $role,
            {email => $email, gecos => $comment},
            stash => \@stash
        );
    }
    foreach my $report (@stash) {
        $self->add_stash($request, @$report);
        if ($report->[0] eq 'intern') {
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $report->[1],      #FIXME: Update listmaster tt2
                    who    => $sender,
                    action => 'Command process',
                }
            );
        }
    }
    return undef if grep { $_->[0] eq 'user' or $_->[0] eq 'intern' } @stash;

    if ($role eq 'member') {
        _report_member($self, $request);
    } else {
        _report_user($self, $request);
    }

    return 1;
}

sub _report_member {
    my $self    = shift;
    my $request = shift;

    my $list    = $request->{context};
    my $sender  = $request->{sender};
    my $email   = $request->{email};
    my $comment = $request->{gecos};

    $self->add_stash($request, 'notice', 'now_subscriber',
        {'email' => $email, listname => $list->{'name'}});

    # FIXME: Required?
    my $user = Sympa::User->new($email);
    $user->lang($list->{'admin'}{'lang'}) unless $user->lang;
    $user->save;

    ## Now send the welcome file to the user if it exists and notification
    ## is supposed to be sent.
    $request->{quiet} = ($Conf::Conf{'quiet_subscription'} eq "on")
        if $Conf::Conf{'quiet_subscription'} ne "optional";
    unless ($request->{quiet}) {
        unless ($list->send_probe_to_user('welcome', $email)) {
            $log->syslog('notice', 'Unable to send "welcome" probe to %s',
                $email);
        }
    }

    $log->syslog(
        'info',
        'ADD %s %s from %s accepted (%.2f seconds, %d subscribers)',
        $list->{'name'},
        $email,
        $sender,
        Time::HiRes::time() - $self->{start_time},
        $list->get_total()
    );
    if ($request->{notify}) {
        $list->send_notify_to_owner(
            'notice',
            {   'who'     => $email,
                'gecos'   => $comment,
                'command' => 'add',
                'by'      => $sender
            }
        );
    }
}

sub _report_user {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $role   = $request->{role};
    my $email  = $request->{email};
    my $sender = $request->{sender};

    # Notify the new list owner/editor
    unless ($request->{quiet}) {
        Sympa::send_notify_to_user($list, 'added_as_listadmin', $email,
            {admin_type => $role, delegator => $sender});
        $self->add_stash($request, 'notice', 'user_notified',
            {'notified_user' => $email});
    }

    $log->syslog(
        'info',
        'request "add" %s %s to %s from %s accepted (%.2f seconds)',
        $role,
        $email,
        $list,
        $sender,
        Time::HiRes::time() - $self->{start_time}
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::add - add request handler

=head1 DESCRIPTION

Adds a user to a list (requested by another user). Verifies
the proper authorization and sends acknowledgements unless
quiet add has been chosen (which requires the
quiet_subscription setting to be "optional") or forced (which
requires the quiet_subscription setting to be "on").

B<Note>:
The autharization secenario C<add.*> is applicable only when the {role}
attribute is C<'member'> (default).
In the other cases the scenario processing should be skipped.

=head2 Attributes

See also L<Sympa::Request/"Attributes">.

=over

=item {email}

I<Mandatory>.
E-mail of the user to be added.

=item {force}

I<Optional>.
If true value is specified,
users will be added even if the list is closed.

=item {gecos}

I<Optional>.
Display name of the user to be added.

=item {role}

I<Optional>.
Role of the user to be added: C<'member'>, C<'owner'> or C<'editor'>.
Default value is C<'member'>.

This attribute was introduced on Sympa 6.2.67b.2.

=item {quiet}

I<Optional>.
Don't notify addition to the user.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
