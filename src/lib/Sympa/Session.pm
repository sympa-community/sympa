# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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

package Sympa::Session;

use strict;
use warnings;
use CGI::Cookie;
use Digest::MD5;

use Conf;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::Log;
use tools;
use Sympa::Tools::Data;
use Sympa::Tools::Password;
use Sympa::Tools::Time;

# this structure is used to define which session attributes are stored in a
# dedicated database col where others are compiled in col 'data_session'
my %session_hard_attributes = (
    'id_session'   => 1,
    'prev_id'      => 1,
    'date'         => 1,
    'refresh_date' => 1,
    'remote_addr'  => 1,
    'robot'        => 1,
    'email'        => 1,
    'start_date'   => 1,
    'hit'          => 1,
    'new_session'  => 1,
);

my $log = Sympa::Log->instance;

sub new {
    my $pkg     = shift;
    my $robot   = shift;
    my $context = shift;

    my $cookie = $context->{'cookie'};
    my $action = $context->{'action'};
    my $rss    = $context->{'rss'};
    #my $ajax = $context->{'ajax'};

    $log->syslog('debug', '(%s, %s, %s)', $robot, $cookie, $action);
    my $self = {'robot' => $robot};    # set current robot
    bless $self, $pkg;

    unless ($robot) {
        $log->syslog('err',
            'Missing robot parameter, cannot create session object');
        return undef;
    }

    # passive_session are session not stored in the database, they are used
    # for crawler bots and action such as css, wsdl, ajax and rss
    if (_is_a_crawler($robot)) {
        $self->{'is_a_crawler'}    = 1;
        $self->{'passive_session'} = 1;
    }
    $self->{'passive_session'} = 1
        if $rss
            or $action and ($action eq 'wsdl' or $action eq 'css');

    # if a session cookie exist, try to restore an existing session, don't
    # store sessions from bots
    if ($cookie and !$self->{'passive_session'}) {
        my $status;
        $status = $self->load($cookie);
        unless (defined $status) {
            return undef;
        }
        if ($status eq 'not_found') {
            # Start a Sympa::Session->new(may be a fake cookie).
            $log->syslog('info', 'Ignoring unknown session cookie "%s"',
                $cookie);
            return (Sympa::Session->new($robot));
        }
    } else {
        # create a new session context
        $self->{'new_session'} =
            1;    ## Tag this session as new, ie no data in the DB exist
        $self->{'id_session'}  = Sympa::Tools::Password::get_random();
        $self->{'email'}       = 'nobody';
        $self->{'remote_addr'} = $ENV{'REMOTE_ADDR'};
        $self->{'date'} = $self->{'refresh_date'} = $self->{'start_date'} =
            time;
        $self->{'hit'}  = 1;
        $self->{'data'} = '';
    }
    return $self;
}

