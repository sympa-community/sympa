<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>
  Esti inscris din<FONT COLOR="[dark_color]">[subscriber->date]</FONT> <BR>
  <BR>
  Ultima actualizare: <FONT COLOR="[dark_color]">[subscriber->update_date]</FONT> 
  <BR>
  <BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  Mod de primire: 
  <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     [PARSE '/home/sympa/bin/etc/wws_templates/button_header.tpl']
     
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> <A HREF="[path_cgi]/nomenu/help/user_options" onClick="window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=400,height=200')" TARGET="wws_help"> 
    <FONT SIZE=-1><B>Ajutor</B></FONT></A> </TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_footer.tpl']

     <BR>
  Vizibilitate : 
  <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     
  <INPUT TYPE="submit" NAME="action_set" VALUE="Actualizeaza">
     
</FORM>
