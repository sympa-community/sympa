# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020, 2021, 2022, 2023 The Sympa Community.
# See the AUTHORS.md file at the top-level directory of this distribution
# and at <https://github.com/sympa-community/sympa.git>.
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

package Sympa::Upgrade;

use strict;
use warnings;
use Cwd qw();
use Encode qw();
use English qw(-no_match_vars);
use File::Copy qw();
use MIME::Base64 qw();
use Time::Local qw();

use Sympa;
use Sympa::CLI;
use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Message;
use Sympa::Request;
use Sympa::Spool;
use Sympa::Spool::Archive;
use Sympa::Spool::Auth;
use Sympa::Spool::Digest;
use Sympa::Tools::Data;
use Sympa::Tools::File;
use Sympa::Tools::Text;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

## Return the previous Sympa version, ie the one listed in
## data_structure.version
sub get_previous_version {
    my $version_file = "$Conf::Conf{'etc'}/data_structure.version";
    my $previous_version;

    if (-f $version_file) {
        my $ifh;
        unless (open $ifh, '<', $version_file) {
            $log->syslog('err', 'Unable to open %s: %m', $version_file);
            return undef;
        }
        while (<$ifh>) {
            next if /^\s*$/;
            next if /^\s*\#/;
            chomp;
            $previous_version = $_;
            last;
        }
        close $ifh;

        return $previous_version;
    }

    return undef;
}

sub update_version {
    my $version_file = "$Conf::Conf{'etc'}/data_structure.version";

    ## Saving current version if required
    my $ofh;
    unless (open $ofh, '>', $version_file) {
        $log->syslog(
            'err',
            'Unable to write %s; Sympa needs write access on %s directory: %m',
            $version_file,
            $Conf::Conf{'etc'}
        );
        return undef;
    }
    printf $ofh
        "# This file is automatically created by sympa after installation\n# Unless you know what you are doing, you should not modify it\n";
    printf $ofh "%s\n", Sympa::Constants::VERSION;
    close $ofh;

    return 1;
}

