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

package Sympa::Request::Handler::subscribe;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::Password;
use Sympa::User;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Subscribes a user to a list. The user sent a subscribe
# command. Format was : sub list optionnal comment. User can
# be informed by template 'welcome'.
# Old name: Sympa::Commands::subscribe().
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
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $sender  = $request->{sender};
    my $email   = $request->{email};
    my $comment = $request->{gecos};

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

    # Unless rejected by scenario, don't go further if the user is subscribed
    # already.
    my $user_entry = $list->get_list_member($email);
    if (defined $user_entry) {
        $self->add_stash($request, 'user', 'already_subscriber',
            {'email' => $email});
        $log->syslog(
            'err',
            'User %s is subscribed to %s already. Ignoring subscription request',
            $email,
            $list
        );
        return undef;
    }

    my $u;
    my $defaults = $list->get_default_user_options();
    %{$u} = %{$defaults};
    $u->{'email'} = $email;
    $u->{'gecos'} = $comment;
    $u->{'date'}  = $u->{'update_date'} = time;

    $list->add_list_member($u);
    if (defined $list->{'add_outcome'}{'errors'}) {
        if (defined $list->{'add_outcome'}{'errors'}
            {'max_list_members_exceeded'}) {
            $self->add_stash($request, 'user', 'max_list_members_exceeded',
                {max_list_members => $list->{'admin'}{'max_list_members'}});
        } else {
            my $error =
                sprintf 'Unable to add user %s in list %s : %s',
                $u, $list->get_id,
                $list->{'add_outcome'}{'errors'}{'error_message'};
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
        }
        return undef;
    }

    my $user = Sympa::User->new($email);
    $user->lang($list->{'admin'}{'lang'}) unless $user->lang;
    $user->password(Sympa::Tools::Password::tmp_passwd($email))
        unless $user->password;
    $user->save;

    ## Now send the welcome file to the user
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
