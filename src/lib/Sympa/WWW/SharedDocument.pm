# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2022 The Sympa Community. See the
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

package Sympa::WWW::SharedDocument;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Find qw();
use POSIX qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Scenario;
use Sympa::Tools::File;
use Sympa::Tools::Text;

# Creates a new object.
sub new {
    my $class   = shift;
    my $list    = shift;
    my $path    = shift;
    my %options = @_;

    die 'bug in logic. Ask developer' unless ref $list eq 'Sympa::List';

    my $paths;
    if (ref $path eq 'ARRAY') {
        $paths = $path;
    } elsif (defined $path and length $path) {
        $paths = [split m{/+}, $path];
    } else {
        $paths = [];
    }

    unless (@$paths) {
        return $class->_new_root($list);
    } else {
        my $parent_paths = [@$paths];
        my $name         = pop @$parent_paths;
        return undef
            unless defined $name
            and length $name
            and $name !~ /\A[.]+\z/
            and $name !~ /\A[.]desc(?:[.]|\z)/;

        my $parent = $class->new($list, $parent_paths);
        return undef unless $parent;

        #FIXME: At present, conversion by qencode_filename() /
        # qdecode_filename() may not be bijective.  So we take the first one
        # of (possibly multiple) matching paths insted of taking encoded one.
        my ($self) = $parent->get_children(%options, name => $name);
        return $self;
    }
}

sub _new_root {
    my $class = shift;
    my $list  = shift;

    my $status;
    if (-e $list->{'dir'} . '/shared') {
        $status = 'exist';
    } elsif (-e $list->{'dir'} . '/pending.shared') {
        $status = 'deleted';
    } else {
        $status = 'none';
    }

    bless {
        context => $list,
        fs_name => '',
        fs_path => $list->{'dir'} . '/shared',
        name    => '',
        paths   => [],
        status  => $status,
        type    => 'root',
    } => $class;
}

sub _new_child {
    my $self    = shift;
    my $fs_name = shift;
    my %options = @_;

    # Document isn't a description file.
    # It exists.
    # It has non-zero size.
    return undef
        if $fs_name =~ /\A[.]+\z/
        or $fs_name =~ /\A[.]desc(?:[.]|\z)/;
    return undef unless -e $self->{fs_path} . '/' . $fs_name;
    unless (exists $options{allow_empty} and $options{allow_empty}) {
        return undef unless -s $self->{fs_path} . '/' . $fs_name;
    }

    my $child = bless {
        context => $self->{context},
        parent  => $self
    } => (ref $self);

    my $stem;
    if ($fs_name =~ /\A[.](.*)[.]moderate\z/) {
        $stem = $1;
        $child->{moderate} = 1;
    } else {
        $stem = $fs_name;
    }
    $child->{fs_name} = $fs_name;
    $child->{fs_path} = $self->{fs_path} . '/' . $fs_name;
    $child->{name}    = Sympa::Tools::Text::qdecode_filename($stem);
    $child->{paths}   = [@{$self->{paths}}, $child->{name}];

    $child->{file_extension} = $1 if $stem =~ /[.](\w+)\z/;
    $child->{type} =
          (-d $child->{fs_path}) ? 'directory'
        : ($child->{file_extension} and $child->{file_extension} eq 'url')
        ? 'url'
        : 'file';

    if (exists $options{name}) {
        return undef if $child->{name} ne $options{name};
    }
    if (exists $options{moderate}) {
        return undef if $child->{moderate} xor $options{moderate};
    }

    ## Check access control
    #check_access_control($child, $param);

    # Date.
    $child->{date_epoch} = Sympa::Tools::File::get_mtime($child->{fs_path});
    # Size of the doc.
    $child->{size} = (-s $child->{fs_path}) / 1000;

    # Load .desc file unless root directory.
    my %desc = $child->_load_desc;
    if (%desc) {
        $child->{serial_desc} = $desc{serial_desc};
        $child->{owner}       = $desc{email};
        $child->{title}       = $desc{title};
        $child->{scenario}    = {read => $desc{read}, edit => $desc{edit}};
    }

    if (exists $options{owner}) {
        return undef unless defined $child->{owner};
        return undef if $child->{owner} ne $options{owner};
    }

    # File, directory or URL ?
    my $robot_id = $self->{context}->{'domain'};
    if ($child->{type} eq 'url') {
        $child->{icon} = _get_icon($robot_id, 'url');

        if (open my $fh, $child->{fs_path}) {
            my $url = <$fh>;
            close $fh;
            chomp $url;
            $child->{url} = $url;
        }

        if ($child->{name} =~ /\A(.+)[.]url\z/) {
            $child->{label} = $1;
        }
    } elsif ($child->{type} eq 'file') {
        if ($child->{file_extension}
            and grep { lc $child->{file_extension} eq $_ } qw(htm html)) {
            # HTML.
            $child->{mime_type} = 'text/html';

            $child->{html} = 1;
            $child->{icon} = _get_icon($robot_id, 'text');
        } elsif (my $type =
            Conf::get_mime_type($child->{file_extension} || '')) {
            $child->{mime_type} = lc $type;

            # Type of the icon.
            my $mimet;
            if (lc $type eq 'application/octet-stream') {
                $mimet = 'octet-stream';
            } else {
                ($mimet) = split m{/}, $type;
            }
            $child->{icon} = _get_icon($robot_id, $mimet)
                || _get_icon($robot_id, 'unknown');
        } else {
            # Unknown file type.
            $child->{icon} = _get_icon($robot_id, 'unknown');
        }
    } else {
        # Directory.
        $child->{icon} = _get_icon($robot_id, 'folder');
    }

    $child;
}

