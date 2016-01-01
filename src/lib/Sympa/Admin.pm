# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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

=encoding utf-8

#=head1 NAME 
#
#I<admin.pm> - This module includes administrative function for the lists.

=head1 DESCRIPTION 

Central module for creating and editing lists.

=cut 

package Sympa::Admin;

use strict;
use warnings;
use Encode qw();
use English qw(-no_match_vars);
use File::Copy qw();

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Robot;
use Sympa::Scenario;
use Sympa::Template;
use Sympa::Tools::File;
use Sympa::User;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by admin.pm 

=cut 

=pod 

=head2 sub create_list_old(HASHRef,STRING,STRING)

Creates a list. Used by the create_list() sub in sympa.pl and the do_create_list() sub in wwsympa.fcgi.

=head3 Arguments 

=over 

=item * I<$param>, a ref on a hash containing parameters of the config list. The following keys are mandatory:

=over 4

=item - I<$param-E<gt>{'listname'}>,

=item - I<$param-E<gt>{'subject'}>,

=item - I<$param-E<gt>{'owner'}>, (or owner_include): array of hashes, with key email mandatory

=item - I<$param-E<gt>{'owner_include'}>, array of hashes, with key source mandatory

=back

=item * I<$list_tpl>, a string containing the list creation template

=item * I<$robot>, a string containing the name of the robot the list will be hosted by.

=back 

=head3 Return 

=over 

=item * I<undef>, if something prevents the list creation

=item * I<a reference to a hash>, if the list is normally created. This hash contains two keys:

=over 4

=item - I<list>, the list object corresponding to the list just created

=item - I<aliases>, undef if not applicable; 1 (if ok) or $aliases : concatenated string of aliases if they are not installed or 1 (in status open)

=back

=back 

=cut 

