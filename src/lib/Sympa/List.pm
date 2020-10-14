# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::List;

use strict;
use warnings;
use Digest::MD5 qw();
use English qw(-no_match_vars);
use IO::Scalar;
use POSIX qw();
use Storable qw();

use Sympa;
use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Database;
use Sympa::DatabaseDescription;
use Sympa::DatabaseManager;
use Sympa::Family;
use Sympa::Language;
use Sympa::List::Config;
use Sympa::ListDef;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Robot;
use Sympa::Spindle::ProcessRequest;
use Sympa::Spindle::ProcessTemplate;
use Sympa::Spool::Auth;
use Sympa::Template;
use Sympa::Tools::Data;
use Sympa::Tools::Domains;
use Sympa::Tools::File;
use Sympa::Tools::SMIME;
use Sympa::Tools::Text;
use Sympa::User;

my @sources_providing_listmembers = qw/
    include_file
    include_ldap_2level_query
    include_ldap_query
    include_remote_file
    include_remote_sympa_list
    include_sql_query
    include_sympa_list
    /;

# No longer used.
#my @more_data_sources;

# All non-pluggable sources are in the admin user file
# NO LONGER USED.
my %config_in_admin_user_file = map +($_ => 1),
    @sources_providing_listmembers;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

## Database and SQL statement handlers
my ($sth, @sth_stack);

# DB fields with numeric type.
# We should not do quote() for these while inserting data.
my %db_struct = Sympa::DatabaseDescription::full_db_struct();
my %numeric_field;
foreach my $t (qw(subscriber_table admin_table)) {
    foreach my $k (keys %{$db_struct{$t}->{fields}}) {
        if ($db_struct{$t}->{fields}{$k}{struct} =~ /\A(tiny|small|big)?int/)
        {
            $numeric_field{$k} = 1;
        }
    }
}

# This is the generic hash which keeps all lists in memory.
my %list_of_lists = ();

## Creates an object.
sub new {
    my ($pkg, $name, $robot, $options) = @_;
    my $list = {};
    $log->syslog('debug3', '(%s, %s, %s)', $name, $robot,
        join('/', keys %$options));

    # Lowercase list name.
    $name = lc $name;
    # In case the variable was multiple. FIXME:required?
    $name = $1 if $name =~ /^(\S+)\0/;

    ## Allow robot in the name
    if ($name =~ /\@/) {
        my @parts = split /\@/, $name;
        $robot ||= $parts[1];
        $name = $parts[0];
    }

    # Look for the list if no robot was provided.
    if (not $robot or $robot eq '*') {
        #FIXME: Default robot would be used instead of oppotunistic search.
        $robot = search_list_among_robots($name);
    } else {
        $robot = lc $robot;    #FIXME: More canonicalization.
    }

    unless ($robot) {
        $log->syslog('err',
            'Missing robot parameter, cannot create list object for %s',
            $name)
            unless ($options->{'just_try'});
        return undef;
    }

    $options = {} unless (defined $options);

    ## Only process the list if the name is valid.
    #FIXME: Existing lists may be checked with looser rule.
    my $listname_regexp = Sympa::Regexps::listname();
    unless ($name and ($name =~ /^($listname_regexp)$/io)) {
        $log->syslog('err', 'Incorrect listname "%s"', $name)
            unless ($options->{'just_try'});
        return undef;
    }
    ## Lowercase the list name.
    $name = $1;
    $name =~ tr/A-Z/a-z/;

    ## Reject listnames with reserved list suffixes
    my $regx = Conf::get_robot_conf($robot, 'list_check_regexp');
    if ($regx) {
        if ($name =~ /^(\S+)-($regx)$/) {
            $log->syslog(
                'err',
                'Incorrect name: listname "%s" matches one of service aliases',
                $name
            ) unless ($options->{'just_try'});
            return undef;
        }
    }

    my $status;
    ## If list already in memory and not previously purged by another process
    if ($list_of_lists{$robot}{$name}
        and -d $list_of_lists{$robot}{$name}{'dir'}) {
        # use the current list in memory and update it
        $list = $list_of_lists{$robot}{$name};

        $status = $list->load($name, $robot, $options);
    } else {
        # create a new object list
        bless $list, $pkg;

        $options->{'first_access'} = 1;
        $status = $list->load($name, $robot, $options);
    }
    unless (defined $status) {
        return undef;
    }

    return $list;
}

## When no robot is specified, look for a list among robots
sub search_list_among_robots {
    my $listname = shift;

    unless ($listname) {
        $log->syslog('err', 'Missing list parameter');
        return undef;
    }

    ## Search in default robot
    if (-d $Conf::Conf{'home'} . '/' . $listname) {
        return $Conf::Conf{'domain'};
    }

    foreach my $r (keys %{$Conf::Conf{'robots'}}) {
        if (-d $Conf::Conf{'home'} . '/' . $r . '/' . $listname) {
            return $r;
        }
    }

    return 0;
}

## set the list in status error_config and send a notify to listmaster
sub set_status_error_config {
    $log->syslog('debug2', '(%s, %s, ...)', @_);
    my ($self, $msg, @param) = @_;

    unless ($self->{'admin'}
        and $self->{'admin'}{'status'} eq 'error_config') {
        $self->{'admin'}{'status'} = 'error_config';

        # No more save config in error...
        # $self->save_config(tools::get_address($self->{'domain'},
        #     'listmaster'));
        $log->syslog('err',
            'The list %s is set in status error_config: %s(%s)',
            $self, $msg, join(', ', @param));
        Sympa::send_notify_to_listmaster($self, $msg,
            [$self->{'name'}, @param]);
    }
}

# Destroy multiton instance. FIXME
sub destroy_multiton {
    my $self = shift;
    delete $list_of_lists{$self->{'domain'}}{$self->{'name'}};
}

## set the list in status family_closed and send a notify to owners
# Deprecated.  Use Sympa::Request::Handler::close_list handler.
#sub set_status_family_closed;

# Saves the statistics data to disk.
# Deprecated. Use Sympa::List::update_stats().
#sub savestats;

## msg count.
# Old name: increment_msg_count().
sub _increment_msg_count {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    # Be sure the list has been loaded.
    my $file = "$self->{'dir'}/msg_count";

    my %count;
    if (open(MSG_COUNT, $file)) {
        while (<MSG_COUNT>) {
            if ($_ =~ /^(\d+)\s(\d+)$/) {
                $count{$1} = $2;
            }
        }
        close MSG_COUNT;
    }
    my $today = int(time / 86400);
    if ($count{$today}) {
        $count{$today}++;
    } else {
        $count{$today} = 1;
    }

    unless (open(MSG_COUNT, ">$file.$PID")) {
        $log->syslog('err', 'Unable to create "%s.%s": %m', $file, $PID);
        return undef;
    }
    foreach my $key (sort { $a <=> $b } keys %count) {
        printf MSG_COUNT "%d\t%d\n", $key, $count{$key};
    }
    close MSG_COUNT;

    unless (rename("$file.$PID", $file)) {
        $log->syslog('err', 'Unable to write "%s": %m', $file);
        return undef;
    }
    return 1;
}

# Returns the number of messages sent to the list
sub get_msg_count {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    # Be sure the list has been loaded.
    my $file = "$self->{'dir'}/stats";

    my $count = 0;
    if (open(MSG_COUNT, $file)) {
        while (<MSG_COUNT>) {
            if ($_ =~ /^(\d+)\s+(.*)$/) {
                $count = $1;
            }
        }
        close MSG_COUNT;
    }

    return $count;
}
## last date of distribution message .
sub get_latest_distribution_date {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    # Be sure the list has been loaded.
    my $file = "$self->{'dir'}/msg_count";

    my $latest_date = 0;
    unless (open(MSG_COUNT, $file)) {
        $log->syslog('debug2', 'Unable to open %s', $file);
        return undef;
    }

    while (<MSG_COUNT>) {
        if ($_ =~ /^(\d+)\s(\d+)$/) {
            $latest_date = $1 if ($1 > $latest_date);
        }
    }
    close MSG_COUNT;

    return undef if ($latest_date == 0);
    return $latest_date;
}

## Update the stats struct
## Input  : num of bytes of msg
## Output : num of msgs sent
# Old name: List::update_stats().
# No longer used. Use Sympa::List::update_stats(1);
#sub get_next_sequence;

sub get_stats {
    my $self = shift;

    my @stats;
    my $lock_fh = Sympa::LockedFile->new($self->{'dir'} . '/stats', 2, '<');
    if ($lock_fh) {
        @stats = split /\s+/, do { my $line = <$lock_fh>; $line };
        $lock_fh->close;
    }

    foreach my $i ((0 .. 3)) {
        $stats[$i] = 0 unless $stats[$i];
    }
    return @stats[0 .. 3];
}

sub update_stats {
    $log->syslog('debug2', '(%s, %s, %s, %s, %s)', @_);
    my $self  = shift;
    my @diffs = @_;

    my $lock_fh = Sympa::LockedFile->new($self->{'dir'} . '/stats', 2, '+>>');
    unless ($lock_fh) {
        $log->syslog('err', 'Could not create new lock');
        return;
    }

    # Update stats file.
    # Note: The last three fields total, last_sync and last_sync_admin_user
    # were deprecated.
    seek $lock_fh, 0, 0;
    my @stats = split /\s+/, do { my $line = <$lock_fh>; $line };
    foreach my $i ((0 .. 3)) {
        $stats[$i] ||= 0;
        $stats[$i] += $diffs[$i] if $diffs[$i];
    }
    seek $lock_fh, 0, 0;
    truncate $lock_fh, 0;
    printf $lock_fh "%d %.0f %.0f %.0f\n", @stats;

    return unless $lock_fh->close;

    if ($diffs[0]) {
        $self->_increment_msg_count;
    }

    return @stats;
}

sub _cache_publish_expiry {
    my $self = shift;
    my $type = shift;

    my $stat_file;
    if ($type eq 'member') {
        $stat_file = $self->{'dir'} . '/.last_change.member';
    } elsif ($type eq 'admin_user') {
        $stat_file = $self->{'dir'} . '/.last_change.admin';
    } else {
        die 'bug in logic. Ask developer';
    }

    # Touch status file.
    my $fh;
    open $fh, '>', $stat_file and close $fh;
    utime undef, undef, $stat_file;    # required for such as NFS.
}

sub _cache_read_expiry {
    my $self = shift;
    my $type = shift;

    if ($type eq 'member') {
        # If changes have never been done, just now is assumed.
        my $stat_file = $self->{'dir'} . '/.last_change.member';
        $self->_cache_publish_expiry('member') unless -e $stat_file;
        return [stat $stat_file]->[9];
    } elsif ($type eq 'admin_user') {
        # If changes have never been done, just now is assumed.
        my $stat_file = $self->{'dir'} . '/.last_change.admin';
        $self->_cache_publish_expiry('admin_user') unless -e $stat_file;
        return [stat $stat_file]->[9];
    } elsif ($type eq 'edit_list_conf') {
        return [stat Sympa::search_fullpath($self, 'edit_list.conf')]->[9];
    } else {
        die 'bug in logic. Ask developer';
    }
}

sub _cache_get {
    my $self = shift;
    my $type = shift;

    my $lasttime = $self->{_mtime}{$type};
    my $mtime;
    if ($type eq 'total' or $type eq 'is_list_member') {
        $mtime = $self->_cache_read_expiry('member');
    } else {
        $mtime = $self->_cache_read_expiry($type);
    }
    $self->{_mtime}{$type} = $mtime;

    return undef unless defined $lasttime and defined $mtime;
    return undef if $lasttime <= $mtime;
    return $self->{_cached}{$type};
}

sub _cache_put {
    my $self  = shift;
    my $type  = shift;
    my $value = shift;

    return $self->{_cached}{$type} = $value;
}

# Old name: List::extract_verp_rcpt().
# Moved to: Sympa::Spindle::DistributeMessage::_extract_verp_rcpt().
#sub _extract_verp_rcpt;

# Dumps a copy of list users to disk, in text format.
# Old name: Sympa::List::dump() which dumped only members.
sub dump_users {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $role = shift;

    die 'bug in logic. Ask developer'
        unless grep { $role eq $_ } qw(member owner editor);

    my $file = $self->{'dir'} . '/' . $role . '.dump';

    unlink $file . '.old' if -e $file . '.old';
    rename $file, $file . '.old' if -e $file;
    my $lock_fh = Sympa::LockedFile->new($file, 5, '>');
    unless ($lock_fh) {
        $log->syslog(
            'err', 'Failed to save file %s.new: %s',
            $file, Sympa::LockedFile->last_error
        );
        return undef;
    }

    if ($role eq 'member') {
        my %map_field = _map_list_member_cols();

        my $user;
        for (
            $user = $self->get_first_list_member();
            $user;
            $user = $self->get_next_list_member()
        ) {
            foreach my $k (sort keys %map_field) {
                if ($k eq 'custom_attribute') {
                    next unless ref $user->{$k} eq 'HASH' and %{$user->{$k}};
                    my $encoded = Sympa::Tools::Data::encode_custom_attribute(
                        $user->{$k});
                    printf $lock_fh "%s %s\n", $k, $encoded;
                } else {
                    next unless defined $user->{$k} and length $user->{$k};
                    printf $lock_fh "%s %s\n", $k, $user->{$k};
                }
            }

            # Compat.<=6.2.44
            # This is needed for earlier version of Sympa on e.g. remote host.
            print $lock_fh "included 1\n"
                if defined $user->{inclusion};

            print $lock_fh "\n";
        }
    } else {
        my %map_field = _map_list_admin_cols();

        foreach my $user (@{$self->get_current_admins || []}) {
            next unless $user->{role} eq $role;
            foreach my $k (sort keys %map_field) {
                printf $lock_fh "%s %s\n", $k, $user->{$k}
                    if defined $user->{$k} and length $user->{$k};
            }

            # Compat.<=6.2.44
            # This is needed for earlier version of Sympa on e.g. remote host.
            print $lock_fh "included 1\n"
                if defined $user->{inclusion};

            print $lock_fh "\n";
        }
    }

    $lock_fh->close;

    # FIXME:Are these lines required?
    $self->{'_mtime'}{'config'} =
        Sympa::Tools::File::get_mtime($self->{'dir'} . '/config');

    return 1;
}

## Saves the configuration file to disk
sub save_config {
    my ($self, $email) = @_;
    $log->syslog('debug3', '(%s, %s)', $self->{'name'}, $email);

    return undef
        unless ($self);

    my $config_file_name = "$self->{'dir'}/config";

    ## Lock file
    my $lock_fh = Sympa::LockedFile->new($config_file_name, 5, '+<');
    unless ($lock_fh) {
        $log->syslog('err', 'Could not create new lock');
        return undef;
    }

    my $name                 = $self->{'name'};
    my $old_serial           = $self->{'admin'}{'serial'};
    my $old_config_file_name = "$self->{'dir'}/config.$old_serial";

    ## Update management info
    $self->{'admin'}{'serial'}++;
    $self->{'admin'}{'update'} = {
        'email'      => $email,
        'date_epoch' => time,
    };

    unless (
        $self->_save_list_config_file(
            $config_file_name, $old_config_file_name
        )
    ) {
        $log->syslog('info', 'Unable to save config file %s',
            $config_file_name);
        $lock_fh->close();
        return undef;
    }

    ## Also update the binary version of the data structure
    if (Conf::get_robot_conf($self->{'domain'}, 'cache_list_config') eq
        'binary_file') {
        eval {
            Storable::store($self->{'admin'}, "$self->{'dir'}/config.bin");
        };
        if ($@) {
            $log->syslog('err',
                'Failed to save the binary config %s. error: %s',
                "$self->{'dir'}/config.bin", $@);
        }
    }

    ## Release the lock
    unless ($lock_fh->close()) {
        return undef;
    }

    unless ($self->_update_list_db) {
        $log->syslog('err', "Unable to update list_table");
    }

    return 1;
}

## Loads the administrative data for a list
sub load {
    $log->syslog('debug3', '(%s, %s, %s, ...)', @_);
    my $self    = shift;
    my $name    = shift;
    my $robot   = shift;
    my $options = shift;

    die 'bug in logic. Ask developer' unless $robot;

    ## Set of initializations ; only performed when the config is first loaded
    if ($options->{'first_access'}) {
        # Create parent of list directory if not exist yet e.g. when list to
        # be created manually.
        # Note: For compatibility, directory with primary domain is omitted.
        if (    $robot
            and $robot ne $Conf::Conf{'domain'}
            and not -d "$Conf::Conf{'home'}/$robot") {
            mkdir "$Conf::Conf{'home'}/$robot", 0775;
        }

        if ($robot && (-d "$Conf::Conf{'home'}/$robot")) {
            $self->{'dir'} = "$Conf::Conf{'home'}/$robot/$name";
        } elsif (lc($robot) eq lc($Conf::Conf{'domain'})) {
            $self->{'dir'} = "$Conf::Conf{'home'}/$name";
        } else {
            $log->syslog('err', 'No such robot (virtual domain) %s', $robot)
                unless ($options->{'just_try'});
            return undef;
        }

        $self->{'domain'} = $robot;

        # default list host is robot domain: Deprecated.
        #XXX$self->{'admin'}{'host'} ||= $self->{'domain'};
        $self->{'name'} = $name;
    }

    unless ((-d $self->{'dir'}) && (-f "$self->{'dir'}/config")) {
        $log->syslog('debug2', 'Missing directory (%s) or config file for %s',
            $self->{'dir'}, $name)
            unless ($options->{'just_try'});
        return undef;
    }

    # Last modification of list config ($last_time_config) on memory cache.
    # Note: "subscribers" file was deprecated. No need to load "stats" file.
    my $last_time_config = $self->{'_mtime'}{'config'};
    $last_time_config = POSIX::INT_MIN() unless defined $last_time_config;

    my $time_config = Sympa::Tools::File::get_mtime("$self->{'dir'}/config");
    my $time_config_bin =
        Sympa::Tools::File::get_mtime("$self->{'dir'}/config.bin");
    my $main_config_time =
        Sympa::Tools::File::get_mtime(Sympa::Constants::CONFIG);
    # my $web_config_time  = Sympa::Tools::File::get_mtime(Sympa::Constants::WWSCONFIG);
    my $config_reloaded = 0;
    my $admin;

    if (Conf::get_robot_conf($self->{'domain'}, 'cache_list_config') eq
            'binary_file'
        and !$options->{'reload_config'}
        and $time_config_bin > $last_time_config
        and $time_config_bin >= $time_config
        and $time_config_bin >= $main_config_time) {
        ## Get a shared lock on config file first
        my $lock_fh =
            Sympa::LockedFile->new($self->{'dir'} . '/config', 5, '<');
        unless ($lock_fh) {
            $log->syslog('err', 'Could not create new lock');
            return undef;
        }

        ## Load a binary version of the data structure
        ## unless config is more recent than config.bin
        eval { $admin = Storable::retrieve("$self->{'dir'}/config.bin") };
        if ($@) {
            $log->syslog('err',
                'Failed to load the binary config %s, error: %s',
                "$self->{'dir'}/config.bin", $@);
            $lock_fh->close();
            return undef;
        }

        $config_reloaded  = 1;
        $last_time_config = $time_config_bin;
        $lock_fh->close();
    } elsif ($self->{'name'} ne $name
        or $time_config > $last_time_config
        or $options->{'reload_config'}) {
        $admin = $self->_load_list_config_file;

        ## Get a shared lock on config file first
        my $lock_fh =
            Sympa::LockedFile->new($self->{'dir'} . '/config', 5, '+<');
        unless ($lock_fh) {
            $log->syslog('err', 'Could not create new lock');
            return undef;
        }

        ## update the binary version of the data structure
        if (Conf::get_robot_conf($self->{'domain'}, 'cache_list_config') eq
            'binary_file') {
            eval { Storable::store($admin, "$self->{'dir'}/config.bin") };
            if ($@) {
                $log->syslog('err',
                    'Failed to save the binary config %s. error: %s',
                    "$self->{'dir'}/config.bin", $@);
            }
        }

        $config_reloaded = 1;
        unless (defined $admin) {
            $log->syslog(
                'err',
                'Impossible to load list config file for list %s set in status error_config',
                $self
            );
            $self->set_status_error_config('load_admin_file_error');
            $lock_fh->close();
            return undef;
        }

        $last_time_config = $time_config;
        $lock_fh->close();
    }

    ## If config was reloaded...
    if ($admin) {
        $self->{'admin'} = $admin;

        ## check param_constraint.conf if belongs to a family and the config
        ## has been loaded
        if (    not $options->{'no_check_family'}
            and defined $admin->{'family_name'}
            and $admin->{'status'} ne 'error_config') {
            my $family;
            unless ($family = $self->get_family()) {
                $log->syslog(
                    'err',
                    'Impossible to get list %s family: %s. The list is set in status error_config',
                    $self,
                    $self->{'admin'}{'family_name'}
                );
                $self->set_status_error_config('no_list_family',
                    $self->{'admin'}{'family_name'});
                return undef;
            }
        }
    }

    $self->{'as_x509_cert'} = 1
        if ((-r "$self->{'dir'}/cert.pem")
        || (-r "$self->{'dir'}/cert.pem.enc"));

    $self->{'_mtime'}{'config'} = $last_time_config;

    $list_of_lists{$self->{'domain'}}{$name} = $self;
    return $config_reloaded;
}

## Return a list of hash's owners and their param
#OBSOLETED.  Use get_admins().
#sub get_owners;

# OBSOLETED: No longer used.
#sub get_nb_owners;

## Return a hash of list's editors and their param(empty if there isn't any
## editor)
#OBSOLETED. Use get_admins().
#sub get_editors;

## Returns an array of owners' email addresses
#OBSOLETED: Use get_admins_email('receptive_owner') or
#           get_admins_email('owner').
#sub get_owners_email;

## Returns an array of editors' email addresses
#  or owners if there isn't any editors' email addresses
#OBSOLETED: Use get_admins_email('receptive_editor') or
#           get_admins_email('actual_editor').
#sub get_editors_email;

## Returns an object Sympa::Family if the list belongs to a family or undef
sub get_family {
    my $self = shift;

    if (ref $self->{'family'} eq 'Sympa::Family') {
        return $self->{'family'};
    } elsif ($self->{'admin'}{'family_name'}) {
        return $self->{'family'} =
            Sympa::Family->new($self->{'admin'}{'family_name'},
            $self->{'domain'});
    } else {
        return undef;
    }
}

## return the config_changes hash
## Used ONLY with lists belonging to a family.
sub get_config_changes {
    my $self = shift;
    $log->syslog('debug3', '(%s)', $self->{'name'});

    unless ($self->{'admin'}{'family_name'}) {
        $log->syslog('err',
            '(%s) Is called but there is no family_name for this list',
            $self->{'name'});
        return undef;
    }

    ## load config_changes
    my $time_file =
        Sympa::Tools::File::get_mtime("$self->{'dir'}/config_changes");
    unless (defined $self->{'config_changes'}
        && ($self->{'config_changes'}{'mtime'} >= $time_file)) {
        unless ($self->{'config_changes'} =
            $self->_load_config_changes_file()) {
            $log->syslog('err',
                'Impossible to load file config_changes from list %s',
                $self->{'name'});
            return undef;
        }
    }
    return $self->{'config_changes'};
}

## update file config_changes if the list belongs to a family by
#  writing the $what(file or param) name
sub update_config_changes {
    my $self = shift;
    my $what = shift;
    # one param or a ref on array of param
    my $name = shift;
    $log->syslog('debug2', '(%s, %s)', $self->{'name'}, $what);

    unless ($self->{'admin'}{'family_name'}) {
        $log->syslog(
            'err',
            '(%s, %s, %s) Is called but there is no family_name for this list',
            $self->{'name'},
            $what
        );
        return undef;
    }
    unless (($what eq 'file') || ($what eq 'param')) {
        $log->syslog('err', '(%s, %s) %s is wrong: must be "file" or "param"',
            $self->{'name'}, $what);
        return undef;
    }

    # status parameter isn't updating set in config_changes
    if (($what eq 'param') && ($name eq 'status')) {
        return 1;
    }

    ## load config_changes
    my $time_file =
        Sympa::Tools::File::get_mtime("$self->{'dir'}/config_changes");
    unless (defined $self->{'config_changes'}
        && ($self->{'config_changes'}{'mtime'} >= $time_file)) {
        unless ($self->{'config_changes'} =
            $self->_load_config_changes_file()) {
            $log->syslog('err',
                'Impossible to load file config_changes from list %s',
                $self->{'name'});
            return undef;
        }
    }

    if (ref($name) eq 'ARRAY') {
        foreach my $n (@{$name}) {
            $self->{'config_changes'}{$what}{$n} = 1;
        }
    } else {
        $self->{'config_changes'}{$what}{$name} = 1;
    }

    $self->_save_config_changes_file();

    return 1;
}

