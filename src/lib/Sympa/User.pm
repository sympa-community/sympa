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

package Sympa::User;

use strict;
use warnings;
use Carp qw();
use Digest::MD5;
BEGIN { eval 'use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64)'; }

use Conf;
use Sympa::DatabaseDescription;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::Data;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

## Database and SQL statement handlers
my ($sth, @sth_stack);

## mapping between var and field names
my %db_struct = Sympa::DatabaseDescription::full_db_struct();
my %map_field;
foreach my $k (keys %{$db_struct{'user_table'}->{'fields'}}) {
    if ($k =~ /^(.+)_user$/) {
        $map_field{$1} = $k;
    }
}

## DB fields with numeric type
## We should not do quote() for these while inserting data
my %numeric_field;
foreach my $k (keys %{$db_struct{'user_table'}->{'fields'}}) {
    if ($db_struct{'user_table'}->{'fields'}{$k}{'struct'} =~ /^int/) {
        $numeric_field{$k} = 1;
    }
}

=encoding utf-8

=head1 NAME

Sympa::User - All Users Identified by Sympa

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new ( EMAIL, [ KEY => VAL, ... ] )

Create new Sympa::User object.

=back

=cut

sub new {
    my $pkg    = shift;
    my $who    = Sympa::Tools::Text::canonic_email(shift);
    my %values = @_;
    my $self;
    return undef unless defined $who;

    ## Canonicalize lang if possible
    $values{'lang'} = Sympa::Language::canonic_lang($values{'lang'})
        || $values{'lang'}
        if $values{'lang'};

    if (!($self = get_global_user($who))) {
        ## unauthenticated user would not be added to database.
        $values{'email'} = $who;
        if (scalar grep { $_ ne 'lang' and $_ ne 'email' } keys %values) {
            unless (defined add_global_user(\%values)) {
                return undef;
            }
        }
        $self = \%values;
    }

    bless $self => $pkg;
}

=head2 METHODS

=over 4

=item expire

Remove user information from user_table.

=back

=cut

sub expire {
    delete_global_user(shift->email);
}

=over 4

=item get_id

Get unique identifier of object.

=back

=cut

sub get_id {
    ## DO NOT use accessors since $self may not have been fully initialized.
    shift->{'email'} || '';
}

=over 4

=item moveto

Change email of user.

=back

=cut

sub moveto {
    my $self     = shift;
    my $newemail = Sympa::Tools::Text::canonic_email(shift);

    unless (defined $newemail) {
        $log->syslog('err', 'No email');
        return undef;
    }
    if ($self->email eq $newemail) {
        return 0;
    }

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{UPDATE user_table
              SET email_user = ?
              WHERE email_user = ?},
            $newemail, $self->email
        )
    ) {
        $log->syslog('err', 'Can\'t move user %s to %s', $self, $newemail);
        $sth = pop @sth_stack;
        return undef;
    }

    $sth = pop @sth_stack;

    $self->{'email'} = $newemail;

    return 1;
}

=over 4

=item save

Save user information to user_table.

=back

=cut

sub save {
    my $self = shift;
    unless (add_global_user('email' => $self->email, %$self)
        or update_global_user($self->email, %$self)) {
        $log->syslog('err', 'Cannot save user %s', $self);
        return undef;
    }

    return 1;
}

=head3 ACCESSORS

=over 4

=item E<lt>attributeE<gt>

=item E<lt>attributeE<gt>C<( VALUE )>

I<Getters/Setters>.
Get or set user attributes.
For example C<$user-E<gt>gecos> returns "gecos" parameter of the user,
and C<$user-E<gt>gecos("foo")> also changes it.
Basic user profile "email" have only getter,
so it is read-only.

=back

=cut

our $AUTOLOAD;

sub DESTROY { }   # "sub DESTROY;" may cause segfault with Perl around 5.10.1.

