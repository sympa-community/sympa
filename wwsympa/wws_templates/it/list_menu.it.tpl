<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin list_menu.it.tpl -->
<TABLE border="0"  CELLPADDING="0" CELLSPACING="0">
 <TR VALIGN="top"><!-- empty line in the left menu panel -->
  <TD WIDTH="5" BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="40" BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="30" ></TD>
  <TD WIDTH="40" ></TD>
 </TR>
 <TR>
  <TD WIDTH="5" BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>

<!-- begin -->
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

      [IF action=info]
        <TD WIDTH=100% BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
           <font color="--BG_COLOR--" size=-1><b>Informazioni</b></font>
        </TD>
      [ELSE]
        <TD WIDTH=100% BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <A HREF="[path_cgi]/info/[list]" STYLE="TEXT-DECORATION: NONE"><font size=-1><b>Informazioni</b>
        </font></A>
        </TD>
      [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>


  <TD WIDTH=40></TD>
 </TR>
 <TR><!-- empty line in the left menu panel -->
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR><!-- Panel list info -->
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=110 COLSPAN=3 BGCOLOR="--BG_COLOR--" NOWRAP align=left>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD BGCOLOR="--LIGHT_COLOR--">
	  Iscritti: <B>[total]</B><BR>
	  [IF is_priv]
	   Percentuale errati: <B>[bounce_rate]%</B><BR>
 	  [ENDIF]
	  <BR>
	  Proprietari
	  [FOREACH o IN owner]
	    <BR><FONT SIZE=-1><A HREF="mailto:[o->NAME]">[o->gecos]</A></FONT>
	  [END]
	  <BR>
	  [IF is_moderated]
	    Moderatori
	    [FOREACH e IN editor]
	      <BR><FONT SIZE=-1><A HREF="mailto:[e->NAME]">[e->gecos]</A></FONT>
	    [END]
	  [ENDIF]
          <BR>
	  [IF list_as_x509_cert]
          <BR><A HREF="[path_cgi]/load_cert/[list]"><font size="-1"><b>Load certificat<b></font></A><BR>
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
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF is_priv]
 <TR><!-- for listmaster owner and editor -->
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>

  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

   [IF action=admin]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Amministra</b></font></TD>
   [ELSIF action_type=admin]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
        <b>
         <A HREF="[path_cgi]/admin/[list]" STYLE="TEXT-DECORATION: NONE"><FONT COLOR="--BG_COLOR--" SIZE="-1">Amministra</FONT></A>
        </b>
        </TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/admin/[list]" STYLE="TEXT-DECORATION: NONE">Amministra</A>
        </b></font>
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
     <!-- end is_priv -->
   [ENDIF]
   <!-- Subscription depending on susbscriber or not, email define or not etc -->
   [IF is_subscriber=1]
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>

  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=suboptions]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Opzioni d'iscrizione</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/suboptions/[list]" STYLE="TEXT-DECORATION: NONE">Opzioni d'iscrizione</A>
        </b></font>
        </TD>
      [ENDIF]
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40>
  </TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF may_subscribe<>1]
        <!-- Should we print something in case subscription is closed ?? ->
        <!-- END may subscribe -->     
   [ENDIF] 
   [IF may_signoff=1] 
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
      [IF action=signoff]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Cancella iscrizione</b></font></TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]" STYLE="TEXT-DECORATION: NONE">Cancella iscrizione</A>
        </b></font>
        </TD>
      [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
   [ELSE]
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1 COLOR="--BG_COLOR--"><b>Cancella iscrizione<</b></font>
        </TD>
        <TD WIDTH=40></TD>
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
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=subrequest]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1><b>Iscrizione</b></font></TD>
   [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
   [IF may_subscribe=1]
        <font size=-1><b>
         <A HREF="[path_cgi]/subrequest/[list]" STYLE="TEXT-DECORATION: NONE">Iscrizione</A>
        </b></font>
   [ELSE]
	<font size=-1 COLOR="--BG_COLOR--"><b>Iscrizione</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>

   [IF may_signoff]
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>

        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
        <font size=-1><b>
         <A HREF="[path_cgi]/sigrequest/[list]" STYLE="TEXT-DECORATION: NONE">Cancella iscrizione</A>
        </b></font>
        </TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
   [ENDIF]

      <!-- END is_subscriber -->
   [ENDIF]
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
   [IF is_archived]
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
   [IF action=arc]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archivio</b></font>
	</TD>
   [ELSIF action=arcsearch_form]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archivio</b></font>
	</TD>
   [ELSIF action=arcsearch]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archivio</b></font>
	</TD>
   [ELSIF action=arc_protect]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right>
          <font size=-1 COLOR="--BG_COLOR--"><b>Archivio</b></font>
	</TD>
  [ELSE]

        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
   [IF arc_access]
        <font size=-1><b>
         <A HREF="[path_cgi]/arc/[list]" STYLE="TEXT-DECORATION: NONE">Archivio</A>
        </b></font>
   [ELSE]
        <font size=-1 COLOR="--BG_COLOR--"><b>Archivio</b></font>
   [ENDIF]
        </TD>
   [ENDIF]

       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>

  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
      <!-- END is_archived -->
    [ENDIF]

    [IF shared=exist]
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp; </TD>   
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
    [IF action=d_read]
        <TD WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" NOWRAP align=right><font color="--BG_COLOR--" size=-1>
         <b>Spazio web condiviso</b></font>
        </TD>
    [ELSE]
      [IF may_d_read]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/d_read/[list]/" STYLE="TEXT-DECORATION: NONE">Spazio web condiviso</A>
         </b></font>
        </TD>
      [ELSE]
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1 COLOR="--BG_COLOR--"><b>Spazio web condiviso</b></font>
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
  <TD WIDTH=40></TD>
 </TR> 
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]

    [IF may_review]
 <TR>
  <TD WIDTH=5 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH="70" COLSPAN="2" NOWRAP align=right>
   <TABLE  WIDTH="100%" BORDER="0" CELLPADDING="1" CELLSPACING="2">
    <TR>
     <TD BGCOLOR="--DARK_COLOR--" VALIGN="top">
      <TABLE BORDER="0" WIDTH="100%" CELLSPACING="1" CELLPADDING="2" VALIGN="top">
       <TR>
        <TD WIDTH="100%" BGCOLOR="--LIGHT_COLOR--" NOWRAP align=right>
         <font size=-1><b>
         <A HREF="[path_cgi]/review/[list]" STYLE="TEXT-DECORATION: NONE">Riassumi</A>
         </b></font>
	</TD>
       </TR>
      </TABLE>
     </TD>
    </TR>
   </TABLE>
  </TD>
  <TD WIDTH=40></TD>
 </TR>
 <TR>
  <TD WIDTH=45 COLSPAN=2 BGCOLOR="--DARK_COLOR--" NOWRAP>&nbsp;</TD>
  <TD WIDTH=70 COLSPAN=2><BR></TD>
 </TR>
    [ENDIF]
</TABLE>
<!-- end list_menu.it.tpl -->
