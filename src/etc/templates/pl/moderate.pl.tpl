From: [from]
To: Moderatorzy listy [list->name] <[list->name]-editor@[list->host]>
Subject: Listów do potwierdzenia
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary]"

--[boundary]
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF method=md5]
Aby rozes³aæ za³±czon± wiadomo¶æ na listê [list->name]:
mailto:[conf->email]@[conf->host]?subject=DISTRIBUTE%20[list->name]%20[modkey]
Lub wy¶lij wiadomo¶æ do [conf->email]@[conf->host] z tematem :
DISTRIBUTE [list->name] [modkey]

Aby odrzuciæ j± (zostanie usuniêta):
mailto:[conf->email]@[conf->host]?subject=REJECT%20[list->name]%20[modkey]
Lub wy¶lij wiadomo¶æ do [conf->email]@[conf->host] z tematem :
REJECT [list->name] [modkey]
[ENDIF]

--[boundary]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[INCLUDE msg]

--[boundary]--

