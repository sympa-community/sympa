From: [conf->email]@[conf->host]
Subject: Benvenuto nella lista [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Benvenuto nella lista [list->name]@[list->host].
Il suo indirizzo di iscrizione e' [user->email]
[IF user->password]
La sua password : [user->password]
[ENDIF]

[PARSE 'info']

Tutto quello che riguarda questa lista :
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Benvenuto nella lista [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<b>Benvenuto nella lista [list->name]@[list->host].</b><BR>
Il suo indirizzo di iscrizione e' [user->email]
[IF user->password]
<BR>
La sua password : [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Tutto quello che riguarda questa lista :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
--===Sympa===
