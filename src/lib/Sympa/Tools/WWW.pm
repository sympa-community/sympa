# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Sympa::Tools::WWW;

use strict;
use warnings;

use Conf;
use Sympa::Constants;
use Log;

## Cookie expiration periods with corresponding entry in NLS
our %cookie_period = (
    0     => {'gettext_id' => "session"},
    10    => {'gettext_id' => "10 minutes"},
    30    => {'gettext_id' => "30 minutes"},
    60    => {'gettext_id' => "1 hour"},
    360   => {'gettext_id' => "6 hours"},
    1440  => {'gettext_id' => "1 day"},
    10800 => {'gettext_id' => "1 week"},
    43200 => {'gettext_id' => "30 days"}
);

## Filenames with corresponding entry in NLS set 15
our %filenames = (
    'welcome.tt2'       => {'gettext_id' => "welcome message"},
    'bye.tt2'           => {'gettext_id' => "unsubscribe message"},
    'removed.tt2'       => {'gettext_id' => "deletion message"},
    'message.footer'    => {'gettext_id' => "message footer"},
    'message.header'    => {'gettext_id' => "message header"},
    'remind.tt2'        => {'gettext_id' => "remind message"},
    'reject.tt2'        => {'gettext_id' => "editor rejection message"},
    'invite.tt2'        => {'gettext_id' => "subscribing invitation message"},
    'helpfile.tt2'      => {'gettext_id' => "help file"},
    'lists.tt2'         => {'gettext_id' => "directory of lists"},
    'global_remind.tt2' => {'gettext_id' => "global remind message"},
    'summary.tt2'       => {'gettext_id' => "summary message"},
    'info'              => {'gettext_id' => "list description"},
    'homepage'          => {'gettext_id' => "list homepage"},
    'create_list_request.tt2' =>
        {'gettext_id' => "list creation request message"},
    'list_created.tt2' =>
        {'gettext_id' => "list creation notification message"},
    'your_infected_msg.tt2' => {'gettext_id' => "virus infection message"},
    'list_aliases.tt2'      => {'gettext_id' => "list aliases template"}
);

## Defined in RFC 1893
our %bounce_status = (
    '1.0' => 'Other address status',
    '1.1' => 'Bad destination mailbox address',
    '1.2' => 'Bad destination system address',
    '1.3' => 'Bad destination mailbox address syntax',
    '1.4' => 'Destination mailbox address ambiguous',
    '1.5' => 'Destination mailbox address valid',
    '1.6' => 'Mailbox has moved',
    '1.7' => 'Bad sender\'s mailbox address syntax',
    '1.8' => 'Bad sender\'s system address',
    '2.0' => 'Other or undefined mailbox status',
    '2.1' => 'Mailbox disabled, not accepting messages',
    '2.2' => 'Mailbox full',
    '2.3' => 'Message length exceeds administrative limit',
    '2.4' => 'Mailing list expansion problem',
    '3.0' => 'Other or undefined mail system status',
    '3.1' => 'Mail system full',
    '3.2' => 'System not accepting network messages',
    '3.3' => 'System not capable of selected features',
    '3.4' => 'Message too big for system',
    '4.0' => 'Other or undefined network or routing status',
    '4.1' => 'No answer from host',
    '4.2' => 'Bad connection',
    '4.3' => 'Routing server failure',
    '4.4' => 'Unable to route',
    '4.5' => 'Network congestion',
    '4.6' => 'Routing loop detected',
    '4.7' => 'Delivery time expired',
    '5.0' => 'Other or undefined protocol status',
    '5.1' => 'Invalid command',
    '5.2' => 'Syntax error',
    '5.3' => 'Too many recipients',
    '5.4' => 'Invalid command arguments',
    '5.5' => 'Wrong protocol version',
    '6.0' => 'Other or undefined media error',
    '6.1' => 'Media not supported',
    '6.2' => 'Conversion required and prohibited',
    '6.3' => 'Conversion required but not supported',
    '6.4' => 'Conversion with loss performed',
    '6.5' => 'Conversion failed',
    '7.0' => 'Other or undefined security status',
    '7.1' => 'Delivery not authorized, message refused',
    '7.2' => 'Mailing list expansion prohibited',
    '7.3' => 'Security conversion required but not possible',
    '7.4' => 'Security features not supported',
    '7.5' => 'Cryptographic failure',
    '7.6' => 'Cryptographic algorithm not supported',
    '7.7' => 'Message integrity failure'
);

