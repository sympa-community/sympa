<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
WWSympa a <B>[conf->email]@[conf->host]</B> levelezõlista szerveren
tárolt beállításaid módosításához nyújt elérést.
<BR><BR>
A mûveletek, a Sympa email parancsok megfelelõi, a felhasználói oldal
felsõ részén érhetõek el. WWSympa felületén keresztûl a következõ
mûveletek végezhetõek el:

<UL>
<LI><A HREF="[path_cgi]/pref">Beállítások</A>: felhasználó beállításai. Csak a felhasználó azonosításához szükséges.

<LI><A HREF="[path_cgi]/lists">Nyilvános listák</A>: a szerveren mûködõ nyilvános levelezõlisták sora.

<LI><A HREF="[path_cgi]/which">Feliratkozásod</A>: listatag vagy tulajdonos beállításai.

<LI><A HREF="[path_cgi]/loginrequest">Belépés</A> / <A HREF="[path_cgi]/logout">Kilépés</A> : Belépés / Kilépés a WWSympa programból.
</UL>

<H2>Belépés</H2>

Azonosításkor (<A HREF="[path_cgi]/loginrequest">Belépés</A>) meg kell adnod az email címedet és jelszavadat.
<BR><BR>
Sikeres azonosítás után a bejelentkezési adatokat a WWSympa a 
kapcsolat folyamán <i>süti</i>ben tárolja. A <i>süti</i> érvényességi
idejét a <A HREF="[path_cgi]/pref">beállítások</A> menûben lehet
megadni. 

<BR><BR>
Bármikor ki lehet lépni (a <i>süti</i> törlõdik) a
<A HREF="[path_cgi]/logout">kilépés</A> menûvel.

<H5>Bejelentkezésrõl</H5>

<I>Nem vagyok listatag </I><BR>
Tehát a Sympa adatbázisában nem vagy nyilvántartva, ezért nem tudsz bejelentkezni.
Ha lista tag vagy, akkor a WWSympa el küldheti a jelenlegi jelszavadat.
<BR><BR>

<I>Legalább egy lista tagja vagyok, de nincs jelszavam</I><BR>
Jelszavadat innen kaphatod meg: 
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>Elfelejtettem a jelszavamat</I><BR>

WWSympa emlékeztetõül el küldheti a jelszavadat:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

A rendszergazdát itt érheted el: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













