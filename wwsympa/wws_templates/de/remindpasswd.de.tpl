<!-- RCS Identication ; $Revision$ ; $Date$ -->

      Falls Sie noch nie ein Passwort f&uuml;r diesen Server hatten oder
      sich nicht mehr erinnern, k&ouml;nnen Sie sich ein Passwort per EMail
      zusenden lassen:

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
  	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <B>Ihre EMail-Adresse</B>:<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Passwort zuschicken">
      </FORM>
