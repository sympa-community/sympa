the file [shortname] already exists 
<P>

 <FORM  ACTION="[path_cgi]" METHOD="POST">

   <TABLE CELLSPACING=15>
    <TR> 
     <TD ALIGN ="right" VALIGN="bottom">
      Do you want to delete the old file [shortname]?
     </TD>
     <TD ALIGN ="left" VALIGN="bottom">
      <INPUT TYPE="submit" NAME="mode_delete" VALUE="Delete">
     </TD>
    </TR>
    <BR>
    <TR>
     <TD ALIGN="right" VALIGN="bottom">
      Do you want to rename your file [shortname] ? <BR>
      <INPUT size=50 maxlenght=100 NAME="new_name"></TD>
     </TD>
     <TD ALIGN="left" VALIGN="bottom">
      <INPUT size=20 maxlenght=50 TYPE="submit" NAME="mode_rename" VALUE="Rename">
     </TD>
    </TR>
    <BR>
    <TR> 
     <TD ALIGN ="right" VALIGN="bottom">
      Do you want to cancel the upload ? 
     </TD>
     <TD ALIGN ="left" VALIGN="bottom">
      <INPUT TYPE="submit" NAME="mode_cancel" VALUE="Cancel">
     </TD>
    </TR>
   </TABLE>

   <INPUT TYPE="hidden" NAME="action_d_upload" VALUE="1">
   <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="shortname" VALUE="[shortname]">

 </FORM>



