From: [conf->email]@[conf->host]
Subject: Vitejte v konferenci [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit


Dobrý den.

Vítejte v konferenci [list->name]@[list->host].
Jste pøihlá¹en z adresy [user->email]
[IF user->password]
Va¹e heslo je: [user->password]
[ENDIF]

[PARSE 'info']

Informace o konferenci:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-2
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Vítejte v konferenci [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>
Dobrý den.<p>
<b>Vítejte v konferenci [list->name]@[list->host].</b><BR>
Jste pøihlá¹en z adresy [user->email]
[IF user->password]
<BR>
Va¹e heslo je: [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>
<HR>

Informace o konferenci:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>
--===Sympa===--
