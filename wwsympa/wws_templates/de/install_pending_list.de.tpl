<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
 <TD><B>Listenname:</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD><B>Titel: </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD NOWRAP><B>Liste beantragt von </B></TD><TD WIDTH=100%>[list_request_by] <B>am</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF auto_aliases]
Mail Aliase wurden installiert.
[ELSE]
<TABLE BORDER=1>
<TR BGCOLOR="[light_color]"><TD align=center>Sie sollten die folgenden Aliase in Ihrem EMail-System installieren:</TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]
