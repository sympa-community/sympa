$ Sep 2002, Initial version by Harry Westerman

$ codeset=iso-8859-1
$quote "

$set 1	Messages used while processing the configuration file
1	"Het configuratiebestand bevat fouten.\n"
3	"Fout in regel %d : %s"
102	"3.3a"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Fout bij benaderen van map %s : %m"

$set 4	Messages used in the main loop
11	"Uw bericht aan %s is afgewezen."
12	"Uw bericht kon niet worden verstuurd omdat \n\
hij groter was dan het maximum toegestaan op deze lijst.\n"
15	"Uw bericht voor lijst %s is afgwezen.\n\
Het bericht wordt dus aan u teruggestuurd.\n\n\
Uw bericht :\n"
17	"De resultaten van uw commando"
18	"Commando 'quit' gevonden : Het einde van het bericht wordt genegeerd.\n"
19	"Commando niet begrepen: Het einde van het bericht wordt genegeerd.\n"
24	"Het einde van uw EXPIRE commando op lijst %s"
26	"Deze inschrijvers zijn :\n"
27	"Wanneer u zich van deze lijst wil uitschrijven, gebruik dan de volgende commandos :\n"
28	"Dan degenen die geabonneerd zijn op lijst %s sinds %d dagen, heeft %d niet hun abonnement bevestigd.\n"
37	"Het bericht wordt genegeerd omdat het niet in het text/plain formaat is, gebruikt uw alstublieft uitsluitend text/plain \n(of zet uw commando in het onderwerp).\n"
38	"Uw bericht voor lijst %s is doorgestuurd naar de editor(s)\n"
39	"Geen commando gevonden in het bericht."
40	"Uw bericht wordt gemodereerd."

$set 5	Messages used in the tools module
1	"Safefork kan geen nieuw proces aanmaken : %m"
2	"Routing fout ?"
3	"Het volgende bericht was naar een lijst gestuurd terwijl het commandos lijkt te bevatten \n\
als subscribe, unsubscribe, help, index, get, ...\n\n\
Als uw bericht inderdaad een commando bevatte, begrijp dan dat \n\
commandos nooit naar de lijst zelf gestuurd dienen te worden. Commandos moeten alleen naar \n\
 %s gestuurd worden.\n\n\
Als uw bericht echt voor de lijst bedoeld was, dan is het \n\
door de software geinterpreteerd als een commando. Neem contact op met de manager \n\
van de service : %s zodat zij uw bericht kunnen bekijken.\n\n\
Bedankt voor uw aandacht.\n\n\
------ Begin van verdacht bericht ------\n"
4	"------ Einde van verdacht bericht ------\n"

$set 6	Messages du module Commands.pm
2	"Het helpbestand kan niet gelezen worden : %s\n"
3	"Lijst '%s' heeft geen geabonneerden.\n"
5	"Lijst '%s' bestaat niet.\n"
7	"Het archief van deze lijst is leeg.\n"
8	"Het verplichte bestand bestaat niet.\n"
9	"De lijst is prive, u kunt niet door de archieven bladeren.\n"
10	"De lijst is prive, u kunt niet door de bestanden bladeren.\n"
11	"De lijst is prive, u kunt niet door de geabonneerden bladeren.\n"
13	"Commando syntax fout.\n"
15	"De authenticatie is niet gelukt.\n\n"
16	"U hebt waarschijnlijk uw abonnement met een ander email adres\n\
 bevestigd. Probeer met uw echte adres in te schrijven."
