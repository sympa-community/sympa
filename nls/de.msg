$ 1 Oct 2001, Updated by H. Wilhelmi, TNG Tech. <harald.wilhelmi@tngtech.com>
$ 26 Apr 2001, Updated by H. Wilhelmi, TNG Tech. <harald.wilhelmi@tngtech.com>
$ 26 Feb 2000, Update by Carsten Clasohm <cc@clasohm.com>
$ 16 Sept 1999, Initial version by Carsten Clasohm <cc@clasohm.com>

$quote "

$set 1	Messages used while processing the configuration file
1	"Die Konfigurationsdatei enthält Fehler.\n"
3	"Fehler in Zeile %d : %s"
102	"3.3a"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Auf Verzeichnis %s kann nicht zugegriffen werden: %m"

$set 4	Messages used in the main loop
11	"Nachricht an %s abgelehnt"
12	"Ihre Nachricht konnte nicht gesendet werden, weil sie\n\
das Größenlimit für diese Liste überschreitet.\n"
15	"Sie haben versucht, eine Nachricht an eine private Liste\n\
zu schicken, die Sie nicht abonniert haben. Die Nachricht\n\
wird deshalb an Sie zurückgeschickt:\n"
17	"Ergebnis Ihrer Befehle"
18	"Befehl 'quit' gefunden. Rest der Nachricht ignoriert.\n"
19	"Unbekannter Befehl. Rest der Nachricht ignoriert.\n"
24	"Ende Ihres EXPIRE-Befehls für Liste %s"
26	"Diese Abonnenten sind:\n"
27	"Wenn Sie diese Abonnenten von der Liste entfernen wollen,\n\
benutzen Sie die folgenden Befehle:\n"
28	"Von denen, die die Liste %s seit %d Tagen abonniert haben,\n\
haben %d ihr Abonnenment nicht bestätigt.\n"
37	"Ignoriere Nachricht, da sie nicht das Format text/plain hat.\n\
Bitte benutzen Sie text/plain (oder geben Sie den Befehl in der\n\
Betreffzeile an).\n"
38	"Ihre Nachricht an Liste %s wurde an den Moderator weitergeleitet\n"
39	"Kein Kommando in Nachricht gefunden"
40	"Ihre Nachricht wird moderiert"

$set 5	Messages used in the tools module
1	"Safefork konnte keinen neuen Prozeß erzeugen: %m"
2	"Routing-Fehler?"
3	"Die folgende Nachricht wurde an eine Liste geschickt, obwohl sie\n\
Befehle wie subscribe, signoff, help, index, get, ... zu enthalten\n\
scheint.\n\n\
Wenn Ihre Nachricht tatsächlich einen Befehl enthält, denken Sie\n\
bitte daran, daß Befehle niemals an eine Liste geschickt werden\n\
dürfen. Befehle müssen an die Adresse %s geschickt werden.\n\n\
Wenn Ihre Nachricht an die Liste gehen sollte, wurde Sie leider\n\
fälschlicherweise als Befehl verarbeitet. Bitte setzen Sie sich\n\
mit dem Administrator unter %s in Verbindung, damit er sich um\n\
das Problem kümmern kann.\n\n\
Danke für Ihre Aufmerksamkeit.\n\n\
------ Start der Nachricht ------\n"
4	"------ Ende der Nachricht ------\n"

