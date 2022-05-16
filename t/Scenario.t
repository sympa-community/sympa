# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use lib qw(t/stub);
use strict;
use warnings;
use English qw(-no_match_vars);
use File::Path qw(make_path rmtree);
use Test::More;

BEGIN {
    use_ok('Sympa::Scenario');
}

%Conf::Conf = (
    domain     => 'lists.example.com',    # mandatory
    listmaster => 'dude@example.com',     # mandatory
    etc        => 't/tmp/etc',
);

my $domain = $Conf::Conf{'domain'};
my $list   = bless {
    name   => 'listname',
    domain => $domain,
    dir    => Sympa::Constants::EXPLDIR() . '/listname',
    admin  => {status => 'open'}
} => 'Sympa::List';

make_path $Conf::Conf{'etc'} . '/scenari' or die $ERRNO;

my $scenario;

# Nonexisting scenarios.
$scenario = Sympa::Scenario->new($domain, 'create_list', name => 'none');
is(($scenario->authz('smtp', {}) || {})->{action}, 'reject');
$scenario = Sympa::Scenario->new($list, 'visibility', name => 'none');
is(($scenario->authz('smtp', {}) || {})->{action}, 'reject');

# ToDo: compile()

my $fh;
# GH issue #860: Crash by bad syntax of regexp
open $fh, '>', $Conf::Conf{'etc'} . '/scenari/send.bad_regexp';
print $fh <<'EOF';
match([sender],/[custom_vars->sender_whitelist]/) smtp,dkim,md5,smime -> do_it
EOF
close $fh;
$scenario = Sympa::Scenario->new($list, 'send', name => 'bad_regexp');
is(($scenario->authz('smtp', {}) || {})->{action},
    'reject', 'bad regexp syntax');
# ... and legitimate case
open $fh, '>', $Conf::Conf{'etc'} . '/scenari/send.good_regexp';
print $fh <<'EOF';
match([sender],/[domain]/) smtp,dkim,md5,smime -> do_it
EOF
close $fh;
$scenario = Sympa::Scenario->new($list, 'send', name => 'good_regexp');
is( ($scenario->authz('smtp', {sender => 'me@lists.example.com'}) || {})
    ->{action},
    'do_it',
    'good regexp'
);

rmtree 't/tmp' or die $ERRNO;
done_testing();