sub _load_desc {
    my $self = shift;

    my $desc_file = $self->_desc_file;
    return unless $desc_file and -e $desc_file;

    my %desc = _load_desc_file($desc_file);
    $desc{serial_desc} = Sympa::Tools::File::get_mtime($desc_file);

    return %desc;
}

# Gets path of property description on physical filesystem.
sub _desc_file {
    my $self = shift;

    return (-d $self->{fs_path})
        ? ($self->{fs_path} . '/.desc')
        : ($self->{parent}->{fs_path} . '/.desc.' . $self->{fs_name});
}

# Old name: Sympa::Tools::WWW::get_desc_file().
#FIXME: Generalize parsing.
#FIXME: Lock file.
sub _load_desc_file {
    my $file = shift;

    my $line;
    my %hash;

    open my $fh, '<', $file or return;    #FIXME: Check errors.

    while ($line = <$fh>) {
        if ($line =~ /^title\s*$/) {
            # Title of the document
            while ($line = <$fh>) {
                last if ($line =~ /^\s*$/);
                $line =~ /^\s*(\S.*\S)\s*/;
                $hash{'title'} = $hash{'title'} . $1 . " ";
            }
        }

        if ($line =~ /^creation\s*$/) {
            # Creation of the document.
            while ($line = <$fh>) {
                last if ($line =~ /^\s*$/);
                if ($line =~ /^\s*email\s*(\S*)\s*/) {
                    $hash{'email'} = $1;
                }
                if ($line =~ /^\s*date_epoch\s*(\d*)\s*/) {
                    $hash{'date'} = $1;
                }
            }
        }

        if ($line =~ /^access\s*$/) {
            # Access scenarios for the document.
            while ($line = <$fh>) {
                last if ($line =~ /^\s*$/);
                if ($line =~ /^\s*read\s*(\S*)\s*/) {
                    $hash{'read'} = $1;
                }
                if ($line =~ /^\s*edit\s*(\S*)\s*/) {
                    $hash{'edit'} = $1;
                }
            }
        }
    }

    close $fh;

    return %hash;
}

# Hash of the icons linked with a type of file.
# Note: Image icons are no longer used by templates. This is kept for
# backward compatibility.
my %icons = (
    'unknown'        => 'unknown.png',
    'folder'         => 'folder.png',
    'current_folder' => 'folder.open.png',
    'application'    => 'unknown.png',
    'octet-stream'   => 'binary.png',
    'audio'          => 'sound1.png',
    'image'          => 'image2.png',
    'text'           => 'text.png',
    'video'          => 'movie.png',
    'father'         => 'back.png',
    'sort'           => 'down.png',
    'url'            => 'link.png',
    'left'           => 'left.png',
    'right'          => 'right.png',
);

# Old name: Sympa::Tools::WWW::get_icon().
# Note: Image icons are no longer used by templates. This is kept for
# backward compatibility.
sub _get_icon {
    my $robot = shift || '*';
    my $type = shift;

    return undef unless defined $icons{$type};
    return
          Conf::get_robot_conf($robot, 'static_content_url')
        . '/icons/'
        . $icons{$type};
}

