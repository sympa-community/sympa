### Requirements
##

# Minimum version of Perl required.
# Notation suggested on https://metacpan.org/pod/Carton#PERL-VERSIONS
requires 'perl', '5.16.0';

# This module provides zip/unzip for archive and shared document download/upload
requires 'Archive::Zip', '>= 1.05';

# Required to run Sympa web interface
requires 'CGI', '>= 3.51';

# Note: 'CGI::Cookie' is included in CGI.

# Note: 'CGI::Util' is included in CGI.

# WWSympa, Sympa's web interface can run as a FastCGI (i.e. a persistent CGI). If you install this module, you will also need to install FCGI module
# Note: 'CGI::Fast' was included in core of Perl < 5.22 so that dependency
#   upon 'FCGI' might not be enforced.
# Note: 1.08 is at least version with CGI 3.51.
requires 'CGI::Fast', '>= 1.08';

# Used to construct various singleton classes.
requires 'Class::Singleton', '>= 1.03';

# A generic Database Driver, required by Sympa to access Subscriber information and User preferences. An additional Database Driver is required for each database type you wish to connect to.
requires 'DBI', '>= 1.48';

# Note: 'DateTime' is used by DateTime::Format::Mail.

# Used to decode date and time in message headers
requires 'DateTime::Format::Mail', '>= 0.28';

# Used to decode date and time in message headers
requires 'DateTime::TimeZone', '>= 0.59';

# Used to compute MD5 digests for passwords, etc.
requires 'Digest::MD5', '>= 2.00';

# Module for character encoding processing
requires 'Encode';

# WWSympa, Sympa's web interface can run as a FastCGI (i.e. a persistent CGI). If you install this module, you will also need to install the associated FastCGI frontend, e.g. mod_fcgid for Apache.
requires 'FCGI', '>= 0.67';

# Note: 'Fcntl' is core module.

# Note: 'File::Basename' is core module.

# Used to copy file hierarchies
requires 'File::Copy::Recursive', '>= 0.36';

# Required to perform NFS-safe file locking
requires 'File::NFSLock';

# Used to create or remove paths
requires 'File::Path', '>= 2.08';

# Note: 'HTML::Entities' >=3.59 is included in HTML-Parser which
#   'HTML::StripScripts::Parser' depends on.

# Used to compute plaindigest messages from HTML
requires 'HTML::FormatText';

# Note: 'HTML::Parser' is used by HTML::StripScripts::Parser.

# Required for XSS protection on the web interface
requires 'HTML::StripScripts::Parser', '>= 1.03';

# Used to compute plaindigest messages from HTML
requires 'HTML::TreeBuilder';

# Note: 'HTTP::Cookies' is included or depended on by libwww-perl which
#   includes 'LWP::UserAgent'.

# Note: 'HTTP::Request' is included or depended on by libwww-perl which
#   includes 'LWP::UserAgent'.

# Internal use for filehandle processing
requires 'IO::File', '>= 1.10';

# Internal use for string processing
requires 'IO::Scalar';

# Required when including members of a remote list
requires 'LWP::UserAgent';

# Set of various subroutines to handle scalar
# Note: The pure-perl version of Scalar::Util::looks_like_number() was
#   unstable. To force using XS version, check existence of 'List::Util::XS'.
requires 'List::Util::XS', '>= 1.20';

# Internationalization functions
# Note: 1.22 or later is recommended.
requires 'Locale::Messages', '>= 1.20';

# MHonArc is used to build Sympa web archives
requires 'MHonArc::UTF8', '>= 2.6.24';

# Required to compute digest for password and emails
requires 'MIME::Base64', '>= 3.03';

# Used to encode mail body using a different charset
requires 'MIME::Charset', '>= 1.011.3';

# Required to decode/encode SMTP header fields without breaking character encoding
requires 'MIME::EncWords', '>= 1.014';

# Used to compose HTML mail from the web interface
requires 'MIME::Lite::HTML', '>= 1.23';

# Provides libraries for manipulating MIME messages
requires 'MIME::Tools', '>= 5.423';

# Used to parse or build mailboxes in message headers
requires 'Mail::Address', '>= 1.70';

# Used to check netmask within Sympa authorization scenario rules
requires 'Net::CIDR', '>= 0.16';

# Note: 'Scalar::Util' is included in Scalar-List-Utils which includes
#   'List::Util'.