########################################################
# create_list_old
########################################################
# Create a list : used by sympa.pl--create_list and
#                 wwsympa.fcgi--do_create_list
# without family concept
#
# IN  : - $param : ref on parameters of the config list
#         with obligatory :
#         $param->{'listname'}
#         $param->{'subject'}
#         $param->{'owner'} (or owner_include):
#          array of hash,with key email obligatory
#         $param->{'owner_include'} array of hash :
#              with key source obligatory
#       - $list_tpl : the create list template
#       - $robot : the list's robot
#       - $origin : the source of the command : web, soap or command_line
#              no longer used
# OUT : - hash with keys :
#          -list :$list
#          -aliases : undef if not applicable; 1 (if ok) or
#           $aliases : concated string of alias if they
#           are not installed or 1(in status open)
#######################################################
sub create_list_old {
    my ($param, $list_tpl, $robot, $origin, $user_mail) = @_;
    $log->syslog('debug', '(%s, %s)', $param->{'listname'}, $robot, $origin);

    ## obligatory list parameters
    foreach my $arg ('listname', 'subject') {
        unless ($param->{$arg}) {
            $log->syslog('err', 'Missing list param %s', $arg);
            return undef;
        }
    }
    # owner.email || owner_include.source
    unless (check_owner_defined($param->{'owner'}, $param->{'owner_include'}))
    {
        $log->syslog('err',
            'Problem in owner definition in this list creation');
        return undef;
    }

    # template
    unless ($list_tpl) {
        $log->syslog('err', 'Missing param "template"', $list_tpl);
        return undef;
    }
    # robot
    unless ($robot) {
        $log->syslog('err', 'Missing param "robot"', $robot);
        return undef;
    }

    ## check listname
    $param->{'listname'} = lc($param->{'listname'});
    my $listname_regexp = Sympa::Regexps::listname();

    unless ($param->{'listname'} =~ /^$listname_regexp$/i
        and length $param->{'listname'} <= Sympa::Constants::LIST_LEN()) {
        $log->syslog('err', 'Incorrect listname %s', $param->{'listname'});
        return undef;
    }

    my $regx = Conf::get_robot_conf($robot, 'list_check_regexp');
    if ($regx) {
        if ($param->{'listname'} =~ /^(\S+)-($regx)$/) {
            $log->syslog('err',
                'Incorrect listname %s matches one of service aliases',
                $param->{'listname'});
            return undef;
        }
    }

    if (   $param->{'listname'} eq Conf::get_robot_conf($robot, 'email')
        or $param->{'listname'} eq
        Conf::get_robot_conf($robot, 'listmaster_email')) {
        $log->syslog('err',
            'Incorrect listname %s matches one of service aliases',
            $param->{'listname'});
        return undef;
    }

    ## Check listname on SMTP server
    my $res = list_check_smtp($param->{'listname'}, $robot);
    unless (defined $res) {
        $log->syslog('err', 'Can\'t check list %.128s on %s',
            $param->{'listname'}, $robot);
        return undef;
    }

    ## Check this listname doesn't exist already.
    if ($res
        || Sympa::List->new($param->{'listname'}, $robot, {'just_try' => 1}))
    {
        $log->syslog('err',
            'Could not create already existing list %s on %s for',
            $param->{'listname'}, $robot);
        foreach my $o (@{$param->{'owner'}}) {
            $log->syslog('err', $o->{'email'});
        }
        return undef;
    }

    ## Check the template supposed to be used exist.
    my $template_file = Sympa::search_fullpath($robot, 'config.tt2',
        subdir => 'create_list_templates/' . $list_tpl);
    unless (defined $template_file) {
        $log->syslog('err', 'No template %s found', $list_tpl);
        return undef;
    }

    ## Create the list directory
    my $list_dir;

    # a virtual robot
    if (-d "$Conf::Conf{'home'}/$robot") {
        unless (-d $Conf::Conf{'home'} . '/' . $robot) {
            unless (mkdir $Conf::Conf{'home'} . '/' . $robot, 0777) {
                $log->syslog('err', 'Unable to create %s/%s: %s',
                    $Conf::Conf{'home'}, $robot, $ERRNO);
                return undef;
            }
        }
        $list_dir =
            $Conf::Conf{'home'} . '/' . $robot . '/' . $param->{'listname'};
    } else {
        $list_dir = $Conf::Conf{'home'} . '/' . $param->{'listname'};
    }

    ## Check the privileges on the list directory
    unless (mkdir $list_dir, 0777) {
        $log->syslog('err', 'Unable to create %s: %s', $list_dir, $ERRNO);
        return undef;
    }

    ## Check topics
    if ($param->{'topics'}) {
        unless (check_topics($param->{'topics'}, $robot)) {
            $log->syslog('err', 'Topics param %s not defined in topics.conf',
                $param->{'topics'});
        }
    }

    # Creation of the config file.
    #FIXME:should be unneccessary
    $param->{'creation'}{'date'} =
        $language->gettext_strftime("%d %b %Y at %H:%M:%S", localtime time);
    $param->{'creation'}{'date_epoch'} = time;
    $param->{'creation_email'} ||= Sympa::get_address($robot, 'listmaster');
    $param->{'status'} ||= 'open';

    ## Lock config before openning the config file
    my $lock_fh = Sympa::LockedFile->new($list_dir . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %m', $list_dir);
        return undef;
    }

    my $config = '';
    my $template =
        Sympa::Template->new($robot,
        subdir => 'create_list_templates/' . $list_tpl);
    unless ($template->parse($param, 'config.tt2', \$config)) {
        $log->syslog(
            'err',     'Can\'t parse %s/config.tt2: %s',
            $list_tpl, $template->{last_error}
        );
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
    unless (open INFO, '>', "$list_dir/info") {
        $log->syslog('err', 'Impossible to create %s/info: %m', $list_dir);
    }
    if (defined $param->{'description'}) {
        Encode::from_to($param->{'description'},
            'utf8', $Conf::Conf{'filesystem_encoding'});
        print INFO $param->{'description'};
    }
    close INFO;

    ## Create list object
    my $list;
    unless ($list = Sympa::List->new($param->{'listname'}, $robot)) {
        $log->syslog('err', 'Unable to create list %s', $param->{'listname'});
        return undef;
    }

    ## Create shared if required
    if (defined $list->{'admin'}{'shared_doc'}) {
        $list->create_shared();
    }

    #log in stat_table to make statistics

    if ($origin eq "web") {
        $log->add_stat(
            'robot'     => $robot,
            'list'      => $param->{'listname'},
            'operation' => 'create_list',
            'parameter' => '',
            'mail'      => $user_mail
        );
    }

    my $return = {};
    $return->{'list'} = $list;

    if ($list->{'admin'}{'status'} eq 'open') {
        $return->{'aliases'} = install_aliases($list);
    } else {
        $return->{'aliases'} = 1;
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

    $list->save_config($param->{'creation_email'});
    return $return;
}

########################################################
# create_list
########################################################
# Create a list : used by sympa.pl--instantiate_family
# with family concept
#
# IN  : - $param : ref on parameters of the config list
#         with obligatory :
#         $param->{'listname'}
#         $param->{'subject'}
#         $param->{'owner'} (or owner_include):
#          array of hash,with key email obligatory
#         $param->{'owner_include'} array of hash :
#              with key source obligatory
#       - $family : the family object
#       - $robot : the list's robot  ** No longer used.
#       - $abort_on_error : won't create the list directory on
#          tt2 process error (useful for dynamic lists that
#          throw exceptions)
# OUT : - hash with keys :
#          -list :$list
#          -aliases : undef if not applicable; 1 (if ok) or
#           $aliases : concated string of alias if they
#           are not installed or 1(in status open)
#######################################################
sub create_list {
    my ($param, $family, $dummy, $abort_on_error) = @_;
    $log->syslog('info', '(%s, %s, %s)', $param->{'listname'},
        $family->{'name'}, $param->{'subject'});

    ## mandatory list parameters
    foreach my $arg ('listname') {
        unless ($param->{$arg}) {
            $log->syslog('err', 'Missing list param %s', $arg);
            return undef;
        }
    }

    unless ($family) {
        $log->syslog('err', 'Missing param "family"');
        return undef;
    }

    #robot
    my $robot = $family->{'robot'};
    unless ($robot) {
        $log->syslog('err', 'Missing param "robot"');
        return undef;
    }

    ## check listname
    $param->{'listname'} = lc($param->{'listname'});
    my $listname_regexp = Sympa::Regexps::listname();

    unless ($param->{'listname'} =~ /^$listname_regexp$/i
        and length $param->{'listname'} <= Sympa::Constants::LIST_LEN()) {
        $log->syslog('err', 'Incorrect listname %s', $param->{'listname'});
        return undef;
    }

    my $regx = Conf::get_robot_conf($robot, 'list_check_regexp');
    if ($regx) {
        if ($param->{'listname'} =~ /^(\S+)-($regx)$/) {
            $log->syslog('err',
                'Incorrect listname %s matches one of service aliases',
                $param->{'listname'});
            return undef;
        }
    }
    if (   $param->{'listname'} eq Conf::get_robot_conf($robot, 'email')
        or $param->{'listname'} eq
        Conf::get_robot_conf($robot, 'listmaster_email')) {
        $log->syslog('err',
            'Incorrect listname %s matches one of service aliases',
            $param->{'listname'});
        return undef;
    }

    ## Check listname on SMTP server
    my $res = list_check_smtp($param->{'listname'}, $robot);
    unless (defined $res) {
        $log->syslog('err', 'Can\'t check list %.128s on %s',
            $param->{'listname'}, $robot);
        return undef;
    }

    if ($res) {
        $log->syslog('err',
            'Could not create already existing list %s on %s for',
            $param->{'listname'}, $robot);
        foreach my $o (@{$param->{'owner'}}) {
            $log->syslog('err', $o->{'email'});
        }
        return undef;
    }

    ## template file
    my $template_file = Sympa::search_fullpath($family, 'config.tt2');
    unless (defined $template_file) {
        $log->syslog('err', 'No config template from family %s@%s',
            $family->{'name'}, $robot);
        return undef;
    }

    my $family_config =
        Conf::get_robot_conf($robot, 'automatic_list_families');
    $param->{'family_config'} = $family_config->{$family->{'name'}};
    my $conf;
    my $template =
        Sympa::Template->new(undef, include_path => [$family->{'dir'}]);
    my $tt_result = $template->parse($param, 'config.tt2', \$conf);
    if (not $tt_result and $abort_on_error) {
        $log->syslog(
            'err',
            'Abort on template error. List %s from family %s@%s, file config.tt2 : %s',
            $param->{'listname'},
            $family->{'name'},
            $robot,
            $template->{last_error}
        );
        return undef;
    }

    ## Create the list directory
    my $list_dir;

    if (-d "$Conf::Conf{'home'}/$robot") {
        unless (-d $Conf::Conf{'home'} . '/' . $robot) {
            unless (mkdir $Conf::Conf{'home'} . '/' . $robot, 0777) {
                $log->syslog('err', 'Unable to create %s/%s: %s',
                    $Conf::Conf{'home'}, $robot, $ERRNO);
                return undef;
            }
        }
        $list_dir =
            $Conf::Conf{'home'} . '/' . $robot . '/' . $param->{'listname'};
    } else {
        $list_dir = $Conf::Conf{'home'} . '/' . $param->{'listname'};
    }

    unless (-r $list_dir or mkdir($list_dir, 0777)) {
        $log->syslog('err', 'Unable to create %s: %s', $list_dir, $ERRNO);
        return undef;
    }

    ## Check topics
    if (defined $param->{'topics'}) {
        unless (check_topics($param->{'topics'}, $robot)) {
            $log->syslog('err', 'Topics param %s not defined in topics.conf',
                $param->{'topics'});
        }
    }

    ## Lock config before openning the config file
    my $lock_fh = Sympa::LockedFile->new($list_dir . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %m', $list_dir);
        return undef;
    }
    print $lock_fh $conf;

    ## Unlock config file
    $lock_fh->close;

    ## Creation of the info file
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and
    # EIMS:
    if (defined $param->{'description'}) {
        $param->{'description'} =~ s/\r\n|\r/\n/g;
    }

    unless (open INFO, '>', "$list_dir/info") {
        $log->syslog('err', 'Impossible to create %s/info: %m', $list_dir);
    }
    if (defined $param->{'description'}) {
        print INFO $param->{'description'};
    }
    close INFO;

    ## Create associated files if a template was given.
    my @files_to_parse;
    foreach my $file (split ',',
        Conf::get_robot_conf($robot, 'parsed_family_files')) {
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
                    'Template error. List %s from family %s@%s, file %s : %s',
                    $param->{'listname'},
                    $family->{'name'},
                    $robot,
                    $file,
                    $template->{last_error}
                );
            }
            unless (open FILE, '>', "$list_dir/$file") {
                $log->syslog('err', 'Impossible to create %s/%s: %m',
                    $list_dir, $file);
            }
            print FILE $file_content;
            close FILE;
        }
    }

    ## Create list object
    my $list;
    unless ($list = Sympa::List->new($param->{'listname'}, $robot)) {
        $log->syslog('err', 'Unable to create list %s', $param->{'listname'});
        return undef;
    }

    ## Create shared if required
    if (defined $list->{'admin'}{'shared_doc'}) {
        $list->create_shared();
    }

    ##FIXME:should be unneccessary
    $list->{'admin'}{'creation'}{'date'} =
        $language->gettext_strftime("%d %b %Y at %H:%M:%S", localtime time);
    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    $list->{'admin'}{'creation'}{'email'}      = $param->{'creation_email'}
        || Sympa::get_address($robot, 'listmaster');
    $list->{'admin'}{'status'} = $param->{'status'} || 'open';
    $list->{'admin'}{'family_name'} = $family->{'name'};

    my $return = {};
    $return->{'list'} = $list;

    if ($list->{'admin'}{'status'} eq 'open') {
        $return->{'aliases'} = install_aliases($list);
    } else {
        $return->{'aliases'} = 1;
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

    return $return;
}

