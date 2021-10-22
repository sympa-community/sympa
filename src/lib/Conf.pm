# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

## This module handles the configuration file for Sympa.

package Conf;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Tools::Data;
use Sympa::Tools::File;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

=encoding utf-8

#=head1 NAME
#
#Conf - Sympa configuration

=head1 DESCRIPTION

=head2 CONSTANTS AND EXPORTED VARIABLES

=cut

## Database and SQL statement handlers
my $sth;
# parameters hash, keyed by parameter name
our %params =
    map { $_->{name} => $_ }
    grep { $_->{name} } @Sympa::ConfDef::params;

# valid virtual host parameters, keyed by parameter name
my %valid_robot_key_words;
my %db_storable_parameters;
my %optional_key_words;
foreach my $hash (@Sympa::ConfDef::params) {
    $valid_robot_key_words{$hash->{'name'}} = 1 if ($hash->{'vhost'});
    $db_storable_parameters{$hash->{'name'}} = 1
        if (defined($hash->{'db'}) and $hash->{'db'} ne 'none');
    $optional_key_words{$hash->{'name'}} = 1 if ($hash->{'optional'});
}

our $params_by_categories = _get_parameters_names_by_category();

my %trusted_applications = (
    'trusted_application' => {
        'occurrence' => '0-n',
        'format'     => {
            'name' => {
                'format'     => '\S*',
                'occurrence' => '1',
                'case'       => 'insensitive',
            },
            'ip' => {
                'format'     => '\d+\.\d+\.\d+\.\d+',
                'occurrence' => '0-1'
            },
            'md5password' => {
                'format'     => '.*',
                'occurrence' => '0-1'
            },
            'proxy_for_variables' => {
                'format'     => '.*',
                'occurrence' => '0-n',
                'split_char' => ','
            },
            'set_variables' => {
                'format'     => '\S+=.*',
                'occurrence' => '0-n',
                'split_char' => ',',
            },
            'allow_commands' => {
                'format'     => '\S+',
                'occurrence' => '0-n',
                'split_char' => ',',
            },
        }
    }
);
#XXXmy $binary_file_extension = ".bin";

our $wwsconf;
our %Conf = ();

=head2 FUNCTIONS

=over 4

=item load ( [ CONFIG_FILE ], [ NO_DB ], [ RETURN_RESULT ] )

Loads and parses the configuration file.  Reports errors if any.

do not try to load database values if NO_DB is set;
do not change gloval hash %Conf if RETURN_RESULT is set;

## we known that's dirty, this proc should be rewritten without this global
## var %Conf

=back

=cut

sub load {
    my $config_file   = shift || get_sympa_conf();
    my $no_db         = shift;
    my $return_result = shift;
    my $force_reload;

    my $config_err = 0;
    my $unknown;
    my %line_numbered_config;

    $log->syslog('debug3',
        'File %s has changed since the last cache. Loading file',
        $config_file);
    # Will force the robot.conf reloading, as sympa.conf is the default.
    $force_reload = 1;
    ## Loading the Sympa main config file.
    if (my $config_loading_result = _load_config_file_to_hash($config_file)) {
        %line_numbered_config =
            %{$config_loading_result->{'numbered_config'}};
        %Conf       = %{$config_loading_result->{'config'}};
        $config_err = $config_loading_result->{'errors'};
        $unknown    = $config_loading_result->{unknown};
    } else {
        return undef;
    }
    # Returning the config file content if this is what has been asked.
    return (\%line_numbered_config) if ($return_result);

    # Users may define parameters with a typo or other errors. Check that
    # the parameters
    # we found in the config file are all well defined Sympa parameters.
    $config_err += $unknown;

    _set_listmasters_entry(\%Conf);

    ## Some parameters must have a value specifically defined in the
    ## config. If not, it is an error.
    $config_err += _detect_missing_mandatory_parameters(\%Conf);

    # Some parameters need special treatments to get their final values.
    _infer_server_specific_parameter_values({'config_hash' => \%Conf,});

    _infer_robot_parameter_values({'config_hash' => \%Conf});

    if ($config_err) {
        $log->syslog('err', 'Errors while parsing main config file %s',
            $config_file);
        return undef;
    }

    _store_source_file_name(
        {'config_hash' => \%Conf, 'config_file' => $config_file});
    #XXX_save_config_hash_to_binary({'config_hash' => \%Conf,});

    if (my $missing_modules_count =
        _check_cpan_modules_required_by_config({'config_hash' => \%Conf,})) {
        $log->syslog('err', 'Warning: %d required modules are missing',
            $missing_modules_count);
    }

    _replace_file_value_by_db_value({'config_hash' => \%Conf})
        unless ($no_db);
    _load_server_specific_secondary_config_files({'config_hash' => \%Conf,});
    _load_robot_secondary_config_files({'config_hash' => \%Conf});

    ## Load robot.conf files
    unless (
        load_robots(
            {   'config_hash'  => \%Conf,
                'no_db'        => $no_db,
                'force_reload' => $force_reload
            }
        )
    ) {
        return undef;
    }
    ##_create_robot_like_config_for_main_robot();
    return 1;
}

## load each virtual robots configuration files
sub load_robots {
    my $param = shift;
    my @robots;

    my $robots_list_ref = get_robots_list();
    unless (defined $robots_list_ref) {
        $log->syslog('err', 'Robots config loading failed');
        return undef;
    } else {
        @robots = @{$robots_list_ref};
    }
    unless ($#robots > -1) {
        return 1;
    }
    my $exiting = 0;
    foreach my $robot (@robots) {
        my $robot_config_file = "$Conf{'etc'}/$robot/robot.conf";
        my $robot_conf        = undef;
        unless (
            $robot_conf = _load_single_robot_config(
                {   'robot'        => $robot,
                    'no_db'        => $param->{'no_db'},
                    'force_reload' => $param->{'force_reload'}
                }
            )
        ) {
            $log->syslog(
                'err',
                'The config for robot %s contain errors: it could not be correctly loaded',
                $robot
            );
            $exiting = 1;
        } else {
            $param->{'config_hash'}{'robots'}{$robot} = $robot_conf;
        }
        #_check_double_url_usage(
        #    {'config_hash' => $param->{'config_hash'}{'robots'}{$robot}});
    }
    return undef if ($exiting);
    return 1;
}

## returns a robot conf parameter
sub get_robot_conf {
    my ($robot, $key) = @_;

    # Resolve alias.
    my ($k, $o) = ($key, $key);
    do {
        ($k, $o) = ($o, ($params{$o} // {})->{obsolete});
    } while ($o and $params{$o});
    $key = $k;

    if (defined $robot and $robot ne '*') {
        return $Conf{'robots'}{$robot}{$key}
            if defined $Conf{'robots'}{$robot}
            and defined $Conf{'robots'}{$robot}{$key};
    }
    # default
    return $Conf{$key};
}

=over 4

=item get_sympa_conf

Gets path name of main config file.
Path name is taken from:

=over 4

=item 1

C<--config> command line option

=item 2

C<SYMPA_CONFIG> environment variable

=item 3

built-in default

=back

=back

=cut

our $sympa_config;

sub get_sympa_conf {
    return $sympa_config || $ENV{'SYMPA_CONFIG'} || Sympa::Constants::CONFIG;
}

=over 4

=item get_wwsympa_conf

Gets path name of wwsympa.conf file.
Path name is taken from:

=over 4

=item 1

C<SYMPA_WWSCONFIG> environment variable

=item 2

built-in default

=back

=back

=cut

sub get_wwsympa_conf {
    return $ENV{'SYMPA_WWSCONFIG'} || Sympa::Constants::WWSCONFIG;
}

# deletes all the *.conf.bin files.
# No longer used.
#sub delete_binaries;

# Return a reference to an array containing the names of the robots on the
# server.
sub get_robots_list {
    $log->syslog('debug2', "Retrieving the list of robots on the server");
    my @robots_list;
    unless (opendir DIR, $Conf{'etc'}) {
        $log->syslog('err',
            'Unable to open directory %s for virtual robots config',
            $Conf{'etc'});
        return undef;
    }
    foreach my $robot (readdir DIR) {
        my $robot_config_file = "$Conf{'etc'}/$robot/robot.conf";
        next unless (-d "$Conf{'etc'}/$robot");
        next unless (-f $robot_config_file);
        push @robots_list, $robot;
    }
    closedir(DIR);
    return \@robots_list;
}

## Returns a hash containing the values of all the parameters of the group
## (as defined in Sympa::ConfDef) whose name is given as argument, in the
## context of the robot given as argument.
sub get_parameters_group {
    my ($robot, $group) = @_;
    $log->syslog('debug3', 'Getting parameters for group "%s"', $group);
    my $param_hash;
    foreach my $param_name (keys %{$params_by_categories->{$group}}) {
        $param_hash->{$param_name} = get_robot_conf($robot, $param_name);
    }
    return $param_hash;
}

## fetch the value from parameter $label of robot $robot from conf_table
sub get_db_conf {
    my $robot = shift;
    my $label = shift;

    # if the value is related to a robot that is not explicitly defined, apply
    # it to the default robot.
    $robot = '*' unless (-f $Conf{'etc'} . '/' . $robot . '/robot.conf');
    unless ($robot) { $robot = '*' }

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT value_conf AS value
              FROM conf_table
              WHERE robot_conf = ? AND label_conf = ?},
            $robot, $label
        )
    ) {
        $log->syslog(
            'err',
            'Unable retrieve value of parameter %s for robot %s from the database',
            $label,
            $robot
        );
        return undef;
    }

    my $value = $sth->fetchrow;

    $sth->finish();
    return $value;
}

