$ April 2000, Initial version by Mikko "Bemmu" Sepponen

$quote "

$set 1	Messages used while processing the configuration file
1	"Asetustiedostossa on virheitä.\n"
3	"Virhe rivillä %d : %s"
102	"2.5.4"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Hakemiston %s käyttäminen ei onnistu : %m"

$set 4	Messages used in the main loop
11	"Viestisi listalle %s on hylätty"
12	"Viestiäsi ei voitu lähettää, koska viestin koko ylitti listalle asetetun kokorajoituksen.\n"
15	"Yritit lähettää viestin yksityiselle listalle, vaikket itse kyseiselle listalle kuulu.\n\
Siispä viestisi on palautettu sinulle.\n\n\
Viestisi :\n"
17	"Käskyjesi lopputulos"
18	"Käskyä 'quit' ei löytynyt : viestin loppuosasta ei välitetä.\n"
19	"Käskyä ei ymmärretty : viestin loppuosasta ei välitetä.\n"
24	"EXPIRE-käskysi loppu listalla %s"
26	"Tilaajiin kuuluu :\n"
27	"Jos haluat poistaa nämä tilaajat listalta, käytä seuraavia komentoja :\n"
28	"Listan %s tilaajien joukossa %d päivän aikana, %d ei vahvistanut tilaustaan.\n"
37	"Hylkään text/plainiin kuulumattoman viestin osan, käytä vain text/plainia \n(tai laita käskysi subject-kenttään).\n"
38	"Viestisi listalle %s on annettu eteenpäin toimittajille\n"

$set 5	Messages used in the tools module
1	"Safefork ei voinut luoda uutta prosessia : %m"
2	"Reititysvirhe ?"
3	"Seuraava viesti oli lähetetty listalle vaikka se näyttää sisältävän\n\
käskyjä kuten subscribe, unsubscribe, help, index, get, ...\n\n\
Jos viestisi todellakin sisälsi komentoja, huomaa että \n\
komentoja ei tulisi koskaan, missään tapauksessa, lähettää listoille. \n\
Komennot tulee lähettää yksinomaan osoitteeseen %s.\n\n\
Jos viestisi oli tosiaan tarkoitettu listalle, se on tulkittu\n\
ohjelmiston puolesta komentona. Ole hyvä ja ota yhteys palvelun\n\
ylläpitäjään : %s jotta viestisi voidaan käsitellä.\n\n\
Kiitos ajastasi.\n\n\
------ Epäselvän viestin alku ------\n"
4	"------ Epäselvän viestin loppu ------\n"

