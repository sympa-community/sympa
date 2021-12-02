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

package Sympa::CLI::make_alias_file;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa::Aliases;
use Conf;
use Sympa::List;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw(domain|site domain*);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @domains = @_;

    if (grep { $_ eq '*' } @domains) {
        @domains = Sympa::List::get_robots();
    }
    exit 0 unless @domains;

    # There may be multiple aliases files.  Give each of them suffixed
    # name.
    my ($basename, %robots_of, %sympa_aliases);
    $basename = sprintf '%s/sympa_aliases.%s', $Conf::Conf{'tmpdir'}, $PID;

    foreach my $robot (@domains) {
        my $file = Conf::get_robot_conf($robot, 'sendmail_aliases');
        next if $file eq 'none';

        $robots_of{$file} ||= [];
        push @{$robots_of{$file}}, $robot;
    }
    if (1 < scalar(keys %robots_of)) {
        my $i = 0;
        %sympa_aliases = map {
            $i++;
            map { $_ => sprintf('%s.%03d', $basename, $i) } @{$robots_of{$_}}
        } sort keys %robots_of;
    } else {
        %sympa_aliases = map { $_ => $basename } @domains;
    }

    # Create files.
    foreach my $sympa_aliases (values %sympa_aliases) {
        my $fh;
        unless (open $fh, '>', $sympa_aliases) {    # truncate if exists
            printf STDERR "Unable to create %s: %s\n", $sympa_aliases, $ERRNO;
            exit 1;
        }
        close $fh;
    }

    # Write files.
    foreach my $robot (sort @domains) {
        my $alias_manager = Conf::get_robot_conf($robot, 'alias_manager');
        my $sympa_aliases = $sympa_aliases{$robot};

        my $aliases =
            Sympa::Aliases->new($alias_manager, file => $sympa_aliases);
        next
            unless $aliases and $aliases->isa('Sympa::Aliases::Template');

        my $fh;
        unless (open $fh, '>>', $sympa_aliases) {    # append
            printf STDERR "Unable to create %s: %s\n", $sympa_aliases, $ERRNO;
            exit 1;
        }
        printf $fh "#\n#\tAliases for all Sympa lists open on %s\n#\n",
            $robot;
        close $fh;

        my $all_lists = Sympa::List::get_lists($robot);
        foreach my $list (@{$all_lists || []}) {
            next unless $list->{'admin'}{'status'} eq 'open';

            $aliases->add($list);
        }
    }

    if (1 < scalar(keys %robots_of)) {
        printf
            "Sympa aliases files %s.??? were made.  You probably need to install them in your SMTP engine.\n",
            $basename;
    } else {
        printf
            "Sympa aliases file %s was made.  You probably need to install it in your SMTP engine.\n",
            $basename;
    }
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-make_alias_file - Create aliases file

=head1 SYNOPSIS

C<sympa.pl make_alias_file> I<domain>|C<"*"> [ I<domain> ... ]

=head1 DESCRIPTION

Create an aliases file in the temporary directory
(specified by C<tmpdir> parameter) with all list aliases. It uses the
F<list_aliases.tt2> template  (useful when F<list_aliases.tt2> was changed).

=cut
