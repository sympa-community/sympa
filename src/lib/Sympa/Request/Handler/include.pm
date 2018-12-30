# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 201X The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Request::Handler::include;

use strict;
use warnings;

use Sympa;
use Sympa::DatabaseManager;
use Sympa::DataSource;
use Sympa::LockedFile;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

my %config_ca_map = (
    'include_ldap_ca'        => 'Sympa::DataSource::LDAP',
    'include_ldap_2level_ca' => 'Sympa::DataSource::LDAP2',
    'include_sql_ca'         => 'Sympa::DataSource::SQL',
);

my %config_user_map = (
    'include_file'              => 'Sympa::DataSource::File',
    'include_remote_file'       => 'Sympa::DataSource::RemoteFile',
    'include_list'              => 'Sympa::DataSource::List',      # Obsoleted
    'include_sympa_list'        => 'Sympa::DataSource::List',
    'include_remote_sympa_list' => 'Sympa::DataSource::RemoteDump',
    'include_ldap_query'        => 'Sympa::DataSource::LDAP',
    'include_ldap_2level_query' => 'Sympa::DataSource::LDAP2',
    'include_sql_query'         => 'Sympa::DataSource::SQL',
    'include_voot_group'        => 'Sympa::DataSource::VOOT',
);

sub _get_data_sources {
    my $list = shift;
    my $role = shift;

    my @dss;

    if ($role eq 'custom_attribute') {
        foreach my $ptype (sort keys %config_ca_map) {
            my @config = grep {$_} @{$list->{'admin'}{$ptype} || []};
            my $type = $config_ca_map{$ptype};
            push @dss, map {
                Sympa::DataSource->new($type, $role, context => $list, %$_)
            } @config;
        }
    } elsif ($role eq 'member') {
        my @config_files = map { $list->_load_include_admin_user_file($_) }
            @{$list->{'admin'}{'member_include'} || []};

        foreach my $ptype (sort keys %config_user_map) {
            my @config = grep {$_} (
                @{$list->{'admin'}{$ptype} || []},
                map { @{$_->{$ptype} || []} } @config_files
            );
            # Special case: include_file is not paragraph.
            if ($ptype eq 'include_file') {
                @config = map { {name => $_, path => $_} } @config;
            }
            my $type = $config_user_map{$ptype};
            push @dss, map {
                Sympa::DataSource->new($type, $role, context => $list, %$_)
            } @config;
        }
    } else {
        my $pname = ($role eq 'owner') ? 'owner_include' : 'editor_include';
        my @config_files = map { $list->_load_include_admin_user_file($_) }
            @{$list->{'admin'}{$pname} || []};

        foreach my $ptype (sort keys %config_user_map) {
            my @config = grep {$_}
                map { @{$_->{$ptype} || []} } @config_files;
            # Special case: include_file is not paragraph.
            if ($ptype eq 'include_file') {
                @config = map { {name => $_, path => $_} } @config;
            }
            my $type = $config_user_map{$ptype};
            push @dss, map {
                Sympa::DataSource->new($type, $role, context => $list, %$_)
            } @config;
        }
    }

    return [@dss];
}

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list = $request->{context};
    my $role = $request->{role};

    die 'bug in logic. Ask developer'
        unless grep { $role and $role eq $_ } qw(member owner editor);

    my $dss = _get_data_sources($list, $role);
    return 0 unless $dss and @$dss;

    # Get an Exclusive lock.
    my $lock_file = $list->{'dir'} . '/' . $role . '.include';
    my $lock_fh = Sympa::LockedFile->new($lock_file, -1, '+>>');
    unless ($lock_fh) {
        $log->syslog('info', '%s: Locked, skip inclusion', $list);
        $self->add_stash($request, 'notice', 'include_skip',
            {listname => $list->{'name'}});
        return 0;
    }

    my $sdm = Sympa::DatabaseManager->instance;
    return undef unless $sdm;
    my $sth;
    my ($t, $r) =
          ($role eq 'member')
        ? ('subscriber', '')
        : ('admin', sprintf ' AND role_admin = %s', $sdm->quote($role));

    # I. Start.

    my %sync_starts;
    seek $lock_fh, 0, 0;
    while (my $line = <$lock_fh>) {
        $sync_starts{$1} = $2 + 0 if $line =~ /\A(\w+)\s+(\d+)/;
    }
    my $sync_start = time;

    # II. Include new entries.

    my %result = (added => 0, deleted => 0, updated => 0, kept => 0);
    foreach my $ds (@{$dss || []}) {
        $lock_fh->extend;

        next unless $ds->is_allowed_to_sync;
        my %res = _sync_ds($ds, $sync_start);
        next unless %res;

        # Update time of allowed and succeeded data sources.
        $sync_starts{$ds->get_short_id} = $sync_start;

        $log->syslog(
            'info', '%s: %d included, %d deleted, %d updated, %d kept',
            $ds,    @res{qw(added deleted updated kept)}
        );
        $self->add_stash(
            $request, 'notice',
            'include',
            {   listname => $list->{'name'},
                id       => $ds->get_short_id,
                name     => $ds->name,
                result   => {%res}
            }
        );
        foreach my $key (keys %res) {
            $result{$key} += $res{$key} if exists $result{$key};
        }
    }

    # III. Expire outdated entries.

    # Choose most earlier time of succeeding inclusions (if any of
    # data sources have not succeeded yet, Unix epoch will be chosen).
    my $last_start = $sync_start;
    foreach my $id (map { $_->get_short_id } @$dss) {
        unless (defined $sync_starts{$id}) {
            undef $last_start;
            last;
        } elsif ($sync_starts{$id} < $last_start) {
            $last_start = $sync_starts{$id};
        }
    }

    if (defined $last_start) {
        # Remove list users not subscribing (only included) and
        # not included anymore.
        $lock_fh->extend;
        unless (
            $sth = $sdm->do_prepared_query(
                qq{SELECT user_$t AS email
                   FROM ${t}_table
                   WHERE (subscribed_$t IS NULL OR subscribed_$t <> 1) AND
                         inclusion_$t IS NOT NULL AND inclusion_$t < ? AND
                         list_$t = ? AND robot_$t = ?$r},
                $last_start,
                $list->{'name'}, $list->{'domain'}
            )
        ) {
            #FIXME: report error
            $self->add_stash($request, 'intern');
            return undef;
        } else {
            my @emails = map { $_->[0] } @{$sth->fetchall_arrayref || []};
            $sth->finish;

            foreach my $email (@emails) {
                next unless defined $email and length $email;

                if ($role eq 'member') {
                    $list->delete_list_member(users => [$email]);

                    # Send notification if the list config authorizes it only.
                    if ($list->{'admin'}{'inclusion_notification_feature'} eq
                        'on') {
                        unless (
                            Sympa::send_file($list, 'removed', $email, {})) {
                            $log->syslog('err',
                                'Unable to send template "removed" to %s',
                                $email);
                        }
                    }
                } else {
                    $list->delete_list_admin($role, $email);
                }
                $result{deleted} += 1;
            }
        }

        # Cancel inclusion of users subscribing (and also included) and
        # not included anymore.
        unless (
            $sdm->do_prepared_query(
                qq{UPDATE ${t}_table
                   SET inclusion_$t = NULL, inclusion_ext_$t = NULL
                   WHERE subscribed_$t = 1 AND
                         inclusion_$t IS NOT NULL AND inclusion_$t < ? AND
                         list_$t = ? AND robot_$t = ?$r},
                $last_start,
                $list->{'name'}, $list->{'domain'}
            )
            and $sdm->do_prepared_query(
                qq{UPDATE ${t}_table
                   SET inclusion_ext_$t = NULL
                   WHERE subscribed_$t = 1 AND
                         inclusion_ext_$t IS NOT NULL AND
                         inclusion_ext_$t < ? AND
                         list_$t = ? AND robot_$t = ?$r},
                $last_start,
                $list->{'name'}, $list->{'domain'}
            )
        ) {
            #FIXME: report error
        }

        # Special treatment for Sympa::DataSource::List.
        _clean_inclusion_table($list, $role, $last_start);
    }

    # IV. Update custom attributes.

    if ($role eq 'member') {
        my $dss = _get_data_sources($list, 'custom_attribute');
        if ($dss and @$dss) {
            foreach my $ds (@{$dss || []}) {
                $lock_fh->extend;

                _sync_ds($ds) if $ds->is_allowed_to_sync;
            }
        }
    }

    # V. Finish.

    # Write out updated times of succeeding inclusions.
    my $ofh;
    unless (open $ofh, '>', $lock_file . '.new') {
        $log->syslog('err', 'Can\'t open file %s: %m', $lock_file . '.new');
        $self->add_stash($request, 'intern');
        return undef;
    }
    foreach my $id (map { $_->get_short_id } @$dss) {
        printf $ofh "%s %d\n", $id, $sync_starts{$id}
            if defined $sync_starts{$id};
    }
    close $ofh;
    unlink $lock_file . '.old';
    unless ($lock_fh->rename($lock_file . '.old')
        and rename($lock_file . '.new', $lock_file)) {
        $log->syslog('err', 'Can\'t update file %s: %m', $lock_file);
        $self->add_stash($request, 'intern');
        return undef;
    }
    unlink $lock_file . '.old';

    $log->syslog(
        'info',   '%s: %d included, %d deleted, %d updated',
        $request, @result{qw(added deleted updated)}
    );
    $self->add_stash($request, 'notice', 'include_performed',
        {listname => $list->{'name'}, result => {%result}});
    return 1;
}

