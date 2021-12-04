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
use Getopt::Long qw(:config no_ignore_case);
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
    $module = sprintf '%s::%s', $class, $module;

    unless (eval sprintf 'require %s', $module and $module->isa($class)) {
        printf STDERR "Unable to use %s module: %s\n",
            $module, $EVAL_ERROR || "Not a $class class";
        return undef;
    }

    my %options;
    if (@argv and ref $argv[0] eq 'HASH') {
        %options = %{shift @argv};
    } elsif (grep /^-/, $module->_options) {
        ;
    } elsif (
        not Getopt::Long::GetOptionsFromArray(
            \@argv, \%options,
            qw(config|f=s debug|d lang|l=s log_level=s mail|m),
            $module->_options
        )
    ) {
        printf STDERR "See '%s help %s'\n", $PROGRAM_NAME, join ' ',
            split /::/, ($module =~ s/\ASympa::CLI:://r);
        exit 1;
    }

    if ($module->_need_priv) {
        $module->arrange(%options);
    } else {
        my $lang = $ENV{'LANGUAGE'} || $ENV{'LC_ALL'} || $ENV{'LANG'};
        $module->set_lang($options{'lang'}, $lang);
    }

    my @parsed_argv = ();
    foreach my $argdefs ($module->_args) {
        my $defs = $argdefs;
        my @a;
        if ($defs =~ s/[*]\z//) {
            (@a, @argv) = @argv;
        } elsif ($defs =~ s/[?]\z//) {
            @a = (shift @argv) if @argv;
        } elsif (@argv and defined $argv[0]) {
            @a = (shift @argv);
        } else {
            printf STDERR "Missing %s.\n", $defs;
            exit 1;
        }
        foreach my $arg (@a) {
            my $val;
            foreach my $def (split /[|]/, $defs) {
                if ($def eq 'list') {
                    unless (0 <= index $arg, '@') {
                        $val = Sympa::List->new($arg, $Conf::Conf{'domain'});
                    } elsif ($arg =~ /\A[^\@]+\@[^\@]*\z/) {
                        $val = Sympa::List->new($arg);
                    }
                } elsif ($def eq 'list_id') {
                    unless (0 <= index $arg, '@') {
                        $val = $arg;
                    } elsif ($arg =~ /\A[^\@]+\@[^\@]*\z/) {
                        $val = $arg;
                    }
                } elsif ($def eq 'family') {
                    my ($family_name, $domain) = split /\@\@/, $arg, 2;
                    if (length $family_name) {
                        $val = Sympa::Family->new($family_name,
                            $domain || $Conf::Conf{'domain'});
                    }
                } elsif ($def eq 'domain') {
                    if (length $arg and Conf::valid_robot($arg)) {
                        $val = $arg;
                    }
                } elsif ($def eq 'site') {
                    if ($arg eq '*') {
                        $val = $arg;
                    }
                } else {
                    $val = $arg;
                }
                last if defined $val;
            }
            if (defined $val) {
                push @parsed_argv, $val;
            } else {
                printf STDERR "Unknown %s \"%s\".\n", $defs, $arg;
                exit 1;
            }
        }
    }

    $module->_run(\%options, @parsed_argv, @argv);
}

sub _options       { () }
sub _args          { () }
sub _need_priv     {1}
sub _log_to_stderr {0}

my $is_arranged;

sub arrange {
    my $class   = shift;
    my %options = @_;

    return if $is_arranged;

    # Init random engine
    srand time;

    my $mailer = Sympa::Mailer->instance;
    my $log    = Sympa::Log->instance;

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

    $class->set_lang($options{'lang'}, $Conf::Conf{'lang'});

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

    $is_arranged = 1;
}

sub set_lang {
    my $class = shift;
    my @langs = @_;

    foreach (@langs) {
        s/[.].*\z// if defined;    # Compat.<2.3.3 & some POSIX locales
    }
    Sympa::Language->instance->set_lang(@langs, 'en-US', 'en');
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

# Translate warnings if possible.

my @getoptions_messages = (
    {gettext_id => 'Value "%s" invalid for option %s'},
    {gettext_id => 'Insufficient arguments for option %s'},
    {gettext_id => 'Duplicate specification "%s" for option "%s"'},
    {gettext_id => 'Option %s is ambiguous (%s)'},
    {gettext_id => 'Missing option after %s'},
    {gettext_id => 'Unknown option: %s'},
    {gettext_id => 'Option %s does not take an argument'},
    {gettext_id => 'Option %s requires an argument'},
    {gettext_id => 'Option %s, key "%s", requires a value'},
    {gettext_id => 'Value "%s" invalid for option %s (number expected)'},
    {   gettext_id =>
            'Value "%s" invalid for option %s (extended number expected)'
    },
    {gettext_id => 'Value "%s" invalid for option %s (real number expected)'},
);

sub _translate_warn {
    my $output = shift;

    my $language = Sympa::Language->instance;
    foreach my $item (@getoptions_messages) {
        my $format = $item->{'gettext_id'};
        my $regexp = quotemeta $format;
        $regexp =~ s/\\\%[sd]/(.+)/g;

        my ($match, @args) = ($output =~ /\A($regexp)\s*\z/i);
        next unless $match;
        return $language->gettext_sprintf($format, @args) . "\n";
    }
    return $output;
}

$SIG{__WARN__} = sub { warn _translate_warn(shift) };

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

