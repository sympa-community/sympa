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

