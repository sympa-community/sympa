<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operación realizada con éxito</b>. El mensaje será borrado tan pronto como 
sea posible. Esta tarea puede permanecer inactiva durante unos minutos, no 
olvide recargar la página en cuestión.
[ELSIF status = no_msgid]
<b>Es imposible encontrar el mensaje para borrar. Seguramente, el mensaje fue 
recibido sin el campo "Message-Id:" Contacte con el listmaster con la URL 
completa del mensaje en cuestión.</center>
[ELSIF status = not_found]
<b>Es imposible encontrar el mensaje para borrar.</b>
[ELSE]
<b>Error al intentar borrar este mensaje, contacte con el listmaster con la 
URL completa del mensaje en cuestión.</b>
[ENDIF]
