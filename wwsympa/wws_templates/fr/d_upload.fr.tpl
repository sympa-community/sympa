le fichier [shortname] existe dÃ©jÃ  
<P>

 <FORM  ACTION="[path_cgi]" METHOD="POST">

   <TABLE CELLSPACING=15>
    <TR> 
     <TD ALIGN ="right" VALIGN="bottom">
      Voulez vous écraser l'ancien fichier [shortname]?
     </TD>
     <TD ALIGN ="left" VALIGN="bottom">
      <INPUT TYPE="submit" NAME="mode_delete" VALUE="Ecraser">
     </TD>
    </TR>
    <BR>
    <TR>
     <TD ALIGN="right" VALIGN="bottom">
      Voulez vous renommer votre fichier [shortname] ? <BR>
      <INPUT size=50 maxlenght=100 NAME="new_name"></TD>
     </TD>
     <TD ALIGN="left" VALIGN="bottom">
      <INPUT size=20 maxlenght=50 TYPE="submit" NAME="mode_rename" VALUE="Renommer">
     </TD>
    </TR>
    <BR>
    <TR> 
     <TD ALIGN ="right" VALIGN="bottom">
      Voulez vous annuler le téléchargement ? 
     </TD>
     <TD ALIGN ="left" VALIGN="bottom">
      <INPUT TYPE="submit" NAME="mode_cancel" VALUE="Annuler">
     </TD>
    </TR>
   </TABLE>

   <INPUT TYPE="hidden" NAME="action_d_upload" VALUE="1">
   <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="shortname" VALUE="[shortname]">

 </FORM>



