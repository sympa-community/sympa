<!-- RCS Identication ; $Revision$ ; $Date$ -->

Sinun tarvitsee valita salasana WWSympa j‰rjestelm‰‰ varten.
Tarvitset salasanaa sis‰‰nkirjautumisessa.

<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
[ELSE]
  <FONT COLOR="[dark_color]">Nykyinen salasana : </FONT>
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR><FONT COLOR="[dark_color]">Uusi salasana : </FONT>
<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR><FONT COLOR="[dark_color]">Uusi salasana uudelleen : </FONT>
<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="L‰het‰">

</FORM>

