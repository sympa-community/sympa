# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2019, 2021 The Sympa Community. See the
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

package Sympa::Request::Handler::subscribe;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::User;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'subscribe';
use constant _action_regexp   => qr'reject|request_auth|owner|do_it'i;
use constant _context_class   => 'Sympa::List';
use constant _owner_action    => 'add';

# Old name: Sympa::Commands::subscribe().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $sender  = $request->{sender};
    my $email   = $request->{email};
    my $comment = $request->{gecos};
    my $ca      = $request->{custom_attribute};

    $language->set_lang($list->{'admin'}{'lang'});

    # This is a really minimalistic handling of the comments,
    # it is far away from RFC-822 completeness.
    #FIXME: Needed?
    if (defined $comment and $comment =~ /\S/) {
        $comment =~ s/"/\\"/g;
        $comment = "\"$comment\"" if ($comment =~ /[<>\(\)]/);
    } else {
        undef $comment;
    }

    # If a list is not 'open' and allow_subscribe_if_pending has been set to
    # 'off' returns undef.
    unless ($list->is_subscription_allowed) {
        $log->syslog('info', 'List %s not open', $list);
        $self->add_stash($request, 'user', 'list_not_open',
            {status => $list->{'admin'}{'status'}});
        $self->{finish} = 1;
        return undef;
    }

    my @stash;
    $list->add_list_member(
        {email => $email, gecos => $comment, ($ca ? (attrib => $ca) : ())},
        stash => \@stash);
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

    my $user = Sympa::User->new($email);
    $user->lang($list->{'admin'}{'lang'}) unless $user->lang;
    $user->save;

    ## Now send the welcome file to the user
    $request->{quiet} = ($Conf::Conf{'quiet_subscription'} eq "on")
        if $Conf::Conf{'quiet_subscription'} ne "optional";
    unless ($request->{quiet}) {
        unless ($list->send_probe_to_user('welcome', $email)) {
            $log->syslog('notice', 'Unable to send "welcome" probe to %s',
                $email);
        }
    }

    ## If requested send notification to owners
    if ($request->{notify}) {
        $list->send_notify_to_owner(
            'notice',
            {   'who'     => $email,
                'gecos'   => $comment,
                'command' => 'subscribe'
            }
        );
    }
    $log->syslog(
        'info',
        'SUB %s from %s accepted (%.2f seconds, %d subscribers)',
        $which,
        $sender,
        Time::HiRes::time() - $self->{start_time},
        $list->get_total()
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::subscribe - subscribe request handler

=head1 DESCRIPTION

Subscribes a user to a list. The user sent a subscribe command.
User can be informed by template 'welcome'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
