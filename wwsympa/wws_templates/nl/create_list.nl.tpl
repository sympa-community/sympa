<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
Uw lijst is aangemaakt.<BR> 
U kunt hem nu configureren via de <B>administratie</B> knop hiernaast.
<BR>
[IF auto_aliases]
Aliassen zijn geinstalleerd.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Verplichte aliassen</TD></TR>
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
U aanvraag voor de aanmaak van een lijst is geregistreerd. U kan nu de lijst
configureren via de administratie knop maar de lijst is pas bruikbaar
wanneer de listmaster de lijst valideerd.
[ENDIF]
