<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.us.tpl -->
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="--BG_COLOR--"><b>List adminstration panel</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[base_url][path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Restore list</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="--BG_COLOR--"><b>Restore list</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[base_url][path_cgi]/close_list_request/[list]" ><FONT size=-1><b>Remove list</b></font></A>
       [ENDIF]
    </TD>
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Create shared</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Restore shared</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Delete Shared</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
      <FONT size="-1" COLOR="--BG_COLOR--"><b>Edit list config</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Edit list config</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Subscribers</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=--LIGHT_COLOR-- ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/review/[list]" >
       <FONT size="-1"><b>Subscribers</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Bounces</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Bounces</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Moderate</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="--LIGHT_COLOR--" ALIGN=CENTER>
         <A HREF="[base_url][path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>Moderate</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	   <FONT size="-1" COLOR="--BG_COLOR--"><b>Moderate</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Customizing</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Customizing</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->

