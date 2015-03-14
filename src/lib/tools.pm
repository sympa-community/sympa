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

package tools;

use strict;
use warnings;
use Encode qw();
use Encode::MIME::Header;    # for 'MIME-Q' encoding
use English;                 # FIXME: drop $MATCH usage
use MIME::EncWords;

use Sympa;
use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::ListDef;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Tools::Data;
use Sympa::Tools::File;

my $log = Sympa::Log->instance;

## Returns an HTML::StripScripts::Parser object built with  the parameters
## provided as arguments.
# DEPRECATED: Use Sympa::HTMLSanitizer::new().
#sub _create_xss_parser(robot => $robot);

## Returns sanitized version (using StripScripts) of the string provided as
## argument.
# DEPRECATED: Use Sympa::HTMLSanitizer::filter_html().
#sub sanitize_html(robot => $robot, string => $string);

## Returns sanitized version (using StripScripts) of the content of the file
## whose path is provided as argument.
# DEPRECATED: Use Sympa::HTMLSanitizer::filter_html_file().
#sub sanitize_html_file($robot => $robot, file => $file);

## Sanitize all values in the hash $var, starting from $level
# DEPRECATED: Use Sympa::HTMLSanitizer().
#sub sanitize_var(robot => $robot, var => $var, ...);

# DEPRECATED: No longer used.
#sub sortbydomain($x, $y);

# Sort subroutine to order files in sympa spool by date
#OBSOLETED: No longer used.
sub by_date {
    my @a_tokens = split /\./, ($a || '');
    my @b_tokens = split /\./, ($b || '');

    ## File format : list@dom.date.pid
    my $a_time = $a_tokens[$#a_tokens - 1] || 0;
    my $b_time = $b_tokens[$#b_tokens - 1] || 0;

    return $a_time <=> $b_time;

}

# Moved to Sympa::Mailer::_safefork().
#sub safefork ($i, $pid);

# Moved to _check_command in sympa_msg.pl.
#sub checkcommand;

## return a hash from the edit_list_conf file
sub load_edit_list_conf {
    $log->syslog('debug2', '(%s)', @_);
    my $list = shift;

    my $robot = $list->{'domain'};
    my $file;
    my $conf;

    return undef
        unless $file = Sympa::search_fullpath($list, 'edit_list.conf');

    unless (open(FILE, $file)) {
        $log->syslog('info', 'Unable to open config file %s', $file);
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
                    $log->syslog('notice', '"default" is no more recognised');
                    foreach
                        my $set ('owner', 'privileged_owner', 'listmaster') {
                        $conf->{$param}{$set} = $priv;
                    }
                    next;
                }
                $conf->{$param}{$r} = $priv;
            }
        } else {
            $log->syslog(
                'info',
                'Unknown parameter in %s (Ignored) %s',
                "$Conf::Conf{'etc'}/edit_list.conf", $_
            );
            next;
        }
    }

    if ($error_in_conf) {
        Sympa::send_notify_to_listmaster($robot, 'edit_list_error', [$file]);
    }

    close FILE;
    return $conf;
}

