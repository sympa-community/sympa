<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Listname :</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Subject : </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD NOWRAP><B>List requested by </B></TD><TD WIDTH=100%>[list_request_by] <B>on</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF auto_aliases]
Aliases have been installed.
[ELSE]
<TABLE BORDER=1>
<TR BGCOLOR="--LIGHT_COLOR--"><TD align=center>Aliases you should install in your mailer</TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]