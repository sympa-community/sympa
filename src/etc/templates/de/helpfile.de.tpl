
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

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