sub _sync_ds {
    my $ds         = shift;
    my $sync_start = shift;

    return unless $ds->open;

    my %result = (added => 0, deleted => 0, updated => 0, kept => 0);
    while (my $entry = $ds->next) {
        my ($email, $other_value) = @$entry;
        my %res =
            ($ds->role eq 'custom_attribute')
            ? _sync_ds_ca($ds, $email, $other_value)
            : _sync_ds_user($ds, $email, $other_value, $sync_start);

        unless (%res) {
            $ds->close;
            $log->syslog('info', '%s: Aborted sync', $ds);
            return;
        }
        foreach my $res (keys %res) {
            $result{$res} += $res{$res} if exists $result{$res};
        }
    }
    unless ($ds->role eq 'custom_attribute') {
        # Special treatment for Sympa::DataSource::List.
        _update_inclusion_table($ds, $sync_start)
            if ref $ds eq 'Sympa::DataSource::List';
    }

    $ds->close;

    return %result;
}

# Internal function.
sub _sync_ds_ca {
    my $ds        = shift;
    my $email     = shift;
    my $ca_update = shift;

    my $list   = $ds->{context};
    my $member = $list->get_list_member($email);
    return unless $member;
    my $ca = $member->{custom_attribute} || {};

    my $changed;
    foreach my $key (sort keys %{$ca_update || {}}) {
        my $cur = $ca->{$key};
        $cur = '' unless defined $cur;
        my $new = $ca_update->{$key};
        $new = '' unless defined $new;
        next if $cur eq $new;

        $ca->{$key} = $new;
        $changed = 1;
    }
    return (kept => 1) unless $changed;

    $list->update_list_member($email, custom_attribute => $ca_update);

    return (updated => 1);
}

