<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
 <TD><B>邮递表名: </B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD><B>主题: </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD NOWRAP><B>邮递表由</B></TD><TD WIDTH=100%>[list_request_by]<B>请求于</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF list_status=pending]
<TABLE BORDER=0>
<TR>
<TD>
<FORM ACTION="[path_cgi]" METHOD=POST>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="serial" VALUE="[list_serial]">

<MENU>
<INPUT TYPE="radio" NAME="status" VALUE="closed">关闭它 &nbsp;&nbsp;
<INPUT TYPE="radio" NAME="status" VALUE="open">安装它 &nbsp;&nbsp;
</MENU>
</TD><TD>
<TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_install_pending_list" VALUE="提交">
</FORM>
</TD>
</TR>
</TABLE>
<BR><HR><BR>
[ENDIF]
[ENDIF]
<TABLE BORDER=0 WIDTH=100%>
<TR>
 <TD ALIGN=CENTER>
   <B>信息文件</B> 
   [IF is_listmaster]
      ([list_info])
   [ENDIF]
 </TD>
</TR>
<TR>
 <TD>
     <TABLE WIDTH=100% BORDER=1>
      <TR><TD><CODE><PRE>
       [INCLUDE list_info]
      </PRE></CODE></TD></TR>
     </TABLE>
 </TD>
</TR>
<TR>
 <TD ALIGN=CENTER><B>配置文件</B>
   [IF is_listmaster]
      ([list_config])
   [ENDIF]
 </TD>
</TR><TR>
 <TD><TABLE WIDTH=100% border=1>
      <TR><TD><CODE><PRE>
        [INCLUDE list_config]
      </PRE></CODE></TD></TR>
     </TABLE>
 </TD>
</TR>
</TABLE>


