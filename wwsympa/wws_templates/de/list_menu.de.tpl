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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

      [IF action=info]
        <TD WIDTH=100% BGCOLOR="[selected_color]" NOWRAP align=right>
           <font color="[bg_color]" size=-1><b>Listeninfo.</b></font>
        </TD>
      [ELSE]
        <TD WIDTH=100% BGCOLOR="[light_color]" NOWRAP align=right>
        <A HREF="[path_cgi]/info/[list]" ><font size=-1><b>Listeninfo.</b>
        </font></A>
        </TD>
      [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="[light_color]">
	  Abonnenten: <B>[total]</B><BR>
	  <BR>
	  Besitzer
	  [FOREACH o IN owner]
	    <BR><FONT SIZE=-1><A HREF="mailto:[o->NAME]">[o->gecos]</A></FONT>
	  [END]
	  <BR>
	  [IF is_moderated]
	    Moderatoren
	    [FOREACH e IN editor]
	      <BR><FONT SIZE=-1><A HREF="mailto:[e->NAME]">[e->gecos]</A></FONT>
	    [END]
	  [ENDIF]
          <BR>
	  [IF list_as_x509_cert]
          <BR><A HREF="[path_cgi]/load_cert/[list]"><font size="-1"><b>Lade Zertifikat<b></font></A><BR>
          [ENDIF]
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

   [IF action=admin]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Listenadmin.</b></font></TD>
   [ELSIF action_type=admin]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
        <b>
         <A HREF="[path_cgi]/admin/[list]" ><FONT COLOR="[bg_color]" SIZE="-1">Listenadmin.</FONT></A>
        </b>
        </TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/admin/[list]" >Listenadmin.</A>
        </b></font>
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="[light_color]">
	   Unzustellbar: <B>[bounce_rate]%</B><BR>
           <BR>
	   [if mod_total=0]
	   Nichts zu moderieren
           [else]
           Unmoderierte Nachrichten:<B> [mod_total]</B>
           [endif]
	  <BR>
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>

  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=suboptions]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Abonnentenoptionen</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/suboptions/[list]" >Abonnentenoptionen</A>
        </b></font>
        </TD>
      [ENDIF]
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=--COL4-->
  </TD>
 </TR>
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF may_signoff=1] 
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=signoff]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Abbestellen</b></font></TD>
      [ELSE]
       [IF user->email]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'M&ouml;chten Sie wirklich die Liste [list] abbestellen?'); return false;">Abbestellen</A>
        </b></font>
        </TD>
       [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]">Abbestellen</A>
        </b></font>
        </TD>
       [ENDIF]
      [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=--COL4--></TD>
 </TR>
   [ELSE]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="[dark_color]" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
        <font size=-1 COLOR="[bg_color]"><b>Abbestellen</b></font>
        </TD>
        <TD WIDTH=--COL4--></TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=subrequest]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1><b>Abonnieren</b></font></TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
    [IF may_subscribe=1]
      [IF user->email]
        <font size=-1><b>
     <A HREF="[path_cgi]/subscribe/[list]" onClick="request_confirm_link('[path_cgi]/subscribe/[list]', 'Wollen Sie wirklich die Liste [list] abonnieren?'); return false;">Abonnieren</A>
        </b></font>
      [ELSE]
         <font size=-1><b>
     <A HREF="[path_cgi]/subrequest/[list]">Abonnieren</A>
        </b></font>
      [ENDIF]
    [ELSE]
	<font size=-1 COLOR="[bg_color]"><b>Abonnieren</b></font>
    [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
       [IF user->email]
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'M&ouml;chten Sie wirklich die Liste [list] abbestellen?'); return false;">Abbestellen</A>
        </b></font>
       [ELSE]
       <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]">Abbestellen</A>
        </b></font>
       [ENDIF]
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=arc]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Archiv</b></font>
	</TD>
   [ELSIF action=arcsearch_form]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Archiv</b></font>
	</TD>
   [ELSIF action=arcsearch]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Archiv</b></font>
	</TD>
   [ELSIF action=arc_protect]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Archiv</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
   [IF arc_access]
        <font size=-1><b>
         <A HREF="[path_cgi]/arc/[list]" >Archiv</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="[bg_color]"><b>Archiv</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=compose_mail]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right>
          <font size=-1 COLOR="[bg_color]"><b>Senden</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
   [IF may_post]
        <font size=-1><b>
         <A HREF="[path_cgi]/compose_mail/[list]" >Senden</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="[bg_color]"><b>Senden</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
    [IF action=d_read]
        <TD WIDTH="100%" BGCOLOR="[selected_color]" NOWRAP align=right><font color="[bg_color]" size=-1>
         <b>Gemein. Web</b></font>
        </TD>
    [ELSE]
      [IF may_d_read]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/d_read/[list]/" >Gemein. Web</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1 COLOR="[bg_color]"><b>Gemein. web</b></font>
        </TD>
      [ENDIF]
    [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="[dark_color]" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="[light_color]" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/review/[list]" >Review</A>
         </b></font>
	</TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
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
