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

package tt2;

use strict;
use warnings;

use Sympa::Template;

my $last_error;
my @other_include_path;
my $allow_absolute;

## To add a directory to the TT2 include_path
# OBSOLETED.  No longer used.
sub add_include_path {
    my $path = shift;

    push @other_include_path, $path;
}

## Get current INCLUDE_PATH
# OBSOLETED.  No longer used.
sub get_include_path {
    return @other_include_path;
}

## Clear current INCLUDE_PATH
# OBSOLETED.  No longer used.
sub clear_include_path {
    @other_include_path = ();
}

## Allow inclusion/insertion of file with absolute path
# OBSOLETED.  Use {allow_absolute} property of Sympa::Template instance.
sub allow_absolute_path {
    $allow_absolute = 1;
}

## Return the last error message
# OBSOLETED.  Use {last_error} property of Sympa::Template instance.
sub get_error {
    return $last_error;
}

# OBSOLETED.  Use tools::escape_url().
sub escape_url {
    return tools::escape_url(@_);
}

# OBSOLETED.  Use Sympa::Template::parse().
sub parse_tt2 {
    my ($data, $tpl_string, $output, $include_path, $options) = @_;
    $include_path ||= [Sympa::Constants::DEFAULTDIR];
    $options ||= {};

    # Add directories that may have been added
    push @{$include_path}, @other_include_path;
    clear_include_path();    # Reset it

    my $template = Sympa::Template->new(
        undef,
        include_path   => $include_path,
        allow_absolute => $allow_absolute
    );
    undef $allow_absolute;
    my $ret =
        $template->parse($data, $tpl_string, $output, %{$options || {}});
    $last_error = $template->{last_error};

    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

tt2

=head1 NOTICE

This module was OBSOLETED.
Use L<Sympa::Template> instead.

=cut