sub as_hashref {
    my $self = shift;

    my %hash = %$self;
    $hash{context} = {
        name => $self->{context}->{'name'},
        # Compat. < 6.2.32
        host => $self->{context}->{'domain'},
    };
    $hash{parent} = $self->{parent}->as_hashref if $self->{parent};
    $hash{paths} = [@{$self->{paths}}];

    # Special items.
    # The i18n'ed date.
    $hash{date} =
        Sympa::Language->instance->gettext_strftime('%d %b %Y %H:%M:%S',
        localtime $self->{date_epoch})
        if defined $self->{date_epoch};
    # Path components with trailing slash.
    $hash{paths_d} = [@{$self->{paths}}];
    push @{$hash{paths_d}}, ''
        if grep { $self->{type} eq $_ } qw(root directory);

    my @ancestors;
    my $p = $self->{parent};
    while ($p) {
        unshift @ancestors,
            {
            name    => $p->{name},
            paths   => $p->{paths},
            paths_d => [@{$p->{paths}}, ''],
            type    => $p->{type},
            };
        $p = $p->{parent};
    }
    $hash{ancestors} = [@ancestors];

    return {%hash};
}

# Old name: Sympa::List::create_shared().
sub create {
    my $self = shift;

    unless ($self->{type} eq 'root') {
        $ERRNO = POSIX::EINVAL();
        return undef;
    }
    return undef unless CORE::mkdir $self->{fs_path}, 0777;

    $self->{status} = 'exist';
    return 1;
}

sub create_child {
    my $self     = shift;
    my $new_name = shift;
    my %options  = @_;

    $options{type} ||= 'directory';

    if (not Sympa::WWW::SharedDocument::valid_name($new_name)) {
        $ERRNO = POSIX::EINVAL();
        return undef;
    }

    my $new_fs_name =
        $options{moderate}
        ? '.' . Sympa::Tools::Text::qencode_filename($new_name) . '.moderate'
        : Sympa::Tools::Text::qencode_filename($new_name);
    my $new_fs_path = $self->{fs_path} . '/' . $new_fs_name;
    my $new_desc_file =
        ($options{type} eq 'directory')
        ? $new_fs_path . '/.desc'
        : $self->{fs_path} . '/.desc.' . $new_fs_name;

    if ($options{type} eq 'directory') {
        return undef unless mkdir $new_fs_path, 0777;
    } else {
        my $fh;
        return undef unless open $fh, '>', $new_fs_path;
        if (exists $options{content} and defined $options{content}) {
            print $fh $options{content};
        }
        close $fh;
    }

    # Creation of a default description file
    my $fh;
    return undef unless open $fh, '>', $new_desc_file;
    print $fh "title\n";
    print $fh " \n";
    print $fh "\n";
    print $fh "creation\n";
    print $fh "  date_epoch " . time . "\n";
    print $fh "  email $options{owner}\n";
    print $fh "\n";
    print $fh "access\n";
    print $fh "  read $options{scenario}->{read}\n";
    print $fh "  edit $options{scenario}->{edit}\n";
    print $fh "\n";
    close $fh;

    return $self->_new_child($new_fs_name, allow_empty => 1);
}

sub delete {
    my $self = shift;

    unless ($self->{type} eq 'root') {
        $ERRNO = POSIX::EINVAL();
        return undef;
    }

    my $list = $self->{context};
    return undef
        unless CORE::rename $self->{fs_path},
        $list->{'dir'} . '/pending.shared';

    $self->{status} = 'deleted';
    return 1;
}

sub count_children {
    my $self = shift;

    my $dh;
    return undef unless opendir $dh, $self->{fs_path};
    my @children =
        grep { !/\A[.]+\z/ and !/\A[.]desc(?:[.]|\z)/ } sort readdir $dh;
    closedir $dh;

    return scalar @children;
}

sub get_children {
    my $self    = shift;
    my %options = @_;

    my $dh;
    return unless opendir $dh, $self->{fs_path};    #FIXME: Report error.

    my @children =
        sort { _by_order($options{order_by}) }
        grep {$_}
        map { $self->_new_child($_, %options) }
        grep { !/\A[.]+\z/ and !/\A[.]desc(?:[.]|\z)/ } sort readdir $dh;

    closedir $dh;

    return @children;
}

