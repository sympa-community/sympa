# Survey.pm - This module includes all survey processing functions
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Survey;

use strict;
require Exporter;
my @ISA = qw(Exporter);
my @EXPORT = qw();

use XML::LibXML;
use Conf;
use Log;


my %survey_format = (  'format' => 'node',
		       's_status' => {'format' => ['pending','closed','open','empty']},
		       's_type' => {'format' => ['anonymous','include_user_email']},
		       's_title' => {'format' => '.*'},
		       'author' => {'format'  => '.*'},
		       'header_text' => {'format'  => '.*','occurrence' => '0-1'},
		       'footer_text' => {'format'  => '.*','occurrence' => '0-1'},
		       'creation_date'  => {'format' => '\d+'},
		       'close_date' => {'format' => '\d+','occurrence' => '0-1'},
		       'last_update' => {'format' => '\d+'},
		       's_edit' => {'format' => '.*'},
		       's_answer' => {'format' => '.*'},
		       's_review' => {'format' => '.*'},
		       'query' => {
			   'format' => 'node',
			   'occurrence' => '1-n',
			   'query_text' => {'format'  => '.*'},
			   'query_comment' => {'format'  => '.*','occurrence' => '0-1'},
			   'query_type' => {'format' => ['text','select','textarea','radio','checkbox']},
			   'answer_type' => {'format' => ['text','boolean','integer']},
			   'lenght' => {'format' => '\d+','occurrence' => '0-1'},
			   'lines' => {'format' => '\d+','occurrence' => '0-1'},
			   'min'  => {'format' => '\d+','occurrence' => '0-1'},
			   'max'  => {'format' => '\d+','occurrence' => '0-1'},
			   'default_answer' => {'format'  => '.*','occurrence' => '0-1'},
			   'possible_answers' => { 'format' => 'node',
						   'occurrence' => '0-n',
						   'answer' => {
						       'format' => '.*',
						       'occurrence' => '1-n',
						   }
					       }              
		       }
		       );


# initialise a new survey file
sub init_survey {

    my $basedir = shift;

    &do_log('debug',"Survey::init_survey ($basedir)");

    $basedir =  $basedir.'/surveys';
    unless (-d $basedir) {
	&do_log('info',"Survey::init_survey_file_survey   creating $basedir");
	# Creation of the survey directory
	unless (mkdir ("$basedir",0777)) {
	    &do_log('err',"Survey::init_survey_file : cannot create surveys directory $basedir reason $!");
	    return undef;
	}	
    }

    my $seq = 0 ;

    if (-f "$basedir/seq") { 
	unless (open FILE, "$basedir/seq") {
	    &do_log('err',"Survey::init_survey : Unable to read survey sequence: $!");
	    return undef;		
	}
	my @content = <FILE>;
	close FILE ;	
	$seq = @content[0];
	&do_log('debug',"xxxxxxxxxxxxxxxxxxxxxxx seq $seq");
	chomp $seq;
	$seq++;
	&do_log('debug',"xxxxxxxxxxxxxxxxxxxxxxx seq $seq");

    }else{
	&do_log('debug',"xxxxxxxxxxxxxxxxxxxxxx not -f $basedir/seq");
	$seq= 1; # this is the first survey for this list
    }
    
    unless (open FILE, ">$basedir/seq") {
	&do_log('err',"Survey::init_survey  : Unable to write survey sequence number: $!");
	return undef;
    }
    print FILE $seq;
    close FILE;
        
    do_log('debug',"Survey::init_survey return $seq   for ($basedir/seq)");
    return ($seq); 
}

# return the number of first free survey number
sub get_survey_id {

    my $basedir = shift;

    &do_log('debug',"Survey::get_survey_id ($basedir)");

    $basedir =  $basedir.'/surveys';
    unless (-d $basedir) {
	&do_log('info',"Survey::get_survey_id creating $basedir");
	# Creation of the survey directory
	unless (mkdir ("$basedir",0777)) {
	    &do_log('err',"Survey::get_survey_id : cannot create surveys directory $basedir reason $!");
	    return undef;
	}	
    }

    my $seq = 0 ;

    unless (-f ">$basedir/seq") {
	# this is the first survey for this list
	unless (open FILE, ">$basedir/seq") {
	    &do_log('err',"Survey::get_survey_id  : Unable to initialize survey sequence: $!");
	    return undef;
	}
	print FILE '1';
	close FILE;
	$seq = 1;
    }else{ 
	unless (open FILE, "$basedir/seq") {
	    &do_log('err',"Survey::get_survey_file : Unable to read survey sequence: $!");
	    return undef;		
	}
	my @content = <FILE>;
	$seq = @content[0];
	chmop $seq; $seq++;
	close FILE ;	
    }
    do_log('debug',"Survey::get_survey_id return $seq"); 
    return ($seq); 
}


