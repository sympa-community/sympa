$ 16 Oct 2000, Add Web specific translations <os@cru.fr>
$ 14 Apr 2000, Changes for moderation Raphael Hertzog <rhertzog@hrnet.fr>

$ codeset=iso-8859-1
$quote "

$set 1	Messages utilisés pour l'analyse du fichier de configuration
1	"Le fichier de configuration contient des erreurs.\n"
3	"Erreur ligne %d : %s"
102	"3.3a"

$set 2	Messages utilisés par Conf dans la vérification des fichiers

$set 3	Messages divers dans le programme principal
1	"Impossible d'aller dans le repertoire %s : %m"

$set 4	Messages utilisés dans la boucle principale
11	"Votre message pour %s a ete rejete"
12	"Votre message ne peut pas être envoyé car il dépasse la taille maximale\n\
autorisée pour cette liste.\n"
15	"Votre message pour la liste %s a été rejeté.\n\
Le message vous est donc renvoyé.\n\n\
Votre message :\n"
17	"Resultats de vos commandes"
18	"Commande 'quit' trouvée : la fin du message est ignorée.\n"
19	"Commande non comprise : la fin du message est ignorée.\n"
24	"Fin de votre commande EXPIRE de la liste %s"
26	"Ces abonnés sont :\n"
27	"Si vous voulez retirer ces abonnés de la liste utilisez les commandes :\n"
28	"Parmi les abonnés à la liste %s depuis %d jours, %d n'ont pas confirmé leur abonnement.\n"
37	"Corps de message ignoré, utilisez uniquement du text/plain\n(ou mettez vos commandes dans le sujet du message)\n"
38	"Votre message pour la liste %s a été transmis au(x) modérateur(s)\n"
39	"Aucune commande n'a été reconnue dans votre message"
40	"Modération de votre message"

$set 5	Messages utilisés dans le module tools
1	"Safefork ne peut pas créer un nouveau processus : %m"
2	"Erreur d'aiguillage ?"
3	"Le message suivant a été adressé à une liste alors qu'il semble\n\
contenir des commandes telles que subscribe, signoff, help, index, get, ...\n\n\
Si effectivement votre message contenait une commande, sachez que les commandes\n\
ne doivent en aucun cas être adressées aux listes. Elles sont à envoyer à\n\
l'adresse %s exclusivement.\n\n\
Si votre message était effectivement destiné à la liste, celui-ci a malheureu-\n\
sement été interprété par le logiciel comme une commande. Veuillez contacter\n\
le gestionnaire du service : %s afin qu'il s'occupe de\n\
votre message.\n\nMerci de votre attention.\n\n\
------ Début du message suspect ------\n"
4	"------ Fin du message suspect ------\n"

