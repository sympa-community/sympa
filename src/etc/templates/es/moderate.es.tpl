From: [from]
To: Moderadores de la lista [list->name] <[list->name]-editor@[list->host]>
Subject: Artículo para ser aprobado
Reply-To: [conf->email]@[conf->host]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

[IF method=md5]
Para distribuir el mensaje adjunto en la lista [list->name], haga click en:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
O envíe un mensaje a [conf->email]@[conf->host] con el siguiente tema :
DISTRIBUTE [list->name] [modkey]

Para negar la difusión (el mensaje será borrado) :
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
O envíe un mensaje a [conf->email]@[conf->host] con el siguiente tema :
REJECT [list->name] [modkey]
[ENDIF]


--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

