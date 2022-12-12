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

package Sympa::CLI::create;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(input-file=s);
use constant _args    => qw(family|domain?);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $that    = shift // $Conf::Conf{'domain'};

    unless ($options->{input_file}) {
        print STDERR "Error : missing 'input_file' parameter\n";
        exit 1;
    }

    my $action =
        (ref $that eq 'Sympa::Family')
        ? 'create_automatic_list'
        : 'create_list';

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $that,
        action           => $action,
        parameters       => {file => $options->{input_file}},
        sender           => Sympa::get_address($that, 'listmaster'),
        scenario_context => {skip => 1}
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        print STDERR "Could not create list\n";
        exit 1;
    }
    exit 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-create - Create a list

=head1 SYNOPSIS

C<sympa create> C<--input-file=>I</path/to/file.xml> [ I<domain> ]

C<sympa create> C<--input-file=>I</path/to/file.xml> I<family>C<@@>I<domain>

=head1 DESCRIPTION

Create a list with the XML file under specified domain or family.
If the context was not specified, primary domain will be used.

=cut