# Used to record system log via syslog
requires 'Sys::Syslog', '>= 0.03';

# Sympa template format, used for web pages and other mail, config file templates. See http://template-toolkit.org/.
requires 'Template', '>= 2.21';

# Used to show progress bar by command line utilities
requires 'Term::ProgressBar', '>= 2.09';

# Used to fold lines in HTML mail composer and system messages, prior to Text::Wrap
requires 'Text::LineFold', '>= 2018.012';

# Used to get time with sub-second precision
requires 'Time::HiRes', '>= 1.29';

# Used to create URI containing non URI-canonical characters.
# Note: '3.28' is the version included in URI-1.35.
requires 'URI::Escape', '>= 3.28';

# Note: 'Unicode::GCString' is included in Unicode-LineBreak which includes
#   'Text::LineFold'.

# Used to parse list configuration templates and instanciate list families
# libxml2-devel is needed to build the Perl code
requires 'XML::LibXML', '>= 1.70';

### Recommendations
##

# Use XS version of some modules to make Sympa faster
# Used to make copy of internal data structures.
recommends 'Clone', '>= 0.31';

# Used to encrypt passwords with the Bcrypt hash algorithm
recommends 'Crypt::Eksblowfish', '>= 0.009';

# Used for configureable hardening of passwords via the password_validation sympa.conf directive.
recommends 'Data::Password', '>= 1.07';

# Useful when running command line utilities in the console not supporting UTF-8 encoding
recommends 'Encode::Locale', '>= 1.02';

# Note: 'Mail::DKIM::Signer' is included in Mail-DKIM.

# Note: 'Mail::DKIM::TextWrap' is included in Mail-DKIM.

# Required in order to use DKIM features (both for signature verification and signature insertion)
recommends 'Mail::DKIM::Verifier', '>= 0.37';

# This is required if you set a value for "dmarc_protection_mode" which requires DNS verification
recommends 'Net::DNS', '>= 0.65';

# This is required if you set "list_check_smtp" sympa.conf parameter, used to check existing aliases before mailing list creation.
recommends 'Net::SMTP';

# Normalizes file names represented by Unicode
# Note: Perl 5.8.1 bundles version 0.23.
# Note: Perl 5.10.1 bundles 1.03 (per Unicode 5.1.0).
recommends 'Unicode::Normalize', '>= 1.03';

recommends 'Unicode::UTF8', '>= 0.58';

### Features
##

feature 'cas', 'CAS Single Sign-On client libraries. Required if you configure Sympa to delegate web authentication to a CAS server.' => sub {
    requires 'AuthCAS', '>= 1.4';
};

feature 'Clone', 'Used to make copy of internal data structures.' => sub {
    requires 'Clone', '>= 0.31';
};

feature 'migrate-from-very-old-version', 'This module provides reversible encryption of user passwords in the database.  Useful when updating from old version with password reversible encryption, or if secure session cookies in non-SSL environments are required.' => sub {
    requires 'Crypt::CipherSaber', '>= 0.50';
};

feature 'Crypt::Eksblowfish', 'Used to encrypt passwords with the Bcrypt hash algorithm.' => sub {
    requires 'Crypt::Eksblowfish', '>= 0.009';
};

feature 'x509-auth', 'Required to extract user certificates for SSL clients and S/MIME messages.' => sub {
    requires 'Crypt::OpenSSL::X509', '>= 1.800.1';
};

feature 'smime', 'Required to sign, verify, encrypt and decrypt S/MIME messages.' => sub {
    requires 'Convert::ASN1';
    requires 'Crypt::SMIME', '>= 0.15';
    # Required to extract user certificates for SSL clients and S/MIME messages.
    # Note: On versions < 1.808, the value() method for extension was broken.
    requires 'Crypt::OpenSSL::X509', '>= 1.808';
};

feature 'csv', 'CSV database driver, required if you include list members, owners or moderators from CSV file.' => sub {
    requires 'DBD::CSV', '>= 0.22';
};

feature 'odbc', 'ODBC database driver, required if you connect to a database via ODBC.' => sub {
    requires 'DBD::ODBC';
};

feature 'oracle', 'Oracle database driver, required if you connect to a Oracle database.' => sub {
    requires 'DBD::Oracle', '>= 1.02';
};

