<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
A lista mûködik.<BR> 
A <B>lista adminisztráció</B> gombra kattintva a lista tulajdonságait, paramétereit állíthatod be.
<BR>
[IF auto_aliases]
A lista bejegyzések (aliases) elmentve.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Szükséges bejegyzések</TD></TR>
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
Lista létrehozási igényedet bejegyeztük. A lista beállításait 
az admin gombra kattintva végezheted el, azonban a lista csak
a listmaster jóváhagyása után fog mûködni.
[ENDIF]
