<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin list_menu.tpl -->
<TABLE border="0"  CELLPADDING="0" CELLSPACING="0">
 <TR VALIGN="top"><!-- empty line in the left menu panel -->
  <TD WIDTH="--COL1--" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL2--" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL3--" ></TD>
  <TD WIDTH="--COL4--" ></TD>
 </TR>
 <TR>
  <TD WIDTH="--COL1--" BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

<!-- begin -->
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']

      [IF action=info]
        <TD WIDTH=100% BGCOLOR="[selected_color]" NOWRAP align=right>
           <font color="[bg_color]" size=-1><b>Listan tiedot</b></font>
        </TD>
      [ELSE]
        <TD WIDTH=100% BGCOLOR="[light_color]" NOWRAP align=right>
        <A HREF="[path_cgi]/info/[list]" ><font size=-1><b>Listan tiedot</b>
        </font></A>
        </TD>
      [ENDIF]

     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>


  <TD WIDTH=--COL4--></TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel list info -->
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL234-- COLSPAN=3 BGCOLOR="[bg_color]" NOWRAP align=left>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
        <TD BGCOLOR="[light_color]">
	  Tilaajat: <B>[total]</B><BR>
	  <BR>
	  Omistajat
	  [FOREACH o IN owner]
	    [IF o->gecos]
	    <BR><FONT SIZE=-1>[o->gecos]</FONT>
            [ELSE]
	    <BR><FONT SIZE=-1>[o->masked_email]</FONT>
	    [ENDIF]
	  [END]
	  <BR>
	  [IF is_moderated]
	    Hallitsijat
	    [FOREACH e IN editor]
	    [IF e->gecos]
	    <BR><FONT SIZE=-1>[e->gecos]</FONT>
            [ELSE]
	    <BR><FONT SIZE=-1>[e->masked_email]</FONT>
	    [ENDIF]
	    [END]
	  [ENDIF]
          <BR>
	  [IF list_as_x509_cert]
          <BR><A HREF="[path_cgi]/load_cert/[list]"><font size="-1"><b>Lataa sertifikaatti<b></font></A><BR>
          [ENDIF]
     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF is_priv]
 <TR><!-- for listmaster owner and editor -->
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']

   [IF action=admin]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Listan hallinta</b></font></TD>
   [ELSIF action_type=admin]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
        <b>
         <A HREF="[path_cgi]/admin/[list]" ><FONT COLOR="[bg_color]" SIZE="-1">Listan hallinta</FONT></A>
        </b>
        </TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/admin/[list]" >Listan hallinta</A>
        </b></font>
        </TD>
   [ENDIF]

     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel admin info -->
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL234-- COLSPAN=3 BGCOLOR="[bg_color]" NOWRAP align=left>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
        <TD BGCOLOR="[light_color]">
	   Palautuneiden viestien m‰‰r‰: <B>[bounce_rate]%</B><BR>
           <BR>
	   [if mod_total=0]
	   Ei viestej‰ hallittavana
           [else]
           Hallittavat viestit :<B> [mod_total]</B>
           [endif]
	  <BR>
        </TD>
         [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>
 </TR>
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>


     <!-- end is_priv -->
   [ENDIF]
   <!-- Subscription depending on susbscriber or not, email define or not etc -->
   [IF is_subscriber=1]
    [IF may_suboptions=1]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
      [IF action=suboptions]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Tilaajan Asetukset</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/suboptions/[list]" >Tilaajan Asetukset</A>
        </b></font>
        </TD>
      [ENDIF]
     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=--COL4-->
  </TD>

 </TR>
  [ENDIF]

 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF may_signoff=1] 
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
      [IF action=signoff]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Tilauksen poisto</b></font></TD>
      [ELSIF user->email]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'Haluatko varmasti poistua listalta [list]?'); return false;">Poista tilaus</A>
        </b></font>
        </TD>
       [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]">Poista tilaus</A>
        </b></font>
        </TD>
       [ENDIF]
     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']

  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>
   [ELSE]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1 COLOR="[bg_color]"><b>Poista tilaus</b></font>
        </TD>
        <TD WIDTH=--COL4--></TD>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>
 </TR>
      <!-- end may_signoff -->
   [ENDIF]
      <!-- is_subscriber -->

   [ELSE]
      <!-- else is_subscriber -->

 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
   [IF action=subrequest]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Tilaa lista</b></font></TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
    [IF may_subscribe=1]
      [IF user->email]
        <font size=-1><b>
     <A HREF="[path_cgi]/subscribe/[list]" onClick="request_confirm_link('[path_cgi]/subscribe/[list]', 'Haluatko varmasti tilata listan [list]?'); return false;">Tilaa lista</A>
        </b></font>
      [ELSE]
         <font size=-1><b>
     <A HREF="[path_cgi]/subrequest/[list]">Tilaa lista</A>
        </b></font>
      [ENDIF]
    [ELSE]
	<font size=-1 COLOR="[bg_color]"><b>Tilaa lista</b></font>
    [ENDIF]
        </TD>
   [ENDIF]

     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>

   [IF may_signoff]
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
       [IF user->email]
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'Haluatko varmasti poistaa tilauksen listalta [list]?'); return false;">Poista tilaus</A>
        </b></font>
       [ELSE]
       <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]">Poista tilaus</A>
        </b></font>
       [ENDIF]
        </TD>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>
   [ENDIF]

      <!-- END is_subscriber -->
   [ENDIF]
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF is_archived]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
   [IF action=arc]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Arkisto</b></font>
	</TD>
   [ELSIF action=arcsearch_form]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Arkisto</b></font>
	</TD>
   [ELSIF action=arcsearch]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Arkisto</b></font>
	</TD>
   [ELSIF action=arc_protect]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Arkisto</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
   [IF arc_access]
        <font size=-1><b>
         <A HREF="[path_cgi]/arc/[list]" >Arkisto</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="[bg_color]"><b>Arkisto</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
      <!-- END is_archived -->
    [ENDIF]

 <!-- Post -->
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
   [IF action=compose_mail]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>L‰het‰</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
   [IF may_post]
        <font size=-1><b>
         <A HREF="[path_cgi]/compose_mail/[list]" >L‰het‰</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="[bg_color]"><b>L‰het‰</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
      <!-- END post -->

    [IF shared=exist]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp; </TD>   
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
    [IF action=d_read]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1>
         <b>Jaettu WWW</font>
        </TD>
    [ELSE]
      [IF may_d_read]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/d_read/[list]/" >Jaettu WWW</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1 COLOR="[bg_color]"><b>Jaettu WWW</b></font>
        </TD>
      [ENDIF]
    [ENDIF]

      [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>

       <!-- END shared --> 
  <TD WIDTH=--COL4--></TD>
 </TR> 
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]

    [IF may_review]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
     [PARSE '--ETCBINDIR--/wws_templates/list_button_header.tpl']
      [IF action=review]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Tarkista</b></font>
	</TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/review/[list]" >Tarkista</A>
         </b></font>
	</TD>
      [ENDIF]
     [PARSE '--ETCBINDIR--/wws_templates/list_button_footer.tpl']
  </TD>
  <TD WIDTH=--COL4--></TD>
 </TR>
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]
</TABLE>
<!-- end list_menu.tpl -->
