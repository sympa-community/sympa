# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::Robot;

use strict;
use warnings;
use Encode qw();

use Sympa::Auth;
use Conf;
use Sympa::Language;
#use Sympa::List;
use Log;
use Sympa::Mail;
use SDM;
use tools;
use Sympa::Tools::SMIME;
use tt2;
use Sympa::User;

# Language context
my $language = Sympa::Language->instance;

## Database and SQL statement handlers
my ($sth, @sth_stack);

our %list_of_topics = ();
## Last modification times
our %mtime;

our %listmaster_messages_stack;

# MOVED: Use tools::send_file(), or Sympa::Message::new_from_template() with
# Sympa::Mail::sending().
# sub send_global_file($tpl, $who, $robot, $context, $options);

####################################################
# send_notify_to_listmaster
####################################################
# Sends a notice to listmaster by parsing
# listmaster_notification.tt2 template
#
# IN : -$operation (+): notification type
#      -$robot (+): robot
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#
######################################################
sub send_notify_to_listmaster {
    my ($operation, $robot, $data, $checkstack, $purge) = @_;

    if ($checkstack or $purge) {
        foreach my $robot (keys %Sympa::Robot::listmaster_messages_stack) {
            foreach my $operation (
                keys %{$Sympa::Robot::listmaster_messages_stack{$robot}}) {
                my $first_age =
                    time -
                    $Sympa::Robot::listmaster_messages_stack{$robot}
                    {$operation}{'first'};
                my $last_age =
                    time -
                    $Sympa::Robot::listmaster_messages_stack{$robot}
                    {$operation}{'last'};
                # not old enough to send and first not too old
                next
                    unless ($purge or ($last_age > 30) or ($first_age > 60));
                next
                    unless ($Sympa::Robot::listmaster_messages_stack{$robot}
                    {$operation}{'messages'});

                my %messages =
                    %{$Sympa::Robot::listmaster_messages_stack{$robot}
                        {$operation}{'messages'}};
                Log::do_log(
                    'info', 'Got messages about "%s" (%s)',
                    $operation, join(', ', keys %messages)
                );

                ##### bulk send
                foreach my $email (keys %messages) {
                    my $param = {
                        to                    => $email,
                        auto_submitted        => 'auto-generated',
                        operation             => $operation,
                        notification_messages => $messages{$email},
                        boundary              => '----------=_'
                            . tools::get_message_id($robot)
                    };

                    Log::do_log('info', 'Send messages to %s', $email);

                    # Skip DB access because DB is not accessible
                    $email = [$email]
                        if not ref $email
                            and (  $operation eq 'no_db'
                                or $operation eq 'db_restored');

                    my $message =
                        Sympa::Message->new_from_template($robot,
                        'listmaster_groupednotifications',
                        $email, $param);
                    unless (
                        $message
                        and Sympa::Mail::sending(
                            $message, $email,
                            Conf::get_robot_conf($robot, 'request'),
                            priority => Conf::get_robot_conf(
                                $robot, 'sympa_priority'
                            )
                        )
                        ) {
                        Log::do_log(
                            'notice',
                            'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                            $robot,
                            $email
                        ) unless $operation eq 'logs_failed';
                        return undef;
                    }
                }

                Log::do_log('info', 'Cleaning stacked notifications');
                delete $Sympa::Robot::listmaster_messages_stack{$robot}
                    {$operation};
            }
        }
        return 1;
    }

    my $stack = 0;
    $Sympa::Robot::listmaster_messages_stack{$robot}{$operation}{'first'} =
        time
        unless ($Sympa::Robot::listmaster_messages_stack{$robot}{$operation}
        {'first'});
    $Sympa::Robot::listmaster_messages_stack{$robot}{$operation}{'counter'}++;
    $Sympa::Robot::listmaster_messages_stack{$robot}{$operation}{'last'} =
        time;
    if ($Sympa::Robot::listmaster_messages_stack{$robot}{$operation}
        {'counter'} > 3) {
        # stack if too much messages w/ same code
        $stack = 1;
    }

    Log::do_log('debug2', '(%s, %s)', $operation, $robot)
        unless $operation and $operation eq 'logs_failed';

    unless (defined $operation) {
        die 'missing incoming parameter "$operation"';
    }

    unless (defined $robot) {
        die 'missing incoming parameter "$robot"';
    }

    my $host = Conf::get_robot_conf($robot, 'host');
    my $listmaster =
        [split /\s*,\s*/, Conf::get_robot_conf($robot, 'listmaster')];
    my $to = "$Conf::Conf{'listmaster_email'}\@$host";

    if ((ref($data) ne 'HASH') and (ref($data) ne 'ARRAY')) {
        Log::do_log(
            'err',
            '(%s, %s) Error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY',
            $operation,
            $robot
        ) unless $operation eq 'logs_failed';
        return undef;
    }

    if (ref($data) ne 'HASH') {
        my $d = {};
        for my $i (0 .. $#{$data}) {
            $d->{"param$i"} = $data->[$i];
        }
        $data = $d;
    }

    $data->{'to'}             = $to;
    $data->{'type'}           = $operation;
    $data->{'auto_submitted'} = 'auto-generated';
    $data->{'alarm'}          = 1;

    if ($data->{'list'} && ref($data->{'list'}) eq 'Sympa::List') {
        my $list = $data->{'list'};
        $data->{'list'} = {
            'name'    => $list->{'name'},
            'host'    => $list->{'domain'},
            'subject' => $list->{'admin'}{'subject'},
        };
    }

    my @tosend;

    if ($operation eq 'automatic_bounce_management') {
        ## Automatic action done on bouncing addresses
        my $list = Sympa::List->new($data->{'list'}{'name'}, $robot);
        unless (defined $list) {
            Log::do_log(
                'err',
                'Parameter %s (%s) is not a valid list',
                $data->{'list'}{'name'}, $robot
            ) unless $operation eq 'logs_failed';
            return undef;
        }
        my $message = Sympa::Message->new_from_template($list,
            'listmaster_notification', $to, $data);
        unless (
            $message
            and Sympa::Mail::sending(
                $message, $listmaster,
                $list->get_list_address('return_path'),
                priority => Conf::get_robot_conf($robot, 'sympa_priority'),
                use_bulk => 1
            )
            ) {
            Log::do_log(
                'notice',
                'Unable to send template "listmaster_notification" to %s listmaster %s',
                $robot,
                $listmaster
            ) unless $operation eq 'logs_failed';
            return undef;
        }
        return 1;
    }

    if ($operation eq 'no_db' or $operation eq 'db_restored') {
        $data->{'db_name'} = Conf::get_robot_conf($robot, 'db_name');
    }

    if ($operation eq 'loop_command') {
        ## Loop detected in Sympa
        $data->{'boundary'} = '----------=_' . tools::get_message_id($robot);
        tt2::allow_absolute_path();
    }

    if (   ($operation eq 'request_list_creation')
        or ($operation eq 'request_list_renaming')) {
        foreach my $email (@$listmaster) {
            my $cdata = tools::dup_var($data);
            $cdata->{'one_time_ticket'} =
                Sympa::Auth::create_one_time_ticket($email, $robot,
                'get_pending_lists', $cdata->{'ip'});
            push @tosend,
                {
                email => $email,
                data  => $cdata
                };
        }
    } else {
        push @tosend,
            {
            email => $listmaster,
            data  => $data
            };
    }

    foreach my $ts (@tosend) {
        my $email = $ts->{'email'};
        # Skip DB access because DB is not accessible
        $email = [$email]
            if not ref $email
                and ($operation eq 'no_db' or $operation eq 'db_restored');

        my $notif_message =
            Sympa::Message->new_from_template($robot,
            'listmaster_notification', $email, $ts->{'data'});
        if ($stack) {
            Log::do_log('info', 'Stacking message about "%s" for %s (%s)',
                $operation, $ts->{'email'}, $robot)
                unless $operation eq 'logs_failed';
            push
                @{$Sympa::Robot::listmaster_messages_stack{$robot}{$operation}
                    {'messages'}{$ts->{'email'}}}, $notif_message->as_string;
            return 1;
        }
        my $r = Sympa::Mail::sending(
            $notif_message,
            $ts->{'email'},
            Conf::get_robot_conf($robot, 'request'),
            priority => Conf::get_robot_conf($robot, 'sympa_priority')
        );

        unless ($r) {
            Log::do_log(
                'notice',
                'Unable to send template "listmaster_notification" to %s listmaster %s',
                $robot,
                $listmaster
            ) unless $operation eq 'logs_failed';
            return undef;
        }
    }

    return 1;
}

