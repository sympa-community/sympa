<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Privilege for adding (ADD command) a subscriber to the list
[ELSIF p->NAME=anonymous_sender]
  To hide the sender's email address before distributing the message.
  It is replaced by the provided email address.
[ELSIF p->NAME=archive]
  Privilege for reading mail archives and frequency of archiving
[ELSIF p->NAME=owner]
  Owners are managing subscribers of the list. They may review subscribers,
 add or delete email addresses from the mailing list. If you are privileged
 owner of the list, you can choose other owners for the mailing list. 
Privileged owners may edit a bit more options than other owners. There can
only be one privileged owner per list ; his/her email address may not
be edited from the web.
[ELSIF p->NAME=editor]
Editors are responsible of messages moderation. If the mailing list is moderated, messages posted to the list will first be passed to the editors, 
who will decide to distribute or to reject it. <BR>
FYI: Defining editors will not make the list moderated ; you will have to
set the "send" parameter.<BR>
FYI: If the list is moderated, the first editor distributing or rejecting 
a message will make the decision for other editors. If none of them make 
a decision, the message will remain unmoderated in the moderation spool.
[ELSE]
  No Comment
[ENDIF]

</DL>
[END]
	