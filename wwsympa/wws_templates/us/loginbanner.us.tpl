<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Your password has been sent to your email address [init_email].<BR>
  Please check your e-mail box to provide your password below.
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
[IF use_sso]
[IF use_passwd=1]

To login, select your organization authentication server below.<BR>
If it is not listed or if you don't have any, login using your email and password on the right column.

[ENDIF]
[ELSE]
[IF use_passwd=1]
Login with you email address and password. You can request a password reminder.
[ENDIF]
[ENDIF]

[ENDIF]

<TABLE BORDER=1 width=100% CELLSPACING=0 CELLPADDING=0>
<TR>

[IF use_sso]
<TD valign='top'>
[IF sso_number = 1]

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="sso_login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
	

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>Magic authentification

                [FOREACH server IN sso]
                   <INPUT TYPE="hidden" NAME="auth_service_name" VALUE="[server->NAME]">
                [END]
              </SELECT>
              <INPUT TYPE="submit" NAME="action_sso_login" VALUE="go" SELECTED>

   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 
[ELSE]
    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="sso_login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
	

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>Choose your authentication server 

              <SELECT NAME="auth_service_name" onchange="this.form.submit();">
                [FOREACH server IN sso]
                   <OPTION VALUE="[server->NAME]">[server]
                [END]
              </SELECT>
              <INPUT TYPE="submit" NAME="action_sso_login" VALUE="Go" SELECTED>


   	    </TD>
     	  </TR>
       </TABLE>
 </FORM>
[ENDIF] 
</TD>

[ENDIF]

<TD valign='top'>


<TABLE BORDER=0  width=100% CELLSPACING=0 CELLPADDING=0>
<tr><td>

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>email address <INPUT TYPE="text" NAME="email" SIZE=20 VALUE="[init_email]">
      	      password : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Login" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 



<TABLE border=0><TR>
<TD>
<I>If you never had a password from that server or if you don't remember it :</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      [IF escaped_init_email]
         <A HREF="[path_cgi]/nomenu/sendpasswd/[escaped_init_email]"
      [ELSE]
         <A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]"
      [ENDIF]
       onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login">
     <FONT SIZE=-1><B>Send me a password</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
</TD>

</TR>
</TABLE>




