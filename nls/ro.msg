$ March 2002, Initial Romanian translation by Valics Lehel <lvalics@grafx.ro>

$ codeset=iso-8859-2
$quote "

$set 1	Messages used while processing the configuration file
1	"Fisierul de configurare are greseli.\n"
3	"Greseala în linia %d %s"
102	"3.3a"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"%s libraria nu este disponibila: %m"

$set 4	Messages used in the main loop
11	"Mesajul trimis catre %s a fost respinsa"
12	"Mesajul tau nu a fost trimis, ai depasit marimea admisa\n"
15	"Mesajul tau trimis la lista %s a fost respins.\n\
Mesajul tau a fost returnat.\n\n\
Mesajul:\n"
17	"Rezultatul comenzii:"
18	"Comanda 'quit' executata: restul mesajului a fost ignorat.\n"
19	"Comanda neexecutabila: restul mesajului a fost ignorat.\n"
24	"Comanda EXPIRE executat pe lista %s."
26	"Lista membrilor:\n"
27	"Lista enumerata o poti sterge cu urmatoarea comanda:\n"
28	"De pe lista %s de %d zile %d nu au confirmat abonarerea.\n"
37 	"Mesaj ignorat pentru ca nu este in format text, Scrie doar mesaje in format text \n(sau pune comanda in subiect).\n"
38	"%s mesajul trimis pe lista a fost trimisa si la administrator(i)\n"
39	"Aceasta comanda nu este prezenta in mesaj."
40	"Aparitia mesajului va fi decisa de moderator."

$set 5	Messages used in the tools module
1 	"Comanda safefork nu poate incepe alt proces : %m"
2	"Eroare rutare?"
3	"Urmatoarea scrisoare a fost trimisa pe lista, dar acesta contine \n\
comenzi, ca de exemplu,subscribe, unsubscribe, help, index, get.\n\n\
Daca scrisoarea contine intr-adevar comenzi, atunci trebuie sa stii ca \n\
acest tip de scrisori nu se trimit pe lista ci doar pe anumite %s adrese email\n\
.\n\n\
Daca mesajul a fost trimis pe lista atunci administratorul listei va\n\
rula comenzile. Contacteaza administratorul sistemului\n\
: %s pentru a se ocupa de mesaj.\n\n\
Multumim pentru intelegere.\n\n\
------ Inceputul scrisorii cu probleme ------\n"
4	"------ Sfarsitul scrisorii cu probleme ------\n"

