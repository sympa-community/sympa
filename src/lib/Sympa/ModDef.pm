# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::ModDef;

use strict;
use warnings;
use English qw(-no_match_vars);

our %cpan_modules = (
    'Archive::Zip' => {
        required_version => '1.05',
        package_name     => 'Archive-Zip',
        mandatory        => 1,
        'gettext_id' =>
            'this module provides zip/unzip for archive and shared document download/upload',
    },
    'AuthCAS' => {
        required_version => '1.4',
        package_name     => 'AuthCAS',
        'gettext_id' =>
            'CAS Single Sign-On client libraries. Required if you configure Sympa to delegate web authentication to a CAS server.',
    },
    'CGI' => {
        required_version => '3.51',
        package_name     => 'CGI',
        mandatory        => 1,
        'gettext_id'     => 'required to run Sympa web interface',
    },
    # CGI::Cookie is included in CGI.
    # CGI::Fast is included in CGI.
    'Class::Singleton' => {
        required_version => '1.03',
        package_name     => 'Class-Singleton',
        mandatory        => 1,
        'gettext_id'     => 'used to construct various singleton classes.',
    },
    'Crypt::CipherSaber' => {
        required_version => '0.50',
        package_name     => 'Crypt-CipherSaber',
        'gettext_id' =>
            'this module provides reversible encryption of user passwords in the database.  Useful when updating from old version with password reversible encryption, or if secure session cookies in non-SSL environments are required.',
    },
    'Crypt::OpenSSL::X509' => {
        required_version => '1.800.1',
        package_name     => 'Crypt-OpenSSL-X509',
        'gettext_id' =>
            'required to extract user certificates for SSL clients and S/MIME messages.',
    },
    'Crypt::SMIME' => {
        required_version => '0.09',
        package_name => 'Crypt-SMIME',
        'gettext_id' =>
            'required to sign, encrypt or decrypt S/MIME messages.',
    },
    'Data::Password' => {
        required_version => '1.07',
        package_name     => 'Data-Password',
        'gettext_id' =>
            'Used for configureable hardening of passwords via the password_validation sympa.conf directive.',
    },
    # DateTime is used by DateTime::Format::Mail.
    'DateTime::Format::Mail' => {
        required_version => '0.28',
        package_name     => 'DateTime-Format-Mail',
        mandatory        => 1,
        'gettext_id'     => 'used to decode date and time in message headers',
    },
    'DateTime::TimeZone' => {
        required_version => '1.10',
        package_name     => 'DateTime-TimeZone',
        mandatory        => 1,
        'gettext_id'     => 'used to decode date and time in message headers',
    },
    'DB_File' => {
        required_version => '1.75',
        package_name     => 'DB_File',
        mandatory        => 1,
        'gettext_id'     => 'used for maintaining snapshots of list members',
    },
    'DBD::ODBC' => {
        package_name => 'DBD-ODBC',
        'gettext_id' =>
            'ODBC database driver, required if you connect to a database via ODBC.',
    },
    'DBD::Oracle' => {
        required_version => '0.90',
        package_name     => 'DBD-Oracle',
        'gettext_id' =>
            'Oracle database driver, required if you connect to a Oracle database.',
    },
    'DBD::Pg' => {
        required_version => '2.00',
        'gettext_comment' =>
            'postgresql-devel and postgresql-server. PostgreSQL server should be running for make test to succeed',
        package_name => 'DBD-Pg',
        'gettext_id' =>
            'PostgreSQL database driver, required if you connect to a PostgreSQL database.',
    },
    'DBD::SQLite' => {
        required_version => '1.31',
        'gettext_comment' =>
            'sqlite-devel. No need to install a server, the SQLite server code being provided with the client code.',
        package_name => 'DBD-SQLite',
        'gettext_id' =>
            'SQLite database driver, required if you connect to a SQLite database.',
    },
    'DBD::Sybase' => {
        required_version => '0.90',
        package_name     => 'DBD-Sybase',
        'gettext_id' =>
            'Sybase database driver, required if you connect to a Sybase database.',
    },
    'DBD::mysql' => {
        required_version => '4.008',
        'gettext_comment' =>
            'mysql-devel and myslq-server. MySQL (or MariaDB) server should be running for make test to succeed',
        package_name => 'DBD-mysql',
        mandatory    => 1,
        'gettext_id' =>
            'MySQL / MariaDB database driver, required if you connect to a MySQL (or MariaDB) database.',
    },
    'DBI' => {
        required_version => '1.48',
        package_name     => 'DBI',
        mandatory        => 1,
        'gettext_id' =>
            'a generic Database Driver, required by Sympa to access Subscriber information and User preferences. An additional Database Driver is required for each database type you wish to connect to.',
    },
    'Digest::MD5' => {
        required_version => '2.00',
        package_name     => 'Digest-MD5',
        mandatory        => 1,
        'gettext_id'     => 'used to compute MD5 digests for passwords, etc.',
    },
    'Email::Simple' => {
        required_version => '2.100',
        package_name     => 'Email-Simple',
        mandatory        => 1,
        'gettext_id'     => 'Used for email tracking',
    },
    'Encode' => {
        package_name => 'Encode',
        mandatory    => 1,
        'gettext_id' => 'module for character encoding processing',
    },
    'Encode::Locale' => {
        required_version => '1.02',
        package_name     => 'Encode-Locale',
        'gettext_id' =>
            'Useful when running command line utilities in the console not supporting UTF-8 encoding',
    },
    'FCGI' => {
        required_version => '0.67',
        package_name     => 'FCGI',
        'gettext_id' =>
            "WWSympa, Sympa's web interface can run as a FastCGI (i.e. a persistent CGI). If you install this module, you will also need to install the associated FastCGI frontend, e.g. mod_fcgid for Apache.",
    },
    'File::Copy::Recursive' => {
        required_version => '0.36',
        package_name     => 'File-Copy-Recursive',
        mandatory        => 1,
        'gettext_id'     => 'used to copy file hierarchies',
    },
    'File::NFSLock' => {
        package_name => 'File-NFSLock',
        mandatory    => 1,
        'gettext_id' => 'required to perform NFS-safe file locking',
    },
    'HTML::FormatText' => {
        package_name => 'HTML-Format',
        mandatory    => 1,
        'gettext_id' => 'used to compute plaindigest messages from HTML',
    },
    'HTML::StripScripts::Parser' => {
        required_version => '1.03',
        package_name     => 'HTML-StripScripts-Parser',
        mandatory        => 1,
        'gettext_id' => 'required for XSS protection on the web interface',
    },
    'HTML::TreeBuilder' => {
        package_name => 'HTML-Tree',
        mandatory    => 1,
        'gettext_id' => 'used to compute plaindigest messages from HTML',
    },
    'IO::File' => {
        required_version => '1.10',
        package_name     => 'IO',
        mandatory        => 1,
        'gettext_id'     => 'internal use for filehandle processing',
    },
    'IO::Scalar' => {
        package_name => 'IO-stringy',
        mandatory    => 1,
        'gettext_id' => 'internal use for string processing',
    },
    'IO::Socket::SSL' => {
        required_version => '0.90',
        package_name     => 'IO-Socket-SSL',
        'gettext_id' => 'required when including members of a remote list',
    },
    # Net::SSLeay is included in IO-Socket-SSL.
    'JSON::XS' => {
        required_version => '2.32',
        package_name     => 'JSON-XS',
        'gettext_id'     => 'required when using the VOOT protocol',
    },
    # The pure-perl version of Scalar::Util::looks_like_number() was unstable.
    # To force using XS version, check existence of Sympa::List::Util::XS.
    'Sympa::List::Util::XS' => {
        required_version => '1.20',
        package_name     => 'Scalar-List-Utils',
        mandatory        => 1,
        'gettext_id'     => 'set of various subroutines to handle scalar',
    },
    'Locale::Messages' => {
        required_version => '1.22',
        package_name     => 'libintl-perl',
        mandatory        => 1,
        'gettext_id'     => 'internationalization functions',
    },
    'LWP::UserAgent' => {
        package_name => 'libwww-perl',
        mandatory    => 1,
        'gettext_id' => 'required when including members of a remote list',
    },
    'Mail::Address' => {
        required_version => '1.70',
        package_name     => 'MailTools',
        mandatory        => 1,
        'gettext_id' => 'used to parse or build mailboxes in message headers',
    },
    # Mail::DKIM::Signer is included in Mail-DKIM.
    # Mail::DKIM::TextWrap is included in Mail-DKIM.
    'Mail::DKIM::Verifier' => {
        required_version => '0.39',
        package_name     => 'Mail-DKIM',
        'gettext_id' =>
            'required in order to use DKIM features (both for signature verification and signature insertion)',
    },
    'MHonArc::UTF8' => {
        required_version => '2.6.18',
        package_name     => 'MHonArc',
        mandatory        => 1,
        'gettext_id'     => 'MHonArc is used to build Sympa web archives',
    },
    'MIME::Base64' => {
        required_version => '3.03',
        package_name     => 'MIME-Base64',
        mandatory        => 1,
        'gettext_id' => 'required to compute digest for password and emails',
    },
    'MIME::Charset' => {
        required_version => '1.010',
        package_name     => 'MIME-Charset',
        mandatory        => 1,
        'gettext_id' => 'used to encode mail body using a different charset',
    },
    'MIME::EncWords' => {
        required_version => '1.014',
        package_name     => 'MIME-EncWords',
        mandatory        => 1,
        'gettext_id' =>
            'required to decode/encode SMTP header fields without breaking character encoding',
    },
    'MIME::Lite::HTML' => {
        required_version => '1.23',
        package_name     => 'MIME-Lite-HTML',
        mandatory        => 1,
        'gettext_id' => 'used to compose HTML mail from the web interface',
    },
    'MIME::Tools' => {
        required_version => '5.423',
        package_name     => 'MIME-tools',
        mandatory        => 1,
        'gettext_id' => 'provides libraries for manipulating MIME messages',
    },
    'Net::CIDR' => {
        required_version => '0.16',
        package_name     => 'Net-CIDR',
        mandatory        => 1,
        'gettext_id' =>
            'used to check netmask within Sympa autorization scenario rules',
    },
    'Net::DNS' => {
        required_version => '0.65',
        package_name     => 'Net-DNS',
        mandatory        => 1,
        'gettext_id' =>
            'this is required if you set a value for "dmarc_protection_mode" which requires DNS verification',
    },
    'Net::LDAP' => {
        required_version => '0.27',
        'gettext_comment' =>
            'openldap-devel is needed to build the Perl code',
        package_name => 'perl-ldap',
        'gettext_id' =>
            'required to query LDAP directories. Sympa can do LDAP-based authentication ; it can also build mailing lists with LDAP-extracted members.',
    },
    'Net::SMTP' => {
        package_name => 'libnet',
        'gettext_id' =>
            'this is required if you set "list_check_smtp" sympa.conf parameter, used to check existing aliases before mailing list creation.',
    },
    'perl'               => {required_version => '5.008',},
    'Proc::ProcessTable' => {
        package_name     => 'Proc-ProcessTable',
        required_version => '0.44',
        mandatory        => 1,
        'gettext_id' =>
            'Used by the bulk.pl daemon to check the number of slave bulks running.',
    },
    # Scalar::Util is included in Scalar-List-Utils.
    'SOAP::Lite' => {
        required_version => '0.712',
        package_name     => 'SOAP-Lite',
        'gettext_id' =>
            'required if you want to run the Sympa SOAP server that provides ML services via a "web service"',
    },
    'Template' => {
        package_name => 'Template-Toolkit',
        mandatory    => 1,
        'gettext_id' =>
            'Sympa template format, used for web pages and other mail, config file templates. See http://template-toolkit.org/.',
    },
    'Term::ProgressBar' => {
        required_version => '2.09',
        package_name     => 'Term-ProgressBar',
        mandatory        => 1,
        'gettext_id'     => 'used while checking the RDBMS buffer size',
    },
    'Text::LineFold' => {
        required_version => '2011.05',
        package_name     => 'Unicode-LineBreak',
        mandatory        => 1,
        'gettext_id' =>
            'used to fold lines in HTML mail composer and system messages, prior to Text::Wrap',
    },
    'Time::HiRes' => {
        required_version => '1.29',
        package_name     => 'Time-HiRes',
        mandatory        => 1,
        'gettext_id' =>
            'used by sympa.pl --test_database_message_buffer to test database performances',
    },
    'URI::Escape' => {
        required_version => '1.35',
        package_name     => 'URI-Escape',
        mandatory        => 1,
        'gettext_id' =>
            'Used to create URI containing non URI-canonical characters.',
    },
    'XML::LibXML' => {
        'gettext_comment' => 'libxml2-devel is needed to build the Perl code',
        package_name      => 'XML-LibXML',
        mandatory         => 1,
        'gettext_id' =>
            'used to parse list configuration templates and instanciate list families',
    },
);

$cpan_modules{'Unicode::CaseFold'} = {
    required_version => '0.02',
    package_name     => 'Unicode-CaseFold',
    mandatory        => 1,
    'gettext_id'     => 'used to compute case-folding search keys'
    }
    if 5.008 < $] and $] < 5.016;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ModDef - Definition of dependent modules

=head1 DESCRIPTION

This module keeps definition of modules required by Sympa.

=head2 Global variable

=over

=item %cpan_modules

This defines the modules.
Each item has Perl package name as key and hashref containing pairs below
as value.

=over

=item required_version =E<gt> STRING

Minimum version of package.
Assume required_version = '1.0' if not specified.

=item package_name =E<gt> STRING

Name of CPAN module.

=item mandatory =E<gt> 1|0

If 1, the module is mandatory.  Default is 0.

=item gettext_id =E<gt> STRING

Usage of this package,

=item gettext_comment =E<gt> STRING

Description of prerequisites if any.

=back

=back

=head1 SEE ALSO

sympa_wizard(1).

=cut
