<!-- RCS Identication ; $Revision$ ; $Date$ -->

Sie m&uuml;ssen nun ein Passwort f&uuml;r Ihre WWSympa-Umgebung w&auml;hlen.
Dieses Passwort ben&ouml;tigen Sie, um die priveligierten Funktionen zu
benutzen.

<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
[ELSE]
  <FONT COLOR="--DARK_COLOR--">Altes Passwort: </FONT>
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR><FONT COLOR="--DARK_COLOR--">Neues Paswort: </FONT>
<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR><FONT COLOR="--DARK_COLOR--">Nocheinmal neues Passwort : </FONT>
<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="&Auml;ndern">

</FORM>

