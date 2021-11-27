# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021 The Sympa Community. See the
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

package Sympa::CLI::upgrade_config_location;

use strict;
use warnings;
use English qw(-no_match_vars);
use Fcntl qw();
use File::Basename;
use File::Copy;
use File::Path qw();

use Sympa::Constants;

use parent qw(Sympa::CLI);

use constant _options  => qw();
use constant _arranged => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

#if ($options->{upgrade_config_location}) {
    my $config_file = Conf::get_sympa_conf();

    if (-f $config_file) {
        printf "Sympa configuration already located at %s\n", $config_file;
        exit 0;
    }

    my ($file, $dir, $suffix) = File::Basename::fileparse($config_file);
    my $old_dir = $dir;
    $old_dir =~ s/sympa\///;

    # Try to create config path if it does not exist
    unless (-d $dir) {
        my $error;
        File::Path::make_path(
            $dir,
            {   mode  => 0755,
                owner => Sympa::Constants::USER(),
                group => Sympa::Constants::GROUP(),
                error => \$error
            }
        );
        if (@$error) {
            my $diag = pop @$error;
            my ($target, $error) = %$diag;
            die "Unable to create $target: $error";
        }
    }

    # Check ownership of config folder
    my @stat = stat($dir);
    my $user = (getpwuid $stat[4])[0];
    if ($user ne Sympa::Constants::USER()) {
        die sprintf
            "Config dir %s exists but is not owned by %s (owned by %s).\n",
            $dir, Sympa::Constants::USER(), $user;
    }

    # Check permissions on config folder
    if (($stat[2] & Fcntl::S_IRWXU()) != Fcntl::S_IRWXU()) {
        die
            "Config dir $dir exists, but sympa does not have rwx permissions on it";
    }

    # Move files from old location to new one
    opendir my $dh, $old_dir
        or die sprintf 'Could not open %s for reading: %s', $dir, $ERRNO;
    my @files = grep {/^(ww)?sympa\.conf.*$/} readdir $dh;
    closedir $dh;

    foreach my $file (@files) {
        unless (File::Copy::move("$old_dir/$file", "$dir/$file")) {
            die sprintf 'Could not move %s/%s to %s/%s: %s', $old_dir, $file,
                $dir, $file, $ERRNO;
        }
    }

    printf "Sympa configuration moved to %s\n", $dir;
    exit 0;
}
1;
