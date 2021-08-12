# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2021 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Sympa::Tools::SMIME;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Log;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

=over

=item find_keys ( $that, $operation )

Find the appropriate S/MIME keys/certs for $operation of $that.

$operation can be:

=over

=item 'sign'

return the preferred signing key/cert

=item 'decrypt'

return a list of possible decryption keys/certs

=item 'encrypt'

return the preferred encryption key/cert

=back

Returnss C<($certs, $keys)>.
For 'sign' and 'encrypt', these are strings containing the absolute filename.
For 'decrypt', these are arrayrefs containing absolute filenames.

=back

=cut

# Old name: tools::smime_find_keys()
sub find_keys {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $that = shift || '*';
    my $operation = shift;

    my $dir;
    if (ref $that eq 'Sympa::List') {
        $dir = $that->{'dir'};
    } else {
        $dir = $Conf::Conf{'home'} . '/sympa';    #FIXME
    }

    my (%certs, %keys);
    my $ext = ($operation eq 'sign' ? 'sign' : 'enc');

    unless (opendir(D, $dir)) {
        return undef;
    }

    while (my $fn = readdir(D)) {
        if ($fn =~ /^cert\.pem/) {
            $certs{"$dir/$fn"} = 1;
        } elsif ($fn =~ /^private_key/) {
            $keys{"$dir/$fn"} = 1;
        }
    }
    closedir(D);

    foreach my $c (keys %certs) {
        my $k = $c;
        $k =~ s/\/cert\.pem/\/private_key/;
        unless ($keys{$k}) {
            $log->syslog('debug3', '%s exists, but matching %s doesn\'t',
                $c, $k);
            delete $certs{$c};
        }
    }

    foreach my $k (keys %keys) {
        my $c = $k;
        $c =~ s/\/private_key/\/cert\.pem/;
        unless ($certs{$c}) {
            $log->syslog('debug3', '%s exists, but matching %s doesn\'t',
                $k, $c);
            delete $keys{$k};
        }
    }

    my ($certs, $keys);
    if ($operation eq 'decrypt') {
        $certs = [sort keys %certs];
        $keys  = [sort keys %keys];
    } else {
        if ($certs{"$dir/cert.pem.$ext"}) {
            $certs = "$dir/cert.pem.$ext";
            $keys  = "$dir/private_key.$ext";
        } elsif ($certs{"$dir/cert.pem"}) {
            $certs = "$dir/cert.pem";
            $keys  = "$dir/private_key";
        } else {
            $log->syslog('debug3', '%s: no certs/keys found for %s',
                $that, $operation);
            return undef;
        }
    }

    $log->syslog('debug3', '%s: certs/keys for %s found', $that, $operation);
    return ($certs, $keys);
}

BEGIN {
    eval 'use Crypt::OpenSSL::X509';
    eval 'use Convert::ASN1 qw()';
}

# IN: hashref:
# file => filename
# text => PEM-encoded cert
# OUT: hashref
# email => email address from cert
# subject => distinguished name
# purpose => hashref
#  enc => true if v3 purpose is encryption
#  sign => true if v3 purpose is signing
#
# Old name: tools::smime_parse_cert()
sub parse_cert {
    $log->syslog('debug3', '(%s => %s)', @_);
    my %arg = @_;

    return undef unless $Crypt::OpenSSL::X509::VERSION;

    ## Load certificate
    my $x509;
    if ($arg{'text'}) {
        $x509 = eval { Crypt::OpenSSL::X509->new_from_string($arg{'text'}) };
    } elsif ($arg{'file'}) {
        $x509 = eval { Crypt::OpenSSL::X509->new_from_file($arg{'file'}) };
    } else {
        $log->syslog('err', 'Neither "text" nor "file" given');
        return undef;
    }
    unless ($x509) {
        $log->syslog('err', 'Cannot parse certificate');
        return undef;
    }

    my %res;
    $res{subject} = join '',
        map { '/' . $_->as_string } @{$x509->subject_name->entries};

    # Get email(s).
    # The subjectAltName extension is used. The email() method that gives
    # single address may be used for workaround on malformed certificates.
    my @emails = _get_subjectAltName($x509, 1);    # rfc822Name [1]
    unless (@emails) {
        @emails = ($x509->email) if $x509->email;
    }
    $res{email} =
        {map { (Sympa::Tools::Text::canonic_email($_) => 1) } @emails};

    # Check key usage roughy.
    my %purposes = $x509->extensions_by_name->{keyUsage}->hash_bit_string;
    $res{purpose}->{sign} = $purposes{'Digital Signature'} ? 1 : '';
    $res{purpose}->{enc}  = $purposes{'Key Encipherment'}  ? 1 : '';
    return \%res;
}

sub _get_subjectAltName {
    my $x509        = shift;
    my $context_num = shift;

    my $extensions = $x509->extensions_by_name;

    return
            unless $extensions
        and $extensions->{subjectAltName}
        and $extensions->{subjectAltName}->value =~ /\A#([0-9A-F]+)\z/;

    my $bin = pack 'H*', $1;
    my ($tag, $tnum, $len);

    ($tag, $tnum, $bin, $len) = _parse_asn1_single_value($bin);
    return
        unless defined $tag
        and ($tag & ~Convert::ASN1::ASN_CONSTRUCTOR()) ==
        Convert::ASN1::ASN_SEQUENCE();

    my @ret;
    while (length $bin) {
        my $val;
        ($tag, $tnum, $val, $len) = _parse_asn1_single_value($bin);
        last unless defined $tag;
        $bin = substr $bin, $len;
        next if $tag == 0 and length $val == 0;

        push @ret, $val
            if ($tag & 0xC0) == Convert::ASN1::ASN_CONTEXT()
            and $tnum == $context_num;
    }
    return @ret;
}

sub _parse_asn1_single_value {
    my $bin = shift;

    my ($tb, $tag, $tnum) =
        Convert::ASN1::asn_decode_tag2(substr $bin, 0, 10);
    return unless defined $tb;
    my ($lb, $len) = Convert::ASN1::asn_decode_length(substr $bin, $tb, 10);
    return unless $tb + $lb + $len <= length $bin;

    return ($tag, $tnum, substr($bin, $tb + $lb, $len), $tb + $lb + $len);
}

# NO LONGER USED
# However, this function may be useful because it can extract messages openssl
# can not (e.g. signature part not encoded by BASE64).
sub smime_extract_certs {
    my ($mime, $outfile) = @_;
    $log->syslog('debug2', '(%s)', $mime->mime_type);

    if ($mime->mime_type =~ /application\/(x-)?pkcs7-/) {
        my $pipeout;
        unless (
            open $pipeout,
            '|-', $Conf::Conf{openssl}, 'pkcs7', '-print_certs',
            '-inform' => 'der',
            '-out'    => $outfile
        ) {
            $log->syslog('err', 'Unable to run openssl pkcs7: %m');
            return 0;
        }
        print $pipeout $mime->bodyhandle->as_string;
        close $pipeout;
        my $status = $CHILD_ERROR >> 8;
        if ($status) {
            $log->syslog('err', 'Openssl pkcs7 returned an error: %s',
                $status);
            return 0;
        }
        return 1;
    }
}

1;