$set 6	Messages du module Commands.pm
2	"Kann Hilfedatei nicht lesen: %s\n"
5	"Liste '%s' existiert nicht.\n"
7	"Das Archiv dieser Liste enthält keine Dateien.\n"
8	"Benötigte Datei existiert nicht.\n"
9	"Die Liste ist privat. Sie können das Archiv nicht lesen.\n"
10	"Die Liste ist privat. Sie können die verfügbaren Dateien\n\
nicht auflisten\n"
11	"Die Liste ist privat. Sie können die Mitglieder nicht auflisten.\n"
13	"Syntaxfehler im Befehl.\n"
15	"Die Authentifizierung ist fehlgeschlagen.\n\n"
16	"Sie haben Ihr Abonnement wahrscheinlich unter einer\n\
anderen EMail-Adresse bestätigt. Bitte versuchen Sie es noch\n\
einmal mit Ihrer Hauptadresse.\n"
18	"Ihr Abonnement der Liste %s wurde aufgehoben."
21	"Erneuerung Ihres Abonnements der Liste '%s'"
24	"Im Moment werden keine neue Abonnenten in diese Liste aufgenommen.\n"
25	"Ihre Bitte, die Liste zu abonnieren bzw. das Abonnement\n\
aufzuheben, wurde an den Verwalter der Liste weitergeleitet.\n\
Sie erhalten eine Bestätigung, sobald Ihr Auftrag erfolgreich\n\
bearbeitet wurde.\n"
26	"Das Abonnement der Liste %s kann nicht aufgehoben werden."
27	"Die Angaben zu Ihrem Abonnement wurden aktualisiert.\n"
28	"Sie sind jetzt Mitglied der Liste %s.\n"
29	"Informationen zu dieser Liste werden Ihnen in einer separaten\n\
Nachricht geschickt.\n"
30	"Ihre EMail-Adresse wurde nicht in der Liste %s gefunden.\n\
Haben Sie sie vielleicht unter einer anderen Adresse abonniert?\n"
31	"Sie wurden aus der Liste %s ausgetragen.\n\
Danke, daß Sie diese Liste abonniert hatten.\n"
32	"\
Nur Verwalter der Liste %s können Abonnenten hinzufügen oder löschen.\n\
Sie dürfen diesen Befehl nicht benutzen, oder die zu Ihrer Identifikation\n\
nötigen Informationen fehlen."
33	"Die EMail-Adresse %s konnte nicht in der Liste gefunden werden.\n"
34	"Sie sind vom Verwalter %s aus der Liste ausgetragen worden.\n\
Dies geschieht normalerweise, wenn Nachrichten an eine Adresse\n\
nicht zugestellt werden können. Wenn Ihre Adresse korrekt ist,\n\
entschuldigen Sie bitte die Unannehmlichkeiten und erneuern\n\
Sie Ihr Abonnement.\n"
35	"Das Archiv wird Ihnen in einer separaten Nachricht zugeschickt.\n"
36	"Angaben zum Benutzer %s wurden für die Liste %s aktualisiert.\n"
37	"Der Benutzer %s ist jetzt Mitglied der Liste %s.\n"
38	"Der Benutzer %s wurde aus der Liste %s gelöscht.\n"
39	"\
Jemand (hoffentlich Sie) hat darum gebeten, daß jemand zur\n\
Liste %s hinzugefügt oder aus ihr entfernt wird.\n\n\
Bitte bestätigen Sie diesen Befehl, indem Sie eine Mail an\n\
%s schicken, die den Befehl\n\n\
   %s\n\n\
enthält. Wenn der Befehl nicht ausgeführt werden soll, ignorieren\n\
Sie diese Nachricht einfach.\n"
40	"Ihre Einstellungen für die Liste %s wurden aktualisiert.\n"
41	"Freizugebende Nachricht für Liste %s mit Schlüssel\n\
%s nicht gefunden.\n\
Die Nachricht wurde eventuell schon von einem anderen Moderator\n\
freigegeben.\n"
43	"Nachricht für Liste %s gelöscht.\n"
44	"Nachricht für Liste %s wurde verteilt.\n"
45	"Die Liste %s erlaubt den DIGEST-Modus nicht. Ihre Einstellungen\n\
bezüglich des Modus wurden nicht geändert.\n"
46	"Der MODINDEX-Befehl darf nur von Moderatoren benutzt werden.\n\
Sie sind kein Moderator der Liste %s.\n"
47	"Die Befehle EXPIRE, EXPIREINDEX und EXPIREDEL dürfen nur von\n\
Verwaltern einer Liste benutzt werden.\n\
Sie sind kein Verwalter der Liste %s.\n"
48	"\
Jemand (hoffentlich Sie) hat darum gebeten, daß alle, die die Liste\n\
'%s' seit mehr als %d Tagen abonniert haben, Ihr Abonnement bestätigen\n\
müssen.\n\
\n\
Wenn das nicht passieren soll, ignorieren Sie diese Nachricht einfach.\n\
Um den Befehl auszuführen, schicken Sie eine EMail an '%s', die den\n\
folgenden Befehl enthält:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Für die Liste %s läuft bereits ein EXPIRE-Befehl, der vom Verwalter\n\
%s (%s) gestartet wurde.\n\
\n\
Für eine Liste kann jeweils nur ein EXPIRE-Befehl laufen. Der\n\
aktuelle Befehl betrifft alle, die seit mehr als %d Tagen Mitglied\n\
der Liste sind und ihr Abonnement nicht bestätigt haben. Er läuft\n\
noch für %d Tag(e) (%s).\n"
52	"Adressen, für die %s keine Bestätigung bekommen hat:\n"
53	"Um den EXPIRE-Befehl zu stoppen: EXPIREDEL %s\n"
54	"Für die Liste %s läuft im Moment kein EXPIRE-Befehl.\n"
55	"Sie haben den EXPIRE-Befehl für die Liste %s gestoppt.\n"
56	"Ein EXPIRE-Befehl für Liste %s wurde gestartet. Dieser Befehl\n\
läuft %d Tage. Sie werden eine Liste der Mitglieder erhalten,\n\
die ihr Abonnement nicht bestätigt haben, und können dann diese\n\
Abonnenten mit dem DEL-Befehl löschen.\n"
57	"Um die Liste der Mitglieder anzuzeigen, die ihr\n\
Abonnement nicht bestätigt haben: EXPIREINDEX %s\n"
58	"Sie können diese Abonnenten mit den folgenden Befehlen\n\
aus der Liste löschen:\n"
60	"\
Der EXPIRE-Befehl konnte nicht ausgeführt werden. Dem Befehl muß ein\n\
erklärender Text folgen, der für die Mitglieder bestimmt ist, die ihr\n\
Abonnement erneuern sollen.\n\
Dieser Text muß\n\
- in der ersten Zeile nach dem EXPIRE-Befehl beginnen,\n\
- aus mindestens 20 Worten bestehen und\n\
- mit dem Wort QUIT enden.\n"
61	"Deshalb wurde die Nachricht an Sie zurückgeschickt:\n"
67	"Sie haben im Moment diese Listen abonniert:\n\n"
68	"Kann auf die Nachricht mit dem Schlüßel %s nicht zugreifen.\n"
69	"%s hat Ihre EXPIRE-Nachricht an folgende Adressen geschickt:\n"
70	"\nPowered by Sympa %s : http://listes.cru.fr/sympa/\n"
71	"Abonnement der Liste %s aufheben"
72	"\n\nListen, die Sie verwalten:\n\n"
73	"\n\nListen, die Sie moderieren:\n\n"
74	"Authentifizierung angefordert von %s für Befehl %s\n"
75	"Erlaube, %s aus jeder Liste auszutragen\n"
76	"Erinnerung an Ihr Abonnement der Liste %s"
77	"Sie sind Mitglied der Liste %s unter der Adresse %s\n"
78	"Erinnerung verschickt an jeden der %d %s Abonnenten\n"
79	"\
Jemand (hoffentlich Sie) hat Sympa darum gebeten, eine Erinnerung\n\
an jeden Abonnenten der Liste %s zu schicken.\n\
\n\
Wenn der Befehl ausgeführt werden soll, schicken Sie bitte eine\n\
EMail an %s mit dem Befehl\n\n\
   %s\n\n\
Ansonsten ignorieren Sie diese Nachricht einfach.\n"
80	"Sie dürfen den Befehl %s für die Liste %s nicht ausführen\n"
81	"Anleitung"
82	"Öffentliche Mailing-Listen"
83	"Zusammenfaßung"
84	"Der Benutzer '%s' ist bereits Abonneten der Liste '%s'\n"
85	"Benutzer %s wurde eingeladen die Liste %s zuabonnieren.\n"
86	"Der Benutzer '%s' ist gegen seinen Willen auf '%s'\n"
90	"Liste %s erlaubt nur die folgenden Empfangsmodi: %s \n\
Ihre Konfiguration wurde nicht modifiziert.\n"
91	"Die Liste %s ermöglicht keine Abonneteneinstellung.\n"
92	"Änderung Ihrer Einstellungen für Liste %s ist fehlgeschlagen.\n"
260	"\
Jemand (hoffentlich Sie) hat darum gebeten, daß Ihre EMail-Adresse\n\
zur Liste '%s' hinzugefügt wird.\n\
Wenn Sie die Liste abonnieren wollen,\n\
\n\
- antworten Sie auf diese Nachricht\n\
ODER\n\
- schicken Sie eine Nachricht an %s mit dem\n\
  Betreff: %s\n\
ODER\n\
- klicken Sie diesen Link: %s\n\
\n\
Wenn es sich um einen Irrtum handelt, ignorieren Sie diese\n\
Nachricht einfach.\n"
261	"\
Jemand (hoffentlich Sie) hat darum gebeten, daß Ihre EMail-Adresse\n\
aus der Liste '%s' gelöscht wird.\n\
Wenn Sie das Abonnement aufheben wollen,\n\
\n\
- antworten Sie auf diese Nachricht\n\
ODER\n\
- schicken Sie eine Nachricht an %s mit dem\n\
  Betreff: %s\n\
ODER\n\
- klicken Sie diesen Link: %s\n\
\n\
Wenn es sich um einen Irrtum handelt, ignorieren Sie diese\n\
Nachricht einfach.\n"
262	"Die S/MIME-Signature wurde erfolgreich überprüft"
263	"Die Nachricht nicht vom Typ multipart/signed or Sympa konnte die\n\
Signature nicht überprüfen (Sympa kann Signatures nicht prüfen, wenn ein Kommando im Subject benutzt wird)."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Verwalter der Liste %s"
2	"Abo-Wunsch für die Liste %s"
3	"Ein Benutzer hat darum gebeten, als Mitglied in die Liste %s\n\
aufgenommen zu werden. Wenn das in Ordnung ist, können Sie ihn mit dem\n\
folgenden Befehl zur Liste hinzufügen:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
6	"Willkommen bei %s!"
7	"Datei"
9	"Zusammenfaßung für Liste %s"
12	"Um die angeh"angte Nachricht über Liste %s zu verteilen:\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Oder: Schicken Sie eine Nachricht an %s mit folgendem Subject:\n\
CONFIRM %s\n"
13	"Inhaltsverzeichnis" 
14	"Ende der Zusammenfaßung für Liste %s"
15	"%d Nachrichten in Liste %s müssen überprüft werden" 
16	"Authentifizierung erforderlich"
21	"Zur Information: %s list %s von %s %s"
22	"Zur Information: Befehl %s list %s von %s %s\n(kein Eingreifen nötig)\n"
23	"WARNUNG: %s %s konnte das Abonnement der Liste %s nicht aufheben,\n\
weil die Adresse nicht gefunden wurde.\n\
(Sie können diesem Benutzer vielleicht helfen.)\n"
24	"UNsubscription-Befehl für Liste %s"
25	"Lieber Verwalter der Liste %s,\n\n\
ein Benutzer hat darum gebeten, daß sein Abonnement der Liste aufgehoben\n\
wird. Wenn das in Ordnung ist, können Sie ihn mit dem folgenden Befehl\n\
aus der Liste löschen:\n\n\
DEL %s %s\n"
26	"Zur Information: Der Befehl %s list %s von %s %s\n\
wurde von %s bestätigt. (kein Eingreifen nötig)\n"
27	"Der Anteil ungültige Mailadressen in Liste %s beträgt %d%%.\n\n\
Sie sollten die ungültigen Adressen löschen:\n\
%s/reviewbouncing/%s"
28	"WARNUNG: Zu viele ungültige Mailadressen in Liste %s"
29	"Einladung für Liste %s"
30	"Sie sind eingeladen worden, die Liste %s zu abonnieren"
31	"Zusammenfaßung von Liste %s"

