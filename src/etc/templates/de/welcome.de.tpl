From: [conf->email]@[conf->host]
Subject: Willkommen auf der Mailing-Liste [list->name]
Content-Type: text/html


<HTML>
<HEAD>
<TITLE>Willkommen auf der Mailing-Liste [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Willkommen auf der Mailing-Liste [list->name]@[list->host]. </B><BR>
Sie sind mit der EMail-Adresse [user->email] registriert.
[IF user->password]
<BR> 
Ihr Passwort: [user->password].
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Weitere Informationen &uuml;ber die Liste:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>
</BODY></HTML>

