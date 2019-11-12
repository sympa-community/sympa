#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;
use Data::Dumper;
use English;
use File::Path qw(make_path rmtree);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);

use FindBin qw($Bin);
use lib "$Bin/../src/lib";

use Test::More;

BEGIN {
    use_ok('Sympa::Message');
}

my $tmp_dir = 't/tmp';
my $db_dir = $tmp_dir.'/db';
my $home_dir = $tmp_dir.'/list_data';
my $etc_dir = $tmp_dir.'/etc';

%Conf::Conf = (
    domain     => 'lists.example.com',     # mandatory
    listmaster => 'dude@example.com',      # mandatory
    lang       => 'en-US',
    sender_headers => 'From',
    tmpdir => $tmp_dir,
    db_type    => 'SQLite',
    db_name    => $db_dir.'/message-test-db.sqlite',
    update_db_field_types    => 'auto',
    home => $home_dir,
    etc => $etc_dir,
    cache_list_config => '',
    supported_lang => 'en-US',
    filesystem_encoding => 'utf-8',
);

if (-d $tmp_dir) {
  print "kill!\n";
  rmtree($tmp_dir);
}
make_path($tmp_dir);
make_path($db_dir);
make_path($home_dir);
dircopy('t/data/list_data/', $home_dir);
make_path($etc_dir);

if (-f $Conf::Conf{db_name}) {
    unlink $Conf::Conf{db_name};
}

open my $fileHandle, ">", "$Conf::Conf{db_name}" or die "Can't create '$Conf::Conf{db_name}'\n";
close $fileHandle;

my $sdm = Sympa::DatabaseManager->instance;
Sympa::DatabaseManager::probe_db();

my $list = Sympa::List->new('test', '*');
$list->_update_list_db;
my $to_urlize_file = 't/samples/urlize-encoding.eml';
my $lock_fh =  Sympa::LockedFile->new($to_urlize_file, -1, '+<');
my $to_urlize_string = do { local $RS; <$lock_fh> };
my $to_urlize = Sympa::Message->new($to_urlize_string);

my $parser = MIME::Parser->new;
$parser->extract_nested_messages(0);
$parser->extract_uuencode(1);
$parser->output_to_core(1);
$parser->tmp_dir($Conf::Conf{'tmpdir'});

my $msg_string = $to_urlize->as_string;
$msg_string =~ s/\AReturn-Path: (.*?)\n(?![ \t])//s;
my $entity = $parser->parse_data($msg_string);

Sympa::Message::_urlize_parts($entity, $list, $to_urlize->{'message_id'});

rmtree $tmp_dir;
done_testing();
