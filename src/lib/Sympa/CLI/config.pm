# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
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

package Sympa::CLI::config;

use strict;
use warnings;
use English qw(-no_match_vars);
use Sys::Hostname qw();

use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Language;

use parent qw(Sympa::CLI);

use constant _options   => qw();
use constant _args      => qw();
use constant _need_priv => 0;

my $language = Sympa::Language->instance;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    my %user_param;
    foreach my $arg (@argv) {
        # Check for key/values settings
        if ($arg =~ /\A(\w+)=(.+)/) {
            $user_param{$1} = $2;
        } else {
            die "$0: Invalid commandline argument: $arg\n";
        }
    }
    if (%user_param) {
        return _edit_configuration($options, %user_param);
    }

    Sympa::CLI->run(qw(help config));
}

# Old name: edit_configuragion() in sympa_wizard.pl.
sub _edit_configuration {
    my $options    = shift;
    my %user_param = @_;

    die "$0: You must run as superuser.\n"
        if $UID;

    # complement required fields.
    foreach my $param (@Sympa::ConfDef::params) {
        next if $param->{obsolete};
        next unless $param->{'name'};
        if ($param->{'name'} eq 'domain') {
            $param->{'default'} = Sys::Hostname::hostname();
        } elsif ($param->{'name'} eq 'wwsympa_url') {
            $param->{'default'} = sprintf 'http://%s/sympa',
                Sys::Hostname::hostname();
        } elsif ($param->{'name'} eq 'listmaster') {
            $param->{'default'} = sprintf 'your_email_address@%s',
                Sys::Hostname::hostname();
        }
    }

    ## Load sympa config (but not using database)
    unless (defined Conf::load(undef, 1)) {
        die sprintf
            "%s: Unable to load sympa configuration, file %s or one of the virtual host robot.conf files contain errors. Exiting.\n",
            $PROGRAM_NAME, Sympa::Constants::CONFIG();
    }

    my $somechange = 0;

    my @new_sympa_conf;
    my $title = undef;

    # dynamic defaults
    my $domain    = Sys::Hostname::hostname();
    my $http_host = "http://$domain";

    ## Edition mode
    foreach my $param (@Sympa::ConfDef::params) {
        next if $param->{obsolete};

        unless ($param->{'name'}) {
            $title = $language->gettext($param->{'gettext_id'})
                if $param->{'gettext_id'};
            next;
        }

        #my $file  = $param->{'file'};
        my $name = $param->{'name'};
        my $query = $param->{'gettext_id'} || '';
        $query = $language->gettext($query) if $query;
        my $advice = $param->{'gettext_comment'};
        $advice = $language->gettext($advice) if $advice;
        my $sample = $param->{'sample'};
        my $current_value;

        #next unless $file;
        #if ($file eq 'sympa.conf' or $file eq 'wwsympa.conf') {
        #    $current_value = $Conf::Conf{$name};
        #    $current_value = '' unless defined $current_value;
        #} else {
        #    next;
        #}
        $current_value = $Conf::Conf{$name} // '';

        if ($title) {
            ## write to conf file
            push @new_sympa_conf,
                sprintf "###\\\\\\\\ %s ////###\n\n", $title;
        }

        my $new_value = '';
        if (exists $user_param{$name}) {
            $new_value = $user_param{$name};
        }
        if ($new_value eq '') {
            $new_value = $current_value;
        }

        undef $title;

        ## Skip empty parameters
        next if $new_value eq '' and !$sample;

        ## param is an ARRAY
        if (ref($new_value) eq 'ARRAY') {
            $new_value = join ',', @{$new_value};
        }

        #unless ($file eq 'sympa.conf' or $file eq 'wwsympa.conf') {
        #    warn $language->gettext_sprintf("Incorrect parameter definition: %s\n",
        #        $file);
        #}

        if ($new_value eq '') {
            next unless $sample;

            push @new_sympa_conf,
                Sympa::Tools::Text::wrap_text($query, '## ', '## ');

            if (defined $advice and length $advice) {
                push @new_sympa_conf,
                    Sympa::Tools::Text::wrap_text($advice, '## ', '## ');
            }

            push @new_sympa_conf, "# $name\t$sample\n\n";
        } else {
            push @new_sympa_conf,
                Sympa::Tools::Text::wrap_text($query, '## ', '## ');
            if (defined $advice and length $advice) {
                push @new_sympa_conf,
                    Sympa::Tools::Text::wrap_text($advice, '## ', '## ');
            }

            if ($current_value ne $new_value) {
                push @new_sympa_conf, "# was $name $current_value\n";
                $somechange = 1;
            }

            push @new_sympa_conf, "$name\t$new_value\n\n";
        }
    }

    if ($somechange) {
        my @time = localtime time;
        my $date = sprintf '%d%02d%02d%02d%02d%02d',
            $time[5] + 1900, $time[4] + 1, @time[3, 2, 1, 0];
        my $sympa_conf = Sympa::Constants::CONFIG();

        ## Keep old config file
        unless (rename $sympa_conf, $sympa_conf . '.' . $date) {
            warn $language->gettext_sprintf('Unable to rename %s : %s',
                $sympa_conf, $ERRNO);
        }

        ## Write new config file
        my $umask = umask 037;
        my $ofh;
        unless (open $ofh, '>', $sympa_conf) {
            umask $umask;
            die "$0: "
                . $language->gettext_sprintf('Unable to open %s : %s',
                $sympa_conf, $ERRNO)
                . "\n";
        }
        umask $umask;
        chown [getpwnam(Sympa::Constants::USER)]->[2],
            [getgrnam(Sympa::Constants::GROUP)]->[2], $sympa_conf;

        print $ofh @new_sympa_conf;
        close $ofh;

        print $language->gettext_sprintf(
            "%s have been updated.\nPrevious versions have been saved as %s.\n",
            $sympa_conf, "$sympa_conf.$date"
        );
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-config - Manipulate configuration of Sympa

=head1 SYNOPSIS

C<sympa config> I<name>=I<value> ...

C<sympa config> I<sub-command> [ I<options> ... ]

=head1 DESCRIPTION

=over

=item C<sympa> C<config> I<name>C<=>I<value> ...

Edit configuration file in batch mode.
Arguments would include pairs of parameter name and value.

=back

=head2 SUB-COMMANDS

Currently following sub-commands are available.
To see detail of each sub-command,
run 'C<sympa help config> I<sub-command>'.

=over

=item L<C<sympa config create> ...|sympa-config-create(1)>

Create configuration file.

=item L<C<sympa config show> ...|sympa-config-show(1)>

Show the content of configuration file.

=back

=head1 HISTORY

L<sympa_wizard.pl> appeared on Sympa 3.3.4b.9.
It was originally written by:

=over 4

=item Serge Aumont <sa@cru.fr>

=item Olivier SalaE<252>n <os@cru.fr>

=back

C<--batch> and C<--display> options are added on Sympa 6.1.25 and 6.2.15.

On Sympa 6.2.69b, the most of functions provided by this program was
reorganized and was integrated into C<sympa config> command line,
therefore sympa_wizard.pl was deprecated.

=cut