$set 11	Messages used by the smtp module.
1	"Ihr System folgt nicht dem POSIX P1003.1 Standard oder\n\
Ihre Perl-Version definiert in der POSIX-Bibliothek die Konstante\n\
_SC_ARG_MAX nicht. Sie müssen das smtp.pm-Modul anpaßen und der\n\
Variablen $max_arg einen Wert zuweisen.\n"
2	"smtpto konnte keinen Kanal öffnen: %m"

$set 12 MIME headers
1	"1.0"
2	"iso-8859-1"
3	"8bit"
4	"SYMPA <%s>"

$set 14 Pour le web
1	"de_DE"
2	"deutsch"

$set 15 Templates files
1	"Begrüßungsnachricht"
2	"Abmeldungsnachricht"
3	"Löschnachricht"
4	"Nachrichtungenfuß"
5	"Nachrichtenkopf"
6	"Erinnerungsnachricht"
7	"Moderator-Ablehnungs-Nachricht"
8	"Einladungsnachricht"
9	"Hilfstext"
10	"Mailing-Listen-Übersicht"
11	"Globale Erinnerungsnachricht"
12	"Zusammenfaßungsnachricht"
13	"Listenbeschreibung"
14	"Listen-Homepage"
15	"Listen-Erzeugungs-Anfrage"
16	"Listen-Erzeugungs-Bestätigung"
17	"Virus-verseuchte Nachricht"

