<!-- RCS Identication ; $Revision$ ; $Date$ -->


	Te kas unustasite oma parooli või teil ei ole siin serveris parooli olnudki. <BR>
	Teie parool saadetakse teie e-postiaadressile;

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
  	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <B>Teie e-posti aadress</B>:<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Saada parool">
      </FORM>
