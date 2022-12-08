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

    my %data;
    if ($list) {
        %data = (
            d => (
                       $list->{'admin'}{'dkim_parameters'}{'signer_domain'}
                    || $list->{'admin'}{'arc_parameters'}{'signer_domain'}
                    || $list->{'domain'}
            ),
            # "i=" tag is -request address by default.
            # See RFC 4871 (page 21).
            i => (
                $list->{'admin'}{'dkim_parameters'}{'signer_identity'}
                    || Sympa::get_address($list, 'owner')
            ),
            s => (
                       $list->{'admin'}{'dkim_parameters'}{'selector'}
                    || $list->{'admin'}{'arc_parameters'}{'selector'}
            ),
            key => _load_dkim_private_key(
                       $list->{'admin'}{'dkim_parameters'}{'private_key_path'}
                    || $list->{'admin'}{'arc_parameters'}{'private_key_path'}
            ),
        );
    } else {
        %data = (
            d => (
                Conf::get_robot_conf($robot_id,
                    'dkim_parameters.signer_domain')
                    || Conf::get_robot_conf($robot_id,
                    'arc_parameters.signer_domain')
                    || $robot_id
            ),
            # This is NOT derived by list config
            i => Conf::get_robot_conf($robot_id, 'dkim_signer_identity'),
            s => (
                Conf::get_robot_conf($robot_id, 'dkim_parameters.selector')
                    || Conf::get_robot_conf(
                    $robot_id, 'arc_parameters.selector'
                    )
            ),
            key => _load_dkim_private_key(
                Conf::get_robot_conf($robot_id,
                    'dkim_parameters.private_key_path')
                    || Conf::get_robot_conf(
                    $robot_id, 'arc_parameters.private_key_path'
                    )
            ),
        );
    }
    return
            unless length($data{d} // '')
        and length($data{s} // '')
        and $data{key};

    return %data;
}

sub get_arc_parameters {
    $log->syslog('debug2', '(%s)', @_);
    my $that = shift;
    my $cv   = shift;

    my ($robot_id, $list);
    if (ref $that eq 'Sympa::List') {
        $robot_id = $that->{'domain'};
        $list     = $that;
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my %data;
    if ($list) {
        # fetch arc parameter in list context
        %data = (
            d => (
                       $list->{'admin'}{'arc_parameters'}{'signer_domain'}
                    || $list->{'admin'}{'dkim_parameters'}{'signer_domain'}
                    || $list->{'domain'}
            ),
            s => (
                       $list->{'admin'}{'arc_parameters'}{'selector'}
                    || $list->{'admin'}{'dkim_parameters'}{'selector'}
            ),
            key => _load_dkim_private_key(
                       $list->{'admin'}{'arc_parameters'}{'private_key_path'}
                    || $list->{'admin'}{'dkim_parameters'}{'private_key_path'}
            ),
        );
    } else {
        %data = (
            d => (
                Conf::get_robot_conf($robot_id,
                    'arc_parameters.signer_domain')
                    || Conf::get_robot_conf($robot_id,
                    'dkim_parameters.signer_domain')
                    || $robot_id
            ),
            s => (
                Conf::get_robot_conf($robot_id, 'arc_parameters.selector')
                    || Conf::get_robot_conf(
                    $robot_id, 'dkim_parameters.selector'
                    )
            ),
            key => _load_dkim_private_key(
                Conf::get_robot_conf($robot_id,
                    'arc_parameters.private_key_path')
                    || Conf::get_robot_conf(
                    $robot_id, 'dkim_parameters.private_key_path'
                    )
            ),
        );
    }

    $data{authserv_id} = Conf::get_robot_conf($robot_id, 'arc_srvid')
        || $data{d};
    $data{cv} = $cv;
    return
            unless length($data{d} // '')
        and length($data{s} // '')
        and $data{key}
        and $data{cv}
        and grep { $data{cv} eq $_ } qw(pass fail none);

    return %data;
}

# Mail::DKIM::Privatekey <= 0.58 doesn't have $VERSION variable.
my $has_Mail_DKIM_PrivateKey;

BEGIN {
    eval 'use Mail::DKIM::PrivateKey';
    $has_Mail_DKIM_PrivateKey = !$EVAL_ERROR;
}

sub _load_dkim_private_key {
    my $keyfile = shift;

    return undef unless $has_Mail_DKIM_PrivateKey;

    my $fh;
    unless (open $fh, '<', $keyfile) {
        $log->syslog('err', 'Could not read arc private key %s: %m',
            $keyfile);
        return undef;
    }

    # DKIM::PrivateKey does never allow armour texts nor newlines.
    # Strip them.
    my $privatekey_string = join '',
        grep { !/^---/ and $_ } split /\r\n|\r|\n/, do { local $RS; <$fh> };
    close $fh;

    my $privatekey = Mail::DKIM::PrivateKey->load(Data => $privatekey_string);
    unless ($privatekey) {
        $log->syslog('err', 'Can\'t create Mail::DKIM::PrivateKey');
        return undef;

    }

    return $privatekey;
}

# Old name: tools::dkim_verifier().
#DEPRECATED: Use Sympa::Message::check_dkim_signature().
#sub verifier($msg_as_string);

1;
