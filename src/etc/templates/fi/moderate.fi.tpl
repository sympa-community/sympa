From: [from]
To: Moderators of list [list->name] <[list->name]-editor@[list->host]>
Subject: Viesti hyväksyntää varten listalle [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain
Content-transfer-encoding: 7bit

[IF method=md5]
Lähettääksesi ohessa olevan viestin listalle [list->name]:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
tai lähetä viesti osoitteeseen [conf->email]@[conf->host] seuraavalla otsikolla :
DISTRIBUTE [list->name] [modkey]

Hylätäksesi viestin (se poistetaan) :
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
tai lähetä viesti osoitteeseen [conf->email]@[conf->host] seuraavalla otsikolla :
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

