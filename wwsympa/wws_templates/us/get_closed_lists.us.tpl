<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<B>Closed lists</B>
<P>
<TABLE WIDTH="100%">
 <TR bgcolor="[light_color]">
   <TD><B>X</B></TD>
   <TD><B>list name</B></TD>
   <TD><B>list subject</B></TD>
   <TD><B>Requested by</B></TD>
 </TR>

[FOREACH list IN closed]
<TR>
<TD><INPUT TYPE=checkbox name="selected_lists" value="[list->NAME]"></TD>
<TD><A HREF="[path_cgi]/admin/[list->NAME]">[list->NAME]</A></TD>
<TD>[list->subject]</TD>
<TD>[list->by]</TD>
</TR>
[END]
</TABLE>

<INPUT TYPE="submit" NAME="action_purge_list" VALUE="Purge selected lists">

</FORM>



