# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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
use File::Path qw();
use HTTP::Request;
use IO::Scalar;
use LWP::UserAgent;
use POSIX qw();
use Storable qw();

use Sympa;
use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Database;
use Sympa::DatabaseDescription;
use Sympa::DatabaseManager;
use Sympa::Datasource;
use Sympa::Family;
use Sympa::Fetch;
use Sympa::Language;
use Sympa::ListDef;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Process;
use Sympa::Regexps;
use Sympa::Robot;
use Sympa::Scenario;
use Sympa::Spindle::ProcessTemplate;
use Sympa::Spool::Auth;
use Sympa::Task;
use Sympa::Template;
use Sympa::Ticket;
use Sympa::Tools::Data;
use Sympa::Tools::File;
use Sympa::Tools::Password;
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

#XXX include_admin
my @more_data_sources = qw/
    editor_include
    owner_include
    member_include
    /;

# All non-pluggable sources are in the admin user file
# NO LONGER USED.
my %config_in_admin_user_file = map +($_ => 1),
    @sources_providing_listmembers;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

=encoding utf-8

#=head1 NAME
#
#List - Mailing list

=head1 CONSTRUCTOR

=over

=item new( [PHRASE] )

 Sympa::List->new();

Creates a new object which will be used for a list and
eventually loads the list if a name is given. Returns
a List object.

=back

=head1 METHODS

=over 4

=item load ( LIST )

Loads the indicated list into the object.

=item save ( LIST )

Saves the indicated list object to the disk files.

=item savestats ()

Saves updates the statistics file on disk.

=item update_stats( BYTES )

Updates the stats, argument is number of bytes, returns the next
sequence number. Does nothing if no stats.

This method was DEPRECATED.

=item delete_list_member ( ARRAY )

Delete the indicated users from the list.

=item delete_list_admin ( ROLE, ARRAY )

Delete the indicated admin user with the predefined role from the list.

=item get_cookie ()

Returns the cookie for a list, if available.

=item get_max_size ()

Returns the maximum allowed size for a message.

=item get_reply_to ()

Returns an array with the Reply-To values.

=item get_default_user_options ()

Returns a default option of the list for subscription.

=item get_total ()

Returns the number of subscribers to the list.

=item get_global_user ( USER )

Returns a hash with the information regarding the indicated
user.

=item get_list_member ( USER )

Returns a subscriber of the list.

=item get_list_admin ( ROLE, USER)

Return an admin user of the list with predefined role

OBSOLETED.
Use get_admins().

=item get_first_list_member ()

Returns a hash to the first user on the list.

=item get_first_list_admin ( ROLE )

OBSOLETED.
Use get_admins().

=item get_next_list_member ()

Returns a hash to the next users, until we reach the end of
the list.

=item get_next_list_admin ()

OBSOLETED.
Use get_admins().

=item update_list_member ( $email, key =E<gt> value, ... )

I<Instance method>.
Sets the new values given in the pairs for the user.

=item update_list_admin ( USER, ROLE, HASHPTR )

Sets the new values given in the hash for the admin user.

=item add_list_member ( USER, HASHPTR )

Adds a new user to the list. May overwrite existing
entries.

=item add_admin_user ( USER, ROLE, HASHPTR )

Adds a new admin user to the list. May overwrite existing
entries.

=item is_list_member ( USER )

Returns true if the indicated user is member of the list.

=item am_i ( ROLE, USER )

DEPRECATED. Use is_admin().

=item get_state ( FLAG )

Returns the value for a flag : sig or sub.

=item may_do ( ACTION, USER )

B<Note>:
This method was obsoleted.

Chcks is USER may do the ACTION for the list. ACTION can be
one of following : send, review, index, getm add, del,
reconfirm, purge.

=item is_moderated ()

Returns true if the list is moderated.

=item archive_exist ( FILE )

DEPRECATED.
Returns true if the indicated file exists.

=item archive_send ( WHO, FILE )

DEPRECATED.
Send the indicated archive file to the user, if it exists.

=item archive_ls ()

DEPRECATED.
Returns the list of available files, if any.

=item archive_msg ( MSG )

DEPRECATED.
Archives the Mail::Internet message given as argument.

=item is_archived ()

Returns true is the list is configured to keep archives of
its messages.

=item is_archiving_enabled ( )

Returns true is the list is configured to keep archives of
its messages, i.e. process_archive parameter is set to "on".

=item is_included ( )

Returns true value if the list is included in another list(s).

=item get_stats ( OPTION )

Returns either a formatted printable strings or an array whith
the statistics. OPTION can be 'text' or 'array'.

=item print_info ( FDNAME )

Print the list information to the given file descriptor, or the
currently selected descriptor.

=back

=cut

## Database and SQL statement handlers
my ($sth, @sth_stack);

my %list_cache;

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
my %list_of_lists  = ();
my %list_of_robots = ();
my %edit_list_conf = ();

## Creates an object.
sub new {
    my ($pkg, $name, $robot, $options) = @_;
    my $list = {};
    $log->syslog('debug2', '(%s, %s, %s)', $name, $robot,
        join('/', keys %$options));

    $name = lc($name);
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

    ## Config file was loaded or reloaded
    my $pertinent_ttl = $list->{'admin'}{'distribution_ttl'}
        || $list->{'admin'}{'ttl'};
    if ($status
        && ((     !$options->{'skip_sync_admin'}
                && $list->{'last_sync'} < time - $pertinent_ttl
            )
            || $options->{'force_sync_admin'}
        )
        ) {
        ## Update admin_table
        unless (defined $list->sync_include_admin()) {
            $log->syslog('err', '')
                unless ($options->{'just_try'});
        }
        if (not @{$list->get_admins('owner') || []}
            and $list->{'admin'}{'status'} ne 'error_config') {
            $log->syslog('err', 'The list "%s" has got no owner defined',
                $list->{'name'});
            $list->set_status_error_config('no_owner_defined');
        }
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
        # $self->savestats();
        $log->syslog('err',
            'The list %s is set in status error_config: %s(%s)',
            $self, $msg, join(', ', @param));
        Sympa::send_notify_to_listmaster($self, $msg,
            [$self->{'name'}, @param]);
    }
}

## set the list in status family_closed and send a notify to owners
sub set_status_family_closed {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self    = shift;
    my $message = shift;    # 'close_list', 'purge_list': Currently unused.
    my @param   = @_;       # No longer used.

    unless ($self->{'admin'}{'status'} eq 'family_closed') {
        my $updater = Sympa::get_address($self->{'domain'}, 'listmaster');

        unless ($self->close_list($updater, 'family_closed')) {
            $log->syslog('err',
                'Impossible to set the list %s in status family_closed');
            return undef;
        }
        $log->syslog('info', 'The list "%s" is set in status family_closed',
            $self->{'name'});
        $self->send_notify_to_owner('list_closed_family', {});
    }
    return 1;
}

## Saves the statistics data to disk.
sub savestats {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    # Be sure the list has been loaded.
    my $dir = $self->{'dir'};
    return undef unless $list_of_lists{$self->{'domain'}}{$self->{'name'}};

    unless (ref($self->{'stats'}) eq 'ARRAY') {
        $log->syslog('err', 'Incorrect parameter %s', $self->{'stats'});
        return undef;
    }

    ## Lock file
    my $lock_fh = Sympa::LockedFile->new($dir . '/stats', 2, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Could not create new lock');
        return undef;
    }

    printf $lock_fh "%d %.0f %.0f %.0f %d %d %d\n",
        @{$self->{'stats'}}, $self->{'total'}, $self->{'last_sync'},
        $self->{'last_sync_admin_user'};

    ## Release the lock
    unless ($lock_fh->close) {
        return undef;
    }

    ## Changed on disk
    $self->{'_mtime'}{'stats'} = time;

    return 1;
}

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
sub get_next_sequence {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    my $stats = $self->{'stats'};
    $stats->[0]++;

    ## Update 'msg_count' file, used for bounces management
    $self->_increment_msg_count();

    return $stats->[0];
}

# Old name: List::extract_verp_rcpt().
# Moved to: Sympa::Spindle::DistributeMessage::_extract_verp_rcpt().
#sub _extract_verp_rcpt;

## Dumps a copy of lists to disk, in text format
sub dump {
    my $self = shift;
    $log->syslog('debug2', '(%s)', $self->{'name'});

    unless (defined $self) {
        $log->syslog('err', 'Unknown list');
        return undef;
    }

    my $user_file_name = "$self->{'dir'}/subscribers.db.dump";

    unless ($self->_save_list_members_file($user_file_name)) {
        $log->syslog('err', 'Failed to save file %s', $user_file_name);
        return undef;
    }

    # Note: "subscribers" file was deprecated.
    $self->{'_mtime'} = {
        'config' => Sympa::Tools::File::get_mtime($self->{'dir'} . '/config'),
        'stats'  => Sympa::Tools::File::get_mtime($self->{'dir'} . '/stats'),
    };

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
        'date'       => $language->gettext_strftime(
            "%d %b %Y at %H:%M:%S",
            localtime time
        ),
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
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $self    = shift;
    my $name    = shift;
    my $robot   = shift;
    my $options = shift;

    die 'bug in logic. Ask developer' unless $robot;

    ## Set of initializations ; only performed when the config is first loaded
    if ($options->{'first_access'}) {
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

        # default list host is robot domain
        $self->{'admin'}{'host'} ||= $self->{'domain'};
        $self->{'name'} = $name;
    }

    unless ((-d $self->{'dir'}) && (-f "$self->{'dir'}/config")) {
        $log->syslog('debug2', 'Missing directory (%s) or config file for %s',
            $self->{'dir'}, $name)
            unless ($options->{'just_try'});
        return undef;
    }

    # Last modification of list config ($last_time_config) and stats
    # ($last_time_stats) on memory cache.
    # Note: "subscribers" file was deprecated.
    my ($last_time_config, $last_time_stats);
    if ($self->{'_mtime'}) {
        $last_time_config = $self->{'_mtime'}{'config'};
        $last_time_stats  = $self->{'_mtime'}{'stats'};
    } else {
        $last_time_config = POSIX::INT_MIN();
        $last_time_stats  = POSIX::INT_MIN();
    }

    my $time_config = Sympa::Tools::File::get_mtime("$self->{'dir'}/config");
    my $time_config_bin =
        Sympa::Tools::File::get_mtime("$self->{'dir'}/config.bin");
    my $time_stats = Sympa::Tools::File::get_mtime("$self->{'dir'}/stats");
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
        if (defined $admin->{'family_name'}
            && ($admin->{'status'} ne 'error_config')) {
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
            my $error = $family->check_param_constraint($self);
            unless ($error) {
                $log->syslog(
                    'err',
                    'Impossible to check parameters constraint for list % set in status error_config',
                    $self->{'name'}
                );
                $self->set_status_error_config('no_check_rules_family',
                    $family->{'name'});
            }
            if (ref($error) eq 'ARRAY') {
                $log->syslog(
                    'err',
                    'The list "%s" does not respect the rules from its family %s',
                    $self->{'name'},
                    $family->{'name'}
                );
                $self->set_status_error_config('no_respect_rules_family',
                    $family->{'name'});
            }
        }
    }

    $self->{'as_x509_cert'} = 1
        if ((-r "$self->{'dir'}/cert.pem")
        || (-r "$self->{'dir'}/cert.pem.enc"));

    ## Load stats file if first new() or stats file changed
    my ($stats, $total);
    my $stats_file = $self->{'dir'} . '/stats';
    if (!-e $stats_file or $time_stats > $last_time_stats) {
        (   $stats, $total, $self->{'last_sync'},
            $self->{'last_sync_admin_user'}
        ) = _load_stats_file($stats_file);
        $last_time_stats = $time_stats;

        $self->{'stats'} = $stats if (defined $stats);
        $self->{'total'} = $total if (defined $total);
    }

    $self->{'_mtime'} = {
        'config' => $last_time_config,
        'stats'  => $last_time_stats,
    };

    $list_of_lists{$self->{'domain'}}{$name} = $self;
    return $config_reloaded;
}

## Return a list of hash's owners and their param
#OBSOLETED.  Use get_admins().
sub get_owners {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    # owners are in the admin_table ; they might come from an include data
    # source
    return [$self->get_admins('owner')];
}

# OBSOLETED: No longer used.
sub get_nb_owners {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    return scalar @{$self->get_admins('owner')};
}

## Return a hash of list's editors and their param(empty if there isn't any
## editor)
#OBSOLETED. Use get_admins().
sub get_editors {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    # editors are in the admin_table ; they might come from an include data
    # source
    return [$self->get_admins('editor')];
}

## Returns an array of owners' email addresses
#OBSOLETED: Use get_admins_email('receptive_owner') or
#           get_admins_email('owner').
sub get_owners_email {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $self  = shift;
    my $param = shift;

    my @rcpt;

    if ($param->{'ignore_nomail'}) {
        @rcpt = map { $_->{'email'} } $self->get_admins('owner');
    } else {
        @rcpt = map { $_->{'email'} } $self->get_admins('receptive_owner');
    }
    unless (@rcpt) {
        $log->syslog('notice', 'Warning: No owner found for list %s', $self);
    }
    return @rcpt;
}

