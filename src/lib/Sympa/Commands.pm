# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Commands;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Archive;
use Conf;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Report;
use Sympa::Request;
use Sympa::Scenario;
use Sympa::Spindle::ProcessHeld;
use Sympa::Spindle::ProcessModeration;
use Sympa::Spool::Moderation;
use Sympa::Spool::Request;
use Sympa::Tools::Password;
use Sympa::User;

my %comms = (
    'add'                               => 'add',
    'con|confirm'                       => 'confirm',
    'del|delete'                        => 'del',
    'dis|distribute'                    => 'distribute',
    'get'                               => 'getfile',
    'hel|help|sos'                      => 'help',
    'inf|info'                          => 'info',
    'inv|invite'                        => 'invite',
    'ind|index'                         => 'index',
    'las|last'                          => 'last',
    'lis|lists?'                        => 'lists',
    'mod|modindex|modind'               => 'modindex',
    'qui|quit|end|stop|-'               => 'finished',
    'rej|reject'                        => 'reject',
    'rem|remind'                        => 'remind',
    'rev|review|who'                    => 'review',
    'set'                               => 'set',
    'sub|subscribe'                     => 'subscribe',
    'sig|signoff|uns|unsub|unsubscribe' => 'signoff',
    'sta|stats'                         => 'stats',
    'ver|verify'                        => 'verify',
    'whi|which|status'                  => 'which'
);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# command sender
my $sender = '';
# time of the process command
my $time_command;
## my $msg_file;
# command line to process
my $cmd_line;
# key authentication if 'auth' is present in the command line
my $auth;
# boolean says if quiet is in the cmd line
my $quiet;

##############################################
#  parse
##############################################
# Parses the command and calls the adequate
# subroutine with the arguments to the command.
#
# IN :-$sender (+): the command sender
#     -$robot (+): robot
#     -$i (+): command line
#     -$sign_mod : 'smime'| 'dkim' -
#
# OUT : $status |'unknown_cmd'
#
##############################################
sub parse {
    $log->syslog('debug2', '(%s, %s, %s, %s, %s)', @_);
    $sender = lc(shift);    #FIXME: eliminate module-global variable.
    my $robot    = shift;
    my $i        = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my $j;
    $cmd_line = '';

    $log->syslog('notice', "Parsing: %s", $i);

    ## allow reply usage for auth process based on user mail replies
    if ($i =~ /auth\s+(\S+)\s+(.+)$/io) {
        $auth = $1;
        $i    = $2;
    } else {
        $auth = '';
    }

    if ($i =~ /^quiet\s+(.+)$/i) {
        $i     = $1;
        $quiet = 1;
    } else {
        $quiet = 0;
    }

    foreach $j (keys %comms) {
        if ($i =~ /^($j)(\s+(.+))?\s*$/i) {
            no strict 'refs';

            $time_command = Time::HiRes::time();
            my $args = $3;
            if ($args and length $args) {
                $args =~ s/^\s*//;
                $args =~ s/\s*$//;
            }

            my $status;
            $cmd_line = $i;
            $status = $comms{$j}->($args, $robot, $sign_mod, $message);

            return $status;
        }
    }

    ## Unknown command
    return 'unknown_cmd';
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
sub finished {
    $log->syslog('debug2', '');

    Sympa::Report::notice_report_cmd('finished', {}, $cmd_line);
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
sub help {
    $log->syslog('debug2', '(%s, %s)', @_);
    shift;
    my $robot = shift;

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
        Sympa::Report::reject_report_cmd('intern_quiet', '', {}, $cmd_line,
            $sender, $robot);
    }

    $log->syslog(
        'info',  'HELP from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $time_command
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
sub lists {
    shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', 'For robot %s, sign_mod %, message %s',
        $robot, $sign_mod, $message);

    my $data  = {};
    my $lists = {};

    my $all_lists = Sympa::List::get_lists($robot);

    foreach my $list (@$all_lists) {
        my $l = $list->{'name'};

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
                "Unable to evaluate scenario 'visibility' for list $l";
            Sympa::send_notify_to_listmaster(
                $list,
                'intern_error',
                {   'error'          => $error,
                    'who'            => $sender,
                    'cmd'            => $cmd_line,
                    'action'         => 'Command process',
                    'auto_submitted' => 'auto-replied'
                }
            );
            next;
        }

        if ($action eq 'do_it') {
            $lists->{$l}{'subject'} = $list->{'admin'}{'subject'};
            $lists->{$l}{'host'}    = $list->{'admin'}{'host'};
        }
    }

    $data->{'lists'}          = $lists;
    $data->{'auto_submitted'} = 'auto-replied';

    unless (Sympa::send_file($robot, 'lists', $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "lists" to %s',
            $sender);
        Sympa::Report::reject_report_cmd('intern_quiet', '', {}, $cmd_line,
            $sender, $robot);
    }

    $log->syslog(
        'info',  'LISTS from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $time_command
    );

    return 1;
}

#####################################################
#  stats
#####################################################
#  Sends the statistics about a list using template
#  'stats_report'
#
# IN : -$listname (+): list name
#      -$robot (+): robot
#      -$sign_mod : 'smime' | 'dkim'|  -
#
# OUT : 'unknown_list'|'not_allowed'|1  | undef
#
#######################################################
sub stats {
    my $listname = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $listname, $robot, $sign_mod, $message);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        $log->syslog('info',
            'STATS %s from %s refused, unknown list for robot %s',
            $listname, $sender, $robot);
        return 'unknown_list';
    }

    my $auth_method = get_auth_method(
        'stats', $sender,
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "STATS $listname from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list, 'review',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'review' for list $listname";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $listname, 'list' => $list},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'Stats %s from %s refused (not allowed)',
            $listname, $sender);
        return 'not_allowed';
    } else {
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
            Sympa::Report::reject_report_cmd('intern_quiet', '',
                {'listname' => $listname, 'list' => $list},
                $cmd_line, $sender, $robot);
        }

        $log->syslog('info', 'STATS %s from %s accepted (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $time_command);
    }

    return 1;
}

