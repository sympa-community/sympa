<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH p IN param]
<A NAME="[p->NAME]">
<B>[p->title]</B> ([p->NAME]):
<DL>
<DD>
[IF p->NAME=add]
  Privilegio para añadir (comando ADD) un suscriptor a la lista
[ELSIF p->NAME=anonymous_sender]
  Para ocultar el email del remitente antes de distribuir el mensaje.
  Es cambiado por el email definido.
[ELSIF p->NAME=archive]
  Privilegio para leer los archivos de mensajes y la frecuencia de archivado
[ELSIF p->NAME=owner]
  Los propietarios administran los suscriptores. Ellos pueden revisar los suscriptores, añadir y borrar direcciones de la lista de correo. Si usted es propietario privilegiado de una lista de correo, puede añadir otros propietarios a la misma. 
[ELSIF p->NAME=editor]
Los editores son responsables de la moderación de mensajes. Ellos deciden si un mensaje se aprueba o no para su distribución en la lista. <BR>
[ELSE]
  Sin comentarios
[ENDIF]

</DL>
[END]
	
