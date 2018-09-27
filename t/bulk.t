#!/usr/bin/perl

# TODO:
# mkdir -p t/tmp/spooldir

# TODO: this case is trying to work in / because of undefined variable
# some day  it must die ?
#
# Use of uninitialized value $Sympa::Constants::SPOOLDIR in concatenation (.) or string at t/bulk.t line 12.
# Use of uninitialized value $Conf::Conf{"umask"} in oct at /home/mc/sympa/7/t/../src/lib/Sympa/Bulk.pm line 74.
# info Sympa::Bulk::_create_spool() Creating spool /bulk
# Cannot create /bulk: Permission denied at /home/mc/sympa/7/t/../src/lib/Sympa/Bulk.pm line 90. 
#
# TODO: mkdir only when in a sandbox or never (as option ?)
#
# TODO:
#
# it seems every new iteration change
#
# info Sympa::Bulk::_create_spool() Creating spool t/tmp/spooldir/bulk/bad
# Cannot create t/tmp/spooldir/bulk/bad: No such file or directory at /home/mc/sympa/7/t/../src/lib/Sympa/Bulk.pm line 90.

use strict;
use warnings;
use Data::Dumper;
use FindBin qw( $Bin );
use lib qw( t/lib );
use Test::More;
use Sympa::Bulk;
use Sympa::Tools::File;

# TODO: what to do with use_ok ?
# BEGIN { use_ok('Sympa::Bulk'); }

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
