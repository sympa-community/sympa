# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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
use Sympa::Constants;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Template;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_regexp   => qr{reject|listmaster|do_it}i;
use constant _action_scenario => 'create_list';

# Old name: Sympa::Admin::create_list_old().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot_id = $request->{context};
    my $listname = lc($request->{listname} || '');
    my $param    = $request->{parameters};
    my $pending  = $request->{pending};
    my $notify   = $request->{notify};
    my $sender   = $request->{sender};

    # Obligatory parameters.
    foreach my $arg (qw(subject template topics)) {
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

    # Check listname.
    my $listname_re = Sympa::Regexps::listname();
    unless (defined $listname
        and $listname =~ /^$listname_re$/i
        and length $listname <= Sympa::Constants::LIST_LEN()) {
        $log->syslog('err', 'Incorrect listname %s', $listname);
        $self->add_stash($request, 'user', 'incorrect_listname',
            {bad_listname => $listname});
        return undef;
    }

    my $regx = Conf::get_robot_conf($robot_id, 'list_check_regexp');
    if ($regx) {
        if ($listname =~ /^(\S+)-($regx)$/) {
            $log->syslog('err',
                'Incorrect listname %s matches one of service aliases',
                $listname);
            $self->add_stash($request, 'user', 'listname_matches_aliases',
                {new_listname => $listname});
            return undef;
        }
    }

    if (   $listname eq Conf::get_robot_conf($robot_id, 'email')
        or $listname eq Conf::get_robot_conf($robot_id, 'listmaster_email')) {
        $log->syslog('err',
            'Incorrect listname %s matches one of service aliases',
            $listname);
        $self->add_stash($request, 'user', 'listname_matches_aliases',
            {new_listname => $listname});
        return undef;
    }

    ## Check listname on SMTP server
    my $aliases =
        Sympa::Aliases->new(Conf::get_robot_conf($robot_id, 'alias_manager'));
    my $res = $aliases->check($listname, $robot_id) if $aliases;
    unless (defined $res) {
        $log->syslog('err', 'Can\'t check list %.128s on %s',
            $listname, $robot_id);
        $self->add_stash($request, 'intern');
        return undef;
    }

    ## Check this listname doesn't exist already.
    if ($res or Sympa::List->new($listname, $robot_id, {'just_try' => 1})) {
        $log->syslog('err',
            'Could not create list %s: list on %s already exist',
            $listname, $robot_id);
        $self->add_stash($request, 'user', 'list_already_exists',
            {new_listname => $listname});
        return undef;
    }

    ## Check the template supposed to be used exist.
    my $template_file =
        Sympa::search_fullpath($robot_id, 'config.tt2',
        subdir => 'create_list_templates/' . $param->{template});
    unless (defined $template_file) {
        $log->syslog('err', 'No template %s found', $param->{template});
        $self->add_stash($request, 'user', 'unknown_template',
            {tpl => $param->{template}});
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
        subdir => 'create_list_templates/' . $param->{'template'});
    unless ($template->parse($param, 'config.tt2', \$config)) {
        $log->syslog('err', 'Can\'t parse %s/config.tt2: %s',
            $param->{'template'}, $template->{last_error});
        $self->add_stash($request, 'intern');
        return undef;
    }

    print $lock_fh $config;

    ## Unlock config file
    $lock_fh->close;

    ## Creation of the info file
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and
    # EIMS:
    $param->{'description'} =~ s/\r\n|\r/\n/g;

    ## info file creation.
    my $fh;
    unless (open $fh, '>', "$list_dir/info") {
        $log->syslog('err', 'Impossible to create %s/info: %m', $list_dir);
    } elsif (defined $param->{'description'}) {
        Encode::from_to($param->{'description'},
            'utf8', $Conf::Conf{'filesystem_encoding'});
        print $fh $param->{'description'};
    }
    close $fh;

    # Create list object.
    my $list;
    unless ($list = Sympa::List->new($listname, $robot_id)) {
        $log->syslog('err', 'Unable to create list %s', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }

    if ($listname ne $request->{listname}) {
        $self->add_stash($request, 'notice', 'listname_lowercased');
    }

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
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

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
