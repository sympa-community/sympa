$ RCS Identication ; $Revision$ ; $Date$

$ 16 Oct 2000, Add Web translations <os@cru.fr>
$ 19 Jun 2000, Update of Josep Román <josep.roman@zuerich-see.ch>
$ 26 Feb 2000, Update of Josep Román <josep.roman@zuerich-see.ch>
$ 16 Feb 2000, Update of Josep Román <josep.roman@zuerich-see.ch>
$ 29 april 1999, Initial version by Alex Nappa <alex.nappa@imag.fr>

$quote "

$set 1	Mensajes usados durante el proceso del archivo de configuración
1	"El archivo de configuración contiene errores.\n"
3	"Error en la línea %d: %s"
102	"3.0"

$set 2	Mensajes usados por Conf en la comprobación de archivos

$set 3	Mensajes varios del programa principal
1	"Imposible acceder al directorio %s: %m"

$set 4	Mensajes usados en el bucle principal
11	"Su mensaje para %s ha sido rechazado"
12	"Su mensaje no puede ser envíado porque sobrepasa el tamaño máximo \n\
permitido por esta lista.\n"
15	"Usted intentó enviar un mensaje a una lista privada a la que no está subscrito.\n\nEl mensaje es por tanto, devuelto.\n\n\
Su mensaje era :\n"
17	"Resultados de sus comandos"
18	"Comando 'QUIT' encontrado: el resto del mensaje se ignora.\n"
19	"Comando no entendido: el resto del mensaje se ignora.\n"
24	"Fin de su orden EXPIRE en la lista %s"
26	"Los subscriptores son:\n"
27	"Si usted quiere borrar a estos subscriptores de la lista utilice los siguientes comandos:\n"
28	"Entre los subscriptores de la lista %s desde hace %d días, %d no confirmaron su subscripción.\n"
37	"El texto del mensaje ha sido ignorado, utilice unicamente formato de texto normal (no HTML)\n(o ponga los comandos en el tema del mensaje).\n"
38	"Su mensaje para la lista %s ha sido dirigido a los editores\n"
39	"No se encontró ninguna orden en el mensaje"
40	"Moderando su mensaje"

$set 5	Mensajes usados en el módulo de herramientas
1	"Safefork no puede crear un nuevo proceso: %m"
2	"Error de encaminamiento?"
3	"El mensaje siguiente se ha dirigido a una lista aunque parece \n\
que contiene comandos como SUBSCRIBE, SIGNOFF, HELP, INDEX, GET,... \n\n\
Si de hecho su mensaje contuviera un comando, sepa que estos \n\
en ningún caso deben ser dirigidos a las listas.\n\
Deben ser enviados exclusivamente a la dirección %s.\n\n\
Si su mensaje se destinara efectivamente a la lista, ha sido desgraciadamente\n\
interpretado por el software como un comando.\n\
Por favor contacte con el responsable del servicio : %s para que se ocupe de su mensaje.\n\
Gracias por su atención. \n\n\
------Inicio del mensaje sospechoso------\n"
4	"------Fin del mensaje sospechoso------\n"