########################################################
# update_list
########################################################
# update a list : used by sympa.pl--instantiate_family
# with family concept when the list already exists
#
# IN  : - $list : the list to update
#       - $param : ref on parameters of the new
#          config list with obligatory :
#         $param->{'listname'}
#         $param->{'subject'}
#         $param->{'owner'} (or owner_include):
#          array of hash,with key email obligatory
#         $param->{'owner_include'} array of hash :
#              with key source obligatory
#       - $family : the family object
#       - $robot : the list's robot
#
# OUT : - $list : the updated list or undef
#######################################################
sub update_list {
    my ($list, $param, $family, $robot) = @_;
    $log->syslog('info', '(%s, %s, %s)', $param->{'listname'},
        $family->{'name'}, $param->{'subject'});

    ## mandatory list parameters
    foreach my $arg ('listname') {
        unless ($param->{$arg}) {
            $log->syslog('err', 'Missing list param %s', $arg);
            return undef;
        }
    }

    ## template file
    my $template_file = Sympa::search_fullpath($family, 'config.tt2');
    unless (defined $template_file) {
        $log->syslog('err', 'No config template from family %s@%s',
            $family->{'name'}, $robot);
        return undef;
    }

    ## Check topics
    if (defined $param->{'topics'}) {
        unless (check_topics($param->{'topics'}, $robot)) {
            $log->syslog('err', 'Topics param %s not defined in topics.conf',
                $param->{'topics'});
        }
    }

    ## Lock config before openning the config file
    my $lock_fh = Sympa::LockedFile->new($list->{'dir'} . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %s',
            $list->{'dir'}, $ERRNO);
        return undef;
    }

    my $template =
        Sympa::Template->new(undef, include_path => [$family->{'dir'}]);
    unless ($template->parse($param, 'config.tt2', $lock_fh)) {
        $log->syslog('err', 'Can\'t parse %s/config.tt2: %s',
            $family->{'dir'}, $template->{last_error});
        return undef;
    }
    ## Unlock config file
    $lock_fh->close;

    ## Create list object
    unless ($list = Sympa::List->new($param->{'listname'}, $robot)) {
        $log->syslog('err', 'Unable to create list %s', $param->{'listname'});
        return undef;
    }

    ##FIXME:should be unneccessary
    $list->{'admin'}{'creation'}{'date'} =
        $language->gettext_strftime("%d %b %Y at %H:%M:%S", localtime time);
    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    $list->{'admin'}{'creation'}{'email'}      = $param->{'creation_email'}
        || Sympa::get_address($robot, 'listmaster');
    $list->{'admin'}{'status'} = $param->{'status'} || 'open';
    $list->{'admin'}{'family_name'} = $family->{'name'};

    ## Create associated files if a template was given.
    my @files_to_parse;
    foreach my $file (split ',',
        Conf::get_robot_conf($robot, 'parsed_family_files')) {
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
            unless ($tt_result) {
                $log->syslog(
                    'err',
                    'Template error. List %s from family %s@%s, file %s: %s',
                    $param->{'listname'},
                    $family->{'name'},
                    $robot,
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

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

    return $list;
}

########################################################
# rename_list
########################################################
# Rename a list or move a list to another virtual host
#
# IN  : - list
#       - new_listname
#       - new_robot
#       - mode  : 'copy'
#       - auth_method
#       - user_email
#       - remote_host
#       - remote_addr
#       - options : 'skip_authz' to skip authorization scenarios eval
#
# OUT via reference :
#       - aliases
#       - status : 'pending'
#
# OUT : - scalar
#           undef  : error
#           1      : success
#           string : error code
#######################################################
sub rename_list {
    my (%param) = @_;
    $log->syslog('info', '',);

    my $list         = $param{'list'};
    my $robot        = $list->{'domain'};
    my $old_listname = $list->{'name'};

    # check new listname syntax
    my $new_listname    = lc($param{'new_listname'});
    my $listname_regexp = Sympa::Regexps::listname();

    unless ($new_listname =~ /^$listname_regexp$/i
        and length $new_listname <= Sympa::Constants::LIST_LEN()) {
        $log->syslog('err', 'Incorrect listname %s', $new_listname);
        return 'incorrect_listname';
    }

    ## Evaluate authorization scenario unless run as listmaster (sympa.pl)
    my ($result, $r_action, $reason);
    unless ($param{'options'}{'skip_authz'}) {
        $result = Sympa::Scenario::request_action(
            $param{'new_robot'},
            'create_list',
            $param{'auth_method'},
            {   'sender'      => $param{'user_email'},
                'remote_host' => $param{'remote_host'},
                'remote_addr' => $param{'remote_addr'}
            }
        );

        if (ref($result) eq 'HASH') {
            $r_action = $result->{'action'};
            $reason   = $result->{'reason'};
        }

        unless ($r_action =~ /do_it|listmaster/) {
            $log->syslog('err', 'Authorization error');
            return 'authorization';
        }
    }

    ## Check listname on SMTP server
    my $res = list_check_smtp($param{'new_listname'}, $param{'new_robot'});
    unless (defined($res)) {
        $log->syslog('err', 'Can\'t check list %.128s on %.128s',
            $param{'new_listname'}, $param{'new_robot'});
        return 'internal';
    }

    if ($res
        || ($list->{'name'} ne $param{'new_listname'})
        &&    ## Do not test if listname did not change
        (   Sympa::List->new(
                $param{'new_listname'}, $param{'new_robot'},
                {'just_try' => 1}
            )
        )
        ) {
        $log->syslog(
            'err',
            'Could not rename list %s on %s: new list %s on %s already existing list',
            $list->{'name'},
            $robot,
            $param{'new_listname'},
            $param{'new_robot'}
        );
        return 'list_already_exists';
    }

    my $regx = Conf::get_robot_conf($param{'new_robot'}, 'list_check_regexp');
    if ($regx) {
        if ($param{'new_listname'} =~ /^(\S+)-($regx)$/) {
            $log->syslog('err',
                'Incorrect listname %s matches one of service aliases',
                $param{'new_listname'});
            return 'incorrect_listname';
        }
    }

    unless ($param{'mode'} eq 'copy') {
        $list->savestats();

        ## Dump subscribers
        $list->_save_list_members_file(
            "$list->{'dir'}/subscribers.closed.dump");

        $param{'aliases'} = remove_aliases($list, $list->{'domain'});
    }

    ## Rename or create this list directory itself
    my $new_dir;
    ## Default robot
    if (-d "$Conf::Conf{'home'}/$param{'new_robot'}") {
        $new_dir =
              $Conf::Conf{'home'} . '/'
            . $param{'new_robot'} . '/'
            . $param{'new_listname'};
    } elsif ($param{'new_robot'} eq $Conf::Conf{'domain'}) {
        $new_dir = $Conf::Conf{'home'} . '/' . $param{'new_listname'};
    } else {
        $log->syslog('err', 'Unknown robot %s', $param{'new_robot'});
        return 'unknown_robot';
    }

    ## If we are in 'copy' mode, create en new list
    if ($param{'mode'} eq 'copy') {
        unless (
            $list = clone_list_as_empty(
                $list->{'name'},        $list->{'domain'},
                $param{'new_listname'}, $param{'new_robot'},
                $param{'user_email'}
            )
            ) {
            $log->syslog('err', 'Unable to load %s while renaming',
                $param{'new_listname'});
            return 'internal';
        }
    }

    # set list status to pending if creation list is moderated
    if ($r_action =~ /listmaster/) {
        $list->{'admin'}{'status'} = 'pending';
        Sympa::send_notify_to_listmaster(
            $list,
            'request_list_renaming',
            {   'new_listname' => $param{'new_listname'},
                'old_listname' => $old_listname,
                'email'        => $param{'user_email'},
                'mode'         => $param{'mode'}
            }
        );
        $param{'status'} = 'pending';
    }

    ## Save config file for the new() later to reload it
    $list->save_config($param{'user_email'});

    ## This code should be in Sympa::List::rename()
    unless ($param{'mode'} eq 'copy') {
        unless (File::Copy::move($list->{'dir'}, $new_dir)) {
            $log->syslog('err', 'Unable to rename %s to %s: %m',
                $list->{'dir'}, $new_dir);
            return 'internal';
        }

        ## Rename archive
        my $arc_dir =
            Conf::get_robot_conf($robot, 'arc_path') . '/'
            . $list->get_list_id();
        my $new_arc_dir =
              Conf::get_robot_conf($param{'new_robot'}, 'arc_path') . '/'
            . $param{'new_listname'} . '@'
            . $param{'new_robot'};
        if (-d $arc_dir && $arc_dir ne $new_arc_dir) {
            unless (File::Copy::move($arc_dir, $new_arc_dir)) {
                $log->syslog('err', 'Unable to rename archive %s', $arc_dir);
                # continue even if there is some troubles with archives
                # return undef;
            }
        }

        ## Rename bounces
        my $bounce_dir = $list->get_bounce_dir();
        my $new_bounce_dir =
              Conf::get_robot_conf($param{'new_robot'}, 'bounce_path') . '/'
            . $param{'new_listname'} . '@'
            . $param{'new_robot'};
        if (-d $bounce_dir && $bounce_dir ne $new_bounce_dir) {
            unless (File::Copy::move($bounce_dir, $new_bounce_dir)) {
                $log->syslog('err',
                    "Unable to rename bounces from $bounce_dir to $new_bounce_dir"
                );
            }
        }

        # if subscribtion are stored in database rewrite the database
        Sympa::List::rename_list_db($list, $param{'new_listname'},
            $param{'new_robot'});
    }

    my $sdm = Sympa::DatabaseManager->instance;

    # Move stats
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE stat_table
              SET list_stat = ?, robot_stat = ?
              WHERE list_stat = ? AND robot_stat = ?},
            $param{'new_listname'}, $param{'new_robot'},
            $list->{'name'},        $robot
        )
        ) {
        $log->syslog(
            'err',
            'Unable to transfer stats from list %s@%s to list %s@%s',
            $param{'new_listname'},
            $param{'new_robot'},
            $list->{'name'},
            $robot
        );
    }

    # Move stat counters
    unless (
        $sdm->do_prepared_query(
            q{UPDATE stat_counter_table
              SET list_counter = ?, robot_counter = ?
              WHERE list_counter = ? AND robot_counter = ?},
            $param{'new_listname'}, $param{'new_robot'},
            $list->{'name'},        $robot
        )
        ) {
        $log->syslog(
            'err',
            'Unable to transfer stat counter from list %s@%s to list %s@%s',
            $param{'new_listname'},
            $param{'new_robot'},
            $list->{'name'},
            $robot
        );
    }

    ## Install new aliases
    $param{'listname'} = $param{'new_listname'};

    unless (
        $list = Sympa::List->new(
            $param{'new_listname'}, $param{'new_robot'},
            {'reload_config' => 1}
        )
        ) {
        $log->syslog('err', 'Unable to load %s while renaming',
            $param{'new_listname'});
        return 'internal';
    }

    ## Check custom_subject
    if (defined $list->{'admin'}{'custom_subject'}
        && $list->{'admin'}{'custom_subject'} =~ /$old_listname/) {
        $list->{'admin'}{'custom_subject'} =~
            s/$old_listname/$param{'new_listname'}/g;

        $list->save_config($param{'user_email'});
    }

    if ($list->{'admin'}{'status'} eq 'open') {
        $param{'aliases'} = install_aliases($list);
    }

    unless ($param{'mode'} eq 'copy') {

        ## Rename files in spools
        ## Auth & Mod  spools
        foreach my $spool (
            'queueauth',      'queuemod',
            'queuetask',      'queuebounce',
            'queue',          'queueoutgoing',
            'queuesubscribe', 'queueautomatic',
            'queuedigest'
            ) {
            unless (opendir(DIR, $Conf::Conf{$spool})) {
                $log->syslog('err', 'Unable to open "%s" spool: %m',
                    $Conf::Conf{$spool});
            }

            foreach my $file (sort readdir(DIR)) {
                next
                    unless ($file =~ /^$old_listname\_/
                    || $file =~ /^$old_listname/
                    || $file =~ /^$old_listname\./
                    || $file =~ /^$old_listname\@$robot\./
                    || $file =~ /^\.$old_listname\@$robot\_/
                    || $file =~ /^$old_listname\@$robot\_/
                    || $file =~ /\.$old_listname$/);

                my $newfile = $file;
                if ($file =~ /^$old_listname\_/) {
                    $newfile =~ s/^$old_listname\_/$param{'new_listname'}\_/;
                } elsif ($file =~ /^$old_listname/) {
                    $newfile =~ s/^$old_listname/$param{'new_listname'}/;
                } elsif ($file =~ /^$old_listname\./) {
                    $newfile =~ s/^$old_listname\./$param{'new_listname'}\./;
                } elsif ($file =~ /^$old_listname\@$robot\./) {
                    $newfile =~
                        s/^$old_listname\@$robot\./$param{'new_listname'}\@$param{'new_robot'}\./;
                } elsif ($file =~ /^$old_listname\@$robot\_/) {
                    $newfile =~
                        s/^$old_listname\@$robot\_/$param{'new_listname'}\@$param{'new_robot'}\_/;
                } elsif ($file =~ /^\.$old_listname\@$robot\_/) {
                    $newfile =~
                        s/^\.$old_listname\@$robot\_/\.$param{'new_listname'}\@$param{'new_robot'}\_/;
                } elsif ($file =~ /\.$old_listname$/) {
                    $newfile =~ s/\.$old_listname$/\.$param{'new_listname'}/;
                }

                ## Rename file
                unless (
                    File::Copy::move(
                        $Conf::Conf{$spool} . '/' . $file,
                        $Conf::Conf{$spool} . '/' . $newfile
                    )
                    ) {
                    $log->syslog(
                        'err',
                        'Unable to rename %s to %s: %m',
                        "$Conf::Conf{$spool}/$newfile",
                        "$Conf::Conf{$spool}/$newfile"
                    );
                    next;
                }

                ## Change X-Sympa-To
                #tools::change_x_sympa_to("$Conf::Conf{$spool}/$newfile",
                #    "$param{'new_listname'}\@$param{'new_robot'}");
            }

            close DIR;
        }
        ## Digest spool
        if (-f "$Conf::Conf{'queuedigest'}/$old_listname") {
            unless (
                File::Copy::move(
                    $Conf::Conf{'queuedigest'} . '/' . $old_listname,
                    $Conf::Conf{'queuedigest'} . '/' . $param{'new_listname'}
                )
                ) {
                $log->syslog(
                    'err',
                    'Unable to rename %s to %s: %m',
                    "$Conf::Conf{'queuedigest'}/$old_listname",
                    "$Conf::Conf{'queuedigest'}/$param{'new_listname'}"
                );
                next;
            }
        } elsif (-f "$Conf::Conf{'queuedigest'}/$old_listname\@$robot") {
            unless (
                File::Copy::move(
                    $Conf::Conf{'queuedigest'} . '/'
                        . $old_listname . '@'
                        . $robot,
                    $Conf::Conf{'queuedigest'} . '/'
                        . $param{'new_listname'} . '@'
                        . $param{'new_robot'}
                )
                ) {
                $log->syslog(
                    'err',
                    'Unable to rename %s to %s: %m',
                    "$Conf::Conf{'queuedigest'}/$old_listname\@$robot",
                    "$Conf::Conf{'queuedigest'}/$param{'new_listname'}\@$param{'new_robot'}"
                );
                next;
            }
        }
    }

    return 1;
}

