$ April 2001, Initial Hungarian translation by Szilard Vizi <vizisz@freemail.hu>
$ June 2001, Updating with the help of Attila Szabo <szabo.a@oep.hu>

$quote "

$set 1	Messages used while processing the configuration file
1	"A konfigurációs állomány hibás.\n"
3	"Hiba a(z) %d sorban: %s"
102	"2.8.1"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"%s könyvtár nem elérhetõ: %m"

$set 4	Messages used in the main loop
11	"%s részére küldött leveled vissza lett utasítva"
12	"Leveledet nem lehet kézbesíteni, mert mérete\n\
a listára küldhetõ maximális méretet meghaladta.\n"
15	"%s listára küldött leveledet visszautasították.\n\
A leveled vissza lett küldve a címedre.\n\n\
Leveled:\n"
17	"Parancsaid eredménye"
18	"'quit' parancs megadva: üzenet többi része figyelmen kívül hagyva.\n"
19	"Nem értelmezhetõ parancs: üzenet többi része figyelmen kívül hagyva.\n"
24	"EXPIRE parancs teljesítve a(z) %s listán."
26	"Tagok listája:\n"
27	"A felsorolt tagokat a következõ paranccsal törölheted a listáról:\n"
28	"A(z) %s lista tagjai közül %d napja %d nem erõsítette meg a tagságát.\n"
37	"A levél törzse nem sima szöveges formátumú, figyelmen kívül lett hagyva.\n Kérlek csak sima szöveges formátumot használj (vagy parancsot a levél tárgyában adj meg).\n"
38	"%s listára küldött leveled a szerkesztõ(k)höz lett továbbítva\n"
39	"Nem található parancs a levélben."
40	"Leveled engedélyeztetése"

$set 5	Messages used in the tools module
1	"Safefork nem tud új folyamatot indítani: %m"
2	"Routing hiba?"
3	"A következõ levél a listára lett küldve, miközben valószínûleg\n\
parancsokat, mint például subscribe, unsubscribe, help, index, get, ... tartalmaz.\n\n\
Ha leveled tényleg parancsokat tartalmaz, akkor fontos tudnod, hogy az \n\
ilyen leveleket nem a listára, hanem kizárólag a(z) %s címre kell\n\
küldeni.\n\n\
Ha leveled a listára lett küldve, akkor a levelezõlista-kezelõ a\n\
parancsokat végrehajtja. Ekkor fordulj a(z) %s üzemeltetõjéhez,\n\
hogy leveledrõl gondoskodjon.\n\n\
Köszönöm megértésedet.\n\n\
------ Problémás levél eleje ------\n"
4	"------ Problémás levél vége ------\n"

