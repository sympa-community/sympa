<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	您请求订阅邮递表 [list]。<BR>要确认您的请求，请点击下面的按钮: <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="我订阅邮递表 [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	您请求订阅邮递表 [list]。
	<BR><BR>
	为了确认您的身份，避免其他人违背您的意愿为您订阅这个邮递表，将发送一个包含
	您的口令的邮件给您。<BR><BR>

	检查您的邮件箱，然后在下面输入口令。这将确认您订阅邮递表 [list]。
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>口令</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="订阅">
        </FORM>

      	这个口令，和您的邮件地址关联，允许您访问自己的定制环境。

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>您的电子邮件地址</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="提交">
         </FORM>


  [ELSIF status=notauth]

	为了确认您订阅邮递表 [list]，请在下面输入您的口令:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>电子邮件地址</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>口令</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="订阅">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="我的口令 ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>您已经订阅了邮递表 [list]。
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.cn-gb.tpl']

  [ENDIF]      