sub AUTOLOAD {
    $AUTOLOAD =~ m/^(.*)::(.*)/;

    my $attr = $2;

    if (scalar grep { $_ eq $attr } qw(email)) {
        ## getter for user attribute.
        no strict "refs";
        *{$AUTOLOAD} = sub {
            my $self = shift;
            Carp::croak "Can't call method \"$attr\" on uninitialized "
                . ref($self)
                . " object"
                unless $self->{'email'};
            Carp::croak "Can't modify \"$attr\" attribute"
                if scalar @_ > 1;
            $self->{$attr};
        };
    } elsif (exists $map_field{$attr}) {
        ## getter/setter for user attributes.
        no strict "refs";
        *{$AUTOLOAD} = sub {
            my $self = shift;
            Carp::croak "Can't call method \"$attr\" on uninitialized "
                . ref($self)
                . " object"
                unless $self->{'email'};
            $self->{$attr} = shift
                if scalar @_ > 1;
            $self->{$attr};
        };
    } else {
        Carp::croak "Can't locate object method \"$2\" via package \"$1\"";
    }
    goto &$AUTOLOAD;
}

=head2 FUNCTIONS

=over 4

=item get_users ( ... )

Not yet implemented.

=back

=cut

sub get_users {
    die;
}

=over 4

=item password_fingerprint ( )

Returns the password finger print.

=back

=cut

# Old name: Sympa::Auth::password_fingerprint().
#
# Password fingerprint functions are stored in a table. Currently supported
# algorithms are the default 'md5', and 'bcrypt'.
#
# If the algorithm uses a salt (e.g. bcrypt) and the second parameter $salt
# is not provided, a random one will be generated.
#

my %fingerprint_hashes = (
    # default is to use MD5, which does not use a salt
    'md5' => sub {
        my ($pwd, $salt) = @_;

        $salt = '' unless defined $salt;

        # salt parameter is not used for MD5 hashes
        my $fingerprint = Digest::MD5::md5_hex($pwd);
        my $match = ($fingerprint eq $salt) ? "yes" : "no";

        $log->syslog('debug', 'md5: match %s salt \"%s\" fingerprint %s',
            $match, $salt, $fingerprint);

        return $fingerprint;
    },
    # bcrypt uses a salt and has a configurable "cost" parameter
    'bcrypt' => sub {
        my ($pwd, $salt) = @_;

        die "bcrypt support unavailable: install Crypt::Eksblowfish::Bcrypt"
            unless $Crypt::Eksblowfish::Bcrypt::VERSION;

        # A bcrypt-encrypted password contains the settings at the front.
        # If this not look like a settings string, create one.
        unless (defined($salt)
            && $salt =~ m#\A\$2(a?)\$([0-9]{2})\$([./A-Za-z0-9]{22})#x) {
            my $bcrypt_cost = Conf::get_robot_conf('*', 'bcrypt_cost');
            my $cost = sprintf("%02d", 0 + $bcrypt_cost);
            my $newsalt = "";

            for my $i (0 .. 15) {
                $newsalt .= chr(rand(256));
            }
            $newsalt = '$2a$' . $cost . '$' . en_base64($newsalt);
            $log->syslog('debug',
                "bcrypt: create new salt: cost $cost \"$newsalt\"");

            $salt = $newsalt;
        }

        my $fingerprint = bcrypt($pwd, $salt);
        my $match = ($fingerprint eq $salt) ? "yes" : "no";

        $log->syslog('debug', 'bcrypt: match %s salt \"%s\" fingerprint %s',
            $match, $salt, $fingerprint);

        return $fingerprint;
    }
);

sub password_fingerprint {

    my ($pwd, $salt) = @_;

    $log->syslog('debug', "salt \"%s\"", $salt);

    my $password_hash = Conf::get_robot_conf('*', 'password_hash');
    my $password_hash_update =
        Conf::get_robot_conf('*', 'password_hash_update');

    if (Conf::get_robot_conf('*', 'password_case') eq 'insensitive') {
        $pwd = lc($pwd);
    }

    # If updating hashes, honor the hash type implied by $salt. This lets
    # the user successfully log in, after which the hash can be updated

    if ($password_hash_update) {
        if (defined($salt) && defined(my $hash_type = hash_type($salt))) {
            $log->syslog('debug', "honoring  hash_type %s", $hash_type);
            $password_hash = $hash_type;
        }
    }

    die "password_fingerprint: unknown password_hash \"$password_hash\""
        unless defined($fingerprint_hashes{$password_hash});

    return $fingerprint_hashes{$password_hash}->($pwd, $salt);
}