$set 6	Messages du module Commands.pm
2	"Nem olvasható a súgó állomány: %s\n"
5	"Nincs '%s' nevû lista.\n"
7	"A lista archívuma nem tartalmaz egyetlen levelet sem.\n"
8	"A kért állomány nem létezik.\n"
9	"Privát lista: Az archívumot nem olvashatod.\n"
10	"Privát lista: Az elérhetõ állományok között nem böngészhetsz.\n"
11	"Privát lista: A tagok listáját nem tekintheted meg.\n"
12	"Listatagok: %d\n"
13	"Hibásan megadott parancs.\n"
15	"Hiba az azonosításkor\n\n"
16	"Feliratkozásodat valószínûleg egy másik email címrõl erõsítetted\n\
meg. Kérlek a megfelelõ email címedet használd feliratkozáshoz."
18	"A(z) %s listáról töröltek."
21	"'%s' listán feliratkozásod meg lett újítva"
24	"A listára való jelentkezés jelenleg szünetel.\n"
25	"Fel/leiratkozásod a lista tulajdonosának jóváhagyásra továbbítva lett.\n\
A tulajdonos döntésérõl (fel/leiratkozásod ügyében) emailben\n\
értesítést fogsz kapni.\n"
26	"A(z) %s listáról nem lehet leiratkozni.\n"
27	"Feliratkozási információid frissítve lettek.\n"
28	"A(z) %s lista tagja lettél.\n"
29	"A listával kapcsolatos információkat külön levélben fogod megkapni.\n"
30	"%s listán nem található az email címed. Nem lehet, hogy egy\n\
másik email címmel iratkoztál fel?\n"
31	"%s listáról sikeresen leiratkoztál.\n\
Köszönjük, hogy eddig velünk voltál.\n"
32	"Csak a(z) %s lista tulajdonosa jogosult tagok felvételére vagy törlésére.\n\
Ezt a parancsot nem használhatod, vagy az azonosításodhoz nem adtad\n\
meg a szükséges adatokat.\n"
33	"%s email cím nem található a listán.\n"
34	"%s, a lista tulajdonosa törölt\n\
a listáról.\n\n\
Általában a nem megfelelõen mûködõ címeket távolítja el ilyenkor a\n\
tulajdonos. Ha a címed mégis megfelelõen mûködik, akkor elnézésedet\n\
kérjük, feliratkozásod kérlek újítsd meg.\n"
35	"Az üzenet külön levélben kerül elküldésre.\n"
36	"%s felhasználó adatai a(z) %s listán frissítve lettek.\n"
37	"%s felhasználó mostmár tagja a(z) %s listának.\n"
38	"%s felhasználó a(z) %s listáról törölve lett/\n"
39	"Valaki (remélhetõleg te) a(z) %s listára egy felhasználót akar\n\
felvenni vagy arról törölni.\n\n\
A parancs végrehajtásához a(z) %s címre, kell\n\
kell elküldeni a következõt:\n\n\
   %s\n\n\
Ha a parancsot nem akarod végrehajtani, akkor töröld ezt a levelet.\n"
40	"%s listán a beállításaid frissítve lettek.\n"
41	"A(z) %s listán a(z) %s jelzésû moderált levél nem lehet elérni.\n\
A levélrõl valószínûleg az egyik moderátor már gondoskodott.\n"
43	"A(z) %s levelet a(z) %s listán visszautasították.\n"
44	"A(z) %s levet engedélyezték a(z) %s listán megjelenésre.\n"
45	"%s listán nincs DIGEST mód. Ez a beállítasod figyelmen kívül lett hagyva.\n"
46	"A MODINDEX parancsot csak a moderátorok használhatják.\n\
Te nem vagy a(z) %s lista moderátorai között.\n"
47	"Az EXPIRE, EXPIREINDEX es EXPIREDEL parancsokat csakis a lista tulajdonosai használhatják.\n\
Te nem vagy a(z) %s lista tulajdonosai között.\n"
48	"\
Valaki (remélhetõleg te) a(z) '%s' lista azon tagjait, akik már legalább\n\
%d napja tagok, arra kérted, hogy erõsítsék meg listatagságukat. Ha végre\n\
akarod hajtani a parancsot, akkor a(z) '%s' címre küld el a következõt:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Az EXPIRE parancs a(z) %s listán jelenleg fut\n\
a(z) %s (%s) tulajdonos kérésére.\n\
Adott listán egyszerre csak egy 'expire' -t lehet megadni.\n\
A jelenleg futó parancs a tagok tagságának %d napon belüli megerõsítését\n\
írja elõ. A megerõsítési határidõ %d nap (%s) múlva letelik.\n"
52	"%s listára nem érkezett meg a megerõsítés a következõ címekrõl:\n"
53	"A megerõsítési felszólítást a következõ paranccsal lehet törölni: EXPIREDEL %s\n"
54	"A(z) %s listán nincs folyamatban megerõsítési felszólítás.\n"
55	"A megerõsítési felszólítást a(z) %s listáról törölted.\n"
56	"\
Megerõsítési felszólítás lett a(z) %s listára elküldve. A felszólítás\n\
még %d napig érvényes. A határidõ után értesítve leszel azon tagokról,\n\
akik nem erõsítették meg tagságukat.\n\
Ezeket a tagokat a DEL paranccsal törölheted a listáról.\n"
57	"A megerõsítési felszólításra nem válaszoló listatagokat a következõ\n\
paranccsal tekintheted meg: EXPIREINDEX %s\n"
58	"A felsorolt tagokat a listáról a következõ paranccsal törölheted:\n"
60	"\
Az EXPIRE parancsot nem lehet futtatni. A parancs után meg kell adni az\n\
érintett tagoknak a felszólítás indokát.\n\
A indoklás szövegének\n\n\
 - az EXPIRE utáni sorban kell kezdõdnie,\n\
 - minimum 20 szóból kell állnia és\n\
 - a QUIT szó megadásával kell befejezõdnie.\n"