###############################################
#  getfile
##############################################
# Sends back the requested archive file
#
# IN : -$which (+): command parameters : listname filename
#      -$robot (+): robot
#
# OUT : 'unknownlist'|'no_archive'|'not_allowed'|1
#
###############################################
sub getfile {
    $log->syslog('debug', '(%s, %s, %s, %s)', @_);
    my $args     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my ($which, $arc) = split /\s+/, $args, 2;

    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'GET %s %s from %s refused, list unknown for robot %s',
            $which, $arc, $sender, $robot);
        return 'unknownlist';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        Sympa::Report::reject_report_cmd('user', 'empty_archives', {},
            $cmd_line);
        $log->syslog('info',
            'GET %s %s from %s refused, no archive for list %s',
            $which, $arc, $sender, $which);
        return 'no_archive';
    }

    my $auth_method = get_auth_method(
        'get', $sender,
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "GET $which $arc from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list,
        'archive.mail_access',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error =
            "Unable to evaluate scenario 'archive_mail_access' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which, 'list' => $list},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'GET %s %s from %s refused (not allowed)',
            $which, $arc, $sender);
        return 'not_allowed';
    }

    my $archive = Sympa::Archive->new($list);
    my @msg_list;
    unless ($archive->select_archive($arc)) {
        Sympa::Report::reject_report_cmd('user', 'no_required_file', {},
            $cmd_line);
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
        Sympa::Report::reject_report_cmd(
            'intern',
            "Unable to send archive to $sender",
            {'listname' => $which},
            $cmd_line, $sender, $robot
        );
        return 'no_archive';
    }

    $log->syslog('info', 'GET %s %s from %s accepted (%.2f seconds)',
        $which, $arc, $sender, Time::HiRes::time() - $time_command);

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
sub last {
    $log->syslog('debug', '(%s, %s, %s, %s)', @_);
    my $which    = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'LAST %s from %s refused, list unknown for robot %s',
            $which, $sender, $robot);
        return 'unknownlist';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        Sympa::Report::reject_report_cmd('user', 'empty_archives', {},
            $cmd_line);
        $log->syslog('info', 'LAST %s from %s refused, list not archived',
            $which, $sender);
        return 'no_archive';
    }

    my $auth_method = get_auth_method(
        'last', $sender,
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "LAST $which from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list,
        'archive.mail_access',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error =
            "Unable to evaluate scenario 'archive_mail_access' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which, 'list' => $list},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'LAST %s from %s refused (not allowed)',
            $which, $sender);
        return 'not_allowed';
    }

    my ($arc_message, $arc_handle);
    my $archive = Sympa::Archive->new($list);
    foreach my $arc (reverse $archive->get_archives) {
        next unless $archive->select_archive($arc);
        ($arc_message, $arc_handle) = $archive->next(reverse => 1);
        last if $arc_message;
    }
    unless ($arc_message) {
        Sympa::Report::reject_report_cmd('user', 'no_required_file', {},
            $cmd_line);
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
        Sympa::Report::reject_report_cmd(
            'intern',
            "Unable to send archive to $sender",
            {'listname' => $which},
            $cmd_line, $sender, $robot
        );
        return 'no_archive';
    }

    $log->syslog('info', 'LAST %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $time_command);

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
sub index {
    $log->syslog('debug', '(%s, %s, %s, %s)', @_);
    my $which    = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'INDEX %s from %s refused, list unknown for robot %s',
            $which, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $auth_method = get_auth_method(
        'index', $sender,
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "INDEX $which from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list,
        'archive.mail_access',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error =
            "Unable to evaluate scenario 'archive_mail_access' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which, 'list' => $list},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'INDEX %s from %s refused (not allowed)',
            $which, $sender);
        return 'not_allowed';
    }

    unless ($list->is_archived()) {
        Sympa::Report::reject_report_cmd('user', 'empty_archives', {},
            $cmd_line);
        $log->syslog('info', 'INDEX %s from %s refused, list not archived',
            $which, $sender);
        return 'no_archive';
    }

    my @arcs;
    if ($list->is_archived) {
        my $archive = Sympa::Archive->new($list);
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
        Sympa::Report::reject_report_cmd('intern_quiet', '',
            {'listname' => $list->{'name'}},
            $cmd_line, $sender, $robot);
    }

    $log->syslog('info', 'INDEX %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $time_command);

    return 1;
}

############################################################
#  review
############################################################
#  Sends the list of subscribers to the requester.
#
# IN : -$listname (+): list name
#      -$robot (+): robot
#      -$sign_mod : 'smime'| -
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       |'no_subscribers'|1 | undef
#
################################################################
sub review {
    my $listname = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s)', $listname, $robot, $sign_mod);

    my $user;
    my $list = Sympa::List->new($listname, $robot);

    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        $log->syslog('info',
            'REVIEW %s from %s refused, list unknown to robot %s',
            $listname, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    unless (defined $list->on_the_fly_sync_include(use_ttl => 1)) {
        $log->syslog('notice', 'Unable to synchronize list %s', $list);
        #FIXME: Abort if synchronization failed.
    }

    my $auth_method = get_auth_method(
        'review', '',
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "REVIEW $listname from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list, 'review',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'review' for list $listname";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $listname},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /request_auth/i) {
        $log->syslog('debug2', 'Auth requested from %s', $sender);
        unless (Sympa::request_auth($list, $sender, 'review')) {
            my $error =
                'Unable to request authentication for command "review"';
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $listname},
                $cmd_line, $sender, $robot);
            return undef;
        }
        $log->syslog('info',
            'REVIEW %s from %s, auth requested (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }
    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'Review %s from %s refused (not allowed)',
            $listname, $sender);
        return 'not_allowed';
    }

    my @users;

    if ($action =~ /do_it/i) {
        my $is_owner = $list->is_admin('owner', $sender)
            || Sympa::is_listmaster($list, $sender);
        unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
            Sympa::Report::reject_report_cmd('user', 'no_subscriber',
                {'listname' => $listname}, $cmd_line);
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
            Sympa::Report::reject_report_cmd('intern_quiet', '',
                {'listname' => $listname},
                $cmd_line, $sender, $robot);
        }

        $log->syslog('info', 'REVIEW %s from %s accepted (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }
    $log->syslog('info',
        'REVIEW %s from %s aborted, unknown requested action in scenario',
        $listname, $sender);
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error,
        {'listname' => $listname},
        $cmd_line, $sender, $robot);
    return undef;
}

