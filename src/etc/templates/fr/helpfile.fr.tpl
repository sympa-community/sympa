
              SYMPA -- Systeme de Multi-Postage Automatique
 
                       Guide de l'utilisateur


SYMPA est un gestionnaire de listes electroniques. Il permet d'automatiser
les fonctions de gestion des listes telles les abonnements, la moderation
et la gestion des archives.

Toutes les commandes doivent etre adressees a l'adresse electronique
[conf->sympa]

Il est possible de mettre plusieurs commandes dans chaque message : les
commandes doivent apparaitre dans le corps du message et chaque ligne ne
doit contenir qu'une seule commande. Sympa ignore le corps du message
si celui-ci n'est de type "Content-type: text/plain", mais même si vous
etes fanatique d'un agent de messagerie qui fabrique systematiquement des
messages "multipart" ou "text/html", les commandes placees dans le sujet
du messages sont reconnues.

Les commandes disponibles sont :

 HELp                        * Ce fichier d'aide
 LISts                       * Annuaire des listes geres sur ce noeud
 REView <list>               * Connaitre la liste des abonnes de <list>
 WHICH                       * Savoir à quelles listes on est abonné
 SUBscribe <list> Prenom Nom * S'abonner ou confirmer son abonnement a la 
			       liste <list>
 SIGnoff <list|*> [user->email]    * Quitter la liste <list>, ou toutes les listes.
                               Où [user->email] est facultatif

 SET <list|*> NOMAIL         * Suspendre la reception des messages de <list>
 SET <list|*> DIGEST         * Reception des message en mode compilation
 SET <list|*> SUMMARY        * Reception de la liste des messages uniquement
 SET <list|*> NOTICE         * Reception de l'objet des message uniquement

 SET <list|*> MAIL           * Reception de la liste <list> en mode normal
 SET <list|*> CONCEAL        * Passage en liste rouge (adresse d'abonné cachée)
 SET <list|*> NOCONCEAL      * Adresse d'abonné visible via REView

 INFO <list>                 * Informations sur une liste
 INDex <list>                * Liste des fichiers de l'archive de <list>
 GET <list> <fichier>        * Obtenir <fichier> de l'archive de <list>
 LAST <list>		     * Obtenir le dernier message de <list>
 INVITE <list> <email>       * Inviter <email> a s'abonner à <list>
 CONFIRM <clef>	 	     * Confirmation pour l'envoi d'un message
			       (selon config de la liste)
 QUIT                        * Indique la fin des commandes (pour ignorer 
                               une signature

[IF is_owner]
Commandes réservées aux propriétaires de listes:
 
 ADD <list> user@host Prenom Nom * Ajouter un utilisateur a une liste
 DEL <list> user@host            * Supprimer un utilisateur d'une liste
 STATS <list>                    * Consulter les statistiques de <list>
 EXPire <list> <ancien> <delai>  * Déclanche un processus d'expiration pour
                                   les abonnés à la liste <list> n'ayant pas
				   confirmé leur abonnement depuis <ancien>
				   jours. Les abonnés ont <delai> jours pour
				   confirmer
 EXPireINDex <list>              * Connaitre l'état du processus d'expiration
                                   en cours pour la liste <list>
 EXPireDEL <list>                * Désactive le processus d'espiration de la
                                   liste <list>

 REMind <list>                   * Envoi à chaque abonné un message
                                   personnalisé lui rappelant
                                   l'adresse avec laquelle il est abonné.
[ENDIF]

[IF is_editor]

Commandes réservées aux modérateurs de listes :

 DISTribute <list> <clef>        * Modération : valider un message
 REJect <list> <clef>            * Modération : invalider un message
 MODINDEX <list>                 * Modération : consulter la liste des messages
                                   à modérer
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
