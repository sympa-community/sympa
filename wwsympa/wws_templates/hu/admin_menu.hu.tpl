<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.hu.tpl -->
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="--BG_COLOR--"><b>Lista adminisztrációs oldal</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[base_url][path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Lista helyreállítása</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="--BG_COLOR--"><b>Lista helyreállítása<b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[base_url][path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Biztosan meg akarja szüntetni a(z) [list] listát?'); return false;"><FONT size=-1><b>Lista törlése</b></font></A>
       [ENDIF]
    </TD>
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Megosztott mappa létrehozása<b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Megosztott mappa helyreállítása</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Megosztott mappa törlése</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
      <FONT size="-1" COLOR="--BG_COLOR--"><b>Lista beállítások szerkesztése</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Lista beállítások szerkesztése</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Listatagok</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=--LIGHT_COLOR-- ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/review/[list]" >
       <FONT size="-1"><b>Listatagok</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Továbbküldések</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Továbbküldések</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Moderálás</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="--LIGHT_COLOR--" ALIGN=CENTER>
         <A HREF="[base_url][path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>Moderálás</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
	   <FONT size="-1" COLOR="--BG_COLOR--"><b>Moderálás</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="--SELECTED_COLOR--" ALIGN="CENTER">
       <FONT size="-1" COLOR="--BG_COLOR--"><b>Egyéni beállítás</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="--LIGHT_COLOR--" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Egyéni beállítás</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.hu.tpl -->

