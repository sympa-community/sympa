# List.pm -  This module provides parsing functions for sympa template files.
# These templates consists of text files including variables and directives
# (IF, FOREACH, INCLUDE, PARSE,...)
# RCS Identication ; $Revision$ ; $Date$ 
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

use FileHandle;

my ($index, @t, $data, $internal);

## The main parsing sub
sub parse_tpl {
    my ($template, $output);
    ($data, $template, $output) = @_;

    print STDERR "\tsub parse_tpl $template\n" if $opt_p;

    my ($hash, $foreach);
    
    my ($old_index, $old_data) = ($index, $data);
    my @old_t = @t;

    my @old_mode = ($*, $/);
    ($*, $/) = (0, "\n");

    my $old_desc = select;
    select $output;
     
    ## Parses the HTML template
    ## Possible syntax of templates are 
    ## [var] for variables
    ## [IF var]...[ENDIF]
    ## [IF var=xx]...[ELSE]..[ENDIF]
    ## [FOREACH item IN list]...[item->NAME]...[END]
    ## [INCLUDE file]
    ## [PARSE file]

    my $fh = new FileHandle $template;

    $index = -1;
    @t = <$fh>;
    close $fh;

    &process(1);

    select $old_desc;

    ($*, $/) = @old_mode;

    ($index, $data) = ($old_index, $old_data);
    @t = @old_t;
}

return 1;

## Processes [SET xx=yy] 
sub do_setvar {
    my $echo = shift;

    if ($echo && /\[\s*SET\s+(\w+)\s*\=\s*(\w+)\->(\w+)\s*\]/i) {
	if (ref ($data->{$2})) {
	    $data->{$1} = $data->{$2}{$3};
	}
    }elsif ($echo && /\[\s*SET\s+(\w+)\s*\=\s*(\d+)\s*\]/i) {
	$data->{$1} = $2;
    }

    return;
}

## Processe [INCLUDE 'file']
sub do_include {
    my $file = pop;

    my $fh = new FileHandle $file;

    print <$fh>;
    close $fh;
}

## Processe [IF ...]
## $echo possible values : 0, 1, -1
sub do_if {
    my ($echo) = @_;

    print STDERR "[$index]\tsub do_if ($echo)\n" if $opt_p;
    print STDERR "\t$t[$index]" if $opt_p;

    $echo = -1 if ($echo == 1);

    while ($_ = $t[$index]) {
	
	unless ($echo == 0 ) {

	    if (/\[\s*(ELSE|ELSIF)\s+.*\]/i and ($echo == 1)) {
		$echo = 0;

	    }else {
		if (/\[\s*(IF|ELSIF)\s+(\w+)\s*\]/i) {
		    $echo *= -1 if ($data->{$2});
		    
		}elsif (/\[\s*(IF|ELSIF)\s+!\s*(\w+)\s*\]/i) {
		    $echo *= -1 if (! $data->{$2});
		    
		}elsif (/\[\s*(IF|ELSIF)\s+(\w+)\-\>(\w+)\s*\]/i) {
		    $echo *= -1 if (defined $data->{$2} && $data->{$2}{$3});
		    
		}elsif (/\[\s*(IF|ELSIF)\s+!\s*(\w+)\-\>(\w+)\s*\]/i) {
		    $echo *= -1 if ((! defined $data->{$2}) || (! $data->{$2}{$3}));
		    
		}elsif (/\[\s*(IF|ELSIF)\s+(\w+)\s*(=|<>)\s*(\S+)\s*\]/i) {
		    $echo *= -1  if ( ( ($3 eq "=") and ($data->{$2} eq $4) ) 
				     or  
				     ( ($3 eq "<>") and ($data->{$2} ne $4) ) );
		    
		}elsif (/\[\s*(IF|ELSIF)\s+(\w+)\-\>(NAME|INDEX)\s*(=|<>)\s*(\S+)\s*\]/i) {
		    $echo *= -1 if ( ( ($4 eq "=") and ($internal->{$2}{$3} eq $5) ) 
				     or  
				     ( ($4 eq "<>") and ($internal->{$2}{$3} ne $5) ) );
	    
		}elsif (/\[\s*(IF|ELSIF)\s+(\w+)\-\>(\w+)\s*(=|<>)\s*(\S+)\s*\]/i) {
		    $echo *= -1 if ( ( ($4 eq "=") and ($data->{$2}{$3} eq $5) ) 
				     or  
				     ( ($4 eq "<>") and ($data->{$2}{$3} ne $5) ) );
		    
		}elsif (/\[\s*ELSE\s*\]/i) {
		    $echo *= -1;
		}
		
	    }
	}
	
	return if (/\[\s*ENDIF\s*\]/i);

	&process($echo);
    }
    return;
}