# Function which sorts a hash of documents
# Sort by various parameters
# Old name: by_order() in wwsympa.fcgi.
sub _by_order {
    my $order = shift || 'order_by_doc';

    if ($order eq 'order_by_doc') {
        $a->{name} cmp $b->{name} || $b->{date_epoch} <=> $a->{date_epoch};
    } elsif ($order eq 'order_by_author') {
        $a->{owner} cmp $b->{owner} || $b->{date_epoch} <=> $a->{date_epoch};
    } elsif ($order eq 'order_by_size') {
        $a->{size} <=> $b->{size} || $b->{date_epoch} <=> $a->{date_epoch};
    } elsif ($order eq 'order_by_date') {
        $b->{date_epoch} <=> $a->{date_epoch} || $a->{name} cmp $b->{name};
    } else {
        $a->{name} cmp $b->{name};
    }
}

# OBSOLETED.  Never used.
#sub dump;

# OBSOLETED.  No longer used.
#sub dup;

sub count_moderated_descendants {
    my $self = shift;

    return undef unless -d $self->{fs_path};

    my $count = 0;
    File::Find::find(
        sub { $count++ if !/\A[.]desc([.]|\z)/ and /\A[.].*[.]moderate\z/; },
        $self->{fs_path}
    );
    return $count;
}

# Old name: Sympa::List::get_shared_moderated().
sub get_moderated_descendants {
    my $self = shift;

    return unless -e $self->{fs_path};

    my @moderated = $self->_get_moderated_descendants;
    wantarray ? @moderated : \@moderated;
}

# Old name: Sympa::List::sort_dir_to_get_mod().
sub _get_moderated_descendants {
    my $self = shift;

    my @moderated;
    foreach my $child ($self->get_children) {
        push @moderated, $child
            if $child->{moderate};
        push @moderated, $child->_get_moderated_descendants
            if $child->{type} eq 'directory';
    }
    return @moderated;
}

# Returns a hash with privileges in read, edit, control.

## Regulars
#  read(/) = default (config list)
#  edit(/) = default (config list)
#  control(/) = not defined
#  read(A/B)= (read(A) && read(B)) ||
#             (author(A) || author(B))
#  edit = idem read
#  control (A/B) : author(A) || author(B)
#  + (set owner A/B) if (empty directory &&
#                        control A)

# Arguments:
# (\%mode,$path)
# if mode->{'read'} control access only for read
# if mode->{'edit'} control access only for edit
# if mode->{'control'} control access only for control

# return the hash (
# $result{'may'}{'read'} == $result{'may'}{'edit'} == $result{'may'}{'control'}  if is_author else :
# $result{'may'}{'read'} = 0 or 1 (right or not)
# $result{'may'}{'edit'} = 0(not may edit) or 0.5(may edit with moderation) or 1(may edit ) : it is not a boolean anymore
# $result{'may'}{'control'} = 0 or 1 (right or not)
# $result{'reason'}{'read'} = string for authorization_reject.tt2 when may_read == 0
# $result{'reason'}{'edit'} = string for authorization_reject.tt2 when may_edit == 0
# $result{'scenario'}{'read'} = scenario name for the document
# $result{'scenario'}{'edit'} = scenario name for the document