## store the value from parameter $label of robot $robot from conf_table
sub set_robot_conf {
    my $robot = shift;
    my $label = shift;
    my $value = shift;

    $log->syslog('info', 'Set config for robot %s, %s="%s"',
        $robot, $label, $value);

    # set the current config before to update database.
    if (-f "$Conf{'etc'}/$robot/robot.conf") {
        $Conf{'robots'}{$robot}{$label} = $value;
    } else {
        $Conf{$label} = $value;
        $robot = '*';
    }

    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT COUNT(*)
              FROM conf_table
              WHERE robot_conf = ? AND label_conf = ?},
            $robot, $label
        )
    ) {
        $log->syslog(
            'err',
            'Unable to check presence of parameter %s for robot %s in database',
            $label,
            $robot
        );
        return undef;
    }

    my $count = $sth->fetchrow;
    $sth->finish();

    if ($count == 0) {
        unless (
            $sth = $sdm->do_prepared_query(
                q{INSERT INTO conf_table
                  (robot_conf, label_conf, value_conf)
                  VALUES (?, ?, ?)},
                $robot, $label, $value
            )
        ) {
            $log->syslog(
                'err',
                'Unable add value %s for parameter %s in the robot %s DB conf',
                $value,
                $label,
                $robot
            );
            return undef;
        }
    } else {
        unless (
            $sth = $sdm->do_prepared_query(
                q{UPDATE conf_table
                  SET robot_conf = ?, label_conf = ?, value_conf = ?
                  WHERE robot_conf = ? AND label_conf = ?},
                $robot, $label, $value,
                $robot, $label
            )
        ) {
            $log->syslog(
                'err',
                'Unable set parameter %s value to %s in the robot %s DB conf',
                $label,
                $value,
                $robot
            );
            return undef;
        }
    }
}

# Store configs to database
sub conf_2_db {
    $log->syslog('debug2', '(%s)', @_);

    my @conf_parameters = @Sympa::ConfDef::params;

    # store in database robots parameters.
    # load only parameters that are in a robot.conf file (do not apply
    # defaults).
    my $robots_conf = load_robots();

    unless (opendir DIR, $Conf{'etc'}) {
        $log->syslog('err',
            'Unable to open directory %s for virtual robots config',
            $Conf{'etc'});
        return undef;
    }

    foreach my $robot (readdir(DIR)) {
        next unless (-d "$Conf{'etc'}/$robot");
        next unless (-f "$Conf{'etc'}/$robot/robot.conf");

        my $config;
        if (my $result_of_config_loading = _load_config_file_to_hash(
                $Conf{'etc'} . '/' . $robot . '/robot.conf'
            )
        ) {
            $config = $result_of_config_loading->{'config'};
        }
        _remove_unvalid_robot_entry($config);

        for my $i (0 .. $#conf_parameters) {
            if ($conf_parameters[$i]->{'name'}) {
                # skip separators in conf_parameters structure
                if (($conf_parameters[$i]->{'vhost'} eq '1')
                    && #skip parameters that can't be define by robot so not to be loaded in db at that stage
                    ($config->{$conf_parameters[$i]->{'name'}})
                ) {
                    Conf::set_robot_conf(
                        $robot,
                        $conf_parameters[$i]->{'name'},
                        $config->{$conf_parameters[$i]->{'name'}}
                    );
                }
            }
        }
    }
    closedir(DIR);

    # store in database sympa;conf and wwsympa.conf

    ## Load configuration file. Ignoring database config and get result
    my $global_conf;
    unless ($global_conf =
        Conf::load(Conf::get_sympa_conf(), 1, 'return_result')) {
        $log->syslog('err', 'Configuration file %s has errors',
            Conf::get_sympa_conf());
        return undef;
    }

    for my $i (0 .. $#conf_parameters) {
        if (($conf_parameters[$i]->{'edit'} eq '1')
            && $global_conf->{$conf_parameters[$i]->{'name'}}) {
            Conf::set_robot_conf(
                "*",
                $conf_parameters[$i]->{'name'},
                $global_conf->{$conf_parameters[$i]->{'name'}}[0]
            );
        }
    }
}

## Check required files and create them if required
sub checkfiles_as_root {

    my $config_err = 0;

    ## Check aliases file
    unless (-f $Conf{'sendmail_aliases'}
        || ($Conf{'sendmail_aliases'} =~ /^none$/i)) {
        unless (open ALIASES, ">$Conf{'sendmail_aliases'}") {
            $log->syslog(
                'err',
                "Failed to create aliases file %s",
                $Conf{'sendmail_aliases'}
            );
            return undef;
        }

        print ALIASES
            "## This aliases file is dedicated to Sympa Mailing List Manager\n";
        print ALIASES
            "## You should edit your sendmail.mc or sendmail.cf file to declare it\n";
        close ALIASES;
        $log->syslog(
            'notice',
            "Created missing file %s",
            $Conf{'sendmail_aliases'}
        );
        unless (
            Sympa::Tools::File::set_file_rights(
                file  => $Conf{'sendmail_aliases'},
                user  => Sympa::Constants::USER,
                group => Sympa::Constants::GROUP,
                mode  => 0644,
            )
        ) {
            $log->syslog('err', 'Unable to set rights on %s',
                $Conf{'db_name'});
            return undef;
        }
    }

    foreach my $robot (keys %{$Conf{'robots'}}) {

        # create static content directory
        my $dir = get_robot_conf($robot, 'static_content_path');
        if ($dir ne '' && !-d $dir) {
            unless (mkdir($dir, 0775)) {
                $log->syslog('err', 'Unable to create directory %s: %m',
                    $dir);
                $config_err++;
            }

            unless (
                Sympa::Tools::File::set_file_rights(
                    file  => $dir,
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
                )
            ) {
                $log->syslog('err', 'Unable to set rights on %s',
                    $Conf{'db_name'});
                return undef;
            }
        }
    }

    return 1;
}

## Check if data structures are uptodate
## If not, no operation should be performed before the upgrade process is run
sub data_structure_uptodate {
    my $version_file =
        Conf::get_robot_conf('*', 'etc') . '/data_structure.version';
    my $data_structure_version;

    if (-f $version_file) {
        my $fh;
        unless (open $fh, '<', $version_file) {
            $log->syslog('err', 'Unable to open %s: %m', $version_file);
            return undef;
        }
        while (<$fh>) {
            next if /^\s*$/;
            next if /^\s*\#/;
            chomp;
            $data_structure_version = $_;
            last;
        }
        close $fh;
    }

    if (defined $data_structure_version
        and $data_structure_version ne Sympa::Constants::VERSION) {
        $log->syslog('err',
            "Data structure (%s) is not uptodate for current release (%s)",
            $data_structure_version, Sympa::Constants::VERSION);
        return 0;
    }

    return 1;
}

# Check if cookie parameter was changed.
# Old name: tools::cookie_changed().
# Deprecated: No longer used.
#sub cookie_changed;

