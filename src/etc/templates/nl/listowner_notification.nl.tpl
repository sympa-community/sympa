From: [conf->email]@[conf->host]
To: Listowners <[to]>
[IF type=arc_quota_exceeded]
Subject: List "[list->name]" archive quota exceeded

[list->name]@[list->host] archief disk quota verbruikt. Totale grootte
gebruikt voor [list->name]@[list->host] archief is [size] Bytes. Berichten 
worden niet meer gearchiveerd voor het web. Neemt u a.u.b. contact op met listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: List "[list->name]" waarschuwing : archief [rate]% vol

[rate2]
[list->name]@[list->host] archief gebruikt [rate]% van de toegestande schijfruimte.
De totale groote gebruikt voor [list->name]@[list->host] archief is [size] Bytes.

Berichten worden nog steeds gearchiveerd, maar u zou contact op kunnen nemen met listmaster@[conf->host]. 
[ENDIF]