## return a hash of config_changes file
sub _load_config_changes_file {
    my $self = shift;
    $log->syslog('debug3', '(%s)', $self->{'name'});

    my $config_changes = {};

    unless (-e "$self->{'dir'}/config_changes") {
        $log->syslog('err', 'No file %s/config_changes. Assuming no changes',
            $self->{'dir'});
        return $config_changes;
    }

    unless (open(FILE, "$self->{'dir'}/config_changes")) {
        $log->syslog('err',
            'File %s/config_changes exists, but unable to open it: %m',
            $self->{'dir'});
        return undef;
    }

    while (<FILE>) {

        next if /^\s*(\#.*|\s*)$/;

        if (/^param\s+(.+)\s*$/) {
            $config_changes->{'param'}{$1} = 1;

        } elsif (/^file\s+(.+)\s*$/) {
            $config_changes->{'file'}{$1} = 1;

        } else {
            $log->syslog('err', '(%s) Bad line: %s', $self->{'name'}, $_);
            next;
        }
    }
    close FILE;

    $config_changes->{'mtime'} =
        Sympa::Tools::File::get_mtime("$self->{'dir'}/config_changes");

    return $config_changes;
}

## save config_changes file in the list directory
sub _save_config_changes_file {
    my $self = shift;
    $log->syslog('debug3', '(%s)', $self->{'name'});

    unless ($self->{'admin'}{'family_name'}) {
        $log->syslog('err',
            '(%s) Is called but there is no family_name for this list',
            $self->{'name'});
        return undef;
    }
    unless (open FILE, '>', $self->{'dir'} . '/config_changes') {
        $log->syslog('err', 'Unable to create file %s/config_changes: %m',
            $self->{'dir'});
        return undef;
    }

    foreach my $what ('param', 'file') {
        foreach my $name (keys %{$self->{'config_changes'}{$what}}) {
            print FILE "$what $name\n";
        }
    }
    close FILE;

    return 1;
}

## Returns the list parameter value from $list->{'admin'}
#  the parameter is simple ($param) or composed ($param & $minor_param)
#  the value is a scalar or a ref on an array of scalar
# (for parameter digest : only for days)
sub get_param_value {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $self        = shift;
    my $param       = shift;
    my $as_arrayref = shift || 0;
    my $pinfo       = Sympa::Robot::list_params($self->{'domain'});
    my $minor_param;
    my $value;

    if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
        $param       = $1;
        $minor_param = $2;
    }
    # Resolve aliases.
    if ($pinfo->{$param}) {
        my $alias = $pinfo->{$param}{'obsolete'};
        if ($alias and $pinfo->{$alias}) {
            $param = $alias;
        }
    }
    if (    $minor_param
        and ref $pinfo->{$param}{'format'} eq 'HASH'
        and $pinfo->{$param}{'format'}{$minor_param}) {
        my $alias = $pinfo->{$param}{'format'}{$minor_param}{'obsolete'};
        if ($alias and $pinfo->{$param}{'format'}{$alias}) {
            $minor_param = $alias;
        }
    }

    ## Multiple parameter (owner, custom_header, ...)
    if (ref($self->{'admin'}{$param}) eq 'ARRAY'
        and !$pinfo->{$param}{'split_char'}) {
        my @values;
        foreach my $elt (@{$self->{'admin'}{$param}}) {
            my $val =
                _get_single_param_value($pinfo, $elt, $param, $minor_param);
            push @values, $val if defined $val;
        }
        $value = \@values;
    } else {
        $value = _get_single_param_value($pinfo, $self->{'admin'}{$param},
            $param, $minor_param);
        if ($as_arrayref) {
            return [$value] if defined $value;
            return [];
        }
    }
    return $value;
}

## Returns the single list parameter value from struct $p, with $key entrie,
#  $k is optionnal
#  the single value can be a ref on a list when the parameter value is a list
sub _get_single_param_value {
    my ($pinfo, $p, $key, $k) = @_;
    $log->syslog('debug3', '(%s %s)', $key, $k);

    if (   defined($pinfo->{$key}{'scenario'})
        || defined($pinfo->{$key}{'task'})) {
        return $p->{'name'};

    } elsif (ref($pinfo->{$key}{'file_format'})) {

        if (defined($pinfo->{$key}{'file_format'}{$k}{'scenario'})) {
            return $p->{$k}{'name'};

        } elsif (($pinfo->{$key}{'file_format'}{$k}{'occurrence'} =~ /n$/)
            && $pinfo->{$key}{'file_format'}{$k}{'split_char'}) {
            return $p->{$k};    # ref on an array
        } else {
            return $p->{$k};
        }

    } else {
        if (($pinfo->{$key}{'occurrence'} =~ /n$/)
            && $pinfo->{$key}{'split_char'}) {
            return $p;          # ref on an array
        } elsif ($key eq 'digest') {
            return $p->{'days'};    # ref on an array
        } else {
            return $p;
        }
    }
}

##############################################################################
#                       FUNCTIONS FOR MESSAGE SENDING
#                       #
##############################################################################
#
#  -list distribution
#  -template sending
#  #
#  -service messages
#  -notification sending(listmaster, owner, editor, user)
#  #
#                                                                 #

###   LIST DISTRIBUTION  ###

# Moved (split) to:
# Sympa::Spindle::TransformIncoming::_twist(),
# Sympa::Spindle::ToArchive::_twist(),
# Sympa::Spindle::TransformOutgoing::_twist(),
# Sympa::Spindle::ToDigest::_twist(), Sympa::Spindle::ToList::_send_msg().
#sub distribute_msg;

# Moved to: Sympa::Spindle::DecodateOutgoing::_twist().
#sub post_archive;

# Old name: Sympa::Mail::mail_message()
# Moved To: Sympa::Spindle::ToList::_mail_message().
#sub _mail_message;

# Old name: List::send_msg_digest().
# Moved to Sympa::Spindle::ProcessDigest::_distribute_digest().
#sub distribute_digest;

sub get_digest_recipients_per_mode {
    my $self = shift;

    my @tabrcpt_digest;
    my @tabrcpt_summary;
    my @tabrcpt_digestplain;

    ## Create the list of subscribers in various digest modes
    for (
        my $user = $self->get_first_list_member();
        $user;
        $user = $self->get_next_list_member()
    ) {
        # Test to know if the rcpt suspended her subscription for this list.
        # If yes, don't send the message.
        if ($user and $user->{'suspend'}) {
            if (    (not $user->{'startdate'} or $user->{'startdate'} <= time)
                and (not $user->{'enddate'} or time <= $user->{'enddate'})) {
                next;
            } elsif ($user->{'enddate'} and $user->{'enddate'} < time) {
                # If end date is < time, update subscriber by deleting the
                # suspension setting.
                $self->restore_suspended_subscription($user->{'email'});
            }
        }
        if ($user->{'reception'} eq "digest") {
            push @tabrcpt_digest, $user->{'email'};

        } elsif ($user->{'reception'} eq "summary") {
            ## Create the list of subscribers in summary mode
            push @tabrcpt_summary, $user->{'email'};

        } elsif ($user->{'reception'} eq "digestplain") {
            push @tabrcpt_digestplain, $user->{'email'};
        }
    }

    return 0
        unless @tabrcpt_summary
        or @tabrcpt_digest
        or @tabrcpt_digestplain;

    my $available_recipients;
    $available_recipients->{'summary'} = \@tabrcpt_summary
        if @tabrcpt_summary;
    $available_recipients->{'digest'} = \@tabrcpt_digest if @tabrcpt_digest;
    $available_recipients->{'digestplain'} = \@tabrcpt_digestplain
        if @tabrcpt_digestplain;

    return $available_recipients;
}

###   TEMPLATE SENDING  ###

# MOVED to Sympa::send_dsn().
#sub send_dsn;

#MOVED: Use Sympa::send_file() or Sympa::List::send_probe_to_user().
# sub send_file($self, $tpl, $who, $robot, $context);

#DEPRECATED: Merged to List::distribute_msg(), then moved to
# Sympa::Spindle::ToList::_send_msg().
# sub send_msg($message);

sub get_recipients_per_mode {
    my $self    = shift;
    my $message = shift;
    my %options = @_;

    my $robot = $self->{'domain'};

    my (@tabrcpt_mail,        @tabrcpt_mail_verp,
        @tabrcpt_notice,      @tabrcpt_notice_verp,
        @tabrcpt_txt,         @tabrcpt_txt_verp,
        @tabrcpt_urlize,      @tabrcpt_urlize_verp,
        @tabrcpt_digestplain, @tabrcpt_digestplain_verp,
        @tabrcpt_digest,      @tabrcpt_digest_verp,
        @tabrcpt_summary,     @tabrcpt_summary_verp,
        @tabrcpt_nomail,      @tabrcpt_nomail_verp,
    );

    for (
        my $user = $self->get_first_list_member();
        $user;
        $user = $self->get_next_list_member()
    ) {
        unless ($user->{'email'}) {
            $log->syslog('err',
                'Skipping user with no email address in list %s', $self);
            next;
        }
        # Test to know if the rcpt suspended her subscription for this list.
        # if yes, don't send the message.
        if ($user and $user->{'suspend'}) {
            if (    (not $user->{'startdate'} or $user->{'startdate'} <= time)
                and (not $user->{'enddate'} or time <= $user->{'enddate'})) {
                push @tabrcpt_nomail_verp, $user->{'email'};
                next;
            } elsif ($user->{'enddate'} and $user->{'enddate'} < time) {
                # If end date is < time, update subscriber by deleting the
                # suspension setting.
                $self->restore_suspended_subscription($user->{'email'});
            }
        }

        # Check if "not_me" reception mode is set.
        next
            if $user->{'reception'} eq 'not_me'
            and $message->{sender} eq $user->{'email'};

        # Recipients who won't receive encrypted messages.
        # The digest, digestplain, nomail and summary reception option are
        # initialized for tracking feature only.
        if ($user->{'reception'} eq 'digestplain') {
            push @tabrcpt_digestplain_verp, $user->{'email'};
            next;
        } elsif ($user->{'reception'} eq 'digest') {
            push @tabrcpt_digest_verp, $user->{'email'};
            next;
        } elsif ($user->{'reception'} eq 'summary') {
            push @tabrcpt_summary_verp, $user->{'email'};
            next;
        } elsif ($user->{'reception'} eq 'nomail') {
            push @tabrcpt_nomail_verp, $user->{'email'};
            next;
        } elsif ($user->{'reception'} eq 'notice') {
            if ($user->{'bounce_address'}) {
                push @tabrcpt_notice_verp, $user->{'email'};
            } else {
                push @tabrcpt_notice, $user->{'email'};
            }
            next;
        }

        #XXX Following will be done by ProcessOutgoing spindle.
        # # Message should be re-encrypted, however, user certificate is
        # # missing.
        # if ($message->{'smime_crypted'}
        #     and not -r $Conf::Conf{'ssl_cert_dir'} . '/'
        #     . Sympa::Tools::Text::escape_chars($user->{'email'})
        #     and not -r $Conf::Conf{'ssl_cert_dir'} . '/'
        #     . Sympa::Tools::Text::escape_chars($user->{'email'} . '@enc')) {
        #     my $subject = $message->{'decoded_subject'};
        #     my $sender  = $message->{'sender'};
        #     unless (
        #         Sympa::send_file(
        #             $self,
        #             'x509-user-cert-missing',
        #             $user->{'email'},
        #             {   'mail' =>
        #                     {'subject' => $subject, 'sender' => $sender},
        #                 'auto_submitted' => 'auto-generated'
        #             }
        #         )
        #         ) {
        #         $log->syslog(
        #             'notice',
        #             'Unable to send template "x509-user-cert-missing" to %s',
        #             $user->{'email'}
        #         );
        #     }
        #     next;
        # }
        # # Otherwise it may be shelved encryption.

        if ($user->{'reception'} eq 'txt') {
            if ($user->{'bounce_address'}) {
                push @tabrcpt_txt_verp, $user->{'email'};
            } else {
                push @tabrcpt_txt, $user->{'email'};
            }
        } elsif ($user->{'reception'} eq 'urlize') {
            if ($user->{'bounce_address'}) {
                push @tabrcpt_urlize_verp, $user->{'email'};
            } else {
                push @tabrcpt_urlize, $user->{'email'};
            }
        } else {
            if ($user->{'bounce_score'}) {
                push @tabrcpt_mail_verp, $user->{'email'};
            } else {
                push @tabrcpt_mail, $user->{'email'};
            }
        }
    }

    return 0
        unless @tabrcpt_mail
        or @tabrcpt_notice
        or @tabrcpt_txt
        or @tabrcpt_urlize
        or @tabrcpt_mail_verp
        or @tabrcpt_notice_verp
        or @tabrcpt_txt_verp
        or @tabrcpt_urlize_verp;

    my $available_recipients;

    $available_recipients->{'mail'}{'noverp'} = \@tabrcpt_mail
        if @tabrcpt_mail;
    $available_recipients->{'mail'}{'verp'} = \@tabrcpt_mail_verp
        if @tabrcpt_mail_verp;
    $available_recipients->{'notice'}{'noverp'} = \@tabrcpt_notice
        if @tabrcpt_notice;
    $available_recipients->{'notice'}{'verp'} = \@tabrcpt_notice_verp
        if @tabrcpt_notice_verp;
    $available_recipients->{'txt'}{'noverp'} = \@tabrcpt_txt if @tabrcpt_txt;
    $available_recipients->{'txt'}{'verp'} = \@tabrcpt_txt_verp
        if @tabrcpt_txt_verp;
    $available_recipients->{'urlize'}{'noverp'} = \@tabrcpt_urlize
        if @tabrcpt_urlize;
    $available_recipients->{'urlize'}{'verp'} = \@tabrcpt_urlize_verp
        if @tabrcpt_urlize_verp;
    $available_recipients->{'digestplain'}{'noverp'} = \@tabrcpt_digestplain
        if @tabrcpt_digestplain;
    $available_recipients->{'digestplain'}{'verp'} =
        \@tabrcpt_digestplain_verp
        if @tabrcpt_digestplain_verp;
    $available_recipients->{'digest'}{'noverp'} = \@tabrcpt_digest
        if @tabrcpt_digest;
    $available_recipients->{'digest'}{'verp'} = \@tabrcpt_digest_verp
        if @tabrcpt_digest_verp;
    $available_recipients->{'summary'}{'noverp'} = \@tabrcpt_summary
        if @tabrcpt_summary;
    $available_recipients->{'summary'}{'verp'} = \@tabrcpt_summary_verp
        if @tabrcpt_summary_verp;
    $available_recipients->{'nomail'}{'noverp'} = \@tabrcpt_nomail
        if @tabrcpt_nomail;
    $available_recipients->{'nomail'}{'verp'} = \@tabrcpt_nomail_verp
        if @tabrcpt_nomail_verp;

    return $available_recipients;
}

###   SERVICE MESSAGES   ###

# Old name: List::send_to_editor().
# Moved to: Sympa::Spindle::ToEditor & Sympa::Spindle::ToModeration.
#sub send_confirm_to_editor;

# Old name: List::send_auth().
# Moved to Sympa::Spindle::ToHeld::_send_confirm_to_sender().
#sub send_confirm_to_sender;

#MOVED: Use Sympa::request_auth().
#sub request_auth;

# Merged into Sympa::Commands::getfile().
#sub archive_send;

# Merged into Sympa::Commands::last().
#sub archive_send_last;

###   NOTIFICATION SENDING  ###

####################################################
# send_notify_to_owner
####################################################
# Sends a notice to list owner(s) by parsing
# listowner_notification.tt2 template
#
# IN : -$self (+): ref(List)
#      -$operation (+): notification type
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#
######################################################
sub send_notify_to_owner {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self      = shift;
    my $operation = shift;
    my $param     = shift;

    die 'bug in logic. Ask developer' unless defined $operation;

    my @rcpt = $self->get_admins_email('receptive_owner');
    @rcpt = $self->get_admins_email('owner') unless @rcpt;
    unless (@rcpt) {
        $log->syslog(
            'notice',
            'No owner defined at all in list %s; notification is sent to listmasters',
            $self
        );
        @rcpt = Sympa::get_listmasters_email($self);
    }

    if (ref $param eq 'HASH') {
        $param->{'auto_submitted'} = 'auto-generated';
        $param->{'to'}             = join(',', @rcpt);
        $param->{'type'}           = $operation;

        if ($operation eq 'sigrequest' or $operation eq 'subrequest') {
            # Sends notifications by each so that auth links with owners'
            # addresses will be included.
            foreach my $owner (@rcpt) {
                unless (
                    Sympa::send_file(
                        $self, 'listowner_notification', $owner, $param
                    )
                ) {
                    $log->syslog(
                        'notice',
                        'Unable to send template "listowner_notification" to %s list owner %s',
                        $self,
                        $owner
                    );
                }
            }
        } else {
            if ($operation eq 'bounce_rate') {
                $param->{'rate'} = int($param->{'rate'} * 10) / 10;
            }
            unless (
                Sympa::send_file(
                    $self, 'listowner_notification', [@rcpt], $param
                )
            ) {
                $log->syslog(
                    'notice',
                    'Unable to send template "listowner_notification" to %s list owner',
                    $self
                );
                return undef;
            }
        }
    } elsif (ref $param eq 'ARRAY') {

        my $data = {
            'to'   => join(',', @rcpt),
            'type' => $operation
        };

        for my $i (0 .. $#{$param}) {
            $data->{"param$i"} = $param->[$i];
        }
        unless (
            Sympa::send_file($self, 'listowner_notification', \@rcpt, $data))
        {
            $log->syslog(
                'notice',
                'Unable to send template "listowner_notification" to %s list owner',
                $self
            );
            return undef;
        }

    } else {
        $log->syslog(
            'err',
            '(%s, %s) Error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY',
            $self,
            $operation
        );
        return undef;
    }
    return 1;
}

# FIXME:This might be moved to Sympa::WWW namespace.
sub get_picture_path {
    my $self = shift;
    return join '/', $Conf::Conf{'pictures_path'}, $self->get_id, @_;
}

# No longer used.  Use Sympa::List::find_picture_url().
#sub get_picture_url;

# Old name: tools::pictures_filename()
# FIXME:This might be moved to Sympa::WWW namespace.
sub find_picture_filenames {
    my $self  = shift;
    my $email = shift;

    my @ret = ();
    if ($email) {
        my $login = Digest::MD5::md5_hex($email);
        foreach my $ext (qw{gif jpg jpeg png}) {
            if (-f $self->get_picture_path($login . '.' . $ext)) {
                push @ret, $login . '.' . $ext;
            }
        }
    }
    return @ret;
}

# FIXME:This might be moved to Sympa::WWW namespace.
sub find_picture_paths {
    my $self  = shift;
    my $email = shift;

    return
        map { $self->get_picture_path($_) }
        $self->find_picture_filenames($email);
}

# Old name: tools::make_pictures_url().
# FIXME:This might be moved to Sympa::WWW namespace.
sub find_picture_url {
    my $self  = shift;
    my $email = shift;

    my ($filename) = $self->find_picture_filenames($email);
    return undef unless $filename;

    return Sympa::Tools::Text::weburl($Conf::Conf{'pictures_url'},
        [$self->get_id, $filename]);
}

# FIXME:This might be moved to Sympa::WWW namespace.
sub delete_list_member_picture {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self  = shift;
    my $email = shift;

    my $ret = 1;
    foreach my $path ($self->find_picture_paths($email)) {
        unless (unlink $path) {
            $log->syslog('err', 'Failed to delete %s', $path);
            $ret = undef;
        } else {
            $log->syslog('debug3', 'File deleted successfully: %s', $path);
        }
    }

    return $ret;
}

#No longer used.
#sub send_notify_to_editor;

# Moved to Sympa::send_notify_to_user().
#sub send_notify_to_user;

sub send_probe_to_user {
    my $self = shift;
    my $type = shift;
    my $who  = shift;

    # Shelve VERP for welcome or remind message if necessary
    my $tracking;
    if (    $self->{'admin'}{'welcome_return_path'} eq 'unique'
        and $type eq 'welcome') {
        $tracking = 'w';
    } elsif ($self->{'admin'}{'remind_return_path'} eq 'unique'
        and $type eq 'remind') {
        $tracking = 'r';
    } else {
        #FIXME? Return-Path for '*_return_path' parameter with 'owner'
        # value is LIST-owner address.  It might be LIST-request address.
    }

    my $spindle = Sympa::Spindle::ProcessTemplate->new(
        context  => $self,
        template => $type,
        rcpt     => $who,
        data     => {},
        tracking => $tracking,
        #FIXME: Why overwrite priority?
        priority => Conf::get_robot_conf($self->{'domain'}, 'sympa_priority'),
    );
    unless ($spindle and $spindle->spin and $spindle->{finish} eq 'success') {
        $log->syslog('err', 'Could not send template %s to %s', $type, $who);
        return undef;
    }

    return 1;
}

### END functions for sending messages ###

#MOVED: Use Sympa::compute_auth().
#sub compute_auth;

# DEPRECATED: Moved to Sympa::Message::_decorate_parts().
#sub add_parts;

## Delete a user in the user_table
##sub delete_global_user
## DEPRECATED: Use Sympa::User::delete_global_user() or $user->expire();

## Delete the indicate list member
## IN : - ref to array
##      - option exclude
##
## $list->delete_list_member('users' => \@u, 'exclude' => 1)
## $list->delete_list_member('users' => [$email], 'exclude' => 1)
sub delete_list_member {
    my $self    = shift;
    my %param   = @_;
    my @u       = @{$param{'users'}};
    my $exclude = $param{'exclude'};

    # Case of deleting: "auto_del" (bounce management), "signoff" (manual
    # signoff) or "del" (deleted by admin)?
    my $operation = $param{'operation'};

    $log->syslog('debug2', '');

    my $name  = $self->{'name'};
    my $total = 0;

    my $sdm = Sympa::DatabaseManager->instance;

    foreach my $who (@u) {
        $who = Sympa::Tools::Text::canonic_email($who);

        ## Include in exclusion_table only if option is set.
        if ($exclude) {
            # Insert in exclusion_table if $user->{inclusion} defined.
            $self->insert_delete_exclusion($who, 'insert');
        }

        # Delete record in subscriber_table.
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{DELETE FROM subscriber_table
                  WHERE user_subscriber = ? AND
                        list_subscriber = ? AND robot_subscriber = ?},
                $who, $name, $self->{'domain'}
            )
        ) {
            $log->syslog('err', 'Unable to remove list member %s', $who);
            next;
        }

        # Delete signoff requests if any.
        my $spool_req = Sympa::Spool::Auth->new(
            context => $self,
            action  => 'del',
            email   => $who,
        );
        while (1) {
            my ($request, $handle) = $spool_req->next;
            last unless $handle;
            next unless $request;

            $spool_req->remove($handle);
        }

        #log in stat_table to make statistics
        if ($operation) {
            $log->add_stat(
                'robot'     => $self->{'domain'},
                'list'      => $name,
                'operation' => $operation,
                'mail'      => $who
            );
        }

        $total--;
    }

    $self->_cache_publish_expiry('member');
    delete_list_member_picture($self, shift(@u));
    return (-1 * $total);

}

## Delete the indicated admin users from the list.
sub delete_list_admin {
    my ($self, $role, @u) = @_;
    $log->syslog('debug2', '', $role);

    my $name  = $self->{'name'};
    my $total = 0;

    foreach my $who (@u) {
        $who = Sympa::Tools::Text::canonic_email($who);
        my $statement;

        my $sdm = Sympa::DatabaseManager->instance;

        # Delete record in ADMIN
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{DELETE FROM admin_table
                  WHERE user_admin = ? AND list_admin = ? AND
                        robot_admin = ? AND role_admin = ?},
                $who,              $self->{'name'},
                $self->{'domain'}, $role
            )
        ) {
            $log->syslog('err', 'Unable to remove admin %s of list %s',
                $who, $self);
            next;
        }

        $total--;
    }

    $self->_cache_publish_expiry('admin_user');

    return (-1 * $total);
}

# Delete all admin_table entries.
# OBSOLETED: No longer used.
#sub delete_all_list_admin;

