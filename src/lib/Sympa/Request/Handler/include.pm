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
    my $lock_fh =
        Sympa::LockedFile->new($list->{'dir'} . '/include.' . $role, -1, '+');
    unless ($lock_fh) {
        $log->syslog('info', '%s: Locked, skip syncing', $list);
        $self->add_stash($request, 'notice', 'sync_include_skip',
            {listname => $list->{'name'}});
        return 0;
    }

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    # Start sync.
    my $sync_start = time;

    foreach my $ds (@{$dss || []}) {
        $lock_fh->extend;

        $ds->{_sync_start} = $sync_start;
        if ($ds->is_allowed_to_sync) {
            my %result = _sync_ds($ds);
            if (%result) {
                $log->syslog('info',
                    '%s: %d included, %d deleted, %d updated, %d kept',
                    $ds, @result{qw(added deleted updated kept)});
                $self->add_stash(
                    $request, 'notice',
                    'include',
                    {   listname => $list->{'name'},
                        id       => $ds->get_short_id,
                        name     => $ds->name,
                        result   => {%result}
                    }
                );
                next;
            }
        }

        # Preserve users with failed or disallowed data sources:
        # Update update_date column of existing rows.
        my $id = $ds->get_short_id;

        if ($role eq 'member') {
            unless (
                $sdm
                and $sdm->do_prepared_query(
                    q{UPDATE subscriber_table
                      SET update_epoch_subscriber = ?
                      WHERE include_sources_subscriber LIKE ? AND
                            update_epoch_subscriber < ? AND
                            list_subscriber = ? AND robot_subscriber = ?},
                    $sync_start,
                    '%' . $id . '%',
                    $sync_start,
                    $list->{'name'}, $list->{'domain'}
                )
            ) {
                #FIXME: report error
                $self->add_stash($request, 'intern');
                return undef;    # Abort sync
            }
        } else {
            unless (
                $sdm
                and $sdm->do_prepared_query(
                    q{UPDATE admin_table
                      SET update_epoch_admin = ?
                      WHERE include_sources_admin LIKE ? AND
                            update_epoch_admin < ? AND
                            list_admin = ? AND robot_admin = ? AND
                            role_admin = ?},
                    $sync_start,
                    '%' . $id . '%',
                    $sync_start,
                    $list->{'name'}, $list->{'domain'},
                    $role
                )
            ) {
                #FIXME: report error
                $self->add_stash($request, 'intern');
                return undef;    # Abort sync
            }
        }
    }

    # Remove list users not updated anymore.
    $lock_fh->extend;
    if ($role eq 'member') {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT user_subscriber AS email
                  FROM subscriber_table
                  WHERE (subscribed_subscriber <> 1 OR
                         subscribed_subscriber IS NULL) AND
                        included_subscriber = 1 AND
                        update_epoch_subscriber < ? AND
                        list_subscriber = ? AND robot_subscriber = ?},
                $sync_start,
                $list->{'name'}, $list->{'domain'}
            )
        ) {
            #FIXME: report error
        } else {
            my @emails = map { $_->[0] } @{$sth->fetchall_arrayref || []};
            $sth->finish;

            foreach my $email (@emails) {
                next unless defined $email and length $email;

                $list->delete_list_member(users => [$email]);

                # Send notification if the list config authorizes it only.
                if ($list->{'admin'}{'inclusion_notification_feature'} eq
                    'on') {
                    unless (Sympa::send_file($list, 'removed', $email, {})) {
                        $log->syslog('err',
                            'Unable to send template "removed" to %s',
                            $email);
                    }
                }
            }
        }

        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{UPDATE subscriber_table
                  SET included_subscriber = 0,
                      include_sources_subscriber = NULL
                  WHERE subscribed_subscriber = 1 AND
                        included_subscriber = 1 AND
                        update_epoch_subscriber < ? AND
                        list_subscriber = ? AND robot_subscriber = ?},
                $sync_start,
                $list->{'name'}, $list->{'domain'}
            )
        ) {
            #FIXME: report error
        }

        my $dss = _get_data_sources($list, 'custom_attribute');
        if ($dss and @$dss) {
            foreach my $ds (@{$dss || []}) {
                $lock_fh->extend;

                _sync_ds($ds) if $ds->is_allowed_to_sync;
            }
        }
    } else {
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT user_admin AS email
                  FROM admin_table
                  WHERE (subscribed_admin <> 1 OR
                         subscribed_admin IS NULL) AND
                        included_admin = 1 AND
                        update_epoch_admin < ? AND
                        list_admin = ? AND robot_admin = ? AND
                        role_admin = ?},
                $sync_start,
                $list->{'name'}, $list->{'domain'},
                $role
            )
        ) {
            #FIXME: report error
        } else {
            my @emails = map { $_->[0] } @{$sth->fetchall_arrayref || []};
            $sth->finish;

            foreach my $email (@emails) {
                next unless defined $email and length $email;

                $list->delete_list_admin($role, $email);
            }
        }

        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{UPDATE admin_table
                  SET included_admin = 0,
                      include_sources_admin = NULL
                  WHERE subscribed_admin = 1 AND
                        included_admin = 1 AND
                        update_epoch_admin < ? AND
                        list_admin = ? AND robot_admin = ? AND
                        role_admin = ?},
                $sync_start,
                $list->{'name'}, $list->{'domain'},
                $role
            )
        ) {
            #FIXME: report error
        }
    }

    # Special treatment for Sympa::DataSource::List.
    _clean_inclusion_table($list, $role, $sync_start);

    # Release lock.
    $lock_fh->close;

    $log->syslog('notice', '%s: include succeeded', $list);
    $self->add_stash($request, 'notice', 'performed');
    return 1;
}

