# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
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

package Sympa::Request::Handler::update_automatic_list;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Copy qw();

use Sympa;
use Conf;
use Sympa::Config_XML;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Template;

use base qw(Sympa::Request::Handler);

use constant _action_scenario => undef;            # Only listmasters allowed.
use constant _context_class   => 'Sympa::Family';

my $log = Sympa::Log->instance;

# Old name: Sympa::Admin::update_list(), Sympa::Family::_update_list().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $family   = $request->{context};
    my $list     = $request->{current_list};
    my $param    = $request->{parameters};
    my $robot_id = $family->{'domain'};

    my $path;

    if ($param->{file}) {
        $path = $param->{file};
        # get list data
        $param = Sympa::Config_XML->new($path)->as_hashref;
        unless ($param) {
            $log->syslog('err',
                "Error in representation data with these xml data");
            $self->add_stash($request, 'user', 'XXX');
            return undef;
        }
    }

    # getting list
    if ($list and $param->{listname}) {
        unless ($list->get_id eq
            sprintf('%s@%s', lc $param->{listname}, $family->{'domain'})) {
            $log->syslog('err', 'The list %s and list name %s mismatch',
                $list, $param->{listname});
            $self->add_stash($request, 'user', 'XXX');
            return undef;
        }
    } elsif (
        $list
        or ($list = Sympa::List->new(
                $param->{listname}, $family->{'domain'},
                {just_try => 1, no_check_family => 1}
            )
        )
    ) {
        $param->{listname} = $list->{'name'};
    } else {
        $log->syslog('err', 'The list "%s" does not exist',
            $param->{listname});
        $self->add_stash($request, 'user', 'XXX');
        return undef;
    }

    ## check family name
    if (defined $list->{'admin'}{'family_name'}) {
        unless ($list->{'admin'}{'family_name'} eq $family->{'name'}) {
            $log->syslog('err',
                "The list $list->{'name'} already belongs to family $list->{'admin'}{'family_name'}."
            );
            $self->add_stash($request, 'user', 'listname_already_used');
            return undef;
        }
    } else {
        $log->syslog('err',
            "The orphan list $list->{'name'} already exists.");
        $self->add_stash($request, 'user', 'listname_already_used');
        return undef;
    }

    # Get allowed and forbidden list customizing.
    my $custom = _get_customizing($family, $list);
    unless (defined $custom) {
        $log->syslog('err', 'Impossible to get list %s customizing', $list);
        $self->add_stash($request, 'intern');
        return undef;
    }
    my $config_changes = $custom->{'config_changes'};
    my $old_status     = $list->{'admin'}{'status'};

    # Check the template supposed to be used exist.
    my $template_file = Sympa::search_fullpath($family, 'config.tt2');
    unless (defined $template_file) {
        $log->syslog('err', 'No config template from family %s', $family);
        $self->add_stash($request, 'intern');
        return undef;
    }

    my $config = '';
    my $template =
        Sympa::Template->new(undef, include_path => [$family->{'dir'}]);
    unless ($template->parse($param, 'config.tt2', \$config)) {
        $log->syslog('err', 'Can\'t parse %s/config.tt2: %s',
            $family->{'dir'}, $template->{last_error});
        $self->add_stash($request, 'intern');
        return undef;
    }

    ### Check topics
    #if (defined $param->{'topics'}) {
    #    unless (_check_topics($param->{'topics'}, $robot_id)) {
    #        $log->syslog('err', 'Topics param %s not defined in topics.conf',
    #            $param->{'topics'});
    #    }
    #}

    ## Lock config before openning the config file
    my $lock_fh = Sympa::LockedFile->new($list->{'dir'} . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %s',
            $list->{'dir'}, $ERRNO);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Write config. NOTE: Unlike list creation, files will be overwritten.
    # - Write out permanent owners/editors in <role>.dump files.
    # - Write remainder to config file.
    $config =~ s/(\A|\n)[\t ]+(?=\n)/$1/g;    # normalize empty lines
    open my $ifh, '<', \$config;              # open "in memory" file
    my @config = do { local $RS = ''; <$ifh> };
    close $ifh;
    foreach my $role (qw(owner editor)) {
        # No update needed if modification allowed.
        next if $custom->{allowed}->{$role};

        my $file = $list->{'dir'} . '/' . $role . '.dump';
        unlink "$file.old";
        rename $file, "$file.old";
        if (open my $ofh, '>', $file) {
            my $admins = join '', grep {/\A\s*$role\b/} @config;
            print $ofh $admins;
            close $ofh;
        }
    }
    print $lock_fh join '', grep { !/\A\s*(owner|editor)\b/ } @config;

    ## Unlock config file
    $lock_fh->close;

    #FIXME: Would info file be updated?

    ## Create associated files if a template was given.
    my @files_to_parse;
    foreach my $file (split /\s*,\s*/,
        Conf::get_robot_conf($robot_id, 'parsed_family_files')) {
        # Compat. <= 6.2.38: message.* were moved to message_*.
        $file =~ s/\Amessage[.](header|footer)\b/message_$1/;

        push @files_to_parse, $file;
    }
    for my $file (@files_to_parse) {
        # Compat. <= 6.2.38: message.* were obsoleted by message_*.
        my $file_obs;
        if ($file =~ /\Amessage_(header|footer)\b(.*)\z/) {
            $file_obs = "message.$1$2";
        }
        my $template_file = Sympa::search_fullpath($family, $file . '.tt2');
        $template_file = Sympa::search_fullpath($family, $file_obs . '.tt2')
            if not $template_file and $file_obs;

        if (defined $template_file) {
            my $file_content;

            my $template =
                Sympa::Template->new(undef,
                include_path => [$family->{'dir'}]);
            my $tt_result =
                $template->parse($param, $file . ".tt2", \$file_content);
            unless ($tt_result) {
                $log->syslog(
                    'err',
                    'Template error. List %s from family %s@%s, file %s: %s',
                    $param->{'listname'},
                    $family->{'name'},
                    $robot_id,
                    $file,
                    $template->{last_error}
                );
                next;    #FIXME: Abort processing and rollback.
            }
            unless (open FILE, '>', "$list->{'dir'}/$file") {
                $log->syslog('err', 'Impossible to create %s/%s: %s',
                    $list->{'dir'}, $file, $!);
            }
            print FILE $file_content;
            close FILE;
        }
    }

    ## Create list object
    my $listname = $list->{'name'};
    unless ($list =
        Sympa::List->new($listname, $robot_id, {no_check_family => 1})) {
        $log->syslog('err', 'Unable to create list %s', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Update permanent list users.
    # No update needed if modification allowed.
    $list->restore_users('owner')  unless $custom->{allowed}->{owner};
    $list->restore_users('editor') unless $custom->{allowed}->{editor};

    # Restore list customizations.
    foreach my $p (keys %{$custom->{'allowed'}}) {
        $list->{'admin'}{$p} = $custom->{'allowed'}{$p};
        delete $list->{'admin'}{'defaults'}{$p};
        $log->syslog('info', 'Customizing: Keeping values for parameter %s',
            $p);
    }

    # Update info file.
    unless ($config_changes->{'file'}{'info'}) {
        my $description =
            (defined $param->{description}) ? $param->{description} : '';
        $description =~ s/\r\n|\r/\n/g;

        if (open my $fh, '>', $list->{'dir'} . '/info') {
            print $fh $description;
            close $fh;
        } else {
            $log->syslog('err', 'Impossible to open %s/info: %m',
                $list->{'dir'});
        }
    }
    # Changed files
    foreach my $f (keys %{$config_changes->{'file'}}) {
        $log->syslog('info', 'Customizing: This file has been changed: %s',
            $f);
    }
    #FIXME: would be better to rename forbidden files?

    #FIXME: Not saved?
    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    $list->{'admin'}{'creation'}{'email'}      = $param->{'creation_email'}
        || Sympa::get_address($robot_id, 'listmaster');
    $list->{'admin'}{'status'} = $param->{'status'} || 'open';
    $list->{'admin'}{'family_name'} = $family->{'name'};

    # Synchronize list members if required
    $log->syslog('notice', "Synchronizing list members...");
    $list->sync_include('member');
    $log->syslog('notice', "...done");

    # (Note: Following block corresponds to previous _set_status_changes()).
    my $current_status = $list->{'admin'}{'status'} || 'open';
    # Update aliases.
    if ($current_status eq 'open' and not($old_status eq 'open')) {
        my $aliases = Sympa::Aliases->new(
            Conf::get_robot_conf($list->{'domain'}, 'alias_manager'));
        if ($aliases and $aliases->add($list)) {
            $self->add_stash($request, 'notice', 'auto_aliases');
        }
    } elsif ($current_status eq 'pending'
        and ($old_status eq 'open' or $old_status eq 'error_config')) {
        my $aliases = Sympa::Aliases->new(
            Conf::get_robot_conf($list->{'domain'}, 'alias_manager'));
        $aliases and $aliases->del($list);
    }

    # Update config_changes.
    delete @{$config_changes->{'param'}}{@{$custom->{'forbidden'}{'param'}}};
    if (open my $ofh, '>', $list->{'dir'} . '/config_changes') {
        close $ofh;
    } else {
        $log->syslog('err', 'Impossible to open file %s/config_changes: %m',
            $list->{'dir'});
        $self->add_stash($request, 'intern');
        $list->set_status_error_config('error_copy_file', $self->{'name'});
    }
    my @kept_param = keys %{$config_changes->{'param'}};
    $list->update_config_changes('param', \@kept_param);
    my @kept_files = keys %{$config_changes->{'file'}};
    $list->update_config_changes('file', \@kept_files);

    # Notify owner for forbidden customizing.
    if (@{$custom->{forbidden}{param} || []}) {
        my $forbidden_param = join ',', @{$custom->{forbidden}{param}};
        $log->syslog(
            'notice',
            'These parameters aren\'t allowed in the new family definition, they are erased by a new instantiation family: %s',
            $forbidden_param
        );
        $list->send_notify_to_owner('erase_customizing',
            [$family->{'name'}, $forbidden_param]);
    }

    # info parameters
    $list->{'admin'}{'latest_instantiation'}{'email'} =
        Sympa::get_address($family, 'listmaster');
    $list->{'admin'}{'latest_instantiation'}{'date_epoch'} = time;
    $list->save_config(Sympa::get_address($family, 'listmaster'));
    $list->{'family'} = $family;

    # Check param_constraint.conf
    my $error = $family->check_param_constraint($list);

    unless (defined $error) {
        $list->set_status_error_config('no_check_rules_family',
            $family->{'name'});
        $self->add_stash($request, 'intern');
        $log->syslog('err', 'Impossible to check parameters constraint');
        return undef;
    }
    if (ref $error eq 'ARRAY') {
        $list->set_status_error_config('no_respect_rules_family',
            $family->{'name'});
        $self->add_stash($request, 'user', 'not_respect_rules_family',
            {errors => $error});
        $log->syslog('err', 'The list does not respect the family rules : %s',
            join ', ', @{$error});
    }

    # Copy files in the list directory : xml file
    if ($path and $path ne $list->{'dir'} . '/instance.xml') {
        unless (File::Copy::copy($path, $list->{'dir'} . '/instance.xml')) {
            $list->set_status_error_config('error_copy_file',
                $family->{'name'});
            $self->add_stash($request, 'intern');
            $log->syslog('err',
                'Impossible to copy the XML file in the list directory');
        }
    }

    return 1;
}

# Gets list customizations from the config_changes file and keeps on changes
# allowed by param_constraint.conf.
#
# Parameters:
# * $list, a List object corresponding to the list we want to check.
#
# Returns:
# Hashref containing following items:
# * {config_changes}   the list config_changes.
# * {allowed}          a hash of allowed parameters: ($param,$values).
# * {forbidden}{param} an arrayref.
# * {forbidden}{file}  an arrayref (not working).
#
# Old name: Sympa::Family::_get_customizing().
sub _get_customizing {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $family = shift;
    my $list   = shift;

    my $result;
    my $config_changes = $list->get_config_changes;

    unless (defined $config_changes) {
        $log->syslog('err', 'Impossible to get config_changes');
        return undef;
    }

    ## FILES
    #foreach my $f (keys %{$config_changes->{'file'}}) {
    #    my $privilege; # =may_edit($f)
    #
    #    unless ($privilege eq 'write') {
    #        push @{$result->{'forbidden'}{'file'}},$f;
    #    }
    #}

    ## PARAMETERS

    # Get customizing values.
    # Special cases: "owner" and "editor" are not real parameters.
    my $changed_values;
    foreach my $p (keys %{$config_changes->{'param'}}) {
        $changed_values->{$p} =
            ($p eq 'owner' or $p eq 'editor') ? [] : $list->{'admin'}{$p};
    }

    # check these values
    my $constraint = $family->get_constraints();
    unless (defined $constraint) {
        $log->syslog('err', 'Unable to get family constraints',
            $family->{'name'}, $list->{'name'});
        return undef;
    }

    my $fake_list =
        bless {'domain' => $list->{'domain'}, 'admin' => $changed_values} =>
        'Sympa::List';
    # TODO: update parameter cache

    foreach my $param (keys %{$constraint}) {
        my $constraint_value = $constraint->{$param};
        my $param_value;
        my $value_error;

        unless (defined $constraint_value) {
            $log->syslog(
                'err',
                'No value constraint on parameter %s in param_constraint.conf',
                $param
            );
            next;
        }

        $param_value = $fake_list->get_param_value($param, 1);

        $value_error = $family->check_values($param_value, $constraint_value);

        foreach my $v (@{$value_error}) {
            push @{$result->{'forbidden'}{'param'}}, $param;
            $log->syslog('err', 'Error constraint on parameter %s, value: %s',
                $param, $v);
        }
    }

    # Keep allowed values.
    foreach my $param (@{$result->{'forbidden'}{'param'}}) {
        if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
            $param = $1;
        }

        if (defined $changed_values->{$param}) {
            delete $changed_values->{$param};
        }
    }
    $result->{'allowed'} = $changed_values;

    $result->{'config_changes'} = $config_changes;
    return $result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::update_automatic_list -
update_automatic_list request handler

=head1 DESCRIPTION

Update a list with family concept when the list already exists.

TBD.

=head1 HISTORY

L<Sympa::Request::Handler::update_automatic_list> appeared on Sympa 6.2.33b.2.

=cut
