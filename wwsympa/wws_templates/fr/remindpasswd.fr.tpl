
      Vous avez oublié votre mot de passe ou vous n'avez pas encore de mot de
      passe sur ce serveur<BR>
      Un mot de passe va vous être envoyé par email :

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
        <B>Votre adresse électronique</B> :<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Envoyez-moi mon mot de passe">
      </FORM>
