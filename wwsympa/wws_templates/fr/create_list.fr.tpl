<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]

Votre liste est créée.<BR> 
Vous pouvez la configurer via le bouton <b>Admin liste</b> ci-contre.
<BR>
[IF auto_aliases]
Les alias ont été installés.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Les alias à installer </TD></TR>
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

Votre demande de création de liste est enregistrée. Vous pouvez 
la modifier en utilisant le bouton <b>Admin liste</b>. Mais cette liste
ne sera effectivement installée et rendue visible sur ce serveur
que quand le listmaster validera sa création.
[ENDIF]
