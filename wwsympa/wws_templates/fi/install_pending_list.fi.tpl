<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
 <TD><B>Listan nimi:</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD><B>Otsikko : </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD NOWRAP><B>Listan pyytäjä </B></TD><TD WIDTH=100%>[list_request_by] <B>pvm</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF auto_aliases]
Aliakset on asennettu.
[ELSE]
<TABLE BORDER=1>
<TR BGCOLOR="[light_color]"><TD align=center>Aliakset jotka sinun tulee asentaa postiohjelmaan</TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]
[ENDIF]
