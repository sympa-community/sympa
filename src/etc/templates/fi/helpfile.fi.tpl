
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatic Mailing System)
						
					  K‰ytt‰j‰n Opas	

SYMPA on s‰hkˆpostilistojen hallintaa tehty ohjelma, joka mahdollistaa
toiminnot kuten tilaukset, hallinnan ja arkistojen k‰ytˆn.

Kaikki komennot tulee l‰hett‰‰ osoitteeseen [conf->sympa]

Voit antaa useampia komentoja samassa viestiss‰. Komennot tulee olla viestin
sis‰ltˆkent‰ss‰ ja eri komennot omilla riveill‰‰n. Viestin sis‰ltˆosaa ei 
huomioida jos Content-Type eroaa text/plain muodosta, mutta myˆs moniosaiset
viestit huomioidaan otsikkokent‰ss‰.

Saatavilla olevat komennot:

 HELP                        * T‰m‰ tiedosto
 INFO                        * Tietoja listoista
 LISTS                       * Hakemisto listoista joita palvelimella on olemassa
 REVIEW <list>               * N‰ytt‰‰ tilaajat listlle <list>
 WHICH                       * N‰ytt‰‰ mit‰ listoja tilaat
 SUBscribe <list> <GECOS>    * Tilataksesi tai varmistaaksesi tilauksen listalle
                               <list>, <GECOS> on vapaaehtoista tietoa tilaajasta.

 UNSubscribe <list> <EMAIL>  * Poistuaksesi listalta <list>. <EMAIL> on vaihtoehtoinen
					 osoite, hyˆdyllinen jos se eroaa L‰hett‰j‰: (From:) 
					 osoitteesta.
 UNSubscribe * <EMAIL>       * Poistuaksesi kaikilta listoilta.

 SET <list|*> NOMAIL         * Pys‰ytt‰‰ksesi viestien vastaanoton listalta <list>
 SET <list|*> DIGEST         * Viestien vastaanotto koostetilassa
 SET <list|*> SUMMARY        * Ainoastaan viestien listauksen vastaanotto
 SET <list|*> NOTICE         * Ainoastaan viestien otsikon vastaanotto

 SET <list|*> MAIL           * <list> vastaanotto normaali tilassa
 SET <list|*> CONCEAL        * Salaa osoitteesi muilta
 SET <list|*> NOCONCEAL      * Tilaajan osoite n‰kyviss‰ REView komennon kautta


 INDex <list>                * <list> arkistojen listaus
 GET <list> <file>           * Saadaksesi tiedosto <file> listan <list> arkistosta
 LAST <list>                 * K‰yt‰ saadaksesi viimeisin viesti listalta <list>
 INVITE <list> <email>       * Kutsu <email> tilaajaksi listalle <list>
 CONFIRM <key>               * Varmistus viestien l‰heteyksest‰ (riippuu
                               listan asetuksista)
 QUIT                        * M‰‰rittelee komentojen loppumisen (jotta allekirjoitusta ei
                               huomioida)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
Seuraavat komennot ovat saatavilla vain listan omistajille ja hallitsijoille:

 ADD <list> user@host First Last * Lis‰t‰ksesi tilaajan listalle
 DEL <list> user@host            * Poistaaksesi tilaajan listalta
 STATS <list>                    * Saadaksesi tilastot listalle <list>
 EXPire <list> <old> <delay>     * Aloittaaksesi vanhenemisprosessin listalle <list>
					     Tilaajat jota eiv‰t ole varmistaneet 
					     tilaustaan <old> p‰iv‰‰n. Tilaajille
					     <delay> aikaa varmistaa
 EXPireINDex <list>              * N‰ytt‰‰ t‰m‰n hetkin vanhenemisprosessin tilan 
					     listalle <list>
 EXPireDEL <list>                * Lopettaaksesi vanhenemisprosessin listalle
                                   <list>

 REMIND <list>                   * L‰hett‰‰ksesi muistutus viestin jokaiselle
					     tilaajalle (t‰ll‰ voidaan ilmoittaa kenen tahansa oikea
					     tilaajaosoite).
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Hallinta: hyv‰ksy viesti
 REJect <list> <clef>            * Hallinta: hylk‰‰ viesti
 MODINDEX <list>                 * Hallinta: tarkista viestilista hallintaa varten
[ENDIF]

Alustana Sympa [conf->version] : http://listes.cru.fr/sympa/

