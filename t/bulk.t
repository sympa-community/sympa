#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw( $Bin );
use lib qw( t/lib );
use Test::More;
use Sympa::Tools::File;
use ok 'Sympa::Bulk';

%Conf::Conf = (
    domain     => 'lists.example.com',  # mandatory
    listmaster => 'dude@example.com',   # mandatory
    lang       => 'en-US',
    db_type    => 'SQLite',
    db_name    => 't/data/sympa.sqlite',
    queuebulk  => Sympa::Constants::SPOOLDIR."/bulk",
    umask      => '027',
);

# ensure queuebulk is empty
Sympa::Tools::File::del_dir $Conf::Conf{queuebulk};
ok( Sympa::Bulk->new,
    "bulk created from an empty queuebulk directory",);

# create a new one
my $bulk = Sympa::Bulk->new;
ok $bulk, "bulk created on already setup directory";

done_testing;
