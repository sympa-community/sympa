<!-- RCS Identication ; $Revision$ ; $Date$ -->
<BR>
[IF password_sent]
  您的口令已经被发送到您的 Email 地址 [init_email]。<BR>
  请检查您的 Email 邮件箱获得您的口令，并输入到下面。<BR><BR>
[ENDIF]

[IF action=loginrequest]
 您需要登录来使用您定制的 WWSympa 环境，或进行一个特权操作(需要您的 email 地址)。
[ELSE]
 大多数的邮递表特性需要您的 email 地址。某些邮递表不会被未经确认的人看到。<BR>
 如果想要获得本服务器提供的完全的服务，您可能需要首先确认您自己的身份。<BR>
[ENDIF]

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
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>邮件地址: <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      口令: </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="登录" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 

<CENTER>

    <B>邮件地址</B>，是您的订阅 email 地址<BR>
    <B>口令</B>，是您的口令。<BR><BR>

<TABLE border=0><TR>
<TD>
<I>如果您没有从服务器获得过口令或您忘记了口令: </I>
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
     <FONT SIZE=-1><B>给我发送口令</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>
</TD></TR></TABLE>
</CENTER>




