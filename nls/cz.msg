$ Apr 2001, Initial version by Petr Prazak <prazak@grisoft.cz>

$quote "

$set 1	Messages used while processing the configuration file
1	"Konfiguraèní soubor obsahuje chyby.\n"
3	"Chyba na øádku %d : %s"
102	"3.1b.12"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Chyba pøístupu k adresáøi %s : %m"

$set 4	Messages used in the main loop
11	"Va¹e zpráva pro %s byla odmítnuta"
12	"Va¹e zpráva nemohla být doruèena, proto¾e její velikost \n\
pøesahuje maximální mo¾nou velikost pro tuto konferenci.\n"
15	"Va¹e pøíspìvek do konference %s byl odmítnut.\n\
Tímto ho zasíláme zpìt.\n\n\
Va¹e zpráva :\n"
17	"Výsledek Va¹ich pøíkazù"
18	"Nalezen pøíkaz 'quit' : ignoruji zbytek zprávy.\n"
19	"Nesprávný pøíkaz: ignoruji zbytek zprávy.\n"
24	"Konec Va¹eho pøíkazu EXPIRE pro konferenci %s"
26	"Tito èlenové jsou :\n"
27	"Pokud chcete odstranit tyto èleny z konference, pou¾ijte následující pøíkazy :\n"
28	"Mezi èleny konference %s od %d dní, jich %d nepotvrdilo jejich pøihlá¹ení.\n"
37	"Ignoruji tìlo zprávy, která neni ve formátu text/plain, prosím pou¾ijte pouze formát text/plain \n(nebo vlo¾te pøíkaz do subjektu zprávy).\n"
38	"Vá¹ pøíkaz pro konferenci %s byl pøedán jejímu správci\n"
39	"Ve zpráve nebyl nalezen ¾ádný pøíkaz."
40	"Va¹e zpráva bude moderována"

$set 5	Messages used in the tools module
1	"Safefork nemù¾e vytvoøit nový proces : %m"
2	"Chyba routování ?"
3	"Následující zpráva byla odeslána do konference a zdá se, ¾e obsahuje\n\
pøíkazy jako subscribe, unsubscribe, help, index, get, ...\n\n\
Pokud Va¹e zpráva skuteènì obsahovala pøíkaz, pov¹imnìte si prosím, ¾e \n\
pøíkazy by se nemìly nikdy posílat do konference. Pøíkazy se musí odeslat\n\
výhradnì na adresu %s .\n\n\
Pokud jste chtìl Va¹i zprávu opravdu poslat do konference, byla\n\
zpracována jako pøíkaz. Prosím kontaktujte správce: %s \n\
aby se mohl o Va¹i zprávu postarat.\n\n\
Dìkujeme za Va¹i pozornost.\n\n\
------ Zaèátek podezøelé zprávy ------\n"
4	"------ Konec podezøelé zpávy ------\n"

