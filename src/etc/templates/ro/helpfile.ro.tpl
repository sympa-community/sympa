
                           SYMPA - Sistem de mail automat

                                Ghidul utilizatorului


SYMPA este un sistem de administrare automatic al listelor de e-mail si functioneaza 
ca si tratare a abonarilor, moderator al trimiterii si aministrator al arhivelor.

Toate comenzile de sistem trebuiesc trimise la adresa electronica [conf->sympa]

Intr-un singur mesaj se pot include mai multe comenzi. Aceste comenzi trebuie sa apara 
in continutul mesajului - message body si fiecare rand trebuie sa contina o singura comanda. 
Programul va ignora continutul mesajului daca setarea Content-Type este alta decat text/plain, 
dar comenzile din campul de subiect vor fi recunoscute de orice sistem.

Comenzile disponibile sunt:

 HELP                        * Ajutor pentru acest fisier
 INFO                        * Informatii legate de o lista
 LISTS                       * Directorul listelor administrate pe acest nod
 REVIEW <list>               * Afisarea membrilor inscrisi in <list>
 WHICH                       * Afisarea listelor la care sunteti inscris
 SUBSCRIBE <list> <GECOS>    * Pentru a va abona sau pentru a confirma o abonare la <list>, 
 iar <GECOS> este o informatie optionala despre membri inscrisi.
 UNSUBSCRIBE <list> <EMAIL>  * Deconectarea de la <list>. <EMAIL> este o adresa optionala, in 
 cazul in care difera de adresa dumneavoastra de la "From:".
 UNSSUBSCRIBE * <EMAIL>       * Deconectarea de la toate listele.

 SET <list|*> NOMAIL         * Suspendarea receptionarii mesajelor pentru <list>
 SET <list|*> DIGEST         * Receptionarea mesajelor in mod de compilare
 SET <list|*> SUMMARY        * Receptionarea numai a indexului de mesaj 
 SET <list|*> NOTICE         * Receptionarea numai a subiectului de mesaj 
 SET <list|*> MAIL           * Receptionarea <list> in mod normal
 SET <list|*> CONCEAL        * Pentru a deveni nelistat (adresa de membru ascunsa)
 SET <list|*> NOCONCEAL      * Adresa de membru inscris vizibila prin REVIEW

 INDEX <list>                * Lista fisierelor arhiva apartinand la <list> 
 GET <list> <file>           * Pentru a accesa <file> arhivei apartinand la <list>
 LAST <list>                 * Utilizat pentru accesarea ultimului mesaj de pe <list>
 INVITE <list> <email>       * Invita <email> pentru abonare in <list>
 CONFIRM <key>               * Confirmarea pentru trimiterea unui mesaj (depinzand de configuratia listei)
 QUIT                        * Indica sfersitul comenzilor (pentru ignorarea unei semnaturi)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Urmatoarele comenzi sunt disponibile numai pentru proprietarii listelor sau pentru moderatorii acestora:

 ADD <list> user@host First Last * Adaugarea unui utilizator la lista
 DEL <list> user@host            * Stergerea unui utilizator din lista
 STATS <list>                    * Consultarea statisticii pentru <list>
 EXPire <list> <old> <delay>     * Initierea unui proces de expirare pentru membri inscrisi 
 la <list> care nu si-au confirmat abonarea pentru zilelele trecute <old>. Membri inscrisi au la 
 dispozitie zilele de ragaz <delay> pentru confirmare
 EXPireINDex <list>              * Afisarea starii procesului curent de expirare pentru <list>
 EXPireDEL <list>                * Dezactivarea procesului curent de expirare pentru <list>
 
 REMIND <list>                   * Trimiterea unui mesaj de reamintire catre fiecare membru inscris 
 (pentru a informa membri referitor la mesajul de abonare).
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderare: pentru validarea mesajului
 REJect <list> <clef>            * Moderare: pentru refuzarea mesajului
 MODINDEX <list>                 * Moderare: pentru consultarea listei de mesaje pentru moderare
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/