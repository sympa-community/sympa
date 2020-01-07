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
my $test_list_name = 'test';

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
    urlize_min_size => 0,
);

if (-d $tmp_dir) {
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

my $list = Sympa::List->new($test_list_name, '*');
$list->_update_list_db;

my @to_urlize = (
    {
        filename => 't/samples/urlize-encoding.eml',
        attachment_name => 'image accentuée.jpg',
        escaped_attachment_name => '/attach/test/2_24%40domain.tld/image%2520accentu%25c3%25a9e.jpg',
        dirname => '2_24@domain.tld'
    },
    {
        filename => 't/samples/urlize-nested.eml',
        attachment_name => 'Würzburg.pdf',
        escaped_attachment_name => '/attach/test/3_24%40domain.tld/W%25c3%25bcrzburg.pdf',
        dirname => '3_24@domain.tld'
    },
);
foreach my $test_file (@to_urlize) {
    my $to_urlize_file = $test_file->{filename};
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

    my $new_entity = Sympa::Message::_urlize_parts($entity, $list, $to_urlize->{'message_id'});

    ### Preparation done. Actual testing starts here.

    my $urlized_directory;
    opendir my $dh, $home_dir.'/'.$test_list_name.'/urlized/';
    foreach my $file (readdir $dh) {
      next if $file =~ m{\A\.+\Z};
      $urlized_directory = $file; last;
    }
    closedir $dh;

    is($urlized_directory, $test_file->{dirname}, 'Directory where urlized parts are stored correctly escaped.');

    ok(! -f $home_dir.'/'.$test_list_name.'/urlized/'.$urlized_directory.'/msg.0.bin', 'The text of the message has not been converted to binary attachment.') ;

    ok(! -f $home_dir.'/'.$test_list_name.'/urlized/'.$urlized_directory.'/msg.0.txt', 'The text of the message has not been converted to text attachment.') ;

    ok( -f $home_dir.'/'.$test_list_name.'/urlized/'.$urlized_directory.'/'.$test_file->{attachment_name}, 'The attachment has been stored on the filesystem.') ;

    my $found_url_to_attachment = 0;
    foreach my $line (split '\n', $new_entity->as_string()) {
        my $line_to_match = $test_file->{escaped_attachment_name};
        if ($line =~ m{$line_to_match}) {
            $found_url_to_attachment = 1;
            last;
        }
    }
    
    is( $found_url_to_attachment, 1, 'The attachment stored on the filesystem has an URL to retrieve it it the new message.');

}
rmtree $tmp_dir;
done_testing();