############################################################
#  verify
############################################################
#  Verify an S/MIME signature
#
# IN : -$listname (+): list name
#      -$robot (+): robot
#      -$sign_mod : 'smime'| 'dkim' | -
#
# OUT : 1
#
#############################################################
sub verify {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $listname = shift;
    my $robot    = shift;
    my $sign_mod = shift;

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        $log->syslog('info',
            'VERIFY from %s refused, unknown list for robot %s',
            $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    if ($sign_mod) {
        $log->syslog(
            'info',  'VERIFY successful from %s (%.2f seconds)',
            $sender, Time::HiRes::time() - $time_command
        );
        if ($sign_mod eq 'smime') {
            ##$auth_method='smime';
            Sympa::Report::notice_report_cmd('smime', {}, $cmd_line);
        } elsif ($sign_mod eq 'dkim') {
            ##$auth_method='dkim';
            Sympa::Report::notice_report_cmd('dkim', {}, $cmd_line);
        }
    } else {
        $log->syslog(
            'info',
            'VERIFY from %s: could not find correct S/MIME signature (%.2f seconds)',
            $sender,
            Time::HiRes::time() - $time_command
        );
        Sympa::Report::reject_report_cmd('user', 'no_verify_sign', {},
            $cmd_line);
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
# IN : -$what (+): command parameters : listname(+), comment
#      -$robot (+): robot
#      -$sign_mod : 'smime'| -
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'| 1 | undef
#
################################################################
sub subscribe {
    my $what     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $what, $robot, $sign_mod, $message);

    $what =~ /^(\S+)(\s+(.+))?\s*$/;
    my ($which, $comment) = ($1, $3);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'SUB %s from %s refused, unknown list for robot %s',
            $which, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    ## This is a really minimalistic handling of the comments,
    ## it is far away from RFC-822 completeness.
    if (defined $comment and $comment =~ /\S/) {
        $comment =~ s/"/\\"/g;
        $comment = "\"$comment\"" if ($comment =~ /[<>\(\)]/);
    } else {
        undef $comment;
    }

    ## Now check if the user may subscribe to the list

    my $auth_method = get_auth_method(
        'subscribe',
        $sender,
        {   'type' => 'wrong_email_confirm',
            'data' => {'command' => 'subscription'},
            'msg'  => "SUB $which from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    ## query what to do with this subscribtion request

    my $result = Sympa::Scenario::request_action(
        $list,
        'subscribe',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'subscribe' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which},
            $cmd_line, $sender, $robot);
        return undef;
    }

    $log->syslog('debug2', 'Action: %s', $action);

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'SUB %s from %s refused (not allowed)',
            $which, $sender);
        return 'not_allowed';
    }

    ## Unless rejected by scenario, don't go further if the user is subscribed
    ## already.
    my $user_entry = $list->get_list_member($sender);
    if (defined($user_entry)) {
        Sympa::Report::reject_report_cmd('user', 'already_subscriber',
            {'email' => $sender, 'listname' => $list->{'name'}}, $cmd_line);
        $log->syslog(
            'err',
            'User %s is subscribed to %s already. Ignoring subscription request',
            $sender,
            $list->{'name'}
        );
        return undef;
    }

    ## Continue checking scenario.
    if ($action =~ /owner/i) {
        Sympa::Report::notice_report_cmd('req_forward', {}, $cmd_line);
        ## Send a notice to the owners.
        unless (
            $list->send_notify_to_owner(
                'subrequest',
                {   'who'     => $sender,
                    'keyauth' => Sympa::compute_auth($list, $sender, 'add'),
                    'replyto' => Conf::get_robot_conf($robot, 'sympa'),
                    'gecos'   => $comment
                }
            )
            ) {
            #FIXME: Why is error reported only in this case?
            $log->syslog('info',
                'Unable to send notify "subrequest" to %s list owner', $list);
            Sympa::Report::reject_report_cmd(
                'intern',
                "Unable to send subrequest to $list->{'name'} list owner",
                {'listname' => $list->{'name'}},
                $cmd_line,
                $sender,
                $robot
            );
        }

        my $spool_req = Sympa::Spool::Request->new;
        my $request   = Sympa::Request->new_from_tuples(
            context => $list,
            sender  => $sender,
            gecos   => $comment,
            action  => 'add',
            date    => $message->{date},    # Keep date of message.
        );
        if ($spool_req->store($request)) {
            $log->syslog(
                'info',
                'SUB %s from %s forwarded to the owners of the list (%.2f seconds)',
                $which,
                $sender,
                Time::HiRes::time() - $time_command
            );
        }
        return 1;
    }
    if ($action =~ /request_auth/i) {
        my $cmd = 'subscribe';
        $cmd = "quiet $cmd" if $quiet;
        unless (Sympa::request_auth($list, $sender, $cmd, $comment)) {
            my $error =
                'Unable to request authentication for command "subscribe"';
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }
        $log->syslog('info', 'SUB %s from %s, auth requested (%.2f seconds)',
            $which, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }
    if ($action =~ /do_it/i) {
        my $user_entry = $list->get_list_member($sender);

        if (defined $user_entry) {
            # Only updates the date.  Options remain the same.
            my %update = (
                update_date => time,
                subscribed  => 1,
            );
            $update{gecos} = $comment
                if defined $comment and $comment =~ /\S/;

            unless ($list->update_list_member($sender, %update)) {
                my $error = sprintf 'Unable to update user %s in list %s',
                    $sender, $list->{'name'};
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $which},
                    $cmd_line, $sender, $robot);
                return undef;
            }
        } else {

            my $u;
            my $defaults = $list->get_default_user_options();
            %{$u} = %{$defaults};
            $u->{'email'} = $sender;
            $u->{'gecos'} = $comment;
            $u->{'date'}  = $u->{'update_date'} = time;

            $list->add_list_member($u);
            if (defined $list->{'add_outcome'}{'errors'}) {
                my $error =
                    sprintf "Unable to add user %s in list %s : %s",
                    $u, $which,
                    $list->{'add_outcome'}{'errors'}{'error_message'};
                my $error_type = 'intern';
                $error_type = 'user'
                    if defined $list->{'add_outcome'}{'errors'}
                    {'max_list_members_exceeded'};
                Sympa::Report::reject_report_cmd($error_type, $error,
                    {'listname' => $which},
                    $cmd_line, $sender, $robot);
                return undef;
            }
        }

        my $u = Sympa::User->new($sender);
        $u->lang($list->{'admin'}{'lang'}) unless $u->lang;
        $u->password(Sympa::Tools::Password::tmp_passwd($sender))
            unless $u->password;
        $u->save;

        ## Now send the welcome file to the user
        unless ($quiet || ($action =~ /quiet/i)) {
            unless ($list->send_probe_to_user('welcome', $sender)) {
                $log->syslog('notice', 'Unable to send "welcome" probe to %s',
                    $sender);
            }
        }

        ## If requested send notification to owners
        if ($action =~ /notify/i) {
            $list->send_notify_to_owner(
                'notice',
                {   'who'     => $sender,
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
            Time::HiRes::time() - $time_command,
            $list->get_total()
        );

        return 1;
    }

    $log->syslog('info',
        'SUB %s from %s aborted, unknown requested action in scenario',
        $which, $sender);
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error, {'listname' => $which},
        $cmd_line, $sender, $robot);
    return undef;
}

############################################################
#  info
############################################################
#  Sends the information file to the requester
#
# IN : -$listname (+): concerned list
#      -$robot (+): robot
#      -$sign_mod : 'smime'|undef
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
##############################################################
sub info {
    my $listname = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $listname, $robot, $sign_mod, $message);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        $log->syslog('info',
            'INFO %s from %s refused, unknown list for robot %s',
            $listname, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $auth_method = get_auth_method(
        'info', '',
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "INFO $listname from $sender"
        },
        $sign_mod,
        $list
    );

    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list, 'info',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );

    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'review' for list $listname";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $listname, 'list' => $list},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (Sympa::send_file($list, $result->{'tt2'}, $sender, {})) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'Review %s from %s refused (not allowed)',
            $listname, $sender);
        return 'not_allowed';
    }
    if ($action =~ /do_it/i) {

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

        my $wwsympa_url = Conf::get_robot_conf($robot, 'wwsympa_url');
        $data->{'url'} = $wwsympa_url . '/info/' . $list->{'name'};

        unless (Sympa::send_file($list, 'info_report', $sender, $data)) {
            $log->syslog('notice',
                'Unable to send template "info_report" to %s', $sender);
            Sympa::Report::reject_report_cmd('intern_quiet', '',
                {'listname' => $list->{'name'}},
                $cmd_line, $sender, $robot);
        }

        $log->syslog('info', 'INFO %s from %s accepted (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }

    $log->syslog('info',
        'INFO %s from %s aborted, unknown requested action in scenario',
        $listname, $sender);
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error,
        {'listname' => $listname},
        $cmd_line, $sender, $robot);
    return undef;

}

