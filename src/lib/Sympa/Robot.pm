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

package Sympa::Robot;

use strict;
use warnings;
use Encode qw();

use Sympa;
use Conf;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::ListDef;
use Sympa::Log;
use Sympa::Tools::Data;
use Sympa::Tools::File;

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

my $default_topics_visibility = 'noconceal';

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

    my $topics = {};

    ## Load if not loaded or changed on disk
    if (!$list_of_topics{$robot}
        or Sympa::Tools::File::get_mtime($conf_file) >
        $mtime{'topics'}{$robot}) {

        ## delete previous list of topics
        %list_of_topics = ();

        unless (-r $conf_file) {
            $log->syslog('err', 'Unable to read %s', $conf_file);
            return;
        }

        my $fh;
        unless (open $fh, '<', $conf_file) {
            $log->syslog('err', 'Unable to open config file %s', $conf_file);
            return;
        }

        ## Rough parsing
        my $index = 0;
        my (@rough_data, $topic);
        while (my $line = <$fh>) {
            Encode::from_to($line, $Conf::Conf{'filesystem_encoding'},
                'utf8');
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
        close $fh;

        ## Last topic
        if (defined $topic->{'name'}) {
            push @rough_data, $topic;
            $topic = {};
        }

        $mtime{'topics'}{$robot} = Sympa::Tools::File::get_mtime($conf_file);

        unless ($#rough_data > -1) {
            $log->syslog('notice', 'No topic defined in %s', $conf_file);
            return;
        }

        ## Analysis
        foreach my $topic (@rough_data) {
            my @tree = split '/', $topic->{'name'};

            if ($#tree == 0) {
                my $title = _load_topics_get_title($topic);
                $list_of_topics{$robot}{$tree[0]}{'title'} = $title;
                $list_of_topics{$robot}{$tree[0]}{'visibility'} =
                    $topic->{'visibility'} || $default_topics_visibility;
                $list_of_topics{$robot}{$tree[0]}{'order'} =
                    $topic->{'order'};
            } else {
                my $subtopic = join('/', @tree[1 .. $#tree]);
                my $title = _load_topics_get_title($topic);
                my $visibility =
                    $topic->{'visibility'} || $default_topics_visibility;
                $list_of_topics{$robot}{$tree[0]}{'sub'}{$subtopic} =
                    _add_topic($subtopic, $title, $visibility);
            }
        }

        ## Set undefined Topic (defined via subtopic)
        foreach my $t (keys %{$list_of_topics{$robot}}) {
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

# Old name: _get_topic_titles().
sub _load_topics_get_title {
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
    my ($name, $title, $visibility) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
        return {'title' => $title, 'visibility' => $visibility};
    } else {
        $topic->{'sub'}{$name} =
            _add_topic(join('/', @tree[1 .. $#tree]), $title, $visibility);
        return $topic;
    }
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
