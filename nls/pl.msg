$ Jan 2001, Initial version by Chopin

$ codeset=iso-8859-2
$quote "

$set 1	Messages used while processing the configuration file
1	"Plik konfiguracyjny zawiera b³êdy.\n"
3	"B³±d w linii %d : %s"
102	"2.8.1"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Brak dostêpu do katalogu %s : %m"

$set 4	Messages used in the main loop
11	"Twoja wiadomo¶æ do %s zosta³a odrzucona"
12	"Twoja wiadomo¶æ nie zosta³a przes³ana, poniewa¿ jej rozmiar \n\
przekracza dozwolony limit na tej li¶cie.\n"
15	"Twoja wiadomo¶æ wys³ana na %s zosta³a odrzucona.\n\
Zostaje wiêc zwrócona do nadawcy.\n\n\
Twoja wiadomo¶æ :\n"
17	"Wyniki wydanych poleceñ"
18	"Polecenie 'quit' znalezione : nie przetwarzam koñca wiadomo¶ci.\n"
19	"Polecenie nie zrozumiane: ignoruje koniec wiadomo¶ci.\n"
24	"Koniec twojego polecenia EXPIRE na li¶cie %s"
26	"Zapisane osoby :\n"
27	"Je¿eli chesz usun±æ wymienione adresy z listy, u¿yj poleceñ:\n"
28	"Wymienione adresy zapisane na listê %s od %d dni, %d nie potwierdzi³y udia³u w li¶cie.\n"
37	"Ignorujê tre¶æ wiadomo¶ci poniewa¿ jej zawarto¶æ to nie text/plain, proszê u¿ywaæ tylko zawarto¶ci typu text/plain\n(lub umie¶æ polecenie w temacie wiadomo¶ci).\n"
38	" wiadomo¶æ wys³ana na listê %s zosta³a przekazana osobie administruj±cej.\n"
39	"Brak poleceñ w tre¶ci wiadomo¶ci"
40	"Moderujê twoj± wiadomo¶æ"

$set 5	Messages used in the tools module
1	"Safefork nie móg³ uruchomiæ nowego procesu : %m"
2	"B³±d routingu ?"
3	"Poni¿sza wiadomo¶æ zosta³a przes³ana na listê. Zawiera ona jednak\n\
polecenia takie jak subscribe, unsubscribe, help, index, get, ...\n\n\
Proszê mieæ na uwadze to, ¿e polecenia serwera nie powinny nigdy byæ \n\
wysy³ane na listê. W celu wydania serwerowi polecenia prosimy wysy³aæ \n\
listy na adres %s.\n\n\
Je¿eli twoja wiadomo¶æ by³a poprawnie adresowana do listy a zosta³a \n\
zinterpretowana przez oprogramowanie jako polecenie, proszê powiadomiæ \n\
o tym osobê administruj±c± po adresem: %s \n\n\
------ Pocz±tek podejrzanej wiadomo¶ci ------\n"
4	"------ Koniec podejrzanej wiadomo¶ci ------\n"

