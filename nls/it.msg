$ 20 Mar 2000, improvements by Alberto Pasquale <techlist@pianeta.it>
$ 16 Feb 2000, Initial version by Marco Ferrante <ferrante@unige.it>

$ codeset=iso-8859-1
$quote "

$set 1	Messages used while processing the configuration file
1	"Il file di configurazione contiene degli errori.\n"
3	"Errore alla linea %d : %s"
102	"2.5.4"

$set 2	Messages used by Conf when verifying the files

$set 3	Misc. messages in the main program
1	"Impossibile accedere alla directory %s : %m"

$set 4	Messages used in the main loop
11	"Il suo messaggio a %s e' stato rifiutato"
12	"Il suo messaggio non puo' essere inoltrato perche' le dimensioni eccedono quelle ammesse in questa lista.\n"
15	"Lei ha provato a inviare un messaggio a una lista chiusa senza essere iscritto alla lista.\n\n\
Il messaggio che ha provato ad inviare e':\n"
17	"Risultati dei comandi"
18	"Comando QUIT trovato: ignorato il resto del messaggio.\n"
19	"Comando non riconosciuto: ignorato il resto del messaggio.\n"
24	"Scadenza del comando EXPIRE sulla lista %s"
26	"Questi iscritti sono :\n"
27	"Se vuole rimuovere questi iscritti dalla lista, usi i seguenti comandi:\n"
28	"Degli iscritti alla lista %s da %d giorni, %d non hanno confermato la propria iscrizione.\n"
37	"Messaggio di comando ignorato perche' non in text/plain.\n\
Utilizzare solo text/plain (o mettere il comando nel soggetto).\n"
38	"Il suo messaggio per la lista %s e' stato trasmesso al(ai) moderatore(i)\n"

$set 5	Messages used in the tools module
1	"Safefork non puo' creare un nuovo processo : %m"
2	"Possibile errore di indirizzo"
3	"Il seguente messaggio e' stato inviato alla lista, ma sembra\n\
contenere dei comandi come SUBSCRIBE, SIGNOFF, HELP, ...\n\n\
I comandi possono essere inviati solo al server di liste %s.\n\n\
Se il messaggio era effettivamente destinato alla lista, e' stato\n\
interpretato dal programma come un comando: contattare il gestore\n\
del servizio %s per la soluzione del problema.\n\n\
Grazie per l'attenzione.\n\n\
------ Inizio del messaggio originale ------\n"
4	"------ Fine del messaggio originale ------\n"

