<!-- RCS Identication ; $Revision$ ; $Date$ -->


      Olet unohtanut salasanasi, tai et ole sit‰ koskaan saanut<BR>
      se l‰hetet‰‰n sinulle emailina :

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
  	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <B>Email osoitteesi</B> :<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="L‰het‰ salasana">
      </FORM>
