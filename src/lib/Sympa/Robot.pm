# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2020, 2021 The Sympa Community. See the
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

package Sympa::Robot;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::ListDef;
use Sympa::Log;
use Sympa::Tools::Data;
use Sympa::Tools::File;
use Sympa::Tools::Text;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

## Database and SQL statement handlers
my ($sth, @sth_stack);

our %list_of_topics = ();
## Last modification times
our %mtime;

our %listmaster_messages_stack;

# MOVED: Use Sympa::send_file(), or Sympa::Message::Template::new() with
# Sympa::Mailer::send_message().
# sub send_global_file($tpl, $who, $robot, $context, $options);

# MOVED: Use Sympa::send_notify_to_listmaster() or
# Sympa::Spool::Listmaster::flush().
# sub send_notify_to_listmaster($operation, $robot, $data, $checkstack, $purge);

## Is the user listmaster
# MOVED: Use Sympa::is_listmaster().
#sub is_listmaster;

## get idp xref to locally validated email address
sub get_netidtoemail_db {
    my $robot   = shift;
    my $netid   = shift;
    my $idpname = shift;
    $log->syslog('debug', '(%s, %s)', $netid, $idpname);

    my ($l, %which, $email);

    push @sth_stack, $sth;

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT email_netidmap
              FROM netidmap_table
              WHERE netid_netidmap = ? and serviceid_netidmap = ? and
                    robot_netidmap = ?},
            $netid, $idpname,
            $robot
        )
    ) {
        $log->syslog(
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
    $log->syslog('debug', '(%s, %s, %s)', $netid, $idpname, $email);

    my ($l, %which);

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{INSERT INTO netidmap_table
              (netid_netidmap, serviceid_netidmap, email_netidmap,
               robot_netidmap)
              SELECT ?, ?, ?, ?
              FROM dual
              WHERE NOT EXISTS (
                SELECT 1
                FROM netidmap_table
                WHERE netid_netidmap = ? AND serviceid_netidmap = ? AND
                      email_netidmap = ? AND robot_netidmap = ?
              )},
            $netid, $idpname, $email, $robot,
            $netid, $idpname, $email, $robot
        )
    ) {
        $log->syslog(
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
        $log->syslog('err', 'Missing parameter');
        return undef;
    }

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE netidmap_table
              SET email_netidmap = ?
              WHERE email_netidmap = ? AND robot_netidmap = ?},
            $new_email,
            $old_email, $robot
        )
    ) {
        $log->syslog(
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

# Loads the list of topics if updated.
# The topic names "others" and "topicsless" are reserved words therefore
# ignored.  Note: "other" is not reserved and may be used.
sub load_topics {
    my $robot = shift;
    $log->syslog('debug2', '(%s)', $robot);

    my $conf_file = Sympa::search_fullpath($robot, 'topics.conf');

    unless ($conf_file) {
        $log->syslog('err', 'No topics.conf defined');
        return;
    }

    my $topics = $list_of_topics{$robot};

    ## Load if not loaded or changed on disk
    if (not $topics
        or Sympa::Tools::File::get_mtime($conf_file) >
        $mtime{'topics'}{$robot}) {

        # Delete previous list of topics
        $list_of_topics{$robot} = $topics = {};

        my $config_content;
        if (open my $ifh, '<', $conf_file) {
            $config_content = do { local $RS; <$ifh> };
            close $ifh;
        } else {
            $log->syslog('err', 'Unable to read %s: %m', $conf_file);
            return;
        }

        ## Rough parsing
        my $index = 0;
        my (@rough_data, $topic);
        foreach my $line (split /(?<=\n)(?=\n|.)/, $config_content) {
            if ($line =~ /\A(others|topicsless)\s*\z/i) {
                # "others" and "topicsless" are reserved words. Ignore.
                next;
            } elsif ($line =~ /^([\-\w\/]+)\s*$/) {
                $index++;
                $topic = {
                    'name'  => lc($1),
                    'order' => $index
                };
            } elsif ($line =~ /^([\w\.]+)\s+(.+\S)\s*$/) {
                next unless defined $topic->{'name'};

                $topic->{$1} = $2;
            } elsif ($line =~ /^\s*$/) {
                next unless defined $topic->{'name'};

                push @rough_data, $topic;
                $topic = {};
            }
        }

        ## Last topic
        if (defined $topic->{'name'}) {
            push @rough_data, $topic;
            $topic = {};
        }

        $mtime{'topics'}{$robot} = Sympa::Tools::File::get_mtime($conf_file);

        unless (@rough_data) {
            $log->syslog('notice', 'No topic defined in %s', $conf_file);
            return;
        }

        ## Analysis
        foreach my $topic (@rough_data) {
            _add_topic($topics, $topic);
        }
    }

    return %$topics;
}

# Old name: _get_topic_titles().
# No longer used.
#sub _load_topics_get_title;

## Inner sub used by load_topics()
sub _add_topic {
    my $topics = shift;
    my $topic  = shift;
    my $names  = shift || [split m{/}, $topic->{name}];

    my $topname = shift @$names;

    my $top = $topics->{$topname} //= {};
    unless (scalar @$names) {
        my $title;
        foreach my $key (keys %$topic) {
            if (lc $key eq 'title.gettext') {
                $title->{gettext} = $topic->{$key};
            } elsif ($key =~ /\Atitle[.](\S+)\z/i) {
                my $lang = Sympa::Language::canonic_lang($1);
                $title->{$lang} = $topic->{$key} if $lang;
            } elsif (lc $key eq 'title') {
                $title->{default} = $topic->{$key};
            }
        }
        @{$top}{qw(title visibility order)} =
            ($title, $topic->{visibility}, $topic->{order});
    } else {
        my $sub = $topics->{$topname}{sub} //= {};
        _add_topic($sub, $topic, $names);

        my $order = $topic->{order};
        $top->{order} = $order
            unless ($top->{order} // $order) < $order;
    }
    $top->{title} //= {default => $topname};
    $top->{visibility} ||= 'noconceal';

    unshift @$names, $topname;
}

sub topic_keys {
    my $robot_id = shift;

    my %topics = Sympa::Robot::load_topics($robot_id);
    return map {
        my $topic = $_;
        if ($topics{$topic}->{sub}) {
            (   $topic,
                map { $topic . '/' . $_ } sort keys %{$topics{$topic}->{sub}}
            );
        } else {
            ($topic);
        }
    } sort keys %topics;
}

sub topic_get_title {
    my $robot_id = shift;
    my $topic    = shift;

    my $tinfo = {Sympa::Robot::load_topics($robot_id)};
    return unless %$tinfo;

    my @ttitles;
    my @tpaths = split '/', $topic;

    while (1) {
        my $t = shift @tpaths;
        unless (exists $tinfo->{$t}) {
            @ttitles = ();
            last;
        } elsif (not @tpaths) {
            push @ttitles, (_topic_get_title($tinfo->{$t}) || $t);
            last;
        } elsif (not $tinfo->{$t}->{sub}) {
            @ttitles = ();
            last;
        } else {
            push @ttitles, (_topic_get_title($tinfo->{$t}) || $t);
            $tinfo = $tinfo->{$t}->{sub};
        }
    }

    return @ttitles if wantarray;
    return join ' / ', @ttitles;
}

sub _topic_get_title {
    my $titem = shift;

    return undef unless $titem and exists $titem->{title};

    foreach my $lang (Sympa::Language::implicated_langs($language->get_lang))
    {
        return $titem->{title}->{$lang}
            if $titem->{title}->{$lang};
    }
    if ($titem->{title}->{gettext}) {
        return $language->gettext($titem->{title}->{gettext});
    } elsif ($titem->{title}->{default}) {
        return $titem->{title}->{default};
    } else {
        return undef;
    }
}

=over 4

=item list_params

I<Getter>.
Returns hashref to list parameter information.

=back

=cut

# Old name: tools::get_list_params().
sub list_params {
    my $robot_id = shift;

    my $pinfo = Sympa::Tools::Data::clone_var(\%Sympa::ListDef::pinfo);
    $pinfo->{lang}{format} = [Sympa::get_supported_languages($robot_id)];

    my @topics = Sympa::Robot::topic_keys($robot_id);
    $pinfo->{topics}{format} = [@topics];
    # Compat.
    $pinfo->{topics}{file_format} = sprintf '(%s)(,(%s))*',
        join('|', @topics),
        join('|', @topics);

    return $pinfo;
}

1;
