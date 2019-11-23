# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2019 The Sympa Community. See the AUTHORS.md file
# at the top-level directory of this distribution and at
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
use XML::LibXML;

use Sympa::Log;

my $log = Sympa::Log->instance;

#########################################
# new
#########################################
# constructor of the class Config_XML :
#   parse the xml file
#
# IN : -$class
#      -$fh :  file handler on the xml file
#########################################
sub new {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $class = shift;
    my $path  = shift;

    my $fh;
    unless (open $fh, '<', $path) {
        $log->syslog('err', 'Can\'t open %s: $m', $path);
        return bless {} => $class;
    }

    my $self   = {};
    my $parser = XML::LibXML->new();
    $parser->line_numbers(1);
    my $doc = $parser->parse_fh($fh);

    $self->{'root'} = $doc->documentElement();

    return bless $self => $class;
}

# Returns the hash structure.
sub as_hashref {
    $log->syslog('debug2', '(%s)', @_);
    my $self = shift;

    return undef unless $self->{root};
    return undef unless $self->_createHash;

    my $phash = {%{$self->{config} || {}}};
    # Compatibility: single topic on 6.2.24 or earlier.
    $phash->{topics} ||= $phash->{topic};
    # In old documentation "moderator" was single or multiple editors.
    my $mod = $phash->{moderator};
    $phash->{editor} ||=
        (ref $mod eq 'ARRAY') ? $mod : (ref $mod eq 'HASH') ? [$mod] : [];

    return $phash;
}

# Create a hash used to create a list. Check elements unicity when their are
# not declared multiple.
# Old name: Sympa::Config_XML::createHash().
sub _createHash {
    my $self = shift;

    unless ($self->{'root'}->nodeName eq 'list') {
        $log->syslog('err', 'The root element must be called "list"');
        return undef;
    }

    unless (defined $self->_getRequiredElements()) {
        $log->syslog('err', 'Error in required elements');
        return undef;
    }

    if ($self->{'root'}->hasChildNodes()) {
        my $hash = _getChildren($self->{'root'});
        unless ($hash) {
            $log->syslog('err', 'Error in list elements');
            return undef;
        } elsif (ref $hash eq 'HASH') {
            $self->{config} = {%$hash};
        } else {    # a string
            $log->syslog('err', 'The list\'s children are not homogeneous');
            return undef;
        }
    }
    return 1;
}

# Deprecated: No longer used.
#sub getHash;

#################################################################
# _getRequiredElements
#################################################################
# get all obligatory elements and store them :
#  single : listname
# remove it in order to the later recursive call
#
# IN : -$self
# OUT : -1 or undef
#################################################################
sub _getRequiredElements {
    $log->syslog('debug3', @_);
    my $self = shift;

    # listname element is obligatory
    unless ($self->_getRequiredSingle('listname')) {
        return undef;
    }
    return 1;
}

