<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<B>Closed lists</B>
<P>
<TABLE WIDTH="100%">
 <TR bgcolor="[light_color]">
   <TD><B>X</B></TD>
   <TD><B>Nombre de la lista</B></TD>
   <TD><B>Tema de la lista</B></TD>
   <TD><B>Solicitada por</B></TD>
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

<INPUT TYPE="submit" NAME="action_purge_list" VALUE="Borrar listas seleccionadas">

</FORM>



