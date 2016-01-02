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

package Sympa::Report;

use strict;
use warnings;

use Sympa;
use Sympa::Log;

my $log = Sympa::Log->instance;

### MESSAGE DIFFUSION REPORT ###

# DEPRECATED.  Use Sympa::send_dsn().
#sub reject_report_msg;

# No longer used.
#sub _get_msg_as_hash;

# DEPRECATED.  Use Sympa::send_file($that, 'message_report').
#sub notice_report_msg;

### MAIL COMMAND REPORT ###

# for rejected command because of internal error
my @intern_error_cmd;
# for rejected command because of user error
my @user_error_cmd;
# for errors no relative to a command
my @global_error_cmd;
# for rejected command because of no authorization
my @auth_reject_cmd;
# for command notice
my @notice_cmd;

#########################################################
# init_report_cmd
#########################################################
#  init arrays for mail command reports :
#
#
# IN : -
#
# OUT : -
#
#########################################################
sub init_report_cmd {

    undef @intern_error_cmd;
    undef @user_error_cmd;
    undef @global_error_cmd;
    undef @auth_reject_cmd;
    undef @notice_cmd;
}

#########################################################
# is_there_any_report_cmd
#########################################################
#  Look for some mail command report in one of arrays report
#
# IN : -
#
# OUT : 1 if there are some reports to send
#
#########################################################
sub is_there_any_report_cmd {

    return (   @intern_error_cmd
            || @user_error_cmd
            || @global_error_cmd
            || @auth_reject_cmd
            || @notice_cmd);
}

#########################################################
# send_report_cmd
#########################################################
#  Send the template command_report to $sender
#   with global arrays :
#  @intern_error_cmd,@user_error_cmd,@global_error_cmd,
#   @auth_reject_cmd,@notice_cmd.
#
#
# IN : -$sender (+): SCALAR
#      -$robot (+): SCALAR
#
# OUT : 1 if there are some reports to send
#
#########################################################
sub send_report_cmd {
    my ($sender, $robot) = @_;

    unless ($sender) {
        $log->syslog('err',
            'Unable to send template "command_report": No user to notify');
        return undef;
    }

    unless ($robot) {
        $log->syslog('err',
            'Unable to send template "command_report": No robot');
        return undef;
    }

    # for mail layout
    my $before_auth = 0;
    $before_auth = 1 if @notice_cmd;

    my $before_user_err;
    $before_user_err = 1 if $before_auth or @auth_reject_cmd;

    my $before_intern_err;
    $before_intern_err = 1 if $before_user_err or @user_error_cmd;

    chomp($sender);

    # Ensure 1 second elapsed since last message.
    Sympa::send_file(
        $robot,
        'command_report',
        $sender,
        {   to                => $sender,
            nb_notice         => scalar(@notice_cmd),
            nb_auth           => scalar(@auth_reject_cmd),
            nb_user_err       => scalar(@user_error_cmd),
            nb_intern_err     => scalar(@intern_error_cmd),
            nb_global         => scalar(@global_error_cmd),
            before_auth       => $before_auth,
            before_user_err   => $before_user_err,
            before_intern_err => $before_intern_err,
            notices           => [@notice_cmd],
            auths             => [@auth_reject_cmd],
            user_errors       => [@user_error_cmd],
            intern_errors     => [@intern_error_cmd],
            globals           => [@global_error_cmd],
        },
        date => time + 1
    );

    init_report_cmd();
}

#########################################################
# global_report_cmd
#########################################################
#  puts global report of mail with commands in
#  @global_report_cmd  used to send message with template
#  mail_tt2/command_report.tt2
#  if $now , the template is sent now
#  if $type eq 'intern', the listmaster is notified
#
# IN : -$type (+): 'intern'||'intern_quiet||'user'
#      -$error : scalar - $glob.entry in command_report.tt2 if $type = 'user'
#                          - string error for listmaster if $type = 'intern'
#      -$data : ref(HASH) - var used in command_report.tt2
#      -$sender :  required if $type eq 'intern' or if $now
#                  scalar - the user to notify
#      -$robot :   required if $type eq 'intern' or if $now
#                  scalar - to notify useror listmaster
#      -$now : send now if true
#
# OUT : 1|| undef
#
#########################################################
sub global_report_cmd {
    my ($type, $error, $data, $sender, $robot, $now) = @_;
    my $entry;

    unless ($type eq 'intern' || $type eq 'intern_quiet' || $type eq 'user') {
        $log->syslog(
            'err',
            'Error to prepare parsing "command_report" template to %s: Not a valid error type',
            $sender
        );
        return undef;
    }

    if ($type eq 'intern') {

        if ($robot) {
            my $param = $data;
            $param ||= {};
            $param->{'error'}  = $error;
            $param->{'who'}    = $sender;
            $param->{'action'} = 'Command process';

            Sympa::send_notify_to_listmaster($robot, 'mail_intern_error',
                $param);
        } else {
            $log->syslog('notice',
                'Unable to send notify to listmaster: No robot');
        }
    }

    if ($type eq 'user') {
        $entry = $error;

    } else {
        $entry = 'intern_error';
    }

    $data ||= {};
    $data->{'entry'} = $entry;
    push @global_error_cmd, $data;

    if ($now) {
        unless ($sender && $robot) {
            $log->syslog('err',
                'Unable to send template "command_report" now: No sender or robot'
            );
            return undef;
        }
        send_report_cmd($sender, $robot);

    }
}

