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
use POSIX qw();

use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Language;
use Sympa::Tools::Data;

use parent qw(Sympa::CLI);

use constant _options   => qw(output|o=s@);
use constant _args      => qw(keyvalue*);
use constant _need_priv => 0;

my $language = Sympa::Language->instance;

sub _run {
    my $class   = shift;
    my $options = shift;
    my @argv    = @_;

    my %newConf;
    foreach my $arg (@argv) {
        # Check for key/values settings.
        last unless ref $arg eq 'ARRAY';
        my ($key, $val) = @$arg;

        # FIXME: Resolve parameter aliase names.
        $newConf{$key} = $val;
    }
    if (%newConf) {
        my $curConf = _load();
        return undef unless $curConf;

        my $out = Sympa::Tools::Data::format_config(
            [@Sympa::ConfDef::params],
            $curConf, \%newConf,
            only_changed => 1,
            filter => ([@{$options->{output} // []}, qw(explicit mandatory)])
        );
        die "Not changed.\n" unless defined $out;

        my $sympa_conf = Sympa::Constants::CONFIG();
        my $date = POSIX::strftime('%Y%m%d%H%M%S', localtime time);

        ## Keep old config file
        unless (rename $sympa_conf, $sympa_conf . '.' . $date) {
            warn $language->gettext_sprintf('Unable to rename %s : %s',
                $sympa_conf, $ERRNO);
        }

        # Write new config file.
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

        print $ofh $out;
        close $ofh;

        print $language->gettext_sprintf(
            "%s have been updated.\nPrevious versions have been saved as %s.\n",
            $sympa_conf, "$sympa_conf.$date"
        );
        return 1;
    }

    Sympa::CLI->run(qw(help config));
}

# Old name: edit_configuragion() in sympa_wizard.pl.
# Obsoleted: Use Sympa::Tools::Data::format_config().
#sub _edit_configuration;

sub _load {
    my $sympa_conf = shift || Sympa::Constants::CONFIG();

    #FIXME: Refactor Conf.
    my $res = Conf::_load_config_file_to_hash($sympa_conf);
    return undef unless $res;
    return $res->{config};
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

If no explicit changes given, configuration file won't be rewritten.

Options:

=over

=item C<-o>, C<--output=>I<set> ...

Specify set(s) of parameters to be output.
I<set> may be either C<omittable>, C<optional>, C<mandatory>,
C<full> (synonym for the former three), C<explicit> or C<minimal>.
This option can be specified more than once.

With this command, C<explicit> and C<mandatory> sets,
i.e. those defined in the configuration file explicitly,
specified in command line arguments or defined as mandatory,
are always included.

=back

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
