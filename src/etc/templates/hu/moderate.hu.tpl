From: [from]
To: [list->name] lista moderátorai <[list->name]-editor@[list->host]>
Subject: Engedélyezésre váró levél
Reply-To: [conf->email]@[conf->host]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF method=md5]
A(z) [list->name] listán a melléklet megjelenésének jóváhagyásához használd a következõ parancsot:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Vagy [conf->email]@[conf->host] címre küldj egy levelet a következõ tárggyal:
DISTRIBUTE [list->name] [modkey]

Visszautasításhoz (ez törlést jelent) használd a következõt:
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Vagy [conf->email]@[conf->host] címre küldj egy levelet a következõ tárggyal:
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--
