<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.es.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>Panel de administración</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Restaurar Lista</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="[bg_color]"><b>Restaurar Lista</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', '¿Está Vd. seguro de que quiere cerrar la lista [list] ?'); return false;"><FONT size=-1><b>Eliminar Lista</b></font></A>
       [ENDIF]
    </TD>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Crear Compartición</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Restaurar Compartición</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Borrar Compartición</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <FONT size="-1" COLOR="[bg_color]"><b>Configurar Lista</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Configurar Lista</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Suscriptores</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=[light_color] ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/review/[list]" >
       <FONT size="-1"><b>Suscriptores</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Rebotados</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Rebotados</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Moderar</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/modindex/[list]" >
       <FONT size="-1"><b>Moderar</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Personalizar</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Personalizar</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->
