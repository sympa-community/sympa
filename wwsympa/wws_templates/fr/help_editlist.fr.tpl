<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]) :
<DL>
<DD>
[IF p->NAME=subject]
  Sujet de la liste tel qu'il apparaîtra dans l'annuaire des listes
[ELSIF p->NAME=visibility]
  Définit si la liste sera visible pour tous, ou si sa visibilité sera
  restreinte.
[ELSIF p->NAME=info]
  Indique qui peut consulter la page d'information (page d'accueil) de la
  liste.
[ELSIF p->NAME=subscribe]
  Définit les conditions requises pour s'abonner à cette liste. Principalement,
  l'abonnement peut être ouvert à tous (libre) ou soumis à autorisation du
  propriétaire de la liste.<br>
  Il est conseillé de toujours choisir une option comportant le paramètre "auth",
  car ainsi le système demandera confirmation par mail au futur abonné avant de l'abonner
  à la liste. Ceci permet à la fois d'éviter des prises d'abonnement avec une
  adresse e-mail invalide, et assure que personne ne peut être abonné à la liste
  contre son gré (par un tiers).
  Si l'option comporte le paramètre "notify", le propriétaire de la liste sera
  averti par mail pour chaque nouvel abonnement.
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
  Définit le ou les propriétaires de la liste.
[ELSIF p->NAME=send]
  Définit qui peut envoyer des messages à la liste.<br>
  Dans la plupart des cas, le droit de poster dans une liste est :<br>
  - soit réservé aux abonnés de cette liste, sans modération, et c'est alors le
    paramètre "private" qui s'applique.<br>
  - soit soumis à l'approbation du message par les modérateurs de la
    liste, et c'est alors les paramètres "editor", "editorkey" ou
    "editorkeyonly" qui s'appliquent.<br>
  - soit la liste est de type "lettre d'information" issue uniquement des
    modérateurs, et il faut alors utiliser "newsletter",
    "newsletterkey" ou "newsletterkeyonly".<br>
  Les modes d'approbation diffèrent selon la sécurité qu'ils apportent :<br>
  - editor ou editorkey : Un message provenant (from) du modérateur sera diffusé directement.
    Un message ne provenant pas du modérateur sera transmis à celui-ci pour
    approbation. Cependant, l'authenticité de la provenance n'est pas vérifiée,
    aussi, une forme de falsification est possible.<br>
  - editorkeyonly : Tout message devra être confirmé par le modérateur (au moyen
    d'une clé de contrôle qui lui sera envoyée par le serveur), MEME si ce
    message semble provenir directement du modérateur lui-même. Ceci limite très
    fortement les possibilités de fraude dans la diffusion de messages, mais rend
    le processus de modération plus lourd.
[ELSIF p->NAME=editor]
  Définit qui sont le ou les "modérateurs" de la liste, si celle-ci est
  "modérée". Les modérateurs ont la charge d'approuver chaque message avant sa
  diffusion sur la liste.<br>
  Par défaut, le modérateur est le propriétaire de la liste, même si celle-ci n'a
  pas été définie comme modérée.<br>
  Pour que la modération soit active, il faut définir ce comportement dans le
  paramètre "send" (Qui peut diffuser des messages).<br>
  Astuce : Si la liste n'est pas modérée, et que l'on ne souhaite pas afficher de
  nom ou d'adresse e-mail de modérateur sur la page "Info" de la liste, il est
  possible d'indiquer "Liste non modérée" par exemple, à la place du nom du
  premier modérateur.
[ELSIF p->NAME=topics]
  Définit la ou les rubrique(s) de l'annuaire des listes dans lesquelles cette
  liste sera classée.
[ELSIF p->NAME=host]
  Indique le nom de serveur pour cette liste. L'adresse de la liste sera alors
  nom_de_la_liste@host
[ELSIF p->NAME=lang]
  Définit la langue principale en usage pour cette liste.
[ELSIF p->NAME=web_archive]
  Définit qui aura le droit de consulter les messages de la liste en utilisant
  l'interface web du serveur.<br>
  Si ce paramètre n'est pas défini, aucune archive web ne sera créée.
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
  Définit ce qui se passe par défaut quand un abonné utilise le bouton
  "répondre" sur un message provenant de la liste :<br>
  - list : La réponse est adressée à la liste.<br>
  - sender : La réponse est adressée à l'auteur du message original.
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
[ELSIF p->NAME=custom_subject]
  Définit un sujet fixe qui apparaîtra entre crochets pour chaque message
  transmis par la liste, afin d'en faciliter le classement.<br>
  Il est d'usage d'indiquer ici le nom de la liste, ou son abréviation.<br>
  Ne pas mettre les crochets, qui seront ajoutés automatiquement par le système.
[ELSIF p->NAME=invite]
  Définit qui a le droit de faire envoyer, par l'intermédiaire du serveur, un
  message standard d'invitation à s'abonner à cette liste, en utilisant par mail
  la commande "invite".
[ELSIF p->NAME=max_size]
  Indique la taille maximale des messages qui seront acceptés sur cette liste.
  Les messages plus gros seront rejetés.
[ELSIF p->NAME=remind]
  Indique qui a le droit de faire envoyer, par l'intermédiaire du serveur, un
  message standard de rappel des abonnements à cette liste, en utilisant par mail
  la commande "remind".
[ELSIF p->NAME=review]
  Indique qui a le droit de consulter la liste des abonnés de cette liste de
  diffusion.
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
	
