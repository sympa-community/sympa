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

use constant _options   => qw(format|o=s);
use constant _args      => qw(command*);
use constant _need_priv => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @command = @_;

    my $noperldoc = 1 unless -t STDOUT or $options->{format};
    my $message;

    local $ENV{PERLDOC} = sprintf '-o%s', $options->{format}
        if ($options->{format} // '') =~ /\A\w+\z/;

    unless (@command) {
        Pod::Usage::pod2usage(
            -input     => $PROGRAM_NAME,
            -verbose   => 2,
            -exitval   => 0,
            -noperldoc => $noperldoc
        );
    }

    if (grep { not length $_ or /\W/ } @command) {
        $message = sprintf 'Malformed argument "%s"', join ' ', @command;
        @command = qw(help);
    }

    my $path;
    foreach my $dir (@INC) {
        next unless -d $dir;
        $path = sprintf '%s/Sympa/CLI/%s.pm', $dir, join '/', @command;
        last if -e $path;
        undef $path;
    }
    unless ($path) {
        printf STDERR
            "Unknown command '%s'. See '%s help commands' to know available commands.\n",
            join(' ', @command), $PROGRAM_NAME;
        exit 1;
    } else {
        Pod::Usage::pod2usage(
            ($message ? (-message => $message) : ()),
            -input => $path,
            ($message ? () : (-verbose => 2)),
            -exitval   => 0,
            -noperldoc => $noperldoc
        );
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-help - Display help information about Sympa CLI

=head1 SYNOPSIS

C<sympa.pl help> [ C<--format=>I<format> ] [ I<command>... ]

=head1 DESCRIPTION

TBD.

=cut
