<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin admin_menu.us.tpl -->
    
<TD BGCOLOR="[selected_color]" ALIGN="CENTER" COLSPAN="7"> <FONT COLOR="[bg_color]"><b>Panou 
  de comanda de lista</b></font> </TD>
    </TR>
    <TR>
    
  <TD BGCOLOR="[light_color]" ALIGN="CENTER"> 
    [IF list_conf->status=closed] 
	[IF is_privileged_owner]
	 <A HREF="[path_cgi]/restore_list/[list]" > <FONT size="-1"><b>Refacerea 
    listei </b></font></A> 
	[ELSE] 
	  <FONT size="-1" COLOR="[bg_color]"><b>Refacerea 
    listei</b></font> 
	[ENDIF] 
    [ELSE] 
	<A HREF="[path_cgi]/close_list/[list]" onClick="request_confirm_link('[path_cgi]/close_list/[list]', 'Are you sure you wish to close [list] list ?'); return false;"><FONT size=-1><b>Stergerea 
    listei</b></font></A> 
    [ENDIF]
    </TD>
    
  <TD BGCOLOR="[light_color]" ALIGN="CENTER"> 
    [IF shared=none] 
	<A HREF="[path_cgi]/d_admin/[list]/create" > 
    <FONT size=-1><b>Creaza lista comuna</b></font></A> 
    [ELSIF shared=deleted] 
    <A HREF="[path_cgi]/d_admin/[list]/restore" > <FONT size=-1><b>Refacere lista 
    comuna </b></font></A> 
    [ELSIF shared=exist] \
	<A HREF="[path_cgi]/d_admin/[list]/delete" > 
    <FONT size=-1><b>Sterge lista comuna</b></font></A> 
    [ELSE] 
	<FONT size=1 color=red> 
    [comun]</font> 
    [ENDIF] 
	</TD>

    [IF action=edit_list_request]
    
  <TD BGCOLOR="[selected_color]" ALIGN="CENTER"> <FONT size="-1" COLOR="[bg_color]"><b>Configuratie 
    lista </b></FONT> </TD>
    [ELSE]
    
  <TD BGCOLOR="[light_color]" ALIGN="CENTER"> <A HREF="[path_cgi]/edit_list_request/[list]" > 
    <FONT size="-1"><b>Configuratie lista</b></FONT></A> </TD>
    [ENDIF]

    [IF action=review]
    
  <TD BGCOLOR="[selected_color]" ALIGN="CENTER"> <FONT size="-1" COLOR="[bg_color]"><b>Abonati</b></FONT> 
  </TD>
    [ELSE]
    
  <TD BGCOLOR=[light_color] ALIGN=CENTER> 
    [IF is_owner] 
	<A HREF="[path_cgi]/review/[list]" > 
    <FONT size="-1"><b>Abonati</b></FONT></A> 
    [ENDIF] 
</TD>
    [ENDIF]

    [IF action=reviewbouncing]
    
  <TD BGCOLOR="[selected_color]" ALIGN="CENTER"> <FONT size="-1" COLOR="[bg_color]"><b>Adrese 
    eronate </b></FONT> </TD>
    [ELSE]
    
  <TD BGCOLOR="[light_color]" ALIGN="CENTER"> 
    [IF is_owner] 
	<A HREF="[path_cgi]/reviewbouncing/[list]" > 
    <FONT size="-1"><b>Adrese eronate</b></FONT></A> 
     [ENDIF] 
	</TD>
    [ENDIF]

    [IF action=modindex]
    
  <TD BGCOLOR="[selected_color]" ALIGN="CENTER"> <FONT size="-1" COLOR="[bg_color]"><b>Moderare</b></FONT> 
  </TD>
    [ELSE]
       [IF is_editor]
       
  <TD BGCOLOR="[light_color]" ALIGN=CENTER> <A HREF="[path_cgi]/modindex/[list]" > 
    <FONT size="-1"><b>Moderare</b></FONT></A> </TD>
       [ELSE]
         
  <TD BGCOLOR="[light_color]" ALIGN="CENTER"> <FONT size="-1" COLOR="[bg_color]"><b>Moderare</b></FONT> 
  </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    
  <TD BGCOLOR="[selected_color]" ALIGN="CENTER"> <FONT size="-1" COLOR="[bg_color]"><b>Alte 
    configurari </b></FONT> </TD>
    [ELSE]
    
  <TD BGCOLOR="[light_color]" ALIGN="CENTER"> 
    [IF is_owner] <A HREF="[path_cgi]/editfile/[list]" > 
    <FONT size="-1"><b>Alte configurari</b></FONT></A> 
    [ENDIF]
	 </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->

