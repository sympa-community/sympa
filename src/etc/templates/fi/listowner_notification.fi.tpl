From: [conf->email]@[conf->host]
To: Listowners <[to]>
[IF type=arc_quota_exceeded]
Subject: Listan "[list->name]" arkisto ylittänyt quota rajan

[list->name]@[list->host] arkiston on ylittänyt quota rajan. Arkiston
[list->name]@[list->host] käyttämä koko on [size] tavua. Viestejä 
ei enää tallenneta WWW-arkistoon. Ota yhteyttä listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: Lista "[list->name]" varoitus : arkisto [rate]% täynnä

[rate2]
[list->name]@[list->host] käyttää [rate]% sallitusta quotasta.
Arkiston [list->name]@[list->host] käyttämä koko on [size] tavua.

Viestit tallennetaan yhä arkistoon, mutta sinun tulisi ottaa 
yhteyttä listmaster@[conf->host]. 
[ENDIF]
