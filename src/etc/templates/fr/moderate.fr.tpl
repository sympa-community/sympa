From: [from]
To: Moderateurs de la liste [list->name] <[list->name]-editor@[list->host]>
Subject: Message à modérer pour [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

[IF method=md5]
Pour diffuser le message ci-joint dans la liste [list->name], 
cliquez sur ce lien :
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Ou alors envoyez un mail à [conf->email]@[conf->host] avec comme sujet :
DISTRIBUTE [list->name] [modkey]

Pour refuser sa diffusion (il sera effacé),
cliquez sur ce lien :
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Ou alors envoyez un mail à [conf->email]@[conf->host] avec comme sujet :
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

