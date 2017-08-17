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

## Note to developers:
## This corresponds to Sympa::ConfigurableObject (and Sympa::Site) package
## in trunk.

package Sympa;

use strict;
use warnings;
#use Cwd qw();
use DateTime;
use English qw(-no_match_vars);
use Scalar::Util qw();
use URI;

use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Spindle::ProcessTemplate;
use Sympa::Ticket;
use Sympa::Tools::Data;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

# Old name: List::compute_auth().
#DEPRECATED.  Reusable auth key is no longer used.
#sub compute_auth;

# Old name: List::request_auth().
# DEPRECATED.  Reusable auth keys are no longer used.
#sub request_auth;

# Old names:
# [<=6.2a] tools::get_filename()
# [6.2b] tools::search_fullpath()
# [trunk] Sympa::ConfigurableObject::get_etc_filename()
sub search_fullpath {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $that    = shift;
    my $name    = shift;
    my %options = @_;

    my (@try, $default_name);

    ## template refers to a language
    ## => extend search to default tpls
    ## FIXME: family path precedes to list path.  Is it appropriate?
    if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
        $default_name = $1 . '.tt2';
        @try =
            map { ($_ . '/' . $name, $_ . '/' . $default_name) }
            @{Sympa::get_search_path($that, %options)};
    } else {
        @try =
            map { $_ . '/' . $name }
            @{Sympa::get_search_path($that, %options)};
    }

    my @result;
    foreach my $f (@try) {
##        if (-l $f) {
##            my $realpath = Cwd::abs_path($f);    # follow symlink
##            next unless $realpath and -r $realpath;
##        } elsif (!-r $f) {
##            next;
##        }
        next unless -r $f;
        $log->syslog('debug3', 'Name: %s; file %s', $name, $f);

        if ($options{'order'} and $options{'order'} eq 'all') {
            push @result, $f;
        } else {
            return $f;
        }
    }
    if ($options{'order'} and $options{'order'} eq 'all') {
        return @result;
    }

    return undef;
}

# Old names:
# [<=6.2a] tools::make_tt2_include_path()
# [6.2b] tools::get_search_path()
# [trunk] Sympa::ConfigurableObject::get_etc_include_path()
sub get_search_path {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $that    = shift;
    my %options = @_;

    my $subdir    = $options{'subdir'};
    my $lang      = $options{'lang'};
    my $lang_only = $options{'lang_only'};

    ## Get language subdirectories.
    my $lang_dirs;
    if ($lang) {
        ## For compatibility: add old-style "locale" directory at first.
        ## Add lang itself and fallback directories.
        $lang_dirs = [
            grep {$_} (
                Sympa::Language::lang2oldlocale($lang),
                Sympa::Language::implicated_langs($lang)
            )
        ];
    }

    return [_get_search_path($that, $subdir, $lang_dirs, $lang_only)];
}

