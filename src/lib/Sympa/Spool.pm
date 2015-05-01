# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Spool;

use strict;
use warnings;
use Digest::MD5;
use English qw(-no_match_vars);
use POSIX qw();
use Sys::Hostname qw();
use Time::HiRes qw();

use Conf;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;

my $log = Sympa::Log->instance;

sub split_listname {
    my $robot_id = shift || '*';
    my $mailbox = shift;
    return unless defined $mailbox and length $mailbox;

    my $return_path_suffix =
        Conf::get_robot_conf($robot_id, 'return_path_suffix');
    my $regexp = join(
        '|',
        map { quotemeta $_ }
            grep { $_ and length $_ }
            split(
            /[\s,]+/, Conf::get_robot_conf($robot_id, 'list_check_suffixes')
            )
    );

    if (    $mailbox eq 'sympa'
        and $robot_id eq $Conf::Conf{'domain'}) {    # compat.
        return (undef, 'sympa');
    } elsif ($mailbox eq Conf::get_robot_conf($robot_id, 'email')
        or $robot_id eq $Conf::Conf{'domain'}
        and $mailbox eq $Conf::Conf{'email'}) {
        return (undef, 'sympa');
    } elsif ($mailbox eq Conf::get_robot_conf($robot_id, 'listmaster_email')
        or $robot_id eq $Conf::Conf{'domain'}
        and $mailbox eq $Conf::Conf{'listmaster_email'}) {
        return (undef, 'listmaster');
    } elsif ($mailbox =~ /^(\S+)$return_path_suffix$/) {    # -owner
        return ($1, 'return_path');
    } elsif (!$regexp) {
        return ($mailbox);
    } elsif ($mailbox =~ /^(\S+)-($regexp)$/) {
        my ($name, $suffix) = ($1, $2);
        my $type;

        if ($suffix eq 'request') {                         # -request
            $type = 'owner';
        } elsif ($suffix eq 'editor') {
            $type = 'editor';
        } elsif ($suffix eq 'subscribe') {
            $type = 'subscribe';
        } elsif ($suffix eq 'unsubscribe') {
            $type = 'unsubscribe';
        } else {
            $name = $mailbox;
            $type = 'UNKNOWN';
        }
        return ($name, $type);
    } else {
        return ($mailbox);
    }
}

# Old name: SympaspoolClassic::analyze_file_name().
sub unmarshal_metadata {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $spool_dir       = shift;
    my $marshalled      = shift;
    my $metadata_regexp = shift;
    my $metadata_keys   = shift;

    my $data;
    my @matches;
    unless (@matches = ($marshalled =~ /$metadata_regexp/)) {
        $log->syslog('debug',
            'File name %s does not have the proper format: %s',
            $marshalled, $metadata_regexp);
        return undef;
    }
    $data = {
        messagekey => $marshalled,
        map {
            my $value = shift @matches;
            (defined $value and length $value) ? ($_ => $value) : ();
            } @{$metadata_keys}
    };

    my ($robot_id, $listname, $type, $list, $priority);

    $robot_id = lc($data->{'domainpart'})
        if defined $data->{'domainpart'}
            and length $data->{'domainpart'}
            and Conf::valid_robot($data->{'domainpart'}, {just_try => 1});
    ($listname, $type) =
        Sympa::Spool::split_listname($robot_id || '*', $data->{'localpart'});

    $list = Sympa::List->new($listname, $robot_id || '*', {'just_try' => 1})
        if defined $listname;

    ## Get priority
    #FIXME: is this always needed?
    if (exists $data->{'priority'}) {
        # Priority was given by metadata.
        ;
    } elsif ($type and $type eq 'listmaster') {
        ## highest priority
        $priority = 0;
    } elsif ($type and $type eq 'owner') {    # -request
        $priority = Conf::get_robot_conf($robot_id, 'request_priority');
    } elsif ($type and $type eq 'return_path') {    # -owner
        $priority = Conf::get_robot_conf($robot_id, 'owner_priority');
    } elsif ($type and $type eq 'sympa') {
        $priority = Conf::get_robot_conf($robot_id, 'sympa_priority');
    } elsif (ref $list eq 'Sympa::List') {
        $priority = $list->{'admin'}{'priority'};
    } else {
        $priority = Conf::get_robot_conf($robot_id, 'default_list_priority');
    }

    $data->{context} = $list || $robot_id || '*';
    $data->{'listname'} = $listname if $listname;
    $data->{'listtype'} = $type     if defined $type;
    $data->{'priority'} = $priority if defined $priority;

    $log->syslog('debug3', 'messagekey=%s, context=%s, priority=%s',
        $marshalled, $data->{context}, $data->{'priority'});

    return $data;
}