sub load {
    my $self   = shift;
    my $cookie = shift;
    $log->syslog('debug', '(%s)', $cookie);

    unless ($cookie) {
        $log->syslog('err', 'Internal error.  Undefined id_session');
        return undef;
    }

    my $sth;
    my $statement;
    my $id_session;
    my $is_old_session = 0;

    my $sdm = Sympa::DatabaseManager->instance;

    ## Load existing session.
    if ($cookie and $cookie !~ /[^0-9]/ and length $cookie <= 16) {
        ## Compatibility: session by older releases of Sympa.
        $id_session     = $cookie;
        $is_old_session = 1;

        ## Session by older releases of Sympa doesn't have refresh_date.
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT id_session AS id_session, id_session AS prev_id,
                         date_session AS "date",
                         remote_addr_session AS remote_addr,
                         email_session AS email,
                         data_session AS data, hit_session AS hit,
                         start_date_session AS start_date,
                         date_session AS refresh_date
                  FROM session_table
                  WHERE id_session = ? AND
                        refresh_date_session IS NULL},
                $id_session
            )
            ) {
            $log->syslog('err', 'Unable to load session %s', $id_session);
            return undef;
        }
    } else {
        $id_session = decrypt_session_id($cookie);
        unless ($id_session) {
            $log->syslog('err', 'Internal error.  Undefined id_session');
            return undef;
        }

        ## Cookie may contain current or previous session ID.
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT id_session AS id_session, prev_id_session AS prev_id,
                         date_session AS "date",
                         remote_addr_session AS remote_addr,
                         email_session AS email,
                         data_session AS data, hit_session AS hit,
                         start_date_session AS start_date,
                         refresh_date_session AS refresh_date
                  FROM session_table
                  WHERE id_session = ? AND prev_id_session IS NOT NULL OR
                        prev_id_session = ?},
                $id_session, $id_session
            )
            ) {
            $log->syslog('err', 'Unable to load session %s', $id_session);
            return undef;
        }
    }

    my $session     = undef;
    my $new_session = undef;
    my $counter     = 0;
    while ($new_session = $sth->fetchrow_hashref('NAME_lc')) {
        if ($counter > 0) {
            $log->syslog('err',
                'The SQL statement did return more than one session');
            $session->{'email'} = '';
            last;
        }
        $session = $new_session;
        $counter++;
    }

    unless ($session) {
        return 'not_found';
    }

    ## Compatibility: Upgrade session by older releases of Sympa.
    if ($is_old_session) {
        $sdm->do_prepared_query(
            q{UPDATE session_table
              SET prev_id_session = id_session
              WHERE id_session = ? AND prev_id_session IS NULL AND
                    refresh_date_session IS NULL},
            $id_session
        );
    }

    my %datas = Sympa::Tools::Data::string_2_hash($session->{'data'});

    ## canonicalize lang if possible.
    $datas{'lang'} = Sympa::Language::canonic_lang($datas{'lang'})
        || $datas{'lang'}
        if $datas{'lang'};

    foreach my $key (keys %datas) { $self->{$key} = $datas{$key}; }

    $self->{'id_session'}   = $session->{'id_session'};
    $self->{'prev_id'}      = $session->{'prev_id'};
    $self->{'date'}         = $session->{'date'};
    $self->{'refresh_date'} = $session->{'refresh_date'};
    $self->{'start_date'}   = $session->{'start_date'};
    $self->{'hit'}          = $session->{'hit'} + 1;
    $self->{'remote_addr'}  = $session->{'remote_addr'};
    $self->{'email'}        = $session->{'email'};

    return ($self);
}

## This method will both store the session information in the database
sub store {
    my $self = shift;
    $log->syslog('debug', '');

    return undef unless ($self->{'id_session'});
    # do not create a session in session table for crawlers;
    return
        if ($self->{'is_a_crawler'});
    # do not create a session in session table for action such as RSS or CSS
    # or wsdlthat do not require this sophistication;
    return
        if ($self->{'passive_session'});

    my %hash;
    foreach my $var (keys %$self) {
        next if ($session_hard_attributes{$var});
        next unless ($var);
        $hash{$var} = $self->{$var};
    }
    my $data_string = Sympa::Tools::Data::hash_2_string(\%hash);
    my $time        = time;

    my $sdm = Sympa::DatabaseManager->instance;

    ## If this is a new session, then perform an INSERT
    if ($self->{'new_session'}) {
        # Store the new session ID in the DB
        # Previous session ID is set to be same as new session ID.
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{INSERT INTO session_table
                  (id_session, prev_id_session,
                   date_session, refresh_date_session,
                   remote_addr_session, robot_session,
                   email_session, start_date_session, hit_session,
                   data_session)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)},
                $self->{'id_session'}, $self->{'id_session'},
                $time,                 $time,
                $ENV{'REMOTE_ADDR'},   $self->{'robot'},
                $self->{'email'}, $self->{'start_date'}, $self->{'hit'},
                $data_string
            )
            ) {
            $log->syslog('err',
                'Unable to add new information for session %s in database',
                $self->{'id_session'});
            return undef;
        }

        $self->{'prev_id'} = $self->{'id_session'};
    } else {
        ## If the session already exists in DB, then perform an UPDATE

        ## Cookie may contain previous session ID.
        my $sth;
        unless (
            $sdm
            and $sth = $sdm->do_prepared_query(
                q{SELECT id_session
                  FROM session_table
                  WHERE prev_id_session = ?},
                $self->{'id_session'}
            )
            ) {
            $log->syslog('err',
                'Unable to update session information in database');
            return undef;
        }
        my $new_id;
        ($new_id) = $sth->fetchrow_array;
        $sth->finish;
        if ($new_id) {
            $self->{'prev_id'}    = $self->{'id_session'};
            $self->{'id_session'} = $new_id;
        }

        ## Update the new session in the DB
        unless (
            $sdm->do_prepared_query(
                q{UPDATE session_table
                  SET date_session = ?, remote_addr_session = ?,
                      robot_session = ?, email_session = ?,
                      start_date_session = ?, hit_session = ?, data_session = ?
                  WHERE id_session = ? AND prev_id_session IS NOT NULL OR
                        prev_id_session = ?},
                $time,            $ENV{'REMOTE_ADDR'},
                $self->{'robot'}, $self->{'email'},
                $self->{'start_date'}, $self->{'hit'}, $data_string,
                $self->{'id_session'},
                $self->{'id_session'}
            )
            ) {
            $log->syslog('err',
                'Unable to update information for session %s in database',
                $self->{'id_session'});
            return undef;
        }
    }

    return 1;
}

