<!-- RCS Identication ; $Revision$ ; $Date$ -->
<P>
Here is a description of the reception modes available in Sympa. These options
are exclusive, which means that you can't set 2 different reception modes at the
same time. Only a subset might be available for a mailing list.
</P>
<UL>

<LI>Digest<BR>
Instead of receiving mail from the list in a normal manner, the subscriber will periodically 
receive it in a Digest. This Digest compiles a group of messages from the list, using
 multipart/digest MIME format. 
<BR><BR>
The sending period for these Digests is defined by the list owner.<BR><BR>
	
<LI>Summary<BR> 

Instead of receiving mail from the list in a normal manner, the subscriber will periodically 
receive the list of messages. This mode is very close to the Digest reception mode but the 
subscriber receives only the list of messages. 
<BR><BR>

<LI>Nomail <BR>

This mode is used when a subscriber no longer wishes to receive mail from the list, but 
nevertheless wishes to retain the possibility of posting to the list. This mode therefore 
prevents the subscriber from unsubscribing and subscribing later on. <BR><BR>

<LI>Txt <BR>

This mode is used when a subscriber wishes to receive mails sent in both format txt/html and 
txt/plain only in txt/plain format.<BR><BR>

<LI>Html<BR> 

This mode is used when a subscriber wishes to receive mails sent in both format txt/html and 
txt/plain only in txt/html format.<BR><BR>

<LI>Urlize<BR> 

This mode is used when a subscriber wishes not to receive attached files. The attached files are 
replaced by an URL leading to the file stored on the list site. <BR><BR>

<LI>Not_me<BR> 

This mode is used when a subscriber wishes not to receive back the message that he has sent to 
the list. <BR><BR>

<LI>Normal<BR>

This option is mainly used to cancel the nomail, summary or digest modes. If the subscriber was 
in nomail mode, he or she will again receive mail from the list in a normal manner. <BR><BR>

</UL>