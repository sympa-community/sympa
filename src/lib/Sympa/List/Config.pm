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
    my %options = @_;

    die 'bug in logic. Ask developer' unless ref $context eq 'Sympa::List';

    # The undef means list creation.
    # Empty hashref (default) means loading existing config.
    my $config;
    if (exists $options{config}) {
        $config = $options{config};
    } else {
        $config = {};
    }
    $config = Sympa::Tools::Data::clone_var($config)
        if $options{copy};

    #FIXME:Should $config be sanitized?
    my $self =
        bless {context => $context, _config => $config, _changes => {}} =>
        $class;

    $self->{_pinfo} = $self->_list_params(%options);

    return $self;
}

sub _list_params {
    my $self    = shift;
    my %options = @_;

    my $list = $self->{context};

    my $pinfo = Sympa::Robot::list_params($list->{'domain'});
    $self->_list_params_apply_family($pinfo)
        unless $options{no_family};

    return $pinfo;
}

sub _list_params_apply_family {
    my $self  = shift;
    my $pinfo = shift;

    my $family = $self->{context}->get_family;
    return unless ref $family eq 'Sympa::Family';

    foreach my $pname (_keys($pinfo)) {
        $self->__list_params_apply_family($pinfo->{$pname}, [$pname],
            $family);
    }
}

# Adds additional constraint by family to pinfo.
# The family constraint
# * restricts options for particular scalar parameters to the set of values,
# * makes occurrence of them be required.
sub __list_params_apply_family {
    my $self   = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $family = shift;

    my $ret = 0;
    if (ref $pitem->{format} eq 'HASH') {
        foreach my $key (_keys($pitem->{format})) {
            if ($self->_list_params_apply_family(
                    $pitem->{format}->{$key},
                    [@$pnames, $key], $family
                )
                ) {
                if ($pitem->{format}->{$key}->{occurrence} eq '0-1') {
                    $pitem->{format}->{$key}->{occurrence} = '1';
                } elsif ($pitem->{format}->{$key}->{occurrence} eq '0-n') {
                    $pitem->{format}->{$key}->{occurrence} = '1-n';
                }
                $ret = 1;
            }
        }
    } else {
        my $constraint = $family->get_param_constraint(join '.', @$pnames);
        my @constr;
        unless (defined $constraint) {    # Error
            next;
        } elsif (ref $constraint eq 'ARRAY') {    # Multiple choices
            @constr = @$constraint;
        } elsif ($constraint ne '0') {            # Fixed value
            @constr = ($constraint);
        } else {                                  # No control
            next;
        }

        if (ref $pitem->{format} eq 'ARRAY') {
            @constr = grep {
                my $k = $_;
                grep { $k eq $_ } @constr
            } @{$pitem->{format}};
        } else {
            my $re = $pitem->{format};
            @constr = grep {/^($re)$/} @constr;
        }

        if (@constr) {
            if (ref $pitem->{format} eq 'ARRAY') {
                $pitem->{format} = [@constr];
            } else {
                $pitem->{format} = join '|', map { quotemeta $_ } @constr;
            }

            if ($pitem->{occurrence} eq '0-n') {
                $pitem->{occurrence} = '1-n';
            } elsif ($pitem->{occurrence} eq '0-1') {
                $pitem->{occurrence} = '1';
            }

            if (1 == scalar @constr) {
                $pitem->{default} = $constr[0];

                # Choose more restrictive privilege.
                # See also _get_schema_apply_privilege().
                $pitem->{privilege} = 'read'
                    if not $pitem->{privilege}
                        or 'read' lt $pitem->{privilege};
            } elsif (exists $pitem->{default} and defined $pitem->{default}) {
                delete $pitem->{default}
                    unless grep { $pitem->{default} eq $_ } @constr;
            }
            $ret = 1;
        }
    }

    return $ret;
}

sub get {
    my $self  = shift;
    my $ppath = shift;

    my @ppaths = split /[.]/, $ppath;
    return unless @ppaths;

    my @value = _get($self->{_config}, @ppaths);
    return unless @value;
    return $value[0] unless ref $value[0];
    return Sympa::Tools::Data::clone_var($value[0]);
}