18	"Uw inschrijving voor lijst %s is ongedaan gemaakt."
21	"Vernieuwing voor uw inschrijving voor lijst '%s'"
24	"Inschrijven op deze lijst is op dit moment niet mogelijk.\n"
25	"Uw aanvraag voor in- of uitschrijven is doorgestuurd naar de lijsteigenaars voor \n\
toestemming. U zult nog een bevestiging ontvangenn wanneer u bent \n\
in- of uitgeschreven voor de lijst.\n"
26	"Uitschrijven is niet toegestaan voor de lijst %s.\n"
27	"Informatie over uw inschrijving is gewijzigd.\n"
28	"U bent nu geabonneerd op de lijst %s.\n"
29	"Informatie over deze lijst wordt u toegestuurd in een apart bericht.\n"
30	"Uw emailadres is niet gevonden in de lijst %s. Misschien\n\
bent u met een ander emailadres ingeschreven op de lijst?\n"
31	"U bent verwijderd van lijst %s.\n\
Bedankt voor het gebruiken van deze lijst.\n"
32	"Alleen de eigenaren van de lijst %s mogen mensen in- of uitschrijven.\n\
U mag dit commando niet gebruiken, of uw heeft zich onvoldoende\n\
geauthenticeerd.\n"
33	"Email adres %s is niet gevonden op deze lijst.\n"
34	"U bent verwijderd van de lijst\n\
door %s, de eigenaar van deze lijst.\n\n\
Dit gebeurt meestal om adressen te verwijderen die toch niet afgeleverd kunnen worden\n\
. Misschien werkt uw emailadres wel degelijk, in dat geval onze excuses hiervoor.\n\
Vernieuwd u in dat geval uw abonnement.\n"
35	"Het archief wordt u toegezonden in een apart bericht.\n"
36	"Informatie over gebruiker %s is gewijzigd voor lijst %s.\n"
37	"Gebruiker %s is nu geabonneerd op lijst %s.\n"
38	"Gebruiker %s is uitgeschreven van lijst %s/\n"
39	"Iemand (hopelijk uzelf) vroeg aan dat een gebruiker van de emaillijst %s wordt\n\
in- of uitgeschreven.\n\n\
Wanneer u wilt dat dit gebeurd, stuur dan een email naar\n\
%s met als inhoud \n\n\
   %s\n\n\
Wanneer u niet wilt dat er iets gebeurt, negeer dan dit bericht..\n"
40	"Uw configuratie voor lijst %s is gewijzigd.\n"
41	"Onmogelijk om het gemodereerde bericht op lijst %s met sleutel %s te benaderen.\n\
Dit bericht kan al verstuurd zijn door een van de moderators van de lijst\n.\n"
43	"Bericht %s voor lijst %s is afgewezen.\n"
44	"Bericht %s voor lijst %s is gedistribueerd.\n"
45	"Lijst %s kent geen DIGEST stand. Uw configuratie is niet gewijzigd..\n"
46	"Het MODINDEX commando is alleen voor moderators.\n\
U bent geen moderator voor lijst %s.\n"
47	"De EXPIRE, EXPIREINDEX en EXPIREDEL commandos zijn alleen voor de eigenaren van deze lijst.\n\
U behoort niet tot de eigenaren van lijst %s.\n"
48	"\
Iemand (Hopelijk uwzelf) heeft aangevraagd dat de abonnees van de lijst\n\
'%s' in minder dan %d dagen hun abonnement dienen te bevestigen.\n\
Wanneer u dit niet wilt, negeer dan dit bericht.\n\
Stuur een email om deze actie te bevestigen naar '%s', met het volgende commando:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Een EXPIRE commando is geactiveerd voor lijst %s.\n\
Dit is opgestart door eigenaar %s (%s)\n\
Er kan niet meer dan 1 proces tegelijkertijd voor een lijst actief zijn.\n\
De huidige expiratie is voor mensen die meer dan \n\
%d dagen niet bereikt zijn en die hun abonnement die bevestigd hebben. De expiratie\n\
zal stoppen over %d dag(en) (%s).\n"
52	"%s kreeg geen bevestigen voor de volgende adressen :\n"
53	"Om het expiratie proces te stoppen : EXPIREDEL %s\n"
54	"Voor lijst %s draait geen expiratie proces op dit moment.\n"
55	"U heeft het expiratieproces gestopt voor lijst %s\n"
56	"\
Een expiratie proces voor lijst %s is gestart. Dit proces\n\
zal eindigen over %d dagen. U zult dan een lijst van abonnees ontvangen \n\
die niet op tijd hun inschrijving hebben bevestigd.\n\
Daarna kunt u deze adressen verwijderen met het DEL commando.\n"
57	"Om de lijst abonnees te bekijken, geeft het \n\
commando : EXPIREINDEX %s\n"
58	"U kunt deze abonnees van de lijst halen met het commando :\n"
60	"\
Het EXPIRE commando kon niet worden uitgevoerd. Het moet gevolgd worden door een uitleg\n\
voor de abonnees van de lijst.\n\
Deze tekst moet:\n\n\
 - Op de eerste regel na het EXPIRE commando starten,\n\
 - Minstens 20 woorden gevatten,\n\
 - en eindigen met het QUIT commando.\n"
