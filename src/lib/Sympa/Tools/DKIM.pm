# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2020, 2021 The Sympa Community. See the
# AUTHORS.md # file at the top-level directory of this distribution and at
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

package Sympa::Tools::DKIM;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Conf;
use Sympa::Log;

my $log = Sympa::Log->instance;

# Old name: tools::get_dkim_parameters().
sub get_dkim_parameters {
    $log->syslog('debug2', '(%s)', @_);
    my $that = shift;

    my ($robot_id, $list);
    if (ref $that eq 'Sympa::List') {
        $robot_id = $that->{'domain'};
        $list     = $that;
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $data;
    my $keyfile;
    if ($list) {
        # fetch dkim parameter in list context
        $data->{'d'} = $list->{'admin'}{'dkim_parameters'}{'signer_domain'};
        if ($list->{'admin'}{'dkim_parameters'}{'signer_identity'}) {
            $data->{'i'} =
                $list->{'admin'}{'dkim_parameters'}{'signer_identity'};
        } else {
            # RFC 4871 (page 21)
            $data->{'i'} = Sympa::get_address($list, 'owner');    # -request
        }
        $data->{'selector'} = $list->{'admin'}{'dkim_parameters'}{'selector'};
        $keyfile = $list->{'admin'}{'dkim_parameters'}{'private_key_path'};
    } else {
        # in robot context
        $data->{'d'} = Conf::get_robot_conf($robot_id, 'dkim_signer_domain');
        $data->{'i'} =
            Conf::get_robot_conf($robot_id, 'dkim_signer_identity');
        $data->{'selector'} =
            Conf::get_robot_conf($robot_id, 'dkim_selector');
        $keyfile = Conf::get_robot_conf($robot_id, 'dkim_private_key_path');
    }
    return undef
        unless defined $data->{'d'}
        and defined $data->{'selector'}
        and defined $keyfile;

    my $fh;
    unless (open $fh, '<', $keyfile) {
        $log->syslog('err', 'Could not read dkim private key %s: %m',
            $keyfile);
        return undef;
    }
    $data->{'private_key'} = do { local $RS; <$fh> };
    close $fh;

    return $data;
}

sub get_arc_parameters {
    $log->syslog('debug2', '(%s)', @_);
    my $that = shift;

    my ($robot_id, $list);
    if (ref $that eq 'Sympa::List') {
        $robot_id = $that->{'domain'};
        $list     = $that;
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my ($data, $keyfile);
    if ($list) {
        # check if enabled for the list
        $log->syslog(
            'debug2',
            'list arc feature %s',
            $list->{'admin'}{'arc_feature'}
        );

        return undef unless $list->{'admin'}{'arc_feature'} eq 'on';

        # fetch arc parameter in list context
        $data->{'d'} = $list->{'admin'}{'arc_parameters'}{'arc_signer_domain'}
            || $list->{'admin'}{'dkim_parameters'}{'signer_domain'};
        $data->{'selector'} =
               $list->{'admin'}{'arc_parameters'}{'arc_selector'}
            || $list->{'admin'}{'dkim_parameters'}{'selector'};
        $keyfile = $list->{'admin'}{'arc_parameters'}{'arc_private_key_path'}
            || $list->{'admin'}{'dkim_parameters'}{'private_key_path'};
    } else {
        # in robot context
        $log->syslog(
            'debug2',
            'robot arc feature %s',
            Conf::get_robot_conf($robot_id, 'arc_feature')
        );
        return undef
            unless Conf::get_robot_conf($robot_id, 'arc_feature') eq 'on';

        $data->{'d'} = Conf::get_robot_conf($robot_id, 'arc_signer_domain')
            || Conf::get_robot_conf($robot_id, 'dkim_signer_domain');
        $data->{'selector'} = Conf::get_robot_conf($robot_id, 'arc_selector')
            || Conf::get_robot_conf($robot_id, 'dkim_selector');
        $keyfile =
               Conf::get_robot_conf($robot_id, '        arc_private_key_path')
            || Conf::get_robot_conf($robot_id, 'dkim_private_key_path');
    }

    $data->{'srvid'} = Conf::get_robot_conf($robot_id, 'arc_srvid')
        || $data->{'d'};
    return undef
        unless defined $data->{'d'}
        and defined $data->{'selector'}
        and defined $keyfile;

    my $fh;
    unless (open $fh, '<', $keyfile) {
        $log->syslog('err', 'Could not read arc private key %s: %m',
            $keyfile);
        return undef;
    }
    $data->{'private_key'} = do { local $RS; <$fh> };
    close $fh;

    return $data;
}

# Old name: tools::dkim_verifier().
#DEPRECATED: Use Sympa::Message::check_dkim_signature().
#sub verifier($msg_as_string);

1;
