# tools.pl - This module provides various tools for Sympa
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

package tools;

use strict;

use Time::Local;
use File::Find;
use Digest::MD5;
use HTML::StripScripts::Parser;
use File::Copy::Recursive;
use POSIX qw(strftime mkfifo strtod);
use Sys::Hostname;
use Mail::Header;
use Encode::Guess; ## Usefull when encoding should be guessed
use Encode::MIME::Header;

use Conf;
use Language;
use Log;
use Sympa::Constants;
use Message;

## RCS identification.
#my $id = '@(#)$Id$';

## global var to store a CipherSaber object 
my $cipher;

my $separator="------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------";

## Regexps for list params
## Caution : if this regexp changes (more/less parenthesis), then regexp using it should 
## also be changed
my %regexp = ('email' => '([\w\-\_\.\/\+\=\'\&]+|\".*\")\@[\w\-]+(\.[\w\-]+)+',
	      'family_name' => '[a-z0-9][a-z0-9\-\.\+_]*', 
	      'template_name' => '[a-zA-Z0-9][a-zA-Z0-9\-\.\+_\s]*', ## Allow \s
	      'host' => '[\w\.\-]+',
	      'multiple_host_with_port' => '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*',
	      'listname' => '[a-z0-9][a-z0-9\-\.\+_]{0,49}',
	      'sql_query' => '(SELECT|select).*',
	      'scenario' => '[\w,\.\-]+',
	      'task' => '\w+',
	      'datasource' => '[\w-]+',
	      'uid' => '[\w\-\.\+]+',
	      );

my %openssl_errors = (1 => 'an error occurred parsing the command options',
		      2 => 'one of the input files could not be read',
		      3 => 'an error occurred creating the PKCS#7 file or when reading the MIME message',
		      4 => 'an error occurred decrypting or verifying the message',
		      5 => 'the message was verified correctly but an error occurred writing out the signers certificates');

## Local variables to determine whether to use Text::LineFold or Text::Wrap.
my $use_text_linefold;
my $use_text_wrap;
eval { require Text::LineFold; Text::LineFold->import(0.008); };
if ($@) {
    $use_text_linefold = 0;
    eval { require Text::Wrap; };
    if ($@) {
	$use_text_wrap = 0;
    } else {
	$use_text_wrap = 1;
    }
} else {
    $use_text_linefold = 1;
}

## Sets owner and/or access rights on a file.
sub set_file_rights {
    my %param = @_;
    my ($uid, $gid);

    if ($param{'user'}){
	unless ($uid = (getpwnam($param{'user'}))[2]) {
	    &do_log('err', "User %s can't be found in passwd file",$param{'user'});
	    return undef;
	}
    }else {
	$uid = -1;# "A value of -1 is interpreted by most systems to leave that value unchanged".
    }
    if ($param{'group'}) {
	unless ($gid = (getgrnam($param{'group'}))[2]) {
	    &do_log('err', "Group %s can't be found",$param{'group'});
	    return undef;
	}
    }else {
	$gid = -1;# "A value of -1 is interpreted by most systems to leave that value unchanged".
    }
    unless (chown($uid,$gid, $param{'file'})){
	&do_log('err', "Can't give ownership of file %s to %s.%s: %s",$param{'file'},$param{'user'},$param{'group'}, $!);
	return undef;
    }
    if ($param{'mode'}){
	unless (chmod($param{'mode'}, $param{'file'})){
	    &do_log('err', "Can't change rights of file %s: %s",$Conf::Conf{'db_name'}, $!);
	    return undef;
	}
    }
    return 1;
}

## Returns an HTML::StripScripts::Parser object built with  the parameters provided as arguments.
sub _create_xss_parser {
    my %parameters = @_;
    &do_log('debug3','tools::_create_xss_parser(%s)',$parameters{'robot'});
    my $hss = HTML::StripScripts::Parser->new({ Context => 'Document',
						AllowSrc        => 1,
						AllowHref       => 1,
						AllowRelURL     => 1,
						EscapeFiltered  => 1,
						Rules => {
						    '*' => {
							src => '^http://'.&Conf::get_robot_conf($parameters{'robot'},'http_host'),
						    },
						},
					    });
    return $hss;
}

#*******************************************
# Function : pictures_filename
# Description : return the type of a pictures
#               according to the user
## IN : email, list
#*******************************************
sub pictures_filename {
    my %parameters = @_;
    
    my $login = &md5_fingerprint($parameters{'email'});
    my ($listname, $robot) = ($parameters{'list'}{'name'}, $parameters{'list'}{'domain'});
    
    my $filetype;
    my $filename = undef;
    foreach my $ext ('.gif','.jpg','.jpeg','.png') {
 	if (-f &Conf::get_robot_conf($robot,'pictures_path').'/'.$listname.'@'.$robot.'/'.$login.$ext) {
 	    my $file = $login.$ext;
 	    $filename = $file;
 	    last;
 	}
    }
    return $filename;
}

## Creation of pictures url
## IN : email, list
sub make_pictures_url {
    my %parameters = @_;

    my ($listname, $robot) = ($parameters{'list'}{'name'}, $parameters{'list'}{'domain'});

    my $url;
    if(&pictures_filename('email' => $parameters{'email'}, 'list' => $parameters{'list'})) {
 	$url =  &Conf::get_robot_conf($robot, 'pictures_url').$listname.'@'.$robot.'/'.&pictures_filename('email' => $parameters{'email'}, 'list' => $parameters{'list'});
    }
    else {
 	$url = undef;
    }
    return $url;
}

## Returns sanitized version (using StripScripts) of the string provided as argument.
sub sanitize_html {
    my %parameters = @_;
    &do_log('debug3','tools::sanitize_html(%s,%s)',$parameters{'string'},$parameters{'robot'});

    unless (defined $parameters{'string'}) {
	&do_log('err',"No string provided.");
	return undef;
    }

    my $hss = &_create_xss_parser('robot' => $parameters{'robot'});
    unless (defined $hss) {
	&do_log('err',"Can't create StripScript parser.");
	return undef;
    }
    my $string = $hss -> filter_html($parameters{'string'});
    return $string;
}

## Returns sanitized version (using StripScripts) of the content of the file whose path is provided as argument.
sub sanitize_html_file {
    my %parameters = @_;
    &do_log('debug3','tools::sanitize_html_file(%s)',$parameters{'robot'});

    unless (defined $parameters{'file'}) {
	&do_log('err',"No path to file provided.");
	return undef;
    }

    my $hss = &_create_xss_parser('robot' => $parameters{'robot'});
    unless (defined $hss) {
	&do_log('err',"Can't create StripScript parser.");
	return undef;
    }
    $hss -> parse_file($parameters{'file'});
    return $hss -> filtered_document;
}

## Sanitize all values in the hash $var, starting from $level
sub sanitize_var {
    my %parameters = @_;
    &do_log('debug3','tools::sanitize_var(%s,%s,%s)',$parameters{'var'},$parameters{'level'},$parameters{'robot'});
    unless (defined $parameters{'var'}){
	&do_log('err','Missing var to sanitize.');
	return undef;
    }
    unless (defined $parameters{'htmlAllowedParam'} && $parameters{'htmlToFilter'}){
	&do_log('err','Missing var *** %s *** %s *** to ignore.',$parameters{'htmlAllowedParam'},$parameters{'htmlToFilter'});
	return undef;
    }
    my $level = $parameters{'level'};
    $level |= 0;
    
    if(ref($parameters{'var'})) {
	if(ref($parameters{'var'}) eq 'ARRAY') {
	    foreach my $index (0..$#{$parameters{'var'}}) {
		if ((ref($parameters{'var'}->[$index]) eq 'ARRAY') || (ref($parameters{'var'}->[$index]) eq 'HASH')) {
		    &sanitize_var('var' => $parameters{'var'}->[$index],
				  'level' => $level+1,
				  'robot' => $parameters{'robot'},
				  'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
				  'htmlToFilter' => $parameters{'htmlToFilter'},
				  );
		}
		else {
		    if (defined $parameters{'var'}->[$index]) {
			$parameters{'var'}->[$index] = &escape_html($parameters{'var'}->[$index]);
		    }
		}
	    }
	}
	elsif(ref($parameters{'var'}) eq 'HASH') {
	    foreach my $key (keys %{$parameters{'var'}}) {
		if ((ref($parameters{'var'}->{$key}) eq 'ARRAY') || (ref($parameters{'var'}->{$key}) eq 'HASH')) {
		    &sanitize_var('var' => $parameters{'var'}->{$key},
				  'level' => $level+1,
				  'robot' => $parameters{'robot'},
				  'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
				  'htmlToFilter' => $parameters{'htmlToFilter'},
				  );
		}
		else {
		    if (defined $parameters{'var'}->{$key}) {
			unless ($parameters{'htmlAllowedParam'}{$key}||$parameters{'htmlToFilter'}{$key}) {
			    $parameters{'var'}->{$key} = &escape_html($parameters{'var'}->{$key});
			}
			if ($parameters{'htmlToFilter'}{$key}) {
			    $parameters{'var'}->{$key} = &sanitize_html('string' => $parameters{'var'}->{$key},
									'robot' =>$parameters{'robot'} );
			}
		    }
		}
		
	    }
	}
    }
    else {
	&do_log('err','Variable is neither a hash nor an array.');
	return undef;
    }
    return 1;
}

## Sorts the list of adresses by domain name
## Input : users hash
## Sort by domain.
sub sortbydomain {
   my($x, $y) = @_;
   $x = join('.', reverse(split(/[@\.]/, $x)));
   $y = join('.', reverse(split(/[@\.]/, $y)));
   #print "$x $y\n";
   $x cmp $y;
}