61	"Daarom wordt uw bericht naar u teruggestuurd :\n"
67	"Hier zijn de lijsten waar u op geabonneerd bent :\n\n"
68	"Geen toegang tot het bericht met sleutel %s.\n"
69	"%s heeft uw expiratie bericht gepost op het volgende adres :\n"
70	"\nWij werken met Sympa %s : http://www.sympa.org/\n"
71	"Uitschrijven van lijst %s"
72	"\n\nLijsten waar u eigenaar van bent:\n\n"
73	"\n\nLijsten waar u editor van bent :\n\n"
74	"Authenticatie gevraagd %s voor commando %s\n"
75	"Aanzetten om uit te schrijven %s van elke lijst \n"
76	"Herinnering aan uw  %s abonnement"
77	"U bent geabonneerd op lijst %s met emailadres %s\n"
78	"Abonnements herinnering gestuurd naar %d %s abonnees\n"
79	"U vroeg om een inschrijvingsherinnering te sturen naar\n\
iedere abonnee van de lijst %s\n\n\
Wanneer u dit wilt, stuur dan een email naar \n\
%s met de inhoud \n\n\
   %s\n\n\
Wanneer u niet wilt dat dit gebeurt, negeer dan dit bericht..\n"
80	"Het is niet toegestaan dat u commando %s voor list %s geeft.\n"
81	"Gebruikershandleiding"
82	"Publieke lijsten"
83	"Abonnementssamenvatting"
84	"De gebruiker '%s' is al ingeschreven op lijst '%s'\n"
85	"Gebruiker %s is uitgenodigd om zich in te schrijven voor lijst %s.\n"
86	"Gebruiker %s is ongwenst in lijst %s.\n"
90	"Lijst %s staat alleen de volgende ontvangstmethodes toe: : %s\n\
Uw configuratie is niet veranderd.\n"
91	"%s mailinglijst doet niet aan abonnee voorkeursinstellingen.\n"
92	"Het is niet gelukt om uw instellingen te veranderen voor lijst %s.\n"
260	"Iemand (hopelijk uzelf) vroeg om uw emaildres \n\
toe te voegen aan de lijst '%s'.\n\
Wanneer u dit wil, beantwoord dan\n\
\n\
- dit bericht\nOF\n\
- stuur een bericht naar  %s met als onderwerp\n %s\nOF\n\
- klik hierop %s\n\
\n\
Wanneer u niet wilt dat dit gebeurd, kunt u dit bericht \n\
negeren."
261	"Iemand (hopelijk uzelf) vroeg om uw adres te verwijderen \n\
van de lijst '%s'.\n\
Wanneer u dit wilt: \n\
\n\
- beantwoord dan dit bericht\nOF\n\
- stuur dan een bericht naar '%s' met onderwerp\n %s\nOF\n\
- klik hierop %s\n\n\
\
Dit kan worden gedaan via de URL %s\n\
Wanneer u dit niet wilt kunt u rustig\n\
dit bericht negeren."
262	"Uw handtekening onder dit bericht was succesvol gechecked met S/MIME"
263	"Uw bericht was niet een multipart/signed berciht of Sympa kon uw\nhandtekening niet controleren (let er op dat Sympa uw handtekening niet kan controleren met een commando in het onderwerp)."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Eigenaren van lijst %s"
2	"Inschrijving voor lijst %s"
3	"Geachte eigenaar van lijst %s,\n\n\
Iemand vroeg om ingeschreven te worden voor de lijst. Vindt u dit goed\n\
, klik dan op de volgende URL :\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n\n\
of stuur een email naar %s met het volgende onderwerp :\n\
AUTH %s ADD %s %s %s\n"
6	"Welkom op de lijst %s"
7	"Bestand"
9	"Samenvatting voor de lijst %s"
12	"Om het toegevoegde bericht te distribueren in de lijst %s :\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Of zend een bericht naar %s met het volgende onderwerp :\n\
CONFIRM %s\n"
13	"Inhoudsopgave" 
14	"Einde van de samenvatting van de lijst %s"
16	"Authenticatie gevraagd"
21	"Ter info: %s lijst %s van %s %s"
22	"Ter info commando %s lijst %s van %s %s \n (geen actie benodigd)\n"
23	"WAARSCHUWING : %s %s lukt het niet om zich uit te schrijven van %s omdat het adres niet gevonden werd\n\
op de lijst\n (Misschien kunt u de persoon helpen)\n"
24	"Aanvraag voor uitschrijven bij lijst %s"
25	"Geachte eigenaar van de lijst  %s,\n\n\
Een gebruiker vroeg om zich uit te schrijven bij de lijst. Vind u dit goed\n\
klik dan op de volgende URL :\n\n\
mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s\n\n\
of stuur een email naar %s met het volgende onderwerp :\n\
AUTH %s DEL %s %s\n"
26	"Ter info: commando %s lijst %s van %s %s gevalideerd door %s\n (geen actie benodigd)\n"
27	"Teruggekomen post ratio in lijst %s is %d%%.\n\n\
U zou de abonnees wiens emailadres niet te bereiken is kunnen verwijderen : \n\
%s/reviewbouncing/%s"
28	"WAARSCHUWING het percentage adressen dat niet te bereiken is is te hoog in lijst %s"
29	"Uitnodiging om in te schrijven op lijst %s"
30	"U bent uitgenodigd om u in te schrijven op lijst %s"
31	"Samenvatting van lijst %s"

