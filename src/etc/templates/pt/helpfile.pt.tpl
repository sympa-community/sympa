              SYMPA -- Systeme de Multi-Postage Automatique
                       (Sistema Automático de Listas de Correio)

                                Guia de Usuário


SYMPA é um gestor de listas de correio eletrônicas que automatiza as funções
freqüentes de uma lista como a subscrição, moderação e arquivo de mensagens.

Todos os comandos devem ser enviados a o endereço [conf->sympa]

Podem se colocar múltiplos comandos numa mesma mensagem. Estes comandos tem que
aparecer no texto da mensagem e cada línea deve conter um único comando.
As mensagens devem se enviar como texto normal (text/plain) e não em formato HTML.
Em qualquer caso, os comandos no tema da mensagem também são interpretados.


Os comandos disponíveis são:

HELp                        * Este ficheiro de ajuda
INFO                        * Informação de uma lista
LISts                       * Diretório de todas as listas de este sistema
REView <lista>              * Mostra os subscritores de <lista>
WHICH                       * Mostra a que listas está subscrito
SUBscribe <lista> <GECOS>   * Para se subcribir ou confirmar uma subscrição
                               a <lista>.  <GECOS> e informação adicional
                               do subscritor (opcional).

UNSubscribe <lista> <EMAIL> * Para anular uma subscrição a <lista>.
                               <EMAIL> e opcional, e o endereço elec-
                               trônico do subscritor, útil si difere
                               do endereço normal "De:".

UNSubscribe * <EMAIL>       * Para se borrar de todas as listas

SET <lista> NOMAIL          * Para suspender a recepção das mensagens de <lista>
SET <lista|*> DIGEST        * Para receber as mensagens recopiladas
SET <lista|*> SUMMARY       * Para só receber o índex das mensagens 
SET <lista|*> MAIL          * Para ativar a recepção das mensagens de <lista>
SET <lista|*> CONCEAL       * Ocultar a endereço para o comando REView
SET <lista|*> NOCONCEAL     * O endereço do subscritor e visível via REView

INDex <lista>               * Lista o arquivo de <lista>
GET <lista> <ficheiro>      * Para obter o <ficheiro> de <lista>
LAST <lista>                * Usado para receber a última mensagem enviada a <lista>
INVITE <lista> <email>      * Convida <email> a se subscribir a <lista>
CONFIRM <key>               * Confirmação para enviar uma mensagem
(depende da configuração da lista)
QUIT                        * Indica o final dos comandos


[IF is_owner]%)
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-
Os seguintes comandos são unicamente para os proprietários ou moderadores das listas:

ADD <lista> <email> Nome Sobrenome     * Para adicionar um novo usuário a <lista>
DEL <lista> <email>                   * Para eliminar um usuário da <lista>
STATS <lista>                         * Para consultar as estatísticas da <lista>

EXPire <lista> <dias> <espera>        * Para iniciar um processo de expiração para aqueles subscritores que não tem confirmado 
sua subscrição desde tantos <dias>.
Os subscritores tem tantos dias de <espera> 
para confirmar.

EXPireINDEx <lista>                   * Mostra o atual processo de expiração da <lista>
EXPireDEL <lista>                     * Desativa o processo de expiração da <lista>

REMIND <lista>                        * Envia uma mensagem a cada subscritor (isto é um jeito para qualquer se lembrar com quê e-mail está subscrito).

[ENDIF]
[IF is_editor])

DISTribute <lista> <clave>           * Moderação: para validar uma mensagem
REJect <lista> <clave>               * Moderação: para denegar uma mensagem
MODINDEX <lista>                     * Moderação: consultar a lista das mensagens a moderar

[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/
