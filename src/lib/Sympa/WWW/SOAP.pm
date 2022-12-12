# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020, 2021 The Sympa Community. See the
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

package Sympa::WWW::SOAP;

use strict;
use warnings;
use Encode qw();

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Spindle::ProcessRequest;
use Sympa::Template;
use Sympa::Tools::Text;
use Sympa::User;
use Sympa::WWW::Auth;
use Sympa::WWW::Session;

## Define types of SOAP type listType
my %types = (
    'listType' => {
        'listAddress'  => 'string',
        'homepage'     => 'string',
        'isSubscriber' => 'boolean',
        'isOwner'      => 'boolean',
        'isEditor'     => 'boolean',
        'subject'      => 'string',
        'info'         => 'string',
        'email'        => 'string',
        'gecos'        => 'string'
    }
);

my $log = Sympa::Log->instance;

sub checkCookie {
    my $class = shift;

    my $sender = $ENV{'USER_EMAIL'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    $log->syslog('debug', 'SOAP checkCookie');

    return SOAP::Data->name('result')->type('string')->value($sender);
}

sub lists {
    my $self     = shift;         #$self is a service object
    my $topic    = shift;
    my $subtopic = shift;
    my $mode     = shift // '';

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    $log->syslog('notice', '(%s, %s, %s)', $topic, $subtopic, $sender);

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    my @result;

    $log->syslog('info', '(%s, %s)', $topic, $subtopic);

    my $all_lists = Sympa::List::get_lists($robot);
    foreach my $list (@$all_lists) {

        my $listname = $list->{'name'};

        my $result_item = {};
        my $result = Sympa::Scenario->new($list, 'visibility')->authz(
            'md5',
            {   'sender'                  => $sender,
                'remote_application_name' => $ENV{'remote_application_name'}
            }
        );
        my $action;
        $action = $result->{'action'} if (ref($result) eq 'HASH');
        next unless ($action eq 'do_it');

        ##building result packet
        $result_item->{'listAddress'} = Sympa::get_address($list);
        $result_item->{'subject'}     = $list->{'admin'}{'subject'};
        $result_item->{'subject'} =~ s/;/,/g;
        $result_item->{'homepage'} = Sympa::get_url($list, 'info');

        my $listInfo;
        if ($mode eq 'complex') {
            $listInfo = struct_to_soap($result_item);
        } else {
            $listInfo = struct_to_soap($result_item, 'as_string');
        }

        ## no topic ; List all lists
        if (!$topic) {
            push @result, $listInfo;

        } elsif ($list->{'admin'}{'topics'}) {
            foreach my $list_topic (@{$list->{'admin'}{'topics'}}) {
                my @tree = split '/', $list_topic;

                next if (($topic)    && ($tree[0] ne $topic));
                next if (($subtopic) && ($tree[1] ne $subtopic));

                push @result, $listInfo;
            }
        } elsif ($topic eq 'topicsless') {
            push @result, $listInfo;
        }
    }

    return SOAP::Data->name('listInfo')->value(\@result);
}

sub login {
    my $class  = shift;
    my $email  = shift;
    my $passwd = shift;

    my $http_host = $ENV{'SERVER_NAME'};
    my $robot     = $ENV{'SYMPA_ROBOT'};
    $log->syslog('notice', '(%s)', $email);

    #foreach my  $k (keys %ENV) {
    #$log->syslog('notice', 'ENV %s = %s', $k, $ENV{$k});
    #}
    unless (defined $http_host) {
        $log->syslog('err', 'SERVER_NAME not defined');
    }
    unless (defined $email) {
        $log->syslog('err', 'Email not defined');
    }
    unless (defined $passwd) {
        $log->syslog('err', 'Passwd not defined');
    }

    unless ($http_host and $email and $passwd) {
        $log->syslog('err', 'Incorrect number of parameters');
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <HTTP host> <email> <password>');
    }

    ## Authentication of the sender
    ## Set an env var to find out if in a SOAP context
    $ENV{'SYMPA_SOAP'} = 1;

    my $user = Sympa::WWW::Auth::check_auth($robot, $email, $passwd);

    unless ($user) {
        $log->syslog('notice', 'Login authentication failed');
        die SOAP::Fault->faultcode('Server')
            ->faultstring('Authentication failed')
            ->faultdetail("Incorrect password for user $email or bad login");
    }

    ## Create Sympa::WWW::Session object
    my $session =
        Sympa::WWW::Session->new($robot, {cookie => $ENV{SESSION_ID}});
    $ENV{'USER_EMAIL'} = $email;
    $session->{'email'} = $email;
    $session->store();

    ## Note that id_session changes each time it is saved in the DB
    $ENV{'SESSION_ID'} = $session->{'id_session'};

    ## Also return the cookie value
    return SOAP::Data->name('result')->type('string')
        ->value($ENV{SESSION_ID});
}

sub casLogin {
    my $class       = shift;
    my $proxyTicket = shift;

    my $http_host = $ENV{'SERVER_NAME'};
    my $sender    = $ENV{'USER_EMAIL'};
    my $robot     = $ENV{'SYMPA_ROBOT'};
    $log->syslog('notice', '(%s)', $proxyTicket);

    unless ($http_host and $proxyTicket) {
        $log->syslog('err', 'Incorrect number of parameters');
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <HTTP host> <proxyTicket>');
    }

    unless (eval "require AuthCAS") {
        $log->syslog('err',
            "Unable to use AuthCAS library, install AuthCAS (CPAN) first");
        return undef;
    }
    require AuthCAS;

    ## Validate the CAS ST against all known CAS servers defined in auth.conf
    ## CAS server response will include the user's NetID
    my ($user, @proxies, $email, $auth);
    foreach my $auth_service (grep { $_->{auth_type} eq 'cas' }
        @{$Conf::Conf{'auth_services'}{$robot}}) {
        my $cas = AuthCAS->new(
            casUrl => $auth_service->{'base_url'},
            #CAFile => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
        );

        ($user, @proxies) =
            $cas->validatePT(Conf::get_robot_conf($robot, 'soap_url'),
            $proxyTicket);
        unless (defined $user) {
            $log->syslog(
                'err', 'CAS ticket %s not validated by server %s: %s',
                $proxyTicket, $auth_service->{'base_url'},
                AuthCAS::get_errors()
            );
            next;
        }

        $log->syslog('notice', 'User %s authenticated against server %s',
            $user, $auth_service->{'base_url'});

        ## User was authenticated
        $auth = $auth_service;
        last;
    }

    unless ($user) {
        $log->syslog('notice', 'Login authentication failed');
        die SOAP::Fault->faultcode('Server')
            ->faultstring('Authentication failed')
            ->faultdetail("Proxy ticket could not be validated");
    }

    ## Now fetch email attribute from LDAP
    unless ($email =
        Sympa::WWW::Auth::get_email_by_net_id($robot, $auth, {uid => $user}))
    {
        $log->syslog('err',
            'Could not get email address from LDAP for user %s', $user);
        die SOAP::Fault->faultcode('Server')
            ->faultstring('Authentication failed')
            ->faultdetail("Could not get email address from LDAP directory");
    }

    ## Create Sympa::WWW::Session object
    my $session =
        Sympa::WWW::Session->new($robot, {cookie => $ENV{SESSION_ID}});
    $ENV{'USER_EMAIL'} = $email;
    $session->{'email'} = $email;
    $session->store();

    ## Note that id_session changes each time it is saved in the DB
    $ENV{'SESSION_ID'} = $session->{'id_session'};

    ## Also return the cookie value
    return SOAP::Data->name('result')->type('string')
        ->value($ENV{SESSION_ID});
}

## Used to call a service as an authenticated user without using HTTP cookies
## First parameter is the secret contained in the cookie
sub authenticateAndRun {
    my ($self, $email, $cookie, $service, $parameters) = @_;
    my $session_id;

    if ($parameters) {
        $log->syslog('notice', '(%s, %s, %s, %s)',
            $email, $cookie, $service, join(',', @$parameters));
    } else {
        $log->syslog('notice', '(%s, %s, %s)', $email, $cookie, $service);
    }

    unless ($cookie and $service) {
        $log->syslog('err', "Missing parameter");
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <email> <cookie> <service>');
    }

    ## Provided email is not trusted, we fetch the user email from the
    ## session_table instead
    my $session =
        Sympa::WWW::Session->new($ENV{'SYMPA_ROBOT'}, {cookie => $cookie});

    unless (defined $session
        && !$session->{'new_session'}
        && $session->{'email'} eq $email) {
        $log->syslog('err',
            'Failed to authenticate user %s with session ID %s',
            $email, $cookie);
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Could not get email from cookie')->faultdetail('');
    }

    $ENV{'USER_EMAIL'} = $email;
    $ENV{'SESSION_ID'} = $session->{'id_session'};

    no strict 'refs';
    $service->($self, @$parameters);
}
## request user email from http cookie
##
sub getUserEmailByCookie {
    my ($self, $cookie) = @_;

    $log->syslog('debug3', '(%s)', $cookie);

    unless ($cookie) {
        $log->syslog('err', "Missing parameter cookie");
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Missing parameter')->faultdetail('Use : <cookie>');
    }

    my $session =
        Sympa::WWW::Session->new($ENV{'SYMPA_ROBOT'}, {'cookie' => $cookie});

    unless (defined $session && ($session->{'email'} ne 'unkown')) {
        $log->syslog('err', 'Failed to load session for %s', $cookie);
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Could not get email from cookie')->faultdetail('');
    }

    return SOAP::Data->name('result')->type('string')
        ->value($session->{'email'});

}
## Used to call a service from a remote proxy application
## First parameter is the application name as defined in the
## trusted_applications.conf file
##   2nd parameter is remote application password
##   3nd a string with multiple cars definition comma separated
##   (var=value,var=value,...)
##   4nd is service name requested
##   5nd service parameters
sub authenticateRemoteAppAndRun {
    my ($self, $appname, $apppassword, $vars, $service, $parameters) = @_;
    my $robot = $ENV{'SYMPA_ROBOT'};

    if ($parameters) {
        $log->syslog('notice', '(%s, %s, %s, %s)',
            $appname, $vars, $service, join(',', @$parameters));
    } else {
        $log->syslog('notice', '(%s, %s, %s)', $appname, $vars, $service);
    }

    unless ($appname and $apppassword and $service) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <appname> <apppassword> <vars> <service>');
    }
    my ($proxy_vars, $set_vars) =
        Sympa::WWW::Auth::remote_app_check_password($appname, $apppassword,
        $robot, $service);

    unless (defined $proxy_vars) {
        $log->syslog('notice', 'Authentication failed');
        die SOAP::Fault->faultcode('Server')
            ->faultstring('Authentication failed')
            ->faultdetail("Authentication failed for application $appname");
    }
    $ENV{'remote_application_name'} = $appname;

    foreach my $var (split(/,/, $vars)) {
        # check if the remote application is trusted proxy for this variable
        # $log->syslog('notice',
        #     'Remote application is trusted proxy for %s', $var);

        my ($id, $value) = split(/=/, $var);
        if (!defined $id) {
            $log->syslog('notice', 'Incorrect syntaxe ID');
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Incorrect syntaxe id')
                ->faultdetail("Unrecognized syntaxe  $var");
        }
        if (!defined $value) {
            $log->syslog('notice', 'Incorrect syntaxe value');
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Incorrect syntaxe value')
                ->faultdetail("Unrecognized syntaxe  $var");
        }
        $ENV{$id} = $value if ($proxy_vars->{$id});
    }
    # Set fixed variables.
    foreach my $var (keys %$set_vars) {
        $ENV{$var} = $set_vars->{$var};
    }

    no strict 'refs';
    $service->($self, @$parameters);
}