##############################################################
#  signoff
##############################################################
#  Unsubscribes a user from a list. The user sent a signoff
# command. Format was : sig list. He can be informed by template 'bye'
#
# IN : -$which (+): command parameters : listname(+), email(+)
#      -$robot (+): robot
#      -$sign_mod : 'smime'| -
#
# OUT : 'syntax_error'|'unknown_list'|'wrong_auth'
#       |'not_allowed'| 1 | undef
#
#
##############################################################
sub signoff {
    my $which    = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $which, $robot, $sign_mod, $message);

    my ($email, $l, $list, $auth_method);
    my $host = Conf::get_robot_conf($robot, 'host');

    ## $email is defined if command is "unsubscribe <listname> <e-mail>"
    unless ($which =~ /^(\*|[\w\.\-]+)(\@$host)?(\s+(.+))?$/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        $log->syslog('notice', 'Command syntax error');
        return 'syntax_error';
    }

    ($which, $email) = ($1, $4 || $sender);

    if ($which eq '*') {
        my $success;
        foreach $list (Sympa::List::get_which($email, $robot, 'member')) {
            $l = $list->{'name'};

            ## Skip hidden lists
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
                    "Unable to evaluate scenario 'visibility' for list $l";
                Sympa::send_notify_to_listmaster(
                    $list,
                    'intern_error',
                    {   'error'  => $error,
                        'who'    => $sender,
                        'cmd'    => $cmd_line,
                        'action' => 'Command process'
                    }
                );
                next;
            }

            if ($action =~ /reject/) {
                next;
            }

            $result = signoff("$l $email", $robot);
            $success ||= $result;
        }
        return ($success);
    }

    $list = Sympa::List->new($which, $robot);

    ## Is this list defined
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info', 'SIG %s %s from %s, unknown list for robot %s',
            $which, $email, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    $auth_method = get_auth_method(
        'signoff',
        $email,
        {   'type' => 'wrong_email_confirm',
            'data' => {'command' => 'unsubscription'},
            'msg'  => "SIG $which from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list,
        'unsubscribe',
        $auth_method,
        {   'email'   => $email,
            'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'unsubscribe' for list $l";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (Sympa::send_file($list, $result->{'tt2'}, $sender, {})) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $which}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                {'listname' => $which}, $cmd_line);
        }
        $log->syslog('info', 'SIG %s %s from %s refused (not allowed)',
            $which, $email, $sender);
        return 'not_allowed';
    }
    if ($action =~ /request_auth\s*\(\s*\[\s*(email|sender)\s*\]\s*\)/i) {
        my $to;
        if ($1 eq 'email') {
            $to = $email;
        } else {
            $to = $sender;
        }
        my $cmd = 'signoff';
        $cmd = "quiet $cmd" if $quiet;
        unless (Sympa::request_auth($list, $to, $cmd)) {
            my $error =
                'Unable to request authentication for command "signoff"';
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }
        $log->syslog('info', 'SIG %s from %s auth requested (%.2f seconds)',
            $which, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }

    if ($action =~ /owner/i) {
        Sympa::Report::notice_report_cmd('req_forward', {}, $cmd_line)
            unless ($action =~ /quiet/i);
        ## Send a notice to the owners.
        unless (
            $list->send_notify_to_owner(
                'sigrequest',
                {   'who'     => $sender,
                    'keyauth' => Sympa::compute_auth($list, $sender, 'del')
                }
            )
            ) {
            #FIXME: Why is error reported only in this case?
            Sympa::Report::reject_report_cmd(
                'intern_quiet',
                "Unable to send sigrequest to $list->{'name'} list owner",
                {'listname' => $list->{'name'}},
                $cmd_line,
                $sender,
                $robot
            );
        }
        $log->syslog(
            'info',
            'SIG %s from %s forwarded to the owners of the list (%.2f seconds)',
            $which,
            $sender,
            Time::HiRes::time() - $time_command
        );
        return 1;
    }
    if ($action =~ /do_it/i) {
        ## Now check if we know this email on the list and
        ## remove it if found, otherwise just reject the
        ## command.
        my $user_entry = $list->get_list_member($email);
        unless ((defined $user_entry)) {
            Sympa::Report::reject_report_cmd('user', 'your_email_not_found',
                {'email' => $email, 'listname' => $list->{'name'}},
                $cmd_line);
            $log->syslog('info', 'SIG %s from %s refused, not on list',
                $which, $email);

            ## Tell the owner somebody tried to unsubscribe
            if ($action =~ /notify/i) {
                # try to find email from same domain or email wwith same local
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
            my $error = "Unable to delete user $email from list $which";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
        }

        ## Notify the owner
        if ($action =~ /notify/i) {
            $list->send_notify_to_owner(
                'notice',
                {   'who'     => $email,
                    'gecos'   => ($user_entry->{'gecos'} || ''),
                    'command' => 'signoff'
                }
            );
        }

        unless ($quiet || ($action =~ /quiet/i)) {
            ## Send bye file to subscriber
            unless (Sympa::send_file($list, 'bye', $email, {})) {
                $log->syslog('notice', 'Unable to send template "bye" to %s',
                    $email);
            }
        }

        $log->syslog(
            'info',
            'SIG %s from %s accepted (%.2f seconds, %d subscribers)',
            $which,
            $email,
            Time::HiRes::time() - $time_command,
            $list->get_total()
        );

        return 1;
    }
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error, {'listname' => $which},
        $cmd_line, $sender, $robot);
    return undef;
}

############################################################
#  add
############################################################
#  Adds a user to a list (requested by another user). Verifies
#  the proper authorization and sends acknowledgements unless
#  quiet add.
#
# IN : -$what (+): command parameters : listname(+),
#                                    email(+), comments
#      -$robot (+): robot
#      -$sign_mod : 'smime'|undef
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
############################################################
sub add {
    my $what     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $what, $robot, $sign_mod, $message);

    my $email_regexp = Sympa::Regexps::email();

    $what =~ /^(\S+)\s+($email_regexp)(\s+(.+))?\s*$/;
    my ($which, $email, $comment) = ($1, $2, $6);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'ADD %s %s from %s refused, unknown list for robot %s',
            $which, $email, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $auth_method = get_auth_method(
        'add', $email,
        {   'type' => 'wrong_email_confirm',
            'data' => {'command' => 'addition'},
            'msg'  => "ADD $which $email from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list, 'add',
        $auth_method,
        {   'email'   => $email,
            'sender'  => $sender,
            'message' => $message,
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'add' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (Sympa::send_file($list, $result->{'tt2'}, $sender, {})) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $which}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                {'listname' => $which}, $cmd_line);
        }
        $log->syslog('info', 'ADD %s %s from %s refused (not allowed)',
            $which, $email, $sender);
        return 'not_allowed';
    }

    if ($action =~ /request_auth/i) {
        my $cmd = 'add';
        $cmd = "quiet $cmd" if $quiet;
        unless (Sympa::request_auth($list, $sender, $cmd, $email, $comment)) {
            my $error = 'Unable to request authentication for command "add"';
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }
        $log->syslog('info', 'ADD %s from %s, auth requested(%.2f seconds)',
            $which, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }
    if ($action =~ /do_it/i) {
        if ($list->is_list_member($email)) {
            Sympa::Report::reject_report_cmd('user', 'already_subscriber',
                {'email' => $email, 'listname' => $which}, $cmd_line);
            $log->syslog(
                'err',
                'ADD command rejected; user "%s" already member of list "%s"',
                $email,
                $which
            );
            return undef;

        } else {
            my $u;
            my $defaults = $list->get_default_user_options();
            %{$u} = %{$defaults};
            $u->{'email'} = $email;
            $u->{'gecos'} = $comment;
            $u->{'date'}  = $u->{'update_date'} = time;

            $list->add_list_member($u);
            if (defined $list->{'add_outcome'}{'errors'}) {
                my $error =
                    sprintf "Unable to add user %s in list %s : %s",
                    $u, $which,
                    $list->{'add_outcome'}{'errors'}{'error_message'};
                my $error_type = 'intern';
                $error_type = 'user'
                    if (
                    defined $list->{'add_outcome'}{'errors'}
                    {'max_list_members_exceeded'});
                Sympa::Report::reject_report_cmd($error_type, $error,
                    {'listname' => $which},
                    $cmd_line, $sender, $robot);
                return undef;
            }

            my $spool_req = Sympa::Spool::Request->new(
                context => $list,
                sender  => $email,
                action  => 'add'
            );
            while (1) {
                my ($request, $handle) = $spool_req->next;
                last unless $handle;
                next unless $request;

                $spool_req->remove($handle);
            }

            Sympa::Report::notice_report_cmd('now_subscriber',
                {'email' => $email, 'listname' => $which}, $cmd_line);
        }

        my $u = Sympa::User->new($email);
        $u->lang($list->{'admin'}{'lang'}) unless $u->lang;
        $u->password(Sympa::Tools::Password::tmp_passwd($email))
            unless $u->password;
        $u->save;

        ## Now send the welcome file to the user if it exists and notification
        ## is supposed to be sent.
        unless ($quiet || $action =~ /quiet/i) {
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
            Time::HiRes::time() - $time_command,
            $list->get_total()
        );
        if ($action =~ /notify/i) {
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
    $log->syslog('info',
        'ADD %s from %s aborted, unknown requested action in scenario',
        $which, $sender);
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error, {'listname' => $which},
        $cmd_line, $sender, $robot);
    return undef;

}

############################################################
#  invite
############################################################
#  Invite someone to subscribe a list by sending him
#  template 'invite'
#
# IN : -$what (+): listname(+), email(+) and comments
#      -$robot (+): robot
#      -$sign_mod : 'smime'|undef
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
##############################################################
sub invite {
    my $what     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $what, $robot, $sign_mod, $message);

    my $sympa = Conf::get_robot_conf($robot, 'sympa');

    $what =~ /^(\S+)\s+(\S+)(\s+(.+))?\s*$/;
    my ($which, $email, $comment) = ($1, $2, $4);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'INVITE %s %s from %s refused, unknown list for robot',
            $which, $email, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $auth_method = get_auth_method(
        'invite', $email,
        {   'type' => 'wrong_email_confirm',
            'data' => {'command' => 'invitation'},
            'msg'  => "INVITE $which $email from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    my $result = Sympa::Scenario::request_action(
        $list, 'invite',
        $auth_method,
        {   'sender'  => $sender,
            'message' => $message,
        }
    );

    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'invite' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (Sympa::send_file($list, $result->{'tt2'}, $sender, {})) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        $log->syslog('info', 'INVITE %s %s from %s refused (not allowed)',
            $which, $email, $sender);
        return 'not_allowed';
    }

    if ($action =~ /request_auth/i) {
        unless (
            Sympa::request_auth($list, $sender, 'invite', $email, $comment)) {
            my $error =
                'Unable to request authentication for command "invite"';
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }

        $log->syslog('info',
            'INVITE %s from %s, auth requested (%.2f seconds)',
            $which, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }
    if ($action =~ /do_it/i) {
        if ($list->is_list_member($email)) {
            Sympa::Report::reject_report_cmd('user', 'already_subscriber',
                {'email' => $email, 'listname' => $which}, $cmd_line);
            $log->syslog(
                'err',
                'INVITE command rejected; user "%s" already member of list "%s"',
                $email,
                $which
            );
            return undef;
        } else {
            ## Is the guest user allowed to subscribe in this list ?

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
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $which},
                    $cmd_line, $sender, $robot);
                return undef;
            }

            if ($action =~ /request_auth/i) {
                my $keyauth = Sympa::compute_auth($list, $email, 'subscribe');
                my $command = "auth $keyauth sub $which $comment";
                $context{'subject'} = $command;
                $context{'url'}     = "mailto:$sympa?subject=$command";
                $context{'url'} =~ s/\s/%20/g;
                unless (Sympa::send_file($list, 'invite', $email, \%context))
                {
                    $log->syslog('notice',
                        'Unable to send template "invite" to %s', $email);
                    Sympa::Report::reject_report_cmd(
                        'intern',
                        "Unable to send template 'invite' to $email",
                        {'listname' => $which},
                        $cmd_line,
                        $sender,
                        $robot
                    );
                    return undef;
                }
                $log->syslog(
                    'info',
                    'INVITE %s %s from %s accepted, auth requested (%.2f seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    Time::HiRes::time() - $time_command,
                    $list->get_total()
                );
                Sympa::Report::notice_report_cmd('invite',
                    {'email' => $email, 'listname' => $which}, $cmd_line);

            } elsif ($action !~ /reject/i) {
                $context{'subject'} = "sub $which $comment";
                $context{'url'} = "mailto:$sympa?subject=$context{'subject'}";
                $context{'url'} =~ s/\s/%20/g;
                unless (Sympa::send_file($list, 'invite', $email, \%context))
                {
                    $log->syslog('notice',
                        'Unable to send template "invite" to %s', $email);
                    Sympa::Report::reject_report_cmd(
                        'intern',
                        "Unable to send template 'invite' to $email",
                        {'listname' => $which},
                        $cmd_line,
                        $sender,
                        $robot
                    );
                    return undef;
                }
                $log->syslog(
                    'info',
                    'INVITE %s %s from %s accepted, (%.2f seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    Time::HiRes::time() - $time_command,
                    $list->get_total()
                );
                Sympa::Report::notice_report_cmd('invite',
                    {'email' => $email, 'listname' => $which}, $cmd_line);

            } elsif ($action =~ /reject/i) {
                $log->syslog(
                    'info',
                    'INVITE %s %s from %s refused, not allowed (%.2f seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    Time::HiRes::time() - $time_command,
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
                        Sympa::Report::reject_report_cmd('auth',
                            $result->{'reason'}, {}, $cmd_line);
                    }
                } else {
                    Sympa::Report::reject_report_cmd('auth',
                        $result->{'reason'},
                        {'email' => $email, 'listname' => $which}, $cmd_line);
                }
            }
        }
        return 1;
    }
    $log->syslog('info',
        'INVITE %s from %s aborted, unknown requested action in scenario',
        $which, $sender);
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error, {'listname' => $which},
        $cmd_line, $sender, $robot);
    return undef;
}

