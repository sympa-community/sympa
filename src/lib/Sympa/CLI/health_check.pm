# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021 The Sympa Community. See the
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

package Sympa::CLI::health_check;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::DatabaseManager;
use Sympa::Log;

use parent qw(Sympa::CLI);

my $log = Sympa::Log->instance;

use constant _options  => qw();
use constant _arranged => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

#} elsif ($options->{health_check}) {
    ## Health check

    ## Load configuration file. Ignoring database config for now: it avoids
    ## trying to load a database that could not exist yet.
    unless (Conf::load(Conf::get_sympa_conf(), 'no_db')) {
        #FIXME: force reload
        die sprintf
            "Configuration file %s has errors.\n",
            Conf::get_sympa_conf();
    }

    ## Open the syslog and say we're read out stuff.
    $log->openlog(
        $Conf::Conf{'syslog'},
        $Conf::Conf{'log_socket_type'},
        service => 'sympa/health_check'
    );

    ## Setting log_level using conf unless it is set by calling option
    #FIXME: Redundant code?
    if ($options->{log_level}) {
        $log->{level} = $options->{log_level};
        $log->syslog('info',
            'Configuration file read, log level set using options: %s',
            $options->{log_level});
    } else {
        $log->{level} = $Conf::Conf{'log_level'};
        $log->syslog(
            'info',
            'Configuration file read, default log level %s',
            $Conf::Conf{'log_level'}
        );
    }

    ## Check if db_type is not the boilerplate one
    if ($Conf::Conf{'db_type'} eq '(You must define this parameter)') {
        die sprintf
            "Database type \"%s\" defined in sympa.conf is the boilerplate one and obviously incorrect. Verify db_xxx parameters in sympa.conf\n",
            $Conf::Conf{'db_type'};
    }

    ## Preliminary check of db_type
    unless ($Conf::Conf{'db_type'} and $Conf::Conf{'db_type'} =~ /\A\w+\z/) {
        die sprintf
            "Database type \"%s\" defined in sympa.conf seems incorrect. Verify db_xxx parameters in sympa.conf\n",
            $Conf::Conf{'db_type'};
    }

    ## Check database connectivity and probe database
    unless (Sympa::DatabaseManager::probe_db()) {
        die sprintf
            "Database %s defined in sympa.conf has not the right structure or is unreachable. Verify db_xxx parameters in sympa.conf\n",
            $Conf::Conf{'db_name'};
    }

    ## Now trying to load full config (including database)
    unless (Conf::load()) {    #FIXME: load Site, then robot cache
        die sprintf
            "Unable to load Sympa configuration, file %s or any of the virtual host robot.conf files contain errors. Exiting.\n",
            Conf::get_sympa_conf();
    }

    ## Change working directory.
    if (!chdir($Conf::Conf{'home'})) {
        printf STDERR "Can't chdir to %s: %s\n", $Conf::Conf{'home'}, $ERRNO;
        exit 1;
    }

    ## Check for several files.
    unless (Conf::checkfiles_as_root()) {
        printf STDERR "Missing files.\n";
        exit 1;
    }

    ## Check that the data structure is uptodate
    unless (Conf::data_structure_uptodate()) {
        printf STDOUT
            "Data structure was not updated; you should run sympa.pl --upgrade to run the upgrade process.\n";
    }

    exit 0;
}
1;