## Returns an array of editors' email addresses
#  or owners if there isn't any editors' email addresses
#OBSOLETED: Use get_admins_email('receptive_editor') or
#           get_admins_email('actual_editor').
sub get_editors_email {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $self  = shift;
    my $param = shift;

    my @rcpt;

    if ($param->{'ignore_nomail'}) {
        @rcpt = map { $_->{'email'} } $self->get_admins('actual_editor');
    } else {
        @rcpt = map { $_->{'email'} } $self->get_admins('receptive_editor');
    }
    return @rcpt;
}

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
        my $user_data = get_list_member_no_object(
            {   email  => $user->{'email'},
                name   => $self->{'name'},
                domain => $self->{'domain'},
            }
        );
        ## test to know if the rcpt suspended her subscription for this list
        ## if yes, don't send the message
        if (defined $user_data->{'suspend'}
            and $user_data->{'suspend'} + 0) {
            if ($user_data->{'startdate'} <= time
                and (time <= $user_data->{'enddate'}
                    or !$user_data->{'enddate'})
                ) {
                next;
            } elsif ($user_data->{'enddate'} < time
                and $user_data->{'enddate'}) {
                ## If end date is < time, update the BDD by deleting the
                ## suspending's data
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
        @tabrcpt_html,        @tabrcpt_html_verp,
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
        my $user_data = get_list_member_no_object(
            {   email  => $user->{'email'},
                name   => $self->{'name'},
                domain => $self->{'domain'},
            }
        );

        # test to know if the rcpt suspended her subscription for this list
        # if yes, don't send the message
        if (    $user_data
            and defined $user_data->{'suspend'}
            and $user_data->{'suspend'} + 0) {
            if (($user_data->{'startdate'} <= time)
                && (   (time <= $user_data->{'enddate'})
                    || (!$user_data->{'enddate'}))
                ) {
                push @tabrcpt_nomail_verp, $user->{'email'};
                next;
            } elsif (($user_data->{'enddate'} < time)
                && ($user_data->{'enddate'})) {
                ## If end date is < time, update the BDD by deleting the
                ## suspending's data
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
        } elsif ($user->{'reception'} eq 'html') {
            if ($user->{'bounce_address'}) {
                push @tabrcpt_html_verp, $user->{'email'};
            } else {
                push @tabrcpt_html, $user->{'email'};
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
        or @tabrcpt_html
        or @tabrcpt_urlize
        or @tabrcpt_mail_verp
        or @tabrcpt_notice_verp
        or @tabrcpt_txt_verp
        or @tabrcpt_html_verp
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
    $available_recipients->{'html'}{'noverp'} = \@tabrcpt_html
        if @tabrcpt_html;
    $available_recipients->{'html'}{'verp'} = \@tabrcpt_html_verp
        if @tabrcpt_html_verp;
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

=over

=item send_confirm_to_editor ( $message, $method )

This method was DEPRECATED.

Send a L<Sympa::Message> object to the editor (for approval).

Sends a message to the list editor to ask him for moderation
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

=back

=cut

# Old name: List::send_to_editor().
# Moved to: Sympa::Spindle::ToEditor & Sympa::Spindle::ToModeration.
#sub send_confirm_to_editor;

=over

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

=cut

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
    my ($self, $operation, $param) = @_;

    my $host  = $self->{'admin'}{'host'};
    my @rcpt  = $self->get_admins_email('receptive_owner');
    my $robot = $self->{'domain'};

    unless (@rcpt) {
        $log->syslog(
            'notice',
            'No owner defined or all of them use nomail option in list %s; using listmasters as default',
            $self
        );
        @rcpt = Sympa::get_listmasters_email($self);
    }
    unless (defined $operation) {
        die 'missing incoming parameter "$operation"';
    }

    if (ref($param) eq 'HASH') {

        $param->{'auto_submitted'} = 'auto-generated';
        $param->{'to'}             = join(',', @rcpt);
        $param->{'type'}           = $operation;

        if ($operation eq 'warn-signoff') {
            foreach my $owner (@rcpt) {
                $param->{'one_time_ticket'} = Sympa::Ticket::create(
                    $owner,
                    $robot,
                    'search/'
                        . Sympa::Tools::Text::encode_uri($self->{'name'})
                        . '/'
                        . Sympa::Tools::Text::encode_uri($param->{'who'}),
                    $param->{'ip'}
                );
                unless (
                    Sympa::send_file(
                        $self, 'listowner_notification', [$owner], $param
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
        } elsif ($operation eq 'subrequest') {
            foreach my $owner (@rcpt) {
                $param->{'one_time_ticket'} = Sympa::Ticket::create(
                    $owner,
                    $robot,
                    'subindex/'
                        . Sympa::Tools::Text::encode_uri($self->{'name'}),
                    $param->{'ip'}
                );
                unless (
                    Sympa::send_file(
                        $self, 'listowner_notification', [$owner], $param
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
        } elsif ($operation eq 'sigrequest') {
            foreach my $owner (@rcpt) {
                $param->{'one_time_ticket'} = Sympa::Ticket::create(
                    $owner,
                    $robot,
                    'sigindex/'
                        . Sympa::Tools::Text::encode_uri($self->{'name'}),
                    $param->{'ip'}
                );
                unless (
                    Sympa::send_file(
                        $self, 'listowner_notification', [$owner], $param
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
                    $self, 'listowner_notification', \@rcpt, $param
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

    } elsif (ref($param) eq 'ARRAY') {

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

# Note: This would be moved to Robot package.
sub get_picture_path {
    my $self = shift;
    return join '/',
        Conf::get_robot_conf($self->{'domain'}, 'static_content_path'),
        'pictures', $self->get_id, @_;
}

# Note: This would be moved to Robot package.
sub get_picture_url {
    my $self = shift;
    return join '/',
        Conf::get_robot_conf($self->{'domain'}, 'static_content_url'),
        'pictures', $self->get_id, @_;
}

=over 4

=item find_picture_filenames ( $email )

Returns the type of a pictures according to the user.

=back

=cut

# Old name: tools::pictures_filename()
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

sub find_picture_paths {
    my $self  = shift;
    my $email = shift;

    return
        map { $self->get_picture_path($_) }
        $self->find_picture_filenames($email);
}

=over

=item find_picture_url ( $email )

Find pictures URL

=back

=cut

# Old name: tools::make_pictures_url().
sub find_picture_url {
    my $self  = shift;
    my $email = shift;

    my ($filename) = $self->find_picture_filenames($email);
    return undef unless $filename;
    return $self->get_picture_url($filename);
}

=over

=item delete_list_member_picture ( $email )

Deletes a member's picture file.

=back

=cut

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

####################################################
# send_notify_to_editor
####################################################
# Sends a notice to list editor(s) or owner (if no editor)
# by parsing listeditor_notification.tt2 template
#
# IN : -$self (+): ref(List)
#      -$operation (+): notification type
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#
######################################################
sub send_notify_to_editor {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my ($self, $operation, $param) = @_;

    my @rcpt = $self->get_admins_email('receptive_editor');
    @rcpt = $self->get_admins_email('actual_editor') unless @rcpt;

    my $robot = $self->{'domain'};
    $param->{'auto_submitted'} = 'auto-generated';

    unless (@rcpt) {
        $log->syslog('notice',
            'Warning: No editor and owner defined at all in list %s', $self);
        return undef;
    }
    unless (defined $operation) {
        die 'missing incoming parameter "$operation"';
    }
    if (ref($param) eq 'HASH') {

        $param->{'to'} = join(',', @rcpt);
        $param->{'type'} = $operation;

        unless (
            Sympa::send_file(
                $self, 'listeditor_notification', \@rcpt, $param
            )
            ) {
            $log->syslog(
                'notice',
                'Unable to send template "listeditor_notification" to %s list editor',
                $self
            );
            return undef;
        }

    } elsif (ref($param) eq 'ARRAY') {

        my $data = {
            'to'   => join(',', @rcpt),
            'type' => $operation
        };

        foreach my $i (0 .. $#{$param}) {
            $data->{"param$i"} = $param->[$i];
        }
        unless (
            Sympa::send_file($self, 'listeditor_notification', \@rcpt, $data))
        {
            $log->syslog('notice',
                'Unable to send template "listeditor_notification" to %s list editor'
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

# Moved to Sympa::send_notify_to_user().
#sub send_notify_to_user;

=over

=item send_probe_to_user

XXX

=back

=cut

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
            ## Insert in exclusion_table if $user->{'included'} eq '1'
            $self->insert_delete_exclusion($who, 'insert');

        }

        $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who} = undef;
        $list_cache{'get_list_member'}{$self->{'domain'}}{$name}{$who} =
            undef;

        ## Delete record in SUBSCRIBER
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

    $self->{'total'} += $total;
    $self->savestats();
    delete_list_member_picture($self, shift(@u));
    return (-1 * $total);

}

## Delete the indicated admin users from the list.
sub delete_list_admin {
    my ($self, $role, @u) = @_;
    $log->syslog('debug2', '', $role);

    my $name  = $self->{'name'};
    my $total = 0;

    $self->{_admin_cache} ||= {};
    delete $self->{_admin_cache}{$role};    # Reset cache

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

    return (-1 * $total);
}

## Delete all admin_table entries
sub delete_all_list_admin {
    $log->syslog('debug2', '');

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    ## Delete record in ADMIN
    unless ($sdm
        and $sth = $sdm->do_prepared_query(q{DELETE FROM admin_table})) {
        $log->syslog('err', 'Unable to remove all admin from database');
        return undef;
    }

    return 1;
}

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
    my $self = shift->{'admin'};
    my $what = shift;
    $log->syslog('debug3', '(%s)', $what);

    if ($self) {
        return $self->{'default_user_options'};
    }
    return undef;
}

## Returns the number of subscribers to the list
sub get_total {
    my $self   = shift;
    my $name   = $self->{'name'};
    my $option = shift;
    $log->syslog('debug3', '(%s)', $name);

    if ($option and $option eq 'nocache') {
        $self->{'total'} = $self->_load_total_db($option);
    }

    return $self->{'total'};
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
#   - 1 if his/her subscription is restored                          #
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
        ## INSERT only if $user->{'included'} eq '1'
        my $options;
        $options->{'email'}  = $email;
        $options->{'name'}   = $name;
        $options->{'domain'} = $robot_id;
        my $user = get_list_member_no_object($options);
        my $date = time;

        if ($user->{'included'} eq '1') {
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

######################################################################
###  get_list_member                                                  #
## Returns a subscriber of the list.
## Options :
##    probe : don't log error if user does not exist
##    #
######################################################################
sub get_list_member {
    my $self    = shift;
    my $email   = Sympa::Tools::Text::canonic_email(shift);
    my %options = @_;

    $log->syslog('debug2', '(%s)', $email);

    my $name = $self->{'name'};

    ## Use session cache
    if (defined $list_cache{'get_list_member'}{$self->{'domain'}}{$name}
        {$email}) {
        return $list_cache{'get_list_member'}{$self->{'domain'}}{$name}
            {$email};
    }

    my $options;
    $options->{'email'}  = $email;
    $options->{'name'}   = $self->{'name'};
    $options->{'domain'} = $self->{'domain'};

    my $user = get_list_member_no_object($options);

    unless (defined $user) {
        return undef;
    } else {
        unless ($user) {
            $log->syslog('debug',
                'User %s was not found in the subscribers of list %s@%s',
                $email, $self->{'name'}, $self->{'domain'});
            return undef;
        } else {
            $user->{'reception'} =
                $self->{'admin'}{'default_user_options'}{'reception'}
                unless (
                $self->is_available_reception_mode($user->{'reception'}));
        }

        ## Set session cache
        $list_cache{'get_list_member'}{$self->{'domain'}}{$self->{'name'}}
            {$email} = $user;
    }
    return $user;
}

# Mapping between var and field names.
sub _map_list_member_cols {
    my %map_field = (
        update_date => 'update_subscriber',
        gecos       => 'comment_subscriber',
        email       => 'user_subscriber',
        id          => 'include_sources_subscriber',
        startdate   => 'suspend_start_date_subscriber',
        enddate     => 'suspend_end_date_subscriber',
    );

    foreach my $f (
        keys %{
            {Sympa::DatabaseDescription::full_db_struct()}
            ->{'subscriber_table'}->{fields}
        }
        ) {
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
        my $col;
        if ($_ eq 'date' or $_ eq 'update_date') {
            $col = $sdm->get_canonical_read_date($map_field{$_});
        } else {
            $col = $map_field{$_};
        }
        ($col eq $_) ? $col : sprintf('%s AS "%s"', $col, $_);
    } sort keys %map_field;
}

######################################################################
###  get_list_member_no_object                                        #
## Get details regarding a subscriber.                               #
# IN:                                                                #
#   - a single reference to a hash with the following keys:          #
#     * email : the subscriber email                                 #
#     * name: the name of the list                                   #
#     * domain: the virtual host under which the list is installed.  #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - a hash containing the user details otherwise                   #
######################################################################

sub get_list_member_no_object {
    my $options = shift;
    $log->syslog('debug2', '(%s, %s, %s)', $options->{'name'},
        $options->{'email'}, $options->{'domain'});

    my $name = $options->{'name'};

    my $email = Sympa::Tools::Text::canonic_email($options->{'email'});

    ## Use session cache
    if (defined $list_cache{'get_list_member'}{$options->{'domain'}}{$name}
        {$email}) {
        return $list_cache{'get_list_member'}{$options->{'domain'}}{$name}
            {$email};
    }

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
            $name,
            $options->{'domain'}
        )
        ) {
        $log->syslog('err', 'Unable to gather information for user: %s',
            $email, $name, $options->{'domain'});
        return undef;
    }
    my $user = $sth->fetchrow_hashref('NAME_lc');
    if (defined $user) {
        $sth->finish;

        $user->{'reception'}   ||= 'mail';
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

    } else {
        my $error = $sth->err;
        $sth->finish;

        if ($error) {
            $log->syslog('err',
                "An error occurred while fetching the data from the database."
            );
            return undef;
        } else {
            $log->syslog('debug2',
                "No user with the email %s is subscribed to list %s@%s",
                $email, $name, $options->{'domain'});
            return 0;
        }
    }

    # Set session cache
    $list_cache{'get_list_member'}{$options->{'domain'}}{$name}{$email} =
        $user;
    return $user;
}

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

    $log->syslog('debug2', '(%s, %s, %s)', $self->{'name'}, $sortby, $offset);

    my $name = $self->{'name'};
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
        $sdm->quote($name),
        $sdm->quote($self->{'domain'}),
        ($selection || '');

    ## SORT BY
    if ($sortby eq 'email') {
        ## Default SORT
        $statement .= ' ORDER BY email';

    } elsif ($sortby eq 'date') {
        $statement .= ' ORDER BY date DESC';

    } elsif ($sortby eq 'sources') {
        $statement .= " ORDER BY subscribed DESC,id";

    } elsif ($sortby eq 'name') {
        $statement .= ' ORDER BY gecos';
    }
    push @sth_stack, $sth;

    unless ($sdm and $sth = $sdm->do_query($statement)) {
        $log->syslog('err', 'Unable to get members of list %s@%s',
            $name, $self->{'domain'});
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
            'Warning: Entry with empty email address in list %s',
            $self->{'name'})
            if (!$user->{'email'});
        $user->{'reception'} ||= 'mail';
        $user->{'reception'} =
            $self->{'admin'}{'default_user_options'}{'reception'}
            unless ($self->is_available_reception_mode($user->{'reception'}));
        $user->{'update_date'} ||= $user->{'date'};

        ######################################################################
        if (defined $user->{custom_attribute}) {
            $user->{'custom_attribute'} =
                Sympa::Tools::Data::decode_custom_attribute(
                $user->{'custom_attribute'});
        }
    } else {
        $sth->finish;
        $sth = pop @sth_stack;
    }

    ## If no offset (for LIMIT) was used, update total of subscribers
    unless ($offset) {
        my $total = $self->_load_total_db('nocache');
        if ($total != $self->{'total'}) {
            $self->{'total'} = $total;
            $self->savestats();
        }
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
            $self->{'name'});
        return undef;
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');

    if (defined $user) {
        $log->syslog('err',
            'Warning: Entry with empty email address in list %s',
            $self->{'name'})
            if (!$user->{'email'});
        $user->{'reception'} ||= 'mail';
        unless ($self->is_available_reception_mode($user->{'reception'})) {
            $user->{'reception'} =
                $self->{'admin'}{'default_user_options'}{'reception'};
        }
        $user->{'update_date'} ||= $user->{'date'};

        $log->syslog('debug2', '(email = %s)', $user->{'email'});
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
    } else {
        $sth->finish;
        $sth = pop @sth_stack;
    }

    return $user;
}

## Loop for all subsequent admin users with the role defined in
## get_first_list_admin.
#DEPRECATED: Merged into _get_basic_admins().  Use get_admins() instead.
#sub get_next_list_admin;

=over

=item get_admins ( $role, [ filter => \@filters ] )

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

=back

=cut

sub get_admins {
    $log->syslog('debug2', '(%s, %s, %s => %s)', @_);
    my $self    = shift;
    my $role    = lc(shift || '');
    my %options = @_;

    my %query = @{$options{filter} || []};
    $query{email} = Sympa::Tools::Text::canonic_email($query{email})
        if defined $query{email};

    # Fill caches.
    $self->{_admin_cache} ||= {};
    if ($role eq 'editor') {
        unless ($self->{_admin_cache}{$role}) {
            delete $self->{_admin_cache}{actual_editor};
            delete $self->{_admin_cache}{receptive_editor};
            $self->{_admin_cache}{$role} = $self->_get_basic_admins($role);
        }
    } elsif ($role eq 'owner') {
        unless ($self->{_admin_cache}{$role}) {
            delete $self->{_admin_cache}{actual_editor};
            delete $self->{_admin_cache}{privileged_owner};
            delete $self->{_admin_cache}{receptive_editor};
            delete $self->{_admin_cache}{receptive_owner};
            $self->{_admin_cache}{$role} = $self->_get_basic_admins($role);
        }
    } elsif ($role eq 'actual_editor') {
        $self->get_admins('owner');
        $self->get_admins('editor');
        unless ($self->{_admin_cache}{$role}) {
            if (@{$self->{_admin_cache}{editor} || []}) {
                $self->{_admin_cache}{$role} = $self->{_admin_cache}{editor};
            } else {
                $self->{_admin_cache}{$role} = $self->{_admin_cache}{owner};
            }
        }
    } elsif ($role eq 'privileged_owner') {
        $self->get_admins('owner');
        unless ($self->{_admin_cache}{$role}) {
            $self->{_admin_cache}{$role} =
                [grep { $_->{profile} and $_->{profile} eq 'privileged' }
                    @{$self->{_admin_cache}{owner} || []}];
        }
    } elsif ($role eq 'receptive_editor') {
        $self->get_admins('owner');
        $self->get_admins('editor');
        unless ($self->{_admin_cache}{$role}) {
            my @users =
                grep { ($_->{reception} || 'mail') ne 'nomail' }
                @{$self->{_admin_cache}{editor} || []};
            @users =
                grep { ($_->{reception} || 'mail') ne 'nomail' }
                @{$self->{_admin_cache}{owner} || []}
                unless @users;
            $self->{_admin_cache}{$role} = [@users];
        }
    } elsif ($role eq 'receptive_owner') {
        $self->get_admins('owner');
        unless ($self->{_admin_cache}{$role}) {
            $self->{_admin_cache}{$role} =
                [grep { ($_->{reception} || 'mail') ne 'nomail' }
                    @{$self->{_admin_cache}{owner}}];
        }
    } else {
        die sprintf 'Unknown role "%s"', $role;
    }

    my $admin_user = $self->{_admin_cache}{$role};
    return unless $admin_user;    # Returns void.

    if (defined $query{email}) {
        $admin_user =
            [grep { ($_->{email} || '') eq $query{email} } @$admin_user];
    }

    return wantarray ? @$admin_user : $admin_user;
}

# Old name: Sympa::List::get_first_list_admin() and
# Sympa::List::get_next_list_admin().
sub _get_basic_admins {
    my $self = shift;
    my $role = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    unless (
        $sdm and $sth = $sdm->do_prepared_query(
            sprintf(
                q{SELECT user_admin AS email, comment_admin AS gecos,
                         reception_admin AS reception,
                         visibility_admin AS visibility,
                         %s AS "date", %s AS update_date,
                         info_admin AS info, profile_admin AS profile,
                         subscribed_admin AS subscribed,
                         included_admin AS included,
                         include_sources_admin AS id
                  FROM admin_table
                  WHERE list_admin = ? AND robot_admin = ? AND role_admin = ?
                  ORDER BY user_admin},
                $sdm->get_canonical_read_date('date_admin'),
                $sdm->get_canonical_read_date('update_admin'),
            ),
            $self->{'name'},
            $self->{'domain'},
            $role
        )
        ) {
        $log->syslog('err', 'Unable to get admins having role %s for list %s',
            $role, $self);
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
        $user->{'update_date'} ||= $user->{'date'};
    }

    return $admin_user;
}

=over

=item get_admins_email ( $role )

I<Instance method>.
Gets an array of emails of list admins with role
C<receptive_editor>, C<actual_editor>, C<receptive_owner> or C<owner>.

=back

=cut

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
            if (!$user->{'email'});
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

=over

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

=back

=cut

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
            {   email   => 'email',
                date    => 'date DESC',
                sources => 'subscribed DESC, id ASC',
                name    => 'gecos',
            }->{$order}
                || 'email'
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
    }

    # If no offset nor limit was used, update total of subscribers.
    if (    $role eq 'member'
        and not $offset
        and not $limit
        and not $cond) {
        my $total = $self->_load_total_db('nocache');
        if ($total != $self->{'total'}) {
            $self->{'total'} = $total;
            $self->savestats();
        }
    }

    return wantarray ? @$users : $users;
}

=over

=item get_resembling_members ( $role, $searchkey )

I<instance method>.
TBD.

=back

=cut

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

=over

=item is_admin ( $role, $user )

I<Instance method>.
Returns true if $user has $role
(C<privileged_owner>, C<owner>, C<actual_editor> or C<editor>) on the list.

=back

=cut

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
    my ($self, $who) = @_;
    $who = Sympa::Tools::Text::canonic_email($who);
    $log->syslog('debug3', '(%s)', $who);

    return undef unless ($self && $who);

    my $name = $self->{'name'};

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    ## Use cache
    if (defined $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who})
    {
        return $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who};
    }

    ## Query the Database
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT count(*)
              FROM subscriber_table
              WHERE list_subscriber = ? AND robot_subscriber = ? AND
                    user_subscriber = ?},
            $name, $self->{'domain'}, $who
        )
        ) {
        $log->syslog(
            'err',
            'Unable to check chether user %s is subscribed to list %s@%s: %s',
            $who,
            $name,
            $self->{'domain'}
        );
        return undef;
    }

    my $is_user = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    ## Set cache
    $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who} = $is_user;

    return $is_user;
}

## Sets new values for the given user (except gecos)
sub update_list_member {
    my $self   = shift;
    my $who    = Sympa::Tools::Text::canonic_email(shift);
    my $values = $_[0];                                      # Compat.
    $values = {@_} unless ref $values eq 'HASH';

    my ($field, $value, $table);
    my $name = $self->{'name'};

    # Mapping between var and field names.
    my %map_field = _map_list_member_cols();

    my $sdm = Sympa::DatabaseManager->instance;
    return undef unless $sdm;

    my @set_list;
    my @val_list;
    while (($field, $value) = each %{$values}) {
        die sprintf 'Unknown database field %s', $field
            unless $map_field{$field};

        if ($field eq 'date' or $field eq 'update_date') {
            push @set_list,
                sprintf('%s = %s',
                $map_field{$field}, $sdm->get_canonical_write_date($value));
        } elsif ($field eq 'custom_attribute') {
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

    ## Reset session cache
    $list_cache{'get_list_member'}{$self->{'domain'}}{$name}{$who} = undef;

    return 1;
}

## Sets new values for the given admin user (except gecos)
sub update_list_admin {
    my ($self, $who, $role, $values) = @_;
    $log->syslog('debug2', '(%s, %s)', $role, $who);
    $who = Sympa::Tools::Text::canonic_email($who);

    my ($field, $value, $table);
    my $name = $self->{'name'};

    ## mapping between var and field names
    my %map_field = (
        reception   => 'reception_admin',
        visibility  => 'visibility_admin',
        date        => 'date_admin',
        update_date => 'update_admin',
        gecos       => 'comment_admin',
        password    => 'password_user',
        email       => 'user_admin',
        subscribed  => 'subscribed_admin',
        included    => 'included_admin',
        id          => 'include_sources_admin',
        info        => 'info_admin',
        profile     => 'profile_admin',
        role        => 'role_admin'
    );

    ## mapping between var and tables
    my %map_table = (
        reception   => 'admin_table',
        visibility  => 'admin_table',
        date        => 'admin_table',
        update_date => 'admin_table',
        gecos       => 'admin_table',
        password    => 'user_table',
        email       => 'admin_table',
        subscribed  => 'admin_table',
        included    => 'admin_table',
        id          => 'admin_table',
        info        => 'admin_table',
        profile     => 'admin_table',
        role        => 'admin_table'
    );
#### ??
    ## additional DB fields
#    if (defined $Conf::Conf{'db_additional_user_fields'}) {
#	foreach my $f (split ',', $Conf::Conf{'db_additional_user_fields'}) {
#	    $map_table{$f} = 'user_table';
#	    $map_field{$f} = $f;
#	}
#    }

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
                if ($field eq 'date' || $field eq 'update_date') {
                    $value = $sdm->get_canonical_write_date($value);
                } elsif ($value and $value eq 'NULL') {    # get_null_value?
                    if ($Conf::Conf{'db_type'} eq 'mysql') {
                        $value = '\N';
                    }
                } else {
                    if ($numeric_field{$map_field{$field}}) {
                        $value ||= 0;    ## Can't have a null value
                    } else {
                        $value = $sdm->quote($value);
                    }
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

    ## Reset session cache
    $self->{_admin_cache} ||= {};
    delete $self->{_admin_cache}{$role};

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
    my ($self, @new_users) = @_;
    $log->syslog('debug2', '%s', $self->{'name'});

    my $name = $self->{'name'};

    $self->{'add_outcome'}                                   = undef;
    $self->{'add_outcome'}{'added_members'}                  = 0;
    $self->{'add_outcome'}{'expected_number_of_added_users'} = $#new_users;
    $self->{'add_outcome'}{'remaining_members_to_add'} =
        $self->{'add_outcome'}{'expected_number_of_added_users'};

    my $current_list_members_count = $self->get_total();

    my $sdm = Sympa::DatabaseManager->instance;

    foreach my $new_user (@new_users) {
        my $who = Sympa::Tools::Text::canonic_email($new_user->{'email'});
        unless (defined $who) {
            $log->syslog('err', 'Ignoring %s which is not a valid email',
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
            $self->sync_include();
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

        # Crypt password if it was not crypted.
        unless (
            Sympa::Tools::Data::smart_eq($new_user->{'password'}, qr/^crypt/))
        {
            $new_user->{'password'} = Sympa::Tools::Password::crypt_password(
                $new_user->{'password'});
        }

        $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who} = undef;

        ## Either is_included or is_subscribed must be set
        ## default is is_subscriber for backward compatibility reason
        unless ($new_user->{'included'}) {
            $new_user->{'subscribed'} = 1;
        }

        unless ($new_user->{'included'}) {
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

        $new_user->{'subscribed'} ||= 0;
        $new_user->{'included'}   ||= 0;

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
                sprintf(
                    q{INSERT INTO subscriber_table
                      (user_subscriber, comment_subscriber,
                       list_subscriber, robot_subscriber,
                       date_subscriber, update_subscriber,
                       reception_subscriber, topics_subscriber,
                       visibility_subscriber, subscribed_subscriber,
                       included_subscriber, include_sources_subscriber,
                       custom_attribute_subscriber,
                       suspend_subscriber,
                       suspend_start_date_subscriber,
                       suspend_end_date_subscriber,
                       number_messages_subscriber)
                      VALUES (?, ?, ?, ?, %s, %s, ?, ?, ?, ?, ?, ?, ?,
                              ?, ?, ?, 0)},
                    $sdm->get_canonical_write_date($new_user->{'date'}),
                    $sdm->get_canonical_write_date(
                        $new_user->{'update_date'}
                    )
                ),
                $who,
                $new_user->{'gecos'},
                $name,
                $self->{'domain'},
                $new_user->{'reception'},
                $new_user->{'topics'},
                $new_user->{'visibility'},
                $new_user->{'subscribed'},
                $new_user->{'included'},
                $new_user->{'id'},
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

    $self->{'total'} += $self->{'add_outcome'}{'added_members'};
    $self->savestats();
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
    my ($self, $role, @new_admin_users) = @_;
    $log->syslog('debug2', '');

    my $name  = $self->{'name'};
    my $total = 0;

    $self->{_admin_cache} ||= {};
    delete $self->{_admin_cache}{$role};    # Reset cache

    foreach my $new_admin_user (@new_admin_users) {
        my $who =
            Sympa::Tools::Text::canonic_email($new_admin_user->{'email'});

        next unless defined $who;

        $new_admin_user->{'date'} ||= time;
        $new_admin_user->{'update_date'} ||= $new_admin_user->{'date'};

        ##  either is_included or is_subscribed must be set
        ## default is is_subscriber for backward compatibility reason
        unless ($new_admin_user->{'included'}) {
            $new_admin_user->{'subscribed'} = 1;
        }

        unless ($new_admin_user->{'included'}) {
            ## Is the email in user table?
            ## Insert in User Table
            unless (
                Sympa::User->new(
                    $who,
                    'gecos'    => $new_admin_user->{'gecos'},
                    'lang'     => $new_admin_user->{'lang'},
                    'password' => $new_admin_user->{'password'}
                )
                ) {
                $log->syslog('err', 'Unable to add admin %s to user_table',
                    $who);
                next;
            }
        }

        $new_admin_user->{'subscribed'} ||= 0;
        $new_admin_user->{'included'}   ||= 0;

        my $sdm = Sympa::DatabaseManager->instance;

        # Update Admin Table
        unless (
            $sdm
            and $sdm->do_prepared_query(
                sprintf(
                    q{INSERT INTO admin_table
                      (user_admin, comment_admin, list_admin, robot_admin,
                       date_admin, update_admin, reception_admin,
                       visibility_admin,
                       subscribed_admin,
                       included_admin, include_sources_admin,
                       role_admin, info_admin, profile_admin)
                      VALUES (?, ?, ?, ?, %s, %s, ?, ?, ?, ?, ?, ?, ?, ?)},
                    $sdm->get_canonical_write_date($new_admin_user->{'date'}),
                    $sdm->get_canonical_write_date(
                        $new_admin_user->{'update_date'}
                    )
                ),
                $who,
                $new_admin_user->{'gecos'},
                $name,
                $self->{'domain'},
                $new_admin_user->{'reception'},
                $new_admin_user->{'visibility'},
                $new_admin_user->{'subscribed'},
                $new_admin_user->{'included'},
                $new_admin_user->{'id'},
                $role,
                $new_admin_user->{'info'},
                $new_admin_user->{'profile'}
            )
            ) {
            $log->syslog(
                'err',
                'Unable to add admin %s to table admin_table for list %s: %s',
                $who,
                $self
            );
            next;
        }
        $total++;
    }

    return $total;
}

## Update subscribers and admin users (used while renaming a list)
sub rename_list_db {
    my ($self, $new_listname, $new_robot) = @_;
    $log->syslog('debug', '(%s, %s, %s)', $self->{'name'}, $new_listname,
        $new_robot);

    my $statement_subscriber;
    my $statement_admin;
    my $statement_list_cache;

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE subscriber_table
              SET list_subscriber = ?, robot_subscriber = ?
              WHERE list_subscriber = ? AND robot_subscriber = ?},
            $new_listname,   $new_robot,
            $self->{'name'}, $self->{'domain'}
        )
        ) {
        $log->syslog('err',
            'Unable to rename list %s@%s to %s@%s in the database',
            $self->{'name'}, $self->{'domain'}, $new_listname, $new_robot);
        next;
    }

    $log->syslog('debug', 'Statement: %s', $statement_subscriber);

    # admin_table is "alive" only in case include2
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE admin_table
              SET list_admin = ?, robot_admin = ?
              WHERE list_admin = ? AND robot_admin = ?},
            $new_listname,   $new_robot,
            $self->{'name'}, $self->{'domain'}
        )
        ) {
        $log->syslog(
            'err',
            'Unable to change admins in database while renaming list %s@%s to %s@%s',
            $self->{'name'},
            $self->{'domain'},
            $new_listname,
            $new_robot
        );
        next;
    }
    $log->syslog('debug', 'Statement: %s', $statement_admin);

    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE list_table
              SET name_list = ?, robot_list = ?
              WHERE name_list = ? AND robot_list = ?},
            $new_listname,   $new_robot,
            $self->{'name'}, $self->{'domain'}
        )
        ) {
        $log->syslog('err', "Unable to rename list in database");
        return undef;
    }

    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE inclusion_table
              SET target_inclusion = ?
              WHERE target_inclusion = ?},
            sprintf('%s@%s', $new_listname, $new_robot),
            $self->get_id
        )
        ) {
        $log->syslog('err', "Unable to rename list in database");
        return undef;
    }

    return 1;
}