$set 6	Messages du module Commands.pm
2	"Impossible de lire le fichier d'aide : %s\n"
3	"La liste '%s' ne comporte aucun abonné.\n"
5	"Liste '%s' inexistante.\n"
6	"Informations concernant la liste %s :\n\n"
7	"Il n'y a pas de fichiers dans les archives de cette liste.\n"
8	"Le fichier demande n'existe pas.\n"
9	"La liste est privée : vous ne pouvez pas consulter les archives.\n"
10	"La liste est privée : vous ne pouvez pas consulter la liste des\n\
fichiers disponibles.\n"
11	"La liste est privée : vous ne pouvez pas consulter la liste des\n\
abonnés.\n"
13	"Erreur de syntaxe.\n"
15	"La phase d'authentification a échoué.\n\n"
16	"Vous avez très probablement validé votre abonnement en utilisant une\n\
adresse différente. Veuillez reformuler une demande d'abonnement en\n\
utilisant votre adresse canonique."
18	"Vous avez été retiré de la liste %s"
21	"Renouvellement de votre abonnement à la liste '%s'"
24	"Les abonnements à cette liste sont suspendus.\n"
25	"Votre demande d'abonnement (ou de désabonnement) a été envoyée aux propriétaires de la liste\n\
pour examen. Vous recevrez une notification lorsque ceux-ci vous auront\n\
abonné (ou désabonné) à la liste.\n"
26	"La fonction de désabonnement n'est pas disponible pour la liste %s.\n"
27	"Les informations vous concernant ont été mises à jour.\n"
28	"Vous êtes maintenant abonné à la liste %s.\n"
29	"Les informations sur cette liste seront envoyés dans un autre message.\n"
30	"L'adresse %s n'a pas été trouvée dans la liste %s. Peut-être\n\
vous êtes vous abonné avec une adresse différente ?\n"
31	"Votre adresse a été supprimée de la liste %s. Merci de\n\
votre présence sur la liste.\n"
32	"Les propriétaires de la liste %s sont les seuls habilités\n\
à ajouter ou supprimer des abonnés. Vous n'êtes pas autorisé à utiliser\n\
cette commande, ou bien vous n'avez pas fourni les informations nécessaires\n\
à votre identification.\n"
33	"L'adresse électronique %s n'a pas été trouvée\n\
sur la liste.\n"
34	"Votre adresse a été retirée de la liste %s\n\
par %s, gestionnnaire de cette liste.\n\n\
Cette opération est en générale le résultat des différentes opérations\n\
de suppression de la liste des abonnés des adresses erronées.\n\
Il se peut cependant que votre adresse fonctionne correctement. Si tel était\n\
le cas, veuillez nous excuser du désagrément. et vous réabonner.\n"
35	"L'archive vous est envoyée dans un message séparé.\n"
36	"Les informations concernant l'utilisateur %s ont été mises à jour dans la liste %s.\n"
37	"L'utilisateur %s est maintenant abonné à la liste %s.\n"
38	"L'utilisateur %s a été retiré de %s\n"
39	"Quelqu'un (probablement vous) a demandé l'ajout ou la suppression d'un\n\
utilisateur de la liste %s.\n\n\
Si vous confirmez que cette action doit être entreprise, veuillez renvoyer\n\
un courrier électronique à l'adresse %s avec :\n\n\
   %s\n\n\
Si vous ne souhaitez pas que l'action soit entreprise, vous pouvez ignorer\n\
ce message.\n"
40	"Votre configuration concernant la liste %s a été mise à jour.\n"
41	"Impossible d'accéder au message à modérer de la liste %s avec la clé %s.\n\
Il se peut que ce message ait déjà été diffusé par un modérateur de la liste\n.\n"
43	"Le message %s pour la liste %s a été rejeté.\n"
44	"Le message %s pour la liste %s a été distribué.\n"
45	"La liste %s n'accepte pas le mode DIGEST. Votre configuration concernant cette liste n'a pas été modifiée.\n"
46	"La commande MODINDEX est réservée aux modérateurs.\n\
Vous n'êtes pas modérateur de la liste %s.\n"
47	"Les commandes EXPIRE,EXPIREINDEX et EXPIREDEL sont réservées aux propriétaires.\n\
Vous n'êtes pas propriétaire de la liste %s.\n"
48	"\
Quelqu'un (probablement vous) a demandé que les abonnés à la\n\
liste '%s' depuis plus de %d jours reconfirment leur abonnement.\n\
Si vous ne souhaitez pas que l'action soit entreprise, vous pouvez ignorer ce message.\n\
Pour confirmer, veuillez renvoyer un courrier électronique à l'adresse '%s' avec la commande suivante :\n\
\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Une commande EXPIRE est en cours d'exécution pour la liste %s.\n\
Elle a été exécutée par le propriétaire %s (%s)\n\
Un seul processus 'expire' peut être déclenché à la fois pour \n\
une même liste.\n\
L'expiration en cours concerne les personnes abonnées depuis plus \n\
de %d jours n'ayant pas confirmé leur abonnement. L'expiration \n\
s'arrêtera dans %d jour(s) (%s).\n"
52	"%s n'a pas reçu de confimation pour les adresses suivantes :\n"
53	"Pour interrompre le processus d'expiration : EXPIREDEL %s\n"
54	"La liste %s n'a pas d'expiration en cours.\n"
55	"Vous venez d'arrêter la commande d'expire en cours de la liste %s\n"
56	"\
Un processus d'expiration est initié pour la liste %s. Ce processus\n\
se terminera dans %d jours. Vous recevrez alors la liste des abonnés \n\
n'ayant pas confirmé leur abonnement dans le délai imposé\n\
Vous pourrez alors supprimer vous-même ces adresses à l'aide de la commande DEL.\n"
57	"Pour consulter la liste des abonnements non confirmés : EXPIREINDEX %s\n"
58	"Vous pouvez retirer ces abonnés de la liste avec les commandes suivantes :\n"
60	"\
La commande EXPIRE n'a pu être exécutée. Elle doit être suivie\n\
d'un texte d'explication destiné aux abonnés qui doivent confirmer\n\
leur abonnement. Ce texte doit\n\n\
 - commencer juste après la ligne de la commande expire\n\
 - contenir au moins 20 mots\n\
 - se terminer par la commande QUIT\n"
