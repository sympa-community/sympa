# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

use Sympa::Log;
use Sympa::Message;

%Conf::Conf = (sender_headers => 'From',);

Sympa::Log->instance->{log_to_stderr} = 'err';

# ToDo: smime_encrypt()

# ToDo: smime_decrypt()

# ToDo: smime_sign()

# ToDo: check_smime_signature()

# is_signed()
is test_is_signed('t/samples/unsigned.eml'), 0, 'never signed';
is test_is_signed('t/samples/signed.eml'),   1, 'multipart/signed S/MIME';
#is test_is_signed('t/samples/signed-pkcs7.eml'), 1, 'PKCS#7 S/MIME';
#is test_is_signed('t/samples/signed-pgp.eml'), 0, 'multipart/signed PGP/MIME';
#is test_is_signed('t/samples/signed-pgp-inline.eml'), 0, 'PGP inline';

done_testing();

sub test_is_signed {
    my $path = shift;

    open my $fh, '<', $path or die $ERRNO;
    my $str = do { local $RS; <$fh> };
    close $fh;
    my $message = Sympa::Message->new($str, context => '*');

    return $message->is_signed;
}

