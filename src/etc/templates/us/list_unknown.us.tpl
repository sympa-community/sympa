From: [conf->email]@[conf->host]
To: [to]
Subject: List unknown
Mime-version: 1.0
Content-Type: multipart/report; report-type=delivery-status; 
	boundary="[boundary]"

--[boundary]
Content-Description: Notification
Content-Type: text/plain

This is an automatic response sent by Sympa Mailing Lists Manager.

The following address is not a known mailing list :

	[list]

To find out the correct listname, ask for this server's lists directory :

	mailto:[conf->email]@[conf->host]?subject=WHICH

For further assistance, please contact listmaster@[conf->host]

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