#########################################################
# reject_report_cmd
#########################################################
#  puts errors reports of processed commands in
#  @user/intern_error_cmd, @auth_reject_cmd
#  used to send message with template
#  mail_tt2/command_report.tt2
#  if $type eq 'intern', the listmaster is notified
#
# IN : -$type (+): 'intern'||'intern_quiet||'user'||'auth'
#      -$error : scalar - $u_err.entry in command_report.tt2 if $type = 'user'
#                       - $auth.entry in command_report.tt2 if $type = 'auth'
#                       - string error for listmaster if $type = 'intern'
#      -$data : ref(HASH) - var used in command_report.tt2
#      -$cmd : SCALAR - the rejected cmd : $xx.cmd in command_report.tt2
#      -$sender :  required if $type eq 'intern'
#                  scalar - the user to notify
#      -$list :    required if $type eq 'intern'
#                  scalar - to notify listmaster
#
# OUT : 1|| undef
#
#########################################################
sub reject_report_cmd {
    my ($type, $error, $data, $cmd, $sender, $list) = @_;

    unless ($type eq 'intern'
        || $type eq 'intern_quiet'
        || $type eq 'user'
        || $type eq 'auth') {
        $log->syslog(
            'err',
            'Error to prepare parsing "command_report" template to %s: Not a valid error type',
            $sender
        );
        return undef;
    }

    $data ||= {};
    $data->{cmd} = $cmd;
    $data->{listname} = $list->{'name'} if ref $list eq 'Sympa::List';

    if ($type eq 'intern') {
        if (ref $list eq 'Sympa::List') {
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   %$data,
                    error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
        } else {
            $log->syslog('notice',
                'Unable to notify listmaster for error: "%s": (no list)',
                $error);
        }
    }

    if ($type eq 'auth') {
        $data->{'entry'} = $error;
        push @auth_reject_cmd, $data;

    } elsif ($type eq 'user') {
        $data->{'entry'} = $error;
        push @user_error_cmd, $data;

    } else {
        $data->{'entry'} = 'intern_error';
        push @intern_error_cmd, $data;

    }

}

#########################################################
# notice_report_cmd
#########################################################
#  puts notices reports of processed commands in
#  @notice_cmd used to send message with template
#  mail_tt2/command_report.tt2
#
# IN : -$entry : $notice.entry to select string in
#               command_report.tt2
#      -$data : ref(HASH) - var used in command_report.tt2
#      -$cmd : SCALAR - the noticed cmd
#
# OUT : 1
#
#########################################################
sub notice_report_cmd {
    my ($entry, $data, $cmd, $sender, $list) = @_;

    $data ||= {};
    $data->{'cmd'}   = $cmd;
    $data->{'entry'} = $entry;
    $data->{listname} = $list->{'name'} if ref $list eq 'Sympa::List';
    push @notice_cmd, $data;
}

### WEB COMMAND REPORT ###

# for rejected web command because of internal error
my @intern_error_web;
# for rejected web command because of system error
my @system_error_web;
# for rejected web command because of user error
my @user_error_web;
# for rejected web command because of no authorization
my @auth_reject_web;
# for web command notice
my @notice_web;

#########################################################
# init_report_web
#########################################################
#  init arrays for web reports :
#
#
# IN : -
#
# OUT : -
#
#########################################################
sub init_report_web {

    undef @intern_error_web;
    undef @system_error_web;
    undef @user_error_web;
    undef @auth_reject_web;
    undef @notice_web;
}

#########################################################
# is_there_any_reject_report_web
#########################################################
#  Look for some web reports in one of web
#  arrays reject report
#
# IN : -
#
# OUT : 1 if there are some reports to send
#
#########################################################
sub is_there_any_reject_report_web {

    return (   @intern_error_web
            || @system_error_web
            || @user_error_web
            || @auth_reject_web);
}

#########################################################
# get_intern_error_web
#########################################################
#  return array of web intern error
#
# IN : -
#
# OUT : ref(ARRAY) - clone of \@intern_error_web
#
#########################################################
sub get_intern_error_web {
    my @intern_err;

    foreach my $i (@intern_error_web) {
        push @intern_err, $i;
    }
    return \@intern_err;
}

#########################################################
# get_system_error_web
#########################################################
#  return array of web system error
#
# IN : -
#
# OUT : ref(ARRAY) - clone of \@system_error_web
#
#########################################################
sub get_system_error_web {
    my @system_err;

    foreach my $i (@system_error_web) {
        push @system_err, $i;
    }
    return \@system_err;
}

