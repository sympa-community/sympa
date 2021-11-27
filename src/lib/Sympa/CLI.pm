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

package Sympa::CLI;

use strict;
use warnings;
use English qw(-no_match_vars);
use Getopt::Long qw();
use POSIX qw();

use Conf;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Template;
use Sympa::Tools::Data;

sub run {
    my $class  = shift;
    my $module = shift;
    my @argv   = @_;

    unless ($module and $module !~ /\W/) {
        print STDERR "Unable to use %s module: Illegal module\n";
        return undef;
    }
    $module = "Sympa::CLI::$module";

    unless (eval sprintf 'require %s', $module and $module->isa('Sympa::CLI'))
    {
        printf STDERR "Unable to use %s module: %s\n",
            ($module, $EVAL_ERROR || 'Not a Sympa::CLI class');
        return undef;
    }

    my %options;
    if (ref $argv[0]) {
        %options = %{shift @argv};
    } else {
        exit 1
            unless Getopt::Long::GetOptionsFromArray(\@argv, \%options,
            'config|f=s', 'debug|d', 'lang|l=s', 'log_level=s', 'mail|m',
            $module->_options);
    }
    $module->arrange(%options)
        if $module->_arranged;

    $module->_run(\%options, @argv);
}

sub _options       { () }
sub _arranged      {1}
sub _log_to_stderr {0}

sub arrange {
    my $class   = shift;
    my %options = @_;

    # Init random engine
    srand time;

    my $language = Sympa::Language->instance;
    my $mailer   = Sympa::Mailer->instance;
    my $log      = Sympa::Log->instance;

    $log->{log_to_stderr} = 'notice,err'
        if $class->_log_to_stderr;

    #_load();
    ## Load sympa.conf.

    unless (Conf::load($options{config}, 'no_db')) {    #Site and Robot
        die sprintf
            "Unable to load sympa configuration, file %s or one of the vhost robot.conf files contain errors. Exiting.\n",
            ($options{config} || Conf::get_sympa_conf());
    }

    ## Open the syslog and say we're read out stuff.
    $log->openlog($Conf::Conf{'syslog'}, $Conf::Conf{'log_socket_type'});

    # Enable SMTP logging if required
    $mailer->{log_smtp} = $options{'mail'}
        || Sympa::Tools::Data::smart_eq($Conf::Conf{'log_smtp'}, 'on');

    # setting log_level using conf unless it is set by calling option
    if ($options{'debug'}) {
        $options{'log_level'} = 2 unless $options{'log_level'};
    }
    if (defined $options{'log_level'}) {
        $log->{level} = $options{'log_level'};
        $log->syslog('info',
            'Configuration file read, log level set using options: %s',
            $options{'log_level'});
    } else {
        $log->{level} = $Conf::Conf{'log_level'};
        $log->syslog(
            'info',
            'Configuration file read, default log level %s',
            $Conf::Conf{'log_level'}
        );
    }

    # Check database connectivity.
    unless (Sympa::DatabaseManager->instance) {
        die sprintf
            "Database %s defined in sympa.conf is unreachable. verify db_xxx parameters in sympa.conf\n",
            $Conf::Conf{'db_name'};
    }

    # Now trying to load full config (including database)
    unless (Conf::load()) {    #FIXME: load Site, then robot cache
        die sprintf
            "Unable to load Sympa configuration, file %s or any of the virtual host robot.conf files contain errors. Exiting.\n",
            Conf::get_sympa_conf();
    }

    ## Set locale configuration
    ## Compatibility with version < 2.3.3
    $options{'lang'} =~ s/\.cat$//
        if defined $options{'lang'};
    my $default_lang =
        $language->set_lang($options{'lang'}, $Conf::Conf{'lang'}, 'en');

    ## Main program
    if (!chdir($Conf::Conf{'home'})) {
        die sprintf 'Can\'t chdir to %s: %s', $Conf::Conf{'home'}, $ERRNO;
        ## Function never returns.
    }

    ## Check for several files.
    unless (Conf::checkfiles_as_root()) {
        die "Missing files\n";
    }

    # end _load()

    $log->openlog($Conf::Conf{'syslog'}, $Conf::Conf{'log_socket_type'});

    # Set the User ID & Group ID for the process
    $GID = $EGID = (getgrnam(Sympa::Constants::GROUP))[2];
    $UID = $EUID = (getpwnam(Sympa::Constants::USER))[2];

    ## Required on FreeBSD to change ALL IDs
    ## (effective UID + real UID + saved UID)
    POSIX::setuid((getpwnam(Sympa::Constants::USER))[2]);
    POSIX::setgid((getgrnam(Sympa::Constants::GROUP))[2]);

    ## Check if the UID has correctly been set (useful on OS X)
    unless (($GID == (getgrnam(Sympa::Constants::GROUP))[2])
        && ($UID == (getpwnam(Sympa::Constants::USER))[2])) {
        die
            "Failed to change process user ID and group ID. Note that on some OS Perl scripts can't change their real UID. In such circumstances Sympa should be run via sudo.\n";
    }

    # Sets the UMASK
    umask(oct($Conf::Conf{'umask'}));

    ## Most initializations have now been done.
    $log->syslog('notice', 'Sympa %s Started', Sympa::Constants::VERSION());

    # Check for several files.
    #FIXME: This would be done in --health_check mode.
    unless (Conf::checkfiles()) {
        die "Missing files.\n";
        ## No return.
    }
}

sub _report {
    my $class   = shift;
    my $spindle = shift;

    my @reports = @{$spindle->{stash} || []};
    @reports = ([undef, 'notice', 'performed']) unless @reports;

    my $template = Sympa::Template->new('*', subdir => 'mail_tt2');
    foreach my $report (@reports) {
        my ($request, $report_type, $report_entry, $report_param) = @$report;
        my $action = $request ? $request->{action} : 'sympa';
        my $message = '';
        $template->parse(
            {   report_type  => $report_type,
                report_entry => $report_entry,
                report_param => ($report_param || {}),
            },
            'report.tt2',
            \$message
        );
        $message ||= $report_entry;
        $message =~ s/\n/ /g;

        printf STDERR "%s [%s] %s\n", $action, $report_type, $message;
    }

    return $spindle->success ? 1 : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::CLI - Base class of Sympa CLI modules

=head1 SYNOPSIS

TBD.

=head1 DESCRIPTION

TBD.

=head1 HISTORY

L<Sympa::CLI> appeared on Sympa 6.2.68.

=cut

