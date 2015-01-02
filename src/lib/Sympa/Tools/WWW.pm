# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

# hash of the icons linked with a type of file
# application file
my %icons = (
    'unknown'        => 'unknown.png',
    'folder'         => 'folder.png',
    'current_folder' => 'folder.open.png',
    'application'    => 'unknown.png',
    'octet-stream'   => 'binary.png',
    'audio'          => 'sound1.png',
    'image'          => 'image2.png',
    'text'           => 'text.png',
    'video'          => 'movie.png',
    'father'         => 'back.png',
    'sort'           => 'down.png',
    'url'            => 'link.png',
    'left'           => 'left.png',
    'right'          => 'right.png',
);

# lazy loading on demand
my %mime_types;

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
# Moved to _load_mime_types().
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

## Useful function to get off the slash at the end of the path
## at its end
sub no_slash_end {
    my $path = shift;

    ## supress ending '/'
    $path =~ s/\/+$//;

    return $path;
}

## return a visible path from a moderated file or not
sub make_visible_path {
    my $path = shift;

    my $visible_path = $path;

    if ($path =~ /\.url(\.moderate)?$/) {
        if ($path =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/) {
            $visible_path =~ s/\.moderate$//;
            $visible_path =~ s/^\.//;
            $visible_path =~ s/\.url$//;
        }

    } elsif ($path =~ /\.moderate$/) {
        if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
            my $name = $3;
            $name =~ s/^\.//;
            $name =~ s/\.moderate//;
            $visible_path = "$2" . "$name";
        }
    }

    ## Qdecode the visible path
    return tools::qdecode_filename($visible_path);
}