# OBSOLETED: This may no longer be used.
# Returns the cookie for a list, if any.
sub get_cookie {
    return shift->{'admin'}{'cookie'};
}

# OBSOLETED: No longer used.
# Returns the maximum size allowed for a message to the list.
sub get_max_size {
    return shift->{'admin'}{'max_size'};
}

## Returns an array with the Reply-To data
sub get_reply_to {
    my $admin = shift->{'admin'};

    my $value = $admin->{'reply_to_header'}{'value'};

    $value = $admin->{'reply_to_header'}{'other_email'}
        if ($value eq 'other_email');

    return $value;
}

## Returns a default user option
sub get_default_user_options {
    $log->syslog('debug3', '(%s,%s)', @_);
    my $self = shift;
    my $what = shift;

    if ($self) {
        return $self->{'admin'}{'default_user_options'};
    }
    return undef;
}

# Returns the number of subscribers of a list.
sub get_total {
    my $self   = shift;
    my $option = shift;

    my $total = $self->_cache_get('total');
    if (defined $total and not($option and $option eq 'nocache')) {
        return $total;
    }

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT COUNT(*)
              FROM subscriber_table
              WHERE list_subscriber = ? AND robot_subscriber = ?},
            $self->{'name'}, $self->{'domain'}
        )
    ) {
        $log->syslog('err', 'Unable to get subscriber count for list %s',
            $self);
        return $total;    # Return cache probably outdated.
    }
    $total = $self->_cache_put('total', $sth->fetchrow);
    $sth->finish;

    return $total;
}

## Returns a hash for a given user
##sub get_global_user {
## DEPRECATED: Use Sympa::User::get_global_user() or Sympa::User->new().

## Returns an array of all users in User table hash for a given user
##sub get_all_global_user {
## DEPRECATED: Use Sympa::User::get_all_global_user() or
## Sympa::User::get_users().

######################################################################
###  suspend_subscription                                            #
## Suspend an user from list(s)                                      #
######################################################################
# IN:                                                                #
#   - email : the subscriber email                                   #
#   - list : the name of the list                                    #
#   - data : start_date and end_date                                 #
#   - robot : domain                                                 #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - 1 if user is suspended from the list                           #
######################################################################
sub suspend_subscription {

    my $email = shift;
    my $list  = shift;
    my $data  = shift;
    my $robot = shift;
    $log->syslog('debug2', '("%s", "%s", "%s")', $email, $list, $data);

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE subscriber_table
              SET suspend_subscriber = 1,
                  suspend_start_date_subscriber = ?,
                  suspend_end_date_subscriber = ?
              WHERE user_subscriber = ? AND
                    list_subscriber = ? AND robot_subscriber = ?},
            $data->{'startdate'}, $data->{'enddate'},
            $email, $list, $robot
        )
    ) {
        $log->syslog('err',
            'Unable to suspend subscription of user %s to list %s@%s',
            $email, $list, $robot);
        return undef;
    }

    return 1;
}

######################################################################
###  restore_suspended_subscription                                  #
## Restore the subscription of an user from list(s)                  #
######################################################################
# IN:                                                                #
#   - email : the subscriber email                                   #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - 1 if their subscription is restored                          #
######################################################################
sub restore_suspended_subscription {
    $log->syslog('debug2', '(%s)', @_);
    my $self  = shift;
    my $email = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE subscriber_table
              SET suspend_subscriber = 0,
                  suspend_start_date_subscriber  = NULL,
                  suspend_end_date_subscriber = NULL
              WHERE user_subscriber = ? AND list_subscriber = ? AND
                    robot_subscriber = ?},
            $email, $self->{'name'}, $self->{'domain'}
        )
    ) {
        $log->syslog('err',
            'Unable to restore subscription of user %s to list %s',
            $email, $self);
        return undef;
    }

    return 1;
}

######################################################################
# insert_delete_exclusion                                            #
# Update the exclusion_table                                         #
######################################################################
# IN:                                                                #
#   - email : the subscriber email                                   #
#   - action : insert or delete                                      #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - 1                                                              #
######################################################################
sub insert_delete_exclusion {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self   = shift;
    my $email  = shift;
    my $action = shift;

    die sprintf 'Invalid parameter: %s', $self
        unless ref $self;    #prototype changed (6.2b)

    my $name     = $self->{'name'};
    my $robot_id = $self->{'domain'};
    my $sdm      = Sympa::DatabaseManager->instance;

    my $r = 1;

    if ($action eq 'insert') {
        # INSERT only if $user->{inclusion} defined.
        my $user = $self->get_list_member($email);
        my $date = time;

        if (defined $user->{'inclusion'}) {
            unless (
                $sdm
                and $sdm->do_prepared_query(
                    q{INSERT INTO exclusion_table
                      (list_exclusion, family_exclusion, robot_exclusion,
                       user_exclusion, date_exclusion)
                      VALUES (?, ?, ?, ?, ?)},
                    $name, '', $robot_id, $email, $date
                )
            ) {
                $log->syslog('err', 'Unable to exclude user %s from list %s',
                    $email, $self);
                return undef;
            }
        }
    } elsif ($action eq 'delete') {
        ## If $email is in exclusion_table, delete it.
        my $data_excluded = $self->get_exclusion();
        my @users_excluded;

        my $key = 0;
        while ($data_excluded->{'emails'}->[$key]) {
            push @users_excluded, $data_excluded->{'emails'}->[$key];
            $key = $key + 1;
        }

        $r = 0;
        my $sth;
        foreach my $users (@users_excluded) {
            if ($email eq $users) {
                ## Delete : list, user and date
                unless (
                    $sdm
                    and $sth = $sdm->do_prepared_query(
                        q{DELETE FROM exclusion_table
                          WHERE list_exclusion = ? AND robot_exclusion = ? AND
                                user_exclusion = ?},
                        $name, $robot_id, $email
                    )
                ) {
                    $log->syslog(
                        'err',
                        'Unable to remove entry %s for list %s from table exclusion_table',
                        $email,
                        $self
                    );
                }
                $r = $sth->rows;
            }
        }
    } else {
        $log->syslog('err', 'Unknown action %s', $action);
        return undef;
    }

    return $r;
}

######################################################################
# get_exclusion                                                      #
# Returns a hash with those excluded from the list and the date.     #
#                                                                    #
# IN:  - name : the name of the list                                 #
# OUT: - data_exclu : * %data_exclu->{'emails'}->[]                  #
#                     * %data_exclu->{'date'}->[]                    #
######################################################################
sub get_exclusion {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    die sprintf 'Invalid parameter: %s', $self
        unless ref $self;    #prototype changed (6.2b)

    my $name     = $self->{'name'};
    my $robot_id = $self->{'domain'};

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    if (defined $self->{'admin'}{'family_name'}
        and length $self->{'admin'}{'family_name'}) {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT user_exclusion AS email, date_exclusion AS "date"
                  FROM exclusion_table
                  WHERE (list_exclusion = ? OR family_exclusion = ?) AND
                         robot_exclusion = ?},
                $name, $self->{'admin'}{'family_name'}, $robot_id
            )
        ) {
            $log->syslog('err',
                'Unable to retrieve excluded users for list %s', $self);
            $sth = pop @sth_stack;
            return undef;
        }
    } else {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT user_exclusion AS email, date_exclusion AS "date"
                  FROM exclusion_table
                  WHERE list_exclusion = ? AND robot_exclusion = ?},
                $name, $robot_id
            )
        ) {
            $log->syslog('err',
                'Unable to retrieve excluded users for list %s', $self);
            $sth = pop @sth_stack;
            return undef;
        }
    }

    my @users;
    my @date;
    my $data;
    while ($data = $sth->fetchrow_hashref) {
        push @users, $data->{'email'};
        push @date,  $data->{'date'};
    }
    # In order to use the data, we add the emails and dates in different
    # array
    my $data_exclu = {
        "emails" => \@users,
        "date"   => \@date
    };
    $sth->finish();

    $sth = pop @sth_stack;

    unless ($data_exclu) {
        $log->syslog('err',
            'Unable to retrieve information from database for list %s',
            $self);
        return undef;
    }
    return $data_exclu;
}

sub is_member_excluded {
    my $self  = shift;
    my $email = shift;

    return undef unless defined $email and length $email;
    $email = Sympa::Tools::Text::canonic_email($email);

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    if (defined $self->{'admin'}{'family_name'}
        and length $self->{'admin'}{'family_name'}) {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT COUNT(*)
                  FROM exclusion_table
                  WHERE (list_exclusion = ? OR family_exclusion = ?) AND
                        robot_exclusion = ? AND
                        user_exclusion = ?},
                $self->{'name'}, $self->{'admin'}{'family_name'},
                $self->{'domain'},
                $email
            )
        ) {
            #FIXME: report error
            return undef;
        }
    } else {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT COUNT(*)
                  FROM exclusion_table
                  WHERE list_exclusion = ? AND robot_exclusion = ? AND
                        user_exclusion = ?},
                $self->{'name'}, $self->{'domain'},
                $email
            )
        ) {
            #FIXME: report error
            return undef;
        }
    }
    my ($count) = $sth->fetchrow_array;
    $sth->finish;

    return $count || 0;
}

# Mapping between var and field names.
sub _map_list_member_cols {
    my %map_field = (
        date        => 'date_epoch_subscriber',
        update_date => 'update_epoch_subscriber',
        gecos       => 'comment_subscriber',
        email       => 'user_subscriber',
        startdate   => 'suspend_start_date_subscriber',
        enddate     => 'suspend_end_date_subscriber',
    );

    my $fields =
        {Sympa::DatabaseDescription::full_db_struct()}->{'subscriber_table'}
        ->{fields};
    foreach my $f (keys %$fields) {
        next if $f eq 'list_subscriber' or $f eq 'robot_subscriber';

        my $k = {reverse %map_field}->{$f};
        unless ($k) {
            $k = $f;
            $k =~ s/_subscriber\z//;
            $map_field{$k} = $f;
        }
    }
    # Additional DB fields.
    if ($Conf::Conf{'db_additional_subscriber_fields'}) {
        foreach my $f (split /\s*,\s*/,
            $Conf::Conf{'db_additional_subscriber_fields'}) {
            $map_field{$f} = $f;
        }
    }

    return %map_field;
}

sub _list_member_cols {
    my $sdm = shift;

    my %map_field = _map_list_member_cols();
    return join ', ', map {
        my $col = $map_field{$_};
        ($col eq $_) ? $col : sprintf('%s AS "%s"', $col, $_);
    } sort keys %map_field;
}

sub get_list_member {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self  = shift;
    my $email = Sympa::Tools::Text::canonic_email(shift);

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            sprintf(
                q{SELECT %s
                  FROM subscriber_table
                  WHERE user_subscriber = ? AND
                        list_subscriber = ? AND robot_subscriber = ?},
                _list_member_cols($sdm)
            ),
            $email,
            $self->{'name'},
            $self->{'domain'}
        )
    ) {
        $log->syslog('err', 'Unable to gather information for user: %s',
            $email, $self);
        return undef;
    }
    my $user = $sth->fetchrow_hashref('NAME_lc');
    if (defined $user) {
        $sth->finish;

        $user->{'reception'} ||= 'mail';
        $user->{'reception'} =
            $self->{'admin'}{'default_user_options'}{'reception'}
            unless $self->is_available_reception_mode($user->{'reception'});
        $user->{'visibility'}  ||= 'noconceal';
        $user->{'update_date'} ||= $user->{'date'};

        $log->syslog(
            'debug2',
            'Custom_attribute = (%s)',
            $user->{custom_attribute}
        );
        if (defined $user->{custom_attribute}) {
            $user->{'custom_attribute'} =
                Sympa::Tools::Data::decode_custom_attribute(
                $user->{'custom_attribute'});
        }

        # Compat.<=6.2.44 FIXME: needed?
        $user->{'included'} = 1
            if defined $user->{'inclusion'};
    } else {
        my $error = $sth->err;
        $sth->finish;

        if ($error) {
            $log->syslog(
                'err',
                'An error occurred while fetching the data from the database: %s',
                $sth->errstr
            );
            return undef;
        } else {
            $log->syslog('debug',
                'User %s was not found in the subscribers of list %s',
                $email, $self);
            return undef;
        }
    }

    return $user;
}

# Deprecated. Merged into get_list_member(),
#sub get_list_member_no_object;

## Returns an admin user of the list.
# OBSOLETED.  Use get_admins().
sub get_list_admin {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self  = shift;
    my $role  = shift;
    my $email = shift;

    my ($admin_user) =
        @{$self->get_admins($role, filter => [email => $email])};

    return $admin_user;
}

## Returns the first user for the list.

sub get_first_list_member {
    my ($self, $data) = @_;

    my ($sortby, $offset, $sql_regexp);
    $sortby = $data->{'sortby'};
    ## Sort may be domain, email, date
    $sortby ||= 'email';
    $offset     = $data->{'offset'};
    $sql_regexp = $data->{'sql_regexp'};

    $log->syslog('debug2', '(%s, %s, %s)', $self, $sortby, $offset);

    my $statement;

    my $sdm = Sympa::DatabaseManager->instance;
    push @sth_stack, $sth;

    ## SQL regexp
    my $selection;
    if ($sql_regexp) {
        $selection =
            sprintf
            " AND (user_subscriber LIKE %s OR comment_subscriber LIKE %s)",
            $sdm->quote($sql_regexp), $sdm->quote($sql_regexp);
    }

    $statement = sprintf q{SELECT %s
          FROM subscriber_table
          WHERE list_subscriber = %s AND robot_subscriber = %s %s},
        _list_member_cols($sdm),
        $sdm->quote($self->{'name'}),
        $sdm->quote($self->{'domain'}),
        ($selection || '');

    ## SORT BY
    $statement .= ' ORDER BY '
        . (
        {   email => 'user_subscriber',
            date  => 'date_epoch_subscriber DESC',
            sources =>
                'subscribed_subscriber DESC, inclusion_label_subscriber ASC',
            name => 'comment_subscriber',
        }->{$sortby}
            || 'user_subscriber'
        );
    push @sth_stack, $sth;

    unless ($sdm and $sth = $sdm->do_query($statement)) {
        $log->syslog('err', 'Unable to get members of list %s', $self);
        return undef;
    }

    # Offset
    # Note: Several RDBMSs don't support nonstandard OFFSET clause, OTOH
    # some others don't support standard ROW_NUMBER function.
    # Instead, fetch unneccessary rows and discard them.
    if (defined $offset) {
        my $remainder = $offset;
        while (1000 < $remainder) {
            $remainder -= 1000;
            my $rows = $sth->fetchall_arrayref([qw(email)], 1000);
            last unless $rows and @$rows;
        }
        if (0 < $remainder) {
            $sth->fetchall_arrayref([qw(email)], $remainder);
        }
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');
    if (defined $user) {
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s', $self)
            unless $user->{'email'};
        $user->{'reception'} ||= 'mail';
        $user->{'reception'} =
            $self->{'admin'}{'default_user_options'}{'reception'}
            unless $self->is_available_reception_mode($user->{'reception'});
        $user->{'visibility'}  ||= 'noconceal';
        $user->{'update_date'} ||= $user->{'date'};

        if (defined $user->{custom_attribute}) {
            $user->{'custom_attribute'} =
                Sympa::Tools::Data::decode_custom_attribute(
                $user->{'custom_attribute'});
        }

        # Compat.<=6.2.44 FIXME: needed?
        $user->{'included'} = 1
            if defined $user->{'inclusion'};
    } else {
        $sth->finish;
        $sth = pop @sth_stack;
    }

    return $user;
}

# Moved to Sympa::Tools::Data::decode_custom_attribute().
#sub parseCustomAttribute;

# Moved to Sympa::Tools::Data::encode_custom_attribute().
#sub createXMLCustomAttribute;

## Returns the first admin_user with $role for the list.
#DEPRECATED: Merged into _get_basic_admins().  Use get_admins() instead.
#sub get_first_list_admin;

## Loop for all subsequent users.
sub get_next_list_member {
    my $self = shift;
    $log->syslog('debug2', '');

    unless (defined $sth) {
        $log->syslog('err',
            'No handle defined, get_first_list_member(%s) was not run',
            $self);
        return undef;
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');

    if (defined $user) {
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s', $self)
            unless $user->{'email'};
        $user->{'reception'} ||= 'mail';
        $user->{'reception'} =
            $self->{'admin'}{'default_user_options'}{'reception'}
            unless $self->is_available_reception_mode($user->{'reception'});
        $user->{'visibility'}  ||= 'noconceal';
        $user->{'update_date'} ||= $user->{'date'};

        if (defined $user->{custom_attribute}) {
            my $custom_attr = Sympa::Tools::Data::decode_custom_attribute(
                $user->{'custom_attribute'});
            unless (defined $custom_attr) {
                $log->syslog(
                    'err',
                    "Failed to parse custom attributes for user %s, list %s",
                    $user->{'email'},
                    $self
                );
            }
            $user->{'custom_attribute'} = $custom_attr;
        }

        # Compat.<=6.2.44 FIXME: needed?
        $user->{'included'} = 1
            if defined $user->{'inclusion'};
    } else {
        $sth->finish;
        $sth = pop @sth_stack;
    }

    return $user;
}

# Mapping between var and field names.
sub _map_list_admin_cols {
    my %map_field = (
        date        => 'date_epoch_admin',
        update_date => 'update_epoch_admin',
        gecos       => 'comment_admin',
        email       => 'user_admin',
    );

    my $fields =
        {Sympa::DatabaseDescription::full_db_struct()}->{'admin_table'}
        ->{fields};
    foreach my $f (keys %$fields) {
        next
            if $f eq 'list_admin'
            or $f eq 'robot_admin'
            or $f eq 'role_admin';

        my $k = {reverse %map_field}->{$f};
        unless ($k) {
            $k = $f;
            $k =~ s/_admin\z//;
            $map_field{$k} = $f;
        }
    }

    return %map_field;
}

sub _list_admin_cols {
    my $sdm = shift;

    my %map_field = _map_list_admin_cols();
    return join ', ', map {
        my $col = $map_field{$_};
        ($col eq $_) ? $col : sprintf('%s AS "%s"', $col, $_);
    } sort keys %map_field;
}

## Loop for all subsequent admin users with the role defined in
## get_first_list_admin.
#DEPRECATED: Merged into _get_basic_admins().  Use get_admins() instead.
#sub get_next_list_admin;

sub get_admins {
    $log->syslog('debug2', '(%s, %s, %s => %s)', @_);
    my $self    = shift;
    my $role    = lc(shift || '');
    my %options = @_;

    my $admin_user = $self->_cache_get('admin_user');
    unless ($admin_user and @{$admin_user || []}) {
        # Get recent admins from database.
        $admin_user = $self->get_current_admins;
        if ($admin_user) {
            $self->_cache_put('admin_user', $admin_user);
        } else {
            # If failed, reuse cache probably outdated.
            $admin_user = $self->{_cached}{admin_user};
        }
    }
    return unless $admin_user;    # Returns void.

    my %query = @{$options{filter} || []};
    $query{email} = Sympa::Tools::Text::canonic_email($query{email})
        if defined $query{email};

    my @users;
    if ($role eq 'editor') {
        @users =
            grep { $_ and $_->{role} eq 'editor' } @{$admin_user || []};
    } elsif ($role eq 'owner') {
        @users =
            grep { $_ and $_->{role} eq 'owner' } @{$admin_user || []};
    } elsif ($role eq 'actual_editor') {
        @users =
            grep { $_ and $_->{role} eq 'editor' } @{$admin_user || []};
        @users = grep { $_ and $_->{role} eq 'owner' } @{$admin_user || []}
            unless @users;
    } elsif ($role eq 'privileged_owner') {
        @users = grep {
                    $_
                and $_->{role} eq 'owner'
                and $_->{profile}
                and $_->{profile} eq 'privileged'
        } @{$admin_user || []};
    } elsif ($role eq 'receptive_editor') {
        @users = grep {
                    $_
                and $_->{role} eq 'editor'
                and ($_->{reception} || 'mail') ne 'nomail'
        } @{$admin_user || []};
        @users = grep {
                    $_
                and $_->{role} eq 'owner'
                and ($_->{reception} || 'mail') ne 'nomail'
        } @{$admin_user || []}
            unless @users;
    } elsif ($role eq 'receptive_owner') {
        @users = grep {
                    $_
                and $_->{role} eq 'owner'
                and ($_->{reception} || 'mail') ne 'nomail'
        } @{$admin_user || []};
    } else {
        die sprintf 'Unknown role "%s"', $role;
    }

    if (defined $query{email}) {
        @users = grep { ($_->{email} || '') eq $query{email} } @users;
    }

    return wantarray ? @users : [@users];
}

# Get all admins passing cache.
# Note: Use with care. This increases database load.
sub get_current_admins {
    my $self = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm and $sth = $sdm->do_prepared_query(
            sprintf(
                q{SELECT %s, role_admin AS "role"
                  FROM admin_table
                  WHERE list_admin = ? AND robot_admin = ?
                  ORDER BY user_admin},
                _list_admin_cols($sdm)
            ),
            $self->{'name'},
            $self->{'domain'}
        )
    ) {
        $log->syslog('err', 'Unable to get admins for list %s', $self);
        return undef;
    }
    my $admin_user = $sth->fetchall_arrayref({}) || [];
    $sth->finish;

    foreach my $user (@$admin_user) {
        $user->{'email'} = Sympa::Tools::Text::canonic_email($user->{'email'})
            if defined $user->{'email'};
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s', $self)
            unless defined $user->{'email'};
        $user->{'reception'}   ||= 'mail';
        $user->{'visibility'}  ||= 'noconceal';
        $user->{'update_date'} ||= $user->{'date'};

        # Compat.<=6.2.44 FIXME: needed?
        $user->{'included'} = 1
            if defined $user->{'inclusion'};
    }

    return $admin_user;
}

sub get_admins_email {
    my $self = shift;
    my $role = lc(shift || '');

    return unless $role;    # Returns void.

    return map { $_->{email} } @{$self->get_admins($role) || []};
}

## Returns the first bouncing user

sub get_first_bouncing_list_member {
    my $self = shift;
    $log->syslog('debug2', '');

    my $name = $self->{'name'};

    my $sdm = Sympa::DatabaseManager->instance;
    push @sth_stack, $sth;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            sprintf(
                q{SELECT %s
                FROM subscriber_table
                WHERE list_subscriber = ? AND robot_subscriber = ? AND
                      bounce_subscriber IS NOT NULL},
                _list_member_cols($sdm)
            ),
            $self->{'name'},
            $self->{'domain'}
        )
    ) {
        $log->syslog('err', 'Unable to get bouncing users %s@%s',
            $name, $self->{'domain'});
        return undef;
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');

    if (defined $user) {
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s',
            $self->{'name'})
            unless defined $user->{'email'} and length $user->{'email'};

        # Compat.<=6.2.44 FIXME: needed?
        $user->{'included'} = 1
            if defined $user->{'inclusion'};
    } else {
        $sth->finish;
        $sth = pop @sth_stack;
    }

    return $user;
}

## Loop for all subsequent bouncing users.
sub get_next_bouncing_list_member {
    my $self = shift;
    $log->syslog('debug2', '');

    unless (defined $sth) {
        $log->syslog(
            'err',
            'No handle defined, get_first_bouncing_list_member(%s) was not run',
            $self->{'name'}
        );
        return undef;
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');

    if (defined $user) {
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s',
            $self->{'name'})
            if (!$user->{'email'});

        if (defined $user->{custom_attribute}) {
            $user->{'custom_attribute'} =
                Sympa::Tools::Data::decode_custom_attribute(
                $user->{'custom_attribute'});
        }

        # Compat.<=6.2.44 FIXME: needed?
        $user->{'included'} = 1
            if defined $user->{'inclusion'};
    } else {
        $sth->finish;
        $sth = pop @sth_stack;
    }

    return $user;
}

sub parse_list_member_bounce {
    my ($self, $user) = @_;
    if ($user->{bounce}) {
        $user->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
        $user->{'first_bounce'} = $1;
        $user->{'last_bounce'}  = $2;
        $user->{'bounce_count'} = $3;
        if ($5 =~ /^(\d+)\.\d+\.\d+$/) {
            $user->{'bounce_class'} = $1;
        }

        ## Define color in function of bounce_score
        if ($user->{'bounce_score'} <=
            $self->{'admin'}{'bouncers_level1'}{'rate'}) {
            $user->{'bounce_level'} = 0;
        } elsif ($user->{'bounce_score'} <=
            $self->{'admin'}{'bouncers_level2'}{'rate'}) {
            $user->{'bounce_level'} = 1;
        } else {
            $user->{'bounce_level'} = 2;
        }
    }
}

