<!-- RCS Identication ; $Revision$ ; $Date$ -->
<P>
This is a description of the reception modes available in Sympa. These options
are mutually exclusive, which means that you can't set two different reception
modes at the same time. Only some of the modes might be available for specific
mailing lists.
</P>
<UL>

<LI>Digest<BR>
Instead of receiving individual mail messages from the list, the subscriber will periodically 
receive batched messages in a Digest. This Digest compiles a group of messages from the list, using
the multipart/digest MIME format. 
<BR><BR>
The sending interval for these Digests is defined by the list owner.<BR><BR>
	
<LI>Summary<BR> 

Instead of receiving individual mail messages from the list, the subscriber will periodically 
receive a list of messages. This mode is very close to the Digest reception mode but the 
subscriber receives only the list of messages. 
<BR><BR>

<LI>Nomail <BR>

This mode is used when a subscriber no longer wishes to receive mail from the list, but 
nevertheless wishes to retain the ability to post to the list. This mode therefore 
prevents the subscriber from unsubscribing and subscribing later on. <BR><BR>

<LI>Txt <BR>

This mode is used when a subscriber wishes to receive mails sent in both HTML and plain text formats
only in plain text format.<BR><BR>

<LI>Html<BR> 

This mode is used when a subscriber wishes to receive mails sent in both HTML and plain text formats
only in HTML format.<BR><BR>

<LI>Urlize<BR> 

This mode is used when a subscriber does not want to receive attached files. The attached files are 
replaced by a URL leading to the file stored on the list site. <BR><BR>

<LI>Not_me<BR> 

This mode is used when a subscriber does not want to receive copies of messages that he or she has sent to 
the list. <BR><BR>

<LI>Normal<BR>

This option is used mainly to cancel the nomail, summary or digest modes. If the subscriber was 
in nomail mode, he or she will again receive individual mail messages from the list. <BR><BR>

</UL>
