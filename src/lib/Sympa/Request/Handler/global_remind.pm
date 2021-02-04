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

package Sympa::Request::Handler::global_remind;

use strict;
use warnings;

use Sympa;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::User;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'global_remind';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;

# Old name: (part of) Sympa::Commands::remind().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $sender = $request->{sender};

    my ($list, $listname, $robot);

    $listname = '*';
    $robot    = $request->{context};

    my %global_subscription;
    my %global_info;
    my $count = 0;
    my %context;

    $context{'subject'} = $language->gettext("Subscription summary");

    my $auth_method =
          $request->{smime_signed} ? 'smime'
        : $request->{md5_check}    ? 'md5'
        : $request->{dkim_pass}    ? 'dkim'
        :                            'smtp';

    # This remind is a global remind.
    foreach my $list (@{Sympa::List::get_lists($robot) || []}) {
        my $listname = $list->{'name'};
        my $user;
        next unless ($user = $list->get_first_list_member());

        do {
            my $email = lc($user->{'email'});
            my $result =
                Sympa::Scenario->new($list, 'visibility')
                ->authz($auth_method, $self->{scenario_context});
            my $action;
            $action = $result->{'action'} if ref $result eq 'HASH';

            unless (defined $action) {
                my $error =
                    "Unable to evaluate scenario 'visibility' for list $listname";
                Sympa::send_notify_to_listmaster(
                    $list,
                    'intern_error',
                    {   'error'  => $error,
                        'who'    => $sender,
                        'cmd'    => $request->{cmd_line},
                        'action' => 'Command process'
                    }
                );
                next;
            }

            if ($action eq 'do_it') {
                push @{$global_subscription{$email}}, $listname;

                $user->{'lang'} ||= $list->{'admin'}{'lang'};

                $global_info{$email} = $user;

                $log->syslog('debug2', 'REMIND *: %s subscriber of %s',
                    $email, $listname);
                $count++;
            }
        } while ($user = $list->get_next_list_member());
    }
    unless (%global_subscription) {
        $self->add_stash($request, 'user', 'no_lists');
        $log->syslog('info', 'REMIND * from %s refused, no lists to proceess',
            $sender);
        return undef;
    }

    foreach my $email (keys %global_subscription) {
        my $user = Sympa::User::get_global_user($email);
        foreach my $key (keys %{$user}) {
            $global_info{$email}{$key} = $user->{$key}
                if ($user->{$key});
        }

        $context{'user'}{'email'}    = $email;
        $context{'user'}{'lang'}     = $global_info{$email}{'lang'};
        $context{'user'}{'password'} = $global_info{$email}{'password'};
        $context{'user'}{'gecos'}    = $global_info{$email}{'gecos'};
        @{$context{'lists'}} = @{$global_subscription{$email}};

        #FIXME: needs VERP?
        unless (Sympa::send_file($robot, 'global_remind', $email, \%context))
        {
            $log->syslog('notice',
                'Unable to send template "global_remind" to %s', $email);
            $self->add_stash($request, 'intern');
        }
    }
    $self->add_stash($request, 'notice', 'glob_remind', {'count' => $count});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::global_remind - global 'remind' request handler

=head1 DESCRIPTION

Sends a personal reminder to each subscriber
of every list using template 'global_remind'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