# Old names: get_first_list_member() and get_next_list_member().
sub get_members {
    $log->syslog('debug2', '(%s, %s, %s => %s, %s => %s, %s => %s)', @_);
    my $self    = shift;
    my $role    = shift;
    my %options = @_;

    my $limit  = $options{limit};
    my $offset = $options{offset};
    my $order  = $options{order};
    my $cond   = $options{othercondition};

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    # Filters
    my $filter = '';
    if ($role eq 'member') {
        $filter = '';
    } elsif ($role eq 'unconcealed_member') {
        $filter = " AND visibility_subscriber <> 'conceal'";
    } else {
        die sprintf 'Unknown role "%s"', $role;
    }

    if ($cond) {
        $filter .= " AND ($cond)";
    }

    # SORT BY
    my $order_by = '';
    if ($order) {
        $order_by = 'ORDER BY '
            . (
            {   email => 'user_subscriber',
                date  => 'date_epoch_subscriber DESC',
                sources =>
                    'subscribed_subscriber DESC, inclusion_label_subscriber ASC',
                name => 'comment_subscriber',
            }->{$order}
                || 'user_subscriber'
            );
    }

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            sprintf(
                q{SELECT %s
                  FROM subscriber_table
                  WHERE list_subscriber = ? AND robot_subscriber = ?%s
                  %s},
                _list_member_cols($sdm), $filter, $order_by
            ),
            $self->{'name'},
            $self->{'domain'}
        )
    ) {
        $log->syslog('err', 'Unable to get members of list %s', $self);
        return;    # Returns void.
    }

    # Offset
    # Note: Several RDBMSs don't support nonstandard OFFSET clause, OTOH
    # some others don't support standard ROW_NUMBER function.
    # Instead, fetch unneccessary rows and discard them.
    if (defined $offset) {
        my $remainder = $offset;
        while (1000 < $remainder) {
            $remainder -= 1000;
            my $rows = $sth->fetchall_arrayref([qw(email)], 1000);
            last unless $rows and @$rows;
        }
        if (0 < $remainder) {
            $sth->fetchall_arrayref([qw(email)], $remainder);
        }
    }

    my $users = $sth->fetchall_arrayref({}, ($limit || undef));
    $sth->finish;

    foreach my $user (@{$users || []}) {
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s',
            $self->{'name'})
            unless $user->{email};

        $user->{reception} ||= 'mail';
        $user->{reception} =
            $self->{'admin'}{'default_user_options'}{'reception'}
            unless $self->is_available_reception_mode($user->{reception});
        $user->{visibility}  ||= 'noconceal';
        $user->{update_date} ||= $user->{date};

        if (defined $user->{custom_attribute}) {
            my $custom_attr = Sympa::Tools::Data::decode_custom_attribute(
                $user->{custom_attribute});
            unless (defined $custom_attr) {
                $log->syslog(
                    'err',
                    "Failed to parse custom attributes for user %s, list %s",
                    $user->{email},
                    $self
                );
            }
            $user->{custom_attribute} = $custom_attr;
        }

        # Compat.<=6.2.44 FIXME: needed?
        $user->{included} = 1
            if defined $user->{'inclusion'};
    }

    return wantarray ? @$users : $users;
}

# Old name: get_resembling_list_members_no_object().
# Note that the name of this function in 6.2a.32 or earlier is
# "get_ressembling_list_members_no_object" (look at doubled "s").
sub get_resembling_members {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self      = shift;
    my $role      = shift;
    my $searchkey = Sympa::Tools::Text::canonic_email(shift);

    return unless defined $searchkey;
    $searchkey =~ s/(['%_\\])/\\$1/g;

    my ($local, $domain) = split /\@/, $searchkey;
    return unless $local and $domain;
    my ($account, $ext)  = ($local =~ /\A(.*)[+](.*)\z/);
    my ($first,   $name) = ($local =~ /\A(.*)[.](.*)\z/);
    my $initial = $1 if defined $first and $first =~ /\A([a-z])/;
    $initial .= $1
        if defined $initial
        and defined $name
        and $name =~ /\A([a-z])/;
    my ($top, $upperdomain) = split /[.]/, $domain, 2;

    my @cond;
    ##### plused
    # is subscriber a plused email ?
    push @cond, $account . '@' . $domain if defined $ext;
    # is some subscriber ressembling with a plused email ?
    push @cond, $local . '+%@' . $domain;
    # ressembling local part
    # try to compare firstname.name@domain with name@domain
    push @cond, '%' . $local . '@' . $domain;
    push @cond, $name . '@' . $domain if defined $name;
    #### Same local_part and ressembling domain
    # compare host.domain.tld with domain.tld
    # remove first token if there is still at least 2 tokens try to
    # find a subscriber with that domain
    push @cond, $local . '@' . $upperdomain if defined $upperdomain;
    push @cond, $local . '@%' . $domain;
    # looking for initial
    push @cond, $initial . '@' . $domain if defined $initial;
    #XXX#### users in the same local part in any other domain
    #XXXpush @cond, $local . '@%';
    my $cond = join ' OR ', map {"user_subscriber LIKE '$_'"} @cond;
    return unless $cond;

    my $users = [$self->get_members($role, othercondition => $cond)];
    return wantarray ? @$users : $users;
}

#DEPRECATED.  Merged into get_resembling_members().
#sub find_list_member_by_pattern_no_object;

sub get_info {
    my $self = shift;

    my $info;

    unless (open INFO, "$self->{'dir'}/info") {
        $log->syslog('err', 'Could not open %s: %m',
            $self->{'dir'} . '/info');
        return undef;
    }

    while (<INFO>) {
        $info .= $_;
    }
    close INFO;

    return $info;
}

## Total bouncing subscribers
sub get_total_bouncing {
    my $self = shift;
    $log->syslog('debug2', '');

    my $name = $self->{'name'};

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    ## Query the Database
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT count(*)
              FROM subscriber_table
              WHERE list_subscriber = ? AND robot_subscriber = ? AND
                    bounce_subscriber IS NOT NULL},
            $name, $self->{'domain'}
        )
    ) {
        $log->syslog('err',
            'Unable to gather bouncing subscribers count for list %s@%s',
            $name, $self->{'domain'});
        return undef;
    }

    my $total = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $total;
}

## Does the user have a particular function in the list?
# Old name: [<=6.2.3] am_i().
sub is_admin {
    $log->syslog('debug2', '(%s, %s, %s, %s)', @_);
    my $self = shift;
    my $role = lc(shift || '');
    my $who  = shift;

    return undef unless defined $who and length $who;

    if (@{$self->get_admins($role, filter => [email => $who])}) {
        return 1;
    } else {
        return undef;
    }
}

## Is the person in user table (db only)
##sub is_global_user {
## DEPRECATED: Use Sympa::User::is_global_user().

## Is the indicated person a subscriber to the list?
sub is_list_member {
    $log->syslog('debug2', '(%s, %s)', @_);
    my ($self, $who) = @_;
    $who = Sympa::Tools::Text::canonic_email($who);

    return undef unless $who;

    my $is_list_member = $self->_cache_get('is_list_member');
    if (defined $is_list_member and defined $is_list_member->{$who}) {
        return $is_list_member->{$who};
    }
    $is_list_member ||= {};

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT count(*)
              FROM subscriber_table
              WHERE list_subscriber = ? AND robot_subscriber = ? AND
                    user_subscriber = ?},
            $self->{'name'}, $self->{'domain'}, $who
        )
    ) {
        $log->syslog('err',
            'Unable to check chether user %s is subscribed to list %s',
            $who, $self);
        return undef;
    }
    $is_list_member->{$who} = $sth->fetchrow;
    $self->_cache_put('is_list_member', $is_list_member);
    $sth->finish;

    return $is_list_member->{$who};
}

## Sets new values for the given user (except gecos)
sub update_list_member {
    my $self   = shift;
    my $who    = Sympa::Tools::Text::canonic_email(shift);
    my $values = $_[0];                                      # Compat.
    $values = {@_} unless ref $values eq 'HASH';

    my ($field, $value, $table);

    # Mapping between var and field names.
    my %map_field = _map_list_member_cols();

    my $sdm = Sympa::DatabaseManager->instance;
    return undef unless $sdm;

    my @set_list;
    my @val_list;
    while (($field, $value) = each %{$values}) {
        die sprintf 'Unknown database field %s', $field
            unless $map_field{$field};

        if ($field eq 'custom_attribute') {
            push @set_list, sprintf('%s = ?', $map_field{$field});
            push @val_list,
                Sympa::Tools::Data::encode_custom_attribute($value);
        } elsif ($numeric_field{$map_field{$field}}) {
            push @set_list, sprintf('%s = ?', $map_field{$field});
            # FIXME: Can't have a null value?
            push @val_list, ($value || 0);
        } else {
            push @set_list, sprintf('%s = ?', $map_field{$field});
            push @val_list, $value;
        }
    }
    return 0 unless @set_list;

    # Update field
    if ($who eq '*') {
        unless (
            $sdm->do_prepared_query(
                sprintf(
                    q{UPDATE subscriber_table
                      SET %s
                      WHERE list_subscriber = ? AND robot_subscriber = ?},
                    join(', ', @set_list)
                ),
                @val_list,
                $self->{'name'},
                $self->{'domain'}
            )
        ) {
            $log->syslog(
                'err',
                'Could not update information for subscriber %s in database for list %s',
                $who,
                $self
            );
            return undef;
        }
    } else {
        unless (
            $sdm->do_prepared_query(
                sprintf(
                    q{UPDATE subscriber_table
                      SET %s
                      WHERE user_subscriber = ? AND
                            list_subscriber = ? AND robot_subscriber = ?},
                    join(',', @set_list)
                ),
                @val_list,
                $who,
                $self->{'name'},
                $self->{'domain'}
            )
        ) {
            $log->syslog(
                'err',
                'Could not update information for subscriber %s in database for list %s',
                $who,
                $self
            );
            return undef;
        }
    }

    # Delete subscription / signoff requests no longer used.
    my $new_email;
    if (    $who ne '*'
        and $values->{'email'}
        and $new_email = Sympa::Tools::Text::canonic_email($values->{'email'})
        and $who ne $new_email) {
        my $spool_req;

        # Delete signoff requests if any.
        $spool_req = Sympa::Spool::Auth->new(
            context => $self,
            action  => 'del',
            email   => $who,
        );
        while (1) {
            my ($request, $handle) = $spool_req->next;
            last unless $handle;
            next unless $request;

            $spool_req->remove($handle);
        }

        # Delete subscription requests if any.
        $spool_req = Sympa::Spool::Auth->new(
            context => $self,
            action  => 'add',
            email   => $new_email,
        );
        while (1) {
            my ($request, $handle) = $spool_req->next;
            last unless $handle;
            next unless $request;

            $spool_req->remove($handle);
        }
    }

    # Rename picture on disk if user email changed.
    if ($values->{'email'}) {
        foreach my $path ($self->find_picture_paths($who)) {
            my $extension = [reverse split /\./, $path]->[0];
            my $new_path = $self->get_picture_path(
                Digest::MD5::md5_hex($values->{'email'}) . '.' . $extension);
            unless (rename $path, $new_path) {
                $log->syslog('err', 'Failed to rename %s to %s : %m',
                    $path, $new_path);
                last;
            }
        }
    }

    return 1;
}

## Sets new values for the given admin user (except gecos)
sub update_list_admin {
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $self   = shift;
    my $who    = Sympa::Tools::Text::canonic_email(shift);
    my $role   = shift;
    my $values = $_[0];                                      # Compat.
    $values = {@_} unless ref $values eq 'HASH';

    my ($field, $value, $table);
    my $name = $self->{'name'};

    ## mapping between var and field names
    my %map_field = (
        reception       => 'reception_admin',
        visibility      => 'visibility_admin',
        date            => 'date_epoch_admin',
        update_date     => 'update_epoch_admin',
        inclusion       => 'inclusion_admin',
        inclusion_ext   => 'inclusion_ext_admin',
        inclusion_label => 'inclusion_label_admin',
        gecos           => 'comment_admin',
        password        => 'password_user',
        email           => 'user_admin',
        subscribed      => 'subscribed_admin',
        info            => 'info_admin',
        profile         => 'profile_admin',
        role            => 'role_admin'
    );

    ## mapping between var and tables
    my %map_table = (
        reception       => 'admin_table',
        visibility      => 'admin_table',
        date            => 'admin_table',
        update_date     => 'admin_table',
        inclusion       => 'admin_table',
        inclusion_ext   => 'admin_table',
        inclusion_label => 'admin_table',
        gecos           => 'admin_table',
        password        => 'user_table',
        email           => 'admin_table',
        subscribed      => 'admin_table',
        info            => 'admin_table',
        profile         => 'admin_table',
        role            => 'admin_table'
    );
    #### ??
    ## additional DB fields
    #if (defined $Conf::Conf{'db_additional_user_fields'}) {
    #    foreach my $f (split ',', $Conf::Conf{'db_additional_user_fields'}) {
    #        $map_table{$f} = 'user_table';
    #        $map_field{$f} = $f;
    #    }
    #}

    # Compat.<=6.2.44 FIXME: is this used?
    $values->{inclusion} ||= ($values->{update_date} || time)
        if $values->{included};

    my $sdm = Sympa::DatabaseManager->instance;
    return undef unless $sdm;

    ## Update each table
    foreach $table ('user_table', 'admin_table') {

        my @set_list;
        while (($field, $value) = each %{$values}) {

            unless ($map_field{$field} and $map_table{$field}) {
                $log->syslog('err', 'Unknown database field %s', $field);
                next;
            }

            if ($map_table{$field} eq $table) {
                if ($value and $value eq 'NULL') {    #FIXME:get_null_value?
                    if ($Conf::Conf{'db_type'} eq 'mysql') {
                        $value = '\N';
                    }
                } elsif ($numeric_field{$map_field{$field}}) {
                    $value ||= 0;    #FIXME:Can't have a null value
                } else {
                    $value = $sdm->quote($value);
                }
                my $set = sprintf "%s=%s", $map_field{$field}, $value;

                push @set_list, $set;
            }
        }
        next unless @set_list;

        ## Update field
        if ($table eq 'user_table') {
            unless (
                $sth = $sdm->do_query(
                    q{UPDATE %s SET %s WHERE email_user = %s},
                    $table, join(',', @set_list),
                    $sdm->quote($who)
                )
            ) {
                $log->syslog('err',
                    'Could not update information for admin %s in table %s',
                    $who, $table);
                return undef;
            }

        } elsif ($table eq 'admin_table') {
            if ($who eq '*') {
                unless (
                    $sth = $sdm->do_query(
                        q{UPDATE %s
                          SET %s
                          WHERE list_admin = %s AND robot_admin = %s AND
                                role_admin = %s},
                        $table,
                        join(',', @set_list),
                        $sdm->quote($name),
                        $sdm->quote($self->{'domain'}),
                        $sdm->quote($role)
                    )
                ) {
                    $log->syslog(
                        'err',
                        'Could not update information for admin %s in table %s for list %s@%s',
                        $who,
                        $table,
                        $name,
                        $self->{'domain'}
                    );
                    return undef;
                }
            } else {
                unless (
                    $sth = $sdm->do_query(
                        q{UPDATE %s
                          SET %s
                          WHERE user_admin = %s AND
                          list_admin = %s AND robot_admin = %s AND
                          role_admin = %s},
                        $table,
                        join(',', @set_list),
                        $sdm->quote($who),
                        $sdm->quote($name),
                        $sdm->quote($self->{'domain'}),
                        $sdm->quote($role)
                    )
                ) {
                    $log->syslog(
                        'err',
                        'Could not update information for admin %s in table %s for list %s@%s',
                        $who,
                        $table,
                        $name,
                        $self->{'domain'}
                    );
                    return undef;
                }
            }
        }
    }

    # Reset session cache.
    $self->_cache_publish_expiry('admin_user');

    return 1;
}

## Sets new values for the given user in the Database
##sub update_global_user {
## DEPRECATED: Use Sympa::User::update_global_user() or $user->save().

## Adds a user to the user_table
##sub add_global_user {
## DEPRECATED: Use Sympa::User::add_global_user() or $user->save().

## Adds a list member ; no overwrite.
sub add_list_member {
    $log->syslog('debug2', '%s, ...', @_);
    my $self      = shift;
    my @new_users = @_;

    my $name = $self->{'name'};

    $self->{'add_outcome'}                                   = undef;
    $self->{'add_outcome'}{'added_members'}                  = 0;
    $self->{'add_outcome'}{'expected_number_of_added_users'} = $#new_users;
    $self->{'add_outcome'}{'remaining_members_to_add'} =
        $self->{'add_outcome'}{'expected_number_of_added_users'};

    my $current_list_members_count = 0;
    if ($self->{'admin'}{'max_list_members'} > 0) {
        $current_list_members_count = $self->get_total;  # FIXME: high db load
    }

    my $sdm = Sympa::DatabaseManager->instance;

    foreach my $new_user (@new_users) {
        my $who = Sympa::Tools::Text::canonic_email($new_user->{'email'});
        unless (defined $who) {
            $log->syslog('err', 'Ignoring %s which is not a valid email',
                $new_user->{'email'});
            next;
        }
        if (Sympa::Tools::Domains::is_blacklisted($who)) {
            $log->syslog('err', 'Ignoring %s which uses a blacklisted domain',
                $new_user->{'email'});
            next;
        }
        unless (
            $current_list_members_count < $self->{'admin'}{'max_list_members'}
            || $self->{'admin'}{'max_list_members'} == 0) {
            $self->{'add_outcome'}{'errors'}{'max_list_members_exceeded'} = 1;
            $log->syslog(
                'notice',
                'Subscription of user %s failed: max number of subscribers (%s) reached',
                $new_user->{'email'},
                $self->{'admin'}{'max_list_members'}
            );
            last;
        }

        # Delete from exclusion_table and force a sync_include if new_user was
        # excluded
        if ($self->insert_delete_exclusion($who, 'delete')) {
            $self->sync_include('member');
            if ($self->is_list_member($who)) {
                $self->{'add_outcome'}{'added_members'}++;
                next;
            }
        }

        $new_user->{'date'} ||= time;
        $new_user->{'update_date'} ||= $new_user->{'date'};

        my $custom_attribute;
        if (ref $new_user->{'custom_attribute'} eq 'HASH') {
            $new_user->{'custom_attribute'} =
                Sympa::Tools::Data::encode_custom_attribute(
                $new_user->{'custom_attribute'});
        }
        $log->syslog(
            'debug3',
            'Custom_attribute = %s',
            $new_user->{'custom_attribute'}
        );

        # Compat.<=6.2.44 FIXME: needed?
        $new_user->{'inclusion'} ||= ($new_user->{'date'} || time)
            if $new_user->{'included'};

        ## Either is_included or is_subscribed must be set
        ## default is is_subscriber for backward compatibility reason
        $new_user->{'subscribed'} = 1 unless defined $new_user->{'inclusion'};
        $new_user->{'subscribed'} ||= 0;

        unless (defined $new_user->{'inclusion'}) {
            ## Is the email in user table?
            ## Insert in User Table
            unless (
                Sympa::User->new(
                    $who,
                    'gecos'    => $new_user->{'gecos'},
                    'lang'     => $new_user->{'lang'},
                    'password' => $new_user->{'password'}
                )
            ) {
                $log->syslog('err', 'Unable to add user %s to user_table',
                    $who);
                $self->{'add_outcome'}{'errors'}{'unable_to_add_to_database'}
                    = 1;
                next;
            }
        }

        #Log in stat_table to make staistics
        $log->add_stat(
            'robot'     => $self->{'domain'},
            'list'      => $self->{'name'},
            'operation' => 'add_or_subscribe',
            'parameter' => '',
            'mail'      => $new_user->{'email'}
        );

        ## Update Subscriber Table
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{INSERT INTO subscriber_table
                  (user_subscriber, comment_subscriber,
                   list_subscriber, robot_subscriber,
                   date_epoch_subscriber, update_epoch_subscriber,
                   inclusion_subscriber, inclusion_ext_subscriber,
                   inclusion_label_subscriber,
                   reception_subscriber, topics_subscriber,
                   visibility_subscriber, subscribed_subscriber,
                   custom_attribute_subscriber,
                   suspend_subscriber,
                   suspend_start_date_subscriber,
                   suspend_end_date_subscriber,
                   number_messages_subscriber)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)},
                $who,                     $new_user->{'gecos'},
                $name,                    $self->{'domain'},
                $new_user->{'date'},      $new_user->{'update_date'},
                $new_user->{'inclusion'}, $new_user->{'inclusion_ext'},
                $new_user->{'inclusion_label'},
                $new_user->{'reception'},  $new_user->{'topics'},
                $new_user->{'visibility'}, $new_user->{'subscribed'},
                $new_user->{'custom_attribute'},
                $new_user->{'suspend'},
                $new_user->{'startdate'},
                $new_user->{'enddate'}
            )
        ) {
            $log->syslog(
                'err',
                'Unable to add subscriber %s to table subscriber_table for list %s@%s %s',
                $who,
                $name,
                $self->{'domain'}
            );
            next;
        }

        # Delete subscription requests if any.
        my $spool_req = Sympa::Spool::Auth->new(
            context => $self,
            action  => 'add',
            email   => $who,
        );
        while (1) {
            my ($request, $handle) = $spool_req->next;
            last unless $handle;
            next unless $request;

            $spool_req->remove($handle);
        }

        $self->{'add_outcome'}{'added_members'}++;
        $self->{'add_outcome'}{'remaining_member_to_add'}--;
        $current_list_members_count++;
    }

    $self->_cache_publish_expiry('member');
    $self->_create_add_error_string() if ($self->{'add_outcome'}{'errors'});
    return 1;
}

sub _create_add_error_string {
    my $self = shift;
    $self->{'add_outcome'}{'errors'}{'error_message'} = '';
    if ($self->{'add_outcome'}{'errors'}{'max_list_members_exceeded'}) {
        $self->{'add_outcome'}{'errors'}{'error_message'} .=
            $language->gettext_sprintf(
            'Attempt to exceed the max number of members (%s) for this list.',
            $self->{'admin'}{'max_list_members'}
            );
    }
    if ($self->{'add_outcome'}{'errors'}{'unable_to_add_to_database'}) {
        $self->{'add_outcome'}{'error_message'} .= ' '
            . $language->gettext(
            'Attempts to add some users in database failed.');
    }
    $self->{'add_outcome'}{'errors'}{'error_message'} .= ' '
        . $language->gettext_sprintf(
        'Added %s users out of %s required.',
        $self->{'add_outcome'}{'added_members'},
        $self->{'add_outcome'}{'expected_number_of_added_users'}
        );
}

## Adds a new list admin user, no overwrite.
sub add_list_admin {
    $log->syslog('debug2', '(%s, %s, ...)', @_);
    my $self  = shift;
    my $role  = shift;
    my @users = @_;

    my $total = 0;
    foreach my $user (@users) {
        $total++ if $self->_add_list_admin($role, $user);
    }

    $self->_cache_publish_expiry('admin_user') if $total;
    return $total;
}

