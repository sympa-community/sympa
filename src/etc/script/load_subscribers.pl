#!--PERL--

# load_subscribers.pl - This script loads a Sympa subscriber file in a Database
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

use lib '--DIR--/bin';

use DBI;
use Conf;

die "usage : $ARGV[-1] listname" unless ($#ARGV == 0);

$listname = $ARGV[0];

## Load sympa config
unless (&Conf::load('--CONFIG--')) {
    die 'config_error';
}

$expl_dir = $Conf{'home'};
$db_type = $Conf{'db_type'};
$db_name = $Conf{'db_name'};
$db_host = $Conf{'db_host'};
$db_user = $Conf{'db_user'};
$db_passwd = $Conf{'db_passwd'};

%date_func = ('Pg' => '\'epoch\'::datetime + \'%d sec\'',
	      'mysql' => 'FROM_UNIXTIME(%d)');

## Connect to Database
unless ($dbh = DBI->connect("DBI:$db_type:dbname=$db_name;host=$db_host", $db_user, $db_passwd)) {
    die "Can't connect to Database :", $DBI::errstr;
}

## Cleanup in tables
#$dbh->do("DELETE FROM user_table");
#$dbh->do("DELETE FROM subscriber_table");

unless (-d $expl_dir) {
    die "expl dir not found : $expl_dir";
}

unless ((-d "$expl_dir/$listname") and (-f "$expl_dir/$listname/subscribers") and (-r "$expl_dir/$listname/subscribers")) {
    die "Unable to read subscribers file";
}

print STDERR "####$listname####\n";

## Parse subscribers
open ABO, "$expl_dir/$listname/subscribers" or die;
my @old = ($*, $/);
$* = 1; $/ = '';

undef $cpt;

## Process the lines
while (<ABO>) {
    $cpt++;
    my($k, %user);
    
    $user{'email'} = $1 if (/^\s*email\s+(.+)\s*$/o);
    $user{'gecos'} = $1 if (/^\s*gecos\s+(.+)\s*$/o);
    $user{'date'} = $1 if (/^\s*date\s+(\d+)\s*$/o);
    $user{'reception'} = $1 if (/^\s*reception\s+(.+)\s*$/o);
    $user{'visibility'} = $1 if (/^\s*visibility\s+(.+)\s*$/o);
    $user{'email'} =~ tr/A-Z/a-z/;
    
    ## Insert User in Database
    $sql = sprintf "INSERT IGNORE INTO user_table (email_user,gecos_user) VALUES (%s,%s)"
	, $dbh->quote($user{'email'}),$dbh->quote($user{'gecos'});
    $dbh->do($sql);
    
    $date = sprintf "$date_func{$db_type}", $user{'date'};
    
    $sql = sprintf "INSERT IGNORE INTO subscriber_table (user_subscriber,list_subscriber,date_subscriber,comment_subscriber,reception_subscriber,visibility_subscriber) VALUES (%s, %s, %s, %s, %s, %s)"
	, $dbh->quote($user{'email'}), $dbh->quote($listname), 
	$date, $dbh->quote($user{'gecos'}), 
	$dbh->quote($user{'reception'}), $dbh->quote($user{'visibility'});
    
    $dbh->do($sql) or die "$sql : $DBI::errstr";
	
}
close ABO;
($*, $/) = @old;

print STDERR "$cpt\n";


## Disconnect
$dbh->disconnect;






