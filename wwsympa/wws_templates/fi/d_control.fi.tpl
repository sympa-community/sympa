<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H1>Dokumentin saantioikeudet [path]</H1>
    Omistaja : [owner] <BR>
    Viim. p‰ivitys : [doc_date] <BR>
    Kuvaus : [doc_title] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]"> Ylemp‰‰n hakemistoon</A></H3>

<TABLE width=100%>

  <TR VALIGN="top">
  <TD>

  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B>Lukuoikeus</B><BR>
  <SELECT NAME="read_access">
  [FOREACH s IN scenari_read]
    <OPTION VALUE='[s->scenario_name]' [s->selected]>[s->scenario_label]
  [END]
  </SELECT>
  <BR>

  <B>Muutos oikeus</B><BR>
  <SELECT NAME="edit_access">
  [FOREACH s IN scenari_edit]
    <OPTION VALUE='[s->scenario_name]' [s->selected]>[s->scenario_label]
  [END]
  </SELECT>
  <BR>
   
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
   <INPUT TYPE="submit" NAME="action_d_change_access" VALUE="muuta oikeuksia">
   </FORM>

   </TD>

   [IF set_owner]
     <TD>
     <B>Aseta hakemiston omistaja [path]</B>

     <FORM ACTION="[path_cgi]" METHOD="POST">
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
     <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
     <INPUT TYPE="hidden" NAME="action" VALUE="d_set_owner">
     <INPUT MAXLENGTH=50 NAME="content" VALUE="[owner]" SIZE=30>
     <INPUT TYPE="submit" NAME="action_d_set_owner" VALUE="Aseta omistaja">
     </FORM>

     </TD>
  [ENDIF]

</TR>

</TABLE>

