<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.fr.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>Administration de liste</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Restaurer la liste</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="[bg_color]"><b>Restaurer la liste</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Êtes-vous sûr de vouloir fermer la liste [list] ?'); return false;"><FONT size=-1><b>Supprimer la liste</b></font></A>
       [ENDIF]
    </TD>

    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Créer un espace partagé</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Restaurer l'espace partagé</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Supprimer l'espace partagé</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <FONT size="-1" COLOR="[bg_color]"><b>Configurer la liste</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Configurer la liste</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Abonnés</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=[light_color] ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/review/[list]" >
       <FONT size="-1"><b>Abonnés</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Erreurs</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Erreurs</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Modérer</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="[light_color]" ALIGN=CENTER>
         <A HREF="[path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>Modérer</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	   <FONT size="-1" COLOR="[bg_color]"><b>Modérer</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Personnaliser</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Personnaliser</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end admin_menu.fr.tpl -->