####################################################
# _getMultipleAndRequiredChild  : no used anymore
####################################################
# get all nodes with name $nodeName and check if
#  they contain the child $childName and store them
#
# IN : -$self
#      -$nodeName
#      -$childName
# OUT : - the number of node with the name $nodeName
####################################################
sub _getMultipleAndRequiredChild {
    my $self      = shift;
    my $nodeName  = shift;
    my $childName = shift;
    $log->syslog('debug3', '(%s, %s)', $nodeName, $childName);

    my @nodes = $self->{'root'}->getChildrenByTagName($nodeName);

    unless (defined _verify_single_nodes(\@nodes)) {
        return undef;
    }

    foreach my $o (@nodes) {
        my @child = $o->getChildrenByTagName($childName);
        if ($#child < 0) {
            $log->syslog('err',
                'Element "%s" is required for element "%s", line: %s',
                $childName, $nodeName, $o->line_number());
            return undef;
        }

        my $hash = _getChildren($o);
        unless (defined $hash) {
            $log->syslog('err', 'Error on _getChildren(%s)', $o->nodeName);
            return undef;
        }

        push @{$self->{'config'}{$nodeName}}, $hash;
        $self->{'root'}->removeChild($o);
    }
    return ($#nodes + 1);
}

############################################
# _getRequiredSingle
############################################
# get the node with name $nodeName and check
#  its unicity and store it
#
# IN : -$self
#      -$nodeName
# OUT : -1 or undef
############################################
sub _getRequiredSingle {
    my $self     = shift;
    my $nodeName = shift;
    $log->syslog('debug3', '(%s)', $nodeName);

    my @nodes = $self->{'root'}->getChildrenByTagName($nodeName);

    unless (_verify_single_nodes(\@nodes)) {
        return undef;
    }

    if ($#nodes < 0) {
        $log->syslog('err', 'Element "%s" is required for the list',
            $nodeName);
        return undef;
    }

    if ($#nodes > 0) {
        my @error;
        foreach my $i (@nodes) {
            push(@error, $i->line_number());
        }
        $log->syslog('err',
            'Only one element "%s" is allowed for the list, lines: %s',
            $nodeName, join(", ", @error));
        return undef;
    }

    my $node = shift(@nodes);

    if ($node->getAttribute('multiple')) {
        $log->syslog('err',
            'Attribute multiple=1 not allowed for the element "%s"',
            $nodeName);
        return undef;
    }

    if ($nodeName eq 'type') {
        ## the list template creation without family context

        my $value = $node->textContent;
        $value =~ s/^\s*//;
        $value =~ s/\s*$//;
        $self->{$nodeName} = $value;

    } else {
        my $values = _getChildren($node);
        unless (defined $values) {
            $log->syslog('err', 'Error on _getChildren(%s)', $node->nodeName);
            return undef;
        }

        if (ref($values) eq "HASH") {
            foreach my $k (keys %$values) {
                $self->{'config'}{$nodeName}{$k} = $values->{$k};
            }
        } else {
            $self->{'config'}{$nodeName} = $values;
        }
    }

    $self->{'root'}->removeChild($node);
    return 1;
}

##############################################
# _getChildren
##############################################
# get $node's children (elements, text,
# cdata section) and their values
#  it is a recursive call
#
# IN :  -$node
# OUT : -$hash : hash of children and
#         their contents if elements
#        or
#        $string : value of cdata section
#         or of text content
##############################################
sub _getChildren {
    my $node = shift;
    $log->syslog('debug3', '(%s)', $node->nodeName);

    # return value
    my $hash   = {};
    my $string = "";
    my $return = "empty";    # "hash", "string", "empty"

    my $error          = 0;  # children not homogeneous
    my $multiple_nodes = {};

    my @nodeList = $node->childNodes();

    unless (_verify_single_nodes(\@nodeList)) {
        return undef;
    }

    foreach my $child (@nodeList) {
        my $type      = $child->nodeType;
        my $childName = $child->nodeName;

        # ELEMENT_NODE
        if ($type == 1) {
            my $values = _getChildren($child);
            unless (defined $values) {
                $log->syslog('err', 'Error on _getChildren(%s)', $childName);
                return undef;
            }

            ## multiple
            if ($child->getAttribute('multiple')) {
                push @{$multiple_nodes->{$childName}}, $values;

                ## single
            } else {
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

            # TEXT_NODE
        } elsif ($type == 3) {
            my $value = Encode::encode_utf8($child->nodeValue);
            $value =~ s/^\s+//;
            unless ($value eq "") {
                $string = $string . $value;
                if ($return eq "hash") {
                    $error = 1;
                }
                $return = "string";
            }

            # CDATA_SECTION_NODE
        } elsif ($type == 4) {
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

##################################################
# _verify_single_nodes
##################################################
# check the uniqueness(in a node list) for a node not
#  declared  multiple.
# (no attribute multiple = "1")
#
# IN :  -$nodeList : ref on the array of nodes
# OUT : -1 or undef
##################################################
sub _verify_single_nodes {
    my $nodeList = shift;
    $log->syslog('debug3', '');

    my $error = 0;
    my %error_nodes;
    my $nodeLines = _find_lines($nodeList);

    foreach my $node (@$nodeList) {
        if ($node->nodeType == 1) {    # ELEMENT_NODE
            unless ($node->getAttribute("multiple")) {
                my $name = $node->nodeName;
                if ($#{$nodeLines->{$name}} > 0) {
                    $error_nodes{$name} = 1;
                }
            }
        }
    }
    foreach my $node (keys %error_nodes) {
        my $lines = join ', ', @{$nodeLines->{$node}};
        $log->syslog('err',
            'Element %s is not declared in multiple but it is: lines %s',
            $node, $lines);
        $error = 1;
    }

    if ($error) {
        return undef;
    }
    return 1;
}

###############################################
# _find_lines
###############################################
# make a hash : keys are node names, values
#  are arrays of their line occurrences
#
# IN  : - $nodeList : ref on a array of nodes
# OUT : - $hash : ref on the hash defined
###############################################
sub _find_lines {
    my $nodeList = shift;
    $log->syslog('debug3', '');
    my $hash = {};

    foreach my $node (@$nodeList) {
        if ($node->nodeType == 1) {    # ELEMENT_NODE
            push @{$hash->{$node->nodeName}}, $node->line_number();
        }
    }
    return $hash;
}

1;
