<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<HR  WIDTH=90%>

<P>
<TABLE>
 <TR>
   <TD Colspan=3 bgcolor="[light_color]"><B>Unbest&auml;tigte Listen</B></TD>
 </TR>
 <TR bgcolor="[light_color]">
   <TD><B>Listenname</B></TD>
   <TD><B>Listentitel</B></TD>
   <TD><B>Beantragt von</B></TD>
 </TR>

[FOREACH list IN pending]
<TR>
<TD><A HREF="[path_cgi]/set_pending_list_request/[list->NAME]">[list->NAME]</A></TD></TD>
<TD>[list->subject]</TD>
<TD>[list->by]</TD>
</TR>
[END]
</TABLE>




