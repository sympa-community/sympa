# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use Data::Dumper;
use English qw(-no_match_vars);
use Test::More;
BEGIN { eval 'use Sympa::Test::MockLDAP'; }

unless (eval 'Test::Net::LDAP::Util->can("ldap_mockify")') {
    plan skip_all => 'Test::Net::LDAP required';
}

use Sympa::List;

$Data::Dumper::Terse  = 1;
$Data::Dumper::Indent = 0;

use_ok('Sympa::DataSource::LDAP2');

my $fake_list = bless {
    name   => 'list1',
    domain => 'mail.example.org',
} => 'Sympa::List';

Sympa::Test::MockLDAP::build(
    [   'CN=student1,OU=ELEVES,OU=PERSONNES,DC=info,DC=example,DC=qc,DC=ca',
        attrs => [
            cn               => 'student1',
            businessCategory => '706',
            departmentNumber => '023',
        ],
    ],
    [   'CN=random@hotmail.com,OU=PARENTS,OU=PERSONNES,DC=info,DC=example,DC=qc,DC=ca',
        attrs => [
            cn   => 'random@hotmail.com',
            mail => 'random@hotmail.com',
            kids => ['student2', 'student1'],
        ],
    ],
    [   'CN=random2@hotmail.com,OU=PARENTS,OU=PERSONNES,DC=info,DC=example,DC=qc,DC=ca',
        attrs => [
            cn   => 'random2@hotmail.com',
            mail => ['random1@hotmail.com', 'random2@hotmail.com'],
            kids => ['student2', 'student1'],
        ],
    ],
);

my $ds;
my @res;

$ds = Sympa::DataSource->new(
    'LDAP2', 'member',
    context  => $fake_list,
    name     => 'parent023706',
    suffix1  => 'OU=ELEVES,OU=PERSONNES,DC=info,DC=example,DC=qc,DC=ca',
    filter1  => '(&(departmentNumber=023)(businessCategory=706))',
    scope1   => 'sub',
    select1  => 'all',
    attrs1   => 'cn',
    timeout1 => '60',
    suffix2  => 'OU=PARENTS,OU=PERSONNES,dc=info,dc=example,dc=qc,dc=ca',
    filter2  => '(kids=[attrs1])',
    scope2   => 'sub',
    select2  => 'all',
    attrs2   => 'mail',
    timeout2 => '60',
);
isa_ok $ds, 'Sympa::DataSource::LDAP2';
ok $ds->open, 'open()';

@res = ();
while (my $ent = $ds->next) {
    push @res, $ent;
}
is_deeply [sort { $a->[0] cmp $b->[0] } @res],
    [
    ['random1@hotmail.com', undef],
    ['random2@hotmail.com', undef],
    ['random@hotmail.com',  undef]
    ],
    'LDAP 2-level data source with select=all';
diag Dumper([@res]);

$ds = Sympa::DataSource->new(
    'LDAP2', 'member',
    context  => $fake_list,
    name     => 'parent023706',
    suffix1  => 'OU=ELEVES,OU=PERSONNES,DC=info,DC=example,DC=qc,DC=ca',
    filter1  => '(&(departmentNumber=023)(businessCategory=706))',
    scope1   => 'sub',
    select1  => 'all',
    attrs1   => 'cn',
    timeout1 => '60',
    suffix2  => 'OU=PARENTS,OU=PERSONNES,dc=info,dc=example,dc=qc,dc=ca',
    filter2  => '(kids=[attrs1])',
    scope2   => 'sub',
    select2  => 'first',
    attrs2   => 'mail',
    timeout2 => '60',
);
$ds->open or die;

@res = ();
while (my $ent = $ds->next) {
    push @res, $ent;
}
is scalar(@res), 2, 'LDAP 2-level data source with select=first';
diag Dumper([@res]);

done_testing();