## return a hash from the edit_list_conf file
sub load_create_list_conf {
    my $robot = shift;

    my $file;
    my $conf;

    $file = Sympa::search_fullpath($robot, 'create_list.conf');
    unless ($file) {
        $log->syslog(
            'info',
            'Unable to read %s',
            Sympa::Constants::DEFAULTDIR . '/create_list.conf'
        );
        return undef;
    }

    unless (open(FILE, $file)) {
        $log->syslog('info', 'Unable to open config file %s', $file);
        return undef;
    }

    while (<FILE>) {
        next if /^\s*(\#.*|\s*)$/;

        if (/^\s*(\S+)\s+(read|hidden)\s*$/i) {
            $conf->{$1} = lc($2);
        } else {
            $log->syslog(
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
    unless ($list_conf = tools::load_create_list_conf($robot)) {
        return undef;
    }

    foreach my $dir (
        reverse
        @{Sympa::get_search_path($robot, subdir => 'create_list_templates')})
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
    $log->syslog('debug3', '(%s, %s, %s, %s)', @_);
    my $type    = shift;
    my $robot   = shift;
    my $list    = shift;
    my $options = shift;

    my $listdir;

    unless (($type eq 'web') || ($type eq 'mail')) {
        $log->syslog('info', 'Internal error incorrect parameter');
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
    $log->syslog('debug2', '(%s, %s. %s, %s, %s, %s)', @_);
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
                $log->syslog('info', 'Internal error incorrect parameter');
                return undef;
            }
        }
    }

    unless ($type eq 'web' or $type eq 'mail') {
        $log->syslog('info', 'Internal error incorrect parameter');
        return undef;
    }

    my $dir;
    if ($scope eq 'list') {
        unless (ref $list eq 'Sympa::List') {
            $log->syslog('err', 'Missing parameter "list"');
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
# DEPRECATED: Use "s/([^\x00-\x1F\s\w\x7F-\xFF])/\\$1/g;".
#sub escape_regexp ($s);

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
    return tools::escape_chars($filename, $except);
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

# Old name: tt2::escape_url().
sub escape_url {
    my $string = shift;

    $string =~ s/[\s+]/sprintf('%%%02x', ord($MATCH))/eg;
    # Some MUAs aren't able to decode ``%40'' (escaped ``@'') in e-mail
    # address of mailto: URL, or take ``@'' in query component for a
    # delimiter to separate URL from the rest.
    my ($body, $query) = split(/\?/, $string, 2);
    if (defined $query) {
        $query =~ s/\@/sprintf('%%%02x', ord($MATCH))/eg;
        $string = $body . '?' . $query;
    }

    return $string;
}

# Old name: tt2::escape_xml().
sub escape_xml {
    my $string = shift;

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\'/&apos;/g;
    $string =~ s/\"/&quot;/g;

    return $string;
}

# Old name: tt2::escape_quote().
sub escape_quote {
    my $string = shift;

    $string =~ s/\'/\\\'/g;
    $string =~ s/\"/\\\"/g;

    return $string;
}

# Check sum used to authenticate communication from wwsympa to sympa
# DEPRECATED: No longer used: This is moved to upgrade_send_spool.pl to be
# used for migrating old spool.
#sub sympa_checksum($rcpt);

# Moved to Conf::cookie_changed().
#sub cookie_changed;

# Moved to Sympa::Tools::WWW:_load_mime_types()
#sub load_mime_types();

# Old name: List::compute_auth().
# Moved to Sympa::compute_auth().
#sub compute_auth;

# Old name: List::request_auth().
# Moved to Sympa::request_auth().
#sub request_auth;

# Moved to Sympa::search_fullpath().
#sub search_fullpath;

# Moved to Sympa::get_search_path().
#sub get_search_path;

# Moved to Sympa::send_dsn().
#sub send_dsn;

# Old name: List::send_file(), List::send_global_file().
# Moved to Sympa::send_file().
#sub send_file;

# Old name: List::send_notify_to_listmaster()
# Moved to Sympa::send_notify_to_listmaster().
#sub send_notify_to_listmaster;

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
        $log->syslog('notice', "Renaming %s to %s", $orig_f, $new_f);
        unless (rename $orig_f, $new_f) {
            $log->syslog('err', 'Failed to rename %s to %s: %m',
                $orig_f, $new_f);
            next;
        }
        $count++;
    }

    return $count;
}

# DEPRECATED: No longer used.
#sub dump_encoding($out);

# MOVED to Sympa::Session::_is_a_crawler().
#sub is_a_crawler;

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
        $log->syslog('err', 'Invalid email address "%s"', $email);
        return undef;
    }

    ## Forbidden characters
    if ($email =~ /[\|\$\*\?\!]/) {
        $log->syslog('err', 'Invalid email address "%s"', $email);
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
# Moved to Sympa::Upgrade::lower_version().
#sub lower_version ($v1, $v2);

sub add_in_blacklist {
    my $entry = shift;
    my $robot = shift;
    my $list  = shift;

    $log->syslog('info', '(%s, %s, %s)', $entry, $robot, $list->{'name'});
    $entry = lc($entry);
    chomp $entry;

    # robot blacklist not yet availible
    unless ($list) {
        $log->syslog('info',
            "tools::add_in_blacklist: robot blacklist not yet availible, missing list parameter"
        );
        return undef;
    }
    unless (($entry) && ($robot)) {
        $log->syslog('info', 'Missing parameters');
        return undef;
    }
    if ($entry =~ /\*.*\*/) {
        $log->syslog('info', 'Incorrect parameter %s', $entry);
        return undef;
    }
    my $dir = $list->{'dir'} . '/search_filters';
    unless ((-d $dir) || mkdir($dir, 0755)) {
        $log->syslog('info', 'Unable to create dir %s', $dir);
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
                $log->syslog('notice', '%s already in blacklist(%s)',
                    $entry, $_);
                return 0;
            }
        }
        close BLACKLIST;
    }
    unless (open BLACKLIST, ">> $file") {
        $log->syslog('info', 'Append to file %s', $file);
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

# DEPRECATED: No longer used.
#my $separator =
#    "------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------";
#sub get_separator {
#    return $separator;
#}

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

# OBSOLETED.  Moved to _save_to_bad() in archived.pl.
#sub save_to_bad;

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

=over

=item eval_in_time ( $subref, $timeout )

Evaluate subroutine $subref in $timeout seconds.

TBD.

=back

=cut

sub eval_in_time {
    my $subref  = shift;
    my $timeout = shift;

    # Call to subroutine uses eval to set a timeout.
    # This prevents a subroutine to make the process wait forever if it does
    # not respond.
    my $ret = eval {
        local $SIG{__DIE__} = 'DEFAULT';
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };    # NB: \n required
        alarm $timeout;

        # Inner eval just in case the subroutine would die, thus leaving the
        # alarm trigered.
        my $ret = eval { $subref->() };
        alarm 0;
        $ret;
    };
    if ($EVAL_ERROR and $EVAL_ERROR eq "TIMEOUT\n") {
        $log->syslog('err', 'Processing timeout');
        return undef;
    } elsif ($EVAL_ERROR) {
        $log->syslog('err', 'Processing failed: %m');
        return undef;
    }

    return $ret;
}

sub fix_children {
}

# Moved to Sympa::best_language().
#sub best_language;

# Moved to Sympa::get_supported_languages().
#sub get_supported_languages;

=over 4

=item get_list_params

I<Getter>.
Returns hashref to list parameter information.

=back

=cut

sub get_list_params {
    my $robot_id = shift;

    my $pinfo = Sympa::Tools::Data::dup_var(\%Sympa::ListDef::pinfo);
    $pinfo->{'lang'}{'format'} = [Sympa::get_supported_languages($robot_id)];

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

# Moved to Sympa::Spool::split_listname().
#sub split_listname;

# Old name: SympaspoolClassic::analyze_file_name().
# Moved to Sympa::Spool::unmarshal_metadata().
#sub unmarshal_metadata;

# Moved to Sympa::Spool::marshal_metadata().
#sub marshal_metadata;

# Moved to Sympa::Spool::store_spool().
#sub store_spool;

1;
