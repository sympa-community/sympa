<!-- RCS Identication ; $Revision$ ; $Date$ -->
<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
 <TD><B>Nombre :</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD><B>Tema : </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
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
<TR BGCOLOR="[light_color]"><TD align=center>Debería de instalar los "alias" siguientes</TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]
