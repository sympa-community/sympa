From: [conf->email]@[conf->host]
Subject: Benvenuto nella lista [list->name]
Mime-version: 1.0
Content-Type: text/html;
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

<hr>


</body></html>

