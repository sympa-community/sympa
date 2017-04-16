# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::List::Config;

use strict;
use warnings;

use Conf;
use Sympa::Robot;
use Sympa::Tools::Data;
use Sympa::Tools::Text;

sub new {
    my $class   = shift;
    my $context = shift;
    my $config  = shift;

    die 'bug in logic. Ask developer' unless ref $context eq 'Sympa::List';

    #FIXME: Should sanitize $config.
    bless {context => $context, config => $config, changes => {}} => $class;
}

sub get {
    my $self = shift;
    my $key  = shift;

    return undef unless exists $self->{config}->{$key};
    # FIXME:Multiple levels of keys should be possible.
    return Sympa::Tools::Data::clone_var($self->{config}->{$key});
}

sub get_change {
    my $self = shift;
    my $key  = shift;

    return undef unless exists $self->{changes}->{$key};
    # FIXME:Multiple levels of keys should be possible.
    return Sympa::Tools::Data::clone_var($self->{changes}->{$key});
}

sub submit {
    my $self   = shift;
    my $new    = shift;
    my $user   = shift;
    my $errors = shift;

    my $changes = $self->_sanitize_changes($new, $user);

    # Error if no parameter was edited.
    unless ($changes and %$changes) {
        $self->{changes} = {};
        push @$errors, ['user', 'no_parameter_edited'];
        return '';
    }

    my $validity = $self->_validate_changes($changes, $errors);
    $self->{changes} = $changes;

    return $validity;
}

# Sanitizes parsed input including changes.
# Parameters:
#   $new: Change information.
#   $user: Operating user.  $param->{'user'}{'email'}.
# Returns:
#   Sanitized input, where "owner.0.gecos" will be stores in
#   $hashref->{'owner'}{'0'}{'gecos'}.
sub _sanitize_changes {
    my $self = shift;
    my $new  = shift;
    my $user = shift;

    return undef unless ref $new eq 'HASH';    # Sanity check

    my $list = $self->{context};

    my $authz = sub {
        my $pnames = shift;
        'write' eq $list->may_edit(join('.', @{$pnames || []}), $user);
    };
    my $pinfo = Sympa::Robot::list_params($list->{'domain'});

    my %ret = map {
        unless (exists $pinfo->{$_} and $pinfo->{$_}) {
            ();    # Sanity check: unknown parameter
        } else {
            my $pii  = $pinfo->{$_};
            my $pni  = [$_];
            my $newi = $new->{$_};
            my $curi = Sympa::Tools::Data::clone_var($self->{config}{$_});

            my @r;
            if ($pii->{occurrence} =~ /n$/) {
                if (ref $pii->{format} eq 'ARRAY') {
                    @r =
                        $self->_sanitize_changes_set($curi, $newi, $pii, $pni,
                        $authz);
                } else {
                    @r =
                        $self->_sanitize_changes_array($curi, $newi, $pii,
                        $pni, $authz);
                }
            } elsif (ref $pii->{format} eq 'HASH') {
                @r =
                    $self->_sanitize_changes_paragraph($curi, $newi, $pii,
                    $pni, $authz);
            } else {
                @r =
                    $self->_sanitize_changes_leaf($curi, $newi, $pii, $pni,
                    $authz);
            }

            # Omit removal if current configuration is already empty.
            (@r and not defined $r[1] and not defined $curi) ? () : @r;
        }
    } sort Sympa::List::by_order keys %$new;

    return {%ret};
}