sub _add_list_admin {
    my $self    = shift;
    my $role    = shift;
    my $user    = shift;
    my %options = @_;

    my $who = Sympa::Tools::Text::canonic_email($user->{'email'});
    return undef unless defined $who and length $who;

    unless (defined $user->{'inclusion'}) {
        # Is the email in user_table? Insert it.
        #FIXME: Is it required?
        unless (
            Sympa::User->new(
                $who,
                'gecos'    => $user->{'gecos'},
                'lang'     => $user->{'lang'},
                'password' => $user->{'password'},
            )
        ) {
            $log->syslog('err', 'Unable to add admin %s to user_table', $who);
            return undef;
        }
    }

    $user->{'reception'}  ||= 'mail';
    $user->{'visibility'} ||= 'noconceal';
    $user->{'profile'}    ||= 'normal';

    $user->{'date'} ||= time;
    $user->{'update_date'} ||= $user->{'date'};

    # Compat.<=6.2.44 FIXME: needed?
    $user->{'inclusion'} ||= $user->{'date'}
        if $user->{'included'};

    # Either is_included or is_subscribed must be set.
    # Default is is_subscriber for backward compatibility reason.
    $user->{'subscribed'} = 1 unless defined $user->{'inclusion'};
    $user->{'subscribed'} ||= 0;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;
    my %map_field = _map_list_admin_cols();
    my @key_list =
        grep { $_ ne 'email' and $_ ne 'role' } sort keys %map_field;
    my (@set_list, @val_list);

    # Update Admin Table
    @set_list =
        @map_field{grep { $_ ne 'date' and exists $user->{$_} } @key_list};
    @val_list =
        @{$user}{grep { $_ ne 'date' and exists $user->{$_} } @key_list};
    if (    $options{replace}
        and @set_list
        and $sdm
        and $sth = $sdm->do_prepared_query(
            sprintf(
                q{UPDATE admin_table
                  SET %s
                  WHERE role_admin = ? AND user_admin = ? AND
                        list_admin = ? AND robot_admin = ?},
                join(', ', map { sprintf '%s = ?', $_ } @set_list)
            ),
            @val_list,
            $role,
            $user->{email},
            $self->{'name'},
            $self->{'domain'}
        )
        and $sth->rows    # If no affected rows, then insert a new row
    ) {
        return 1;
    }
    @set_list = @map_field{@key_list};
    @val_list = @{$user}{@key_list};
    if (    @set_list
        and $sdm
        and $sdm->do_prepared_query(
            sprintf(
                q{INSERT INTO admin_table
                  (%s, role_admin, user_admin, list_admin, robot_admin)
                  VALUES (%s, ?, ?, ?, ?)},
                join(', ', @set_list),
                join(', ', map {'?'} @set_list)
            ),
            @val_list,
            $role,
            $who,
            $self->{'name'},
            $self->{'domain'}
        )
    ) {
        return 1;
    }

    $log->syslog('err',
        'Unable to add %s %s to table admin_table for list %s',
        $role, $who, $self);
    return undef;
}

# Moved to: (part of) Sympa::Request::Handler::move_list::_move().
#sub rename_list_db;

## Check list authorizations
## Higher level sub for request_action
# DEPRECATED; Use Sympa::Scenario::request_action();
#sub check_list_authz;

## Initialize internal list cache
# Deprecated. No longer used.
#sub init_list_cache;

## May the indicated user edit the indicated list parameter or not?
sub may_edit {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $self      = shift;
    my $parameter = shift;
    my $who       = shift;
    my %options   = @_;

    # Special case for file edition.
    if ($options{file}) {
        $parameter = 'info.file' if $parameter eq 'info';
    }

    # Load edit_list.conf: Track by file, not domain (file may come from
    # server, robot, family or list context).
    my $edit_list_conf =
           $self->_cache_get('edit_list_conf')
        || $self->_cache_put('edit_list_conf', $self->_load_edit_list_conf)
        || {};

    my $role;

    ## What privilege?
    if (Sympa::is_listmaster($self, $who)) {
        $role = 'listmaster';
    } elsif ($self->is_admin('privileged_owner', $who)) {
        $role = 'privileged_owner';
    } elsif ($self->is_admin('owner', $who)) {
        $role = 'owner';
    } elsif ($self->is_admin('editor', $who)) {
        $role = 'editor';
#    }elsif ( $self->is_admin('subscriber',$who) ) {
#	$role = 'subscriber';
    } else {
        return ('user', 'hidden');
    }

    ## What privilege does he/she has?
    my ($what, @order);

    if (    $parameter =~ /^(\w+)\.(\w+)$/
        and $parameter !~ /\.tt2$/
        and $parameter ne 'message_header.mime'
        and $parameter ne 'message_footer.mime'
        and $parameter ne 'message_global_footer.mime') {
        my $main_parameter = $1;
        @order = (
            $edit_list_conf->{$parameter}{$role},
            $edit_list_conf->{$main_parameter}{$role},
            $edit_list_conf->{'default'}{$role},
            $edit_list_conf->{'default'}{'default'}
        );
    } else {
        @order = (
            $edit_list_conf->{$parameter}{$role},
            $edit_list_conf->{'default'}{$role},
            $edit_list_conf->{'default'}{'default'}
        );
    }

    foreach $what (@order) {
        if (defined $what) {
            return ($role, $what);
        }
    }

    return ('user', 'hidden');
}

# Never used.
#sub may_create_parameter;

# OBSOLETED: No longer used.
#sub may_do;

## Does the list support digest mode
sub is_digest {
    return (shift->{'admin'}{'digest'});
}

## Does the file exist?
# DEPRECATED.  No longer used.
#sub archive_exist;

## List the archived files
# DEPRECATED.  Use Sympa::Archive::get_archives().
#sub archive_ls;

# Merged into distribute_msg().
#sub archive_msg;

## Is the list moderated?
sub is_moderated {

    return 1 if (defined shift->{'admin'}{'editor'});

    return 0;
}

## Is the list archived?
#FIXME: Broken. Use scenario or is_archiving_enabled().
sub is_archived {
    $log->syslog('debug', '');
    if (shift->{'admin'}{'archive'}{'web_access'}) {
        $log->syslog('debug', '1');
        return 1;
    }
    $log->syslog('debug', 'Undef');
    return undef;
}

## Is the list web archived?
#FIXME: Broken. Use scenario or is_archiving_enabled().
sub is_web_archived {
    my $self = shift;
    return 1
        if ref $self->{'admin'}{'archive'} eq 'HASH'
        and $self->{'admin'}{'archive'}{'web_access'};
    return undef;
}

sub is_archiving_enabled {
    return Sympa::Tools::Data::smart_eq(shift->{'admin'}{'process_archive'},
        'on');
}

sub is_included {
    my $self = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT COUNT(*)
              FROM inclusion_table
              WHERE source_inclusion = ?},
            $self->get_id
        )
    ) {
        $log->syslog('err', 'Failed to get inclusion information on list %s',
            $self);
        return 1;    # Fake positive result.
    }
    my ($num) = $sth->fetchrow_array;
    $sth->finish;

    return $num;
}

# Old name: Sympa::List::get_nextdigest().
# Moved to Sympa::Spindle::ProcessDigest::_may_distribute_digest().
#sub may_distribute_digest;

# Moved: Use Sympa::Scenario::get_scenarios().
#sub load_scenario_list;

# Deprecated: Use Sympa::Task::get_tasks().
#sub load_task_list;

# No longer used.
#sub _load_task_title;

## Loads all data sources
sub load_data_sources_list {
    my ($self, $robot) = @_;
    $log->syslog('debug3', '(%s, %s)', $self->{'name'}, $robot);

    my %list_of_data_sources;

    foreach
        my $dir (@{Sympa::get_search_path($self, subdir => 'data_sources')}) {
        next unless -d $dir;

        while (my $file = <$dir/*.incl>) {
            next unless $file =~ m{(?<=/)([^./][^/]*)\.incl\z};
            my $name = $1;    # FIXME: Escape or omit hostile characters.

            next if defined $list_of_data_sources{$name};

            open my $fh, '<', $file or next;
            my ($title) = grep {s/\A\s*name\s+(.+)/$1/} <$fh>;
            close $fh;
            $list_of_data_sources{$name}{'title'} = $title || $name;

            $list_of_data_sources{$name}{'name'} = $name;
        }
    }

    return \%list_of_data_sources;
}

## Loads the statistics information
# No longer used.
#sub _load_stats_file;

## Loads the list of users.
# Old name:: Sympa::List::_load_list_members_file($file) which loaded members.
sub restore_users {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $role = shift;

    die 'bug in logic. Ask developer'
        unless grep { $role eq $_ } qw(member owner editor);

    # Open the file and switch to paragraph mode.
    my $file = $self->{'dir'} . '/' . $role . '.dump';
    my $lock_fh = Sympa::LockedFile->new($file, 5, '<') or return;
    local $RS = '';

    my $time = time;
    if ($role eq 'member') {
        my %map_field = _map_list_member_cols();

        while (my $para = <$lock_fh>) {
            my $user = {
                map {
                    #FIMXE: Define appropriate schema.
                    if (/^\s*(suspend|subscribed|included)\s+(\S+)\s*$/) {
                        # Note: "included" is kept for comatibility.
                        ($1 => !!$2);
                    } elsif (/^\s*(custom_attribute)\s+(.+)\s*$/) {
                        my $k = $1;
                        my $decoded =
                            Sympa::Tools::Data::decode_custom_attribute($2);
                        ($decoded and %$decoded) ? ($k => $decoded) : ();
                    } elsif (
                        /^\s*(date|update_date|inclusion|inclusion_ext|startdate|enddate|bounce_score|number_messages)\s+(\d+)\s*$/
                        or
                        /^\s*(reception)\s+(mail|digest|nomail|summary|notice|txt|html|urlize|not_me)\s*$/
                        or /^\s*(visibility)\s+(conceal|noconceal)\s*$/
                        or (/^\s*(\w+)\s+(.+)\s*$/ and $map_field{$1})) {
                        ($1 => $2);
                    } else {
                        ();
                    }
                } split /\n/,
                $para
            };
            next unless $user->{email};

            $user->{update_date} = $time;
            # Compat. <= 6.2.44
            # This is needed for dump by earlier version of Sympa.
            $user->{inclusion} ||= ($user->{update_date} || time)
                if $user->{included};

            $self->add_list_member($user);
        }
    } else {
        my $changed   = 0;
        my %map_field = _map_list_admin_cols();

        while (my $para = <$lock_fh>) {
            my $user = {
                map {
                    #FIMXE:Define appropriate schema.
                    if (/^\s*(subscribed|included)\s+(\S+)\s*$/) {
                        # Note: "included" is kept for comatibility.
                        ($1 => !!$2);
                    } elsif (/^\s*(email|gecos|info|id)\s+(.+)\s*$/
                        or /^\s*(profile)\s+(normal|privileged)\s*$/
                        or
                        /^\s*(date|update_date|inclusion|inclusion_ext)\s+(\d+)\s*$/
                        or /^\s*(reception)\s+(mail|nomail)\s*$/
                        or /^\s*(visibility)\s+(conceal|noconceal)\s*$/
                        or (/^\s*(\w+)\s+(.+)\s*$/ and $map_field{$1})) {
                        ($1 => $2);
                    } else {
                        ();
                    }
                } split /\n/,
                $para
            };
            next unless defined $user->{email} and length $user->{email};

            $user->{update_date} = $time;
            # Compat. <= 6.2.44
            # This is needed for dump by earlier version of Sympa.
            $user->{inclusion} ||= ($user->{update_date} || time)
                if $user->{included};

            $self->_add_list_admin($role, $user, replace => 1)
                and $changed++;
        }

        # Remove outdated permanent users.
        # Included users will be cleared in the next time of sync.
        my $sdm = Sympa::DatabaseManager->instance;
        my $sth;
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{DELETE FROM admin_table
                  WHERE role_admin = ? AND
                        list_admin = ? AND robot_admin = ? AND
                        subscribed_admin = 1 AND
                        inclusion_admin IS NULL AND
                        (update_epoch_admin IS NULL OR
                         update_epoch_admin < ?)},
                $role, $self->{'name'}, $self->{'domain'},
                $time
            )
        ) {
            $log->syslog('err', '(%s) Failed to delete %s %s(s)',
                $self, $role);
        }
        $changed++ if $sth and $sth->rows;
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{UPDATE admin_table
                  SET subscribed_admin = 0, update_epoch_admin = ?
                  WHERE role_admin = ? AND
                        list_admin = ? AND robot_admin = ? AND
                        subscribed_admin = 1 AND
                        inclusion_admin IS NOT NULL AND
                        (update_epoch_admin IS NULL OR
                         update_epoch_admin < ?)},
                $time,
                $role, $self->{'name'}, $self->{'domain'},
                $time
            )
        ) {
            $log->syslog('err', '(%s) Failed to delete %s', $self, $role);
        }
        $changed++ if $sth and $sth->rows;

        $self->_cache_publish_expiry('admin_user') if $changed;
    }

    $lock_fh->close;
}

# Moved or deprecated:
#sub _include_users_remote_sympa_list;
# -> Sympa::DataSource::RemoteDump class.
#sub _get_https;
# -> No longer used.
#sub _include_users_list;
# -> Sympa::DataSource::List class.
#sub _include_users_admin;
# -> Never used.
#sub _include_users_file;
# -> Sympa::DataSource::File class.
#sub _include_users_remote_file;
# -> Sympa::DataSource::RemoteFile class.
#sub _include_users_ldap;
# -> Sympa::DataSource::LDAP class.
#sub _include_users_ldap_2level;
# -> Sympa::DataSource::LDAP2 class.
#sub _include_sql_ca;
# -> Sympa::DataSource::SQL class.
#sub _include_ldap_ca;
# -> Sympa::DataSource::LDAP class.
#sub _include_ldap_2level_ca;
# -> Sympa::DataSource::LDAP2 class.
#sub _include_users_sql;
# -> Sympa::DataSource::SQL class.
#sub _load_list_members_from_include;
# -> Sympa::Request::Handler::include class.
#sub _load_list_admin_from_include;
# -> Sympa::Request::Handler::include class.

# Load an include admin user file (xx.incl)
#FIXME: Would be merged to _load_list_config_file() which mostly duplicates.
sub _load_include_admin_user_file {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $self  = shift;
    my $entry = shift;

    my $output   = '';
    my $filename = $entry->{'source'} . '.incl';
    my @data     = split ',', $entry->{'source_parameters'}
        if defined $entry->{'source_parameters'};
    my $template = Sympa::Template->new($self, subdir => 'data_sources');
    unless ($template->parse({param => [@data]}, $filename, \$output)) {
        $log->syslog('err', 'Failed to parse %s', $filename);
        return undef;
    }
    1 while $output =~ s/(\A|\n)\s+\n/$1\n/g;    # Clean empty lines
    my @paragraphs = map { [split /\n/, $_] } split /\n\n+/, $output;

    my $robot = $self->{'domain'};

    my $pinfo = {};
    # 'include_list' is kept for comatibility with 6.2.15 or earlier.
    my @sources = (@sources_providing_listmembers, 'include_list');
    @{$pinfo}{@sources} =
        @{Sympa::Robot::list_params($robot) || {}}{@sources};

    my %include;
    for my $index (0 .. $#paragraphs) {
        my @paragraph = @{$paragraphs[$index]};

        my $pname;

        ## Clean paragraph, keep comments
        for my $i (0 .. $#paragraph) {
            my $changed = undef;
            for my $j (0 .. $#paragraph) {
                if ($paragraph[$j] =~ /^\s*\#/) {
                    chomp($paragraph[$j]);
                    push @{$include{'comment'}}, $paragraph[$j];
                    splice @paragraph, $j, 1;
                    $changed = 1;
                } elsif ($paragraph[$j] =~ /^\s*$/) {
                    splice @paragraph, $j, 1;
                    $changed = 1;
                }

                last if $changed;
            }

            last unless $changed;
        }

        ## Empty paragraph
        next unless ($#paragraph > -1);

        ## Look for first valid line
        unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
            $log->syslog(
                'info',
                'Bad paragraph "%s" in %s',
                join("\n", @paragraph), $filename
            );
            next;
        }

        $pname = $1;

        # Parameter aliases (compatibility concerns).
        my $alias = $pinfo->{$pname}{'obsolete'};
        if ($alias and $pinfo->{$alias}) {
            $paragraph[0] =~ s/^\s*$pname/$alias/;
            $pname = $alias;
        }

        unless ($pinfo->{$pname}) {
            $log->syslog('info', 'Unknown parameter "%s" in %s',
                $pname, $filename);
            next;
        }

        ## Uniqueness
        if (defined $include{$pname}) {
            unless (($pinfo->{$pname}{'occurrence'} eq '0-n')
                or ($pinfo->{$pname}{'occurrence'} eq '1-n')) {
                $log->syslog('info', 'Multiple parameter "%s" in %s',
                    $pname, $filename);
            }
        }

        ## Line or Paragraph
        if (ref $pinfo->{$pname}{'file_format'} eq 'HASH') {
            ## This should be a paragraph
            unless ($#paragraph > 0) {
                $log->syslog(
                    'info',
                    'Expecting a paragraph for "%s" parameter in %s, ignore it',
                    $pname,
                    $filename
                );
                next;
            }

            ## Skipping first line
            shift @paragraph;

            my %hash;
            for my $i (0 .. $#paragraph) {
                next if ($paragraph[$i] =~ /^\s*\#/);

                unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
                    $log->syslog('info', 'Bad line "%s" in %s',
                        $paragraph[$i], $filename);
                }

                my $key = $1;

                # Subparameter aliases (compatibility concerns).
                # Note: subparameter alias was introduced by 6.2.15.
                my $alias = $pinfo->{$pname}{'format'}{$key}{'obsolete'};
                if ($alias and $pinfo->{$pname}{'format'}{$alias}) {
                    $paragraph[$i] =~ s/^\s*$key/$alias/;
                    $key = $alias;
                }

                unless (defined $pinfo->{$pname}{'file_format'}{$key}) {
                    $log->syslog('info',
                        'Unknown key "%s" in paragraph "%s" in %s',
                        $key, $pname, $filename);
                    next;
                }

                unless ($paragraph[$i] =~
                    /^\s*$key(?:\s+($pinfo->{$pname}{'file_format'}{$key}{'file_format'}))?\s*$/i
                ) {
                    chomp($paragraph[$i]);
                    $log->syslog('info',
                        'Bad entry "%s" for key "%s", paragraph "%s" in %s',
                        $paragraph[$i], $key, $pname, $filename);
                    next;
                }

                $hash{$key} =
                    $self->_load_list_param($key, $1,
                    $pinfo->{$pname}{'file_format'}{$key});
            }

            ## Apply defaults & Check required keys
            my $missing_required_field;
            foreach my $k (keys %{$pinfo->{$pname}{'file_format'}}) {

                ## Default value
                unless (defined $hash{$k}) {
                    if (defined $pinfo->{$pname}{'file_format'}{$k}{'default'}
                    ) {
                        $hash{$k} = $self->_load_list_param(
                            $k,
                            $pinfo->{$pname}{'file_format'}{$k}{'default'},
                            $pinfo->{$pname}{'file_format'}{$k}
                        );
                    }
                }
                ## Required fields
                if ($pinfo->{$pname}{'file_format'}{$k}{'occurrence'} eq '1'
                    and not $pinfo->{$pname}{'file_format'}{$k}{'obsolete'}) {
                    unless (defined $hash{$k}) {
                        $log->syslog('info',
                            'Missing key "%s" in param "%s" in %s',
                            $k, $pname, $filename);
                        $missing_required_field++;
                    }
                }
            }

            next if $missing_required_field;

            ## Should we store it in an array
            if (($pinfo->{$pname}{'occurrence'} =~ /n$/)) {
                push @{$include{$pname}}, \%hash;
            } else {
                $include{$pname} = \%hash;
            }
        } else {
            ## This should be a single line
            unless ($#paragraph == 0) {
                $log->syslog('info',
                    'Expecting a single line for "%s" parameter in %s',
                    $pname, $filename);
            }

            unless ($paragraph[0] =~
                /^\s*$pname(?:\s+($pinfo->{$pname}{'file_format'}))?\s*$/i) {
                chomp($paragraph[0]);
                $log->syslog('info', 'Bad entry "%s" in %s',
                    $paragraph[0], $filename);
                next;
            }

            my $value = $self->_load_list_param($pname, $1, $pinfo->{$pname});

            if (($pinfo->{$pname}{'occurrence'} =~ /n$/)
                && !(ref($value) =~ /^ARRAY/)) {
                push @{$include{$pname}}, $value;
            } else {
                $include{$pname} = $value;
            }
        }
    }

    _load_include_admin_user_postprocess(\%include);

    delete $include{defaults};
    foreach my $cfgs (values %include) {
        foreach my $cfg (@{$cfgs || []}) {
            next unless ref $cfg;    # include_file doesn't have parameters
            foreach my $k (keys %$entry) {
                next if $k eq 'source';
                next if $k eq 'source_parameters';
                next unless defined $entry->{$k};
                $cfg->{$k} = $entry->{$k};
            }
        }
    }

    return \%include;
}

#sub get_list_of_sources_id;
# -> No longer used.
#sub sync_include_ca;
# -> sync_include('member').
#sub purge_ca;
# -> Never used.

# FIXME: Use Sympa::Request::Handler::include handler.
sub sync_include {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self    = shift;
    my $role    = shift;
    my %options = @_;

    $role ||= 'member';    # Compat.<=6.2.54

    return 0
        unless $self->has_data_sources($role)
        or $self->has_included_users($role);

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $self,
        action           => 'include',
        role             => $role,
        delay            => $options{delay},
        scenario_context => {skip => 1},
    );
    unless ($spindle and $spindle->spin) {
        $log->syslog('err',
            'Could not get users (%s) from an data source for list %s',
            $role, $self);
        if ($role eq 'member') {
            Sympa::send_notify_to_listmaster($self,
                'sync_include_failed', {});
        } else {
            Sympa::send_notify_to_listmaster($self,
                'sync_include_admin_failed', {});
        }
        return undef;
    }

    return 1;
}

#sub _update_inclusion_table;
# -> _update_inclusion_table() and/or _clean_inclusion_table() in
#    Sympa::Request::Handler::include class.

# The function sync_include('member') is to be called by the task_manager.
# This one is to be called from anywhere else. This function deletes the
# scheduled sync_include task. If this deletion happened in sync_include(),
# it would disturb the normal task_manager.pl functionning.
# 6.2.4: Returns 0 if synchronization is not needed.
# No longer used. Use sync_include('member', delay => ...);
#sub on_the_fly_sync_include;

# DEPRECATED. Use sync_include('owner') & sync_include('editor').
#sub sync_include_admin;

#sub _load_list_admin_from_config;
# -> No longer used.
#sub is_update_param;
# -> Never used.
#sub _inclusion_loop;
# -> Sympa::DataSouce::List::_inclusion_loop().

# Merged into Sympa::List::get_total().
#sub _load_total_db;

## Writes the user list to disk
# Depreceted.  Use Sympa::List::dump_users().
#sub _save_list_members_file;

## Does the real job : stores the message given as an argument into
## the digest of the list.
# Moved to Sympa::Spool::Digest::store().
#sub store_digest;

sub get_including_lists {
    my $self = shift;
    my $role = shift || 'member';

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT target_inclusion AS "target"
              FROM inclusion_table
              WHERE source_inclusion = ? AND role_inclusion = ?},
            $self->get_id, $role
        )
    ) {
        $log->syslog('err', 'Cannot get lists including %s', $self);
        return undef;
    }

    my @lists;
    while (my $r = $sth->fetchrow_hashref('NAME_lc')) {
        next unless $r and $r->{target};
        my $l = __PACKAGE__->new($r->{target});
        next unless $l;

        push @lists, $l;
    }
    $sth->finish;

    return [@lists];
}

sub get_lists {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $that = shift || '*';
    my %options = @_;

    # Set signal handler so that long call can be aborted by signal.
    my $signalled;
    my %sighandler = (HUP => $SIG{HUP}, INT => $SIG{INT}, TERM => $SIG{TERM});
    local $SIG{HUP} = sub { $sighandler{HUP}->(@_); $signalled = 1; }
        if ref $SIG{HUP} eq 'CODE';
    local $SIG{INT} = sub { $sighandler{INT}->(@_); $signalled = 1; }
        if ref $SIG{INT} eq 'CODE';
    local $SIG{TERM} = sub { $sighandler{TERM}->(@_); $signalled = 1; }
        if ref $SIG{TERM} eq 'CODE';

    my $sdm = Sympa::DatabaseManager->instance;

    my (@lists, @robot_ids, $family_name);

    if (ref $that and ref $that eq 'Sympa::Family') {
        @robot_ids   = ($that->{'domain'});
        $family_name = $that->{'name'};
    } elsif (!ref $that and $that and $that ne '*') {
        @robot_ids = ($that);
    } elsif (!$that or $that eq '*') {
        @robot_ids = get_robots();
    } else {
        die 'bug in logic.  Ask developer';
    }

    # Build query: Perl expression for files and SQL expression for
    # list_table.
    my $cond_perl   = undef;
    my $cond_sql    = undef;
    my $which_role  = undef;
    my $which_user  = undef;
    my @query       = @{$options{'filter'} || []};
    my @clause_perl = ();
    my @clause_sql  = ();

    ## get family lists
    if ($family_name) {
        push @clause_perl,
            sprintf(
            '$list->{"admin"}{"family_name"} and $list->{"admin"}{"family_name"} eq "%s"',
            quotemeta $family_name);
        push @clause_sql, sprintf(q{family_list LIKE '%s'}, $family_name);
    }

    while (1 < scalar @query) {
        my @expr_perl = ();
        my @expr_sql  = ();

        my $keys = shift @query;
        next unless defined $keys and $keys =~ /\S/;
        $keys =~ s/^(!?)\s*//;
        my $negate = $1;
        my @keys = split /[|]/, $keys;

        my $vals = shift @query;
        next unless defined $vals and length $vals;    # spaces are allowed
        my @vals = split /[|]/, $vals;

        foreach my $k (@keys) {
            next unless $k =~ /\S/;

            my $cmpl = undef;
            my ($prfx, $sffx) = ('', '');
            $prfx = $1 if $k =~ s/^(%)//;
            $sffx = $1 if $k =~ s/(%)$//;
            if ($prfx or $sffx) {
                unless ($sffx) {
                    $cmpl = '%s eq "%s"';
                } elsif ($prfx) {
                    $cmpl = 'index(%s, "%s") >= 0';
                } else {
                    $cmpl = 'index(%s, "%s") == 0';
                }
            } elsif ($k =~ s/\s*([<>])\s*$//) {
                $cmpl = '%s ' . $1 . ' %s';
            }

            ## query with single key and single value

            if ($k =~ /^(member|owner|editor)$/) {
                if (defined $which_role) {
                    $log->syslog('err', 'bug in logic. Ask developer: $k=%s',
                        $k);
                    return undef;
                }
                $which_role = $k;
                $which_user = $vals;
                next;
            }

            ## query with single value

            if ($k eq 'name' or $k eq 'subject') {
                my ($vl, $ve, $key_perl, $key_sql);
                if ($k eq 'name') {
                    $key_perl = '$list->{"name"}';
                    $key_sql  = 'name_list';
                    $vl       = lc $vals;
                } else {
                    $key_perl =
                        'Sympa::Tools::Text::foldcase($list->{"admin"}{"subject"})';
                    $key_sql = 'searchkey_list';
                    $vl      = Sympa::Tools::Text::foldcase($vals);
                }

                ## Perl expression
                $ve = $vl;
                $ve =~ s/([^ \w\x80-\xFF])/\\$1/g;
                push @expr_perl,
                    sprintf(($cmpl ? $cmpl : '%s eq "%s"'), $key_perl, $ve);

                ## SQL expression
                if ($sffx or $prfx) {
                    $ve = $sdm->quote($vl);
                    $ve =~ s/^["'](.*)['"]$/$1/;
                    $ve =~ s/([%_])/\\$1/g;
                    push @expr_sql,
                        sprintf("%s LIKE '%s'", $key_sql, "$prfx$ve$sffx");
                } else {
                    push @expr_sql,
                        sprintf('%s = %s', $key_sql, $sdm->quote($vl));
                }

                next;
            }

            foreach my $v (@vals) {
                ## Perl expressions
                if ($k eq 'creation' or $k eq 'update') {
                    push @expr_perl,
                        sprintf(
                        ($cmpl ? $cmpl : '%s == %s'),
                        sprintf('$list->{"admin"}{"%s"}->{"date_epoch"}', $k),
                        $v
                        );
#                 } elsif ($k eq 'web_archive') {
#                     push @expr_perl,
#                         sprintf('%s$list->is_web_archived',
#                         ($v+0 ? '' : '! '));
                } elsif ($k eq 'status') {
                    my $ve = lc $v;
                    $ve =~ s/([^ \w\x80-\xFF])/\\$1/g;
                    push @expr_perl,
                        sprintf('$list->{"admin"}{"status"} eq "%s"', $ve);
                } elsif ($k eq 'topics') {
                    my $ve = lc $v;
                    if ($ve eq 'others' or $ve eq 'topicsless') {
                        push @expr_perl,
                            '! scalar(grep { $_ ne "others" } @{$list->{"admin"}{"topics"} || []})';
                    } else {
                        $ve =~ s/([^ \w\x80-\xFF])/\\$1/g;
                        push @expr_perl,
                            sprintf(
                            'scalar(grep { $_ eq "%s" or index($_, "%s/") == 0 } @{$list->{"admin"}{"topics"} || []})',
                            $ve, $ve);
                    }
                } else {
                    $log->syslog('err', 'bug in logic. Ask developer: $k=%s',
                        $k);
                    return undef;
                }

                ## SQL expressions
                if ($k eq 'creation' or $k eq 'update') {
                    push @expr_sql,
                        sprintf('%s_epoch_list %s %s',
                        $k, ($cmpl ? $cmpl : '='), $v);
#                 } elsif ($k eq 'web_archive') {
#                     push @expr_sql,
#                         sprintf('web_archive_list = %d', ($v+0 ? 1 : 0));
                } elsif ($k eq 'status') {
                    push @expr_sql,
                        sprintf('%s_list = %s', $k, $sdm->quote($v));
                } elsif ($k eq 'topics') {
                    my $ve = lc $v;
                    if ($ve eq 'others' or $ve eq 'topicsless') {
                        push @expr_sql, "topics_list = ''";
                    } else {
                        $ve = $sdm->quote($ve);
                        $ve =~ s/^["'](.*)['"]$/$1/;
                        $ve =~ s/([%_])/\\$1/g;
                        push @expr_sql,
                            sprintf(
                            "topics_list LIKE '%%,%s,%%' OR topics_list LIKE '%%,%s/%%'",
                            $ve, $ve);
                    }
                }
            }
        }
        if (scalar @expr_perl) {
            push @clause_perl,
                ($negate ? '! ' : '') . '(' . join(' || ', @expr_perl) . ')';
            push @clause_sql,
                ($negate ? 'NOT ' : '') . '(' . join(' OR ', @expr_sql) . ')';
        }
    }

    if (scalar @clause_perl) {
        $cond_perl = join ' && ',  @clause_perl;
        $cond_sql  = join ' AND ', @clause_sql;
    } else {
        $cond_perl = undef;
        $cond_sql  = undef;
    }
    $log->syslog('debug3', 'filter %s; %s', $cond_perl, $cond_sql);

    ## Sort order
    my $order_perl;
    my $order_sql;
    my $keys      = $options{'order'} || [];
    my @keys_perl = ();
    my @keys_sql  = ();
    foreach my $key (@{$keys}) {
        my $desc = ($key =~ s/^\s*-\s*//i);

        if ($key eq 'creation' or $key eq 'update') {
            if ($desc) {
                push @keys_perl,
                    sprintf
                    '$b->{"admin"}{"%s"}->{"date_epoch"} <=> $a->{"admin"}{"%s"}->{"date_epoch"}',
                    $key,
                    $key;
            } else {
                push @keys_perl,
                    sprintf
                    '$a->{"admin"}{"%s"}->{"date_epoch"} <=> $b->{"admin"}{"%s"}->{"date_epoch"}',
                    $key,
                    $key;
            }
        } elsif ($key eq 'name') {
            if ($desc) {
                push @keys_perl, '$b->{"name"} cmp $a->{"name"}';
            } else {
                push @keys_perl, '$a->{"name"} cmp $b->{"name"}';
            }
        } elsif ($key eq 'total') {
            if ($desc) {
                push @keys_perl, '$b->get_total <=> $a->get_total';
            } else {
                push @keys_perl, '$a->get_total <=> $b->get_total';
            }
        } else {
            $log->syslog('err', 'bug in logic.  Ask developer: $key=%s',
                $key);
            return undef;
        }

        if ($key eq 'creation' or $key eq 'update') {
            push @keys_sql,
                sprintf '%s_epoch_list%s', $key, ($desc ? ' DESC' : '');
        } else {
            push @keys_sql, sprintf '%s_list%s', $key, ($desc ? ' DESC' : '');
        }
    }
    $order_perl = join(' or ', @keys_perl) || undef;
    push @keys_sql, 'name_list'
        unless scalar grep { $_ =~ /name_list/ } @keys_sql;
    $order_sql = join(', ', @keys_sql);
    $log->syslog('debug3', 'order %s; %s', $order_perl, $order_sql);

    ## limit number of result
    my $limit = $options{'limit'} || undef;
    my $count = 0;

    # Check signal at first.
    return undef if $signalled;

    foreach my $robot_id (@robot_ids) {
        if (!Sympa::Tools::Data::smart_eq($Conf::Conf{'db_list_cache'}, 'on')
            or $options{'reload_config'}) {
            # Files are used instead of list_table DB cache.
            my @requested_lists = ();

            # filter by role
            if (defined $which_role) {
                my %r = ();

                push @sth_stack, $sth;

                if ($which_role eq 'member') {
                    $sth = $sdm->do_prepared_query(
                        q{SELECT list_subscriber
                          FROM subscriber_table
                          WHERE robot_subscriber = ? AND user_subscriber = ?},
                        $robot_id, $which_user
                    );
                } else {
                    $sth = $sdm->do_prepared_query(
                        q{SELECT list_admin
                          FROM admin_table
                          WHERE robot_admin = ? AND user_admin = ? AND
                                role_admin = ?},
                        $robot_id, $which_user, $which_role
                    );
                }
                unless ($sth) {
                    $log->syslog(
                        'err',
                        'failed to get lists with user %s as %s from database: %s',
                        $which_user,
                        $which_role,
                        $EVAL_ERROR
                    );
                    $sth = pop @sth_stack;
                    return undef;
                }
                my @row;
                while (@row = $sth->fetchrow_array) {
                    my $listname = $row[0];
                    $r{$listname} = 1;
                }
                $sth->finish;

                $sth = pop @sth_stack;

                # none found
                next unless %r;    # foreach my $robot_id
                @requested_lists = keys %r;
            } else {
                # check existence of robot directory
                my $robot_dir = $Conf::Conf{'home'} . '/' . $robot_id;
                $robot_dir = $Conf::Conf{'home'}
                    if !-d $robot_dir and $robot_id eq $Conf::Conf{'domain'};
                next unless -d $robot_dir;

                unless (opendir(DIR, $robot_dir)) {
                    $log->syslog('err', 'Unable to open %s', $robot_dir);
                    return undef;
                }
                @requested_lists =
                    grep { !/^\.+$/ and -f "$robot_dir/$_/config" }
                    readdir DIR;
                closedir DIR;
            }

            my @l = ();
            foreach my $listname (sort @requested_lists) {
                return undef if $signalled;

                ## create object
                my $list = __PACKAGE__->new(
                    $listname,
                    $robot_id,
                    {   %options,
                        skip_name_check => 1,    #ToDo: implement it.
                    }
                );
                next unless defined $list;

                ## filter by condition
                if (defined $cond_perl) {
                    next unless eval $cond_perl;
                }

                push @l, $list;
                last if $limit and $limit <= ++$count;
            }

            ## sort
            if ($order_perl) {
                eval 'use sort "stable"';
                push @lists, sort { eval $order_perl } @l;
                eval 'use sort "defaults"';
            } else {
                push @lists, @l;
            }
        } else {
            # Use list_table DB cache.
            my @requested_lists;

            my $table;
            my $cond;
            if (!defined $which_role) {
                $table = 'list_table';
                $cond  = '';
            } elsif ($which_role eq 'member') {
                $table = 'list_table, subscriber_table';
                $cond  = sprintf q{robot_list = robot_subscriber AND
                  name_list = list_subscriber AND
                  user_subscriber = %s}, $sdm->quote($which_user);
            } else {
                $table = 'list_table, admin_table';
                $cond  = sprintf q{robot_list = robot_admin AND
                  name_list = list_admin AND
                  role_admin = %s AND
                  user_admin = %s}, $sdm->quote($which_role),
                    $sdm->quote($which_user);
            }

            push @sth_stack, $sth;

            $sth = $sdm->do_query(
                q{SELECT name_list AS name
                  FROM %s
                  WHERE %s
                  ORDER BY %s},
                $table,
                join(
                    ' AND ',
                    grep {$_} (
                        $cond_sql,                 $cond,
                        sprintf 'robot_list = %s', $sdm->quote($robot_id)
                    )
                ),
                $order_sql
            );
            unless ($sth) {
                $log->syslog('err', 'Failed to get lists from %s', $table);
                $sth = pop @sth_stack;
                return undef;
            }

            @requested_lists =
                map { ref $_ ? $_->[0] : $_ }
                @{$sth->fetchall_arrayref([0], ($limit || undef))};
            $sth->finish;

            $sth = pop @sth_stack;

            foreach my $listname (@requested_lists) {
                return undef if $signalled;

                my $list = __PACKAGE__->new(
                    $listname,
                    $robot_id,
                    {   %options,
                        skip_name_check => 1,    #ToDo: implement it.
                    }
                );
                next unless $list;

                push @lists, $list;
                last if $limit and $limit <= ++$count;
            }

        }
        last if $limit and $limit <= $count;
    }    # foreach my $robot_id

    return \@lists;
}

## List of robots hosted by Sympa
sub get_robots {

    my (@robots, $r);
    $log->syslog('debug2', '');

    unless (opendir(DIR, $Conf::Conf{'etc'})) {
        $log->syslog('err', 'Unable to open %s', $Conf::Conf{'etc'});
        return undef;
    }
    my $use_default_robot = 1;
    foreach $r (sort readdir(DIR)) {
        next
            unless (($r !~ /^\./o)
            && (-r "$Conf::Conf{'etc'}/$r/robot.conf"));
        push @robots, $r;
        undef $use_default_robot if ($r eq $Conf::Conf{'domain'});
    }
    closedir DIR;

    push @robots, $Conf::Conf{'domain'} if ($use_default_robot);
    return @robots;
}

sub get_which {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $email    = Sympa::Tools::Text::canonic_email(shift);
    my $robot_id = shift;
    my $role     = shift;

    unless ($role eq 'member' or $role eq 'owner' or $role eq 'editor') {
        $log->syslog('err',
            'Internal error, unknown or undefined parameter "%s"', $role);
        return undef;
    }

    my $all_lists =
        get_lists($robot_id,
        'filter' => [$role => $email, '! status' => 'closed|family_closed']);

    return @{$all_lists || []};
}

## return total of messages awaiting moderation
# DEPRECATED: Use Sympa::Spool::Moderation::size().
# sub get_mod_spool_size;

### moderation for shared

# DEPRECATED: Use {status} attribute of Sympa::WWW::SharedDocument instance.
#sub get_shared_status;

# DEPRECATED: Use Sympa::WWW::SharedDocument::get_moderated_descendants().
#sub get_shared_moderated;

# DEPRECATED: Subroutine of get_shared_moderated().
#sub sort_dir_to_get_mod;

## Get the type of a DB field
#OBSOLETED: No longer used. This is specific to MySQL: Use $sdm->get_fields()
# instead.
sub get_db_field_type {
    my ($table, $field) = @_;

    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm and $sth = $sdm->do_query('SHOW FIELDS FROM %s', $table)) {
        $log->syslog('err', 'Get the list of fields for table %s', $table);
        return undef;
    }

    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        next unless ($ref->{'Field'} eq $field);

        return $ref->{'Type'};
    }

    return undef;
}

