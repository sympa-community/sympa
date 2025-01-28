# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::Spool;

use strict;
use warnings;
use Cwd qw();
use Digest::MD5;
use English qw(-no_match_vars);
use POSIX qw();
use Sys::Hostname qw();
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::Family;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Tools::File;

my $log = Sympa::Log->instance;

# Methods.

sub new {
    my $class   = shift;
    my %options = @_;

    die $EVAL_ERROR unless eval sprintf 'require %s', $class->_generator;

    my $self = bless {
        %options,
        %{$class->_directories(%options) || {}},
        _metadatas    => undef,
        _glob_pattern => undef,
    } => $class;

    $self->_create;
    $self->_init(0) or return undef;

    # Build glob pattern (using encoded attributes).
    unless ($self->_no_glob_pattern) {
        my $opts = {%options};
        $self->_filter_pre($opts);
        $self->{_glob_pattern} =
            Sympa::Spool::build_glob_pattern($self->_marshal_format,
            $self->_marshal_keys, %$opts);
    }

    $self;
}

sub _create {
    my $self = shift;

    my $umask = umask oct $Conf::Conf{'umask'};
    foreach my $directory (sort values %{$self->_directories}) {
        unless (-d $directory) {
            $log->syslog('info', 'Creating directory %s of %s',
                $directory, $self);
            unless (mkdir $directory, 0775 or -d $directory) {
                die sprintf 'Cannot create %s: %s', $directory, $ERRNO;
            }
            unless (
                Sympa::Tools::File::set_file_rights(
                    file  => $directory,
                    user  => Sympa::Constants::USER(),
                    group => Sympa::Constants::GROUP()
                )
            ) {
                die sprintf 'Cannot create %s: %s', $directory, $ERRNO;
            }
        }
    }
    umask $umask;
}

sub _init {1}

sub _no_glob_pattern {0}

sub marshal {
    my $self    = shift;
    my $message = shift;
    my %options = @_;

    return Sympa::Spool::marshal_metadata($message, $self->_marshal_format,
        $self->_marshal_keys, %options);
}