$set 11	Messages used by the smtp module.
1	"Uw systeem voldoet niet aan de POSIX P1003.1 standaard, of\n\
uw Perl systeem definieerd de _SC_ARG_MAX constante in zijn POSIX\n\
bibliotheek. U dient de smtp.pm module te veranderen om een waarde te zetten\n\
voor de variabele $max_arg.\n"
2	"Niet gelukt om een kanaal te maken in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"us-ascii"
3	"7bit"
4	"SYMPA <%s>"

$set 14 Locale equivalent and language name
1	"en_NL"
2	"nederlands"

$set 15 Templates files
1	"welkomstbericht"
2	"uitschrijfbericht"
3	"verwijderbericht"
4	"voetregel van bericht"
5	"hoofdregels van bericht"
6	"herinneringsbericht"
7	"editor afwijzings bericht"
8	"uitnodigingsbericht om in te schrijven"
9	"help bestand"
10	"overzicht van lijsten"
11	"globaal herinneringsbericht"
12	"samenvattings bericht"
13	"lijst omschrijving"
14	"lijst thuispagina"
15	"list aanmaak bericht"
16	"list aanmaak herinneringsbericht"
17	"virus infectie bericht"

$set 16 Listm parameters titles
1	"Inlognaam"
2	"Wie kan abonnees toevoegen"
3	"Anonieme verzender"
4	"Text archieven"
5	"frequentie"
6	"toegangsrecht"
7	"Bounces management"
8	"waarschuwings percentage"
9	"stop percentage"
10	"Afloop van de termijn voor gemodereerde berichten"
11	"Geheim woord voor het aanmaken van een unieke sleutel"
12	"Aanmaken van de lijst"
16	"Speciaal koptekst veld"
17	"Onderwerp markeren"
18	"Inschrijvings profiel"
19	"Ontvangst stand"
20	"zichtbaar"
21	"Wie kan abonnees verwijderen"
22	"Samenvattings frequentie"
23	"dagen"
24	"uur"
25	"minuut"
26	"Moderators"
27	"emailadres"
28	"ontvangst stand"
29	"naam"
30	"private informatie"
31	"Bijlage type"
32	"Verplicht antwoord adres"
33	"Internet domein"
34	"Bestand insluiten"
35	"LDAP aanvraag insluiten"
36	"systeem"
37	"poort"
38	"gebruiker"
39	"wachtwoord"
40	"extensie"
41	"filter"
42	"afgeleid attribuut"
43	"selectie (waneer meerdere)"
44	"Lijst insluiten"
45	"SQL query insluiten"
46	"database type"
47	"remote host"
48	"database naam"
49	"gebruiekrsnaam"
50	"wachtwoord"
51	"SQL query"
53	"Wie kan lijstinformatie zien"
54	"Wie kan mensen uitnodigen"
55	"Taal van de lijst"
56	"Maximum berichten grootte"
57	"Eigenaar"
58	"emailadres"
59	"ontvangst stand"
60	"naam"
61	"private informatie"
62	"profiel"
63	"Prioriteit"
64	"Wie kan een herinneringsproces starten"
65	"Herinner return-path"
66	"Antwoordadres"
67	"Wie kan de abonnees bekijken"
68	"Wie kan berichten sturen"
69	"Serienummer van de configuratie"
70	"Gedeelde documenten"
71	"Status van de lijst"
72	"Onderwerp van de lijst"
73	"Wie kan inschrijven op de lijst"
74	"Onderwerpen voor de lijst"
75	"Timeout voor de inclusions"
76	"Wie kan uitschrijven"
77	"Laatste update van de configuratie"
81	"Gebruiker data bron"
82	"Zichtbaarheid van de lijst"
83	"Web archieven"
84	"toegangsrecht"
85	"Welkom return-path"
86	"Wie kan zien"
87	"Wie kan wijzigen"
88	"Aanwezige inschrijvings opties"
89	"ontvangst stand"
90	"Antwoord adres"
91	"waarde"
92	"ander email adres"
93	"behoud bestaande kopveld"
94	"connectie opties"
97	"Zoek scope"
98	"connectie timeout"
135	"LDAP 2-level query inclusion"
136	"remote host"
137	"remote poort"
138	"remote gebruiker"
139	"remote wachtwoord"
140	"eerste-nivo suffix"
141	"eerste-nivo filter"
142	"eerste-nivo extracted attribute"
143	"eerste-nivo selectie"
144	"tweede-nivo suffix template"
145	"tweede-nivo filter template"
146	"tweede-nivo extracted attribute"
147	"tweede-nivo selectie"
148	"environment variabele voor database connectie."
197	"eerste-nivo zoek scope"
198	"eerste-nivo connectie timeout"
199	"tweede-nivo zoek scope"
200	"tweede-nivo connectie timeout"
201	"eerste-nivo regular expression"
202	"tweede-nivo regular expression"
203	"quota"
204	"quota"
205	"emailadres beveiligingsmethode"
206	"Externe lijst inclusie"
207	"Extern pad voor de sympa lijst dump"
208	"certificaat voor authenticatie voor een externe Sympa"

$set 17 Cookie expiration periods
1	"sessie"
2	"10 minuten"
3	"30 minuten"
4	"1 uur"
5	"6 uren"
6	"1 dag"
7	"1 week"

