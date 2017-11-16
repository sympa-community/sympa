# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Fetch;

use strict;
use warnings;

use Sympa::Log;

my $log = Sympa::Log->instance;

# request a document using https, return status and content
sub get_https {
    $log->syslog('debug2', '(%s, %s, %s, %s, %s, %s)', @_);
    my $host        = shift;
    my $port        = shift;
    my $path        = shift;
    my $client_cert = shift;
    my $client_key  = shift;
    my $ssl_data    = shift;

    my $key_passwd      = $ssl_data->{'key_passwd'};
    my $trusted_ca_file = $ssl_data->{'cafile'};
    my $trusted_ca_path = $ssl_data->{'capath'};

    unless (-r ($trusted_ca_file) || (-d $trusted_ca_path)) {
        $log->syslog('err',
            "error : incorrect access to cafile $trusted_ca_file bor capath $trusted_ca_path"
        );
        return undef;
    }

    unless (eval "require IO::Socket::SSL") {
        $log->syslog('err',
            "Unable to use SSL library, IO::Socket::SSL required, install IO-Socket-SSL (CPAN) first"
        );
        return undef;
    }
    require IO::Socket::SSL;

    unless (eval "require LWP::UserAgent") {
        $log->syslog('err',
            "Unable to use LWP library, LWP::UserAgent required, install LWP (CPAN) first"
        );
        return undef;
    }
    require LWP::UserAgent;

    my $ssl_socket;

    $ssl_socket = IO::Socket::SSL->new(
        SSL_use_cert    => 1,
        SSL_verify_mode => 0x01,
        SSL_cert_file   => $client_cert,
        SSL_key_file    => $client_key,
        SSL_passwd_cb   => sub { return ($key_passwd) },
        SSL_ca_file     => $trusted_ca_file,
        SSL_ca_path     => $trusted_ca_path,
        PeerAddr        => $host,
        PeerPort        => $port,
        Proto           => 'tcp',
        Timeout         => '5'
    );

    unless ($ssl_socket) {
        $log->syslog('err', 'Error %s unable to connect https://%s:%s/',
            IO::Socket::SSL::errstr(), $host, $port);
        return undef;
    }
    $log->syslog('debug', 'Connected to https://%s:%s/',
        IO::Socket::SSL::errstr(), $host, $port);

    if (ref($ssl_socket) eq "IO::Socket::SSL") {
        my $subject_name = $ssl_socket->peer_certificate("subject");
        my $issuer_name  = $ssl_socket->peer_certificate("issuer");
        my $cipher       = $ssl_socket->get_cipher();
        $log->syslog('debug',
            'SSL peer certificate %s issued by %s. Cipher used %s',
            $subject_name, $issuer_name, $cipher);
    }

    print $ssl_socket "GET $path HTTP/1.0\nHost: $host\n\n";

    $log->syslog('debug', 'Requested GET %s HTTP/1.1', $path);
    #my ($buffer) = $ssl_socket->getlines;
    # print STDERR $buffer;
    #$log->syslog ('debug',"return");
    #return ;

    $log->syslog('debug', 'Get_https reading answer');
    my @result;
    while (my $line = $ssl_socket->getline) {
        push @result, $line;
    }

    $ssl_socket->close(SSL_no_shutdown => 1);
    $log->syslog('debug', 'Disconnected');

    return (@result);
}

# request a document using https, return status and content
sub get_https2 {
    my $host = shift;
    my $port = shift;
    my $path = shift;

    my $ssl_data = shift;

    my $trusted_ca_file = $ssl_data->{'cafile'};
    $trusted_ca_file ||= $Conf::Conf{'cafile'};
    my $trusted_ca_path = $ssl_data->{'capath'};
    $trusted_ca_path ||= $Conf::Conf{'capath'};

    $log->syslog('debug', '(%s, %s, %s, %s, %s)',
        $host, $port, $path, $trusted_ca_file, $trusted_ca_path);

    unless (-r ($trusted_ca_file) || (-d $trusted_ca_path)) {
        $log->syslog('err',
            "error : incorrect access to cafile $trusted_ca_file bor capath $trusted_ca_path"
        );
        return undef;
    }

    unless (eval "require IO::Socket::SSL") {
        $log->syslog('err',
            "Unable to use SSL library, IO::Socket::SSL required, install IO-Socket-SSL (CPAN) first"
        );
        return undef;
    }
    require IO::Socket::SSL;

    unless (eval "require LWP::UserAgent") {
        $log->syslog('err',
            "Unable to use LWP library, LWP::UserAgent required, install LWP (CPAN) first"
        );
        return undef;
    }
    require LWP::UserAgent;

    my $ssl_socket;

    $ssl_socket = IO::Socket::SSL->new(
        SSL_use_cert    => 0,
        SSL_verify_mode => 0x01,
        SSL_ca_file     => $trusted_ca_file,
        SSL_ca_path     => $trusted_ca_path,
        PeerAddr        => $host,
        PeerPort        => $port,
        Proto           => 'tcp',
        Timeout         => '5'
    );

    unless ($ssl_socket) {
        $log->syslog('err', 'Error %s unable to connect https://%s:%s/',
            IO::Socket::SSL::errstr(), $host, $port);
        return undef;
    }
    $log->syslog('debug', 'Connected to https://%s:%s/', $host, $port);

    #if( ref($ssl_socket) eq "IO::Socket::SSL") {
    #    my $subject_name = $ssl_socket->peer_certificate("subject");
    #    my $issuer_name = $ssl_socket->peer_certificate("issuer");
    #    my $cipher = $ssl_socket->get_cipher();
    #    $log->syslog('debug',
    #        'SSL peer certificate %s issued by %s. Cipher used %s',
    #        $subject_name,$issuer_name,$cipher);
    #}

    my $request = "GET $path HTTP/1.0\nHost: $host\n\n";
    print $ssl_socket "$request\n\n";

    $log->syslog('debug', 'Requesting %s', $request);
    #my ($buffer) = $ssl_socket->getlines;
    #print STDERR $buffer;
    #$log->syslog ('debug',"return");
    #return ;

    $log->syslog('debug', 'Get_https reading answer returns:');
    my @result;
    while (my $line = $ssl_socket->getline) {
        $log->syslog('debug', '%s', $line);
        push @result, $line;
    }

    $ssl_socket->close(SSL_no_shutdown => 1);
    $log->syslog('debug', 'Disconnected');

    return (@result);
}

1;
