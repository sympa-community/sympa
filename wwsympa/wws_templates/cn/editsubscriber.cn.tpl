<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">邮递表订阅者信息</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>Email: <A HREF="mailto:[current_subscriber->email]">[subscriber->email]</A>
<DD>名字: <INPUT NAME="gecos" VALUE="[current_subscriber->gecos]" SIZE="25">
<DD>订阅时间: [current_subscriber->date]
<DD>接收: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>可见性: [current_subscriber->visibility]
<DD>语言: [current_subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="更新">
<INPUT TYPE="submit" NAME="action_del" VALUE="取消用户的订阅">
<INPUT TYPE="checkbox" NAME="quiet"> 安静
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">退信地址</FONT>
</TD></TR><TR><TD>
<DL>
<DD>状态: [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>退信计数: [current_subscriber->bounce_count]
<DD>时间: 从 [current_subscriber->first_bounce] 到 [current_subscriber->last_bounce]
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">查看最后的退信</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="重置错误计数">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



