<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.us.tpl -->
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="[bg_color]"><b>Lijst Administratie Paneel</b></font>
    </TD>
    </TR>
    <TR>
        [IF action=review]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Abonnees</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=[light_color] ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[path_cgi]/review/[list]" >
       <FONT size="-1"><b>Abonnees</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=edit_list_request]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
      <A HREF="[path_cgi]/edit_list_request/[list]" >
      <FONT size="-1" COLOR="[bg_color]"><b>Wijzig Lijst Configuratie</b></FONT></A>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
        <A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>Wijzig Lijst Configuratie</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Modereer</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="[light_color]" ALIGN=CENTER>
         <A HREF="[path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>Modereer</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="[light_color]" ALIGN="CENTER">
           <FONT size="-1" COLOR="[bg_color]"><b>Modereer</b></FONT>
         </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Aanpassen</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>Aanpassen</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <FONT size="-1" COLOR="[bg_color]"><b>Bounces</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>Bounces</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    <TD BGCOLOR="[light_color]" ALIGN="CENTER">
	[IF shared=none]
          [IF is_privileged_owner]
          <A HREF="[path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>Aanmaken gedeeld</b></font></A>
          [ELSE]
             <FONT size=-1 COLOR="[bg_color]"><b>Create Shared</b></font>
          [ENDIF]
	[ELSIF shared=deleted]
          <A HREF="[path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>Terugzetten gedeeld</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>Terugzetten gedeeld</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

   <TD BGCOLOR="[light_color]" ALIGN="CENTER">
       [IF list_conf->status=closed]         
        [IF is_privileged_owner]                   
        <A HREF="[path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>Terugzetten lijst</b></font></A>
        [ELSE]                               
          <FONT size="-1" COLOR="[bg_color]"><b>Terugzetten lijst</b></font>
        [ENDIF]                              
       [ELSIF is_privileged_owner]                 
        <A HREF="[path_cgi]/close_list/[list]"
onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Weet u zeker dat u lijst [list] wilt sluiten ?'); return false;"><FONT size=-1><b>Verwijder lijst</b></font></A>
       [ELSIF is_owner]                      
       <A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Weet u zeker dat u lijst [list] wilt sluiten ?'); return false;"><FONT size=-1><b>Verwijder lijst</b></font></A>
       [ENDIF]                               
    </TD>       
    [IF action=edit_list_request]
    </TR>
    <TR>
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/description" >
       <FONT COLOR="[bg_color]" size=-1><B>Lijst definitie</B></FONT></A>
    </TD>
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/sending" >
       <FONT COLOR="[bg_color]" size=-1><B>Sturen/ontvangen</B></FONT></A>
    </TD> 
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/command" >
       <FONT COLOR="[bg_color]" size=-1><B>Toegangsrechten</B></FONT></A>
    </TD>
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/archives" >
       <FONT COLOR="[bg_color]" size=-1><B>Archieven</B></FONT></A>
    </TD> 
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/bounces" >
       <FONT COLOR="[bg_color]" size=-1><B>Bounce Instellingen</B></FONT></A>
    </TD>
    
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/other" >
       <FONT COLOR="[bg_color]" size=-1><B>Overig</B></FONT></A>
    </TD>
    [IF is_listmaster]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
       <A HREF="[path_cgi]/edit_list_request/[list]/data_source" >
       <FONT COLOR="[bg_color]" size=-1><B>Data Bron</B></FONT></A>
    </TD>                             
    [ELSE]
    <TD BGCOLOR="[selected_color]" ALIGN="CENTER">
    &nbsp;
    </TD>
    [ENDIF]
    [ENDIF] 
<!-- end menu_admin.tpl -->

