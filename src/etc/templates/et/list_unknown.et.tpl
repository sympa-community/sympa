From: [conf->email]@[conf->host]
To: [to]
Subject: List unknown
Mime-version: 1.0
Content-Type: multipart/report; report-type=delivery-status; 
	boundary="[boundary]"

--[boundary]
Content-Description: Notification
Content-Type: text/plain

See on automaatne vastus Sympa listserverilt. 

Järgnev aadress ei ole listserveri poolt hallatav:

	[list]

Leidmaks korrektset listi nime, küsige informatsiooni Sympalt:

	mailto:[conf->email]@[conf->host]?subject=WHICH

Probleemide puhul kirjutage listserveri haldajatele  listmaster@[conf->host]

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
