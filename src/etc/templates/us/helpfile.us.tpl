[IF  user->lang=fr]

              SYMPA -- Systeme de Multi-Postage Automatique
 
                       Guide de l'utilisateur


SYMPA est un gestionnaire de listes electroniques. Il permet d'automatiser
les fonctions de gestion des listes telles les abonnements, la moderation
et la gestion des archives.

Toutes les commandes doivent etre adressees a l'adresse electronique
[conf->sympa]

Il est possible de mettre plusieurs commandes dans chaque message : les
commandes doivent apparaitre dans le corps du message et chaque ligne ne
doit contenir qu'une seule commande. Sympa ignore le corps du message
si celui-ci n'est de type "Content-type: text/plain", mais même si vous
etes fanatique d'un agent de messagerie qui fabrique systematiquement des
messages "multipart" ou "text/html", les commandes placees dans le sujet
du messages sont reconnues.

Les commandes disponibles sont :

 HELp	                     * Ce fichier d'aide
 LISts	                     * Annuaire des listes geres sur ce noeud
 REView <list>               * Connaitre la liste des abonnes de <list>
 WHICH                       * Savoir à quelles listes on est abonné
 SUBscribe <list> Prenom Nom * S'abonner ou confirmer son abonnement a la 
			       liste <list>
 SIGnoff <list|*> [user->email]    * Quitter la liste <list>, ou toutes les listes.
                               Où [user->email] est facultatif

			     Mise à jour du mode de reception:	
 SET <list|*> MAIL           * Reception de la liste <list> en mode normal
 SET <list|*> NOMAIL         * Suspendre la reception des messages de <list>
 SET <list|*> DIGEST         * Reception des message en mode compilation
 SET <list|*> SUMMARY        * Reception de la liste des messages uniquement
 SET <list|*> NOTICE         * Reception de l'objet des messages uniquement
 SET <list|*> TXT            * Reception uniquement au format texte pour les messages émis 
			       conjointement en HTML et en texte simple.
 SET <list|*> HTML           * Reception uniquement au format HTML pour les messages émis 
			       conjointement en HTML et en texte simple. 
 SET <list|*> URLIZE	     * Remplacement des attachements par une URL
 SET <list|*> NOT_ME         * Ne pas recevoir les messages dont je suis l'auteur


			     Mise à jour de la visibilite:	
 SET <list|*> CONCEAL        * Passage en liste rouge (adresse d'abonné cachée)
 SET <list|*> NOCONCEAL      * Adresse d'abonné visible via REView

 INFO <list>                 * Informations sur une liste
 INDex <list>                * Liste des fichiers de l'archive de <list>
 GET <list> <fichier>        * Obtenir <fichier> de l'archive de <list>
 LAST <list>		     * Obtenir le dernier message de <list>
 INVITE <list> <email>       * Inviter <email> a s'abonner à <list>
 CONFIRM <clef>	 	     * Confirmation pour l'envoi d'un message
			       (selon config de la liste)
 QUIT                        * Indique la fin des commandes (pour ignorer 
                               une signature

[IF is_owner]
Commandes réservées aux propriétaires de listes:
 
 ADD <list> user@host Prenom Nom * Ajouter un utilisateur a une liste
 DEL <list> user@host            * Supprimer un utilisateur d'une liste
 STATS <list>                    * Consulter les statistiques de <list>
 EXPire <list> <ancien> <delai>  * Déclanche un processus d'expiration pour
                                   les abonnés à la liste <list> n'ayant pas
				   confirmé leur abonnement depuis <ancien>
				   jours. Les abonnés ont <delai> jours pour
				   confirmer
 EXPireINDex <list>              * Connaitre l'état du processus d'expiration
                                   en cours pour la liste <list>
 EXPireDEL <list>                * Désactive le processus d'espiration de la
                                   liste <list>

 REMind <list>                   * Envoi à chaque abonné un message
                                   personnalisé lui rappelant
                                   l'adresse avec laquelle il est abonné.
[ENDIF]

[IF is_editor]

Commandes réservées aux modérateurs de listes :

 DISTribute <list> <clef>        * Modération : valider un message
 REJect <list> <clef>            * Modération : invalider un message
 MODINDEX <list>                 * Modération : consulter la liste des messages
                                   à modérer
[ENDIF]

[ELSIF user->lang=it]

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

[ELSIF user->lang=de]

              SYMPA -- Systeme de Multi-Postage Automatique
                         (Automatisches Mailing System)

                             Benutzungshinweise


--------------------------------------------------------------------------------
SYMPA ist ein elektronischer Mailing-Listen-Manager, der Funktionen zur Listen-
verwaltung automatisiert, wie zum Beispiel Abonnieren, Moderieren und Verwalten 
von Mail-Archiven.

Alle Kommandos muessen an die Mail-Adresse [conf->sympa] geschickt werden.

Sie koennen mehrere Kommandos in einer Nachricht abschicken. Diese Kommandos
muessen im Hauptteil der Nachricht stehen und jede Zeile darf nur ein Kommando 
enthalten. Der Mail-Hauptteil wird ignoriert, wenn der Content-Type nicht 
text/plain ist. Sollten Sie ein Mail-Programm verwenden, das jede Nachricht 
als Multipart oder text/html sendet, so kann das Kommando alternativ in der 
Betreffzeile untergebracht werden.

Verfuegbare Kommandos:

 HELp                        * Diese Hilfedatei
 INFO                        * Information ueber die Liste
 LISts                       * Auflistung der verwalteten Listen
 REView <list>               * Anzeige der Abonnenten der Liste <list>
 WHICH                       * Anzeige der Listen, die Sie abonniert haben
 SUBscribe <list> <GECOS>    * Abonnieren bzw. Bestaetigen eines Abonnements
                               der Liste <list>, <GECOS> ist eine zusaetzliche
                               Information ueber den Abonnenten
 UNSubscribe <list> <EMAIL>  * Abbestellen der Liste <list>. <EMAIL> kann
                               optional angegeben werden. Nuetzlich, wenn
                               verschieden von Ihrer "Von:"-Adresse.
 UNSubscribe * <EMAIL>       * Abbestellen aller Listen

 SET <list|*> NOMAIL         * Abonnement der Liste <list> aussetzen
 SET <list|*> DIGEST         * Mail-Empfang im Kompilierungs-Modus
 SET <list|*> SUMMARY        * Receiving the message index only
 SET <list|*> MAIL           * Listenempfang von <list> im Normal-Modus
 SET <list|*> CONCEAL        * Bei Auflistung (REVIEW) Mail-Adresse nicht
                               anzeigen (versteckte Abonnement-Adresse)
 SET <list> NOCONCEAL        * Bei Auflistung (REVIEW) Mail-Adresse wieder
                               sichtbar machen

 INDex <list>                * Auflistung der Dateien im Mail-Archive <list>
 GET <list> <file>           * Datei <file> des Mail-Archivs <list> anfordern
 LAST <list>                 * Used to received the last message from <list>
 INVITE <list> <email>       * Invite user <email> for subscribtion in <list>
 CONFIRM <key>               * Bestaetigung fuer Gueltigkeit der Mail-Adresse
                               (haengt von Konfiguration der Liste ab)
 QUIT                        * Zeigt Ende der Kommandoliste an (wird verwendet
                               zum Ueberlesen der Signatur einer Mail)


[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Die folgenden Kommandos sind nur fuer Eigentuemer bzw. Moderatoren der Listen
zulaessig:

 ADD <list> user@host First Last * Benutzer der Liste <list> hinzufuegen
 DEL <list> user@host            * Benutzer von der Liste <list> entfernen
 STATS <list>                    * Statistik fuer <list> abrufen
 EXPire <list> <old> <delay>     * Ablauffrist fuer Liste <list> setzen fuer
                                   Abonnenten (Subscribers), die nicht inner-
                                   halb von <old> Tagen eine Bestaetigung
                                   schicken. Diese Ablauffrist beginnt erst
                                   nach <delay> Tagen (nach SUBSCRIBE).
 EXPireINDex <list>              * Anzeige des aktuellen Status fuer Ablauf-
                                   fristen der Liste <list>
 EXPireDEL <list>                * Ablauffrist fuer Liste <list> loeschen.

 REMIND <list>                   * Erinnerungsnachricht an jeden Abonnenten
                                   schicken (damit kann jedem Benutzer
                                   mitgeteilt werden, unter welcher
                                   Adresse er die Liste abonniert hat)
[ENDIF]
[IF is_editor]
 DIStribute <list> <clef>        * Moderation: Nachricht ueberpruefen
 REJect <list> <clef>            * Moderation: Nachricht ablehnen
 MODINDEX <list>                 * Moderation: Liste der Nachrichten der zu
                                   moderierenden Nachrichten
[ENDIF]

[ELSIF user->lang=es]
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Sistema Automatico de Listas de Correo)

                                Guía de Usuario


SYMPA es un gestor de listas de correo electrónicas que automatiza las funciones
habituales de una lista como la subscripción, moderación y archivo de mensajes.

Todos los comandos deben ser enviados a la dirección [conf->sympa]

Se pueden poner múltiples comandos en un mismo mensaje. Estos comandos tienen que
aparecer en el texto del mensaje y cada línea debe contener un único comando.
Los mensajes se deben enviar como texto normal (text/plain) y no en formato HTML.
En cualquier caso, los mensajes en el sujeto del mensaje también son interpretados.


Los comandos disponibles son:

 HELp                        * Este fichero de ayuda
 INFO                        * Información de una lista
 LISts                       * Directorio de todas las listas de este sistema
 REView <lista>              * Muestra los subscriptores de <lista>
 WHICH                       * Muestra a qué listas está subscrito
 SUBscribe <lista> <GECOS>   * Para subscribirse o confirmar una subscripción
                               a <lista>.  <GECOS> es información adicional
                               del subscriptor (opcional).

 UNSubscribe <lista> <EMAIL> * Para anular la subscripción a <lista>.
                               <EMAIL> es opcional y es la dirección elec-
                               trónica del subscriptor, útil si difiere
                               de la de dirección normal "De:".

 UNSubscribe * <EMAIL>       * Para borrarse de todas las listas

 SET <lista> NOMAIL          * Para suspender la recepción de mensajes de <lista>
 SET <lista|*> DIGEST        * Para recibir los mensajes recopilados
 SET <lista|*> SUMMARY       * Receiving the message index only
 SET <lista|*> MAIL          * Para activar la recepción de mensaje de <lista>
 SET <lista|*> CONCEAL       * Ocultar la dirección para el comando REView
 SET <lista|*> NOCONCEAL     * La dirección del subscriptor es visible via REView

 INDex <lista>               * Lista el archivo de <lista>
 GET <lista> <fichero>       * Para obtener el <fichero> de <lista>
 LAST <lista>                * Usado para recibir el último mensaje enviado a <lista>
 INVITE <lista> <email>      * Invitación a <email> a subscribirse a <lista>
 CONFIRM <key>               * Confirmación para enviar un mensaje
                               (depende de la configuración de la lista)
 QUIT                        * Indica el fin de los comandos


[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-
Los siguientes comandos son unicamente para los propietarios o moderadores de las listas:

ADD <lista> <email> Nombre Apellido   * Para añadir un nuevo usuario a <lista>
DEL <lista> <email>                   * Para elimiar un usuario de <lista>
STATS <lista>                         * Para consultar las estadísticas de <lista>

EXPire <lista> <dias> <espera>        * Para comenzar un proceso de expiración para
                                        aquellos subscriptores que no han confirmado 
                                        su subscripción desde hace tantos <dias>.
                                        Los subscriptores tiene tantos días de <espera> 
                                        para confirmar.

EXPireINDEx <lista>                   * Muestra el actual proceso de expiración de <lista>
EXPireDEL <lista>                     * Desactiva el proceso de expiración de <lista>

REMIND <lista>                        * Envia un mensaje a cada subscriptor (esto es una
                                        forma de recordar a cualquiera con qué e-mail
                                        está subscrito).

[ENDIF]
[IF is_editor]

 DISTribute <lista> <clave>           * Moderación: para validar un mensaje
 REJect <lista> <clave>               * Moderación: para denegar un mensaje
 MODINDEX <listaa>                    * Moderación: consultar la lista de mensajes a moderar

[ENDIF]

[ELSIF user->lang=pl]
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatyczny System Pocztowy)

	   		     Instrukcja obs³ugi


SYMPA jest automatem odbs³uguj±cym funkcjê zarz±dzania listami takie jak
zapisywanie, wypisywanie, moderacja i obs³uga archiwów list dyskusyjnych.

Wszystkie polecenia musz± byæ wysy³ane pod adres [conf->sympa]

W jednym li¶cie mo¿na umie¶ciæ wiêcej ni¿ jedn± komendê. Musz± siê one 
znajdowaæ w tre¶ci wiadomo¶ci, po jednej na linijkê. Tre¶æ wiadomo¶ci 
nie zostanie wykonana je¿eli zawarto¶æ listu bêdzie inna ni¿ czysty tekst.
(Parametr Content-Type ustawiony na test/plain).
Pomimo tego ograniczenia polecenia mog± byæ umieszczane w temacie wiadomo¶ci.

Dostêpne polecenia:

 HELp                        * Ten plik pomocy
 INFO                        * Informacje o li¶cie
 LISts                       * Spis list na tym serwerze 
 REView <lista>              * Lista zapisanych na listê <lista>
 WHICH                       * Na jakie listy jestem zapisany?
 SUBscribe <lista> <GECOS>   * Zapisz lub potwierd¼ zapisanie na listê
                               <lista>, <GECOS> to dodatkowe informacje 
                               jak imiê i nazwisko.

 UNSubscribe <lista> <EMAIL> * Wypisanie z listy <lista>.<EMAIL> nale¿y
			       podaæ je¿eli adres bêdzie inny ni¿ w polu
			       nadawca tej wiadomo¶ci. 
 UNSubscribe * <EMAIL>       * Wypisanie ze wszystkich list.

 SET <lista|*> NOMAIL        * Zawieszenie zapisania na listê <lista>
 SET <lista|*> DIGEST        * Ustaw tryb odbierania na DIGEST
 SET <lista|*> SUMMARY       * Odbiór tylko spisu wiadomo¶ci z listy
 SET <lista|*> MAIL          * Normalny tryb odbioru listy 
 SET <lista|*> CONCEAL       * Nie pokazuj mojego adresu na li¶cie zapisanych
 SET <lista|*> NOCONCEAL     * Pokazuj mój adres na li¶cie zapisanych


 INDex <lista>               * Lista plików w archiwum
 GET <lista> <plik>          * Pobierz plik z archiwum listy
 LAST <lista>                * Pobierz ostatni list wys³any na listê
 INVITE <lista> <email>      * Zapro¶ <email> do zapisania na listê <lista>
 CONFIRM <key>               * Potwierd¼ wys³anie wiadomo¶ci kluczem
			       (wymagane tylko je¶li ustawienia tego wymagaj±)
 QUIT                        * Koniec bloku poleceñ

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Polecenia zarezerwowane dla osoby administruj±cej lub moderuj±cej list±:

 ADD <lista> user@host Imiê Nazw  * Zapisz na listê adres
 DEL <lista> user@host            * Wypisz adres z listy
 STATS <lista>                    * Statystyki listy <lista>
 EXPire <lista> <old> <delay>     * Rozpoczêcie procesu wypisania adresów
				    nie aktywnych na li¶cie. Osoby które nie
			            potwierdza³y zapisania od <old> dni, maj±
				    <delay> dni czasu aby to zrobiæ.
				    Po up³ywie tego czasu zostan± wypisane.
 EXPireINDex <lista>              * Status procesu potwierdzania 
 EXPireDEL <lista>                * Wy³±czenie procesu potwierdzania dla listy

 REMIND <lista>                   * Wy¶lij polecenie przypomnienia do
				    wszystkich zapisanych. (jest to sposób 
				    na przypomnienie o adresie z ktorego ka¿da
				    osoba jest zapisana). 
[ENDIF]
[IF is_editor]

 DISTribute <lista> <clef>        * Moderacja: potwierd¼ wiadomo¶æ
 REJect <lista> <clef>            * Moderacja: odrzuæ wiadomo¶æ
 MODINDEX <lista>                 * Moderacja: lista wiadomo¶ci wymagaj±cych
				    potwierdzenia.
[ENDIF]

Obs³ugiwane przez Sympa [conf->version] : http://listes.cru.fr/sympa/

[ELSIF user->lang=cz]

              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatic Mailing System)

                          Pøíruèka u¾ivatele


SYMPA elektronický správce konferencí, který automatizuje funkce pro
správu konference jako jsou pøihlá¹ení, moderování a archivace.

V¹echny pøíkazy se musí posílat na adresu [conf->sympa]

Mù¾ete umístit vice pøikazù do jedné zprávy. Tyto pøíkazy musí být
v tìle zprávy a ka¾dý øádek mù¾e obsahovat jenom jeden pøíkaz. Pokud
není tìlo zprávy ve formátu prostého textu, jsou pøíkazy ignorovány,
v tom pøípadì mohou být i pøíkazy v subjektu zprávy.

Dostupné pøíkazy jsou:

 HELp                        * Tato nápovìda
 INFO                        * Informace o konferenci
 LISts                       * Seznam konferencí na tomto poèítaèi
 REView <list>               * Zobrazi seznamu èlenù konference <list>
 WHICH                       * Zobrazy konference, jich¾ jste èleny
 SUBscribe <list> <jmeno>    * Pro pøihlá¹ení nebo jeho potvrzeni do
                               konference <list>, <jmeno> je volitelna
                               informace o èlenu konference.

 UNSubscribe <list> <EMAIL>  * Pro opu¹tìní konference <list>.
                               <EMAIL> je volitelná emailova adresa,
                               vhodná, pokud se li¹í od Va¹í adresy
                               v poli "From:" .

 UNSubscribe * <EMAIL>       * Pro opu¹tìní v¹ech konferencí.

 SET <list|*> NOMAIL         * Pro potlaèení pøijímání zpráv z konference <list>
 SET <list|*> DIGEST         * Pøijímání zprav v re¾imu shrnutí
 SET <list|*> SUMMARY        * Pøijímání pouze indexu zpráv
 SET <list|*> NOTICE         * Pøijímání pouze subjektù zpráv

 SET <list|*> MAIL           * Nastaví pøíjem zpráv z konference <list> do normálního re¾imu
 SET <list|*> CONCEAL        * Pro skrytí ze seznamu konference (skrytá adresa)
 SET <list|*> NOCONCEAL      * Adresa bude dostupná pøes pøíkaz REView


 INDex <list>                * Seznam souboru z archívu konference <list>
 GET <list> <file>           * Pro získání souboru <file> z archívu konference <list>
 LAST <list>                 * Pro získání poslední zprávy z konference <list>
 INVITE <list> <email>       * Pozvat <email> k pøihlá¹ení do konference <list>
 CONFIRM <key>               * Potvrzení pro odeslání zprávy (zále¾í
                               na konfiguraci konference)
 QUIT                        * Oznaèuje konec pøíkazu (pro ignorování podpisu)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Následující pøíkazy jsou dostupné pouze správcùm nebo moderátorùm konference:

 ADD <list> user@host First Last * Pro pøidání u¾ivatele do konference
 DEL <list> user@host            * Pro smazání u¾ivatele z konference
 STATS <list>                    * Statistika konference <list>
 EXPire <list> <old> <delay>     * Pro spu¹tìní expiraèního procesu pro
                                   u¾ivatele konference <list>,
                                   kteøí nepotvrdili své pøihlá¹ení u¾
                                   <old> dní. Èlenové mají <delay> dnù
                                   pro potvrzení.
 EXPireINDex <list>              * Zobrazí aktuální stav expirace pro <list>
 EXPireDEL <list>                * Pro zru¹ení procesu expirace pro <list>

 REMIND <list>                   * Pro zaslání upozornìní ka¾dému
                                   èlenu (toto je zpùsob, jak je informovat
                                   o jejich adrese v konferenci).

[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderování: potvrzení zprávy
 REJect <list> <clef>            * Moderování: odmítnutí zprávy
 MODINDEX <list>                 * Moderování: získání seznamu zpráv
                                   èekajících na moderování

[ENDIF]

[ELSIF user->lang=hu]

              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatikus Levelezõ Rendszer)

                                Felhaszálói Könyv

SYMPA egy automatikus levelezõlista-kezelõ program, mellyel a listakezelést,
mint pl. a feliratkozásokat, moderálást és archíválást lehet elvégezni.

Az összes email parancsot a következõ címre kell küldeni: [conf->sympa]

Egy levélben több parancsot is meg lehet adni. A parancsokat a levél 
törzsében, soronként egyesével kell megadni. A levél törzse csak akkor
kerül feldologzásra, ha az sima szöveges formátumûm, vagyis a Content-Type
text/plain. A program képes a levél tárgyában megadott email parancsok 
értelmezésére, amely néhány levelezõkliens használatánál elõfordulhat.

Az alkalmazható parancsok a következõk:

 HELp                        * Ez a súgó
 INFO                        * Információ adott listáról
 LISts                       * A szerveren mûködö levelezõlisták sora
 REView <lista>              * A <lista> tagjainak sora
 WHICH                       * Megmondja mely listáknak vagy tagja
 SUBscribe <lista> <GECOS>   * Feliratkozás vagy annak megerõsítése a
			       <listá>-ra. <GECOS> kiegészítõ információkat
			       tartalmazhat a feliratkozóról.

 UNSubscribe <lista> <EMAIL> * Törlés a <listá>-ról. <EMAIL> az az email 
			       cím, amellyel a lista tagja vagy, hasznos
			       ha a jelenlegi címed eltér a nyilvántarottól.
 
 UNSubscribe * <EMAIL>       * Törlés az összes listáról.

 SET <lista|*> NOMAIL        * Levélfogadás szüneteltetése a <listá>-ról
 SET <lista|*> DIGEST        * Levelek fogadása egyben (digestként)
 SET <lista|*> SUMMARY       * Csak a levelek listájának fogadása
 SET <lista|*> NOTICE        * Csak a levelek tárgysorának fogadása

 SET <lista|*> MAIL          * Levélfogadás <listá>-ról hagyományos módon
 SET <lista|*> CONCEAL       * Címed elrejtése (titkos lesz az email címed)
 SET <lista|*> NOCONCEAL     * Címed megjelenik a REView parancs kiemenetében


 INDex <lista>               * <lista> archívum tartalmának lekérése
 GET <lista> <file>          * <lista> archívumából <file> lekérése
 LAST <lista>                * <lista> utolsó üzenetének lekérése
 INVITE <lista> <email>      * <email> felkérése a <listá>-hoz csatlakozásra 
 CONFIRM <kulcs>             * Üzenet megjelenésének megerõsítéséhez szükséges
			       kulcs (lista beállításától függ használata)
 QUIT                        * A megadott parancsok feldolgozásának befejezése
			       (az aláírás így nem kerül feldolgozásra) 

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Parancsok csak a lista tulajdonosának vagy szerkesztõjének:

 ADD <lista> user@host Knév Vnév  * Tag hozzáadása a listához
 DEL <lista> user@host            * Tag törlése a listáról
 STATS <lista>                    * <lista> statisztikájának megtekintése
 EXPire <lista> <nap> <határidõ>  * Azon tagok értesítése a <listá>-n akik 
			            <nap> óta nem erõsítették meg lista-
				    tagásgukat. A tagoknak <határidõ>-ben
				    megadott nap áll rendelkezésükre ezt
				    pótolni.
 EXPireINDex <lista>              * A <listá>-n jelenleg érvényben levõ
				    megerõsítési folyamat megjelenítése
 EXPireDEL <lista>                * A <listá>-n lévõ megerõsítési folyamat
				    törlése

 REMIND <lista>                   * Send a reminder message to each
                                   subscriber (this is a way to inform
                                   anyone what is his real subscribing
                                   email).
[ENDIF]
[IF is_editor]

 DISTribute <lista> <clef>        * Moderálás: levél engedélyezése
 REJect <lista> <clef>            * Moderálás: levél visszautasítása
 MODINDEX <lista>                 * Moderálás: moderálásra váró levelek
				    megtekintése

[ENDIF]

[ELSIF user->lang=pt]
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Sistema Automático de Listas de Correio)

                                Guia de Usuário


