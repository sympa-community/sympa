              SYMPA -- Systeme de Multi-Postage Automatique
                  (Automaatne e-posti listide süsteem)

                            Kasutajajuhend


Sympa on e-posti listide haldamise tarkvara, mis võimaldab lihtsalt
hallata listide liikmeid, arhiive ning modereerimist. 

Kõik käsud sympale tuleb saada e-posti aadressile [conf->sympa]

E-posti teel Sympale saadetavad käsud peavad olema kas kirja sisus või
teemareal. Kirja sisus saab sympale kirjutada ka mitut käsku, selleks peab 
käsk olema eraldi real. Kirja sisus olvatest käskudest saab sympa aru ainult
siis, kui kiri on saadetud tavalise tekstina, mille mime tüübiks on 
text/plain. Juhul kui teie e-postiprogramm ei saada kirju puhta tekstina,
saate Sympale käske saata teemareal.

Sympa käsud on:

 HELp                        * Saadab teile sellesama abifaili
 INFO                        * Info listi kohta
 LISts                       * Selle serveri poolt hallatavte listide nimekiri
 REView <list>               * Näitab listi <list> lugejaid
 WHICH                       * Näitab, milliste listide liige te olete
 SUBscribe <list> <GECOS>    * Selle käsuga saab listi <list> liikmeks. 
                               <GECOS> kohale kirjutage täiendav info enda 
			       kohta (näiteks nimi)
 UNSubscribe <list> <EMAIL>  * Selle käsuga saab lahkuda listist <list>.
                               <EMAIL> asemele kirjutage teie aadress, mis on 
			       listis, juhul kui listis olev aadress erineb 
			       sellest aadressist, mis on teil From: real.
 UNSubscribe * <EMAIL>       * Analoogne eelmisega, ainult lahkute kõikidest
                               listidest
 SET <list|*> NOMAIL         * Peatab listi(de)st kirjade tulemise, jääte
                               listi(de) liikmeks siiski edasi.
 SET <list|*> DIGEST         * Kirjad listi(de)st tulevad kokkuvõtetena.
 SET <list|*> SUMMARY        * Saate kirjadest vaid indeksi.
 SET <list|*> NOTICE         * Saate igast kirjast vaid teemarea. 

 SET <list|*> MAIL           * Saate listi normaalselt (kirjadena)
 SET <list|*> CONCEAL        * Saate varjata oma listi liikmestaatust
 SET <list|*> NOCONCEAL      * Saate oma liikmestaatuse nähtavaks teha


 INDex <list>                * Saate listi <list> arhiivifailide nimekirja 
 GET <list> <file>           * Saate faili <file> listi <list> arhiivist
 LAST <list>                 * Saate viimase kirja listist <list>
 INVITE <list> <email>       * Kutsute aadressi <email> liituma listiga <list>
 CONFIRM <key>               * Kinnitate listi kirja saamtist (sõltub listi
                               seadetest)
 QUIT                        * Näitab, et käsud on lõppenud (signatuuri 
                               varjamiseks).

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Järgnevaid käskusid saavad kasutada vaid listide omanikud ja moderaatorid:

 ADD <list> user@host First Last * Lisate kasutaja listi. 
 DEL <list> user@host            * Kustutae kasutaja listist.
 STATS <list>                    * Listi <list> statistika
 EXPire <list> <old> <delay>     * Algatab aegumisprotsessi listi <list>
                                   lugejate hulgas, kes ei ole kinnitanud oma
				   liikmestaatust <old> päeva jooksul.
				   Lugejatel on <delay> päeva aega kinnitada
				   oma lugejastaatust.
 EXPireINDex <list>              * Näitab käesoleva aegumisprotsessi staatust
                                   listis <list>
 EXPireDEL <list>                * Peatab aegumisprotsessi listis <list>
 REMIND <list>                   * Saadab meeldetuletusteate igale listi 
                                   liikmele. (Nii saab teavitada listi liikmeid
				   nende tegelikest e-posti aadressidest lists)
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Modereerimine: kirja aktsepteerimine 
 REJect <list> <clef>            * Modereerimine: kirja tagasi lükkamine
 MODINDEX <list>                 * Modereerimine: modereeritavate kirjade
                                   nimekirja näitamine.
[ENDIF]

Siin töötab Sympa [conf->version] : http://listes.cru.fr/sympa/

