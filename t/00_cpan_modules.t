# -*- indent-tabs-mode: nil; -*-
# # vim:ft=perl:et:sw=4

use strict;
use warnings;
use Test::More;

our $identifier;
our $description;
our $phase;
our $is_optional;
my %seen;

do './cpanfile' || die($@ or $!);
done_testing;

sub feature {
    local $identifier  = shift;
    local $description = shift unless ref $_[0];
    local $is_optional = 1;
    shift->();
    1;
}

sub on {
    local $phase       = shift;
    local $is_optional = 1
        unless grep { $phase eq $_ } qw(configure build test runtime);
    shift->();
    1;
}

sub recommends {
    local $is_optional = 1;
    _depends(@_);
}

sub requires {
    _depends(@_);
}

sub _depends {
    my $module = shift;
    my $verreq = shift || '0';
    $verreq = [grep { !/[!<]/ } split /\s*,\s*/, $verreq]->[0];
    $verreq =~ s/\A\s*([=>]+)\s*//;
    my $verop = $1 || '>=';

    # Skip duplicate entries
    my $key = join ' ', $is_optional ? 'o' : 'm', $module, $verop, $verreq;
    return 1 if $seen{$key};
    $seen{$key} = 1;

    if ($module eq 'perl') {
        # Compat. for perl < 5.10: $^V is not an object but a vector of
        # integers.
        my $rpv = eval "v$verreq" or die $@;
        ok(($^V ge $rpv), sprintf 'Perl (%s >= %s)', $], $verreq);
    } else {
        my $version;
        eval "require $module";
        {
            no strict 'refs';
            my $v = "${module}::VERSION";
            $version = $$v;
        }
        my $ok =
              $verop eq '==' ? $version eq $verreq
            : $verop eq '>'  ? $version gt $verreq
            : $verop eq '>=' ? $version ge $verreq
            : die "unknown operator $verop"
            if defined $version;

        if ($is_optional) {
            note sprintf
                '%s .. %s %s (%s%s%s) [optional]',
                $ok ? 'ok' : 'not ok',
                $phase || 'runtime',
                $module,
                defined $version ? $version : 'NONE',
                $verreq eq '0'   ? ''       : " $verop ",
                $verreq eq '0'   ? ''       : $verreq;
        } else {
            ok $ok,
                sprintf '%s %s (%s%s%s)',
                $phase || 'runtime',
                $module,
                defined $version ? $version : 'NONE',
                $verreq eq '0'   ? ''       : " $verop ",
                $verreq eq '0'   ? ''       : $verreq;
        }
    }

    1;
}