## Sort subroutine to order files in sympa spool by date
sub by_date {
    my @a_tokens = split /\./, $a;
    my @b_tokens = split /\./, $b;

    ## File format : list@dom.date.pid
    my $a_time = $a_tokens[$#a_tokens -1];
    my $b_time = $b_tokens[$#b_tokens -1];

    return $a_time <=> $b_time;

}

## Safefork does several tries before it gives up.
## Do 3 trials and wait 10 seconds * $i between each.
## Exit with a fatal error is fork failed after all
## tests have been exhausted.
sub safefork {
   my($i, $pid);
   
   for ($i = 1; $i < 4; $i++) {
      my($pid) = fork;
      return $pid if (defined($pid));
      do_log ('warning', "Can't create new process in safefork: %m");
      ## should send a mail to the listmaster
      sleep(10 * $i);
   }
   fatal_err("Can't create new process in safefork: %m");
   ## No return.
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
   my($msg, $sender, $robot) = @_;
   do_log('debug3', 'tools::checkcommand(msg->head->get(subject): %s,%s)',$msg->head->get('Subject'), $sender);

   my($avoid, $i);

   my $hdr = $msg->head;

   ## Check for commands in the subject.
   my $subject = $msg->head->get('Subject');

   if ($subject) {
       if ($Conf::Conf{'misaddressed_commands_regexp'} && ($subject =~ /^$Conf::Conf{'misaddressed_commands_regexp'}\b/im)) {
	   return 1;
       }
   }

   return 0 if ($#{$msg->body} >= 5);  ## More than 5 lines in the text.

   foreach $i (@{$msg->body}) {
       if ($Conf::Conf{'misaddressed_commands_regexp'} && ($i =~ /^$Conf::Conf{'misaddressed_commands_regexp'}\b/im)) {
	   return 1;
       }

       ## Control is only applied to first non-blank line
       last unless $i =~ /^\s*$/;
   }
   return 0;
}



## return a hash from the edit_list_conf file
sub load_edit_list_conf {
    my $robot = shift;
    my $list = shift;
    do_log('debug2', 'tools::load_edit_list_conf (%s)',$robot);

    my $file;
    my $conf ;
    
    return undef 
	unless ($file = &tools::get_filename('etc',{},'edit_list.conf',$robot,$list));

    unless (open (FILE, $file)) {
	&do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    my $error_in_conf;
    my $roles_regexp = 'listmaster|privileged_owner|owner|editor|subscriber|default';
    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(($roles_regexp)\s*(,\s*($roles_regexp))*)\s+(read|write|hidden)\s*$/i) {
	    my ($param, $role, $priv) = ($1, $2, $6);
	    my @roles = split /,/, $role;
	    foreach my $r (@roles) {
		$r =~ s/^\s*(\S+)\s*$/$1/;
		if ($r eq 'default') {
		    $error_in_conf = 1;
		    &do_log('notice', '"default" is no more recognised');
		    foreach my $set ('owner','privileged_owner','listmaster') {
			$conf->{$param}{$set} = $priv;
		    }
		    next;
		}
		$conf->{$param}{$r} = $priv;
	    }
	}else{
	    &do_log ('info', 'unknown parameter in %s  (Ignored) %s', "$Conf::Conf{'etc'}/edit_list.conf",$_ );
	    next;
	}
    }

    if ($error_in_conf) {
	unless (&List::send_notify_to_listmaster('edit_list_error', $robot, [$file])) {
	    &do_log('notice',"Unable to send notify 'edit_list_error' to listmaster");
	}
    }
    
    close FILE;
    return $conf;
}


## return a hash from the edit_list_conf file
sub load_create_list_conf {
    my $robot = shift;

    my $file;
    my $conf ;
    
    $file = &tools::get_filename('etc',{}, 'create_list.conf', $robot);
    unless ($file) {
	&do_log('info', 'unable to read %s', Sympa::Constants::DEFAULTDIR . '/create_list.conf');
	return undef;
    }

    unless (open (FILE, $file)) {
	&do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(read|hidden)\s*$/i) {
	    $conf->{$1} = lc($2);
	}else{
	    &do_log ('info', 'unknown parameter in %s  (Ignored) %s', "$Conf::Conf{'etc'}/create_list.conf",$_ );
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
    }else {
	$topic->{'sub'}{$name} = &_add_topic(join ('/', @tree[1..$#tree]), $title);
	return $topic;
    }
}

sub get_list_list_tpl {
    my $robot = shift;

    my $list_conf;
    my $list_templates ;
    unless ($list_conf = &load_create_list_conf($robot)) {
	return undef;
    }
    
    foreach my $dir (
        Sympa::Constants::DEFAULTDIR . '/create_list_templates',
        "$Conf::Conf{'etc'}/create_list_templates",
        "$Conf::Conf{'etc'}/$robot/create_list_templates"
    ) {
	if (opendir(DIR, $dir)) {
	    foreach my $template ( sort grep (!/^\./,readdir(DIR))) {

		my $status = $list_conf->{$template} || $list_conf->{'default'};

		next if ($status eq 'hidden') ;

		$list_templates->{$template}{'path'} = $dir;

		my $locale = &Language::Lang2Locale( &Language::GetLang());
		## Look for a comment.tt2 in the appropriate locale first
		if (-r $dir.'/'.$template.'/'.$locale.'/comment.tt2') {
		    $list_templates->{$template}{'comment'} = $dir.'/'.$template.'/'.$locale.'/comment.tt2';
		}elsif (-r $dir.'/'.$template.'/comment.tt2') {
		    $list_templates->{$template}{'comment'} = $dir.'/'.$template.'/comment.tt2';
		}
	    }
	    closedir(DIR);
	}
    }

    return ($list_templates);
}


#copy a directory and it's content
sub copy_dir {
    my $dir1 = shift;
    my $dir2 = shift;
    &do_log('info','copy_dir %1 %2',$dir1,$dir2);

    return undef unless (-d $dir1) ;
    #return undef unless (-d $dir2) ;
    return (&File::Copy::Recursive::dircopy($dir1,$dir2)) ;
}

#to be used before creating a file in a directory that may not exist already. 
sub mk_parent_dir {
    my $file = shift;
    $file =~ /^(.*)\/([^\/])*$/ ;
    my $dir = $1;

    return 1 if (-d $dir);
    &mkdir_all($dir, 0755);
}

## Recursively create directory and all parent directories
sub mkdir_all {
    my ($path, $mode) = @_;
    my $status = 1;

    ## Change umask to fully apply modes of mkdir()
    my $saved_mask = umask;
    umask 0000;

    return undef if ($path eq '');
    return 1 if (-d $path);

    ## Compute parent path
    my @token = split /\//, $path;
    pop @token;
    my $parent_path = join '/', @token;

    unless (-d $parent_path) {
	unless (&mkdir_all($parent_path, $mode)) {
	    $status = undef;
	}
    }

    if (defined $status) { ## Don't try if parent dir could not be created
	unless (mkdir ($path, $mode)) {
	    $status = undef;
	}
    }

    ## Restore umask
    umask $saved_mask;

    return $status;
}

# shift file renaming it with date. If count is defined, keep $count file and unlink others
sub shift_file {
    my $file = shift;
    my $count = shift;
    do_log('debug', "shift_file ($file,$count)");

    unless (-f $file) {
	do_log('info', "shift_file : unknown file $file");
	return undef;
    }
    
    my @date = localtime (time);
    my $file_extention = strftime("%Y:%m:%d:%H:%M:%S", @date);
    
    unless (rename ($file,$file.'.'.$file_extention)) {
	&do_log('err', "shift_file : Cannot rename file $file to $file.$file_extention" );
	return undef;
    }
    if ($count) {
	$file =~ /^(.*)\/([^\/])*$/ ;
	my $dir = $1;

	unless (opendir(DIR, $dir)) {
	    &do_log('err', "shift_file : Cannot read dir $dir" );
	    return ($file.'.'.$file_extention);
	}
	my $i = 0 ;
	foreach my $oldfile (reverse (sort (grep (/^$file\./,readdir(DIR))))) {
	    $i ++;
	    if ($count lt $i) {
		if (unlink ($oldfile)) { 
		    do_log('info', "shift_file : unlink $oldfile");
		}else{
		    do_log('info', "shift_file : unable to unlink $oldfile");
		}
	    }
	}
    }
    return ($file.'.'.$file_extention);
}

sub get_templates_list {

    my $type = shift;
    my $robot = shift;
    my $list = shift;
    my $options = shift;

    my $listdir;

    do_log('debug', "get_templates_list ($type, $robot, $list)");
    unless (($type == 'web')||($type == 'mail')) {
	do_log('info', 'get_templates_list () : internal error incorrect parameter');
    }

    my $distrib_dir = Sympa::Constants::DEFAULTDIR . '/'.$type.'_tt2';
    my $site_dir = $Conf::Conf{'etc'}.'/'.$type.'_tt2';
    my $robot_dir = $Conf::Conf{'etc'}.'/'.$robot.'/'.$type.'_tt2';

    my @try;

    ## The 'ignore_global' option allows to look for files at list level only
    unless ($options->{'ignore_global'}) {
	push @try, $distrib_dir ;
	push @try, $site_dir ;
	push @try, $robot_dir;
    }    

    if (defined $list) {
	$listdir = $list->{'dir'}.'/'.$type.'_tt2';	
	push @try, $listdir ;
    }

    my $i = 0 ;
    my $tpl;

    foreach my $dir (@try) {
	next unless opendir (DIR, $dir);
	foreach my $file ( grep (!/^\./,readdir(DIR))) {	    
	    ## Subdirectory for a lang
	    if (-d $dir.'/'.$file) {
		my $lang = $file;
		next unless opendir (LANGDIR, $dir.'/'.$lang);
		foreach my $file (grep (!/^\./,readdir(LANGDIR))) {
		    next unless ($file =~ /\.tt2$/);
		    if ($dir eq $distrib_dir){$tpl->{$file}{'distrib'}{$lang} = $dir.'/'.$lang.'/'.$file;}
		    if ($dir eq $site_dir)   {$tpl->{$file}{'site'}{$lang} =  $dir.'/'.$lang.'/'.$file;}
		    if ($dir eq $robot_dir)  {$tpl->{$file}{'robot'}{$lang} = $dir.'/'.$lang.'/'.$file;}
		    if ($dir eq $listdir)    {$tpl->{$file}{'list'}{$lang} = $dir.'/'.$lang.'/'.$file;}
		}
		closedir LANGDIR;

	    }else {
		next unless ($file =~ /\.tt2$/);
		if ($dir eq $distrib_dir){$tpl->{$file}{'distrib'}{'default'} = $dir.'/'.$file;}
		if ($dir eq $site_dir)   {$tpl->{$file}{'site'}{'default'} =  $dir.'/'.$file;}
		if ($dir eq $robot_dir)  {$tpl->{$file}{'robot'}{'default'} = $dir.'/'.$file;}
		if ($dir eq $listdir)    {$tpl->{$file}{'list'}{'default'}= $dir.'/'.$file;}
	    }
	}
	closedir DIR;
    }
    return ($tpl);

}


# return the path for a specific template
sub get_template_path {

    my $type = shift;
    my $robot = shift;
    my $scope = shift;
    my $tpl = shift;
    my $lang = shift || 'default';
    my $list = shift;

    do_log('debug', "get_templates_path ($type,$robot,$scope,$tpl,$lang,%s)", $list->{'name'});

    my $listdir;
    if (defined $list) {
	$listdir = $list->{'dir'};
    }

    unless (($type == 'web')||($type == 'mail')) {
	do_log('info', 'get_templates_path () : internal error incorrect parameter');
    }

    my $distrib_dir = Sympa::Constants::DEFAULTDIR . '/'.$type.'_tt2';
    my $site_dir = $Conf::Conf{'etc'}.'/'.$type.'_tt2';
    $site_dir .= '/'.$lang unless ($lang eq 'default');
    my $robot_dir = $Conf::Conf{'etc'}.'/'.$robot.'/'.$type.'_tt2';
    $robot_dir .= '/'.$lang unless ($lang eq 'default');    

    if ($scope eq 'list')  {
	my $dir = $listdir.'/'.$type.'_tt2';
	$dir .= '/'.$lang unless ($lang eq 'default');
	return $dir.'/'.$tpl ;

    }elsif ($scope eq 'robot')  {
	return $robot_dir.'/'.$tpl;

    }elsif ($scope eq 'site') {
	return $site_dir.'/'.$tpl;

    }elsif ($scope eq 'distrib') {
	return $distrib_dir.'/'.$tpl;

    }

    return undef;
}

sub get_dkim_parameters {

    my $params = shift;

    my $robot = $params->{'robot'};
    my $listname = $params->{'listname'};
    do_log('debug2',"get_dkim_parameters (%s,%s)",$robot, $listname);

    my $data ; my $keyfile ;
    if ($listname) {
	# fetch dkim parameter in list context
	my $list = new List ($listname,$robot);
	unless ($list){
	    do_log('err',"Could not load list %s@%s",$listname, $robot);
	    return undef;
	}

	$data->{'d'} = $list->{'admin'}{'dkim_parameters'}{'signer_domain'};
	if ($list->{'admin'}{'dkim_parameters'}{'signer_identity'}) {
	    $data->{'i'} = $list->{'admin'}{'dkim_parameters'}{'signer_identity'};
	}else{
	    # RFC 4871 (page 21) 
	    $data->{'i'} = $list->{'name'}.'-request@'.$robot;
	}
	
	$data->{'header_list'} = $list->{'admin'}{'dkim_parameters'}{'header_list'};
	$data->{'selector'} = $list->{'admin'}{'dkim_parameters'}{'selector'};
	$keyfile = $list->{'admin'}{'dkim_parameters'}{'private_key_path'};
    }else{
	# in robot context
	$data->{'d'} = &Conf::get_robot_conf($robot, 'dkim_signer_domain');
	$data->{'i'} = &Conf::get_robot_conf($robot, 'dkim_signer_identity');
	$data->{'header_list'} = &Conf::get_robot_conf($robot, 'dkim_header_list');
	$data->{'selector'} = &Conf::get_robot_conf($robot, 'dkim_selector');
	$keyfile = &Conf::get_robot_conf($robot, 'dkim_private_key_path');
    }
    unless (open (KEY, $keyfile)) {
	do_log('err',"Could not read dkim private key %s",&Conf::get_robot_conf($robot, 'dkim_signer_selector'));
	return undef;
    }
    while (<KEY>){
	$data->{'private_key'} .= $_;
    }
    close (KEY);

    return $data;
}

# input a msg as string, output the dkim status
sub dkim_verifier {
    my $msg_as_string = shift;
    my $dkim;

    unless (eval "require Mail::DKIM::Verifier") {
	&do_log('err', "Failed to load Mail::DKIM::verifier perl module, ignoring DKIM signature");
	return undef;
    }
    
    unless ( $dkim = Mail::DKIM::Verifier->new() ){
	&do_log('err', 'Could not create Mail::DKIM::Verifier');
	return undef;
    }
   
    my $temporary_file = $Conf::Conf{'tmpdir'}."/dkim.".$$ ;  
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('err', 'Can\'t store message in file %s', $temporary_file);
	return undef;
    }
    print MSGDUMP $msg_as_string ;

    unless (close(MSGDUMP)){ 
	do_log('err',"unable to dump message in temporary file $temporary_file"); 
	return undef; 
    }

    unless (open (MSGDUMP, "$temporary_file")) {
	&do_log('err', 'Can\'t read message in file %s', $temporary_file);
	return undef;
    }

    # this documented method is pretty but dont validate signatures, why ?
    # $dkim->load(\*MSGDUMP);
    while (<MSGDUMP>){
	chomp;
	s/\015$//;
	$dkim->PRINT("$_\015\012");
    }

    $dkim->CLOSE;
    close(MSGDUMP);
    unlink ($temporary_file);
    
    foreach my $signature ($dkim->signatures) {
	return 1 if  ($signature->result_detail eq "pass");
    }    
    return undef;
}

# input a msg as string, output idem without signature if invalid
sub remove_invalid_dkim_signature {

    do_log('debug',"removing invalide dkim signature");

    my $msg_as_string = shift;

    unless (&tools::dkim_verifier($msg_as_string)){
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	my $entity = $parser->parse_data($msg_as_string);
	unless($entity) {
	    &do_log('err','could not parse message');
	    return $msg_as_string ;
	}
	$entity->head->delete('DKIM-Signature');
	return $entity->as_string;
    }else{
	return ($msg_as_string); # sgnature is valid.
    }
}

# input object msg and listname, output signed message object
sub dkim_sign {
    # in case of any error, this proc MUST return $msg_as_string NOT undef ; this would cause Sympa to send empty mail 
    my $msg_as_string = shift;
    my $data = shift;
    my $dkim_d = $data->{'dkim_d'};    
    my $dkim_i = $data->{'dkim_i'};
    my $dkim_selector = $data->{'dkim_selector'};
    my $dkim_privatekey = $data->{'dkim_privatekey'};
    my $dkim_header_list = $data->{'dkim_header_list'};

    do_log('debug2', 'tools::dkim_sign (msg:%s,dkim_d:%s,dkim_i%s,dkim_selector:%s,dkim_header_list:%s,dkim_privatekey:%s)',substr($msg_as_string,0,30),$dkim_d,$data->{'dkim_i'},$data->{'dkim_selector'},$data->{'dkim_header_list'}, substr($data->{'dkim_privatekey'},0,30));

    unless ($dkim_selector) {
	do_log('err',"DKIM selector is undefined, could not sign message");
	return $msg_as_string;
    }
    unless ($dkim_privatekey) {
	do_log('err',"DKIM key file is undefined, could not sign message");
	return $msg_as_string;
    }
    unless ($dkim_d) {
	do_log('err',"DKIM d= tag is undefined, could not sign message");
	return $msg_as_string;
    }
    
    my $temporary_keyfile = $Conf::Conf{'tmpdir'}."/dkimkey.".$$ ;  
    if (!open(MSGDUMP,"> $temporary_keyfile")) {
	&do_log('err', 'Can\'t store key in file %s', $temporary_keyfile);
	return $msg_as_string;
    }
    print MSGDUMP $dkim_privatekey ;
    close(MSGDUMP);

    unless (eval "require Mail::DKIM::Signer") {
	&do_log('err', "Failed to load Mail::DKIM::signer perl module, ignoring DKIM signature");
	return ($msg_as_string); 
    }
    my $dkim ;
    if ($dkim_i) {
    # create a signer object
	$dkim = Mail::DKIM::Signer->new(
					Algorithm => "rsa-sha1",
					Method    => "relaxed",
					Domain    => $dkim_d,
					Identity  => $dkim_i,
					Selector  => $dkim_selector,
					KeyFile   => $temporary_keyfile,
					);
    }else{
	$dkim = Mail::DKIM::Signer->new(
					Algorithm => "rsa-sha1",
					Method    => "relaxed",
					Domain    => $dkim_d,
					Selector  => $dkim_selector,
					KeyFile   => $temporary_keyfile,
					);
    }
    unless ($dkim) {
	&do_log('err', 'Can\'t create Mail::DKIM::Signer');
	return ($msg_as_string); 
    }    
    my $temporary_file = $Conf::Conf{'tmpdir'}."/dkim.".$$ ;  
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('err', 'Can\'t store message in file %s', $temporary_file);
	return ($msg_as_string); 
    }
    print MSGDUMP $msg_as_string ;
    close(MSGDUMP);

    unless (open (MSGDUMP , $temporary_file)){
	&do_log('err', 'Can\'t read temporary file %s', $temporary_file);
	return undef;
    }

    $dkim->load(\*MSGDUMP);

    close (MSGDUMP);
    unless ($dkim->CLOSE) {
	&do_log('err', 'Cannot sign (DKIM) message');
	return ($msg_as_string); 
    }
    my $message = new Message($temporary_file,'noxsympato');
    unless ($message){
	do_log('err',"unable to load $temporary_file as a message objet");
	return ($msg_as_string); 
    }

    if ($main::options{'debug'}) {
	do_log('debug',"temporary file is $temporary_file");
    }else{
	unlink ($temporary_file);
    }
    unlink ($temporary_keyfile);
#    $dkim->signature->headerlist("Message-ID:Date:From:To:Subject:Sender");
    $dkim->signature->headerlist($dkim_header_list);
    $dkim->signature->prettify;
    
    $message->{'msg'}->head->add('DKIM-signature',$dkim->signature->as_string);

    return $message->{'msg'}->as_string ;
}

# input object msg and listname, output signed message object
sub smime_sign {
    my $in_msg = shift;
    my $list = shift;
    my $robot = shift;

    do_log('debug2', 'tools::smime_sign (%s,%s)',$in_msg,$list);

    my $self = new List($list, $robot);
    my($cert, $key) = &smime_find_keys($self->{dir}, 'sign');
    my $temporary_file = $Conf::Conf{'tmpdir'}."/".$self->get_list_id().".".$$ ;    
    my $temporary_pwd = $Conf::Conf{'tmpdir'}.'/pass.'.$$;

    my ($signed_msg,$pass_option );
    $pass_option = "-passin file:$temporary_pwd" if ($Conf::Conf{'key_passwd'} ne '') ;

    ## Keep a set of header fields ONLY
    ## OpenSSL only needs content type & encoding to generate a multipart/signed msg
    my $dup_msg = $in_msg->dup;
    foreach my $field ($dup_msg->head->tags) {
         next if ($field =~ /^content-type|content-transfer-encoding$/i);
         $dup_msg->head->delete($field);
    }
	    

    ## dump the incomming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('info', 'Can\'t store message in file %s', $temporary_file);
	return undef;
    }
    $dup_msg->print(\*MSGDUMP);
    close(MSGDUMP);

    if ($Conf::Conf{'key_passwd'} ne '') {
	unless ( mkfifo($temporary_pwd,0600)) {
	    do_log('notice', 'Unable to make fifo for %s',$temporary_pwd);
	}
    }
    &do_log('debug', "$Conf::Conf{'openssl'} smime -sign -rand $Conf::Conf{'tmpdir'}"."/rand -signer $cert $pass_option -inkey $key -in $temporary_file");    
    unless (open (NEWMSG,"$Conf::Conf{'openssl'} smime -sign  -rand $Conf::Conf{'tmpdir'}"."/rand -signer $cert $pass_option -inkey $key -in $temporary_file |")) {
    	&do_log('notice', 'Cannot sign message (open pipe)');
	return undef;
    }

    if ($Conf::Conf{'key_passwd'} ne '') {
	unless (open (FIFO,"> $temporary_pwd")) {
	    do_log('notice', 'Unable to open fifo for %s', $temporary_pwd);
	}

	print FIFO $Conf::Conf{'key_passwd'};
	close FIFO;
	unlink ($temporary_pwd);
    }

    my $parser = new MIME::Parser;

    $parser->output_to_core(1);
    unless ($signed_msg = $parser->read(\*NEWMSG)) {
	do_log('notice', 'Unable to parse message');
	return undef;
    }
    unless (close NEWMSG){
	&do_log('notice', 'Cannot sign message (close pipe)');
	return undef;
    } 

    my $status = $?/256 ;
    unless ($status == 0) {
	do_log('notice', 'Unable to S/MIME sign message : status = %d', $status);
	return undef;	
    }

    unlink ($temporary_file) unless ($main::options{'debug'}) ;
    
    ## foreach header defined in  the incomming message but undefined in the
    ## crypted message, add this header in the crypted form.
    my $predefined_headers ;
    foreach my $header ($signed_msg->head->tags) {
	$predefined_headers->{$header} = 1 if ($signed_msg->head->get($header)) ;
    }
    foreach my $header ($in_msg->head->tags) {
	$signed_msg->head->add($header,$in_msg->head->get($header)) unless $predefined_headers->{$header} ;
    }
    
    my $messageasstring = $signed_msg->as_string ;

    return $signed_msg;
}


sub smime_sign_check {
    my $message = shift;

    my $sender = $message->{'sender'};
    my $file = $message->{'filename'};

    do_log('debug2', 'tools::smime_sign_check (message, %s, %s)', $sender, $file);

    my $is_signed = {};
    $is_signed->{'body'} = undef;   
    $is_signed->{'subject'} = undef;

    my $verify ;

    ## first step is the msg signing OK ; /tmp/sympa-smime.$$ is created
    ## to store the signer certificat for step two. I known, that's durty.

    my $temporary_file = $Conf::Conf{'tmpdir'}."/".'smime-sender.'.$$ ;
    my $trusted_ca_options = '';
    $trusted_ca_options = "-CAfile $Conf::Conf{'cafile'} " if ($Conf::Conf{'cafile'});
    $trusted_ca_options .= "-CApath $Conf::Conf{'capath'} " if ($Conf::Conf{'capath'});
    do_log('debug3', "$Conf::Conf{'openssl'} smime -verify  $trusted_ca_options -signer  $temporary_file");

    unless (open (MSGDUMP, "| $Conf::Conf{'openssl'} smime -verify  $trusted_ca_options -signer $temporary_file > /dev/null")) {

	do_log('err', "unable to verify smime signature from $sender $verify");
	return undef ;
    }

    if ($message->{'smime_crypted'}) {
	$message->{'msg'}->head->print(\*MSGDUMP);
	print MSGDUMP "\n";
	print MSGDUMP ${$message->{'msg_as_string'}};
    }else {
	unless (open MSG, $file) {
	    do_log('err', 'Unable to open file %s: %s', $file, $!);
	    return undef;
	}
	print MSGDUMP <MSG>;
    }

    close MSG;
    close MSGDUMP;

    my $status = $?/256 ;
    unless ($status == 0) {
	do_log('err', 'Unable to check S/MIME signature : %s', $openssl_errors{$status});
	return undef ;
    }
    
    ## second step is the message signer match the sender
    ## a better analyse should be performed to extract the signer email. 
    my $signer = smime_parse_cert({file => $temporary_file});

    unless ($signer->{'email'}{lc($sender)}) {
	unlink($temporary_file) unless ($main::options{'debug'}) ;
	&do_log('err', "S/MIME signed message, sender(%s) does NOT match signer(%s)",$sender, join(',', keys %{$signer->{'email'}}));
	return undef;
    }

    &do_log('debug', "S/MIME signed message, signature checked and sender match signer(%s)", join(',', keys %{$signer->{'email'}}));
    ## store the signer certificat
    unless (-d $Conf::Conf{'ssl_cert_dir'}) {
	if ( mkdir ($Conf::Conf{'ssl_cert_dir'}, 0775)) {
	    do_log('info', "creating spool $Conf::Conf{'ssl_cert_dir'}");
	}else{
	    do_log('err', "Unable to create user certificat directory $Conf::Conf{'ssl_cert_dir'}");
	}
    }

    ## It gets a bit complicated now. openssl smime -signer only puts
    ## the _signing_ certificate into the given file; to get all included
    ## certs, we need to extract them from the signature proper, and then
    ## we need to check if they are for our user (CA and intermediate certs
    ## are also included), and look at the purpose:
    ## "S/MIME signing : Yes/No"
    ## "S/MIME encryption : Yes/No"
    my $certbundle = "$Conf::Conf{tmpdir}/certbundle.$$";
    my $tmpcert = "$Conf::Conf{tmpdir}/cert.$$";
    my $nparts = $message->{msg}->parts;
    my $extracted = 0;
    &do_log('debug2', "smime_sign_check: parsing $nparts parts");
    if($nparts == 0) { # could be opaque signing...
	$extracted +=&smime_extract_certs($message->{msg}, $certbundle);
    } else {
	for (my $i = 0; $i < $nparts; $i++) {
	    my $part = $message->{msg}->parts($i);
	    $extracted += &smime_extract_certs($part, $certbundle);
	    last if $extracted;
	}
    }
    
    unless($extracted) {
	&do_log('err', "No application/x-pkcs7-* parts found");
	return undef;
    }

    unless(open(BUNDLE, $certbundle)) {
	&do_log('err', "Can't open cert bundle $certbundle: $!");
	return undef;
    }
    
    ## read it in, split on "-----END CERTIFICATE-----"
    my $cert = '';
    my(%certs);
    while(<BUNDLE>) {
	$cert .= $_;
	if(/^-----END CERTIFICATE-----$/) {
	    my $workcert = $cert;
	    $cert = '';
	    unless(open(CERT, ">$tmpcert")) {
		&do_log('err', "Can't create $tmpcert: $!");
		return undef;
	    }
	    print CERT $workcert;
	    close(CERT);
	    my($parsed) = &smime_parse_cert({file => $tmpcert});
	    unless($parsed) {
		&do_log('err', 'No result from smime_parse_cert');
		return undef;
	    }
	    unless($parsed->{'email'}) {
		&do_log('debug', "No email in cert for $parsed->{subject}, skipping");
		next;
	    }
	    
	    &do_log('debug2', "Found cert for <%s>", join(',', keys %{$parsed->{'email'}}));
	    if ($parsed->{'email'}{lc($sender)}) {
		if ($parsed->{'purpose'}{'sign'} && $parsed->{'purpose'}{'enc'}) {
		    $certs{'both'} = $workcert;
		    &do_log('debug', 'Found a signing + encryption cert');
		}elsif ($parsed->{'purpose'}{'sign'}) {
		    $certs{'sign'} = $workcert;
		    &do_log('debug', 'Found a signing cert');
		} elsif($parsed->{'purpose'}{'enc'}) {
		    $certs{'enc'} = $workcert;
		    &do_log('debug', 'Found an encryption cert');
		}
	    }
	    last if(($certs{'both'}) || ($certs{'sign'} && $certs{'enc'}));
	}
    }
    close(BUNDLE);
    if(!($certs{both} || ($certs{sign} || $certs{enc}))) {
	&do_log('err', "Could not extract certificate for %s", join(',', keys %{$signer->{'email'}}));
	return undef;
    }
    ## OK, now we have the certs, either a combined sign+encryption one
    ## or a pair of single-purpose. save them, as email@addr if combined,
    ## or as email@addr@sign / email@addr@enc for split certs.
    foreach my $c (keys %certs) {
	my $fn = "$Conf::Conf{ssl_cert_dir}/" . &escape_chars(lc($sender));
	if ($c ne 'both') {
	    unlink($fn); # just in case there's an old cert left...
	    $fn .= "\@$c";
	}else {
	    unlink("$fn\@enc");
	    unlink("$fn\@sign");
	}
	&do_log('debug', "Saving $c cert in $fn");
	unless (open(CERT, ">$fn")) {
	    &do_log('err', "Unable to create certificate file $fn: $!");
	    return undef;
	}
	print CERT $certs{$c};
	close(CERT);
    }

    unless ($main::options{'debug'}) {
	unlink($temporary_file);
	unlink($tmpcert);
	unlink($certbundle);
    }

    $is_signed->{'body'} = 'smime';
    
    # futur version should check if the subject was part of the SMIME signature.
    $is_signed->{'subject'} = $signer;
    return $is_signed;
}

# input : msg object, return a new message object encrypted
sub smime_encrypt {
    my $msg_header = shift;
    my $msg_body = shift;
    my $email = shift ;
    my $list = shift ;

    my $usercert;
    my $dummy;
    my $cryptedmsg;
    my $encrypted_body;    

    &do_log('debug2', 'tools::smime_encrypt( %s, %s', $email, $list);
    if ($list eq 'list') {
	my $self = new List($email);
	($usercert, $dummy) = smime_find_keys($self->{dir}, 'encrypt');
    }else{
	my $base = "$Conf::Conf{'ssl_cert_dir'}/".&tools::escape_chars($email);
	if(-f "$base\@enc") {
	    $usercert = "$base\@enc";
	} else {
	    $usercert = "$base";
	}
    }
    if (-r $usercert) {
	my $temporary_file = $Conf::Conf{'tmpdir'}."/".$email.".".$$ ;

	## encrypt the incomming message parse it.
        do_log ('debug3', "tools::smime_encrypt : $Conf::Conf{'openssl'} smime -encrypt -out $temporary_file -des3 $usercert");

	if (!open(MSGDUMP, "| $Conf::Conf{'openssl'} smime -encrypt -out $temporary_file -des3 $usercert")) {
	    &do_log('info', 'Can\'t encrypt message for recipient %s', $email);
	}
## don't; cf RFC2633 3.1. netscape 4.7 at least can't parse encrypted stuff
## that contains a whole header again... since MIME::Tools has got no function
## for this, we need to manually extract only the MIME headers...
##	$msg_header->print(\*MSGDUMP);
##	printf MSGDUMP "\n%s", $msg_body;
	my $mime_hdr = $msg_header->dup();
	foreach my $t ($mime_hdr->tags()) {
	  $mime_hdr->delete($t) unless ($t =~ /^(mime|content)-/i);
	}
	$mime_hdr->print(\*MSGDUMP);

	printf MSGDUMP "\n%s", $msg_body;
	close(MSGDUMP);

	my $status = $?/256 ;
	unless ($status == 0) {
	    do_log('err', 'Unable to S/MIME encrypt message : %s', $openssl_errors{$status});
	    return undef ;
	}

        ## Get as MIME object
	open (NEWMSG, $temporary_file);
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($cryptedmsg = $parser->read(\*NEWMSG)) {
	    do_log('notice', 'Unable to parse message');
	    return undef;
	}
	close NEWMSG ;

        ## Get body
	open (NEWMSG, $temporary_file);
        my $in_header = 1 ;
	while (<NEWMSG>) {
	   if ( !$in_header)  { 
	     $encrypted_body .= $_;       
	   }else {
	     $in_header = 0 if (/^$/); 
	   }
	}						    
	close NEWMSG;

unlink ($temporary_file) unless ($main::options{'debug'}) ;

	## foreach header defined in  the incomming message but undefined in the
        ## crypted message, add this header in the crypted form.
	my $predefined_headers ;
	foreach my $header ($cryptedmsg->head->tags) {
	    $predefined_headers->{$header} = 1 
	        if ($cryptedmsg->head->get($header)) ;
	}
	foreach my $header ($msg_header->tags) {
	    $cryptedmsg->head->add($header,$msg_header->get($header)) 
	        unless $predefined_headers->{$header} ;
	}

    }else{
	do_log ('notice','unable to encrypt message to %s (missing certificat %s)',$email,$usercert);
	return undef;
    }
        
    return $cryptedmsg->head->as_string . "\n" . $encrypted_body;
}

# input : msg object for a list, return a new message object decrypted
sub smime_decrypt {
    my $msg = shift;
    my $list = shift ; ## the recipient of the msg
    
    &do_log('debug2', 'tools::smime_decrypt message msg from %s,%s',$msg->head->get('from'),$list->{'name'});

    ## an empty "list" parameter means mail to sympa@, listmaster@...
    my $dir = $list->{'dir'};
    unless ($dir) {
	$dir = $Conf::Conf{home} . '/sympa';
    }
    my ($certs,$keys) = smime_find_keys($dir, 'decrypt');
    unless (defined $certs && @$certs) {
	do_log('err', "Unable to decrypt message : missing certificate file");
	return undef;
    }

    my $temporary_file = $Conf::Conf{'tmpdir'}."/".$list->get_list_id().".".$$ ;
    my $temporary_pwd = $Conf::Conf{'tmpdir'}.'/pass.'.$$;

    ## dump the incomming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('info', 'Can\'t store message in file %s',$temporary_file);
    }
    $msg->print(\*MSGDUMP);
    close(MSGDUMP);
    
    my ($decryptedmsg, $pass_option, $msg_as_string);
    if ($Conf::Conf{'key_passwd'} ne '') {
	# if password is define in sympa.conf pass the password to OpenSSL using
	$pass_option = "-passin file:$temporary_pwd";	
    }

    ## try all keys/certs until one decrypts.
    while (my $certfile = shift @$certs) {
	my $keyfile = shift @$keys;
	&do_log('debug', "Trying decrypt with $certfile, $keyfile");
	if ($Conf::Conf{'key_passwd'} ne '') {
	    unless (mkfifo($temporary_pwd,0600)) {
		&do_log('err', 'Unable to make fifo for %s', $temporary_pwd);
		return undef;
	    }
	}

	&do_log('debug',"$Conf::Conf{'openssl'} smime -decrypt -in $temporary_file -recip $certfile -inkey $keyfile $pass_option");
	open (NEWMSG, "$Conf::Conf{'openssl'} smime -decrypt -in $temporary_file -recip $certfile -inkey $keyfile $pass_option |");

	if ($Conf::Conf{'key_passwd'} ne '') {
	    unless (open (FIFO,"> $temporary_pwd")) {
		&do_log('notice', 'Unable to open fifo for %s', $temporary_pwd);
		return undef;
	    }
	    print FIFO $Conf::Conf{'key_passwd'};
	    close FIFO;
	    unlink ($temporary_pwd);
	}
	
	while (<NEWMSG>) {
	    $msg_as_string .= $_;
	}
	close NEWMSG ;
	my $status = $?/256;
	
	unless ($status == 0) {
	    do_log('notice', 'Unable to decrypt S/MIME message : %s', $openssl_errors{$status});
	    next;
	}
	
	unlink ($temporary_file) unless ($main::options{'debug'}) ;
	
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($decryptedmsg = $parser->parse_data($msg_as_string)) {
	    &do_log('notice', 'Unable to parse message');
	    last;
	}
    }
	
    unless (defined $decryptedmsg) {
      &do_log('err', 'Message could not be decrypted');
      return undef;
    }

    ## Now remove headers from $msg_as_string
    my @msg_tab = split(/\n/, $msg_as_string);
    my $line;
    do {$line = shift(@msg_tab)} while ($line !~ /^\s*$/);
    $msg_as_string = join("\n", @msg_tab);
    
    ## foreach header defined in the incomming message but undefined in the
    ## decrypted message, add this header in the decrypted form.
    my $predefined_headers ;
    foreach my $header ($decryptedmsg->head->tags) {
	$predefined_headers->{$header} = 1 if ($decryptedmsg->head->get($header)) ;
    }
    
    foreach my $header ($msg->head->tags) {
	$decryptedmsg->head->add($header,$msg->head->get($header)) unless $predefined_headers->{$header} ;
    }
    ## Some headers from the initial message should not be restored
    ## Content-Disposition and Content-Transfer-Encoding if the result is multipart
    $decryptedmsg->head->delete('Content-Disposition') if ($msg->head->get('Content-Disposition'));
    if ($decryptedmsg->head->get('Content-Type') =~ /multipart/) {
	$decryptedmsg->head->delete('Content-Transfer-Encoding') if ($msg->head->get('Content-Transfer-Encoding'));
    }

    return ($decryptedmsg, \$msg_as_string);
}


## Make a multipart/alternative, a singlepart
sub as_singlepart {
    &do_log('debug2', 'tools::as_singlepart()');
    my ($msg, $preferred_type, $loops) = @_;
    my $done = 0;
    $loops++;
    
    unless (defined $msg) {
	&do_log('err', "Undefined message parameter");
	return undef;
    }

    if ($loops > 4) {
	do_log('err', 'Could not change multipart to singlepart');
	return undef;
    }

    if ($msg->effective_type() =~ /^$preferred_type$/) {
	$done = 1;
    }elsif ($msg->effective_type() =~ /^multipart\/alternative/) {
	my @parts = $msg->parts();
	foreach my $index (0..$#parts) {
	    if (($parts[$index]->effective_type() =~ /^$preferred_type$/) ||
		(
		 ($parts[$index]->effective_type() =~ /^multipart\/related$/) &&
		 ($parts[$index]->parts(0)->effective_type() =~ /^$preferred_type$/))) {
		## Only keep the first matching part
		$msg->parts([$parts[$index]]);
		$msg->make_singlepart();
		$done = 1;
		last;
	    }
	}
    }elsif ($msg->effective_type() =~ /multipart\/signed/) {
	my @parts = $msg->parts();
	## Only keep the first part
	$msg->parts([$parts[0]]);
	$msg->make_singlepart();       

	$done ||= &as_singlepart($msg, $preferred_type, $loops);

    }elsif ($msg->effective_type() =~ /^multipart/) {
	my @parts = $msg->parts();
	foreach my $index (0..$#parts) {
            
            next unless (defined $parts[$index]); ## Skip empty parts
 
	    if ($parts[$index]->effective_type() =~ /^multipart\/alternative/) {
		if (&as_singlepart($parts[$index], $preferred_type, $loops)) {
		    $msg->parts([$parts[$index]]);
		    $msg->make_singlepart();
		    $done = 1;
		}
	    }
	}    
    }

    return $done;
}

## Escape characters before using a string within a regexp parameter
## Escaped characters are : @ $ [ ] ( ) ' ! '\' * . + ?
sub escape_regexp {
    my $s = shift;
    my @escaped = ("\\",'@','$','[',']','(',')',"'",'!','*','.','+','?');
    my $backslash = "\\"; ## required in regexp

    foreach my $escaped_char (@escaped) {
	$s =~ s/$backslash$escaped_char/\\$escaped_char/g;
    }

    return $s;
}

## Escape weird characters
sub escape_chars {
    my $s = shift;    
    my $except = shift; ## Exceptions
    my $ord_except = ord($except) if (defined $except);

    ## Escape chars
    ##  !"#$%&'()+,:;<=>?[] AND accented chars
    ## escape % first
    foreach my $i (0x25,0x20..0x24,0x26..0x2c,0x3a..0x3f,0x5b,0x5d,0x80..0x9f,0xa0..0xff) {
	next if ($i == $ord_except);
	my $hex_i = sprintf "%lx", $i;
	$s =~ s/\x$hex_i/%$hex_i/g;
    }
    $s =~ s/\//%a5/g unless ($except eq '/');  ## Special traetment for '/'

    return $s;
}

## Escape shared document file name
## Q-decode it first
sub escape_docname {
    my $filename = shift;
    my $except = shift; ## Exceptions

    ## Q-decode
    $filename = MIME::EncWords::decode_mimewords($filename);

    ## Decode from FS encoding to utf-8
    #$filename = &Encode::decode($Conf::Conf{'filesystem_encoding'}, $filename);

    ## escapesome chars for use in URL
    return &escape_chars($filename, $except);
}

## Convert from Perl unicode encoding to UTF8
sub unicode_to_utf8 {
    my $s = shift;
    
    if (&Encode::is_utf8($s)) {
	return &Encode::encode_utf8($s);
    }

    return $s;
}

## This applies recursively to a data structure
## The transformation subroutine is passed as a ref
sub recursive_transformation {
    my ($var, $subref) = @_;
    
    return unless (ref($var));

    if (ref($var) eq 'ARRAY') {
	foreach my $index (0..$#{$var}) {
	    if (ref($var->[$index])) {
		&recursive_transformation($var->[$index], $subref);
	    }else {
		$var->[$index] = &{$subref}($var->[$index]);
	    }
	}
    }elsif (ref($var) eq 'HASH') {
	foreach my $key (sort keys %{$var}) {
	    if (ref($var->{$key})) {
		&recursive_transformation($var->{$key}, $subref);
	    }else {
		$var->{$key} = &{$subref}($var->{$key});
	    }
	}    
    }
    
    return;
}

## Q-Encode web file name
sub qencode_filename {
    my $filename = shift;

    ## We don't use MIME::Words here because it does not encode properly Unicode
    ## Check if string is already Q-encoded first
    ## Also check if the string contains 8bit chars
    unless ($filename =~ /\=\?UTF-8\?/ ||
	    $filename =~ /^[\x00-\x7f]*$/) {

	## Don't encode elements such as .desc. or .url or .moderate or .extension
	my $part = $filename;
	my ($leading, $trailing);
	$leading = $1 if ($part =~ s/^(\.desc\.)//); ## leading .desc
	$trailing = $1 if ($part =~ s/((\.\w+)+)$//); ## trailing .xx

	my $encoded_part = MIME::EncWords::encode_mimewords($part, Charset => 'utf8', Encoding => 'q', MaxLineLen => 1000, Minimal => 'NO');
	

	$filename = $leading.$encoded_part.$trailing;
    }
    
    return $filename;
}

## Q-Decode web file name
sub qdecode_filename {
    my $filename = shift;
    
    ## We don't use MIME::Words here because it does not encode properly Unicode
    ## Check if string is already Q-encoded first
    #if ($filename =~ /\=\?UTF-8\?/) {
    $filename = Encode::encode_utf8(&Encode::decode('MIME-Q', $filename));
    #}
    
    return $filename;
}

## Unescape weird characters
sub unescape_chars {
    my $s = shift;

    $s =~ s/%a5/\//g;  ## Special traetment for '/'
    foreach my $i (0x20..0x2c,0x3a..0x3f,0x5b,0x5d,0x80..0x9f,0xa0..0xff) {
	my $hex_i = sprintf "%lx", $i;
	my $hex_s = sprintf "%c", $i;
	$s =~ s/%$hex_i/$hex_s/g;
    }

    return $s;
}

sub escape_html {
    my $s = shift;

    $s =~ s/\"/\&quot\;/gm;
    $s =~ s/\</&lt\;/gm;
    $s =~ s/\>/&gt\;/gm;
    
    return $s;
}

sub unescape_html {
    my $s = shift;

    $s =~ s/\&quot\;/\"/g;
    $s =~ s/&lt\;/\</g;
    $s =~ s/&gt\;/\>/g;
    
    return $s;
}

sub tmp_passwd {
    my $email = shift;

    return ('init'.substr(Digest::MD5::md5_hex(join('/', $Conf::Conf{'cookie'}, $email)), -8)) ;
}

# Check sum used to authenticate communication from wwsympa to sympa
sub sympa_checksum {
    my $rcpt = shift;
    return (substr(Digest::MD5::md5_hex(join('/', $Conf::Conf{'cookie'}, $rcpt)), -10)) ;
}

# create a cipher
sub ciphersaber_installed {

    my $is_installed;
    foreach my $dir (@INC) {
	if (-f "$dir/Crypt/CipherSaber.pm") {
	    $is_installed = 1;
	    last;
	}
    }

    if ($is_installed) {
	require Crypt::CipherSaber;
	$cipher = Crypt::CipherSaber->new($Conf::Conf{'cookie'});
    }else{
	$cipher = 'no_cipher';
    }
}

# create a cipher
sub cookie_changed {
    my $current=shift;
    my $changed = 1 ;
    if (-f "$Conf::Conf{'etc'}/cookies.history") {
	unless (open COOK, "$Conf::Conf{'etc'}/cookies.history") {
	    do_log('err', "Unable to read $Conf::Conf{'etc'}/cookies.history") ;
	    return undef ; 
	}
	my $oldcook = <COOK>;
	close COOK;

	my @cookies = split(/\s+/,$oldcook );
	

	if ($cookies[$#cookies] eq $current) {
	    do_log('debug2', "cookie is stable") ;
	    $changed = 0;
#	}else{
#	    push @cookies, $current ;
#	    unless (open COOK, ">$Conf::Conf{'etc'}/cookies.history") {
#		do_log('err', "Unable to create $Conf::Conf{'etc'}/cookies.history") ;
#		return undef ; 
#	    }
#	    printf COOK "%s",join(" ",@cookies) ;
#	    
#	    close COOK;
	}
	return $changed ;
    }else{
	unless (open COOK, ">$Conf::Conf{'etc'}/cookies.history") {
	    do_log('err', "Unable to create $Conf::Conf{'etc'}/cookies.history") ;
	    return undef ; 
	}
	printf COOK "$current ";
	close COOK;
	return(0);
    }
}

## encrypt a password
sub crypt_password {
    my $inpasswd = shift ;

    unless (defined($cipher)){
	$cipher = ciphersaber_installed();
    }
    return $inpasswd if ($cipher eq 'no_cipher') ;
    return ("crypt.".&MIME::Base64::encode($cipher->encrypt ($inpasswd))) ;
}

## decrypt a password
sub decrypt_password {
    my $inpasswd = shift ;
    do_log('debug2', 'tools::decrypt_password (%s)', $inpasswd);

    return $inpasswd unless ($inpasswd =~ /^crypt\.(.*)$/) ;
    $inpasswd = $1;

    unless (defined($cipher)){
	$cipher = ciphersaber_installed();
    }
    if ($cipher eq 'no_cipher') {
	do_log('info','password seems crypted while CipherSaber is not installed !');
	return $inpasswd ;
    }
    return ($cipher->decrypt(&MIME::Base64::decode($inpasswd)));
}

sub load_mime_types {
    my $types = {};

    my @localisation = ('/etc/mime.types',
			'/usr/local/apache/conf/mime.types',
			'/etc/httpd/conf/mime.types','mime.types');

    foreach my $loc (@localisation) {
        next unless (-r $loc);

        unless(open (CONF, $loc)) {
            printf STDERR "load_mime_types: unable to open $loc\n";
            return undef;
        }
    }
    
    while (<CONF>) {
        next if /^\s*\#/;
        
        if (/^(\S+)\s+(.+)\s*$/i) {
            my ($k, $v) = ($1, $2);
            
            my @extensions = split / /, $v;
        
            ## provides file extention, given the content-type
            if ($#extensions >= 0) {
                $types->{$k} = $extensions[0];
            }
    
            foreach my $ext (@extensions) {
                $types->{$ext} = $k;
            }
            next;
        }
    }
    
    close FILE;
    return $types;
}

sub split_mail {
    my $message = shift ; 
    my $pathname = shift ;
    my $dir = shift ;

    my $head = $message->head ;
    my $body = $message->body ;
    my $encoding = $head->mime_encoding ;

    if ($message->is_multipart
	|| ($message->mime_type eq 'message/rfc822')) {

        for (my $i=0 ; $i < $message->parts ; $i++) {
            &split_mail ($message->parts ($i), $pathname.'.'.$i, $dir) ;
        }
    }
    else { 
	    my $fileExt ;

	    if ($head->mime_attr("content_type.name") =~ /\.(\w+)\s*\"*$/) {
		$fileExt = $1 ;
	    }
	    elsif ($head->recommended_filename =~ /\.(\w+)\s*\"*$/) {
		$fileExt = $1 ;
	    }
	    else {
		my $mime_types = &load_mime_types();

		$fileExt=$mime_types->{$head->mime_type};
		my $var=$head->mime_type;
	    }
	
	    

	    ## Store body in file 
	    unless (open OFILE, ">$dir/$pathname.$fileExt") {
		&do_log('err', "Unable to create $dir/$pathname.$fileExt : $!") ;
		return undef ; 
	    }
	    
	    if ($encoding =~ /^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/ ) {
		open TMP, ">$dir/$pathname.$fileExt.$encoding";
		$message->print_body (\*TMP);
		close TMP;

		open BODY, "$dir/$pathname.$fileExt.$encoding";

		my $decoder = new MIME::Decoder $encoding;
		unless (defined $decoder) {
		    &do_log('err', 'Cannot create decoder for %s', $encoding);
		    return undef;
		}
		$decoder->decode(\*BODY, \*OFILE);
		close BODY;
		unlink "$dir/$pathname.$fileExt.$encoding";
	    }else {
		$message->print_body (\*OFILE) ;
	    }
	    close (OFILE);
	    printf "\t-------\t Create file %s\n", $pathname.'.'.$fileExt ;
	    
	    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
	    $message->purge ;	
    }
    
    return 1;
}

sub virus_infected {
    my $mail = shift ;
    my $file = shift ;

    &do_log('debug2', 'Scan virus in %s', $file);
    
    unless ($Conf::Conf{'antivirus_path'} ) {
        &do_log('debug', 'Sympa not configured to scan virus in message');
	return 0;
    }
    my @name = split(/\//,$file);
    my $work_dir = $Conf::Conf{'tmpdir'}.'/antivirus';
    
    unless ((-d $work_dir) ||( mkdir $work_dir, 0755)) {
	do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return undef;
    }

    $work_dir = $Conf::Conf{'tmpdir'}.'/antivirus/'.$name[$#name];
    
    unless ( (-d $work_dir) || mkdir ($work_dir, 0755)) {
	do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return undef;
    }

    #$mail->dump_skeleton;

    ## Call the procedure of spliting mail
    unless (&split_mail ($mail,'msg', $work_dir)) {
	&do_log('err', 'Could not split mail %s', $mail);
	return undef;
    }

    my $virusfound = 0; 
    my $error_msg;
    my $result;

    ## McAfee
    if ($Conf::Conf{'antivirus_path'} =~  /\/uvscan$/) {

	# impossible to look for viruses with no option set
	unless ($Conf::Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
	open (ANTIVIR,"$Conf::Conf{'antivirus_path'} $Conf::Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    $result .= $_; chomp $result;
	    if ((/^\s*Found the\s+(.*)\s*virus.*$/i) ||
		(/^\s*Found application\s+(.*)\.\s*$/i)){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status =12 or 13 (*256) => virus
        if (( $status == 13) || ($status == 12)) { 
	    $virusfound ||= "unknown";
	}

	## Meaning of the codes
	##  12 : The program tried to clean a file, and that clean failed for some reason and the file is still infected.
	##  13 : One or more viruses or hostile objects (such as a Trojan horse, joke program,  or  a  test file) were found.
	##  15 : The programs self-check failed; the program might be infected or damaged.
	##  19 : The program succeeded in cleaning all infected files.

	$error_msg = $result
	    if ($status != 0 && $status != 12 && $status != 13 && $status != 19);

    ## Trend Micro
    }elsif ($Conf::Conf{'antivirus_path'} =~  /\/vscan$/) {

	open (ANTIVIR,"$Conf::Conf{'antivirus_path'} $Conf::Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    if (/Found virus (\S+) /i){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status = 1 | 2 (*256) => virus
        if ((( $status == 1) or ( $status == 2)) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

    ## F-Secure
    } elsif($Conf::Conf{'antivirus_path'} =~  /\/fsav$/) {
	my $dbdir=$` ;

	# impossible to look for viruses with no option set
	unless ($Conf::Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}

	open (ANTIVIR,"$Conf::Conf{'antivirus_path'} --databasedirectory $dbdir $Conf::Conf{'antivirus_args'} $work_dir |") ;

	while (<ANTIVIR>) {

	    if (/infection:\s+(.*)/){
		$virusfound = $1;
	    }
	}
	
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## fsecure status =3 (*256) => virus
        if (( $status == 3) and not($virusfound)) { 
	    $virusfound = "unknown";
	}    
    }elsif($Conf::Conf{'antivirus_path'} =~ /f-prot\.sh$/) {

        &do_log('debug2', 'f-prot is running');    

        open (ANTIVIR,"$Conf::Conf{'antivirus_path'} $Conf::Conf{'antivirus_args'} $work_dir |") ;
        
        while (<ANTIVIR>) {
        
            if (/Infection:\s+(.*)/){
                $virusfound = $1;
            }
        }
        
        close ANTIVIR;
        
        my $status = $?/256 ;
        
        &do_log('debug2', 'Status: '.$status);    
        
        ## f-prot status =3 (*256) => virus
        if (( $status == 3) and not($virusfound)) { 
            $virusfound = "unknown";
        }    
    }elsif ($Conf::Conf{'antivirus_path'} =~ /kavscanner/) {

	# impossible to look for viruses with no option set
	unless ($Conf::Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
	open (ANTIVIR,"$Conf::Conf{'antivirus_path'} $Conf::Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    if (/infected:\s+(.*)/){
		$virusfound = $1;
	    }
	    elsif (/suspicion:\s+(.*)/i){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status =3 (*256) => virus
        if (( $status >= 3) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

        ## Sophos Antivirus... by liuk@publinet.it
    }elsif ($Conf::Conf{'antivirus_path'} =~ /\/sweep$/) {
	
        # impossible to look for viruses with no option set
	unless ($Conf::Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
        open (ANTIVIR,"$Conf::Conf{'antivirus_path'} $Conf::Conf{'antivirus_args'} $work_dir |") ;
	
	while (<ANTIVIR>) {
	    if (/Virus\s+(.*)/) {
		$virusfound = $1;
	    }
	}       
	close ANTIVIR;
        
	my $status = $?/256 ;
        
	## sweep status =3 (*256) => virus
	if (( $status == 3) and not($virusfound)) {
	    $virusfound = "unknown";
	}

	## Clam antivirus
    }elsif ($Conf::Conf{'antivirus_path'} =~ /\/clamd?scan$/) {
	
        open (ANTIVIR,"$Conf::Conf{'antivirus_path'} $Conf::Conf{'antivirus_args'} $work_dir |") ;
	
	my $result;
	while (<ANTIVIR>) {
	    $result .= $_; chomp $result;
	    if (/^\S+:\s(.*)\sFOUND$/) {
		$virusfound = $1;
	    }
	}       
	close ANTIVIR;
        
	my $status = $?/256 ;
        
	## Clamscan status =1 (*256) => virus
	if (( $status == 1) and not($virusfound)) {
	    $virusfound = "unknown";
	}

	$error_msg = $result
	    if ($status != 0 && $status != 1);

    }         

    ## Error while running antivir, notify listmaster
    if ($error_msg) {
	unless (&List::send_notify_to_listmaster('virus_scan_failed', $Conf::Conf{'domain'},
						 {'filename' => $file,
						  'error_msg' => $error_msg})) {
	    &do_log('notice',"Unable to send notify 'virus_scan_failed' to listmaster");
	}

    }

    ## if debug mode is active, the working directory is kept
    unless ($main::options{'debug'}) {
	opendir (DIR, ${work_dir});
	my @list = readdir(DIR);
	closedir (DIR);
        foreach (@list) {
	    my $nbre = unlink ("$work_dir/$_")  ;
	}
	rmdir ($work_dir) ;
    }
   
    return $virusfound;
   
}

## subroutines for epoch and human format date processings


## convert an epoch date into a readable date scalar
sub adate {

    my $epoch = $_[0];
    my @date = localtime ($epoch);
    my $date = strftime ("%e %a %b %Y  %H h %M min %S s", @date);
    
    return $date;
}

## human format (used in task models and scenarii)

# -> absolute date :
#  xxxxYxxMxxDxxHxxMin
# Y year ; M : month (1-12) ; D : day (1-28|29|30|31) ; H : hour (0-23) ; Min : minutes (0-59)
# H and Min parameters are optionnal
# ex 2001y9m13d14h10min

# -> duration :
# +|- xxYxxMxxWxxDxxHxxMin
# W week, others are the same
# all parameters are optionnals
# before the duration you may write an absolute date, an epoch date or the keyword 'execution_date' which refers to the epoch date when the subroutine is executed. If you put nothing, the execution_date is used


## convert a human format date into an epoch date
sub epoch_conv {

    my $arg = $_[0]; # argument date to convert
    my $time = $_[1] || time; # the epoch current date

    &do_log('debug3','tools::epoch_conv(%s, %d)', $arg, $time);

    my $result;
    
     # decomposition of the argument date
    my $date;
    my $duration;
    my $op;

    if ($arg =~ /^(.+)(\+|\-)(.+)$/) {
	$date = $1;
	$duration = $3;
	$op = $2;
    } else {
	$date = $arg;
	$duration = '';
	$op = '+';
	}

     #conversion
    $date = date_conv ($date, $time);
    $duration = duration_conv ($duration, $date);

    if ($op eq '+') {$result = $date + $duration;}
    else {$result = $date - $duration;}

    return $result;
}

sub date_conv {
   
    my $arg = $_[0];
    my $time = $_[1];

    if ( ($arg eq 'execution_date') ){ # execution date
	return time;
    }

    if ($arg =~ /^\d+$/) { # already an epoch date
	return $arg;
    }
	
    if ($arg =~ /^(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/) { # absolute date

	my @date = ("$6", "$5", "$4", "$3", "$2", "$1");
	for (my $i = 0; $i < 6; $i++) {
	    chop ($date[$i]);
	    if (($i == 1) || ($i== 2)) {chop ($date[$i]); chop ($date[$i]);}
	    $date[$i] = 0 unless ($date[$i]);
	}
	$date[3] = 1 if ($date[3] == 0);
	$date[4]-- if ($date[4] != 0);
	$date[5] -= 1900;
	
	return timelocal (@date);
    }
    
    return time;
}

sub duration_conv {
    
    my $arg = $_[0];
    my $start_date = $_[1];

    return 0 unless $arg;
  
    $arg =~ /(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/i ;
    my @date = ("$1", "$2", "$3", "$4", "$5", "$6", "$7");
    for (my $i = 0; $i < 7; $i++) {
      $date[$i] =~ s/[a-z]+$//; ## Remove trailing units
    }
    
    my $duration = $date[6]+60*($date[5]+60*($date[4]+24*($date[3]+7*$date[2]+365*$date[0])));
	
    # specific processing for the months because their duration varies
    my @months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
		  31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    my $start  = (localtime ($start_date))[4];
    for (my $i = 0; $i < $date[1]; $i++) {
	$duration += $months[$start + $i] * 60 * 60 * 24;
    }
	
    return $duration;
}

## Look for a file in the list > robot > server > default locations
## Possible values for $options : order=all
sub get_filename {
    my ($type, $options, $name, $robot, $object) = @_;
    my $list;
    my $family;
    &do_log('debug3','tools::get_filename(%s,%s,%s,%s,%s)', $type,  join('/',keys %$options), $name, $robot, $object->{'name'});

    
    if (ref($object) eq 'List') {
 	$list = $object;
 	if ($list->{'admin'}{'family_name'}) {
 	    unless ($family = $list->get_family()) {
 		&do_log('err', 'Impossible to get list %s family : %s. The list is set in status error_config',$list->{'name'},$list->{'admin'}{'family_name'});
 		$list->set_status_error_config('no_list_family',$list->{'name'}, $list->{'admin'}{'family_name'});
 		return undef;
 	    }  
 	}
    }elsif (ref($object) eq 'Family') {
 	$family = $object;
    }
    
    if ($type eq 'etc') {
	my (@try, $default_name);
	
	## template refers to a language
	## => extend search to default tpls
	if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
	    $default_name = $1.'.tt2';
	    
	    @try = (
            $Conf::Conf{'etc'} . "/$robot/$name",
		    $Conf::Conf{'etc'} . "/$robot/$default_name",
		    $Conf::Conf{'etc'} . "/$name",
		    $Conf::Conf{'etc'} . "/$default_name",
		    Sympa::Constants::DEFAULTDIR . "/$name",
		    Sympa::Constants::DEFAULTDIR . "/$default_name");
	}else {
	    @try = (
            $Conf::Conf{'etc'} . "/$robot/$name",
		    $Conf::Conf{'etc'} . "/$name",
		    Sympa::Constants::DEFAULTDIR . "/$name"
        );
	}
	
	if ($family) {
 	    ## Default tpl
 	    if ($default_name) {
		unshift @try, $family->{'dir'}.'/'.$default_name;
	    }
	}
	
	unshift @try, $family->{'dir'}.'/'.$name;
    
	if ($list->{'name'}) {
	    ## Default tpl
	    if ($default_name) {
		unshift @try, $list->{'dir'}.'/'.$default_name;
	    }
	    
	    unshift @try, $list->{'dir'}.'/'.$name;
	}
	my @result;
	foreach my $f (@try) {
	    &do_log('debug3','get_filename : name: %s ; dir %s', $name, $f  );
	    if (-r $f) {
		if ($options->{'order'} eq 'all') {
		    push @result, $f;
		}else {
		    return $f;
		}
	    }
	}
	if ($options->{'order'} eq 'all') {
	    return @result ;
	}
    }
    
    #&do_log('notice','tools::get_filename: Cannot find %s in %s', $name, join(',',@try));
    return undef;
}
####################################################
# make_tt2_include_path
####################################################
# make an array of include path for tt2 parsing
# 
# IN -$robot(+) : robot
#    -$dir : directory ending each path
#    -$lang : lang
#    -$list : ref(List)
#
# OUT : ref(ARRAY) of tt2 include path
#
######################################################
sub make_tt2_include_path {
    my ($robot,$dir,$lang,$list) = @_;
    &Log::do_log('debug3','tools::make_tt2_include_path(%s,%s,%s,%s)',$robot,$dir,$lang,$list);

    my @include_path;

    my $path_etcbindir;
    my $path_etcdir;
    my $path_robot;  ## optional
    my $path_list;   ## optional
    my $path_family; ## optional

    if ($dir) {
	$path_etcbindir = Sympa::Constants::DEFAULTDIR . "/$dir";
	$path_etcdir = "$Conf::Conf{'etc'}/".$dir;
	$path_robot = "$Conf::Conf{'etc'}/".$robot.'/'.$dir if (lc($robot) ne lc($Conf::Conf{'host'}));
	if (ref($list) eq 'List'){
	    $path_list = $list->{'dir'}.'/'.$dir;
	    if (defined $list->{'admin'}{'family_name'}) {
		my $family = $list->get_family();
	        $path_family = $family->{'dir'}.'/'.$dir;
	    }
	} 
    }else {
	$path_etcbindir = Sympa::Constants::DEFAULTDIR;
	$path_etcdir = "$Conf::Conf{'etc'}";
	$path_robot = "$Conf::Conf{'etc'}/".$robot if (lc($robot) ne lc($Conf::Conf{'host'}));
	if (ref($list) eq 'List') {
	    $path_list = $list->{'dir'} ;
	    if (defined $list->{'admin'}{'family_name'}) {
		my $family = $list->get_family();
	        $path_family = $family->{'dir'};
	    }
	}
    }
    if ($lang) {
	@include_path = ($path_etcdir.'/'.$lang,
			 $path_etcdir,
			 $path_etcbindir.'/'.$lang,
			 $path_etcbindir);
	if ($path_robot) {
	    unshift @include_path,$path_robot;
	    unshift @include_path,$path_robot.'/'.$lang;
	}
	if ($path_list) {
	    unshift @include_path,$path_list;
	    unshift @include_path,$path_list.'/'.$lang;

	    if ($path_family) {
		unshift @include_path,$path_family;
		unshift @include_path,$path_family.'/'.$lang;
	    }	
	    
	}
    }else {
	@include_path = ($path_etcdir,
			 $path_etcbindir);

	if ($path_robot) {
	    unshift @include_path,$path_robot;
	}
	if ($path_list) {
	    unshift @include_path,$path_list;
	   
	    if ($path_family) {
		unshift @include_path,$path_family;
	    }
	}
    }

    return \@include_path;

}

## Find a file in an ordered list of directories
sub find_file {
    my ($filename, @directories) = @_;
    &Log::do_log('debug3','tools::find_file(%s,%s)', $filename, join(':',@directories));

    foreach my $d (@directories) {
	if (-f "$d/$filename") {
	    return "$d/$filename";
	}
    }
    
    return undef;
}

## Recursively list the content of a directory
## Return an array of hash, each entry with directory + filename + encoding
sub list_dir {
    my $dir = shift;
    my $all = shift;
    my $original_encoding = shift; ## Suspected original encoding of filenames

    my $size=0;

    if (opendir(DIR, $dir)) {
	foreach my $file ( sort grep (!/^\.\.?$/,readdir(DIR))) {

	    ## Guess filename encoding
	    my ($encoding, $guess);
	    my $decoder = &Encode::Guess::guess_encoding($file, $original_encoding, 'utf-8');
	    if (ref $decoder) {
		$encoding = $decoder->name;
	    }else {
		$guess = $decoder;
	    }

	    push @$all, {'directory' => $dir,
			 'filename' => $file,
			 'encoding' => $encoding,
			 'guess' => $guess};
	    if (-d "$dir/$file") {
		&list_dir($dir.'/'.$file, $all, $original_encoding);
	    }
	}
        closedir DIR;
    }

    return 1;
}

## Q-encode a complete file hierarchy
## Usefull to Q-encode subshared documents
sub qencode_hierarchy {
    my $dir = shift; ## Root directory
    my $original_encoding = shift; ## Suspected original encoding of filenames

    my $count;
    my @all_files;
    &tools::list_dir($dir, \@all_files, $original_encoding);

    foreach my $f_struct (reverse @all_files) {
    
	next unless ($f_struct->{'filename'} =~ /[^\x00-\x7f]/); ## At least one 8bit char

	my $new_filename = $f_struct->{'filename'};
	my $encoding = $f_struct->{'encoding'};
	Encode::from_to($new_filename, $encoding, 'utf8') if $encoding;
    
	## Q-encode filename to escape chars with accents
	$new_filename = &tools::qencode_filename($new_filename);
    
	my $orig_f = $f_struct->{'directory'}.'/'.$f_struct->{'filename'};
	my $new_f = $f_struct->{'directory'}.'/'.$new_filename;

	## Rename the file using utf8
	&do_log('notice', "Renaming %s to %s", $orig_f, $new_f);
	unless (rename $orig_f, $new_f) {
	    &do_log('err', "Failed to rename %s to %s : %s", $orig_f, $new_f, $!);
	    next;
	}
	$count++;
    }

    return $count;
}

## Dumps the value of each character of the inuput string
sub dump_encoding {
    my $out = shift;

    $out =~ s/./sprintf('%02x', ord($&)).' '/eg;
    return $out;
}

## Remove PID file and STDERR output
sub remove_pid {
    my ($pidfile, $pid, $options) = @_;

    ## If in multi_process mode (bulk.pl for instance can have child processes)
    ## Then the pidfile contains a list of space-separated PIDs on a single line
    if($options->{'multiple_process'}){
	unless (open(PFILE, $pidfile)) {
	    fatal_err('Could not open %s, exiting', $pidfile);
	}
	my $previous_pid = <PFILE>; chomp $previous_pid;
	close PFILE;
	$previous_pid =~ s/$pid//g;

	## If no PID left, then remove the file
	if ($previous_pid =~ /^\s*$/){
	    ## Release the lock
	    unless (unlink $pidfile) {
		&do_log('err', "Failed to remove $pidfile: %s", $!);
		return undef;
	    }
	}else{
	    if(-f $pidfile){
		unless (open(PFILE, ">$pidfile")) {
		    fatal_err('Could not open %s, exiting', $pidfile);
		}
		print PFILE "$previous_pid\n";
		close(PFILE);
	    }else{
		&do_log('notice','pidfile %s does not exist. Nothing to do.',$pidfile);
	    }
	}
    }else{
	unless (unlink $pidfile) {
	    &do_log('err', "Failed to remove $pidfile: %s", $!);
	    return undef;
	}
	
	my $err_file = $Conf::Conf{'tmpdir'}.'/'.$pid.'.stderr';
	if (-f $err_file) {
	    unless (unlink $err_file) {
		&do_log('err', "Failed to remove $err_file: %s", $!);
		return undef;
	    }
	}
    }
    return 1;
}

# input user agent string and IP. return 1 if suspected to be a crawler.
# initial version based on rawlers_dtection.conf file only
# later : use Session table to identify those who create a lot of sessions 
sub is_a_crawler {

    my $robot = shift;
    my $context = shift;

#    if ($Conf::Conf{$robot}{'crawlers_detection'}) {
#	return ($Conf::Conf{$robot}{'crawlers_detection'}{'user_agent_string'}{$context->{'user_agent_string'}});
#    }

    # open (TMP, ">> /tmp/dump1"); printf TMP "dump de la conf dans is_a_crawler : \n"; &tools::dump_var($Conf::Conf{'crawlers_detection'}, 0,\*TMP);     close TMP;
    return $Conf::Conf{'crawlers_detection'}{'user_agent_string'}{$context->{'user_agent_string'}};
}

sub write_pid {
    my ($pidfile, $pid, $options) = @_;

   my $piddir = $pidfile;
    $piddir =~ s/\/[^\/]+$//;

    ## Create piddir
    unless (-d $piddir) {
	mkdir $piddir, 0755;
    }
    
    unless (&tools::set_file_rights(file => $piddir,
				    user  => Sympa::Constants::USER,
				    group => Sympa::Constants::GROUP,
				    ))
    {
	&do_log('err','Unable to set rights on %s',$Conf::Conf{'db_name'});
	return undef;
    }

    ## If pidfile exists, read the PID
    my ($other_pid);
    if (-f $pidfile) {
	open PFILE, $pidfile;
	$other_pid = <PFILE>; chomp $other_pid;
	close PFILE;	
    }

    ## If we can have multiple options for the process.
    ## Print other pids + this one
    if($options->{'multiple_process'}){
	unless (open(LCK, "> $pidfile")) {
	    fatal_err('Could not open %s, exiting', $pidfile);
	}

	## Print other pids + this one
	print LCK "$other_pid $pid\n";

	close(LCK);
    }else{
	## Create and write the pidfile
	unless (open(LOCK, "+>> $pidfile")) {
	    fatal_err('Could not open %s, exiting', $pidfile);
	}
	unless (flock(LOCK, 6)) {
	    fatal_err('Could not lock %s, process is probably already running : %s', $pidfile, $!);
	}
	
	## The previous process died suddenly, without pidfile cleanup
	## Send a notice to listmaster with STDERR of the previous process
	if ($other_pid) {
	    &do_log('notice', "Previous process $other_pid died suddenly ; notifying listmaster");
	    my $err_file = $Conf::Conf{'tmpdir'}.'/'.$other_pid.'.stderr';
	    my (@err_output, $err_date);
	    if (-f $err_file) {
		open ERR, $err_file;
		@err_output = <ERR>;
		close ERR;
		
		$err_date = strftime("%d %b %Y  %H:%M", localtime( (stat($err_file))[9]));
	    }
	    
	    &List::send_notify_to_listmaster('crash', $Conf::Conf{'domain'},
					     {'crash_err' => \@err_output, 'crash_date' => $err_date});
	}
	
	unless (open(LCK, "> $pidfile")) {
	    fatal_err('Could not open %s, exiting', $pidfile);
	}
	unless (truncate(LCK, 0)) {
	    fatal_err('Could not truncate %s, exiting.', $pidfile);
	}
	
	print LCK "$pid\n";
	close(LCK);
    }
    unless (&tools::set_file_rights(file => $pidfile,
				    user  => Sympa::Constants::USER,
				    group => Sympa::Constants::GROUP,
				    ))
    {
	&do_log('err','Unable to set rights on %s',$Conf::Conf{'db_name'});
	return undef;
    }

    ## Error output is stored in a file with PID-based name
    ## Usefull if process crashes
    unless ($options->{'stderr_to_tty'}) {
      open(STDERR, '>>',  $Conf::Conf{'tmpdir'}.'/'.$pid.'.stderr') unless ($main::options{'foreground'});
      unless (&tools::set_file_rights(file => $Conf::Conf{'tmpdir'}.'/'.$pid.'.stderr',
				      user  => Sympa::Constants::USER,
				      group => Sympa::Constants::GROUP,
				     ))
	{
	  &do_log('err','Unable to set rights on %s',$Conf::Conf{'db_name'});
	  return undef;
	}
    }

    return 1;
}

sub get_message_id {
    my $robot = shift;

    my $id = sprintf '<sympa.%d.%d.%d@%s>', time, $$, int(rand(999)), $robot;

    return $id;
}


sub get_dir_size {
    my $dir =shift;
    
    my $size=0;

    if (opendir(DIR, $dir)) {
	foreach my $file ( sort grep (!/^\./,readdir(DIR))) {
	    if (-d "$dir/$file") {
		$size += get_dir_size("$dir/$file");
	    }
	    else{
		my @info = stat "$dir/$file" ;
		$size += $info[7];
	    }
	}
        closedir DIR;
    }

    return $size;
}

## Basic check of an email address
sub valid_email {
    my $email = shift;
    
    unless ($email =~ /^$regexp{'email'}$/) {
	do_log('err', "Invalid email address '%s'", $email);
	return undef;
    }
    
    ## Forbidden characters
    if ($email =~ /[\|\$\*\?\!]/) {
	do_log('err', "Invalid email address '%s'", $email);
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

## Function for Removing a non-empty directory
## It takes a variale number of arguments : 
## it can be a list of directory
## or few direcoty paths
sub remove_dir {
    
    do_log('debug2','remove_dir()');
    
    foreach my $current_dir (@_){
	finddepth({wanted => \&del, no_chdir => 1},$current_dir);
    }
    sub del {
	my $name = $File::Find::name;

	if (!-l && -d _) {
	    unless (rmdir($name)) {
		&Log::do_log('err','Error while removing dir %s',$name);
	    }
	}else{
	    unless (unlink($name)) {
		&Log::do_log('err','Error while removing file  %s',$name);
	    }
	}
    }
    return 1;
}

## find the appropriate S/MIME keys/certs for $oper in $dir.
## $oper can be:
## 'sign' -> return the preferred signing key/cert
## 'decrypt' -> return a list of possible decryption keys/certs
## 'encrypt' -> return the preferred encryption key/cert
## returns ($certs, $keys)
## for 'sign' and 'encrypt', these are strings containing the absolute filename
## for 'decrypt', these are arrayrefs containing absolute filenames
sub smime_find_keys {
    my($dir, $oper) = @_;
    &Log::do_log('debug', 'tools::smime_find_keys(%s, %s)', $dir, $oper);

    my(%certs, %keys);
    my $ext = ($oper eq 'sign' ? 'sign' : 'enc');

    unless (opendir(D, $dir)) {
	do_log('err', "unable to opendir $dir: $!");
	return undef;
    }

    while (my $fn = readdir(D)) {
	if ($fn =~ /^cert\.pem/) {
	    $certs{"$dir/$fn"} = 1;
	}elsif ($fn =~ /^private_key/) {
	    $keys{"$dir/$fn"} = 1;
	}
    }
    closedir(D);

    foreach my $c (keys %certs) {
	my $k = $c;
	$k =~ s/\/cert\.pem/\/private_key/;
	unless ($keys{$k}) {
	    do_log('notice', "$c exists, but matching $k doesn't");
	    delete $certs{$c};
	}
    }

    foreach my $k (keys %keys) {
	my $c = $k;
	$c =~ s/\/private_key/\/cert\.pem/;
	unless ($certs{$c}) {
	    do_log('notice', "$k exists, but matching $c doesn't");
	    delete $keys{$k};
	}
    }

    my ($certs, $keys);
    if ($oper eq 'decrypt') {
	$certs = [ sort keys %certs ];
	$keys = [ sort keys %keys ];
    }else {
	if($certs{"$dir/cert.pem.$ext"}) {
	    $certs = "$dir/cert.pem.$ext";
	    $keys = "$dir/private_key.$ext";
	} elsif($certs{"$dir/cert.pem"}) {
	    $certs = "$dir/cert.pem";
	    $keys = "$dir/private_key";
	} else {
	    do_log('info', "$dir: no certs/keys found for $oper");
	    return undef;
	}
    }

    return ($certs,$keys);
}

# IN: hashref:
# file => filename
# text => PEM-encoded cert
# OUT: hashref
# email => email address from cert
# subject => distinguished name
# purpose => hashref
#  enc => true if v3 purpose is encryption
#  sign => true if v3 purpose is signing
sub smime_parse_cert {
    my($arg) = @_;
    &Log::do_log('debug', 'tools::smime_parse_cert(%s)', join('/',%{$arg}));

    unless (ref($arg)) {
	&Log::do_log('err', "smime_parse_cert: must be called with hashref, not %s", ref($arg));
	return undef;
    }

    ## Load certificate
    my @cert;
    if($arg->{'text'}) {
	@cert = ($arg->{'text'});
    }elsif ($arg->{file}) {
	unless (open(PSC, "$arg->{file}")) {
	    &Log::do_log('err', "smime_parse_cert: open %s: $!", $arg->{file});
	    return undef;
	}
	@cert = <PSC>;
	close(PSC);
    }else {
	&Log::do_log('err', 'smime_parse_cert: neither "text" nor "file" given');
	return undef;
    }

    ## Extract information from cert
    my ($tmpfile) = $Conf::Conf{'tmpdir'}."/parse_cert.$$";
    unless (open(PSC, "| $Conf::Conf{openssl} x509 -email -subject -purpose -noout > $tmpfile")) {
	&Log::do_log('err', "smime_parse_cert: open |openssl: $!");
	return undef;
    }
    print PSC join('', @cert);

    unless (close(PSC)) {
	&Log::do_log('err', "smime_parse_cert: close openssl: $!, $@");
	return undef;
    }

    unless (open(PSC, "$tmpfile")) {
	&Log::do_log('err', "smime_parse_cert: open $tmpfile: $!");
	return undef;
    }

    my (%res, $purpose_section);

    while (<PSC>) {
      ## First lines before subject are the email address(es)

      if (/^subject=\s+(\S.+)\s*$/) {
	$res{'subject'} = $1;

      }elsif (! $res{'subject'} && /\@/) {
	my $email_address = lc($_);
	chomp $email_address;
	$res{'email'}{$email_address} = 1;

	  ## Purpose section appears at the end of the output
	  ## because options order matters for openssl
      }elsif (/^Certificate purposes:/) {
		  $purpose_section = 1;
	  }elsif ($purpose_section) {
		if (/^S\/MIME signing : (\S+)/) {
			$res{purpose}->{sign} = ($1 eq 'Yes');
	  
		}elsif (/^S\/MIME encryption : (\S+)/) {
			$res{purpose}->{enc} = ($1 eq 'Yes');
		}
      }
    }
    
    ## OK, so there's CAs which put the email in the subjectAlternateName only
    ## and ones that put it in the DN only...
    if(!$res{email} && ($res{subject} =~ /\/email(address)?=([^\/]+)/)) {
	$res{email} = $1;
    }
    close(PSC);
    unlink($tmpfile);
    return \%res;
}

sub smime_extract_certs {
    my($mime, $outfile) = @_;
    &Log::do_log('debug2', "tools::smime_extract_certs(%s)",$mime->mime_type);

    if ($mime->mime_type =~ /application\/(x-)?pkcs7-/) {
	unless (open(MSGDUMP, "| $Conf::Conf{openssl} pkcs7 -print_certs ".
		     "-inform der > $outfile")) {
	    &Log::do_log('err', "unable to run openssl pkcs7: $!");
	    return 0;
	}
	print MSGDUMP $mime->bodyhandle->as_string;
	close(MSGDUMP);
	if ($?) {
	    &Log::do_log('err', "openssl pkcs7 returned an error: ", $?/256);
	    return 0;
	}
	return 1;
    }
}

## Dump a variable's content
sub dump_var {
    my ($var, $level, $fd) = @_;

    return undef unless ($fd);

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
		print $fd "\t"x$level.$index."\n";
		&dump_var($var->[$index], $level+1, $fd);
	    }
	}elsif (ref($var) eq 'HASH' || ref($var) eq 'Scenario' || ref($var) eq 'List') {
	    foreach my $key (sort keys %{$var}) {
		print $fd "\t"x$level.'_'.$key.'_'."\n";
		&dump_var($var->{$key}, $level+1, $fd);
	    }    
	}else {
	    printf $fd "\t"x$level."'%s'"."\n", ref($var);
	}
    }else {
	if (defined $var) {
	    print $fd "\t"x$level."'$var'"."\n";
	}else {
	    print $fd "\t"x$level."UNDEF\n";
	}
    }
}

## Dump a variable's content
sub dump_html_var {
    my ($var) = shift;
	my $html = '';

    
    if (ref($var)) {

	if (ref($var) eq 'ARRAY') {
	    $html .= '<ul>';
	    foreach my $index (0..$#{$var}) {
		$html .= '<li> '.$index.':';
		$html .= &dump_html_var($var->[$index]);
		$html .= '</li>';
	    }
	    $html .= '</ul>';
	}elsif (ref($var) eq 'HASH' || ref($var) eq 'Scenario' || ref($var) eq 'List') {
	    $html .= '<ul>';
	    foreach my $key (sort keys %{$var}) {
		$html .= '<li>'.$key.'=' ;
		$html .=  &dump_html_var($var->{$key});
		$html .= '</li>';
	    }
	    $html .= '</ul>';
	}else {
	    $html .= 'EEEEEEEEEEEEEEEEEEEEE'.ref($var);
	}
    }else{
	if (defined $var) {
	    $html .= &escape_html($var);
	}else {
	    $html .= 'UNDEF';
	}
    }
    return $html;
}

## Dump a variable's content
sub dump_html_var2 {
    my ($var) = shift;

    my $html = '' ;
    
    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    $html .= 'ARRAY <ul>';
	    foreach my $index (0..$#{$var}) {
		$html .= '<li> '.$index;
		$html .= &dump_html_var($var->[$index]);
		$html .= '</li>'
	    }
	    $html .= '</ul>';
	}elsif (ref($var) eq 'HASH' || ref($var) eq 'Scenario' || ref($var) eq 'List') {
	    #$html .= " (".ref($var).') <ul>';
	    $html .= '<ul>';
	    foreach my $key (sort keys %{$var}) {
		$html .= '<li>'.$key.'=' ;
		$html .=  &dump_html_var($var->{$key});
		$html .= '</li>'
	    }    
	    $html .= '</ul>';
	}else {
	    $html .= "<li>'%s'"."</li>", ref($var);
	}
    }else{
	if (defined $var) {
	    $html .= '<li>'.$var.'</li>';
	}else {
	    $html .= '<li>UNDEF</li>';
	}
    }
    return $html;
}

sub remove_empty_entries {
    my ($var) = @_;    
    my $not_empty = 0;

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
		my $status = &remove_empty_entries($var->[$index]);
		$var->[$index] = undef unless ($status);
		$not_empty ||= $status
	    }	    
	}elsif (ref($var) eq 'HASH') {
	    foreach my $key (sort keys %{$var}) {
		my $status = &remove_empty_entries($var->{$key});
		$var->{$key} = undef unless ($status);
		$not_empty ||= $status;
	    }    
	}
    }else {
	if (defined $var && $var) {
	    $not_empty = 1
	}
    }
    
    return $not_empty;
}

## Duplictate a complex variable
sub dup_var {
    my ($var) = @_;    

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    my $new_var = [];
	    foreach my $index (0..$#{$var}) {
		$new_var->[$index] = &dup_var($var->[$index]);
	    }	    
	    return $new_var;
	}elsif (ref($var) eq 'HASH') {
	    my $new_var = {};
	    foreach my $key (sort keys %{$var}) {
		$new_var->{$key} = &dup_var($var->{$key});
	    }    
	    return $new_var;
	}
    }
    
    return $var; 
}

####################################################
# get_array_from_splitted_string                          
####################################################
# return an array made on a string splited by ','.
# It removes spaces.
#
# 
# IN : -$string (+): string to split 
#
# OUT : -ref(ARRAY)
#
######################################################
sub get_array_from_splitted_string {
    my ($string) = @_;
    my @array;

    foreach my $word (split /,/,$string) {
	$word =~ s/^\s+//;
	$word =~ s/\s+$//;
	push @array, $word;
    }

    return \@array;
}


####################################################
# diff_on_arrays                     
####################################################
# Makes set operation on arrays (seen as set, with no double) :
#  - deleted : A \ B
#  - added : B \ A
#  - intersection : A /\ B
#  - union : A \/ B
# 
# IN : -$setA : ref(ARRAY) - set
#      -$setB : ref(ARRAY) - set
#
# OUT : -ref(HASH) with keys :  
#          deleted, added, intersection, union
#
#######################################################    
sub diff_on_arrays {
    my ($setA,$setB) = @_;
    my $result = {'intersection' => [],
	          'union' => [],
	          'added' => [],
	          'deleted' => []};
    my %deleted;
    my %added;
    my %intersection;
    my %union;
    
    my %hashA;
    my %hashB;
    
    foreach my $eltA (@$setA) {
	$hashA{$eltA} = 1;
	$deleted{$eltA} = 1;
	$union{$eltA} = 1;
    }
    
    foreach my $eltB (@$setB) {
	$hashB{$eltB} = 1;
	$added{$eltB} = 1;
	
	if ($hashA{$eltB}) {
	    $intersection{$eltB} = 1;
	    $deleted{$eltB} = 0;
	}else {
	    $union{$eltB} = 1;
	}
    }
    
    foreach my $eltA (@$setA) {
	if ($hashB{$eltA}) {
	    $added{$eltA} = 0; 
	}
    }
    
    foreach my $elt (keys %deleted) {
	next unless $elt;
	push @{$result->{'deleted'}},$elt if ($deleted{$elt});
    }
    foreach my $elt (keys %added) {
	next unless $elt;
	push @{$result->{'added'}},$elt if ($added{$elt});
    }
    foreach my $elt (keys %intersection) {
	next unless $elt;
	push @{$result->{'intersection'}},$elt if ($intersection{$elt});
    }
    foreach my $elt (keys %union) {
	next unless $elt;
	push @{$result->{'union'}},$elt if ($union{$elt});
    } 
    
    return $result;
    
} 

####################################################
# is_on_array                     
####################################################
# Test if a value is on an array
# 
# IN : -$setA : ref(ARRAY) - set
#      -$value : a serached value
#
# OUT : boolean
#######################################################    
sub is_in_array {
    my ($set,$value) = @_;
    
    foreach my $elt (@$set) {
	return 1 if ($elt eq $value);
    }
    return undef;
}

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
    
    chomp $msg_id;

    if ($msg_id =~ /\<(.+)\>/) {
	$msg_id = $1;
    }

    return $msg_id;
}



## Change X-Sympa-To: header field in the message
sub change_x_sympa_to {
    my ($file, $value) = @_;
    
    ## Change X-Sympa-To
    unless (open FILE, $file) {
	&do_log('err', "Unable to open '%s' : %s", $file, $!);
	next;
    }	 
    my @content = <FILE>;
    close FILE;
    
    unless (open FILE, ">$file") {
	&do_log('err', "Unable to open '%s' : %s", "$file", $!);
	next;
    }	 
    foreach (@content) {
	if (/^X-Sympa-To:/i) {
	    $_ = "X-Sympa-To: $value\n";
	}
	print FILE;
    }
    close FILE;
    
    return 1;
}

## Compare 2 versions of Sympa
sub higher_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./,$v1;
    my @tab2 = split /\./,$v2;
    
    
    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for my $i (0..$max) {
    
        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        }elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        }elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] > $tab2[0]);
    }

    return 0;
}

## Compare 2 versions of Sympa
sub lower_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./,$v1;
    my @tab2 = split /\./,$v2;
    
    
    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for my $i (0..$max) {
    
        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        }elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        }elsif ($tab2[0] =~ /^(\d*)b$/) {
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

sub LOCK_SH {1};
sub LOCK_EX {2};
sub LOCK_NB {4};
sub LOCK_UN {8};

## lock a file 
sub lock {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    
    my $operation;
    my $open_mode;

    if ($mode eq 'read') {
	$operation = LOCK_SH;
    }else {
	$operation = LOCK_EX;
	$open_mode = '>>';
    }
    
    ## Read access to prevent "Bad file number" error on Solaris
    unless (open FH, $open_mode.$lock_file) {
	&Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	return undef;
    }
    
    my $got_lock = 1;
    unless (flock (FH, $operation | LOCK_NB)) {
	&Log::do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);

	## If lock was obtained more than 20 minutes ago, then force the lock
	if ( (time - (stat($lock_file))[9] ) >= 60*20) {
	    &Log::do_log('notice','Removing lock file %s', $lock_file);
	    unless (unlink $lock_file) {
		&Log::do_log('err', 'Cannot remove %s: %s', $lock_file, $!);
		return undef;	    		
	    }
	    
	    unless (open FH, ">$lock_file") {
		&Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		return undef;	    
	    }
	}

	$got_lock = undef;
	my $max = 10;
	$max = 2 if ($ENV{'HTTP_HOST'}); ## Web context
	for (my $i = 1; $i < $max; $i++) {
	    sleep (10 * $i);
	    if (flock (FH, $operation | LOCK_NB)) {
		$got_lock = 1;
		last;
	    }
	    &Log::do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);
	}
    }
	
    if ($got_lock) {
	&Log::do_log('debug2', 'Got lock for %s on %s', $mode, $lock_file);

	## Keep track of the locking PID
	if ($mode eq 'write') {
	    print FH "$$\n";
	}
    }else {
	&Log::do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	return undef;
    }

    return \*FH;
}

sub add_in_blacklist {
    my $entry = shift;
    my $robot = shift;
    my $list =shift;

    &do_log('info',"tools::add_in_blacklist(%s,%s,%s)",$entry,$robot,$list->{'name'});
    $entry = lc($entry);
    chomp $entry;

    # robot blacklist not yet availible 
    unless ($list) {
	 &do_log('info',"tools::add_in_blacklist: robot blacklist not yet availible, missing list parameter");
	 return undef;
    }
    unless (($entry)&&($robot)) {
	 &do_log('info',"tools::add_in_blacklist:  missing parameters");
	 return undef;
    }
    if ($entry =~ /\*.*\*/) {
	&do_log('info',"tools::add_in_blacklist: incorrect parameter $entry");
	return undef;
    }
    my $dir = $list->{'dir'}.'/search_filters';
    unless ((-d $dir) || mkdir ($dir, 0755)) {
	&do_log('info','do_blacklist : unable to create dir %s',$dir);
	return undef;
    }
    my $file = $dir.'/blacklist.txt';
    
    if (open BLACKLIST, "$file"){
	while(<BLACKLIST>) {
	    next if (/^\s*$/o || /^[\#\;]/o);
	    my $regexp= $_ ;
	    chomp $regexp;
	    $regexp =~ s/\*/.*/ ; 
	    $regexp = '^'.$regexp.'$';
	    if ($entry =~ /$regexp/i) { 
		&do_log('notice','do_blacklist : %s already in blacklist(%s)',$entry,$_);
		return 0;
	    }	
	}
	close BLACKLIST;
    }   
    unless (open BLACKLIST, ">> $file"){
	&do_log('info','do_blacklist : append to file %s',$file);
	return undef;
    }
    printf BLACKLIST "$entry\n";
    close BLACKLIST;

}

## unlock a file 
sub unlock {
    my $lock_file = shift;
    my $fh = shift;
    
    unless (flock($fh,LOCK_UN)) {
	&Log::do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    &Log::do_log('debug2', 'Release lock on %s', $lock_file);
    
    return 1;
}

############################################################
#  get_fingerprint                                         #
############################################################
#  Used in 2 cases :                                       #
#  - check the md5 in the url                              #
#  - create an md5 to put in a url                         #
#                                                          #
#  Use : get_db_random()                                   #
#        init_db_random()                                  #
#        md5_fingerprint()                                 #
#                                                          #  
# IN : $email : email of the subscriber                    #
#      $fingerprint : the fingerprint in the url (1st case)#
#                                                          # 
# OUT : $fingerprint : a md5 for create an url             #
#     | 1 : if the md5 in the url is true                  #
#     | undef                                              #
#                                                          #
############################################################
sub get_fingerprint {
    
    my $email = shift;
    my $fingerprint = shift;
    my $random;
    my $random_email;
     
    unless($random = &get_db_random()){ # si un random existe : get_db_random
	$random = &init_db_random(); # sinon init_db_random
    }
 
    $random_email = ($random.$email);
 
    if( $fingerprint ) { #si on veut vérifier le fingerprint dans l'url

	if($fingerprint eq &md5_fingerprint($random_email)){
	    return 1;
	}else{
	    return undef;
	}

    }else{ #si on veut créer une url de type http://.../sympa/unsub/$list/$email/&get_fingerprint($email)

	$fingerprint = &md5_fingerprint($random_email);
	return $fingerprint;

    }
}

############################################################
#  md5_fingerprint                                         #
############################################################
#  The algorithm MD5 (Message Digest 5) is a cryptographic #
#  hash function which permit to obtain                    #
#  the fingerprint of a file/data                          #
#                                                          #
# IN : a string                                            #
#                                                          #
# OUT : md5 digest                                         #
#     | undef                                              #
#                                                          #
############################################################
sub md5_fingerprint {
    
    my $input_string = shift;
    return undef unless (defined $input_string);
    chomp $input_string;
    
    my $digestmd5 = new Digest::MD5;
    $digestmd5->reset;
    $digestmd5->add($input_string);
    return (unpack("H*", $digestmd5->digest));
}

############################################################
#  get_db_random                                           #
############################################################
#  This function returns $random                           #
#  which is stored in the database                         #
#                                                          #  
# IN : -                                                   #
#                                                          #
# OUT : $random : the random stored in the database        #
#     | undef                                              #
#                                                          #
############################################################
sub get_db_random {
    
    ## Database and SQL statement handlers
    my ($dbh, $sth, @sth_stack);

    $dbh = &List::db_get_handler();

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
	$dbh = &List::db_get_handler();
    }
    my $statement = sprintf "SELECT random FROM fingerprint_table;";
    
    push @sth_stack, $sth;
    unless ($sth = $dbh->prepare($statement)) {
	&do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    unless ($sth->execute) {
	&do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    my $random = $sth->fetchrow_hashref('NAME_lc');
    
    $sth->finish();
    $sth = pop @sth_stack;

    return $random;

}

############################################################
#  init_db_random                                          #
############################################################
#  This function initializes $random used in               #
#  get_fingerprint if there is no value in the database    #
#                                                          #  
# IN : -                                                   #
#                                                          #
# OUT : $random : the random initialized in the database   #
#     | undef                                              #
#                                                          #
############################################################
sub init_db_random {

    my $range = 89999999999999999999;
    my $minimum = 10000000000000000000;

    my $random = int(rand($range)) + $minimum;

    ## Database and SQL statement handlers
    my ($dbh, $sth, @sth_stack);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    my $statement = sprintf "INSERT INTO fingerprint_table VALUES (%d)", $random;
    
    push @sth_stack, $sth;
    
    unless ($dbh->do($statement)) {
	&do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
       
    return $random;
}

sub get_separator {
    return $separator;
}

## Return the Sympa regexp corresponding to the input param
sub get_regexp {
    my $type = shift;

    if (defined $regexp{$type}) {
	return $regexp{$type};
    }else {
	return '\w+'; ## default is a very strict regexp
    }

}

## convert a string formated as var1="value1";var2="value2"; into a hash.
## Used when extracting from session table some session properties or when extracting users preference from user table
## Current encoding is NOT compatible with encoding of values with '"'
##
sub string_2_hash {
    my $data = shift;
    my %hash ;
    
    pos($data) = 0;
    while ($data =~ /\G;?(\w+)\=\"((\\[\"\\]|[^\"])*)\"(?=(;|\z))/g) {
	my ($var, $val) = ($1, $2);
	$val =~ s/\\([\"\\])/$1/g;
	$hash{$var} = $val; 
    }    

    return (%hash);

}
## convert a hash into a string formated as var1="value1";var2="value2"; into a hash
sub hash_2_string { 
    my $refhash = shift;

    return undef unless ((ref($refhash))&& (ref($refhash) eq 'HASH')) ;

    my $data_string ;
    foreach my $var (keys %$refhash ) {
	next unless ($var);
	my $val = $refhash->{$var};
	$val =~ s/([\"\\])/\\$1/g;
	$data_string .= ';'.$var.'="'.$val.'"';
    }
    return ($data_string);
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

=head3 Calls 

=over 

=item * List::send_notify_to_listmaster

=back 

=cut 

sub save_to_bad {

    my $param = shift;
    
    my $file = $param->{'file'};
    my $hostname = $param->{'hostname'};
    my $queue = $param->{'queue'};

    if (! -d $queue.'/bad') {
	unless (mkdir $queue.'/bad', 0775) {
	    &do_log('notice','Unable to create %s/bad/ directory.',$queue);
	    unless (&List::send_notify_to_listmaster('unable_to_create_dir',$hostname),{'dir' => "$queue/bad"}) {
		&do_log('notice',"Unable to send notify 'unable_to_create_dir' to listmaster");
	    }
	    return undef;
	}
	do_log('debug',"mkdir $queue/bad");
    }
    &do_log('notice',"Saving file %s to %s", $queue.'/'.$file, $queue.'/bad/'.$file);
    unless (rename($queue.'/'.$file ,$queue.'/bad/'.$file) ) {
	&do_log('notice', 'Could not rename %s to %s: %s', $queue.'/'.$file, $queue.'/bad/'.$file, $!);
	return undef;
    }
    
    return 1;
}

=pod 

=head2 sub CleanSpool(STRING $spool_dir, INT $clean_delay)

Clean all messages in spool $spool_dir older than $clean_delay.

=head3 Arguments 

=over 

=item * I<spool_dir> : a string corresponding to the path to the spool to clean;

=item * I<clean_delay> : the delay between the moment we try to clean spool and the last modification date of a file.

=back

=back 

=head3 Return 

=over

=item * 1 if the spool was cleaned withou troubles.

=item * undef if something went wrong.

=back 

=head3 Calls 

=over 

=item * tools::remove_dir

=back 

=cut 

############################################################
#  CleanSpool
############################################################
#  Cleans files older than $clean_delay from spool $spool_dir
#  
# IN : -$spool_dir (+): the spool directory
#      -$clean_delay (+): delay in days 
#
# OUT : 1
#
############################################################## 
sub CleanSpool {
    my ($spool_dir, $clean_delay) = @_;
    &do_log('debug', 'CleanSpool(%s,%s)', $spool_dir, $clean_delay);

    unless (opendir(DIR, $spool_dir)) {
	&do_log('err', "Unable to open '%s' spool : %s", $spool_dir, $!);
	return undef;
    }

    my @qfile = sort grep (!/^\.+$/,readdir(DIR));
    closedir DIR;
    
    my ($curlist,$moddelay);
    foreach my $f (sort @qfile) {

	if ((stat "$spool_dir/$f")[9] < (time - $clean_delay * 60 * 60 * 24)) {
	    if (-f "$spool_dir/$f") {
		unlink ("$spool_dir/$f") ;
		&do_log('notice', 'Deleting old file %s', "$spool_dir/$f");
	    }elsif (-d "$spool_dir/$f") {
		unless (&tools::remove_dir("$spool_dir/$f")) {
		    &do_log('err', 'Cannot remove old directory %s : %s', "$spool_dir/$f", $!);
		    next;
		}
		&do_log('notice', 'Deleting old directory %s', "$spool_dir/$f");
	    }
	}
    }

    return 1;
}


# return a lockname that is a uniq id of a processus (hostname + pid) ; hostname (20) and pid(10) are truncated in order to store lockname in database varchar(30)
sub get_lockname (){
    return substr(substr(hostname(), 0, 20).$$,0,30);   
}

## compare 2 scalars, string/numeric independant
sub smart_lessthan {
    my ($stra, $strb) = @_;
    $stra =~ s/^\s+//; $stra =~ s/\s+$//;
    $strb =~ s/^\s+//; $strb =~ s/\s+$//;
    $! = 0;
    my($numa, $unparsed) = strtod($stra);
    my $numb;
    $numb = strtod($strb)
    	unless ($! || $unparsed !=0);
    if (($stra eq '') || ($strb eq '') || ($unparsed != 0) || $!) {
	return $stra lt $strb;
    } else {
        return $stra < $strb;
    } 
}

## Returns the number of pid identifiers in the pid file.
sub get_number_of_pids {
    my $pidfile = shift;
    my $p_count = 0;
    unless (open(PFILE, $pidfile)){
	fatal_err('Could not open %s, exiting', $pidfile);
    }
    while (<PFILE>){
	$p_count += &count_numbers_in_string($_);
    }
    close PFILE;
    return $p_count;
}

## Returns the counf of numbers found in the string given as argument.
sub count_numbers_in_string {
    my $str = shift;
    my $count = 0;
    $count++ while $str =~ /(\d+\s+)/g;
    return $count;
}

#*******************************************
# Function : wrap_text
# Description : return line-wrapped text.
## IN : text, init, subs, cols
#*******************************************
sub wrap_text {
    my $text = shift;
    my $init = shift;
    my $subs = shift;
    my $cols = shift;
    $cols = 78 unless defined $cols;
    return $text unless $cols;

    if ($use_text_linefold) {
	my $emailre = &tools::get_regexp('email');
	$text = Text::LineFold->new(
	    Language => &Language::GetLang(),
	    OutputCharset => (&Encode::is_utf8($text)? '_UNICODE_': 'utf8'),
	    UserBreaking => ['NONBREAKURI',
			     [qr/\b$emailre\b/ => sub { ($_[1]) }],
			     ],
	    ColumnsMax => $cols
	)->fold($init, $subs, $text);
    } elsif ($use_text_wrap) {
	local ($Text::Wrap::unexpand) = 0;
	local ($Text::Wrap::columns) = $cols + 1;
	$text = Text::Wrap::wrap($init, $subs, $text);
    }

    return $text;
}

#*******************************************
# Function : addrencode
# Description : return formatted (and encoded) name-addr as RFC5322 3.4.
## IN : addr, [phrase, [charset]]
#*******************************************
sub addrencode {
    my $addr = shift;
    my $phrase = (shift || '');
    my $charset = (shift || 'utf8');

    return undef unless $addr =~ /\S/;

    if ($phrase =~ /[^\s\x21-\x7E]/) {
	# Minimal encoding leaves special characters unencoded.
	# In this case do maximal encoding for workaround.
	my $minimal =
	    ($phrase =~ /(\A|\s)[\x21-\x7E]*[\"(),:;<>\@\\][\x21-\x7E]*(\s|\z)/)?
	    'NO': 'YES';
	$phrase = MIME::EncWords::encode_mimewords(
	    Encode::decode('utf8', $phrase),
	    'Encoding' => 'A', 'Charset' => $charset,
	    'Replacement' => 'FALLBACK',
	    'Field' => 'Resent-Sender', # almost longest
	    'Minimal' => $minimal
            );
	return "$phrase <$addr>";
    } elsif ($phrase =~ /\S/) {
	$phrase =~ s/([\\\"])/\\$1/g;
	return "\"$phrase\" <$addr>";
    } else {
	return "<$addr>";
    }
}

1;