# Internal function.
sub _sync_ds_user {
    my $ds         = shift;
    my $email      = shift;
    my $gecos      = shift;
    my $sync_start = shift;

    return (none => 0) unless Sympa::Tools::Text::valid_email($email);
    $email = Sympa::Tools::Text::canonic_email($email);

    my $list = $ds->{context};
    my $role = $ds->role;

    my $time = time;
    # Avoid retrace of clock e.g. by outage of NTP server.
    $time = $sync_start unless $sync_start <= time;

    my $sdm = Sympa::DatabaseManager->instance;
    return undef unless $sdm;
    my $sth;
    my ($t, $r) =
          ($role eq 'member')
        ? ('subscriber', '')
        : ('admin', sprintf ' AND role_admin = %s', $sdm->quote($role));
    my $is_external_ds = not(ref $ds eq 'Sympa::DataSource::List'
        and [split /\@/, $ds->{listname}, 2]->[1] eq $list->{'domain'});

    # 1. If role of the data source is 'member' and the user is excluded:
    #    Do nothing.
    return (none => 0)
        if $role eq 'member' and $list->is_member_excluded($email);

    # 2. If user has already been updated by the other data sources:
    #    Keep user.
    if ($is_external_ds) {
        return unless $sth = $sdm->do_prepared_query(
            qq{SELECT COUNT(*)
               FROM ${t}_table
               WHERE user_$t = ? AND list_$t = ? AND robot_$t = ?$r AND
                     inclusion_$t IS NOT NULL AND ? <= inclusion_$t AND
                     inclusion_ext_$t IS NOT NULL AND ? <= inclusion_ext_$t},
            $email,      $list->{'name'}, $list->{'domain'},
            $sync_start, $sync_start
        );
    } else {
        return unless $sth = $sdm->do_prepared_query(
            qq{SELECT COUNT(*)
               FROM ${t}_table
               WHERE user_$t = ? AND list_$t = ? AND robot_$t = ?$r AND
                     inclusion_$t IS NOT NULL AND ? <= inclusion_$t},
            $email, $list->{'name'}, $list->{'domain'},
            $sync_start
        );
    }
    my ($count) = $sth->fetchrow_array;
    $sth->finish;
    return (kept => 1) if $count;

    # 3. If user (has not been updated by the other data sources and) exists:
    #    UPDATE inclusion.
    if ($is_external_ds) {
        return unless $sth = $sdm->do_prepared_query(
            qq{UPDATE ${t}_table
               SET inclusion_$t = ?, inclusion_ext_$t = ?
               WHERE user_$t = ? AND list_$t = ? AND robot_$t = ?$r},
            $time, $time,
            $email, $list->{'name'}, $list->{'domain'}
        );
    } else {
        return unless $sth = $sdm->do_prepared_query(
            qq{UPDATE ${t}_table
               SET inclusion_$t = ?
               WHERE user_$t = ? AND list_$t = ? AND robot_$t = ?$r},
            $time,
            $email, $list->{'name'}, $list->{'domain'}
        );
    }
    return (updated => 1) if $sth->rows;    #FIXME: Duplicate counts

    # 4. Otherwise, i.e. a new user:
    #    INSERT new user with:
    #    email, gecos, subscribed=0, date, update, inclusion and
    #    default attributes.
    my $user = {
        email       => $email,
        gecos       => $gecos,
        subscribed  => 0,
        date        => $time,
        update_date => $time,
        inclusion   => $time,
        ($is_external_ds ? (inclusion_ext => $time) : ()),
    };
    my @defkeys = @{$ds->{_defkeys} || []};
    my @defvals = @{$ds->{_defvals} || []};
    @{$user}{@defkeys} = @defvals if @defkeys;

    if ($role eq 'member') {
        $list->add_list_member($user);

        # Send notification if the list config authorizes it only.
        if ($list->{'admin'}{'inclusion_notification_feature'} eq 'on') {
            unless ($list->send_probe_to_user('welcome', $email)) {
                $log->syslog('err',
                    'Unable to send "welcome" probe to %s', $email);
            }
        }
    } else {
        $list->add_list_admin($role, $user);
    }
    return (added => 1);
}

