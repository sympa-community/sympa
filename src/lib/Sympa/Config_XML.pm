# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2019, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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

package Sympa::Config_XML;

use strict;
use warnings;
use Encode qw();
use English qw(-no_match_vars);
use XML::LibXML;

use Sympa::Log;

my $log = Sympa::Log->instance;

# Constructor of the class Config_XML :
#   parse the xml file
#
# IN : -$class
#      -$file : path of XML file or file handle on the XML file.
sub new {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $class = shift;
    my $file  = shift;

    my $fh;
    if (ref $file) {
        $fh = $file;
    } else {
        unless (open $fh, '<', $file) {
            $log->syslog('err', 'Can\'t open %s: %s', $file, $ERRNO);
            return bless {} => $class;
        }
    }

    my $parser = XML::LibXML->new;
    $parser->line_numbers(1);
    my $doc = eval { $parser->parse_fh($fh) };
    unless ($doc) {
        $log->syslog('err', '%s',
            (ref $EVAL_ERROR) ? $EVAL_ERROR->as_string : $EVAL_ERROR);
        return bless {} => $class;
    }

    my $root = $doc->documentElement;
    my $config;
    if ($root) {
        unless ($root->nodeName eq 'list') {
            $log->syslog('err', 'The root element must be called "list"');
        } elsif (not _checkRequiredSingle($root, 'listname')) {
            ;
        } else {
            my $hash = _getChildren($root);
            if (ref $hash eq 'HASH' and %$hash) {
                $config = $hash;
            }
        }
    }

    if ($config) {
        # Compatibility: single topic on 6.2.24 or earlier.
        $config->{topics} ||= $config->{topic};
        # In old documentation "moderator" was single or multiple editors.
        my $mod = $config->{moderator};
        $config->{editor} ||=
            (ref $mod eq 'ARRAY') ? $mod : (ref $mod eq 'HASH') ? [$mod] : [];
    }

    return bless {config => $config} => $class;
}

# Returns the hash structure.
sub as_hashref {
    return shift->{config} || undef;
}

# Old name: Sympa::Config_XML::createHash().
# Deprecated: No longer used.
#sub _createHash;

# Deprecated: No longer used.
#sub getHash;

# Deprecated: No longer used.
#sub _getRequiredElements;

# No longer used.
#sub _getMultipleAndRequiredChild;

# Old name: Sympa::Config_XML::_getRequiredSingle().
sub _checkRequiredSingle {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $root     = shift;
    my $nodeName = shift;

    my @nodes = $root->getChildrenByTagName($nodeName);
    unless (@nodes) {
        $log->syslog('err', 'Element "%s" is required for the list',
            $nodeName);
        return undef;
    } elsif (1 < scalar @nodes) {
        my @error = map { $_->line_number } @nodes;
        $log->syslog('err',
            'Only one element "%s" is allowed for the list, lines: %s',
            $nodeName, join(", ", @error));
        return undef;
    } elsif ($nodes[0]->getAttribute('multiple')) {
        $log->syslog('err',
            'Attribute multiple not allowed for the element "%s"', $nodeName);
        return undef;
    }

    my $values = _getChildren($nodes[0]);
    if (not $values or ref $values) {
        return undef;
    }

    return 1;
}

# Gets $node's children (elements, text, cdata section) and their values
# recursively.
# IN :  -$node
# OUT : -$hash : hash of children and their contents if elements, or
#        $string : value of cdata section or of text content
sub _getChildren {
    $log->syslog('debug3', '(%s)', @_);
    my $node = shift;

    # return value
    my $hash   = {};
    my $string = "";
    my $return = "empty";    # "hash", "string", "empty"

    my $error          = 0;  # children not homogeneous
    my $multiple_nodes = {};

    my @nodeList = $node->childNodes();

    foreach my $child (@nodeList) {
        my $type      = $child->nodeType;
        my $childName = $child->nodeName;

        if ($type == 1) {
            # ELEMENT_NODE
            my $values = _getChildren($child);
            return undef unless defined $values;

            if ($child->getAttribute('multiple')) {
                push @{$multiple_nodes->{$childName}}, $values;
            } else {
                # Verify single nodes.
                my @sisters = $node->getChildrenByTagName($childName);
                if (1 < scalar @sisters) {
                    $log->syslog(
                        'err',
                        'Element "%s" is not declared in multiple but it is: lines %s',
                        $childName,
                        join(', ', map { $_->line_number } @sisters)
                    );
                    return undef;
                }

                if (ref($values) eq "HASH") {
                    foreach my $k (keys %$values) {
                        $hash->{$childName}{$k} = $values->{$k};
                    }
                } else {
                    $hash->{$childName} = $values;
                }
            }

            if ($return eq "string") {
                $error = 1;
            }
            $return = "hash";
        } elsif ($type == 3) {
            # TEXT_NODE
            my $value = Encode::encode_utf8($child->nodeValue);
            $value =~ s/^\s+//;
            unless ($value eq "") {
                $string = $string . $value;
                if ($return eq "hash") {
                    $error = 1;
                }
                $return = "string";
            }
        } elsif ($type == 4) {
            # CDATA_SECTION_NODE
            $string = $string . Encode::encode_utf8($child->nodeValue);
            if ($return eq "hash") {
                $error = 1;
            }
            $return = "string";
        }

        ## error
        if ($error) {
            $log->syslog('err',
                '(%s) The children are not homogeneous, line %s',
                $node->nodeName, $node->line_number());
            return undef;
        }
    }

    ## return
    foreach my $array (keys %$multiple_nodes) {
        $hash->{$array} = $multiple_nodes->{$array};
    }

    if ($return eq "hash") {
        return $hash;
    } elsif ($return eq "string") {
        $string =~ s/^\s*//;
        $string =~ s/\s*$//;
        return $string;
    } else {    # "empty"
        return "";
    }
}

# Deprecated: No longer used.
#sub _verify_single_nodes;

# Deprecated: No longer used.
#sub _find_lines;

1;
