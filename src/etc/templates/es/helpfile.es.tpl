              SYMPA -- Systeme de Multi-Postage Automatique
                       (Sistema Automatico de Listas de Correo)

                                Guía de Usuario


SYMPA es un gestor de listas de correo electrónicas que automatiza las funciones
habituales de una lista como la subscripción, moderación y archivo de mensajes.

Todos los comandos deben ser enviados a la dirección [conf->sympa]

Se pueden poner múltiples comandos en un mismo mensaje. Estos comandos tienen que
aparecer en el texto del mensaje y cada línea debe contener un único comando.
Los mensajes se deben enviar como texto normal (text/plain) y no en formato HTML.
En cualquier caso, los mensajes en el sujeto del mensaje también son interpretados.


Los comandos disponibles son:

 HELp                        * Este fichero de ayuda
 INFO                        * Información de una lista
 LISts                       * Directorio de todas las listas de este sistema
 REView <lista>              * Muestra los subscriptores de <lista>
 WHICH                       * Muestra a qué listas está subscrito
 SUBscribe <lista> <GECOS>   * Para subscribirse o confirmar una subscripción
                               a <lista>.  <GECOS> es información adicional
                               del subscriptor (opcional).

 UNSubscribe <lista> <EMAIL> * Para anular la subscripción a <lista>.
                               <EMAIL> es opcional y es la dirección elec-
                               trónica del subscriptor, útil si difiere
                               de la de dirección normal "De:".

 UNSubscribe * <EMAIL>       * Para borrarse de todas las listas

 SET <lista> NOMAIL          * Para suspender la recepción de mensajes de <lista>
 SET <lista|*> DIGEST        * Para recibir los mensajes recopilados
 SET <lista|*> SUMMARY       * Receiving the message index only
 SET <lista|*> MAIL          * Para activar la recepción de mensaje de <lista>
 SET <lista|*> CONCEAL       * Ocultar la dirección para el comando REView
 SET <lista|*> NOCONCEAL     * La dirección del subscriptor es visible via REView

 INDex <lista>               * Lista el archivo de <lista>
 GET <lista> <fichero>       * Para obtener el <fichero> de <lista>
 LAST <lista>                * Usado para recibir el último mensaje enviado a <lista>
 INVITE <lista> <email>      * Invitación a <email> a subscribirse a <lista>
 CONFIRM <key>               * Confirmación para enviar un mensaje
                               (depende de la configuración de la lista)
 QUIT                        * Indica el fin de los comandos


[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-
Los siguientes comandos son unicamente para los propietarios o moderadores de las listas:

ADD <lista> <email> Nombre Apellido   * Para añadir un nuevo usuario a <lista>
DEL <lista> <email>                   * Para elimiar un usuario de <lista>
STATS <lista>                         * Para consultar las estadísticas de <lista>

EXPire <lista> <dias> <espera>        * Para comenzar un proceso de expiración para
                                        aquellos subscriptores que no han confirmado 
                                        su subscripción desde hace tantos <dias>.
                                        Los subscriptores tiene tantos días de <espera> 
                                        para confirmar.

EXPireINDEx <lista>                   * Muestra el actual proceso de expiración de <lista>
EXPireDEL <lista>                     * Desactiva el proceso de expiración de <lista>

REMIND <lista>                        * Envia un mensaje a cada subscriptor (esto es una
                                        forma de recordar a cualquiera con qué e-mail
                                        está subscrito).

[ENDIF]
[IF is_editor]

 DISTribute <lista> <clave>           * Moderación: para validar un mensaje
 REJect <lista> <clave>               * Moderación: para denegar un mensaje
 MODINDEX <listaa>                    * Moderación: consultar la lista de mensajes a moderar

[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
