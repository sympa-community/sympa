#! --PERL--

# crypt_passwd.pl - This script crypts uncrypted passwords in DB
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

use lib '--modulesdir--';
use wwslib;

unless (require Crypt::CipherSaber) {
    die "Crypt::CipherSaber not installed ; cannot crypt passwords";
}

require tools;

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

while ($user = $sth->fetchrow_hashref('NAME_lc')) {
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
