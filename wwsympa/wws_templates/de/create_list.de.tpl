<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
Ihre Liste wurde erzeugt.<BR> 
Sie k&ouml;nnen sie &uuml;ber den <B>admin</B>-Knopf konfiguriern.
<BR>
[IF auto_aliases]
Mail-Aliase wurden installiert.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Ben&ouml;tigte Mail Aliase</TD></TR>
 <TR>
 <TD>
 <pre><code>
 [aliases]
 </code></pre>
 </TD>
 </TR>
 </TABLE>
[ENDIF]

[ELSE]
Ihre Anfrage zur Erzeugung einer Liste wurde registriert. Sie k&ouml;nnen
jetzt die Konfiguration mit dem Admin-Knopf modifizieren. Die Liste
wird aber erst benutzbar, wenn der Administrator (listmaster) die
Liste best&auml;tigt.
[ENDIF]