61	"Ezért az üzenetedet visszaküldtük:\n"
67	"Jelenleg a következõ listáknak vagy tagja:\n\n"
68	"A(z) %s kulccsal azonosított üzenetet nem lehet elérni.\n"
69	"%s a megerõsítési üzenetedet a következõ címre küldte el:\n"
70	"\nSympa levelezõlista-kezelõ%s : http://listes.cru.fr/sympa/\n"
71	"Leiratkozás a(z) %s listáról"
72	"\n\nAz következõ listák tulajdonosa vagy:\n\n"
73	"\n\nAz következõ listák szerkesztõje vagy:\n\n"
74	"%s -nek azonosítani kell magát az %s parancs végrehajtásához\n"
75	"Engedélyezve, hogy bármely listáról %s leiratkozhasson \n"
76	"Emlékeztetõ %s listatagságodról"
77	"%s listán %s email címmel vagy nyilvántartva\n"
78	"Listatagsági emlékeztetõ elküldése minden %d %s tagnak\n"
79	"Listagsági emlékeztetõ elküldését kérvényezted a(z) %s lista\n\
minden tagjának.\n\n\
A parancs megerõsítéséhez %s címre küldj egy levelet \n\
a következõ tartalommali:\n\n\
   %s\n\n\
Ha nem akarod a parancsot megerõsíteni, akkor hagyd figyelmen kívül azt a levelet.\n"
80	"A(z) %s parancsot nem futtathatod a(z) %s listán.\n"
81	"Felhasználói útmutató"
82	"Nyilvános listák"
83	"Feliratkozási összesítés"
84	"'%s' felhasználó már tagja a(z) '%s' listának\n"
85	"%s felhasználó feliratkozhat a(z) %s listára.\n"
86	"%s felhasználó nem iratkozhat fel a(z) %s listára.\n"
90	"A(z) %s listán csak a következõ levélfogadási módok használhatóak: %s\n\
Beállításaid nem változtak meg.\n"
91	"%s levelezõlistán a tagok nem rendelkezhetnek egyéni beállításokkal"
92	"Nem sikerült módosítani a beállításaidat a(z) %s listán."
260	"Valaki (remélhetõleg te) az email címeddel szeretne  a(z) '%s'\n\
listára feliratkozni.\n\
Ha a feliratkozást meg akarod erõsíteni, akkor\n\
\n\
 - válaszolj erre a levélre, \nVAGY\n\
 - küldj egy levelet %s tárggyal a(z) %s címre, \nVAGY\n\
 - a(z) %s címre válaszolj.\n\
 \n\
Ha nem akarod feliratkozásodat megerõsíteni, akkor hagyd figyelmen\n\
kívül ezt a levelet.\n"
261	"Valaki (remélhetõleg te) az email címeddel le akar iratkozni\n\
a(z) '%s' listáról.\n\
Ha a leiratkozást meg akarod erõsíteni, akkor\n\
 - válaszolj erre a levélre, \nVAGY\n\
 - küldj egy levelet %s tárggyal a(z) %s címre, \nVAGY\n\
 - a(z) % címre válaszolja.\n\n\
\
Leiratkozni a(z) %s címen is lehet.\n\
Ha nem akarod leiratkozásodat megerõsíteni, akkor hagyd figyelmen\n\
kívül ezt a levelet."
262	"A levélben található aláírásod S/MIME kódolással sikeresen azonosítva"
263	"A leveled nem többrészes/aláírt formátumú vagy a Sympa nem tudja\nazonosítani az aláírásodat (a Sympa nem tudja az aláírást ellenõrizni, ha a levél tárgy mezõjében parancsok vannak megadva)."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"a(z) %s lista tulajdonosai"
2	"Feliratkozási kérelem a(z) %s listára"
3	"Tisztelt %s lista tulajdonosa!\n\n\
Egy felhasználó a lista tagja szeretne lenne. A feliratkozás\n\
engedélyezéséhez használd a következõ parancsot:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
6	"Üdvözlünk a(z) %s listán"
7	"Állomány"
9	"Digest a(z) %s listán"
12	"A(z) %s listán a melléklet megjelenésének jóváhagyásához használd a következõt:\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Vagy %s címre küldj egy levelet a következõ tárggyal:\n\
CONFIRM %s\n"
13	"Tartalomjegyzék" 
14	"Digest vége a(z) %s listán"
16	"Azonosítás szükséges"
21	"BIZ: %s lista %s feladó %s %s"
22	"BIZ: %s parancs a(z) %s listán %s %s felhasználótól \n (nincs teendõ)\n"
23	"FIGYELMEZTETÉS: %s %s nem tud leiratkozni, mert a címe nem található\n\
a(z) %s listán\n (Segítened kell neki).\n"
24	"LEiratkozási kérelem a(z) %s listán"
25	"Tisztelt %s lista tulajdonos!\n\n\
Egy felhasználó le szeretne iratkozni a listáról. A leiratkozás\n\
engedélyezéséhez használd a következõ parancsot:\n\n\
DEL %s %s\n"
26	"BIZ: %s parancs a(z) %s listán %s %s felhasználótól, jóváhagyta: %s\n (nincs teendõ)\n"
27	"A(z) %s listán a visszapattanási arány %d%%.\n\n\
Érdemes törölni a továbbküldõ tagokat: \n\
%s/reviewbouncing/%s"
28	"FIGYELMEZTETÉS: a visszapattanási túl magas a(z) %s listán"
29	"Felkérés a(z) %s listára való feliratkozásra"
30	"Felkértek, hogy legyél a(z) %s lista tagja"
31	"Kivonat a(z) %s listáról"

