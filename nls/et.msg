$ Aug 2001, Initial version by Lauri Jesmin, jesmin@ut.ee
$ Mar 2002, updated to 3.3.4b3 by Lauri Jesmin, jesmin@ut.ee

$ codeset=iso-8859-15
$quote "

$set 1	Konfiguratsioonifaili töötlemise ajal kasutatavad teated
1	"Seadete fail sisaldab vigu.\n"
3	"Viga real %d : %s"
102	"3.3a"

$set 2	Teated, mida kasutab Conf failide kontrollimisel

$set 3	Erinevad teated peamises programmis
1	"Kataloogi %s kasutamine on takistatud: %m"

$set 4	Peamises korduses kasutatud teated
11	"Sinu kirja saatmisest aadressile %s keelduti"
12	"Sinu kirja ei saanud saata, kuna see oli suurem \n\
kui maksimaalne kirja suurus selles listis.\n"
15	"Sinu kirja saatmisest listi % keelduti.\n\
Seetõttu saadan kirja sulle tagasi.\n\n\
Sinu kiri: \n"
17	"Tulemused sinu käskudest"
18	"Leitud käsk 'quit': ignoreerin kirja lõppu.\n"
19	"Käsku ei mõistetud: ignoreerin kirja lõppu.\n"
24	"Lõppes käsk EXPIRE sinu listil %s"
26	"Lugejad on :\n"
27	"Kui soovid neid lugejaid eemaldada, kasuta järgnevaid käske :\n"
28	"Listi %s lugejatest ei uuendanud %d päeva jooksul ei kinnitanud %d oma soovi.\n"
37	"Ignoreerin kirja sisu, kuna see ei ole text/plain.\n Kui te ei saa kirja saata tekstivormis, pange oma käsk kirja subject reale.\n"
38	"Sinu kiri listi %s saadeti edasi listi toimetaja(te)le\n"
39	"Kirjast ei leitud ühtegi käsku"
40	"Modereerin sinu kirja"

$set 5	Teated, mida kasutatakse tööriistade moodulis
1	"Safefork ei saa hakkama uue protsessi loomisega : %m"
2	"Viga marsruutimisel ?"
3	"Järgnevat kirja ei saadetud listi, kuna tundus et ta sisaldas käske \n\
listserverile, nagu subscribe, unsubscibe, help, index, get vms.\n\n\
Kui see tõepoolest oli nii, siis saatke edaspidi käsud aadressile %s, \n\n\
see on robot mis käske töötleb.\n\n\
Kui see kiri tõepoolest oli mõeldud listi saatmiseks, siis tegelikult\n\n\
töödelti teie kirja kui käsklusi tarkvarale. Palun võtke ühendust teenuse \n\n\
haldajaga (%s), siis võib teie kiri ikkagi kohale jõuda. \n\n\
---- Kahtlase teate algus ---- \n"
4	"---- Kahtlase teate lõpp ----\n"