sub _get_search_path {
    my $that = shift;
    my ($subdir, $lang_dirs, $lang_only) = @_;    # shift is not used

    my @search_path;

    if (ref $that and ref $that eq 'Sympa::List') {
        my $path_list;
        my $path_family;
        @search_path = _get_search_path($that->{'domain'}, @_);

        if ($subdir) {
            $path_list = $that->{'dir'} . '/' . $subdir;
        } else {
            $path_list = $that->{'dir'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                unshift @search_path, $path_list;
            }
            unshift @search_path, map { $path_list . '/' . $_ } @$lang_dirs;
        } else {
            unshift @search_path, $path_list;
        }

        if (defined $that->get_family) {
            my $family = $that->get_family;
            if ($subdir) {
                $path_family = $family->{'dir'} . '/' . $subdir;
            } else {
                $path_family = $family->{'dir'};
            }
            if ($lang_dirs) {
                unless ($lang_only) {
                    unshift @search_path, $path_family;
                }
                unshift @search_path,
                    map { $path_family . '/' . $_ } @$lang_dirs;
            } else {
                unshift @search_path, $path_family;
            }
        }
    } elsif (ref $that and ref $that eq 'Sympa::Family') {
        my $path_family;
        @search_path = _get_search_path($that->{'robot'}, @_);

        if ($subdir) {
            $path_family = $that->{'dir'} . '/' . $subdir;
        } else {
            $path_family = $that->{'dir'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                unshift @search_path, $path_family;
            }
            unshift @search_path, map { $path_family . '/' . $_ } @$lang_dirs;
        } else {
            unshift @search_path, $path_family;
        }
    } elsif (not ref $that and $that and $that ne '*') {    # Robot
        my $path_robot;
        @search_path = _get_search_path('*', @_);

        if ($subdir) {
            $path_robot = $Conf::Conf{'etc'} . '/' . $that . '/' . $subdir;
        } else {
            $path_robot = $Conf::Conf{'etc'} . '/' . $that;
        }
        if (-d $path_robot) {
            if ($lang_dirs) {
                unless ($lang_only) {
                    unshift @search_path, $path_robot;
                }
                unshift @search_path,
                    map { $path_robot . '/' . $_ } @$lang_dirs;
            } else {
                unshift @search_path, $path_robot;
            }
        }
    } elsif (not ref $that and $that eq '*') {    # Site
        my $path_etcbindir;
        my $path_etcdir;

        if ($subdir) {
            $path_etcbindir = Sympa::Constants::DEFAULTDIR . '/' . $subdir;
            $path_etcdir    = $Conf::Conf{'etc'} . '/' . $subdir;
        } else {
            $path_etcbindir = Sympa::Constants::DEFAULTDIR;
            $path_etcdir    = $Conf::Conf{'etc'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                @search_path = (
                    (map { $path_etcdir . '/' . $_ } @$lang_dirs),
                    $path_etcdir,
                    (map { $path_etcbindir . '/' . $_ } @$lang_dirs),
                    $path_etcbindir
                );
            } else {
                @search_path = (
                    (map { $path_etcdir . '/' . $_ } @$lang_dirs),
                    (map { $path_etcbindir . '/' . $_ } @$lang_dirs)
                );
            }
        } else {
            @search_path = ($path_etcdir, $path_etcbindir);
        }
    } else {
        die 'bug in logic.  Ask developer';
    }

    return @search_path;
}

# Default diagnostic messages taken from IANA registry:
# http://www.iana.org/assignments/smtp-enhanced-status-codes/
# They should be modified to fit in Sympa.
my %diag_messages = (
    'default' => 'Other undefined Status',
    # success
    '2.1.5' => 'Destination address valid',
    # no available family, dynamic list creation failed, etc.
    '4.2.1' => 'Mailbox disabled, not accepting messages',
    # no subscribers in dynamic list
    '4.2.4' => 'Mailing list expansion problem',
    # unknown list address
    '5.1.1' => 'Bad destination mailbox address',
    # unknown robot
    '5.1.2' => 'Bad destination system address',
    # too large
    '5.2.3' => 'Message length exceeds administrative limit',
    # could not store message into spool or mailer
    '5.3.0' => 'Other or undefined mail system status',
    # misconfigured family list
    '5.3.5' => 'System incorrectly configured',
    # loop detected
    '5.4.6' => 'Routing loop detected',
    # message contains commands
    '5.6.0' => 'Other or undefined media error',
    # no command found in message
    '5.6.1' => 'Media not supported',
    # failed to personalize (merge_feature)
    '5.6.5' => 'Conversion Failed',
    # virus found
    '5.7.0' => 'Other or undefined security status',
    # message is not authorized and is rejected
    '5.7.1' => 'Delivery not authorized, message refused',
    # failed to re-encrypt decrypted message
    '5.7.5' => 'Cryptographic failure',
);

