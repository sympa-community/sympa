From: [conf->email]@[conf->host]
Subject: Witaj na li¶cie [list->name]
Mime-version: 1.0
Content-Type: text/html;
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Benvenuto nella lista [list->name]@[list->host]</title>
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

