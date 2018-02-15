# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../src/lib";

use English qw(-no_match_vars);
use Test::More;

eval {
    require Test::Compile;
    Test::Compile->import();
};
if ($EVAL_ERROR) {
    my $msg = 'Test::Compile required';
    plan(skip_all => $msg);
}

#$ENV{PERL5LIB} = $ENV{PERL5LIB} ? "$ENV{PERL5LIB}:src/lib" : "src/lib";

all_pl_files_ok(
	##<po/*.pl>,
        <src/sbin/*.pl>,
        <src/bin/*.pl>,
        <src/libexec/*.pl>,
        'src/cgi/wwsympa.fcgi',
        'src/cgi/sympa_soap_server.fcgi',
);
