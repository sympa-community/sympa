<!-- RCS Identication ; $Revision$ ; $Date$ -->
Trebuie sa alegi o parola pentru mediul WWSympa. Ai nevoie de aceasta parola 
pentru a accesa mai multe optiunile/servicii. 
<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
  [ELSE] <FONT COLOR="[dark_color]">Parola actuala: </FONT> 
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR>
  <FONT COLOR="[dark_color]">Parola noua: </FONT> 
  <INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR>
  <font color="[dark_color]">Confirma parola noua: </font> 
  <INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR>
  <INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Trimite">

</FORM>

