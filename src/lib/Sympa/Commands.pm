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

use Sympa::Archive;
use Conf;
use Sympa::Language;
use Sympa::List;
use Log;
use Sympa::Message;
use Sympa::Regexps;
use Sympa::Report;
use Sympa::Scenario;
use tools;
use Sympa::Tools::Data;
use Sympa::Tools::File;
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

# command sender
my $sender = '';
# time of the process command
my $time_command;
## my $msg_file;
# command line to process
my $cmd_line;
# key authentification if 'auth' is present in the command line
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
    Log::do_log('debug2', '(%s, %s, %s, %s, %s)', @_);
    $sender = lc(shift);    #FIXME: eliminate module-global variable.
    my $robot    = shift;
    my $i        = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my $j;
    $cmd_line = '';

    Log::do_log('notice', "Parsing: %s", $i);

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

            $time_command = time;
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
    Log::do_log('debug2', '');

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
    Log::do_log('debug2', '(%s, %s)', @_);
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

    unless (tools::send_file($robot, "helpfile", $sender, $data)) {
        Log::do_log('notice', 'Unable to send template "helpfile" to %s',
            $sender);
        Sympa::Report::reject_report_cmd('intern_quiet', '', {}, $cmd_line,
            $sender, $robot);
    }

    Log::do_log('info', 'HELP from %s accepted (%d seconds)',
        $sender, time - $time_command);

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

    my $sympa = Conf::get_robot_conf($robot, 'sympa');
    my $host  = Conf::get_robot_conf($robot, 'host');

    Log::do_log('debug', 'For robot %s, sign_mod %, message %s',
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
            tools::send_notify_to_listmaster(
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

    unless (tools::send_file($robot, 'lists', $sender, $data)) {
        Log::do_log('notice', 'Unable to send template "lists" to %s',
            $sender);
        Sympa::Report::reject_report_cmd('intern_quiet', '', {}, $cmd_line,
            $sender, $robot);
    }

    Log::do_log('info', 'LISTS from %s accepted (%d seconds)',
        $sender, time - $time_command);

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

    Log::do_log('debug', '(%s, %s, %s, %s)',
        $listname, $robot, $sign_mod, $message);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        Log::do_log('info',
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
                tools::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'Stats %s from %s refused (not allowed)',
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
            tools::send_file(
                $list,
                'stats_report',
                $sender,
                {   'stats'   => \%stats,
                    'subject' => "STATS $list->{'name'}",  # compat <= 6.1.17.
                    'auto_submitted' => 'auto-replied'
                }
            )
            ) {
            Log::do_log('notice',
                'Unable to send template "stats_reports" to %s', $sender);
            Sympa::Report::reject_report_cmd('intern_quiet', '',
                {'listname' => $listname, 'list' => $list},
                $cmd_line, $sender, $robot);
        }

        Log::do_log('info', 'STATS %s from %s accepted (%d seconds)',
            $listname, $sender, time - $time_command);
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
    Log::do_log('debug', '(%s, %s, %s, %s)', @_);
    my $args     = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my ($which, $file) = split /\s+/, $args;

    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        Log::do_log('info',
            'GET %s %s from %s refused, list unknown for robot %s',
            $which, $file, $sender, $robot);
        return 'unknownlist';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        Sympa::Report::reject_report_cmd('user', 'empty_archives', {},
            $cmd_line);
        Log::do_log('info',
            'GET %s %s from %s refused, no archive for list %s',
            $which, $file, $sender, $which);
        return 'no_archive';
    }
    ## Check file syntax
    if ($file =~ /(\.\.|\/)/) {
        Sympa::Report::reject_report_cmd('user', 'no_required_file', {},
            $cmd_line);
        Log::do_log('info', 'GET %s %s from %s, incorrect filename',
            $which, $file, $sender);
        return 'no_archive';
    }

    my $auth_method = get_auth_method(
        'get', $sender,
        {   'type' => 'auth_failed',
            'data' => {},
            'msg'  => "GET $which $file from $sender"
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
                tools::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'GET %s %s from %s refused (not allowed)',
            $which, $file, $sender);
        return 'not_allowed';
    }
#    unless ($list->archive_exist($file)) {
#	Sympa::Report::reject_report_cmd('user', 'no_required_file', {},
#	    $cmd_line);
# 	Log::do_log('info',
# 	'GET %s %s from %s refused, archive not found for list %s', $which,
# 	    $file, $sender, $which);
#	return 'no_archive';
#    }

    unless ($list->archive_send($sender, $file)) {
        Sympa::Report::reject_report_cmd(
            'intern',
            "Unable to send archive to $sender",
            {'listname' => $which},
            $cmd_line, $sender, $robot
        );
        return 'no_archive';
    }

    Log::do_log('info', 'GET %s %s from %s accepted (%d seconds)',
        $which, $file, $sender, time - $time_command);

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
    Log::do_log('debug', '(%s, %s, %s, %s)', @_);
    my $which    = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        Log::do_log('info',
            'LAST %s from %s refused, list unknown for robot %s',
            $which, $sender, $robot);
        return 'unknownlist';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
        Sympa::Report::reject_report_cmd('user', 'empty_archives', {},
            $cmd_line);
        Log::do_log('info', 'LAST %s from %s refused, list not archived',
            $which, $sender);
        return 'no_archive';
    }
    my $file;
    unless ($file = Sympa::Archive::last_path($list)) {
        Sympa::Report::reject_report_cmd('user', 'no_required_file', {},
            $cmd_line);
        Log::do_log('info',
            'LAST %s from %s refused, archive file %s not found',
            $which, $sender, $file);
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
                tools::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'LAST %s from %s refused (not allowed)',
            $which, $sender);
        return 'not_allowed';
    }

    unless ($list->archive_send_last($sender)) {
        Sympa::Report::reject_report_cmd(
            'intern',
            "Unable to send archive to $sender",
            {'listname' => $which},
            $cmd_line, $sender, $robot
        );
        return 'no_archive';
    }

    Log::do_log('info', 'LAST %s from %s accepted (%d seconds)',
        $which, $sender, time - $time_command);

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
    Log::do_log('debug', '(%s, %s, %s, %s)', @_);
    my $which    = shift;
    my $robot    = shift;
    my $sign_mod = shift;
    my $message  = shift;

    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        Log::do_log('info',
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
                tools::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'INDEX %s from %s refused (not allowed)',
            $which, $sender);
        return 'not_allowed';
    }

    unless ($list->is_archived()) {
        Sympa::Report::reject_report_cmd('user', 'empty_archives', {},
            $cmd_line);
        Log::do_log('info', 'INDEX %s from %s refused, list not archived',
            $which, $sender);
        return 'no_archive';
    }

    my @l = $list->archive_ls();
    unless (
        tools::send_file(
            $list, 'index_archive', $sender,
            {'archives' => \@l, 'auto_submitted' => 'auto-replied'}
        )
        ) {
        Log::do_log('notice', 'Unable to send template "index_archive" to %s',
            $sender);
        Sympa::Report::reject_report_cmd('intern_quiet', '',
            {'listname' => $list->{'name'}},
            $cmd_line, $sender, $robot);
    }

    Log::do_log('info', 'INDEX %s from %s accepted (%d seconds)',
        $which, $sender, time - $time_command);

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

    Log::do_log('debug', '(%s, %s, %s)', $listname, $robot, $sign_mod);
    my $sympa = Conf::get_robot_conf($robot, 'sympa');

    my $user;
    my $list = Sympa::List->new($listname, $robot);

    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        Log::do_log('info',
            'REVIEW %s from %s refused, list unknown to robot %s',
            $listname, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    $list->on_the_fly_sync_include('use_ttl' => 1);

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
        Log::do_log('debug2', 'Auth requested from %s', $sender);
        unless (tools::request_auth($list, $sender, 'review')) {
            my $error =
                "Unable to request authentification for command 'review'";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $listname},
                $cmd_line, $sender, $robot);
            return undef;
        }
        Log::do_log('info', 'REVIEW %s from %s, auth requested (%d seconds)',
            $listname, $sender, time - $time_command);
        return 1;
    }
    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                tools::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'Review %s from %s refused (not allowed)',
            $listname, $sender);
        return 'not_allowed';
    }

    my @users;

    if ($action =~ /do_it/i) {
        my $is_owner = $list->am_i('owner', $sender);
        unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
            Sympa::Report::reject_report_cmd('user', 'no_subscriber',
                {'listname' => $listname}, $cmd_line);
            Log::do_log('err', 'No subscribers in list "%s"',
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
            tools::send_file(
                $list, 'review', $sender,
                {   'users'   => \@users,
                    'total'   => $list->get_total(),
                    'subject' => "REVIEW $listname",    # Compat <= 6.1.17.
                    'auto_submitted' => 'auto-replied'
                }
            )
            ) {
            Log::do_log('notice', 'Unable to send template "review" to %s',
                $sender);
            Sympa::Report::reject_report_cmd('intern_quiet', '',
                {'listname' => $listname},
                $cmd_line, $sender, $robot);
        }

        Log::do_log('info', 'REVIEW %s from %s accepted (%d seconds)',
            $listname, $sender, time - $time_command);
        return 1;
    }
    Log::do_log('info',
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
    Log::do_log('debug2', '(%s, %s)', @_);
    my $listname = shift;
    my $robot    = shift;
    my $sign_mod = shift;

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        Log::do_log('info',
            'VERIFY from %s refused, unknown list for robot %s',
            $sender, $robot);
        return 'unknown_list';
    }

    my $user;

    $language->set_lang($list->{'admin'}{'lang'});

    if ($sign_mod) {
        Log::do_log(
            'info',  'VERIFY successfull from %s',
            $sender, time - $time_command
        );
        if ($sign_mod eq 'smime') {
            ##$auth_method='smime';
            Sympa::Report::notice_report_cmd('smime', {}, $cmd_line);
        } elsif ($sign_mod eq 'dkim') {
            ##$auth_method='dkim';
            Sympa::Report::notice_report_cmd('dkim', {}, $cmd_line);
        }
    } else {
        Log::do_log('info',
            'VERIFY from %s: could not find correct S/MIME signature',
            $sender, time - $time_command);
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
        $what, $robot, $sign_mod, $message);

    $what =~ /^(\S+)(\s+(.+))?\s*$/;
    my ($which, $comment) = ($1, $3);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $which}, $cmd_line);
        Log::do_log('info',
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

    Log::do_log('debug2', 'Action: %s', $action);

    if ($action =~ /reject/i) {
        if (defined $result->{'tt2'}) {
            unless (
                tools::send_file(
                    $list, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'SUB %s from %s refused (not allowed)',
            $which, $sender);
        return 'not_allowed';
    }

    ## Unless rejected by scenario, don't go further if the user is subscribed
    ## already.
    my $user_entry = $list->get_list_member($sender);
    if (defined($user_entry)) {
        Sympa::Report::reject_report_cmd('user', 'already_subscriber',
            {'email' => $sender, 'listname' => $list->{'name'}}, $cmd_line);
        Log::do_log(
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
                    'keyauth' => tools::compute_auth($list, $sender, 'add'),
                    'replyto' => Conf::get_robot_conf($robot, 'sympa'),
                    'gecos'   => $comment
                }
            )
            ) {
            #FIXME: Why is error reported only in this case?
            Log::do_log('info',
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
        if ($list->store_subscription_request($sender, $comment)) {
            Log::do_log(
                'info',
                'SUB %s from %s forwarded to the owners of the list (%d seconds)',
                $which,
                $sender,
                time - $time_command
            );
        }
        return 1;
    }
    if ($action =~ /request_auth/i) {
        my $cmd = 'subscribe';
        $cmd = "quiet $cmd" if $quiet;
        unless (tools::request_auth($list, $sender, $cmd, $comment)) {
            my $error =
                "Unable to request authentification for command 'subscribe'";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }
        Log::do_log('info', 'SUB %s from %s, auth requested (%d seconds)',
            $which, $sender, time - $time_command);
        return 1;
    }
    if ($action =~ /do_it/i) {

        my $user_entry = $list->get_list_member($sender);

        if (defined $user_entry) {

            ## Only updates the date
            ## Options remain the same
            my $user = {};
            $user->{'update_date'} = time;
            $user->{'gecos'}       = $comment if $comment;
            $user->{'subscribed'}  = 1;

            unless ($list->update_list_member($sender, $user)) {
                my $error = sprintf "Unable to update user %s in list %s",
                    $user, $list->{'name'};
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
                Log::do_log('notice', 'Unable to send "welcome" probe to %s',
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
        Log::do_log(
            'info', 'SUB %s from %s accepted (%d seconds, %d subscribers)',
            $which, $sender, time - $time_command,
            $list->get_total()
        );

        return 1;
    }

    Log::do_log('info',
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
        $listname, $robot, $sign_mod, $message);

    my $sympa = Conf::get_robot_conf($robot, 'sympa');

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $listname}, $cmd_line);
        Log::do_log('info',
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
            unless (tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'Review %s from %s refused (not allowed)',
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

        unless (tools::send_file($list, 'info_report', $sender, $data)) {
            Log::do_log('notice',
                'Unable to send template "info_report" to %s', $sender);
            Sympa::Report::reject_report_cmd('intern_quiet', '',
                {'listname' => $list->{'name'}},
                $cmd_line, $sender, $robot);
        }

        Log::do_log('info', 'INFO %s from %s accepted (%d seconds)',
            $listname, $sender, time - $time_command);
        return 1;
    }

    Log::do_log('info',
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
        $which, $robot, $sign_mod, $message);

    my ($email, $l, $list, $auth_method);
    my $host = Conf::get_robot_conf($robot, 'host');

    ## $email is defined if command is "unsubscribe <listname> <e-mail>"
    unless ($which =~ /^(\*|[\w\.\-]+)(\@$host)?(\s+(.+))?$/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        Log::do_log('notice', 'Command syntax error');
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
                tools::send_notify_to_listmaster(
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
        Log::do_log('info', 'SIG %s %s from %s, unknown list for robot %s',
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
            unless (tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $which}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                {'listname' => $which}, $cmd_line);
        }
        Log::do_log('info', 'SIG %s %s from %s refused (not allowed)',
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
        unless (tools::request_auth($list, $to, $cmd)) {
            my $error =
                "Unable to request authentification for command 'signoff'";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }
        Log::do_log('info', 'SIG %s from %s auth requested (%d seconds)',
            $which, $sender, time - $time_command);
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
                    'keyauth' => tools::compute_auth($list, $sender, 'del')
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
        Log::do_log(
            'info',
            'SIG %s from %s forwarded to the owners of the list (%d seconds)',
            $which,
            $sender,
            time - $time_command
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
            Log::do_log('info', 'SIG %s from %s refused, not on list',
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
                'exclude'   => ' 1',
                'parameter' => 'unsubscription'
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
            unless (tools::send_file($list, 'bye', $email, {})) {
                Log::do_log('notice', 'Unable to send template "bye" to %s',
                    $email);
            }
        }

        Log::do_log(
            'info', 'SIG %s from %s accepted (%d seconds, %d subscribers)',
            $which, $email, time - $time_command,
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
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
        Log::do_log('info',
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
            unless (tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $which}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                {'listname' => $which}, $cmd_line);
        }
        Log::do_log('info', 'ADD %s %s from %s refused (not allowed)',
            $which, $email, $sender);
        return 'not_allowed';
    }

    if ($action =~ /request_auth/i) {
        my $cmd = 'add';
        $cmd = "quiet $cmd" if $quiet;
        unless (tools::request_auth($list, $sender, $cmd, $email, $comment)) {
            my $error =
                "Unable to request authentification for command 'add'";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }
        Log::do_log('info', 'ADD %s from %s, auth requested(%d seconds)',
            $which, $sender, time - $time_command);
        return 1;
    }
    if ($action =~ /do_it/i) {
        if ($list->is_list_member($email)) {
            Sympa::Report::reject_report_cmd('user', 'already_subscriber',
                {'email' => $email, 'listname' => $which}, $cmd_line);
            Log::do_log(
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

            $list->delete_subscription_request($email);
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
                Log::do_log('notice', 'Unable to send "welcome" probe to %s',
                    $email);
            }
        }

        Log::do_log(
            'info',
            'ADD %s %s from %s accepted (%d seconds, %d subscribers)',
            $which,
            $email,
            $sender,
            time - $time_command,
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
    Log::do_log('info',
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
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
        Log::do_log('info',
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
            unless (tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'}, {},
                $cmd_line);
        }
        Log::do_log('info', 'INVITE %s %s from %s refused (not allowed)',
            $which, $email, $sender);
        return 'not_allowed';
    }

    if ($action =~ /request_auth/i) {
        unless (
            tools::request_auth($list, $sender, 'invite', $email, $comment)) {
            my $error =
                "Unable to request authentification for command 'invite'";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            return undef;
        }

        Log::do_log('info', 'INVITE %s from %s, auth requested (%d seconds)',
            $which, $sender, time - $time_command);
        return 1;
    }
    if ($action =~ /do_it/i) {
        if ($list->is_list_member($email)) {
            Sympa::Report::reject_report_cmd('user', 'already_subscriber',
                {'email' => $email, 'listname' => $which}, $cmd_line);
            Log::do_log(
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
                my $keyauth = tools::compute_auth($list, $email, 'subscribe');
                my $command = "auth $keyauth sub $which $comment";
                $context{'subject'} = $command;
                $context{'url'}     = "mailto:$sympa?subject=$command";
                $context{'url'} =~ s/\s/%20/g;
                unless (tools::send_file($list, 'invite', $email, \%context))
                {
                    Log::do_log('notice',
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
                Log::do_log(
                    'info',
                    'INVITE %s %s from %s accepted, auth requested (%d seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    time - $time_command,
                    $list->get_total()
                );
                Sympa::Report::notice_report_cmd('invite',
                    {'email' => $email, 'listname' => $which}, $cmd_line);

            } elsif ($action !~ /reject/i) {
                $context{'subject'} = "sub $which $comment";
                $context{'url'} = "mailto:$sympa?subject=$context{'subject'}";
                $context{'url'} =~ s/\s/%20/g;
                unless (tools::send_file($list, 'invite', $email, \%context))
                {
                    Log::do_log('notice',
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
                Log::do_log(
                    'info',
                    'INVITE %s %s from %s accepted, (%d seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    time - $time_command,
                    $list->get_total()
                );
                Sympa::Report::notice_report_cmd('invite',
                    {'email' => $email, 'listname' => $which}, $cmd_line);

            } elsif ($action =~ /reject/i) {
                Log::do_log(
                    'info',
                    'INVITE %s %s from %s refused, not allowed (%d seconds, %d subscribers)',
                    $which,
                    $email,
                    $sender,
                    time - $time_command,
                    $list->get_total()
                );
                if (defined $result->{'tt2'}) {
                    unless (
                        tools::send_file(
                            $list, $result->{'tt2'}, $sender, {}
                        )
                        ) {
                        Log::do_log('notice',
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
    Log::do_log('info',
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
        $which, $robot, $sign_mod, $message);

    my $host = Conf::get_robot_conf($robot, 'host');

    my %context;

    unless ($which =~ /^(\*|[\w\.\-]+)(\@$host)?\s*$/) {
        Sympa::Report::reject_report_cmd('user', 'error_syntax', {},
            $cmd_line);
        Log::do_log('notice', 'Command syntax error');
        return 'syntax_error';
    }

    my $listname = $1;
    my $list;

    unless ($listname eq '*') {
        $list = Sympa::List->new($listname, $robot);
        unless ($list) {
            Sympa::Report::reject_report_cmd('user', 'no_existing_list',
                {'listname' => $which}, $cmd_line);
            Log::do_log('info',
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
        Log::do_log('info', 'Remind for list %s from %s refused',
            $listname, $sender);
        if (defined $result->{'tt2'}) {
            unless (tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
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
        Log::do_log('debug2', 'Auth requested from %s', $sender);
        if ($listname eq '*') {
            unless (tools::request_auth('*', $sender, 'remind')) {
                my $error =
                    "Unable to request authentification for command 'remind'";
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $listname},
                    $cmd_line, $sender, $robot);
                return undef;
            }
        } else {
            unless (tools::request_auth($list, $sender, 'remind')) {
                my $error =
                    "Unable to request authentification for command 'remind'";
                Sympa::Report::reject_report_cmd('intern', $error,
                    {'listname' => $listname},
                    $cmd_line, $sender, $robot);
                return undef;
            }
        }
        Log::do_log('info', 'REMIND %s from %s, auth requested (%d seconds)',
            $listname, $sender, time - $time_command);
        return 1;
    } elsif ($action =~ /do_it/i) {

        if ($listname ne '*') {

            unless ($list) {
                Sympa::Report::reject_report_cmd('user', 'no_existing_list',
                    {'listname' => $listname}, $cmd_line);
                Log::do_log('info',
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
                    Log::do_log('notice',
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
            Log::do_log(
                'info',
                'REMIND %s from %s accepted, sent to %d subscribers (%d seconds)',
                $listname,
                $sender,
                $total,
                time - $time_command
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
                        tools::send_notify_to_listmaster(
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

                        Log::do_log('debug2', 'REMIND *: %s subscriber of %s',
                            $email, $listname);
                        $count++;
                    }
                } while ($user = $list->get_next_list_member());
            }
            Log::do_log('debug2', 'Sending REMIND * to %d users', $count);

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
                    tools::send_file(
                        $robot, 'global_remind', $email, \%context
                    )
                    ) {
                    Log::do_log('notice',
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
        Log::do_log(
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
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
        Log::do_log('info',
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
            unless (tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                Log::do_log('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                    {'listname' => $which}, $cmd_line);
            }
        } else {
            Sympa::Report::reject_report_cmd('auth', $result->{'reason'},
                {'listname' => $which}, $cmd_line);
        }
        Log::do_log('info', 'DEL %s %s from %s refused (not allowed)',
            $which, $who, $sender);
        return 'not_allowed';
    }
    if ($action =~ /request_auth/i) {
        my $cmd = 'del';
        $cmd = "quiet $cmd" if $quiet;
        unless (tools::request_auth($list, $sender, $cmd, $who)) {
            my $error =
                "Unable to request authentification for command 'del'";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which, 'list' => $list},
                $cmd_line, $sender, $robot);
            return undef;
        }
        Log::do_log('info', 'DEL %s %s from %s, auth requested (%d seconds)',
            $which, $who, $sender, time - $time_command);
        return 1;
    }

    if ($action =~ /do_it/i) {
        ## Check if we know this email on the list and remove it. Otherwise
        ## just reject the message.
        my $user_entry = $list->get_list_member($who);

        unless ((defined $user_entry)) {
            Sympa::Report::reject_report_cmd('user', 'your_email_not_found',
                {'email' => $who, 'listname' => $which}, $cmd_line);
            Log::do_log('info', 'DEL %s %s from %s refused, not on list',
                $which, $who, $sender);
            return 'not_allowed';
        }

        ## Get gecos before deletion
        my $gecos = $user_entry->{'gecos'};

        ## Really delete and rewrite to disk.
        my $u;
        unless (
            $u = $list->delete_list_member(
                'users'     => [$who],
                'exclude'   => ' 1',
                'parameter' => 'deletd by admin'
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
            unless (tools::send_file($list, 'removed', $who, {})) {
                Log::do_log('notice',
                    'Unable to send template "removed" to %s', $who);
            }
        }
        Sympa::Report::notice_report_cmd('removed',
            {'email' => $who, 'listname' => $which}, $cmd_line);
        Log::do_log(
            'info',
            'DEL %s %s from %s accepted (%d seconds, %d subscribers)',
            $which,
            $who,
            $sender,
            time - $time_command,
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
    Log::do_log('info',
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

    Log::do_log('debug', '(%s, %s, %s, %s)',
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

    ## SET EACH is a synonim for SET MAIL
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
                tools::send_notify_to_listmaster(
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
        Log::do_log('info',
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
        Log::do_log('info', 'SET %s %s from %s refused, not on list',
            $which, $mode, $sender);
        return 'not allowed';
    }

    ## May set to DIGEST
    if ($mode =~ /^(digest|digestplain|summary)/ and !$list->is_digest()) {
        Sympa::Report::reject_report_cmd('user', 'no_digest',
            {'listname' => $which}, $cmd_line);
        Log::do_log('info', 'SET %s DIGEST from %s refused, no digest mode',
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
            Log::do_log('info',
                'SET %s %s from %s refused, mode not available',
                $which, $mode, $sender);
            return 'not_allowed';
        }

        my $update_mode = $mode;
        $update_mode = '' if ($update_mode eq 'mail');
        unless (
            $list->update_list_member(
                $sender, {'reception' => $update_mode, 'update_date' => time}
            )
            ) {
            my $error =
                "Failed to change subscriber '$sender' options for list $which";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            Log::do_log('info', 'SET %s %s from %s refused, update failed',
                $which, $mode, $sender);
            return 'failed';
        }

        Sympa::Report::notice_report_cmd('config_updated',
            {'listname' => $which}, $cmd_line);

        Log::do_log('info', 'SET %s %s from %s accepted (%d seconds)',
            $which, $mode, $sender, time - $time_command);
    }

    if ($mode =~ /^(conceal|noconceal)/) {
        unless (
            $list->update_list_member(
                $sender, {'visibility' => $mode, 'update_date' => time}
            )
            ) {
            my $error =
                "Failed to change subscriber '$sender' options for list $which";
            Sympa::Report::reject_report_cmd('intern', $error,
                {'listname' => $which},
                $cmd_line, $sender, $robot);
            Log::do_log('info', 'SET %s %s from %s refused, update failed',
                $which, $mode, $sender);
            return 'failed';
        }

        Sympa::Report::notice_report_cmd('config_updated',
            {'listname' => $which}, $cmd_line);
        Log::do_log('info', 'SET %s %s from %s accepted (%d seconds)',
            $which, $mode, $sender, time - $time_command);
    }
    return 1;
}

############################################################
#  distribute
############################################################
#  distributes the broadcast of a validated moderated message
#
# IN : -$what (+): command parameters : listname(+), authentification key(+)
#      -$robot (+): robot
#
# OUT : 'unknown_list'|'msg_noty_found'| 1 | undef
#
##############################################################
sub distribute {
    my $what  = shift;
    my $robot = shift;

    $what =~ /^\s*(\S+)\s+(.+)\s*$/;
    my ($which, $key) = ($1, $2);
    $which =~ y/A-Z/a-z/;

    Log::do_log('debug', '(%s, %s, %s, %s)', $which, $robot, $key, $what);

    my $start_time = time;    # get the time at the beginning
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);
    unless ($list) {
        Log::do_log('info',
            'DISTRIBUTE %s %s from %s refused, unknown list for robot %s',
            $which, $key, $sender, $robot);
        Sympa::Report::reject_report_msg('user', 'list_unknown', $sender,
            {'listname' => $which},
            $robot, '', '');
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    #read the moderation queue and purge it
    my $modqueue = Conf::get_robot_conf($robot, 'queuemod');

    my $name = $list->{'name'};
    my $file;

    ## For compatibility concerns
    foreach my $list_id ($list->get_list_id(), $list->{'name'}) {
        $file = $modqueue . '/' . $list_id . '_' . $key;
        last if (-f $file);
    }

    ## if the file has been accepted by WWSympa, it's name is different.
    unless (-r $file) {
        ## For compatibility concerns
        foreach my $list_id ($list->get_list_id(), $list->{'name'}) {
            $file = $modqueue . '/' . $list_id . '_' . $key . '.distribute';
            last if (-f $file);
        }
    }

    ## Open and parse the file
    my $message = Sympa::Message->new_from_file($file, context => $list);
    unless ($message) {
        Log::do_log('err', 'Unable to create Message object %s', $file);
        Sympa::Report::reject_report_msg('user', 'unfound_message', $sender,
            {'listname' => $name, 'key' => $key},
            $robot, '', $list);
        return 'msg_not_found';
    }

    # Decrypt message.
    # If encrypted, it will be re-encrypted by succeeding process.
    $message->smime_decrypt;

    my $msg_id     = $message->{'message_id'};
    my $msg_string = $message->as_string;

    $message->add_header('X-Validation-by', $sender);

    ## Distribute the message
    my $numsmtp;
    $message->{shelved}{dkim_sign} = 1
        if Sympa::Tools::Data::is_in_array(
        $list->{'admin'}{'dkim_signature_apply_on'}, 'any')
        or Sympa::Tools::Data::is_in_array(
        $list->{'admin'}{'dkim_signature_apply_on'},
        'editor_validated_messages');

    $numsmtp = Sympa::List::distribute_msg($message);
    unless (defined $numsmtp) {
        Log::do_log('err', 'Unable to send message to list %s', $name);
        Sympa::Report::reject_report_msg('intern', '', $sender,
            {'msg_id' => $msg_id},
            $robot, $msg_string, $list);
        return undef;
    }
    unless ($numsmtp) {
        Log::do_log(
            'info',
            'Message for %s from %s accepted but all subscribers use digest, nomail or summary',
            $which,
            $sender
        );
    }
    Log::do_log(
        'info',
        'Message for %s from %s accepted (%d seconds, %d sessions, %d subscribers), message ID=%s, size=%d',
        $which,
        $sender,
        time - $start_time,
        $numsmtp,
        $list->get_total(),
        $msg_id,
        $message->{'size'}
    );

    unless ($quiet) {
        unless (
            Sympa::Report::notice_report_msg(
                'message_distributed', $sender,
                {'key' => $key, 'message' => $message}, $robot,
                $list
            )
            ) {
            Log::do_log(
                'notice',
                'Unable to send template "message_report", entry "message_distributed" to %s',
                $sender
            );
        }
    }

    Log::do_log('info', 'DISTRIBUTE %s %s from %s accepted (%d seconds)',
        $name, $key, $sender, time - $time_command);

    unlink($file);

    return 1;
}

############################################################
#  confirm
############################################################
#  confirms the authentification of a message for its
#  distribution on a list
#
# IN : -$what (+): command parameter : authentification key
#      -$robot (+): robot
#
# OUT : 'wrong_auth'|'msg_not_found'
#       | 1  | undef
#
#
############################################################
sub confirm {
    my $what  = shift;
    my $robot = shift;
    Log::do_log('debug', '(%s, %s)', $what, $robot);

    $what =~ /^\s*(\w+)\s*$/;
    my $key = $1 || '';
    my $start_time = time;    # get the time at the beginning

    my ($filename, $metadata);
    my $queueauth = Conf::get_robot_conf($robot, 'queueauth');

    unless (opendir DIR, $queueauth) {
        Log::do_log('info', 'Warning: Unable to read %s directory',
            $queueauth);
        my $string =
            sprintf
            'Unable to open directory %s to confirm message with key %s',
            $queueauth, $key;
        Sympa::Report::reject_report_msg('intern', $string, $sender, {},
            $robot, '', '');
        return undef;
    }

    # TODO: delete old file from the auth directory
    foreach my $file (grep (!/^\./, readdir(DIR))) {
        next unless $file =~ /\_$key$/i;
        $filename = $queueauth . '/' . $file;
        next unless -f $filename and -r $filename;

        $metadata = tools::unmarshal_metadata(
            $queueauth, $file,
            qr{\A([^\s\@]+)(?:\@([\w\.\-]+))?_(\w+)\z},
            [qw(localpart domainpart authkey)]
        );
        last if $metadata;
    }
    closedir DIR;

    # auth spool keeps messages only with List context.
    unless ($metadata and ref($metadata->{context}) eq 'Sympa::List') {
        Log::do_log('info', 'CONFIRM %s from %s refused, auth failed',
            $key, $sender);
        Sympa::Report::reject_report_msg('user', 'unfound_file_message',
            $sender, {'key' => $key},
            $robot, '', '');
        return 'wrong_auth';
    }

    my $message = Sympa::Message->new_from_file($filename, %$metadata);
    unless ($message) {
        Log::do_log('err', 'Unable to create Message object %s', $filename);
        Sympa::Report::reject_report_msg('user', 'wrong_format_message',
            $sender, {'key' => $key},
            $robot, '', '');
        return 'msg_not_found';
    }

    # Decrpyt message.
    # If encrypted, it will be re-encrypted by succeeding processes.
    $message->smime_decrypt;

    my $list = $message->{context};
    $language->set_lang($list->{'admin'}{'lang'});

    my $msgid      = $message->{'message_id'};
    my $msg_string = $message->as_string;

    my $result = Sympa::Scenario::request_action(
        $list, 'send', 'md5',
        {   'sender'  => $sender,
            'message' => $message,
        }
    );

    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        Log::do_log(
            'err',
            'Message %s is ignored because unable to evaluate scenario for list %s',
            $message,
            $list
        );
        Sympa::Report::reject_report_msg(
            'intern',
            'Message ignored because scenario "send" cannot be evaluated',
            $sender,
            {'msg_id' => $msgid, 'message' => $message},
            $robot,
            $msg_string,
            $list
        );
        return undef;
    }

    if ($action =~ /^editorkey(\s?,\s?(quiet))?/) {
        my $key = Sympa::List::send_confirm_to_editor($message, 'md5');

        unless (defined $key) {
            Log::do_log(
                'err',
                'Failed to moderation request %s from %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
            Sympa::Report::reject_report_msg(
                'intern',
                'The request moderation sending to moderator failed.',
                $sender,
                {'msg_id' => $msgid, 'message' => $message},
                $robot,
                $msg_string,
                $list
            );
            return undef;
        }

        Log::do_log('info',
            'Message %s with key %s for list %s from %s sent to editors',
            $message, $key, $list, $sender);

        unless ($2 eq 'quiet') {
            unless (
                Sympa::Report::notice_report_msg(
                    'moderating_message', $sender,
                    {'message' => $message}, $robot,
                    $list
                )
                ) {
                Log::do_log('notice',
                    "Commands::confirm(): Unable to send template 'message_report', entry 'moderating_message' to $sender"
                );
            }
        }
        return 1;

    } elsif ($action =~ /editor(\s?,\s?(quiet))?/) {
        my $key = Sympa::List::send_confirm_to_editor($message, 'smtp');

        unless (defined $key) {
            Log::do_log(
                'err',
                'Failed to moderation request of %s from %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
            Sympa::Report::reject_report_msg(
                'intern',
                'The request moderation sending to moderator failed.',
                $sender,
                {'msg_id' => $msgid, 'message' => $message},
                $robot,
                $msg_string,
                $list
            );
            return undef;
        }

        Log::do_log('info',
            'Message %s with key %s for list %s from %s sent to editors',
            $message, $list, $key, $sender);

        unless ($2 eq 'quiet') {
            unless (
                Sympa::Report::notice_report_msg(
                    'moderating_message', $sender,
                    {'message' => $message}, $robot,
                    $list
                )
                ) {
                Log::do_log('notice',
                    "Commands::confirm(): Unable to send template 'message_report', type 'success', entry 'moderating_message' to $sender"
                );
            }
        }
        return 1;

    } elsif ($action =~ /^reject(,(quiet))?/) {
        Log::do_log('notice',
            'Message %s for %s from %s rejected, sender not allowed',
            $message, $list, $sender);
        unless ($2 eq 'quiet') {
            if (defined $result->{'tt2'}) {
                unless (
                    tools::send_file($list, $result->{'tt2'}, $sender, {})) {
                    Log::do_log('notice',
                        "Commands::confirm(): Unable to send template '$result->{'tt2'}' to $sender"
                    );
                    Sympa::Report::reject_report_msg('auth',
                        $result->{'reason'}, $sender, {'message' => $message},
                        $robot, $msg_string, $list);
                }
            } else {
                unless (
                    Sympa::Report::reject_report_msg(
                        'auth', $result->{'reason'},
                        $sender, {'message' => $message},
                        $robot, $msg_string,
                        $list
                    )
                    ) {
                    Log::do_log('notice',
                        "Commands::confirm(): Unable to send template 'message_report', type 'auth' to $sender"
                    );
                }
            }
        }
        return undef;

    } elsif ($action =~ /^do_it/) {
        $message->add_header('X-Validation-by', $sender);

        ## Distribute the message
        my $numsmtp;
        $message->{shelved}{dkim_sign} = 1
            if Sympa::Tools::Data::is_in_array(
            $list->{'admin'}{'dkim_signature_apply_on'}, 'any')
            or Sympa::Tools::Data::is_in_array(
            $list->{'admin'}{'dkim_signature_apply_on'},
            'md5_authenticated_messages');

        $numsmtp = Sympa::List::distribute_msg($message);
        unless (defined $numsmtp) {
            Log::do_log('err', 'Unable to send message to list %s',
                $list->{'name'});
            Sympa::Report::reject_report_msg('intern', '', $sender,
                {'msg_id' => $msgid, 'message' => $message},
                $robot, $msg_string, $list);
            return undef;
        }

        unless ($quiet || ($action =~ /quiet/i)) {
            unless (
                Sympa::Report::notice_report_msg(
                    'message_confirmed', $sender,
                    {'key' => $key, 'message' => $message}, $robot,
                    $list
                )
                ) {
                Log::do_log(
                    'notice',
                    'Unable to send template "message_report", entry "message_confirmed" to %s',
                    $sender
                );
            }
        }
        Log::do_log('info',
            'CONFIRM %s from %s for list %s accepted (%d seconds)',
            $key, $sender, $list->{'name'}, time - $time_command);

        unlink($filename);

        return 1;
    }
}

############################################################
#  reject
############################################################
#  Refuse and delete  a moderated message and notify sender
#  by sending template 'reject'
#
# IN : -$what (+): command parameter : listname and authentification key
#      -$robot (+): robot
#
# OUT : 'unknown_list'|'wrong_auth'| 1 | undef
#
#
##############################################################
sub reject {
    my $what  = shift;
    my $robot = shift;
    shift;
    my $editor_msg = shift;

    Log::do_log('debug', '(%s, %s)', $what, $robot);

    $what =~ /^(\S+)\s+(.+)\s*$/;
    my ($which, $key) = ($1, $2);
    $which =~ y/A-Z/a-z/;
    my $modqueue = Conf::get_robot_conf($robot, 'queuemod');
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = Sympa::List->new($which, $robot);

    unless ($list) {
        Log::do_log('info',
            'REJECT %s %s from %s refused, unknown list for robot %s',
            $which, $key, $sender, $robot);
        Sympa::Report::reject_report_msg('user', 'list_unknown', $sender,
            {'listname' => $which},
            $robot, '', '');
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $name = "$list->{'name'}";
    my $file;

    ## For compatibility concerns
    foreach my $list_id ($list->get_list_id(), $list->{'name'}) {
        $file = $modqueue . '/' . $list_id . '_' . $key;
        last if -f $file;
    }

    unless ($file and -f $file) {
        Log::do_log('info', 'REJECT %s %s from %s refused, auth failed',
            $which, $key, $sender);
        Sympa::Report::reject_report_msg('user', 'unfound_message', $sender,
            {'key' => $key},
            $robot, '', $list);
        return 'wrong_auth';
    }

    my $message = Sympa::Message->new_from_file($file, context => $list);
    unless ($message) {
        Log::do_log('notice', 'Unable to parse message');
        Sympa::Report::reject_report_msg('intern', '', $sender, {}, $robot,
            '', $list);
        return undef;
    }

    if ($message->{'sender'}) {
        my $rejected_sender = $message->{'sender'};
        my %context;
        $context{'subject'}         = $message->{'decoded_subject'};
        $context{'rejected_by'}     = $sender;
        $context{'editor_msg_body'} = $editor_msg->body_as_string
            if $editor_msg;

        Log::do_log('debug2', 'Message %s by %s rejected sender %s',
            $context{'subject'}, $context{'rejected_by'}, $rejected_sender);

        ## Notify author of message
        unless ($quiet) {
            unless (
                tools::send_file(
                    $list, 'reject', $rejected_sender, \%context
                )
                ) {
                Log::do_log('notice',
                    'Unable to send template "reject" to %s',
                    $rejected_sender);
                Sympa::Report::reject_report_msg('intern_quiet', '', $sender,
                    {'listname' => $list->{'name'}, 'message' => $message},
                    $robot, '', $list);
            }
        }

        ## Notify list moderator
        unless (
            Sympa::Report::notice_report_msg(
                'message_rejected', $sender,
                {'key' => $key, 'message' => $message}, $robot,
                $list
            )
            ) {
            Log::do_log('err',
                "Commands::reject(): Unable to send template 'message_report', entry 'message_rejected' to $sender"
            );
        }

    }

    Log::do_log('info', 'REJECT %s %s from %s accepted (%d seconds)',
        $name, $sender, $key, time - $time_command);
    Sympa::Tools::File::remove_dir($Conf::Conf{'viewmail_dir'} . '/mod/'
            . $list->get_list_id() . '/'
            . $key);
    unlink($file);

    return 1;
}

#########################################################
#  modindex
#########################################################
#  Sends a list of current messages to moderate of a list
#  (look into spool queuemod)
#  usage :    modindex <liste>
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
    Log::do_log('debug', '(%s, %s)', $name, $robot);

    $name =~ y/A-Z/a-z/;

    my $list = Sympa::List->new($name, $robot);
    unless ($list) {
        Sympa::Report::reject_report_cmd('user', 'no_existing_list',
            {'listname' => $name}, $cmd_line);
        Log::do_log('info',
            'MODINDEX %s from %s refused, unknown list for robot %s',
            $name, $sender, $robot);
        return 'unknown_list';
    }

    $language->set_lang($list->{'admin'}{'lang'});

    my $modqueue = Conf::get_robot_conf($robot, 'queuemod');

    my $i;

    unless ($list->may_do('modindex', $sender)) {
        Sympa::Report::reject_report_cmd('auth', 'restricted_modindex', {},
            $cmd_line);
        Log::do_log('info', 'MODINDEX %s from %s refused, not allowed',
            $name, $sender);
        return 'not_allowed';
    }

    # purge the queuemod -> delete old files
    if (!opendir(DIR, $modqueue)) {
        Log::do_log('info', 'Warning: Unable to read %s directory',
            $modqueue);
    }
    my @qfile = sort grep (!/^\.+$/, readdir(DIR));
    closedir(DIR);
    my ($curlist, $moddelay);
    foreach $i (sort @qfile) {

        next if (-d "$modqueue/$i");

        $i =~ /\_(.+)$/;
        $curlist = Sympa::List->new($`, $robot);
        if ($curlist) {
            # list loaded
            if (exists $curlist->{'admin'}{'clean_delay_queuemod'}) {
                $moddelay = $curlist->{'admin'}{'clean_delay_queuemod'};
            } else {
                $moddelay =
                    Conf::get_robot_conf($robot, 'clean_delay_queuemod');
            }

            if (Sympa::Tools::File::get_mtime("$modqueue/$i") <
                (time - $moddelay * 86400)) {
                unlink("$modqueue/$i");
                Log::do_log('notice',
                    'Deleting unmoderated message %s, too old', $i);
            }
        }
    }

    opendir(DIR, $modqueue);

    my $list_id = $list->get_list_id();
    my @files = (sort grep (/^($name|$list_id)\_/, readdir(DIR)));
    closedir(DIR);
    my $n;
    my @now = localtime(time);

    ## List of messages
    my @spool;

    foreach $i (@files) {
        ## skip message already marked to be distributed using WWS
        next if ($i =~ /.distribute$/);

        ## Push message for building MODINDEX
        my $raw_msg;
        open(IN, "$modqueue\/$i");
        while (<IN>) {
            $raw_msg .= $_;
        }
        close IN;
        push @spool, $raw_msg;

        $n++;
    }

    unless ($n) {
        Sympa::Report::notice_report_cmd('no_message_to_moderate',
            {'listname' => $name}, $cmd_line);
        Log::do_log('info',
            'MODINDEX %s from %s refused, no message to moderate',
            $name, $sender);
        return 'no_file';
    }

    unless (
        tools::send_file(
            $list,
            'modindex',
            $sender,
            {   'spool' => \@spool,    #FIXME: Use msg_list.
                'total' => $n,
                'boundary1' => "==main $now[6].$now[5].$now[4].$now[3]==",
                'boundary2' => "==digest $now[6].$now[5].$now[4].$now[3]=="
            }
        )
        ) {
        Log::do_log('notice', 'Unable to send template "modindex" to %s',
            $sender);
        Sympa::Report::reject_report_cmd('intern_quiet', '',
            {'listname' => $name},
            $cmd_line, $sender, $robot);
    }

    Log::do_log('info', 'MODINDEX %s from %s accepted (%d seconds)',
        $name, $sender, time - $time_command);

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

    Log::do_log('debug', '(%s, %s, %s, %s)',
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
            tools::send_notify_to_listmaster(
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

    unless (tools::send_file($robot, 'which', $sender, $data)) {
        Log::do_log('notice', 'Unable to send template "which" to %s',
            $sender);
        Sympa::Report::reject_report_cmd('intern_quiet', '',
            {'listname' => $listname},
            $cmd_line, $sender, $robot);
    }

    Log::do_log('info', 'WHICH from %s accepted (%d seconds)',
        $sender, time - $time_command);

    return 1;
}

################ Function for authentification #######################

##########################################################
#  get_auth_method
##########################################################
# Checks the authentification and return method
# used if authentification not failed
#
# IN :-$cmd (+): current command
#     -$email (+): used to compute auth
#     -$error (+):ref(HASH) with keys :
#        -type : for message_report.tt2 parsing
#        -data : ref(HASH) for message_report.tt2 parsing
#        -msg : for Log::do_log()
#     -$sign_mod (+): 'smime'| 'dkim' | -
#     -$list : ref(List) | -
#
# OUT : 'smime'|'md5'|'dkim'|'smtp' if authentification OK, undef else
#       | undef
##########################################################
sub get_auth_method {
    Log::do_log('debug3', '(%s, %s, %s, %s, %s)', @_);
    my ($cmd, $email, $error, $sign_mod, $list) = @_;
    my $that;
    my $auth_method;

    if ($sign_mod and $sign_mod eq 'smime') {
        $auth_method = 'smime';
    } elsif ($auth ne '') {
        Log::do_log('debug', 'Auth received from %s: %s', $sender, $auth);

        my $compute;
        if (ref $list eq 'Sympa::List') {
            $compute = tools::compute_auth($list, $email, $cmd);
            $that = $list->{'domain'};    # Robot
        } else {
            $compute = tools::compute_auth('*', $email, $cmd);
            $that = '*';    # Site
        }
        if ($auth eq $compute) {
            $auth_method = 'md5';
        } else {
            Log::do_log('debug2', 'Auth should be %s', $compute);
            if ($error->{'type'} eq 'auth_failed') {
                Sympa::Report::reject_report_cmd('intern',
                    "The authentication process failed",
                    $error->{'data'}, $cmd_line, $sender, $that);
            } else {
                Sympa::Report::reject_report_cmd('user', $error->{'type'},
                    $error->{'data'}, $cmd_line);
            }
            Log::do_log('info', '%s refused, auth failed', $error->{'msg'});
            return undef;
        }
    } else {
        $auth_method = 'smtp';
        $auth_method = 'dkim' if $sign_mod and $sign_mod eq 'dkim';
    }

    return $auth_method;
}

1;
