# SQLSource.pm - This module includes SQL DB related functions
#<!-- RCS Identication ; $Revision$ --> 

#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package SQLSource;

use strict;

use Carp;
use Log;
use Conf;
use List;
use tools;
use tt2;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(%date_format);
our @EXPORT_OK = qw(connect query disconnect fetch create_db ping quote set_fetch_timeout);
our $AUTOLOAD;

our %date_format = (
		   'read' => {
		       'Pg' => 'date_part(\'epoch\',%s)',
		       'mysql' => 'UNIX_TIMESTAMP(%s)',
		       'Oracle' => '((to_number(to_char(%s,\'J\')) - to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) * 86400) +to_number(to_char(%s,\'SSSSS\'))',
		       'Sybase' => 'datediff(second, \'01/01/1970\',%s)',
		       'SQLite' => 'strftime(\'%%s\',%s,\'utc\')'
		       },
		   'write' => {
		       'Pg' => '\'epoch\'::timestamp with time zone + \'%d sec\'',
		       'mysql' => 'FROM_UNIXTIME(%d)',
		       'Oracle' => 'to_date(to_char(round(%s/86400) + to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) || \':\' ||to_char(mod(%s,86400)), \'J:SSSSS\')',
		       'Sybase' => 'dateadd(second,%s,\'01/01/1970\')',
		       'SQLite' => 'datetime(%d,\'unixepoch\',\'localtime\')'
		       }
	       );

## Structure to keep track of active connections/connection status
## Key : connect_string (includes server+port+dbname+DB type)
## Values : dbh,status,first_try
## "status" can have value 'failed'
## 'first_try' contains an epoch date
my %db_connections;

sub new {
    my $pkg = shift;
    my $param = shift;
    my $self = $param;
    &Log::do_log('debug','Creating new SQLSource object for RDBMS "%s"',$param->{'db_type'});
    ## Casting the object with the right DBManipulator<RDBMS> class according to
    ## the parameters. It's repetitive code because it is hard to use variables
    ## with "require" pragma and @ISA decalarations. Later, maybe...
    if ($param->{'db_type'} =~ /^mysql$/i) {
	unless ( eval "require DBManipulatorMySQL" ){
	    &Log::do_log('err',"Unable to use DBManipulatorMySQL module");
	    return undef;
	}
	require DBManipulatorMySQL;
	our @ISA = qw(DBManipulatorMySQL);
    }elsif ($param->{'db_type'} =~ /^sqlite$/i) {
	unless ( eval "require DBManipulatorSQLite" ){
	    &Log::do_log('err',"Unable to use DBManipulatorSQLite module");
	    return undef;
	}
	require DBManipulatorSQLite;
	our @ISA = qw(DBManipulatorSQLite);
    }elsif ($param->{'db_type'} =~ /^pg$/i) {
	unless ( eval "require DBManipulatorPostgres" ){
	    &Log::do_log('err',"Unable to use DBManipulatorPostgres module");
	    return undef;
	}
	require DBManipulatorPostgres;
	our @ISA = qw(DBManipulatorPostgres);
    }elsif ($param->{'db_type'} =~ /^oracle$/i) {
	unless ( eval "require DBManipulatorOracle" ){
	    &Log::do_log('err',"Unable to use DBManipulatorOracle module");
	    return undef;
	}
	require DBManipulatorOracle;
	our @ISA = qw(DBManipulatorOracle);
    }elsif ($param->{'db_type'} =~ /^sybase$/i) {
	unless ( eval "require DBManipulatorSybase" ){
	    &Log::do_log('err',"Unable to use DBManipulatorSybase module");
	    return undef;
	}
	require DBManipulatorSybase;
	our @ISA = qw(DBManipulatorSybase);
    }else {
	&Log::do_log('err','Unknown RDBMS type "%s"',$param->{'db_type'});
	return undef;
    }
    $self = $pkg->SUPER::new($param);
    
    $self->{'db_host'} ||= $self->{'host'};
    $self->{'db_user'} ||= $self->{'user'};
    $self->{'db_passwd'} ||= $self->{'passwd'};
    $self->{'db_options'} ||= $self->{'connect_options'};
    
    unless ( eval "require DBI" ){
	&Log::do_log('err',"Unable to use DBI library, install DBI (CPAN) first");
	return undef ;
    }
    require DBI;

    bless $self, $pkg;
    return $self;
}