sub next {
    my $self    = shift;
    my %options = @_;

    return unless $self->{directory};

    unless ($self->{_metadatas}) {
        $self->{_metadatas} = $self->_load;
    }
    unless ($self->{_metadatas} and @{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        $self->_init(1);
        return;
    }

    while (my $marshalled = shift @{$self->{_metadatas}}) {
        my ($handle, $metadata, $message);

        # Try locking message.  Those locked or removed by other process will
        # be skipped.
        if ($options{no_lock}) {
            next
                unless open $handle, '<',
                $self->{directory} . '/' . $marshalled;
        } else {
            $handle =
                Sympa::LockedFile->new($self->{directory} . '/' . $marshalled,
                -1, $self->_is_collection ? '+' : '+<');
            next unless $handle;
        }

        $metadata = $self->unmarshal($marshalled);

        if ($metadata) {
            if ($options{no_filter}) {
                $self->_filter($metadata);
            } else {
                next unless $self->_filter($metadata);
            }

            if ($self->_is_collection) {
                $message = $self->_generator->new(%$metadata);
            } else {
                my $msg_string = do { local $RS; <$handle> };
                $message = $self->_generator->new($msg_string, %$metadata);
            }
        }

        # Though message might not be deserialized, anyway return the result.
        if ($options{no_lock}) {
            close $handle;
            return ($message, 1);
        } else {
            return ($message, $handle);
        }
    }
    return;
}

sub _filter {1}

sub _load {
    my $self = shift;

    my @entries;
    if ($self->{_glob_pattern}) {
        my $cwd = Cwd::getcwd();
        die sprintf 'Cannot chdir to %s: %s', $self->{directory}, $ERRNO
            unless chdir $self->{directory};
        @entries = glob $self->{_glob_pattern};
        chdir $cwd;
    } else {
        my $dh;
        die sprintf 'Cannot open dir %s: %s', $self->{directory}, $ERRNO
            unless opendir $dh, $self->{directory};
        @entries = readdir $dh;
        closedir $dh;
    }

    my $iscol     = $self->_is_collection;
    my $metadatas = [
        sort grep {
                    !/,lock/
                and !m{(?:\A|/)(?:\.|T\.|BAD-)}
                and ((not $iscol and -f ($self->{directory} . '/' . $_))
                or ($iscol and -d ($self->{directory} . '/' . $_)))
        } @entries
    ];

    return $metadatas;
}

sub _is_collection {0}

sub quarantine {
    my $self   = shift;
    my $handle = shift;

    return undef unless $self->{bad_directory};
    die 'bug in logic. Ask developer' unless ref $handle;

    my $bad_file;

    $bad_file = $self->{bad_directory} . '/' . $handle->basename;
    unless (-d $self->{bad_directory} and $handle->rename($bad_file)) {
        $bad_file = $self->{directory} . '/BAD-' . $handle->basename;
        return undef unless $handle->rename($bad_file);
    }

    return 1;
}

sub remove {
    my $self   = shift;
    my $handle = shift;

    die 'bug in logic.  Ask developer' unless ref $handle;

    if ($self->_is_collection) {
        return undef
            unless rmdir($self->{directory} . '/' . $handle->basename);
        return $handle->close;
    } else {
        return $handle->unlink;
    }
}

sub size {
    scalar @{shift->_load || []};
}

sub store {
    my $self    = shift;
    my $message = shift->dup;
    my %options = @_;

    return if $self->_is_collection;

    $message->{date} = time unless defined $message->{date};

    my $marshalled =
        Sympa::Spool::store_spool($self->{directory}, $message,
        $self->_marshal_format, $self->_marshal_keys, %options,
        _filter_pre => sub { $self->_filter_pre(shift) },);
    return unless $marshalled;

    $log->syslog('notice', '%s is stored into %s as <%s>',
        $message, $self, $marshalled);

    if ($self->_store_key) {
        my $metadata = $self->unmarshal($marshalled);
        return $metadata ? $metadata->{$self->_store_key} : undef;
    }
    return $marshalled;
}

sub _filter_pre {1}

sub _store_key {undef}

sub unmarshal {
    my $self       = shift;
    my $marshalled = shift;

    return Sympa::Spool::unmarshal_metadata(
        $self->{directory},     $marshalled,
        $self->_marshal_regexp, $self->_marshal_keys
    );
}

# Low-level functions.

sub build_glob_pattern {
    my $format  = shift;
    my $keys    = shift;
    my %options = @_;

    if (exists $options{context}) {
        my $context = $options{context};
        if (ref $context eq 'Sympa::List') {
            @options{qw(localpart domainpart)} =
                split /\@/, Sympa::get_address($context);
        } else {
            $options{domainpart} = $context;
        }
    }

    $format =~ s/(%%|%[-#+.\d ]*[l]*\w)/$1 eq '%%' ? '%%' : '%s'/eg;
    my @args =
        map {
        if (exists $options{$_} and defined $options{$_}) {
            my $val = $options{$_};
            $val =~ s/([^0-9A-Za-z\x80-\xFF])/\\$1/g;
            $val;
        } else {
            '*';
        }
        } map {
        lc $_
        } @{$keys || []};
    my $pattern = sprintf $format, @args;
    $pattern =~ s/[*][*]+/*/g;

    # Eliminate patterns contains only punctuations:
    # ',', '.', '_', wildcard etc.
    return ($pattern =~ /[0-9A-Za-z\x80-\xFF]|\\[^0-9A-Za-z\x80-\xFF]/)
        ? $pattern
        : undef;
}

sub split_listname {
    my $robot_id = shift || '*';
    my $mailbox = shift;
    return unless defined $mailbox and length $mailbox;

    my $return_path_suffix =
        Conf::get_robot_conf($robot_id, 'return_path_suffix');
    my $regexp = join '|',
        map { quotemeta $_ }
        @{Conf::get_robot_conf($robot_id, 'list_check_suffixes') // []};

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
            if (   $name eq Conf::get_robot_conf($robot_id, 'email')
                or $robot_id eq $Conf::Conf{'domain'}
                and $name eq $Conf::Conf{'email'}) {        # sympa-request
                ($name, $type) = (undef, 'sympaowner');
            } else {
                $type = 'owner';
            }
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
    my $spool_dir      = shift;
    my $marshalled     = shift;
    my $marshal_regexp = shift;
    my $marshal_keys   = shift;

    my $data;
    my @matches;
    unless (@matches = ($marshalled =~ /$marshal_regexp/)) {
        $log->syslog('debug',
            'File name %s does not have the proper format: %s',
            $marshalled, $marshal_regexp);
        return undef;
    }
    $data = {
        messagekey => $marshalled,
        map {
            my $value = shift @matches;
            (defined $value and length $value) ? (lc($_) => $value) : ();
        } @{$marshal_keys}
    };

    my ($robot_id, $family, $listname, $type, $list, $priority);

    $robot_id = lc($data->{'domainpart'})
        if defined $data->{'domainpart'}
        and length $data->{'domainpart'}
        and Conf::valid_robot($data->{'domainpart'}, {just_try => 1});

    if ($data->{localpart} and 0 == index $data->{localpart}, '@') {
        my $familyname = substr $data->{localpart}, 1;
        $family = Sympa::Family->new($familyname, $robot_id || '*');
    } else {
        ($listname, $type) = Sympa::Spool::split_listname($robot_id || '*',
            $data->{'localpart'});
        $list =
            Sympa::List->new($listname, $robot_id || '*', {'just_try' => 1})
            if defined $listname;
    }

    ## Get priority
    #FIXME: is this always needed?
    if (exists $data->{'priority'}) {
        # Priority was given by metadata.
        ;
    } elsif ($type and $type eq 'sympaowner') {    # sympa-request
        $priority = 0;
    } elsif ($type and $type eq 'listmaster') {
        ## highest priority
        $priority = 0;
    } elsif ($type and $type eq 'owner') {         # -request
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

    $data->{context} = $list || $family || $robot_id || '*';
    $data->{'listname'} = $listname if $listname;
    $data->{'listtype'} = $type     if defined $type;
    $data->{'priority'} = $priority if defined $priority;

    $log->syslog('debug3', 'messagekey=%s, context=%s, priority=%s',
        $marshalled, $data->{context}, $data->{'priority'});

    return $data;
}

sub marshal_metadata {
    my $message        = shift;
    my $marshal_format = shift;
    my $marshal_keys   = shift;
    my %options        = @_;

    # "sympa@DOMAIN", "@FAMILYNAME@DOMAIN" and "LISTNAME(-TYPE)@DOMAIN" are
    # supported.
    my ($localpart, $domainpart);
    my $that = $message->{context};
    if (ref $that eq 'Sympa::List') {
        ($localpart, $domainpart) = split /\@/,
            Sympa::get_address($that, $message->{listtype});
    } elsif (ref $that eq 'Sympa::Family') {
        my $familyname;
        ($familyname, $domainpart) = split /\@/, $that->get_id;
        $localpart = sprintf '@%s', $familyname;
    } else {
        my $robot_id = $that || '*';
        $localpart  = Conf::get_robot_conf($robot_id, 'email');
        $domainpart = Conf::get_robot_conf($robot_id, 'domain');
    }

    my @args = map {
        if ($_ eq 'localpart') {
            $localpart;
        } elsif ($_ eq 'domainpart') {
            $domainpart;
        } elsif (lc $_ ne $_
            and $options{keep_keys}
            and exists $message->{lc $_}
            and defined $message->{lc $_}
            and !ref($message->{lc $_})) {
            # If keep_keys is set, use metadata instead of auto-generated
            # values.
            $message->{lc $_};
        } elsif ($_ eq 'AUTHKEY') {
            Digest::MD5::md5_hex(time . (int rand 46656) . $domainpart);
        } elsif ($_ eq 'KEYAUTH') {
            substr
                Digest::MD5::md5_hex(time . (int rand 46656) . $domainpart),
                0, 16;
        } elsif ($_ eq 'PID') {
            $PID;
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
    } @{$marshal_keys};

    # Set "C" locale so that decimal point for "%f" will be ".".
    my $locale_numeric = POSIX::setlocale(POSIX::LC_NUMERIC());
    POSIX::setlocale(POSIX::LC_NUMERIC(), 'C');
    my $marshalled = sprintf $marshal_format, @args;
    POSIX::setlocale(POSIX::LC_NUMERIC(), $locale_numeric);
    return $marshalled;
}

sub store_spool {
    my $spool_dir      = shift;
    my $message        = shift;
    my $marshal_format = shift;
    my $marshal_keys   = shift;
    my %options        = @_;

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
        my $metadata = {%$message};
        if (ref $options{_filter_pre} eq 'CODE') {
            next unless $options{_filter_pre}->($metadata);
        }

        my $marshalled =
            Sympa::Spool::marshal_metadata($metadata, $marshal_format,
            $marshal_keys);
        next unless defined $marshalled and length $marshalled;
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

Sympa::Spool - Base class of spool classes

=head1 SYNOPSIS

  package Sympa::Spool::FOO;
  
  use base qw(Sympa::Spool);
  
  sub _directories {
      return {
          directory     => '/path/to/spool',
          bad_directory => '/path/to/spool/bad',
      };
  }
  use constant _generator      => 'Sympa::Message';
  use constant _marshal_format => '%s@%s.%ld.%ld,%d';
  use constant _marshal_keys   => [qw(localpart domainpart date PID RAND)];
  use constant _marshal_regexp =>
      qr{\A([^\s\@]+)(?:\@([\w\.\-]+))?\.(\d+)\.(\w+)(?:,.*)?\z};
  
  1;

=head1 DESCRIPTION

This module is the base class for spool subclasses of Sympa.

=head2 Public methods

=over

=item new ( [ options... ] )

I<Constructor>.
Creates new instance of the class.

=item marshal ( $message, [ keep_keys =E<gt> 1 ] )

I<Instance method>.
Gets marshalled key (file name) of the message.

Parameters:

=over

=item $message

Message to be marshalled.

=item keep_keys =E<gt> 1

See marshal_metadata().

=back

=item next ( [ no_filter =E<gt> 1 ], [ no_lock =E<gt> 1 ] )

I<Instance method>.
Gets next message to process, order is controlled by name of spool file and
so on.
Message will be locked to prevent multiple processing of a single message.

Parameters:

=over

=item no_filter =E<gt> 1

Won't skip messages when filter defined by _filter() returns false.

=item no_lock =E<gt> 1

Won't lock messages.

=back

Returns:

Two-elements list of message instance and filehandle locking
a message.
If parsing message fails, list of C<undef> and filehandle.
If no more message found, empty array.

If C<no_lock> is set,
true scalar value will be returned in place of filehandle.

=item quarantine ( $handle )

I<Instance method>.
Quarantines a message.
On filesystem spool,
message will be moved into C<{bad_directory}> of the spool using rename().

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking message.

=back

Returns:

True value if message could be quarantined.
Otherwise false value.

If $handle was not a filehandle, this method will die.

=item remove ( $handle )

I<Instance method>.
Removes a message.

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking message.

=back

Returns:

True value if message could be removed.
Otherwise false value.

If $handle was not a filehandle, this method will die.

=item size ( )

I<Instance method>.
Gets the number of messages the spool contains.

Parameters:

None.

Returns:

Number of messages.

Note:
This method returns the number of messages _load() returns,
not applying _filter().

=item store ( $message, [ original =E<gt> $original ] )

I<Instance method>.
Stores the message into spool.

Parameters:

=over

=item $message

Message to be stored.

=item original =E<gt> $original

If true value is specified and $message was decrypted,
Stores original encrypted form.

=back

Returns:

If storing succeeded, marshalled metadata (file name) of the message.
Otherwise C<undef>.

=item unmarshal ( $marshalled )

I<Instance method>.
Gets metadata from marshalled key (file name).

Parameters:

=over

=item $marshalled

Marshalled key.

=back

Returns:

Hashref containing metadata.

=back

=head2 Properties

Instance of L<Sympa::Spool> may have following properties.

=over

=item Directories

Directories _directories() method returns:
C<{directory}>, C<{bad_directory}> and so on.

=back

=head2 Low level functions

=over

=item build_glob_pattern ( $marshal_format, $marshal_keys,
[ key =E<gt> value, ... ] )

I<Function>.
Builds a glob pattern from parameters and returns it.
If built pattern is empty or contains only punctuations,
i.e. C<[^0-9A-Za-z\x80-\xFF]>, will return C<undef>.

=item split_listname ( $robot, $localpart )

I<Function>.
Split local part of e-mail to list name and type.
Returns an array C<(name, type)>.
Note that the list with returned name may or may not exist.

If local part looks like listmaster or sympa address, name is C<undef> and
type is either C<'listmaster'> or C<'sympa'>.
Otherwise, type is either C<'editor'>, C<'owner'>, C<'return_path'>,
C<'subscribe'>, C<'unsubscribe'>, C<'UNKNOWN'> or C<undef>.

Note:
For C<-request> and C<-owner> suffix, this function returns
C<owner> and C<return_path> types, respectively.

=item store_spool ( $spool_dir, $message, $marshal_format, $marshal_keys,
[ key => value, ... ] )

I<Function>.
Store $message into directory $spool_dir as a file with name as
marshalled metadata using $marshal_format and $marshal_keys.

=item unmarshal_metadata ( $spool_dir, $marshalled,
$marshal_regexp, $marshal_keys )

I<Function>.
Unmarshals metadata.
Returns hashref with keys in arrayref $marshal_keys
and values with substrings captured by regexp $marshal_regexp.
If $marshalled did not match against $marshal_regexp,
returns C<undef>.

The keys C<localpart> and C<domainpart> are special.
Following keys are derived from them:
C<context>, C<listname>, C<listtype>, C<priority>.

=item marshal_metadata ( $message, $marshal_format, $marshal_keys,
[ keep_keys =E<gt> 1 ] )

I<Function>.
Marshals metadata.
Returns formatted string by sprintf() using $marshal_format
and metadatas indexed by keys in arrayref $marshal_keys.

If key is uppercase, it means auto-generated value:
C<'AUTHKEY'>, C<'KEYAUTH'>, C<'PID'>, C<'RAND'>, C<'TIME'>.
Otherwise it means metadata or property of $message.
If C<keep_keys> option (added on 6.2.23b) is set, forces using latter.

sprintf() is executed under C<C> locale:
Full stop (C<.>) is always used for decimal point in floating point number.

=back

=head2 Methods subclass should implement

=over

=item _create ( )

I<Instance method>, I<overridable>.
Creates spool.
By default, creates directories returned by _directories().

=item _directories ( [ options, ... ] )

I<Class or instance method>, I<mandatory for filesystem spool>.
Returns hashref with directory paths related to the spool as values.
It must have keys at least C<directory> and
(if you wish to implement quarantine() method) C<bad_directory>.

=item _filter ( $metadata )

I<Instance method>, I<overridable>.
If it returned false value, processing of $metadata by next() will be skipped.
By default, always returns true value.

This method may modify unmarshalled metadata _and_ deserialized messages
include it.

=item _filter_pre ( $metadata )

I<Instance method>, I<overridable>.
If it returned false value, processing of $metadata by store() will be
skipped.
By default, always returns true value.

This method may modify marshalled metadata _but_ stored messages are not
affected.

=item _generator ( )

I<Class or instance method>, I<mandatory>.
Returns name of the class to serialize and deserialize messages in the spool.
If spool subclass is the collection (see _is_collection),
generator class must implement new().
Otherwise,
generator class must implement dup(), new() and to_string().

=item _glob_pattern ( )

Deprecated.  See _no_glob_pattern ( )

=item _init ( $state )

I<Instance method>.
Additional processing when _load() returns no contents ($state is 1) or
when the spool class is instantiated ($state is 0).

=item _is_collection ( )

I<Instance method>, I<overridable>.
If the class is collection of spool class, returns true value.
By default returns false value.

Collection class does not have store() method.
Its content is the set of spool instances.

=item _load ( )

I<Instance method>, I<overridable>.
Loads sorted content of spool.
Returns arrayref of marshalled metadatas.
By default, returns content of C<{directory}> directory sorted by file name.

=item _marshal_format ( )

=item _marshal_keys ( )

=item _marshal_regexp ( )

I<Instance methods>, I<mandatory for filesystem spool>.
_marshal_format() and _marshal_keys() are used to marshal metadata.
_marshal_keys() and _marshal_regexp() are used to unmarshal metadata.
See also marshal_metadata() and unmarshal_metadata().

=item _no_glob_pattern ( )

I<Class or instance method>, I<overridable for filesystem spool>.
If it returns false value,
glob() is used as much as possible to scan the spool faster.
Otherwise readdir() is used for filesystem spool to get all entries.
By default returns false value.

=item _store_key ( )

I<Instance method>.
If implemented and returns non-empty string,
store() returns an item in metadata specified by this method.
By default store() returns marshalled metadata
(file name on filesystem spool).

=back

=head2 Marshaling and unmarshaling metadata

Spool class gives generator class the B<metadata> to instantiate it.
On spool based on filesystem, it is typically encoded into file names.
For example a file name in incoming spool (L<Sympa::Spool::Incoming>)

  listname-owner@domain.name.143599229.12345

encodes the metadata

  localpart  => 'listname-owner',
  listname   => 'listname',
  listtype   => 'return_path',
  domainpart => 'domain.name',
  date       => 143599229,

Metadata always includes information of B<context>: List, Robot, Site
(or Family).  For example:

- Message in incoming spool bound for E<lt>listname@domain.nameE<gt>:

  context    => Sympa::List <listname@domain.name>,

- Command message in incoming spool bound for E<lt>sympa@domain.nameE<gt>:

  context    => 'domain.name',

- Message sent from Sympa to super-listmaster(s):

  context    => '*'

Context is determined when the generator class is instantiated, and
generally never changed through lifetime of instance.
Thus, constructor of generator class should take context object as an
argument.

C<localpart> is encoded in a bit complex manner.

=over

=item *

If the context is Site or Robot, it is a value of C<email> parameter,
typically "C<sympa>".

=item *

If the context is Family, it is encoded as C<@I<family name>>.
This encoding was added on Sympa 6.2.53b.

=item *

If the context is List, it is encoded as local part of list address
according to listtype (See also L<Sympa/get_address>).

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item default_list_priority

=item email

=item owner_priority

=item list_check_suffix

=item listmaster_email

=item request_priority

=item return_path_suffix

=item sympa_priority

Used to extract metadata from marshalled data (file name).

=item umask

The umask to make directories of spool.

=back

=head1 SEE ALSO

L<Sympa::Message>, especially L<Serialization|Sympa::Message/"Serialization">.

=head1 HISTORY

L<Sympa::Spool> appeared on Sympa 6.2.
It as the base class appeared on Sympa 6.2.6.

build_glob_pattern(), size(), _glob_pattern() and _store_key()
were introduced on Sympa 6.2.8.
_filter_pre() was introduced on Sympa 6.2.10.
marshal(), unmarshal() and C<no_filter> option of next()
were introduced on Sympa 6.2.22.
_no_glob_pattern() was introduced and _glob_pattern() was deprecated
on Sympa 6.2.36.

=cut
