From: [conf->email]@[conf->host]
Subject: Welcome in list [list->name]
Content-Type: text/html


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
Everything about this list :
<A HREF="[conf->wwsympa_url]/info/[list->name]">[conf->wwsympa_url]/info/[list->name]</A>


</BODY></HTML>
