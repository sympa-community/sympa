From: [conf->email]@[conf->host]
Subject: Toimetamist ootavad kirjad listis [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary1]"

--[boundary1]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

[total] kirja ootab listis [list->name]@[list->host] toimetamist

[IF spool]
--[boundary1]
Content-Type: multipart/digest; boundary="[boundary2]"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

See on mitmeosaline kiri MIME formaadis. 

[FOREACH msg IN spool]
--[boundary2]
Content-Type: message/rfc822
Content-Transfer-Encoding: 8bit
Content-Disposition: inline

[msg]

[END]
--[boundary2]--

--[boundary1]--

