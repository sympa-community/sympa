	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  New list name : <INPUT NAME="new_listname" VALUE=""> 
	[IF robots]
           <SELECT NAME="new_robot">
           [FOREACH vr IN robots]
             <OPTION VALUE="[vr->NAME]" [vr]>[vr->NAME]
           [END]
	   </SELECT>
	[ELSE]
	   <INPUT NAME="new_robot" TYPE="hidden" VALUE="[robot]">
	   [robot]
        [ENDIF]
	  <INPUT TYPE="submit" NAME="action_rename_list" VALUE="Rename this list" onClick="return request_confirm('Do you really want to rename this list')">
	</FORM>


	
	

