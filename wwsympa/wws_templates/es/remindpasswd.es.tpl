<!-- RCS Identication ; $Revision$ ; $Date$ -->


      Usted no tiene una contraseña en este servidor o se le ha olvidado.<br>
      Introduzca su dirección de correo electrónico y se la mandaremos :

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
        <FONT COLOR="--DARK_COLOR--"><B>Dirección E-mail</B> </FONT>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Enviar">
      </FORM>
