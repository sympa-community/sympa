<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="--DARK_COLOR--">
<FONT COLOR="--BG_COLOR--">Információk a listatagokról</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[subscriber->escaped_email]">
<DL>
<DD>Email: <INPUT NAME="new_email" VALUE="[subscriber->email]" SIZE="25">
<DD>Név: <INPUT NAME="gecos" VALUE="[subscriber->gecos]" SIZE="25">
<DD>[subscriber->date] óta listatag
<DD>Küldési mód: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Nyilvánosság: [subscriber->visibility]
<DD>Nyelv: [subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Frissít">
<INPUT TYPE="submit" NAME="action_del" VALUE="A tag törlése">
<INPUT TYPE="checkbox" NAME="quiet"> nincs értesítés
</DL>
</TD></TR>
[IF subscriber->bounce]
<TR><TH BGCOLOR="--ERROR_COLOR--">
<FONT COLOR="--BG_COLOR--">Visszapattanó címek</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Állapot: [subscriber->bounce_status] ([subscriber->bounce_code])
<DD>Visszaküldések: [subscriber->bounce_count]
<DD>Idõszak: [subscriber->first_bounce]-tól/tõl [subscriber->last_bounce]-ig
<DD><A HREF="[path_cgi]/viewbounce/[list]/[subscriber->escaped_email]">Mutasd az utolsót</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Hibák törlése">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>



