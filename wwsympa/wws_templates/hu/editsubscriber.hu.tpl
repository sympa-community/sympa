<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD=POST>
<TABLE WIDTH="100%" BORDER=0>
<TR><TH BGCOLOR="[dark_color]">
<FONT COLOR="[bg_color]">Információk a listatagokról</FONT>
</TH></TR><TR><TD>
<INPUT TYPE="hidden" NAME="previous_action" VALUE=[previous_action]>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="hidden" NAME="email" VALUE="[current_subscriber->escaped_email]">
<DL>
<DD>E-mail: <INPUT NAME="new_email" VALUE="[current_subscriber->email]" SIZE="25">
<DD>Név: <INPUT NAME="gecos" VALUE="current_[subscriber->gecos]" SIZE="25">
<DD>[current_subscriber->date] óta listatag
<DD>Utolsó módosítás: [current_subscriber->update_date]
<DD>Küldési mód: <SELECT NAME="reception">
		  [FOREACH r IN reception]
		    <OPTION VALUE="[r->NAME]" [r->selected]>[r->description]
		  [END]
	        </SELECT>

<DD>Nyilvánosság: [current_subscriber->visibility]
<DD>Nyelv: [current_subscriber->lang]
<DD><INPUT TYPE="submit" NAME="action_set" VALUE="Frissít">
<INPUT TYPE="submit" NAME="action_del" VALUE="A tag törlése">
<INPUT TYPE="checkbox" NAME="quiet"> nincs értesítés
</DL>
</TD></TR>
[IF current_subscriber->bounce]
<TR><TH BGCOLOR="[error_color]">
<FONT COLOR="[bg_color]">Visszapattanó címek</FONT>
</TD></TR><TR><TD>
<DL>
<DD>Állapot: [current_subscriber->bounce_status] ([current_subscriber->bounce_code])
<DD>Visszaküldések: [current_subscriber->bounce_count]
<DD>Idõszak: [current_subscriber->first_bounce]-tól/tõl [current_subscriber->last_bounce]-ig
<DD><A HREF="[path_cgi]/viewbounce/[list]/[current_subscriber->escaped_email]">Mutasd az utolsót</A>
<DD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Hibák törlése">
</DL>
</TD></TR>
[ENDIF]
</TABLE>
</FORM>