sub amI {
    my ($class, $listname, $function, $user) = @_;

    my $robot = $ENV{'SYMPA_ROBOT'};

    $log->syslog('notice', '(%s, %s, %s)', $listname, $function, $user);

    unless ($listname and $user and $function) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list> <function> <user email>');
    }

    $listname = lc($listname);
    my $list = Sympa::List->new($listname, $robot);

    $log->syslog('debug', '(%s)', $listname);

    if ($list) {
        if ($function eq 'subscriber') {
            return SOAP::Data->name('result')->type('boolean')
                ->value($list->is_list_member($user));
        } elsif ($function eq 'editor') {
            return SOAP::Data->name('result')->type('boolean')
                ->value($list->is_admin('actual_editor', $user));
        } elsif ($function eq 'owner') {
            return SOAP::Data->name('result')->type('boolean')
                ->value($list->is_admin('owner', $user)
                    || Sympa::is_listmaster($list, $user));
        } else {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Unknown function.')
                ->faultdetail("Function $function unknown");
        }
    } else {
        die SOAP::Fault->faultcode('Server')->faultstring('Unknown list.')
            ->faultdetail("List $listname unknown");
    }

}

sub info {
    my $class    = shift;
    my $listname = shift;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }

    $log->syslog('notice', '(%s)', $listname);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info', 'Info %s from %s refused, list unknown',
            $listname, $sender);
        die SOAP::Fault->faultcode('Server')->faultstring('Unknown list')
            ->faultdetail("List $listname unknown");
    }

    my $result = Sympa::Scenario->new($list, 'info')->authz(
        'md5',
        {   'sender'                  => $sender,
            'remote_application_name' => $ENV{'remote_application_name'}
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    die SOAP::Fault->faultcode('Server')->faultstring('No action available')
        unless (defined $action);

    if ($action =~ /reject/i) {
        my $reason_string = get_reason_string(
            [{action => 'info'}, 'auth', $result->{'reason'}], $robot);
        $log->syslog('info', 'Info %s from %s refused (not allowed)',
            $listname, $sender);
        die SOAP::Fault->faultcode('Server')->faultstring('Not allowed')
            ->faultdetail($reason_string);
    }
    if ($action =~ /do_it/i) {
        my $result_item;

        $result_item->{'listAddress'} =
            SOAP::Data->name('listAddress')->type('string')
            ->value(Sympa::get_address($list));
        $result_item->{'subject'} =
            SOAP::Data->name('subject')->type('string')
            ->value($list->{'admin'}{'subject'});
        $result_item->{'info'} =
            SOAP::Data->name('info')->type('string')->value($list->get_info);
        $result_item->{'homepage'} =
            SOAP::Data->name('homepage')->type('string')
            ->value(Sympa::get_url($list, 'info'));

        ## determine status of user
        if ($list->is_admin('owner', $sender)
            or Sympa::is_listmaster($list, $sender)) {
            $result_item->{'isOwner'} =
                SOAP::Data->name('isOwner')->type('boolean')->value(1);
        }
        if ($list->is_admin('actual_editor', $sender)) {
            $result_item->{'isEditor'} =
                SOAP::Data->name('isEditor')->type('boolean')->value(1);
        }
        if ($list->is_list_member($sender)) {
            $result_item->{'isSubscriber'} =
                SOAP::Data->name('isSubscriber')->type('boolean')->value(1);
        }

        #push @result, SOAP::Data->type('listType')->value($result_item);
        return SOAP::Data->value([$result_item]);
    }
    $log->syslog('info',
        'Info %s from %s aborted, unknown requested action in scenario',
        $listname, $sender);
    die SOAP::Fault->faultcode('Server')
        ->faultstring('Unknown requested action')->faultdetail(
        "SOAP info : %s from %s aborted because unknown requested action in scenario",
        $listname, $sender
        );
}

sub createList {
    $log->syslog(
        'info',
        '(%s, listname=%s, subject=%s, template=%s, description=%s, topics=%s)',
        @_
    );
    my $class       = shift;
    my $listname    = shift;
    my $subject     = shift;
    my $list_tpl    = shift;
    my $description = shift;
    my $topics      = shift;

    my $sender                  = $ENV{'USER_EMAIL'};
    my $robot                   = $ENV{'SYMPA_ROBOT'};
    my $remote_application_name = $ENV{'remote_application_name'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not specified')
            ->faultdetail('Use a trusted proxy or login first ');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }

    my $reject;
    unless ($subject) {
        $reject .= 'subject';
    }
    unless ($list_tpl) {
        $reject .= ', template';
    }
    unless ($description) {
        $reject .= ', description';
    }
    unless ($topics) {
        $reject .= 'topics';
    }
    if ($reject) {
        $log->syslog('info',
            'Create_list %s@%s from %s refused, missing parameter(s) %s',
            $listname, $robot, $sender, $reject);
        die SOAP::Fault->faultcode('Server')
            ->faultstring('Missing parameter')
            ->faultdetail("Missing required parameter(s) : $reject");
    }

    my $user = Sympa::User::get_global_user($sender)
        if Sympa::User::is_global_user($sender);

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context    => $robot,
        action     => 'create_list',
        parameters => {
            listname => $listname,
            owner    => [
                {   email => $sender,
                    gecos => ($user ? $user->{gecos} : undef),
                }
            ],
            subject        => $subject,
            creation_email => $sender,
            type           => $list_tpl,
            topics         => $topics,
            description    => $description,
        },
        sender    => $sender,
        md5_check => 1,

        scenario_context => {
            'sender'                  => $sender,
            'candidate_listname'      => $listname,
            'candidate_subject'       => $subject,
            'candidate_template'      => $list_tpl,
            'candidate_info'          => $description,
            'candidate_topics'        => $topics,
            'remote_host'             => $ENV{'REMOTE_HOST'},
            'remote_addr'             => $ENV{'REMOTE_ADDR'},
            'remote_application_name' => $ENV{'remote_application_name'}
        }
    );
    unless ($spindle and $spindle->spin) {
        die SOAP::Fault->faultcode('Server')->faultstring('Internal error');
    }

    foreach my $report (@{$spindle->{stash} || []}) {
        my $reason_string = get_reason_string($report, $robot);
        if ($report->[1] eq 'auth') {
            die SOAP::Fault->faultcode('Server')->faultstring('Not allowed.')
                ->faultdetail($reason_string);
        } elsif ($report->[1] eq 'intern') {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Internal error');
        } elsif ($report->[1] eq 'notice') {
            return SOAP::Data->name('result')->type('boolean')->value(1);
        } elsif ($report->[1] eq 'user') {
            die SOAP::Fault->faultcode('Server')->faultstring('Undef')
                ->faultdetail($reason_string);
        }
    }
    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub closeList {
    my $class    = shift;
    my $listname = shift;

    my $sender                  = $ENV{'USER_EMAIL'};
    my $robot                   = $ENV{'SYMPA_ROBOT'};
    my $remote_application_name = $ENV{'remote_application_name'};

    $log->syslog('info', '(list = %s\@%s) From %s via proxy application %s',
        $listname, $robot, $sender, $remote_application_name);

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not specified')
            ->faultdetail('Use a trusted proxy or login first ');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }

    $log->syslog('debug', '(%s, %s)', $listname, $robot);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info', 'CloseList %s@%s from %s refused, unknown list',
            $listname, $robot, $sender);
        die SOAP::Fault->faultcode('Client')->faultstring('unknown list')
            ->faultdetail("inknown list $listname");
    }

    # check authorization
    unless ($list->is_admin('owner', $sender)
        or Sympa::is_listmaster($list, $sender)) {
        $log->syslog('info', 'CloseList %s from %s not allowed',
            $listname, $sender);
        die SOAP::Fault->faultcode('Client')->faultstring('Not allowed')
            ->faultdetail("Not allowed");
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context      => $list->{'domain'},
        action       => 'close_list',
        current_list => $list,
        mode =>
            (($list->{'admin'}{'status'} eq 'pending') ? 'purge' : 'close'),
        sender           => $sender,
        md5_check        => 1,
        scenario_context => {
            sender                  => $sender,
            remote_host             => $ENV{'REMOTE_HOST'},
            remote_addr             => $ENV{'REMOTE_ADDR'},
            remote_application_name => $ENV{'remote_application_name'}
        }
    );
    unless ($spindle and $spindle->spin) {
        die SOAP::Fault->faultcode('Server')->faultstring('Internal error');
    }

    foreach my $report (@{$spindle->{stash} || []}) {
        my $reason_string = get_reason_string($report, $robot);
        if ($report->[1] eq 'auth') {
            die SOAP::Fault->faultcode('Server')->faultstring('Not allowed.')
                ->faultdetail($reason_string);
        } elsif ($report->[1] eq 'intern') {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Internal error');
        } elsif ($report->[1] eq 'notice') {
            return SOAP::Data->name('result')->type('boolean')->value(1);
        } elsif ($report->[1] eq 'user') {
            die SOAP::Fault->faultcode('Server')->faultstring('Undef')
                ->faultdetail($reason_string);
        }
    }
    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub add {
    my $class    = shift;
    my $listname = shift;
    my $email    = shift;
    my $gecos    = shift;
    my $quiet    = shift;

    my $sender                  = $ENV{'USER_EMAIL'};
    my $robot                   = $ENV{'SYMPA_ROBOT'};
    my $remote_application_name = $ENV{'remote_application_name'};

    $log->syslog(
        'info',
        '(list = %s@%s, email = %s, quiet = %s) From %s via proxy application %s',
        $listname,
        $robot,
        $email,
        $quiet,
        $sender,
        $remote_application_name
    );

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not specified')
            ->faultdetail('Use a trusted proxy or login first ');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }
    unless ($email) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <email>');
    }
    unless (Sympa::Tools::Text::valid_email($email)) {
        my $error = "Invalid email address provided: '$email'";
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Unable to add user')->faultdetail($error);
    }
    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info', 'Add %s@%s %s from %s refused, no such list',
            $listname, $robot, $email, $sender);
        die SOAP::Fault->faultcode('Server')->faultstring('Undefined list')
            ->faultdetail("Undefined list");
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'add',
        sender           => $sender,
        email            => $email,
        gecos            => $gecos,
        quiet            => $quiet,
        md5_check        => 1,
        scenario_context => {
            sender                  => $sender,
            email                   => $email,
            remote_host             => $ENV{'REMOTE_HOST'},
            remote_addr             => $ENV{'REMOTE_ADDR'},
            remote_application_name => $ENV{'remote_application_name'}
        }
    );
    unless ($spindle and $spindle->spin) {
        die SOAP::Fault->faultcode('Server')->faultstring('Internal error');
    }

    foreach my $report (@{$spindle->{stash} || []}) {
        my $reason_string = get_reason_string($report, $robot);
        if ($report->[1] eq 'auth') {
            die SOAP::Fault->faultcode('Server')->faultstring('Not allowed.')
                ->faultdetail($reason_string);
        } elsif ($report->[1] eq 'intern') {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Internal error');
        } elsif ($report->[1] eq 'notice') {
            return SOAP::Data->name('result')->type('boolean')->value(1);
        } elsif ($report->[1] eq 'user') {
            die SOAP::Fault->faultcode('Server')->faultstring('Undef')
                ->faultdetail($reason_string);
        }
    }
    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub del {
    my $class    = shift;
    my $listname = shift;
    my $email    = shift;
    my $quiet    = shift;

    my $sender                  = $ENV{'USER_EMAIL'};
    my $robot                   = $ENV{'SYMPA_ROBOT'};
    my $remote_application_name = $ENV{'remote_application_name'};

    $log->syslog(
        'info',
        '(list = %s@%s, email = %s, quiet = %s) From %s via proxy application %s',
        $listname,
        $robot,
        $email,
        $quiet,
        $sender,
        $remote_application_name
    );

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not specified')
            ->faultdetail('Use a trusted proxy or login first ');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }
    unless ($email) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <email>');
    }
    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info', 'Del %s@%s %s from %s refused, no such list',
            $listname, $robot, $email, $sender);
        die SOAP::Fault->faultcode('Server')->faultstring('Undefined list')
            ->faultdetail("Undefined list");
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'del',
        sender           => $sender,
        email            => $email,
        quiet            => $quiet,
        md5_check        => 1,
        scenario_context => {
            sender                  => $sender,
            email                   => $email,
            remote_host             => $ENV{'REMOTE_HOST'},
            remote_addr             => $ENV{'REMOTE_ADDR'},
            remote_application_name => $ENV{'remote_application_name'}
        }
    );
    unless ($spindle and $spindle->spin) {
        die SOAP::Fault->faultcode('Server')->faultstring('Internal error');
    }

    foreach my $report (@{$spindle->{stash} || []}) {
        my $reason_string = get_reason_string($report, $robot);
        if ($report->[1] eq 'auth') {
            die SOAP::Fault->faultcode('Server')->faultstring('Not allowed.')
                ->faultdetail($reason_string);
        } elsif ($report->[1] eq 'intern') {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Internal error');
        } elsif ($report->[1] eq 'notice') {
            return SOAP::Data->name('result')->type('boolean')->value(1);
        } elsif ($report->[1] eq 'user') {
            die SOAP::Fault->faultcode('Server')->faultstring('Undef')
                ->faultdetail($reason_string);
        }
    }
    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub review {
    my $class    = shift;
    my $listname = shift;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    my @resultSoap;

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }

    $log->syslog('debug', '(%s, %s)', $listname, $robot);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info',
            'Review %s from %s refused, list unknown to robot %s',
            $listname, $sender, $robot);
        die SOAP::Fault->faultcode('Server')->faultstring('Unknown list')
            ->faultdetail("List $listname unknown");
    }

    my $user;

    # Part of the authorization code
    $user = Sympa::User::get_global_user($sender);

    my $result = Sympa::Scenario->new($list, 'review')->authz(
        'md5',
        {   'sender'                  => $sender,
            'remote_application_name' => $ENV{'remote_application_name'}
        }
    );
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    die SOAP::Fault->faultcode('Server')->faultstring('No action available')
        unless (defined $action);

    if ($action =~ /reject/i) {
        my $reason_string = get_reason_string(
            [{action => 'review'}, 'auth', $result->{'reason'}], $robot);
        $log->syslog('info', 'Review %s from %s refused (not allowed)',
            $listname, $sender);
        die SOAP::Fault->faultcode('Server')->faultstring('Not allowed')
            ->faultdetail($reason_string);
    }
    if ($action =~ /do_it/i) {
        my $is_owner = $list->is_admin('owner', $sender)
            || Sympa::is_listmaster($list, $sender);

        unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
            $log->syslog('err', 'No subscribers in list "%s"',
                $list->{'name'});
            push @resultSoap,
                SOAP::Data->name('result')->type('string')
                ->value('no_subscribers');
            return SOAP::Data->name('return')->value(\@resultSoap);
        }
        do {
            ## Owners bypass the visibility option
            unless (($user->{'visibility'} eq 'conceal')
                and (!$is_owner)) {

                ## Lower case email address
                $user->{'email'} =~ y/A-Z/a-z/;
                push @resultSoap,
                    SOAP::Data->name('item')->type('string')
                    ->value($user->{'email'});
            }
        } while ($user = $list->get_next_list_member());
        $log->syslog('info', 'Review %s from %s accepted', $listname,
            $sender);
        return SOAP::Data->name('return')->value(\@resultSoap);
    }
    $log->syslog('info',
        'Review %s from %s aborted, unknown requested action in scenario',
        $listname, $sender);
    die SOAP::Fault->faultcode('Server')
        ->faultstring('Unknown requested action')->faultdetail(
        "SOAP review : %s from %s aborted because unknown requested action in scenario",
        $listname, $sender
        );
}