## Processe [FOREACH x IN y]
sub do_foreach {
    my ($echo) = @_;
    my ($i, $val, $var, $struct, $start);

    print STDERR "[$index]\tsub do_foreach ($echo)\n" if $opt_p;
    print STDERR "\t$t[$index]" if $opt_p;

    if (/\[\s*FOREACH\s+(\w+)\s+IN\s+(\w+)(\->(\w+))?\s*\]/i) {
	($var, $key, $key2) = ($1, $2, $4);
	$start = $index;

	if (($key2 and ref($data->{$key}{$key2}) =~ /HASH/) 
	    or (!$key2 and  ref($data->{$key}) =~ /HASH/)) {
	    
	    if ($key2) {
		$struct = $data->{$key}{$key2};
	    }else {
		$struct = $data->{$key};
	    }

	    my ($prev_data, $prev_internal) = ($data->{$var}, $internal->{$var});
	    foreach $i (sort keys %{$struct}) {
		$data->{$var} = $struct->{$i};

		$internal->{$var}{'NAME'} = $i;
		
		$index = $start;
		
		while ($_ = $t[$index]) {
		    if (/\[END\]/i) {
			last;
		    }
		    
		    &process($echo);
		}
	    }
	    ## Restore context
	    ($data->{$var}, $internal->{$var}) = ($prev_data, $prev_internal);

	}elsif (($key2 and (ref($data->{$key}{$key2}) =~ /ARRAY/))
		or (! $key2 and ref($data->{$key}) =~ /ARRAY/)) {

	    my $i = 0;

	    if ($key2) {
		$struct = $data->{$key}{$key2};
	    }else {
		$struct = $data->{$key};
	    }

	    my ($prev_data, $prev_internal) = ($data->{$var}, $internal->{$var});
	    foreach $val (@{$struct}) {
		$data->{$var} = $val;
		$internal->{$var}{'INDEX'} = $i;

		$index = $start;
		
		while ($_ = $t[$index]) {
		    if (/\[END\]/i) {
			last;
		    }
		    
		    &process($echo);
		}

		$i++;
	    }
	    ## Restore context
	    ($data->{$var}, $internal->{$var}) = ($prev_data, $prev_internal);

	}else {

	    while ($_ = $t[$index]) {
		if (/\[END\]/i) {
		    last;
		}
		
		&process(0);
	    }
	}
    }
    return;
}

## Processes [STOPPARSE]
sub do_stopparse {
    print STDERR "[$index]\tsub do_stopparse\n" if $opt_p;
    print STDERR "\t$t[$index]" if $opt_p;

    $index++;

    while ($_ = $t[$index]) {
	return if /\[\s*STARTPARSE\s*\]/i;
	print;
	$index++;
    }
    return;
}

## Main processing sub
sub process {
    my ($echo) = @_;

    my $backup_echo;

    $echo = 0 if ($echo == -1);

    print STDERR "[$index]\tsub process ($echo)\n" if $opt_p;

    while ($_ = $t[++$index]) {
	if (/\[\s*IF.*\]/i) {
	    &do_if($echo);
	}elsif (/\[\s*ENDIF\s*\]/i) {
	    return;
	}elsif (/\[\s*ELSE\s*\]/i) {
	    return;
	}elsif (/\[\s*ELSIF\s*.*\]/i) {
	    return;
	}elsif (/\[\s*INCLUDE\s+(\w+)\s*\]/i) {
	    &do_include($data->{$1}) if ($echo == 1);
	}elsif (/\[\s*INCLUDE\s+\'(\S+)\'\s*\]/i) {
	    &do_include($1) if ($echo == 1);
	}elsif (/\[\s*PARSE\s+(\w+)\s*\]/i) {
	    parse_tpl($data, $data->{$1}, select()) if ($echo == 1);
	}elsif (/\[\s*PARSE\s+(\w+)\->(\w+)\s*\]/i) {
	    parse_tpl($data, $data->{$1}{$2}, select()) if (defined $data->{$1} && $echo == 1);
	}elsif (/\[\s*PARSE\s+\'(\S+)\'\s*\]/i) {
	    parse_tpl($data, $1, select())  if ($echo == 1);
	}elsif (/\[\s*FOREACH\s+(\w+)\s+IN\s+(\w+(\->\w+)?)\s*\]/i) {
	    &do_foreach($echo);
	}elsif (/\[\s*END\s*\]/i) {
	    return;
	}elsif (/\[\s*STOPPARSE\s*\]/i) {
	    &do_stopparse();
	}elsif (/\[\s*SET\s+(\w+)\s*\=\s*(\w+\->\w+|\d+)\s*\]/i) {
	    &do_setvar($echo);
	}elsif ($echo == 1) {
	    &do_parse();
	    print;
	}
    }
    return;
}

## Instanciates variables
sub do_parse {

    print STDERR "[$index]\tsub do_parse\n" if $opt_p;
    print STDERR "\t$t[$index]" if $opt_p;

    $_ = $t[$index];
    
    s/\[(\w+\-\>\w+|\w+)\]/&do_eval($1)/eg;
    
    return $_;
}

sub do_eval {
    my $var = shift;

    if ($var =~ /^(\w+)\-\>(INDEX|NAME)$/) {
	if (ref($internal->{$1}) eq 'HASH') {
	    return $internal->{$1}{$2};
	}
    }elsif ($var =~ /^(\w+)\-\>(\w+)$/) {
	if (ref($data->{$1}) eq 'HASH') {
	    return $data->{$1}{$2};
	}
    }elsif ($var =~ /^(\w+)$/) {
	return $data->{$1};
    }else {
	print STDERR "Unable to parse '$var'\n" if $opt_p;
    }

    return '';
}