# Old name: d_access_control() in wwsympa.fcgi,
# Sympa::SharedDocument::check_access_control().
sub get_privileges {
    my $self    = shift;
    my %options = @_;

    my $mode             = $options{mode} || '';
    my $sender           = $options{sender};
    my $auth_method      = $options{auth_method};
    my $scenario_context = $options{scenario_context} || {};

    my $list = $self->{context};

    # Result
    my %result;
    $result{'reason'} = {};

    my $mode_read    = (0 <= index $mode, 'read');
    my $mode_edit    = (0 <= index $mode, 'edit');
    my $mode_control = (0 <= index $mode, 'control');

    # Control for editing
    my $may_read     = 1;
    my $why_not_read = '';
    my $may_edit     = 1;
    my $why_not_edit = '';
    my $is_author    = 0;    # <=> $may_control

    # First check privileges on the root shared directory.
    $result{'scenario'}{'read'} =
        $list->{'admin'}{'shared_doc'}{'d_read'}{'name'};
    $result{'scenario'}{'edit'} =
        $list->{'admin'}{'shared_doc'}{'d_edit'}{'name'};

    # Privileged owner has all privileges.
    if (Sympa::is_listmaster($list, $sender)
        or $list->is_admin('privileged_owner', $sender)) {
        $result{'may'}{'read'}    = 1;
        $result{'may'}{'edit'}    = 1;
        $result{'may'}{'control'} = 1;
        return %result;
    }

    # if not privileged owner
    if ($mode_read) {
        my $result = Sympa::Scenario->new($list, 'd_read')
            ->authz($auth_method, $scenario_context);
        my $action;
        if (ref($result) eq 'HASH') {
            $action       = $result->{'action'};
            $why_not_read = $result->{'reason'};
        }

        $may_read = ($action =~ /\Ado_it\b/i);
    }

    if ($mode_edit) {
        my $result = Sympa::Scenario->new($list, 'd_edit')
            ->authz($auth_method, $scenario_context);
        my $action;
        if (ref($result) eq 'HASH') {
            $action       = $result->{'action'};
            $why_not_edit = $result->{'reason'};
        }
        $action ||= '';

        # edit = 0, 0.5 or 1
        $may_edit =
              ($action =~ /\Ado_it\b/i)  ? 1
            : ($action =~ /\Aeditor\b/i) ? 0.5
            :                              0;
        $why_not_edit = '' if $may_edit;
    }

    # Only authenticated users can edit files.
    unless ($sender) {
        $may_edit     = 0;
        $why_not_edit = 'not_authenticated';
    }

    #if ($mode_control) {
    #    $result{'may'}{'control'} = 0;
    #}

    my $current = $self;
    while ($current and @{$current->{paths}}) {
        if ($current->{scenario}) {
            if ($mode_read) {
                my $result =
                    Sympa::Scenario->new($list, 'd_read',
                    name => $current->{scenario}{read})
                    ->authz($auth_method, $scenario_context);
                my $action;
                if (ref($result) eq 'HASH') {
                    $action       = $result->{'action'};
                    $why_not_read = $result->{'reason'};
                }

                $may_read = $may_read && ($action =~ /\Ado_it\b/i);
                $why_not_read = '' if $may_read;
            }

            if ($mode_edit) {
                my $result =
                    Sympa::Scenario->new($list, 'd_edit',
                    name => $current->{scenario}{edit})
                    ->authz($auth_method, $scenario_context);
                my $action_edit;
                if (ref($result) eq 'HASH') {
                    $action_edit  = $result->{'action'};
                    $why_not_edit = $result->{'reason'};
                }
                $action_edit ||= '';

                # $may_edit = 0, 0.5 or 1
                my $may_action_edit =
                      ($action_edit =~ /\Ado_it\b/i)  ? 1
                    : ($action_edit =~ /\Aeditor\b/i) ? 0.5
                    :                                   0;
                $may_edit =
                     !($may_edit and $may_action_edit) ? 0
                    : ($may_edit == 0.5 or $may_action_edit == 0.5) ? 0.5
                    :                                                 1;
                $why_not_edit = '' if $may_edit;
            }

            # Only authenticated users can edit files.
            unless ($sender) {
                $may_edit     = 0;
                $why_not_edit = 'not_authenticated';
            }

            $is_author = $is_author
                || (($sender || 'nobody') eq $current->{owner});

            unless (defined $result{'scenario'}{'read'}) {
                $result{scenario}{read} = $current->{scenario}{read};
                $result{scenario}{edit} = $current->{scenario}{edit};
            }

            # Author has all privileges.
            if ($is_author) {
                $result{'may'}{'read'}    = 1;
                $result{'may'}{'edit'}    = 1;
                $result{'may'}{'control'} = 1;
                return %result;
            }

        }

        $current = $current->{parent};
    }

    if ($mode_read) {
        $result{'may'}{'read'}    = $may_read;
        $result{'reason'}{'read'} = $why_not_read;
    }

    if ($mode_edit) {
        $result{'may'}{'edit'}    = $may_edit;
        $result{'reason'}{'edit'} = $why_not_edit;
    }

    #if ($mode_control) {
    #    $result{'may'}{'control'} = 0;
    #}

    return %result;
}

# Returns the mode of editing included in $action : 0, 0.5 or 1
# Old name: Sympa::Tools::WWW::find_edit_mode().
# No longer used.
#sub _find_edit_mode {
#    my $action = shift;
#
#    my $result;
#    if ($action =~ /editor/i) {
#        $result = 0.5;
#    } elsif ($action =~ /do_it/i) {
#        $result = 1;
#    } else {
#        $result = 0;
#    }
#    return $result;
#}

# Returns the mode of editing : 0, 0.5 or 1 :
#  do the merging between 2 args of right access edit  : "0" > "0.5" > "1"
#  instead of a "and" between two booleans : the most restrictive right is
#  imposed
# Old name: Sympa::Tools::WWW::merge_edit().
# No longer used.
#sub _merge_edit {
#    my $arg1 = shift;
#    my $arg2 = shift;
#    my $result;
#
#    if ($arg1 == 0 || $arg2 == 0) {
#        $result = 0;
#    } elsif ($arg1 == 0.5 || $arg2 == 0.5) {
#        $result = 0.5;
#    } else {
#        $result = 1;
#    }
#    return $result;
#}

