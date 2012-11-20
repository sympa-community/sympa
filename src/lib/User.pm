
package User;

use strict;
use warnings;
use Carp qw(carp croak);

#use Site; # this module is used in Site

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

User - All Users Identified by Sympa

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new ( EMAIL, [ KEY => VAL, ... ] )

Create new User object.

=back

=cut

sub new {
    my $pkg    = shift;
    my $who    = tools::clean_email(shift || '');
    my %values = @_;
    my $self;
    return undef unless $who;

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
    my $self = shift;
    my $newemail = tools::clean_email(shift || '');

    unless ($newemail) {
	&Log::do_log('err', 'No email');
	return undef;
    }
    if ($self->email eq $newemail) {
	return 0;
    }

    push @sth_stack, $sth;

    unless (
	$sth = do_prepared_query(
	    q{UPDATE user_table
	      SET email_user = ?
	      WHERE email_user = ?},
	    $newemail, $self->email
	) and
	$sth->rows
	) {
	&Log::do_log('err', 'Can\'t move user %s to %s', $self, $newemail);
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
    unless (add_global_user('email' => $self->email, %$self) or
	update_global_user($self->email, %$self)) {
	&Log::do_log('err', 'Cannot save user %s', $self);
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

sub DESTROY;

sub AUTOLOAD {
    $AUTOLOAD =~ m/^(.*)::(.*)/;

    my $attr = $2;

    if (scalar grep { $_ eq $attr } qw(email)) {
	## getter for user attribute.
	no strict "refs";
	*{$AUTOLOAD} = sub {
	    my $self = shift;
	    croak "Can't call method \"$attr\" on uninitialized " .
		ref($self) . " object"
		unless $self->{'email'};
	    croak "Can't modify \"$attr\" attribute"
		if scalar @_ > 1;
	    $self->{$attr};
	};
    } elsif (exists $map_field{$attr}) {
	## getter/setter for user attributes.
	no strict "refs";
	*{$AUTOLOAD} = sub {
	    my $self = shift;
	    croak "Can't call method \"$attr\" on uninitialized " .
		ref($self) . " object"
		unless $self->{'email'};
	    $self->{$attr} = shift
		if scalar @_ > 1;
	    $self->{$attr};
	};
    } else {
	croak "Can't locate object method \"$2\" via package \"$1\"";
    }
    goto &$AUTOLOAD;
}

=head2 FUNCTIONS

=over 4

=item get_users ( ... )

=back

=cut

sub get_users {
    croak();
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

=item update_global_user

=back

=cut

## Delete a user in the user_table
sub delete_global_user {
    my @users = @_;

    &Log::do_log('debug2', '');

    return undef unless ($#users >= 0);

    foreach my $who (@users) {
	$who = &tools::clean_email($who);
	## Update field

	unless (
	    &SDM::do_prepared_query(
		q{DELETE FROM user_table WHERE email_user = ?}, $who
	    )
	    ) {
	    &Log::do_log('err', 'Unable to delete user %s', $who);
	    next;
	}
    }

    return $#users + 1;
}

## Returns a hash for a given user
sub get_global_user {
    &Log::do_log('debug2', '(%s)', @_);
    my $who = &tools::clean_email(shift);

    ## Additional subscriber fields
    my $additional = '';
    if (Site->db_additional_user_fields) {
	$additional = ', ' . Site->db_additional_user_fields;
    }

    push @sth_stack, $sth;

    unless (
	$sth = &SDM::do_prepared_query(
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
	&Log::do_log('err', 'Failed to prepare SQL query');
	$sth = pop @sth_stack;
	return undef;
    }

    my $user = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish();

    $sth = pop @sth_stack;

    if (defined $user) {
	## decrypt password
	if ($user->{'password'}) {
	    $user->{'password'} =
		&tools::decrypt_password($user->{'password'});
	}

	## Turn user_attributes into a hash
	my $attributes = $user->{'attributes'};
	if (defined $attributes and length $attributes) {
	    $user->{'attributes'} ||= {};
	    foreach my $attr (split(/\;/, $attributes)) {
		my ($key, $value) = split(/\=/, $attr);
		$user->{'attributes'}{$key} = $value;
	    }
	    delete $user->{'attributes'}
		unless scalar keys %{$user->{'attributes'}};
	} else {
	    delete $user->{'attributes'};
	}
	## Turn data_user into a hash
	if ($user->{'data'}) {
	    my %prefs = &tools::string_2_hash($user->{'data'});
	    $user->{'prefs'} = \%prefs;
	}
    }

    return $user;
}

## Returns an array of all users in User table hash for a given user
sub get_all_global_user {
    &Log::do_log('debug2', '()');

    my @users;

    push @sth_stack, $sth;

    unless ($sth =
	&SDM::do_prepared_query('SELECT email_user FROM user_table')) {
	&Log::do_log('err', 'Unable to gather all users in DB');
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
    my $who = &tools::clean_email(pop);
    &Log::do_log('debug3', '(%s)', $who);

    return undef unless ($who);

    push @sth_stack, $sth;

    ## Query the Database
    unless (
	$sth = &SDM::do_prepared_query(
	    q{SELECT count(*) FROM user_table WHERE email_user = ?}, $who
	)
	) {
	&Log::do_log('err',
	    'Unable to check whether user %s is in the user table.');
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
    &Log::do_log('debug', '(%s, ...)', @_);
    my $who    = shift;
    my $values = $_[0];
    if (ref $values) {
	$values = {%$values};
    } else {
	$values = {@_};
    }

    $who = &tools::clean_email($who);

    ## use md5 fingerprint to store password
    $values->{'password'} = &Auth::password_fingerprint($values->{'password'})
	if ($values->{'password'});

    my ($field, $value);

    my ($user, $statement, $table);

    ## Update each table
    my @set_list;

    while (($field, $value) = each %{$values}) {
	unless ($map_field{$field}) {
	    &Log::do_log('error',
		"unkown field $field in map_field internal error");
	    next;
	}
	my $set;

	if ($numeric_field{$map_field{$field}}) {
	    $value ||= 0;    ## Can't have a null value
	    $set = sprintf '%s=%s', $map_field{$field}, $value;
	} else {
	    $set = sprintf '%s=%s', $map_field{$field}, &SDM::quote($value);
	}
	push @set_list, $set;
    }

    return undef unless @set_list;

    ## Update field

    push @sth_stack, $sth;

    $sth = &SDM::do_query(
	"UPDATE user_table SET %s WHERE (email_user=%s)",
	join(',', @set_list),
	&SDM::quote($who)
    );
    unless (defined $sth) {
	&Log::do_log('err',
	    'Could not update informations for user %s in user_table', $who);
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

## Adds a user to the user_table
sub add_global_user {
    &Log::do_log('debug3', '(...)');
    my $values = $_[0];
    if (ref $values) {
	$values = {%$values};
    } else {
	$values = {@_};
    }

    my ($field, $value);
    my ($user, $statement, $table);

    ## encrypt password
    $values->{'password'} = &Auth::password_fingerprint($values->{'password'})
	if ($values->{'password'});

    return undef unless (my $who = &tools::clean_email($values->{'email'}));
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
	    $insert = sprintf "%s", &SDM::quote($value);
	}
	push @insert_value, $insert;
	push @insert_field, $map_field{$field};
    }

    unless (@insert_field) {
	&Log::do_log(
	    'err',
	    'The fields (%s) do not correspond to anything in the database',
	    join(',', keys(%{$values}))
	);
	return undef;
    }

    push @sth_stack, $sth;

    ## Update field
    $sth = &SDM::do_query(
	"INSERT INTO user_table (%s) VALUES (%s)",
	join(',', @insert_field),
	join(',', @insert_value)
    );
    unless (defined $sth) {
	&Log::do_log('err',
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

=head2 Miscelaneous

=over 4

=item clean_user ( USER_OR_HASH )

=item clean_users ( ARRAYREF_OF_USERS_OR_HASHES )

I<Function>.
Warn if the argument is not a User object.
Return User object, if any.

I<TENTATIVE>.
These functions will be used during transition between old and object-oriented
styles.  At last modifications have been done, they shall be removed.

=back

=cut

sub clean_user {
    my $user = shift;

    unless (ref $user eq 'User') {
	my $level = $Carp::CarpLevel;
	$Carp::CarpLevel = 1;
	carp "Deprecated usage: user should be a User object";
	$Carp::CarpLevel = $level;

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
	unless (ref $user eq 'User') {
	    unless ($warned) {
		my $level = $Carp::CarpLevel;
		$Carp::CarpLevel = 1;
		carp "Deprecated usage: user should be a User object";
		$Carp::CarpLevel = $level;

		$warned = 1;
	    }
	    if (ref $user eq 'HASH') {
		$user = bless $user => __PACKAGE__;
	    } else {
		$user = undef;
	    }
	}
    }
    $users;
}

###### END of the User package ######

## Packages must return true.
1;