############################################################
#  connect
############################################################
#  Connect to an SQL database.
#  
# IN : $options : ref to a hash. Options for the connection process.
#         currently accepts 'keep_trying' : wait and retry until
#         db connection is ok (boolean) ; 'warn' : warn
#         listmaster if connection fails (boolean)
# OUT : $dbh
#     | undef
#
##############################################################
sub connect {
    my $self = shift;
    my $options = shift;

    ## Do we have db_xxx required parameters
    foreach my $db_param ('db_type','db_name') {
	unless ($self->{$db_param}) {
	    do_log('info','Missing parameter %s for DBI connection', $db_param);
	    return undef;
	}
	## SQLite just need a db_name
	unless ($self->{'db_type'} eq 'SQLite') {
	    foreach my $db_param ('db_host','db_user') {
		unless ($self->{$db_param}) {
		    do_log('info','Missing parameter %s for DBI connection', $db_param);
		    return undef;
		}
	    }
	}
    }
    
    ## Check if DBD is installed
    unless (eval "require DBD::$self->{'db_type'}") {
	do_log('err',"No Database Driver installed for $self->{'db_type'} ; you should download and install DBD::$self->{'db_type'} from CPAN");
	&List::send_notify_to_listmaster('missing_dbd', $Conf::Conf{'domain'},{'db_type' => $self->{'db_type'}});
	return undef;
    }

    ## Build connect_string
    if ($self->{'f_dir'}) {
	$self->{'connect_string'} = "DBI:CSV:f_dir=$self->{'f_dir'}";
    }else {
	$self->build_connect_string();
    }
    if ($self->{'db_options'}) {
	$self->{'connect_string'} .= ';' . $self->{'db_options'};
    }
    if (defined $self->{'db_port'}) {
	$self->{'connect_string'} .= ';port=' . $self->{'db_port'};
    }
 
    ## First check if we have an active connection with this server
    if (defined $db_connections{$self->{'connect_string'}} && 
	defined $db_connections{$self->{'connect_string'}}{'dbh'} && 
	$db_connections{$self->{'connect_string'}}{'dbh'}->ping()) {
      
      &do_log('debug', "Use previous connection");
      $self->{'dbh'} = $db_connections{$self->{'connect_string'}}{'dbh'} if $self;
      return $db_connections{$self->{'connect_string'}}{'dbh'};

    }else {
      
      ## Set environment variables
      ## Used by Oracle (ORACLE_HOME)
      if ($self->{'db_env'}) {
	foreach my $env (split /;/,$self->{'db_env'}) {
	  my ($key, $value) = split /=/, $env;
	  $ENV{$key} = $value if ($key);
	}
      }
      
      my $dbh;
      unless ($dbh = DBI->connect($self->{'connect_string'}, $self->{'db_user'}, $self->{'db_passwd'})) {
    	
	## Notify listmaster if warn option was set
	## Unless the 'failed' status was set earlier
	if ($options->{'warn'}) {
	  unless (defined $db_connections{$self->{'connect_string'}} &&
		  $db_connections{$self->{'connect_string'}}{'status'} eq 'failed') { 

	    unless (&List::send_notify_to_listmaster('no_db', $Conf::Conf{'domain'},{})) {
	      &do_log('err',"Unable to send notify 'no_db' to listmaster");
	    }
	  }
	}
	
	if ($options->{'keep_trying'}) {
	  &do_log('err','Can\'t connect to Database %s as %s, still trying...', $self->{'connect_string'}, $self->{'db_user'});
	} else{
	  do_log('err','Can\'t connect to Database %s as %s', $self->{'connect_string'}, $self->{'db_user'});
	  $db_connections{$self->{'connect_string'}}{'status'} = 'failed';
	  $db_connections{$self->{'connect_string'}}{'first_try'} ||= time;
	  return undef;
	}
	
	## Loop until connect works
	my $sleep_delay = 60;
	while (1) {
	  sleep $sleep_delay;
	  $dbh = DBI->connect($self->{'connect_string'}, $self->{'db_user'}, $self->{'db_passwd'});
	  last if ($dbh && $dbh->ping());
	  $sleep_delay += 10;
	}
	
	if ($options->{'warn'}) {
	  do_log('notice','Connection to Database %s restored.', $self->{'connect_string'});
	  unless (&send_notify_to_listmaster('db_restored', $Conf::Conf{'domain'},{})) {
	    &do_log('notice',"Unable to send notify 'db_restored' to listmaster");
	  }
	}
	
      }
      
      if ($self->{'db_type'} eq 'Pg') { # Configure Postgres to use ISO format dates
	$dbh->do ("SET DATESTYLE TO 'ISO';");
      }
      
      ## Set client encoding to UTF8
      if ($self->{'db_type'} eq 'mysql' ||
	  $self->{'db_type'} eq 'Pg') {
	$dbh->do("SET NAMES 'utf8'");
      }elsif ($self->{'db_type'} eq 'oracle') { 
	$ENV{'NLS_LANG'} = 'UTF8';
      }elsif ($self->{'db_type'} eq 'Sybase') { 
	$ENV{'SYBASE_CHARSET'} = 'utf8';
      }
      
      ## added sybase support
      if ($self->{'db_type'} eq 'Sybase') { 
	my $dbname;
	$dbname="use $self->{'db_name'}";
        $dbh->do ($dbname);
      }
      
      ## Force field names to be lowercased
      ## This has has been added after some problems of field names upercased with Oracle
      $dbh->{'FetchHashKeyName'}='NAME_lc';

      if ($self->{'db_type'} eq 'SQLite') { # Configure to use sympa database
        $dbh->func( 'func_index', -1, sub { return index($_[0],$_[1]) }, 'create_function' );
	if(defined $self->{'db_timeout'}) { $dbh->func( $self->{'db_timeout'}, 'busy_timeout' ); } else { $dbh->func( 5000, 'busy_timeout' ); };
      }
      
      $self->{'dbh'} = $dbh if $self;
      $self->{'connect_string'} = $self->{'connect_string'} if $self;     
      $db_connections{$self->{'connect_string'}}{'dbh'} = $dbh;
      
      do_log('debug2','Connected to Database %s',$self->{'db_name'});
      return $dbh;
    }
}