## Load WWSympa configuration file
##sub load_config
## MOVED: use Conf::_load_wwsconf().

## Load HTTPD MIME Types
# DUPLICATE: Use tools::load_mime_types().
#sub load_mime_types();

## Returns user information extracted from the cookie
# Deprecated.  Use Sympa::Session->new etc.
#sub get_email_from_cookie;

sub new_passwd {

    my $passwd;
    my $nbchar = int(rand 5) + 6;
    foreach my $i (0 .. $nbchar) {
        $passwd .= chr(int(rand 26) + ord('a'));
    }

    return 'init' . $passwd;
}

## Basic check of an email address
# DUPLICATE: Use tools::valid_email().
#sub valid_email($email);

# 6.2b: added $robot parameter.
sub init_passwd {
    my ($robot, $email, $data) = @_;

    my ($passwd, $user);

    if (Sympa::User::is_global_user($email)) {
        $user = Sympa::User::get_global_user($email);

        $passwd = $user->{'password'};

        unless ($passwd) {
            $passwd = new_passwd();

            unless (
                Sympa::User::update_global_user(
                    $email, {'password' => $passwd}
                )
                ) {
                Sympa::Report::reject_report_web('intern',
                    'update_user_db_failed', {'user' => $email},
                    '', '', $email, $robot);
                Log::do_log('info', 'Update failed');
                return undef;
            }
        }
    } else {
        $passwd = new_passwd();
        unless (
            Sympa::User::add_global_user(
                {   'email'    => $email,
                    'password' => $passwd,
                    'lang'     => $data->{'lang'},
                    'gecos'    => $data->{'gecos'}
                }
            )
            ) {
            Sympa::Report::reject_report_web('intern', 'add_user_db_failed',
                {'user' => $email},
                '', '', $email, $robot);
            Log::do_log('info', 'Add failed');
            return undef;
        }
    }

    return 1;
}

sub get_my_url {

    my $return_url;

    ## Mod_ssl sets SSL_PROTOCOL ; apache-ssl sets SSL_PROTOCOL_VERSION
    if ($ENV{'HTTPS'} eq 'on') {
        $return_url = 'https';
    } else {
        $return_url = 'http';
    }

    $return_url .= '://' . &main::get_header_field('HTTP_HOST');
    $return_url .= ':' . $ENV{'SERVER_PORT'}
        unless (($ENV{'SERVER_PORT'} eq '80')
        || ($ENV{'SERVER_PORT'} eq '443'));
    $return_url .= $ENV{'REQUEST_URI'};
    return ($return_url);
}

# Uploade source file to the destination on the server
sub upload_file_to_server {
    my $param = shift;
    Log::do_log(
        'debug',
        "Uploading file from field %s to destination %s",
        $param->{'file_field'},
        $param->{'destination'}
    );
    my $fh;
    unless ($fh = $param->{'query'}->upload($param->{'file_field'})) {
        Log::do_log(
            'debug',
            'Cannot upload file from field %s',
            $param->{'file_field'}
        );
        return undef;
    }

    unless (open FILE, ">:bytes", $param->{'destination'}) {
        Log::do_log(
            'debug',
            'Cannot open file %s: %m',
            $param->{'destination'}
        );
        return undef;
    }
    while (<$fh>) {
        print FILE;
    }
    close FILE;
    return 1;
}

1;