# Moved to _lowercase_field() in sympa.pl.
#sub lowercase_field;

############ THIS IS RELATED TO NEW LOAD_ADMIN_FILE #############

## Sort function for writing config files
sub _by_order {
    (($Sympa::ListDef::pinfo{$a || ''}{'order'} || 0)
        <=> ($Sympa::ListDef::pinfo{$b || ''}{'order'} || 0))
        || (($a || '') cmp($b || ''));
}

## Apply defaults to parameters definition (%Sympa::ListDef::pinfo)
## DEPRECATED: use Sympa::Robot::list_params($robot).
##sub _apply_defaults {

## Save a parameter
sub _save_list_param {
    my ($robot_id, $key, $p, $defaults, $fd) = @_;

    ## Ignore default value
    return 1 if $defaults;
    return 1 unless (defined($p));

    my $pinfo = Sympa::Robot::list_params($robot_id);
    if (   defined($pinfo->{$key}{'scenario'})
        || defined($pinfo->{$key}{'task'})) {
        return 1 if ($p->{'name'} eq 'default');

        $fd->print(sprintf "%s %s\n", $key, $p->{'name'});
        $fd->print("\n");

    } elsif (ref($pinfo->{$key}{'file_format'}) eq 'HASH') {
        $fd->print(sprintf "%s\n", $key);
        foreach my $k (keys %{$p}) {

            if (defined($pinfo->{$key}{'file_format'}{$k}{'scenario'})) {
                ## Skip if empty value
                next
                    unless defined $p->{$k}{'name'}
                    and $p->{$k}{'name'} =~ /\S/;

                $fd->print(sprintf "%s %s\n", $k, $p->{$k}{'name'});

            } elsif (($pinfo->{$key}{'file_format'}{$k}{'occurrence'} =~ /n$/)
                && $pinfo->{$key}{'file_format'}{$k}{'split_char'}) {
                next unless $p->{$k} and @{$p->{$k}};

                $fd->print(
                    sprintf "%s %s\n",
                    $k,
                    join(
                        $pinfo->{$key}{'file_format'}{$k}{'split_char'},
                        @{$p->{$k}}
                    )
                );
            } else {
                ## Skip if empty value
                next unless defined $p->{$k} and $p->{$k} =~ /\S/;

                $fd->print(sprintf "%s %s\n", $k, $p->{$k});
            }
        }
        $fd->print("\n");

    } else {
        if (($pinfo->{$key}{'occurrence'} =~ /n$/)
            && $pinfo->{$key}{'split_char'}) {
            ### " avant de debugger do_edit_list qui crée des nouvelles
            ### entrées vides
            my $string = join($pinfo->{$key}{'split_char'}, @{$p});
            $string =~ s/\,\s*$//;

            $fd->print(sprintf "%s %s\n\n", $key, $string);
        } elsif ($key eq 'digest') {
            my $value = sprintf '%s %d:%d', join(',', @{$p->{'days'}}),
                $p->{'hour'}, $p->{'minute'};
            $fd->print(sprintf "%s %s\n\n", $key, $value);
        } else {
            $fd->print(sprintf "%s %s\n\n", $key, $p);
        }
    }

    return 1;
}

## Load a single line
sub _load_list_param {
    $log->syslog('debug3', '(%s, %s, %s, %s)', @_);
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    my $p     = shift;

    my $robot = $self->{'domain'};

    # Empty value.
    unless (defined $value and $value =~ /\S/) {
        return undef;    #FIXME
    }

    # For compatibility to <= 6.2.40: Special name "default" stands for
    # the default scenario.
    if ($p->{'scenario'} and $value eq 'default') {
        $value = $p->{'default'};
    }

    ## Search configuration file
    if (    ref $value
        and $value->{'conf'}
        and grep { $_->{'name'} and $_->{'name'} eq $value->{'conf'} }
        @Sympa::ConfDef::params) {
        my $param = $value->{'conf'};
        $value = Conf::get_robot_conf($robot, $param);
    }

    ## Synonyms
    if (defined $value and defined $p->{'synonym'}{$value}) {
        $value = $p->{'synonym'}{$value};
    }

    ## Scenario
    if ($p->{'scenario'}) {
        $value =~ y/,/_/;    # Compat. eg "add owner,notify"
        #FIXME: Check existence of scenario file.
        $value = {'name' => $value};
    } elsif ($p->{'task'}) {
        $value = {'name' => $value};
    }

    ## Do we need to split param if it is not already an array
    if (    exists $p->{'occurrence'}
        and $p->{'occurrence'} =~ /n$/
        and $p->{'split_char'}
        and defined $value
        and ref $value ne 'ARRAY') {
        $value =~ s/^\s*(.+)\s*$/$1/;
        return [split /\s*$p->{'split_char'}\s*/, $value];
    } else {
        return $value;
    }
}

BEGIN { eval 'use Crypt::OpenSSL::X509'; }

# Load the certificate file.
sub get_cert {
    $log->syslog('debug2', '(%s)', @_);
    my $self   = shift;
    my $format = shift;

    ## Default format is PEM (can be DER)
    $format ||= 'pem';

    # we only send the encryption certificate: this is what the user
    # needs to send mail to the list; if they ever get anything signed,
    # it will have the respective cert attached anyways.
    # (the problem is that netscape, opera and IE can't only
    # read the first cert in a file)
    my ($certs, $keys) = Sympa::Tools::SMIME::find_keys($self, 'encrypt');

    my @cert;
    if ($format eq 'pem') {
        unless (open(CERT, $certs)) {
            $log->syslog('err', 'Unable to open %s: %m', $certs);
            return undef;
        }

        my $state;
        while (<CERT>) {
            chomp;
            if ($state) {
                # convert to CRLF for windows clients
                push(@cert, "$_\r\n");
                if (/^-+END/) {
                    pop @cert;
                    last;
                }
            } elsif (/^-+BEGIN/) {
                $state = 1;
            }
        }
        close CERT;
    } elsif ($format eq 'der' and $Crypt::OpenSSL::X509::VERSION) {
        my $x509 = eval { Crypt::OpenSSL::X509->new_from_file($certs) };
        unless ($x509) {
            $log->syslog('err', 'Unable to open certificate %s: %m', $certs);
            return undef;
        }
        @cert = ($x509->as_string(Crypt::OpenSSL::X509::FORMAT_ASN1()));
    } else {
        $log->syslog('err', 'Unknown "%s" certificate format', $format);
        return undef;
    }

    return join '', @cert;
}

