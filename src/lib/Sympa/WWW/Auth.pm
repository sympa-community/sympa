# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2019, 2021 The Sympa Community. See the
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

package Sympa::WWW::Auth;

use strict;
use warnings;
use Digest::MD5;
BEGIN { eval 'use Net::LDAP::Util'; }

use Sympa;
use Conf;
use Sympa::Database;
use Sympa::Log;
use Sympa::Robot;
use Sympa::Tools::Data;
use Sympa::Tools::Text;
use Sympa::User;

my $log = Sympa::Log->instance;

# Moved to: Sympa::User::password_fingerprint().
#sub password_fingerprint;

## authentication : via email or uid
sub check_auth {
    $log->syslog('debug', '(%s, %s, ?, ...)', @_);
    my $robot   = shift;
    my $auth    = shift;    ## User email or UID
    my $pwd     = shift;    ## Password
    my %options = @_;

    my $stash_ref = $options{stash} || [];

    my ($canonic, $user);

    if (Sympa::Tools::Text::valid_email($auth)) {
        return authentication($robot, $auth, $pwd, stash => $stash_ref);
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
                'user' => $user,
                'auth' => 'ldap',
            };

        } else {
            push @$stash_ref, ['user', 'incorrect_passwd']
                unless $ENV{'SYMPA_SOAP'};
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
    $log->syslog('debug', '(%s, %s, ?, ...)', @_);
    my $robot   = shift;
    my $email   = shift;
    my $pwd     = shift;
    my %options = @_;

    my $stash_ref = $options{stash} || [];

    my ($user, $canonic);

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
        push @$stash_ref, ['user', 'too_many_wrong_login']
            unless $ENV{'SYMPA_SOAP'};
        $log->syslog('err',
            'Login is blocked: too many wrong password submission for %s',
            $email);
        return undef;
    }

    my $native_login_failed = 0;
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
            # Old style RC4 encrypted password.
            if ($user->{'password'} and $user->{'password'} =~ /\Acrypt[.]/) {
                $log->syslog('notice',
                    'Password in database seems encrypted. Run upgrade_sympa_password.pl to rehash passwords'
                );
                Sympa::send_notify_to_listmaster('*', 'password_encrypted',
                    {});
                return undef;
            }

            my $fingerprint =
                Sympa::User::password_fingerprint($pwd, $user->{'password'});

            if ($fingerprint eq $user->{'password'}) {
                Sympa::User::update_password_hash($user, $pwd);
                Sympa::User::update_global_user($email,
                    {wrong_login_count => 0});
                return {
                    'user' => $user,
                    'auth' => 'classic',
                };
            }

            $native_login_failed = 1;
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
                    'user' => $user,
                    'auth' => 'ldap',
                };
            }
        }
    }

    # Increment wrong login count, if all login attempts including a
    # user_table method have failed.
    if ($native_login_failed) {
        Sympa::User::update_global_user($email,
            {wrong_login_count => ($user->{'wrong_login_count'} || 0) + 1});
    }

    push @$stash_ref, ['user', 'incorrect_passwd']
        unless $ENV{'SYMPA_SOAP'};
    $log->syslog('err', 'Incorrect password for user %s', $email);

    return undef;
}

