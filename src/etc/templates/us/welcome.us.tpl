From: [conf->email]@[conf->host]
Subject: Welcome in list [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Welcome in list [list->name]@[list->host].
Your subscrition email is [user->email]
[IF user->password]
Your password : [user->password].
[ENDIF]

[PARSE 'info']

Everything about this list:
[conf->wwsympa_url]/info/[list->name]

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Welcome in list [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

<B>Welcome in list [list->name]@[list->host]. </B><BR>
Your subscrition email is [user->email] 
[IF user->password] 
<BR>
Your password : [user->password]. 
[ENDIF]
<BR><BR>
<PRE>
[PARSE 'info']
</PRE>

<HR>
Everything about this list:
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
--===Sympa===