sub _get {
    my $cur    = shift;
    my @ppaths = @_;

    while (1) {
        my $key = shift @ppaths;

        if ($key =~ /\A\d+\z/) {
            unless (ref $cur eq 'ARRAY' and exists $cur->[$key]) {
                return;
            } elsif (not @ppaths) {
                return ($cur->[$key]);
            } else {
                $cur = $cur->[$key];
            }
        } else {
            unless (ref $cur eq 'HASH' and exists $cur->{$key}) {
                return;
            } elsif (not @ppaths) {
                return $cur->{$key};
            } else {
                $cur = $cur->{$key};
            }
        }
    }
}

sub get_change {
    my $self  = shift;
    my $ppath = shift;

    my @ppaths = split /[.]/, $ppath;
    return unless @ppaths;

    my @value = _get_change($self->{_changes}, @ppaths);
    return unless @value;
    return $value[0] unless ref $value[0];
    return Sympa::Tools::Data::clone_var($value[0]);
}

sub _get_change {
    my $new    = shift;
    my @ppaths = @_;

    while (1) {
        my $key = shift @ppaths;

        unless (ref $new eq 'HASH' and exists $new->{$key}) {
            return;
        } elsif (not @ppaths) {
            return $new->{$key};
        } else {
            $new = $new->{$key};
        }
    }
}

sub get_changeset {
    my $self = shift;

    return $self->{_changes};
}

# Gets default for the set or the array of scalars.
sub _get_default_multiple {
    my $self  = shift;
    my $pitem = shift;

    my $val;
    my $list = $self->{context};

    my $default = $pitem->{default};
    if (ref $default eq 'HASH' and exists $default->{conf}) {
        $val = Conf::get_robot_conf($list->{'domain'}, $default->{conf});
    } else {
        $val = $default;
    }

    unless (defined $val) {
        $val = [];
    } else {
        my $re = quotemeta($pitem->{split_char} || ',');
        $val = [split /\s*$re\s*/, $val];
    }

    return $val;
}

sub _get_default_leaf {
    my $self  = shift;
    my $pitem = shift;

    my $val;
    my $list = $self->{context};

    my $default = $pitem->{default};
    if (ref $default eq 'HASH' and exists $default->{conf}) {
        $val = Conf::get_robot_conf($list->{'domain'}, $default->{conf});
    } else {
        $val = $default;
    }

    if (defined $val and ($pitem->{scenario} or $pitem->{task})) {
        return {name => $val};
    } else {
        return $val;
    }
}

# Apply default values, if elements are mandatory and are scalar.
# The init option means list/node creation.
sub _apply_defaults {
    my $self    = shift;
    my $cur     = shift;
    my $phash   = shift;
    my %options = @_;

    foreach my $key (_keys($phash)) {
        my $pii = $phash->{$key};

        if (exists $cur->{$key}) {
            next;
        } elsif (ref $pii->{format} eq 'HASH') {    # Not a scalar
            next;
        } elsif ($pii->{occurrence} =~ /n$/) {
            if (exists $pii->{default}) {
                $cur->{$key} = $self->_get_default_multiple($pii)
                    if $options{init}
                        or $pii->{occurrence} =~ /^1/;
            }
        } else {
            if (exists $pii->{default}) {
                $cur->{$key} = $self->_get_default_leaf($pii)
                    if $options{init}
                        or $pii->{occurrence} =~ /^1/;
            }
        }
    }
}

sub get_schema {
    my $self = shift;
    my $user = shift;

    my $pinfo = Sympa::Tools::Data::clone_var($self->{_pinfo});
    if ($user) {
        foreach my $pname (_keys($pinfo)) {
            $self->_get_schema_apply_privilege($pinfo->{$pname}, [$pname],
                $user, undef);
        }
    }
    $pinfo;
}

# Apply privilege on each parameter.
sub _get_schema_apply_privilege {
    my $self   = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $user   = shift;
    my $priv_p = shift;

    my $list = $self->{context};

    # Choose most restrictive privilege.
    # Trick:
    # "hidden", "read" and "write" precede others in reverse dictionary order.
    my $priv = $list->may_edit(_pfullname($pnames), $user);
    $priv = $priv_p
        if not $priv
            or ($priv_p and $priv_p lt $priv);
    $pitem->{privilege} = $priv
        if not $pitem->{privilege}
            or ($priv and $priv lt $pitem->{privilege});
    $pitem->{privilege} ||= 'hidden';    # Implicit default

    if (ref $pitem->{format} eq 'HASH') {
        foreach my $key (_keys($pitem->{format})) {
            $self->_get_schema_apply_privilege(
                $pitem->{format}->{$key},
                [@$pnames, $key],
                $user, $pitem->{privilege}
            );
        }
    }
}