$set 6	Messages du module Commands.pm
2	"Il file di guida non e' disponibile: %s\n"
5	"La lista '%s' non esiste.\n"
7	"L'archivio di questa lista non contiene alcun file.\n"
8	"Il file richiesto non e' disponibile.\n"
9	"Questa lista e' chiusa: impossibile leggere l'archivio.\n"
10	"Questa lista e' chiusa: impossibile elencare i messaggi archiviati.\n"
11	"Questa lista e' chiusa: impossibile elencare gli iscritti.\n"
12	"Iscritti alla lista : %d\n"
13	"Errore di sintassi nel comando.\n"
15	"Procedura di autenticazione fallita.\n\n"
16	"Lei ha probabilmente confermato l'iscrizione usando un'indirizzo differente\n\
da quello usato per la richiesta. Verificare l'indirizzo usato."
18	"La sua iscrizione alla lista %s e' stata cancellata."
21	"Rinnovo della sua iscrizione alla lista '%s'"
24	"L'iscrizione alla lista e' temporaneamente sospesa.\n"
25	"La sua richiesta di iscrizione/cancellazione alla lista e' stata inoltrata al gestore per l'approvazione.\n\
Ricevera' una notifica quando l'operazione verra' effettuata.\n"
26	"La funzione di cancellazione dell'iscrizione non e' disponibile per la lista '%s'.\n"
27	"Le informazioni sulla sua iscrizione sono state aggiornate.\n"
28	"Lei e' ora iscritto alla lista %s.\n"
29	"Le informazioni su questa lista saranno inviate in un messaggio separato.\n"
30	"L'indirizzo %s non e' stato trovato nella lista %s.\n\
E' possibile che lei sia iscritto con un indirizzo differente ?\n"
31	"Lei e' stato rimosso dalla lista %s.\n\
Grazie per aver usato questa lista.\n"
32	"Solo i gestori della lista %s possono aggiungere o rimuovere gli iscritti.\n\
Lei non e' autorizzato a usare questo comando o non ha fornito le informazioni necesssarie\n\
alla sua identificazione.\n"
33	"L'indirizzo %s non e' presente nella lista.\n"
34	"Lei e' stato rimosso dalla lista %s \n\
da %s, gestore di questa lista.\n\n\
Questo solitamente avviene in seguito a numerosi messaggi di errore\n\
sulla sua casella di posta.\n\
Se il suo indirizzo funziona correttamente, scusi per il disagio\n\
e, eventualmente, rinnovi l'iscrizione.\n"
35	"L'archivio verra' inviato in un messaggio separato.\n"
36	"Le informazioni sull'utente %s sono state aggiornate per la lista '%s'.\n"
37	"L'utente %s e' stato iscritto alla lista '%s'.\n"
38	"L'utente %s e' stato rimosso dalla lista %s/\n"
39	"Qualcuno (probabilmente lei) ha richiesto l'iscrizione o la cancellazione di un \n\
utente alla/dalla lista '%s'.\n\n\
Per confermare l'azione, invii un messaggio a %s contenente \n\n\
   %s\n\n\
Se non vuole proseguire nell'azione, ignori questo messaggio.\n"
40	"La sua configurazione relativa alla lista '%s' e' stata aggiornata.\n"
41	"Impossibile accadere al messaggio da moderare sulla lista '%s' con l'identificatore %s.\n\
Il messaggio potrebbe gia' essere stato approvato da uno degli altri moderatori della lista.\n"
43	"Il messaggio per la lista '%s' e' stato rimosso.\n"
44	"Il messaggio per la lista '%s' e' stato distribuito.\n"
45	"La lista '%s' non accetta il modo DIGEST. Il relativo comando di configurazione e' stato ignorato.\n"
46	"Il comando MODINDEX puo' essere usato solo dai moderatori della lista '%s'.\n"
47	"I comandi EXPIRE, EXPIREINDEX e EXPIREDEL possono essere usati solo dai gestori della lista '%s'.\n"
48	"\
Qualcuno (probabilmente un gestore) ha richiesto che gli iscritti alla lista\n\
'%s' da piu' di %d giorni riconfermino la loro iscrizione.\n\
Se lei non vuole rinnovare l'iscrizione, ignori semplicemente questo messaggio.\n\
Per confermarla, invii un messaggio a '%s', con il seguente comando nel soggetto:\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Un comando di EXPIRE e' gia' in esecuzione per la lista %s.\n\
E' stato lanciato dal gestore %s (%s)\n\
Non puo' esserci piu' di un processo di scadenza alla volta per una lista.\n\
Il processo corrente e' per le persone iscritte da piu'\n\
di %d giorni e che non hanno riconfermato la propria iscrizione. Il processo\n\
finira' fra %d giorni (%s).\n"
52	"%s non ha ricevuto conferma per i seguenti indirizzi :\n"
53	"Per fermare il processo di scadenza : EXPIREDEL %s\n"
54	"La lista %s non ha correntemente in corso nessun processo di scadenza.\n"
55	"Il processo di scadenza per la lista %s e' stato arrestato.\n"
56	"\
E' stato avviato un processo di scadenza per la lista %s . Il processo\n\
terminira' tra %d giorni. Lei ricevera' la lista degli utenti \n\
che non hanno riconfermato la propria iscrizione in tempo.\n\
Potra' rimuovere questi indirizzi con il comando DEL.\n"
57	"Per leggere la lista degli utenti che non hanno riconfermato la propria\n\
iscrizione: EXPIREINDEX %s\n"
58	"Lei puo' rimuvere questi iscritti dalla lista con i seguenti comandi:\n"
60	"\
Il comando EXPIRE non puo' essere eseguito. Deve essere seguito da un testo\n\
esplicativo per aiutare gli utenti che intendono confermare la propria iscrizione.\n\
Questo testo deve\n\n\
 - iniziare alla riga immediatamente successiva a quella del comando EXPIRE\n\
 - contenere almeno 20 parole\n\
 - terminare con il comando 'QUIT'\n"
