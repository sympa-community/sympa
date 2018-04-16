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

package Sympa::Request::Handler::create_automatic_list;

use strict;
use warnings;
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

use constant _action_regexp   => qr{reject|do_it}i;
use constant _action_scenario => 'automatic_list_creation';
use constant _context_class   => 'Sympa::Family';

# Old names: Merger of Sympa::Admin::create_list(), Sympa::Family::add_list().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $family         = $request->{context};
    my $listname       = lc($request->{listname} || '');
    my $param          = $request->{parameters};
    my $abort_on_error = $request->{abort_on_error};
    my $robot_id       = $family->{'robot'};

    die 'bug in logic. Ask developer' unless ref $family eq 'Sympa::Family';
    $family->{'state'} = 'no_check';

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
    my $template_file = Sympa::search_fullpath($family, 'config.tt2');
    unless (defined $template_file) {
        $log->syslog('err', 'No config template from family %s', $family);
        $self->add_stash($request, 'intern');
        return undef;
    }

    my $family_config =
        Conf::get_robot_conf($robot_id, 'automatic_list_families');
    $param->{'family_config'} = $family_config->{$family->{'name'}};
    $param->{'listname'}      = $listname;

    my $config = '';
    my $template =
        Sympa::Template->new(undef, include_path => [$family->{'dir'}]);
    my $tt_result = $template->parse($param, 'config.tt2', \$config);
    if (not $tt_result and $abort_on_error) {
        $log->syslog(
            'err',
            'Abort on template error. List %s from family %s, file config.tt2 : %s',
            $listname,
            $family,
            $template->{last_error}
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    ## Create the list directory
    my $list_dir;
    if (-d $Conf::Conf{'home'} . '/' . $robot_id) {
        $list_dir = $Conf::Conf{'home'} . '/' . $robot_id . '/' . $listname;
    } elsif ($robot_id eq $Conf::Conf{'domain'}) {
        $list_dir = $Conf::Conf{'home'} . '/' . $listname;
    } else {
        $log->syslog('err', 'Unknown robot %s', $robot_id);
        $self->add_stash($request, 'user', 'unknown_robot',
            {new_robot => $robot_id});
        return undef;
    }

    ## Check the privileges on the list directory
    unless (-r $list_dir or mkdir $list_dir, 0775) {
        $log->syslog('err', 'Unable to create %s: %m', $list_dir);
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
    my $lock_fh = Sympa::LockedFile->new($list_dir . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %m', $list_dir);
        $self->add_stash($request, 'intern');
        return undef;
    }
    print $lock_fh $config;

    ## Unlock config file
    $lock_fh->close;

    ## Creation of the info file
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and
    # EIMS:
    if (defined $param->{'description'}) {
        $param->{'description'} =~ s/\r\n|\r/\n/g;
    }

    if (open my $fh, '>', "$list_dir/info") {
        print $fh $param->{'description'} if defined $param->{'description'};
        close $fh;
    } else {
        $log->syslog('err', 'Impossible to create %s/info: %m', $list_dir);
    }

    ## Create associated files if a template was given.
    my @files_to_parse;
    foreach my $file (split ',',
        Conf::get_robot_conf($robot_id, 'parsed_family_files')) {
        $file =~ s{\s}{}g;
        push @files_to_parse, $file;
    }
    for my $file (@files_to_parse) {
        my $template_file = Sympa::search_fullpath($family, $file . ".tt2");
        if (defined $template_file) {
            my $file_content;
            my $template =
                Sympa::Template->new(undef,
                include_path => [$family->{'dir'}]);
            my $tt_result =
                $template->parse($param, $file . ".tt2", \$file_content);
            unless (defined $tt_result) {
                $log->syslog(
                    'err',
                    'Template error. List %s from family %s, file %s : %s',
                    $listname,
                    $family,
                    $file,
                    $template->{last_error}
                );
            }
            my $fh;
            unless (open $fh, '>', $list_dir . '/' . $file) {
                $log->syslog('err', 'Impossible to create %s/%s: %m',
                    $list_dir, $file);
            } else {
                print $fh $file_content;
                close $fh;
            }
        }
    }

    ## Create list object
    my $list;
    unless ($list = Sympa::List->new($listname, $robot_id)) {
        $log->syslog('err', 'Unable to create list %s', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }

    if ($listname ne $request->{listname}) {
        $self->add_stash($request, 'notice', 'listname_lowercased');
    }

    ## Create shared if required.
    #if (defined $list->{'admin'}{'shared_doc'}) {
    #    $list->create_shared();
    #}

    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    $list->{'admin'}{'creation'}{'email'}      = $param->{'creation_email'}
        || Sympa::get_address($robot_id, 'listmaster');
    $list->{'admin'}{'status'} = $param->{'status'} || 'open';
    $list->{'admin'}{'family_name'} = $family->{'name'};

    if ($list->{'admin'}{'status'} eq 'open') {
        my $aliases = Sympa::Aliases->new(
            Conf::get_robot_conf($list->{'domain'}, 'alias_manager'));
        if ($aliases and $aliases->add($list)) {
            $self->add_stash($request, 'notice', 'auto_aliases');
        }
    } else {
        ;
    }

    #FIXME: add_stat().

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

    # config_changes
    if (open my $fh, '>', "$list->{'dir'}/config_changes") {
        close $fh;
    } else {
        $self->add_stash($request, 'intern', $ERRNO);
        $list->set_status_error_config('error_copy_file', $family->{'name'});
    }

    # info parameters
    $list->{'admin'}{'latest_instantiation'}{'email'} =
        Sympa::get_address($family, 'listmaster');
    $list->{'admin'}{'latest_instantiation'}{'date_epoch'} = time;
    $list->save_config(Sympa::get_address($family, 'listmaster'));
    $list->{'family'} = $family;

    ## check param_constraint.conf
    $family->{'state'} = 'normal';
    my $error = $family->check_param_constraint($list);
    $family->{'state'} = 'no_check';

    unless (defined $error) {
        $list->set_status_error_config('no_check_rules_family',
            $family->{'name'});
        $self->add_stash($request, 'intern');
        return undef;
    }
    if (ref $error eq 'ARRAY') {
        $list->set_status_error_config('no_respect_rules_family',
            $family->{'name'});
        $self->add_stash($request, 'user', 'not_respect_rules_family',
            {errors => $error});
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

    ## END
    $family->{'state'} = 'normal';

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::create_automatic_list -
create_automatic_list request handler

=head1 DESCRIPTION

Adds a list to the family. List description can be passed through a hash of
data.

TBD.

=head1 HISTORY

L<Sympa::Request::Handler::create_automatic_list> appeared on Sympa 6.2.23b.

=cut
