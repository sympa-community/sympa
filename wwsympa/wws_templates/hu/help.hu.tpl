<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
A WWSympa felület a <B>[conf->email]@[conf->host]</B> levelezõlista-szerveren
tárolt beállításaid módosításához nyújt egyszerû elérést.
<BR><BR>
A mûveletek, a Sympa e-mail parancsok megfelelõi, a felhasználói oldal
felsõ részén érhetõek el. A WWSympa felületen keresztûl a következõ
mûveletek érhetõk el:

<UL>
<LI><A HREF="[path_cgi]/pref">Beállításaim</A>: felhasználó beállításai. Csak a felhasználó egyedi azonosításához szükséges.

<LI><A HREF="[path_cgi]/lists">Nyilvános listák</A>: a szerveren mûködõ nyilvános levelezõlisták sora.

<LI><A HREF="[path_cgi]/which">Feliratkozásaim</A>: listatag vagy tulajdonos beállításai.

<LI><A HREF="[path_cgi]/loginrequest">Belépés</A> / <A HREF="[path_cgi]/logout">Kilépés</A> : Belépés / Kilépés a WWSympa programból.
</UL>

<H2>Belépés</H2>

[IF auth=classic]
Azonosításkor (<A HREF="[path_cgi]/loginrequest">Belépés</A>) meg kell adnod az e-mail címedet és jelszavadat.
<BR><BR>
Sikeres azonosítás után a bejelentkezési adatokat a WWSympa a 
kapcsolat folyamán <i>süti</i>ben tárolja. A <i>süti</i> érvényességi
idejét a <A HREF="[path_cgi]/pref">beállításaim</A> menûben lehet
megadni. 

<BR><BR>
[ENDIF]

A <A HREF="[path_cgi]/logout">Kilépés</A> menûvel bármikor ki lehet lépni
a programból, ekkor az azonosításhoz használt <i>süti</i> törlõdik.

<H5>Bejelentkezésrõl</H5>

<I>Nem vagyok listatag </I><BR>
Tehát a Sympa adatbázisában nem vagy nyilvántartva, ezért nem tudsz bejelentkezni.
Ha lista tag vagy, akkor a WWSympa kérésre elküldheti a jelenlegi jelszavadat,
hogy be tudj jelentkezni.
<BR><BR>

<I>Legalább egy lista tagja vagyok, de nincs jelszavam</I><BR>
A jelszavadat a következõ oldalon lekérheted e-mailben: 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Elfelejtettem a jelszavamat</I><BR>

A WWSympa emlékeztetõül elküldheti a jelszavadat:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

A rendszergazdát itt érheted el: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]
