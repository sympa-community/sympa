From: [from]
To: [to]
Reply-to: [reply]
Subject: [list->name] Digest [date]
Content-Type: text/plain; charset=iso-8859-1;
Content-transfer-encoding: 8bit

[list->name] Digest             [date]

Table of contents:

[FOREACH m IN msg_list]
[m->id]. [m->subject] - [m->from]
[END]

----------------------------------------------------------------------

[FOREACH m IN msg_list]
Date: [m->date]
From: [m->from]
Subject: [m->subject]

[m->plain_body]

------------------------------

[END]
End of [list->name] Digest [date]
*********************************************