61	"Votre message vous est donc renvoyé :\n"
67	"Voici les listes auxquelles vous êtes abonné :\n\n"
68	"Impossible d'accéder au message authentifié avec la clé %s.\n"
69	"%s a posté votre message d'expiration aux adresses suivantes :\n"
70	"\nService rendu par Sympa %s : http://www.sympa.org/\n"
71	"Desabonnement de la liste %s"
72	"Voici les listes dont vous êtes propriétaire :\n\n"
73	"Voici les listes dont vous êtes modérateur :\n\n"
74	"Authentification demandée à %s pour la commande %s\n"
75	"Aucun désabonnement possible pour l'adresse %s\n"
76	"Rappel de votre abonnement dans la liste %s"
77	"Vous êtes abonné dans la liste %s avec l'adresse %s.\n"
78	"Rappel d'abonnement envoyé aux %d abonnés de %s.\n"
79	"Quelqu'un (probablement vous) a demandé à ce que chaque abonné\n\
de la liste %s recoive un rappel individualisé de son abonnement\n\n\
Si vous confirmez que cette action doit être entreprise, veuillez renvoyer\n\
un courrier électronique à l'adresse %s avec :\n\n\
   %s\n\n\
Si vous ne souhaitez pas que l'action soit entreprise, vous pouvez ignorer\n\
ce message.\n"
80	"Vous n'êtes pas autorisé à exécuter la commande %s dans la liste %s.\n"
81	"Mode d'emploi"
82	"Les listes publiques"
83	"Synthese de vos abonnements"
84	"Cette personne '%s' est déjà abonnée à la liste '%s'.\n"
85	"Cette personne '%s' a été conviée à s'abonner dans la liste '%s'.\n"
86	"Cette personne '%s' est indésirable dans la liste '%s'.\n"
90	"La liste %s autorise uniquement ces modes de réception : %s\n\
Votre configuration concernant n'a pas été modifiée.\n"
91	"La liste %s ne propose pas d'options d'abonnement.\n"
92	"Vos options d'abonné à la liste %s n'ont pu être mises à jour.\n"
260	"Quelqu'un (probablement vous) a demandé votre abonnement à la  liste '%s'.\n\
Pour confirmer cette action veuillez :\n\
- répondre à ce message\nOU\n\
- envoyer un courrier à '%s' avec pour sujet\n%s\nOU\n\
- cliquez l'URL %s )\n\n\
Si vous ne souhaitez pas que l'action soit entreprise, ignorez simplement\n\
ce message.\n"
261	"Quelqu'un (probablement vous) a demandé votre désabonnement de la liste '%s'.\n\n\
Pour confirmez cette action veuillez :\n\
- répondre à ce message\nOU\n\
- envoyer un courrier à '%s' avec pour sujet\n%s\nOU\n\
- cliquez l'URL %s )\n\n\
Si vous ne souhaitez pas que l'action soit entreprise, ignorez simplement\n\
ce message.\n"
262	"Signature S/MIME correctement vérifiée"
263	"Message non signé ou signature non reconnue (attention, Sympa ne peut\n verifier une signature S/MIME pour une commande dans l'entête Subject:)"

$set 7	Messages syslog des commandes (Commands.pm)

