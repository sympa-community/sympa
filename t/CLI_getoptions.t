# -*- indent-tabs-mode: nil; -*-
# # vim:ft=perl:et:sw=4

use strict;
use warnings;
use Test::More;

use Sympa::CLI;

# Option and its alias(es)
dotest('Sympa::CLI::config::show', {config => '<path_to_config>'},
    [], qw(config show --config=<path_to_config>));
dotest('Sympa::CLI::config::show', {config => '<path_to_config>'},
    [], qw(config show -f <path_to_config>));
dotest(
    'Sympa::CLI::config',
    {output => ['minimal']},
    [qw(dmarc_protection.mode=dmarc_reject)],
    qw(config -o minimal dmarc_protection.mode=dmarc_reject)
);
dotest(
    'Sympa::CLI::config',
    {output => ['minimal']},
    [qw(dmarc_protection.mode=dmarc_reject)],
    qw(config --output=minimal dmarc_protection.mode=dmarc_reject)
);
dotest(
    'Sympa::CLI::config',
    {output => ['minimal', 'full']},
    [qw(dmarc_protection.mode=dmarc_reject)],
    qw(config -o minimal -o full dmarc_protection.mode=dmarc_reject)
);

# Hyphens and underscores.
dotest(
    'Sympa::CLI::upgrade::outgoing',
    {dry_run => 1},
    [], qw(upgrade outgoing --dry-run)
);
dotest(
    'Sympa::CLI::upgrade::outgoing',
    {dry_run => 1},
    [], qw(upgrade outgoing --dry_run)
);
dotest(
    'Sympa::CLI::upgrade::outgoing',
    {dry_run => 1},
    [], qw(upgrade outgoing -n)
);

dotest('Sympa::CLI::create', {input_file => '<path_to_input>'},
    [], qw(create --input-file=<path_to_input>));
dotest('Sympa::CLI::create', {input_file => '<path_to_input>'},
    [], qw(create --input-file <path_to_input>));
dotest('Sympa::CLI::create', {input_file => '<path_to_input>'},
    [], qw(create --input_file=<path_to_input>));

# PR #1344
dotest('Sympa::CLI::config', {}, [qw(unknown)], qw(config unknown));
dotest('Sympa::CLI::config::create', {}, [qw(unknown)],
    qw(config create unknown));

# Issue #1966
dotest('Sympa::CLI::add', {config => '<path_to_config>', force => 1},
    [qw(mylist@example.org)],
    qw(add -F -f <path_to_config> mylist@example.org));

# Unknown options
dotest(undef, {}, [qw(config create --unknown)], qw(config create --unknown));

sub dotest {
    my $wishedClass   = shift;
    my $wishedOptions = shift;
    my $wishedArgv    = shift;
    my @argv          = @_;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    note join(' ', @_) =~ s/(.{73}).*/$1.../r;
    my ($class, %options) = Sympa::CLI->getoptions(undef, \@argv);
    is $class, $wishedClass, $wishedClass;
    is_deeply \%options, $wishedOptions,
        join('', explain $wishedOptions) =~ s/\n\s*//gr;
    is_deeply \@argv, $wishedArgv,
        join('', explain $wishedArgv) =~ s/\n\s*//gr;

    note map { '  ' . $_ } @warnings if @warnings;
}

done_testing;