## Check a few files
sub checkfiles {
    my $config_err = 0;

    foreach my $p (qw(sendmail antivirus_path)) {
        next unless $Conf{$p};

        unless (-x $Conf{$p}) {
            $log->syslog('err', "File %s does not exist or is not executable",
                $Conf{$p});
            $config_err++;
        }
    }

    foreach my $qdir (qw(spool queuetask tmpdir)) {
        unless (-d $Conf{$qdir}) {
            $log->syslog('info', 'Creating spool %s', $Conf{$qdir});
            unless (mkdir($Conf{$qdir}, 0775)) {
                $log->syslog('err', 'Unable to create spool %s',
                    $Conf{$qdir});
                $config_err++;
            }
            unless (
                Sympa::Tools::File::set_file_rights(
                    file  => $Conf{$qdir},
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
                )
            ) {
                $log->syslog('err', 'Unable to set rights on %s',
                    $Conf{$qdir});
                $config_err++;
            }
        }
    }

    # Check if directory parameters point to the same directory.
    my @keys = qw(bounce_path etc home
        queue queueauth queuebounce queuebulk queuedigest
        queuemod queueoutgoing queuesubscribe queuetask
        queuetopic spool tmpdir viewmail_dir);
    push @keys, 'queueautomatic'
        if $Conf::Conf{'automatic_list_feature'} eq 'on';
    my %dirs = (Sympa::Constants::PIDDIR() => 'PID directory');

    foreach my $key (@keys) {
        my $val = $Conf::Conf{$key};
        next unless $val;

        if ($dirs{$val}) {
            $log->syslog(
                'err',
                'Error in config: %s and %s parameters pointing to the same directory (%s)',
                $dirs{$val},
                $key,
                $val
            );
            $config_err++;
        } else {
            $dirs{$val} = $key;
        }
    }

    # Create pictures directory. FIXME: Would be created on demand.
    my $pictures_dir = $Conf::Conf{'pictures_path'};
    unless (-d $pictures_dir) {
        unless (mkdir $pictures_dir, 0775) {
            $log->syslog('err', 'Unable to create directory %s',
                $pictures_dir);
            $config_err++;
        } else {
            chmod 0775, $pictures_dir;    # set masked bits.

            my $index_path = $pictures_dir . '/index.html';
            my $fh;
            unless (open $fh, '>', $index_path) {
                $log->syslog(
                    'err',
                    'Unable to create %s as an empty file to protect directory',
                    $index_path
                );
            } else {
                close $fh;
            }
        }
    }

    #update_css();

    return undef if ($config_err);
    return 1;
}

## return 1 if the parameter is a known robot
## Valid options :
##    'just_try' : prevent error logs if robot is not valid
sub valid_robot {
    my $robot   = shift;
    my $options = shift;

    ## Main host
    return 1 if ($robot eq $Conf{'domain'});

    ## Missing etc directory
    unless (-d $Conf{'etc'} . '/' . $robot) {
        $log->syslog(
            'err',  'Robot %s undefined; no %s directory',
            $robot, $Conf{'etc'} . '/' . $robot
        ) unless ($options->{'just_try'});
        return undef;
    }

    ## Missing expl directory
    unless (-d $Conf{'home'} . '/' . $robot) {
        $log->syslog(
            'err',  'Robot %s undefined; no %s directory',
            $robot, $Conf{'home'} . '/' . $robot
        ) unless ($options->{'just_try'});
        return undef;
    }

    ## Robot not loaded
    unless (defined $Conf{'robots'}{$robot}) {
        $log->syslog('err', 'Robot %s was not loaded by this Sympa process',
            $robot)
            unless ($options->{'just_try'});
        return undef;
    }

    return 1;
}

## Returns the SSO record correponding to the provided sso_id
## return undef if none was found
sub get_sso_by_id {
    my %param = @_;

    unless (defined $param{'service_id'} && defined $param{'robot'}) {
        return undef;
    }

    foreach my $sso (@{$Conf{'auth_services'}{$param{'robot'}}}) {
        $log->syslog('notice', 'SSO: %s', $sso->{'service_id'});
        next unless ($sso->{'service_id'} eq $param{'service_id'});

        return $sso;
    }

    return undef;
}

##########################################
## Low level subs. Not supposed to be called from other modules.
##########################################

sub _load_auth {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $that = shift || '*';

    my $config_file = Sympa::search_fullpath($that, 'auth.conf');
    die sprintf 'No auth.conf for %s', $that
        unless $config_file and -r $config_file;

    my $robot      = ($that and $that ne '*') ? $that : $Conf{'domain'};
    my $line_num   = 0;
    my $config_err = 0;
    my @paragraphs;
    my %result;
    my $current_paragraph;

    my %valid_keywords = (
        'ldap' => {
            'regexp'          => '.*',
            'negative_regexp' => '.*',
            'host'            => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
            'timeout'         => '\d+',
            'suffix'          => '.+',
            'bind_dn'         => '.+',
            'bind_password'   => '.+',
            'get_dn_by_uid_filter'   => '.+',
            'get_dn_by_email_filter' => '.+',
            'email_attribute'        => Sympa::Regexps::ldap_attrdesc(),
            'alternative_email_attribute' => '.*',                 # Obsoleted
            'scope'                       => 'base|one|sub',
            'authentication_info_url'     => 'http(s)?:/.*',
            'use_tls'                     => 'starttls|ldaps|none',
            'use_ssl'                     => '1',                  # Obsoleted
            'use_start_tls'               => '1',                  # Obsoleted
            'ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1|tlsv1_[123]',
            'ssl_ciphers' => '[\w:]+',
            'ssl_cert'    => '.+',
            'ssl_key'     => '.+',
            'ca_verify'   => '\w+',
            'ca_path'     => '.+',
            'ca_file'     => '.+',
        },

        'user_table' => {
            'regexp'          => '.*',
            'negative_regexp' => '.*'
        },

        'cas' => {
            'base_url'                   => 'http(s)?:/.*',
            'non_blocking_redirection'   => 'on|off',
            'login_path'                 => '.*',
            'logout_path'                => '.*',
            'service_validate_path'      => '.*',
            'proxy_path'                 => '.*',
            'proxy_validate_path'        => '.*',
            'auth_service_name'          => '[\w\-\.]+',
            'auth_service_friendly_name' => '.*',
            'authentication_info_url'    => 'http(s)?:/.*',
            'host'          => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
            'bind_dn'       => '.+',
            'bind_password' => '.+',
            'timeout'       => '\d+',
            'suffix'        => '.+',
            'scope'         => 'base|one|sub',
            'get_email_by_uid_filter' => '.+',
            'email_attribute'         => Sympa::Regexps::ldap_attrdesc(),
            'use_tls'                 => 'starttls|ldaps|none',
            'use_ssl'       => '1',    # Obsoleted
            'use_start_tls' => '1',    # Obsoleted
            'ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1|tlsv1_[123]',
            'ssl_ciphers' => '[\w:]+',
            'ssl_cert'    => '.+',
            'ssl_key'     => '.+',
            'ca_verify'   => '\w+',
            'ca_path'     => '.+',
            'ca_file'     => '.+',
        },
        'generic_sso' => {
            'service_name'                => '.+',
            'service_id'                  => '\S+',
            'http_header_prefix'          => '\w+',
            'http_header_list'            => '[\w\.\-\,]+',
            'email_http_header'           => '\w+',
            'http_header_value_separator' => '.+',
            'logout_url'                  => '.+',
            'host'          => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
            'bind_dn'       => '.+',
            'bind_password' => '.+',
            'timeout'       => '\d+',
            'suffix'        => '.+',
            'scope'         => 'base|one|sub',
            'get_email_by_uid_filter' => '.+',
            'email_attribute'         => Sympa::Regexps::ldap_attrdesc(),
            'use_tls'                 => 'starttls|ldaps|none',
            'use_ssl'       => '1',    # Obsoleted
            'use_start_tls' => '1',    # Obsoleted
            'ssl_version'        => 'sslv2/3|sslv2|sslv3|tlsv1|tlsv1_[123]',
            'ssl_ciphers'        => '[\w:]+',
            'ssl_cert'           => '.+',
            'ssl_key'            => '.+',
            'ca_verify'          => '\w+',
            'ca_path'            => '.+',
            'ca_file'            => '.+',
            'force_email_verify' => '1',
            'internal_email_by_netid' => '1',
            'netid_http_header'       => '[\w\-\.]+',
        },
        'authentication_info_url' => 'http(s)?:/.*'
    );

    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config_file)) {
        $log->syslog('notice', 'Unable to open %s: %m', $config_file);
        return undef;
    }

    $Conf{'cas_number'}{$robot}         = 0;
    $Conf{'generic_sso_number'}{$robot} = 0;
    $Conf{'ldap_number'}{$robot}        = 0;
    $Conf{'use_passwd'}{$robot}         = 0;

    ## Parsing  auth.conf
    while (<IN>) {

        $line_num++;
        next if (/^\s*[\#\;]/o);

        if (/^\s*authentication_info_url\s+(.*\S)\s*$/o) {
            $Conf{'authentication_info_url'}{$robot} = $1;
            next;
        } elsif (/^\s*(ldap|cas|user_table|generic_sso)\s*$/io) {
            $current_paragraph->{'auth_type'} = lc($1);
        } elsif (/^\s*(\S+)\s+(.*\S)\s*$/o) {
            my ($keyword, $value) = ($1, $2);

            # Workaround: Some parameters required by cas and generic_sso auth
            # types may be prefixed by "ldap_", but LDAP database driver
            # requires those not prefixed.
            $keyword =~ s/\Aldap_//;

            unless (
                defined $valid_keywords{$current_paragraph->{'auth_type'}}
                {$keyword}) {
                $log->syslog('err', 'Unknown keyword "%s" in %s line %d',
                    $keyword, $config_file, $line_num);
                next;
            }
            unless ($value =~
                /^$valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}$/
            ) {
                $log->syslog('err',
                    'Unknown format "%s" for keyword "%s" in %s line %d',
                    $value, $keyword, $config_file, $line_num);
                next;
            }

            ## Allow white spaces between hosts
            if ($keyword =~ /host$/) {
                $value =~ s/\s//g;
            }

            $current_paragraph->{$keyword} = $value;
        }

        ## process current paragraph
        if (/^\s+$/o || eof(IN)) {
            if (defined($current_paragraph)) {
                # Parameters obsoleted as of 6.2.15.
                if ($current_paragraph->{use_start_tls}) {
                    $current_paragraph->{use_tls} = 'starttls';
                } elsif ($current_paragraph->{use_ssl}) {
                    $current_paragraph->{use_tls} = 'ldaps';
                }
                delete $current_paragraph->{use_start_tls};
                delete $current_paragraph->{use_ssl};

                if ($current_paragraph->{'auth_type'} eq 'cas') {
                    unless (defined $current_paragraph->{'base_url'}) {
                        $log->syslog('err',
                            'Incorrect CAS paragraph in auth.conf');
                        next;
                    }
                    $Conf{'cas_number'}{$robot}++;

                    eval "require AuthCAS";
                    if ($EVAL_ERROR) {
                        $log->syslog('err',
                            'Failed to load AuthCAS perl module');
                        return undef;
                    }

                    my $cas_param =
                        {casUrl => $current_paragraph->{'base_url'}};

                    ## Optional parameters
                    ## We should also cope with X509 CAs
                    $cas_param->{'loginPath'} =
                        $current_paragraph->{'login_path'}
                        if (defined $current_paragraph->{'login_path'});
                    $cas_param->{'logoutPath'} =
                        $current_paragraph->{'logout_path'}
                        if (defined $current_paragraph->{'logout_path'});
                    $cas_param->{'serviceValidatePath'} =
                        $current_paragraph->{'service_validate_path'}
                        if (
                        defined $current_paragraph->{'service_validate_path'}
                        );
                    $cas_param->{'proxyPath'} =
                        $current_paragraph->{'proxy_path'}
                        if (defined $current_paragraph->{'proxy_path'});
                    $cas_param->{'proxyValidatePath'} =
                        $current_paragraph->{'proxy_validate_path'}
                        if (
                        defined $current_paragraph->{'proxy_validate_path'});

                    $current_paragraph->{'cas_server'} =
                        AuthCAS->new(%{$cas_param});
                    unless (defined $current_paragraph->{'cas_server'}) {
                        $log->syslog(
                            'err',
                            'Failed to create CAS object for %s: %s',
                            $current_paragraph->{'base_url'},
                            AuthCAS::get_errors()
                        );
                        next;
                    }

                    $Conf{'cas_id'}{$robot}
                        {$current_paragraph->{'auth_service_name'}}{'casnum'}
                        = scalar @paragraphs;

                    ## Default value for auth_service_friendly_name IS
                    ## auth_service_name
                    $Conf{'cas_id'}{$robot}
                        {$current_paragraph->{'auth_service_name'}}
                        {'auth_service_friendly_name'} =
                           $current_paragraph->{'auth_service_friendly_name'}
                        || $current_paragraph->{'auth_service_name'};

                    ## Force the default scope because '' is interpreted as
                    ## 'base'
                    $current_paragraph->{'scope'} ||= 'sub';
                } elsif ($current_paragraph->{'auth_type'} eq 'generic_sso') {
                    $Conf{'generic_sso_number'}{$robot}++;
                    $Conf{'generic_sso_id'}{$robot}
                        {$current_paragraph->{'service_id'}} =
                        $#paragraphs + 1;
                    ## Force the default scope because '' is interpreted as
                    ## 'base'
                    $current_paragraph->{'scope'} ||= 'sub';
                    ## default value for http_header_value_separator is ';'
                    $current_paragraph->{'http_header_value_separator'} ||=
                        ';';

                    ## CGI.pm changes environment variable names ('-' => '_')
                    ## declared environment variable names needs to be
                    ## transformed accordingly
                    foreach my $parameter ('http_header_list',
                        'email_http_header', 'netid_http_header') {
                        $current_paragraph->{$parameter} =~ s/\-/\_/g
                            if (defined $current_paragraph->{$parameter});
                    }
                } elsif ($current_paragraph->{'auth_type'} eq 'ldap') {
                    $Conf{'ldap'}{$robot}++;
                    $Conf{'use_passwd'}{$robot} = 1;
                    ## Force the default scope because '' is interpreted as
                    ## 'base'
                    $current_paragraph->{'scope'} ||= 'sub';
                } elsif ($current_paragraph->{'auth_type'} eq 'user_table') {
                    $Conf{'use_passwd'}{$robot} = 1;
                }
                # setting default
                $current_paragraph->{'regexp'} = '.*'
                    unless (defined($current_paragraph->{'regexp'}));
                $current_paragraph->{'non_blocking_redirection'} = 'on'
                    unless (
                    defined($current_paragraph->{'non_blocking_redirection'})
                    );
                push(@paragraphs, $current_paragraph);

                undef $current_paragraph;
            }
            next;
        }
    }
    close(IN);

    return \@paragraphs;

}