############################################################
#  remind
############################################################
#  Sends a personal reminder to each subscriber of one list or
#  of every list ($which = *) using template 'remind' or
#  'global_remind'
#
#
# IN : -$which (+): * | listname
#      -$robot (+): robot
#      -$sign_mod : 'smime'| -
#
# OUT : 'syntax_error'|'unknown_list'|'wrong_auth'
#       |'not_allowed' |  1 | undef
#
#
##############################################################
sub remind {
    my $which    = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $which, $robot, $sign_mod, $message);

    my $host = Conf::get_robot_conf($robot, 'host');

    my %context;

    unless ($which =~ /^(\*|[\w\.\-]+)(\@$host)?\s*$/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        $log->syslog('notice', 'Command syntax error');
        return 'syntax_error';
    }

    my $listname = $1;
    my $list;

    unless ($listname eq '*') {
        $list = Sympa::List->new($listname, $robot);
        unless ($list) {
            Sympa::Report::reject_report_cmd('user', 'no_existing_list',
                {'listname' => $which}, $cmd_line);
            $log->syslog('info',
                'REMIND %s from %s refused, unknown list for robot %s',
                $which, $sender, $robot);
            return 'unknown_list';
        }
    }

    my $auth_method;

    if ($listname eq '*') {
        $auth_method = get_auth_method(
            'remind', '',
            {   'type' => 'auth_failed',
                'data' => {},
                'msg'  => "REMIND $listname from $sender"
            },
            $sign_mod
        );
    } else {
        $auth_method = get_auth_method(
            'remind', '',
            {   'type' => 'auth_failed',
                'data' => {},
                'msg'  => "REMIND $listname from $sender"
            },
            $sign_mod,
            $list
        );
    }

    return 'wrong_auth'
        unless (defined $auth_method);

    my $action;
    my $result;

    if ($listname eq '*') {

        $result =
            Sympa::Scenario::request_action($robot, 'global_remind',
            $auth_method, {'sender' => $sender});
        $action = $result->{'action'} if (ref($result) eq 'HASH');

    } else {

        $language->set_lang($list->{'admin'}{'lang'});

        $host = $list->{'admin'}{'host'};

        $result = Sympa::Scenario::request_action(
            $list, 'remind',
            $auth_method,
            {   'sender'  => $sender,
                'message' => $message,
            }
        );

        $action = $result->{'action'} if (ref($result) eq 'HASH');

    }

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'remind' for list $listname";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $listname},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        $log->syslog('info', 'Remind for list %s from %s refused',
            $listname, $sender);
        if (defined $result->{'tt2'}) {
            unless (Sympa::send_file($list, $result->{'tt2'}, $sender, {})) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);

                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $listname}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        return 'not_allowed';
    } elsif ($action =~ /request_auth/i) {
        $log->syslog('debug2', 'Auth requested from %s', $sender);
        if ($listname eq '*') {
            unless (Sympa::request_auth('*', $sender, 'remind')) {
                my $error =
                    'Unable to request authentication for command "remind"';
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $listname},
                    $cmd_line, $sender, $robot);
                return undef;
            }
        } else {
            unless (Sympa::request_auth($list, $sender, 'remind')) {
                my $error =
                    'Unable to request authentication for command "remind"';
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $listname},
                    $cmd_line, $sender, $robot);
                return undef;
            }
        }
        $log->syslog('info',
            'REMIND %s from %s, auth requested (%.2f seconds)',
            $listname, $sender, Time::HiRes::time() - $time_command);
        return 1;
    } elsif ($action =~ /do_it/i) {

        if ($listname ne '*') {

            unless ($list) {
                Sympa::Report::reject_report_cmd('user', 'no_existing_list',
                    {'listname' => $listname}, $cmd_line);
                $log->syslog('info',
                    'REMIND %s from %s refused, unknown list for robot %s',
                    $listname, $sender, $robot);
                return 'unknown_list';
            }

            ## for each subscriber send a reminder
            my $total = 0;
            my $user;

            unless ($user = $list->get_first_list_member()) {
                my $error = "Unable to get subscribers for list $listname";
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $listname},
                    $cmd_line, $sender, $robot);
                return undef;
            }

            do {
                unless ($list->send_probe_to_user('remind', $user->{'email'}))
                {
                    $log->syslog('notice',
                        'Unable to send "remind" probe to %s',
                        $user->{'email'});
                    Sympa::Report::reject_report_cmd('intern_quiet', '',
                        {'listname' => $listname},
                        $cmd_line, $sender, $robot);
                }
                $total += 1;
            } while ($user = $list->get_next_list_member());

            Sympa::Report::notice_report_cmd('remind',
                {'total' => $total, 'listname' => $listname}, $cmd_line);
            $log->syslog(
                'info',
                'REMIND %s from %s accepted, sent to %d subscribers (%.2f seconds)',
                $listname,
                $sender,
                $total,
                Time::HiRes::time() - $time_command
            );

            return 1;
        } else {
            ## Global REMIND
            my %global_subscription;
            my %global_info;
            my $count = 0;

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
                                'cmd'    => $cmd_line,
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
                    Sympa::Report::reject_report_cmd('intern_quiet', '',
                        {'listname' => $listname},
                        $cmd_line, $sender, $robot);
                }
            }
            Sympa::Report::notice_report_cmd('glob_remind',
                {'count' => $count}, $cmd_line);
        }
    } else {
        $log->syslog(
            'info',
            'REMIND %s from %s aborted, unknown requested action in scenario',
            $listname,
            $sender
        );
        my $error = "Unknown requested action in scenario: $action.";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $listname},
            $cmd_line, $sender, $robot);
        return undef;
    }
}

