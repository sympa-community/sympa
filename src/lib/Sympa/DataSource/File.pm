# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::DataSource::File;

use strict;
use warnings;

use Sympa::Log;
use Sympa::Regexps;

use base qw(Sympa::DataSource);

my $log = Sympa::Log->instance;

sub _open {
    my $self = shift;

    my $fh;
    unless (open $fh, '<', $self->{path}) {
        $log->syslog('err', 'Unable to open file "%s": %m', $self->{path});
        return undef;
    }

    return $fh;
}

# Old name: (part of) Sympa::List::_include_users_file().
sub _next {
    my $self = shift;

    my $email_re = Sympa::Regexps::addrspec();

    my $lines = 0;
    my $found = 0;

    my $ifh = $self->__dsh;
    while (my $line = <$ifh>) {
        $line =~ s/\s+\z//;    # allow any styles of newline

        if (++$lines > 49 and not $found) {
            $log->syslog(
                'err',
                'Too much errors in file %s. Source file probably corrupted. Cancelling',
                $self->{path}
            );
            return undef;
        }

        # Empty lines are skipped
        next if $line =~ /^\s*$/;
        next if $line =~ /^\s*\#/;

        # Skip badly formed emails.
        unless ($line =~ /\A\s*($email_re)(?:\s+(\S.*))?\z/) {
            $log->syslog('err', 'Skip badly formed line: "%s"', $line);
            next;
        }
        my ($email, $gecos) = ($1, $2);
        $gecos =~ s/\s+\z// if defined $gecos;
        $found++;

        return [$email, $gecos];
    }

    return;
}

sub _close {
    my $self = shift;

    my $fh = $self->__dsh;
    return unless ref $fh;

    unless (close $fh) {
        $log->syslog('info', 'Can\'t close data source %s: %m', $self);
        return undef;
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::file - Data source based on local file

=head1 DESCRIPTION

TBD.

Each line is expected to start with a valid email address and
an optional display name.

=head2 Attributes

=over

=item {name}

Short description of this data source.

=item {path}

Full path to local file.

=back

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::File> appeared on Sympa 6.2.45b.

=cut