## Load a config file of a list
#FIXME: Would merge _load_include_admin_user_file() which mostly duplicates.
sub _load_list_config_file {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    my $robot = $self->{'domain'};

    my $pinfo       = Sympa::Robot::list_params($robot);
    my $config_file = $self->{'dir'} . '/config';

    my %admin;
    my (@paragraphs);

    ## Just in case...
    local $RS = "\n";

    ## Set defaults to 1
    foreach my $pname (keys %$pinfo) {
        $admin{'defaults'}{$pname} = 1
            unless ($pinfo->{$pname}{'internal'});
    }

    ## Lock file
    my $lock_fh = Sympa::LockedFile->new($config_file, 5, '<');
    unless ($lock_fh) {
        $log->syslog('err', 'Could not create new lock on %s', $config_file);
        return undef;
    }

    ## Split in paragraphs
    my $i = 0;
    while (<$lock_fh>) {
        if (/^\s*$/) {
            $i++ if $paragraphs[$i];
        } else {
            push @{$paragraphs[$i]}, $_;
        }
    }

    for my $index (0 .. $#paragraphs) {
        my @paragraph = @{$paragraphs[$index]};

        my $pname;

        ## Clean paragraph, keep comments
        for my $i (0 .. $#paragraph) {
            my $changed = undef;
            for my $j (0 .. $#paragraph) {
                if ($paragraph[$j] =~ /^\s*\#/) {
                    chomp($paragraph[$j]);
                    push @{$admin{'comment'}}, $paragraph[$j];
                    splice @paragraph, $j, 1;
                    $changed = 1;
                } elsif ($paragraph[$j] =~ /^\s*$/) {
                    splice @paragraph, $j, 1;
                    $changed = 1;
                }

                last if $changed;
            }

            last unless $changed;
        }

        ## Empty paragraph
        next unless ($#paragraph > -1);

        ## Look for first valid line
        unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
            $log->syslog('err', 'Bad paragraph "%s" in %s, ignore it',
                @paragraph, $config_file);
            next;
        }

        $pname = $1;

        # Parameter aliases (compatibility concerns).
        my $alias = $pinfo->{$pname}{'obsolete'};
        if ($alias and $pinfo->{$alias}) {
            $paragraph[0] =~ s/^\s*$pname/$alias/;
            $pname = $alias;
        }

        unless (defined $pinfo->{$pname}) {
            $log->syslog('err', 'Unknown parameter "%s" in %s, ignore it',
                $pname, $config_file);
            next;
        }

        ## Uniqueness
        if (defined $admin{$pname}) {
            unless (($pinfo->{$pname}{'occurrence'} eq '0-n')
                or ($pinfo->{$pname}{'occurrence'} eq '1-n')) {
                $log->syslog('err',
                    'Multiple occurrences of a unique parameter "%s" in %s',
                    $pname, $config_file);
            }
        }

        ## Line or Paragraph
        if (ref $pinfo->{$pname}{'file_format'} eq 'HASH') {
            ## This should be a paragraph
            unless ($#paragraph > 0) {
                $log->syslog(
                    'err',
                    'Expecting a paragraph for "%s" parameter in %s, ignore it',
                    $pname,
                    $config_file
                );
                next;
            }

            ## Skipping first line
            shift @paragraph;

            my %hash;
            for my $i (0 .. $#paragraph) {
                next if ($paragraph[$i] =~ /^\s*\#/);

                unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
                    $log->syslog('err', 'Bad line "%s" in %s',
                        $paragraph[$i], $config_file);
                }

                my $key = $1;

                # Subparameter aliases (compatibility concerns).
                # Note: subparameter alias was introduced by 6.2.15.
                my $alias = $pinfo->{$pname}{'format'}{$key}{'obsolete'};
                if ($alias and $pinfo->{$pname}{'format'}{$alias}) {
                    $paragraph[$i] =~ s/^\s*$key/$alias/;
                    $key = $alias;
                }

                unless (defined $pinfo->{$pname}{'file_format'}{$key}) {
                    $log->syslog('err',
                        'Unknown key "%s" in paragraph "%s" in %s',
                        $key, $pname, $config_file);
                    next;
                }

                unless ($paragraph[$i] =~
                    /^\s*$key(?:\s+($pinfo->{$pname}{'file_format'}{$key}{'file_format'}))?\s*$/i
                ) {
                    chomp($paragraph[$i]);
                    $log->syslog(
                        'err',
                        'Bad entry "%s" for key "%s", paragraph "%s" in file "%s"',
                        $paragraph[$i],
                        $key,
                        $pname,
                        $config_file
                    );
                    next;
                }

                $hash{$key} =
                    $self->_load_list_param($key, $1,
                    $pinfo->{$pname}{'file_format'}{$key});
            }

            ## Apply defaults & Check required keys
            my $missing_required_field;
            foreach my $k (keys %{$pinfo->{$pname}{'file_format'}}) {

                ## Default value
                unless (defined $hash{$k}) {
                    if (defined $pinfo->{$pname}{'file_format'}{$k}{'default'}
                    ) {
                        $hash{$k} = $self->_load_list_param(
                            $k,
                            $pinfo->{$pname}{'file_format'}{$k}{'default'},
                            $pinfo->{$pname}{'file_format'}{$k}
                        );
                    }
                }

                ## Required fields
                if ($pinfo->{$pname}{'file_format'}{$k}{'occurrence'} eq '1'
                    and not $pinfo->{$pname}{'file_format'}{$k}{'obsolete'}) {
                    unless (defined $hash{$k}) {
                        $log->syslog('info',
                            'Missing key "%s" in param "%s" in %s',
                            $k, $pname, $config_file);
                        $missing_required_field++;
                    }
                }
            }

            next if $missing_required_field;

            delete $admin{'defaults'}{$pname};

            ## Should we store it in an array
            if (($pinfo->{$pname}{'occurrence'} =~ /n$/)) {
                push @{$admin{$pname}}, \%hash;
            } else {
                $admin{$pname} = \%hash;
            }
        } else {
            ## This should be a single line
            unless ($#paragraph == 0) {
                $log->syslog('info',
                    'Expecting a single line for "%s" parameter in %s',
                    $pname, $config_file);
            }

            unless ($paragraph[0] =~
                /^\s*$pname(?:\s+($pinfo->{$pname}{'file_format'}))?\s*$/i) {
                chomp($paragraph[0]);
                $log->syslog('info', 'Bad entry "%s" in %s',
                    $paragraph[0], $config_file);
                next;
            }

            my $value = $self->_load_list_param($pname, $1, $pinfo->{$pname});

            delete $admin{'defaults'}{$pname};

            if (($pinfo->{$pname}{'occurrence'} =~ /n$/)
                && !(ref($value) =~ /^ARRAY/)) {
                push @{$admin{$pname}}, $value;
            } else {
                $admin{$pname} = $value;
            }
        }
    }

    ## Release the lock
    unless ($lock_fh->close) {
        $log->syslog('err', 'Could not remove the read lock on file %s',
            $config_file);
        return undef;
    }

    ## Apply defaults & check required parameters
    foreach my $p (keys %$pinfo) {

        ## Defaults
        unless (defined $admin{$p}) {

            ## Simple (versus structured) parameter case
            if (defined $pinfo->{$p}{'default'}) {
                $admin{$p} =
                    $self->_load_list_param($p, $pinfo->{$p}{'default'},
                    $pinfo->{$p});

                ## Sructured parameters case : the default values are defined
                ## at the next level
            } elsif ((ref $pinfo->{$p}{'format'} eq 'HASH')
                && ($pinfo->{$p}{'occurrence'} =~ /1$/)) {
                ## If the paragraph is not defined, try to apply defaults
                my $hash;

                foreach my $key (keys %{$pinfo->{$p}{'format'}}) {

                    ## Skip keys without default value.
                    unless (defined $pinfo->{$p}{'format'}{$key}{'default'}) {
                        next;
                    }

                    $hash->{$key} = $self->_load_list_param(
                        $key,
                        $pinfo->{$p}{'format'}{$key}{'default'},
                        $pinfo->{$p}{'format'}{$key}
                    );
                }

                $admin{$p} = $hash if (defined $hash);

            }

#	    $admin{'defaults'}{$p} = 1;
        }

        ## Required fields
        if (    $pinfo->{$p}{'occurrence'}
            and $pinfo->{$p}{'occurrence'} =~ /^1(-n)?$/
            and not $pinfo->{$p}{'obsolete'}) {
            unless (defined $admin{$p}) {
                $log->syslog('info', 'Missing parameter "%s" in %s',
                    $p, $config_file);
            }
        }
    }

    $self->_load_list_config_postprocess(\%admin);
    _load_include_admin_user_postprocess(\%admin);

    return \%admin;
}

# Proprocessing particular parameters.
sub _load_list_config_postprocess {
    my $self        = shift;
    my $config_hash = shift;

    ## "Original" parameters
    if (defined($config_hash->{'digest'})) {
        if ($config_hash->{'digest'} =~ /^(.+)\s+(\d+):(\d+)$/) {
            my $digest = {};
            $digest->{'hour'}   = $2;
            $digest->{'minute'} = $3;
            my $days = $1;
            $days =~ s/\s//g;
            @{$digest->{'days'}} = split /,/, $days;

            $config_hash->{'digest'} = $digest;
        }
    }

    # The 'host' parameter is ignored if the list is stored on a
    # virtual robot directory.
    # $config_hash->{'host'} = $self{'domain'} if ($self{'dir'} ne '.');

    if (defined($config_hash->{'custom_subject'})) {
        if ($config_hash->{'custom_subject'} =~ /^\s*\[\s*(\w+)\s*\]\s*$/) {
            $config_hash->{'custom_subject'} = $1;
        }
    }

    ## Format changed for reply_to parameter
    ## New reply_to_header parameter
    if ((   $config_hash->{'forced_reply_to'}
            && !$config_hash->{'defaults'}{'forced_reply_to'}
        )
        || ($config_hash->{'reply_to'}
            && !$config_hash->{'defaults'}{'reply_to'})
    ) {
        my ($value, $apply, $other_email);
        $value = $config_hash->{'forced_reply_to'}
            || $config_hash->{'reply_to'};
        $apply = 'forced' if ($config_hash->{'forced_reply_to'});
        if ($value =~ /\@/) {
            $other_email = $value;
            $value       = 'other_email';
        }

        $config_hash->{'reply_to_header'} = {
            'value'       => $value,
            'other_email' => $other_email,
            'apply'       => $apply
        };

        ## delete old entries
        $config_hash->{'reply_to'}        = undef;
        $config_hash->{'forced_reply_to'} = undef;
    }

    # lang
    # canonicalize language
    unless ($config_hash->{'lang'} =
        Sympa::Language::canonic_lang($config_hash->{'lang'})) {
        $config_hash->{'lang'} =
            Conf::get_robot_conf($self->{'domain'}, 'lang');
    }

    ############################################
    ## Below are constraints between parameters
    ############################################

    ## This default setting MUST BE THE LAST ONE PERFORMED
    #if ($config_hash->{'status'} ne 'open') {
    #    # requested and closed list are just list hidden using visibility
    #    # parameter and with send parameter set to closed.
    #    $config_hash->{'send'} =
    #        $self->_load_list_param('send', 'closed', $pinfo->{'send'});
    #    $config_hash->{'visibility'} =
    #        $self->_load_list_param('visibility', 'conceal',
    #            $pinfo->{'visibility'});
    #}

    ## reception of default_user_options must be one of reception of
    ## available_user_options. If none, warning and put reception of
    ## default_user_options in reception of available_user_options
    if (!grep (/^$config_hash->{'default_user_options'}{'reception'}$/,
            @{$config_hash->{'available_user_options'}{'reception'}})
    ) {
        push @{$config_hash->{'available_user_options'}{'reception'}},
            $config_hash->{'default_user_options'}{'reception'};
        $log->syslog(
            'info',
            'Reception is not compatible between default_user_options and available_user_options in configuration of %s',
            $self
        );
    }
}

# Proprocessing particular parameters specific to datasources.
sub _load_include_admin_user_postprocess {
    my $config_hash = shift;

    # The include_list was obsoleted by include_sympa_list on 6.2.16.
    #FIXME: Existing lists may be checked with looser rule.
    if ($config_hash->{'include_list'}) {
        my $listname_regex =
              Sympa::Regexps::listname() . '(?:\@'
            . Sympa::Regexps::host() . ')?';
        my $filter_regex = '(' . $listname_regex . ')\s+filter\s+(.+)';

        $config_hash->{'include_sympa_list'} ||= [];
        foreach my $incl (@{$config_hash->{'include_list'} || []}) {
            next unless defined $incl and $incl =~ /\S/;

            my ($listname, $filter);
            if ($incl =~ /\A$filter_regex/) {
                ($listname, $filter) = (lc $1, $2);
                undef $filter unless $filter =~ /\S/;
            } elsif ($incl =~ /\A$listname_regex\z/) {
                $listname = lc $incl;
            } else {
                $log->syslog(
                    'err',
                    'Malformed value "%s" in include_list parameter. Skipped',
                    $incl
                );
                next;
            }

            push @{$config_hash->{'include_sympa_list'}},
                {
                name     => sprintf('include_list %s', $incl),
                listname => $listname,
                filter   => $filter,
                };
        }
        delete $config_hash->{'include_list'};
        delete $config_hash->{'defaults'}{'include_list'}
            if $config_hash->{'defaults'};
    }
}

## Save a config file
sub _save_list_config_file {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    my ($config_file, $old_config_file) = @_;

    my $pinfo = Sympa::Robot::list_params($self->{'domain'});

    unless (rename $config_file, $old_config_file) {
        $log->syslog(
            'notice',     'Cannot rename %s to %s',
            $config_file, $old_config_file
        );
        return undef;
    }

    my $fh_config;
    unless (open $fh_config, '>', $config_file) {
        $log->syslog('info', 'Cannot open %s', $config_file);
        return undef;
    }
    my $config = '';
    my $fd     = IO::Scalar->new(\$config);

    foreach my $c (@{$self->{'admin'}{'comment'}}) {
        $fd->print(sprintf "%s\n", $c);
    }
    $fd->print("\n");

    foreach my $key (sort _by_order keys %{$self->{'admin'}}) {

        next if ($key =~ /^(comment|defaults)$/);
        next unless (defined $self->{'admin'}{$key});

        ## Multiple parameter (owner, custom_header,...)
        if ((ref($self->{'admin'}{$key}) eq 'ARRAY')
            && !$pinfo->{$key}{'split_char'}) {
            foreach my $elt (@{$self->{'admin'}{$key}}) {
                _save_list_param($self->{'domain'}, $key, $elt,
                    $self->{'admin'}{'defaults'}{$key}, $fd);
            }
        } else {
            _save_list_param(
                $self->{'domain'}, $key,
                $self->{'admin'}{$key},
                $self->{'admin'}{'defaults'}{$key}, $fd
            );
        }
    }
    print $fh_config $config;
    close $fh_config;

    return 1;
}

# Is a reception mode in the parameter reception of the available_user_options
# section?
sub is_available_reception_mode {
    my ($self, $mode) = @_;
    $mode =~ y/[A-Z]/[a-z]/;

    return undef unless ($self && $mode);

    my @available_mode =
        @{$self->{'admin'}{'available_user_options'}{'reception'}};

    foreach my $m (@available_mode) {
        if ($m eq $mode) {
            return $mode;
        }
    }

    return undef;
}

# List the parameter reception of the available_user_options section
# Note: Since Sympa 6.1.18, this returns an array under array context.
sub available_reception_mode {
    my $self = shift;
    return @{$self->{'admin'}{'available_user_options'}{'reception'} || []}
        if wantarray;
    return join(' ',
        @{$self->{'admin'}{'available_user_options'}{'reception'} || []});
}

##############################################################################
#                       FUNCTIONS FOR MESSAGE TOPICS
#                       #
##############################################################################
#
#

####################################################
# is_there_msg_topic
####################################################
#  Test if some msg_topic are defined
#
# IN : -$self (+): ref(List)
#
# OUT : 1 - some are defined | 0 - not defined
####################################################
sub is_there_msg_topic {
    my ($self) = shift;

    if (defined $self->{'admin'}{'msg_topic'}) {
        if (ref($self->{'admin'}{'msg_topic'}) eq "ARRAY") {
            if ($#{$self->{'admin'}{'msg_topic'}} >= 0) {
                return 1;
            }
        }
    }
    return 0;
}

####################################################
# is_available_msg_topic
####################################################
#  Checks for a topic if it is available in the list
# (look foreach list parameter msg_topic.name)
#
# IN : -$self (+): ref(List)
#      -$topic (+): string
# OUT : -$topic if it is available  | undef
####################################################
sub is_available_msg_topic {
    my ($self, $topic) = @_;

    my @available_msg_topic;
    foreach my $msg_topic (@{$self->{'admin'}{'msg_topic'}}) {
        return $topic
            if ($msg_topic->{'name'} eq $topic);
    }

    return undef;
}

####################################################
# get_available_msg_topic
####################################################
#  Return an array of available msg topics (msg_topic.name)
#
# IN : -$self (+): ref(List)
#
# OUT : -\@topics : ref(ARRAY)
####################################################
sub get_available_msg_topic {
    my ($self) = @_;

    my @topics;
    foreach my $msg_topic (@{$self->{'admin'}{'msg_topic'}}) {
        if ($msg_topic->{'name'}) {
            push @topics, $msg_topic->{'name'};
        }
    }

    return \@topics;
}

####################################################
# is_msg_topic_tagging_required
####################################################
# Checks for the list parameter msg_topic_tagging
# if it is set to 'required'
#
# IN : -$self (+): ref(List)
#
# OUT : 1 - the msg must must be tagged
#       | 0 - the msg can be no tagged
####################################################
sub is_msg_topic_tagging_required {
    my ($self) = @_;

    if ($self->{'admin'}{'msg_topic_tagging'} =~ /required/) {
        return 1;
    } else {
        return 0;
    }
}

# DEPRECATED.
# Use Sympa::Message::compute_topic() and Sympa::Spool::Topic::store() instead.
#sub automatic_tag;

# Moved to Sympa::Message::compute_topic().
#sub compute_topic;

# DEPRECATED.  Use Sympa::Spool::Topic::store() instead.
#sub tag_topic;

# DEPRECATED.  Use Sympa::Spool::Topic::load() instead.
#sub load_msg_topic_file;

# Moved to _notify_deleted_topic() in wwsympa.fcgi.
#sub modifying_msg_topic_for_list_members;

####################################################
# select_list_members_for_topic
####################################################
# Select users subscribed to a topic that is in
# the topic list incoming when reception mode is 'mail', 'notice', 'not_me',
# 'txt' or 'urlize', and the other
# subscribers (recpetion mode different from 'mail'), 'mail' and no topic
# subscription.
# Note: 'html' mode was deprecated as of 6.2.23b.2.
#
# IN : -$self(+) : ref(List)
#      -$string_topic(+) : string splitted by ','
#                          topic list
#      -$subscribers(+) : ref(ARRAY) - list of subscribers(emails)
#
# OUT : @selected_users
#
#
####################################################
sub select_list_members_for_topic {
    my ($self, $string_topic, $subscribers) = @_;
    $log->syslog('debug3', '(%s, %s)', $self->{'name'}, $string_topic);

    my @selected_users;
    my $msg_topics;

    if ($string_topic) {
        $msg_topics =
            Sympa::Tools::Data::get_array_from_splitted_string($string_topic);
    }

    foreach my $user (@$subscribers) {

        # user topic
        my $info_user = $self->get_list_member($user);

        if ($info_user->{'reception'} !~
            /^(mail|notice|not_me|txt|html|urlize)$/i) {
            push @selected_users, $user;
            next;
        }
        unless ($info_user->{'topics'}) {
            push @selected_users, $user;
            next;
        }
        my $user_topics = Sympa::Tools::Data::get_array_from_splitted_string(
            $info_user->{'topics'});

        if ($string_topic) {
            my $result =
                Sympa::Tools::Data::diff_on_arrays($msg_topics, $user_topics);
            if ($#{$result->{'intersection'}} >= 0) {
                push @selected_users, $user;
            }
        } else {
            my $result =
                Sympa::Tools::Data::diff_on_arrays(['other'], $user_topics);
            if ($#{$result->{'intersection'}} >= 0) {
                push @selected_users, $user;
            }
        }
    }
    return @selected_users;
}

#
#
#
### END - functions for message topics ###

# DEPRECATED.  Use Sympa::Spool::Auth::store().
#sub store_subscription_request;

# DEPRECATED.  Use Sympa::Spool::Auth::next().
#sub get_subscription_requests;

# DEPRECATED.  Use Sympa::Spool::Auth::size().
#sub get_subscription_request_count;

# DEPRECATED.  Use Sympa::Spool::Auth::remove().
#sub delete_subscription_request;

# OBSOLETED: Use Sympa::WWW::SharedDocument::get_size().
#sub get_shared_size;

# OBSOLETED: Use Sympa::Archive::get_size().
#sub get_arc_size;

# return the date epoch for next delivery planified for a list
# Note: As of 6.2a.41, returns undef if parameter is not set or invalid.
#       Previously it returned current time.
sub get_next_delivery_date {
    my $self = shift;

    my $dtime = $self->{'admin'}{'delivery_time'};
    return undef unless $dtime;
    my ($h, $m) = split /:/, $dtime, 2;
    return undef unless $h == 24 and $m == 0 or $h <= 23 and $m <= 60;

    my $date = time();
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        localtime($date);

    my $plannified_time = (($h * 60) + $m) * 60;    # plannified time in sec
    my $now_time =
        ((($hour * 60) + $min) * 60) + $sec;    # Now #sec since to day 00:00

    my $result = $date - $now_time + $plannified_time;
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        localtime($result);

    if ($now_time <= $plannified_time) {
        return ($date - $now_time + $plannified_time);
    } else {
        # plannified time is past so report to tomorrow
        return ($date - $now_time + $plannified_time + (24 * 3600));
    }
}

#sub search_datasource;
# -> No longer used.
#sub get_datasource_name;
# -> No longer used.
#sub add_source_id;
# -> No longer used.

## Remove a task in the tasks spool
# No longer used.
#sub remove_task;

# Deprecated. Use Sympa::Request::Handler::close_list handler.
#sub close_list;

## Remove the list
# Deprecated. Use Sympa::Request::Handler::close_list handler.
#sub purge;

## Remove list aliases
# Deprecated. Use Sympa::Aliases::del().
#sub remove_aliases;

# Moved: use Sympa::Spindle::ProcessTask::_remove_bouncers().
#sub remove_bouncers;

# Moved: Use Sympa::Spindle::ProcessTask::_notify_bouncers().
#sub notify_bouncers;

# DDEPRECATED: Use Sympa::WWW::SharedDocument::create().
#sub create_shared;

# Check if a list has data sources
# Old name: Sympa::List::has_include_data_sources(), without $role parameter.
sub has_data_sources {
    my $self = shift;
    my $role = shift;

    my @parameters;
    if (not $role or $role eq 'member') {
        push @parameters, @sources_providing_listmembers, 'member_include';
    }
    if (not $role or $role eq 'owner') {
        push @parameters, 'owner_include';
    }
    if (not $role or $role eq 'editor') {
        push @parameters, 'editor_include';
    }

    foreach my $type (@parameters) {
        my $resource = $self->{'admin'}{$type} || [];
        return 1 if ref $resource eq 'ARRAY' and @$resource;
    }

    return 0;
}

sub has_included_users {
    my $self = shift;
    my $role = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;
    if (not $role or $role eq 'member') {
        unless (
            $sdm and $sth = $sdm->do_prepared_query(
                q{SELECT COUNT(*)
                  FROM subscriber_table
                  WHERE list_subscriber = ? AND robot_subscriber = ? AND
                        inclusion_subscriber IS NOT NULL},
                $self->{'name'}, $self->{'domain'}
            )
        ) {
            return undef;
        }
        my ($count) = $sth->fetchrow_array;
        return 1 if $count;
    }
    if (not $role or $role ne 'member') {
        unless (
            $sdm and $sth = $sdm->do_prepared_query(
                q{SELECT COUNT(*)
                  FROM admin_table
                  WHERE list_admin = ? AND robot_admin = ? AND
                        inclusion_admin IS NOT NULL AND
                        (role_admin = ? OR role_admin = ?)},
                $self->{'name'}, $self->{'domain'},
                ($role || 'owner'), ($role || 'editor')
            )
        ) {
            return undef;
        }
        my ($count) = $sth->fetchrow_array;
        return 1 if $count;
    }

    return 0;
}

# move a message to a queue or distribute spool
#DEPRECATED: No longer used.
# Use Sympa::Spool::XXX::store() (and Sympa::Spool::XXX::remove()).
sub move_message {
    my ($self, $file, $queue) = @_;
    $log->syslog('debug2', '(%s, %s, %s)', $file, $self->{'name'}, $queue);

    my $dir = $queue || (Sympa::Constants::SPOOLDIR() . '/distribute');
    my $filename = $self->get_id . '.' . time . '.' . (int rand 999);

    unless (open OUT, ">$dir/T.$filename") {
        $log->syslog('err', 'Cannot create file %s', "$dir/T.$filename");
        return undef;
    }

    unless (open IN, $file) {
        $log->syslog('err', 'Cannot open file %s', $file);
        return undef;
    }

    print OUT <IN>;
    close IN;
    close OUT;
    unless (rename "$dir/T.$filename", "$dir/$filename") {
        $log->syslog(
            'err',              'Cannot rename file %s into %s',
            "$dir/T.$filename", "$dir/$filename"
        );
        return undef;
    }
    return 1;
}

# New in 6.2.13.
sub get_archive_dir {
    my $self = shift;

    my $arc_dir = Conf::get_robot_conf($self->{'domain'}, 'arc_path');
    die sprintf
        'Robot %s has no archives directory. Check arc_path parameter in this robot.conf and in sympa.conf',
        $self->{'domain'}
        unless $arc_dir;
    return $arc_dir . '/' . $self->get_id;
}

# Return the path to the list bounce directory, where bounces are stored.
sub get_bounce_dir {
    my $self = shift;

    my $root_dir = Conf::get_robot_conf($self->{'domain'}, 'bounce_path');
    return $root_dir . '/' . $self->get_id;
}

# New in 6.2.13.
sub get_digest_spool_dir {
    my $self = shift;

    my $spool_dir = $Conf::Conf{'queuedigest'};
    return $spool_dir . '/' . $self->get_id;
}

# OBSOLETED. Merged into Sympa::get_address().
sub get_list_address {
    goto &Sympa::get_address;    # "&" is required.
}

sub get_bounce_address {
    my $self = shift;
    my $who  = shift;
    my @opts = @_;

    my $escwho = $who;
    $escwho =~ s/\@/==a==/;

    return sprintf('%s+%s@%s',
        $Conf::Conf{'bounce_email_prefix'},
        join('==', $escwho, $self->{'name'}, @opts),
        $self->{'domain'});
}

sub get_id {
    my $self = shift;

    return '' unless $self->{'name'} and $self->{'domain'};
    return $self->{'name'} . '@' . $self->{'domain'};
}

# OBSOLETED: use get_id()
sub get_list_id { shift->get_id }

