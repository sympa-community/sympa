<!-- RCS Identication ; $Revision$ ; $Date$ -->

<!-- begin menu.tpl -->
<TABLE CELLPADDING="1" CELLSPACING="0" WIDTH="100%" BORDER="0"><TR><TD>
<TABLE CELLPADDING="0" CELLSPACING="0" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  [IF auth_method=smime]
  <TD bgcolor="[bg_color]">
     <A HREF="[path_cgi]/show_cert" onClick="winhelp=window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=600,height=320');winlogin.focus()" TARGET="wws_help"><IMG SRC="[icons_url]/locked.png" align="center" alt="security info" border=0></A>
  [ELSE]
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="1" CELLPADDING="2">
     <TR> 
  [IF user->email]
  [IF auth_method=md5]
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/logout/referer/[referer]" >
     [ELSE]
      <A HREF="[path_cgi]/logout/[action]/[list]" >
     [ENDIF]
     <FONT SIZE=-1><B>Logout</B></FONT></A>
     </TD>
  [ELSE]
     <TD NOWRAP BGCOLOR="[bg_color]" ALIGN="center">
      <A HREF="[path_cgi]/show_cert" onClick="winhelp=window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=600,height=320');winlogin.focus()" TARGET="wws_help"><IMG SRC="[icons_url]/locked.png" align="center" alt="security info" border=0></A>
     </TD>
  [ENDIF]
  [ELSE]
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
     [IF referer]
      <A HREF="[path_cgi]/nomenu/loginrequest/referer/[referer]"
     [ELSE]
      <A HREF="[path_cgi]/nomenu/loginrequest/[action]/[list]"
     [ENDIF]
       onClick="winlogin=window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=550,height=300');winlogin.focus()" TARGET="wws_login">

	 <FONT SIZE=-1><B>Login</B></FONT></A>
         </TD>
  [ENDIF]
    </TR>
  </TABLE>
  [ENDIF]
 </TD>
</TR>
</TABLE>


</TD>
<TD WIDTH=100% BGCOLOR="[bg_color]">&nbsp;</TD>
<TD>

<TABLE CELLPADDING=0 CELLSPACING=0 WIDTH="100%" BORDER=0>
  <TR ALIGN=center BGCOLOR="[dark_color]"><TD>
  <TABLE WIDTH="100%" BORDER=0 CELLSPACING=1 CELLPADDING=2>
     <TR> 
  [IF may_create_list]
   [IF action=create_list_request]
    <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center">
        <FONT SIZE=-1 COLOR="[bg_color]"><B>Création de liste</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="[light_color]"  ALIGN="center">
	 <A HREF="[path_cgi]/create_list_request" ><FONT SIZE=-1><B>Creation de liste</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF is_listmaster]
   [IF action=serveradmin]
    <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center">
        <FONT SIZE=-1 COLOR=[bg_color] ><B>Admin Sympa</B></FONT>
    </TD>
   [ELSE]
    <TD NOWRAP BGCOLOR="[light_color]"  ALIGN="center">
	 <A HREF="[path_cgi]/serveradmin" ><font size=-1><B>Admin Sympa</B></FONT></A>
    </TD>
   [ENDIF]
  [ENDIF]

  [IF user->email]

  [IF action=pref]
  <TD NOWRAP BGCOLOR="[selected_color]"  ALIGN="center">
      <FONT SIZE=-1 COLOR=[bg_color] ><B>Préférences</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]">
      <A HREF="[path_cgi]/pref/[action]/[list]" ><FONT SIZE=-1><B>Préférences</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=which]
  <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center">
      <FONT SIZE=-1 COLOR=[bg_color] ><B>Vos abonnements</B></FONT>
  </TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <A HREF="[path_cgi]/which" ><FONT SIZE=-1><B>Vos abonnements</B></FONT></A>
   </TD>
   [ENDIF]
  
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <FONT SIZE=-1 COLOR=[bg_color] ><B>Préférences</B></FONT>
  </TD>
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <FONT SIZE=-1 COLOR="[bg_color]"><B>Vos abonnements</B></FONT>
  </TD>
  [ENDIF]

  [IF action=home]
  <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center"><FONT SIZE=-1 COLOR=[bg_color]><B>Accueil</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <A HREF="[path_cgi]/" ><FONT SIZE=-1><B>Accueil</B></FONT></A>
  </TD>
  [ENDIF]

  [IF action=help]
  <TD NOWRAP BGCOLOR="[selected_color]" ALIGN="center"><FONT SIZE=-1 COLOR=[bg_color]><B>Aide</B></FONT></TD>
  [ELSE]
  <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center">
      <A HREF="[path_cgi]/help" ><FONT SIZE=-1><B>Aide</B></FONT></A>
  </TD>
  [ENDIF]
</TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
<!-- end menu.tpl -->