$set 6	Mensajes del módulo de Commands.pm
2	"Imposible leer el archivo de ayuda: %s\n"
5	"La lista '%s' no existe.\n"
6	"Información acerca de la lista %s :\n\n"
7	"No hay ningún archivo en el histórico de esta lista.\n"
8	"El archivo solicitado no existe.\n"
9	"La lista es privada: usted no puede consultar los archivos.\n"
10	"La lista es privada: usted no puede consultar la lista de los archivos disponibles.\n"
11	"La lista es privada: usted no puede consultar la lista de los subscriptores.\n"
12	"El número de subscriptores es: %d\n"
13	"Error de sintaxis.\n"
15	"El proceso de autentificación ha fallado.\n\n"
16	"Usted probablemente confirmó su subscripción con una dirección electrónica diferente.\n\
Por favor subscribase usando su dirección oficial.\n"
18	"Su subscripción a la lista %s ha sido suprimida."
21	"Su subscripción a la lista %s ha sido renovada."
24	"Las subscripciones a esta lista están por el momento suspendidas.\n"
25	"Su petición de subscripción (o anulación) se ha enviado a los propietarios de la lista\n\
para su aprobación. Usted recibirá una notificación cuando usted haya sido\n\
subscrito (o anulado) a la lista.\n"
26	"Anular una subscripción en la lista %s no es posible.\n"
27	"La información referente a su subscripción ha sido actualizada.\n"
28	"Usted es ahora un subscriptor de la lista %s.\n"
29	"La información sobre esta lista será enviada en otro mensaje.\n"
30	"Su dirección electrónica no se ha encontrado en la lista %s.\n\
Quizás se subscribió usted con una dirección diferente?\n"
31	"Su subscripción ha sido suprimida de la lista %s.\n\
Agradecemos su presencia en esta lista.\n"
32	"Sólo los propietarios de la lista %s pueden modificar las subscripciones.\n\
Usted no está autorizado a utilizar este comando o no facilitó la información\n\
necesaria para su autentificación.\n"
33	"La dirección electrónica %s no se encontró en la lista.\n"
34	"Usted ha sido suprimido de la lista %s por %s, propietario de esta lista.\n\
Esta acción se realiza generalmente para eliminar direcciones que generan problemas\n\
en el envío de mensajes. Sin embargo, puede ser que su problema haya sido sólo \n\
temporal.\n Si es así, disculpe las molestias y renueve su subscripción."
35	"El archivo se le enviará en un mensaje separado.\n"
36	"La información acerca del usuario %s fueron actualizadas para la lista %s.\n"
37	"El usuario %s es ahora subscriptor de la lista %s.\n"
38	"El usuario especificado se ha eliminado de la lista.\n"
39	"Alguien (probablemente usted) solicitó añadir o suprimir un usuario de la lista %s.\n\n\
Si usted confirma esta acción, por favor envíe de nuevo un correo electrónico a la dirección %s \n\
conteniendo :\n\n%s\n\n\
Si usted no desea confirmar la acción, ignore este mensaje.\n"
40	"Su configuración relativa a la lista %s fue actualizada.\n"
41	"Imposible acceder al mensaje moderado en la lista %s con la clave %s.\n\
Puede ser que este mensaje ya ha sido distribuido por algún moderador de la lista.\n"
43	"El mensaje para la lista %s ha sido rechazado.\n"
44	"El mensaje para la lista %s ha sido distribuido.\n"
45	"La lista %s no acepta el modo resumen (DIGEST). Su configuración en esta lista no se ha modificado.\n"
46	"El comando MODINDEX se reserva a moderadores.\n\
Usted no es moderador de la lista %s.\n"
47	"Las ordenes EXPIRE, EXPIREINDEX y EXPIREDEL se reservan a los propietarios.\n\
Usted no es propietario de la lista %s.\n"
48	"\
Alguien (probablemente usted) solicitó que los subscriptores a la\n\
lista '%s' desde hace  más de %d días reconfirmen su subscripción.\n\
Si usted no desea que la acción se emprende, ignore este mensaje.\n\
Para confirmar, por favor envíe un mensaje a la dirección '%s' con el siguiente comando:\n\n\
AUTH %s EXPIRE %s %d %d\n"
49	"\
Un comando EXPIRE está siendo ejecutado para la lista %s.\n\
Ha sido ejecutado por el propietario %s (%s)\n\
Sólo puede haber un proceso 'expire' a la vez para una misma lista.\n\
La expiración es para los subscriptores desde más de %d días\ny que no confirmaron su subscripción.\n\
La expiración terminará dentro de %d días (%s).\n"
52	"%s no recibió confirmación de las siguientes direcciones:\n"
53	"Para interrumpir el proceso de expiración: EXPIREDEL %s\n"
54	"La lista %s no está efectuando una expiración.\n"
55	"Usted ha detenido el commando de expiración para la lista %s\n."
56	"\
Un proceso de expiración comenzó para la lista %s.\n\
Este proceso acabará dentro de %d días. Usted recibirá entonces la lista de los subscriptores \n\
que no han confirmado su subscripción en el tiempo impuesto.\n\
Usted podrá entonces suprimir esas direcciones con el comando DEL.\n"
57	"Para consultar la lista de los subscriptores que no han confirmado su subscripción : EXPIREINDEX %s\n"
58	"Usted puede suprimir a estos subscriptores de la lista con los comandos siguientes:\n"
60	"\
El comando EXPIRE no ha podido ser ejecutado.\n\
Debe ser seguido de un texto de explicación destinado a los subscriptores que deben confirmar su subscripción.\n\
Este texto debe:\n\n\
 - comenzar después de la línea siguiente del comando EXPIRE,\n\
 - tener por lo menos 20 palabras,\n\
 - acabar con la palabra QUIT.\n"
