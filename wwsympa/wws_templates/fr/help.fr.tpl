<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa vous donne accès à votre environnement sur le serveur de listes 
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Seules les fonctions qui vous sont autorisées sont affichées dans
chaque page. Cette interface est donc plus complète et facile à utiliser
si vous êtes identifiés préalablement (via le bouton login). Exemple :

<UL>
<LI><TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
<TR><TD  NOWRAP>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/pref" >
     <FONT SIZE=-1><B>Préférences</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
  </TD>
</TR>
</TABLE>
</TD><TD> : Préférences d'usager.  </TD></TR></TABLE>

<LI>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
<TR><TD  NOWRAP>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/lists" >
     <FONT SIZE=-1><B>liste des listes</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
  </TD>
</TR>
</TABLE>
</TD><TD> : certaines listes sont
accéssibles à certaines catégories de personnes. Si vous n'êtes pas identfié,
cette page ne délivre que la liste des listes publiques. 
</TD></TR></TABLE>

<LI>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
<TR><TD  NOWRAP>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/which" >
     <FONT SIZE=-1><B>Vos abonnements</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
  </TD>
</TR>
</TABLE>
</TD><TD> : la liste de vos abonnements (et celle des listes que vous administrez).
</TD></TR></TABLE>
<LI>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
<TR><TD  NOWRAP>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/loginrequest" >
     <FONT SIZE=-1><B>login</B></FONT></A>
     </TD>
    </TR>
  </TABLE></TD>
</TR>
</TABLE>
</TD><TD> / </TD><TD>
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/logout" >
     <FONT SIZE=-1><B>logout</B></FONT></A>
     </TD>
    </TR>
  </TABLE></TD>
</TR>
</TABLE>
</TD><TD>
 : connexion / déconnexion .
</TD></TR></TABLE>
</UL>

<H2>Login</H2>

Le bouton Login, permet de vous identifier auprès du
serveur en renseignant votre adresse email et le mot de passe associé.
Si vous avez oublié votre mot de passe, ou si vous n'en avez jamais eu aucun, le bouton
<TABLE CELLPADDING="2" CELLSPACING="2"  BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/remindpasswd" >
     <FONT SIZE=-1><B>Recevoir mon mot de passe</B></FONT></A>
     </TD>
    </TR>
  </TABLE></TD>
</TR>
</TABLE>
de la page d'accueil permet de vous en faire allouer (ou ré-allouer) un.

<BR><BR>

Une fois authentifié un <I>cookie</I> contenant vos information de connexion
est envoyé à votre navigateur. Votre adresse apparait en haut à gauche de la page.
La durée de vie de ce cookie est paramétrable via 
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/pref" >
     <FONT SIZE=-1><B>Préférences</B></FONT></A>
     </TD>
    </TR>
  </TABLE></TD>
</TR>
</TABLE>


<BR><BR>
Vous pouvez vous déconnecter (effacer le <I>cookie</I>) à tout moment en utilisant le bouton
<TABLE CELLPADDING="2" CELLSPACING="2" BORDER="0">
  <TR ALIGN=center BGCOLOR="[dark_color]">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/logout" >
     <FONT SIZE=-1><B>Logout</B></FONT></A>
     </TD>
    </TR>
  </TABLE></TD>
</TR>
</TABLE>
<BR>
Pour contacter les administrateurs de ce service : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>

<P>
[ENDIF]