## This method will renew the session ID
sub renew {
    my $self = shift;
    $log->syslog('debug', '(id_session=%s)', $self->{'id_session'});

    return undef unless ($self->{'id_session'});
    # do not create a session in session table for crawlers;
    return
        if ($self->{'is_a_crawler'});
    # do not create a session in session table for action such as RSS or CSS
    # or wsdlthat do not require this sophistication;
    return
        if ($self->{'passive_session'});

    my %hash;
    foreach my $var (keys %$self) {
        next if ($session_hard_attributes{$var});
        next unless ($var);
        $hash{$var} = $self->{$var};
    }

    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    # Cookie may contain previous session ID.
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT id_session
              FROM session_table
              WHERE prev_id_session = ?},
            $self->{'id_session'}
        )
        ) {
        $log->syslog('err',
            'Unable to update information for session %s in database',
            $self->{'id_session'});
        return undef;
    }
    my $new_id;
    ($new_id) = $sth->fetchrow_array;
    $sth->finish;
    if ($new_id) {
        $self->{'prev_id'}    = $self->{'id_session'};
        $self->{'id_session'} = $new_id;
    }

    ## Renew the session ID in order to prevent session hijacking
    $new_id = Sympa::Tools::Password::get_random();

    ## Do refresh the session ID when remote address was changed or refresh
    ## interval was past.  Conditions also are checked by SQL so that
    ## simultaneous processes will be prevented renewing cookie.
    my $time        = time;
    my $remote_addr = $ENV{'REMOTE_ADDR'};
    my $refresh_term;
    if ($Conf::Conf{'cookie_refresh'} == 0) {
        $refresh_term = $time;
    } else {
        my $cookie_refresh = $Conf::Conf{'cookie_refresh'};
        $refresh_term =
            int($time - $cookie_refresh * 0.25 - rand($cookie_refresh * 0.5));
    }
    unless ($self->{'remote_addr'} ne $remote_addr
        or $self->{'refresh_date'} <= $refresh_term) {
        return 0;
    }

    ## First insert DB entry with new session ID,
    # Note: prepared query cannot be used, because use of placeholder (?) as
    # selected value is not portable.
    $sth = $sdm->do_query(
        q{INSERT INTO session_table
          (id_session, prev_id_session,
           start_date_session, date_session, refresh_date_session,
           remote_addr_session, robot_session, email_session,
           hit_session, data_session)
          SELECT %s, id_session,
                 start_date_session, date_session, %d,
                 %s, %s, email_session,
                 hit_session, data_session
          FROM session_table
          WHERE (id_session = %s AND prev_id_session IS NOT NULL OR
                 prev_id_session = %s) AND
                (remote_addr_session <> %s OR refresh_date_session <= %d)},
        $sdm->quote($new_id),
        $time,
        $sdm->quote($remote_addr),
        $sdm->quote($self->{'robot'}),
        $sdm->quote($self->{'id_session'}),
        $sdm->quote($self->{'id_session'}),
        $sdm->quote($remote_addr), $refresh_term
    );
    unless ($sth) {
        $log->syslog('err', 'Unable to renew session ID for session %s',
            $self->{'id_session'});
        return undef;
    }
    unless ($sth->rows) {
        return 0;
    }
    ## Keep previous ID to prevent crosstalk, clearing grand-parent ID.
    $sdm->do_prepared_query(
        q{UPDATE session_table
          SET prev_id_session = NULL
          WHERE id_session = ?},
        $self->{'id_session'}
    );
    ## Remove record of grand-parent ID.
    $sdm->do_prepared_query(
        q{DELETE FROM session_table
          WHERE id_session = ? AND prev_id_session IS NULL},
        $self->{'prev_id'}
    );

    ## Renew the session ID in order to prevent session hijacking
    $log->syslog(
        'info',
        '[robot %s] [session %s] [client %s]%s new session %s',
        $self->{'robot'},
        $self->{'id_session'},
        $remote_addr,
        ($self->{'email'} ? sprintf(' [user %s]', $self->{'email'}) : ''),
        $new_id
    );
    $self->{'prev_id'}      = $self->{'id_session'};
    $self->{'id_session'}   = $new_id;
    $self->{'refresh_date'} = $time;
    $self->{'remote_addr'}  = $remote_addr;

    return 1;
}