61	"Il messaggio le e' stato rispedito indietro:\n"
67	"Lei e' attualmente iscritto alle liste:\n\n"
68	"Accesso impossibile al messaggio identificato dalla chiave %s.\n"
69	"%s ha inviato il messaggio di scadenza ai seguenti indirizzi:\n"
70	"\nPowered by Sympa %s : http://www.sympa.org/\n"
71	"Cancellazione dalla lista '%s'"
72	"\n\nListe di cui lei e' gestore:\n\n"
73	"\n\nListe di cui lei e' moderatore:\n\n"
74	"E' stata inviata a %s la richiesta di autenticazione per il comando %s\n"
75	"Impossibile alcuna cancellazione di iscrizione per l'indirizzo %s\n"
76	"Riconferma della sua iscrizione alla lista %s"
77	"Lei e' iscritto alla lista %s con l'indirizzo %s.\n"
78	"Notifica di iscrizione spedita ai %d utenti di %s.\n"
79	"Qualcuno (probabilmente un gestore) ha chiesto di comunicare a tutti gli\n\
iscritti alla lista %s lo stato della propria iscrizione\n\n\
Per confermare l'operazione, reinvii per favore un messaggio\n\
all'indirizzo %s contenente: \n\n\
   %s\n\n\
Per annullare l'operazione, ignori semplicemente questo messaggio.\n"
80	"Lei non e' abilitato a eseguire il comando %s per la lista '%s'\n"
81	"Istruzioni"
82	"Liste Pubbliche"
83	"Riassunto delle sue iscrizioni"
84	"L'utente '%s' e' gia' iscritto alla lista '%s'.\n"
85	"L'utente '%s' e' stato invitato a iscriversi alla lista '%s'.\n"
86	"L'utente '%s' e' indesiderato nella lista '%s'.\n"
260	"Qualcuno (probabilmente lei) ha richiesto la sua iscrizione alla lista '%s'.\n\
Per confermare questa operazione:\n\
\n\
- risponda con un reply a questo messaggio\nO\n\
- invii un messaggio a '%s' con l'oggetto\n%s\nO\n\
- segua il seguente link %s\n\n\
Per non confermare, ignori semplicemente questo messaggio."
261	"Qualcuno (probabilmente lei) ha richiesto la sua cancellazione dalla lista '%s'.\n\n\
Per confermare la cancellazione:\n\
\n\
- risponda con un reply a questo messaggio\nO\n\
- invii un messaggio a '%s' con l'oggetto\n%s\nO\n\
- segua il seguente link %s\n\n\
Per non confermare, ignori semplicemente questo messaggio."

$set 7	Commands syslog messages (Commands.pm)

$set 8	Messages used in List.pm
1	"Gestore della lista %s"
2	"Richiesta di iscrizione alla lista %s"
3	"Gentili gestori della lista %s,\n\n\
Un utente ha chiesto di essere iscritto alla vostra lista.\n\
Per acconsentire, inviare il comando:\n\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n"
6	"Benvenuto nella lista '%s'"
7	"File"
9	"Riassunto della lista '%s'"
13	"Sommario"
14	"Fine del riassunto della lista '%s'"
16	"Autenticazione richiesta"
21	"FYI: %s lista %s da %s %s"
22	"FYI: comando %s nella lista %s da %s %s \n (nessuna azione richiesta)\n"
23	"ATTENZIONE: %s %s non e' riuscito a cancellarsi dalla lista %s\n(Forse ha bisogno di aiuto)"
24	"Richiesta di cancellazione dalla lista '%s'"
25	"Gentili gestori della lista '%s',\n\n\
Un utente ha chiesto di essere cancellato dalla vostra lista. \n\
Per acconsentire, invii il seguente comando:\n\n\
DEL %s %s\n"
26	"FYI: comando %s nella lista %s da %s %s validato da %s\n (nessuna azione richiesta)\n"
27	"Il tasso di messaggi respinti nella lista %s e' del %d%%.\n\n\
Dovrebbe cancellare gli iscritti : \n\
%s/reviewbouncing/%s"
28	"ATTENZIONE: tasso di messaggi respinti troppo elevato nella lista %s"
29	"Invito nella lista %s"
30	"Lei e' invitato a iscriversi alla lista %s"

$set 9	Messages for the review header
1	"Gestore               : %s\n"
2	"Moderatore            : %s\n"
3	"Iscrizione            : %s\n"
4	"Iscrizione cancellata : %s\n"
5	"Invio di messaggi     : %s\n"
6	"Lista degli iscritti  : %s\n"
7	"Rispondere a          : %s\n"
8	"Dimensione massima    : %d\n"
9	"URL della lista       : %s\n"
10	"Riassunto             : %s\n"
11	"Oggetto personalizzato: %s\n"
12	"Oggetto               : %s\n"

$set 11	Messages used by the smtp module.
1	"Il suo sistema non sembra conforme allo standard POSIX P1003.1, oppure\n\
il suo sistema Perl non ha definito la costante _SC_ARG_MAX nella libreria\n\
POSIX. E' necessario che modifichi il modulo smtp.pm per fissare un\n\
valore per la variabile $max_arg.\n"
2	"Impossibile creare un canale in smtpto: %m"

$set 12 MIME headers
1	"1.0"
2	"iso-8859-1"
3	"8bit"
4	"SYMPA <%s>"

