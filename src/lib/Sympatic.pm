package Sympatic;
our $VERSION = '0.0';
use v5.14;
use strict;
use warnings;
require Import::Into;

sub import {
    my $to = caller;

    English->import::into($to, qw<  -no_match_vars >);
    feature->import::into($to,qw< say >);
    strict->import::into($to);
    warnings->import::into($to);
    Function::Parameters->import::into($to);
    utf8::all->import::into($to);

    # see https://github.com/pjf/autodie/commit/6ff9ff2b463af3083a02a7b5a2d727b8a224b970
    # TODO: is there a case when caller > 1 ?
    autodie->import::into(1);

    # remove things for args until there is no more argument
    shift; # 'Sympatic', the package name

    while (@_) {

        if ($_[0] eq '-oo') {
                shift;
                Moo->import::into($to);
                MooX::LvalueAttribute->import::into($to);
        }
        else {
            die "invalid argument remains: "
            . join "\n", @_;
        }

    }

}

1;
