From: [conf->email]@[conf->host]
Subject: Bienvenue sur la liste [list->name]
Mime-version: 1.0
Content-Type: text/html;
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bienvenue dans la liste [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Bienvenue dans la liste [list->name]@[list->host].</B><BR> 
Votre adresse d'abonnement est  [user->email] 
[IF user->password] 
<BR>
Votre mot de passe : [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Pour tout savoir sur cette liste :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>