feature 'pg', 'PostgreSQL database driver, required if you connect to a PostgreSQL database.' => sub {
    # postgresql-devel and postgresql-server. PostgreSQL server should be running for make test to succeed
    requires 'DBD::Pg', '>= 2.00';
};

feature 'sqlite', 'SQLite database driver, required if you connect to a SQLite database.' => sub {
    # sqlite-devel. No need to install a server, the SQLite server code being provided with the client code.
    requires 'DBD::SQLite', '>= 1.31';
};

#feature 'sybase', 'Sybase database driver, required if you connect to a Sybase database.' => sub {
#    requires 'DBD::Sybase', '>= 0.90';
#};

feature 'mysql', 'MySQL / MariaDB database driver, required if you connect to a MySQL (or MariaDB) database.' => sub {
    # mysql-devel and myslq-server. MySQL (or MariaDB) server should be running for make test to succeed
    requires 'DBD::mysql', '>= 4.008';
};

feature 'Data::Password', 'Used for configureable hardening of passwords via the password_validation sympa.conf directive.' => sub {
    requires 'Data::Password', '>= 1.07';
};

feature 'Encode::Locale', 'Useful when running command line utilities in the console not supporting UTF-8 encoding.' => sub {
    requires 'Encode::Locale', '>= 1.02';
};

feature 'remote-list-including', 'Required when including members of a remote list.' => sub {
    requires 'LWP::Protocol::https';
};

feature 'Mail::DKIM::Verifier', 'Required in order to use DKIM features (both for signature verification and signature insertion).' => sub {
    requires 'Mail::DKIM::Verifier', '>= 0.37';
};

feature 'Mail::DKIM::ARC::Signer', 'Required in order to use ARC features to add ARC seals.' => sub {
    requires 'Mail::DKIM::ARC::Signer', '>= 0.55';
};

feature 'Net::DNS', 'This is required if you set a value for "dmarc_protection_mode" which requires DNS verification.' => sub {
    requires 'Net::DNS', '>= 0.65';
};

feature 'ipv6', 'Required to support IPv6 with client features.' => sub {
    # Note: Perl 5.14 bundles Socket 0.95 which exports AF_INET6.  Earlier
    #   version also requires Socket6 >= 0.23.
    # Note: Some distributions e.g. RHEL/CentOS 6 do not provide package for
    #   IO::Socket::IP.  If that is the case, use IO::Socket::INET6 instead.
    # Note: Perl 5.20.0 bundles IO::Socket::IP 0.29.
    requires 'IO::Socket::IP', '>= 0.21';
};

feature 'ldap', 'Required to query LDAP directories. Sympa can do LDAP-based authentication ; it can also build mailing lists with LDAP-extracted members.' => sub {
    # openldap-devel is needed to build the Perl code
    requires 'Net::LDAP', '>= 0.40';

    # Note: 'Net::LDAP::Entry' and 'Net::LDAP::Util' are also
    #   included in perl-ldap.
};

feature 'ldap-secure', 'Required to query LDAP directories over TLS.' => sub {
    requires 'Net::LDAP', '>= 0.40';
    requires 'IO::Socket::SSL', '>= 0.90';

    # Note: 'Net::LDAPS' is also included in perl-ldap.
};

feature 'Net::SMTP', 'This is required if you set "list_check_smtp" sympa.conf parameter, used to check existing aliases before mailing list creation.' => sub {
    requires 'Net::SMTP';
};

feature 'soap', 'Required if you want to run the Sympa SOAP server that provides mailing list services via a "web service".' => sub {
    requires 'SOAP::Lite', '>= 0.712';
};

feature 'safe-unicode', 'Sanitises inputs with Unicode text.' => sub {
    # Note: Perl 5.8.1 bundles version 0.23.
    # Note: Perl 5.10.1 bundles 1.03 (per Unicode 5.1.0).
    requires 'Unicode::Normalize', '>= 1.03';
    requires 'Unicode::UTF8', '>= 0.58';
};

on 'test' => sub {
    requires 'Test::Compile';
    requires 'Test::Harness';
    requires 'Test::More';
    requires 'Test::Pod', '>= 1.41';
};

on 'develop' => sub {
    requires 'Test::Fixme';
    requires 'Test::PerlTidy', '== 20130104';
    requires 'Perl::Tidy', '== 20180220';
    requires 'Code::TidyAll';
    requires 'Test::Net::LDAP', '>= 0.06';
};
