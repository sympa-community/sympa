<!-- RCS Identication ; $Revision$ ; $Date$ -->

Description des messages de service :<UL>
<LI>Message de bienvenue : Ce message est envoyé aux nouveaux abonnés.
Vous pouvez utiliser un message MIME structuré (réservé aux experts
du format MIME).

<LI>Message de désabonnement : Envoyé aux personnes qui se désabonnent de la liste.

<LI>Message de suppression : ce message est envoyé aux personnes, que vous désabonnez (commande DEL),&nbsp; notamment parce que leur adresse a généré des erreurs.

<LI>Message de rappel individualisé : ce message est envoyé aux
abonnés lors d'un rappel individualisé (commande REMIND). La commande REMIND est importante pour la bonne gestion de votre liste, car de nombreuses erreurs d'acheminement du courrier (bounces) sont dues à des personnes dont l'adresse courante ne correspond plus à l'adresse d'abonnement, ou même qui ont oublié leur abonnement. 


<LI>Invitation à s'abonner : Message envoyé à une personne via la commande
<CODE>INVITE [nom de liste]</CODE>.
</UL>

Description des autres fichiers/pages :<UL>

<LI>Description de la liste : ce texte décrivant la liste est envoyé par mél en réponse à la commande INFO. 
Il peut également être automatiquement  inclus dans le message de bienvenue. Il ne doit pas être confondu avec la page de présentation de la liste qui est affichée sur le site wws, et qui est éditable à partir du lien <i>Editer la page de présentation de la liste</i>. 

<LI>Page d'accueil de la liste : ce texte décrivant la liste est présenté dans la partie droite de la page d'info de la liste. Il peut être au format HTML. Si vous n'utilisez pas ce format, employez toutefois les balises BR pour marquer les sauts de ligne.
Par ailleurs, un texte de présentation de la liste peut être envoyé par mél à tout nouvel abonné, ou en réponse à la commade INFO. Ce texte fait partie des 
messages de service modifiables

<LI>Description de la liste : Ce texte est envoyé en retour
à la commande <code>INFO [nom de liste]</code> en mode messagerie.
Il est aussi inclus dans le <I>message de bienvenue</I>.

<LI>Attachement de début de message : s'il est défini, une partie MIME comprenant le texte sera ajoutée au début de chaque message
diffusé dans la liste.

<LI>Attachement de fin de message : s'il est défini, une partie MIME comprenant le texte sera ajoutée en fin de chaque message
diffusé dans la liste.

</UL>

	


