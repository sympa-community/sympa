<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa Vám poskytuje pøístup k Va¹emu prostøedí na konferenèním serveru
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Funkce, ekvivalentní k pøíkazùm v po¹tì, jsou dostupné ve vrchní úrovni
u¾ivatelského rozhraní. WWSympa poskytuje prostøedí s pøístupem k následujícím
funkcím:

<UL>
<LI><A HREF="[path_cgi]/pref">Nastavení</A> : u¾ivatelské nastavení. Je dostupné pouze pøihlá¹eným u¾ivatelùm

<LI><A HREF="[path_cgi]/lists">Veøejné konference</A> : adresáø konferencí dostupných na serveru

<LI><A HREF="[path_cgi]/which">Va¹e èlenství</A> : Va¹e prostøedí jako èlen nebo vlastník

<LI><A HREF="[path_cgi]/loginrequest">Pøihlá¹ení</A> / <A HREF="[path_cgi]/logout">Odhlá¹ení</A> : Pøihlá¹ení / Odhlá¹ení z WWSympa.
</UL>

<H2>Pøihlá¹ení</H2>

Pøi ovìøování toto¾nosti (<A HREF="[path_cgi]/loginrequest">pøihlá¹ení</A>), poskytujete Va¹i emailovou adresu a heslo.
<BR><BR>
Jakmile jste provìøen, je vytvoøena <I>"cookie"</I> která obsahuje
informace pro udr¾ení Va¹í toto¾nosti. Doba trvání <I>cookie</I> 
se dá zmìnit v <A HREF="[path_cgi]/pref">Nastavení</A>. 

<BR><BR>
Mù¾ete se odhlásit (vymazáním <I>cookie</I>) kdykoli pomoci funkce
<A HREF="[path_cgi]/logout">logout</A>.


<H5>Otázky pøihlá¹ení</H5>

<I>Nejsem èlenem konference</I><BR>
To znamená, ¾e nejste registrován v databázi u¾ivatelù a tedy se nemù¾ete 
pøihlásit. Jakmile se pøihlásíte do nìjaké konference, WWSympa Vám pøidìlí
úvodní heslo.
<BR><BR>

<I>Jsem èlenem v konferenci ale nám heslo</I><BR>
Pro získání hesla : 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Zapomnìl jsem heslo</I><BR>

WWSympa Vám za¹le heslo emailem :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

Kontakt na správce : <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]
