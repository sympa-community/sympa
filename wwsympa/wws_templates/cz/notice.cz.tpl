<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF notice->msg=sent_to_owner]
Vá¹ po¾adavek byl odeslán správci konference

[ELSIF notice->msg=add_performed]
pøidáno [notice->total] èlenù

[ELSIF notice->msg=performed]
[notice->action] : akce skonèila úspì¹nì

[ELSIF notice->msg=list_config_updated]
Soubor s konfigurací zmìnìn

[ELSIF notice->msg=upload_success] 
Soubor [notice->path] byl úspì¹nì nahrán!

[ELSIF notice->msg=save_success] 
Soubor [notice->path] ulo¾en

[ELSIF notice->msg=password_sent]
Va¹e heslo Vám bylo odesláno emailem

[ELSIF notice->msg=you_should_choose_a_password]
Pro zmìnu hesla jdìte do "Nastavení" v horní èasti stránky

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]
