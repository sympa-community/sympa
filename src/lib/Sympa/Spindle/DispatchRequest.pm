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

package Sympa::Spindle::DispatchRequest;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Archive;
use Conf;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Spindle::ProcessHeld;
use Sympa::Spindle::ProcessModeration;
use Sympa::Spool::Moderation;
use Sympa::Spool::Request;
use Sympa::Tools::Password;
use Sympa::User;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Use {start_time} attribute of spindle.
#my $time_command;

# Moved to: Sympa::Request::Message::_parse().
#sub parse;

# Old name: (part of) Sympa::Commands::parse().
sub _twist {
    my $self    = shift;
    my $request = shift;

    return _error($self, $request) if $request->{error};

    my $action = __PACKAGE__ . '::' . $request->{action};
    no strict 'refs';
    return $self->$action($request);
}

##############################################
#  error
#
#  Pseudo-request to report error.
##############################################
sub _error {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $robot =
        (ref $request->{context} eq 'Sympa::List')
        ? $request->{context}->{'domain'}
        : ($request->{context} || '*');
    my $entry = $request->{error};

    if ($entry eq 'syntax_error') {
        $self->add_stash($request, 'user', 'error_syntax');
        $log->syslog('notice', 'Command syntax error');
    } elsif ($entry eq 'unknown_list') {
        $self->add_stash($request, 'user', 'no_existing_list',
            {'listname' => $request->{localpart}});
        $log->syslog(
            'info',
            '%s from %s refused, unknown list for robot %s',
            uc $request->{action},
            $request->{sender}, $robot
        );
    } else {
        Sympa::send_notify_to_listmaster(
            $request->{context},
            'mail_intern_error',
            {   error  => $entry,
                who    => $request->{sender},
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        $log->syslog('err', 'Unknown error: %s', $entry);
        return undef;
    }
    return 1;
}

# Old name: Sympa::Commands::unknown().
sub unknown {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $robot =
        (ref $request->{context} eq 'Sympa::List')
        ? $request->{context}->{'domain'}
        : ($request->{context} || '*');

    $log->syslog('notice', 'Unknown command found: %s', $request->{cmd_line});
    $self->add_stash($request, 'user', 'not_understood');
    $log->db_log(
        'robot' => $robot,
        #'list'         => 'sympa',
        'action'       => 'DoCommand',
        'parameters'   => $message->get_id,
        'target_email' => '',
        'msg_id'       => $message->{message_id},
        'status'       => 'error',
        'error_type'   => 'not_understood',
        'user_email'   => $request->{sender},
    );
    return undef;
}

##############################################
#  finished
##############################################
#  Do not process what is after this line
#
# IN : -
#
# OUT : 1
#
################################################
# Old name: Sympa::Commands::finished().
sub finished {
    my $self    = shift;
    my $request = shift;

    $self->add_stash($request, 'notice', 'finished');
    return 1;
}

##############################################
#  help
##############################################
#  Sends the help file for the software
#
# IN : - ?
#      -$robot (+): robot
#
# OUT : 1 | undef
#
##############################################
# Old name: Sympa::Commands::help().
sub help {
    my $self    = shift;
    my $request = shift;

    my $robot  = $request->{context};
    my $sender = $request->{sender};

    my $data = {};

    my @owner  = Sympa::List::get_which($sender, $robot, 'owner');
    my @editor = Sympa::List::get_which($sender, $robot, 'editor');

    $data->{'is_owner'}  = 1 if @owner;
    $data->{'is_editor'} = 1 if @editor;
    $data->{'user'}      = Sympa::User->new($sender);
    $language->set_lang($data->{'user'}->lang)
        if $data->{'user'}->lang;
    $data->{'subject'}        = $language->gettext("User guide");
    $data->{'auto_submitted'} = 'auto-replied';

    unless (Sympa::send_file($robot, "helpfile", $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "helpfile" to %s',
            $sender);
        $self->add_stash($request, 'intern');
    }

    $log->syslog(
        'info',  'HELP from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

#####################################################
#  lists
#####################################################
#  Sends back the list of public lists on this node.
#
# IN : - ?
#      -$robot (+): robot
#
# OUT : 1  | undef
#
#######################################################
# Old name: Sympa::Commands::lists().
sub lists {
    my $self    = shift;
    my $request = shift;

    my $robot   = $request->{context};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $data  = {};
    my $lists = {};

    my $all_lists = Sympa::List::get_lists($robot);

    foreach my $list (@$all_lists) {
        my $result = Sympa::Scenario::request_action(
            $list, 'visibility', 'smtp',    # 'smtp' isn't it a bug ?
            {   'sender'  => $sender,
                'message' => $message,
            }
        );

        my $action;
        $action = $result->{'action'} if (ref($result) eq 'HASH');

        unless (defined $action) {
            my $error =
                sprintf
                'Unable to evaluate scenario "visibility" for list %s',
                $list->get_id;
            Sympa::send_notify_to_listmaster(
                $list,
                'intern_error',
                {   'error'          => $error,
                    'who'            => $sender,
                    'cmd'            => $request->{cmd_line},
                    'action'         => 'Command process',
                    'auto_submitted' => 'auto-replied'
                }
            );
            next;
        }

        if ($action eq 'do_it') {
            $lists->{$list->{'name'}}{'subject'} =
                $list->{'admin'}{'subject'};
            $lists->{$list->{'name'}}{'host'} = $list->{'admin'}{'host'};
        }
    }

    $data->{'lists'}          = $lists;
    $data->{'auto_submitted'} = 'auto-replied';

    unless (Sympa::send_file($robot, 'lists', $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "lists" to %s',
            $sender);
        $self->add_stash($request, 'intern');
    }

    $log->syslog(
        'info',  'LISTS from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

#####################################################
#  stats
#####################################################
#  Sends the statistics about a list using template
#  'stats_report'
#
# OUT : 'unknown_list'|'not_allowed'|1  | undef
#
#######################################################
# Old name: Sympa::Commands::stats().
sub stats {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $message  = $request->{message};
    my $sender   = $request->{sender};

        my %stats = (
            'msg_rcv'  => $list->{'stats'}[0],
            'msg_sent' => $list->{'stats'}[1],
            'byte_rcv' =>
                sprintf('%9.2f', ($list->{'stats'}[2] / 1024 / 1024)),
            'byte_sent' =>
                sprintf('%9.2f', ($list->{'stats'}[3] / 1024 / 1024))
        );

        unless (
            Sympa::send_file(
                $list,
                'stats_report',
                $sender,
                {   'stats'   => \%stats,
                    'subject' => "STATS $list->{'name'}",  # compat <= 6.1.17.
                    'auto_submitted' => 'auto-replied'
                }
            )
            ) {
            $log->syslog('notice',
                'Unable to send template "stats_reports" to %s', $sender);
            $self->add_stash($request, 'intern');
        }

        $log->syslog('info', 'STATS %s from %s accepted (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $self->{start_time});
        return 1;
}

###############################################
#  get
##############################################
# Sends back the requested archive file
#
# IN : -$which (+): command parameters : listname filename
#      -$robot (+): robot
#
# OUT : 'unknownlist'|'no_archive'|'not_allowed'|1
#
###############################################
# Old name: Sympa::Commands::getfile().
sub get {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $arc = $request->{arc};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived) {
        $self->add_stash($request, 'user', 'empty_archives');
        $log->syslog('info',
            'GET %s %s from %s refused, no archive for list %s',
            $which, $arc, $sender, $which);
        return 'no_archive';
    }

    my $archive = Sympa::Archive->new(context => $list);
    my @msg_list;
    unless ($archive->select_archive($arc)) {
        $self->add_stash($request, 'user', 'no_required_file');
        $log->syslog('info', 'GET %s %s from %s, no such archive',
            $which, $arc, $sender);
        return 'no_archive';
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
        boundary1      => tools::get_message_id($list->{'domain'}),
        boundary2      => tools::get_message_id($list->{'domain'}),
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
        return 'no_archive';
    }

    $log->syslog('info', 'GET %s %s from %s accepted (%.2f seconds)',
        $which, $arc, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

###############################################
#  last
##############################################
# Sends back the last archive file
#
#
# IN : -$which (+): listname
#      -$robot (+): robot
#
# OUT : 'unknownlist'|'no_archive'|'not_allowed'|1
#
###############################################
# Old name: Sympa::Commands::last().
sub last {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        $self->add_stash($request, 'user', 'empty_archives');
        $log->syslog('info', 'LAST %s from %s refused, list not archived',
            $which, $sender);
        return 'no_archive';
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
        return 'no_archive';
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
        boundary1      => tools::get_message_id($list->{'domain'}),
        boundary2      => tools::get_message_id($list->{'domain'}),
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
        return 'no_archive';
    }

    $log->syslog('info', 'LAST %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

############################################################
#  index
############################################################
#  Sends the list of archived files of a list
#
# IN : -$which (+): list name
#      -$robot (+): robot
#
# OUT : 'unknown_list'|'not_allowed'|'no_archive'|1
#
#############################################################
# Old name: Sympa::Commands::index().
sub index {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        $self->add_stash($request, 'user', 'empty_archives');
        $log->syslog('info', 'INDEX %s from %s refused, list not archived',
            $which, $sender);
        return 'no_archive';
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
    }

    $log->syslog('info', 'INDEX %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

############################################################
#  review
############################################################
#  Sends the list of subscribers to the requester.
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       |'no_subscribers'|1 | undef
#
################################################################
# Old name: Sympa::Commands::review().
sub review {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $message  = $request->{message};
    my $sender   = $request->{sender};

    my $user;

    $language->set_lang($list->{'admin'}{'lang'});

    unless (defined $list->on_the_fly_sync_include(use_ttl => 1)) {
        $log->syslog('notice', 'Unable to synchronize list %s', $list);
        #FIXME: Abort if synchronization failed.
    }

    my @users;

        my $is_owner = $list->is_admin('owner', $sender)
            || Sympa::is_listmaster($list, $sender);
        unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
            $self->add_stash($request, 'user', 'no_subscriber');
            $log->syslog('err', 'No subscribers in list "%s"',
                $list->{'name'});
            return 'no_subscribers';
        }
        do {
            ## Owners bypass the visibility option
            unless (($user->{'visibility'} eq 'conceal')
                and (!$is_owner)) {

                ## Lower case email address
                $user->{'email'} =~ y/A-Z/a-z/;
                push @users, $user;
            }
        } while ($user = $list->get_next_list_member());
        unless (
            Sympa::send_file(
                $list, 'review', $sender,
                {   'users'   => \@users,
                    'total'   => $list->get_total(),
                    'subject' => "REVIEW $listname",    # Compat <= 6.1.17.
                    'auto_submitted' => 'auto-replied'
                }
            )
            ) {
            $log->syslog('notice', 'Unable to send template "review" to %s',
                $sender);
            $self->add_stash($request, 'intern');
        }

        $log->syslog('info', 'REVIEW %s from %s accepted (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $self->{start_time});
        return 1;
}

############################################################
#  verify
############################################################
#  Verify an S/MIME signature
#
# OUT : 1
#
#############################################################
# Old name: Sympa::Commands::verify().
sub verify {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sign_mod = $request->{sign_mod};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    if ($sign_mod) {
        $log->syslog(
            'info',  'VERIFY successful from %s (%.2f seconds)',
            $sender, Time::HiRes::time() - $self->{start_time}
        );
        if ($sign_mod eq 'smime') {
            ##$auth_method='smime';
            $self->add_stash($request, 'notice', 'smime');
        } elsif ($sign_mod eq 'dkim') {
            ##$auth_method='dkim';
            $self->add_stash($request, 'notice', 'dkim');
        }
    } else {
        $log->syslog(
            'info',
            'VERIFY from %s: could not find correct S/MIME signature (%.2f seconds)',
            $sender,
            Time::HiRes::time() - $self->{start_time}
        );
        $self->add_stash($request, 'user', 'no_verify_sign');
    }
    return 1;
}

##############################################################
#  subscribe
##############################################################
#  Subscribes a user to a list. The user sent a subscribe
#  command. Format was : sub list optionnal comment. User can
#  be informed by template 'welcome'
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'| 1 | undef
#
################################################################
# Old name: Sympa::Commands::subscribe().
sub subscribe {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
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
        $self->add_stash($request, 'user',
            'already_subscriber', {'email' => $email});
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
                    $self->add_stash($request, 'user',
                        'max_list_members_exceeded',
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

############################################################
#  info
############################################################
#  Sends the information file to the requester
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
##############################################################
# Old name: Sympa::Commands::info().
sub info {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $message  = $request->{message};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

        my $data;
        foreach my $key (keys %{$list->{'admin'}}) {
            $data->{$key} = $list->{'admin'}{$key};
        }

        ## Set title in the current language
        foreach my $p ('subscribe', 'unsubscribe', 'send', 'review') {
            my $scenario = Sympa::Scenario->new(
                'robot'     => $robot,
                'directory' => $list->{'dir'},
                'file_path' => $list->{'admin'}{$p}{'file_path'}
            );
            $data->{$p} = $scenario->get_current_title();
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
        $data->{'available_reception_mode'} =
            $list->available_reception_mode();
        $data->{'available_reception_modeA'} =
            [$list->available_reception_mode()];

        my $wwsympa_url =
            Conf::get_robot_conf($list->{'domain'}, 'wwsympa_url');
        $data->{'url'} = $wwsympa_url . '/info/' . $list->{'name'};

        unless (Sympa::send_file($list, 'info_report', $sender, $data)) {
            $log->syslog('notice',
                'Unable to send template "info_report" to %s', $sender);
            $self->add_stash($request, 'intern');
        }

        $log->syslog('info', 'INFO %s from %s accepted (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $self->{start_time});
        return 1;
}

##############################################################
#  signoff
##############################################################
#  Unsubscribes a user from a list. The user sent a signoff
# command. Format was : sig list. He can be informed by template 'bye'
#
# OUT : 'syntax_error'|'unknown_list'|'wrong_auth'
#       |'not_allowed'| 1 | undef
#
#
##############################################################
# Old name: (part of) Sympa::Commands::signoff().
sub global_signoff {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $email = $request->{email};

        foreach my $list (
            Sympa::List::get_which($email, $request->{context}, 'member')) {
            # Skip hidden lists.
            my $result = Sympa::Scenario::request_action(
                $list,
                'visibility',
                'smtp',
                {   'sender'  => $sender,
                    'message' => $message,
                }
            );

            my $action;
            $action = $result->{'action'} if (ref($result) eq 'HASH');

            unless (defined $action) {
                my $error =
                    sprintf
                    'Unable to evaluate scenario "visibility" for list ',
                    $list->get_id;
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

            if ($action =~ /reject/) {
                next;
            }

            my $req = $request->dup;
            $req->{action}    = 'signoff';
            $req->{context}   = $list;
            $req->{localpart} = $list->{'name'};

            $self->{distaff}->store($req);
        }
        return 1;
}

# Old name: (part of) Sympa::Commands::signoff().
sub signoff {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $email = $request->{email};

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list  = $request->{context};
    my $which = $list->{'name'};

    $language->set_lang($list->{'admin'}{'lang'});

        # Now check if we know this email on the list and
        # remove it if found, otherwise just reject the
        # command.
        my $user_entry = $list->get_list_member($email);
        unless (defined $user_entry) {
            $self->add_stash($request, 'user',
                'your_email_not_found', {'email' => $email});
            $log->syslog('info', 'SIG %s from %s refused, not on list',
                $which, $email);

            # Tell the owner somebody tried to unsubscribe.
            if ($request->{notify}) {
                # Try to find email from same domain or email with same local
                # part.
                $list->send_notify_to_owner(
                    'warn-signoff',
                    {   'who'   => $email,
                        'gecos' => ($user_entry->{'gecos'} || '')
                    }
                );
            }
            return 'not_allowed';
        }

        ## Really delete and rewrite to disk.
        unless (
            $list->delete_list_member(
                'users'     => [$email],
                'exclude'   => '1',
                'operation' => 'signoff',
            )
            ) {
            my $error = sprintf 'Unable to delete user %s from list %s',
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
        }

        # Notify the owner.
        if ($request->{notify}) {
            $list->send_notify_to_owner(
                'notice',
                {   'who'     => $email,
                    'gecos'   => ($user_entry->{'gecos'} || ''),
                    'command' => 'signoff'
                }
            );
        }

        unless ($request->{quiet}) {
            # Send bye file to subscriber.
            unless (Sympa::send_file($list, 'bye', $email, {})) {
                $log->syslog('notice', 'Unable to send template "bye" to %s',
                    $email);
            }
        }

        $log->syslog(
            'info',
            'SIG %s from %s accepted (%.2f seconds, %d subscribers)',
            $which,
            $sender,
            Time::HiRes::time() - $self->{start_time},
            $list->get_total()
        );

        return 1;
}

############################################################
#  add
############################################################
#  Adds a user to a list (requested by another user). Verifies
#  the proper authorization and sends acknowledgements unless
#  quiet add.
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
############################################################
# Old name: Sympa::Commands::add().
sub add {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $email   = $request->{email};
    my $comment = $request->{gecos};

    $language->set_lang($list->{'admin'}{'lang'});

        if ($list->is_list_member($email)) {
            $self->add_stash($request, 'user',
                'already_subscriber', {'email' => $email});
            $log->syslog(
                'err',
                'ADD command rejected; user "%s" already member of list "%s"',
                $email,
                $which
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
                    $self->add_stash($request, 'user',
                        'max_list_members_exceeded',
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

            my $spool_req = Sympa::Spool::Request->new(
                context => $list,
                email   => $email,
                action  => 'add'
            );
            while (1) {
                my ($request, $handle) = $spool_req->next;
                last unless $handle;
                next unless $request;

                $spool_req->remove($handle);
            }

            $self->add_stash($request, 'notice', 'now_subscriber',
                {'email' => $email});

        my $user = Sympa::User->new($email);
        $user->lang($list->{'admin'}{'lang'}) unless $user->lang;
        $user->password(Sympa::Tools::Password::tmp_passwd($email))
            unless $user->password;
        $user->save;

        ## Now send the welcome file to the user if it exists and notification
        ## is supposed to be sent.
        unless ($request->{quiet}) {
            unless ($list->send_probe_to_user('welcome', $email)) {
                $log->syslog('notice', 'Unable to send "welcome" probe to %s',
                    $email);
            }
        }

        $log->syslog(
            'info',
            'ADD %s %s from %s accepted (%.2f seconds, %d subscribers)',
            $which,
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
        return 1;
}

############################################################
#  invite
############################################################
#  Invite someone to subscribe a list by sending him
#  template 'invite'
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
##############################################################
# Old name: Sympa::Commands::invite().
sub invite {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $email   = $request->{email};
    my $comment = $request->{gecos};

    my $sympa = Sympa::get_address($robot, 'sympa');

    $language->set_lang($list->{'admin'}{'lang'});

        if ($list->is_list_member($email)) {
            $self->add_stash($request, 'user',
                'already_subscriber', {'email' => $email});
            $log->syslog(
                'err',
                'INVITE command rejected; user "%s" already member of list "%s"',
                $email,
                $which
            );
            return undef;
        }

            # Is the guest user allowed to subscribe in this list?

            my %context;
            $context{'user'}{'email'} = $email;
            $context{'user'}{'gecos'} = $comment;
            $context{'requested_by'}  = $sender;

            my $result = Sympa::Scenario::request_action(
                $list,
                'subscribe',
                'smtp',
                {   'sender'  => $sender,
                    'message' => $message,
                }
            );
            my $action;
            $action = $result->{'action'} if (ref($result) eq 'HASH');

            unless (defined $action) {
                my $error =
                    "Unable to evaluate scenario 'subscribe' for list $which";
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

            if ($action =~ /\Arequest_auth\b/i) {
                my $keyauth = Sympa::compute_auth(
                    context => $list,
                    email   => $email,
                    action  => 'subscribe'
                );
                my $command = "auth $keyauth sub $which $comment";
                $context{'subject'} = $command;
                $context{'url'}     = "mailto:$sympa?subject=$command";
                $context{'url'} =~ s/\s/%20/g;
                unless (Sympa::send_file($list, 'invite', $email, \%context))
                {
                    $log->syslog('notice',
                        'Unable to send template "invite" to %s', $email);
                    my $error =
                        sprintf 'Unable to send template "invite" to %s',
                        $email;
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
                $log->syslog(
                    'info',
                    'INVITE %s %s from %s accepted, auth requested (%.2f seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    Time::HiRes::time() - $self->{start_time},
                    $list->get_total()
                );
                $self->add_stash($request, 'notice', 'invite',
                    {'email' => $email});

            } elsif ($action !~ /\Areject\b/i) {
                $context{'subject'} = "sub $which $comment";
                $context{'url'} = "mailto:$sympa?subject=$context{'subject'}";
                $context{'url'} =~ s/\s/%20/g;
                unless (Sympa::send_file($list, 'invite', $email, \%context))
                {
                    $log->syslog('notice',
                        'Unable to send template "invite" to %s', $email);
                    my $error =
                        sprintf 'Unable to send template "invite" to %s',
                        $email;
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
                $log->syslog(
                    'info',
                    'INVITE %s %s from %s accepted, (%.2f seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    Time::HiRes::time() - $self->{start_time},
                    $list->get_total()
                );
                $self->add_stash($request, 'notice', 'invite',
                    {'email' => $email});

            } elsif ($action =~ /\Areject\b/i) {
                $log->syslog(
                    'info',
                    'INVITE %s %s from %s refused, not allowed (%.2f seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    Time::HiRes::time() - $self->{start_time},
                    $list->get_total()
                );
                if (defined $result->{'tt2'}) {
                    unless (
                        Sympa::send_file(
                            $list, $result->{'tt2'}, $sender, {}
                        )
                        ) {
                        $log->syslog('notice',
                            'Unable to send template "%s" to %s',
                            $result->{'tt2'}, $sender);
                        $self->add_stash($request, 'auth',
                            $result->{'reason'}, {'email' => $email});
                    }
                } else {
                    $self->add_stash($request, 'auth',
                        $result->{'reason'}, {'email' => $email});
                }
            }

        return 1;
}

############################################################
#  remind
############################################################
#  Sends a personal reminder to each subscriber of one list or
#  of every list ($which = *) using template 'remind' or
#  'global_remind'
#
# OUT : 'syntax_error'|'unknown_list'|'wrong_auth'
#       |'not_allowed' |  1 | undef
#
#
##############################################################
# Old name: (part of) Sympa::Commands::remind().
sub global_remind {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $sender  = $request->{sender};

    my ($list, $listname, $robot);

        $listname = '*';
        $robot    = $request->{context};

            my %global_subscription;
            my %global_info;
            my $count = 0;
            my %context;

            $context{'subject'} = $language->gettext("Subscription summary");
            # this remind is a global remind.

            my $all_lists = Sympa::List::get_lists($robot);
            foreach my $list (@$all_lists) {
                my $listname = $list->{'name'};
                my $user;
                next unless ($user = $list->get_first_list_member());

                do {
                    my $email  = lc($user->{'email'});
                    my $result = Sympa::Scenario::request_action(
                        $list,
                        'visibility',
                        'smtp',
                        {   'sender'  => $sender,
                            'message' => $message,
                        }
                    );
                    my $action;
                    $action = $result->{'action'} if (ref($result) eq 'HASH');

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

                        $log->syslog('debug2',
                            'REMIND *: %s subscriber of %s',
                            $email, $listname);
                        $count++;
                    }
                } while ($user = $list->get_next_list_member());
            }
            $log->syslog('debug2', 'Sending REMIND * to %d users', $count);

            foreach my $email (keys %global_subscription) {
                my $user = Sympa::User::get_global_user($email);
                foreach my $key (keys %{$user}) {
                    $global_info{$email}{$key} = $user->{$key}
                        if ($user->{$key});
                }

                $context{'user'}{'email'} = $email;
                $context{'user'}{'lang'}  = $global_info{$email}{'lang'};
                $context{'user'}{'password'} =
                    $global_info{$email}{'password'};
                $context{'user'}{'gecos'} = $global_info{$email}{'gecos'};
                @{$context{'lists'}} = @{$global_subscription{$email}};

                #FIXME: needs VERP?
                unless (
                    Sympa::send_file(
                        $robot, 'global_remind', $email, \%context
                    )
                    ) {
                    $log->syslog('notice',
                        'Unable to send template "global_remind" to %s',
                        $email);
                    $self->add_stash($request, 'intern');
                }
            }
            $self->add_stash($request, 'notice', 'glob_remind',
                {'count' => $count});
        return 1;
}

# Old name: (part of) Sympa::Commands::remind().
sub remind {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $sender  = $request->{sender};

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
        my $list     = $request->{context};
        my $listname = $list->{'name'};
        my $robot    = $list->{'domain'};

        $language->set_lang($list->{'admin'}{'lang'});

            # For each subscriber send a reminder.
            my $total = 0;
            my $user;

            unless ($user = $list->get_first_list_member()) {
                my $error = "Unable to get subscribers for list $listname";
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

            do {
                unless ($list->send_probe_to_user('remind', $user->{'email'}))
                {
                    $log->syslog('notice',
                        'Unable to send "remind" probe to %s',
                        $user->{'email'});
                    $self->add_stash($request, 'intern');
                }
                $total += 1;
            } while ($user = $list->get_next_list_member());

            $self->add_stash($request, 'notice', 'remind', {total => $total});
            $log->syslog(
                'info',
                'REMIND %s from %s accepted, sent to %d subscribers (%.2f seconds)',
                $listname,
                $sender,
                $total,
                Time::HiRes::time() - $self->{start_time}
            );

            return 1;
}

############################################################
#  del
############################################################
# Removes a user from a list (requested by another user).
# Verifies the authorization and sends acknowledgements
# unless quiet is specified.
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
##############################################################
# Old name: Sympa::Commands::del().
sub del {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    my $who = $request->{email};

    $language->set_lang($list->{'admin'}{'lang'});

        # Check if we know this email on the list and remove it. Otherwise
        # just reject the message.
        my $user_entry = $list->get_list_member($who);

        unless ((defined $user_entry)) {
            $self->add_stash($request, 'user',
                'your_email_not_found', {'email' => $who});
            $log->syslog('info', 'DEL %s %s from %s refused, not on list',
                $which, $who, $sender);
            return 'not_allowed';
        }

        # Really delete and rewrite to disk.
        my $u;
        unless (
            $u = $list->delete_list_member(
                'users'     => [$who],
                'exclude'   => ' 1',
                'operation' => 'del'
            )
            ) {
            my $error =
                "Unable to delete user $who from list $which for command 'del'";
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
        } else {
            my $spool_req = Sympa::Spool::Request->new(
                context => $list,
                email   => $who,
                action  => 'del'
            );
            while (1) {
                my ($request, $handle) = $spool_req->next;
                last unless $handle;
                next unless $request;

                $spool_req->remove($handle);
            }
        }

        ## Send a notice to the removed user, unless the owner indicated
        ## quiet del.
        unless ($request->{quiet}) {
            unless (Sympa::send_file($list, 'removed', $who, {})) {
                $log->syslog('notice',
                    'Unable to send template "removed" to %s', $who);
            }
        }
        $self->add_stash($request, 'notice', 'removed', {'email' => $who});
        $log->syslog(
            'info',
            'DEL %s %s from %s accepted (%.2f seconds, %d subscribers)',
            $which,
            $who,
            $sender,
            Time::HiRes::time() - $self->{start_time},
            $list->get_total()
        );
        if ($request->{notify}) {
            $list->send_notify_to_owner(
                'notice',
                {   'who'     => $who,
                    'gecos'   => "",
                    'command' => 'del',
                    'by'      => $sender
                }
            );
        }
        return 1;
}

############################################################
#  set
############################################################
#  Change subscription options (reception or visibility)
#
# IN : -$what (+): command parameters : listname,
#        reception mode (digest|digestplain|nomail|normal...)
#        or visibility mode(conceal|noconceal)
#      -$robot (+): robot
#
# OUT : 'syntax_error'|'unknown_list'|'not_allowed'|'failed'|1
#
#
#############################################################
# Old name: (part of) Sympa::Commands::set().
sub global_set {
    my $self    = shift;
    my $request = shift;

    my $message = $request->{message};
    my $sender  = $request->{sender};
    my $mode    = $request->{mode};

    # Recursive call to subroutine.
        foreach my $list (
            Sympa::List::get_which($sender, $request->{context}, 'member')) {
            # Skip hidden lists.
            my $result = Sympa::Scenario::request_action(
                $list,
                'visibility',
                'smtp',
                {   'sender'  => $sender,
                    'message' => $message,
                }
            );

            my $action;
            $action = $result->{'action'} if (ref($result) eq 'HASH');

            unless (defined $action) {
                my $error =
                    sprintf
                    'Unable to evaluate scenario "visibility" for list %s',
                    $list->get_id;
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

            if ($action =~ /reject/) {
                next;
            }

            my $req = $request->dup;
            $req->{action}    = 'set';
            $req->{context}   = $list;
            $req->{localpart} = $list->{'name'};

            $self->{distaff}->store($req);
        }
        return 1;
}

# Old name: (part of) Sympa::Commands::set().
sub set {
    my $self    = shift;
    my $request = shift;

    my $sender  = $request->{sender};
    my $mode    = $request->{mode};

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list  = $request->{context};
    my $which = $list->{'name'};

    $language->set_lang($list->{'admin'}{'lang'});

    ## Check if we know this email on the list and remove it. Otherwise
    ## just reject the message.
    unless ($list->is_list_member($sender)) {
        $self->add_stash($request, 'user', 'email_not_found',
            {'email' => $sender});
        $log->syslog('info', 'SET %s %s from %s refused, not on list',
            $which, $mode, $sender);
        return 'not allowed';
    }

    ## May set to DIGEST
    if ($mode =~ /^(digest|digestplain|summary)/ and !$list->is_digest()) {
        $self->add_stash($request, 'user', 'no_digest');
        $log->syslog('info', 'SET %s DIGEST from %s refused, no digest mode',
            $which, $sender);
        return 'not_allowed';
    }

    if ($mode =~
        /^(mail|nomail|digest|digestplain|summary|notice|txt|html|urlize|not_me)/
        ) {
        # Verify that the mode is allowed
        if (!$list->is_available_reception_mode($mode)) {
            $self->add_stash( $request, 'user',
                'available_reception_mode',
                {   'modes' => join(' ', $list->available_reception_mode()),
                    'reception_modes' => [$list->available_reception_mode()]
                }
            );
            $log->syslog('info',
                'SET %s %s from %s refused, mode not available',
                $which, $mode, $sender);
            return 'not_allowed';
        }

        my $update_mode = $mode;
        $update_mode = '' if $update_mode eq 'mail';
        unless (
            $list->update_list_member(
                $sender,
                reception   => $update_mode,
                update_date => time
            )
            ) {
            my $error =
                "Failed to change subscriber '$sender' options for list $which";
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
            $log->syslog('info', 'SET %s %s from %s refused, update failed',
                $which, $mode, $sender);
            return 'failed';
        }

        $self->add_stash($request, 'notice', 'config_updated');

        $log->syslog('info', 'SET %s %s from %s accepted (%.2f seconds)',
            $which, $mode, $sender, Time::HiRes::time() - $self->{start_time});
    }

    if ($mode =~ /^(conceal|noconceal)/) {
        unless (
            $list->update_list_member(
                $sender,
                visibility  => $mode,
                update_date => time
            )
            ) {
            my $error =
                "Failed to change subscriber '$sender' options for list $which";
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
            $log->syslog('info', 'SET %s %s from %s refused, update failed',
                $which, $mode, $sender);
            return 'failed';
        }

        $self->add_stash($request, 'notice', 'config_updated');
        $log->syslog('info', 'SET %s %s from %s accepted (%.2f seconds)',
            $which, $mode, $sender, Time::HiRes::time() - $self->{start_time});
    }
    return 1;
}

############################################################
#  distribute
############################################################
#  distributes the broadcast of a validated moderated message
#
# IN : -$what (+): command parameters : listname(+), authentication key(+)
#      -$robot (+): robot
#
# OUT : 'unknown_list'|'msg_noty_found'| 1 | undef
#
##############################################################
# Old name: Sympa::Commands::distribute().
sub distribute {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    my $key = $request->{authkey};

    my $spindle = Sympa::Spindle::ProcessModeration->new(
        distributed_by => $sender,
        context        => $robot,
        authkey        => $key,
        quiet          => $request->{quiet}
    );

    unless ($spindle and $spindle->spin) {    # No message.
        $log->syslog('err',
            'Unable to find message with key <%s> for list %s',
            $key, $list);
        $self->add_stash($request, 'user', 'unfound_message', {key => $key});
        return 'msg_not_found';
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info',
            'DISTRIBUTE %s %s from %s accepted (%.2f seconds)',
            $list->{'name'}, $key, $sender,
            Time::HiRes::time() - $self->{start_time});
        return 1;
    } else {
        return undef;
    }
}

############################################################
#  confirm
############################################################
#  confirms the authentication of a message for its
#  distribution on a list
#
# IN : -$what (+): command parameter : authentication key
#      -$robot (+): robot
#
# OUT : 'wrong_auth'|'msg_not_found'
#       | 1  | undef
#
#
############################################################
# Old name: Sympa::Commands::confirm().
sub confirm {
    my $self    = shift;
    my $request = shift;

    my $robot  = $request->{context};
    my $sender = $request->{sender};

    my $key = $request->{authkey};

    my $spindle = Sympa::Spindle::ProcessHeld->new(
        confirmed_by => $sender,
        context      => $robot,
        authkey      => $key,
        quiet        => $request->{quiet}
    );

    unless ($spindle and $spindle->spin) {    # No message.
        $log->syslog('info', 'CONFIRM %s from %s refused, auth failed',
            $key, $sender);
        $self->add_stash($request, 'user',
            'unfound_file_message', {'key' => $key});
        return 'wrong_auth';
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info', 'CONFIRM %s from %s accepted (%.2f seconds)',
            $key, $sender, Time::HiRes::time() - $self->{start_time});
        return 1;
    } else {
        return undef;
    }
}

############################################################
#  reject
############################################################
#  Refuse and delete  a moderated message and notify sender
#  by sending template 'reject'
#
# IN : -$what (+): command parameter : listname and authentication key
#      -$robot (+): robot
#
# OUT : 'unknown_list'|'wrong_auth'| 1 | undef
#
#
##############################################################
# Old name: Sympa::Commands::reject().
sub reject {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    my $key = $request->{authkey};

    my $spindle = Sympa::Spindle::ProcessModeration->new(
        rejected_by => $sender,
        context     => $list,
        authkey     => $key,
        quiet       => $request->{quiet}
    );

    unless ($spindle and $spindle->spin) {    # No message
        $log->syslog('info', 'REJECT %s %s from %s refused, auth failed',
            $list->{'name'}, $key, $sender);
        $self->add_stash($request, 'user', 'unfound_message', {key => $key});
        return 'wrong_auth';
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info', 'REJECT %s %s from %s accepted (%.2f seconds)',
            $list->{'name'}, $key, $sender,
            Time::HiRes::time() - $self->{start_time});
        return 1;
    } else {
        return undef;
    }
}

#########################################################
#  modindex
#########################################################
#  Sends a list of current messages to moderate of a list
#  (look into moderation spool)
#  usage :    modindex <list>
#
# IN : -$name (+): listname
#      -$robot (+): robot
#
# OUT : 'unknown_list'|'not_allowed'|'no_file'|1
#
#########################################################
# Old name: Sympa::Commands::modindex().
sub modindex {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return _error($self, $request);
    }
    my $list   = $request->{context};
    my $name   = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_admin('actual_editor', $sender)) {
        $self->add_stash($request, 'auth', 'restricted_modindex');
        $log->syslog('info', 'MODINDEX %s from %s refused, not allowed',
            $name, $sender);
        return 'not_allowed';
    }

    my $spool_mod = Sympa::Spool::Moderation->new(context => $list);
    my @now = localtime(time);

    # List of messages
    my @spool;

    while (1) {
        my ($message, $handle) = $spool_mod->next(no_lock => 1);
        last unless $handle;
        next unless $message and not $message->{validated};
        # Skip message already marked to be distributed using WWSympa.

        # Push message for building MODINDEX
        push @spool, $message->as_string;
    }

    unless (scalar @spool) {
        $self->add_stash($request, 'notice', 'no_message_to_moderate');
        $log->syslog('info',
            'MODINDEX %s from %s refused, no message to moderate',
            $name, $sender);
        return 'no_file';
    }

    unless (
        Sympa::send_file(
            $list,
            'modindex',
            $sender,
            {   'spool' => \@spool,          #FIXME: Use msg_list.
                'total' => scalar(@spool),
                'boundary1' => "==main $now[6].$now[5].$now[4].$now[3]==",
                'boundary2' => "==digest $now[6].$now[5].$now[4].$now[3]=="
            }
        )
        ) {
        $log->syslog('notice', 'Unable to send template "modindex" to %s',
            $sender);
        $self->add_stash($request, 'intern');
    }

    $log->syslog('info', 'MODINDEX %s from %s accepted (%.2f seconds)',
        $name, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

#########################################################
#  which
#########################################################
#  Return list of lists that sender is subscribed. If he is
#  owner and/or editor, managed lists are also noticed.
#
# IN : - : ?
#      -$robot (+): robot
#
# OUT : 1
#
#########################################################
# Old name: Sympa::Commands::which().
sub which {
    my $self    = shift;
    my $request = shift;

    my $robot   = $request->{context};
    my $message = $request->{message};
    my $sender  = $request->{sender};

    my ($listname, @which);

    ## Subscriptions
    my $data;
    foreach my $list (Sympa::List::get_which($sender, $robot, 'member')) {
        ## wwsympa :  my $list = Sympa::List->new($l);
        ##            next unless (defined $list);
        $listname = $list->{'name'};

        my $result = Sympa::Scenario::request_action(
            $list,
            'visibility',
            'smtp',
            {   'sender'  => $sender,
                'message' => $message,
            }
        );

        my $action;
        $action = $result->{'action'} if (ref($result) eq 'HASH');

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

        next unless ($action =~ /do_it/);

        push @{$data->{'lists'}}, $listname;
    }

    ## Ownership
    if (@which = Sympa::List::get_which($sender, $robot, 'owner')) {
        foreach my $list (@which) {
            push @{$data->{'owner_lists'}}, $list->{'name'};
        }
        $data->{'is_owner'} = 1;
    }

    ## Editorship
    if (@which = Sympa::List::get_which($sender, $robot, 'editor')) {
        foreach my $list (@which) {
            push @{$data->{'editor_lists'}}, $list->{'name'};
        }
        $data->{'is_editor'} = 1;
    }

    unless (Sympa::send_file($robot, 'which', $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "which" to %s',
            $sender);
        $self->add_stash($request, 'intern');
    }

    $log->syslog(
        'info',  'WHICH from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

# Old name: Sympa::Commands::get_auth_method().
# Moved to: Sympa::Spindle::AuthorizeRequest::_get_auth_method().
#sub get_auth_method;

1;
