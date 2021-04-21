# -*- indent-tabs-mode: nil; -*-
# # vim:ft=perl:et:sw=4

use strict;
use warnings;
use FindBin qw($Bin);
use IO::Scalar;

use Test::More;

BEGIN {
    use_ok('Sympa::Config_XML');
}

my @in = do { local $/ = ''; <DATA> };

is_deeply(
    Sympa::Config_XML->new(IO::Scalar->new(\(shift @in)))->as_hashref,
    {   'owner' => [
            {   'email' => 'admin.etulistes@example.fr',
                'gecos' => 'Administrateur listes etudiants'
            }
        ],
        'topics'   => 'fst/etulistes',
        'editor'   => [],
        'subject'  => 'FST Licence 1e annee Informatique-groupe 1',
        'listname' => '1liai1-1-s1-in-1',
        'ldap'     => {
            'select2'     => 'first',
            'scope2'      => 'sub',
            'suffix1'     => 'ou=groups,dc=example,dc=fr',
            'suffix2'     => '[attrs1]',
            'attrs1'      => 'member',
            'user'        => 'XXX',
            'select1'     => 'all',
            'filter2'     => '(mail=*)',
            'timeout1'    => '30',
            'attrs2'      => 'mail',
            'scope1'      => 'sub',
            'host'        => 'XXX',
            'use_ssl'     => 'yes',
            'passwd'      => 'XXX',
            'filter1'     => '(uhaGroupeMail=1LIAI1-1-S1-IN-1@example.fr)',
            'timeout2'    => '30',
            'ssl_version' => 'sslv3'
        }
    }
);
is_deeply(
    Sympa::Config_XML->new(IO::Scalar->new(\(shift @in)))->as_hashref,
    {   'owner'    => [{'email' => 'bruno.malaval@example.fr'}],
        'topics'   => undef,
        'editor'   => [],
        'subject'  => 'test-etc',
        'listname' => 'di-test-xml',
        'type'     => 'intranet_list'
    }
);
is(Sympa::Config_XML->new(IO::Scalar->new(\(shift @in)))->as_hashref, undef);
is(Sympa::Config_XML->new(IO::Scalar->new(\(shift @in)))->as_hashref, undef);

# GH#953: "false" values in XML file prevent list creation
if (isnt(
        my $h =
            Sympa::Config_XML->new(IO::Scalar->new(\(shift @in)))->as_hashref,
        undef
    )
) {
    is($h->{filtre}, '0');
}

done_testing();

__END__
<?xml version="1.0" ?>
  <list>
    <listname>1liai1-1-s1-in-1</listname>
    <subject>FST Licence 1e annee Informatique-groupe 1</subject>
    <owner multiple="1">
      <email>admin.etulistes@example.fr</email>
      <gecos>Administrateur listes etudiants</gecos>
    </owner>
    <ldap>
      <host>XXX</host>
      <user>XXX</user>
      <passwd>XXX</passwd>
      <use_ssl>yes</use_ssl>
      <ssl_version>sslv3</ssl_version>
      <suffix1>ou=groups,dc=example,dc=fr</suffix1>
      <timeout1>30</timeout1>
      <attrs1>member</attrs1>
      <filter1>(uhaGroupeMail=1LIAI1-1-S1-IN-1@example.fr)</filter1>
      <scope1>sub</scope1>
      <select1>all</select1>
      <suffix2>[attrs1]</suffix2>
      <timeout2>30</timeout2>
      <attrs2>mail</attrs2>
      <filter2>(mail=*)</filter2>
      <scope2>sub</scope2>
      <select2>first</select2>
    </ldap>
    <topics>fst/etulistes</topics>
  </list>

<?xml version="1.0" ?>
  <list>
    <listname>di-test-xml</listname>
    <type>intranet_list</type>
    <subject>test-etc</subject>
    <owner multiple="1">
      <email>bruno.malaval@example.fr</email>
    </owner>
  </list>

<?xml version="1.0" ?>
  <list>
    <listname>di-test-xml</listname>
    <type>intranet_list</type>
    <subject>test-etc</subject>
    <owner>
      <email>bruno.malaval@example.fr</email>
    </owner>
    <owner>
      <email>bruno.malaval@example.fr</email>
    </owner>
  </list>

<?xml version="1.0" ?>
  <list>
    <listname multiple="1">di-test-xml</listname>
    <listname multiple="1">di-test-xml</listname>
    <type>intranet_list</type>
    <subject>test-etc</subject>
    <owner multiple="1">
      <email>bruno.malaval@example.fr</email>
    </owner>
  </list>

<?xml version="1.0" encoding="UTF-8"?>
  <list>
    <listname>liste.org1.test</listname>
    <subject>Liste test</subject>
    <custom_subject>TEST</custom_subject>
    <topics>communication</topics>
    <reply_mail>noreply@domaine.fr</reply_mail>
    <status>open</status>
    <source>mysql</source>
    <send>diffuseur</send>
    <filtre>0</filtre>
    <owner multiple="1">
      <email>listmaster@domaine.fr</email>
      <gecos>listmaster</gecos>
      <reception>mail</reception>
    </owner>
  </list>

