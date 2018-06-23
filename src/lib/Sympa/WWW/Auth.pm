# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::WWW::Auth;

use strict;
use warnings;
use Digest::MD5;

use Sympa;
use Conf;
use Sympa::Database;
use Sympa::Log;
use Sympa::Robot;
use Sympa::Tools::Data;
use Sympa::Tools::Text;
use Sympa::User;
use Sympa::WWW::Report;

my $log = Sympa::Log->instance;

# Moved to: Sympa::User::password_fingerprint().
#sub password_fingerprint;

## authentication : via email or uid
sub check_auth {
    my $robot = shift;
    my $auth  = shift;    ## User email or UID
    my $pwd   = shift;    ## Password
    $log->syslog('debug', '(%s)', $auth);

    my ($canonic, $user);

    if (Sympa::Tools::Text::valid_email($auth)) {
        return authentication($robot, $auth, $pwd);
    } else {
        ## This is an UID
        foreach my $ldap (@{$Conf::Conf{'auth_services'}{$robot}}) {
            # only ldap service are to be applied here
            next unless ($ldap->{'auth_type'} eq 'ldap');

            $canonic =
                ldap_authentication($robot, $ldap, $auth, $pwd, 'uid_filter');
            last if ($canonic);    ## Stop at first match
        }
        if ($canonic) {

            unless ($user = Sympa::User::get_global_user($canonic)) {
                $user = {'email' => $canonic};
            }
            return {
                'user'       => $user,
                'auth'       => 'ldap',
                'alt_emails' => {$canonic => 'ldap'}
            };

        } else {
            Sympa::WWW::Report::reject_report_web('user', 'incorrect_passwd',
                {})
                unless ($ENV{'SYMPA_SOAP'});
            $log->syslog('err', "Incorrect LDAP password");
            return undef;
        }
    }
}

## This subroutine if Sympa may use its native authentication for a given user
## It might not if no user_table paragraph is found in auth.conf or if the
## regexp or
## negative_regexp exclude this user
## IN : robot, user email
## OUT : boolean
sub may_use_sympa_native_auth {
    my ($robot, $user_email) = @_;

    my $ok = 0;
    ## check each auth.conf paragrpah
    foreach my $auth_service (@{$Conf::Conf{'auth_services'}{$robot}}) {
        next unless ($auth_service->{'auth_type'} eq 'user_table');

        next
            if ($auth_service->{'regexp'}
            && ($user_email !~ /$auth_service->{'regexp'}/i));
        next
            if ($auth_service->{'negative_regexp'}
            && ($user_email =~ /$auth_service->{'negative_regexp'}/i));

        $ok = 1;
        last;
    }

    return $ok;
}

sub authentication {
    my ($robot, $email, $pwd) = @_;
    my ($user, $canonic);
    $log->syslog('debug', '(%s)', $email);

    unless ($user = Sympa::User::get_global_user($email)) {
        $user = {'email' => $email};
    }
    unless ($user->{'password'}) {
        $user->{'password'} = '';
    }

    if (($user->{'wrong_login_count'} || 0) >
        Conf::get_robot_conf($robot, 'max_wrong_password')) {
        # too many wrong login attemp
        Sympa::User::update_global_user($email,
            {wrong_login_count => $user->{'wrong_login_count'} + 1});
        Sympa::WWW::Report::reject_report_web('user', 'too_many_wrong_login',
            {})
            unless ($ENV{'SYMPA_SOAP'});
        $log->syslog('err',
            'Login is blocked: too many wrong password submission for %s',
            $email);
        return undef;
    }
    foreach my $auth_service (@{$Conf::Conf{'auth_services'}{$robot}}) {
        next if ($auth_service->{'auth_type'} eq 'authentication_info_url');
        next if ($email !~ /$auth_service->{'regexp'}/i);
        next
            if $auth_service->{'negative_regexp'}
            and $email =~ /$auth_service->{'negative_regexp'}/i;

        ## Only 'user_table' and 'ldap' backends will need that Sympa collects
        ## the user passwords
        ## Other backends are Single Sign-On solutions
        if ($auth_service->{'auth_type'} eq 'user_table') {
            my $fingerprint =
                Sympa::User::password_fingerprint($pwd, $user->{'password'});

            if ($fingerprint eq $user->{'password'}) {
                Sympa::User::update_password_hash($user, $pwd);
                Sympa::User::update_global_user($email,
                    {wrong_login_count => 0});
                return {
                    'user'       => $user,
                    'auth'       => 'classic',
                    'alt_emails' => {$email => 'classic'}
                };
            }
        } elsif ($auth_service->{'auth_type'} eq 'ldap') {
            if ($canonic = ldap_authentication(
                    $robot, $auth_service, $email, $pwd, 'email_filter'
                )
            ) {
                unless ($user = Sympa::User::get_global_user($canonic)) {
                    $user = {'email' => $canonic};
                }
                Sympa::User::update_global_user($canonic,
                    {wrong_login_count => 0});
                return {
                    'user'       => $user,
                    'auth'       => 'ldap',
                    'alt_emails' => {$email => 'ldap'}
                };
            }
        }
    }

    # increment wrong login count.
    Sympa::User::update_global_user($email,
        {wrong_login_count => ($user->{'wrong_login_count'} || 0) + 1});

    Sympa::WWW::Report::reject_report_web('user', 'incorrect_passwd', {})
        unless $ENV{'SYMPA_SOAP'};
    $log->syslog('err', 'Incorrect password for user %s', $email);

    my $param;    #FIXME FIXME: not used.
    $param->{'init_email'} = $email;
    return undef;
}

