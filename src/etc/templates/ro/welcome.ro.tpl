From: [conf->email]@[conf->host]
Subject: Bine ai venit pe lista [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Bine ai venit pe lista [list->name]@[list->host].
Adresa de mail de abonare este [user->email]
[IF user->password]
Parola este : [user->password].
[ENDIF]

[PARSE 'info']

Afla mai multe despre aceasta lista:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bine ai venit pe lista  [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Bine ai venit pe lista [list->name]@[list->host]. </B><BR>
Adresa de mail de abonare este [user->email] 
[IF user->password] 
<BR>
Parola este : [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Afla mai multe despre aceasta lista:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
--===Sympa===