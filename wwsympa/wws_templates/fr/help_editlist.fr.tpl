<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]) :
<DL>
<DD>
[IF p->NAME=subject]
C'est une ligne de texte qui apparaît en sous-titre dans la page de présentation de la liste, et qui accompagne le nom de la liste dans le tableau récapitulatif des listes. La limitation à une ligne ne permet évidemment pas une présentation détaillée.
Pour cela, il faut utiliser la page de présentation de la liste et le champs &quot;info&quot; inclus dans certains messages de service (voir les rubriques
d'aides correspondantes).
[ELSIF p->NAME=visibility]
<p>Ce paramètre détermine le comportement du robot en réponse à la commande LISTS d'un non abonné. Il détermine aussi les règles d'accès d'un non
abonné à la page de présentation de votre liste sur l'interface web ([conf->wwsympa_url]).
Il ne détermine pas <i>l'aspect </i>de la page de présentation, lequel est défni par les paramètres <font color="#800000">mode d'abonnement</font> et <font color="#800000">listes des abonnés</font> (voir l'aide spécifique à ces paramètres).</p>
<p>Le paramètre visibilité est défini indépendamment du mode d'abonnement à la liste. Cependant, dans la majorité des cas, il semble logique de mettre les
listes à abonnement libre (open et open_notify) en option noconceal, et les listes à abonnement fermé (closed) en option conceal. Si votre liste a le mode
d'abonnement owner, vous pourrez la classer en conceal ou noconceal suivant le degré de publicité que vous souhaitez lui donner.</p>
<p><font color="#800000"><b>noconceal&nbsp; </b></font>(non confidentielle) : le nom de votre liste et son sujet apparaissent dans la réponse à la commande
LISTS, même si l'émetteur de la commande n'est pas abonné à la liste. De même, dans l'interface web, le menu &quot;listes publiques&quot; fera
apparaître votre liste même si le visiteur effectue une connexion anonyme.&nbsp;</p>
<p><font color="#800000"><b>conceal&nbsp; </b></font>(confidentielle) : le nom de votre liste n'apparaît pas dans la réponse à la commande LISTS d'un non
abonné, ni dans le menu &quot;listes publiques&quot; de l'interface web, à moins que le visiteur soit abonné à votre liste et établisse une connexion
non anonyme. Autrement dit, il vous appartient de faire vous-même la publicité de votre liste. Remarquez que le paramètre conceal<font color="#800000">&nbsp;</font> ne s'applique pas aux propriétaires et aux abonnés de la liste. Ainsi, si vous envoyez la commande LISTS sous votre adresse de propriétaire, vous verrez apparaître le nom de votre liste dans la réponse du robot, que votre liste soit publique ou nom.<br>
<font color="#800000"><i>Important</i></font> : même si la liste est déclarée conceal, il est possible d'obtenir sa page de présentation sur le web, à condition de connaître par ailleurs le nom de la liste. <br>Celle-ci se trouve à l'adresse : [conf->wwsympa_url]/info/nom_de_la_liste.<br>
Il&nbsp; y a peu de chances qu'une personne ne connaissant pas le nom de la liste tombe sur cette page; il vaut mieux cependant prévoir un texte de
présentation. Si la personne n'est pas abonnée, elle n'aura pas d'accès à d'autres renseignements que ceux que vous aurez ainsi affichés.</p>
[ELSIF p->NAME=info]
  Indique qui peut consulter la page d'information (page d'accueil) de la
  liste.
[ELSIF p->NAME=subscribe]
  <p>Vous pouvez&nbsp; définir le mode d'abonnement à votre liste, celui-ci règle la réponse du robot à une demande d'abonnement (commande SUBscribe)
ou de désabonnement (commande SIGoff). Le comportement est le même si les demandes sont faites par l'intermédiaire de l'interface web.</p>
<p><font color="#800000"><b>open</b></font> : l'abonnement est réalisé dès réception d'une commande SUB ou par simple clic sur le bouton
&quot;abonnement&quot; de l'interface web. Si vous adoptez ce mode d'abonnement avec une liste non modérée, surveillez attentivement les messages postés sur
la liste pour éviter toute dérive.&nbsp;</p>
<p><b><font color="#800000">open_notify</font></b> : ce mode est semblable au précédent. La seule différence est que vous serez informé par e-mail de
l'inscription de chaque nouvel abonné.</p>
<p><b><font color="#800000">owner</font></b> :<b> </b>seuls les propriétaires peuvent procéder aux abonnements. La commande SUB ou le clic sur le bouton
&quot;abonnement&quot;&nbsp; ne provoquent pas l'abonnement automatique; le demandeur est informé que sa demande est envoyée aux propriétaires de la
liste. Pour rendre l'abonnement effectif, ceux-ci devront utiliser la commande ADD&nbsp; ou l'interface web. Ce mode est recommandé pour les listes non
modérées.</p>
<p><font color="#800000"><b>closed</b></font> : seuls les propriétaires peuvent procéder aux abonnements. A la différence du mode précédent, la commande SUB
ne transmet pas de demande d'abonnement aux propriétaires. L'émetteur de la commande SUB est informé que les abonnements à la liste sont fermés. Dans l'interface
web, le bouton &quot;abonnement &quot; est remplacé par la mention :&quot;Abonnements fermés&quot;. </p>

[ELSIF p->NAME=add]
  Indique qui (en dehors des abonnés eux-mêmes) peut directement inscrire des
  abonnés à la liste. Ce droit est habituellement réservé au propriétaire de la
  liste.
[ELSIF p->NAME=unsubscribe]
  Définit les conditions requises pour se désabonner de cette liste. Dans la majorité des cas,
  le désabonnement devrait être disponible pour les abonnés uniquement, avec
  confirmation, pour permettre à tout abonné désireux de quitter une liste de
  pouvoir le faire, en évitant qu'un tiers puisse désabonner quelqu'un à son
  insu.<br>
  La valeur correspondant à ce réglage est "auth".<br>
  Si le propriétaire de la liste désire être informé par mail lorsqu'un abonné
  quitte la liste, la valeur à choisir est "auth_notify".
[ELSIF p->NAME=del]
  Indique qui (en dehors des abonnés eux-mêmes) peut directement supprimer des
  abonnés de la liste. Ce droit est habituellement réservé au propriétaire de la
  liste.
[ELSIF p->NAME=owner]
<p><font color="#800000"><b>Les propriétaires</b></font> ou gestionnaires sont responsables de la gestion des abonnés de la liste. Ils peuvent consulter le
fichier des abonnés, ajouter une adresse ou la supprimer soit par courrier soit par l'interface web. Si vous êtes propriétaire privilégié, vous pouvez désigner d'autres propriétaires en écrivant simplement leur adresse dans un des champs. Pour supprimer un propriétaire, effacez le champ correspondant.</p>

<p><font color="#800000"><b>Les propriétaires privilégiés</b></font> peuvent, en plus, éditer les messages de service de la liste, définir certains
paramètres, désigner d'autres propriétaires ou des modérateurs. Pour des raisons de sécurité, il ne peut y avoir qu'un propriétaire privilégié par
liste. De plus, son adresse n'est pas éditable par interface web. Si vous désirez modifier une adresse de propriétaire privilégié, adressez-vous au listmaster.</p>

[ELSIF p->NAME=send]
<p>Ce paramètre définit la façon dont les messages envoyés à la liste sont traités ; la liste ci-dessous n'est pas exhaustive.</p>

<p><b><font color="#800000">public :</font></b> tous les messages adressés à la liste, que le contributeur soit abonné ou non, sont diffusés à tous les
abonnés. Il n'y a pas de modération. Comme vous n'avez aucun contrôle a priori sur l'auteur du message et sur le contenu, vous ne devez utiliser ce mode
qu'avec prudence et en aucun cas avec une liste à abonnement libre. Exemple d'utilisation : réalisation d'une enquête dont le dépouillement sera assuré
par un groupe de personnes abonnées à la liste et bien connues de vous.</p>

<p><font color="#800000"><b>private :</b></font> seuls les abonnés peuvent poster un message. Il n'y a pas de modération. Ce mode est recommandé si vous
voulez animer une liste non modérée. En effet, l'abonnement est une démarche volontaire ; tout abonné est réputé avoir pris connaissance du sujet et des
règles de fonctionnement de votre liste dans la page de présentation, dans le&nbsp; message de bienvenue adressé aux nouveaux abonnés ou dans les
messages de rappel d'abonnement.</p>

<p><font color="#800000"><b>editorkeyonly&nbsp; :</b></font> Les messages adressés à la liste, que le contributeur soit abonné ou non, sont envoyés
d'abord aux modérateurs. Ceux-ci ne peuvent pas modifier les messages : ils peuvent seulement les accepter ou les rejeter. Dans un cas comme dans l'autre,
le message est retiré de la file d'attente, ce qui revient à dire que le premier modérateur qui prend une décision l'impose aux autres. Si aucun
modérateur ne prend de décision dans un délai d'une semaine suivant l'arrivée du message, ce dernier est détruit sans être diffusé. Notez que
les messages postés par les modérateurs sont également soumis à la modération.<br>

<p><font color="#800000"><b>editorkey&nbsp; :</b></font> Ce mode est identique à editorkeyonley, à la différence que les messages des modérateurs sont
diffusés directement. Cela offre une plus grande souplesse d'utilisation aux modérateurs, au prix d'une sécurité un peu moins grande, car le robot se base
sur les champs d'en-tête du message. Un utilisateur capable de bricoler son logiciel de messagerie pour y écrire une adresse de modérateur dans un champ
d'en-tête pourrait ainsi envoyer un message court-circuitant la modération.</p>

<p><font color="#800000"><b>privateoreditorkey :&nbsp;</b></font> Les messages postés par les abonnés sont diffusés directement, comme avec le paramètre <i>p
rivate</i> seul. Les messages postés par les non abonnés sont soumis à la modération dans les mêmes conditions qu'avec le paramètre <i>editorkey</i>.
</p>

<p><font color="#800000"><b>privateandeditor :&nbsp;</b></font> Ce mode de contribution combine les options <i>private</i> et <i>editorkeyonly</i>.
Seuls les messages postés par les abonnés sont envoyés aux modérateurs. Les messages des non abonnés sont automatiquement rejetés.
</p>   

<p><font color="#800000"><b>newsletter :&nbsp;</b></font>
Seuls les messages des modérateurs sont acceptés. Tous les autres messages, même ceux des abonnés, sont rejetés. Bien entendu, ce mode ne convient pas pour
une liste de discussion. Il est utilisé pour des listes diffusant des bulletins d'informations. 
</p>

[ELSIF p->NAME=editor]

<p><b><font color="#800000">Les modérateurs </font></b>sont responsables de la modération des messages. Si la liste est modérée, les messages postés sur la
liste seront d'abord adressés aux modérateurs qui pourront autoriser ou non la diffusion. Cette interface vous permet de désigner plusieurs modérateurs,
en écrivant leur adresse dans un des champs.<br>
<i><font color="#800000">Remarques importantes :</font><br>
- </i>Il ne suffit pas de désigner un modérateur pour que la liste soit modérée. Vous devez également régler la valeur du paramètre &quot;mode de
contribution&quot; en conséquence (voir aide sur le mode de contribution).<br>
- Si une liste possède plusieurs modérateurs, le premier modérateur qui accepte ou rejette un message prend la décision pour les autres. Si aucun
modérateur ne prend de décision, les messages en attente de modération sont effacés au bout d'une semaine.</p>

[ELSIF p->NAME=topics]
  Définit la ou les rubrique(s) de l'annuaire des listes dans lesquelles cette
  liste sera classée.
[ELSIF p->NAME=host]
  Indique le nom de serveur pour cette liste. L'adresse de la liste sera alors
  nom_de_la_liste@host
[ELSIF p->NAME=lang]
  Définit la langue principale en usage pour cette liste.
[ELSIF p->NAME=web_archive]
<p>Ce paramètre ne concerne que les listes dont les messages sont archivés. Il
ne détermine que le mode de consultation des messages par l'interface web, et
non le mode d'archivage lui-même. En particulier, même si la consultation des
archives est totalement fermée, les messages continuent d'être archivés. Si
vous souhaitez interrompre l'archivage lui-même, vous devez
en faire la demande auprès des administrateurs.</P>
<p><font color="#800000"><b>public</b> : </font>les archives sont consultables par tous, abonnés ou non. Les contributeurs doivent évidemment être
conscients de cette situation. L'accès aux archives se faisant par l'intermédiaire de la page de présentation de la liste, le mode 
<font color="#800000">public</font>n'a de sens que si le paramètre visibilité de la liste est en mode <font color="#800000">noconceal</font>
(voir l'aide sur le paramètre visibilité pour plus de détails).</p>
<p><font color="#800000"><b>private </b>:<b> </b></font>les archives sont accessibles seulement aux abonnés. Pour les consulter, il faut se connecter à
l'interface web des listes en fournissant son mot de passe.</p>
<p><font color="#800000"><b>owner </b>: </font>les archives sont accessibles seulement aux propriétaires de la liste.</p>
<p><font color="#800000"><b>listmaster </b>: </font>les archives sont accessibles seulement aux administrateurs du service de listes.</p>
<p><font color="#800000"><b>closed </b>: </font>les archives sont fermées à toute consultation.</p>
<p><font color="#800000">Remarque : </font>en temps normal, seuls les deux premiers modes présentent un intérêt. Les autres modes ne doivent être
utilisés que pendant une réorganisation importante des archives, ou en cas d'urgence. Exemple : vous souhaitez supprimer un message que vous estimez
diffamatoire. Vous pourrez interdire la consultation des archives jusqu'au retrait du message litigieux.</p>

[ELSIF p->NAME=archive]
  Définit qui aura le droit de se faire envoyer par e-mail les archives
  récapitulatives des messages de la liste, ainsi que la périodicité de groupage
  de ces archives.<br>
  Par exemple, si la périodicité est "month", l'ensemble des messages passés
  sur la liste en un mois seront regroupés dans un message d'archives
  unique, qui pourra être demandé par e-mail au serveur.<br>
  Si ce paramètre n'est pas défini, la liste n'aura aucune archive consultable
  par mail.
[ELSIF p->NAME=digest]
  Définit quels jours de la semaine, et à quelle heure, seront réalisées les
  compilations de tous les messages récents passés sur la liste, pour être
  envoyés aux abonnés qui ont choisi de ne recevoir que la compilation de la
  liste, plutôt que les messages individuels.
  Evitez de choisir un horaire compris entre 23h et minuit.
[ELSIF p->NAME=available_user_options]
  Définit quelles sont les options de réception disponibles pour cette
liste :<br>
  - digest : Ne recevoir que la compilation périodique de la liste.<br>
  - mail : Recevoir tous les mails individuels transmis par la liste.<br>
  - nomail : Ne RIEN recevoir du tout.<br>
  - notice : Etre uniquement informé des sujets des messages qui passent sur la
    liste.<br>
  - summary : Recevoir périodiquement une compilation qui ne comprend que les
    sujets des messages, sans leur contenu.
[ELSIF p->NAME=default_user_options]
  Définit quelle option de réception (voir available_user_options) sera affectée par défaut
  à un nouvel abonné de cette liste.
[ELSIF p->NAME=reply_to]
<p>Ce mode détermine le comportement du robot lorsqu'un abonné utilise la fonction &quot;répondre&quot; de son logiciel de messagerie en réponse à un
message publié sur la liste.&nbsp;</p>
<p><font color="#800000"><b>sender</b></font> : la réponse est envoyée à l'auteur du message. C'est le mode par défaut défini lors de la création de
la liste.</p>
<p><font color="#800000"><b>list</b></font> : la réponse est envoyée à la liste. Elle sera donc diffusée à tous les abonnés (éventuellement après
modération, suivant la configuration de la liste). Ce mode convient plutôt aux listes de type &quot;liste de discussion&quot;. Si un abonné veut répondre à
l'auteur du message personnellement, il ne doit pas utiliser la fonction &quot;répondre&quot; de son logiciel de messagerie, mais écrire directement à
l'auteur du message.&nbsp; <br>
Une mauvaise utilisation du&nbsp; mode list peut entraîner des situations embarrassantes, comme la publication d'un message personnel. Prévenez donc vos
abonnés du mode de réponse utilisé (dans la page de présentation ou le message de bienvenue).</p>

[ELSIF p->NAME=forced_reply_to]
  Même fonction que pour "reply-to", mais permet de "forcer" l'adresse de
  réponse, même si le message envoyé à la liste spécifiait une adresse de réponse
  différente.<br>
  Si ce paramètre n'est pas défini, et que le message reçu spécifie une adresse
  de réponse, celle-ci sera alors honorée.
[ELSIF p->NAME=bounce]
  Indique le taux d'abonnés en erreur (adresses mail invalides) à partir duquel
  le propriétaire de la liste recevra une notification de "taux d'erreurs
  important" l'invitant à supprimer de sa liste les abonnés en erreur.<br>
  Indique également le taux d'erreurs à partir duquel la distribution des
  messages de la liste sera automatiquement interrompue.
[ELSIF p->NAME=bouncers_level1]
  La gestion automatique des abonnés en erreur permet d'associer des actions à des 
  catégories d'utilisateurs. Ces catégories dépendent du SCORE de chaque abonné en erreur.
  Le Niveau 1 est le plus bas niveau (action par defaut : notification des abonnés en erreur).
  <BR><BR>
    <UL>
    <LI>rate (Default value: 45)<BR><BR>
     Ce paramètre definit la limite inférieure du  niveau 1. Il faut savoir, que 
     les utilisateurs sont notés de 0 à 100. Par exemple, par défaut le niveau 1 concerne
     les abonnés en erreur dont le score est compris entre 45 et 80 <BR><BR>
     </LI>
     <LI>action (Default value: notify_bouncers)<BR><BR>
     Ce paramètre défini l'action automatique qui est effectuée périodiquement sur les abonnés 
     en erreur du niveau 1. La notification tente de prévenir les abonnés en erreur<BR><BR>
     </LI>
     <LI>Notification (Default value: owner)<BR><BR>
     Il est possible de prévenir par email le propriétaire ou le Listmaster, des actions effectuées, et
     des adresses concernées.<BR><BR>
     </LI>
     </UL>    
[ELSIF p->NAME=bouncers_level2]
  La gestion automatique des abonnés en erreur permet d'associer des actions à des 
  catégories d'utilisateurs. Ces catégories dépendent du SCORE de chaque abonné en erreur.
  Le Niveau 2 est le plus haut niveau. <BR><BR>
    <UL>
    <LI>rate (Default value: 80)<BR><BR>
     Ce paramètre definit la limite entre le niveau 2, et le niveau 1. Il faut savoir, que 
     les utilisateurs sont notés de 0 à 100. Par exemple, par défaut le niveau 2 concerne
     les abonnés en erreur dont le score est compris entre 80 et 100 <BR><BR>
     </LI>
     <LI> action (Default value: remove_bouncers)<BR><BR>
     Ce paramètre défini l'action automatique qui est effectuée périodiquement sur les abonnés 
     en erreur du niveau 2.<BR><BR>
     </LI>
     <LI>Notification (Default value: owner)<BR><BR>
     Il est possible de prévenir par email le propriétaire ou le Listmaster, des actions effectuées, et
     des adresses concernées.<BR><BR>
     </LI>
     </UL>    
[ELSIF p->NAME=custom_subject]
Ce texte facultatif est placé en tête du champ sujet de la liste. Il est d'usage de mettre le nom de la liste entre crochets pour faciliter aux abonnés le classement de leur courrier. On peut remplacer les crochets et le nom&nbsp; par toute autre indication permettant d'identifier le message comme provenant de la liste. 
[ELSIF p->NAME=invite]
  Définit qui a le droit de faire envoyer, par l'intermédiaire du serveur, un
  message standard d'invitation à s'abonner à cette liste, en utilisant par mail
  la commande "invite".
[ELSIF p->NAME=max_size]
  Ce paramètre détermine la taille maximum
d'un message qu'on peut poster sur la liste. En cas de dépassement, le message
est retourné à l'envoyeur.
[ELSIF p->NAME=remind]
  Indique qui a le droit de faire envoyer, par l'intermédiaire du serveur, un
  message standard de rappel des abonnements à cette liste, en utilisant par mail
  la commande "remind".
[ELSIF p->NAME=review]
<p>Ce paramètre détermine le droit d'accès à la liste des abonnés, c'est à dire le comportement du robot en réponse à la commande REView ou certains
aspects de la page de présentation de la liste.</p>
<p><font color="#800000"><b>owner</b> </font>: Seul le propriétaire de la liste peut obtenir la liste des abonnés, que les abonnés soient sur la &quot;liste
rouge&quot; ou non. <i><font color="#800000">Ce mode est fortement recommandé </font></i>compte-tenu de la multiplication des &quot;spams&quot;, &quot;hoaks&quot; et autres plaisanteries sur internet.</p>
<p><font color="#800000"><b>private</b> </font>: La liste des abonnés est accessible à tous les abonnés, soit par la commande REV, soit par l'interface
web à condition que l'abonné se connecte en donnant son mot de passe. Dans un cas comme dans l'autre, les adresses électroniques des abonnés inscrits sur la
&quot;liste rouge&quot; restent masquées (voir mode d'emploi de sympa).
N'utilisez ce mode que si vous avez une bonne raison de le&nbsp; faire. Par exemple pour une liste de travail réservée à des interlocuteurs dont
l'activité nécessite qu'ils connaissent l'adresse des autres colistiers. Cela implique aussi un mode d'abonnement <font color="#800000">closed</font>, ou à
la rigueur <font color="#800000">owner</font>. </p>

[ELSIF p->NAME=shared_doc]
  Définit qui a le droit de consulter et de modifier les documents qui peuvent
  être mis en place dans un "espace partagé" correspondant à cette liste de
  diffusion.
[ELSIF p->NAME=status]
  Indique l'état actuel de cette liste :<br>
  - Open : Liste active<br>
  - Closed : Liste fermée<br>
  - Pending : Liste en attente d'approbation et d'installation par
    l'administrateur du serveur (listmaster).
[ELSIF p->NAME=anonymous_sender]
  Si on désire que les messages transmis sur la liste masquent l'adresse e-mail
  de l'auteur réel du message (expéditeur anonyme), il est possible d'indiquer
  ici une adresse e-mail. Tous les messages diffusés sur cette liste indiqueront
  alors cette adresse e-mail comme "auteur" du message.
[ELSIF p->NAME=clean_delay_queuemod]
  Indique le délai (en jours) au delà duquel les messages en attente de
  modération pour cette liste, mais qui n'auraient pas été traités (ni approuvés,
  ni rejetés) seront automatiquement supprimés par le serveur.
[ELSIF p->NAME=custom_header]
  Définit un header personnalisé supplémentaire qui sera ajouté à chaque
  message transmis sur cette liste.
[ELSIF p->NAME=footer_type]
  Indique la manière dont l'en-tête et le pied-de-lettre standard de la liste sont ajoutés aux messages
  diffusés sur cette liste :<br>
  - mime : Ces éléments seront ajoutés au message sous forme de parties MIME
    séparées. Si le message est au départ de type multipart/alternative, ces
    éléments seront cependant ignorés.<br>
  - append : Sympa ne créera pas de parties MIME, mais ajoutera directement les
    textes d'en-tête et de pied-de-lettre au corps du message, uniquement si
    celui-ci est de type text/plain. Dans le cas contraire, rien ne sera ajouté.
[ELSIF p->NAME=priority]
  Définit la priorité de traitement de cette liste, de la plus haute (1) à la
  plus basse (9). Si la priorité est "z", les messages pour cette liste resteront
  indéfiniment en attente.
[ELSIF p->NAME=serial]
  Numéro de série de la configuration (nombre de modifications).
[ELSE]
  Pas d'aide disponible pour ce paramètre
[ENDIF]

</DL>
[END]
	
