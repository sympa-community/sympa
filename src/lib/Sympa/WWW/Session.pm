# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::WWW::Session;

use strict;
use warnings;
use CGI::Cookie;
use Digest::MD5;

use Conf;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::Data;
use Sympa::Tools::Password;

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
            # Start a Sympa::WWW::Session->new(may be a fake cookie).
            $log->syslog('info', 'Ignoring unknown session cookie "%s"',
                $cookie);
            return (Sympa::WWW::Session->new($robot));
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
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self   = shift;
    my $cookie = shift;

    my $sdm = Sympa::DatabaseManager->instance;
    my $sth;

    my $session_id = _cookie2id($cookie);
    unless ($session_id) {
        $log->syslog('info', 'Undefined session ID in cookie "%s"', $cookie);
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
            $session_id,
            $session_id
        )
    ) {
        $log->syslog('err', 'Unable to load session %s', $session_id);
        return undef;
    }

    my $session = $sth->fetchrow_hashref('NAME_lc');
    return 'not_found' unless $session;
    if ($sth->fetchrow_hashref('NAME_lc')) {
        $log->syslog('err',
            'The SQL statement did return more than one session');
        $session->{'email'} = '';    #FIXME
    }
    $sth->finish;

    my @keys;

    my %datas = Sympa::Tools::Data::string_2_hash($session->{'data'});
    @keys = keys %datas;
    @{$self}{@keys} = @datas{@keys};
    # Canonicalize lang if possible.
    $self->{lang} =
        Sympa::Language::canonic_lang($self->{lang}) || $self->{lang}
        if $self->{lang};

    @keys = qw(id_session prev_id date refresh_date start_date hit
        remote_addr email);
    @{$self}{@keys} = @{$session}{@keys};
    # Update hit count.
    $self->{hit}++;

    return $self;
}

# Get correct session ID from sympa_session cookie value.
sub _cookie2id {
    my $cookie = shift;

    return undef unless $cookie;
    return $1 if $cookie =~ /\A5e55([0-9]{14,16})\z/;    #  Compat. < 6.2.42
    return $cookie if $cookie =~ /\A[0-9]{14,16}\z/;
    return undef;
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

# Deprecated. Use purge_session_table() in task_manager.pl.
#sub purge_old_sessions;

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
    return Sympa::WWW::Session::_generic_get_cookie($http_cookie,
        'sympa_session');
}

## Generic subroutine to set a cookie
## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec)
## domain=(localhost|<a domain>)
sub set_cookie {
    $log->syslog('debug', '(%s, %s, %s, %s)', @_);
    my $self    = shift;
    my $dom     = shift;
    my $expires = shift;
    my $use_ssl = shift;

    $expires = $Conf::Conf{'cookie_expire'} unless defined $expires;

    my $expiration;
    if ($expires eq '0' or $expires eq 'session') {
        $expiration = '';
    } elsif ($expires =~ /now/i) {    #FIXME: Perhaps never used.
        ## 10 years ago
        $expiration = '-10y';
    } else {
        $expiration = '+' . $expires . 'm';
    }

    my $cookie = CGI::Cookie->new(
        -name     => 'sympa_session',
        -domain   => (($dom eq 'localhost') ? '' : $dom),
        -path     => '/',
        -secure   => $use_ssl,
        -httponly => 1,
        -value    => $self->{id_session},
        ($expiration ? (-expires => $expiration) : ()),
    );

    # Send cookie to the client.
    printf "Set-Cookie: %s\n", $cookie->as_string;
}

