<!-- RCS Identication ; $Revision$ ; $Date$ -->


	Se hai dimenticato la password o non ne hai mai ricevuta una relativa a questo servizio<BR>
	ti verr&agrave; recapitata per email:

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
        <FONT COLOR="[dark_color]"><B>indirizzo e-mail</B> </FONT>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Mandami la password">
      </FORM>
