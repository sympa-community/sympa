<!-- RCS Identication ; $Revision$ ; $Date$ -->

Description des messages de service :<UL>
<LI>Message de bienvenue : Ce message est envoyé aux nouveaux abonnés.
Vous pouvez utiliser un message MIME structuré (réservé aux experts
du format MIME).

<LI>Message de désabonnement : Envoyé aux personnes qui se désabonnent de la liste.

<LI>Message de suppression : Envoyé aux personnes supprimés de la liste des abonnés
par le propriétaire de la liste ou via le module de gestion des erreurs.

<LI>Message de rappel individualisé : Message envoyé à chaque abonné lors du rappel des abonnements. Ce message peut être envoyé depuis l'interface d'administration de liste dans la page <i>abonnés</i>. Cette procédure est très utile
pour aider chaque personne à se désabonner au cas où celles-ci
ne connaissent plus leur adresse d'abonnement.

<LI>Invitation à s'abonner : Message envoyé à une personne via la commande
<CODE>INVITE [nom de liste]</CODE>.

Description des autres fichiers/pages :<UL>
<LI>Page d'accueil de la liste : Description de la liste  au format HTML. S'affiche en partie droite de la page de la liste. (a pour défaut la description de la liste)

<LI>Description de la liste : Ce texte est envoyé en retour
à la commande <code>INFO [nom de liste]</code> en mode messagerie.
Il est aussi inclus dans le <I>message de bienvenue</I>.

<LI> Attachement de début de message : Si non vide, ce fichier est
attaché au début de chaque message diffusé dans la liste.
<LI> Attachement de fin de message : Identique à l'<i>Attachement de début de message</i> mais attaché en fin de message.


</UL>

	