## Upgrade data structure from one version to another
sub upgrade {
    $log->syslog('debug3', '(%s, %s)', @_);
    my ($previous_version, $new_version) = @_;

    if (lower_version($new_version, $previous_version)) {
        $log->syslog('notice',
            'Installing  older version of Sympa ; no upgrade operation is required'
        );
        return 1;
    }

    ## Check database connectivity and probe database
    unless (Sympa::DatabaseManager::probe_db()) {
        $log->syslog(
            'err',
            'Database %s defined in sympa.conf has not the right structure or is unreachable. verify db_xxx parameters in sympa.conf',
            $Conf::Conf{'db_name'}
        );
        return undef;
    }

    # As of 6.2.33b.1, owners/moderators are no longer stored in config file.
    # - Write out initial permanent owners/editors in <role>.dump files.
    # - And, if list is not closed, import owners/moderators from those files
    #   into database.
    if (lower_version($previous_version, '6.2.33b.1')) {
        $log->syslog('notice',
            'Restoring users of ALL lists...it may take a while...');

        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@{$all_lists || []}) {
            next unless $list;
            my $dir = $list->{'dir'};

            my $fh;
            next unless open $fh, '<', $dir . '/config';
            my $config = do { local $RS; <$fh> };
            close $fh;

            $config =~ s/(\A|\n)[\t ]+(?=\n)/$1/g;    # normalize empty lines
            open my $ifh, '<', \$config;              # open "in memory" file
            my @config = do { local $RS = ''; <$ifh> };
            close $ifh;
            foreach my $role (qw(owner editor)) {
                my $file = $dir . '/' . $role . '.dump';
                if (!-e $file and open my $ofh, '>', $file) {
                    my $admins = join '', grep {/\A\s*$role\b/} @config;
                    print $ofh $admins;
                    close $ofh;
                }

                next
                    if $list->{'admin'}{'status'} eq 'closed'
                    or $list->{'admin'}{'status'} eq 'family_closed';
                $list->restore_users($role);
            }
        }
    }

    # Always update config.bin files while upgrading.
    # This is especially useful for character encoding reasons.
    $log->syslog('notice',
        'Rebuilding config.bin files for ALL lists...it may take a while...');
    my $all_lists = Sympa::List::get_lists('*', reload_config => 1);
    # Recreate admin_table entries. #FIXME: Is this needed here?
    $log->syslog('notice',
        'Rebuilding the admin_table...it may take a while...');
    foreach my $list (@{$all_lists || []}) {    # See GH #71
        $list->sync_include('owner');
        $list->sync_include('editor');
    }

    ## Migration to tt2
    if (lower_version($previous_version, '4.2b')) {
        # Orgranization of templates has been changed and migration is no use.
        #$log->syslog('notice', 'Migrating templates to TT2 format...');
        #
        #my $tpl_script = Sympa::Constants::SCRIPTDIR . '/tpl2tt2.pl';
        #my $pipein;
        #unless (open $pipein, '-|', $tpl_script) {    #FIXME
        #    $log->syslog('err', 'Unable to run %s', $tpl_script);
        #    return undef;
        #}
        #close $pipein;

        $log->syslog('notice', 'Rebuilding web archives...');
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            # FIXME: line below will always success
            next
                unless defined $list->{'admin'}{'web_archive'}
                or defined $list->{'admin'}{'archive'};

            my $arc_message = Sympa::Message->new(
                sprintf("\nrebuildarc %s *\n\n", $list->{'name'}),
                context => $list->{'domain'},
                sender  => sprintf('listmaster@%s', $list->{'domain'}),
                date    => time
            );
            unless (Sympa::Spool::Archive->new->store($arc_message)) {
                $log->syslog('err', 'Cannot rebuild web archive of %s',
                    $list);
                next;
            }
        }
    }

    ## Initializing the new admin_table
    if (lower_version($previous_version, '4.2b.4')) {
        $log->syslog('notice', 'Initializing the new admin_table...');
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            $list->sync_include('owner');
            $list->sync_include('editor');
        }
    }

    ## Move old-style web templates out of the include_path
    if (lower_version($previous_version, '5.0.1')) {
        $log->syslog('notice',
            'Old web templates HTML structure is not compliant with latest ones.'
        );
        $log->syslog('notice',
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
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            if (-d ($list->{'dir'} . '/web_tt2')) {
                push @directories, $list->{'dir'} . '/web_tt2';
            }
        }

        my @templates;

        foreach my $d (@directories) {
            my $dh;
            unless (opendir $dh, $d) {
                printf STDERR "Error: Cannot read %s directory: %s", $d,
                    $ERRNO;
                next;
            }

            foreach my $tt2 (sort grep {/\.tt2$/} readdir $dh) {
                push @templates, "$d/$tt2";
            }

            closedir $dh;
        }

        foreach my $tpl (@templates) {
            unless (rename $tpl, "$tpl.oldtemplate") {
                printf STDERR
                    "Error : failed to rename %s to %s.oldtemplate: %s\n",
                    $tpl, $tpl, $ERRNO;
                next;
            }

            $log->syslog('notice', 'File %s renamed %s',
                $tpl, "$tpl.oldtemplate");
        }
    }

    ## Clean buggy list config files
    if (lower_version($previous_version, '5.1b')) {
        $log->syslog('notice', 'Cleaning buggy list config files...');
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            $list->save_config('listmaster@' . $list->{'domain'});
        }
    }

    ## Fix a bug in Sympa 5.1
    if (lower_version($previous_version, '5.1.2')) {
        $log->syslog('notice', 'Rename archives/log. files...');
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            if (-f $list->{'dir'} . '/archives/log.') {
                rename $list->{'dir'} . '/archives/log.',
                    $list->{'dir'} . '/archives/log.00';
            }
        }
    }

    if (lower_version($previous_version, '5.2a.1')) {

        ## Fill the robot_subscriber and robot_admin fields in DB
        $log->syslog('notice',
            'Updating the new robot_subscriber and robot_admin  Db fields...'
        );

        foreach my $r (keys %{$Conf::Conf{'robots'}}) {
            my $all_lists = Sympa::List::get_lists($r);
            foreach my $list (@$all_lists) {
                my $sdm = Sympa::DatabaseManager->instance;
                foreach my $table ('subscriber', 'admin') {
                    unless (
                        $sdm
                        and $sdm->do_query(
                            "UPDATE %s_table SET robot_%s=%s WHERE (list_%s=%s)",
                            $table,
                            $table,
                            $sdm->quote($r),
                            $table,
                            $sdm->quote($list->{'name'})
                        )
                    ) {
                        $log->syslog(
                            'err',
                            'Unable to fille the robot_admin and robot_subscriber fields in database for robot %s',
                            $r
                        );
                        Sympa::send_notify_to_listmaster('*',
                            'upgrade_failed', {'error' => $sdm->error});
                        return undef;
                    }
                }
            }
        }

        ## Rename web archive directories using 'domain' instead of 'host'
        $log->syslog('notice',
            'Renaming web archive directories with the list domain...');

        my $root_dir =
            Conf::get_robot_conf($Conf::Conf{'domain'}, 'arc_path');
        my $dh;
        unless (opendir $dh, $root_dir) {
            $log->syslog('err', 'Unable to open %s: %m', $root_dir);
            return undef;
        }

        foreach my $dir (sort readdir $dh) {
            ## Skip files and entries starting with '.'
            next
                if (($dir =~ /^\./o) || (!-d $root_dir . '/' . $dir));

            my ($listname, $listdomain) = split /\@/, $dir;

            next unless ($listname && $listdomain);

            my $list = Sympa::List->new($listname, $listdomain);
            unless (defined $list) {
                $log->syslog('notice', 'Skipping unknown list %s', $listname);
                next;
            }

            if ($listdomain ne $list->{'domain'}) {
                my $old_path =
                    $root_dir . '/' . $listname . '@' . $listdomain;
                my $new_path =
                    $root_dir . '/' . $listname . '@' . $list->{'domain'};

                if (-d $new_path) {
                    $log->syslog(
                        'err',
                        'Could not rename %s to %s; directory already exists',
                        $old_path,
                        $new_path
                    );
                    next;
                } else {
                    unless (rename $old_path, $new_path) {
                        $log->syslog('err', 'Failed to rename %s to %s: %m',
                            $old_path, $new_path);
                        next;
                    }
                    $log->syslog('notice', "Renamed %s to %s",
                        $old_path, $new_path);
                }
            }
        }
        closedir $dh;

    }

    ## DB fields of enum type have been changed to int
    if (lower_version($previous_version, '5.2a.1')) {
        if ($Conf::Conf{'db_type'} eq 'mysql') {
            my %check = (
                'subscribed_subscriber' => 'subscriber_table',
                'included_subscriber'   => 'subscriber_table',
                'subscribed_admin'      => 'admin_table',
                'included_admin'        => 'admin_table'
            );

            foreach my $field (keys %check) {
                my $statement;
                my $sth;

                my $sdm = Sympa::DatabaseManager->instance;
                unless (
                    $sdm
                    and $sth = $sdm->do_query(
                        q{SELECT max(%s) FROM %s},
                        $field, $check{$field}
                    )
                ) {
                    $log->syslog('err', 'Unable to prepare SQL statement');
                    return undef;
                }

                my $max = $sth->fetchrow();
                $sth->finish();

                ## '0' has been mapped to 1 and '1' to 2
                ## Restore correct field value
                if ($max > 1) {
                    ## 1 to 0
                    $log->syslog('notice',
                        'Fixing DB field %s; turning 1 to 0...', $field);
                    my $rows;
                    $sth =
                        $sdm->do_query(q{UPDATE %s SET %s = %d WHERE %s = %d},
                        $check{$field}, $field, 0, $field, 1);
                    unless ($sth) {
                        $log->syslog('err',
                            'Unable to execute SQL statement');
                        return undef;
                    }
                    $rows = $sth->rows;
                    $log->syslog('notice', 'Updated %d rows', $rows);

                    ## 2 to 1
                    $log->syslog('notice',
                        'Fixing DB field %s; turning 2 to 1...', $field);

                    $sth =
                        $sdm->do_query(q{UPDATE %s SET %s = %d WHERE %s = %d},
                        $check{$field}, $field, 1, $field, 2);
                    unless ($sth) {
                        $log->syslog('err',
                            'Unable to execute SQL statement');
                        return undef;
                    }
                    $rows = $sth->rows;
                    $log->syslog('notice', 'Updated %d rows', $rows);
                }

                ## Set 'subscribed' data field to '1' is none of 'subscribed'
                ## and 'included' is set
                $log->syslog('notice',
                    'Updating subscribed field of the subscriber table...');
                my $rows;
                $sth = $sdm->do_query(
                    q{UPDATE subscriber_table
                      SET subscribed_subscriber = 1
                      WHERE (included_subscriber IS NULL OR
                             included_subscriber <> 1) AND
                            (subscribed_subscriber IS NULL OR
                             subscribed_subscriber <> 1)}
                );
                unless ($sth) {
                    $log->syslog('err', 'Unable to execute SQL statement');
                    return undef;
                }
                $rows = $sth->rows;
                $log->syslog('notice', '%d rows have been updated', $rows);
            }
        }
    }

    ## Rename bounce sub-directories
    if (lower_version($previous_version, '5.2a.1')) {

        $log->syslog('notice',
            'Renaming bounce sub-directories adding list domain...');

        my $root_dir =
            Conf::get_robot_conf($Conf::Conf{'domain'}, 'bounce_path');
        my $dh;
        unless (opendir $dh, $root_dir) {
            $log->syslog('err', 'Unable to open %s: %m', $root_dir);
            return undef;
        }

        foreach my $dir (sort readdir $dh) {
            ## Skip files and entries starting with '.'
            next
                if (($dir =~ /^\./o) || (!-d $root_dir . '/' . $dir));

            ## Directory already include the list domain
            next
                if ($dir =~ /\@/);

            my $listname = $dir;
            my $list     = Sympa::List->new($listname);
            unless (defined $list) {
                $log->syslog('notice', 'Skipping unknown list %s', $listname);
                next;
            }

            my $old_path = $root_dir . '/' . $listname;
            my $new_path =
                $root_dir . '/' . $listname . '@' . $list->{'domain'};

            if (-d $new_path) {
                $log->syslog('err',
                    'Could not rename %s to %s; directory already exists',
                    $old_path, $new_path);
                next;
            } else {
                unless (rename $old_path, $new_path) {
                    $log->syslog('err', 'Failed to rename %s to %s: %m',
                        $old_path, $new_path);
                    next;
                }
                $log->syslog('notice', "Renamed %s to %s",
                    $old_path, $new_path);
            }
        }
        closedir $dh;
    }

    # Update lists config using 'include_sympa_list'
    if (lower_version($previous_version, '5.2a.1')) {
        $log->syslog('notice',
            'Update lists config using include_sympa_list parameter...');

        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            my @include_lists =
                @{$list->{'admin'}{'include_sympa_list'} || []};
            my $changed = 0;
            foreach my $incl (@include_lists) {
                # Search for the list if robot is not specified.
                my $incl_list =
                    Sympa::List->new($incl->{listname}, $list->{'domain'});

                if (    $incl_list
                    and $incl_list->{'domain'} ne $list->{'domain'}) {
                    $log->syslog('notice',
                        'Update config file of list %s, including list %s',
                        $list->get_id, $incl_list->get_id);
                    $incl->{listname} = $incl_list->get_id;
                    $changed = 1;
                }
            }
            if ($changed) {
                $list->{'admin'}{'include_sympa_list'} = [@include_lists];
                $list->save_config(Sympa::get_address($list, 'listmaster'));
            }
        }
    }

    ## New mhonarc ressource file with utf-8 recoding
    if (lower_version($previous_version, '5.3a.6')) {

        $log->syslog('notice',
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
                $log->syslog(
                    'notice',
                    "Custom %s file has been backed up as %s",
                    $etc_dir . '/mhonarc-ressources.tt2',
                    $new_filename
                );
                Sympa::send_notify_to_listmaster('*', 'file_removed',
                    [$etc_dir . '/mhonarc-ressources.tt2', $new_filename]);
            }
        }

        $log->syslog('notice', 'Rebuilding web archives...');
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            # FIXME: next line always success
            next
                unless defined $list->{'admin'}{'web_archive'}
                or defined $list->{'admin'}{'archive'};

            my $arc_message = Sympa::Message->new(
                sprintf("\nrebuildarc %s *\n\n", $list->{'name'}),
                context => $list->{'domain'},
                sender  => sprintf('listmaster@%s', $list->{'domain'}),
                date    => time
            );
            unless (Sympa::Spool::Archive->new->store($arc_message)) {
                $log->syslog('err', 'Cannot rebuild web archive of %s',
                    $list);
                next;
            }
        }

    }

    ## Changed shared documents name encoding
    ## They are Q-encoded therefore easier to store on any filesystem with any
    ## encoding
    if (lower_version($previous_version, '5.3a.8')) {
        $log->syslog('notice', 'Q-Encoding web documents filenames...');
        Sympa::CLI->run({}, 'upgrade', 'shared', '*');
    }

    ## We now support UTF-8 only for custom templates, config files, headers
    ## and footers, info files
    ## + web_tt2, scenari, create_list_templatee, families
    if (lower_version($previous_version, '5.3b.3')) {
        $log->syslog('notice', 'Encoding all custom files to UTF-8...');

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
        my $all_lists = Sympa::List::get_lists('*');
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
            my $dh;
            unless (opendir $dh, $d) {
                next;
            }

            if ($d =~ /(mail_tt2|web_tt2)$/) {
                foreach
                    my $subdir (grep {/^[a-z]{2}(_[A-Z]{2})?$/} readdir $dh) {
                    if (-d "$d/$subdir") {
                        push @directories, ["$d/$subdir", $subdir];
                    }
                }
                closedir $dh;

            } elsif ($d =~ /(create_list_templates|families)$/) {
                foreach my $subdir (grep {/^\w+$/} readdir $dh) {
                    if (-d "$d/$subdir") {
                        push @directories,
                            ["$d/$subdir", $Conf::Conf{'lang'}];
                    }
                }
                closedir $dh;
            }
        }

        foreach my $pair (@directories) {
            my ($d, $lang) = @$pair;
            my $dh;
            unless (opendir $dh, $d) {
                next;
            }
            foreach my $file (readdir $dh) {
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
            closedir $dh;
        }

        ## Do the encoding modifications
        ## Previous versions of files are backed up with the date extension
        my $total = to_utf8(\@files);
        $log->syslog('notice', '%d files have been modified', $total);
    }

    ## giving up subscribers flat files ; moving subscribers to the DB
    ## Also giving up old 'database' mode
    if (lower_version($previous_version, '5.4a.1')) {

        $log->syslog('notice',
            'Looking for lists with user_data_source parameter set to file or database...'
        );

        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {

            if ($list->{'admin'}{'user_data_source'} eq 'file') {

                $log->syslog(
                    'notice',
                    'List %s; changing user_data_source from file to include2...',
                    $list->{'name'}
                );

                # Load <list dir>/subscribers to the DB
                if (-e $list->{'dir'} . '/subscribers'
                    and rename $list->{'dir'} . '/subscribers',
                    $list->{'dir'} . '/member.dump'
                ) {
                    $list->restore_users('member');
                    #$log->syslog('notice',
                    #    '%d subscribers have been loaded into the database',
                    #    $total);
                }

                $list->{'admin'}{'user_data_source'} = 'include2';

                unless ($list->save_config('automatic')) {
                    $log->syslog('err',
                        'Failed to save config file for list %s', $list);
                }
            } elsif ($list->{'admin'}{'user_data_source'} eq 'database') {

                $log->syslog(
                    'notice',
                    'List %s; changing user_data_source from database to include2...',
                    $list->{'name'}
                );

                my $sdm = Sympa::DatabaseManager->instance;
                unless (
                    $sdm and $sdm->do_prepared_query(
                        q{UPDATE subscriber_table
                          SET subscribed_subscriber = 1
                          WHERE list_subscriber = ? AND robot_subscriber = ?},
                        $list->{'name'}, $list->{'domain'}
                    )
                ) {
                    $log->syslog('err',
                        'Failed to update subscribed DB field');
                }

                $list->{'admin'}{'user_data_source'} = 'include2';

                unless ($list->save_config('automatic')) {
                    $log->syslog('err',
                        'Failed to save config file for list %s',
                        $list->{'name'});
                }
            }
        }
    }

    if (lower_version($previous_version, '5.5a.1')) {
        # Remove OTHER/ subdirectories in bounces
        $log->syslog('notice', "Removing obsolete OTHER/ bounce directories");
        if (opendir my $dh, $Conf::Conf{'bounce_path'}) {
            foreach my $subdir (sort grep (!/^\.+$/, readdir $dh)) {
                my $other_dir =
                    $Conf::Conf{'bounce_path'} . '/' . $subdir . '/OTHER';
                if (-d $other_dir) {
                    Sympa::Tools::File::remove_dir($other_dir);
                    $log->syslog('notice', 'Directory %s removed',
                        $other_dir);
                }
            }
            closedir $dh;
        } else {
            $log->syslog(
                'err',
                'Failed to open directory %s: %m',
                $Conf::Conf{'bounce_path'}
            );
        }
    }

    if (lower_version($previous_version, '6.1b.5')) {
        ## Encoding of shared documents was not consistent with recent
        ## versions of MIME::Encode
        ## MIME::EncWords::encode_mimewords() used to encode characters -!*+/
        ## Now these characters are preserved, according to RFC 2047 section 5
        ## We change encoding of shared documents according to new algorithm
        $log->syslog('notice',
            'Fixing Q-encoding of web document filenames...');
        Sympa::CLI->run({fix_qencode => 1}, 'upgrade', 'shared', '*');
    }
    if (lower_version($previous_version, '6.1.11')) {
        ## Exclusion table was not robot-enabled.
        $log->syslog('notice', 'Fixing robot column of exclusion table');
        my $sth;
        my $sdm = Sympa::DatabaseManager->instance;
        unless (
            $sdm and $sth = $sdm->do_query(
                q{SELECT *
                  FROM exclusion_table
                  WHERE robot_exclusion IS NULL OR robot_exclusion = ''}
            )
        ) {
            $log->syslog('err',
                'Unable to gather information from the exclusions table');
        }
        my $rows = $sth->fetchall_arrayref(
            {list_exclusion => 1, user_exclusion => 1});
        $sth->finish;

        my @robots = Sympa::List::get_robots();
        foreach my $data (@{$rows || []}) {
            # Guessing right robot for each exclusion.
            my @valid_robot_candidates;
            foreach my $robot (@robots) {
                next
                    unless Sympa::List->new($data->{'list_exclusion'},
                    $robot, {just_try => 1});
                push @valid_robot_candidates, $robot;
            }
            unless (@valid_robot_candidates) {
                unless (
                    $sdm->do_prepared_query(
                        q{DELETE FROM exclusion_table
                          WHERE (robot_exclusion IS NULL OR
                                 robot_exclusion = '') AND
                                list_exclusion = ? AND user_exclusion = ?},
                        $data->{list_exclusion}, $data->{user_exclusion}
                    )
                ) {
                    $log->syslog(
                        'err',
                        'Unable to delete entry (%s, %s) in exclusions table',
                        $data->{'list_exclusion'},
                        $data->{'user_exclusion'}
                    );
                }
            } elsif (1 == scalar @valid_robot_candidates) {
                my $valid_robot = $valid_robot_candidates[0];
                unless (
                    $sdm->do_prepared_query(
                        q{UPDATE exclusion_table
                          SET robot_exclusion = ?
                          WHERE (robot_exclusion IS NULL OR
                                 robot_exclusion = '') AND
                                list_exclusion = ? AND user_exclusion = ?},
                        $valid_robot,
                        $data->{'list_exclusion'}, $data->{'user_exclusion'}
                    )
                ) {
                    $log->syslog(
                        'err',
                        'Unable to update entry (%s, %s) in exclusions table (trying to add robot %s)',
                        $data->{'list_exclusion'},
                        $data->{'user_exclusion'},
                        $valid_robot
                    );
                }
            } else {
                $log->syslog(
                    'err',
                    'Exclusion robot could not be guessed for user "%s" in list "%s". Either this user is no longer subscribed to the list or the list appears in more than one robot (or the query to the database failed). Here is the list of robots in which this list name appears: "%s"',
                    $data->{'user_exclusion'},
                    $data->{'list_exclusion'},
                    join(', ', @valid_robot_candidates)
                );
            }
        }
        ## Caching all lists config subset to database
        $log->syslog('notice', 'Caching all list config to database...');
        Sympa::List::_flush_list_db();
        my $all_lists = Sympa::List::get_lists('*', 'reload_config' => 1);
        foreach my $list (@$all_lists) {
            $list->_update_list_db;
        }
        $log->syslog('notice', '...done');
    }

    ## We have obsoleted wwsympa.conf.  It would be migrated to sympa.conf.
    if (lower_version($previous_version, '6.2b.1')) {
        $log->syslog('notice', 'Migrating wwsympa.conf...');

        my $sympa_conf   = Conf::get_sympa_conf();
        my $wwsympa_conf = Conf::get_wwsympa_conf();
        my $fh;
        my %migrated = ();
        my @newconf  = ();
        my ($date, $human_date);

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
            'html_editor_file'           => 'NO',    # 6.2a
            'html_editor_init'           => 'NO',
            'ldap_force_canonical_email' => 'NO',
            'log_facility'               => 'yes',
            'mhonarc'                    => 'yes',
            'password_case'              => 'NO',
            'review_page_size'           => 'yes',
            'title'                      => 'NO',
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
            'use_fast_cgi'         => 'No longer used',   # 6.2.25b deprecated
            'htmlarea_url'         => 'No longer used',   # 6.2.36 deprecated
        );

        ## Set language of new file content
        $language->push_lang($Conf::Conf{'lang'});
        $date       = time;
        $human_date = $language->gettext_strftime('%d %b %Y at %H:%M:%S',
            localtime $date);

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
            open $fh, '<', $sympa_conf or die $ERRNO;
            @newconf = <$fh>;
            close $fh;
            $newconf[$#newconf] .= "\n" unless $newconf[$#newconf] =~ /\n\z/;

            push @newconf,
                  "\n"
                . ('#' x 76) . "\n" . '#### '
                . $language->gettext("Migration from wwsympa.conf") . "\n"
                . '#### '
                . $human_date . "\n"
                . ('#' x 76) . "\n\n";

            foreach my $type (qw(duplicate add obsolete unknown)) {
                my %newconf = %{$migrated{$type} || {}};
                next unless scalar keys %newconf;

                push @newconf,
                    Sympa::Tools::Text::wrap_text(
                    $language->gettext(
                        "Migrated Parameters\nFollowing parameters were migrated from wwsympa.conf."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'add';
                push @newconf,
                    Sympa::Tools::Text::wrap_text(
                    $language->gettext(
                        "Overrididing Parameters\nFollowing parameters existed both in sympa.conf and  wwsympa.conf.  Previous release of Sympa used those in wwsympa.conf.  Comment-out ones you wish to be disabled."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'override';
                push @newconf,
                    Sympa::Tools::Text::wrap_text(
                    $language->gettext(
                        "Duplicate of sympa.conf\nThese parameters were found in both sympa.conf and wwsympa.conf.  Previous release of Sympa used those in sympa.conf.  Uncomment ones you wish to be enabled."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'duplicate';
                push @newconf,
                    Sympa::Tools::Text::wrap_text(
                    $language->gettext(
                        "Old Parameters\nThese parameters are no longer used."
                    ),
                    '#### ', '#### '
                    )
                    . "\n"
                    if $type eq 'obsolete';
                push @newconf,
                    Sympa::Tools::Text::wrap_text(
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
                        Sympa::Tools::Text::wrap_text(
                        $language->gettext($param->{'gettext_id'}),
                        '## ', '## ')
                        if $param->{'gettext_id'};
                    push @newconf,
                        Sympa::Tools::Text::wrap_text(
                        $language->gettext($param->{'gettext_comment'}),
                        '## ', '## ')
                        if $param->{'gettext_comment'};
                    if (defined $v
                        and ($type eq 'add' or $type eq 'override')) {
                        push @newconf,
                            sprintf("%s\t%s\n\n", $param->{'name'}, $v);
                    } else {
                        push @newconf, sprintf("#%s\t\n\n", $param->{'name'});
                    }
                }
            }
        }

        ## Restore language
        $language->pop_lang;

        if (%migrated) {
            warn sprintf 'Unable to rename %s: %s', $sympa_conf, $ERRNO
                unless rename $sympa_conf, "$sympa_conf.$date";
            ## Write new config files
            my $umask = umask 037;
            unless (open $fh, '>', $sympa_conf) {
                umask $umask;
                die sprintf 'Unable to open %s: %s', $sympa_conf, $ERRNO;
            }
            umask $umask;
            chown [getpwnam(Sympa::Constants::USER)]->[2],
                [getgrnam(Sympa::Constants::GROUP)]->[2], $sympa_conf;
            print $fh @newconf;
            close $fh;

            ## Keep old config file
            $log->syslog(
                'notice',
                '%s has been updated.  Previous version has been saved as %s',
                $sympa_conf,
                "$sympa_conf.$date"
            );
        }

        if (-r $wwsympa_conf) {
            ## Keep old config file
            warn sprintf 'Unable to rename %s: %s', $wwsympa_conf, $ERRNO
                unless rename $wwsympa_conf, "$wwsympa_conf.$date";
            $log->syslog(
                'notice',
                '%s will NO LONGER be used.  Previous version has been saved as %s',
                $wwsympa_conf,
                "$wwsympa_conf.$date"
            );
        }
    }

    # 6.2.70: Now HTML view of held messages will be created on demand.
    ## Create HTML view of pending messages
    #if (lower_version($previous_version, '6.2b.1')) {
    #    $log->syslog('notice', 'Creating HTML view of moderation spool...');
    #    my $status =
    #        system(Sympa::Constants::SCRIPTDIR() . '/' . 'mod2html.pl') >> 8;
    #    $log->syslog('err', 'mod2html.pl failed with status %s', $status)
    #        if $status;
    #}

    # Rename files in automatic spool with older format created by
    # sympa-milter 0.6 or earlier: <family_name>.<date>.<rand> to
    # <localpart>@<domainpart>.<date>.<rand>.
    if (lower_version($previous_version, '6.2b.1')) {
        $log->syslog('notice', 'Upgrading automatic spool...');

        my $spooldir = $Conf::Conf{'queueautomatic'};

        my $dh;
        my @qfile;
        unless (opendir $dh, $spooldir) {
            $log->syslog('err', 'Can\'t open dir %s: %m', $spooldir);
        } else {
            @qfile = sort grep {
                        !/,lock/
                    and !/\A(?:\.|T\.|BAD-)/
                    and -f ($spooldir . '/' . $_)
            } readdir $dh;
            closedir $dh;
        }

        my $lock_fh;
        my @performed;
        foreach my $filename (@qfile) {
            $lock_fh =
                Sympa::LockedFile->new($spooldir . '/' . $filename, -1, '+<');
            next unless $lock_fh;

            my $metadata = Sympa::Spool::unmarshal_metadata(
                $spooldir, $filename,
                qr{\A([^\s\@]+)\.(\d+)\.(\d+)\z},
                [qw(list_or_family date rand)]
            );
            next unless $metadata;

            my $msg_string = do { local $RS; <$lock_fh> };
            my $message = Sympa::Message->new($msg_string, %$metadata);
            next unless $message->{rcpt} and $message->{family};

            my $new_filename =
                Sympa::Spool::marshal_metadata($message, '%s.%ld.%d',
                [qw(rcpt date rand)]);
            next unless $new_filename ne $filename;

            if ($lock_fh->rename($spooldir . '/' . $new_filename)) {
                push @performed, $new_filename;
            }
        }

        $log->syslog('info',
            'Upgrade process for spool %s: performed files %s',
            $spooldir, join(', ', @performed))
            if @performed;
    }

    # As of 6.2b.1, several list parameters are renamed or added.
    if (lower_version($previous_version, '6.2b.1')) {
        $log->syslog('notice', 'Upgrading list config...');
        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@$all_lists) {
            $list->{'admin'}{'archive'} = {}
                unless ref $list->{'admin'}{'archive'} eq 'HASH';

            if ($list->{'admin'}{'archive'}{'access'}) {
                $list->{'admin'}{'archive'}{'mail_access'} =
                    {'name' => $list->{'admin'}{'archive'}{'access'}};
                delete $list->{'admin'}{'defaults'}{'archive'};
            }
            delete $list->{'admin'}{'archive'}{'access'};

            if (ref $list->{'admin'}{'web_archive'} eq 'HASH'
                and $list->{'admin'}{'web_archive'}{'access'}) {
                $list->{'admin'}{'process_archive'} = 'on';
                delete $list->{'admin'}{'defaults'}{'process_archive'};
            }
            if (ref $list->{'admin'}{'web_archive'} eq 'HASH') {
                $list->{'admin'}{'archive'}{'web_access'} =
                    $list->{'admin'}{'web_archive'}{'access'}
                    if $list->{'admin'}{'web_archive'}{'access'};
                $list->{'admin'}{'archive'}{'quota'} =
                    $list->{'admin'}{'web_archive'}{'quota'}
                    if $list->{'admin'}{'web_archive'}{'quota'};
                $list->{'admin'}{'archive'}{'max_month'} =
                    $list->{'admin'}{'web_archive'}{'max_month'}
                    if $list->{'admin'}{'web_archive'}{'max_month'};
                delete $list->{'admin'}{'defaults'}{'archive'};
            }
            delete $list->{'admin'}{'web_archive'};

            $list->save_config('automatic');
        }
    }
    if (lower_version($previous_version, '6.2b.1')) {
        $log->syslog('notice',
            'Setting web interface colors to new defaults.');
        fix_colors(Sympa::Constants::CONFIG);

        if (-d "$Conf::Conf{'etc'}/web_tt2") {
            $log->syslog('info', 'Saving main web_tt2 directory');
            save_web_tt2("$Conf::Conf{'etc'}/web_tt2");
        }
        my @robots = Sympa::List::get_robots();
        foreach my $robot (@robots) {
            if (-f "$Conf::Conf{'etc'}/$robot/robot.conf") {
                $log->syslog('info', 'Fixing colors for %s robot', $robot);
                fix_colors("$Conf::Conf{'etc'}/$robot/robot.conf");
            }
            if (-d "$Conf::Conf{'etc'}/$robot/web_tt2") {
                $log->syslog('info', 'Saving web_tt2 directory %s robot',
                    $robot);
                save_web_tt2("$Conf::Conf{'etc'}/$robot/web_tt2");
            }

            # CSS would be regenerated...
            my $dir = $Conf::Conf{'css_path'} . '/' . $robot;
            rename $dir . '/style.css', $dir . '/style.css.' . time
                if -f $dir . '/style.css';
        }
        $log->syslog('notice',
            'Web interface colors defaulted to new values.');
    }

    # notification_table no longer keeps DSN/MDN.
    if (lower_version($previous_version, '6.2b.3')
        and not lower_version($previous_version, '6.2a.7')) {
        $log->syslog('notice', 'Upgrading tracking spool.');
        my $sdm = Sympa::DatabaseManager->instance;
        my $sth;
        unless ($sdm
            and $sth =
            $sdm->do_prepared_query(q{SELECT * FROM notification_table})) {
            $log->syslog('err',
                'Cannot execute SQL query.  Database is inaccessible');
        } else {
            while (my $info = $sth->fetchrow_hashref('NAME_lc')) {
                my $list = Sympa::List->new(
                    $info->{'list_notification'},
                    $info->{'robot_notification'}
                );
                next unless $list;

                my $msg_string = $info->{'message_notification'};
                my $recipient  = $info->{'recipient_notification'};
                if (    defined $msg_string
                    and length $msg_string
                    and $recipient) {
                    $msg_string = MIME::Base64::decode_base64($msg_string);
                    # Note: See also upgrading from versions later than 6.2b.3
                    # to version 6.2.63b.1 in below.
                    # below.
                    my $bounce_path = sprintf '%s/%s_%08s',
                        $list->get_bounce_dir,
                        _escape_chars($recipient),
                        $info->{'pk_notification'};
                    if (open my $fh, '>', $bounce_path) {
                        print $fh $msg_string;
                        close $fh;
                    } else {
                        $log->syslog('err', 'Cannot open file %s: %m',
                            $bounce_path);
                    }
                }
            }
            $sth->finish;
        }
    }

    # Format of digest spool was changed.
    my $digest_separator =
        '------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------';

    if (lower_version($previous_version, '6.2b.5')) {
        $log->syslog('notice', 'Upgrading digest spool.');

        my $dh;
        my @dfile;
        if (opendir $dh, $Conf::Conf{'queuedigest'}) {
            @dfile =
                grep {
                        !/,lock/
                    and !/\A(?:\.|T\.|BAD-)/
                    and !/(?:_unknown|_migrated)\z/
                    and -f ($Conf::Conf{'queuedigest'} . '/' . $_)
                } readdir $dh;
            closedir $dh;
        }
        foreach my $filename (@dfile) {
            my $metadata = Sympa::Spool::unmarshal_metadata(
                $Conf::Conf{'queuedigest'},
                $filename,
                qr{\A([^\s\@]+)(?:\@([\w\.\-]+))?\z},
                [qw(localpart domainpart)]
            );
            unless ($metadata and ref $metadata->{context} eq 'Sympa::List') {
                $log->syslog('err', 'Unknown list %s', $filename);
                rename $Conf::Conf{'queuedigest'} . '/' . $filename,
                    $Conf::Conf{'queuedigest'} . '/' . $filename . '_unknown';
                next;
            }

            rename $Conf::Conf{'queuedigest'} . '/' . $filename,
                $Conf::Conf{'queuedigest'} . '/' . $filename . '_migrated';

            my $spool_digest = Sympa::Spool::Digest->new(%$metadata);
            unless ($spool_digest) {
                rename $Conf::Conf{'queuedigest'} . '/'
                    . $filename
                    . '_migrated',
                    $Conf::Conf{'queuedigest'} . '/' . $filename;
                next;
            }

            local $RS = "\n\n" . $digest_separator . "\n\n";
            open my $fh, '<',
                $Conf::Conf{'queuedigest'} . '/' . $filename . '_migrated'
                or next;
            my $i = 0;
            while (my $text = <$fh>) {
                next unless $i++;    # Skip introduction part.

                $text =~ s{$RS\z}{};
                $text =~ s/\r?\z/\n/ unless $text =~ /\n\z/;

                my $message = Sympa::Message->new($text, %$metadata);
                next unless $message;

                $message->{date} = time;
                $spool_digest->store($message);
            }
            close $fh;
        }
    }

    if (lower_version($previous_version, '6.2b.8')
        and not lower_version($previous_version, '6.2a.0')) {
        $log->syslog('notice', 'Upgrading stat_counter_table.');
        my $sdm = Sympa::DatabaseManager->instance;

        # Clear unusable information.
        if ($sdm) {
            $sdm->do_prepared_query(q{DELETE FROM stat_table});
            $sdm->do_prepared_query(q{DELETE FROM stat_counter_table});
        }

        # As the field id_counter is no longer used but it has NOT NULL
        # constraint, it should be deleted.
        if ($sdm and $sdm->can('drop_field')) {
            $sdm->delete_field(
                {table => 'stat_counter_table', field => 'id_counter'});
        } else {
            $log->syslog('err',
                'Can\'t delete id_counter field in stat_counter_table.  You must delete it manually.'
            );
        }

        # number_messages_subscriber field should not be NULL.
        unless (
            $sdm and $sdm->do_prepared_query(
                q{UPDATE subscriber_table
                  SET number_messages_subscriber = 0
                  WHERE number_messages_subscriber IS NULL}
            )
        ) {
            $log->syslog('err',
                'Can\'t update number_messages_subscriber field of subscriber_table.  You must update it manually.'
            );
        }
    }

    if (lower_version($previous_version, '6.2b.9')
        and not lower_version($previous_version, '6.2a.0')) {
        $log->syslog('notice', 'Upgrading stat_table.');
        my $sdm = Sympa::DatabaseManager->instance;

        # As the field id_stat is no longer used but it has NOT NULL
        # constraint, it should be deleted.
        if ($sdm and $sdm->can('drop_field')) {
            $sdm->delete_field({table => 'stat_table', field => 'id_stat'});
        } else {
            $log->syslog('err',
                'Can\'t delete id_stat field in stat_table.  You must delete it manually.'
            );
        }
    }

    # arrival_date_epoch_notification field was renamed to
    # arrival_epoch_notification.
    if (lower_version($previous_version, '6.2b.10')
        and not lower_version($previous_version, '6.2b.3')) {
        $log->syslog('notice', 'Upgrading notification_table.');
        my $sdm = Sympa::DatabaseManager->instance;

        $sdm
            and $sdm->do_prepared_query(
            q{UPDATE notification_table
              SET arrival_epoch_notification = arrival_date_epoch_notification
              WHERE arrival_date_epoch_notification IS NOT NULL}
            );
    }

    # As of 6.2, format of archive spool was changed.
    if (lower_version($previous_version, '6.2b.10')) {
        $log->syslog('notice', 'Upgrading archive spool.');
        my $spool = Sympa::Spool::Archive->new;

        mkdir($spool->{directory} . '/migrated/')
            unless -d $spool->{directory} . '/migrated/';

        my $dh;
        unless (opendir $dh, $spool->{directory}) {
            $log->syslog('err', 'Can\'t open directory %s: %m',
                $spool->{directory});
            return undef;
        }
        my @files =
            sort grep {/(^[^\.]|^\.(remove|rebuild)\.(.*))/} readdir $dh;
        closedir $dh;

        foreach my $file (@files) {
            next unless -f $spool->{directory} . '/' . $file;
            my $lock_fh =
                Sympa::LockedFile->new($spool->{directory} . '/' . $file,
                5, '+<');
            next unless $lock_fh;

            my ($metadata, $message);
            if ($metadata = Sympa::Spool::unmarshal_metadata(
                    $spool->{directory},
                    $file,
                    qr/\A\.remove\.([^\s\@]+)(?:\@([\w\.\-]+))?\.(\d\d\d\d\-\d\d)\.(\d+)\z/,
                    [qw(localpart domainpart arc date)]
                )
            ) {
                my $arc  = $metadata->{arc};
                my $date = $metadata->{date};
                my $list = $metadata->{context};
                next unless ref $list eq 'Sympa::List';

                my $old_string = do { local $RS; <$lock_fh> };
                foreach my $line (split /\n+/, $old_string) {
                    next unless $line =~ /\S/;
                    $line =~ s/\s*$//;
                    my ($msgid, $sender) = split /\|\|/, $line;
                    next unless $msgid and $sender;

                    my $msg_string = sprintf "\n\nremove_arc %s %s %s\n",
                        $list->{'name'}, $arc, $msgid;
                    my $message = Sympa::Message->new(
                        $msg_string,
                        context => $list->{'domain'},
                        sender  => $sender,
                        date    => $date
                    );
                    if ($message) {
                        $spool->store($message);
                    }
                }
                $lock_fh->rename(
                    $spool->{directory} . '/migrated/' . $lock_fh->basename);
            } elsif (
                $metadata = Sympa::Spool::unmarshal_metadata(
                    $spool->{directory},
                    $file,
                    qr/\A\.rebuild\.([^\s\@]+)(?:\@([\w\.\-]+))?\.(\d{4}-\d{2})\z/,
                    [qw(localpart domainpart arc)]
                )
                or $metadata = Sympa::Spool::unmarshal_metadata(
                    $spool->{directory}, $file,
                    qr/\A\.rebuild\.([^\s\@]+)(?:\@([\w\.\-]+))?\z/,
                    [qw(localpart domainpart)]
                )
            ) {
                my $list = $metadata->{context};
                next unless ref $list eq 'Sympa::List';

                my $date = Sympa::Tools::File::get_mtime(
                    $spool->{directory} . '/' . $file);
                my $arc = $metadata->{arc} || '*';

                my $msg_string = sprintf "\n\nrebuildarc %s %s\n",
                    $list->{'name'}, $arc;
                my $message = Sympa::Message->new(
                    $msg_string,
                    context => $list->{'domain'},
                    sender  => sprintf('listmaster@%s', $list->{'domain'}),
                    date    => $date
                );
                if ($message) {
                    $spool->store($message);
                }

                $lock_fh->rename(
                    $spool->{directory} . '/migrated/' . $lock_fh->basename);
            } else {
                if ($file =~
                    /^(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(.*)$/)
                {
                    my @localtime = ($1, $2, $3, $4, $5, $6);
                    my $list_id = $7;

                    $localtime[1]--;
                    my $date = Time::Local::timelocal(reverse @localtime);
                    $file = sprintf '%s.%ld.0', $list_id, $date;
                }

                if ($metadata = Sympa::Spool::unmarshal_metadata(
                        $spool->{directory},
                        $file,
                        qr/\A([^\s\@]+)\@([\w\.\-]+)\.(\d+)\.(\d+)\.(\d+)\z/,
                        [qw(localpart domainpart date)]
                    )
                    or $metadata = Sympa::Spool::unmarshal_metadata(
                        $spool->{directory},
                        $file,
                        qr/\A([^\s\@]+)\@([\w\.\-]+)\.(\d+)\.(\d+)\z/,
                        [qw(localpart domainpart date)]
                    )
                ) {
                    my $list = $metadata->{context};
                    next unless ref $list eq 'Sympa::List';

                    my $date = $metadata->{date};

                    my $msg_string = do { local $RS; <$lock_fh> };
                    my $message = Sympa::Message->new(
                        $msg_string,
                        context => $list,
                        date    => $date
                    );
                    if ($message) {
                        $spool->store($message);
                    }
                    $lock_fh->rename($spool->{directory}
                            . '/migrated/'
                            . $lock_fh->basename);
                } else {
                    next;
                }
            }
        }    # End foreach my $file
    }

    # Prior to 5.2b, domain parts in message files of auth & mod spool were
    # missing.  As of 6.2.8, they became mandatory.
    if (lower_version($previous_version, '6.2.8')) {
        $log->syslog('notice', 'Upgrading auth & mod spool.');

        foreach my $spool_dir (
            ($Conf::Conf{'queueauth'}, $Conf::Conf{'queuemod'})) {
            my $dh;
            next unless opendir $dh, $spool_dir;

            foreach my $filename (readdir $dh) {
                next if $filename =~ /\A(?:[.]|T[.]|BAD-)/;
                next unless -f $spool_dir . '/' . $filename;

                next unless $filename =~ /\A([^\@]+)_(\w+)([.]distribute)?\z/;
                my ($name, $authkey, $validated) = ($1, $2, $3);
                $validated ||= '';

                rename sprintf('%s/%s', $spool_dir, $filename),
                    sprintf('%s/%s@%s_%s%s',
                    $spool_dir, $name, $Conf::Conf{'domain'}, $authkey,
                    $validated);
            }
            closedir $dh;
        }

        # 6.2.70: Now HTML view of held messages will be created on demand.
        #$log->syslog('notice', 'Creating HTML view of moderation spool...');
        #my $status =
        #    system(Sympa::Constants::SCRIPTDIR() . '/' . 'mod2html.pl') >> 8;
        #$log->syslog('err', 'mod2html.pl failed with status %s', $status)
        #    if $status;
    }

    # Upgrading moderation spool on subscription.
    if (lower_version($previous_version, '6.2.10')) {
        $log->syslog('notice', 'Upgrading subscribe spool.');

        my $spool_dir = $Conf::Conf{'queuesubscribe'};
        if (opendir my $dh, $spool_dir) {
            foreach my $filename (readdir $dh) {
                next if $filename =~ /\A(?:[.]|T[.]|BAD-)/;
                next unless -f $spool_dir . '/' . $filename;

                my $metadata = Sympa::Spool::unmarshal_metadata(
                    $spool_dir, $filename,
                    qr{([^\s\@]+)(?:\@([\w\.\-]+))?[.](\d+)[.](\d+)\z},
                    [qw(localpart domainpart date rand)]
                );
                next unless $metadata;

                my $lock_fh =
                    Sympa::LockedFile->new($spool_dir . '/' . $filename,
                    -1, '+<');
                next unless $lock_fh;

                my $req_string = do { local $RS; <$lock_fh> };

                # First line of the file contains the user email address +
                # their name.
                my ($email, $gecos);
                if ($req_string =~ s/\A((\S+|\".*\")\@\S+)(?:\t(.*))?\n+//) {
                    ($email, $gecos) = ($1, $2);
                } else {
                    next;
                }
                # Following lines may contain custom attributes in XML format.
                my $custom_attribute =
                    Sympa::Tools::Data::decode_custom_attribute($req_string);
                my $request = Sympa::Request->new_from_tuples(
                    email            => $email,
                    gecos            => $gecos,
                    custom_attribute => $custom_attribute,
                    action           => 'add',
                    %$metadata
                );
                next unless $request;

                my $spool_req = Sympa::Spool::Auth->new;
                if ($spool_req->store($request)) {
                    $lock_fh->unlink;
                } else {
                    $lock_fh->close;
                }
            }
            closedir $dh;
        }
    }

    if (lower_version($previous_version, '6.2.10')
        and not lower_version($previous_version, '5.3a.8')) {
        $log->syslog('notice', 'Upgrading logs_table.');
        my $sdm = Sympa::DatabaseManager->instance;

        # As the field id_logs is no longer used but it has NOT NULL
        # constraint, it should be deleted.
        if ($sdm and $sdm->can('drop_field')) {
            $sdm->delete_field({table => 'logs_table', field => 'id_logs'});
        } else {
            $log->syslog('err',
                'Can\'t delete id_logs field in logs_table.  You must delete it manually.'
            );
        }
        # Newly added subsecond field should be 0 by default.
        $sdm->do_query(
            q{UPDATE logs_table
              SET usec_logs = 0
              WHERE usec_logs IS NULL}
        );
    }

    # Database field type datetime was deprecated.  Unix time will be used.
    if (lower_version($previous_version, '6.2.25b.3')) {
        my $sdm = Sympa::DatabaseManager->instance;

        $log->syslog('notice', 'Upgrading subscriber_table.');
        # date_subscriber & update_subscriber (datetime) was obsoleted.
        # Use date_epoch_subscriber & update_epoch_subscriber (int).
        $sdm->do_prepared_query(
            sprintf(
                q{UPDATE subscriber_table
                  SET date_epoch_subscriber = %s
                  WHERE date_subscriber IS NOT NULL AND
                        date_epoch_subscriber IS NULL},
                _get_canonical_read_date($sdm, 'date_subscriber')
            )
        );
        $sdm->do_prepared_query(
            sprintf(
                q{UPDATE subscriber_table
                  SET update_epoch_subscriber = %s
                  WHERE update_subscriber IS NOT NULL AND
                        update_epoch_subscriber IS NULL},
                _get_canonical_read_date($sdm, 'update_subscriber')
            )
        );
        $log->syslog('notice', 'Upgrading admin_table.');
        # date_admin & update_admin (datetime) was obsoleted.
        # Use date_epoch_admin & update_epoch_admin (int).
        $sdm->do_prepared_query(
            sprintf(
                q{UPDATE admin_table
                  SET date_epoch_admin = %s
                  WHERE date_admin IS NOT NULL AND
                        date_epoch_admin IS NULL},
                _get_canonical_read_date($sdm, 'date_admin')
            )
        );
        $sdm->do_prepared_query(
            sprintf(
                q{UPDATE admin_table
                  SET update_epoch_admin = %s
                  WHERE update_admin IS NOT NULL AND
                        update_epoch_admin IS NULL},
                _get_canonical_read_date($sdm, 'update_admin')
            )
        );
    }

    # Upgrade dump files for list users.
    if (lower_version($previous_version, '6.2.33b.1')) {
        $log->syslog('notice', 'Upgrading user dumps of closed lists.');
        # Upgrading user dumps of closed lists.
        my $lists =
            Sympa::List::get_lists('*',
            filter => [status => 'closed|family_closed']);
        foreach my $list (@{$lists || []}) {
            my $dir = $list->{'dir'};

            if (-e $dir . '/subscribers.closed.dump') {
                unlink $dir . '/member.dump.old';
                rename $dir . '/member.dump', $dir . '/member.dump.old';
                rename $dir . '/subscribers.closed.dump',
                    $dir . '/member.dump';
            }
        }
    }

    # GH Issue #240: PostgreSQL: Unable to edit owners/subscribers.
    if (lower_version($previous_version, '6.2.30')) {
        my $sdm = Sympa::DatabaseManager->instance;

        # As the field date_admin and date_subscriber are no longer used but
        # they have NOT NULL constraint, they should be deleted.
        if ($sdm and $sdm->can('delete_field')) {
            $log->syslog('notice', 'Upgrading admin_table');
            $sdm->delete_field(
                {table => 'admin_table', field => 'date_admin'});
            $log->syslog('notice', 'Upgrading subscriber_table');
            $sdm->delete_field(
                {table => 'subscriber_table', field => 'date_subscriber'});
        } else {
            $log->syslog('err',
                'Can\'t delete date_admin field in admin_table and date_subscriber field in subscriber_table.  You must delete them manually.'
            );
        }
    }

    # GH #330: wwsympa_url would be optional. http://domain/sympa is
    # assigned to robot.conf for compatibility.
    if (lower_version($previous_version, '6.2.33b.2')) {
        my @robot_ids = Sympa::List::get_robots();
        foreach my $robot_id (@robot_ids) {
            next if $robot_id eq $Conf::Conf{'domain'};    # Primary domain

            my $config_file = sprintf '%s/%s/robot.conf', $Conf::Conf{'etc'},
                $robot_id;

            my $ifh;
            next unless open $ifh, '<', $config_file;
            my ($parameter) = grep {/\Awwsympa_url\s+\S+/} <$ifh>;
            close $ifh;
            next if $parameter;

            $log->syslog('info', 'Updating wwsympa_url for %s', $robot_id);
            my $ofh;
            unless (open $ofh, '>>', $config_file) {
                $log->syslog('err', 'Cannot write to %s: %m', $config_file);
                next;
            }
            printf $ofh "\n\n# Added by upgrade from %s\n", $previous_version;
            printf $ofh "wwsympa_url\thttp://%s/sympa\n",   $robot_id;
            close $ofh;
        }
    }

    # Task files are moved.
    if (lower_version($previous_version, '6.2.37b.2')) {
        my $sitedir = $Conf::Conf{'etc'};
        my @robotdirs =
            map { $Conf::Conf{'etc'} . '/' . $_ } Sympa::List::get_robots();
        my @listdirs =
            map { $_->{'dir'} } @{Sympa::List::get_lists('*') || []};

        my $model_dir = $sitedir . '/global_task_models';
        if (-e $model_dir) {
            my $task_dir = $sitedir . '/tasks';
            unless (Sympa::Tools::File::copy_dir($model_dir, $task_dir)) {
                $log->syslog('err', 'Unable to copy %s to %s',
                    $model_dir, $task_dir);
            }
        }
        foreach my $dir (($sitedir, @robotdirs, @listdirs)) {
            my $model_dir = $dir . '/list_task_models';
            if (-e $model_dir) {
                my $task_dir = $dir . '/tasks';
                unless (Sympa::Tools::File::copy_dir($model_dir, $task_dir)) {
                    $log->syslog('err', 'Unable to copy %s to %s',
                        $model_dir, $task_dir);
                }
            }
        }
    }

    # Default list scenario names will be specified in robot.conf/sympa.conf
    # instead of creating symbolic links named "*.default".
    if (lower_version($previous_version, '6.2.41b.1')) {
        my @scenarios = qw(visibility
            send info subscribe add unsubscribe del invite remind review
            d_read d_edit
            archive_web_access archive_mail_access
            tracking);

        my @dirs = ($Conf::Conf{'etc'});
        push @dirs,
            map { $Conf::Conf{'etc'} . '/' . $_ } Sympa::List::get_robots();
        foreach my $dir (@dirs) {
            my %scenario_names;

            next unless $dir eq $Conf::Conf{'etc'} or -e $dir . '/robot.conf';
            next unless -d $dir . '/scenari';

            foreach my $scenario (@scenarios) {
                my $path = $dir . '/scenari/' . $scenario . '.default';
                next unless -e $path;

                my $name = '';
                if (-l $path) {
                    $path = Cwd::abs_path($path);
                    next unless $path and -e $path;

                    if ($path =~ m{/$scenario\.([-\w]+)\z}) {
                        $name = $1;
                    }
                }
                $scenario_names{$scenario} = $name;
            }
            next unless %scenario_names;

            my $ofh;
            if ($dir eq $Conf::Conf{'etc'}) {
                open $ofh, '>>', Conf::get_sympa_conf() or next;
            } else {
                open $ofh, '>>', $dir . '/robot.conf' or next;
            }
            print $ofh "\n\n";
            printf $ofh
                "# Following parameters were added during upgrade to %s\n\n",
                $new_version;
            foreach my $scenario (@scenarios) {
                unless (exists $scenario_names{$scenario}) {
                    next;
                } elsif ($scenario_names{$scenario}) {
                    printf $ofh "%s %s\n", $scenario,
                        $scenario_names{$scenario};
                } else {
                    printf $ofh
                        "#%s (Assign default manually, or distribution default will be used.)\n",
                        $scenario;
                }
            }
            close $ofh;
        }
    }

    if (lower_version($previous_version, '6.2.41b.1')) {
        # The header/footer files were renamed.
        # Site-level files were moved.
        my %file_map = (
            'message.header'        => 'message_header',
            'message.footer'        => 'message_footer',
            'message.global_footer' => 'message_global_footer'
        );

        my $all_lists = Sympa::List::get_lists('*');
        foreach my $list (@{$all_lists || []}) {
            my $dir = $list->{'dir'};
            foreach my $file (keys %file_map) {
                next if $file eq 'message.global_footer';

                my $new_file = $file_map{$file};

                if (-e $dir . '/' . $file and !-e $dir . '/' . $new_file) {
                    File::Copy::copy($dir . '/' . $file,
                        $dir . '/' . $new_file);
                }
                if (-e $dir . '/' . $file . '.mime'
                    and !-e $dir . '/' . $new_file . '.mime') {
                    File::Copy::copy(
                        $dir . '/' . $file . '.mime',
                        $dir . '/' . $new_file . '.mime'
                    );
                }
            }
        }
        my $dir = $Conf::Conf{'etc'};
        foreach my $file (keys %file_map) {
            my $new_file = $file_map{$file};

            if (-e $dir . '/mail_tt2/' . $file) {
                File::Copy::copy($dir . '/mail_tt2/' . $file,
                    $dir . '/' . $new_file);
            }
            if (-e $dir . '/mail_tt2/' . $file . '.mime') {
                File::Copy::copy(
                    $dir . '/mail_tt2/' . $file . '.mime',
                    $dir . '/' . $new_file . '.mime'
                );
            }
        }
    }

    # Clean style sheets with earlier timestamp so that they will be recreated
    # with recent timestamp.
    if (lower_version($previous_version, '6.2.41b.1')
        and not lower_version($previous_version, '6.2.26')) {
        if ($Conf::Conf{'css_path'} and -d $Conf::Conf{'css_path'}) {
            my @robot_ids = Sympa::List::get_robots();
            foreach my $robot_id (@robot_ids) {
                my $dir = $Conf::Conf{'css_path'} . '/' . $robot_id;
                next unless -e $dir . '/style.css';
                unlink $dir . '/style.css';
            }
        }
    }

    # Previously shared repository could not be disabled.
    if (lower_version($previous_version, '6.2.41b.2')) {
        my $human_date = $language->gettext_strftime('%d %b %Y at %H:%M:%S',
            localtime time);

        open my $ofh, '>>', Conf::get_sympa_conf();
        printf $ofh "\n\n# Upgrade from %s to %s\n# %s\nshared_feature on\n",
            $previous_version, $new_version, $human_date;
        close $ofh;
    }

    # included_* and include_sources_* were deprecated and inclusion_*
    # was introduced in subscriber_table and admin_table.
    if (lower_version($previous_version, '6.2.45b.1')) {
        my $sdm = Sympa::DatabaseManager->instance;

        $log->syslog('notice', 'Upgrading subscriber_table and admin_table.');
        foreach my $role (qw(member owner editor)) {
            my ($t, $r) =
                  ($role eq 'member')
                ? ('subscriber', '')
                : ('admin',
                sprintf ' AND role_admin = %s', $sdm->quote($role));
            unless (
                $sdm and $sdm->do_prepared_query(
                    qq{UPDATE ${t}_table
                       SET inclusion_$t = update_epoch_$t
                       WHERE included_$t = 1 AND inclusion_$t IS NULL$r}
                )
            ) {
                $log->syslog('err',
                    'Can\'t update inclusion_%s field for %s in %s_table',
                    $t, $role, $t);
            }
        }
    }

    if (lower_version($previous_version, '6.2.61b.1')) {
        # Variable tags "($tag$% ... %$tag$)" no longer used in
        # mhonarc_rc.tt2 (ex. mhonarc-ressources.tt2) and were replaced with
        # "<% ... %>".
        $log->syslog('notice', 'Converting mhonarc-ressources.tt2...');
        _process_all_files(
            'mhonarc-ressources.tt2',
            sub {
                my $that    = shift;
                my $dir     = shift;
                my $oldfile = shift;
                my $newfile = 'mhonarc_rc.tt2';

                open my $ifh, '<', $dir . '/' . $oldfile
                    or die sprintf '%s: %s', $oldfile, $ERRNO;
                my $text = do { local $RS; <$ifh> };
                close $ifh;

                $text =~ s{[(]\$tag\$%}{<%}g;
                $text =~ s{%\$tag\$[)]}{%>}g;

                open my $ofh, '>', $dir . '/' . $newfile
                    or die sprintf '%s: %s', $newfile, $ERRNO;
                print $ofh $text;
                close $ofh;
            }
        );
        $log->syslog('notice', '...Done. Use new file(s) mhonarc_rc.tt2.');

        # blocklist.txt will be used instead of blacklist.txt
        $log->syslog('notice', 'Rename blacklist.txt to blocklist.txt...');
        _process_all_files(
            'search_filters/blacklist.txt',
            sub {
                my $that    = shift;
                my $dir     = shift;
                my $oldfile = shift;
                my $newfile = 'search_filters/blocklist.txt';

                rename($dir . '/' . $oldfile, $dir . '/' . $newfile)
                    or
                    $log->syslog('err', 'Cannot rename file %s/%s to %s: %m',
                    $dir, $oldfile, $newfile);
            }
        );
        $log->syslog('notice', '...Done.');
    }

    if (lower_version($previous_version, '6.2.63b.1')) {
        $log->syslog('notice', 'Moving bounce information and so on...');
        _process_all_files(
            'config',
            sub {
                my $that = shift;
                my $dir  = shift;
                my $file = shift;

                return unless ref $that eq 'Sympa::List';

                # Note: See also upgrading to version 6.2b.3 in above.
                my $bounce_dir = $that->get_bounce_dir;
                my $dh;
                return unless -d $bounce_dir and opendir $dh, $bounce_dir;

                foreach my $old (readdir $dh) {
                    next if 0 == index $old, '.';

                    next unless $old =~ /\A(.+)(?:_(\w+))?\z/;
                    my ($escaped_email, $envid) = ($1, $2);

                    my $new;
                    if (defined $envid) {
                        $new = sprintf '%s/%s__%08s',
                            Sympa::Tools::Text::encode_filesystem_safe(
                            _unescape_chars($escaped_email)), $envid;
                    } else {
                        $new =
                            Sympa::Tools::Text::encode_filesystem_safe(
                            _unescape_chars($escaped_email));
                    }

                    next if $old eq $new;

                    rename sprintf('%s/%s', $bounce_dir, $old),
                        sprintf('%s/%s', $bounce_dir, $new);

                }
            }
        );

        my $dh;
        if (opendir $dh, $Conf::Conf{'ssl_cert_dir'}) {
            foreach my $old (readdir $dh) {
                next if 0 == index $old, '.';

                my ($escaped_email, $ext) = ($old =~ /\A(.+)(?:(\@\w+)?)\z/);
                my $new =
                    Sympa::Tools::Text::encode_filesystem_safe(
                    _unescape_chars($escaped_email))
                    . ($ext // '');
                next if $old eq $new;

                rename sprintf('%s/%s', $Conf::Conf{'ssl_cert_dir'}, $old),
                    sprintf('%s/%s', $Conf::Conf{'ssl_cert_dir'}, $new);
            }
        }

        $log->syslog('notice', '...Done.');
    }

    if (lower_version($previous_version, '6.2.65b.1')) {
        # Site/domain parameter "tracking" has been deprecated and
        # should be renamed to "tracking.tracking" to avoid conflict with
        # list config paragraph named "tracking".

        _process_all_files(
            '',
            sub {
                my $that    = shift;
                my $dir     = shift;
                my $oldfile = shift;

                my $file;
                if (ref $that eq 'Sympa::List') {
                    return;
                } elsif ($that and $that ne '*') {
                    $file = sprintf '%s/robot.conf', $dir;
                } else {
                    $file = Sympa::Constants::CONFIG();
                }

                open my $fh, '<+', $file or next;

                my $text = do { local $RS; <$fh> };
                $text =~ s/(\A|\n)tracking(\s|\z)/${1}tracking.tracking$2/g;
                seek $fh, 0, 0;
                truncate $fh, 0;
                print $fh $text;
                close $fh;
            }
        );
    }

    if (lower_version($previous_version, '6.2.72')) {
        # Web fonts have moved to Font Awesome 6 Free.
        # Upgrade customized templates.
        $log->syslog('notice', 'Upgrading web templates...');
        Sympa::CLI->run({}, 'upgrade', 'webfont');
        $log->syslog('notice', '...Done.');
    }

    if (lower_version($previous_version, '6.2.74')) {
        # syslog_socket.type no longer has the default.
        # Previously, log_socket_type had a default value "unix".
        if (open my $fh, '+<', Conf::get_sympa_conf()) {
            my @p = grep {/\A\s*log_socket_type\s+\S+/} <$fh>;
            if (not @p and seek $fh, 0, 2) {
                my $human_date =
                    $language->gettext_strftime('%d %b %Y at %H:%M:%S',
                    localtime time);
                printf $fh
                    "\n\n# Upgrade from %s to %s\n# %s\nsyslog_socket.type unix\n",
                    $previous_version, $new_version, $human_date;
            }
            close $fh;
        }
    }

    return 1;
}

# Use Sympa::DatabaseManager::probe_db();
#sub probe_db;

# Use Conf::data_structure_uptodate();
#sub data_structure_uptodate;

## used to encode files to UTF-8
## also add X-Attach header field if template requires it
## IN : - arrayref with list of filepath/lang pairs
sub to_utf8 {
    my $files = shift;

    my $with_attachments =
        qr{ archive.tt2 | digest.tt2 | get_archive.tt2 | listmaster_notification.tt2 | 
				   message_report.tt2 | moderate.tt2 |  modindex.tt2 | send_auth.tt2 }x;
    my $total;

    # Get an obsoleted parameter filesystem_encoding.
    my $filesystem_encoding;
    open my $fh, '<', Conf::get_sympa_conf();
    while (my $line = <$fh>) {
        $filesystem_encoding = $1
            if $line =~ /\A\s*(?:web_recode_to|filesystem_encoding)\s+(\S+)/i;
    }
    close $fh;

    foreach my $pair (@{$files}) {
        my ($file, $lang) = @$pair;
        my $ifh;
        unless (open $ifh, '<', $file) {
            $log->syslog('err', 'Cannot open template %s', $file);
            next;
        }

        my $text     = '';
        my $modified = 0;

        # If an obsoleted parameter filesystem_encoding was set, files are
        # supposed to be encoded according to it.
        my $charset;
        if ($filesystem_encoding) {
            $charset = $filesystem_encoding;
        } else {
            $language->push_lang($lang);
            $charset = Conf::lang2charset($language->get_lang);
            $language->pop_lang;
        }

        # Add X-Sympa-Attach: headers if required.
        if ($file =~ /mail_tt2/ and $file =~ /\/($with_attachments)$/) {
            while (<$ifh>) {
                $text .= $_;
                if (m/^Content-Type:\s*message\/rfc822/i) {
                    while (<$ifh>) {
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
            $text = do { local $RS; <$ifh> };
        }
        close $ifh;

        # Check if template is encoded by UTF-8.
        if ($text =~ /[^\x20-\x7E]/) {
            my $t = $text;
            eval { Encode::decode('UTF-8', $t, Encode::FB_CROAK); };
            if ($EVAL_ERROR) {
                eval {
                    $t = $text;
                    Encode::from_to($t, $charset, "UTF-8", Encode::FB_CROAK);
                };
                if ($EVAL_ERROR) {
                    $log->syslog('err',
                        "Template %s cannot be converted from %s to UTF-8",
                        $charset, $file);
                } else {
                    $text     = $t;
                    $modified = 1;
                }
            }
        }

        next unless $modified;

        my $date = time;
        unless (rename $file, $file . '.' . $date) {
            $log->syslog('err', "Cannot rename old template %s", $file);
            next;
        }
        my $ofh;
        unless (open $ofh, '>', $file) {
            $log->syslog('err', "Cannot open new template %s", $file);
            next;
        }
        print $ofh $text;
        close $ofh;
        unless (
            Sympa::Tools::File::set_file_rights(
                file  => $file,
                user  => Sympa::Constants::USER,
                group => Sympa::Constants::GROUP,
                mode  => 0644,
            )
        ) {
            $log->syslog('err', 'Unable to set rights on %s',
                $Conf::Conf{'db_name'});
            next;
        }
        $log->syslog('notice', 'Modified file %s; original file kept as %s',
            $file, $file . '.' . $date);

        $total++;
    }

    return $total;
}

## Compare 2 versions of Sympa
# Old name: tools::lower_version().
sub lower_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./, $v1;
    my @tab2 = split /\./, $v2;

    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for my $i (0 .. $max) {

        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        } elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        } elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] < $tab2[0]);
    }

    return 0;
}

sub fix_colors {
    my ($file) = @_;
    my $new_conf = '';
    my %default_colors;
    return unless (-f $file);
    foreach my $param (@Sympa::ConfDef::params) {
        my $name = $param->{'name'};
        next unless ($name);
        if ($name =~ m{color_.+}) {
            $default_colors{$name} = $param->{'default'};
            unless (Sympa::DatabaseManager::probe_db()) {
                die sprintf
                    "Database %s defined in sympa.conf has not the right structure or is unreachable. verify db_xxx parameters in sympa.conf\n",
                    $Conf::Conf{'db_name'};
            }
            my $sdm = Sympa::DatabaseManager->instance;
            unless (
                $sdm
                and $sdm->do_query(
                    'DELETE FROM conf_table WHERE label_conf like %s',
                    $sdm->quote($name)
                )
            ) {
                $log->syslog('err',
                    'Cannot clean color parameters from database.');
            }
        }
    }
    my $ifh;
    unless (open $ifh, '<', $file) {
        die sprintf "Unable to open %s : %s", $file, $ERRNO;
    }
    foreach my $line (<$ifh>) {
        chomp $line;
        if ($line =~ m{^\s*(color_\d+)}) {
            my $param_name = $1;
            $line = sprintf '%s %s', $param_name,
                $default_colors{$param_name};
        }
        $new_conf .= "$line\n";
    }
    # Save previous config file
    my $date = time;
    unless (rename($file, "$file.upgrade$date")) {
        $log->syslog(
            'err',
            'Unable to rename %s file: %s. Web interface might look buggy after upgrade',
            $file,
            $ERRNO
        );
        return 0;
    }
    $log->syslog('notice', '%s file saved as %s', $file,
        "$file.upgrade$date");
    ## Write new config file
    my $umask = umask 037;
    my $ofh;
    unless (open $ofh, '>', $file) {
        umask $umask;
        $log->syslog(
            'err',
            'Unable to open %s : %s. Web interface colors not updated. Please remove them by hand in config file.',
            $file,
            $ERRNO
        );
        return 0;
    }
    umask $umask;
    chown [getpwnam(Sympa::Constants::USER)]->[2],
        [getgrnam(Sympa::Constants::GROUP)]->[2], $file;

    print $ofh $new_conf;
    close $ofh;
}

sub save_web_tt2 {
    my ($dir) = @_;
    unless (-w $dir) {
        $log->syslog(
            'err',
            '%s directory is not writable: %s. Unable to rename it. Web interface might look buggy after upgrade',
            $dir,
            $ERRNO
        );
        return 0;
    }
    my $date = time;
    unless (rename($dir, "$dir.upgrade$date")) {
        $log->syslog(
            'err',
            'Unable to rename %s directory: %s. Web interface might look buggy after upgrade',
            $dir,
            $ERRNO
        );
        return 0;
    }
    $log->syslog('notice', '%s directory saved as %s',
        $dir, "$dir.upgrade$date");
    return 1;
}

sub _get_canonical_read_date {
    my $sdm    = shift;
    my $target = shift;

    if ($sdm->isa('Sympa::DatabaseDriver::MySQL')) {
        return sprintf 'UNIX_TIMESTAMP(%s)', $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::Oracle')) {
        return
            sprintf
            q{((to_number(to_char(%s,'J')) - to_number(to_char(to_date('01/01/1970','dd/mm/yyyy'), 'J'))) * 86400) +to_number(to_char(%s,'SSSSS'))},
            $target, $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::PostgreSQL')) {
        return sprintf 'date_part(\'epoch\',%s)', $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::SQLite')) {
        return $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::Sybase')) {
        return sprintf 'datediff(second, \'01/01/1970\',%s)', $target;
    } else {
        # Unknown driver
        return $target;
    }
}

# No yet used.
sub _get_cacnonical_write_date {
    my $sdm    = shift;
    my $target = shift;

    if ($sdm->isa('Sympa::DatabaseDriver::MySQL')) {
        return sprintf 'FROM_UNIXTIME(%d)', $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::Oracle')) {
        return
            sprintf
            q{to_date(to_char(floor(%s/86400) + to_number(to_char(to_date('01/01/1970','dd/mm/yyyy'), 'J'))) || ':' ||to_char(mod(%s,86400)), 'J:SSSSS')},
            $target, $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::PostgreSQL')) {
        return sprintf '\'epoch\'::timestamp with time zone + \'%d sec\'',
            $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::SQLite')) {
        return $target;
    } elsif ($sdm->isa('Sympa::DatabaseDriver::Sybase')) {
        return sprintf 'dateadd(second,%s,\'01/01/1970\')', $target;
    } else {
        # Unknown driver
        return $target;
    }
}

sub _process_all_files {
    my $file = shift;
    my $sub  = shift;

    $sub->('*', $Conf::Conf{'etc'}, $file)
        if -f $Conf::Conf{'etc'} . '/' . $file;

    foreach my $robot (Sympa::List::get_robots()) {
        my $dir = sprintf '%s/%s', $Conf::Conf{'etc'}, $robot;
        $sub->($robot, $dir, $file)
            if -f $dir . '/' . $file;

        foreach my $list (@{Sympa::List::get_lists($robot) || []}) {
            $sub->($list, $list->{'dir'}, $file)
                if -f $list->{'dir'} . '/' . $file;
        }
    }
}

# Old name: tools::escape_chars(), Sympa::Tools::Text::escape_chars().
sub _escape_chars {
    my $s          = shift;
    my $except     = shift;                            ## Exceptions
    my $ord_except = ord $except if defined $except;

    ## Escape chars
    ##  !"#$%&'()+,:;<=>?[] AND accented chars
    ## escape % first
    foreach my $i (
        0x25,
        0x20 .. 0x24,
        0x26 .. 0x2c,
        0x3a .. 0x3f,
        0x5b, 0x5d,
        0x80 .. 0x9f,
        0xa0 .. 0xff
    ) {
        next if defined $ord_except and $i == $ord_except;
        my $hex_i = sprintf "%lx", $i;
        $s =~ s/\x$hex_i/%$hex_i/g;
    }
    ## Special traetment for '/'
    $s =~ s/\//%a5/g unless defined $except and $except eq '/';

    return $s;
}

# Old name: tools::unescape_chars(), Sympa::Tools::Text::unescape_chars().
sub _unescape_chars {
    my $s = shift;

    $s =~ s/%a5/\//g;    ## Special traetment for '/'
    foreach my $i (0x20 .. 0x2c, 0x3a .. 0x3f, 0x5b, 0x5d, 0x80 .. 0x9f,
        0xa0 .. 0xff) {
        my $hex_i = sprintf "%lx", $i;
        my $hex_s = sprintf "%c",  $i;
        $s =~ s/%$hex_i/$hex_s/g;
    }

    return $s;
}

1;
