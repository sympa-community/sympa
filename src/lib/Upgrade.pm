# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Upgrade;

use strict;
use warnings;
use Encode qw();
use File::Find qw();
use File::Path qw();
use POSIX qw();

use Sympa::Archive;
use Sympa::Auth;
use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Language;
use List;
use Log;
use Message;
use SDM;
use tools;

my $language = Sympa::Language->instance;

## Return the previous Sympa version, ie the one listed in
## data_structure.version
sub get_previous_version {
    my $version_file = "$Conf::Conf{'etc'}/data_structure.version";
    my $previous_version;

    if (-f $version_file) {
        unless (open VFILE, $version_file) {
            Log::do_log('err', 'Unable to open %s: %s', $version_file, $!);
            return undef;
        }
        while (<VFILE>) {
            next if /^\s*$/;
            next if /^\s*\#/;
            chomp;
            $previous_version = $_;
            last;
        }
        close VFILE;

        return $previous_version;
    }

    return undef;
}

sub update_version {
    my $version_file = "$Conf::Conf{'etc'}/data_structure.version";

    ## Saving current version if required
    unless (open VFILE, ">$version_file") {
        Log::do_log(
            'err',
            'Unable to write %s; sympa.pl needs write access on %s directory: %s',
            $version_file,
            $Conf::Conf{'etc'},
            $!
        );
        return undef;
    }
    printf VFILE
        "# This file is automatically created by sympa.pl after installation\n# Unless you know what you are doing, you should not modify it\n";
    printf VFILE "%s\n", Sympa::Constants::VERSION;
    close VFILE;

    return 1;
}

