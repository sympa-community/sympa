From: [from]
To: [to]
Reply-to: [reply]
Subject: Riassunto della lista [list->name]
Mime-version: 1.0
Content-Type: multipart/mixed; boundary="[boundary1]"

--[boundary1]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Sommario:

[FOREACH m IN msg_list]
[m->id]. [m->subject] - [m->from]
[END]

--[boundary1]
Content-type: multipart/digest; boundary="[boundary2]"
Mime-Version: 1.0

This is a multi-part message in MIME format...

[FOREACH m IN msg_list]
--[boundary2]
Content-Type: message/rfc822
Content-Disposition: inline

[m->full_msg]

[END]
--[boundary2]
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit
Content-Disposition: inline

Fine del riassunto della lista [list->name] - [date]

--[boundary2]--

--[boundary1]--



