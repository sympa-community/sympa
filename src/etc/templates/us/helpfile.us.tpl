
              SYMPA -- Systeme de Multi-Postage Automatique
                       (Automatic Mailing System)

                                User's Guide


SYMPA is an electronic mailing-list manager that automates list management
functions such as subscriptions, moderation, and archive management.

All commands must be sent to the electronic address [conf->sympa]

You can put multiple commands in a message. These commands must appear in the
message body and each line must contain only one command. The message body
is ignored if the Content-Type is different from text/plain but even with
crasy mailer using multipart and text/html for any message, commands in the
subject are recognized.

Available commands are:

 HELp                        * This help file
 INFO                        * Information about a list
 LISts                       * Directory of lists managed on this node
 REView <list>               * Displays the subscribers to <list>
 WHICH                       * Displays which lists you are subscribed to
 SUBscribe <list> <GECOS>    * To subscribe or to confirm a subscription to
                               <list>, <GECOS> is an optional information
                               about subscriber.

 UNSubscribe <list> <EMAIL>  * To quit <list>. <EMAIL> is an optional 
                               email address, usefull if different from
                               your "From:" address.
 UNSubscribe * <EMAIL>       * To quit all lists.

 SET <list|*> NOMAIL         * To suspend the message reception for <list>
 SET <list|*> DIGEST         * Message reception in compilation mode
 SET <list|*> SUMMARY        * Receiving the message index only
 SET <list|*> NOTICE         * Receiving message subject only

 SET <list|*> MAIL           * <list> reception in normal mode
 SET <list|*> CONCEAL        * To become unlisted (hidden subscriber address)
 SET <list|*> NOCONCEAL      * Subscriber address visible via REView


 INDex <list>                * <list> archive file list
 GET <list> <file>           * To get <file> of <list> archive
 LAST <list>                 * Used to received the last message from <list>
 INVITE <list> <email>       * Invite <email> for subscription in <list>
 CONFIRM <key>               * Confirmation for sending a message (depending
                               on the list's configuration)
 QUIT                        * Indicates the end of the commands (to ignore a
                               signature)

[IF is_owner]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
The following commands are available only for lists's owners or moderators:

 ADD <list> user@host First Last * To add a user to a list
 DEL <list> user@host            * To delete a user from a list
 STATS <list>                    * To consult the statistics for <list>
 EXPire <list> <old> <delay>     * To begin an expiration process for <list>
                                   subscribers who have not confirmed their
                                   subscription for <old> days. The
                                   subscribers have <delay> days to confirm
 EXPireINDex <list>              * Displays the current expiration process
                                   state for <list>
 EXPireDEL <list>                * To de-activate the expiration process for
                                   <list>

 REMIND <list>                   * Send a reminder message to each
                                   subscriber (this is a way to inform
                                   anyone what is his real subscribing
                                   email).
[ENDIF]
[IF is_editor]

 DISTribute <list> <clef>        * Moderation: to validate a message
 REJect <list> <clef>            * Moderation: to reject a message
 MODINDEX <list>                 * Moderation: to consult the message list to
                                   moderate
[ENDIF]

Powered by Sympa [conf->version] : http://listes.cru.fr/sympa/

