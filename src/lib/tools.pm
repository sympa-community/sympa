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

package tools;

use strict;
use warnings;
#use Cwd qw();
use Digest::MD5;
use Encode qw();
use Encode::MIME::Header;    # for 'MIME-Q' encoding
use English qw(-no_match_vars);
use HTML::StripScripts::Parser;
use MIME::EncWords;
use POSIX qw();
use Scalar::Util qw();
use Sys::Hostname qw();
use Time::HiRes qw();

use Sympa::Alarm;
use Sympa::Auth;
use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::List;
use Sympa::ListDef;
use Sympa::LockedFile;
use Log;
use Sympa::Mail;
use Sympa::Message;
use Sympa::Regexps;
use Sympa::Tools::Data;
use Sympa::Tools::File;

my $separator =
    "------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------";

## Returns an HTML::StripScripts::Parser object built with  the parameters
## provided as arguments.
sub _create_xss_parser {
    my %parameters = @_;
    my $robot      = $parameters{'robot'};
    Log::do_log('debug3', '(%s)', $robot);

    my $http_host_re = Conf::get_robot_conf($robot, 'http_host');
    $http_host_re =~ s/([^\s\w\x80-\xFF])/\\$1/g;
    my $hss = HTML::StripScripts::Parser->new(
        {   Context  => 'Document',
            AllowSrc => 1,
            Rules    => {'*' => {src => qr{^http://$http_host_re},},},
        }
    );
    return $hss;
}

## Returns sanitized version (using StripScripts) of the string provided as
## argument.
sub sanitize_html {
    my %parameters = @_;
    my $robot      = $parameters{'robot'};
    Log::do_log('debug3', '(string=%s, robot=%s)',
        $parameters{'string'}, $robot);

    unless (defined $parameters{'string'}) {
        Log::do_log('err', 'No string provided');
        return undef;
    }

    my $hss = _create_xss_parser('robot' => $robot);
    unless (defined $hss) {
        Log::do_log('err', 'Can\'t create StripScript parser');
        return undef;
    }
    my $string = $hss->filter_html($parameters{'string'});
    return $string;
}

## Returns sanitized version (using StripScripts) of the content of the file
## whose path is provided as argument.
sub sanitize_html_file {
    my %parameters = @_;
    my $robot      = $parameters{'robot'};
    Log::do_log('debug3', '(file=%s, robot=%s)', $parameters{'file'}, $robot);

    unless (defined $parameters{'file'}) {
        Log::do_log('err', 'No path to file provided');
        return undef;
    }

    my $hss = _create_xss_parser('robot' => $robot);
    unless (defined $hss) {
        Log::do_log('err', 'Can\'t create StripScript parser');
        return undef;
    }
    $hss->parse_file($parameters{'file'});
    return $hss->filtered_document;
}

## Sanitize all values in the hash $var, starting from $level
sub sanitize_var {
    my %parameters = @_;
    my $robot      = $parameters{'robot'};
    Log::do_log('debug3', '(var=%s, level=%s, robot=%s)',
        $parameters{'var'}, $parameters{'level'}, $robot);
    unless (defined $parameters{'var'}) {
        Log::do_log('err', 'Missing var to sanitize');
        return undef;
    }
    unless (defined $parameters{'htmlAllowedParam'}
        && $parameters{'htmlToFilter'}) {
        Log::do_log(
            'err',
            'Missing var *** %s *** %s *** to ignore',
            $parameters{'htmlAllowedParam'},
            $parameters{'htmlToFilter'}
        );
        return undef;
    }
    my $level = $parameters{'level'};
    $level |= 0;

    if (ref($parameters{'var'})) {
        if (ref($parameters{'var'}) eq 'ARRAY') {
            foreach my $index (0 .. $#{$parameters{'var'}}) {
                if (   (ref($parameters{'var'}->[$index]) eq 'ARRAY')
                    || (ref($parameters{'var'}->[$index]) eq 'HASH')) {
                    sanitize_var(
                        'var'              => $parameters{'var'}->[$index],
                        'level'            => $level + 1,
                        'robot'            => $robot,
                        'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
                        'htmlToFilter'     => $parameters{'htmlToFilter'},
                    );
                } elsif (defined $parameters{'var'}->[$index]) {
                    # preserve numeric flags.
                    $parameters{'var'}->[$index] =
                        escape_html($parameters{'var'}->[$index])
                        unless Scalar::Util::looks_like_number(
                        $parameters{'var'}->[$index]);
                }
            }
        } elsif (ref($parameters{'var'}) eq 'HASH') {
            foreach my $key (keys %{$parameters{'var'}}) {
                if (   (ref($parameters{'var'}->{$key}) eq 'ARRAY')
                    || (ref($parameters{'var'}->{$key}) eq 'HASH')) {
                    sanitize_var(
                        'var'              => $parameters{'var'}->{$key},
                        'level'            => $level + 1,
                        'robot'            => $robot,
                        'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
                        'htmlToFilter'     => $parameters{'htmlToFilter'},
                    );
                } elsif (defined $parameters{'var'}->{$key}) {
                    unless ($parameters{'htmlAllowedParam'}{$key}
                        or $parameters{'htmlToFilter'}{$key}) {
                        # preserve numeric flags.
                        $parameters{'var'}->{$key} =
                            escape_html($parameters{'var'}->{$key})
                            unless Scalar::Util::looks_like_number(
                            $parameters{'var'}->{$key});
                    }
                    if ($parameters{'htmlToFilter'}{$key}) {
                        $parameters{'var'}->{$key} = sanitize_html(
                            'string' => $parameters{'var'}->{$key},
                            'robot'  => $robot
                        );
                    }
                }

            }
        }
    } else {
        Log::do_log('err', 'Variable is neither a hash nor an array');
        return undef;
    }
    return 1;
}

# DEPRECATED: No longer used.
#sub sortbydomain($x, $y);

## Sort subroutine to order files in sympa spool by date
sub by_date {
    my @a_tokens = split /\./, ($a || '');
    my @b_tokens = split /\./, ($b || '');

    ## File format : list@dom.date.pid
    my $a_time = $a_tokens[$#a_tokens - 1] || 0;
    my $b_time = $b_tokens[$#b_tokens - 1] || 0;

    return $a_time <=> $b_time;

}

## Safefork does several tries before it gives up.
## Do 3 trials and wait 10 seconds * $i between each.
## Exit with a fatal error is fork failed after all
## tests have been exhausted.
sub safefork {
    my ($i, $pid);

    my $err;
    for ($i = 1; $i < 4; $i++) {
        my ($pid) = fork;
        return $pid if defined $pid;

        $err = $ERRNO;
        Log::do_log('err', 'Cannot create new process: %s', $err);
        #FIXME:should send a mail to the listmaster
        sleep(10 * $i);
    }
    die sprintf 'Exiting because cannot create new process: %s', $err;
    # No return.
}

####################################################
# checkcommand
####################################################
# Checks for no command in the body of the message.
# If there are some command in it, it return true
# and send a message to $sender
#
# IN : -$msg (+): ref(MIME::Entity) - message to check
#      -$sender (+): the sender of $msg
#      -$robot (+) : robot
#
# OUT : -1 if there are some command in $msg
#       -0 else
#
######################################################
sub checkcommand {
    my ($msg, $sender, $robot) = @_;

    my ($avoid, $i);

    my $hdr = $msg->head;

    ## Check for commands in the subject.
    my $subject = $msg->head->get('Subject');

    Log::do_log('debug3', '(msg->head->get(subject) %s, %s)',
        $subject, $sender);

    if ($subject) {
        if ($Conf::Conf{'misaddressed_commands_regexp'}
            && ($subject =~
                /^$Conf::Conf{'misaddressed_commands_regexp'}\b/im)) {
            return 1;
        }
    }

    return 0 if ($#{$msg->body} >= 5);    ## More than 5 lines in the text.

    foreach $i (@{$msg->body}) {
        if ($Conf::Conf{'misaddressed_commands_regexp'}
            && ($i =~ /^$Conf::Conf{'misaddressed_commands_regexp'}\b/im)) {
            return 1;
        }

        ## Control is only applied to first non-blank line
        last unless $i =~ /^\s*$/;
    }
    return 0;
}

## return a hash from the edit_list_conf file
sub load_edit_list_conf {
    Log::do_log('debug2', '(%s)', @_);
    my $list = shift;

    my $robot = $list->{'domain'};
    my $file;
    my $conf;

    return undef
        unless $file = tools::search_fullpath($list, 'edit_list.conf');

    unless (open(FILE, $file)) {
        Log::do_log('info', 'Unable to open config file %s', $file);
        return undef;
    }

    my $error_in_conf;
    my $roles_regexp =
        'listmaster|privileged_owner|owner|editor|subscriber|default';
    while (<FILE>) {
        next if /^\s*(\#.*|\s*)$/;

        if (/^\s*(\S+)\s+(($roles_regexp)\s*(,\s*($roles_regexp))*)\s+(read|write|hidden)\s*$/i
            ) {
            my ($param, $role, $priv) = ($1, $2, $6);
            my @roles = split /,/, $role;
            foreach my $r (@roles) {
                $r =~ s/^\s*(\S+)\s*$/$1/;
                if ($r eq 'default') {
                    $error_in_conf = 1;
                    Log::do_log('notice', '"default" is no more recognised');
                    foreach
                        my $set ('owner', 'privileged_owner', 'listmaster') {
                        $conf->{$param}{$set} = $priv;
                    }
                    next;
                }
                $conf->{$param}{$r} = $priv;
            }
        } else {
            Log::do_log(
                'info',
                'Unknown parameter in %s (Ignored) %s',
                "$Conf::Conf{'etc'}/edit_list.conf", $_
            );
            next;
        }
    }

    if ($error_in_conf) {
        tools::send_notify_to_listmaster($robot, 'edit_list_error', [$file]);
    }

    close FILE;
    return $conf;
}

## return a hash from the edit_list_conf file
sub load_create_list_conf {
    my $robot = shift;

    my $file;
    my $conf;

    $file = tools::search_fullpath($robot, 'create_list.conf');
    unless ($file) {
        Log::do_log(
            'info',
            'Unable to read %s',
            Sympa::Constants::DEFAULTDIR . '/create_list.conf'
        );
        return undef;
    }

    unless (open(FILE, $file)) {
        Log::do_log('info', 'Unable to open config file %s', $file);
        return undef;
    }

    while (<FILE>) {
        next if /^\s*(\#.*|\s*)$/;

        if (/^\s*(\S+)\s+(read|hidden)\s*$/i) {
            $conf->{$1} = lc($2);
        } else {
            Log::do_log(
                'info',
                'Unknown parameter in %s (Ignored) %s',
                "$Conf::Conf{'etc'}/create_list.conf", $_
            );
            next;
        }
    }

    close FILE;
    return $conf;
}

sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
        return {'title' => $title};
    } else {
        $topic->{'sub'}{$name} =
            _add_topic(join('/', @tree[1 .. $#tree]), $title);
        return $topic;
    }
}

sub get_list_list_tpl {
    my $robot = shift;

    my $list_conf;
    my $list_templates;
    unless ($list_conf = load_create_list_conf($robot)) {
        return undef;
    }

    foreach my $dir (
        reverse
        @{tools::get_search_path($robot, subdir => 'create_list_templates')})
    {
        if (opendir(DIR, $dir)) {
        LOOP_FOREACH_TEMPLATE:
            foreach my $template (sort grep (!/^\./, readdir(DIR))) {
                my $status = $list_conf->{$template}
                    || $list_conf->{'default'};
                next if $status eq 'hidden';

                $list_templates->{$template}{'path'} = $dir;

                # Look for a comment.tt2.
                # Check old style locale first then canonic language and its
                # fallbacks.
                my $lang = Sympa::Language->instance->get_lang;
                my $comment_tt2;
                foreach my $l (
                    Sympa::Language::lang2oldlocale($lang),
                    Sympa::Language::implicated_langs($lang)
                    ) {
                    next unless $l;
                    $comment_tt2 =
                        $dir . '/' . $template . '/' . $l . '/comment.tt2';
                    if (-r $comment_tt2) {
                        $list_templates->{$template}{'comment'} =
                            $comment_tt2;
                        next LOOP_FOREACH_TEMPLATE;
                    }
                }
                $comment_tt2 = $dir . '/' . $template . '/comment.tt2';
                if (-r $comment_tt2) {
                    $list_templates->{$template}{'comment'} = $comment_tt2;
                }
            }
            closedir(DIR);
        }
    }

    return ($list_templates);
}

sub get_templates_list {
    Log::do_log('debug3', '(%s, %s, %s, %s)', @_);
    my $type    = shift;
    my $robot   = shift;
    my $list    = shift;
    my $options = shift;

    my $listdir;

    unless (($type eq 'web') || ($type eq 'mail')) {
        Log::do_log('info', 'Internal error incorrect parameter');
    }

    my $distrib_dir = Sympa::Constants::DEFAULTDIR . '/' . $type . '_tt2';
    my $site_dir    = $Conf::Conf{'etc'} . '/' . $type . '_tt2';
    my $robot_dir = $Conf::Conf{'etc'} . '/' . $robot . '/' . $type . '_tt2';

    my @try;

    ## The 'ignore_global' option allows to look for files at list level only
    unless ($options->{'ignore_global'}) {
        push @try, $distrib_dir;
        push @try, $site_dir;
        push @try, $robot_dir;
    }

    if (defined $list) {
        $listdir = $list->{'dir'} . '/' . $type . '_tt2';
        push @try, $listdir;
    } else {
        $listdir = '';
    }

    my $i = 0;
    my $tpl;

    foreach my $dir (@try) {
        next unless opendir(DIR, $dir);
        foreach my $file (grep (!/^\./, readdir(DIR))) {
            ## Subdirectory for a lang
            if (-d $dir . '/' . $file) {
                my $lang = $file;
                next unless opendir(LANGDIR, $dir . '/' . $lang);
                foreach my $file (grep (!/^\./, readdir(LANGDIR))) {
                    next unless ($file =~ /\.tt2$/);
                    if ($dir eq $distrib_dir) {
                        $tpl->{$file}{'distrib'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                    if ($dir eq $site_dir) {
                        $tpl->{$file}{'site'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                    if ($dir eq $robot_dir) {
                        $tpl->{$file}{'robot'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                    if ($dir eq $listdir) {
                        $tpl->{$file}{'list'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                }
                closedir LANGDIR;

            } else {
                next unless ($file =~ /\.tt2$/);
                if ($dir eq $distrib_dir) {
                    $tpl->{$file}{'distrib'}{'default'} = $dir . '/' . $file;
                }
                if ($dir eq $site_dir) {
                    $tpl->{$file}{'site'}{'default'} = $dir . '/' . $file;
                }
                if ($dir eq $robot_dir) {
                    $tpl->{$file}{'robot'}{'default'} = $dir . '/' . $file;
                }
                if ($dir eq $listdir) {
                    $tpl->{$file}{'list'}{'default'} = $dir . '/' . $file;
                }
            }
        }
        closedir DIR;
    }
    return ($tpl);

}

# return the path for a specific template
sub get_template_path {
    Log::do_log('debug2', '(%s, %s. %s, %s, %s, %s)', @_);
    my $type  = shift;
    my $robot = shift;
    my $scope = shift;
    my $tpl   = shift;
    my $lang  = shift || 'default';
    my $list  = shift;

    my $subdir = '';
    # canonicalize language name which may be old-style locale name.
    unless ($lang eq 'default') {
        my $oldlocale = Sympa::Language::lang2oldlocale($lang);
        unless ($oldlocale eq $lang) {
            $subdir = Sympa::Language::canonic_lang($lang);
            unless ($subdir) {
                Log::do_log('info', 'Internal error incorrect parameter');
                return undef;
            }
        }
    }

    unless ($type eq 'web' or $type eq 'mail') {
        Log::do_log('info', 'Internal error incorrect parameter');
        return undef;
    }

    my $dir;
    if ($scope eq 'list') {
        unless (ref $list eq 'Sympa::List') {
            Log::do_log('err', 'Missing parameter "list"');
            return undef;
        }
        $dir = $list->{'dir'};
    } elsif ($scope eq 'robot') {
        $dir = $Conf::Conf{'etc'} . '/' . $robot;
    } elsif ($scope eq 'site') {
        $dir = $Conf::Conf{'etc'};
    } elsif ($scope eq 'distrib') {
        $dir = Sympa::Constants::DEFAULTDIR;
    } else {
        return undef;
    }

    $dir .= '/' . $type . '_tt2';
    $dir .= '/' . $subdir if length $subdir;
    return $dir . '/' . $tpl;
}

## Make a multipart/alternative to a singlepart
# DEPRECATED: Use Sympa::Message::_as_singlepart().
#sub as_singlepart($msg, $preferred_type, $loops);

## Escape characters before using a string within a regexp parameter
## Escaped characters are : @ $ [ ] ( ) ' ! '\' * . + ?
sub escape_regexp {
    my $s = shift;
    my @escaped =
        ("\\", '@', '$', '[', ']', '(', ')', "'", '!', '*', '.', '+', '?');
    my $backslash = "\\";    ## required in regexp

    foreach my $escaped_char (@escaped) {
        $s =~ s/$backslash$escaped_char/\\$escaped_char/g;
    }

    return $s;
}

# Escape weird characters
# FIXME: Should not use.
sub escape_chars {
    my $s          = shift;
    my $except     = shift;                            ## Exceptions
    my $ord_except = ord $except if defined $except;

    ## Escape chars
    ##  !"#$%&'()+,:;<=>?[] AND accented chars
    ## escape % first
    foreach my $i (
        0x25,
        0x20 .. 0x24,
        0x26 .. 0x2c,
        0x3a .. 0x3f,
        0x5b, 0x5d,
        0x80 .. 0x9f,
        0xa0 .. 0xff
        ) {
        next if defined $ord_except and $i == $ord_except;
        my $hex_i = sprintf "%lx", $i;
        $s =~ s/\x$hex_i/%$hex_i/g;
    }
    ## Special traetment for '/'
    $s =~ s/\//%a5/g unless defined $except and $except eq '/';

    return $s;
}

## Escape shared document file name
## Q-decode it first
sub escape_docname {
    my $filename = shift;
    my $except   = shift;    ## Exceptions

    ## Q-decode
    $filename = MIME::EncWords::decode_mimewords($filename);

    ## Decode from FS encoding to utf-8
    #$filename = Encode::decode($Conf::Conf{'filesystem_encoding'}, $filename);

    ## escapesome chars for use in URL
    return escape_chars($filename, $except);
}

## Convert from Perl unicode encoding to UTF8
sub unicode_to_utf8 {
    my $s = shift;

    if (Encode::is_utf8($s)) {
        return Encode::encode_utf8($s);
    }

    return $s;
}

## Q-Encode web file name
sub qencode_filename {
    my $filename = shift;

    ## We don't use MIME::Words here because it does not encode properly
    ## Unicode
    ## Check if string is already Q-encoded first
    ## Also check if the string contains 8bit chars
    unless ($filename =~ /\=\?UTF-8\?/
        || $filename =~ /^[\x00-\x7f]*$/) {

        ## Don't encode elements such as .desc. or .url or .moderate
        ## or .extension
        my $part = $filename;
        my ($leading, $trailing);
        $leading  = $1 if ($part =~ s/^(\.desc\.)//);    ## leading .desc
        $trailing = $1 if ($part =~ s/((\.\w+)+)$//);    ## trailing .xx

        my $encoded_part = MIME::EncWords::encode_mimewords(
            $part,
            Charset    => 'utf8',
            Encoding   => 'q',
            MaxLineLen => 1000,
            Minimal    => 'NO'
        );

        $filename = $leading . $encoded_part . $trailing;
    }

    return $filename;
}

## Q-Decode web file name
sub qdecode_filename {
    my $filename = shift;

    ## We don't use MIME::Words here because it does not encode properly
    ## Unicode
    ## Check if string is already Q-encoded first
    #if ($filename =~ /\=\?UTF-8\?/) {
    $filename = Encode::encode_utf8(Encode::decode('MIME-Q', $filename));
    #}

    return $filename;
}

## Unescape weird characters
sub unescape_chars {
    my $s = shift;

    $s =~ s/%a5/\//g;    ## Special traetment for '/'
    foreach my $i (0x20 .. 0x2c, 0x3a .. 0x3f, 0x5b, 0x5d, 0x80 .. 0x9f,
        0xa0 .. 0xff) {
        my $hex_i = sprintf "%lx", $i;
        my $hex_s = sprintf "%c",  $i;
        $s =~ s/%$hex_i/$hex_s/g;
    }

    return $s;
}

sub escape_html {
    my $s = shift;
    return $s unless defined $s;

    $s =~ s/\"/\&quot\;/gm;
    $s =~ s/\</&lt\;/gm;
    $s =~ s/\>/&gt\;/gm;

    return $s;
}

sub unescape_html {
    my $s = shift;
    return $s unless defined $s;

    $s =~ s/\&quot\;/\"/g;
    $s =~ s/&lt\;/\</g;
    $s =~ s/&gt\;/\>/g;

    return $s;
}

# Check sum used to authenticate communication from wwsympa to sympa
# DEPRECATED: No longer used: This is moved to upgrade_send_spool.pl to be
# used for migrating old spool.
#sub sympa_checksum($rcpt);

# create a cipher
sub cookie_changed {
    my $current = shift;
    my $changed = 1;
    if (-f "$Conf::Conf{'etc'}/cookies.history") {
        unless (open COOK, "$Conf::Conf{'etc'}/cookies.history") {
            Log::do_log('err', 'Unable to read %s/cookies.history',
                $Conf::Conf{'etc'});
            return undef;
        }
        my $oldcook = <COOK>;
        close COOK;

        my @cookies = split(/\s+/, $oldcook);

        if ($cookies[$#cookies] eq $current) {
            Log::do_log('debug2', 'Cookie is stable');
            $changed = 0;
#	}else{
#	    push @cookies, $current ;
#	    unless (open COOK, ">$Conf::Conf{'etc'}/cookies.history") {
#		Log::do_log('err', 'Unable to create %s/cookies.history', $Conf::Conf{'etc'}) ;
#		return undef ;
#	    }
#	    printf COOK "%s",join(" ",@cookies) ;
#
#	    close COOK;
        }
        return $changed;
    } else {
        my $umask = umask 037;
        unless (open COOK, ">$Conf::Conf{'etc'}/cookies.history") {
            umask $umask;
            Log::do_log('err', 'Unable to create %s/cookies.history',
                $Conf::Conf{'etc'});
            return undef;
        }
        umask $umask;
        chown [getpwnam(Sympa::Constants::USER)]->[2],
            [getgrnam(Sympa::Constants::GROUP)]->[2],
            "$Conf::Conf{'etc'}/cookies.history";
        print COOK "$current ";
        close COOK;
        return (0);
    }
}

sub load_mime_types {
    my $types = {};

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
                $types->{$k} = $extensions[0];
            }
            foreach my $ext (@extensions) {
                $types->{$ext} = $k;
            }
        }

        close $fh;
        return $types;
    }

    return undef;
}

=head3 Finding config files and templates

=over 4

=item search_fullpath ( $that, $name, [ opt => val, ...] )

    # To get file name for global site
    $file = tools::search_fullpath('*', $name);
    # To get file name for a robot
    $file = tools::search_fullpath($robot_id, $name);
    # To get file name for a family
    $file = tools::search_fullpath($family, $name);
    # To get file name for a list
    $file = tools::search_fullpath($list, $name);

Look for a file in the list > robot > site > default locations.

Possible values for options:
    order     => 'all'
    subdir    => directory ending each path
    lang      => language
    lang_only => if paths without lang subdirectory would be omitted

Returns full path of target file C<I<root>/I<subdir>/I<lang>/I<name>>
or C<I<root>/I<subdir>/I<name>>.
I<root> is the location determined by target object $that.
I<subdir> and I<lang> are optional.
If C<lang_only> option is set, paths without I<lang> subdirectory is omitted.

=back

=cut

sub search_fullpath {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $that    = shift;
    my $name    = shift;
    my %options = @_;

    my (@try, $default_name);

    ## template refers to a language
    ## => extend search to default tpls
    ## FIXME: family path precedes to list path.  Is it appropriate?
    if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
        $default_name = $1 . '.tt2';
        @try =
            map { ($_ . '/' . $name, $_ . '/' . $default_name) }
            @{get_search_path($that, %options)};
    } else {
        @try =
            map { $_ . '/' . $name } @{get_search_path($that, %options)};
    }

    my @result;
    foreach my $f (@try) {
##        if (-l $f) {
##            my $realpath = Cwd::abs_path($f);    # follow symlink
##            next unless $realpath and -r $realpath;
##        } elsif (!-r $f) {
##            next;
##        }
        next unless -r $f;
        Log::do_log('debug3', 'Name: %s; file %s', $name, $f);

        if ($options{'order'} and $options{'order'} eq 'all') {
            push @result, $f;
        } else {
            return $f;
        }
    }
    if ($options{'order'} and $options{'order'} eq 'all') {
        return @result;
    }

    return undef;
}

=over 4

=item get_search_path ( $that, [ opt => val, ... ] )

    # To make include path for global site
    @path = @{tools::get_search_path('*')};
    # To make include path for a robot
    @path = @{tools::get_search_path($robot_id)};
    # To make include path for a family
    @path = @{tools::get_search_path($family)};
    # To make include path for a list
    @path = @{tools::get_search_path($list)};

make an array of include path for tt2 parsing

IN :
      -$that(+) : ref(Sympa::List) | ref(Sympa::Family) | Robot | "*"
      -%options : options

Possible values for options:
    subdir    => directory ending each path
    lang      => language
    lang_only => if paths without lang subdirectory would be omitted

OUT : ref(ARRAY) of tt2 include path

=begin comment

Note:
As of 6.2b, argument $lang is recommended to be IETF language tag,
rather than locale name.

=end comment

=back

=cut

sub get_search_path {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $that    = shift;
    my %options = @_;

    my $subdir    = $options{'subdir'};
    my $lang      = $options{'lang'};
    my $lang_only = $options{'lang_only'};

    ## Get language subdirectories.
    my $lang_dirs;
    if ($lang) {
        ## For compatibility: add old-style "locale" directory at first.
        ## Add lang itself and fallback directories.
        $lang_dirs = [
            grep {$_} (
                Sympa::Language::lang2oldlocale($lang),
                Sympa::Language::implicated_langs($lang)
            )
        ];
    }

    return [_get_search_path($that, $subdir, $lang_dirs, $lang_only)];
}

sub _get_search_path {
    my $that = shift;
    my ($subdir, $lang_dirs, $lang_only) = @_;    # shift is not used

    my @search_path;

    if (ref $that and ref $that eq 'Sympa::List') {
        my $path_list;
        my $path_family;
        @search_path = _get_search_path($that->{'domain'}, @_);

        if ($subdir) {
            $path_list = $that->{'dir'} . '/' . $subdir;
        } else {
            $path_list = $that->{'dir'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                unshift @search_path, $path_list;
            }
            unshift @search_path, map { $path_list . '/' . $_ } @$lang_dirs;
        } else {
            unshift @search_path, $path_list;
        }

        if (defined $that->get_family) {
            my $family = $that->get_family;
            if ($subdir) {
                $path_family = $family->{'dir'} . '/' . $subdir;
            } else {
                $path_family = $family->{'dir'};
            }
            if ($lang_dirs) {
                unless ($lang_only) {
                    unshift @search_path, $path_family;
                }
                unshift @search_path,
                    map { $path_family . '/' . $_ } @$lang_dirs;
            } else {
                unshift @search_path, $path_family;
            }
        }
    } elsif (ref $that and ref $that eq 'Sympa::Family') {
        my $path_family;
        @search_path = _get_search_path($that->{'robot'}, @_);

        if ($subdir) {
            $path_family = $that->{'dir'} . '/' . $subdir;
        } else {
            $path_family = $that->{'dir'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                unshift @search_path, $path_family;
            }
            unshift @search_path, map { $path_family . '/' . $_ } @$lang_dirs;
        } else {
            unshift @search_path, $path_family;
        }
    } elsif (not ref $that and $that and $that ne '*') {    # Robot
        my $path_robot;
        @search_path = _get_search_path('*', @_);

        if ($that ne $Conf::Conf{'domain'}) {
            if ($subdir) {
                $path_robot =
                    $Conf::Conf{'etc'} . '/' . $that . '/' . $subdir;
            } else {
                $path_robot = $Conf::Conf{'etc'} . '/' . $that;
            }
            if ($lang_dirs) {
                unless ($lang_only) {
                    unshift @search_path, $path_robot;
                }
                unshift @search_path,
                    map { $path_robot . '/' . $_ } @$lang_dirs;
            } else {
                unshift @search_path, $path_robot;
            }
        }
    } elsif (not ref $that and $that eq '*') {    # Site
        my $path_etcbindir;
        my $path_etcdir;

        if ($subdir) {
            $path_etcbindir = Sympa::Constants::DEFAULTDIR . '/' . $subdir;
            $path_etcdir    = $Conf::Conf{'etc'} . '/' . $subdir;
        } else {
            $path_etcbindir = Sympa::Constants::DEFAULTDIR;
            $path_etcdir    = $Conf::Conf{'etc'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                @search_path = (
                    (map { $path_etcdir . '/' . $_ } @$lang_dirs),
                    $path_etcdir,
                    (map { $path_etcbindir . '/' . $_ } @$lang_dirs),
                    $path_etcbindir
                );
            } else {
                @search_path = (
                    (map { $path_etcdir . '/' . $_ } @$lang_dirs),
                    (map { $path_etcbindir . '/' . $_ } @$lang_dirs)
                );
            }
        } else {
            @search_path = ($path_etcdir, $path_etcbindir);
        }
    } else {
        die 'bug in logic.  Ask developer';
    }

    return @search_path;
}

=over

=item send_file

    # To send site-global (not relative to a list or a robot)
    # message
    Site->send_file($template, $who, ...);
    # To send global (not relative to a list, but relative to a
    # robot) message
    $robot->send_file($template, $who, ...);
    # To send message relative to a list
    $list->send_file($template, $who, ...);

Send a message to user(s).
Find the tt2 file according to $tpl, set up
$data for the next parsing (with $context and
configuration)
Message is signed if the list has a key and a
certificate

Note: List::send_global_file() was deprecated.

=back

=cut

sub send_file {
    Log::do_log('debug2', '(%s, %s, %s, ...)', @_);
    my $that    = shift;
    my $tpl     = shift;
    my $who     = shift;
    my $context = shift || {};
    my %options = @_;

    my $message =
        Sympa::Message->new_from_template($that, $tpl, $who, $context,
        %options);

    unless ($message and defined Sympa::Bulk::store($message, $who)) {
        Log::do_log('err', 'Could not send template %s to %s', $tpl, $who);
        return undef;
    }

    return 1;
}

# Sends a notice to listmaster by parsing
# listmaster_notification.tt2 template
#
# IN : -$operation (+): notification type
#      -$robot (+): robot
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#

# Old name: List::send_notify_to_listmaster()
# Note: this would be moved to Site package.
sub send_notify_to_listmaster {
    Log::do_log('debug2', '(%s, %s, %s)', @_) unless $_[1] eq 'logs_failed';
    my $that      = shift;
    my $operation = shift;
    my $data      = shift;

    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $list->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $listmaster =
        [split /\s*,\s*/, Conf::get_robot_conf($robot_id, 'listmaster')];
    my $to =
          Conf::get_robot_conf($robot_id, 'listmaster_email') . '@'
        . Conf::get_robot_conf($robot_id, 'host');

    if (ref $data ne 'HASH' and ref $data ne 'ARRAY') {
        die
            'Error on incoming parameter "$data", it must be a ref on HASH or a ref on ARRAY';
    }

    if (ref $data ne 'HASH') {
        my $d = {};
        foreach my $i ((0 .. $#{$data})) {
            $d->{"param$i"} = $data->[$i];
        }
        $data = $d;
    }

    $data->{'to'}             = $to;
    $data->{'type'}           = $operation;
    $data->{'auto_submitted'} = 'auto-generated';

    my @tosend;

    if ($operation eq 'no_db' or $operation eq 'db_restored') {
        $data->{'db_name'} = Conf::get_robot_conf($robot_id, 'db_name');
    }

    if (   $operation eq 'request_list_creation'
        or $operation eq 'request_list_renaming') {
        foreach my $email (@$listmaster) {
            my $cdata = Sympa::Tools::Data::dup_var($data);
            $cdata->{'one_time_ticket'} =
                Sympa::Auth::create_one_time_ticket($email, $robot_id,
                'get_pending_lists', $cdata->{'ip'});
            push @tosend,
                {
                email => $email,
                data  => $cdata
                };
        }
    } else {
        push @tosend,
            {
            email => $listmaster,
            data  => $data
            };
    }

    foreach my $ts (@tosend) {
        my $email = $ts->{'email'};
        # Skip DB access because DB is not accessible
        $email = [$email]
            if not ref $email
                and ($operation eq 'no_db' or $operation eq 'db_restored');

        my $notif_message =
            Sympa::Message->new_from_template($that,
            'listmaster_notification', $email, $ts->{'data'});
        $notif_message->{rcpt} = $email;

        unless ($notif_message
            and defined Sympa::Alarm::store($notif_message, $operation)) {
            Log::do_log(
                'notice',
                'Unable to send template "listmaster_notification" to %s listmaster %s',
                $robot_id,
                $listmaster
            ) unless $operation eq 'logs_failed';
            return undef;
        }
    }

    return 1;
}

## Q-encode a complete file hierarchy
## Usefull to Q-encode subshared documents
sub qencode_hierarchy {
    my $dir               = shift; ## Root directory
    my $original_encoding = shift; ## Suspected original encoding of filenames

    my $count;
    my @all_files;
    Sympa::Tools::File::list_dir($dir, \@all_files, $original_encoding);

    foreach my $f_struct (reverse @all_files) {

        ## At least one 8bit char
        next
            unless ($f_struct->{'filename'} =~ /[^\x00-\x7f]/);

        my $new_filename = $f_struct->{'filename'};
        my $encoding     = $f_struct->{'encoding'};
        Encode::from_to($new_filename, $encoding, 'utf8') if $encoding;

        ## Q-encode filename to escape chars with accents
        $new_filename = tools::qencode_filename($new_filename);

        my $orig_f = $f_struct->{'directory'} . '/' . $f_struct->{'filename'};
        my $new_f  = $f_struct->{'directory'} . '/' . $new_filename;

        ## Rename the file using utf8
        Log::do_log('notice', "Renaming %s to %s", $orig_f, $new_f);
        unless (rename $orig_f, $new_f) {
            Log::do_log('err', 'Failed to rename %s to %s: %m',
                $orig_f, $new_f);
            next;
        }
        $count++;
    }

    return $count;
}

# DEPRECATED: No longer used.
#sub dump_encoding($out);

# input user agent string and IP. return 1 if suspected to be a crawler.
# initial version based on rawlers_dtection.conf file only
# later : use Session table to identify those who create a lot of sessions
sub is_a_crawler {

    my $robot   = shift;
    my $context = shift;

#    if ($Conf::Conf{$robot}{'crawlers_detection'}) {
#	return ($Conf::Conf{$robot}{'crawlers_detection'}{'user_agent_string'}{$context->{'user_agent_string'}});
#    }

    # open (TMP, ">> /tmp/dump1");
    # print TMP "dump de la conf dans is_a_crawler : \n";
    # Sympa::Tools::Data::dump_var($Conf::Conf{'crawlers_detection'}, 0,\*TMP);
    # close TMP;
    return $Conf::Conf{'crawlers_detection'}{'user_agent_string'}
        {$context->{'user_agent_string'}};
}

sub get_message_id {
    my $robot = shift;

    my $domain;
    if ($robot and $robot ne '*') {
        $domain = Conf::get_robot_conf($robot, 'domain');
    } else {
        $domain = $Conf::Conf{'domain'};
    }

    return sprintf '<sympa.%d.%d.%d@%s>', time, $PID, int(rand(999)), $domain;
}

## Basic check of an email address
sub valid_email {
    my $email = shift;

    my $email_re = Sympa::Regexps::email();
    unless ($email =~ /^${email_re}$/) {
        Log::do_log('err', 'Invalid email address "%s"', $email);
        return undef;
    }

    ## Forbidden characters
    if ($email =~ /[\|\$\*\?\!]/) {
        Log::do_log('err', 'Invalid email address "%s"', $email);
        return undef;
    }

    return 1;
}

## Clean email address
sub clean_email {
    my $email = shift;

    ## Lower-case
    $email = lc($email);

    ## remove leading and trailing spaces
    $email =~ s/^\s*//;
    $email =~ s/\s*$//;

    return $email;
}

## Return canonical email address (lower-cased + space cleanup)
## It could also support alternate email
sub get_canonical_email {
    my $email = shift;

    ## Remove leading and trailing white spaces
    $email =~ s/^\s*(\S.*\S)\s*$/$1/;

    ## Lower-case
    $email = lc($email);

    return $email;
}

#DEPRECATED: No longer used.
# sub dump_html_var2($var);

#DEPRECATED: No longer used.
# sub remove_empty_entries($var);

####################################################
# clean_msg_id
####################################################
# clean msg_id to use it without  \n, \s or <,>
#
# IN : -$msg_id (+) : the msg_id
#
# OUT : -$msg_id : the clean msg_id
#
######################################################
sub clean_msg_id {
    my $msg_id = shift;

    return $msg_id unless defined $msg_id;

    chomp $msg_id;

    if ($msg_id =~ /\<(.+)\>/) {
        $msg_id = $1;
    }

    return $msg_id;
}

# Change X-Sympa-To: header field in the message
# DEPRECATED: No longer used
# sub change_x_sympa_to($file, $value);

# Compare 2 versions of Sympa
# DEPRECATED: Never used.
# sub higher_version($v1, $v2);

## Compare 2 versions of Sympa
sub lower_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./, $v1;
    my @tab2 = split /\./, $v2;

    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for my $i (0 .. $max) {

        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        } elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        } elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] < $tab2[0]);
    }

    return 0;
}

sub add_in_blacklist {
    my $entry = shift;
    my $robot = shift;
    my $list  = shift;

    Log::do_log('info', '(%s, %s, %s)', $entry, $robot, $list->{'name'});
    $entry = lc($entry);
    chomp $entry;

    # robot blacklist not yet availible
    unless ($list) {
        Log::do_log('info',
            "tools::add_in_blacklist: robot blacklist not yet availible, missing list parameter"
        );
        return undef;
    }
    unless (($entry) && ($robot)) {
        Log::do_log('info', 'Missing parameters');
        return undef;
    }
    if ($entry =~ /\*.*\*/) {
        Log::do_log('info', 'Incorrect parameter %s', $entry);
        return undef;
    }
    my $dir = $list->{'dir'} . '/search_filters';
    unless ((-d $dir) || mkdir($dir, 0755)) {
        Log::do_log('info', 'Unable to create dir %s', $dir);
        return undef;
    }
    my $file = $dir . '/blacklist.txt';

    if (open BLACKLIST, "$file") {
        while (<BLACKLIST>) {
            next if (/^\s*$/o || /^[\#\;]/o);
            my $regexp = $_;
            chomp $regexp;
            $regexp =~ s/\*/.*/;
            $regexp = '^' . $regexp . '$';
            if ($entry =~ /$regexp/i) {
                Log::do_log('notice', '%s already in blacklist(%s)',
                    $entry, $_);
                return 0;
            }
        }
        close BLACKLIST;
    }
    unless (open BLACKLIST, ">> $file") {
        Log::do_log('info', 'Append to file %s', $file);
        return undef;
    }
    print BLACKLIST "$entry\n";
    close BLACKLIST;

}

# DEPRECATED: No longer used.
# sub get_fingerprint($email, $fingerprint);

# DEPRECATED: Use Digest::MD5::md5_hex.
#sub md5_fingerprint($input_string);

# DEPRECATED: No longer used.
# sub get_db_random();

# DEPRECATED: No longer used.
# sub init_db_random();

sub get_separator {
    return $separator;
}

## Return the Sympa regexp corresponding to the input param
# OBSOLETED: Use Sympa::Regexps::<type>().
sub get_regexp {
    my $type = shift;

    if (my $re = Sympa::Regexps->can($type)) {
        return $re->();
    } else {
        return '\w+';    ## default is a very strict regexp
    }

}

=pod 

=head2 sub save_to_bad(HASH $param)

Saves a message file to the "bad/" spool of a given queue. Creates this directory if not found.

=head3 Arguments 

=over 

=item * I<param> : a hash containing all the arguments, which means:

=over 4

=item * I<file> : the characters string of the path to the file to copy to bad;

=item * I<hostname> : the characters string of the name of the virtual host concerned;

=item * I<queue> : the characters string of the name of the queue.

=back

=back 

=head3 Return 

=over

=item * 1 if the file was correctly saved to the "bad/" directory;

=item * undef if something went wrong.

=back 

=cut 

sub save_to_bad {

    my $param = shift;

    my $file     = $param->{'file'};
    my $robot_id = $param->{'hostname'};
    my $queue    = $param->{'queue'};

    if (!-d $queue . '/bad') {
        unless (mkdir $queue . '/bad', 0775) {
            Log::do_log('notice', 'Unable to create %s/bad/ directory',
                $queue);
            tools::send_notify_to_listmaster($robot_id,
                'unable_to_create_dir', {'dir' => "$queue/bad"});
            return undef;
        }
        Log::do_log('debug', 'mkdir %s/bad', $queue);
    }
    Log::do_log(
        'notice',
        "Saving file %s to %s",
        $queue . '/' . $file,
        $queue . '/bad/' . $file
    );
    unless (rename($queue . '/' . $file, $queue . '/bad/' . $file)) {
        Log::do_log(
            'notice',
            'Could not rename %s to %s: %m',
            $queue . '/' . $file,
            $queue . '/bad/' . $file
        );
        return undef;
    }

    return 1;
}

## Returns the counf of numbers found in the string given as argument.
# DEPRECATED: No longer used.
# sub count_numbers_in_string($str);

#*******************************************
# Function : addrencode
# Description : return formatted (and encoded) name-addr as RFC5322 3.4.
## IN : addr, [phrase, [charset, [comment]]]
#*******************************************
sub addrencode {
    my $addr    = shift;
    my $phrase  = (shift || '');
    my $charset = (shift || 'utf8');
    my $comment = (shift || '');

    return undef unless $addr =~ /\S/;

    if ($phrase =~ /[^\s\x21-\x7E]/) {
        $phrase = MIME::EncWords::encode_mimewords(
            Encode::decode('utf8', $phrase),
            'Encoding'    => 'A',
            'Charset'     => $charset,
            'Replacement' => 'FALLBACK',
            'Field'       => 'Resent-Sender', # almost longest
            'Minimal'     => 'DISPNAME',      # needs MIME::EncWords >= 1.012.
        );
    } elsif ($phrase =~ /\S/) {
        $phrase =~ s/([\\\"])/\\$1/g;
        $phrase = '"' . $phrase . '"';
    }
    if ($comment =~ /[^\s\x21-\x27\x2A-\x5B\x5D-\x7E]/) {
        $comment = MIME::EncWords::encode_mimewords(
            Encode::decode('utf8', $comment),
            'Encoding'    => 'A',
            'Charset'     => $charset,
            'Replacement' => 'FALLBACK',
            'Minimal'     => 'DISPNAME',
        );
    } elsif ($comment =~ /\S/) {
        $comment =~ s/([\\\"])/\\$1/g;
    }

    return
          ($phrase  =~ /\S/ ? "$phrase "    : '')
        . ($comment =~ /\S/ ? "($comment) " : '')
        . "<$addr>";
}

# Generate a newsletter from an HTML URL or a file path.
#sub create_html_part_from_web_page($param);
#DEPRECATED: No longer used.

#DEPRECATED: Use Sympa::Message::get_decoded_header().
#sub decode_header($msg, $tag, $sep=undef);

BEGIN { 'use Data::Password'; }

my @validation_messages = (
    {gettext_id => 'Not between %d and %d characters'},
    {gettext_id => 'Not %d characters or greater'},
    {gettext_id => 'Not less than or equal to %d characters'},
    {gettext_id => 'contains bad characters'},
    {gettext_id => 'contains less than %d character groups'},
    {gettext_id => 'contains over %d leading characters in sequence'},
    {gettext_id => "contains the dictionary word '%s'"},
);

sub password_validation {
    my ($password) = @_;

    my $pv = $Conf::Conf{'password_validation'};
    return undef
        unless $pv
            and defined $password
            and $Data::Password::VERSION;

    local (
        $Data::Password::DICTIONARY, $Data::Password::FOLLOWING,
        $Data::Password::GROUPS,     $Data::Password::MINLEN,
        $Data::Password::MAXLEN
    );
    local @Data::Password::DICTIONARIES = @Data::Password::DICTIONARIES;

    my @techniques = split(/\s*,\s*/, $pv);
    foreach my $technique (@techniques) {
        my ($key, $value) = $technique =~ /([^=]+)=(.*)/;
        $key = uc $key;

        if ($key eq 'DICTIONARY') {
            $Data::Password::DICTIONARY = $value;
        } elsif ($key eq 'FOLLOWING') {
            $Data::Password::FOLLOWING = $value;
        } elsif ($key eq 'GROUPS') {
            $Data::Password::GROUPS = $value;
        } elsif ($key eq 'MINLEN') {
            $Data::Password::MINLEN = $value;
        } elsif ($key eq 'MAXLEN') {
            $Data::Password::MAXLEN = $value;
        } elsif ($key eq 'DICTIONARIES') {
            # TODO: How do we handle a list of dictionaries?
            push @Data::Password::DICTIONARIES, $value;
        }
    }
    my $output = Data::Password::IsBadPassword($password);
    return undef unless $output;

    # Translate result if possible.
    my $language = Sympa::Language->instance;
    foreach my $item (@validation_messages) {
        my $format = $item->{'gettext_id'};
        my $regexp = quotemeta $format;
        $regexp =~ s/\\\%[sd]/(.+)/g;

        my ($match, @args) = ($output =~ /($regexp)/i);
        next unless $match;
        return $language->gettext_sprintf($format, @args);
    }
    return $output;
}

sub fix_children {
}

=over 4

=item get_supported_languages ( [ string ROBOT ] )

I<Function>.
Gets supported languages, canonicalized.
In array context, returns array of supported languages.
In scalar context, returns arrayref to them.

=back

=cut

#FIXME: Inefficient.  Would be cached.
sub get_supported_languages {
    my $robot = shift;

    my @lang_list = ();
    if (%Conf::Conf) {    # configuration loaded.
        my $supported_lang;

        if ($robot and $robot ne '*') {
            $supported_lang = Conf::get_robot_conf($robot, 'supported_lang');
        } else {
            $supported_lang = $Conf::Conf{'supported_lang'};
        }

        my $language = Sympa::Language->instance;
        $language->push_lang;
        @lang_list =
            grep { $_ and $_ = $language->set_lang($_) }
            split /[\s,]+/, $supported_lang;
        $language->pop_lang;
    }
    @lang_list = ('en') unless @lang_list;
    return @lang_list if wantarray;
    return \@lang_list;
}

=over 4

=item get_list_params

I<Getter>.
Returns hashref to list parameter information.

=back

=cut

sub get_list_params {
    my $robot_id = shift;

    my $pinfo = Sympa::Tools::Data::dup_var(\%Sympa::ListDef::pinfo);
    $pinfo->{'lang'}{'format'} = [tools::get_supported_languages($robot_id)];

    return $pinfo;
}

=over

=item lang2charset ( $lang )

Gets charset for e-mail messages sent by Sympa.

Parameters:

$lang - language.

Returns:

Charset name.
If it is not known, returns default charset.

=back

=cut

## FIXME: This would be moved to such as Site package.
sub lang2charset {
    my $lang = shift;

    my $locale2charset;
    if ($lang and %Conf::Conf    # configuration loaded
        and $locale2charset = $Conf::Conf{'locale2charset'}
        ) {
        foreach my $l (Sympa::Language::implicated_langs($lang)) {
            if (exists $locale2charset->{$l}) {
                return $locale2charset->{$l};
            }
        }
    }
    return 'utf-8';              # the last resort
}

=over 4

=item split_listname ( ROBOT_ID, MAILBOX )

XXX @todo doc

Note:
For C<-request> and C<-owner> suffix, this function returns
C<owner> and C<return_path> type, respectively.

=back

=cut

#FIXME: This should be moved to such as Robot package.
sub split_listname {
    my $robot_id = shift || '*';
    my $mailbox = shift;
    return unless defined $mailbox and length $mailbox;

    my $return_path_suffix =
        Conf::get_robot_conf($robot_id, 'return_path_suffix');
    my $regexp = join(
        '|',
        map { quotemeta $_ }
            grep { $_ and length $_ }
            split(
            /[\s,]+/, Conf::get_robot_conf($robot_id, 'list_check_suffixes')
            )
    );

    if (    $mailbox eq 'sympa'
        and $robot_id eq $Conf::Conf{'domain'}) {    # compat.
        return (undef, 'sympa');
    } elsif ($mailbox eq Conf::get_robot_conf($robot_id, 'email')
        or $robot_id eq $Conf::Conf{'domain'}
        and $mailbox eq $Conf::Conf{'email'}) {
        return (undef, 'sympa');
    } elsif ($mailbox eq Conf::get_robot_conf($robot_id, 'listmaster_email')
        or $robot_id eq $Conf::Conf{'domain'}
        and $mailbox eq $Conf::Conf{'listmaster_email'}) {
        return (undef, 'listmaster');
    } elsif ($mailbox =~ /^(\S+)$return_path_suffix$/) {    # -owner
        return ($1, 'return_path');
    } elsif (!$regexp) {
        return ($mailbox);
    } elsif ($mailbox =~ /^(\S+)-($regexp)$/) {
        my ($name, $suffix) = ($1, $2);
        my $type;

        if ($suffix eq 'request') {                         # -request
            $type = 'owner';
        } elsif ($suffix eq 'editor') {
            $type = 'editor';
        } elsif ($suffix eq 'subscribe') {
            $type = 'subscribe';
        } elsif ($suffix eq 'unsubscribe') {
            $type = 'unsubscribe';
        } else {
            $name = $mailbox;
            $type = 'UNKNOWN';
        }
        return ($name, $type);
    } else {
        return ($mailbox);
    }
}

# Old name: SympaspoolClassic::analyze_file_name().
# NOTE: This should be moved to Spool class.
sub unmarshal_metadata {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $spool_dir       = shift;
    my $marshalled      = shift;
    my $metadata_regexp = shift;
    my $metadata_keys   = shift;

    my $data;
    my @matches;
    unless (@matches = ($marshalled =~ /$metadata_regexp/)) {
        Log::do_log('debug',
            'File name %s does not have the proper format: %s',
            $marshalled, $metadata_regexp);
        return undef;
    }
    $data = {
        messagekey => $marshalled,
        map {
            my $value = shift @matches;
            (defined $value and length $value) ? ($_ => $value) : ();
            } @{$metadata_keys}
    };

    my ($robot_id, $listname, $type, $list, $priority);

    $robot_id = lc($data->{'domainpart'})
        if Conf::valid_robot($data->{'domainpart'}, just_try => 1);
    #FIXME: is this always needed?
    ($listname, $type) =
        tools::split_listname($robot_id || '*', $data->{'localpart'});
    if (defined $listname) {
        $list =
            Sympa::List->new($listname, $robot_id || '*', {'just_try' => 1});
    }

    ## Get priority
    #FIXME: is this always needed?
    if (exists $data->{'priority'}) {
        # Priority was given by metadata.
        ;
    } elsif ($type and $type eq 'listmaster') {
        ## highest priority
        $priority = 0;
    } elsif ($type and $type eq 'owner') {    # -request
        $priority = Conf::get_robot_conf($robot_id, 'request_priority');
    } elsif ($type and $type eq 'return_path') {    # -owner
        $priority = Conf::get_robot_conf($robot_id, 'owner_priority');
    } elsif ($type and $type eq 'sympa') {
        $priority = Conf::get_robot_conf($robot_id, 'sympa_priority');
    } elsif (ref $list eq 'Sympa::List') {
        $priority = $list->{'admin'}{'priority'};
    } else {
        $priority = Conf::get_robot_conf($robot_id, 'default_list_priority');
    }

    $data->{context} = $list || $robot_id || '*';
    $data->{'listname'} = $listname if $listname;
    $data->{'listtype'} = $type     if defined $type;
    $data->{'priority'} = $priority if defined $priority;

    Log::do_log('debug3', 'messagekey=%s, context=%s, priority=%s',
        $marshalled, $data->{context}, $data->{'priority'});

    return $data;
}

# NOTE: This should be moved to Spool class.
sub marshal_metadata {
    my $message         = shift;
    my $metadata_format = shift;
    my $metadata_keys   = shift;

    # Currently only "sympa@DOMAIN" and "listname@DOMAIN" are supported.
    my ($localpart, $domainpart);
    if (ref $message->{context} eq 'Sympa::List') {
        $localpart  = $message->{context}->{'name'};
        $domainpart = $message->{context}->{'domain'};
    } else {
        my $robot_id = $message->{context} || '*';
        $localpart  = Conf::get_robot_conf($robot_id, 'email');
        $domainpart = Conf::get_robot_conf($robot_id, 'domain');
    }

    my @args = map {
        if ($_ eq 'localpart') {
            $localpart;
        } elsif ($_ eq 'domainpart') {
            $domainpart;
        } elsif ($_ eq 'PID') {
            $PID;
        } elsif ($_ eq 'AUTHKEY') {
            Digest::MD5::md5_hex(time . (int rand 46656) . $domainpart);
        } elsif ($_ eq 'RAND') {
            int rand 10000;
        } elsif ($_ eq 'TIME') {
            Time::HiRes::time();
        } elsif (exists $message->{$_}
            and defined $message->{$_}
            and !ref($message->{$_})) {
            $message->{$_};
        } else {
            '';
        }
    } @{$metadata_keys};

    # Set "C" locale so that decimal point for "%f" will be ".".
    my $locale_numeric = POSIX::setlocale(POSIX::LC_NUMERIC());
    POSIX::setlocale(POSIX::LC_NUMERIC(), 'C');
    my $marshalled = sprintf $metadata_format, @args;
    POSIX::setlocale(POSIX::LC_NUMERIC(), $locale_numeric);
    return $marshalled;
}

# NOTE: This should be moved to Spool class.
sub store_spool {
    my $spool_dir       = shift;
    my $message         = shift;
    my $metadata_format = shift;
    my $metadata_keys   = shift;

    # At first content is stored into temporary file that has unique name and
    # is referred only by this function.
    my $tmppath = sprintf '%s/T.sympa@_tempfile.%s.%ld.%ld',
        $spool_dir, Sys::Hostname::hostname(), time, $PID;
    my $fh;
    unless (open $fh, '>', $tmppath) {
        die sprintf 'Cannot create %s: %s', $tmppath, $ERRNO;
    }
    print $fh $message->to_string();
    close $fh;

    # Rename temporary path to the file name including metadata.
    # Will retry up to five times.
    my $tries;
    for ($tries = 0; $tries < 5; $tries++) {
        my $marshalled =
            marshal_metadata($message, $metadata_format, $metadata_keys);
        my $path = $spool_dir . '/' . $marshalled;

        my $lock;
        unless ($lock = Sympa::LockedFile->new($path, -1, '+')) {
            next;
        }
        if (-e $path) {
            $lock->close;
            next;
        }

        unless (rename $tmppath, $path) {
            die sprintf 'Cannot create %s: %s', $path, $ERRNO;
        }
        $lock->close;
        return $marshalled;
    }

    unlink $tmppath;
    return undef;
}

1;
