<FORM ACTION="[path_cgi]" METHOD="POST">
 

 <BR> 
 <TABLE>
  [FOREACH f IN list_file]
   <TR><TD>[f]</TD></TR>
  [END]
   <TR><TD>&nbsp; </TD></TR>
   <TR><TD>already exist(s), do you want to confirm the install and erase the old file(s) or cancel the install ? 
   </TD></TR>
 <TR>
  <TD><INPUT TYPE="submit" NAME="mode_confirm" VALUE="Confirm" ></TD>
  <TD><INPUT TYPE="submit" NAME="mode_cancel" VALUE="Cancel" ></TD>
 </TR>
 </TABLE>
 <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
[FOREACH elt IN id]
 <INPUT TYPE="hidden" NAME="id" VALUE="[elt]">
[END]
 <INPUT TYPE="hidden" NAME="action_d_install_shared" VALUE="1"> 
</FORM>  
