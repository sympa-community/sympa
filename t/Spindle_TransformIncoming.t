# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use Test::More;

use Conf;
use Sympa::ConfDef;
use Sympa::List;
use Sympa::Message;
use Sympa::Spindle::TransformIncoming;

do {
    no warnings;
    *Sympa::List::update_stats = sub { (1) };
};

%Conf::Conf = (
    domain     => 'mail.example.org',    # mandatory
    listmaster => 'jade@example.com',    # mandatory
);
# Apply defaults.
foreach my $pinfo (grep { $_->{name} and exists $_->{default} }
    @Sympa::ConfDef::params) {
    $Conf::Conf{$pinfo->{name}} = $pinfo->{default}
        unless exists $Conf::Conf{$pinfo->{name}};
}

my $list = bless {
    name   => 'list',
    domain => $Conf::Conf{'domain'},
    admin  => {custom_subject => '[%list.name%]:[%list.sequence%]',},
} => 'Sympa::List';

my $spindle = Sympa::Spindle::TransformIncoming->new(
    context     => $list,
    splicing_to => 'Sympa::Spindle',
);

my $message;

# custom_subject and subject prefixes

$message = Sympa::Message->new("Subject: Re: Re: Test\n\n", context => $list);
$spindle->{distaff} = Sympa::Spool::Mock->new(message => $message);
$spindle->spin;
is $message->as_string, "Subject: Re: [list:1] Test\n\n", 'Re: Re:';

$message = Sympa::Message->new("Subject: Re:[list:979] Re: Test\n\n",
    context => $list);
$spindle->{distaff} = Sympa::Spool::Mock->new(message => $message);
$spindle->spin;
is $message->as_string, "Subject: Re: [list:1] Test\n\n", 'Re:[tag] Re:';

$message = Sympa::Message->new(<<'EOF', context => $list);
Subject: =?UTF-8?B?U1Y6IEFudHc6IFZTOiBSRUYgOiBSRTogUkVbMl06IEFXOiDOkc6gOiA=?=
 =?UTF-8?B?zpHPgDogzqPOp86VzqQ6IM6jz4fOtc+EOiDQndCwOiDQvdCwOiBWw6E6IFI6IFJJ?=
 =?UTF-8?B?RjogQXRiLjogUkVTOiBPZHA6IFludDogQVRCOiDlm57lpI06IOWbnuimhu+8mlZT?=
 =?UTF-8?Q?=3a_Fwd=3a_Re=3a_Something?=

EOF
$spindle->{distaff} = Sympa::Spool::Mock->new(message => $message);
$spindle->spin;
is $message->as_string, "Subject: SV: [list:1] Fwd: Re: Something\n\n",
    'Multilingual "Re:"';

done_testing;

package Sympa::Spool::Mock;
use parent qw(Sympa::Spool);

use constant _generator       => 'Sympa::Message';
use constant _directories     => {};
use constant _no_glob_pattern => 1;
use constant remove           => 1;

sub next {
    my $self = shift;

    return unless $self->{message};
    return (delete $self->{message}, 1);
}

1;

