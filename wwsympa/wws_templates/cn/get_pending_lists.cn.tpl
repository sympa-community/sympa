
<FORM ACTION="[path_cgi]" METHOD=POST>

<HR  WIDTH=90%>

<P>
<TABLE>
 <TR>
   <TD Colspan=3 bgcolor="#ccccff"><B>待处理的邮递表</B></TD>
 </TR>
 <TR bgcolor="#ccccff">
   <TD><B>邮递表名</B></TD>
   <TD><B>邮递表主题</B></TD>
   <TD><B>请求者</B></TD>
 </TR>

[FOREACH list IN pending]
<TR>
<TD><A HREF="[path_cgi]/set_pending_list_request/[list->NAME]">[list->NAME]</A></TD></TD>
<TD>[list->subject]</TD>
<TD>[list->by]</TD>
</TR>
[END]
</TABLE>




