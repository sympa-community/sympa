From: [conf->email]@[conf->host]
To: Listowners <[to]>
[IF type=arc_quota-exceeded]
Subject: List "[list->name]" archive quota exceeded

[list->name]@[list->host] archive disk quota exceeded. Total size
used for [list->name]@[list->host] archive is [size] Bytes. Messages 
are now ignored for web archive. Please contact listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: List "[list->name]" warning : archive disk is 95%

[list->name]@[list->host] archive disk is 95% of allowed disk quota.
Total size used for [list->name]@[list->host] archive is [size] Bytes.

Messages are still archived but you should contact listmaster@[conf->host]. 
[ENDIF]
