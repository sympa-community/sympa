From: [from]
To: Moderatorul listei [list->name] <[list->name]-editor@[list->host]>
Subject: Articol pentru aprobat [list->name]
Reply-To: [conf->email]@[conf->host]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain
Content-transfer-encoding: 7bit

[IF method=md5]
Pentru a distribui mesajul pe lista [list->name] apasa pe linkul:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
sau trimite un mesaj la [conf->email]@[conf->host] cu urmatorul subiect :
DISTRIBUTE [list->name] [modkey]

Pentru a-l respinge (va fi sters):
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
sau trimite un mesaj la [conf->email]@[conf->host] cu urmatorul subiect :
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

