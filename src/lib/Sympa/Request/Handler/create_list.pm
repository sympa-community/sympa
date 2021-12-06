# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018, 2019, 2020, 2021 The Sympa Community. See the
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

package Sympa::Request::Handler::create_list;

use strict;
use warnings;
use Encode qw();
use English qw(-no_match_vars);

use Sympa;
use Sympa::Aliases;
use Conf;
use Sympa::Config_XML;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Template;
use Sympa::Tools::Text;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_regexp   => qr{reject|listmaster|do_it}i;
use constant _action_scenario => 'create_list';

# Old name: Sympa::Admin::create_list_old().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot_id = $request->{context};
    my $param    = $request->{parameters};
    my $pending  = $request->{pending};
    my $notify   = $request->{notify};
    my $sender   = $request->{sender};

    my $path;

    if ($param->{file}) {
        $path = $param->{file};

        # Get list data
        $param = Sympa::Config_XML->new($path)->as_hashref;
        unless ($param) {
            $log->syslog('err',
                "Error in representation data with these xml data");
            $self->add_stash($request, 'user', 'XXX');
            return undef;
        }
    }

    my $listname = lc $param->{listname};

    # Obligatory parameters.
    foreach my $arg (qw(subject type topics)) {
        unless (defined $param->{$arg} and $param->{$arg} =~ /\S/) {
            $self->add_stash($request, 'user', 'missing_arg',
                {argument => $arg});
            $log->syslog('err', 'Missing list parameter "%s"', $arg);
            return undef;
        }
    }

    # The 'other' topic means no topic.
    $param->{topics} = lc $param->{topics};
    delete $param->{topics} if $param->{topics} eq 'other';
    # Sanytize editor.
    $param->{editor} =
        [grep { ref $_ eq 'HASH' and $_->{email} } @{$param->{editor} || []}];

    # owner.email || owner_include.source
    _check_owner_defined($param);
    unless (@{$param->{'owner'} || []} or @{$param->{'owner_include'} || []})
    {
        $log->syslog('err',
            'Problem in owner definition in this list creation');
        $self->add_stash($request, 'user', 'missing_arg',
            {argument => 'owner'})
            unless @{$param->{'owner'} || []};
        $self->add_stash($request, 'user', 'missing_arg',
            {argument => 'owner_include'})
            unless @{$param->{'owner_include'} || []};
        return undef;
    }

    # Check new listname.
    my @stash = Sympa::Aliases::check_new_listname($listname, $robot_id);
    if (@stash) {
        $self->add_stash($request, @stash);
        return undef;
    }

    ## Check the template supposed to be used exist.
    my $template_file =
        Sympa::search_fullpath($robot_id, 'config.tt2',
        subdir => 'create_list_templates/' . $param->{type});
    unless (defined $template_file) {
        $log->syslog('err', 'No template %s found', $param->{type});
        $self->add_stash($request, 'user', 'unknown_template',
            {tpl => $param->{type}});
        return undef;
    }

    ## Create the list directory
    my $list_dir;
    my $home = $Conf::Conf{'home'};
    my $base = $home . '/' . $robot_id;
    if (-d $base) {
        $list_dir = $base . '/' . $listname;
    } elsif ($robot_id eq $Conf::Conf{'domain'}) {
        # Default robot.
        $list_dir = $home . '/' . $listname;
    } else {
        $log->syslog('err', 'Unknown robot %s', $robot_id);
        $self->add_stash($request, 'user', 'unknown_robot',
            {new_robot => $robot_id});
        return undef;
    }

    ## Check the privileges on the list directory
    unless (mkdir $list_dir, 0775) {
        $log->syslog('err', 'Unable to create %s: %m', $list_dir);
        $self->add_stash($request, 'intern');
        return undef;
    }

    ### Check topics
    #if ($param->{'topics'}) {
    #    unless (check_topics($param->{'topics'}, $robot_id)) {
    #        $log->syslog('err', 'Topics param %s not defined in topics.conf',
    #            $param->{'topics'});
    #    }
    #}

    # Creation of the config file.
    $param->{'listname'}               = $listname;
    $param->{'creation'}{'date_epoch'} = time;
    $param->{'creation'}{'date'}       = 'obsoleted';    # For compatibility.
    $param->{'creation_email'} ||= $sender;
    $param->{'status'} ||= 'open';
    $param->{'status'} = 'pending' if $pending;

    # Lock config before opening the config file.
    my $lock_fh = Sympa::LockedFile->new($list_dir . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %m', $list_dir);
        $self->add_stash($request, 'intern');
        return undef;
    }

    my $config = '';
    my $template =
        Sympa::Template->new($robot_id,
        subdir => 'create_list_templates/' . $param->{type});
    unless ($template->parse($param, 'config.tt2', \$config)) {
        $log->syslog('err', 'Can\'t parse %s/config.tt2: %s',
            $param->{type}, $template->{last_error});
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Write config.
    # - Write out initial permanent owners/editors in <role>.dump files.
    # - Write reminder to config file.
    $config =~ s/(\A|\n)[\t ]+(?=\n)/$1/g;    # normalize empty lines
    open my $ifh, '<', \$config;              # open "in memory" file
    my @config = do { local $RS = ''; <$ifh> };
    close $ifh;
    foreach my $role (qw(owner editor)) {
        my $file = $list_dir . '/' . $role . '.dump';
        if (!-e $file and open my $ofh, '>', $file) {
            my $admins = join '', grep {/\A\s*$role\b/} @config;
            print $ofh $admins;
            close $ofh;
        }
    }
    print $lock_fh join '', grep { !/\A\s*(owner|editor)\b/ } @config;

    ## Unlock config file
    $lock_fh->close;

    ## Creation of the info file
    my $fh;
    unless (open $fh, '>', "$list_dir/info") {
        $log->syslog('err', 'Impossible to create %s/info: %m', $list_dir);
    } elsif (defined $param->{'description'}) {
        print $fh Sympa::Tools::Text::canonic_text($param->{'description'});
    }
    close $fh;

    # Create list object.
    my $list;
    unless ($list = Sympa::List->new($listname, $robot_id)) {
        $log->syslog('err', 'Unable to create list %s', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Store initial permanent list users.
    $list->restore_users('member');
    $list->restore_users('owner');
    $list->restore_users('editor');

    #FIXME
    #if ($listname ne $request->{listname}) {
    #    $self->add_stash($request, 'notice', 'listname_lowercased');
    #}

    if ($list->{'admin'}{'status'} eq 'open') {
        # Install new aliases.
        my $aliases = Sympa::Aliases->new(
            Conf::get_robot_conf($robot_id, 'alias_manager'));
        if ($aliases and $aliases->add($list)) {
            $self->add_stash($request, 'notice', 'auto_aliases');
        }
    } elsif ($list->{'admin'}{'status'} eq 'pending') {
        # Notify listmaster that creation list is moderated.
        Sympa::send_notify_to_listmaster($list, 'request_list_creation',
            {'email' => $sender})
            if $notify;

        $self->add_stash($request, 'notice', 'pending_list');
    }

    ## Create shared if required.
    #if (defined $list->{'admin'}{'shared_doc'}) {
    #    $list->create_shared();
    #}

    # Log in stat_table to make statistics
    $log->add_stat(
        'robot'     => $robot_id,
        'list'      => $listname,
        'operation' => 'create_list',
        'parameter' => '',
        'mail'      => $request->{sender},
    );

    # Synchronize list members if required
    $log->syslog('notice', "Synchronizing list members...");
    $list->sync_include('member');
    $log->syslog('notice', "...done");

    $list->save_config($sender);
    return 1;
}

# Verify if they are any owner defined:
# It must exist at least one parameter owner or owner_include.
# The owner must have sub parameter {email}.
# The owner_include must have sub parameter {source}.
#
# Originally moved from: Sympa::Admin::check_owner_defined().
sub _check_owner_defined {
    my $param = shift;

    my $owner         = $param->{owner};
    my $owner_include = $param->{owner_include};

    my @owner =
        grep { ref $_ eq 'HASH' and $_->{email} }
        ((ref $owner eq 'ARRAY') ? @$owner : ($owner));
    my @owner_include =
        grep { ref $_ eq 'HASH' and $_->{source} }
        (
        (ref $owner_include eq 'ARRAY') ? @$owner_include : ($owner_include));
    @{$param}{qw(owner owner_include)} = ([@owner], [@owner_include]);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::create_list - create_list request handler

=head1 DESCRIPTION

TBD.

=head1 HISTORY

L<Sympa::Request::Handler::create_list> appeared on Sympa 6.2.23b.

=cut