$set 6	Messages du module Commands.pm
2	"Nelze èíst soubor s nápovìdou : %s\n"
5	"Konference '%s' neexistuje.\n"
6	"Informace o konferenci %s :\n\n"
7	"Archív této konference neobsahuje ¾ádné soubory.\n"
8	"Po¾adovaný soubor neexistuje.\n"
9	"Tato konference je soukromá : Nemù¾ete èít archiv.\n"
10	"Tato konference je soukromá : Nelze prohlí¾et dostupné soubory.\n"
11	"Tato konference je soukromá : Nelze prohlí¾et seznam èlenù.\n"
13	"Chyba v pøíkazu.\n"
15	"Proces ovìøení toto¾nosti selhal.\n\n"
16	"Patrnì jste potvrdil va¹e pøihlá¹ení z jiné\n\
emailové adresy. Pøihla¹te se, prosím, z va¹í stálé adresy."
18	"Va¹e èlenství v konferenci %s bylo ukonèeno."
21	"Obnovení va¹eho èlenství v konferenci '%s'"
24	"Mo¾nost pøihlá¹ení do této konference je momentálnì pozastavena.\n"
25	"Vá¹ po¾adavek na pøihlá¹ení/odhlá¹ení byl pøedán správci pro schválení.\n\
Obdr¾íte upozornìní, a¾ budete pøihlá¹en (nebo odhlá¹en)\n."
26	"Odhlá¹ení z konference %s není dostupné.\n"
27	"Informace o Va¹em pøihlá¹ení byla aktualizována.\n"
28	"Jste nyní èlenem konference %s.\n"
29	"Informace o této konferenci bude zaslána v samostatné zprávì.\n"
30	"Va¹e emailová adresa nebyla nalezena v konferenci %s. Mo¾ná\n\
jste se pøihlásil z jiné emailové adresy ?\n"
31	"Byl jste odstranìn z konference %s.\n\
Dìkujeme za Va¹e èlenství.\n"
32	"Pouze vlastníci konference %s mohou pøidávat a odebírat èleny.\n\
Nemáte opravnìní pou¾ít tento pøíkaz, nebo jste neposkytl polo¾ky\n\
potøebné k Va¹í identifikaci.\n"
33	"Emailová adresa %s nebyla nalezena v konferenci.\n"
34	"Správce této konference, %s, Vás odstranil ze seznamu konference.\n\n\
Tato akce se provádí zpravidla kvùli odstranìní adres, tvoøících\n\
hlá¹ení o nedoruèitelnosti. Va¹e adresa v¹ak mù¾e pøesto fungovat normálnì.\n\
Pokud je to tak, omluvte nás prosím za tuto potí¾ a obnovte Va¹e èlenství.\n"
35	"Archív Vám bude odeslán ve zvlá¹tní zprávì.\n"
36	"Informace o u¾ivateli %s v konferenci %s byla aktualizována.\n"
37	"U¾ivatel %s je nyní èlenem konference %s.\n"
38	"U¾ivatel %s byl odstranìn z konference %s.\n"
39	"Nìkdo (doufejme, ¾e Vy) po¾adoval, aby byl pøidán nebo odstranìn\n\
u¾ivatel konfernce %s.\n\n\
Pokud chcete provést tuto akci, ode¹lete zprávu na adresu\n\
%s obsahující \n\n\
   %s\n\n\
Pokud nechcete tuto akci provést, prostì ignorujte tuto zprávu.\n"
40	"Va¹e konfigurace v konferenci %s byla zmìnìna.\n"
41	"Chyba pøístupu k moderované zprávì v konferenci %s pomocí klíèe %s.\n\
Tato zpráva byla mo¾ná ji¾ odeslána jedním z moderátorù konference.\n\n"
43	"Zpráva %s do konference %s byla odmítnuta.\n"
44	"Zpráva %s do konference %s byla rezeslána.\n"
45	"Konference %s nepøijímá re¾im DIGEST. Va¹e konfigurace nebyla zmìnìna.\n"
46	"Pøíkaz MODINDEX je vyhrazen pouze moderátorùm.\n\
Vy nejste moderátorem konference %s.\n"
47	"Pøíkazy EXPIRE, EXPIREINDEX a EXPIREDEL jsou vyhrazeny vlastníkùm konference.\n\
Vy nejste vlastníkem konference %s.\n"
48	"\
Nìkdo (doufejme, ¾e Vy) po¾adoval, aby èlenové konference\n\
'%s' více ne¾ %d dní museli potvrzovat svoje èlenství.\n\
Pokud nechcete tuto akci provést, prostì ignorujte tuto zprávu.\n\
Pro potvrzení této akce ode¹lete email na adresu '%s' s následujícím pøíkazem:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Pøíkaz EXPIRE se právì provádí pro konferenci %s.\n\
Byl spu¹tìn vlastníkem %s (%s)\n\
Nemù¾e být víc ne¾ jeden proces 'expire' najednou pro jednu konferenci.\n\
Momentálnì bì¾ící expirace je pro èleny, kteøí jsou pøihlá¹eni vice ne¾\n\
%d dní a kteøí nepotvrdili svoje pøihlá¹ení. Expirace skonèí\n\
za %d dní (%s).\n"
52	"%s neobdr¾en potvrzení pro následující adresy :\n"
53	"Pro ukonèení procesu expirace : EXPIREDEL %s\n"
54	"Pro konferenci %s není momentálnì spu¹tìn proce expirace.\n"
55	"Ukonèil jste proces expirace pro konferenci %s\n"
56	"\
Byl spu¹tìn proces expirace pro konferenci %s. Tento proces skonèí\n\
za %d dní. Obdr¾íte potom seznam èlenù konference, kteøí \n\
vèas nepotvrdili své èlenství.\n\
Mù¾ete pak tyto adresy odstranit pomocí pøíkazu DEL.\n"
57	"Pro ètení seznamu èlenù konference, kteøí nepovrdili své\n\
pøihlá¹ení : EXPIREINDEX %s\n"
58	"Mù¾ete odstranit tyto èleny z konference pomocí následujících pøíkazù :\n"
60	"\
Pøíkaz EXPIRE nemohl být spu¹tìn. Musí být následován vysvìtlujícím\n\
Pro èleny, kteøí musí obnovit své èlenství.\n\
Tento text musí\n\n\
 - zaèínat hned na dal¹í øádce za pøíkazem EXPIRE,\n\
 - obsahovat alespoò 20 slov,\n\
 - konèit slovem QUIT.\n"
