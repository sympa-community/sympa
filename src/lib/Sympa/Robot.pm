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

package Sympa::Robot;

use strict;
use warnings;
use Encode qw();

use Sympa;
use Conf;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::File;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

## Database and SQL statement handlers
my ($sth, @sth_stack);

our %list_of_topics = ();
## Last modification times
our %mtime;

our %listmaster_messages_stack;

# MOVED: Use Sympa::send_file(), or Sympa::Message::new_from_template() with
# Sympa::Mailer::send_message().
# sub send_global_file($tpl, $who, $robot, $context, $options);

# MOVED: Use Sympa::send_notify_to_listmaster() or Sympa::Alarm::flush().
# sub send_notify_to_listmaster($operation, $robot, $data, $checkstack, $purge);

## Is the user listmaster
sub is_listmaster {
    my $who   = shift;
    my $robot = shift;

    return unless $who;

    $who =~ y/A-Z/a-z/;

    return 1 if grep { lc $_ eq $who } Sympa::get_listmasters_email($robot);
    return 1 if grep { lc $_ eq $who } Sympa::get_listmasters_email('*');
    return 0;
}

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
              VALUES (?, ?, ?, ?)},
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

## Loads the list of topics if updated
## FIXME: This might be moved to Robot package.
sub load_topics {
    my $robot = shift;
    $log->syslog('debug2', '(%s)', $robot);

    my $conf_file = Sympa::search_fullpath($robot, 'topics.conf');

    unless ($conf_file) {
        $log->syslog('err', 'No topics.conf defined');
        return undef;
    }

    my $topics = {};

    ## Load if not loaded or changed on disk
    if (!$list_of_topics{$robot}
        or Sympa::Tools::File::get_mtime($conf_file) >
        $mtime{'topics'}{$robot}) {

        ## delete previous list of topics
        %list_of_topics = ();

        unless (-r $conf_file) {
            $log->syslog('err', 'Unable to read %s', $conf_file);
            return undef;
        }

        unless (open(FILE, "<", $conf_file)) {
            $log->syslog('err', 'Unable to open config file %s', $conf_file);
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

        $mtime{'topics'}{$robot} = Sympa::Tools::File::get_mtime($conf_file);

        unless ($#rough_data > -1) {
            $log->syslog('notice', 'No topic defined in %s', $conf_file);
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
