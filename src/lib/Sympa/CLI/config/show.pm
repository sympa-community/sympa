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

package Sympa::CLI::config::show;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa::Constants;

use parent qw(Sympa::CLI::config);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    _display_configuration($options);
    exit 0;
}

sub _display_configuration {
    die "$PROGRAM_NAME: You must run as superuser.\n"
        if $UID;

    # Load sympa config (but not using database)
    unless (defined Conf::load(Sympa::Constants::CONFIG(), 'no_db')) {
        die sprintf
            "%s: Unable to load sympa configuration, file %s or one of the virtual host robot.conf files contain errors. Exiting.\n",
            $PROGRAM_NAME, Sympa::Constants::CONFIG();
    }

    my ($var, $disp);

    print "[SYMPA]\n";
    foreach my $key (sort keys %Conf::Conf) {
        next
            if grep { $key eq $_ }
            qw(auth_services blocklist crawlers_detection listmasters
            locale2charset nrcpt_by_domain robot_by_http_host request
            robot_name robots source_file sympa trusted_applications);

        $var = $Conf::Conf{$key};

        if ($key eq 'automatic_list_families') {
            $disp = join ';', map {
                my $name = $_;
                join ':', map { sprintf '%s=%s', $_, $var->{$name}{$_} }
                    grep { !/\Aescaped_/ }
                    sort keys %{$var->{$name} || {}};
            } sort keys %{$var || {}};
        } elsif (ref $var eq 'ARRAY') {
            $disp = join(',', map { defined $_ ? $_ : '' } @$var);
        } else {
            $disp = defined $var ? $var : '';
        }

        printf "%s=\"%s\"\n", $key, $disp;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-config-show - Create configuration file

=head1 SYNOPSIS

C<sympa config show>

=head1 DESCRIPTION

Outputs all configuration parameters in F<sympa.conf>.

=cut
