<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
  <A NAME="[p->NAME]"></a>
  <B>[p->title]</B> ([p->NAME]):
  <DL>
    <DD>
      [IF p->NAME=add]
        Oprávnìní pro pøidání (pøíkaz ADD) èlena do konference
      [ELSIF p->NAME=anonymous_sender]
        Pro skrytí emailové adresy odesílatele pøed distribucí zprávy. Tato adresa
        je nahrazena definovanou adresou.
      [ELSIF p->NAME=archive]
        Oprávnìní èíst archívy zpráv a frekvenci archivování
      [ELSIF p->NAME=available_user_options]
        Parametr available_user_options zaèíná odstavec, který definuje mo¾né
        volby pro èleny konference.<BR><BR>
        <UL>
          <LI>reception <i>modelist</i> (Výchozí hodnota: reception mail,notice,digest,summary,nomail)<BR><BR>
              <i>modelist</i> je seznam re¾imù (mail, notice, digest, summary, nomail), oddìlených èárkou.
              Pouze tyto re¾imy budou dovoleny èlenùm konference. Pokud má èlen
              re¾im  pøíjmu zpráv, který není na seznamu, Sympa pou¾ije re¾im
              definovaný v odstavci default_user_options.
        </UL>
      [ELSIF p->NAME=bounce]
        Tento odstavec definuje parametry pro správu vrácených zpráv:<BR><BR>
        <UL>
          <LI>warn_rate (Výchozí hodnota: parametr robotu bounce_warn_rate)<BR><BR>
              Správce konference dostane varování kdykoliv je nìjaká zpráva rozeslána a poèet vrácených
              zpráv (v procentech) pøekroèí tuto hodnotu.
          <LI>halt_rate (Výchozí hodnota: parametr robotu bounce_halt_rate)<BR><BR>
              ZATÍM NEPOU®ITO. Pokud hodnota bounce rate dosáhne stavu halt_rate, zprávy do konference
              se pøestanou odesílat, t.j. budou zachovány pro následné moderování.
           <LI>expire_bounce_task (Výchozí hodnota: daily)<BR><BR>
               Jméno ¹ablony úkolu který se pou¾ije pro odstranìní starých vrácených zpráv.
               Je to u¾iteèné pro odstranìní vrácených zpráv z urèité adresy èlena pokud jsou
               jiné zprávy doruèovány bez problémù. V tomto pøípadì je adresa èlena v poøádku.
               Úkol je aktivní pokud bì¾í proces task_manager.pl.
         </UL>

      [ELSIF p->NAME=bouncers_level1]
        Odstavce Bouncers_level1 definují automatické chování správy vrácených zpráv.<BR>
        Úroveò 1 je nejni¾¹í úroveò vracejících se adres<BR><BR>

        <UL>
          <LI>rate (Výchozí hodnota: 45)<BR><BR>
              Ka¾dý u¾ivatel jemu¾ se vrací zprávy mí urèité skóre (od 0 do 100).
              Tento parametr definuje dolní hranici pro ka¾dou kategorii.
              Na pøíklad úroveò 1 zaèíná od 45 do hodnoty level_2_treshold.
          <LI> action (Výchozí hodnota: notify_bouncers)<BR><BR>
               Tento parametr definuje která úloha bude automaticky aplikována na vrácející se adresy
               úrovnì 1.
           <LI>Notification  (Výchozí hodnota: owner)<BR><BR>
               Kdy¾ se spustí automatická úloha, za¹le se upozornìní správci konference nebo serveru.
        </UL>

      [ELSIF p->NAME=bouncers_level2]
        Odstavce Bouncers_levelX definují automatické chování správy vrácených zpráv.<BR>
        Úroveò 2 je nejvy¹¹í úroveò vracejících se adres<BR><BR>

        <UL>
          <LI>rate (Výchozí hodnota: 80)<BR><BR>
              Ka¾dý u¾ivatel jemu¾ se vrací zprávy mí urèité skóre (od 0 do 100).
              Tento parametr definuje dolní hranici pro ka¾dou kategorii.
              Na pøíklad úroveò 2 je od 80 do 100.
          <LI> action (Výchozí hodnota: notify_bouncers)<BR><BR>
               Tento parametr definuje která úloha bude automaticky aplikována na vrácející se adresy
               úrovnì 2.
           <LI>Notification  (Výchozí hodnota: owner)<BR><BR>
               Kdy¾ se spustí automatická úloha, za¹le se upozornìní správci konference nebo serveru.
        </UL>
      [ELSIF p->NAME=cookie]
        Tento parametr je dùvìrná polo¾ka pro generování autentizaèních klíèù pro
        pro administrativní pøíkazy (ADD, DELETE, atd.). Tento parametr by mìl zùstat utajen, i pro správce konference.
        Tato hodnota je aplikována na v¹echny správce konferencí a brána v potaz pouze pokud má správce parametr auth.
      [ELSIF p->NAME=custom_header]
        Tento parametr je volitelný. Hlavièky zde definované budou pøidány ke v¹em zprávám
        rozeslaným do konference. Od verze Sympa 1.2.2je mo¾né vlo¾it do konfiguraèního souboru více øádkù 
        s vlastními hlavièkami najednou.
      [ELSIF p->NAME=custom_subject]
        Tento parametr je volitelný. Definuje øetìzec který je pøidán do pøedmìtu rozesílaných zpráv.
        Tento øetìzec bude obklopen znaky [].
      [ELSIF p->NAME=default_user_options]
        Parametr default_user_options zaèíná odstavec, který definuje výchozí profil pro èleny konference.<BR><BR>
        <UL>
          <LI>reception notice | digest | summary | nomail | mail<BR><BR>Zpùsob pøijímání zpráv.
          <LI>visibility conceal | noconceal<BR><BR>Viditelnost èlena ve výstupu pøíkazu REVIEW.
        </UL>
      [ELSIF p->NAME=del]
        Tento parametr definuje kdo je oprávnìn pou¾ít pøíkaz DEL.
      [ELSIF p->NAME=digest]
        Definice øe¾imu digest. Pokud je tento parametr pøítomný mohou èlenové zvolit zpùsob pøijímání
        zpráv ve formátu multipart/digest. Zprávy jsou seskupeny dohromady a pravidelnì rozeslány v jedné zprávì podle
	èetnosti definované tímto parametrem.
      [ELSIF p->NAME=editor]
		Editoøi (nebo moderátoøi) jsou zodpovìdní za moderování zpráv. Pokud je konference moderovaná,
		zprávy poslané do konference jsou nejøív poslané editorùm, kteøí rozhodnou,
		jestli se zpráva roze¹le nebo odmítne. <BR>
		FYI: Urèení editorù nenastaví konferenci jako moderovanou; musíte zmìnit
		parametr "send".<BR>
		FYI: Pokud je konference moderovaná, první editor, který potvrdí
		nebo odmítne zprávu rozhodne za ostatní editory. Pokud se nikdo nerozhodne,
		zprava zùstane ve frontì nemoderovaných zpráv.
      [ELSIF p->NAME=expire_task]
        Tento parametr urèuje, který model se pou¾ije pro vytvoøení upozoròovacího úkolu.
        Úkol vypr¹ení pravidelnì kontroluje datum pøihlá¹ení èlenù a po¾aduje po nich obnovení jejich èlenství.
        Pokud je neobnoví, jsou odstranìni.
      [ELSIF p->NAME=footer_type]
        Správci konference se mohou rozhodnout pøidávat urèitý text na zaèátek nebo na konec zpráv rozesílaných
        do konference. Tento parametr definuje zpùsob, jakým je tento text do zprávy vkládán.<BR><BR>
        <UL>
          <LI>footer_type mime<BR><BR>
              Výchozí hodnota. Sympa bude pøidávat text jako novou pøílohu zprávy.
              Pokud je zpráva ve formátu multipart/alternative, nestane se nic (nebo» by to vy¾adovalo
              vytváøet dal¹í úroveò vkládaní zpráv).
          <LI>footer_type append<BR><BR>
              Sympa bude vkládat text pøímo do tìla zpráv. Ji¾ definované pøípony budou ignorovány.
              Text se bude vkládat pouze do zpráv v prostém formátu bez pøíloh (text/plain).
          </LI>
        </UL>
      [ELSIF p->NAME=host]
        Jméno domény konference, výchozé hodnota je jméno domény robota, nastavené v odpovídajícím souboru
        robot.conf nebo v souboru /etc/sympa.conf.
      [ELSIF p->NAME=include_file]
        Tento parametr bude zpracován pouze v pøípadì, ¾e polo¾ka user_data_source má nastavenou hodnotu
        "include". Soubor by mìl pouze obsahovat jednou emailovou adresu na øádek. (Øádky zaèínající znakem
        "#" jsou ignorovány).
      [ELSIF p->NAME=include_ldap_2level_query]
        Tento odstaven definuje parametry pro dvojúrovòový LDAP dotaz, který vrací seznam èlenù.
        Obvykle první úroveò dotazu vrací seznam DN a druhá úroveò dotazu pøevede DN a emailové adresy. Tento parametr
        se pou¾ije pouze pokud je parametr user_data_source nastaven na "include". Tato funkce vy¾aduje
        modul Net::LDAP (perlldap).
      [ELSIF p->NAME=include_ldap_query]
        Tento odstavec definuje parametry pro LDAP dotaz, který vrací seznam èlenù konference.
        Tento parametr se pou¾ije pouze pokud je parametr user_data_source nastaven na "include". 
        Tato funkce vy¾aduje modul Net::LDAP (perlldap).
      [ELSIF p->NAME=include_list]
        Tento parametr se pou¾ije pouze pokud je parametr user_data_source nastaven na "include". 
        V¹ichni èlenové dané konference se stanou èleny této konference.
        Mù¾ete zahrnout více konferencí podle potøeby definováním více øádkù include_list.
        Mù¾ete vkládat libovolnou konferenci bez ohledu na zpùsob definice té konference.
        Dejte pozor na to, abyste nevlo¾ili konferenci A do konference B a potom konferenci B do konference A,
        nebo» to by zpùsobilo nekoneènou smyèku.
      [ELSIF p->NAME=include_remote_sympa_list]
        Sympa mù¾e kontaktovat jinou slu¾bu Sympy pomoci https protokolu a získat seznam èlenù vzdálené konference.
        Lze definovat více konferenci najednou podle potøeby. Dejte jenom pozor aby nevznikaly kruhové vazby.        
        <BR><BR>
        Pro tuto operaci jedno místo Sympa funguje jako server, zatímco druhý jako klient.
        Na strane serveru je nutno nastavit oprávnìní pro vzdálenou Sympu. Toto se øídí scenáøem review.
      [ELSIF p->NAME=include_sql_query]
        Tento parametr se pou¾ije pouze pokud je parametr user_data_source nastaven na "include" a zaèíná odstavec,
        který definuje parametry SQL dotazu.
      [ELSIF p->NAME=lang]
        Tento parametr urèuje výchozí jazyk konference. Je pou¾it pro výchozí nastavení volby jazyka u¾ivatele;
        výstupy pøíkazù Sympy jsou vyta¾eny z pøíslu¹ného katalogu zpráv.
      [ELSIF p->NAME=max_size]
        Maximální velikost zprávy v bajtech.
      [ELSIF p->NAME=owner]
        Vlastníci spravují èleny konference. Mohou si prohlí¾et seznam èlenù, pøidávat
        nebo mazat adresy ze seznamu. Pokud jste oprávnìným správcem konference,
        mù¾ete urèit jiné vlastníky konference.
	Privilegovaní vlastníci mohou upravovat více parametrù ne¾ jiní vlastníci. Pro
	konferenci mù¾e být pouze jeden prvilogovaný vlastník, jeho adresa se
	nedá mìnit z webu.
      [ELSIF p->NAME=priority]
        Priorita se kterou bude Sympa zpracovávan zprávy pro tuto konferenci. Tato úroveò priority je aplikována
        ve chvíli, kdy zpráva prochází frontou zpráv.
      [ELSIF p->NAME=remind]
        Teto parametr urèuje kdo je autorizován pou¾ít pøíkaz REMIND.
      [ELSIF p->NAME=remind_return_path]
        Stejné jako parametr welcome_return_path, ale aplikováno na upomínací zprávy.
      [ELSIF p->NAME=remind_task]
        Tento parametr urèuje model, který se pou¾ije pro vytvoøení upomínací úlohy. Tato úloha pravidelnì
        rozesílá èlenùm zprávu, která jim pøipomíná jejich èlenství v konferenci.
      [ELSIF p->NAME=reply_to_header]
        Parametr reply_to_header zaèíná odstavec, který definuje co Sympa umístí Sympa do
        hlavièky Reply-To: ve zprávì kterou rozesílá.<BR><BR>
        <UL>
          <LI>value sender | list | all | other_email (Výchozí hodnota: sender)<BR><BR>
              Tento parametr urèuje zda polo¾ka Reply-To: by mìla obsahovat odesílatele (sender),
              konferenci (list), oba dva (all) nebo nìjakou jinou adresu (definovanou parametrem
              other_email).<BR><BR>
              Poznámka: Není doporuèeno mìnit tento parametr a zejména jej nastavovat na adresu konference.
              Ze zku¹enosti se ukazuje, ¾e je témìø nevyhnutelné, ¾e u¾ivatelé budou vìøit tomu, ¾e
              posílají zprávu pouze odesílateli, ale ode¹lou ji do konference. To mù¾e vést pøinejmen¹ím
              k trapasu, ale mù¾e to mít i vá¾nìj¹í následky.<BR><BR>
          </LI>
          <LI>other_email emailova adresa<BR><BR>
              Pokud je polo¾ka value nastavena na other_email, pak tento parametr urèuje pou¾itou adresu.<BR><BR>
          </LI>
          <LI>apply respect | forced (Výchozí hodnota: respect)<BR><BR>
               Výchozí hodnota je zachovávat ji¾ existující polo¾ku hlavièky ve zprávách. Pokud je nastaveno "forced", 
               hlavièka bude pøepsána.
          </LI>
        </UL>
      [ELSIF p->NAME=review]
        Tento parametr urèuje kdo mù¾e získat seznam èlenù. Proto¾e adresy èlenù mohou být zneu¾ity pro
        ¹íøení nevy¾ádaných zpráv, je doporuèeno, abyste autorizoval pouze správce nebo existující èleny.
      [ELSIF p->NAME=send]
        Tento parametr definuje kdo mù¾e posílat zprávy do konference. Platné hodnoty pro tento parametr jsou
        odkazy na existující scenáøe.<BR><BR>
        <UL>
          <LI>send closed<BR>uzavøena
          <LI>send editor<BR>moderována, starý styl
          <LI>send editorkey<BR>Moderována
          <LI>send editorkeyonly<BR>Moderována i pro moderátory
          <LI>send editorkeyonlyauth<BR>Moderována, s potvrzením moderátora
          <LI>send intranet<BR>omezena na lokální doménu
          <LI>send intranetorprivate<BR>omezena na lokální doménu a èleny
          <LI>send newsletter<BR>Obì¾ník, omezena jen pro moderátory
          <LI>send newsletterkeyonly<BR>Obì¾ník, omezena jen pro moderátory po potvrzení
          <LI>send private<BR>pouze pro èleny
          <LI>send private_smime<BR>pouze pro èleny, kontrola podpisu SMIME
          <LI>send privateandeditorkey<BR>Moderována, pouze pro èleny
          <LI>send privateandnomultipartoreditorkey<BR>Moderována, pro neèleny nebo zprávy s pøílohou
          <LI>send privatekey<BR>omezena jen pro èleny s pøedchozí MD5 autentizací
          <LI>send privatekeyandeditorkeyonly<BR>Moderována, pro èleny a moderátory
          <LI>send privateoreditorkey<BR>Soukromá, neèleni moderováni
          <LI>send privateorpublickey<BR>Soukromá, neèlení po potvrzení
          <LI>send public<BR>veøejná konference
          <LI>send public_nobcc<BR>veøejná konference, BCC odmítnuto (anti-spam)
          <LI>send publickey<BR>kdokoliv s pøedchozí MD5 autentizací
          <LI>send publicnoattachment<BR>veøejná, zprávy s pøílohou predány moderátorùm
          <LI>send publicnomultipart<BR>veøejná, zprávy s pøílohou jsou odmítnuty
        </UL>
      [ELSIF p->NAME=shared_doc]
        Tento odstavec definuje práva pro ètení a úpravy pro adresáø se sdílenými dokumenty.
      [ELSIF p->NAME=spam_protection]
        Je nutno chránit webové archivy proti robotùm, které sbírají emailové adresy.
        Jsou k dispozici rùzné metody, které mù¾ete nastavit v parametrech spam_protection 
        a web_archive_spam_protection. Mo¾né hodnoty jsou:<BR><BR>
        <UL>
          <LI>javascript: adresa je schována pomocí Javascriptu. U¾ivatel, který má aktivní Javascript uvidí normální adresu, kde¾to ostatní neuvidí nic.
          <LI>at: znak "@" je nahrazen øetìzcem  " AT ".
          <LI>none : zádná ochrana proti spamerùm.
        </UL>
      [ELSIF p->NAME=subject]
        Tento parametru urèuje sujekt zprávy, které je odeslána jako odpovìï na pøíkaz LISTS.
        Obsahem mù¾e být cokoliv v rozsahu jedné øádky
      [ELSIF p->NAME=subscribe]
        Parametr subscribe definuje pravidla pro pøipojení do konference.
        Pøeddefinované scénáøe jsou:<BR><BR>
        <UL>
          <LI>subscribe auth<BR>vy¾adováno potvrzení po¾avku na pøihlá¹ení
          <LI>ubscribe auth_notify<BR>vy¾adováno potvrzení (upozornìní je odesláno správcùm)
          <LI>subscribe auth_owner<BR>vy¾aduje potvrzeni a pak schválení správce
          <LI>subscribe closed<BR>nelze se pøihlásit
          <LI>subscribe intranet<BR>omezeno pouze pro lokální u¾ivatele
          <LI>subscribe intranetorowner<BR>omezeno pouze pro lokální u¾ivatele nebo potvrzení správce
          <LI>subscribe open<BR>pro kohokoliv bez potvrzení
          <LI>subscribe open_notify<BR>kdokoli, upozornìní je odesláno správci
          <LI>subscribe open_quiet<BR>kdokoli, bez uvítací zprávy
          <LI>subscribe owner<BR>vy¾adováno schálení správce
          <LI>subscribe smime<BR>vy¾aduje S/MIME podpis
          <LI>subscribe smimeorowner<BR>vy¾aduje S/MIME podpis nebo schválení správce
        </UL>
      [ELSIF p->NAME=topics]
        Tento parametr dovoluje klasifikaci konferencí. Mù¾ete definovat více témat nebo i jako hierarchii.
        Seznam veøejných konferenci pro WWSympa pou¾ije tuto hodnotu.
      [ELSIF p->NAME=ttl]
        Sympa si pamatuje data získaná z parametru include. Jejich doba ¾ivota (TTL) uvnitø Sympy
        se dá ovlivnit tímto parametrem. Výchozí hodnota je 3600 vteøin.
      [ELSIF p->NAME=unsubscribe]
        Tento parametr urèuje zpùsob odhla¹ování z konference. Pou¾ijte volby open_notify nebo
        auth_notify pro zasílání upozornìní správci. Pøeddefinované scenáøe jsou:<BR><BR>
        <UL>
          <LI>unsubscribe auth<BR>vy¾aduje autentizaci
          <LI>unsubscribe auth_notify<BR>vy¾aduje autentizaci, zasláno upozornìni správci
          <LI>unsubscribe closed<BR>odhlá¹ení zakázáno
          <LI>unsubscribe open<BR>kdokoliv bez autentizace
          <LI>unsubscribe open_notify<BR>bez autentizace, správce obdr¾í upozornìní
          <LI>unsubscribe owner<BR>vy¾adováno potvrzení u¾ivatele
        </UL>
      [ELSIF p->NAME=user_data_source]
        Sympa dovoluje definovat více zdrojù pro seznam èlenù konference.
        Tyto informace mohou být ulo¾eny v textovém souboru nebo v relaèní databázi nebo
        vlo¾eny z rùzných externích zdrojù (konference, prostý textový soubor, dotaz do LDAP)
      [ELSIF p->NAME=visibility]
        Tento parametr urèuje zda by se mìla konference zobrazovat ve výstupu z pøíkazu LISTS nebo
        by mìla být zobrazena v pøehledu konferencí na webovém rozhraní.
      [ELSIF p->NAME=web_archive]
        Definuje kdo mù¾e pøistupovat do webových archívù konference. Pøeddefinované scénáøe jsou:<BR><BR>
        <UL>
          <LI>access closed<BR>pøístup uzavøen
          <LI>access intranet<BR>omezen na u¾ivatele z lokální domény
          <LI>access listmaster<BR>pouze správce
          <LI>access owner<BR>pouze vlastník
          <LI>access private<BR>pouze èlenové konference
          <LI>access public<BR>veøejný pøístup
        </UL>
      [ELSIF p->NAME=web_archive_spam_protection]
        Podobnì jako polo¾ka spam_protection ale omezeno na webový archív. Dal¹í hodnota je mo¾ná: cookie -
        co¾ znamená, ¾e u¾ivatelé musí projít malým formuláøem, aby se dostali dále k archívùm.
        Tato metoda blokuje v¹echny roboty, vèetnì Google a pod.
      [ELSIF p->NAME=welcome_return_path]
        Pokud nastaveno na hodnotu to unique, bude uvítací zpráva odeslana s unikátní návratovou adresou
        tak, aby se dal èlen odstranit okam¾itì v pøípadì vrácení zprávy.
      [ELSE]
        Bez komentáøe
      [ENDIF]
    </DD>
  </DL>
[END]
