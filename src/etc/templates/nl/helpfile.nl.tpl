
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatisch Mailing Systeem)

                                Gebruikers handleiding


SYMPA is een elektronisch mailinglijst management programma dat het managen
van lijsten regelt zoals inschrijvingen, moderatie en archief managen.

Alle commando's dienen naar het volgende adres gestuurd te worden: [conf->sympa]

U kunt meerdere commando's in een bericht plaatsen. Deze commandos moeten in
het bericht zelf geplaatst worden en elke regel dient slechts 1 commando te
bevatten. Het bericht wordt genegeerd als de Content-Type anders is dan
text/plain maar met elke type mailer werkt het geven van opdrachten ook via het
onderwerp van een bericht.


Beschikbare commando's zijn:

 HELp                        * Dit help bestand
 INFO                        * Informatie over een lijst
 LISts                       * Alle lijsten die bestaan op deze server
 REView <list>               * Laat de abonnees zien van lijst <list>
 WHICH                       * Laat de lijsten zien waar u zich op geabonneerd hebt
 SUBscribe <list> <GECOS>    * Om in te schrijven of te bevestigen dat u zich inschrijft
                               op een lijst <list>, <GECOS> is optioniele informatie
                               over de inschrijver

 UNSubscribe <list> <EMAIL>  * Om uit te schrijven bij <list>. <EMAIL> is een optioneel 
                               emailadres, handig wanneer u een ander adres gebruikt
                               dan uw "From:" adres
 UNSubscribe * <EMAIL>       * Om uit te schrijven bij alle lijsten.

 SET <list|*> NOMAIL         * Om het lezen van berichten op <list> tijdelijk te stoppen
 SET <list|*> DIGEST         * De berichten ontvangen in samenvatting
 SET <list|*> SUMMARY        * Om alleen de berichtenindex te ontvangen
 SET <list|*> NOTICE         * Om alleen de onderwerpen van de berichten te ontvangen

 SET <list|*> MAIL           * <list> ontvangst op de normale manier
 SET <list|*> CONCEAL        * Om uw inschrijving te verbergen (vervorgen abonnee adres)
 SET <list|*> NOCONCEAL      * Uw adres is zichtbaar met het REView commando


 INDex <list>                * <list> archief lijst
 GET <list> <file>           * Om <file> van <list> archief te krijgen
 LAST <list>                 * Om het laatste bericht van lijst <list> te krijgen
 INVITE <list> <email>       * nodig <email> uit voor inschrijving op <list>
 CONFIRM <key>               * Bevestigen voor het zenden van een bericht (afhankelijk
                               van de configuratie van de lijst)
 QUIT                        * Geeft het einde van de commando's aan (handig om bijvoorbeeld
                               nog een handtekening toe te kunnen voegen)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
De volgende commando's zijn alleen beschikbaar voor de eigenaren of moderators van een lijst:

 ADD <list> user@host First Last * Om een gebruiker toe te voegen aan een lijst
 DEL <list> user@host            * Om een gebruiker te verwijderen van een lijst
 STATS <list>                    * Om de statistieken van <list> te zien.
 EXPire <list> <old> <delay>     * Om een expiratie proces te beginnen voor <list>
                                   Abonnees die hun abonnement die hebben bevestigd
                                   voor <old> dagen. De
                                   abonnees hebben <delay> dagen om te bevestigen
 EXPireINDex <list>              * Laat de huidige expiratie status
                                   voor <list> zien
 EXPireDEL <list>                * De-activeer het expiratie proces voor
                                   <list>

 REMIND <list>                   * Stuur een herinneringsbericht voor iedere
                                   abonnee. (Dit is een manier om iedereen
                                   te informeren over z'n inschrijvings-
                                   emailadres).
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderatie: Om een bericht te valideren
 REJect <list> <clef>            * Moderatie: Om een bericht af te wijzen
 MODINDEX <list>                 * Moderatie: Om de lijst met berichten te tonen
                                   die gemodereerd moet worden
[ENDIF]

Powered by Sympa [conf->version] : http://www.sympa.org

