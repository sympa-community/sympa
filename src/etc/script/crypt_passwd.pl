#! --PERL--

## Crypt uncrypted passwords in database

use lib '--BINDIR--';
use wwslib;

unless (require Crypt::CipherSaber) {
    die "Crypt::CipherSaber not installed ; cannot crypt passwords";
}

require 'tools.pl';

use List;
use Log;

## Load sympa config
&Conf::load('--CONFIG--') || die 'config_error';

chdir $Conf::Conf{'home'};

&List::db_connect() || die "Can't connect to database";

my $dbh = &List::db_get_handler();

print "Searching uncrypted passwords\n";

my $sth =  $dbh->prepare("SELECT email_user, password_user FROM user_table WHERE (password_user not like 'crypt.%')") || die "Can't prepare SQL statement";

$sth->execute || die "Unable to execute SQL statement";

my $user;

my $count = 0;

while ($user = $sth->fetchrow_hashref) {
    next unless $user->{'password_user'};

    printf "\n%s", $user->{'email_user'};

    my $crypted_password = &tools::crypt_password($user->{'password_user'});

    printf " => %s", $crypted_password;

    my $statement = sprintf "UPDATE user_table SET password_user=%s WHERE (email_user=%s)", $dbh->quote($crypted_password), $dbh->quote($user->{'email_user'});
    my $sth2 =  $dbh->prepare($statement) || die "Can't prepare SQL statement";
    $sth2->execute || die "Unable to execute SQL statement";
    $sth2->finish();

    $count++;
}

$sth->finish();

&List::db_disconnect();

printf "Crypted %d passwords\n", $count;