## Check list authorizations
## Higher level sub for request_action
# DEPRECATED; Use Sympa::Scenario::request_action();
#sub check_list_authz;

## Initialize internal list cache
sub init_list_cache {
    $log->syslog('debug2', '');

    undef %list_cache;
}

## May the indicated user edit the indicated list parameter or not?
sub may_edit {

    my ($self, $parameter, $who) = @_;
    $log->syslog('debug3', '(%s, %s)', $parameter, $who);

    my $role;

    return undef unless ($self);

    my $edit_conf;

    # Load edit_list.conf: track by file, not domain (file may come from
    # server, robot, family or list context)
    my $edit_conf_file = Sympa::search_fullpath($self, 'edit_list.conf');
    if (!$edit_list_conf{$edit_conf_file}
        or Sympa::Tools::File::get_mtime($edit_conf_file) >
        $Sympa::Robot::mtime{'edit_list_conf'}{$edit_conf_file}) {

        $edit_conf = $edit_list_conf{$edit_conf_file} =
            $self->_load_edit_list_conf;
        $Sympa::Robot::mtime{'edit_list_conf'}{$edit_conf_file} = time;
    } else {
        $edit_conf = $edit_list_conf{$edit_conf_file};
    }

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

    if (   ($parameter =~ /^(\w+)\.(\w+)$/)
        && ($parameter !~ /\.tt2$/)) {
        my $main_parameter = $1;
        @order = (
            $edit_conf->{$parameter}{$role},
            $edit_conf->{$main_parameter}{$role},
            $edit_conf->{'default'}{$role},
            $edit_conf->{'default'}{'default'}
        );
    } else {
        @order = (
            $edit_conf->{$parameter}{$role},
            $edit_conf->{'default'}{$role},
            $edit_conf->{'default'}{'default'}
        );
    }

    foreach $what (@order) {
        if (defined $what) {
            return ($role, $what);
        }
    }

    return ('user', 'hidden');
}

## May the indicated user edit a paramter while creating a new list
## Dev note: This sub is never called. Shall we remove it?
# sa cette procédure est appelée nul part, je lui ajoute malgrès tout le
# paramêtre robot
# edit_conf devrait être aussi dépendant du robot
sub may_create_parameter {

    my ($self, $parameter, $who, $robot) = @_;
    $log->syslog('debug3', '(%s, %s, %s)', $parameter, $who, $robot);

    if (Sympa::is_listmaster($robot, $who)) {
        return 1;
    }
    my $edit_conf = $self->_load_edit_list_conf;
    $edit_conf->{$parameter} ||= $edit_conf->{'default'};
    if (!$edit_conf->{$parameter}) {
        $log->syslog('notice', 'Privilege for parameter %s undefined',
            $parameter);
        return undef;
    }
    if ($edit_conf->{$parameter} =~ /^(owner|privileged_owner)$/i) {
        return 1;
    } else {
        return 0;
    }

}

## May the indicated user do something with the list or not?
## Action can be : send, review, index, get
##                 add, del, reconfirm, purge
# OBSOLETED: No longer used.
sub may_do {
    my ($self, $action, $who) = @_;
    $log->syslog('debug3', '(%s, %s)', $action, $who);

    my $i;

    ## Just in case.
    return undef unless ($self && $action);
    my $admin = $self->{'admin'};
    return undef unless ($admin);

    $action =~ y/A-Z/a-z/;
    $who =~ y/A-Z/a-z/;

    if ($action =~ /^(index|get)$/io) {
        my $arc_access = $admin->{'archive'}{'mail_access'};
        if ($arc_access =~ /^public$/io) {
            return 1;
        } elsif ($arc_access =~ /^private$/io) {
            return 1 if $self->is_list_member($who);
            return 1 if $self->is_admin('owner', $who);
            return Sympa::is_listmaster($self, $who);
        } elsif ($arc_access =~ /^owner$/io) {
            return 1 if $self->is_admin('owner', $who);
            return Sympa::is_listmaster($self, $who);
        }
        return undef;
    }

    if ($action =~ /^(review)$/io) {
        foreach $i (@{$admin->{'review'}}) {
            if ($i =~ /^public$/io) {
                return 1;
            } elsif ($i =~ /^private$/io) {
                return 1 if $self->is_list_member($who);
                return $self->is_admin('owner', $who);
            } elsif ($i =~ /^owner$/io) {
                return 1 if Sympa::is_listmaster($self, $who);
                return $self->is_admin('owner', $who);
            }
            return undef;
        }
    }

    if ($action =~ /^send$/io) {
        if ($admin->{'send'} =~
            /^(private|privateorpublickey|privateoreditorkey)$/i) {

            return undef
                unless $self->is_list_member($who)
                or $self->is_admin('owner', $who);
        } elsif (
            $admin->{'send'} =~ /^(editor|editorkey|privateoreditorkey)$/i) {
            return undef unless $self->is_admin('actual_editor', $who);
        } elsif (
            $admin->{'send'} =~ /^(editorkeyonly|publickey|privatekey)$/io) {
            return undef;
        }
        return 1;
    }

    if ($action =~ /^(add|del|remind|reconfirm|purge)$/io) {
        return $self->is_admin('owner', $who)
            || Sympa::is_listmaster($self, $who);
    }

    if ($action =~ /^(modindex)$/io) {
        return undef unless $self->is_admin('actual_editor', $who);
        return 1;
    }

    if ($action =~ /^auth$/io) {
        if ($admin->{'send'} =~ /^(privatekey)$/io) {
            return 1
                if $self->is_list_member($who)
                or $self->is_admin('owner', $who)
                or Sympa::is_listmaster($self, $who);
        } elsif ($admin->{'send'} =~ /^(privateorpublickey)$/io) {
            return 1
                unless $self->is_list_member($who)
                or $self->is_admin('owner', $who)
                or Sympa::is_listmaster($self, $who);
        } elsif ($admin->{'send'} =~ /^(publickey)$/io) {
            return 1;
        }
        return undef;    #authent
    }
    return undef;
}

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

## Loads all scenari for an action
sub load_scenario_list {
    my ($self, $action, $robot) = @_;
    $log->syslog('debug3', '(%s, %s)', $action, $robot);

    my $directory = "$self->{'dir'}";
    my %list_of_scenario;
    my %skip_scenario;
    my @list_of_scenario_dir =
        @{Sympa::get_search_path($self, subdir => 'scenari')};
    unshift @list_of_scenario_dir, $self->{'dir'} . '/scenari';    #FIXME

    foreach my $dir (@list_of_scenario_dir) {
        next unless (-d $dir);

        my $scenario_regexp = Sympa::Regexps::scenario();

        while (<$dir/$action.*:ignore>) {
            if (/$action\.($scenario_regexp):ignore$/) {
                my $name = $1;
                $skip_scenario{$name} = 1;
            }
        }

        while (<$dir/$action.*>) {
            next unless (/$action\.($scenario_regexp)$/);
            my $name = $1;

            next if (defined $list_of_scenario{$name});
            next if (defined $skip_scenario{$name});

            my $scenario = Sympa::Scenario->new(
                'robot'     => $robot,
                'directory' => $directory,
                'function'  => $action,
                'name'      => $name
            );
            $list_of_scenario{$name} = $scenario;
        }
    }

    ## Return a copy of the data to prevent unwanted changes in the central
    ## scenario data structure
    return Sympa::Tools::Data::dup_var(\%list_of_scenario);
}

sub load_task_list {
    my ($self, $action, $robot) = @_;
    $log->syslog('debug2', '(%s, %s)', $action, $robot);

    my %list_of_task;

    foreach my $dir (
        @{Sympa::get_search_path($self, subdir => 'list_task_models')}) {
        next unless (-d $dir);

    LOOP_FOREACH_FILE:
        foreach my $file (<$dir/$action.*>) {
            next unless ($file =~ /$action\.(\w+)\.task$/);
            my $name = $1;

            next if (defined $list_of_task{$name});

            $list_of_task{$name}{'name'} = $name;

            my $titles = Sympa::List::_load_task_title($file);

            ## Set the title in the current language
            foreach my $lang (
                Sympa::Language::implicated_langs($language->get_lang)) {
                if (exists $titles->{$lang}) {
                    $list_of_task{$name}{'title'} = $titles->{$lang};
                    next LOOP_FOREACH_FILE;
                }
            }
            if (exists $titles->{'gettext'}) {
                $list_of_task{$name}{'title'} =
                    $language->gettext($titles->{'gettext'});
            } elsif (exists $titles->{'default'}) {
                $list_of_task{$name}{'title'} = $titles->{'default'};
            } else {
                $list_of_task{$name}{'title'} = $name;
            }
        }
    }

    return \%list_of_task;
}

sub _load_task_title {
    $log->syslog('debug3', '(%s)', @_);
    my $file   = shift;
    my $titles = {};

    unless (open TASK, '<', $file) {
        $log->syslog('err', 'Unable to open file "%s": %m', $file);
        return undef;
    }

    while (<TASK>) {
        last if /^\s*$/;

        if (/^title\.gettext\s+(.*)\s*$/i) {
            $titles->{'gettext'} = $1;
        } elsif (/^title\.(\S+)\s+(.*)\s*$/i) {
            my ($lang, $title) = ($1, $2);
            # canonicalize lang if possible.
            $lang = Sympa::Language::canonic_lang($lang) || $lang;
            $titles->{$lang} = $title;
        } elsif (/^title\s+(.*)\s*$/i) {
            $titles->{'default'} = $1;
        }
    }

    close TASK;

    return $titles;
}

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
sub _load_stats_file {
    my $file = shift;
    $log->syslog('debug3', '(%s)', $file);

    ## Create the initial stats array.
    my ($stats, $total, $last_sync, $last_sync_admin_user);

    if (open(L, $file)) {
        if (<L> =~
            /^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(\s+(\d+))?(\s+(\d+))?(\s+(\d+))?/)
        {
            $stats                = [$1, $2, $3, $4];
            $total                = $6;
            $last_sync            = $8;
            $last_sync_admin_user = $10;

        } else {
            $stats                = [0, 0, 0, 0];
            $total                = 0;
            $last_sync            = 0;
            $last_sync_admin_user = 0;
        }
        close(L);
    } else {
        $stats                = [0, 0, 0, 0];
        $total                = 0;
        $last_sync            = 0;
        $last_sync_admin_user = 0;
    }

    ## Return the array.
    return ($stats, $total, $last_sync, $last_sync_admin_user);
}

## Loads the list of subscribers.
sub _load_list_members_file {
    my $file = shift;
    $log->syslog('debug2', '(%s)', $file);

    ## Open the file and switch to paragraph mode.
    open(L, $file) || return undef;

    ## Process the lines
    local $RS;
    my $data = <L>;

    my @users;
    foreach (split /\n\n/, $data) {
        my (%user, $email);
        $user{'email'} = $email = $1 if (/^\s*email\s+(.+)\s*$/om);
        $user{'gecos'}       = $1 if (/^\s*gecos\s+(.+)\s*$/om);
        $user{'date'}        = $1 if (/^\s*date\s+(\d+)\s*$/om);
        $user{'update_date'} = $1 if (/^\s*update_date\s+(\d+)\s*$/om);
        $user{'reception'}   = $1
            if (
            /^\s*reception\s+(digest|nomail|summary|notice|txt|html|urlize|not_me)\s*$/om
            );
        $user{'visibility'} = $1
            if (/^\s*visibility\s+(conceal|noconceal)\s*$/om);

        push @users, \%user;
    }
    close(L);

    return @users;
}

