From: [conf->email]@[conf->host]
Subject: Tervetuloa listalle [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Tervetuloa listalle [list->name]@[list->host].
Tilauksesi osoite on [user->email]
[IF user->password]
Salasanasi: [user->password].
[ENDIF]

[PARSE 'info']

Kaikki tiedot listasta:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Tervetuloa listalle [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Tervetuloa listalle [list->name]@[list->host]. </B><BR>
Tilauksesi osoite on [user->email] 
[IF user->password] 
<BR>
Salasanasi : [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Kaikki tiedot listasta:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
--===Sympa===--
