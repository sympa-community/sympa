From: [from]
To: [to]
Reply-to: [reply]
Subject: [list->name] Compilation [date]
Content-Type: text/plain; charset=iso-8859-1;
Content-transfer-encoding: 8bit

Compilation de la liste [list->name] du [date]

Sommaire :

[FOREACH m IN msg_list]
[m->id]. [m->subject] - [m->from]
[END]

----------------------------------------------------------------------

[FOREACH m IN msg_list]
Date: [m->date]
Auteur: [m->from]
Objet: [m->subject]

[m->plain_body]

------------------------------

[END]
Fin de la compilation de la liste [list->name] du [date]
*********************************************