## load charset.conf file (charset mapping for service messages)
sub load_charset {
    my $charset = {};

    my $config_file = Sympa::search_fullpath('*', 'charset.conf');
    return {} unless $config_file;

    unless (open CONFIG, $config_file) {
        $log->syslog('err', 'Unable to read configuration file %s: %m',
            $config_file);
        return {};
    }
    while (<CONFIG>) {
        chomp $_;
        s/\s*#.*//;
        s/^\s+//;
        next unless /\S/;
        my ($lang, $cset) = split(/\s+/, $_);
        unless ($cset) {
            $log->syslog('err',
                'Charset name is missing in configuration file %s line %d',
                $config_file, $NR);
            next;
        }
        # canonicalize lang if possible.
        $lang = Sympa::Language::canonic_lang($lang) || $lang;
        $charset->{$lang} = $cset;

    }
    close CONFIG;

    return $charset;
}

=over

=item lang2charset ( $lang )

Gets charset for e-mail messages sent by Sympa.

Parameters:

$lang - language.

Returns:

Charset name.
If it is not known, returns default charset.

=back

=cut

# Old name: tools::lang2charset().
# FIXME: This would be moved to such as Site package.
sub lang2charset {
    my $lang = shift;

    my $locale2charset;
    if ($lang and %Conf::Conf    # configuration loaded
        and $locale2charset = $Conf::Conf{'locale2charset'}
    ) {
        foreach my $l (Sympa::Language::implicated_langs($lang)) {
            if (exists $locale2charset->{$l}) {
                return $locale2charset->{$l};
            }
        }
    }
    return 'utf-8';              # the last resort
}

