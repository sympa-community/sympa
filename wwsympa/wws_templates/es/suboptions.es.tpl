
  <FORM ACTION="[path_cgi]" METHOD=POST>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">

  <table>
    <tr>
      <td>Está suscrito desde el</td><td><FONT COLOR="--DARK_COLOR--">[subscriber->date]</FONT></td>
    </tr>
    <tr>      
      <td>Sistema de recepción :</td> 
      <td><SELECT NAME="reception">
        [FOREACH r IN reception]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
          </SELECT></td>
    </tr>
    <tr>
     <td>Visibilidad :</td>
     <td><SELECT NAME="visibility">
        [FOREACH r IN visibility]
          <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
        [END]
         </SELECT></td>
     </tr>
     </table>
     
     <BR>
     <INPUT TYPE="submit" NAME="action_set" VALUE="Actualizar">
     
</FORM>