########################################################
# clone_list_as_empty {
########################################################
# Clone a list config including customization, templates, scenario config
# but without archives, subscribers and shared
#
# IN  : - $source_list_name : the list to clone
#       - $source_robot : robot of the list to clone
#       - $new_listname : the target listname
#       - $new_robot : the target list's robot
#       - $email : the email of the requestor : used in config as
#       admin->last_update->email
#
# OUT : - $list : the updated list or undef
##
sub clone_list_as_empty {

    my $source_list_name = shift;
    my $source_robot     = shift;
    my $new_listname     = shift;
    my $new_robot        = shift;
    my $email            = shift;

    my $list;
    unless ($list = Sympa::List->new($source_list_name, $source_robot)) {
        $log->syslog('err', 'New list failed %s %s',
            $source_list_name, $source_robot);
        return undef;
    }

    $log->syslog('info',
        "Admin::clone_list_as_empty ($source_list_name, $source_robot,$new_listname,$new_robot,$email)"
    );

    my $new_dir;
    if (-d $Conf::Conf{'home'} . '/' . $new_robot) {
        $new_dir =
            $Conf::Conf{'home'} . '/' . $new_robot . '/' . $new_listname;
    } elsif ($new_robot eq $Conf::Conf{'domain'}) {
        $new_dir = $Conf::Conf{'home'} . '/' . $new_listname;
    } else {
        $log->syslog('err', 'Unknown robot %s', $new_robot);
        return undef;
    }

    unless (mkdir $new_dir, 0775) {
        $log->syslog('err', 'Failed to create directory %s: %m', $new_dir);
        return undef;
    }
    chmod 0775, $new_dir;
    foreach my $subdir ('etc', 'web_tt2', 'mail_tt2', 'data_sources') {
        if (-d $new_dir . '/' . $subdir) {
            unless (
                Sympa::Tools::File::copy_dir(
                    $list->{'dir'} . '/' . $subdir,
                    $new_dir . '/' . $subdir
                )
                ) {
                $log->syslog(
                    'err',
                    'Failed to copy_directory %s: %m',
                    $new_dir . '/' . $subdir
                );
                return undef;
            }
        }
    }
    # copy mandatory files
    foreach my $file ('config') {
        unless (
            File::Copy::copy(
                $list->{'dir'} . '/' . $file,
                $new_dir . '/' . $file
            )
            ) {
            $log->syslog(
                'err',
                'Failed to copy %s: %m',
                $new_dir . '/' . $file
            );
            return undef;
        }
    }
    # copy optional files
    foreach my $file ('message.footer', 'message.header', 'info', 'homepage')
    {
        if (-f $list->{'dir'} . '/' . $file) {
            unless (
                File::Copy::copy(
                    $list->{'dir'} . '/' . $file,
                    $new_dir . '/' . $file
                )
                ) {
                $log->syslog(
                    'err',
                    'Failed to copy %s: %m',
                    $new_dir . '/' . $file
                );
                return undef;
            }
        }
    }

    my $new_list;
    # now switch List object to new list, update some values
    unless ($new_list =
        Sympa::List->new($new_listname, $new_robot, {'reload_config' => 1})) {
        $log->syslog('info',
            "Admin::clone_list_as_empty : unable to load $new_listname while renamming"
        );
        return undef;
    }
    $new_list->{'admin'}{'serial'} = 0;
    $new_list->{'admin'}{'creation'}{'email'} = $email if ($email);
    $new_list->{'admin'}{'creation'}{'date_epoch'} = time;
    ##FIXME:should be unneccessary
    $new_list->{'admin'}{'creation'}{'date'} =
        $language->gettext_strftime("%d %b %y at %H:%M:%S", localtime time);
    $new_list->save_config($email);
    return $new_list;
}