$set 6	Mooduli Commands.pm teated
2	"Ei saa hakkama abifaili lugemisega : %s\n"
3	"Listis %s ei ole lugejaid.\n"
5	"Listi '%s' ei ole olemas.\n"
7	"Selle listi arhiivides pole ühtegi faili.\n"
8	"Nõutud faili ei ole olemas.\n"
9	"List on privaatne : Sa ei saa lugeda arhiivi.\n"
10	"List on privaatne : Sa ei saa vaadata saadavaid faile.\n"
11	"List is privaatne : Sa ei saa vaadata listi lugejaid.\n"
13	"Käsu süntaks on vigane.\n"
15	"Autentimine ei õnnestunud\n\n"
16	"Ilmselt proovisite kinnitada listi liikmeks saamise soovi erinevalt\n\
e-posti aadressilt. Proovige kasutada sama aadressi, mis soovis oli."
18	"Teid eemaldati listi %s lugejate hulgast."
21	"Uuendati teie liikmestaatust listis '%s'"
24	"Sellesse listi liikmete lisamine on hetkel peatatud.\n"
25	"Teie liitumise/lahkumise soov saadeti edasi listi omanikule kinnitamiseks\n\
Peale kinnituse saamist teavitatakse teid listiga liitumisest või listist\n\
lahkumisest.\n"
26	"Listist %s lahkumine ei ole võimalik.\n"
27	"Uuendati informatsiooni teie liikmestaatuse kohta.\n"
28	"Olete nüüd listi %s liige.\n"
29	"Informatsioon listi kohta saadetakse eraldi kirjas.\n"
30	"Teie e-postiaadressi ei leitud listist %s. Võibolla seadsite end listi\n\
liikmeks mõnelt teiselt e-posti aadressilt ?\n"
31	"Teid eemaldati listist %s.\n\
Täname teid.\n"
32	"Ainult listi %s omanikud võivad listi liikmeid lisada/eemaldada.\n\
Teil ei ole seda käsku kasutada lubatud või ei lisanud te käsuga kaasa \n\
teie identifitseerimiseks vajalikku informatsiooni.\n"
33	"E-posti aadressi %s ei leitud listist.\n"
34	"Teid eemaldas listist %s, listi omanik.\n\
Harilikult on selline teguviis tingitud sellest, et teie aadress põhjustab\n\
veateateid. Teie aadress võib siiski korrektselt töötada. Kui töötab, siis\n\
palun vabandage meid probleemide pärast ning uuendage oma liikmestaatust.\n"
35	"Arhiiv saadetakse teile eraldi kirjas.\n"
36	"Uuendati kasutaja %s informatsiooni listis %s.\n"
37	"Kasutaja %s on nüüd listi %s liige.\n"
38	"Kasutaja %s eemaldati listist %s/\n"
39	"Keegi (loodetavasti teie) soovis listi %s kasutaja \n\
lisamist või eemaldamist.\n\n\
Kui soovite, et see saaks tehtud, saatke aadressile %s\n\
kiri, mis sisaldab \n\n\
   %s\n\n\
Kui te ei soovi, et midagi ette võetaks, lihtsalt ignoreerige seda teadet.\n"
40	"Uuendati teie seadeid listis %s.\n"
41	"Listi %s saadetud kirjale ei ole võimalik juurde pääseda võtmega %s.\n\
Mõni listi moderaatoritest võib selle kirja juba listi saatnud olla\n.\n"
43	"Kiri %s listi %s lükati tagasi.\n"
44	"Kiri %s saadeti laiali listi %s.\n"
45	"List %s ei aktsepteeri DIGEST moodi. Sinu seadeid ei uuendatud seoses selle käsuga.\n"
46	"MODINDEX on lubatud ainult listi moderaatoritele.\n\
Teie ei ole listi %s moderaator.\n"
47	"Käsud EXPIRE, EXPIREINDEX ja EXPIREDEL on lubatud ainult listiomanikele.\n\
Teie ei ole listi %s omanik.\n"
48      "\
Keegi (loodetavasti teie) nõudis, et listi %s liikmed kes on listid olnud \n\
rohkem kui %d päeva, uuendaksid oma liikmestaatust .\n\
Kui te ei soovi seda tegevust sooritada, lihtsalt ignoreerige seda teadet.\n\
Et see tegevus sooritada, saatke aadressile %s selline käsk:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"

49      "\
Üks EXPIRE käsk on parasjagu rakendatud listile %s.\n\
Selle käsu käivitas omanik  %s (%s)\n\
Ühele listile ei saa korraga olla rohkem kui 1 EXPIRE käsk korraga töötamas.\n\
Käesolev EXPIRE käsk nõuab, et oma liikmestaatust uuendaksid need listi liikmed\n\
listi liikmed, kes on listis olnud enam kui %d päeva. EXPIRE käsu töö jõuab \n\
lõpule %d päeva jooksul (%s).\n"

