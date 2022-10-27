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
use Sympa::Language;

use parent qw(Sympa::CLI);

use constant _options   => qw(format|o=s);
use constant _args      => qw(command*);
use constant _need_priv => 0;

my $language = Sympa::Language->instance;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @command = @_;

    my $noperldoc = 1 unless Sympa::CLI->istty(1) or $options->{format};
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
        warn $language->gettext_sprintf('Unknown command \'%s\'',
            join(' ', @command))
            . "\n";
        warn $language->gettext_sprintf(
            'See \'%s help\' to know available commands',
            $PROGRAM_NAME)
            . "\n";
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

C<sympa help> [ C<--format=>I<format> ] [ I<command>... ]

=head1 DESCRIPTION

TBD.

=cut
