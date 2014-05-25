#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;

use Test::More;

use tools; #Sympa::Tools::Data;

my @array_from_string_tests = (
    [ 'foo,bar,baz'       => [ qw/foo bar baz/ ] ],
    [ ' foo, bar, baz'    => [ qw/foo bar baz/ ] ],
    [ 'foo ,bar ,baz '    => [ qw/foo bar baz/ ] ],
    [ ' foo , bar , baz ' => [ qw/foo bar baz/ ] ],
);

my @string_2_hash_tests = (
    [ 'var1="val1";var2="val2";' => { var1 => "val1", var2 => "val2" } ],
    [ ';var1="val1";var2="val2"' => { var1 => "val1", var2 => "val2" } ]
);

my @hash_2_string_tests = (
    [ { var1 => "val1", var2 => "val2" }
        => qr/^(;var1="val1";var2="val2"|;var2="val2";var1="val1")$/x ]
);

my @smart_lessthan_ok_tests = (
    [ [ "", "1" ] ],
    [ [ "1", "2" ] ],
    [ [ " 1 ", " 2 " ] ],
);

my @smart_lessthan_nok_tests = (
    [ [ "", "" ] ],
    [ [ "1", "" ] ],
    [ [ "1", "1" ] ],
    [ [ "2", "1" ] ],
    [ [ " 2 ", " 1 " ] ],
);

my @diff_on_arrays_tests = (
    [
        [ [], [] ] => {
            intersection => [],
            union        => [],
            added        => [],
            deleted      => []
        }
    ],
    [
        [ [ 'a' ], [ 'a' ] ] => {
            intersection => [ 'a' ],
            union        => [ 'a' ],
            added        => [ ],
            deleted      => [ ]
        }
    ],
    [
        [ [ 'a' ], [ 'b' ] ] => {
            intersection => [],
            union        => [ 'a', 'b' ],
            added        => [ 'b' ],
            deleted      => [ 'a' ]
        }
    ]
);

my @remove_empty_entries_tests = (
    [ ''                     => [ 0, ''                       ] ],
    [ 'a'                    => [ 1, 'a'                      ] ],
    [ [                    ] => [ 0, [                      ] ] ],
    [ [ 'a'                ] => [ 1, [ 'a'                  ] ] ],
    [ [ 'a', ''            ] => [ 1, [ 'a', undef           ] ] ],
    [ [ 'a', '', 'b'       ] => [ 1, [ 'a', undef, 'b'      ] ] ],
    [ {                    } => [ 0, {                      } ] ],
    [ { a => 'a'           } => [ 1, { a => 'a'             } ] ],
    [ { a => 'a', b => ''  } => [ 1, { a => 'a', b => undef } ] ],
    [ { a => 'a', b => 'b' } => [ 1, { a => 'a', b => 'b'   } ] ],
);

my @recursive_transformation_tests = (
    [ ''                              => ''                                ],
    [ 'a'                             => 'a'                               ],
    [ [                    ]          => [                               ] ],
    [ [ 'a'                ]          => [ 'aa'                          ] ],
    [ [ 'a', ''            ]          => [ 'aa', ''                      ] ],
    [ [ 'a', '', 'b'       ]          => [ 'aa', '', 'bb'                ] ],
    [ {                    }          => {                               } ],
    [ { a => 'a'           }          => { a => 'aa'                     } ],
    [ { a => 'a', b => ''  }          => { a => 'aa', b => ''            } ],
    [ { a => 'a', b => 'b' }          => { a => 'aa', b => 'bb'          } ],
    [ [ 'a', [ 'a' ], {  a => 'a' } ] => [ 'aa', [ 'aa' ], { a => 'aa' } ] ],
);

plan tests =>
    @array_from_string_tests       +
    @string_2_hash_tests           +
    @hash_2_string_tests           +
    @smart_lessthan_ok_tests       +
    @smart_lessthan_nok_tests      +
    @diff_on_arrays_tests          +
    @recursive_transformation_tests ;

foreach my $test (@array_from_string_tests) {
    is_deeply(
        tools::get_array_from_splitted_string($test->[0]),
        $test->[1],
        "get_array_from_splitted_string $test->[0]"
    );
}

foreach my $test (@string_2_hash_tests) {
    is_deeply(
        { tools::string_2_hash($test->[0]) },
        $test->[1],
        "string_2_hash $test->[0]"
    );
}

foreach my $test (@hash_2_string_tests) {
    like(
        tools::hash_2_string($test->[0]),
        $test->[1],
        "hash_2_string"
    );
}

foreach my $test (@smart_lessthan_ok_tests) {
    ok(
        tools::smart_lessthan(@{$test->[0]}),
        "smart_lessthan $test->[0]->[0], $test->[0]->[1]"
    );
}

foreach my $test (@smart_lessthan_nok_tests) {
    ok(
        !tools::smart_lessthan(@{$test->[0]}),
        "smart_lessthan $test->[0]->[0], $test->[0]->[1]"
    );
}

foreach my $test (@diff_on_arrays_tests) {
    # normalize result to enforce constant ordering despite hash randomization
    my $result = tools::diff_on_arrays(@{$test->[0]});
    foreach my $key (qw/union intersection added deleted/) {
        $result->{$key} = [ sort @{$result->{$key}} ];
    }
    my $expected = $test->[1];
    is_deeply(
        $result,
        $expected,
        "diff_in_arrays"
    );
}

my $transformation = sub { return $_[0] . $_[0] };
foreach my $test (@recursive_transformation_tests) {
    tools::recursive_transformation($test->[0], $transformation);
    is_deeply(
        $test->[0],
        $test->[1],
        "recursive_transformation"
   );
}