## include a remote sympa list as subscribers.
sub _include_users_remote_sympa_list {
    my ($self, $users, $param, $dir, $robot, $default_user_options, $tied) =
        @_;

    my $host = $param->{'host'};
    my $port = $param->{'port'} || '443';
    my $path = $param->{'path'};
    my $cert = $param->{'cert'} || 'list';

    my $id = Sympa::Datasource::_get_datasource_id($param);

    $log->syslog('debug', '(%s) https://%s:%s/%s using cert %s,',
        $self->{'name'}, $host, $port, $path, $cert);

    my $total     = 0;
    my $get_total = 0;

    my $cert_file;
    my $key_file;

    $cert_file = $dir . '/cert.pem';
    $key_file  = $dir . '/private_key';
    if ($cert eq 'list') {
        $cert_file = $dir . '/cert.pem';
        $key_file  = $dir . '/private_key';
    } elsif ($cert eq 'robot') {
        $cert_file = Sympa::search_fullpath($self, 'cert.pem');
        $key_file  = Sympa::search_fullpath($self, 'private_key');
    }
    unless ((-r $cert_file) && (-r $key_file)) {
        $log->syslog(
            'err',
            'Include remote list https://%s:%s/%s using cert %s, unable to open %s or %s',
            $host,
            $port,
            $path,
            $cert,
            $cert_file,
            $key_file
        );
        return undef;
    }

    my $getting_headers = 1;

    my %user;
    my $email;

    foreach my $line (
        Sympa::Fetch::get_https(
            $host, $port, $path,
            $cert_file,
            $key_file,
            {   'key_passwd' => $Conf::Conf{'key_passwd'},
                'cafile'     => $Conf::Conf{'cafile'},
                'capath'     => $Conf::Conf{'capath'}
            }
        )
        ) {
        chomp $line;

        if ($getting_headers) {    # ignore http headers
            next
                unless (
                $line =~ /^(date|update_date|email|reception|visibility)/);
        }
        undef $getting_headers;

        if ($line =~ /^\s*email\s+(.+)\s*$/o) {
            $user{'email'} = $email = $1;
            $log->syslog('debug', 'Email found %s', $email);
            $get_total++;
        }
        $user{'gecos'} = $1 if ($line =~ /^\s*gecos\s+(.+)\s*$/o);

        next unless ($line =~ /^$/);

        unless ($user{'email'}) {
            $log->syslog('debug', 'Ignoring block without email definition');
            next;
        }
        my %u;
        ## Check if user has already been included
        if ($users->{$email}) {
            $log->syslog('debug3', 'Ignore %s because already member',
                $email);
            if ($tied) {
                %u = split "\n", $users->{$email};
            } else {
                %u = %{$users->{$email}};
            }
        } else {
            $log->syslog('debug3', 'Add new subscriber %s', $email);
            %u = %{$default_user_options};
            $total++;
        }
        $u{'email'} = $user{'email'};
        if ($u{'id'}) {
            $u{'id'} = join(',', split(',', $u{'id'}), $id);
        } else {
            $u{'id'} = $id;
        }
        $u{'gecos'} = $user{'gecos'};
        delete $user{'gecos'};

        $u{'visibility'} = $default_user_options->{'visibility'}
            if (defined $default_user_options->{'visibility'});
        $u{'reception'} = $default_user_options->{'reception'}
            if (defined $default_user_options->{'reception'});
        $u{'profile'} = $default_user_options->{'profile'}
            if (defined $default_user_options->{'profile'});
        $u{'info'} = $default_user_options->{'info'}
            if (defined $default_user_options->{'info'});

        if ($tied) {
            $users->{$email} = join("\n", %u);
        } else {
            $users->{$email} = \%u;
        }
        delete $user{$email};
        undef $email;

    }
    $log->syslog('info',
        '%d included users from list (%d subscribers) https://%s:%s%s',
        $total, $get_total, $host, $port, $path);
    return $total;
}

## include a list as subscribers.
sub _include_users_list {
    my $self                 = shift;
    my $users                = shift;
    my $incl                 = shift;
    my $default_user_options = shift;
    my $tied                 = shift;

    my $robot     = $self->{'domain'};
    my $source_id = lc $incl->{listname};
    $source_id = sprintf '%s@%s', $source_id, $self->{'domain'}
        unless 0 < index($source_id, '@');
    my $filter = $incl->{filter};
    my $id     = Sympa::Datasource::_get_datasource_id($incl);

    my $total = 0;

    if (defined $filter and length $filter) {
        chomp $filter;
        # Build tt2.
        $filter =~
            s/^((?:USE\s[^;]+;)*)(.+)/[% TRY %][% $1 %][%IF $2 %]1[%END%][% CATCH %][% error %][%END%]/;
        $log->syslog('notice', 'Applying filter on included list %s : %s',
            $source_id, $filter);
    }

    my $includelist;

    # The included list is local or in another local robot
    $includelist = Sympa::List->new($source_id);

    unless ($includelist) {
        $log->syslog('info', 'Included list %s unknown', $source_id);
        return undef;
    }

    for (
        my $user = $includelist->get_first_list_member();
        $user;
        $user = $includelist->get_next_list_member()
        ) {
        # Do we need filtering ?
        if (defined $filter and length $filter) {
            # Prepare available variables
            my $variables = {};
            $variables->{$_} = $user->{$_} foreach (keys %$user);

            # Rename date to avoid conflicts with date tt2 plugin and make name clearer
            $variables->{subscription_date} = $variables->{date};
            delete $variables->{date};

            # Aliases
            $variables->{ca} = $user->{custom_attributes};

            # Status filters
            $variables->{isSubscriberOf} = sub {
                my $list = Sympa::List->new(shift, $robot);
                return defined $list
                    ? $list->is_list_member($user->{email})
                    : undef;
            };
            $variables->{isEditorOf} = sub {
                my $list = Sympa::List->new(shift, $robot);
                return
                    defined $list
                    ? $list->is_admin('actual_editor', $user->{email})
                    : undef;
            };
            $variables->{isOwnerOf} = sub {
                my $list = Sympa::List->new(shift, $robot);
                return
                    defined $list
                    ? ($list->is_admin('owner', $user->{email})
                        || Sympa::is_listmaster($list, $user->{email}))
                    : undef;
            };

            # Run the test
            my $result;
            my $template = Sympa::Template->new(undef);
            unless ($template->parse($variables, \($filter), \$result)) {
                $log->syslog(
                    'err',
                    'Error while applying filter "%s" : %s, aborting include',
                    $filter,
                    $template->{last_error}
                );
                return undef;
            }
            chomp $result;

            if ($result !~ /^1?$/)
            {    # Anything not 1 or empty result is an error
                $log->syslog(
                    'err',
                    'Error while applying filter "%s" : %s, aborting include',
                    $filter,
                    $result
                );
                return undef;
            }

            next
                unless ($result =~ /1/)
                ;    # skip user if filter returned false (= empty result)
        }

        my %u;

        ## Check if user has already been included
        if ($users->{$user->{'email'}}) {
            if ($tied) {
                %u = split "\n", $users->{$user->{'email'}};
            } else {
                %u = %{$users->{$user->{'email'}}};
            }
        } else {
            %u = %{$default_user_options};
            $total++;
        }

        my $email = $u{'email'} = $user->{'email'};
        $u{'gecos'} = $user->{'gecos'};
        if ($u{'id'}) {
            $u{'id'} = join(',', split(',', $u{'id'}), $id);
        } else {
            $u{'id'} = $id;
        }

        $u{'visibility'} = $default_user_options->{'visibility'}
            if (defined $default_user_options->{'visibility'});
        $u{'reception'} = $default_user_options->{'reception'}
            if (defined $default_user_options->{'reception'});
        $u{'profile'} = $default_user_options->{'profile'}
            if (defined $default_user_options->{'profile'});
        $u{'info'} = $default_user_options->{'info'}
            if (defined $default_user_options->{'info'});

        if ($tied) {
            $users->{$email} = join("\n", %u);
        } else {
            $users->{$email} = \%u;
        }
    }
    $log->syslog('info', "%d included users from list %s",
        $total, $includelist);
    return $total;
}

## include a lists owners lists privileged_owners or lists_editors.
sub _include_users_admin {
    my ($users, $selection, $role, $default_user_options, $tied) = @_;
#   il faut préparer une liste de hash avec le nom de liste, le nom de robot,
#   le répertoire de la liset pour appeler
#    load_admin_file décommanter le include_admin
    my $lists;

    unless ($role eq 'listmaster') {

        if ($selection =~ /^\*\@(\S+)$/) {
            $lists = get_lists($1);
            my $robot = $1;
        } else {
            $selection =~ /^(\S+)@(\S+)$/;
            $lists->[0] = $1;
        }

        foreach my $list (@$lists) {
            #my $admin = $list->_load_list_config_file;
        }
    }
}

sub _include_users_file {
    my ($users, $filename, $default_user_options, $tied) = @_;
    $log->syslog('debug2', '(%s)', $filename);

    my $total = 0;

    unless (open(INCLUDE, "$filename")) {
        $log->syslog('err', 'Unable to open file "%s"', $filename);
        return undef;
    }
    $log->syslog('debug2', 'Including file %s', $filename);

    my $id           = Sympa::Datasource::_get_datasource_id($filename);
    my $lines        = 0;
    my $emails_found = 0;
    my $email_regexp = Sympa::Regexps::email();

    while (<INCLUDE>) {
        if ($lines > 49 && $emails_found == 0) {
            $log->syslog(
                'err',
                'Too much errors in file %s (%s lines, %s emails found). Source file probably corrupted. Cancelling',
                $filename,
                $lines,
                $emails_found
            );
            return undef;
        }

        ## Each line is expected to start with a valid email address
        ## + an optional gecos
        ## Empty lines are skipped
        next if /^\s*$/;
        next if /^\s*\#/;

        ## Skip badly formed emails
        unless (/^\s*($email_regexp)(\s*(\S.*))?\s*$/) {
            $log->syslog('err', 'Skip badly formed line: "%s"', $_);
            next;
        }

        my $email = Sympa::Tools::Text::canonic_email($1);

        unless (Sympa::Tools::Text::valid_email($email)) {
            $log->syslog('err', 'Skip badly formed email address: "%s"',
                $email);
            next;
        }

        $lines++;
        next unless $email;
        my $gecos = $5;
        $emails_found++;

        my %u;
        ## Check if user has already been included
        if ($users->{$email}) {
            if ($tied) {
                %u = split "\n", $users->{$email};
            } else {
                %u = %{$users->{$email}};
            }
        } else {
            %u = %{$default_user_options};
            $total++;
        }
        $u{'email'} = $email;
        $u{'gecos'} = $gecos;
        if ($u{'id'}) {
            $u{'id'} = join(',', split(',', $u{'id'}), $id);
        } else {
            $u{'id'} = $id;
        }

        $u{'visibility'} = $default_user_options->{'visibility'}
            if (defined $default_user_options->{'visibility'});
        $u{'reception'} = $default_user_options->{'reception'}
            if (defined $default_user_options->{'reception'});
        $u{'profile'} = $default_user_options->{'profile'}
            if (defined $default_user_options->{'profile'});
        $u{'info'} = $default_user_options->{'info'}
            if (defined $default_user_options->{'info'});

        if ($tied) {
            $users->{$email} = join("\n", %u);
        } else {
            $users->{$email} = \%u;
        }
    }
    close INCLUDE;

    $log->syslog('info', '%d included users from file %s', $total, $filename);
    return $total;
}

sub _include_users_remote_file {
    my ($users, $param, $default_user_options, $tied) = @_;

    my $url = $param->{'url'};

    $log->syslog('debug', '(%s)', $url);

    my $total = 0;
    my $id    = Sympa::Datasource::_get_datasource_id($param);

    my $fetch =
        LWP::UserAgent->new(agent => 'Sympa/' . Sympa::Constants::VERSION);
    my $req = HTTP::Request->new(GET => $url);

    if (defined $param->{'user'} && defined $param->{'passwd'}) {
        $req->authorization_basic($param->{'user'}, $param->{'passwd'});
    }

    my $res = $fetch->request($req);

    # check the outcome
    if ($res->is_success) {
        my @remote_file  = split(/\n/, $res->content);
        my $lines        = 0;
        my $emails_found = 0;
        my $email_regexp = Sympa::Regexps::email();

        # forgot headers (all line before one that contain a email
        foreach my $line (@remote_file) {
            if ($lines > 49 && $emails_found == 0) {
                $log->syslog(
                    'err',
                    'Too much errors in file %s (%s lines, %s emails found). Source file probably corrupted. Cancelling',
                    $url,
                    $lines,
                    $emails_found
                );
                return undef;
            }

            ## Each line is expected to start with a valid email address
            ## + an optional gecos
            ## Empty lines are skipped
            next if ($line =~ /^\s*$/);
            next if ($line =~ /^\s*\#/);

            ## Skip badly formed emails
            unless ($line =~ /^\s*($email_regexp)(\s*(\S.*))?\s*$/) {
                $log->syslog('err', 'Skip badly formed line: "%s"', $line);
                next;
            }

            my $email = Sympa::Tools::Text::canonic_email($1);

            unless (Sympa::Tools::Text::valid_email($email)) {
                $log->syslog('err', 'Skip badly formed email address: "%s"',
                    $line);
                next;
            }

            $lines++;
            next unless $email;
            my $gecos = $5;
            $emails_found++;

            my %u;
            ## Check if user has already been included
            if ($users->{$email}) {
                if ($tied) {
                    %u = split "\n", $users->{$email};
                } else {
                    %u = %{$users->{$email}};
                }
            } else {
                %u = %{$default_user_options};
                $total++;
            }
            $u{'email'} = $email;
            $u{'gecos'} = $gecos;
            if ($u{'id'}) {
                $u{'id'} = join(',', split(',', $u{'id'}), $id);
            } else {
                $u{'id'} = $id;
            }

            $u{'visibility'} = $default_user_options->{'visibility'}
                if (defined $default_user_options->{'visibility'});
            $u{'reception'} = $default_user_options->{'reception'}
                if (defined $default_user_options->{'reception'});
            $u{'profile'} = $default_user_options->{'profile'}
                if (defined $default_user_options->{'profile'});
            $u{'info'} = $default_user_options->{'info'}
                if (defined $default_user_options->{'info'});

            if ($tied) {
                $users->{$email} = join("\n", %u);
            } else {
                $users->{$email} = \%u;
            }
        }
    } else {
        $log->syslog('err', 'Unable to fetch remote file %s: %s',
            $url, $res->message());
        return undef;
    }

    #FIXME: Reset http credentials

    $log->syslog('info', '%d included users from remote file %s',
        $total, $url);
    return $total;
}

## Includes users from voot group
sub _include_users_voot_group {
    my ($users, $param, $default_user_options, $tied) = @_;

    $log->syslog('debug', '(%s, %s, %s)', $param->{'user'},
        $param->{'provider'}, $param->{'group'});

    my $id = Sympa::Datasource::_get_datasource_id($param);

    my $consumer = VOOTConsumer->new(
        user     => $param->{'user'},
        provider => $param->{'provider'}
    );

    # Here we need to check if we are in a web environment and set consumer's
    # webEnv accordingly

    unless ($consumer) {
        $log->syslog('err', 'Cannot create VOOT consumer. Cancelling');
        return undef;
    }

    my $members = $consumer->getGroupMembers(group => $param->{'group'});
    unless (defined $members) {
        my $url = $consumer->getOAuthConsumer()->mustRedirect();
        # Report error with redirect url
        #return do_redirect($url) if(defined $url);
        return undef;
    }

    my $email_regexp = Sympa::Regexps::email();
    my $total        = 0;

    foreach my $member (@$members) {
        #foreach my $email (@{$member->{'emails'}}) {
        if (my $email = shift(@{$member->{'emails'}})) {
            unless (Sympa::Tools::Text::valid_email($email)) {
                $log->syslog('err', 'Skip badly formed email address: "%s"',
                    $email);
                next;
            }
            next unless ($email);

            ## Check if user has already been included
            my %u;
            if ($users->{$email}) {
                %u =
                    $tied
                    ? split("\n", $users->{$email})
                    : %{$users->{$email}};
            } else {
                %u = %{$default_user_options};
                $total++;
            }

            $u{'email'} = $email;
            $u{'gecos'} = $member->{'displayName'};
            if ($u{'id'}) {
                $u{'id'} = join(',', split(',', $u{'id'}), $id);
            } else {
                $u{'id'} = $id;
            }

            $u{'visibility'} = $default_user_options->{'visibility'}
                if (defined $default_user_options->{'visibility'});
            $u{'reception'} = $default_user_options->{'reception'}
                if (defined $default_user_options->{'reception'});
            $u{'profile'} = $default_user_options->{'profile'}
                if (defined $default_user_options->{'profile'});
            $u{'info'} = $default_user_options->{'info'}
                if (defined $default_user_options->{'info'});

            if ($tied) {
                $users->{$email} = join("\n", %u);
            } else {
                $users->{$email} = \%u;
            }
        }
    }

    $log->syslog('info',
        '%d included users from VOOT group %s at provider %s',
        $total, $param->{'group'}, $param->{'provider'});

    return $total;
}

## Returns a list of subscribers extracted from a remote LDAP Directory
sub _include_users_ldap {
    my ($users, $id, $source, $db, $default_user_options, $tied) = @_;
    $log->syslog('debug2', '');

    my $ldap_suffix = $source->{'suffix'};
    my $ldap_filter = $source->{'filter'};
    my $ldap_attrs  = $source->{'attrs'};
    my $ldap_select = $source->{'select'};

    my @attrs = split /\s*,\s*/, $ldap_attrs;
    my ($email_attr, $gecos_attr) = @attrs;

    ## LDAP and query handler
    my $mesg;

    ## Connection timeout (default is 120)
    #my $timeout = 30;

    unless ($db and $db->connect) {
        $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
            $source->{'host'});
        return undef;
    }
    $log->syslog('debug2',
        'Searching on server %s; suffix %s; filter %s; attrs: %s',
        $source->{'host'}, $ldap_suffix, $ldap_filter, $ldap_attrs);
    $mesg = $db->do_operation(
        'search',
        base   => "$ldap_suffix",
        filter => "$ldap_filter",
        attrs  => [@attrs],
        scope  => "$source->{'scope'}"
    );
    unless ($mesg) {
        $log->syslog(
            'err',
            'LDAP search (single level) failed: %s (searching on server %s; suffix %s; filter %s; attrs: %s)',
            $db->error(),
            $source->{'host'},
            $ldap_suffix,
            $ldap_filter,
            $ldap_attrs
        );
        return undef;
    }

    ## Counters.
    my $total = 0;
    my @emails;
    my %emailsViewed;

    while (my $e = $mesg->shift_entry) {
        my $emailentry = $e->get_value($email_attr, asref => 1);
        my $gecosentry = $e->get_value($gecos_attr, asref => 1);
        $gecosentry = $gecosentry->[0] if ref $gecosentry eq 'ARRAY';

        unless (defined $emailentry) {
            next;
        } elsif (ref $emailentry eq 'ARRAY') {
            # Multiple values
            foreach my $email (@{$emailentry}) {
                my $cleanmail = Sympa::Tools::Text::canonic_email($email);
                ## Skip badly formed emails
                unless (Sympa::Tools::Text::valid_email($email)) {
                    $log->syslog('err',
                        'Skip badly formed email address: "%s"', $email);
                    next;
                }

                next if $emailsViewed{$cleanmail};
                push @emails, [$cleanmail, $gecosentry];
                $emailsViewed{$cleanmail} = 1;
                last if $ldap_select eq 'first';
            }
        } else {    #FIMXE: Probably not reached due to asref.
            my $cleanmail = Sympa::Tools::Text::canonic_email($emailentry);
            ## Skip badly formed emails
            unless (Sympa::Tools::Text::valid_email($emailentry)) {
                $log->syslog('err', 'Skip badly formed email address: "%s"',
                    $emailentry);
                next;
            }

            next if $emailsViewed{$cleanmail};
            push @emails, [$cleanmail, $gecosentry];
            $emailsViewed{$cleanmail} = 1;
        }
    }

    unless ($db->disconnect()) {
        $log->syslog('notice', 'Can\'t unbind from LDAP server %s',
            $source->{'host'});
        return undef;
    }

    foreach my $emailgecos (@emails) {
        my ($email, $gecos) = @$emailgecos;
        next if ($email =~ /^\s*$/);

        $email = Sympa::Tools::Text::canonic_email($email);
        my %u;
        ## Check if user has already been included
        if ($users->{$email}) {
            if ($tied) {
                %u = split "\n", $users->{$email};
            } else {
                %u = %{$users->{$email}};
            }
        } else {
            %u = %{$default_user_options};
            $total++;
        }

        $u{'email'}       = $email;
        $u{'gecos'}       = $gecos if ($gecos);
        $u{'date'}        = time;
        $u{'update_date'} = time;
        if ($u{'id'}) {
            $u{'id'} = join(',', split(',', $u{'id'}), $id);
        } else {
            $u{'id'} = $id;
        }

        $u{'visibility'} = $default_user_options->{'visibility'}
            if (defined $default_user_options->{'visibility'});
        $u{'reception'} = $default_user_options->{'reception'}
            if (defined $default_user_options->{'reception'});
        $u{'profile'} = $default_user_options->{'profile'}
            if (defined $default_user_options->{'profile'});
        $u{'info'} = $default_user_options->{'info'}
            if (defined $default_user_options->{'info'});

        if ($tied) {
            $users->{$email} = join("\n", %u);
        } else {
            $users->{$email} = \%u;
        }
    }

    $log->syslog('debug2', 'Unbinded from LDAP server %s', $source->{'host'});
    $log->syslog('info', '%d included users from LDAP query', $total);

    return $total;
}

