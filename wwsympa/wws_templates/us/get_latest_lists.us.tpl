<!-- RCS Identication ; $Revision$ ; $Date$ -->


<TABLE WIDTH="100%">
 <TR bgcolor="[light_color]">
   <TD><B>Creation date</B></TD>
   <TD><B>Listname</B></TD>
   <TD><B>Subject</B></TD>
 </TR>

[FOREACH list IN latest_lists]
<TR>
<TD>[list->creation_date]</TD>
<TD><A HREF="[path_cgi]/admin/[list->name]">[list->name]</A></TD>
<TD>[list->subject]</TD>
</TR>
[END]
</TABLE>