61	"Por consiguiente, su mensaje se le devuelve :\n"
67	"Estas son las listas a las cuales está usted subscrito :\n\n"
68	"Imposible acceder al mensaje autentificado con la clave %s.\n"
69	"%s mandó por correo su mensaje de expiración a las direcciones siguientes:\n"
70	"\nServido por Sympa %s: http://lists.zuerich-see.ch/sympa/\n"
71	"Anular subscripción de la lista %s"
72	"\n\nListas de las que usted es propietario :\n\n"
73	"\n\nListas de las que usted es editor :\n\n"
74	"Autentificación solicitada %s para el comando %s\n"
75	"La anulación de %s es posible en cualquier lista.\n"
76	"Recordatorio de su subscripción a la lista %s."
77	"Usted es un subscriptor de la lista %s con dirección %s.\n"
78	"Recordatorio de subscripción enviado a los %d subscriptores.\n"
79	"Alguien (posiblemente usted) solicitó a Sympa enviar una confirmación\n\
a cada subscriptor de la lista %s\n\n\
Si usted confirma el comando, envie un e-mail a\n\
%s conteniendo \n\n\
   %s\n\n\
Si no desea confirmar este comando, ignore este mensaje.\n"
80	"Usted no está autorizado a utilizar el comando %s en la lista %s.\n"
81	"Guía de usuario"
82	"Listas públicas"
83	"Sumario de subscripción"
84	"El usuario %s ya es un subscriptor de la lista '%s'.\n"
85	"El usuario %s ha sido invitado a subscribirse a la lista %s.\n"
86	"El usuario %s no es aceptado en la lista %s.\n"
260	"Alguien (probablemente usted) solicitó su subscribción a la lista '%s'.\n\
Para confirmar esta acción, por favor \n\n\
- Conteste a este correo\nO\n\
- Envie un mensaje a %s con el tema:\n %s\nO\n\
- Envie un mensaje haciendo un click aquí: %s\n\n\
Si usted no quiere confirmar este comando, ignore este mensaje.\n"
261	"Alguien (probablemente usted) solicitó anular su subscripcion de la lista '%s'.\n\
Para confirmar esta acción, por favor \n\n\
- Conteste a este correo \nO\n\
- Envie un mensaje a %s con el tema \n%s\nO\n\
- Envie un mensaje haciendo un click aquí: %s\n\n\
Esto puede ser validado también mediante la URL: %s\n\
Si usted no quiere confirmar la anulación de la subscripción, ignore este mensaje.\n"


$set 7	Mensajes de Syslog (Commands.pm)

$set 8	Mensajes usado en List.pm
1	"Propietarios de la lista %s"
2	"Solicitud de subscripción a la lista %s"
3	"Querido(s) propietario(s) de la lista %s,\n\n\
Un usuario solicitó subscribirse a su lista. Si está(n) de acuerdo utilice(n) el comando\n\
siguiente:\n\nADD %s %s %s\n"
4	"Moderadores de la lista %s"
5	"[%s] Artículo para ser aprobado"
6	"Bienvenido a la lista %s"
7	"Archivo"
8	"\
   Número de mensajes recibidos     :  %9d\n\
   Número de mensajes transmitidos  :  %9d\n\n\
   Megabytes enviados               : %9.2f\n\
   Megabytes transmitidos           : %9.2f\n"
9	"Resumen de la lista %s"
10	"Para distribuir el mensaje adjunto en la lista %s, haga click en:\n\
mailto:%s?subject=DISTRIBUTE%%20%s%%20%s\n\
O envie un mensaje a %s con el siguiente tema :\n\
DISTRIBUTE %s %s\n\n"
11	"Para negar la difusión (el mensaje será borrado) :\n\
mailto:%s?subject=REJECT%%20%s%%20%s\n\
O envie un mensaje a %s con el siguiente tema :\n\
REJECT %s %s\n"
12	"Para distribuir el mensaje adjunto en la lista %s, haga click en:\n\
mailto:%s?subject=CONFIRM%%20%s\n\
O envie un mensaje a %s con el siguiente tema :\n\
CONFIRM %s %s\n"
13	"Tabla de contenido"
14	"Fin del Resumen de la lista %s"
15	"Hay %d mensajes para ser moderados para la lista %s"
16	"Solicitud de autentificación"
21	"Para su información: %s lista %s de %s %s"
22	"Para su información: comando %s a la lista %s de %s %s \n(ninguna acción requerida).\n"
23	"ATENCIÓN: %s %s falló en una tentativa de anular una subscripción a la lista %s\n\
debido a que la dirección no se encontró en la lista\n\
(Quizás se debe ayudar a esta persona)\n"
24	"Petición de anulación de subscripción a la lista %s"
25	"Querido propietario(s) de la lista %s,\n\n\
Un subscriptor ha solicitado su supresión en la lista.\n\
Si usted está de acuerdo, envíe el siguiente comando:\n\
DEL %s %s\n"
26	"Para su información: comando %s lista %s de %s %s validado por %s\n (no se requiere ninguna acción)\n"
27	"El ratio de mensajes devueltos/erróneos en la lista %s es %d%%.\n\n\
Si se desea suprimir los subscriptores con esos problemas:\n\
%s/reviewbouncing/%s"
28	"ATENCIÓN: El ratio de errores (bouncing) es demasiado alto en la lista %s.\n"
29	"Invitación para unirse a la lista %s"
30	"Usted está invitado a unirse a la lista %s"

