<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Opération réussie</b>. Le message sera détruit rapidement (quelques
minutes). N'oubliez pas de rafraîchir la page concernée pour le vérifier.
[ELSIF status = no_msgid]
<b>Impossible de trouver le message à détruire</b>, probablement, ce
message a été reçu sans l'entête <code>Message-Id:</code>. Merci
de contacter le <i>listmaster</i> et de lui transmettre l'URL
du message à détruire.
[ELSIF status = not_found]
<b>Impossible de trouver le message à détruire</b>
[ELSE]
<b>Erreur lors de la suppression de ce message</b>; Merci
de contacter le <i>listmaster</i> et de lui transmettre l'URL
du message à détruire.
[ENDIF]