$set 6	Messages du module Commands.pm
2	"Nie mogê odczytaæ pliku pomocy : %s\n"
5	"Lista '%s' nie istnieje.\n"
7	"Archiwum tej listy nie zawiera ¿adnych plików.\n"
8	"Wymagany plik nie istnieje.\n"
9	"Lista prywatna : Nie mo¿esz odczytywaæ jej archiwów.\n"
10	"Lista prywatna : Nie mo¿esz przegl±daæ dostêpnych plików s.\n"
11	"Lista priwatna : Nie mo¿esz przegl±daæ listy zapisanych.\n"
13	"B³±d sk³adni polecenia.\n"
15	"B³±d procesu autentyfikacji\n\n"
16	"Prawdopodobnie potwierdzi³e¶ swój udzia³ w li¶cie u¿ywaj±c innego adresu\n\
Proszê u¿yæ swojego kanonicznego adresu."
18	"Zosta³e¶ wypisany z listy %s."
21	"Odnowi³em zapisanie na listê '%s'"
24	"Zapisanie na listê jest obecnie zawieszone.\n"
25	"Twoja pro¶ba o zapisanie/wypisanie z listy zosta³a przes³ana do osoby administruj±cej\n\
w celu zatwierdzenia. Zapisanie/wypisanie zostanie potwierdzone oddzielnym listem.\n"
26	"Wypisanie z listy %s jest nie mo¿liwe.\n"
27	"Informacje dotycz±ce twojego zapisania zosta³y uaktualnione.\n"
28	"Jeste¶ obecnie zapisany na listê %s.\n"
29	"Informacje o tej li¶cie zostan± przes³ane w oddzielnej wiadomo¶ci.\n"
30	"Twój adres email nie zosta³ znaleziony na li¶cie %s. Mo¿e\n\
zapisa³e¶ siê na ni± z innego adresu ?\n"
31	"Zosta³e¶ wypisany z %s.\n\
Dziêkujemy za udzia³ w li¶cie.\n"
32	"Tylko osoby administruj±ce list± %s mog± zapisywaæ/wypisywaæ z listy.\n\
Nie mo¿esz u¿ywaæ tej komendy lub nie dostarczy³e¶ informacji niezbêdynch do identyfikacji.\n"
33	"Adres email %s nie zosta³ znaleziony na li¶cie.\n"
34	"Zosta³e¶ wypisany z listy\n\
przez %s, osobê ni± administruj±c±.\n\n\
Takie dzia³anie ma na celu wypisanie adresów nie poprawnie dzia³aj±cych.\n\
Je¿eli twój adres dzia³a i jest poprawnie obs³ugiwany prosimy ponowiæ zapisanie.\n"
35	"To archiwum zostanie przes³ane w oddzielnej wiadomo¶ci.\n"
36	"Informacje o u¿ytkowniku %s zosta³y uaktualnione na li¶cie %s.\n"
37	"U¿ytkownik %s jest teraz zapisany na listê %s.\n"
38	"U¿ytkownik %s zosta³ wypisany z listy %s.\n"
39	"Kto¶ (miejmy nadziejê, ¿e ty) wys³a³ polecenie zapisania/wypisania na listê %s\n\
W celu potwierdzenia tej akcji wy¶lij email na adres %s w tre¶ci umie¶æ\n\n\
%s\n\n\
   %s\n\n\
W celu zaniechania akcji zignoruj t± wiadomo¶æ.\n"
40	"Twoje ustawienia na li¶cie %s zosta³y uaktualnione.\n"
41	"Nie mogê otworzyæ moderowanej wiadomo¶ci na li¶cie %s u¿y³em klucza %s.\n\
Ta wiadomo¶æ mog³a zostaæ ju¿ wys³ana przez jednego z moderatorów listy\n.\n"
43	"Wiadomo¶æ %s wys³ana na listê %s zosta³a odrzucona.\n"
44	"Wiadomo¶æ %s wys³ana na listê %s zosta³a rozes³ana.\n"
45	"Lista %s nie akceptuje trybu DIGEST. Twoje ustawienia nie zosta³y uaktualnione.\n"
46	"Polecenie MODINDEX jest zarezerwowane dla moderatorów.\n\
Nie jeste¶ moderatorem listy %s.\n"
47	"Polecenia EXPIRE, EXPIREINDEX i EXPIREDEL s± zarezerwowane dla w³a¶cicieli listy.\n\
Nie jeste¶ w³a¶cicielem listy %s.\n"
48	"\
Kto¶ (miejmy nadziejê, ¿e ty) wyda³ polecenie potwierdzenia zapisania na listê\n\
'%s' osobom bêd±cym na niej d³u¿ej ni¿ %d.\n\
Je¿eli nie chcesz potwierdziæ tego polecenia zignoruj t± wiadomo¶æ.\n\
¯eby potwierdziæ jego wykonanie, wy¶lij email na '%s' zawieraj±cy polecenie:\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Polecenie EXPIRE jest obecnie aktywne na li¶cie %s.\n\
Zosta³o uruchomione przez %s (%s)\n\
Dla jednej listy nie mo¿e byæ wiêcej takich poleceñ dzia³aj±cych równocze¶nie.\n\
Obecnie dzia³aj±ce 'expire' dotyczy osób zapisanych wiêcej ni¿ %d dni temu\n\
którzy nie potwierdzili swojego zapisania. Ich automatyczne wypisanie nast±pi\n\
za %d dni (%s).\n"
52	"%s nie otrzyma³ potwierdzenia dla poni¿szego adresu :\n"
53	"¯eby zatrzymaæ proces 'expire' : EXPIREDEL %s\n"
54	"Lista %s nie ma obecnie uruchomionego procesu 'expire'.\n"
55	"W³a¶nie zatrzyma³e¶ proces 'expire' dla listy %s\n"
56	"\
Proces wyga¶niêcia zapisania - 'expire' zosta³ uruchomiony dla listy %s\n\
Zakoñczy siê on za %d dni. Otrzymasz wtedy listê zapisanych osób \n\
które nie potwierdzi³y chêci pozostania na niej w zadanym czasie.\n\
Bêdziesz wtedy móg³ usun±æ te adresy rêcznie wydaj±c polecenie DEL.\n"
57	"Aby odczytaæ listê zapisanych osób które nie potwierdzi³y zapisania \n\
wydaj polecenie : EXPIREINDEX %s\n"
58	"Mo¿esz usun±æ te osoby przy pomocy nastêpuj±cych poleceñ :\n"
60	"\
Polecenie EXPIRE nie mo¿e zostaæ uruchomione. Musi ono zawieraæ tekst\n\
skierowany do osób które musz± potwierdziæ swoje zapisanie.\n\
Teks ten musi\n\
 - zaczynaæ siê od pierwszej linii po poleceniu EXPIRE,\n\
 - zawieraæ co najmniej 20 s³ów,\n\
 - koñczyæ siê s³owem QUIT.\n"
