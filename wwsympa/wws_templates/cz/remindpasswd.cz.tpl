<!-- RCS Identication ; $Revision$ ; $Date$ -->


      Zapomnìl jste Va¹e heslo, nebo jste zde ¾ádné heslo nemìl.
   <BR> Heslo Vám bude odesláno emailem :

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="sendpasswd">
  	  <INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <B>Va¹e emailová adresa</B> :<BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Za¹lete mi heslo">
      </FORM>
