From: [from]
To: Moderators van lijst [list->name] <[list->name]-editor@[list->host]>
Subject: Mail voor goedkeuring op lijst [list->name]
Reply-To: [conf->email]@[conf->host]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain
Content-transfer-encoding: 7bit

[IF method=md5]
Om de bijgevoegde mail te distribueren op lijst [list->name]:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Of zend een bericht naar [conf->email]@[conf->host] met het volgende onderwerp :
DISTRIBUTE [list->name] [modkey]

Om het te weigeren (het bericht zal worden weggegooid):
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Of zend een bericht naar [conf->email]@[conf->host] met het volgende onderwerp :
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

