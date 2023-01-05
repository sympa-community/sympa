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

use Conf;
use Sympa::Constants;

use parent qw(Sympa::CLI::config);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 0;

# Old name: display_configuration() in sympa_wizard.pl.
sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    my $curConf = _load($options->{config});
    return undef unless $curConf;

    my ($var, $disp);

    print "[SYMPA]\n";
    foreach my $key (sort keys %$curConf) {

        $var = $curConf->{$key};

        if (ref $var eq 'ARRAY') {
            $disp = join ',', map { $_ // '' } @$var;
        } else {
            $disp = $var // '';
        }

        printf "%s=\"%s\"\n", $key, $disp;
    }

    return 1;
}

sub _load {
    my $sympa_conf = shift || Sympa::Constants::CONFIG();

    #FIXME: Refactor Conf.
    my $res = Conf::_load_config_file_to_hash($sympa_conf);
    return undef unless $res;
    return $res->{config};
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-config-show - Show the content of configuration file

=head1 SYNOPSIS

C<sympa config show> S<[ C<--config=>I</path/to/new/sympa.conf> ]>

=head1 DESCRIPTION

Outputs all configuration parameters in F<sympa.conf>.

Options:

=over

=item C<--config>, C<-f=>I</path/to/new/sympa.conf>

Use an alternative configuration file.

=back

=head1 HISTORY

See L<sympa config|sympa-config(1)>.

=cut
