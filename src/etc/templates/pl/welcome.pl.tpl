From: [conf->email]@[conf->host]
Subject: Witaj na li¶cie [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Witaj na li¶cie [list->name]@[list->host].
Zosta³e¶ zapisany z adresem [user->email]
[IF user->password]
Twoje has³o to: [user->password]
[ENDIF]

[PARSE 'info']

Informacje o li¶cie:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-2
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Witaj na li¶cie [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<b>Witaj na li¶cie [list->name]@[list->host].</b><BR>
Zosta³e¶ zapisany z adresem [user->email]
[IF user->password]
<BR>
Twoje has³o to: [user->password]
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>
<HR>

Informacje o li¶cie:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>

</BODY></HTML>
--===Sympa===