$set 16 parameters titles
1	"Benutzerkennung"
2	"Wer kann Abonnenten hinzufügen"
3	"Anonymer Absender"
4	"Archiv"
5	"Häufigkeit"
6	"Zugriffsrechte"
7	"Unzustellbare Nachrichten"
8	"Warnungrate"
9	"Stoprate"
10	"Verfall unmoderierter Nachrichten"
11	"Geheimer Wert zum Erzeugen eindeutiger Schlüssel"
12	"Erzeugung der Liste"
16	"Angepaßte Kopfzeile"
17	"Titel-Markierung (Subject)"
18	"Abonnierungsprofil"
19	"Empfangsmodus"
20	"Sichbarkeit"
21	"Wer kann Abonnenten löschen"
22	"Häufigkeit der Zusammenfaßungen"
23	"Tage"
24	"Stunde"
25	"Minute"
26	"Moderatoren"
27	"EMail-Adresse"
28	"Empfangsmodus"
29	"Name"
30	"private Information"
31	"Anlagentyp"
32	"Feste Antwortadresse"
33	"Hostname"
34	"Datei einbeziehen"
35	"LDAP-Anfrage einbeziehen"
36	"entfernter Rechner"
37	"Port auf entferntem Rechner"
38	"Benutzer auf entferntem Rechner"
39	"Passwort auf entferntem Rechner"
40	"Endung"
41	"Filter"
42	"extrahiertes Attribut"
43	"Auswahl (falls mehrere)"
44	"Liste einbeziehen"
45	"SQL-Abfrage einbeziehen"
46	"Datenbanktyp"
47	"entfernter Rechner"
48	"Datanbankname"
49	"entfernter Benutzer"
50	"entferntes Passwort"
51	"SQL-Abfrage"
53	"Wer kann Listen-Information ansehen"
54	"Wer kann neue Abonneten einladen"
55	"Sprache"
56	"Maximale Nachrichtengröße"
57	"Besitzer"
58	"Email-Adresse"
59	"Empfangsmodus"
60	"Name"
61	"private Information"
62	"Profil"
63	"Priorität"
64	"Wer kann Erinnerungen veranlassen"
65	"Rücklaufpfad für Erinnerungen"
66	"Antwortadresse"
67	"Wer kann Abonneten überprüfen"
68	"Wer kann Nachrichten verschicken"
69	"Seriennummer der Konfiguration"
70	"Gemeinsame Dokumente"
71	"Status der Liste"
72	"Titel der Liste"
73	"Wer kann die Liste abonnieren"
74	"Thema der Liste"
75	"Timeout bei Einfügung"
76	"Wer kann abbestellen"
77	"Letze Konfigurationsänderung"
81	"Benutzerdatenquelle"
82	"Sichbarkeit der Liste"
83	"Web-Archiv"
84	"Zugriffsrechte"
85	"Rücklaufpfad für Begrüßungen"
86	"Wer kann anschauen"
87	"Wer kann editieren"
88	"Verfügbare Abonnement-Optionen"
89	"Empfangsmodus"
90	"Antwort-Adresse"
91	"Wert"
92	"Andere EMail-Adresse"
93	"Berücksichtung existierender Felder im Nachrichtenkopf"
94	"Verbindungseinstellungen"

$set 17 Cookie expiration periods
1	"Sitzung"
2	"10 Minuten"
3	"30 Minuten"
4	"1 Stunde"
5	"6 Stunden"
6	"1 Tag"
7	"1 Woche"

