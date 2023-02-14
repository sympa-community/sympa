# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
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

package Sympa::CLI::test::soap;

use strict;
use warnings;
use Encode qw();
use Getopt::Long;
use HTTP::Cookies;
use SOAP::Lite;

use Sympa::Tools::Data;

use parent qw(Sympa::CLI::test);

use constant _options =>
    qw(service=s trusted_application=s trusted_application_password=s
    user_email=s user_password=s cookie=s proxy_vars=s service_parameters=s
    session_id=s);
use constant _args      => qw(soap_url);
use constant _need_priv => 0;

sub _run {
    my $class    = shift;
    my $options  = shift;
    my $soap_url = shift;

    my ($reponse, @ret, $val, %fault);

    my $user_email          = $options->{user_email};
    my $user_password       = $options->{user_password};
    my $session_id          = $options->{session_id};
    my $trusted_application = $options->{trusted_application};
    my $trusted_application_password =
        $options->{trusted_application_password};
    my $proxy_vars         = $options->{proxy_vars};
    my $service            = $options->{service};
    my $service_parameters = $options->{service_parameters};
    my $cookie             = $options->{cookie};

    if (defined $trusted_application) {
        unless (defined $trusted_application_password) {
            printf "error : missing trusted_application_password parameter\n";
            exit 1;
        }
        unless (defined $service) {
            printf "error : missing service parameter\n";
            exit 1;
        }
        unless (defined $proxy_vars) {
            printf "error : missing proxy_vars parameter\n";
            exit 1;
        }

        play_soap_as_trusted($soap_url, $trusted_application,
            $trusted_application_password, $proxy_vars,
            $service, $service_parameters);
    } elsif ($service eq 'getUserEmailByCookie') {
        play_soap(
            $soap_url,
            session_id => $session_id,
            service    => $service
        );

    } elsif (defined $cookie) {
        printf "error : get_email_cookie\n";
        get_email($soap_url, $cookie);
        exit 1;
    } else {
        unless (defined $session_id
            || (defined $user_email && defined $user_password)) {
            printf
                "error : missing session_id OR user_email+user_passwors  parameters\n";
            exit 1;
        }

        play_soap(
            $soap_url,
            user_email         => $user_email,
            user_password      => $user_password,
            session_id         => $session_id,
            service            => $service,
            service_parameters => $service_parameters
        );
    }

    return 1;
}

sub play_soap_as_trusted {
    my $soap_url                     = shift;
    my $trusted_application          = shift;
    my $trusted_application_password = shift;
    my $proxy_vars                   = shift;
    my $service                      = shift;
    my $service_parameters           = shift;

    my $soap = SOAP::Lite->new();
    $soap->uri('urn:sympasoap');
    $soap->proxy($soap_url);

    my @parameters;
    if (defined $service_parameters) {
        @parameters = split /,/, $service_parameters;
    } else {
        @parameters = ();
    }
    printf "calling authenticateRemoteAppAndRun( %s, ?, %s, %s, %s )\n",
        $trusted_application, $proxy_vars, $service, join ',', @parameters;

    my $reponse =
        $soap->authenticateRemoteAppAndRun($trusted_application,
        $trusted_application_password, $proxy_vars, $service, \@parameters);
    print_result($reponse);
}

sub get_email {
    my $soap_url = shift;
    my $cookie   = shift;

    my ($service, $reponse, @ret, $val, %fault);

    ## Cookies management
    # my $uri = URI->new($soap_url);

    #    my $cookies = HTTP::Cookies->new(ignore_discard => 1,
    #				     file => '/tmp/my_cookies' );
    #    $cookies->load();
    printf "cookie : %s\n", $cookie;

    my $soap = SOAP::Lite->new();
    #$soap->on_debug(sub{print@_});
    $soap->uri('urn:sympasoap');
    $soap->proxy($soap_url);
    #,		 cookie_jar =>$cookies);

    print "\n\ngetEmailUserByCookie....\n";
    $reponse = $soap->getUserEmailByCookie($cookie);
    print_result($reponse);
    exit;

}