## Returns a list of subscribers extracted indirectly from a remote LDAP
## Directory using a two-level query
sub _include_users_ldap_2level {
    my ($users, $id, $source, $db, $default_user_options, $tied) = @_;
    $log->syslog('debug2', '');

    my $ldap_suffix1 = $source->{'suffix1'};
    my $ldap_filter1 = $source->{'filter1'};
    my $ldap_attrs1  = $source->{'attrs1'};
    my $ldap_select1 = $source->{'select1'};
    my $ldap_scope1  = $source->{'scope1'};
    my $ldap_regex1  = $source->{'regex1'};
    my $ldap_suffix2 = $source->{'suffix2'};
    my $ldap_filter2 = $source->{'filter2'};
    my $ldap_attrs2  = $source->{'attrs2'};
    my $ldap_select2 = $source->{'select2'};
    my $ldap_scope2  = $source->{'scope2'};
    my $ldap_regex2  = $source->{'regex2'};
    my @sync_errors  = ();

    my ($email_attr, $gecos_attr) = split(/\s*,\s*/, $ldap_attrs2);
    my @ldap_attrs2 = ($email_attr);
    push @ldap_attrs2, $gecos_attr if ($gecos_attr);

    ## LDAP and query handler
    my $mesg;

    unless ($db and $db->connect()) {
        $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
            $source->{'host'});
        return undef;
    }

    $log->syslog('debug2',
        'Searching on server %s; suffix %s; filter %s; attrs: %s',
        $source->{'host'}, $ldap_suffix1, $ldap_filter1, $ldap_attrs1);
    $mesg = $db->do_operation(
        'search',
        base   => "$ldap_suffix1",
        filter => "$ldap_filter1",
        attrs  => ["$ldap_attrs1"],
        scope  => "$ldap_scope1"
    );
    unless ($mesg) {
        $log->syslog(
            'err',
            'LDAP search (1st level) failed: %s (searching on server %s; suffix %s; filter %s; attrs: %s)',
            $db->error(),
            $source->{'host'},
            $ldap_suffix1,
            $ldap_filter1,
            $ldap_attrs1
        );
        return undef;
    }

    ## Counters.
    my $total = 0;

    ## returns a reference to a HASH where the keys are the DNs
    ##  the second level hash's hold the attributes

    my (@attrs, @emails);

    while (my $e = $mesg->shift_entry) {
        my $entry = $e->get_value($ldap_attrs1, asref => 1);

        unless (defined $entry) {
            next;
        } elsif (ref $entry eq 'ARRAY') {
            # Multiple values
            foreach my $attr (@{$entry}) {
                next if $ldap_select1 eq 'regex' and $attr !~ /$ldap_regex1/;
                push @attrs, $attr;
                last if $ldap_select1 eq 'first';
            }
        } else {    #FIXME: Probably not reached due to asref
            next if $ldap_select1 eq 'regex' and $entry !~ /$ldap_regex1/;
            push @attrs, $entry;
        }
    }

    my %emailsViewed;

    my ($suffix2, $filter2);
    foreach my $attr (@attrs) {
        # Escape LDAP characters occurring in attribute
        my $escaped_attr = $attr;
        $escaped_attr =~ s/([\\\(\*\)\0])/sprintf "\\%02X", ord($1)/eg;

        ($suffix2 = $ldap_suffix2) =~ s/\[attrs1\]/$escaped_attr/g;
        ($filter2 = $ldap_filter2) =~ s/\[attrs1\]/$escaped_attr/g;

        $log->syslog('debug2',
            'Searching on server %s; suffix %s; filter %s; attrs: %s',
            $source->{'host'}, $suffix2, $filter2, $ldap_attrs2);
        $mesg = $db->do_operation(
            'search',
            base   => "$suffix2",
            filter => "$filter2",
            attrs  => ["$ldap_attrs2"],    # FIXME: multiple attrs?
            scope  => "$ldap_scope2"
        );
        unless ($mesg) {
            $log->syslog(
                'err',
                'LDAP search (2nd level) failed: %s. Node: %s (searching on server %s; suffix %s; filter %s; attrs: %s)',
                $db->error(),
                $attr,
                $source->{'host'},
                $suffix2,
                $filter2,
                $ldap_attrs2
            );
            push @sync_errors,
                {
                'error',       $db->error(),
                'host',        $source->{'host'},
                'suffix2',     $suffix2,
                'fliter2',     $filter2,
                'ldap_attrs2', $ldap_attrs2
                };
        }

        ## returns a reference to a HASH where the keys are the DNs
        ##  the second level hash's hold the attributes

        while (my $e = $mesg->shift_entry) {
            my $emailentry = $e->get_value($email_attr, asref => 1);
            my $gecosentry = $e->get_value($gecos_attr, asref => 1);
            $gecosentry = $gecosentry->[0] if ref $gecosentry eq 'ARRAY';

            unless (defined $emailentry) {
                next;
            } elsif (ref $emailentry eq 'ARRAY') {
                # Multiple values
                foreach my $email (@{$emailentry}) {
                    my $cleanmail = Sympa::Tools::Text::canonic_email($email);
                    ## Skip badly formed emails
                    unless (Sympa::Tools::Text::valid_email($email)) {
                        $log->syslog('err',
                            'Skip badly formed email address: "%s"', $email);
                        next;
                    }

                    next
                        if $ldap_select2 eq 'regex'
                        and $cleanmail !~ /$ldap_regex2/;
                    next if $emailsViewed{$cleanmail};
                    push @emails, [$cleanmail, $gecosentry];
                    $emailsViewed{$cleanmail} = 1;
                    last if $ldap_select2 eq 'first';
                }
            } else {    #FIXME: Probably not reached due to asref
                my $cleanmail =
                    Sympa::Tools::Text::canonic_email($emailentry);
                ## Skip badly formed emails
                unless (Sympa::Tools::Text::valid_email($emailentry)) {
                    $log->syslog('err',
                        'Skip badly formed email address: "%s"', $emailentry);
                    next;
                }

                next
                    if $ldap_select2 eq 'regex'
                    and $cleanmail !~ /$ldap_regex2/;
                next if $emailsViewed{$cleanmail};
                push @emails, [$cleanmail, $gecosentry];
                $emailsViewed{$cleanmail} = 1;
            }
        }
    }

    unless ($db->disconnect()) {
        $log->syslog('err', 'Can\'t unbind from LDAP server %s',
            $source->{'host'});
        return undef;
    }

    foreach my $emailgecos (@emails) {
        my ($email, $gecos) = @$emailgecos;
        next if ($email =~ /^\s*$/);

        $email = Sympa::Tools::Text::canonic_email($email);
        my %u;
        ## Check if user has already been included
        if ($users->{$email}) {
            if ($tied) {
                %u = split "\n", $users->{$email};
            } else {
                %u = %{$users->{$email}};
            }
        } else {
            %u = %{$default_user_options};
            $total++;
        }

        $u{'email'}       = $email;
        $u{'gecos'}       = $gecos if ($gecos);
        $u{'date'}        = time;
        $u{'update_date'} = time;
        if ($u{'id'}) {
            $u{'id'} = join(',', split(',', $u{'id'}), $id);
        } else {
            $u{'id'} = $id;
        }

        $u{'visibility'} = $default_user_options->{'visibility'}
            if (defined $default_user_options->{'visibility'});
        $u{'reception'} = $default_user_options->{'reception'}
            if (defined $default_user_options->{'reception'});
        $u{'profile'} = $default_user_options->{'profile'}
            if (defined $default_user_options->{'profile'});
        $u{'info'} = $default_user_options->{'info'}
            if (defined $default_user_options->{'info'});

        if ($tied) {
            $users->{$email} = join("\n", %u);
        } else {
            $users->{$email} = \%u;
        }
    }

    $log->syslog('debug2', 'Unbinded from LDAP server %s', $source->{'host'});
    $log->syslog('info', '%d included users from LDAP query 2level', $total);

    my $result;
    $result->{'total'} = $total;
    if ($#sync_errors > -1) { $result->{'errors'} = \@sync_errors; }
    return $result;
}

sub _include_sql_ca {
    my $source = shift;
    my $db     = shift;

    return {} unless $db and $db->connect();

    $log->syslog(
        'debug',
        '%s, email_entry = %s',
        $source->{'sql_query'},
        $source->{'email_entry'}
    );

    my $sth     = $db->do_query($source->{'sql_query'});
    my $mailkey = $source->{'email_entry'};
    my $ca      = $sth->fetchall_hashref($mailkey);
    my $result;
    foreach my $email (keys %{$ca}) {
        foreach my $custom_attribute (keys %{$ca->{$email}}) {
            $result->{$email}{$custom_attribute}{'value'} =
                $ca->{$email}{$custom_attribute}
                unless ($custom_attribute eq $mailkey);
        }
    }
    return $result;
}

sub _include_ldap_ca {
    my $source = shift;
    my $db     = shift;

    return {} unless $db and $db->connect();

    $log->syslog('debug', 'Server %s; suffix %s; filter %s; attrs: %s',
        $source->{'host'}, $source->{'suffix'}, $source->{'filter'},
        $source->{'attrs'});

    my @attrs = split(/\s*,\s*/, $source->{'attrs'});

    my $mesg = $db->do_operation(
        'search',
        base   => $source->{'suffix'},
        filter => $source->{'filter'},
        attrs  => [@attrs],
        scope  => $source->{'scope'}
    );
    unless ($mesg) {
        $log->syslog(
            'err',
            'LDAP search (single level) failed: %s (searching on server %s; suffix %s; filter %s; attrs: %s)',
            $db->error(),
            $source->{'host'},
            $source->{'suffix'},
            $source->{'filter'},
            $source->{'attrs'}
        );
        return {};
    }

    my $attributes;
    while (my $entry = $mesg->shift_entry) {
        my $email = $entry->get_value($source->{'email_entry'});
        next unless ($email);
        foreach my $attr (@attrs) {
            next if ($attr eq $source->{'email_entry'});
            $attributes->{$email}{$attr}{'value'} = $entry->get_value($attr);
        }
    }

    return $attributes;
}

sub _include_ldap_2level_ca {
    my $source = shift;
    my $db     = shift;

    return {} unless $db and $db->connect();

    return {};

    $log->syslog('debug', 'Server %s; suffix %s; filter %s; attrs: %s',
        $source->{'host'}, $source->{'suffix'}, $source->{'filter'},
        $source->{'attrs'});

    my @attrs = split(/\s*,\s*/, $source->{'attrs'});

    my $mesg = $db->do_operation(
        'search',
        base   => $source->{'suffix'},
        filter => $source->{'filter'},
        attrs  => [@attrs],
        scope  => $source->{'scope'}
    );
    unless ($mesg) {
        $log->syslog(
            'err',
            'LDAP search (single level) failed: %s (searching on server %s; suffix %s; filter %s; attrs: %s)',
            $db->error(),
            $source->{'host'},
            $source->{'suffix'},
            $source->{'filter'},
            $source->{'attrs'}
        );
        return {};
    }

    my $attributes;
    while (my $entry = $mesg->shift_entry) {
        my $email = $entry->get_value($source->{'email_entry'});
        next unless ($email);
        foreach my $attr (@attrs) {
            next if ($attr eq $source->{'email_entry'});
            $attributes->{$email}{$attr}{'value'} = $entry->get_value($attr);
        }
    }

    return $attributes;
}

## Returns a list of subscribers extracted from an remote Database
sub _include_users_sql {
    my ($users, $id, $source, $db, $default_user_options, $tied,
        $fetch_timeout)
        = @_;

    my $sth;
    unless ($db
        and $db->connect()
        and $sth = $db->do_query($source->{'sql_query'})) {
        $log->syslog(
            'err',
            'Unable to connect to SQL datasource with parameters host: %s, database: %s',
            $source->{'host'},
            $source->{'db_name'}
        );
        return undef;
    }
    ## Counters.
    my $total = 0;

    ## Process the SQL results
    my $array_of_users =
        Sympa::Process::eval_in_time(sub { $sth->fetchall_arrayref },
        $fetch_timeout);
    $sth->finish;

    unless (ref $array_of_users eq 'ARRAY') {
        $log->syslog('err', 'Failed to include users from %s',
            $source->{'name'});
        return undef;
    }

    foreach my $row (@{$array_of_users}) {
        my $email = $row->[0];    ## only get first field
        my $gecos = $row->[1];    ## second field (if it exists) is gecos
        ## Empty value
        next if ($email =~ /^\s*$/);

        $email = Sympa::Tools::Text::canonic_email($email);

        ## Skip badly formed emails
        unless (Sympa::Tools::Text::valid_email($email)) {
            $log->syslog('err', 'Skip badly formed email address: "%s"',
                $email);
            next;
        }

        my %u;
        ## Check if user has already been included
        if ($users->{$email}) {
            if ($tied eq 'tied') {
                %u = split "\n", $users->{$email};
            } else {
                %u = %{$users->{$email}};
            }
        } else {
            %u = %{$default_user_options};
            $total++;
        }

        $u{'email'}       = $email;
        $u{'gecos'}       = $gecos if ($gecos);
        $u{'date'}        = time;
        $u{'update_date'} = time;
        if ($u{'id'}) {
            $u{'id'} = join(',', split(',', $u{'id'}), $id);
        } else {
            $u{'id'} = $id;
        }

        $u{'visibility'} = $default_user_options->{'visibility'}
            if (defined $default_user_options->{'visibility'});
        $u{'reception'} = $default_user_options->{'reception'}
            if (defined $default_user_options->{'reception'});
        $u{'profile'} = $default_user_options->{'profile'}
            if (defined $default_user_options->{'profile'});
        $u{'info'} = $default_user_options->{'info'}
            if (defined $default_user_options->{'info'});

        if ($tied eq 'tied') {
            $users->{$email} = join("\n", %u);
        } else {
            $users->{$email} = \%u;
        }
    }
    $db->disconnect();
    $log->syslog('info', '%d included users from SQL query', $total);
    return $total;
}

