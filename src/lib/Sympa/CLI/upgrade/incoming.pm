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

package Sympa::CLI::upgrade::incoming;

use strict;
use warnings;
use Digest::MD5;
use English qw(-no_match_vars);

use Sympa::Constants;
use Conf;
use Sympa::Log;
use Sympa::Spool;
use Sympa::Spool::Incoming;
use Sympa::Spool::Outgoing;

use parent qw(Sympa::CLI::upgrade);

use constant _options   => qw(dry_run|n);
use constant _args      => qw();
use constant _need_priv => 1;

my $log = Sympa::Log->instance;

sub _run {
    my $class   = shift;
    my $options = shift;

# Get obsoleted parameter.
    open my $fh, '<', Conf::get_sympa_conf() or die $ERRNO;
    my ($cookie) =
        grep {defined} map { /\A\s*cookie\s+(\S+)/s ? $1 : undef } <$fh>;
    close $fh;

    my $bulk      = Sympa::Spool::Outgoing->new;
    my $spool     = Sympa::Spool::Incoming->new;
    my $spool_dir = $spool->{directory};

    mkdir "$spool_dir/moved", 0755 unless -d "$spool_dir/moved";

    while (1) {
        my ($message, $handle) = $spool->next(no_filter => 1);

        if ($message and $handle) {
            my $status =
                process($options, $cookie, $message, $bulk, $spool_dir);
            unless (defined $status) {
                $spool->quarantine($handle) unless $options->{dry_run};
            } elsif ($status) {
                $handle->rename($spool_dir . '/moved/' . $handle->basename)
                    unless $options->{dry_run};
            } else {
                next;
            }
        } elsif ($handle) {
            next;
        } else {
            last;
        }
    }

    return 1;
}

sub process {
    my $options   = shift;
    my $cookie    = shift;
    my $message   = shift;
    my $bulk      = shift;
    my $spool_dir = shift;

    return 0 unless $message->{checksum};

    ## valid X-Sympa-Checksum prove the message comes from web interface with
    ## authenticated sender
    unless (
        $message->{'checksum'} eq sympa_checksum($message->{'rcpt'}, $cookie))
    {
        $log->syslog('err', '%s: Incorrect X-Sympa-Checksum header',
            $message);
        return undef;
    }

    if (ref $message->{context} eq 'Sympa::List') {
        $message->{'md5_check'} = 1;
        delete $message->{checksum};

        # Don't use method of incoming spool to preserve original PID.
        Sympa::Spool::store_spool($spool_dir, $message, '%s@%s.%ld.%ld,%d',
            [qw(localpart domainpart date pid RAND)])
            unless $options->{dry_run};
        $log->syslog('info', '%s: Moved to msg spool', $message);
    } else {
        $bulk->store($message, [split /\s*,\s*/, $message->{rcpt}])
            unless $options->{dry_run};
        $log->syslog('info', '%s: Moved to bulk spool', $message);
    }
    return 1;
}

sub sympa_checksum {
    my $rcpt   = shift;
    my $cookie = shift;

    return substr Digest::MD5::md5_hex(join '/', $cookie, $rcpt), -10;
}

__END__

=encoding utf-8

=head1 NAME

sympa-upgrade-incoming - Upgrade messages in incoming spool

=head1 SYNOPSIS

  sympa upgrade incoming [ --dry_run | -n ]

=head1 DESCRIPTION

On Sympa earlier than 6.2, messages sent from WWSympa were injected in
msg spool with special checksum.
Recent release of Sympa and WWSympa injects outbound messages in outgoing
spool or sends them by Mailer directly.
This program migrates messages with old format in appropriate spools.

=head1 OPTIONS

=over

=item --dry_run, -n

Shows what will be done but won't really perform upgrade process.

=back

=head1 RETURN VALUE

This program exits with status 0 if processing succeeded.
Otherwise exits with non-zero status.

=head1 CONFIGURATION OPTIONS

Following site configuration parameters in F<--CONFIG--> are referred.

=over

=item cookie

(obsoleted by Sympa 6.2.61b)

=item queue

=item umask

=back

=head1 SEE ALSO

L<sympa_config(5)>,
L<Sympa::Message>.

=head1 HISTORY

upgrade_send_spool.pl appeared on Sympa 6.2.

Its function was moved to C<sympa upgrade incoming> command line on
Sympa 6.2.71b.

=cut
