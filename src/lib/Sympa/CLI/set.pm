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

package Sympa::CLI::set;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::List;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(role=s);
use constant _args    => qw(list keyvalue*);

sub _run {
    my $class   = shift;
    my $options = shift;
    my $list    = shift;
    my @argv    = @_;

    $options->{role} //= 'member';
    unless (grep { $options->{role} eq $_ } qw(member owner editor)) {
        printf STDERR "Unknown role \"%s\".\n", $options->{role};
        exit 1;
    }

    my %newAttrs;
    foreach my $arg (@argv) {
        # Check for key/values settings.
        last unless ref $arg eq 'ARRAY';
        my ($key, $val) = @$arg;

        unless (grep { $key eq $_ } qw(gecos reception visibility)
            or grep { $options->{role} eq $_ } qw(owner editor)
            and $key eq 'info'
            or $options->{role} eq 'owner' and $key eq 'profile') {
            #FIXME:show warnings
            next;
        }
        $val =~ s/\A\s+//;
        $val =~ s/\s+\z//;

        $newAttrs{$key} = $val;
    }
    unless (%newAttrs) {
        Sympa::CLI->run(qw(help set));
        exit 0;
    }

    my @emails;
    my $content = do { local $RS; <STDIN> };
    foreach (split /\r\n|\r|\n/, $content) {
        next unless /\S/;
        next if /\A\s*#/;    #FIXME: email address can contain '#'

        my ($email) = m{\A\s*(\S+)\s*\z};
        push @emails, $email if $email;
    }
    unless (@emails) {
        print STDERR "No email addresses found in input.\n";
        exit 1;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context => $list,
        action  => 'set',
        role    => $options->{role},
        email   => [@emails],
        %newAttrs,
        sender           => Sympa::get_address($list, 'listmaster'),
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin and $class->_report($spindle)) {
        printf STDERR "Failed to set property of user(s) on %s\n",
            $list->get_id;
        exit 1;
    }

    exit 0;

}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-set - Set properties of users of the list

=head1 SYNOPSIS

C<sympa set> [ C<--role=>I<role> ] I<list>C<@>I<domain> I<key>C<=>I<value> ...

=head1 DESCRIPTION

Set properties of the user(s) in a list. Email addresses of users are read
from standard input.
The data should contain one email address per line.

Option:

=over

=item C<--role=>I<role>

Traget role: C<member>, C<editor> or C<owner>.
By default the member is assumed.

=back

Parameters:

I<list>C<@>I<domain>
is mandatory parameter to specify target list.

I<key>C<=>I<value> ...
is the name and value of each attribute of users.
Following keys are available:

=over

=item gecos

Display name.

=item reception

Reception mode.

=item visibility

Visibility.

=item info

Owner or editor only.  Secrect information.

=item profile

Owner only.
Privileges of the owner.  C<normal> or C<privileged>.

=back

With C<gecos> or C<info>,
empty value may be used to delete attribute.

=head1 HISTORY

This option was added on Sympa 6.2.71b.

=cut
