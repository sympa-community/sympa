# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2019, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::Archive;

use strict;
use warnings;
use Cwd qw();
use Digest::MD5 qw();
use Encode qw();
use English qw(-no_match_vars);
use File::Path qw();
use IO::File;
use POSIX qw();

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Message;
use Sympa::Spool;
use Sympa::Tools::File;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

sub new {
    my $class   = shift;
    my %options = @_;

    my $list = $options{context};
    die 'Bug in logic.  Ask developer' unless ref $list eq 'Sympa::List';

    my $self = bless {
        context           => $list,
        base_directory    => $list->get_archive_dir,
        arc_directory     => undef,
        directory         => undef,
        deleted_directory => undef,
        _metadatas        => undef,
    } => $class;

    $self->_create_spool(%options);

    return $self;
}

sub _create_spool {
    my $self    = shift;
    my %options = @_;

    my $umask = umask oct $Conf::Conf{'umask'};
    foreach my $directory ($Conf::Conf{'arc_path'}, $self->{base_directory}) {
        if (-d $directory) {
            next;
        } elsif ($options{create}) {
            $log->syslog('info', 'Creating spool %s', $directory);
            unless (
                mkdir($directory, 0755)
                and Sympa::Tools::File::set_file_rights(
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

sub add_archive {
    my $self = shift;
    my $arc  = shift;

    return undef unless $arc;
    return undef unless $arc =~ /\A\d{4}-\d{2}\z/;

    my $umask = umask oct $Conf::Conf{'umask'};
    my $error;
    File::Path::make_path(
        $self->{base_directory} . '/' . $arc . '/arctxt',
        {   mode  => 0775,
            owner => Sympa::Constants::USER(),
            group => Sympa::Constants::GROUP(),
            error => \$error
        }
    );
    umask $umask;

    if (@$error) {
        return undef;
    }
    return 1;
}

sub purge_archive {
    my $self = shift;
    my $arc  = shift;

    return undef unless $arc;
    return undef unless $arc =~ /\A\d{4}-\d{2}\z/;

    my $error;
    File::Path::remove_tree($self->{base_directory} . '/' . $arc,
        {error => \$error});

    if (@$error) {
        return undef;
    }
    return 1;
}

sub select_archive {
    my $self    = shift;
    my $arc     = shift;
    my %options = @_;

    return undef unless $arc;
    return undef unless $arc =~ /\A\d{4}-\d{2}\z/;

    my $arc_directory     = $self->{base_directory} . '/' . $arc;
    my $directory         = $arc_directory . '/arctxt';
    my $deleted_directory = $arc_directory . '/deleted';

    my $dh;
    unless (opendir $dh, $directory) {
        if (-d $directory) {
            $log->syslog('err', 'Failed to open archive directory %s: %s',
                $directory, $ERRNO);
        }
        return;
    }
    closedir $dh;

    undef $self->{_metadatas};
    undef $self->{_html_metadatas};
    $self->{arc_directory}     = $arc_directory;
    $self->{directory}         = $directory;
    $self->{deleted_directory} = $deleted_directory;

    if ($options{info}) {
        return {
            size  => Sympa::Tools::File::get_dir_size($directory),
            mtime => Sympa::Tools::File::get_mtime($directory),
        };
    } elsif ($options{count}) {
        my $count;
        if (open my $fh, '<', $self->{arc_directory} . '/index') {
            $count = <$fh>;
            chomp $count;
            close $fh;
        }
        return {count => ($count || 0)};
    } else {
        return $arc;
    }
}

sub fetch {
    my $self    = shift;
    my %options = @_;

    undef $self->{_metadatas};    # Rewind cache.
    while (1) {
        my ($message, $handle) = $self->next;
        last unless $handle;      # No more messages.
        next unless $message;     # Malformed message.

        if ($options{message_id}) {
            my $message_id = Sympa::Tools::Text::canonic_message_id(
                $message->get_header('Message-Id'))
                || '';
            if ($message_id eq $options{message_id}) {
                undef $self->{_metadatas};    # Rewind cache.
                return ($message, $handle);
            }
        }
    }

    return;
}

sub html_fetch {
    $log->syslog('debug2', '(%s, %s => %s)', @_);
    my $self    = shift;
    my %options = @_;

    return undef unless $self->{arc_directory};
    return undef unless $options{file};

    my $html_file = $self->{arc_directory} . '/' . $options{file};
    my $handle = IO::File->new($html_file, '<');

    unless ($handle) {
        if (-f $html_file) {
            $log->syslog('err', 'Failed to open archive file %s: %s',
                $html_file, $ERRNO);
        }
        return undef;
    }

    my $metadata = {};    # May be empty.
    while (<$handle>) {
        last if /^\s*$/;    ## Metadata end with an emtpy line

        if (/^<!--(\S+): (.*) -->$/) {
            my ($key, $value) = ($1, $2);
            $value = Sympa::Tools::Text::decode_html($value);
            if ($key eq 'X-From-R13') {
                $metadata->{'X-From'} = $value;
                # MHonArc protection of email addresses.
                $metadata->{'X-From'} =~ tr/N-Z[@A-Mn-za-m/@A-Z[a-z/;
                # Remove the gecos.
                $metadata->{'X-From'} =~ s/^.*<(.*)>/$1/g;
            }
            $metadata->{$key} = $value;
        }
    }
    seek $handle, 0, 0;
    $metadata->{html_content} = do { local $RS; <$handle> };
    $metadata->{filename} = $options{file};

    return $metadata;
}

sub next {
    my $self    = shift;
    my %options = @_;

    return unless $self->{directory};

    unless ($self->{_metadatas}) {
        my $dh;
        unless (opendir $dh, $self->{directory}) {
            die sprintf 'Cannot open dir %s: %s', $self->{directory}, $ERRNO;
        }
        $self->{_metadatas} = [
            sort _cmp_numeric grep {
                        !/,lock/
                    and !m{(?:\A|/)(?:\.|T\.|BAD-)}
                    and -f ($self->{directory} . '/' . $_)
            } readdir $dh
        ];
        closedir $dh;

        # The "reverse" option specific to this class is set.
        $self->{_metadatas} = [reverse @{$self->{_metadatas}}]
            if $options{reverse};
    }
    unless (@{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        return;
    }

    while (my $marshalled = shift @{$self->{_metadatas}}) {
        my ($lock_fh, $metadata, $message);

        # Try locking message.  Those locked or removed by other process will
        # be skipped.
        $lock_fh =
            Sympa::LockedFile->new($self->{directory} . '/' . $marshalled,
            -1, '+<');
        next unless $lock_fh;

        $metadata =
            Sympa::Spool::unmarshal_metadata($self->{directory}, $marshalled,
            qr{\A(\d+)\z}, [qw(serial)]);

        if ($metadata) {
            my $msg_string = do { local $RS; <$lock_fh> };
            $message = Sympa::Message->new($msg_string, %$metadata);
        }

        # Metadata doesn't contain context; add it.
        $message->{context} = $self->{context} if $message;

        # Though message might not be deserialized, anyway return the result.
        return ($message, $lock_fh);
    }
    return;
}

sub html_next {
    my $self    = shift;
    my %options = @_;

    return undef unless $self->{arc_directory};

    unless ($self->{_html_metadatas}) {
        my $dh;
        unless (opendir $dh, $self->{arc_directory}) {
            $log->syslog(
                'err',
                'Cannot open dir %s: %s',
                $self->{arc_directory}, $ERRNO
            );
            return undef;
        }
        $self->{_html_metadatas} = [
            sort _cmp_numeric grep {
                        !/,lock/
                    and !m{(?:\A|/)(?:\.|T\.|BAD-)}
                    and -f ($self->{arc_directory} . '/' . $_)
            } readdir $dh
        ];
        closedir $dh;

        # The "reverse" option specific to this class is set.
        $self->{_html_metadatas} = [reverse @{$self->{_html_metadatas}}]
            if $options{reverse};
    }
    unless (@{$self->{_html_metadatas}}) {
        undef $self->{_html_metadatas};
        return undef;
    }

    while (my $marshalled = shift @{$self->{_html_metadatas}}) {
        return $self->html_fetch(file => $marshalled);
    }
    return undef;
}

sub _cmp_numeric {
    my $a_num = $1 if defined $a and $a =~ /(\d+)/;
    my $b_num = $1 if defined $b and $b =~ /(\d+)/;
    if (defined $a_num and defined $b_num) {
        return $a_num <=> $b_num || $a cmp $b;
    } else {
        return $a cmp $b;
    }
}

sub remove {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self   = shift;
    my $handle = shift;

    return undef unless $self->{arc_directory};

    my $list = $self->{context};

    # Move text message to deleted/ directory.
    unless (-d $self->{deleted_directory}) {
        my $umask = umask oct $Conf::Conf{'umask'};
        unless (mkdir $self->{deleted_directory}, 0777) {
            die sprintf 'Unable to create %s: %s',
                $self->{deleted_directory}, $ERRNO;
        }
        umask $umask;
    }
    unless (
        $handle->rename($self->{deleted_directory} . '/' . $handle->basename))
    {
        $log->syslog('info', 'Unable to rename message %s in archive %s: %s',
            $handle->basename, $self, Sympa::LockedFile->last_error);
        return undef;
    }

    # Remove directory if empty arctxt.
    rmdir $self->{directory};

    return 1;
}

# Old name: remove() in archived.pl.
sub html_remove {
    my $self  = shift;
    my $msgid = shift;

    return undef unless $self->{arc_directory};
    return undef unless $msgid and $msgid !~ /NO-ID-FOUND\.mhonarc\.org/;

    my $list = $self->{context};

    # Remove message from HTML archive.
    system(
        Conf::get_robot_conf($list->{'domain'}, 'mhonarc'),
        '-outdir' => $self->{arc_directory},
        '-rmm'    => $msgid
    );

    # Remomve urlized message.
    my $url_dir =
          $list->{'dir'}
        . '/urlized/'
        . Sympa::Tools::Text::escape_chars($msgid);
    my $error;
    File::Path::remove_tree($url_dir, {error => \$error});

    return 1;
}

# Does the real job : stores the message given as an argument into
# the indicated directory.
# Old name: (part of) mail2arc() in archived.pl.
sub store {
    my $self    = shift;
    my $message = shift;

    my $list = $self->{context};
    my $arc = POSIX::strftime('%Y-%m', localtime $message->{date});
    my $newfile;

    unless ($self->select_archive($arc)) {
        $self->add_archive($arc);
        unless ($self->select_archive($arc)) {
            $log->syslog('err', 'Cannot create directory %s in archive %s',
                $arc, $self);
            return undef;
        }
    }

    # Copy the file in the arctxt.
    if (-f $self->{arc_directory} . "/index") {
        open my $fh, '<', $self->{arc_directory} . '/index'
            or die sprintf 'Can\'t read index of %s in %s: %s', $arc, $self,
            $ERRNO;
        $newfile = <$fh>;
        chomp $newfile;
        $newfile++;
        close $fh;
    } else {
        # recreate index file if needed and update it
        $newfile = _create_idx($self->{arc_directory}) + 1;
    }

    # Save arctxt dump of original message.
    open my $fh, '>', $self->{directory} . '/' . $newfile
        or die sprintf 'Can\'t open file %s/%s: %s', $self->{directory},
        $newfile, $ERRNO;
    print $fh $message->as_string;
    close $fh;

    _save_idx($self->{arc_directory} . '/index', $newfile);

    $log->syslog('notice', 'Message %s is stored into archive %s as <%s>',
        $message, $self, $newfile);
    return $newfile;
}

# Old name: (part of) mail2arc in archived.pl.
sub html_store {
    my $self    = shift;
    my $message = shift->dup;

    my $list = $self->{context};
    my $arc  = POSIX::strftime('%Y-%m', localtime $message->{date});
    my $yyyy = POSIX::strftime('%Y', localtime $message->{date});
    my $mm   = POSIX::strftime('%m', localtime $message->{date});

    unless ($self->select_archive($arc)) {
        $self->add_archive($arc);
        unless ($self->select_archive($arc)) {
            $log->syslog('err', 'Cannot create directory %s in archive %s',
                $arc, $self);
            return undef;
        }
    }

    # Prepare clean message content (HTML parts are cleaned)
    unless ($message->clean_html) {
        $log->syslog('err', "Could not clean message, ignoring message");
        return undef;
    }

    my $mhonarc_ressources =
        Sympa::search_fullpath($list, 'mhonarc-ressources.tt2');

    $log->syslog(
        'debug',
        'Calling %s for list %s',
        Conf::get_robot_conf($list->{'domain'}, 'mhonarc'), $list
    );

    my $tag = _get_tag($list);

    # Call mhonarc on cleaned message source to make clean htlm view of
    # message.
    my @cmd = (
        Conf::get_robot_conf($list->{'domain'}, 'mhonarc'),
        '-add',
        '-addressmodifycode' => '1',    # w/a: Clear old cache in .mhonarc.db.
        '-rcfile'     => $mhonarc_ressources,
        '-outdir'     => $self->{arc_directory},
        '-definevars' => sprintf(
            "listname='%s' hostname=%s yyyy=%s mois=%s yyyymm=%s-%s wdir=%s base=%s/arc tag=%s with_tslice=1 with_powered_by=1",
            $list->{'name'},
            $list->{'domain'},
            $yyyy,
            $mm,
            $yyyy,
            $mm,
            Conf::get_robot_conf($list->{'domain'}, 'arc_path'),
            (Conf::get_robot_conf($list->{'domain'}, 'wwsympa_url') || ''),
            $tag
        ),
        '-umask' => $Conf::Conf{'umask'}
    );

    $log->syslog('debug', 'System call: %s', join(' ', @cmd));

    my $pipeout;
    unless (open $pipeout, '|-', @cmd) {
        $log->syslog('err', 'Could not open pipe: %m');
        return undef;
    }
    print $pipeout $message->as_string;
    close $pipeout;
    my $status = $? >> 8;

    ## Remove lock if required
    if ($status == 75) {
        $log->syslog(
            'notice',
            'Removing lock directory %s',
            $self->{arc_directory} . '/.mhonarc.lck'
        );
        rmdir $self->{arc_directory} . '/.mhonarc.lck';

        my $pipeout;
        unless (open $pipeout, '|-', @cmd) {
            $log->syslog('err', 'Could not open pipe: %m');
            return undef;
        }
        print $pipeout $message->as_string;
        close $pipeout;
        $status = $? >> 8;
    }
    if ($status) {
        $log->syslog(
            'err',
            'Command %s failed with exit code %s',
            join(' ', @cmd), $status
        );
    }

    return 1;
}

# DEPRECATED.  No longer used.
#sub store_last;

# DEPRECATED.  Use get_archives() and select_archive().
#sub list;

# Lists the files included in the archive, preformatted for printing
# Returns an array.
sub get_archives {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    my $base_directory = $self->{base_directory};

    my $dh;
    unless ($base_directory and opendir $dh, $base_directory) {
        $log->syslog('err', 'Cannot open directory %s: %m', $base_directory);
        return;
    }
    my @arcs =
        grep {
        /\A\d\d\d\d\-\d\d\z/
            and -d $base_directory . '/'
            . $_
            . '/arctxt'
        }
        sort readdir $dh;
    closedir $dh;

    return @arcs;
}

# DEPRECATED.  Use select_archive() and next().
#sub scan_dir_archive;

# DEPRECATED.  Use select_archive() and fetch().
#sub search_msgid;

# Old name: Sympa::List::get_arc_size().
sub get_size {
    my $self = shift;
    my $dir  = shift;

    return 0 unless -d $self->{base_directory};
    return Sympa::Tools::File::get_dir_size($self->{base_directory});
}

# OBSOLETED.  No longer used.
sub exist {
    my ($name, $file) = @_;
    my $fn = "$name/$file";

    return $fn if (-r $fn && -f $fn);
    return undef;
}

# return path for latest message distributed in the list
# DEPRECATED.  No longer used.
#sub last_path;

## Load an archived message, returns the mhonarc metadata
## IN : file_path
# DEPRECATED.  Use html_fetch() or html_next().
#sub load_html_message;

# Old name: rebuild() in archived.pl.
sub html_rebuild {
    my $self = shift;
    my $arc  = shift;

    $arc =~ /^(\d{4})-(\d{2})$/;
    my $yyyy = $1;
    my $mm   = $2;

    return unless $self->select_archive($arc);

    my $list          = $self->{context};
    my $listname      = $list->{'name'};
    my $robot_id      = $list->{'domain'};
    my $arc_directory = $self->{arc_directory};

    my $tag = _get_tag($list);
    my $mhonarc_ressources =
        Sympa::search_fullpath($list, 'mhonarc-ressources.tt2');

    # Remove existing HTML files and .mhonarc.db.
    my $dh;
    opendir $dh, $arc_directory;
    unlink map { $arc_directory . '/' . $_ }
        grep {
                $_ ne 'arctxt'
            and $_ ne 'index'
            and $_ ne 'deleted'
            and !/\A\.+\z/
        } readdir $dh;
    closedir $dh;

    my $dir_to_rebuild = $self->{directory};
    my $arcs_dir       = $self->_clean_archive_directory($arc);
    if ($arcs_dir) {
        $dir_to_rebuild = $arcs_dir->{'dir_to_rebuild'};
    }

    # recreate index file if needed
    unless (-f $arc_directory . '/index') {
        _create_idx($arc_directory);
    }

    my @cmd = (
        Conf::get_robot_conf($robot_id, 'mhonarc'),
        '-addressmodifycode' => '1',    # w/a: Clear old cache in .mhonarc.db.
        '-rcfile'     => $mhonarc_ressources,
        '-outdir'     => $arc_directory,
        '-definevars' => sprintf(
            "listname='%s' hostname=%s yyyy=%s mois=%s yyyymm=%s-%s wdir=%s base=%s/arc tag=%s with_tslice=1 with_powered_by=1",
            $listname,
            $robot_id,
            $yyyy,
            $mm,
            $yyyy,
            $mm,
            Conf::get_robot_conf($robot_id, 'arc_path'),
            (Conf::get_robot_conf($robot_id, 'wwsympa_url') || ''),
            $tag
        ),
        '-umask' => $Conf::Conf{'umask'},
        $dir_to_rebuild
    );
    my $exitcode = system(@cmd) >> 8;

    # Delete temporary directory containing files with escaped HTML.
    if ($arcs_dir and -d $arcs_dir->{'cleaned_dir'}) {
        my $error;
        File::Path::remove_tree($arcs_dir->{'cleaned_dir'},
            {error => \$error});
    }

    ## Remove lock if required
    if ($exitcode == 75) {
        $log->syslog(
            'notice',
            'Removing lock directory %s',
            $arc_directory . '/.mhonarc.lck'
        );
        rmdir $arc_directory . '/.mhonarc.lck';

        $exitcode = system(@cmd) >> 8;
    }
    if ($exitcode) {
        $log->syslog(
            'err',
            'Command %s failed with exit code %s',
            join(' ', @cmd), $exitcode
        );
    }
}

# Sets the value of $ENV{'M2H_ADDRESSMODIFYCODE'} and
# $ENV{'M2H_MODIFYBODYADDRESSES'}.
#* $tag a character string (containing the result of _get_tag($list))
# NO LONGER USED.
#sub _set_hidden_mode;

# Empties $ENV{'M2H_ADDRESSMODIFYCODE'}.
# NO LONGER USED.
#sub _unset_hidden_mode;

# Saves the archives index file
#* $index, a string corresponding to the file name to which save an index.
#* $lst, a character string
# Old name: save_idx() in archived.pl.
sub _save_idx {
    my ($index, $lst) = @_;

    return unless $lst;

    if (open my $fh, '>', $index) {
        print $fh "$lst\n";
        close $fh;
    } else {
        die sprintf 'Couldn\'t overwrite index %s: %s', $index, $ERRNO;
    }
}

# Create the 'index' file for one archive subdir
# Old name: create_idx() in archived.pl.
sub _create_idx {
    my $arc_dir = shift;    ## corresponds to the yyyy-mm directory

    my $arc_txt_dir = $arc_dir . '/arctxt';

    if (opendir my $dh, $arc_txt_dir) {
        my @files = sort { $a <=> $b; } grep {/^\d+$/} readdir $dh;
        closedir $dh;
        my $index = $files[$#files] || 0;
        _save_idx($arc_dir . '/index', $index);
        return $index;
    } else {
        $log->syslog('err', 'Failed to open directory %s: %m', $arc_txt_dir);
        return undef;
    }
}

# Old name: clean_archive_directory().
sub _clean_archive_directory {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $self = shift;
    my $arc  = shift;

    return undef unless $self->select_archive($arc);

    my $answer;
    $answer->{'dir_to_rebuild'} = $self->{directory};
    $answer->{'cleaned_dir'}    = sprintf '%s/%s/%s/arctxt',
        $Conf::Conf{'tmpdir'}, $self->{context}->get_id, $arc;
    unless (
        my $number_of_copies = Sympa::Tools::File::copy_dir(
            $answer->{'dir_to_rebuild'},
            $answer->{'cleaned_dir'}
        )
    ) {
        $log->syslog(
            'err',
            'Unable to create a temporary directory where to store files for HTML escaping (%s). Cancelling',
            $number_of_copies
        );
        return undef;
    }
    if (opendir my $dh, $answer->{'cleaned_dir'}) {
        my $files_left_uncleaned = 0;
        foreach my $file (readdir $dh) {
            next if $file =~ /^\./;

            $files_left_uncleaned++
                unless _clean_archived_message(
                $self->{context}->{'domain'},    #FIXME
                $answer->{'cleaned_dir'} . '/' . $file,
                $answer->{'cleaned_dir'} . '/' . $file
                );
        }
        closedir $dh;
        if ($files_left_uncleaned) {
            $log->syslog('err',
                'HTML cleaning failed for %s files in the directory %s',
                $files_left_uncleaned, $answer->{'dir_to_rebuild'});
        }
        $answer->{'dir_to_rebuild'} = $answer->{'cleaned_dir'};
    } else {
        $log->syslog(
            'err',
            'Unable to open directory %s: %m',
            $answer->{'dir_to_rebuild'}
        );
        Sympa::Tools::File::del_dir($answer->{'cleaned_dir'});
        return undef;
    }
    return $answer;
}

# Old name: clean_archived_message().
sub _clean_archived_message {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $robot  = shift;
    my $input  = shift;
    my $output = shift;

    my $message = Sympa::Message->new_from_file($input, context => $robot);
    unless ($message) {
        $log->syslog('err', 'Unable to create a Message object with file %s',
            $input);
        return undef;
    }

    if ($message->clean_html) {
        if (open my $fh, '>', $output) {
            print $fh $message->as_string;
            close $fh;
            return 1;
        } else {
            $log->syslog(
                'err',
                'Unable to create a tmp file to write clean HTML to file %s',
                $output
            );
            return undef;
        }
    } else {
        $log->syslog('err', 'HTML cleaning in file %s failed', $output);
        return undef;
    }
}

# Old names archive::convert_single_msg_2_html(),
# Sympa::Archive::convert_single_message().
sub html_format {
    my $message = shift;
    my %opts    = @_;

    my $that = $message->{context};
    my $list;
    my $robot;
    my $listname;
    my $domain;
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot    = $that->{'domain'};
        $listname = $that->{'name'};
        $domain   = $that->{'domain'};
    } elsif (!ref($that) and $that and $that ne '*') {
        $list     = '';
        $robot    = $that;
        $listname = '';
        $domain   = Conf::get_robot_conf($that, 'domain');
    } else {
        die 'bug in logic.  Ask developer';
    }

    my $msg_as_string = $message->as_string;

    my $destination_dir = $opts{'destination_dir'};
    my $attachment_url  = $opts{'attachment_url'};
    if (ref $attachment_url eq 'ARRAY') {
        $attachment_url = join '/',
            map { Sympa::Tools::Text::encode_uri($_) } @$attachment_url;
    }

    my $mhonarc_ressources =
        Sympa::search_fullpath($that, 'mhonarc-ressources.tt2');
    unless ($mhonarc_ressources) {
        $log->syslog('notice', 'Cannot find any MhOnArc ressource file');
        return undef;
    }

    unless (-d $destination_dir) {
        unless (Sympa::Tools::File::mkdir_all($destination_dir, 0755)) {
            $log->syslog('err', 'Unable to create %s', $destination_dir);
            return undef;
        }
    }

    my $msg_file = $destination_dir . '/msg00000.txt';
    if (open my $fh, '>', $msg_file) {
        print $fh $msg_as_string;
        close $fh;
    } else {
        $log->syslog('notice', 'Can\'t open %s', $msg_file);
        return undef;
    }

    # mhonarc require du change workdir so this proc must retore it
    my $pwd = Cwd::getcwd();

    ## generate HTML
    unless (chdir $destination_dir) {
        $log->syslog('err', 'Could not change working directory to %s',
            $destination_dir);
        return undef;
    }

    my $tag      = _get_tag($that);
    my $exitcode = system(
        Conf::get_robot_conf($robot, 'mhonarc'),
        '-single',
        '-rcfile'     => $mhonarc_ressources,
        '-definevars' => sprintf(
            "listname='%s' hostname=%s yyyy='' mois='' tag=%s with_tslice='' with_powered_by=''",
            $listname, $domain, $tag
        ),
        '-outdir'        => $destination_dir,
        '-attachmentdir' => $destination_dir,
        '-attachmenturl' =>
            sprintf('(%s%% path_cgi %%%s)/%s', $tag, $tag, $attachment_url),
        '-umask'  => $Conf::Conf{'umask'},
        '-stdout' => "$destination_dir/msg00000.html",
        '--',
        $msg_file
    ) >> 8;

    # restore current wd
    chdir $pwd;

    if ($exitcode) {
        $log->syslog(
            'err',
            'Command %s failed with exit code %d',
            Conf::get_robot_conf($robot, 'mhonarc'), $exitcode
        );
    }

    return 1;
}

# Old name: Sympa::Archive::get_tag(), get_tag() in archived.pl.
sub _get_tag {
    my $that = shift;

    my $name;
    if (ref $that eq 'Sympa::List') {
        $name = $that->{'name'};
    } elsif (!ref($that) and $that and $that ne '*') {
        $name = $that;
    } elsif (!ref($that)) {
        $name = '*';
    }

    my $cookie = $Conf::Conf{'cookie'};
    $cookie = '' unless defined $cookie;
    return substr(Digest::MD5::md5_hex(join '/', $cookie, $name), -10);
}

sub get_id {
    my $self = shift;

    my $context = $self->{context};
    unless (ref $context eq 'Sympa::List') {
        return '';
    } elsif ($self->{arc_directory}) {
        return sprintf '%s/%s', $context->get_id,
            [split '/', $self->{arc_directory}]->[-1];
    } else {
        return $context->get_id;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Archive - Archives of Sympa

=head1 SYNOPSIS

  use Sympa::Archive;
  $archive = Sympa::Archive->new(context => $list);

  @arcs = $archive->get_archives;

  $archive->store($message);
  $archive->html_store($message);

  $archive->select_archive('2015-04');
  ($message, $handle) = $archive->next;

  $archive->select_archive('2015-04');
  ($message, $handle) = $archive->fetch(message_id => $message_id);
  $archive->html_remove($message_id);
  $archive->remove($handle);

  $archive->html_rebuild('2015-04');

=head1 DESCRIPTION

L<Sympa::Archive> implements the interface to handle archives.

=head2 Methods and functions

=over

=item new ( context =E<gt> $list, [ create =E<gt> 1 ] )

I<Constructor>.
Creates new instance of L<Sympa::Archive>.

Parameter:

=over

=item context =E<gt> $list

Context of object, a L<Sympa::List> instance.

=item create =E<gt> 1

If necessary, creates directory structure of archive.
Dies if creation fails.
This parameter was introduced on Sympa 6.2.47b.

=back

=item add_archive ( $arc )

I<Instance method>.
Adds archive directory named $arc.
Currently, archive directory must have the form C<YYYY-MM>.

=item purge_archive ( $arc )

I<Instance method>.
Removes archive directory and its content entirely.
removed content can not be recovered.

=item select_archive ( $arc, [ info =E<gt> 1 ] )

I<Instance method>.
Selects an archive directory.
It will be referred by consequent operations.

=item fetch ( message_id =E<gt> $message_id )

I<Instance method>.
Gets a message from archive.
select_archive() must be called in advance.

Message will be locked to prevent multiple processing of a single message.

Parameter:

=over

=item message_id =E<gt> $message_id

Message ID of the message to be fetched.

=back

Returns:

Two-elements list of L<Sympa::Message> instance and filehandle locking
a message.

=item html_fetch ( file =E<gt> $filename )

I<Instance method>.
Gets a metadata of formatted message from HTML archive.
select_archive() must be called in advance.

Parameter:

=over

=item file =E<gt> $filename

File name of the message to be fetched.

=back

Returns:

Hashref.
Note that message won't be locked.

=item get_size ( )

I<Instance method>.
Gets total size of messages in archives.
This method was introduced on Sympa 6.2.17.

=item next ( [ reverse =E<gt> 1 ] )

I<Instance method>.
Gets next message in archive.
select_archive() must be called in advance.

Message will be locked to prevent multiple processing of a single message.

Parameters:

None.

Returns:

Two-elements list of L<Sympa::Message> instance and filehandle locking
a message.

=item html_next ( [ reverse =E<gt> 1 ] )

I<Instance method>.
Gets next metadata of formatted message in archive.
select_archive() must be called in advance.

Parameters:

None.

Returns:

Hashref.
Note that message will not be locked.

=item remove ( $handle )

I<Instance method>.
Removes a message from archive.

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking message.
It is returned by L</fetch>() or L</next>().

=back

Returns:

True value if message could be removed.
Otherwise false value.

=item html_remove ( $message_id )

I<Instance method>.
TBD.

=item store ( $message )

I<Instance method>.
Stores the message into archive.

Parameters:

=over

=item $message

A L<Sympa::Message> instance to be stored.
Following attributes and metadata are referred:

=over

=item {date}

Unix time when the message would be delivered.

=back

=back

Returns:

If storing succeeded, marshalled metadata (file name) of the message.
Otherwise C<undef>.

=item html_store ( $message )

I<Instance method>.
TBD.

=item get_archives ( )

I<Instance method>.
Gets a list of archive directories this archive contains.
Items of returned value may be fed to select_archive() and so on.

=item html_rebuild ( $arc )

I<Instance method>.
Rebuilds archives for the list the name of which is given in the argument
$arc.

Parameters:

=over

=item $arc

A character string containing the name of archive directory in the list
which we want to rebuild.

=back

Returns:

I<undef> if something goes wrong.

=item html_format ( $message,
destination_dir =E<gt> $destination_dir,
attachment_url =E<gt> $attachment_url )

I<Function>.
Converts a message to HTML.

Parameters:

=over

=item $message

Message to be formatted.
L<Sympa::Message> instance.

=item $destination_dir

The directory result is stored in.

=item $attachment_url

Base URL used to link attachments.

Note:
On 6.2.13 and earlier, this option was named "C<attachB<e>ment_url>".

Note:
On 6.2.17 and later, this option may take an arrayref value.
In such case items will be percent-encoded and conjuncted.
Otherwise if a string is given, it will not be encoded.

=back

=item get_id ( )

I<Instance method>.
Gets unique identifier of instance.

=back

=head1 SEE ALSO

L<archived(8)>, L<mhonarc(1)>, L<wwsympa(8)>, L<Sympa::Message>.

=head1 HISTORY

L<Archive> was renamed to L<Sympa::Archive> on Sympa 6.2.

=cut