# Old names: tools::send_dsn(), Sympa::ConfigurableObject::send_dsn().
sub send_dsn {
    my $that    = shift;
    my $message = shift;
    my $param   = shift || {};
    my $status  = shift;
    my $diag    = shift;

    unless (Scalar::Util::blessed($message)
        and $message->isa('Sympa::Message')) {
        $log->syslog('err', 'object %s is not Message', $message);
        return undef;
    }

    my $sender;
    if (defined($sender = $message->{'envelope_sender'})) {
        ## Won't reply to message with null envelope sender.
        return 0 if $sender eq '<>';
    } elsif (!defined($sender = $message->{'sender'})) {
        $log->syslog('err', 'No sender found');
        return undef;
    }

    $param->{listname} ||= $message->{localpart};
    if (ref $that eq 'Sympa::List') {
        $param->{recipient} ||=
            $param->{listname} . '@' . $that->{'admin'}{'host'};
        $status ||= '5.1.1';

        if ($status eq '5.2.3') {
            my $max_size = $that->{'admin'}{'max_size'};
            $param->{msg_size} = int($message->{'size'} / 1024);
            $param->{max_size} = int($max_size / 1024);
        }
    } elsif (!ref $that and $that and $that ne '*') {
        $param->{recipient} ||=
            $param->{listname} . '@' . Conf::get_robot_conf($that, 'host');
        $status ||= '5.1.1';
    } elsif ($that eq '*') {
        $param->{recipient} ||=
            $param->{listname} . '@' . $Conf::Conf{'host'};
        $status ||= '5.1.2';
    } else {
        die 'bug in logic.  Ask developer';
    }

    # Diagnostic message.
    $diag ||= $diag_messages{$status} || $diag_messages{'default'};
    # Delivery result, "failed" or "delivered".
    my $action = (index($status, '2') == 0) ? 'delivered' : 'failed';

    # Attach original (not decrypted) content.
    my $msg_string = $message->as_string(original => 1);
    $msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;
    my $header =
        ($msg_string =~ /\A\r?\n/)
        ? ''
        : [split /(?<=\n)\r?\n/, $msg_string, 2]->[0];

    my $date =
        (eval { DateTime->now(time_zone => 'local') } || DateTime->now)
        ->strftime('%a, %{day} %b %Y %H:%M:%S %z');

    my $spindle = Sympa::Spindle::ProcessTemplate->new(
        context  => $that,
        template => 'delivery_status_notification',
        rcpt     => $sender,
        data     => {
            %$param,
            'to'              => $sender,
            'date'            => $date,
            'msg'             => $msg_string,
            'header'          => $header,
            'auto_submitted'  => 'auto-replied',
            'action'          => $action,
            'status'          => $status,
            'diagnostic_code' => $diag,
        },
        # Set envelope sender.  DSN _must_ have null envelope sender.
        envelope_sender => '<>',
    );
    unless ($spindle and $spindle->spin and $spindle->{finish} eq 'success') {
        $log->syslog('err', 'Unable to send DSN to %s', $sender);
        return undef;
    }

    return 1;
}

# Old name: List::send_file() and List::send_global_file().
sub send_file {
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $that    = shift;
    my $tpl     = shift;
    my $who     = shift;
    my $context = shift || {};
    my %options = @_;

    my $spindle = Sympa::Spindle::ProcessTemplate->new(
        context  => $that,
        template => $tpl,
        rcpt     => $who,
        data     => $context,
        %options
    );
    unless ($spindle and $spindle->spin and $spindle->{finish} eq 'success') {
        $log->syslog('err', 'Could not send template %s to %s', $tpl, $who);
        return undef;
    }

    return 1;
}

