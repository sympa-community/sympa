# LDAPSource.pm - This module includes common LDAP related functions
#<!-- RCS Identication ; $Revision: 1.3 $ --> 

#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package LDAPSource;

use strict;
require Exporter;
require 'tools.pl';
require 'tt2.pl';
our @ISA = qw(Exporter);
our @EXPORT = qw(%date_format);
our @EXPORT_OK = qw(connect query disconnect fetch ping quote);

use Carp;

use Conf;
use Log;
use List;


############################################################
#  connect
############################################################
#  Connect to an LDAP directory. This could be called as
#  a LDAPSource object member, or as a static sub. 
#  
# IN : -$param_ref : ref to a Hash of config data if statically
#       called
#      -$options : ref to a hash. Options for the connection process.
#         currently accepts 'keep_trying' : wait and retry until
#         db connection is ok (boolean) ; 'warn' : warn
#         listmaster if connection fails (boolean)
# OUT : $ldap_handler
#     | undef
#
##############################################################
sub connect {
    my $self = undef;
    my ($param, $options) = @_;

    my $ldap_handler;

    # are we called as an instance member ?
    if (ref($param) ne 'HASH') {
    	$self = $param;
    	$param = $self->{'param'};
    }
    
    unless (eval "require Net::LDAP") {
	do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;

    unless (eval "require Net::LDAP::Entry") {
	do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP::Entry;
    
    unless (eval "require Net::LDAP::Message") {
	do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP::Message;


    ## Map equivalent parameters (depends on the calling context : included members, scenario, authN
    ## Also set defaults
    foreach my $p (keys %{$param}) {
	unless ($p =~ /^ldap_/) {
	    my $p_equiv = 'ldap_'.$p;
	    $param->{$p_equiv} = $param->{$p} unless (defined $param->{$p_equiv}); ## Respect existing entries
	}
    }
    $param->{'timeout'} ||= 3;
    $param->{'async'} = 1;
    
    ## Do we have all required parameters
    foreach my $ldap_param ('ldap_host') {
	unless ($param->{$ldap_param}) {
	    do_log('info','Missing parameter %s for LDAP connection', $ldap_param);
	    return undef;
	}
    }

    my $host_entry;
    ## There might be multiple alternate hosts defined
    foreach $host_entry (split(/,/, $param->{'ldap_host'})){

	## Remove leading and trailing spaces
	$host_entry =~ s/^\s*(\S.*\S)\s*$/$1/;
	my ($host,$port) = split(/:/,$host_entry);
	## If port a 'port' entry was defined, use it as default
	$param->{'port'} ||= $port if (defined $port);

	## value may be '1' or 'yes' depending on the context
	if ($param->{'ldap_use_ssl'} eq 'yes' || $param->{'ldap_use_ssl'} eq '1') {
	    $param->{'sslversion'} = $param->{'ldap_ssl_version'} if ($param->{'ldap_ssl_version'});
	    $param->{'ciphers'} = $param->{'ldap_ssl_ciphers'} if ($param->{'ldap_ssl_ciphers'});
	    
	    unless (eval "require Net::LDAPS") {
		do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		return undef;
	    } 
	    require Net::LDAPS;
	    
	    $ldap_handler = Net::LDAPS->new($host, port => $port, %{$param});
	}else {
	    $ldap_handler = Net::LDAP->new($host, %{$param});
	}

	next unless (defined $ldap_handler );

	## if $ldap_handler is defined, skip alternate hosts
	last;
    }

    unless (defined $ldap_handler ){
	&do_log ('err',"Unable to connect to the LDAP server '%s'",$param->{'ldap_host'});
	return undef;
    }

    ## Using startçtls() will convert the existing connection to using Transport Layer Security (TLS), which pro-
    ## vides an encrypted connection. This is only possible if the connection uses LDAPv3, and requires that the
    ## server advertizes support for LDAP_EXTENSION_START_TLS. Use "supported_extension" in Net::LDAP::RootDSE to
    ## check this.
    if ($param->{'use_start_tls'}) {
	my %tls_param;
	$tls_param{'sslversion'} = $param->{'ssl_version'} if ($param->{'ssl_version'});
	$tls_param{'ciphers'} = $param->{'ssl_ciphers'} if ($param->{'ssl_ciphers'});
	$tls_param{'verify'} = $param->{'ca_verify'} || "optional";
	$tls_param{'capath'} = $param->{'ca_path'} || "/etc/ssl";
	$tls_param{'cafile'} = $param->{'ca_file'} if ($param->{'ca_file'});
	$tls_param{'clientcert'} = $param->{'ssl_cert'} if ($param->{'ssl_cert'});
	$tls_param{'clientkey'} = $param->{'ssl_key'} if ($param->{'ssl_key'});
	$ldap_handler->start_tls(%tls_param);
    }

    my $cnx;
    ## Not always anonymous...
    if (defined ($param->{'ldap_bind_dn'}) && defined ($param->{'ldap_bind_password'})) {
	$cnx = $ldap_handler->bind($param->{'ldap_bind_dn'}, password =>$param->{'ldap_bind_password'});
    }else {
	$cnx = $ldap_handler->bind;
    }
    
    unless (defined($cnx) && ($cnx->code() == 0)){
	&do_log ('err',"Failed to bind to LDAP server : '%s', Ldap server error : '%s'", $host_entry, $cnx->error, $cnx->server_error);
	$ldap_handler->unbind;
	return undef;
    }
    &do_log ('debug',"Bound to LDAP host '$host_entry'");
    
    $self->{'ldap_handler'} = $ldap_handler if $self;
    
    do_log('debug2','Connected to Database %s',$param->{'db_name'});
    return $ldap_handler;

}

sub query {
    my ($self, $sql_query) = @_;
    unless ($self->{'sth'} = $self->{'dbh'}->prepare($sql_query)) {
        do_log('err','Unable to prepare SQL query : %s', $self->{'dbh'}->errstr);
        return undef;
    }
    unless ($self->{'sth'}->execute) {
        do_log('err','Unable to perform SQL query %s : %s ',$sql_query, $self->{'dbh'}->errstr);
        return undef;
    }

}

## Does not make sense in LDAP context
sub ping {
}

## Does not make sense in LDAP context
sub quote {
}

sub fetch {
    my $self = shift;
    return $self->{'sth'}->fetchrow_arrayref;
}

sub disconnect {
    my $self = shift;
    $self->{'ldap_handler'}->unbind if $self->{'ldap_handler'};
}

## Try to create the database
sub create_db {
    &do_log('debug3', 'List::create_db()');    

    &do_log('notice','Trying to create %s database...', $Conf{'db_name'});

    unless ($Conf{'db_type'} eq 'mysql') {
	&do_log('err', 'Cannot create %s DB', $Conf{'db_type'});
	return undef;
    }

    my $drh;
    unless ($drh = DBI->connect("DBI:mysql:dbname=mysql;host=localhost", 'root', '')) {
	&do_log('err', 'Cannot connect as root to database');
	return undef;
    }

    ## Create DB
    my $rc = $drh->func("createdb", $Conf{'db_name'}, 'localhost', $Conf{'db_user'}, $Conf{'db_passwd'}, 'admin');
    unless (defined $rc) {
	&do_log('err', 'Cannot create database %s : %s', $Conf{'db_name'}, $drh->errstr);
	return undef;
    }

    ## Re-connect to DB (to prevent "MySQL server has gone away" error)
    unless ($drh = DBI->connect("DBI:mysql:dbname=mysql;host=localhost", 'root', '')) {
	&do_log('err', 'Cannot connect as root to database');
	return undef;
    }

    ## Grant privileges
    unless ($drh->do("GRANT ALL ON $Conf{'db_name'}.* TO $Conf{'db_user'}\@localhost IDENTIFIED BY '$Conf{'db_passwd'}'")) {
	&do_log('err', 'Cannot grant privileges to %s on database %s : %s', $Conf{'db_user'}, $Conf{'db_name'}, $drh->errstr);
	return undef;
    }

    &do_log('notice', 'Database %s created', $Conf{'db_name'});

    ## Reload MysqlD to take changes into account
    my $rc = $drh->func("reload", $Conf{'db_name'}, 'localhost', $Conf{'db_user'}, $Conf{'db_passwd'}, 'admin');
    unless (defined $rc) {
	&do_log('err', 'Cannot reload mysqld : %s', $drh->errstr);
	return undef;
    }

    $drh->disconnect();

    return 1;
}

sub ping {
    my $self = shift;
    return $self->{'dbh'}->ping; 
}

sub quote {
    my ($self, $string, $datatype) = @_;
    
    return $self->{'dbh'}->quote($string, $datatype); 
}

## Packages must return true.
1;
