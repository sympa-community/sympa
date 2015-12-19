# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Tools::Password;

use strict;
use warnings;
use Digest::MD5;
use MIME::Base64 qw();
BEGIN { eval 'use Crypt::CipherSaber'; }
BEGIN { eval 'use Data::Password'; }

use Conf;
use Sympa::Language;
use Sympa::Log;

my $log = Sympa::Log->instance;

sub tmp_passwd {
    my $email = shift;

    my $cookie = $Conf::Conf{'cookie'};
    $cookie = '' unless defined $cookie;

    return (
        'init' . substr(Digest::MD5::md5_hex(join '/', $cookie, $email), -8));
}

# global var to store a CipherSaber object
my $cipher;

# create a cipher
sub ciphersaber_installed {
    return $cipher if defined $cipher;

    if ($Crypt::CipherSaber::VERSION) {
        $cipher = Crypt::CipherSaber->new($Conf::Conf{'cookie'});
    } else {
        $cipher = '';
    }
    return $cipher;
}

## encrypt a password
sub crypt_password {
    my $inpasswd = shift;

    ciphersaber_installed();
    return $inpasswd unless $cipher;
    return ("crypt." . MIME::Base64::encode($cipher->encrypt($inpasswd)));
}

## decrypt a password
sub decrypt_password {
    my $inpasswd = shift;
    $log->syslog('debug2', '(%s)', $inpasswd);

    return $inpasswd unless ($inpasswd =~ /^crypt\.(.*)$/);
    $inpasswd = $1;

    ciphersaber_installed();
    unless ($cipher) {
        $log->syslog('info',
            'Password seems crypted while CipherSaber is not installed !');
        return $inpasswd;
    }
    return ($cipher->decrypt(MIME::Base64::decode($inpasswd)));
}

# Old name: Sympa::Session::get_random().
sub get_random {
    # Concatenates two integers for a better entropy.
    return sprintf '%07d%07d', int(rand(10**7)), int(rand(10**7));
}

my @validation_messages = (
    {gettext_id => 'Not between %d and %d characters'},
    {gettext_id => 'Not %d characters or greater'},
    {gettext_id => 'Not less than or equal to %d characters'},
    {gettext_id => 'contains bad characters'},
    {gettext_id => 'contains less than %d character groups'},
    {gettext_id => 'contains over %d leading characters in sequence'},
    {gettext_id => "contains the dictionary word '%s'"},
);

# Old name: tools::password_validation().
sub password_validation {
    my ($password) = @_;

    my $pv = $Conf::Conf{'password_validation'};
    return undef
        unless $pv
            and defined $password
            and $Data::Password::VERSION;

    local (
        $Data::Password::DICTIONARY, $Data::Password::FOLLOWING,
        $Data::Password::GROUPS,     $Data::Password::MINLEN,
        $Data::Password::MAXLEN
    );
    local @Data::Password::DICTIONARIES = @Data::Password::DICTIONARIES;

    my @techniques = split(/\s*,\s*/, $pv);
    foreach my $technique (@techniques) {
        my ($key, $value) = $technique =~ /([^=]+)=(.*)/;
        $key = uc $key;

        if ($key eq 'DICTIONARY') {
            $Data::Password::DICTIONARY = $value;
        } elsif ($key eq 'FOLLOWING') {
            $Data::Password::FOLLOWING = $value;
        } elsif ($key eq 'GROUPS') {
            $Data::Password::GROUPS = $value;
        } elsif ($key eq 'MINLEN') {
            $Data::Password::MINLEN = $value;
        } elsif ($key eq 'MAXLEN') {
            $Data::Password::MAXLEN = $value;
        } elsif ($key eq 'DICTIONARIES') {
            # TODO: How do we handle a list of dictionaries?
            push @Data::Password::DICTIONARIES, $value;
        }
    }
    my $output = Data::Password::IsBadPassword($password);
    return undef unless $output;

    # Translate result if possible.
    my $language = Sympa::Language->instance;
    foreach my $item (@validation_messages) {
        my $format = $item->{'gettext_id'};
        my $regexp = quotemeta $format;
        $regexp =~ s/\\\%[sd]/(.+)/g;

        my ($match, @args) = ($output =~ /($regexp)/i);
        next unless $match;
        return $language->gettext_sprintf($format, @args);
    }
    return $output;
}

1;
