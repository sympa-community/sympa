<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
List loodi.<BR>
Saate listi hallata <b>listi haldamine</b> lingist.
<BR>
[IF auto_aliases]
Aliased installeeriti.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>Vajalikud aliased</TD></TR>
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
Teie listisoov on registreeritud. Te saate nüüd oma listi seadeid muuta, kuid
listi kasutamiseks peavad serveri hooldajad listi heaks kiitma.
[ENDIF]