sub query {
    my ($self, $sql_query) = @_;
    unless ($self->{'sth'} = $self->{'dbh'}->prepare($sql_query)) {
        do_log('err','Unable to prepare SQL query : %s', $self->{'dbh'}->errstr);
        return undef;
    }
    unless ($self->{'sth'}->execute) {
        do_log('err','Unable to perform SQL query %s : %s ',$sql_query, $self->{'dbh'}->errstr);
        return undef;
    }

}

sub fetch {
    my $self = shift;
	
    ## call to fetchrow_arrayref() uses eval to set a timeout
    ## this prevents one data source to make the process wait forever if SELECT does not respond
    my $array_of_users;
    $array_of_users = eval {
	local $SIG{ALRM} = sub { die "TIMEOUT\n" }; # NB: \n required
	alarm $self->{'fetch_timeout'}; 
	
	## Inner eval just in case the fetchall_arrayref call would die, thus leaving the alarm trigered
	my $status = eval {
	    return $self->{'sth'}->fetchall_arrayref;
	};
	alarm 0;
	return $status;
    };
    if ( $@ eq "TIMEOUT\n" ) {
	do_log('err','Fetch timeout on remote SQL database');
        return undef;
    }elsif ($@) {
	do_log('err','Fetch failed on remote SQL database');
    return undef;
    }

    return $array_of_users;
}

sub disconnect {
    my $self = shift;
    $self->{'sth'}->finish if $self->{'sth'};
    $self->{'dbh'}->disconnect;
    delete $db_connections{$self->{'connect_string'}};
}

## Try to create the database
sub create_db {
    &do_log('debug3', 'List::create_db()');    

    &do_log('notice','Trying to create %s database...', $Conf::Conf{'db_name'});

    unless ($Conf::Conf{'db_type'} eq 'mysql') {
	&do_log('err', 'Cannot create %s DB', $Conf::Conf{'db_type'});
	return undef;
    }

    my $drh;
    unless ($drh = DBI->connect("DBI:mysql:dbname=mysql;host=localhost", 'root', '')) {
	&do_log('err', 'Cannot connect as root to database');
	return undef;
    }

    ## Create DB
    my $rc = $drh->func("createdb", $Conf::Conf{'db_name'}, 'localhost', $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'}, 'admin');
    unless (defined $rc) {
	&do_log('err', 'Cannot create database %s : %s', $Conf::Conf{'db_name'}, $drh->errstr);
	return undef;
    }

    ## Re-connect to DB (to prevent "MySQL server has gone away" error)
    unless ($drh = DBI->connect("DBI:mysql:dbname=mysql;host=localhost", 'root', '')) {
	&do_log('err', 'Cannot connect as root to database');
	return undef;
    }

    ## Grant privileges
    unless ($drh->do("GRANT ALL ON $Conf::Conf{'db_name'}.* TO '$Conf::Conf{'db_user'}'\@localhost IDENTIFIED BY '$Conf::Conf{'db_passwd'}'")) {
	&do_log('err', 'Cannot grant privileges to %s on database %s : %s', $Conf::Conf{'db_user'}, $Conf::Conf{'db_name'}, $drh->errstr);
	return undef;
    }

    &do_log('notice', 'Database %s created', $Conf::Conf{'db_name'});

    ## Reload MysqlD to take changes into account
    $rc = $drh->func("reload", $Conf::Conf{'db_name'}, 'localhost', $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'}, 'admin');
    unless (defined $rc) {
	&do_log('err', 'Cannot reload mysqld : %s', $drh->errstr);
	return undef;
    }

    $drh->disconnect();

    return 1;
}

sub ping {
    my $self = shift;
    return $self->{'dbh'}->ping; 
}

sub quote {
    my ($self, $string, $datatype) = @_;
    
    return $self->{'dbh'}->quote($string, $datatype); 
}

sub set_fetch_timeout {
    my ($self, $timeout) = @_;

    return $self->{'fetch_timeout'} = $timeout;
}

sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ /(.*):(.*)/;
    &do_log('err',"Function %s was not found in module %s",$2,$1);
    return undef;
}

sub DESTROY {} ## Here to prevent AUTOLOAD calling when destroying the object.

## Packages must return true.
1;