$set 11	Messages used by the smtp module.
1	"A rendszer nem felel meg a POSIX P1003.1 szabványnak, vagy\n\
a Perl rendszer POSIX könyvtárában nincs megadva a _SC_ARG_MAX konstans.\n\
Az $max_arg változó beállításához az smtp.pm modult módosítani kell.\n"
2	"Nem lehet az smtptp -hoz kapcsolódni: %m"

$set 12 MIME headers
1	"1.0"
2	"iso-8859-2"
3	"8bit"
4	"SYMPA <%s>"

$set 14 Pour le web
1	"hu_HU"
2	"magyar"

$set 15 Templates files
1	"üdvözlõ szöveg"
2	"értesítés leiratkozásról"
3	"értesítés törlésrõl"
4	"üzenet lábléce"
5	"üzenet fejléce"
6	"emlékeztetõ"
7	"szerkesztõ visszautasításának szövege"
8	"felkérõ szöveg"
9	"súgó"
10	"listák könyvtárai"
11	"általános emlékeztetõ"
12	"összefoglaló szöveg"
13	"lista leírása"
14	"lista honlap"

$set 16 Listm parameters titles
1	"Azonosító"
2	"Ki vehet fel tagokat"
3	"Névtelen beküldõ"
4	"Szöveges archívumok"
5	"Gyakoriság"
6	"Hozzáférési jogosultságok"
7	"Visszadobások kezelése"
8	"Figyelmeztetési szint"
9	"Leállítási szint"
10	"El nem bírált levelek érvényességének ideje"
11	"Titkos karaktersorozat egyéni kulcsok készítéséhez"
12	"Lista létrehozása"
16	"Egyéni fejléc mezõ"
17	"Tárgy jelölése"
18	"Feliratkozási értékek"
19	"Levélkézbesítési mód"
20	"nyilvánosság"
21	"Ki törölheti a tagokat"
22	"Digest gyakoriság"
23	"Nap"
24	"Óra"
25	"Perc"
26	"Moderátorok"
27	"Email cím"
28	"Levélkézbesítés"
29	"Név"
30	"Személyes adat"
31	"Melléklet típusa"
32	"Beállított válasz cím"
33	"Internet tartomány"
34	"Engedélyezett állományok"
35	"LDAP lekérdezési lehetõség"
36	"Távoli gép"
37	"Távoli portszám"
38	"Távoli felhasználó"
39	"Távoli jelszó"
40	"Utótag"
41	"Szûrõ"
42	"jellemzõ attribútumok"
43	"kijelölés (ha többszörös)"
44	"Engedélyezett listák"
45	"SQL lekérdezési lehetõség"
46	"Adatbázis típusa"
47	"Távoli gép"
48	"Adatbázis neve"
49	"Távoli felhasználó"
50	"Távoli jelszó"
51	"SQL lekérdezés"
53	"Ki tekintheti meg a lista információt"
54	"Ki hívhat meg embereket"
55	"A lista nyelve"
56	"Maximális levélméret"
57	"Tulajdonos"
58	"Email cím"
59	"Levélkézbesítés"
60	"Név"
61	"Személyes adatok"
62	"Profil"
63	"Prioritás"
64	"Ki kezdeményezheti emlékeztetõ elküldését"
65	"Emlékeztetõ válasz cím"
66	"Válasz cím"
67	"Ki ellenõrizheti a tagok listáját"
68	"Ki küldhet levelet"
69	"A beállítás sorozatszáma"
70	"Megosztott dokumentumok"
71	"A lista állapota"
72	"A lista tématerülete"
73	"Ki iratkozhat fel a listára"
74	"Lista témái"
75	"Várakozási idõ"
76	"Ki iratkozhat le"
77	"Beállítások utolsó frissítésének ideje"
81	"Felhasználók adatainak helye"
82	"A lista nyilvánossága"
83	"Web archívum"
84	"hozzáférési jogosultságok"
85	"Válasz cím üdvözlésnél"
86	"Ki tekintheti meg"
87	"Ki szerkesztheti"
88	"Felhasználható tagsági beállítások"
89	"levélkézbesítés"
90	"Válsz cím"
91	"érték"
92	"más email cím"
93	"létezõ fejléc figyelembevéve"

$set 17 Cookie expiration periods
1	"a folyamat bezárásakor"
2	"10 perc múlva"
3	"30 perc múlva"
4	"1 óra múlva"
5	"6 óra múlva"
6	"1 nap múlva"
7	"1 hét múlva"

