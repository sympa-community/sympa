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

package Sympa::CLI::help;

use strict;
use warnings;
use English qw(-no_match_vars);
use Pod::Usage qw();

use Sympa::Constants;

use parent qw(Sympa::CLI);

use constant _options  => qw();
use constant _arranged => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    my $arg = shift @argv;

    unless ($arg) {
        Pod::Usage::pod2usage(
            -input   => $PROGRAM_NAME,
            -exitval => 0
        ) unless $arg;
        #} elsif ($arg eq '?') {
        #    ...
    } elsif ($arg =~ /\W/) {
        Pod::Usage::pod2usage(-exitval => 1);
    } else {
        my $path;
        foreach my $dir (@INC) {
            next unless -d $dir;
            $path = sprintf '%s/Sympa/CLI/%s.pm', $dir, $arg;
            last if -e $path;
            undef $path;
        }
        Pod::Usage::pod2usage(-input => $path, -exitval => 0);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-help - Sympa CLI: Show the help

=head1 SYNOPSIS

C<sympa.pl help>
  
C<sympa.pl help I<command>>

=head1 DESCRIPTION

=cut

