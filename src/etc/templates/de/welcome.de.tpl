From: [conf->email]@[conf->host]
Subject: Willkommen auf der Mailing-Liste [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Willkommen auf der Mailing-Liste [list->name]@[list->host].
Sie sind mit der EMail-Adresse [user->email] registriert.
[IF user->password]
Ihr Passwort: [user->password].
[ENDIF]

[PARSE 'info']

Weitere Informationen &uuml;ber die Liste:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

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
--===Sympa===
