####################################################
## Librairie d'analyse de bounce                  ##
## Comité Réseau des Universités - Olivier Salaün ##
## Copyright 1998                                 ##
####################################################

use MIME::Parser;

use strict;

## RFC1891 compliance check
sub rfc1891 {
    my ($fic, $result, $from) = @_;
  
    $/ = "\n";

    my $nbrcpt;
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
 
    my $entity = $parser->read($fic);

    unless ($entity) {
	return undef;
    }

    my $head = $entity->head;
    $$from = $head->get('From', 0);

    $$from =~ s/^.*<(.*)>.*$/$1/;

    my @parts = $entity->parts();

    foreach my $p (@parts) {
	my $h = $p->head();
	my $content = $h->get('Content-type');

	next unless ($content =~ /message\/delivery-status/i);

	my $body = $p->body();

	## Fork, communicate with child via BODY
	my $pid = open BODY, "-|";

	unless (defined($pid)) {
	    die 'Fork failed';
	}

	if (! $pid) {
	    ## Child process
	    print STDOUT @$body;
	    exit;
	}else {
	    ## Multiline paragraph separator
	    $/ = '';

	    while (<BODY>) {

		my ($status, $recipient);
		if (/^Status:\s*(\d+\.\d+\.\d+)$/mi) {
		    $status = $1;
		}
		
		if (/^Final-Recipient:\s*rfc822\s*;\s*(.*)$/mi) {
		    $recipient = $1;
		    $recipient =~ s/^<(.*)>$/$1/;
		    $recipient =~ y/[A-Z]/[a-z]/;
		}
		
		if ($recipient and $status) {
		    $result->{$recipient} = $status;
		    $nbrcpt++;
		}
	    }
	    $/ = "\n";
	    close BODY;
	}
    }

    return $nbrcpt;
}


