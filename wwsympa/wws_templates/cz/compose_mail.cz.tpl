<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">
Od: [user->email]<BR>
Pro: [mailto]<BR>
Subjekt: <INPUT TYPE="text" SIZE ="25" NAME="subject">
<INPUT TYPE="submit" NAME="action_send_mail" VALUE="Poslat tuto zprávu">
<BR>

<INPUT TYPE="hidden" NAME="in_reply_to" value="[in_reply_to]">
<INPUT TYPE="hidden" NAME="message_id" value="[message_id]">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="to" VALUE="[local_to] [domain_to]">

<TEXTAREA NAME="body" COLS=80 ROWS=25>
</TEXTAREA>

</FORM>
