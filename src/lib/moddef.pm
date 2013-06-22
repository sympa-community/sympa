# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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

=head1 NAME

moddef - Definition of dependent modules

=head1 DESCRIPTION

This module keeps definition of modules required by Sympa.

=cut

package moddef;

use strict;

## This defines the modules :
##   required_version : Minimum version of package.
##            Assume required_version = 1.0 if not specified.
##   package_name : Name of CPAN module.
##   mandatory : 1|0: if 1, the module is mandatory.  Default is 0.
##   gettext_id : Usage of this package,
##   gettext_comment : Description of prerequisites if any.

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
	'Crypt::CipherSaber' => {
		required_version => '0.50',
		package_name     => 'Crypt-CipherSaber',
		'gettext_id' =>
			'this module provides reversible encryption of user passwords in the database.  Useful when updating from old version with password reversible encryption, or if secure session cookies in non-SSL environments are required.',
	},
	'Crypt::OpenSSL::Bignum' => {
		required_version => '0.04',
		package_name     => 'Crypt-OpenSSL-Bignum',
		mandatory        => 1,
		'gettext_id' =>
			'required to prevent Mail::DKIM from crashing Sympa processes.',
	},
	'DB_File' => {
		required_version => '1.75',
		package_name     => 'DB_File',
		mandatory        => 1,
		'gettext_id' =>
			' used for maintaining snapshots of list members',
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
			'postgresql-devel and postgresql-server. postgresql should be running for make test to succeed',
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
			'mysql-devel and myslq-server. mysql should be running for make test to succeed',
		package_name => 'DBD-mysql',
		mandatory    => 1,
		'gettext_id' =>
			'Mysql database driver, required if you connect to a Mysql database.\nYou first need to install the Mysql server and have it started before installing the Perl DBD module.',
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
		'gettext_id' =>
			'used to compute MD5 digests for passwords, etc',
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
			'WWSympa, Sympa\'s web interface can run as a FastCGI (i.e. a persistent CGI). If you install this module, you will also need to install the associated FastCGI frontend, e.g. mod_fcgid for Apache.',
	},
	'File::Copy::Recursive' => {
		required_version => '0.36',
		package_name     => 'File-Copy-Recursive',
		mandatory        => 1,
		'gettext_id'     => 'used to copy file hierarchies',
	},
	'File::NFSLock' => {
		package_name => 'File-NFSLock',
		'gettext_id' =>
			'required to perform NFS lock ; see also lock_method sympa.conf parameter'
	},
	'HTML::FormatText' => {
		package_name => 'HTML-Format',
		mandatory    => 1,
		'gettext_id' =>
			'used to compute plaindigest messages from HTML',
	},
	'HTML::StripScripts::Parser' => {
		required_version => '1.03',
		package_name     => 'HTML-StripScripts-Parser',
		mandatory        => 1,
		'gettext_id' =>
			'required for XSS protection on the web interface',
	},
	'HTML::TreeBuilder' => {
		package_name => 'HTML-Tree',
		mandatory    => 1,
		'gettext_id' =>
			'used to compute plaindigest messages from HTML',
	},
	'IO::Scalar' => {
		package_name => 'IO-stringy',
		mandatory    => 1,
		'gettext_id' => 'internal use for string processing',
	},
	'IO::Socket::SSL' => {
		required_version => '0.90',
		package_name     => 'IO-Socket-SSL',
		'gettext_id' =>
			'required when including members of a remote list',
	},
	'IO::Socket::INET6' => {
		required_version => '2.69',
		package_name     => 'IO-Socket-INET6',
		mandatory        => 1,
		'gettext_id' =>
			'required to prevent Mail::DKIM from crashing Sympa processes.',
	},
	'JSON::XS' => {
		required_version => '2.32',
		package_name     => 'JSON-XS',
		'gettext_id'     => 'required when using the VOOT protocol',
	},
	'Locale::Messages' => {
		package_name => 'libintl-perl',
		mandatory    => 1,
		'gettext_id' => 'internationalization functions',
	},
	'LWP' => {
		package_name => 'libwww-perl',
		mandatory    => 1,
		'gettext_id' =>
			'required when including members of a remote list',
	},
	'Mail::Address' => {
		required_version => '1.70',
		package_name     => 'MailTools',
		mandatory        => 1,
		'gettext_id' =>
			'used to parse or build mailboxes in message headers',
	},
	'Mail::DKIM' => {
		required_version => '0.36',
		package_name     => 'Mail-DKIM',
		'gettext_id' =>
			'required in order to use DKIM features (both for signature verification and signature insertion)',
	},
	'MHonArc::UTF8' => {
		required_version => '2.6.18',
		package_name     => 'MHonArc',
		mandatory        => 1,
		'gettext_id' => 'mhonarc is used to build Sympa web archives',
	},
	'MIME::Base64' => {
		required_version => '3.03',
		package_name     => 'MIME-Base64',
		mandatory        => 1,
		'gettext_id' =>
			'required to compute digest for password and emails',
	},
	'MIME::Charset' => {
		required_version => '1.010',
		package_name     => 'MIME-Charset',
		mandatory        => 1,
		'gettext_id' =>
			'used to encode mail body using a different charset',
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
		'gettext_id' =>
			'used to compose HTML mail from the web interface',
	},
	'MIME::Tools' => {
		required_version => '5.423',
		package_name     => 'MIME-tools',
		mandatory        => 1,
		'gettext_id' =>
			'provides libraries for manipulating MIME messages',
	},
	'Net::LDAP' => {
		required_version => '0.27',
		'gettext_comment' =>
			'openldap-devel is needed to build the Perl code',
		package_name => 'perl-ldap',
		'gettext_id' =>
			'required to query LDAP directories. Sympa can do LDAP-based authentication ; it can also build mailing lists with LDAP-extracted members.',
	},
	'Net::Netmask' => {
		required_version => '1.9015',
		package_name     => 'Net-Netmask',
		mandatory        => 1,
		'gettext_id' =>
			'used to check netmask within Sympa autorization scenario rules',
	},
	'Net::SMTP' => {
		package_name => 'libnet',
		'gettext_id' =>
			'this is required if you set \'list_check_smtp\' sympa.conf parameter, used to check existing aliases before mailing list creation.',
	},
	'OAuth::Lite' => {
		package_name     => 'OAuth-Lite',
		required_version => '1.31',
		'gettext_id' =>
			'This is required if you want to use the VOOT protocol.',
	},
	'perl'               => {required_version => '5.008',},
	'Proc::ProcessTable' => {
		package_name     => 'Proc-ProcessTable',
		required_version => '0.44',
		mandatory        => 1,
		'gettext_id' =>
			'Used by the bulk.pl daemon to check the number of slave bulks running.',
	},
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
		'gettext_id' => 'used while checking the RDBMS buffer size',
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
		'gettext_comment' =>
			'libxml2-devel is needed to build the Perl code',
		package_name => 'XML-LibXML',
		mandatory    => 1,
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
	if 5.008 < $] and
		$] < 5.016;

1;
