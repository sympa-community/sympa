<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      您请求退订邮递表 [list]。<BR>要确认您的请求，请点下面的按钮:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="我退订邮递表 [list]">
	</FORM>

  [ELSIF not_subscriber]

      您没有用邮件地址 [email] 订阅邮递表 [list]。
      <BR><BR>
      您可能使用其它的邮件地址订阅的邮递表。
      请联系邮递表所有者来帮助您退订:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
        您请求退订邮递表 [list]。
	<BR><BR>
	为了确认您的身份，避免其他人违背您的意愿将您从这个邮递表中退订，将发送
	一个包含 URL 的邮件给您。<BR><BR>

	检查您的邮件箱，然后在下面输入 Sympa 发送给您的邮件中的口令。这将
	确认您退订邮递表 [list]。
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>口令</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="退订">
        </FORM>

      	这个口令，和您的邮件地址关联，允许您访问自己的定制环境。

  [ELSIF ! email]
      请给出退订邮递表 [list] 所用的邮件地址。

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>您的邮件地址: </B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	为了确认您退订邮递表 [list]，请在下面输入您的口令:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>口令</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="退订">

<BR><BR>
<I>如果您从来没有从服务器获得过口令，或者您忘记了口令: </I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="给我发送口令">

         </FORM>

  [ENDIF]      