########################################################
# check_owner_defined
########################################################
# verify if they are any owner defined : it must exist
# at least one param owner(in $owner) or one param
# owner_include (in $owner_include)
# the owner param must have sub param email
# the owner_include param must have sub param source
#
# IN  : - $owner : ref on array of hash
#                  or
#                  ref on hash
#       - $owner_include : ref on array of hash
#                          or
#                          ref on hash
# OUT : - 1 if exists owner(s)
#         or
#         undef if no owner defined
#########################################################
sub check_owner_defined {
    my ($owner, $owner_include) = @_;
    $log->syslog('debug2', '');

    if (ref($owner) eq "ARRAY") {
        if (ref($owner_include) eq "ARRAY") {
            if (($#{$owner} < 0) && ($#{$owner_include} < 0)) {
                $log->syslog('err',
                    'Missing list param owner or owner_include');
                return undef;
            }
        } else {
            if (($#{$owner} < 0) && !($owner_include)) {
                $log->syslog('err',
                    'Missing list param owner or owner_include');
                return undef;
            }
        }
    } else {
        if (ref($owner_include) eq "ARRAY") {
            if (!($owner) && ($#{$owner_include} < 0)) {
                $log->syslog('err',
                    'Missing list param owner or owner_include');
                return undef;
            }
        } else {
            if (!($owner) && !($owner_include)) {
                $log->syslog('err',
                    'Missing list param owner or owner_include');
                return undef;
            }
        }
    }

    if (ref($owner) eq "ARRAY") {
        foreach my $o (@{$owner}) {
            unless ($o) {
                $log->syslog('err', 'Empty param "owner"');
                return undef;
            }
            unless ($o->{'email'}) {
                $log->syslog('err',
                    'Missing sub param "email" for param "owner"');
                return undef;
            }
        }
    } elsif (ref($owner) eq "HASH") {
        unless ($owner->{'email'}) {
            $log->syslog('err',
                'Missing sub param "email" for param "owner"');
            return undef;
        }
    } elsif (defined $owner) {
        $log->syslog('err', 'Missing sub param "email" for param "owner"');
        return undef;
    }

    if (ref($owner_include) eq "ARRAY") {
        foreach my $o (@{$owner_include}) {
            unless ($o) {
                $log->syslog('err', 'Empty param "owner_include"');
                return undef;
            }
            unless ($o->{'source'}) {
                $log->syslog('err',
                    'Missing sub param "source" for param "owner_include"');
                return undef;
            }
        }
    } elsif (ref($owner_include) eq "HASH") {
        unless ($owner_include->{'source'}) {
            $log->syslog('err',
                'Missing sub param "source" for param "owner_include"');
            return undef;
        }
    } elsif (defined $owner_include) {
        $log->syslog('err',
            'Missing sub param "source" for param "owner_include"');
        return undef;
    }
    return 1;
}

#####################################################
# list_check_smtp
#####################################################
# check if the requested list exists already using
#   smtp 'rcpt to'
#
# IN  : - $name : name of the list
#       - $robot : list's robot
# OUT : - Net::SMTP object or 0
#####################################################
sub list_check_smtp {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $name  = shift;
    my $robot = shift;

    my $conf = '';
    my $smtp;
    my (@suf, @addresses);

    my $smtp_relay = Conf::get_robot_conf($robot, 'list_check_smtp');
    my $smtp_helo  = Conf::get_robot_conf($robot, 'list_check_helo')
        || $smtp_relay;
    $smtp_helo =~ s/:[-\w]+$// if $smtp_helo;
    my $suffixes = Conf::get_robot_conf($robot, 'list_check_suffixes');
    return 0
        unless $smtp_relay and $suffixes;
    my $host = Conf::get_robot_conf($robot, 'host');
    $log->syslog('debug2', '(%s, %s)', $name, $robot);
    @suf = split /\s*,\s*/, $suffixes;
    return 0 unless @suf;

    foreach my $suffix (@suf) {
        push @addresses, $name . '-' . $suffix . '@' . $host;
    }
    push @addresses, $name . '@' . $host;

    eval { require Net::SMTP; };
    if ($EVAL_ERROR) {
        $log->syslog('err',
            "Unable to use Net library, Net::SMTP required, install it (CPAN) first"
        );
        return undef;
    }
    if ($smtp = Net::SMTP->new(
            $smtp_relay,
            Hello   => $smtp_helo,
            Timeout => 30
        )
        ) {
        $smtp->mail('');
        for (@addresses) {
            $conf = $smtp->to($_);
            last if $conf;
        }
        $smtp->quit();
        return $conf;
    }
    return undef;
}

##########################################################
# install_aliases
##########################################################
# Install sendmail aliases for $list
#
# IN  : - $list : object list
#       - $robot : the list's robot ** No longer used
# OUT : - undef if not applicable or aliases not installed
#         1 (if ok) or
##########################################################
sub install_aliases {
    $log->syslog('debug', '(%s)', @_);
    my $list = shift;

    return 1
        if Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') =~
            /^none$/i;

    my $alias_manager = $Conf::Conf{'alias_manager'};
    $log->syslog('debug2', '%s add %s %s', $alias_manager, $list->{'name'},
        $list->{'admin'}{'host'});

    unless (-x $alias_manager) {
        $log->syslog('err', 'Failed to install aliases: %m');
        return undef;
    }

    #FIXME: 'host' parameter is passed to alias_manager: no 'domain'
    # parameter to determine robot.
    my $status =
        system($alias_manager, 'add', $list->{'name'},
        $list->{'admin'}{'host'}) >> 8;

    if ($status == 0) {
        $log->syslog('info', 'Aliases installed successfully');
        return 1;
    }

    if ($status == 1) {
        $log->syslog('err', 'Configuration file %s has errors',
            Conf::get_sympa_conf());
    } elsif ($status == 2) {
        $log->syslog('err',
            'Internal error: Incorrect call to alias_manager');
    } elsif ($status == 3) {
        # Won't occur
        $log->syslog('err',
            'Could not read sympa config file, report to httpd error_log');
    } elsif ($status == 4) {
        # Won't occur
        $log->syslog('err',
            'Could not get default domain, report to httpd error_log');
    } elsif ($status == 5) {
        $log->syslog('err', 'Unable to append to alias file');
    } elsif ($status == 6) {
        $log->syslog('err', 'Unable to run newaliases');
    } elsif ($status == 7) {
        $log->syslog('err',
            'Unable to read alias file, report to httpd error_log');
    } elsif ($status == 8) {
        $log->syslog('err',
            'Could not create temporay file, report to httpd error_log');
    } elsif ($status == 13) {
        $log->syslog('info', 'Some of list aliases already exist');
    } elsif ($status == 14) {
        $log->syslog('err',
            'Can not open lock file, report to httpd error_log');
    } elsif ($status == 15) {
        $log->syslog('err', 'The parser returned empty aliases');
    } else {
        $log->syslog('err', 'Unknown error %s while running alias manager %s',
            $status, $alias_manager);
    }

    return undef;
}

#########################################################
# remove_aliases
#########################################################
# Remove sendmail aliases for $list
#
# IN  : - $list : object list
#       - $robot : the list's robot  ** No longer used
# OUT : - undef if not applicable
#         1 (if ok) or
#         $aliases : concated string of alias not removed
#########################################################

sub remove_aliases {
    $log->syslog('info', '(%s)', @_);
    my $list = shift;

    return 1
        if Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') =~
            /^none$/i;

    my $status = $list->remove_aliases();
    my $suffix =
        Conf::get_robot_conf($list->{'domain'}, 'return_path_suffix');
    my $aliases;

    unless ($status == 1) {
        $log->syslog('err', 'Failed to remove aliases for list %s',
            $list->{'name'});

        ## build a list of required aliases the listmaster should install
        my $libexecdir = Sympa::Constants::LIBEXECDIR;
        $aliases = <<EOF;
#----------------- $list->{'name'}
$list->{'name'}: "$libexecdir/queue $list->{'name'}"
$list->{'name'}-request: "|$libexecdir/queue $list->{'name'}-request"
$list->{'name'}$suffix: "|$libexecdir/bouncequeue $list->{'name'}"
$list->{'name'}-unsubscribe: "|$libexecdir/queue $list->{'name'}-unsubscribe"
# $list->{'name'}-subscribe: "|$libexecdir/queue $list->{'name'}-subscribe"
EOF

        return $aliases;
    }

    $log->syslog('info', 'Aliases removed successfully');

    return 1;
}

#####################################################
# check_topics
#####################################################
# Check $topic in the $robot conf
#
# IN  : - $topic : id of the topic
#       - $robot : the list's robot
# OUT : - 1 if the topic is in the robot conf or undef
#####################################################
sub check_topics {
    my $topic = shift;
    my $robot = shift;
    $log->syslog('info', '(%s, %s)', $topic, $robot);

    my ($top, $subtop) = split /\//, $topic;

    my %topics;
    unless (%topics = Sympa::Robot::load_topics($robot)) {
        $log->syslog('err', 'Unable to load list of topics');
    }

    if ($subtop) {
        return 1
            if (defined $topics{$top}
            && defined $topics{$top}{'sub'}{$subtop});
    } else {
        return 1 if (defined $topics{$top});
    }

    return undef;
}

# change a user email address for both his memberships and ownerships
#
# IN  : - current_email : current user email address
#       - new_email     : new user email address
#       - robot         : virtual robot
#
# OUT : - status(scalar)          : status of the subroutine
#       - failed_for(arrayref)    : list of lists for which the change could
#       not be done (because user was
#                                   included or for authorization reasons)
sub change_user_email {
    my %in = @_;

    my $robot_id = $in{'robot'};

    my @failed_for;

    unless ($in{'current_email'} and $in{'new_email'} and $in{'robot'}) {
        die 'Missing incoming parameter';
    }

    ## Change email as list MEMBER
    foreach my $list (
        Sympa::List::get_which($in{'current_email'}, $robot_id, 'member')) {
        my $l = $list->{'name'};

        my $user_entry = $list->get_list_member($in{'current_email'});

        if ($user_entry->{'included'} == 1) {
            ## Check the type of data sources
            ## If only include_list of local mailing lists, then no problem
            ## Otherwise, notify list owner
            ## We could also force a sync_include for local lists
            my $use_external_data_sources;
            foreach my $datasource_id (split(/,/, $user_entry->{'id'})) {
                my $datasource = $list->search_datasource($datasource_id);
                if (   !defined $datasource
                    or $datasource->{'type'} ne 'include_list'
                    or (    $datasource->{'def'} =~ /\@(.+)$/
                        and $1 ne $robot_id)
                    ) {
                    $use_external_data_sources = 1;
                    last;
                }
            }
            if ($use_external_data_sources) {
                ## Notify list owner
                $list->send_notify_to_owner(
                    'failed_to_change_included_member',
                    {   'current_email' => $in{'current_email'},
                        'new_email'     => $in{'new_email'},
                        'datasource' =>
                            $list->get_datasource_name($user_entry->{'id'})
                    }
                );
                push @failed_for, $list;
                $log->syslog(
                    'err',
                    'Could not change member email for list %s because member is included',
                    $l
                );
                next;
            }
        }

        ## Check if user is already member of the list with his new address
        ## then we just need to remove the old address
        if ($list->is_list_member($in{'new_email'})) {
            unless (
                $list->delete_list_member('users' => [$in{'current_email'}]))
            {
                push @failed_for, $list;
                $log->syslog('info', 'Could not remove email from list %s',
                    $l);
            }

        } else {
            unless (
                $list->update_list_member(
                    $in{'current_email'},
                    email       => $in{'new_email'},
                    update_date => time
                )
                ) {
                push @failed_for, $list;
                $log->syslog('err', 'Could not change email for list %s', $l);
            }
        }
    }

    ## Change email as list OWNER/MODERATOR
    my %updated_lists;
    foreach my $role ('owner', 'editor') {
        foreach my $list (
            Sympa::List::get_which($in{'current_email'}, $robot_id, $role)) {
            # Check if admin is included via an external datasource
            my ($admin_user) = @{
                $list->get_admins($role,
                    filter => [email => $in{'current_email'}])
                };
            if ($admin_user and $admin_user->{'included'}) {
                # Notify listmaster
                Sympa::send_notify_to_listmaster(
                    $list,
                    'failed_to_change_included_admin',
                    {   'current_email' => $in{'current_email'},
                        'new_email'     => $in{'new_email'},
                        'datasource' =>
                            $list->get_datasource_name($admin_user->{'id'})
                    }
                );
                push @failed_for, $list;
                $log->syslog(
                    'err',
                    'Could not change %s email for list %s because admin is included',
                    $role,
                    $list->{'name'}
                );
                next;
            }

            ## Go through owners/editors of the list
            foreach my $admin (@{$list->{'admin'}{$role}}) {
                next
                    unless (
                    lc($admin->{'email'}) eq lc($in{'current_email'}));

                ## Update entry with new email address
                $admin->{'email'} = $in{'new_email'};
                $updated_lists{$list->{'name'}}++;
            }

            ## Update Db cache for the list
            $list->sync_include_admin();
            $list->save_config();
        }
    }
    ## Notify listmasters that list owners/moderators email have changed
    if (keys %updated_lists) {
        Sympa::send_notify_to_listmaster(
            $robot_id,
            'listowner_email_changed',
            {   'previous_email' => $in{'current_email'},
                'new_email'      => $in{'new_email'},
                'updated_lists'  => keys %updated_lists
            }
        );
    }

    ## Update User_table and remove existing entry first (to avoid duplicate
    ## entries)
    my $oldu = Sympa::User->new($in{'new_email'});
    $oldu->expire if $oldu;
    my $u = Sympa::User->new($in{'current_email'});
    unless ($u and $u->moveto($in{'new_mail'})) {
        $log->syslog('err', 'Update failed');
        return undef;
    }

    ## Update netidmap_table
    unless (
        Sympa::Robot::update_email_netidmap_db(
            $in{'robot'}, $in{'current_email'}, $in{'new_email'}
        )
        ) {
        $log->syslog('err', 'Update failed');
        return undef;
    }

    return (1, \@failed_for);
}

=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier Salaun <os AT cru.fr> 

=back 

=cut 

1;