## Is the user listmaster
sub is_listmaster {
    my $who   = shift;
    my $robot = shift;

    return unless $who;

    $who =~ y/A-Z/a-z/;

    foreach my $listmaster (@{Conf::get_robot_conf($robot, 'listmasters')}) {
        return 1 if (lc($listmaster) eq lc($who));
    }

    foreach my $listmaster (@{Conf::get_robot_conf('*', 'listmasters')}) {
        return 1 if (lc($listmaster) eq lc($who));
    }

    return 0;
}

## get idp xref to locally validated email address
sub get_netidtoemail_db {
    my $robot   = shift;
    my $netid   = shift;
    my $idpname = shift;
    Log::do_log('debug', '(%s, %s)', $netid, $idpname);

    my ($l, %which, $email);

    push @sth_stack, $sth;

    unless (
        $sth = SDM::do_query(
            "SELECT email_netidmap FROM netidmap_table WHERE netid_netidmap = %s and serviceid_netidmap = %s and robot_netidmap = %s",
            SDM::quote($netid),
            SDM::quote($idpname),
            SDM::quote($robot)
        )
        ) {
        Log::do_log(
            'err',
            'Unable to get email address from netidmap_table for id %s, service %s, robot %s',
            $netid,
            $idpname,
            $robot
        );
        return undef;
    }

    $email = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $email;
}