## Corrige une adresse SMTP
sub corrige {

    my ($adr, $from) = @_;

    ## adresse X400
    if ($adr =~ /^\//) {
	
	my (%x400, $newadr);

	my @detail = split /\//, $adr;
	foreach (@detail) {

	    my ($var, $val) = split /=/;
	    $x400{$var} = $val;
	    #print "\t$var <=> $val\n";

	} 
	    
	$newadr = $x400{PN} || "$x400{s}";
	$newadr = "$x400{g}.".$newadr if $x400{g};
	my ($l, $d) =  split /\@/, $from;

	$newadr .= "\@$d";

	return $newadr;

    }elsif ($adr =~ /\@/) {

	return $adr;

    }elsif ($adr =~ /\!/) {

	my ($dom, $loc) = split /\!/, $adr;
	return "$loc\@$dom";

    }else {

	my ($l, $d) =  split /\@/, $from;
	my $newadr = "$adr\@$d";

	return $newadr;

    }
}
## Analyse d'un rapport de non-remise
## Param 1 : descripteur du fichier contenant le bounce
## //    2 : reference d'un hash pour retourner @ en erreur
## //    3 : reference d'un tableau pour retourner des stats
## //    4 : reference d'un tableau pour renvoyer le bounce
sub anabounce {

    my ($fic, $result, $from) = @_;
    my $entete = 1;
    my $type;
    my %info;
    my ($qmail, $type_9, $type_18, $exchange, $ibm_vm, $lotus, $sendmail_5, $yahoo, $type_21, $exim, $vines,
	$mercury_143, $altavista, $mercury_131, $type_31, $type_32,$exim_173, $type_38, $type_39,
	$type_40, $pmdf, $following_recipients, $postfix);

    ## Le champ separateur de paragraphe est un ensemble
    ## de lignes vides
    $/ = '';

    ## Parcour du bounce, paragraphe par paragraphe
    foreach (<$fic>) {

#	push @$bounce, $_;

	if ($entete) {
	    
	    undef $entete;

	    ## Parcour du paragraphe
	    my @paragraphe = split /\n/, $_;
	    $/ = "\n";
	    my ($champ_courant, %champ);
	    foreach (@paragraphe) {

		if (/^(\S+):\s*(.*)$/) {
		    $champ_courant = $1;
		    $champ_courant =~ y/[A-Z]/[a-z]/;
		    $champ{$champ_courant} = $2;
		}elsif (/^\s+(.*)$/) {
		
		    $champ{$champ_courant} .= " $1";

		}

		## Le champ From:
		$champ{from} =~ /([^\s<]+@[^\s>]+)/;
		$$from = $1;
		
	    }
	    $/ = '';
	    
	    $champ{from} =~ s/^.*<(.+)[\>]$/$1/;
	    $champ{from} =~  y/[A-Z]/[a-z]/;
	    my ($local, $domaine) = split /\@/, $champ{from};
	    
	    if ($champ{subject} =~ /^Returned mail: (Quota exceeded for user (\S+))$/) {

		$info{$2}{error} = $1;
		$type = 27;

	    }

	    if ($champ{'x-failed-recipients'} =~ /^\s*(\S+)$/) {
		$info{$1}{error} = "";
	    }

	}elsif (/^\s*-+ The following addresses (had permanent fatal errors|had transient non-fatal errors|have delivery notifications) -+/m) {
	    
	    my $adr;
	    
	    ## Parcour du paragraphe
	    my @paragraphe = split /\n/, $_;
	    $/ = "\n";
	    foreach (@paragraphe) {
		
		if (/^(\S[^\(]*)/) {
		    $adr = $1;
		    my $error = $2;
		    $adr =~ s/^[\"\<](.+)[\"\>]\s*$/$1/;
		    #print "\tADR : #$adr#\n";
		    $info{$adr}{error} = $error;
		    $type = 1;

		}elsif (/^\s+\(expanded from: (.+)\)/) {
		    #print "\tEXPANDED $adr : $1\n";
		    $info{$adr}{expanded} = $1;
		    $info{$adr}{expanded} =~ s/^[\"\<](.+)[\"\>]$/$1/;
	        }
	    }
	    $/ = '';

	}elsif (/^\s+-+\sTranscript of session follows\s-+/m) {

	    my $adr;

	    ## Parcour du paragraphe
	    my @paragraphe = split /\n/, $_;
	    $/ = "\n";
	    foreach (@paragraphe) {
		
		if (/^(\d{3}\s)?(\S+|\".*\")\.{3}\s(.+)$/) {
		    
		    $adr = $2; 
		    my $cause = $3;
		    $cause =~ s/^(.*) [\(\:].*$/$1/;
		    foreach $a(split /,/, $adr) {

			$a =~ s/^[\"\<]([^\"\>]+)[\"\>]$/$1/;
			$info{$a}{error} = $cause;
			$type = 2;

		    }
		}elsif (/^\d{3}\s(too many hops).*to\s(.*)$/i) {

		    $adr = $2; 
		    my $cause = $1;
		    foreach $a (split /,/, $adr) {

			$a =~ s/^[\"\<](.+)[\"\>]$/$1/;
			$info{$a}{error} = $cause;
			$type = 2;

		    }

		}elsif (/^\d{3}\s.*\s([^\s\)]+)\.{3}\s(.+)$/) {
		
		    $adr = $1; 
		    my $cause = $2;
		    $cause =~ s/^(.*) [\(\:].*$/$1/;
		    foreach $a(split /,/, $adr) {

			$a =~ s/^[\"\<](.+)[\"\>]$/$1/;
			$info{$a}{error} = $cause;
			$type = 2;

		    }
		}
	    }
	    $/ = '';

        ## Rapport Compuserve	    
	}elsif (/^Receiver not found:/m) {

	    ## Parcour du paragraphe
	    my @paragraphe = split /\n/, $_;
	    $/ = "\n";
	    foreach (@paragraphe) {
	    
		$info{$2}{error} = $1 if /^(.*): (\S+)/;
		$type = 3;

	    }
	    $/ = '';

	}elsif (/^\s*-+ Special condition follows -+/m) {

	    my ($cause,$adr);
	    
	    ## Parcour du paragraphe
	    my @paragraphe = split /\n/, $_;
	    $/ = "\n";
	    foreach (@paragraphe) {
	    
		if (/^(Unknown QuickMail recipient\(s\)):/) {
		    $cause = $1;
		    $type = 4;
		    
		}elsif (/^\s+(.*)$/ and $cause) {
		    
		    $adr = $1;
		    $adr =~ s/^[\"\<](.+)[\"\>]$/$1/;
		    $info{$adr}{error} = $cause;
		    $type = 4;

		}
	    }
	    $/ = '';

	}elsif (/^Your message adressed to .* couldn\'t be delivered/m) {

	    my $adr;
	    
            ## Parcour du paragraphe
 	    my @paragraphe = split /\n/, $_;
 	    $/ = "\n";
	    foreach (@paragraphe) {
	    
		if (/^Your message adressed to (.*) couldn\'t be delivered, for the following reason :/) {
		    $adr = $1;
		    $adr =~ s/^[\"\<](.+)[\"\>]$/$1/;
		    $type = 5;
		    
		}else {
		    
		    /^(.*)$/;
		    $info{$adr}{error} = $1;
		    $type = 5;

		}
             }
             $/ = '';

         ## Rapport X400
         }elsif (/^Your message was not delivered to:\s+(\S+)\s+for the following reason:\s+(.+)$/m) {
	     
	     my ($adr, $error) = ($1, $2);
	     $error =~ s/Your message.*$//;
	     $info{$adr}{error} = $error;
	     $type = 6;

	 ## Rapport X400
	 }elsif (/^Your message was not delivered to\s+(\S+)\s+for the following reason:\s+(.+)$/m) {
	     
	     my ($adr, $error) = ($1, $2);
	     $error =~ s/\(.*$//;
	     $info{$adr}{error} = $error;
	     $type = 6;

	 ## Rapport X400
	 }elsif (/^Original-Recipient: rfc822; (\S+)\s+Action: (.*)$/m) {

	     $info{$1}{error} = $2;
	     $type = 16;

         ## Rapport NTMail
	 }elsif (/^The requested destination was:\s+(.*)$/m) {

	     $type = 7;

	 }elsif (($type == 7) && (/^\s+(\S+)/)) {

	     undef $type;
	     my $adr =$1;
	     $adr =~ s/^[\"\<](.+)[\"\>]$/$1/;
	     next unless $adr;
	     $info{$adr}{'error'} = '';

	 ## Rapport Qmail dans prochain paragraphe
	 }elsif (/^Hi\. This is the qmail-send program/m) {

	     $qmail = 1;

	 ## Rapport Qmail
	 }elsif ($qmail) {

	     undef $qmail if /^[^<]/;

	     if (/^<(\S+)>:\n(.*)/m) {

		 $info{$1}{error} = $2;
		 $type = 8;

	     }
	     $/ = '';

	 ## Sendmail
	 }elsif (/^Your message was not delivered to the following recipients:/m) {

	     $type_9 = 1;

	 }elsif ($type_9) {

	     undef $type_9;

	     if (/^\s*(\S+):\s+(.*)$/m) {

		 $info{$1}{error} = $2;
		 $type = 9;

	     }

	 ## Rapport Exchange dans prochain paragraphe
	 }elsif (/^The following recipient\(s\) could not be reached:/m or /^did not reach the following recipient\(s\):/m) {

	     $exchange = 1;

	 ## Rapport Exchange
	 }elsif ($exchange) {

	     undef $exchange;

	     if (/^\s*(\S+).*\n\s+(.*)$/m) {
		 
		 $info{$1}{error} = $2;
		 $type = 10;

	     }

	 ## IBM VM dans prochain paragraphe
	 }elsif (/^Your mail item could not be delivered to the following users/m) {

	     $ibm_vm = 1;

	 ## Rapport IBM VM
	 }elsif ($ibm_vm) {

	     undef $ibm_vm;

	     if (/^(.*)\s+\---->\s(\S+)$/m) {
		 
		 $info{$2}{error} = $1;
		 $type = 12;

	     }
	 ## Rapport Lotus SMTP dans prochain paragraphe
	 }elsif (/^-+\s+Failure Reasons\s+-+/m) {

	     $lotus = 1;

	 ## Rapport Lotus SMTP
	 }elsif ($lotus) {

	     undef $lotus;

	     if (/^(.*)\n(\S+)$/m) {
		 
		 $info{$2}{error} = $1;
		 $type = 13;

	     }
	 ## Rapport Sendmail 5 dans prochain paragraphe
	 }elsif (/^\-+\sTranscript of session follows\s\-+/m) {

	     $sendmail_5 = 1;

	 ## Rapport  Sendmail 5
	 }elsif ($sendmail_5) {

	     undef $sendmail_5;

	     if (/<(\S+)>\n\S+, (.*)$/m) {
		 
		 $info{$1}{error} = $2;
		 $type = 14;

	     }
	 ## Rapport Smap
	 }elsif (/^\s+-+ Transcript of Report follows -+/) {

	     my $adr;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {
		 
		 if (/^Rejected-For: (\S+),/) {

		     $adr = $1;
		     $info{$adr}{error} = "";
		     $type = 17;

		 }elsif (/^\s+explanation (.*)$/) {

		     $info{$adr}{error} = $1;

		 }
	     }
	     $/ = '';

	 }elsif (/^\s*-+Message not delivered to the following:/) {

	     $type_18 = 1;

	 }elsif ($type_18) {

	     undef $type_18;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {
		 
		 if (/^\s*(\S+)\s+(.*)$/) {

		     $info{$1}{error} = $2;
		     $type = 18;

		 }
	     }
	     $/ = '';

	 }elsif (/unable to deliver following mail to recipient\(s\):/m) {

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {
		 
		 if (/^\d+ <(\S+)>\.{3} (.+)$/) {
		     
		     $info{$1}{error} = $2;
		     $type = 19;

		 }
	     }
	     $/ = '';

	 ## Rapport de Yahoo dans paragraphe suivant
	 }elsif (/^Unable to deliver message to the following address\(es\)/m) {

	     $yahoo = 1;

	 ## Rapport Yahoo
	 }elsif ($yahoo) {

	     undef $yahoo;

	     if (/^<(\S+)>:\s(.+)$/m) {
		 
		 $info{$1}{error} = $2;
		 $type = 20;

	     }

	 }elsif (/^Content-Description: Session Transcript/m) {

	     $type_21 = 1;

	 }elsif ($type_21) {

	     undef $type_21;

	     
	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {
		 
		 if (/<(\S+)>\.{3} (.*)$/) {
		 
		     $info{$1}{error} = $2;
		     $type = 21;

		 }
	     }
	     $/ = '';

	 }elsif (/^Your message has encountered delivery problems\s+to local user \S+\.\s+\(Originally addressed to (\S+)\)/m or /^Your message has encountered delivery problems\s+to (\S+)\.$/m or /^Your message has encountered delivery problems\s+to the following recipient\(s\):\s+(\S+)$/m) {

	     my $adr = $2 || $1;
	     $info{$adr}{error} = "";
	     $type = 22;
		 
	 }elsif (/^(The user return_address (\S+) does not exist)/) {

	     $info{$2}{error} = $1;
	     $type = 23;

	 ## Rapport Exim paragraphe suivant
	 }elsif (/^A message that you sent could not be delivered to all of its recipients/m or /^The following address\(es\) failed:/m) {

	     $exim = 1;

	 ## Rapport Exim
	 }elsif ($exim) {

	     undef $exim;

	     if (/^\s*(\S+):\s+(.*)$/m) {
		 
		 $info{$1}{error} = $2;
		 $type = 24;

	     }elsif (/^\s*(\S+)$/m) {
		 $info{$1}{error} = "";
	     }

	 ## Rapport VINES-ISMTP par. suivant
	 }elsif (/^Message not delivered to recipients below/m) {

	     $vines = 1;

	 ## Rapport VINES-ISMTP
	 }elsif ($vines) {

	     undef $vines;

	     if (/^\s+\S+:.*\s+(\S+)$/m) {
		 
		 $info{$1}{error} = "";
		 $type = 25;
		 
	     }

	 ## Rapport Mercury 1.43 par. suivant
	 }elsif (/^The local mail transport system has reported the following problems/m) {

	     $mercury_143 = 1;
	     
	 ## Rapport Mercury 1.43
	 }elsif ($mercury_143) {
	     
	     undef $mercury_143;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/<(\S+)>\s+(.*)$/) {
		     
		     $info{$1}{error} = $2;
		     $type = 26;
		 }
	     }
	     $/ = '';

	 ## Rapport de AltaVista Mail dans paragraphe suivant
	 }elsif (/unable to deliver mail to the following recipient\(s\):/m) {

	     $altavista = 1;

	 ## Rapport AltaVista Mail
	 }elsif ($altavista) {

	     undef $altavista;

	     if (/^(\S+):\n.*\n\s*(.*)$/m) {
		 
		 $info{$1}{error} = $2;
		 $type = 27;

	     }

	 ## Rapport SMTP32
	 }elsif (/^(User mailbox exceeds allowed size): (\S+)$/m) {

	     $info{$2}{error} = $1;
	     $type = 28;

	 }elsif (/^The following recipients did not receive this message:$/m) {

	     $following_recipients = 1;

	 }elsif ($following_recipients) {

	     undef $following_recipients;

	     if (/^\s+<(\S+)>/) {
		 
		 $info{$1}{error} = "";
		 $type = 29;

	     }

	 ## Rapport Mercury 1.31 par. suivant
	 }elsif (/^One or more addresses in your message have failed with the following/m) {

	     $mercury_131 = 1;
	     
	 ## Rapport Mercury 1.31
	 }elsif ($mercury_131) {
	     
	     undef $mercury_131;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/<(\S+)>\s+(.*)$/) {
		     
		     $info{$1}{error} = $2;
		     $type = 30;
		 }
	     }
	     $/ = '';

	 }elsif (/^The following recipients haven\'t received this message:/m) {

	     $type_31 = 1;
	     
	 }elsif ($type_31) {
	     
	     undef $type_31;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/(\S+)$/) {
		     
		     $info{$1}{error} = "";
		     $type = 31;
		 }
	     }
	     $/ = '';

	 }elsif (/^The following destination addresses were unknown/m) {

	     $type_32 = 1;

	 }elsif ($type_32) {
	     
	     undef $type_32;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/<(\S+)>/) {
		     
		     $info{$1}{error} = "";
		     $type = 32;
		 }
	     }
	     $/ = '';

	 }elsif (/^-+Transcript of session follows\s-+$/m) {

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/^(\S+)$/) {
		     
		     $info{$1}{error} = "";
		     $type = 33;

		 }elsif (/<(\S+)>\.{3} (.*)$/) {

		     $info{$1}{error} = $2;
		     $type = 33;

		 }
	     }
	     $/ = '';

	 ## Rapport Bigfoot
	  }elsif (/^The message you tried to send to <(\S+)>/m) {
	      $info{$1}{error} = "destination mailbox unavailable";
	      
	  }elsif (/^The destination mailbox (\S+) is unavailable/m) {

	     $info{$1}{error} = "destination mailbox unavailable";
	     
	 }elsif (/^The following message could not be delivered because the address (\S+) does not exist/m) {

	     $info{$1}{error} = "user unknown";
	     
	 }elsif (/^Error-For:\s+(\S+)\s/) {
    
             $info{$1}{error} = "";

         ## Rapport Exim 1.73 dans proc. paragraphe
	 }elsif (/^The address to which the message has not yet been delivered is:/m) {

	     $exim_173 = 1;

         ## Rapport Exim 1.73
	 }elsif ($exim_173) {
	     
	     undef $exim_173;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/(\S+)/) {
		     
		     $info{$1}{error} = "";
		     $type = 37;
		 }
	     }
	     $/ = '';

	 }elsif (/^This Message was undeliverable due to the following reason:/m) {

	     $type_38 = 1;

	 }elsif ($type_38) {
	     
	     undef $type_38 if /Recipient:/;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/\s+Recipient:\s+<(\S+)>/) {
		     
		     $info{$1}{error} = "";
		     $type = 38;

		 }elsif (/\s+Reason:\s+<(\S+)>\.{3} (.*)/) {

		     $info{$1}{error} = $2;
		     $type = 38;

		 }
	     }
	     $/ = '';

	 }elsif (/Your message could not be delivered to:/m) {

	     $type_39 = 1;

	 }elsif ($type_39) {
	     
	     undef $type_39;

             if (/^(\S+)/) {
		     
		 $info{$1}{error} = "";
		 $type = 39;
    
	     }
	 }elsif (/Session Transcription follow:/m) {

             if (/^<+\s+\d+\s+(.*) for \((.*)\)$/m) {
		     
		 $info{$2}{error} = $1;
		 $type = 43;
    
	     }

	 }elsif (/^This message was returned to you for the following reasons:/m) {

	     $type_40 = 1;

	 }elsif ($type_40) {
	     
	     undef $type_40;

             if (/^\s+(.*): (\S+)/) {
		     
		 $info{$2}{error} = $1;
		 $type = 40;
    
	     }

         ## Rapport PMDF dans proc. paragraphe
	 }elsif (/^Your message cannot be delivered to the following recipients:/m or /^Your message has been enqueued and undeliverable for \d day\s*to the following recipients/m) {

         $pmdf = 1;

         ## Rapport PMDF
	 }elsif ($pmdf) {

             my $adr;
             undef $pmdf;

	     ## Parcour du paragraphe
	     my @paragraphe = split /\n/, $_;
	     $/ = "\n";
	     foreach (@paragraphe) {

		 if (/\s+Recipient address:\s+(\S+)/) {
		     
		     $adr = $1;
		     $info{$adr}{error} = "";
		     $type = 41;
	
		 }elsif (/\s+Reason:\s+(.*)$/) {

		     $info{$adr}{error} = $1;
		     $type = 41;

		 }
	     }
	     $/ = '';

         ## Rapport MDaemon
	 }elsif (/^(\S+) - (no such user here)\.$/m) {

	     $info{$1}{error} = $2;
	     $type = 42;

         # Postfix dans le prochain paragraphe
         }elsif (/^This is the Postfix program/m) {
             $postfix = 1;
	 ## Rapport Postfix
         }elsif ($postfix) {

	     undef $postfix if /THIS IS A WARNING/; # Pas la peine de le traiter

	     if (/^<(\S+)>:\s(.*)/m) {
		 my ($addr,$error) = ($1,$2);

		 if ($error =~ /^host\s[^:]*said:\s(\d+)/) {
		     $info{$addr}{error} = $1;
		 }
		 elsif ($error =~ /^([^:]+):/) {
		     $info{$addr}{error} = $1;
		 }else {
		     $info{$addr}{error} = $error;
		 }
	     }
	     $/ = '';
	 ## Wanadoo    
	 }elsif (/^(\S+); Action: Failed; Status: \d.\d.\d \((.*)\)/m) {
	     $info{$1}{error} = $2;
	 }
    }


    my $count=0;
    ## On met les adresses au clair
    foreach my $a1 (keys %info) {

	next unless ($a1 and ref ($info{$a1}));

        $count++;
	my ($a2, $a3);
 
	$a2 = $a1;

	unless (! $info{$a1}{expanded} or ($a1 =~ /\@/ and $info{$a1}{expanded} !~ /\@/) ) {

	    $a2 = $info{$a1}{expanded};

	}

	$a3 = &corrige($a2, $$from);
#        print "CORRECTION : $a2 --> $a3\n" if $a2 ne $a3;

        $a3 =~ y/[A-Z]/[a-z]/;
        $a3 =~ s/^<(.*)>$/$1/;

#        $result->{$a3}{error} = $info{$a1}{error};
         $result->{$a3} = lc ($info{$a1}{error});
    }
   
#   print "$b\n" if ! $type;
    return $count;
}


1; #return true





