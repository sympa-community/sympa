From: [conf->email]@[conf->host]
To: [to]
Subject: Onbekende lijst
Mime-version: 1.0
Content-Type: multipart/report; report-type=delivery-status; 
	boundary="[boundary]"

--[boundary]
Content-Description: Notification
Content-Type: text/plain

Dit is een automatisch bericht verstuurd door Sympa Mailing Lists Manager.

Het volgende adres is geen bekende mailinglijst:

	[list]

Om de goede naam te vinden, vraagt u de inhoudsopgave op van alle beschikbare lijsten.

	mailto:[conf->email]@[conf->host]?subject=WHICH

Heeft u verder nog vragen, stuur dan een email naar listmaster@[conf->host]

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