############################################################
#  del
############################################################
# Removes a user from a list (requested by another user).
# Verifies the authorization and sends acknowledgements
# unless quiet is specified.
#
# IN : -$what (+): command parameters : listname(+), email(+)
#      -$robot (+): robot
#      -$sign_mod : 'smime'|undef
#
# OUT : 'unknown_list'|'wrong_auth'|'not_allowed'
#       | 1 | undef
#
#
##############################################################
sub del {
    my $what     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $what, $robot, $sign_mod, $message);

    my $email_regexp = Sympa::Regexps::email();

    $what =~ /^(\S+)\s+($email_regexp)\s*/;
    my ($which, $who) = ($1, $2);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'DEL %s %s from %s refused, unknown list for robot %s',
            $which, $who, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $auth_method = get_auth_method(
        'del', $who,
        {   'type' => 'wrong_email_confirm',
            'data' => {'command' => 'delete'},
            'msg'  => "DEL $which $who from $sender"
        },
        $sign_mod,
        $list
    );
    return 'wrong_auth'
        unless (defined $auth_method);

    ## query what to do with this DEL request
    my $result = Sympa::Scenario::request_action(
        $list, 'del',
        $auth_method,
        {   'sender'  => $sender,
            'email'   => $who,
            'message' => $message,
        }
    );

    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'del' for list $which";
        Sympa::Report::reject_report_cmd('intern', $error,
            {'listname' => $which},
            $cmd_line, $sender, $robot);
        return undef;
    }

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (Sympa::send_file($list, $result->{'tt2'}, $sender, {})) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $which}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                {'listname' => $which}, $cmd_line);
        }
        $log->syslog('info', 'DEL %s %s from %s refused (not allowed)',
            $which, $who, $sender);
        return 'not_allowed';
    }
    if ($action =~ /request_auth/i) {
        my $cmd = 'del';
        $cmd = "quiet $cmd" if $quiet;
        unless (Sympa::request_auth($list, $sender, $cmd, $who)) {
            my $error = 'Unable to request authentication for command "del"';
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which, 'list' => $list},
                $cmd_line, $sender, $robot);
            return undef;
        }
        $log->syslog('info',
            'DEL %s %s from %s, auth requested (%.2f seconds)',
            $which, $who, $sender, Time::HiRes::time() - $time_command);
        return 1;
    }

    if ($action =~ /do_it/i) {
        ## Check if we know this email on the list and remove it. Otherwise
        ## just reject the message.
        my $user_entry = $list->get_list_member($who);

        unless ((defined $user_entry)) {
            Sympa::Report::reject_report_cmd('user', 'your_email_not_found',
                {'email' => $who, 'listname' => $which}, $cmd_line);
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
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
        }

        ## Send a notice to the removed user, unless the owner indicated
        ## quiet del.
        unless ($quiet || $action =~ /quiet/i) {
            unless (Sympa::send_file($list, 'removed', $who, {})) {
                $log->syslog('notice',
                    'Unable to send template "removed" to %s', $who);
            }
        }
        Sympa::Report::notice_report_cmd('removed',
            {'email' => $who, 'listname' => $which}, $cmd_line);
        $log->syslog(
            'info',
            'DEL %s %s from %s accepted (%.2f seconds, %d subscribers)',
            $which,
            $who,
            $sender,
            Time::HiRes::time() - $time_command,
            $list->get_total()
        );
        if ($action =~ /notify/i) {
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
    $log->syslog('info',
        'DEL %s %s from %s aborted, unknown requested action in scenario',
        $which, $who, $sender);
    my $error = "Unknown requested action in scenario: $action.";
    Sympa::Report::reject_report_cmd('intern', $error,
        {'listname' => $which, 'list' => $list},
        $cmd_line, $sender, $robot);
    return undef;
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
sub set {
    my $what     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $what, $robot, $sign_mod, $message);

    $what =~ /^\s*(\S+)\s+(\S+)\s*$/;
    my ($which, $mode) = ($1, $2);
    $which = (defined $which) ? lc $which : '';
    $mode  = (defined $mode)  ? lc $mode  : '';

    ## Unknown command (should be checked....)
    unless ($mode =~
        /^(digest|digestplain|nomail|normal|not_me|each|mail|conceal|noconceal|summary|notice|txt|html|urlize)$/i
        ) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        return 'syntax_error';
    }

    ## SET EACH is a synonym for SET MAIL
    $mode = 'mail' if ($mode =~ /^(each|eachmail|nodigest|normal)$/i);

    ## Recursive call to subroutine
    if ($which eq "*") {
        my $status;
        foreach my $list (Sympa::List::get_which($sender, $robot, 'member')) {
            my $l = $list->{'name'};

            ## Skip hidden lists
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
                    "Unable to evaluate scenario 'visibility' for list $l";
                Sympa::send_notify_to_listmaster(
                    $list,
                    'intern_error',
                    {   'error'  => $error,
                        'who'    => $sender,
                        'cmd'    => $cmd_line,
                        'action' => 'Command process'
                    }
                );
                next;
            }

            if ($action =~ /reject/) {
                next;
            }

            my $current_status = set("$l $mode");
            $status ||= $current_status;
        }
        return $status;
    }

    ## Load the list if not already done, and reject
    ## if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);

    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'SET %s %s from %s refused, unknown list for robot %s',
            $which, $mode, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    ## Check if we know this email on the list and remove it. Otherwise
    ## just reject the message.
    unless ($list->is_list_member($sender)) {
        Sympa::Report::reject_report_cmd('user', 'email_not_found',
            {'email' => $sender, 'listname' => $which}, $cmd_line);
        $log->syslog('info', 'SET %s %s from %s refused, not on list',
            $which, $mode, $sender);
        return 'not allowed';
    }

    ## May set to DIGEST
    if ($mode =~ /^(digest|digestplain|summary)/ and !$list->is_digest()) {
        Sympa::Report::reject_report_cmd('user', 'no_digest',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info', 'SET %s DIGEST from %s refused, no digest mode',
            $which, $sender);
        return 'not_allowed';
    }

    if ($mode =~
        /^(mail|nomail|digest|digestplain|summary|notice|txt|html|urlize|not_me)/
        ) {
        # Verify that the mode is allowed
        if (!$list->is_available_reception_mode($mode)) {
            Sympa::Report::reject_report_cmd(
                'user',
                'available_reception_mode',
                {   'listname' => $which,
                    'modes' => join(' ', $list->available_reception_mode()),
                    'reception_modes' => [$list->available_reception_mode()]
                },
                $cmd_line
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
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            $log->syslog('info', 'SET %s %s from %s refused, update failed',
                $which, $mode, $sender);
            return 'failed';
        }

        Sympa::Report::notice_report_cmd('config_updated',
            {'listname' => $which}, $cmd_line);

        $log->syslog('info', 'SET %s %s from %s accepted (%.2f seconds)',
            $which, $mode, $sender, Time::HiRes::time() - $time_command);
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
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            $log->syslog('info', 'SET %s %s from %s refused, update failed',
                $which, $mode, $sender);
            return 'failed';
        }

        Sympa::Report::notice_report_cmd('config_updated',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info', 'SET %s %s from %s accepted (%.2f seconds)',
            $which, $mode, $sender, Time::HiRes::time() - $time_command);
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
sub distribute {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $what  = shift;
    my $robot = shift;

    $what =~ /^\s*(\S+)\s+(\w+)\s*$/;
    my ($which, $key) = ($1, $2);
    $which =~ tr/A-Z/a-z/ if $which;
    unless ($which and $key and $key =~ /\A\w+\z/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        $log->syslog('notice', 'Command syntax error');
        return 'syntax_error';
    }

    # Load the list if not already done, and reject the
    # subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot, {just_try => 1});
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'DISTRIBUTE %s %s from %s refused, unknown list for robot %s',
            $which, $key, $sender, $robot);
        return 'unknown_list';
    }

    my $spindle = Sympa::Spindle::ProcessModeration->new(
        distributed_by => $sender,
        context        => $robot,
        authkey        => $key,
        quiet          => $quiet
    );

    unless ($spindle->spin) {    # No message.
        $log->syslog('err',
            'Unable to find message with key <%s> for list %s',
            $key, $list);
        Sympa::Report::reject_report_msg('user', 'unfound_message', $sender,
            {'listname' => $list->{'name'}, 'key' => $key},
            $robot, '', $list);
        return 'msg_not_found';
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info',
            'DISTRIBUTE %s %s from %s accepted (%.2f seconds)',
            $list->{'name'}, $key, $sender,
            Time::HiRes::time() - $time_command);
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
sub confirm {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $what  = shift;
    my $robot = shift;

    $what =~ /^\s*(\w+)\s*$/;
    my $key = $1;
    unless ($key and $key =~ /\A\w+\z/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        $log->syslog('notice', 'Command syntax error');
        return 'syntax_error';
    }

    my $spindle = Sympa::Spindle::ProcessHeld->new(
        confirmed_by => $sender,
        context      => $robot,
        authkey      => $key,
        quiet        => $quiet
    );

    unless ($spindle->spin) {    # No message.
        $log->syslog('info', 'CONFIRM %s from %s refused, auth failed',
            $key, $sender);
        Sympa::Report::reject_report_msg('user', 'unfound_file_message',
            $sender, {'key' => $key},
            $robot, '', '');
        return 'wrong_auth';
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info', 'CONFIRM %s from %s accepted (%.2f seconds)',
            $key, $sender, Time::HiRes::time() - $time_command);
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
sub reject {
    $log->syslog('debug2', '(%s, %s, %s, %s)', @_);
    my $what  = shift;
    my $robot = shift;
    shift;
    my $editor_msg = shift;

    $what =~ /^(\S+)\s+(\w+)\s*$/;
    my ($which, $key) = ($1, $2);
    $which =~ tr/A-Z/a-z/ if $which;
    unless ($which and $key and $key =~ /\A\w+\z/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        $log->syslog('notice', 'Command syntax error');
        return 'syntax_error';
    }

    # Load the list if not already done, and reject the subscription if this
    # list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        $log->syslog('info',
            'REJECT %s %s from %s refused, unknown list for robot %s',
            $which, $key, $sender, $robot);
        return 'unknown_list';
    }

    my $spindle = Sympa::Spindle::ProcessModeration->new(
        rejected_by => $sender,
        context     => $list,
        authkey     => $key,
        quiet       => $quiet
    );

    unless ($spindle->spin) {    # No message
        $log->syslog('info', 'REJECT %s %s from %s refused, auth failed',
            $which, $key, $sender);
        Sympa::Report::reject_report_msg('user', 'unfound_message', $sender,
            {'key' => $key},
            $robot, '', $list);
        return 'wrong_auth';
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info', 'REJECT %s %s from %s accepted (%.2f seconds)',
            $list->{'name'}, $key, $sender,
            Time::HiRes::time() - $time_command);
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
sub modindex {
    my $name  = shift;
    my $robot = shift;
    $log->syslog('debug', '(%s, %s)', $name, $robot);

    $name =~ y/A-Z/a-z/;

    my $list = Sympa::List->new($name, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $name}, $cmd_line);
        $log->syslog('info',
            'MODINDEX %s from %s refused, unknown list for robot %s',
            $name, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_admin('actual_editor', $sender)) {
        Sympa::Report::reject_report_cmd('auth', 'restricted_modindex', {},
            $cmd_line);
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
        Sympa::Report::notice_report_cmd('no_message_to_moderate',
            {'listname' => $name}, $cmd_line);
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
        Sympa::Report::reject_report_cmd('intern_quiet', '',
            {'listname' => $name},
            $cmd_line, $sender, $robot);
    }

    $log->syslog('info', 'MODINDEX %s from %s accepted (%.2f seconds)',
        $name, $sender, Time::HiRes::time() - $time_command);

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
sub which {
    my ($listname, @which);
    shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('debug', '(%s, %s, %s, %s)',
        $listname, $robot, $sign_mod, $message);

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
                    'cmd'    => $cmd_line,
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
        Sympa::Report::reject_report_cmd('intern_quiet', '',
            {'listname' => $listname},
            $cmd_line, $sender, $robot);
    }

    $log->syslog(
        'info',  'WHICH from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $time_command
    );

    return 1;
}