# Sanitizes set.
sub _sanitize_changes_set {
    my $self   = shift;
    my $cur    = shift;
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $authz  = shift;

    return () unless ref $new eq 'ARRAY';    # Sanity check
    return () if $pitem->{obsolete};
    return () unless $authz->($pnames);

    my $list = $self->{context};

    # Apply default.
    unless (defined $cur) {
        my $default = $pitem->{default};
        if (ref $default eq 'HASH' and exists $default->{conf}) {
            $cur = Conf::get_robot_conf($list->{'domain'}, $default->{conf});
        } else {
            $cur = $default;
        }
        if ($pitem->{split_char}) {
            my $split_char = $pitem->{split_char};
            $cur = [split /\s*$split_char\s*/, $cur];
        }
    }

    my $i       = -1;
    my %updated = map {
        $i++;
        my $curi = $_;
        (grep { Sympa::Tools::Data::smart_eq($curi, $_) } @$new)
            ? ()
            : ($i => undef);
    } @$cur;
    my %added = map {
        my $newi = $_;
        (grep { Sympa::Tools::Data::smart_eq($newi, $_) } @$cur)
            ? ()
            : (++$i => $_);
    } @$new;
    my %ret = (%updated, %added);

    # If all children are removed, remove parent.
    while (my ($k, $v) = each %ret) {
        $cur->[$k] = $v;
    }
    return ($pnames->[-1] => undef) unless grep { defined $_ } @$cur;

    unless (%ret) {
        return ();    # No valid changes
    } else {
        return ($pnames->[-1] => {%ret});
    }
}

# Sanitizes array.
sub _sanitize_changes_array {
    my $self   = shift;
    my $cur    = shift || [];
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $authz  = shift;

    return () unless ref $new eq 'ARRAY';    # Sanity check
    return () if $pitem->{obsolete};
    return () unless $authz->($pnames);

    my $i   = -1;
    my %ret = map {
        $i++;
        my $curi = $cur->[$i];

        my @r;
        if (ref $pitem->{format} eq 'HASH') {
            @r =
                $self->_sanitize_changes_paragraph($curi, $_, $pitem, $pnames,
                $authz);
        } else {
            @r =
                $self->_sanitize_changes_leaf($curi, $_, $pitem, $pnames,
                $authz);
        }

        # Omit removal if current configuration is already empty.
        (@r and not defined $r[1] and not defined $curi)
            ? ()
            : (@r ? ($i => $r[1]) : ());
    } @$new;

    # If all children are removed, remove parent.
    while (my ($k, $v) = each %ret) {
        $cur->[$k] = $v;
    }
    return ($pnames->[-1] => undef) unless grep { defined $_ } @$cur;

    unless (%ret) {
        return ();    # No valid changes
    } else {
        return ($pnames->[-1] => {%ret});
    }
}

# Sanitizes paragraph.
sub _sanitize_changes_paragraph {
    my $self   = shift;
    my $cur    = shift || {};
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $authz  = shift;

    return () unless ref $new eq 'HASH';    # Sanity check
    return () if $pitem->{obsolete};
    return () unless $authz->($pnames);

    my %ret = map {
        unless (exists $pitem->{format}->{$_} and $pitem->{format}->{$_}) {
            ();                             # Sanity check: unknown parameter
        } else {
            my $pii  = $pitem->{format}->{$_};
            my $pni  = [@$pnames, $_];
            my $newi = $new->{$_};
            my $curi = $cur->{$_};

            my @r;
            if ($pii->{occurrence} =~ /n$/) {
                if (ref $pii->{format} eq 'ARRAY') {
                    @r =
                        $self->_sanitize_changes_set($curi, $newi, $pii, $pni,
                        $authz);
                } else {
                    @r =
                        $self->_sanitize_changes_array($curi, $newi, $pii,
                        $pni, $authz);
                }
            } elsif (ref $pii->{format} eq 'HASH') {
                @r =
                    $self->_sanitize_changes_paragraph($curi, $newi, $pii,
                    $pni, $authz);
            } else {
                @r =
                    $self->_sanitize_changes_leaf($curi, $newi, $pii, $pni,
                    $authz);
            }

            # Omit removal if current configuration is already empty.
            (@r and not defined $r[1] and not defined $curi) ? () : @r;
        }
    } sort keys %$new;

    while (my ($k, $v) = each %ret) {
        $cur->{$k} = $v;
    }
    # As soon as a required component is found to be removed,
    # the whole parameter instance is removed.
    return ($pnames->[-1] => undef)
        if grep {
        $pitem->{format}->{$_}->{occurrence} =~ /^1/
            and not defined $cur->{$_}
        } keys %{$pitem->{format}};
    # If all children are removed, remove parent.
    return ($pnames->[-1] => undef)
        unless grep { defined $_ } values %$cur;

    unless (%ret) {
        return ();    # No valid changes
    } else {
        return ($pnames->[-1] => {%ret});
    }
}