61	"Proto je Vám zpráva vrácena zpìt :\n"
67	"Zde je seznam konferencí, jich¾ jste èlenem :\n\n"
68	"Nelze pøistupovat ke zprávì, ovìøené klíèem %s.\n"
69	"%s odeslal expiraèní zprávu na následující adresy :\n"
70	"\nPowered by Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Odhlá¹ení z konference %s"
72	"\n\nKonference, jich¾ jste vlastníky :\n\n"
73	"\n\nKonference, jich¾ jste editory :\n\n"
74	"Ovìøení toto¾nosti k %s pro pøíkaz %s\n"
75	"Povolit odhlá¹ení %s ze v¹ech konferencí \n"
76	"Pøipomenutí Va¹eho èlenství v %s "
77	"Jste èlenem konference %s s adresou %s\n"
78	"Pøipomenutí pøihlá¹ení odesláno na %d èlenù %s \n"
79	"Po¾adoval jste, aby se odeslalo pøipomenutí pøihlá¹ení\n\
ka¾dému èlenovi konference %s\n\n\
Pokud chcete provést tuto akci, ode¹lete prosím zprávu na adresu\n\
%s obsahující \n\n\
   %s\n\n\
Pokud nechcete provést tuto akci, jednodu¹e ignorujte tuto zprávu.\n"
80	"Nemáte oprávnìní provést pøíkaz %s v konferenci %s\n"
81	"Pøíruèka u¾ivatele"
82	"Veøejné konference"
83	"Souhrn pøihlá¹ení"
84	"U¾ivatel '%s' je ji¾ èlenem konference '%s'\n"
85	"U¾ivatel %s byl vyzván, aby se pøihlásil do konference %s.\n"
86	"U¾ivatel %s je v konferenci %s ne¾ádoucí.\n"
90	"Konference %s dovoluje pouze tyto re¾imy pøíjmu : %s\n\
Va¹e konfigurace nebyla zmìnìna.\n"
260	"Nìkdo (doufejme, ¾e Vy) po¾aduje, aby byla Va¹e emailová adresa\n\
pøipojena do konference '%s'.\n\
Pokud chcete provést tuto akci, buïto\n\
\n\
- odpovìzte na tuto zprávu\nNEBO\n\
- za¹lete zprávu na adresu %s se subjektem\n %s\nNEBO\n\
- pou¾ijte následující odkaz %s\n\
\n\
Pokud tuto akci nechcete provést, mù¾ete klidnì tuto zprávu ignorovat."
261	"Nìkdo (doufejme, ¾e Vy) po¾aduje, aby byla Va¹e emailová adresa\n\
odstranìna z konference '%s'.\n\
Pokud chcete provést tuto akci, buïto\n\
\n\
- odpovìzte na tuto zprávu\nNEBO\n\
- za¹lete zprávu na adresu %s se subjektem\n %s\nNEBO\n\
- pou¾ijte následující odkaz %s\n\n\
\
Mù¾ete to také udìlat pomocí tohoto odkazu %s\n\
Pokud tuto akci nechcete provést, mù¾ete klidnì tuto zprávu ignorovat."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Vlastníci konference %s"
2	"Po¾adavek na pøihlá¹ení do konference %s"
3	"Milý vlastníku konference %s,\n\n\
Nìjaký u¾ivatel se chce pøipojit do konference. Pokud s tím souhlasíte,\n\
mìl byste otevøít následujcí odkaz :\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n\n\
nebo odeslat zprávu na adresu %s s následující subjektem :\n\
AUTH %s ADD %s %s %s\n"
4	"Moderátoøi konference %s"
5	"[%s] Pøíspìvek ke schválení"
6	"Vítejte v konferenci %s"
7	"Soubor"
9	"Shrnutí konference %s"
10	"Pro rozeslání pøipojené zprávy do konference %s:\n\
mailto:%s?subject=DISTRIBUTE%%20%s%%20%s\n\
Nebo po¹lete zprávu na adresu %s s nasledujícím subjektem :\n\
DISTRIBUTE %s %s\n\n"
11	"Pro její odmítnutí (bude odstranìna):\n\
mailto:%s?subject=REJECT%%20%s%%20%s\n\
Nebo po¹lete zprávu na adresu %s s nasledujícím subjektem :\n\
REJECT %s %s\n"
12	"Pro rozeslání pøipojené zprávy do konference %s :\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Nebo po¹lete zprávu na adresu %s s nasledujícím subjektem :\n\
CONFIRM %s\n"
13	"Obsah" 
14	"Konec shrnutí konference %s"
15	"Na moderování èeká %d zpráv v konferenci %s" 
16	"Po¾adováno ovìøení toto¾nosti"
21	"FYI: Pøíkaz %s v konferenci %s od u¾ivatele %s %s"
22	"Na vìdomost: pøíkaz %s v konferenci %s od u¾ivatele %s %s \n (¾ádná akce není tøeba)\n"
23	"POZOR: %s %s se nemohl odhásit z konference %s, proto¾e jeho adresa\n\
nebyla nalezena v seznamu\n (Zkuste této osobì pomoci)\n"
24	"Po¾adavek na odhlá¹ení z konference %s"
25	"Milý vlastníku konference %s,\n\n\
Nìjaký u¾ivatel se chce odhlásit z konference. Pokud s tím souhlasíte,\n\
mìl byste otevøít následujcí odkaz :\n\n\
mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s\n\n\
nebo odeslat zprávu na adresu %s s následující subjektem :\n\
AUTH %s DEL %s %s\n"
26	"FYI: pøíkaz %s v konferenci %s od u¾ivatele %s %s schválil %s\n (¾ádná akce není tøeba)\n"
27	"Pomìr vrácených zpráv konferenci %s je %d%%.\n\n\
Mìl byste odstranit chybné adresy: \n\
%s/reviewbouncing/%s"
28	"POZOR: pomìr vrácených zpráv v konferenci %s je pøíli¹ vysoký"
29	"Pozvání k pøipojení se ke konferenci %s"
30	"Jste zván, abyste se pøipojil ke konferenci %s"
31	"Souhrn konference %s"

