<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin list_menu.tpl -->
<TABLE border="0"  CELLPADDING="0" CELLSPACING="0">
 <TR VALIGN="top"><!-- empty line in the left menu panel -->
  <TD WIDTH="--COL1--" BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL2--" BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL3--" ></TD>
  <TD WIDTH="--COL4--" ></TD>
 </TR>
 <TR>
  <TD WIDTH="--COL1--" BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>

<!-- begin -->
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

      [IF action=info]
        <TD WIDTH=100% BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
           <font color="--BG_COLOR--" size=-1><b>Info liste</b></font>
        </TD>
      [ELSE]
        <TD WIDTH=100% BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <A HREF="[path_cgi]/info/[list]" ><font size=-1><b>Info liste</b>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel list info -->
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL234-- COLSPAN=3 BGCOLOR="--BG_COLOR--" NOWRAP align=left>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="--LIGHT_COLOR--">
	  Abonnés: <B>[total]</B><BR>
	  Propriétaires :
	  [FOREACH o IN owner]
	    <BR><FONT SIZE=-1><A HREF="mailto:[o->NAME]">[o->gecos]</A></FONT>
	  [END]
	  <BR>
	  [IF is_moderated]
	    Modérateurs
	    [FOREACH e IN editor]
	      <BR><FONT SIZE=-1><A HREF="mailto:[e->NAME]">[e->gecos]</A></FONT>
	    [END]
	  [ENDIF]
          <BR>
	  [IF list_as_x509_cert]
          <BR><A HREF="[path_cgi]/load_cert/[list]"><font size="-1"><b>Charger le certificat<b></font></A><BR>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF is_priv]
 <TR><!-- for listmaster owner and editor -->
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>

  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

   [IF action=admin]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Admin liste</b></font></TD>
   [ELSIF action_type=admin]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
        <b>
         <A HREF="[path_cgi]/admin/[list]" ><FONT COLOR="--BG_COLOR--" SIZE="-1">Admin liste</FONT></A>
        </b>
        </TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/admin/[list]" >Admin liste</A>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel admin info -->
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL234-- COLSPAN=3 BGCOLOR="--BG_COLOR--" NOWRAP align=left>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="--LIGHT_COLOR--">
	   Taux d'adresse en erreur: <B>[bounce_rate]%</B><BR><BR>
	   [if mod_total=0]
	   Aucun message à modérer
           [else]
           Messages en attente de modération :<B> [mod_total]</B>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>


     <!-- end is_priv -->
   [ENDIF]
   <!-- Subscription depending on susbscriber or not, email define or not etc -->
   [IF is_subscriber=1]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>

  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=suboptions]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Options d'abonné</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/suboptions/[list]" >Options d'abonné</A>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF may_subscribe<>1]
        <!-- Should we print something in case subscribtion is closed ?? ->
        <!-- END may subscribe -->     
   [ENDIF] 
   [IF may_signoff=1] 
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=signoff]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Désabonnement</b></font></TD>
      [ELSIF user->email]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'Voulez-vous vous désabonner de la liste [list]?'); return false;">Désabonnement</A>
        </b></font>
        </TD>
      [ELSE]
       <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]">Désabonnement</A>
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
   [ELSE]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1 COLOR="--BG_COLOR--"><b>Désabonnement</b></font>
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
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=subrequest]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Abonnement</b></font></TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
   [IF may_subscribe=1]
        <font size=-1><b>
	[IF user->email]
         <A HREF="[path_cgi]/subscribe/[list]" onClick="request_confirm_link('[path_cgi]/subscribe/[list]', 'Voulez-vous vous abonner à la liste [list]?'); return false;">Abonnement</A>
	[ELSE]
         <A HREF="[path_cgi]/subrequest/[list]">Abonnement</A>
	[ENDIF]
        </b></font>
   [ELSE]
	<font size=-1 COLOR="--BG_COLOR--"><b>Abonnement</b></font>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
	[IF user->email]
         <A HREF="[path_cgi]/signoff/[list]" onClick="request_confirm_link('[path_cgi]/signoff/[list]', 'Voulez-vous vous désabonner de la liste [list]?'); return false;">Désabonnement</A>
	[ELSE]
	  <A HREF="[path_cgi]/sigrequest/[list]">Désabonnement</A>
	[ENDIF]
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
   [ENDIF]

      <!-- END is_subscriber -->
   [ENDIF]
 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
   [IF is_archived]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=arc]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archive</b></font>
	</TD>
   [ELSIF action=arcsearch_form]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archive</b></font>
	</TD>
   [ELSIF action=arcsearch]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archive</b></font>
	</TD>
   [ELSIF action=arc_protect]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archive</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
   [IF arc_access]
        <font size=-1><b>
         <A HREF="[path_cgi]/arc/[list]" >Archive</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="--BG_COLOR--"><b>Archive</b></font>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
      <!-- END is_archived -->
    [ENDIF]

 <!-- Post -->
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp; </TD>   
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
    [IF action=compose_mail]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1>
         <b>Poster</b></font>
        </TD>
    [ELSE]
      [IF may_post]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/compose_mail/[list]/" >Poster</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1 COLOR="--BG_COLOR--"><b>Poster</b></font>
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
 <!-- END post --> 

 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>

    [IF shared=exist]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp; </TD>   
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
    [IF action=d_read]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1>
         <b>Documents</b></font>
        </TD>
    [ELSE]
      [IF may_d_read]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/d_read/[list]/" >Documents</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1 COLOR="--BG_COLOR--"><b>Documents</b></font>
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
 <!-- END shared --> 

 <TR>
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]

    [IF may_review]
 <TR>
  <TD WIDTH=--COL1-- BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="--COL23--" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/review/[list]" >Les abonnés</A>
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
  <TD WIDTH=--COL12-- COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=--COL34-- COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]
</TABLE>
<!-- end list_menu.tpl -->