sub fullReview {
    my $class    = shift;
    my $listname = shift;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }

    $log->syslog('debug', '(%s, %s)', $listname, $robot);

    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info',
            'Review %s from %s refused, list unknown to robot %s',
            $listname, $sender, $robot);
        die SOAP::Fault->faultcode('Server')->faultstring('Unknown list')
            ->faultdetail("List $listname unknown");
    }

    unless (Sympa::is_listmaster($list, $sender)
        or $list->is_admin('owner', $sender)) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Not enough privileges')
            ->faultdetail('Listmaster or listowner required');
    }

    my $members;
    my $user;
    if ($user = $list->get_first_list_member({'sortby' => 'email'})) {
        do {
            $user->{'email'} =~ y/A-Z/a-z/;

            my $res;
            $res->{'email'}        = $user->{'email'};
            $res->{'gecos'}        = $user->{'gecos'};
            $res->{'isOwner'}      = 0;
            $res->{'isEditor'}     = 0;
            $res->{'isSubscriber'} = 0;
            if ($list->is_list_member($user->{'email'})) {
                $res->{'isSubscriber'} = 1;
            }

            $members->{$user->{'email'}} = $res;
        } while ($user = $list->get_next_list_member());
    }

    foreach my $role (qw(owner editor)) {
        foreach my $user ($list->get_admins($role)) {
            $user->{'email'} =~ y/A-Z/a-z/;

            unless (defined $members->{$user->{'email'}}) {
                $members->{$user->{'email'}} = {
                    email        => $user->{'email'},
                    gecos        => $user->{'gecos'},
                    isOwner      => 0,
                    isEditor     => 0,
                    isSubscriber => 0,
                };
            }
            $members->{$user->{'email'}}{'isOwner'}  = 1 if $role eq 'owner';
            $members->{$user->{'email'}}{'isEditor'} = 1 if $role eq 'editor';
        }
    }

    my @result;
    foreach my $email (keys %$members) {
        push @result, struct_to_soap($members->{$email});
    }

    $log->syslog('info', 'FullReview %s from %s accepted', $listname,
        $sender);
    return SOAP::Data->name('return')->value(\@result);
}

