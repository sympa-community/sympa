From: [from]
To: Moderatoren der Liste [list->name] <[list->name]-editor@[list->host]>
Subject: Freigabe einer Nachricht
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

[IF method=md5]
Um die angehängte Nachricht an die Liste [list->name] weiterzuleiten :
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Oder: Schicken Sie eine Nachricht an [conf->email]@[conf->host] mit folgendem Subject:
DISTRIBUTE [list->name] [modkey]

Um sie abzulehnen (sie wird gelöscht):
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Oder: Schicken Sie eine Nachricht an [conf->email]@[conf->host] mit folgendem Subject:
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