61	"Wiadomo¶c zostaje odes³ana spowrotem :\n"
67	"Oto listy na które jeste¶ obecnie zapisany/a :\n\n"
68	"Brak dostêpu do wiadomo¶ci identyfikowanej kluczem %s.\n"
69	"%s wys³a³ powiadomienie o wyga¶niêciu zapisania na adresy :\n"
70	"\nObs³ugiwane przez Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Wypisanie z listy %s"
72	"\n\nListy których jeste¶ w³a¶cicielem:\n\n"
73	"\n\nListy których jeste¶ edytorem :\n\n"
74	"Wymagana autoryzacja %s dla komendy %s\n"
75	"Jest mo¿liwo¶æ wypisania %s z ka¿dej listy \n"
76	"Przypomnienie o twoim %s zapisaniu"
77	"Jeste¶ zapisany na listê %s z adresem email %s\n"
78	"Przypomnienie o zapisaniu dla %d adresów z listy %s zosta³o wys³ane\n"
79	"Wyda³e¶ polecenie wys³ania przypomnienia o zapisaniu\n\
do ka¿dego z zapisanych na listê %s adresów\n\n\
W celu potwierdzenia jego wykonania, proszê przes³aæ email do\n\
%s zawieraj±cy \n\n\
   %s\n\n\
W celu zaniechania proszê zignorowaæ t± wiadomo¶æ.\n"
80	"Nie jeste¶ upowa¿niony do wydawania polecenia %s na li¶cie %s\n"
81	"Instrukcja obs³ugi"
82	"Listy publiczne"
83	"Podsumowanie zapisania"
84	"U¿ytkownik '%s' jest ju¿ zapisany na listê '%s'\n"
85	"U¿ytkownik %s zosta³ zaproszony do zapisania na listê %s.\n"
86	"U¿ytkownik %s jest nie chciany na li¶cie %s.\n"
260	"Kto¶ (miejmy nadziejê, ¿e ty) poprosi³ o dodanie swojego adresu email \n\
do listy '%s'.\n\
W celu potwierdzenia proszê:\n\
\n\
- odpowiedzieæ na ten list\nOR\n\
- wys³aæ wiadomo¶æ do %s z tematem\n %s\nOR\n\
- klikn±c na %s\n\
\n\
W celu zaniechania proszê zignorowaæ ten list."
261	"Kto¶ (miejmy nadziejê, ¿e ty) poprosi³ o usuniêcie swojego adresu email \n\
z listy '%s'.\n\
W celu potwierdzenia proszê:\n\
\n\
- odpowiedzieæ na ten list\nOR\n\
- wys³aæ wiadomo¶æ do %s z tematem\n %s\nOR\n\
- klikn±c na %s\n\
\
Mo¿na to równie¿ zrobiæ za pomoc± adresu WWW %s\n\
W celu zaniechania proszê zignorowaæ ten list."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Administracja listy %s"
2	"Pro¶ba o zapisanie na listê %s"
3	"Drogi administratorze listy %s,\n\n\
U¿ytkownik poprosi³ o zapisanie na listê. Je¿eli wyra¿asz na to zgodê\n\
wydaj polecenie:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
6	"Witaj na li¶cie %s"
7	"Plik"
9	"Digest dla listy %s"
12	"Aby rozes³aæ za³±czon± wiadomo¶æ na listê %s:\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Lub wy¶lij wiadomo¶æ do %s z tematem :\n\
CONFIRM %s\n"
13	"Zawarto¶æ" 
14	"Koniec digestu dla listy %s"
16	"Pro¶ba autoryzacj"
21	"FYI: %s lista %s od %s %s"
22	"FYI polecenie %s lista %s od %s %s \n (nie wymaga dzia³ania)\n"
23	"UWAGA : %s %s nie powiod³o siê wypisanie z %s poniewa¿ jego adres nie zosta³\n\
znaleziony na li¶cie\n (Mo¿esz pomóc tej osobie)\n"
24	"Polecenie wypisania z listy %s"
25	"Drogi administratorze listy %s,\n\n\
U¿ytkownik poprosi³ o wypisanie z listy. Je¿eli wyra¿asz na to zgodê\n\
wydaj polecenie:\n\n\
DEL %s %s\n"
26	"FYI polecenie %s listy %s od %s %s potwierdzone przez %s\n (nie wymaga dzia³ania)\n"
27	"Limit odbiæ listów na li¶cie %s wynosi %d%%.\n\n\
Powiniene¶ usun±æ adresy odbijaj±ce listy : \n\
%s/reviewbouncing/%s"
28	"UWAGA: limit odbiæ listów jest zbyt wysoki na li¶cie %s"
29	"Zaproszenie do zapisania na listê %s"
30	"Zosta³e¶ zaproszony do zapisana siê na listê %s"