=over 4

=item hash_type ( )

detect the type of password fingerprint used for a hashed password

Returns undef if no supported hash type is detected

=back

=cut

sub hash_type {
    my $hash = shift;

    return 'md5' if ($hash =~ /^[a-f0-9]{32}$/i);
    return 'bcrypt'
        if ($hash =~ m#\A\$2(a?)\$([0-9]{2})\$([./A-Za-z0-9]{22})#);
    return undef;
}

=over 4

=item update_password_hash ( )

If needed, update the hash used for the user's encrypted password entry

=back

=cut

sub update_password_hash {
    my ($user, $pwd) = @_;

    return unless (Conf::get_robot_conf('*', 'password_hash_update'));

    # here if configured to check and update the password hash algorithm

    my $user_hash = hash_type($user->{'password'});
    my $system_hash = Conf::get_robot_conf('*', 'password_hash');

    return if (defined($user_hash) && ($user_hash eq $system_hash));

    # note that we directly use the callback for the hash type
    # instead of using any other logic to determine which to call

    $log->syslog('debug', 'update password hash for %s from %s to %s',
        $user->{'email'}, $user_hash, $system_hash);

    # note that we use the cleartext password here, not the hash
    update_global_user($user->{'email'}, {password => $pwd});

}

############################################################################
## Old-style functions
############################################################################

=head2 OLD STYLE FUNCTIONS

=over 4

=item add_global_user

=item delete_global_user

=item is_global_user

=item get_global_user

=item get_all_global_user

I<Obsoleted>.

=item update_global_user

=back

=cut

## Delete a user in the user_table
sub delete_global_user {
    my @users = @_;

    $log->syslog('debug2', '');

    return undef unless @users;

    my $sdm = Sympa::DatabaseManager->instance;
    foreach my $who (@users) {
        $who = Sympa::Tools::Text::canonic_email($who);

        # Update field
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{DELETE FROM user_table WHERE email_user = ?}, $who
            )
        ) {
            $log->syslog('err', 'Unable to delete user %s', $who);
            next;
        }
    }

    return scalar @users;
}

## Returns a hash for a given user
sub get_global_user {
    $log->syslog('debug2', '(%s)', @_);
    my $who = Sympa::Tools::Text::canonic_email(shift);

    ## Additional subscriber fields
    my $additional = '';
    if ($Conf::Conf{'db_additional_user_fields'}) {
        $additional = ', ' . $Conf::Conf{'db_additional_user_fields'};
    }

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            sprintf(
                q{SELECT email_user AS email, gecos_user AS gecos,
                         password_user AS password,
                         cookie_delay_user AS cookie_delay, lang_user AS lang,
                         attributes_user AS attributes, data_user AS data,
                         last_login_date_user AS last_login_date,
                         wrong_login_count_user AS wrong_login_count,
                         last_login_host_user AS last_login_host%s
                  FROM user_table
                  WHERE email_user = ?},
                $additional
            ),
            $who
        )
    ) {
        $log->syslog('err', 'Failed to prepare SQL query');
        $sth = pop @sth_stack;
        return undef;
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish();

    $sth = pop @sth_stack;

    if (defined $user) {
        # Canonicalize lang if possible.
        if ($user->{'lang'}) {
            $user->{'lang'} = Sympa::Language::canonic_lang($user->{'lang'})
                || $user->{'lang'};
        }

        ## Turn user_attributes into a hash
        my $attributes = $user->{'attributes'};
        if (defined $attributes and length $attributes) {
            $user->{'attributes'} = {};
            foreach my $attr (split(/__ATT_SEP__/, $attributes)) {
                my ($key, $value) = split(/__PAIRS_SEP__/, $attr);
                $user->{'attributes'}{$key} = $value;
            }
            delete $user->{'attributes'}
                unless scalar keys %{$user->{'attributes'}};
        } else {
            delete $user->{'attributes'};
        }
        ## Turn data_user into a hash
        if ($user->{'data'}) {
            my %prefs = Sympa::Tools::Data::string_2_hash($user->{'data'});
            $user->{'prefs'} = \%prefs;
        }
    }

    return $user;
}

