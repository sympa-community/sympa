<!-- RCS Identication ; $Revision$ ; $Date$ -->
<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Nombre :</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD><B>Tema : </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="--LIGHT_COLOR--">
 <TD NOWRAP><B>Lista solicitada por </B></TD><TD WIDTH=100%>[list_request_by] <B>el</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF auto_aliases]
Los "Alias" han sido instalados.
[ELSE]
<TABLE BORDER=1>
<TR BGCOLOR="--LIGHT_COLOR--"><TD align=center>Debería de instalar los "alias" siguientes</TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]