## remove old sessions from a particular robot or from all robots.
## delay is a parameter in seconds
sub purge_old_sessions {
    $log->syslog('debug2', '(%s)', @_);
    my $robot = shift;

    my $delay =
        Sympa::Tools::Time::duration_conv($Conf::Conf{'session_table_ttl'});
    my $anonymous_delay = Sympa::Tools::Time::duration_conv(
        $Conf::Conf{'anonymous_session_table_ttl'});

    unless ($delay) {
        $log->syslog('info', '(%s) Exit with delay null', $robot);
        return;
    }
    unless ($anonymous_delay) {
        $log->syslog('info', '(%s) Exit with anonymous delay null', $robot);
        return;
    }

    my @sessions;
    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm) {
        $log->syslog('err', 'Unavailable database connection');
        return;
    }

    my (@conditions, @anonymous_conditions);
    push @conditions, sprintf('robot_session = %s', $sdm->quote($robot))
        if $robot and $robot ne '*';
    @anonymous_conditions = @conditions;

    push @conditions, sprintf('%d > date_session', time - $delay) if $delay;
    push @anonymous_conditions,
        sprintf('%d > date_session', time - $anonymous_delay)
        if $anonymous_delay;

    my $condition           = join ' AND ', @conditions;
    my $anonymous_condition = join ' AND ', @anonymous_conditions,
        "email_session = 'nobody'", 'hit_session = 1';

    my $count_statement =
        sprintf q{SELECT COUNT(*) FROM session_table WHERE %s}, $condition;
    my $anonymous_count_statement =
        sprintf q{SELECT COUNT(*) FROM session_table WHERE %s},
        $anonymous_condition;

    my $statement = sprintf q{DELETE FROM session_table WHERE %s}, $condition;
    my $anonymous_statement = sprintf q{DELETE FROM session_table WHERE %s},
        $anonymous_condition;

    unless ($sth = $sdm->do_query($count_statement)) {
        $log->syslog('err', 'Unable to count old session for robot %s',
            $robot);
        return undef;
    }

    my $total = $sth->fetchrow;
    if ($total == 0) {
        $log->syslog('debug', 'No sessions to expire');
    } else {
        unless ($sth = $sdm->do_query($statement)) {
            $log->syslog('err', 'Unable to purge old sessions for robot %s',
                $robot);
            return undef;
        }
    }
    unless ($sth = $sdm->do_query($anonymous_count_statement)) {
        $log->syslog('err', 'Unable to count anonymous sessions for robot %s',
            $robot);
        return undef;
    }
    my $anonymous_total = $sth->fetchrow;
    if ($anonymous_total == 0) {
        $log->syslog('debug', 'No anonymous sessions to expire');
        return $total;
    }
    unless ($sth = $sdm->do_query($anonymous_statement)) {
        $log->syslog('err', 'Unable to purge anonymous sessions for robot %s',
            $robot);
        return undef;
    }
    return $total + $anonymous_total;
}

# Moved to: Sympa::Ticket::purge_old_tickets().
#sub purge_old_tickets;

# list sessions for $robot where last access is newer then $delay. List is
# limited to connected users if $connected_only
sub list_sessions {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $delay          = shift;
    my $robot          = shift;
    my $connected_only = shift;

    my @sessions;
    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm) {
        $log->syslog('err', 'Unavailable database connection');
        return undef;
    }

    my @conditions;
    push @conditions, sprintf('robot_session = %s', $sdm->quote($robot))
        if $robot and $robot ne '*';
    push @conditions, sprintf('%d < date_session ', time - $delay) if $delay;
    push @conditions, " email_session <> 'nobody' "
        if $connected_only and $connected_only eq 'on';

    my $condition = join ' AND ', @conditions, 'prev_id_session IS NOT NULL';

    my $statement =
        sprintf q{SELECT remote_addr_session, email_session, robot_session,
                         date_session AS date_epoch,
                         start_date_session AS start_date_epoch, hit_session
                  FROM session_table
                  WHERE %s}, $condition;
    $log->syslog('debug', 'Statement = %s', $statement);

    unless ($sth = $sdm->do_query($statement)) {
        $log->syslog('err', 'Unable to get the list of sessions for robot %s',
            $robot);
        return undef;
    }

    while (my $session = ($sth->fetchrow_hashref('NAME_lc'))) {
        push @sessions, $session;
    }

    return \@sessions;
}