# Build an HTTP cookie value to be sent to a SOAP client
sub soap_cookie2 {
    my ($session_id, $http_domain, $expire) = @_;
    my $cookie;

    ## With set-cookie2 max-age of 0 means removing the cookie
    ## Maximum cookie lifetime is the session
    $expire ||= 600;    ## 10 minutes

    if ($http_domain eq 'localhost') {
        $cookie = CGI::Cookie->new(
            -name  => 'sympa_session',
            -value => $session_id,
            -path  => '/',
        );
        $cookie->max_age(time + $expire);    # needs CGI >= 3.51.
    } else {
        $cookie = CGI::Cookie->new(
            -name   => 'sympa_session',
            -value  => $session_id,
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
# No longer used.
#sub encrypt_session_id;

## Get session ID from cookie.
# No longer used
#sub decrypt_session_id;

## Generic subroutine to set a cookie
# DEPRECATED: No longer used.  Use CGI::Cookie::new().
# Old name: cookielib::generic_set_cookie()
#sub generic_set_cookie(
#    name=>NAME, value=>VALUE, expires=>EXPIRES, domain=>DOMAIN, path=>PATH);

# Sets an HTTP cookie to be sent to a SOAP client
# DEPRECATED: Use Sympa::WWW::Session::soap_cookie2().
#sub set_cookie_soap($session_id, $http_domain, $expire);

## returns Message Authentication Check code
# Old name: cookielib::get_mac(), Sympa::CookieLib::get_mac().
# DEPRECATED: No longer used.
#sub _get_mac;

# Old name:
# cookielib::set_cookie_extern(), Sympa::CookieLib::set_cookie_extern().
# DEPRECATED: No longer used.
#sub set_cookie_extern;

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
# DEPRECATED: No longer used.
#sub check_cookie_extern;

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

sub confirm_action {
    my $self     = shift;
    my $action   = shift;
    my $response = shift || '';
    my %opts     = @_;

    if ($response eq 'init') {
        # Check if action in session matches current action.
        unless ($self->{confirm_action}
            and $self->{confirm_action} eq $action) {
            delete @{$self}{qw(confirm_action confirm_id previous_action)};
        }
        return;
    }

    my $id = Digest::MD5::md5_hex($opts{arg} || '');
    my $default_home = Conf::get_robot_conf($self->{robot}, 'default_home');
    unless ($response
        and $self->{confirm_action}
        and $self->{confirm_action} eq $action
        and $self->{confirm_id}
        and $self->{confirm_id} eq $id) {
        # Not yet confirmed / dismissed: Save parameters in session.
        @{$self}{qw(confirm_action confirm_id previous_action)} =
            ($action, $id, ($opts{previous_action} || $default_home));
        return 'confirm_action';
    } elsif ($response eq 'confirm') {
        # Action is confirmed: Clear parameters in session.
        delete @{$self}{qw(confirm_action confirm_id previous_action)};
        return 1;
    } else {
        # Action is dismissed: Clear parameters in session then returns name
        # of previous action.
        my $previous_action = $self->{previous_action} || $default_home;
        delete @{$self}{qw(confirm_action confirm_id previous_action)};
        return $previous_action;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::WWW::Session - Web session

=head1 SYNOPSIS

  use Sympa::WWW::Session;
  
  my $session = Sympa::WWW::Session->new($robot,
      {cookie => Sympa::WWW::Session::get_session_cookie($ENV{'HTTP_COOKIE'})}
  );
  $session->renew();
  $session->store();

=head2 Confirmation

  $session->confirm_action($action, 'init');
  
  sub do_myaction {
  
      # Validate arguments...
  
      $param->{arg} = $arg;
      my $next_action = $session->confirm_action($action, $response,
          $arg, $previous_action);
      return $next_action unless $next_action eq '1';
  
      # Process action...
  
  }

=head1 DESCRIPTION

L<Sympa::WWW::Session> provides web session for Sympa web interface.
HTTP cookie is required to determine users.
Session store is used to keep users' personal data.

=head2 Methods

=over

=item new ( $robot, { [ cookie =E<gt> $cookie ], ... } )

I<Constructor>.
Creates new instance and loads user data from session store.

Parameters:

=over

=item $robot

Context of the session.

=item { cookie =E<gt> $cookie }

HTTP cookie.

=back

Returns:

A new instance.

=item as_hashref ( )

I<Instance method>.
Casts the instance to hashref.

Parameters:

None.

Returns:

A hashref including attributes of instance (see L</Attributes>).

=item confirm_action ( $action, $response, [ arg =E<gt> $arg, ]
[ previous_action =E<gt> $previous_action ] )

I<Instance method>.
Check if action has been confirmed.

Confirmation follows two steps:

=over

=item 1.

The method is called with no (undefined) response.
The action, hash of argument and previous_action are stored into
session store.
And then this method returns C<'confirm_action'>.

=item 2.

The method is called with C<'confirm'> or other true value as response.
I<If> action and hash of argument match with those in session store, and:

=over

=item *

If C<'confirm'> is given, returns C<1>.

=item *

If other true value is given, returns previous action stored in
session store (previous_action given in argument is ignored).

=back

In both cases session store is cleared.

=back

Anytime when the action submitted by user is determined,
This method may be called with response as C<'init'>.
In this case, if action doesn't match with that in session store,
session store will be cleared.

Parameters:

=over

=item $action

Action to be checked.

=item $response

Response from user:
C<'init'>, false value (not yet checked), C<'confirm'> and others (cancelled).
This may typically be given by user using C<response_action> parameter.

=item arg =E<gt> $arg

Argument(s) of action.

=item previous_action => $previous_action

The action users will be redirected when action is confirmed.
This may typically given by user using C<previous_action> parameter.

=back

=item is_anonymous ( )

I<Instance method>.
TBD.

=item renew ( )

I<Instance method>.
Renews the session.
Updates internal session ID and HTTP cookie.

=item store ( )

I<Instance method>.
Stores session into session store.

=back

=head2 Functions

=over

=item check_cookie_extern ( )

I<Function>.
Deprecated.

=item decrypt_session_id ( )

I<Function>.
Deprecated.

=item encrypt_session_id ( )

I<Function>.
Deprecated.

=item list_sessions ( )

I<Function>.
TBD.

=item purge_old_sessions ( )

I<Function>.
Deprecated.

=item set_cookie ( $cookie_domain, $expires, [ $use_ssl ] )

I<Instance method>.
TBD.

=item set_cookie_extern ( $cookie_domain, [ $use_ssl ] )

I<Instance method>.
Deprecated.

=back

=head2 Attributes

TBD.

=head1 SEE ALSO

L<Sympa::DatabaseManager>.

=head1 HISTORY

L<SympaSession> appeared on Sympa 5.4a3.

It was renamed to L<Sympa::Session> on Sympa 6.2a.41,
then L<Sympa::WWW::Session> on Sympa 6.2.26.

L</"confirm_action"> method was added on Sympa 6.2.17.

=cut

