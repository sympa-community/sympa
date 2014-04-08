# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;

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
	'important_changes.pl',
	##<po/*.pl>,
	<src/*.pl>,
	<src/etc/script/*.pl>,
	<soap/*.pl>,
	<wwsympa/wwsympa.fcgi>,
	<soap/sympa_soap_server.fcgi>,
);