## Returns an array of all users in User table hash for a given user
# OBSOLETED: No longer used.
sub get_all_global_user {
    $log->syslog('debug2', '');

    my @users;

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    unless ($sdm
        and $sth =
        $sdm->do_prepared_query('SELECT email_user FROM user_table')) {
        $log->syslog('err', 'Unable to gather all users in DB');
        $sth = pop @sth_stack;
        return undef;
    }

    while (my $email = ($sth->fetchrow_array)[0]) {
        push @users, $email;
    }
    $sth->finish();

    $sth = pop @sth_stack;

    return @users;
}

## Is the person in user table (db only)
sub is_global_user {
    my $who = Sympa::Tools::Text::canonic_email(pop);
    $log->syslog('debug3', '(%s)', $who);

    return undef unless defined $who;

    push @sth_stack, $sth;
    my $sdm = Sympa::DatabaseManager->instance;

    ## Query the Database
    unless (
        $sdm
        and $sth = $sdm->do_prepared_query(
            q{SELECT COUNT(*) FROM user_table WHERE email_user = ?}, $who
        )
    ) {
        $log->syslog('err',
            'Unable to check whether user %s is in the user table');
        $sth = pop @sth_stack;
        return undef;
    }

    my $is_user = $sth->fetchrow();
    $sth->finish();

    $sth = pop @sth_stack;

    return $is_user;
}

## Sets new values for the given user in the Database
sub update_global_user {
    $log->syslog('debug', '(%s, ...)', @_);
    my $who    = shift;
    my $values = $_[0];
    if (ref $values) {
        $values = {%$values};
    } else {
        $values = {@_};
    }

    $who = Sympa::Tools::Text::canonic_email($who);

    ## use hash fingerprint to store password
    ## hashes that use salts will randomly generate one
    ## avoid rehashing passwords that are already hash strings
    if ($values->{'password'}) {
        if (defined(hash_type($values->{'password'}))) {
            $log->syslog(
                'debug',
                'password is in %s format, not rehashing',
                hash_type($values->{'password'})
            );
        } else {
            $values->{'password'} =
                Sympa::User::password_fingerprint($values->{'password'},
                undef);
        }
    }

    ## Canonicalize lang if possible.
    $values->{'lang'} = Sympa::Language::canonic_lang($values->{'lang'})
        || $values->{'lang'}
        if $values->{'lang'};

    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm) {
        $log->syslog('err', 'Unavailable database connection');
        return undef;
    }

    my ($field, $value);

    ## Update each table
    my @set_list;

    while (($field, $value) = each %{$values}) {
        unless ($map_field{$field}) {
            $log->syslog('err',
                'Unknown field %s in map_field internal error', $field);
            next;
        }
        my $set;

        if ($numeric_field{$map_field{$field}}) {
            $value ||= 0;    ## Can't have a null value
            $set = sprintf '%s=%s', $map_field{$field}, $value;
        } elsif ($field eq 'data' and ref $value eq 'HASH') {
            $set = sprintf '%s=%s', $map_field{$field},
                $sdm->quote(Sympa::Tools::Data::hash_2_string($value));
        } elsif ($field eq 'attributes' and ref $value eq 'HASH') {
            $set = sprintf '%s=%s', $map_field{$field},
                $sdm->quote(
                join '__ATT_SEP__',
                map { sprintf '%s__PAIRS_SEP__%s', $_, $value->{$_} }
                    sort keys %$value
                );
        } else {
            $set = sprintf '%s=%s', $map_field{$field}, $sdm->quote($value);
        }
        push @set_list, $set;
    }

    return undef unless @set_list;

    ## Update field

    push @sth_stack, $sth;

    $sth = $sdm->do_query(
        "UPDATE user_table SET %s WHERE (email_user=%s)",
        join(',', @set_list),
        $sdm->quote($who)
    );
    unless (defined $sth) {
        $log->syslog('err',
            'Could not update information for user %s in user_table', $who);
        $sth = pop @sth_stack;
        return undef;
    }

    $sth = pop @sth_stack;

    return 1;
}

