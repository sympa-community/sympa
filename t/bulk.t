#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw( $Bin );
use lib qw( t/lib );
use Test::More;
use Sympa::Tools::File;
use Sympa::Message;
use ok 'Sympa::Bulk';
use English;

# during a test, syslog would be helpful as a note
# so *Sympa::Log::syslog is diverted
#
# by default, syslog remains silent

{ no warnings;
    *Sympa::Log::syslog = 1 #  $ENV{SYMPA_TEST_SILENT_SYSLOG}
    ? sub {}
    : sub {
        shift; # $self isn't expected anymore
        my ( $level, $fmt, @params ) = @_;
        note sprintf "syslog $level: $fmt", @params; }
    ;
}

# this is the basic (ideally the only one keys required)
# config to make this test work

%Conf::Conf = (
    # Sympa::Bulk::store needs
    sympa_packet_priority => 5,
    sympa_priority        => 1,
    email                 => 'sympa',
    domain                => 'lists.example.com',
    sender_headers        => 'Resent-From,From,Return-Path',
    list_check_suffixes   => 'list_check_suffixes',
    umask                 => '027',
);

# we need an absolute path there because in Sympa/Bulk.pm:109
#
#    $self->{_metadatas} = [
#        sort grep {
#                    !/,lock/
#                and !m{(?:\A|/)(?:\.|T\.|BAD-)}
#                and -f ($self->{pct_directory} . '/' . $_)
#        } glob $self->{_glob_pattern}
#    ];
#
# as we are already in $self->{pct_directory}, -f will always fail with a
# relative path.
#
# i (eiro) don't know if it's a bug or a feature

use Cwd;
$Conf::Conf{queuebulk} =
    Cwd::abs_path
    Sympa::Constants::SPOOLDIR."/bulk";

# we need to be sure that new files are created by the code below
# so we delete the old queuebulk

for ( $Conf::Conf{queuebulk} ) {
    Sympa::Tools::File::del_dir $_;
    ok +( ! -e ) => "remove queuebulk";
}

# create a new Sympa::Message from the content of t/samples/unsigned.eml
my %sample;
@sample{qw( file msg )} =
    map +(
        $_,
        Sympa::Message->new_from_file($_)
    ), "t/samples/unsigned.eml";

# store a message and returns a hashref with its
# qw( total_packets marshalled ) as keys.

sub ok_bulk_store {
    my ( $bulk, $msg ) = @_;
    my $stored =
        $bulk->store
        ($msg
        , 'dave.null@example.com' );
    isa_ok $stored, HASH =>  '$bulk->store';
    # TODO: skip them if $stored isn't HASH
    ok +( 2 ==
            grep
            +(exists $$stored{$_})
            , qw( total_packets marshalled ) )
        , "got total_packets and marshalled from stored msg";

    ok +( 2 == keys %$stored )
        => "no extra information";
    # TODO: test data extractions from marshalled name ?
    $stored;
}

sub ok_no_next_from_empty_bulk {
    my ( $bulk, $desc ) = @_;
    my ( $msg, $file ) = $bulk->next;
    ok +( not defined $file ) => "no next message $desc"
        or note "next: $file";
}

sub ok_next_message {
    my ( $bulk, $desc ) = @_;
    my ( $msg, $file ) = $bulk->next;
    ok $file, $desc;
    isa_ok $msg  , 'Sympa::Message'    , 'next message';
    isa_ok $file , 'Sympa::LockedFile' , 'next lock';
    ( $msg, $file );
}

sub ok_new_bulk {
    my ( $desc ) = @_;
    my $bulk = Sympa::Bulk->new;
    ok $bulk, $desc;
    isa_ok $bulk,
        'Sympa::Bulk',
        "Sympa::Bulk->new";
    $bulk;
}

# as all the tests are run twice and the actual creation of the tree
# will occur once, the second pass will test the usage of an existing
# queuebulk
# TODO: delete a part of the tree and see what happens ... ?

for my $context ('fresh queuebulk', 'existing queuebulk') {

    my ($stored, $msg, $file );

    my $bulk = ok_new_bulk "bulk created on $context";
    ok_no_next_from_empty_bulk $bulk
        => "from empty bulk in $context";
    $stored = ok_bulk_store $bulk, $sample{msg};

    ( $msg, $file ) = $bulk->next;
    ok $file, "got next messsage from $context";
    isa_ok $file, 'Sympa::LockedFile', "next message from $context";

    ok $bulk->remove($file), "message removed";
    ok_no_next_from_empty_bulk $bulk
        => "when everything was removed from $context";

    ok_bulk_store $bulk, $sample{msg};

    ( $msg, $file ) = ok_next_message $bulk
        => "got the next element from $context";
    ok $bulk->quarantine($file)
        => "message in quarantine";
    ok_no_next_from_empty_bulk $bulk
        => "no next element message in quarantine";

}

# because those messages are just kept in quarantine, they aren't removed
# so they should remain on the quarantine directory.

$_ = Sympa::Bulk->new->{bad_msg_directory};
ok +( 2 == map $_, <$_/*> )
    => "2 messages in quarantine";

done_testing;
