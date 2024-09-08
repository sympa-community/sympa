# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
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

package Sympa::CLI::test::ldap;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa::Constants;
use Sympa::Database;
use Sympa::DatabaseDriver::LDAP;
use Sympa::Log;    # Show err logs on STDERR.

use parent qw(Sympa::CLI::test);

use constant _options => (
    (   map {"$_=s"} @{Sympa::DatabaseDriver::LDAP->required_parameters},
        @{Sympa::DatabaseDriver::LDAP->optional_parameters},
        qw(use_ssl use_start_tls),    # Deprecated as of 6.2.15
        qw(scope)
    ),
    qw(suffix:s attrs:s)
);
use constant _args      => qw(filter);
use constant _need_priv => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my $filter  = shift;

# Parameters deprecated as of 6.2.15.
    if ($options->{use_start_tls}) {
        $options->{use_tls} = 'starttls';
    } elsif ($options->{use_ssl}) {
        $options->{use_tls} = 'ldaps';
    }
    delete $options->{use_start_tls};
    delete $options->{use_ssl};

    if ($options->{bind_dn} and not $options->{bind_password}) {
        local $SIG{TERM} = sub { system qw(stty echo) };
        system qw(stty -echo);
        print 'Bind password:';
        my $password = <STDIN>;
        chomp $password;
        print "\n";
        $SIG{TERM}->();

        $options->{bind_password} = $password;
    }

    my $db = Sympa::Database->new('LDAP', %$options);
    unless ($db) {
        warn sprintf "%s\n", ($EVAL_ERROR // 'Connection failed');
        exit 1;
    }

    printf "host=%s suffix=%s filter=%s\n",
        ($options->{host} // ''), ($options->{suffix} // ''), $filter;
    print "\n";

    my ($mesg, $res);

    $db->connect
        or die sprintf "Connect impossible: %s\n", ($db->error || '');
    $mesg = $db->do_operation(
        'search',
        base   => ($options->{suffix} // ''),
        filter => $filter,
        scope  => ($options->{scope} || 'sub'),
        deref  => ($options->{deref} || 'find'),
        attrs =>
            ($options->{attrs} ? [split /\s*,\s*/, $options->{attrs}] : ['']),
    ) or die sprintf "Search  impossible: %s\n", $db->error;
    $res = $mesg->as_struct;

    my $cpt = 0;
    foreach my $dn (keys %$res) {

        my $hash = $res->{$dn};
        print "#$dn\n";

        foreach my $k (keys %$hash) {
            my $array = $hash->{$k};
            if ((ref($array) eq 'ARRAY') and ($k ne 'jpegphoto')) {
                printf "\t%s => %s\n", $k, join(',', @$array);
            } else {
                printf "\t%s => %s\n", $k, $array;
            }
        }
        $cpt++;
    }

    print "Total : $cpt\n";

    $db->disconnect or printf "disconnect impossible: %s\n", $db->error;

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-test-ldap - Testing LDAP connection for Sympa

=head1 SYNOPSIS

  sympa test ldap --host=string --suffix=string
  [ --attrs=[ string,...|* ] ]
  [ --bind_dn=string [ --bind_password=string ] ]
  [ --port=string ] [ --scope=base|one|sub ]
  [ --use_tls=starttls|ldaps|none
    [ --ca_file=string ] [ --ca_path=string ]
    [ --ca_verify=none|optional|require ]
    [ --ssl_cert=string ] [ --ssl_ciphers=string ] [ --ssl_key=string ]
    [ --ssl_version=sslv2|sslv3|tlsv1|tlsv1_1|tlsv1_2|tlsv1_3 ] ]
  filter

=head1 DESCRIPTION

C<sympa test ldap> tests LDAP connection and search operation using LDAP
driver of Sympa.

=head1 SEE ALSO

L<Sympa::DatabaseDriver::LDAP>.

=head1 HISTORY

testldap.pl appeared before Sympa 3.0.

It supported LDAP over TLS (ldaps) on Sympa 5.3a.1.

testldap.pl was renamed to sympa_test_ldap.pl on Sympa 6.2.

C<--use_ssl> and C<--use_start_tls> options were obsoleted by Sympa 6.2.15.
C<--use_tls> option would be used instead.

This function was moved to C<sympa test ldap> command line on Sympa 6.2.71b.

=cut
