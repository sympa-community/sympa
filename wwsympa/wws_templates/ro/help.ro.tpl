<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa iti ofera acces la mediul tau pe mailing list server <B>[conf->email]@[conf->host]</B>. 
<BR>
<BR>
Functiile, echivalente comenzilor Sympa automatizate, sunt accesibile in partea 
superioara a bannerului interfatei de utilizator. WWSympa ofera un mediu adaptabil 
cu acces la urmatoarele functii: 
<UL>
  <LI><A HREF="[path_cgi]/pref">Preferinte</A> : user preferences. This proposed 
    to identified users only. 
  <LI><A HREF="[path_cgi]/lists">Liste publice</A> : director cu liste disponibile 
    pe server
  <LI><A HREF="[path_cgi]/which">Subscrierile tale</A> : mediul tau ca si abonat 
    sau proprietar de lista
  <LI><A HREF="[path_cgi]/loginrequest">Login</A> / <A HREF="[path_cgi]/logout">Logout</A> 
    : Login / Logout din WWSympa. 
</UL>

<H2>Login</H2>

[IF auth=classic] 
La autentificare(<A HREF="[path_cgi]/loginrequest">Login</A>), 
scrie adresa email si parola asociata. <BR>
<BR>
Dupa autentificare, cu ajutorul unui <I>cookie</I> care contine informatiile tale 
vei fi conectat la WWSympa. Durata de viata acestui <I>cookie</I> este setabila 
prin intermediul <A HREF="[path_cgi]/pref">preferintelor</A>. <BR>
<BR>
[ENDIF] 
Poti iesi din sistem(stergere <I>cookie</I>) oricand utilizand functia 
<A HREF="[path_cgi]/logout">logout</A>. 
<H5>Probleme legate de login</H5>

<I>Nu sunt inscris pe o lista</I><BR>
Nu esti inregistrat in baza de date Sympa si nu poti sa te autentifici. Daca te 
inscrii intr-o lista, WWSympa iti va da o parola initiala. <BR>
<BR>
<I>Sunt inscris cel putin pe o lista dar nu am parola</I><BR>
Pentru a primi parola: <A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A> 
<BR>
<BR>
<I>Mi-am uitat parola</I><BR>
WWSympa iti poate trimite parola prin email: <A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A> 
<P> Pentru a contacta administratorul acestui serviciu : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A> 
  [ENDIF] 
