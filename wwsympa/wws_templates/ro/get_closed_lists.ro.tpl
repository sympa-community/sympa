<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>
  <B>Liste inchise</B> 
  <P>
<TABLE WIDTH="100%">
 <TR bgcolor="[light_color]">
   <TD><B>X</B></TD>
      <TD><B>denumire lista</B></TD>
      <TD><B>subiectul listei </B></TD>
      <TD><B>Ceruta de catre</B></TD>
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