sub signoff {
    $log->syslog('notice', '(%s, %s)', @_);
    my ($class, $listname) = @_;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }
    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters.')
            ->faultdetail('Use : <list> ');
    }
    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info', 'Sign off from %s for %s refused, list unknown',
            $listname, $sender);
        die SOAP::Fault->faultcode('Server')->faultstring('Unknown list.')
            ->faultdetail("List $listname unknown");
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'signoff',
        sender           => $sender,
        email            => $sender,
        md5_check        => 1,
        scenario_context => {
            sender                  => $sender,
            remote_application_name => $ENV{remote_application_name},
        },
    );
    unless ($spindle and $spindle->spin) {
        die SOAP::Fault->faultcode('Server')->faultstring('Internal error');
    }

    foreach my $report (@{$spindle->{stash} || []}) {
        my $reason_string = get_reason_string($report, $robot);
        if ($report->[1] eq 'auth') {
            die SOAP::Fault->faultcode('Server')->faultstring('Not allowed.')
                ->faultdetail($reason_string);
        } elsif ($report->[1] eq 'intern') {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Internal error');
        } elsif ($report->[1] eq 'notice') {
            return SOAP::Data->name('result')->type('boolean')->value(1);
        } elsif ($report->[1] eq 'user') {
            die SOAP::Fault->faultcode('Server')->faultstring('Undef')
                ->faultdetail($reason_string);
        }
    }
    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub subscribe {
    $log->syslog('notice', '(%s, %s, %s)', @_);
    my ($class, $listname, $gecos) = @_;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }
    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list> [user gecos]');
    }
    my $list = Sympa::List->new($listname, $robot);
    unless ($list) {
        $log->syslog('info',
            'Subscribe to %s from %s refused, list unknown to robot %s',
            $listname, $sender, $robot);
        die SOAP::Fault->faultcode('Server')->faultstring('Unknown list')
            ->faultdetail("List $listname unknown");
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $list,
        action           => 'subscribe',
        sender           => $sender,
        email            => $sender,
        gecos            => $gecos,
        md5_check        => 1,
        scenario_context => {
            sender                  => $sender,
            remote_application_name => $ENV{remote_application_name},
        },
    );
    unless ($spindle and $spindle->spin) {
        die SOAP::Fault->faultcode('Server')->faultstring('Internal error');
    }

    foreach my $report (@{$spindle->{stash} || []}) {
        my $reason_string = get_reason_string($report, $robot);
        if ($report->[1] eq 'auth') {
            die SOAP::Fault->faultcode('Server')->faultstring('Not allowed.')
                ->faultdetail($reason_string);
        } elsif ($report->[1] eq 'intern') {
            die SOAP::Fault->faultcode('Server')
                ->faultstring('Internal error');
        } elsif ($report->[1] eq 'notice') {
            return SOAP::Data->name('result')->type('boolean')->value(1);
        } elsif ($report->[1] eq 'user') {
            die SOAP::Fault->faultcode('Server')->faultstring('Undef')
                ->faultdetail($reason_string);
        }
    }
    return SOAP::Data->name('result')->type('boolean')->value(1);
}

