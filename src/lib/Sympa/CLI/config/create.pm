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

package Sympa::CLI::config::create;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Language;
use Sympa::Tools::Data;

use parent qw(Sympa::CLI::config);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 0;

my $language = Sympa::Language->instance;

# Old name: create_configuration() in sympa_wizard.pl.
sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    my $conf = $options->{config} // Sympa::Constants::CONFIG();

    if (-f $conf) {
        die $language->gettext_sprintf('The file %s already exists', $conf)
            . "\n";
    }

    my $umask = umask 037;
    my $ofh;
    unless (open $ofh, '>', $conf) {
        umask $umask;
        die "$PROGRAM_NAME: "
            . $language->gettext_sprintf('Unable to open %s : %s',
            $conf, $ERRNO)
            . "\n";
    }
    umask $umask;

    print $ofh Sympa::Tools::Data::format_config([@Sympa::ConfDef::params]);

    close $ofh;
    print $language->gettext_sprintf('The file %s has been created', $conf)
        . "\n";
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-config-create - Create configuration file

=head1 SYNOPSIS

C<sympa config create> S<[ C<--config=>I</path/to/new/sympa.conf> ]>

=head1 DESCRIPTION

Creates a new F<sympa.conf> configuration file.

Options:

=over

=item C<--config>, C<-f=>I</path/to/new/sympa.conf>

Use an alternative configuration file.

=back

=cut
