## Configuration de la liste sympa-l
## Cree le Mercredi 31 Mars 99
#send editorkey

subject [subject]

status [status]

visibility noconceal

subscribe open_notify

unsubscribe open_notify

owner
  email [owner->email]
  profile privileged
  [IF owner->gecos] 
  gecos [owner->gecos]
  [ENDIF]

send privateoreditorkey

[IF topics]
topics [topics]
[ENDIF]

web_archive
access public

archive
access owner
period week

digest 1,4 13:26

review owner

shared_doc
d_edit default
d_read public

creation
date_epoch [creation->date_epoch]
date       [creation->date]
email      [creation->email]