# Sanitizes leaf.
sub _sanitize_changes_leaf {
    my $self   = shift;
    my $cur    = shift;
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $authz  = shift;

    return () if ref $new eq 'ARRAY';    # Sanity check: Hashref or scalar
    return () if $pitem->{obsolete};
    return () unless $authz->($pnames);

    my $list = $self->{context};

    # If the parameter corresponds to a scenario or a task, mark it
    # as changed if its name was changed.  Example: 'subscribe'.
    if ($pitem->{scenario} or $pitem->{task}) {
        return () unless ref($new || {}) eq 'HASH';    # Sanity check
        $cur = ($cur || {})->{name};
        $new = ($new || {})->{name};
    }
    # Apply default.
    unless (defined $cur) {
        my $default = $pitem->{default};
        if (ref $default eq 'HASH' and exists $default->{conf}) {
            $cur = Conf::get_robot_conf($list->{'domain'}, $default->{conf});
        } else {
            $cur = $default;
        }
    }

    if (Sympa::Tools::Data::smart_eq($cur, $new)) {
        return ();    # Not changed
    }

    if ($pitem->{scenario} or $pitem->{task}) {
        return ($pnames->[-1] => {name => $new});
    } else {
        return ($pnames->[-1] => $new);
    }
}

# Validates changes on list configuration.
# Context:
# - $list: An instance of Sympa::List.
# Parameters:
# - $new: Hashref including changes.
# - $errors: Error information, initially may be empty arrayref.
# Returns:
# - 'valid' if changes are valid; 'invalid' otherwise;
#   '' if no changes necessary; undef if internal error occurred.
# - $new may be modified, if there are any omittable changes.
# - Error information will be added to $errors.
sub _validate_changes {
    my $self   = shift;
    my $new    = shift;
    my $errors = shift;

    my $list  = $self->{context};
    my $pinfo = Sympa::Robot::list_params($list->{'domain'});

    my $ret = 'valid';
    foreach my $pname (sort Sympa::List::by_order keys %$new) {
        my $newi = $new->{$pname};
        my $pii  = $pinfo->{$pname};
        my $pni  = [$pname];

        my $r;
        if ($pii->{occurrence} =~ /n$/) {
            $r =
                $self->_validate_changes_multiple($newi, $pii, $pni, $errors);
        } elsif (ref $pii->{format} eq 'HASH') {
            $r =
                $self->_validate_changes_paragraph($newi, $pii, $pni,
                $errors);
        } else {
            $r = $self->_validate_changes_leaf($newi, $pii, $pni, $errors);
        }

        return undef unless defined $r;
        delete $new->{$pname} if $r eq 'omit';
        $ret = 'invalid' if $r eq 'invalid';
    }

    return '' unless %$new;
    return $ret;
}

# Validates array or set.
sub _validate_changes_multiple {
    my $self   = shift;
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $errors = shift;

    if (not defined $new and $pitem->{occurrence} =~ /^1/) {
        push @$errors, ['user', 'mandatory_parameter', $pitem, $pnames];
        return 'omit';
    }

    my $ret = 'valid';
    if (defined $new) {
        foreach my $i (sort { $a <=> $b } keys %$new) {
            my $newi = $new->{$i};

            if (defined $newi) {
                my $r;
                if (ref $pitem->{format} eq 'HASH') {
                    $r =
                        $self->_validate_changes_paragraph($newi, $pitem,
                        $pnames, $errors);
                } else {
                    $r =
                        $self->_validate_changes_leaf($newi, $pitem, $pnames,
                        $errors);
                }

                return undef unless defined $r;
                delete $new->{$i} if $r eq 'omit';
                $ret = 'invalid' if $r eq 'invalid';
            }
        }

        return 'omit' unless %$new;
    }

    return $ret;
}