$set 6	Messages du module Commands.pm
2	"Ohjetiedoston luku epäonnistui : %s\n"
5	"Listaa '%s' ei ole olemassa.\n"
6	"Listaan %s liittyvää tietoa :\n\n"
7	"Tämän listan arkistot eivät sisällä mitään tiedostoa.\n"
8	"Tarvittavaa tiedostoa ei ole.\n"
9	"Lista on yksityinen : Et voi lukea arkistoja.\n"
10	"Lista on yksityinen : Et voi selata tiedostoja.\n"
11	"Lista on yksityinen : Et voi selata tilaajalistaa.\n"
13	"Syntaksivirhe komennossa.\n"
15	"Käyttöoikeuksien tarkastusprosessi epäonnistui\n\n"
16	"Vahvistit listan tilauksen luultavasti eri sähköpostiosoitteesta.\n\
Yritä listan tilaamista alkuperäisestä osoitteesta."
18	"Tilauksesi listalle %s on poistettu."
21	"Tilauksen uusiminen listalle '%s'"
24	"Tilaus tälle listalle on tällä hetkellä keskeytetty.\n"
25	"Pyyntösi listalle liittymiseen tai listalta poistumiseen on lähetetty eteenpäin\n\
listan omistajien hyväksyttäväksi. Saat vahvistuksen kun listan tilaus\n\
(tai listalta poistuminen) on hyväksytty.\n"
26	"Listalta %s poistuminen ei ole mahdollista.\n"
27	"Listan tilaukseesi liittyvää tietoa on päivitetty.\n"
28	"Olet nyt listan %s tilaaja.\n"
29	"Tätä listaa koskevat tiedot lähetetään erillisessä viestissä.\n"
30	"Sähköpostiosoitettasi ei löytynyt listalta. Ehkä\n\
liityit listan tilaajaksi eri sähköpostiosoitteesta ?\n"
31	"Sinut on poistettu listalta %s.\n\
Kiitos listan käytöstä.\n"
32	"Vain listan %s omistajat voivat lisätä tai poistaa tilaajia.\n\
Tämän komennon käyttö ei ole sallittua, tai et antanut käyttöoikeuksien\n\
tarkastamiseen tarvittavia tietoja.\n"
33	"Sähköpostiosoitetta %s ei löytynyt listalta.\n"
34	"Sinut on poistettu listalta. Poistamisen\n\
suoritti %s, listan omistaja.\n\n\
Tällainen toimenpide tehdään yleensä kun viestien toimittaminen\n\
aiheuttaa ilmoituksia viestin toimitusongelmista. Osoitteesi saattaa\n\
kuitenkin toimia oikein. Jos näin on asian laita, pyydämme anteeksi\n\
ja toivomme että uusit tilauksesi.\n"
35	"Arkisto lähetetään sinulle erillisessä viestissä.\n"
36	"Käyttäjää %s koskevat tiedot on päivitetty listalle %s.\n"
37	"Käyttäjä %s on nyt listan %s tilaaja.\n"
38	"Käyttäjä %s on poistettu listalta %s/\n"
39	"Joku (toivon mukaan sinä) pyysi listan %s käyttäjän\n\
poistettavaksi tai lisättäväksi.\n\n\
Jos haluat että näin todellakin tehdään, lähetäpä viesti osoitteeseen\n\
%s, viestin tulisi sisältää \n\n\
   %s\n\n\
Jos et halua tehdä tätä, älä reagoi tähän viestiin.\n"
40	"Listaan %s liittyvät asetukset on päivitetty.\n"
41	"Listan %s moderoidun viestin käyttö avaimella %s ei onnistunut.\n\
Viesti on jo saatettu lähettää listan jonkun moderoijan toimesta\n.\n"
43	"Listan %s viesti on poistettu.\n"
44	"Listan %s viesti on pistetty levitykseen.\n"
45	"Lista %s ei hyväksy DIGEST-tilaa. Asetuksiasi tämän komennon suhteen ei ole päivitetty.\n"
46	"Vain moderaattorit voivat käyttää MODINDEX-käskyä.\n\
Et kuulu listan %s moderaattoreihin.\n"
47	"Vain listan omistajat voivat käyttää EXPIRE, EXPIREINDEX tai EXPIREDEL -komentoja.\n\
Et kuulu listan %s omistajiin.\n"
48	"\
Joku (toivottavasti sinä) pyysi, että listan '%s' %d päivää ylittävien\n\
tilaajien täytyy vahvistaa tilauksensa.\n\
Jos et halua että näin tapahtuu, älä reagoi tähän viestiin.\n\
Jos haluat vahvistaa tämän toimenpiteen, lähetä sähköpostia osoitteeseen '%s'.\n\
Sähköpostin tulisi sisältää seuraava komento:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
EXPIRE-komento on juuri ajautumassa listalla %s.\n\
Sen käynnisti omistaja %s (%s)\n\
Vain yksi expire-prosessi voi olla kerrallaan käynnissä listalla.\n\
Tällä hetkellä pyörivä expire-käsky koskee ihmisiä jotka ovat tilanneet\n\
yli %d päivää tai ihmisiä jotka eivät ole vahvistaneet tilaustaan. Expire\n\
päättyy %d:ssä päivässä (%s).\n"
52	"%s ei vastaanottanut vahvistusta seuraaville osoitteille :\n"
53	"Expire-prosessin lopettaminen : EXPIREDEL %s\n"
54	"Listalla %s ei ole tällä hetkellä menossa expire-prosessia.\n"
55	"Listaa %s koskeva expire-prosessi lopetettu\n"
56	"\
Listaa %s koskeva expire-prosessi aloitettu. Tämä prosessi loppuu\n\
%d:ssä päivässä. Saat prosessin loputtua listan tilaajista jotka eivät\n\
vahvistaneet tilaustaan ajoissa.\n\
Voit sitten poistaa nuo tilaajat itse DEL-komennon avulla.\n"
57	"Saadaksesi luettelon listan tilaajista, jotka eivät ole\n\
vahvistaneet tilaustaan : EXPIREINDEX %s\n"
58	"Voit poistaa nämä tilaajat listalta seuraavia käskyjä käyttäen :\n"
60	"\
EXPIRE-käskyä ei voitu suorittaa. Käskyä tulee seurata teksti joka\n\
on tarkoitettu tilauksen vahvistamista tarvitseville tilaajille.\n\
Tämän tekstin täytyy\n\
 - alkaa EXPIRE-käskyä seuraavalta riviltä,\n\
 - sisältää ainakin 20 sanaa,\n\
 - ja loppua QUIT-sanaan.\n"
