<!-- RCS Identication ; $Revision$ ; $Date$ -->

<BR>
[IF password_sent]
  Votre mot de passe vous a été envoyé à l'adresse [init_email].<BR>
  Relevez votre boîte aux lettres pour renseigner votre mot de passe ci-dessous. 
  <BR><BR>
[ENDIF]

[IF action=loginrequest]
Identifiez-vous pour : <UL>
  <LI>effectuer une opération privilégiée
  <LI>accéder à votre environnement personnel
</UL>

[ELSE]
 La plupart des services nécessitent votre adresse e-mail. Certaines listes sont
cachées aux personnes non identifées.
Pour bénéficier de l'accès intégral à ce serveur de listes, vous
devez probablement vous identifier préalablement.<BR>
[IF use_sso=0]
[IF use_passwd=1]
A cet effet, identifiez-vous en utilisant votre adresse messagerie et votre mot de passe. Au besoin faîtes vous allouer un mot de passe initial. 
[ENDIF]
[ELSE]
[IF use_passwd=1]

A cet effet, identifiez-vous de préférence en sélectionnant le serveur d'authentification de votre établissement ou à défault utilisez l'identification avec adresse et mot de passe

[ENDIF]
[ENDIF]

[ENDIF]

<TABLE BORDER=1 width=100% CELLSPACING=0 CELLPADDING=0>
<TR>

[IF use_sso]
<TD valign='top'>
[IF sso_number = 1]	

    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="sso_login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
	

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>Authentification magique&nbsp;

                [FOREACH server IN sso]
                   <INPUT TYPE="hidden" NAME="auth_service_name" VALUE="[server->NAME]">
                [END]
              </SELECT>
              <INPUT TYPE="submit" NAME="action_sso_login" VALUE="go" SELECTED>

   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 
[ELSE]
    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="sso_login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
	

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>Choississez le serveur CAS dont vous dépendez 

              <SELECT NAME="auth_service_name" onchange="this.form.submit();">
                [FOREACH server IN sso]
                   <OPTION VALUE="[server->NAME]">[server->NAME]
                [END]
              </SELECT>
              <INPUT TYPE="submit" NAME="action_sso_login" VALUE="Go" SELECTED>


   	    </TD>
     	  </TR>
       </TABLE>
 </FORM>
[END] 
</TD>

[ENDIF]

<TD valign='top'>


<TABLE BORDER=0  width=100% CELLSPACING=0 CELLPADDING=0>
<tr><td>
    <FORM ACTION="[path_cgi]" METHOD=POST> 
        <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
        <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	<INPUT TYPE="hidden" NAME="referer" VALUE="[referer]">
	<INPUT TYPE="hidden" NAME="action" VALUE="login">
	<INPUT TYPE="hidden" NAME="nomenu" VALUE="[nomenu]">
	

        <TABLE BORDER=0 width=100% CELLSPACING=0 CELLPADDING=0>
         <TR BGCOLOR="[light_color]">
          <TD NOWRAP align=center>
     	      <INPUT TYPE=hidden NAME=list VALUE="[list]">
     	      <FONT SIZE=-1 COLOR="[selected_color]"><b>adresse électronique <INPUT TYPE=text NAME=email SIZE=20 VALUE="[init_email]">
      	      mot de passe : </b>
              <INPUT TYPE=password NAME=passwd SIZE=8>&nbsp;&nbsp;
              <INPUT TYPE="submit" NAME="action_login" VALUE="Login" SELECTED>
   	    </TD>
     	  </TR>
       </TABLE>
 </FORM> 
</td></tr>
<TR><TD>

<TABLE BORDER=0><TR><TD>
<I>Si vous n'avez jamais eu de mot de passe sur ce serveur ou si vous l'avez oublié :</I>
</TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      [IF escaped_init_email]
        <A HREF="[path_cgi]/nomenu/sendpasswd/[escaped_init_email]"
      [ELSE]
	<A HREF="[path_cgi]/nomenu/remindpasswd/referer/[referer]"
      [ENDIF]
         onClick="window.open('','wws_login','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=300')" TARGET="wws_login" >

     <FONT SIZE=-1><B>Envoyez-moi mon mot de passe</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
</TR>
</TABLE>

</TD></TR></TABLE>

</TD></TR></TABLE>

</TD>

</TR>
</TABLE>

<CENTER>

</CENTER>