# Update inclusion_table: This feature was added on 6.2.16.
# Related only to Sympa::DataSource::List class.
# Old name: (part of) Sympa::List::_update_inclusion_table().
sub _update_inclusion_table {
    my $ds         = shift;
    my $sync_start = shift;

    my $list   = $ds->{context};
    my $role   = $ds->role;
    my $inlist = Sympa::List->new($ds->{listname});

    my $time = time;
    # Avoid retrace of clock e.g. by outage of NTP server.
    $time = $sync_start unless $sync_start <= $time;

    my $sdm = Sympa::DatabaseManager->instance;
    return undef unless $sdm;
    my $sth;

    unless (
        $sth = $sdm->do_prepared_query(
            q{UPDATE inclusion_table
              SET update_epoch_inclusion = ?
              WHERE target_inclusion = ? AND
                    role_inclusion = ? AND
                    source_inclusion = ? AND
                    (update_epoch_inclusion IS NULL OR
                     update_epoch_inclusion < ?)},
            $time, $list->get_id, $role, $inlist->get_id, $time
        )
        and $sth->rows
        or $sth = $sdm->do_prepared_query(
            q{INSERT INTO inclusion_table
              (target_inclusion, role_inclusion, source_inclusion,
               update_epoch_inclusion)
              VALUES (?, ?, ?, ?)},
            $list->get_id, $role, $inlist->get_id, $time
        )
        and $sth->rows
    ) {
        $log->syslog('err', 'Unable to update list %s in database', $list);
        return undef;
    }

    return 1;
}

# Old name: (part of) Sympa::List::_update_inclusion_table().
# Related only to Sympa::DataSource::List class.
sub _clean_inclusion_table {
    my $list       = shift;
    my $role       = shift;
    my $sync_start = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    $sdm and $sdm->do_prepared_query(
        q{DELETE FROM inclusion_table
          WHERE target_inclusion = ? AND role_inclusion = ? AND
                update_epoch_inclusion < ?},
        $list->get_id, $role, $sync_start
    );
}

# Enforce uniqueness in a comma separated list of user source ID's.
# Old name: (part of) Sympa::List::add_source_id().
# No longer used.
#sub _add_source_id;

# Returns a real unique ID for an include datasource.
sub get_id {
    shift->{context};
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Hander::include - include request handler

=head1 DESCRIPTION

Includes users from data sources to a list.

Opens data sources, synchronizes list users with each of them and closes.
TBD.

=head1 SEE ALSO

L<Sympa::DataSource>, L<Sympa::List>.

L<"admin_table"|sympa_database(5)/"admin_table">,
L<"exclusion_table"|sympa_database(5)/"exclusion_table">,
L<"inclusion_table"|sympa_database(5)/"inclusion_table"> and
L<"subscriber_table"|sympa_database(5)/"subscriber_table">
in L<sympa_database(5)>.

=head1 HISTORY

The feature to include subscribers from data sources was introduced on
Sympa 3.3.6b.4.
Inclusion of owners and moderators was introduced on Sympa 4.2b.5.

L<Datasource> module appeared on Sympa 5.3a.9.
Entirely rewritten and renamed L<Sympa::DataSource> module and
L<Sympa::Request::Hander::include> module appeared on Sympa 6.2.XX.

=cut