61	"Viestisi on lähetetty sinulle takaisin :\n"
67	"Tässä listat, joiden tilaaja tällä hetkellä olet :\n\n"
68	"En voinut käyttää avaimella %s vahvistettua viestiä.\n"
69	"%s lähetti tilauksen päättymisviestisi seuraaviin osoitteisiin :\n"
70	"\nPowered by Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Lopeta tilauksesi listalle %s"
72	"\n\nListat, joiden omistaja olet:\n\n"
73	"\n\nListat, joiden toimittaja olet:\n\n"
74	"%s tarvitsee vahvistusta komennolle %s\n"
75	"Käytä lopettaaksesi käyttäjän %s tilauksen miltä tahansa listalta \n"
76	"Muistutus %s tilauksestasi"
77	"Olet listan %s tilaaja sähköpostiosoitteella %s\n"
78	"Tilausmuistutus lähetetty jokaiselle %d:lle listan %s tilaajista\n"
79	"Joku (sinä toivottavasti) pyysi Sympaa lähettämään tilauksen\n\
jokaiselle listan %s tilaajista\n\n\
Jos haluat että näin tapahtuu, lähetä viesti sähköpostiosoitteeseen\n\
%s, viestin tulee sisältää \n\n\
   %s\n\n\
Jos et halua että näin tapahtuu, älä reagoi tähän viestiin.\n"
80	"Komennon %s suorittaminen listalla %s kielletty\n"
81	"Käyttäjän opas"
82	"Julkiset listat"
83	"Tilausyhteenveto"
84	"Käyttäjä '%s' on jo listan '%s' tilaaja\n"
85	"Käyttäjä %s on kutsuttu liittymään listan %s tilaajaksi.\n"
86	"Käyttäjää %s ei haluta listalle %s.\n"
260	"Joku (toivottavasti sinä) pyysi sähköpostiosoitteesi\n\
lisäämistä listalle '%s'.\n\
Jos haluat että näin tapahtuu niin\n\
\n\
- vastaa tähän mailiin\nTAI\n\
- lähetä viesti osoitteeseen %s ja laita subject-kenttään\n %s\nTAI\n\
- käytä tätä: %s\n\
\n\
Jos et halua että mailiosoitettasi lisätään listalle, sinun ei\n\
tarvitse reagoida mitenkään."
261	"Joku (toivon mukaan sinä) pyysi että mailiosoitteesi\n\
poistetaan listalta '%s'.\n\
Jos haluat että näin tehdään niin \n\
\n\
- vastaa tähän mailiin\nTAI\n\
- lähetä viesti osoitteeseen '%s' ja laita subject-kenttään\n %s\nTAI\n\
- käytä tätä: %s\n\n\
\
Tämä voidaan tehdä URLin %s avulla\n\
Jos et halua että näin tapahtuu, voit vain unohtaa tämän viestin."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Listan %s omistajat"
2	"Tilauspyyntö listalle %s"
3	"Hyvä listan %s omistaja,\n\n\
Käyttäjä pyysi päästä listasi tilaajaksi. Jos tämä käy sinulle,\n\
voisit harkita seuraavan komennon käyttämistä:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
4	"Listan %s moderoijat"
5	"[%s] Hyväksyntää odottava artikkeli"
6	"Tervetuloa listalle %s"
7	"Tiedosto"
8	"\
   Vastaanotettuja viestejä    :  %9d\n\
   Forwardoituja viestejä      :  %9d\n\
   Megoja lähetetty            :  %9d\n\
   Megoja forwardoitu          :  %9d\n"
