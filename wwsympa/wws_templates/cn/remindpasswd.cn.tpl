<!-- RCS Identication ; $Revision$ ; $Date$ -->

      您忘记了口令，或者您从来没有获得这个服务器上的邮递表口令<BR>
      口令将通过电子邮件发送给您:

      <FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
        <B>您的电子邮件地址</B>: <BR>
        [IF email]
	  [email]
          <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	[ELSE]
	  <INPUT TYPE="text" NAME="email" SIZE="20">
	[ENDIF]
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="给我发送口令">
      </FORM>
