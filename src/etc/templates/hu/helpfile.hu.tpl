
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatikus Levelezõ Rendszer)

                                Felhasználói Kézikönyv

SYMPA egy automatikus levelezõlista-kezelõ program, mellyel a listakezelést,
mint pl. a feliratkozásokat, moderálást és archíválást lehet elvégezni.

Minden parancsot a következõ email címre kell küldeni: [conf->sympa]

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
			       ha a jelenlegi címed eltér a nyilvántartottól.
 
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
				    tagságukat. A tagoknak <határidõ>-ben
				    megadott nap áll rendelkezésükre ezt
				    pótolni.
 EXPireINDex <lista>              * A <listá>-n jelenleg érvényben levõ
				    megerõsítési folyamat megjelenítése
 EXPireDEL <lista>                * A <listá>-n lévõ megerõsítési folyamat
				    törlése

 REMIND <lista>                   * Emlékeztetõ levél elküldése a <lista>
                                    összes tagjának. (Így adható tudtukra,
                                    hogy milyen címmel vannak a listán
                                    nyilvántartva.)
[ENDIF]
[IF is_editor]

 DISTribute <lista> <clef>        * Moderálás: levél engedélyezése
 REJect <lista> <clef>            * Moderálás: levél visszautasítása
 MODINDEX <lista>                 * Moderálás: moderálásra váró levelek
				    megtekintése

[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
