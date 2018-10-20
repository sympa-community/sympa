# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
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

package Sympa::List::Users;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::ListDef;
use Sympa::Log;
use Sympa::Tools::Text;

use base qw(Sympa::List::Config);

my $log = Sympa::Log->instance;

sub _schema {
    my $self = shift;

    return {%Sympa::ListDef::user_info};
}

# The 'owner_domain' option is an example of this need. The restriction applies
# to the entire set of owner addresses, not just a single owner.
use constant _global_validations => {
    owner_domain => sub {
        my $self = shift;
        my $new  = shift;

        my $list = $self->{context};
        my $config =
            Sympa::List::Config->new($list, config => $list->{'admin'});
        my $pinfo    = $self->{_pinfo};
        my $loglevel = 'debug';         # was set to 'info' during development

        # gather parameters
        my $owner_domain = $config->get('owner_domain');
        if (defined($self->get_change('owner_domain'))) {
            $owner_domain = $self->get_change('owner_domain');
        }
        (my $domainrex = "[.\@]($owner_domain)\$") =~ s/ /|/g;

        my $owner_domain_min = $config->get('owner_domain_min');
        if (defined($self->get_change('owner_domain_min'))) {
            $owner_domain_min = $self->get_change('owner_domain_min');
        }
        $owner_domain_min ||= 0;

        # if no owner_domain setting, do nothing
        return if ($owner_domain =~ /^\s*$/);

        # calculate updated owner list, including deletions
        my @owner = map { $_->{'email'} } @{$self->get('owner')};
        my $changes = $self->get_change('owner');

        #use Data::Dumper;
        #my $changedump = Dumper($changes);
        #$changedump =~ s/\n//g;
        #$changedump =~ s/ +/ /g;
        #$log->syslog($loglevel, "conf changes = $changedump");

        $log->syslog($loglevel, "BEGIN owner_domain validation");
        $log->syslog($loglevel, "original owners: " . join(" ", @owner));

        map {
            unless (defined($changes->{$_})) {
                # value undefined => owner was removed
                $log->syslog($loglevel, "remove $_ \"$owner[$_]\"");
                $owner[$_] = undef;
            } elsif (defined($changes->{$_}->{'email'})) {
                # owner address modified
                my $oldowner = $owner[$_];
                $owner[$_] = $changes->{$_}->{'email'};
                $log->syslog($loglevel,
                    "update $_ \"$oldowner\" => \"$owner[$_]\"");
            }
        } CORE::keys %{$changes || {}};

        @owner = grep defined, @owner;

        # count matches and non-matches
        my @non_matching_owners = grep { !/$domainrex/ } @owner;
        my @matching_owners     = grep {/$domainrex/} @owner;

        my $non_matching_count   = 1 + $#non_matching_owners;
        my $matching_owner_count = 1 + $#matching_owners;

        # logging
        $log->syslog($loglevel, "owner_domain: $owner_domain");
        $log->syslog($loglevel, "owner_domain_min: $owner_domain_min");
        $log->syslog($loglevel, "updated owners: " . join(" ", @owner));
        $log->syslog($loglevel, "total owners: " . ($#owner + 1));
        $log->syslog($loglevel, "domainrex: $domainrex");
        $log->syslog($loglevel,
            "matching_owners: " . join(" ", @matching_owners));
        $log->syslog($loglevel,
            "matching_owner_count: $matching_owner_count");
        $log->syslog($loglevel,
            "non_matching_owners: " . join(" ", @non_matching_owners));
        $log->syslog($loglevel, "non_matching_count: $non_matching_count");

        # apply different rules based on min domain requirement
        if ($owner_domain_min == 0) {
            return (
                'owner_domain',
                {   p_info       => $pinfo->{'owner'},
                    p_paths      => ['owner'],
                    owner_domain => $owner_domain,
                    value        => join(' ', @non_matching_owners)
                }
            ) unless ($non_matching_count == 0);
        } else {
            return (
                'owner_domain_min',
                {   p_info           => $pinfo->{'owner'},
                    p_paths          => ['owner'],
                    owner_domain     => $owner_domain,
                    owner_domain_min => $owner_domain_min,
                    value            => $matching_owner_count
                }
            ) unless ($matching_owner_count >= $owner_domain_min);
        }
        $log->syslog($loglevel, "END owner_domain validation");
        return '';
    },
};

use constant _local_validations => {
    # Checking that list owner/editor address is not set to list address.
    list_address => sub {
        my $self = shift;
        my $new  = shift;

        my $list = $self->{context};

        my $email = Sympa::Tools::Text::canonic_email($new);
        return 'syntax_errors'
            unless defined $email;

        return 'incorrect_email'
            if Sympa::get_address($list) eq $email;
    },
    # Checking that list editor address is not set to editor special address.
    list_editor_address => sub {
        my $self = shift;
        my $new  = shift;

        my $list = $self->{context};

        my $email = Sympa::Tools::Text::canonic_email($new);
        return 'syntax_errors'
            unless defined $email;

        return 'incorrect_email'
            if Sympa::get_address($list, 'editor') eq $email;
    },
    # Checking that list owner address is not set to one of the special
    # addresses.
    list_special_addresses => sub {
        my $self = shift;
        my $new  = shift;

        my $list = $self->{context};

        my $email = Sympa::Tools::Text::canonic_email($new);
        return 'syntax_errors'
            unless defined $email;

        my @special = ();
        push @special,
            map { Sympa::get_address($list, $_) }
            qw(owner editor return_path subscribe unsubscribe);
        push @special, map {
            sprintf '%s-%s@%s',
                $list->{'name'}, lc $_, $list->{'domain'}
            }
            split /[,\s]+/,
            Conf::get_robot_conf($list->{'domain'}, 'list_check_suffixes');
        my $bounce_email_re = quotemeta($list->get_bounce_address('ANY'));
        $bounce_email_re =~ s/(?<=\\\+).*(?=\\\@)/.*/;

        return 'incorrect_email'
            if grep { $email eq $_ } @special
            or $email =~ /^$bounce_email_re$/;
    },
    # Avoid duplicate parameter values in the array.
    unique_paragraph_key => sub {
        my $self   = shift;
        my $new    = shift;
        my $pitem  = shift;
        my $ppaths = shift;

        my @p_ppaths = (@$ppaths);
        my $keyname  = pop @p_ppaths;
        my $i        = pop @p_ppaths;
        return unless defined $i and $i =~ /\A\d+\z/;
        return if $i == 0;

        my ($p_cur) = $self->get(join '.', @p_ppaths);
        $p_cur ||= [];
        my @p_curkeys = map { $_->{$keyname} } @$p_cur;

        my ($p_new) = $self->get_change(join '.', @p_ppaths);
        my %p_newkeys =
            map {
                  (exists $p_new->{$_}->{$keyname})
                ? ($_ => $p_new->{$_}->{$keyname})
                : ()
            } (CORE::keys %$p_new);

        foreach my $j (0 .. $i - 1) {
            next unless exists $p_newkeys{$j};
            $p_curkeys[$j] = $p_newkeys{$j};
        }
        foreach my $j (0 .. $i - 1) {
            next unless defined $p_curkeys[$j];
            if ($p_curkeys[$j] eq $new) {
                return qw(unique_paragraph_key omit);
            }
        }
    },
};

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::List::Users - List users

=head1 SYNOPSIS

  use Sympa::List::Users;
  my $config = Sympa::List::Users->new($list, {...});
 
  my $errors = []; 
  my $validity = $config->submit({...}, $user, $errors);
  $config->commit($errors);
  
  my ($value) = $config->get('owner.0.gecos');
  my @keys  = $config->keys('owner');

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( $list, [ config =E<gt> $initial_config ], [ copy =E<gt> 1 ],
[ no_family =E<gt> 1 ] )

I<Constructor>.
Creates new instance of L<Sympa::List::Users> object.

Parameters:

See also L<Sympa::Config/new>.

=over

=item $list

Context.  An instance of L<Sympa::List> class.

=item no_family =E<gt> 1

Won't apply family constraint.
By default, the constraint will be applied if the list is belonging to
family.
See also L<Sympa::List::Config/"Family constraint">.

=back

=item get_schema ( [ $user ] )

I<Instance method>.
Get configuration schema as hashref.
See L<Sympa::ListDef> about structure of schema.

Parameter:

=over

=item $user

Email address of a user.
If specified, adds C<'privilege'> attribute taken from L<edit_list.conf(5)>
for the user.

=back

=back

=head2 Attribute

See L<Sympa::Config/Attribute>.

=head2 Filters

TBD.

=head2 Validations

TBD.

=head1 SEE ALSO

L<Sympa::Config>,
L<Sympa::List::Config>,
L<Sympa::ListDef>.

=head1 HISTORY

L<Sympa::List::Users> appeared on Sympa 6.2.33b.2.

=cut