## Loads the list of subscribers from an external include source
sub _load_list_members_from_include {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self     = shift;
    my $old_subs = shift;

    # To prevent overwriting actual list config.
    my $sources = {
        map {
            ($_ => (Sympa::Tools::Data::dup_var($self->{'admin'}{$_}) || []))
        } @sources_providing_listmembers
    };

    my %users;
    my @depend_on;
    my $total = 0;
    my @errors;
    my @ex_sources;

    foreach my $entry (@{$self->{'admin'}{'member_include'}}) {
        next unless $entry;

        my $include_file = Sympa::search_fullpath(
            $self,
            $entry->{'source'} . '.incl',
            subdir => 'data_sources'
        );

        unless (defined $include_file) {
            $log->syslog('err', 'The file %s.incl doesn\'t exist',
                $entry->{'source'});
            return undef;
        }

        my $include_member;
        ## the file has parameters
        if (defined $entry->{'source_parameters'}) {
            my %parsing;

            $parsing{'data'}     = $entry->{'source_parameters'};
            $parsing{'template'} = "$entry->{'source'}\.incl";

            my $name = "$entry->{'source'}\.incl";

            my $include_path = $include_file;
            if ($include_path =~ s/$name$//) {
                $parsing{'include_path'} = $include_path;
                $include_member =
                    $self->_load_include_admin_user_file($include_path,
                    \%parsing);
            } else {
                $log->syslog('err',
                    'Errors to get path of the the file %s.incl',
                    $entry->{'source'});
                return undef;
            }

        } else {
            $include_member =
                $self->_load_include_admin_user_file($include_file);
        }

        if ($include_member and %$include_member) {
            my @types = keys %{$include_member};
            my $type  = $types[0];                    #FIXME: Gets random key?
            my @defs  = @{$include_member->{$type}};
            my $def   = $defs[0];
            push @{$sources->{$type}}, $def;
        }
    }

    foreach my $type (@sources_providing_listmembers) {
        foreach my $tmp_incl (@{$sources->{$type}}) {
            # Work with a copy of admin hash branch to avoid including
            # temporary variables into the actual admin hash.[bug #3182]
            my $incl = Sympa::Tools::Data::dup_var($tmp_incl);

            # As CA certificate is required, take it from site config.
            if (    ref $incl eq 'HASH'
                and $incl->{use_tls}
                and $incl->{use_tls} ne 'none'
                and not $incl->{ca_file}
                and not $incl->{ca_path}) {
                $incl->{ca_file} = $Conf::Conf{'cafile'}
                    if $Conf::Conf{'cafile'};
                $incl->{ca_path} = $Conf::Conf{'capath'}
                    if $Conf::Conf{'capath'};
            }

            my $source_id = Sympa::Datasource::_get_datasource_id($tmp_incl);
            my $source_is_new = defined $old_subs->{$source_id};

            # Get the list of users.
            # Verify if we can synchronize sources. If it's allowed OR there
            # are new sources, we update the list, and can add subscribers.
            # If we can't synchronize, we make an array with excluded sources.

            my $included;
            if (my $plugin = $self->isPlugin($type)) {
                my $source = $plugin->listSource;
                if ($source->isAllowedToSync || $source_is_new) {
                    $log->syslog(debug => "syncing members from $type");
                    $included = $source->getListMembers(
                        users         => \%users,
                        settings      => $incl,
                        user_defaults => $self->get_default_user_options
                    );
                    defined $included
                        or push @errors,
                        {type => $type, name => $incl->{name}};
                }
            } elsif ($type eq 'include_sql_query') {
                my $db = Sympa::Database->new(
                    $incl->{'db_type'},
                    %$incl,
                    db_host    => $incl->{'host'},
                    db_options => $incl->{'connect_options'},
                    db_user    => $incl->{'user'},
                    db_passwd  => $incl->{'passwd'},
                );
                if (Sympa::Datasource::is_allowed_to_sync(
                        $incl->{'nosync_time_ranges'}
                    )
                    or $source_is_new
                    ) {
                    $log->syslog('debug', 'Is_new %d, syncing',
                        $source_is_new);
                    $included = _include_users_sql(
                        \%users,
                        $source_id,
                        $incl,
                        $db,
                        $self->{'admin'}{'default_user_options'},
                        'untied',
                        $self->{'admin'}{'sql_fetch_timeout'}
                    );
                    unless (defined $included) {
                        push @errors,
                            {'type' => $type, 'name' => $incl->{'name'}};
                    }
                } else {
                    my $exclusion_data = {
                        'id'   => $source_id,
                        'name' => $incl->{'name'},
                    };
                    push @ex_sources, $exclusion_data;
                    $included = 0;
                }
            } elsif ($type eq 'include_ldap_query') {
                my $db = Sympa::Database->new(
                    'LDAP',
                    %$incl,
                    bind_dn       => $incl->{'user'},
                    bind_password => $incl->{'passwd'},
                );
                if (Sympa::Datasource::is_allowed_to_sync(
                        $incl->{'nosync_time_ranges'}
                    )
                    or $source_is_new
                    ) {
                    $included =
                        _include_users_ldap(\%users, $source_id, $incl, $db,
                        $self->{'admin'}{'default_user_options'});
                    unless (defined $included) {
                        push @errors,
                            {'type' => $type, 'name' => $incl->{'name'}};
                    }
                } else {
                    my $exclusion_data = {
                        'id'   => $source_id,
                        'name' => $incl->{'name'},
                    };
                    push @ex_sources, $exclusion_data;
                    $included = 0;
                }
            } elsif ($type eq 'include_ldap_2level_query') {
                my $db = Sympa::Database->new(
                    'LDAP',
                    %$incl,
                    bind_dn       => $incl->{'user'},
                    bind_password => $incl->{'passwd'},
                    timeout => $incl->{'timeout1'},    # Note: not "timeout"
                );
                if (Sympa::Datasource::is_allowed_to_sync(
                        $incl->{'nosync_time_ranges'}
                    )
                    or $source_is_new
                    ) {
                    my $result =
                        _include_users_ldap_2level(\%users, $source_id, $incl,
                        $db, $self->{'admin'}{'default_user_options'});
                    if (defined $result) {
                        $included = $result->{'total'};
                        if (defined $result->{'errors'}) {
                            $log->syslog('err',
                                'Errors occurred during the second LDAP passe'
                            );
                            push @errors,
                                {'type' => $type, 'name' => $incl->{'name'}};
                        }
                    } else {
                        $included = undef;
                        push @errors,
                            {'type' => $type, 'name' => $incl->{'name'}};
                    }
                } else {
                    my $exclusion_data = {
                        'id'   => $source_id,
                        'name' => $incl->{'name'},
                    };
                    push @ex_sources, $exclusion_data;
                    $included = 0;
                }
            } elsif ($type eq 'include_remote_sympa_list') {
                $included =
                    $self->_include_users_remote_sympa_list(\%users, $incl,
                    $self->{'dir'}, $self->{'domain'},
                    $self->{'admin'}{'default_user_options'});
                unless (defined $included) {
                    push @errors,
                        {'type' => $type, 'name' => $incl->{'name'}};
                }
            } elsif ($type eq 'include_sympa_list') {
                if ($self->_inclusion_loop('member', $incl, 'recursive')) {
                    $log->syslog(
                        'err',
                        'Loop detection in list inclusion: could not include again %s in list %s',
                        $incl->{name},
                        $self
                    );
                } else {
                    $included =
                        $self->_include_users_list(\%users, $incl,
                        $self->{'admin'}{'default_user_options'});
                    unless (defined $included) {
                        push @errors,
                            {'type' => $type, 'name' => $incl->{name}};
                    } else {
                        push @depend_on, $incl;
                    }
                }
            } elsif ($type eq 'include_file') {
                $included =
                    _include_users_file(\%users, $incl,
                    $self->{'admin'}{'default_user_options'});
                unless (defined $included) {
                    push @errors, {'type' => $type, 'name' => $incl};
                }
            } elsif ($type eq 'include_remote_file') {
                $included =
                    _include_users_remote_file(\%users, $incl,
                    $self->{'admin'}{'default_user_options'});
                unless (defined $included) {
                    push @errors,
                        {'type' => $type, 'name' => $incl->{'name'}};
                }
            }

            unless (defined $included) {
                $log->syslog('err', 'Inclusion %s failed in list %s',
                    $type, $self);
                next;
            }
            $total += $included;
        }
    }

    ## If an error occurred, return an undef value
    my $result = {
        users      => \%users,
        errors     => \@errors,
        exclusions => \@ex_sources,
        depend_on  => [
            Sympa::Tools::Data::sort_uniq(
                map {
                    my $source_id = lc $_->{listname};
                    $source_id = sprintf '%s@%s', $source_id,
                        $self->{'domain'}
                        unless 0 < index($source_id, '@');
                    $source_id
                } @depend_on
            )
        ],
    };
    ##use Data::Dumper;
    ##if(open OUT, '>/tmp/result') { print OUT Dumper $result; close OUT }
    return $result;
}
## Loads the list of admin users from an external include source
sub _load_list_admin_from_include {
    my $self = shift;
    my $role = shift;
    my $name = $self->{'name'};

    $log->syslog('debug2', '(%s) For list %s', $role, $name);

    my %admin_users;
    my @depend_on;
    my $total      = 0;
    my $list_admin = $self->{'admin'};
    my $dir        = $self->{'dir'};

    foreach my $entry (@{$list_admin->{$role . "_include"}}) {

        next unless (defined $entry);

        my %option;
        $option{'reception'} = $entry->{'reception'}
            if (defined $entry->{'reception'});
        $option{'visibility'} = $entry->{'visibility'}
            if (defined $entry->{'visibility'});
        $option{'profile'} = $entry->{'profile'}
            if (defined $entry->{'profile'} && ($role eq 'owner'));

        my $include_file = Sympa::search_fullpath(
            $self,
            $entry->{'source'} . '.incl',
            subdir => 'data_sources'
        );

        unless (defined $include_file) {
            $log->syslog('err', 'The file %s.incl doesn\'t exist',
                $entry->{'source'});
            return undef;
        }

        my $include_admin_user;
        ## the file has parameters
        if (defined $entry->{'source_parameters'}) {
            my %parsing;

            $parsing{'data'}     = $entry->{'source_parameters'};
            $parsing{'template'} = "$entry->{'source'}\.incl";

            my $name = "$entry->{'source'}\.incl";

            my $include_path = $include_file;
            if ($include_path =~ s/$name$//) {
                $parsing{'include_path'} = $include_path;
                $include_admin_user =
                    $self->_load_include_admin_user_file($include_path,
                    \%parsing);
            } else {
                $log->syslog('err',
                    'Errors to get path of the the file %s.incl',
                    $entry->{'source'});
                return undef;
            }

        } else {
            $include_admin_user =
                $self->_load_include_admin_user_file($include_file);
        }

        foreach my $type (@sources_providing_listmembers) {
            defined $total or last;

            foreach my $tmp_incl (@{$include_admin_user->{$type}}) {

                # Work with a copy of admin hash branch to avoid including
                # temporary variables into the actual admin hash. [bug #3182]
                my $incl = Sympa::Tools::Data::dup_var($tmp_incl);

                # As CA certificate is required, take it from site config.
                if (    ref $incl eq 'HASH'
                    and $incl->{use_tls}
                    and $incl->{use_tls} ne 'none'
                    and not $incl->{ca_file}
                    and not $incl->{ca_path}) {
                    $incl->{ca_file} = $Conf::Conf{'cafile'}
                        if $Conf::Conf{'cafile'};
                    $incl->{ca_path} = $Conf::Conf{'capath'}
                        if $Conf::Conf{'capath'};
                }

                # get the list of admin users
                # does it need to define a 'default_admin_user_option'?
                my $included;
                if (my $plugin = $self->isPlugin($type)) {
                    my $source = $plugin->listSource;
                    $log->syslog(debug => "syncing admins from $type");
                    $included = $source->getListMembers(
                        users         => \%admin_users,
                        settings      => $incl,
                        user_defaults => \%option,
                        admin_only    => 1
                    );
                } elsif ($type eq 'include_sql_query') {
                    my $db = Sympa::Database->new(
                        $incl->{'db_type'},
                        %$incl,
                        db_host    => $incl->{'host'},
                        db_options => $incl->{'connect_options'},
                        db_user    => $incl->{'user'},
                        db_passwd  => $incl->{'passwd'},
                    );
                    $included = _include_users_sql(
                        \%admin_users,
                        Sympa::Datasource::_get_datasource_id($incl),
                        $incl,
                        $db,
                        \%option,
                        'untied',
                        $list_admin->{'sql_fetch_timeout'}
                    );
                } elsif ($type eq 'include_ldap_query') {
                    my $db = Sympa::Database->new(
                        'LDAP',
                        %$incl,
                        bind_dn       => $incl->{'user'},
                        bind_password => $incl->{'passwd'},
                    );
                    $included =
                        _include_users_ldap(\%admin_users,
                        Sympa::Datasource::_get_datasource_id($incl),
                        $incl, $db, \%option);
                } elsif ($type eq 'include_ldap_2level_query') {
                    my $db = Sympa::Database->new(
                        'LDAP',
                        %$incl,
                        bind_dn       => $incl->{'user'},
                        bind_password => $incl->{'passwd'},
                        timeout => $incl->{'timeout1'},  # Note: not "timeout"
                    );
                    my $result =
                        _include_users_ldap_2level(\%admin_users,
                        Sympa::Datasource::_get_datasource_id($incl),
                        $incl, $db, \%option);
                    if (defined $result) {
                        $included = $result->{'total'};
                        if (defined $result->{'errors'}) {
                            $log->syslog('err',
                                'Errors occurred during the second LDAP passe. Please verify your LDAP query.'
                            );
                        }
                    } else {
                        $included = undef;
                    }
                } elsif ($type eq 'include_remote_sympa_list') {
                    $included =
                        $self->_include_users_remote_sympa_list(\%admin_users,
                        $incl, $dir, $self->{'domain'}, \%option);
                } elsif ($type eq 'include_sympa_list') {
                    if ($self->_inclusion_loop($role, $incl, 0)) {
                        #FIXME: Required?
                        $log->syslog(
                            'err',
                            'Loop detection in list inclusion: could not include again %s in %s of %s',
                            $incl->{name},
                            $role,
                            $self
                        );
                    } else {
                        $included =
                            $self->_include_users_list(\%admin_users, $incl,
                            \%option);
                        unless (defined $included) {
                            # push @errors,
                            #    {'type' => $type, 'name' => $incl->{name}};
                        } else {
                            push @depend_on, $incl;
                        }
                    }
                } elsif ($type eq 'include_file') {
                    $included =
                        _include_users_file(\%admin_users, $incl, \%option);
                } elsif ($type eq 'include_remote_file') {
                    $included =
                        _include_users_remote_file(\%admin_users, $incl,
                        \%option);
                } elsif ($type eq 'include_voot_group') {
                    $included =
                        _include_users_voot_group(\%admin_users, $incl,
                        \%option);
                }
                unless (defined $included) {
                    $log->syslog('err', 'Inclusion %s %s failed in list %s',
                        $role, $type, $name);
                    next;
                }
                $total += $included;
            }
        }

        ## If an error occurred, return an undef value
        unless (defined $total) {
            return undef;
        }
    }

    return {
        users     => \%admin_users,
        depend_on => [
            Sympa::Tools::Data::sort_uniq(
                map {
                    my $source_id = lc $_->{listname};
                    $source_id = sprintf '%s@%s', $source_id,
                        $self->{'domain'}
                        unless 0 < index($source_id, '@');
                    $source_id
                } @depend_on
            )
        ],
    };
}

# Load an include admin user file (xx.incl)
#FIXME: Would be merged to _load_list_config_file() which mostly duplicates.
sub _load_include_admin_user_file {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $self    = shift;
    my $file    = shift;
    my $parsing = shift;

    my $robot = $self->{'domain'};

    my $pinfo = {};
    # 'include_list' is kept for comatibility with 6.2.15 or earlier.
    my @sources = (@sources_providing_listmembers, 'include_list');
    @{$pinfo}{@sources} =
        @{Sympa::Robot::list_params($robot) || {}}{@sources};

    my %include;
    my (@paragraphs);

    # the file has parmeters
    if (defined $parsing) {
        my @data = split(',', $parsing->{'data'});
        my $vars = {'param' => \@data};
        my $output = '';

        my $template =
            Sympa::Template->new(undef,
            include_path => [$parsing->{'include_path'}]);
        unless ($template->parse($vars, $parsing->{'template'}, \$output)) {
            $log->syslog('err', 'Failed to parse %s', $parsing->{'template'});
            return undef;
        }

        my @lines = split('\n', $output);

        my $i = 0;
        foreach my $line (@lines) {
            if ($line =~ /^\s*$/) {
                $i++ if $paragraphs[$i];
            } else {
                push @{$paragraphs[$i]}, $line;
            }
        }
    } else {
        my $fh;
        unless (open $fh, '<', $file) {
            $log->syslog('info', 'Cannot open %s', $file);
        }

        ## Just in case...
        local $RS = "\n";

        ## Split in paragraphs
        my $i = 0;
        while (<$fh>) {
            if (/^\s*$/) {
                $i++ if $paragraphs[$i];
            } else {
                push @{$paragraphs[$i]}, $_;
            }
        }
        close $fh;
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
            $log->syslog('info', 'Bad paragraph "%s" in %s',
                @paragraph, $file);
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
                $pname, $file);
            next;
        }

        ## Uniqueness
        if (defined $include{$pname}) {
            unless (($pinfo->{$pname}{'occurrence'} eq '0-n')
                or ($pinfo->{$pname}{'occurrence'} eq '1-n')) {
                $log->syslog('info', 'Multiple parameter "%s" in %s',
                    $pname, $file);
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
                    $file
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
                        $paragraph[$i], $file);
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
                        $key, $pname, $file);
                    next;
                }

                unless ($paragraph[$i] =~
                    /^\s*$key\s+($pinfo->{$pname}{'file_format'}{$key}{'file_format'})\s*$/i
                    ) {
                    chomp($paragraph[$i]);
                    $log->syslog('info',
                        'Bad entry "%s" for key "%s", paragraph "%s" in %s',
                        $paragraph[$i], $key, $pname, $file);
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
                        $hash{$k} =
                            $self->_load_list_param($k, 'default',
                            $pinfo->{$pname}{'file_format'}{$k});
                    }
                }
                ## Required fields
                if ($pinfo->{$pname}{'file_format'}{$k}{'occurrence'} eq '1')
                {
                    unless (defined $hash{$k}) {
                        $log->syslog('info',
                            'Missing key "%s" in param "%s" in %s',
                            $k, $pname, $file);
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
                    $pname, $file);
            }

            unless ($paragraph[0] =~
                /^\s*$pname\s+($pinfo->{$pname}{'file_format'})\s*$/i) {
                chomp($paragraph[0]);
                $log->syslog('info', 'Bad entry "%s" in %s',
                    $paragraph[0], $file);
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

    return \%include;
}

## Returns a ref to an array containing the ids (as computed by
## Sympa::Datasource::_get_datasource_id) of the list of memebers given as
## argument.
sub get_list_of_sources_id {
    my $self                = shift;
    my $list_of_subscribers = shift;

    my %old_subs_id;
    foreach my $old_sub (keys %{$list_of_subscribers}) {
        my $ids = $list_of_subscribers->{$old_sub}{'id'};
        $ids = '' unless defined $ids;
        my @tmp_old_tab = split /,/, $ids;
        foreach my $raw (@tmp_old_tab) {
            $old_subs_id{$raw} = 1;
        }
    }
    return \%old_subs_id;
}

sub sync_include_ca {
    my $self  = shift;
    my $admin = $self->{'admin'};
    my $purge = shift;
    my %users;
    my %changed;

    $self->purge_ca() if ($purge);

    $log->syslog('debug', 'Syncing CA');

    for (
        my $user = $self->get_first_list_member();
        $user;
        $user = $self->get_next_list_member()
        ) {
        $users{$user->{'email'}} = $user->{'custom_attribute'};
    }

    foreach my $type ('include_sql_ca', 'include_ldap_ca',
        'include_ldap_2level_ca') {
        foreach my $tmp_incl (@{$admin->{$type}}) {
            ## Work with a copy of admin hash branch to avoid including
            ## temporary variables into the actual admin hash.[bug #3182]
            my $incl = Sympa::Tools::Data::dup_var($tmp_incl);

            # As CA certificate is required, take it from site config.
            if (    ref $incl eq 'HASH'
                and $incl->{use_tls}
                and $incl->{use_tls} ne 'none'
                and not $incl->{ca_file}
                and not $incl->{ca_path}) {
                $incl->{ca_file} = $Conf::Conf{'cafile'}
                    if $Conf::Conf{'cafile'};
                $incl->{ca_path} = $Conf::Conf{'capath'}
                    if $Conf::Conf{'capath'};
            }

            my $db;
            my $srcca = undef;
            if ($type eq 'include_sql_ca') {
                $db = Sympa::Database->new(
                    $incl->{'db_type'},
                    %$incl,
                    db_host    => $incl->{'host'},
                    db_options => $incl->{'connect_options'},
                    db_user    => $incl->{'user'},
                    db_passwd  => $incl->{'passwd'},
                );
            } elsif ($type eq 'include_ldap_ca'
                or $type eq 'include_ldap_2level_ca') {
                $db = Sympa::Database->new(
                    'LDAP',
                    %$incl,
                    bind_dn       => $incl->{'user'},
                    bind_password => $incl->{'passwd'},
                    timeout => ($incl->{'timeout'} || $incl->{'timeout1'}),
                );
            }
            next unless $db;
            if (Sympa::Datasource::is_allowed_to_sync(
                    $incl->{'nosync_time_ranges'}
                )
                ) {
                my $getter = '_' . $type;
                {    # Magic inside
                    no strict "refs";
                    $srcca = $getter->($incl, $db);
                }
                if (defined($srcca)) {
                    foreach my $email (keys %$srcca) {
                        $users{$email} = {} unless (defined $users{$email});
                        foreach my $key (keys %{$srcca->{$email}}) {
                            next
                                if ($users{$email}{$key}{'value'} eq
                                $srcca->{$email}{$key}{'value'});
                            $users{$email}{$key} = $srcca->{$email}{$key};
                            $changed{$email} = 1;
                        }
                    }
                }
            }
            unless ($db->disconnect()) {
                $log->syslog('notice', 'Can\'t unbind from source %s', $type);
                return undef;
            }
        }
    }

    foreach my $email (keys %changed) {
        if ($self->update_list_member(
                $email, custom_attribute => $users{$email}
            )
            ) {
            $log->syslog('debug', 'Updated user %s', $email);
        } else {
            $log->syslog('err', 'Could not update user %s', $email);
        }
    }

    return 1;
}

### Purge synced custom attributes from user records, only keep user writable
### ones
sub purge_ca {
    my $self  = shift;
    my $admin = $self->{'admin'};
    my %userattributes;
    my %users;

    $log->syslog('debug', 'Purge CA');

    foreach my $attr (@{$admin->{'custom_attribute'}}) {
        $userattributes{$attr->{'id'}} = 1;
    }

    for (
        my $user = $self->get_first_list_member();
        $user;
        $user = $self->get_next_list_member()
        ) {
        next unless (keys %{$user->{'custom_attribute'}});
        my $attributes;
        foreach my $id (keys %{$user->{'custom_attribute'}}) {
            next unless (defined $userattributes{$id});
            $attributes->{$id} = $user->{'custom_attribute'}{$id};
        }
        $users{$user->{'email'}} = $attributes;
    }

    foreach my $email (keys %users) {
        if ($self->update_list_member(
                $email, custom_attribute => $users{$email}
            )
            ) {
            $log->syslog('debug', 'Updated user %s', $email);
        } else {
            $log->syslog('err', 'Could not update user %s', $email);
        }
    }

    return 1;
}

