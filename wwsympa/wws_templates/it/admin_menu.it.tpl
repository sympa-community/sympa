<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.it.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>Pannello di amministrazione della lista</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_privileged_owner]
        <A HREF="[path_cgi]/restore_list/[list]">
          <FONT size="-1"><b>Ripristina la mailing list</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="[bg_color]"><b>Ripristina la mailing list</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Sei sicuro di voler chiudere la lista [list]?'); return false;"><FONT size=-1><b>Elimina la mailing list</b></font></A>
       [ENDIF]
    </TD>
        
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[path_cgi]/d_admin/[list]/create">
             <FONT size=-1><b>Crea uno spazio web condiviso</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore">
             <FONT size=-1><b>Ripristina uno spazio web condiviso</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete">
             <FONT size=-1><b>Elimina uno spazio web condiviso</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <FONT size="-1" COLOR="[bg_color]"><b>Modifica la configurazione della lista</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]">
          <FONT size="-1"><b>Modifica la configurazione della lista</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Utenti iscritti</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=[light_color] ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/review/[list]">
       <FONT size="-1"><b>Utenti iscritti</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Messaggi con indirizzo errato</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/reviewbouncing/[list]">
       <FONT size="-1"><b>Messaggi con indirizzo errato</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Modera</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/modindex/[list]">
       <FONT size="-1"><b>Modera</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Modifica le preferenze</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/editfile/[list]">
       <FONT size="-1"><b>Modifica le preferenze</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.it.tpl -->
