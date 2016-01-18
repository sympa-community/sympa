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

package Sympa::CommandDef;

use strict;
use warnings;

use Conf;
use Sympa::Regexps;

my $_email_re = Sympa::Regexps::addrspec();
our %comms     = (
    add => {
        cmd_regexp => qr'add'i,
        arg_regexp => qr{(\S+)\s+($_email_re)(?:\s+(.+))?\s*\z},
        arg_keys   => [qw(localpart email gecos)],
        scenario   => 'add',
    },
    confirm => {
        cmd_regexp => qr'con|confirm'i,
        arg_regexp => qr'(\w+)\s*\z',
        arg_keys   => [qw(authkey)],
    },
    del => {
        cmd_regexp => qr'del|delete'i,
        arg_regexp => qr{(\S+)\s+($_email_re)\s*},
        arg_keys   => [qw(localpart email)],
        scenario   => 'del',
    },
    distribute => {
        cmd_regexp => qr'dis|distribute'i,
        arg_regexp => qr'(\S+)\s+(\w+)\s*\z',
        arg_keys   => [qw(localpart authkey)],
        # No scenario.
    },
    get => {
        cmd_regexp => qr'get'i,
        arg_regexp => qr'(\S+)\s+(.+)',
        arg_keys   => [qw(localpart arc)],
        scenario   => 'archive.mail_access',
    },
    help => {cmd_regexp => qr'hel|help|sos'i,},
    info => {
        cmd_regexp => qr'inf|info'i,
        arg_regexp => qr'(.+)',
        arg_keys   => [qw(localpart)],
        scenario   => 'info',
    },
    index => {
        cmd_regexp => qr'ind|index'i,
        arg_regexp => qr'(.+)',
        arg_keys   => [qw(localpart)],
        scenario   => 'archive.mail_access',
    },
    invite => {
        cmd_regexp => qr'inv|invite'i,
        arg_regexp => qr{(\S+)\s+($_email_re)(?:\s+(.+))?\s*\z},
        arg_keys   => [qw(localpart email gecos)],
        scenario   => 'invite',
    },
    last => {
        cmd_regexp => qr'las|last'i,
        arg_regexp => qr'(.+)',
        arg_keys   => [qw(localpart)],
        scenario   => 'archive.mail_access',
    },
    lists    => {cmd_regexp => qr'lis|lists?'i,},
    modindex => {
        cmd_regexp => qr'mod|modindex|modind'i,
        arg_regexp => qr'(\S+)',
        arg_keys   => [qw(localpart)],
        # No scenario. Only actual editors are allowed.
    },
    finished => {cmd_regexp => qr'qui|quit|end|stop|-'i,},
    reject   => {
        cmd_regexp => qr'rej|reject'i,
        arg_regexp => qr'(\S+)\s+(\w+)\s*\z',
        arg_keys   => [qw(localpart authkey)],
        # No scenario.
    },
    remind => {
        cmd_regexp => qr'rem|remind'i,
        arg_regexp => qr'(?:([*])|([^\s\@]+))(?:\@([-.\w]+))?\s*\z',
        arg_keys   => [qw(anylists localpart domainpart)],
        filter     => sub {
            my $r = shift;

            if ($r->{domainpart}) {
                my $host;
                if (ref $r->{context} eq 'Sympa::List') {
                    $host = $r->{context}->{'admin'}{'host'};
                } else {
                    $host = Conf::get_robot_conf($r->{context}, 'host');
                }
                return undef unless lc $r->{domainpart} eq $host;
            }
            $r;
        },
        scenario => 'remind',    # or global_remind scenario.
    },
    review => {
        cmd_regexp => qr'rev|review|who'i,
        arg_regexp => qr'(.+)',
        arg_keys   => [qw(localpart)],
        scenario   => 'review',
    },
    set => {
        cmd_regexp => qr'set'i,
        arg_regexp =>
            qr'(?:([*])|(\S+))\s+(digest|digestplain|nomail|normal|not_me|each|mail|conceal|noconceal|summary|notice|txt|html|urlize)\s*\z'i,
        arg_keys => [qw(anylists localpart mode)],
        filter   => sub {
            my $r = shift;

            $r->{mode} = lc($r->{mode} || '');
            # SET EACH is a synonym for SET MAIL.
            $r->{mode} = 'mail'
                if grep { $r->{mode} eq $_ }
                    qw(each eachmail nodigest normal);
            $r;
        },
        # No scenario.  Only list members are allowed.
    },
    stats => {
        cmd_regexp => qr'sta|stats'i,
        arg_regexp => qr'(.+)',
        arg_keys   => [qw(localpart)],
        scenario   => 'review',
    },
    subscribe => {
        cmd_regexp => qr'sub|subscribe'i,
        arg_regexp => qr'(\S+)(?:\s+(.+))?\s*\z',
        arg_keys   => [qw(localpart gecos)],
        filter     => sub {
            my $r = shift;
            $r->{email} = $r->{sender};
            $r;
        },
        scenario => 'subscribe',
    },
    signoff => {
        cmd_regexp => qr'sig|signoff|uns|unsub|unsubscribe'i,
        arg_regexp =>
            qr{(?:([*])|([^\s\@]+))(?:\@([-.\w]+))?(?:\s+($_email_re))?\z},
        arg_keys => [qw(anylists localpart domainpart email)],
        filter   => sub {
            my $r = shift;
            $r->{email} ||= $r->{sender};

            if ($r->{domainpart}) {
                my $host;
                if (ref $r->{context} eq 'Sympa::List') {
                    $host = $r->{context}->{'admin'}{'host'};
                } else {
                    $host = Conf::get_robot_conf($r->{context}, 'host');
                }
                return undef unless lc $r->{domainpart} eq $host;
            }
            $r;
        },
        scenario => 'unsubscribe',    # global signoff allows any lists.
    },
    verify => {
        cmd_regexp => qr'ver|verify'i,
        arg_regexp => qr'(.+)',
        arg_keys   => [qw(localpart)],
        # No scenario.
    },
    which => {cmd_regexp => qr'whi|which|status'i,},
);

1;
__END__

