From: [from]
To: Moderators of list [list->name] <[list->name]-editor@[list->host]>
Subject: Article to be approved for [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain
Content-transfer-encoding: 7bit

To distribute the attached message in list [list->name]:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%%20[list->name]%%20[modkey]
Or send a message to [conf->email]@[conf->host] with the following subject :
DISTRIBUTE [list->name] [modkey]

To reject it (it will be removed):
mailto:[conf->email]@[conf->host]?subject=REJECT%%20[list->name]%%20[modkey]
Or send a message to [conf->email]@[conf->host] with the following subject :
REJECT [list->name] [modkey]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