# Old name: Sympa::List::get_shared_size().
sub get_size {
    my $self = shift;

    return undef unless grep { $self->{type} eq $_ } qw(root directory);
    return 0 unless -d $self->{fs_path};
    return Sympa::Tools::File::get_dir_size($self->{fs_path});
}

sub install {
    my $self = shift;

    unless ($self->{moderate} and -e $self->{fs_path}) {
        $ERRNO = POSIX::ENOENT();
        return undef;
    }

    my $new_fs_name;
    if ($self->{fs_name} =~ /\A[.](.+)[.]moderate\z/) {
        $new_fs_name = $1;
    } else {
        $ERRNO = POSIX::ENOENT();
        return undef;
    }
    my $new_fs_path = $self->{parent}->{fs_path} . '/' . $new_fs_name;
    my $desc_file   = $self->_desc_file;
    my $new_desc_file =
          (-d $self->{fs_path})
        ? ($new_fs_path . '/.desc')
        : ($self->{parent}->{fs_path} . '/.desc.' . $new_fs_name);

    # Rename the old file in .old if exists.
    if (-e $new_fs_path) {
        return undef
            unless CORE::rename $new_fs_path, $new_fs_path . '.old';
        if (-e $new_desc_file) {
            return undef
                unless CORE::rename $new_desc_file, $new_desc_file . '.old';
        }
    }
    return undef
        unless CORE::rename $self->{fs_path}, $new_fs_path;
    if (-e $desc_file) {
        return undef
            unless CORE::rename $desc_file, $new_desc_file;
    }

    $self->{fs_path} = $new_fs_path;
    $self->{fs_name} = $new_fs_name;
    delete $self->{moderate};

    return 1;
}

