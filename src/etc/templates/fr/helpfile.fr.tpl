
              SYMPA -- Système de Multi-Postage Automatique
 
                       Guide de l'utilisateur


SYMPA est un gestionnaire de listes électroniques. Il permet d'automatiser
les fonctions de gestion des listes telles que les abonnements, la modération
et la gestion des archives.

Toutes les commandes doivent être adressées à l'adresse électronique
[conf->sympa].

Il est possible de mettre plusieurs commandes dans chaque message :
les commandes doivent apparaître dans le corps du message et chaque ligne ne
doit contenir qu'une seule commande. Sympa ignore le corps du message
si celui-ci n'est pas de type "Content-type: text/plain", mais même si vous
êtes fanatique d'un agent de messagerie qui fabrique systématiquement des
messages "multipart" ou "text/html", les commandes placées dans le sujet
du messages sont reconnues.

Les commandes disponibles sont :

 HELp                        * Recevoir ce fichier d'aide
 LISts                       * Recevoir l'annuaire des listes gérées sur ce
                               noeud
 REView <list>               * Recevoir la liste des abonnés à <list>
 WHICH                       * Recevoir la liste des listes auxquelles
                               on est abonné
 SUBscribe <list> Prénom Nom * S'abonner ou confirmer son abonnement à <list>
 SIGnoff <list|*> [user->email]    * Quitter <list>, ou toutes les listes
                               ([user->email] est facultatif)

 SET <list|*> NOMAIL         * Suspendre la réception des messages de <list>
 SET <list|*> MAIL           * Recevoir les messages en mode normal
 SET <list|*> DIGEST         * Recevoir une compilation des messages
 SET <list|*> DIGESTPLAIN    * Recevoir une compilation des messages, en mode texte,
	                       sans les attachements
 SET <list|*> SUMMARY        * Recevoir la liste des messages uniquement
 SET <list|*> NOTICE         * Recevoir l'objet des message uniquement

 SET <list|*> CONCEAL        * Passage en liste rouge (adresse d'abonné cachée)
 SET <list|*> NOCONCEAL      * Adresse d'abonné visible via REView

 INFO <list>                 * Recevoir les informations sur <list>
 INDex <list>                * Recevoir la liste des fichiers de l'archive
                               de <list>
 GET <list> <fichier>        * Recevoir <fichier> de l'archive de <list>
 LAST <list>                 * Recevoir le dernier message de <list>
 INVITE <list> <e-mail>      * Inviter <e-mail> à s'abonner à <list>
 CONFIRM <clef>              * Confirmer l'envoi d'un message
                               (selon la configuration de la liste)
 QUIT                        * Indiquer la fin des commandes
                               (pour ignorer une signature)

[IF is_owner]
Commandes réservées aux propriétaires de listes :
 
 ADD <list> user@host Prenom Nom * Ajouter un utilisateur à <list>
 DEL <list> user@host            * Supprimer un utilisateur de <list>
 STATS <list>                    * Consulter les statistiques de <list>
 EXPire <list> <ancien> <delai>  * Déclancher un processus d'expiration pour
                                   les abonnés à <list> n'ayant pas confirmé
                                   leur abonnement depuis <ancien> jours.
                                   Les abonnés ont <delai> jours pour
                                   confirmer
 EXPireINDex <list>              * Connaître l'état du processus d'expiration
                                   en cours pour la liste <list>
 EXPireDEL <list>                * Désactiver le processus d'expiration de
                                   <list>

 REMind <list>                   * Envoyer à chaque abonné un message
                                   personnalisé lui rappelant l'adresse
                                   avec laquelle il est abonné
[ENDIF]

[IF is_editor]

Commandes réservées aux modérateurs de listes :

 DISTribute <list> <clef>        * Modération : valider un message
 REJect <list> <clef>            * Modération : invalider un message
 MODINDEX <list>                 * Modération : consulter la liste des messages
                                                à modérer
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