## Which list the user is subscribed to
## TODO (pour listmaster, toutes les listes)
sub complexWhich {
    my $self   = shift;
    my $sender = $ENV{'USER_EMAIL'};
    $log->syslog('notice', 'Xx complexWhich(%s)', $sender);

    $self->which('complex');
}

sub complexLists {
    my $self     = shift;
    my $topic    = shift || '';
    my $subtopic = shift || '';
    my $sender   = $ENV{'USER_EMAIL'};
    $log->syslog('notice', '(%s)', $sender);

    $self->lists($topic, $subtopic, 'complex');
}

## Which list the user is subscribed to
## TODO (pour listmaster, toutes les listes)
## Simplified return structure
sub which {
    my $self = shift;
    my $mode = shift // '';
    my @result;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    $log->syslog('notice', '(%s, %s)', $sender, $mode);

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    my %listnames;

    foreach my $role ('member', 'owner', 'editor') {
        foreach my $list (Sympa::List::get_which($sender, $robot, $role)) {
            my $name = $list->{'name'};
            $listnames{$name} = $list;
        }
    }

    foreach my $name (keys %listnames) {
        my $list = $listnames{$name};

        my $result_item;

        my $result = Sympa::Scenario->new($list, 'visibility')->authz(
            'md5',
            {   'sender'                  => $sender,
                'remote_application_name' => $ENV{'remote_application_name'}
            }
        );
        my $action;
        $action = $result->{'action'} if (ref($result) eq 'HASH');
        next unless ($action =~ /do_it/i);

        $result_item->{'listAddress'} = Sympa::get_address($list);
        $result_item->{'subject'}     = $list->{'admin'}{'subject'};
        $result_item->{'subject'} =~ s/;/,/g;
        $result_item->{'homepage'} = Sympa::get_url($list, 'info');

        ## determine status of user
        $result_item->{'isOwner'} = 0;
        if ($list->is_admin('owner', $sender)
            or Sympa::is_listmaster($list, $sender)) {
            $result_item->{'isOwner'} = 1;
        }
        $result_item->{'isEditor'} = 0;
        if ($list->is_admin('actual_editor', $sender)) {
            $result_item->{'isEditor'} = 1;
        }
        $result_item->{'isSubscriber'} = 0;
        if ($list->is_list_member($sender)) {
            $result_item->{'isSubscriber'} = 1;
        }
        # determine bounce information of this user for this list
        if ($result_item->{'isSubscriber'}) {
            my $subscriber;
            if ($subscriber = $list->get_list_member($sender)) {
                $result_item->{'bounceCount'} = 0;
                if ($subscriber->{'bounce'} =~
                    /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/) {
                    $result_item->{'firstBounceDate'} = $1;
                    $result_item->{'lastBounceDate'}  = $2;
                    $result_item->{'bounceCount'}     = $3;
                    if ($4 =~ /^\s*(\d+\.(\d+\.\d+))$/) {
                        $result_item->{'bounceCode'} = $1;
                    }
                }
                $result_item->{'bounceScore'} = $subscriber->{'bounce_score'};
            }
        }

        my $listInfo;
        if ($mode eq 'complex') {
            $listInfo = struct_to_soap($result_item);
        } else {
            $listInfo = struct_to_soap($result_item, 'as_string');
        }
        push @result, $listInfo;
    }

#    return SOAP::Data->name('return')->type->('ArrayOfString')
#    ->value(\@result);
    return SOAP::Data->name('return')->value(\@result);
}