sub ldap_authentication {
    my ($robot, $ldap, $auth, $pwd, $whichfilter) = @_;
    my $mesg;
    $log->syslog('debug2', '(%s, %s, %s)', $auth, '****', $whichfilter);
    $log->syslog('debug3', 'Password used: %s', $pwd);

    unless (Sympa::search_fullpath($robot, 'auth.conf')) {
        return undef;
    }

    ## No LDAP entry is defined in auth.conf
    if ($#{$Conf::Conf{'auth_services'}{$robot}} < 0) {
        $log->syslog('notice', 'Skipping empty auth.conf');
        return undef;
    }

    # only ldap service are to be applied here
    return undef unless ($ldap->{'auth_type'} eq 'ldap');

    # skip ldap auth service if the an email address was provided
    # and this email address does not match the corresponding regexp
    return undef if ($auth =~ /@/ && $auth !~ /$ldap->{'regexp'}/i);

    my @alt_attrs =
        split /\s*,\s*/, ($ldap->{'alternative_email_attribute'} || '');
    my $attr = $ldap->{'email_attribute'};
    my $filter;
    if ($whichfilter eq 'uid_filter') {
        $filter = $ldap->{'get_dn_by_uid_filter'};
    } elsif ($whichfilter eq 'email_filter') {
        $filter = $ldap->{'get_dn_by_email_filter'};
    }
    $filter =~ s/\[sender\]/$auth/ig;

    ## bind in order to have the user's DN
    my $db = Sympa::Database->new('LDAP', %$ldap);

    unless ($db and $db->connect()) {
        $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
            $ldap->{'host'});
        return undef;
    }

    $mesg = $db->do_operation(
        'search',
        base    => $ldap->{'suffix'},
        filter  => "$filter",
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'}
    );

    unless ($mesg and $mesg->count()) {
        $log->syslog('notice',
            'No entry in the LDAP Directory Tree of %s for %s',
            $ldap->{'host'}, $auth);
        $db->disconnect();
        return undef;
    }

    my $refhash = $mesg->as_struct();
    my (@DN) = keys(%$refhash);
    $db->disconnect();

    ##  bind with the DN and the pwd

    # Then set the bind_dn and password according to the current user
    $db = Sympa::Database->new(
        'LDAP',
        %$ldap,
        bind_dn       => $DN[0],
        bind_password => $pwd,
    );

    unless ($db and $db->connect()) {
        $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
            $ldap->{'host'});
        return undef;
    }

    $mesg = $db->do_operation(
        'search',
        base    => $ldap->{'suffix'},
        filter  => "$filter",
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'}
    );

    unless ($mesg and $mesg->count()) {
        $log->syslog('notice', "No entry in the LDAP Directory Tree of %s",
            $ldap->{'host'});
        $db->disconnect();
        return undef;
    }

    ## To get the value of the canonic email and the alternative email
    my (@emails, @alt_emails);

    #FIXME FIXME: After all, $param->{'alt_emails'} is never used!
    my $param = Sympa::Tools::Data::dup_var($ldap);
    ## Keep previous alt emails not from LDAP source
    my $previous = {};
    foreach my $alt (keys %{$param->{'alt_emails'}}) {
        $previous->{$alt} = $param->{'alt_emails'}{$alt}
            if ($param->{'alt_emails'}{$alt} ne 'ldap');
    }
    $param->{'alt_emails'} = {};

    my $entry = $mesg->entry(0);

    my $values = $entry->get_value($attr, alloptions => 1);
    @emails =
        map { lc $_ }
        grep {$_} map { @{$values->{$_}} } sort keys %{$values || {}};

    @alt_emails = map {
        my $values = $entry->get_value($_, alloptions => 1);
        map { lc $_ }
            grep {$_} map { @{$values->{$_}} } sort keys %{$values || {}};
    } @alt_attrs;

    foreach my $email (@emails, @alt_emails) {
        $param->{'alt_emails'}{$email} = 'ldap';
    }

    ## Restore previous emails
    foreach my $alt (keys %{$previous}) {
        $param->{'alt_emails'}{$alt} = $previous->{$alt};
    }

    $db->disconnect() or $log->syslog('notice', 'Unable to unbind');
    $log->syslog('debug3', 'Canonic: %s', $emails[0]);
    ## If the identifier provided was a valid email, return the provided
    ## email.
    ## Otherwise, return the canonical email guessed after the login.
    if (Sympa::Tools::Text::valid_email($auth)
        and not Conf::get_robot_conf($robot, 'ldap_force_canonical_email')) {
        return $auth;
    } else {
        return $emails[0];
    }
}

