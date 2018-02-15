# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../src/lib";

use Test::More;

use Conf;
use Sympa::Tools::Password;

unless ($Data::Password::VERSION) {
    plan skip_all => 'Data::Password required';
} else {
    plan tests => 2;
}

$Conf::Conf{'password_validation'} = 'MINLEN=8,GROUPS=4';
isnt(Sympa::Tools::Password::password_validation('XXX'), undef, 'Bad');
is(Sympa::Tools::Password::password_validation('91#%cxCX'), undef, 'Good');

# ToDo: tmp_passwd()
# ToDo: ciphersaber_installed()
# ToDo: crypt_password()
# ToDo: decrypt_password()