$set 9	Mensajes para la cabacera del comando 'review'
1	"Propietario            : %s\n"
2	"Moderador		         : %s\n"
3	"Subscripción	         : %s\n"
4	"Supresión		         : %s\n"
5	"Enviando mensajes      : %s\n"
6	"Lista de subscriptores : %s\n"
7	"Respuesta a            : %s\n"
8	"Tamaño Máximo          : %d\n"
9	"URL de la lista        : %s\n"
10	"Resumen			         : %s\n"
11	"Tema personalizado     : %s\n"
12	"Tema normal            : %s\n"

$set 11	Mensajes utilizados por el modulo smtp.
1	"Su sistema no parece conformar el standard POSIX P1003.1, o bien\n\
su sistema Perl no define _SC_ARG_MAX en su biblioteca POSIX.\n\
Es necesario que usted modifique el módulo smtp.pm para fijar un\n\
valor para la variable $max_arg.\n"
2	"Imposible crear un canal en smtpto: %m"

$set 12 Cabecera MIME
1	"1.0"
2	"iso-8859-1"
3	"8bit"
4	"SYMPA <%s>"

$set 13 Mensajes para la cabecera del indice de moderación
1	"\t	Fecha               : %s"
2	"\t	Remitente           : %s"
3	"\t 	Tamaño              : %s"
4	"\t 	Clave de moderación : %s\n"

$set 14 For the web
1	"es_ES"
2	"español"

$set 15 Templates files
1	"Mensaje de Bienvenida"
2	"Anulación subscripción"
3	"Mensaje de supresión"
4	"Pie de mensaje"
5	"Cabecera de mensaje"
6	"Mensaje de recordatorio"
7	"Mensaje de rechazo del editor de la lista"
8	"Mensaje de invitación a subscribirse"
9	"Fichero de ayuda"
10	"Directorio de listas"
11	"Mensaje de recordatorio global"
12	"Sumario de mensajes"
13	"Descripción de la lista"
14	"Principal de la lista"


$set 16 Listm parameters titles
1	"Cuenta"
2	"Quién puede añadir subscriptores"
3	"Remitente anónimo"
4	"Archivos de Texto"
5	"frecuencia"
6	"derechos de acceso"
7	"Gestión de los Bounces"
8	"ratio de aviso"
9	"ratio de stop"
10	"Expiración de los mensajes no moderados"
11	"String Secreto para genera claves únicas"
12	"Creación de la lista"
16	"Definición del Campo de cabecera"
17	"Etiquetado del Tema"
18	"Perfil de Subscripción"
19	"modo de recepción"
20	"visibilidad"
21	"Quién puede borrar subscriptores"
22	"Frecuencia del Resúmen"
23	"días"
24	"hora"
25	"minuto"
26	"Moderadores"
27	"dirección E-mail"
28	"modo de recepción"
29	"nombre"
30	"información privada"
31	"Tipo de Anexo"
32	"Dirección de respuesta forzada"
33	"Domino de Internet"
34	"Inclsuón de fichero"
35	"Inclusión de petición LDAP"
36	"host remoto"
37	"puerto remoto"
38	"usuario remoto"
39	"contraseña remota"
40	"sufijo"
41	"filtro"
42	"atributo extraído"
43	"selección (si múltiple)"
44	"Inclusión de Lista"
45	"Inclusión de petición SQL"
46	"tipo de base de datos"
47	"host remoto"
48	"nombre de la base de datos"
49	"usuario remoto"
50	"contraseña remota"
51	"Petición SQL"
53	"Quién puede ver información de la lista"
54	"Quién puede invitar a gente"
55	"Idioma de la lista"
56	"Tamaño máximo de mensaje"
57	"Propietario"
58	"dirección E-mail"
59	"modo de recepción"
60	"nombre"
61	"informaciones privadas"
62	"perfil"
63	"Prioridad"
64	"Quién puede activar un proceso de recordatorio"
65	"Dirección de retorno del Recordatorio"
66	"Dirección de respuesta"
67	"Quién puede ver los subscriptores"
68	"Quién puede enviar mensajes"
69	"Número de serial de la configuración"
70	"Documentos compartidos"
71	"Estado de la lista"
72	"Tema de la lista"
73	"Quién puede subscribirse a la lista"
74	"Tópicos de la lista"
75	"Timeout de las inclusiones"
76	"Quién puede anular la subscripción"
77	"Ultima actualización de la configuración"
81	"Fuente de los usuarios"
82	"Visibilidad de la lista"
83	"Archivos Web"
84	"derecho de accesos"
85	"Dirección de retorno de la Bienvenida"
86	"Quién puede visualizar"
87	"Quién puede editar"