SYMPA é um gestor de listas de correio eletrônicas que automatiza as funções
freqüentes de uma lista como a subscrição, moderação e arquivo de mensagens.

Todos os comandos devem ser enviados a o endereço [conf->sympa]

Podem se colocar múltiplos comandos numa mesma mensagem. Estes comandos tem que
aparecer no texto da mensagem e cada línea deve conter um único comando.
As mensagens devem se enviar como texto normal (text/plain) e não em formato HTML.
Em qualquer caso, os comandos no tema da mensagem também são interpretados.


Os comandos disponíveis são:

HELp                        * Este ficheiro de ajuda
INFO                        * Informação de uma lista
LISts                       * Diretório de todas as listas de este sistema
REView <lista>              * Mostra os subscritores de <lista>
WHICH                       * Mostra a que listas está subscrito
SUBscribe <lista> <GECOS>   * Para se subcribir ou confirmar uma subscrição
                               a <lista>.  <GECOS> e informação adicional
                               do subscritor (opcional).

UNSubscribe <lista> <EMAIL> * Para anular uma subscrição a <lista>.
                               <EMAIL> e opcional, e o endereço elec-
                               trônico do subscritor, útil si difere
                               do endereço normal "De:".

UNSubscribe * <EMAIL>       * Para se borrar de todas as listas

