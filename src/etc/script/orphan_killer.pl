#!/usr/bin/perl

# orphan_killer.pl - This script deletes entries in user_table
# for email adresses not in subscriber_table.
# This is no more usefull because Sympa does a better management
# of user_table
# RCS Identication ; $Revision$ ; $Date$ 
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

use lib '/home/sympa/bin';

use Conf;
## Change to your wwsympa.conf location

## Load sympa config
unless (&Conf::load('/etc/sympa.conf')) {
    print STDERR "Can't load config\n";
    exit (-1);
}


unless (require DBI) {
    print STDERR "enable to use DBI library, install DBI (CPAN) first";
    exit (-1);
}

$connect_string = sprintf 'DBI:%s:dbname=%s;host=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};

unless ( $dbh = DBI->connect($connect_string, $Conf{'db_user'}, $Conf{'db_passwd'}) ) {
    print STDERR 'Can\'t connect to Database %s as %s', $connect_string, $Conf{'db_user'};
    return undef;
}

if ($Conf{'db_type'} eq 'Pg') { # Configure Postgres to use ISO format dates
    $dbh->do ("SET DATESTYLE TO 'ISO';");
}

$sth = $dbh->prepare('SELECT email_user FROM user_table');

unless ($sth->execute) {
    print STDERR 'Unable to execute SQL statement : %s', $dbh->errstr;
    return undef;
}

print "Loading user list\n";
while ($user = $sth->fetchrow) {
    push @users, $user;
}

$total = $#users;

print "Searching orphans\n";
foreach $user (@users) {
    
    print "\n$total\t$user\t";

    $total--;

    my $statement = sprintf "SELECT COUNT(*) FROM subscriber_table WHERE user_subscriber = %s", $dbh->quote($user);
    
    $sth = $dbh->prepare($statement);
    
    unless ($sth->execute) {
	print STDERR 'Unable to execute SQL statement : %s', $dbh->errstr;
	next;
    }
    
    $count = $sth->fetchrow;
    
    if ($count == 0) {
	
	print '+';

	$statement = sprintf "DELETE FROM user_table WHERE email_user = %s", 
	$dbh->quote($user);

	unless ($dbh->do($statement)) {
	    print STDERR 'Unable to execute SQL statement : %s', $dbh->errstr;
	    next;
	}

    }else {
	print '.';
    }
}
