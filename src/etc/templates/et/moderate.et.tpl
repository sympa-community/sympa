From: [from]
To: Listi moderaatoritele [list->name] <[list->name]-editor@[list->host]>
Subject: Kiri toimetamiseks listis [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain
Content-transfer-encoding: 7bit

[IF method=md5]

Manusena kaasa pandid kirja saamiseks listi [list->name] klikake 
järgnevale URLile:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]

Või saatke kiri aadressile [conf->email]@[conf->host] järgneva teemaga:
DISTRIBUTE [list->name] [modkey]

Kirja eemaldamikeks (kirja ei saadeta listi): 
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]

Või saatke kiri aadressile [conf->email]@[conf->host] järgneva teemaga:
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

