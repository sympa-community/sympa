From: [conf->email]@[conf->host]
Subject: Messages à modérer pour [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary1]"

--[boundary1]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Il y a [total] messages à modérer pour la liste [list->name]@[list->host].

[IF spool]
--[boundary1]
Content-Type: multipart/digest; boundary="[boundary2]"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

This is a multi-part message in MIME format...

[FOREACH msg IN spool]
--[boundary2]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[msg]

[END]
--[boundary2]--

--[boundary1]--
