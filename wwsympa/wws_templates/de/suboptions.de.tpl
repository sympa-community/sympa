<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>

  Sie erhalten die Liste seit <FONT COLOR="[dark_color]">[subscriber->date]</FONT>  <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     Zustellungsmodus: 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>
     <BR>Sichbarkeit:
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="&Auml;ndern">
     
</FORM>