SET <lista> NOMAIL          * Para suspender a recepção das mensagens de <lista>
SET <lista|*> DIGEST        * Para receber as mensagens recopiladas
SET <lista|*> SUMMARY       * Para só receber o índex das mensagens 
SET <lista|*> MAIL          * Para ativar a recepção das mensagens de <lista>
SET <lista|*> CONCEAL       * Ocultar a endereço para o comando REView
SET <lista|*> NOCONCEAL     * O endereço do subscritor e visível via REView

INDex <lista>               * Lista o arquivo de <lista>
GET <lista> <ficheiro>      * Para obter o <ficheiro> de <lista>
LAST <lista>                * Usado para receber a última mensagem enviada a <lista>
INVITE <lista> <email>      * Convida <email> a se subscribir a <lista>
CONFIRM <key>               * Confirmação para enviar uma mensagem
(depende da configuração da lista)
QUIT                        * Indica o final dos comandos


[IF is_owner]%)
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-
Os seguintes comandos são unicamente para os proprietários ou moderadores das listas:

ADD <lista> <email> Nome Sobrenome     * Para adicionar um novo usuário a <lista>
DEL <lista> <email>                   * Para eliminar um usuário da <lista>
STATS <lista>                         * Para consultar as estatísticas da <lista>

EXPire <lista> <dias> <espera>        * Para iniciar um processo de expiração para aqueles subscritores que não tem confirmado 
sua subscrição desde tantos <dias>.
Os subscritores tem tantos dias de <espera> 
para confirmar.

