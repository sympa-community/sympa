<BR>
[IF password_sent]
  Your password has been sent to your email address [init_email].<BR>
  Please check your e-mail box to provide your password bellow.
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
 You need to login to access your custom WWSympa environment or to perform a
privileged operation (one that requires your email address).
[ELSE]
 Most mailing list features require your email. Some mailing lists are hidden to
 unidentified persons.<BR>
 In order to benefit from the full services provided by this server, you probably
 need to identify yourself first. <BR>
[ENDIF]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="--LIGHT_COLOR--">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="--SELECTED_COLOR--"><b>email <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      password : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Login" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>email</B>, is your subscriber email address<BR>
    <B>password</B>, is your password.<BR><BR>

<TABLE border=0><TR>
<TD>
<I>If you never had a password from that server or if you don't remember it :</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="--DARK_COLOR--">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="center"> 
         <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]"
       onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
     <FONT SIZE=-1><B>Send me a password</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




