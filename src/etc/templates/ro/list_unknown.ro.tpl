From: [conf->email]@[conf->host]
To: [to]
Subject: Lista necunoscuta
Mime-version: 1.0
Content-Type: multipart/report; report-type=delivery-status; 
	boundary="[boundary]"

--[boundary]
Content-Description: Notification
Content-Type: text/plain

Acesta este un raspuns automat trimis de Sympa Mailing Lists Manager.

Adresa urmatoare nu este cunoscuta ca si lista:

	[list]

Pentru a afla numele corect a listelor, trimite un mesja la :

	mailto:[conf->email]@[conf->host]?subject=WHICH

Pentru mai multe informatii, contacteaza listmaster@[conf->host]

--[boundary]
Content-Type: message/delivery-status

Reporting-MTA: dns; [conf->host]
Arrival-Date: [date]

Final-Recipient: rfc822; [list]
Action: failed
Status: 5.1.1
Remote-MTA: dns; [conf->host]
Diagnostic-Code: List unknown

--[boundary]
Content-Type: text/rfc822-headers

[header]

--[boundary]--
