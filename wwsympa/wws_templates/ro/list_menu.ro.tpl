<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin list_menu.tpl -->
<TABLE border="0"  CELLPADDING="0" CELLSPACING="0">
 <TR VALIGN="top"><!-- empty line in the left menu panel -->
  <TD WIDTH="5" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="40" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="30" ></TD>
  <TD WIDTH="40" ></TD>
 </TR>
 <TR>
  <TD WIDTH="5" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

<!-- begin -->
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']

      [IF action=info]
        
    <TD WIDTH=100% BGCOLOR="[selected_color]" NOWRAP align=right> <font color="[bg_color]" size=-1><b>Informatii 
      lista</b></font> </TD>
      [ELSE]
        
    <TD WIDTH=100% BGCOLOR="[light_color]" NOWRAP align=right> <A HREF="[path_cgi]/info/[list]" ><font size=-1><b>Informatii 
      lista</b></font></A> </TD>
      [ENDIF]

     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>


  <TD WIDTH=40></TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel list info -->
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=110 COLSPAN=3 BGCOLOR="[bg_color]" NOWRAP align=left>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
        <TD BGCOLOR="[light_color]">
	  Subscribers: <B>[total]</B><BR>
	  <BR>
      Proprietari
     [FOREACH o IN owner] 
       [IF o->gecos] 
        <BR>
      <FONT SIZE=-1>[o->gecos]</FONT>
            [ELSE]
	    <BR><FONT SIZE=-1>[o->masked_email]</FONT>
	    [ENDIF]
	  [END]
	  <BR>
      [IF is_moderated] 
	Moderatori 
	[FOREACH e IN editor] 
	  [IF e->gecos] 
	   <BR>
      <FONT SIZE=-1>[e->gecos]</FONT>
            [ELSE]
	    <BR><FONT SIZE=-1>[e->masked_email]</FONT>
	    [ENDIF]
	    [END]
	  [ENDIF]
          <BR>
	  [IF list_as_x509_cert]
          <BR>
      <A HREF="[path_cgi]/load_cert/[list]"><font size="-1"><b>Incarca certificatul</b></font></A><BR>
          [ENDIF]
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF is_priv]
 <TR><!-- for listmaster owner and editor -->
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']

   [IF action=admin]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Administrare 
      lista</b></font></TD>
   [ELSIF action_type=admin]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right> <b> <A HREF="[path_cgi]/admin/[list]" ><FONT COLOR="[bg_color]" SIZE="-1">Administrare 
      lista</FONT></A></b> </TD>
   [ELSE]
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> <font size=-1><b> 
      <A HREF="[path_cgi]/admin/[list]" >Adminstrare lista</A></b></font> </TD>
   [ENDIF]

     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel admin info -->
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=110 COLSPAN=3 BGCOLOR="[bg_color]" NOWRAP align=left>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
        
    <TD BGCOLOR="[light_color]"> Rata de emailuri in asteptare: <B>[bounce_rate]%</B><BR>
           <BR>
      [IF mod_total=0] 
	Nu exista mesaje pentru moderare 
      [ELSE] 
	Mesaje pentru moderare:<B> 
      [mod_total]</B> 
      [ENDIF] 
	<BR>
        </TD>
         [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>


     <!-- end is_priv -->
   [ENDIF]
   <!-- Subscription depending on susbscriber or not, email define or not etc -->
   [IF is_subscriber=1]
    [IF may_suboptions=1]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
      [IF action=suboptions]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Optiunile 
      abonatului</b></font></TD>
      [ELSE]
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> <font size=-1><b> 
      <A HREF="[path_cgi]/suboptions/[list]" >Optiunile abonatului</A></b></font> 
    </TD>
      [ENDIF]
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=40>
  </TD>

 </TR>
  [ENDIF]

 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF may_signoff=1] 
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
      [IF action=signoff]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Deazabonare</b></font></TD>
      [ELSIF user->email]
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> <font size=-1><b> 
      <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'Do you really want to unsubscribe from list [list]?'); return false;">Dezabonare</A></b></font> 
    </TD>
       [ELSE]
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> <font size=-1><b> 
      <A HREF="[path_cgi]/sigrequest/[list]">Dezabonare</A> </b></font> </TD>
       [ENDIF]
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']

  </TD>

  <TD WIDTH=40></TD>
 </TR>
   [ELSE]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> <font size=-1 COLOR="[bg_color]"><b>Deazabonare</b></font> 
    </TD>
        <TD WIDTH=40></TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>
 </TR>
      <!-- end may_signoff -->
   [ENDIF]
      <!-- is_subscriber -->

   [ELSE]
      <!-- else is_subscriber -->

 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
   [IF action=subrequest]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Inscriere</b></font></TD>
   [ELSE]
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> [IF may_subscribe=1] 
      [IF user->email] 
	<font size=-1><b> <A HREF="[path_cgi]/subscribe/[list]" onClick="request_confirm_link('[path_cgi]/subscribe/[list]', 'Do you really want to subscribe to list [list]?'); return false;">Inscriere</A> 
      </b></font> 
      [ELSE] 
	<font size=-1><b> <A HREF="[path_cgi]/subrequest/[list]">Inscriere</A> 
      </b></font> 
      [ENDIF] 
      [ELSE] 
	<font size=-1 COLOR="[bg_color]"><b>Inscriere</b></font> 
      [ENDIF] 
	</TD>
   [ENDIF]

     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=40></TD>
 </TR>

   [IF may_signoff]
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']

        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> 
    [IF user->email] 
      <font size=-1><b> <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'Do you really want to unsubscribe from list [list]?'); return false;">Dezabonare</A> 
      </b></font> 
    [ELSE] 
	<font size=-1><b> <A HREF="[path_cgi]/sigrequest/[list]">Dezabonare</A> 
      </b></font> 
     [ENDIF] 
	</TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=40></TD>
 </TR>
   [ENDIF]

      <!-- END is_subscriber -->
   [ENDIF]
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF is_archived]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
   [IF action=arc]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Archive</b></font>
	</TD>
   [ELSIF action=arcsearch_form]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right> <font size=-1 COLOR="[bg_color]"><b>Arhive</b></font> 
    </TD>
   [ELSIF action=arcsearch]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right> <font size=-1 COLOR="[bg_color]"><b>Arhive</b></font> 
    </TD>
   [ELSIF action=arc_protect]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right> <font size=-1 COLOR="[bg_color]"><b>Arhive</b></font> 
    </TD>
  [ELSE]

        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> 
     [IF arc_access] 
      <font size=-1><b> <A HREF="[path_cgi]/arc/[list]" >Arhive</A> </b></font> 
      [ELSE]
	 <font size=-1 COLOR="[bg_color]"><b>Arhive</b></font> 
      [ENDIF] 
	</TD>
   [ENDIF]

     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
      <!-- END is_archived -->
    [ENDIF]

 <!-- Post -->
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
   [IF action=compose_mail]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right> <font size=-1 COLOR="[bg_color]"><b>Publica</b></font> 
    </TD>
  [ELSE]

        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> 
	[IF may_post] 
      <font size=-1><b> <A HREF="[path_cgi]/compose_mail/[list]" >Publica</A> 
      </b></font> 
	[ELSE] 
	<font size=-1 COLOR="[bg_color]"><b>Publica</b></font> 
      [ENDIF]
 </TD>
   [ENDIF]

     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
      <!-- END post -->

    [IF shared=exist]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp; </TD>   
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
    [IF action=d_read]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1>
         <b>Shared web</b></font>
        </TD>
    [ELSE]
      [IF may_d_read]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/d_read/[list]/" >Shared web</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1 COLOR="[bg_color]"><b>Shared web</b></font>
        </TD>
      [ENDIF]
    [ENDIF]

      [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>

       <!-- END shared --> 
  <TD WIDTH=40></TD>
 </TR> 
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]

    [IF may_review]
 <TR>
  <TD WIDTH=5 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_header.tpl']
      [IF action=review]
        
    <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right> <font size=-1 COLOR="[bg_color]"><b>Revizuire</b></font> 
    </TD>
      [ELSE]
        
    <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right> <font size=-1><b> 
      <A HREF="[path_cgi]/review/[list]" >Revizuire</A> </b></font> </TD>
      [ENDIF]
     [PARSE '/home/sympa/bin/etc/wws_templates/list_button_footer.tpl']
  </TD>
  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]
</TABLE>
<!-- end list_menu.tpl -->
