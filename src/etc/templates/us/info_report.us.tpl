Information regarding list [list->name]@[list->host] :

Subject            : [subject]
[FOREACH o IN owner]
Owner              : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderator          : [e->gecos] <[e->email]>
[END]
Subscription       : [subscribe]
Unsubscription     : [unsubscribe]
Sending messages   : [send]
Review subscribers : [review]
Reply to           : [reply_to]
Maximum size       : [max_size]
[IF digest]
Digest             : [digest]
[ENDIF]
Reception modes    : [available_reception_mode]
Homepage           : [url]

[PARSE 'info']
