# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021, 2022, 2024 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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

package Sympa::CLI::instantiate;

use strict;
use warnings;
use Term::ProgressBar;
use XML::LibXML;

use Sympa;
use Conf;
use Sympa::Family;
use Sympa::List;
use Sympa::Log;
use Sympa::Spindle::ProcessRequest;

use parent qw(Sympa::CLI);

use constant _options => qw(close_unknown input_file=s);
use constant _args    => qw(family);

my $log = Sympa::Log->instance;

sub _run {
    my $class   = shift;
    my $options = shift;
    my $family  = shift;

    unless ($options->{input_file}) {
        print STDERR "Error : missing input_file parameter\n";
        exit 1;
    }

    unless (-r $options->{input_file}) {
        printf STDERR "Unable to read %s file\n", $options->{input_file};
        exit 1;
    }

    unless (
        instantiate(
            $family,
            $options->{input_file},
            close_unknown => $options->{close_unknown},
            noout         => ($options->{noout} or not $class->istty(2)),
        )
    ) {
        print STDERR "\nImpossible family instantiation : action stopped \n";
        exit 1;
    }

    my %result;
    my $err = get_instantiation_results($family, \%result);

    unless ($options->{noout}) {
        print STDOUT "@{$result{'info'}}";
        print STDOUT "@{$result{'warn'}}";
    }
    if ($err >= 0) {
        print STDERR "@{$result{'errors'}}";
        exit 1;
    }

    exit 0;
}

# instantiate family action :
#  - create family lists if they are not
#  - update family lists if they already exist
#
# IN : -$family
#      -$xml_fh : file handle on the xml file
#      -%options
#        - close_unknown : true if must close old lists undefined in new
#                          instantiation
# OUT : -1 or undef
# Old name: Sympa::Family::instantiate(), instantiate() in sympa.pl.
sub instantiate {
    $log->syslog('debug2', '(%s, %s, ...)', @_);
    my $family   = shift;
    my $xml_file = shift;
    my %options  = @_;

    ## all the description variables are emptied.
    _initialize_instantiation($family);

    ## get the currently existing lists in the family
    my $previous_family_lists = {
        (   map { $_->{name} => $_ }
                @{Sympa::List::get_lists($family, no_check_family => 1) || []}
        )
    };

    ## Splits the family description XML file into a set of list description
    ## xml files
    ## and collects lists to be created in $list_to_generate.
    my $list_to_generate = _split_xml_file($family, $xml_file);
    unless ($list_to_generate) {
        $log->syslog('err', 'Errors during the parsing of family xml file');
        return undef;
    }

    my $created = 0;
    my $total;
    my $progress;
    unless (@$list_to_generate) {
        $log->syslog('err', 'No list found in XML file %s.', $xml_file);
        $total = 0;
    } else {
        $total    = scalar @$list_to_generate;
        $progress = Term::ProgressBar->new(
            {   name   => 'Creating lists',
                count  => $total,
                ETA    => 'linear',
                silent => $options{noout},
            }
        );
        $progress->max_update_rate(1);
    }
    my $next_update = 0;

    # EACH FAMILY LIST
    foreach my $listname (@$list_to_generate) {
        my $path = $family->{'dir'} . '/' . $listname . '.xml';
        my $list = Sympa::List->new($listname, $family->{'domain'},
            {no_check_family => 1});

        if ($list) {
            ## LIST ALREADY EXISTING
            delete $previous_family_lists->{$list->{'name'}};

            # Update list config.
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context          => $family,
                action           => 'update_automatic_list',
                parameters       => {file => $path},
                sender           => Sympa::get_address($family, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push(@{$family->{'errors'}{'update_list'}}, $list->{'name'});
                $list->set_status_error_config('instantiation_family',
                    $family->{'name'});
                next;
            }
        } else {
            # FIRST LIST CREATION

            ## Create the list
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context          => $family,
                action           => 'create_automatic_list',
                listname         => $listname,
                parameters       => {file => $path},
                sender           => Sympa::get_address($family, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push @{$family->{'errors'}{'create_list'}}, $listname;
                next;
            }

            $list = Sympa::List->new($listname, $family->{'domain'},
                {no_check_family => 1});

            ## aliases
            if (grep { $_->[1] eq 'notice' and $_->[2] eq 'auto_aliases' }
                @{$spindle->{stash} || []}) {
                push(
                    @{$family->{'created_lists'}{'with_aliases'}},
                    $list->{'name'}
                );
            } else {
                $family->{'created_lists'}{'without_aliases'}{$list->{'name'}}
                    = $list->{'name'};
            }
        }

        $created++;
        $progress->message(
            sprintf(
                "List \"%s\" (%i/%i) created/updated",
                $list->{'name'}, $created, $total
            )
        );
        $next_update = $progress->update($created) // 0
            if $created > $next_update;
    }

    $progress->update($total) if $progress;

    ## PREVIOUS LIST LEFT
    foreach my $l (keys %{$previous_family_lists}) {
        my $list;
        unless ($list =
            Sympa::List->new($l, $family->{'domain'}, {no_check_family => 1}))
        {
            push(@{$family->{'errors'}{'previous_list'}}, $l);
            next;
        }

        my $answer;
        unless ($options{close_unknown}) {
            #while ($answer ne 'y' and $answer ne 'n') {
            print STDOUT
                "The list $l isn't defined in the new instantiation family, do you want to close it ? (y or n)";
            $answer = <STDIN>;
            chomp($answer);
            #######################
            $answer ||= 'y';
            #}
        }
        if ($options{close_unknown} or $answer eq 'y') {
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context          => $family->{'domain'},
                action           => 'close_list',
                current_list     => $list,
                sender           => Sympa::get_address($family, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push @{$family->{'family_closed'}{'impossible'}},
                    $list->{'name'};
            }
            push(@{$family->{'family_closed'}{'ok'}}, $list->{'name'});

        } elsif (lc($answer) eq 'n') {
            next;
        } else {
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context      => $family,
                action       => 'update_automatic_list',
                current_list => $list,
                parameters   => {file => $list->{'dir'} . '/instance.xml'},
                sender       => Sympa::get_address($family, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push(@{$family->{'errors'}{'update_list'}}, $list->{'name'});
                $list->set_status_error_config('instantiation_family',
                    $family->{'name'});
                next;
            }
        }
    }

    return 1;
}