# Validates paragraph.
sub _validate_changes_paragraph {
    my $self   = shift;
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $errors = shift;

    if (not defined $new and $pitem->{occurrence} =~ /^1/) {
        push @$errors, ['user', 'mandatory_parameter', $pitem, $pnames];
        return 'omit';
    }

    my $ret = 'valid';
    if (defined $new) {
        foreach my $key (sort keys %$new) {
            my $pii  = $pitem->{format}->{$key};
            my $pni  = [@$pnames, $key];
            my $newi = $new->{$key};

            my $r;
            if ($pii->{occurrence} =~ /n$/) {
                $r =
                    $self->_validate_changes_multiple($newi, $pii, $pni,
                    $errors);
            } elsif (ref $pii->{format} eq 'HASH') {
                $r =
                    $self->_validate_changes_paragraph($newi, $pii, $pni,
                    $errors);
            } else {
                $r =
                    $self->_validate_changes_leaf($newi, $pii, $pni, $errors);
            }

            return undef unless defined $r;
            delete $new->{$key} if $r eq 'omit';
            $ret = 'invalid' if $r eq 'invalid';
        }

        return 'omit' unless %$new;
    }

    return $ret;
}

my %validations = (
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
                $list->{'name'}, lc $_, $list->{'admin'}{'host'}
            }
            split /[,\s]+/,
            Conf::get_robot_conf($list->{'domain'}, 'list_check_suffixes');
        my $bounce_email_re = quotemeta($list->get_bounce_address('ANY'));
        $bounce_email_re =~ s/(?<=\\\+).*(?=\\\@)/.*/;

        return 'incorrect_email'
            if grep { $email eq $_ } @special
                or $email =~ /^$bounce_email_re$/;
    },
    # Checking no topic named "other".
    reserved_msg_topic_name => sub {
        my $self = shift;
        my $new  = shift;

        return 'topic_other'
            if lc $new eq 'other';
    },
);

# Validates leaf.
sub _validate_changes_leaf {
    my $self   = shift;
    my $new    = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $errors = shift;

    # If the parameter corresponds to a scenario or a task, mark it
    # as changed if its name was changed.  Example: 'subscribe'.
    if ($pitem->{scenario} or $pitem->{task}) {
        $new = $new->{name} if defined $new;
    }

    if (not defined $new and $pitem->{occurrence} =~ /^1/) {
        push @$errors, ['user', 'mandatory_parameter', $pitem, $pnames];
        return 'omit';
    }

    # Check that the new values have the right syntax.
    if (defined $new) {
        my $format = $pitem->{format};
        if (   (ref $format eq 'ARRAY' and not grep { $new eq $_ } @$format)
            or (ref $format ne 'ARRAY' and not $new =~ /^$format$/)) {
            push @$errors,
                ['user', 'syntax_errors', $pitem, $pnames, {value => $new}];
            return 'invalid';
        }
        foreach my $validation (@{$pitem->{validations} || []}) {
            next unless ref $validations{$validation} eq 'CODE';
            my $validity = $validations{$validation}->($self, $new);
            next unless $validity;

            push @$errors,
                ['user', $validity, $pitem, $pnames, {value => $new}];
            return 'invalid';
        }
    }

    return 'valid';
}

sub commit {
    die 'Not yet implemented';
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::List::Config - List configuration

=head1 SYNOPSIS

  use Sympa::List::Config;
  my $config = Sympa::List::Config->new($list, {...});
 
  my $errors = []; 
  my $validity = $config->submit({...}, $user, $errors);
  $config->commit;

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( $list, [ $initial_config ] )

I<Constructor>.
TBD.

=item get ( $key )

I<Instance method>.
TBD.

=item get_change ($key )

I<Instance method>.
Gets submitted change.

=item submit ( $new, $user, \@errors )

I<Instance method>.
Submits change and verify it.
TBD.

=item commit ( $change )

I<Instance method>.
Merges change verified by sbumit() into actual configuration.
TBD.

=back

=head1 SEE ALSO

L<Sympa::List>,
L<Sympa::ListDef>.

=head1 HISTORY

L<Sympa::List::Config> appeared on Sympa 6.2.17.

=cut

# -*- indent-tabs-mode: nil; -*-
