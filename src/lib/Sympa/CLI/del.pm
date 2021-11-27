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

package Sympa::CLI::del;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(force|F notify quiet role=s);

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;
    $options->{del} = shift @argv;

#} elsif ($options->{del}) {
    #FIXME The parameter should be a list address.
    unless (0 < index $options->{del}, '@') {
        printf STDERR "Incorrect list address %s\n", $options->{del};
        exit 1;
    }
    my $list;
    unless ($list = Sympa::List->new($options->{del})) {
        printf STDERR "Unknown list name %s\n", $options->{del};
        exit 1;
    }

    $options->{role} //= 'member';
    unless (grep { $options->{role} eq $_ } qw(member owner editor)) {
        printf STDERR "Unknown role \"%s\".\n", $options->{role};
        exit 1;
    }

    my @emails;
    my $content = do { local $RS; <STDIN> };
    foreach (split /\r\n|\r|\n/, $content) {
        next unless /\S/;
        next if /\A\s*#/;    #FIXME: email address can contain '#'

        my ($email) = m{\A\s*(\S+)};
        push @emails, $email;
    }
    unless (@emails) {
        print STDERR "No email addresses found in input.\n";
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'del',
        role             => $options->{role},
        email            => [@emails],
        force            => $options->{force},
        quiet            => $options->{quiet},
        notify           => $options->{notify},
        sender           => Sympa::get_address($list, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Failed to delete email addresses from %s\n",
            $list->get_id;
        exit 1;
    }

    exit 0;

}
1;
