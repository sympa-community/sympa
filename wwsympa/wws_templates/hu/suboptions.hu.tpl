<!-- RCS Identication ; $Revision$ ; $Date$ -->

  <FORM ACTION="[path_cgi]" METHOD=POST>

   <FONT COLOR="#330099">[subscriber->date]</FONT> óta vagy feliratkozva. <BR><BR>
     <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
     Fogadási mód: 
     <SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>
     <BR>Nyilvánosság :
     <SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
     </SELECT>

     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="Frissít">
     
</FORM>
