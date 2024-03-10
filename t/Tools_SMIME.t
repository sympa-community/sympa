#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_smime.t 8874 2013-03-14 18:59:35Z rousse $

use strict;

use English qw(-no_match_vars);
use File::Temp;
use MIME::Parser;
use Test::More;

#use Sympa::Tools::File;
use Sympa::Tools::SMIME;

plan tests => 15;

#ok(
#    !Sympa::Tools::SMIME::find_keys('/no/where', 'sign'),
#    'non existing directory'
#);

my $home_dir =
    File::Temp->newdir("test.$$.XXXXX",
    CLEANUP => ($ENV{TEST_DEBUG} ? 0 : 1));
$Conf::Conf{'home'} = $home_dir;
my $cert_dir = $home_dir . '/sympa';
mkdir $cert_dir;

ok(!Sympa::Tools::SMIME::find_keys('*', 'sign'), 'empty directory');

my $generic_cert_file    = $cert_dir . '/cert.pem';
my $generic_key_file     = $cert_dir . '/private_key';
my $encryption_cert_file = $cert_dir . '/cert.pem.enc';
my $encryption_key_file  = $cert_dir . '/private_key.enc';
my $signature_cert_file  = $cert_dir . '/cert.pem.sign';
my $signature_key_file   = $cert_dir . '/private_key.sign';

touch($generic_cert_file);

ok(!Sympa::Tools::SMIME::find_keys('*', 'sign'),
    'directory with certificate only');

unlink($generic_cert_file);

touch($generic_key_file);

ok(!Sympa::Tools::SMIME::find_keys('*', 'sign'), 'directory with key only');

unlink($generic_key_file);

touch($generic_cert_file);
touch($generic_key_file);

is_deeply(
    [Sympa::Tools::SMIME::find_keys('*', 'sign')],
    [$generic_cert_file, $generic_key_file],
    'directory with generic key/certificate only, signature operation'
);

is_deeply(
    [Sympa::Tools::SMIME::find_keys('*', 'encrypt')],
    [$generic_cert_file, $generic_key_file],
    'directory with generic key/certificate only, encryption operation'
);

is_deeply(
    [Sympa::Tools::SMIME::find_keys('*', 'decrypt')],
    [[$generic_cert_file], [$generic_key_file]],
    'directory with generic key/certificate only, decryption operation'
);

touch($signature_cert_file);
touch($signature_key_file);
touch($encryption_cert_file);
touch($encryption_key_file);

is_deeply(
    [Sympa::Tools::SMIME::find_keys('*', 'sign')],
    [$signature_cert_file, $signature_key_file],
    'directory with dedicated key/certificates, signature operation'
);

is_deeply(
    [Sympa::Tools::SMIME::find_keys('*', 'encrypt')],
    [$encryption_cert_file, $encryption_key_file],
    'directory with dedicated key/certificates, encryption operation'
);

is_deeply(
    [Sympa::Tools::SMIME::find_keys('*', 'decrypt')],
    [   [$generic_cert_file, $encryption_cert_file, $signature_cert_file],
        [$generic_key_file,  $encryption_key_file,  $signature_key_file],
    ],
    'directory with dedicated key/certificates, decryption operation'
);

ok(!eval { Sympa::Tools::SMIME::parse_cert() },
    'neither text nor file given');

ok( !Sympa::Tools::SMIME::parse_cert(file => '/no/where'),
    'non-existing file',
);

ok(!eval { Sympa::Tools::SMIME::parse_cert(text => '') }, 'empty string',);

my $cert_file = 't/pki/crt/rousse.pem';
#my $cert_string = Sympa::Tools::File::slurp_file($cert_file);
my $cert_string = do { local (@ARGV, $/) = $cert_file; <> };
my $cert_data = {
    purpose => {
        sign => 1,
        enc  => 1
    },
    subject =>
        'O=sympa developpers, OU=unit testing, CN=Guillaume Rousse, emailAddress=Guillaume.Rousse@sympa.org',
    email    => {'guillaume.rousse@sympa.org' => 1},
    emails   => ['guillaume.rousse@sympa.org'],
    notAfter => 'Feb 23 17:11:04 2023 GMT',
    issuer =>
        'O=sympa developpers, OU=unit testing, CN=Test CA, emailAddress=test@sympa.org',
};

SKIP: {
    skip 'Crypt::OpenSSL::X509 not installed', 2
        unless $Crypt::OpenSSL::X509::VERSION;

    is_deeply(Sympa::Tools::SMIME::parse_cert(file => $cert_file,),
        $cert_data, 'user certificate file parsing');

    is_deeply(Sympa::Tools::SMIME::parse_cert(text => $cert_string,),
        $cert_data, 'user certificate string parsing');
}

my $ca_cert_file = 't/pki/crt/ca.pem';
my $ca_cert_data = {
    subject =>
        'O=sympa developpers, OU=unit testing, CN=Test CA, emailAddress=test@sympa.org',
    email   => {'test@sympa.org' => 1},
    emails  => ['test@sympa.org'],
    purpose => {
        sign => '',
        enc  => ''
    },
    notAfter => 'Feb 24 17:05:48 2018 GMT',
    issuer =>
        'O=sympa developpers, OU=unit testing, CN=Test CA, emailAddress=test@sympa.org',
};

SKIP: {
    skip 'Crypt::OpenSSL::X509 not installed', 1
        unless $Crypt::OpenSSL::X509::VERSION;

    is_deeply(Sympa::Tools::SMIME::parse_cert(file => $ca_cert_file,),
        $ca_cert_data, 'CA certificate file parsing');
}

sub touch {
    my ($file) = @_;
    open(my $fh, '>', $file) or die "Can't create file: $ERRNO";
    close $fh;
}