9	"Listan %s digest"
10	"Levittääksesi liitetetiedoston listalle %s:\n\
mailto:%s?subject=DISTRIBUTE%%20%s%%20%s\n\n"
11	"Hylätäksesi sen (se poistetaan):\n\
mailto:%s?subject=REJECT%%20%s%%20%s\n"
12	"Levittääksesi liitetyn viestin listalla %s :\n\
mailto:%s?subject=CONFIRM%%20%s\n\n"
13	"Sisällysluettelo"
14	"Listan %s digestin loppu"
15	"%d moderoitavaa viestiä listalla %s"
16	"Tarvitaan käyttöoikeuksien vahvistus"
21	"FYI: %s listalla %s lähteestä %s %s"
22	"FYI-komento %s listalla %s lähteestä %s %s \n (tähän ei tarvitse puuttua)\n"
23	"VAROITUS : %s %s ei onnistunut lähtemään listalta %s koska hänen osoitteensa\n\
ei löytynyt listalta\n (Voisit auttaa tätä henkilöä)\n"
24	"Tilauksen päättämispyyntö listalta %s"
25	"Hyvä listan %s omistaja,\n\n\
Käyttäjä pyysi että hänet tuhotaan tilaajalistalta. Jos tämä käy sinulle,\n\
sinun tulisi käyttää seuraavaa komentoa:\n\n\
DEL %s %s\n"
26	"FYI-komento %s listalla %s lähteestä %s %s vahvistettu %s toimesta\n\
 (sinun ei tarvitse tehdä mitään)\n"
27	"Palautettujen (bounce) viestien osuus listalla %s on %d%%.\n\n\
Sinun tulisi poistaa nämä tilaajat,\n\
joille lähetetyt viestit ovat palanneet takaisin : \n\
%s/reviewbouncing/%s"
28	"VAROITUS: palanneiden (bounce) viestien osuus liian suuri listalla %s"
29	"Kutsu listalle %s liittymiseksi"
30	"Sinut on kutsuttu listalle %s"

$set 9	Messages for the review header
1	"Omistaja           : %s\n"
2	"Moderaattori       : %s\n"
3	"Tilaus             : %s\n"
4	"Tilauksen lopetus  : %s\n"
5	"Viestien lähetys   : %s\n"
6	"Tilaajien lista    : %s\n"
7	"Vastausosoite      : %s\n"
8	"Enimmäiskoko       : %s\n"
9	"Listan URL         : %s\n"
10	"Digest             : %s\n"
11	"Kustomoitu aihe    : %s\n"
12	"Aihe               : %s\n"

$set 11	Messages used by the smtp module.
1	"Järjestelmäsi ei seuraa POSIX P1003.1 standardia, tai\n\
Perl ei definoi _SC_ARG_MAX constantia POSIX-kirjastossaan.\n\
Sinun täytyy muokata smtp.pm moduulia asettaaksesi arvon\n\
muuttujalle $max_arg.\n"
2	"Ei voitu luoda kanavaa smtpto:ssa : %m"

$set 12 MIME headers
1	"1.0"
2	"us-ascii"
3	"7bit"
4	"SYMPA <%s>"

$set 13	Messages for the header of moderation index
1	"\t     Päivämäärä           : %s"
2	"\t     Lähettäjä            : %s"
3	"\t     Koko                 : %s\n"
4	"\t     Moderointiavain      : %s\n"