$set 8	Messages utilises dans List.pm
1	"Proprietaires de la liste %s"
2	"Demande d'abonnement à la liste %s"
3	"Cher propriétaire de la liste %s,\n\n\
Un utilisateur a demandé à être abonné à votre liste. Pour valider cette,\n\
demande, vous voudrez bien cliquer sur ce lien :\n\
mailto:%s?subject=auth%%20%s%%20ADD%%20%s%%20%s%%20%s\n\n\
Ou alors envoyer un mail à %s avec comme objet :\n\
AUTH %s ADD %s %s %s\n"
6	"Bienvenue sur la liste %s"
7	"Fichier"
9	"Compilation de la liste %s"
12	"Pour diffuser le message ci-joint dans la liste %s,\n\
cliquez sur ce lien :\n\
mailto:%s?subject=CONFIRM%%20%s\n\
Ou alors envoyez un mail à %s avec comme sujet :\n\
CONFIRM %s\n"
13	"Sommaire"
14	"Fin de compilation de la liste %s"
16	"Authentification demandée"
21	"Pour info %s liste %s de %s %s"
22	"Pour Info, opération %s dans la liste %s de %s %s \n(aucune action requise)"
23	"ATTENTION : %s %s a échoué dans une tentative de se désabonner de la liste %s\n(Vous devriez peut-être aider cette personne)"
24	"Demande de desabonnement de la liste %s"
25	"Cher(s) propriétaires de la liste %s,\n\n\
Un utilisateur a demandé à être DÉSabonné de votre liste. Pour valider cette,\n\
demande, vous voudrez bien cliquez sur ce lien :\n\
mailto:%s?subject=auth%%20%s%%20DEL%%20%s%%20%s\n\n\
Ou alors envoyez un mail à %s avec comme objet :\n\
AUTH %s DEL %s %s\n"
26	"Pour Info, opération %s dans la liste %s de %s %s validée par %s\n(aucune action requise)"
27	"Le taux de bounces dans la liste %s est de %d%%.\n\n\
Vous devriez supprimer les abonnés en erreur : \n\
%s/reviewbouncing/%s"
28	"ATTENTION: taux de bounces trop eleve dans la liste %s"
29	"Invitation dans la liste %s"
30	"Vous êtes invité à vous abonner à la liste %s"
31	"Résumé de la liste %s"

$set 9	Messages pour l'entête review
1	"Propriétaire       : %s\n"
2	"Modérateur         : %s\n"
3	"Abonnement         : %s\n"
4	"Désabonnement      : %s\n"
5	"Envoi de messages  : %s\n"
6	"Liste des abonnés  : %s\n"
7	"Répondre à         : %s\n"
8	"Taille maximale    : %d\n"
9	"URL de la liste    : %s\n"
10	"Digest             : %s\n"
11	"Sujet personnalisé : %s\n"
12	"Sujet              : %s\n"
13	"Modes de réception : %s\n"

$set 11	Messages utilisés par le module smtp.
1	"Votre système ne semble pas répondre au standard POSIX P1003.1, ou bien\n\
votre système Perl ne définit pas la constante _SC_ARG_MAX dans sa bibliothèque\n\
POSIX. Il est nécessaire que vous modifiez le module smtp.pm afin de fixer une\n\
valeur pour la variable $max_arg.\n"
2	"Impossible de créer un canal dans smtpto: %m"

$set 12 Entêtes MIME
1	"1.0"
2	"iso-8859-1"
3	"8bit"
4	"SYMPA <%s>"

$set 14 Pour le web
1	"fr_FR"
2	"français"

$set 15 Templates files
1	"message de bienvenue"
2	"message de désabonnement"
3	"message de suppression"
4	"attachement de fin de message"
5	"attachement de début de message"
6	"message de rappel individualisé"
7	"message de rejet par le modérateur"
8	"message d'invitation à s'abonner"
9	"fichier d'aide"
10	"liste des listes"
11	"message de rappel global"
12	"résumé des messages"
13	"description de la liste"
14	"page d'accueil de la liste"
15	"demande de création de liste"
16	"notification de création de liste"
17	"rejet d'un message contenant un virus"
18	"modèle d'alias de liste"