sub sync_include {
    $log->syslog('debug', '(%s, %s)', @_);
    my $self   = shift;
    my $option = shift;

    my %old_subscribers;
    my $total           = 0;
    my $errors_occurred = 0;

    ## Load a hash with the old subscribers
    for (
        my $user = $self->get_first_list_member();
        $user;
        $user = $self->get_next_list_member()
        ) {
        $old_subscribers{lc($user->{'email'})} = $user;

        ## User neither included nor subscribed = > set subscribed to 1
        unless ($old_subscribers{lc($user->{'email'})}{'included'}
            || $old_subscribers{lc($user->{'email'})}{'subscribed'}) {
            $log->syslog('notice',
                'Update user %s neither included nor subscribed',
                $user->{'email'});
            unless (
                $self->update_list_member(
                    lc($user->{'email'}),
                    update_date => time,
                    subscribed  => 1
                )
                ) {
                $log->syslog(
                    'err', '(%s) Failed to update %s',
                    $self, lc($user->{'email'})
                );
                next;
            }
            $old_subscribers{lc($user->{'email'})}{'subscribed'} = 1;
        }

        $total++;
    }

    ## Load a hash with the new subscriber list
    my $new_subscribers;
    unless ($option and $option eq 'purge') {
        my $result =
            $self->_load_list_members_from_include(
            $self->get_list_of_sources_id(\%old_subscribers))
            || {};
        $new_subscribers = $result->{'users'};
        my @errors     = @{$result->{'errors'}};
        my @exclusions = @{$result->{'exclusions'}};
        my @depend_on  = @{$result->{depend_on} || []};

        ## If include sources were not available, do not update subscribers
        ## Use DB cache instead and warn the listmaster.
        if (@errors) {
            $log->syslog(
                'err',
                'Errors occurred while synchronizing datasources for list %s',
                $self
            );
            $errors_occurred = 1;
            Sympa::send_notify_to_listmaster($self, 'sync_include_failed',
                {'errors' => \@errors});
            foreach my $e (@errors) {
                my $plugin = $self->isPlugin($e->{type}) or next;
                my $source = $plugin->listSource;
                $source->reportListError($self, $e->{name});
            }
            return undef;
        }

        # Feed the new_subscribers hash with users previously subscribed
        # with data sources not used because we were not in the period of
        # time during which synchronization is allowed. This will prevent
        # these users from being unsubscribed.
        if (@exclusions) {
            foreach my $ex_sources (@exclusions) {
                my $id = $ex_sources->{'id'};
                foreach my $email (keys %old_subscribers) {
                    if ($old_subscribers{$email}{'id'} =~ /$id/g) {
                        $new_subscribers->{$email}{'date'} =
                            $old_subscribers{$email}{'date'};
                        $new_subscribers->{$email}{'update_date'} =
                            $old_subscribers{$email}{'update_date'};
                        $new_subscribers->{$email}{'visibility'} =
                            $self->get_default_user_options->{'visibility'}
                            if defined $self->get_default_user_options->{
                            'visibility'};
                        $new_subscribers->{$email}{'reception'} =
                            $self->get_default_user_options->{'reception'}
                            if defined $self->get_default_user_options->{
                            'reception'};
                        $new_subscribers->{$email}{'profile'} =
                            $self->get_default_user_options->{'profile'}
                            if defined $self->get_default_user_options->{
                            'profile'};
                        $new_subscribers->{$email}{'info'} =
                            $self->get_default_user_options->{'info'}
                            if
                            defined $self->get_default_user_options->{'info'};
                        if (defined $new_subscribers->{$email}{'id'}
                            && $new_subscribers->{$email}{'id'} ne '') {
                            $new_subscribers->{$email}{'id'} = join(',',
                                split(',', $new_subscribers->{$email}{'id'}),
                                $id);
                        } else {
                            $new_subscribers->{$email}{'id'} =
                                $old_subscribers{$email}{'id'};
                        }
                    }
                }
            }
        }

        # Update inclusion dependency (added on 6.2.16).
        $self->_update_inclusion_table('member', @depend_on);
    }

    my $data_exclu;
    my @subscriber_exclusion;

    ## Gathering a list of emails for a the list in 'exclusion_table'
    $data_exclu = $self->get_exclusion();

    my $key = 0;
    while ($data_exclu->{'emails'}->[$key]) {
        push @subscriber_exclusion, $data_exclu->{'emails'}->[$key];
        $key = $key + 1;
    }

    my $users_added   = 0;
    my $users_updated = 0;

    ## Get an Exclusive lock
    my $lock_fh =
        Sympa::LockedFile->new($self->{'dir'} . '/include', 10 * 60, '+');
    unless ($lock_fh) {
        $log->syslog('err', 'Could not create new lock');
        return undef;
    }

    ## Go through previous list of users
    my $users_removed = 0;
    my $user_removed;
    my @deltab;
    foreach my $email (keys %old_subscribers) {
        unless (defined($new_subscribers->{$email})) {
            ## User is also subscribed, update DB entry
            if ($old_subscribers{$email}{'subscribed'}) {
                $log->syslog('debug', 'Updating %s to list %s', $email,
                    $self);
                unless (
                    $self->update_list_member(
                        $email,
                        update_date => time,
                        included    => 0,
                        id          => ''
                    )
                    ) {
                    $log->syslog('err', '(%s) Failed to update %s',
                        $self, $email);
                    next;
                }

                $users_updated++;

                ## Tag user for deletion
            } else {
                $log->syslog('debug3', 'Removing %s from list %s',
                    $email, $self);
                @deltab = ($email);
                unless ($user_removed =
                    $self->delete_list_member('users' => \@deltab)) {
                    $log->syslog('err', '(%s) Failed to delete %s',
                        $self, $user_removed);
                    return undef;
                }
                if ($user_removed) {
                    $users_removed++;
                    ## Send notification if the list config authorizes it
                    ## only.
                    if ($self->{'admin'}{'inclusion_notification_feature'} eq
                        'on') {
                        unless (
                            Sympa::send_file($self, 'removed', $email, {})) {
                            $log->syslog('err',
                                "Unable to send template 'removed' to $email"
                            );
                        }
                    }
                }
            }
        }
    }
    if ($users_removed > 0) {
        $log->syslog('notice', '(%s) %d users removed', $self,
            $users_removed);
    }

    ## Go through new users
    my @add_tab;
    $users_added = 0;
    foreach my $email (keys %{$new_subscribers}) {
        my $compare = 0;
        foreach my $sub_exclu (@subscriber_exclusion) {
            if ($email eq $sub_exclu) {
                $compare = 1;
                last;
            }
        }
        if ($compare == 1) {
            delete $new_subscribers->{$email};
            next;
        }
        if (defined($old_subscribers{$email})) {
            if ($old_subscribers{$email}{'included'}) {
                ## If one user attribute has changed, then we should update
                ## the user entry
                my $succesful_update = 0;
                foreach my $attribute ('id', 'gecos') {
                    unless (
                        Sympa::Tools::Data::smart_eq(
                            $old_subscribers{$email}{$attribute},
                            $new_subscribers->{$email}{$attribute}
                        )
                        ) {
                        $log->syslog('debug', 'Updating %s to list %s',
                            $email, $self);
                        my $update_time =
                            $new_subscribers->{$email}{'update_date'} || time;
                        unless (
                            $self->update_list_member(
                                $email,
                                update_date => $update_time,
                                $attribute =>
                                    $new_subscribers->{$email}{$attribute}
                            )
                            ) {
                            $log->syslog('err', '(%s) Failed to update %s',
                                $self, $email);
                            next;
                        } else {
                            $succesful_update = 1;
                        }
                    }
                }
                $users_updated++ if ($succesful_update);
                ## User was already subscribed, update
                ## include_sources_subscriber in DB
            } else {
                $log->syslog('debug', 'Updating %s to list %s', $email,
                    $self);
                unless (
                    $self->update_list_member(
                        $email,
                        update_date => time,
                        included    => 1,
                        id          => $new_subscribers->{$email}{id}
                    )
                    ) {
                    $log->syslog('err', '(%s) Failed to update %s',
                        $self, $email);
                    next;
                }
                $users_updated++;
            }

            ## Add new included user
        } else {
            my $compare = 0;
            foreach my $sub_exclu (@subscriber_exclusion) {
                unless ($compare eq '1') {
                    if ($email eq $sub_exclu) {
                        $compare = 1;
                    } else {
                        next;
                    }
                }
            }
            if ($compare eq '1') {
                next;
            }
            $log->syslog('debug3', 'Adding %s to list %s', $email, $self);
            my $u = $new_subscribers->{$email};
            $u->{'included'} = 1;
            $u->{'date'}     = time;
            @add_tab         = ($u);
            my $user_added = 0;
            unless ($user_added = $self->add_list_member(@add_tab)) {
                $log->syslog('err', '(%s) Failed to add new users', $self);
                return undef;
            }
            if ($user_added) {
                $users_added++;
                ## Send notification if the list config authorizes it only.
                if ($self->{'admin'}{'inclusion_notification_feature'} eq
                    'on') {
                    unless (
                        $self->send_probe_to_user('welcome', $u->{'email'})) {
                        $log->syslog('err',
                            'Unable to send "welcome" probe to %s',
                            $u->{'email'});
                    }
                }
            }
        }
    }

    if ($users_added) {
        $log->syslog('notice', '(%s) %d users added', $self, $users_added);
    }

    $log->syslog('notice', '(%s) %d users updated', $self, $users_updated);

    ## Release lock
    unless ($lock_fh->close()) {
        return undef;
    }

    ## Get and save total of subscribers
    $self->{'total'}     = $self->_load_total_db('nocache');
    $self->{'last_sync'} = time;
    $self->savestats();
    $self->sync_include_ca($option and $option eq 'purge');

    return 1;
}

# Update inclusion_table: This feature was added on 6.2.16.
sub _update_inclusion_table {
    my $self      = shift;
    my $role      = shift;
    my @depend_on = @_;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    my $now = time;
    foreach my $list_id (@depend_on) {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{UPDATE inclusion_table
                  SET update_epoch_inclusion = ?
                  WHERE target_inclusion = ? AND
                        role_inclusion = ? AND
                        source_inclusion = ? AND
                        (update_epoch_inclusion IS NULL OR
                         update_epoch_inclusion < ?)},
                $now, $self->get_id, $role, $list_id, $now
            )
            and $sth->rows
            or $sdm and $sth = $sdm->do_prepared_query(
                q{INSERT INTO inclusion_table
                  (target_inclusion, role_inclusion, source_inclusion,
                   update_epoch_inclusion)
                  VALUES (?, ?, ?, ?)},
                $self->get_id, $role, $list_id, $now
            )
            and $sth->rows
            ) {
            $log->syslog('err', 'Unable to update list %s in database',
                $self);
            return undef;
        }
    }
    $sdm->do_prepared_query(
        q{DELETE FROM inclusion_table
          WHERE target_inclusion = ? AND role_inclusion = ? AND
                update_epoch_inclusion < ?},
        $self->get_id, $role, $now
    );
}

## The previous function (sync_include) is to be called by the task_manager.
## This one is to be called from anywhere else. This function deletes the
## scheduled
## sync_include task. If this deletion happened in sync_include(), it would
## disturb
## the normal task_manager.pl functionning.

# 6.2.4: Returns 0 if synchronization is not needed.
sub on_the_fly_sync_include {
    my $self    = shift;
    my %options = @_;

    my $pertinent_ttl = $self->{'admin'}{'distribution_ttl'}
        || $self->{'admin'}{'ttl'};
    $log->syslog('debug2', '(%s)', $pertinent_ttl);
    if (not $options{'use_ttl'}
        or $self->{'last_sync'} < time - $pertinent_ttl) {
        $log->syslog('notice', "Synchronizing list members...");
        my $return_value = $self->sync_include();
        if ($return_value) {
            $self->remove_task('sync_include');
            return 1;
        } else {
            return $return_value;
        }
    }
    return 0;
}

sub sync_include_admin {
    my ($self) = shift;
    my $option = shift;

    my $name = $self->{'name'};
    $log->syslog('debug2', '(%s)', $name);

    ## don't care about listmaster role
    foreach my $role ('owner', 'editor') {
        ## Load a hash with the old admin users
        my $old_admin_users =
            {map { ($_->{'email'} => $_) } $self->get_admins($role)};

        ## Load a hash with the new admin user list from an include source(s)
        my $new_admin_users_include;
        ## Load a hash with the new admin user users from the list config
        my $new_admin_users_config;
        unless ($option and $option eq 'purge') {
            my $result = $self->_load_list_admin_from_include($role) || {};
            $new_admin_users_include = $result->{users};
            my @depend_on = @{$result->{depend_on} || []};

            ## If include sources were not available, do not update admin
            ## users
            ## Use DB cache instead
            unless (defined $new_admin_users_include) {
                $log->syslog('err',
                    'Could not get %ss from an include source for list %s',
                    $role, $self);
                Sympa::send_notify_to_listmaster($self,
                    'sync_include_admin_failed', {});
                return undef;
            }

            $new_admin_users_config =
                $self->_load_list_admin_from_config($role);

            unless (defined $new_admin_users_config) {
                $log->syslog('err',
                    'Could not get %ss from config for list %s',
                    $role, $name);
                return undef;
            }

            # Update inclusion dependency (added on 6.2.16).
            $self->_update_inclusion_table($role, @depend_on);
        }

        my @add_tab;
        my $admin_users_added   = 0;
        my $admin_users_updated = 0;

        ## Get an Exclusive lock
        my $lock_fh =
            Sympa::LockedFile->new($self->{'dir'} . '/include_admin_user',
            20, '+');
        unless ($lock_fh) {
            $log->syslog('err', 'Could not create new lock');
            return undef;
        }

        ## Go through new admin_users_include
        foreach my $email (keys %{$new_admin_users_include}) {

            # included and subscribed
            if (defined $new_admin_users_config->{$email}) {
                my $param;
                foreach my $p ('reception', 'visibility', 'gecos', 'info',
                    'profile') {
                    #  config parameters have priority on include parameters
                    #  in case of conflict
                    $param->{$p} = $new_admin_users_config->{$email}{$p}
                        if (defined $new_admin_users_config->{$email}{$p});
                    $param->{$p} ||= $new_admin_users_include->{$email}{$p};
                }

                #Admin User was already in the DB
                if (defined $old_admin_users->{$email}) {

                    $param->{'included'} = 1;
                    $param->{'id'} = $new_admin_users_include->{$email}{'id'};
                    $param->{'subscribed'} = 1;

                    my $param_update =
                        is_update_param($param, $old_admin_users->{$email});

                    # updating
                    if (defined $param_update) {
                        if (%{$param_update}) {
                            $log->syslog('debug', 'Updating %s %s to list %s',
                                $role, $email, $name);
                            $param_update->{'update_date'} = time;

                            unless (
                                $self->update_list_admin(
                                    $email, $role, $param_update
                                )
                                ) {
                                $log->syslog('err',
                                    '(%s) Failed to update %s %s',
                                    $name, $role, $email);
                                next;
                            }
                            $admin_users_updated++;
                        }
                    }
                    # for the next foreach (sort of new_admin_users_config
                    # that are not included)
                    delete($new_admin_users_config->{$email});

                    # add a new included and subscribed admin user
                } else {
                    $log->syslog('debug2', 'Adding %s %s to list %s',
                        $email, $role, $name);

                    foreach my $key (keys %{$param}) {
                        $new_admin_users_config->{$email}{$key} =
                            $param->{$key};
                    }
                    $new_admin_users_config->{$email}{'included'}   = 1;
                    $new_admin_users_config->{$email}{'subscribed'} = 1;
                    push(@add_tab, $new_admin_users_config->{$email});

                    # for the next foreach (sort of new_admin_users_config
                    # that are not included)
                    delete($new_admin_users_config->{$email});
                }

                # only included
            } else {
                my $param = $new_admin_users_include->{$email};

                #Admin User was already in the DB
                if (defined($old_admin_users->{$email})) {

                    $param->{'included'} = 1;
                    $param->{'id'} = $new_admin_users_include->{$email}{'id'};
                    $param->{'subscribed'} = 0;

                    my $param_update =
                        is_update_param($param, $old_admin_users->{$email});

                    # updating
                    if (defined $param_update) {
                        if (%{$param_update}) {
                            $log->syslog('debug', 'Updating %s %s to list %s',
                                $role, $email, $name);
                            $param_update->{'update_date'} = time;

                            unless (
                                $self->update_list_admin(
                                    $email, $role, $param_update
                                )
                                ) {
                                $log->syslog('err',
                                    '(%s) Failed to update %s %s',
                                    $name, $role, $email);
                                next;
                            }
                            $admin_users_updated++;
                        }
                    }
                    # add a new included admin user
                } else {
                    $log->syslog('debug2', 'Adding %s %s to list %s',
                        $role, $email, $name);

                    foreach my $key (keys %{$param}) {
                        $new_admin_users_include->{$email}{$key} =
                            $param->{$key};
                    }
                    $new_admin_users_include->{$email}{'included'} = 1;
                    push(@add_tab, $new_admin_users_include->{$email});
                }
            }
        }

        ## Go through new admin_users_config (that are not included : only
        ## subscribed)
        foreach my $email (keys %{$new_admin_users_config}) {

            my $param = $new_admin_users_config->{$email};

            #Admin User was already in the DB
            if (defined($old_admin_users->{$email})) {

                $param->{'included'}   = 0;
                $param->{'id'}         = '';
                $param->{'subscribed'} = 1;
                my $param_update =
                    is_update_param($param, $old_admin_users->{$email});

                # updating
                if (defined $param_update) {
                    if (%{$param_update}) {
                        $log->syslog('debug', 'Updating %s %s to list %s',
                            $role, $email, $name);
                        $param_update->{'update_date'} = time;

                        unless (
                            $self->update_list_admin(
                                $email, $role, $param_update
                            )
                            ) {
                            $log->syslog('err', '(%s) Failed to update %s %s',
                                $name, $role, $email);
                            next;
                        }
                        $admin_users_updated++;
                    }
                }
                # add a new subscribed admin user
            } else {
                $log->syslog('debug2', 'Adding %s %s to list %s',
                    $role, $email, $name);

                foreach my $key (keys %{$param}) {
                    $new_admin_users_config->{$email}{$key} = $param->{$key};
                }
                $new_admin_users_config->{$email}{'subscribed'} = 1;
                push(@add_tab, $new_admin_users_config->{$email});
            }
        }

        if ($#add_tab >= 0) {
            unless ($admin_users_added =
                $self->add_list_admin($role, @add_tab)) {
                $log->syslog('err', 'Failed to add new %s(s) to list %s',
                    $role, $self);
                return undef;
            }
        }

        if ($admin_users_added) {
            $log->syslog('debug', '(%s) %d %s(s) added',
                $name, $admin_users_added, $role);
        }

        $log->syslog('debug', '(%s) %d %s(s) updated',
            $name, $admin_users_updated, $role);

        ## Go though old list of admin users
        my $admin_users_removed = 0;
        my @deltab;

        foreach my $email (keys %$old_admin_users) {
            unless (defined($new_admin_users_include->{$email})
                || defined($new_admin_users_config->{$email})) {
                $log->syslog('debug2', 'Removing %s %s to list %s',
                    $role, $email, $name);
                push(@deltab, $email);
            }
        }

        if ($#deltab >= 0) {
            unless ($admin_users_removed =
                $self->delete_list_admin($role, @deltab)) {
                $log->syslog('err', '(%s) Failed to delete %s %s',
                    $name, $role, $admin_users_removed);
                return undef;
            }
            $log->syslog('debug', '(%s) %d %s(s) removed',
                $name, $admin_users_removed, $role);
        }

        ## Release lock
        unless ($lock_fh->close()) {
            return undef;
        }
    }

    $self->{'last_sync_admin_user'} = time;
    $self->savestats();

    return scalar @{$self->get_admins('owner')};
}

## Load param admin users from the config of the list
sub _load_list_admin_from_config {
    my $self = shift;
    my $role = shift;
    my $name = $self->{'name'};
    my %admin_users;

    $log->syslog('debug2', '(%s) For list %s', $role, $name);

    foreach my $entry (@{$self->{'admin'}{$role}}) {
        my $email = lc($entry->{'email'});
        my %u;

        $u{'email'}      = $email;
        $u{'reception'}  = $entry->{'reception'};
        $u{'visibility'} = $entry->{'visibility'};
        $u{'gecos'}      = $entry->{'gecos'};
        $u{'info'}       = $entry->{'info'};
        $u{'profile'}    = $entry->{'profile'} if ($role eq 'owner');

        $admin_users{$email} = \%u;
    }
    return \%admin_users;
}

## return true if new_param has changed from old_param
#  $new_param is changed to return only entries that need to
# be updated (only deals with admin user parameters, editor or owner)
sub is_update_param {
    my $new_param = shift;
    my $old_param = shift;
    my $resul     = {};
    my $update    = 0;

    $log->syslog('debug2', '');

    foreach my $p (
        'reception', 'visibility', 'gecos',    'info',
        'profile',   'id',         'included', 'subscribed'
        ) {
        if (defined $new_param->{$p}) {
            if (!defined($old_param->{$p})
                or $new_param->{$p} ne $old_param->{$p}) {
                $resul->{$p} = $new_param->{$p};
                $update = 1;
            }
        } else {
            if (defined $old_param->{$p} and $old_param->{$p} ne '') {
                $resul->{$p} = '';
                $update = 1;
            }
        }
    }
    if ($update) {
        return $resul;
    } else {
        return undef;
    }
}