EXPireINDEx <lista>                   * Mostra o atual processo de expiração da <lista>
EXPireDEL <lista>                     * Desativa o processo de expiração da <lista>

REMIND <lista>                        * Envia uma mensagem a cada subscritor (isto é um jeito para qualquer se lembrar com quê e-mail está subscrito).

[ENDIF]
[IF is_editor])

DISTribute <lista> <clave>           * Moderação: para validar uma mensagem
REJect <lista> <clave>               * Moderação: para denegar uma mensagem
MODINDEX <lista>                     * Moderação: consultar a lista das mensagens a moderar

[ENDIF]

[ELSE]

              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatic Mailing System)

                                User's Guide


SYMPA is an electronic mailing-list manager that automates list management
functions such as subscriptions, moderation, and archive management.

All commands must be sent to the electronic address [conf->sympa]

You can put multiple commands in a message. These commands must appear in the
message body and each line must contain only one command. The message body
is ignored if the Content-Type is different from text/plain but even with
crasy mailer using multipart and text/html for any message, commands in the
subject are recognized.

Available commands are:

 HELp                        * This help file
 INFO                        * Information about a list
 LISts                       * Directory of lists managed on this node
 REView <list>               * Displays the subscribers to <list>
 WHICH                       * Displays which lists you are subscribed to
 SUBscribe <list> <GECOS>    * To subscribe or to confirm a subscription to
                               <list>, <GECOS> is an optional information
                               about subscriber.

 UNSubscribe <list> <EMAIL>  * To quit <list>. <EMAIL> is an optional 
                               email address, usefull if different from
                               your "From:" address.
 UNSubscribe * <EMAIL>       * To quit all lists.

 SET <list|*> NOMAIL         * To suspend the message reception for <list>
 SET <list|*> DIGEST         * Message reception in compilation mode
 SET <list|*> SUMMARY        * Receiving the message index only
 SET <list|*> NOTICE         * Receiving message subject only
 SET <list|*> TXT            * Receiving only text/plain part of messages send in both
			       text/plain and in text/html format.
 SET <list|*> HTML           * Receiving only text/html part of messages send in both
			       text/plain and in text/html format.
 SET <list|*> URLIZE         * Attachments are replaced by and URL.
 SET <list|*> NOT_ME         * No copy is sent to the sender of the message


 SET <list|*> MAIL           * <list> reception in normal mode
 SET <list|*> CONCEAL        * To become unlisted (hidden subscriber address)
 SET <list|*> NOCONCEAL      * Subscriber address visible via REView


 INDex <list>                * <list> archive file list
 GET <list> <file>           * To get <file> of <list> archive
 LAST <list>                 * Used to received the last message from <list>
 INVITE <list> <email>       * Invite <email> for subscribtion in <list>
 CONFIRM <key>               * Confirmation for sending a message (depending
                               on the list's configuration)
 QUIT                        * Indicates the end of the commands (to ignore a
                               signature)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
The following commands are available only for lists's owners or moderators:

 ADD <list> user@host First Last * To add a user to a list
 DEL <list> user@host            * To delete a user from a list
 STATS <list>                    * To consult the statistics for <list>
 EXPire <list> <old> <delay>     * To begin an expiration process for <list>
                                   subscribers who have not confirmed their
                                   subscription for <old> days. The
                                   subscribers have <delay> days to confirm
 EXPireINDex <list>              * Displays the current expiration process
                                   state for <list>
 EXPireDEL <list>                * To de-activate the expiration process for
                                   <list>

 REMIND <list>                   * Send a reminder message to each
                                   subscriber (this is a way to inform
                                   anyone what is his real subscribing
                                   email).
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderation: to validate a message
 REJect <list> <clef>            * Moderation: to reject a message
 MODINDEX <list>                 * Moderation: to consult the message list to
                                   moderate
[ENDIF]
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/