52	"%s ei saanud kinnitust järgnevatele aadressidele :\n"
53	"Aegumisprotsessi peatamiseks saatke käsk:  EXPIREDEL %s\n"
54	"Listis %s ei tööta parasjagu EXPIRE käsk.\n"
55	"Peatasite EXPIRE käsu töö listil %s\n"
56      "\
Listil %s käivitati EXPIRE käsk . See käsk lõpetab oma töö\n\
%d päeva jooksul. Peale seda saate nimekirja aadressidest, kes ei uuendanud \n\
liikmestaatust vastava aja jooksul.\n\
Need aadressid saate eemaldada listist, kasutades DEL käsku.\n"
57	"Selleks, et lugeda aadresside nimekirja, kust ei ole uuendatud listi\n\
liikmestaatust kasutage käsku EXPIREINDEX %s\n"
58	"Te saate eemaldada need aadressid listist, kui kasutate järgnevaid käske :\n"
60      "\
Ei saanud käivitada EXPIRE käsku, kuna EXPIRE käsule peab järgnema selgitus\n\
nendele listi lugejatele, kes peavad uuendama oma liikmestaatust.\n\
See tekst peab:\n\n\
 * algama kohe järgmiselt realt peale EXPIRE käsku\n\
 * sisaldama vähemalt 20 sõna\n\
 * lõppema sõnaga QUIT.\n"
61	"Seega saadan kirja teile tagasi:\n"
67	"Hetkel olete nende listide liige:\n\n"
68	"Ei leia kirja, mille autentimisvõti on  %s.\n"
69	"%s saatis aegumisteated järgnevatele aadressidele:\n"
70	"\nSiin töötab Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Lahku listist %s"
72	"\n\nOled nende listide omanik:\n\n"
73	"\n\nOled nende listide toimetaja:\n\n"
74	"Kasutajalt %s nõutakse käsu %s täitmiseks enese autentimist\n"
75	"Luba kasutajal %s lahkuda suvalisest listist\n"
76	"Meeldetuletus listi %s liikmestaatusest"
77	"Olete listi %s liige e-posti aadressilt %s\n"
78	"Meeldetuletus saadeti kõikidele %d-le %s listi lugejale\n"
79      "Te soovisite, et listi %s kõidele lugejatele saadetaks meeldetuletus\n\
nende liikmestaatuse kohta.\n\n\
Kui soovite, et see tehtud saaks, saatke kiri aadressile %s\n\
sisuga \n\n\
   %s\n\n\
Kui soovite, et meeldetuletust ei saadetaks, ignoreerige seda kirja.\n"
80	"Teil ei ole lubatud kasutada käsku %s listil %s\n"
81	"Kasutajajuhend"
82	"Avalikud listid"
83	"Liikmestaatuse kokkuvõte"
84	"Kasutaja %s on juba listi %s liige\n"
85	"Kasutaja %s kutsuti liituma listiga %s.\n"
86	"Kasutajat %s ei soovita listi %s.\n"
90	"Listis %s on lubatud vaid need vastuvõtuviisid: %s\n\
Teie seadeid ei muudetud.\n"
91	"%s list ei paku liikmetele seadeid.\n"
92	"Ei saanud hakkama listilugejate seadete muutmisega listis %s.\n"
260     "Keegi (loodetavasti teie) soovis teid lisada listi %s.\n\
Kui soovite saada listi liikmeks, siis:\n\
\n\
* vastake sellele kirjale\nVÕI\n\
* saatke kiri aadressil %s teemareal tekstiga\n %s\nVÕI\n\
* klikkige siia viitele %s\n\
\n\
Kui te ei soovi saada selle listi liikmeks ei pea te midagi tegema\n"