sub ldap_authentication {
    $log->syslog('debug2', '(%s, %s, %s, *, %s)', @_[0 .. 2, 4]);
    my $robot       = shift;
    my $ldap        = shift;
    my $auth        = shift;
    my $pwd         = shift;
    my $whichfilter = shift;

    die 'bug in logic. Ask developer' unless $ldap->{auth_type} eq 'ldap';
    unless ($Net::LDAP::Util::VERSION) {
        $log->syslog('err', 'Net::LDAP::Util required. Install it');
        return undef;
    }

    # Skip ldap auth mechanism if an email address was provided and it does
    # not match the corresponding regexp.
    return undef
        if $auth =~ /\@/
        and defined $ldap->{regexp}
        and $auth !~ /$ldap->{regexp}/i;

    my $entry;

    my $filter;
    if ($whichfilter eq 'uid_filter') {
        $filter = $ldap->{'get_dn_by_uid_filter'};
    } elsif ($whichfilter eq 'email_filter') {
        $filter = $ldap->{'get_dn_by_email_filter'};
    }
    my $escaped_auth = Net::LDAP::Util::escape_filter_value($auth);
    $filter =~ s/\[sender\]/$escaped_auth/ig;

    # Get the user's entry.
    my $db = Sympa::Database->new('LDAP', %$ldap);
    unless ($db and $db->connect) {
        $log->syslog('err', 'Unable to connect to the LDAP Server "%s": %s',
            $ldap->{host}, ($db and $db->error));
        return undef;
    }
    my $mesg = $db->do_operation(
        'search',
        base    => $ldap->{'suffix'},
        filter  => $filter,
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'}
    );
    unless ($mesg and $entry = $mesg->shift_entry) {
        $log->syslog(
            'notice', 'Authentication for "%s" failed: %s',
            $auth, $mesg ? 'No entry' : $db->error
        );
        $db->disconnect;
        return undef;
    }
    $db->disconnect;

    # Bind again with user's DN and the password.
    $db = Sympa::Database->new(
        'LDAP',
        %$ldap,
        bind_dn       => $entry->dn,
        bind_password => $pwd,
    );
    unless ($db and $db->connect) {
        $log->syslog('notice', 'Authentication for "%s" failed: %s',
            $auth, ($db and $db->error));
        return undef;
    }
    $db->disconnect;

    # If the identifier provided was a valid email, return the provided email.
    # Otherwise, return the canonical email guessed after the login.
    my $do_canonicalize =
        Conf::get_robot_conf($robot, 'ldap_force_canonical_email')
        || !Sympa::Tools::Text::valid_email($auth);
    if ($do_canonicalize and $ldap->{email_attribute}) {
        my $values =
            $entry->get_value($ldap->{email_attribute}, alloptions => 1);
        ($auth) =
            grep { Sympa::Tools::Text::valid_email($_) }
            map { @{$values->{$_}} } sort keys %{$values || {}};
    }

    $log->syslog('debug3', 'Canonic: %s', $auth);
    return undef unless Sympa::Tools::Text::valid_email($auth);
    return $auth;
}

# fetch user email using their cas net_id and the paragrapah number in auth.conf
# NOTE: This might be moved to Robot package.
sub get_email_by_net_id {
    $log->syslog('debug', '(%s, %s, %s)', @_);
    my $robot      = shift;
    my $auth       = shift;
    my $attributes = shift;

    if (defined $auth->{internal_email_by_netid}) {
        my $netid_cookie = $auth->{netid_http_header};

        $netid_cookie =~ s/(\w+)/$attributes->{$1}/ig;

        my $email =
            Sympa::Robot::get_netidtoemail_db($robot, $netid_cookie,
            $auth->{service_id});

        return $email;
    }

    my %ldap = %$auth;
    my $db = Sympa::Database->new('LDAP', %ldap);
    unless ($db and $db->connect) {
        $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
            $ldap{host});
        return undef;
    }

    my $filter = $auth->{get_email_by_uid_filter};
    $filter =~ s/\[([\w-]+)\]/$attributes->{$1}/ig;

    my $mesg = $db->do_operation(
        'search',
        base    => $auth->{suffix},
        filter  => $filter,
        scope   => $auth->{scope},
        timeout => $auth->{timeout},
        attrs   => [$auth->{email_attribute}],
    );

    unless ($mesg and $mesg->count) {
        $log->syslog('notice', "No entry in the LDAP Directory Tree of %s",
            $ldap{host});
        $db->disconnect;
        return undef;
    }

    $db->disconnect;

    # Return only the first attribute.
    foreach my $result ($mesg->entries) {
        my $email = $result->get_value($auth->{email_attribute});
        return undef unless Sympa::Tools::Text::valid_email($email);
        return Sympa::Tools::Text::canonic_email($email);
    }
    return undef;
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