$set 9	Messages for the review header
1	"Vlastník             : %s\n"
2	"Moderátor            : %s\n"
3	"Pøihlá¹ení           : %s\n"
4	"Odhlá¹ení            : %s\n"
5	"Zasílání zpráv       : %s\n"
6	"Seznam èlenù         : %s\n"
7	"Odpovìï na           : %s\n"
8	"Maximální velikost   : %d\n"
9	"Odkaz pro konferenci : %s\n"
10	"Shrnutí              : %s\n"
11	"Vlastní subjekt      : %s\n"
12	"Subjekt              : %s\n"
13	"Zpùsob pøijímání     : %s\n"

$set 11	Messages used by the smtp module.
1	"Vá¹ systém neodpovídá standardu POSIX P1003.1, nebo\n\
Va¹e instalace Perlu nedefinuje konstantu _SC_ARG_MAX ve své knihovnì POSIX.\n\
Upravte modul smtp.pm tak, aby se dala dosadit hodnota do \n\
promìnné $max_arg.\n"
2	"Nelze vytvoøit kanál ve funkci smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"iso-8859-2"
3	"8bit"
4	"SYMPA <%s>"

$set 13	Messages for the header of moderation index
1	"\t     Datum                : %s"
2	"\t     Odesílatel           : %s"
3	"\t     Velikost             : %s\n"
4	"\t     Klíè moderátora      : %s\n"

