 ###############################################################
 #                      PlainDigest                            #
 # version: 0.3.1                                              #
 #                                                             #
 # PlainDigest provides an extension to the MIME::Entity       #
 # class that returns a plain text version of an email         #
 # message, suitable for use in plain text digests.            #
 #                                                             #
 # SYNOPSIS:                                                   #
 # (assuming an existing MIME::Entity object as $mail)         #
 #                                                             #
 # use PlainDigest;                                            #
 # $string = $mail->PlainDigest::plain_body_as_string(@opt);   #
 #                                                             #
 # where @opt is an are options, currently:                    #
 # use_lynx:    default to using Lynx when processing HTML     #
 #                                                             #
 # WHAT DOES IT DO?                                            #
 # Most attachments are stripped out and replaced with a       #
 # note that they've been stripped. text/plain parts are       #
 # retained and encoding is 'levelled' to 8bit. A crude        #
 # attempt to convert single part text/html messages to plain  #
 # text is made. For text/plain parts that were not            #
 # originally in chasrset us-ascii or ISO-8859-1 all           #
 # characters above ascii 127 are replaced with '?' and a      #
 # warning added. Parts of type message/rfc822 are recursed    #
 # through in the same way, with brief headers included. Any   #
 # line consisting only of 30 hyphens has the first            #
 # character changed to space (see RFC 1153). Lines are        #
 # wrapped at 80 characters.                                   #
 #                                                             #
 # BUGS                                                        #
 # Probably dozens of them, and possibly dependant on your     #
 # versions of Perl and MIME-Tools (on which it is very        #
 # reliant).                                                   #
 # Seems to ignore any text after a UUencoded attachment.      #
 # Probably horrible if ISO-8859-1 or something close isn't    #
 # you're usual charset.                                       #
 #                                                             #
 # LICENSE                                                     #
 # Written by and (c) Chris Hastie 2004                        #
 # This program is free software; you can redistribute it      #
 # and/or modify it under the terms of the GNU General Public  #
 # License as published by the Free Software Foundation; either#
 # version 2 of the License, or (at your option) any later     #
 # version.                                                    #
 #                                                             #
 # This program is distributed in the hope that it will be     #
 # useful,but WITHOUT ANY WARRANTY; without even the implied   #
 # warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR     #
 # PURPOSE. See the GNU General Public License for more details#
 #                                                             # 
 # You should have received a copy of the GNU General Public   #
 # License along with this program; if not, write to the Free  #
 # Software Foundation, Inc., 59 Temple Place - Suite 330,     #
 # Boston, MA 02111-1307, USA.                                 #
 #                                                             #
 #                                        Chris Hastie         #
 #                                                             #
 ###############################################################
 
 
 package PlainDigest;

 @ISA = qw(MIME::Entity);
 use Mail::Internet;
 use Mail::Address;
 use MIME::Parser;
 use Text::Wrap;
 use MIME::WordDecoder;
 use Language;
 
 sub plain_body_as_string {
 
  local $outstring = "";
  my ($topent, @paramlist) = @_;
  my %params = @paramlist;
  
#  my $output_dir = $params{output_dir} || '.';
  local $use_lynx = $params{use_lynx} || undef;

#  my $parser = new MIME::Parser;
#  $parser->extract_uuencode(1);  
#  $parser->extract_nested_messages(1);
#  $parser->output_dir($output_dir);

  # Convert Mail::Internet object to a MIME::Entity:
#  my @lines = (@{$mail->header}, "\n", @{$mail->body});
#  my $topent = $parser->parse_data(\@lines);
  
  #$topent->dump_skeleton; # for debugging only!
  
  _do_toplevel ($topent);

  # clean up after ourselves
  $topent->purge;
  
  $Text::Wrap::columns = 80;
  return wrap ('','',$outstring);
 }

 sub _do_toplevel {
 
  my $topent = shift;
  if ($topent->effective_type =~ /^text\/plain/i) {
    _do_text_plain($topent);
  }
  elsif ($topent->effective_type =~ /^text\/html/i) {
    _do_text_html($topent);
  }
  elsif ($topent->effective_type =~ /^multipart\/.*/i) {
    _do_multipart ($topent);
  }
  elsif ($topent->effective_type =~ /^message\/rfc822/i) {
    _do_message ($topent);
  } 
  elsif ($topent->effective_type =~ /^message\/delivery-status/i) {
    _do_dsn ($topent);
  }       
  else {
    _do_other ($topent);
  }
  return 1;
 }
 
 sub _do_multipart {

  my $topent = shift;

  # cycle through each part and process accordingly
  foreach $subent ($topent->parts) {    
     if ($subent->effective_type =~ /^text\/plain/i) {
       _do_text_plain($subent);
     }
     elsif ($subent->effective_type =~ /^multipart\/.*/i) {
       _do_multipart ($subent);
     } 
     elsif ($subent->effective_type =~ /^text\/html/i && $topent->effective_type =~ /^multipart\/alternative/i) {
       # assume there's a text/plain alternive, so don't warn
       # that the text/html part has been scrubbed
       next;
     }
     elsif ($subent->effective_type =~ /^message\/rfc822/i) {
       _do_message ($subent);
     } 
     elsif ($subent->effective_type =~ /^message\/delivery-status/i) {
       _do_dsn ($subent);
     }     
     else {
       _do_other ($subent);
     }
  }
  return 1;

 }
 
 sub _do_message {
  my $topent = shift;
  my $msgent = $topent->parts(0);
  my $wdecode = new MIME::WordDecoder::ISO_8859 (1);

  unless ($msgent) {
      $outstring .= sprintf(gettext("----- Malformed message ignored -----\n\n"));
      return undef;
  }
  
  my $from = $msgent->head->get('From');
  my $subject = $msgent->head->get('Subject');
  my $date = $msgent->head->get('Date');
  my $to = $msgent->head->get('To');
  my $cc = $msgent->head->get('Cc');
  unless ($from = $wdecode->decode($from)) {
     $from = "???????";
  }
  unless ($to = $wdecode->decode($to)) {
     $to = "";
  }
  unless ($cc = $wdecode->decode($cc)) {
     $cc = "";
  } 
  unless ($subject = $wdecode->decode($subject)) {
     $subject = "";
  }
  chomp $from;
  chomp $to;
  chomp $cc;
  chomp $subject;
  chomp $date;
  
  my @fromline = Mail::Address->parse($from);
  my $name = $fromline[0]->name();
  $name = $fromline[0]->address() unless $name;

  $outstring .= gettext("\n[Attached message follows]\n-----Original message-----\n"); 
  $outstring .= "Date: $date\n" if $date;
  $outstring .= "From: $from\n" if $from;
  $outstring .= "To: $to\n" if $to;
  $outstring .= "Cc: $cc\n" if $cc;
  $outstring .= "Subject: $subject\n" if $subject;
  $outstring .= "\n";
  
  _do_toplevel ($msgent);
  
  $outstring .= sprintf(gettext("-----End of original message from %s-----\n\n"), $name);
  return 1;
 }

 sub _do_text_plain {
  my $entity = shift;    

  my $charset = $entity->head->mime_attr('content-type.charset'); 
  my $thispart;
  
  # this reads in the decoded body of the current entity  
  if ($io = $entity->open("r")) {
    while (defined($_ = $io->getline)) { 
      chomp $_;
      # if line is 30 hyphens, replace first character with space (RFC 1153)
      if ($_ eq "------------------------------") {
        s/^\-/ /;       
      }
      $thispart .= $_ . "\n";
    }
  }
  
  # scrub the 8bit characters (replace with '?') if the charset
  # isn't us-ascii or iso-8859-1. Add a warning.
  my %ok_charset = (
    'us-ascii' => 1,
    'iso-8859-1' => 1,
    'iso_8859-1' => 1,
    'latin1' => 1,
    'latin-1' => 1,
    'l1' => 1,
    'windows-1252' => 1,
    'iso-ir-100' => 1,
    'ibm819' => 1,
    'cp819' => 1,
    'csisolatin1' => 1
  );
  if ($charset) {
    unless ($ok_charset{lc($charset)}) {
      $outstring .= sprintf (gettext("** Warning: Message part originally used character set %s\n    Some characters may be lost or incorrect **\n\n"), $charset);
      $thispart =~ tr/\x00-\x7F/\?/c;
    }
  }

  $outstring .= $thispart;
  return 1;
 }

 sub _do_other {
  # just add a note that attachment was stripped.
  my $entity = shift;
  $outstring .= sprintf (gettext("\n[An attachment of type %s was included here]\n"), $entity->mime_type);
  return 1;
 }
 
 sub _do_dsn {
   my $entity = shift;
   $outstring .= sprintf (gettext("\n-----Delivery Status Report-----\n"));
   _do_text_plain ($entity);
   $outstring .= sprintf (gettext("-----End of Delivery Status Report-----\n"));
 }

 sub _do_text_html {
 # get a plain text representation of an HTML part
  my $entity = shift;
  my $text;
  my $have_mods = 1;
  my $lynx = undef;
  
  # do we have the relevant HTML::* modules?
  eval {
    require HTML::TreeBuilder;
    require HTML::FormatText;
  } or $have_mods = 0;
  
  # find the path to lynx
  my @path = ('/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin', '.');
  foreach $path (@path) {
    if (-x $path . '/lynx') {
       $lynx = $path . '/lynx';
       last;
    }
  }
  
  $use_lynx = undef if (!$lynx);
  
  if (defined $entity->bodyhandle) {
    
    if ($have_mods && !$use_lynx) { # use perl HTML::* modules 
      eval {
        my $tree = HTML::TreeBuilder->new->parse($entity->bodyhandle->as_string);
        $tree->eof();
        my $formatter = HTML::myFormatText->new(leftmargin => 0, rightmargin => 72);    
        $text = $formatter->format($tree); 
        $tree->delete();
      } ;
      if ($@) {
        $outstring .= gettext("\n[** Unable to process HTML message part **]\n");
        return 1;
      }      
    }

    elsif ($lynx) {     # use Lynx
      eval {
        use IPC::Open3;         
        my $mypid;
        my $read;
        $mypid = open3(\*SEND, \*GET, \*ERR, "lynx --stdin --dump --force_html --hiddenlinks=ignore --localhost --image_links --nolist --noredir --noreferer --realm");
        syswrite( SEND, $entity->bodyhandle->as_string);
        close SEND;
        while (sysread(GET, $read, 4096)) {
          $text .= $read ;
        }   
        close GET;
        close ERR;      
        waitpid($mypid,0);
      };
      if ($@) {
        $outstring .= gettext ("\n[** Unable to process HTML message part **]\n");
        return 1;
      }
    }
    
    else {
      $outstring .= gettext ("\n[ ** Unable to process HTML message part **]\n");
      return 1;      
    }
    
    $outstring .= sprintf(gettext ("[ Text converted from HTML ]\n"));
    
    # deal with 30 hyphens (RFC 1153)
    $text =~ s/\n-{30}(\n|$)/\n -----------------------------\n/;
    $outstring .= $text;
  }
  else {
    $outstring .= gettext("\n[ ** Unable to process HTML message part ** ]\n");   
  }
  return 1;
 }


 package HTML::myFormatText;
 
 # This is a subclass of the HTML::FormatText object. 
 # This subclassing is done to allow internationalisation of some strings
 
 @ISA = qw(HTML::FormatText);
     
 use Language;
 use strict;

 sub img_start   {
  my($self,$node) = @_;
  my $alt = $node->attr('alt');
  $self->out(  defined($alt) ? sprintf(gettext("[ Image%s ]"), ": " . $alt) : sprintf(gettext("[Image%s]"),""));
 }

