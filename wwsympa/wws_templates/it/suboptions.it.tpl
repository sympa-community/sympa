  <FORM ACTION="[path_cgi]" METHOD=POST>

  Sei iscritto dal <FONT COLOR="--DARK_COLOR--">[subscriber->date]</FONT>  <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     Modalit&agrave; di ricezione  : 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>
     <BR>Visibilit&agrave; :
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="Aggiorna">
     
</FORM>
