<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H1>Drepturi de acces pentru documetul [path]</H1>
    Proprietar : [owner] <BR>
Ultima actualizare : [doc_date] <BR>
Descriere : [doc_title] <BR>
<BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]"> 
  Nivelul precedent</A></H3>

<TABLE width=100%>

  <TR VALIGN="top">
  <TD>

  <FORM ACTION="[path_cgi]" METHOD="POST">
        <B>Acces Read</B><BR>
  <SELECT NAME="read_access">
  [FOREACH s IN scenari_read]
    <OPTION VALUE='[s->scenario_name]' [s->selected]>[s->scenario_label]
  [END]
  </SELECT>
  <BR>
        <B>Acces Edit</B><BR>
  <SELECT NAME="edit_access">
  [FOREACH s IN scenari_edit]
    <OPTION VALUE='[s->scenario_name]' [s->selected]>[s->scenario_label]
  [END]
  </SELECT>
  <BR>
   
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
        <INPUT TYPE="submit" NAME="action_d_change_access" VALUE="modifica optiune acces">
   </FORM>

   </TD>

   [IF set_owner]
     
    <TD> <B>Configureaza proprietarul pentru directorul [path]</B> 
      <FORM ACTION="[path_cgi]" METHOD="POST">
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
     <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
     <INPUT TYPE="hidden" NAME="action" VALUE="d_set_owner">
     <INPUT MAXLENGTH=50 NAME="content" VALUE="[owner]" SIZE=30>
     <INPUT TYPE="submit" NAME="action_d_set_owner" VALUE="Set owner">
     </FORM>

     </TD>
  [ENDIF]

</TR>

</TABLE>

