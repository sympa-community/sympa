From: [conf->email]@[conf->host]
Subject: Tere tulemast listi [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Tere tulemast listi [list->name]@[list->host].
Te liitusite aadressilt [user->email]
[IF user->password]
Teie parool on: [user->password].
[ENDIF]

[PARSE 'info']

Kogu info listi kohta:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Tere tulemast listi [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Tere tulemast listi [list->name]@[list->host]. </B><BR>
Te liitusite aadressilt [user->email] 
[IF user->password] 
<BR>
Teie parool on: [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Kogu info listi kohta:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
--===Sympa===