sub keys {
    my $self  = shift;
    my $pname = shift;

    return _keys($self->{_pinfo}) unless $pname;
    my @pnames = split /[.]/, $pname;

    my $phash = $self->{_pinfo};
    while (1) {
        my $key = shift @pnames;

        unless (ref $phash eq 'HASH'
            and exists $phash->{$key}
            and exists $phash->{$key}->{format}) {
            return;
        } elsif (not @pnames) {
            return _keys($phash->{$key}->{format});
        } else {
            $phash = $phash->{$key}->{format};
        }
    }
}

sub _keys {
    my $hash = shift;
    my $phash = shift || $hash;

    return sort {
        ($phash->{$a}->{order} || 999) <=> ($phash->{$b}->{order} || 999)
    } CORE::keys %$hash;
}

# Gets parameter name of node from list of parameter paths.
sub _pname {
    my $ppaths = shift;
    return undef unless $ppaths and @$ppaths;
    [grep { !/\A\d+\z/ } @$ppaths]->[-1];
}

# Gets full parameter name of node from list of parameter paths.
sub _pfullname {
    my $ppaths = shift;
    return undef unless $ppaths and @$ppaths;
    return join '.', grep { !/\A\d+\z/ } @$ppaths;
}

sub submit {
    my $self   = shift;
    my $new    = shift;
    my $user   = shift;
    my $errors = shift;

    my $changes = $self->_sanitize_changes($new, $user);

    # Error if no parameter was edited.
    unless ($changes and %$changes) {
        $self->{_changes} = {};
        push @$errors, ['notice', 'no_parameter_edited'];
        return '';
    }

    my $validity = $self->_validate_changes($changes, $errors);
    $self->{_changes} = $changes;

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

    # Apply privileges: {privilege} will keep 'hidden', 'read' or 'write'.
    my $pinfo = $self->get_schema($user);

    # Undefined {_config} means list creation.
    # Empty hashref means loading existing config.
    my $init = (not defined $self->{_config});
    my $loading = ($self->{_config} and not %{$self->{_config}});
    my $cur = $init ? {} : Sympa::Tools::Data::clone_var($self->{_config});
    $self->_apply_defaults($cur, $pinfo, init => ($init and not $loading));

    my %ret = map {
        unless (exists $pinfo->{$_} and $pinfo->{$_}) {
            ();    # Sanity check: unknown parameter
        } else {
            # Resolve alias.
            my ($k, $o) = ($_, $_);
            do {
                ($k, $o) = ($o, $pinfo->{$o}->{obsolete});
            } while ($o and $pinfo->{$o});
            unless ($k eq $_) {
                $new->{$k} = $new->{$_};
                delete $new->{$_};
            }

            my $pii  = $pinfo->{$k};
            my $ppi  = [$k];
            my $newi = $new->{$k};
            my $curi = $cur->{$k};

            my @r;
            if ($pii->{occurrence} =~ /n$/) {
                if (ref $pii->{format} eq 'ARRAY') {
                    @r =
                        $self->_sanitize_changes_set($curi, $newi, $pii,
                        $ppi);
                } else {
                    @r =
                        $self->_sanitize_changes_array($curi, $newi, $pii,
                        $ppi, loading => $loading);
                }
            } elsif (ref $pii->{format} eq 'HASH') {
                @r = $self->_sanitize_changes_paragraph(
                    $curi, $newi, $pii, $ppi,
                    init    => (not defined $curi),
                    loading => $loading
                );
            } else {
                @r = $self->_sanitize_changes_leaf($curi, $newi, $pii, $ppi);
            }

            # Omit removal if current configuration is already empty.
            (@r and not defined $r[1] and not defined $curi) ? () : @r;
        }
    } _keys($new, $pinfo);

    return {%ret};
}

