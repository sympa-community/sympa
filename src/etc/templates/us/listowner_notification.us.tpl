From: [conf->email]@[conf->host]
To: Listowners <[to]>
[IF type=arc_quota_exceeded]
Subject: List "[list->name]" archive quota exceeded

[list->name]@[list->host] archives disk quota exceeded. Total size
used for [list->name]@[list->host] archive is [size] Bytes. Messages 
are no more web-archived. Please contact listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: List "[list->name]" warning : archive [rate]% full

[rate2]
[list->name]@[list->host] archives use [rate]% of allowed disk quota.
Total size used for [list->name]@[list->host] archive is [size] Bytes.

Messages are still archived but you should contact listmaster@[conf->host]. 
[ENDIF]
