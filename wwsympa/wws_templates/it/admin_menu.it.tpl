<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.it.tpl -->
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="--BG_COLOR--"><b>Pannello di amministrazione della lista</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[base_url][path_cgi]/restore_list/[list]" STYLE="TEXT-DECORATION: NONE">
          <FONT size="-1"><b>Ripristina la mailing list</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="--BG_COLOR--"><b>Ripristina la mailing list</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[base_url][path_cgi]/close_list_request/[list]" STYLE="TEXT-DECORATION: NONE"><FONT size=-1><b>Elimina la mailing list</b></font></A>
       [ENDIF]
    </TD>
        
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/create" STYLE="TEXT-DECORATION: NONE">
             <FONT size=-1><b>Crea uno spazio web condiviso</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/restore" STYLE="TEXT-DECORATION: NONE">
             <FONT size=-1><b>Ripristina uno spazio web condiviso</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/delete" STYLE="TEXT-DECORATION: NONE">
             <FONT size=-1><b>Elimina uno spazio web condiviso</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
      <FONT size="-1" COLOR="--BG_COLOR--"><b>Modifica la configurazione della lista</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" STYLE="TEXT-DECORATION: NONE">
          <FONT size="-1"><b>Modifica la configurazione della lista</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Utenti iscritti</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=--LIGHT_COLOR-- ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/review/[list]" STYLE="TEXT-DECORATION: NONE">
       <FONT size="-1"><b>Utenti iscritti</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Messaggi con indirizzo errato</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/reviewbouncing/[list]" STYLE="TEXT-DECORATION: NONE">
       <FONT size="-1"><b>Messaggi con indirizzo errato</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Modera</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/modindex/[list]" STYLE="TEXT-DECORATION: NONE">
       <FONT size="-1"><b>Modera</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Modifica le preferenze</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/editfile/[list]" STYLE="TEXT-DECORATION: NONE">
       <FONT size="-1"><b>Modifica le preferenze</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.it.tpl -->