$set 6 Messages du module Commands.pm
2 	"Fisierul help nu poate fi accesat: %s\n"
3 	"Lista '%s' nu are utilizatori.\n"
5	"Lista cu denumirea  '%s' nu exista.\n"
7	"Arhiva listei nu contine nici un mesaj.\n"
8	"Fisierul cerut nu exista.\n"
9	"Lista particulara: Nu ai acces la arhiva.\n"
10	"Lista particulara: Nu acces la fisierele.\n"
11	" Lista particulara: Lista continutului nu poate fi accesata.\n"
13	"Comanda eronata.\n"
15	"Procesul de actualizare a esuat\n\n"
16	"Confirmarea abonarii probabil a fost facuta de pe o alta adresa email\n\. Foloseste aceeasi adresa email."
18	"Inscrierea ta pe lista %s nu mai este valida  ."
21	"Reinoirea contului la lista '%s'"
24	"Inscrierile pe aceasta lista sunt momentan suspendate.\n"
25	"Cererea de abonare/renuntare a fost trimisa la administratorul listei\n\ pentru aprobare. Vei fi anuntat cand vei fiaccepta/sters de pe lista.\n"
26	"Renuntarea la lista %s nu este posibila .\n"
27	"Informatiile privind abonarea ta au fost actualizate.\n"
28	"Ai acces la lista %s.\n"
29	"Informatii privind aceasta lista vor fi trimise intr-un mesaj separat.\n"
30	"Adresa ta email nu exista in lista %s. \n\
Te-ai inscris de pe o alta adresa?\n"
31	"Ai fost sters de pe lista %s.\n\
Multumim ca ai utilizat aceasta lista.\n"
32	"Doar proprietarii liste %s pot sa adauge sau sa starga utilizatori.\n\
Nu ai acces de utilizare a acestei comenzi sau nu ai furnizat datele necesare pentru identificare\n\.\n"
33	"Adresa email%s nu exista in aceasta lista.\n"
34	"Ai fost sters de pe lista\n\ de %s, proprietarul acestei liste.\n\n\
Acest fapt survine pentru a sterge adresele care genereaza \n\
rapoarte de netrimitere/eroare. Adresa poate fi totusi buna.\n\
Daca e asa, ne cerem scuze si reinoiesteti subsrierea\n"
35	"Arhiva va fi trimisa intr-un mesaj separat.\n"
36	"Informatiile privind utilizatorul %s au fost actualizate pe lista %s.\n"
37	"Utilizatorul %s este inscris pe lista %s.\n"
38	"Utilizatorul %s a fost sters de pe lista %s/\n"
39	"Cineva (sa speram ca chiar tu) a cerut ca un utilzator sa fie adaugat sau sters de pe lista %s \n\
.\n\n\
Daca vrei ca aceasta actiune sa aiba loc, trimite un mail la \n\
%s cu continutul \n\n\
%s\n\n\
Daca vrei ca aceasta actiune sa nu aiba loc, ignora mesajul.\n"
40	"Configuratia contului tau pentru lista %s a fost actualizata.\n"
41	"Mesajul moderatorului de pe lista%s cu tasta %s nu poate fi accesat.\n\
Probabil ca acest mesaj a fost deja trimis de catre unul dintre moderatorii listei\n.\n"
43	"Mesajul %s pentru lista %s a fost respins.\n"
44	"Mesajul %s pentru lista %s a fost distribuit.\n"
45	"Lista %s nu accepta tipul DIGEST. Configuratia privind acest aspect nu a fost actualizata.\n"
46	"Comanda MODINDEX este strict pentru moderatori.\n\
Nu esti unul dintre moderatorii listei %s.\n"
47	"Comenzile EXPIRE, EXPIREINDEX si EXPIREDEL sunt exclusiv pentru proprietarii listei.\n\
Nu esti unul dintre proprietarii listei %s.\n"
48	"\
Cineva (sa speram ca chiar tu) a cerut ca cei inscrisi pe lista\n\
'%s' pentru mai mult de %d zile trebuie confirme abonarea.\n\
Daca aceasta actiune vrei sa nu fie pusa in aplicare, ignora mesajul.\n\
Pentru a confirma actiunea, trimite un mail la '%s', cu urmatoarea comnada:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
O comanda EXPIRE ruleaza pentru lista %s.\n\
A fost rulata de catre proprietarul %s (%s)\n\
Nu pot fi rulate mai multe procese 'expire' in acelasi timp pentru aceasta lista.\n\
Procesul “expire” curent ruleaza pentru oamenii care s-au inscris de mai mult \n\
de %d zile si care nu si-au confirmat abonarea. Procesul de expirare\n\
se va incheia in %d zile(s) (%s).\n"
52	"%s Nu s-a primit confirmarea pentru urmatoarele adrese:\n"
53	"Pentru a stopa procesul de expirare : EXPIREDEL %s\n"
54	"Lista %s nu ruleaza in prezent nici un process de expirare.\n"
55	"Ai oprit procesul de expirare pentru lista%s\n"
56	"\
Pentru lista %s a fost pornit un proces de expirare. Acest proces\n\
se va incheia in %d zile. Vei primi apoi o lista cu inscrisi \n\
care nu au confirmat abonarea in tiimp util.\n\
Acum vei putea sa stergi aceste adrese cu comanda  DEL.\n"
57	"Pentru a citi lista celor care nu au confirmat \n\
subscrierea:EXPIREINDEX %s\n"
58	"Aceste adrese email pot fi sterse utilizand urmatoarele comenzi :\n"
60	"\
Comanda EXPIRE nu poate fi rulata. Trebuie urmata de o explicatie\n\
care sa se adreseze direct celor care trebuie sa confirme abonarea.\n\
Acest text trebuie \n\n\
 - sa inceapa pe prima linie dupa comanda EXPIRE,\n\
 - sa contina cel putin 20 de cuvinte,\n\
 - iar incheierea sa aiba cuvantul QUIT.\n"
