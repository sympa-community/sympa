
		  SYMPA -- Mailing List Manager

	     		Guida utente

SYMPA e' un gestore di liste di posta elettronica.
Permette di automatizzare le funzioni di gestione delle liste:
iscrizioni, cancellazioni, moderazione, archiviazione.

Tutti i comandi devono essere inviati all'indirizzo
  [conf->sympa]

E'  possibile  inserire piu' di un comando in ciascun messaggio:
i comandi devono essere scritti nel corpo del messaggio, uno per riga.

Il formato deve essere text/plain: se proprio siete fanatici dei
messaggi "multipart" o "text/html", potete inserire un comando
nell'oggetto del messaggio.

Elenco dei comandi:

  HELp                  * Questo file di istruzioni

  LISts                 * Lista delle liste gestite da questo server

  REView <list>         * Elenco degli iscritti

  WHICH                 * Mostra in quali liste sei iscritto

  SUBscribe <list> [Nome Cognome]
                        * Iscrizione

  SIGnoff <list|*> [user->email]
                        * Cancellazione dalla lista o da tutte le liste

  SET <list|*> NOMAIL   * Sospende la ricezione dei messaggi

  SET <list|*> DIGEST   * Ricezione dei messaggi in modo aggregato

  SET <list|*> SUMMARY  * Receiving the message index only

  SET <list|*> MAIL     * Ricezione dei messaggi in modo normale

  SET <list> CONCEAL    * Nasconde il proprio indirizzo dall'elenco
                          ottenuto col comando REV

  SET <list> NOCONCEAL  * Rende visibile il proprio indirizzo
                          nell'elenco ottenuto col comando REV

  INFO <list>           * Informazioni sulla lista

  INDex <list>          * Indice dei file di archivio

  GET <list> <file>     * Scarica il <file> dall'archivio

  LAST <list>           * Prende l'ultimo messaggio

  INVITE <list> <email> * Invita l'utente <email> a iscriversi

  CONFIRM <key>         * Conferma per l'invio di un messaggio (dipende
                          dalla configurazione della lista)

  QUIT                  * Fine dei comandi (per ignorare la firma)

[IF is_owner]
Comandi riservati ai gestori delle liste:

 ADD <list> user@host [Nome Cognome]
                        * Aggiunge l'utente

 DEL <list> user@host   * Cancella l'utente

 STATS <list>           * Consulta le statistiche

 EXPire <list> <old> <delay>
                        * Inizia un processo di scadenza per gli utenti
                          che non hanno confermato l'iscrizione da <old>
                          giorni.
                          Restano <delay> giorni per confermare.

 EXPireINDex <list>     * Mostra lo stato del processo di scadenza
                          corrente per la lista <list>

 EXPireDEL <list>       * Annulla il processo di scadenza per la lista

 REMIND <list>          * Invia a ciascun utente un messaggio
                          personalizzato per ricordare con quale
                          indirizzo e' iscritto
[ENDIF]

[IF is_editor]


Comandi riservati ai moderatori delle liste:

 DISTribute <list> <key>
                        * Moderazione: convalida di messaggio

 REJect <list> <key>    * Moderazione: rifiuto di messaggio

 MODINDEX <list>        * Moderazione: consultazione dell'elenco dei
                          messaggi da moderare
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