# Sanitizes set.
sub _sanitize_changes_set {
    my $self   = shift;
    my $cur    = shift || [];
    my $new    = shift;
    my $pitem  = shift;
    my $ppaths = shift;

    return () unless ref $new eq 'ARRAY';    # Sanity check
    return () if $pitem->{obsolete};
    return () unless $pitem->{privilege} eq 'write';

    my $list = $self->{context};

    # Resolve synonym.
    if (ref $pitem->{synonym} eq 'HASH') {
        @$new = map {
            if (defined $_) {
                my $synonym = $pitem->{synonym}->{$_};
                (defined $synonym) ? $synonym : $_;
            } else {
                undef;
            }
        } @$new;
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
    return (_pname($ppaths) => undef) unless grep { defined $_ } @$cur;

    unless (%ret) {
        return ();    # No valid changes
    } else {
        return (_pname($ppaths) => {%ret});
    }
}

# Sanitizes array.
sub _sanitize_changes_array {
    my $self    = shift;
    my $cur     = shift || [];
    my $new     = shift;
    my $pitem   = shift;
    my $ppaths  = shift;
    my %options = @_;

    return () unless ref $new eq 'ARRAY';    # Sanity check
    return () if $pitem->{obsolete};
    return () unless $pitem->{privilege} eq 'write';

    my $i   = -1;
    my %ret = map {
        $i++;
        my $curi = $cur->[$i];
        my $ppi = [@$ppaths, $i];

        my @r;
        if (ref $pitem->{format} eq 'HASH') {
            @r = $self->_sanitize_changes_paragraph(
                $curi, $_, $pitem, $ppi,
                init    => (not defined $curi),
                loading => $options{loading}
            );
        } else {
            @r = $self->_sanitize_changes_leaf($curi, $_, $pitem, $ppi);
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
    return (_pname($ppaths) => undef) unless grep { defined $_ } @$cur;

    unless (%ret) {
        return ();    # No valid changes
    } else {
        return (_pname($ppaths) => {%ret});
    }
}

# Sanitizes paragraph.
# The init option means node creation.
sub _sanitize_changes_paragraph {
    my $self    = shift;
    my $cur     = shift || {};
    my $new     = shift;
    my $pitem   = shift;
    my $ppaths  = shift;
    my %options = @_;

    return () unless ref $new eq 'HASH';    # Sanity check
    return () if $pitem->{obsolete};
    return () unless $pitem->{privilege} eq 'write';

    $self->_apply_defaults($cur, $pitem->{format},
        init => ($options{init} and not $options{loading}));

    my %ret = map {
        unless (exists $pitem->{format}->{$_} and $pitem->{format}->{$_}) {
            ();                             # Sanity check: unknown parameter
        } else {
            # Resolve alias.
            my ($k, $o) = ($_, $_);
            do {
                ($k, $o) = ($o, $pitem->{format}->{$o}->{obsolete});
            } while ($o and $pitem->{format}->{$o});
            unless ($k eq $_) {
                $new->{$k} = $new->{$_};
                delete $new->{$_};
            }

            my $pii  = $pitem->{format}->{$k};
            my $ppi  = [@$ppaths, $k];
            my $newi = $new->{$k};
            my $curi = $cur->{$k};

            my @r;
            if ($pii->{occurrence} =~ /n$/) {
                if (ref $pii->{format} eq 'ARRAY') {
                    @r =
                        $self->_sanitize_changes_set($curi, $newi, $pii,
                        $ppi);
                } else {
                    @r =
                        $self->_sanitize_changes_array($curi, $newi, $pii,
                        $ppi, loading => $options{loading});
                }
            } elsif (ref $pii->{format} eq 'HASH') {
                @r = $self->_sanitize_changes_paragraph(
                    $curi, $newi, $pii, $ppi,
                    init    => (not defined $curi),
                    loading => $options{loading}
                );
            } else {
                @r = $self->_sanitize_changes_leaf($curi, $newi, $pii, $ppi);
            }

            # Omit removal if current configuration is already empty.
            (@r and not defined $r[1] and not defined $curi) ? () : @r;
        }
    } _keys($new, $pitem->{format});

    while (my ($k, $v) = each %ret) {
        $cur->{$k} = $v;
    }
    # As soon as a required component is found to be removed,
    # the whole parameter instance is removed.
    return (_pname($ppaths) => undef)
        if grep {
        $pitem->{format}->{$_}->{occurrence} =~ /^1/
            and not defined $cur->{$_}
        } _keys($pitem->{format});
    # If all children are removed, remove parent.
    return (_pname($ppaths) => undef)
        unless grep { defined $_ } values %$cur;

    unless (%ret) {
        return ();    # No valid changes
    } else {
        return (_pname($ppaths) => {%ret});
    }
}

# Sanitizes leaf.
sub _sanitize_changes_leaf {
    my $self   = shift;
    my $cur    = shift;
    my $new    = shift;
    my $pitem  = shift;
    my $ppaths = shift;

    return () if ref $new eq 'ARRAY';    # Sanity check: Hashref or scalar
    return () if $pitem->{obsolete};
    return () unless $pitem->{privilege} eq 'write';

    my $list = $self->{context};

    # If the parameter corresponds to a scenario or a task, mark it
    # as changed if its name was changed.  Example: 'subscribe'.
    if ($pitem->{scenario} or $pitem->{task}) {
        return () unless ref($new || {}) eq 'HASH';    # Sanity check
        $cur = ($cur || {})->{name};
        $new = ($new || {})->{name};
    }
    # Resolve synonym.
    if (defined $new and ref $pitem->{synonym} eq 'HASH') {
        my $synonym = $pitem->{synonym}->{$new};
        $new = $synonym if defined $synonym;
    }

    if (Sympa::Tools::Data::smart_eq($cur, $new)) {
        return ();                                     # Not changed
    }

    if ($pitem->{scenario} or $pitem->{task}) {
        return (_pname($ppaths) => {name => $new});
    } else {
        return (_pname($ppaths) => $new);
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

    my $pinfo = $self->{_pinfo};

    my $ret = 'valid';
    foreach my $pname (_keys($new, $pinfo)) {
        my $newi = $new->{$pname};
        my $pii  = $pinfo->{$pname};
        my $ppi  = [$pname];

        my $r;
        if ($pii->{occurrence} =~ /n$/) {
            $r =
                $self->_validate_changes_multiple($newi, $pii, $ppi, $errors);
        } elsif (ref $pii->{format} eq 'HASH') {
            $r =
                $self->_validate_changes_paragraph($newi, $pii, $ppi,
                $errors);
        } else {
            $r = $self->_validate_changes_leaf($newi, $pii, $ppi, $errors);
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
    my $ppaths = shift;
    my $errors = shift;

    if (not defined $new and $pitem->{occurrence} =~ /^1/) {
        push @$errors,
            [
            'user', 'mandatory_parameter',
            {p_info => $pitem, p_paths => $ppaths}
            ];
        return 'omit';
    }

    my $ret = 'valid';
    if (defined $new) {
        foreach my $i (sort { $a <=> $b } CORE::keys %$new) {
            my $newi = $new->{$i};
            my $ppi = [@$ppaths, $i];

            if (defined $newi) {
                my $r;
                if (ref $pitem->{format} eq 'HASH') {
                    $r =
                        $self->_validate_changes_paragraph($newi, $pitem,
                        $ppi, $errors);
                } else {
                    $r =
                        $self->_validate_changes_leaf($newi, $pitem, $ppi,
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
    my $ppaths = shift;
    my $errors = shift;

    if (not defined $new and $pitem->{occurrence} =~ /^1/) {
        push @$errors,
            [
            'user', 'mandatory_parameter',
            {p_info => $pitem, p_paths => $ppaths}
            ];
        return 'omit';
    }

    my $ret = 'valid';
    if (defined $new) {
        foreach my $key (_keys($new, $pitem->{format})) {
            my $pii  = $pitem->{format}->{$key};
            my $ppi  = [@$ppaths, $key];
            my $newi = $new->{$key};

            my $r;
            if ($pii->{occurrence} =~ /n$/) {
                $r =
                    $self->_validate_changes_multiple($newi, $pii, $ppi,
                    $errors);
            } elsif (ref $pii->{format} eq 'HASH') {
                $r =
                    $self->_validate_changes_paragraph($newi, $pii, $ppi,
                    $errors);
            } else {
                $r =
                    $self->_validate_changes_leaf($newi, $pii, $ppi, $errors);
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
    # Checking that list editor address is not set to editor special address.
    list_editor_address => sub {
        my $self = shift;
        my $new  = shift;

        my $list = $self->{context};

        my $email = Sympa::Tools::Text::canonic_email($new);
        return 'syntax_errors'
            unless defined $email;

        return 'incorrect_email'
            if Sympa::get_address($list, 'editor') eq $new;
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
    my $ppaths = shift;
    my $errors = shift;

    # If the parameter corresponds to a scenario or a task, mark it
    # as changed if its name was changed.  Example: 'subscribe'.
    if ($pitem->{scenario} or $pitem->{task}) {
        $new = $new->{name} if defined $new;
    }

    if (not defined $new and $pitem->{occurrence} =~ /^1/) {
        push @$errors,
            [
            'user', 'mandatory_parameter',
            {p_info => $pitem, p_paths => $ppaths}
            ];
        return 'omit';
    }

    # Check that the new values have the right syntax.
    if (defined $new) {
        my $format = $pitem->{format};
        if (ref $format eq 'ARRAY' and not grep { $new eq $_ } @$format) {
            push @$errors,
                [
                'user', 'syntax_errors',
                {p_info => $pitem, p_paths => $ppaths, value => $new}
                ];
            return 'invalid';
        } elsif (ref $format ne 'ARRAY' and not $new =~ /^$format$/) {
            push @$errors,
                [
                'user', 'syntax_errors',
                {p_info => $pitem, p_paths => $ppaths, value => $new}
                ];
            return 'invalid';
        }
        foreach my $validation (@{$pitem->{validations} || []}) {
            next unless ref $validations{$validation} eq 'CODE';
            my $validity = $validations{$validation}->($self, $new);
            next unless $validity;

            push @$errors,
                [
                'user', $validity,
                {p_info => $pitem, p_paths => $ppaths, value => $new}
                ];
            return 'invalid';
        }
    }

    return 'valid';
}

sub commit {
    my $self = shift;
    my $errors = shift || [];

    my $list    = $self->{context};
    my $changes = $self->{_changes};
    my $pinfo   = $self->{_pinfo};

    # Updating config_changes for changed parameters.
    # FIXME:Check subitems also.
    if (ref($list->get_family) eq 'Sympa::Family') {
        unless (
            $list->update_config_changes('param', [_keys($changes, $pinfo)]))
        {
            push @$errors, ['intern', 'update_config_changes'];
            return undef;
        }
    }

    # Undefined {_config} means list creation.
    # Empty hashref means loading existing config.
    my $init    = (not defined $self->{_config});
    my $loading = ($self->{_config} and not %{$self->{_config}});
    my $cur     = $init ? {} : $self->{_config};
    $self->_apply_defaults($cur, $pinfo, init => ($init and not $loading));

    foreach my $pname (_keys($self->{_changes}, $pinfo)) {
        my $curi = $cur->{$pname};
        my $newi = $self->{_changes}->{$pname};
        my $pii  = $pinfo->{$pname};

        unless (defined $newi) {
            delete $cur->{$pname};
        } elsif ($pii->{occurrence} =~ /n$/) {
            $curi = $cur->{$pname} = [] unless defined $curi;
            $self->_merge_changes_multiple($curi, $newi, $pii,
                loading => $loading);
        } elsif (ref $pii->{format} eq 'HASH') {
            my $init = (not defined $curi);
            $curi = $cur->{$pname} = {} if $init;
            $self->_merge_changes_paragraph(
                $curi, $newi, $pii,
                init    => $init,
                loading => $loading
            );
        } else {
            $cur->{$pname} = $newi;
        }
    }

    $self->{_config} = $cur if $init;

    # Update 'defaults' item to indicate default settings, for compatibility.
    #FIXME:Multiple levels of keys should be possible.
    foreach my $pname (_keys($self->{_changes}, $pinfo)) {
        if (defined $self->{_changes}->{$pname}
            or $pinfo->{$pname}->{internal}) {
            delete $self->{_config}->{defaults}->{$pname};
        } else {
            $self->{_config}->{defaults}->{$pname} = 1;
        }
    }
}

sub _merge_changes_multiple {
    my $self    = shift;
    my $cur     = shift;
    my $new     = shift;
    my $pitem   = shift;
    my %options = @_;

    foreach my $i (reverse sort { $a <=> $b } CORE::keys %$new) {
        my $curi = $cur->[$i];
        my $newi = $new->{$i};

        unless (defined $new->{$i}) {
            splice @$cur, $i, 1;
        } elsif (ref $pitem->{format} eq 'HASH') {
            my $init = (not defined $curi);
            $curi = $cur->[$i] = {} if $init;
            $self->_merge_changes_paragraph(
                $curi, $newi, $pitem,
                init    => $init,
                loading => $options{loading}
            );
        } else {
            $cur->[$i] = $newi;
        }
    }

    # The set: Dedupe and sort.
    if (ref $pitem->{format} eq 'ARRAY') {
        my %elements = map { ($_ => 1) } grep { defined $_ } @$cur;
        @$cur = sort(CORE::keys %elements);
    }
}

# Merges changes on paragraph node.
# The init option means node creation.
sub _merge_changes_paragraph {
    my $self    = shift;
    my $cur     = shift;
    my $new     = shift;
    my $pitem   = shift;
    my %options = @_;

    $self->_apply_defaults($cur, $pitem->{format},
        init => ($options{init} and not $options{loading}));

    foreach my $key (_keys($new, $pitem->{format})) {
        my $curi = $cur->{$key};
        my $newi = $new->{$key};
        my $pii  = $pitem->{format}->{$key};

        unless (defined $newi) {
            delete $cur->{$key};
        } elsif ($pii->{occurrence} =~ /n$/) {
            $curi = $cur->{$key} = [] unless defined $curi;
            $self->_merge_changes_multiple($curi, $newi, $pii,
                loading => $options{loading});
        } elsif (ref $pii->{format} eq 'HASH') {
            my $init = (not defined $curi);
            $curi = $cur->{$key} = {} if $init;
            $self->_merge_changes_paragraph(
                $curi, $newi, $pii,
                init    => $init,
                loading => $options{loading}
            );
        } else {
            $cur->{$key} = $newi;
        }
    }
}

sub get_id {
    my $list = shift->{context};
    $list ? $list->get_id : '';
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
  $config->commit($errors);
  
  my $value = $config->get('owner.0.gecos');
  my @keys  = $config->keys('owner');

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( $list, [ config =E<gt> $initial_config ], [ copy =E<gt> 1 ],
[ no_family =E<gt> 1 ] )

I<Constructor>.
Creates new instance of L<Sympa::List::Config> object.

Parameters:

=over

=item $list

Context.  An instance of L<Sympa::List> class.

=item config =E<gt> $initial_config

Initial configuration.
Note:

=over

=item *

When the list will be initially created,
C<undef> must be specified explicitly
so that default parameter values will be completed.

=item *

When exisiting list will be instantiated and config will be loaded,
C<{}> (default) would be specified
so that default parameter values except optional ones
(with occurrence C<'0-1'> or C<'0-n'>) will be completed.

=item *

Otherwise, default parameter values are completed
only when the new paragraph node will be added.

=back

=item copy =E<gt> 1

Uses deep copy of initial configuration (see L</"config">)
instead of real reference.

=item no_family =E<gt> 1

Won't apply family constraint.
By default, the constraint will be applied if the list is belonging to
family.

=back

=item get ( $ppath )

I<Instance method>.
Gets copy of current value of parameter.

Parameter:

=over

=item $ppath

Parameter path,
e.g. C<'owner.0.email'> specifys "email" parameter of
the first "owner" paragraph.

=back

Returns:

Value of parameter.
If parameter or value does not exist, returns C<undef> in scalar context
and an empty list in array context.

=item get_change ( $ppath )

I<Instance method>.
Gets copy of submitted change on parameter.

Parameter:

=over

=item $ppath

Parameter path.
See also get().

=back

Returns:

If value won't be changed, returns empty list in array context
and C<undef> in scalar context.
If value would be deleted, returns C<undef>.

=item get_changeset ( )

I<Instance method>.
Gets all submitted changes.

Note that returned value is the real reference to internal information.
Any modifications might break it.

=item get_schema ( [ $user ] )

I<Instance method>.
TDB.

=item keys ( [ $pname ] )

I<Instance method>.
Gets parameter keys in order defined by schema.

Parameter:

=over

=item $pname

Full parameter name.
If omitted or false value,
returns keys of top-level parameters.

=back

Returns:

List of keys.
If parameter does not exist or it does not have sub-parameters,
i.e. it is not the paragraph, empty list.

=item submit ( $new, $user, \@errors )

I<Instance method>.
Submits change and verifys it.
TBD.

=item commit ( [ \@errors ] )

I<Instance method>.
Merges change verified by sbumit() into actual configuration.
TBD.

=back

=head2 Attribute

=over

=item {context}

Context, L<Sympa::List> instance.

=back

=head1 SEE ALSO

L<Sympa::List>,
L<Sympa::ListDef>.

=head1 HISTORY

L<Sympa::List::Config> appeared on Sympa 6.2.17.

=cut

# -*- indent-tabs-mode: nil; -*-