###############################
# Subroutines to read cookies #
###############################

## Subroutine to get session cookie value
sub get_session_cookie {
    my $http_cookie = shift;
    return Sympa::Session::_generic_get_cookie($http_cookie, 'sympa_session');
}

## Generic subroutine to set a cookie
## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec)
## domain=(localhost|<a domain>)
sub set_cookie {
    my ($self, $http_domain, $expires, $use_ssl) = @_;
    $log->syslog('debug', '(%s, %s, secure= %s)',
        $http_domain, $expires, $use_ssl);

    my $expiration;
    if ($expires =~ /now/i) {
        ## 10 years ago
        $expiration = '-10y';
    } else {
        $expiration = '+' . $expires . 'm';
    }

    if ($http_domain eq 'localhost') {
        $http_domain = "";
    }

    my $value = encrypt_session_id($self->{'id_session'});

    my $cookie;
    if ($expires =~ /session/i) {
        $cookie = CGI::Cookie->new(
            -name     => 'sympa_session',
            -value    => $value,
            -domain   => $http_domain,
            -path     => '/',
            -secure   => $use_ssl,
            -httponly => 1
        );
    } else {
        $cookie = CGI::Cookie->new(
            -name     => 'sympa_session',
            -value    => $value,
            -expires  => $expiration,
            -domain   => $http_domain,
            -path     => '/',
            -secure   => $use_ssl,
            -httponly => 1
        );
    }

    ## Send cookie to the client
    printf "Set-Cookie: %s\n", $cookie->as_string;
    return 1;
}

# Build an HTTP cookie value to be sent to a SOAP client
sub soap_cookie2 {
    my ($session_id, $http_domain, $expire) = @_;
    my $cookie;
    my $value;

    # WARNING : to check the cookie the SOAP services does not gives
    # all the cookie, only it's value so we need ':'
    $value = encrypt_session_id($session_id);

    ## With set-cookie2 max-age of 0 means removing the cookie
    ## Maximum cookie lifetime is the session
    $expire ||= 600;    ## 10 minutes

    if ($http_domain eq 'localhost') {
        $cookie = CGI::Cookie->new(
            -name  => 'sympa_session',
            -value => $value,
            -path  => '/',
        );
        $cookie->max_age(time + $expire);    # needs CGI >= 3.51.
    } else {
        $cookie = CGI::Cookie->new(
            -name   => 'sympa_session',
            -value  => $value,
            -domain => $http_domain,
            -path   => '/',
        );
        $cookie->max_age(time + $expire);    # needs CGI >= 3.51.
    }

    ## Return the cookie value
    return $cookie->as_string;
}

# Moved to Sympa::Tools::Password::get_random().
#sub get_random;

## Return the session object content, as a hashref
sub as_hashref {
    my $self = shift;
    my $data;

    foreach my $key (keys %{$self}) {
        $data->{$key} = $self->{$key};
    }

    return $data;
}

## Return 1 if the Session object corresponds to an anonymous session.
sub is_anonymous {
    my $self = shift;
    if ($self->{'email'} eq 'nobody' || $self->{'email'} eq '') {
        return 1;
    } else {
        return 0;
    }
}

## Generate cookie from session ID.
sub encrypt_session_id {
    my $id_session = shift;

    my $cipher = Sympa::Tools::Password::ciphersaber_installed();
    unless ($cipher) {
        return "5e55$id_session";
    }
    return unpack 'H*', $cipher->encrypt(pack 'H*', $id_session);
}

## Get session ID from cookie.
sub decrypt_session_id {
    my $cookie = shift;

    return undef unless $cookie and $cookie =~ /\A(?:[0-9a-f]{2})+\z/;

    my $cipher = Sympa::Tools::Password::ciphersaber_installed();
    unless ($cipher) {
        return undef unless $cookie =~ s/\A5e55//;
        return $cookie;
    }
    return unpack 'H*', $cipher->decrypt(pack 'H*', $cookie);
}

