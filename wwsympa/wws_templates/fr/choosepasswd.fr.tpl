<!-- RCS Identication ; $Revision$ ; $Date$ -->

Vous devez choisir un mot de passe pour votre envirronement
de listes de diffusion <i>Sympa</i>. Ce mot de passe vous permettra
d'accéder aux opérations privilégiées.

<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
<INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">

[IF init_passwd]
  <INPUT TYPE="hidden" NAME="passwd" VALUE="[user->password]">
[ELSE]
  <FONT COLOR="[dark_color]">Mot de passe actuel : </FONT>
  <INPUT TYPE="password" NAME="passwd" SIZE=15>
[ENDIF]

<BR><BR><FONT COLOR="[dark_color]">Nouveau mot de passe : </FONT>
<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
<BR><BR><FONT COLOR="[dark_color]">Confirmation nouveau mot de passe : </FONT>
<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
<BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Envoyer">

</FORM>