sub rename {
    my $self     = shift;
    my $new_name = shift;

    if ($self->{type} eq 'root') {
        $ERRNO = POSIX::EPERM();
        return undef;
    }
    if (not Sympa::WWW::SharedDocument::valid_name($new_name)
        or ($self->{type} eq 'url' and $new_name !~ /[.]url\z/)) {
        $ERRNO = POSIX::EINVAL();
        return undef;
    }

    my $new_fs_name;
    if ($self->{moderate}) {
        $new_fs_name = '.'
            . Sympa::Tools::Text::qencode_filename($new_name)
            . '.moderate';
    } else {
        $new_fs_name = Sympa::Tools::Text::qencode_filename($new_name);
    }
    my $new_fs_path = $self->{parent}->{fs_path} . '/' . $new_fs_name;
    my $new_paths =
        [@{$self->{paths}}[0 .. ($#{$self->{paths}} - 1)], $new_name];

    return undef
        unless CORE::rename $self->{fs_path}, $new_fs_path;

    # Rename description file.
    unless ($self->{type} eq 'directory') {
        my $desc_file = $self->_desc_file;
        my $new_desc_file =
            $self->{parent}->{fs_path} . '/.desc.' . $new_fs_name;
        if (-e $desc_file) {
            return undef
                unless CORE::rename $desc_file, $new_desc_file;
        }
    }

    @{$self}{qw(fs_name fs_path name paths)} =
        ($new_fs_name, $new_fs_path, $new_name, $new_paths);

    return 1;
}

sub restore {
    my $self = shift;

    unless ($self->{type} eq 'root') {
        $ERRNO = POSIX::EINVAL();
        return undef;
    }

    my $list = $self->{context};
    return undef
        unless CORE::rename $list->{'dir'} . '/pending.shared',
        $self->{fs_path};

    $self->{status} = 'exist';
    return 1;
}

sub rmdir {
    my $self = shift;

    unless ($self->{type} eq 'directory' and -d $self->{fs_path}) {
        $ERRNO = POSIX::ENOTDIR();
        return undef;
    }
    if ($self->count_children) {
        $ERRNO = POSIX::EEXIST();
        return undef;
    }

    if (-e $self->_desc_file) {
        return undef unless CORE::unlink $self->_desc_file;
    }
    CORE::rmdir $self->{fs_path};
}

#FIXME:Generalize serialization.
#FIXME:Lock file.
sub save_description {
    my $self = shift;

    $self->{title} = '' unless defined $self->{title};

    my $fh;
    return undef unless open $fh, '>', $self->_desc_file;

    print $fh "title\n";
    printf $fh "  %s\n", $self->{title};
    print $fh "\n";

    print $fh "access\n";
    printf $fh "  read %s\n", $self->{scenario}{read};
    printf $fh "  edit %s\n", $self->{scenario}{edit};
    print $fh "\n";

    print $fh "creation\n";
    printf $fh "  date_epoch %s\n", $self->{date_epoch};
    printf $fh "  email %s\n",      $self->{owner};
    print $fh "\n";

    close $fh;

    $self->{serial_desc} = Sympa::Tools::File::get_mtime($self->_desc_file);

    return 1;
}

sub unlink {
    my $self = shift;

    if (grep { $self->{type} eq $_ } qw(root directory)) {
        $ERRNO = POSIX::EPERM();
        return undef;
    }

    return undef
        unless CORE::unlink $self->{fs_path};
    my $desc_file = $self->_desc_file;
    if (-e $desc_file) {
        return undef
            unless CORE::unlink $desc_file;
    }

    return 1;
}

sub valid_name {
    my $new_name = shift;

    return undef
        if not defined $new_name
        or $new_name !~ /\S/
        or $new_name =~ /\A[.]/
        or 0 <= index($new_name, '/')
        or $new_name =~ /[<>\\\*\$\[\]\n]/
        or $new_name =~ /[~#\[\]]$/;

    return 1;
}

# Old name: tools::escape_docname().
# DEPRECATED. No longer used.
#sub escape_docname;

sub get_id {
    shift->{fs_path};
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::WWW::SharedDocument - Shared document repository and its nodes

=head1 SYNOPSIS

  use Sympa::WWW::SharedDocument;
  
  $shared = Sympa::WWW::SharedDocument->new($list, $path);
  
  %access = $shared->get_privileges('read', $email, 'md5', {...});
  @children = $shared->get_children;
  $parent = $shared->{parent};

=head1 DESCRIPTION

L<Sympa::WWW::SharedDocument> implements shared document repository of lists.

=head2 Methods

=over

=item new ( $list, [ $path, [ allow_empty =E<gt> 1 ] ] )

I<Constructor>.
Creates new instance.

Parameters:

=over

=item $list

A L<Sympa::List> instance.

=item $path

String to determine path or arrayref of path components.
The path is relative to repository root.

=item allow_empty =E<gt> 1

Don't omit files with zero size.

=back

Returns:

If $path is empty or not specified, returns new instance of repository root;
{status} attribute will be set.
If $path is not empty and the path exists, returns new instance of node.
Otherwise returns false value.

=item as_hashref ( )

I<Instance method>.
Casts the instance to hashref.

Parameters:

None.

Returns:

A hashref including attributes of instance (see L</Attributes>)
and following special items:

=over

=item {ancestors}

Arrayref of hashrefs including some attributes of all ancestor nodes.

=item {context}

Hashref including name and host of the list.

=item {date}

Localized form of {date_epoch}.

=item {parent}

Hashref including attributes of parent node recursively.

=item {paths_d}

Same as {paths} but, if the node is a directory, includes additional empty
component at the end.
This is useful when the path created by join() should be followed by
additional "/" character.

=back

=item count_children ( )

I<Instance method>.
Returns number of child nodes.

=item count_moderated_descendants ( )

I<Instance method>.
Returns number of nodes waiting for moderation.

=item create_child ( $name, owner =E<gt> $email, scenario =E<gt> $scenario,
type =E<gt> $type, [ content => $content ] )

I<Instance method>.
Creates child node and returns it.
TBD.

=item get_children ( [ moderate =E<gt> boolean ], [ name =E<gt> $name ],
[ order_by =E<gt> $order ], [ owner =E<gt> $email ], [ allow_empty =E<gt> 1 ] )

I<Instance method>.
Gets child nodes.

Parameters:

=over

=item moderate =E<gt> boolean

=item name =E<gt> $name

=item owner =E<gt> $email

Filters results.

=item order_by =E<gt> $order

Sorts results.
$order may be one of
C<'order_by_doc'> (by name of nodes),
C<'order_by_author'> (by owner),
C<'order_by_size'> (by size),
C<'order_by_date'> (by modification time).
Default is ordering by names.

=item allow_empty =E<gt> 1

Don't omit nodes with zero size.

=back

Returns:

(Possibly empty) list of child nodes.

=item get_moderated_descendants ( )

I<Instance method>.
Returns the list of nodes waiting for moderation.

Parameters:

None.

Returns:

In array context, a list of nodes.
In scalar context, an arrayref of them.

=item get_privileges ( mode =E<gt> $mode, sender =E<gt> $sender,
auth_method =E<gt> $auth_method, scenario_context =E<gt> $scenario_context )

I<Instance method>.
Gets privileges of a user on the node.

TBD.

=item get_size ( )

I<Instance method>.
Gets total size under current node.

=item install ( )

I<Instance method>.
Approves (install) file if it was held for moderation.

Returns:

True value.
If installation failed, returns false value and sets $ERRNO ($!).

=item rename ( $new_name )

I<Instance method>.
Renames file or directory.

Parameters:

=over

=item $new_name

The name to be renamed to.

=back

Returns:

True value.
If renaming failed, returns false value and sets $ERRNO ($!).

=item rmdir ( )

I<instance method>.
Removes directory from repository.
Directory must be empty.

Returns:

True value.
If removal failed, returns false value and sets $ERRNO ($!).

=item save_description ( )

I<Instance method>.
Creates or updates property description of the node.

=item unlink ( )

I<instance method>.
Removes file from repository.

Returns:

True value.
If removal failed, returns false value and sets $ERRNO ($!).

=item get_id ( )

I<Instance method>.
Returns unique identifier of instance.

=back

=head3 Methods for repository root

=over

=item create ( )

I<Instance method>.
Creates document repository on physical filesystem.

=item delete ( )

I<Instance method>.
Deletes document repository.

=item restore ( )

I<Instance method>.
Restores deleted document repository.

=back

=head2 Functions

=over

=item valid_name ( $new_name )

I<Function>.
Check if the name is allowed for directory and file.

Note:
This should be used with name of newly created node.
Existing files and directories may have the name not allowed by this function.

=back

=head2 Attributes

Instance of L<Sympa::WWW::SharedDocument> may have following attributes.

=over

=item {context}

I<Mandatory>.
Instance of L<Sympa::List> class the shared document repository belongs to.

=item {date_epoch}

I<Mandatory>.
Modification time of node in Unix time.

=item {file_extension}

File extension if any.

=item {fs_name}

I<Mandatory>.
Name of node on physical filesystem,
i.e. the last part of {fs_path}.

=item {fs_path}

I<Mandatory>.
Full path of node on physical filesystem.

=item {html}

Only in HTML file.
True value will be set.

=item {icon}

URL to icon.

=item {label}

Only in bookmark file.
Label to be shown in hyperlink.

=item {mime_type}

Only in regular file.
MIME content type of the file if it is known.

=item {moderate}

Set if node is held for moderation.

=item {name}

I<Mandatory>.
Name of node accessible by users,
i.e. the last item of {paths}.

=item {owner}

Owner (author) of node,
given by property description.

=item {parent}

Parent node if any.  L<Sympa::WWW::SharedDocument> instance.

=item {paths}

I<Mandatory>.
Arrayref to all path components of node accessible by users.

=item {scenario}{read}

=item {scenario}{edit}

Scenario names to define privileges.
These may be given by property description.

=item {serial_desc}

Modification time of property description in Unix time.
Available if property description exists.

=item {size}

Size of file.

=item {status}

I<Only in repository root>.
Status of repository:
C<'exist'>, C<'deleted'> or C<'none'>.

=item {title}

Description of node,
given by property description.

=item {type}

I<Mandatory>.
Type of node.
C<'root'> (the root of repository), C<'directory'> (directory), C<'url'>
(bookmark file) or C<'file'> (other file).

=item {url}

Only in bookmark file.
URL to be linked.

=back

=head1 FILES

=over

=item I<list home>/shared/

Root of repository.

=item I<... path>/I<name>

Directory or file.

=item I<... path>/.I<name>.moderate

Moderated directory or file.

=item I<... path>/I<name>/.desc

=item I<... path>/.desc.I<name>

=item I<... path>/.desc..I<name>.moderate

Property description of directories or files, not moderated or moderated.

=back

Note:
The path components ("I<name>" above) are encoded to the format suitable to
physical filesystem.
Such conversion will be hidden behind object methods.

=head1 SEE ALSO

L<Sympa::List>,
L<Sympa::Tools::Text/"qdecode_filename">,
L<Sympa::Tools::Text/"qencode_filename">.

=head1 HISTORY

L<SharedDocument> module appeared on Sympa 5.2b.2.

Rewritten L<Sympa::SharedDocument> began to provide OO interface on
Sympa 6.2.17.

It was renamed to L<Sympa::WWW::SharedDocument> on Sympa 6.2.26.

=cut