sub marshal_metadata {
    my $message         = shift;
    my $metadata_format = shift;
    my $metadata_keys   = shift;

    #FIXME: Currently only "sympa@DOMAIN" and "LISTNAME(-TYPE)@DOMAIN" are
    # supported.
    my ($localpart, $domainpart);
    if (ref $message->{context} eq 'Sympa::List') {
        ($localpart) = split /\@/,
            $message->{context}->get_list_address($message->{listtype});
        $domainpart = $message->{context}->{'domain'};
    } else {
        my $robot_id = $message->{context} || '*';
        $localpart  = Conf::get_robot_conf($robot_id, 'email');
        $domainpart = Conf::get_robot_conf($robot_id, 'domain');
    }

    my @args = map {
        if ($_ eq 'localpart') {
            $localpart;
        } elsif ($_ eq 'domainpart') {
            $domainpart;
        } elsif ($_ eq 'PID') {
            $PID;
        } elsif ($_ eq 'AUTHKEY') {
            Digest::MD5::md5_hex(time . (int rand 46656) . $domainpart);
        } elsif ($_ eq 'RAND') {
            int rand 10000;
        } elsif ($_ eq 'TIME') {
            Time::HiRes::time();
        } elsif (exists $message->{$_}
            and defined $message->{$_}
            and !ref($message->{$_})) {
            $message->{$_};
        } else {
            '';
        }
    } @{$metadata_keys};

    # Set "C" locale so that decimal point for "%f" will be ".".
    my $locale_numeric = POSIX::setlocale(POSIX::LC_NUMERIC());
    POSIX::setlocale(POSIX::LC_NUMERIC(), 'C');
    my $marshalled = sprintf $metadata_format, @args;
    POSIX::setlocale(POSIX::LC_NUMERIC(), $locale_numeric);
    return $marshalled;
}

sub store_spool {
    my $spool_dir       = shift;
    my $message         = shift;
    my $metadata_format = shift;
    my $metadata_keys   = shift;
    my %options         = @_;

    # At first content is stored into temporary file that has unique name and
    # is referred only by this function.
    my $tmppath = sprintf '%s/T.sympa@_tempfile.%s.%ld.%ld',
        $spool_dir, Sys::Hostname::hostname(), time, $PID;
    my $fh;
    unless (open $fh, '>', $tmppath) {
        die sprintf 'Cannot create %s: %s', $tmppath, $ERRNO;
    }
    print $fh $message->to_string(original => $options{original});
    close $fh;

    # Rename temporary path to the file name including metadata.
    # Will retry up to five times.
    my $tries;
    for ($tries = 0; $tries < 5; $tries++) {
        my $marshalled =
            Sympa::Spool::marshal_metadata($message, $metadata_format,
            $metadata_keys);
        my $path = $spool_dir . '/' . $marshalled;

        my $lock;
        unless ($lock = Sympa::LockedFile->new($path, -1, '+')) {
            next;
        }
        if (-e $path) {
            $lock->close;
            next;
        }

        unless (rename $tmppath, $path) {
            die sprintf 'Cannot create %s: %s', $path, $ERRNO;
        }
        $lock->close;

        # Set mtime to be {date} in metadata of the message.
        my $mtime =
              defined $message->{date} ? $message->{date}
            : defined $message->{time} ? $message->{time}
            :                            time;
        utime $mtime, $mtime, $path;

        return $marshalled;
    }

    unlink $tmppath;
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool - Future base class of Sympa spool subclasses

=head1 SYNOPSIS

TBD.

=head1 DESCRIPTION

This module aims to be the base class for spool subclasses of Sympa.

=head2 Methods

Not implemented yet.

=head2 Low level functions

=over

=item split_listname ( $robot, $mailbox )

I<Function>.
TBD.

Note:
For C<-request> and C<-owner> suffix, this function returns
C<owner> and C<return_path> type, respectively.

=item unmarshal_metadata ( $spool_dir, $marshalled,
$metadata_regexp, $metadata_keys )

I<Function>.
TBD.

=item marshal_metadata ( $message, $metadata_format, $metadata_keys )

I<Function>.
TBD.

=item store_spool ( $spool_dir, $message, $metadata_format, $metadata_keys,
[ key => value, ... ] )

I<Function>.
TBD.

=back

=head1 SEE ALSO

L<Sympa::Message>, especially L<Serialization|Sympa::Message/"Serialization">.

=cut
