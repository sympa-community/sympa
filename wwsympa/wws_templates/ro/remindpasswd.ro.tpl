<!-- RCS Identication ; $Revision$ ; $Date$ -->
Ti-ai uitat parola sau nu ai avut parola pentru acest server, iti va fi trimis
prin email: 
<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
  	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
  <B>Adresa ta de email</B> :<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;
  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Trimite-mi parola">
      </FORM>
