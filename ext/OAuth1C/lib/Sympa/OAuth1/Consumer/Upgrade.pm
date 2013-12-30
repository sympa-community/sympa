package Sympa::OAuth1::Consumer::Upgrade;
use strict;
use warnings;

use Sympa::Plugin::Util qw/:functions/;

=head1 NAME 

Sympa::OAuth1::Consumer::Upgrade - OAuth v1 plugin upgrade

=head1 SYNOPSIS

=head1 DESCRIPTION 

This module is invoked by L<Sympa::Plugin> when the module version of
L<Sympa::OAuth1> is newer than the version used in the previous run.

=head1 METHODS

=head2 Control

=head3 $class->upgrade(OPTIONS)

=over 4

=item * from =E<gt> VERSION

=item * to =E<gt> VERSION

=back

=cut

sub upgrade(%)
{   my ($self, %args) = @_;

    # no changes needed (yet)
    $args{to};
}


=head3 $class->setup(OPTIONS)

Options:

=over 4

=item * db =E<gt> DB, default_db

=back

=cut

my %create_tables;
sub setup(%)
{    my ($self, %args) = @_;

     my $db      = $args{db} || default_db;
     my $db_type = Site->db_type;

     $create_tables{$db_type}
         or fatal "unsupported database type $db_type for ".__PACKAGE__;

     $db->do($create_tables{$db_type});
}

