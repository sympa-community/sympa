<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operazione eseguita</b>. Il messaggio verr&agrave; cancellato il pi&ugrave; presto possibile.<br>
Questa operazione potrebbe essere eseguita nell'arco di qualche minuto, non dimenticare di ricaricare la pagina incriminata.
[ELSIF status = no_msgid]
<b>Non riesco a trovare il messaggio da cancellare, probabilmente il messaggio era privo di un "Message-Id:" <br>
Fate riferimento al vostro listmaster tramite l'indirizzo completo del messaggio incriminato</b></center>
[ELSIF status = not_found]
<b>Non riesco a trovare il messaggio da cancellare</b>
[ELSE]
<b>Errore durante la cancellazione del messaggio, fate riferimento al vostro
listmaster tramite l'indirizzo completo del messaggio incriminato</b>
[ENDIF]