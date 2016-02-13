# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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

use Sympa::Regexps;

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
#DEPRECATED: No longer used.
#sub by_date;

# Moved to Sympa::Mailer::_safefork().
#sub safefork ($i, $pid);

# Moved to _check_command in sympa_msg.pl.
#sub checkcommand;

# Moved to Sympa::List::_load_edit_list_conf().
#sub load_edit_list_conf;

# Moved to Sympa::Tools::WWW::_load_create_list_conf().
#sub load_create_list_conf;

#Moved to Sympa::Robot::_add_topic().
#sub _add_topic;

# Moved to Sympa::Tools::WWW::get_list_list_tpl().
#sub get_list_list_tpl;

# Moved to Sympa::Tools::WWW::get_templates_list().
#sub get_templates_list;

# Moved to Sympa::Tools::WWW:get_template_path().
#sub get_template_path;

## Make a multipart/alternative to a singlepart
# DEPRECATED: Use Sympa::Message::_as_singlepart().
#sub as_singlepart($msg, $preferred_type, $loops);

## Escape characters before using a string within a regexp parameter
## Escaped characters are : @ $ [ ] ( ) ' ! '\' * . + ?
# DEPRECATED: Use "s/([^\x00-\x1F\s\w\x7F-\xFF])/\\$1/g;".
#sub escape_regexp ($s);

# Moved to: Sympa::Tools::Text::escape_chars().
#sub escape_chars;

# Moved to: Sympa::SharedDocument::escape_docname().
#sub escape_docname;

## Convert from Perl unicode encoding to UTF8
# OBSOLETED.  No longer used.
sub unicode_to_utf8 {
    my $s = shift;

    if (Encode::is_utf8($s)) {
        return Encode::encode_utf8($s);
    }

    return $s;
}

# Moved to Sympa::Tools::Text::qencode_filename().
#sub qencode_filename;

# Moved to Sympa::Tools::Text::qdecode_filename().
#sub qdecode_filename;

# Moved to: Sympa::Tools::Text::unescape_chars().
#sub unescape_chars;

# Moved to: Sympa::Tools::WWW::escape_html_minimum().
#sub escape_html;

# Moved to: Sympa::Tools::WWW::unescape_html_minimum().
#sub unescape_html;

# Check sum used to authenticate communication from wwsympa to sympa
# DEPRECATED: No longer used: This is moved to upgrade_send_spool.pl to be
# used for migrating old spool.
#sub sympa_checksum($rcpt);

# Moved to Conf::cookie_changed().
#sub cookie_changed;

# Moved to Conf::_load_mime_types()
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

# Moved to Sympa::Tools::File::qencode_hierarchy().
#sub qencode_hierarchy;

# DEPRECATED: No longer used.
#sub dump_encoding($out);

# MOVED to Sympa::Session::_is_a_crawler().
#sub is_a_crawler;

# Moved to Sympa::unique_message_id().
#sub get_message_id;

# Moved to Sympa::Tools::Text::valid_email().
#sub valid_email;

#DEPRECATED.  Use Sympa::Tools::Text::canonic_email().
#sub clean_email;

#DEPRECATED.  Use Sympa::Tools::Text::canonic_email().
#sub get_canonical_email;

#DEPRECATED: No longer used.
# sub dump_html_var2($var);

#DEPRECATED: No longer used.
# sub remove_empty_entries($var);

# Moved to Sympa::Tools:Text::canonic_message_id().
#sub clean_msg_id;

# Change X-Sympa-To: header field in the message
# DEPRECATED: No longer used
# sub change_x_sympa_to($file, $value);

# Compare 2 versions of Sympa
# DEPRECATED: Never used.
# sub higher_version($v1, $v2);

## Compare 2 versions of Sympa
# Moved to Sympa::Upgrade::lower_version().
#sub lower_version ($v1, $v2);

# Moved to _add_in_blacklist() in wwsympa.fcgi.
#sub add_in_blacklist;

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

# Moved to: Sympa::Tools::Text::addrencode().
#sub addrencode;

# Generate a newsletter from an HTML URL or a file path.
#sub create_html_part_from_web_page($param);
#DEPRECATED: No longer used.

#DEPRECATED: Use Sympa::Message::get_decoded_header().
#sub decode_header($msg, $tag, $sep=undef);

# Moved to @Sympa::Tools::Password::validation_messages.
#my @validation_messages;

# Moved to Sympa::Tools::Password::password_validation().
#sub password_validation;

# Moved to Sympa::Process::eval_in_time().
#sub eval_in_time;

sub fix_children {
}

# Moved to Sympa::best_language().
#sub best_language;

# Moved to Sympa::get_supported_languages().
#sub get_supported_languages;

# Moved to Sympa::Robot::list_params().
#sub get_list_params;

# Moved to Conf::lang2charset().
#sub lang2charset;

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
__END__

=encoding utf-8

=head1 NOTE

This module was OBSOLETED.
Use appropriate module(s) instead.

=cut