261     "Keegi (loodetavasti teie ise) soovis, et teie e-posti aadress eemaldataks \n\
listist %s.\n\
Kui te tõepoolest soovite sellest listist lahkuda, siis: \n\
\n\
* vastake sellele kirjale\nVÕI\n\
* saatke kiri aadressile %s, kirja teemareale kirjutage:\n %s\nVÕI\n\
* klikkige urlile %s\n\n\
\
Samuti saate seda teha veebiaadressilt %s\n\
Kui te ei soovi listist lahkuda, võite rahulikult seda teadet ignoreerida.\n"
262	"Teie kirja S/MIME signatuur kontrolliti edukalt"
263 	"Teie kiri ei olnud saatetud multipart/signed vormigus või Sympa ei suutnud\n kontrollida signatuuri (Sympa ei saa kontrollida signatuuri kui käsk on\nsaadetud kirja teemareal)."

$set 7	Käskude syslog teated (Commands.pm)

$set 8	Teatead failist List.pm
1	"Listi %s omanikud"
2	"Listiga %s liitumise soov"
3       "Listi %s omanik,\n\n\
1 kasutaja soovis liituda teie listiga. Kui te nõustute sellega, klikkige \n\
järgnevale URLile:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n\n\
või saatke e-kiri aadressile %s ning kirja teemareale pange:\n\
AUTH %s ADD %s %s %s\n"
6	"Tere tulemast listi %s"
7	"Fail"
9	"Kokkuvõte listist %s"
REJECT %s %s\n"
12	"Selleks, et saata kaasa pandud kiri listi %s:\n\
mailto:%s?subject=CONFIRM%%20%s\n\
või saatke kiri aadressile %s järgneva teemareaga:\n\
CONFIRM %s\n"
13	"Sisukord" 
14	"Listi %s kokkvõtte lõpp"
16	"Nõutakse identifitseerimist"
21	"INFO: %s list %s aadressilt %s %s"
22	"INFO: käsk %s listis %s aadressilt %s %s \n (midagi ei pea tegema)\n"
23	"HOIATUS: %s %s ei saanud lahkuda listist %s kuna tema aadressi ei \n\
leitud sellest listist\n ( Te võite seda inimest aidata )\n"
24	"Lahkumissoov listist %s"
25	"Listi %s omanik,\n\n\
Teie listist paluti kustutada üks kasutaja. Kui te nõustute\n\
selle sooviga, klikkige järgneval URLil:\n\n\
mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s\n\n\
või saatke e-kiri aadressile %s järgneva teemareaga:\n\
AUTH %s DEL %s %s\n"
26	"INFO käsu %s listil %s aadressilt %s %s tunnistas kõlblikuks %s\n (kõik ok)\n"
27	"Vigade hulk listis %s on %d%%.\n\n\
Te peaks kustutama vigasid genereerivad kasutajad : \n\
%s/reviewbouncing/%s"
28	"HOIATUS: vigade arv on liiga suur listis %s"
29	"Kutse liitumaks listiga %s"
30	"Teid kutsuti listi %s"
31	"Listi %s kokkuvõte"

$set 11	Messages used by the smtp module.
1	"Your system does not conform to the POSIX P1003.1 standard, or\n\
your Perl system does not define the _SC_ARG_MAX constant in its POSIX\n\
library. You must modify the smtp.pm module in order to set a value\n\
for variable $max_arg.\n"
2	"Unable to create a channel in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"us-ascii"
3	"7bit"
4	"SYMPA <%s>"

$set 14 Pour le web
1	"et"
2	"estonian"

$set 15 Templates files
1	"tervituskiri"
2	"listist lahkumise kiri"
3	"kiri kustutamisest"
4	"kirja jalus"
5	"kirja päis"
6	"meeldetuletuskiri"
7	"kiri toimetaja keeldumisest"
8	"listi liitumisele kutsuv kiri"
9	"abifail"
10	"listide kataloog"
11	"globaalne meeldetuletuskiri"
12	"kokkuvõttev kiri"
13	"listi kirjeldus"
14	"listi koduleht"
15	"listi soovimise teade"
16	"listi tekitamisest teavitamise teade"
17	"viirusest teavitamise teade"