################ Function for authentication #######################

##########################################################
#  get_auth_method
##########################################################
# Checks the authentication and return method
# used if authentication not failed
#
# IN :-$cmd (+): current command
#     -$email (+): used to compute auth
#     -$error (+):ref(HASH) with keys :
#        -type : for message_report.tt2 parsing
#        -data : ref(HASH) for message_report.tt2 parsing
#        -msg : for $log->syslog()
#     -$sign_mod (+): 'smime'| 'dkim' | -
#     -$list : ref(List) | -
#
# OUT : 'smime'|'md5'|'dkim'|'smtp' if authentication OK, undef else
#       | undef
##########################################################
sub get_auth_method {
    $log->syslog('debug3', '(%s, %s, %s, %s, %s)', @_);
    my ($cmd, $email, $error, $sign_mod, $list) = @_;
    my $that;
    my $auth_method;

    if ($sign_mod and $sign_mod eq 'smime') {
        $auth_method = 'smime';
    } elsif ($auth ne '') {
        $log->syslog('debug', 'Auth received from %s: %s', $sender, $auth);

        my $compute;
        if (ref $list eq 'Sympa::List') {
            $compute = Sympa::compute_auth($list, $email, $cmd);
            $that = $list->{'domain'};    # Robot
        } else {
            $compute = Sympa::compute_auth('*', $email, $cmd);
            $that = '*';    # Site
        }
        if ($auth eq $compute) {
            $auth_method = 'md5';
        } else {
            $log->syslog('debug2', 'Auth should be %s', $compute);
            if ($error->{'type'} eq 'auth_failed') {
                Sympa::Report::reject_report_cmd('intern',
                    "The authentication process failed",
                    $error->{'data'}, $cmd_line, $sender, $that);
            } else {
                Sympa::Report::reject_report_cmd('user', $error->{'type'},
                    $error->{'data'}, $cmd_line);
            }
            $log->syslog('info', '%s refused, auth failed', $error->{'msg'});
            return undef;
        }
    } else {
        $auth_method = 'smtp';
        $auth_method = 'dkim' if $sign_mod and $sign_mod eq 'dkim';
    }

    return $auth_method;
}

1;