sub add_list_header {
    my $self    = shift;
    my $message = shift;
    my $field   = shift;
    my %options = @_;

    my $robot = $self->{'domain'};

    if ($field eq 'id') {
        $message->add_header('List-Id',
            sprintf('<%s.%s>', $self->{'name'}, $self->{'domain'}));
    } elsif ($field eq 'help') {
        $message->add_header(
            'List-Help',
            sprintf(
                '<%s>',
                Sympa::Tools::Text::mailtourl(
                    Sympa::get_address($self, 'sympa'),
                    query => {subject => 'help'}
                )
            )
        );
    } elsif ($field eq 'unsubscribe') {
        $message->add_header(
            'List-Unsubscribe',
            sprintf(
                '<%s>',
                Sympa::Tools::Text::mailtourl(
                    Sympa::get_address($self, 'sympa'),
                    query => {
                        subject => sprintf('unsubscribe %s', $self->{'name'})
                    }
                )
            )
        );
    } elsif ($field eq 'subscribe') {
        $message->add_header(
            'List-Subscribe',
            sprintf(
                '<%s>',
                Sympa::Tools::Text::mailtourl(
                    Sympa::get_address($self, 'sympa'),
                    query =>
                        {subject => sprintf('subscribe %s', $self->{'name'})}
                )
            )
        );
    } elsif ($field eq 'post') {
        $message->add_header(
            'List-Post',
            sprintf('<%s>',
                Sympa::Tools::Text::mailtourl(Sympa::get_address($self)))
        );
    } elsif ($field eq 'owner') {
        $message->add_header(
            'List-Owner',
            sprintf(
                '<%s>',
                Sympa::Tools::Text::mailtourl(
                    Sympa::get_address($self, 'owner')
                )
            )
        );
    } elsif ($field eq 'archive') {
        if (Conf::get_robot_conf($robot, 'wwsympa_url')
            and $self->is_web_archived()) {
            $message->add_header('List-Archive',
                sprintf('<%s>', Sympa::get_url($self, 'arc')));
        } else {
            return 0;
        }
    } elsif ($field eq 'archived_at') {
        if (Conf::get_robot_conf($robot, 'wwsympa_url')
            and $self->is_web_archived()) {
            # Use possiblly anonymized Message-Id: field instead of
            # {message_id} attribute.
            my $message_id = Sympa::Tools::Text::canonic_message_id(
                $message->get_header('Message-Id'));

            my $arc;
            if (defined $options{arc} and length $options{arc}) {
                $arc = $options{arc};
            } else {
                my @now = localtime time;
                $arc = sprintf '%04d-%02d', 1900 + $now[5], $now[4] + 1;
            }
            $message->add_header(
                'Archived-At',
                sprintf(
                    '<%s>',
                    Sympa::get_url(
                        $self, 'arcsearch_id',
                        paths => [$arc, $message_id]
                    )
                )
            );
        } else {
            return 0;
        }
    } else {
        die sprintf 'Unknown field "%s".  Ask developer', $field;
    }

    return 1;
}

# connect to stat_counter_table and extract data.
# DEPRECATED: No longer used.
#sub get_data;

sub _update_list_db {
    my ($self) = shift;
    my @admins;
    my $i;
    my $adm_txt;
    my $ed_txt;

    my $name = $self->{'name'};
    my $searchkey =
        Sympa::Tools::Text::foldcase($self->{'admin'}{'subject'} || '');
    my $status = $self->{'admin'}{'status'};
    my $robot  = $self->{'domain'};

    my $family = $self->{'admin'}{'family_name'};
    $family = undef unless defined $family and length $family;

    my $web_archive = $self->is_web_archived ? 1 : 0;
    my $topics = join ',',
        grep { defined $_ and length $_ and $_ ne 'others' }
        @{$self->{'admin'}{'topics'} || []};
    $topics = ",$topics," if length $topics;

    my $creation_epoch = $self->{'admin'}{'creation'}->{'date_epoch'};
    my $creation_email = $self->{'admin'}{'creation'}->{'email'};
    my $update_epoch   = $self->{'admin'}{'update'}->{'date_epoch'};
    my $update_email   = $self->{'admin'}{'update'}->{'email'};
# This may be added too.
#     my $latest_instantiation_epoch =
#         $self->{'admin'}{'latest_instantiation'}->{'date_epoch'};
#     my $latest_instantiation_email =
#         $self->{'admin'}{'latest_instantiation'}->{'email'};

# Not yet implemented.
#     eval { $config = Storable::nfreeze($self->{'admin'}); };
#     if ($@) {
#         $log->syslog('err',
#             'Failed to save the config to database. error: %s', $@);
#         return undef;
#     }

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    # update database cache
    # try INSERT then UPDATE
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{UPDATE list_table
              SET status_list = ?, name_list = ?, robot_list = ?,
                  family_list = ?,
                  creation_epoch_list = ?, creation_email_list = ?,
                  update_epoch_list = ?, update_email_list = ?,
                  searchkey_list = ?, web_archive_list = ?, topics_list = ?
              WHERE robot_list = ? AND name_list = ?},
            $status, $name, $robot,
            $family,
            $creation_epoch, $creation_email,
            $update_epoch,   $update_email,
            $searchkey, $web_archive, $topics,
            $robot,     $name
        )
        and $sth->rows
        or $sth = $sdm->do_prepared_query(
            q{INSERT INTO list_table
              (status_list, name_list, robot_list, family_list,
               creation_epoch_list, creation_email_list,
               update_epoch_list, update_email_list,
               searchkey_list, web_archive_list, topics_list)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)},
            $status,         $name, $robot, $family,
            $creation_epoch, $creation_email,
            $update_epoch,   $update_email,
            $searchkey, $web_archive, $topics
        )
        and $sth->rows
    ) {
        $log->syslog('err', 'Unable to update list %s in database', $self);
        $sth = pop @sth_stack;
        return undef;
    }

    # If inclusion settings do no longer exist, inclusion_table won't be
    # sync'ed anymore.  Rows left behind should be removed.
    foreach my $role (qw(member owner editor)) {
        unless ($self->has_data_sources($role)) {
            $sdm and $sdm->do_prepared_query(
                q{DELETE FROM inclusion_table
                  WHERE target_inclusion = ? AND role_inclusion = ?},
                $self->get_id, $role
            );
        }
    }

    $sth = pop @sth_stack;

    return 1;
}

sub _flush_list_db {
    my $listname = shift;

    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;
    unless ($listname) {
        # Do DELETE because SQLite does not have TRUNCATE TABLE.
        $sth = $sdm->do_prepared_query('DELETE FROM list_table');
    } else {
        $sth = $sdm->do_prepared_query(
            q{DELETE FROM list_table
              WHERE name_list = ?}, $listname
        );
    }

    unless ($sth) {
        $log->syslog('err', 'Unable to flush lists table');
        return undef;
    }
}

# Moved to Sympa::ListOpt::get_title().
#sub get_option_title;

# Return a hash from the edit_list_conf file.
# Old name: tools::load_edit_list_conf().
sub _load_edit_list_conf {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    my $robot = $self->{'domain'};

    my $pinfo = {
        %{Sympa::Robot::list_params($self->{'domain'})},
        %Sympa::ListDef::user_info
    };

    my $file;
    my $conf;

    return undef
        unless $file = Sympa::search_fullpath($self, 'edit_list.conf');

    my $fh;
    unless (open $fh, '<', $file) {
        $log->syslog('info', 'Unable to open config file %s', $file);
        return undef;
    }

    my $error_in_conf;
    my $role_re =
        qr'(?:listmaster|privileged_owner|owner|editor|subscriber|default)'i;
    my $priv_re = qr'(?:read|write|hidden)'i;
    my $line_re =
        qr/\A\s*(\S+)\s+($role_re(?:\s*,\s*$role_re)*)\s+($priv_re)\s*\z/i;
    foreach my $line (<$fh>) {
        next unless $line =~ /\S/;
        next if $line =~ /\A\s*#/;
        chomp $line;

        if ($line =~ /$line_re/) {
            my ($param, $role, $priv) = ($1, $2, $3);

            # Resolve alias.
            my $key;
            ($param, $key) = split /[.]/, $param, 2;
            if ($pinfo->{$param}) {
                my $alias = $pinfo->{$param}{obsolete};
                if ($alias and $pinfo->{$alias}) {
                    $param = $alias;
                }
                if (    $key
                    and ref $pinfo->{$param}{'format'} eq 'HASH'
                    and $pinfo->{$param}{'format'}{$key}) {
                    my $alias = $pinfo->{$param}{'format'}{$key}{obsolete};
                    if ($alias and $pinfo->{$param}{'format'}{$alias}) {
                        $key = $alias;
                    }
                }
            }
            $param = $param . '.' . $key if $key;

            my @roles = split /\s*,\s*/, $role;
            foreach my $r (@roles) {
                $r =~ s/^\s*(\S+)\s*$/$1/;
                if ($r eq 'default') {
                    $error_in_conf = 1;
                    $log->syslog('notice', '"default" is no more recognised');
                    foreach my $set (qw(owner privileged_owner listmaster)) {
                        $conf->{$param}{$set} = $priv;
                    }
                    next;
                }
                $conf->{$param}{$r} = $priv;
            }
        } else {
            $log->syslog('info', 'Unknown parameter in %s (Ignored): %s',
                $file, $line);
            next;
        }
    }

    if ($error_in_conf) {
        Sympa::send_notify_to_listmaster($robot, 'edit_list_error', [$file]);
    }

    close $fh;
    return $conf;
}

###### END of the List package ######

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::List - Mailing list

=head1 DESCRIPTION

L<Sympa::List> represents the mailing list on Sympa.

=head2 Methods

=over

=item new( $name, [ $domain [ {options...} ] ] )

I<Constructor>.
Creates a new object which will be used for a list and
eventually loads the list if a name is given. Returns
a List object.

Parameters

FIXME @todo doc

=item add_list_admin ( ROLE, USERS, ... )

Adds a new admin user to the list. May overwrite existing
entries.

=item add_list_header ( $message, $field_type )

FIXME @todo doc

=item add_list_member ( USER, HASHPTR )

Adds a new user to the list. May overwrite existing
entries.

=item available_reception_mode ( )

I<Instance method>.
FIXME @todo doc

Note: Since Sympa 6.1.18, this returns an array under array context.

=item delete_list_admin ( ROLE, ARRAY )

Delete the indicated admin user with the predefined role from the list.
ROLE may be C<'owner'> or C<'editor'>.

=item delete_list_member ( ARRAY )

Delete the indicated users from the list.

=item delete_list_member_picture ( $email )

Deletes a member's picture file.

=item destroy_multiton ( )
I<Instance method>.
Destroy multiton instance. FIXME

=item dump_users ( ROLE )

Dump user information in user store into file C<I<$role>.dump> under
list directory. ROLE may be C<'member'>, C<'owner'> or C<'editor'>.

=item find_picture_filenames ( $email )

Returns the type of a pictures according to the user.

=item find_picture_paths ( )

I<Instance method>.
FIXME @todo doc

=item find_picture_url ( $email )

Find pictures URL

=item get_admins ( $role, [ filter =E<gt> \@filters ] )

I<Instance method>.
Gets users of the list with one of following roles.

=over

=item C<actual_editor>

Editors belonging to the list.
If there are no such users, owners of the list.

=item C<editor>

Editors belonging to the list.

=item C<owner>

Owners of the list.

=item C<privileged_owner>

Owners whose C<profile> attribute is C<privileged>.

=item C<receptive_editor>

Editors belonging to the list and whose reception mode is C<mail>.
If there are no such users, owners whose reception mode is C<mail>.

=item C<receptive_owner>

Owners whose reception mode is C<mail>.

=back

Optional filter may be:

=over

=item [email =E<gt> $email]

Limit result to the user with their e-mail $email.

=back

Returns:

In array context, returns (possiblly empty or single-item) array of users.
In scalar context, returns reference to it.
In case of database error, returns empty array or undefined value.

=item get_admins_email ( $role )

I<Instance method>.
Gets an array of emails of list admins with role
C<receptive_editor>, C<actual_editor>, C<receptive_owner> or C<owner>.

=item get_archive_dir ( )

I<Instance method>.
FIXME @todo doc

=item get_available_msg_topic ( )

I<Instance method>.
FIXME @todo doc

=item get_bounce_address ( WHO, [ OPTS, ... ] )

Return the VERP address of the list for the user WHO.

FIXME: VERP addresses have the name of originating robot, not mail host.

=item get_bounce_dir ( )

I<Instance method>.
FIXME @todo doc

=item get_cert ( )

I<Instance method>.
FIXME @todo doc

=item get_config_changes ( )

I<Instance method>.
FIXME @todo doc

=item get_cookie ()

Returns the cookie for a list, if available.

=item get_current_admins ( ... )

I<Instance method>.
FIXME @todo doc

=item get_default_user_options ()

Returns a default option of the list for subscription.

=item get_first_list_member ()

Returns a hash to the first user on the list.

=item get_id ( )

Return the list ID, different from the list address (uses the robot name)

=item get_including_lists ( $role )

I<Instance method>.
List of lists including specified list and hosted by a whole site.

Parameter:

=over

=item $role

Role of included users.
C<'member'>, C<'owner'> or C<'editor'>.

=back

Returns:

Arrayref of <Sympa::List> instances.
Return C<undef> on failure.

=item get_list_member ( USER )

Returns a subscriber of the list.

=item get_max_size ()

Returns the maximum allowed size for a message.

=item get_members ( $role, [ offset => $offset ], [ order => $order ],
[ limit => $limit ])

I<Instance method>.
Gets users of the list with one of following roles.

=over

=item C<member>

Members of the list, either subscribed or included.

=item C<unconcealed_member>

Members whose C<visibility> property is not C<conceal>.

=back

Optional parameters:

=over

=item limit => $limit

=item offset => $offset

=item order => $order

TBD.

=back

Returns:

In array context, returns (possiblly empty or single-item) array of users.
In scalar context, returns reference to it.
In case of database error, returns empty array or undefined value.

=item get_msg_count ( )

I<Instance method>.
Returns the number of messages sent to the list.
FIXME

=item get_next_bouncing_list_member ( )

I<Instance method>.
Loop for all subsequent bouncing users.
FIXME

=item get_next_delivery_date ( )

I<Instance method>.
Returns the date epoch for next delivery planned for a list.

Note: As of 6.2a.41, returns C<undef> if parameter is not set or invalid.
Previously it returned current time.

=item get_next_list_member ()

Returns a hash to the next users, until we reach the end of
the list.

=item get_param_value ( $param, [ $as_arrayref ] )

I<instance method>.
Returns the list parameter value.
the parameter is simple (I<name>) or composed (I<name>C<.>I<minor>)
the value is a scalar or a ref on an array of scalar
(for parameter digest : only for days).

=item get_picture_path ( )

I<Instance method>.
FIXME

=item get_recipients_per_mode ( )

I<Instance method>.
FIXME @todo doc

=item get_reply_to ()

Returns an array with the Reply-To values.

=item get_resembling_members ( $role, $searchkey )

I<instance method>.
TBD.

=item get_stats ( )

Returns array of the statistics.

=item get_total ( [ 'nocache' ] )

Returns the number of subscribers to the list.

=item get_total_bouncing ( )

I<Instance method>.
Gets total number of bouncing subscribers.

=item has_data_sources ( )

I<Instance method>.
Checks if a list has data sources.

=item has_included_users ( $role )

I<Instance method>.
FIXME @todo doc

=item insert_delete_exclusion ( $email, C<"insert">|C<"delete"> )

I<Instance method>.
Update the exclusion table.
FIXME @todo doc

=item is_admin ( $role, $user )

I<Instance method>.
Returns true if $user has $role
(C<privileged_owner>, C<owner>, C<actual_editor> or C<editor>) on the list.

=item is_archived ()

Returns true is the list is configured to keep archives of
its messages.

=item is_archiving_enabled ( )

Returns true is the list is configured to keep archives of
its messages, i.e. process_archive parameter is set to "on".

=item is_available_msg_topic ( $topic )

I<Instance method>.
Checks for a topic if it is available in the list
(look for each list parameter C<msg_topic.name>).

=item is_available_reception_mode ( $mode )

I<Instance method>.
Is a reception mode in the parameter reception of the available_user_options
section?

=item is_digest ( )

I<Instance method>.
Does the list support digest mode?

=item is_included ( )

Returns true value if the list is included in another list(s).

=item is_list_member ( USER )

Returns true if the indicated user is member of the list.

=item is_member_excluded ( $email )

I<Instance method>.
FIXME @todo doc

=item is_moderated ()

Returns true if the list is moderated.
FIXME this may not be useful.

=item is_msg_topic_tagging_required ( )

I<Instance method>.
Checks for the list parameter msg_topic_tagging
if it is set to 'required'.

=item is_there_msg_topic ( )

I<Instance method>.
Tests if some msg_topic are defined.

=item is_web_archived ( )

I<Instance method>.
Is the list web archived?

FIXME: Broken. Use scenario or is_archiving_enabled().

=item load ( )

Loads the indicated list into the object.

=item load_data_sources_list ( $robot )

I<Instance method>.
Loads all data sources.
FIXME: Used only in wwsympa.fcgi.

=item may_edit ( $param, $who, [ options, ... ] )

I<Instance method>.
May the indicated user edit the indicated list parameter or not?
FIXME @todo doc

=item parse_list_member_bounce ( $user )

I<Instance method>.
FIXME @todo doc

=item restore_suspended_subscription ( $email )

I<Instance method>.
FIXME @todo doc

=item restore_users ( ROLE )

Import user information into user store from file C<I<$role>.dump> under
list directory. ROLE may be C<'member'>, C<'owner'> or C<'editor'>.

=item save_config ( LIST )

Saves the indicated list object to the disk files.

=item search_list_among_robots ( $listname )

I<Instance method>.
FIXME @todo doc

=item select_list_members_for_topic ( $topic, \@emails )

I<Instance method>.
FIXME @todo doc

=item send_notify_to_owner ( $operation, $params )

I<Instance method>.
FIXME @todo doc

=item send_probe_to_user ( $type, $who )

I<Instance method>.
FIXME @todo doc

=item set_status_error_config ( $msg, parameters, ... )

I<Instance method>.
FIXME @todo doc

=item suspend_subscription ( $email, $list, $data, $robot )

I<Function>.
FIXME This should be a instance method.
FIXME @todo doc

=item sync_include ( $role, options... )

I<Instance method>.
FIXME would be obsoleted.
FIXME @todo doc

=item update_config_changes ( )

I<Instance method>.
FIXME @todo doc

=item update_list_admin ( USER, ROLE, HASHPTR )

Sets the new values given in the hash for the admin user.

=item update_list_member ( $email, key =E<gt> value, ... )

I<Instance method>.
Sets the new values given in the pairs for the user.

=item update_stats ( count, [ sent, bytes, sent_by_bytes ] )

Updates the stats, argument is number of bytes, returns list fo the updated
values.  Returns zeroes if failed.

=back

=head2 Functions

=over

=item get_lists ( [ $that, [ options, ... ] ] )

I<Function>.
List of lists hosted by a family, a robot or whole site.

=over 4

=item $that

Robot, Sympa::Family object or site (default).

=item options, ...

Hash including options passed to Sympa::List->new() (see load()) and any of
following pairs:

=over 4

=item C<'filter' =E<gt> [ KEYS =E<gt> VALS, ... ]>

Filter with list profiles.  When any of items specified by KEYS
(separated by C<"|">) have any of values specified by VALS,
condition by that pair is satisfied.
KEYS prefixed by C<"!"> mean negated condition.
Only lists satisfying all conditions of query are returned.
Currently available keys and values are:

=over 4

=item 'creation' => TIME

=item 'creation<' => TIME

=item 'creation>' => TIME

Creation date is equal to, earlier than or later than the date (UNIX time).

=item 'member' => EMAIL

=item 'owner' => EMAIL

=item 'editor' => EMAIL

Specified user is a subscriber, owner or editor of the list.

=item 'name' => STRING

=item 'name%' => STRING

=item '%name%' => STRING

Exact, prefixed or substring match against list name,
case-insensitive.

=item 'status' => "STATUS|..."

Status of list.  One of 'open', 'closed', 'pending',
'error_config' and 'family_closed'.

=item 'subject' => STRING

=item 'subject%' => STRING

=item '%subject%' => STRING

Exact, prefixed or substring match against list subject,
case-insensitive (case folding is Unicode-aware).

=item 'topics' => "TOPIC|..."

Exact match against any of list topics.
'others' or 'topicsless' means no topics.

=item 'update' => TIME

=item 'update<' => TIME

=item 'update>' => TIME

Date of last update is equal to, earlier than or later than the date (UNIX time).

=begin comment

=item 'web_archive' => ( 1 | 0 )

Whether Web archive of the list is available.  1 or 0.

=end comment

=back

=item C<'limit' =E<gt> NUMBER >

Limit the number of results.
C<0> means no limit (default).
Note that this option may be applied prior to C<'order'> option.

=item C<'order' =E<gt> [ KEY, ... ]>

Subordinate sort key(s).  The results are sorted primarily by robot names
then by other key(s).  Keys prefixed by C<"-"> mean descendent ordering.
Available keys are:

=over 4

=item C<'creation'>

Creation date.

=item C<'name'>

List name, case-insensitive.  It is the default.

=item C<'total'>

Estimated number of subscribers.

=item C<'update'>

Date of last update.

=back

=back

=begin comment 

##=item REQUESTED_LISTS
##
##Arrayref to name of requested lists, if any.

=end comment

=back

Returns a ref to an array of List objects.

=item get_robots ( )

I<Function>.
List of robots hosted by Sympa.

=item get_which ( EMAIL, ROBOT, ROLE )

I<Function>.
Get a list of lists where EMAIL assumes this ROLE (owner, editor or member) of
function to any list in ROBOT.

=back

=head2 Obsoleted methods

=over

=item add_admin_user ( USER, ROLE, HASHPTR )

DEPRECATED.
Use add_list_admin().

=item am_i ( ROLE, USER )

DEPRECATED. Use is_admin().

=item archive_exist ( FILE )

DEPRECATED.
Returns true if the indicated file exists.

=item archive_ls ()

DEPRECATED.
Returns the list of available files, if any.

=item archive_msg ( MSG )

DEPRECATED.
Archives the Mail::Internet message given as argument.

=item archive_send ( WHO, FILE )

DEPRECATED.
Send the indicated archive file to the user, if it exists.

=item get_db_field_type ( ... )

I<Instance method>.
Obsoleted.

=item get_first_list_admin ( ROLE )

OBSOLETED.
Use get_admins().

=item get_global_user ( USER )

DEPRECATED.
Returns a hash with the information regarding the indicated
user.

=item get_latest_distribution_date ( )

I<Instance method>.
Gets last date of distribution message .

=item get_list_address ( [ TYPE ] )

OBSOLETED.
Use L<Sympa/"get_address">.

Return the list email address of type TYPE: posting address (default),
"owner", "editor" or (non-VERP) "return_path".

=item get_list_admin ( ROLE, USER)

Return an admin user of the list with predefined role

OBSOLETED.
Use get_admins().

=item get_list_id ( )

OBSOLETED.
Use get_id().

=item get_next_list_admin ()

OBSOLETED.
Use get_admins().

=item get_state ( FLAG )

Deprecated.
Returns the value for a flag : sig or sub.

=item may_do ( ACTION, USER )

B<Note>:
This method was obsoleted.

Chcks is USER may do the ACTION for the list. ACTION can be
one of following : send, review, index, getm add, del,
reconfirm, purge.

=item move_message ( $file, $queue )

DEPRECATED.
No longer used.

=item print_info ( FDNAME )

DEPRECATED.
Print the list information to the given file descriptor, or the
currently selected descriptor.

=item savestats ()

B<Deprecated> on 6.2.23b.

Saves updates the statistics file on disk.

=item send_confirm_to_editor ( $message, $method )

This method was DEPRECATED.

Send a L<Sympa::Message> object to the editor (for approval).

Sends a message to the list editor to ask them for moderation
(in moderation context : editor or editorkey). The message
to moderate is set in moderation spool with name containing
a key (reference send to editor for moderation).
In context of msg_topic defined the editor must tag it
for the moderation (on Web interface).

Parameters:

=over

=item $message

Sympa::Message instance - the message to moderate.

=item $method

'md5' - for "editorkey", 'smtp' - for "editor".

=back

Returns:

The moderation key for naming message waiting for moderation in moderation spool, or C<undef>.

=item send_confirm_to_sender ( $message )

This method was DEPRECATED.

Sends an authentication request for a sent message to distribute.
The message for distribution is copied in the auth
spool in order to wait for confirmation by its sender.
This message is named with a key.
In context of msg_topic defined, the sender must tag it
for the confirmation

Parameter:

=over

=item $message

L<Sympa::Message> instance.

=back

Returns:

The key for naming message waiting for confirmation (or tagging) in auth spool, or C<undef>.

=back

=head2 Attributes

FIXME @todo doc

=head1 SEE ALSO

L<Sympa>.

=head1 HISTORY

L<List> module was renamed to L<Sympa::List> module on Sympa 6.2.

=cut
