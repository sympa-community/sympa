<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
A lista mûködik.<BR> 
Az <B>admin</B> gombra kattintva állíthatod be a paramétereit.
<BR>
[IF auto_aliases]
A lista bejegyzések (aliases) mentve lettek.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="--LIGHT_COLOR--"><TD align=center>Szükséges bejegyzések</TD></TR>
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