## Generic subroutine to set a cookie
# DEPRECATED: No longer used.  Use CGI::Cookie::new().
# Old name: cookielib::generic_set_cookie()
#sub generic_set_cookie(
#    name=>NAME, value=>VALUE, expires=>EXPIRES, domain=>DOMAIN, path=>PATH);

# Sets an HTTP cookie to be sent to a SOAP client
# DEPRECATED: Use Sympa::Session::soap_cookie2().
#sub set_cookie_soap($session_id, $http_domain, $expire);

## returns Message Authentication Check code
# Old name: cookielib::get_mac(), Sympa::CookieLib::get_mac().
sub _get_mac {
    my $email  = shift;
    my $secret = shift;
    $log->syslog('debug3', '(%s, %s)', $email, $secret);

    unless ($secret) {
        $log->syslog('err',
            'Failure missing server secret for cookie MD5 digest');
        return undef;
    }
    unless ($email) {
        $log->syslog('err',
            'Failure missing email address or cookie MD5 digest');
        return undef;
    }

    my $md5 = Digest::MD5->new;

    $md5->reset;
    $md5->add($email . $secret);

    return substr(unpack("H*", $md5->digest), -8);

}

# Old name:
# cookielib::set_cookie_extern(), Sympa::CookieLib::set_cookie_extern().
sub set_cookie_extern {
    my ($secret, $http_domain, %alt_emails) = @_;
    my $cookie;
    my $value;

    my @mails;
    foreach my $mail (keys %alt_emails) {
        my $string = $mail . ':' . $alt_emails{$mail};
        push(@mails, $string);
    }
    my $emails = join(',', @mails);

    $value = sprintf '%s&%s', $emails, _get_mac($emails, $secret);

    if ($http_domain eq 'localhost') {
        $http_domain = "";
    }

    $cookie = CGI::Cookie->new(
        -name    => 'sympa_altemails',
        -value   => $value,
        -expires => '+1y',
        -domain  => $http_domain,
        -path    => '/'
    );
    ## Send cookie to the client
    printf "Set-Cookie: %s\n", $cookie->as_string;
    #$log->syslog('notice','%s',$cookie->as_string);
    return 1;
}

###############################
# Subroutines to read cookies #
###############################

## Generic subroutine to get a cookie value
# Old name:
# cookielib::generic_get_cookie(), Sympa::CookieLib::generic_get_cookie().
sub _generic_get_cookie {
    my $http_cookie = shift;
    my $cookie_name = shift;

    if ($http_cookie and $http_cookie =~ /\S+/g) {
        my %cookies = CGI::Cookie->parse($http_cookie);
        foreach my $cookie (values %cookies) {
            next unless $cookie->name eq $cookie_name;
            return ($cookie->value);
        }
    }
    return undef;
}

## Returns user information extracted from the cookie
# DEPRECATED: No longer used.
# Old name: cookielib::check_cookie().
#sub check_cookie(($http_cookie, $secret);

# Old name:
# cookielib::check_cookie_extern(), Sympa::CookieLib::check_cookie_extern().
sub check_cookie_extern {
    my ($http_cookie, $secret, $user_email) = @_;

    my $extern_value = _generic_get_cookie($http_cookie, 'sympa_altemails');

    if ($extern_value and $extern_value =~ /^(\S+)&(\w+)$/) {
        return undef unless (_get_mac($1, $secret) eq $2);

        my %alt_emails;
        foreach my $element (split(/,/, $1)) {
            my @array = split(/:/, $element);
            $alt_emails{$array[0]} = $array[1];
        }

        my $e = lc($user_email);
        unless ($alt_emails{$e}) {
            return undef;
        }
        return (\%alt_emails);
    }
    return undef;
}

# input user agent string and IP. return 1 if suspected to be a crawler.
# initial version based on rawlers_dtection.conf file only
# later : use Session table to identify those who create a lot of sessions
#FIXME: Robot context is ignored.
sub _is_a_crawler {
    my $robot = shift;

    my $ua = $ENV{'HTTP_USER_AGENT'};
    return undef unless defined $ua;
    return $Conf::Conf{'crawlers_detection'}{'user_agent_string'}{$ua};
}

1;
