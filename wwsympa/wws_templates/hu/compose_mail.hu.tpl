<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">
Feladó: [user->email]<BR>
Címzett: [to]<BR>
Tárgy: <INPUT TYPE="text" SIZE ="25" NAME="subject">
<INPUT TYPE="submit" NAME="action_send_mail" VALUE="Küldd el a levelet">
<BR>

  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">

<TEXTAREA NAME="body" COLS=80 ROWS=25>
</TEXTAREA>

</FORM>