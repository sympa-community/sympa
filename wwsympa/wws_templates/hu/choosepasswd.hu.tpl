<!-- RCS Identication ; $Revision$ ; $Date$ -->

A WWWSympa használatához jelszóval kell rendelkezned. Csak a 
jelszó ismeretében tudod a fontos beállításokat megváltoztatni.

<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
[ELSE]
  <FONT COLOR="[dark_color]">Aktuális jelszó: </FONT>
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR><FONT COLOR="[dark_color]">Új jelszó: </FONT>
<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR><FONT COLOR="[dark_color]">Új jelszó mégegyszer: </FONT>
<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Elküld">

</FORM>

