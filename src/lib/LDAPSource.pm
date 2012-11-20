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

use Exporter;
use Datasource;
use Carp;

#use tools; # not used
#use tt2; # not used
#use Conf; # not used
use Log;
#use List; # not used
use Data::Dumper;

our @ISA = qw(Datasource Exporter);
our @EXPORT = qw(%date_format);
our @EXPORT_OK = qw(connect query disconnect fetch ping quote set_fetch_timeout);

sub new {
    my $pkg = shift;
    my $param = shift;
    my $self = $param;
    &Log::do_log('debug','Creating new LDAPSource object');
    ## Map equivalent parameters (depends on the calling context : included members, scenario, authN
    ## Also set defaults
    foreach my $p (keys %{$self}) {
	unless ($p =~ /^ldap_/) {
	    my $p_equiv = 'ldap_'.$p;
	    $self->{$p_equiv} = $self->{$p} unless (defined $self->{$p_equiv}); ## Respect existing entries
	}
    }

    $self->{'timeout'} ||= 3;
    $self->{'async'} = 1;
    $self->{'ldap_bind_dn'} = $self->{'user'};
    $self->{'ldap_bind_password'} = $self->{'passwd'};

    $self = $pkg->SUPER::new($self);
    bless $self, $pkg;
    
    
    unless (eval "require Net::LDAP") {
	&Log::do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;

    unless (eval "require Net::LDAP::Entry") {
	&Log::do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP::Entry;
    
    unless (eval "require Net::LDAP::Message") {
	&Log::do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP::Message;
    return $self;
}

############################################################
#  connect
############################################################
#  Connect to an LDAP directory. This could be called as
#  a LDAPSource object member, or as a static sub. 
#  
# IN : -$options : ref to a hash. Options for the connection process.
#         currently accepts 'keep_trying' : wait and retry until
#         db connection is ok (boolean) ; 'warn' : warn
#         listmaster if connection fails (boolean)
# OUT : $self->{'ldap_handler'}
#     | undef
#
##############################################################
sub connect {
    my $self = shift;
    my $options = shift;

    ## Do we have all required parameters
    foreach my $ldap_param ('ldap_host') {
	unless ($self->{$ldap_param}) {
	    &Log::do_log('info','Missing parameter %s for LDAP connection', $ldap_param);
	    return undef;
	}
    }

    my $host_entry;
    ## There might be multiple alternate hosts defined
    foreach $host_entry (split(/,/, $self->{'ldap_host'})){

	## Remove leading and trailing spaces
	$host_entry =~ s/^\s*(\S.*\S)\s*$/$1/;
	my ($host,$port) = split(/:/,$host_entry);
	## If port a 'port' entry was defined, use it as default
	$self->{'port'} ||= $port if (defined $port);

	## value may be '1' or 'yes' depending on the context
	if ($self->{'ldap_use_ssl'} eq 'yes' || $self->{'ldap_use_ssl'} eq '1') {
	    $self->{'sslversion'} = $self->{'ldap_ssl_version'} if ($self->{'ldap_ssl_version'});
	    $self->{'ciphers'} = $self->{'ldap_ssl_ciphers'} if ($self->{'ldap_ssl_ciphers'});
	    
	    unless (eval "require Net::LDAPS") {
		&Log::do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		return undef;
	    } 
	    require Net::LDAPS;
	    
	    $self->{'ldap_handler'} = Net::LDAPS->new($host, port => $port, %{$self});
	}else {
	    $self->{'ldap_handler'} = Net::LDAP->new($host, %{$self});
	}

	next unless (defined $self->{'ldap_handler'} );

	## if $self->{'ldap_handler'} is defined, skip alternate hosts
	last;
    }

    unless (defined $self->{'ldap_handler'} ){
	&Log::do_log ('err',"Unable to connect to the LDAP server '%s'",$self->{'ldap_host'});
	return undef;
    }

    ## Using start_tls() will convert the existing connection to using Transport Layer Security (TLS), which pro-
    ## vides an encrypted connection. This is only possible if the connection uses LDAPv3, and requires that the
    ## server advertizes support for LDAP_EXTENSION_START_TLS. Use "supported_extension" in Net::LDAP::RootDSE to
    ## check this.
    if ($self->{'use_start_tls'}) {
	my %tls_param;
	$tls_param{'sslversion'} = $self->{'ssl_version'} if ($self->{'ssl_version'});
	$tls_param{'ciphers'} = $self->{'ssl_ciphers'} if ($self->{'ssl_ciphers'});
	$tls_param{'verify'} = $self->{'ca_verify'} || "optional";
	$tls_param{'capath'} = $self->{'ca_path'} || "/etc/ssl";
	$tls_param{'cafile'} = $self->{'ca_file'} if ($self->{'ca_file'});
	$tls_param{'clientcert'} = $self->{'ssl_cert'} if ($self->{'ssl_cert'});
	$tls_param{'clientkey'} = $self->{'ssl_key'} if ($self->{'ssl_key'});
	$self->{'ldap_handler'}->start_tls(%tls_param);
    }

    my $cnx;
    ## Not always anonymous...
    if (defined ($self->{'ldap_bind_dn'}) && defined ($self->{'ldap_bind_password'})) {
	$cnx = $self->{'ldap_handler'}->bind($self->{'ldap_bind_dn'}, password =>$self->{'ldap_bind_password'});
    }else {
	$cnx = $self->{'ldap_handler'}->bind;
    }
    
    unless (defined($cnx) && ($cnx->code() == 0)){
	&Log::do_log ('err',"Failed to bind to LDAP server : '%s', Ldap server error : '%s'", $host_entry, $cnx->error, $cnx->server_error);
	$self->{'ldap_handler'}->unbind;
	return undef;
    }
    &Log::do_log ('debug',"Bound to LDAP host '$host_entry'");
    
    &Log::do_log('debug','Connected to Database %s',$self->{'db_name'});
    return $self->{'ldap_handler'};

}

sub query {
    my ($self, $sql_query) = @_;
    unless ($self->{'sth'} = $self->{'dbh'}->prepare($sql_query)) {
        &Log::do_log('err','Unable to prepare SQL query : %s', $self->{'dbh'}->errstr);
        return undef;
    }
    unless ($self->{'sth'}->execute) {
        &Log::do_log('err','Unable to perform SQL query %s : %s ',$sql_query, $self->{'dbh'}->errstr);
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

## Does not make sense in LDAP context
sub create_db {
}

sub disconnect {
    my $self = shift;
    $self->{'ldap_handler'}->unbind if $self->{'ldap_handler'};
}

## Does not make sense in LDAP context
sub set_fetch_timeout {
}

## Packages must return true.
1;
