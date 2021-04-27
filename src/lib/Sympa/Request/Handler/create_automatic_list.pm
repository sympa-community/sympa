# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018, 2019, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::Request::Handler::create_automatic_list;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Copy qw();

use Sympa;
use Sympa::Aliases;
use Conf;
use Sympa::Config_XML;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
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
    my $param          = $request->{parameters};
    my $abort_on_error = $request->{abort_on_error};
    my $robot_id       = $family->{'domain'};

    my $path;

    die 'bug in logic. Ask developer' unless ref $family eq 'Sympa::Family';

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
    # Check new listname.
    my @stash = Sympa::Aliases::check_new_listname($listname, $robot_id);
    if (@stash) {
        $self->add_stash($request, @stash);
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
    unless ($list =
        Sympa::List->new($listname, $robot_id, {no_check_family => 1})) {
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

    # Synchronize list members if required
    $log->syslog('notice', "Synchronizing list members...");
    $list->sync_include('member');
    $log->syslog('notice', "...done");

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

    # Check param_constraint.conf
    my $error = $family->check_param_constraint($list);

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

    # Synchronize list members if required
    $log->syslog('notice', "Synchronizing list members...");
    $list->sync_include('member');
    $log->syslog('notice', "...done");

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
