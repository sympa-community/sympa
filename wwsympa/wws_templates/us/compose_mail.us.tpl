<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">
From: [user->email]<BR>
To: [to]<BR>
Subject: <INPUT TYPE="text" SIZE ="25" NAME="subject">
<INPUT TYPE="submit" NAME="action_send_mail" VALUE="Send this mail">
<BR>

  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">

<TEXTAREA NAME="body" COLS=80 ROWS=25>
</TEXTAREA>

</FORM>