$set 16 Listm parameters titles
1	"Konto"
2	"Kes saab listi liikmeid lisada"
3	"Anonüümne saatja"
4	"Tekstipõhised arhiivid"
5	"sagedus"
6	"juurdepääsuõigus"
7	"Veateadete haldamine"
8	"hoiatamise häär"
9	"peatamise määr"
10	"Modereerimata teadete aegumine"
11	"Salajane sõne unikaalsete võtmete genereerimiseks"
12	"Listi loomine"
16	"Lisatav päiserida"
17	"Teemarea märgistamine"
18	"Listiga liitumise profiil"
19	"vastuvõtu viis"
20	"nähtavus"
21	"Kes võib kustutada listi lugejaiks soovijaid"
22	"Kokkuvõtte sagedus"
23	"päevi"
24	"tund"
25	"minut"
26	"Moderaatorid"
27	"e-posti aadress"
28	"vastuvõtu viis"
29	"nimi"
30	"isiklik informatsioon"
31	"Manuse tüüp"
32	"Pealesunnitud vastusaadress"
33	"Interneti domeeninimi"
34	"Failist lisamine"
35	"LDAP päringuga kasutajate lisamine"
36	"kaughost"
37	"kaugport"
38	"kaugkasutaja"
39	"kaugparool"
40	"eesliide"
41	"filter"
42	"eraldatud atribuut"
43	"valik (kui võimalik)"
44	"Listi kasutajate lisamine"
45	"SQL päringuga kasutajate lisamine"
46	"andmebaasi tüüp"
47	"kaughost"
48	"andmebaasi nimi"
49	"kaugkasutaja"
50	"kaugparool"
51	"SQL päring"
53	"Kes saab näha infot listi kohta"
54	"Kes võib inimesi listi kutsuda"
55	"Listi keel"
56	"Maksimaalne kirja suurus"
57	"Omanik"
58	"e-posti aadress"
59	"vastuvõtu viis"
60	"nimi"
61	"isiklik informatsioon"
62	"profiil"
63	"Prioriteet"
64	"Kes võib käivitada meeldetuletuse"
65	"Pea meeles tagasiaadress"
66	"Vastusaadress"
67	"Kes võib listi liikmeid vaadata"
68	"Kes võib kirju saata"
69	"Seadete järjekorranumber"
70	"Jagatud dokumendid"
71	"Listi staatus"
72	"Listi teema"
73	"Kes võib listiga liituda"
74	"Listi teemad"
75	"Lisamiste aegumine"
76	"Kes võib listist lahkuda"
77	"Seadete viimane uuendamine"
81	"Kasutajaandmete allikas"
82	"Kellele on list nähtav"
83	"Veebiarhiivid"
84	"juurdepääsu õigused"
85	"Tervitusteksti vastusaadress"
86	"Kes saab vaadata"
87	"Kes saab toimetada"
88	"Võimalikud listiga liitumise variandid"
89	"vastuvõtu viis"
90	"Vastusaadress"
91	"väärtus"
92	"teine e-posti aadress"
93	"usutakse olemasolevat päiserida"
94	"ühenduse seaded"
97	"otsingu skoop"
98	"ühenduse aegumine"
135	"LDAPi 2-tasemelise päringu lisamine"
136	"arvuti nimi"
137	"port"
138	"kasutajanimi"
139	"parool"
140	"first-level suffix"
141	"first-level filter"
142	"first-level extracted attribute"
143	"first-level selection"
144	"second-level suffix template"
145	"second-level filter template"
146	"second-level extracted attribute"
147	"second-level selection"
148	"environment variables for database connexion"
197	"first-level search scope"
198	"first-level connection timeout"
199	"second-level search scope"
200	"second-level connection timeout"
201	"first-level regular expression"
202	"second-level regular expression"


$set 17 Küpsiste aegumisperioodid
1	"sessioon"
2	"10 minutit"
3	"30 minutit"
4	"1 tund"
5	"6 tundi"
6	"1 päev"
7	"1 nädal"