$set 11	Messages used by the smtp module.
1	"Twój system nie jest zgodny ze standardem POSIX P1003.1 lub\n\
twój Perl nie ustawia sta³ej _SC_ARG_MAX w swojej bibliotece POSIX\n\
Musisz poprawiæ modu³ smtp.pm aby ustawiæ t± warto¶æ\n\
dla zmiennej $max_arg.\n"
2	"Nie mogê stworzyæ kana³u w smtptp: %m"

$set 12 MIME headers
1	"1.0"
2	"iso-8859-2"
3	"8bit"
4	"SYMPA <%s>"

$set 14 Pour le web
1	"pl_PL"
2	"polish"

$set 15 Templates files
1	"Wiadomo¶æ powitalna"
2	"Wiadomo¶æ porzegnalna"
3	"Wiadomo¶æ o usuniêciu"
4	"Stopka wiadomo¶ci"
5	"Nag³ówek wiadomo¶ci"
6	"Przypomnienie"
7	"Wiadomo¶æ o odrzuceniu przez edytora"
8	"Zaproszenie do zapisania"
9	"plik pomocy"
10	"katalog list"
11	"Wiadomo¶æ porzypominaj±ca"
12	"Podsumowanie"
13	"Opis listy"
14	"Strona domowa listy"

$set 16 Listm parameters titles
1	"Konto"
2	"Kto mo¿e zapisywaæ na listê"
3	"Anonimowy nadawca"
4	"Archiwa tekstowe"
5	"czêstotliwo¶æ"
6	"prawo dostêpu"
7	"Obs³uga odbiæ"
8	"czêstotliwo¶æ ostrzegania"
9	"czêstotliwo¶æ zatrzymywania"
10	"Wyga¶niêcie nie potwierdzonych przez moderatora listów"
11	"Sekretny ci±g do generowania unikatowych kluczy"
12	"Tworzenie listy"
16	"Dodatkowe pole nag³ówka"
17	"Oznaczenie tematu"
18	"Profil zapisów"
19	"tryb odbioru"
20	"widoczno¶æ"
21	"Kto mo¿e kasowaæ zapisanych"
22	"Czesto¶æ gigestu"
23	"dni"
24	"godzin"
25	"minut"
26	"Moderatorzy"
27	"adres email"
28	"tryb odbioru"
29	"nazwisko"
30	"informacje prywatne"
31	"Rodzaj za³±cznika"
32	"Wymuszony adres zwrotny"
33	"Domena Internetowa"
34	"Dodanie pliku"
35	"Dodanie zapytania LDAP"
36	"zdalny serwer"
37	"zdalny port"
38	"zdalny u¿ytkownik"
39	"zdalne has³o"
40	"suffix"
41	"filtr"
42	"wyci±g atrybutu"
43	"wybór (je¿eli istnieje wiele mo¿liwo¶ci)"
44	"Za³±czenie listy"
45	"Za³±czenie zapytania SQL"
46	"typ bazy danych"
47	"zdalny komputer"
48	"nazwa bazy danych"
49	"zdalny u¿ytkownik"
50	"zdalne has³o"
51	"zapytanie SQL"
53	"Kto mo¿e przegl±daæ informacje o li¶cie"
54	"Kto mo¿e zapraszaæ na listê"
55	"Jêzyk listy"
56	"Maksymalny rozmiar wiadomo¶ci"
57	"Administrator"
58	"adres email"
59	"tryb odbioru"
60	"nazwa"
61	"informacje prywatne"
62	"profil"
63	"Priorytet"
64	"Kto mo¿e rozpocz±æ proces przypominania"
65	"Przypomnienie ¶cie¿ki-zwrotnej"
66	"Adres zwrotny"
67	"Kto mo¿e przegl±daæ zapisanych"
68	"Kto mo¿e wysy³aæ wiadomo¶ci"
69	"Numer seryjny pliku konfiguracyjnego"
70	"Dokumenty wspó³dzielone"
71	"Status listy"
72	"Temat listy"
73	"Kto mo¿e zapisaæ siêna listê"
74	"Tematy dla listy"
75	"Up³yn±³ czas do³±czenia"
76	"Kto mo¿e siê wypisaæ"
77	"Ostatnia modyfikacja pliku konfiguracyjnego"
81	"¬ród³o danych u¿ytkownika"
82	"Widoczno¶æ listy"
83	"Archiwa WWW"
84	"prawa dostêpu"
85	"Powitalna ¶cie¿ka-zwrotna"
86	"Kto mo¿e odczytywaæ"
87	"Kto mo¿e edytowaæ"