61	"Astfel, mesajul tau e trimis inapoi la tine:\n"
67	"Acestea sunt listele la care esti in prezent inscris:\n\n"
68	"Accesul la mesajul autentificat cu tasta %s invalid.\n"
69	"%s a afisat mesajul expirat la urmatoarea adresa:\n"
70	"\nPowered de Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Renunta la lista %s"
72	"\n\nListe a caror proprietar esti:\n\n"
73	"\n\nListe a caror editor esti:\n\n"
74	"Autentificare ceruta pentru %s pentru comanda %s\n"
75	"Permite renuntarea utilizatorului %s din orice lista\n"
76	"Iti reaminteste %s subscriere"
77	"Esti membru al listei %s cu email-ul %s\n"
78	"Mesaj de reamintire trimis la toti cei inscrisi %d %s \n"
79	"Ai cerut ca un mesaj de atentionare sa fie trimis \n\
la fiecare abonat al listei %s\n\n\
Daca aceasta actiune vrei sa nu fie pusa in aplicare, ignora mesajul.\n\
Pentru a confirma actiunea, trimite un mail la \n\
%s cu continutul\n\n\
   %s\n\n\
Daca nu doresti sa confirm actiunea, ignora mesajul.\n"
80	"Comanda %s nu este permisa in lista %s\n"
81	"Ghidul utilizatorului"
82	"Liste publice"
83	"Rezumatul abonarilor"
84	"Utilizatorul '%s' este deja inscris la lista '%s'\n"
85	"Utilizatorul %s a fost invitat sa se abona in lista %s.\n"
86	"Utilizatorul %s este persona non-grata in lista %s.\n"
90	"Lista %s permite doar aceste metode de primire a mesajelor: %s\n\
Configuratia contului tau nu a fost modificata.\n"
91	"Lista %s nu ofera utilizatorilor optiuni.\n"
92	"Operatia de modificare a preferintelor la lista %s au esuat.\n"
260	"Cineva a cerut ca adresa email \n\ sa fie adaugata la lista '%s'.\n\
Daca vrei ca actiunea sa fie rulata \n\
\n\
- raspunde la acest mail\nOR\n\
- trimite un mail la %s cu subiectul\n %s\nOR\n\
- apasa pe mailto %s\n\
\n\
Daca nu vrei ca actiunea sa fie rulat, poti sa ignori\n\
acest mesaj."
261	"Cineva a cerut ca adresa email \n\
sa fie stearsa din lista '%s'.\n\
Daca vrei ca actiunea sa fie rulata \n\
\n\
- raspunde la acest mail\nOR\n\
- trimite un mail la %s cu subiectul\n %s\nOR\n\
- click pe mailto %s\n\
\n\
Acest lucru poate fi facut prin URL %s\n\
Daca nu vrei ca aceasta nu fie rulata, ignora acest mesaj\n\."
262	"Semnatura mesajului a fost verificata cu succes utilizand S/MIME"
263	"Mesajul tau nu a fost multipart/semnat sau Sympa nu a putut\n verifica semnatura (Sympa nu poate verifica semnatura daca utilizezi headerul subiectului pentru a scrie o comnada)."

$set 7 Commands syslog messages (Commands.pm)

$set 8 Messages used in List.pm
1	"Proprietarii listei %s"
2	"Cerere de abonare la lista %s"
3	"Draga proprietar al listei %s,\n\n\
Un utilizator a cerut sa fie sters din lista ta. Daca esti de acord, \n\
apasa pe urmatorul URL :\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n\n\
sau trimite un mail %s cu urmatorul subiect:\n\
AUTH %s ADD %s %s %s \n"
6	"Bun venit pe lista %s"
7	"Fisier"
9	"Mesaje compilate pentru lista %s"
12	"Pentru a trimite mesajul atasat din lista %s :\n\
mailto:%s?subject=CONFIRM%%20%s\n\
sau trimite un mesaj la %s cu urmatorul subiect:\n\
CONFIRM %s \n"
13	"Continut" 
14	"Terminarea compilarii mesajelor pentru lista %s"
16	"Cerere de autentificare"
21	"FYI: %s lista %s de la %s %s"
22	"FYI comanda %s lista %s  de la %s %s \n (nu necesita alte operatii)\n"
23	"Avertisment: %s %s nu a putut fi sters din %s pentru ca adresa lui\n\
nu a fost gasita in lista\n (Ajuta aceasta persoana)\n"
24	"Cerere de dezabonare din lista %s"
25	"Draga proprietar al listei %s,\n\n\
Un utilizator a cerut sa fie sters din lista ta. Daca esti de acord, \n\
apasa pe urmatorul URL:\n\n\
mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s\n\n\
sau trimite un email la %s cu urmatorul subiect:\n\
AUTH %s DEL %s %s \n"
26	"FYI comanda %s lista %s din %s %s validata de %s \n (nu este necesara nici o actiune)\n"
27	"Rata de retrimitere (bounced) in lista %s este%d%%.\n\n\
E indicat sa stergi abonatii care sunt retrimisi: \n\
%s/vezi retrimiterile/%s"
28	"Avertizare:rata de retrimitere (bounced) in lista %s este prea mare"
29	"Invitatie pentru abonare la lista%s"
30	"Esti invitat sa te abonezi la lista %s"
31 ”Rezumat al listei %s"

$set 11 Messages used by the smtp module.
1	"Sistemul tau nu corespunde standardelor POSIX P1003.1, sau\n\
sistemul tau Perl nu defineste constanta _SC_ARG_MAX din clasa POSIX\n\
. Trebuie sa modifici modulul smtp.pm pentru a putea atribui o valoare\n\
pentru variabila $max_arg.\n"
2	"Nu se poate crea un canal in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"iso-8859-2"
3	"8bit"
4	"SYMPA <%s>"