sub _sync_ds {
    my $ds = shift;

    return unless $ds->open;

    my %result = (added => 0, deleted => 0, updated => 0, kept => 0);
    while (my $entry = $ds->next) {
        my ($email, $other_value) = @$entry;
        my %res =
            ($ds->role eq 'custom_attribute')
            ? _sync_ds_ca($ds, $email, $other_value)
            : _sync_ds_user($ds, $email, $other_value);
        foreach my $res (qw(added deleted updated kept)) {
            $result{$res} += $res{$res};
        }
    }
    unless ($ds->role eq 'custom_attribute') {
        # Special treatment for Sympa::DataSource::List.
        _update_inclusion_table($ds) if ref $ds eq 'Sympa::DataSource::List';
    }

    $ds->close;

    return %result;
}

# Internal function.
sub sync_ds_ca {
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
    my $ds    = shift;
    my $email = shift;
    my $gecos = shift;

    my $list = $ds->{context};
    my $role = $ds->role;

    my $sync_start = $ds->{_sync_start} || time;
    my $time = time;
    # Avoid retrace of clock e.g. by outage of NTP server.
    $time = $sync_start unless $sync_start <= $time;

    # Assign user options.
    my %update = (
        gecos       => $gecos,
        update_date => $time,
    );
    my @defkeys = @{$ds->{_defkeys} || []};
    my @defvals = @{$ds->{_defvals} || []};
    @update{@defkeys} = @defvals if @defkeys;

    #FIXME Following process is not atomic!
    # Check if user has already been included.
    my $user;
    if ($role eq 'member') {
        $user = $list->get_list_member($email);
    } else {
        ($user) = @{$list->get_admins($role, filter => [email => $email])};
    }
    if ($user) {
        $log->syslog('debug3', 'Ignore %s because already a user', $email);
        my $new_ids = _add_source_id($user->{id} || '', $ds->get_short_id);

        if ($role eq 'member') {
            # Remove excluded members.
            if ($list->is_member_excluded($email)) {
                if ($user->{subscribed}) {
                    $list->update_list_member(
                        $email,
                        included => 0,
                        id       => ''
                    );
                    return (kept => 1);
                }

                $list->delete_list_member(users => [$email]);

                # Send notification if the list config authorizes it only.
                if ($list->{'admin'}{'inclusion_notification_feature'} eq
                    'on') {
                    unless (Sympa::send_file($list, 'removed', $email, {})) {
                        $log->syslog('err',
                            'Unable to send template "removed" to %s',
                            $email);
                    }
                }
                return (deleted => 1);
            }

            $list->update_list_member(
                $email,
                included => 1,
                id       => $new_ids,
                %update
            );
        } else {
            $list->update_list_admin(
                $email, $role,
                included => 1,
                id       => $new_ids,
                %update
            );
        }
        return (updated => 1);
    } else {
        $log->syslog('debug3', 'Add new subscriber %s', $email);

        if ($role eq 'member') {
            # Skip excluded members.
            if ($list->is_member_excluded($email)) {
                return 0;
            }

            $list->add_list_member(
                {   email      => $email,
                    subscribed => 0,
                    included   => 1,
                    id         => $ds->get_short_id,
                    %update,
                }
            );

            # Send notification if the list config authorizes it only.
            if ($list->{'admin'}{'inclusion_notification_feature'} eq 'on') {
                unless ($list->send_probe_to_user('welcome', $email)) {
                    $log->syslog('err',
                        'Unable to send "welcome" probe to %s', $email);
                }
            }
        } else {
            $list->add_list_admin(
                $role,
                {   email      => $email,
                    subscribed => 0,
                    included   => 1,
                    id         => $ds->get_short_id,
                    %update,
                }
            );
        }
        return (added => 1);
    }
}

# Update inclusion_table: This feature was added on 6.2.16.
# Related only to Sympa::DataSource::List class.
# Old name: (part of) Sympa::List::_update_inclusion_table().
sub _update_inclusion_table {
    my $ds = shift;

    my $list   = $ds->{context};
    my $role   = $ds->role;
    my $inlist = Sympa::List->new($ds->{listname});

    my $time = time;
    my $sync_start = $ds->{_sync_start} or return;
    $time = $sync_start if $time < $sync_start;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

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
            $time, $list->get_id, $role, $inlist->get_id, $time
        )
        and $sth->rows
        or $sdm and $sth = $sdm->do_prepared_query(
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
sub _add_source_id {
    my $idlist = shift;
    my $newid  = shift;

    # make a list of all id's, including the new one
    my @ids = split(',', $idlist);
    push @ids, $newid;

    # suppress duplicates
    my %seen;
    return join(',', grep { !$seen{$_}++ } @ids);
}

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
