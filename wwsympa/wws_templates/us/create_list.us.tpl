<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
Your list is created.<BR> 
You can configure it via the <B>admin</B> button beside.
<BR>
[IF auto_aliases]
Aliases have been installed.
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="--LIGHT_COLOR--"><TD align=center>Required aliases</TD></TR>
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
Your list creation request is registred. You can now  modify its
configuration using the admin button but the list will be unusable until the listmaster validates it.
[ENDIF]
