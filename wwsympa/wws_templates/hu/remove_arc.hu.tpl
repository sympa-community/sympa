<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Mûvelet sikeresen befejezve.</b> Az üzenetet amint lehet törölni
fogjuk. Ez pár percen belül megtörténhet, fontos hogy ne felejtsd el
frissíteni a hivatkozó oldalt.
[ELSIF status = no_msgid]
<b>A törlésre szánt üzenet nem található, valószínüleg az üzenetet
"Message-Id:" azonosító nélkül kaptad. Kérlek fordulj a listmasterhez
a törlésre szánt üzenet teljes címével (URL).
</center>
[ELSIF status = not_found]
<b>A törlésre szánt üzenet nem található.</b>
[ELSE]
<b>Hiba az üzenet törlésénél, kérlek fordulj a listmasterhez a 
törlésre szánt üzenet teljes címével (URL).</b>
[ENDIF]
