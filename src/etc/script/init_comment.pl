#! --PERL--

use lib '--BINDIR--';
require 'wws-lib.pl';

$sympa_conf_file = '--CONFIG--';

use List;
use Log;


## Load sympa config
unless (&Conf::load($sympa_conf_file)) {
    die 'config_error';
}

chdir $Conf::Conf{'home'};

&List::db_connect() || die "Can't connect to database";

my $sth =  $dbh->prepare("SELECT user_subscriber, comment_subscriber FROM subscriber_table");

$sth = $dbh->prepare($statement) || die "Can't prepare SQL statement";

$sth->execute || die "Unable to execute SQL statement";

my $user;

while ($user = $sth->fetchrow_hashref) {
    printf "User: %s\n", $user->{'user_subscriber'};
}

&List::db_disconnect();
