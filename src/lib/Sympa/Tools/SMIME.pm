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

BEGIN { eval 'use Crypt::OpenSSL::X509'; }

use Conf;
use Sympa::Tools::Text;

# Old name: tools::smime_find_keys()
sub find_keys {
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

    my $dh;
    return undef unless opendir $dh, $dir;

    while (my $fn = readdir $dh) {
        if ($fn =~ /^cert\.pem/) {
            $certs{"$dir/$fn"} = 1;
        } elsif ($fn =~ /^private_key/) {
            $keys{"$dir/$fn"} = 1;
        }
    }
    closedir $dh;

    foreach my $c (keys %certs) {
        my $k = $c;
        $k =~ s/\/cert\.pem/\/private_key/;
        unless ($keys{$k}) {
            delete $certs{$c};
        }
    }

    foreach my $k (keys %keys) {
        my $c = $k;
        $c =~ s/\/private_key/\/cert\.pem/;
        unless ($certs{$c}) {
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
            return undef;
        }
    }

    return ($certs, $keys);
}

# Old name: tools::smime_parse_cert()
sub parse_cert {
    my %arg = @_;

    return undef unless $Crypt::OpenSSL::X509::VERSION;

    ## Load certificate
    my $x509;
    if ($arg{'text'}) {
        $x509 = eval { Crypt::OpenSSL::X509->new_from_string($arg{'text'}) };
    } elsif ($arg{'file'}) {
        $x509 = eval { Crypt::OpenSSL::X509->new_from_file($arg{'file'}) };
    } else {
        die 'bug in logic. Ask developer';
    }
    unless ($x509) {
        return undef;
    }

    my %res;
    $res{subject}  = $x509->subject;
    $res{notAfter} = $x509->notAfter;
    $res{issuer}   = $x509->issuer;

    my @emails =
        map  { Sympa::Tools::Text::canonic_email($_) }
        grep { Sympa::Tools::Text::valid_email($_) }
        split / +/, ($x509->email // '');
    $res{emails} = [@emails];
    $res{email} = {map { ($_ => 1) } @emails};

    # Check key usage roughy.
    my %purposes = $x509->extensions_by_name->{keyUsage}->hash_bit_string;
    $res{purpose}->{sign} = $purposes{'Digital Signature'} ? 1 : '';
    $res{purpose}->{enc}  = $purposes{'Key Encipherment'}  ? 1 : '';
    return \%res;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Tools::SMIME - Tools for S/MIME messages and X.509 certificates

=head1 DESCRIPTION

=head2 Functions

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

=item parse_cert ( C<text>|C<file> =E<gt> $content )

Parses X.509 certificate.

Options:

=over

=item C<file> =E<gt> $filename

=item C<text> =E<gt> $text

Specifies PEM-encoded certificate.

=back

Returns a hashref containing these items:

=over

=item {email}

hashref with email addresses from cert as keys

=item {emails}

arrayref with email addresses from cert.
This was added on Sympa 6.2.67b.

=item {subject}

distinguished name

=item {purpose}

hashref containing:

=over

=item {enc}

true if v3 purpose is encryption

=item {sign}

true if v3 purpose is signing

=back

=item TBD.

=back

If parsing failed, returns C<undef>.

=back

=head1 HISTORY

TBD.

=cut
