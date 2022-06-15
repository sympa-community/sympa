# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021, 2022 The Sympa Community. See the
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
BEGIN { eval 'use Encode::Locale'; }

use Conf;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::Family;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Template;
use Sympa::Tools::Data;

my $language = Sympa::Language->instance;

sub run {
    my $class   = shift;
    my $options = shift if @_ and ref $_[0] eq 'HASH';
    my @argv    = @_;

    if ($class eq 'Sympa::CLI') {
        $class->istty;

        # Detect console encoding.
        if ($Encode::Locale::VERSION) {
            unless ('ascii' eq
                Encode::resolve_alias($Encode::Locale::ENCODING_CONSOLE_IN)) {
                if ($class->istty(0)) {
                    binmode(STDIN, ':encoding(console_in):bytes');
                    foreach my $arg (@argv) {
                        Encode::from_to($arg,
                            $Encode::Locale::ENCODING_CONSOLE_IN, 'utf-8');
                    }
                }
            }
            unless ('ascii' eq
                Encode::resolve_alias($Encode::Locale::ENCODING_CONSOLE_OUT))
            {
                binmode(STDOUT, ':encoding(console_out):bytes')
                    if $class->istty(1);
                binmode(STDERR, ':encoding(console_out):bytes')
                    if $class->istty(2);
            }
        }

        # Deal with some POSIX locales (LL_cc.encoding)
        my @langs =
            map {s/[.].*\z//r} grep {defined} @ENV{qw(LANGUAGE LC_ALL LANG)};
        $language->set_lang(@langs, 'en-US', 'en');
    }

    if (@argv and ($argv[0] // '') =~ /\A\w+\z/) {
        # Check if (sub-)command is implemented.
        my $dir = $INC{($class =~ s|::|/|gr) . '.pm'} =~ s/[.]pm\z//r;
        if (-e "$dir/$argv[0].pm") {
            # Load module for the command.
            my $command = shift @argv;
            my $subclass = sprintf '%s::%s', $class, $command;
            unless (eval(sprintf 'require %s', $subclass)
                and $subclass->isa($class)) {
                warn $language->gettext_sprintf('Invalid command \'%s\'',
                    $command)
                    . "\n";
                return undef;
            }
            return $subclass->run(($options ? ($options) : ()), @argv);
        }
    }
    if ($class eq 'Sympa::CLI') {
        # No valid main command.
        warn $language->gettext_sprintf(
            'Invalid argument \'%s\' (command is expected)',
            ($argv[0] // ''))
            . "\n";
        return undef;
    }

    # Parse options if necessary.
    my %options;
    if ($options) {
        %options = %$options;
    } elsif (grep /^-/, $class->_options) {
        ;
    } elsif (
        not Getopt::Long::GetOptionsFromArray(
            \@argv, \%options,
            qw(config|f=s debug|d lang|l=s log_level=s mail|m),
            $class->_options
        )
    ) {
        warn $language->gettext_sprintf('See \'%s help %s\'',
            $PROGRAM_NAME, join ' ', split /::/,
            ($class =~ s/\ASympa::CLI:://r))
            . "\n";
        return undef;
    }

    # Get privileges and load config if necessary.
    # Otherwise only setup language if specified.
    $language->set_lang($options{lang}) if $options{lang};
    $class->arrange(%options) if $class->_need_priv;

    # Parse arguments.
    my @parsed_argv = ();
    foreach my $argdefs ($class->_args) {
        my $defs = $argdefs;
        my @a;
        if ($defs =~ s/[*]\z//) {
            (@a, @argv) = @argv;
        } elsif ($defs =~ s/[?]\z//) {
            @a = (shift @argv) if @argv;
        } elsif (@argv and defined $argv[0]) {
            @a = (shift @argv);
        } else {
            warn $language->gettext_sprintf('Missing argument (%s)',
                _arg_expected($defs))
                . "\n";
            return undef;
        }
        foreach my $arg (@a) {
            my $val;
            foreach my $def (split /[|]/, $defs) {
                if ($def eq 'list') {
                    if (index($arg, '@') < 0 and index($defs, 'domain') < 0) {
                        $val = Sympa::List->new($arg, $Conf::Conf{'domain'},
                            {just_try => 1});
                    } elsif ($arg =~ /\A([^\@]+)\@([^\@]*)\z/) {
                        my ($name, $domain) = ($1, $2);
                        $val = Sympa::List->new(
                            $name,
                            $domain || $Conf::Conf{'domain'},
                            {just_try => 1}
                        );
                    }
                } elsif ($def eq 'list_id') {
                    if (index($arg, '@') < 0 and index($defs, 'domain') < 0) {
                        $val = $arg;
                    } elsif ($arg =~ /\A[^\@]+\@[^\@]*\z/) {
                        $val = $arg;
                    }
                } elsif ($def eq 'family') {
                    if (index($arg, '@@') < 0 and index($defs, 'domain') < 0)
                    {
                        $val =
                            Sympa::Family->new($arg, $Conf::Conf{'domain'});
                    } elsif ($arg =~ /\A([^\@]+)\@\@([^\@]*)\z/) {
                        my ($name, $domain) = ($1, $2);
                        $val = Sympa::Family->new($name,
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
                } elsif ($def eq 'keyvalue') {
                    if ($arg =~ /\A(\w+)=(.*)\z/) {
                        $val = [$1 => $2];
                    }
                } else {
                    $val = $arg;
                }
                last if defined $val;
            }
            if (defined $val) {
                push @parsed_argv, $val;
            } else {
                warn $language->gettext_sprintf(
                    'Invalid argument \'%s\' (%s)',
                    $arg, _arg_expected($defs))
                    . "\n";
                return undef;
            }
        }
    }

    $class->_run(\%options, @parsed_argv, @argv);
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

    $Conf::sympa_config = $options{config};    #FIXME

    my $mailer = Sympa::Mailer->instance;
    my $log    = Sympa::Log->instance;

    $log->{log_to_stderr} = 'notice,err'
        if $class->_log_to_stderr;

    # Moved from: _load() in sympa.pl.
    ## Load sympa.conf.

    unless (Conf::load(undef, 'no_db')) {
        die sprintf
            "Unable to load sympa configuration, file %s or one of the vhost robot.conf files contain errors. Exiting.\n",
            Conf::get_sympa_conf();
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
    unless (Conf::load()) {
        die sprintf
            "Unable to load Sympa configuration, file %s or any of the virtual host robot.conf files contain errors. Exiting.\n",
            Conf::get_sympa_conf();
    }

    $language->set_lang($Conf::Conf{'lang'}) unless $options{lang};

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

my @istty;

sub istty {
    my $class = shift;

    unless (@_) {    # Get tty-nesses.
        @istty = (-t STDIN, -t STDOUT, -t STDERR);
    } else {
        return $istty[$_[0]];
    }
}

# Moved from: _report() in sympa.pl.
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

        warn sprintf "%s [%s] %s\n", $action, $report_type, $message;
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

my $arg_labels = {
    list    => {gettext_id => 'list'},
    list_id => {gettext_id => 'list'},
    family  => {gettext_id => 'family'},
    domain  => {gettext_id => 'domain'},
    site    => {gettext_id => '"*"'},
    command => {gettext_id => 'command'},
    string  => {gettext_id => 'string'},
    email   => {gettext_id => 'email address'},
    keyvalue => {gettext_id => '"key=value"'},
};

sub _arg_expected {
    my $defs = shift;

    my @labels = map {
              $arg_labels->{$_}
            ? $language->gettext($arg_labels->{$_}->{gettext_id})
            : $_
    } split /[|]/, ($defs =~ s/[?*]\z//r);
    if (3 == scalar @labels) {
        return $language->gettext_sprintf('%s, %s or %s is expected',
            @labels);
    } elsif (2 == scalar @labels) {
        return $language->gettext_sprintf('%s or %s is expected', @labels);
    } else {
        return $language->gettext_sprintf('%s is expected',
            join(', ', @labels));
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::CLI - Base class of Sympa CLI modules

=head1 SYNOPSIS

  package Sympa::CLI::mycommand;
  use parent qw(Sympa::CLI);
  
  use constant _options   => qw(...);
  use constant _args      => qw(...);
  use constant _need_priv => 0;
  
  sub _run {
      my $class   = shift;
      my $options = shift;
      my @argv    = @_;
  
      #... Do the job...
      exit 0;
  }

This will implement the function of F<sympa mycommand>.

=head1 DESCRIPTION

L<Sympa::CLI> is the base class of the classes which defines particular
command of command line utility.
TBD.

=head2 Methods subclass should implement

=over

=item _options ( )

I<Class method>, I<overridable>.
Returns an array to define command line options.
About the format see L<Getopt::Long/Summary of Option Specifications>.

By default no options are defined.

=item _args ( )

I<Class method>, I<overridable>.
Returns an array to define mandatory arguments.
TBD.

By default no mandatory arguments are defined.

=item _need_priv ( )

I<Class method>, I<overridable>.
If this returns true value (the default), the program tries getting privileges
of Sympa user, prepare database connection, loading main configuration
and then setting language according to configuration.
Otherwise, it sets language according to locale setting of console.

=item _log_to_stderr ( )

I<Class method>, I<overridable>.
If this returns true value, output by logging facility will be redirected
to standard error output (stderr).

By default redirection is disabled.

=item _run ( \$options, @argv )

I<Class method>, I<mandatory>.
If the program is invoked, command line options are parsed as _options()
defines, arguments are checked as _args() defines and this method is called.

=back

=head2 Subcommands

To implement a subcommand, simply create a submodule inheriting the module
for parent command:

  package Sympa::CLI::mycommand::subcommand;
  use parent qw(Sympa::CLI::mycommand);
  ...

Then this will implement the function of F<sympa mycommand subcommand>.

=head1 SEE ALSO

L<sympa(1)>.

=head1 HISTORY

L<Sympa::CLI> appeared on Sympa 6.2.68.

=cut