## set idp xref to locally validated email address
sub set_netidtoemail_db {
    my $robot   = shift;
    my $netid   = shift;
    my $idpname = shift;
    my $email   = shift;
    Log::do_log('debug', '(%s, %s, %s)', $netid, $idpname, $email);

    my ($l, %which);

    unless (
        SDM::do_query(
            "INSERT INTO netidmap_table (netid_netidmap,serviceid_netidmap,email_netidmap,robot_netidmap) VALUES (%s, %s, %s, %s)",
            SDM::quote($netid),
            SDM::quote($idpname),
            SDM::quote($email),
            SDM::quote($robot)
        )
        ) {
        Log::do_log(
            'err',
            'Unable to set email address %s in netidmap_table for id %s, service %s, robot %s',
            $email,
            $netid,
            $idpname,
            $robot
        );
        return undef;
    }

    return 1;
}

## Update netidmap table when user email address changes
sub update_email_netidmap_db {
    my ($robot, $old_email, $new_email) = @_;

    unless (defined $robot
        && defined $old_email
        && defined $new_email) {
        Log::do_log('err', 'Missing parameter');
        return undef;
    }

    unless (
        SDM::do_query(
            "UPDATE netidmap_table SET email_netidmap = %s WHERE (email_netidmap = %s AND robot_netidmap = %s)",
            SDM::quote($new_email),
            SDM::quote($old_email),
            SDM::quote($robot)
        )
        ) {
        Log::do_log(
            'err',
            'Unable to set new email address %s in netidmap_table to replace old address %s for robot %s',
            $new_email,
            $old_email,
            $robot
        );
        return undef;
    }

    return 1;
}

