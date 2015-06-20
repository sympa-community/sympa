# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use lib qw(src/lib);
use strict;
use warnings;
use CPAN::Meta '2.00';

use Sympa::Constants;
use Sympa::ModDef;

my $struct = {
    # Required fields
    abstract       => 'Sympa is a powerful multilingual List Manager',
    author         => ['Sympa authors <sympa-authors@listes.renater.fr>'],
    dynamic_config => 0,
    license        => [qw(gpl_2 gpl_3)],
    name           => 'sympa',
    release_status => '',                            # See below
    version        => Sympa::Constants::VERSION(),

    # Optional fields
    no_index          => {directory => [qw(po t www xt)],},
    optional_features => {},        # See below
    prereqs   => {},                                 # See below
    resources => {
        homepage => 'https://www.sympa.org/',
        bugtracker =>
            {web => 'https://sourcesup.renater.fr/tracker/?group_id=23',},
        repository => {
            url  => 'https://subversion.renater.fr/sympa',
            type => 'svn',
        },
    },
};

$struct->{release_status} =
      (Sympa::Constants::VERSION() =~ /\da/) ? 'unstable'
    : (Sympa::Constants::VERSION() =~ /\db/) ? 'testing'
    :                                          'stable';
$struct->{optional_features} = {optional_features()};
$struct->{prereqs}           = {prereqs()};

my $meta = CPAN::Meta->create($struct);
print $meta->as_string;

exit 0;

sub optional_features {
    my %features;
    foreach my $mod (sort keys %Sympa::ModDef::cpan_modules) {
        my $def = $Sympa::ModDef::cpan_modules{$mod};
        next if $mod eq 'perl' or $def->{mandatory};

        $features{$def->{package_name}}{description} = $def->{gettext_id}
            if $def->{gettext_id};
        $features{$def->{package_name}}{prereqs}{runtime}{requires}{$mod} =
            $def->{required_version} || '0';
    }
    return %features;
}

sub prereqs {
    my %requires;
    foreach my $mod (sort keys %Sympa::ModDef::cpan_modules) {
        my $def = $Sympa::ModDef::cpan_modules{$mod};
        next unless $mod eq 'perl' or $def->{mandatory};

        $requires{$mod} = $def->{required_version} || '0';
    }
    return (runtime => {requires => \%requires});
}