# Checks if adding a include_sympa_list setting will cause inclusion loop.
#FIXME:Isn't there any more efficient way to explore DAG?
sub _inclusion_loop {
    my $self      = shift;
    my $role      = shift || 'member';
    my $incl      = shift;
    my $recursive = shift;

    my $source_id = lc $incl->{listname};
    $source_id = sprintf '%s@%s', $source_id, $self->{'domain'}
        unless 0 < index($source_id, '@');
    my $target_id = $self->get_id;

    unless ($recursive) {
        return ($source_id eq $target_id);
    }

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    my %visited;
    my @ancestors = ($source_id);
    while (@ancestors) {
        # Loop detected.
        return 1
            if grep { $target_id eq $_ } @ancestors;

        @visited{@ancestors} = @ancestors;
        @ancestors = Sympa::Tools::Data::sort_uniq(
            grep {
                # Ignore loop by other nodes to prevent infinite processing.
                not exists $visited{$_}
                } map {
                my @parents;
                if ($sdm
                    and $sth = $sdm->do_prepared_query(
                        q{SELECT source_inclusion
                          FROM inclusion_table
                          WHERE target_inclusion = ? AND role_inclusion = ?},
                        $_, $role
                    )
                    ) {
                    @parents =
                        map { $_->[0] } @{$sth->fetchall_arrayref([0]) || []};
                    $sth->finish;
                }
                @parents
                } @ancestors
        );
    }

    return 0;
}

sub _load_total_db {
    my $self   = shift;
    my $option = shift;
    $log->syslog('debug2', '(%s)', $self->{'name'});

    ## Use session cache
    if (($option ne 'nocache')
        && (defined $list_cache{'load_total_db'}{$self->{'domain'}}
            {$self->{'name'}})
        ) {
        return $list_cache{'load_total_db'}{$self->{'domain'}}
            {$self->{'name'}};
    }

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    ## Query the Database
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT count(*)
              FROM subscriber_table
              WHERE list_subscriber = ? AND robot_subscriber = ?},
            $self->{'name'}, $self->{'domain'}
        )
        ) {
        $log->syslog('debug', 'Unable to get subscriber count for list %s@%s',
            $self->{'name'}, $self->{'domain'});
        return undef;
    }

    my $total = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    ## Set session cache
    $list_cache{'load_total_db'}{$self->{'domain'}}{$self->{'name'}} = $total;

    return $total;
}

## Writes the user list to disk
sub _save_list_members_file {
    my ($self, $file) = @_;
    $log->syslog('debug3', '(%s)', $file);

    my ($k, $s);

    $log->syslog('debug2', 'Saving user file %s', $file);

    rename("$file", "$file.old");
    open my $fh, '>', $file or return undef;

    for (
        $s = $self->get_first_list_member();
        $s;
        $s = $self->get_next_list_member()
        ) {
        foreach $k (
            'date',      'update_date', 'email', 'gecos',
            'reception', 'visibility'
            ) {
            printf $fh "%s %s\n", $k, $s->{$k}
                if defined $s->{$k} and length $s->{$k};

        }
        print $fh "\n";
    }
    close $fh;
    return 1;
}

## Does the real job : stores the message given as an argument into
## the digest of the list.
# Moved to Sympa::Spool::Digest::store().
#sub store_digest;

=over 4

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

=back

=cut

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

=over 4

=item get_lists( [ $that, [ options, ... ] ] )

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

=back

=cut

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
        @robot_ids   = ($that->{'robot'});
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
        push @clause_sql, q{family_list LIKE '$family_name'};
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
                push @keys_perl, sprintf '$b->{"total"} <=> $a->{"total"}';
            } else {
                push @keys_perl, sprintf '$a->{"total"} <=> $b->{"total"}';
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
                    {   skip_sync_admin => ($which_role ? 1 : 0),
                        %options,
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
                    {   skip_sync_admin => ($which_role ? 1 : 0),
                        %options,
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
        next unless (($r !~ /^\./o) && (-d "$Conf::Conf{'home'}/$r"));
        next unless (-r "$Conf::Conf{'etc'}/$r/robot.conf");
        push @robots, $r;
        undef $use_default_robot if ($r eq $Conf::Conf{'domain'});
    }
    closedir DIR;

    push @robots, $Conf::Conf{'domain'} if ($use_default_robot);
    return @robots;
}

=over 4

=item get_which ( EMAIL, ROBOT, ROLE )

I<Function>.
Get a list of lists where EMAIL assumes this ROLE (owner, editor or member) of
function to any list in ROBOT.

=back

=cut

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

# DEPRECATED: Use {status} attribute of Sympa::SharedDocument instance.
#sub get_shared_status;

# DEPRECATED: Use Sympa::SharedDocument::get_moderated_descendants().
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
sub by_order {
    (($Sympa::ListDef::pinfo{$main::a || ''}{'order'} || 0)
        <=> ($Sympa::ListDef::pinfo{$main::b || ''}{'order'} || 0))
        || (($main::a || '') cmp($main::b || ''));
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

    my $robot     = $self->{'domain'};
    my $directory = $self->{'dir'};

    ## Empty value
    if ($value =~ /^\s*$/) {
        return undef;
    }

    ## Default
    if ($value eq 'default') {
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
        $value =~ y/,/_/;
        my $scenario = Sympa::Scenario->new(
            'function'  => $p->{'scenario'},
            'robot'     => $robot,
            'name'      => $value,
            'directory' => $directory
        );

        ## We store the path of the scenario in the sstructure
        ## Later Sympa::Scenario::request_action() will look for the scenario in
        ## %Sympa::Scenario::all_scenarios through Scenario::new()
        $value = {
            'file_path' => $scenario->{'file_path'},
            'name'      => $scenario->{'name'}
        };
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
    # needs to send mail to the list; if he ever gets anything signed,
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
                    /^\s*$key\s+($pinfo->{$pname}{'file_format'}{$key}{'file_format'})\s*$/i
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
                        $hash{$k} =
                            $self->_load_list_param($k, 'default',
                            $pinfo->{$pname}{'file_format'}{$k});
                    }
                }

                ## Required fields
                if ($pinfo->{$pname}{'file_format'}{$k}{'occurrence'} eq '1')
                {
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
                /^\s*$pname\s+($pinfo->{$pname}{'file_format'})\s*$/i) {
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
        if (   $pinfo->{$p}{'occurrence'}
            && $pinfo->{$p}{'occurrence'} =~ /^1(-n)?$/) {
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
        delete $config_hash->{'defaults'}{'include_sympa_list'};
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

    foreach my $key (sort by_order keys %{$self->{'admin'}}) {

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
# Use Sympa::Message::compute_topic() and Sympa::Topic::store() instead.
#sub automatic_tag;

# Moved to Sympa::Message::compute_topic().
#sub compute_topic;

# DEPRECATED.  Use Sympa::Topic::store() instead.
#sub tag_topic;

# DEPRECATED.  Use Sympa::Topic::load() instead.
#sub load_msg_topic_file;

# Moved to _notify_deleted_topic() in wwsympa.fcgi.
#sub modifying_msg_topic_for_list_members;

####################################################
# select_list_members_for_topic
####################################################
# Select users subscribed to a topic that is in
# the topic list incoming when reception mode is 'mail', 'notice', 'not_me',
# 'txt', 'html' or 'urlize', and the other
# subscribers (recpetion mode different from 'mail'), 'mail' and no topic
# subscription
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

# OBSOLETED: Use Sympa::SharedDocument::get_size().
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

## Searches the include datasource corresponding to the provided ID
sub search_datasource {
    my ($self, $id) = @_;
    $log->syslog('debug2', '(%s, %s)', $self->{'name'}, $id);

    ## Go through list parameters
    foreach my $p (keys %{$self->{'admin'}}) {
        next unless ($p =~ /^include/);

        ## Go through sources
        foreach my $s (@{$self->{'admin'}{$p}}) {
            if (Sympa::Datasource::_get_datasource_id($s) eq $id) {
                return {'type' => $p, 'def' => $s};
            }
        }
    }

    return undef;
}

## Return the names of datasources, given a coma-separated list of source ids
# IN : -$class
#      -$id : datasource ids (coma-separated)
# OUT : -$name : datasources names (scalar)
sub get_datasource_name {
    my ($self, $id) = @_;
    $log->syslog('debug2', '(%s, %s)', $self->{'name'}, $id);
    my %sources;

    my @ids = split /,/, $id;
    foreach my $id (@ids) {
        ## User may come twice from the same datasource
        unless (defined($sources{$id})) {
            my $datasource = $self->search_datasource($id);
            if (defined $datasource) {
                if (ref($datasource->{'def'})) {
                    $sources{$id} = $datasource->{'def'}{'name'}
                        || $datasource->{'def'}{'host'};
                } else {
                    $sources{$id} = $datasource->{'def'};

                    if (    $datasource->{'type'} eq 'include_list'
                        and $sources{$id} =~ /^([^\s]+)\s+filter/) {
                        $sources{$id} = $1 . '>filtered';
                    }
                }
            }
        }
    }

    return join(', ', values %sources);
}

## Remove a task in the tasks spool
sub remove_task {
    my $self = shift;
    my $task = shift;

    unless (opendir(DIR, $Conf::Conf{'queuetask'})) {
        $log->syslog(
            'err',
            'Can\'t open dir %s: %m',
            $Conf::Conf{'queuetask'}
        );
        return undef;
    }
    my @tasks = grep !/^\.\.?$/, readdir DIR;
    closedir DIR;

    foreach my $task_file (@tasks) {
        if ($task_file =~
            /^(\d+)\.\w*\.$task\.$self->{'name'}\@$self->{'domain'}$/) {
            unless (unlink("$Conf::Conf{'queuetask'}/$task_file")) {
                $log->syslog('err', 'Unable to remove task file %s: %m',
                    $task_file);
                return undef;
            }
            $log->syslog('notice', 'Removing task file %s', $task_file);
        }
    }

    return 1;
}

## Close the list (remove from DB, remove aliases, change status to 'closed'
## or 'family_closed')
sub close_list {
    my ($self, $email, $status) = @_;

    return undef
        unless ($self
        && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));

    # If list is included by another list, then it cannot be removed.
    if ($self->is_included) {
        $log->syslog('err',
            'List %s is included by other list: cannot close it', $self);
        return undef;
    }

    ## Dump subscribers, unless list is already closed
    unless ($self->{'admin'}{'status'} eq 'closed') {
        $self->_save_list_members_file(
            "$self->{'dir'}/subscribers.closed.dump");
    }

    ## Delete users
    my @users;
    for (
        my $user = $self->get_first_list_member();
        $user;
        $user = $self->get_next_list_member()
        ) {
        push @users, $user->{'email'};
    }
    $self->delete_list_member('users' => \@users);

    ## Remove entries from admin_table
    foreach my $role (qw(editor owner)) {
        $self->delete_list_admin($role, $self->get_admins_email($role));
    }

    ## Change status & save config
    $self->{'admin'}{'status'} = 'closed';

    if (defined $status) {
        foreach my $s ('family_closed', 'closed') {
            if ($status eq $s) {
                $self->{'admin'}{'status'} = $status;
                last;
            }
        }
    }

    $self->{'admin'}{'defaults'}{'status'} = 0;

    $self->save_config($email);
    $self->savestats();

    $self->remove_aliases();

    #log in stat_table to make staistics
    $log->add_stat(
        'robot'     => $self->{'domain'},
        'list'      => $self->{'name'},
        'operation' => 'close_list',
        'parameter' => '',
        'mail'      => $email,
    );

    return 1;
}

## Remove the list
sub purge {
    my ($self, $email) = @_;

    return undef
        unless ($self
        && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));

    ## Remove tasks for this list
    Sympa::Task::list_tasks($Conf::Conf{'queuetask'});
    foreach my $task (Sympa::Task::get_tasks_by_list($self->get_id)) {
        unlink $task->{'filepath'};
    }

    ## Close the list first, just in case...
    $self->close_list();

    if ($self->{'name'}) {
        #FIXME: Lock directories to remove them safely.
        my $error;
        File::Path::remove_tree($self->get_archive_dir, {error => \$error});
        File::Path::remove_tree($self->get_digest_spool_dir,
            {error => \$error});
        File::Path::remove_tree($self->get_bounce_dir, {error => \$error});
    }

    ## Clean list table if needed
    #if ($Conf::Conf{'db_list_cache'} eq 'on') {
    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{DELETE FROM list_table
                  WHERE name_list = ? AND robot_list = ?},
            $self->{'name'}, $self->{'domain'}
        )
        ) {
        $log->syslog('err', 'Cannot remove list %s from table', $self);
    }
    #}
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{DELETE FROM inclusion_table
              WHERE target_inclusion = ?},
            $self->get_id
        )
        ) {
        $log->syslog('err', 'Cannot remove list %s from table', $self);
    }

    ## Clean memory cache
    delete $list_of_lists{$self->{'domain'}}{$self->{'name'}};

    Sympa::Tools::File::remove_dir($self->{'dir'});

    #log ind stat table to make statistics
    $log->add_stat(
        'robot'     => $self->{'domain'},
        'list'      => $self->{'name'},
        'operation' => 'purge_list',
        'parameter' => '',
        'mail'      => $email
    );

    return 1;
}

## Remove list aliases
sub remove_aliases {
    my $self = shift;

    return undef
        unless $self
        and $list_of_lists{$self->{'domain'}}{$self->{'name'}}
        and Conf::get_robot_conf($self->{'domain'}, 'sendmail_aliases') !~
        /^none$/i;

    my $alias_manager = $Conf::Conf{'alias_manager'};

    unless (-x $alias_manager) {
        $log->syslog('err', 'Cannot run alias_manager %s', $alias_manager);
        return undef;
    }

    my $status =
        system($alias_manager, 'del', $self->{'name'},
        $self->{'admin'}{'host'}) >> 8;
    if ($status) {
        $log->syslog('err', 'Failed to remove aliases; status %d: %m',
            $status);
        return undef;
    }

    $log->syslog('info', 'Aliases for list %s removed successfully',
        $self->{'name'});

    return 1;
}

##
## bounce management actions
##

# Sub for removing user
#
sub remove_bouncers {
    my $self   = shift;
    my $reftab = shift;
    $log->syslog('debug', '(%s)', $self->{'name'});

    ## Log removal
    foreach my $bouncer (@{$reftab}) {
        $log->syslog('notice', 'Removing bouncing subsrciber of list %s: %s',
            $self->{'name'}, $bouncer);
    }

    unless (
        $self->delete_list_member(
            'users'     => $reftab,
            'exclude'   => '1',
            'operation' => 'auto_del'
        )
        ) {
        $log->syslog('info', 'Error while calling sub delete_users');
        return undef;
    }
    return 1;
}

# Sub for notifying users: "Be careful, you're bouncing".
sub notify_bouncers {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self   = shift;
    my $reftab = shift;

    foreach my $user (@$reftab) {
        $log->syslog('notice', 'Notifying bouncing subsrciber of list %s: %s',
            $self, $user);
        Sympa::send_notify_to_user($self, 'auto_notify_bouncers', $user);
    }
    return 1;
}

# DDEPRECATED: Use Sympa::SharedDocument::create().
#sub create_shared;

## check if a list  has include-type data sources
sub has_include_data_sources {
    my $self = shift;

    foreach my $type (@sources_providing_listmembers, @more_data_sources) {
        my $resource = $self->{'admin'}{$type} || [];
        return 1 if ref $resource eq 'ARRAY' && @$resource;
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

=over 4

=item get_list_address ( [ TYPE ] )

OBSOLETED.
Use L<Sympa/"get_address">.

Return the list email address of type TYPE: posting address (default),
"owner", "editor" or (non-VERP) "return_path".

=back

=cut

# OBSOLETED. Merged into Sympa::get_address().
sub get_list_address {
    goto &Sympa::get_address;    # "&" is required.
}

=over 4

=item get_bounce_address ( WHO, [ OPTS, ... ] )

Return the VERP address of the list for the user WHO.

FIXME: VERP addresses have the name of originating robot, not mail host.

=back

=cut

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

=over 4

=item get_id ( )

Return the list ID, different from the list address (uses the robot name)

=back

=cut

sub get_id {
    my $self = shift;

    return '' unless $self->{'name'} and $self->{'domain'};
    return $self->{'name'} . '@' . $self->{'domain'};
}

# OBSOLETED: use get_id()
sub get_list_id { shift->get_id }

=over 4

=item add_list_header ( $message, $field_type )

FIXME @todo doc

=back

=cut

sub add_list_header {
    my $self    = shift;
    my $message = shift;
    my $field   = shift;

    my $robot = $self->{'domain'};

    if ($field eq 'id') {
        $message->add_header('List-Id',
            sprintf('<%s.%s>', $self->{'name'}, $self->{'admin'}{'host'}));
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

            my @now  = localtime(time);
            my $yyyy = sprintf '%04d', 1900 + $now[5];
            my $mm   = sprintf '%02d', $now[4] + 1;
            $message->add_header(
                'Archived-At',
                sprintf(
                    '<%s>',
                    Sympa::get_url(
                        $self, 'arcsearch_id',
                        paths => ["$yyyy-$mm", $message_id]
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
    unless ($self->has_include_data_sources) {
        $sdm and $sdm->do_prepared_query(
            q{DELETE FROM inclusion_table
              WHERE target_inclusion = ?},
            $self->get_id
        );
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

    my $pinfo = Sympa::Robot::list_params($self->{'domain'});

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

=head2 Pluggin data-sources

=head3 $obj->includes(DATASOURCE, [NEW])

More abstract accessor for $list->include_DATASOURCE.  It will return
a LIST of the data.  You may pass a NEW single or ARRAY of values.

NOTE: As on this version accessor methods have not been implemented yet,
so $list->{'admin'}->{"include_DATASOURCE"}->(...) is used instead.

=cut

sub includes($;$) {
    my $self   = shift;
    my $source = 'include_' . shift;
    if (@_) {
        my $data = ref $_[0] ? shift : [shift];
        return $self->{'admin'}->{$source}->($data);
    }
    @{$self->{'admin'}{$source} || []};
}

=head3 $class->registerPlugin(CLASS)

CLASS must extend L<Sympa::Plugin::ListSource>

=cut

# We have own plugin administration, not using the Sympa::Plugin::Manager
# until all 'include_' labels are abstracted out into objects.
my %plugins;

sub registerPlugin($$) {
    my ($class, $impl) = @_;
    my $source = 'include_' . $impl->listSourceName;
    push @sources_providing_listmembers, $source;
    $plugins{$source} = $impl;
}

=head3 $obj->isPlugin(DATASOURCE)

=cut

sub isPlugin($) { $plugins{$_[1]} }

###### END of the List package ######

1;

__END__

## This package handles Sympa virtual robots
## It should :
##   * provide access to global conf parameters,
##   * deliver the list of lists
##   * determine the current robot, given a host
package Robot;

use Conf;

## Constructor of a Robot instance
sub new {
    my ($pkg, $name) = @_;

    my $robot = {'name' => $name};
    $log->syslog('debug2', '');

    unless (defined $name && $Conf::Conf{'robots'}{$name}) {
        $log->syslog('err', 'Unknown robot "%s"', $name);
        return undef;
    }

    ## The default robot
    if ($name eq $Conf::Conf{'domain'}) {
        $robot->{'home'} = $Conf::Conf{'home'};
    } else {
        $robot->{'home'} = $Conf::Conf{'home'} . '/' . $name;
        unless (-d $robot->{'home'}) {
            $log->syslog('err', 'Missing directory "%s" for robot "%s"',
                $robot->{'home'}, $name);
            return undef;
        }
    }

    ## Initialize internal list cache
    undef %list_cache;

    # create a new Robot object
    bless $robot, $pkg;

    return $robot;
}

## load all lists belonging to this robot
sub get_lists {
    my $self = shift;

    return Sympa::List::get_lists($self->{'name'});
}

###### END of the Robot package ######

1;
