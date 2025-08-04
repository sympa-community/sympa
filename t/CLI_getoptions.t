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

# PR #1344
dotest('Sympa::CLI::config', {}, [qw(unknown)], qw(config unknown));
dotest('Sympa::CLI::config::create', {}, [qw(unknown)],
    qw(config create unknown));

sub dotest {
    my $wishedClass   = shift;
    my $wishedOptions = shift;
    my $wishedArgv    = shift;
    my @argv          = @_;

    diag join(' ', @argv) =~ s/(.{73}).*/$1.../r;
    my %options;
    my $class = Sympa::CLI->getoptions(\%options, \@argv);

    is $class, $wishedClass, "Class $wishedClass";
    is_deeply \%options, $wishedOptions, sprintf '{%s}',
        join(', ', sort keys %$wishedOptions) =~ s/(.{65}).*/$1.../r;
    is_deeply \@argv, $wishedArgv, sprintf '[%s]',
        join(', ', @$wishedArgv) =~ s/(.{65}).*/$1.../r;
}

done_testing;
