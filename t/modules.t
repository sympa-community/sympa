#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../src/lib";
use lib "$Bin/../wwsympa";
use Test::More qw(no_plan);
use File::Find;

my $test = sub {
    return unless $_ =~ /\.pm$/;
    my $file = $File::Find::name;
    $file =~ s/\.\///;
    require_ok $file;
};
foreach my $dir ("$Bin/../src/lib", "$Bin/../wwsympa") {
    chdir $dir;
    find($test, '.');
}