$set 14 Locale equivalent and language name
1	"ro_RO"
2	"Romanian"

$set 15 Templates files
1	"mesaj de bun venit"
2	"mesaj de dezabonare"
3	"mesaj de stergere"
4	"footer pentru mesaj"
5	"header pentru mesaj"
6	"mesaj de atentionare"
7	"mesaj de respingere din partea editorului"
8	"mesaj de invitare la abonare"
9	"fisier help"
10	"lista tuturor listelor"
11	"mesaj global de avertizare"
12	"mesaj de rezumare"
13	"descrierea listei"
14	"lista homepage"
15	"mesaj de cerere a crearii unei noi liste"
16	"mesaj de notificare a crearii unei noi liste"
17	"mesaj de infectare cu virus"

$set 16 Listm parameters titles
1	"Cont"
2	"Cine poate adauga abonati"
3	"Expeditor anonim"
4	"Arhive text"
5	"Frecventa"
6	"Drept de accesare"
7	"Management-ul mesajelor eronate (bounced)"
8	"Rata de avertizare"
9	"Rata de orpire"
10	"Expirarea mesajelor nemoderate"
11	"Sir secret pentru generarea de chei unice"
12	"Crearea listei"
16	"Camp header"
17	"Subiect afisat"
18	"Profil de abonare"
19	"Modalitate de primire"
20	"Visibilitate"
21	"Cine poate sterge abonatii"
22	"Frecventa de compilare a mesajelor"
23	"Zile"
24	"Ore"
25	"Minute"
26	"Moderatori"
27	"Adresa email"
28	"Modalitate de primire"
29	"Nume"
30	"Informatii private"
31	"Tipul atasamentului"
32	"Adresa fortata de raspuns"
33	"Domeniu internet"
34	"Includere fisier"
35	"Includere cerere LDAP"
36	"Remote host"
37	"Remote port"
38	"Remote user"
39	"Remote password"
40	"Sufix"
41	"Filter"
42	"Atribut extras"
43	"Selectie (daca e multipla)"
44	"Includere lista"
45	"Cerere includere SQL"
46	"Tipul bazei de date"
47	"Remote host"
48	"Numele bazei de date"
49	"Remote user"
50	"Remote password"
51	"Cerere SQL"
53	"Cine poate vizualiza informatiile despre lisat"
54	"Cine poate invita pe altii"
55	"Limba pentru lista"
56	"Marimea maxima a mesajului"
57	"Proprietar"
58	"Adresa email"
59	"Modalitate de primire"
60	"Nume"
61	"Informatii confidentiale"
62	"Profil"
63	"Prioritate"
64	"Cine poate porni un proces de trimitere de mesaje de atentionare"
65	"Atentionare return-path"
66	"Adresa de raspuns"
67	"Cine poate verifica abonatii"
68	"Cine poate trimite mesaje"
69	"Numar de serie pentru config"
70	"Fisiere shared"
71	"Statutul listei"
72	"Subiectul listei"
73	"Cine se poate abona la lista"
74	"Subiecte pentrlista"
75	"Timeout pentru includeri"
76	"Cine se poate dezabona"
77	"Ultima actualizare a config"
81	"Data sursa pentru utilizator"
82	"Vizibilitatea listei"
83	"Arhive WEB"
84	"Drept de acces"
85	"Bun venit prin calea de returnare"
86	"Cine poate vizualiza"
87	"Cine poate edita"
88	"Preferinte disponibile"
89	"Tip de receptare"
90	"Adresa de raspuns"
91	"Valoare"
92	"Alte adrese email"
93	"Respecta headerul campului existent"
94	"Optiuni de conectare"
97	"Scopul cautarii"
98	"Timeout conectare"
135	"Includere cerere LDAP de nivel 2"
136	"Remote host"
137	"Remote port"
138	"Remote user"
139	"Remote password"
140	"Sufix la primul nivel"
141	"Filtru la primul nivel"
142	"Atribut extras la primul nivel"
143	"Selectie la primul nivel"
144	"Suffix template la al doilea nivel"
145	"Filter template la al doilea nivel"
146	"Atribut extras la al doilea nivel"
147	"Selectie la al doilea nivel"
148	"Variabile de mediu pentru conectarea cu baza de date"
197	"Scopul cautarii la primul nivel"
198	"Timeout conectare la primul nivel"
199	"Scopul cautarii la al doilea nivel"
200	"Timeout conectare la al doilea nivel"
201	"Primul nivel al unei expresii obisnuite"
202	"Al doilea nivel al unei expresii obisnuite"

$set 17 Cookie expiration periods
1	"Sesiune"
2	"10 minute"
3	"30 minute"
4	"1 ora"
5	"6 ore"
6	"1 zi"
7	"1 saptamana"