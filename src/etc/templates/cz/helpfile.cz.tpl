
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

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
