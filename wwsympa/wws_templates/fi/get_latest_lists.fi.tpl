<!-- RCS Identication ; $Revision$ ; $Date$ -->


<TABLE WIDTH="100%">
 <TR bgcolor="[light_color]">
   <TD><B>Luonti pvm</B></TD>
   <TD><B>Listan nimi</B></TD>
   <TD><B>Otsikko</B></TD>
 </TR>

[FOREACH list IN latest_lists]
<TR>
<TD>[list->creation_date]</TD>
<TD><A HREF="[path_cgi]/admin/[list->name]">[list->name]</A></TD>
<TD>[list->subject]</TD>
</TR>
[END]
</TABLE>




