# Fetch.pm - This module includes functions to fetch remote files
#
#<!-- RCS Identication ; $Revision$ ; $Date$ -->
#
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

package Fetch;

use Log;

# request a document using https, return status and content
sub get_https{
	my $host = shift;
	my $port = shift;
	my $path = shift;
    	my $client_cert = shift;
	my $client_key = shift;
	my $ssl_data= shift;

	my $key_passwd = $ssl_data->{'key_passwd'};
	my $trusted_ca_file = $ssl_data->{'cafile'};
	my $trusted_ca_path = $ssl_data->{'capath'};

	do_log ('debug','get_https (%s,%s,%s,%s,%s,%s,%s,%s)',$host,$port,$path,$client_cert,$client_key,$key_passwd,$trusted_ca_file,$trusted_ca_path );

	unless ( -r ($trusted_ca_file) ||  (-d $trusted_ca_path )) {
	    do_log ('err',"error : incorrect access to cafile $trusted_ca_file bor capath $trusted_ca_path");
	    return undef;
	}

	unless (eval "require IO::Socket::SSL") {
	    do_log('err',"Unable to use SSL library, IO::Socket::SSL required, install IO-Socket-SSL (CPAN) first");
	    return undef;
	}
	require IO::Socket::SSL;
	
	unless (eval "require LWP::UserAgent") {
	    do_log('err',"Unable to use LWP library, LWP::UserAgent required, install LWP (CPAN) first");
	    return undef;
	}
	require LWP::UserAgent;

	my $ssl_socket;

	$ssl_socket = new IO::Socket::SSL(SSL_use_cert => 1,
					  SSL_verify_mode => 0x01,
					  SSL_cert_file => $client_cert,
					  SSL_key_file => $client_key,
					  SSL_passwd_cb => sub { return ($key_passwd)},
					  SSL_ca_file => $trusted_ca_file,
					  SSL_ca_path => $trusted_ca_path,
					  PeerAddr => $host,
					  PeerPort => $port,
					  Proto => 'tcp',
					  Timeout => '5'
					  );
	
	unless ($ssl_socket) {
	    do_log ('err','error %s unable to connect https://%s:%s/',&IO::Socket::SSL::errstr,$host,$port);
	    return undef;
	}
	do_log ('debug','connected to https://%s:%s/',&IO::Socket::SSL::errstr,$host,$port);

	if( ref($ssl_socket) eq "IO::Socket::SSL") {
	   my $subject_name = $ssl_socket->peer_certificate("subject");
	   my $issuer_name = $ssl_socket->peer_certificate("issuer");
	   my $cipher = $ssl_socket->get_cipher();
	   do_log ('debug','ssl peer certificat %s issued by %s. Cipher used %s',$subject_name,$issuer_name,$cipher);
	}

	print $ssl_socket "GET $path HTTP/1.0\nHost: $host\n\n";

	do_log ('debug',"requested GET $path HTTP/1.1");
	#my ($buffer) = $ssl_socket->getlines;
	# print STDERR $buffer;
	#do_log ('debug',"return");
	#return ;

	do_log ('debug',"get_https reading answer");
	my @result;
	while (my $line = $ssl_socket->getline) {
	    push  @result, $line;
	} 
	
	$ssl_socket->close(SSL_no_shutdown => 1);	
	do_log ('debug',"disconnected");

	return (@result);	
}


# request a document using https, return status and content
sub get_https2{
	my $host = shift;
	my $port = shift;
	my $path = shift;

	my $ssl_data= shift;

	my $trusted_ca_file = $ssl_data->{'cafile'};
	$trusted_ca_file ||= $Conf::Conf{'cafile'};
	my $trusted_ca_path = $ssl_data->{'capath'};
	$trusted_ca_path ||= $Conf::Conf{'capath'};

	do_log ('debug','Fetch::get_https2 (%s,%s,%s,%s,%s)',$host,$port,$path,$trusted_ca_file,$trusted_ca_path );

	unless ( -r ($trusted_ca_file) ||  (-d $trusted_ca_path )) {
	    do_log ('err',"error : incorrect access to cafile $trusted_ca_file bor capath $trusted_ca_path");
	    return undef;
	}

	unless (eval "require IO::Socket::SSL") {
	    do_log('err',"Unable to use SSL library, IO::Socket::SSL required, install IO-Socket-SSL (CPAN) first");
	    return undef;
	}
	require IO::Socket::SSL;
	
	unless (eval "require LWP::UserAgent") {
	    do_log('err',"Unable to use LWP library, LWP::UserAgent required, install LWP (CPAN) first");
	    return undef;
	}
	require LWP::UserAgent;

	my $ssl_socket;

	$ssl_socket = new IO::Socket::SSL(SSL_use_cert => 0,
					  SSL_verify_mode => 0x01,
					  SSL_ca_file => $trusted_ca_file,
					  SSL_ca_path => $trusted_ca_path,
					  PeerAddr => $host,
					  PeerPort => $port,
					  Proto => 'tcp',
					  Timeout => '5'
					  );
	
	unless ($ssl_socket) {
	    do_log ('err','error %s unable to connect https://%s:%s/',&IO::Socket::SSL::errstr,$host,$port);
	    return undef;
	}
	do_log ('debug',"connected to https://$host:$port/");

#	if( ref($ssl_socket) eq "IO::Socket::SSL") {
#	   my $subject_name = $ssl_socket->peer_certificate("subject");
#	   my $issuer_name = $ssl_socket->peer_certificate("issuer");
#	   my $cipher = $ssl_socket->get_cipher();
#	   do_log ('debug','ssl peer certificat %s issued by %s. Cipher used %s',$subject_name,$issuer_name,$cipher);
#	}

	my $request = "GET $path HTTP/1.0\nHost: $host\n\n";
	print $ssl_socket "$request\n\n";

	do_log ('debug',"requesting  $request");
	#my ($buffer) = $ssl_socket->getlines;
	# print STDERR $buffer;
	#do_log ('debug',"return");
	#return ;

	do_log ('debug',"get_https reading answer returns :");
	my @result;
	while (my $line = $ssl_socket->getline) {
	    do_log ('debug',"$line");
	    push  @result, $line;
	} 
	
	$ssl_socket->close(SSL_no_shutdown => 1);	
	do_log ('debug',"disconnected");

	return (@result);	
}



#################################################################

## Packages must return true.
1;
