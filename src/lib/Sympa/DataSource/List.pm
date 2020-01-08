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

package Sympa::DataSource::List;

use strict;
use warnings;

use Conf;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Template;
use Sympa::Tools::Data;

use base qw(Sympa::DataSource);

my $log = Sympa::Log->instance;

sub _new {
    my $class   = shift;
    my %options = @_;

    my $self = $class->SUPER::_new(%options);
    return undef unless $self;

    my $list = $self->{context};
    if (ref $list eq 'Sympa::List') {
        my $inlist = Sympa::List->new($self->{listname}, $list->{'domain'},
            {just_try => 1});
        $self->{listname} = $inlist->get_id if $inlist;
    }

    return $self;
}

sub _open {
    my $self = shift;

    # The included list is local or in another local robot.
    my $inlist = Sympa::List->new($self->{listname});
    return undef unless $inlist;

    # Check inclusion loop.
    my $list = $self->{context};
    if (ref $list eq 'Sympa::List'
        and _inclusion_loop(
            $list, $self->role,
            $inlist, ($self->role eq 'member') ? 'recursive' : 0
        )
    ) {
        $log->syslog(
            'err',
            'Loop detection in list inclusion: could not include again %s in list %s',
            $self,
            $list
        );
        return undef;
    }

    $self->{_read} = 0;

    return $inlist;
}

# Checks if adding a include_sympa_list setting will cause inclusion loop.
#FIXME:Isn't there any more efficient way to explore DAG?
# Old name: Sympa::List::_inclusion_loop().
sub _inclusion_loop {
    my $list      = shift;
    my $role      = shift || 'member';
    my $inlist    = shift;
    my $recursive = shift;

    my $source_id = $inlist->get_id;
    my $target_id = $list->get_id;

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

# Old name: (part of) Sympa::List::_include_users_list().
sub _next {
    my $self = shift;

    my $list   = $self->{context};
    my $robot  = $list->{'domain'};
    my $filter = $self->{filter};

    if (defined $filter and length $filter) {
        $filter =~ s/\A\s+//;
        $filter =~ s/\s+\z//;
        $filter =~ s{\A((?:USE\s[^;]+;)*)\s*(.+)}
            {[% TRY %][% $1 %][%IF $2 %]1[%END%][% CATCH %][% error %][%END%]};
        $log->syslog('debug3', 'Applying filter on data source: %s: %s',
            $self, $filter);
    }

    my $inlist = $self->__dsh;
    while (
        my $user = (
              $self->{_read}
            ? $inlist->get_next_list_member
            : $inlist->get_first_list_member
        )
    ) {
        $self->{_read} = 1;

        # Do we need filtering ?
        if (defined $filter and length $filter) {
            my $variables = {%{$user || {}}};

            # Rename date to avoid conflicts with date tt2 plugin and make
            # name clearer.
            $variables->{subscription_date} = $variables->{date};
            delete $variables->{date};

            # Aliases.
            $variables->{ca} = $user->{custom_attributes};

            # Status filters.
            $variables->{isSubscriberOf} = sub {
                my $other_list = Sympa::List->new(shift, $robot);
                return $other_list
                    ? $other_list->is_list_member($user->{email})
                    : undef;
            };
            $variables->{isEditorOf} = sub {
                my $other_list = Sympa::List->new(shift, $robot);
                return $other_list
                    ? $other_list->is_admin('actual_editor', $user->{email})
                    : undef;
            };
            $variables->{isOwnerOf} = sub {
                my $other_list = Sympa::List->new(shift, $robot);
                return $other_list
                    ? ($other_list->is_admin('owner', $user->{email})
                        || Sympa::is_listmaster($other_list, $user->{email}))
                    : undef;
            };

            # Run the test.
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
            $result =~ s/\s+\z//;

            unless ($result eq '' or $result eq '1') {
                # Anything not 1 or empty result is an error.
                $log->syslog(
                    'debug2',
                    'Error while applying filter "%s" : %s, aborting include',
                    $filter,
                    $result
                );
                return undef;
            }

            # Skip user if filter returned false, i.e. empty result.
            next unless $result eq '1';
        }

        return [$user->{email}, $user->{gecos}];
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::List - Data source based on a list at local machine

=head1 DESCRIPTION

Include a list as subscribers.

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::List> appeared on Sympa 6.2.45b.

=cut