## load nrcpt file (limite receipient par domain
sub load_nrcpt_by_domain {
    my $config_file = Sympa::search_fullpath('*', 'nrcpt_by_domain.conf');
    return unless $config_file;

    my $line_num        = 0;
    my $config_err      = 0;
    my $nrcpt_by_domain = {};
    my $valid_dom       = 0;

    ## Open the configuration file or return and read the lines.
    unless (open IN, '<', $config_file) {
        $log->syslog('err', 'Unable to open %s: %m', $config_file);
        return;
    }
    while (<IN>) {
        $line_num++;
        next if (/^\s*$/o || /^[\#\;]/o);
        if (/^(\S+)\s+(\d+)$/io) {
            my ($domain, $value) = ($1, $2);
            chomp $domain;
            chomp $value;
            $nrcpt_by_domain->{$domain} = $value;
            $valid_dom += 1;
        } else {
            $log->syslog('notice',
                'Error at configuration file %s line %d: %s',
                $config_file, $line_num, $_);
            $config_err++;
        }
    }
    close IN;
    return $nrcpt_by_domain;
}

## load .sql named filter conf file
sub load_sql_filter {

    my $file                    = shift;
    my %sql_named_filter_params = (
        'sql_named_filter_query' => {
            'occurrence' => '1',
            'format'     => {
                'db_type' =>
                    {'format' => 'mysql|MySQL|Oracle|Pg|PostgreSQL|SQLite',},
                'db_name'    => {'format' => '.*',  'occurrence' => '1',},
                'db_host'    => {'format' => '.*',  'occurrence' => '0-1',},
                'statement'  => {'format' => '.*',  'occurrence' => '1',},
                'db_user'    => {'format' => '.*',  'occurrence' => '0-1',},
                'db_passwd'  => {'format' => '.*',  'occurrence' => '0-1',},
                'db_options' => {'format' => '.*',  'occurrence' => '0-1',},
                'db_env'     => {'format' => '.*',  'occurrence' => '0-1',},
                'db_port'    => {'format' => '\d+', 'occurrence' => '0-1',},
                'db_timeout' => {'format' => '\d+', 'occurrence' => '0-1',},
            }
        }
    );

    return undef unless (-r $file);

    return (
        load_generic_conf_file($file, \%sql_named_filter_params, 'abort'));
}

## load automatic_list_description.conf configuration file
sub load_automatic_lists_description {
    my $robot  = shift;
    my $family = shift;
    $log->syslog('debug2', 'Starting: Robot %s family %s', $robot, $family);

    my %automatic_lists_params = (
        'class' => {
            'occurrence' => '1-n',
            'format'     => {
                'name'        => {'format' => '.*',  'occurrence' => '1',},
                'stamp'       => {'format' => '.*',  'occurrence' => '1',},
                'description' => {'format' => '.*',  'occurrence' => '1',},
                'order'       => {'format' => '\d+', 'occurrence' => '1',},
                'instances' => {'occurrence' => '1', 'format' => '.*',},
                #'format' => {
                #'instance' => {
                #'occurrence' => '1-n',
                #'format' => {
                #'value' => {'format' => '.*', 'occurrence' => '1', },
                #'tag' => {'format' => '.*', 'occurrence' => '1', },
                #'order' => {'format' => '\d+', 'occurrence' => '1',  },
                #},
                #},
                #},
            },
        },
    );
    # find appropriate automatic_lists_description.conf file
    my $config = Sympa::search_fullpath(
        $robot,
        'automatic_lists_description.conf',
        subdir => ('families/' . $family)
    );
    return undef unless $config;
    my $description =
        load_generic_conf_file($config, \%automatic_lists_params);

    ## Now doing some structuration work because
    ## Conf::load_automatic_lists_description() can't handle
    ## data structured beyond one level of hash. This needs to be changed.
    my @structured_data;
    foreach my $class (@{$description->{'class'}}) {
        my @structured_instances;
        my @instances = split '%%%', $class->{'instances'};
        my $default_found = 0;
        foreach my $instance (@instances) {
            my $structured_instance;
            my @instance_params = split '---', $instance;
            foreach my $instance_param (@instance_params) {
                $instance_param =~ /^\s*(\S+)\s+(.*)\s*$/;
                my $key   = $1;
                my $value = $2;
                $key =~ s/^\s*//;
                $key =~ s/\s*$//;
                $value =~ s/^\s*//;
                $value =~ s/\s*$//;
                $structured_instance->{$key} = $value;
            }
            $structured_instances[$structured_instance->{'order'}] =
                $structured_instance;
            if (defined $structured_instance->{'default'}) {
                $default_found = 1;
            }
        }
        unless ($default_found) { $structured_instances[0]->{'default'} = 1; }
        $class->{'instances'} = \@structured_instances;
        $structured_data[$class->{'order'}] = $class;
    }
    $description->{'class'} = \@structured_data;
    return $description;
}

## load trusted_application.conf configuration file
sub load_trusted_application {
    my $that = shift || '*';

    # find appropriate trusted-application.conf file
    my $config_file =
        Sympa::search_fullpath($that, 'trusted_applications.conf');
    return undef unless $config_file and -r $config_file;

    return load_generic_conf_file($config_file, \%trusted_applications);
}

## load trusted_application.conf configuration file
sub load_crawlers_detection {
    my $that = shift || '*';

    my %crawlers_detection_conf = (
        'user_agent_string' => {
            'occurrence' => '0-n',
            'format'     => '.+'
        }
    );

    my $config_file =
        Sympa::search_fullpath($that, 'crawlers_detection.conf');
    return undef unless $config_file and -r $config_file;
    my $hashtab =
        load_generic_conf_file($config_file, \%crawlers_detection_conf);
    my $hashhash;

    foreach my $kword (keys %{$hashtab}) {
        # ignore comments and default
        next
            unless ($crawlers_detection_conf{$kword});
        foreach my $value (@{$hashtab->{$kword}}) {
            $hashhash->{$kword}{$value} = 'true';
        }
    }

    return $hashhash;
}

############################################################
#  load_generic_conf_file
############################################################
#  load a generic config organized by paragraph syntax
#
# IN : -$config_file (+): full path of config file
#      -$structure_ref (+): ref(HASH) describing expected syntax
#      -$on_error: optional. sub returns undef if set to 'abort'
#          and an error is found in conf file
# OUT : ref(HASH) of parsed parameters
#     | undef
#
##############################################################
sub load_generic_conf_file {
    my $config_file   = shift;
    my $structure_ref = shift;
    my $on_error      = shift;
    my %structure     = %$structure_ref;

    my %admin;
    my (@paragraphs);

    ## Just in case...
    local $RS = "\n";

    ## Set defaults to 1
    foreach my $pname (keys %structure) {
        $admin{'defaults'}{$pname} = 1
            unless ($structure{$pname}{'internal'});
    }

    ## Split in paragraphs
    my $i = 0;
    unless (open(CONFIG, $config_file)) {
        $log->syslog('err', 'Unable to read configuration file %s',
            $config_file);
        return undef;
    }
    while (<CONFIG>) {
        if (/^\s*$/) {
            $i++ if $paragraphs[$i];
        } else {
            push @{$paragraphs[$i]}, $_;
        }
    }

    ## Parse each paragraph
    for my $index (0 .. $#paragraphs) {
        my @paragraph = @{$paragraphs[$index]};

        my $pname;

        ## Clean paragraph, keep comments
        for my $i (0 .. $#paragraph) {
            my $changed = undef;
            for my $j (0 .. $#paragraph) {
                if ($paragraph[$j] =~ /^\s*\#/) {
                    chomp($paragraph[$j]);
                    push @{$admin{'comment'}}, $paragraph[$j];
                    splice @paragraph, $j, 1;
                    $changed = 1;
                } elsif ($paragraph[$j] =~ /^\s*$/) {
                    splice @paragraph, $j, 1;
                    $changed = 1;
                }
                last if $changed;
            }
            last unless $changed;
        }

        ## Empty paragraph
        next unless ($#paragraph > -1);

        ## Look for first valid line
        unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
            $log->syslog('notice', 'Bad paragraph "%s" in %s, ignored',
                $paragraph[0], $config_file);
            return undef if $on_error eq 'abort';
            next;
        }

        $pname = $1;
        unless (defined $structure{$pname}) {
            $log->syslog('notice', 'Unknown parameter "%s" in %s, ignored',
                $pname, $config_file);
            return undef if $on_error eq 'abort';
            next;
        }
        ## Uniqueness
        if (defined $admin{$pname}) {
            unless (($structure{$pname}{'occurrence'} eq '0-n')
                or ($structure{$pname}{'occurrence'} eq '1-n')) {
                $log->syslog('err', 'Multiple parameter "%s" in %s',
                    $pname, $config_file);
                return undef if $on_error eq 'abort';
            }
        }

        ## Line or Paragraph
        if (ref $structure{$pname}{'format'} eq 'HASH') {
            ## This should be a paragraph
            unless ($#paragraph > 0) {
                $log->syslog(
                    'notice',
                    'Expecting a paragraph for "%s" parameter in %s, ignore it',
                    $pname,
                    $config_file
                );
                return undef if $on_error eq 'abort';
                next;
            }

            ## Skipping first line
            shift @paragraph;

            my %hash;
            for my $i (0 .. $#paragraph) {
                next if ($paragraph[$i] =~ /^\s*\#/);
                unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
                    $log->syslog('notice', 'Bad line "%s" in %s',
                        $paragraph[$i], $config_file);
                    return undef if $on_error eq 'abort';
                }
                my $key = $1;
                unless (defined $structure{$pname}{'format'}{$key}) {
                    $log->syslog('notice',
                        'Unknown key "%s" in paragraph "%s" in %s',
                        $key, $pname, $config_file);
                    return undef if $on_error eq 'abort';
                    next;
                }

                unless ($paragraph[$i] =~
                    /^\s*$key\s+($structure{$pname}{'format'}{$key}{'format'})\s*$/i
                ) {
                    $log->syslog('notice',
                        'Bad entry "%s" in paragraph "%s" in %s',
                        $paragraph[$i], $key, $pname, $config_file);
                    return undef if $on_error eq 'abort';
                    next;
                }

                $hash{$key} =
                    _load_a_param($key, $1,
                    $structure{$pname}{'format'}{$key});
            }

            ## Apply defaults & Check required keys
            my $missing_required_field;
            foreach my $k (keys %{$structure{$pname}{'format'}}) {
                ## Default value
                unless (defined $hash{$k}) {
                    if (defined $structure{$pname}{'format'}{$k}{'default'}) {
                        $hash{$k} =
                            _load_a_param($k, 'default',
                            $structure{$pname}{'format'}{$k});
                    }
                }
                ## Required fields
                if ($structure{$pname}{'format'}{$k}{'occurrence'} eq '1') {
                    unless (defined $hash{$k}) {
                        $log->syslog('notice',
                            'Missing key %s in param %s in %s',
                            $k, $pname, $config_file);
                        return undef if $on_error eq 'abort';
                        $missing_required_field++;
                    }
                }
            }

            next if $missing_required_field;

            delete $admin{'defaults'}{$pname};

            ## Should we store it in an array
            if (($structure{$pname}{'occurrence'} =~ /n$/)) {
                push @{$admin{$pname}}, \%hash;
            } else {
                $admin{$pname} = \%hash;
            }
        } else {
            ## This should be a single line
            my $xxxmachin = $structure{$pname}{'format'};
            unless ($#paragraph == 0) {
                $log->syslog('err',
                    'Expecting a single line for %s parameter in %s %s',
                    $pname, $config_file, $xxxmachin);
                return undef if $on_error eq 'abort';
            }

            unless ($paragraph[0] =~
                /^\s*$pname\s+($structure{$pname}{'format'})\s*$/i) {
                $log->syslog('err', 'Bad entry "%s" in %s',
                    $paragraph[0], $config_file);
                return undef if $on_error eq 'abort';
                next;
            }

            my $value = _load_a_param($pname, $1, $structure{$pname});

            delete $admin{'defaults'}{$pname};

            if (($structure{$pname}{'occurrence'} =~ /n$/)
                && !(ref($value) =~ /^ARRAY/)) {
                push @{$admin{$pname}}, $value;
            } else {
                $admin{$pname} = $value;
            }
        }
    }
    close CONFIG;
    return \%admin;
}

### load_a_param
#
sub _load_a_param {
    my ($key, $value, $p) = @_;

    ## Empty value
    if ($value =~ /^\s*$/) {
        return undef;
    }

    ## Default
    if ($value eq 'default') {
        $value = $p->{'default'};
    }
    # Lower case if useful.
    $value = lc($value)
        if (defined $p->{'case'} && $p->{'case'} eq 'insensitive');

    ## Do we need to split param if it is not already an array
    if (   ($p->{'occurrence'} =~ /n$/)
        && $p->{'split_char'}
        && !(ref($value) eq 'ARRAY')) {
        my @array = split /$p->{'split_char'}/, $value;
        foreach my $v (@array) {
            $v =~ s/^\s*(.+)\s*$/$1/g;
        }

        return \@array;
    } else {
        return $value;
    }
}

## Simply load a config file and returns a hash.
## the returned hash contains two keys:
## 1- the key 'config' points to a hash containing the data found in the
## config file.
## 2- the key 'numbered_config' points to a hash containing the data found in
## the config file. Each entry contains both the value of a parameter and the
## line where it was found in the config file.
## 3- the key 'errors' contains the number of config entries that could not be
## loaded, due to an error.
## Returns undef if something went wrong while attempting to read the file.
sub _load_config_file_to_hash {
    my $config_file = shift;

    my $line_num = 0;
    # Open the configuration file or return and read the lines.
    my $ifh;
    unless (open $ifh, '<', $config_file) {
        $log->syslog('notice', 'Unable to open %s: %m', $config_file);
        return undef;
    }

    # Initialize result.
    my $result = {
        errors          => 0,
        unknown         => 0,
        config          => {},
        numbered_config => {},
    };

    while (<$ifh>) {
        $line_num++;
        # skip empty or commented lines
        next if (/^\s*$/ || /^[\#;]/);

        # match "keyword value" pattern
        unless (/^(\S+)\s+(.+)$/) {
            $log->syslog('err', 'Error at line %d: %s',
                $line_num, $config_file, $_);
            $result->{errors}++;
            next;
        }
        my ($key, $val) = ($1, $2);
        $val =~ s/\s*$//;

        # Deprecated syntax: `command`
        if ($val =~ /^\`(.*)\`$/) {
            die sprintf
                "%s: Backtick (`...`) in %s is no longer allowed. Check and modify configuration.\n",
                $val, $config_file;
        }

        # Unknown parameter name.
        unless ($params{$key}) {
            $log->syslog('err', 'Line %d, unknown field: %s in %s',
                $line_num, $key, $config_file);
            $result->{unknown}++;
            next;
        }

        # Resolve alias.
        my ($k, $o) = ($key, $key);
        do {
            ($k, $o) = ($o, ($params{$o} // {})->{obsolete});
        } while ($o and $params{$o});
        $key = $k;

        if ($params{$key}->{multiple}    #FIXME: not implemented yet
            or $key eq 'custom_robot_parameter' or $key eq 'listmaster'
        ) {
            if (my $split_char = $params{$key}->{split_char}) {
                my @vals =
                    grep { length $_ } split(/\s*$split_char\s*/, $val);
                $result->{config}{$key} = [@vals];
                $result->{numbered_config}{$key} =
                    [map { [$_, $line_num] } @vals];
            } elsif ($result->{config}{$key}) {
                push @{$result->{config}{$key}}, $val;
                push @{$result->{numbered_config}{$key}}, [$val, $line_num];
            } else {
                $result->{config}{$key} = [$val];
                $result->{numbered_config}{$key} = [[$val, $line_num]];
            }
        } else {
            $result->{config}{$key} = $val;
            $result->{numbered_config}{$key} = [$val, $line_num];
        }
    }
    close $ifh;
    return $result;
}

## Checks a hash containing a sympa config and removes any entry that
## is not supposed to be defined at the robot level.
sub _remove_unvalid_robot_entry {
    my $param       = shift;
    my $config_hash = $param->{'config_hash'};
    foreach my $keyword (keys %$config_hash) {
        unless ($valid_robot_key_words{$keyword}) {
            $log->syslog('err', 'Removing unknown robot keyword %s', $keyword)
                unless ($param->{'quiet'});
            delete $config_hash->{$keyword};
        }
    }
    return 1;
}

# No longer used.
#sub _detect_unknown_parameters_in_config;

sub _infer_server_specific_parameter_values {
    my $param = shift;

    $param->{'config_hash'}{'robot_name'} = '';

    unless (
        Sympa::Tools::Data::smart_eq(
            $param->{'config_hash'}{'dkim_feature'}, 'on'
        )
    ) {
        # dkim_signature_apply_ on nothing if dkim_feature is off
        # Sets empty array.
        $param->{'config_hash'}{'dkim_signature_apply_on'} = [''];
    } else {
        $param->{'config_hash'}{'dkim_signature_apply_on'} =~ s/\s//g;
        my @dkim =
            split(/,/, $param->{'config_hash'}{'dkim_signature_apply_on'});
        $param->{'config_hash'}{'dkim_signature_apply_on'} = \@dkim;
    }
    unless ($param->{'config_hash'}{'dkim_signer_domain'}) {
        $param->{'config_hash'}{'dkim_signer_domain'} =
            $param->{'config_hash'}{'domain'};
    }

    my @dmarc = split /[,\s]+/,
        ($param->{'config_hash'}{'dmarc_protection.mode'} || '');
    if (@dmarc) {
        $param->{'config_hash'}{'dmarc_protection.mode'} = \@dmarc;
    } else {
        delete $param->{'config_hash'}{'dmarc_protection.mode'};
    }

    ## Set Regexp for accepted list suffixes
    if (defined($param->{'config_hash'}{'list_check_suffixes'})) {
        $param->{'config_hash'}{'list_check_regexp'} =
            $param->{'config_hash'}{'list_check_suffixes'};
        $param->{'config_hash'}{'list_check_regexp'} =~ s/[,\s]+/\|/g;
    }

#    my $p = 1;
#    foreach (split(/,/, $param->{'config_hash'}{'sort'})) {
#        $param->{'config_hash'}{'poids'}{$_} = $p++;
#    }
#    $param->{'config_hash'}{'poids'}{'*'} = $p
#        if !$param->{'config_hash'}{'poids'}{'*'};

    ## Parameters made of comma-separated list
    foreach my $parameter (
        'rfc2369_header_fields', 'anonymous_header_fields',
        'remove_headers',        'remove_outgoing_headers'
    ) {
        if ($param->{'config_hash'}{$parameter} eq 'none') {
            delete $param->{'config_hash'}{$parameter};
        } else {
            $param->{'config_hash'}{$parameter} =
                [split(/,/, $param->{'config_hash'}{$parameter})];
        }
    }

    foreach
        my $action (split /\s*,\s*/, $param->{'config_hash'}{'use_blocklist'})
    {
        next unless $action =~ /\A[.\w]+\z/;
        # Compat. <= 6.2.38
        $action = {
            'shared_doc.d_read'   => 'd_read',
            'shared_doc.d_edit'   => 'd_edit',
            'archive.access'      => 'archive_mail_access',    # obsoleted
            'web_archive.access'  => 'archive_web_access',     # obsoleted
            'archive.web_access'  => 'archive_web_access',
            'archive.mail_access' => 'archive_mail_access',
            'tracking.tracking'   => 'tracking',
        }->{$action}
            || $action;

        $param->{'config_hash'}{'blocklist'}{$action} = 1;
    }

    if ($param->{'config_hash'}{'ldap_export_name'}) {
        $param->{'config_hash'}{'ldap_export'} = {
            $param->{'config_hash'}{'ldap_export_name'} => {
                'host'     => $param->{'config_hash'}{'ldap_export_host'},
                'suffix'   => $param->{'config_hash'}{'ldap_export_suffix'},
                'password' => $param->{'config_hash'}{'ldap_export_password'},
                'DnManager' =>
                    $param->{'config_hash'}{'ldap_export_dnmanager'},
                'connection_timeout' =>
                    $param->{'config_hash'}{'ldap_export_connection_timeout'}
            }
        };
    }

    return 1;
}

sub _load_server_specific_secondary_config_files {
    my $param = shift;

    ## wwsympa.conf exists
    if (-f get_wwsympa_conf()) {
        $log->syslog(
            'notice',
            '%s was found but it is no longer loaded.  Please run sympa.pl --upgrade to migrate it',
            get_wwsympa_conf()
        );
    }

    # canonicalize language, or if failed, apply site-wide default.
    $param->{'config_hash'}{'lang'} =
        Sympa::Language::canonic_lang($param->{'config_hash'}{'lang'})
        || 'en-US';

    ## Load charset.conf file if necessary.
    if ($param->{'config_hash'}{'legacy_character_support_feature'} eq 'on') {
        $param->{'config_hash'}{'locale2charset'} = load_charset();
    } else {
        $param->{'config_hash'}{'locale2charset'} = {};
    }

    ## Load nrcpt_by_domain.conf
    $param->{'config_hash'}{'nrcpt_by_domain'} = load_nrcpt_by_domain();
    $param->{'config_hash'}{'crawlers_detection'} =
        load_crawlers_detection($param->{'config_hash'}{'robot_name'});
}

sub _infer_robot_parameter_values {
    my $param = shift;

    # 'domain' is mandatory, and synonym 'host' may be still used
    # even if the doc requires domain.
    $param->{'config_hash'}{'domain'} = $param->{'config_hash'}{'host'}
        if not defined $param->{'config_hash'}{'domain'}
        and defined $param->{'config_hash'}{'host'};

    $param->{'config_hash'}{'static_content_url'} ||=
        $Conf{'static_content_url'};
    $param->{'config_hash'}{'static_content_path'} ||=
        $Conf{'static_content_path'};

    unless ($param->{'config_hash'}{'email'}) {
        $param->{'config_hash'}{'email'} = $Conf{'email'};
    }
    # Obsoleted. Use get_address().
    $param->{'config_hash'}{'sympa'} =
          $param->{'config_hash'}{'email'} . '@'
        . $param->{'config_hash'}{'domain'};
    # Obsoleted. Use get_address('owner').
    $param->{'config_hash'}{'request'} =
          $param->{'config_hash'}{'email'}
        . '-request@'
        . $param->{'config_hash'}{'domain'};

    # split action list for blocklist usage
    foreach my $action (split /\s*,\s*/, $Conf{'use_blocklist'}) {
        next unless $action =~ /\A[.\w]+\z/;
        # Compat. <= 6.2.38
        $action = {
            'shared_doc.d_read'   => 'd_read',
            'shared_doc.d_edit'   => 'd_edit',
            'archive.access'      => 'archive_mail_access',    # obsoleted
            'web_archive.access'  => 'archive_web_access',     # obsoleted
            'archive.web_access'  => 'archive_web_access',
            'archive.mail_access' => 'archive_mail_access',
            'tracking.tracking'   => 'tracking',
        }->{$action}
            || $action;

        $param->{'config_hash'}{'blocklist'}{$action} = 1;
    }

    # Hack because multi valued parameters are not available for Sympa 6.1.
    if (defined $param->{'config_hash'}{'automatic_list_families'}) {
        my @families = split ';',
            $param->{'config_hash'}{'automatic_list_families'};
        my %families_description;
        foreach my $family_description (@families) {
            my %family;
            my @family_parameters = split ':', $family_description;
            foreach my $family_parameter (@family_parameters) {
                my @parameter = split '=', $family_parameter;
                $family{$parameter[0]} = $parameter[1];
            }
            $family{'escaped_prefix_separator'} = $family{'prefix_separator'};
            $family{'escaped_prefix_separator'} =~ s/([+*?.])/\\$1/g;
            $family{'escaped_classes_separator'} =
                $family{'classes_separator'};
            $family{'escaped_classes_separator'} =~ s/([+*?.])/\\$1/g;
            $families_description{$family{'name'}} = \%family;
        }
        $param->{'config_hash'}{'automatic_list_families'} =
            \%families_description;
    }

    # canonicalize language
    $param->{'config_hash'}{'lang'} =
        Sympa::Language::canonic_lang($param->{'config_hash'}{'lang'})
        or delete $param->{'config_hash'}{'lang'};

    _parse_custom_robot_parameters(
        {'config_hash' => $param->{'config_hash'}});
}

sub _load_robot_secondary_config_files {
    my $param = shift;
    my $trusted_applications =
        load_trusted_application($param->{'config_hash'}{'robot_name'});
    $param->{'config_hash'}{'trusted_applications'} = undef;
    if (defined $trusted_applications) {
        $param->{'config_hash'}{'trusted_applications'} =
            $trusted_applications->{'trusted_application'};
    }
    my $robot_name_for_auth_storing = $param->{'config_hash'}{'robot_name'}
        || $Conf{'domain'};
    $Conf{'auth_services'}{$robot_name_for_auth_storing} =
        _load_auth($param->{'config_hash'}{'robot_name'});
    if (defined $param->{'config_hash'}{'automatic_list_families'}) {
        foreach my $family (
            keys %{$param->{'config_hash'}{'automatic_list_families'}}) {
            $param->{'config_hash'}{'automatic_list_families'}{$family}
                {'description'} = load_automatic_lists_description(
                $param->{'config_hash'}{'robot_name'},
                $param->{'config_hash'}{'automatic_list_families'}{$family}
                    {'name'}
                );
        }
    }
    return 1;
}
## For parameters whose value is hard_coded, as per %hardcoded_params, set the
## parameter value to the hardcoded value, whatever is defined in the config.
## Returns a ref to a hash containing the ignored values.
# Deprecated.
#sub _set_hardcoded_parameter_values;

sub _detect_missing_mandatory_parameters {
    my $config_hash = shift;

    my $errors = 0;
    foreach my $key (sort keys %params) {
        next if defined $config_hash->{$key};
        next if $params{$key}->{optional};

        if (defined $params{$key}->{default}) {
            $config_hash->{$key} = $params{$key}->{default};
            next;
        }

        $log->syslog('err', 'Required field not found in sympa.conf: %s',
            $key);
        $errors++;
    }
    return $errors;
}

## Some functionalities activated by some parameter values require that
## some optional CPAN modules are installed. This function checks whether
## these modules are installed and if they are missing, changes the config
## to fall back to a functioning that doesn't require a module and issues
## a warning.
## Returns the number of missing modules.
sub _check_cpan_modules_required_by_config {
    my $param                     = shift;
    my $number_of_missing_modules = 0;

    ## Some parameters require CPAN modules
    if ($param->{'config_hash'}{'dkim_feature'} eq 'on') {
        eval "require Mail::DKIM";
        if ($EVAL_ERROR) {
            $log->syslog('notice',
                'Failed to load Mail::DKIM perl module ; setting "dkim_feature" to "off"'
            );
            $param->{'config_hash'}{'dkim_feature'} = 'off';
            $number_of_missing_modules++;
        }
    }

    return $number_of_missing_modules;
}

sub _dump_non_robot_parameters {
    my $param = shift;
    foreach my $key (keys %{$param->{'config_hash'}}) {
        unless ($valid_robot_key_words{$key}) {
            delete $param->{'config_hash'}{$key};
            $log->syslog('err',
                'Robot %s config: unknown robot parameter: %s',
                $param->{'robot'}, $key);
        }
    }
}

sub _load_single_robot_config {
    my $param = shift;
    my $robot = $param->{'robot'};
    my $robot_conf;

    my $config_err;
    my $config_file = "$Conf{'etc'}/$robot/robot.conf";

    if (my $config_loading_result = _load_config_file_to_hash($config_file)) {
        $robot_conf = $config_loading_result->{'config'};
        $config_err = $config_loading_result->{'errors'};
    } else {
        $log->syslog('err', 'Unable to load %s. Aborting', $config_file);
        return undef;
    }

    # Remove entries which are not supposed to be defined at the robot
    # level.
    _dump_non_robot_parameters(
        {'config_hash' => $robot_conf, 'robot' => $robot});

    #FIXME: They may be no longer used.  Kept for possible compatibility.
    $robot_conf->{'host'}       ||= $robot;
    $robot_conf->{'robot_name'} ||= $robot;

    unless ($robot_conf->{'dkim_signer_domain'}) {
        $robot_conf->{'dkim_signer_domain'} = $robot;
    }

    my @dmarc = split /[,\s]+/,
        ($robot_conf->{'dmarc_protection.mode'} || '');
    if (@dmarc) {
        $robot_conf->{'dmarc_protection.mode'} = \@dmarc;
    } else {
        delete $robot_conf->{'dmarc_protection.mode'};
    }

    _set_listmasters_entry($robot_conf);

    _infer_robot_parameter_values({'config_hash' => $robot_conf});

    _store_source_file_name(
        {'config_hash' => $robot_conf, 'config_file' => $config_file});
    #XXX_save_config_hash_to_binary(
    #XXX    {'config_hash' => $robot_conf, 'source_file' => $config_file});
    return undef if ($config_err);

    _replace_file_value_by_db_value({'config_hash' => $robot_conf})
        unless $param->{'no_db'};
    _load_robot_secondary_config_files({'config_hash' => $robot_conf});
    return $robot_conf;
}

sub _set_listmasters_entry {
    my $config_hash = shift;

    my @values =
        grep {
        if (Sympa::Tools::Text::valid_email($_)) {
            1;
        } else {
            $log->syslog(
                'err',
                'Robot %s config: Listmaster address "%s" is not a valid email',
                $config_hash->{'domain'},
                $_
            );
            0;
        }
        } @{$config_hash->{'listmaster'} // []};

    if (@values) {
        $config_hash->{'listmaster'} = join ',', @values;    #FIXME
    } else {
        delete $config_hash->{'listmaster'};
    }
}

# No longer used.
#sub _check_double_url_usage;

sub _parse_custom_robot_parameters {
    my $param           = shift;
    my $csp_tmp_storage = undef;
    if (defined $param->{'config_hash'}{'custom_robot_parameter'}
        && ref() ne 'HASH') {
        foreach my $custom_p (
            @{$param->{'config_hash'}{'custom_robot_parameter'}}) {
            if ($custom_p =~ /(\S+)\s*\;\s*(.+)/) {
                $csp_tmp_storage->{$1} = $2;
            }
        }
        $param->{'config_hash'}{'custom_robot_parameter'} = $csp_tmp_storage;
    }
}

sub _replace_file_value_by_db_value {
    my $param = shift;
    my $robot = $param->{'config_hash'}{'robot_name'};
    # The name of the default robot is "*" in the database.
    $robot = '*' if ($param->{'config_hash'}{'robot_name'} eq '');
    foreach my $label (keys %db_storable_parameters) {
        next unless ($robot ne '*' && $valid_robot_key_words{$label} == 1);
        my $value = get_db_conf($robot, $label);
        if (defined $value) {
            $param->{'config_hash'}{$label} = $value;
        }
    }
}

# Stores the config hash binary representation to a file.
# Returns 1 or undef if something went wrong.
# No longer used.
#sub _save_binary_cache;

# Loads the config hash binary representation from a file an returns it
# Returns the hash or undef if something went wrong.
# No longer used.
#sub _load_binary_cache;

# No longer used.
#sub _save_config_hash_to_binary;

# No longer used.
#sub _source_has_not_changed;

sub _store_source_file_name {
    my $param = shift;
    $param->{'config_hash'}{'source_file'} = $param->{'config_file'};
}

# No longer used. Use Sympa::search_fullpath().
#sub _get_config_file_name;

sub _create_robot_like_config_for_main_robot {
    return if (defined $Conf::Conf{'robots'}{$Conf::Conf{'domain'}});
    my $main_conf_no_robots = Sympa::Tools::Data::dup_var(\%Conf);
    delete $main_conf_no_robots->{'robots'};
    _remove_unvalid_robot_entry(
        {'config_hash' => $main_conf_no_robots, 'quiet' => 1});
    $Conf{'robots'}{$Conf{'domain'}} = $main_conf_no_robots;
}

sub _get_parameters_names_by_category {
    my $param_by_categories;
    my $current_category;
    foreach my $entry (@Sympa::ConfDef::params) {
        unless ($entry->{'name'}) {
            $current_category = $entry->{'gettext_id'};
        } else {
            $param_by_categories->{$current_category}{$entry->{'name'}} = 1;
        }
    }
    return $param_by_categories;
}

=over 4

=item _load_wwsconf ( FILE )

Load WWSympa configuration file.

=back

=cut

sub _load_wwsconf {
    my $param       = shift;
    my $config_hash = $param->{'config_hash'};
    my $config_file = get_wwsympa_conf();

    return 0 unless -f $config_file;    # this file is optional.

    ## Old params
    my %old_param = (
        'alias_manager' => 'No more used, using '
            . $config_hash->{'alias_manager'},
        'wws_path'  => 'No more used',
        'icons_url' => 'No more used. Using static_content/icons instead.',
        'robots' =>
            'Not used anymore. Robots are fully described in their respective robot.conf file.',
        'task_manager_pidfile' => 'No more used',
        'bounced_pidfile'      => 'No more used',
        'archived_pidfile'     => 'No more used',
    );

    ## Valid params
    my %default_conf =
        map { $_->{'name'} => $_->{'default'} }
        grep { exists $_->{'file'} and $_->{'file'} eq 'wwsympa.conf' }
        @Sympa::ConfDef::params;

    my $conf = \%default_conf;

    my $fh;
    unless (open $fh, '<', $config_file) {
        $log->syslog('err', 'Unable to open %s', $config_file);
        return undef;
    }

    while (<$fh>) {
        next if /^\s*\#/;

        if (/^\s*(\S+)\s+(.+)$/i) {
            my ($k, $v) = ($1, $2);
            $v =~ s/\s*$//;
            if (exists $conf->{$k}) {
                $conf->{$k} = $v;
            } elsif (defined $old_param{$k}) {
                $log->syslog('err',
                    'Parameter %s in %s no more supported: %s',
                    $k, $config_file, $old_param{$k});
            } else {
                $log->syslog('err', 'Unknown parameter %s in %s',
                    $k, $config_file);
            }
        }
        next;
    }

    close $fh;

    ## Check binaries and directories
    if ($conf->{'arc_path'} && (!-d $conf->{'arc_path'})) {
        $log->syslog('err', 'No web archives directory: %s',
            $conf->{'arc_path'});
    }

    if ($conf->{'bounce_path'} && (!-d $conf->{'bounce_path'})) {
        $log->syslog(
            'err',
            'Missing directory "%s" (defined by "bounce_path" parameter)',
            $conf->{'bounce_path'}
        );
    }

    if ($conf->{'mhonarc'} && (!-x $conf->{'mhonarc'})) {
        $log->syslog('err',
            'MHonArc is not installed or %s is not executable',
            $conf->{'mhonarc'});
    }

    ## set default
    $conf->{'log_facility'} ||= $config_hash->{'syslog'};

    foreach my $k (keys %$conf) {
        $config_hash->{$k} = $conf->{$k};
    }
    $wwsconf = $conf;
    return $wwsconf;
}

# MOVED: Use Sympa::WWW::Tools::update_css().
#sub update_css;

# lazy loading on demand
my %mime_types;

# Old name: Sympa::Tools::WWW::get_mime_type().
# FIXME: This would be moved to such as Site package.
sub get_mime_type {
    my $type = shift;

    %mime_types = _load_mime_types() unless %mime_types;

    return $mime_types{$type};
}

# Old name: Sympa::Tools::WWW::load_mime_types().
sub _load_mime_types {
    my %types = ();

    my @localisation = (
        Sympa::search_fullpath('*', 'mime.types'),
        '/etc/mime.types', '/usr/local/apache/conf/mime.types',
        '/etc/httpd/conf/mime.types',
    );

    foreach my $loc (@localisation) {
        my $fh;
        next unless $loc and open $fh, '<', $loc;

        foreach my $line (<$fh>) {
            next if $line =~ /^\s*\#/;
            chomp $line;

            my ($k, $v) = split /\s+/, $line, 2;
            next unless $k and $v and $v =~ /\S/;

            my @extensions = split /\s+/, $v;
            # provides file extention, given the content-type
            if (@extensions) {
                $types{$k} = $extensions[0];
            }
            foreach my $ext (@extensions) {
                $types{$ext} = $k;
            }
        }

        close $fh;
        return %types;
    }

    return;
}

1;