%create_tables =
  ( mysql => <<'__CREATE_MYSQL'

CREATE TABLE oauthconsumer_sessions_table ( 
	 access_secret_oauthconsumer 	 varchar(100), 
	 access_token_oauthconsumer 	 varchar(100), 
	 provider_oauthconsumer 	 varchar(100), 
	 tmp_secret_oauthconsumer 	 varchar(100), 
	 tmp_token_oauthconsumer 	 varchar(100), 
	 user_oauthconsumer 		 varchar(100), 
	 PRIMARY KEY (provider_oauthconsumer, user_oauthconsumer) 
) DEFAULT CHARACTER SET utf8;

CREATE TABLE oauthprovider_nonces_table ( 
	 id_nonce 		 	int(11), 
	 id_oauthprovider 	 	int(11), 
	 nonce_oauthprovider 		 varchar(100), 
	 time_oauthprovider 		 int(11), 
	 PRIMARY KEY (id_nonce) 
) DEFAULT CHARACTER SET utf8;

CREATE TABLE oauthprovider_sessions_table ( 
	 accessgranted_oauthprovider 	 tinyint(1), 
	 callback_oauthprovider 	 varchar(100), 
	 consumer_oauthprovider 	 varchar(100), 
	 firsttime_oauthprovider 	 int(11), 
	 id_oauthprovider 		 int(11), 
	 isaccess_oauthprovider 	 tinyint(1), 
	 lasttime_oauthprovider 	 int(11), 
	 secret_oauthprovider 		 varchar(32), 
	 token_oauthprovider 		 varchar(32), 
	 user_oauthprovider 		 varchar(100), 
	 verifier_oauthprovider 	 varchar(32), 
	 PRIMARY KEY (id_oauthprovider) 
) DEFAULT CHARACTER SET utf8;

__CREATE_MYSQL

 , Oracle => <<'__CREATE_ORACLE'

CREATE TABLE oauthconsumer_sessions_table ( 
	 access_secret_oauthconsumer 	varchar2(100), 
	 access_token_oauthconsumer 	varchar2(100), 
	 provider_oauthconsumer 	varchar2(100), 
	 tmp_secret_oauthconsumer 	varchar2(100), 
	 tmp_token_oauthconsumer 	varchar2(100), 
	 user_oauthconsumer 		varchar2(100), 
	 CONSTRAINT ind_oauthconsumer_sessions
		PRIMARY KEY (provider_oauthconsumer, user_oauthconsumer) 
 );

CREATE TABLE oauthprovider_nonces_table ( 
	 id_nonce		 	number, 
	 id_oauthprovider	 	number, 
	 nonce_oauthprovider 		varchar2(100), 
	 time_oauthprovider	 	number, 
	 CONSTRAINT ind_oauthprovider_nonces
		 PRIMARY KEY (id_nonce) 
);

CREATE TABLE oauthprovider_sessions_table ( 
	 accessgranted_oauthprovider 	tinyint(1), 
	 callback_oauthprovider 	varchar2(100), 
	 consumer_oauthprovider 	varchar2(100), 
	 firsttime_oauthprovider 	number, 
	 id_oauthprovider 		number, 
	 isaccess_oauthprovider 	tinyint(1), 
	 lasttime_oauthprovider 	number, 
	 secret_oauthprovider 		varchar2(32), 
	 token_oauthprovider 		varchar2(32), 
	 user_oauthprovider 		varchar2(100), 
	 verifier_oauthprovider 	varchar2(32), 
	 CONSTRAINT ind_oauthprovider_sessions PRIMARY KEY (id_oauthprovider) 
 );

__CREATE_ORACLE

  , Pg => <<'__CREATE_PG'

CREATE TABLE oauthconsumer_sessions_table ( 
	 access_secret_oauthconsumer 	varchar(100), 
	 access_token_oauthconsumer 	varchar(100), 
	 provider_oauthconsumer 	varchar(100), 
	 tmp_secret_oauthconsumer 	varchar(100), 
	 tmp_token_oauthconsumer 	varchar(100), 
	 user_oauthconsumer 		varchar(100), 
	 CONSTRAINT ind_oauthconsumer_sessions
		 PRIMARY KEY (provider_oauthconsumer, user_oauthconsumer) 
 );

CREATE TABLE oauthprovider_nonces_table ( 
	 id_nonce 			int4, 
	 id_oauthprovider 		int4, 
	 nonce_oauthprovider 		varchar(100), 
	 time_oauthprovider 		int4, 
	 CONSTRAINT ind_oauthprovider_nonces
		 PRIMARY KEY (id_nonce) 
 );

CREATE TABLE oauthprovider_sessions_table ( 
	 accessgranted_oauthprovider 	int2, 
	 callback_oauthprovider 	varchar(100), 
	 consumer_oauthprovider 	varchar(100), 
	 firsttime_oauthprovider 	int4, 
	 id_oauthprovider 		int4, 
	 isaccess_oauthprovider 	int2, 
	 lasttime_oauthprovider 	int4, 
	 secret_oauthprovider 		varchar(32), 
	 token_oauthprovider 		varchar(32), 
	 user_oauthprovider 		varchar(100), 
	 verifier_oauthprovider 	varchar(32), 
	 CONSTRAINT ind_oauthprovider_sessions
		 PRIMARY KEY (id_oauthprovider) 
 );

__CREATE_PG

  , SQLite => <<'__CREATE_SQLITE'

CREATE TABLE oauthconsumer_sessions_table ( 
	 access_secret_oauthconsumer 	text, 
	 access_token_oauthconsumer 	text, 
	 provider_oauthconsumer 	text, 
	 tmp_secret_oauthconsumer 	text, 
	 tmp_token_oauthconsumer 	text, 
	 user_oauthconsumer 		text, 
	 PRIMARY KEY (provider_oauthconsumer, user_oauthconsumer) 
);

CREATE TABLE oauthprovider_nonces_table ( 
	 id_nonce 			integer, 
	 id_oauthprovider 		integer, 
	 nonce_oauthprovider	 	text, 
	 time_oauthprovider 		integer, 
	 PRIMARY KEY (id_nonce) 
);

CREATE TABLE oauthprovider_sessions_table ( 
	 accessgranted_oauthprovider 	integer, 
	 callback_oauthprovider 	text, 
	 consumer_oauthprovider 	text, 
	 firsttime_oauthprovider 	integer, 
	 id_oauthprovider 		integer, 
	 isaccess_oauthprovider 	integer, 
	 lasttime_oauthprovider 	integer, 
	 secret_oauthprovider 		text, 
	 token_oauthprovider	 	text, 
	 user_oauthprovider 		text, 
	 verifier_oauthprovider 	text, 
	 PRIMARY KEY (id_oauthprovider) 
);

__CREATE_SQLITE

  , Sybase => <<'__CREATE_SYBASE'

create table oauthconsumer_sessions_table 
( 
	 access_secret_oauthconsumer 	varchar(100), 
	 access_token_oauthconsumer 	varchar(100), 
	 provider_oauthconsumer 	varchar(100), 
	 tmp_secret_oauthconsumer 	varchar(100), 
	 tmp_token_oauthconsumer 	varchar(100), 
	 user_oauthconsumer 		varchar(100), 
	 constraint ind_oauthconsumer_sessions
		PRIMARY KEY (provider_oauthconsumer, user_oauthconsumer)
)
go 


create table oauthprovider_nonces_table 
( 
	 id_nonce 			numeric, 
	 id_oauthprovider	 	numeric, 
	 nonce_oauthprovider 		varchar(100), 
	 time_oauthprovider 		numeric, 
	 constraint ind_oauthprovider_nonces
		PRIMARY KEY (id_nonce)
)
go 

create table oauthprovider_sessions_table 
( 
	 accessgranted_oauthprovider 	tinyint(1), 
	 callback_oauthprovider 	varchar(100), 
	 consumer_oauthprovider 	varchar(100), 
	 firsttime_oauthprovider 	numeric, 
	 id_oauthprovider 		numeric, 
	 isaccess_oauthprovider 	tinyint(1), 
	 lasttime_oauthprovider 	numeric, 
	 secret_oauthprovider	 	varchar(32), 
	 token_oauthprovider 		varchar(32), 
	 user_oauthprovider 		varchar(100), 
	 verifier_oauthprovider 	varchar(32), 
	 constraint ind_oauthprovider_sessions
		PRIMARY KEY (id_oauthprovider)
)
go 

__CREATE_SYBASE

  );

=head1 AUTHORS 

=over 4

=item * Mark Overmeer <mark AT overmeer.net >

=back 

=cut 

1;