$set 16 Titres des paramètres de config de listes
1	"Compte"
2	"Qui peut ajouter des abonnés"
3	"Auteur anonyme"
4	"Archives textuelles"
5	"périodicité"
6	"droit d'accès"
7	"Gestion des bounces"
8	"seuil d'alerte"
9	"seuil d'interruption"
10	"Expiration des messages non modérés"
11	"Secret pour la génération de clefs"
12	"Création de la liste"
16	"Champs d'entête personnalisés"
17	"Marquage du sujet des messages"
18	"Profil d'abonnement"
19	"mode de réception"
20	"visibilité"
21	"Qui peut supprimer des abonnés"
22	"Périodicité des compilations"
23	"jours"
24	"heure"
25	"minute"
26	"Modérateurs"
27	"adresse email"
28	"mode de réception"
29	"nom"
30	"informations privées"
31	"Type d'attachement"
32	"Adresse de réponse forcée"
33	"Domaine internet"
34	"Inclusion d'un fichier"
35	"Inclusion d'une requête LDAP"
36	"serveur distant"
37	"port"
38	"utilisateur"
39	"mot de passe"
40	"suffixe"
41	"filtre"
42	"attribut à extraire"
43	"sélection (si multiple)"
44	"Inclusion d'une liste"
45	"Inclusion d'une requête SQL"
46	"type de la base"
47	"serveur distant"
48	"nom de la base"
49	"utilisateur"
50	"mot de passe"
51	"requête SQL"
53	"Qui a accès aux informations sur la liste"
54	"Qui peut inviter à s'abonner"
55	"Langue de la liste"
56	"Taille maximum des messages"
57	"Propriétaires"
58	"adresse email"
59	"mode de réception"
60	"nom"
61	"informations privées"
62	"profil"
63	"Priorité de la liste"
64	"Qui peut déclencher un processus de rappel des abonnements"
65	"Return-path de remind"
66	"Adresse de réponse"
67	"Qui a accès à la liste des abonnés"
68	"Qui peut diffuser des messages"
69	"Numéro de série de la config"
70	"Partage de documents"
71	"Etat de la liste"
72	"Objet de la liste"
73	"Qui peut s'abonner"
74	"Catégorie de la liste"
75	"Expiration des inclusions"
76	"Qui peut se désabonner"
77	"Dernière mise à jour de la config"
81	"Source de données"
82	"Visibilité de la liste"
83	"Archives web"
84	"droit d'accès"
85	"Return-path d'abonnement"
86	"droit de consultation"
87	"droit d'édition"
88	"Options d'abonné disponibles"
89	"mode de réception"
90	"Adresse de réponse"
91	"valeur"
92	"autre adresse email"
93	"respect du champ existant"
94	"paramètres de connexion"
97	"portée de la recherche"
98	"délai de connexion"
135	"Inclusion d'une requête LDAP (2 passes)"
136	"serveur distant"
137	"port"
138	"utilisateur"
139	"mot de passe"
140	"suffixe (1er niveau)"
141	"filtre (1er niveau)"
142	"attribut à extraire (1er niveau)"
143	"sélection (1er niveau)"
144	"suffixe (2nd niveau)"
145	"filtre (2nd niveau)"
146	"attribut à extraire (2nd niveau)"
147	"sélection (2nd niveau)"
148	"variable d'environnement pour la connexion"
197	"portée de la recherche (1er niveau)"
198	"délai de connexion (1er niveau)"
199	"portée de la recherche (2nd niveau)"
200	"élai de connexion (2nd niveau)"
201	"expression régulière (1er niveau)"
202	"expression régulière (1nd niveau)"
203	"quota"
204	"quota"
205	"methode de protection des adresses contre les robots spammeur"
206	"inclusion de liste distante"
207	"path du dump de la liste distante"
208	"Certificat pour authentification de la connection"
209	"nom court pour cette source"

$set 17 Cookie expiration periods
1	"la session"
2	"10 minutes"
3	"30 minutes"
4	"1 heure"
5	"6 heures"
6	"1 jour"
7	"1 semaine"
