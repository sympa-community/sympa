#! --PERL--

use lib '--BINDIR--';
require 'wws-lib.pl';

use List;
use Log;

## Load sympa config
&Conf::load('--CONFIG--') || die 'config_error';

chdir $Conf::Conf{'home'};

&List::db_connect() || die "Can't connect to database";

my $dbh = &List::db_get_handler();

my $sth =  $dbh->prepare("SELECT user_subscriber, comment_subscriber FROM subscriber_table") || die "Can't prepare SQL statement";

$sth->execute || die "Unable to execute SQL statement";

my $user;

while ($user = $sth->fetchrow_hashref) {
    printf "\nUser: %s", $user->{'user_subscriber'};

    unless ($user->{'comment_subscriber'}) {
	my $statement = sprintf "SELECT gecos_user FROM user_table WHERE email_user=%s", $dbh->quote($user->{'user_subscriber'});
	my $sth2 =  $dbh->prepare($statement) || die "Can't prepare SQL statement";
	
	$sth2->execute || die "Unable to execute SQL statement";

	my $gecos = $sth2->fetchrow;
	$sth2->finish();
	
	if ($gecos) {
	    printf " =>%s", $gecos;
	    my $statement = sprintf "UPDATE subscriber_table SET comment_subscriber=%s WHERE (user_subscriber=%s)", $dbh->quote($gecos), $dbh->quote($user->{'user_subscriber'});
	    my $sth2 =  $dbh->prepare($statement) || die "Can't prepare SQL statement";
	    $sth2->execute || die "Unable to execute SQL statement";
	    $sth2->finish();
	}
	
    }
}

$sth->finish();

&List::db_disconnect();