# fetch user email using his cas net_id and the paragrapah number in auth.conf
# NOTE: This might be moved to Robot package.
sub get_email_by_net_id {

    my $robot      = shift;
    my $auth_id    = shift;
    my $attributes = shift;

    $log->syslog('debug', '(%s, %s)', $auth_id, $attributes->{'uid'});

    if (defined $Conf::Conf{'auth_services'}{$robot}[$auth_id]
        {'internal_email_by_netid'}) {
        my $sso_config   = @{$Conf::Conf{'auth_services'}{$robot}}[$auth_id];
        my $netid_cookie = $sso_config->{'netid_http_header'};

        $netid_cookie =~ s/(\w+)/$attributes->{$1}/ig;

        my $email =
            Sympa::Robot::get_netidtoemail_db($robot, $netid_cookie,
            $Conf::Conf{'auth_services'}{$robot}[$auth_id]{'service_id'});

        return $email;
    }

    my $ldap = $Conf::Conf{'auth_services'}{$robot}->[$auth_id];

    my $db = Sympa::Database->new('LDAP', %$ldap);

    unless ($db and $db->connect()) {
        $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
            $ldap->{'host'});
        return undef;
    }

    my $filter = $ldap->{'get_email_by_uid_filter'};
    $filter =~ s/\[([\w-]+)\]/$attributes->{$1}/ig;

    # my @alt_attrs =
    #     split /\s*,\s*/, $ldap->{'alternative_email_attribute'} || '';

    my $mesg = $db->do_operation(
        'search',
        base    => $ldap->{'suffix'},
        filter  => $filter,
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'},
        attrs   => [$ldap->{'email_attribute'}],
    );

    unless ($mesg and $mesg->count()) {
        $log->syslog('notice', "No entry in the LDAP Directory Tree of %s",
            $ldap->{'host'});
        $db->disconnect();
        return undef;
    }

    $db->disconnect();

    ## return only the first attribute
    my @results = $mesg->entries;
    foreach my $result (@results) {
        return (lc($result->get_value($ldap->{'email_attribute'})));
    }

}

# check trusted_application_name et trusted_application_password : return 1 or
# undef;
sub remote_app_check_password {
    my ($trusted_application_name, $password, $robot, $service) = @_;
    $log->syslog('debug', '(%s, %s, %s)', $trusted_application_name, $robot,
        $service);

    my $md5 = Digest::MD5::md5_hex($password);

    # seach entry for trusted_application in Conf
    my @trusted_apps;

    # select trusted_apps from robot context or sympa context
    @trusted_apps = @{Conf::get_robot_conf($robot, 'trusted_applications')};

    foreach my $application (@trusted_apps) {

        if (lc($application->{'name'}) eq lc($trusted_application_name)) {
            if ($md5 eq $application->{'md5password'}) {
                # $log->syslog('debug', 'Authentication succeed for %s',$application->{'name'});
                my %proxy_for_vars;
                my %set_vars;
                foreach my $varname (@{$application->{'proxy_for_variables'}})
                {
                    $proxy_for_vars{$varname} = 1;
                }
                foreach my $varname (@{$application->{'set_variables'}}) {
                    $set_vars{$1} = $2 if $varname =~ /(\S+)=(.*)/;
                }
                if ($application->{'allow_commands'}) {
                    foreach my $cmdname (@{$application->{'allow_commands'}})
                    {
                        return (\%proxy_for_vars, \%set_vars)
                            if $cmdname eq $service;
                    }
                    $log->syslog(
                        'info',   'Illegal command %s received from %s',
                        $service, $trusted_application_name
                    );
                    return;
                }
                return (\%proxy_for_vars, \%set_vars);
            } else {
                $log->syslog('info', 'Bad password from %s',
                    $trusted_application_name);
                return;
            }
        }
    }
    # no matching application found
    $log->syslog('info', 'Unknown application name %s',
        $trusted_application_name);
    return;
}

# Moved to Sympa::Ticket::create().
#sub create_one_time_ticket;

# Moved to Sympa::Tickect::load().
#sub get_one_time_ticket;

1;
