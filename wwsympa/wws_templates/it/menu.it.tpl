<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin menu.it.tpl -->
<TABLE CELLPADDING="1" CELLSPACING="0" WIDTH="100%" BORDER="0"><TR><TD>
<TABLE CELLPADDING="0" CELLSPACING="0" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  [IF auth_method=smime]
  <TD bgcolor="[bg_color]">
<A HREF="[path_cgi]/show_cert" onClick="winhelp=window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=600,height=320');winlogin.focus()" TARGET="wws_help">
     <IMG SRC="[icons_url]/locked.png" align="center" alt="security info" border=0></A>
  [ELSE]
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="1" CELLPADDING="2">
     <TR> 
  [IF user->email]
  [IF auth_method=md5]
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/logout/referer/[referer]" STYLE="TEXT-DECORATION: NONE">
     [ELSE]
      <A HREF="[path_cgi]/logout/[action]/[list]" STYLE="TEXT-DECORATION: NONE">
     [ENDIF]
     <FONT SIZE=-1><B>Logout</B></FONT></A>
     </TD>
  [ELSE]
     <TD NOWRAP BGCOLOR="[bg_color]" ALIGN="center"><IMG SRC="[icons_url]/locked.png" align="center" alt="https"></TD>
  [ENDIF]
  [ELSE]
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/nomenu/loginrequest/referer/[referer]" STYLE="TEXT-DECORATION: NONE"
     [ELSE]
      <A HREF="[path_cgi]/nomenu/loginrequest/[action]/[list]" STYLE="TEXT-DECORATION: NONE"
     [ENDIF]
onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=550,height=300')" TARGET="wws_login">
	 <FONT SIZE=-1><B>Login</B></FONT></A>
         </TD>
  [ENDIF]
    </TR>
  </TABLE>
  [ENDIF]
</TR>
</TABLE>


</TD>
<TD WIDTH=100% BGCOLOR="[bg_color]">&nbsp;</TD>
<TD>

<TABLE CELLPADDING=0 CELLSPACING=0 WIDTH="100%" BORDER=0>
  <TR ALIGN=center BGCOLOR="[dark_color]"><TD>
  <TABLE WIDTH="100%" BORDER=0 CELLSPACING=2 CELLPADDING=2>
     <TR> 
  [IF may_create_list]
   [IF action=create_list_request]
    <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center">
        <FONT SIZE=-1 COLOR=[bg_color] ><B>Crea una lista</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="[light_color]"  ALIGN="center">
	 <A HREF="[path_cgi]/create_list_request" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Crea una lista</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF is_listmaster]
   [IF action=serveradmin]
    <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center">
        <FONT SIZE=-1 COLOR=[bg_color] ><B>Amministra Sympa</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="[light_color]"  ALIGN="center">
	 <A HREF="[path_cgi]/serveradmin" STYLE="TEXT-DECORATION: NONE"><font size=-1><B>Amministra Sympa</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF user->email]

  [IF action=pref]
  <TD NOWRAP BGCOLOR="[selected_color]"  ALIGN="center">
      <FONT SIZE=-1 COLOR=[bg_color] ><B>Preferenze</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]">
      <A HREF="[path_cgi]/pref" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Preferenze</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=which]
  <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center">
      <FONT SIZE=-1 COLOR=[bg_color] ><B>Le tue mailing list</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <A HREF="[path_cgi]/which" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Le mie mailing list</B></FONT></A>
   </TD>
   [ENDIF]
  
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <FONT SIZE=-1 COLOR=[bg_color] ><B>Pref</B></FONT>
  </TD>
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <FONT SIZE=-1 COLOR="[bg_color]"><B>Le mie mailing list</B></FONT>
  </TD>
  [ENDIF]

  [IF action=home]
  <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center"><FONT SIZE=-1 COLOR=[bg_color]><B>Principale</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <A HREF="[path_cgi]/" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Principale</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=help]
  <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center"><FONT SIZE=-1 COLOR=[bg_color]><B>Aiuto</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <A HREF="[path_cgi]/help" STYLE="TEXT-DECORATION: NONE"><FONT SIZE=-1><B>Aiuto</B></FONT></A>
  </TD>
  [ENDIF]
</TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
<!-- end menu.it.tpl -->