sub getDetails {
    my $class    = shift;
    my $listname = shift;
    my $subscriber;
    my $list;
    my %result = ();

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list>');
    }

    $log->syslog('debug', 'SOAP getDetails(%s,%s,%s)',
        $listname, $robot, $sender);

    $list = Sympa::List->new($listname, $robot);
    if (!$list) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('List does not exist')->faultdetail('Use : <list>');
    }
    if ($subscriber = $list->get_list_member($sender)) {
        $result{'gecos'}         = $subscriber->{'gecos'};
        $result{'reception'}     = $subscriber->{'reception'};
        $result{'subscribeDate'} = $subscriber->{'date'};
        $result{'updateDate'}    = $subscriber->{'update_date'};
        $result{'custom'}        = [];
        if ($subscriber->{attrib}) {
            foreach my $k (keys %{$subscriber->{attrib}}) {
                push @{$result{'custom'}},
                    {
                    key   => $k,
                    value => $subscriber->{attrib}{$k}
                    }
                    if $k;
            }
        }
    } else {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Not a subscriber to this list')
            ->faultdetail('Use : <list>');
    }

    return SOAP::Data->name('return')->value(\%result);
}

sub setDetails {
    my $class     = shift;
    my $listname  = shift;
    my $gecos     = shift;
    my $reception = shift;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    my $subscriber;
    my $list;
    my %newcustom;
    my %user;

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    unless ($listname) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail(
            'Use : <list> <gecos> <reception> [ <key> <value> ] ...');
    }

    $log->syslog('debug', 'SOAP setDetails(%s,%s,%s)',
        $listname, $robot, $sender);
    $list = Sympa::List->new($listname, $robot);
    if (!$list) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('List does not exist')
            ->faultdetail(
            'Use : <list> <gecos> <reception> [ <key> <value> ] ...');
    }
    $subscriber = $list->get_list_member($sender);
    if (!$subscriber) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Not a subscriber to this list')
            ->faultdetail(
            'Use : <list> <gecos> <reception> [ <key> <value> ] ...');
    }

    # Set subscriber values; return 1 for success.
    $user{gecos} = $gecos if defined $gecos and $gecos =~ /\S/;
    $user{reception} = $reception
        # ideally, this should check against the available_user_options
        # values from the $list config
        if $reception
        and $reception =~
        /^(mail|nomail|digest|digestplain|summary|notice|txt|html|urlize|not_me)$/;
    my %attrs = @_;
    if (%attrs) {
        # We have any custom attributes passed.
        %newcustom = %{$subscriber->{attrib} // {}};
        while (my ($key, $value) = each %attrs) {
            next unless $key;
            unless (length($value // '')) {
                delete $newcustom{$key};
            } else {
                $newcustom{$key} = $value;
            }
        }
        $user{attrib} = \%newcustom;
    }
    die SOAP::Fault->faultcode('Server')
        ->faultstring('Unable to set user details')
        ->faultdetail("SOAP setDetails : update user failed")
        unless $list->update_list_member($sender, %user);

    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub setCustom {
    my ($class, $listname, $key, $value) = @_;
    my $subscriber;
    my $list;
    my $rv;
    my %newcustom;

    my $sender = $ENV{'USER_EMAIL'};
    my $robot  = $ENV{'SYMPA_ROBOT'};

    unless ($sender) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('User not authenticated')
            ->faultdetail('You should login first');
    }

    unless ($listname and $key) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Incorrect number of parameters')
            ->faultdetail('Use : <list> <key> <value>');
    }

    $log->syslog('debug', 'SOAP setCustom(%s,%s,%s,%s)',
        $listname, $robot, $sender, $key);

    $list = Sympa::List->new($listname, $robot);
    if (!$list) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('List does not exist')
            ->faultdetail('Use : <list> <key> <value>');
    }
    $subscriber = $list->get_list_member($sender);
    if (!$subscriber) {
        die SOAP::Fault->faultcode('Client')
            ->faultstring('Not a subscriber to this list')
            ->faultdetail('Use : <list> <key> <value> ');
    }
    %newcustom = %{$subscriber->{attrib} // {}};

    # Workaround for possible bug in SOAP::Lite.
    Encode::_utf8_off($key);
    Encode::_utf8_off($value);

    unless (length($value // '')) {
        delete $newcustom{$key};
    } else {
        $newcustom{$key} = $value;
    }
    die SOAP::Fault->faultcode('Server')
        ->faultstring('Unable to set user attributes')
        ->faultdetail("SOAP setCustom : update user failed")
        unless $list->update_list_member($sender, attrib => \%newcustom);

    return SOAP::Data->name('result')->type('boolean')->value(1);
}

## Return a structure in SOAP data format
## either flat (string) or structured (complexType)
sub struct_to_soap {
    my $data   = shift;
    my $format = shift // '';

    my $soap_data;

    unless (ref($data) eq 'HASH') {
        return undef;
    }

    if ($format eq 'as_string') {
        my @all;
        my $formated_data;
        foreach my $k (keys %$data) {
            push @all, Encode::decode_utf8($k . '=' . $data->{$k});
        }

        $formated_data = join ';', @all;
        $soap_data = SOAP::Data->type('string')->value($formated_data);
    } else {
        my $formated_data;
        foreach my $k (keys %$data) {
            $formated_data->{$k} =
                SOAP::Data->name($k)->type($types{'listType'}{$k})
                ->value($data->{$k});
        }

        $soap_data = SOAP::Data->value($formated_data);
    }

    return $soap_data;
}

sub get_reason_string {
    my $report = shift;
    my $robot  = shift;

    my $data = {
        report_type  => $report->[1],
        report_entry => $report->[2],
        report_param => {
            action => $report->[0]->{action},
            %{$report->[3] || {}},
        },
    };
    my $string;

    my $template =
        Sympa::Template->new($robot, subdir => 'mail_tt2');    # FIXME: lang?
    unless ($template->parse($data, 'report.tt2', \$string)) {
        my $error = $template->{last_error};
        $error = $error->as_string if ref $error;
        Sympa::send_notify_to_listmaster($robot, 'web_tt2_error', [$error]);
        $log->syslog('info', 'Error parsing');
        return '';
    }

    return $string;
}

1;
