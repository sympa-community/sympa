# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

=encoding utf-8

#=head1 NAME 
#
#I<admin.pm> - This module includes administrative function for the lists.

=head1 DESCRIPTION 

Central module for creating and editing lists.

=cut 

package Sympa::Admin;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Constants;
use Sympa::Log;

my $log = Sympa::Log->instance;

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by admin.pm 

=cut 

# Moved to: Sympa::Request::Handler::create_list::_twist().
#sub create_list_old;

# Merged to: Sympa::Request::Handler::create_automatic_list::_twist().
#sub create_list;

# Moved to: Sympa::Family::_update_list().
#sub update_list;

# Moved to: Sympa::Request::Handler::move_list::_twist().
#sub rename_list;

# Moved to: (part of) Sympa::Request::Handler::move_list::_copy().
#sub clone_list_as_empty;

# Moved to: Sympa::Request::Handler::create_list::_check_owner_defined().
#sub check_owner_defined;

#####################################################
# list_check_smtp
#####################################################
# check if the requested list exists already using
#   smtp 'rcpt to'
#
# IN  : - $name : name of the list
#       - $robot : list's robot
# OUT : - Net::SMTP object or 0
#####################################################
sub list_check_smtp {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $name  = shift;
    my $robot = shift;

    my $conf = '';
    my $smtp;
    my (@suf, @addresses);

    my $smtp_relay = Conf::get_robot_conf($robot, 'list_check_smtp');
    my $smtp_helo  = Conf::get_robot_conf($robot, 'list_check_helo')
        || $smtp_relay;
    $smtp_helo =~ s/:[-\w]+$// if $smtp_helo;
    my $suffixes = Conf::get_robot_conf($robot, 'list_check_suffixes');
    return 0
        unless $smtp_relay and $suffixes;
    my $host = Conf::get_robot_conf($robot, 'host');
    $log->syslog('debug2', '(%s, %s)', $name, $robot);
    @suf = split /\s*,\s*/, $suffixes;
    return 0 unless @suf;

    foreach my $suffix (@suf) {
        push @addresses, $name . '-' . $suffix . '@' . $host;
    }
    push @addresses, $name . '@' . $host;

    eval { require Net::SMTP; };
    if ($EVAL_ERROR) {
        $log->syslog('err',
            "Unable to use Net library, Net::SMTP required, install it (CPAN) first"
        );
        return undef;
    }
    if ($smtp = Net::SMTP->new(
            $smtp_relay,
            Hello   => $smtp_helo,
            Timeout => 30
        )
        ) {
        $smtp->mail('');
        for (@addresses) {
            $conf = $smtp->to($_);
            last if $conf;
        }
        $smtp->quit();
        return $conf;
    }
    return undef;
}

##########################################################
# install_aliases
##########################################################
# Install sendmail aliases for $list
#
# IN  : - $list : object list
#       - $robot : the list's robot ** No longer used
# OUT : - undef if not applicable or aliases not installed
#         1 (if ok) or
##########################################################
sub install_aliases {
    $log->syslog('debug', '(%s)', @_);
    my $list = shift;

    return 1
        if Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') =~
        /^none$/i;

    my $alias_manager = $Conf::Conf{'alias_manager'};
    $log->syslog('debug2', '%s add %s %s', $alias_manager, $list->{'name'},
        $list->{'admin'}{'host'});

    unless (-x $alias_manager) {
        $log->syslog('err', 'Failed to install aliases: %m');
        return undef;
    }

    #FIXME: 'host' parameter is passed to alias_manager: no 'domain'
    # parameter to determine robot.
    my $status =
        system($alias_manager, 'add', $list->{'name'},
        $list->{'admin'}{'host'}) >> 8;

    if ($status == 0) {
        $log->syslog('info', 'Aliases installed successfully');
        return 1;
    }

    if ($status == 1) {
        $log->syslog('err', 'Configuration file %s has errors',
            Conf::get_sympa_conf());
    } elsif ($status == 2) {
        $log->syslog('err',
            'Internal error: Incorrect call to alias_manager');
    } elsif ($status == 3) {
        # Won't occur
        $log->syslog('err',
            'Could not read sympa config file, report to httpd error_log');
    } elsif ($status == 4) {
        # Won't occur
        $log->syslog('err',
            'Could not get default domain, report to httpd error_log');
    } elsif ($status == 5) {
        $log->syslog('err', 'Unable to append to alias file');
    } elsif ($status == 6) {
        $log->syslog('err', 'Unable to run newaliases');
    } elsif ($status == 7) {
        $log->syslog('err',
            'Unable to read alias file, report to httpd error_log');
    } elsif ($status == 8) {
        $log->syslog('err',
            'Could not create temporay file, report to httpd error_log');
    } elsif ($status == 13) {
        $log->syslog('info', 'Some of list aliases already exist');
    } elsif ($status == 14) {
        $log->syslog('err',
            'Can not open lock file, report to httpd error_log');
    } elsif ($status == 15) {
        $log->syslog('err', 'The parser returned empty aliases');
    } else {
        $log->syslog('err', 'Unknown error %s while running alias manager %s',
            $status, $alias_manager);
    }

    return undef;
}

#########################################################
# remove_aliases
#########################################################
# Remove sendmail aliases for $list
#
# IN  : - $list : object list
#       - $robot : the list's robot  ** No longer used
# OUT : - undef if not applicable
#         1 (if ok) or
#         $aliases : concated string of alias not removed
#########################################################

sub remove_aliases {
    $log->syslog('info', '(%s)', @_);
    my $list = shift;

    return 1
        if Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') =~
        /^none$/i;

    my $status = $list->remove_aliases();
    my $suffix =
        Conf::get_robot_conf($list->{'domain'}, 'return_path_suffix');
    my $aliases;

    unless ($status == 1) {
        $log->syslog('err', 'Failed to remove aliases for list %s',
            $list->{'name'});

        ## build a list of required aliases the listmaster should install
        my $libexecdir = Sympa::Constants::LIBEXECDIR;
        $aliases = <<EOF;
#----------------- $list->{'name'}
$list->{'name'}: "$libexecdir/queue $list->{'name'}"
$list->{'name'}-request: "|$libexecdir/queue $list->{'name'}-request"
$list->{'name'}$suffix: "|$libexecdir/bouncequeue $list->{'name'}"
$list->{'name'}-unsubscribe: "|$libexecdir/queue $list->{'name'}-unsubscribe"
# $list->{'name'}-subscribe: "|$libexecdir/queue $list->{'name'}-subscribe"
EOF

        return $aliases;
    }

    $log->syslog('info', 'Aliases removed successfully');

    return 1;
}

# No longer used.
#sub check_topics;

# Moved to Sympa::Request::Handler::move_user::_twist().
#sub change_user_email;

=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier Salaun <os AT cru.fr> 

=back 

=cut 

1;
