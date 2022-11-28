# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::DataSource::SQL;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Database;
use Sympa::Log;
use Sympa::Process;
use Sympa::Tools::Data;

use base qw(Sympa::DataSource);

my $log = Sympa::Log->instance;

# Old name: (part of) Sympa::List::_include_users_sql() and
# Sympa::List::_include_sql_ca().  Entirely rewritten.
sub _open {
    my $self = shift;

    my $list = $self->{context};

    my $db = Sympa::Database->new($self->{db_type}, %$self);
    return undef unless $db and $db->connect;

    my $fh = Sympa::Process::eval_in_time(
        sub {
            my $sth = $db->do_prepared_query($self->{sql_query});
            unless ($sth) {
                $log->syslog('err',
                    'Unable to connect to SQL data source %s', $self);
                return undef;
            }

            #FIXME File::Temp 0.22 or later might be used, but
            # those bundled in Perl 5.8.x are older.
            my $tmpfile = sprintf '%s/%s_SQL_%s.%s.ds',
                $Conf::Conf{'tmpdir'}, $list->get_id, $self->role, $PID;
            my $tmpfh;
            unless (open $tmpfh, '+>', $tmpfile) {
                $log->syslog('err',
                    'Couldn\'t open temporary file for data source %s: %m',
                    $self);
                return undef;
            }
            $self->{_tmpfile} = $tmpfile;

            if ($self->role eq 'custom_attribute') {
                while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
                    next unless $row and %$row;

                    my $email = delete $row->{$self->{email_entry}};
                    next unless defined $email and length $email;
                    $email =~ s/[\t\r\n]+/ /g;
                    foreach my $k (keys %$row) {
                        $row->{$k} = { value => $row->{$k} }
                            unless ref $row->{$k} eq 'HASH' and defined $row->{$k}{value};
                    }
                    printf $tmpfh "%s\t%s\n", $email,
                        Sympa::Tools::Data::encode_custom_attribute($row);
                }
            } else {
                while (my $row = $sth->fetchrow_arrayref) {
                    next unless $row and defined $row->[0];

                    my ($email, $value) = @$row;
                    next unless defined $email and length $email;
                    $email =~ s/[\t\r\n]+/ /g;
                    $value =~ s/[\t\r\n]+/ /g if defined $value;

                    printf $tmpfh "%s\t%s\n", $email, $value // '';
                }
            }
            $sth->finish;

            seek $tmpfh, 0, 0;
            return $tmpfh;
        },
        ($list->{'admin'}{'sql_fetch_timeout'} || 300)
    );
    unless ($fh) {
        my $tmpfile = delete $self->{_tmpfile};
        unlink $tmpfile if $tmpfile;
    }

    unless ($db->disconnect) {
        $log->syslog('info', 'Can\'t close data source %s: %s',
            $self, $db->error);
    }

    return $fh;
}

sub _next {
    my $self = shift;

    my $fh = $self->__dsh;
    while (my $line = <$fh>) {
        chomp $line;
        my ($email, $value) = split /\t/, $line, 2;
        next unless length $email;

        return [$email] unless length $value;
        return [$email, $value];
    }

    return;
}

sub _next_ca {
    my $self = shift;

    my $fh = $self->__dsh;
    while (my $line = <$fh>) {
        chomp $line;
        my ($email, $value) = split /\t/, $line, 2;
        next unless length $email;

        my $ca = Sympa::Tools::Data::decode_custom_attribute($value);
        next unless $ca;

        return [$email, $ca];
    }

    return;
}

sub _close {
    my $self = shift;

    my $fh = $self->__dsh;
    close $fh if $fh;
    my $tmpfile = delete $self->{_tmpfile};
    unlink $tmpfile if $tmpfile;

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::SQL - Data source based on SQL query

=head1 DESCRIPTION

Returns a list of subscribers extracted from an remote Database

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::SQL> appeared on Sympa 6.2.45b.

=cut
