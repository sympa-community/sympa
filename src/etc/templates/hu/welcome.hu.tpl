From: [conf->email]@[conf->host]
Subject: Üdvözlünk a(z) [list->name] levelezõlistán
Mime-version: 1.0
Content-Type: text/html; charset=iso-8859-2
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Üdvözlünk a(z) [list->name]@[list->host] levelezõlistán</title>
<BODY  BGCOLOR=#ffffff>

<B>Üdvözlünk a(z) [list->name]@[list->host] levelezõlistán. </B><BR>
Feliratkozási e-mail címed: [user->email] 
[IF user->password] 
<BR>
Jelszavad: [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
A listáról bõvebben itt olvashatsz:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</body></html>