## Adds a user to the user_table
sub add_global_user {
    $log->syslog('debug3', '(...)');
    my $values = $_[0];
    if (ref $values) {
        $values = {%$values};
    } else {
        $values = {@_};
    }

    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm) {
        $log->syslog('err', 'Unavailable database connection');
        return undef;
    }

    my ($field, $value);

    ## encrypt password with the configured password hash algorithm
    ## an salt of 'undef' means generate a new random one
    ## avoid rehashing passwords that are already hash strings
    if ($values->{'password'}) {
        if (defined(hash_type($values->{'password'}))) {
            $log->syslog(
                'debug',
                'password is in %s format, not rehashing',
                hash_type($values->{'password'})
            );
        } else {
            $values->{'password'} =
                Sympa::User::password_fingerprint($values->{'password'},
                undef);
        }
    }

    ## Canonicalize lang if possible
    $values->{'lang'} = Sympa::Language::canonic_lang($values->{'lang'})
        || $values->{'lang'}
        if $values->{'lang'};

    my $who = Sympa::Tools::Text::canonic_email($values->{'email'});
    return undef unless defined $who;
    return undef if (is_global_user($who));

    ## Update each table
    my (@insert_field, @insert_value);
    while (($field, $value) = each %{$values}) {

        next unless ($map_field{$field});

        my $insert;
        if ($numeric_field{$map_field{$field}}) {
            $value ||= 0;    ## Can't have a null value
            $insert = $value;
        } else {
            $insert = $sdm->quote($value);
        }
        push @insert_value, $insert;
        push @insert_field, $map_field{$field};
    }

    unless (@insert_field) {
        $log->syslog(
            'err',
            'The fields (%s) do not correspond to anything in the database',
            join(',', keys(%{$values}))
        );
        return undef;
    }

    push @sth_stack, $sth;

    ## Update field
    $sth = $sdm->do_query(
        "INSERT INTO user_table (%s) VALUES (%s)",
        join(',', @insert_field),
        join(',', @insert_value)
    );
    unless (defined $sth) {
        $log->syslog('err',
            'Unable to add user %s to the DB table user_table',
            $values->{'email'});
        $sth = pop @sth_stack;
        return undef;
    }
    unless ($sth->rows) {
        $sth = pop @sth_stack;
        return 0;
    }

    $sth = pop @sth_stack;

    return 1;
}

=head2 Miscellaneous

=over 4

=item clean_user ( USER_OR_HASH )

=item clean_users ( ARRAYREF_OF_USERS_OR_HASHES )

I<Function>.
Warn if the argument is not a Sympa::User object.
Return Sympa::User object, if any.

I<TENTATIVE>.
These functions will be used during transition between old and object-oriented
styles.  At last modifications have been done, they shall be removed.

=back

=cut

sub clean_user {
    my $user = shift;

    unless (ref $user eq 'Sympa::User') {
        local $Carp::CarpLevel = 1;
        Carp::carp("Deprecated usage: user should be a Sympa::User object");

        if (ref $user eq 'HASH') {
            $user = bless $user => __PACKAGE__;
        } else {
            $user = undef;
        }
    }
    $user;
}

sub clean_users {
    my $users = shift;
    return $users unless ref $users eq 'ARRAY';

    my $warned = 0;
    foreach my $user (@$users) {
        unless (ref $user eq 'Sympa::User') {
            unless ($warned) {
                local $Carp::CarpLevel = 1;
                Carp::carp(
                    "Deprecated usage: user should be a Sympa::User object");

                $warned = 1;
            }
            if (ref $user eq 'HASH') {
                $user = bless $user => __PACKAGE__;
            } else {
                $user = undef;
            }
        }
    }
    return $users;
}

1;
