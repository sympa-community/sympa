<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa tarjoaa liittym‰n postituslistaohjelmaan palvelimella
<B>[conf->email]@[conf->host]</B>.
<BR><BR>
Komennot, jotka vastaavat Sympa email komentoja, ovat k‰ytett‰viss‰
liittym‰n yl‰osassa. WWSympa tarjoaa liittym‰n seuraaville toiminnoille:

<UL>
<LI><A HREF="[path_cgi]/pref">Asetukset</A> : k‰ytt‰j‰n asetukset. T‰m‰ on vain tunnistetuille k‰ytt‰jille.

<LI><A HREF="[path_cgi]/lists">Julkiset listat</A> : hakemisto listoista jotka ovat saatavilla t‰ll‰ palvelimella

<LI><A HREF="[path_cgi]/which">Tilauksesi</A> : ymp‰ristˆsi tilaajana tai omistajana

<LI><A HREF="[path_cgi]/loginrequest">Kirjaudu</A> / <A HREF="[path_cgi]/logout">Kirjaudu ulos</A> : Kirjautuminen/Kirjautuminen ulos WWWSympassa.
</UL>

<H2>Kirjautuminen</H2>

[IF auth=classic]
Kun tunnistaudut(<A HREF="[path_cgi]/loginrequest">Kirjautuminen</A>), anna email osoitteesi ja salasana.
<BR><BR>
Kun olet tunnistautunut, <I>kuitti(cookie)</I> sis‰lt‰en kirjautumistietoja 
tallennetaan joka m‰‰rittelee WWSynpa yhteyden keston. <I>Kuitin</I> 
kesto on m‰‰ritelt‰viss‰ <A HREF="[path_cgi]/pref">asetuksissa</A>. 

<BR><BR>
[ENDIF]

Voit kirjautua ulos (<I>kuitin</I> poisto) milloin tahansa
<A HREF="[path_cgi]/logout">uloskirjautumis</A>
toiminnolla.

<H5>Kirjautumis asiaa</H5>

<I>En ole listan tilaaja </I><BR>
Et ole Sympan k‰ytt‰j‰tietokannassa etk‰ siksi voi kirjautua.
Kun tilaat listan, WWSympa antaa sinulle alustavan salasanan.
<BR><BR>

<I>Olen tilaaja ainakin yhdell‰ listalla, mutta minulla ei ole salasanaa</I><BR>
Vastaanottaaksesi salasanan : 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Unohdin salasanan</I><BR>

WWSympa voi muistuttaa salasanasta emailina :
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

Ottaaksesi yhteytt‰ t‰m‰n palvelun yll‰pit‰j‰‰n :  <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













