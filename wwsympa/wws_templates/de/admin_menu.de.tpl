<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.de.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>Listen-Administrations-Men&uuml;</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Liste wiederherstellen</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="[bg_color]"><b>Liste wiederherstellen</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Wirklich Liste [list] schlie&szlig;en?'); return false;"><FONT size=-1><b>Liste schlie&szlig;en</b></font></A>
       [ENDIF]
    </TD>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>SHARED anlegen</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>SHARED wiederherstellen</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>SHARED l&ouml;schen</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <FONT size="-1" COLOR="[bg_color]"><b>Listenkonfig.</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Listenkonfig.</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Abonnenten</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=[light_color] ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/review/[list]" >
       <FONT size="-1"><b>Abonnenten</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Unzustellbar</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Unzustellbar</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Moderieren</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="[light_color]" ALIGN=CENTER>
         <A HREF="[path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>Moderieren</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	   <FONT size="-1" COLOR="[bg_color]"><b>Moderieren</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Anpassen</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Anpassen</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->

