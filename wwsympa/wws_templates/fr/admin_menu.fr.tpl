<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.fr.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>Administration de liste</b></font>
    </TD>
    </TR>
    <TR>
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

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <A HREF="[path_cgi]/edit_list_request/[list]" >
      <FONT size="-1" COLOR="[bg_color]"><b>Configurer la liste</b></FONT></A>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
        <A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Configurer la liste</b></FONT></A>
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

    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          [IF is_privileged_owner]
          <A HREF="[path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Créer un espace partagé</b></font></A>
          [ELSE]
             <FONT size=-1 COLOR="[bg_color]"><b>Créer un espace partagé</b></font>
          [ENDIF]
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Restaurer l'espace partagé</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Fermer l'espace partagé</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

   <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]         
        [IF is_privileged_owner]                   
        <A HREF="[path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Restaurer la liste</b></font></A>
        [ELSE]                               
          <FONT size="-1" COLOR="[bg_color]"><b>Restaurer la liste</b></font>
        [ENDIF]                              
       [ELSIF is_privileged_owner]                 
        <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Vous êtes sur le point de supprimer la liste [list]. Confirmer ?'); return false;"><FONT size=-1><b>Supprimer la liste</b></font></A>
       [ELSIF is_owner]                      
       <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Vous êtes sur le point de suppimer la liste [list]. Confirmer ?'); return false;"><FONT size=-1><b>Supprimer la liste</b></font></A>
       [ENDIF]                               
    </TD>       
    [IF action=edit_list_request]
    </TR>
    <TR>
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/description" >
       <FONT COLOR="[bg_color]" size=-1><B>Définition de la liste</B></FONT></A>
    </TD>
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/sending" >
       <FONT COLOR="[bg_color]" size=-1><B>Diffusion/Réception</B></FONT></A>
    </TD> 
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/command" >
       <FONT COLOR="[bg_color]" size=-1><B>Privilèges</B></FONT></A>
    </TD>
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/archives" >
       <FONT COLOR="[bg_color]" size=-1><B>Archives</B></FONT></A>
    </TD> 
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/bounces" >
       <FONT COLOR="[bg_color]" size=-1><B>Gestion des erreurs</B></FONT></A>
    </TD>
    
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/other" >
       <FONT COLOR="[bg_color]" size=-1><B>Divers</B></FONT></A>
    </TD>
    [IF is_listmaster]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/data_source" >
       <FONT COLOR="[bg_color]" size=-1><B>Sources de données</B></FONT></A>
    </TD>                             
    [ELSE]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
    &nbsp;
    </TD>
    [ENDIF]
    [ENDIF] 
<!-- end menu_admin.tpl -->