## Loads the list of topics if updated
## FIXME: This might be moved to Robot package.
sub load_topics {
    my $robot = shift;
    Log::do_log('debug2', '(%s)', $robot);

    my $conf_file = tools::search_fullpath($robot, 'topics.conf');

    unless ($conf_file) {
        Log::do_log('err', 'No topics.conf defined');
        return undef;
    }

    my $topics = {};

    ## Load if not loaded or changed on disk
    if (!$list_of_topics{$robot}
        or tools::get_mtime($conf_file) > $mtime{'topics'}{$robot}) {

        ## delete previous list of topics
        %list_of_topics = ();

        unless (-r $conf_file) {
            Log::do_log('err', 'Unable to read %s', $conf_file);
            return undef;
        }

        unless (open(FILE, "<", $conf_file)) {
            Log::do_log('err', 'Unable to open config file %s', $conf_file);
            return undef;
        }

        ## Rough parsing
        my $index = 0;
        my (@rough_data, $topic);
        while (<FILE>) {
            Encode::from_to($_, $Conf::Conf{'filesystem_encoding'}, 'utf8');
            if (/^([\-\w\/]+)\s*$/) {
                $index++;
                $topic = {
                    'name'  => $1,
                    'order' => $index
                };
            } elsif (/^([\w\.]+)\s+(.+)\s*$/) {
                next unless (defined $topic->{'name'});

                $topic->{$1} = $2;
            } elsif (/^\s*$/) {
                next unless defined $topic->{'name'};

                push @rough_data, $topic;
                $topic = {};
            }
        }
        close FILE;

        ## Last topic
        if (defined $topic->{'name'}) {
            push @rough_data, $topic;
            $topic = {};
        }

        $mtime{'topics'}{$robot} = tools::get_mtime($conf_file);

        unless ($#rough_data > -1) {
            Log::do_log('notice', 'No topic defined in %s', $conf_file);
            return undef;
        }

        ## Analysis
        foreach my $topic (@rough_data) {
            my @tree = split '/', $topic->{'name'};

            if ($#tree == 0) {
                my $title = _get_topic_titles($topic);
                $list_of_topics{$robot}{$tree[0]}{'title'} = $title;
                $list_of_topics{$robot}{$tree[0]}{'visibility'} =
                    $topic->{'visibility'} || 'default';
                #$list_of_topics{$robot}{$tree[0]}{'visibility'} = _load_scenario_file('topics_visibility', $robot,$topic->{'visibility'}||'default');
                $list_of_topics{$robot}{$tree[0]}{'order'} =
                    $topic->{'order'};
            } else {
                my $subtopic = join('/', @tree[1 .. $#tree]);
                my $title = _get_topic_titles($topic);
                $list_of_topics{$robot}{$tree[0]}{'sub'}{$subtopic} =
                    _add_topic($subtopic, $title);
            }
        }

        ## Set undefined Topic (defined via subtopic)
        foreach my $t (keys %{$list_of_topics{$robot}}) {
            unless (defined $list_of_topics{$robot}{$t}{'visibility'}) {
                #$list_of_topics{$robot}{$t}{'visibility'} = _load_scenario_file('topics_visibility', $robot,'default');
            }

            unless (defined $list_of_topics{$robot}{$t}{'title'}) {
                $list_of_topics{$robot}{$t}{'title'} = {'default' => $t};
            }
        }
    }

    ## Set the title in the current language
    my $lang = $language->get_lang;
    foreach my $top (keys %{$list_of_topics{$robot}}) {
        my $topic = $list_of_topics{$robot}{$top};
        foreach my $l (Sympa::Language::implicated_langs($lang)) {
            if (exists $topic->{'title'}{$l}) {
                $topic->{'current_title'} = $topic->{'title'}{$l};
            }
        }
        unless (exists $topic->{'current_title'}) {
            if (exists $topic->{'title'}{'gettext'}) {
                $topic->{'current_title'} =
                    $language->gettext($topic->{'title'}{'gettext'});
            } else {
                $topic->{'current_title'} = $topic->{'title'}{'default'}
                    || $top;
            }
        }

        foreach my $subtop (keys %{$topic->{'sub'}}) {
            foreach my $l (Sympa::Language::implicated_langs($lang)) {
                if (exists $topic->{'sub'}{$subtop}{'title'}{$l}) {
                    $topic->{'sub'}{$subtop}{'current_title'} =
                        $topic->{'sub'}{$subtop}{'title'}{$l};
                }
            }
            unless (exists $topic->{'sub'}{$subtop}{'current_title'}) {
                if (exists $topic->{'sub'}{$subtop}{'title'}{'gettext'}) {
                    $topic->{'sub'}{$subtop}{'current_title'} =
                        $language->gettext(
                        $topic->{'sub'}{$subtop}{'title'}{'gettext'});
                } else {
                    $topic->{'sub'}{$subtop}{'current_title'} =
                           $topic->{'sub'}{$subtop}{'title'}{'default'}
                        || $subtop;
                }
            }
        }
    }

    return %{$list_of_topics{$robot}};
}

sub _get_topic_titles {
    my $topic = shift;

    my $title;
    foreach my $key (%{$topic}) {
        if ($key =~ /^title\.gettext$/i) {
            $title->{'gettext'} = $topic->{$key};
        } elsif ($key =~ /^title\.(\S+)$/i) {
            my $lang = $1;
            # canonicalize lang if possible.
            $lang = Sympa::Language::canonic_lang($lang) || $lang;
            $title->{$lang} = $topic->{$key};
        } elsif ($key =~ /^title$/i) {
            $title->{'default'} = $topic->{$key};
        }
    }

    return $title;
}

## Inner sub used by load_topics()
sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
        return {'title' => $title};
    } else {
        $topic->{'sub'}{$name} =
            _add_topic(join('/', @tree[1 .. $#tree]), $title);
        return $topic;
    }
}

1;
