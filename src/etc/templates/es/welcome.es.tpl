From: [conf->email]@[conf->host]
Subject: Bienvenido a la lista [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Bienvenido a la lista [list->name]@[list->host].
Usted ha sido subscrito con el e-mail [user->email]
[IF user->password]
Y contraseña : [user->password].
[ENDIF]

[PARSE 'info']

Para más información acerca de esta lista :
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit
<HTML>
<HEAD>
<TITLE>Bienvenido a la lista [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Bienvenido a la lista [list->name]@[list->host]. </B><BR>
Usted ha sido subscrito con el e-mail [user->email]
[IF user->password]
<BR>
Y contraseña : [user->password].
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Para más información acerca de esta lista :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>
--===Sympa===--