## returns a mailto according to list spam protection parameter
sub mailto {
    my $list  = shift;
    my $email = shift;
    my $gecos = shift;
    my $next_one;

    my $mailto = '';
    my @addresses;
    my %recipients;

    @addresses = split(',', $email);

    $gecos = $email unless ($gecos);
    $gecos =~ s/&/&amp;/g;
    $gecos =~ s/</&lt;/g;
    $gecos =~ s/>/&gt;/g;
    foreach my $address (@addresses) {

        ($recipients{$address}{'local'}, $recipients{$address}{'domain'}) =
            split('@', $address);
    }

    if ($list->{'admin'}{'spam_protection'} eq 'none') {
        $mailto .= "<a href=\"mailto:?";
        foreach my $address (@addresses) {
            $mailto .= "&amp;" if ($next_one);
            $mailto .= "to=$address";
            $next_one = 1;
        }
        $mailto .= "\">$gecos</a>";
    } elsif ($list->{'admin'}{'spam_protection'} eq 'javascript') {

        if ($gecos =~ /\@/) {
            $gecos =~ s/@/\" + \"@\" + \"/;
        }

        $mailto .= "<script type=\"text/javascript\">
 <!--
 document.write(\"<a href=\\\"\" + \"mail\" + \"to:?\" + ";
        foreach my $address (@addresses) {
            $mailto .= "\"\&amp\;\" + " if ($next_one);
            $mailto .=
                "\"to=\" + \"$recipients{$address}{'local'}\" + \"@\" + \"$recipients{$address}{'domain'}\" + ";
            $next_one = 1;
        }
        $mailto .= "\"\\\">$gecos<\" + \"/a>\")
 // --></script>";

    } elsif ($list->{'admin'}{'spam_protection'} eq 'at') {
        foreach my $address (@addresses) {
            $mailto .= " AND " if ($next_one);
            $mailto .=
                "$recipients{$address}{'local'} AT $recipients{$address}{'domain'}";
            $next_one = 1;
        }
    }
    return $mailto;

}

## return the mode of editing included in $action : 0, 0.5 or 1
sub find_edit_mode {
    my $action = shift;

    my $result;
    if ($action =~ /editor/i) {
        $result = 0.5;
    } elsif ($action =~ /do_it/i) {
        $result = 1;
    } else {
        $result = 0;
    }
    return $result;
}

## return the mode of editing : 0, 0.5 or 1 :
#  do the merging between 2 args of right access edit  : "0" > "0.5" > "1"
#  instead of a "and" between two booleans : the most restrictive right is
#  imposed
sub merge_edit {
    my $arg1 = shift;
    my $arg2 = shift;
    my $result;

    if ($arg1 == 0 || $arg2 == 0) {
        $result = 0;
    } elsif ($arg1 == 0.5 || $arg2 == 0.5) {
        $result = 0.5;
    } else {
        $result = 1;
    }
    return $result;
}

sub get_desc_file {
    my $file = shift;
    my $ligne;
    my %hash;

    open DESC_FILE, "$file";

    while ($ligne = <DESC_FILE>) {
        if ($ligne =~ /^title\s*$/) {
            #case title of the document
            while ($ligne = <DESC_FILE>) {
                last if ($ligne =~ /^\s*$/);
                $ligne =~ /^\s*(\S.*\S)\s*/;
                $hash{'title'} = $hash{'title'} . $1 . " ";
            }
        }

        if ($ligne =~ /^creation\s*$/) {
            #case creation of the document
            while ($ligne = <DESC_FILE>) {
                last if ($ligne =~ /^\s*$/);
                if ($ligne =~ /^\s*email\s*(\S*)\s*/) {
                    $hash{'email'} = $1;
                }
                if ($ligne =~ /^\s*date_epoch\s*(\d*)\s*/) {
                    $hash{'date'} = $1;
                }
            }
        }

        if ($ligne =~ /^access\s*$/) {
            #case access scenarios for the document
            while ($ligne = <DESC_FILE>) {
                last if ($ligne =~ /^\s*$/);
                if ($ligne =~ /^\s*read\s*(\S*)\s*/) {
                    $hash{'read'} = $1;
                }
                if ($ligne =~ /^\s*edit\s*(\S*)\s*/) {
                    $hash{'edit'} = $1;
                }
            }
        }
    }

    close DESC_FILE;

    return %hash;
}

## return a ref on an array of file (or subdirecties) to show to user
sub get_directory_content {
    my $tmpdir = shift;
    my $user   = shift;
    my $list   = shift;
    my $doc    = shift;

    # array of file not hidden
    my @dir = grep !/^\./, @$tmpdir;

    # array with documents not yet moderated
    my @moderate_dir = grep (/(\.moderate)$/, @$tmpdir);
    @moderate_dir = grep (!/^\.desc\./, @moderate_dir);

    # the editor can see file not yet moderated
    # a user can see file not yet moderated if he is th owner of these files
    if ($list->am_i('editor', $user)) {
        push(@dir, @moderate_dir);
    } else {
        my @privatedir = select_my_files($user, $doc, \@moderate_dir);
        push(@dir, @privatedir);
    }

    return \@dir;
}

## return an array that contains only file from @$refdir that belongs to $user
sub select_my_files {
    my ($user, $path, $refdir) = @_;
    my @new_dir;

    foreach my $d (@$refdir) {
        if (-e "$path/.desc.$d") {
            my %desc_hash = get_desc_file("$path/.desc.$d");
            if ($user eq $desc_hash{'email'}) {
                $new_dir[$#new_dir + 1] = $d;
            }
        }
    }
    return @new_dir;
}

sub get_icon {
    my $robot = shift || '*';
    my $type = shift;

    return undef unless defined $icons{$type};
    return
          Conf::get_robot_conf($robot, 'static_content_url')
        . '/icons.'
        . $icons{$type};
}

sub get_mime_type {
    my $type = shift;

    %mime_types = _load_mime_types() unless %mime_types;

    return $mime_types{$type};
}

sub _load_mime_types {
    my %types = ();

    my @localisation = (
        tools::search_fullpath('*', 'mime.types'),
        '/etc/mime.types', '/usr/local/apache/conf/mime.types',
        '/etc/httpd/conf/mime.types',
    );

    foreach my $loc (@localisation) {
        my $fh;
        next unless $loc and open $fh, '<', $loc;

        foreach my $line (<$fh>) {
            next if $line =~ /^\s*\#/;
            chomp $line;

            my ($k, $v) = split /\s+/, $line, 2;
            next unless $k and $v and $v =~ /\S/;

            my @extensions = split /\s+/, $v;
            # provides file extention, given the content-type
            if (@extensions) {
                $types{$k} = $extensions[0];
            }
            foreach my $ext (@extensions) {
                $types{$ext} = $k;
            }
        }

        close $fh;
        return %types;
    }

    return;
}

1;
