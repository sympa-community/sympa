<FORM ACTION="[path_cgi]" METHOD="POST">
 

 <BR> 
 <TABLE>
  [FOREACH f IN list_file]
   <TR><TD>[f]</TD></TR>
  [END]
   <TR><TD>&nbsp; </TD></TR>
   <TR><TD>existe(nt) déjà , voulez vous confirmer la validation et écraser le(s) ancien(s) fichiers ou annuler la validation ? 
   </TD></TR>
 <TR>
  <TD><INPUT TYPE="submit" NAME="mode_confirm" VALUE="Confirmer" ></TD>
  <TD><INPUT TYPE="submit" NAME="mode_cancel" VALUE="Annuler" ></TD>
 </TR>
 </TABLE>
 <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
[FOREACH elt IN id]
 <INPUT TYPE="hidden" NAME="id" VALUE="[elt]">
[END]
 <INPUT TYPE="hidden" NAME="action_d_install_shared" VALUE="1"> 
</FORM>  