# return a string of instantiation results
#
# IN : -$family
#
# OUT : -$string
# Old name: Sympa::Family::get_instantiation_results(),
#   get_instantiation_results() in sympa.pl..
sub get_instantiation_results {
    my ($family, $result) = @_;
    $log->syslog('debug3', '(%s)', $family->{'name'});

    $result->{'errors'} = ();
    $result->{'warn'}   = ();
    $result->{'info'}   = ();
    my $string;

    unless ($#{$family->{'errors'}{'create_hash'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list generation because errors in xml file for : \n  "
                . join(", ", @{$family->{'errors'}{'create_hash'}}) . "\n"
        );
    }

    unless ($#{$family->{'errors'}{'create_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list creation for : \n  "
                . join(", ", @{$family->{'errors'}{'create_list'}}) . "\n"
        );
    }

    unless ($#{$family->{'errors'}{'listname_already_used'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list creation because listname is already used (orphelan list or in another family) for : \n  "
                . join(", ", @{$family->{'errors'}{'listname_already_used'}})
                . "\n"
        );
    }

    unless ($#{$family->{'errors'}{'update_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list updating for : \n  "
                . join(", ", @{$family->{'errors'}{'update_list'}}) . "\n"
        );
    }

    unless ($#{$family->{'errors'}{'previous_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nExisted lists from the lastest instantiation impossible to get and not anymore defined in the new instantiation : \n  "
                . join(", ", @{$family->{'errors'}{'previous_list'}}) . "\n"
        );
    }

    # $string .= "\n****************************************\n";

    unless ($#{$family->{'created_lists'}{'with_aliases'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists have been created and aliases are ok :\n  "
                . join(", ", @{$family->{'created_lists'}{'with_aliases'}})
                . "\n"
        );
    }

    my $without_aliases = $family->{'created_lists'}{'without_aliases'};
    if (ref $without_aliases) {
        if (scalar %{$without_aliases}) {
            $string =
                "\nThese lists have been created but aliases need to be installed : \n";
            foreach my $l (keys %{$without_aliases}) {
                $string .= " $without_aliases->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    unless ($#{$family->{'updated_lists'}{'aliases_ok'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists have been updated and aliases are ok :\n  "
                . join(", ", @{$family->{'updated_lists'}{'aliases_ok'}})
                . "\n"
        );
    }

    my $aliases_to_install = $family->{'updated_lists'}{'aliases_to_install'};
    if (ref $aliases_to_install) {
        if (scalar %{$aliases_to_install}) {
            $string =
                "\nThese lists have been updated but aliases need to be installed : \n";
            foreach my $l (keys %{$aliases_to_install}) {
                $string .= " $aliases_to_install->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    my $aliases_to_remove = $family->{'updated_lists'}{'aliases_to_remove'};
    if (ref $aliases_to_remove) {
        if (scalar %{$aliases_to_remove}) {
            $string =
                "\nThese lists have been updated but aliases need to be removed : \n";
            foreach my $l (keys %{$aliases_to_remove}) {
                $string .= " $aliases_to_remove->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    # $string .= "\n****************************************\n";

    unless ($#{$family->{'generated_lists'}{'file_error'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nThese lists have been generated but they are in status error_config because of errors while creating list config files :\n  "
                . join(", ", @{$family->{'generated_lists'}{'file_error'}})
                . "\n"
        );
    }

    my $constraint_error = $family->{'generated_lists'}{'constraint_error'};
    if (ref $constraint_error) {
        if (scalar %{$constraint_error}) {
            $string =
                "\nThese lists have been generated but there are in status error_config because of errors on parameter constraint :\n";
            foreach my $l (keys %{$constraint_error}) {
                $string .= " $l : " . $constraint_error->{$l} . "\n";
            }
            push(@{$result->{'errors'}}, $string);
        }
    }

    # $string .= "\n****************************************\n";

    unless ($#{$family->{'family_closed'}{'ok'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists don't belong anymore to the family, they are in status family_closed :\n  "
                . join(", ", @{$family->{'family_closed'}{'ok'}}) . "\n"
        );
    }

    unless ($#{$family->{'family_closed'}{'impossible'}} < 0) {
        push(
            @{$result->{'warn'}},
            "\nThese lists don't belong anymore to the family, but they can't be set in status family_closed :\n  "
                . join(", ", @{$family->{'family_closed'}{'impossible'}})
                . "\n"
        );
    }

    unshift @{$result->{'errors'}},
        "\n********** ERRORS IN INSTANTIATION of $family->{'name'} FAMILY ********************\n"
        if ($#{$result->{'errors'}} > 0);
    unshift @{$result->{'warn'}},
        "\n********** WARNINGS IN INSTANTIATION of $family->{'name'} FAMILY ********************\n"
        if ($#{$result->{'warn'}} > 0);
    unshift @{$result->{'info'}},
        "\n\n******************************************************************************\n"
        . "\n******************** INSTANTIATION of $family->{'name'} FAMILY ********************\n"
        . "\n******************************************************************************\n\n";

    return $#{$result->{'errors'}};

}

# initialize vars for instantiation and result
# then to make a string result
#
# IN  : -$family
# OUT : -1
# Old name: Sympa::Family::_initialize_instantiation(),
#   _initialize_instantiation() in sympa.pl.
sub _initialize_instantiation {
    my $family = shift;
    $log->syslog('debug3', '(%s)', $family->{'name'});

    ### info vars for instantiate  ###
    ### returned by                ###
    ### get_instantiation_results  ###

    ## lists in error during creation or updating : LIST FATAL ERROR
    # array of xml file name  : error during xml data extraction
    $family->{'errors'}{'create_hash'} = ();
    ## array of list name : error during list creation
    $family->{'errors'}{'create_list'} = ();
    ## array of list name : error during list updating
    $family->{'errors'}{'update_list'} = ();
    ## array of list name : listname already used (in another family)
    $family->{'errors'}{'listname_already_used'} = ();
    ## array of list name : previous list impossible to get
    $family->{'errors'}{'previous_list'} = ();

    ## created or updated lists
    ## array of list name : aliases are OK (installed or not, according to
    ## status)
    $family->{'created_lists'}{'with_aliases'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $family->{'created_lists'}{'without_aliases'} = {};
    ## array of list name : aliases are OK (installed or not, according to
    ## status)
    $family->{'updated_lists'}{'aliases_ok'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $family->{'updated_lists'}{'aliases_to_install'} = {};
    ## hash of (list name -> aliases) : aliases needed to be removed
    $family->{'updated_lists'}{'aliases_to_remove'} = {};

    ## generated (created or updated) lists in error : no fatal error for the
    ## list
    ## array of list name : error during copying files
    $family->{'generated_lists'}{'file_error'} = ();
    ## hash of (list name -> array of param) : family constraint error
    $family->{'generated_lists'}{'constraint_error'} = {};

    ## lists isn't anymore in the family
    ## array of list name : lists in status family_closed
    $family->{'family_closed'}{'ok'} = ();
    ## array of list name : lists that must be in status family_closed but
    ## they aren't
    $family->{'family_closed'}{'impossible'} = ();

    return 1;
}

# split the xml family file into xml list files. New
# list names are put in the array reference
# and new files are put in
# the family directory
#
# IN : -$family
#      -$xml_fh : file handle on xml file containing description
#               of the family lists
# OUT : -1 (if OK) or undef
# Old name: Sympa::Family::_split_xml_file(), _split_xml_file() in sympa.pl.
sub _split_xml_file {
    my $family   = shift;
    my $xml_file = shift;
    my $root;
    $log->syslog('debug2', '(%s)', $family->{'name'});

    ## parse file
    my $parser = XML::LibXML->new();
    $parser->line_numbers(1);
    my $doc;

    unless ($doc = $parser->parse_file($xml_file)) {
        $log->syslog('err', 'Failed to parse XML file');
        return undef;
    }

    ## the family document
    $root = $doc->documentElement();
    unless ($root->nodeName eq 'family') {
        $log->syslog('err', 'The root element must be called "family"');
        return undef;
    }

    # Lists: Family's elements.
    my @list_to_generate;
    foreach my $list_elt ($root->childNodes()) {

        if ($list_elt->nodeType == 1) {    # ELEMENT_NODE
            unless ($list_elt->nodeName eq 'list') {
                $log->syslog(
                    'err',
                    'Elements contained in the root element must be called "list", line %s',
                    $list_elt->line_number()
                );
                return undef;
            }
        } else {
            next;
        }

        ## listname
        my @children = $list_elt->getChildrenByTagName('listname');

        if ($#children < 0) {
            $log->syslog(
                'err',
                '"listname" element is required in "list" element, line: %s',
                $list_elt->line_number()
            );
            return undef;
        }
        if ($#children > 0) {
            my @error;
            foreach my $i (@children) {
                push(@error, $i->line_number());
            }
            $log->syslog(
                'err',
                'Only one "listname" element is allowed for "list" element, lines: %s',
                join(", ", @error)
            );
            return undef;
        }
        my $listname_elt = shift @children;
        my $listname     = $listname_elt->textContent();
        $listname =~ s/^\s*//;
        $listname =~ s/\s*$//;
        $listname = lc $listname;
        my $filename = $listname . ".xml";

        ## creating list XML document
        my $list_doc =
            XML::LibXML::Document->createDocument($doc->version(),
            $doc->encoding());
        $list_doc->setDocumentElement($list_elt);

        ## creating the list xml file
        unless ($list_doc->toFile("$family->{'dir'}/$filename", 0)) {
            $log->syslog(
                'err',
                'Cannot create list file %s',
                $family->{'dir'} . '/' . $filename,
                $list_elt->line_number()
            );
            return undef;
        }

        push @list_to_generate, $listname;
    }
    return [@list_to_generate];
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-instantiate - Instantiate the lists in a family

=head1 SYNOPSIS

C<sympa instantiate> C<--input-file=>I</path/to/file.xml> [ C<--close-unknown> ] [ C<--noout> ] I<family>C<@@>I<domain>

=head1 DESCRIPTION

Instantiate the lists described in the file.xml in specified family.
The family directory must exist; automatically close undefined lists in a
new instantiation if C<--close_unknown> is specified; do not print report if
C<--noout> is specified.

=cut
