subject [subject]

status [status]

topics [topics]

visibility noconceal

send privateorpublickey

web_archive
  access intranet

archive
  period month
  access owner

clean_delay_queuemod 15

subscribe intranet

unsubscribe open,notify

review private

invite default

custom_subject [listname]

digest 1,4 6:56

owner
  email [owner->email]
  profile privileged
  [IF owner->gecos] 
  gecos [owner->gecos]
  [ENDIF]

editor
  email [owner->email]

creation
  date [creation->date]
  date_epoch [creation->date_epoch]
  email [creation->email]

serial 0
