<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>

  You are subscribed since <FONT COLOR="[dark_color]">[subscriber->date]</FONT>  <BR><BR>
  Last update: <FONT COLOR="[dark_color]">[subscriber->update_date]</FONT>  <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     Reception mode : 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>
     <BR>Visibility :
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="Update">
     
</FORM>