#########################################################
# get_user_error_web
#########################################################
#  return array of web user error
#
# IN : -
#
# OUT : ref(ARRAY) - clone of \@user_error_web
#
#########################################################
sub get_user_error_web {
    my @user_err;

    foreach my $u (@user_error_web) {
        push @user_err, $u;
    }
    return \@user_err;
}

#########################################################
# get_auth_reject_web
#########################################################
#  return array of web authorization rejects
#
# IN : -
#
# OUT : ref(ARRAY) - clone of \@auth_reject_web
#
#########################################################
sub get_auth_reject_web {
    my @auth_rej;

    foreach my $a (@auth_reject_web) {
        push @auth_rej, $a;
    }
    return \@auth_rej;
}

#########################################################
# get_notice_web
#########################################################
#  return array of web notice
#
# IN : -
#
# OUT : ref(ARRAY) - clone of \@notice_web
#
#########################################################
sub get_notice_web {
    my @notice;

    if (@notice_web) {

        foreach my $n (@notice_web) {
            push @notice, $n;
        }
        return \@notice;

    } else {
        return 0;
    }

}

#########################################################
# notice_report_web
#########################################################
#  puts notices reports of web commands in
#  @notice_web used to notice user with template
#  web_tt2/notice.tt2
#
# IN : -$msg : $notice.msg to select string in
#               web/notice.tt2
#      -$data : ref(HASH) - var used in web_tt2/notices.tt2
#      -$action : SCALAR - the noticed action $notice.action in
#      web_tt2/notices.tt2
#
# OUT : 1
#
#########################################################
sub notice_report_web {
    my ($msg, $data, $action) = @_;

    $data ||= {};
    $data->{'action'} = $action;
    $data->{'msg'}    = $msg;
    push @notice_web, $data;

}

#########################################################
# reject_report_web
#########################################################
#  puts errors reports of web commands in
#  @intern/user/system_error_web, @auth_reject_web
#   used to send message with template  web_tt2/error.tt2
#  if $type = 'intern'||'system', the listmaster is notified
#  (with 'web_intern_error' || 'web_system_error')
#
# IN : -$type (+):
# 'intern'||'intern_quiet||'system'||'system_quiet'||user'||'auth'
#      -$error (+): scalar  - $u_err.msg in error.tt2 if $type = 'user'
#                           - $auth.msg in error.tt2 if $type = 'auth'
#                           - $s_err.msg in error.tt2 if $type =
#                           'system'||'system_quiet'
#                           - $i_err.msg in error.tt2 if $type = 'intern' ||
#                           'intern_quiet'
#                           - $error in listmaster_notification if $type =
#                           'system'||'intern'
#      -$data : ref(HASH) - var used in web_tt2/error.tt2
#      -$action(+) : SCALAR - the rejected action :
#            $xx.action in web_tt2/error.tt2
#            $action in listmaster_notification.tt2 if needed
#      -$list : ref(List) || ''
#      -$user :  required if $type eq 'intern'||'system'
#                  scalar - the concerned user to notify listmaster
#      -$robot :   required if $type eq 'intern'||'system'
#                  scalar - the robot to notify listmaster
#
# OUT : 1|| undef
#
#########################################################
sub reject_report_web {
    my ($type, $error, $data, $action, $list, $user, $robot) = @_;

    unless ($type eq 'intern'
        || $type eq 'intern_quiet'
        || $type eq 'system'
        || $type eq 'system_quiet'
        || $type eq 'user'
        || $type eq 'auth') {
        $log->syslog(
            'err',
            'Error to prepare parsing "web_tt2/error.tt2" template to %s: Not a valid error type',
            $user
        );
        return undef;
    }

    my $listname;
    if (ref($list) eq 'Sympa::List') {
        $listname = $list->{'name'};
    }

    ## Notify listmaster for internal or system errors
    if ($type eq 'intern' || $type eq 'system') {
        if ($robot) {
            my $param = $data || {};
            $param->{'error'} = $error;
            $param->{'who'}   = $user;
            $param->{'action'} ||= 'Command process';

            Sympa::send_notify_to_listmaster(($list || $robot),
                'web_' . $type . '_error', $param);
        } else {
            $log->syslog('notice',
                'Unable to notify listmaster for error: "%s": (no robot)',
                $error);
        }
    }

    $data ||= {};

    $data->{'action'}   = $action;
    $data->{'msg'}      = $error;
    $data->{'listname'} = $listname;

    if ($type eq 'auth') {
        push @auth_reject_web, $data;

    } elsif ($type eq 'user') {
        push @user_error_web, $data;

    } elsif ($type eq 'system' || $type eq 'system_quiet') {
        push @system_error_web, $data;

    } elsif ($type eq 'intern' || $type eq 'intern_quiet') {
        push @intern_error_web, $data;

    }
}

1;
