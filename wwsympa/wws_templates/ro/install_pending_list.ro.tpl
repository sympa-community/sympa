

<br>

<BR>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
<TD>
<TABLE BORDER=0 WIDTH=100% >
<TR BGCOLOR="[light_color]">
          <TD><B>Denimire lista:</B></TD>
          <TD WIDTH=100% >[list]</TD>
</TR>
<TR BGCOLOR="[light_color]">
          <TD><B>Subiect : </B></TD>
          <TD WIDTH=100%>[list_subject]</TD>
</TR>
<TR BGCOLOR="[light_color]">
          <TD NOWRAP><B>Lista ceruta de</B></TD>
          <TD WIDTH=100%>[list_request_by] <B>on</B> [list_request_date]</TD>
</TR>
</TABLE>
</TD>
</TR>
</TABLE>
<BR><BR>
[IF is_listmaster]
  [IF auto_aliases]
   Aliasurile au fost instalate. 
  [ELSE] 
<TABLE BORDER=1>
<TR BGCOLOR="[light_color]">
    <TD align=center>Aliasurile pe care trebuie sa le instalezi in mailer</TD>
  </TR>
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