sub play_soap {
    my $soap_url = shift;
    my %param    = @_;

    my $user_email         = $param{'user_email'};
    my $user_password      = $param{'user_password'};
    my $session_id         = $param{'session_id'};
    my $service            = $param{'service'};
    my $service_parameters = $param{'service_parameters'};

    my ($reponse, @ret, $val, %fault);

    ## Cookies management
    # my $uri = URI->new($soap_url);

    my $cookies = HTTP::Cookies->new(
        ignore_discard => 1,
        file           => '/tmp/my_cookies'
    );
    $cookies->load();
    printf "cookie : %s\n", $cookies->as_string();

    my @parameters;
    @parameters = split(/,/, $service_parameters)
        if (defined $service_parameters);
    my $p = join(',', @parameters);
    foreach my $tmpParam (@parameters) {
        printf "param: %s\n", $tmpParam;
    }

    # Change to the path of Sympa.wsdl
    #$service = SOAP::Lite->service($soap_url);
    #$reponse = $service->login($user_email,$user_password);
    #my $soap = SOAP::Lite->service($soap_url);

    my $soap = SOAP::Lite->new() || die;
    #$soap->on_debug(sub{print@_});
    $soap->uri('urn:sympasoap');
    $soap->proxy($soap_url, cookie_jar => $cookies);

    ## Do the login unless a session_id is provided
    if ($session_id) {
        print "Using Session_id $session_id\n";

    } else {
        print "LOGIN....\n";

        #$reponse = $soap->casLogin($soap_url);
        $reponse = $soap->login($user_email, $user_password);
        $cookies->save;
        print_result($reponse);
        $session_id = $reponse->result;
    }

    ## Don't use authenticateAndRun for lists command

    ## Split parameters
    if ($service_parameters && $service_parameters ne '') {
        @parameters = split /,/, $service_parameters;
    }

    if ($service eq 'lists') {
        printf "\n\nlists....\n";
        $reponse = $soap->lists();

    } elsif ($service eq 'subscribe') {
        printf "\n\n$service....\n";
        $reponse = $soap->subscribe(@parameters);

    } elsif ($service eq 'signoff') {
        printf "\n\n$service....\n";
        $reponse = $soap->signoff(@parameters);

    } elsif ($service eq 'add') {
        printf "\n\n$service....\n";
        $reponse = $soap->add(@parameters);

    } elsif ($service eq 'del') {
        printf "\n\n$service....\n";
        $reponse = $soap->del(@parameters);

    } elsif ($service eq 'getUserEmailByCookie') {
        printf "\n\n$service....\n";
        $reponse = $soap->getUserEmailByCookie($session_id);

    } else {
        printf "\n\nAuthenticateAndRun service=%s;(session_id=%s)....\n",
            $service, $session_id;
        $reponse =
            $soap->authenticateAndRun($user_email, $session_id, $service,
            \@parameters);
    }

    print_result($reponse);

}

sub print_result {
    my $r = shift;

    if ($r->fault) {
        print "SOAP error :\n";
        _dump_var($r->fault);
    } else {
        _dump_var($r->result);
    }

    return 1;
}

# Dump a variable's content
# Old name: Sympa::Tools::Data::dump_var().
sub _dump_var {
    my $var = shift;
    my $level = shift || 0;

    if (ref $var eq 'ARRAY') {
        foreach my $index (0 .. $#{$var}) {
            printf "%s%d\n", "\t" x $level, $index;
            _dump_var($var->[$index], $level + 1);
        }
    } elsif (ref $var eq 'HASH') {
        foreach my $key (sort keys %{$var}) {
            printf "%s_%s_\n", "\t" x $level, $key;
            _dump_var($var->{$key}, $level + 1);
        }
    } elsif (ref $var) {
        printf "%s'%s'\n", "\t" x $level, ref $var;
    } elsif (defined $var) {
        printf "%s'%s'\n", "\t" x $level,
            Encode::is_utf8($var) ? Encode::encode_utf8($var) : $var;
    } else {
        printf "%sUNDEF\n", "\t" x $level;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-test-soap - Demo client for Sympa SOAP/HTTP API

=head1 DESCRIPTION

C<sympa test soap>
is a perl soap client for Sympa for TEST ONLY. Use it to illustrate how to
code access to features of Sympa soap server. Authentication can be done via
user/password or user cookie or as a trusted remote application

Usage: sympa test soap
--service=<a sympa service>
--trusted_application=<app name>
--trusted_application_password=<password>
--proxy_vars=<id=value,id2=value2>
--service_parameters=<value1,value2,value3>
<soap sympa server url>


OR usage: sympa test soap
--user_email=<email>
--user_password=<password>
--session_id=<sessionid>
--service=<a sympa service>
--service_parameters=<value1,value2,value3>
<soap sympa server url>


OR usage: sympa test soap
--cookie=<sympauser cookie string>
<soap sympa server url>

Example:
sympa test soap --cookie=sympauser=someone@cru.fr <soap sympa server url> 

=head1 HISTORY

F<sympa_soap_client.pl> appeared on Sympa 4.0a.8.

Its function was moved to C<sympa test soap> command line on Sympa 6.2.71b.

=cut