# return the path of a survey from (listdir) create directies and sequence file if needed
sub get_survey_file {

    my $basedir = shift;
    my $survey = shift;

    unless ($survey) {
	&do_log('err',"get_survey_file : undefined survey_id");
	return undef;
    }
    unless ($basedir) {
	&do_log('err',"get_survey_file : undefined basedir");
	return undef;
    }
    unless (-d "$basedir/surveys/$survey/") {
	&do_log('err',"get_survey_file : could not find directory $basedir/surveys/$survey/");
	return undef;
    }

    return ("$basedir/surveys/$survey/definition.xml"); 
}


#  return a hash structure from a survey   
sub load_xml_survey {

    my $basedir = shift;
    my $survey_id = shift;

    do_log ('debug',"Survey::load_xml_survey $basedir $survey_id");

    unless ($basedir) {	
	do_log ('err',"Survey::load_xml_survey basedir undefined");
	return undef;
    }
    
    unless ($survey_id) {	
	do_log ('err',"Survey::load_xml_survey survey_id undefined");
	return undef;
    }
    
    my $file = get_survey_file($basedir,$survey_id);
    
    unless (-r $file) {
	return undef;
    }

    my $parser;
    unless ($parser = XML::LibXML->new()) {
	$parser->pedantic_parser(1);
	my $errstring = $parser->get_last_error();
	printf STDERR "-------------------------------------------------- erreur XML\n";
	do_log('err', "Survey::load_xml_survey error XML::LibXML->new() $errstring");
    }
    # $parser->line_numbers(1);
    # $parser->expand_xinclude(1);


    # use of eval because libxml return error to stderr en exit (from fastcgi) if the wml file is buggy. 
    my $xmlsurvey = eval {$parser->parse_file( $file )};
    
    unless ($xmlsurvey) {
	do_log('err', "Survey::load_xml_survey error XML::LibXML->new() incorrect XML ? ");
	return ('status' => 'err');
    }

    my $root = $xmlsurvey->documentElement();
    
    
    unless ($root->nodeName eq 'survey') {
	do_log ('err',"$file not a survey");
	return ('status' => 'err');
    }
        unless ($root->hasChildNodes()) {
	do_log ('info',"empty survey");
	return ('status' => 'err');
    }
    return (&load_survey_node (\%survey_format,$root)) ;
}



sub load_survey_node {
    
    my $format = shift;
    my $node=shift;    
    
    my %survey_node;

    my $hashnode ;

    my @childnodes = $node->getChildnodes;
    foreach my $child (@childnodes) {

	my $name = $child->nodeName;
	next if ($name eq 'text');
	unless (defined $format->{$name}) {
#	    printf "----------------------------------------------------  $name\n";
#	    &dump_var($format,0,\*STDOUT);
	    printf STDERR "load_survey_node unknown tag $name\n";
	    return -1;
	}
	if (($node->hasChildNodes()) && ($format->{$name}{'format'} eq 'node')) { 	    
	    $hashnode = &load_survey_node ($format->{$name},$child);
	}else{
	    $hashnode = $child->textContent;	     
#	     printf "========= $child->textContent\n";
	}
	if ($format->{$name}{'occurrence'} eq '1-n') {
	    push (@{$survey_node{$name}},$hashnode);
        }else{
	    $survey_node{$name} = $hashnode ;
	}
    }
    return \%survey_node;
}



sub dump_xml_survey {

    my ($var, $dir , $seq) = @_;

    &do_log ('debug',"Survey::dump_xml_survey ($var,$dir,$seq)");

    my $file = &get_survey_file ($dir,$seq);
    unless (open (DUMP , ">$file")) {
	do_log ('err',"dump_xml_survey : could not open $file");
	return undef;
    }
    &dump_survey_node ($var,\*DUMP,'survey');
    close DUMP;
}



sub dump_survey_node {

    my ($var, $fd, $nodename, $indent) = @_;


    printf $fd "<survey>\n" if ($nodename eq 'survey') ;

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
#		print $fd "\t"x$level.$index."\n";
		print $fd "$indent<$nodename>\n";
		&dump_survey_node($var->[$index], $fd, $nodename,"$indent\t");
		print $fd "$indent</$nodename>\n";
	    }
	}elsif (ref($var) eq 'HASH') {
	    foreach my $key (keys %{$var}) {
		print $fd "$indent<$key>\n" unless (ref($var->{$key}) eq 'ARRAY') ;
		&dump_survey_node($var->{$key}, $fd, $key,"$indent\t");
		print $fd "$indent</$key>\n" unless (ref($var->{$key}) eq 'ARRAY') ;
	    }    
	}
    }else {
	if (defined $var) {
	    print $fd "$indent$var\n";
	}else {
	    print $fd "UNDEF\n";
	}
    }

    printf $fd "</survey>\n" if ($nodename eq 'survey') ;
}



sub dump_node {
  
    my $indent=shift;
    my $root = shift;
    my @childnodes = $root->getChildnodes;

    foreach my $child (@childnodes) {
	my $name = $child->nodeName;
	next if ($name eq 'text');
	my $lineno = $child->line_number();
	my $content = $child->nodeValue;
	my $content = $child->textContent;

	printf "++$lineno $indent ---$name---$content\n";

	if ($child->hasChildNodes()) { 
	    &dump_node ($indent."\t",$child);
	}
	
    }
}



return 1;
