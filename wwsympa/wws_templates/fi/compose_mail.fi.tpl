<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">
Lähettäjä: [user->email]<BR>
Vastaanottaja: [to]<BR>
Otsikko: <INPUT TYPE="text" SIZE ="45" NAME="subject" VALUE="[subject]">
<INPUT TYPE="submit" NAME="action_send_mail" VALUE="Lähetä tämä viesti">
<BR>
<INPUT TYPE="hidden" NAME="in_reply_to" value="[in_reply_to]">
<INPUT TYPE="hidden" NAME="message_id" value="[message_id]">
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="to" VALUE="[to]">

<TEXTAREA NAME="body" COLS=80 ROWS=25>
</TEXTAREA>

</FORM>
