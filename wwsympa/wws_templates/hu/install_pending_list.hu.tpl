<!-- RCS Identication ; $Revision$ ; $Date$ -->

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
 <TD><B>Lista neve:</B></TD><TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD><B>Tématerülete: </B></TD><TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
 <TD NOWRAP>A lista mûködését [list_request_date]-ei <b>napon</b></TD><TD WIDTH=100%>[list_request_by] <B>kérvényezte</B>.</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
[IF auto_aliases]
A lista bejegyzések (aliases) elmentve.
[ELSE]
<TABLE BORDER=1>
<TR BGCOLOR="[light_color]"><TD align=center>A levelezõrendszernek megadandó bejegyzések (aliases):</TD></TR>
<TR>
<TD>
<pre><code>
[aliases]
</code></pre>
</TD>
</TR>
</TABLE>
[ENDIF]
