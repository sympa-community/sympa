<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.es.tpl -->
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="--BG_COLOR--"><b>Lista panel de administración</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[base_url][path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Restaura lista</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="--BG_COLOR--"><b>Restaura lista</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[base_url][path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Está Vd. seguro que quiere cerrar la lista [list] ?'); return false;"><FONT size=-1><b>Elimina lista</b></font></A>
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
      <FONT size="-1" COLOR="--BG_COLOR--"><b>Edita config lista</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Edita config lista</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Subscriptores</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=--LIGHT_COLOR-- ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/review/[list]" >
       <FONT size="-1"><b>Subscriptores</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Rebotados</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Rebotados</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Moderar</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/modindex/[list]" >
       <FONT size="-1"><b>Moderar</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Personalizar</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Personalizar</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->
