<!-- RCS Identication ; $Revision$ ; $Date$ -->
[IF status=open] 
Lista ta a fost creata.<BR> Poti sa o setezi butonul <B>admin</B> alaturat. <BR> 
[IF auto_aliases] 
Aliasurile au fost instalate. 
[ELSE] 
<TABLE BORDER=1 width="136">
  <TR BGCOLOR="[light_color]">
    <TD align=center>Aliasuri obligatorii</TD>
  </TR>
 <TR>
 <TD>
 <pre><code>
 [aliases]
 </code></pre>
 </TD>
 </TR>
 </TABLE>
[ENDIF] 
[ELSE] Cererea pentru creerea listei a fost inregistrata. Poti sa ii modifici 
setarile utilizand butonul admin dar lista nu poate fi utilizata pana la validarea 
acesteia de catre administratorul listelor. 
[ENDIF] 