## Upgrade data structure from one version to another
sub upgrade {
    Log::do_log('debug3', '(%s, %s)', @_);
    my ($previous_version, $new_version) = @_;

    if (tools::lower_version($new_version, $previous_version)) {
        Log::do_log('notice',
            'Installing  older version of Sympa ; no upgrade operation is required'
        );
        return 1;
    }

    ## Check database connectivity and probe database
    unless (SDM::check_db_connect('just_try') and SDM::probe_db()) {
        Log::do_log(
            'err',
            'Database %s defined in sympa.conf has not the right structure or is unreachable. verify db_xxx parameters in sympa.conf',
            $Conf::Conf{'db_name'}
        );
        return undef;
    }

    ## Always update config.bin files while upgrading
    Conf::delete_binaries();

    ## Always update config.bin files while upgrading
    ## This is especially useful for character encoding reasons
    Log::do_log('notice',
        'Rebuilding config.bin files for ALL lists...it may take a while...');
    my $all_lists = List::get_lists('*', 'reload_config' => 1);

    ## Empty the admin_table entries and recreate them
    Log::do_log('notice', 'Rebuilding the admin_table...');
    List::delete_all_list_admin();
    foreach my $list (@$all_lists) {
        $list->sync_include_admin();
    }

    ## Migration to tt2
    if (tools::lower_version($previous_version, '4.2b')) {

        Log::do_log('notice', 'Migrating templates to TT2 format...');

        my $tpl_script = Sympa::Constants::SCRIPTDIR . '/tpl2tt2.pl';
        unless (open EXEC, "$tpl_script|") {
            Log::do_log('err', 'Unable to run %s', $tpl_script);
            return undef;
        }
        close EXEC;

        Log::do_log('notice', 'Rebuilding web archives...');
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            # FIXME: line below will always success
            next unless (defined $list->{'admin'}{'web_archive'});
            my $file =
                  $Conf::Conf{'queueoutgoing'}
                . '/.rebuild.'
                . $list->get_list_id();

            unless (open REBUILD, ">$file") {
                Log::do_log('err', 'Cannot create %s', $file);
                next;
            }
            print REBUILD ' ';
            close REBUILD;
        }
    }

    ## Initializing the new admin_table
    if (tools::lower_version($previous_version, '4.2b.4')) {
        Log::do_log('notice', 'Initializing the new admin_table...');
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            $list->sync_include_admin();
        }
    }

    ## Move old-style web templates out of the include_path
    if (tools::lower_version($previous_version, '5.0.1')) {
        Log::do_log('notice',
            'Old web templates HTML structure is not compliant with latest ones.'
        );
        Log::do_log('notice',
            'Moving old-style web templates out of the include_path...');

        my @directories;

        if (-d "$Conf::Conf{'etc'}/web_tt2") {
            push @directories, "$Conf::Conf{'etc'}/web_tt2";
        }

        ## Go through Virtual Robots
        foreach my $vr (keys %{$Conf::Conf{'robots'}}) {

            if (-d "$Conf::Conf{'etc'}/$vr/web_tt2") {
                push @directories, "$Conf::Conf{'etc'}/$vr/web_tt2";
            }
        }

        ## Search in V. Robot Lists
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            if (-d "$list->{'dir'}/web_tt2") {
                push @directories, "$list->{'dir'}/web_tt2";
            }
        }

        my @templates;

        foreach my $d (@directories) {
            unless (opendir DIR, $d) {
                printf STDERR "Error: Cannot read %s directory : %s", $d, $!;
                next;
            }

            foreach my $tt2 (sort grep(/\.tt2$/, readdir DIR)) {
                push @templates, "$d/$tt2";
            }

            closedir DIR;
        }

        foreach my $tpl (@templates) {
            unless (rename $tpl, "$tpl.oldtemplate") {
                printf STDERR
                    "Error : failed to rename $tpl to $tpl.oldtemplate : $!\n";
                next;
            }

            Log::do_log('notice', 'File %s renamed %s',
                $tpl, "$tpl.oldtemplate");
        }
    }

    ## Clean buggy list config files
    if (tools::lower_version($previous_version, '5.1b')) {
        Log::do_log('notice', 'Cleaning buggy list config files...');
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            $list->save_config('listmaster@' . $list->{'domain'});
        }
    }

    ## Fix a bug in Sympa 5.1
    if (tools::lower_version($previous_version, '5.1.2')) {
        Log::do_log('notice', 'Rename archives/log. files...');
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            my $l = $list->{'name'};
            if (-f $list->{'dir'} . '/archives/log.') {
                rename $list->{'dir'} . '/archives/log.',
                    $list->{'dir'} . '/archives/log.00';
            }
        }
    }

    if (tools::lower_version($previous_version, '5.2a.1')) {

        ## Fill the robot_subscriber and robot_admin fields in DB
        Log::do_log('notice',
            'Updating the new robot_subscriber and robot_admin  Db fields...'
        );

        foreach my $r (keys %{$Conf::Conf{'robots'}}) {
            my $all_lists = List::get_lists($r, 'skip_sync_admin' => 1);
            foreach my $list (@$all_lists) {

                foreach my $table ('subscriber', 'admin') {
                    unless (
                        SDM::do_query(
                            "UPDATE %s_table SET robot_%s=%s WHERE (list_%s=%s)",
                            $table,
                            $table,
                            SDM::quote($r),
                            $table,
                            SDM::quote($list->{'name'})
                        )
                        ) {
                        Log::do_log(
                            'err',
                            'Unable to fille the robot_admin and robot_subscriber fields in database for robot %s',
                            $r
                        );
                        List::send_notify_to_listmaster(
                            'upgrade_failed',
                            $Conf::Conf{'domain'},
                            {   'error' =>
                                    $SDM::db_source->{'db_handler'}->errstr
                            }
                        );
                        return undef;
                    }
                }

                ## Force Sync_admin
                $list =
                    List->new($list->{'name'}, $list->{'domain'},
                    {'force_sync_admin' => 1});
            }
        }

        ## Rename web archive directories using 'domain' instead of 'host'
        Log::do_log('notice',
            'Renaming web archive directories with the list domain...');

        my $root_dir =
            Conf::get_robot_conf($Conf::Conf{'domain'}, 'arc_path');
        unless (opendir ARCDIR, $root_dir) {
            Log::do_log('err', 'Unable to open %s: %m', $root_dir);
            return undef;
        }

        foreach my $dir (sort readdir(ARCDIR)) {
            ## Skip files and entries starting with '.'
            next
                if (($dir =~ /^\./o) || (!-d $root_dir . '/' . $dir));

            my ($listname, $listdomain) = split /\@/, $dir;

            next unless ($listname && $listdomain);

            my $list = new List $listname;
            unless (defined $list) {
                Log::do_log('notice', 'Skipping unknown list %s', $listname);
                next;
            }

            if ($listdomain ne $list->{'domain'}) {
                my $old_path =
                    $root_dir . '/' . $listname . '@' . $listdomain;
                my $new_path =
                    $root_dir . '/' . $listname . '@' . $list->{'domain'};

                if (-d $new_path) {
                    Log::do_log(
                        'err',
                        'Could not rename %s to %s; directory already exists',
                        $old_path,
                        $new_path
                    );
                    next;
                } else {
                    unless (rename $old_path, $new_path) {
                        Log::do_log('err', 'Failed to rename %s to %s: %s',
                            $old_path, $new_path, $!);
                        next;
                    }
                    Log::do_log('notice', "Renamed %s to %s",
                        $old_path, $new_path);
                }
            }
        }
        close ARCDIR;

    }

    ## DB fields of enum type have been changed to int
    if (tools::lower_version($previous_version, '5.2a.1')) {

        if (SDM::use_db() && $Conf::Conf{'db_type'} eq 'mysql') {
            my %check = (
                'subscribed_subscriber' => 'subscriber_table',
                'included_subscriber'   => 'subscriber_table',
                'subscribed_admin'      => 'admin_table',
                'included_admin'        => 'admin_table'
            );

            foreach my $field (keys %check) {
                my $statement;
                my $sth;

                $sth = SDM::do_query(q{SELECT max(%s) FROM %s},
                    $field, $check{$field});
                unless ($sth) {
                    Log::do_log('err', 'Unable to prepare SQL statement');
                    return undef;
                }

                my $max = $sth->fetchrow();
                $sth->finish();

                ## '0' has been mapped to 1 and '1' to 2
                ## Restore correct field value
                if ($max > 1) {
                    ## 1 to 0
                    Log::do_log('notice',
                        'Fixing DB field %s; turning 1 to 0...', $field);
                    my $rows;
                    $sth =
                        SDM::do_query(q{UPDATE %s SET %s = %d WHERE %s = %d},
                        $check{$field}, $field, 0, $field, 1);
                    unless ($sth) {
                        Log::do_log('err', 'Unable to execute SQL statement');
                        return undef;
                    }
                    $rows = $sth->rows;
                    Log::do_log('notice', 'Updated %d rows', $rows);

                    ## 2 to 1
                    Log::do_log('notice',
                        'Fixing DB field %s; turning 2 to 1...', $field);

                    $sth =
                        SDM::do_query(q{UPDATE %s SET %s = %d WHERE %s = %d},
                        $check{$field}, $field, 1, $field, 2);
                    unless ($sth) {
                        Log::do_log('err', 'Unable to execute SQL statement');
                        return undef;
                    }
                    $rows = $sth->rows;
                    Log::do_log('notice', 'Updated %d rows', $rows);
                }

                ## Set 'subscribed' data field to '1' is none of 'subscribed'
                ## and 'included' is set
                Log::do_log('notice',
                    'Updating subscribed field of the subscriber table...');
                my $rows;
                $sth = SDM::do_query(
                    q{UPDATE subscriber_table
		      SET subscribed_subscriber = 1
		      WHERE (included_subscriber IS NULL OR
			     included_subscriber <> 1) AND
			    (subscribed_subscriber IS NULL OR
			     subscribed_subscriber <> 1)}
                );
                unless ($sth) {
                    Log::do_log('err', 'Unable to execute SQL statement');
                    return undef;
                }
                $rows = $sth->rows;
                Log::do_log('notice', '%d rows have been updated', $rows);
            }
        }
    }

    ## Rename bounce sub-directories
    if (tools::lower_version($previous_version, '5.2a.1')) {

        Log::do_log('notice',
            'Renaming bounce sub-directories adding list domain...');

        my $root_dir =
            Conf::get_robot_conf($Conf::Conf{'domain'}, 'bounce_path');
        unless (opendir BOUNCEDIR, $root_dir) {
            Log::do_log('err', 'Unable to open %s: %m', $root_dir);
            return undef;
        }

        foreach my $dir (sort readdir(BOUNCEDIR)) {
            ## Skip files and entries starting with '.'
            next
                if (($dir =~ /^\./o) || (!-d $root_dir . '/' . $dir));

            ## Directory already include the list domain
            next
                if ($dir =~ /\@/);

            my $listname = $dir;
            my $list     = new List $listname;
            unless (defined $list) {
                Log::do_log('notice', 'Skipping unknown list %s', $listname);
                next;
            }

            my $old_path = $root_dir . '/' . $listname;
            my $new_path =
                $root_dir . '/' . $listname . '@' . $list->{'domain'};

            if (-d $new_path) {
                Log::do_log('err',
                    'Could not rename %s to %s; directory already exists',
                    $old_path, $new_path);
                next;
            } else {
                unless (rename $old_path, $new_path) {
                    Log::do_log('err', 'Failed to rename %s to %s: %s',
                        $old_path, $new_path, $!);
                    next;
                }
                Log::do_log('notice', "Renamed %s to %s",
                    $old_path, $new_path);
            }
        }
        close BOUNCEDIR;
    }

    ## Update lists config using 'include_list'
    if (tools::lower_version($previous_version, '5.2a.1')) {

        Log::do_log('notice',
            'Update lists config using include_list parameter...');

        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {

            if (defined $list->{'admin'}{'include_list'}) {
                my $include_lists = $list->{'admin'}{'include_list'};
                my $changed       = 0;
                foreach my $index (0 .. $#{$include_lists}) {
                    my $incl      = $include_lists->[$index];
                    my $incl_list = List->new($incl);

                    if (defined $incl_list
                        and $incl_list->{'domain'} ne $list->{'domain'}) {
                        Log::do_log(
                            'notice',
                            'Update config file of list %s, including list %s',
                            $list->get_list_id(),
                            $incl_list->get_list_id()
                        );
                        $include_lists->[$index] = $incl_list->get_list_id();
                        $changed = 1;
                    }
                }
                if ($changed) {
                    $list->{'admin'}{'include_list'} = $include_lists;
                    $list->save_config('listmaster@' . $list->{'domain'});
                }
            }
        }
    }

    ## New mhonarc ressource file with utf-8 recoding
    if (tools::lower_version($previous_version, '5.3a.6')) {

        Log::do_log('notice',
            'Looking for customized mhonarc-ressources.tt2 files...');
        foreach my $vr (keys %{$Conf::Conf{'robots'}}) {
            my $etc_dir = $Conf::Conf{'etc'};

            if ($vr ne $Conf::Conf{'domain'}) {
                $etc_dir .= '/' . $vr;
            }

            if (-f $etc_dir . '/mhonarc-ressources.tt2') {
                my $new_filename =
                    $etc_dir . '/mhonarc-ressources.tt2' . '.' . time;
                rename $etc_dir . '/mhonarc-ressources.tt2', $new_filename;
                Log::do_log(
                    'notice',
                    "Custom %s file has been backed up as %s",
                    $etc_dir . '/mhonarc-ressources.tt2',
                    $new_filename
                );
                List::send_notify_to_listmaster('file_removed',
                    $Conf::Conf{'domain'},
                    [$etc_dir . '/mhonarc-ressources.tt2', $new_filename]);
            }
        }

        Log::do_log('notice', 'Rebuilding web archives...');
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            # FIXME: next line always success
            next unless (defined $list->{'admin'}{'web_archive'});
            my $file =
                  $Conf::Conf{'queueoutgoing'}
                . '/.rebuild.'
                . $list->get_list_id();

            unless (open REBUILD, ">$file") {
                Log::do_log('err', 'Cannot create %s', $file);
                next;
            }
            print REBUILD ' ';
            close REBUILD;
        }

    }

    ## Changed shared documents name encoding
    ## They are Q-encoded therefore easier to store on any filesystem with any
    ## encoding
    if (tools::lower_version($previous_version, '5.3a.8')) {
        Log::do_log('notice', 'Q-Encoding web documents filenames...');

        $language->push_lang($Conf::Conf{'lang'});
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            if (-d $list->{'dir'} . '/shared') {
                Log::do_log(
                    'notice',
                    'Processing list %s...',
                    $list->get_list_address()
                );

                ## Determine default lang for this list
                ## It should tell us what character encoding was used for
                ## filenames
                $language->set_lang($list->{'admin'}{'lang'});
                my $list_encoding = tools::lang2charset($language->get_lang);

                my $count =
                    tools::qencode_hierarchy($list->{'dir'} . '/shared',
                    $list_encoding);

                if ($count) {
                    Log::do_log('notice',
                        'List %s: %d filenames has been changed',
                        $list->{'name'}, $count);
                }
            }
        }
        $language->pop_lang;
    }

    ## We now support UTF-8 only for custom templates, config files, headers
    ## and footers, info files
    ## + web_tt2, scenari, create_list_templatee, families
    if (tools::lower_version($previous_version, '5.3b.3')) {
        Log::do_log('notice', 'Encoding all custom files to UTF-8...');

        my (@directories, @files);

        ## Site level
        foreach my $type (
            'mail_tt2', 'web_tt2',
            'scenari',  'create_list_templates',
            'families'
            ) {
            if (-d $Conf::Conf{'etc'} . '/' . $type) {
                push @directories,
                    [$Conf::Conf{'etc'} . '/' . $type, $Conf::Conf{'lang'}];
            }
        }

        foreach my $f (
            Conf::get_sympa_conf(),
            Conf::get_wwsympa_conf(),
            $Conf::Conf{'etc'} . '/' . 'topics.conf',
            $Conf::Conf{'etc'} . '/' . 'auth.conf'
            ) {
            if (-f $f) {
                push @files, [$f, $Conf::Conf{'lang'}];
            }
        }

        ## Go through Virtual Robots
        foreach my $vr (keys %{$Conf::Conf{'robots'}}) {
            foreach my $type (
                'mail_tt2', 'web_tt2',
                'scenari',  'create_list_templates',
                'families'
                ) {
                if (-d $Conf::Conf{'etc'} . '/' . $vr . '/' . $type) {
                    push @directories,
                        [
                        $Conf::Conf{'etc'} . '/' . $vr . '/' . $type,
                        Conf::get_robot_conf($vr, 'lang')
                        ];
                }
            }

            foreach my $f ('robot.conf', 'topics.conf', 'auth.conf') {
                if (-f $Conf::Conf{'etc'} . '/' . $vr . '/' . $f) {
                    push @files,
                        [
                        $Conf::Conf{'etc'} . '/' . $vr . '/' . $f,
                        $Conf::Conf{'lang'}
                        ];
                }
            }
        }

        ## Search in Lists
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            foreach my $f (
                'config',   'info',
                'homepage', 'message.header',
                'message.footer'
                ) {
                if (-f $list->{'dir'} . '/' . $f) {
                    push @files,
                        [$list->{'dir'} . '/' . $f, $list->{'admin'}{'lang'}];
                }
            }

            foreach my $type ('mail_tt2', 'web_tt2', 'scenari') {
                my $directory = $list->{'dir'} . '/' . $type;
                if (-d $directory) {
                    push @directories, [$directory, $list->{'admin'}{'lang'}];
                }
            }
        }

        ## Search language directories
        foreach my $pair (@directories) {
            my ($d, $lang) = @$pair;
            unless (opendir DIR, $d) {
                next;
            }

            if ($d =~ /(mail_tt2|web_tt2)$/) {
                foreach
                    my $subdir (grep(/^[a-z]{2}(_[A-Z]{2})?$/, readdir DIR)) {
                    if (-d "$d/$subdir") {
                        push @directories, ["$d/$subdir", $subdir];
                    }
                }
                closedir DIR;

            } elsif ($d =~ /(create_list_templates|families)$/) {
                foreach my $subdir (grep(/^\w+$/, readdir DIR)) {
                    if (-d "$d/$subdir") {
                        push @directories,
                            ["$d/$subdir", $Conf::Conf{'lang'}];
                    }
                }
                closedir DIR;
            }
        }

        foreach my $pair (@directories) {
            my ($d, $lang) = @$pair;
            unless (opendir DIR, $d) {
                next;
            }
            foreach my $file (readdir DIR) {
                next
                    unless (
                    (   $d =~
                        /mail_tt2|web_tt2|create_list_templates|families/
                        && $file =~ /\.tt2$/
                    )
                    || ($d =~ /scenari$/ && $file =~ /\w+\.\w+$/)
                    );
                push @files, [$d . '/' . $file, $lang];
            }
            closedir DIR;
        }

        ## Do the encoding modifications
        ## Previous versions of files are backed up with the date extension
        my $total = to_utf8(\@files);
        Log::do_log('notice', '%d files have been modified', $total);
    }

    ## giving up subscribers flat files ; moving subscribers to the DB
    ## Also giving up old 'database' mode
    if (tools::lower_version($previous_version, '5.4a.1')) {

        Log::do_log('notice',
            'Looking for lists with user_data_source parameter set to file or database...'
        );

        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {

            if ($list->{'admin'}{'user_data_source'} eq 'file') {

                Log::do_log(
                    'notice',
                    'List %s; changing user_data_source from file to include2...',
                    $list->{'name'}
                );

                my @users = List::_load_list_members_file(
                    "$list->{'dir'}/subscribers");

                $list->{'admin'}{'user_data_source'} = 'include2';
                $list->{'total'} = 0;

                ## Add users to the DB
                $list->add_list_member(@users);
                my $total = $list->{'add_outcome'}{'added_members'};
                if (defined $list->{'add_outcome'}{'errors'}) {
                    Log::do_log(
                        'err',
                        'Failed to add users: %s',
                        $list->{'add_outcome'}{'errors'}{'error_message'}
                    );
                }

                Log::do_log('notice',
                    '%d subscribers have been loaded into the database',
                    $total);

                unless ($list->save_config('automatic')) {
                    Log::do_log('err',
                        'Failed to save config file for list %s',
                        $list->{'name'});
                }
            } elsif ($list->{'admin'}{'user_data_source'} eq 'database') {

                Log::do_log(
                    'notice',
                    'List %s; changing user_data_source from database to include2...',
                    $list->{'name'}
                );

                unless ($list->update_list_member('*', {'subscribed' => 1})) {
                    Log::do_log('err',
                        'Failed to update subscribed DB field');
                }

                $list->{'admin'}{'user_data_source'} = 'include2';

                unless ($list->save_config('automatic')) {
                    Log::do_log('err',
                        'Failed to save config file for list %s',
                        $list->{'name'});
                }
            }
        }
    }

    if (tools::lower_version($previous_version, '5.5a.1')) {

        ## Remove OTHER/ subdirectories in bounces
        Log::do_log('notice', "Removing obsolete OTHER/ bounce directories");
        if (opendir BOUNCEDIR,
            Conf::get_robot_conf($Conf::Conf{'domain'}, 'bounce_path')) {

            foreach my $subdir (sort grep (!/^\.+$/, readdir(BOUNCEDIR))) {
                my $other_dir =
                    Conf::get_robot_conf($Conf::Conf{'domain'}, 'bounce_path')
                    . '/'
                    . $subdir
                    . '/OTHER';
                if (-d $other_dir) {
                    tools::remove_dir($other_dir);
                    Log::do_log('notice', 'Directory %s removed', $other_dir);
                }
            }

            close BOUNCEDIR;

        } else {
            Log::do_log(
                'err',
                'Failed to open directory %s: %m',
                $Conf::Conf{'queuebounce'}
            );
        }

    }

    if (tools::lower_version($previous_version, '6.1b.5')) {
        ## Encoding of shared documents was not consistent with recent
        ## versions of MIME::Encode
        ## MIME::EncWords::encode_mimewords() used to encode characters -!*+/
        ## Now these characters are preserved, according to RFC 2047 section 5
        ## We change encoding of shared documents according to new algorithm
        Log::do_log('notice',
            'Fixing Q-encoding of web document filenames...');
        my $all_lists = List::get_lists('*');
        foreach my $list (@$all_lists) {
            if (-d $list->{'dir'} . '/shared') {
                Log::do_log(
                    'notice',
                    'Processing list %s...',
                    $list->get_list_address()
                );

                my @all_files;
                tools::list_dir($list->{'dir'}, \@all_files, 'utf-8');

                my $count;
                foreach my $f_struct (reverse @all_files) {
                    my $new_filename = $f_struct->{'filename'};

                    ## Decode and re-encode filename
                    $new_filename =
                        tools::qencode_filename(
                        tools::qdecode_filename($new_filename));

                    if ($new_filename ne $f_struct->{'filename'}) {
                        ## Rename file
                        my $orig_f =
                              $f_struct->{'directory'} . '/'
                            . $f_struct->{'filename'};
                        my $new_f =
                            $f_struct->{'directory'} . '/' . $new_filename;
                        Log::do_log('notice', "Renaming %s to %s",
                            $orig_f, $new_f);
                        unless (rename $orig_f, $new_f) {
                            Log::do_log('err',
                                'Failed to rename %s to %s: %s',
                                $orig_f, $new_f, $!);
                            next;
                        }
                        $count++;
                    }
                }
                if ($count) {
                    Log::do_log('notice',
                        'List %s: %d filenames has been changed',
                        $list->{'name'}, $count);
                }
            }
        }

    }
    if (tools::lower_version($previous_version, '6.1.11')) {
        ## Exclusion table was not robot-enabled.
        Log::do_log('notice', 'Fixing robot column of exclusion table');
        my $sth;
        unless ($sth = SDM::do_query("SELECT * FROM exclusion_table")) {
            Log::do_log('err',
                'Unable to gather informations from the exclusions table');
        }
        my @robots = List::get_robots();
        while (my $data = $sth->fetchrow_hashref) {
            next
                if (defined $data->{'robot_exclusion'}
                && $data->{'robot_exclusion'} ne '');
            ## Guessing right robot for each exclusion.
            my $valid_robot = '';
            my @valid_robot_candidates;
            foreach my $robot (@robots) {
                if (my $list = List->new($data->{'list_exclusion'}, $robot)) {
                    if ($list->is_list_member($data->{'user_exclusion'})) {
                        push @valid_robot_candidates, $robot;
                    }
                }
            }
            if ($#valid_robot_candidates == 0) {
                $valid_robot = $valid_robot_candidates[0];
                my $sth;
                unless (
                    $sth = SDM::do_query(
                        "UPDATE exclusion_table SET robot_exclusion = %s WHERE list_exclusion=%s AND user_exclusion=%s",
                        SDM::quote($valid_robot),
                        SDM::quote($data->{'list_exclusion'}),
                        SDM::quote($data->{'user_exclusion'})
                    )
                    ) {
                    Log::do_log(
                        'err',
                        'Unable to update entry (%s, %s) in exclusions table (trying to add robot %s)',
                        $data->{'list_exclusion'},
                        $data->{'user_exclusion'},
                        $valid_robot
                    );
                }
            } else {
                Log::do_log(
                    'err',
                    'Exclusion robot could not be guessed for user "%s" in list "%s". Either this user is no longer subscribed to the list or the list appears in more than one robot (or the query to the database failed). Here is the list of robots in which this list name appears: "%s"',
                    $data->{'user_exclusion'},
                    $data->{'list_exclusion'},
                    @valid_robot_candidates
                );
            }
        }
        ## Caching all lists config subset to database
        Log::do_log('notice', 'Caching all lists config subset to database');
        List::_flush_list_db();
        my $all_lists = List::get_lists('*', 'reload_config' => 1);
        foreach my $list (@$all_lists) {
            $list->_update_list_db;
        }
    }

    ## We have obsoleted wwsympa.conf.  It would be migrated to sympa.conf.
    if (tools::lower_version($previous_version, '6.2b.1')) {
        my $sympa_conf   = Conf::get_sympa_conf();
        my $wwsympa_conf = Conf::get_wwsympa_conf();
        my $fh;
        my %migrated = ();
        my @newconf  = ();
        my $date;

        ## Some sympa.conf parameters were overridden by wwsympa.conf.
        ## Others prefer sympa.conf.
        my %wwsconf_override = (
            'arc_path'                   => 'yes',
            'archive_default_index'      => 'yes',
            'bounce_path'                => 'yes',
            'cookie_domain'              => 'NO',
            'cookie_expire'              => 'yes',
            'cookie_refresh'             => 'NO',
            'custom_archiver'            => 'yes',
            'default_home'               => 'NO',
            'export_topics'              => 'yes',
            'htmlarea_url'               => 'yes',
            'html_editor_file'           => 'NO',    # 6.2a
            'html_editor_init'           => 'NO',
            'ldap_force_canonical_email' => 'NO',
            'log_facility'               => 'yes',
            'mhonarc'                    => 'yes',
            'password_case'              => 'NO',
            'review_page_size'           => 'yes',
            'title'                      => 'NO',
            'use_fast_cgi'               => 'yes',
            'use_html_editor'            => 'NO',
            'viewlogs_page_size'         => 'yes',
            'wws_path'                   => undef,
        );
        ## Old params
        my %old_param = (
            'alias_manager' => 'No more used, using '
                . $Conf::Conf{'alias_manager'},
            'wws_path' => 'No more used',
            'icons_url' =>
                'No more used. Using static_content/icons instead.',
            'robots' =>
                'Not used anymore. Robots are fully described in their respective robot.conf file.',
            'task_manager_pidfile' => 'No more used',
            'archived_pidfile'     => 'No more used',
            'bounced_pidfile'      => 'No more used',
        );

        ## Set language of new file content
        $language->push_lang($Conf::Conf{'lang'});
        $date =
            $language->gettext_strftime("%d.%b.%Y-%H.%M.%S", localtime time);

        if (-r $wwsympa_conf) {
            ## load only sympa.conf
            my $conf = (
                Conf::_load_config_file_to_hash(
                    {'path_to_config_file' => $sympa_conf}
                    )
                    || {}
            )->{'config'};
            # not yet implemented.
            #my $conf = Conf::load_robot_conf(
            #    {'robot' => '*', 'no_db' => 1, 'return_result' => 1}
            #);

            my %infile = ();
            ## load defaults
            foreach my $p (@Sympa::ConfDef::params) {
                next unless $p->{'name'};
                next unless $p->{'file'};
                next unless $p->{'file'} eq 'wwsympa.conf';
                $infile{$p->{'name'}} = $p->{'default'};
            }
            ## get content of wwsympa.conf
            open my $fh, '<', $wwsympa_conf;
            while (<$fh>) {
                next if /^\s*#/;
                chomp $_;
                next unless /^\s*(\S+)\s+(.+)$/i;
                my ($k, $v) = ($1, $2);
                $infile{$k} = $v;
            }
            close $fh;

            my $name;
            foreach my $p (@Sympa::ConfDef::params) {
                next unless $p->{'name'};
                $name = $p->{'name'};
                next unless exists $infile{$name};

                unless ($p->{'file'} and $p->{'file'} eq 'wwsympa.conf') {
                    ## may it exist in wwsympa.conf?
                    $migrated{'unknown'} ||= {};
                    $migrated{'unknown'}->{$name} = [$p, $infile{$name}];
                } elsif (exists $conf->{$name}) {
                    if ($wwsconf_override{$name} eq 'yes') {
                        ## does it override sympa.conf?
                        $migrated{'override'} ||= {};
                        $migrated{'override'}->{$name} = [$p, $infile{$name}];
                    } elsif (defined $conf->{$name}) {
                        ## or, is it there in sympa.conf?
                        $migrated{'duplicate'} ||= {};
                        $migrated{'duplicate'}->{$name} =
                            [$p, $infile{$name}];
                    } else {
                        ## otherwise, use values in wwsympa.conf
                        $migrated{'add'} ||= {};
                        $migrated{'add'}->{$name} = [$p, $infile{$name}];
                    }
                } else {
                    ## otherwise, use values in wwsympa.conf
                    $migrated{'add'} ||= {};
                    $migrated{'add'}->{$name} = [$p, $infile{$name}];
                }
                delete $infile{$name};
            }
            ## obsoleted or unknown parameters
            foreach my $name (keys %infile) {
                if ($old_param{$name}) {
                    $migrated{'obsolete'} ||= {};
                    $migrated{'obsolete'}->{$name} = [
                        {'name' => $name, 'gettext_id' => $old_param{$name}},
                        $infile{$name}
                    ];
                } else {
                    $migrated{'unknown'} ||= {};
                    $migrated{'unknown'}->{$name} = [
                        {   'name'       => $name,
                            'gettext_id' => 'Unknown parameter'
                        },
                        $infile{$name}
                    ];
                }
            }
        }

        ## Add contents to sympa.conf
        if (%migrated) {
            open $fh, '<', $sympa_conf or die $!;
            @newconf = <$fh>;
            close $fh;
            $newconf[$#newconf] .= "\n" unless $newconf[$#newconf] =~ /\n\z/;

            push @newconf,
                  "\n"
                . ('#' x 76) . "\n" . '#### '
                . $language->gettext("Migration from wwsympa.conf") . "\n"
                . '#### '
                . $date . "\n"
                . ('#' x 76) . "\n\n";

            foreach my $type (qw(duplicate add obsolete unknown)) {
                my %newconf = %{$migrated{$type} || {}};
                next unless scalar keys %newconf;

                push @newconf,
                    tools::wrap_text(
                    $language->gettext(
                        "Migrated Parameters\nFollowing parameters were migrated from wwsympa.conf."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'add';
                push @newconf,
                    tools::wrap_text(
                    $language->gettext(
                        "Overrididing Parameters\nFollowing parameters existed both in sympa.conf and  wwsympa.conf.  Previous release of Sympa used those in wwsympa.conf.  Comment-out ones you wish to be disabled."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'override';
                push @newconf,
                    tools::wrap_text(
                    $language->gettext(
                        "Duplicate of sympa.conf\nThese parameters were found in both sympa.conf and wwsympa.conf.  Previous release of Sympa used those in sympa.conf.  Uncomment ones you wish to be enabled."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'duplicate';
                push @newconf,
                    tools::wrap_text(
                    $language->gettext(
                        "Old Parameters\nThese parameters are no longer used."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'obsolete';
                push @newconf,
                    tools::wrap_text(
                    $language->gettext(
                        "Unknown Parameters\nThough these parameters were found in wwsympa.conf, they were ignored.  You may simply remove them."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'unknown';

                foreach my $k (sort keys %newconf) {
                    my ($param, $v) = @{$newconf{$k}};

                    push @newconf,
                        tools::wrap_text(
                        $language->gettext($param->{'gettext_id'}),
                        '## ', '## ')
                        if $param->{'gettext_id'};
                    push @newconf,
                        tools::wrap_text(
                        $language->gettext($param->{'gettext_comment'}),
                        '## ', '## ')
                        if $param->{'gettext_comment'};
                    if (defined $v
                        and ($type eq 'add' or $type eq 'override')) {
                        push @newconf,
                            sprintf("%s\t%s\n\n", $param->{'name'}, $v);
                    } else {
                        push @newconf,
                            sprintf("#%s\t%s\n\n", $param->{'name'}, $v);
                    }
                }
            }
        }

        ## Restore language
        $language->pop_lang;

        if (%migrated) {
            warn sprintf 'Unable to rename %s : %s', $sympa_conf, $!
                unless rename $sympa_conf, "$sympa_conf.$date";
            ## Write new config files
            my $umask = umask 037;
            unless (open $fh, '>', $sympa_conf) {
                umask $umask;
                die sprintf 'Unable to open %s : %s', $sympa_conf, $!;
            }
            umask $umask;
            chown [getpwnam(Sympa::Constants::USER)]->[2],
                [getgrnam(Sympa::Constants::GROUP)]->[2], $sympa_conf;
            print $fh @newconf;
            close $fh;

            ## Keep old config file
            printf
                "%s has been updated.\nPrevious version has been saved as %s.\n",
                $sympa_conf, "$sympa_conf.$date";
        }

        if (-r $wwsympa_conf) {
            ## Keep old config file
            warn sprintf 'Unable to rename %s : %s', $wwsympa_conf, $!
                unless rename $wwsympa_conf, "$wwsympa_conf.$date";
            printf
                "%s will NO LONGER be used.\nPrevious version has been saved as %s.\n",
                $wwsympa_conf, "$wwsympa_conf.$date";
        }
    }

    # Create HTML view of pending messages
    if (tools::lower_version($previous_version, '6.2b.1')) {
        my $spooldir     = $Conf::Conf{'queuemod'};
        my $viewmail_dir = $Conf::Conf{'viewmail_dir'};
        my @ignored      = ();
        my @performed    = ();

        my $umask = umask oct($Conf::Conf{'umask'});

        # Create directory for HTML view if necessary
        unless (-d "$viewmail_dir/mod") {
            my @dirs = File::Path::mkpath("$viewmail_dir/mod");
            foreach my $dir (@dirs) {
                tools::set_file_rights(
                    'file'  => $dir,
                    'user'  => Sympa::Constants::USER(),
                    'group' => Sympa::Constants::GROUP(),
                );
            }
        }

        unless (opendir DIR, $spooldir) {
            die sprintf 'Can\t open dir %s: %s', $spooldir, "$!";
            ## No return.
        }
        my @qfile = grep !/^\./, readdir DIR;
        closedir DIR;

        foreach my $filename (sort @qfile) {
            ## For compatibility concern:
            ## <name>@<robot>_<key> and <name>_<key> are possible.
            unless ($filename =~ /^([^@]*)(?:\@([^@]*))?\_(.*)$/) {
                push @ignored, $filename;
                next;
            }
            my $listname = lc $1;
            my $robot_id = lc($2 || $Conf::Conf{'domain'});
            my $modkey   = $3;

            # check if robot exists
            unless (Conf::valid_robot($robot_id)) {
                push @ignored, $filename;
                next;
            }
            my $list = List->new($listname, $robot_id);
            unless ($list) {
                push @ignored, $filename;
                next;
            }
            my $message = Message->new({'file' => "$spooldir/$filename"});
            unless ($message) {
                push @ignored, $filename;
                next;
            }

            my $destination_dir =
                  $viewmail_dir . '/mod/'
                . $list->get_list_id() . '/'
                . $modkey;
            if (-e $destination_dir) {
                push @ignored, $filename;
                next;
            } else {
                my @dirs = File::Path::mkpath($destination_dir);
                foreach my $dir (@dirs) {
                    tools::set_file_rights(
                        'file'  => $dir,
                        'user'  => Sympa::Constants::USER(),
                        'group' => Sympa::Constants::GROUP(),
                    );
                }
            }

            Sympa::Archive::convert_single_message(
                $list, $message,
                'destination_dir' => $destination_dir,
                'attachement_url' =>
                    join('/', '..', 'viewmod', $listname, $modkey),
            );
            File::Find::find(
                sub {
                    tools::set_file_rights(
                        'file'  => $File::Find::name,
                        'user'  => Sympa::Constants::USER(),
                        'group' => Sympa::Constants::GROUP(),
                    );
                },
                $destination_dir
            );

            push @performed, $filename;
        }

        # Restore umask
        umask $umask;

        Log::do_log('info', 'Upgrade process for spool %s: ignored files %s',
            $spooldir, join(', ', @ignored))
            if @ignored;
        Log::do_log('info',
            'Upgrade process for spool %s: performed files %s',
            $spooldir, join(', ', @performed))
            if @performed;
    }

    return 1;
}

sub probe_db {
    SDM::probe_db();
}

sub data_structure_uptodate {
    SDM::data_structure_uptodate();
}

## used to encode files to UTF-8
## also add X-Attach header field if template requires it
## IN : - arrayref with list of filepath/lang pairs
sub to_utf8 {
    my $files = shift;

    my $with_attachments =
        qr{ archive.tt2 | digest.tt2 | get_archive.tt2 | listmaster_notification.tt2 | 
				   message_report.tt2 | moderate.tt2 |  modindex.tt2 | send_auth.tt2 }x;
    my $total;

    foreach my $pair (@{$files}) {
        my ($file, $lang) = @$pair;
        unless (open(TEMPLATE, $file)) {
            Log::do_log('err', "Cannot open template %s", $file);
            next;
        }

        my $text     = '';
        my $modified = 0;

        ## If filesystem_encoding is set, files are supposed to be encoded
        ## according to it
        my $charset;
        if (defined $Conf::Ignored_Conf{'filesystem_encoding'}
            and $Conf::Ignored_Conf{'filesystem_encoding'} ne 'utf-8') {
            $charset = $Conf::Ignored_Conf{'filesystem_encoding'};
        } else {
            $language->push_lang($lang);
            $charset = tools::lang2charset($language->get_lang);
            $language->pop_lang;
        }

        # Add X-Sympa-Attach: headers if required.
        if (($file =~ /mail_tt2/) && ($file =~ /\/($with_attachments)$/)) {
            while (<TEMPLATE>) {
                $text .= $_;
                if (m/^Content-Type:\s*message\/rfc822/i) {
                    while (<TEMPLATE>) {
                        if (m{^X-Sympa-Attach:}i) {
                            $text .= $_;
                            last;
                        }
                        if (m/^[\r\n]+$/) {
                            $text .= "X-Sympa-Attach: yes\n";
                            $modified = 1;
                            $text .= $_;
                            last;
                        }
                        $text .= $_;
                    }
                }
            }
        } else {
            $text = join('', <TEMPLATE>);
        }
        close TEMPLATE;

        # Check if template is encoded by UTF-8.
        if ($text =~ /[^\x20-\x7E]/) {
            my $t = $text;
            eval { Encode::decode('UTF-8', $t, Encode::FB_CROAK); };
            if ($@) {
                eval {
                    $t = $text;
                    Encode::from_to($t, $charset, "UTF-8", Encode::FB_CROAK);
                };
                if ($@) {
                    Log::do_log('err',
                        "Template %s cannot be converted from %s to UTF-8",
                        $charset, $file);
                } else {
                    $text     = $t;
                    $modified = 1;
                }
            }
        }

        next unless $modified;

        my $date = POSIX::strftime("%Y.%m.%d-%H.%M.%S", localtime(time));
        unless (rename $file, $file . '@' . $date) {
            Log::do_log('err', "Cannot rename old template %s", $file);
            next;
        }
        unless (open(TEMPLATE, ">$file")) {
            Log::do_log('err', "Cannot open new template %s", $file);
            next;
        }
        print TEMPLATE $text;
        close TEMPLATE;
        unless (
            tools::set_file_rights(
                file  => $file,
                user  => Sympa::Constants::USER,
                group => Sympa::Constants::GROUP,
                mode  => 0644,
            )
            ) {
            Log::do_log('err', 'Unable to set rights on %s',
                $Conf::Conf{'db_name'});
            next;
        }
        Log::do_log('notice', 'Modified file %s; original file kept as %s',
            $file, $file . '@' . $date);

        $total++;
    }

    return $total;
}

# md5_encode_password : Version later than 5.4 uses md5 fingerprint instead of
# symetric crypto to store password.
#  This require to rewrite paassword in database. This upgrade IS NOT
#  REVERSIBLE
sub md5_encode_password {

    my $total = 0;

    Log::do_log('notice',
        'Upgrade::md5_encode_password() recoding password using md5 fingerprint'
    );

    unless (SDM::check_db_connect('just_try')) {
        return undef;
    }

    my $sth =
        SDM::do_query(q{SELECT email_user, password_user from user_table});
    unless ($sth) {
        Log::do_log('err', 'Unable to prepare SQL statement');
        return undef;
    }

    $total = 0;
    my $total_md5 = 0;

    while (my $user = $sth->fetchrow_hashref('NAME_lc')) {

        my $clear_password;
        if ($user->{'password_user'} =~ /^[0-9a-f]{32}/) {
            Log::do_log('info',
                'Password from %s already encoded as md5 fingerprint',
                $user->{'email_user'});
            $total_md5++;
            next;
        }

        ## Ignore empty passwords
        next if ($user->{'password_user'} =~ /^$/);

        if ($user->{'password_user'} =~ /^crypt.(.*)$/) {
            $clear_password =
                tools::decrypt_password($user->{'password_user'});
        } else {    ## Old style cleartext passwords
            $clear_password = $user->{'password_user'};
        }

        $total++;

        ## Updating Db
        unless (
            SDM::do_query(
                q{UPDATE user_table
	      SET password_user = %s
	      WHERE email_user = %s},
                SDM::quote(
                    Sympa::Auth::password_fingerprint($clear_password)
                ),
                SDM::quote($user->{'email_user'})
            )
            ) {
            Log::do_log('err', 'Unable to execute SQL statement');
            return undef;
        }
    }
    $sth->finish();

    Log::do_log(
        'info',
        "Updating password storage in table user_table using md5 for %d users",
        $total
    );
    if ($total_md5) {
        Log::do_log(
            'info',
            "Found in table user %d password stored using md5, did you run Sympa before upgrading ?",
            $total_md5
        );
    }
    return $total;
}

1;