# Old name: List::send_notify_to_listmaster()
sub send_notify_to_listmaster {
    $log->syslog('debug2', '(%s, %s, %s)', @_) unless $_[1] eq 'logs_failed';
    my $that      = shift;
    my $operation = shift;
    my $data      = shift;

    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $list->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my @listmasters = Sympa::get_listmasters_email($that);
    my $to = Sympa::get_address($robot_id, 'listmaster');

    if (ref $data ne 'HASH' and ref $data ne 'ARRAY') {
        die
            'Error on incoming parameter "$data", it must be a ref on HASH or a ref on ARRAY';
    }

    if (ref $data ne 'HASH') {
        my $d = {};
        foreach my $i ((0 .. $#{$data})) {
            $d->{"param$i"} = $data->[$i];
        }
        $data = $d;
    }

    $data->{'to'}             = $to;
    $data->{'type'}           = $operation;
    $data->{'auto_submitted'} = 'auto-generated';

    my @tosend;

    if ($operation eq 'no_db' or $operation eq 'db_restored') {
        $data->{'db_name'} = Conf::get_robot_conf($robot_id, 'db_name');
    }

    if (   $operation eq 'request_list_creation'
        or $operation eq 'request_list_renaming') {
        foreach my $email (@listmasters) {
            my $cdata = Sympa::Tools::Data::dup_var($data);
            $cdata->{'one_time_ticket'} =
                Sympa::Ticket::create($email, $robot_id, 'get_pending_lists',
                $cdata->{'ip'});
            push @tosend,
                {
                email => $email,
                data  => $cdata
                };
        }
    } else {
        push @tosend,
            {
            email => [@listmasters],
            data  => $data
            };
    }

    foreach my $ts (@tosend) {
        my $email = $ts->{'email'};
        # Skip DB access because DB is not accessible
        $email = [$email]
            if not ref $email
            and ($operation eq 'missing_dbd'
            or $operation eq 'no_db'
            or $operation eq 'db_restored');

        my $spindle = Sympa::Spindle::ProcessTemplate->new(
            context  => $that,
            template => 'listmaster_notification',
            rcpt     => $email,
            data     => $ts->{'data'},

            splicing_to => ['Sympa::Spindle::ToAlarm'],
        );
        unless ($spindle
            and $spindle->spin
            and $spindle->{finish} eq 'success') {
            $log->syslog(
                'notice',
                'Unable to send template "listmaster_notification" to %s listmaster %s',
                $robot_id,
                $ts->{'email'}
            ) unless $operation eq 'logs_failed';
            return undef;
        }
    }

    return 1;
}

sub send_notify_to_user {
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $that      = shift;
    my $operation = shift;
    my $user      = shift;
    my $param     = shift || {};

    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $list->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    $param->{'auto_submitted'} = 'auto-generated';

    die 'Missing parameter "operation"' unless $operation;
    die 'missing parameter "user"'      unless $user;

    if (ref $param eq "HASH") {
        $param->{'to'}   = $user;
        $param->{'type'} = $operation;

        if ($operation eq 'ticket_to_family_signoff') {
            $param->{one_time_ticket} =
                Sympa::Ticket::create($user, $robot_id,
                'family_signoff/' . $param->{family} . '/' . $user,
                $param->{ip})
                or return undef;
        }

        unless (Sympa::send_file($that, 'user_notification', $user, $param)) {
            $log->syslog('notice',
                'Unable to send template "user_notification" to %s', $user);
            return undef;
        }
    } elsif (ref $param eq "ARRAY") {
        my $data = {
            'to'   => $user,
            'type' => $operation
        };

        for my $i (0 .. $#{$param}) {
            $data->{"param$i"} = $param->[$i];
        }
        unless (Sympa::send_file($that, 'user_notification', $user, $data)) {
            $log->syslog('notice',
                'Unable to send template "user_notification" to %s', $user);
            return undef;
        }
    } else {
        $log->syslog(
            'err',
            'error on incoming parameter "%s", it must be a ref on HASH or a ref on ARRAY',
            $param
        );
        return undef;
    }
    return 1;
}

sub best_language {
    my $that = shift;
    my $accept_string = join ',', grep { $_ and $_ =~ /\S/ } @_;
    $accept_string ||= $ENV{HTTP_ACCEPT_LANGUAGE} || '*';

    my @supported_languages;
    my %supported_languages;
    my @langs = ();
    my $lang;

    if (ref $that eq 'Sympa::List') {
        @supported_languages =
            Sympa::get_supported_languages($that->{'domain'});
        $lang = $that->{'admin'}{'lang'};
    } elsif (!ref $that) {
        @supported_languages = Sympa::get_supported_languages($that || '*');
        $lang = Conf::get_robot_conf($that || '*', 'lang');
    } else {
        die 'bug in logic.  Ask developer';
    }
    %supported_languages = map { $_ => 1 } @supported_languages;
    push @langs, $lang
        if $supported_languages{$lang};

    if (ref $that eq 'Sympa::List') {
        my $lang = Conf::get_robot_conf($that->{'domain'}, 'lang');
        push @langs, $lang
            if $supported_languages{$lang} and !grep { $_ eq $lang } @langs;
    }
    if (ref $that eq 'Sympa::List' or !ref $that and $that and $that ne '*') {
        my $lang = $Conf::Conf{'lang'};
        push @langs, $lang
            if $supported_languages{$lang} and !grep { $_ eq $lang } @langs;
    }
    foreach my $lang (@supported_languages) {
        push @langs, $lang
            if !grep { $_ eq $lang } @langs;
    }

    return Sympa::Language::negotiate_lang($accept_string, @langs) || $lang;
}

#FIXME: Inefficient.  Would be cached.
#FIXME: Would also accept Sympa::List object.
# Old name: [trunk] Sympa::Site::supported_languages().
sub get_supported_languages {
    my $robot = shift;

    my @lang_list = ();
    if (%Conf::Conf) {    # configuration loaded.
        my $supported_lang;

        if ($robot and $robot ne '*') {
            $supported_lang = Conf::get_robot_conf($robot, 'supported_lang');
        } else {
            $supported_lang = $Conf::Conf{'supported_lang'};
        }

        my $language = Sympa::Language->instance;
        $language->push_lang;
        @lang_list =
            grep { $_ and $_ = $language->set_lang($_) }
            split /[\s,]+/, $supported_lang;
        $language->pop_lang;
    }
    @lang_list = ('en') unless @lang_list;
    return @lang_list if wantarray;
    return \@lang_list;
}

sub get_address {
    my $that = shift || '*';
    my $type = shift || '';

    if (ref $that eq 'Sympa::List') {
        unless ($type) {
            return $that->{'name'} . '@' . $that->{'admin'}{'host'};
        } elsif ($type eq 'owner') {
            return
                  $that->{'name'}
                . '-request' . '@'
                . $that->{'admin'}{'host'};
        } elsif ($type eq 'editor') {
            return
                  $that->{'name'}
                . '-editor' . '@'
                . $that->{'admin'}{'host'};
        } elsif ($type eq 'return_path') {
            return $that->{'name'}
                . Conf::get_robot_conf($that->{'domain'},
                'return_path_suffix')
                . '@'
                . $that->{'admin'}{'host'};
        } elsif ($type eq 'subscribe') {
            return
                  $that->{'name'}
                . '-subscribe' . '@'
                . $that->{'admin'}{'host'};
        } elsif ($type eq 'unsubscribe') {
            return
                  $that->{'name'}
                . '-unsubscribe' . '@'
                . $that->{'admin'}{'host'};
        } elsif ($type eq 'sympa' or $type eq 'listmaster') {
            # robot address, for convenience.
            return Sympa::get_address($that->{'domain'}, $type);
        }
    } elsif (ref $that eq 'Sympa::Family') {
        # robot address, for convenience.
        return Sympa::get_address($that->{'robot'}, $type);
    } else {
        unless ($type) {
            return Conf::get_robot_conf($that, 'email') . '@'
                . Conf::get_robot_conf($that, 'host');
        } elsif ($type eq 'sympa') {    # same as above, for convenience
            return Conf::get_robot_conf($that, 'email') . '@'
                . Conf::get_robot_conf($that, 'host');
        } elsif ($type eq 'owner' or $type eq 'request') {
            return
                  Conf::get_robot_conf($that, 'email')
                . '-request' . '@'
                . Conf::get_robot_conf($that, 'host');
        } elsif ($type eq 'listmaster') {
            return Conf::get_robot_conf($that, 'listmaster_email') . '@'
                . Conf::get_robot_conf($that, 'host');
        } elsif ($type eq 'return_path') {
            return
                  Conf::get_robot_conf($that, 'email')
                . Conf::get_robot_conf($that, 'return_path_suffix') . '@'
                . Conf::get_robot_conf($that, 'host');
        }
    }

    $log->syslog('err', 'Unknown type of address "%s" for %s', $type, $that);
    return undef;
}

# Old names:
# [6.2b] Conf::get_robot_conf(..., 'listmasters'), $Conf::Conf{'listmasters'}.
# [trunk] Site::listmasters().
sub get_listmasters_email {
    my $that = shift;

    my $listmaster;
    if (ref $that eq 'Sympa::List') {
        $listmaster = Conf::get_robot_conf($that->{'domain'}, 'listmaster');
    } elsif (ref $that eq 'Sympa::Family') {
        $listmaster = Conf::get_robot_conf($that->{'robot'}, 'listmaster');
    } elsif (not ref($that) and $that and $that ne '*') {
        $listmaster = Conf::get_robot_conf($that, 'listmaster');
    } else {
        $listmaster = Conf::get_robot_conf('*', 'listmaster');
    }

    my @listmasters =
        grep { Sympa::Tools::Text::valid_email($_) } split /\s*,\s*/,
        $listmaster;
    # If no valid adresses found, use listmaster of site config.
    unless (@listmasters or (not ref $that and $that eq '*')) {
        $log->syslog('notice', 'Warning: No listmasters found for %s', $that);
        @listmasters = Sympa::get_listmasters_email('*');
    }

    return wantarray ? @listmasters : [@listmasters];
}

sub get_url {
    my $that    = shift;
    my $action  = shift;
    my %options = @_;

    my $robot_id =
          (ref $that eq 'Sympa::List') ? $that->{'domain'}
        : ($that and $that ne '*') ? $that
        :                            '*';
    my $option_authority = $options{authority} || 'default';

    my $base;
    if ($option_authority eq 'local') {
        my $uri = URI->new(Conf::get_robot_conf($robot_id, 'wwsympa_url'));

        # Override scheme.
        if ($ENV{HTTPS} and $ENV{HTTPS} eq 'on') {
            $uri->scheme('https');
        }

        # Try authority locally given.
        my ($host_port, $port);
        my $hostport_re = Sympa::Regexps::hostport();
        my $ipv6_re     = Sympa::Regexps::ipv6();
        unless ($host_port = $ENV{HTTP_HOST}
            and $host_port =~ /\A$hostport_re\z/) {
            # HTTP/1.0 or earlier?
            $host_port = $ENV{SERVER_NAME};
            $port      = $ENV{SERVER_PORT};
        }
        if ($host_port) {
            if ($host_port =~ /\A$ipv6_re\z/) {
                # IPv6 address not enclosed.
                $host_port = '[' . $host_port . ']';
            }
            unless ($host_port =~ /:\d+\z/) {
                $host_port .= ':'
                    . ($port ? $port : ($uri->scheme eq 'https') ? 443 : 80);
            }
            $uri->host_port($host_port);
        }

        # Override path with actual one.
        if (my $path = $ENV{SCRIPT_NAME}) {
            $uri->path($path);
        }

        $base = $uri->canonical->as_string;
    } elsif ($option_authority eq 'omit') {
        $base =
            URI->new(Conf::get_robot_conf($robot_id, 'wwsympa_url'))->path;
    } else {    # 'default'
        $base = Conf::get_robot_conf($robot_id, 'wwsympa_url');
    }

    $base .= '/nomenu' if $options{nomenu};

    if (ref $that eq 'Sympa::List') {
        $base .= '/' . ($action || 'info');
        return Sympa::Tools::Text::weburl($base,
            [$that->{'name'}, @{$options{paths} || []}], %options);
    } else {
        $base .= '/' . $action if $action;
        return Sympa::Tools::Text::weburl($base, $options{paths}, %options);
    }
}

# Old names: [6.2b-6.2.3] Sympa::Robot::is_listmaster($who, $robot_id)
sub is_listmaster {
    my $that = shift;
    my $who  = Sympa::Tools::Text::canonic_email(shift);

    return undef unless defined $who;
    return 1 if grep { lc $_ eq $who } Sympa::get_listmasters_email($that);
    return 1 if grep { lc $_ eq $who } Sympa::get_listmasters_email('*');
    return 0;
}

# Old name: tools::get_message_id().
sub unique_message_id {
    my $that = shift;

    my $domain;
    if (ref $that eq 'Sympa::List') {
        $domain = Conf::get_robot_conf($that->{'domain'}, 'domain');
    } elsif ($that and $that ne '*') {
        $domain = Conf::get_robot_conf($that, 'domain');
    } else {
        $domain = $Conf::Conf{'domain'};
    }

    return sprintf '<sympa.%d.%d.%d@%s>', time, $PID, (int rand 999), $domain;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa - Future base class of Sympa functional objects

=head1 DESCRIPTION

This module aims to be the base class for functional objects of Sympa:
Site, Robot, Family and List.

=head2 Functions

=head3 Finding config files and templates

=over 4

=item search_fullpath ( $that, $name, [ opt => val, ...] )

    # To get file name for global site
    $file = Sympa::search_fullpath('*', $name);
    # To get file name for a robot
    $file = Sympa::search_fullpath($robot_id, $name);
    # To get file name for a family
    $file = Sympa::search_fullpath($family, $name);
    # To get file name for a list
    $file = Sympa::search_fullpath($list, $name);

Look for a file in the list > robot > site > default locations.

Possible values for options:
    order     => 'all'
    subdir    => directory ending each path
    lang      => language
    lang_only => if paths without lang subdirectory would be omitted

Returns full path of target file C<I<root>/I<subdir>/I<lang>/I<name>>
or C<I<root>/I<subdir>/I<name>>.
I<root> is the location determined by target object $that.
I<subdir> and I<lang> are optional.
If C<lang_only> option is set, paths without I<lang> subdirectory is omitted.

=item get_search_path ( $that, [ opt => val, ... ] )

    # To make include path for global site
    @path = @{Sympa::get_search_path('*')};
    # To make include path for a robot
    @path = @{Sympa::get_search_path($robot_id)};
    # To make include path for a family
    @path = @{Sympa::get_search_path($family)};
    # To make include path for a list
    @path = @{Sympa::get_search_path($list)};

make an array of include path for tt2 parsing

IN :
      -$that(+) : ref(Sympa::List) | ref(Sympa::Family) | Robot | "*"
      -%options : options

Possible values for options:
    subdir    => directory ending each path
    lang      => language
    lang_only => if paths without lang subdirectory would be omitted

OUT : ref(ARRAY) of tt2 include path

=begin comment

Note:
As of 6.2b, argument $lang is recommended to be IETF language tag,
rather than locale name.

=end comment

=back

=head3 Sending Notifications

=over 4

=item send_dsn ( $that, $message,
[ { key => val, ... }, [ $status, [ $diag ] ] ] )

    # To send site-wide DSN
    Sympa::send_dsn('*', $message, {'recipient' => $rcpt},
        '5.1.2', 'Unknown robot');
    # To send DSN related to a robot
    Sympa::send_dsn($robot, $message, {'listname' => $name},
        '5.1.1', 'Unknown list');
    # To send DSN specific to a list
    Sympa::send_dsn($list, $message, {}, '2.1.5', 'Success');

Sends a delivery status notification (DSN) to SENDER
by parsing delivery_status_notification.tt2 template.

=item send_file ( $that, $tpl, $who, [ $context, [ options... ] ] )

    # To send site-global (not relative to a list or a robot)
    # message
    Sympa::send_file('*', $template, $who, ...);
    # To send global (not relative to a list, but relative to a
    # robot) message
    Sympa::send_file($robot, $template, $who, ...);
    # To send message relative to a list
    Sympa::send_file($list, $template, $who, ...);

Send a message to user(s).
Find the tt2 file according to $tpl, set up
$data for the next parsing (with $context and
configuration)
Message is signed if the list has a key and a
certificate

Note: List::send_global_file() was deprecated.

=item send_notify_to_listmaster ( $that, $operation, $data )

    # To send notify to super listmaster(s)
    Sympa::send_notify_to_listmaster('*', 'css_updated', ...);
    # To send notify to normal (per-robot) listmaster(s)
    Sympa::send_notify_to_listmaster($robot, 'web_tt2_error', ...);
    # To send notify to normal listmaster(s) of robot the list belongs to.
    Sympa::send_notify_to_listmaster($list, 'request_list_creation', ...);

Sends a notice to (super or normal) listmaster by parsing
listmaster_notification.tt2 template.

Parameters:

=over

=item $self

L<Sympa::List>, Robot or Site.

=item $operation

Notification type.

=item $param

Hashref or arrayref.
Values for template parsing.

=back

Returns:

C<1> or C<undef>.

=item send_notify_to_user ( $that, $operation, $user, $param )

Send a notice to a user (sender, subscriber or another user)
by parsing user_notification.tt2 template.

Parameters:

=over

=item $that

L<Sympa::List>, Robot or Site.

=item $operation

Notification type.

=item $user

E-mail of notified user.

=item $param

Hashref or arrayref.  Values for template parsing.

=back

Returns:

C<1> or C<undef>.

=back

=head3 Internationalization

=over

=item best_language ( LANG, ... )

    # To get site-wide best language.
    $lang = Sympa::best_language('*', 'de', 'en-US;q=0.9');
    # To get robot-wide best language.
    $lang = Sympa::best_language($robot, 'de', 'en-US;q=0.9');
    # To get list-specific best language.
    $lang = Sympa::best_language($list, 'de', 'en-US;q=0.9');

Chooses best language under the context of List, Robot or Site.
Arguments are language codes (see L<Language>) or ones with quality value.
If no arguments are given, the value of C<HTTP_ACCEPT_LANGUAGE> environment
variable will be used.

Returns language tag or, if negotiation failed, lang of object.

=item get_supported_languages ( $that )

I<Function>.
Gets supported languages, canonicalized.
In array context, returns array of supported languages.
In scalar context, returns arrayref to them.

=back

=head3 Addresses and users

These are accessors derived from configuration parameters.

=over

=item get_address ( $that, [ $type ] )

    # Get address bound for super listmaster(s).
    Sympa::get_address('*', 'listmaster');     # <listmaster@DEFAULT_HOST>
    # Get address for command robot and robot listmaster(s).
    Sympa::get_address($robot, 'sympa');       # <sympa@HOST>
    Sympa::get_address($robot, 'listmaster');  # <listmaster@HOST>
    # Get address for command robot and robot listmaster(s).
    Sympa::get_address($family, 'sympa');      # <sympa@HOST>
    Sympa::get_address($family, 'listmaster'); # listmaster@HOST>
    # Get address bound for the list and its owner(s) etc.
    Sympa::get_address($list);                 # <NAME@HOST>
    Sympa::get_address($list, 'owner');        # <NAME-request@HOST>
    Sympa::get_address($list, 'editor');       # <NAME-editor@HOST>
    Sympa::get_address($list, 'return_path');  # <NAME-owner@HOST>

Site or robot:
Returns the site or robot email address of type $type: email command address
(default, <sympa> address), "owner" (<sympa-request> address) or "listmaster".

List:
Returns the list email address of type $type: posting address (default),
"owner" (<LIST-request> address), "editor", non-VERP "return_path"
(<LIST-owner> address), "subscribe" or "unsubscribe".

Note:
%Conf::Conf or Conf::get_robot_conf() may return <sympa> and
<sympa-request> addresses by "sympa" and "request" arguments, respectively.
They are obsoleted.  Use this function instead.

=item get_listmasters_email ( $that )

    # To get addresses of super-listmasters.
    @addrs = Sympa::get_listmasters_email('*');
    # To get addresses of normal listmasters of a robot.
    @addrs = Sympa::get_listmasters_email($robot);
    # To get addresses of normal listmasters of the robot of a family.
    @addrs = Sympa::get_listmasters_email($family);
    # To get addresses of normal listmasters of the robot of a list.
    @addrs = Sympa::get_listmasters_email($list);

Gets valid email addresses of listmasters. In array context, returns array of
addresses. In scalar context, returns arrayref to them.

=item get_url ( $that, $action, [ nomenu =E<gt> 1 ], [ paths =E<gt> \@paths ],
[ authority =E<gt> $mode ],
[ options... ] )

Returns URL for web interface.

Parameters:

=over

=item $action

Name of action.
This is inserted into URL intact.

=item authority =E<gt> $mode

C<'default'> respects C<wwsympa_url> parameter.
C<'local'> is similar but may replace host name and script path.
C<'omit'> omits scheme and authority, i.e. returns relative URI.

Note that C<'local'> mode works correctly only under CGI environment.
See also a note below.

=item nomenu =E<gt> 1

Adds C<nomenu> modifier.

=item paths =E<gt> \@paths

Additional path components.
Note that they are percent-encoded as necessity.

=item options...

See L<Sympa::Tools::Text/"weburl">.

=back

Returns:

A string.

Note:
If $mode is C<'local'>, result is that Sympa server recognizes locally.
In other cases, result is the URI that is used by end users to access to web
interface.
When, for example, the server is placed behind a reverse-proxy,
C<Location:> field in HTTP response to cause redirection would be better
to contain C<'local'> URI.

=item is_listmaster ( $that, $who )

Is the user listmaster?

=item unique_message_id ( $that )

TBD

=back

=head1 SEE ALSO

L<Sympa::Site> (not yet available),
L<Sympa::Robot> (not yet available),
L<Sympa::Family>,
L<Sympa::List>.

=cut
