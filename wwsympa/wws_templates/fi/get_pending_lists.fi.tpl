<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<HR  WIDTH=90%>

<P>
<TABLE>
 <TR>
   <TD Colspan=3 bgcolor="[light_color]"><B>Odottavat listat</B></TD>
 </TR>
 <TR bgcolor="[light_color]">
   <TD><B>listan nimi</B></TD>
   <TD><B>listan otsikko</B></TD>
   <TD><B>Pyytäjä</B></TD>
 </TR>

[FOREACH list IN pending]
<TR>
<TD><A HREF="[path_cgi]/set_pending_list_request/[list->NAME]">[list->NAME]</A></TD>
<TD>[list->subject]</TD>
<TD>[list->by]</TD>
</TR>
[END]
</TABLE>
</FORM>



