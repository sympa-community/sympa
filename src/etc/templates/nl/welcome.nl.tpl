From: [conf->email]@[conf->host]
Subject: Welkom bij de lijst [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Welkom bij de lijst [list->name]@[list->host].
Het emailadres waarmee u zich heeft ingeschreven is [user->email]
[IF user->password]
Uw wachtwoord : [user->password].
[ENDIF]

[PARSE 'info']

Alles over deze lijst:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Welkom bij de lijst [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Welcome bij de lijst [list->name]@[list->host]. </B><BR>
Het emailadres waarmee u zich heeft ingeschreven is [user->email] 
[IF user->password] 
<BR>
Uw wachtwoord : [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Alles over deze lijst:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
--===Sympa===--
