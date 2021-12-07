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

package Sympa::CLI::move;

use strict;
use warnings;

use Conf;
use Sympa;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(mode=s);
use constant _args    => qw(list list_id);

sub _run {
    my $class       = shift;
    my $options     = shift;
    my $list        = shift;
    my $new_list_id = shift;

    my ($listname, $robot_id) = split /\@/, $new_list_id, 2;
    unless (length($robot_id // '')) {
        $robot_id = $list->{'domain'};
    } elsif (not Conf::valid_robot($robot_id)) {
        printf STDERR "Unknown robot \"%s\"\n", $robot_id;
        exit 1;
    }

    unless (grep { ($options->{mode} // 'rename') eq $_ } qw(rename copy)) {
        printf STDERR "Unknown mode %s\n", $options->{mode};
        exit 1;
    }
    my $mode = $options->{mode};

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $robot_id,
        action           => 'move_list',
        current_list     => $list,
        listname         => $listname,
        mode             => $mode,
        sender           => Sympa::get_address($robot_id, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Could not copy list %s to %s\n",
            $list->get_id, $new_list_id;
        exit 1;
    }
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-move - Move or copy the list

=head1 SYNOPSIS

C<sympa move> [ C<--mode=copy> ] I<list>C<@>I<domain> I<new_list>[C<@>I<new_domain>]

=head1 DESCRIPTION

Rename a list or move it to another domain.
If C<--mode=copy> is specified, original list will be kept.

=cut
