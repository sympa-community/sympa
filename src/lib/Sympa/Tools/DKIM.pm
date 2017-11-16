# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Tools::DKIM;

use strict;
use warnings;
use English qw(-no_match_vars);

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

# Old name: tools::dkim_verifier().
#DEPRECATED: Use Sympa::Message::check_dkim_signature().
#sub verifier($msg_as_string);

1;