$set 14 Pour le web
1	"cs_CZ"
2	"èe¹tina"

$set 15 Templates files
1	"uvítací zpráva"
2	"zpráva pro odhlá¹ení"
3	"zpráva pro smazání"
4	"patièka zprávy"
5	"hlavièka zprávy"
6	"pøipomínací zpráva"
7	"zpráva pro odmítnutí redaktorem"
8	"zpráva pro pozvaní k pøihlá¹ení"
9	"nápovìda"
10	"adresáø konferencí"
11	"globální pøipomínací zpráva"
12	"souhrnná zpráva"
13	"popis konference"
14	"domovská stránka konference"

$set 16 Listm parameters titles
1	"Úèet"
2	"Kdo mù¾e pøidat èleny"
3	"Anonymní odesílatel"
4	"Archív textu"
5	"frekvence"
6	"právo pøístupu"
7	"Správa vrácených zpráv"
8	"pomìr pro varování"
9	"pomìr pro zastavení"
10	"Expirace nemoderovaných zpráv"
11	"Tajný øetezec pro vytvoøení jedineèných klíèù"
12	"Vytvoøení konference"
16	"U¾ivatelská polo¾ka hlavièky"
17	"Oznaèení subjektu"
18	"Profil pøihlá¹ení"
19	"zpùsob pøijímání"
20	"viditelnost"
21	"Kdo mù¾e mazat èleny"
22	"Frekvence shrnutí"
23	"dnù"
24	"hodina"
25	"minuta"
26	"Moderátoøi"
27	"emailové adresy"
28	"zpùsob pøijímání"
29	"jméno"
30	"soukromá informace"
31	"Typ pøílohy"
32	"Vnucená adresa pro odpovìï"
33	"Doména v internetu"
34	"Pøipojení souboru"
35	"Pøipojení dotazu v LDAP"
36	"vzdálený poèítaè"
37	"vzdálený port"
38	"vzdálený u¾ivatel"
39	"vzdálené heslo"
40	"pøípona"
41	"filtr"
42	"vyta¾ený atribut"
43	"výbìr (pokud je vícenásobný)"
44	"Pøipojení seznamu"
45	"Pøipojení dotazu SQL"
46	"typ databáze"
47	"vzdálený poèítaè"
48	"jméno databázee"
49	"vzdálený u¾ivatel"
50	"vzdálené heslo"
51	"dotaz SQL"
53	"Kdo mù¾e vidìt popis konference"
54	"Kdo mù¾e zvát u¾ivatele"
55	"Jazyk konference"
56	"Maximální velikost zprávy"
57	"Vlastník"
58	"emailová adresa"
59	"zpùsob pøijímání"
60	"jméno"
61	"soukromé informace"
62	"profil"
63	"Priorita"
64	"Kdo mù¾e spustit proce pøipomínání"
65	"Návratová cesta pro pøipomenutí"
66	"Adresa pro odpovìï"
67	"Kdo mù¾e získat seznam u¾ivatelù"
68	"Kdo mù¾e posílat zprávy"
69	"Poøadové èíslo konfigurace"
70	"Sdílené dokumenty"
71	"Stav konference"
72	"Subjekt konference"
73	"Kdo se mù¾e pøihlásit do konference"
74	"Témata konference"
75	"Èasová prodleva pro zahrnutí"
76	"Kdo se mù¾e odhlásit"
77	"Poslední zmena konfigurace"
81	"Zdroj dat u¾ivatelù"
82	"Viditelnost konference"
83	"Archívy na webu"
84	"právo pøístupu"
85	"Návratová cesta pro uvítání"
86	"Kdo mù¾e prohlí¾et"
87	"Kdo mù¾e editovat"
88	"Dostupné volby pro pøihlá¹ení"
89	"zpùsob pøijímání"

$set 17 Cookie expiration periods
1	"sezení"
2	"10 minut"
3	"30 minut"
4	"1 hodina"
5	"6 hodin"
6	"1 den"
7	"1 týden"

